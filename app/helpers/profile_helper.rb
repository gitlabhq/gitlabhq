module ProfileHelper
  def oauth_active_class(provider)
    if current_user.identities.exists?(provider: provider.to_s)
      'active'
    end
  end

  def show_profile_username_tab?
    current_user.can_change_username?
  end

  def show_profile_social_tab?
    enabled_social_providers.any?
  end

  def show_profile_remove_tab?
    gitlab_config.signup_enabled
  end
end
