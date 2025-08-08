# Getting started

## Unit Primitives

See [glossary](../../../doc/development/ai_features/glossary.md#unit-primitive) for what a unit primitive is.

Consider creating separate unit primitives (e.g., `semantic_search_code`, `semantic_search_issue`, `semantic_search_documentation`) when:

- Different features will exist in different product tiers
- You need different entitlements for different search types
- You plan to package sub-features separately
- You require more granular end-user permissions
- You need to track usage separately for billing purposes

Use a single unit primitive (e.g., `semantic_search`) when:

- All features share the same entitlement level
- There's no need for tier-specific access control
- You want to reduce implementation complexity
- The feature is still in flux or experimental

Keep in mind that splitting or adding primitives increases implementation effort. See [documentation](../../../doc/development/cloud_connector/configuration.md).

Follow the [Cloud Connector guidance for adding a new feature](https://docs.gitlab.com/development/cloud_connector/#register-new-feature-for-gitlab-self-managed-dedicated-and-gitlabcom-customers).

## Configuration

Add an initializer with the following options:

1. `enabled`: `true|false`. Defaults to `false`
1. `indexing_enabled`: `true|false`. Defaults to `false`
1. `re_enqueue_indexing_workers`: `true|false`. Defaults to `false`
1. `logger`: Logger. Defaults to `Logger.new($stdout)`
1. `queue_classes`: Array of queue classes that include the `ActiveContext::Concerns::Queue` concern. Defaults to []

For example:

```ruby
ActiveContext.configure do |config|
  config.enabled = true
  config.indexing_enabled = true
  config.logger = ::Gitlab::Elasticsearch::Logger.build
  config.queue_classes = [::Ai::ActiveContext::Queues::Code]
end
```

## Create a connection

Create a `Ai::ActiveContext::Connection` record in the database with the following fields:

- `name`: Useful name
- `adapter_class`: One of
  - `ActiveContext::Databases::Elasticsearch::Adapter`
  - `ActiveContext::Databases::Opensearch::Adapter`
  - `ActiveContext::Databases::Postgres::Adapter`
- `options`: Connection options
  - For Elasticsearch: `url`, `client_request_timeout`, `retry_on_failure`, `log`, `debug`
  - For OpenSearch: `url`, `aws`, `aws_region`, `aws_access_key`, `aws_secret_access_key`, `client_request_timeout`, `retry_on_failure`, `log`, `debug`
  - For Postgres: `port`, `host`, `username`, `password`

### Use Elasticsearch settings from Advanced Search

```ruby
Ai::ActiveContext::Connection.create!(
  name: "elastic",
  adapter_class: "ActiveContext::Databases::Elasticsearch::Adapter",
  options: { use_advanced_search_config: true }
)
```

### Use OpenSearch settings from Advanced Search

```ruby
Ai::ActiveContext::Connection.create!(
  name: "opensearch",
  adapter_class: "ActiveContext::Databases::Opensearch::Adapter",
  options: { use_advanced_search_config: true }
)
```

## Activate a connection

To make a connection active and deactivate the existing active connection if it is set:

```ruby
connection.activate!
```
