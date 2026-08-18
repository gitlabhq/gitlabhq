---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Azure에서 OpenID Connect를 구성하여 임시 자격 증명 검색
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!warning]
> `CI_JOB_JWT_V2`는 [GitLab 15.9에서 더 이상 사용되지 않으며](../../../update/deprecations.md#old-versions-of-json-web-tokens-are-deprecated) GitLab 17.0에서 제거될 예정입니다. 대신 [ID 토큰](../../secrets/id_token_authentication.md)을 사용하세요.

이 튜토리얼에서는 GitLab CI/CD 작업에서 JSON 웹 토큰(JWT)을 사용하여 비밀을 저장할 필요 없이 Azure에서 임시 자격 증명을 검색하는 방법을 설명합니다.

시작하려면 GitLab과 Azure 간의 ID 페더레이션을 위해 OpenID Connect(OIDC)를 구성합니다. GitLab에서 OIDC 사용에 대한 자세한 내용을 보려면 [클라우드 서비스에 연결](../_index.md)을 읽으세요.

전제 조건:

- `Owner` 액세스 수준이 있는 기존 Azure 구독에 대한 액세스.
- 최소한 `Application Developer` 액세스 수준이 있는 해당 Microsoft Entra ID 테넌트에 대한 액세스.
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)의 로컬 설치. 또는 [Azure Cloud Shell](https://portal.azure.com/#cloudshell/)로 다음의 모든 단계를 사용할 수 있습니다.
- GitLab 인스턴스는 Azure가 GitLab OIDC 엔드포인트에 연결할 수 있도록 인터넷을 통해 공개적으로 액세스할 수 있어야 합니다.
- GitLab 프로젝트.

이 튜토리얼을 완료하려면:

1. [Entra ID 애플리케이션 및 서비스 주체 생성](#create-an-entra-id-application-and-service-principal).
1. [Entra ID 페더레이션 ID 자격 증명 생성](#create-entra-id-federated-identity-credentials).
1. [서비스 주체에 대한 권한 부여](#grant-permissions-for-the-service-principal).
1. [임시 자격 증명 검색](#retrieve-a-temporary-credential).

Azure ID 페더레이션에 대한 자세한 내용을 보려면 [워크로드 ID 페더레이션](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation)을 참조하세요.

## Entra ID 애플리케이션 및 서비스 주체 생성 {#create-an-entra-id-application-and-service-principal}

GitLab을 위한 [Entra ID 애플리케이션](https://learn.microsoft.com/en-us/cli/azure/ad/app?view=azure-cli-latest#az-ad-app-create) 및 서비스 주체를 생성하려면:

1. Azure CLI에서 GitLab용 애플리케이션을 생성합니다:

   ```shell
   appId=$(az ad app create --display-name gitlab-oidc --query appId -otsv)
   ```

   `appId`(애플리케이션 클라이언트 ID) 출력을 저장합니다. 나중에 GitLab CI/CD 파이프라인을 구성하는 데 필요합니다.

1. 해당 [서비스 주체](https://learn.microsoft.com/en-us/cli/azure/ad/sp?view=azure-cli-latest#az-ad-sp-create)를 생성합니다:

   ```shell
   az ad sp create --id $appId --query appId -otsv
   ```

Azure CLI 대신 [Azure Portal을 사용하여 이러한 리소스를 생성](https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal)할 수 있습니다.

## Entra ID 페더레이션 ID 자격 증명 생성 {#create-entra-id-federated-identity-credentials}

`<mygroup>/<myproject>`에서 특정 브랜치에 대한 이전 Entra ID 애플리케이션의 페더레이션 ID 자격 증명을 생성하려면:

```shell
objectId=$(az ad app show --id $appId --query id -otsv)

cat <<EOF > body.json
{
  "name": "gitlab-federated-identity",
  "issuer": "https://gitlab.example.com",
  "subject": "project_path:<mygroup>/<myproject>:ref_type:branch:ref:<branch>",
  "description": "GitLab service account federated identity",
  "audiences": [
    "https://gitlab.example.com"
  ]
}
EOF

az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$objectId/federatedIdentityCredentials" --body @body.json
```

`issuer`, `subject` 또는 `audiences`의 값과 관련된 이슈는 [이슈 해결](#troubleshooting) 세부 정보를 참조하세요.

선택적으로 Azure Portal에서 Entra ID 애플리케이션 및 Entra ID 페더레이션 ID 자격 증명을 확인할 수 있습니다:

1. [Microsoft Entra ID 앱 등록](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps) 뷰를 열고 표시 이름 `gitlab-oidc`을(를) 검색하여 적절한 앱 등록을 선택합니다.
1. 개요 페이지에서 `Application (client) ID`, `Object ID` 및 `Tenant ID` 등의 세부 정보를 확인할 수 있습니다.
1. `Certificates & secrets` 아래에서 `Federated credentials`로 이동하여 Entra ID 페더레이션 ID 자격 증명을 검토합니다.

### 모든 브랜치 또는 태그에 대한 자격 증명 생성 {#create-credentials-for-any-branch-or-any-tag}

모든 브랜치 또는 태그(와일드카드 일치)에 대한 자격 증명을 생성하려면 [유연한 페더레이션 ID 자격 증명](https://learn.microsoft.com/entra/workload-id/workload-identities-flexible-federated-identity-credentials)을 사용할 수 있습니다.

`<mygroup>/<myproject>`의 모든 브랜치에 대해:

```shell
objectId=$(az ad app show --id $appId --query id -otsv)

cat <<EOF > body.json
{
  "name": "gitlab-federated-identity",
  "issuer": "https://gitlab.example.com",
  "subject": null,
  "claimsMatchingExpression": {
    "value": "claims['sub'] matches 'project_path:<mygroup>/<myproject>:ref_type:branch:ref:*'",
    "languageVersion": 1
  },
  "description": "GitLab service account federated identity",
  "audiences": [
    "https://gitlab.example.com"
  ]
}
EOF

az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$objectId/federatedIdentityCredentials" --body @body.json
```

`<mygroup>/<myproject>`의 모든 태그에 대해:

```shell
objectId=$(az ad app show --id $appId --query id -otsv)

cat <<EOF > body.json
{
  "name": "gitlab-federated-identity",
  "issuer": "https://gitlab.example.com",
  "subject": null,
  "claimsMatchingExpression": {
    "value": "claims['sub'] matches 'project_path:<mygroup>/<myproject>:ref_type:tag:ref:*'",
    "languageVersion": 1
  },
  "description": "GitLab service account federated identity",
  "audiences": [
    "https://gitlab.example.com"
  ]
}
EOF

az rest --method POST --uri "https://graph.microsoft.com/beta/applications/$objectId/federatedIdentityCredentials" --body @body.json
```

## 서비스 주체에 대한 권한 부여 {#grant-permissions-for-the-service-principal}

자격 증명을 생성한 후 [`role assignment`](https://learn.microsoft.com/en-us/cli/azure/role/assignment?view=azure-cli-latest#az-role-assignment-create)를 사용하여 이전 서비스 주체에 권한을 부여하여 Azure 리소스에 액세스할 수 있도록 합니다:

```shell
az role assignment create --assignee $appId --role Reader --scope /subscriptions/<subscription-id>
```

구독 ID는 다음에서 찾을 수 있습니다:

- [Azure 포털](https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id#find-your-azure-subscription)입니다.
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli#get-the-active-subscription)입니다.

이전 명령은 전체 구독에 읽기 전용 권한을 부여합니다. 조직의 맥락에서 최소 권한의 원칙을 적용하는 방법에 대한 자세한 내용을 보려면 [Entra ID 역할의 모범 사례](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/best-practices)를 읽으세요.

## 임시 자격 증명 검색 {#retrieve-a-temporary-credential}

Entra ID 애플리케이션 및 페더레이션 ID 자격 증명을 구성한 후 CI/CD 작업은 [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest#az-login)를 사용하여 임시 자격 증명을 검색할 수 있습니다:

```yaml
default:
  image: mcr.microsoft.com/azure-cli:latest

variables:
  AZURE_CLIENT_ID: "<client-id>"
  AZURE_TENANT_ID: "<tenant-id>"

auth:
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: https://gitlab.com
  script:
    - az login --service-principal -u $AZURE_CLIENT_ID -t $AZURE_TENANT_ID --federated-token $GITLAB_OIDC_TOKEN
    - az account show
```

CI/CD 변수는 다음과 같습니다:

- `AZURE_CLIENT_ID`: 이전에 저장한 [애플리케이션 클라이언트 ID](#create-an-entra-id-application-and-service-principal).
- `AZURE_TENANT_ID`: Microsoft Entra ID 테넌트 ID. [Azure CLI 또는 Azure Portal을 사용하여 찾을 수](https://learn.microsoft.com/en-us/entra/fundamentals/how-to-find-tenant) 있습니다.
- `GITLAB_OIDC_TOKEN`: OIDC [ID 토큰](../../secrets/id_token_authentication.md).

## 문제 해결 {#troubleshooting}

### 오류: `No matching federated identity record found` {#error-no-matching-federated-identity-record-found}

`ERROR: AADSTS70021: No matching federated identity record found for presented assertion.` 오류가 표시되면 다음을 확인해야 합니다:

- Entra ID 페더레이션 ID 자격 증명에 정의된 `Issuer`, 예를 들어 `https://gitlab.com` 또는 고유한 GitLab URL.
- Entra ID 페더레이션 ID 자격 증명에 정의된 `Subject identifier`, 예를 들어 `project_path:<mygroup>/<myproject>:ref_type:branch:ref:<branch>`.
  - `gitlab-group/gitlab-project` 프로젝트 및 `main` 브랜치의 경우 `project_path:gitlab-group/gitlab-project:ref_type:branch:ref:main`이 됩니다.
  - `mygroup` 및 `myproject`의 올바른 값은 GitLab 프로젝트에 액세스할 때 URL을 확인하거나 프로젝트 개요 페이지의 오른쪽 위 모서리에서 **코드**를 선택하여 검색할 수 있습니다.
- Entra ID 페더레이션 ID 자격 증명에 정의된 `Audience`, 예를 들어 `https://gitlab.com` 또는 고유한 GitLab URL.

`AZURE_CLIENT_ID` 및 `AZURE_TENANT_ID` CI/CD 변수뿐만 아니라 이러한 설정을 Azure Portal에서 검토할 수 있습니다:

1. [Microsoft Entra ID 앱 등록](https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps) 뷰를 열고 표시 이름 `gitlab-oidc`을(를) 검색하여 적절한 앱 등록을 선택합니다.
1. 개요 페이지에서 `Application (client) ID`, `Object ID` 및 `Tenant ID` 등의 세부 정보를 확인할 수 있습니다.
1. `Certificates & secrets` 아래에서 `Federated credentials`로 이동하여 Entra ID 페더레이션 ID 자격 증명을 검토합니다.

자세한 내용을 보려면 [클라우드 서비스에 연결](../_index.md)을 검토하세요.

### `Request to External OIDC endpoint failed` 메시지 {#request-to-external-oidc-endpoint-failed-message}

`ERROR: AADSTS501661: Request to External OIDC endpoint failed.` 오류가 표시되면 GitLab 인스턴스가 인터넷에서 공개적으로 액세스할 수 있는지 확인해야 합니다.

Azure는 OIDC로 인증하기 위해 다음 GitLab 엔드포인트에 액세스할 수 있어야 합니다:

- `GET /.well-known/openid-configuration`
- `GET /oauth/discovery/keys`

방화벽을 업데이트한 후에도 여전히 이 오류가 발생하면 [Redis 캐시 지우기](../../../administration/raketasks/maintenance.md#clear-redis-cache)를 시도하고 다시 시도하세요.

### `No matching federated identity record found for presented assertion audience` 메시지 {#no-matching-federated-identity-record-found-for-presented-assertion-audience-message}

`ERROR: AADSTS700212: No matching federated identity record found for presented assertion audience 'https://gitlab.com'` 오류가 표시되면 CI/CD 작업이 올바른 `aud` 값을 사용하는지 확인해야 합니다.

`aud` 값은 [페더레이션 ID 자격 증명을 생성](#create-entra-id-federated-identity-credentials)할 때 사용되는 대상과 일치해야 합니다.
