class FileStreamer #:nodoc:
  attr_reader :to_path

  def initialize(path)
    @to_path = path
  end

  # Stream the file's contents if Rack::Sendfile isn't present.
  def each
    File.open(to_path, 'rb') do |file|
      while chunk = file.read(16384)
        yield chunk
      end
    end
  end
end
