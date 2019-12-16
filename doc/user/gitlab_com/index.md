# GitLab.com settings

In this page you will find information about the settings that are used on
[GitLab.com](https://about.gitlab.com/pricing/).

## SSH host keys fingerprints

Below are the fingerprints for GitLab.com's SSH host keys.

| Algorithm | MD5 | SHA256  |
| --------- | --- | ------- |
|  DSA      | `7a:47:81:3a:ee:89:89:64:33:ca:44:52:3d:30:d4:87` | `p8vZBUOR0XQz6sYiaWSMLmh0t9i8srqYKool/Xfdfqw` |
|  ECDSA    | `f1:d0:fb:46:73:7a:70:92:5a:ab:5d:ef:43:e2:1c:35` | `HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw` |
|  ED25519  | `2e:65:6a:c8:cf:bf:b2:8b:9a:bd:6d:9f:11:5c:12:16` | `eUXGGm1YGsMAS7vkcx6JOJdOGHPem5gQp4taiCfCLB8` |
|  RSA      | `b6:03:0e:39:97:9e:d0:e7:24:ce:a3:77:3e:01:42:09` | `ROQFvPThGrW4RuWLoL9tq9I9zJ42fK4XywyRtbOz/EQ` |

## SSH `known_hosts` entries

Add the following to `.ssh/known_hosts` to skip manual fingerprint
confirmation in SSH:

```
gitlab.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf
gitlab.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsj2bNKTBSpIYDEGk9KxsGh3mySTRgMtXL583qmBpzeQ+jqCMRgBqB98u3z++J1sKlXHWfM9dyhSevkMwSbhoR8XIq/U0tCNyokEi/ueaBMCvbcTHhO7FcwzY92WK4Yt0aGROY5qX2UKSeOvuP4D6TPqKF1onrSzH9bx9XUf2lEdWT/ia1NEKjunUqu1xOB/StKDHMoX4/OKyIzuS0q/T1zOATthvasJFoPrAjkohTyaDUz2LN5JoH839hViyEG82yB+MjcFV5MU3N1l1QL3cVUCh93xSaua1N85qivl+siMkPGbO5xR/En4iEY6K2XPASUEMaieWVNTRCtJ4S8H+9
gitlab.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFSMqzJeV9rUzU4kWitGjeR4PWSa29SPqJ1fVkhtj3Hw9xjLVXVYrU9QlYWrOLXBpQ6KWjbjTDTdDkoohFzgbEY=
```

## Mail configuration

GitLab.com sends emails from the `mg.gitlab.com` domain via [Mailgun] and has
its own dedicated IP address (`198.61.254.240`).

## Alternative SSH port

GitLab.com can be reached via a [different SSH port][altssh] for `git+ssh`.

| Setting     | Value               |
| ---------   | ------------------- |
| `Hostname`  | `altssh.gitlab.com` |
| `Port`      | `443`               |

An example `~/.ssh/config` is the following:

```
Host gitlab.com
  Hostname altssh.gitlab.com
  User git
  Port 443
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/gitlab
```

## GitLab Pages

Below are the settings for [GitLab Pages](https://about.gitlab.com/product/pages/).

| Setting                     | GitLab.com        | Default       |
| --------------------------- | ----------------  | ------------- |
| Domain name                 | `gitlab.io`       | -             |
| IP address                  | `35.185.44.232`   | -             |
| Custom domains support      | yes               | no            |
| TLS certificates support    | yes               | no            |
| Maximum size (uncompressed) | 1G                | 100M          |

NOTE: **Note:**
The maximum size of your Pages site is regulated by the artifacts maximum size
which is part of [GitLab CI/CD](#gitlab-cicd).

## GitLab CI/CD

Below are the current settings regarding [GitLab CI/CD](../../ci/README.md).

| Setting                 | GitLab.com        | Default       |
| -----------             | ----------------- | ------------- |
| Artifacts maximum size (uncompressed) | 1G                | 100M          |
| Artifacts [expiry time](../../ci/yaml/README.md#artifactsexpire_in)   | kept forever           | deleted after 30 days unless otherwise specified    |
| Scheduled Pipeline Cron | `*/5 * * * *` | `*/19 * * * *` |

## Repository size limit

The maximum size your Git repository is allowed to be, including LFS. If you are near
or over the size limit, you can [reduce your repository size with Git](../project/repository/reducing_the_repo_size_using_git.md).

| Setting                 | GitLab.com        | Default       |
| -----------             | ----------------- | ------------- |
| Repository size including LFS | 10G         | Unlimited     |

## IP range

GitLab.com, CI/CD, and related services are deployed into Google Cloud Platform (GCP). Any
IP based firewall can be configured by looking up all
[IP address ranges or CIDR blocks for GCP](https://cloud.google.com/compute/docs/faq#where_can_i_find_product_name_short_ip_ranges).

[Static endpoints](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/97) are being considered.

## Shared Runners

Shared Runners on GitLab.com run in [autoscale mode] and powered by Google Cloud Platform.
Autoscaling means reduced waiting times to spin up CI/CD jobs, and isolated VMs for each project,
thus maximizing security. They're free to use for public open source projects and limited
to 2000 CI minutes per month per group for private projects. More minutes
[can be purchased](../../subscriptions/index.md#extra-shared-runners-pipeline-minutes), if
needed. Read about all [GitLab.com plans](https://about.gitlab.com/pricing/).

All your CI/CD jobs run on [n1-standard-1 instances](https://cloud.google.com/compute/docs/machine-types) with 3.75GB of RAM, CoreOS and the latest Docker Engine
installed. Instances provide 1 vCPU and 25GB of HDD disk space. The default
region of the VMs is US East1.
Each instance is used only for one job, this ensures any sensitive data left on the system can't be accessed by other people their CI jobs.

The `gitlab-shared-runners-manager-X.gitlab.com` fleet of Runners are dedicated for GitLab projects as well as community forks of them. They use a slightly larger machine type (n1-standard-2) and have a bigger SSD disk size. They will not run untagged jobs and unlike the general fleet of shared Runners, the instances are re-used up to 40 times.

Jobs handled by the shared Runners on GitLab.com (`shared-runners-manager-X.gitlab.com`),
**will be timed out after 3 hours**, regardless of the timeout configured in a
project. Check the issues [4010] and [4070] for the reference.

Below are the shared Runners settings.

| Setting                               | GitLab.com                                        | Default    |
| -----------                           | -----------------                                 | ---------- |
| [GitLab Runner]                       | [Runner versions dashboard](https://dashboards.gitlab.com/d/000000159/ci?from=now-1h&to=now&refresh=5m&orgId=1&panelId=12&fullscreen&theme=light) | - |
| Executor                              | `docker+machine`                                  | -          |
| Default Docker image                  | `ruby:2.5`                                        | -          |
| `privileged` (run [Docker in Docker]) | `true`                                            | `false`    |

### `config.toml`

The full contents of our `config.toml` are:

**Google Cloud Platform**

```toml
concurrent = X
check_interval = 1
metrics_server = "X"
sentry_dsn = "X"

[[runners]]
  name = "docker-auto-scale"
  request_concurrency = X
  url = "https://gitlab.com/"
  token = "SHARED_RUNNER_TOKEN"
  executor = "docker+machine"
  environment = [
    "DOCKER_DRIVER=overlay2",
    "DOCKER_TLS_CERTDIR="
  ]
  limit = X
  [runners.docker]
    image = "ruby:2.5"
    privileged = true
    volumes = [
      "/certs/client",
      "/dummy-sys-class-dmi-id:/sys/class/dmi/id:ro" # Make kaniko builds work on GCP.
    ]
  [runners.machine]
    IdleCount = 50
    IdleTime = 3600
    OffPeakPeriods = ["* * * * * sat,sun *"]
    OffPeakTimezone = "UTC"
    OffPeakIdleCount = 15
    OffPeakIdleTime = 3600
    MaxBuilds = 1 # For security reasons we delete the VM after job has finished so it's not reused.
    MachineName = "srm-%s"
    MachineDriver = "google"
    MachineOptions = [
      "google-project=PROJECT",
      "google-disk-size=25",
      "google-machine-type=n1-standard-1",
      "google-username=core",
      "google-tags=gitlab-com,srm",
      "google-use-internal-ip",
      "google-zone=us-east1-d",
      "engine-opt=mtu=1460", # Set MTU for container interface, for more information check https://gitlab.com/gitlab-org/gitlab-runner/issues/3214#note_82892928
      "google-machine-image=PROJECT/global/images/IMAGE",
      "engine-opt=ipv6", # This will create IPv6 interfaces in the containers.
      "engine-opt=fixed-cidr-v6=fc00::/7",
      "google-operation-backoff-initial-interval=2" # Custom flag from forked docker-machine, for more information check https://github.com/docker/machine/pull/4600
    ]
  [runners.cache]
    Type = "gcs"
    Shared = true
    [runners.cache.gcs]
      CredentialsFile = "/path/to/file"
      BucketName = "bucket-name"
```

## Sidekiq

GitLab.com runs [Sidekiq](https://sidekiq.org) with arguments `--timeout=4 --concurrency=4`
and the following environment variables:

| Setting                                    | GitLab.com | Default   |
|--------                                    |----------- |--------   |
| `SIDEKIQ_DAEMON_MEMORY_KILLER`             | -          | -         |
| `SIDEKIQ_MEMORY_KILLER_MAX_RSS`            | `2000000`  | `2000000` |
| `SIDEKIQ_MEMORY_KILLER_HARD_LIMIT_RSS`     | -          | -         |
| `SIDEKIQ_MEMORY_KILLER_CHECK_INTERVAL`     | -          | `3`       |
| `SIDEKIQ_MEMORY_KILLER_GRACE_TIME`         | -          | `900`     |
| `SIDEKIQ_MEMORY_KILLER_SHUTDOWN_WAIT`      | -          | `30`      |
| `SIDEKIQ_LOG_ARGUMENTS`                    | `1`        | -         |

NOTE: **Note:**
The `SIDEKIQ_MEMORY_KILLER_MAX_RSS` setting is `16000000` on Sidekiq import
nodes and Sidekiq export nodes.

## Cron jobs

Periodically executed jobs by Sidekiq, to self-heal GitLab, do external
synchronizations, run scheduled pipelines, etc.:

| Setting                     | GitLab.com   | Default      |
|--------                     |------------- |------------- |
| `pipeline_schedule_worker`  | `19 * * * *` | `19 * * * *` |

## PostgreSQL

GitLab.com being a fairly large installation of GitLab means we have changed
various PostgreSQL settings to better suit our needs. For example, we use
streaming replication and servers in hot-standby mode to balance queries across
different database servers.

The list of GitLab.com specific settings (and their defaults) is as follows:

| Setting                             | GitLab.com                                                          | Default                               |
|:------------------------------------|:--------------------------------------------------------------------|:--------------------------------------|
| archive_command                     | `/usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e wal-push %p` | empty                                 |
| archive_mode                        | on                                                                  | off                                   |
| autovacuum_analyze_scale_factor     | 0.01                                                                | 0.01                                  |
| autovacuum_max_workers              | 6                                                                   | 3                                     |
| autovacuum_vacuum_cost_limit        | 1000                                                                | -1                                    |
| autovacuum_vacuum_scale_factor      | 0.01                                                                | 0.02                                  |
| checkpoint_completion_target        | 0.7                                                                 | 0.9                                   |
| checkpoint_segments                 | 32                                                                  | 10                                    |
| effective_cache_size                | 338688MB                                                            | Based on how much memory is available |
| hot_standby                         | on                                                                  | off                                   |
| hot_standby_feedback                | on                                                                  | off                                   |
| log_autovacuum_min_duration         | 0                                                                   | -1                                    |
| log_checkpoints                     | on                                                                  | off                                   |
| log_line_prefix                     | `%t [%p]: [%l-1]`                                                   | empty                                 |
| log_min_duration_statement          | 1000                                                                | -1                                    |
| log_temp_files                      | 0                                                                   | -1                                    |
| maintenance_work_mem                | 2048MB                                                              | 16 MB                                 |
| max_replication_slots               | 5                                                                   | 0                                     |
| max_wal_senders                     | 32                                                                  | 0                                     |
| max_wal_size                        | 5GB                                                                 | 1GB                                   |
| shared_buffers                      | 112896MB                                                            | Based on how much memory is available |
| shared_preload_libraries            | pg_stat_statements                                                  | empty                                 |
| shmall                              | 30146560                                                            | Based on the server's capabilities    |
| shmmax                              | 123480309760                                                        | Based on the server's capabilities    |
| wal_buffers                         | 16MB                                                                | -1                                    |
| wal_keep_segments                   | 512                                                                 | 10                                    |
| wal_level                           | replica                                                             | minimal                               |
| statement_timeout                   | 15s                                                                 | 60s                                   |
| idle_in_transaction_session_timeout | 60s                                                                 | 60s                                   |

Some of these settings are in the process being adjusted. For example, the value
for `shared_buffers` is quite high and as such we are looking into adjusting it.
More information on this particular change can be found at
<https://gitlab.com/gitlab-com/infrastructure/issues/1555>. An up to date list
of proposed changes can be found at
<https://gitlab.com/gitlab-com/infrastructure/issues?scope=all&utf8=%E2%9C%93&state=opened&label_name[]=database&label_name[]=change>.

## Unicorn

GitLab.com adjusts the memory limits for the [unicorn-worker-killer][unicorn-worker-killer] gem.

Base default:

- `memory_limit_min` = 750MiB
- `memory_limit_max` = 1024MiB

Web front-ends:

- `memory_limit_min` = 1024MiB
- `memory_limit_max` = 1280MiB

## GitLab.com-specific rate limits

NOTE: **Note:**
See [Rate limits](../../security/rate_limits.md) for administrator
documentation.

IP blocks usually happen when GitLab.com receives unusual traffic from a single
IP address that the system views as potentially malicious based on rate limit
settings. After the unusual traffic ceases, the IP address will be automatically
released depending on the type of block, as described below.

If you receive a `403 Forbidden` error for all requests to GitLab.com, please
check for any automated processes that may be triggering a block. For
assistance, contact [GitLab Support](https://support.gitlab.com/hc/en-us)
with details, such as the affected IP address.

### HAProxy API throttle

GitLab.com responds with HTTP status code `429` to API requests that exceed 10
requests
per second per IP address.

The following example headers are included for all API requests:

```
RateLimit-Limit: 600
RateLimit-Observed: 6
RateLimit-Remaining: 594
RateLimit-Reset: 1563325137
RateLimit-ResetTime: Wed, 17 Jul 2019 00:58:57 GMT
```

Source:

- Search for `rate_limit_http_rate_per_minute` and `rate_limit_sessions_per_second` in [GitLab.com's current HAProxy settings](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy/blob/master/attributes/default.rb).

### Rack Attack initializer

Details of rate limits enforced by [Rack Attack](../../security/rack_attack.md).

#### Protected paths throttle

GitLab.com responds with HTTP status code `429` to POST requests at protected
paths that exceed 10 requests per **minute** per IP address.

See the source below for which paths are protected. This includes user creation,
user confirmation, user sign in, and password reset.

This header is included in responses to blocked requests:

```
Retry-After: 60
```

See [Protected Paths](../admin_area/settings/protected_paths.md) for more details.

#### Git and container registry failed authentication ban

GitLab.com responds with HTTP status code `403` for 1 hour, if 30 failed
authentication requests were received in a 3-minute period from a single IP address.

This applies only to Git requests and container registry (`/jwt/auth`) requests
(combined).

This limit:

- Is reset by requests that authenticate successfully. For example, 29
  failed authentication requests followed by 1 successful request, followed by 29
  more failed authentication requests would not trigger a ban.
- Does not apply to JWT requests authenticated by `gitlab-ci-token`.

No response headers are provided.

### Admin Area settings

GitLab.com:

- Has [rate limits on raw endpoints](../../user/admin_area/settings/rate_limits_on_raw_endpoints.md)
  set to the default.
- Does not have the user and IP rate limits settings enabled.

### Visibility settings

On GitLab.com, projects, groups, and snippets created
As of GitLab 12.2 (July 2019), projects, groups, and snippets have the
[**Internal** visibility](../../public_access/public_access.md#internal-projects) setting [disabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/issues/12388).

## GitLab.com Logging

We use [Fluentd](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#fluentd) to parse our logs. Fluentd sends our logs to
[Stackdriver Logging](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#stackdriver) and [Cloud Pub/Sub](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#cloud-pubsub).
Stackdriver is used for storing logs long-term in Google Cold Storage (GCS). Cloud Pub/Sub
is used to forward logs to an [Elastic cluster](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#elastic) using [pubsubbeat](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#pubsubbeat-vms).

You can view more information in our runbooks such as:

- A [detailed list of what we're logging](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#what-are-we-logging)
- Our [current log retention policies](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#retention)
- A [diagram of our logging infrastructure](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#logging-infrastructure-overview)

## GitLab.com at scale

In addition to the GitLab Enterprise Edition Omnibus install, GitLab.com uses
the following applications and settings to achieve scale. All settings are
publicly available at [chef cookbooks](https://gitlab.com/gitlab-cookbooks).

### Elastic Cluster

We use Elasticsearch and Kibana for part of our monitoring solution:

- [`gitlab-cookbooks` / `gitlab-elk` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-elk)
- [`gitlab-cookbooks` / `gitlab_elasticsearch` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab_elasticsearch)

### Fluentd

We use Fluentd to unify our GitLab logs:

- [`gitlab-cookbooks` / `gitlab_fluentd` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab_fluentd)

### Prometheus

Prometheus complete our monitoring stack:

- [`gitlab-cookbooks` / `gitlab-prometheus` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-prometheus)

### Grafana

For the visualization of monitoring data:

- [`gitlab-cookbooks` / `gitlab-grafana` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-grafana)

### Sentry

Open source error tracking:

- [`gitlab-cookbooks` / `gitlab-sentry` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-sentry)

### Consul

Service discovery:

- [`gitlab-cookbooks` / `gitlab_consul` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab_consul)

### Haproxy

High Performance TCP/HTTP Load Balancer:

- [`gitlab-cookbooks` / `gitlab-haproxy` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy)

[autoscale mode]: https://docs.gitlab.com/runner/configuration/autoscale.html "How Autoscale works"
[runners-post]: https://about.gitlab.com/blog/2016/04/05/shared-runners/ "Shared Runners on GitLab.com"
[GitLab Runner]: https://gitlab.com/gitlab-org/gitlab-runner
[altssh]: https://about.gitlab.com/blog/2016/02/18/gitlab-dot-com-now-supports-an-alternate-git-plus-ssh-port/ "GitLab.com now supports an alternate git+ssh port"
[docker in docker]: https://hub.docker.com/_/docker/ "Docker in Docker at DockerHub"
[mailgun]: https://www.mailgun.com/ "Mailgun website"
[unicorn-worker-killer]: https://rubygems.org/gems/unicorn-worker-killer "unicorn-worker-killer"
[4010]: https://gitlab.com/gitlab-com/infrastructure/issues/4010 "Find a good value for maximum timeout for Shared Runners"
[4070]: https://gitlab.com/gitlab-com/infrastructure/issues/4070 "Configure per-runner timeout for shared-runners-manager-X on GitLab.com"
