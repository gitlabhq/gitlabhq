class AnalyticsStageEntity < Grape::Entity
  include EntityDateHelper

  expose :title
  expose :description

  expose :median, as: :value do |stage|
    stage.median && !stage.median.zero? ? distance_of_time_in_words(stage.median) : nil
  end
end
