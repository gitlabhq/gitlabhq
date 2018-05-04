require "tempfile"
require "tmpdir"
require "fileutils"

class UploadedFile
  InvalidPathError = Class.new(StandardError)

  # The filename, *not* including the path, of the "uploaded" file
  attr_reader :original_filename

  # The tempfile
  attr_reader :tempfile

  # The content type of the "uploaded" file
  attr_accessor :content_type

  attr_reader :remote_id
  attr_reader :sha256

  def initialize(path, filename: nil, content_type: "application/octet-stream", sha256: nil, remote_id: nil)
    raise InvalidPathError, "#{path} file does not exist" unless ::File.exist?(path)

    @content_type = content_type
    @original_filename = filename || ::File.basename(path)
    @content_type = content_type
    @sha256 = sha256
    @remote_id = remote_id
    @tempfile = File.new(path, 'rb')
  end

  def self.from_params(params, field, upload_path)
    unless params["#{field}.path"]
      raise InvalidPathError, "file is invalid" if params["#{field}.remote_id"]

      return
    end

    file_path = File.realpath(params["#{field}.path"])

    unless self.allowed_path?(file_path, [upload_path, Dir.tmpdir].compact)
      raise InvalidPathError, "insecure path used '#{file_path}'"
    end

    UploadedFile.new(file_path,
      filename: params["#{field}.name"],
      content_type: params["#{field}.type"] || 'application/octet-stream',
      sha256: params["#{field}.sha256"],
      remote_id: params["#{field}.remote_id"])
  end

  def self.allowed_path?(file_path, paths)
    paths.any? do |path|
      File.exist?(path) && file_path.start_with?(File.realpath(path))
    end
  end

  def path
    @tempfile.path
  end

  alias_method :local_path, :path

  def method_missing(method_name, *args, &block) #:nodoc:
    @tempfile.__send__(method_name, *args, &block) # rubocop:disable GitlabSecurity/PublicSend
  end

  def respond_to?(method_name, include_private = false) #:nodoc:
    @tempfile.respond_to?(method_name, include_private) || super
  end
end
