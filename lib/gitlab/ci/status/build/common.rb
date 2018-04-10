module Gitlab
  module Ci
    module Status
      module Build
        module Common
          def illustration
            {
              image: 'illustrations/skipped-job_empty.svg',
              size: 'svg-430',
              title: _('This job does not have a trace.'),
            }
          end

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
