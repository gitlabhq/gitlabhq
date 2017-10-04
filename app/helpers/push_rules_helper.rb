module PushRulesHelper
  def reject_unsigned_commits_description(push_rule)
    message = [s_("ProjectSettings|Only signed commits can be pushed to this repository.")]

    if push_rule.global?
      message << s_("ProjectSettings|This setting will be applied to all projects unless overridden by an admin.")
    else
      if PushRule.global&.reject_unsigned_commits
        message << if push_rule.reject_unsigned_commits
                     s_("ProjectSettings|This setting is applied on the server level and can be overridden by an admin.")
                   else
                     s_("ProjectSettings|This setting is applied on the server level but has been overridden for this project.")
                   end

        message << s_("ProjectSettings|Contact an admin to change this setting.") unless current_user.admin?
      end
    end

    message.join(' ')
  end
end
