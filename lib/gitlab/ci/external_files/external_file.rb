require 'open-uri'

module Gitlab
  module Ci
    module ExternalFiles
      class ExternalFile
        def initialize(value, project)
          @value = value
          @project = project
        end

        def content
          if remote_url?
            open(value).read
          else
            local_file_content
          end
        end

        def valid?
          remote_url? || local_file_content
        end

        private

        attr_reader :value, :project

        def remote_url?
          ::Gitlab::UrlSanitizer.valid?(value)
        end

        def local_file_content
          project.repository.fetch_file_for(sha, value)
        end

        def sha
          @sha ||= project.repository.commit.sha
        end
      end
    end
  end
end
