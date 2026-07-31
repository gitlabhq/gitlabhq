---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Elasticsearch 마이그레이션 문제 해결
---

{{< details >}}

- 티어: Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Elasticsearch 마이그레이션을 작업할 때 다음 이슈가 발생할 수 있습니다.

[`elasticsearch.log`](../../../administration/logs/_index.md#elasticsearchlog)에 오류가 포함되어 있고 실패한 마이그레이션을 다시 시도해도 작동하지 않으면 GitLab 지원팀에 문의하세요. 자세한 내용은 [고급 검색 마이그레이션](../../advanced_search/elasticsearch.md#advanced-search-migrations)을 참조하세요.

## 오류: `Elasticsearch::Transport::Transport::Errors::BadRequest` {#error-elasticsearchtransporttransporterrorsbadrequest}

비슷한 예외가 발생하면 올바른 Elasticsearch 버전이 있고 [시스템 요구 사항](../../advanced_search/elasticsearch.md#system-requirements)을 충족하는지 확인하세요. `sudo gitlab-rake gitlab:check` 명령을 사용하여 버전을 자동으로 확인할 수도 있습니다.

## 오류: `Faraday::TimeoutError (execution expired)` {#error-faradaytimeouterror-execution-expired}

프록시를 사용하는 경우 `gitlab_rails['env']` 환경 변수를 [`no_proxy`](https://docs.gitlab.com/omnibus/settings/environment-variables/)(으)로 설정하고 Elasticsearch 호스트의 IP 주소를 지정하세요.

## 단일 노드 Elasticsearch 클러스터 상태가 노란색에서 녹색으로 전환되지 않음 {#single-node-elasticsearch-cluster-status-never-goes-from-yellow-to-green}

단일 노드 Elasticsearch 클러스터의 경우 기능 클러스터 상태는 노란색(녹색이 아님)입니다. 이유는 주 샤드는 할당되지만 Elasticsearch가 복제본을 할당할 수 있는 다른 노드가 없기 때문에 복제본을 할당할 수 없다는 것입니다. [Amazon OpenSearch](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/aes-handling-errors.html#aes-handling-errors-yellow-cluster-status) 서비스를 사용하는 경우에도 해당됩니다.

> [!warning]
> 복제본의 개수를 `0`(으)로 설정하는 것은 권장되지 않습니다(GitLab Elasticsearch 통합 메뉴에서는 허용되지 않음). Elasticsearch 노드를 더 추가할 계획이 있다면(총 1개 이상의 Elasticsearch) 복제본의 개수를 `0`보다 큰 정수 값으로 설정해야 합니다. 그렇지 않으면 중복성이 부족하여 한 노드를 잃으면 인덱스가 손상됩니다.

단일 노드 Elasticsearch 클러스터에 대해 녹색 상태를 유지하려면 위험을 이해하고 다음 쿼리를 실행하여 복제본의 개수를 `0`(으)로 설정하세요. 클러스터는 더 이상 샤드 복제본을 만들려고 시도하지 않습니다.

```shell
curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
     --data '{
       "index" : {
         "number_of_replicas" : 0
       }
     }'
```

## 오류: `health check timeout: no Elasticsearch node available` {#error-health-check-timeout-no-elasticsearch-node-available}

인덱싱 프로세스 중에 Sidekiq에서 `health check timeout: no Elasticsearch node available` 오류가 발생하면:

```plaintext
Gitlab::Elastic::Indexer::Error: time="2020-01-23T09:13:00Z" level=fatal msg="health check timeout: no Elasticsearch node available"
```

Elasticsearch 통합 메뉴의 **"URL"** 필드에서 값의 일부로 `http://` 또는 `https://`를 사용하지 않았을 가능성이 있습니다. 이 필드의 URL 형식을 확인하세요. [Elasticsearch client for Go](https://github.com/olivere/elastic)는 URL의 접두사가 [유효한 것으로 허용](https://github.com/olivere/elastic/commit/a80af35aa41856dc2c986204e2b64eab81ccac3a)되어야 합니다. URL의 형식을 수정한 후 [인덱스 삭제](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks) 및 [인스턴스 콘텐츠 다시 인덱싱](../../advanced_search/elasticsearch.md#enable-advanced-search)을 수행하세요.

## Elasticsearch가 일부 타사 플러그인과 호환되지 않음 {#elasticsearch-does-not-work-with-some-third-party-plugins}

특정 타사 플러그인은 클러스터에서 버그를 일으키거나 통합과 호환되지 않을 수 있습니다.

Elasticsearch 클러스터에 타사 플러그인이 있고 통합이 작동하지 않으면 플러그인을 비활성화해 보세요.

## Elasticsearch 워커가 Sidekiq을 오버로드 {#elasticsearch-workers-overload-sidekiq}

일부 경우 Elasticsearch는 더 이상 GitLab에 연결할 수 없습니다:

- Elasticsearch 암호가 한쪽에서만 업데이트됨(`Unauthorized [401] ... unable to authenticate user` 오류).
- 방화벽 또는 네트워크 이슈로 인해 연결이 손상됨(`Failed to open TCP connection to <ip>:9200` 오류).

이러한 오류는 [`gitlab-rails/elasticsearch.log`](../../../administration/logs/_index.md#elasticsearchlog)에 기록됩니다. 오류를 검색하려면 [`jq`](../../../administration/logs/log_parsing.md)를 사용하세요:

```shell
$ jq --raw-output 'select(.severity == "ERROR") | [.error_class, .error_message] | @tsv' \
    gitlab-rails/elasticsearch.log |
  sort | uniq -c
```

`Elastic` 워커와 [Sidekiq 작업](../../../administration/admin_area.md#background-jobs)은 Elasticsearch가 이전 작업이 실패하면 자주 다시 인덱싱을 시도하기 때문에 훨씬 더 자주 표시될 수 있습니다. [`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats#usage) 또는 `jq`를 사용하여 [Sidekiq 로그](../../../administration/logs/_index.md#sidekiq-logs)의 워커 개수를 셀 수 있습니다:

```shell
$ fast-stats --print-fields=count,score sidekiq/current
WORKER                            COUNT   SCORE
Search::Elastic::IndexBulkCronWorker         234  123456
Search::Elastic::IndexInitialBulkCronWorker  345   12345
Some::OtherWorker                             12     123
...

$ jq '.class' sidekiq/current | sort | uniq -c | sort -nr
 234 "Search::Elastic::IndexInitialBulkCronWorker"
 345 "Search::Elastic::IndexBulkCronWorker"
  12 "Some::OtherWorker"
...
```

이 경우 오버로드된 GitLab 노드의 `free -m`도 예상치 못하게 높은 `buff/cache` 사용량을 표시합니다.

## 오류: `Couldn't load task status` {#error-couldnt-load-task-status}

다시 인덱싱할 때 `Couldn't load task status` 오류가 발생할 수 있습니다. `sliceId must be greater than 0 but was [-1]` 오류도 Elasticsearch 호스트에 나타날 수 있습니다. 해결 방법으로 [처음부터 다시 인덱싱](indexing.md#last-resort-to-recreate-an-index)하거나 GitLab 16.3으로 업그레이드하는 것을 고려하세요.

자세한 내용은 [이슈 422938](https://gitlab.com/gitlab-org/gitlab/-/issues/422938)을 참조하세요.

## 오류: `migration has failed with NoMethodError:undefined method` {#error-migration-has-failed-with-nomethoderrorundefined-method}

GitLab 15.11에서 `BackfillProjectPermissionsInBlobs` 마이그레이션은 `elasticsearch.log`에서 다음 오류 메시지와 함께 실패할 수 있습니다:

```shell
migration has failed with NoMethodError:undefined method `<<' for nil:NilClass, no retries left
```

`BackfillProjectPermissionsInBlobs`이 유일한 실패한 마이그레이션이면 [수정 사항](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118494)을 포함하는 GitLab 16.0의 최신 패치 버전으로 업그레이드할 수 있습니다. 그렇지 않으면 고급 검색의 기능에 영향을 주지 않으므로 오류를 무시할 수 있습니다.

## `ElasticIndexInitialBulkCronWorker` 및 `ElasticIndexBulkCronWorker` 작업이 중복 제거에서 중단됨 {#elasticindexinitialbulkcronworker-and-elasticindexbulkcronworker-jobs-stuck-in-deduplication}

GitLab 16.5 이전 버전에서 `ElasticIndexInitialBulkCronWorker` 및 `ElasticIndexBulkCronWorker` 작업이 중복 제거에서 중단될 수 있습니다. 이 이슈는 새 인덱스를 만든 후에도 고급 검색이 문서를 제대로 인덱싱하지 못하도록 할 수 있습니다. GitLab 16.6에서 `idempotent!`는 인덱싱을 수행하는 대량 cron 워커에 대해 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135817)되었습니다.

Sidekiq 로그에 다음 항목이 있을 수 있습니다:

```shell
{"severity":"INFO","time":"2023-10-31T10:33:06.998Z","retry":0,"queue":"default","version":0,"queue_namespace":"cronjob","args":[],"class":"ElasticIndexInitialBulkCronWorker",
...
"idempotency_key":"resque:gitlab:duplicate:default:<value>","duplicate-of":"91e8673347d4dc84fbad5319","job_size_bytes":2,"pid":12047,"job_status":"deduplicated","message":"ElasticIndexInitialBulkCronWorker JID-5e1af9180d6e8f991fc773c6: deduplicated: until executing","deduplication.type":"until executing"}
```

이 이슈를 해결하려면:

1. [Rails 콘솔 세션](../../../administration/operations/rails_console.md#starting-a-rails-console-session)에서 다음 명령을 실행하세요:

   ```shell
   idempotency_key = "<idempotency_key_from_log_entry>"
   duplicate_key = "resque:gitlab:#{idempotency_key}:cookie:v2"
   Gitlab::Redis::Queues.with { |c| c.del(duplicate_key) }
   ```

1. `<idempotency_key_from_log_entry>`을 로그의 실제 항목으로 바꾸세요.
