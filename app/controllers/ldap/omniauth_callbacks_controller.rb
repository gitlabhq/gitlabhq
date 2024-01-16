# frozen_string_literal: true

class Ldap::OmniauthCallbacksController < OmniauthCallbacksController
  extend ::Gitlab::Utils::Override

  before_action :check_action_name_in_available_providers

  def self.define_providers!
    return unless Gitlab::Auth::Ldap::Config.sign_in_enabled?

    Gitlab::Auth::Ldap::Config.servers.each do |server|
      alias_method server['provider_name'], :ldap
    end
  end

  # We only find ourselves here
  # if the authentication to LDAP was successful.
  def ldap
    return unless Gitlab::Auth::Ldap::Config.sign_in_enabled?

    if Gitlab::CurrentSettings.admin_mode
      return admin_mode_flow(Gitlab::Auth::Ldap::User) if current_user_mode.admin_mode_requested?
    end

    sign_in_user_flow(Gitlab::Auth::Ldap::User)
  end

  define_providers!

  override :set_remember_me
  def set_remember_me(user, _auth_user)
    user.remember_me = params[:remember_me] if user.persisted?
  end

  override :fail_login
  def fail_login(user)
    flash[:alert] = _('Access denied for your LDAP account.')

    redirect_to new_user_session_path
  end

  private

  def check_action_name_in_available_providers
    render_404 unless available_providers.include?(action_name)
  end

  def available_providers
    Gitlab::Auth::Ldap::Config.available_servers.map do |server|
      server['provider_name']
    end
  end
end

Ldap::OmniauthCallbacksController.prepend_mod_with('Ldap::OmniauthCallbacksController')
