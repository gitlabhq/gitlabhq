module Gitlab
  module Ci
    module External
      module File
        class Local
          attr_reader :value, :project, :branch_name

          def initialize(value, project, branch_name)
            @value = value
            @project = project
            @branch_name = branch_name
          end

          def valid?
            commit && local_file_content
          end

          def content
            local_file_content
          end

          private

          def commit
            @commit ||= project.repository.commit(branch_name)
          end

          def local_file_content
            @local_file_content ||= project.repository.blob_data_at(commit.sha, value)
          end
        end
      end
    end
  end
end
