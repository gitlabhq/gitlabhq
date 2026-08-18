---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GCP Workload Identity Federation으로 OpenID Connect 구성
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> `CI_JOB_JWT_V2`는 [GitLab 15.9에서 사용 중단됨](../../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated)이며 GitLab 17.0에서 제거될 예정입니다. 대신 [ID 토큰](../../secrets/id_token_authentication.md)을 사용하세요.

이 튜토리얼에서는 JSON Web Token(JWT) 토큰 및 Workload Identity Federation을 사용하여 GitLab CI/CD 작업에서 Google Cloud로 인증하는 방법을 보여줍니다. 이 구성은 필요할 때마다 비밀을 저장할 필요 없이 수명이 짧은 자격 증명을 생성합니다.

시작하려면 GitLab과 Google Cloud 간의 ID 연동을 위해 OpenID Connect(OIDC)를 구성하세요. GitLab에서 OIDC 사용에 대한 자세한 정보는 [클라우드 서비스에 연결](../_index.md)을 읽으세요.

이 튜토리얼에서는 Google Cloud 계정과 Google Cloud 프로젝트가 있다고 가정합니다. 계정에는 Google Cloud 프로젝트에 대해 최소한 **workload identity pool Admin** 권한이 있어야 합니다.

> [!note]
> 이 튜토리얼 대신 Terraform 모듈과 CI/CD 템플릿을 사용하려면 [OIDC가 GitLab CI/CD 파이프라인과 Google Cloud 인증을 어떻게 단순화하는지](https://about.gitlab.com/blog/introduction-of-oidc-modules-for-integration-between-google-cloud-and-gitlab-ci/)를 참조하세요.

이 튜토리얼을 완료하려면:

1. [Google Cloud workload identity pool 생성](#create-the-google-cloud-workload-identity-pool)하세요.
1. [workload identity provider 생성](#create-a-workload-identity-provider)하세요.
1. [서비스 계정 가장에 대한 권한 부여](#grant-permissions-for-service-account-impersonation)하세요.
1. [임시 자격 증명 검색](#retrieve-a-temporary-credential)하세요.

## Google Cloud workload identity pool 생성 {#create-the-google-cloud-workload-identity-pool}

[새 Google Cloud workload identity pool 생성](https://cloud.google.com/iam/docs/workload-identity-federation-with-other-clouds#create_the_workload_identity_pool_and_provider)하며 다음 옵션을 사용하세요:

- **Name (이름)**: workload identity pool의 사람이 읽을 수 있는 이름(예: `GitLab`)입니다.
- **풀 ID**: workload identity pool에 대한 Google Cloud 프로젝트의 고유 ID(예: `gitlab`)입니다. 이 값은 풀을 참조하는 데 사용되며 URL에 나타납니다.
- **Description (설명)**: 선택 사항. 풀에 대한 설명입니다.
- **Enabled Pool**: 이 옵션이 `true`인지 확인하세요.

GitLab 설치당 Google Cloud 프로젝트당 단일 풀을 생성하는 것이 좋습니다. 동일한 GitLab 인스턴스에 여러 GitLab 리포지토리 및 CI/CD 작업이 있는 경우, 동일한 풀에 대해 다른 공급자를 사용하여 인증할 수 있습니다.

## workload identity provider 생성 {#create-a-workload-identity-provider}

[새 Google Cloud workload identity provider 생성](https://cloud.google.com/iam/docs/workload-identity-federation-with-other-clouds#create_the_workload_identity_pool_and_provider)하며 이전 단계에서 생성한 workload identity pool 내부에서 다음 옵션을 사용하세요:

- **공급자 유형**: OpenID Connect(OIDC)입니다.
- **Provider name**: workload identity provider의 사람이 읽을 수 있는 이름(예: `gitlab/gitlab`)입니다.
- **공급자 ID**: workload identity provider에 대한 풀의 고유 ID(예: `gitlab-gitlab`)입니다. 이 값은 공급자를 참조하는 데 사용되며 URL에 나타납니다.
- **Issuer (URL)**: GitLab 인스턴스의 주소(예: `https://gitlab.com/` 또는 `https://gitlab.example.com/`)입니다.
  - 주소는 `https://` 프로토콜을 사용해야 합니다.
  - 주소는 슬래시로 끝나야 합니다.
- **Audiences**: 허용된 대상 목록을 GitLab 인스턴스의 주소(예: `https://gitlab.com` 또는 `https://gitlab.example.com`)로 수동으로 설정하세요.
  - 주소는 `https://` 프로토콜을 사용해야 합니다.
  - 주소는 슬래시로 끝나면 안 됩니다.
- **Provider attributes mapping**: `attribute.X`가 Google 토큰에 클레임으로 포함될 속성의 이름이고 `assertion.X`이 [GitLab 클레임](../_index.md#id-token-authentication-for-cloud-services)에서 추출할 값인 다음 매핑을 생성하세요:

  | 속성(Google) | 어설션(GitLab에서) |
  | --- | --- |
  | `google.subject` | `assertion.sub` |
  | `attribute.X` | `assertion.X` |

  [복잡한 속성 빌드](https://cloud.google.com/iam/docs/workload-identity-federation#mapping)하기 위해 Common Expression Language(CEL)를 사용할 수도 있습니다.

  권한 부여에 사용하려는 모든 속성을 매핑해야 합니다. 예를 들어 다음 단계에서 사용자의 이메일 주소를 기반으로 권한을 매핑하려면 `attribute.user_email`을(를) `assertion.user_email`에 매핑해야 합니다.

> [!warning]
> GitLab.com에서 호스팅되는 프로젝트의 경우 GCP에서 [GitLab 그룹에서 발급한 토큰으로만 액세스를 제한](https://cloud.google.com/iam/docs/workload-identity-federation-with-deployment-pipelines#gitlab-saas_2)해야 합니다.

## 서비스 계정 가장에 대한 권한 부여 {#grant-permissions-for-service-account-impersonation}

workload identity pool 및 workload identity provider를 생성하면 Google Cloud로의 인증이 정의됩니다. 이 시점에서 GitLab CI/CD 작업에서 Google Cloud로 인증할 수 있습니다. 그러나 Google Cloud에 대한 권한이 없습니다(권한 부여).

GitLab CI/CD 작업에 Google Cloud에 대한 권한을 부여하려면 다음을 수행해야 합니다:

1. [Google Cloud 서비스 계정 생성](https://cloud.google.com/iam/docs/service-accounts-create)하세요. 원하는 이름과 ID를 사용할 수 있습니다.
1. [IAM 권한을 부여](https://cloud.google.com/iam/docs/granting-changing-revoking-access)하여 Google Cloud 리소스에 대한 서비스 계정을 부여합니다. 이러한 권한은 사용 사례에 따라 크게 다릅니다. 일반적으로 GitLab CI/CD 작업이 사용할 수 있기를 원하는 Google Cloud 프로젝트 및 리소스에 대한 권한을 이 서비스 계정에 부여하세요. 예를 들어 GitLab CI/CD 작업에서 Google Cloud Storage 버킷에 파일을 업로드해야 하는 경우 Cloud Storage 버킷에서 이 서비스 계정에 `roles/storage.objectCreator` 역할을 부여합니다.
1. [외부 ID에 권한을 부여](https://cloud.google.com/iam/docs/workload-identity-federation-with-other-clouds#impersonate)하여 서비스 계정을 가장합니다. 이 단계를 통해 GitLab CI/CD 작업이 서비스 계정 가장을 통해 Google Cloud로 권한을 부여할 수 있습니다. 이 단계는 서비스 계정 자체에 IAM 권한을 부여하여 외부 ID에 해당 서비스 계정으로 작동할 수 있는 권한을 제공합니다. 외부 ID는 `principalSet://` 프로토콜을 사용하여 표현됩니다.

이전 단계와 마찬가지로 이 단계는 원하는 구성에 따라 크게 달라집니다. 예를 들어 GitLab CI/CD 작업이 `my-service-account` 이름의 서비스 계정을 가장할 수 있도록 허용하려고 하고 GitLab CI/CD 작업이 사용자 이름 `chris`인 GitLab 사용자에 의해 시작된 경우 `roles/iam.workloadIdentityUser` IAM 역할을 `my-service-account`의 외부 ID에 부여합니다. 외부 ID는 다음 형식을 사용합니다:

```plaintext
principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/attribute.user_login/chris
```

`PROJECT_NUMBER`은(는) Google Cloud 프로젝트 번호이고 `POOL_ID`은(는) 첫 번째 섹션에서 생성한 workload identity pool의 ID(이름이 아님)입니다.

이 구성은 또한 이전 섹션의 어설션에서 매핑된 속성으로 `user_login`을(를) 추가했다고 가정합니다.

## 임시 자격 증명 검색 {#retrieve-a-temporary-credential}

OIDC 및 역할을 구성한 후 GitLab CI/CD 작업은 [Google Cloud Security Token Service(STS)](https://cloud.google.com/iam/docs/reference/sts/rest)에서 임시 자격 증명을 검색할 수 있습니다.

`id_tokens`을(를) CI/CD 작업에 추가하세요:

```yaml
job:
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://gitlab.example.com
```

ID 토큰을 사용하여 임시 자격 증명을 가져오세요:

```shell
PAYLOAD="$(cat <<EOF
{
  "audience": "//iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID",
  "grantType": "urn:ietf:params:oauth:grant-type:token-exchange",
  "requestedTokenType": "urn:ietf:params:oauth:token-type:access_token",
  "scope": "https://www.googleapis.com/auth/cloud-platform",
  "subjectTokenType": "urn:ietf:params:oauth:token-type:jwt",
  "subjectToken": "${GITLAB_OIDC_TOKEN}"
}
EOF
)"
```

```shell
FEDERATED_TOKEN="$(curl --fail "https://sts.googleapis.com/v1/token" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --data "${PAYLOAD}" \
  | jq -r '.access_token'
)"
```

위치:

- `PROJECT_NUMBER`은(는) Google Cloud 프로젝트 번호(이름이 아님)입니다.
- `POOL_ID`은(는) 첫 번째 섹션에서 생성한 workload identity pool의 ID입니다.
- `PROVIDER_ID`은(는) 두 번째 섹션에서 생성한 workload identity provider의 ID입니다.
- `GITLAB_OIDC_TOKEN`은(는) OIDC [ID 토큰](../../secrets/id_token_authentication.md)입니다.

그러면 결과 페더레이션 토큰을 사용하여 이전 섹션에서 생성한 서비스 계정을 가장할 수 있습니다:

```shell
ACCESS_TOKEN="$(curl --fail "https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/SERVICE_ACCOUNT_EMAIL:generateAccessToken" \
  --header "Accept: application/json" \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer FEDERATED_TOKEN" \
  --data '{"scope": ["https://www.googleapis.com/auth/cloud-platform"]}' \
  | jq -r '.accessToken'
)"
```

위치:

- `SERVICE_ACCOUNT_EMAIL`은(는) 가장할 서비스 계정의 전체 이메일 주소(이전 섹션에서 생성됨)입니다.
- `FEDERATED_TOKEN`은(는) 이전 단계에서 검색한 페더레이션 토큰입니다.

결과는 Google Cloud OAuth 2.0 액세스 토큰이며, 이를 베어러 토큰으로 사용할 때 대부분의 Google Cloud API 및 서비스에 인증하는 데 사용할 수 있습니다. 이 값을 `gcloud` CLI에 전달할 수도 있습니다(환경 변수 `CLOUDSDK_AUTH_ACCESS_TOKEN` 설정).

## 작업 예제 {#working-example}

이 [참조 프로젝트](https://gitlab.com/guided-explorations/gcp/configure-openid-connect-in-gcp)를 검토하여 Terraform과 임시 자격 증명을 검색하는 샘플 스크립트를 사용하여 GCP에서 OIDC를 프로비저닝하세요.

## 문제 해결 {#troubleshooting}

- `curl` 응답을 디버깅할 때 최신 버전의 curl을 설치하세요. `--fail-with-body`를 `-f` 대신 사용하세요. 이 명령은 전체 본문을 출력하므로 유용한 오류 메시지를 포함할 수 있습니다.

- 자세한 내용은 [Workload Identity Federation 문제 해결](https://cloud.google.com/iam/docs/troubleshooting-workload-identity-federation)을 참조하세요.
