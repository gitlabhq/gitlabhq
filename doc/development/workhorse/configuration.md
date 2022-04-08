---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Workhorse configuration

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
      Optional: ActionCable backend (default authBackend)
  -cableSocket string
      Optional: Unix domain socket to dial cableBackend at (default authSocket)
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
      pprof listening address, e.g. 'localhost:6060'
  -prometheusListenAddr string
      Prometheus listening address, e.g. 'localhost:9229'
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
[`net/http/pprof` profiler server](http://golang.org/pkg/net/http/pprof/).

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
Sentinel = [ "tcp://sentinel1:23456", "tcp://sentinel2:23456" ]
SentinelMaster = "mymaster"
```

- `URL` - A string in the format `unix://path/to/redis.sock` or `tcp://host:port`.
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

## Interaction of authBackend and authSocket

The interaction between `authBackend` and `authSocket` can be confusing.
If `authSocket` is set, it overrides the host portion of `authBackend`, but not
the relative path.

In table form:

| authBackend                    | authSocket        | Workhorse connects to | Rails relative URL |
|--------------------------------|-------------------|-----------------------|--------------------|
| unset                          | unset             | `localhost:8080`      | `/`                |
| `http://localhost:3000`        | unset             | `localhost:3000`      | `/`                |
| `http://localhost:3000/gitlab` | unset             | `localhost:3000`      | `/gitlab`          |
| unset                          | `/path/to/socket` | `/path/to/socket`     | `/`                |
| `http://localhost:3000`        | `/path/to/socket` | `/path/to/socket`     | `/`                |
| `http://localhost:3000/gitlab` | `/path/to/socket` | `/path/to/socket`     | `/gitlab`          |

The same applies to `cableBackend` and `cableSocket`.

## Error tracking

GitLab-Workhorse supports remote error tracking with [Sentry](https://sentry.io).
To enable this feature, set the `GITLAB_WORKHORSE_SENTRY_DSN` environment variable.
You can also set the `GITLAB_WORKHORSE_SENTRY_ENVIRONMENT` environment variable to
use the Sentry environment feature to separate staging, production and
development.

Omnibus GitLab (`/etc/gitlab/gitlab.rb`):

```ruby
gitlab_workhorse['env'] = {
    'GITLAB_WORKHORSE_SENTRY_DSN' => 'https://foobar'
    'GITLAB_WORKHORSE_SENTRY_ENVIRONMENT' => 'production'
}
```

Source installations (`/etc/default/gitlab`):

```plaintext
export GITLAB_WORKHORSE_SENTRY_DSN='https://foobar'
export GITLAB_WORKHORSE_SENTRY_ENVIRONMENT='production'
```

## Distributed tracing

Workhorse supports distributed tracing through [LabKit](https://gitlab.com/gitlab-org/labkit/)
using [OpenTracing APIs](https://opentracing.io).

By default, no tracing implementation is linked into the binary. You can link in
different OpenTracing providers with [build tags](https://golang.org/pkg/go/build/#hdr-Build_Constraints)
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

## Continuous profiling

Workhorse supports continuous profiling through [LabKit](https://gitlab.com/gitlab-org/labkit/)
using [Stackdriver Profiler](https://cloud.google.com/profiler). By default, the
Stackdriver Profiler implementation is linked in the binary using
[build tags](https://golang.org/pkg/go/build/#hdr-Build_Constraints), though it's not
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

- [LabKit monitoring documentation](https://gitlab.com/gitlab-org/labkit/-/blob/master/monitoring/doc.go).
