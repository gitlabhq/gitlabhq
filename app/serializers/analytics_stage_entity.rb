class AnalyticsStageEntity < Grape::Entity
  include EntityDateHelper

  expose :title
  expose :name
  expose :legend
  expose :description

  expose :median, as: :value do |stage|
    if stage.median && !(stage.median.nil? || stage.median.zero?)
      distance_of_time_in_words(stage.median)
    end
  end
end
