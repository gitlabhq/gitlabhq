# frozen_string_literal: true

module API
  module Entities
    class ProjectDailyStatistics < Grape::Entity
      expose :fetches do
        expose :total_fetch_count, as: :total, documentation: { type: 'integer', example: 3 }
        expose :fetches, as: :days, using: ProjectDailyFetches, documentation: { is_array: true }
      end
    end
  end
end
