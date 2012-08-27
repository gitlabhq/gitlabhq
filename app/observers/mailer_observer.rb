class MailerObserver < ActiveRecord::Observer
  observe :note, :merge_request
  cattr_accessor :current_user

  def after_create(model)
    new_note(model) if model.kind_of?(Note)
    new_merge_request(model) if model.kind_of?(MergeRequest)
  end

  def after_update(model)
    changed_merge_request(model) if model.kind_of?(MergeRequest)
  end

  protected

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
    all_users = note.project.users.reject { |u| u.id == current_user.id }
    all_users_ids = all_users.collect{ |u| u.id }

    case note.noteable_type
    when "Commit"
      ci = note.project.commit(noteable_id)
      # author email may not belong to any user, so use email directly.
      to_users_emails = [ci.author_email, ci.committer_email].uniq
      all_users_emails = all_users.collect{ |u| u.email }
      cc_users_emails = all_users_emails - to_users_emails
      Notify.note_commit_email(to_users_emails, cc_users_emails, note.id).deliver
    when "Issue"
      to_users_ids = [note.noteable.assignee_id, note.noteable.author_id].uniq
      cc_users_ids = all_users_ids - to_users_ids
      Notify.note_issue_email(to_users_ids, cc_users_ids, note.id).deliver
    when "Wiki"
      Notify.note_wiki_email(u.id, note.id).deliver
    when "MergeRequest"
      to_users_ids = [note.noteable.assignee_id, note.noteable.author_id].uniq
      cc_users_ids = all_users_ids - to_users_ids
      Notify.note_merge_request_email(to_users_ids, cc_users_ids, note.id).deliver
    when "Snippet"
      true
    else
      Notify.note_wall_email(u.id, note.id).deliver
    end
  end

  def new_merge_request(merge_request)
    if merge_request.assignee && merge_request.assignee != current_user
      Notify.new_merge_request_email(merge_request.id).deliver
    end
  end

  def changed_merge_request(merge_request)
    status_notify_and_comment merge_request, :reassigned_merge_request_email
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
      note = Note.new(noteable: target, project: target.project)
      note.author = current_user
      note.note = "_Status changed to #{target.closed ? 'closed' : 'reopened'}_"
      note.save()
    end
  end
end
