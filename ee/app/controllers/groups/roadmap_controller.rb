module Groups
  class RoadmapController < Groups::ApplicationController
    include IssuableCollections
    include EpicsActions

    before_action :check_epics_available!
    before_action :group
    before_action :persist_roadmap_layout, only: [:show]

    def show
      # show roadmap for a group
      set_sort_order_from_cookie
      @sort = params[:sort] || default_sort_order
      @epics_count = EpicsFinder.new(current_user, group_id: @group.id).execute.count
    end

    private

    def persist_roadmap_layout
      return unless current_user

      roadmap_layout = params[:layout]&.downcase

      return unless User.roadmap_layouts[roadmap_layout]
      return if current_user.roadmap_layout == roadmap_layout

      Users::UpdateService.new(current_user, user: current_user, roadmap_layout: roadmap_layout).execute
    end
  end
end
