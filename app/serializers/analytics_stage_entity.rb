class AnalyticsStageEntity < Grape::Entity
  include EntityDateHelper

  expose :title
  expose :name
  expose :legend
  expose :description

  expose :medians, as: :values do |stage|
    medians = stage.medians

    unless medians.blank?
      medians.each do |id, median|
        medians[id] = distance_of_time_in_words(median)
      end
    end
  end
end
