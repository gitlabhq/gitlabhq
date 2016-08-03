class Projects::BoardListsController < Projects::ApplicationController
  respond_to :json

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def create
    list = Boards::Lists::CreateService.new(project, current_user, list_params).execute

    if list.valid?
      render json: list.as_json(only: [:id, :list_type, :position], methods: [:title], include: { label: { only: [:id, :title, :color] } })
    else
      render json: list.errors, status: :unprocessable_entity
    end
  end

  def update
    service = Boards::Lists::MoveService.new(project, current_user, move_params)

    if service.execute
      head :ok
    else
      head :unprocessable_entity
    end
  end

  def destroy
    service = Boards::Lists::DestroyService.new(project, current_user, params)

    if service.execute
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def list_params
    params.require(:list).permit(:label_id)
  end

  def move_params
    params.require(:list).permit(:position).merge(id: params[:id])
  end

  def record_not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end
end
