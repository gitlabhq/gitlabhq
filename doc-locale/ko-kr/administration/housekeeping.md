---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 정리
description: Git 리포지토리에 대한 정리 작업입니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab은 Git 리포지토리에서 정리 작업을 지원하고 자동화하여 가능한 한 효율적으로 제공할 수 있도록 합니다. 정리 작업에는 다음이 포함됩니다:

- Git 객체 및 리비전 압축
- 도달할 수 없는 객체 제거
- 잠금 파일과 같은 오래된 데이터 제거
- 성능을 개선하는 데이터 구조 유지
- 포크 전체에서 객체 중복 제거를 개선하도록 객체 풀 업데이트

> [!warning]
> GitLab에서 제어하는 Git 리포지토리에서 정리를 수행하기 위해 Git 명령을 수동으로 실행하지 마세요. 이렇게 하면 리포지토리 손상 및 데이터 손실이 발생할 수 있습니다.

## 정리 전략 {#housekeeping-strategy}

Gitaly는 두 가지 방법으로 Git 리포지토리에서 정리 작업을 수행할 수 있습니다:

- [즉시 정리](#eager-housekeeping)는 리포지토리의 상태와 관계없이 특정 정리 작업을 실행합니다.
- [휴리스틱 정리](#heuristical-housekeeping)는 리포지토리 상태를 기반으로 실행해야 할 정리 작업을 결정하는 휴리스틱 집합을 기반으로 정리 작업을 실행합니다.

### 즉시 정리 {#eager-housekeeping}

"즉시" 정리 전략은 리포지토리 상태와 관계없이 리포지토리에서 정리 작업을 실행합니다. 이것은 [수동 트리거](#manual-trigger) 및 푸시 기반 트리거에서 사용되는 기본 전략입니다.

즉시 정리 전략은 GitLab 애플리케이션에 의해 제어됩니다. 정리 작업을 실행하게 한 트리거에 따라 GitLab은 Gitaly에 특정 정리 작업을 수행하도록 요청합니다. Gitaly는 리포지토리가 최적화된 상태에 있어도 이러한 작업을 수행합니다. 결과적으로 이 전략은 정리 작업 수행이 느릴 수 있는 큰 리포지토리에서 비효율적일 수 있습니다.

### 휴리스틱 정리 {#heuristical-housekeeping}

{{< history >}}

- [GitLab 14.9에서 도입됨](https://gitlab.com/gitlab-org/gitaly/-/issues/2634) - [수동 트리거](#manual-trigger) 및 푸시 기반 트리거 [플래그 포함](feature_flags/_index.md) 이름: `optimized_housekeeping` 기본적으로 활성화됨.
- [GitLab.com에서 활성화됨](https://gitlab.com/gitlab-org/gitlab/-/issues/353607) \- GitLab 14.10
- [일반적으로 사용 가능함](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107661) \- GitLab 15.8 기능 플래그 `optimized_housekeeping` 제거됨.

{{< /history >}}

휴리스틱(또는 "기회주의적") 정리 전략은 리포지토리 상태를 분석하고 하나 이상의 데이터 구조가 충분히 최적화되지 않은 경우에만 정리 작업을 실행합니다. 이것은 [예약된 정리](#scheduled-housekeeping)에서 사용되는 전략입니다.

휴리스틱 정리는 다음 정보를 사용하여 실행해야 할 작업을 결정합니다:

- 느슨하고 오래된 객체의 개수
- 이미 압축된 객체를 포함하는 팩파일의 개수
- 느슨한 참조의 개수
- 커밋 그래프의 존재 여부

분석된 데이터 구조를 최적화해야 하는지 여부는 리포지토리의 크기에 따라 결정됩니다:

- 모든 객체의 총 크기가 클수록 객체가 더 자주 다시 압축됩니다.
- 전체 참조가 많을수록 참조가 덜 자주 다시 압축됩니다.

Gitaly는 데이터 구조를 최적화하는 데 걸리는 시간이 구조가 커질수록 더 오래 걸린다는 사실을 상쇄하기 위해 이를 수행합니다. 특히 많은 트래픽을 받는 대규모 모노레포에서는 너무 자주 최적화되지 않도록 하는 것이 중요합니다.

Gitaly에 리포지토리를 최적화하도록 요청하는 빈도를 변경할 수 있습니다.

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **리포지토리**를 선택하세요.
1. **리포지토리 유지 보수**를 확장하세요.
1. **정리** 섹션에서 정리 옵션을 구성하세요.
1. **변경 사항 저장**을 선택합니다.

- **자동 리포지토리 하우스키핑 활성화**:  정기적으로 Gitaly에 리포지토리 최적화를 실행하도록 요청하세요. 이 설정을 오랫동안 비활성화된 상태로 두면 GitLab 서버의 Git 리포지토리 접근이 느려지고 리포지토리가 더 많은 디스크 공간을 사용하게 됩니다.
- **리포지토리 주기 최적화**:  Gitaly에 리포지토리를 최적화하도록 요청한 후의 Git 푸시 횟수입니다.

## 정리 작업 실행 {#running-housekeeping-tasks}

GitLab이 정리 작업을 실행하는 방법은 여러 가지입니다:

- 리포지토리 관리자는 [수동으로 트리거](#manual-trigger)하여 리포지토리 정리 작업을 수행할 수 있습니다.
- GitLab은 여러 Git 푸시 후에 정리 작업을 자동으로 예약할 수 있습니다.
- GitLab은 [작업 예약](#scheduled-housekeeping)하여 구성 가능한 시간 프레임 내 모든 리포지토리에 대해 정리 작업을 실행할 수 있습니다.

### 수동 트리거 {#manual-trigger}

리포지토리 관리자는 리포지토리에서 정리 작업을 수동으로 트리거할 수 있습니다. 일반적으로 GitLab이 정리 작업을 자동으로 실행하도록 알고 있으므로 이는 필수가 아닙니다. 수동 트리거는 다음과 같은 경우에 유용할 수 있습니다:

- 리포지토리가 정리가 필요한 것으로 알려져 있습니다.
- 정리 작업의 자동 푸시 기반 스케줄링이 비활성화되었습니다.

정리 작업을 수동으로 트리거하려면:

1. 상단 바에서 **Search or go to**를 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **고급**을 확장하세요.
1. **정리 실행**을 선택하세요.

이것은 프로젝트의 리포지토리에 대한 비동기 백그라운드 워커를 시작합니다. 백그라운드 워커는 Gitaly에 여러 최적화를 수행하도록 요청합니다.

정리는 또한 프로젝트에서 매 `200` 푸시마다 [참조되지 않은 LFS 파일을 제거](raketasks/cleanup.md#remove-unreferenced-lfs-files)하여 프로젝트의 저장 공간을 확보합니다.

### 도달할 수 없는 객체 정리 {#prune-unreachable-objects}

도달할 수 없는 객체는 예약된 정리의 일부로 정리됩니다. 그러나 수동 정리를 트리거할 수도 있습니다. 정리를 트리거하면 도달할 수 없는 객체가 2주의 유예 기간으로 정리됩니다. 도달할 수 없는 객체의 정리를 수동으로 트리거하면 유예 기간이 30분으로 단축됩니다.

> [!warning]
> 도달할 수 없는 객체를 정리한다고 해서 유출된 보안 정보 및 기타 민감한 정보의 제거를 보장하지는 않습니다. 커밋되었지만 푸시되지 않은 보안 정보를 제거하는 방법에 대한 정보는 [커밋에서 보안 정보 제거 자습서](../user/application_security/secret_detection/remove_secrets_tutorial.md)를 참조하세요. 추가로 [개별적으로 blob 제거](../user/project/repository/repository_size.md#remove-blobs)할 수 있습니다. 해당 작업 수행의 가능한 결과를 보려면 해당 설명서를 참조하세요.
>
> 동시 프로세스(예: `git push`)가 객체를 생성했지만 아직 객체에 대한 참조를 생성하지 않은 경우, 객체 삭제 후 객체에 대한 참조가 추가되면 리포지토리가 손상될 수 있습니다. 유예 기간은 이러한 경합 조건의 가능성을 줄이기 위해 존재합니다. 예를 들어 종종 매우 느린 연결을 통해 많은 큰 객체를 자주 푸시하는 경우, 도달할 수 없는 객체를 정리하는 것과 관련된 위험이 프로젝트에 회사 내부에서만 액세스할 수 있고 성능이 좋은 연결을 사용하는 회사 환경의 경우보다 훨씬 높습니다. 이 옵션을 사용할 때 프로젝트 사용 프로필을 고려하고 조용한 기간을 선택하세요.

도달할 수 없는 객체를 수동으로 정리하려면:

1. 상단 바에서 **Search or go to**를 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **Settings** > **General**을 선택합니다.
1. **고급**을 확장하세요.
1. **정리 실행**을 선택하세요.
1. 작업 완료를 위해 30분을 기다리세요.
1. **정리 실행**을 선택한 페이지로 돌아가서 **도달할 수 없는 객체 정리**를 선택하세요.

### 예약된 정리 {#scheduled-housekeeping}

{{< details >}}

- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab은 푸시 횟수를 기반으로 자동으로 정리 작업을 수행하지만, 푸시를 받지 않는 리포지토리는 유지하지 않습니다. 결과적으로, 휴면 리포지토리 또는 읽기 요청만 받는 리포지토리는 리포지토리 정리 전략의 개선 사항으로부터 이점을 얻지 못할 수 있습니다.

관리자는 이 상황을 해결하기 위해 사용자 지정 가능한 간격으로 모든 리포지토리에서 정리를 수행하는 백그라운드 작업을 활성화할 수 있습니다. 이 백그라운드 작업은 Gitaly 노드에서 호스팅되는 모든 리포지토리를 무작위 순서로 처리하고 정리 작업을 즉시 수행합니다. Gitaly 노드는 구성된 간격보다 오래 걸리면 리포지토리 처리를 중지합니다.

#### 예약된 정리 구성 {#configure-scheduled-housekeeping}

Git 리포지토리의 백그라운드 유지 보수는 Gitaly에서 구성됩니다. 기본적으로 Gitaly는 매일 정오 12:00에 10분 동안 백그라운드 리포지토리 유지 보수를 수행합니다.

Gitaly 구성에서 이 기본값을 변경할 수 있습니다.

Gitaly Cluster(Praefect)가 있는 환경의 경우, 예약된 정리 시작 시간을 Gitaly 노드 전체에 엇갈리게 하여 예약된 정리가 여러 노드에서 동시에 실행되지 않도록 할 수 있습니다.

예약된 정리 실행이 지정된 `duration`에 도달하면 실행 중인 작업이 정상적으로 취소됩니다. 후속 예약된 정리 실행에서 Gitaly는 처리할 리포지토리 목록을 무작위로 섞습니다.

다음 코드 조각을 사용하면 `default` 저장소에 대해 23:00에 시작하여 1시간 동안 매일 백그라운드 리포지토리 유지 보수가 활성화됩니다:

{{< tabs >}}

{{< tab title="직접 컴파일(소스)" >}}

```toml
[daily_maintenance]
start_hour = 23
start_minute = 00
duration = 1h
storages = ["default"]
```

다음 코드 조각을 사용하여 백그라운드 리포지토리 유지 보수를 완전히 비활성화하세요:

```toml
[daily_maintenance]
disabled = true
```

{{< /tab >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```ruby
gitaly['configuration'] = {
  daily_maintenance: {
    disabled: false,
    start_hour: 23,
    start_minute: 00,
    duration: '1h',
    storages: ['default'],
  },
}
```

다음 코드 조각을 사용하여 백그라운드 리포지토리 유지 보수를 완전히 비활성화하세요:

```ruby
gitaly['configuration'] = {
  daily_maintenance: {
    disabled: true,
  },
}
```

{{< /tab >}}

{{< /tabs >}}

예약된 정리가 실행되면 [Gitaly 로그](logs/_index.md#gitaly-logs)에서 다음 항목을 볼 수 있습니다:

```json
# When the scheduled housekeeping starts
{"level":"info","msg":"maintenance: daily scheduled","pid":197260,"scheduled":"2023-09-27T13:10:00+13:00","time":"2023-09-27T00:08:31.624Z"}

# When the scheduled housekeeping completes
{"actual_duration":321181874818,"error":null,"level":"info","max_duration":"1h0m0s","msg":"maintenance: daily completed","pid":197260,"time":"2023-09-27T00:15:21.182Z"}
```

`actual_duration`(나노초 단위)는 예약된 유지 보수가 실행하는 데 걸린 시간을 나타냅니다. 이전 예제에서는 예약된 정리가 5분 이상 만에 완료되었습니다.

## 객체 풀 리포지토리 {#object-pool-repositories}

{{< details >}}

- 제공 서비스: GitLab Self-Managed

{{< /details >}}

객체 풀 리포지토리는 GitLab에서 포크 전체에서 객체를 중복 제거하는 데 사용됩니다. 첫 번째 포크를 생성할 때:

1. 포크될 예정인 리포지토리의 모든 객체를 포함하는 객체 풀 리포지토리를 생성하세요.
1. Git의 교체 메커니즘을 사용하여 리포지토리를 이 새 객체 풀에 연결하세요.
1. 객체 풀에서 객체를 사용하도록 리포지토리를 다시 압축하세요. 따라서 객체의 자체 복사본을 삭제할 수 있습니다.

이 리포지토리의 모든 포크는 이제 객체 풀에 대해 연결할 수 있으므로 기본 리포지토리와 다른 객체만 유지하면 됩니다.

GitLab은 객체 풀에서 특별한 정리 작업을 수행해야 합니다:

- Gitaly는 객체 풀에서 도달할 수 없는 객체를 삭제할 수 없습니다. 이들이 연결된 포크 중 하나에서 사용될 수 있기 때문입니다.
- Gitaly는 같은 이유로 모든 객체에 대해 도달 가능해야 합니다. 객체 풀은 따라서 도달할 수 없는 "매달려 있는" 객체에 대한 참조를 유지하여 삭제되지 않도록 합니다.
- GitLab은 기본 리포지토리에 추가된 새 객체를 가져오기 위해 객체 풀을 정기적으로 업데이트해야 합니다. 그렇지 않으면 객체 풀은 객체 중복 제거에서 점점 더 비효율적이 됩니다.

이러한 정리 작업은 이러한 모든 특별한 작업을 처리하고 표준 Git 리포지토리에 대해 실행하는 일반 정리 작업도 실행하는 특수 `FetchIntoObjectPool` RPC에 의해 수행됩니다.

객체 풀은 기본 멤버가 가비지 수집되고 있을 때마다 자동으로 최적화됩니다. 따라서 해당 프로젝트에서 동일한 Git GC 기간을 사용하여 주기를 구성할 수 있습니다.

[Rails 콘솔](operations/rails_console.md)에서 RPC를 수동으로 호출해야 하는 경우 `project.pool_repository.object_pool.fetch`을(를) 호출할 수 있습니다. 이것은 잠재적으로 장시간 실행되는 작업이지만 Gitaly는 약 8시간 후에 시간 초과됩니다.
