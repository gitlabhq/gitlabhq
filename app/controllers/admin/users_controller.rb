# frozen_string_literal: true

class Admin::UsersController < Admin::ApplicationController
  include RoutableActions
  include SortingHelper

  before_action :user, except: [:index, :new, :create]
  before_action :check_impersonation_availability, only: :impersonate
  before_action :ensure_destroy_prerequisites_met, only: [:destroy]
  before_action :set_shared_view_parameters, only: [:show, :projects, :keys]

  feature_category :user_management

  PAGINATION_WITH_COUNT_LIMIT = 1000

  def index
    return redirect_to admin_cohorts_path if params[:tab] == 'cohorts'

    @users = User.filter_items(params[:filter]).order_name_asc

    if params[:search_query].present?
      # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- available only for self-managed instances
      @users = @users.search(params[:search_query], with_private_emails: true, partial_email_search: !Gitlab.com?)
      # rubocop:enable Gitlab/AvoidGitlabInstanceChecks
    end

    @users = users_with_included_associations(@users)
    @sort = params[:sort].presence || sort_value_name
    @users = @users.sort_by_attribute(@sort)
    @users = @users.page(params[:page])
    @users = @users.without_count if paginate_without_count?
  end

  def show; end

  # rubocop: disable CodeReuse/ActiveRecord
  def projects
    @personal_projects = user.personal_projects.includes(:topics)
    @joined_projects = user.projects.joined(@user).includes(:topics)
  end

  def keys
    @keys = user.keys.order_id_desc
  end

  def new
    @user = User.new
  end

  def edit
    user
  end

  def impersonate
    if helpers.can_impersonate_user(user, impersonation_in_progress?)
      session[:impersonator_id] = current_user.id

      warden.set_user(user, scope: :user)
      clear_access_token_session_keys!

      log_impersonation_event

      flash[:notice] = format(_("You are now impersonating %{username}"), username: user.username)

      redirect_to root_path
    else
      flash[:alert] = helpers.impersonation_error_text(user, impersonation_in_progress?)

      redirect_to admin_user_path(user)
    end
  end

  def approve
    result = Users::ApproveService.new(current_user).execute(user)

    if result[:status] == :success
      redirect_back_or_admin_user(notice: _("Successfully approved"))
    else
      redirect_back_or_admin_user(alert: result[:message])
    end
  end

  def reject
    result = Users::RejectService.new(current_user).execute(user)

    if result[:status] == :success
      redirect_back_or_admin_user(notice: format(_("You've rejected %{user}"), user: user.name))
    else
      redirect_back_or_admin_user(alert: result[:message])
    end
  end

  def activate
    activate_service = Users::ActivateService.new(current_user)
    result = activate_service.execute(user)

    if result.success?
      redirect_back_or_admin_user(notice: _("Successfully activated"))
    else
      redirect_back_or_admin_user(alert: result.message)
    end
  end

  def deactivate
    deactivate_service = Users::DeactivateService.new(current_user, skip_authorization: true)
    result = deactivate_service.execute(user)

    if result.success?
      redirect_back_or_admin_user(notice: _("Successfully deactivated"))
    else
      redirect_back_or_admin_user(alert: result.message)
    end
  end

  def block
    result = Users::BlockService.new(current_user).execute(user)

    respond_to do |format|
      if result[:status] == :success
        notice = _("Successfully blocked")
        format.json { render json: { notice: notice } }
        format.html { redirect_back_or_admin_user(notice: notice) }
      else
        alert = _("Error occurred. User was not blocked")
        format.json { render json: { error: alert } }
        format.html { redirect_back_or_admin_user(alert: alert) }
      end
    end
  end

  def unblock
    if user.ldap_blocked?
      return redirect_back_or_admin_user(alert: _("This user cannot be unlocked manually from GitLab"))
    end

    result = Users::UnblockService.new(current_user).execute(user)

    if result.success?
      redirect_back_or_admin_user(notice: _("Successfully unblocked"))
    else
      redirect_back_or_admin_user(alert: _("Error occurred. User was not unblocked"))
    end
  end

  def ban
    result = Users::BanService.new(current_user).execute(user)

    if result[:status] == :success
      redirect_back_or_admin_user(notice: _("Successfully banned"))
    else
      redirect_back_or_admin_user(alert: _("Error occurred. User was not banned"))
    end
  end

  def unban
    result = Users::UnbanService.new(current_user).execute(user)

    if result[:status] == :success
      redirect_back_or_admin_user(notice: _("Successfully unbanned"))
    else
      redirect_back_or_admin_user(alert: _("Error occurred. User was not unbanned"))
    end
  end

  def unlock
    if unlock_user
      redirect_back_or_admin_user(notice: _("Successfully unlocked"))
    else
      redirect_back_or_admin_user(alert: _("Error occurred. User was not unlocked"))
    end
  end

  def trust
    result = Users::TrustService.new(current_user).execute(user)

    if result[:status] == :success
      redirect_back_or_admin_user(notice: _("Successfully trusted"))
    else
      redirect_back_or_admin_user(alert: _("Error occurred. User was not updated"))
    end
  end

  def untrust
    result = Users::UntrustService.new(current_user).execute(user)

    if result[:status] == :success
      redirect_back_or_admin_user(notice: _("Successfully untrusted"))
    else
      redirect_back_or_admin_user(alert: _("Error occurred. User was not updated"))
    end
  end

  def confirm
    if update_user(&:force_confirm)
      redirect_back_or_admin_user(notice: _("Successfully confirmed"))
    else
      redirect_back_or_admin_user(alert: _("Error occurred. User was not confirmed"))
    end
  end

  def disable_two_factor
    result = TwoFactor::DestroyService.new(current_user, user: user).execute

    if result[:status] == :success
      redirect_to admin_user_path(user),
        notice: _('Two-factor authentication has been disabled for this user')
    else
      redirect_to admin_user_path(user), alert: result[:message]
    end
  end

  def create
    opts = user_params.merge(reset_password: true, skip_confirmation: true)
    opts[:organization_id] ||= Current.organization&.id

    response = Users::CreateService.new(current_user, opts).execute

    @user = response.payload[:user]

    respond_to do |format|
      if response.success?
        format.html { redirect_to default_route, notice: _('User was successfully created.') }
        format.json { render json: @user, status: :created, location: @user }
      else
        if @user&.errors&.any?
          format.html { render "new" }
        else
          format.html { redirect_to admin_users_path, notice: response.message }
        end

        format.json { render json: @user&.errors || {}, status: :unprocessable_entity }
      end
    end
  end

  def update
    user_params_with_pass = user_params.dup

    if params[:user][:password].present?
      password_params = {
        password: params[:user][:password],
        password_confirmation: params[:user][:password_confirmation]
      }

      password_params[:password_expires_at] = Time.current if admin_making_changes_for_another_user?

      user_params_with_pass.merge!(password_params)
    end

    cc_validation_params = process_credit_card_validation_params(
      user_params_with_pass.delete(:credit_card_validation_attributes)
    )
    user_params_with_pass.merge!(cc_validation_params)

    respond_to do |format|
      result = Users::UpdateService.new(current_user, user_params_with_pass.merge(user: user)).execute do |user|
        prepare_user_for_update(user)
      end

      if result[:status] == :success
        format.html { redirect_to [:admin, user], notice: _('User was successfully updated.') }
        format.json { head :ok }
      else
        # restore username to keep form action url.
        user.username = params[:id]
        format.html { render "edit" }
        format.json { render json: [result[:message]], status: :internal_server_error }
      end
    end
  end

  def destroy
    user.delete_async(deleted_by: current_user, params: destroy_params)

    respond_to do |format|
      format.html { redirect_to admin_users_path, status: :found, notice: _("The user is being deleted.") }
      format.json { head :ok }
    end
  end

  def remove_email
    email = user.emails.find(params[:email_id])
    success = Emails::DestroyService.new(current_user, user: user).execute(email)

    respond_to do |format|
      if success
        format.html { redirect_back_or_admin_user(notice: _('Successfully removed email.')) }
        format.json { head :ok }
      else
        format.html { redirect_back_or_admin_user(alert: _('There was an error removing the e-mail.')) }
        format.json { render json: _('There was an error removing the e-mail.'), status: :bad_request }
      end
    end
  end

  protected

  def process_credit_card_validation_params(cc_validation_params)
    return unless cc_validation_params && cc_validation_params[:credit_card_validated_at]

    cc_validation = cc_validation_params[:credit_card_validated_at]

    if cc_validation == "1" && !user.credit_card_validated_at
      {
        credit_card_validation_attributes: {
          credit_card_validated_at: Time.zone.now
        }
      }

    elsif cc_validation == "0" && user.credit_card_validated_at
      {
        credit_card_validation_attributes: {
          _destroy: true
        }
      }
    end
  end

  def paginate_without_count?
    counts = Gitlab::Database::Count.approximate_counts([User])

    counts[User] > PAGINATION_WITH_COUNT_LIMIT
  end

  def users_with_included_associations(users)
    users.includes(:authorized_projects, :trusted_with_spam_attribute) # rubocop: disable CodeReuse/ActiveRecord
  end

  def admin_making_changes_for_another_user?
    user != current_user
  end

  def destroy_params
    params.permit(:hard_delete)
  end

  def ensure_destroy_prerequisites_met
    return if hard_delete?

    if user.solo_owned_groups.present?
      message = s_('AdminUsers|You must transfer ownership or delete the ' \
        'groups owned by this user before you can delete their account')

      redirect_to admin_user_path(user), status: :see_other, alert: message
    end
  end

  def hard_delete?
    destroy_params[:hard_delete]
  end

  def user
    @user ||= find_routable!(User, params[:id], request.fullpath)
  end

  def build_canonical_path(user)
    url_for(safe_params.merge(id: user.to_param))
  end

  def redirect_back_or_admin_user(options = {})
    redirect_back_or_default(default: default_route, options: options)
  end

  def default_route
    [:admin, @user]
  end

  def user_params
    params.require(:user).permit(allowed_user_params)
  end

  def allowed_user_params
    [
      :access_level,
      :avatar,
      :bio,
      :bluesky,
      :can_create_group,
      :color_mode_id,
      :color_scheme_id,
      :discord,
      :email,
      :extern_uid,
      :external,
      :force_random_password,
      :hide_no_password,
      :hide_no_ssh_key,
      :key_id,
      :linkedin,
      :mastodon,
      :name,
      :note,
      :organization_id,
      :organization_access_level,
      :password_expires_at,
      :private_profile,
      :projects_limit,
      :provider,
      :remember_me,
      :skype,
      :theme_id,
      :twitter,
      :username,
      :website_url,
      { credit_card_validation_attributes: [:credit_card_validated_at] },
      { organization_users_attributes: [:id, :organization_id, :access_level] }
    ]
  end

  def update_user(&block)
    result = Users::UpdateService.new(current_user, user: user).execute(&block)

    result[:status] == :success
  end

  def check_impersonation_availability
    access_denied! unless Gitlab.config.gitlab.impersonation_enabled
  end

  def log_impersonation_event
    Gitlab::AppLogger.info(format(_("User %{current_user_username} has started impersonating %{username}"),
      current_user_username: current_user.username, username: user.username))
  end

  # method overridden in EE
  def unlock_user
    update_user(&:unlock_access!)
  end

  private

  def set_shared_view_parameters
    @can_impersonate = helpers.can_impersonate_user(user, impersonation_in_progress?)
    unless @can_impersonate
      @impersonation_error_text =
        helpers.impersonation_error_text(user, impersonation_in_progress?)
    end
  end

  # method overridden in EE
  def prepare_user_for_update(user)
    user.skip_reconfirmation!
    user.send_only_admin_changed_your_password_notification! if admin_making_changes_for_another_user?
  end
end

Admin::UsersController.prepend_mod_with('Admin::UsersController')
