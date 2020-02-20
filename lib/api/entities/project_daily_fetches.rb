# frozen_string_literal: true

module API
  module Entities
    class ProjectDailyFetches < Grape::Entity
      expose :fetch_count, as: :count
      expose :date
    end
  end
end
