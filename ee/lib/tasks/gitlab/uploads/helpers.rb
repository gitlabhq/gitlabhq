module UploadTaskHelpers
  def batch_size
    ENV.fetch('BATCH', 200).to_i
  end

  def calculate_checksum(absolute_path)
    Digest::SHA256.file(absolute_path).hexdigest
  end

  def check_checksum(upload)
    checksum = calculate_checksum(upload.absolute_path)

    if checksum != upload.checksum
      puts "  * File checksum (#{checksum}) does not match the one in the database (#{upload.checksum})".color(:red)
    end
  end

  def uploads_batches(&block)
    Upload.all.in_batches(of: batch_size, start: ENV['ID_FROM'], finish: ENV['ID_TO']) do |relation| # rubocop: disable Cop/InBatches
      yield relation
    end
  end
end
