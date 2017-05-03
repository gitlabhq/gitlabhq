module Gitlab
  module Ci
    module Status
      module Build
        module Common
          def has_details?
            can?(user, :read_build, subject)
          end

          def details_path
            namespace_project_build_path(subject.project.namespace,
                                         subject.project,
                                         subject)
          end
        end
      end
    end
  end
end
