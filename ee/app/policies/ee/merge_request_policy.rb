module EE
  module MergeRequestPolicy
    extend ActiveSupport::Concern

    prepended do
      with_scope :subject
      condition(:can_override_approvers, score: 0) do
        @subject.target_project&.can_override_approvers?
      end

      rule { ~can_override_approvers }.prevent :update_approvers
      rule { can?(:update_merge_request) }.enable :update_approvers
    end
  end
end
