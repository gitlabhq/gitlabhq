class ActivityObserver < ActiveRecord::Observer
  observe :issue, :merge_request, :note

  def after_create(record)
    Event.create(
      :project => record.project,
      :target_id => record.id,
      :target_type => record.class.name,
      :action => Event.determine_action(record)
    )
  end
end
