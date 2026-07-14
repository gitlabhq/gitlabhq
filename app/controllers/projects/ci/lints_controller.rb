# frozen_string_literal: true

class Projects::Ci::LintsController < Projects::ApplicationController
  before_action :authorize_create_pipeline!

  feature_category :pipeline_composition

  respond_to :json, only: [:create]
  urgency :low, [:show, :create]

  def show; end

  def create
    content = safe_params[:content]
    dry_run = safe_params[:dry_run]

    result = Gitlab::Ci::Lint
      .new(project: @project, current_user: current_user)
      .legacy_validate(content, dry_run: dry_run)

    render json: ::Ci::Lint::ResultSerializer.new.represent(result)
  rescue Gitlab::Ci::Lint::RateLimitError
    response.set_header('Retry-After', Gitlab::ApplicationRateLimiter.interval(:ci_lint).to_s)
    render json: { error: _('This endpoint has been requested too many times. Try again later.') },
      status: :too_many_requests
  end

  def safe_params
    params.permit(:content, :dry_run)
  end
end
