---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 검출된 시크릿
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## 시크릿 분류 {#secret-categories}

GitLab 시크릿 검색은 두 가지 방식으로 시크릿을 식별합니다: 규칙 기반 검색과 일반 검색입니다.

### 규칙 기반 검색 {#rule-based-detection}

규칙 기반 검색은 스캔한 콘텐츠를 규칙이라고 불리는 각 인증 유형의 알려진 패턴과 비교하여 시크릿을 식별합니다. 예를 들어 GitLab 개인 액세스 토큰은 패턴 `glpat-` 다음에 20자 문자열이 오는 것으로 식별됩니다. GitLab은 기본적으로 인기 있는 공급업체를 포함하는 [200개 이상의 규칙](#supported-rules-for-rule-based-detection)을 지원합니다.

규칙 기반 검색의 범위는 분석기가 지원하는 규칙으로 제한됩니다. 지원되는 규칙과 일치하지 않는 시크릿은 검출되지 않습니다. Gitleaks 기반 분석기와 [GitLab Secret Scanning for Source Code](gitlab_secret_scanner/_index.md) 모두 규칙 기반 검색을 지원합니다.

### 일반 검색 {#generic-detection}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  베타

{{< /details >}}

규칙 기반 검색은 이미 알고 있는 패턴과 일치하는 시크릿만 찾을 수 있습니다. 많은 인증 정보가 게시되거나 일관된 형식을 따르지 않아 규칙이 일치하지 않을 수 있습니다. 예를 들어 내부 서비스의 비밀번호, 데이터베이스 연결 문자열 또는 특별한 접두사가 없는 API 키가 있습니다. 일반 검색은 이러한 시크릿을 대상으로 합니다. 일반 검색은 고정 패턴을 일치하는 대신 값 주위의 컨텍스트와 값 자체의 속성을 검토합니다. 두 신호 모두 값이 인증 정보일 가능성이 있는지 여부를 결정합니다.

일반 검색은 알려진 패턴에 의존하지 않기 때문에 규칙 기반 검색에서 놓치는 시크릿을 포착할 수 있습니다. 또한 거짓 양성이 더 많이 발생하므로 GitLab Secret Scanning for Source Code에는 노이즈를 줄이기 위한 거짓 양성 감소 기능이 포함되어 있습니다.

GitLab Secret Scanning for Source Code는 일반 검색을 지원하는 유일한 GitLab 분석기입니다. 자세한 정보는 [일반 시크릿](gitlab_secret_scanner/_index.md#generic-secrets)을 참조하세요.

일반 검색은 명백한 `secret = "value"` 할당에 제한되지 않습니다. 다음 코드 조각은 식별하는 덜 명백한 값과 각각 생성하는 검출을 보여줍니다:

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

#### 일반 시크릿 검출 {#generic-secret-findings}

일반 시크릿이 검출되면 GitLab은 검출된 값의 유형에 따라 취약성 보고서에서 검출을 레이블합니다:

- `Generic Password`: 데이터베이스 비밀번호 또는 서비스 비밀번호와 같은 사람이 정의한 비밀번호입니다.
- `Generic Secret`: 알려진 공급업체 형식과 일치하지 않는 API 키 또는 액세스 토큰과 같은 기계 생성 인증 정보입니다.
- `Generic UUID Secret`, `Generic Base64-Encoded Secret`, `Generic Base64URL-Encoded Secret`, `Generic Hex-Encoded Secret`, `Generic JWT Token` 및 `Generic Paseto Token`: GitLab이 형식별로 추가로 분류한 기계 생성 인증 정보입니다.

각 검출에는 값이 플래그된 이유를 설명하는 설명이 포함됩니다. 설명은 값이 실제 시크릿인지 확인하는 방법, 확인된 시크릿을 순환하는 방법 또는 거짓 양성을 무시하는 방법에 대한 지침을 제공합니다.

#### 일반 검색에서 놓칠 수 있는 시크릿 {#secrets-generic-detection-might-miss}

일반 검색은 값이 무엇을 하는지 확인하는 것이 아니라 키워드나 값의 형식과 같은 주변 정보에서 시크릿을 식별합니다. 이 접근 방식에는 절충점이 있습니다. 거짓 양성 감소가 적용되더라도 일부 비시크릿 값이 검출로 표시될 수 있습니다. 예를 들어:

- `full_key = prefix + secret_suffix` 같은 연결이나 문자열 보간을 통해 빌드된 시크릿입니다.
- `key`, `secret`, `token` 또는 `password` 같은 레이블이 없는 하드코딩된 값처럼 근처에 인식 가능한 키워드가 없는 시크릿입니다.
- 일반 검색에서 제외하는 파일이나 경로의 시크릿 (예: 번들로 제공되는 종속성, 생성된 파일 또는 문서)입니다.
- 일반 검색이 해당 유형의 시크릿에 대해 예상하는 최소 길이보다 짧은 값입니다.
- 중간 또는 낮은 신뢰도로 보고된 시크릿입니다. GitLab Secret Scanning for Source Code는 취약성 보고서에만 높은 신뢰도 검출을 표시합니다.

## 규칙 기반 검색에 지원되는 규칙 {#supported-rules-for-rule-based-detection}

이 표는 규칙 기반 검색에 사용되는 규칙을 나열하고 각 규칙이 다음을 지원하는지 여부를 보여줍니다:

- 파이프라인 시크릿 탐지
- 클라이언트측 시크릿 검색
- 시크릿 푸시 보호

시크릿 검색 규칙은 [기본 규칙 집합](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/tree/main)에서 업데이트됩니다. 제거되거나 업데이트된 패턴이 있는 검출된 시크릿은 개발자가 분류할 수 있도록 열려 있습니다.

새로운 시크릿 검색 규칙을 추가하려면 모든 GitLab 사용자에 대해 [새로운 검출 규칙을 제안](pipeline/configure.md#propose-new-detection-rules)하거나 특정 프로젝트에 대해 [규칙 집합을 사용자 지정](pipeline/configure.md#customize-analyzer-rulesets)할 수 있습니다.

<!-- markdownlint-disable MD044 -->
<!-- vale gitlab_base.Spelling = NO -->
<!-- vale gitlab_base.SentenceSpacing = NO -->

| 설명                                   | ID                                            | 파이프라인 시크릿 탐지 | 클라이언트측 시크릿 검색 | 시크릿 푸시 보호 |
|:----------------------------------------------|:----------------------------------------------|:--------------------------|:-----------------------------|:-----------------------|
| Adafruit IO 키                               | AdafruitIOKey                                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Adobe 클라이언트 ID (OAuth 웹)                       | Adobe Client ID (Oauth Web)                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Adobe 클라이언트 시크릿                               | Adobe Client Secret                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Adobe IMS 액세스 토큰                            | AdobeIMSAccessToken                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Age 시크릿 키                                    | Age 시크릿 키                                | {{< yes >}} | {{< no >}} | {{< no >}} |
| Aiven 서비스 비밀번호                            | AivenServicePassword                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Alibaba AccessKey ID                              | Alibaba AccessKey ID                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| Alibaba 시크릿 키                                | Alibaba 시크릿 키                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Amazon OAuth 클라이언트 ID                            | AmazonOAuthClientID                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Anthropic API 키                                 | anthropic_key                                 | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Artifactory API 키                               | ArtifactoryApiKey                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Artifactory Identity 토큰                        | ArtifactoryIdentityToken                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Asana 클라이언트 ID                                   | Asana Client ID                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| Asana 클라이언트 시크릿                               | Asana Client Secret                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Asana 개인 액세스 토큰 V1                   | AsanaPersonalAccessTokenV1                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Asana 개인 액세스 토큰 V2                   | AsanaPersonalAccessTokenV2                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Atlassian API 키                                 | AtlassianApiKey                               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Atlassian API 토큰                               | Atlassian API 토큰                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Atlassian 사용자 API 토큰                          | AtlassianUserApiToken                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Auth0 클라이언트 시크릿                               | Auth0ClientSecret                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| AWS 액세스 키 ID                                 | AWS                                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| AWS 액세스 시크릿 키                             | AWSSecretAccessKey                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| AWS 세션 토큰                                 | AWSSessionToken                               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| AWS Cognito Identity Pool ID                      | AWSCognitoIdentityPoolID                      | {{< yes >}} | {{< no >}} | {{< no >}} |
| AWS Bedrock 키                                   | AWSBedrockKey                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| AWS Bedrock 단기 키                       | AWSBedrockShortLivedKey                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure API Management Gateway 키                  | AzureAPIManagementGatewayKey                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure API Management Direct 키                   | AzureAPIManagementDirectKey                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Azure 앱 구성                                  | AzureAppConfigConnectionString                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure 통신 서비스                      | AzureCommServicesConnectionString                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure Cosmos DB 인증 정보                       | AzureCosmosDBCredentials                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Azure Entra 클라이언트 시크릿                         | AzureEntraClientSecret                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure Entra 클라이언트 ID 토큰                       | AzureEntraIDToken                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure EventGrid 액세스 키                        | AzureEventGridAccessKey                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Azure Functions API 키                           | AzureFunctionsAPIKey                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure Logic App SAS                               | AzureLogicAppSAS                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Azure OpenAI API 키                              | AzureOpenAIAPIKey                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Azure 개인 액세스 토큰                       | AzurePersonalAccessToken                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Azure SignalR 액세스 키                          | AzureSignalRAccessKey                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Beamer API 토큰                                  | Beamer API 토큰                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Bitbucket 클라이언트 ID                               | Bitbucket 클라이언트 ID                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Bitbucket 클라이언트 시크릿                           | Bitbucket 클라이언트 시크릿                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Brevo API 토큰                                   | Sendinblue API token                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Brevo SMTP 토큰                                  | Sendinblue SMTP token                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Canada Digital Service Notify API 키             | CDSCanadaNotifyAPIKey                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| CircleCI 액세스 토큰                             | CircleCI access tokens                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Clojars 배포 토큰                              | Clojars API token                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| Contentful 제공 API 토큰                     | Contentful 제공 API 토큰                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| Contentful 개인 액세스 토큰                  | ContentfulPersonalAccessToken                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Contentful 미리보기 API 토큰                      | Contentful 미리보기 API 토큰                  | {{< yes >}} | {{< no >}} | {{< no >}} |
| Databricks API 토큰                              | Databricks API 토큰                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| DataDog API 키                                   | DataDogAPIKey                                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| DigitalOcean OAuth 액세스 토큰                   | digitalocean-access-token                     | {{< yes >}} | {{< no >}} | {{< no >}} |
| DigitalOcean 개인 액세스 토큰                | digitalocean-pat                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| DigitalOcean 새로 고침 토큰                        | digitalocean-refresh-token                    | {{< yes >}} | {{< no >}} | {{< no >}} |
| Discord API 키                                   | Discord API 키                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| Discord 클라이언트 ID                                 | Discord 클라이언트 ID                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| Discord 클라이언트 시크릿                             | Discord 클라이언트 시크릿                         | {{< yes >}} | {{< no >}} | {{< no >}} |
| Docker 개인 액세스 토큰                      | DockerPersonalAccessToken                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Doppler API 토큰                                 | Doppler API 토큰                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Doppler 서비스 토큰                             | Doppler 서비스 토큰                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Dropbox API 시크릿/키                            | Dropbox API 시크릿/키                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Dropbox 앱 액세스 토큰                          | DropboxAppAccessToken                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Dropbox 수명이 긴 API 토큰                      | Dropbox 수명이 긴 API 토큰                  | {{< yes >}} | {{< no >}} | {{< no >}} |
| Dropbox 수명이 짧은 API 토큰                     | Dropbox 수명이 짧은 API 토큰                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Duffel API 토큰                                  | Duffel API 토큰                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Dynatrace Platform 토큰                          | DynatracePlatformToken                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| EasyPost 프로덕션 API 키                       | EasyPost API token                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| EasyPost 테스트 API 키                             | EasyPost test API token                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Facebook 토큰                                    | Facebook 토큰                                | {{< yes >}} | {{< no >}} | {{< no >}} |
| Fastly API 사용자 또는 자동화 토큰               | Fastly API token                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Figma 개인 액세스 토큰                       | FigmaPersonalAccessToken                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Finicity API 토큰                                | Finicity API 토큰                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Finicity 클라이언트 시크릿                            | Finicity 클라이언트 시크릿                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Flutterwave Prod 암호화 키                    | FlutterwaveProdEncryptedKey                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Flutterwave 테스트 암호화 키                    | Flutterwave encrypted key                     | {{< yes >}} | {{< no >}} | {{< no >}} |
| Flutterwave Prod 공개 키                       | FlutterwaveProdPublicKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Flutterwave 테스트 공개 키                       | Flutterwave public key                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Flutterwave Prod 시크릿 키                       | FlutterwaveProdSecretKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Flutterwave 테스트 시크릿 키                       | Flutterwave secret key                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Frame.io API 토큰                                | Frame.io API 토큰                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| GCP API 키                                       | GCP API 키                                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| GCP OAuth 클라이언트 시크릿                           | GCP OAuth 클라이언트 시크릿                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GCP Vertex Express Mode 키                       | GCPVertexExpressModeKey                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHub 앱 토큰                                  | Github App Token                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHub 앱 설치 토큰                     | GithubAppInstallationToken                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHub Fine Grained 개인 액세스 토큰         | GithubFineGrainedPersonalAccessToken          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHub OAuth 액세스 토큰                         | Github OAuth Access Token                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHub 개인 액세스 토큰 (클래식)            | Github Personal Access Token                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitHub 새로 고침 토큰                              | Github Refresh Token                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitLab CI/CD 작업 토큰                            | gitlab_ci_build_token                         | {{< yes >}} | {{< yes >}} | {{< no >}} |
| GitLab 배포 토큰                               | gitlab_deploy_token                           | {{< yes >}} | {{< yes >}} | {{< no >}} |
| GitLab 기능 플래그 클라이언트 토큰                 | 없음                                          | {{< no >}} | {{< yes >}} | {{< no >}} |
| GitLab 피드 토큰                                 | gitlab_feed_token                             | {{< yes >}} | {{< yes >}} | {{< no >}} |
| GitLab 피드 토큰 v2                              | gitlab_feed_token_v2                          | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab 수신 이메일 토큰                       | gitlab_incoming_email_token                   | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab Kubernetes 에이전트 토큰                     | gitlab_kubernetes_agent_token                 | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab OAuth 애플리케이션 시크릿                   | gitlab_oauth_app_secret                       | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab 개인 액세스 토큰                      | gitlab_personal_access_token                  | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab 개인 액세스 토큰 (라우팅 가능)           | gitlab_personal_access_token_routable         | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab 파이프라인 트리거 토큰                     | gitlab_pipeline_trigger_token                 | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab 러너 인증 토큰                | gitlab_runner_auth_token                      | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| GitLab 러너 등록 토큰                  | gitlab_runner_registration_token              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| GitLab SCIM OAuth 토큰                           | gitlab_scim_oauth_token                       | {{< yes >}} | {{< yes >}} | {{< no >}} |
| GoCardless API 토큰                              | GoCardless API 토큰                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| Google API 키                                    | GCP API 키                                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Google (GCP) 서비스 계정                      | Google (GCP) Service-account                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Grafana 서비스 계정 토큰                     | GrafanaServiceAccountToken                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Grafana Cloud 액세스 정책 토큰                 | GrafanaCloudAccessPolicyToken                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| HashiCorp Terraform API 토큰                     | Hashicorp Terraform user/org API token        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| HashiCorp Vault 배치 토큰                       | Hashicorp Vault batch token                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| HashiCorp Vault 서비스 토큰                     | HashicorpVaultServiceToken                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Heroku API 키 또는 애플리케이션 인증 토큰 | Heroku API Key                                | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Highnote Live 시크릿 키                          | HighnoteLiveSecretKey                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Highnote Test 시크릿 키                          | HighnoteTestSecretKey                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| HubSpot 비공개 앱 API 토큰                     | Hubspot API token                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Hugging Face 사용자 액세스 토큰                    | HuggingFaceUserAccessToken                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Instagram 액세스 토큰                            | Instagram 액세스 토큰                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Intercom API 토큰                                | Intercom API 토큰                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Intercom 앱 액세스 토큰                         | IntercomAppAccessToken                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Intercom 클라이언트 시크릿 또는 클라이언트 ID               | Intercom client secret/ID                     | {{< yes >}} | {{< no >}} | {{< no >}} |
| Ionic 개인 액세스 토큰                       | Ionic API token                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| JFrog Platform 액세스 토큰                      | JfrogPlatformAccessToken                      | {{< yes >}} | {{< no >}} | {{< no >}} |
| Kubernetes 서비스 계정 토큰                  | KubernetesServiceAccToken                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| LangChain API 키                                 | LangChainAPIKey                               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Linear API 토큰                                  | Linear API 토큰                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Linear 클라이언트 시크릿 또는 ID (OAuth 2.0)            | Linear client secret/ID                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| LinkedIn 클라이언트 ID                                | Linkedin Client ID                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| LinkedIn 클라이언트 시크릿                            | Linkedin Client secret                        | {{< yes >}} | {{< no >}} | {{< no >}} |
| Lob API 키                                       | Lob API Key                                   | {{< yes >}} | {{< no >}} | {{< no >}} |
| Lob 게시 가능 API 키                           | Lob Publishable API Key                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Mailchimp API 키                                 | Mailchimp API 키                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Mailgun 비공개 API 토큰                         | Mailgun 비공개 API 토큰                     | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Mailgun 공개 검증 키                   | Mailgun public validation key                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| Mailgun 웹후크 서명 키                       | Mailgun 웹후크 서명 키                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Mapbox API 토큰                                  | Mapbox API 토큰                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Mapbox 시크릿 API 토큰                           | MapboxSecretApiToken                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| MaxMind 라이선스 키                               | MaxMind 라이선스 키                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| MessageBird 액세스 키                            | messagebird-api-token                         | {{< yes >}} | {{< no >}} | {{< no >}} |
| MessageBird API 클라이언트 ID                         | MessageBird API 클라이언트 ID                     | {{< yes >}} | {{< no >}} | {{< no >}} |
| Meta 액세스 토큰                                 | Meta 액세스 토큰                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| New Relic 수집 브라우저 API 토큰                | New Relic 수집 브라우저 API 토큰            | {{< yes >}} | {{< no >}} | {{< no >}} |
| New Relic 수집 브라우저 API 토큰 v2             | New Relic 수집 브라우저 API 토큰 v2         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| New Relic REST API 키                            | New Relic REST API 키                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| New Relic 사용자 API ID                             | New Relic 사용자 API ID                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| New Relic 사용자 API 키                            | New Relic user API Key                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| npm 액세스 토큰                                  | npm 액세스 토큰                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Oculus 액세스 토큰                               | Oculus 액세스 토큰                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Okta API 토큰                                    | OktaAPIToken                                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Okta 클라이언트 시크릿                                | OktaClientSecret                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Onfido Live API 토큰                             | Onfido Live API 토큰                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| OpenAI API 키                                    | open ai token                                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| OpenAI 프로젝트 키                                | OpenAiProjectKey                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| OpenAI 서비스 계정 키                        | OpenAiServiceAccountKey                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| URL의 비밀번호                                   | URL의 비밀번호                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| PGP 비공개 키                                   | PGP 비공개 키                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| PKCS8 비공개 키                                 | PKCS8 비공개 키                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| PlanetScale API 토큰                             | Planetscale API token                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| PlanetScale 앱 시크릿                            | PlanetscaleAppSecret                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| PlanetScale OAuth 시크릿                          | PlanetscaleOAuthSecret                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| PlanetScale 비밀번호                              | Planetscale password                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| PostHog 개인 API 키                          | PostHogPersonalAPIkey                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| PostHog 프로젝트 API 키                           | PostHogProjectAPIkey                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Postman API 토큰                                 | Postman API 토큰                             | {{< yes >}} | {{< no >}} | {{< no >}} |
| Postman Collection 액세스 키                     | PostmanCollectionAccessKey                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Pulumi API 토큰                                  | Pulumi API 토큰                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| PyPi 업로드 토큰                                 | PyPI upload token                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| RSA 비공개 키                                   | RSA 비공개 키                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| RubyGems API 토큰                                | Rubygem API token                             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Segment 공개 API 토큰                          | Segment Public API token                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| SendGrid API 토큰                                | Sendgrid API token                            | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Shippo API 토큰                                  | Shippo API 토큰                              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Shippo 테스트 API 토큰                             | Shippo 테스트 API 토큰                         | {{< yes >}} | {{< no >}} | {{< no >}} |
| Shopify 파트너 API 토큰                         | ShopifyPartnerAPIToken                        | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Shopify 개인 액세스 토큰                     | Shopify access token                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Shopify 비공개 앱 액세스 토큰                  | Shopify 비공개 앱 액세스 토큰              | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Shopify 사용자 지정 앱 액세스 토큰                   | Shopify custom app access token               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Shopify 공유 시크릿                             | Shopify 공유 시크릿                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Slack 앱 구성 토큰                     | SlackAppConfigurationToken                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Slack 앱 구성 새로 고침 토큰             | SlackAppConfigurationRefreshToken             | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Slack 앱 수준 토큰                             | SlackAppLevelToken                            | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Slack 봇 사용자 OAuth 토큰                        | Slack token                                   | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Slack 웹후크                                     | Slack Webhook                                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| SonarQube Global 분석 토큰                   | SonarQubeGlobalAnalysisToken                  | {{< yes >}} | {{< no >}} | {{< yes >}} |
| SonarQube 프로젝트 분석 토큰                  | SonarQubeProjectAnalysisToken                 | {{< yes >}} | {{< no >}} | {{< yes >}} |
| SonarQube 사용자 토큰                              | SonarQubeUserToken                            | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Splunk 인증 토큰                       | SplunkAuthToken                               | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Splunk HTTP 이벤트 수집기(HEC) 토큰            | SplunkHECToken                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| SSH (DSA) 비공개 키                             | SSH (DSA) 비공개 키                         | {{< yes >}} | {{< no >}} | {{< no >}} |
| SSH (EC) 비공개 키                              | SSH (EC) 비공개 키                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| SSH 비공개 키                                   | SSH 비공개 키                               | {{< yes >}} | {{< no >}} | {{< no >}} |
| Stripe 라이브 제한 키                        | StripeLiveRestrictedKey                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Stripe 라이브 시크릿 키                            | StripeLiveSecretKey                           | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Stripe 라이브 단축 시크릿 키                      | StripeLiveShortSecretKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Stripe 게시 가능 라이브 키                       | StripeLivePublishableKey                      | {{< yes >}} | {{< no >}} | {{< no >}} |
| Stripe 게시 가능 테스트 키                       | StripeTestPublishableKey                      | {{< yes >}} | {{< no >}} | {{< no >}} |
| Stripe 제한 테스트 키                        | StripeTestRestrictedKey                       | {{< yes >}} | {{< no >}} | {{< no >}} |
| Stripe 시크릿 테스트 키                            | StripeTestSecretKey                           | {{< yes >}} | {{< no >}} | {{< no >}} |
| Stripe 테스트 단축 시크릿 키                      | StripeTestShortSecretKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Tailscale OAuth 클라이언트 시크릿                     | TailscaleOauthClientSecret                    | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Tailscale API 액세스 토큰                        | TailscaleApiAccessToken                       | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Tailscale 개인 인증 키                       | TailscalePersonalAuthKey                      | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Tencent Cloud 시크릿 ID                           | TencentCloudSecretID                          | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Twilio 계정 SID                                | Twilio 계정 SID                            | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Twilio API 키                                    | Twilio API Key                                | {{< yes >}} | {{< no >}} | {{< yes >}} |
| Twitch OAuth 클라이언트 시크릿                        | Twitch API token                              | {{< yes >}} | {{< no >}} | {{< no >}} |
| Typeform 개인 액세스 토큰                    | Typeform API token                            | {{< yes >}} | {{< no >}} | {{< no >}} |
| Volcengine 액세스 키 ID                          | VolcengineAccessKeyID                         | {{< yes >}} | {{< no >}} | {{< yes >}} |
| WakaTime API 키                                  | WakaTimeAPIKey                                | {{< yes >}} | {{< no >}} | {{< yes >}} |
| X 토큰                                           | Twitter token                                 | {{< yes >}} | {{< no >}} | {{< no >}} |
| Yandex.Cloud AWS API 호환 액세스 시크릿     | Yandex.Cloud AWS API compatible Access Secret | {{< yes >}} | {{< no >}} | {{< no >}} |
| Yandex.Cloud API 키                              | Yandex.Cloud API 키                          | {{< yes >}} | {{< no >}} | {{< no >}} |
| Yandex.Cloud IAM 쿠키 v1-1                      | Yandex.Cloud IAM Cookie v1 - 1                | {{< yes >}} | {{< no >}} | {{< no >}} |
| Yandex.Cloud IAM 쿠키 v1-3                      | Yandex.Cloud IAM Cookie v1 - 3                | {{< yes >}} | {{< no >}} | {{< no >}} |

<!-- vale gitlab_base.SentenceSpacing = YES -->
<!-- vale gitlab_base.Spelling = YES -->
<!-- markdownlint-enable MD044 -->
