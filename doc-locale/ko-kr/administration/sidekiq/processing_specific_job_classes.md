---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 특정 작업 클래스 처리
---

> [!warning]
> 이것은 고급 설정입니다. GitLab.com에서 사용되지만, 대부분의 GitLab 인스턴스는 모든 큐를 수신 대기하는 더 많은 프로세스를 추가해야 합니다. 이것은 [참조 아키텍처](../reference_architectures/_index.md)에 설명된 것과 동일한 접근 방식입니다.

대부분의 GitLab 인스턴스는 [모든 프로세스가 모든 큐를 수신 대기](extra_sidekiq_processes.md#start-multiple-processes)하도록 해야 합니다.

다른 대안은 [라우팅 규칙](#routing-rules)을 사용하는 것입니다. 이것은 애플리케이션 내의 특정 작업 클래스를 사용자가 구성한 큐 이름으로 직접 라우팅합니다. 그러면 Sidekiq 프로세스는 구성된 큐 중 일부만 수신 대기하면 됩니다. 이렇게 하면 Redis의 로드가 감소하며, 이는 매우 대규모 배포에서 중요합니다.

## 라우팅 규칙 {#routing-rules}

{{< history >}}

- [기본 라우팅 규칙 값](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/97908)은 GitLab 15.4에서 도입되었습니다.
- 큐 선택기가 GitLab 17.0에서 [라우팅 규칙으로 변경](https://gitlab.com/gitlab-org/gitlab/-/issues/390787)되었습니다.

{{< /history >}}

> [!note]
> 메일러 작업은 라우팅 규칙으로 라우팅할 수 없으며 항상 `mailers` 큐로 이동합니다. 라우팅 규칙을 사용할 때는 최소한 하나의 프로세스가 `mailers` 큐를 수신 대기하는지 확인하세요. 일반적으로 이것은 `default` 큐 옆에 배치할 수 있습니다.

대부분의 GitLab 인스턴스가 라우팅 규칙을 사용하여 Sidekiq 큐를 관리할 것을 권장합니다. 이것은 관리자가 특성에 따라 작업 클래스 그룹에 대한 단일 큐 이름을 선택할 수 있게 합니다. 구문은 `[query, queue]`의 순서 있는 쌍 배열입니다:

1. 쿼리는 [워커 일치 쿼리](#worker-matching-query)입니다.
1. 큐 이름은 유효한 Sidekiq 큐 이름이어야 합니다. 큐 이름이 `nil`이거나 빈 문자열이면 워커는 워커 이름으로 생성된 큐로 라우팅됩니다. ([사용 가능한 작업 클래스 목록](#list-of-available-job-classes)을 참고하세요). 큐 이름은 사용 가능한 작업 클래스 목록의 기존 큐 이름과 일치할 필요가 없습니다.
1. 워커와 일치하는 첫 번째 쿼리가 해당 워커에 대해 선택되고 이후 규칙은 무시됩니다.

### 라우팅 규칙 마이그레이션 {#routing-rules-migration}

Sidekiq 라우팅 규칙이 변경된 후 마이그레이션 시 주의를 기울여 작업이 완전히 손실되지 않도록 해야 하며, 특히 많은 작업 큐가 있는 시스템에서는 더욱 그러합니다. 마이그레이션은 [Sidekiq 작업 마이그레이션](sidekiq_job_migration.md)에서 언급된 마이그레이션 단계를 따라 수행할 수 있습니다.

### 확장된 아키텍처의 라우팅 규칙 {#routing-rules-in-a-scaled-architecture}

라우팅 규칙은 애플리케이션 구성의 일부이므로 모든 GitLab 노드(특히 GitLab Rails 및 Sidekiq 노드)에서 동일해야 합니다.

### 상세 예제 {#detailed-example}

이것은 다양한 가능성을 보여주기 위한 종합적인 예제입니다. [Helm 차트 예제도 사용 가능합니다](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/#queues). 이것들은 권장 사항이 아닙니다.

1. `/etc/gitlab/gitlab.rb`을 편집하세요:

   ```ruby
   sidekiq['routing_rules'] = [
     # Route all non-CPU-bound workers that are high urgency to `high-urgency` queue
     ['resource_boundary!=cpu&urgency=high', 'high-urgency'],
     # Route all database, gitaly and global search workers that are throttled to `throttled` queue
     ['feature_category=database,gitaly,global_search&urgency=throttled', 'throttled'],
     # Route all workers having contact with outside world to a `network-intensive` queue
     ['has_external_dependencies=true|feature_category=hooks|tags=network', 'network-intensive'],
     # Wildcard matching, route the rest to `default` queue
     ['*', 'default']
   ]
   ```

   `queue_groups`을 이러한 생성된 큐 이름과 일치하도록 설정할 수 있습니다. 예를 들어:

   ```ruby
   sidekiq['queue_groups'] = [
     # Run two high-urgency processes
     'high-urgency',
     'high-urgency',
     # Run one process for throttled, network-intensive
     'throttled,network-intensive',
     # Run one 'catchall' process on the default and mailers queues
     'default,mailers'
   ]
   ```

1. 파일을 저장하고 GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## 워커 일치 쿼리 {#worker-matching-query}

GitLab은 라우팅 규칙에서 사용하는 특성을 기반으로 워커와 일치시키는 쿼리 구문을 제공합니다. 쿼리는 두 가지 구성 요소를 포함합니다:

- 선택할 수 있는 특성입니다.
- 쿼리를 구성하는 데 사용되는 연산자입니다.

### 사용 가능한 특성 {#available-attributes}

큐 일치 쿼리는 GitLab 개발 문서의 Sidekiq 스타일 가이드에서 설명된 워커 특성을 기반으로 작동합니다. 워커 특성의 부분 집합을 기반으로 쿼리하는 것을 지원합니다:

- `feature_category` - 큐가 속한 GitLab 기능 카테고리입니다. 예를 들어 `merge` 큐는 `source_code_management` 카테고리에 속합니다.
- `has_external_dependencies` - 큐가 외부 서비스에 연결되는지 여부입니다. 예를 들어 모든 임포터는 이것을 `true`으로 설정합니다.
- `urgency` - 이 큐의 작업이 빠르게 실행되는 것이 얼마나 중요한지 입니다. `high`, `low` 또는 `throttled`일 수 있습니다. 예를 들어 `authorized_projects` 큐는 사용자 권한을 새로 고치는 데 사용되며 `high` 긴급성입니다.
- `worker_name` - 워커 이름입니다. 이 특성을 사용하여 특정 워커를 선택합니다. 아래 [작업 클래스 목록](#list-of-available-job-classes)에서 모든 사용 가능한 이름을 찾으세요.
- `name` - 워커 이름에서 생성된 큐 이름입니다. 이 특성을 사용하여 특정 큐를 선택합니다. 이것은 워커 이름에서 생성되기 때문에 다른 라우팅 규칙의 결과에 따라 변경되지 않습니다.
- `resource_boundary` - 큐가 `cpu`, `memory` 또는 `unknown`으로 바인딩되는지 여부입니다. 예를 들어 `ProjectExportWorker`는 메모리로 바인딩되며 내보내기 위해 저장하기 전에 메모리에 데이터를 로드해야 합니다.
- `tags` - 큐에 대한 단기 주석입니다. 이것들은 릴리스마다 자주 변경되며 완전히 제거될 수 있습니다.
- `queue_namespace` - 일부 워커는 작업 네임스페이스로 그룹화되고 `name`는 `<queue_namespace>:` 접두사가 붙습니다. 예를 들어 큐 `name`이 `cronjob:admin_email`인 경우 `queue_namespace`는 `cronjob`입니다. 이 특성을 사용하여 워커 그룹을 선택합니다.

`has_external_dependencies`는 부울 특성입니다. 정확한 문자열 `true`만 참으로 간주되고 나머지는 모두 거짓으로 간주됩니다.

`tags`는 집합입니다. 즉 `=`는 교집합을 확인하고 `!=`는 분리된 집합을 확인합니다. 예를 들어 `tags=a,b`는 태그 `a`, `b` 또는 둘 다 있는 큐를 선택합니다. `tags!=a,b`는 이러한 태그가 없는 큐를 선택합니다.

### 사용 가능한 연산자 {#available-operators}

라우팅 규칙은 다음 연산자를 지원하며 가장 높은 것부터 가장 낮은 우선순위 순서로 나열됩니다:

- `|` - 논리 `OR` 연산자입니다. 예를 들어 `query_a|query_b` (`query_a`와 `query_b`는 여기의 다른 연산자로 만든 쿼리)는 어느 쿼리든 일치하는 큐를 포함합니다.
- `&` - 논리 `AND` 연산자입니다. 예를 들어 `query_a&query_b` (`query_a`와 `query_b`는 여기의 다른 연산자로 만든 쿼리)는 두 쿼리를 모두 일치하는 큐만 포함합니다.
- `!=` - `NOT IN` 연산자입니다. 예를 들어 `feature_category!=issue_tracking`은 `issue_tracking` 기능 카테고리의 모든 큐를 제외합니다.
- `=` - `IN` 연산자입니다. 예를 들어 `resource_boundary=cpu`은 CPU 바인딩된 모든 큐를 포함합니다.
- `,` - 연결 집합 연산자입니다. 예를 들어 `feature_category=continuous_integration,pages`는 `continuous_integration` 카테고리 또는 `pages` 카테고리 중 하나의 모든 큐를 포함합니다. 이 예제는 OR 연산자를 사용하여도 가능하지만 더 간결성을 허용하고 우선순위도 낮습니다.

이 구문의 연산자 우선순위는 고정되어 있습니다. `AND`가 `OR`보다 높은 우선순위를 갖도록 하는 것은 불가능합니다.

이전에 문서화된 표준 큐 그룹 구문과 마찬가지로 전체 큐 그룹으로서 단일 `*`는 모든 큐를 선택합니다.

### Rails 콘솔에서 라우팅 규칙 테스트 {#test-routing-rules-in-the-rails-console}

[Rails 콘솔](../operations/rails_console.md)에서 다음을 실행하여 주어진 쿼리와 일치하는 워커를 확인할 수 있습니다:

```ruby
matcher = Gitlab::SidekiqConfig::WorkerMatcher.new("feature_category=global_search")
Gitlab::SidekiqConfig.workers
  .select { |w| matcher.match?(w.to_yaml) }
  .map(&:klass)
```

쿼리 문자열을 유효한 워커 일치 쿼리로 바꾸어 다양한 라우팅 규칙을 테스트합니다.

[사용 가능한 작업 클래스 목록](#list-of-available-job-classes)을 참고하여 자신에게 맞는 쿼리 매개변수를 찾으세요.

### 사용 가능한 작업 클래스 목록 {#list-of-available-job-classes}

기존 Sidekiq 작업 클래스 및 큐의 목록을 보려면 다음 파일을 확인하세요:

- [모든 GitLab 에디션의 큐](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/workers/all_queues.yml)
- [GitLab Enterprise 에디션 전용 큐](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/all_queues.yml)
