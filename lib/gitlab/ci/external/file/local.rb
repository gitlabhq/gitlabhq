module Gitlab
  module Ci
    module External
      module File
        class Local < Base
          attr_reader :location, :project, :sha

          def initialize(location, opts = {})
            super

            @project = opts.fetch(:project)
            @sha = opts.fetch(:sha)
          end

          def content
            @content ||= fetch_local_content
          end

          def error_message
            "Local file '#{location}' is not valid."
          end

          private

          def fetch_local_content
            project.repository.blob_data_at(sha, location)
          end
        end
      end
    end
  end
end
