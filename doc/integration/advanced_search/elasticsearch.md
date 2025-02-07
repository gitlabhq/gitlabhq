---
stage: Foundations
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Elasticsearch
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

This page describes how to enable advanced search. When enabled,
advanced search provides faster search response times and [improved search features](../../user/search/advanced_search.md).

To enable advanced search, you must:

1. [Install an Elasticsearch or AWS OpenSearch cluster](#install-an-elasticsearch-or-aws-opensearch-cluster).
1. [Enable advanced search](#enable-advanced-search).

NOTE:
Advanced search stores all projects in the same Elasticsearch indices.
However, private projects appear in search results only to users who have access.

## Elasticsearch glossary

This glossary provides definitions for terms related to Elasticsearch.

- **Lucene**: A full-text search library written in Java.
- **Near real time (NRT)**: Refers to the slight latency from the time to index a
  document to the time when it becomes searchable.
- **Cluster**: A collection of one or more nodes that work together to hold all
  the data, providing indexing and search capabilities.
- **Node**: A single server that works as part of a cluster.
- **Index**: A collection of documents that have somewhat similar characteristics.
- **Document**: A basic unit of information that can be indexed.
- **Shards**: Fully-functional and independent subdivisions of indices. Each shard is actually
  a Lucene index.
- **Replicas**: Failover mechanisms that duplicate indices.

## Install an Elasticsearch or AWS OpenSearch cluster

Elasticsearch and AWS OpenSearch are **not** included in the Linux package.
You can install a search cluster yourself or use a cloud-hosted offering such as:

- [Elasticsearch Service](https://www.elastic.co/elasticsearch/service) (available on Amazon Web Services, Google Cloud Platform, and Microsoft Azure)
- [Amazon OpenSearch Service](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/gsg.html)

You should install the search cluster on a separate server.
Running the search cluster on the same server as GitLab might lead to performance issues.

For a search cluster with a single node, the cluster status is always yellow because the primary shard is allocated.
The cluster cannot assign replica shards to the same node as primary shards.

NOTE:
Before you use a new Elasticsearch cluster in production, see
[important Elasticsearch configuration](https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html).

### Version requirements

#### Elasticsearch

> - Support for Elasticsearch 6.8 [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/350275) in GitLab 15.0.

Advanced search works with the following versions of Elasticsearch.

| GitLab version        | Elasticsearch version       |
|-----------------------|-----------------------------|
| GitLab 15.0 and later | Elasticsearch 7.x and later |
| GitLab 14.0 to 14.10  | Elasticsearch 6.8 to 7.x    |

Advanced search follows the [Elasticsearch end-of-life policy](https://www.elastic.co/support/eol).
When we change Elasticsearch supported versions in GitLab, we announce them in [deprecation notes](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#update-the-deprecations-doc) in monthly release posts
before we remove them.

#### OpenSearch

| GitLab version          | OpenSearch version             |
|-------------------------|--------------------------------|
| GitLab 17.6.3 and later | OpenSearch 1.x and later       |
| GitLab 15.5.3 to 17.6.2 | OpenSearch 1.x, 2.0 to 2.17    |
| GitLab 15.0 to 15.5.2   | OpenSearch 1.x                 |

If your version of Elasticsearch or OpenSearch is incompatible, to prevent data loss, indexing pauses and
a message is logged in the
[`elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog) file.

If you are using a compatible version and after connecting to OpenSearch, you get the message `Elasticsearch version not compatible`, [resume indexing](#resume-indexing).

### System requirements

Elasticsearch and AWS OpenSearch require more resources than
[GitLab installation requirements](../../install/requirements.md).

Memory, CPU, and storage requirements depend on the amount of data you index into the cluster.
Heavily used Elasticsearch clusters might require more resources.
The [`estimate_cluster_size`](#gitlab-advanced-search-rake-tasks) Rake task uses the total repository size
to estimate the advanced search storage requirements.

### Access requirements

GitLab supports both [HTTP and role-based authentication methods](#advanced-search-configuration)
depending on your requirements and the backend service you use.

#### Role-based access control for Elasticsearch

Elasticsearch can offer role-based access control to further secure a cluster. To access and perform operations in the
Elasticsearch cluster, the `Username` configured in the **Admin** area must have roles that grant the following
privileges. The `Username` makes requests from GitLab to the search cluster.

For more information,
see [Elasticsearch role based access control](https://www.elastic.co/guide/en/elasticsearch/reference/current/authorization.html#roles)
and [Elasticsearch security privileges](https://www.elastic.co/guide/en/elasticsearch/reference/current/security-privileges.html).

```json
{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": ["gitlab-*"],
      "privileges": [
        "create_index",
        "delete_index",
        "view_index_metadata",
        "read",
        "manage",
        "write"
      ]
    }
  ]
}
```

#### Access control for AWS OpenSearch Service

Prerequisites:

- You must have a [service-linked role](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/slr.html)
  in your AWS account named `AWSServiceRoleForAmazonOpenSearchService` when you create OpenSearch domains.
- The domain access policy for AWS OpenSearch must allow `es:ESHttp*` actions.

`AWSServiceRoleForAmazonOpenSearchService` is used by **all** OpenSearch domains.
In most cases, this role is created automatically when you use the AWS Management Console to create the first OpenSearch domain.
To create a service-linked role manually, see the
[AWS documentation](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/slr-aos.html#create-slr).

AWS OpenSearch Service has three main security layers:

- [Network](#network)
- [Domain access policy](#domain-access-policy)
- [Fine-grained access control](#fine-grained-access-control)

##### Network

With this security layer, you can select **Public access** when you create
a domain so requests from any client can reach the domain endpoint.
If you select **VPC access**, clients must connect to the VPC
for requests to reach the endpoint.

For more information, see the
[AWS documentation](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-access-policies).

##### Domain access policy

GitLab supports the following methods of domain access control for AWS OpenSearch:

- [**Resource-based (domain) access policy**](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ac.html#ac-types-resource): where the AWS OpenSearch domain is configured with an IAM policy
- [**Identity-based policy**](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ac.html#ac-types-identity): where clients use IAM principals with policies to configure access

###### Resource-based policy examples

Here's an example of a resource-based (domain) access policy where `es:ESHttp*` actions are allowed:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "es:ESHttp*"
      ],
      "Resource": "arn:aws:es:us-west-1:987654321098:domain/test-domain/*"
    }
  ]
}
```

Here's an example of a resource-based (domain) access policy where `es:ESHttp*` actions are allowed only for a specific IAM principal:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::123456789012:user/test-user"
        ]
      },
      "Action": [
        "es:ESHttp*"
      ],
      "Resource": "arn:aws:es:us-west-1:987654321098:domain/test-domain/*"
    }
  ]
}
```

###### Identity-based policy examples

Here's an example of an identity-based access policy attached to an IAM principal where `es:ESHttp*` actions are allowed:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "es:ESHttp*",
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
```

##### Fine-grained access control

When you enable fine-grained access control, you must set a
[master user](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-master-user) in one of the following ways:

- [Set an IAM ARN as a master user](#set-an-iam-arn-as-a-master-user).
- [Create a master user](#create-a-master-user).

###### Set an IAM ARN as a master user

If you use an IAM principal as a master user, all requests
to the cluster must be signed with AWS Signature Version 4.
You can also specify an IAM ARN, which is the IAM role you assigned to your EC2 instance.
For more information, see the
[AWS documentation](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-master-user).

To set an IAM ARN as a master user, you must
use AWS OpenSearch Service with IAM credentials on your GitLab instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Expand **Advanced Search**.
1. In the **AWS OpenSearch IAM credentials** section:
   1. Select the **Use AWS OpenSearch Service with IAM credentials** checkbox.
   1. In **AWS region**, enter the AWS region where your OpenSearch domain
      is located (for example, `us-east-1`).
   1. In **AWS access key** and **AWS secret access key**,
      enter your access keys for authentication.

      NOTE:
      For GitLab deployments on EC2 instances, you do not have to enter access keys.
      Your GitLab instance obtains these keys automatically from the
      [AWS Instance Metadata Service (IMDS)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html).

1. Select **Save changes**.

###### Create a master user

If you create a master user in the internal user database,
you can use HTTP basic authentication to make requests to the cluster.
For more information, see the
[AWS documentation](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-master-user).

To create a master user, you must configure the OpenSearch domain URL and
the master username and password on your GitLab instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Expand **Advanced Search**.
1. In **OpenSearch domain URL**, enter the URL to the OpenSearch domain endpoint.
1. In **Username**, enter the master username.
1. In **Password**, enter the master password.
1. Select **Save changes**.

### Upgrade to a new Elasticsearch major version

> - Support for Elasticsearch 6.8 [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/350275) in GitLab 15.0.

When you upgrade Elasticsearch, you do not have to change the GitLab configuration.

During an Elasticsearch upgrade, you must:

- Pause indexing so changes can still be tracked.
- Disable advanced search so searches do not fail with an `HTTP 500` error.

When the Elasticsearch cluster is fully upgraded and active, [resume indexing](#resume-indexing) and enable advanced search.

When you upgrade to GitLab 15.0 and later, you must use Elasticsearch 7.x and later.

## Elasticsearch repository indexer

To index Git repository data, GitLab uses [`gitlab-elasticsearch-indexer`](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer).
For self-compiled installations, see [install the indexer](#install-the-indexer).

### Install the indexer

You first install some dependencies and then build and install the indexer itself.

#### Install dependencies

This project relies on [International Components for Unicode](https://icu.unicode.org/) (ICU) for text encoding,
therefore we must ensure the development packages for your platform are
installed before running `make`.

##### Debian / Ubuntu

To install on Debian or Ubuntu, run:

```shell
sudo apt install libicu-dev
```

##### CentOS / RHEL

To install on CentOS or RHEL, run:

```shell
sudo yum install libicu-devel
```

##### macOS

NOTE:
You must first [install Homebrew](https://brew.sh/).

To install on macOS, run:

```shell
brew install icu4c
export PKG_CONFIG_PATH="/usr/local/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"
```

#### Build and install

To build and install the indexer, run:

```shell
indexer_path=/home/git/gitlab-elasticsearch-indexer

# Run the installation task for gitlab-elasticsearch-indexer:
sudo -u git -H bundle exec rake gitlab:indexer:install[$indexer_path] RAILS_ENV=production
cd $indexer_path && sudo make install
```

The `gitlab-elasticsearch-indexer` is installed to `/usr/local/bin`.

You can change the installation path with the `PREFIX` environment variable.
Remember to pass the `-E` flag to `sudo` if you do so.

Example:

```shell
PREFIX=/usr sudo -E make install
```

After installation, be sure to [enable Elasticsearch](#enable-advanced-search).

NOTE:
If you see an error such as `Permission denied - /home/git/gitlab-elasticsearch-indexer/` while indexing, you
may need to set the `production -> elasticsearch -> indexer_path` setting in your `gitlab.yml` file to
`/usr/local/bin/gitlab-elasticsearch-indexer`, which is where the binary is installed.

### View indexing errors

Errors from the [GitLab Elasticsearch Indexer](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer) are reported in
the [`elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog) file and the [`sidekiq.log`](../../administration/logs/_index.md#sidekiqlog) file with a `json.exception.class` of `Gitlab::Elastic::Indexer::Error`.
These errors may occur when indexing Git repository data.

## Enable advanced search

Prerequisites:

- You must have administrator access to the instance.

To enable advanced search:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Configure the [advanced search settings](#advanced-search-configuration) for
   your Elasticsearch cluster. Do not select the **Search with Elasticsearch enabled** checkbox yet.
1. [Index the instance](#index-the-instance).
1. Optional. [Check indexing status](#check-indexing-status).
1. After the indexing is complete, select the **Search with Elasticsearch enabled** checkbox, then select **Save changes**.

NOTE:
When your Elasticsearch cluster is down while Elasticsearch is enabled,
you might have problems updating documents such as issues because your
instance queues a job to index the change, but cannot find a valid
Elasticsearch cluster.

For GitLab instances with more than 50 GB of repository data, see [Index large instances efficiently](#index-large-instances-efficiently).

### Index the instance

#### From the user interface

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/271532) in GitLab 17.3.

Prerequisites:

- You must have administrator access to the instance.

You can perform initial indexing or re-create an index from the user interface.

To enable advanced search and index the instance from the user interface:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Select the **Elasticsearch indexing** checkbox, then select **Save changes**.
1. Select **Index the instance**.

#### With a Rake task

Prerequisites:

- You must have administrator access to the instance.

To index the entire instance, use the following Rake tasks:

```shell
# WARNING: This task deletes all existing indices
# For installations that use the Linux package
sudo gitlab-rake gitlab:elastic:index

# WARNING: This task deletes all existing indices
# For self-compiled installations
bundle exec rake gitlab:elastic:index RAILS_ENV=production
```

To index specific data, use the following Rake tasks:

```shell
# For installations that use the Linux package
sudo gitlab-rake gitlab:elastic:index_epics
sudo gitlab-rake gitlab:elastic:index_work_items
sudo gitlab-rake gitlab:elastic:index_group_wikis
sudo gitlab-rake gitlab:elastic:index_namespaces
sudo gitlab-rake gitlab:elastic:index_projects
sudo gitlab-rake gitlab:elastic:index_snippets
sudo gitlab-rake gitlab:elastic:index_users

# For self-compiled installations
bundle exec rake gitlab:elastic:index_epics RAILS_ENV=production
bundle exec rake gitlab:elastic:index_work_items RAILS_ENV=production
bundle exec rake gitlab:elastic:index_group_wikis RAILS_ENV=production
bundle exec rake gitlab:elastic:index_namespaces RAILS_ENV=production
bundle exec rake gitlab:elastic:index_projects RAILS_ENV=production
bundle exec rake gitlab:elastic:index_snippets RAILS_ENV=production
bundle exec rake gitlab:elastic:index_users RAILS_ENV=production
```

### Check indexing status

Prerequisites:

- You must have administrator access to the instance.

To check indexing status:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Expand **Indexing status**.

### Monitor the status of background jobs

Prerequisites:

- You must have administrator access to the instance.

To monitor the status of background jobs:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Monitoring > Background jobs**.
1. On the Sidekiq dashboard, select **Queues** and wait for the `elastic_commit_indexer` and `elastic_wiki_indexer` queues to drop to `0`.
   These queues contain jobs to index code and wiki data for projects and groups.

### Advanced search configuration

The following Elasticsearch settings are available:

| Parameter                                             | Description |
|-------------------------------------------------------|-------------|
| `Elasticsearch indexing`                              | Enables or disables Elasticsearch indexing and creates an empty index if one does not already exist. You may want to enable indexing but disable search to give the index time to be fully completed, for example. Also, keep in mind that this option doesn't have any impact on existing data, this only enables/disables the background indexer which tracks data changes and ensures new data is indexed. |
| `Pause Elasticsearch indexing`                        | Enables or disables temporary indexing pause. This is useful for cluster migration/reindexing. All changes are still tracked, but they are not committed to the Elasticsearch index until resumed. |
| `Search with Elasticsearch enabled`                   | Enables or disables using Elasticsearch in search. |
| `Requeue indexing workers`                            | Enable automatic requeuing of indexing workers. This improves non-code indexing throughput by enqueuing Sidekiq jobs until all documents are processed. Requeuing indexing workers is not recommended for smaller instances or instances with few Sidekiq processes. |
| `URL`                                                 | The URL of your Elasticsearch instance. Use a comma-separated list to support clustering (for example, `http://host1, https://host2:9200`). If your Elasticsearch instance is password-protected, use the `Username` and `Password` fields. Alternatively, use inline credentials such as `http://<username>:<password>@<elastic_host>:9200/`. If you use [OpenSearch](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/vpc.html), only connections over ports `80` and `443` are accepted. |
| `Username`                                                 | The `username` of your Elasticsearch instance. |
| `Password`                                                 | The password of your Elasticsearch instance. |
| `Number of Elasticsearch shards and replicas per index`    | Elasticsearch indices are split into multiple shards for performance reasons. In general, you should use at least five shards. Indices with tens of millions of documents should have more shards ([see the guidance](#guidance-on-choosing-optimal-cluster-configuration)). Changes to this value do not take effect until you re-create the index. For more information about scalability and resilience, see the [Elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/scalability.html). Each Elasticsearch shard can have a number of replicas. These replicas are a complete copy of the shard and can provide increased query performance or resilience against hardware failure. Increasing this value increases the total disk space required by the index. You can set the number of shards and replicas for each of the indices. |
| `Limit the amount of namespace and project data to index` | When you enable this setting, you can specify namespaces and projects to index. All other namespaces and projects use database search instead. If you enable this setting but do not specify any namespace or project, [only project records are indexed](#all-project-records-are-indexed). For more information, see [Limit the amount of namespace and project data to index](#limit-the-amount-of-namespace-and-project-data-to-index). |
| `Use AWS OpenSearch Service with IAM credentials` | Sign your OpenSearch requests using [AWS IAM authorization](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html), [AWS EC2 Instance Profile Credentials](https://docs.aws.amazon.com/codedeploy/latest/userguide/getting-started-create-iam-instance-profile.html#getting-started-create-iam-instance-profile-cli), or [AWS ECS Tasks Credentials](https://docs.aws.amazon.com/AmazonECS/latest/userguide/task-iam-roles.html). Refer to [Identity and Access Management in Amazon OpenSearch Service](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ac.html) for details of AWS hosted OpenSearch domain access policy configuration. |
| `AWS Region`                                          | The AWS region in which your OpenSearch Service is located. |
| `AWS Access Key`                                      | The AWS access key. |
| `AWS Secret Access Key`                               | The AWS secret access key. |
| `Maximum file size indexed`                           | See [the explanation in instance limits.](../../administration/instance_limits.md#maximum-file-size-indexed). |
| `Maximum field length`                                | See [the explanation in instance limits.](../../administration/instance_limits.md#maximum-field-length). |
| `Number of shards for non-code indexing` | Number of indexing worker shards. This improves non-code indexing throughput by enqueuing more parallel Sidekiq jobs. Increasing the number of shards is not recommended for smaller instances or instances with few Sidekiq processes. Default is `2`. |
| `Maximum bulk request size (MiB)` | Used by the GitLab Ruby and Go-based indexer processes. This setting indicates how much data must be collected (and stored in memory) in a given indexing process before submitting the payload to the Elasticsearch Bulk API. For the GitLab Go-based indexer, you should use this setting with `Bulk request concurrency`. `Maximum bulk request size (MiB)` must accommodate the resource constraints of both the Elasticsearch hosts and the hosts running the GitLab Go-based indexer from either the `gitlab-rake` command or the Sidekiq tasks. |
| `Bulk request concurrency`                            | The Bulk request concurrency indicates how many of the GitLab Go-based indexer processes (or threads) can run in parallel to collect data to subsequently submit to the Elasticsearch Bulk API. This increases indexing performance, but fills the Elasticsearch bulk requests queue faster. This setting should be used together with the Maximum bulk request size setting (see above) and needs to accommodate the resource constraints of both the Elasticsearch hosts and the hosts running the GitLab Go-based indexer either from the `gitlab-rake` command or the Sidekiq tasks. |
| `Client request timeout` | Elasticsearch HTTP client request timeout value in seconds. `0` means using the system default timeout value, which depends on the libraries that GitLab application is built upon. |
| `Code indexing concurrency` | Maximum number of Elasticsearch code indexing background jobs allowed to run concurrently. This only applies to repository indexing operations. |
| `Retry on failure` | Maximum number of possible retries for Elasticsearch search requests. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/486935) in GitLab 17.6. |

WARNING:
Increasing the values of `Maximum bulk request size (MiB)` and `Bulk request concurrency` can negatively impact
Sidekiq performance. Return them to their default values if you see increased `scheduling_latency_s` durations
in your Sidekiq logs. For more information, see
[issue 322147](https://gitlab.com/gitlab-org/gitlab/-/issues/322147).

### Limit the amount of namespace and project data to index

When you select the **Limit the amount of namespace and project data to index**
checkbox, you can specify namespaces and projects to index. If the namespace is a group,
any subgroups and projects belonging to those subgroups are also indexed.

Advanced search only provides cross-group code/commit search (global) if all name-spaces are indexed. In this particular scenario where only a subset of namespaces are indexed, a global search does not provide a code or commit scope. This is possible only in the scope of an indexed namespace. There is no way to code/commit search in multiple indexed namespaces (when only a subset of namespaces has been indexed). For example if two groups are indexed, there is no way to run a single code search on both. You can only run a code search on the first group and then on the second.

If you do not specify any namespace or project, [only project records are indexed](#all-project-records-are-indexed).

WARNING:
If you have already indexed your instance, you must regenerate the index to delete all existing data
for filtering to work correctly. To do this, run the Rake tasks `gitlab:elastic:recreate_index` and
`gitlab:elastic:clear_index_status`. Afterwards, removing a namespace or a project from the list deletes the data
from the Elasticsearch index as expected.

#### All project records are indexed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/428070) in GitLab 16.7 [with a flag](../../administration/feature_flags.md) named `search_index_all_projects`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148111) in GitLab 16.11. Feature flag `search_index_all_projects` removed.

When you select the **Limit the amount of namespace and project data to index** checkbox:

- All project records are indexed.
- Associated data (issues, merge requests, or code) is not indexed.

If you do not specify any namespace or project, only project records are indexed.

## Enable custom language analyzers

Prerequisites:

- You must have administrator access to the instance.

You can improve language support for Chinese and Japanese by using the [`smartcn`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-smartcn.html)
and [`kuromoji`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-kuromoji.html) analysis plugins from Elastic.

To enable custom language analyzers:

1. Install the desired plugins, refer to [Elasticsearch documentation](https://www.elastic.co/guide/en/elasticsearch/plugins/7.9/installation.html) for plugins installation instructions. The plugins must be installed on every node in the cluster, and each node must be restarted after installation. For a list of plugins, see the table later in this section.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Locate **Custom analyzers: language support**.
1. Enable plugins support for **Indexing**.
1. Select **Save changes** for the changes to take effect.
1. Trigger [zero-downtime reindexing](#zero-downtime-reindexing) or reindex everything from scratch to create a new index with updated mappings.
1. Enable plugins support for **Searching** after the previous step is completed.

For guidance on what to install, see the following Elasticsearch language plugin options:

| Parameter                                             | Description |
|-------------------------------------------------------|-------------|
| `Enable Chinese (smartcn) custom analyzer: Indexing`   | Enables or disables Chinese language support using [`smartcn`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-smartcn.html) custom analyzer for newly created indices.|
| `Enable Chinese (smartcn) custom analyzer: Search`   | Enables or disables using [`smartcn`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-smartcn.html) fields for advanced search. Only enable this after [installing the plugin](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-smartcn.html), enabling custom analyzer indexing and recreating the index.|
| `Enable Japanese (kuromoji) custom analyzer: Indexing`   | Enables or disables Japanese language support using [`kuromoji`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-kuromoji.html) custom analyzer for newly created indices.|
| `Enable Japanese (kuromoji) custom analyzer: Search`  | Enables or disables using [`kuromoji`](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-kuromoji.html) fields for advanced search. Only enable this after [installing the plugin](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-kuromoji.html), enabling custom analyzer indexing and recreating the index.|

## Disable advanced search

Prerequisites:

- You must have administrator access to the instance.

To disable advanced search in GitLab:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Clear the **Elasticsearch indexing** and **Search with Elasticsearch enabled** checkboxes.
1. Select **Save changes**.
1. Optional. For Elasticsearch instances that are still online, delete existing indices:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:delete_index

   # For self-compiled installations
   bundle exec rake gitlab:elastic:delete_index RAILS_ENV=production
   ```

## Resume indexing

Prerequisites:

- You must have administrator access to the instance.

To resume indexing:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Expand **Advanced Search**.
1. Clear the **Pause Elasticsearch indexing** checkbox.

## Zero-downtime reindexing

The idea behind this reindexing method is to leverage the [Elasticsearch reindex API](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html)
and Elasticsearch index alias feature to perform the operation. We set up an index alias which connects to a
`primary` index which is used by GitLab for reads/writes. When reindexing process starts, we temporarily pause
the writes to the `primary` index. Then, we create another index and invoke the Reindex API which migrates the
index data onto the new index. After the reindexing job is complete, we switch to the new index by connecting the
index alias to it which becomes the new `primary` index. At the end, we resume the writes and typical operation resumes.

### Using zero-downtime reindexing

You can use zero-downtime reindexing to configure index settings or mappings that cannot be changed without creating a new index and copying existing data. You should not use zero-downtime reindexing to fix missing data. Zero-downtime reindexing does not add data to the search cluster if the data is not already indexed. You must complete all [advanced search migrations](#advanced-search-migrations) before you start reindexing.

### Trigger reindexing

Prerequisites:

- You must have administrator access to the instance.

To trigger reindexing:

1. Sign in to your GitLab instance as an administrator.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Expand **Elasticsearch zero-downtime reindexing**.
1. Select **Trigger cluster reindexing**.

Reindexing can be a lengthy process depending on the size of your Elasticsearch cluster.

After this process is completed, the original index is scheduled to be deleted after
14 days. You can cancel this action by pressing the **Cancel** button on the same
page you triggered the reindexing process.

While the reindexing is running, you can follow its progress under that same section.

#### Trigger zero-downtime reindexing

Prerequisites:

- You must have administrator access to the instance.

To trigger zero-downtime reindexing:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Expand **Elasticsearch zero-downtime reindexing**.
   The following settings are available:

   - [Slice multiplier](#slice-multiplier)
   - [Maximum running slices](#maximum-running-slices)

##### Slice multiplier

The slice multiplier calculates the [number of slices during reindexing](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html#docs-reindex-slice).

GitLab uses [manual slicing](https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html#docs-reindex-manual-slice)
to control the reindex efficiently and safely, which enables users to retry only
failed slices.

The multiplier defaults to `2` and applies to the number of shards per index.
For example, if this value is `2` and your index has 20 shards, then the
reindex task is split into 40 slices.

##### Maximum running slices

The maximum running slices parameter defaults to `60` and corresponds to the
maximum number of slices allowed to run concurrently during Elasticsearch
reindexing.

Setting this value too high can have adverse performance impacts as your cluster
may become heavily saturated with searches and writes. Setting this value too
low may lead the reindexing process to take a very long time to complete.

The best value for this depends on your cluster size, whether you're willing
to accept some degraded search performance during reindexing, and how important
it is for the reindex to finish quickly and resume indexing.

### Mark the most recent reindexing job as failed and resume indexing

Prerequisites:

- You must have administrator access to the instance.

To abandon an unfinished reindexing job and resume indexing:

1. Mark the most recent reindexing job as failed:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:mark_reindex_failed

   # For self-compiled installations
   bundle exec rake gitlab:elastic:mark_reindex_failed RAILS_ENV=production
   ```

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Expand **Advanced Search**.
1. Clear the **Pause Elasticsearch indexing** checkbox.

## Index integrity

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112369) in GitLab 15.10 [with a flag](../../administration/feature_flags.md) named `search_index_integrity`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/392981) in GitLab 16.4. Feature flag `search_index_integrity` removed.

Index integrity detects and fixes missing repository data.
This feature is automatically used when code searches
scoped to a group or project return no results.

## Advanced search migrations

With reindex migrations running in the background, there's no need for a manual
intervention. This usually happens in situations where new features are added to
advanced search, which means adding or changing the way content is indexed.

### Migration dictionary files

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/414674) in GitLab 16.3.

Every migration has a corresponding dictionary file in the `ee/elastic/docs/` folder with the following information:

```yaml
name:
version:
description:
group:
milestone:
introduced_by_url:
obsolete:
marked_obsolete_by_url:
marked_obsolete_in_milestone:
```

You can use this information, for example, to identify when a migration was introduced or was marked as obsolete.

### Check for pending migrations

To check for pending advanced search migrations, run this command:

```shell
curl "$CLUSTER_URL/gitlab-production-migrations/_search?size=100&q=*" | jq .
```

This should return something similar to:

```json
{
  "took": 14,
  "timed_out": false,
  "_shards": {
    "total": 1,
    "successful": 1,
    "skipped": 0,
    "failed": 0
  },
  "hits": {
    "total": {
      "value": 1,
      "relation": "eq"
    },
    "max_score": 1,
    "hits": [
      {
        "_index": "gitlab-production-migrations",
        "_type": "_doc",
        "_id": "20230209195404",
        "_score": 1,
        "_source": {
          "completed": true
        }
      }
    ]
  }
}
```

To debug issues with the migrations, check the [`elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog) file.

### Retry a halted migration

Some migrations are built with a retry limit. If the migration cannot finish within the retry limit,
it is halted and a notification is displayed in the advanced search integration settings.

It is recommended to check the [`elasticsearch.log` file](../../administration/logs/_index.md#elasticsearchlog) to
debug why the migration was halted and make any changes before retrying the migration.

When you believe you've fixed the cause of the failure:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Search**.
1. Expand **Advanced Search**.
1. Inside the **Elasticsearch migration halted** alert box, select **Retry migration**. The migration is scheduled to be retried in the background.

If you cannot get the migration to succeed, you may
consider the
[last resort to recreate the index from scratch](../elasticsearch/troubleshooting/indexing.md#last-resort-to-recreate-an-index).
This may allow you to skip over
the problem because a newly created index skips all migrations as the index
is recreated with the correct up-to-date schema.

### All migrations must be finished before doing a major upgrade

Before upgrading to a major GitLab version, you must complete all
migrations that exist up until the latest minor version before that major
version. You must also resolve and [retry any halted migrations](#retry-a-halted-migration)
before proceeding with a major version upgrade. For more information, see [Migrations for upgrades](../../update/background_migrations.md).

Migrations that have been removed are
[marked as obsolete](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63001).
If you upgrade GitLab before all pending advanced search migrations are completed,
any pending migrations that have been removed in the new version cannot be executed or retried.
In this case, you must
[re-create your index from scratch](../elasticsearch/troubleshooting/indexing.md#last-resort-to-recreate-an-index).

### Skippable migrations

Skippable migrations are only executed when a condition is met.
For example, if a migration depends on a specific version of Elasticsearch, it could be skipped until that version is reached.

If a skippable migration is not executed by the time the migration is marked as obsolete, to apply the change you must
[re-create the index](../elasticsearch/troubleshooting/indexing.md#last-resort-to-recreate-an-index).

## GitLab advanced search Rake tasks

Rake tasks are available to:

- [Build and install](#build-and-install) the indexer.
- Delete indices when [disabling Elasticsearch](#disable-advanced-search).
- Add GitLab data to an index.

The following are some available Rake tasks:

| Task                                                                                                                                                    | Description                                                                                                                                                                               |
|:--------------------------------------------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`sudo gitlab-rake gitlab:elastic:info`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                            | Outputs debugging information for the advanced search integration. |
| [`sudo gitlab-rake gitlab:elastic:index`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                            | In GitLab 17.0 and earlier, enables Elasticsearch indexing and runs `gitlab:elastic:recreate_index`, `gitlab:elastic:clear_index_status`, `gitlab:elastic:index_group_entities`, `gitlab:elastic:index_projects`, `gitlab:elastic:index_snippets`, and `gitlab:elastic:index_users`.<br>In GitLab 17.1 and later, queues a Sidekiq job in the background. First, the job enables Elasticsearch indexing and pauses indexing to ensure all indices are created. Then, the job re-creates all indices, clears indexing status, and queues additional Sidekiq jobs to index project and group data, snippets, and users. Finally, Elasticsearch indexing is resumed to complete. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/421298) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `elastic_index_use_trigger_indexing`. Enabled by default. [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/434580) in GitLab 17.3. Feature flag `elastic_index_use_trigger_indexing` removed. |
| [`sudo gitlab-rake gitlab:elastic:pause_indexing`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                            | Pauses Elasticsearch indexing. Changes are still tracked. Useful for cluster/index migrations. |
| [`sudo gitlab-rake gitlab:elastic:resume_indexing`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                            | Resumes Elasticsearch indexing. |
| [`sudo gitlab-rake gitlab:elastic:index_projects`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                   | Iterates over all projects, and queues Sidekiq jobs to index them in the background. It can only be used after the index is created.                                                                                                      |
| [`sudo gitlab-rake gitlab:elastic:index_group_entities`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                | Invokes `gitlab:elastic:index_epics` and `gitlab:elastic:index_group_wikis`. |
| [`sudo gitlab-rake gitlab:elastic:index_epics`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                         | Indexes all epics from the groups where Elasticsearch is enabled. |
| [`sudo gitlab-rake gitlab:elastic:index_group_wikis`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                   | Indexes all wikis from the groups where Elasticsearch is enabled. |
| [`sudo gitlab-rake gitlab:elastic:index_projects_status`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)            | Determines the overall indexing status of all project repository data (code, commits, and wikis). The status is calculated by dividing the number of indexed projects by the total number of projects and multiplying by 100. This task does not include non-repository data such as issues, merge requests, or milestones. |
| [`sudo gitlab-rake gitlab:elastic:clear_index_status`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)               | Deletes all instances of IndexStatus for all projects. This command results in a complete wipe of the index, and it should be used with caution.                                                                                              |
| [`sudo gitlab-rake gitlab:elastic:create_empty_index`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake) | Generates empty indices (the default index and a separate issues index) and assigns an alias for each on the Elasticsearch side only if it doesn't already exist.                                                                                                      |
| [`sudo gitlab-rake gitlab:elastic:delete_index`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)       | Removes the GitLab indices and aliases (if they exist) on the Elasticsearch instance.                                                                                                                                   |
| [`sudo gitlab-rake gitlab:elastic:recreate_index`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)     | Wrapper task for `gitlab:elastic:delete_index` and `gitlab:elastic:create_empty_index`.                                                                       |
| [`sudo gitlab-rake gitlab:elastic:index_snippets`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                   | Performs an Elasticsearch import that indexes the snippets data.                                                                                                                          |
| [`sudo gitlab-rake gitlab:elastic:index_users`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                   | Imports all users into Elasticsearch.                                                                                                                 |
| [`sudo gitlab-rake gitlab:elastic:projects_not_indexed`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)             | Displays which projects do not have repository data indexed. This task does not include non-repository data such as issues, merge requests, or milestones.                                                                                                                                    |
| [`sudo gitlab-rake gitlab:elastic:reindex_cluster`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)                  | Schedules a zero-downtime cluster reindexing task. |
| [`sudo gitlab-rake gitlab:elastic:mark_reindex_failed`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)              | Mark the most recent re-index job as failed. |
| [`sudo gitlab-rake gitlab:elastic:list_pending_migrations`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)          | List pending migrations. Pending migrations include those that have not yet started, have started but not finished, and those that are halted. |
| [`sudo gitlab-rake gitlab:elastic:estimate_cluster_size`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)            | Get an estimate of cluster size based on the total repository size. |
| [`sudo gitlab-rake gitlab:elastic:estimate_shard_sizes`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)            | Get an estimate of shard sizes for each index based on approximate database counts. This estimate does not include repository data (code, commits, and wikis). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146108) in GitLab 16.11. |
| [`sudo gitlab-rake gitlab:elastic:enable_search_with_elasticsearch`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)            | Enables advanced search with Elasticsearch. |
| [`sudo gitlab-rake gitlab:elastic:disable_search_with_elasticsearch`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/tasks/gitlab/elastic.rake)            | Disables advanced search with Elasticsearch. |

### Environment variables

In addition to the Rake tasks, there are some environment variables that can be used to modify the process:

| Environment Variable | Data Type | What it does                                                                 |
| -------------------- |:---------:| ---------------------------------------------------------------------------- |
| `ID_TO`              | Integer   | Tells the indexer to only index projects less than or equal to the value.    |
| `ID_FROM`            | Integer   | Tells the indexer to only index projects greater than or equal to the value. |

### Indexing a range of projects or a specific project

Using the `ID_FROM` and `ID_TO` environment variables, you can index a limited number of projects. This can be useful for staging indexing.

```shell
root@git:~# sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=1 ID_TO=100
```

Because `ID_FROM` and `ID_TO` use the `or equal to` comparison, you can use them to index only one project
by setting both to the same project ID:

```shell
root@git:~# sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=5 ID_TO=5
Indexing project repositories...I, [2019-03-04T21:27:03.083410 #3384]  INFO -- : Indexing GitLab User / test (ID=33)...
I, [2019-03-04T21:27:05.215266 #3384]  INFO -- : Indexing GitLab User / test (ID=33) is done!
```

## Advanced search index scopes

When performing a search, the GitLab index uses the following scopes:

| Scope Name       | What it searches       |
|------------------|------------------------|
| `commits`        | Commit data            |
| `projects`       | Project data (default) |
| `blobs`          | Code                   |
| `issues`         | Issue data             |
| `merge_requests` | Merge request data     |
| `milestones`     | Milestone data         |
| `notes`          | Note data              |
| `snippets`       | Snippet data           |
| `wiki_blobs`     | Wiki contents          |
| `users`          | Users                  |
| `epics`          | Epic data              |

## Tuning

### Guidance on choosing optimal cluster configuration

For basic guidance on choosing a cluster configuration you may refer to [Elastic Cloud Calculator](https://cloud.elastic.co/pricing). You can find more information below.

- Generally, you want to use at least a 2-node cluster configuration with one replica, which allows you to have resilience. If your storage usage is growing quickly, you may want to plan horizontal scaling (adding more nodes) beforehand.
- It's not recommended to use HDD storage with the search cluster, because it takes a hit on performance. It's better to use SSD storage (NVMe or SATA SSD drives for example).
- You should not use [coordinating-only nodes](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html#coordinating-only-node) with large instances. Coordinating-only nodes are smaller than [data nodes](https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-node.html#data-node), which can impact performance and [advanced search migrations](#advanced-search-migrations).
- You can use the [GitLab Performance Tool](https://gitlab.com/gitlab-org/quality/performance) to benchmark search performance with different search cluster sizes and configurations.
- `Heap size` should be set to no more than 50% of your physical RAM. Additionally, it shouldn't be set to more than the threshold for zero-based compressed oops. The exact threshold varies, but 26 GB is safe on most systems, but can also be as large as 30 GB on some systems. See [Heap size settings](https://www.elastic.co/guide/en/elasticsearch/reference/current/important-settings.html#heap-size-settings) and [Setting JVM options](https://www.elastic.co/guide/en/elasticsearch/reference/current/jvm-options.html) for more details.
- `refresh_interval` is a per index setting. You may want to adjust that from default `1s` to a bigger value if you don't need data in real-time. This changes how soon you see fresh results. If that's important for you, you should leave it as close as possible to the default value.
- You might want to raise [`indices.memory.index_buffer_size`](https://www.elastic.co/guide/en/elasticsearch/reference/current/indexing-buffer.html) to 30% or 40% if you have a lot of heavy indexing operations.

### Advanced search settings

#### Number of Elasticsearch shards

For single-node clusters, set the number of Elasticsearch shards per index to the number of
CPU cores. Keep the average shard size between a few GB and 30 GB.

For multi-node clusters, set the number of Elasticsearch shards per index to at least `5`.

To update the shard size for an index, change the setting and trigger [zero-downtime reindexing](#zero-downtime-reindexing).

##### Indices with database data

> - `gitlab:elastic:estimate_shard_sizes` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146108) in GitLab 16.11.

For indices that contain database data:

- `gitlab-production-projects`
- `gitlab-production-issues`
- `gitlab-production-epics`
- `gitlab-production-merge_requests`
- `gitlab-production-notes`
- `gitlab-production-users`

Run the Rake task `gitlab:elastic:estimate_shard_sizes` to determine the number of shards.
The task returns approximate document counts and recommendations for shard and replica sizes.

##### Indices with repository data

For indices that contain repository data:

- `gitlab-production`
- `gitlab-production-wikis`
- `gitlab-production-commits`

Keep the average shard size between a few GB and 30 GB.
If the average shard size grows to more than 30 GB, increase the shard size
for the index and trigger [zero-downtime reindexing](#zero-downtime-reindexing).
To ensure the cluster is healthy, the number of shards per node
must not exceed 20 times the configured heap size.
For example, a node with a 30 GB heap must have a maximum of 600 shards.

#### Number of Elasticsearch replicas

For single-node clusters, set the number of Elasticsearch replicas per index to `0`.

For multi-node clusters, set the number of Elasticsearch replicas per index to `1` (each shard has one replica).
The number must not be `0` because losing one node corrupts the index.

### Index large instances efficiently

Prerequisites:

- You must have administrator access to the instance.

WARNING:
Indexing a large instance generates a lot of Sidekiq jobs.
Make sure to prepare for this task by having a
[scalable setup](../../administration/reference_architectures/_index.md) or by creating
[extra Sidekiq processes](../../administration/sidekiq/extra_sidekiq_processes.md).

If [enabling advanced search](#enable-advanced-search) causes problems
due to large volumes of data being indexed:

1. [Configure your Elasticsearch host and port](#enable-advanced-search).
1. Create empty indices:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:create_empty_index

   # For self-compiled installations
   bundle exec rake gitlab:elastic:create_empty_index RAILS_ENV=production
   ```

1. If this is a re-index of your GitLab instance, clear the index status:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:clear_index_status

   # For self-compiled installations
   bundle exec rake gitlab:elastic:clear_index_status RAILS_ENV=production
   ```

1. [Select the **Elasticsearch indexing** checkbox](#enable-advanced-search).
1. Indexing large Git repositories can take a while. To speed up the process, you can [tune for indexing speed](https://www.elastic.co/guide/en/elasticsearch/reference/current/tune-for-indexing-speed.html#tune-for-indexing-speed):

   - You can temporarily increase [`refresh_interval`](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-refresh.html).

   - You can set the number of replicas to 0. This setting controls the number of copies each primary shard of an index has. Thus, having 0 replicas effectively disables the replication of shards across nodes, which should increase the indexing performance. This is an important trade-off in terms of reliability and query performance. It is important to remember to set the replicas to a considered value after the initial indexing is complete.

   You can expect a 20% decrease in indexing time. After the indexing is complete, you can set `refresh_interval` and `number_of_replicas` back to their desired values.

   NOTE:
   This step is optional but may help significantly speed up large indexing operations.

   ```shell
   curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
        --data '{
          "index" : {
              "refresh_interval" : "30s",
              "number_of_replicas" : 0
          } }'
   ```

1. Index projects and their associated data:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:index_projects

   # For self-compiled installations
   bundle exec rake gitlab:elastic:index_projects RAILS_ENV=production
   ```

   This enqueues a Sidekiq job for each project that needs to be indexed.
   You can view the jobs in the **Admin** area under **Monitoring > Background jobs > Queues Tab**
   and select `elastic_commit_indexer`, or you can query indexing status using a Rake task:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:index_projects_status

   # For self-compiled installations
   bundle exec rake gitlab:elastic:index_projects_status RAILS_ENV=production

   Indexing is 65.55% complete (6555/10000 projects)
   ```

   If you want to limit the index to a range of projects you can provide the
   `ID_FROM` and `ID_TO` parameters:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=1001 ID_TO=2000

   # For self-compiled installations
   bundle exec rake gitlab:elastic:index_projects ID_FROM=1001 ID_TO=2000 RAILS_ENV=production
   ```

   Where `ID_FROM` and `ID_TO` are project IDs. Both parameters are optional.
   The above example indexes all projects from ID `1001` up to (and including) ID `2000`.

   NOTE:
   Sometimes the project indexing jobs queued by `gitlab:elastic:index_projects`
   can get interrupted. This may happen for many reasons, but it's always safe
   to run the indexing task again.

   You can also use the `gitlab:elastic:clear_index_status` Rake task to force the
   indexer to "forget" all progress, so it retries the indexing process from the
   start.

1. Epics, group wikis, personal snippets, and users are not associated with a project and must be indexed separately:

   ```shell
   # For installations that use the Linux package
   sudo gitlab-rake gitlab:elastic:index_epics
   sudo gitlab-rake gitlab:elastic:index_group_wikis
   sudo gitlab-rake gitlab:elastic:index_snippets
   sudo gitlab-rake gitlab:elastic:index_users

   # For self-compiled installations
   bundle exec rake gitlab:elastic:index_epics RAILS_ENV=production
   bundle exec rake gitlab:elastic:index_group_wikis RAILS_ENV=production
   bundle exec rake gitlab:elastic:index_snippets RAILS_ENV=production
   bundle exec rake gitlab:elastic:index_users RAILS_ENV=production
   ```

1. Enable replication and refreshing again after indexing (only if you previously increased `refresh_interval`):

   ```shell
   curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
        --data '{
          "index" : {
              "number_of_replicas" : 1,
              "refresh_interval" : "1s"
          } }'
   ```

   A force merge should be called after enabling the refreshing above.

   For Elasticsearch 6.x and later, ensure the index is in read-only mode before proceeding with the force merge:

   ```shell
   curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
        --data '{
          "settings": {
            "index.blocks.write": true
          } }'
   ```

   Then, initiate the force merge:

   ```shell
   curl --request POST 'localhost:9200/gitlab-production/_forcemerge?max_num_segments=5'
   ```

   Then, change the index back to read-write mode:

   ```shell
   curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
        --data '{
          "settings": {
            "index.blocks.write": false
          } }'
   ```

1. After the indexing is complete, [select the **Search with Elasticsearch enabled** checkbox](#enable-advanced-search).

### Deleted documents

Whenever a change or deletion is made to an indexed GitLab object (a merge request description is changed, a file is deleted from the default branch in a repository, a project is deleted, etc), a document in the index is deleted. However, since these are "soft" deletes, the overall number of "deleted documents", and therefore wasted space, increases. Elasticsearch does intelligent merging of segments to remove these deleted documents. However, depending on the amount and type of activity in your GitLab installation, it's possible to see as much as 50% wasted space in the index.

In general, we recommend letting Elasticsearch merge and reclaim space automatically, with the default settings. From [Lucene's Handling of Deleted Documents](https://www.elastic.co/blog/lucenes-handling-of-deleted-documents "Lucene's Handling of Deleted Documents"), _"Overall, besides perhaps decreasing the maximum segment size, it is best to leave Lucene defaults as-is and not fret too much about when deletes are reclaimed."_

However, some larger installations may wish to tune the merge policy settings:

- Consider reducing the `index.merge.policy.max_merged_segment` size from the default 5 GB to maybe 2 GB or 3 GB. Merging only happens when a segment has at least 50% deletions. Smaller segment sizes allows merging to happen more frequently.

  ```shell
  curl --request PUT localhost:9200/gitlab-production/_settings ---header 'Content-Type: application/json' \
       --data '{
         "index" : {
           "merge.policy.max_merged_segment": "2gb"
         }
       }'
  ```

- You can also adjust `index.merge.policy.reclaim_deletes_weight`, which controls how aggressively deletions are targeted. But this can lead to costly merge decisions, so we recommend not changing this unless you understand the tradeoffs.

  ```shell
  curl --request PUT localhost:9200/gitlab-production/_settings ---header 'Content-Type: application/json' \
       --data '{
         "index" : {
           "merge.policy.reclaim_deletes_weight": "3.0"
         }
       }'
  ```

- Do not do a [force merge](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-forcemerge.html "Force Merge") to remove deleted documents. A warning in the [documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-forcemerge.html "Force Merge") states that this can lead to very large segments that may never get reclaimed, and can also cause significant performance or availability issues.

## Index large instances with dedicated Sidekiq nodes or processes

WARNING:
Most instances should not need to configure this. The steps below use an advanced setting of Sidekiq called [routing rules](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules).
Be sure to fully understand about the implication of using routing rules to avoid losing jobs entirely.

Indexing a large instance can be a lengthy and resource-intensive process that has the potential
of overwhelming Sidekiq nodes and processes. This negatively affects the GitLab performance and
availability.

As GitLab allows you to start multiple Sidekiq processes, you can create an
additional process dedicated to indexing a set of queues (or queue group). This way, you can
ensure that indexing queues always have a dedicated worker, while the rest of the queues have
another dedicated worker to avoid contention.

For this purpose, use the [routing rules](../../administration/sidekiq/processing_specific_job_classes.md#routing-rules)
option that allows Sidekiq to route jobs to a specific queue based on [worker matching query](../../administration/sidekiq/processing_specific_job_classes.md#worker-matching-query).

To handle this, we generally recommend one of the following two options. You can either:

- [Use two queue groups on one single node](#single-node-two-processes).
- [Use two queue groups, one on each node](#two-nodes-one-process-for-each).

For the steps below, consider the entry of `sidekiq['routing_rules']`:

- `["feature_category=global_search", "global_search"]` as all indexing jobs are routed to the `global_search` queue.
- `["*", "default"]` as all other non-indexing jobs are routed to the `default` queue.

At least one process in `sidekiq['queue_groups']` has to include the `mailers` queue, otherwise mailers jobs are not processed at all.

NOTE:
Routing rules (`sidekiq['routing_rules']`) must be the same across all GitLab nodes (especially GitLab Rails and Sidekiq nodes).

WARNING:
When starting multiple processes, the number of processes cannot exceed the number of CPU
cores you want to dedicate to Sidekiq. Each Sidekiq process can use only one CPU core, subject
to the available workload and concurrency settings. For more details, see how to
[run multiple Sidekiq processes](../../administration/sidekiq/extra_sidekiq_processes.md).

### Single node, two processes

To create both an indexing and a non-indexing Sidekiq process in one node:

1. On your Sidekiq node, change the `/etc/gitlab/gitlab.rb` file to:

   ```ruby
   sidekiq['enable'] = true

   sidekiq['routing_rules'] = [
      ["feature_category=global_search", "global_search"],
      ["*", "default"],
   ]

   sidekiq['queue_groups'] = [
      "global_search", # process that listens to global_search queue
      "default,mailers" # process that listens to default and mailers queue
   ]

   sidekiq['min_concurrency'] = 20
   sidekiq['max_concurrency'] = 20
   ```

   If you are using GitLab 16.11 and earlier, explicitly disable any
   [queue selectors](https://archives.docs.gitlab.com/16.11/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors-deprecated):

   ```ruby
   sidekiq['queue_selector'] = false
   ```

1. Save the file and [reconfigure GitLab](../../administration/restart_gitlab.md)
   for the changes to take effect.
1. On all other Rails and Sidekiq nodes, ensure that `sidekiq['routing_rules']` is the same as above.
1. Run the Rake task to [migrate existing jobs](../../administration/sidekiq/sidekiq_job_migration.md):

NOTE:
It is important to run the Rake task immediately after reconfiguring GitLab.
After reconfiguring GitLab, existing jobs are not processed until the Rake task starts to migrate the jobs.

### Two nodes, one process for each

To handle these queue groups on two nodes:

1. To set up the indexing Sidekiq process, on your indexing Sidekiq node, change the `/etc/gitlab/gitlab.rb` file to:

   ```ruby
   sidekiq['enable'] = true

   sidekiq['routing_rules'] = [
      ["feature_category=global_search", "global_search"],
      ["*", "default"],
   ]

   sidekiq['queue_groups'] = [
     "global_search", # process that listens to global_search queue
   ]

   sidekiq['min_concurrency'] = 20
   sidekiq['max_concurrency'] = 20
   ```

   If you are using GitLab 16.11 and earlier, explicitly disable any
   [queue selectors](https://archives.docs.gitlab.com/16.11/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors-deprecated):

   ```ruby
   sidekiq['queue_selector'] = false
   ```

1. Save the file and [reconfigure GitLab](../../administration/restart_gitlab.md)
   for the changes to take effect.

1. To set up the non-indexing Sidekiq process, on your non-indexing Sidekiq node, change the `/etc/gitlab/gitlab.rb` file to:

   ```ruby
   sidekiq['enable'] = true

   sidekiq['routing_rules'] = [
      ["feature_category=global_search", "global_search"],
      ["*", "default"],
   ]

   sidekiq['queue_groups'] = [
      "default,mailers" # process that listens to default and mailers queue
   ]

   sidekiq['min_concurrency'] = 20
   sidekiq['max_concurrency'] = 20
   ```

   If you are using GitLab 16.11 and earlier, explicitly disable any
   [queue selectors](https://archives.docs.gitlab.com/16.11/ee/administration/sidekiq/processing_specific_job_classes.html#queue-selectors-deprecated):

   ```ruby
   sidekiq['queue_selector'] = false
   ```

1. On all other Rails and Sidekiq nodes, ensure that `sidekiq['routing_rules']` is the same as above.
1. Save the file and [reconfigure GitLab](../../administration/restart_gitlab.md)
   for the changes to take effect.
1. Run the Rake task to [migrate existing jobs](../../administration/sidekiq/sidekiq_job_migration.md):

   ```shell
   sudo gitlab-rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule gitlab:sidekiq:migrate_jobs:queued
   ```

NOTE:
It is important to run the Rake task immediately after reconfiguring GitLab.
After reconfiguring GitLab, existing jobs are not processed until the Rake task starts to migrate the jobs.

## Reverting to Basic Search

Sometimes there may be issues with your Elasticsearch index data and as such
GitLab allows you to revert to "basic search" when there are no search
results and assuming that basic search is supported in that scope. This "basic
search" behaves as though you don't have advanced search enabled at all for
your instance and search using other data sources (such as PostgreSQL data and Git
data).

## Disaster recovery

Elasticsearch is a secondary data store for GitLab.
All of the data stored in Elasticsearch can be derived again
from other data sources, specifically PostgreSQL and Gitaly.
If the Elasticsearch data store gets corrupted,
you can reindex everything from scratch.

If your Elasticsearch index is too large, it might cause
too much downtime to reindex everything from scratch.
You cannot automatically find discrepancies and resync an Elasticsearch index,
but you can inspect the logs for any missing updates.
To recover data more quickly, you can replay:

1. All synced non-repository updates by searching in
   [`elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog)
   for [`track_items`](https://gitlab.com/gitlab-org/gitlab/-/blob/1e60ea99bd8110a97d8fc481e2f41cab14e63d31/ee/app/services/elastic/process_bookkeeping_service.rb#L25).
   You must send these items again through
   `::Elastic::ProcessBookkeepingService.track!`.
1. All repository updates by searching in
   [`elasticsearch.log`](../../administration/logs/_index.md#elasticsearchlog)
   for [`indexing_commit_range`](https://gitlab.com/gitlab-org/gitlab/-/blob/6f9d75dd3898536b9ec2fb206e0bd677ab59bd6d/ee/lib/gitlab/elastic/indexer.rb#L41).
   You must set [`IndexStatus#last_commit/last_wiki_commit`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/models/index_status.rb)
   to the oldest `from_sha` in the logs and then trigger another index of
   the project with [`ElasticCommitIndexerWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/elastic_commit_indexer_worker.rb) and [`ElasticWikiIndexerWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/elastic_wiki_indexer_worker.rb).
1. All project deletes by searching in
   [`sidekiq.log`](../../administration/logs/_index.md#sidekiqlog) for
   [`ElasticDeleteProjectWorker`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/elastic_delete_project_worker.rb).
   You must trigger another `ElasticDeleteProjectWorker`.

You can also take regular
[Elasticsearch snapshots](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html) to reduce the time it takes to recover from data loss without reindexing everything from scratch.
