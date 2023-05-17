# frozen_string_literal: true

class Projects::Ci::LintsController < Projects::ApplicationController
  before_action :authorize_create_pipeline!

  feature_category :pipeline_composition

  respond_to :json, only: [:create]
  urgency :low, [:create]

  def show
  end

  def create
    content = params[:content]
    dry_run = params[:dry_run]

    result = Gitlab::Ci::Lint
      .new(project: @project, current_user: current_user)
      .validate(content, dry_run: dry_run)

    render json: ::Ci::Lint::ResultSerializer.new.represent(result)
  end
end
