---
stage: Analytics
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Troubleshooting Elasticsearch migrations
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

When working with Elasticsearch migrations, you might encounter the following issues.

If [`elasticsearch.log`](../../../administration/logs/_index.md#elasticsearchlog) contains errors
and retrying failed migrations does not work, contact GitLab Support.
For more information, see [advanced search migrations](../../advanced_search/elasticsearch.md#advanced-search-migrations).

## Error: `Elasticsearch::Transport::Transport::Errors::BadRequest`

If you have a similar exception, ensure you have the correct Elasticsearch version and you meet the [system requirements](../../advanced_search/elasticsearch.md#system-requirements).
You can also check the version automatically by using the `sudo gitlab-rake gitlab:check` command.

## Error: `Faraday::TimeoutError (execution expired)`

When you use a proxy, set a custom `gitlab_rails['env']` environment variable
named [`no_proxy`](https://docs.gitlab.com/omnibus/settings/environment-variables/)
with the IP address of your Elasticsearch host.

## Single-node Elasticsearch cluster status never goes from yellow to green

For a single-node Elasticsearch cluster, the functional cluster health status is yellow (never green). The reason is that the primary shard is allocated, but replicas cannot be as no other node to which Elasticsearch can assign a replica exists. This also applies if you are using the [Amazon OpenSearch](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/aes-handling-errors.html#aes-handling-errors-yellow-cluster-status) service.

> [!warning]
> Setting the number of replicas to `0` is discouraged (this is not allowed in the GitLab Elasticsearch Integration menu). If you are planning to add more Elasticsearch nodes (for a total of more than 1 Elasticsearch node) the number of replicas needs to be set to an integer value larger than `0`. Failure to do so results in lack of redundancy (losing one node corrupts the index).

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

You probably have not used either `http://` or `https://` as part of your value in the **"URL"** field of the Elasticsearch Integration Menu. Confirm the URL format in this field as the [Elasticsearch client for Go](https://github.com/olivere/elastic) requires the prefix for the URL to be [accepted as valid](https://github.com/olivere/elastic/commit/a80af35aa41856dc2c986204e2b64eab81ccac3a).
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

In this case, `free -m` on the overloaded GitLab node would also show
unexpectedly high `buff/cache` usage.
