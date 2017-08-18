module Gitlab
  module Ci
    module Status
      module Build
        module Common
          def has_details?
            can?(user, :read_build, subject)
          end

          def details_path
            project_job_path(subject.project, subject)
          end
        end
      end
    end
  end
end
