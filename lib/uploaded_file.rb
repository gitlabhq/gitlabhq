require "tempfile"
require "fileutils"

# Taken from: Rack::Test::UploadedFile
class UploadedFile
  # The filename, *not* including the path, of the "uploaded" file
  attr_reader :original_filename

  # The tempfile
  attr_reader :tempfile

  # The content type of the "uploaded" file
  attr_accessor :content_type

  def initialize(path, filename, content_type = "text/plain")
    raise "#{path} file does not exist" unless ::File.exist?(path)

    @content_type = content_type
    @original_filename = filename || ::File.basename(path)
    @tempfile = File.new(path, 'rb')
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
