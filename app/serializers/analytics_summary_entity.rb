# frozen_string_literal: true

class AnalyticsSummaryEntity < Grape::Entity
  expose :value, safe: true
  expose :title
  expose :unit, if: { with_unit: true }

  private

  def value
    object.value.to_s
  end
end
