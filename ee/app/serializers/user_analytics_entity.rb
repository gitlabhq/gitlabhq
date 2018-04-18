class UserAnalyticsEntity < Grape::Entity
  include RequestAwareEntity

  EVENT_TYPES = [:push, :issues_created, :issues_closed, :merge_requests_created,
                 :merge_requests_merged, :total_events].freeze

  expose :username

  expose :name, as: :fullname

  expose :user_web_url do |user|
    user_path(user)
  end

  EVENT_TYPES.each do |event_type|
    expose event_type do |user|
      request.events[event_type].fetch(user.id, 0)
    end
  end
end
