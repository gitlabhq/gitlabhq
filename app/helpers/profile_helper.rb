module ProfileHelper
  def oauth_active_class provider
    if current_user.provider == provider.to_s
      'active'
    end
  end
end
