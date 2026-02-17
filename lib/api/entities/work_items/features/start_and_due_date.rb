# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        class StartAndDueDate < Grape::Entity
          expose :start_date, documentation: { type: 'Date', example: '2022-08-17' }
          expose :due_date, documentation: { type: 'Date', example: '2022-08-30' }
        end
      end
    end
  end
end
