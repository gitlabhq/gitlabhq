class Projects::BoardListsController < Projects::ApplicationController
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

  private

  def list_params
    params.require(:list).permit(:label_id)
  end
end
