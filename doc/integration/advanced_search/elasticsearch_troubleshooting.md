---
stage: Foundations
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Troubleshooting Elasticsearch

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

When working with Elasticsearch, you might encounter the following issues.

## Issues with migrations

Ensure you've read about [Elasticsearch Migrations](../advanced_search/elasticsearch.md#advanced-search-migrations).

If there is a halted migration and your [`elasticsearch.log`](../../administration/logs/index.md#elasticsearchlog) file contain errors, this could potentially be a bug/issue. Escalate to GitLab support if retrying migrations does not succeed.

## Error: `Can't specify parent if no parent field has been configured`

If you enabled Elasticsearch before GitLab 8.12 and have not rebuilt indices, you get
exceptions in lots of different cases:

```plaintext
Elasticsearch::Transport::Transport::Errors::BadRequest([400] {
    "error": {
        "root_cause": [{
            "type": "illegal_argument_exception",
            "reason": "Can't specify parent if no parent field has been configured"
        }],
        "type": "illegal_argument_exception",
        "reason": "Can't specify parent if no parent field has been configured"
    },
    "status": 400
}):
```

This is because we changed the index mapping in GitLab 8.12 and the old indices should be removed and built from scratch again,
see details in the [update guide](../../update/upgrading_from_source.md).

## Error: `Elasticsearch::Transport::Transport::Errors::BadRequest`

If you have this exception (just like in the case above but the actual message is different), check that you have the correct Elasticsearch version and you met the other [requirements](elasticsearch.md#system-requirements).
There is also an easy way to check it automatically with `sudo gitlab-rake gitlab:check` command.

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

## My single node Elasticsearch cluster status never goes from `yellow` to `green`

**For a single node Elasticsearch cluster the functional cluster health status is yellow** (never green) because the primary shard is allocated but replicas cannot be as there is no other node to which Elasticsearch can assign a replica. This also applies if you are using the [Amazon OpenSearch](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/aes-handling-errors.html#aes-handling-errors-yellow-cluster-status) service.

WARNING:
Setting the number of replicas to `0` is discouraged (this is not allowed in the GitLab Elasticsearch Integration menu). If you are planning to add more Elasticsearch nodes (for a total of more than 1 Elasticsearch) the number of replicas needs to be set to an integer value larger than `0`. Failure to do so results in lack of redundancy (losing one node corrupts the index).

If you have a **hard requirement to have a green status for your single node Elasticsearch cluster**, make sure you understand the risks outlined in the previous paragraph and then run the following query to set the number of replicas to `0`(the cluster no longer tries to create any shard replicas):

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
After you have corrected the formatting of the URL, delete the index (via the [dedicated Rake task](elasticsearch.md#gitlab-advanced-search-rake-tasks)) and [reindex the content of your instance](elasticsearch.md#enable-advanced-search).

## My Elasticsearch cluster has a plugin and the integration is not working

Certain 3rd party plugins may introduce bugs in your cluster or for whatever
reason may be incompatible with our integration. You should try disabling
plugins so you can rule out the possibility that the plugin is causing the
problem.

## Elasticsearch `code_analyzer` doesn't account for all code cases

The `code_analyzer` pattern and filter configuration is being evaluated for improvement. We have fixed [most edge cases](https://gitlab.com/groups/gitlab-org/-/epics/3621#note_363429094) that were not returning expected search results due to our pattern and filter configuration.

Improvements to the `code_analyzer` pattern and filters are being discussed in [epic 3621](https://gitlab.com/groups/gitlab-org/-/epics/3621).

## Some binary files may not be searchable by name

In GitLab 13.9, a change was made where [binary filenames are being indexed](https://gitlab.com/gitlab-org/gitlab/-/issues/301083). However, without indexing all projects' data from scratch, only binary files that are added or updated after the GitLab 13.9 release are searchable.

## How does advanced search handle private projects?

Advanced search stores all the projects in the same Elasticsearch indices,
however, searches only surface results that can be viewed by the user.
Advanced search honors all permission checks in the application by
filtering out projects that a user does not have access to at search time.

## Elasticsearch workers overload Sidekiq

In some cases, Elasticsearch cannot connect to GitLab anymore because:

- The Elasticsearch password has been updated on one side only (`Unauthorized [401] ... unable to authenticate user` errors).
- A firewall or network issue impairs connectivity (`Failed to open TCP connection to <ip>:9200` errors).

These errors are logged in [`gitlab-rails/elasticsearch.log`](../../administration/logs/index.md#elasticsearchlog). To retrieve the errors, use [`jq`](../../administration/logs/log_parsing.md):

```shell
$ jq --raw-output 'select(.severity == "ERROR") | [.error_class, .error_message] | @tsv' \
    gitlab-rails/elasticsearch.log |
  sort | uniq -c
```

`Elastic` workers and [Sidekiq jobs](../../administration/admin_area.md#background-jobs) could also appear much more often
because Elasticsearch frequently attempts to reindex if a previous job fails.
You can use [`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats#usage)
or `jq` to count workers in the [Sidekiq logs](../../administration/logs/index.md#sidekiq-logs):

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

When you reindex, you might get a `Couldn't load task status` error. A `sliceId must be greater than 0 but was [-1]` error might also appear on the Elasticsearch host. As a workaround, consider [reindexing from scratch](../elasticsearch/troubleshooting/indexing.md#last-resort-to-recreate-an-index) or upgrading to GitLab 16.3.

For more information, see [issue 422938](https://gitlab.com/gitlab-org/gitlab/-/issues/422938).

## Migration `BackfillProjectPermissionsInBlobs` has been halted in GitLab 15.11

In GitLab 15.11, it is possible for the `BackfillProjectPermissionsInBlobs` migration to be halted with the following error message in the `elasticsearch.log`:

```shell
migration has failed with NoMethodError:undefined method `<<' for nil:NilClass, no retries left
```

If `BackfillProjectPermissionsInBlobs` is the only halted migration, you can upgrade to the latest patch version of GitLab 16.0, which includes [the fix](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118494). Otherwise, you can ignore the error as it will not affect the current functionality of advanced search.

## `ElasticIndexInitialBulkCronWorker` and `ElasticIndexBulkCronWorker` jobs stuck in deduplication

In GitLab 16.5 and earlier, the `ElasticIndexInitialBulkCronWorker` and `ElasticIndexBulkCronWorker` jobs might get stuck in deduplication. This issue might prevent advanced search from properly indexing documents even after creating a new index. In GitLab 16.6, `idempotent!` was [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135817) for bulk cron workers that perform indexing.

The Sidekiq log might have the following entries:

```shell
{"severity":"INFO","time":"2023-10-31T10:33:06.998Z","retry":0,"queue":"default","version":0,"queue_namespace":"cronjob","args":[],"class":"ElasticIndexInitialBulkCronWorker",
...
"idempotency_key":"resque:gitlab:duplicate:default:<value>","duplicate-of":"91e8673347d4dc84fbad5319","job_size_bytes":2,"pid":12047,"job_status":"deduplicated","message":"ElasticIndexInitialBulkCronWorker JID-5e1af9180d6e8f991fc773c6: deduplicated: until executing","deduplication.type":"until executing"}
```

To resolve this issue:

1. In a [Rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session), run this command:

   ```shell
   idempotency_key = "<idempotency_key_from_log_entry>"
   duplicate_key = "resque:gitlab:#{idempotency_key}:cookie:v2"
   Gitlab::Redis::Queues.with { |c| c.del(duplicate_key) }
   ```

1. Replace `<idempotency_key_from_log_entry>` with the actual entry in your log.
