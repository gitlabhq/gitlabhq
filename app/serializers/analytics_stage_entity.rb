# frozen_string_literal: true

class AnalyticsStageEntity < Grape::Entity
  include EntityDateHelper

  expose :title
  expose :name
  expose :legend
  expose :description

  expose :project_median, as: :value
end
