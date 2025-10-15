# frozen_string_literal: true

Gitlab::GrapeOpenapi.configure do |config|
  config.servers = [
    Gitlab::GrapeOpenapi::Models::Server.new(
      url: Gitlab::Utils.append_path(Gitlab.config.gitlab.url, "api/v4"),
      description: "GitLab REST API"
    )
  ]

  config.security_schemes = [
    Gitlab::GrapeOpenapi::Models::SecurityScheme.new(
      name: "bearerAuth",
      type: "http",
      scheme: "bearer"
    ),
    Gitlab::GrapeOpenapi::Models::SecurityScheme.new(
      name: "OAuth2",
      type: "oauth2",
      flows: {
        authorizationCode: {
          authorizationUrl: Gitlab::Utils.append_path(Gitlab.config.gitlab.url, "/oauth/authorize"),
          tokenUrl: Gitlab::Utils.append_path(Gitlab.config.gitlab.url, "/oauth/token"),
          refreshUrl: Gitlab::Utils.append_path(Gitlab.config.gitlab.url, "/oauth/refresh"),
          scopes: Gitlab::Auth::API_SCOPES.map(&:to_s)
        }
      }
    )
  ]
end
