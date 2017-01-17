module Gitlab
  module Ci
    module Status
      module External
        module Common
          def has_details?
            can?(user, :read_commit_status, subject) &&
              subject.target_url.present?
          end

          def details_path
            subject.target_url
          end

          def has_action?
            false
          end
        end
      end
    end
  end
end
