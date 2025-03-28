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
| Adobe Client ID (OAuth Web)                   | Adobe Client ID (OAuth Web)                   | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Adobe Client Secret                           | Adobe Client Secret                           | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Age secret key                                | Age secret key                                | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Alibaba AccessKey ID                          | Alibaba AccessKey ID                          | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Alibaba Secret Key                            | Alibaba Secret Key                            | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Anthropic keys                                | anthropic_key                                 | {{< icon name="check-circle" >}} Yes    | {{< icon name="check-circle" >}} Yes       | {{< icon name="check-circle" >}} Yes |
| Asana Client ID                               | Asana Client ID                               | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Asana Client Secret                           | Asana Client Secret                           | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Atlassian API token                           | Atlassian API token                           | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| AWS Access Token                              | AWS                                           | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| Beamer API token                              | Beamer API token                              | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Bitbucket client ID                           | Bitbucket client ID                           | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Bitbucket client secret                       | Bitbucket client secret                       | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| CircleCI access tokens                        | CircleCI access tokens                        | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Clojars API token                             | Clojars API token                             | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Contentful delivery API token                 | Contentful delivery API token                 | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Contentful preview API token                  | Contentful preview API token                  | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Databricks API token                          | Databricks API token                          | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| DigitalOcean OAuth Access Token               | digitalocean-access-token                     | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| DigitalOcean OAuth Refresh Token              | digitalocean-refresh-token                    | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| DigitalOcean Personal Access Token            | digitalocean-pat                              | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Discord API key                               | Discord API key                               | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Discord client ID                             | Discord client ID                             | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Discord client secret                         | Discord client secret                         | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Doppler API token                             | Doppler API token                             | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Dropbox API secret/key                        | Dropbox API secret/key                        | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Dropbox long lived API token                  | Dropbox long lived API token                  | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Dropbox short lived API token                 | Dropbox short lived API token                 | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Duffel API token                              | Duffel API token                              | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Dynatrace API token                           | Dynatrace API token                           | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| EasyPost API token                            | EasyPost API token                            | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| EasyPost test API token                       | EasyPost test API token                       | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Facebook token                                | Facebook token                                | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Fastly API token                              | Fastly API token                              | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Finicity API token                            | Finicity API token                            | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Finicity client secret                        | Finicity client secret                        | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Flutterwave encrypted key                     | Flutterwave encrypted key                     | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Flutterwave public key                        | Flutterwave public key                        | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Flutterwave secret key                        | Flutterwave secret key                        | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Frame.io API token                            | Frame.io API token                            | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| GCP API keys                                  | GCP API key                                   | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| GCP OAuth client secret                       | GCP OAuth client secret                       | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| GitHub App Token                              | GitHub App Token                              | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| GitHub OAuth Access Token                     | GitHub OAuth Access Token                     | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| GitHub Personal Access Token                  | GitHub Personal Access Token                  | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| GitHub Refresh Token                          | GitHub Refresh Token                          | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| GitLab Agent for Kubernetes token             | gitlab_kubernetes_agent_token                 | {{< icon name="check-circle" >}} Yes    | {{< icon name="check-circle" >}} Yes       | {{< icon name="check-circle" >}} Yes |
| GitLab CI Build (Job) token                   | gitlab_ci_build_token                         | {{< icon name="check-circle" >}} Yes    | {{< icon name="check-circle" >}} Yes       | {{< icon name="dotted-circle" >}} No |
| GitLab Deploy Token                           | gitlab_deploy_token                           | {{< icon name="check-circle" >}} Yes    | {{< icon name="check-circle" >}} Yes       | {{< icon name="dotted-circle" >}} No |
| GitLab Feature Flags Client Token             | None                                          | {{< icon name="dotted-circle" >}} No    | {{< icon name="check-circle" >}} Yes       | {{< icon name="dotted-circle" >}} No |
| GitLab Feed Token                             | gitlab_feed_token                             | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| GitLab Feed Token                             | gitlab_feed_token_v2                          | {{< icon name="check-circle" >}} Yes    | {{< icon name="check-circle" >}} Yes       | {{< icon name="check-circle" >}} Yes |
| GitLab Incoming email token                   | gitlab_incoming_email_token                   | {{< icon name="check-circle" >}} Yes    | {{< icon name="check-circle" >}} Yes       | {{< icon name="check-circle" >}} Yes |
| GitLab OAuth Application Secrets              | gitlab_oauth_app_secret                       | {{< icon name="check-circle" >}} Yes    | {{< icon name="check-circle" >}} Yes       | {{< icon name="check-circle" >}} Yes |
| GitLab Personal Access Token                  | gitlab_personal_access_token                  | {{< icon name="check-circle" >}} Yes    | {{< icon name="check-circle" >}} Yes       | {{< icon name="check-circle" >}} Yes |
| GitLab Personal Access Token (Routable)       | gitlab_personal_access_token_routable         | {{< icon name="check-circle" >}} Yes    | {{< icon name="check-circle" >}} Yes       | {{< icon name="check-circle" >}} Yes |
| GitLab Pipeline Trigger Token                 | gitlab_pipeline_trigger_token                 | {{< icon name="check-circle" >}} Yes    | {{< icon name="check-circle" >}} Yes       | {{< icon name="check-circle" >}} Yes |
| GitLab Runner Authentication Token            | gitlab_runner_auth_token                      | {{< icon name="check-circle" >}} Yes    | {{< icon name="check-circle" >}} Yes       | {{< icon name="check-circle" >}} Yes |
| GitLab Runner Registration Token              | gitlab_runner_registration_token              | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| GitLab SCIM token                             | gitlab_scim_oauth_token                       | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| GoCardless API token                          | GoCardless API token                          | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Google (GCP) Service-account                  | Google (GCP) Service-account                  | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| Grafana API token                             | Grafana API token                             | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| Hashicorp Terraform user/org API token        | Hashicorp Terraform user/org API token        | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| Hashicorp Vault batch token                   | Hashicorp Vault batch token                   | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| Heroku API Key                                | Heroku API Key                                | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Hubspot API token                             | Hubspot API token                             | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Instagram access token                        | Instagram access token                        | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Intercom API token                            | Intercom API token                            | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Intercom client secret/ID                     | Intercom client secret/ID                     | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Ionic API token                               | Ionic API token                               | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Linear API token                              | Linear API token                              | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Linear client secret/ID                       | Linear client secret/ID                       | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Linkedin Client ID                            | Linkedin Client ID                            | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Linkedin Client secret                        | Linkedin Client secret                        | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Lob API Key                                   | Lob API Key                                   | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Lob Publishable API Key                       | Lob Publishable API Key                       | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Mailchimp API key                             | Mailchimp API key                             | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| Mailgun private API token                     | Mailgun private API token                     | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| Mailgun public validation key                 | Mailgun public validation key                 | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Mailgun webhook signing key                   | Mailgun webhook signing key                   | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| Mapbox API token                              | Mapbox API token                              | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| MessageBird API client ID                     | MessageBird API client ID                     | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| MessageBird API token                         | messagebird-api-token                         | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Meta access token                             | Meta access token                             | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| New Relic ingest browser API token            | New Relic ingest browser API token            | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| New Relic user API ID                         | New Relic user API ID                         | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| New Relic user API Key                        | New Relic user API Key                        | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| npm access token                              | npm access token                              | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| Oculus access token                           | Oculus access token                           | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Open AI API key                               | open ai token                                 | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Password in URL                               | Password in URL                               | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| PGP private key                               | PGP private key                               | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| PKCS8 private key                             | PKCS8 private key                             | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Planetscale API token                         | Planetscale API token                         | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Planetscale password                          | Planetscale password                          | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Postman API token                             | Postman API token                             | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Pulumi API token                              | Pulumi API token                              | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| PyPI upload token                             | PyPI upload token                             | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| RSA private key                               | RSA private key                               | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Rubygem API token                             | Rubygem API token                             | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| Segment Public API token                      | Segment Public API token                      | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| Sendgrid API token                            | Sendgrid API token                            | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| Sendinblue API token                          | Sendinblue API token                          | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Sendinblue SMTP token                         | Sendinblue SMTP token                         | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Shippo API token                              | Shippo API token                              | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Shopify access token                          | Shopify access token                          | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| Shopify custom app access token               | Shopify custom app access token               | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| Shopify private app access token              | Shopify private app access token              | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| Shopify shared secret                         | Shopify shared secret                         | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| Slack token                                   | Slack token                                   | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| Slack Webhook                                 | Slack Webhook                                 | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| SSH (DSA) private key                         | SSH (DSA) private key                         | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| SSH (EC) private key                          | SSH (EC) private key                          | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| SSH private key                               | SSH private key                               | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Stripe                                        | Stripe                                        | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="check-circle" >}} Yes |
| systemd machine-id                            | systemd-machine-id                            | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Tailscale keys                                | Tailscale key                                 | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Twilio API Key                                | Twilio API Key                                | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Twitch API token                              | Twitch API token                              | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Twitter token                                 | Twitter token                                 | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Typeform API token                            | Typeform API token                            | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Yandex.Cloud AWS API compatible Access Secret | Yandex.Cloud AWS API compatible Access Secret | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Yandex.Cloud IAM API key v1                   | Yandex.Cloud IAM Cookie v1 - 3                | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Yandex.Cloud IAM Cookie v1                    | Yandex.Cloud IAM Cookie v1 - 1                | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |
| Yandex.Cloud IAM Token v1                     | Yandex.Cloud IAM Cookie v1 - 2                | {{< icon name="check-circle" >}} Yes    | {{< icon name="dotted-circle" >}} No       | {{< icon name="dotted-circle" >}} No |

<!-- vale gitlab_base.SentenceSpacing = YES -->
<!-- markdownlint-enable MD034 -->
<!-- markdownlint-enable MD044 -->
