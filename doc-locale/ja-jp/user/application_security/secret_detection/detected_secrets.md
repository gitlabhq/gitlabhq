---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 検出されたシークレット
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

この表は、検出されたシークレットをリストしたものです:

- パイプラインシークレット検出
- クライアントサイドシークレット検出
- シークレットプッシュ保護

シークレット検出ルールは、[デフォルトのルールセット](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/tree/main)で更新されます。削除または更新されたパターンを持つ検出されたシークレットは、トリアージできるように、開いたままになります。

<!-- markdownlint-disable MD034 -->
<!-- markdownlint-disable MD044 -->
<!-- vale gitlab_base.SentenceSpacing = NO -->

| 説明                                   | ID                                            | パイプラインシークレット検出 | クライアントサイドシークレット検出 | シークレットプッシュ保護 |
|:----------------------------------------------|:----------------------------------------------|:--------------------------|:-----------------------------|:-----------------------|
| Adafruit IOキー                               | AdafruitIOKey                                 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Adobe Client ID (OAuth Web)                       | Adobe Client ID (OAuth Web)                   | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Adobeクライアントのシークレットキー                               | Adobe Client Secret                           | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Ageシークレットキー                                    | Ageシークレットキー                                | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Aiven Service Password                            | AivenServicePassword                          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Alibaba AccessKey ID                              | Alibaba AccessKey ID                          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Alibaba Secretキー                                | Alibaba Secretキー                            | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Amazon OAuth Client ID                            | AmazonOAuthClientID                           | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Anthropic APIキー                                 | anthropic_key                                 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 |
| Artifactory APIキー                               | ArtifactoryApiKey                             | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Artifactory Identityトークン                        | ArtifactoryIdentityToken                      | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| AsanaクライアントID                                   | Asana Client ID                               | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Asanaクライアントのシークレットキー                               | Asana Client Secret                           | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| AsanaパーソナルアクセストークンV1                   | AsanaPersonalAccessTokenV1                    | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| AsanaパーソナルアクセストークンV2                   | AsanaPersonalAccessTokenV2                    | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Atlassian APIキー                                 | AtlassianApiKey                               | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Atlassian APIトークン                               | Atlassian APIトークン                           | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Atlassian User APIトークン                          | AtlassianUserApiToken                         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Auth0 Client Secret                               | Auth0ClientSecret                             | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| AWSアクセストークン                                  | AWS                                           | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| AWS Bedrockキー                                   | AWSBedrockKey                       | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| AWSセキュリティトークンサービス                        | AWSSTSKey                                     | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Azure API Management Gatewayキー                  | AzureAPIManagementGatewayKey                  | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Azure API Management Directキー                   | AzureAPIManagementDirectKey                   | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Azure App Config                                  | AzureAppConfigConnectionString                        | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Azure Communication Services                      | AzureCommServicesConnectionString                     | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Azure Cosmos DB認証情報                       | AzureCosmosDBCredentials                   | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Azure Entraクライアントのシークレットキー                         | AzureEntraClientSecret                        | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Azure Entra Client IDトークン                       | AzureEntraIDToken                          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Azure EventGridアクセスキー                        | AzureEventGridAccessKey                       | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Azure Functions APIキー                           | AzureFunctionsAPIKey                          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Azure Logic App SAS                               | AzureLogicAppSAS                          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Azure OpenAI APIキー                              | AzureOpenAIAPIKey                       | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Azureパーソナルアクセストークン                       | AzurePersonalAccessToken                   | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Azure SignalRアクセスキー                          | AzureSignalRAccessKey                          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Beamer APIトークン                                  | Beamer APIトークン                              | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| BitbucketクライアントID                               | BitbucketクライアントID                           | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Bitbucketクライアントのシークレットキー                           | Bitbucketクライアントのシークレットキー                       | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Brevo APIトークン                                   | Sendinblue APIトークン                          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Brevo SMTPトークン                                  | Sendinblue SMTPトークン                         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Canada Digital Service Notify APIキー             | CDSCanadaNotifyAPIKey                         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| CircleCIアクセストークン                             | CircleCIアクセストークン                        | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| CircleCIパーソナルアクセストークン                    | CircleCIPersonalAccessToken                   | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Clojarsデプロイトークン                              | Clojars APIトークン                             | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| ContentfulデリバリーAPIトークン                     | ContentfulデリバリーAPIトークン                 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Contentfulパーソナルアクセストークン                  | ContentfulPersonalAccessToken                 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| ContentfulプレビューAPIトークン                      | ContentfulプレビューAPIトークン                  | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Databricks APIトークン                              | Databricks APIトークン                          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| DataDog APIキー                                   | DataDogAPIKey                                 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| DigitalOcean OAuthアクセストークン                   | digitalocean-access-token                     | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| DigitalOceanパーソナルアクセストークン                | digitalocean-pat                              | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| DigitalOcean更新トークン                        | digitalocean-更新-トークン                    | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Discord APIキー                                   | Discord APIキー                               | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| DiscordクライアントID                                 | DiscordクライアントID                             | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Discordクライアントのシークレットキー                             | Discordクライアントのシークレットキー                         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Dockerパーソナルアクセストークン                      | DockerPersonalAccessToken                     | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Doppler APIトークン                                 | Doppler APIトークン                             | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Doppler Serviceトークン                             | Doppler Serviceトークン                         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Dropbox APIシークレット/キー                            | Dropbox APIシークレット/キー                        | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Dropbox long lived APIトークン                      | Dropbox long lived APIトークン                  | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Dropbox short lived APIトークン                     | Dropbox short lived APIトークン                 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Duffel APIトークン                                  | Duffel APIトークン                              | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Dynatrace Platformトークン                          | DynatracePlatformToken                        | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| EasyPost本番環境APIキー                       | EasyPost APIトークン                            | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| EasyPost test APIキー                             | EasyPost test APIトークン                       | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Facebookトークン                                    | Facebookトークン                                | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Fastly API user or automationトークン               | Fastly APIトークン                              | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Figmaパーソナルアクセストークン                       | FigmaPersonalAccessToken                      | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Finicity APIトークン                                | Finicity APIトークン                            | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Finicityクライアントのシークレットキー                            | Finicityクライアントのシークレットキー                        | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Flutterwave test暗号化されたキー                    | Flutterwave暗号化されたキー                     | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Flutterwave test publicキー                       | Flutterwave publicキー                        | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Flutterwave testシークレットキー                       | Flutterwaveシークレットキー                        | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Frame.io APIトークン                                | Frame.io APIトークン                            | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| GCP APIキー                                       | GCP APIキー                                   | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| GCP OAuthクライアントのシークレットキー                           | GCP OAuthクライアントのシークレットキー                       | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| GCP Vertex Express Modeキー                       | GCPVertexExpressModeKey                       | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| GitHub appトークン                                  | Github App Token                              | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| GitHub App Installationトークン                     | GithubAppInstallationToken                    | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| GitHub Fine Grainedパーソナルアクセストークン         | GithubFineGrainedPersonalAccessToken          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| GitHub OAuthアクセストークン                         | Github OAuthアクセストークン                     | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| GitHubのパーソナルアクセストークンを使用する            | GitHubパーソナルアクセストークンを使用する                  | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| GitHub更新トークン                              | Github更新トークン                          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| GitLab CI/CDジョブトークン                            | gitlab_ci_build_token                         | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 |
| GitLabデプロイトークン                               | GitLabデプロイトークン                           | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 |
| 機能フラグクライアントトークン                 | なし                                          | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 |
| GitLabフィードトークン                                 | gitlab_feed_token                             | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 |
| GitLabフィードトークンv2                              | gitlab_feed_token_v2                          | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 |
| GitLab受信メールトークン                       | gitlab_incoming_email_token                   | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 |
| GitLab Kubernetesエージェントトークン                     | gitlab_kubernetes_エージェント_token                 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 |
| OAuthアプリケーションのシークレット                   | gitlab_oauth_app_シークレット                       | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 |
| GitLabパーソナルアクセストークン                      | GitLabパーソナルアクセストークン                  | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 |
| GitLabパーソナルアクセストークン (ルーティング可能)           | gitlab_personal_access_token_routable         | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 |
| パイプライントリガートークンの変更後                     | gitlab_パイプライントリガートークンの変更後                 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 |
| Runner認証トークン                | gitlab_runner_auth_token                      | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 |
| Runner登録トークンを許可                  | gitlab_Runner登録トークンを許可              | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| GitLab SCIM OAuthトークン                           | gitlab_scim_OAuth_トークン                       | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 |
| GoCardless APIトークン                              | GoCardless APIトークン                          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Google APIキー                                    | GCP APIキー                                   | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Google (GCP) サービスアカウント                      | Google (GCP) Service-アカウント                  | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Grafana APIトークン                                 | Grafana APIトークン                             | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| HashiCorp Terraform APIトークン                     | Hashicorp Terraform user/org APIトークン        | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| HashiCorp Vault batchトークン                       | Hashicorp Vault batchトークン                   | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| HashiCorp Vault Serviceトークン                     | HashicorpVaultServiceToken                     | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Heroku APIキーor認可トークン | Heroku APIキー                                | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Highnote Live Secretキー                          | HighnoteLiveSecretKey                         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Highnote Test Secretキー                          | HighnoteTestSecretKey                         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| HubSpot private app APIトークン                     | Hubspot APIトークン                             | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Hugging Face Userアクセストークン                    | HuggingFaceUserAccessToken                    | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Instagramアクセストークン                            | Instagramアクセストークン                        | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Intercom APIトークン                                | Intercom APIトークン                            | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| IntercomクライアントのシークレットキーorクライアントID               | Intercomクライアントのシークレットキー/ID                     | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Ionicパーソナルアクセストークン                       | Ionic APIトークン                               | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Kubernetesサービスアカウントトークン                  | KubernetesServiceAccToken                     | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| LangChain APIキー                                 | LangChainAPIKey                               | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Linear APIトークン                                  | Linear APIトークン                              | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Linearクライアントのシークレットキーor ID (OAuth 2.0)            | Linearクライアントのシークレットキー/ID                       | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| LinkedInクライアントID                                | LinkedInクライアントID                            | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| LinkedInクライアントシークレット                            | LinkedInクライアントシークレット                        | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Lob APIキー                                       | Lob APIキー                                   | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Lob公開APIキー                           | Lob公開APIキー                       | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Mailchimp APIキー                                 | Mailchimp APIキー                             | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| MailgunプライベートAPIトークン                         | MailgunプライベートAPIトークン                     | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Mailgunパブリック検証キー                   | Mailgunパブリック検証キー                 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Mailgun Webhook署名キー                       | Mailgun Webhook署名キー                   | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Mapbox APIトークン                                  | Mapbox APIトークン                              | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| MaxMindライセンスキー                               | MaxMindライセンスキー                           | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| MessageBirdアクセストークン                            | messagebird-api-トークン                         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| MessageBird APIクライアントID                         | MessageBird APIクライアントID                     | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Metaアクセストークン                                 | Metaアクセストークン                             | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| New RelicインジェストブラウザーAPIトークン                | New RelicインジェストブラウザーAPIトークン            | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| New RelicインジェストブラウザーAPIトークンv2             | New RelicインジェストブラウザーAPIトークンv2         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| New Relic REST APIキー                            | New Relic REST APIキー                        | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| New RelicユーザーAPI ID                             | New RelicユーザーAPI ID                         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| New RelicユーザーAPIキー                            | New RelicユーザーAPIキー                        | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| npmアクセストークン                                  | npmアクセストークン                              | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Oculusアクセストークン                               | Oculusアクセストークン                           | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Okta APIトークン                                    | OktaAPIトークン                                  | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Oktaクライアントシークレット                                | Oktaクライアントシークレット                              | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Onfido Live APIトークン                             | Onfido Live APIトークン                         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| OpenAI APIキー                                    | Open AIトークン                                 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| URLのパスワード                                   | URLのパスワード                               | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| PGP private key                                   | PGP private key                               | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| PKCS8 private key                                 | PKCS8 private key                             | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| PlanetScale APIトークン                             | Planetscale APIトークン                         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| PlanetScaleアプリシークレット                            | Planetscaleアプリシークレット                          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| PlanetScale OAuthシークレット                          | Planetscale OAuthシークレット                        | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| PlanetScaleパスワード                              | Planetscaleパスワード                          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| PostHogパーソナルAPIキー                          | PostHogパーソナルAPIキー                         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| PostHogプロジェクトAPIキー                           | PostHogプロジェクトAPIキー                          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Postman APIトークン                                 | Postman APIトークン                             | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Pulumi APIトークン                                  | Pulumi APIトークン                              | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| PyPiアップロードトークン                                 | PyPiアップロードトークン                             | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| RSA private key                                   | RSA private key                               | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| RubyGems APIトークン                                | Rubygem APIトークン                             | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| セグメントパブリックAPIトークン                          | セグメントパブリックAPIトークン                      | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| SendGrid APIトークン                                | Sendgrid APIトークン                            | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Shippo APIトークン                                  | Shippo APIトークン                              | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| ShippoテストAPIトークン                             | ShippoテストAPIトークン                         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Shopifyカスタムアプリアクセストークン                   | Shopifyカスタムアプリアクセストークン               | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Shopifyパーソナルアクセストークン                     | Shopifyアクセストークン                          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Shopifyプライベートアプリアクセストークン                  | Shopifyプライベートアプリアクセストークン              | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Shopify共有シークレット                             | Shopify共有シークレット                         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Slackアプリレベルトークン                             | Slackアプリレベルトークン                            | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| SlackボットユーザーOAuthトークン                        | Slackトークン                                   | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Slack Webhook                                     | Slack Webhook                                 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| SonarQubeグローバル分析トークン                   | SonarQubeグローバル分析トークン                  | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| SonarQubeプロジェクト分析トークン                  | SonarQubeプロジェクト分析トークン                 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| SonarQubeユーザートークン                              | SonarQubeユーザートークン                            | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Splunk Authenticationトークン                       | Splunk認証トークン                               | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Splunk HTTPイベントコレクター（HEC）トークン            | SplunkHECトークン                               | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| SSH（DSA）private key                             | SSH（DSA）private key                         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| SSH（EC）private key                              | SSH（EC）private key                          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| SSH private key                                   | SSH private key                               | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Stripeライブ制限キー                        | Stripeライブ制限キー                       | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Stripeライブシークレットキー                            | Stripeライブシークレットキー                           | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Stripeライブショートシークレットキー                      | Stripeライブショートシークレットキー                      | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Stripe公開ライブキー                       | Stripe公開ライブキー                      | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Stripe公開テストキー                       | Stripe公開テストキー                      | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Stripe制限付きテストキー                        | Stripe制限付きテストキー                       | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Stripeシークレットテストキー                            | Stripeシークレットテストキー                           | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Stripeテストショートシークレットキー                      | Stripeテストショートシークレットキー                      | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Tailscaleキー                                     | Tailscaleキー                                 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Tencent CloudシークレットID                           | TencentCloudシークレットID                          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| TwilioアカウントID                                | TwilioアカウントID                            | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Twilio APIキー                                    | Twilio APIキー                                | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Twitch OAuthクライアントシークレット                        | Twitch APIトークン                              | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Typeformパーソナルアクセストークン                    | Typeform APIトークン                            | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| VolcengineアクセスキーID                          | VolcengineアクセスキーID                         | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| WakaTime APIキー                                  | WakaTimeAPIキー                                | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}非対応 | {{< icon name="check-circle" >}}対応 |
| Xトークン                                           | Twitterトークン                                 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Yandex.Cloud AWS API互換アクセスシークレット     | Yandex.Cloud AWS API互換アクセスシークレット | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Yandex.Cloud APIキー                              | Yandex.Cloud APIキー                          | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Yandex.Cloud IAM cookie v1-1                      | Yandex.Cloud IAM Cookie v1 - 1                | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |
| Yandex.Cloud IAM cookie v1-3                      | Yandex.Cloud IAM Cookie v1 - 3                | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}対象外 | {{< icon name="dotted-circle" >}}対象外 |

<!-- vale gitlab_base.SentenceSpacing = YES -->
<!-- markdownlint-enable MD034 -->
<!-- markdownlint-enable MD044 -->
