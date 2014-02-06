module ProfileHelper
  def oauth_active_class provider
    if current_user.provider == provider.to_s
      'active'
    end
  end

  def show_profile_username_tab?
    current_user.can_change_username?
  end

  def show_profile_social_tab?
    Gitlab.config.omniauth.enabled && !current_user.ldap_user?
  end

  def show_profile_remove_tab?
    gitlab_config.signup_enabled && !current_user.ldap_user?
  end
end
