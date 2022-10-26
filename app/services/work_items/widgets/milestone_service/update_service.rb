# frozen_string_literal: true

module WorkItems
  module Widgets
    module MilestoneService
      class UpdateService < WorkItems::Widgets::MilestoneService::BaseService
        def before_update_callback(params:)
          handle_milestone_change(params: params)
        end
      end
    end
  end
end
