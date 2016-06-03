class Dashboard::LabelsController < Dashboard::ApplicationController
  def index
    labels = Label.where(project_id: projects).select(:title, :color).uniq(:title)

    respond_to do |format|
      format.json { render json: labels }
    end
  end
end
