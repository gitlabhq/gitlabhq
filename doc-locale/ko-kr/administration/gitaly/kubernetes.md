---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Kubernetes의 Gitaly
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.3에서 [실험](../../policy/development_stages_support.md)으로 도입되었습니다.
- GitLab 17.10에서 실험 버전에서 베타 버전으로 변경되었습니다.
- GitLab 18.2에서 베타 버전에서 제한된 가용성으로 변경되었습니다.
- GitLab 18.11에서 제한된 가용성에서 일반적 가용성으로 변경되었습니다.

{{< /history >}}

Kubernetes의 Gitaly는 가용성 트레이드오프가 있으므로 프로덕션 환경을 계획할 때 이러한 트레이드오프를 고려하고 예상을 적절히 설정합니다. 이 문서에서는 기존 제한을 최소화하고 계획하는 방법을 설명하고 지침을 제공합니다.

Kubernetes의 Gitaly는 Gitaly 팀에서 평가했으며 Gitaly를 배포하는 안전한 방법으로 결정되었습니다. 이 문서의 나머지 부분에서는 이를 수행하기 위한 모범 사례를 자세히 설명합니다.

## 타임라인 {#timeline}

[Kubernetes의 Gitaly](kubernetes.md)는 GitLab 18.11부터 일반적으로 사용 가능합니다. GitLab은 클라우드 공급자(Amazon EKS, Google GKE, Azure AKS 등)의 특정 관리형 Kubernetes 제공과의 호환성을 보장하지 않습니다. 프로덕션에 배포하기 전에 특정 환경을 검증해야 합니다.

## 컨텍스트 {#context}

설계상 Gitaly(non-Cluster)는 단일 실패 지점(SPoF) 서비스입니다. 데이터는 단일 인스턴스에서 소싱되고 제공됩니다. Kubernetes의 경우 StatefulSet 팟(pod)이 회전할 때(예: 업그레이드, 노드 유지 관리 또는 제거 중) 회전으로 인해 팟 또는 인스턴스에서 제공하는 데이터에 대한 서비스 중단이 발생합니다.

[Cloud Native Hybrid](../reference_architectures/1k_users.md#cloud-native-hybrid-reference-architecture-with-helm-charts) 설정(Gitaly VM)에서 Linux 패키지(Omnibus)는 다음과 같은 방식으로 문제를 가립니다:

1. Gitaly 바이너리를 제자리에서 업그레이드합니다.
1. 정상적인 재로드를 수행합니다.

컨테이너 또는 팟이 완전히 종료되고 새 컨테이너 또는 팟으로 시작해야 하는 컨테이너 기반 수명 주기에는 동일한 접근 방식이 적합하지 않습니다.

Gitaly Cluster(Praefect)는 인스턴스 간에 데이터를 복제하여 데이터 및 서비스 고가용성 측면을 해결합니다. 그러나 Gitaly Cluster(Praefect)는 [기존 문제 및 설계 제약](praefect/_index.md#known-issues)으로 인해 Kubernetes에서 실행하기에 적합하지 않으며, 이는 컨테이너 기반 플랫폼에 의해 강화됩니다.

Cloud Native 배포를 지원하기 위해 Gitaly(non-Cluster)가 유일한 옵션입니다. 적절한 Kubernetes 및 Gitaly 기능과 구성을 활용하면 서비스 중단을 최소화하고 좋은 사용자 경험을 제공할 수 있습니다.

## 요구 사항 {#requirements}

이 페이지의 정보는 다음을 가정합니다:

- Kubernetes 버전 `1.29` 이상입니다.
- Kubernetes 노드 `runc` 버전 `1.1.9` 이상입니다.
- Kubernetes 노드 cgroup v2입니다. 기본, 하이브리드 v1 모드는 지원되지 않습니다. [`systemd`-style cgroup 구조](https://kubernetes.io/docs/setup/production-environment/container-runtimes/#systemd-cgroup-driver)만 지원됩니다(Kubernetes 기본값).
- 노드 마운트포인트 `/sys/fs/cgroup`에 대한 팟 액세스입니다.
- containerd 버전 2.1.0 이상입니다.
- 팟 초기화 컨테이너(`init-cgroups`) `/sys/fs/cgroup`에 대한 `root` 사용자 파일 시스템 권한에 액세스합니다. 팟 cgroup을 Gitaly 컨테이너(사용자 `git`, UID `1000`)에 위임하는 데 사용됩니다.
- cgroups 파일 시스템은 `nsdelegate` 플래그로 마운트되지 않습니다. 자세한 정보는 Gitaly 이슈 [6480](https://gitlab.com/gitlab-org/gitaly/-/issues/6480)을 참조하세요.

## 지침 {#guidance}

Kubernetes에서 Gitaly를 실행할 때 다음을 수행해야 합니다:

- [팟 중단 해결](#address-pod-disruption)합니다.
- [리소스 경합 및 포화 해결](#address-resource-contention-and-saturation)합니다.
- [팟 회전 시간 최적화](#optimize-pod-rotation-time)합니다.
- [디스크 사용량 모니터링](#monitor-disk-usage)

### containerd에서 `cgroup_writable` 필드 활성화 {#enable-cgroup_writable-field-in-containerd}

Gitaly의 Cgroup 지원은 권한이 없는 컨테이너에 대한 cgroup에 대한 쓰기 액세스가 필요합니다. containerd v2.1.0은 `cgroup_writable` 구성 옵션을 도입했습니다. 이 옵션이 활성화되면 cgroups 파일 시스템이 읽기/쓰기 권한으로 마운트됩니다.

이 필드를 활성화하려면 Gitaly가 배포될 노드에서 다음 단계를 수행합니다. Gitaly가 이미 배포된 경우 구성을 수정한 후 팟을 다시 생성해야 합니다.

1. `/etc/containerd/config.toml`에 있는 containerd 구성 파일을 수정하여 `cgroup_writable` 필드를 포함합니다:

   ```toml
   [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
   runtime_type = "io.containerd.runc.v2"
   cgroup_writable = true
   ```

1. Kubelet 및 containerd 서비스를 다시 시작합니다:

   ```shell
   sudo systemctl restart kubelet
   sudo systemctl restart containerd
   ```

   이러한 명령은 서비스가 다시 시작하는 데 오래 걸리면 노드를 NotReady로 표시할 수 있습니다.

### 팟 중단 해결 {#address-pod-disruption}

팟은 여러 이유로 회전할 수 있습니다. 서비스 수명 주기를 이해하고 계획하면 중단을 최소화하는 데 도움이 됩니다.

예를 들어 Gitaly를 사용하면 Kubernetes `StatefulSet`이 `spec.template` 객체 변경에 따라 회전하며, 이는 Helm Chart 업그레이드(레이블 또는 이미지 태그) 또는 팟 리소스 요청 또는 제한 업데이트 중에 발생할 수 있습니다.

이 섹션에서는 일반적인 팟 중단 경우와 이를 해결하는 방법에 중점을 둡니다.

#### 유지 관리 창 예약 {#schedule-maintenance-windows}

서비스가 높은 가용성이 없기 때문에 특정 작업으로 인해 짧은 서비스 중단이 발생할 수 있습니다. 유지 관리 창을 예약하면 잠재적 서비스 중단을 신호하고 예상을 설정하는 데 도움이 됩니다. 다음에 대해 유지 관리 창을 사용해야 합니다:

- GitLab Helm chart 업그레이드 및 재구성입니다.
- Gitaly 구성 변경입니다.
- Kubernetes 노드 유지 관리 창입니다. 예를 들어 업그레이드 및 패칭입니다. Gitaly를 자체 전용 노드 풀로 격리하면 도움이 될 수 있습니다.

#### `PriorityClass` 사용 {#use-priorityclass}

[PriorityClass](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/#priorityclass)를 사용하여 다른 팟에 비해 Gitaly 팟에 더 높은 우선순위를 할당하여 노드 포화 압력, 제거 우선순위 및 스케줄링 지연 시간을 줄입니다:

1. 우선순위 클래스를 생성합니다:

   ```yaml
   apiVersion: scheduling.k8s.io/v1
   kind: PriorityClass
   metadata:
     name: gitlab-gitaly
   value: 1000000
   globalDefault: false
   description: "GitLab Gitaly priority class"
   ```

1. 우선순위 클래스를 Gitaly 팟에 할당합니다:

   ```yaml
   gitlab:
     gitaly:
       priorityClassName: gitlab-gitaly
   ```

#### 제거를 방지하기 위해 노드 자동 확장 신호 {#signal-node-autoscaling-to-prevent-eviction}

노드 자동 확장 도구는 필요에 따라 Kubernetes 노드를 추가하고 제거하여 팟을 스케줄하고 비용을 최적화합니다.

확장 축소 이벤트 중에 리소스 사용을 최적화하기 위해 Gitaly 팟을 제거할 수 있습니다. 주석은 일반적으로 이 동작을 제어하고 워크로드를 제외하는 데 사용 가능합니다. 예를 들어 Cluster Autoscaler의 경우:

```yaml
gitlab:
  gitaly:
    annotations:
      cluster-autoscaler.kubernetes.io/safe-to-evict: "false"
```

### 리소스 경합 및 포화 해결 {#address-resource-contention-and-saturation}

Gitaly 서비스 리소스 사용은 Git 작업의 불확실한 특성으로 인해 예측할 수 없습니다. 모든 리포지토리가 동일하지 않으며 크기는 성능 및 리소스 사용에 큰 영향을 미치며, 특히 [monorepos](../../user/project/repository/monorepos/_index.md)의 경우입니다.

Kubernetes에서 제어되지 않은 리소스 사용으로 인해 OOM(Out Of Memory) 이벤트가 발생할 수 있으며, 이는 플랫폼이 팟을 종료하고 모든 프로세스를 종료하도록 강제합니다. 팟 종료는 두 가지 중요한 우려 사항을 제기합니다:

- 데이터/리포지토리 손상
- 서비스 중단

이 섹션은 영향 범위를 줄이고 전체 서비스를 보호하는 데 중점을 둡니다.

#### Git 프로세스 리소스 사용 제약 {#constrain-git-processes-resource-usage}

Git 프로세스를 격리하면 단일 Git 호출이 모든 서비스 및 팟 리소스를 소비할 수 없다는 것을 보장하여 안전성을 제공합니다.

Gitaly는 Linux [Control Groups(cgroups)](cgroups.md)을 사용하여 리소스 사용에 대해 더 작은 리포지토리 단위 할당량을 부과할 수 있습니다.

전체 팟 리소스 할당 아래에서 cgroup 할당량을 유지해야 합니다. CPU는 서비스를 느리게 할 뿐이므로 중요하지 않습니다. 그러나 메모리 포화로 인해 팟 종료가 발생할 수 있습니다. 팟 요청과 Git cgroup 할당 간의 1GiB 메모리 버퍼는 안전한 시작점입니다. 버퍼 크기 조정은 트래픽 패턴 및 리포지토리 데이터에 따라 달라집니다.

예를 들어 팟 메모리 요청이 15GiB인 경우 14GiB가 Git 호출에 할당됩니다:

```yaml
gitlab:
  gitaly:
    cgroups:
      enabled: true
      # Total limit across all repository cgroups, excludes Gitaly process
      memoryBytes: 15032385536 # 14GiB
      cpuShares: 1024
      cpuQuotaUs: 400000 # 4 cores
      # Per repository limits, 50 repository cgroups
      repositories:
        count: 50
        memoryBytes: 7516192768 # 7GiB
        cpuShares: 512
        cpuQuotaUs: 200000 # 2 cores
```

자세한 정보는 [Gitaly 구성 문서](configure_gitaly.md#control-groups)를 참조하세요.

#### 팟 리소스 크기 조정 {#right-size-pod-resources}

Gitaly 팟 크기를 정하는 것은 중요하며 [참조 아키텍처](../reference_architectures/_index.md#cloud-native-hybrid)는 시작점으로 일부 지침을 제공합니다. 그러나 다양한 리포지토리 및 사용 패턴은 다양한 리소스를 소비합니다. 리소스 사용을 모니터링하고 시간이 지남에 따라 적절히 조정해야 합니다.

메모리는 메모리 부족 시 팟 종료를 트리거할 수 있으므로 Kubernetes에서 가장 민감한 리소스입니다. [cgroups을 사용한 Git 호출 격리](#constrain-git-processes-resource-usage)는 리포지토리 작업에 대한 리소스 사용을 제한하는 데 도움이 되지만 Gitaly 서비스 자체는 포함하지 않습니다. cgroup 할당량에 대한 이전 권장 사항과 일치하여 안전성을 개선하기 위해 전체 Git cgroup 메모리 할당과 팟 메모리 요청 간에 버퍼를 추가합니다.

팟 `Guaranteed` [Quality of Service](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/) 클래스가 선호됩니다(리소스 요청이 한계와 일치). 이 설정을 사용하면 팟은 리소스 경합에 덜 민감하며 다른 팟의 소비에 따라 제거될 수 없습니다.

리소스 구성 예:

```yaml
gitlab:
  gitaly:
    resources:
      requests:
        cpu: 4000m
        memory: 15Gi
      limits:
        cpu: 4000m
        memory: 15Gi

    init:
      resources:
        requests:
          cpu: 50m
          memory: 32Mi
        limits:
          cpu: 50m
          memory: 32Mi
```

#### 동시성 제한 구성 {#configure-concurrency-limiting}

동시성 제한을 사용하여 비정상적인 트래픽 패턴으로부터 서비스를 보호할 수 있습니다. 자세한 정보는 [동시성 구성 문서](concurrency_limiting.md) 및 [제한 모니터링 방법](monitoring.md#monitor-gitaly-concurrency-limiting)을 참조하세요.

#### Gitaly 팟 격리 {#isolate-gitaly-pods}

여러 Gitaly 팟을 실행할 때 여러 노드에 팟을 예약하여 실패 도메인을 분산해야 합니다. 이는 팟 반대 선호도를 사용하여 적용할 수 있습니다. 예를 들어:

```yaml
gitlab:
  gitaly:
    antiAffinity: hard
```

### 팟 회전 시간 최적화 {#optimize-pod-rotation-time}

이 섹션에서는 팟이 트래픽 제공을 시작하는 데 걸리는 시간을 줄여 유지 관리 이벤트 또는 계획되지 않은 인프라 이벤트 중에 가동 중지 시간을 줄이기 위한 최적화 영역을 다룹니다.

#### Persistent Volume 권한 {#persistent-volume-permissions}

데이터 크기가 증가함에 따라(Git 기록 및 더 많은 리포지토리), 팟이 시작되어 준비되는 데 더 많은 시간이 걸립니다.

팟 초기화 중에 persistent volume 마운트의 일부로 파일 시스템 권한 및 소유권이 컨테이너 `uid` 및 `gid`로 명시적으로 설정됩니다. 이 작업은 기본적으로 실행되며 저장된 Git 데이터가 많은 작은 파일을 포함하기 때문에 팟 시작 시간을 크게 늦출 수 있습니다.

이 동작은 [`fsGroupChangePolicy`](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#configure-volume-permission-and-ownership-change-policy-for-pods) 속성으로 구성할 수 있습니다. 이 속성을 사용하여 volume root `uid` 또는 `gid`이 컨테이너 사양과 일치하지 않는 경우에만 작업을 수행합니다:

```yaml
gitlab:
  gitaly:
    securityContext:
      fsGroupChangePolicy: OnRootMismatch
```

#### 상태 확인 {#health-probes}

Gitaly 팟은 준비 상태 확인이 성공한 후 트래픽 제공을 시작합니다. 기본 프로브 시간은 대부분의 사용 사례를 포함하도록 보수적입니다. `readinessProbe` `initialDelaySeconds` 속성을 줄이면 더 빨리 프로브를 트리거하여 팟 준비를 가속화합니다. 예를 들어:

```yaml
gitlab:
  gitaly:
    statefulset:
      readinessProbe:
        initialDelaySeconds: 2
        periodSeconds: 10
        timeoutSeconds: 3
        successThreshold: 1
        failureThreshold: 3
```

#### Gitaly 정상적인 종료 시간 초과 {#gitaly-graceful-shutdown-timeout}

기본적으로 종료할 때 Gitaly는 진행 중인 요청이 완료될 때까지 1분의 시간 초과를 부여합니다. 언뜻 보기에는 도움이 되지만 이 시간 초과:

- 팟 회전 속도를 늦춥니다.
- 종료 프로세스 중에 요청을 거부하여 가용성을 줄입니다.

컨테이너 기반 배포의 더 나은 접근 방식은 클라이언트 측 재시도 로직을 사용하는 것입니다. `gracefulRestartTimeout` 필드를 사용하여 시간 초과를 다시 구성할 수 있습니다. 예를 들어 1초의 정상적인 시간 초과를 부여하려면:

```yaml
gitlab:
  gitaly:
    gracefulRestartTimeout: 1
```

### 디스크 사용량 모니터링 {#monitor-disk-usage}

[로그 회전이 활성화되지 않은](https://docs.gitlab.com/charts/charts/globals/#log-rotation) 경우 로그 파일 증가로 인해 스토리지 문제가 발생할 수 있으므로 장기 실행 Gitaly 컨테이너의 디스크 사용량을 정기적으로 모니터링합니다.

## Kubernetes에서 Gitaly로 마이그레이션 {#migrate-to-gitaly-on-kubernetes}

non-Kubernetes Gitaly 노드에서 Kubernetes의 Gitaly로 기존 리포지토리를 마이그레이션하려면:

1. Kubernetes 노드에 Gitaly를 배포하고 [새 리포지토리 스토리지로 추가](../repository_storage_paths.md#configure-where-new-repositories-are-stored)합니다. GitLab 관리자 영역에서입니다. 모든 새 리포지토리가 새 리포지토리 스토리지에 생성되도록 스토리지 가중치를 구성합니다. 이는 마이그레이션이 진행되는 동안 새 프로젝트가 이전 리포지토리 스토리지에 생성되는 것을 방지합니다.
1. 리포지토리 이동 API를 사용하여 기존 리포지토리를 새 스토리지로 이동합니다. GitLab 리포지토리는 프로젝트, 그룹 및 스니펫과 연결될 수 있으며 각 유형에는 별도의 API가 있습니다. 전체 지침은 [GitLab에서 관리하는 리포지토리 이동](../operations/moving_repositories.md)을 참조하세요.

각 리포지토리는 이동 기간 동안 읽기 전용이며 이동이 완료될 때까지 쓰기 불가능합니다.
