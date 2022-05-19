# frozen_string_literal: true

class Dashboard::LabelsController < Dashboard::ApplicationController
  feature_category :team_planning
  urgency :low

  def index
    respond_to do |format|
      format.json { render json: LabelSerializer.new.represent_appearance(labels) }
    end
  end

  def labels
    finder_params = { project_ids: projects.select(:id) }

    LabelsFinder.new(current_user, finder_params).execute
      .select('DISTINCT ON (labels.title) labels.*')
  end
end
