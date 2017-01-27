class Projects::BoardsController < Projects::ApplicationController
  include IssuableCollections

  # before_action :authorize_read_board!, only: [:index, :show, :backlog]

  def index
    @boards = ::Boards::ListService.new(project, current_user).execute

    respond_to do |format|
      format.html
      format.json do
        render json: serialize_as_json(@boards)
      end
    end
  end

  def show
    @board = project.boards.find(params[:id])

    respond_to do |format|
      format.html
      format.json do
        render json: serialize_as_json(@board)
      end
    end
  end

  def backlog
    board = project.boards.find(params[:id])

    @issues = issues_collection
    @issues = @issues.where.not(
      LabelLink.where("label_links.target_type = 'Issue' AND label_links.target_id = issues.id")
               .where(label_id: board.lists.movable.pluck(:label_id)).limit(1).arel.exists
    )
    @issues = @issues.page(params[:page]).per(params[:per])

    render json: @issues.as_json(
      labels: true,
      only: [:id, :iid, :title, :confidential, :due_date],
      include: {
        assignee: { only: [:id, :name, :username], methods: [:avatar_url] },
        milestone: { only: [:id, :title] }
      },
      user: current_user
    )
  end

  private

  def authorize_read_board!
    return access_denied! unless can?(current_user, :read_board, project)
  end

  def serialize_as_json(resource)
    resource.as_json(only: [:id])
  end
end
