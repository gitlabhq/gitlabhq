class NoteObserver < ActiveRecord::Observer
  def after_create(note)
    notification.new_note(note)
  end

  protected

  def notification
    NotificationService.new
  end
end
