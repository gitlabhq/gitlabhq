# frozen_string_literal: true

class GroupsController < Groups::ApplicationController
  include API::Helpers::RelatedResourcesHelpers
  include IssuableCollectionsAction
  include ParamsBackwardCompatibility
  include PreviewMarkdown
  include RecordUserLastActivity
  extend ::Gitlab::Utils::Override

  respond_to :html

  prepend_before_action(only: [:show, :issues]) { authenticate_sessionless_user!(:rss) }
  prepend_before_action(only: [:issues_calendar]) { authenticate_sessionless_user!(:ics) }

  before_action :authenticate_user!, only: [:new, :create]
  before_action :group, except: [:index, :new, :create]

  # Authorize
  before_action :authorize_admin_group!, only: [:edit, :update, :destroy, :projects, :transfer]
  before_action :authorize_create_group!, only: [:new]

  before_action :group_projects, only: [:projects, :activity, :issues, :merge_requests]
  before_action :event_filter, only: [:activity]

  before_action :user_actions, only: [:show]

  before_action do
    push_frontend_feature_flag(:vue_issuables_list, @group)
  end

  skip_cross_project_access_check :index, :new, :create, :edit, :update,
                                  :destroy, :projects
  # When loading show as an atom feed, we render events that could leak cross
  # project information
  skip_cross_project_access_check :show, if: -> { request.format.html? }

  layout :determine_layout

  def index
    redirect_to(current_user ? dashboard_groups_path : explore_groups_path)
  end

  def new
    @group = Group.new(params.permit(:parent_id))
  end

  def create
    @group = Groups::CreateService.new(current_user, group_params).execute

    if @group.persisted?
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
        render_show_html
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
        pager_json("events/_events", @events.count)
      end
    end
  end

  def edit
    @badge_api_endpoint = expose_url(api_v4_groups_badges_path(id: @group.id))
  end

  def projects
    @projects = @group.projects.with_statistics.page(params[:page])
  end

  def update
    if Groups::UpdateService.new(@group, current_user, group_params).execute
      redirect_to edit_group_path(@group, anchor: params[:update_section]), notice: "Group '#{@group.name}' was successfully updated."
    else
      @group.path = @group.path_before_last_save || @group.path_was
      render action: "edit"
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

  protected

  def render_show_html
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
      :subgroup_creation_level
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

  private

  def groups
    if @group.supports_events?
      @group.self_and_descendants.public_or_visible_to_user(current_user)
    end
  end

  override :markdown_service_params
  def markdown_service_params
    params.merge(group: group)
  end
end

GroupsController.prepend_if_ee('EE::GroupsController')
