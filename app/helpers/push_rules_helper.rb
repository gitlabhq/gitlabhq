module PushRulesHelper
  def reject_unsigned_commits_description(push_rule)
    message = [s_("ProjectSettings|Only signed commits can be pushed to this repository.")]

    annotate_with_update_message(message, push_rule,
                                 enabled_globally: PushRule.global&.reject_unsigned_commits,
                                 enabled_in_project: push_rule.reject_unsigned_commits)
    message.join(' ')
  end

  def commit_author_check_description(push_rule)
    message = [s_("ProjectSettings|Only the author of a commit can push changes to this repository.")]

    annotate_with_update_message(message, push_rule,
                                 enabled_globally: PushRule.global&.commit_author_check,
                                 enabled_in_project: push_rule.commit_author_check)
    message.join(' ')
  end

  private

  def annotate_with_update_message(message, push_rule, enabled_globally:, enabled_in_project:)
    if push_rule.global?
      message << s_("ProjectSettings|This setting will be applied to all projects unless overridden by an admin.")
    else
      if enabled_globally
        message << if enabled_in_project
                     s_("ProjectSettings|This setting is applied on the server level and can be overridden by an admin.")
                   else
                     s_("ProjectSettings|This setting is applied on the server level but has been overridden for this project.")
                   end

        message << s_("ProjectSettings|Contact an admin to change this setting.") unless current_user.admin?
      end
    end
  end
end
