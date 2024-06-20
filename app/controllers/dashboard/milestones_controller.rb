# frozen_string_literal: true

class Dashboard::MilestonesController < Dashboard::ApplicationController
  before_action :projects
  before_action :groups, only: :index

  feature_category :team_planning
  urgency :low

  def index
    respond_to do |format|
      format.html do
        @milestone_states = Milestone.states_count(@projects.select(:id), groups.select(:id))
        @milestones = milestones.page(pagination_params[:page])
      end
      format.json do
        render json: milestones.to_json(only: [:id, :title, :due_date], methods: :name)
      end
    end
  end

  private

  def milestones
    MilestonesFinder.new(search_params).execute
  end

  def groups
    @groups ||= GroupsFinder.new(current_user, all_available: false).execute
  end

  def search_params
    params.permit(:state, :search_title).merge(group_ids: groups, project_ids: projects)
  end
end
