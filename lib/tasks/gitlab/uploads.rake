namespace :gitlab do
  namespace :uploads do
    desc 'GitLab | Uploads | Check integrity of uploaded files'
    task check: :environment do
      puts 'Checking integrity of uploaded files'

      uploads_batches do |batch|
        batch.each do |upload|
          puts "- Checking file (#{upload.id}): #{upload.absolute_path}".color(:green)

          if upload.exist?
            check_checksum(upload)
          else
            puts "  * File does not exist on the file system".color(:red)
          end
        end
      end

      puts 'Done!'
    end

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
end
