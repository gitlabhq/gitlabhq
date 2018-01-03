class IssuableSidebarEntity < Grape::Entity
  include TimeTrackableEntity
  include RequestAwareEntity

  expose :participants, using: ::API::Entities::UserBasic do |issuable|
    issuable.participants(request.current_user)
  end

  expose :subscribed do |issuable|
    issuable.subscribed?(request.current_user, issuable.project)
  end
end
