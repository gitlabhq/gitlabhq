---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Detected secrets
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This table lists the secrets detected by:

- Pipeline secret detection
- Client-side secret detection
- Secret push protection

<!-- markdownlint-disable MD034 -->
<!-- markdownlint-disable MD044 -->
<!-- vale gitlab_base.SentenceSpacing = NO -->

| Description                                   | ID                                            | Pipeline secret detection | Client-side secret detection | Secret push protection |
|:----------------------------------------------|:----------------------------------------------|:--------------------------|:-----------------------------|:-----------------------|
| Adobe Client ID (OAuth Web)                   | Adobe Client ID (OAuth Web)                   | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Adobe Client Secret                           | Adobe Client Secret                           | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Age secret key                                | Age secret key                                | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Alibaba AccessKey ID                          | Alibaba AccessKey ID                          | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Alibaba Secret Key                            | Alibaba Secret Key                            | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Anthropic keys                                | anthropic_key                                 | **{check-circle}** Yes    | **{check-circle}** Yes       | **{dotted-circle}** No |
| Asana Client ID                               | Asana Client ID                               | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Asana Client Secret                           | Asana Client Secret                           | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Atlassian API token                           | Atlassian API token                           | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| AWS Access Token                              | AWS                                           | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| Beamer API token                              | Beamer API token                              | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Bitbucket client ID                           | Bitbucket client ID                           | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Bitbucket client secret                       | Bitbucket client secret                       | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| CircleCI access tokens                        | CircleCI access tokens                        | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Clojars API token                             | Clojars API token                             | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Contentful delivery API token                 | Contentful delivery API token                 | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Contentful preview API token                  | Contentful preview API token                  | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Databricks API token                          | Databricks API token                          | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| DigitalOcean OAuth Access Token               | digitalocean-access-token                     | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| DigitalOcean OAuth Refresh Token              | digitalocean-refresh-token                    | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| DigitalOcean Personal Access Token            | digitalocean-pat                              | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Discord API key                               | Discord API key                               | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Discord client ID                             | Discord client ID                             | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Discord client secret                         | Discord client secret                         | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Doppler API token                             | Doppler API token                             | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Dropbox API secret/key                        | Dropbox API secret/key                        | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Dropbox long lived API token                  | Dropbox long lived API token                  | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Dropbox short lived API token                 | Dropbox short lived API token                 | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Duffel API token                              | Duffel API token                              | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Dynatrace API token                           | Dynatrace API token                           | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| EasyPost API token                            | EasyPost API token                            | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| EasyPost test API token                       | EasyPost test API token                       | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Facebook token                                | Facebook token                                | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Fastly API token                              | Fastly API token                              | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Finicity API token                            | Finicity API token                            | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Finicity client secret                        | Finicity client secret                        | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Flutterwave encrypted key                     | Flutterwave encrypted key                     | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Flutterwave public key                        | Flutterwave public key                        | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Flutterwave secret key                        | Flutterwave secret key                        | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Frame.io API token                            | Frame.io API token                            | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| GCP API keys                                  | GCP API key                                   | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| GCP OAuth client secret                       | GCP OAuth client secret                       | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| GitHub App Token                              | GitHub App Token                              | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| GitHub OAuth Access Token                     | GitHub OAuth Access Token                     | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| GitHub Personal Access Token                  | GitHub Personal Access Token                  | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| GitHub Refresh Token                          | GitHub Refresh Token                          | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| GitLab Agent for Kubernetes token             | gitlab_kubernetes_agent_token                 | **{check-circle}** Yes    | **{check-circle}** Yes       | **{check-circle}** Yes |
| GitLab CI Build (Job) token                   | gitlab_ci_build_token                         | **{check-circle}** Yes    | **{check-circle}** Yes       | **{dotted-circle}** No |
| GitLab Deploy Token                           | gitlab_deploy_token                           | **{check-circle}** Yes    | **{check-circle}** Yes       | **{dotted-circle}** No |
| GitLab Feature Flags Client Token             | None                                          | **{dotted-circle}** No    | **{check-circle}** Yes       | **{dotted-circle}** No |
| GitLab Feed Token                             | gitlab_feed_token                             | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| GitLab Feed Token                             | gitlab_feed_token_v2                          | **{check-circle}** Yes    | **{check-circle}** Yes       | **{check-circle}** Yes |
| GitLab Incoming email token                   | gitlab_incoming_email_token                   | **{check-circle}** Yes    | **{check-circle}** Yes       | **{check-circle}** Yes |
| GitLab OAuth Application Secrets              | gitlab_oauth_app_secret                       | **{check-circle}** Yes    | **{check-circle}** Yes       | **{check-circle}** Yes |
| GitLab Personal Access Token                  | gitlab_personal_access_token                  | **{check-circle}** Yes    | **{check-circle}** Yes       | **{check-circle}** Yes |
| GitLab Pipeline Trigger Token                 | gitlab_pipeline_trigger_token                 | **{check-circle}** Yes    | **{check-circle}** Yes       | **{check-circle}** Yes |
| GitLab Runner Authentication Token            | gitlab_runner_auth_token                      | **{check-circle}** Yes    | **{check-circle}** Yes       | **{check-circle}** Yes |
| GitLab Runner Registration Token              | gitlab_runner_registration_token              | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| GitLab SCIM token                             | gitlab_scim_oauth_token                       | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| GoCardless API token                          | GoCardless API token                          | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Google (GCP) Service-account                  | Google (GCP) Service-account                  | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| Grafana API token                             | Grafana API token                             | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| Hashicorp Terraform user/org API token        | Hashicorp Terraform user/org API token        | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| Hashicorp Vault batch token                   | Hashicorp Vault batch token                   | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| Heroku API Key                                | Heroku API Key                                | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Hubspot API token                             | Hubspot API token                             | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Instagram access token                        | Instagram access token                        | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Intercom API token                            | Intercom API token                            | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Intercom client secret/ID                     | Intercom client secret/ID                     | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Ionic API token                               | Ionic API token                               | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Linear API token                              | Linear API token                              | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Linear client secret/ID                       | Linear client secret/ID                       | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Linkedin Client ID                            | Linkedin Client ID                            | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Linkedin Client secret                        | Linkedin Client secret                        | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Lob API Key                                   | Lob API Key                                   | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Lob Publishable API Key                       | Lob Publishable API Key                       | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Mailchimp API key                             | Mailchimp API key                             | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| Mailgun private API token                     | Mailgun private API token                     | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| Mailgun public validation key                 | Mailgun public validation key                 | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Mailgun webhook signing key                   | Mailgun webhook signing key                   | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| Mapbox API token                              | Mapbox API token                              | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| MessageBird API client ID                     | MessageBird API client ID                     | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| MessageBird API token                         | messagebird-api-token                         | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Meta access token                             | Meta access token                             | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| New Relic ingest browser API token            | New Relic ingest browser API token            | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| New Relic user API ID                         | New Relic user API ID                         | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| New Relic user API Key                        | New Relic user API Key                        | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| npm access token                              | npm access token                              | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| Oculus access token                           | Oculus access token                           | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Open AI API key                               | open ai token                                 | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Password in URL                               | Password in URL                               | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| PGP private key                               | PGP private key                               | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| PKCS8 private key                             | PKCS8 private key                             | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Planetscale API token                         | Planetscale API token                         | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Planetscale password                          | Planetscale password                          | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Postman API token                             | Postman API token                             | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Pulumi API token                              | Pulumi API token                              | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| PyPI upload token                             | PyPI upload token                             | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| RSA private key                               | RSA private key                               | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Rubygem API token                             | Rubygem API token                             | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| Segment Public API token                      | Segment Public API token                      | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| Sendgrid API token                            | Sendgrid API token                            | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| Sendinblue API token                          | Sendinblue API token                          | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Sendinblue SMTP token                         | Sendinblue SMTP token                         | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Shippo API token                              | Shippo API token                              | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Shopify access token                          | Shopify access token                          | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| Shopify custom app access token               | Shopify custom app access token               | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| Shopify private app access token              | Shopify private app access token              | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| Shopify shared secret                         | Shopify shared secret                         | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| Slack token                                   | Slack token                                   | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| Slack Webhook                                 | Slack Webhook                                 | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| SSH (DSA) private key                         | SSH (DSA) private key                         | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| SSH (EC) private key                          | SSH (EC) private key                          | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| SSH private key                               | SSH private key                               | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Stripe                                        | Stripe                                        | **{check-circle}** Yes    | **{dotted-circle}** No       | **{check-circle}** Yes |
| systemd machine-id                            | systemd-machine-id                            | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Tailscale keys                                | Tailscale key                                 | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Twilio API Key                                | Twilio API Key                                | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Twitch API token                              | Twitch API token                              | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Twitter token                                 | Twitter token                                 | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Typeform API token                            | Typeform API token                            | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Yandex.Cloud AWS API compatible Access Secret | Yandex.Cloud AWS API compatible Access Secret | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Yandex.Cloud IAM API key v1                   | Yandex.Cloud IAM Cookie v1 - 3                | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Yandex.Cloud IAM Cookie v1                    | Yandex.Cloud IAM Cookie v1 - 1                | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |
| Yandex.Cloud IAM Token v1                     | Yandex.Cloud IAM Cookie v1 - 2                | **{check-circle}** Yes    | **{dotted-circle}** No       | **{dotted-circle}** No |

<!-- vale gitlab_base.SentenceSpacing = YES -->
<!-- markdownlint-enable MD034 -->
<!-- markdownlint-enable MD044 -->
