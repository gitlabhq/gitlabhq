class Groups::EpicIssuesController < Groups::EpicsController
  include IssuableLinks

  skip_before_action :authorize_destroy_issuable!
  before_action :authorize_admin_epic!, only: [:create, :destroy]

  private

  def create_service
    EpicIssues::CreateService.new(epic, current_user, create_params)
  end

  def destroy_service
    epic_issue = EpicIssue.find(params[:id])
    EpicIssues::DestroyService.new(epic_issue, current_user)
  end

  def issues
    EpicIssues::ListService.new(epic, current_user).execute
  end

  def authorize_admin_epic!
    render_403 unless can?(current_user, :admin_epic, epic)
  end
end
