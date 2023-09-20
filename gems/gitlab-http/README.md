# Gitlab::HTTP_V2

This gem is used as a proxy for all outbounding http connection
coming from callbacks, services and hooks. The direct use of the HTTParty
is discouraged because it can lead to several security problems, like SSRF
calling internal IP or services.

## Usage

### Configuration

```ruby
Gitlab::HTTP_V2.configure do |config|
  config.allowed_internal_uris = []

  config.log_exception_proc = ->(exception, extra_info) do
    # operation
  end
  config.silent_mode_log_info_proc = ->(message, http_method) do
    # operation
  end
end
```

### Actions

Basic examples;

```ruby
Gitlab::HTTP_V2.post(uri, body: body)

Gitlab::HTTP_V2.try_get(uri, params)

response = Gitlab::HTTP_V2.head(project_url, verify: true)

Gitlab::HTTP_V2.post(path, base_uri: base_uri, **params)
```

## Development

After checking out the repo, run `bundle` to install dependencies.
Then, run `RACK_ENV=test bundle exec rspec spec` to run the tests.
