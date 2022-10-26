# frozen_string_literal: true

module WorkItems
  module Widgets
    module MilestoneService
      class CreateService < WorkItems::Widgets::MilestoneService::BaseService
        def before_create_callback(params:)
          handle_milestone_change(params: params)
        end
      end
    end
  end
end
