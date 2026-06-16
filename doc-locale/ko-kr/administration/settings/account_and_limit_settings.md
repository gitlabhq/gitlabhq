---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
description: "GitLab Self-Managed에서 사용자가 만들 수 있는 최대 프로젝트 수를 구성합니다. 첨부 파일, 푸시 및 리포지토리 크기에 대한 크기 제한을 구성합니다."
title: 계정과 제한 설정
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab 관리자는 인스턴스에서 프로젝트 및 계정 제한을 구성할 수 있습니다. 예를 들면:

- 사용자가 만들 수 있는 프로젝트 수입니다.
- 첨부 파일, 푸시 및 리포지토리의 크기 제한입니다.
- 세션 기간 및 만료입니다.
- 액세스 토큰 설정(예: 만료 및 접두어)입니다.
- 사용자 개인 정보 및 삭제 설정입니다.
- 조직 및 최상위 그룹에 대한 생성 규칙입니다.

## 기본 프로젝트 한도 {#default-projects-limit}

새 사용자가 자신의 개인 네임스페이스에서 만들 수 있는 프로젝트의 기본 최대 수를 구성할 수 있습니다. 이 한도는 설정을 변경한 후 생성된 새 사용자 계정에만 영향을 미칩니다. 이 설정은 기존 사용자에게 소급 적용되지 않지만 [기존 사용자의 프로젝트 한도](#projects-limit-for-a-user)를 별도로 편집할 수 있습니다.

새 사용자를 위해 개인 네임스페이스의 최대 프로젝트 수를 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한**을 펼칩니다.
1. **기본 프로젝트 한도** 값을 증가 또는 감소시킵니다.

**기본 프로젝트 한도**를 0으로 설정하면 사용자는 자신의 개인 네임스페이스에서 프로젝트를 만들 수 없습니다. 그러나 프로젝트는 여전히 그룹에서 만들 수 있습니다.

### 사용자의 프로젝트 제한 {#projects-limit-for-a-user}

특정 사용자를 편집하여 해당 사용자가 자신의 개인 네임스페이스에서 만들 수 있는 프로젝트의 최대 수를 변경할 수 있습니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **개요** > **사용자**를 선택하세요.
1. 사용자 목록에서 사용자를 선택합니다.
1. **편집**을 선택합니다.
1. **프로젝트 제한** 값을 증가 또는 감소시킵니다.

## 최대 첨부 파일 크기 {#max-attachment-size}

GitLab 댓글 및 답글의 첨부 파일에 대한 최대 파일 크기는 100MB입니다. 최대 첨부 파일 크기를 변경하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한**을 펼칩니다.
1. **최대 첨부 파일 크기(MiB)**의 값을 변경하여 증가 또는 감소시킵니다.

웹 서버에 대해 구성된 값보다 큰 크기를 선택하면 오류가 발생할 수 있습니다. 자세한 내용은 [문제 해결 섹션](#troubleshooting)을 참조하세요.

GitLab.com 리포지토리 크기 한도는 [계정 및 제한 설정](../../user/gitlab_com/_index.md#account-and-limit-settings)을 참조하세요.

## 최대 푸시 크기 {#max-push-size}

인스턴스의 최대 푸시 크기를 변경할 수 있습니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한**을 펼칩니다.
1. **최대 푸시 크기 (MiB)**의 값을 변경하여 증가 또는 감소시킵니다.

GitLab.com 푸시 크기 한도는 [계정 및 제한 설정](../../user/gitlab_com/_index.md#account-and-limit-settings)을 참조하세요.

> [!note]
> 웹 UI를 통해 [리포지토리에 파일을 추가](../../user/project/repository/web_editor.md#create-a-file)할 때 최대 첨부 파일 크기가 제한 요소입니다. 이는 GitLab이 커밋을 생성하기 전에 웹 서버가 파일을 수신해야 하기 때문입니다. [Git LFS](../../topics/git/lfs/_index.md)를 사용하여 대용량 파일을 리포지토리에 추가합니다. 이 설정은 Git LFS 객체를 푸시할 때 적용되지 않습니다.

## 리포지토리 크기 제한 {#repository-size-limit}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab 인스턴스의 리포지토리는 특히 LFS를 사용하는 경우 빠르게 증가할 수 있습니다. 리포지토리 크기는 기하급수적으로 증가하여 사용 가능한 스토리지를 빠르게 소비할 수 있습니다. 이를 방지하기 위해 리포지토리 크기에 대한 하드 제한을 설정할 수 있습니다. 이 제한은 전역적으로, 그룹별로 또는 프로젝트별로 설정할 수 있으며, 프로젝트별 제한이 가장 높은 우선순위를 갖습니다.

리포지토리 크기 제한은 개인 및 공개 프로젝트 모두에 적용됩니다. 리포지토리 파일 및 Git LFS 객체(외부 객체 스토리지에 저장된 경우에도)를 포함하지만 다음은 포함하지 않습니다:

- 아티팩트
- 컨테이너
- 패키지
- 스니펫
- 업로드
- 위키

리포지토리 크기에 대한 제한을 설정할 수 있는 많은 사용 사례가 있습니다. 예를 들어 다음 워크플로를 고려하세요:

1. 팀에서 대용량 파일을 애플리케이션 리포지토리에 저장해야 하는 앱을 개발합니다.
1. 프로젝트에 [Git LFS](../../topics/git/lfs/_index.md)를 활성화했지만 스토리지가 크게 증가했습니다.
1. 사용 가능한 스토리지를 초과하기 전에 리포지토리당 10GB 제한을 설정합니다.

GitLab Self-Managed 및 GitLab Dedicated에서는 GitLab 관리자만 이러한 제한을 설정할 수 있습니다. 제한을 `0`로 설정하면 제한이 없다는 의미입니다. GitLab.com 리포지토리 크기 한도는 [계정 및 제한 설정](../../user/gitlab_com/_index.md#account-and-limit-settings)을 참조하세요.

이러한 설정은 다음에서 찾을 수 있습니다:

- 각 프로젝트의 설정:
  1. 프로젝트의 홈페이지에서 **설정** > **일반**으로 이동합니다.
  1. **Naming, topics, avatar** 섹션에서 **리포지토리 크기 제한 (MiB)** 필드를 입력합니다.
  1. **변경 사항 저장**을 선택합니다.
- 각 그룹의 설정:
  1. 그룹의 홈페이지에서 **설정** > **일반**으로 이동합니다.
  1. **이름, 공개범위** 섹션에서 **리포지토리 크기 제한 (MiB)** 필드를 입력합니다.
  1. **변경 사항 저장**을 선택합니다.
- GitLab 전역 설정:
  1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
  1. **Settings** > **General**을 선택합니다.
  1. **계정과 제한** 섹션을 펼칩니다.
  1. **리포지토리당 크기 제한 (MiB)** 필드를 입력합니다.
  1. **변경 사항 저장**을 선택합니다.

LFS 객체를 포함한 새 프로젝트의 첫 번째 푸시는 크기 검사를 받습니다. 크기의 합이 허용된 최대 리포지토리 크기를 초과하면 푸시가 거부됩니다.

### 리포지토리 크기 확인 {#check-repository-size}

프로젝트가 구성된 리포지토리 크기 제한에 가까워지고 있는지 확인하려면:

1. [스토리지 사용량 보기](../../user/storage_usage_quotas.md#view-storage). **리포지토리** 크기에는 Git 리포지토리 파일 및 [Git LFS](../../topics/git/lfs/_index.md) 객체가 모두 포함됩니다.
1. 현재 사용량을 구성된 리포지토리 크기 제한과 비교하여 남은 용량을 예상합니다.

[Projects API](../../api/projects.md)를 사용하여 리포지토리 통계를 검색할 수 있습니다.

리포지토리 크기를 줄이려면 [리포지토리 크기를 줄이는 방법](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size)을 참조하세요.

## 세션 기간 {#session-duration}

### 기본 세션 기간 사용자 지정 {#customize-the-default-session-duration}

사용자가 활동 없이 로그인 상태를 유지할 수 있는 시간을 변경할 수 있습니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한**을 펼칩니다.
1. **Session duration (minutes)** 필드를 입력합니다.
   > [!warning]
   > **Session duration (minutes)**을 `0`로 설정하면 GitLab 인스턴스가 손상됩니다. 자세한 내용은 [이슈 19469](https://gitlab.com/gitlab-org/gitlab/-/issues/19469)를 참조하세요.
1. **변경 사항 저장**을 선택합니다.
1. 변경 사항을 적용하려면 GitLab을 다시 시작합니다.
   > [!note]
   > GitLab Dedicated의 경우 [지원 티켓](https://support.gitlab.com/hc/en-us/requests/new?ticket_form_id=4414917877650)을 제출하여 인스턴스 재시작을 요청합니다.

[**계정 정보 저장** 옵션](#configure-the-remember-me-option)이 활성화되면 사용자의 세션은 무한정 활성 상태를 유지할 수 있습니다.

자세한 내용은 [로그인에 사용되는 쿠키](../../user/profile/_index.md#cookies-used-for-sign-in)를 참조하세요.

### 생성 날짜부터 만료되도록 세션 설정 {#set-sessions-to-expire-from-creation-date}

{{< history >}}

- GitLab 18.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/395038)되었으며 `session_expire_from_init` 이름의 [플래그](../feature_flags/_index.md)를 포함합니다. 기본적으로 활성화됨.
- GitLab 18.3에서 [일반 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198734)합니다. 기능 플래그 `session_expire_from_init` 제거됨.

{{< /history >}}

기본적으로 세션은 세션이 비활성화된 후 설정된 시간이 지나면 만료됩니다. 대신 세션이 생성된 후 설정된 시간이 지나면 만료되도록 세션을 구성할 수 있습니다.

세션 기간에 도달하면 세션이 종료되고 다음인 경우에도 사용자가 로그아웃됩니다:

- 사용자가 여전히 세션을 적극적으로 사용하고 있습니다.
- 사용자가 로그인 중에 [**계정 정보 저장**](#configure-the-remember-me-option)을 선택했습니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한**을 펼칩니다.
1. **Expire session from creation date** 체크박스를 선택합니다.

세션이 종료되면 창이 나타나 사용자에게 다시 로그인하도록 지시합니다.

### 계정 정보 저장 옵션 구성 {#configure-the-remember-me-option}

{{< history >}}

- **계정 정보 저장** 설정 활성화 및 비활성화는 GitLab 16.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/369133)되었습니다.

{{< /history >}}

사용자는 로그인 시 **계정 정보 저장** 체크박스를 선택할 수 있습니다. 특정 브라우저에서 액세스할 때 세션은 무한정 활성 상태를 유지합니다. 보안 또는 규정 준수 목적으로 이 설정을 끄면 세션이 만료됩니다. 이 설정을 끄면 [세션 기간을 사용자 지정](#customize-the-default-session-duration)할 때 설정한 비활성 시간(분)이 지나면 사용자의 세션이 만료됩니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한**을 펼칩니다.
1. **계정 정보 저장** 체크박스를 선택하거나 선택 해제하여 이 설정을 켜거나 끕니다.

### 2FA가 활성화된 경우 Git 작업에 대한 세션 기간 사용자 지정 {#customize-session-duration-for-git-operations-when-2fa-is-enabled}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

<!-- The history line is too old, but must remain until `feature_flags/development/two_factor_for_cli.yml` is removed -->

{{< history >}}

- GitLab 13.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/296669)되었으며 `two_factor_for_cli` 이름의 [플래그](../feature_flags/_index.md)를 포함합니다. 기본적으로 비활성화됨. 이 기능 플래그는 또한 [2FA for Git over SSH 작업](../../security/two_factor_authentication.md#2fa-for-git-over-ssh-operations)에 영향을 미칩니다.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능 여부는 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요. 이 기능은 프로덕션 사용을 위해 준비되지 않았습니다.

GitLab 관리자는 2FA가 활성화되었을 때 Git 작업에 대한 세션 기간(분)을 사용자 지정하도록 선택할 수 있습니다. 기본값은 15이며 1에서 10080 사이의 값으로 설정할 수 있습니다.

이러한 세션의 유효 기간을 제한하도록 설정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한** 섹션을 펼칩니다.
1. **2FA가 활성화된 경우 Git 사용할 수 있는 세션 기간(분)** 필드를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## 최상위 그룹 소유자가 서비스 계정을 만들도록 허용 {#allow-top-level-group-owners-to-create-service-accounts}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.5에서 GitLab Self-Managed의 경우 `allow_top_level_group_owners_to_create_service_accounts` 이름의 [기능 플래그](../feature_flags/_index.md) 와 함께 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163726)되었습니다. 기본적으로 비활성화됨.
- GitLab 17.6에서 [일반 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172502)합니다. 기능 플래그 `allow_top_level_group_owners_to_create_service_accounts` 제거됨.

{{< /history >}}

기본적으로 관리자만 서비스 계정을 만들 수 있습니다. GitLab을 구성하여 최상위 그룹 소유자도 서비스 계정을 만들 수 있도록 허용할 수 있습니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

최상위 그룹 소유자가 서비스 계정을 만들도록 허용하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한**을 펼칩니다.
1. **서비스 계정 생성** 아래에서 **Allow top-level group owners to create Service accounts** 체크박스를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

## 새 액세스 토큰에 대해 만료 날짜 필요 {#require-expiration-dates-for-new-access-tokens}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/470192)되었습니다.

{{< /history >}}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

모든 새 액세스 토큰에 만료 날짜를 가지도록 요구할 수 있습니다. 이 설정은 기본적으로 켜져 있으며 다음에 적용됩니다:

- 서비스 계정이 아닌 사용자의 개인 액세스 토큰입니다.
- 그룹 액세스 토큰입니다.
- 프로젝트 액세스 토큰입니다.

서비스 계정의 개인 액세스 토큰의 경우 [응용 프로그램 설정 API](../../api/settings.md)에서 `service_access_tokens_expiration_enforced` 설정을 사용합니다.

새 액세스 토큰에 대해 만료 날짜를 요구하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한**을 펼칩니다.
1. **Personal / Project / Group access token expiration** 체크박스를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

새 액세스 토큰에 대해 만료 날짜를 요구하면:

- 사용자는 새 액세스 토큰의 허용된 수명을 초과하지 않는 만료 날짜를 설정해야 합니다.
- 최대 액세스 토큰 수명을 제어하려면 [**Limit the lifetime of access tokens** 설정](#limit-the-lifetime-of-access-tokens)을 사용합니다.

## 비활성 프로젝트 및 그룹 액세스 토큰 보존 기간 {#inactive-project-and-group-access-token-retention-period}

{{< details >}}

- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

기본적으로 GitLab은 [토큰 가족](../../api/personal_access_tokens.md#automatic-reuse-detection)의 마지막 활성 토큰이 비활성화된 후 30일 후에 그룹 및 프로젝트 액세스 토큰과 해당 토큰을 삭제합니다. 이 삭제는 토큰 가족의 모든 토큰, 관련 봇 사용자를 제거하고 모든 봇 기여도를 [ghost 사용자](../../user/profile/account/delete_account.md#associated-records)로 이동합니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

비활성 토큰의 보존 기간을 수정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한**을 펼칩니다.
1. **비활성 프로젝트 및 그룹 액세스 토큰 보존 기간** 텍스트 상자에서 보존 기간을 수정합니다.
   - 숫자가 정의되면 모든 그룹 및 프로젝트 액세스 토큰이 지정된 일 수 동안 비활성화된 후 삭제됩니다.
   - 필드가 비어 있으면 비활성 토큰은 삭제되지 않습니다.
1. **변경 사항 저장**을 선택합니다.

[응용 프로그램 설정 API](../../api/settings.md)를 사용하여 `inactive_resource_access_tokens_delete_after_days` 속성을 수정할 수도 있습니다.

## 개인 액세스 토큰 접두어 {#personal-access-token-prefix}

개인 액세스 토큰의 접두어를 지정할 수 있습니다. 사용자 지정 접두어 사용의 이점:

- 토큰이 구별되고 식별 가능합니다.
- 누출된 토큰은 보안 스캔 중에 더 쉽게 식별할 수 있습니다.
- 다양한 인스턴스 간의 토큰 혼동 위험을 줄입니다.

개인 액세스 토큰의 기본 접두어는 `glpat-`이지만 관리자는 변경할 수 있습니다. [프로젝트 액세스 토큰](../../user/project/settings/project_access_tokens.md) 및 [그룹 액세스 토큰](../../user/group/settings/group_access_tokens.md)도 이 접두어를 상속합니다.

> [!warning]
> 기본적으로 클라이언트 측 시크릿 검색, 시크릿 푸시 보호 및 파이프라인 시크릿 검색은 사용자 지정 접두어가 있는 토큰을 검색하지 않습니다. 이로 인해 거짓 음성이 증가할 수 있습니다. 그러나 [파이프라인 시크릿 검색을 사용자 지정](../../user/application_security/secret_detection/pipeline/configure.md#customize-analyzer-rulesets)하여 이러한 토큰을 검색할 수 있습니다.

### 접두어 설정 {#set-a-prefix}

기본 전역 접두어를 변경하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한** 섹션을 펼칩니다.
1. **Personal access token prefix** 필드를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

[설정 API](../../api/settings.md)를 사용하여 접두어를 구성할 수도 있습니다.

## 인스턴스 토큰 접두어 {#instance-token-prefix}

{{< history >}}

- GitLab 17.10에서 `custom_prefix_for_all_token_types` 이름의 [플래그](../feature_flags/_index.md) 와 함께 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179852)되었습니다. 기본적으로 비활성화됨.

{{< /history >}}

> [!flag]
> 이 기능의 사용 가능 여부는 기능 플래그에 의해 제어됩니다. 자세한 내용은 이력을 참조하세요. 이 기능은 테스트에 사용할 수 있지만 프로덕션 사용을 위해 준비되지 않았습니다.

인스턴스에서 생성된 모든 토큰에 추가될 사용자 지정 접두어를 설정할 수 있습니다. 사용자 지정 접두어 사용의 이점:

- 토큰이 구별되고 식별 가능합니다.
- 누출된 토큰은 보안 스캔 중에 더 쉽게 식별할 수 있습니다.
- 다양한 인스턴스 간의 토큰 혼동 위험을 줄입니다.

> [!warning]
> 기본적으로 클라이언트 측 시크릿 검색, 시크릿 푸시 보호 및 파이프라인 시크릿 검색은 사용자 지정 접두어가 있는 토큰을 검색하지 않습니다. 이로 인해 거짓 음성이 증가할 수 있습니다. 그러나 [파이프라인 시크릿 검색을 사용자 지정](../../user/application_security/secret_detection/pipeline/configure.md#customize-analyzer-rulesets)하여 이러한 토큰을 검색할 수 있습니다.

사용자 지정 토큰 접두어는 다음 토큰에만 적용됩니다:

- [CI/CD 작업 토큰](../../security/tokens/_index.md#cicd-job-tokens)
- [클러스터 에이전트 토큰](../../security/tokens/_index.md#gitlab-cluster-agent-tokens)
- [배포 토큰](../../user/project/deploy_tokens/_index.md)
- [기능 플래그 클라이언트 토큰](../../operations/feature_flags.md#get-access-credentials)
- [피드 토큰](../../security/tokens/_index.md#feed-token)
- [들어오는 이메일 토큰](../../security/tokens/_index.md#incoming-email-token)
- [OAuth 응용 프로그램 시크릿](../../integration/oauth_provider.md)
- [개인 액세스 토큰](../../user/profile/personal_access_tokens.md)
- [파이프라인 트리거 토큰](../../ci/triggers/_index.md#create-a-pipeline-trigger-token)
- [러너 인증 토큰](../../security/tokens/_index.md#runner-authentication-tokens)
- [SCIM 토큰](../../security/tokens/_index.md#token-prefixes)
- [워크스페이스 토큰](../../security/tokens/_index.md#workspace-token)

전제 조건:

- 인스턴스에 대한 관리자 액세스 권한이 있어야 합니다.

사용자 지정 토큰 접두어를 설정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한** 섹션을 펼칩니다.
1. **인스턴스 토큰 접두어** 필드에 사용자 지정 접두어를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

## 액세스 토큰의 수명 제한 {#limit-the-lifetime-of-access-tokens}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.6에서 `buffered_token_expiration_limit` 이름의 [플래그](../feature_flags/_index.md) 와 함께 최대 허용 수명 제한을 400일의 증가된 값으로 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/461901)했습니다. 기본적으로 비활성화됨.

{{< /history >}}

> [!flag]
> 확장된 최대 허용 수명 제한의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 이력을 참조하세요. 기능 플래그는 GitLab Dedicated에서 사용할 수 없습니다.

사용자는 액세스 토큰의 최대 수명(일)을 선택적으로 지정할 수 있습니다. 여기에는 [개인](../../user/profile/personal_access_tokens.md) , [그룹](../../user/group/settings/group_access_tokens.md) 및 [프로젝트](../../user/project/settings/project_access_tokens.md) 액세스 토큰이 포함됩니다. 이 수명은 필수 사항이 아니며 0보다 크고 다음 이하의 값으로 설정할 수 있습니다:

- 기본적으로 365일입니다.
- `buffered_token_expiration_limit` 기능 플래그를 활성화하면 400일입니다. 이 확장된 제한은 GitLab Dedicated에서 사용할 수 없습니다.

이 설정을 비워 두면 액세스 토큰의 기본 허용 수명은:

- 기본적으로 365일입니다.
- `buffered_token_expiration_limit` 기능 플래그를 활성화하면 400일입니다. 이 확장된 제한은 GitLab Dedicated에서 사용할 수 없습니다.

액세스 토큰은 GitLab에 프로그래밍 방식으로 액세스하는 데 필요한 유일한 토큰입니다. 그러나 보안 요구 사항이 있는 조직은 이러한 토큰의 정기적인 로테이션을 요구하여 더 많은 보호를 적용할 수 있습니다.

### 수명 설정 {#set-a-lifetime}

GitLab 관리자만 수명을 설정할 수 있습니다. 비어 두면 제한이 없다는 의미입니다.

액세스 토큰의 유효 기간을 설정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한** 섹션을 펼칩니다.
1. **Maximum allowable lifetime for access tokens (days)** 필드를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

액세스 토큰의 수명이 설정되면 GitLab은:

- 새 개인 액세스 토큰에 대해 수명을 적용하고 사용자에게 만료 날짜와 허용된 수명 이하인 날짜를 설정하도록 요구합니다.
- 3시간 후 만료 날짜가 없거나 허용된 수명보다 수명이 더 긴 이전 토큰을 취소합니다. 3시간은 관리자가 허용된 수명을 변경하거나 제거한 후 취소가 발생하기 전에 시간을 제공하기 위해 제공됩니다.

## SSH 키의 수명 제한 {#limit-the-lifetime-of-ssh-keys}

{{< details >}}

- 티어:  Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

사용자는 선택적으로 [SSH 키](../../user/ssh.md)의 수명을 지정할 수 있습니다. 이 수명은 필수 사항이 아니며 임의의 일 수로 설정할 수 있습니다.

SSH 키는 GitLab에 액세스하기 위한 사용자 자격 증명입니다. 그러나 보안 요구 사항이 있는 조직은 이러한 키의 정기적인 로테이션을 요구하여 더 많은 보호를 적용할 수 있습니다.

### 수명 설정 {#set-a-lifetime-1}

GitLab 관리자만 수명을 설정할 수 있습니다. 비어 두면 제한이 없다는 의미입니다.

SSH 키의 유효 기간을 설정하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한** 섹션을 펼칩니다.
1. **Maximum allowable lifetime for SSH keys (days)** 필드를 입력합니다.
1. **변경 사항 저장**을 선택합니다.

SSH 키의 수명이 설정되면 GitLab은:

- 사용자에게 새로운 SSH 키에 대해 허용된 수명 이하인 만료 날짜를 설정하도록 요구합니다. 최대 허용 수명은:
  - 기본적으로 365일입니다.
  - `buffered_token_expiration_limit` 기능 플래그를 활성화하면 400일입니다. 이 확장된 제한은 GitLab Dedicated에서 사용할 수 없습니다.
- 기존 SSH 키에 수명 제한을 적용합니다. 만료 또는 최대값보다 수명이 더 긴 키는 즉시 유효하지 않게 됩니다.

> [!note]
> 사용자의 SSH 키가 유효하지 않게 되면 동일한 키를 삭제했다가 다시 추가할 수 있습니다.

## 사용자 OAuth 응용 프로그램 설정 {#user-oauth-applications-setting}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

**사용자 OAuth 응용 프로그램** 설정은 사용자가 GitLab을 OAuth 공급자로 사용하도록 응용 프로그램을 등록할 수 있는지 여부를 제어합니다. 이 설정은 사용자가 소유한 OAuth 응용 프로그램에 영향을 미치지만 그룹이 소유한 OAuth 응용 프로그램에는 영향을 미치지 않습니다.

**사용자 OAuth 응용 프로그램** 설정을 켜거나 끄려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한** 섹션을 펼칩니다.
1. **사용자 OAuth 응용 프로그램** 체크박스를 선택하거나 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.

## 사용자 프로필 이름 변경 비활성화 {#disable-user-profile-name-changes}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[감사 이벤트](../compliance/audit_event_reports.md)의 사용자 세부 정보 무결성을 유지하기 위해 GitLab 관리자는 사용자가 프로필 이름을 변경하지 못하도록 할 수 있습니다.

이렇게 하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한**을 펼칩니다.
1. **사용자가 프로필 이름을 변경하지 못하도록 방지**를 선택합니다.

선택하면 GitLab 관리자는 [**운영자** 영역](../admin_area.md#administering-users) 또는 [API](../../api/users.md#modify-a-user)에서 사용자 이름을 계속 업데이트할 수 있습니다.

## 사용자가 조직을 만드는 것을 방지 {#prevent-users-from-creating-organizations}

{{< details >}}

- 상태:  실험

{{< /details >}}

{{< history >}}

- GitLab 16.7에서 `ui_for_organizations` 이름의 [플래그](../feature_flags/_index.md) 와 함께 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/423302)되었습니다. 기본적으로 비활성화됨.

{{< /history >}}

> [!flag]
> GitLab Self-Managed에서 기본적으로 이 기능은 사용할 수 없습니다. 사용 가능하게 하려면 관리자가 `ui_for_organizations` 이름의 [기능 플래그를 활성화](../feature_flags/_index.md)할 수 있습니다. GitLab.com 및 GitLab Dedicated에서는 이 기능을 사용할 수 없습니다. 이 기능은 프로덕션 사용을 위해 준비되지 않았습니다.

기본적으로 사용자는 조직을 만들 수 있습니다. GitLab 관리자는 사용자가 조직을 만드는 것을 방지할 수 있습니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한**을 펼칩니다.
1. **사용자가 조직을 생성하도록 허용** 체크박스를 선택 해제합니다.

## 새 사용자가 최상위 그룹을 만드는 것을 방지 {#prevent-new-users-from-creating-top-level-groups}

기본적으로 새 사용자는 최상위 그룹을 만들 수 있습니다. GitLab 관리자는 새 사용자가 최상위 그룹을 만드는 것을 방지할 수 있습니다:

- GitLab UI에서 이 섹션의 단계를 사용합니다.
- [응용 프로그램 설정 API](../../api/settings.md#update-application-settings)와 함께합니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한**을 펼칩니다.
1. **새 사용자가 최상위 그룹을 만들 수 있도록 허용** 체크박스를 선택 해제합니다.

> [!note]
> 이 설정은 설정을 끈 후 추가된 사용자에게만 적용됩니다. 기존 사용자는 여전히 최상위 그룹을 만들 수 있습니다.

## 게스트 권한이 없는 사용자가 프로젝트 및 그룹을 만드는 것을 방지 {#prevent-non-members-from-creating-projects-and-groups}

{{< history >}}

- GitLab 16.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/426279)되었습니다.

{{< /history >}}

기본적으로 게스트 역할을 가진 사용자는 프로젝트 및 그룹을 만들 수 있습니다. GitLab 관리자는 이 동작을 방지할 수 있습니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한**을 펼칩니다.
1. **게스트 권한을 가진 사용자에게 그룹 및 개인 프로젝트 생성을 허용** 체크박스를 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.

## 사용자가 프로필을 비공개로 설정하는 것을 방지 {#prevent-users-from-making-their-profiles-private}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `disallow_private_profiles`이라는 이름의 [플래그와 함께](../feature_flags/_index.md) GitLab 17.1에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/421310). 기본적으로 비활성화됨.
- GitLab 17.9에서 [일반 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/427400)합니다. 기능 플래그 `disallow_private_profiles` 제거됨.

{{< /history >}}

기본적으로 사용자는 프로필을 비공개로 설정할 수 있습니다. GitLab 관리자는 이 설정을 비활성화하여 모든 사용자 프로필이 공개되도록 요구할 수 있습니다. 이 설정은 [내부 사용자](../internal_users.md)("봇"이라고도 함)에 영향을 미치지 않습니다.

사용자가 프로필을 비공개로 설정하는 것을 방지하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한**을 펼칩니다.
1. **사용자가 자신의 프로필을 비공개로 설정할 수 있도록 허용** 체크박스를 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.

이 설정을 끄면:

- 모든 비공개 사용자 프로필이 공개됩니다.
- [기본적으로 새 사용자의 프로필을 비공개로 설정](#set-profiles-of-new-users-to-private-by-default) 옵션도 꺼집니다.

이 설정을 다시 활성화하면 사용자의 [이전에 설정한 프로필 표시 유형](../../user/profile/_index.md#make-your-user-profile-page-private)이 선택됩니다.

## 기본적으로 새 사용자의 프로필을 비공개로 설정 {#set-profiles-of-new-users-to-private-by-default}

기본적으로 새로 생성된 사용자는 공개 프로필을 가집니다. GitLab 관리자는 새 사용자가 기본적으로 비공개 프로필을 가지도록 설정할 수 있습니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한**을 펼칩니다.
1. **기본적으로 새 사용자의 프로필을 비공개로 설정** 체크박스를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

> [!note]
> [**사용자가 자신의 프로필을 비공개로 설정할 수 있도록 허용**](#prevent-users-from-making-their-profiles-private)이 비활성화되면 이 설정도 비활성화됩니다.

## 사용자가 자신의 계정을 삭제하는 것을 방지 {#prevent-users-from-deleting-their-accounts}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.1에서 `deleting_account_disabled_for_users` 이름의 [플래그](../feature_flags/_index.md) 와 함께 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/26053)되었습니다. 기본적으로 활성화됨.

{{< /history >}}

기본적으로 사용자는 자신의 계정을 삭제할 수 있습니다. GitLab 관리자는 사용자가 자신의 계정을 삭제하는 것을 방지할 수 있습니다:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **계정과 제한**을 펼칩니다.
1. **사용자가 자신의 계정을 삭제할 수 있도록 허용** 체크박스를 선택 해제합니다.

## 문제 해결 {#troubleshooting}

{{< details >}}

- 제공 서비스: GitLab Self-Managed

{{< /details >}}

### 413 요청 엔티티가 너무 큼 {#413-request-entity-too-large}

GitLab의 댓글 또는 답글에 파일을 첨부할 때 [최대 첨부 파일 크기](#max-attachment-size)가 웹 서버의 허용 값보다 클 수 있습니다.

[Linux 패키지](https://docs.gitlab.com/omnibus/) 설치에서 최대 첨부 파일 크기를 200MB로 늘리려면:

1. `/etc/gitlab/gitlab.rb`에 이 줄을 추가합니다:

   ```ruby
   nginx['client_max_body_size'] = "200m"
   ```

1. 최대 첨부 파일 크기를 늘립니다.

### 이 리포지토리의 크기 한도를 초과했습니다 {#this-repository-has-exceeded-its-size-limit}

[Rails 예외 로그](../logs/_index.md#exceptions_jsonlog)에서 간헐적 푸시 오류를 수신하는 경우 다음과 같은 경우:

```plaintext
Your push to this repository cannot be completed because this repository has exceeded the allocated storage for your project.
```

[하우스키핑](../housekeeping.md) 작업이 리포지토리 크기 증가를 야기할 수 있습니다. 이 문제를 해결하려면 다음 옵션 중 하나가 단기에서 중기간에 도움이 됩니다:

- [리포지토리 크기 제한](#repository-size-limit)을 늘립니다.
- [리포지토리 크기 줄입니다](../../user/project/repository/repository_size.md#methods-to-reduce-repository-size).
