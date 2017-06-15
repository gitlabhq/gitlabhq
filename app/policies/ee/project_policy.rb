module EE
  module ProjectPolicy
    def rules
      super

      guest_access! if user.support_bot?
    end

    def disabled_features!
      raise NotImplementedError unless defined?(super)

      super

      if License.block_changes?
        cannot! :create_issue
        cannot! :create_merge_request
        cannot! :push_code
        cannot! :push_code_to_protected_branches
      end

      if @user&.support_bot? && !@subject.service_desk_enabled?
        cannot! :create_note
        cannot! :read_project
      end

      unless project.feature_available?(:related_issues)
        cannot! :read_issue_link
        cannot! :admin_issue_link
      end
    end
  end
end
