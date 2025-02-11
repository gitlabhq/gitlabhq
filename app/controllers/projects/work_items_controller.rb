# frozen_string_literal: true

class Projects::WorkItemsController < Projects::ApplicationController
  include WorkhorseAuthorization
  extend Gitlab::Utils::Override

  EXTENSION_ALLOWLIST = %w[csv].map(&:downcase).freeze

  before_action :authorize_import_access!, only: [:import_csv, :authorize] # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action do
    push_frontend_feature_flag(:notifications_todos_buttons)
    push_force_frontend_feature_flag(:work_items, project&.work_items_feature_flag_enabled?)
    push_force_frontend_feature_flag(:work_items_beta, project&.work_items_beta_feature_flag_enabled?)
    push_force_frontend_feature_flag(:work_items_alpha, project&.work_items_alpha_feature_flag_enabled?)
    push_force_frontend_feature_flag(:glql_integration, project&.glql_integration_feature_flag_enabled?)
    push_force_frontend_feature_flag(:continue_indented_text, project&.continue_indented_text_feature_flag_enabled?)
    push_frontend_feature_flag(:namespace_level_work_items, project&.group)
    push_frontend_feature_flag(:work_item_description_templates, project&.group)
  end

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

  def show
    return if show_params[:iid] == 'new'

    @work_item = ::WorkItems::WorkItemsFinder.new(current_user, project_id: project.id)
      .execute.with_work_item_type.find_by_iid(show_params[:iid])
  end

  private

  def import_params
    params.permit(:file)
  end

  def show_params
    params.permit(:iid)
  end

  def authorize_import_access!
    can_import = can?(current_user, :import_work_items, project)
    import_csv_feature_available = Feature.enabled?(:import_export_work_items_csv, project)
    return if can_import && import_csv_feature_available

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
end

Projects::WorkItemsController.prepend_mod
