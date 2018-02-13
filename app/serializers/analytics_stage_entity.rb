class AnalyticsStageEntity < Grape::Entity
  include EntityDateHelper

  expose :title
  expose :name
  expose :legend
  expose :description

  expose :median, as: :value do |stage|
    distance_of_time_in_words(stage.median) if stage.median && !(stage.median.blank? || stage.median.zero?)
  end
end
