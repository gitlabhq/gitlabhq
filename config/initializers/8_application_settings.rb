if ActiveRecord::Base.connection.table_exists?('application_settings')
  unless ApplicationSetting.any?
    ApplicationSetting.create(
      default_projects_limit: Settings.gitlab['default_projects_limit'],
      signup_enabled: Settings.gitlab['signup_enabled'],
      signin_enabled: Settings.gitlab['signin_enabled'],
      gravatar_enabled: Settings.gravatar['enabled'],
      sign_in_text: Settings.extra['sign_in_text'],
    )
  end
end
