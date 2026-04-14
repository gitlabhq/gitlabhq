# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        class StartAndDueDate < Grape::Entity
          expose :start_date,
            documentation: { type: 'Date', example: '2022-08-17' },
            expose_nil: true

          expose :due_date,
            documentation: { type: 'Date', example: '2022-08-30' },
            expose_nil: true

          expose :roll_up, documentation: { type: 'Boolean', example: false } do |widget, _|
            widget.can_rollup?
          end
        end
      end
    end
  end
end

::API::Entities::WorkItems::Features::StartAndDueDate.prepend_mod
