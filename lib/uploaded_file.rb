require "tempfile"
require "tmpdir"
require "fileutils"

class UploadedFile
  InvalidPathError = Class.new(StandardError)

  # The filename, *not* including the path, of the "uploaded" file
  attr_reader :original_filename

  # The content type of the "uploaded" file
  attr_accessor :content_type

  attr_reader :local_path
  attr_reader :remote_id
  attr_reader :sha256

  def initialize(local_path, filename: nil, content_type: "application/octet-stream", sha256: nil, remote_id: nil, allowed_paths: nil)
    raise InvalidPathError, "missing filename or local_path" unless filename || local_path
    raise InvalidPathError, "local_path or remote_id has to be provided" unless local_path || remote_id

    if local_path
      raise InvalidPathError, "#{path} file does not exist" unless ::File.exist?(local_path)
      raise InvalidPathError, "insecure local_path used for '#{local_path}'" unless self.class.allowed_path?(local_path, allowed_paths)
    end

    @local_path = local_path
    @content_type = content_type
    @sha256 = sha256
    @remote_id = remote_id
    @original_filename = filename
    @original_filename ||= ::File.basename(local_path) if local_path
  end

  def self.from_params(params, field, upload_path)
    UploadedFile.new(params["#{field}.path"],
      filename: params["#{field}.name"],
      content_type: params["#{field}.type"] || 'application/octet-stream',
      sha256: params["#{field}.sha256"],
      remote_id: params["#{field}.remote_id"],
      allowed_paths: [upload_path, Dir.tmpdir].compact)
  end

  def self.allowed_path?(file_path, allowed_paths)
    return true unless allowed_paths

    file_path = File.realpath(file_path)

    allowed_paths.any? do |allowed_path|
      File.exist?(allowed_path) && file_path.start_with?(File.realpath(allowed_path))
    end
  end

  def local?
    local_path.present?
  end

  def remote?
    remote_id.present?
  end

  alias_method :path, :local_path

  def tempfile
    @tempfile ||= File.new(local_path, 'rb') if local_path
  end

  def method_missing(method_name, *args, &block) #:nodoc:
    tempfile.__send__(method_name, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
  end

  def respond_to?(method_name, include_private = false) #:nodoc:
    tempfile&.respond_to?(method_name, include_private) || super
  end
end
