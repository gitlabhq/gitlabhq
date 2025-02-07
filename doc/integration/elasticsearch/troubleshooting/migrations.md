---
stage: Foundations
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting Elasticsearch migrations
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

When working with Elasticsearch migrations, you might encounter the following issues.

If [`elasticsearch.log`](../../../administration/logs/_index.md#elasticsearchlog) contains errors
and retrying failed migrations does not work, contact GitLab Support.
For more information, see [advanced search migrations](../../advanced_search/elasticsearch.md#advanced-search-migrations).

## Error: `Elasticsearch::Transport::Transport::Errors::BadRequest`

If you have a similar exception, ensure you have the correct Elasticsearch version and you meet the [system requirements](../../advanced_search/elasticsearch.md#system-requirements).
You can also check the version automatically by using the `sudo gitlab-rake gitlab:check` command.

## Error: `Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge`

```plaintext
[413] {"Message":"Request size exceeded 10485760 bytes"}
```

This exception is seen when your Elasticsearch cluster is configured to reject requests above a certain size (10 MiB in this case). This corresponds to the `http.max_content_length` setting in `elasticsearch.yml`. Increase it to a larger size and restart your Elasticsearch cluster.

AWS has [network limits](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/limits.html#network-limits) on the maximum size of HTTP request payloads based on the size of the underlying instance. Set the maximum bulk request size to a value lower than 10 MiB.

## Error: `Faraday::TimeoutError (execution expired)`

When you use a proxy, set a custom `gitlab_rails['env']` environment variable
named [`no_proxy`](https://docs.gitlab.com/omnibus/settings/environment-variables.html)
with the IP address of your Elasticsearch host.

## Single-node Elasticsearch cluster status never goes from yellow to green

For a single-node Elasticsearch cluster, the functional cluster health status is yellow (never green). The reason is that the primary shard is allocated, but replicas cannot be as no other node to which Elasticsearch can assign a replica exists. This also applies if you are using the [Amazon OpenSearch](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/aes-handling-errors.html#aes-handling-errors-yellow-cluster-status) service.

WARNING:
Setting the number of replicas to `0` is discouraged (this is not allowed in the GitLab Elasticsearch Integration menu). If you are planning to add more Elasticsearch nodes (for a total of more than 1 Elasticsearch) the number of replicas needs to be set to an integer value larger than `0`. Failure to do so results in lack of redundancy (losing one node corrupts the index).

If you want to have a green status for your single-node Elasticsearch cluster, understand the risks and run the following query to set the number of replicas to `0`. The cluster no longer tries to create any shard replicas.

```shell
curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
     --data '{
       "index" : {
         "number_of_replicas" : 0
       }
     }'
```

## Error: `health check timeout: no Elasticsearch node available`

If you're getting a `health check timeout: no Elasticsearch node available` error in Sidekiq during the indexing process:

```plaintext
Gitlab::Elastic::Indexer::Error: time="2020-01-23T09:13:00Z" level=fatal msg="health check timeout: no Elasticsearch node available"
```

You probably have not used either `http://` or `https://` as part of your value in the **"URL"** field of the Elasticsearch Integration Menu. Make sure you are using either `http://` or `https://` in this field as the [Elasticsearch client for Go](https://github.com/olivere/elastic) that we are using [needs the prefix for the URL to be accepted as valid](https://github.com/olivere/elastic/commit/a80af35aa41856dc2c986204e2b64eab81ccac3a).
After you have corrected the formatting of the URL, [delete the index](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks) and [reindex the content of your instance](../../advanced_search/elasticsearch.md#enable-advanced-search).

## Elasticsearch does not work with some third-party plugins

Certain third-party plugins might introduce bugs in your cluster or
be incompatible with the integration.

If your Elasticsearch cluster has third-party plugins and the integration is not working,
try to disable the plugins.

## Elasticsearch workers overload Sidekiq

In some cases, Elasticsearch cannot connect to GitLab anymore because:

- The Elasticsearch password has been updated on one side only (`Unauthorized [401] ... unable to authenticate user` errors).
- A firewall or network issue impairs connectivity (`Failed to open TCP connection to <ip>:9200` errors).

These errors are logged in [`gitlab-rails/elasticsearch.log`](../../../administration/logs/_index.md#elasticsearchlog). To retrieve the errors, use [`jq`](../../../administration/logs/log_parsing.md):

```shell
$ jq --raw-output 'select(.severity == "ERROR") | [.error_class, .error_message] | @tsv' \
    gitlab-rails/elasticsearch.log |
  sort | uniq -c
```

`Elastic` workers and [Sidekiq jobs](../../../administration/admin_area.md#background-jobs) could also appear much more often
because Elasticsearch frequently attempts to reindex if a previous job fails.
You can use [`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats#usage)
or `jq` to count workers in the [Sidekiq logs](../../../administration/logs/_index.md#sidekiq-logs):

```shell
$ fast-stats --print-fields=count,score sidekiq/current
WORKER                            COUNT   SCORE
ElasticIndexBulkCronWorker          234  123456
ElasticIndexInitialBulkCronWorker   345   12345
Some::OtherWorker                    12     123
...

$ jq '.class' sidekiq/current | sort | uniq -c | sort -nr
 234 "ElasticIndexInitialBulkCronWorker"
 345 "ElasticIndexBulkCronWorker"
  12 "Some::OtherWorker"
...
```

In this case, `free -m` on the overloaded GitLab node would also show
unexpectedly high `buff/cache` usage.

## Error: `Couldn't load task status`

When you reindex, you might get a `Couldn't load task status` error. A `sliceId must be greater than 0 but was [-1]` error might also appear on the Elasticsearch host. As a workaround, consider [reindexing from scratch](indexing.md#last-resort-to-recreate-an-index) or upgrading to GitLab 16.3.

For more information, see [issue 422938](https://gitlab.com/gitlab-org/gitlab/-/issues/422938).

## Error: `migration has failed with NoMethodError:undefined method`

In GitLab 15.11, the `BackfillProjectPermissionsInBlobs` migration might fail with the following error message in `elasticsearch.log`:

```shell
migration has failed with NoMethodError:undefined method `<<' for nil:NilClass, no retries left
```

If `BackfillProjectPermissionsInBlobs` is the only failed migration, you can upgrade to the latest patch version of GitLab 16.0, which includes [the fix](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118494). Otherwise, you can ignore the error as it does not affect the functionality of advanced search.

## `ElasticIndexInitialBulkCronWorker` and `ElasticIndexBulkCronWorker` jobs stuck in deduplication

In GitLab 16.5 and earlier, the `ElasticIndexInitialBulkCronWorker` and `ElasticIndexBulkCronWorker` jobs might get stuck in deduplication. This issue might prevent advanced search from properly indexing documents even after creating a new index. In GitLab 16.6, `idempotent!` was [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135817) for bulk cron workers that perform indexing.

The Sidekiq log might have the following entries:

```shell
{"severity":"INFO","time":"2023-10-31T10:33:06.998Z","retry":0,"queue":"default","version":0,"queue_namespace":"cronjob","args":[],"class":"ElasticIndexInitialBulkCronWorker",
...
"idempotency_key":"resque:gitlab:duplicate:default:<value>","duplicate-of":"91e8673347d4dc84fbad5319","job_size_bytes":2,"pid":12047,"job_status":"deduplicated","message":"ElasticIndexInitialBulkCronWorker JID-5e1af9180d6e8f991fc773c6: deduplicated: until executing","deduplication.type":"until executing"}
```

To resolve this issue:

1. In a [Rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session), run this command:

   ```shell
   idempotency_key = "<idempotency_key_from_log_entry>"
   duplicate_key = "resque:gitlab:#{idempotency_key}:cookie:v2"
   Gitlab::Redis::Queues.with { |c| c.del(duplicate_key) }
   ```

1. Replace `<idempotency_key_from_log_entry>` with the actual entry in your log.
