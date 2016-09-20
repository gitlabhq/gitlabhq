class Dashboard::LabelsController < Dashboard::ApplicationController
  def index
    respond_to do |format|
      format.json { render json: LabelsFinder.new(current_user).execute }
    end
  end
end
