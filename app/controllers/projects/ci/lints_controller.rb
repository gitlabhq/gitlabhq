# frozen_string_literal: true

class Projects::Ci::LintsController < Projects::ApplicationController
  before_action :authorize_create_pipeline!
  before_action do
    push_frontend_feature_flag(:ci_lint_vue, project, default_enabled: true)
  end

  feature_category :pipeline_authoring

  def show
  end

  def create
    @content = params[:content]
    @dry_run = params[:dry_run]

    @result = Gitlab::Ci::Lint
      .new(project: @project, current_user: current_user)
      .validate(@content, dry_run: @dry_run)

    respond_to do |format|
      format.html { render :show }
      format.json do
        render json: ::Ci::Lint::ResultSerializer.new.represent(@result)
      end
    end
  end
end
