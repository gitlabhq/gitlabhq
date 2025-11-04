# frozen_string_literal: true

class Projects::WorkItemsController < Projects::ApplicationController
  include WorkhorseAuthorization
  include WorkItemsCollections
  extend Gitlab::Utils::Override

  EXTENSION_ALLOWLIST = %w[csv].map(&:downcase).freeze

  before_action :authorize_import_access!, only: [:import_csv, :authorize] # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action do
    push_frontend_feature_flag(:notifications_todos_buttons, current_user)
    push_force_frontend_feature_flag(:work_items_alpha, !!project&.work_items_alpha_feature_flag_enabled?)
    push_force_frontend_feature_flag(:glql_load_on_click, !!project&.glql_load_on_click_feature_flag_enabled?)
    push_force_frontend_feature_flag(:work_item_planning_view,
      !!project&.work_items_consolidated_list_enabled?(current_user))
  end

  before_action :check_search_rate_limit!, if: ->(c) do
    c.action_name.to_sym == :calendar || c.action_name.to_sym == :rss
  end

  prepend_before_action(only: [:calendar]) { authenticate_sessionless_user!(:ics) }
  prepend_before_action(only: [:rss]) { authenticate_sessionless_user!(:rss) }

  feature_category :team_planning
  urgency :high, [:authorize]
  urgency :low

  def import_csv
    file = import_params[:file]
    return render json: { errors: invalid_file_message }, status: :bad_request unless file_is_valid?(file)

    result = WorkItems::PrepareImportCsvService.new(project, current_user, file: file).execute

    if result.status == :error
      render json: { errors: result.message }, status: :bad_request
    else
      render json: { message: result.message }, status: :ok
    end
  end

  def index
    not_found unless project&.work_items_consolidated_list_enabled?(current_user)
  end

  def show
    return if show_params[:iid] == 'new'

    @work_item = issuable
  end

  def calendar
    @work_items = work_items_for_calendar

    respond_to do |format|
      format.ics do
        response.headers['Content-Type'] = 'text/plain' if request.referer&.start_with?(::Settings.gitlab.base_url)
      end
    end
  end

  def rss
    @work_items = work_items_for_rss

    respond_to do |format|
      format.atom { render layout: 'xml' }
    end
  end

  private

  def import_params
    params.permit(:file)
  end

  def show_params
    params.permit(:iid)
  end

  def authorize_import_access!
    return if can?(current_user, :import_work_items, project)

    if current_user || action_name == 'authorize'
      render_404
    else
      authenticate_user!
    end
  end

  def invalid_file_message
    supported_file_extensions = ".#{EXTENSION_ALLOWLIST.join(', .')}"
    format(_("The uploaded file was invalid. Supported file extensions are %{extensions}."),
      { extensions: supported_file_extensions })
  end

  def uploader_class
    FileUploader
  end

  def maximum_size
    Gitlab::CurrentSettings.max_attachment_size.megabytes
  end

  def file_extension_allowlist
    EXTENSION_ALLOWLIST
  end

  def issuable
    @issuable ||= ::WorkItems::WorkItemsFinder.new(current_user, project_id: project.id)
      .execute.with_work_item_type
      .find_by_iid(show_params[:iid])
  end
end

Projects::WorkItemsController.prepend_mod
