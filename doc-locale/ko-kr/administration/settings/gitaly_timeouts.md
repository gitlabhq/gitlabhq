---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gitaly 시간 초과 및 재시도
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

[Gitaly](../gitaly/_index.md)는 구성 가능한 두 가지 유형의 시간 초과를 제공합니다:

- GitLab UI를 사용하여 구성된 호출 시간 초과
- Gitaly 구성 파일을 사용하여 구성된 협상 시간 초과

## 호출 시간 초과 구성 {#configure-the-call-timeouts}

다음 호출 시간 초과를 구성하여 장시간 실행되는 Gitaly 호출이 불필요하게 리소스를 사용하지 않도록 합니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

호출 시간 초과를 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **Gitaly 시간 초과** 섹션을 확장합니다.
1. 필요에 따라 각 시간 초과를 설정합니다.

### 사용 가능한 호출 시간 초과 {#available-call-timeouts}

다양한 Gitaly 작업에 대해 다양한 호출 시간 초과를 사용할 수 있습니다.

| 시간 초과 | 기본값    | 설명 |
|:--------|:-----------|:------------|
| 기본값 | 55초 | 대부분의 Gitaly 호출에 대한 시간 초과(`git` `fetch` 및 `push` 작업 또는 Sidekiq 작업에는 적용되지 않음). 예를 들어 리포지토리가 디스크에 있는지 확인합니다. 웹 요청에서 수행된 Gitaly 호출이 전체 요청 시간 초과를 초과하지 않도록 합니다. [워커 시간 초과](../operations/puma.md#change-the-worker-timeout) 보다 짧아야 하며, [Puma](../../install/requirements.md#puma)에 대해 구성할 수 있습니다. Gitaly 호출 시간 초과가 워커 시간 초과를 초과하면 워커를 종료하지 않도록 워커 시간 초과의 남은 시간이 사용됩니다. |
| 빠름    | 10초 | 요청에서 사용되는 빠른 Gitaly 작업에 대한 시간 초과(때로는 여러 번). 예를 들어 리포지토리가 디스크에 있는지 확인합니다. 빠른 작업이 이 임계값을 초과하면 스토리지 샤드에 문제가 있을 수 있습니다. 빠르게 실패하면 GitLab 인스턴스의 안정성을 유지하는 데 도움이 됩니다. |
| 중간  | 30초 | 빠르게(요청에서 가능) 수행되어야 하지만 요청에서 여러 번 사용되지 않는 것이 좋은 Gitaly 작업에 대한 시간 초과. 예를 들어 blob을 로드합니다. 기본값과 빠름 사이에 설정해야 하는 시간 초과. |

기본적으로 **기본값** 시간 초과는 `57` 초보다 높게 설정할 수 없습니다. 자세한 내용은 [Gitaly 기본 시간 초과를 57초 이상으로 늘릴 수 없음](#unable-to-raise-gitaly-default-timeout-above-57-seconds)을 참조하세요.

## 협상 시간 초과 구성 {#configure-the-negotiation-timeouts}

{{< history >}}

- GitLab 16.5에서 [도입](https://gitlab.com/gitlab-org/gitaly/-/issues/5574)되었습니다.

{{< /history >}}

협상 시간 초과를 늘려야 할 수도 있습니다:

- 특히 큰 리포지토리의 경우.
- 이러한 명령을 병렬로 수행할 때.

다음에 대해 협상 시간 초과를 구성할 수 있습니다:

- `git-upload-pack(1)`는 `git fetch`를 실행할 때 Gitaly 노드에 의해 호출됩니다.
- `git-upload-archive(1)`는 `git archive --remote`를 실행할 때 Gitaly 노드에 의해 호출됩니다.

이러한 시간 초과를 구성하려면:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

`/etc/gitlab/gitlab.rb`을 편집하세요:

```ruby
gitaly['configuration'] = {
    timeout: {
        upload_pack_negotiation: '10m',      # 10 minutes
        upload_archive_negotiation: '20m',   # 20 minutes
    }
}
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

`/home/git/gitaly/config.toml`을 편집하세요:

```toml
[timeout]
upload_pack_negotiation = "10m"
upload_archive_negotiation = "20m"
```

{{< /tab >}}

{{< /tabs >}}

값의 경우 Go에서 [`ParseDuration`](https://pkg.go.dev/time#ParseDuration) 형식을 사용합니다.

이러한 시간 초과는 전체 전송이 아니라 원격 Git 작업의 [협상 단계](https://git-scm.com/docs/pack-protocol/2.2.3#_packfile_negotiation)에만 영향을 미칩니다.

## Gitaly 클라이언트 재시도 {#gitaly-client-retries}

{{< history >}}

- GitLab 18.10에 [도입됨](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/work_items/811).

{{< /history >}}

Gitaly는 때때로 일시적으로 사용할 수 없습니다. 예를 들어 GitLab 업그레이드 중입니다. 특히 Pod가 시작되고 재시작하는 데 몇 초가 걸리는 Kubernetes의 Gitaly를 사용할 때.

Gitaly가 일시적으로 사용할 수 없을 때 GitLab이 클라이언트에 오류를 반환하지 않도록 Gitaly 클라이언트 재시도를 구성합니다. Gitaly 클라이언트 재시도가 구성되고 Gitaly를 사용할 수 없으면 Rails(GitLab 애플리케이션), Workhorse, GitLab Shell과 같은 Gitaly 클라이언트는 지수 백오프 방식으로 요청을 재시도합니다.

두 가지 매개변수를 구성할 수 있습니다:

- `max_attempts`:  2~5 사이의 최대 재시도 횟수.
- `max_backoff`:  클라이언트가 재시도를 중지하기 전까지의 최대 시간. 값은 `1.4s` 또는 `10s`과 같은 기간 문자열이어야 합니다.

백오프 승수는 `2`로 설정되고 초기 백오프는 두 매개변수에서 파생됩니다.

### 구성 지침 {#configuration-guidelines}

올바른 구성은 GitLab 인스턴스 설정 및 Gitaly가 사용 불가능한 상태로 유지되는 기간에 따라 다릅니다:

- Kubernetes에서 Gitaly Pod는 클라우드 공급자에 따라 시작하는 데 약 10~12초가 걸릴 수 있습니다. 시간에는 볼륨을 Pod에 연결하고 마운트하는 데 걸리는 시간이 포함됩니다.
- Linux 패키지 인스턴스의 경우 Gitaly를 다시 시작하는 것이 프로세스 재시작이기 때문에 Gitaly가 훨씬 빠르게 재시작될 수 있습니다.

또한 Gitaly는 정상 종료 시간 초과로 구성될 수 있다는 점을 염두에 두어야 합니다. Gitaly가 종료될 때 새 요청은 거부되지만 gRPC 서버는 다음 중 하나가 될 때까지 비행 중인 요청을 계속 처리합니다:

- 모두 제공됩니다.
- 종료 시간 초과가 경과합니다.

이 정상 종료 시간 초과는 Gitaly가 새 요청에 사용 불가능한 상태로 유지되는 기간에 영향을 미칠 수 있습니다.

클라이언트 재시도를 `max_backoff`로 구성해야 하며, 이는 정상 종료 + (재)시작 시간의 합과 같거나 커야 합니다.

### 클라이언트 재시도 구성 {#configure-client-retries}

다음 구성은 Rails(GitLab 애플리케이션), Workhorse, GitLab Shell에 적용되며 모든 클라이언트에 동일한 구성이 적용됩니다.

제공된 값은 예시이며 지침으로 취급하지 않아야 합니다.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

`gitlab.rb` 파일을 다음 구성으로 업데이트합니다:

```ruby
gitlab_rails['gitaly_client_max_attempts'] = 5
gitlab_rails['gitaly_client_max_backoff'] = '1.4s'
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

`values.yml` 파일을 다음 구성으로 업데이트합니다:

```yaml
global:
  gitaly:
    client:
      maxAttempts: 5
      maxBackoff: '1.4s'
```

{{< /tab >}}

{{< /tabs >}}

## 문제 해결 {#troubleshooting}

Gitaly 시간 초과로 작업할 때 다음 이슈가 발생할 수 있습니다.

### Gitaly 기본 시간 초과를 57초 이상으로 늘릴 수 없음 {#unable-to-raise-gitaly-default-timeout-above-57-seconds}

> [!warning]
> 필요한 경우에만 이러한 값을 늘립니다. 워커 시간 초과가 높을수록 느리거나 중단된 요청이 Puma 워커를 더 오래 점유하여 인스턴스 용량이 감소합니다. Gitaly **기본값** 시간 초과를 높이는 일반적인 이유는 느린 스토리지의 매우 큰 리포지토리, 비싼 차이 또는 비교 보기, 또는 성능 저하된 Gitaly 클러스터 노드입니다. 가져오기, 미러, 또는 하우스키핑과 같은 배경 작업의 경우 이 제한에 의해 제한되지 않는 Sidekiq으로 오프로딩하는 것이 좋습니다.

기본적으로 [**기본값** 시간 초과](#available-call-timeouts)는 `57` 초 이상으로 늘릴 수 없습니다. 시간 초과를 더 높게 설정하려고 하면 유효성 검사 오류가 발생합니다:

```plaintext
Gitaly timeout default must be less than or equal to 57
```

이 제한은 세 가지 상호 작용하는 시간 초과에 의해 적용됩니다:

- `puma['worker_timeout']`:  워커별 Puma 시간 초과. 기본값은 `60` 초입니다. 자세한 내용은 [워커 시간 초과 변경](../operations/puma.md#change-the-worker-timeout)을 참조하세요.
- `gitlab_rails['max_request_duration_seconds']` - GitLab **기본값** 시간 초과를 제한하는 GitLab 애플리케이션 설정입니다. 기본값은 `(worker_timeout * 0.95).ceil` = `57` 초입니다. 이 설정은 `puma['worker_timeout']`보다 엄격히 작아야 합니다.
- `GITLAB_RAILS_RACK_TIMEOUT` - `Rack::Timeout` 미들웨어 `service_timeout`입니다. 기본값은 `60` 초입니다. 이 시간 초과는 다른 두 시간 초과와 독립적이며 다른 시간 초과의 구성 방식에 관계없이 이 값에서 요청을 종료합니다.

Gitaly **기본값** 시간 초과를 57초 이상으로 높이려면 세 값을 모두 함께 늘려야 합니다. 예를 들어 Gitaly **기본값** 시간 초과를 `110` 초로 허용하려면:

1. `/etc/gitlab/gitlab.rb`을 편집하세요:

   ```ruby
   puma['worker_timeout'] = 120
   gitlab_rails['max_request_duration_seconds'] = 114
   gitlab_rails['env'] = {
     'GITLAB_RAILS_RACK_TIMEOUT' => 120
   }
   ```

1. GitLab을 재구성하세요:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **환경설정**을 선택합니다.
1. **Gitaly 시간 초과**를 확장합니다.
1. **기본 시간 초과**를 새로 원하는 값(최대 `max_request_duration_seconds`)으로 설정합니다.

   작은 여유를 남기는 것이 좋습니다. 기본 제공 기본값은 5% 간격(`max_request_duration_seconds = (worker_timeout * 0.95).ceil`)을 사용하므로 Puma가 워커 시간 초과에 도달하기 전에 Rails 요청 기한이 경과합니다.

   `GITLAB_RAILS_RACK_TIMEOUT`는 자체적으로 Gitaly 제한을 높이지 **not**. `Settings.gitlab.max_request_duration_seconds`은 애플리케이션 설정 유효성 검사기가 참조하는 것이며, `gitlab_rails['max_request_duration_seconds']`에 의해 설정됩니다. 그러나 `GITLAB_RAILS_RACK_TIMEOUT`을 기본값인 `60` 초로 두면 Rack 미들웨어가 60초보다 긴 모든 요청(장시간 Gitaly 호출 포함)을 완료되기 전에 종료합니다.
