---
stage: Security Governance
group: AI Control Plane
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 이전 GitLab 버전의 GitLab Duo 가용성 제어
---

{{< details >}}

- 티어:  Premium, Ultimate
- 추가 기능: GitLab Duo Pro 또는 Enterprise
- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

GitLab Duo Pro 또는 Enterprise의 경우 그룹, 프로젝트 또는 인스턴스에서 GitLab Duo를 켜거나 끌 수 있습니다.

> [!note]
> 이 정보는 GitLab 18.1 이하에 적용됩니다. GitLab 18.2 이상의 경우 [최신 설명서](turn_on_off.md)를 확인하세요.

그룹, 프로젝트 또는 인스턴스에서 GitLab Duo가 꺼진 경우:

- 코드, 이슈, 취약점 등의 리소스에 액세스하는 GitLab Duo 기능은 사용할 수 없습니다.
- Code Suggestions는 사용할 수 없습니다.
- GitLab Duo Chat는 사용할 수 없습니다.

## 그룹 또는 하위 그룹의 경우 {#for-a-group-or-subgroup}

{{< tabs >}}

{{< tab title="17.8~18.1" >}}

GitLab 17.8~18.1에서 하위 그룹 및 프로젝트를 포함한 그룹에서 GitLab Duo를 켜거나 끄려면 다음 지시사항을 따릅니다.

사전 요구 사항:

- 그룹에 대한 소유자 역할이 있어야 합니다.

그룹 또는 하위 그룹에서 GitLab Duo를 켜거나 끄려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 그룹 또는 하위 그룹을 찾습니다.
1. 배포 유형 및 그룹 수준에 따라 설정으로 이동합니다:
   - GitLab.com 최상위 그룹의 경우: **설정** > **GitLab Duo**를 선택한 후 **구성 변경**을 선택합니다.
   - GitLab.com 하위 그룹의 경우: **설정** > **일반**을 선택한 후 **GitLab Duo 기능**을 펼칩니다.
   - GitLab Self-Managed(모든 그룹 및 하위 그룹)의 경우: **설정** > **일반**을 선택한 후 **GitLab Duo 기능**을 펼칩니다.
1. 옵션을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< tab title="17.7" >}}

GitLab 17.7에서 하위 그룹 및 프로젝트를 포함한 그룹에서 GitLab Duo를 켜거나 끄려면 다음 지시사항을 따릅니다.

> [!note]
> GitLab 17.7:
>
> - GitLab.com의 경우 GitLab Duo 설정 페이지는 최상위 그룹에만 사용 가능하며 하위 그룹에는 사용 가능하지 않습니다.
> - GitLab Self-Managed의 경우 GitLab Duo 설정 페이지는 그룹 또는 하위 그룹에 사용할 수 없습니다.

사전 요구 사항:

- 그룹에 대한 소유자 역할이 있어야 합니다.

최상위 그룹에서 GitLab Duo를 켜거나 끄려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. 옵션을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< tab title="17.4~17.6" >}}

GitLab 17.4~17.6에서 그룹과 하위 그룹 및 프로젝트에서 GitLab Duo를 켜거나 끄려면 다음 지시사항을 따릅니다.

> [!note]
> GitLab 17.4~17.6:
>
> - GitLab.com의 경우 GitLab Duo 설정 페이지는 최상위 그룹에만 사용 가능하며 하위 그룹에는 사용 가능하지 않습니다.
> - GitLab Self-Managed의 경우 GitLab Duo 설정 페이지는 그룹 또는 하위 그룹에 사용할 수 없습니다.

사전 요구 사항:

- 그룹에 대한 소유자 역할이 있어야 합니다.

최상위 그룹에서 GitLab Duo를 켜거나 끄려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. 옵션을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< tab title="17.3 이전" >}}

GitLab 17.3 이하에서 그룹과 하위 그룹 및 프로젝트에서 GitLab Duo를 켜거나 끄려면 다음 지시사항을 따릅니다.

사전 요구 사항:

- 그룹에 대한 소유자 역할이 있어야 합니다.

그룹 또는 하위 그룹에서 GitLab Duo를 켜거나 끄려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 그룹 또는 하위 그룹을 찾습니다.
1. **설정** > **일반**을 선택합니다.
1. **권한 및 그룹 기능**을 확장합니다.
1. **GitLab Duo 기능 사용** 확인란을 선택하거나 선택 해제합니다.
1. 선택 사항입니다. **모든 하위 그룹에 대해 적용** 확인란을 선택하여 설정을 모든 하위 그룹에 적용합니다.

   ![설정 연쇄 적용](img/disable_duo_features_v17_1.png)

{{< /tab >}}

{{< /tabs >}}

## 프로젝트의 경우 {#for-a-project}

{{< tabs >}}

{{< tab title="17.4~18.1" >}}

GitLab 17.4~18.1에서 프로젝트에서 GitLab Duo를 켜거나 끄려면 다음 지시사항을 따릅니다.

사전 요구 사항:

- 프로젝트에 대해 유지 관리자 또는 소유자 역할이 있어야 합니다.

프로젝트에서 GitLab Duo를 켜거나 끄려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
1. **GitLab Duo** 아래에서 토글을 켜거나 끕니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< tab title="17.3 이전" >}}

GitLab 17.3 이하에서 프로젝트에서 GitLab Duo를 켜거나 끄려면 다음 지시사항을 따릅니다.

1. GitLab GraphQL API [`projectSettingsUpdate`](../../api/graphql/reference/_index.md#mutationprojectsettingsupdate) 변이를 사용합니다.
1. [`duo_features_enabled`](../../api/graphql/getting_started.md#update-project-settings) 설정을 `true` 또는 `false`로 설정합니다.

{{< /tab >}}

{{< /tabs >}}

## 인스턴스의 경우 {#for-an-instance}

{{< details >}}

- 제공 서비스: GitLab Self-Managed

{{< /details >}}

{{< tabs >}}

{{< tab title="17.7~18.1" >}}

GitLab 17.7~18.1에서 인스턴스에서 GitLab Duo를 켜거나 끄려면 다음 지시사항을 따릅니다.

사전 요구 사항:

- 관리자 권한이 있어야 합니다.

인스턴스에서 GitLab Duo를 켜거나 끄려면:

1. 오른쪽 위 모서리에서 **관리자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. 옵션을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< tab title="17.4~17.6" >}}

GitLab 17.4~17.6에서 인스턴스에서 GitLab Duo를 켜거나 끄려면 다음 지시사항을 따릅니다.

사전 요구 사항:

- 관리자 권한이 있어야 합니다.

인스턴스에서 GitLab Duo를 켜거나 끄려면:

1. 오른쪽 위 모서리에서 **관리자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **GitLab Duo 기능**을 확장합니다.
1. 옵션을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< tab title="17.3 이전" >}}

GitLab 17.3 이하에서 인스턴스에서 GitLab Duo를 켜거나 끄려면 다음 지시사항을 따릅니다.

사전 요구 사항:

- 관리자 권한이 있어야 합니다.

인스턴스에서 GitLab Duo를 켜거나 끄려면:

1. 왼쪽 사이드바의 맨 아래에서 **운영자 영역**을 선택합니다.
1. **설정** > **일반**을 선택합니다.
1. **AI 기반 기능**을 펼칩니다.
1. **Duo 기능 사용** 확인란을 선택하거나 선택 해제합니다.
1. 선택 사항입니다. **모든 하위 그룹에 대해 적용** 확인란을 선택하여 설정을 인스턴스의 모든 그룹에 적용합니다.

{{< /tab >}}

{{< /tabs >}}
