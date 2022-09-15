# frozen_string_literal: true

if Gitlab.config.microsoft_graph_mailer.enabled
  ActionMailer::Base.delivery_method = :microsoft_graph

  ActionMailer::Base.microsoft_graph_settings = {
    user_id: Gitlab.config.microsoft_graph_mailer.user_id,
    tenant: Gitlab.config.microsoft_graph_mailer.tenant,
    client_id: Gitlab.config.microsoft_graph_mailer.client_id,
    client_secret: Gitlab.config.microsoft_graph_mailer.client_secret,
    azure_ad_endpoint: Gitlab.config.microsoft_graph_mailer.azure_ad_endpoint,
    graph_endpoint: Gitlab.config.microsoft_graph_mailer.graph_endpoint
  }
end
