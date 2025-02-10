---
stage: Create
group: Source Code
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Workhorse configuration
---

For historical reasons, Workhorse uses:

- Command line flags.
- A configuration file.
- Environment variables.

Add any new Workhorse configuration options into the configuration file.

## CLI options

```plaintext
  gitlab-workhorse [OPTIONS]

Options:
  -apiCiLongPollingDuration duration
        Long polling duration for job requesting for runners (default 50ns)
  -apiLimit uint
        Number of API requests allowed at single time
  -apiQueueDuration duration
        Maximum queueing duration of requests (default 30s)
  -apiQueueLimit uint
        Number of API requests allowed to be queued
  -authBackend string
        Authentication/authorization backend (default "http://localhost:8080")
  -authSocket string
        Optional: Unix domain socket to dial authBackend at
  -cableBackend string
        ActionCable backend
  -cableSocket string
        Optional: Unix domain socket to dial cableBackend at
  -config string
        TOML file to load config from
  -developmentMode
        Allow the assets to be served from Rails app
  -documentRoot string
        Path to static files content (default "public")
  -listenAddr string
        Listen address for HTTP server (default "localhost:8181")
  -listenNetwork string
        Listen 'network' (tcp, tcp4, tcp6, unix) (default "tcp")
  -listenUmask int
        Umask for Unix socket
  -logFile string
        Log file location
  -logFormat string
        Log format to use defaults to text (text, json, structured, none) (default "text")
  -pprofListenAddr string
        pprof listening address, for example, 'localhost:6060'
  -prometheusListenAddr string
        Prometheus listening address, for example, 'localhost:9229'
  -propagateCorrelationID X-Request-ID
        Reuse existing Correlation-ID from the incoming request header X-Request-ID if present
  -proxyHeadersTimeout duration
        How long to wait for response headers when proxying the request (default 5m0s)
  -secretPath string
        File with secret key to authenticate with authBackend (default "./.gitlab_workhorse_secret")
  -version
        Print version and exit
```

The 'auth backend' refers to the GitLab Rails application. The name is
a holdover from when GitLab Workhorse only handled `git push` and `git pull` over
HTTP.

GitLab Workhorse can listen on either a TCP or a Unix domain socket. It
can also open a second listening TCP listening socket with the Go
[`net/http/pprof` profiler server](https://pkg.go.dev/net/http/pprof).

GitLab Workhorse can listen on Redis build and runner registration events if you
pass a valid TOML configuration file through the `-config` flag.
A regular setup it only requires the following (replacing the string
with the actual socket)

## Redis

GitLab Workhorse integrates with Redis to do long polling for CI build
requests. To configure it:

- Configure Redis settings in the TOML configuration file.
- Control polling behavior for CI build requests with the `-apiCiLongPollingDuration`
  command-line flag.

You can enable Redis in the configuration file while leaving CI polling
disabled. This configuration results in an idle Redis Pub/Sub connection. The
opposite is not possible: CI long polling requires a correct Redis configuration.

For example, the `[redis]` section in the configuration file could contain:

```plaintext
[redis]
URL = "unix:///var/run/gitlab/redis.sock"
Password = "my_awesome_password"
```

- `URL` - A string in the format `unix://path/to/redis.sock` or `redis://host:port`.
- `Password` - Required only if your Redis instance is password-protected.
- `Sentinel` - Required if you use Sentinel.

If both `Sentinel` and `URL` are given, only `Sentinel` is used.

Optional fields:

```plaintext
[redis]
DB = 0
MaxIdle = 1
MaxActive = 1
```

- `DB` - The database to connect to. Defaults to `0`.
- `MaxIdle` - How many idle connections can be in the Redis pool at once. Defaults to `1`.
- `MaxActive` - How many connections the pool can keep. Defaults to `1`.

## Relative URL support

If you mount GitLab at a relative URL, like `example.com/gitlab`), use this
relative URL in the `authBackend` setting:

```plaintext
gitlab-workhorse -authBackend http://localhost:8080/gitlab
```

## TLS support

A listener with TLS can be configured to be used for incoming requests.
Paths to the files containing a certificate and matching private key for the server must be provided:

```toml
[[listeners]]
network = "tcp"
addr = "localhost:3443"
[listeners.tls]
  certificate = "/path/to/certificate"
  key = "/path/to/private/key"
  min_version = "tls1.2"
  max_version = "tls1.3"
```

The `certificate` file should contain the concatenation
of the server's certificate, any intermediates, and the certificate authority's certificate.

Metrics endpoints can be configured similarly:

```toml
[metrics_listener]
network = "tcp"
addr = "localhost:9229"
[metrics_listener.tls]
  certificate = "/path/to/certificate"
  key = "/path/to/private/key"
  min_version = "tls1.2"
  max_version = "tls1.3"
```

## Sentinel support

```plaintext
[redis]
Sentinel = [ "redis://sentinel1:23456", "redis://sentinel2:23456" ]
SentinelMaster = "mymaster"
```

## Sentinel TLS support

```plaintext
[redis]
Sentinel = [ "rediss://sentinel1:23456", "rediss://sentinel2:23456" ]
SentinelMaster = "mymaster"
[Sentinel.tls]
  certificate = "/path/to/certificate"
  key = "/path/to/private/key"
  ca_certificate = "/path/to/ca_certificate" # optional
  min_version = "tls1.2"                     # optional
  max_version = "tls1.3"                     # optional
```

## Interaction of `authBackend` and `authSocket`

The interaction between `authBackend` and `authSocket` can be confusing.
If `authSocket` is set, it overrides the host portion of `authBackend`, but not
the relative path.

In table form:

| `authBackend`                  | `authSocket`      | Workhorse connects to | Rails relative URL |
|--------------------------------|-------------------|-----------------------|--------------------|
| unset                          | unset             | `localhost:8080`      | `/`                |
| `http://localhost:3000`        | unset             | `localhost:3000`      | `/`                |
| `http://localhost:3000/gitlab` | unset             | `localhost:3000`      | `/gitlab`          |
| unset                          | `/path/to/socket` | `/path/to/socket`     | `/`                |
| `http://localhost:3000`        | `/path/to/socket` | `/path/to/socket`     | `/`                |
| `http://localhost:3000/gitlab` | `/path/to/socket` | `/path/to/socket`     | `/gitlab`          |

The same applies to `cableBackend` and `cableSocket`.

## Metadata options

Include the following options in the `[metadata]` section:

| Setting                  | Type  | Default value     | Description                                                                                                                                      |
| ------------------------ | ----- | ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `zip_reader_limit_bytes` | bytes | 104857600 (100 MB) | The optional number of bytes to limit the zip reader to. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/439016) in GitLab 16.9. |

For example:

```toml
[metadata]
zip_reader_limit_bytes = 209715200 # 200 MB
```

## Error tracking

GitLab-Workhorse supports remote error tracking with [Sentry](https://sentry.io).
To enable this feature, set the `GITLAB_WORKHORSE_SENTRY_DSN` environment variable.
You can also set the `GITLAB_WORKHORSE_SENTRY_ENVIRONMENT` environment variable to
use the Sentry environment feature to separate staging, production and
development.

::Tabs

:::TabTitle Linux package (Omnibus)

```ruby
gitlab_workhorse['env'] = {
    'GITLAB_WORKHORSE_SENTRY_DSN' => 'https://foobar'
    'GITLAB_WORKHORSE_SENTRY_ENVIRONMENT' => 'production'
}
```

:::TabTitle Self-compiled (source)

```plaintext
export GITLAB_WORKHORSE_SENTRY_DSN='https://foobar'
export GITLAB_WORKHORSE_SENTRY_ENVIRONMENT='production'
```

::EndTabs

## Distributed tracing

Workhorse supports distributed tracing through [LabKit](https://gitlab.com/gitlab-org/labkit/)
using [OpenTracing APIs](https://opentracing.io).

By default, no tracing implementation is linked into the binary. You can link in
different OpenTracing providers with [build tags](https://pkg.go.dev/go/build#hdr-Build_Constraints)
or build constraints by setting the `BUILD_TAGS` make variable.

For more details of the supported providers, refer to LabKit. For an example of
Jaeger tracing support, include the tags: `BUILD_TAGS="tracer_static tracer_static_jaeger"` like this:

```shell
make BUILD_TAGS="tracer_static tracer_static_jaeger"
```

After you compile Workhorse with an OpenTracing provider, configure the tracing
configuration with the `GITLAB_TRACING` environment variable, like this:

```shell
GITLAB_TRACING=opentracing://jaeger ./gitlab-workhorse
```

### Propagate correlation IDs

When a user makes an HTTP request, such as creating a new project, the
initial request is routed through Workhorse to another service, which
may in turn, make other requests. To help trace the request as it flows
across services, Workhorse generates a random value called a
[correlation ID](../../administration/logs/tracing_correlation_id.md).
Workhorse sends this correlation ID with the `X-Request-Id` HTTP header.

Some GitLab services, such as GitLab Shell, generate their own
correlation IDs. In addition, other services, such as Gitaly, make
internal API calls that pass along a correlation ID from the original
request. In either case, the correlation ID is also passed with the
`X-Request-Id` HTTP header.

By default, Workhorse ignores this header and always generates a new
correlation ID. This makes debugging harder and prevents distributed
tracing from working properly, because the new correlation ID is
completely unrelated to the original one.

Workhorse can be configured to propagate an incoming correlation ID with
the `-propagateCorrelationID` command-line flag. It is highly
recommended that this option be used with an IP allow list to ensure
arbitrary values cannot be generated by untrusted clients.

An IP allow list is specified with the `trusted_cidrs_for_propagation`
option in the Workhorse configuration file. Specify a list of CIDR blocks
that can be trusted. For example:

```toml
trusted_cidrs_for_propagation = ["10.0.0.0/8", "127.0.0.1/32"]
```

NOTE:
The `-propagateCorrelationID` flag must be used for the `trusted_cidrs_for_propagation` option to work.

### Trusted proxies

If Workhorse is behind a reverse proxy such as NGINX, the
`trusted_cidrs_for_x_forwarded_for` option is needed to specify which
CIDR blocks can be used to trust to provide the originating IP address
with the `X-Forwarded-For` HTTP header. For example:

```toml
trusted_cidrs_for_x_forwarded_for = ["10.0.0.0/8", "127.0.0.1/32"]
```

## Continuous profiling

Workhorse supports continuous profiling through [LabKit](https://gitlab.com/gitlab-org/labkit/)
using [Stackdriver Profiler](https://cloud.google.com/products/operations). By default, the
Stackdriver Profiler implementation is linked in the binary using
[build tags](https://pkg.go.dev/go/build#hdr-Build_Constraints), though it's not
required and can be skipped. For example:

```shell
make BUILD_TAGS=""
```

After you compile Workhorse with continuous profiling, set the profiler configuration
with the `GITLAB_CONTINUOUS_PROFILING` environment variable. For example:

```shell
GITLAB_CONTINUOUS_PROFILING="stackdriver?service=workhorse&service_version=1.0.1&project_id=test-123 ./gitlab-workhorse"
```

## Related topics

- [LabKit monitoring documentation](https://gitlab.com/gitlab-org/labkit/-/blob/master/monitoring/doc.go)
