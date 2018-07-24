# frozen_string_literal: true

module TimeTrackableEntity
  extend ActiveSupport::Concern
  extend Grape

  included do
    expose :time_estimate
    expose :total_time_spent
    expose :human_time_estimate
    expose :human_total_time_spent
  end
end
