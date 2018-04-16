# Elasticsearch integration **[STARTER ONLY]**

>
[Introduced][ee-109] in GitLab [Starter][ee] 8.4. Support
for [Amazon Elasticsearch][aws-elastic] was [introduced][ee-1305] in GitLab
[Starter][ee] 9.0.

This document describes how to set up Elasticsearch with GitLab. Once enabled,
you'll have the benefit of fast search response times and the advantage of two
special searches:

- [Advance Global Search](../user/search/advanced_global_search.md)
- [Advanced Syntax Search](../user/search/advanced_search_syntax.md)

## Requirements

| GitLab version | Elasticsearch version |
| -------------- | --------------------- |
| GitLab Enterprise Edition 8.4 - 8.17  | Elasticsearch 2.4 with [Delete By Query Plugin](https://www.elastic.co/guide/en/elasticsearch/plugins/2.4/plugins-delete-by-query.html) installed |
| GitLab Enterprise Edition 9.0+        | Elasticsearch 5.1 - 5.5 |

Elasticsearch 6.0+ is not supported currently. [We will support 6.0+ in the future.](https://gitlab.com/gitlab-org/gitlab-ee/issues/4218)

## Installing Elasticsearch

Elasticsearch is _not_ included in the Omnibus packages. You will have to
install it yourself whether you are using the Omnibus package or installed
GitLab from source. Providing detailed information on installing Elasticsearch
is out of the scope of this document.

Once the data is added to the database or repository and [Elasticsearch is
enabled in the admin area](#enable-elasticsearch) the search index will be
updated automatically. Elasticsearch can be installed on the same machine as
GitLab, or on a separate server, or you can use the [Amazon Elasticsearch][aws-elastic]
service.

You can follow the steps as described in the [official web site][install] or
use the packages that are available for your OS.

## Enabling Elasticsearch

In order to enable Elasticsearch, you need to have admin access. Go to
**Admin > Settings** and find the "Elasticsearch" section.

The following Elasticsearch settings are available:

| Parameter                           | Description |
| ---------                           | ----------- |
| `Elasticsearch indexing`            | Enables/disables Elasticsearch indexing. You may want to enable indexing but disable search in order to give the index time to be fully completed, for example. Also keep in mind that this option doesn't have any impact on existing data, this only enables/disables background indexer which tracks data changes. So by enabling this you will not get your existing data indexed, use special rake task for that as explained in [Adding GitLab's data to the Elasticsearch index](#adding-gitlabs-data-to-the-elasticsearch-index). |
| `Use experimental repository indexer` | Perform repository indexing using [GitLab Elasticsearch Indexer](https://gitlab.com/gitlab-org/gitlab-elasticsearch-indexer). |
| `Search with Elasticsearch enabled` | Enables/disables using Elasticsearch in search. |
| `URL`                              | The URL to use for connecting to Elasticsearch. Use a comma-separated list to support clustering (e.g., "http://host1, https://host2:9200"). |
| `Using AWS hosted Elasticsearch with IAM credentials` | Sign your Elasticsearch requests using [AWS IAM authorization][aws-iam] or [AWS EC2 Instance Profile Credentials][aws-instance-profile]. The policies must be configured to allow `es:*` actions. |
| `AWS Region` | The AWS region your Elasticsearch service is located in. |
| `AWS Access Key` | The AWS access key. |
| `AWS Secret Access Key` | The AWS secret access key. |

## Disabling Elasticsearch

To disable the Elasticsearch integration:

1. Navigate to the **Admin area > Settings**
1. Find the 'Elasticsearch' section and uncheck 'Search with Elasticsearch enabled'
   and 'Elasticsearch indexing'
1. Click **Save** for the changes to take effect

## Adding GitLab's data to the Elasticsearch index

### Indexing small instances (database size less than 500 MiB, size of repos less than 5 GiB)

Configure Elasticsearch's host and port in **Admin > Settings**. Then create empty indexes using one of the following commands:

```
# Omnibus installations
sudo gitlab-rake gitlab:elastic:create_empty_index

# Installations from source
bundle exec rake gitlab:elastic:create_empty_index RAILS_ENV=production
```

Then enable Elasticsearch indexing and run repository indexing tasks:

```
# Omnibus installations
sudo gitlab-rake gitlab:elastic:index

# Installations from source
bundle exec rake gitlab:elastic:index RAILS_ENV=production
```

Enable Elasticsearch search.

### Indexing large instances

Configure Elasticsearch's host and port in **Admin > Settings**. Then create empty indexes using one of the following commands:

```
# Omnibus installations
sudo gitlab-rake gitlab:elastic:create_empty_index

# Installations from source
bundle exec rake gitlab:elastic:create_empty_index RAILS_ENV=production
```

Indexing large Git repositories can take a while. To speed up the process, you
can temporarily disable auto-refreshing and replicating. In our experience you can expect a 20%
time drop. We'll enable them when indexing is done. This step is optional!

```bash
curl --request PUT localhost:9200/gitlab-production/_settings --data '{
    "index" : {
        "refresh_interval" : "-1",
        "number_of_replicas" : 0
    } }'
```

Then enable Elasticsearch indexing and run repository indexing tasks:

```
# Omnibus installations
sudo gitlab-rake gitlab:elastic:index_repositories_async

# Installations from source
bundle exec rake gitlab:elastic:index_repositories_async RAILS_ENV=production
```

This enqueues a number of Sidekiq jobs to index your existing repositories.
You can view the jobs in the admin panel (they are placed in the `elastic_batch_project_indexer`)
queue), or you can query indexing status using a rake task:


```
# Omnibus installations
sudo gitlab-rake gitlab:elastic:index_repositories_status

# Installations from source
bundle exec rake gitlab:elastic:index_repositories_status RAILS_ENV=production

Indexing is 65.55% complete (6555/10000 projects)
```

By default, one job is created for every 300 projects. For large numbers of
projects, you may wish to increase the batch size, by setting the `BATCH`
environment variable. You may also wish to consider [throttling](../administration/operations/sidekiq_job_throttling.md)
the `elastic_batch_project_indexer` queue, as this step can be I/O-intensive.

You can also run the initial indexing synchronously - this is most useful if
you have a small number of projects, or need finer-grained control over indexing
than Sidekiq permits:

```
# Omnibus installations
sudo gitlab-rake gitlab:elastic:index_repositories

# Installations from source
bundle exec rake gitlab:elastic:index_repositories RAILS_ENV=production
```

It might take a while depending on how big your Git repositories are.

If you want to run several tasks in parallel (probably in separate terminal
windows) you can provide the `ID_FROM` and `ID_TO` parameters:

```
# Omnibus installations
sudo gitlab-rake gitlab:elastic:index_repositories ID_FROM=1001 ID_TO=2000

# Installations from source
bundle exec rake gitlab:elastic:index_repositories ID_FROM=1001 ID_TO=2000 RAILS_ENV=production
```

Where `ID_FROM` and `ID_TO` are project IDs. Both parameters are optional.
As an example, if you have 3,000 repositories and you want to run three separate indexing tasks, you might run:

```
# Omnibus installations
sudo gitlab-rake gitlab:elastic:index_repositories ID_TO=1000
sudo gitlab-rake gitlab:elastic:index_repositories ID_FROM=1001 ID_TO=2000
sudo gitlab-rake gitlab:elastic:index_repositories ID_FROM=2001

# Installations from source
bundle exec rake gitlab:elastic:index_repositories RAILS_ENV=production ID_TO=1000
bundle exec rake gitlab:elastic:index_repositories RAILS_ENV=production ID_FROM=1001 ID_TO=2000
bundle exec rake gitlab:elastic:index_repositories RAILS_ENV=production ID_FROM=2001
```

Sometimes your repository index process `gitlab:elastic:index_repositories` or
`gitlab:elastic:index_repositories_async` can get interrupted. This may happen
for many reasons, but it's always safe to run the indexing job again - it will
skip those repositories that have already been indexed.

As the indexer stores the last commit SHA of every indexed repository in the
database, you can run the indexer with the special parameter `UPDATE_INDEX` and
it will check every project repository again to make sure that every commit in
that repository is indexed, it can be useful in case if your index is outdated:

```
# Omnibus installations
sudo gitlab-rake gitlab:elastic:index_repositories UPDATE_INDEX=true ID_TO=1000

# Installations from source
bundle exec rake gitlab:elastic:index_repositories UPDATE_INDEX=true ID_TO=1000 RAILS_ENV=production
```

You can also use the `gitlab:elastic:clear_index_status` Rake task to force the
indexer to "forget" all progresss, so retrying the indexing process from the
start.

To index all wikis:

```
# Omnibus installations
sudo gitlab-rake gitlab:elastic:index_wikis

# Installations from source
bundle exec rake gitlab:elastic:index_wikis RAILS_ENV=production
```

The wiki indexer also supports the `ID_FROM` and `ID_TO` parameters if you want
to limit a project set.

Index all database entities (Keep in mind it can take a while so consider using `screen` or `tmux`):

```
# Omnibus installations
sudo gitlab-rake gitlab:elastic:index_database

# Installations from source
bundle exec rake gitlab:elastic:index_database RAILS_ENV=production
```

Enable replication and refreshing again after indexing (only if you previously disabled it):

```bash
curl --request PUT localhost:9200/gitlab-production/_settings --data '{
    "index" : {
        "number_of_replicas" : 1,
        "refresh_interval" : "1s"
    } }'
```

A force merge should be called after enabling the refreshing above:

```bash
curl --request POST 'http://localhost:9200/_forcemerge?max_num_segments=5'
```

Enable Elasticsearch search in **Admin > Settings**. That's it. Enjoy it!

## Troubleshooting

Here are some common pitfalls and how to overcome them:

- **I indexed all the repositories but I can't find anything**

    Make sure you indexed all the database data [as stated above](#adding-gitlab-data-to-the-elasticsearch-index).

- **"Can't specify parent if no parent field has been configured"**

    If you enabled Elasticsearch before GitLab 8.12 and have not rebuilt indexes you will get
    exception in lots of different cases:

    ```
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

    This is because we changed the index mapping in GitLab 8.12 and the old indexes should be removed and built from scratch again,
    see details in the [8-11-to-8-12 update guide](https://gitlab.com/gitlab-org/gitlab-ee/blob/master/doc/update/8.11-to-8.12.md#11-elasticsearch-index-update-if-you-currently-use-elasticsearch).

- Exception `Elasticsearch::Transport::Transport::Errors::BadRequest`

    If you have this exception (just like in the case above but the actual message is different) please check if you have the correct Elasticsearch version and you met the other [requirements](#requirements).
    There is also an easy way to check it automatically with `sudo gitlab-rake gitlab:check` command.

- Exception `Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge`

    ```
    [413] {"Message":"Request size exceeded 10485760 bytes"}
    ```

    This exception is seen when your Elasticsearch cluster is configured to reject
    requests above a certain size (10MiB in this case). This corresponds to the
    `http.max_content_length` setting in `elasticsearch.yml`. Increase it to a
    larger size and restart your Elasticsearch cluster.

    AWS has [fixed limits](http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/aes-limits.html)
    for this setting ("Maximum Size of HTTP Request Payloads"), based on the size of
    the underlying instance.

[ee-1305]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1305
[aws-elastic]: http://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/es-gsg.html
[aws-iam]: http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html
[aws-instance-profile]: http://docs.aws.amazon.com/codedeploy/latest/userguide/getting-started-create-iam-instance-profile.html#getting-started-create-iam-instance-profile-cli
[ee-109]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/109 "Elasticsearch Merge Request"
[elasticsearch]: https://www.elastic.co/products/elasticsearch "Elasticsearch website"
[install]: https://www.elastic.co/guide/en/elasticsearch/reference/current/_installation.html "Elasticsearch installation documentation"
[pkg]: https://about.gitlab.com/downloads/ "Download Omnibus GitLab"
[elastic-settings]: https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration.html#settings "Elasticsearch configuration settings"
[ee]: https://about.gitlab.com/products/
