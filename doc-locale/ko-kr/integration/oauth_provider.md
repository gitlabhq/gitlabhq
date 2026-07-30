---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab을 OAuth 2.0 인증 ID 제공자로 구성하기
---

{{< history >}}

- OAuth 애플리케이션을 위한 그룹 SAML SSO 지원이 GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/461212)되었으며 [기능 플래그](../administration/feature_flags/_index.md) `ff_oauth_redirect_to_sso_login`로 명명되었습니다. 기본적으로 비활성화되었습니다.
- OAuth 애플리케이션을 위한 그룹 SAML SSO 지원이 [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/200682)되었습니다(GitLab 18.3).
- GitLab 18.5에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/561778)합니다. `ff_oauth_redirect_to_sso_login` 기능 플래그가 제거되었습니다.

{{< /history >}}

[OAuth 2.0](https://oauth.net/2/)은 리소스 소유자를 대신하여 클라이언트 애플리케이션에 안전하게 위임된 서버 리소스 액세스를 제공합니다. OAuth 2는 권한 부여 서버가 리소스 소유자 또는 최종 사용자의 승인으로 써드파티 클라이언트에 액세스 토큰을 발급할 수 있습니다.

GitLab을 OAuth 2 인증 ID 제공자로 사용하려면 다음 유형의 OAuth 2 애플리케이션을 인스턴스에 추가하세요:

- [사용자 소유 애플리케이션](#create-a-user-owned-application).
- [그룹 소유 애플리케이션](#create-a-group-owned-application).
- [인스턴스 전체 애플리케이션](#create-an-instance-wide-application).

이러한 방법은 [권한 수준](../user/permissions.md)에만 다릅니다. 기본 콜백 URL은 SSL URL `https://your-gitlab.example.com/users/auth/gitlab/callback`입니다. 비SSL URL을 대신 사용할 수 있지만 SSL URL을 사용해야 합니다.

OAuth 2 애플리케이션을 인스턴스에 추가한 후 OAuth 2를 사용하여:

- 사용자가 GitLab.com 계정으로 애플리케이션에 로그인할 수 있습니다.
- SAML이 연결된 그룹에 대해 구성되었을 때 사용자가 [SAML SSO](../user/group/saml_sso/_index.md)를 사용하여 애플리케이션에 로그인할 수 있습니다.
- GitLab.com을 GitLab 인스턴스에 인증하도록 설정합니다. 자세한 내용은 [GitLab.com과 서버 통합](gitlab.md)을 참조하세요.
- 애플리케이션이 생성된 후 외부 서비스는 [OAuth 2 API](../api/oauth2.md)를 사용하여 액세스 토큰을 관리할 수 있습니다.

## 사용자 소유 애플리케이션 생성 {#create-a-user-owned-application}

사용자 소유 애플리케이션을 만들려면:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **액세스** > **응용 프로그램**을 선택합니다.
1. **새 애플리케이션 추가**를 선택하세요.
1. **이름** 및 **Redirect URI**를 입력하세요.
1. **범위** OAuth 2를 선택하고 [승인된 애플리케이션](#view-all-authorized-applications)에서 정의한 대로 선택합니다.
1. **Redirect URI**에 사용자가 GitLab으로 인증한 후 전송되는 URL을 입력하세요.
1. **애플리케이션 저장**을 선택합니다. GitLab이 제공합니다:

   - **애플리케이션 ID** 필드의 OAuth 2 클라이언트 ID.
   - OAuth 2 클라이언트 비밀은 **복사**를 선택하여 **비밀** 필드에서 액세스할 수 있습니다.
   - **비밀 갱신** 기능입니다. 이 기능을 사용하여 이 애플리케이션에 대한 새로운 비밀을 생성하고 복사하세요. 비밀을 갱신하면 자격 증명이 업데이트될 때까지 기존 애플리케이션이 작동하지 않습니다.

## 그룹 소유 애플리케이션 생성 {#create-a-group-owned-application}

그룹 소유 애플리케이션을 만들려면:

1. 원하는 그룹으로 이동합니다.
1. 왼쪽 사이드바에서 **설정** > **응용 프로그램**을 선택하세요.
1. **이름** 및 **Redirect URI**를 입력하세요.
1. OAuth 2 범위를 선택하고 [승인된 애플리케이션](#view-all-authorized-applications)에서 정의한 대로 선택합니다.
1. **Redirect URI**에 사용자가 GitLab으로 인증한 후 전송되는 URL을 입력하세요.
1. **애플리케이션 저장**을 선택합니다. GitLab이 제공합니다:

   - **애플리케이션 ID** 필드의 OAuth 2 클라이언트 ID.
   - OAuth 2 클라이언트 비밀은 **복사**를 선택하여 **비밀** 필드에서 액세스할 수 있습니다.
   - **비밀 갱신** 기능입니다. 이 기능을 사용하여 이 애플리케이션에 대한 새로운 비밀을 생성하고 복사하세요. 비밀을 갱신하면 자격 증명이 업데이트될 때까지 기존 애플리케이션이 작동하지 않습니다.

## 인스턴스 전체 애플리케이션 생성 {#create-an-instance-wide-application}

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

GitLab 인스턴스를 위한 애플리케이션을 만들려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **응용 프로그램**을 선택하세요.
1. **새 어플리케이션**을 선택하세요.

**운영자** 영역에서 애플리케이션을 만들 때 **trusted** 것으로 표시합니다. 사용자 권한 부여 단계가 이 애플리케이션에 대해 자동으로 건너뜁니다.

## 승인된 모든 애플리케이션 보기 {#view-all-authorized-applications}

{{< history >}}

- `k8s_proxy`이 GitLab 16.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/422408)되었으며 [기능 플래그](../administration/feature_flags/_index.md) `k8s_proxy_pat`로 명명되었습니다. 기본적으로 활성화되었습니다.
- 기능 플래그 `k8s_proxy_pat`이 GitLab 16.5에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131518)되었습니다.

{{< /history >}}

GitLab 자격 증명으로 승인한 모든 애플리케이션을 보려면:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **액세스** > **응용 프로그램**을 선택합니다.
1. **승인된 애플리케이션** 섹션을 확인하세요.

GitLab OAuth 2 애플리케이션은 범위를 지원하여 애플리케이션이 다양한 작업을 수행할 수 있도록 합니다. 사용 가능한 모든 범위는 다음 표를 참조하세요.

| 범위                    | 설명 |
|--------------------------|-------------|
| `api`                    | API에 대한 전체 읽기/쓰기 액세스를 부여하며 모든 그룹과 프로젝트, 컨테이너 레지스트리, 종속성 프록시 및 패키지 레지스트리를 포함합니다. |
| `read_api`               | API에 대한 읽기 액세스를 부여하며 모든 그룹과 프로젝트, 컨테이너 레지스트리 및 패키지 레지스트리를 포함합니다. |
| `read_user`              | `/user` API 끝점을 통해 인증된 사용자의 프로필에 대한 읽기 전용 액세스를 부여합니다. 여기에는 사용자 이름, 공개 이메일 및 전체 이름이 포함됩니다. 또한 `/users` 아래의 읽기 전용 API 끝점에 대한 액세스를 부여합니다. |
| `create_runner`          | 러너에 대한 생성 액세스를 부여합니다. |
| `manage_runner`          | 러너를 관리할 수 있는 액세스를 부여합니다. |
| `k8s_proxy`              | Kubernetes용 에이전트를 사용하여 Kubernetes API 호출을 수행할 수 있는 권한을 부여합니다. |
| `read_repository`        | Git-over-HTTP 또는 리포지토리 파일 API를 사용하여 비공개 프로젝트의 리포지토리에 대한 읽기 전용 액세스를 부여합니다. |
| `write_repository`       | Git-over-HTTP를 사용하여 비공개 프로젝트의 리포지토리에 대한 읽기-쓰기 액세스를 부여합니다(API 사용 안 함). |
| `read_registry`          | 비공개 프로젝트의 컨테이너 레지스트리 이미지에 대한 읽기 전용 액세스를 부여합니다. |
| `write_registry`         | 비공개 프로젝트의 컨테이너 레지스트리 이미지에 대한 쓰기 액세스를 부여합니다. 이미지를 푸시하려면 읽기 및 쓰기 액세스가 모두 필요합니다. |
| `read_virtual_registry`  | 비공개 프로젝트 및 가상 레지스트리의 종속성 프록시를 통해 컨테이너 이미지에 대한 읽기 전용 액세스를 부여합니다. |
| `write_virtual_registry` | 비공개 프로젝트의 종속성 프록시를 통해 컨테이너 이미지에 대한 읽기, 쓰기 및 삭제 액세스를 부여합니다. |
| `read_observability`     | GitLab 관찰 기능에 대한 읽기 전용 액세스를 부여합니다. |
| `write_observability`    | GitLab 관찰 기능에 대한 쓰기 액세스를 부여합니다. |
| `ai_features`            | GitLab Duo 관련 API 끝점에 대한 액세스를 부여합니다. |
| `sudo`                   | 관리자 사용자로 인증할 때 시스템의 모든 사용자로 API 작업을 수행할 수 있는 권한을 부여합니다. |
| `admin_mode`             | 관리자 모드가 활성화되었을 때 관리자로 API 작업을 수행할 수 있는 권한을 부여합니다. |
| `read_service_ping`      | 관리자 사용자로 인증할 때 API를 통해 Service Ping 페이로드를 다운로드할 수 있는 액세스를 부여합니다. |
| `openid`                 | [OpenID Connect](openid_connect_provider.md)를 사용하여 GitLab으로 인증할 수 있는 권한을 부여합니다. 또한 사용자의 프로필 및 그룹 멤버십에 대한 읽기 전용 액세스를 제공합니다. |
| `profile`                | [OpenID Connect](openid_connect_provider.md)를 사용하여 사용자의 프로필 데이터에 대한 읽기 전용 액세스를 부여합니다. |
| `email`                  | [OpenID Connect](openid_connect_provider.md)를 사용하여 사용자의 기본 이메일 주소에 대한 읽기 전용 액세스를 부여합니다. |

언제든지 **해지**를 선택하여 액세스를 해지할 수 있습니다.

## 액세스 토큰 만료 {#access-token-expiration}

{{< history >}}

- OAuth 액세스 토큰 만료를 인스턴스 관리자가 구성할 수 있도록 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/237354)되었습니다(GitLab 19.1).

{{< /history >}}

기본적으로 액세스 토큰은 2시간(7200초) 후에 만료됩니다. 액세스 토큰을 사용하는 통합은 `refresh_token` 속성으로 새 토큰을 생성해야 합니다. 새로 고침 토큰은 액세스 토큰 자체가 만료된 후에도 사용할 수 있습니다. 만료된 액세스 토큰을 새로 고치는 방법에 대한 자세한 내용은 [OAuth 2.0 토큰 설명서](../api/oauth2.md)를 참조하세요.

GitLab Self-Managed 및 GitLab Dedicated에서 관리자는 토큰 수명을 구성할 수 있습니다. 자세한 내용은 [OAuth 액세스 토큰 최대 수명 수정](../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-oauth-access-tokens)을 참조하세요.

애플리케이션이 삭제되면 애플리케이션과 관련된 모든 권한 부여 및 토큰도 삭제됩니다.

## 해시된 OAuth 애플리케이션 비밀 {#hashed-oauth-application-secrets}

기본적으로 GitLab은 OAuth 애플리케이션 비밀을 데이터베이스에 해시된 형식으로 저장합니다. 이러한 비밀은 OAuth 애플리케이션을 생성한 직후에만 사용자가 사용할 수 있습니다. 이전 버전의 GitLab에서는 애플리케이션 비밀이 데이터베이스에 일반 텍스트로 저장됩니다.

## GitLab에서 OAuth 2를 사용하는 다른 방법 {#other-ways-to-use-oauth-2-in-gitlab}

다음을 수행할 수 있습니다.

- [애플리케이션 API](../api/applications.md)를 사용하여 OAuth 2 애플리케이션을 생성하고 관리할 수 있습니다.
- 사용자가 써드파티 OAuth 2 제공자를 사용하여 GitLab에 로그인할 수 있습니다. 자세한 내용은 [OmniAuth 설명서](omniauth.md)를 참조하세요.
- GitLab Importer를 OAuth 2와 함께 사용하여 GitLab.com 계정에 사용자 자격 증명을 공유하지 않고도 리포지토리에 대한 액세스를 제공할 수 있습니다.
