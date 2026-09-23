---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Free 티어 사용자 및 그룹 제한
---

{{< details >}}

- 티어:  Free
- 제공 서비스: GitLab.com

{{< /details >}}

Free 티어를 사용 중이면 다음의 사용자 및 그룹 제한이 적용됩니다.

## Free 사용자 제한 {#free-user-limit}

GitLab.com에서 새로 생성된 최상위 네임스페이스에 최대 5명의 사용자를 추가할 수 있습니다. 단, 네임스페이스의 가시성이 비공개여야 합니다.

2022년 12월 28일 이전에 생성된 네임스페이스는 2023년 6월 13일에 이 사용자 제한이 적용되었습니다.

5명 이상의 사용자가 있는 최상위 비공개 네임스페이스는 읽기 전용 상태로 설정됩니다. 이러한 네임스페이스는 다음 중 어디에도 새 데이터를 쓸 수 없습니다:

- 리포지토리
- Git Large File Storage(LFS)
- 패키지
- 레지스트리.

제한된 작업의 전체 목록은 [읽기 전용 네임스페이스](read_only_namespaces.md)를 참조하세요.

사용자 제한은 다음의 Free 티어 사용자에게 적용되지 않습니다:

- GitLab.com, 다음 항목의 경우:
  - 공개 최상위 그룹
  - 개인 네임스페이스(기본적으로 공개이므로)
  - 유료 티어
  - 다음의 [커뮤니티 프로그램](https://about.gitlab.com/community/):
    - 오픈소스용 GitLab
    - 교육용 GitLab
    - 스타트업용 GitLab
- [GitLab Self-Managed 구독](../subscriptions/manage_subscription.md)

자세한 내용은 [전문가와 상담](https://page.gitlab.com/usage_limits_help.html)할 수 있습니다.

## 최상위 그룹 제한 {#top-level-group-limits}

2026년 1월 27일 이후 Free 티어에서 생성된 계정은 최대 3개의 최상위 그룹(그룹 네임스페이스)으로 제한됩니다. 사용자의 [개인 네임스페이스](namespace/_index.md#types-of-namespaces)는 이 제한에 포함되지 않습니다. 이 제한은 Ultimate 평가판에 있는 계정에도 적용됩니다.

더 많은 그룹을 만들려면 유료 티어로 업그레이드하세요.

## 네임스페이스 사용자 수 확인 {#determine-namespace-user-counts}

비공개 가시성을 가진 최상위 네임스페이스의 모든 고유 사용자는 5명 사용자 제한에 포함됩니다. 여기에는 네임스페이스 내의 그룹, 서브그룹 및 프로젝트의 모든 사용자가 포함됩니다.

예를 들어 `example-1` 및 `example-2` 두 개의 그룹이 있습니다.

`example-1` 그룹의 구성:

- 하나의 그룹 소유자 `A`.
- 하나의 서브그룹 `subgroup-1`, 멤버 `B` 1명.
  - `subgroup-1`는 `example-1`에서 멤버 `A`를 상속받습니다.
- `subgroup-1` 내에 프로젝트 `project-1` 1개, 멤버 `C`, `D` 2명.
  - `project-1`는 `subgroup-1`에서 멤버 `A`, `B`를 상속받습니다.

네임스페이스 `example-1`는 고유 멤버 4명(`A`, `B`, `C`, `D`)이 있으므로 5명 사용자 제한을 초과하지 않습니다.

`example-2` 그룹의 구성:

- 하나의 그룹 소유자 `A`.
- 하나의 서브그룹 `subgroup-2`, 멤버 `B` 1명.
  - `subgroup-2`는 `example-2`에서 멤버 `A`를 상속받습니다.
- `subgroup-2` 내에 프로젝트 `project-2a` 1개, 멤버 `C`, `D` 2명.
  - `project-2a`는 `subgroup-2`에서 멤버 `A`, `B`를 상속받습니다.
- `subgroup-2` 내에 프로젝트 `project-2b` 1개, 멤버 `E`, `F` 2명.
  - `project-2b`는 `subgroup-2`에서 멤버 `A`, `B`를 상속받습니다.

네임스페이스 `example-2`는 고유 멤버 6명(`A`, `B`, `C`, `D`, `E`, `F`)이 있으므로 5명 사용자 제한을 초과합니다.

## 그룹 네임스페이스에서 멤버 관리 {#manage-members-in-your-group-namespace}

Free 사용자 제한을 관리하는 데 도움이 되도록, 네임스페이스 내의 모든 프로젝트 및 그룹에서 멤버의 총 수를 확인하고 관리할 수 있습니다.

사전 요구 사항:

- 그룹에 대한 소유자 역할이 있어야 합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **설정** > **사용 할당량**을 선택합니다.
1. 모든 멤버를 보려면 **좌석** 탭을 선택합니다.

이 페이지에서 네임스페이스의 모든 멤버를 확인하고 관리할 수 있습니다. 예를 들어 멤버를 제거하려면 **사용자 삭제**를 선택합니다.

## 그룹을 조직의 구독에 포함 {#include-a-group-in-an-organizations-subscription}

조직에 여러 그룹이 있는 경우 유료(Premium 또는 Ultimate 티어) 및 Free 티어 구독이 혼합되어 있을 수 있습니다. Free 티어 구독이 있는 그룹이 사용자 제한을 초과하면 네임스페이스가 [읽기 전용](read_only_namespaces.md)이 됩니다.

Free 티어 구독이 있는 그룹에서 사용자 제한을 제거하려면 해당 그룹을 조직의 구독에 포함합니다:

1. 그룹이 구독에 포함되어 있는지 확인하려면 [해당 그룹의 구독 세부사항 확인](../subscriptions/manage_subscription.md#view-subscription)하세요.

   그룹에 Free 티어 구독이 있으면 조직의 구독에 포함되지 않습니다.

1. 그룹을 유료 Premium 또는 Ultimate 티어 구독에 포함시키려면 [해당 그룹을 전송](group/manage.md#transfer-a-group)하여 조직의 최상위 네임스페이스로 이동합니다.

Premium 또는 Ultimate 티어의 유료 구독이 있음에도 불구하고 그룹에 5명 사용자 제한이 적용된 경우 다음 중 하나에 [구독이 연결](../subscriptions/manage_subscription.md#link-subscription-to-a-group)되어 있는지 확인합니다:

- 올바른 최상위 네임스페이스.
- 사용자의 [고객 포털](../subscriptions/billing_account.md) 계정.

### 전송된 그룹이 구독 비용에 미치는 영향 {#impact-of-transferred-groups-on-subscription-costs}

그룹을 조직의 구독으로 전송하면 좌석 수가 증가할 수 있습니다. 이로 인해 구독에 대한 추가 비용이 발생할 수 있습니다.

예를 들어 회사에 그룹 A와 그룹 B가 있습니다:

- 그룹 A는 유료 Premium 또는 Ultimate 티어 구독을 가지고 있으며 5명의 사용자가 있습니다.
- 그룹 B는 Free 티어 구독을 가지고 있으며 8명의 사용자가 있고, 이 중 4명은 그룹 A의 멤버입니다.
- 그룹 B는 5명 사용자 제한을 초과하므로 읽기 전용 상태입니다.
- 읽기 전용 상태를 제거하기 위해 그룹 B를 회사의 구독으로 전송합니다.
- 회사는 그룹 A의 멤버가 아닌 그룹 B의 4명 멤버에 대해 4개 좌석의 추가 비용을 부담합니다.

최상위 네임스페이스에 포함되지 않은 사용자는 활성 상태로 유지하려면 추가 좌석이 필요합니다. 자세한 내용은 [구독에 대한 좌석 구매](../subscriptions/manage_seats.md#buy-more-seats)를 참조하세요.

## 5명 사용자 제한 증가 {#increase-the-five-user-limit}

GitLab.com의 Free 구독 티어에서는 비공개 가시성을 가진 최상위 그룹의 5명 사용자 제한을 늘릴 수 없습니다.

더 큰 팀의 경우 유료 Premium 또는 Ultimate 티어로 업그레이드해야 합니다. 이러한 티어는 사용자 수를 제한하지 않으며 팀 생산성을 높일 수 있는 더 많은 기능을 제공합니다. 자세한 내용은 [GitLab Self-Managed에서 구독 티어 업그레이드](../subscriptions/manage_subscription.md#upgrade-subscription-tier)를 참조하세요.

업그레이드하기 전에 유료 티어를 시도해 보려면 GitLab Ultimate의 [무료 평가판](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com/user/free_user_limit/)을 시작하세요.

## 그룹 네임스페이스 외 개인 프로젝트에서 멤버 관리 {#manage-members-in-personal-projects-outside-a-group-namespace}

개인 프로젝트는 최상위 그룹 네임스페이스에 위치하지 않습니다. 각 개인 프로젝트의 사용자를 관리할 수 있습니다. 개인 프로젝트에는 5명 이상의 사용자를 보유할 수 있습니다.

[개인 프로젝트를 그룹으로 이동](../tutorials/move_personal_project_to_group/_index.md)하여 다음을 수행할 수 있습니다:

- 사용자 수를 5명 이상으로 늘립니다.
- 유료 티어 구독, 추가 컴퓨팅 시간 또는 스토리지를 구매합니다.
- 그룹에서 [GitLab 기능](https://about.gitlab.com/pricing/feature-comparison/)을 사용합니다.
- GitLab Ultimate의 [무료 평가판](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com/user/free_user_limit/)을 시작합니다.
