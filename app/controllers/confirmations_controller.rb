# frozen_string_literal: true

class ConfirmationsController < Devise::ConfirmationsController
  include AcceptsPendingInvitations
  include GitlabRecaptcha
  include OneTrustCSP

  prepend_before_action :check_recaptcha, only: :create
  before_action :load_recaptcha, only: :new

  feature_category :user_management

  def almost_there
    flash[:notice] = nil
    render layout: "devise_empty"
  end

  # modified from Devise::ConfirmationsController
  # https://github.com/heartcombo/devise/blob/e9c534d363cc9d552662049b38582eead87bedd6/app/controllers/devise/confirmations_controller.rb#L22
  # since we must accept a user_id sharding param and use it in the lookup
  # for Email confirmations, but User confirmations should remain unchanged
  #
  # this override can be removed once emails table is re-sharded to organization_id
  # and we've refactored to override Email.confirm_by_token instead
  # https://gitlab.com/gitlab-org/gitlab/-/work_items/585903
  def show
    return super unless resource_class == Email && email_confirmation_params[:user_id].present?

    self.resource = confirm_email_by_token(
      email_confirmation_params[:user_id],
      email_confirmation_params[:confirmation_token]
    )

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)
      respond_with_navigational(resource) { redirect_to after_confirmation_path_for(resource_name, resource) }
    else
      respond_with_navigational(resource.errors, status: :unprocessable_entity) { render :new }
    end
  end

  protected

  def email_confirmation_params
    params.permit(:user_id, :confirmation_token)
  end

  # modified from Devise::Confirmable module to use user_id in query
  # https://github.com/heartcombo/devise/blob/c8a64b549c8b37e494eaca7be2def136a7e1b236/lib/devise/models/confirmable.rb#L329
  def confirm_email_by_token(user_id, confirmation_token)
    if confirmation_token.blank?
      confirmable = resource_class.new
      confirmable.errors.add(:confirmation_token, :blank)
      return confirmable
    end

    confirmable = resource_class.find_first_by_auth_conditions(
      user_id: user_id,
      confirmation_token: confirmation_token
    )

    unless confirmable
      confirmation_digest = Devise.token_generator.digest(resource_class, :confirmation_token, confirmation_token)
      confirmable = resource_class.find_or_initialize_with_errors(
        [:user_id, :confirmation_token],
        { user_id: user_id, confirmation_token: confirmation_digest }
      )
    end

    confirmable.confirm if confirmable.persisted?
    confirmable
  end

  def after_resending_confirmation_instructions_path_for(resource)
    return users_almost_there_path unless Gitlab::CurrentSettings.email_confirmation_setting_soft?

    stored_location_for(resource) || dashboard_projects_path
  end

  def after_confirmation_path_for(_resource_name, resource)
    accept_pending_invitations

    # incoming resource can either be a :user or an :email
    if signed_in?(:user)
      after_sign_in(resource)
    else
      Gitlab::AppLogger.info(
        "Email Confirmed: username=#{resource.username} email=#{resource.email} ip=#{request.remote_ip}"
      )
      flash[:notice] = flash[:notice] + _(" Please sign in.")
      sign_in_path(resource)
    end
  end

  def sign_in_path(user)
    new_session_path(:user, anchor: 'login-pane', invite_email: resource.email)
  end

  def check_recaptcha
    return unless resource_params[:email].present?

    super
  end

  def after_sign_in(resource)
    after_sign_in_path_for(resource)
  end

  def context_user
    resource
  end
end

ConfirmationsController.prepend_mod_with('ConfirmationsController')
