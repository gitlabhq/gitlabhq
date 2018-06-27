# This fixes the problem https://gitlab.com/gitlab-org/gitlab-ce/issues/46182 that carrierwave eagerly loads upoloading files into memory
# There is an PR https://github.com/carrierwaveuploader/carrierwave/pull/2314 which has the identical change.
module CarrierWave
  module Storage
    class Fog < Abstract
      class File
        module MonkeyPatch
          ##
          # Read content of file from service
          #
          # === Returns
          #
          # [String] contents of file
          def read
            file_body = file.body

            return if file_body.nil?
            return file_body unless file_body.is_a?(::File)

            # Fog::Storage::XXX::File#body could return the source file which was upoloaded to the remote server.
            read_source_file(file_body) if ::File.exist?(file_body.path)

            # If the source file doesn't exist, the remote content is read
            @file = nil # rubocop:disable Gitlab/ModuleWithInstanceVariables
            file.body
          end

          ##
          # Write file to service
          #
          # === Returns
          #
          # [Boolean] true on success or raises error
          def store(new_file)
            if new_file.is_a?(self.class) # rubocop:disable Cop/LineBreakAroundConditionalBlock
              new_file.copy_to(path)
            else
              fog_file = new_file.to_file
              @content_type ||= new_file.content_type # rubocop:disable Gitlab/ModuleWithInstanceVariables
              @file = directory.files.create({ # rubocop:disable Gitlab/ModuleWithInstanceVariables
                :body         => fog_file ? fog_file : new_file.read, # rubocop:disable Style/HashSyntax
                :content_type => @content_type, # rubocop:disable Style/HashSyntax,Gitlab/ModuleWithInstanceVariables
                :key          => path, # rubocop:disable Style/HashSyntax
                :public       => @uploader.fog_public # rubocop:disable Style/HashSyntax,Gitlab/ModuleWithInstanceVariables
              }.merge(@uploader.fog_attributes)) # rubocop:disable Gitlab/ModuleWithInstanceVariables
              fog_file.close if fog_file && !fog_file.closed?
            end
            true
          end

          private

          def read_source_file(file_body)
            return unless ::File.exist?(file_body.path)

            begin
              file_body = ::File.open(file_body.path) if file_body.closed? # Reopen if it's already closed
              file_body.read
            ensure
              file_body.close
            end
          end
        end

        prepend MonkeyPatch
      end
    end
  end
end
