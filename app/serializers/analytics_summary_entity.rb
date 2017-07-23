class AnalyticsSummaryEntity < Grape::Entity
  expose :value, safe: true
  expose :title
end
