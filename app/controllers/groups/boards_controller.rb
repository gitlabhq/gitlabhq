class Groups::BoardsController < Groups::ApplicationController
  before_action :check_group_issue_boards_available!

  def index
    @boards = ::Boards::ListService.new(group, current_user).execute

    respond_to do |format|
      format.html
      format.json do
        render json: serialize_as_json(@boards)
      end
    end
  end
end
