# frozen_string_literal: true

require "tempfile"
require "tmpdir"
require "fileutils"

class UploadedFile
  InvalidPathError = Class.new(StandardError)
  UnknownSizeError = Class.new(StandardError)
  ALLOWED_KWARGS = %i[filename content_type sha256 remote_id size upload_duration sha1 md5].freeze

  # The filename, *not* including the path, of the "uploaded" file
  attr_reader :original_filename

  # The tempfile
  attr_reader :tempfile

  # The content type of the "uploaded" file
  attr_accessor :content_type

  attr_reader :remote_id, :sha256, :size, :upload_duration, :sha1, :md5

  def initialize(path, **kwargs)
    validate_kwargs(kwargs)

    if path.present?
      raise InvalidPathError, "#{path} file does not exist" unless ::File.exist?(path)

      @tempfile = File.new(path, 'rb')
      @size = @tempfile.size
    else
      begin
        @size = Integer(kwargs[:size])
      rescue ArgumentError, TypeError
        raise UnknownSizeError, 'Unable to determine file size'
      end
    end

    begin
      @upload_duration = Float(kwargs[:upload_duration])
    rescue ArgumentError, TypeError
      @upload_duration = 0
    end

    @content_type = kwargs[:content_type] || 'application/octet-stream'
    @original_filename = sanitize_filename(kwargs[:filename] || path || '')
    @sha256 = kwargs[:sha256]
    @sha1 = kwargs[:sha1]
    @md5 = kwargs[:md5]
    @remote_id = kwargs[:remote_id]
  end

  def self.from_params(params, upload_paths)
    path = params['path']
    remote_id = params['remote_id']
    return if path.blank? && remote_id.blank?

    # don't use file_path if remote_id is set
    if remote_id.present?
      file_path = nil
    elsif path.present?
      file_path = File.realpath(path)

      unless self.allowed_path?(file_path, Array(upload_paths).compact)
        raise InvalidPathError, "insecure path used '#{file_path}'"
      end
    end

    new(
      file_path,
      filename: params['name'],
      content_type: params['type'] || 'application/octet-stream',
      sha256: params['sha256'],
      remote_id: remote_id,
      size: params['size'],
      upload_duration: params['upload_duration'],
      sha1: params['sha1'],
      md5: params['md5']
    ).tap do |uploaded_file|
      ::Gitlab::Instrumentation::Uploads.track(uploaded_file)
    end
  end

  def self.allowed_path?(file_path, paths)
    paths.any? do |path|
      File.exist?(path) && file_path.start_with?(File.realpath(path))
    end
  end

  # copy-pasted from CarrierWave::SanitizedFile
  def sanitize_filename(name)
    name = name.tr("\\", "/") # work-around for IE
    name = ::File.basename(name)
    name = name.gsub(CarrierWave::SanitizedFile.sanitize_regexp, "_")
    name = "_#{name}" if /\A\.+\z/.match?(name)
    name = "unnamed" if name.empty?
    name.mb_chars.to_s
  end

  def path
    @tempfile&.path
  end

  def close
    @tempfile&.close
  end

  def empty_size?
    size == 0
  end

  alias_method :local_path, :path

  def method_missing(method_name, *args, &block) # :nodoc:
    @tempfile.__send__(method_name, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
  end

  def respond_to?(method_name, include_private = false) # :nodoc:
    @tempfile.respond_to?(method_name, include_private) || super
  end

  private

  def validate_kwargs(kwargs)
    invalid_kwargs = kwargs.keys - ALLOWED_KWARGS
    raise ArgumentError, "unknown keyword(s): #{invalid_kwargs.join(', ')}" if invalid_kwargs.any?
  end
end
