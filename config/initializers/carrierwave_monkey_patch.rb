# This is a monkey patch until https://github.com/carrierwaveuploader/carrierwave/pull/2314 has been merged
# This fixes a problem https://gitlab.com/gitlab-org/gitlab-ce/issues/46182 that carrierwave loads large files into memory
# and triggers sidekiq shutdown by hitting RSS limit.
module CarrierWave
  module Storage
    class Fog < Abstract
      class File
        def read
          file_body = file.body

          return if file_body.nil?
          return file_body unless file_body.is_a?(::File)

          begin
            file_body = ::File.open(file_body.path) if file_body.closed? # Reopen if it's closed
            file_body.read
          ensure
            file_body.close
          end
        end

        def store(new_file)
          if new_file.is_a?(self.class) # rubocop:disable Gitlab/LineBreakAroundConditionalBlock
            new_file.copy_to(path)
          else
            fog_file = new_file.to_file
            @content_type ||= new_file.content_type
            @file = directory.files.create({
              :body         => fog_file ? fog_file : new_file.read, # rubocop:disable Gitlab/HashSyntax
              :content_type => @content_type, # rubocop:disable Gitlab/HashSyntax
              :key          => path, # rubocop:disable Gitlab/HashSyntax
              :public       => @uploader.fog_public # rubocop:disable Gitlab/HashSyntax
            }.merge(@uploader.fog_attributes))
            fog_file.close if fog_file && !fog_file.closed?
          end
          true
        end
      end
    end
  end
end
