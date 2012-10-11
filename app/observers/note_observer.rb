class NoteObserver < ActiveRecord::Observer

  def after_create(note)
    if note.notify
      # Notify whole team except author of note
      notify_team_of_new_note(note)
    elsif note.notify_author
      # Notify only author of resource
      Notify.note_commit_email(note.commit_author.id, note.id).deliver
    else
      # Otherwise ignore it
      nil
    end
  end

  protected

  def notify_team_of_new_note(note)
    team_without_note_author(note).map do |u|
      case note.noteable_type
      when "Commit"; Notify.note_commit_email(u.id, note.id).deliver
      when "Issue";  Notify.note_issue_email(u.id, note.id).deliver
      when "Wiki";  Notify.note_wiki_email(u.id, note.id).deliver
      when "MergeRequest"; Notify.note_merge_request_email(u.id, note.id).deliver
      when "Wall"; Notify.note_wall_email(u.id, note.id).deliver
      when "Snippet"; true # no notifications for snippets?
      else
        true
      end
    end
  end

  def team_without_note_author(note)
    note.project.users.reject { |u| u.id == note.author.id }
  end
end
