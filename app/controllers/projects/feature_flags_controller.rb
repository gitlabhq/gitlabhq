# frozen_string_literal: true

class Projects::FeatureFlagsController < Projects::ApplicationController
  respond_to :html

  before_action :authorize_read_feature_flag!
  before_action :authorize_create_feature_flag!, only: [:new, :create]
  before_action :authorize_update_feature_flag!, only: [:edit, :update]
  before_action :authorize_destroy_feature_flag!, only: [:destroy]

  before_action :feature_flag, only: [:edit, :update, :destroy]

  feature_category :feature_flags
  urgency :low

  def index
    @feature_flags = FeatureFlagsFinder
      .new(project, current_user, scope: params[:scope])
      .execute
      .page(params[:page])
      .per(30)

    respond_to do |format|
      format.html
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: 10_000)

        render json: { feature_flags: feature_flags_json }.merge(summary_json)
      end
    end
  end

  def new; end

  def show
    respond_to do |format|
      format.json do
        Gitlab::PollingInterval.set_header(response, interval: 10_000)

        render_success_json(feature_flag)
      end
    end
  end

  def create
    result = FeatureFlags::CreateService.new(project, current_user, create_params).execute

    if result[:status] == :success
      respond_to do |format|
        format.json { render_success_json(result[:feature_flag]) }
      end
    else
      respond_to do |format|
        format.json { render_error_json(result[:message]) }
      end
    end
  end

  def edit; end

  def update
    result = FeatureFlags::UpdateService.new(project, current_user, update_params).execute(feature_flag)

    if result[:status] == :success
      respond_to do |format|
        format.json { render_success_json(result[:feature_flag]) }
      end
    else
      respond_to do |format|
        format.json { render_error_json(result[:message], result[:http_status]) }
      end
    end
  end

  def destroy
    result = FeatureFlags::DestroyService.new(project, current_user).execute(feature_flag)

    if result[:status] == :success
      respond_to do |format|
        format.html { redirect_to_index(notice: _('Feature flag was successfully removed.')) }
        format.json { render_success_json(feature_flag) }
      end
    else
      respond_to do |format|
        format.html { redirect_to_index(alert: _('Feature flag was not removed.')) }
        format.json { render_error_json(result[:message]) }
      end
    end
  end

  protected

  def feature_flag
    @feature_flag ||= @noteable = project.operations_feature_flags.find_by_iid!(params[:iid])
  end

  def create_params
    params.require(:operations_feature_flag).permit(
      :name,
      :description,
      :active,
      :version,
      scopes_attributes: [
        :environment_scope, :active,
        { strategies: [:name, { parameters: [:groupId, :percentage, :userIds] }] }
      ],
      strategies_attributes: [
        :name,
        :user_list_id,
        { parameters: [:groupId, :percentage, :userIds, :rollout, :stickiness],
          scopes_attributes: [:environment_scope] }
      ]
    )
  end

  def update_params
    params.require(:operations_feature_flag).permit(
      :name,
      :description,
      :active,
      scopes_attributes: [
        :id,
        :environment_scope,
        :active,
        :_destroy,
        { strategies: [:name, { parameters: [:groupId, :percentage, :userIds] }] }
      ],
      strategies_attributes: [
        :id,
        :name,
        :user_list_id,
        :_destroy,
        { parameters: [:groupId, :percentage, :userIds, :rollout, :stickiness],
          scopes_attributes: [:id, :environment_scope, :_destroy] }
      ]
    )
  end

  def feature_flag_json(feature_flag)
    FeatureFlagSerializer
      .new(project: @project, current_user: @current_user)
      .represent(feature_flag)
  end

  def feature_flags_json
    FeatureFlagSerializer
      .new(project: @project, current_user: @current_user)
      .with_pagination(request, response)
      .represent(@feature_flags)
  end

  def summary_json
    FeatureFlagSummarySerializer
      .new(project: @project, current_user: @current_user)
      .represent(@project)
  end

  def redirect_to_index(**args)
    redirect_to project_feature_flags_path(@project), status: :found, **args
  end

  def render_success_json(feature_flag)
    render json: feature_flag_json(feature_flag), status: :ok
  end

  def render_error_json(messages, status = :bad_request)
    render json: { message: messages }, status: status
  end
end
