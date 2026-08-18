---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Elasticsearch 인덱싱 및 검색 문제 해결
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Elasticsearch 인덱싱 또는 검색 작업 중 다음과 같은 이슈가 발생할 수 있습니다.

## 빈 인덱스 생성 {#create-an-empty-index}

인덱싱 이슈의 경우 먼저 빈 인덱스를 생성해 보세요. Elasticsearch 인스턴스를 확인하여 `gitlab-production` 인덱스가 존재하는지 확인하세요. 존재하는 경우 Elasticsearch 인스턴스에서 인덱스를 수동으로 삭제한 후 [`recreate_index`](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks) Rake 작업에서 다시 생성해 보세요.

이슈가 계속 발생하면 Elasticsearch 인스턴스에서 수동으로 인덱스를 생성해 보세요. 다음 조건에 해당하는 경우:

- 인덱스를 생성할 수 없는 경우 Elasticsearch 관리자에게 문의하세요.
- 인덱스를 생성할 수 있는 경우 GitLab 지원팀에 문의하세요.

## 인덱싱된 프로젝트의 상태 확인 {#check-the-status-of-indexed-projects}

프로젝트 인덱싱 중 오류를 확인할 수 있습니다. 오류가 발생할 수 있는 곳:

- GitLab 인스턴스: 직접 해결할 수 없는 경우 GitLab 지원팀에 문의하여 도움을 받으세요.
- Elasticsearch 인스턴스: [오류가 나열되지 않은 경우](_index.md) Elasticsearch 관리자에게 문의하세요.

인덱싱에서 오류가 반환되지 않으면 다음 Rake 작업으로 인덱싱된 프로젝트의 상태를 확인하세요:

- [`sudo gitlab-rake gitlab:elastic:index_projects_status`](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks) 전체 상태의 경우
- [`sudo gitlab-rake gitlab:elastic:projects_not_indexed`](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks) 인덱싱되지 않은 특정 프로젝트의 경우

인덱싱 상태가:

- 완료된 경우 GitLab 지원팀에 문의하세요.
- 완료되지 않은 경우 `sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=<project ID> ID_TO=<project ID>`을 실행하여 해당 프로젝트를 다시 인덱싱해 보세요.

프로젝트를 다시 인덱싱할 때 다음에서 오류가 나타나면:

- GitLab 인스턴스: GitLab 지원팀에 문의하세요.
- Elasticsearch 인스턴스 또는 오류가 없음: Elasticsearch 관리자에게 문의하여 인스턴스를 확인하세요.

## GitLab 업데이트 후 검색 결과 없음 {#no-search-results-after-updating-gitlab}

저희는 인덱싱 전략을 지속적으로 업데이트하고 최신 버전의 Elasticsearch를 지원하기 위해 노력합니다. 인덱싱 변경이 이루어지면 GitLab 업데이트 후 [다시 인덱싱](../../advanced_search/elasticsearch.md#zero-downtime-reindexing)해야 할 수 있습니다.

## 모든 저장소 인덱싱 후 검색 결과 없음 {#no-search-results-after-indexing-all-repositories}

> [!note]
> [네임스페이스 부분집합](../../advanced_search/elasticsearch.md#limit-the-amount-of-namespace-and-project-data-to-index)만 인덱싱하는 시나리오에는 이 지침을 사용하지 마세요.

[모든 데이터베이스 데이터를 인덱싱했는지](../../advanced_search/elasticsearch.md#enable-advanced-search) 확인하세요.

UI 검색에 결과(hits)가 없는 경우 Rails 콘솔(`sudo gitlab-rails console`)을 통해 동일한 결과를 보는지 확인하세요:

```ruby
u = User.find_by_username('your-username')
s = SearchService.new(u, {:search => 'search_term', :scope => 'blobs'})
pp s.search_objects.to_a
```

그 외에 [Elasticsearch 검색 API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-search.html)를 통해 데이터가 Elasticsearch 측에 나타나는지 확인하세요:

```shell
curl --request GET <elasticsearch_server_ip>:9200/gitlab-production/_search?q=<search_term>
```

더 [복잡한 Elasticsearch API 호출](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-filter-context.html)도 가능합니다.

결과가:

- 동기화되는 경우 [지원되는 구문](../../../user/search/advanced_search.md#syntax)을 사용하고 있는지 확인하세요. 고급 검색은 [정확한 부분 문자열 일치](https://gitlab.com/gitlab-org/gitlab/-/issues/325234)를 지원하지 않습니다.
- 일치하지 않는 경우 프로젝트에서 생성된 문서에 문제가 있음을 나타냅니다. [해당 프로젝트를 다시 인덱싱](../../advanced_search/elasticsearch.md#indexing-a-range-of-projects-or-a-specific-project)하는 것이 좋습니다.

특정 유형의 데이터 검색에 대한 자세한 내용은 [Elasticsearch 인덱스 범위](../../advanced_search/elasticsearch.md#advanced-search-index-scopes)를 참조하세요.

## 낮은 동시성으로 고급 검색을 활성화한 후 검색 결과 없음 {#no-search-results-after-enabling-advanced-search-with-low-concurrency}

고급 검색을 활성화한 후 문서가 인덱싱되지 않고 코드를 검색할 수 없음을 알 수 있습니다. Sidekiq 로그에서 다음과 유사한 메시지가 표시될 수 있습니다:

```json
"job_status":"concurrency_limit","message":"Search::Elastic::CommitIndexerWorker JID-352e0b9ee88af9f455c69b81: concurrency_limit: paused"
```

이 이슈를 해결하려면:

1. Rake 작업 `gitlab-rake gitlab:elastic:info`을 사용하여 **Indexing queues**의 상태를 확인하세요.
1. **Concurrency limit code queue**가 0이 아닌 경우 **코드 인덱싱 동시성** 값을 확인하세요. 너무 낮은 값은 인덱싱이 진행되는 것을 방지할 수 있습니다. 이 값을 증가시키고 Rake 작업으로 진행 상황을 확인해 보세요.

## Elasticsearch 서버 전환 후 검색 결과 없음 {#no-search-results-after-switching-elasticsearch-servers}

데이터베이스, 저장소 및 위키를 다시 인덱싱하려면 [인스턴스를 인덱싱](../../advanced_search/elasticsearch.md#index-the-instance)하세요.

## 인덱싱이 `error: elastic: Error 429 (Too Many Requests)` 오류로 실패 {#indexing-fails-with-error-elastic-error-429-too-many-requests}

`Search::Elastic::CommitIndexerWorker` Sidekiq 처리기가 인덱싱 중 이 오류로 실패하면 일반적으로 Elasticsearch가 인덱싱 요청의 동시성을 따라잡을 수 없음을 의미합니다. 해결하려면 다음 설정을 변경하세요:

- 인덱싱 처리량을 줄이려면 `Bulk request concurrency`을 줄일 수 있습니다([고급 검색 설정](../../advanced_search/elasticsearch.md#advanced-search-configuration) 참조). 기본값은 `10`이지만 동시 인덱싱 작업의 수를 줄이기 위해 1로 낮출 수 있습니다.
- `Bulk request concurrency`을 변경해도 도움이 되지 않으면 [라우팅 규칙](../../../administration/sidekiq/processing_specific_job_classes.md#routing-rules) 옵션을 사용하여 [인덱싱 작업을 특정 Sidekiq 노드로만 제한](../../advanced_search/elasticsearch.md#index-large-instances-with-dedicated-sidekiq-nodes-or-processes)할 수 있으며, 이렇게 하면 인덱싱 요청의 수가 줄어듭니다.

## 오류: `Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge` {#error-elasticsearchtransporttransporterrorsrequestentitytoolarge}

```plaintext
[413] {"Message":"Request size exceeded 10485760 bytes"}
```

이 예외는 Elasticsearch 클러스터가 특정 크기 이상의 요청을 거부하도록 구성된 경우 발생합니다(이 경우 10MiB). 이는 `elasticsearch.yml`에서 `http.max_content_length` 설정에 해당합니다. 더 큰 크기로 증가하고 Elasticsearch 클러스터를 다시 시작하세요.

AWS에는 기본 인스턴스의 크기에 따라 HTTP 요청 페이로드의 최대 크기에 대한 [네트워크 제한](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/limits.html#network-limits)이 있습니다. 최대 대량 요청 크기를 10MiB보다 낮은 값으로 설정하세요.

## 인덱싱이 `rejected execution of coordinating operation`로 인해 매우 느리거나 실패 {#indexing-is-very-slow-or-fails-with-rejected-execution-of-coordinating-operation}

Elasticsearch 노드에서 거부된 대량 요청은 로드 및 사용 가능한 메모리 부족으로 인한 것일 가능성이 높습니다. Elasticsearch 클러스터가 [시스템 요구 사항](../../advanced_search/elasticsearch.md#system-requirements)을 충족하고 대량 작업을 수행할 수 있는 충분한 리소스가 있는지 확인하세요. ["429(너무 많은 요청)"](#indexing-fails-with-error-elastic-error-429-too-many-requests) 오류도 참조하세요.

## 인덱싱이 `strict_dynamic_mapping_exception` 오류로 실패 {#indexing-fails-with-strict_dynamic_mapping_exception}

모든 [고급 검색 마이그레이션이 주요 업그레이드 전에 완료되지 않으면](../../advanced_search/elasticsearch.md#all-migrations-must-be-finished-before-doing-a-major-upgrade) 인덱싱이 실패할 수 있습니다. 큰 Sidekiq 백로그가 이 오류와 함께 발생할 수 있습니다. 인덱싱 실패를 해결하려면 데이터베이스, 저장소 및 위키를 다시 인덱싱해야 합니다.

1. Sidekiq이 따라잡을 수 있도록 인덱싱을 일시 중지하세요:

   ```shell
   sudo gitlab-rake gitlab:elastic:pause_indexing
   ```

1. [처음부터 인덱스 다시 생성](#last-resort-to-recreate-an-index)하세요.
1. 인덱싱 재개:

   ```shell
   sudo gitlab-rake gitlab:elastic:resume_indexing
   ```

## 인덱싱이 `elasticsearch_pause_indexing setting is enabled`로 인해 계속 일시 중지됨 {#indexing-keeps-pausing-with-elasticsearch_pause_indexing-setting-is-enabled}

검색을 실행할 때 새 데이터가 감지되지 않는 것을 알 수 있습니다.

이 오류는 새 데이터가 제대로 인덱싱되지 않을 때 발생합니다.

이 오류를 해결하려면 [데이터를 다시 인덱싱](../../advanced_search/elasticsearch.md#zero-downtime-reindexing)하세요.

그러나 다시 인덱싱할 때 인덱싱 프로세스가 계속 일시 중지되는 오류가 발생할 수 있으며 Elasticsearch 로그에는 다음이 표시됩니다:

```shell
"message":"elasticsearch_pause_indexing setting is enabled. Job was added to the waiting queue"
```

다시 인덱싱이 이 이슈를 해결하지 못했고 인덱싱 프로세스를 수동으로 일시 중지하지 않은 경우 이 오류는 두 개의 GitLab 인스턴스가 하나의 Elasticsearch 클러스터를 공유하기 때문에 발생할 수 있습니다.

이 오류를 해결하려면 GitLab 인스턴스 중 하나를 Elasticsearch 클러스터 사용에서 연결 해제하세요.

자세한 내용은 [이슈 3421](https://gitlab.com/gitlab-org/gitlab/-/issues/3421)을 참조하세요.

## 검색이 `too_many_clauses: maxClauseCount is set to 1024`로 인해 실패 {#search-fails-with-too_many_clauses-maxclausecount-is-set-to-1024}

이 오류는 쿼리에 `indices.query.bool.max_clause_count` 설정에 정의된 것보다 많은 절이 있을 때 발생합니다:

- [Elasticsearch 7.17 이전](https://www.elastic.co/guide/en/elasticsearch/reference/7.17/search-settings.html)에서 기본값은 `1024`입니다.
- [Elasticsearch 8.0](https://www.elastic.co/guide/en/elasticsearch/reference/8.0/search-settings.html)에서 기본값은 `4096`입니다.
- [Elasticsearch 8.1 이상](https://www.elastic.co/guide/en/elasticsearch/reference/8.1/search-settings.html)에서는 설정이 더 이상 사용되지 않으며 값은 동적으로 결정됩니다.

이 이슈를 해결하려면 값을 증가하거나 Elasticsearch 8.1 이상으로 업그레이드하세요. 값을 증가하면 성능 저하가 발생할 수 있습니다.

## 여러 페이지에서 검색 결과에 중복 포함 {#search-results-contain-duplicates-across-multiple-pages}

고급 검색을 사용하면 여러 페이지에 걸친 검색 결과에 중복이 포함될 수 있습니다. 중복이 나타나면 일치하는 일부 결과가 반환되지 않습니다.

GitLab은 Elasticsearch의 고유한 일치 결과 수에 따라 결과를 페이지 매기합니다. 그러나 Elasticsearch가 결과를 정렬하는 방식으로 인해 동일한 결과가 여러 페이지에 나타날 수 있습니다. 이 이슈는 관련성별로 결과를 정렬할 때 더 자주 발생합니다.

해결 방법으로 다음을 고려하세요:

- 결과를 좁히기 위해 더 구체적인 검색 쿼리를 사용합니다.
- 가능한 경우 다른 정렬 옵션을 사용합니다.

자세한 내용은 [이슈 416286](https://gitlab.com/gitlab-org/gitlab/-/work_items/416286)을 참조하세요.

## 오류: `disk usage exceeded flood-stage watermark, index has read-only-allow-delete block` {#error-disk-usage-exceeded-flood-stage-watermark-index-has-read-only-allow-delete-block}

이 오류는 Elasticsearch 클러스터에 디스크 공간이 심각하게 부족한 노드가 하나 이상 있을 때 발생합니다. 기본 워터마크 임계값인 95%를 초과하는 클러스터는 모든 추가 쓰기 작업을 방지하는 읽기 전용 블록을 적용합니다. 이 블록으로 인해 새 인덱스 작업이 실패하고 검색 결과가 최신이 아닐 수 있습니다.

다음 Rake 작업을 사용하여 클러스터가 읽기 전용 모드인지 확인할 수 있습니다:

```shell
sudo gitlab-rake gitlab:elastic:info
```

`blocks.write` 또는 `blocks.read_only_allow_delete`가 `true`임을 나타내는 출력을 찾으세요.

Elasticsearch 클러스터의 디스크 사용량을 확인하려면 다음 명령을 실행하세요:

```shell
curl --request GET '<your_ES_cluster>:9200/_cat/allocation?v&pretty'
```

이 이슈를 해결하려면 전체 노드의 디스크 볼륨을 증가하세요. 다음 Rake 작업으로 클러스터 크기를 추정할 수 있습니다:

```shell
sudo gitlab-rake gitlab:elastic:estimate_cluster_size
```

## 인덱스를 다시 생성하기 위한 최후의 수단 {#last-resort-to-recreate-an-index}

어떤 이유로 데이터가 인덱싱되지 않았고 큐에도 없거나 인덱스가 마이그레이션을 진행할 수 없는 상태에 있을 수 있는 경우가 있습니다. 항상 [로그를 보면서](access.md#view-logs) 문제의 근본 원인을 해결하려고 시도하는 것이 좋습니다.

최후의 수단으로 처음부터 인덱스를 다시 생성할 수 있습니다. 작은 GitLab 설치의 경우 인덱스를 다시 생성하면 일부 이슈를 빠르게 해결할 수 있습니다. 그러나 대규모 GitLab 설치의 경우 이 방법은 매우 오랜 시간이 걸릴 수 있습니다. 인덱싱이 완료될 때까지 인덱스에 올바른 검색 결과가 표시되지 않습니다. 인덱싱이 실행되는 동안 **고급 검색으로 검색** 확인란을 선택 해제하고 싶을 수 있습니다.

이전 주의 사항을 읽었고 계속 진행하려면 다음 Rake 작업을 실행하여 처음부터 전체 인덱스를 다시 생성해야 합니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
# WARNING: DO NOT RUN THIS UNTIL YOU READ THE DESCRIPTION ABOVE
sudo gitlab-rake gitlab:elastic:index
```

{{< /tab >}}

{{< tab title="Self-compiled(source)" >}}

```shell
# WARNING: DO NOT RUN THIS UNTIL YOU READ THE DESCRIPTION ABOVE
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:elastic:index
```

{{< /tab >}}

{{< /tabs >}}

## 데드 큐 {#dead-queue}

항목은 한 번 재시도한 후 실패하면 데드 큐에 들어갑니다. 데드 큐 항목은 수동으로 조사해야 하며 자동으로 다시 시도되지 않습니다.

### 상태 확인 {#check-the-status}

데드 큐의 크기와 세부 정보를 확인하려면:

1. Rails 콘솔을 시작하세요:

   ```shell
   sudo gitlab-rails console
   ```

1. 실패한 항목의 수를 확인하세요:

   ```ruby
   Search::Elastic::DeadQueue.queue_size
   ```

1. 실패한 항목의 세부 정보를 검사하세요:

   ```ruby
   Search::Elastic::DeadQueue.queued_items
   ```

   이 명령은 각 키가 샤드 번호이고 각 값이 `[spec, score]` 쌍의 배열인 해시를 반환합니다. spec은 실패한 항목에 대한 정보를 포함합니다.

### 항목 재시도 {#retry-items}

다시 시도할 항목을 큐에 넣습니다. 이 항목들이 다시 실패하면 데드 큐로 다시 이동합니다.

데드 큐의 항목을 다시 시도하려면:

1. Rails 콘솔을 시작하세요:

   ```shell
   sudo gitlab-rails console
   ```

1. 데드 큐에서 항목을 재시도 큐로 이동하세요:

   ```ruby
   specs = Search::Elastic::DeadQueue.queued_items.flat_map { |_, items| items.map { |spec, _| spec } }

   Search::Elastic::DeadQueue.clear_tracking!
   Search::Elastic::RetryQueue.track!(*specs)
   ```

1. 선택 사항. [인덱싱 상태 확인](../../advanced_search/elasticsearch.md#check-indexing-status)하세요.

데드 큐의 항목을 다시 시도하지 않고 삭제하려면 다음 명령을 실행하세요:

```ruby
Search::Elastic::DeadQueue.clear_tracking!
```

### GitLab 지원팀에 문의 {#contact-gitlab-support}

데드 큐 항목에 대한 도움이 필요한 경우 GitLab 지원팀과 다음 정보를 공유하세요:

- `Search::Elastic::DeadQueue.queue_size`의 출력
- Elasticsearch 및 GitLab 버전
- 인덱싱 실패가 시작된 시기
- 관련 애플리케이션 로그 또는 오류 메시지

## Elasticsearch 성능 개선 {#improve-elasticsearch-performance}

성능을 개선하려면 다음을 확인하세요:

- Elasticsearch 서버 **은 아님** GitLab과 동일한 노드에서 실행되지 않습니다.
- Elasticsearch 서버에 충분한 RAM 및 CPU 코어가 있습니다.
- 샤딩이 **다음과 같음**입니다.

여기서 더 자세히 설명하면 Elasticsearch가 GitLab과 동일한 서버에서 실행 중이면 리소스 경합이 **very** 발생할 가능성이 높습니다. 이상적으로는 충분한 리소스가 필요한 Elasticsearch가 자체 서버에서 실행되어야 합니다(Logstash 및 Kibana와 함께 사용될 수도 있음).

Elasticsearch와 관련하여 RAM은 핵심 리소스입니다. Elasticsearch는 다음을 권장합니다:

- 비프로덕션 인스턴스의 경우 **At least** 8GB RAM.
- 프로덕션 인스턴스의 경우 **At least** 16GB RAM.
- 이상적으로는 64GB RAM.

CPU의 경우 Elasticsearch는 최소 2개의 CPU 코어를 권장하지만 Elasticsearch는 일반적인 설정이 최대 8개 코어를 사용한다고 명시합니다. 서버 사양에 대한 자세한 내용은 [Elasticsearch 하드웨어 가이드](https://www.elastic.co/guide/en/elasticsearch/guide/current/hardware.html)를 확인하세요.

명백한 것 외에도 샤딩이 작용합니다. 샤딩은 Elasticsearch의 핵심 부분입니다. 대량의 데이터를 다룰 때 유용한 인덱스의 수평 확장을 가능하게 합니다.

GitLab이 인덱싱하는 방식으로 인해 **huge** 양의 문서가 인덱싱됩니다. 샤딩을 사용하면 각 샤드가 Lucene 인덱스이기 때문에 Elasticsearch가 데이터를 찾을 수 있는 능력을 가속화할 수 있습니다.

샤딩을 사용하지 않으면 프로덕션 환경에서 Elasticsearch를 사용하기 시작할 때 이슈가 발생할 가능성이 높습니다.

단일 샤드만 있는 인덱스는 **no scale factor** 일정한 빈도로 호출될 때 이슈가 발생할 가능성이 높습니다. [용량 계획에 대한 Elasticsearch 문서](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/capacity-planning.html)를 참조하세요.

샤딩이 사용 중인지 확인하는 가장 쉬운 방법은 [Elasticsearch 상태 API](https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-health.html)의 출력을 확인하는 것입니다:

- 빨간색은 클러스터가 다운되었음을 의미합니다.
- 노란색은 샤딩/복제 없이 가동 중임을 의미합니다.
- 녹색은 정상(가동, 샤딩, 복제)을 의미합니다.

프로덕션 사용의 경우 항상 녹색이어야 합니다.

이 단계를 넘어서면 병합 및 캐싱과 같이 확인해야 할 더 복잡한 항목들을 접하게 됩니다. 이러한 항목은 복잡할 수 있으며 학습에 시간이 걸리므로, 더 자세히 파고들어야 하는 경우 Elasticsearch 전문가와 에스컬레이션/협력하는 것이 최선입니다.

GitLab 지원팀에 문의하세요. 그러나 이것은 숙련된 Elasticsearch 관리자가 더 많은 경험을 가지고 있을 가능성이 높습니다.

## 느린 초기 인덱싱 {#slow-initial-indexing}

GitLab 인스턴스가 보유한 데이터가 많을수록 인덱싱에 걸리는 시간이 깁니다. Rake 작업 `sudo gitlab-rake gitlab:elastic:estimate_cluster_size`으로 클러스터 크기를 추정할 수 있습니다.

### 코드 문서용 {#for-code-documents}

코드, 커밋 및 위키를 효율적으로 인덱싱하기에 충분한 Sidekiq 노드 및 프로세스가 있는지 확인하세요. 초기 인덱싱이 느린 경우 [전용 Sidekiq 노드 또는 프로세스](../../advanced_search/elasticsearch.md#index-large-instances-with-dedicated-sidekiq-nodes-or-processes)를 고려하세요.

### 비코드 문서용 {#for-non-code-documents}

초기 인덱싱이 느리지만 Sidekiq에 충분한 노드 및 프로세스가 있는 경우 GitLab의 고급 검색 작업자 설정을 조정할 수 있습니다. **인덱싱 처리기 대기열 재조정**의 경우 기본값은 `false`입니다. **비코드 인덱싱을 위한 샤드 수**의 경우 기본값은 `2`입니다. 이 설정은 인덱싱을 분당 2000개의 문서로 제한합니다.

전제 조건:

- 관리자 액세스 권한이 있어야 합니다.

작업자 설정을 조정하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **검색**을 선택하세요.
1. **고급 검색**을 확장하세요.
1. **인덱싱 처리기 대기열 재조정** 확인란을 선택하세요.
1. **비코드 인덱싱을 위한 샤드 수** 텍스트 상자에서 `2`보다 높은 값을 입력하세요.
1. **변경 사항 저장**을 선택합니다.
