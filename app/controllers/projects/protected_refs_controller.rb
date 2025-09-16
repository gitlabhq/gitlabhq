# frozen_string_literal: true

class Projects::ProtectedRefsController < Projects::ApplicationController
  include RepositorySettingsRedirect

  # Authorize
  before_action :authorize_admin_protected_refs!
  before_action :load_protected_ref, only: [:show, :update, :destroy]

  layout "project_settings"

  feature_category :source_code_management

  def index
    redirect_to_repository_settings(@project)
  end

  def create
    protected_ref = create_service_class.new(@project, current_user, protected_ref_params).execute

    flash[:alert] = protected_ref.errors.full_messages.join(', ').html_safe unless protected_ref.persisted?

    respond_to do |format|
      format.html { redirect_to_repository_settings(@project, anchor: params[:update_section]) }
      format.json { head :ok }
    end
  end

  def show
    service_params = params.merge(ref_type: ref_type, search: @protected_ref.name)

    @matching_refs, @prev_path, @next_path = Projects::RefsByPaginationService.new(
      @protected_ref,
      @project,
      service_params
    ).execute
  rescue Gitlab::Git::InvalidPageToken
    flash[:alert] = 'Invalid page token'
  end

  def update
    @protected_ref = update_service_class.new(@project, current_user, protected_ref_params).execute(@protected_ref)

    if @protected_ref.valid?
      render json: @protected_ref, status: :ok, include: access_levels
    else
      render json: @protected_ref.errors, status: :unprocessable_entity
    end
  end

  def destroy
    destroy_service_class.new(@project, current_user).execute(@protected_ref)

    respond_to do |format|
      format.html { redirect_to_repository_settings(@project, anchor: params[:update_section]) }
      format.js { head :ok }
    end
  end

  protected

  def create_service_class
    service_namespace::CreateService
  end

  def update_service_class
    service_namespace::UpdateService
  end

  def destroy_service_class
    service_namespace::DestroyService
  end

  def access_level_attributes
    %i[access_level id _destroy deploy_key_id]
  end

  def authorize_admin_protected_refs!
    authorize_admin_project!
  end
end

Projects::ProtectedRefsController.prepend_mod_with('Projects::ProtectedRefsController')
