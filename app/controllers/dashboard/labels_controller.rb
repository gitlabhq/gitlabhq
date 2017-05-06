class Dashboard::LabelsController < Dashboard::ApplicationController
  def index
    labels = LabelsFinder.new(current_user).execute

    respond_to do |format|
      format.json { render json: LabelSerializer.new.represent_appearance(labels) }
    end
  end
end
