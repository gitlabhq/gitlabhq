# GitLab.com settings

In this page you will find information about the settings that are used on
[GitLab.com](https://about.gitlab.com/pricing).

## SSH host keys fingerprints

Below are the fingerprints for GitLab.com's SSH host keys.

| Algorithm | MD5 | SHA256  |
| --------- | --- | ------- |
|  DSA      | `7a:47:81:3a:ee:89:89:64:33:ca:44:52:3d:30:d4:87` | `p8vZBUOR0XQz6sYiaWSMLmh0t9i8srqYKool/Xfdfqw` |
|  ECDSA    | `f1:d0:fb:46:73:7a:70:92:5a:ab:5d:ef:43:e2:1c:35` | `HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw` |
|  ED25519  | `2e:65:6a:c8:cf:bf:b2:8b:9a:bd:6d:9f:11:5c:12:16` | `eUXGGm1YGsMAS7vkcx6JOJdOGHPem5gQp4taiCfCLB8` |
|  RSA      | `b6:03:0e:39:97:9e:d0:e7:24:ce:a3:77:3e:01:42:09` | `ROQFvPThGrW4RuWLoL9tq9I9zJ42fK4XywyRtbOz/EQ` |

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

Below are the settings for [GitLab Pages].

| Setting                 | GitLab.com        | Default       |
| ----------------------- | ----------------  | ------------- |
| Domain name             | `gitlab.io`       | -             |
| IP address              | `52.167.214.135`  | -             |
| Custom domains support  | yes               | no            |
| TLS certificates support| yes               | no            |

The maximum size of your Pages site is regulated by the artifacts maximum size
which is part of [GitLab CI/CD](#gitlab-ci-cd).

## GitLab CI/CD

Below are the current settings regarding [GitLab CI/CD](../../ci/README.md).

| Setting                 | GitLab.com        | Default       |
| -----------             | ----------------- | ------------- |
| Artifacts maximum size  | 1G                | 100M          |

## Repository size limit

The maximum size your Git repository is allowed to be including LFS.

| Setting                 | GitLab.com        | Default       |
| -----------             | ----------------- | ------------- |
| Repository size including LFS | 10G         | Unlimited     |

## Shared Runners

Shared Runners on GitLab.com run in [autoscale mode] and powered by
Google Cloud Platform and DigitalOcean. Autoscaling means reduced
waiting times to spin up CI/CD jobs, and isolated VMs for each project,
thus maximizing security.

They're free to use for public open source projects and limited to 2000 CI
minutes per month per group for private projects. Read about all
[GitLab.com plans](https://about.gitlab.com/pricing/).

In case of DigitalOcean based Runners, all your CI/CD jobs run on ephemeral
instances with 2GB of RAM, CoreOS and the latest Docker Engine installed.
Instances provide 2 vCPUs and 60GB of SSD disk space. The default region of the
VMs is NYC1.

In case of Google Cloud Platform based Runners, all your CI/CD jobs run on
ephemeral instances with 3.75GB of RAM, CoreOS and the latest Docker Engine
installed. Instances provide 1 vCPU and 25GB of HDD disk space. The default
region of the VMs is US East1.

Below are the shared Runners settings.

| Setting                               | GitLab.com                                        | Default    |
| -----------                           | -----------------                                 | ---------- |
| [GitLab Runner]                       | [Runner versions dashboard][ci_version_dashboard] | -          |
| Executor                              | `docker+machine`                                  | -          |
| Default Docker image                  | `ruby:2.5`                                        | -          |
| `privileged` (run [Docker in Docker]) | `true`                                            | `false`    |

[ci_version_dashboard]: https://monitor.gitlab.net/dashboard/db/ci?from=now-1h&to=now&refresh=5m&orgId=1&panelId=12&fullscreen&theme=light

### `config.toml`

The full contents of our `config.toml` are:

**DigitalOcean**

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
    "DOCKER_DRIVER=overlay2"
  ]
  limit = X
  [runners.docker]
    image = "ruby:2.5"
    privileged = true
  [runners.machine]
    IdleCount = 20
    IdleTime = 1800
    OffPeakPeriods = ["* * * * * sat,sun *"]
    OffPeakTimezone = "UTC"
    OffPeakIdleCount = 5
    OffPeakIdleTime = 1800
    MaxBuilds = 1
    MachineName = "srm-%s"
    MachineDriver = "digitalocean"
    MachineOptions = [
      "digitalocean-image=X",
      "digitalocean-ssh-user=core",
      "digitalocean-region=nyc1",
      "digitalocean-size=s-2vcpu-2gb",
      "digitalocean-private-networking",
      "digitalocean-tags=shared_runners,gitlab_com",
      "engine-registry-mirror=http://INTERNAL_IP_OF_OUR_REGISTRY_MIRROR",
      "digitalocean-access-token=DIGITAL_OCEAN_ACCESS_TOKEN",
    ]
  [runners.cache]
    Type = "s3"
    BucketName = "runner"
    Insecure = true
    Shared = true
    ServerAddress = "INTERNAL_IP_OF_OUR_CACHE_SERVER"
    AccessKey = "ACCESS_KEY"
    SecretKey = "ACCESS_SECRET_KEY"
```

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
    "DOCKER_DRIVER=overlay2"
  ]
  limit = X
  [runners.docker]
    image = "ruby:2.5"
    privileged = true
  [runners.machine]
    IdleCount = 20
    IdleTime = 1800
    OffPeakPeriods = ["* * * * * sat,sun *"]
    OffPeakTimezone = "UTC"
    OffPeakIdleCount = 5
    OffPeakIdleTime = 1800
    MaxBuilds = 1
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
      "google-machine-image=PROJECT/global/images/IMAGE",
      "engine-registry-mirror=http://INTERNAL_IP_OF_OUR_REGISTRY_MIRROR"
    ]
  [runners.cache]
    Type = "s3"
    BucketName = "runner"
    Insecure = true
    Shared = true
    ServerAddress = "INTERNAL_IP_OF_OUR_CACHE_SERVER"
    AccessKey = "ACCESS_KEY"
    SecretKey = "ACCESS_SECRET_KEY"
```

## Sidekiq

GitLab.com runs [Sidekiq][sidekiq] with arguments `--timeout=4 --concurrency=4`
and the following environment variables:

| Setting                                 | GitLab.com | Default   |
|--------                                 |----------- |--------   |
| `SIDEKIQ_MEMORY_KILLER_MAX_RSS`         | `1000000`  | `1000000` |
| `SIDEKIQ_MEMORY_KILLER_SHUTDOWN_SIGNAL` | `SIGKILL`  | -         |
| `SIDEKIQ_LOG_ARGUMENTS`                 | `1`        | -         |

## Cron jobs

Periodically executed jobs by Sidekiq, to self-heal Gitlab, do external
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
| log_line_prefix                     | `%t [%p]: [%l-1] `                                                  | empty                                 |
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
* `memory_limit_min` = 750MiB
* `memory_limit_max` = 1024MiB

Web front-ends:
* `memory_limit_min` = 1024MiB
* `memory_limit_max` = 1280MiB

## GitLab.com at scale

In addition to the GitLab Enterprise Edition Omnibus install, GitLab.com uses
the following applications and settings to achieve scale. All settings are
located publicly available [chef cookbooks](https://gitlab.com/gitlab-cookbooks).

### ELK

We use Elasticsearch, logstash, and Kibana for part of our monitoring solution:

- [gitlab-cookbooks / gitlab-elk · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-elk)
- [gitlab-cookbooks / gitlab_elasticsearch · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab_elasticsearch)

### Prometheus

Prometheus complete our monitoring stack:

- [gitlab-cookbooks / gitlab-prometheus · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-prometheus)

### Grafana

For the visualization of monitoring data:

- [gitlab-cookbooks / gitlab-grafana · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-grafana)

### Sentry

Open source error tracking:

- [gitlab-cookbooks / gitlab-sentry · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-sentry)

### Consul

Service discovery:

- [gitlab-cookbooks / gitlab_consul · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab_consul)

### Haproxy

High Performance TCP/HTTP Load Balancer:

- [gitlab-cookbooks / gitlab-haproxy · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy)

[autoscale mode]: https://docs.gitlab.com/runner/configuration/autoscale.html "How Autoscale works"
[runners-post]: https://about.gitlab.com/2016/04/05/shared-runners/ "Shared Runners on GitLab.com"
[GitLab Runner]: https://gitlab.com/gitlab-org/gitlab-runner
[altssh]: https://about.gitlab.com/2016/02/18/gitlab-dot-com-now-supports-an-alternate-git-plus-ssh-port/ "GitLab.com now supports an alternate git+ssh port"
[GitLab Pages]: https://about.gitlab.com/features/pages "GitLab Pages"
[docker in docker]: https://hub.docker.com/_/docker/ "Docker in Docker at DockerHub"
[mailgun]: https://www.mailgun.com/ "Mailgun website"
[sidekiq]: http://sidekiq.org/ "Sidekiq website"
[unicorn-worker-killer]: https://rubygems.org/gems/unicorn-worker-killer "unicorn-worker-killer"
