class AnalyticsGenericEntity < Grape::Entity
  include RequestAwareEntity
  include ActionView::Helpers::DateHelper


  expose :title
  expose :iid
  expose :started_at, as: :date
  expose :author, using: UserEntity

  expose :total_time do |object|
    distance_of_time_in_words(object[:total_time].to_f)
  end

  expose(:date) do |object|
    interval_in_words(object[:created_at])
  end

  expose :url do |object|
    url_to("namespace_project_#{object[:entity]}".to_sym, id: object[:iid].to_s)
  end

  private

  def url_to(route, id = nil)
    public_send("#{route}_url", options[:project].namespace, options[:project], id)
  end

  def interval_in_words(diff)
    "#{distance_of_time_in_words(diff.to_f)} ago"
  end
end
