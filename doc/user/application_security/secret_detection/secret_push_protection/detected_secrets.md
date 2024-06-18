---
stage: Secure
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Detected secrets

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Dedicated
**Status:** Beta

This table lists the secrets detected by [secret push protection](index.md).

<!-- markdownlint-disable MD044 -->
<!-- markdownlint-disable MD037 -->

| Description                                                        | ID                                     | Keywords                           |
|:-------------------------------------------------------------------|:---------------------------------------|:-----------------------------------|
| AWS Access Token                                                   | AWS                                    | AKIA                               |
| GCP API keys can be misused to gain API quota from billed projects | GCP API key                            | AIza                               |
| GCP OAuth client secrets can be misused to spoof your application  | GCP OAuth client secret                | GOCSPX-                            |
| GitLab Agent for Kubernetes token                                  | gitlab_kubernetes_agent_token          | glagent                            |
| GitLab Feed Token                                                  | gitlab_feed_token_v2                   | glft                               |
| GitLab Incoming email token                                        | gitlab_incoming_email_token            | glimt                              |
| GitLab OAuth Application Secrets                                   | gitlab_oauth_app_secret                | gloas                              |
| GitLab Personal Access Token                                       | gitlab_personal_access_token           | glpat                              |
| GitLab Pipeline Trigger Token                                      | gitlab_pipeline_trigger_token          | glptt                              |
| GitLab Runner Authentication Token                                 | gitlab_runner_auth_token               | glrt                               |
| GitLab Runner Registration Token                                   | gitlab_runner_registration_token       | GR1348941                          |
| GitHub App Token                                                   | GitHub App Token                       | ghu_, ghs_                         |
| GitHub OAuth Access Token                                          | GitHub OAuth Access Token              | gho_                               |
| GitHub Personal Access Token                                       | GitHub Personal Access Token           | ghp_                               |
| GitHub Refresh Token                                               | GitHub Refresh Token                   | ghr_                               |
| Google (GCP) Service-account                                       | Google (GCP) Service-account           | service_account                    |
| Grafana API token                                                  | Grafana API token                      | grafana                            |
| Hashicorp Terraform user/org API token                             | Hashicorp Terraform user/org API token | atlasv1, hashicorp, terraform      |
| Hashicorp Vault batch token                                        | Hashicorp Vault batch token            | hashicorp, AAAAAQ, vault           |
| Mailchimp API key                                                  | Mailchimp API key                      | mailchimp                          |
| Mailgun private API token                                          | Mailgun private API token              | mailgun                            |
| Mailgun webhook signing key                                        | Mailgun webhook signing key            | mailgun                            |
| New Relic user API ID                                              | New Relic user API ID                  | newrelic                           |
| New Relic user API Key                                             | New Relic user API Key                 | NRAK                               |
| npm access token                                                   | npm access token                       | npm_                               |
| PyPI upload token                                                  | PyPI upload token                      | pypi-AgEIcHlwaS5vcmc               |
| Rubygem API token                                                  | Rubygem API token                      | rubygems_                          |
| Segment Public API token                                           | Segment Public API token               | sgp_                               |
| Sendgrid API token                                                 | Sendgrid API token                     | sendgrid                           |
| Shopify access token                                               | Shopify access token                   | shpat_                             |
| Shopify custom app access token                                    | Shopify custom app access token        | shpca_                             |
| Shopify private app access token                                   | Shopify private app access token       | shppa_                             |
| Shopify shared secret                                              | Shopify shared secret                  | shpss_                             |
| Slack token                                                        | Slack token                            | xoxb, xoxa, xoxp, xoxr, xoxs       |
| Stripe                                                             | Stripe                                 | sk_test, pk_test, sk_live, pk_live |

<!-- markdownlint-disable MD037 -->
<!-- markdownlint-disable MD044 -->
