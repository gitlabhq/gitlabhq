class MailerObserver < ActiveRecord::Observer
  observe :issue, :user, :note, :merge_request
  cattr_accessor :current_user

  def after_create(model)
    new_issue(model) if model.kind_of?(Issue)
    new_user(model) if model.kind_of?(User)
    new_note(model) if model.kind_of?(Note)
    new_merge_request(model) if model.kind_of?(MergeRequest)
  end

  def after_update(model)
    changed_merge_request(model) if model.kind_of?(MergeRequest)
    changed_issue(model) if model.kind_of?(Issue)
  end

  protected

  def new_issue(issue)
    if issue.assignee != current_user
      Notify.new_issue_email(issue.id).deliver
    end
  end

  def new_user(user)
    Notify.new_user_email(user.id, user.password).deliver
  end

  def new_note(note)
    if note.notify
      # Notify whole team except author of note
      notify_note(note)
    elsif note.notify_author
      # Notify only author of resource
      Notify.note_commit_email(note.commit_author.id, note.id).deliver
    else
      # Otherwise ignore it
      nil
    end
  end

  def notify_note note
    # reject author of note from mail list
    users = note.project.users.reject { |u| u.id == current_user.id }

    users.each do |u|
      case note.noteable_type
      when "Commit"; Notify.note_commit_email(u.id, note.id).deliver
      when "Issue";  Notify.note_issue_email(u.id, note.id).deliver
      when "MergeRequest"; Notify.note_merge_request_email(u.id, note.id).deliver
      when "Snippet"; true
      else
        Notify.note_wall_email(u.id, note.id).deliver
      end
    end
  end

  def new_merge_request(merge_request)
    if merge_request.assignee != current_user
      Notify.new_merge_request_email(merge_request.id).deliver
    end
  end

  def changed_merge_request(merge_request)
    status_notify_and_comment merge_request, :reassigned_merge_request_email
  end

  def changed_issue(issue)
    status_notify_and_comment issue, :reassigned_issue_email
  end

  # This method used for Issues & Merge Requests
  # 
  # It create a comment for Issue or MR if someone close/reopen.
  # It also notify via email if assignee was changed 
  #
  def status_notify_and_comment target, mail_method
    # If assigne changed - notify to recipients
    if target.assignee_id_changed?
      recipients_ids = target.assignee_id_was, target.assignee_id
      recipients_ids.delete current_user.id

      recipients_ids.each do |recipient_id|
        Notify.send(mail_method, recipient_id, target.id, target.assignee_id_was).deliver
      end
    end

    # Create comment about status changed
    if target.closed_changed?
      note = Note.new(:noteable => target, :project => target.project)
      note.author = current_user
      note.note = "_Status changed to #{target.closed ? 'closed' : 'reopened'}_"
      note.save()
    end
  end
end
