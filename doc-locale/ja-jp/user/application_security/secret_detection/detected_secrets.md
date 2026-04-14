---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 検出されたシークレット
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

この表は、シークレットによって検出されたシークレットを一覧表示します:

- パイプラインシークレット検出
- クライアントサイドシークレット検出
- シークレットプッシュ保護

シークレット検出ルールは、[デフォルトのルールセット](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/tree/main)で更新されます。削除または更新されたパターンを持つ検出されたシークレットは、トリアージできるように、開いたままになります。

新しいシークレット検出ルールを追加する場合は、すべてのGitLabユーザーに対して[新しい検出ルールを提案](pipeline/configure.md#propose-new-detection-rules)するか、特定のプロジェクトに対して[ルールセットをカスタマイズ](pipeline/configure.md#customize-analyzer-rulesets)します。

<!-- markdownlint-disable MD044 -->
<!-- vale gitlab_base.Spelling = NO -->
<!-- vale gitlab_base.SentenceSpacing = NO -->

| 説明                                   | ID                                            | パイプラインシークレット検出 | クライアントサイドシークレット検出 | シークレットプッシュ保護 |
|:----------------------------------------------|:----------------------------------------------|:--------------------------|:-----------------------------|:-----------------------|
| Adafruit IOキー                               | AdafruitIOKey                                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| AdobeクライアントID (OAuth Web)                       | Adobe Client ID (Oauth Web)                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Adobeクライアントのシークレット                               | Adobe Client Secret                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Ageシークレットキー                                    | Ageシークレットキー                                | {{< yes >}} | {{< no >}} | {{< no >}} |
| Aivenサービスパスワード                            | AivenServicePassword                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| AlibabaアクセスキーID                              | AlibabaアクセスキーID                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| Alibabaシークレットキー                                | Alibabaシークレットキー                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Amazon OAuthクライアントID                            | AmazonOAuthClientID                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Anthropic APIキー                                 | anthropic_key                                 | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Artifactory APIキー                               | ArtifactoryApiKey                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Artifactory IDトークン                        | ArtifactoryIdentityToken                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| AsanaクライアントID                                   | Asana Client ID                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| Asanaクライアントのシークレット                               | Asana Client Secret                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| AsanaパーソナルアクセストークンV1                   | AsanaPersonalAccessTokenV1                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| AsanaパーソナルアクセストークンV2                   | AsanaPersonalAccessTokenV2                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Atlassian APIキー                                 | AtlassianApiKey                               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Atlassian APIトークン                               | Atlassian APIトークン                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Atlassian User APIトークン                          | AtlassianUserApiToken                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Auth0クライアントのシークレット                               | Auth0ClientSecret                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| AWSアクセスキーID                                 | AWS                                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| AWSアクセスシークレットキー                             | AWSSecretAccessKey                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| AWSセッショントークン                                 | AWSSessionToken                               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| AWS Cognito IdentityプールID                      | AWSCognitoIdentityPoolID                      | {{< yes >}} | {{< no >}} | {{< no >}} |
| AWS Bedrockキー                                   | AWSBedrockKey                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| AWS Bedrock Short-lived Key                       | AWSBedrockShortLivedKey                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure API管理ゲートウェイキー                  | AzureAPIManagementGatewayKey                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure API管理ダイレクトキー                   | AzureAPIManagementDirectKey                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Azure App設定                                  | AzureAppConfigConnectionString                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azureコミュニケーションサービス                      | AzureCommServicesConnectionString                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure Cosmos DB認証情報                       | AzureCosmosDBCredentials                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Azure Entraクライアントシークレット                         | AzureEntraClientSecret                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure Entra Client IDトークン                       | AzureEntraIDToken                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure EventGridアクセスキー                        | AzureEventGridAccessKey                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Azure Functions APIキー                           | AzureFunctionsAPIKey                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure Logic App SAS                               | AzureLogicAppSAS                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure OpenAI APIキー                              | AzureOpenAIAPIKey                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Azureパーソナルアクセストークン                       | AzurePersonalAccessToken                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Azure SignalRアクセスキー                          | AzureSignalRAccessKey                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Beamer APIトークン                                  | Beamer APIトークン                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| BitbucketクライアントID                               | BitbucketクライアントID                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Bitbucketクライアントのシークレット                           | Bitbucketクライアントのシークレット                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Brevo APIトークン                                   | Sendinblue API token                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Brevo SMTPトークン                                  | Sendinblue SMTP token                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Canada Digital Service Notify APIキー             | CDSCanadaNotifyAPIKey                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| CircleCIアクセストークン                             | CircleCI access tokens                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| CircleCIパーソナルアクセストークン                    | CircleCIPersonalAccessToken                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clojarsデプロイトークン                              | Clojars API token                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| Contentful delivery APIトークン                     | Contentful delivery APIトークン                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| Contentfulパーソナルアクセストークン                  | ContentfulPersonalAccessToken                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| ContentfulプレビューAPIトークン                      | ContentfulプレビューAPIトークン                  | {{< yes >}} | {{< no >}} | {{< no >}} |
| Databricks APIトークン                              | Databricks APIトークン                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| DataDog APIキー                                   | DataDogAPIKey                                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| DigitalOcean OAuthアクセストークン                   | digitalocean-access-token                     | {{< yes >}} | {{< no >}} | {{< no >}} |
| DigitalOceanパーソナルアクセストークン                | digitalocean-pat                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| DigitalOcean更新トークン                        | digitalocean-refresh-token                    | {{< yes >}} | {{< no >}} | {{< no >}} |
| Discord APIキー                                   | Discord APIキー                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| DiscordクライアントID                                 | DiscordクライアントID                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| Discordクライアントのシークレット                             | Discordクライアントのシークレット                         | {{< yes >}} | {{< no >}} | {{< no >}} |
| Dockerパーソナルアクセストークン                      | DockerPersonalAccessToken                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Doppler APIトークン                                 | Doppler APIトークン                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Doppler Serviceトークン                             | Doppler Serviceトークン                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Dropbox APIシークレット/キー                            | Dropbox APIシークレット/キー                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Dropbox Appアクセストークン                          | DropboxAppAccessToken                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Dropbox long lived APIトークン                      | Dropbox long lived APIトークン                  | {{< yes >}} | {{< no >}} | {{< no >}} |
| Dropbox short lived APIトークン                     | Dropbox short lived APIトークン                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Duffel APIトークン                                  | Duffel APIトークン                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Dynatrace Platformトークン                          | DynatracePlatformToken                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| EasyPost本番環境APIキー                       | EasyPost API token                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| EasyPost test APIキー                             | EasyPost test API token                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Facebookトークン                                    | Facebookトークン                                | {{< yes >}} | {{< no >}} | {{< no >}} |
| Fastly APIユーザーまたは認証トークン               | Fastly API token                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Figmaパーソナルアクセストークン                       | FigmaPersonalAccessToken                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Finicity APIトークン                                | Finicity APIトークン                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Finicityクライアントのシークレット                            | Finicityクライアントのシークレット                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Flutterwave Prod Encrypted Key                    | FlutterwaveProdEncryptedKey                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Flutterwave test暗号化されたキー                    | Flutterwave encrypted key                     | {{< yes >}} | {{< no >}} | {{< no >}} |
| Flutterwave Prod Public Key                       | FlutterwaveProdPublicKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Flutterwave test公開キー                       | Flutterwave public key                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Flutterwave Prodシークレットキー                       | FlutterwaveProdSecretKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Flutterwave testシークレットキー                       | Flutterwave secret key                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Frame.io APIトークン                                | Frame.io APIトークン                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| GCP APIキー                                       | GCP APIキー                                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| GCP OAuthクライアントのシークレット                           | GCP OAuthクライアントのシークレット                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GCP Vertex Express Mode Key                       | GCPVertexExpressModeKey                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHub appトークン                                  | Github App Token                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHub App Installationトークン                     | GithubAppInstallationToken                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHub Fine Grainedパーソナルアクセストークン         | GithubFineGrainedPersonalAccessToken          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHub OAuthアクセストークン                         | Github OAuth Access Token                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHubパーソナルアクセストークン (クラシック)            | Github Personal Access Token                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHub更新トークン                              | Github Refresh Token                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitLab CI/CDジョブトークン                            | gitlab_ci_build_token                         | {{< yes >}} | {{< yes >}} | {{< no >}} |
| GitLabデプロイトークン                               | gitlab_deploy_token                           | {{< yes >}} | {{< yes >}} | {{< no >}} |
| GitLab機能フラグクライアントトークン                 | なし                                          | {{< no >}} | {{< yes >}} | {{< no >}} |
| GitLabフィードトークン                                 | gitlab_feed_token                             | {{< yes >}} | {{< yes >}} | {{< no >}} |
| GitLabフィードトークンv2                              | gitlab_feed_token_v2                          | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab受信メールトークン                       | gitlab_incoming_email_token                   | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab Kubernetesエージェントトークン                     | gitlab_kubernetes_agent_token                 | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab OAuthアプリケーションのシークレット                   | gitlab_oauth_app_secret                       | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLabパーソナルアクセストークン                      | gitlab_personal_access_token                  | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLabパーソナルアクセストークン (ルート可能)           | gitlab_personal_access_token_routable         | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLabパイプライントリガートークン                     | gitlab_pipeline_trigger_token                 | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab Runner認証トークン                | gitlab_runner_auth_token                      | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab Runner登録トークン                  | gitlab_runner_registration_token              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitLab SCIM OAuthトークン                           | gitlab_scim_oauth_token                       | {{< yes >}} | {{< yes >}} | {{< no >}} |
| GoCardless APIトークン                              | GoCardless APIトークン                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| Google APIキー                                    | GCP APIキー                                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Google (GCP) サービスアカウント                      | Google (GCP) Service-account                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Grafana Service Accountトークン                     | GrafanaServiceAccountToken                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Grafana Cloud Access Policyトークン                 | GrafanaCloudAccessPolicyToken                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| HashiCorp Terraform APIトークン                     | Hashicorp Terraform user/org API token        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| HashiCorp Vault batchトークン                       | Hashicorp Vault batch token                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| HashiCorp Vault Serviceトークン                     | HashicorpVaultServiceToken                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Heroku APIキーまたはアプリケーション認可トークン | Heroku API Key                                | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Highnote Liveシークレットキー                          | HighnoteLiveSecretKey                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Highnote Testシークレットキー                          | HighnoteTestSecretKey                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| HubSpot private app APIトークン                     | Hubspot API token                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Hugging Face Userアクセストークン                    | HuggingFaceUserAccessToken                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Instagramアクセストークン                            | Instagramアクセストークン                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Intercom APIトークン                                | Intercom APIトークン                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Intercom Appアクセストークン                         | IntercomAppAccessToken                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| IntercomクライアントのシークレットまたはクライアントID               | Intercom client secret/ID                     | {{< yes >}} | {{< no >}} | {{< no >}} |
| Ionicパーソナルアクセストークン                       | Ionic API token                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| Kubernetes Service Accountトークン                  | KubernetesServiceAccToken                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| LangChain APIキー                                 | LangChainAPIKey                               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Linear APIトークン                                  | Linear APIトークン                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| LinearクライアントのシークレットまたはID (OAuth 2.0)            | Linear client secret/ID                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| LinkedInクライアントID                                | Linkedin Client ID                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| LinkedInクライアントのシークレット                            | Linkedin Client secret                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Lob APIキー                                       | Lob API Key                                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Lob公開APIキー                           | Lob Publishable API Key                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Mailchimp APIキー                                 | Mailchimp APIキー                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| MailgunプライベートAPIトークン                         | MailgunプライベートAPIトークン                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Mailgunパブリック検証キー                   | Mailgun public validation key                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| Mailgun Webhook署名キー                       | Mailgun Webhook署名キー                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Mapbox APIトークン                                  | Mapbox APIトークン                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Mapbox Secret APIトークン                           | MapboxSecretApiToken                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| MaxMindライセンスキー                               | MaxMindライセンスキー                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| MessageBirdアクセスキー                            | messagebird-api-token                         | {{< yes >}} | {{< no >}} | {{< no >}} |
| MessageBird APIクライアントID                         | MessageBird APIクライアントID                     | {{< yes >}} | {{< no >}} | {{< no >}} |
| Metaアクセストークン                                 | Metaアクセストークン                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| New RelicインジェストブラウザAPIトークン                | New RelicインジェストブラウザAPIトークン            | {{< yes >}} | {{< no >}} | {{< no >}} |
| New RelicインジェストブラウザAPIトークンv2             | New RelicインジェストブラウザAPIトークンv2         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| New Relic REST APIキー                            | New Relic REST APIキー                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| New RelicユーザーAPI ID                             | New RelicユーザーAPI ID                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| New RelicユーザーAPIキー                            | New Relic user API Key                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| NPMアクセストークン                                  | NPMアクセストークン                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Oculusアクセストークン                               | Oculusアクセストークン                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Okta APIトークン                                    | OktaAPIToken                                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Oktaクライアントのシークレット                                | OktaClientSecret                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Onfido Live APIトークン                             | Onfido Live APIトークン                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| OpenAI APIキー                                    | open ai token                                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| OpenAI Projectキー                                | OpenAiProjectKey                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| OpenAI Service Accountキー                        | OpenAiServiceAccountKey                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| URL内のパスワード                                   | URL内のパスワード                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| PGPプライベートキー                                   | PGPプライベートキー                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| PKCS8プライベートキー                                 | PKCS8プライベートキー                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| PlanetScale APIトークン                             | Planetscale API token                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| PlanetScale App Secret                            | PlanetscaleAppSecret                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| PlanetScale OAuth Secret                          | PlanetscaleOAuthSecret                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| PlanetScaleパスワード                              | Planetscale password                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| PostHog Personal APIキー                          | PostHogPersonalAPIkey                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| PostHog Project APIキー                           | PostHogProjectAPIkey                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Postman APIトークン                                 | Postman APIトークン                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| Postman Collectionアクセスキー                     | PostmanCollectionAccessKey                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Pulumi APIトークン                                  | Pulumi APIトークン                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| PyPiアップロードトークン                                 | PyPI upload token                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| RSAプライベートキー                                   | RSAプライベートキー                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| RubyGems APIトークン                                | Rubygem API token                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| SegmentパブリックAPIトークン                          | Segment Public API token                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| SendGrid APIトークン                                | Sendgrid API token                            | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Shippo APIトークン                                  | Shippo APIトークン                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| ShippoテストAPIトークン                             | ShippoテストAPIトークン                         | {{< yes >}} | {{< no >}} | {{< no >}} |
| Shopify Partner APIトークン                         | ShopifyPartnerAPIToken                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Shopifyパーソナルアクセストークン                     | Shopify access token                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Shopifyプライベートアプリアクセストークン                  | Shopifyプライベートアプリアクセストークン              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Shopify Custom Appアクセストークン                   | Shopify custom app access token               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Shopify共有シークレット                             | Shopify共有シークレット                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Slack App設定トークン                     | SlackAppConfigurationToken                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Slack App設定更新トークン             | SlackAppConfigurationRefreshToken             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Slackアプリレベルトークン                             | SlackAppLevelToken                            | {{< yes >}} | {{< no >}} | {{< yes >}} |
| SlackボットユーザーOAuthトークン                        | Slack token                                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Slack Webhook                                     | Slack Webhook                                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| SonarQubeグローバル分析トークン                   | SonarQubeGlobalAnalysisToken                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| SonarQubeプロジェクト分析トークン                  | SonarQubeProjectAnalysisToken                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| SonarQubeユーザートークン                              | SonarQubeUserToken                            | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Splunk認証トークン                       | SplunkAuthToken                               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Splunk HTTPイベントコレクター (HEC) トークン            | SplunkHECToken                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| SSH (DSA) プライベートキー                             | SSH (DSA) プライベートキー                         | {{< yes >}} | {{< no >}} | {{< no >}} |
| SSH (EC) プライベートキー                              | SSH (EC) プライベートキー                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| SSHプライベートキー                                   | SSHプライベートキー                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| Stripe live制限付きキー                        | StripeLiveRestrictedKey                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Stripe liveシークレットキー                            | StripeLiveSecretKey                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Stripe Live Shortシークレットキー                      | StripeLiveShortSecretKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Stripe公開可能ライブキー                       | StripeLivePublishableKey                      | {{< yes >}} | {{< no >}} | {{< no >}} |
| Stripe公開可能テストキー                       | StripeTestPublishableKey                      | {{< yes >}} | {{< no >}} | {{< no >}} |
| Stripe制限付きテストキー                        | StripeTestRestrictedKey                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Stripeシークレットテストキー                            | StripeTestSecretKey                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Stripe Test Shortシークレットキー                      | StripeTestShortSecretKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Tailscale OAuthクライアントのシークレット                     | TailscaleOauthClientSecret                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Tailscale APIアクセストークン                        | TailscaleApiAccessToken                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Tailscale Personal認証キー                       | TailscalePersonalAuthKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Tencent Cloud Secret ID                           | TencentCloudSecretID                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Twilio Account SID                                | Twilio Account SID                            | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Twilio APIキー                                    | Twilio API Key                                | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Twitch OAuthクライアントのシークレット                        | Twitch API token                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Typeformパーソナルアクセストークン                    | Typeform API token                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| VolcengineアクセスキーID                          | VolcengineAccessKeyID                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| WakaTime APIキー                                  | WakaTimeAPIKey                                | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Xトークン                                           | Twitter token                                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| Yandex.Cloud AWS API互換性のあるアクセスシークレット     | Yandex.Cloud AWS API compatible Access Secret | {{< yes >}} | {{< no >}} | {{< no >}} |
| Yandex.Cloud APIキー                              | Yandex.Cloud APIキー                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| Yandex.Cloud IAM cookie v1-1                      | Yandex.Cloud IAM Cookie v1 - 1                | {{< yes >}} | {{< no >}} | {{< no >}} |
| Yandex.Cloud IAM cookie v1-3                      | Yandex.Cloud IAM Cookie v1 - 3                | {{< yes >}} | {{< no >}} | {{< no >}} |

<!-- vale gitlab_base.SentenceSpacing = YES -->
<!-- vale gitlab_base.Spelling = YES -->
<!-- markdownlint-enable MD044 -->
