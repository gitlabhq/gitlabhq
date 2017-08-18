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
    url_to(:namespace_project_issue, id: object[:iid].to_s)
  end

  private

  def url_to(route, id)
    public_send("#{route}_url", request.project.namespace, request.project, id) # rubocop:disable GitlabSecurity/PublicSend
  end
end
