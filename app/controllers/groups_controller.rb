# frozen_string_literal: true

class GroupsController < Groups::ApplicationController
  include API::Helpers::RelatedResourcesHelpers
  include IssuableCollectionsAction
  include ParamsBackwardCompatibility
  include PreviewMarkdown
  include RecordUserLastActivity
  include SendFileUpload
  include FiltersEvents
  include Recaptcha::Adapters::ControllerMethods
  extend ::Gitlab::Utils::Override

  respond_to :html

  prepend_before_action(only: [:show, :issues]) { authenticate_sessionless_user!(:rss) }
  prepend_before_action(only: [:issues_calendar]) { authenticate_sessionless_user!(:ics) }
  prepend_before_action :check_captcha, only: :create, if: -> { captcha_enabled? }

  before_action :authenticate_user!, only: [:new, :create]
  before_action :group, except: [:index, :new, :create]

  # Authorize
  before_action :authorize_admin_group!, only: [:edit, :update, :destroy, :projects, :transfer, :export, :download_export]
  before_action :authorize_create_group!, only: [:new]
  before_action :load_recaptcha, only: [:new], if: -> { captcha_required? }

  before_action :group_projects, only: [:projects, :activity, :issues, :merge_requests]
  before_action :event_filter, only: [:activity]

  before_action :user_actions, only: [:show]

  before_action :check_export_rate_limit!, only: [:export, :download_export]

  before_action only: :issues do
    push_frontend_feature_flag(:or_issuable_queries, group)
    push_frontend_feature_flag(:frontend_caching, group)
    push_force_frontend_feature_flag(:work_items, group.work_items_feature_flag_enabled?)
  end

  before_action only: :merge_requests do
    push_frontend_feature_flag(:mr_approved_filter, type: :ops)
  end

  helper_method :captcha_required?

  skip_cross_project_access_check :index, :new, :create, :edit, :update, :destroy, :projects
  # When loading show as an atom feed, we render events that could leak cross
  # project information
  skip_cross_project_access_check :show, if: -> { request.format.html? }

  layout :determine_layout

  feature_category :subgroups, [
    :index, :new, :create, :show, :edit, :update,
    :destroy, :details, :transfer, :activity
  ]

  feature_category :team_planning, [:issues, :issues_calendar, :preview_markdown]
  feature_category :code_review_workflow, [:merge_requests, :unfoldered_environment_names]
  feature_category :projects, [:projects]
  feature_category :importers, [:export, :download_export]
  urgency :low, [:export, :download_export]

  urgency :high, [:unfoldered_environment_names]

  urgency :low, [:issues, :issues_calendar, :preview_markdown]
  # TODO: Set #show to higher urgency after resolving https://gitlab.com/gitlab-org/gitlab/-/issues/334795
  urgency :low, [:merge_requests, :show, :create, :new, :update, :projects, :destroy, :edit, :activity]

  def index
    redirect_to(current_user ? dashboard_groups_path : explore_groups_path)
  end

  def new
    @parent_group = Group.find_by_id(params[:parent_id])
    @group = Group.new(params.permit(:parent_id))
    @group.build_namespace_settings
  end

  def create
    @group = Groups::CreateService.new(current_user, group_params).execute

    if @group.persisted?
      successful_creation_hooks

      notice = if @group.chat_team.present?
                 format(_("Group %{group_name} and its Mattermost team were successfully created."), group_name: @group.name)
               else
                 format(_("Group %{group_name} was successfully created."), group_name: @group.name)
               end

      redirect_to @group, notice: notice
    else
      render action: "new"
    end
  end

  def show
    respond_to do |format|
      format.html do
        if @group.import_state&.in_progress?
          redirect_to group_import_path(@group)
        else
          render_show_html
        end
      end

      format.atom do
        render_details_view_atom
      end
    end
  end

  def details
    respond_to do |format|
      format.html do
        redirect_to group_path(group)
      end

      format.atom do
        render_details_view_atom
      end
    end
  end

  def activity
    respond_to do |format|
      format.html

      format.json do
        load_events
        pager_json("events/_events", @events.count { |event| event.visible_to_user?(current_user) })
      end
    end
  end

  def edit
    @badge_api_endpoint = expose_path(api_v4_groups_badges_path(id: @group.id))
  end

  def projects
    @projects = @group.projects.with_statistics.page(params[:page])
  end

  def update
    if Groups::UpdateService.new(@group, current_user, group_params).execute
      notice = "Group '#{@group.name}' was successfully updated."

      redirect_to edit_group_origin_location, notice: notice
    else
      @group.reset
      render action: "edit"
    end
  end

  def edit_group_origin_location
    if params.dig(:group, :redirect_target) == 'repository_settings'
      group_settings_repository_path(@group, anchor: 'js-default-branch-name')
    else
      edit_group_path(@group, anchor: params[:update_section])
    end
  end

  def destroy
    Groups::DestroyService.new(@group, current_user).async_execute

    redirect_to root_path, status: :found, alert: "Group '#{@group.name}' was scheduled for deletion."
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def transfer
    parent_group = Group.find_by(id: params[:new_parent_group_id])
    service = ::Groups::TransferService.new(@group, current_user)

    if service.execute(parent_group)
      flash[:notice] = "Group '#{@group.name}' was successfully transferred."
      redirect_to group_path(@group)
    else
      flash[:alert] = service.error.html_safe
      redirect_to edit_group_path(@group)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def export
    export_service = Groups::ImportExport::ExportService.new(group: @group, user: current_user)

    if export_service.async_execute
      redirect_to edit_group_path(@group), notice: _('Group export started. A download link will be sent by email and made available on this page.')
    else
      redirect_to edit_group_path(@group), alert: _('Group export could not be started.')
    end
  end

  def download_export
    if @group.export_file_exists?
      if @group.export_archive_exists?
        send_upload(@group.export_file, attachment: @group.export_file.filename)
      else
        redirect_to edit_group_path(@group),
          alert: _('The file containing the export is not available yet; it may still be transferring. Please try again later.')
      end
    else
      redirect_to edit_group_path(@group),
        alert: _('Group export link has expired. Please generate a new export from your group settings.')
    end
  end

  def unfoldered_environment_names
    respond_to do |format|
      format.json do
        render json: Environments::EnvironmentNamesFinder.new(@group, current_user).execute
      end
    end
  end

  def issues
    return super unless html_request?

    @has_issues = IssuesFinder.new(current_user, group_id: group.id, include_subgroups: true).execute
      .non_archived
      .exists?

    @has_projects = group_projects.exists?

    set_sort_order

    respond_to do |format|
      format.html
    end
  end

  protected

  def render_show_html
    Gitlab::Tracking.event('group_overview', 'render', user: current_user, namespace: @group)

    render 'groups/show', locals: { trial: params[:trial] }
  end

  def render_details_view_atom
    load_events
    render layout: 'xml', template: 'groups/show'
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def authorize_create_group!
    allowed = if params[:parent_id].present?
                parent = Group.find_by(id: params[:parent_id])
                can?(current_user, :create_subgroup, parent)
              else
                can?(current_user, :create_group)
              end

    render_404 unless allowed
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def determine_layout
    if [:new, :create].include?(action_name.to_sym)
      'dashboard'
    elsif [:edit, :update, :projects].include?(action_name.to_sym)
      'group_settings'
    else
      'group'
    end
  end

  def group_params
    params.require(:group).permit(group_params_attributes)
  end

  def group_params_attributes
    [
      :avatar,
      :description,
      :emails_disabled,
      :show_diff_preview_in_email,
      :mentions_disabled,
      :lfs_enabled,
      :name,
      :path,
      :public,
      :request_access_enabled,
      :share_with_group_lock,
      :visibility_level,
      :parent_id,
      :create_chat_team,
      :chat_team_name,
      :require_two_factor_authentication,
      :two_factor_grace_period,
      :enabled_git_access_protocol,
      :project_creation_level,
      :subgroup_creation_level,
      :default_branch_protection,
      :default_branch_name,
      :allow_mfa_for_subgroups,
      :resource_access_token_creation_allowed,
      :prevent_sharing_groups_outside_hierarchy,
      :setup_for_company,
      :jobs_to_be_done,
      :crm_enabled
    ] + [group_feature_attributes: group_feature_attributes]
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def load_events
    params[:sort] ||= 'latest_activity_desc'

    options = { include_subgroups: true }
    projects = GroupProjectsFinder.new(params: params, group: group, options: options, current_user: current_user)
                 .execute
                 .includes(:namespace)

    @events = EventCollection
      .new(projects, offset: params[:offset].to_i, filter: event_filter, groups: groups)
      .to_a
      .map(&:present)

    Events::RenderService
      .new(current_user)
      .execute(@events, atom_request: request.format.atom?)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def user_actions
    if current_user
      @notification_setting = current_user.notification_settings_for(group)
    end
  end

  def build_canonical_path(group)
    return group_path(group) if action_name == 'show' # root group path

    params[:id] = group.to_param

    url_for(safe_params)
  end

  def check_export_rate_limit!
    prefixed_action = "group_#{params[:action]}".to_sym

    scope = params[:action] == :download_export ? @group : nil

    check_rate_limit!(prefixed_action, scope: [current_user, scope].compact)
  end

  private

  def load_recaptcha
    Gitlab::Recaptcha.load_configurations!
  end

  def check_captcha
    return if group_params[:parent_id].present? # Only require for top-level groups

    load_recaptcha

    return if verify_recaptcha

    flash[:alert] = _('There was an error with the reCAPTCHA. Please solve the reCAPTCHA again.')
    flash.delete :recaptcha_error
    @group = Group.new(group_params)
    add_gon_variables
    render action: 'new'
  end

  def successful_creation_hooks
    update_user_role_and_setup_for_company
  end

  def update_user_role_and_setup_for_company
    user_params = params.fetch(:user, {}).permit(:role)
    user_params[:setup_for_company] = @group.setup_for_company if !@group.setup_for_company.nil? && current_user.setup_for_company.nil?
    Users::UpdateService.new(current_user, user_params.merge(user: current_user)).execute if user_params.present?
  end

  def groups
    if @group.supports_events?
      @group.self_and_descendants.public_or_visible_to_user(current_user)
    end
  end

  override :markdown_service_params
  def markdown_service_params
    params.merge(group: group)
  end

  override :has_project_list?
  def has_project_list?
    %w[details show index].include?(action_name)
  end

  def captcha_enabled?
    helpers.recaptcha_enabled? && Feature.enabled?(:recaptcha_on_top_level_group_creation, type: :ops)
  end

  def captcha_required?
    captcha_enabled? && !params[:parent_id]
  end

  def group_feature_attributes
    []
  end
end

GroupsController.prepend_mod_with('GroupsController')
