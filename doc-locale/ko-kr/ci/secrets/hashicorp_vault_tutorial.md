---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: '튜토리얼: HashiCorp Vault로 인증하고 비밀 읽기'
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

이 튜토리얼에서는 GitLab CI/CD에서 HashiCorp의 Vault로 인증하고, 구성하고, 비밀을 읽는 방법을 보여줍니다.

## 전제 조건 {#prerequisites}

이 튜토리얼은 사용자가 GitLab CI/CD와 Vault에 익숙하다고 가정합니다.

계속 진행하려면 다음이 필요합니다:

- GitLab의 계정
- 실행 중인 Vault 서버(최소 v1.2.0)에 대한 액세스로 인증을 구성하고 역할 및 정책을 생성합니다. HashiCorp Vault의 경우 오픈 소스 또는 엔터프라이즈 버전일 수 있습니다.

> [!note]
> `vault.example.com` URL을 Vault 서버의 URL로 바꾸고 `gitlab.example.com`을(를) GitLab 인스턴스의 URL로 바꿔야 합니다.

## Vault 구성 {#configure-the-vault}

> [!warning]
> JWT는 자격 증명이며 리소스에 대한 액세스를 부여할 수 있습니다. 이를 붙여넣는 위치에 주의하세요!

Vault 서버에 스테이징 및 프로덕션 데이터베이스의 비밀번호를 저장하는 시나리오를 생각해봅시다. 이 시나리오는 [KV v2](https://developer.hashicorp.com/vault/docs/secrets/kv#kv-version-2) 비밀 엔진을 사용한다고 가정합니다. [KV v1](https://developer.hashicorp.com/vault/docs/secrets/kv#version-comparison)을(를) 사용 중이면 다음 정책 경로에서 `/data/`을(를) 제거하고 [CI/CD 작업을 구성하는 방법](convert-to-id-tokens.md#kv-secrets-engine-v1)을 참조하세요.

`vault kv get` 명령으로 비밀번호를 검색할 수 있습니다.

```shell
$ vault kv get -field=password secret/myproject/staging/db
pa$$w0rd

$ vault kv get -field=password secret/myproject/production/db
real-pa$$w0rd
```

스테이징 비밀번호는 `pa$$w0rd`이고 프로덕션 비밀번호는 `real-pa$$w0rd`입니다.

Vault 서버를 구성하려면 [JWT Auth](https://developer.hashicorp.com/vault/docs/auth/jwt) 방법을 활성화하여 시작합니다:

```shell
$ vault auth enable jwt
Success! Enabled jwt auth method at: jwt/
```

그런 다음 이러한 비밀을 읽을 수 있는 정책을 만듭니다(각 비밀마다 하나씩):

```shell
$ vault policy write myproject-staging - <<EOF
# Policy name: myproject-staging
#
# Read-only permission on 'secret/data/myproject/staging/*' path
path "secret/data/myproject/staging/*" {
  capabilities = [ "read" ]
}
EOF
Success! Uploaded policy: myproject-staging

$ vault policy write myproject-production - <<EOF
# Policy name: myproject-production
#
# Read-only permission on 'secret/data/myproject/production/*' path
path "secret/data/myproject/production/*" {
  capabilities = [ "read" ]
}
EOF
Success! Uploaded policy: myproject-production
```

또한 JWT를 이러한 정책에 연결하는 역할이 필요합니다.

예를 들어 `myproject-staging`이라는 스테이징용 역할입니다. [bound claims](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims)는 `main` 브랜치에서만 ID가 `22`인 프로젝트에 사용할 정책을 허용하도록 구성됩니다:

```json
$ vault write auth/jwt/role/myproject-staging - <<EOF
{
  "role_type": "jwt",
  "policies": ["myproject-staging"],
  "token_explicit_max_ttl": 60,
  "user_claim": "user_email",
  "bound_audiences": "https://vault.example.com",
  "bound_claims": {
    "project_id": "22",
    "ref": "main",
    "ref_type": "branch"
  }
}
EOF
```

그리고 `myproject-production`이라는 프로덕션용 역할입니다. 이 역할의 `bound_claims` 섹션은 `auto-deploy-*` 패턴과 일치하는 보호된 브랜치만 비밀에 액세스하도록 허용합니다.

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
    "project_id": "22",
    "ref_protected": "true",
    "ref_type": "branch",
    "ref": "auto-deploy-*"
  }
}
EOF
```

[보호된 브랜치](../../user/project/repository/branches/protected.md)와 함께 누가 인증하고 비밀을 읽을 수 있는지 제한할 수 있습니다.

[JWT에 포함된](id_token_authentication.md#token-payload) 모든 클레임을 bound claims의 값 목록과 비교할 수 있습니다. 예를 들어:

```json
"bound_claims": {
  "user_login": ["alice", "bob", "mallory"]
}

"bound_claims": {
  "ref": ["main", "develop", "test"]
}

"bound_claims": {
  "namespace_id": ["10", "20", "30"]
}

"bound_claims": {
  "project_id": ["12", "22", "37"]
}
```

- `namespace_id`만 사용되는 경우 네임스페이스의 모든 프로젝트가 허용됩니다. 중첩된 프로젝트는 포함되지 않으므로 필요한 경우 해당 네임스페이스 ID도 목록에 추가해야 합니다.
- `namespace_id`과(와) `project_id`을(를) 모두 사용하는 경우 Vault는 먼저 프로젝트의 네임스페이스가 `namespace_id`에 있는지 확인한 다음 프로젝트가 `project_id`에 있는지 확인합니다.

[`token_explicit_max_ttl`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#token_explicit_max_ttl)는 성공적인 인증 시 Vault에서 발급한 토큰이 60초의 하드 수명 제한을 가지도록 지정합니다.

[`user_claim`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#user_claim)는 성공적인 로그인 시 Vault에서 생성한 Identity alias의 이름을 지정합니다.

[`bound_claims_type`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_claims_type)는 `bound_claims` 값의 해석을 구성합니다. `glob`로 설정하면 값은 glob으로 해석되며 `*`는 임의의 문자 수와 일치합니다.

[클레임 필드](id_token_authentication.md#token-payload)는 [Vault의 정책 경로 템플릿 지정](https://developer.hashicorp.com/vault/tutorials/policies/policy-templating?in=vault%2Fpolicies) 목적으로 Vault의 JWT 인증 접근자 이름을 사용하여 액세스할 수도 있습니다. [mount accessor name](https://developer.hashicorp.com/vault/tutorials/auth-methods/identity#step-1-create-an-entity-with-alias)(`ACCESSOR_NAME`(다음 예제에서))는 `vault auth list`를 실행하여 검색할 수 있습니다.

`project_path`이라는 명명된 메타데이터 필드를 사용하는 정책 템플릿 예시:

```plaintext
path "secret/data/{{identity.entity.aliases.ACCESSOR_NAME.metadata.project_path}}/staging/*" {
  capabilities = [ "read" ]
}
```

이전 템플릿 정책을 지원하고 [`claim_mappings`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#claim_mappings) 구성을 사용하여 클레임 필드 `project_path`을(를) 메타데이터 필드로 매핑하는 역할 예시:

```json
{
  "role_type": "jwt",
  ...
  "claim_mappings": {
    "project_path": "project_path"
  }
}
```

전체 옵션 목록은 Vault의 [역할 생성 설명서](https://developer.hashicorp.com/vault/api-docs/auth/jwt#create-role)를 참조하세요.

> [!warning]
> 항상 제공된 클레임(예: `project_id` 또는 `namespace_id`)을(를) 사용하여 역할을 프로젝트 또는 네임스페이스로 제한합니다. 그렇지 않으면 이 인스턴스에서 생성된 모든 JWT가 이 역할을 사용하여 인증하도록 허용될 수 있습니다.

이제 JWT 인증 방법을 구성합니다:

```shell
$ vault write auth/jwt/config \
    oidc_discovery_url="https://gitlab.example.com" \
    bound_issuer="https://gitlab.example.com"
```

[`bound_issuer`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#bound_issuer)는 `iss` 클레임이 `gitlab.example.com`로 설정된 JWT만 이 방법을 사용하여 인증할 수 있으며 `oidc_discovery_url`(`https://gitlab.example.com`)을(를) 토큰 검증에 사용해야 함을 지정합니다.

전체 사용 가능한 구성 옵션 목록은 Vault의 [API 설명서](https://developer.hashicorp.com/vault/api-docs/auth/jwt#configure)를 참조하세요.

GitLab에서 Vault 서버에 대한 세부 정보를 제공하려면 다음 [CI/CD 변수](../variables/_index.md#for-a-project)를 만듭니다:

- `VAULT_SERVER_URL`: Vault 서버의 URL입니다(예: `https://vault.example.com:8200`).
- `VAULT_AUTH_ROLE`: 선택 사항. 인증을 시도할 때 사용할 Vault JWT Auth 역할의 이름입니다. 이 튜토리얼에서는 `myproject-staging` 및 `myproject-production`이라는 이름의 두 가지 역할을 이미 만들었습니다. 역할을 지정하지 않으면 Vault는 인증 방법이 구성되었을 때 지정된 [기본 역할](https://developer.hashicorp.com/vault/api-docs/auth/jwt#default_role)을 사용합니다.
- `VAULT_AUTH_PATH`: 선택 사항. 인증 방법이 마운트된 경로입니다. 기본값은 `jwt`입니다.
- `VAULT_NAMESPACE`: 선택 사항. 비밀을 읽고 인증하는 데 사용할 [Vault Enterprise 네임스페이스](https://developer.hashicorp.com/vault/docs/enterprise/namespaces)입니다. 네임스페이스가 지정되지 않으면 Vault는 root(`/`) 네임스페이스를 사용합니다. 이 설정은 Vault Open Source에서 무시됩니다.

## 자동 ID 토큰 인증 {#automatic-id-token-authentication}

다음 작업은 기본 브랜치에서 실행할 때 `secret/myproject/staging/` 아래의 비밀을 읽을 수 있지만 `secret/myproject/production/` 아래의 비밀은 읽을 수 없습니다:

```yaml
job_with_secrets:
  id_tokens:
    VAULT_ID_TOKEN:
      aud: https://vault.example.com
  secrets:
    STAGING_DB_PASSWORD:
      vault: myproject/staging/db/password@secret  # translates to a path of 'secret/myproject/staging/db' and field 'password'. Authenticates using $VAULT_ID_TOKEN.
  script:
    - access-staging-db.sh --token $STAGING_DB_PASSWORD
```

이 예에서:

- `id_tokens` - OIDC 인증에 사용되는 JSON Web Token(JWT)입니다. `aud` 클레임은 Vault JWT 인증 방법에 사용되는 `role`의 `bound_audiences` 파라미터와 일치하도록 설정됩니다.
- `@secret` - Secrets Engines이 활성화된 Vault 이름입니다.
- `myproject/staging/db` - Vault의 비밀 경로 위치입니다.
- `password` 참조된 비밀에서 가져올 필드입니다.

ID 토큰을 두 개 이상 정의하면 `token` 키워드를 사용하여 사용할 토큰을 지정합니다. 예를 들어:

```yaml
job_with_secrets:
  id_tokens:
    FIRST_ID_TOKEN:
      aud: https://first.service.com
    SECOND_ID_TOKEN:
      aud: https://second.service.com
  secrets:
    FIRST_DB_PASSWORD:
      vault: first/db/password
      token: $FIRST_ID_TOKEN
    SECOND_DB_PASSWORD:
      vault: second/db/password
      token: $SECOND_ID_TOKEN
  script:
    - access-first-db.sh --token $FIRST_DB_PASSWORD
    - access-second-db.sh --token $SECOND_DB_PASSWORD
```

> [!note]
> Vault 1.17부터 [JWT 인증 로그인에는 역할에 대한 바운드 audiences가 필요합니다](https://developer.hashicorp.com/vault/docs/upgrading/upgrade-to-1.17.x#jwt-auth-login-requires-bound-audiences-on-the-role) JWT에 `aud` claim이 포함된 경우입니다. `aud` claim은 단일 문자열 또는 문자열 목록이 될 수 있습니다.

### 수동 인증 {#manual-authentication}

ID 토큰을 사용하여 HashiCorp Vault로 수동으로 인증할 수 있습니다. 예를 들어:

```yaml
manual_authentication:
  variables:
    VAULT_ADDR: http://vault.example.com:8200
  image: vault:latest
  id_tokens:
    VAULT_ID_TOKEN:
      aud: http://vault.example.com
  script:
    - export VAULT_TOKEN="$(vault write -field=token auth/jwt/login role=myproject-example jwt=$VAULT_ID_TOKEN)"
    - export PASSWORD="$(vault kv get -field=password secret/myproject/example/db)"
    - my-authentication-script.sh $VAULT_TOKEN $PASSWORD
```

## Vault 비밀에 대한 토큰 액세스 제한 {#limit-token-access-to-vault-secrets}

Vault 보호 및 GitLab 기능을 사용하여 Vault 비밀에 대한 ID 토큰 액세스를 제어할 수 있습니다. 예를 들어 다음과 같이 토큰을 제한합니다:

- 특정 ID 토큰 `aud` 클레임에 대해 Vault [bound audiences](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-audiences)를 사용합니다.
- `group_claim`를 사용하여 특정 그룹에 대해 Vault [bound claims](https://developer.hashicorp.com/vault/docs/auth/jwt#bound-claims)를 사용합니다.
- 특정 사용자의 `user_login` 및 `user_email`을(를) 기반으로 Vault bound claims에 대한 값을 하드코딩합니다.
- [`token_explicit_max_ttl`](https://developer.hashicorp.com/vault/api-docs/auth/jwt#token_explicit_max_ttl)에 지정된 대로 토큰의 TTL에 대한 Vault 시간 제한을 설정하며, 여기서 토큰은 인증 후 만료됩니다.
- JWT를 프로젝트 사용자의 하위 집합으로 제한되는 [GitLab 보호된 브랜치](../../user/project/repository/branches/protected.md)로 지정합니다.
- JWT를 프로젝트 사용자의 하위 집합으로 제한되는 [GitLab 보호된 태그](../../user/project/protected_tags.md)로 지정합니다.

## 문제 해결 {#troubleshooting}

### `The secrets provider can not be found. Check your CI/CD variables and try again.` 메시지 {#the-secrets-provider-can-not-be-found-check-your-cicd-variables-and-try-again-message}

HashiCorp Vault에 액세스하도록 구성된 작업을 시작하려고 할 때 이 오류가 발생할 수 있습니다:

```plaintext
The secrets provider can not be found. Check your CI/CD variables and try again.
```

필수 변수가 정의되지 않아 작업을 만들 수 없습니다:

- `VAULT_SERVER_URL`

### `api error: status code 400: missing role` 오류 {#api-error-status-code-400-missing-role-error}

HashiCorp Vault에 액세스하도록 구성된 작업을 시작하려고 할 때 `missing role` 오류가 발생할 수 있습니다. `VAULT_AUTH_ROLE` 변수가 정의되지 않아 작업이 Vault 서버로 인증할 수 없기 때문일 수 있습니다.

### `audience claim does not match any expected audience` 오류 {#audience-claim-does-not-match-any-expected-audience-error}

YAML 파일에 지정된 ID 토큰의 `aud:` 클레임 값과 JWT 인증에 사용되는 `role`의 `bound_audiences` 파라미터 값이 일치하지 않으면 이 오류가 발생할 수 있습니다:

`invalid audience (aud) claim: audience claim does not match any expected audience`

이 값들이 동일한지 확인하세요.
