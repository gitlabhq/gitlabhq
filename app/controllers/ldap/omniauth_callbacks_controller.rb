class Ldap::OmniauthCallbacksController < OmniauthCallbacksController
  extend ::Gitlab::Utils::Override
<<<<<<< HEAD
  prepend EE::OmniauthCallbacksController
  prepend EE::Ldap::OmniauthCallbacksController
=======
>>>>>>> upstream/master

  def self.define_providers!
    return unless Gitlab::Auth::LDAP::Config.enabled?

    Gitlab::Auth::LDAP::Config.available_servers.each do |server|
      alias_method server['provider_name'], :ldap
    end
  end

  # We only find ourselves here
  # if the authentication to LDAP was successful.
  def ldap
    sign_in_user_flow(Gitlab::Auth::LDAP::User)
  end

  define_providers!

  override :set_remember_me
  def set_remember_me(user)
    user.remember_me = params[:remember_me] if user.persisted?
  end

  override :fail_login
  def fail_login(user)
    flash[:alert] = 'Access denied for your LDAP account.'

    redirect_to new_user_session_path
  end
end
