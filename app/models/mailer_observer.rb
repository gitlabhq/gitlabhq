class MailerObserver < ActiveRecord::Observer
  observe :issue, :user, :note, :merge_request
  cattr_accessor :current_user

  def after_create(model)
    new_issue(model) if model.kind_of?(Issue)
    new_user(model) if model.kind_of?(User)
    new_note(model) if model.kind_of?(Note)
    new_merge_request(model) if model.kind_of?(MergeRequest)
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
      return unless note.notify
      note.project.users.reject { |u| u.id == current_user.id } .each do |u|
        case note.noteable_type
        when "Commit" then
          Notify.note_commit_email(u, note).deliver
        when "Issue" then
          Notify.note_issue_email(u, note).deliver
        when "MergeRequest"
          true # someone should write email notification
        when "Snippet"
          true
        else
          Notify.note_wall_email(u, note).deliver
        end
      end
    end

    def new_merge_request(merge_request)
      if merge_request.assignee != current_user
        Notify.new_merge_request_email(merge_request).deliver
      end
    end

end
