module ExternalAuthorizationServiceHelpers
  def enable_external_authorization_service
    stub_licensed_features(external_authorization_service: true)

    # Not using `stub_application_setting` because the method is prepended in
    # `EE::ApplicationSetting` which breaks when using `any_instance`
    # https://gitlab.com/gitlab-org/gitlab-ce/issues/33587
    allow(::Gitlab::CurrentSettings.current_application_settings)
      .to receive(:external_authorization_service_enabled) { true }
    allow(::Gitlab::CurrentSettings.current_application_settings)
      .to receive(:external_authorization_service_enabled?) { true }

    stub_application_setting(external_authorization_service_url: 'https://authorize.me')
    stub_application_setting(external_authorization_service_default_label: 'default_label')
    stub_request(:post, "https://authorize.me").to_return(status: 200)
  end

  def external_service_set_access(allowed, user, project)
    enable_external_authorization_service
    classification_label = ::Gitlab::CurrentSettings.current_application_settings
                             .external_authorization_service_default_label

    # Reload the project so cached licensed features are reloaded
    if project
      classification_label = Project.find(project.id).external_authorization_classification_label
    end

    allow(EE::Gitlab::ExternalAuthorization)
      .to receive(:access_allowed?)
            .with(user, classification_label)
            .and_return(allowed)
  end

  def external_service_allow_access(user, project = nil)
    external_service_set_access(true, user, project)
  end

  def external_service_deny_access(user, project = nil)
    external_service_set_access(false, user, project)
  end
end
