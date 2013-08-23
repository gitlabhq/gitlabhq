class ProjectActivityCacheObserver < BaseObserver
  observe :event

  def after_create(event)
    event.project.update_column(:last_activity_at, event.created_at) if event.project
    
    if event.project && event.action == Event::PUSHED
        notification.receive_commit(event)
    end
  end
end

