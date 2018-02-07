require_relative 'helpers.rb'

namespace :gitlab do
  namespace :uploads do
    desc 'GitLab | Uploads | Check integrity of uploaded files'
    task check: :environment do
      include UploadTaskHelpers

      puts 'Checking integrity of uploaded files'

      uploads_batches do |batch|
        batch.each do |upload|
          begin
            puts "- Checking file (#{upload.id}): #{upload.absolute_path}".color(:green)

            if upload.exist?
              check_checksum(upload)
            else
              puts "  * File does not exist on the file system".color(:red)
            end
          rescue ObjectStorage::RemoteStoreError
            puts "- File (#{upload.id}): File is stored remotely, skipping".color(:yellow)
          end
        end
      end

      puts 'Done!'
    end
  end
end
