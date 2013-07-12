class ProjectActivityCacheObserver < BaseObserver
  observe :event

  def after_create(event)
    # Commit Email Push
    #log_info "Is Push ? #{ event.action == Event::PUSHED } #{ event.project }, #{ event.author_id }"
    notification.receive_commit(event) if event.action == Event::PUSHED

    event.project.update_column(:last_activity_at, event.created_at) if event.project
  end
end

