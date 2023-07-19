# frozen_string_literal: true

module Projects
  module ObservabilityHelper
    def observability_tracing_view_model(project)
      Gitlab::Json.generate({
        tracingUrl: Gitlab::Observability.tracing_url(project),
        provisioningUrl: Gitlab::Observability.provisioning_url(project),
        oauthUrl: Gitlab::Observability.oauth_url
      })
    end
  end
end
