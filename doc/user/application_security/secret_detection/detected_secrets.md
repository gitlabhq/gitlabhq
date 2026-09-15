---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Detected secrets
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Secret categories

GitLab Secret Detection identifies secrets using two approaches: rule-based detection and generic detection.

### Rule-based detection

Rule-based detection identifies secrets by matching scanned content against a known pattern for each
credential type, called a rule. For example, a GitLab personal access token is identified by the pattern
`glpat-` followed by a 20-character string. GitLab supports
[200+ rules](#supported-rules-for-rule-based-detection) covering popular vendors by default.

Rule-based detection's coverage is limited to the rules the analyzer supports.
Secrets that don't match a supported rule aren't detected. Both the Gitleaks-based analyzer
and [GitLab Secret Scanning for Source Code](gitlab_secret_scanner/_index.md)
support rule-based detection.

### Generic detection

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta

{{< /details >}}

Rule-based detection can only find secrets that match a pattern it already knows about.
Many credentials don't follow a published or consistent format, so no rule can match them.
For example, a password for an internal service, a database connection string, or an API key
with no distinguishing prefix.
Generic detection targets these secrets.
Instead of matching a fixed pattern, generic detection examines the context around a value and the properties
of the value itself. Both signals determine whether the value is likely to be a credential.

Because generic detection doesn't depend on a known pattern, it can catch secrets that rule-based
detection misses. It's also more prone to false positives, so GitLab Secret Scanning for Source Code
includes false positive reduction to reduce noise.

GitLab Secret Scanning for Source Code is the only GitLab analyzer that supports generic detection.
For more information, see [generic secrets](gitlab_secret_scanner/_index.md#generic-secrets).

Generic detection isn't limited to an obvious `secret = "value"` assignment.
The following snippet shows less obvious values it identifies, and the finding each one produces:

```plaintext
# Secret assigned in a Perl hash, not a plain key-value pair
$config{'webhook_token'} = "Of0Pg2Qh4Ri6Sj8Tk";

# Password stored as the content of an XML element, not an attribute
<db_password>Ct8Du0Ev2Fw4Gx6Hy</db_password>

# API key passed as a URL query parameter
https://app.gitlab.com?api_key=Of3Pg5Qh7Ri9Sj1Tk

# Token embedded as a literal value in a SQL statement
INSERT INTO secrets (key, value) VALUES ('api_token', 'Kb1Lc3Md5Ne7Of9Pg');

# Password assigned through an environment variable lookup, not a plain variable
ENV["redis_pass"] = "Tt7Yy9Uu1Ii3OoPp5"

# Token passed as an argument to a setter method, not a direct assignment
config.put("dbToken", "Kb8Lc0Md2Ne4Of6Pg");

# Bearer token embedded in an XML configuration property
<property name="authorizationHeader" value="Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"/>

# Secret passed as a CLI flag, not a variable assignment
curl "https://api.example.com/v1/deploy" --api-token=7bN2vLpQ9wXzKfM4

# Credential left behind in a comment
# old admin password was T3mpP@ssw0rd2023XyZ1, rotate before removing this line

# UUID-formatted secret
client_secret: 123e4567-e89b-12d3-a456-426614174000

# Secret disguised by Base64 encoding
auth_token = "c2VjcmV0LWFwaS1rZXktdmFsdWU="

# Secret disguised by hex encoding
signing_key = "4f3c2b1a9e8d7c6b5a4938271605f4e3d2c1b0a"
```

#### Generic secret findings

When a generic secret is found, GitLab labels the finding in the vulnerability report based on the type of value it detected:

- `Generic Password`: A human-defined password, such as a database password or a service password.
- `Generic Secret`: A machine-generated credential, such as an API key or access token, that doesn't match a known vendor format.
- `Generic UUID Secret`, `Generic Base64-Encoded Secret`, `Generic Base64URL-Encoded Secret`, `Generic Hex-Encoded Secret`, `Generic JWT Token`, and `Generic Paseto Token`: Machine-generated credentials that GitLab further classified by their format.

Each finding includes a description that explains why the value was flagged. The description provides
guidance on how to confirm whether the value is a real secret, rotate a confirmed secret, or
dismiss a false positive.

#### Secrets generic detection might miss

Generic detection identifies a secret from its surroundings, such as a keyword or the format of the value,
not from confirming what the value does. This approach has trade-offs. Even with false positive reduction in
place, some non-secret values can show up as findings. For example:

- A secret built through concatenation or string interpolation, such as `full_key = prefix + secret_suffix`.
- A secret with no recognizable keyword nearby, such as a hardcoded value with no label like `key`, `secret`, `token`, or `password` next to it.
- A secret in a file or path that generic detection excludes, such as a vendored dependency, a generated file, or documentation.
- A value that's shorter than the minimum length generic detection expects for that type of secret.
- A secret reported at medium or low confidence. GitLab Secret Scanning for Source Code shows only high-confidence findings in the vulnerability report.

## Supported rules for rule-based detection

This table lists the rules used for rule-based detection, and shows whether each is supported by:

- Pipeline secret detection
- Client-side secret detection
- Secret push protection

Secret detection rules are updated in the [default ruleset](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/tree/main).
Detected secrets with patterns that have been removed or updated remain open so you can triage them.

If you want to add a new secret detection rule, you can [propose new detection rules](pipeline/configure.md#propose-new-detection-rules) for all GitLab users, or [customize rulesets](pipeline/configure.md#customize-analyzer-rulesets) for your specific project.

<!-- markdownlint-disable MD044 -->
<!-- vale gitlab_base.Spelling = NO -->
<!-- vale gitlab_base.SentenceSpacing = NO -->

| Description                                   | ID                                            | Pipeline secret detection | Client-side secret detection | Secret push protection |
|:----------------------------------------------|:----------------------------------------------|:--------------------------|:-----------------------------|:-----------------------|
| Adafruit IO Key                               | AdafruitIOKey                                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Adobe Client ID (OAuth Web)                       | Adobe Client ID (Oauth Web)                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Adobe client secret                               | Adobe Client Secret                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Adobe IMS Access Token                            | AdobeIMSAccessToken                           | {{< yes >}} | {{< no >}} | {{< no >}} |
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
| CircleCI access token                             | CircleCI access tokens                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
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
| JFrog Platform Access Tokens                      | JfrogPlatformAccessToken                      | {{< yes >}} | {{< no >}} | {{< no >}} |
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
<!-- vale gitlab_base.Spelling = YES -->
<!-- markdownlint-enable MD044 -->
