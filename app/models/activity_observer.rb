class ActivityObserver < ActiveRecord::Observer
  observe :issue, :merge_request

  def after_create(record)
    Event.create(
      :project => record.project,
      :target_id => record.id,
      :target_type => record.class.name,
      :action => Event.determine_action(record),
      :author_id => record.author_id
    )
  end

  def after_save(record)
    if record.changed.include?("closed") 
      Event.create(
        :project => record.project,
        :target_id => record.id,
        :target_type => record.class.name,
        :action => (record.closed ? Event::Closed : Event::Reopened),
        :author_id => record.author_id_of_changes
      )
    end
  end
end
