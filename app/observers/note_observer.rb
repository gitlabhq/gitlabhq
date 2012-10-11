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
    notify_method = 'note_' + note.noteable_type.underscore + '_email'

    if Notify.respond_to? notify_method
      team_without_note_author(note).map do |u|
        Notify.send(notify_method.to_sym, u.id, note.id).deliver
      end
    end
  end

  def team_without_note_author(note)
    note.project.users.reject { |u| u.id == note.author.id }
  end
end
