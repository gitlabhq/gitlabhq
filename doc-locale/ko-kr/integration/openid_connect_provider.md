---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OpenID Connect 신원 공급자로서의 GitLab
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab을 [OpenID Connect](https://openid.net/developers/how-connect-works/) (OIDC) 신원 공급자로 사용하여 다른 서비스에 액세스할 수 있습니다. OIDC는 OpenID 2.0과 동일한 많은 작업을 수행하지만 API 친화적이며 네이티브 및 모바일 애플리케이션에서 사용 가능한 신원 계층입니다.

클라이언트는 OIDC를 다음 용도로 사용할 수 있습니다:

- GitLab이 수행한 인증을 기반으로 최종 사용자의 신원을 확인합니다.
- 최종 사용자에 대한 기본 프로필 정보를 상호 운용 가능한 REST 방식으로 얻습니다.

Rails 애플리케이션에 [OmniAuth::OpenIDConnect](https://github.com/omniauth/omniauth_openid_connect)를 사용할 수 있으며 다른 많은 사용 가능한 [클라이언트 구현](https://openid.net/developers/certified-openid-connect-implementations/)이 있습니다.

GitLab은 `doorkeeper-openid_connect` gem을 사용하여 OIDC 서비스를 제공합니다. 자세한 내용은 [`doorkeeper-openid_connect`](https://github.com/doorkeeper-gem/doorkeeper-openid_connect "리포지토리")를 참조하세요.

일부 사용자가 GitLab을 OIDC 공급자로만 사용하고 GitLab 프로젝트 또는 그룹에 액세스할 필요가 없는 경우, [최소 액세스](../user/permissions.md#users-with-minimal-access) 역할을 최상위 그룹에서 사용자에게 할당하는 것을 고려하세요. 최소 액세스 사용자는 구독에서 사용자를 소비하지 않으며, [제한된 액세스](../subscriptions/manage_seats.md#restricted-access)가 활성화되어 있고 사용 가능한 사용자가 없을 때도 액세스할 수 있습니다.

## OAuth 애플리케이션용 OIDC 활성화 {#enable-oidc-for-oauth-applications}

OAuth 애플리케이션용 OIDC를 활성화하려면 애플리케이션 설정에서 `openid` 범위를 선택해야 합니다. 자세한 내용은 [OAuth 2.0 인증 신원 공급자로서 GitLab 구성](oauth_provider.md)을 참조하세요.

## 설정 검색 {#settings-discovery}

클라이언트가 검색 URL에서 OIDC 설정을 가져올 수 있는 경우, GitLab은 이 정보에 액세스할 수 있는 끝점을 제공합니다:

- GitLab.com의 경우 `https://gitlab.com/.well-known/openid-configuration`을 사용합니다.
- GitLab Self-Managed의 경우 `https://<your-gitlab-instance>/.well-known/openid-configuration`을 사용합니다

## 공유 정보 {#shared-information}

다음 사용자 정보가 클라이언트와 공유됩니다:

| 클레임                | 형식      | 설명 | ID 토큰에 포함됨 | `userinfo` 끝점에 포함됨 |
|:---------------------|:----------|:------------|:---------------------|:------------------------------|
| `sub`                | `string`  | 사용자의 ID | {{< yes >}} | {{< yes >}} |
| `auth_time`          | `integer` | 사용자의 마지막 인증 타임스탬프 | {{< yes >}} | {{< no >}} |
| `name`               | `string`  | 사용자의 전체 이름 | {{< yes >}} | {{< yes >}} |
| `nickname`           | `string`  | 사용자의 GitLab 사용자 이름 | {{< yes >}}| {{< yes >}} |
| `preferred_username` | `string`  | 사용자의 GitLab 사용자 이름 | {{< yes >}} | {{< yes >}} |
| `given_name`         | `string`  | 사용자의 이름 | {{< yes >}} | {{< yes >}} |
| `family_name`        | `string`  | 사용자의 성 | {{< yes >}} | {{< yes >}} |
| `email`              | `string`  | 사용자의 기본 이메일 주소 | {{< yes >}} | {{< yes >}} |
| `email_verified`     | `boolean` | 사용자의 이메일 주소가 확인되었는지 여부 | {{< yes >}} | {{< yes >}} |
| `website`            | `string`  | 사용자의 웹 사이트 URL | {{< yes >}} | {{< yes >}} |
| `profile`            | `string`  | 사용자의 GitLab 프로필 URL | {{< yes >}} | {{< yes >}}|
| `picture`            | `string`  | 사용자의 GitLab 아바타 URL | {{< yes >}}| {{< yes >}} |
| `groups`             | `array`   | 사용자가 직접 또는 상위 그룹을 통해 멤버인 그룹의 경로입니다. | {{< no >}} | {{< yes >}} |
| `groups_direct`      | `array`   | 사용자가 직접 멤버인 그룹의 경로입니다. | {{< yes >}} | {{< no >}} |
| `https://gitlab.org/claims/groups/owner`      | `array`   | 사용자가 소유자 역할로 직접 멤버인 그룹의 이름 | {{< no >}} | {{< yes >}} |
| `https://gitlab.org/claims/groups/maintainer` | `array`   | 사용자가 유지보수자 역할로 직접 멤버인 그룹의 이름 | {{< no >}} | {{< yes >}} |
| `https://gitlab.org/claims/groups/developer`  | `array`   | 사용자가 개발자 역할로 직접 멤버인 그룹의 이름 | {{< no >}} | {{< yes >}} |

클레임 `email`과 `email_verified`는 애플리케이션이 `email` 범위에 액세스할 수 있고 사용자의 공개 이메일 주소가 있는 경우에만 포함됩니다. 다른 모든 클레임은 OIDC 클라이언트가 사용하는 `/oauth/userinfo` 끝점에서 사용할 수 있습니다.
