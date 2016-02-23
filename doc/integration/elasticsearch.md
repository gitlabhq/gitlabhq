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

Once the data is added to the database, search indexes will be updated
automatically. Elasticsearch can be installed on the same machine that GitLab
is installed or on a separate server.

## Requirements

These are the minimum requirements needed for Elasticsearch to work:

- GitLab 8.4+
- Elasticsearch 2.0+

## Install Elasticsearch

Providing detailed information on installing Elasticsearch is out of the scope
of this document.

You can follow the steps as described in the [official web site][install] or
use the packages that are available for your OS.

## Enable Elasticsearch

In order to enable Elasticsearch you need to have access to the server that
GitLab is hosted on.

The following three parameters are needed to enable Elasticsearch:

| Parameter | Description |
| --------- | ----------- |
| `enabled` | Enables/disables the Elasticsearch integration. Can be either `true` or `false` |
| `host`    | The host where Elasticsearch is installed on. Can be either an IP or a domain name which correctly resolves to an IP. It can be changed in the [Elasticsearch configuration settings][elastic-settings]. The default value is `localhost` |
| `port`    | The TCP port that Elasticsearch listens to. It can be changed in the [Elasticsearch configuration settings][elastic-settings]. The default value is `9200`  |

### Enable Elasticsearch in Omnibus installations

If you have used one of the [Omnibus packages][pkg] to install GitLab, all
you have to do is edit `/etc/gitlab/gitlab.rb` and add the following lines:

```ruby
gitlab_rails['elasticsearch_enabled'] = true
gitlab_rails['elasticsearch_host'] = "localhost"
gitlab_rails['elasticsearch_port'] = 9200
```

Replace the values as you see fit according to the
[settings table above](#enable-elasticsearch).

Save the file and reconfigure GitLab for the changes to take effect:
`sudo gitlab-ctl reconfigure`.

As a last step, move on to
[add GitLab's data to the Elasticsearch index](#add-gitlabs-data-to-the-elasticsearch-index).

### Enable Elasticsearch in source installations

If you have installed GitLab from source, edit `/home/git/gitlab/config/gitlab.yml`:

```yaml
elasticsearch:
  enabled: true
  host: localhost
  port: 9200
```

Replace the values as you see fit according to the
[settings table above](#enable-elasticsearch).

Save the file and restart GitLab for the changes to take effect:
`sudo service gitlab restart`.

As a last step, move on to
[add GitLab's data to the Elasticsearch index](#add-gitlabs-data-to-the-elasticsearch-index).

## Add GitLab's data to the Elasticsearch index

After [enabling Elasticsearch](#enable-elasticsearch), you must run the
following rake tasks to add GitLab's data to the Elasticsearch index.

It might take a while depending on how big your Git repositories are (see
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

If you want to update outdated indexes you can add parameter `UPDATE_INDEX`:

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

## Disable Elasticsearch

Disabling the Elasticsearch integration is as easy as setting `enabled` to
`false` in your GitLab settings. See [Enable Elasticsearch](#enable-elasticsearch)
to find where those settings are and don't forget to reconfigure/restart GitLab
for the changes to take effect.

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

1. Configure Elasticsearch in `gitlab.yml`, or `gitlab.rb` for Omnibus
   installations, but do not enable it, just set a host and port.

1. Create empty indexes:

    ```
    # Omnibus installations
    sudo gitlab-rake gitlab:elastic:create_empty_indexes

    # Installations from source
    bundle exec rake gitlab:elastic:create_empty_indexes
    ```

1. Index all repositories using the `gitlab:elastic:index_repositories` Rake
   task (see above). You'll probably want to do this in parallel.

1. Enable Elasticsearch and restart GitLab.

1. Run indexers for database, wikis, and repositories. By running the repository
   indexer twice you will be sure that everything is indexed because some
   commits could be pushed while you performed initial indexing. The repository
   indexer will skip repositories and commits that are already indexed, so it
   will be much shorter than the first run.

[ee-109]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/109 "Elasticsearch Merge Request"
[elasticsearch]: https://www.elastic.co/products/elasticsearch "Elasticsearch website"
[install]: https://www.elastic.co/guide/en/elasticsearch/reference/current/_installation.html "Elasticsearch installation documentation"
[pkg]: https://about.gitlab.com/downloads/ "Download Omnibus GitLab"
[elastic-settings]: https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration.html#settings "Elasticsearch configuration settings"
