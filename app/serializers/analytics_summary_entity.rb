class AnalyticsSummaryEntity < Grape::Entity
  expose :value, safe: true

  expose :title do |object|
    object.title.pluralize(object.value)
  end
end
