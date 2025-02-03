# Getting started

## Configuration

Add an initializer with the following options:

1. `enabled`: `true|false`. Defaults to `false`
1. `databases`: Hash containing database configuration options
1. `indexing_enabled`: `true|false`. Defaults to `false`
1. `re_enqueue_indexing_workers`: `true|false`. Defaults to `false`
1. `logger`: Logger. Defaults to `Logger.new($stdout)`

For example:

```ruby
ActiveContext.configure do |config|
  config.enabled = true
  config.logger = ::Gitlab::Elasticsearch::Logger.build

  config.databases = {
    es1: {
      adapter: 'ActiveContext::Databases::Elasticsearch::Adapter',
      prefix: 'gitlab_active_context',
      options: ::Gitlab::CurrentSettings.elasticsearch_config
    }
  }
end
```

### Elasticsearch/OpenSearch Configuration Options

| Option | Description | Required | Default | Example |
|--------|-------------|----------|---------|---------|
| `url` | The URL of the Elasticsearch server | Yes | N/A | `'http://localhost:9200'` |
| `prefix` | The prefix for Elasticsearch indices | No | `'gitlab_active_context'` | `'my_custom_prefix'` |
| `client_request_timeout` | The timeout for client requests in seconds | No | N/A | `60` |
| `retry_on_failure` | The number of times to retry a failed request | No | `0` (no retries) | `3` |
| `debug` | Enable or disable debug logging | No | `false` | `true` |
| `max_bulk_size_bytes` | Maximum size before forcing a bulk operation in megabytes | No | `10.megabytes` | `5242880` | 
