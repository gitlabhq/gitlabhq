# frozen_string_literal: true

class IssuableSidebarExtrasEntity < Grape::Entity
  include RequestAwareEntity
  include TimeTrackableEntity

  expose :assignees, using: ::API::Entities::UserBasic
end
