class Groups::EpicIssuesController < Groups::EpicsController
  include IssuableLinks

  skip_before_action :authorize_destroy_issuable!
  skip_before_action :authorize_create_epic!
  skip_before_action :authorize_update_issuable!

  before_action :authorize_admin_epic!, only: [:create, :destroy, :update]
  before_action :authorize_issue_link_association!, only: [:destroy, :update]

  def update
    result = EpicIssues::UpdateService.new(link, current_user, params[:epic]).execute

    render json: { message: result[:message] }, status: result[:http_status]
  end

  private

  def create_service
    EpicIssues::CreateService.new(epic, current_user, create_params)
  end

  def destroy_service
    EpicIssues::DestroyService.new(link, current_user)
  end

  def issues
    EpicIssues::ListService.new(epic, current_user).execute
  end

  def authorize_admin_epic!
    render_403 unless can?(current_user, :admin_epic, epic)
  end

  def authorize_issue_link_association!
    render_404 if link.epic != epic
  end

  def link
    @link ||= EpicIssue.find(params[:id])
  end
end
