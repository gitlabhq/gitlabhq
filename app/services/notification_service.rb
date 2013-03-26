# NotificationService class
#
# Used for notifing users with emails about different events
#
# Ex.
#   NotificationService.new.new_issue(issue, current_user)
#
class NotificationService
  # Always notify user about ssh key added
  # only if ssh key is not deploy key
  def new_key(key)
    if key.user
      Notify.delay.new_ssh_key_email(key.id)
    end
  end

  # TODO: When we close an issue we should send next emails:
  #
  #  * issue author if his notification level is not Disabled
  #  * issue assignee if his notification level is not Disabled
  #  * project team members with notification level higher then Participating
  #
  def close_issue(issue, current_user)
    recipients = [issue.author, issue.assignee].compact.uniq

    # Dont send email to me when I close an issue
    recipients.reject! { |u| u == current_user }

    recipients.each do |recipient|
      Notify.delay.issue_status_changed_email(recipient.id, issue.id, issue.state, current_user.id)
    end
  end

  # When we reassign an issue we should send next emails:
  #
  #  * issue author if his notification level is not Disabled
  #  * issue assignee if his notification level is not Disabled
  #
  def reassigned_issue(issue, current_user)
    recipient_ids = [issue.assignee_id, issue.assignee_id_was].compact.uniq

    # Reject me from recipients if I reassign an issue
    recipient_ids.reject! { |id| id == current_user.id }

    recipient_ids.each do |recipient_id|
      Notify.delay.reassigned_issue_email(recipient_id, issue.id, issue.assignee_id_was)
    end
  end

  # When we reassign an issue we should send next emails:
  #
  #  * issue assignee if his notification level is not Disabled
  #
  def new_issue(issue, current_user)
    if issue.assignee && issue.assignee != current_user
      Notify.delay.new_issue_email(issue.id)
    end
  end
end
