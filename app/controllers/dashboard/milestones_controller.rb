class Dashboard::MilestonesController < Dashboard::ApplicationController
  include GlobalMilestones

  before_action :projects
  before_action :milestones, only: [:index]
  before_action :milestone, only: [:show]

  def index
  end

  def show
  end

  private

  def projects
    @projects ||= current_user.authorized_projects.sorted_by_activity.non_archived
  end
end
