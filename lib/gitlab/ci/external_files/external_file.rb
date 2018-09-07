module Gitlab
  module Ci
    module ExternalFiles
      class ExternalFile
        attr_reader :value, :project

        def initialize(value, project)
          @value = value
          @project = project
        end

        def content
          if remote_url?
            HTTParty.get(value)
          else
            local_file_content
          end
        rescue HTTParty::Error, Timeout::Error
          nil
        end

        def valid?
          remote_url? || local_file_content
        end

        private

        def remote_url?
          ::Gitlab::UrlSanitizer.valid?(value)
        end

        def local_file_content
          project.repository.blob_data_at(sha, value)
        end

        def sha
          @sha ||= project.repository.commit.sha
        end
      end
    end
  end
end
