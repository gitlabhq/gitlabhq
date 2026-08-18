---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 세분화된 개인 액세스 토큰
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.10에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/18555)되었으며 [베타](../../policy/development_stages_support.md#beta) 상태입니다.
- GitLab 19.2에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/work_items/596613)합니다.

{{< /history >}}

상세조정 개인 액세스 토큰은 정의된 특정 리소스와 권한만 액세스하도록 범위가 설정됩니다. 토큰을 생성할 때 다음 특성을 정의합니다:

- 리소스: API 작업의 집합입니다. 리소스는 더 큰 범위로 그룹화됩니다 ( `Group and project`, `User`, `Global`).
- 권한: 토큰이 리소스에서 수행할 수 있는 특정 작업입니다. 일반적으로 만들기, 읽기, 업데이트 및 삭제 작업을 준수합니다.

## 상세조정 개인 액세스 토큰 생성 {#create-a-fine-grained-personal-access-token}

상세조정 개인 액세스 토큰을 생성하려면:

1. 오른쪽 위 모서리에서 아바타를 선택합니다.
1. **프로필 편집**을 선택합니다.
1. 왼쪽 사이드바에서 **액세스** > **개인 액세스 토큰**을 선택합니다.
1. **토큰 생성** 드롭다운 목록에서 **상세조정 토큰**을 선택합니다.
1. **이름**과 **설명** 필드를 완료합니다.
1. **만료일** 텍스트 상자에 토큰의 만료 날짜를 입력합니다.
   - 토큰은 그 날짜의 자정 UTC에 만료됩니다.
   - 날짜를 입력하지 않으면 만료일이 오늘로부터 365일로 설정됩니다.
   - 기본적으로 만료일은 오늘로부터 365일을 초과할 수 없습니다. GitLab 17.6 이상에서는 관리자가 [액세스 토큰의 최대 수명을 수정](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens)할 수 있습니다.
1. 그룹 또는 프로젝트 리소스를 추가하는 경우 **그룹과 프로젝트 접근** 아래에서 옵션을 선택합니다.
1. **리소스 권한 추가** 아래:
   1. **그룹과 프로젝트**, **사용자**, 또는 **전역** 탭을 사용하여 범위별로 리소스를 필터링합니다.
   1. 왼쪽 패널에서 하나 이상의 리소스를 선택합니다.
   1. 오른쪽 패널에서 각 리소스에 대해 [사용 가능한 권한](#available-fine-grained-permissions)을 선택합니다.
1. **토큰 생성**을 선택합니다.

개인 액세스 토큰이 표시됩니다. 개인 액세스 토큰을 안전한 위치에 저장합니다. 페이지를 떠나거나 새로 고친 후에는 다시 볼 수 없습니다.

## sudo로 사용자 가장 {#impersonate-users-with-sudo}

관리자는 REST API의 [`sudo`](../../api/rest/authentication.md#sudo) 매개변수로 다른 사용자를 가장할 수 있는 세분화된 개인 액세스 토큰을 만들 수 있습니다.

관리자만 sudo 기능을 사용하여 토큰을 만들 수 있습니다. 관리자가 아닌 사용자가 이를 만들려고 하면 오류가 발생합니다.

세분화된 토큰은 가장하는 동안 자신의 권한을 계속 적용합니다. 토큰은 다음 중 둘 다 참인 경우에만 작업을 수행할 수 있습니다:

- 가장된 사용자는 해당 작업을 수행할 수 있습니다.
- 토큰에 해당 작업을 허용하는 권한이 있습니다.

이 동작은 가장된 사용자로서 모든 작업을 수행할 수 있는 `sudo` 범위를 가진 레거시 개인 액세스 토큰과 다릅니다.

> [!warning]
> sudo 기능을 가진 토큰은 모든 사용자로 작동할 수 있습니다. 권한과 범위를 필요한 최소한으로 제한하고 안전하게 저장합니다.

## 사용 가능한 세분화된 권한 {#available-fine-grained-permissions}

세분화된 개인 액세스 토큰이 사용할 수 있는 권한은 토큰이 호출하는 엔드포인트에 따라 다릅니다:

- [REST API용 세분화된 권한](fine_grained_access_tokens_rest.md)
- [GraphQL API용 세분화된 권한](fine_grained_access_tokens_graphql.md)
- [Git 및 기타 작업을 위한 세분화된 권한](fine_grained_access_tokens_other.md)

## 세분화된 개인 액세스 토큰 강제 적용 {#enforce-fine-grained-personal-access-tokens}

{{< history >}}

- [도입](https://gitlab.com/groups/gitlab-org/-/work_items/20180)됨: GitLab 18.11에서 [플래그](../../administration/feature_flags/_index.md) `granular_personal_access_tokens_enforcement` 및 `granular_personal_access_tokens_enforcement_saas` 포함. 기본적으로 비활성화되었습니다.
- GitLab Self-Managed의 GitLab 19.2에서 [일반 공개](https://gitlab.com/gitlab-org/gitlab/-/work_items/596613).

{{< /history >}}

특정 강제 시행 날짜 이후에 사용자가 세분화된 개인 액세스 토큰을 채택하도록 요구할 수 있습니다. 이 날짜 이후에는 기존의 모든 레거시 개인 액세스 토큰이 사용자 프로필에 나열되지만 리소스에 액세스하는 데 사용할 수 없습니다.

강제 적용은 GitLab.com과 GitLab Self-Managed에서 다르게 작동합니다:

- GitLab.com에서는 강제 적용이 최상위 그룹에 적용되고 모든 하위 그룹 및 프로젝트에 의해 상속됩니다.
- GitLab Self-Managed에서는 강제 적용이 전체 인스턴스에 적용됩니다.

### 최상위 그룹의 세분화된 토큰 강제 적용 {#enforce-fine-grained-tokens-for-a-top-level-group}

전제 조건:

- 최상위 그룹에 대한 Owner 역할이 있어야 합니다.

GitLab.com에서는 강제 적용이 그룹 및 해당 하위 그룹과 프로젝트에 적용되며 강제 시행 날짜 이후에 레거시 개인 액세스 토큰이 해당 리소스에 액세스하는 것을 차단합니다. 사용자는 여전히 레거시 토큰을 만들 수 있지만 해당 토큰은 그룹의 강제된 리소스에 액세스할 수 없습니다.

이 설정은 GitLab Self-Managed에서 사용할 수 없습니다.

최상위 그룹에서만 세분화된 토큰을 강제할 수 있습니다.

최상위 그룹의 세분화된 개인 액세스 토큰을 강제 적용하려면:

1. 왼쪽 사이드바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. **설정** > **일반**을 선택합니다.
1. **Permissions and group features**를 확장합니다.
1. **특정 날짜 이후에는 세분화된 개인 액세스 토큰을 요구합니다**를 선택합니다.
1. 향후 강제 시행 날짜를 입력합니다. 강제 시행 날짜는 협정 세계시(UTC)입니다.
1. **변경 사항 저장**을 선택합니다.

강제 시행 날짜 이후에는 사용자가 최상위 그룹, 모든 하위 그룹 또는 프로젝트의 리소스에 액세스하기 위해 레거시 토큰을 사용하려고 할 때 오류를 받습니다. 오류는 세분화된 토큰이 필요한 리소스 범위와 권한을 나열합니다. 예를 들어:

```plaintext
Access denied: This operation requires a fine-grained personal access token with the following project permissions: [Project: Read].
```

### GitLab Self-Managed에서 세분화된 토큰 강제 적용 {#enforce-fine-grained-tokens-on-gitlab-self-managed}

전제 조건:

- 관리자여야 합니다.

GitLab Self-Managed에서는 강제 적용이 전체 인스턴스에 적용되며 강제 시행 날짜 이후에 사용자가 레거시 개인 액세스 토큰을 만들거나 회전하는 것을 차단합니다. 사용자는 세분화된 토큰만 만들 수 있습니다. 기존 레거시 토큰은 만료될 때까지 계속 작동합니다.

인스턴스의 세분화된 개인 액세스 토큰을 강제 적용하려면:

1. 왼쪽 사이드바 맨 아래에서 **Admin**을 선택합니다.
1. **설정** > **일반**을 선택합니다.
1. **계정과 제한**을 펼칩니다.
1. **특정 날짜 이후에는 세분화된 개인 액세스 토큰을 요구합니다**를 선택합니다.
1. **세분화된 개인 액세스 토큰 강제 시행일**에 향후 날짜를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

강제 시행 날짜 이후에는 사용자가 레거시 토큰을 만들거나 회전하려고 할 때 오류를 받습니다.
