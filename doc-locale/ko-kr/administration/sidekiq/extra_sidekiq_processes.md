---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 여러 Sidekiq 프로세스 실행
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

GitLab을 사용하면 단일 인스턴스에서 더 높은 속도로 백그라운드 작업을 처리하기 위해 여러 Sidekiq 프로세스를 시작할 수 있습니다. 기본적으로 Sidekiq은 하나의 워커 프로세스를 시작하며 단일 코어만 사용합니다.

> [!note]
> 이 페이지의 정보는 Linux 패키지 설치에만 적용됩니다.

## 여러 프로세스 시작 {#start-multiple-processes}

여러 프로세스를 시작할 때 프로세스의 개수는 최대한 Sidekiq에 할당하려는 CPU 코어 개수와 같아야 하며 **not**. Sidekiq 워커 프로세스는 최대 하나의 CPU 코어만 사용합니다.

여러 프로세스를 시작하려면 `sidekiq['queue_groups']` 배열 설정을 사용하여 `sidekiq-cluster`을(를) 사용하여 생성할 프로세스의 개수를 지정하고 어떤 큐를 처리할지 결정합니다. 배열의 각 항목은 하나의 추가 Sidekiq 프로세스에 해당하며, 각 항목의 값은 프로세스가 작동하는 큐를 결정합니다. 대부분의 경우 모든 프로세스는 모든 큐를 수신해야 합니다 ([특정 작업 클래스 처리](processing_specific_job_classes.md) 참조).

예를 들어 4개의 Sidekiq 프로세스를 생성하여 각각 사용 가능한 모든 큐를 수신하도록 하려면:

1. `/etc/gitlab/gitlab.rb`을 편집하세요:

   ```ruby
   sidekiq['queue_groups'] = ['*'] * 4
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

GitLab에서 Sidekiq 프로세스를 보려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **모니터링** > **백그라운드 작업**을(를) 선택합니다.

## 동시성 {#concurrency}

기본적으로 `sidekiq` 아래에 정의된 각 프로세스는 큐의 개수와 같은 수의 스레드로 시작하며, 여유 스레드 1개를 추가하고 최대 50개까지입니다. 예를 들어 모든 큐를 처리하는 프로세스는 기본적으로 50개의 스레드를 사용합니다.

이러한 스레드는 단일 Ruby 프로세스 내에서 실행되며, 각 프로세스는 단일 CPU 코어만 사용할 수 있습니다. 스레딩의 유용성은 데이터베이스 쿼리 또는 HTTP 요청과 같이 대기할 외부 종속성이 있는 작업에 따라 달라집니다. 대부분의 Sidekiq 배포는 이러한 스레딩의 이점을 누립니다.

## 데이터베이스 연결 계획 {#database-connection-planning}

Sidekiq 프로세스 또는 동시성을 늘리기 전에 PostgreSQL `max_connections` 설정에 대한 데이터베이스 연결 영향을 고려합니다.

자세한 연결 계획 및 계산은 [PostgreSQL 튜닝](../postgresql/tune.md) 페이지를 참조합니다.

### 스레드 수를 명시적으로 관리합니다 {#manage-thread-counts-explicitly}

올바른 최대 스레드 수(동시성이라고도 함)는 워크로드에 따라 다릅니다. 일반적인 값은 CPU 바운드 작업의 경우 `5`부터 혼합 낮은 우선 순위 작업의 경우 `15` 이상입니다. 합리적인 시작 범위는 전문적이지 않은 배포의 경우 `15`부터 `25`입니다.

값은 각 특정 Sidekiq 배포가 수행하는 작업에 따라 달라집니다. 특정 큐에 전담하는 프로세스가 있는 다른 특수한 배포는 다음에 따라 동시성을 조정해야 합니다:

- 각 프로세스 유형의 CPU 사용량.
- 달성된 처리량.

각 스레드는 Redis 연결이 필요하므로 스레드를 추가하면 Redis 레이턴시가 증가하고 클라이언트 타임아웃이 발생할 수 있습니다. [Redis에 대한 Sidekiq 문서](https://github.com/mperham/sidekiq/wiki/Using-Redis)를 참조합니다.

#### 동시성 필드를 사용하여 스레드 수 관리 {#manage-thread-counts-with-concurrency-field}

{{< history >}}

- GitLab 16.9에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/439687)되었습니다.

{{< /history >}}

GitLab 16.9 이상에서는 `concurrency`을(를) 설정하여 동시성을 설정할 수 있습니다. 이 값은 각 프로세스가 이 정도의 동시성을 명시적으로 설정합니다.

예를 들어 동시성을 `20`로 설정하려면:

1. `/etc/gitlab/gitlab.rb`을 편집하세요:

   ```ruby
   sidekiq['concurrency'] = 20
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 확인 간격 수정 {#modify-the-check-interval}

추가 Sidekiq 프로세스의 Sidekiq 상태 확인 간격을 수정하려면:

1. `/etc/gitlab/gitlab.rb`을 편집하세요:

   ```ruby
   sidekiq['interval'] = 5
   ```

   값은 초 단위의 정수입니다.

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## CLI를 사용하여 문제 해결 {#troubleshoot-using-the-cli}

> [!warning]
> Sidekiq 프로세스를 구성하기 위해 `/etc/gitlab/gitlab.rb`을(를) 사용하는 것이 좋습니다. 문제가 발생하면 GitLab 지원팀에 문의해야 합니다. 명령줄을 사용할 때는 스스로의 책임 하에 사용합니다.

디버깅 목적으로 `/opt/gitlab/embedded/service/gitlab-rails/bin/sidekiq-cluster` 명령을 사용하여 추가 Sidekiq 프로세스를 시작할 수 있습니다. 이 명령은 다음 구문을 사용하는 인수를 사용합니다:

```shell
/opt/gitlab/embedded/service/gitlab-rails/bin/sidekiq-cluster [QUEUE,QUEUE,...] [QUEUE, ...]
```

`--dryrun` 인수를 사용하면 실제로 시작하지 않고도 실행할 명령을 볼 수 있습니다.

각 별도 인수는 Sidekiq 프로세스에서 처리해야 하는 큐 그룹을 나타냅니다. 같은 프로세스로 여러 큐를 처리할 수 있으며, 공백 대신 쉼표로 분리합니다.

큐 대신 큐 네임스페이스를 제공할 수도 있으며, 프로세스가 모든 큐 이름을 명시적으로 나열할 필요 없이 해당 네임스페이스 내의 모든 큐를 자동으로 수신하도록 할 수 있습니다. 큐 네임스페이스에 대한 자세한 내용은 GitLab 개발 문서의 Sidekiq 개발 부분에서 관련 섹션을 참조합니다.

### `sidekiq-cluster` 명령 모니터링 {#monitor-the-sidekiq-cluster-command}

`sidekiq-cluster` 명령은 원하는 양의 Sidekiq 프로세스를 시작한 후에는 종료되지 않습니다. 대신 프로세스는 계속 실행되고 자식 프로세스에 신호를 전달합니다. 이를 통해 모든 Sidekiq 프로세스를 중지할 수 있습니다. `sidekiq-cluster` 프로세스에 신호를 보낼 때 개별 프로세스에 신호를 보낼 필요가 없습니다.

`sidekiq-cluster` 프로세스가 충돌하거나 `SIGKILL`를 수신하면 자식 프로세스는 몇 초 후에 스스로 종료됩니다. 이렇게 하면 좀비 Sidekiq 프로세스가 남지 않습니다.

이를 통해 `sidekiq-cluster`을(를) 선택한 감시자(예: runit)에 연결하여 프로세스를 모니터링할 수 있습니다.

자식 프로세스가 죽으면 `sidekiq-cluster` 명령은 모든 나머지 프로세스에 종료 신호를 보낸 다음 스스로 종료됩니다. 이렇게 하면 `sidekiq-cluster`이(가) 복잡한 프로세스 모니터링/재시작 코드를 다시 구현할 필요가 없습니다. 대신 감시자가 필요할 때마다 `sidekiq-cluster` 프로세스를 다시 시작하도록 해야 합니다.

### PID 파일 {#pid-files}

`sidekiq-cluster` 명령은 PID를 파일에 저장할 수 있습니다. 기본적으로 PID 파일을 쓰지 않지만 `--pidfile` 옵션을 `sidekiq-cluster`에 전달하여 변경할 수 있습니다. 예를 들어:

```shell
/opt/gitlab/embedded/service/gitlab-rails/bin/sidekiq-cluster --pidfile /var/run/gitlab/sidekiq_cluster.pid process_commit
```

PID 파일에는 `sidekiq-cluster` 명령의 PID가 포함되어 있으며 시작된 Sidekiq 프로세스의 PID가 아닙니다.

### 환경 {#environment}

Rails 환경은 `--environment` 플래그를 `sidekiq-cluster` 명령에 전달하거나 `RAILS_ENV`을(를) 비어 있지 않은 값으로 설정하여 설정할 수 있습니다. 기본값은 `/opt/gitlab/etc/gitlab-rails/env/RAILS_ENV`에서 찾을 수 있습니다.
