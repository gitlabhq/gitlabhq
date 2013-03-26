class NoteObserver < BaseObserver
  def after_create(note)
    notification.new_note(note)
  end
end
