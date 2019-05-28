# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module External
        module Common
          def label
            subject.description.presence || super
          end

          def has_details?
            subject.target_url.present? &&
              can?(user, :read_commit_status, subject)
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
