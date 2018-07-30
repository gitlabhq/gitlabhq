# frozen_string_literal: true

class NewEpicWorker
  include ApplicationWorker
  include NewIssuable

  def perform(epic_id, user_id)
    return unless objects_found?(epic_id, user_id)

    NotificationService.new.new_epic(issuable)
    issuable.create_cross_references!(user)
  end

  def issuable_class
    Epic
  end
end
