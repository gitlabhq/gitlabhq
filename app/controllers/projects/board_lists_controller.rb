class Projects::BoardListsController < Projects::ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def create
    list = Boards::Lists::CreateService.new(project, list_params).execute

    respond_to do |format|
      if list.valid?
        format.json { render json: list.as_json(only: [:id, :list_type, :position], methods: [:title], include: { label: { only: [:id, :title, :color] } }) }
      else
        format.json { render json: list.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    service = Boards::Lists::MoveService.new(project, move_params)

    respond_to do |format|
      if service.execute
        format.json { head :ok }
      else
        format.json { head :unprocessable_entity }
      end
    end
  end

  def destroy
    service = Boards::Lists::DestroyService.new(project, params)

    respond_to do |format|
      if service.execute
        format.json { head :ok }
      else
        format.json { head :unprocessable_entity }
      end
    end
  end

  private

  def record_not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def list_params
    params.require(:list).permit(:label_id)
  end

  def move_params
    params.require(:list).permit(:position).merge(id: params[:id])
  end
end
