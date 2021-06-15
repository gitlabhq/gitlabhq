# frozen_string_literal: true

class GroupsController < Groups::ApplicationController
  include API::Helpers::RelatedResourcesHelpers
  include IssuableCollectionsAction
  include ParamsBackwardCompatibility
  include PreviewMarkdown
  include RecordUserLastActivity
  include SendFileUpload
  include FiltersEvents
  include Recaptcha::Verify
  extend ::Gitlab::Utils::Override

  respond_to :html

  prepend_before_action(only: [:show, :issues]) { authenticate_sessionless_user!(:rss) }
  prepend_before_action(only: [:issues_calendar]) { authenticate_sessionless_user!(:ics) }
  prepend_before_action :ensure_export_enabled, only: [:export, :download_export]
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

  before_action do
    push_frontend_feature_flag(:vue_issuables_list, @group)
    push_frontend_feature_flag(:iteration_cadences, @group, default_enabled: :yaml)
  end

  before_action :export_rate_limit, only: [:export, :download_export]

  helper_method :captcha_required?

  skip_cross_project_access_check :index, :new, :create, :edit, :update,
                                  :destroy, :projects
  # When loading show as an atom feed, we render events that could leak cross
  # project information
  skip_cross_project_access_check :show, if: -> { request.format.html? }

  layout :determine_layout

  feature_category :subgroups, [
                     :index, :new, :create, :show, :edit, :update,
                     :destroy, :details, :transfer, :activity
                   ]

  feature_category :issue_tracking, [:issues, :issues_calendar, :preview_markdown]
  feature_category :code_review, [:merge_requests, :unfoldered_environment_names]
  feature_category :projects, [:projects]
  feature_category :importers, [:export, :download_export]

  def index
    redirect_to(current_user ? dashboard_groups_path : explore_groups_path)
  end

  def new
    @group = Group.new(params.permit(:parent_id))
  end

  def create
    @group = Groups::CreateService.new(current_user, group_params).execute

    if @group.persisted?
      successful_creation_hooks

      notice = if @group.chat_team.present?
                 "Group '#{@group.name}' and its Mattermost team were successfully created."
               else
                 "Group '#{@group.name}' was successfully created."
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
        render_details_html
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

  protected

  def render_show_html
    record_experiment_user(:invite_members_empty_group_version_a) if ::Gitlab.com?

    render 'groups/show', locals: { trial: params[:trial] }
  end

  def render_details_html
    render 'groups/show'
  end

  def render_details_view_atom
    load_events
    render layout: 'xml.atom', template: 'groups/show'
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
      'application'
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
      :project_creation_level,
      :subgroup_creation_level,
      :default_branch_protection,
      :default_branch_name,
      :allow_mfa_for_subgroups,
      :resource_access_token_creation_allowed,
      :prevent_sharing_groups_outside_hierarchy
    ]
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

  def export_rate_limit
    prefixed_action = "group_#{params[:action]}".to_sym

    scope = params[:action] == :download_export ? @group : nil

    if Gitlab::ApplicationRateLimiter.throttled?(prefixed_action, scope: [current_user, scope].compact)
      Gitlab::ApplicationRateLimiter.log_request(request, "#{prefixed_action}_request_limit".to_sym, current_user)

      render plain: _('This endpoint has been requested too many times. Try again later.'), status: :too_many_requests
    end
  end

  def ensure_export_enabled
    render_404 unless Feature.enabled?(:group_import_export, @group, default_enabled: true)
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
    render action: 'new'
  end

  def successful_creation_hooks; end

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
    %w(details show index).include?(action_name)
  end

  def captcha_enabled?
    Gitlab::Recaptcha.enabled? && Feature.enabled?(:recaptcha_on_top_level_group_creation, type: :ops)
  end

  def captcha_required?
    captcha_enabled? && !params[:parent_id]
  end
end

GroupsController.prepend_mod_with('GroupsController')
