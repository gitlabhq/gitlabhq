module Groups
  class RoadmapController < Groups::ApplicationController
    before_action :group

    def show
      # show roadmap for a group
      @epics_count = EpicsFinder.new(current_user, group_id: @group.id).execute.count
    end
  end
end
