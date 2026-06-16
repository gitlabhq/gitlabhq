---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 메모리 사용 감소
---

Sidekiq 메모리 킬러는 너무 많은 메모리를 소비하는 백그라운드 작업 프로세스를 자동으로 관리합니다. 이 기능은 워커 프로세스를 모니터링하고 Linux 메모리 킬러가 개입하기 전에 재시작하므로, 백그라운드 작업이 완료될 때까지 실행되고 정상적으로 종료될 수 있습니다. 이러한 이벤트를 로깅하면 높은 메모리 사용을 초래하는 작업을 더 쉽게 식별할 수 있습니다.

## Sidekiq 메모리 모니터링 방법 {#how-we-monitor-sidekiq-memory}

GitLab은 기본적으로 Linux 패키지 또는 Docker 설치에 대해서만 사용 가능한 RSS 한도를 모니터링합니다. 이는 GitLab이 메모리 유도 종료 후 Sidekiq을 재시작하기 위해 runit에 의존하며, 자체 컴파일 및 Helm 차트 설치는 runit 또는 동등한 도구를 사용하지 않기 때문입니다.

기본 설정에서 Sidekiq은 15분마다 한 번 이상 재시작되지 않으며, 재시작으로 인해 들어오는 백그라운드 작업에 약 1분의 지연이 발생합니다.

일부 백그라운드 작업은 오래 실행되는 외부 프로세스에 의존합니다. Sidekiq을 재시작할 때 이들이 정상적으로 종료되도록 하기 위해, 각 Sidekiq 프로세스는 프로세스 그룹 리더로 실행되어야 합니다(예: `chpst -P` 사용). Linux 패키지 설치 또는 `bin/background_jobs` 스크립트가 `runit`과(와) 함께 설치된 경우, 이는 자동으로 처리됩니다.

## 한도 구성 {#configuring-the-limits}

Sidekiq 메모리 한도는 [환경 변수](https://docs.gitlab.com/omnibus/settings/environment-variables/#setting-custom-environment-variables)를 사용하여 제어됩니다

- `SIDEKIQ_MEMORY_KILLER_MAX_RSS` (KB): 허용된 RSS에 대한 Sidekiq 프로세스 소프트 한도를 정의합니다. Sidekiq 프로세스 RSS(KB 단위로 표현)가 `SIDEKIQ_MEMORY_KILLER_MAX_RSS`을(를) 초과하고 `SIDEKIQ_MEMORY_KILLER_GRACE_TIME`보다 오래 지속되면, 정상적인 재시작이 트리거됩니다. `SIDEKIQ_MEMORY_KILLER_MAX_RSS`가 설정되지 않았거나 값이 0으로 설정된 경우, 소프트 한도가 모니터링되지 않습니다. `SIDEKIQ_MEMORY_KILLER_MAX_RSS`의 기본값은 `2000000`입니다.
- `SIDEKIQ_MEMORY_KILLER_GRACE_TIME`: Sidekiq 프로세스가 허용된 RSS 소프트 한도 이상으로 실행될 수 있는 유예 시간(초)을 정의합니다. Sidekiq 프로세스가 `SIDEKIQ_MEMORY_KILLER_GRACE_TIME` 내에서 허용된 RSS(소프트 한도) 이하로 떨어지면, 재시작이 중단됩니다. 기본값은 900초(15분)입니다.
- `SIDEKIQ_MEMORY_KILLER_HARD_LIMIT_RSS` (KB): 허용된 RSS에 대한 Sidekiq 프로세스 하드 한도를 정의합니다. Sidekiq 프로세스 RSS(KB 단위로 표현)가 `SIDEKIQ_MEMORY_KILLER_HARD_LIMIT_RSS`을(를) 초과하면, Sidekiq의 즉시 정상적인 재시작이 트리거됩니다. 이 값이 설정되지 않았거나 0으로 설정된 경우, 하드 한도가 모니터링되지 않습니다.

- `SIDEKIQ_MEMORY_KILLER_CHECK_INTERVAL`: 프로세스 RSS를 확인하는 빈도를 정의합니다. 기본값은 3초입니다.
- `SIDEKIQ_MEMORY_KILLER_SHUTDOWN_WAIT`: 모든 Sidekiq 작업이 완료되도록 허용된 최대 시간을 정의합니다. 그 시간 동안 새로운 작업은 허용되지 않습니다. 기본값은 30초입니다.

  Sidekiq에서 프로세스 재시작이 수행되지 않으면, Sidekiq 프로세스는 [Sidekiq 종료 시간 제한](https://github.com/mperham/sidekiq/wiki/Signals#term)(기본값 25초) +2초 후에 강제로 종료됩니다. 작업이 그 시간 동안 완료되지 않으면, 현재 실행 중인 모든 작업은 Sidekiq 프로세스로 전송된 `SIGTERM` 신호로 중단됩니다.

- `GITLAB_MEMORY_WATCHDOG_ENABLED`: 기본적으로 활성화됩니다. `GITLAB_MEMORY_WATCHDOG_ENABLED`을(를) false로 설정하여 Watchdog이 실행되지 않도록 비활성화합니다.

### 워커 재시작 모니터링 {#monitor-worker-restarts}

GitLab은 높은 메모리 사용으로 인해 워커가 재시작되면 로그 이벤트를 발생합니다.

다음은 `/var/log/gitlab/gitlab-rails/sidekiq_client.log`의 이러한 로그 이벤트 중 하나의 예입니다:

```json
{
  "severity": "WARN",
  "time": "2023-02-04T09:45:16.173Z",
  "correlation_id": null,
  "pid": 2725,
  "worker_id": "sidekiq_1",
  "memwd_handler_class": "Gitlab::Memory::Watchdog::SidekiqHandler",
  "memwd_sleep_time_s": 3,
  "memwd_rss_bytes": 1079683247,
  "memwd_max_rss_bytes": 629145600,
  "memwd_max_strikes": 5,
  "memwd_cur_strikes": 6,
  "message": "rss memory limit exceeded",
  "running_jobs": [
    {
      jid: "83efb701c59547ee42ff7068",
      worker_class: "Ci::DeleteObjectsWorker"
    },
    {
      jid: "c3a74503dc2637f8f9445dd3",
      worker_class: "Ci::ArchiveTraceWorker"
    }
  ]
}
```

여기서:

- `memwd_rss_bytes`은(는) 소비된 실제 메모리 양입니다.
- `memwd_max_rss_bytes`은(는) `per_worker_max_memory_mb`를 통해 설정된 RSS 한도입니다.
- `running jobs`은(는) 프로세스가 RSS 한도를 초과했을 때 실행 중이던 작업과 정상적인 재시작을 시작한 작업을 나열합니다.
