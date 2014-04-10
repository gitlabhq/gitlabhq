class MilestoneObserver < BaseObserver
  def after_create(milestone)
    event_service.open_milestone(milestone, current_user)
  end

  def after_close(milestone, transition)
    event_service.close_milestone(milestone, current_user)
  end

  def after_reopen(milestone, transition)
    event_service.reopen_milestone(milestone, current_user)
  end
end
