---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Vault와 GitLab OpenID Connect를 사용한 인증
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Vault](https://www.vaultproject.io/)는 HashiCorp에서 제공하는 시크릿 관리 애플리케이션입니다. 시크릿 환경 변수, 암호화 키, 인증 토큰 등 민감한 정보를 저장하고 관리할 수 있습니다.

Vault는 ID 기반 액세스를 제공하므로 Vault 사용자는 여러 클라우드 공급자를 통해 인증할 수 있습니다.

다음 내용은 Vault 사용자가 OpenID 인증 기능을 사용하여 GitLab을 통해 인증하는 방법을 설명합니다.

## 전제 조건 {#prerequisites}

1. [Vault 설치](https://developer.hashicorp.com/vault/install).
1. Vault를 실행합니다.

## GitLab에서 OpenID Connect 클라이언트 ID 및 시크릿 가져오기 {#get-the-openid-connect-client-id-and-secret-from-gitlab}

먼저 Vault로 인증하기 위한 애플리케이션 ID 및 시크릿을 얻기 위해 GitLab 애플리케이션을 만들어야 합니다. 이를 위해 GitLab에 로그인하고 다음 단계를 따릅니다:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **액세스** > **응용 프로그램**을 선택합니다.
1. 애플리케이션 **이름** 및 [**Redirect URI**](https://developer.hashicorp.com/vault/docs/auth/jwt#redirect-uris)를 입력합니다.
1. **OpenID** 범위를 선택합니다.
1. **애플리케이션 저장**을 선택합니다.
1. **클라이언트 ID** 및 **Client Secret**을 복사하거나 참조용으로 페이지를 열어 둡니다.

![OAuth 공급자로서의 GitLab](img/gitlab_oauth_vault_v12_6.png)

## Vault에서 OpenID Connect 사용 {#enable-openid-connect-on-vault}

OpenID Connect(OIDC)는 Vault에서 기본적으로 활성화되지 않습니다.

Vault에서 OIDC 인증 공급자를 활성화하려면 터미널 세션을 열고 다음 명령을 실행합니다:

```shell
vault auth enable oidc
```

터미널에서 다음 출력을 확인합니다:

```plaintext
Success! Enabled oidc auth method at: oidc/
```

## OIDC 구성 작성 {#write-the-oidc-configuration}

Vault에 GitLab에서 생성한 애플리케이션 ID 및 시크릿을 제공하고 Vault가 GitLab을 통해 인증하도록 하려면 터미널에서 다음 명령을 실행합니다:

```shell
vault write auth/oidc/config \
  oidc_discovery_url="https://gitlab.com" \
  oidc_client_id="<your_application_id>" \
  oidc_client_secret="<your_secret>" \
  default_role="demo" \
  bound_issuer="localhost"
```

`<your_application_id>` 및 `<your_secret>`를 앱에 대해 생성된 애플리케이션 ID 및 시크릿으로 바꿉니다.

터미널에서 다음 출력을 확인합니다:

```shell
Success! Data written to: auth/oidc/config
```

## OIDC 역할 구성 작성 {#write-the-oidc-role-configuration}

애플리케이션을 만들 때 GitLab에 제공된 [**Redirect URIs**](https://developer.hashicorp.com/vault/docs/auth/jwt#redirect-uris) 및 범위를 Vault에 알려야 합니다.

터미널에서 다음 명령을 실행합니다:

```shell
vault write auth/oidc/role/demo - <<EOF
{
   "user_claim": "sub",
   "allowed_redirect_uris": "<your_vault_instance_redirect_uris>",
   "bound_audiences": "<your_application_id>",
   "oidc_scopes": "<openid>",
   "role_type": "oidc",
   "policies": "demo",
   "ttl": "1h",
   "bound_claims": { "groups": ["<yourGroup/yourSubgrup>"] }
}
EOF
```

바꿀 항목:

- `<your_vault_instance_redirect_uris>`을 Vault 인스턴스가 실행 중인 위치와 일치하는 리다이렉트 URI로 바꿉니다.
- `<your_application_id>`을 앱에 대해 생성된 애플리케이션 ID로 바꿉니다.

`oidc_scopes` 필드에는 `openid`이 포함되어야 합니다.

이 구성은 생성하는 역할의 이름으로 저장됩니다. 이 예는 `demo` 역할을 만듭니다.

> [!warning]
> GitLab.com과 같은 공개 GitLab 인스턴스를 사용하는 경우 `bound_claims`을 지정하여 그룹 또는 프로젝트의 멤버만 액세스할 수 있도록 해야 합니다. 그렇지 않으면 공개 계정이 있는 누구나 Vault 인스턴스에 액세스할 수 있습니다.

## Vault에 로그인 {#sign-in-to-vault}

1. Vault UI로 이동합니다. 예: <http://127.0.0.1:8200/ui/vault/auth?with=oidc>.
1. `OIDC` 메서드를 선택하지 않은 경우 드롭다운 목록을 열고 선택합니다.
1. **Sign in With GitLab**을 선택하면 대화 상자가 열립니다:

   ![GitLab으로 Vault에 로그인](img/sign_into_vault_with_gitlab_v12_6.png)
1. Vault가 GitLab을 통해 로그인하도록 하려면 **권한 부여**를 선택합니다. 이렇게 하면 인증된 사용자로 Vault UI로 다시 리다이렉트됩니다.

   ![GitLab과 연결하기 위해 Vault에 권한 부여](img/authorize_vault_with_gitlab_v12_6.png)

## Vault CLI를 사용하여 로그인(선택 사항) {#sign-in-using-the-vault-cli-optional}

[Vault CLI](https://developer.hashicorp.com/vault/docs/commands)를 사용하여 Vault에 로그인할 수도 있습니다.

1. 이전 예에서 만든 역할 구성으로 로그인하려면 터미널에서 다음 명령을 실행합니다:

   ```shell
   vault login -method=oidc port=8250 role=demo
   ```

   이 명령은 다음을 설정합니다:

   - `role=demo`은 Vault가 어떤 구성으로 로그인하고 싶은지 알 수 있도록 합니다.
   - `-method=oidc`을 설정하면 Vault가 `OIDC` 로그인 메서드를 사용하도록 합니다.
   - `port=8250`을 설정하면 GitLab이 리다이렉트할 포트입니다. 이 포트 번호는 [리다이렉트 URI](https://developer.hashicorp.com/vault/docs/auth/jwt#redirect-uris)를 나열할 때 GitLab에 지정된 포트와 일치해야 합니다.

   이 명령을 실행한 후 터미널에 링크가 표시됩니다.
1. 웹 브라우저에서 이 링크를 엽니다:

   ![OIDC를 통해 Vault에 로그인함](img/signed_into_vault_via_oidc_v12_6.png)

   터미널에서 다음을 확인합니다:

   ```plaintext
   Success! You are now authenticated. The token information displayed below
   is already stored in the token helper. You do NOT need to run "vault login"
   again. Future Vault requests will automatically use this token.
   ```
