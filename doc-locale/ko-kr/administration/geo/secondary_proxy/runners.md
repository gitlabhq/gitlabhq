---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: 보조 러너
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `geo_proxy_check_pipeline_refs`라는 이름의 [플래그와 함께](../../feature_flags/_index.md) GitLab 16.8에서 [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/9779). 기본적으로 비활성화됨.
- [GitLab 16.9에서 기본적으로 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/434041)

{{< /history >}}

[보조 사이트용 Geo 프록시](_index.md)를 사용하면 `gitlab-runner`을 보조 사이트에 등록할 수 있습니다. 이를 통해 기본 인스턴스의 부하를 줄입니다.

> [!note]
> 파이프라인의 첫 번째 스테이지 중에 시작되는 작업은 거의 항상 Git 클론 요청이 기본 사이트로 전달됩니다. 이는 보조 사이트에서 Git 데이터를 복제하고 확인하기 전에 해당 클론이 일반적으로 발생하기 때문입니다. 이후 스테이지도 보조 사이트에서 제공된다고 보장할 수 없습니다. 예를 들어 Git 변경 사항이 크거나 대역폭이 작거나 파이프라인 스테이지가 짧은 경우입니다. 대부분의 경우 파이프라인의 이후 스테이지는 보조 사이트에서 Git 데이터를 제공합니다. [이슈 446176](https://gitlab.com/gitlab-org/gitlab/-/issues/446176)은 첫 번째 스테이지 클론 요청이 보조 사이트에서 제공될 가능성을 높이기 위한 개선 사항을 제안합니다.

## 위치 인식 공개 URL(통합 URL)을 사용하는 보조 러너 {#use-secondary-runners-with-a-location-aware-public-url-unified-url}

{{< details >}}

- 제공:  GitLab Self-Managed

{{< /details >}}

[위치 인식 DNS](_index.md#configure-location-aware-dns)를 사용하고 기능 플래그가 활성화된 경우 추가 구성 없이 작동합니다. 보조 사이트와 같은 위치에 러너를 설치하고 등록한 후 가장 가까운 사이트로 자동 연결되며, 보조 사이트가 만료된 경우에만 기본 사이트로 프록시합니다.

## 별도의 URL을 사용하는 보조 러너 {#use-secondary-runners-with-separate-urls}

별도의 보조 URL을 사용하는 경우 러너는 다음과 같이 구성해야 합니다:

1. 보조 외부 URL로 등록합니다.
1. [`clone_url`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#how-clone_url-works)를 보조 인스턴스의 `external_url`로 설정합니다.

## 보조 러너를 사용한 계획된 페일오버 처리 {#handling-a-planned-failover-with-secondary-runners}

[계획된 페일오버](../disaster_recovery/planned_failover.md)를 실행할 때 보조 러너는 로컬 인스턴스와의 통신을 계속 시도합니다. 이로 인해 러너 용량이 감소하며 이를 고려해야 할 수 있습니다.

### 위치 인식 공개 URL {#with-location-aware-public-url}

{{< details >}}

- 제공:  GitLab Self-Managed

{{< /details >}}

[위치 인식 DNS](_index.md#configure-location-aware-dns)를 사용하는 경우 모든 러너가 가장 가까운 Geo 사이트로 자동 연결됩니다.

새로운 기본 사이트로 페일오버할 때:

- 이전 기본 사이트가 여전히 DNS 레코드에 있는 동안 이전 기본 사이트에 이전에 연결된 러너는 여전히 이전 기본 사이트에서 작업을 선택하려고 시도합니다. 도달할 수 없는 경우 러너가 [이를 감지](https://docs.gitlab.com/runner/configuration/advanced-configuration/#how-unhealthy_requests_limit-and-unhealthy_interval-works)하고 인스턴스가 반환된 후 연장된 기간 동안 요청을 중지합니다.
- [여러 보조 노드](../disaster_recovery/_index.md#promoting-secondary-geo-replica-in-multi-secondary-configurations) 가 있는 경우 초기 페일오버 후 남은 보조 사이트는 새로운 기본 사이트로 [복제](../disaster_recovery/_index.md#step-2-initiate-the-replication-process)될 때까지 비정상 상태입니다. 이 경우 러너는 체크 인할 수 없으며 상태 확인도 시작됩니다.
- Geo DNS 항목에서 비정상 노드를 제거하면 러너가 다음으로 가장 가까운 인스턴스를 선택합니다. 아키텍처에 따라 이것이 원하는 것이 아닐 수 있습니다. 축소된 상태의 사이트를 압도할 수 있기 때문입니다.

이러한 문제를 해결하려면 사이트가 100%로 복구될 때까지 [일시 중지](#pausing-runners)하거나 일부 러너를 종료할 수 있습니다.

이러한 문제가 걱정되지 않으면 여기서 수행할 작업이 없습니다.

### 별도의 URL 사용 {#with-separate-urls}

- 이전 기본 사이트를 서비스로 반환하는 경우 다시 온라인 상태가 될 때까지 이전 기본 러너를 일시 중지할 수 있습니다. 이렇게 하면 상태 확인이 시작되지 않습니다.
- 이전 기본 사이트가 반환되지 않거나 일시적으로 감소한 러너 용량을 피하려는 경우 기본 러너를 새로운 기본 사이트에 연결되도록 재구성해야 합니다.
- 여러 보조 사이트를 사용하는 경우 새로운 기본 사이트로 복제되는 동안 러너를 [일시 중지](#pausing-runners)하거나 종료하거나 새로운 기본 사이트에 연결되도록 재구성해야 합니다.

### 러너 일시 중지 {#pausing-runners}

다음 방법을 사용하려면 관리자 액세스 권한이 있어야 합니다:

- **운영자** 영역을 통해:
  1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
  1. **설정** > **러너**를 선택합니다.
  1. 일시 중지하려는 러너를 식별합니다.
  1. 일시 중지하려는 각 러너 옆의 `pause` 버튼을 선택합니다.
  1. 페일오버가 완료된 후 이전 단계에서 일시 중지한 러너를 재개합니다.
- [러너 API](../../../api/runners.md)를 사용합니다:
  1. 관리자 액세스 권한이 있는 [개인 액세스 토큰](../../../user/profile/personal_access_tokens.md)을 가져오거나 생성합니다.
  1. 러너 목록을 가져옵니다. [API를 사용](../../../api/runners.md#list-all-runners)하여 목록을 필터링할 수 있습니다.
  1. 일시 중지하려는 러너를 식별하고 해당 `id`을 기록합니다.
  1. [API 설명서를 따르고](../../../api/runners.md#pause-a-runner) 각 러너를 일시 중지합니다.
  1. 페일오버가 완료된 후 `paused=false`을 설정하여 API를 사용하여 러너 목록을 재개합니다.
