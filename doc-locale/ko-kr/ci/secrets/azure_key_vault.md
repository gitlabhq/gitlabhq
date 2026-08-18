---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab CI/CD 파이프라인에서 Azure Key Vault 비밀을 사용하는 방법을 알아봅니다.
title: GitLab CI/CD에서 Azure Key Vault 비밀 사용
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [GitLab과 GitLab Runner 16.3에서 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/271271). [이슈 424746](https://gitlab.com/gitlab-org/gitlab/-/issues/424746)로 인해 이 기능은 예상대로 작동하지 않았습니다.
- [이슈 424746](https://gitlab.com/gitlab-org/gitlab/-/issues/424746)이 해결되었으며 이 기능은 GitLab Runner 16.6에서 일반 공개되었습니다.

{{< /history >}}

[Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault/)에 저장된 비밀을 GitLab CI/CD 파이프라인에서 사용할 수 있습니다.

전제 조건:

- Azure에 [Key Vault](https://learn.microsoft.com/en-us/azure/key-vault/general/quick-create-portal)를 보유해야 합니다.
  - IAM 사용자는 Key Vault에 할당된 **resource group**에 대해 [**Key Vault Administrator** 역할 할당을 받아야](https://learn.microsoft.com/en-us/azure/role-based-access-control/quickstart-assign-role-user-portal#grant-access) 합니다. 그렇지 않으면 Key Vault 내에 비밀을 생성할 수 없습니다.
- [Azure에서 OpenID Connect를 구성하여 임시 자격증명을 검색하세요](../cloud_services/azure/_index.md). 이 단계에는 Key Vault 액세스를 위해 Azure AD 애플리케이션을 만드는 방법에 대한 지침이 포함됩니다.
- [프로젝트에 CI/CD 변수 추가](../variables/_index.md#for-a-project)하여 Vault 서버에 대한 세부 정보를 제공합니다:
  - `AZURE_KEY_VAULT_SERVER_URL`: Azure Key Vault 서버의 URL(예: `https://vault.example.com`)입니다.
  - `AZURE_CLIENT_ID`: Azure 애플리케이션의 클라이언트 ID입니다.
  - `AZURE_TENANT_ID`: Azure 애플리케이션의 테넌트 ID입니다.

## CI/CD 작업에서 Azure Key Vault 비밀 사용 {#use-azure-key-vault-secrets-in-a-cicd-job}

[`azure_key_vault`](../yaml/_index.md#secretsazure_key_vault) 키워드로 정의하여 Azure Key Vault에 저장된 비밀을 작업에서 사용할 수 있습니다:

```yaml
job:
  id_tokens:
    AZURE_JWT:
      aud: 'https://gitlab.com'
  secrets:
    DATABASE_PASSWORD:
      token: $AZURE_JWT
      azure_key_vault:
        name: 'DATABASE-PASSWORD'
        version: '00000000000000000000000000000000'
```

동일한 작업에서 Azure Key Vault의 여러 비밀을 사용하려면 `secrets` 키워드 아래에 각 비밀을 정의합니다:

```yaml
job:
  id_tokens:
    AZURE_JWT:
      aud: 'https://gitlab.com'
  secrets:
    REDIS_PASSWORD:
      token: $AZURE_JWT
      azure_key_vault:
        name: 'REDIS-PASSWORD'
        version: '00000000000000000000000000000000'
    DATABASE_PASSWORD:
      token: $AZURE_JWT
      azure_key_vault:
        name: 'DATABASE-PASSWORD'
        version: '00000000000000000000000000000000'
```

다음 예에서:

- `aud`은 [페더레이션된 ID 자격증명을 만들](../cloud_services/azure/_index.md#create-entra-id-federated-identity-credentials) 때 사용한 대상과 일치해야 하는 대상입니다.
- `name`은 Azure Key Vault의 비밀 이름입니다.
- `version`은 Azure Key Vault의 비밀 버전입니다. 버전은 Azure Key Vault 비밀 페이지에서 찾을 수 있는 대시가 없는 생성된 GUID입니다.
- GitLab은 Azure Key Vault에서 비밀을 가져와서 값을 임시 파일에 저장합니다. 이 파일의 경로는 비밀 아래에 정의한 이름의 CI/CD 변수에 저장되며(예: `DATABASE_PASSWORD` 또는 `REDIS_PASSWORD`), [파일 유형 CI/CD 변수](../variables/_index.md#use-file-type-cicd-variables)와 유사합니다.

## 문제 해결 {#troubleshooting}

Azure를 사용하여 OIDC를 설정할 때 발생하는 일반적인 문제에 대해 [Azure OIDC 문제 해결](../cloud_services/azure/_index.md#troubleshooting)을 참고하세요.

### `JWT token is invalid or malformed` 메시지 {#jwt-token-is-invalid-or-malformed-message}

Azure Key Vault에서 비밀을 가져올 때 이 오류가 나타날 수 있습니다:

```plaintext
RESPONSE 400 Bad Request
AADSTS50027: JWT token is invalid or malformed.
```

이는 러너의 [알려진 이슈](https://gitlab.com/gitlab-org/gitlab/-/issues/424746)로 인해 발생하며 JWT 토큰이 올바르게 파싱되지 않습니다. 이를 해결하려면 GitLab Runner 16.6 이상으로 업그레이드하세요.

### `Caller is not authorized to perform action on resource` 메시지 {#caller-is-not-authorized-to-perform-action-on-resource-message}

Azure Key Vault에서 비밀을 가져올 때 이 오류가 나타날 수 있습니다:

```plaintext
RESPONSE 403: 403 Forbidden
ERROR CODE: Forbidden
Caller is not authorized to perform action on resource.\r\nIf role assignments, deny assignments or role definitions were changed recently, please observe propagation time.
ForbiddenByRbac
```

Azure Key Vault에서 RBAC를 사용하는 경우 Azure AD 애플리케이션에 **Key Vault Secrets User** 역할 할당을 추가해야 합니다.

예를 들어:

```shell
appId=$(az ad app list --display-name gitlab-oidc --query '[0].appId' -otsv)
az role assignment create --assignee $appId --role "Key Vault Secrets User" --scope /subscriptions/<subscription-id>
```

구독 ID는 다음에서 찾을 수 있습니다:

- [Azure 포털](https://learn.microsoft.com/en-us/azure/azure-portal/get-subscription-tenant-id#find-your-azure-subscription)입니다.
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/manage-azure-subscriptions-azure-cli#get-the-active-subscription)입니다.

### `The secrets provider can not be found. Check your CI/CD variables and try again.` 메시지 {#the-secrets-provider-can-not-be-found-check-your-cicd-variables-and-try-again-message}

Azure Key Vault에 액세스하도록 구성된 작업을 시작하려고 할 때 이 오류가 나타날 수 있습니다:

```plaintext
The secrets provider can not be found. Check your CI/CD variables and try again.
```

필수 변수 중 하나 이상이 정의되지 않았기 때문에 작업을 만들 수 없습니다:

- `AZURE_KEY_VAULT_SERVER_URL`
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
