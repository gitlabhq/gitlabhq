# frozen_string_literal: true

class GroupAnalyticsStageEntity < Grape::Entity
  include EntityDateHelper

  expose :title
  expose :name
  expose :legend
  expose :description

  expose :group_median, as: :value do |stage|
    # median returns a BatchLoader instance which we first have to unwrap by using to_f
    # we use to_f to make sure results below 1 are presented to the end-user
    stage.group_median.to_f.nonzero? ? distance_of_time_in_words(stage.group_median) : nil
  end
end
