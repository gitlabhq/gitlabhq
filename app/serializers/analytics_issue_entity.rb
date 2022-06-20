# frozen_string_literal: true

class AnalyticsIssueEntity < Grape::Entity
  include RequestAwareEntity
  include EntityDateHelper

  expose :title
  expose :author, using: UserEntity
  expose :project_path do |object|
    object[:project_path]
  end

  expose :namespace_full_path do |object|
    object[:namespace_path]
  end

  expose :iid do |object|
    object[:iid].to_s
  end

  expose :total_time do |object|
    distance_of_time_as_hash(object[:total_time].to_f)
  end

  expose(:created_at) do |object|
    interval_in_words(object[:created_at])
  end

  expose :url do |object|
    url_to(:namespace_project_issue, object)
  end

  expose :end_event_timestamp do |object|
    object[:end_event_timestamp] && interval_in_words(object[:end_event_timestamp])
  end

  private

  def url_to(route, object)
    public_send("#{route}_url", object[:namespace_path], object[:project_path], object[:iid].to_s) # rubocop:disable GitlabSecurity/PublicSend
  end
end
