# frozen_string_literal: true

class IssuableSidebarExtrasEntity < Grape::Entity
  include RequestAwareEntity
  include TimeTrackableEntity
  include NotificationsHelper

  expose :participants, using: ::API::Entities::UserBasic do |issuable|
    issuable.participants(request.current_user)
  end

  expose :project_emails_disabled do |issuable|
    issuable.project.emails_disabled?
  end

  expose :subscribe_disabled_description do |issuable|
    notification_description(:owner_disabled)
  end

  expose :subscribed do |issuable|
    issuable.subscribed?(request.current_user, issuable.project)
  end

  expose :assignees, using: API::Entities::UserBasic
end
