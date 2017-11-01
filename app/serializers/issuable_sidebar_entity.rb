class IssuableSidebarEntity < Grape::Entity
  include RequestAwareEntity

  expose :participants, using: ::API::Entities::UserBasic do |issuable|
    issuable.participants(request.current_user)
  end

  expose :subscribed do |issuable|
    issuable.subscribed?(request.current_user, issuable.project)
  end

  expose :time_estimate
  expose :total_time_spent
  expose :human_time_estimate
  expose :human_total_time_spent
end
