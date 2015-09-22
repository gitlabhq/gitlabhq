# EventCreateService class
#
# Used for creating events feed on dashboard after certain user action
#
# Ex.
#   EventCreateService.new.new_issue(issue, current_user)
#
class EventCreateService
  def open_issue(issue, current_user)
    create_record_event(issue, current_user, Event::CREATED)
  end

  def close_issue(issue, current_user)
    create_record_event(issue, current_user, Event::CLOSED)
  end

  def reopen_issue(issue, current_user)
    create_record_event(issue, current_user, Event::REOPENED)
  end

  def open_mr(merge_request, current_user)
    create_record_event(merge_request, current_user, Event::CREATED)
  end

  def close_mr(merge_request, current_user)
    create_record_event(merge_request, current_user, Event::CLOSED)
  end

  def reopen_mr(merge_request, current_user)
    create_record_event(merge_request, current_user, Event::REOPENED)
  end

  def merge_mr(merge_request, current_user)
    create_record_event(merge_request, current_user, Event::MERGED)
  end

  def open_milestone(milestone, current_user)
    create_record_event(milestone, current_user, Event::CREATED)
  end

  def close_milestone(milestone, current_user)
    create_record_event(milestone, current_user, Event::CLOSED)
  end

  def reopen_milestone(milestone, current_user)
    create_record_event(milestone, current_user, Event::REOPENED)
  end

  def destroy_milestone(milestone, current_user)
    create_record_event(milestone, current_user, Event::DESTROYED)
  end

  def leave_note(note, current_user)
    create_record_event(note, current_user, Event::COMMENTED)
  end

  def join_project(project, current_user)
    create_event(project, current_user, Event::JOINED)
  end

  def leave_project(project, current_user)
    create_event(project, current_user, Event::LEFT)
  end

  def create_project(project, current_user)
    create_event(project, current_user, Event::CREATED)
  end

  def push(project, current_user, push_data)
    create_event(project, current_user, Event::PUSHED, data: push_data)
  end

  private

  def create_record_event(record, current_user, status)
    create_event(record.project, current_user, status, target_id: record.id, target_type: record.class.name)
  end

  def create_event(project, current_user, status, attributes = {})
    attributes.reverse_merge!(
      project: project,
      action: status,
      author_id: current_user.id
    )

    Event.create(attributes)
  end
end
