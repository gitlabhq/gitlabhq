# frozen_string_literal: true

require "tempfile"
require "tmpdir"
require "fileutils"

class UploadedFile
  InvalidPathError = Class.new(StandardError)
  UnknownSizeError = Class.new(StandardError)

  # The filename, *not* including the path, of the "uploaded" file
  attr_reader :original_filename

  # The tempfile
  attr_reader :tempfile

  # The content type of the "uploaded" file
  attr_accessor :content_type

  attr_reader :remote_id
  attr_reader :sha256
  attr_reader :size

  def initialize(path, filename: nil, content_type: "application/octet-stream", sha256: nil, remote_id: nil, size: nil)
    if path.present?
      raise InvalidPathError, "#{path} file does not exist" unless ::File.exist?(path)

      @tempfile = File.new(path, 'rb')
      @size = @tempfile.size
    else
      begin
        @size = Integer(size)
      rescue ArgumentError, TypeError
        raise UnknownSizeError, 'Unable to determine file size'
      end
    end

    @content_type = content_type
    @original_filename = sanitize_filename(filename || path || '')
    @content_type = content_type
    @sha256 = sha256
    @remote_id = remote_id
  end

  def self.from_params(params, field, upload_paths, path_override = nil)
    path = path_override || params["#{field}.path"]
    remote_id = params["#{field}.remote_id"]
    return if path.blank? && remote_id.blank?

    if remote_id.present? # don't use file_path if remote_id is set
      file_path = nil
    elsif path.present?
      file_path = File.realpath(path)

      paths = Array(upload_paths) << Dir.tmpdir
      unless self.allowed_path?(file_path, paths.compact)
        raise InvalidPathError, "insecure path used '#{file_path}'"
      end
    end

    UploadedFile.new(file_path,
      filename: params["#{field}.name"],
      content_type: params["#{field}.type"] || 'application/octet-stream',
      sha256: params["#{field}.sha256"],
      remote_id: remote_id,
      size: params["#{field}.size"])
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
    name = "_#{name}" if name =~ /\A\.+\z/
    name = "unnamed" if name.empty?
    name.mb_chars.to_s
  end

  def path
    @tempfile&.path
  end

  def close
    @tempfile&.close
  end

  alias_method :local_path, :path

  def method_missing(method_name, *args, &block) #:nodoc:
    @tempfile.__send__(method_name, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
  end

  def respond_to?(method_name, include_private = false) #:nodoc:
    @tempfile.respond_to?(method_name, include_private) || super
  end
end
