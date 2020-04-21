# frozen_string_literal: true

class AnalyticsSummaryEntity < Grape::Entity
  expose :value, safe: true
  expose :title
  expose :unit, if: { with_unit: true }

  private

  def value
    return object.value if object.value.is_a? String

    object.value&.nonzero? ? object.value.to_s : '-'
  end
end
