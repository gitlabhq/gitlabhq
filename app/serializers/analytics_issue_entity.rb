# frozen_string_literal: true

class AnalyticsIssueEntity < Grape::Entity
  include RequestAwareEntity
  include EntityDateHelper

  expose :title
  expose :author, using: UserEntity

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

  private

  def url_to(route, object)
    public_send("#{route}_url", object[:path], object[:name], object[:iid].to_s) # rubocop:disable GitlabSecurity/PublicSend
  end
end
