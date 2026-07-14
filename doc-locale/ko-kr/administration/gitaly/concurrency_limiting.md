---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 동시성 제한
---

Gitaly를 실행하는 서버에 과부하를 주지 않으려면 다음의 동시성을 제한할 수 있습니다:

- RPC
- 팩 객체

이러한 제한은 고정되거나 적응형으로 설정할 수 있습니다.

> [!warning]
> 환경에서 제한을 활성화할 때는 주의가 필요하며 예상치 못한 트래픽으로부터 보호하는 경우 등 선별된 상황에서만 활성화해야 합니다. 제한에 도달하면 연결이 끊어져 사용자에게 부정적인 영향을 미칩니다. 일관되고 안정적인 성능을 위해서는 노드 사양 조정 및 [대용량 리포지토리 검토](../../user/project/repository/monorepos/_index.md)나 워크로드 등 다른 옵션을 먼저 살펴봐야 합니다.

## RPC 동시성 제한 {#limit-rpc-concurrency}

리포지토리를 복제하거나 끌어올 때 다양한 RPC가 백그라운드에서 실행됩니다. 특히 Git 팩 RPC는 다음과 같습니다:

- `SSHUploadPackWithSidechannel` (Git SSH의 경우)
- `PostUploadPackWithSidechannel` (Git HTTP의 경우)

이러한 RPC는 많은 양의 리소스를 소비할 수 있으며 다음과 같은 상황에서 중대한 영향을 미칠 수 있습니다:

- 예상치 못한 높은 트래픽
- 모범 사례를 따르지 않는 [대용량 리포지토리](../../user/project/repository/monorepos/_index.md)에 대해 실행

Gitaly 구성 파일의 동시성 제한을 사용하여 이러한 시나리오에서 이러한 프로세스가 Gitaly 서버를 압도하는 것을 제한할 수 있습니다. 예를 들어:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
   # ...
   concurrency: [
      {
         rpc: '/gitaly.SmartHTTPService/PostUploadPackWithSidechannel',
         max_per_repo: 20,
         max_queue_wait: '1s',
         max_queue_size: 10,
      },
      {
         rpc: '/gitaly.SSHService/SSHUploadPackWithSidechannel',
         max_per_repo: 20,
         max_queue_wait: '1s',
         max_queue_size: 10,
      },
   ],
}
```

- `rpc`은 리포지토리당 동시성 제한을 설정할 RPC의 이름입니다.
- `max_per_repo`은 리포지토리당 주어진 RPC의 최대 미처리 RPC 호출 수입니다.
- `max_queue_wait`은 요청이 Gitaly에서 선택될 때까지 동시성 큐에서 대기할 수 있는 최대 시간입니다.
- `max_queue_size`은 요청이 Gitaly에 의해 거부되기 전에 동시성 큐(RPC 메서드당)가 증가할 수 있는 최대 크기입니다.

이는 주어진 RPC에 대한 미처리 RPC 호출의 수를 제한합니다. 제한은 리포지토리당 적용됩니다. 이전 예제에서:

- Gitaly 서버에서 제공하는 각 리포지토리는 최대 20개의 동시 `PostUploadPackWithSidechannel` 및 `SSHUploadPackWithSidechannel` RPC 호출을 미처리 상태로 가질 수 있습니다.
- 리포지토리의 20개 슬롯을 모두 사용한 경우 다른 요청이 들어오면 해당 요청이 큐에 추가됩니다.
- 요청이 큐에서 1초 이상 대기하면 오류와 함께 거부됩니다.
- 큐가 10을 초과하면 이후 요청은 오류와 함께 거부됩니다.

> [!note]
> 이러한 제한에 도달하면 사용자가 연결 해제됩니다.

Gitaly 로그 및 Prometheus를 사용하여 이 큐의 동작을 관찰할 수 있습니다. 자세한 내용은 [관련 설명서](monitoring.md#monitor-gitaly-concurrency-limiting)를 참조하세요.

### 인증되지 않은 요청을 위한 별도의 제한 {#separate-limits-for-unauthenticated-requests}

{{< history >}}

- GitLab 18.7에서 [플래그와 함께](../../operations/feature_flags.md) `gitaly_limit_unauthenticated`라는 이름으로 도입되었습니다. 기본적으로 비활성화됨.

{{< /history >}}

> [!flag]
> 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하세요. 이 기능은 테스트용으로 제공되지만 프로덕션 사용에는 준비되지 않았습니다.

기본적으로 RPC 동시성 제한은 인증 상태와 관계없이 모든 요청에 적용됩니다. 그러나 인증되지 않은 요청에 대해 더 제한적인 별도의 제한을 구성하여 익명 트래픽으로부터 Gitaly 서버를 잠재적 남용이나 리소스 고갈로부터 보호할 수 있습니다.

RPC에 대해 `unauthenticated` 필드를 구성하면 Gitaly는 별도의 제한기를 사용합니다:

- **Authenticated requests**은 주 동시성 제한(RPC 구성의 최상위 수준에서 구성됨)을 사용합니다.
- **인증되지 않은 요청**은 `unauthenticated` 필드에 지정된 제한을 사용합니다.

이 분리를 통해 다음을 수행할 수 있습니다:

- 인증되지 않은 트래픽에는 더 엄격한 제한을 적용하면서 인증된 사용자를 위한 더 높은 처리량을 유지합니다.
- 익명 복제 또는 끌어오기로부터 서비스 거부 시나리오로부터 보호합니다.
- 인증된 사용자가 Gitaly 리소스에 대한 우선적 액세스 권한을 가지도록 합니다.

`unauthenticated` 필드를 구성하지 않으면 모든 요청(인증된 요청과 인증되지 않은 요청 모두)이 동일한 동시성 제한을 공유합니다.

#### 인증되지 않은 요청을 위한 별도의 제한을 사용하는 경우 {#when-to-use-separate-unauthenticated-limits}

다음 경우에 인증되지 않은 요청을 위한 별도의 제한 구성을 고려하세요:

- GitLab 인스턴스에서 공개 리포지토리 액세스를 허용하고 높은 익명 트래픽을 경험합니다.
- 높은 로드 기간 동안 인증된 사용자를 우선시하려고 합니다.
- 인증되지 않은 소스로부터 잠재적 남용으로부터 보호해야 합니다.
- 인증된 요청과 인증되지 않은 요청 간의 리소스 경합을 관찰합니다.

#### 인증되지 않은 요청에 대한 정적 제한 구성 {#configure-static-limits-for-unauthenticated-requests}

다음 예제는 인증된 요청과 인증되지 않은 요청에 대한 별도의 정적 제한을 구성하는 방법을 보여줍니다:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
   # ...
   concurrency: [
      {
         rpc: '/gitaly.SmartHTTPService/PostUploadPackWithSidechannel',
         # Limits for authenticated requests
         max_per_repo: 20,
         max_queue_wait: '1s',
         max_queue_size: 10,
         # Separate limits for unauthenticated requests
         unauthenticated: {
            max_per_repo: 5,
            max_queue_wait: '500ms',
            max_queue_size: 5,
         },
      },
   ],
}
```

이 예제에서:

- 인증된 요청은 리포지토리당 최대 20개의 동시 작업을 수행할 수 있습니다.
- 인증되지 않은 요청은 리포지토리당 5개의 동시 작업으로 제한됩니다.
- 인증되지 않은 요청은 더 짧은 큐 대기 시간(1초 대 500ms)과 더 작은 큐(10 대 5)를 가집니다.

#### 인증되지 않은 요청을 위한 적응형 제한 구성 {#configure-adaptive-limits-for-unauthenticated-requests}

`unauthenticated` 필드는 주 구성과 마찬가지로 정적 및 적응형 동시성 제한을 모두 지원합니다. 인증되지 않은 요청에 대한 적응형 제한을 구성할 수 있습니다:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
   # ...
   concurrency: [
      {
         rpc: '/gitaly.SmartHTTPService/PostUploadPackWithSidechannel',
         # Adaptive limits for authenticated requests
         adaptive: true,
         min_limit: 10,
         initial_limit: 20,
         max_limit: 40,
         max_queue_wait: '1s',
         max_queue_size: 10,
         # Adaptive limits for unauthenticated requests
         unauthenticated: {
            adaptive: true,
            min_limit: 2,
            initial_limit: 5,
            max_limit: 10,
            max_queue_wait: '500ms',
            max_queue_size: 5,
         },
      },
   ],
}
```

이 구성을 통해 인증된 요청과 인증되지 않은 요청 모두의 제한이 시스템 리소스 사용량을 기반으로 독립적으로 조정되면서 두 트래픽 유형 간의 분리를 유지할 수 있습니다.

## 팩 객체 동시성 제한 {#limit-pack-objects-concurrency}

Gitaly는 SSH 및 HTTPS 트래픽을 처리하여 리포지토리를 복제하거나 끌어올 때 `git-pack-objects` 프로세스를 트리거합니다. 이러한 프로세스는 `pack-file`를 생성하며 예상치 못한 높은 트래픽이나 대용량 리포지토리로부터의 동시 끌어오기와 같은 상황에서 특히 상당한 양의 리소스를 소비할 수 있습니다. GitLab.com에서는 느린 인터넷 연결이 있는 클라이언트의 문제도 관찰합니다.

Gitaly 구성 파일에서 팩 객체 동시성 제한을 설정하여 이러한 프로세스가 Gitaly 서버를 압도하는 것을 제한할 수 있습니다. 이 설정은 원격 IP 주소당 미처리 팩 객체 프로세스의 수를 제한합니다.

> [!warning]
> 이러한 제한을 환경에서 활성화할 때는 주의가 필요하며 예상치 못한 트래픽으로부터 보호하는 경우 등 선별된 상황에서만 활성화해야 합니다. 제한에 도달하면 사용자가 연결 해제됩니다. 일관되고 안정적인 성능을 위해서는 노드 사양 조정 및 [대용량 리포지토리 검토](../../user/project/repository/monorepos/_index.md)나 워크로드 등 다른 옵션을 먼저 살펴봐야 합니다.

예제 구성:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['pack_objects_limiting'] = {
   'max_concurrency' => 15,
   'max_queue_length' => 200,
   'max_queue_wait' => '60s',
}
```

- `max_concurrency`은 키당 미처리 팩 객체 프로세스의 최대 수입니다.
- `max_queue_length`은 요청이 Gitaly에 의해 거부되기 전에 동시성 큐(키당)가 증가할 수 있는 최대 크기입니다.
- `max_queue_wait`은 요청이 Gitaly에서 선택될 때까지 동시성 큐에서 대기할 수 있는 최대 시간입니다.

이전 예제에서:

- 각 원격 IP는 Gitaly 노드에서 최대 15개의 동시 팩 객체 프로세스를 미처리 상태로 가질 수 있습니다.
- 이미 15개 슬롯을 사용한 IP에서 다른 요청이 들어오면 해당 요청이 큐에 추가됩니다.
- 요청이 큐에서 1분 이상 대기하면 오류와 함께 거부됩니다.
- 큐가 200을 초과하면 이후 요청은 오류와 함께 거부됩니다.

팩 객체 캐시가 활성화된 경우 캐시가 누락된 경우에만 팩 객체 제한이 시작됩니다. 자세한 내용은 [팩 객체 캐시](configure_gitaly.md#pack-objects-cache)를 참조하세요.

Gitaly 로그 및 Prometheus를 사용하여 이 큐의 동작을 관찰할 수 있습니다. 자세한 내용은 [Gitaly 팩 객체 동시성 제한 모니터링](monitoring.md#monitor-gitaly-pack-objects-concurrency-limiting)을 참조하세요.

## 동시성 제한 보정 {#calibrating-concurrency-limits}

동시성 제한을 설정할 때는 특정 워크로드 패턴을 기반으로 적절한 값을 선택해야 합니다. 이 섹션에서는 이러한 제한을 효과적으로 보정하는 방법에 대한 지침을 제공합니다.

### 보정을 위해 Prometheus 메트릭 및 로그 사용 {#using-prometheus-metrics-and-logs-for-calibration}

Prometheus 메트릭은 사용 패턴과 각 RPC 유형이 Gitaly 노드 리소스에 미치는 영향에 대한 정량적 인사이트를 제공합니다. 이 분석에 특히 유용한 몇 가지 주요 메트릭이 있습니다:

- RPC당 리소스 소비 메트릭 Gitaly는 대부분의 무거운 작업을 `git` 프로세스로 오프로드하므로 일반적으로 셸 아웃되는 명령은 Git 바이너리입니다. Gitaly는 이러한 명령에서 수집된 메트릭을 로그 및 Prometheus 메트릭으로 노출합니다.
  - `gitaly_command_cpu_seconds_total` - 셸 아웃으로 소비한 CPU 시간의 합계이며 `grpc_service`, `grpc_method`, `cmd`, `subcmd`에 대한 레이블이 있습니다.
  - `gitaly_command_real_seconds_total` - 셸 아웃으로 소비한 실시간의 합계이며 유사한 레이블이 있습니다.
- RPC당 최근 제한 메트릭:
  - `gitaly_concurrency_limiting_in_progress` - 처리 중인 동시 요청의 수
  - `gitaly_concurrency_limiting_queued` - 주어진 리포지토리의 RPC에 대한 대기 상태인 요청의 수
  - `gitaly_concurrency_limiting_acquiring_seconds` - 동시성 제한으로 인해 처리 전에 요청이 대기하는 기간

이러한 메트릭은 특정 시점의 리소스 활용률에 대한 높은 수준의 보기를 제공합니다. `gitaly_command_cpu_seconds_total` 메트릭은 상당한 CPU 리소스를 소비하는 특정 RPC를 식별하는 데 특히 효과적입니다. 추가 메트릭은 [Gitaly 모니터링](monitoring.md)에서 설명한 대로 더 자세한 분석을 위해 사용 가능합니다.

메트릭은 전반적인 리소스 사용 패턴을 캡처하지만 일반적으로 리포지토리별 분석을 제공하지 않습니다. 따라서 로그는 보완적 데이터 소스 역할을 합니다. 로그를 분석하려면:

1. 식별된 높은 영향의 RPC별로 로그를 필터링합니다.
1. 필터링된 로그를 리포지토리 또는 프로젝트별로 집계합니다.
1. 시계열 그래프에 집계된 결과를 시각화합니다.

메트릭과 로그를 모두 사용하는 이 통합 접근 방식은 시스템 전체 리소스 사용량과 리포지토리별 패턴에 대한 포괄적인 가시성을 제공합니다. Kibana 또는 유사한 로그 집계 플랫폼과 같은 분석 도구가 이 프로세스를 촉진할 수 있습니다.

### 제한 조정 {#adjusting-limits}

초기 제한이 충분히 효율적이지 않은 경우 조정해야 할 수 있습니다. 적응형 제한을 사용하면 시스템이 리소스 사용량을 기반으로 자동으로 조정되므로 정확한 제한이 덜 중요합니다.

동시성 제한은 리포지토리 범위로 지정됨을 기억하세요. 30의 제한은 리포지토리당 최대 30개의 동시 미처리 요청을 허용한다는 의미입니다. 제한에 도달하면 요청이 큐에 추가되며 큐가 가득 찼거나 최대 대기 시간에 도달한 경우에만 거부됩니다.

## 적응형 동시성 제한 {#adaptive-concurrency-limiting}

{{< history >}}

- GitLab 16.6에서 [도입](https://gitlab.com/groups/gitlab-org/-/epics/10734)되었습니다.

{{< /history >}}

Gitaly는 두 가지 동시성 제한을 지원합니다:

- [RPC 동시성 제한](#limit-rpc-concurrency)은 각 Gitaly RPC에 대한 최대 동시 미처리 요청 수를 구성할 수 있게 합니다. 제한은 RPC 및 리포지토리 범위로 지정됩니다.
- [팩 객체 동시성 제한](#limit-pack-objects-concurrency)은 IP별 동시 Git 데이터 전송 요청 수를 제한합니다.

이 제한을 초과하면 다음 중 하나가 발생합니다:

- 요청이 큐에 추가됩니다.
- 큐가 가득 찼거나 요청이 큐에 너무 오래 있으면 요청이 거부됩니다.

이러한 동시성 제한 모두 정적으로 구성할 수 있습니다. 정적 제한은 좋은 보호 결과를 얻을 수 있지만 몇 가지 단점이 있습니다:

- 정적 제한은 모든 사용 패턴에 좋지 않습니다. 모든 경우에 적합한 값은 없습니다. 제한이 너무 낮으면 대용량 리포지토리가 부정적인 영향을 받습니다. 제한이 너무 높으면 보호가 본질적으로 손실됩니다.
- 특히 각 리포지토리의 워크로드가 시간이 지남에 따라 변할 때 동시성 제한에 대해 적절한 값을 유지하기는 번거롭습니다.
- 요청이 리소스 비율을 계산하지 않기 때문에 서버가 유휴 상태인 경우에도 요청이 거부될 수 있습니다.

적응형 동시성 제한을 구성하여 이러한 모든 단점을 극복하고 동시성 제한의 이점을 유지할 수 있습니다. 적응형 동시성 제한은 선택 사항이며 두 가지 동시성 제한 유형을 기반으로 합니다. 가산 증가/곱셈 감소(AIMD) 알고리즘을 사용합니다. 각 적응형 제한:

- 일반적인 프로세스 작동 중에 특정 상한까지 점진적으로 증가합니다.
- 호스트 머신에 리소스 문제가 있을 때 빠르게 감소합니다.

이 메커니즘은 머신이 "숨을 쉴" 수 있는 여유를 제공하고 현재 미처리 요청의 속도를 높입니다.

![AIMD 알고리즘을 따르는 시스템 리소스 사용량을 기반으로 조정되는 Gitaly 적응형 동시성 제한을 보여주는 그래프](img/gitaly_adaptive_concurrency_limit_v16_6.png)

적응형 제한기는 30초마다 제한을 보정하고:

- 상한에 도달할 때까지 제한을 1씩 증가합니다.
- 최상위 cgroup의 메모리 사용량이 고도로 제거 가능한 페이지 캐시를 제외하고 90%를 초과하거나 관찰 시간의 50% 이상 CPU가 제한된 경우 제한을 절반으로 감소합니다.

그 외에는 상한에 도달할 때까지 제한이 1씩 증가합니다.

적응형 제한은 각 RPC 또는 팩 객체 캐시에 대해 개별적으로 활성화됩니다. 그러나 제한은 동시에 보정됩니다. 적응형 제한에는 다음 구성이 있습니다:

- `adaptive`은 적응성 활성화 여부를 설정합니다.
- `max_limit`은 최대 동시성 제한입니다. Gitaly는 현재 제한을 이 수에 도달할 때까지 증가시킵니다. 이것은 시스템이 일반적인 조건에서 완전히 지원할 수 있는 넉넉한 값이어야 합니다.
- `min_limit`은 구성된 RPC의 최소 동시성 제한입니다. 호스트 머신에 리소스 문제가 있으면 Gitaly는 이 값에 도달할 때까지 제한을 빠르게 줄입니다. `min_limit`를 0으로 설정하면 처리를 완전히 종료할 수 있으며, 이는 일반적으로 바람직하지 않습니다.
- `initial_limit`는 이러한 극단 사이의 합리적인 시작점을 제공합니다.

### RPC 동시성에 대한 적응성 활성화 {#enable-adaptiveness-for-rpc-concurrency}

전제 조건:

- 적응형 제한이 [제어 그룹](configure_gitaly.md#control-groups)에 의존하기 때문에 적응형 제한을 사용하기 전에 제어 그룹을 활성화해야 합니다.

다음은 RPC 동시성에 대한 적응형 제한을 구성하는 예제입니다:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['configuration'] = {
    # ...
    cgroups: {
        # Minimum required configuration to enable cgroups support.
        repositories: {
            count: 1
        },
    },
    concurrency: [
        {
            rpc: '/gitaly.SmartHTTPService/PostUploadPackWithSidechannel',
            max_queue_wait: '1s',
            max_queue_size: 10,
            adaptive: true,
            min_limit: 10,
            initial_limit: 20,
            max_limit: 40
        },
        {
            rpc: '/gitaly.SSHService/SSHUploadPackWithSidechannel',
            max_queue_wait: '10s',
            max_queue_size: 20,
            adaptive: true,
            min_limit: 10,
            initial_limit: 50,
            max_limit: 100
        },
   ],
}
```

자세한 내용은 [RPC 동시성](#limit-rpc-concurrency)을 참조하세요.

### 팩 객체 동시성에 대한 적응성 활성화 {#enable-adaptiveness-for-pack-objects-concurrency}

전제 조건:

- 적응형 제한이 [제어 그룹](configure_gitaly.md#control-groups)에 의존하기 때문에 적응형 제한을 사용하기 전에 제어 그룹을 활성화해야 합니다.

다음은 팩 객체 동시성에 대한 적응형 제한을 구성하는 예제입니다:

```ruby
# in /etc/gitlab/gitlab.rb
gitaly['pack_objects_limiting'] = {
   'max_queue_length' => 200,
   'max_queue_wait' => '60s',
   'adaptive' => true,
   'min_limit' => 10,
   'initial_limit' => 20,
   'max_limit' => 40
}
```

자세한 내용은 [팩 객체 동시성](#limit-pack-objects-concurrency)을 참조하세요.

### 적응형 동시성 제한 보정 {#calibrating-adaptive-concurrency-limits}

적응형 동시성 제한은 GitLab이 Gitaly 리소스를 보호하는 일반적인 방법과 매우 다릅니다. 정적 임계값에 의존하는 것이 아니라 적응형 제한은 실시간으로 실제 리소스 상태에 지능적으로 대응합니다.

이 접근 방식은 [동시성 제한 보정](#calibrating-concurrency-limits)에서 설명한 대로 광범위한 보정을 통해 "완벽한" 임계값을 찾을 필요를 제거합니다. 실패 시나리오 중에 적응형 제한기는 제한을 지수적으로 감소(예: 60 → 30 → 15 → 10)시킨 후 시스템이 안정화되면 점진적으로 제한을 높여서 자동으로 복구됩니다.

적응형 제한을 보정할 때는 정확도보다 유연성을 우선시할 수 있습니다.

#### RPC 범주 및 구성 예제 {#rpc-categories-and-configuration-examples}

보호해야 하는 비용이 많이 드는 Gitaly RPC는 두 가지 일반적 유형으로 분류할 수 있습니다:

- 순수 Git 데이터 작업
- 시간에 민감한 RPC

각 유형에는 동시성 제한을 구성하는 방법에 영향을 미치는 서로 다른 특성이 있습니다. 다음 예제는 제한 구성 뒤의 논리를 설명합니다. 시작점으로도 사용할 수 있습니다.

##### 순수 Git 데이터 작업 {#pure-git-data-operations}

이러한 RPC는 Git 끌어오기, 푸시 및 페치 작업을 포함하며 다음과 같은 특성을 가집니다:

- 장시간 실행 프로세스
- 상당한 리소스 활용
- 계산 비용이 많이 듭니다.
- 시간에 민감하지 않습니다. 추가 지연은 일반적으로 허용됩니다.

`SmartHTTPService` 및 `SSHService`의 RPC는 순수 Git 데이터 작업 범주에 속합니다. 구성 예제:

```ruby
{
  rpc: "/gitaly.SmartHTTPService/PostUploadPackWithSidechannel", # or `/gitaly.SmartHTTPService/SSHUploadPackWithSidechannel`
  adaptive: true,
  min_limit: 10,  # Minimum concurrency to maintain even under extreme load
  initial_limit: 40,  # Starting concurrency when service initializes
  max_limit: 60,  # Maximum concurrency under ideal conditions
  max_queue_wait: "60s",
  max_queue_size: 300
}
```

##### 시간에 민감한 RPC {#time-sensitive-rpcs}

이러한 RPC는 GitLab 자체 및 다양한 특성을 가진 다른 클라이언트를 제공합니다:

- 일반적으로 온라인 HTTP 요청 또는 Sidekiq 백그라운드 작업의 일부입니다.
- 더 짧은 지연 시간 프로필
- 일반적으로 리소스를 많이 사용하지 않습니다.

이러한 RPC의 경우 GitLab의 타임아웃 구성은 `max_queue_wait` 매개 변수를 알려야 합니다. 예를 들어 `get_tree_entries`는 일반적으로 GitLab에서 중간 타임아웃(30초)을 갖습니다:

```ruby
{
  rpc: "/gitaly.CommitService/GetTreeEntries",
  adaptive: true,
  min_limit: 5,  # Minimum throughput maintained under resource pressure
  initial_limit: 10,  # Initial concurrency setting
  max_limit: 20,  # Maximum concurrency under optimal conditions
  max_queue_size: 50,
  max_queue_wait: "30s"
}
```

### 적응형 제한 모니터링 {#monitoring-adaptive-limiting}

적응형 제한이 프로덕션 환경에서 어떻게 작동하는지 관찰하려면 [Gitaly 적응형 동시성 제한 모니터링](monitoring.md#monitor-gitaly-adaptive-concurrency-limiting)에서 설명하는 모니터링 도구 및 메트릭을 참조하세요. 적응형 제한 동작을 관찰하면 제한이 리소스 압박에 올바르게 반응하고 예상대로 조정되고 있는지 확인할 수 있습니다.
