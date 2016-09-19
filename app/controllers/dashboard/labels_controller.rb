class Dashboard::LabelsController < Dashboard::ApplicationController
  def index
    labels = LabelsFinder.new(current_user, project_id: projects)
                         .execute
                         .select(:id, :title, :color)
                         .uniq(:title)

    respond_to do |format|
      format.json { render json: labels }
    end
  end
end
