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
gitlab_rails['elasticsearch'] = [
  {
    "enabled" => "true",
    "host" => "localhost",
    "port" => 9200
  }
]
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

It might take a while depending on how big your Git repositories are.

---

To index all your repositories:

```
# omnibus installations
sudo gitlab-rake gitlab:elastic:index_repositories

# installations from source
bundle exec rake gitlab:elastic:index_repositories RAILS_ENV=production
```

To index all wikis:

```
# omnibus installations
sudo gitlab-rake gitlab:elastic:index_wikis

# installations from source
bundle exec rake gitlab:elastic:index_wikis RAILS_ENV=production
```

To index all database entities:

```
# omnibus installations
sudo gitlab-rake gitlab:elastic:index_database

# installations from source
bundle exec rake gitlab:elastic:index_database RAILS_ENV=production
```

## Disable Elasticsearch

Disabling the Elasticsearch integration is as easy as setting `enabled` to
`false` in your GitLab settings. See [Enable Elasticsearch](#enable-elasticsearch)
to find where those settings are and don't forget to reconfigure/restart GitLab
for the changes to take effect.


[ee-109]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/109 "Elasticsearch Merge Request"
[elasticsearch]: https://www.elastic.co/products/elasticsearch "Elasticsearch website"
[install]: https://www.elastic.co/guide/en/elasticsearch/reference/current/_installation.html "Elasticsearch installation documentation"
[pkg]: https://about.gitlab.com/downloads/ "Download Omnibus GitLab"
[elastic-settings]: https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-configuration.html#settings "Elasticsearch configuration settings"
