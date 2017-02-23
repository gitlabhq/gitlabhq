# Elasticsearch integration

>[Introduced][ee-109] in GitLab EE 8.4.

[Elasticsearch] is a flexible, scalable and powerful search service.

If you want to keep GitLab's search fast when dealing with huge amount of data,
you should consider [enabling Elasticsearch](#enable-elasticsearch).

GitLab leverages the search capabilities of Elasticsearch and enables it when
searching in:

- GitLab application
- Issues
- Merge requests
- Milestones
- Notes
- Projects
- Repositories
- Snippets
- Wiki

Once the data is added to the database or repository and [Elasticsearch is
enabled in the admin area](#enable-elasticsearch) the search index will be
updated automatically. Elasticsearch can be installed on the same machine as
GitLab, or on a separate server.

## Requirements

| GitLab version | Elasticsearch version |
| -------------- | --------------------- |
| GitLab Enterprise Edition 8.4 - 8.17  | Elasticsearch 2.4 with [Delete By Query Plugin](https://www.elastic.co/guide/en/elasticsearch/plugins/2.4/plugins-delete-by-query.html) installed |
| GitLab Enterprise Edition 9.0+        | Elasticsearch 5.1 |

## Install Elasticsearch

Elasticsearch is _not_ included in the Omnibus packages. You will have to
install it yourself whether you are using the Omnibus package or installed
GitLab from source. Providing detailed information on installing Elasticsearch
is out of the scope of this document.

You can follow the steps as described in the [official web site][install] or
use the packages that are available for your OS.


## Enable Elasticsearch

In order to enable Elasticsearch you need to have access to the server that GitLab is hosted on, and an administrator account on your GitLab instance. Go to **Admin > Settings** and find the "Elasticsearch" section.

The following Elasticsearch settings are available:

| Parameter                           | Description |
| ---------                           | ----------- |
| `Elasticsearch indexing`            | Enables/disables Elasticsearch indexing. You may want to enable indexing but disable search in order to give the index time to be fully completed, for example. Also keep in mind that this option doesn't have any impact on existing data, this only enables/disables background indexer which tracks data changes. So by enabling this you will not get your existing data indexed, use special rake task for that as explained in [Add GitLab's data to the Elasticsearch index](#add-gitlabs-data-to-the-elasticsearch-index). |
| `Search with Elasticsearch enabled` | Enables/disables using Elasticsearch in search. |
| `Host`                              | The TCP/IP host to use for connecting to Elasticsearch. Use a comma-separated list to support clustering (e.g., "host1, host2"). |
| `Port`                              | The TCP port that Elasticsearch listens to. The default value is 9200  |



## Add GitLab's data to the Elasticsearch index

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
the `elastic_batch_project_indexer` queue , as this step can be I/O-intensive.

You can also run the initial indexing synchronously - this is most useful if
you have a small number of projects, or need finer-grained control over indexing
than Sidekiq permits:

```
# Omnibus installations
sudo gitlab-rake gitlab:elastic:index_repositories

# Installations from source
bundle exec rake gitlab:elastic:index_repositories RAILS_ENV=production
```
 It might take a while depending on how big your Git repositories are (see
[Indexing large repositories](#indexing-large-repositories)).

If you want to run several tasks in parallel (probably in separate terminal
windows) you can provide the `ID_FROM` and `ID_TO` parameters:

```
ID_FROM=1001 ID_TO=2000 sudo gitlab-rake gitlab:elastic:index_repositories
```

Where `ID_FROM` and `ID_TO` are project IDs. Both parameters are optional.
As an example, if you have 3,000 repositories and you want to run three separate indexing tasks, you might run:

```
ID_TO=1000 sudo gitlab-rake gitlab:elastic:index_repositories
ID_FROM=1001 ID_TO=2000 sudo gitlab-rake gitlab:elastic:index_repositories
ID_FROM=2001 sudo gitlab-rake gitlab:elastic:index_repositories
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
UPDATE_INDEX=true ID_TO=1000 sudo gitlab-rake gitlab:elastic:index_repositories
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

To index all database entities:

```
# Omnibus installations
sudo gitlab-rake gitlab:elastic:index_database

# Installations from source
bundle exec rake gitlab:elastic:index_database RAILS_ENV=production
```

If your instance is small enough you can index everything at once (database records, repositories, wikis):

```
# Omnibus installations
sudo gitlab-rake gitlab:elastic:index

# Installations from source
bundle exec rake gitlab:elastic:index RAILS_ENV=production
```


## Disable Elasticsearch

Disabling the Elasticsearch integration is as easy as unchecking `Search with Elasticsearch enabled` and `Elasticsearch indexing` in **Admin > Settings**.


## Special recommendations

Here are some tips to use Elasticsearch with GitLab more efficiently.


### Indexing large repositories

Indexing large Git repositories can take a while. To speed up the process, you
can temporarily disable auto-refreshing and replicating. In our experience you can expect a 20%
time drop.

1.  Disable refreshing:

    ```bash
    curl --request PUT localhost:9200/_settings --data '{
        "index" : {
            "refresh_interval" : "-1"
        } }'
    ```

1.  Disable replication and enable it after indexing:

    ```bash
    curl --request PUT localhost:9200/_settings --data '{
        "index" : {
            "number_of_replicas" : 0
        } }'
    ```

1. [Create the indexes](#add-gitlabs-data-to-the-elasticsearch-index)

1.  Enable replication again after
    the indexing is done and set it to its default value, which is 1:

    ```bash
    curl --request PUT localhost:9200/_settings --data '{
        "index" : {
            "number_of_replicas" : 1
        } }'
    ```

1.  Enable refreshing again (after indexing):

    ```bash
    curl --request PUT localhost:9200/_settings --data '{
        "index" : {
            "refresh_interval" : "1s"
        } }'
    ```

1.  A force merge should be called after enabling the refreshing above:

    ```bash
    curl --request POST 'http://localhost:9200/_forcemerge?max_num_segments=5'
    ```

To minimize downtime of the search feature we recommend the following:

1. Configure Elasticsearch in **Admin > Settings**, but do not enable it, just set a host and port.

1. Create empty indexes:

    ```
    # Omnibus installations
    sudo gitlab-rake gitlab:elastic:create_empty_index

    # Installations from source
    bundle exec rake gitlab:elastic:create_empty_index RAILS_ENV=production
    ```

1. Index all repositories using the `gitlab:elastic:index_repositories` Rake
   task (see above). You'll probably want to do this in parallel.

1. Enable Elasticsearch indexing.

1. Run indexers for database, wikis, and
   repositories (with the `UPDATE_INDEX=1` parameter). By running the repository indexer twice you will be sure that
   everything is indexed because some commits could be pushed while you
   performed the initial indexing. The repository indexer will skip
   repositories and commits that are already indexed, so it will be much
   shorter than the first run.


## Troubleshooting

### Exception "Can't specify parent if no parent field has been configured"

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

### Exception Elasticsearch::Transport::Transport::Errors::BadRequest

If you have this exception (just like in the case above but the actual message is different) please check if you have the correct Elasticsearch version and you met the other [requirements](#requirements).
There is also an easy way to check it automatically with `sudo gitlab-rake gitlab:check` command.

### I indexed all the repositories but I can't find anything

Make sure you indexed all the database data as stated above (`sudo gitlab-rake gitlab:elastic:index`)



[ee-109]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/109 "Elasticsearch Merge Request"
[elasticsearch]: https://www.elastic.co/products/elasticsearch "Elasticsearch website"
[install]: https://www.elastic.co/guide/en/elasticsearch/reference/current/_installation.html "Elasticsearch installation documentation"
[pkg]: https://about.gitlab.com/downloads/ "Download Omnibus GitLab"
[elastic-settings]: https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration.html#settings "Elasticsearch configuration settings"
