module Gitlab
  module Ci
    module External
      module File
        class Local
          attr_reader :location, :project, :branch_name

          def initialize(location, opts = {})
            @location = location
            @project = opts.fetch(:project)
            @sha = opts.fetch(:sha)
          end

          def valid?
            local_file_content
          end

          def content
            local_file_content
          end

          private

          def local_file_content
            @local_file_content ||= project.repository.blob_data_at(sha, location)
          end
        end
      end
    end
  end
end
