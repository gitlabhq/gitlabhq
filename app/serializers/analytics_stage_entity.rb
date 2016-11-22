class AnalyticsStageEntity < Grape::Entity
  include EntityDateHelper

  expose :stage, as: :title do |object|
    object.stage.to_s.capitalize
  end
  expose :description

  expose :median, as: :value do |stage|
    stage.median && !stage.median.zero? ? distance_of_time_in_words(stage.median) : nil
  end
end
