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
      Notify.new_issue_email(issue).deliver
    end
  end

  def new_user(user)
    Notify.new_user_email(user, user.password).deliver
  end

  def new_note(note)
    # Notify whole team except author of note
    if note.notify
      note.project.users.reject { |u| u.id == current_user.id } .each do |u|
        case note.noteable_type
        when "Commit" then
          Notify.note_commit_email(u, note).deliver
        when "Issue" then
          Notify.note_issue_email(u, note).deliver
        when "MergeRequest" then
          Notify.note_merge_request_email(u, note).deliver
        when "Snippet"
          true
        else
          Notify.note_wall_email(u, note).deliver
        end
      end
    # Notify only author of resource
    elsif note.notify_author
      Notify.note_commit_email(note.commit_author, note).deliver
    end
  end

  def new_merge_request(merge_request)
    if merge_request.assignee != current_user
      Notify.new_merge_request_email(merge_request).deliver
    end
  end

  def changed_merge_request(merge_request)
    if merge_request.assignee_id_changed?
      recipients_ids = merge_request.assignee_id_was, merge_request.assignee_id
      recipients_ids.delete current_user.id

      User.find(recipients_ids).each do |user|
        Notify.changed_merge_request_email(user, merge_request).deliver
      end
    end

    if merge_request.closed_changed?
      note = Note.new(:noteable => merge_request, :project => merge_request.project)
      note.author = current_user
      note.note = "_Status changed to #{merge_request.closed ? 'closed' : 'reopened'}_"
      note.save()
    end
  end

  def changed_issue(issue)
    if issue.assignee_id_changed?
      recipients_ids = issue.assignee_id_was, issue.assignee_id
      recipients_ids.delete current_user.id

      User.find(recipients_ids).each do |user|
        Notify.changed_issue_email(user, issue).deliver
      end
    end

    if issue.closed_changed?
      note = Note.new(:noteable => issue, :project => issue.project)
      note.author = current_user
      note.note = "_Status changed to #{issue.closed ? 'closed' : 'reopened'}_"
      note.save()
    end
  end
end
