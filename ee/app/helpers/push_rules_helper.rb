module PushRulesHelper
  def reject_unsigned_commits_description(push_rule)
    message = s_("ProjectSettings|Only signed commits can be pushed to this repository.")

    push_rule_update_description(message, push_rule, :reject_unsigned_commits)
  end

  def commit_committer_check_description(push_rule)
    message = s_("ProjectSettings|Users can only push commits to this repository "\
                 "that were committed with one of their own verified emails.")

    push_rule_update_description(message, push_rule, :commit_committer_check)
  end

  private

  def push_rule_update_description(message, push_rule, rule)
    messages = [message]
    if push_rule.global?
      messages << s_("ProjectSettings|This setting will be applied to all projects unless overridden by an admin.")
    else
      enabled_globally = PushRule.global&.public_send(rule) # rubocop:disable GitlabSecurity/PublicSend
      enabled_in_project = push_rule.public_send(rule) # rubocop:disable GitlabSecurity/PublicSend

      if enabled_globally
        messages << if enabled_in_project
                      s_("ProjectSettings|This setting is applied on the server level and can be overridden by an admin.")
                    else
                      s_("ProjectSettings|This setting is applied on the server level but has been overridden for this project.")
                    end

        messages << s_("ProjectSettings|Contact an admin to change this setting.") unless current_user.admin?
      end
    end

    messages.join(' ')
  end
end
