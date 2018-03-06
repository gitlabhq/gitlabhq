module EE
  module ServiceParams
    ALLOWED_PARAMS_EE = [
      :jenkins_url,
      :multiproject_enabled,
      :pass_unstable,
      :project_name,
      :repository_url
    ].freeze

    def allowed_service_params
      super + ALLOWED_PARAMS_EE
    end
  end
end
