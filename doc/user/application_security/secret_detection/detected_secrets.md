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

Secret detection rules are updated in the [default ruleset](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/tree/main).
Detected secrets with patterns that have been removed or updated remain open so you can triage them.

<!-- markdownlint-disable MD044 -->
<!-- vale gitlab_base.SentenceSpacing = NO -->

| Description                                   | ID                                            | Pipeline secret detection | Client-side secret detection | Secret push protection |
|:----------------------------------------------|:----------------------------------------------|:--------------------------|:-----------------------------|:-----------------------|
| Adafruit IO Key                               | AdafruitIOKey                                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Adobe Client ID (OAuth Web)                       | Adobe Client ID (Oauth Web)                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Adobe client secret                               | Adobe Client Secret                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Age secret key                                    | Age secret key                                | {{< yes >}} | {{< no >}} | {{< no >}} |
| Aiven Service Password                            | AivenServicePassword                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Alibaba AccessKey ID                              | Alibaba AccessKey ID                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| Alibaba Secret Key                                | Alibaba Secret Key                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Amazon OAuth Client ID                            | AmazonOAuthClientID                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Anthropic API key                                 | anthropic_key                                 | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Artifactory API Key                               | ArtifactoryApiKey                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Artifactory Identity Token                        | ArtifactoryIdentityToken                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Asana client ID                                   | Asana Client ID                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| Asana client secret                               | Asana Client Secret                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Asana Personal Access Token V1                   | AsanaPersonalAccessTokenV1                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Asana Personal Access Token V2                   | AsanaPersonalAccessTokenV2                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Atlassian API Key                                 | AtlassianApiKey                               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Atlassian API token                               | Atlassian API token                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Atlassian User API Token                          | AtlassianUserApiToken                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Auth0 Client Secret                               | Auth0ClientSecret                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| AWS Access Key ID                                 | AWS                                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| AWS Access Secret Key                             | AWSSecretAccessKey                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| AWS Session Token                                 | AWSSessionToken                               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| AWS Cognito Identity Pool ID                      | AWSCognitoIdentityPoolID                      | {{< yes >}} | {{< no >}} | {{< no >}} |
| AWS Bedrock Key                                   | AWSBedrockKey                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| AWS Bedrock Short-lived Key                       | AWSBedrockShortLivedKey                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure API Management Gateway Key                  | AzureAPIManagementGatewayKey                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure API Management Direct Key                   | AzureAPIManagementDirectKey                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Azure App Config                                  | AzureAppConfigConnectionString                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure Communication Services                      | AzureCommServicesConnectionString                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure Cosmos DB Credentials                       | AzureCosmosDBCredentials                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Azure Entra Client Secret                         | AzureEntraClientSecret                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure Entra Client ID Token                       | AzureEntraIDToken                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure EventGrid Access Key                        | AzureEventGridAccessKey                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Azure Functions API Key                           | AzureFunctionsAPIKey                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure Logic App SAS                               | AzureLogicAppSAS                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure OpenAI API Key                              | AzureOpenAIAPIKey                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Azure Personal Access Token                       | AzurePersonalAccessToken                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Azure SignalR Access Key                          | AzureSignalRAccessKey                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Beamer API token                                  | Beamer API token                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Bitbucket client ID                               | Bitbucket client ID                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Bitbucket client secret                           | Bitbucket client secret                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Brevo API token                                   | Sendinblue API token                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Brevo SMTP token                                  | Sendinblue SMTP token                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Canada Digital Service Notify API Key             | CDSCanadaNotifyAPIKey                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| CircleCI access token                             | CircleCI access tokens                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| CircleCI Personal Access Token                    | CircleCIPersonalAccessToken                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clojars deploy token                              | Clojars API token                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| Contentful delivery API token                     | Contentful delivery API token                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| Contentful personal access token                  | ContentfulPersonalAccessToken                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Contentful preview API token                      | Contentful preview API token                  | {{< yes >}} | {{< no >}} | {{< no >}} |
| Databricks API token                              | Databricks API token                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| DataDog API Key                                   | DataDogAPIKey                                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| DigitalOcean OAuth access token                   | digitalocean-access-token                     | {{< yes >}} | {{< no >}} | {{< no >}} |
| DigitalOcean personal access token                | digitalocean-pat                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| DigitalOcean refresh token                        | digitalocean-refresh-token                    | {{< yes >}} | {{< no >}} | {{< no >}} |
| Discord API key                                   | Discord API key                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| Discord client ID                                 | Discord client ID                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| Discord client secret                             | Discord client secret                         | {{< yes >}} | {{< no >}} | {{< no >}} |
| Docker Personal Access Token                      | DockerPersonalAccessToken                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Doppler API token                                 | Doppler API token                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Doppler Service token                             | Doppler Service token                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Dropbox API secret/key                            | Dropbox API secret/key                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Dropbox App Access Token                          | DropboxAppAccessToken                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Dropbox long lived API token                      | Dropbox long lived API token                  | {{< yes >}} | {{< no >}} | {{< no >}} |
| Dropbox short lived API token                     | Dropbox short lived API token                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Duffel API token                                  | Duffel API token                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Dynatrace Platform Token                          | DynatracePlatformToken                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| EasyPost production API key                       | EasyPost API token                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| EasyPost test API key                             | EasyPost test API token                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Facebook token                                    | Facebook token                                | {{< yes >}} | {{< no >}} | {{< no >}} |
| Fastly API user or automation token               | Fastly API token                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Figma Personal Access Token                       | FigmaPersonalAccessToken                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Finicity API token                                | Finicity API token                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Finicity client secret                            | Finicity client secret                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Flutterwave Prod Encrypted Key                    | FlutterwaveProdEncryptedKey                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Flutterwave test encrypted key                    | Flutterwave encrypted key                     | {{< yes >}} | {{< no >}} | {{< no >}} |
| Flutterwave Prod Public Key                       | FlutterwaveProdPublicKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Flutterwave test public key                       | Flutterwave public key                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Flutterwave Prod Secret Key                       | FlutterwaveProdSecretKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Flutterwave test secret key                       | Flutterwave secret key                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Frame.io API token                                | Frame.io API token                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| GCP API key                                       | GCP API key                                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| GCP OAuth client secret                           | GCP OAuth client secret                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GCP Vertex Express Mode Key                       | GCPVertexExpressModeKey                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHub app token                                  | Github App Token                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHub App Installation Token                     | GithubAppInstallationToken                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHub Fine Grained Personal Access Token         | GithubFineGrainedPersonalAccessToken          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHub OAuth Access Token                         | Github OAuth Access Token                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHub personal access token (classic)            | Github Personal Access Token                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHub refresh token                              | Github Refresh Token                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitLab CI/CD job token                            | gitlab_ci_build_token                         | {{< yes >}} | {{< yes >}} | {{< no >}} |
| GitLab deploy token                               | gitlab_deploy_token                           | {{< yes >}} | {{< yes >}} | {{< no >}} |
| GitLab Feature Flags Client Token                 | None                                          | {{< no >}} | {{< yes >}} | {{< no >}} |
| GitLab feed token                                 | gitlab_feed_token                             | {{< yes >}} | {{< yes >}} | {{< no >}} |
| GitLab feed token v2                              | gitlab_feed_token_v2                          | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab incoming email token                       | gitlab_incoming_email_token                   | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab Kubernetes agent token                     | gitlab_kubernetes_agent_token                 | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab OAuth application secret                   | gitlab_oauth_app_secret                       | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab personal access token                      | gitlab_personal_access_token                  | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab Personal Access Token (routable)           | gitlab_personal_access_token_routable         | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab pipeline trigger token                     | gitlab_pipeline_trigger_token                 | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab runner authentication token                | gitlab_runner_auth_token                      | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab runner registration token                  | gitlab_runner_registration_token              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitLab SCIM OAuth token                           | gitlab_scim_oauth_token                       | {{< yes >}} | {{< yes >}} | {{< no >}} |
| GoCardless API token                              | GoCardless API token                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| Google API key                                    | GCP API key                                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Google (GCP) service account                      | Google (GCP) Service-account                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Grafana Service Account Token                     | GrafanaServiceAccountToken                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Grafana Cloud Access Policy Token                 | GrafanaCloudAccessPolicyToken                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| HashiCorp Terraform API token                     | Hashicorp Terraform user/org API token        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| HashiCorp Vault batch token                       | Hashicorp Vault batch token                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| HashiCorp Vault Service Token                     | HashicorpVaultServiceToken                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Heroku API key or application authorization token | Heroku API Key                                | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Highnote Live Secret Key                          | HighnoteLiveSecretKey                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Highnote Test Secret Key                          | HighnoteTestSecretKey                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| HubSpot private app API token                     | Hubspot API token                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Hugging Face User Access Token                    | HuggingFaceUserAccessToken                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Instagram access token                            | Instagram access token                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Intercom API token                                | Intercom API token                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Intercom App Access Token                         | IntercomAppAccessToken                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Intercom client secret or client ID               | Intercom client secret/ID                     | {{< yes >}} | {{< no >}} | {{< no >}} |
| Ionic personal access token                       | Ionic API token                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| Kubernetes Service Account Token                  | KubernetesServiceAccToken                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| LangChain API Key                                 | LangChainAPIKey                               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Linear API token                                  | Linear API token                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Linear client secret or ID (OAuth 2.0)            | Linear client secret/ID                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| LinkedIn client ID                                | Linkedin Client ID                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| LinkedIn client secret                            | Linkedin Client secret                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Lob API key                                       | Lob API Key                                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Lob publishable API key                           | Lob Publishable API Key                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Mailchimp API key                                 | Mailchimp API key                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Mailgun private API token                         | Mailgun private API token                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Mailgun public verification key                   | Mailgun public validation key                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| Mailgun webhook signing key                       | Mailgun webhook signing key                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Mapbox API token                                  | Mapbox API token                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Mapbox Secret API Token                           | MapboxSecretApiToken                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| MaxMind License Key                               | MaxMind License Key                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| MessageBird access key                            | messagebird-api-token                         | {{< yes >}} | {{< no >}} | {{< no >}} |
| MessageBird API client ID                         | MessageBird API client ID                     | {{< yes >}} | {{< no >}} | {{< no >}} |
| Meta access token                                 | Meta access token                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| New Relic ingest browser API token                | New Relic ingest browser API token            | {{< yes >}} | {{< no >}} | {{< no >}} |
| New Relic ingest browser API token v2             | New Relic ingest browser API token v2         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| New Relic REST API Key                            | New Relic REST API Key                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| New Relic user API ID                             | New Relic user API ID                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| New Relic user API key                            | New Relic user API Key                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| npm access token                                  | npm access token                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Oculus access token                               | Oculus access token                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Okta API Token                                    | OktaAPIToken                                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Okta Client Secret                                | OktaClientSecret                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Onfido Live API Token                             | Onfido Live API Token                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| OpenAI API key                                    | open ai token                                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| OpenAI Project Key                                | OpenAiProjectKey                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| OpenAI Service Account Key                        | OpenAiServiceAccountKey                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Password in URL                                   | Password in URL                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| PGP private key                                   | PGP private key                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| PKCS8 private key                                 | PKCS8 private key                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| PlanetScale API token                             | Planetscale API token                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| PlanetScale App Secret                            | PlanetscaleAppSecret                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| PlanetScale OAuth Secret                          | PlanetscaleOAuthSecret                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| PlanetScale password                              | Planetscale password                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| PostHog Personal API key                          | PostHogPersonalAPIkey                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| PostHog Project API key                           | PostHogProjectAPIkey                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Postman API token                                 | Postman API token                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| Postman Collection Access Key                     | PostmanCollectionAccessKey                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Pulumi API token                                  | Pulumi API token                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| PyPi upload token                                 | PyPI upload token                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| RSA private key                                   | RSA private key                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| RubyGems API token                                | Rubygem API token                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Segment public API token                          | Segment Public API token                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| SendGrid API token                                | Sendgrid API token                            | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Shippo API token                                  | Shippo API token                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Shippo Test API token                             | Shippo Test API token                         | {{< yes >}} | {{< no >}} | {{< no >}} |
| Shopify Partner API Token                         | ShopifyPartnerAPIToken                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Shopify personal access token                     | Shopify access token                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Shopify private app access token                  | Shopify private app access token              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Shopify Custom App Access Token                   | Shopify custom app access token               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Shopify shared secret                             | Shopify shared secret                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Slack App Configuration Token                     | SlackAppConfigurationToken                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Slack App Configuration Refresh Token             | SlackAppConfigurationRefreshToken             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Slack app level token                             | SlackAppLevelToken                            | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Slack bot user OAuth token                        | Slack token                                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Slack webhook                                     | Slack Webhook                                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| SonarQube Global Analysis Token                   | SonarQubeGlobalAnalysisToken                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| SonarQube Project Analysis Token                  | SonarQubeProjectAnalysisToken                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| SonarQube User Token                              | SonarQubeUserToken                            | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Splunk Authentication Token                       | SplunkAuthToken                               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Splunk HTTP Event Collector (HEC) Token            | SplunkHECToken                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| SSH (DSA) private key                             | SSH (DSA) private key                         | {{< yes >}} | {{< no >}} | {{< no >}} |
| SSH (EC) private key                              | SSH (EC) private key                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| SSH private key                                   | SSH private key                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| Stripe live restricted key                        | StripeLiveRestrictedKey                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Stripe live secret key                            | StripeLiveSecretKey                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Stripe Live Short Secret Key                      | StripeLiveShortSecretKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Stripe publishable live key                       | StripeLivePublishableKey                      | {{< yes >}} | {{< no >}} | {{< no >}} |
| Stripe publishable test key                       | StripeTestPublishableKey                      | {{< yes >}} | {{< no >}} | {{< no >}} |
| Stripe restricted test key                        | StripeTestRestrictedKey                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Stripe secret test key                            | StripeTestSecretKey                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Stripe Test Short Secret Key                      | StripeTestShortSecretKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Tailscale OAuth Client Secret                     | TailscaleOauthClientSecret                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Tailscale API Access Token                        | TailscaleApiAccessToken                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Tailscale Personal Auth Key                       | TailscalePersonalAuthKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Tencent Cloud Secret ID                           | TencentCloudSecretID                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Twilio Account SID                                | Twilio Account SID                            | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Twilio API key                                    | Twilio API Key                                | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Twitch OAuth client secret                        | Twitch API token                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Typeform personal access token                    | Typeform API token                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Volcengine Access Key ID                          | VolcengineAccessKeyID                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| WakaTime API Key                                  | WakaTimeAPIKey                                | {{< yes >}} | {{< no >}} | {{< yes >}} |
| X token                                           | Twitter token                                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| Yandex.Cloud AWS API compatible access secret     | Yandex.Cloud AWS API compatible Access Secret | {{< yes >}} | {{< no >}} | {{< no >}} |
| Yandex.Cloud API Key                              | Yandex.Cloud API Key                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| Yandex.Cloud IAM cookie v1-1                      | Yandex.Cloud IAM Cookie v1 - 1                | {{< yes >}} | {{< no >}} | {{< no >}} |
| Yandex.Cloud IAM cookie v1-3                      | Yandex.Cloud IAM Cookie v1 - 3                | {{< yes >}} | {{< no >}} | {{< no >}} |

<!-- vale gitlab_base.SentenceSpacing = YES -->
<!-- markdownlint-enable MD044 -->
