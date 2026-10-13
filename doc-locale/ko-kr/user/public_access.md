---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 프로젝트 및 그룹 공개 범위
description: "공개, 비공개, 내부."
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab의 프로젝트 및 그룹은 비공개, 내부 또는 공개로 설정할 수 있습니다.

프로젝트 또는 그룹의 공개 수준은 프로젝트 또는 그룹의 멤버가 서로를 볼 수 있는지 여부에 영향을 주지 않습니다. 프로젝트 및 그룹은 협업 작업을 위한 것입니다. 이 작업은 모든 멤버가 서로를 알고 있을 때만 가능합니다.

프로젝트 또는 그룹 멤버는 자신이 속한 프로젝트 또는 그룹의 모든 멤버를 볼 수 있습니다. 프로젝트 또는 그룹 멤버는 액세스 권한이 있는 프로젝트 및 그룹의 모든 멤버의 멤버십 출처(원래 프로젝트 또는 그룹)를 볼 수 있습니다.

## 비공개 프로젝트 및 그룹 {#private-projects-and-groups}

비공개 프로젝트의 경우, 비공개 프로젝트 또는 그룹의 멤버만 다음을 수행할 수 있습니다:

- 프로젝트를 복제합니다.
- 공개 액세스 디렉터리(`/public`)를 봅니다.

게스트 역할의 사용자는 프로젝트를 복제할 수 없습니다.

비공개 그룹은 비공개 하위 그룹과 프로젝트만 포함할 수 있습니다.

> [!note]
> [비공개 그룹을 다른 그룹과 공유](project/members/sharing_projects_groups.md#invite-a-group-to-a-group)할 때, 비공개 그룹에 액세스 권한이 없는 사용자는 엔드포인트 `https://gitlab.com/groups/<inviting-group-name>/-/autocomplete_sources/members`를 통해 초대하는 그룹에 액세스 권한이 있는 사용자 목록을 볼 수 있습니다. 그러나 비공개 그룹의 이름 및 경로는 마스킹되고, 사용자의 멤버십 출처는 표시되지 않습니다.

## 내부 프로젝트 및 그룹 {#internal-projects-and-groups}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

내부 프로젝트의 경우, 게스트 역할의 사용자를 포함한 모든 인증된 사용자는 다음을 수행할 수 있습니다:

- 프로젝트를 복제합니다.
- 공개 액세스 디렉터리(`/public`)를 봅니다.

내부 멤버만 내부 콘텐츠를 볼 수 있습니다.

[외부 사용자](../administration/external_users.md)는 프로젝트를 복제할 수 없습니다.

내부 그룹은 내부 또는 비공개 하위 그룹과 프로젝트를 포함할 수 있습니다.

## 공개 프로젝트 및 그룹 {#public-projects-and-groups}

공개 프로젝트의 경우, 인증되지 않은 사용자를 포함한 모든 사용자는 다음을 수행할 수 있습니다:

- 프로젝트를 복제합니다.
- 공개 액세스 디렉터리(`/public`)를 봅니다.

공개 그룹은 공개, 내부 또는 비공개 하위 그룹과 프로젝트를 포함할 수 있습니다.

> [!note]
> 관리자가 [**공개** 수준](../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels)을 제한하면, 공개 액세스 디렉터리(`/public`)는 인증된 사용자에게만 표시됩니다.

## 프로젝트 공개 범위 변경 {#change-project-visibility}

프로젝트의 공개 범위를 변경할 수 있습니다.

사전 요구 사항:

- 프로젝트에 대한 소유자 역할이 있어야 합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
1. **프로젝트 공개 수준** 드롭다운 목록에서 옵션을 선택합니다. 프로젝트의 공개 범위 설정은 최소한 상위 그룹의 공개 범위만큼 제한적이어야 합니다. 프로젝트가 포크인 경우, 공개 범위는 최소한 상위 프로젝트의 공개 범위만큼 제한적이어야 합니다. 자세한 내용은 [포크 공개 범위](project/repository/forking_workflow.md#create-a-fork)를 참조하세요.
1. **변경 사항 저장**을 선택합니다.

## 프로젝트에서 개별 기능의 공개 범위 변경 {#change-the-visibility-of-individual-features-in-a-project}

프로젝트에서 개별 기능의 공개 범위를 변경할 수 있습니다.

사전 요구 사항:

- 프로젝트에 대해 유지 관리자 또는 소유자 역할이 있어야 합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
1. 기능을 활성화하거나 비활성화하려면 기능 토글을 켜거나 끕니다.
1. **변경 사항 저장**을 선택합니다.

## 그룹 공개 범위 변경 {#change-group-visibility}

그룹의 모든 프로젝트의 공개 범위를 변경할 수 있습니다.

사전 요구 사항:

- 그룹에 대한 Owner 역할이 있어야 합니다.
- 프로젝트 및 하위 그룹은 이미 상위 그룹의 새로운 설정만큼 제한적인 공개 범위 설정을 가져야 합니다. 예를 들어, 그룹의 프로젝트 또는 하위 그룹이 공개인 경우 그룹을 비공개로 설정할 수 없습니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **이름, 설명, 공개범위**를 확장합니다.
1. **공개 수준**에 대해 옵션을 선택합니다. 프로젝트의 공개 범위 설정은 최소한 상위 그룹의 공개 범위만큼 제한적이어야 합니다.
1. **변경 사항 저장**을 선택합니다.

## 공개 또는 내부 프로젝트의 사용 제한 {#restrict-use-of-public-or-internal-projects}

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

관리자는 프로젝트 또는 스니펫을 생성할 때 사용자가 선택할 수 있는 공개 수준을 제한할 수 있습니다. 이 설정은 사용자가 실수로 리포지토리를 공개적으로 노출하는 것을 방지하는 데 도움이 됩니다.

자세한 내용은 [공개 수준 제한](../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels)을 참조하세요.
