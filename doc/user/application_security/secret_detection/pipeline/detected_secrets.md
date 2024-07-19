---
stage: Secure
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Detected secrets

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** GA

This table lists the secrets detected by [pipeline secret detection](index.md).

<!-- markdownlint-disable MD034 -->
<!-- markdownlint-disable MD037 -->
<!-- markdownlint-disable MD044 -->
<!-- vale gitlab.SentenceSpacing = NO -->

| Description                                                        | ID                                            | Keywords                              |
|:-------------------------------------------------------------------|:----------------------------------------------|:--------------------------------------|
| AWS Access Token                                                   | AWS                                           | AKIA                                  |
| Adobe Client ID (Oauth Web)                                        | Adobe Client ID (Oauth Web)                   | adobe                                 |
| Adobe Client Secret                                                | Adobe Client Secret                           | adobe, p8e-                           |
| Age secret key                                                     | Age secret key                                | AGE-SECRET-KEY-1                      |
| Alibaba AccessKey ID                                               | Alibaba AccessKey ID                          | LTAI                                  |
| Alibaba Secret Key                                                 | Alibaba Secret Key                            | alibaba                               |
| Asana Client ID                                                    | Asana Client ID                               | asana                                 |
| Asana Client Secret                                                | Asana Client Secret                           | asana                                 |
| Atlassian API token                                                | Atlassian API token                           | atlassian                             |
| Beamer API token                                                   | Beamer API token                              | beamer                                |
| Bitbucket client ID                                                | Bitbucket client ID                           | bitbucket                             |
| Bitbucket client secret                                            | Bitbucket client secret                       | bitbucket                             |
| CircleCI access tokens                                             | CircleCI access tokens                        | CircleCI                              |
| Clojars API token                                                  | Clojars API token                             | CLOJARS_                              |
| Contentful delivery API token                                      | Contentful delivery API token                 | contentful                            |
| Contentful preview API token                                       | Contentful preview API token                  | contentful                            |
| Databricks API token                                               | Databricks API token                          | dapi, databricks                      |
| DigitalOcean OAuth Access Token                                    | digitalocean-access-token                     | doo_v1_                               |
| DigitalOcean OAuth Refresh Token                                   | digitalocean-refresh-token                    | dor_v1_                               |
| DigitalOcean Personal Access Token                                 | digitalocean-pat                              | dop_v1_                               |
| Discord API key                                                    | Discord API key                               | discord                               |
| Discord client ID                                                  | Discord client ID                             | discord                               |
| Discord client secret                                              | Discord client secret                         | discord                               |
| Doppler API token                                                  | Doppler API token                             | doppler                               |
| Dropbox API secret/key                                             | Dropbox API secret/key                        | dropbox                               |
| Dropbox long lived API token                                       | Dropbox long lived API token                  | dropbox                               |
| Dropbox short lived API token                                      | Dropbox short lived API token                 | dropbox                               |
| Duffel API token                                                   | Duffel API token                              | duffel                                |
| Dynatrace API token                                                | Dynatrace API token                           | dt0c01                                |
| EasyPost API token                                                 | EasyPost API token                            | EZAK                                  |
| EasyPost test API token                                            | EasyPost test API token                       | EZTK                                  |
| Facebook token                                                     | Facebook token                                | facebook                              |
| Fastly API token                                                   | Fastly API token                              | fastly                                |
| Finicity API token                                                 | Finicity API token                            | finicity                              |
| Finicity client secret                                             | Finicity client secret                        | finicity                              |
| Flutterwave encrypted key                                          | Flutterwave encrypted key                     | FLWSECK_TEST                          |
| Flutterwave public key                                             | Flutterwave public key                        | FLWPUBK_TEST                          |
| Flutterwave secret key                                             | Flutterwave secret key                        | FLWSECK_TEST                          |
| Frame.io API token                                                 | Frame.io API token                            | fio-u-                                |
| GCP API keys can be misused to gain API quota from billed projects | GCP API key                                   | AIza                                  |
| GCP OAuth client secrets can be misused to spoof your application  | GCP OAuth client secret                       | GOCSPX-                               |
| GitLab Agent for Kubernetes token                                  | gitlab_kubernetes_agent_token                 | glagent                               |
| GitLab CI Build (Job) token                                        | gitlab_ci_build_token                         | glcbt                                 |
| GitLab Deploy Token                                                | gitlab_deploy_token                           | gldt                                  |
| GitLab Feed Token                                                  | gitlab_feed_token                             | feed_token                            |
| GitLab Feed token                                                  | gitlab_feed_token_v2                          | glft                                  |
| GitLab Incoming email token                                        | gitlab_incoming_email_token                   | glimt                                 |
| GitLab OAuth Application Secrets                                   | gitlab_oauth_app_secret                       | gloas                                 |
| GitLab Personal Access Token                                       | gitlab_personal_access_token                  | glpat                                 |
| GitLab Pipeline Trigger Token                                      | gitlab_pipeline_trigger_token                 | glptt                                 |
| GitLab Runner Authentication Token                                 | gitlab_runner_auth_token                      | glrt                                  |
| GitLab Runner Registration Token                                   | gitlab_runner_registration_token              | GR1348941                             |
| GitLab SCIM token                                                  | gitlab_scim_oauth_token                       | glsoat                                |
| GitHub App Token                                                   | GitHub App Token                              | ghu_, ghs_                            |
| GitHub OAuth Access Token                                          | GitHub OAuth Access Token                     | gho_                                  |
| GitHub Personal Access Token                                       | GitHub Personal Access Token                  | ghp_                                  |
| GitHub Refresh Token                                               | GitHub Refresh Token                          | ghr_                                  |
| GoCardless API token                                               | GoCardless API token                          | gocardless                            |
| Google (GCP) Service-account                                       | Google (GCP) Service-account                  | service_account                       |
| Grafana API token                                                  | Grafana API token                             | grafana                               |
| Hashicorp Terraform user/org API token                             | Hashicorp Terraform user/org API token        | atlasv1, hashicorp, terraform         |
| Hashicorp Vault batch token                                        | Hashicorp Vault batch token                   | hashicorp, AAAAAQ, vault              |
| Heroku API Key                                                     | Heroku API Key                                | heroku                                |
| Hubspot API token                                                  | Hubspot API token                             | hubspot                               |
| Instagram access token                                             | Instagram access token                        | IG                                    |
| Intercom API token                                                 | Intercom API token                            | intercom                              |
| Intercom client secret/ID                                          | Intercom client secret/ID                     | intercom                              |
| Ionic API token                                                    | Ionic API token                               | ion_                                  |
| Linear API token                                                   | Linear API token                              | lin_api_                              |
| Linear client secret/ID                                            | Linear client secret/ID                       | linear                                |
| Linkedin Client ID                                                 | Linkedin Client ID                            | linkedin                              |
| Linkedin Client secret                                             | Linkedin Client secret                        | linkedin                              |
| Lob API Key                                                        | Lob API Key                                   | lob                                   |
| Lob Publishable API Key                                            | Lob Publishable API Key                       | lob                                   |
| Mailchimp API key                                                  | Mailchimp API key                             | mailchimp                             |
| Mailgun private API token                                          | Mailgun private API token                     | mailgun                               |
| Mailgun public validation key                                      | Mailgun public validation key                 | mailgun                               |
| Mailgun webhook signing key                                        | Mailgun webhook signing key                   | mailgun                               |
| Mapbox API token                                                   | Mapbox API token                              | mapbox                                |
| MessageBird API client ID                                          | MessageBird API client ID                     | messagebird                           |
| MessageBird API token                                              | messagebird-api-token                         | messagebird                           |
| Meta access token                                                  | Meta access token                             | EA                                    |
| New Relic ingest browser API token                                 | New Relic ingest browser API token            | NRJS                                  |
| New Relic user API ID                                              | New Relic user API ID                         | newrelic                              |
| New Relic user API Key                                             | New Relic user API Key                        | NRAK                                  |
| npm access token                                                   | npm access token                              | npm_                                  |
| Oculus access token                                                | Oculus access token                           | OC                                    |
| Open AI API key                                                    | open ai token                                 | sk-                                   |
| PGP private key                                                    | PGP private key                               | -----BEGIN PGP PRIVATE KEY BLOCK----- |
| PKCS8 private key                                                  | PKCS8 private key                             | -----BEGIN PRIVATE KEY-----           |
| Password in URL                                                    | Password in URL                               | Not applicable                        |
| Planetscale API token                                              | Planetscale API token                         | pscale_tkn_                           |
| Planetscale password                                               | Planetscale password                          | pscale_pw_                            |
| Postman API token                                                  | Postman API token                             | PMAK-                                 |
| Pulumi API token                                                   | Pulumi API token                              | pul-                                  |
| PyPI upload token                                                  | PyPI upload token                             | pypi-AgEIcHlwaS5vcmc                  |
| RSA private key                                                    | RSA private key                               | -----BEGIN RSA PRIVATE KEY-----       |
| Rubygem API token                                                  | Rubygem API token                             | rubygems_                             |
| SSH (DSA) private key                                              | SSH (DSA) private key                         | -----BEGIN DSA PRIVATE KEY-----       |
| SSH (EC) private key                                               | SSH (EC) private key                          | -----BEGIN EC PRIVATE KEY-----        |
| SSH private key                                                    | SSH private key                               | -----BEGIN OPENSSH PRIVATE KEY-----   |
| Segment Public API token                                           | Segment Public API token                      | sgp_                                  |
| Sendgrid API token                                                 | Sendgrid API token                            | sendgrid                              |
| Sendinblue API token                                               | Sendinblue API token                          | xkeysib-                              |
| Sendinblue SMTP token                                              | Sendinblue SMTP token                         | xsmtpsib-                             |
| Shippo API token                                                   | Shippo API token                              | shippo_                               |
| Shopify access token                                               | Shopify access token                          | shpat_                                |
| Shopify custom app access token                                    | Shopify custom app access token               | shpca_                                |
| Shopify private app access token                                   | Shopify private app access token              | shppa_                                |
| Shopify shared secret                                              | Shopify shared secret                         | shpss_                                |
| Slack Webhook                                                      | Slack Webhook                                 | https://hooks.slack.com/services      |
| Slack token                                                        | Slack token                                   | xoxb, xoxa, xoxp, xoxr, xoxs          |
| Stripe                                                             | Stripe                                        | sk_test, pk_test, sk_live, pk_live    |
| systemd machine-id                                                 | systemd-machine-id                            | Not applicable                        |
| Tailscale keys                                                     | Tailscale key                                 | tskey-                                |
| Twilio API Key                                                     | Twilio API Key                                | SK, twilio                            |
| Twitch API token                                                   | Twitch API token                              | twitch                                |
| Twitter token                                                      | Twitter token                                 | twitter                               |
| Typeform API token                                                 | Typeform API token                            | typeform                              |
| Yandex.Cloud AWS API compatible Access Secret                      | Yandex.Cloud AWS API compatible Access Secret | yandex                                |
| Yandex.Cloud IAM API key v1                                        | Yandex.Cloud IAM Cookie v1 - 3                | yandex                                |
| Yandex.Cloud IAM Cookie v1                                         | Yandex.Cloud IAM Cookie v1 - 1                | yandex                                |
| Yandex.Cloud IAM Token v1                                          | Yandex.Cloud IAM Cookie v1 - 2                | yandex                                |

<!-- vale gitlab.SentenceSpacing = YES -->
<!-- markdownlint-enable MD044 -->
<!-- markdownlint-enable MD037 -->
<!-- markdownlint-enable MD034 -->
