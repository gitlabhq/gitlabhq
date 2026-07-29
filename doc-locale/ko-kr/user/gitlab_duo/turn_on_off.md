---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "인스턴스, 그룹 및 프로젝트에 대해 GitLab Duo 기능을 끕니다."
title: GitLab Duo 가용성 제어
---

{{< details >}}

- 티어: Premium, Ultimate
- 추가 기능: GitLab Duo Core, Pro 또는 Enterprise
- 제공 서비스: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 16.10에서 [AI 기능을 켜고 끄는 설정이 도입](https://gitlab.com/groups/gitlab-org/-/epics/12404)되었습니다.
- GitLab 16.11에서 [AI 기능을 켜고 끄는 설정이 UI에 추가](https://gitlab.com/gitlab-org/gitlab/-/issues/441489)되었습니다. 

{{< /history >}}

GitLab Duo는 기본적으로 켜져 있습니다. GitLab Duo에는 [기능 세트](feature_summary.md)가 포함되어 있습니다.

GitLab Duo를 켜거나 끌 수 있습니다.

- GitLab.com:  최상위 그룹, 기타 그룹 또는 하위 그룹 및 프로젝트의 경우.
- GitLab Self-Managed:  인스턴스, 그룹 또는 하위 그룹 및 프로젝트의 경우.
- GitLab Dedicated에서: 관리자는 특정 하위 그룹을 **항상 꺼짐**으로 잠금하여 소유자 역할이 있는 사용자가 해당 하위 그룹에서 GitLab Duo를 활성화할 수 없도록 할 수 있습니다.

## GitLab Duo 켜짐 잠금 {#lock-gitlab-duo-on}

{{< history >}}

- GitLab 19.1에서 [도입](https://gitlab.com/groups/gitlab-org/-/work_items/21844)되었습니다.

{{< /history >}}

그룹 또는 프로젝트 설정에 관계없이 모든 사용자에 대해 GitLab Duo를 켭니다.

GitLab Duo 가용성을 **항상 켜짐**으로 설정하면 실험적 기능과 베타 기능이 자동으로 켜지지 않습니다. 실험적 기능과 베타 기능을 사용하려면 [별도로 켜야 합니다](#turn-on-beta-and-experimental-features).

{{< tabs >}}

{{< tab title="GitLab.com" >}}

전제 조건:

- 최상위 그룹의 Owner 역할.

최상위 그룹에 대해 GitLab Duo를 켜짐으로 잠그려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **GitLab Duo 가용성** 아래에서 **항상 켜짐**을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

GitLab Duo는 모든 하위 그룹 및 프로젝트에 대해 켜짐으로 잠깁니다. 하위 그룹 또는 프로젝트의 Owner 역할을 가진 사용자는 GitLab Duo를 끌 수 없습니다.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

인스턴스에 대해 GitLab Duo를 켜짐으로 잠그려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **GitLab Duo 가용성** 아래에서 **항상 켜짐**을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

GitLab Duo는 모든 그룹, 하위 그룹 및 프로젝트에 대해 켜짐으로 잠깁니다. 그룹, 하위 그룹 또는 프로젝트의 Owner 역할을 가진 사용자는 GitLab Duo를 끌 수 없습니다.

{{< /tab >}}

{{< /tabs >}}

## 선택한 하위 그룹에 대해 GitLab Duo 잠금 해제 {#lock-gitlab-duo-off-for-selected-subgroups}

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab Dedicated, GitLab Dedicated for Government

{{< /details >}}

{{< history >}}

- [GitLab 19.2에서 도입됨](https://gitlab.com/groups/gitlab-org/-/work_items/22389).

{{< /history >}}

GitLab Dedicated 관리자는 특정 하위 그룹을 GitLab Duo 및 GitLab Duo Agent Platform에 대해 **항상 꺼짐**으로 잠금할 수 있습니다. 해당 하위 그룹의 소유자 역할이 있는 사용자는 GitLab Duo를 활성화할 수 없으며, 다른 하위 그룹은 소유자 제어 상태로 유지됩니다.

잠금은 하위 그룹 및 모든 하위 그룹과 프로젝트에 적용됩니다. 하위 그룹 또는 그 하위 항목의 소유자 역할이 있는 사용자는 이 설정을 변경할 수 없습니다. 영향을 받은 소유자는 GitLab Duo가 상위 그룹에 의해 잠금되었다는 메시지를 봅니다.

상위 및 하위 그룹의 체인에는 하나의 잠금만 존재할 수 있습니다. 하위 그룹을 잠금할 때:

- 상위 그룹에 이미 잠금이 있는 경우 잠금이 적용되지 않습니다. 먼저 상위 그룹에서 [잠금을 해제](#clear-the-lock-for-a-subgroup)해야 합니다.
- 하나 이상의 하위 그룹에 이미 관리자 잠금이 있는 경우 확인하라는 메시지가 표시됩니다. 확인하면 해당 하위 그룹의 잠금이 해제되고 선택한 하위 그룹에 잠금이 적용됩니다.

### 하위 그룹 잠금 {#lock-a-subgroup}

전제 조건:

- GitLab Dedicated 인스턴스에 대한 관리자 액세스 권한.

하위 그룹에 대해 GitLab Duo를 잠금하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **Namespace availability overrides** 섹션에서 하위 그룹을 찾습니다.
1. 하위 그룹의 행에서 **GitLab Duo 가용성** 아래의 **항상 꺼짐**을 선택합니다.

### 하위 그룹에 대한 잠금 해제 {#clear-the-lock-for-a-subgroup}

전제 조건:

- GitLab Dedicated 인스턴스에 대한 관리자 액세스 권한.

하위 그룹에 대한 관리자 잠금을 해제하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **Namespace availability overrides** 섹션에서 하위 그룹을 찾습니다.
1. 하위 그룹의 행에서 **재설정**을 선택합니다.

하위 그룹이 인스턴스 기본값으로 돌아갑니다. 하위 그룹의 소유자 역할이 있는 사용자는 이제 GitLab Duo 가용성을 제어할 수 있습니다.

## GitLab Duo 켜기 또는 끄기 {#turn-gitlab-duo-on-or-off}

### GitLab.com {#on-gitlabcom}

#### 최상위 그룹의 경우 {#for-a-top-level-group}

전제 조건:

- 최상위 그룹의 Owner 역할.

최상위 그룹에 대한 GitLab Duo 가용성을 변경하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **GitLab Duo 가용성** 아래에서 옵션을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

GitLab Duo 가용성이 모든 하위 그룹 및 프로젝트에 대해 변경됩니다.

#### 그룹 또는 하위 그룹의 경우 {#for-a-group-or-subgroup}

전제 조건:

- 그룹 또는 하위 그룹의 Owner 역할.

그룹 또는 하위 그룹에 대한 GitLab Duo 가용성을 변경하려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 그룹 또는 하위 그룹을 찾습니다.
1. **설정** > **일반**을 선택합니다.
1. **GitLab Duo 기능**을 확장합니다.
1. **GitLab Duo 가용성** 아래에서 옵션을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

GitLab Duo 가용성이 모든 하위 그룹 및 프로젝트에 대해 변경됩니다.

#### 프로젝트의 경우 {#for-a-project}

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.

프로젝트에 대한 GitLab Duo 가용성을 변경하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **GitLab Duo**를 확장합니다.
1. **GitLab Duo** 토글을 켜거나 끕니다.
1. **변경 사항 저장**을 선택합니다.

### GitLab Self-Managed {#on-gitlab-self-managed}

#### 인스턴스의 경우 {#for-an-instance}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

인스턴스에 대한 GitLab Duo 가용성을 변경하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **GitLab Duo 가용성** 아래에서 옵션을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

#### 그룹 또는 하위 그룹의 경우 {#for-a-group-or-subgroup-1}

전제 조건:

- 그룹 또는 하위 그룹의 Owner 역할.

그룹 또는 하위 그룹에 대한 GitLab Duo 가용성을 변경하려면:

1. 상단 막대에서 **검색 또는 이동**을 선택하고 그룹 또는 하위 그룹을 찾습니다.
1. **설정** > **일반**을 선택합니다.
1. **GitLab Duo 기능**을 확장합니다.
1. **GitLab Duo 가용성** 아래에서 옵션을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

GitLab Duo 가용성이 모든 하위 그룹 및 프로젝트에 대해 변경됩니다.

#### 프로젝트의 경우 {#for-a-project-1}

전제 조건:

- 프로젝트에 대한 Maintainer 또는 Owner 역할.

프로젝트에 대한 GitLab Duo 가용성을 변경하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **GitLab Duo**를 확장합니다.
1. **GitLab Duo** 토글을 켜거나 끕니다.
1. **변경 사항 저장**을 선택합니다.

### 이전 GitLab 버전의 경우 {#for-earlier-gitlab-versions}

이전 GitLab 버전에서 GitLab Duo를 켜거나 끄는 방법에 대한 정보는 [이전 GitLab 버전에 대한 GitLab Duo 가용성 제어](turn_on_off_earlier.md)를 참조하세요.

## GitLab Duo Core 켜기 또는 끄기 {#turn-gitlab-duo-core-on-or-off}

{{< history >}}

- GitLab 18.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/538857)되었습니다.
- GitLab Duo 가용성 설정 및 그룹, 하위 그룹 및 프로젝트 제어가 GitLab 18.2에 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/551895)되었습니다.
- GitLab Duo Non-Agentic Chat이 GitLab 18.3에서 GitLab Duo Core에 [추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201721)되었습니다.

{{< /history >}}

GitLab Duo Core는 Premium 및 Ultimate 구독에 포함되어 있습니다.

- GitLab 17.11 이전의 기존 고객인 경우 GitLab Duo Core에 대한 기능을 켜야 합니다.
- GitLab 18.0 이상의 신규 고객인 경우 GitLab Duo Core가 자동으로 켜져 있으며 추가 작업이 필요하지 않습니다.

2025년 5월 15일 이전에 Premium 또는 Ultimate 구독이 있는 기존 고객이었다면, GitLab 18.0 이상으로 업그레이드할 때 GitLab Duo Core를 사용하려면 이를 켜야 합니다.

### GitLab.com {#on-gitlabcom-1}

전제 조건:

- 최상위 그룹의 Owner 역할.

최상위 그룹에 대한 GitLab Duo Core 가용성을 변경하려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 최상위 그룹을 찾습니다.
1. **설정** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **GitLab Duo 가용성** 아래에서 옵션을 선택합니다.
1. **GitLab Duo 코어** 아래에서 **GitLab Duo Core를 위한 기능 켜기** 체크박스를 선택하거나 선택 해제합니다. GitLab Duo 가용성에 대해 **항상 꺼짐**을 선택한 경우 이 설정에 액세스할 수 없습니다.
1. **변경 사항 저장**을 선택합니다.

변경 사항이 적용되는 데 최대 10분이 소요될 수 있습니다.

### GitLab Self-Managed {#on-gitlab-self-managed-1}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

인스턴스에 대한 GitLab Duo Core 가용성을 변경하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **GitLab Duo 가용성** 아래에서 옵션을 선택합니다.
1. **GitLab Duo 코어** 아래에서 **GitLab Duo Core를 위한 기능 켜기** 체크박스를 선택하거나 선택 해제합니다. GitLab Duo 가용성에 대해 **항상 꺼짐**을 선택한 경우 이 설정에 액세스할 수 없습니다.
1. **변경 사항 저장**을 선택합니다.

## 베타 및 실험적 기능 켜기 {#turn-on-beta-and-experimental-features}

실험적 기능 및 베타 단계인 GitLab Duo 기능은 기본적으로 꺼져 있습니다. 이 기능들은 [테스팅 계약](https://handbook.gitlab.com/handbook/legal/testing-agreement/)의 적용을 받습니다.

### GitLab.com {#on-gitlabcom-2}

전제 조건:

- 최상위 그룹의 Owner 역할.

최상위 그룹에 대한 GitLab Duo 실험적 기능 및 베타 기능을 켜려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택합니다.
1. **기능 미리보기** 아래에서 **실험적 기능과 베타 GitLab Duo 기능 활성화**를 선택합니다.
1. **변경 사항 저장**을 선택합니다.

이 설정은 그룹에 속한 [모든 프로젝트에 적용됨](../project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group).

### GitLab Self-Managed {#on-gitlab-self-managed-2}

{{< tabs >}}

{{< tab title="17.4 이상" >}}

GitLab 17.4 이상에서는 이 지침을 따라 GitLab Self-Managed 인스턴스에 대한 GitLab Duo 실험적 기능 및 베타 기능을 켭니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

인스턴스에 대한 GitLab Duo 실험적 기능 및 베타 기능을 켜려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 확장합니다.
1. **기능 미리보기** 아래에서 **실험적 기능과 베타 GitLab Duo 기능 사용**을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

{{< /tab >}}

{{< tab title="17.3 이전" >}}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.
- [네트워크 연결](../../administration/gitlab_duo/configure/_index.md)이 활성화되었습니다.
- [자동 모드](../../administration/silent_mode/_index.md) 꺼짐.

인스턴스에 대한 GitLab Duo 실험적 기능 및 베타 기능을 켜려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **GitLab Duo**를 선택합니다.
1. **구성 변경**을 확장합니다.
1. **기능 미리보기** 아래에서 **실험적 기능과 베타 GitLab Duo 기능 사용**을 선택합니다.
1. **변경 사항 저장**을 선택합니다.
1. GitLab Duo Chat가 즉시 작동하려면 [수동으로 구독을 동기화](../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data)합니다.

   구독을 수동으로 동기화하지 않으면 인스턴스에서 GitLab Duo Chat을 활성화하는 데 최대 24시간이 소요될 수 있습니다.

{{< /tab >}}

{{< /tabs >}}
