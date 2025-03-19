# Getting started

## Configuration

Add an initializer with the following options:

1. `enabled`: `true|false`. Defaults to `false`
1. `indexing_enabled`: `true|false`. Defaults to `false`
1. `re_enqueue_indexing_workers`: `true|false`. Defaults to `false`
1. `logger`: Logger. Defaults to `Logger.new($stdout)`

For example:

```ruby
ActiveContext.configure do |config|
  config.enabled = true
  config.indexing_enabled = true
  config.logger = ::Gitlab::Elasticsearch::Logger.build
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
  options: ::Gitlab::CurrentSettings.elasticsearch_config
)
```

### Use OpenSearch settings from Advanced Search

```ruby
Ai::ActiveContext::Connection.create!(
  name: "opensearch",
  adapter_class: "ActiveContext::Databases::Opensearch::Adapter",
  options: ::Gitlab::CurrentSettings.elasticsearch_config
)
```

## Activate a connection

To make a connection active and deactivate the existing active connection if it is set:

```ruby
connection.activate!
```
