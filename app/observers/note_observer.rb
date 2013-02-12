class NoteObserver < ActiveRecord::Observer

  def after_create(note)
    send_notify_mails(note)
  end

  protected

  def send_notify_mails(note)
    if note.notify
      notify_team(note)
    elsif note.notify_author
      # Notify only author of resource
      if note.commit_author
        Notify.delay.note_commit_email(note.commit_author.id, note.id)
      end
    else
      # Otherwise ignore it
      nil
    end
  end

  # Notifies the whole team except the author of note
  def notify_team(note)
    # Note: wall posts are not "attached" to anything, so fall back to "Wall"
    noteable_type = note.noteable_type.presence || "Wall"
    notify_method = "note_#{noteable_type.underscore}_email".to_sym

    if Notify.respond_to? notify_method
      team_without_note_author(note).map do |u|
        Notify.delay.send(notify_method, u.id, note.id)
      end
    end
  end

  def team_without_note_author(note)
    note.project.users.reject { |u| u.id == note.author.id }
  end
end
