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

  config.api_prefix = "api"

  config.api_version = "v4"

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
          scopes: Gitlab::Auth::API_SCOPES.reject { |k, _| k == :granular }
                                          .index_with { |s| I18n.t(s, scope: [:doorkeeper, :scope_desc]) }
        }
      }
    )
  ]

  config.tag_overrides = {
    'Ci' => 'CI',
    'Oauth' => 'OAuth',
    'Ldap' => 'LDAP',
    'Npm' => 'NPM',
    'Dora' => 'DORA',
    'Vscode' => 'VSCode',
    'Api' => 'API',
    'Rpm' => 'RPM',
    'Github' => 'GitHub',
    'Saml' => 'SAML'
  }
end
