---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Detected secrets
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

This table lists the secrets detected by:

- Pipeline secret detection
- Client-side secret detection
- Secret push protection

<!-- markdownlint-disable MD034 -->
<!-- markdownlint-disable MD044 -->
<!-- vale gitlab_base.SentenceSpacing = NO -->

| Description                                   | ID                                            | Pipeline secret detection | Client-side secret detection | Secret push protection |
|:----------------------------------------------|:----------------------------------------------|:--------------------------|:-----------------------------|:-----------------------|
| Adobe Client ID (OAuth Web)                       | Adobe Client ID (Oauth Web)                   | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Adobe client secret                               | Adobe Client Secret                           | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Age secret key                                    | Age secret key                                | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Alibaba AccessKey ID                              | Alibaba AccessKey ID                          | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Alibaba Secret Key                                | Alibaba Secret Key                            | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Anthropic API key                                 | anthropic_key                                 | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes |
| Artifactory API Key                               | ArtifactoryApiKey                             | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Artifactory Identity Token                        | ArtifactoryIdentityToken                      | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Asana client ID                                   | Asana Client ID                               | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Asana client secret                               | Asana Client Secret                           | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Atlassian API token                               | Atlassian API token                           | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| AWS access token                                  | AWS                                           | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Beamer API token                                  | Beamer API token                              | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Bitbucket client ID                               | Bitbucket client ID                           | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Bitbucket client secret                           | Bitbucket client secret                       | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Brevo API token                                   | Sendinblue API token                          | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Brevo SMTP token                                  | Sendinblue SMTP token                         | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| CircleCI access token                             | CircleCI access tokens                        | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| CircleCI Personal Access Token                    | CircleCIPersonalAccessToken                   | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Clojars deploy token                              | Clojars API token                             | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Contentful delivery API token                     | Contentful delivery API token                 | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Contentful personal access token                  | ContentfulPersonalAccessToken                 | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Contentful preview API token                      | Contentful preview API token                  | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Databricks API token                              | Databricks API token                          | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| DigitalOcean OAuth access token                   | digitalocean-access-token                     | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| DigitalOcean personal access token                | digitalocean-pat                              | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| DigitalOcean refresh token                        | digitalocean-refresh-token                    | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Discord API key                                   | Discord API key                               | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Discord client ID                                 | Discord client ID                             | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Discord client secret                             | Discord client secret                         | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Doppler API token                                 | Doppler API token                             | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Dropbox API secret/key                            | Dropbox API secret/key                        | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Dropbox long lived API token                      | Dropbox long lived API token                  | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Dropbox short lived API token                     | Dropbox short lived API token                 | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Duffel API token                                  | Duffel API token                              | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Dynatrace API token                               | Dynatrace API token                           | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| EasyPost production API key                       | EasyPost API token                            | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| EasyPost test API key                             | EasyPost test API token                       | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Facebook token                                    | Facebook token                                | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Fastly API user or automation token               | Fastly API token                              | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Finicity API token                                | Finicity API token                            | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Finicity client secret                            | Finicity client secret                        | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Flutterwave test encrypted key                    | Flutterwave encrypted key                     | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Flutterwave test public key                       | Flutterwave public key                        | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Flutterwave test secret key                       | Flutterwave secret key                        | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Frame.io API token                                | Frame.io API token                            | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| GCP API key                                       | GCP API key                                   | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| GCP OAuth client secret                           | GCP OAuth client secret                       | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| GitHub app token                                  | Github App Token                              | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| GitHub OAuth Access Token                         | Github OAuth Access Token                     | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| GitHub personal access token (classic)            | Github Personal Access Token                  | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| GitHub refresh token                              | Github Refresh Token                          | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| GitLab CI build token                             | gitlab_ci_build_token                         | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No |
| GitLab deploy token                               | gitlab_deploy_token                           | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No |
| GitLab Feature Flags Client Token                 | None                                          | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No |
| GitLab feed token                                 | gitlab_feed_token                             | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No |
| GitLab feed token v2                              | gitlab_feed_token_v2                          | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes |
| GitLab incoming email token                       | gitlab_incoming_email_token                   | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes |
| GitLab Kubernetes agent token                     | gitlab_kubernetes_agent_token                 | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes |
| GitLab OAuth application secret                   | gitlab_oauth_app_secret                       | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes |
| GitLab personal access token                      | gitlab_personal_access_token                  | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes |
| GitLab Personal Access Token (routable)           | gitlab_personal_access_token_routable         | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes |
| GitLab pipeline trigger token                     | gitlab_pipeline_trigger_token                 | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes |
| GitLab runner authentication token                | gitlab_runner_auth_token                      | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes |
| GitLab runner registration token                  | gitlab_runner_registration_token              | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| GitLab SCIM OAuth token                           | gitlab_scim_oauth_token                       | {{< icon name="check-circle" >}} Yes | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No |
| GoCardless API token                              | GoCardless API token                          | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Google (GCP) service account                      | Google (GCP) Service-account                  | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Grafana API token                                 | Grafana API token                             | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| HashiCorp Terraform API token                     | Hashicorp Terraform user/org API token        | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| HashiCorp Vault batch token                       | Hashicorp Vault batch token                   | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Heroku API key or application authorization token | Heroku API Key                                | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| HubSpot private app API token                     | Hubspot API token                             | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Instagram access token                            | Instagram access token                        | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Intercom API token                                | Intercom API token                            | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Intercom client secret or client ID               | Intercom client secret/ID                     | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Ionic personal access token                       | Ionic API token                               | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Linear API token                                  | Linear API token                              | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Linear client secret or ID (OAuth 2.0)            | Linear client secret/ID                       | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| LinkedIn client ID                                | Linkedin Client ID                            | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| LinkedIn client secret                            | Linkedin Client secret                        | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Lob API key                                       | Lob API Key                                   | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Lob publishable API key                           | Lob Publishable API Key                       | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Mailchimp API key                                 | Mailchimp API key                             | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Mailgun private API token                         | Mailgun private API token                     | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Mailgun public verification key                   | Mailgun public validation key                 | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Mailgun webhook signing key                       | Mailgun webhook signing key                   | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Mapbox API token                                  | Mapbox API token                              | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| MaxMind License Key                               | MaxMind License Key                           | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| MessageBird access key                            | messagebird-api-token                         | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| MessageBird API client ID                         | MessageBird API client ID                     | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Meta access token                                 | Meta access token                             | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| New Relic ingest browser API token                | New Relic ingest browser API token            | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| New Relic user API ID                             | New Relic user API ID                         | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| New Relic user API key                            | New Relic user API Key                        | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| npm access token                                  | npm access token                              | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Oculus access token                               | Oculus access token                           | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Onfido Live API Token                             | Onfido Live API Token                         | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| OpenAI API key                                    | open ai token                                 | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Password in URL                                   | Password in URL                               | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| PGP private key                                   | PGP private key                               | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| PKCS8 private key                                 | PKCS8 private key                             | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| PlanetScale API token                             | Planetscale API token                         | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| PlanetScale password                              | Planetscale password                          | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Postman API token                                 | Postman API token                             | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Pulumi API token                                  | Pulumi API token                              | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| PyPi upload token                                 | PyPI upload token                             | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| RSA private key                                   | RSA private key                               | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| RubyGems API token                                | Rubygem API token                             | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Segment public API token                          | Segment Public API token                      | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| SendGrid API token                                | Sendgrid API token                            | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Shippo API token                                  | Shippo API token                              | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Shippo Test API token                             | Shippo Test API token                         | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Shopify custom app access token                   | Shopify custom app access token               | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Shopify personal access token                     | Shopify access token                          | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Shopify private app access token                  | Shopify private app access token              | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Shopify shared secret                             | Shopify shared secret                         | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Slack app level token                             | SlackAppLevelToken                            | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Slack bot user OAuth token                        | Slack token                                   | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Slack webhook                                     | Slack Webhook                                 | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| SSH (DSA) private key                             | SSH (DSA) private key                         | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| SSH (EC) private key                              | SSH (EC) private key                          | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| SSH private key                                   | SSH private key                               | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Stripe live restricted key                        | StripeLiveRestrictedKey                       | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Stripe live secret key                            | StripeLiveSecretKey                           | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Stripe publishable live key                       | StripeLivePublishableKey                      | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Stripe publishable test key                       | StripeTestPublishableKey                      | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Stripe restricted test key                        | StripeTestRestrictedKey                       | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Stripe secret test key                            | StripeTestSecretKey                           | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Tailscale key                                     | Tailscale key                                 | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Twilio API key                                    | Twilio API Key                                | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="check-circle" >}} Yes |
| Twitch OAuth client secret                        | Twitch API token                              | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Typeform personal access token                    | Typeform API token                            | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| X token                                           | Twitter token                                 | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Yandex.Cloud AWS API compatible access secret     | Yandex.Cloud AWS API compatible Access Secret | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Yandex.Cloud IAM cookie v1-1                      | Yandex.Cloud IAM Cookie v1 - 1                | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Yandex.Cloud IAM cookie v1-2                      | Yandex.Cloud IAM Cookie v1 - 2                | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |
| Yandex.Cloud IAM cookie v1-3                      | Yandex.Cloud IAM Cookie v1 - 3                | {{< icon name="check-circle" >}} Yes | {{< icon name="dotted-circle" >}} No | {{< icon name="dotted-circle" >}} No |

<!-- vale gitlab_base.SentenceSpacing = YES -->
<!-- markdownlint-enable MD034 -->
<!-- markdownlint-enable MD044 -->
