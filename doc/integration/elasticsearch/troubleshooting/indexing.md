---
stage: Foundations
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting Elasticsearch indexing
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

When working with Elasticsearch indexing, you might encounter the following issues.

## Create an empty index

For indexing issues, try first to create an empty index.
Check the Elasticsearch instance to see if the `gitlab-production` index exists.
If it does, manually delete the index on the Elasticsearch instance and try to recreate it from the
[`recreate_index`](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks)
Rake task.

If you still encounter issues, try to create an index manually on the Elasticsearch instance.
If you:

- Cannot create indices, contact your Elasticsearch administrator.
- Can create indices, contact GitLab Support.

## Check the status of indexed projects

You can check for errors during project indexing.
Errors might occur on:

- The GitLab instance: if you cannot fix them yourself, contact GitLab Support for guidance.
- The Elasticsearch instance: [if the error is not listed](../../advanced_search/elasticsearch_troubleshooting.md), contact your Elasticsearch administrator.

If indexing does not return errors, check the status of indexed projects with the following Rake tasks:

- [`sudo gitlab-rake gitlab:elastic:index_projects_status`](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks)
  for the overall status
- [`sudo gitlab-rake gitlab:elastic:projects_not_indexed`](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks)
  for specific projects that are not indexed

If indexing is:

- Complete, contact GitLab Support.
- Not complete, try to reindex that project by running
  `sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=<project ID> ID_TO=<project ID>`.

If reindexing the project shows errors on:

- The GitLab instance: contact GitLab Support.
- The Elasticsearch instance or no errors at all: contact your Elasticsearch administrator to check the instance.

## No search results after updating GitLab

We continuously make updates to our indexing strategies and aim to support
newer versions of Elasticsearch. When indexing changes are made, you might
have to [reindex](../../advanced_search/elasticsearch.md#zero-downtime-reindexing) after updating GitLab.

## No search results after indexing all repositories

Make sure you [indexed all the database data](../../advanced_search/elasticsearch.md#enable-advanced-search).

If there aren't any results (hits) in the UI search, check if you are seeing the same results via the rails console (`sudo gitlab-rails console`):

```ruby
u = User.find_by_username('your-username')
s = SearchService.new(u, {:search => 'search_term', :scope => 'blobs'})
pp s.search_objects.to_a
```

Beyond that, check via the [Elasticsearch Search API](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-search.html) to see if the data shows up on the Elasticsearch side:

```shell
curl --request GET <elasticsearch_server_ip>:9200/gitlab-production/_search?q=<search_term>
```

More [complex Elasticsearch API calls](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-filter-context.html) are also possible.

If the results:

- Sync up, check that you are using [supported syntax](../../../user/search/advanced_search.md#syntax). Advanced search does not support [exact substring matching](https://gitlab.com/gitlab-org/gitlab/-/issues/325234).
- Do not match up, this indicates a problem with the documents generated from the project. It is best to [re-index that project](../../advanced_search/elasticsearch.md#indexing-a-range-of-projects-or-a-specific-project).

NOTE:
The above instructions are not to be used for scenarios that only index a [subset of namespaces](../../advanced_search/elasticsearch.md#limit-the-amount-of-namespace-and-project-data-to-index).

See [Elasticsearch Index Scopes](../../advanced_search/elasticsearch.md#advanced-search-index-scopes) for more information on searching for specific types of data.

## No search results after switching Elasticsearch servers

To reindex the database, repositories, and wikis, run all Rake tasks again.

## Indexing fails with `error: elastic: Error 429 (Too Many Requests)`

If `ElasticCommitIndexerWorker` Sidekiq workers are failing with this error during indexing, it usually means that Elasticsearch is unable to keep up with the concurrency of indexing request. To address change the following settings:

- To decrease the indexing throughput you can decrease `Bulk request concurrency` (see [Advanced search settings](../../advanced_search/elasticsearch.md#advanced-search-configuration)). This is set to `10` by default, but you change it to as low as 1 to reduce the number of concurrent indexing operations.
- If changing `Bulk request concurrency` didn't help, you can use the [routing rules](../../../administration/sidekiq/processing_specific_job_classes.md#routing-rules) option to [limit indexing jobs only to specific Sidekiq nodes](../../advanced_search/elasticsearch.md#index-large-instances-with-dedicated-sidekiq-nodes-or-processes), which should reduce the number of indexing requests.

## Indexing is very slow or fails with `rejected execution of coordinating operation`

Bulk requests getting rejected by the Elasticsearch nodes are likely due to load and lack of available memory.
Ensure that your Elasticsearch cluster meets the [system requirements](../../advanced_search/elasticsearch.md#system-requirements) and has enough resources
to perform bulk operations. See also the error ["429 (Too Many Requests)"](#indexing-fails-with-error-elastic-error-429-too-many-requests).

## Indexing fails with `strict_dynamic_mapping_exception`

Indexing might fail if all [advanced search migrations were not finished before doing a major upgrade](../../advanced_search/elasticsearch.md#all-migrations-must-be-finished-before-doing-a-major-upgrade).
A large Sidekiq backlog might accompany this error. To fix the indexing failures, you must re-index the database, repositories, and wikis.

1. Pause indexing so Sidekiq can catch up:

   ```shell
   sudo gitlab-rake gitlab:elastic:pause_indexing
   ```

1. [Recreate the index from scratch](#last-resort-to-recreate-an-index).
1. Resume indexing:

   ```shell
   sudo gitlab-rake gitlab:elastic:resume_indexing
   ```

## Indexing keeps pausing with `elasticsearch_pause_indexing setting is enabled`

You might notice that new data is not being detected when you run a search.

This error occurs when that new data is not being indexed properly.

To resolve this error, [reindex your data](../../advanced_search/elasticsearch.md#zero-downtime-reindexing).

However, when reindexing, you might get an error where the indexing process keeps pausing, and the Elasticsearch logs show the following:

```shell
"message":"elasticsearch_pause_indexing setting is enabled. Job was added to the waiting queue"
```

If reindexing does not resolve this issue, and you did not pause the indexing process manually, this error might be happening because two GitLab instances share one Elasticsearch cluster.

To resolve this error, disconnect one of the GitLab instances from using the Elasticsearch cluster.

For more information, see [issue 3421](https://gitlab.com/gitlab-org/gitlab/-/issues/3421).

## Last resort to recreate an index

There may be cases where somehow data never got indexed and it's not in the
queue, or the index is somehow in a state where migrations just cannot
proceed. It is always best to try to troubleshoot the root cause of the problem
by [viewing the logs](access.md#view-logs).

As a last resort, you can recreate the index from scratch. For small GitLab installations,
recreating the index can be a quick way to resolve some issues. For large GitLab
installations, however, this method might take a very long time. Your index
does not show correct search results until the indexing is complete. You might
want to clear the **Search with Elasticsearch enabled** checkbox
while the indexing is running.

If you are sure you've read the above caveats and want to proceed, then you
should run the following Rake task to recreate the entire index from scratch.

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
# WARNING: DO NOT RUN THIS UNTIL YOU READ THE DESCRIPTION ABOVE
sudo gitlab-rake gitlab:elastic:index
```

:::TabTitle Self-compiled (source)

```shell
# WARNING: DO NOT RUN THIS UNTIL YOU READ THE DESCRIPTION ABOVE
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:elastic:index
```

::EndTabs

## Improve Elasticsearch performance

To improve performance, ensure:

- The Elasticsearch server **is not** running on the same node as GitLab.
- The Elasticsearch server have enough RAM and CPU cores.
- That sharding **is** being used.

Going into some more detail here, if Elasticsearch is running on the same server as GitLab, resource contention is **very** likely to occur. Ideally, Elasticsearch, which requires ample resources, should be running on its own server (maybe coupled with Logstash and Kibana).

When it comes to Elasticsearch, RAM is the key resource. Elasticsearch themselves recommend:

- **At least** 8 GB of RAM for a non-production instance.
- **At least** 16 GB of RAM for a production instance.
- Ideally, 64 GB of RAM.

For CPU, Elasticsearch recommends at least 2 CPU cores, but Elasticsearch states common
setups use up to 8 cores. For more details on server specs, check out the
[Elasticsearch hardware guide](https://www.elastic.co/guide/en/elasticsearch/guide/current/hardware.html).

Beyond the obvious, sharding comes into play. Sharding is a core part of Elasticsearch.
It allows for horizontal scaling of indices, which is helpful when you are dealing with
a large amount of data.

With the way GitLab does indexing, there is a **huge** amount of documents being
indexed. By using sharding, you can speed up the ability of Elasticsearch to locate
data because each shard is a Lucene index.

If you are not using sharding, you are likely to hit issues when you start using
Elasticsearch in a production environment.

An index with only one shard has **no scale factor** and is likely
to encounter issues when called upon with some frequency. See the
[Elasticsearch documentation on capacity planning](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/capacity-planning.html).

The easiest way to determine if sharding is in use is to check the output of the
[Elasticsearch Health API](https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-health.html):

- Red means the cluster is down.
- Yellow means it is up with no sharding/replication.
- Green means it is healthy (up, sharding, replicating).

For production use, it should always be green.

Beyond these steps, you get into some of the more complicated things to check,
such as merges and caching. These can get complicated and it takes some time to
learn them, so it is best to escalate/pair with an Elasticsearch expert if you need to
dig further into these.

Reach out to GitLab Support, but this is likely to be something a skilled
Elasticsearch administrator has more experience with.

## Slow initial indexing

The more data your GitLab instance has, the longer the indexing takes.
You can estimate cluster size with the Rake task `sudo gitlab-rake gitlab:elastic:estimate_cluster_size`.

### For code documents

Ensure you have enough Sidekiq nodes and processes to efficiently index code, commits, and wikis.
If your initial indexing is slow, consider [dedicated Sidekiq nodes or processes](../../advanced_search/elasticsearch.md#index-large-instances-with-dedicated-sidekiq-nodes-or-processes).

### For non-code documents

If the initial indexing is slow but Sidekiq has enough nodes and processes,
you can adjust advanced search worker settings in GitLab.
For **Requeue indexing workers**, the default value is `false`.
For **Number of shards for non-code indexing**, the default value is `2`.
These settings limit indexing to 2000 documents per minute.

To adjust worker settings:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Expand **Advanced Search**.
1. Select the **Requeue indexing workers** checkbox.
1. In the **Number of shards for non-code indexing** text box, enter a value higher than `2`.
1. Select **Save changes**.
