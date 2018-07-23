module Groups
  class RoadmapController < Groups::ApplicationController
    before_action :group
    before_action :persist_roadmap_layout, only: [:show]

    def show
      # show roadmap for a group
      @epics_count = EpicsFinder.new(current_user, group_id: @group.id).execute.count
    end

    private

    def persist_roadmap_layout
      return unless current_user
      return unless User.roadmap_layouts[params[:layout]]
      return if current_user.roadmap_layout == params[:layout]

      Users::UpdateService.new(current_user, user: current_user, roadmap_layout: params[:layout]).execute
    end
  end
end
