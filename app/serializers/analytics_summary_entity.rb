# frozen_string_literal: true

class AnalyticsSummaryEntity < Grape::Entity
  expose :value, safe: true
  expose :title
end
