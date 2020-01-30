# frozen_string_literal: true

module API
  module Entities
    class ProjectDailyStatistics < Grape::Entity
      expose :fetches do
        expose :total_fetch_count, as: :total
        expose :fetches, as: :days, using: ProjectDailyFetches
      end
    end
  end
end
