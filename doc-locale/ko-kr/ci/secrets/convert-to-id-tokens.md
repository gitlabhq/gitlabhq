---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 사용 중단된 ‘CI_JOB_JWT’ 변수에서 ID 토큰으로 변환하는 방법을 알아봅니다
title: '튜토리얼: ID 토큰을 사용하도록 HashiCorp Vault 구성 업데이트'
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> Vault 1.17부터 [JWT 인증 로그인에는 역할에 대한 바운드 audiences가 필요합니다](https://developer.hashicorp.com/vault/docs/upgrading/upgrade-to-1.17.x#jwt-auth-login-requires-bound-audiences-on-the-role) JWT에 `aud` claim이 포함된 경우입니다. `aud` claim은 단일 문자열 또는 문자열 목록이 될 수 있습니다.

이 튜토리얼은 기존 CI/CD 비밀 구성을 [ID 토큰](id_token_authentication.md)을 사용하도록 변환하는 방법을 보여줍니다.

`CI_JOB_JWT` 변수는 deprecated되었지만, ID 토큰으로 업데이트하려면 Vault에서 작동하기 위한 중요한 구성 변경이 필요합니다. 작업이 많으면 모든 것을 한 번에 변환하는 것은 힘든 작업입니다.

[ID 토큰](id_token_authentication.md)으로 마이그레이션하는 표준 방법은 없으므로, 이 튜토리얼은 기존 CI/CD 비밀을 변환하는 방법에 대한 두 가지 변형을 포함합니다. 사용 사례에 가장 적합한 방법을 선택하세요:

1. Vault 구성을 업데이트하세요:
   - 방법 A: JWT 역할을 새로운 Vault 인증 방법으로 마이그레이션
     1. [Vault에서 두 번째 JWT 인증 경로 생성](#create-a-second-jwt-authentication-path-in-vault)
     1. [새로운 인증 경로를 사용하도록 역할 재생성](#recreate-roles-to-use-the-new-authentication-path)
   - 방법 B: `iss` claim을 마이그레이션 기간 동안 역할로 이동
     1. [`bound_issuers` claim 맵을 각 역할에 추가](#add-bound_issuers-claim-map-to-each-role)
     1. [`bound_issuers` claim을 인증 방법에서 제거](#remove-bound_issuers-claim-from-auth-method)
1. [CI/CD 작업 업데이트](#update-your-cicd-jobs)

## 전제 조건 {#prerequisites}

이 튜토리얼은 사용자가 GitLab CI/CD와 Vault에 익숙하다고 가정합니다.

계속 진행하려면 다음이 필요합니다:

- GitLab 16.0 이상을 실행하는 인스턴스 또는 GitLab.com 상태입니다.
- 이미 사용 중인 Vault 서버입니다.
- `CI_JOB_JWT`을 사용하여 Vault에서 비밀을 검색하는 CI/CD 작업입니다.

다음 예제에서 다음을 바꾸세요:

- `vault.example.com`을 Vault 서버의 URL로 바꾸세요.
- `gitlab.example.com`을 GitLab 인스턴스의 URL로 바꾸세요.
- `jwt` 또는 `jwt_v2`을 인증 방법 이름으로 바꾸세요.

## 방법 A: JWT 역할을 새로운 Vault 인증 방법으로 마이그레이션 {#method-a-migrate-jwt-roles-to-the-new-vault-auth-method}

이 방법은 기존 JWT 인증 방법과 병렬로 두 번째 JWT 인증 방법을 생성합니다. 그 후에 GitLab 통합에 사용되는 모든 Vault 역할이 이 새로운 인증 방법에서 재생성됩니다.

### Vault에서 두 번째 JWT 인증 경로 생성 {#create-a-second-jwt-authentication-path-in-vault}

`CI_JOB_JWT`에서 ID 토큰으로의 전환의 일부로, Vault에서 `bound_issuer`을 `https://`를 포함하도록 업데이트해야 합니다:

```shell
$ vault write auth/jwt/config \
    oidc_discovery_url="https://gitlab.example.com" \
    bound_issuer="https://gitlab.example.com"
```

이 변경을 수행한 후, `CI_JOB_JWT`을 사용하는 작업이 실패하기 시작합니다.

Vault에서 여러 인증 경로를 생성할 수 있으므로, 중단 없이 프로젝트별로 작업 기반으로 ID 토큰으로 전환할 수 있습니다.

1. `jwt_v2` 이름의 새로운 인증 경로를 구성합니다. 실행:

   ```shell
   vault auth enable -path jwt_v2 jwt
   ```

   다른 이름을 선택할 수 있지만, 이 예제의 나머지는 `jwt_v2`을 사용했다고 가정하므로 필요에 따라 예제를 업데이트하세요.

1. 인스턴스의 새로운 인증 경로를 구성하세요:

   ```shell
   $ vault write auth/jwt_v2/config \
       oidc_discovery_url="https://gitlab.example.com" \
       bound_issuer="https://gitlab.example.com"
   ```

### 새로운 인증 경로를 사용하도록 역할 재생성 {#recreate-roles-to-use-the-new-authentication-path}

역할은 특정 인증 경로에 바인딩되므로 각 작업에 대해 새로운 역할을 추가해야 합니다. JWT에 audience가 포함된 경우 역할에 대한 `bound_audiences` 매개변수는 필수이며 JWT의 관련 `aud` claims 중 최소 하나와 일치해야 합니다.

1. `myproject-staging` 이름의 스테이징에 대한 역할을 재생성합니다:

   ```shell
   $ vault write auth/jwt_v2/role/myproject-staging - <<EOF
   {
     "role_type": "jwt",
     "policies": ["myproject-staging"],
     "token_explicit_max_ttl": 60,
     "user_claim": "user_email",
     "bound_audiences": ["https://vault.example.com"],
     "bound_claims": {
       "project_id": "22",
       "ref": "master",
       "ref_type": "branch"
     }
   }
   EOF
   ```

1. `myproject-production` 이름의 프로덕션에 대한 역할을 재생성합니다:

   ```shell
   $ vault write auth/jwt_v2/role/myproject-production - <<EOF
   {
     "role_type": "jwt",
     "policies": ["myproject-production"],
     "token_explicit_max_ttl": 60,
     "user_claim": "user_email",
     "bound_audiences": ["https://vault.example.com"],
     "bound_claims_type": "glob",
     "bound_claims": {
       "project_id": "22",
       "ref_protected": "true",
       "ref_type": "branch",
       "ref": "auto-deploy-*"
     }
   }
   EOF
   ```

`vault` 명령에서 `jwt`을 `jwt_v2`로 업데이트하기만 하면 되며, 역할 내의 `role_type`은 변경하지 마세요.

## 방법 B: `iss` claim을 마이그레이션 기간 동안 역할로 이동 {#method-b-move-iss-claim-to-roles-for-migration-window}

이 방법은 Vault 관리자가 두 번째 JWT 인증 방법을 생성하고 모든 GitLab 관련 역할을 재생성하도록 요구하지 않습니다.

### `bound_issuers` claim 맵을 각 역할에 추가 {#add-bound_issuers-claim-map-to-each-role}

Vault는 JWT 인증 방법 수준에서 여러 `iss` claims를 허용하지 않습니다. 이 수준의 [`bound_issuer`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_issuer) 지시문은 단일 값만 허용하기 때문입니다. 그러나 [`bound_claims`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims) 맵 구성 지시문을 사용하여 역할 수준에서 여러 claims를 구성할 수 있습니다.

이 방법을 사용하면 Vault에 `iss` claim 검증을 위한 여러 옵션을 제공할 수 있습니다. 이는 `id_tokens`과 함께 제공되는 `https://` 접두사가 있는 GitLab 인스턴스 hostname claim을 지원하고, 이전의 접두사가 없는 claim도 지원합니다.

[`bound_claims`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims) 구성을 필요한 역할에 추가하려면 다음을 실행하세요:

```shell
$ vault write auth/jwt/role/myproject-staging - <<EOF
{
  "role_type": "jwt",
  "policies": ["myproject-staging"],
  "token_explicit_max_ttl": 60,
  "user_claim": "user_email",
  "bound_audiences": ["https://vault.example.com"],
  "bound_claims": {
    "iss": [
      "https://gitlab.example.com",
      "gitlab.example.com"
    ],
    "project_id": "22",
    "ref": "master",
    "ref_type": "branch"
  }
}
EOF
```

`bound_claims` 섹션을 제외한 기존 역할 구성을 변경할 필요가 없습니다. 이전에 표시된 대로 `iss` 구성을 추가하여 Vault가 이 역할에 대해 접두사가 있는 및 없는 `iss` claim을 허용하도록 하세요.

다음 단계로 진행하기 전에 GitLab 통합에 사용되는 모든 JWT 역할에 이 변경을 적용해야 합니다.

모든 프로젝트가 마이그레이션되었으며 더 이상 `CI_JOB_JWT` 및 ID 토큰에 대한 병렬 지원이 필요하지 않은 후에는 원하는 경우 `iss` claim 검증을 인증 방법에서 역할로 되돌릴 수 있습니다.

### `bound_issuers` claim을 인증 방법에서 제거 {#remove-bound_issuers-claim-from-auth-method}

모든 역할이 `bound_claims.iss` claims로 업데이트되었으면, 이 검증을 위해 인증 방법 수준 구성을 제거할 수 있습니다:

```shell
$ vault write auth/jwt/config \
    oidc_discovery_url="https://gitlab.example.com" \
    bound_issuer=""
```

`bound_issuer` 지시문을 빈 문자열로 설정하면 인증 방법 수준에서 issuer 검증이 제거됩니다. 그러나 이 검증은 이제 역할 수준에 있기 때문에 구성은 여전히 안전합니다.

## CI/CD 작업 업데이트 {#update-your-cicd-jobs}

Vault는 두 가지 다른 [KV Secrets Engines](https://developer.hashicorp.com/vault/docs/secrets/kv)을 가지고 있으며, 사용 중인 버전은 CI/CD에서 비밀을 정의하는 방법에 영향을 미칩니다.

HashiCorp의 지원 포털에서 [내 Vault KV Mount 버전은 무엇입니까?](https://support.hashicorp.com/hc/en-us/articles/4404288741139-Which-Version-is-my-Vault-KV-Mount) 문서를 확인하여 Vault 서버를 확인하세요.

또한 필요한 경우 CI/CD 설명서를 검토할 수 있습니다:

- [`secrets:`](../yaml/_index.md#secrets)
- [`id_tokens:`](../yaml/_index.md#id_tokens)

다음 예제는 `secret/myproject/staging/db`의 `password` 필드에 기록된 스테이징 데이터베이스 암호를 얻는 방법을 보여줍니다.

`VAULT_AUTH_PATH` 변수의 값은 사용한 마이그레이션 방법에 따라 다릅니다:

- 방법 A (JWT 역할을 새로운 Vault 인증 방법으로 마이그레이션): `jwt_v2`을 사용하세요.
- 방법 B (`iss` claim을 마이그레이션 기간 동안 역할로 이동): `jwt`을 사용하세요.

### KV Secrets Engine v1 {#kv-secrets-engine-v1}

[`secrets:vault`](../yaml/_index.md#secretsvault) 키워드는 KV Mount의 v2를 기본값으로 하므로, v1 엔진을 사용하도록 작업을 명시적으로 구성해야 합니다:

```yaml
job:
  variables:
    VAULT_SERVER_URL: https://vault.example.com
    VAULT_AUTH_PATH: jwt_v2  # or "jwt" if you used method B
    VAULT_AUTH_ROLE: myproject-staging
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    PASSWORD:
      vault:
        engine:
          name: kv-v1
          path: secret
        field: password
        path: myproject/staging/db
      file: false
```

`VAULT_SERVER_URL` 및 `VAULT_AUTH_PATH`은 모두 선호하는 경우 [프로젝트 또는 그룹 CI/CD 변수로 정의](../variables/_index.md#define-a-cicd-variable-in-the-ui)할 수 있습니다.

[`secrets:file`](../yaml/_index.md#secretsfile)은 `false`로 설정되어 있습니다. ID 토큰은 기본적으로 비밀을 파일에 배치하기 때문에 이전 동작과 일치하도록 일반 변수로 작동해야 합니다.

### KV Secrets Engine v2 {#kv-secrets-engine-v2}

v2 엔진에 사용할 수 있는 두 가지 형식이 있습니다.

긴 형식:

```yaml
job:
  variables:
    VAULT_SERVER_URL: https://vault.example.com
    VAULT_AUTH_PATH: jwt_v2  # or "jwt" if you used method B
    VAULT_AUTH_ROLE: myproject-staging
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    PASSWORD:
      vault:
        engine:
          name: kv-v2
          path: secret
        field: password
        path: myproject/staging/db
      file: false
```

이는 v1 엔진의 예제와 동일하지만 `secrets:vault:engine:name:`은 엔진과 일치하도록 `kv-v2`로 설정됩니다.

짧은 형식을 사용할 수도 있습니다:

```yaml
job:
  variables:
    VAULT_SERVER_URL: https://vault.example.com
    VAULT_AUTH_PATH: jwt_v2  # or "jwt" if you used method B
    VAULT_AUTH_ROLE: myproject-staging
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
      PASSWORD:
        vault: myproject/staging/db/password@secret
        file: false
```

업데이트된 CI/CD 구성을 커밋한 후, 작업이 ID 토큰으로 비밀을 가져올 것입니다. 축하합니다!

모든 프로젝트를 ID 토큰으로 비밀을 가져오도록 마이그레이션했으며 마이그레이션에 방법 B를 사용한 경우, 원하면 `iss` claim 검증을 인증 방법 구성으로 다시 이동할 수 있습니다.
