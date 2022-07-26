---
type: reference
stage: Data Stores
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Elasticsearch troubleshooting **(PREMIUM SELF)**

Use the following information to troubleshoot Elasticsearch issues.

## View logs

One of the most valuable tools for identifying issues with the Elasticsearch
integration are logs. The most relevant logs for this integration are:

1. [`sidekiq.log`](../../administration/logs/index.md#sidekiqlog) - All of the
   indexing happens in Sidekiq, so much of the relevant logs for the
   Elasticsearch integration can be found in this file.
1. [`elasticsearch.log`](../../administration/logs/index.md#elasticsearchlog) - There
   are additional logs specific to Elasticsearch that are sent to this file
   that may contain useful diagnostic information about searching,
   indexing or migrations.

Here are some common pitfalls and how to overcome them.

## How can I verify that my GitLab instance is using Elasticsearch?

There are a couple of ways to achieve that:

- Whenever you perform a search there is a link on the search results page
  in the top right hand corner saying "Advanced search functionality is enabled".
  This is always correctly identifying whether the current project/namespace
  being searched is using Elasticsearch.

- From the Admin Area under **Settings > Advanced Search** check that the
  Advanced Search settings are checked.

  Those same settings there can be obtained from the Rails console if necessary:

  ```ruby
  ::Gitlab::CurrentSettings.elasticsearch_search?         # Whether or not searches will use Elasticsearch
  ::Gitlab::CurrentSettings.elasticsearch_indexing?       # Whether or not content will be indexed in Elasticsearch
  ::Gitlab::CurrentSettings.elasticsearch_limit_indexing? # Whether or not Elasticsearch is limited only to certain projects/namespaces
  ```

- If Elasticsearch is limited to specific namespaces and you need to know if
  Elasticsearch is being used for a specific project or namespace, you can use
  the Rails console:

  ```ruby
  ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: Namespace.find_by_full_path("/my-namespace"))
  ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: Project.find_by_full_path("/my-namespace/my-project"))
  ```

## I updated GitLab and now I can't find anything

We continuously make updates to our indexing strategies and aim to support
newer versions of Elasticsearch. When indexing changes are made, it may
be necessary for you to [reindex](elasticsearch.md#zero-downtime-reindexing) after updating GitLab.

## I indexed all the repositories but I can't get any hits for my search term in the UI

Make sure you [indexed all the database data](elasticsearch.md#enable-advanced-search).

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

It is important to understand at which level the problem is manifesting (UI, Rails code, Elasticsearch side) to be able to [troubleshoot further](../../administration/troubleshooting/elasticsearch.md#search-results-workflow).

NOTE:
The above instructions are not to be used for scenarios that only index a [subset of namespaces](elasticsearch.md#limit-the-number-of-namespaces-and-projects-that-can-be-indexed).

See [Elasticsearch Index Scopes](elasticsearch.md#advanced-search-index-scopes) for more information on searching for specific types of data.

## I indexed all the repositories but then switched Elasticsearch servers and now I can't find anything

You must re-run all the Rake tasks to reindex the database, repositories, and wikis.

## The indexing process is taking a very long time

The more data present in your GitLab instance, the longer the indexing process takes.

## There are some projects that weren't indexed, but I don't know which ones

You can run `sudo gitlab-rake gitlab:elastic:projects_not_indexed` to display projects that aren't indexed.

## No new data is added to the Elasticsearch index when I push code

NOTE:
This was [fixed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/35936) in GitLab 13.2 and the Rake task is not available for versions greater than that.

When performing the initial indexing of blobs, we lock all projects until the project finishes indexing. It could happen that an error during the process causes one or multiple projects to remain locked. To unlock them, run:

```shell
sudo gitlab-rake gitlab:elastic:clear_locked_projects
```

## `Can't specify parent if no parent field has been configured` error

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

## `Elasticsearch::Transport::Transport::Errors::BadRequest`

If you have this exception (just like in the case above but the actual message is different) please check if you have the correct Elasticsearch version and you met the other [requirements](elasticsearch.md#system-requirements).
There is also an easy way to check it automatically with `sudo gitlab-rake gitlab:check` command.

## `Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge`

```plaintext
[413] {"Message":"Request size exceeded 10485760 bytes"}
```

This exception is seen when your Elasticsearch cluster is configured to reject requests above a certain size (10MiB in this case). This corresponds to the `http.max_content_length` setting in `elasticsearch.yml`. Increase it to a larger size and restart your Elasticsearch cluster.

AWS has [fixed limits](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/limits.html#network-limits) for this setting ("Maximum size of HTTP request payloads"), based on the size of the underlying instance.

## My single node Elasticsearch cluster status never goes from `yellow` to `green` even though everything seems to be running properly

**For a single node Elasticsearch cluster the functional cluster health status is yellow** (never green) because the primary shard is allocated but replicas cannot be as there is no other node to which Elasticsearch can assign a replica. This also applies if you are using the [Amazon OpenSearch](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/aes-handling-errors.html#aes-handling-errors-yellow-cluster-status) service.

WARNING:
Setting the number of replicas to `0` is discouraged (this is not allowed in the GitLab Elasticsearch Integration menu). If you are planning to add more Elasticsearch nodes (for a total of more than 1 Elasticsearch) the number of replicas needs to be set to an integer value larger than `0`. Failure to do so results in lack of redundancy (losing one node corrupts the index).

If you have a **hard requirement to have a green status for your single node Elasticsearch cluster**, please make sure you understand the risks outlined in the previous paragraph and then run the following query to set the number of replicas to `0`(the cluster no longer tries to create any shard replicas):

```shell
curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
     --data '{
       "index" : {
         "number_of_replicas" : 0
       }
     }'
```

## `health check timeout: no Elasticsearch node available` error in Sidekiq

If you're getting a `health check timeout: no Elasticsearch node available` error in Sidekiq during the indexing process:

```plaintext
Gitlab::Elastic::Indexer::Error: time="2020-01-23T09:13:00Z" level=fatal msg="health check timeout: no Elasticsearch node available"
```

You probably have not used either `http://` or `https://` as part of your value in the **"URL"** field of the Elasticsearch Integration Menu. Please make sure you are using either `http://` or `https://` in this field as the [Elasticsearch client for Go](https://github.com/olivere/elastic) that we are using [needs the prefix for the URL to be accepted as valid](https://github.com/olivere/elastic/commit/a80af35aa41856dc2c986204e2b64eab81ccac3a).
After you have corrected the formatting of the URL, delete the index (via the [dedicated Rake task](elasticsearch.md#gitlab-advanced-search-rake-tasks)) and [reindex the content of your instance](elasticsearch.md#enable-advanced-search).

## My Elasticsearch cluster has a plugin and the integration is not working

Certain 3rd party plugins may introduce bugs in your cluster or for whatever
reason may be incompatible with our integration. You should try disabling
plugins so you can rule out the possibility that the plugin is causing the
problem.

## Low-level troubleshooting

There is a [more structured, lower-level troubleshooting document](../../administration/troubleshooting/elasticsearch.md) for when you experience other issues, including poor performance.

## Elasticsearch `code_analyzer` doesn't account for all code cases

The `code_analyzer` pattern and filter configuration is being evaluated for improvement. We have fixed [most edge cases](https://gitlab.com/groups/gitlab-org/-/epics/3621#note_363429094) that were not returning expected search results due to our pattern and filter configuration.

Improvements to the `code_analyzer` pattern and filters are being discussed in [epic 3621](https://gitlab.com/groups/gitlab-org/-/epics/3621).

## Some binary files may not be searchable by name

In GitLab 13.9, a change was made where [binary file names are being indexed](https://gitlab.com/gitlab-org/gitlab/-/issues/301083). However, without indexing all projects' data from scratch, only binary files that are added or updated after the GitLab 13.9 release are searchable.

## Last resort to recreate an index

There may be cases where somehow data never got indexed and it's not in the
queue, or the index is somehow in a state where migrations just cannot
proceed. It is always best to try to troubleshoot the root cause of the problem
by [viewing the logs](#view-logs).

If there are no other options, then you always have the option of recreating the
entire index from scratch. If you have a small GitLab installation, this can
sometimes be a quick way to resolve a problem, but if you have a large GitLab
installation, then this might take a very long time to complete. Until the
index is fully recreated, your index does not serve correct search results,
so you may want to disable **Search with Elasticsearch** while it is running.

If you are sure you've read the above caveats and want to proceed, then you
should run the following Rake task to recreate the entire index from scratch:

**For Omnibus installations**

```shell
# WARNING: DO NOT RUN THIS UNTIL YOU READ THE DESCRIPTION ABOVE
sudo gitlab-rake gitlab:elastic:index
```

**For installations from source**

```shell
# WARNING: DO NOT RUN THIS UNTIL YOU READ THE DESCRIPTION ABOVE
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:elastic:index
```

## How does Advanced Search handle private projects?

Advanced Search stores all the projects in the same Elasticsearch indices,
however, searches only surface results that can be viewed by the user.
Advanced Search honors all permission checks in the application by
filtering out projects that a user does not have access to at search time.

## Indexing fails with `error: elastic: Error 429 (Too Many Requests)`

If `ElasticCommitIndexerWorker` Sidekiq workers are failing with this error during indexing, it usually means that Elasticsearch is unable to keep up with the concurrency of indexing request. To address change the following settings:

- To decrease the indexing throughput you can decrease `Bulk request concurrency` (see [Advanced Search settings](elasticsearch.md#advanced-search-configuration)). This is set to `10` by default, but you change it to as low as 1 to reduce the number of concurrent indexing operations.
- If changing `Bulk request concurrency` didn't help, you can use the [queue selector](../../administration/operations/extra_sidekiq_processes.md#queue-selector) option to [limit indexing jobs only to specific Sidekiq nodes](elasticsearch.md#index-large-instances-with-dedicated-sidekiq-nodes-or-processes), which should reduce the number of indexing requests.

## Indexing is very slow or fails with `rejected execution of coordinating operation` messages

Bulk requests getting rejected by the Elasticsearch nodes are likely due to load and lack of available memory.
Ensure that your Elasticsearch cluster meets the [system requirements](elasticsearch.md#system-requirements) and has enough resources
to perform bulk operations. See also the error ["429 (Too Many Requests)"](#indexing-fails-with-error-elastic-error-429-too-many-requests).

## Access requirements for the self-managed AWS OpenSearch Service

To use the self-managed AWS OpenSearch Service with GitLab, configure your instance's domain access policies
to contain the actions below.
See [Identity and Access Management in Amazon OpenSearch Service](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ac.html) for details.

```plaintext
es:ESHttpDelete
es:ESHttpGet
es:ESHttpHead
es:ESHttpPost
es:ESHttpPut
es:ESHttpPatch
```

## Role-mapping when using AWS Elasticsearch or AWS OpenSearch fine-grained access control

When using fine-grained access control with an IAM role, you might encounter the following error:

```plaintext
{"error":{"root_cause":[{"type":"security_exception","reason":"no permissions for [indices:data/write/bulk] and User [name=arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE, backend_roles=[arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE], requestedTenant=null]"}],"type":"security_exception","reason":"no permissions for [indices:data/write/bulk] and User [name=arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE, backend_roles=[arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE], requestedTenant=null]"},"status":403}
```

To fix this, you need to [map the roles to users](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-mapping) in Kibana.
