# frozen_string_literal: true

class Admin::UsersController < Admin::ApplicationController
  include RoutableActions

  before_action :user, except: [:index, :new, :create]
  before_action :check_impersonation_availability, only: :impersonate
  before_action :ensure_destroy_prerequisites_met, only: [:destroy]
  before_action :check_ban_user_feature_flag, only: [:ban]

  feature_category :users

  PAGINATION_WITH_COUNT_LIMIT = 1000

  def index
    return redirect_to admin_cohorts_path if params[:tab] == 'cohorts'

    @users = User.filter_items(params[:filter]).order_name_asc
    @users = @users.search_with_secondary_emails(params[:search_query]) if params[:search_query].present?
    @users = users_with_included_associations(@users)
    @users = @users.sort_by_attribute(@sort = params[:sort])
    @users = @users.page(params[:page])
    @users = @users.without_count if paginate_without_count?
  end

  def show
  end

  def projects
    @personal_projects = user.personal_projects
    @joined_projects = user.projects.joined(@user)
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
    if can?(user, :log_in)
      session[:impersonator_id] = current_user.id

      warden.set_user(user, scope: :user)

      log_impersonation_event

      flash[:alert] = _("You are now impersonating %{username}") % { username: user.username }

      redirect_to root_path
    else
      flash[:alert] =
        if user.blocked?
          _("You cannot impersonate a blocked user")
        elsif user.internal?
          _("You cannot impersonate an internal user")
        else
          _("You cannot impersonate a user who cannot log in")
        end

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
      redirect_to admin_users_path, status: :found, notice: _("You've rejected %{user}" % { user: user.name })
    else
      redirect_back_or_admin_user(alert: result[:message])
    end
  end

  def activate
    return redirect_back_or_admin_user(notice: _("Error occurred. A blocked user must be unblocked to be activated")) if user.blocked?

    user.activate
    redirect_back_or_admin_user(notice: _("Successfully activated"))
  end

  def deactivate
    return redirect_back_or_admin_user(notice: _("Error occurred. A blocked user cannot be deactivated")) if user.blocked?
    return redirect_back_or_admin_user(notice: _("Successfully deactivated")) if user.deactivated?
    return redirect_back_or_admin_user(notice: _("Internal users cannot be deactivated")) if user.internal?
    return redirect_back_or_admin_user(notice: _("The user you are trying to deactivate has been active in the past %{minimum_inactive_days} days and cannot be deactivated") % { minimum_inactive_days: ::User::MINIMUM_INACTIVE_DAYS }) unless user.can_be_deactivated?

    user.deactivate
    redirect_back_or_admin_user(notice: _("Successfully deactivated"))
  end

  def block
    result = Users::BlockService.new(current_user).execute(user)

    if result[:status] == :success
      redirect_back_or_admin_user(notice: _("Successfully blocked"))
    else
      redirect_back_or_admin_user(alert: _("Error occurred. User was not blocked"))
    end
  end

  def unblock
    if user.ldap_blocked?
      redirect_back_or_admin_user(alert: _("This user cannot be unlocked manually from GitLab"))
    elsif update_user { |user| user.activate }
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
    if update_user { |user| user.activate }
      redirect_back_or_admin_user(notice: _("Successfully unbanned"))
    else
      redirect_back_or_admin_user(alert: _("Error occurred. User was not unbanned"))
    end
  end

  def unlock
    if update_user { |user| user.unlock_access! }
      redirect_back_or_admin_user(alert: _("Successfully unlocked"))
    else
      redirect_back_or_admin_user(alert: _("Error occurred. User was not unlocked"))
    end
  end

  def confirm
    if update_user { |user| user.confirm }
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
    opts = {
      reset_password: true,
      skip_confirmation: true
    }

    @user = Users::CreateService.new(current_user, user_params.merge(opts)).execute

    respond_to do |format|
      if @user.persisted?
        format.html { redirect_to [:admin, @user], notice: _('User was successfully created.') }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
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

    cc_validation_params = process_credit_card_validation_params(user_params_with_pass.delete(:credit_card_validation_attributes))
    user_params_with_pass.merge!(cc_validation_params)

    respond_to do |format|
      result = Users::UpdateService.new(current_user, user_params_with_pass.merge(user: user)).execute do |user|
        user.skip_reconfirmation!
        user.send_only_admin_changed_your_password_notification! if admin_making_changes_for_another_user?
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
    users.includes(:authorized_projects) # rubocop: disable CodeReuse/ActiveRecord
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
      message = s_('AdminUsers|You must transfer ownership or delete the groups owned by this user before you can delete their account')

      redirect_to admin_user_path(user), status: :see_other, alert: message
    end
  end

  def hard_delete?
    destroy_params[:hard_delete]
  end

  def user
    @user ||= find_routable!(User, params[:id])
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
      :can_create_group,
      :color_scheme_id,
      :email,
      :extern_uid,
      :external,
      :force_random_password,
      :hide_no_password,
      :hide_no_ssh_key,
      :key_id,
      :linkedin,
      :name,
      :password_expires_at,
      :projects_limit,
      :provider,
      :remember_me,
      :skype,
      :theme_id,
      :twitter,
      :username,
      :website_url,
      :note,
      credit_card_validation_attributes: [:credit_card_validated_at]
    ]
  end

  def update_user(&block)
    result = Users::UpdateService.new(current_user, user: user).execute(&block)

    result[:status] == :success
  end

  def check_impersonation_availability
    access_denied! unless Gitlab.config.gitlab.impersonation_enabled
  end

  def check_ban_user_feature_flag
    access_denied! unless Feature.enabled?(:ban_user_feature_flag)
  end

  def log_impersonation_event
    Gitlab::AppLogger.info(_("User %{current_user_username} has started impersonating %{username}") % { current_user_username: current_user.username, username: user.username })
  end
end

Admin::UsersController.prepend_mod_with('Admin::UsersController')
