---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Zoekt 문제 해결
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed
- 상태:  제한적 출시

{{< /details >}}

Zoekt를 사용할 때 다음과 같은 이슈가 발생할 수 있습니다. 예비 디버깅을 위해:

- [상태 확인 실행](_index.md#run-a-health-check)하여 Zoekt 인프라의 상태를 이해합니다.
- [인덱싱 상태 확인](_index.md#check-indexing-status) `gitlab-rake gitlab:zoekt:info` Rake 작업을 사용합니다.

## 네임스페이스가 인덱싱되지 않음 {#namespace-is-not-indexed}

[설정을 활성화](_index.md#index-root-namespaces-automatically)하면 새 네임스페이스가 자동으로 인덱싱됩니다. 네임스페이스가 자동으로 인덱싱되지 않으면 Sidekiq 로그를 확인하여 작업이 처리 중인지 확인합니다. `Search::Zoekt::SchedulingWorker`는 네임스페이스 인덱싱을 담당합니다.

[Rails 콘솔 세션](../../administration/operations/rails_console.md#starting-a-rails-console-session)에서 다음을 확인할 수 있습니다:

- Zoekt가 활성화되지 않은 네임스페이스:

  ```ruby
  Namespace.group_namespaces.root_namespaces_without_zoekt_enabled_namespace
  ```

- Zoekt 인덱스의 상태:

  ```ruby
  Search::Zoekt::Index.all.pluck(:state, :namespace_id)
  ```

네임스페이스를 수동으로 인덱싱하려면 [인덱싱 설정](https://docs.gitlab.com/charts/charts/gitlab/gitlab-zoekt/#configure-zoekt-in-gitlab)을 참조합니다.

## 오류: `SilentModeBlockedError` {#error-silentmodeblockederror}

정확한 코드 검색을 실행하려고 할 때 `SilentModeBlockedError`이(가) 나타날 수 있습니다. 이 이슈는 GitLab 범위에서 [Silent Mode](../../administration/silent_mode)가 활성화되어 있을 때 발생합니다.

이 이슈를 해결하려면 Silent Mode가 비활성화되어 있는지 확인합니다.

## 오류: `connections to all backends failing` {#error-connections-to-all-backends-failing}

`application_json.log`에서 다음 오류가 나타날 수 있습니다:

```plaintext
connections to all backends failing; last error: UNKNOWN: ipv4:1.2.3.4:5678: Trying to connect an http1.x server
```

이 이슈를 해결하려면 프록시를 사용하고 있는지 확인합니다. 사용 중인 경우 GitLab 서버의 IP 주소를 `no_proxy`로 설정합니다:

```ruby
gitlab_rails['env'] = {
  "http_proxy" => "http://proxy.domain.com:1234",
  "https_proxy" => "http://proxy.domain.com:1234",
  "no_proxy" => ".domain.com,IP_OF_GITLAB_INSTANCE,127.0.0.1,localhost"
}
```

`proxy.domain.com:1234`은(는) 프록시 범위의 도메인 및 포트입니다. `IP_OF_GITLAB_INSTANCE`는 GitLab 범위의 공용 IP 주소를 가리킵니다.

`ip a`을(를) 실행하고 다음 중 하나를 확인하여 이 정보를 얻을 수 있습니다:

- 적절한 네트워크 인터페이스의 IP 주소
- 사용 중인 로드 밸런서의 공용 IP 주소

## 메모리 부족 오류 {#out-of-memory-errors}

Zoekt 노드는 검색 또는 인덱싱 중에 메모리가 부족할 수 있습니다. 메모리 부족(OOM) 오류는 웹 서버에서 더 가능성이 높습니다. 웹 서버는 검색이 수행될 때 인덱스 샤드를 물리적 메모리에 메모리 맵핑하므로, 거주자 메모리는 인덱스 크기 및 쿼리 볼륨에 따라 증가합니다. OOM 오류의 증상과 필요한 복구 단계는 두 구성 요소 간에 다릅니다. 자세한 내용은 [메모리 아키텍처](_index.md#memory-architecture)를 참조합니다.

### 메모리 부족 이벤트 감지 {#detect-an-out-of-memory-event}

Kubernetes 배포의 경우 OOM 오류로 인해 컨테이너가 종료되었는지 확인합니다:

```shell
kubectl describe pod <your_pod_name> -n <your_namespace>
```

`OOMKilled``Last State` 범위에서 찾고, 0이 아닌 `Exit Code` (일반적으로 `137`)을(를) 찾습니다:

```plaintext
Last State: Terminated
  Reason: OOMKilled
  Exit Code: 137
```

모든 Zoekt 포드 전체에서 재시작 횟수를 확인할 수도 있습니다:

```shell
kubectl get pods -n <your_namespace> -l app=gitlab-zoekt
```

포드의 높은 `RESTARTS` 수는 반복된 OOM 종료를 나타냅니다. 레이블 선택기 `app=gitlab-zoekt`는 차트 버전 또는 운영자 구성에 따라 다를 수 있습니다.

[kube-state-metrics](https://github.com/kubernetes/kube-state-metrics)가 설치되어 있으면 Prometheus 또는 Grafana에서 이러한 메트릭을 모니터링할 수도 있습니다:

- `kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}`: OOM으로 인해 종료된 포드입니다.
- `kube_pod_container_status_waiting_reason{reason="CrashLoopBackOff"}`: 충돌 루프에 있는 포드입니다.
- `kube_pod_container_status_restarts_total`: 컨테이너당 누적 재시작 횟수입니다. 빠른 증가는 반복된 충돌을 나타냅니다.

웹 서버는 `process_resident_memory_bytes`을(를) `/metrics` 범위의 포트 `6070`에 표시합니다. 웹 서버 포드에 직접 Prometheus를 구성했으면 이 메트릭을 사용하여 시간 경과에 따른 웹 서버 거주자 메모리 사용을 모니터링할 수 있습니다.

VM 및 베어 메탈 배포의 경우 OOM 이벤트에 대한 시스템 저널을 확인합니다:

```shell
sudo journalctl -k | grep -i "oom\|killed process"
```

### 메모리 부족 이벤트에서 복구 {#recover-from-an-out-of-memory-event}

복구 단계는 OOM 오류가 발생하는 구성 요소에 따라 다릅니다.

#### 인덱서 메모리 부족 오류 {#indexer-out-of-memory-errors}

인덱서가 OOM 오류로 인해 반복적으로 종료되는 경우 인덱싱을 전역적으로 일시 중지하여 조사 중에 모든 노드 전체에서 모든 새 인덱싱 작업을 중지합니다:

```shell
gitlab-rake gitlab:zoekt:pause_indexing
```

또는 UI에서 인덱싱을 일시 중지합니다:

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **인덱싱 일시 정지** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

노드를 안정화한 후 인덱싱을 다시 시작합니다:

```shell
gitlab-rake gitlab:zoekt:resume_indexing
```

#### 웹 서버 메모리 부족 오류 {#webserver-out-of-memory-errors}

웹 서버가 OOM 오류로 인해 반복적으로 종료되는 경우 조사하는 동안 Zoekt 검색을 비활성화합니다. 이렇게 하면 인덱싱에 영향을 주지 않으면서 충돌하는 노드에 대한 검색 트래픽이 중지됩니다.

> [!note]
> Zoekt 검색이 비활성화되면 코드 검색은 기본 검색 모드로 돌아갑니다. Elasticsearch를 사용할 수 없으면 기본 검색 모드에서는 프로젝트 범위 코드 검색만 가능하므로 Gitaly의 로드가 증가합니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **검색 활성화** 확인란을 선택 해제합니다.
1. **변경 사항 저장**을 선택합니다.

노드를 안정화한 후 검색을 다시 활성화합니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **검색 활성화** 확인란을 선택합니다.
1. **변경 사항 저장**을 선택합니다.

### 메모리 압력 감소 {#reduce-memory-pressure}

노드의 크기가 올바르지만 여전히 메모리 압력이 발생하는 경우 다음 설정을 조정하여 메모리 사용을 줄입니다.

#### 병렬 인덱싱 프로세스 감소 {#reduce-parallel-indexing-processes}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

최대 인덱서 메모리를 줄이려면 인덱싱 작업당 병렬 프로세스 수를 낮춥니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **인덱식 작업당 병렬 프로세스의 개수**를 `1`로 설정합니다.
1. **변경 사항 저장**을 선택합니다.

#### 동시 인덱싱 작업 감소 {#reduce-concurrent-indexing-tasks}

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

동시에 실행되는 인덱싱 작업의 수를 줄이려면 **CPU를 작업 배수로 인덱싱** 값을 낮춥니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **CPU를 작업 배수로 인덱싱** 값을 낮춥니다 (예: `0.5`로).
1. **변경 사항 저장**을 선택합니다.

#### 강제 재색인 확률 증가 {#increase-force-reindexing-probability}

Zoekt 웹 서버는 인덱스 샤드를 메모리 맵핑합니다. 시간이 지남에 따라 증분 인덱싱은 많은 작은 샤드를 누적하여 열린 mmap 핸들 수를 증가시킵니다. 강제 재색인은 인덱스를 완전히 재구성하여 샤드를 더 적은 수의 더 큰 파일로 통합하여 메모리 오버헤드를 줄입니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

샤드 누적을 줄이려면 강제 재색인 확률을 높입니다:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택합니다.
1. **정확한 코드 검색**을 확장합니다.
1. **랜덤 포스 재색인 확률 (백분율)** 값을 높입니다. 기본값은 `0.25` (0.25%)입니다. 예를 들어, 대략 1 in 100 증분 인덱싱 작업을 강제로 재색인하려면 `1`로 설정합니다.
1. **변경 사항 저장**을 선택합니다.

### 노드 크기 조정 {#right-size-the-node}

설정을 조정해도 반복된 OOM 이벤트가 해결되지 않으면 노드에 더 많은 메모리가 필요합니다. 인덱스 크기에 따른 메모리 할당에 대한 지침은 [크기 조정 권장 사항](_index.md#sizing-recommendations)을 참조합니다.

Kubernetes 배포의 경우 Helm 차트 `values.yaml`에서 메모리 요청 및 제한을 증가시킵니다. 메모리 제한이 디스크 티어의 크기 조정 표에 있는 값과 같거나 그 이상인지 확인합니다.

VM 및 베어 메탈 배포의 경우 크기 조정 표에서 더 큰 범위 유형으로 이동하거나 추가 노드를 추가하여 인덱스를 더 많은 머신 전체에 배포합니다.

크기 조정 후 상태 확인을 실행하여 노드가 복구되었는지 확인합니다:

```shell
gitlab-rake gitlab:zoekt:health
```

## Zoekt 노드 연결 확인 {#verify-zoekt-node-connections}

Zoekt 노드가 제대로 구성되고 연결되었는지 확인하려면 [Rails 콘솔 세션](../../administration/operations/rails_console.md#starting-a-rails-console-session)에서:

- 구성된 Zoekt 노드의 총 수를 확인합니다:

  ```ruby
  Search::Zoekt::Node.count
  ```

- 몇 개의 노드가 온라인 상태인지 확인합니다:

  ```ruby
  Search::Zoekt::Node.online.count
  ```

또는 `gitlab:zoekt:info` Rake 작업을 사용할 수 있습니다.

온라인 노드의 수가 구성된 노드의 수보다 낮거나 노드가 구성되어 있을 때 0이면 GitLab과 Zoekt 노드 간에 연결 이슈가 있을 수 있습니다.

## Zoekt 연결 오류 디버그 {#debug-zoekt-connection-errors}

Zoekt에서 연결 이슈가 발생할 때 요청 흐름을 이해하고 아키텍처의 각 구성 요소를 체계적으로 확인하는 것이 중요합니다.

### Zoekt 아키텍처 {#zoekt-architecture}

Zoekt는 두 가지 모드로 작동할 수 있는 통합 바이너리(`gitlab-zoekt`)를 사용합니다:

- Gitaly에서 리포지토리를 인덱싱하기 위한 인덱서 모드
- 검색 요청을 제공하기 위한 웹 서버 모드

기본 검색 흐름은:

```plaintext
GitLab Rails → Zoekt webserver
```

Helm 차트(Kubernetes) 배포의 경우 아키텍처는 로드 밸런싱을 위한 추가 게이트웨이 구성 요소를 포함합니다:

```plaintext
GitLab Rails → external gateway (NGINX) → internal gateway (NGINX) → Zoekt webserver
```

이러한 게이트웨이 구성 요소는 Helm 차트 배포의 일부이며 내부 Zoekt 구성 요소가 아닙니다. 이들은 여러 Zoekt 웹 서버 범위 전체에 요청을 배포하고 라우팅, 로드 밸런싱 및 선택적 TLS 종료를 처리하는 NGINX 프록시입니다.

Zoekt 아키텍처 디자인에 대한 자세한 내용은 [코드 검색을 위한 Zoekt 사용](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/code_search_with_zoekt/)을 참조합니다.

### 네트워크 도달성 확인 {#verify-network-reachability}

Zoekt 게이트웨이가 GitLab Rails 포드에서 도달 가능한지 확인하려면 [상태 확인 실행](_index.md#run-a-health-check):

```shell
gitlab-rake gitlab:zoekt:health
```

이 작업은 Rails에서 Zoekt로의 연결을 확인하고 전체 상태를 `HEALTHY`, `DEGRADED` 또는 `UNHEALTHY`로 보고합니다. 상태 확인이 실패하면 GitLab과 Zoekt 인프라 간에 네트워크 연결 이슈가 있을 수 있습니다.

노드 상태와 구성을 확인하려면 다음 Rake 작업을 실행합니다:

```shell
gitlab-rake gitlab:zoekt:info
```

URL을 포함한 자세한 노드 정보를 보려면 [Rails 콘솔](../../administration/operations/rails_console.md#starting-a-rails-console-session)에서 다음 명령을 실행합니다:

```ruby
# View all node attributes including URLs
Search::Zoekt::Node.all.map(&:attributes)
```

- `search_base_url`은(는) Zoekt 웹 서버 또는 Kubernetes의 외부 게이트웨이를 가리켜야 합니다 (예: `http://gitlab-zoekt:8080/`).
- `index_base_url`은(는) Zoekt 인덱서를 가리켜야 합니다.

검색할 때 `404` 응답이 나타나면 요청이 제대로 라우팅되지 않을 수 있습니다. 이 오류는 이슈가 네트워크 연결이 아닌 게이트웨이 구성일 가능성이 높음을 나타냅니다.

### Zoekt 로그 모니터링 {#monitor-zoekt-logs}

Helm 차트(Kubernetes) 배포의 경우 Zoekt 구성 요소 로그를 모니터링하여 연결 이슈를 식별합니다.

`StatefulSet`에 세 개의 컨테이너가 포함되어 있습니다:

```shell
# Monitor webserver logs (search requests from Rails)
kubectl logs -f statefulset/gitlab-zoekt -c zoekt-webserver -n <your_namespace>

# Monitor indexer logs (repository indexing)
kubectl logs -f statefulset/gitlab-zoekt -c zoekt-indexer -n <your_namespace>

# Monitor internal gateway logs (NGINX proxy between the external gateway and webserver)
kubectl logs -f statefulset/gitlab-zoekt -c zoekt-internal-gateway -n <your_namespace>
```

외부 게이트웨이 배포를 사용 중인 경우 외부 게이트웨이 로그도 모니터링할 수 있습니다:

```shell
# Monitor external gateway logs (NGINX proxy for incoming requests from Rails)
kubectl logs -f deployment/gitlab-zoekt-gateway -c zoekt-external-gateway -n <your_namespace>
```

이 로그를 모니터링하는 동안 GitLab UI에서 테스트 검색을 실행합니다. 로그에 처리 중인 요청이 표시되어야 합니다. 요청이 로그에 나타나지 않으면 Rails와 Zoekt 간에 네트워크 라우팅 이슈가 있을 수 있습니다.

### UI에서 테스트 검색 실행 {#run-test-searches-from-the-ui}

Zoekt 로그를 모니터링하는 동안 GitLab UI에서 테스트 검색을 실행할 수 있습니다:

- 특정 노드에 대한 프로젝트에서 검색합니다.
- 여러 노드를 쿼리하려면 그룹에서 검색합니다.
- 모든 노드를 쿼리하려면 전역적으로 검색합니다.

검색이 실패하면 자세한 오류 메시지에 대한 Rails 애플리케이션 로그를 확인합니다:

```shell
# For installations that use the Linux package
tail -f /var/log/gitlab/gitlab-rails/application_json.log | grep -i zoekt

# For self-compiled installations
tail -f log/application_json.log | grep -i zoekt
```

GitLab과 Zoekt 인프라 간의 네트워크 이슈를 나타낼 수 있는 연결 오류, 시간 초과 또는 인증 오류를 찾습니다.

### 포드 및 서비스 상태 확인 {#verify-pod-and-service-status}

Helm 차트(Kubernetes) 배포의 경우 Zoekt 포드 및 서비스의 상태를 확인합니다:

```shell
# Check pod status
kubectl get pods -n <your_namespace> -l app=gitlab-zoekt

# Check `StatefulSet` status
kubectl get statefulset gitlab-zoekt -n <your_namespace>

# Check service endpoints
kubectl get endpoints gitlab-zoekt -n <your_namespace>

# Describe the service to see the configuration
kubectl describe service gitlab-zoekt -n <your_namespace>
```

모든 포드가 실행 중 상태이고 서비스에 유효한 엔드포인트가 있는지 확인합니다. 포드가 실행 중이 아니거나 엔드포인트가 누락되면 Zoekt 배포에 구성 이슈가 있을 수 있습니다.

배포 아키텍처에 대한 자세한 내용은 다음을 참조하세요:

- [외부 게이트웨이 배포 구성](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt/-/blob/main/templates/deployment.yaml)
- [`StatefulSet` 구성 (인덱서, 웹 서버 및 내부 게이트웨이)](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt/-/blob/main/templates/stateful_sets.yaml)

## 오류: `TaskRequest responded with [401]` {#error-taskrequest-responded-with-401}

Zoekt 인덱서 로그에 `TaskRequest responded with [401]`이(가) 표시될 수 있습니다. 이 오류는 Zoekt 인덱서가 GitLab에 인증하지 못하고 있음을 나타냅니다.

이 이슈를 해결하려면 `gitlab-shell-secret`이(가) 올바르게 구성되고 GitLab 범위와 Zoekt 인덱서 간에 일치하는지 확인합니다. 예를 들어 다음 명령의 출력은 `gitlab.rb`의 `gitlab-shell-secret`와 일치해야 합니다:

```shell
kubectl get secret gitlab-shell-secret -o jsonpath='{.data.secret}' -n your_zoekt_namespace | base64 -d
```

## 오류: `missing selected ALPN property` {#error-missing-selected-alpn-property}

Zoekt 게이트웨이 앞에 외부 로드 밸런서를 사용하면 GitLab 로그에 다음 오류가 표시될 수 있습니다:

```plaintext
rpc error: code = Unavailable desc = connection error: desc = "transport: authentication handshake failed: credentials: cannot check peer: missing selected ALPN property"
```

이 오류는 로드 밸런서가 HTTP/2를 통해 ALPN(Application-Layer Protocol Negotiation)을 지원하거나 보급하지 않을 때 발생합니다. Zoekt는 노드 간 통신을 위해 gRPC에 의존하며, HTTP/2 지원이 필요합니다.

이 이슈를 해결하려면 다음 중 하나를 수행합니다:

- 로드 밸런서에서 HTTP/2 지원을 활성화합니다 (권장):

  1. 로드 밸런서를 구성하여 ALPN을 통해 HTTP/2를 지원하고 보급합니다:
     - HAProxy의 경우 백엔드에서 `alpn h2,http/1.1`이(가) 구성되어 있는지 확인합니다.
     - NGINX의 경우 서버 블록에서 다음을 사용합니다:
       - NGINX 1.25.1 이상의 경우 `http2 on;`입니다.
       - NGINX 1.25.0 이전의 경우 `listen 443 ssl http2;`입니다.
  1. HTTP/2 지원 확인:

     ```shell
     curl --verbose --http2 "https://your-zoekt-gateway-url/health" 2>&1 | grep ALPN
     ```

     다음과 유사한 출력이 표시되어야 합니다:

     ```plaintext
     * ALPN, server accepted to use h2
     ```

- TLS 통과 사용:

  로드 밸런서가 HTTP/2를 지원할 수 없으면 밸런서를 TLS 통과로 구성합니다. 그러면 Zoekt 게이트웨이가 TLS 종료를 직접 처리하여 적절한 ALPN 협상을 보장할 수 있습니다. TLS 통과를 사용하려면 Zoekt 게이트웨이에서 유효한 TLS 인증서를 구성합니다:

  1. Helm 차트 배포의 경우 `values.yaml`에서 인증서를 구성합니다:

     ```yaml
     gateway:
       tls:
         certificate:
           enabled: true
           secretName: zoekt-gateway-cert
     ```

  1. 로드 밸런서를 구성하여 TLS를 종료하지 않고 암호화된 트래픽을 통과시킵니다.
