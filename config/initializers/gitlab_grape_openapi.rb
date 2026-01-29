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
      url: 'https://gitlab.com/api',
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
          authorizationUrl: Gitlab::Utils.append_path('https://gitlab.com/api', "/oauth/authorize"),
          tokenUrl: Gitlab::Utils.append_path('https://gitlab.com/api', "/oauth/token"),
          refreshUrl: Gitlab::Utils.append_path('https://gitlab.com/api', "/oauth/refresh"),
          scopes: Gitlab::Auth::API_SCOPES.reject { |k, _| k == :granular }
                                          .index_with { |s| I18n.t(s, scope: [:doorkeeper, :scope_desc]) }
        }
      }
    )
  ]

  config.tag_overrides = {
    'Api' => 'API',
    'bitbucket' => 'Bitbucket',
    'Ci' => 'CI',
    'Dora' => 'DORA',
    'Github' => 'GitHub',
    'Gpg' => 'GPG',
    'Glql' => 'GLQL',
    'google cloud' => 'Google Cloud',
    'Ldap' => 'LDAP',
    'Npm' => 'NPM',
    'Oauth' => 'OAuth',
    'Pypi' => 'PyPi',
    'Rpm' => 'RPM',
    'Rubygem' => 'RubyGem',
    'Saml' => 'SAML',
    'Scim' => 'SCIM',
    'Ssh' => 'SSH',
    'Todos' => 'To-Dos',
    'Vscode' => 'VSCode'
  }.freeze

  # CONFIGURE EXCLUDED APIs
  # API endpoints can be excluded from OpenApi spec generation and the resulting
  # documentation by adding their API classes to the excluded_api_classes array.
  # Grape API classes are not loaded when this config is intitialized.
  # Only use string names. Using class constants will cause loading errors.
  # eg.  config.excluded_api_classes = [ 'API::InternalApiClass', 'API::AdminApiClass' ]
  config.excluded_api_classes = [
    'GitlabSubscriptions::API::Internal::Users',
    'GitlabSubscriptions::API::Internal::UpcomingReconciliations',
    'GitlabSubscriptions::API::Internal::Subscriptions',
    'GitlabSubscriptions::API::Internal::Namespaces::Provision',
    'GitlabSubscriptions::API::Internal::Namespaces',
    'GitlabSubscriptions::API::Internal::Members',
    'GitlabSubscriptions::API::Internal::ComputeMinutes',
    'GitlabSubscriptions::API::Internal::AddOnPurchases',
    'GitlabSubscriptions::API::Internal::API',
    'API::Internal::SecretsManager',
    'API::Internal::Observability',
    'API::Internal::Ai::XRay::Scan',
    'API::Internal::Search::Zoekt',
    'API::Internal::Ci::JobRouter',
    'API::Internal::AppSec::Dast::SiteValidations',
    'API::RemoteDevelopment::Internal::Agents::Agentw::ServerConfig',
    'API::RemoteDevelopment::Internal::Agents::Agentw::AuthorizeUserAccess',
    'API::RemoteDevelopment::Internal::Agents::Agentw::AgentInfo',
    'API::Internal::Shellhorse',
    'API::Internal::Workhorse',
    'API::Internal::MailRoom',
    'API::Internal::ErrorTracking',
    'API::Internal::Kubernetes',
    'API::Internal::Pages',
    'API::Internal::Lfs',
    'API::Internal::Base',
    'API::Internal::AutoFlow'
  ]
end
