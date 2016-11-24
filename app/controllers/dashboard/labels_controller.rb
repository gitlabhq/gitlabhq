class Dashboard::LabelsController < Dashboard::ApplicationController
  def index
    labels = LabelsFinder.new(current_user).execute

    respond_to do |format|
      format.json { render json: labels.as_json(only: [:id, :title, :color]) }
    end
  end
end
