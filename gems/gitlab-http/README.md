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

Basic examples:

```ruby
Gitlab::HTTP_V2.post(uri, body: body)

Gitlab::HTTP_V2.try_get(uri, params)

response = Gitlab::HTTP_V2.head(project_url, verify: true) # returns an HTTParty::Response object

Gitlab::HTTP_V2.post(path, base_uri: base_uri, **params) # returns an HTTParty::Response object
```

Async usage examples:

```ruby
lazy_response = Gitlab::HTTP_V2.get(location, async: true)

lazy_response.execute # starts the request and returns the same LazyResponse object
lazy_response.wait # waits for the request to finish and returns the same LazyResponse object

response = lazy_response.value # returns an HTTParty::Response object
```

## Security

This gem provides several security protections for outbound HTTP requests:

### SSRF Protection

URLs are validated to prevent Server-Side Request Forgery (SSRF) attacks. Requests to internal networks, localhost, and other restricted addresses are blocked by default.

### Header Injection Protection

HTTP headers are validated to prevent CRLF injection attacks. Headers containing control characters (`\r`, `\n`, `\0`) will raise a `HeaderInjectionError`. This prevents HTTP request smuggling/splitting attacks.

```ruby
# This will raise Gitlab::HTTP_V2::HeaderInjectionError
Gitlab::HTTP_V2.get(uri, headers: { 'X-Custom' => "value\r\nX-Injected: attack" })
```

### Response Size Limits

Use the `max_bytes` option to limit response sizes and prevent memory exhaustion.

```ruby
Gitlab::HTTP_V2.get(uri, max_bytes: 1.megabyte)
```

## Development

After checking out the repo, run `bundle` to install dependencies.
Then, run `RACK_ENV=test bundle exec rspec spec` to run the tests.
