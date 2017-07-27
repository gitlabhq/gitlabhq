class Groups::BoardsController < Groups::ApplicationController
  prepend EE::Boards::BoardsController

  before_action :check_group_issue_boards_available!
  before_action :assign_endpoint_vars

  def index
    @boards = Boards::ListService.new(group, current_user).execute

    respond_to do |format|
      format.html
      format.json do
        render json: serialize_as_json(@boards)
      end
    end
  end

  def assign_endpoint_vars
    @boards_endpoint = group_boards_path(group)
    @issues_path = issues_group_path(group)
    @bulk_issues_path = ""
  end
end
