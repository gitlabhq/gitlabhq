---
stage: Foundations
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Troubleshooting Elasticsearch access
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

When working with Elasticsearch access, you might encounter the following issues.

## Set configurations in the Rails console

See [Starting a Rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session).

### List attributes

To list all available attributes:

1. Open the Rails console (`sudo gitlab-rails console`).
1. Run the following command:

```ruby
ApplicationSetting.last.attributes
```

The output contains all the settings available in [Elasticsearch integration](../../advanced_search/elasticsearch.md), such as `elasticsearch_indexing`, `elasticsearch_url`, `elasticsearch_replicas`, and `elasticsearch_pause_indexing`.

### Set attributes

To set an Elasticsearch integration setting, run a command like:

```ruby
ApplicationSetting.last.update(elasticsearch_url: '<your ES URL and port>')

#or

ApplicationSetting.last.update(elasticsearch_indexing: false)
```

### Get attributes

To check if the settings have been set in [Elasticsearch integration](../../advanced_search/elasticsearch.md) or in the Rails console, run a command like:

```ruby
Gitlab::CurrentSettings.elasticsearch_url

#or

Gitlab::CurrentSettings.elasticsearch_indexing
```

### Change the password

To change the Elasticsearch password, run the following commands:

```ruby
es_url = Gitlab::CurrentSettings.current_application_settings

# Confirm the current Elasticsearch URL
es_url.elasticsearch_url

# Set the Elasticsearch URL
es_url.elasticsearch_url = "http://<username>:<password>@your.es.host:<port>"

# Save the change
es_url.save!
```

## View logs

One of the most valuable tools for identifying issues with the Elasticsearch
integration are logs. The most relevant logs for this integration are:

1. [`sidekiq.log`](../../../administration/logs/_index.md#sidekiqlog) - All of the
   indexing happens in Sidekiq, so much of the relevant logs for the
   Elasticsearch integration can be found in this file.
1. [`elasticsearch.log`](../../../administration/logs/_index.md#elasticsearchlog) - There
   are additional logs specific to Elasticsearch that are sent to this file
   that might contain diagnostic information about searching,
   indexing, or migrations.

Here are some common pitfalls and how to overcome them.

## Verify that your GitLab instance is using Elasticsearch

To verify that your GitLab instance is using Elasticsearch:

- When you perform a search, in the upper-right corner of the search results page,
  ensure **Advanced search is enabled** is displayed.

- In the **Admin** area, under **Settings > Search**, check that the
  advanced search settings are selected.

  Those same settings there can be obtained from the Rails console if necessary:

  ```ruby
  ::Gitlab::CurrentSettings.elasticsearch_search?         # Whether or not searches will use Elasticsearch
  ::Gitlab::CurrentSettings.elasticsearch_indexing?       # Whether or not content will be indexed in Elasticsearch
  ::Gitlab::CurrentSettings.elasticsearch_limit_indexing? # Whether or not Elasticsearch is limited only to certain projects/namespaces
  ```

- Confirm searches use Elasticsearch by accessing the
  [Rails console](../../../administration/operations/rails_console.md) and running the following
  commands:

  ```rails
  u = User.find_by_email('email_of_user_doing_search')
  s = SearchService.new(u, {:search => 'search_term'})
  pp s.search_objects.class
  ```

  The output from the last command is the key here. If it shows:

  - `ActiveRecord::Relation`, **it is not** using Elasticsearch.
  - `Kaminari::PaginatableArray`, **it is** using Elasticsearch.

- If Elasticsearch is limited to specific namespaces and you need to know if
  Elasticsearch is being used for a specific project or namespace, you can use
  the Rails console:

  ```ruby
  ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: Namespace.find_by_full_path("/my-namespace"))
  ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: Project.find_by_full_path("/my-namespace/my-project"))
  ```

## Error: `User: anonymous is not authorized to perform: es:ESHttpGet`

When using a domain level access policy with AWS OpenSearch or Elasticsearch, the AWS role is not assigned to the
correct GitLab nodes. The GitLab Rails and Sidekiq nodes require permission to communicate with the search cluster.

```plaintext
User: anonymous is not authorized to perform: es:ESHttpGet because no resource-based policy allows the es:ESHttpGet
action
```

To fix this, ensure the AWS role is assigned to the correct GitLab nodes.

## No valid region specified

When using AWS authorization with advanced search, the region you specify must be valid.

## Error: `no permissions for [indices:data/write/bulk]`

When using fine-grained access control with an IAM role or a role created using AWS OpenSearch Dashboards, you might
encounter the following error:

```json
{
  "error": {
    "root_cause": [
      {
        "type": "security_exception",
        "reason": "no permissions for [indices:data/write/bulk] and User [name=arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE, backend_roles=[arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE], requestedTenant=null]"
      }
    ],
    "type": "security_exception",
    "reason": "no permissions for [indices:data/write/bulk] and User [name=arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE, backend_roles=[arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE], requestedTenant=null]"
  },
  "status": 403
}
```

To fix this, you need
to [map the roles to users](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-mapping)
in the AWS OpenSearch Dashboards.

## Create additional master users in AWS OpenSearch Service

You can set a master user when you create a domain.
With this user, you can create additional master users.
For more information, see the
[AWS documentation](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-more-masters).

To create users and roles with permissions and map users to roles,
see the [OpenSearch documentation](https://opensearch.org/docs/latest/security/access-control/users-roles/).
You must include the following permissions in the role:

```json
{
  "cluster_permissions": [
    "cluster_composite_ops",
    "cluster_monitor"
  ],
  "index_permissions": [
    {
      "index_patterns": [
        "gitlab*"
      ],
      "allowed_actions": [
        "data_access",
        "manage_aliases",
        "search",
        "create_index",
        "delete",
        "manage"
      ]
    },
    {
      "index_patterns": [
        "*"
      ],
      "allowed_actions": [
        "indices:admin/aliases/get",
        "indices:monitor/stats"
      ]
    }
  ]
}
```
