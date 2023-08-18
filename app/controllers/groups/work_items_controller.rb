# frozen_string_literal: true

module Groups
  class WorkItemsController < Groups::ApplicationController
    feature_category :team_planning

    def index
      not_found unless Feature.enabled?(:namespace_level_work_items, group)
    end
  end
end
