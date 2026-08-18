---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "GitLab CI/CD에서 HashiCorp Vault 비밀을 사용하는 방법을 알아봅니다. 인증, Vault 구성, 정책 및 비밀 엔진이 포함됩니다."
title: 'GitLab CI/CD에서 HashiCorp Vault 비밀 사용'
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab CI/CD에서 HashiCorp Vault 비밀을 사용할 수 있습니다. [ID 토큰](id_token_authentication.md)을 사용하여 [HashiCorp Vault로 인증](https://developer.hashicorp.com/vault/docs/auth/jwt#jwt-authentication)합니다.

CI/CD 작업에서 Vault 비밀을 사용하기 전에 Vault 서버를 구성해야 합니다. [HashiCorp Vault를 사용하여 비밀 인증 및 읽기](hashicorp_vault_tutorial.md) 자습서에서 Vault 구성 및 ID 토큰을 사용한 인증에 대한 자세한 내용을 확인할 수 있습니다.

다음 예제에서 `vault.example.com`을 Vault 서버의 URL로 바꾸고, `gitlab.example.com`를 GitLab 인스턴스의 URL로 바꾸세요.

## Vault 서버 구성 {#configure-your-vault-server}

Vault 서버를 구성하려면:

1. 다음 명령을 실행하여 인증 방법을 활성화합니다. 이 명령은 Vault 서버에 GitLab 인스턴스의 [OIDC Discovery URL](https://openid.net/specs/openid-connect-discovery-1_0.html)을 제공하므로 Vault가 인증할 때 공개 서명 키를 가져오고 JSON Web Token(JWT)을 확인할 수 있습니다:

   ```shell
   $ vault auth enable jwt

   $ vault write auth/jwt/config \
     oidc_discovery_url="https://gitlab.example.com" \
     bound_issuer="gitlab.example.com"
   ```

1. 특정 경로 및 작업에 대한 액세스를 허용하거나 거부하도록 Vault 서버의 정책을 구성합니다. 이 예제는 프로덕션 환경에 필요한 비밀 집합에 대한 읽기 액세스 권한을 부여합니다:

   ```shell
   vault policy write myproject-production - <<EOF
   # Read-only permission on 'ops/data/production/*' path

   path "ops/data/production/*" {
     capabilities = [ "read" ]
   }
   EOF
   ```

1. [Vault 서버의 역할](#configure-server-roles)을 구성하고, 역할을 프로젝트 또는 네임스페이스로 제한합니다.
1. 다음 [CI/CD 변수](../variables/_index.md#for-a-project)를 생성하여 Vault 서버에 대한 세부 정보를 제공합니다:
   - `VAULT_SERVER_URL`: `https://vault.example.com:8200`와 같은 Vault 서버의 URL입니다.
   - `VAULT_AUTH_ROLE`: 선택 사항. 인증을 시도할 때 사용할 역할입니다. 역할을 지정하지 않으면 Vault는 인증 방법이 구성되었을 때 지정된 [기본 역할](https://developer.hashicorp.com/vault/api-docs/auth/jwt#default_role)을 사용합니다.
   - `VAULT_AUTH_PATH`: 선택 사항. 인증 방법이 마운트된 경로입니다. 기본값은 `jwt`입니다.
   - `VAULT_NAMESPACE`: 선택 사항. 비밀을 읽고 인증하는 데 사용할 [Vault Enterprise 네임스페이스](https://developer.hashicorp.com/vault/docs/enterprise/namespaces)입니다. 다음:
     - Vault, `root` ("`/`") 네임스페이스는 네임스페이스가 지정되지 않은 경우에 사용됩니다.
     - Vault 오픈소스는 이 설정이 무시됩니다.
     - [HashiCorp Cloud Platform (HCP)](https://www.hashicorp.com/cloud) Vault는 네임스페이스가 필요합니다. HCP Vault는 기본적으로 `admin` 네임스페이스를 루트 네임스페이스로 사용합니다. 예를 들어, `VAULT_NAMESPACE=admin`입니다.

### 서버 역할 구성 {#configure-server-roles}

CI/CD 작업에서 인증을 시도할 때 역할을 지정합니다. 다양한 정책을 함께 그룹화하기 위해 역할을 사용할 수 있습니다. 인증에 성공하면 이러한 정책이 결과 Vault 토큰에 첨부됩니다.

[Bound claims](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-claims)는 JWT claims와 일치하는 미리 정의된 값입니다. 경계 claims를 사용하면 특정 GitLab 사용자, 특정 프로젝트 또는 특정 Git 참조에 대해 실행 중인 작업에 대한 액세스를 제한할 수 있습니다. 필요한 만큼 많은 경계 claims를 가질 수 있지만 인증이 성공하려면 모두 일치해야 합니다.

경계 claims를 [사용자 역할](../../user/permissions.md) 및 [보호된 브랜치](../../user/project/repository/branches/protected.md)와 같은 GitLab 기능과 결합하면 특정 사용 사례에 맞게 이러한 규칙을 조정할 수 있습니다. 이 예제에서 인증은 프로덕션 릴리스에 사용되는 패턴과 일치하는 이름으로 보호된 태그에 대해 실행 중인 작업에만 허용됩니다:

```json
$ vault write auth/jwt/role/myproject-production - <<EOF
{
  "role_type": "jwt",
  "policies": ["myproject-production"],
  "token_explicit_max_ttl": 60,
  "user_claim": "user_email",
  "bound_audiences": "https://vault.example.com",
  "bound_claims_type": "glob",
  "bound_claims": {
    "project_id": "42",
    "ref_protected": "true",
    "ref_type": "tag",
    "ref": "auto-deploy-*"
  }
}
EOF
```

> [!warning]
> 제공된 claims(예: `project_id` 또는 `namespace_id`)를 사용하여 프로젝트 또는 네임스페이스에 대한 역할을 항상 제한하세요. 이러한 제한 없이 이 GitLab 인스턴스에서 생성된 모든 JWT가 이 역할을 사용하여 인증할 수 있습니다.

ID 토큰 JWT claims의 전체 목록은 [HashiCorp Vault 시크릿을 GitLab CI/CD에서 사용](hashicorp_vault_tutorial.md) 튜토리얼을 검토하세요.

TTL(Time-To-Live), IP 주소 범위, 사용 횟수 등과 같은 결과 Vault 토큰의 일부 속성을 지정할 수 있습니다. 전체 옵션 목록은 JSON 웹 토큰 방식의 [Vault 역할 생성 설명서](https://developer.hashicorp.com/vault/api-docs/auth/jwt#create-role)에서 확인할 수 있습니다.

## CI/CD 작업에서 Vault 시크릿 사용 {#use-vault-secrets-in-a-cicd-job}

작업에 정의된 ID 토큰이 하나 이상 있을 때, [`secrets`](../yaml/_index.md#secrets) 키워드가 자동으로 해당 토큰을 사용하여 Vault로 인증합니다.

[Vault 서버 구성](#configure-your-vault-server) 후, [`secrets:vault`](../yaml/_index.md#secretsvault) 키워드를 사용하여 Vault에 저장된 시크릿을 사용하세요:

```yaml
job_using_vault:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    DATABASE_PASSWORD:
      vault: production/db/password@ops
      token: $VAULT_ID_TOKEN
```

이 예에서:

- `production/db`은 시크릿의 경로입니다.
- `password`은 필드입니다.
- `ops`은 시크릿 엔진이 마운트되는 경로입니다.
- `production/db/password@ops`은 `ops/data/production/db`의 경로로 변환됩니다.
- 인증은 `$VAULT_ID_TOKEN`로 수행됩니다.

GitLab이 Vault에서 시크릿을 가져온 후 값은 임시 파일에 저장됩니다. 이 파일의 경로는 `DATABASE_PASSWORD`이라는 CI/CD 변수에 저장되며, [`file` 타입의 변수](../variables/_index.md#use-file-type-cicd-variables)와 유사합니다.

기본 동작을 덮어쓰려면 `file` 옵션을 명시적으로 설정하세요:

```yaml
secrets:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  DATABASE_PASSWORD:
    vault: production/db/password@ops
    file: false
    token: $VAULT_ID_TOKEN
```

이 예제에서 시크릿 값은 파일을 가리키지 않고 `DATABASE_PASSWORD` 변수에 직접 입력됩니다.

## 시크릿 엔진 {#secrets-engines}

{{< history >}}

- `generic` 옵션은 GitLab 러너 16.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/366492)되었습니다.

{{< /history >}}

GitLab 러너는 [`secrets:engine:name`](../yaml/_index.md#secretsvault) 키워드를 사용하여 다양한 시크릿 엔진을 지원합니다:

| 시크릿 엔진                                                                                                                                     | `secrets:engine:name` 값 | 러너 버전 | 세부 정보 |
|----------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------|----------------|---------|
| [KV 시크릿 엔진 - 버전 2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2)                                                       | `kv-v2`                     | 13.4           | `kv-v2`은 엔진 타입이 명시적으로 지정되지 않았을 때 GitLab 러너가 사용하는 기본 엔진입니다. |
| [KV 시크릿 엔진 - 버전 1](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v1)                                                       | `kv-v1` 또는 `generic`        | 13.4           | `generic` 키워드 지원은 GitLab 15.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/366492)되었습니다. |
| [AWS 시크릿 엔진](https://developer.hashicorp.com/vault/docs/secrets/aws)                                                                       | `generic`                   | 16.11          |         |
| [HashiCorp Vault Artifactory 시크릿 플러그인](https://jfrog.com/help/r/jfrog-integrations-documentation/hashicorp-vault-artifactory-secrets-plugin) | `generic`                   | 16.11          | 이 시크릿 백엔드는 JFrog Artifactory 서버(5.0.0 이상)와 상호작용하고 지정된 범위로 액세스 토큰을 동적으로 프로비저닝합니다. |

### 다른 시크릿 엔진 사용 {#use-a-different-secrets-engine}

`kv-v2` 시크릿 엔진은 기본적으로 사용됩니다. 다른 엔진을 사용하려면 구성의 `vault` 아래에 `engine` 섹션을 추가하세요.

예를 들어 Artifactory의 시크릿 엔진과 경로를 설정하려면:

```yaml
job_using_vault:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    JFROG_TOKEN:
      vault:
        engine:
          name: generic
          path: artifactory
        path: production/jfrog
        field: access_token
      file: false
```

이 예제에서 시크릿 값은 `artifactory/production/jfrog`에서 `access_token` 필드로 획득됩니다.

## 문제 해결 {#troubleshooting}

### 자체 서명 인증서 오류: `certificate signed by unknown authority` {#self-signed-certificate-error-certificate-signed-by-unknown-authority}

Vault 서버가 자체 서명 인증서를 사용 중일 때 작업 로그에서 다음 오류가 표시됩니다:

```plaintext
ERROR: Job failed (system failure): resolving secrets: initializing Vault service: preparing authenticated client: checking Vault server health: Get https://vault.example.com:8000/v1/sys/health?drsecondarycode=299&performancestandbycode=299&sealedcode=299&standbycode=299&uninitcode=299: x509: certificate signed by unknown authority
```

이 오류를 해결하는 데 두 가지 옵션이 있습니다:

- 자체 서명 인증서를 GitLab 러너 서버의 CA 저장소에 추가하세요. [Helm 차트](https://docs.gitlab.com/runner/install/kubernetes/)를 사용하여 GitLab 러너를 배포한 경우 자신의 GitLab 러너 이미지를 생성해야 합니다.
- `VAULT_CACERT` 환경 변수를 사용하여 GitLab 러너가 인증서를 신뢰하도록 구성하세요:
  - systemd를 사용하여 GitLab 러너를 관리하는 경우 [GitLab 러너에 환경 변수를 추가하는 방법](https://docs.gitlab.com/runner/configuration/init/#setting-custom-environment-variables)을 참조하세요.
  - [Helm 차트](https://docs.gitlab.com/runner/install/kubernetes/)를 사용하여 GitLab 러너를 배포한 경우:
    1. [GitLab에 액세스하기 위해 사용자 정의 인증서 제공](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration/#access-gitlab-with-a-custom-certificate)을 수행하고 GitLab의 인증서 대신 Vault 서버의 인증서를 추가해야 합니다. GitLab 인스턴스도 자체 서명 인증서를 사용 중인 경우 동일한 `Secret`에 모두 추가할 수 있어야 합니다.
    1. `values.yaml` 파일에 다음 줄을 추가하세요:

       ```yaml
       ## Replace both the <SECRET_NAME> and the <VAULT_CERTIFICATE>
       ## with the actual values you used to create the secret

       certsSecretName: <SECRET_NAME>

       envVars:
         - name: VAULT_CACERT
           value: "/home/gitlab-runner/.gitlab-runner/certs/<VAULT_CERTIFICATE>"
       ```

[GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit)를 사용하여 로컬에서 개발 모드에서 vault 서버를 실행 중인 경우 이 오류가 발생할 수도 있습니다. 시스템에 Vault 서버의 자체 서명 인증서를 신뢰하도록 수동으로 요청할 수 있습니다. 이 [샘플 튜토리얼](https://iboysoft.com/tips/how-to-trust-a-certificate-on-mac.html)에서 macOS에서 이를 수행하는 방법을 설명합니다.

### `resolving secrets: secret not found: MY_SECRET` 오류 {#resolving-secrets-secret-not-found-my_secret-error}

GitLab이 vault에서 시크릿을 찾을 수 없을 때 다음 오류가 나타날 수 있습니다:

```plaintext
ERROR: Job failed (system failure): resolving secrets: secret not found: MY_SECRET
```

`vault` 값이 [CI/CD 작업에서 올바르게 구성](#use-vault-secrets-in-a-cicd-job)되었는지 확인하세요.

Vault CLI의 [`kv` 명령](https://developer.hashicorp.com/vault/docs/commands/kv)을 사용하여 시크릿을 검색할 수 있는지 확인하고 CI/CD 구성에서 `vault` 값의 구문을 결정하는 데 도움을 줄 수 있습니다. 예를 들어 시크릿을 검색하려면:

```shell
$ vault kv get -field=password -namespace=admin -mount=ops "production/db"
this-is-a-password
```
