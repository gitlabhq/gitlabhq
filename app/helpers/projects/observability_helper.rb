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

    def observability_tracing_details_model(project, trace_id)
      Gitlab::Json.generate({
        tracingIndexUrl: namespace_project_tracing_index_path(project.group, project),
        traceId: trace_id,
        tracingUrl: Gitlab::Observability.tracing_url(project),
        provisioningUrl: Gitlab::Observability.provisioning_url(project),
        oauthUrl: Gitlab::Observability.oauth_url
      })
    end
  end
end
