# Elasticsearch integration

_**Note:** This feature was [introduced][ee-109] in GitLab EE 8.4._

---

[Elasticsearch] is a flexible, scalable and powerful search service.

If you want to keep GitLab's search fast when dealing with huge amount of data,
you should consider [enabling Elasticsearch](#enable-elasticsearch).

GitLab leverages the search capabilities of Elasticsearch and enables it when
searching in:

- GitLab application
- issues
- merge requests
- milestones
- notes
- projects
- repositories
- snippets
- wiki repositories

Once the data is added to the database or repository, search indexes will be updated
automatically. Elasticsearch can be installed on the same machine that GitLab
is installed or on a separate server.

## Requirements

These are the minimum requirements needed for Elasticsearch to work:

- GitLab 8.4+
- Elasticsearch 2.0+ (with [Delete By Query Plugin](https://www.elastic.co/guide/en/elasticsearch/plugins/2.0/plugins-delete-by-query.html) installed)

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
| `Elasticsearch indexing`            | Enables/disables Elasticsearch indexing. You may want to enable indexing but disable search in order to give the index time to be fully completed, for example. |
| `Search with Elasticsearch enabled` | Enables/disables using Elasticsearch in search. |
| `Host`                              | The TCP/IP host to use for connecting to Elasticsearch. Use a comma-separated list to support clustering (e.g., "host1, host2"). |
| `Port`                              | The TCP port that Elasticsearch listens to. The default value is 9200  |


## Add GitLab's data to the Elasticsearch index

Configure Elasticsearch's host and port in **Admin > Settings**. Then create empty indexes using one of the following commands:


    ```
    # Omnibus installations
    sudo gitlab-rake gitlab:elastic:create_empty_indexes

    # Installations from source
    bundle exec rake gitlab:elastic:create_empty_indexes
    ```



Then enable Elasticsearch indexing and run indexing tasks. It might take a while depending on how big your Git repositories are (see
[Indexing large repositories](#indexing-large-repositories)).

---

To index all your repositories:

```
# Omnibus installations
sudo gitlab-rake gitlab:elastic:index_repositories

# Installations from source
bundle exec rake gitlab:elastic:index_repositories RAILS_ENV=production
```

If you want to run several tasks in parallel (probably in separate terminal
windows) you can provide the `ID_FROM` and `ID_TO` parameters:

```
ID_FROM=1001 ID_TO=2000 sudo gitlab-rake gitlab:elastic:index_repositories

```

Both parameters are optional. Keep in mind that this task will skip repositories
(and certain commits) that have already been indexed. It stores the last commit
SHA of every indexed repository in the database. As an example, if you have
3,000 repositories and you want to run three separate indexing tasks, you might
run:

```
ID_TO=1000 sudo gitlab-rake gitlab:elastic:index_repositories
ID_FROM=1001 ID_TO=2000 sudo gitlab-rake gitlab:elastic:index_repositories
ID_FROM=2001 sudo gitlab-rake gitlab:elastic:index_repositories
```

If you need to update any outdated indexes, you can use
the `UPDATE_INDEX` parameter:

```
UPDATE_INDEX=true ID_TO=1000 sudo gitlab-rake gitlab:elastic:index_repositories
```

Keep in mind that it will scan all repositories to make sure that last commit is already indexed.

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

Or everything at once (database records, repositories, wikis):

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
can temporarily disable auto-refreshing. In our experience you can expect a 20%
time drop.

1.  Disable refreshing:

    ```bash
    curl -XPUT localhost:9200/_settings -d '{
        "index" : {
            "refresh_interval" : "-1"
        } }'
    ```

1.  (optional) You may want to disable replication and enable it after indexing:

    ```bash
    curl -XPUT localhost:9200/_settings -d '{
        "index" : {
            "number_of_replicas" : 0
        } }'
    ```

1. [Create the indexes](#add-gitlabs-data-to-the-elasticsearch-index)

1.  (optional) If you disabled replication in step 2, enable it after
    the indexing is done and set it to its default value, which is 1:

    ```bash
    curl -XPUT localhost:9200/_settings -d '{
        "index" : {
            "number_of_replicas" : 1
        } }'
    ```

1.  Enable refreshing again (after indexing):

    ```bash
    curl -XPUT localhost:9200/_settings -d '{
        "index" : {
            "refresh_interval" : "1s"
        } }'
    ```

1.  A force merge should be called after enabling the refreshing above:

    ```bash
    curl -XPOST 'http://localhost:9200/_forcemerge?max_num_segments=5'
    ```

To minimize downtime of the search feature we recommend the following:

1. Configure Elasticsearch in **Admin > Settings**, but do not enable it, just set a host and port.

1. Create empty indexes:

    ```
    # Omnibus installations
    sudo gitlab-rake gitlab:elastic:create_empty_indexes

    # Installations from source
    bundle exec rake gitlab:elastic:create_empty_indexes
    ```

1. Index all repositories using the `gitlab:elastic:index_repositories` Rake
   task (see above). You'll probably want to do this in parallel.

1. Enable Elasticsearch indexing.

1. Run indexers for database (with the `UPDATE_INDEX=1` parameter), wikis, and
   repositories. By running  the repository indexer twice you will be sure that
   everything is indexed because some commits could be pushed while you
   performed the initial indexing. The repository indexer will skip
   repositories and commits that are already indexed, so it will be much
   shorter than the first run.

[ee-109]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/109 "Elasticsearch Merge Request"
[elasticsearch]: https://www.elastic.co/products/elasticsearch "Elasticsearch website"
[install]: https://www.elastic.co/guide/en/elasticsearch/reference/current/_installation.html "Elasticsearch installation documentation"
[pkg]: https://about.gitlab.com/downloads/ "Download Omnibus GitLab"
[elastic-settings]: https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration.html#settings "Elasticsearch configuration settings"
