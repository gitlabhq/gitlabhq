# frozen_string_literal: true

I18n.load_path += Dir[Rails.root.join('config/locales/doorkeeper.en.yml')]
I18n.reload!

Gitlab::GrapeOpenapi.configure do |config|
  config.info = Gitlab::GrapeOpenapi::Models::Info.new(
    title: 'GitLab REST API',
    description: 'GitLab REST API used to interact with a GitLab installation.',
    version: 'v4',
    terms_of_service: 'https://about.gitlab.com/terms/'
  )

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
          scopes: Gitlab::Auth::API_SCOPES.index_with { |scope| I18n.t(scope, scope: [:doorkeeper, :scopes]) }
        }
      }
    )
  ]
end
