# frozen_string_literal: true

# Configures the ActionMailer delivery method for GitLab-native email providers
# that are configured via gitlab.yml: Microsoft Graph and Amazon SES.
#
# These two providers are mutually exclusive because they both set
# `ActionMailer::Base.delivery_method`.
#
# Note: SMTP delivery is configured separately. In Omnibus/CNG deployments SMTP configuration is
# injected via config/initializers/smtp_settings.rb, which is loaded after this
# initializer (alphabetical order) and therefore takes precedence.
graph_enabled = Gitlab.config.microsoft_graph_mailer.enabled
ses_enabled = Gitlab.config.amazon_ses_mailer.enabled

if graph_enabled && ses_enabled
  raise 'Only one of microsoft_graph_mailer or amazon_ses_mailer can be enabled at a time.'
end

if graph_enabled
  require 'microsoft_graph_mailer'

  ActionMailer::Base.delivery_method = :microsoft_graph

  ActionMailer::Base.microsoft_graph_settings = {
    user_id: Gitlab.config.microsoft_graph_mailer.user_id,
    tenant: Gitlab.config.microsoft_graph_mailer.tenant,
    client_id: Gitlab.config.microsoft_graph_mailer.client_id,
    client_secret: Gitlab.config.microsoft_graph_mailer.client_secret,
    azure_ad_endpoint: Gitlab.config.microsoft_graph_mailer.azure_ad_endpoint,
    graph_endpoint: Gitlab.config.microsoft_graph_mailer.graph_endpoint
  }
elsif ses_enabled
  require 'aws-actionmailer-ses'

  ses_config = Gitlab.config.amazon_ses_mailer

  credentials = Gitlab::Aws::CredentialsResolver.resolve(
    region: ses_config.region,
    role_arn: ses_config.role_arn,
    role_session_name: 'gitlab_amazon_ses_mailer',
    access_key_id: ses_config.access_key_id,
    secret_access_key: ses_config.secret_access_key
  )

  ActionMailer::Base.delivery_method = :ses_v2

  sesv2_client = Aws::SESV2::Client.new(region: ses_config.region, credentials: credentials)
  ActionMailer::Base.ses_v2_settings = { sesv2_client: sesv2_client }
end
