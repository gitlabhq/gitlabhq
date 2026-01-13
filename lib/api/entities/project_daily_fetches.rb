# frozen_string_literal: true

module API
  module Entities
    class ProjectDailyFetches < Grape::Entity
      expose :fetch_count, as: :count, documentation: { type: 'Integer', example: 3 }
      expose :date, documentation: { type: 'Date', example: '2022-01-01' }
    end
  end
end
