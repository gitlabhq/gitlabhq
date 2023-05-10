---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab.com settings **(FREE SAAS)**

This page contains information about the settings that are used on GitLab.com, available to
[GitLab SaaS](https://about.gitlab.com/pricing/) customers.

See some of these settings on the [instance configuration page](https://gitlab.com/help/instance_configuration) of GitLab.com.

## Password requirements

GitLab.com has the following requirements for passwords on new accounts and password changes:

- Minimum character length 8 characters.
- Maximum character length 128 characters.
- All characters are accepted. For example, `~`, `!`, `@`, `#`, `$`, `%`, `^`, `&`, `*`, `()`,
  `[]`, `_`, `+`,  `=`, and `-`.

## SSH key restrictions

GitLab.com uses the default [SSH key restrictions](../../security/ssh_keys_restrictions.md).

## SSH host keys fingerprints

Below are the fingerprints for SSH host keys on GitLab.com. The first time you
connect to a GitLab.com repository, one of these keys is displayed in the output.

| Algorithm        | MD5 (deprecated) | SHA256  |
|------------------|------------------|---------|
| ED25519          | `2e:65:6a:c8:cf:bf:b2:8b:9a:bd:6d:9f:11:5c:12:16` | `eUXGGm1YGsMAS7vkcx6JOJdOGHPem5gQp4taiCfCLB8` |
| RSA              | `b6:03:0e:39:97:9e:d0:e7:24:ce:a3:77:3e:01:42:09` | `ROQFvPThGrW4RuWLoL9tq9I9zJ42fK4XywyRtbOz/EQ` |
| DSA (deprecated) | `7a:47:81:3a:ee:89:89:64:33:ca:44:52:3d:30:d4:87` | `p8vZBUOR0XQz6sYiaWSMLmh0t9i8srqYKool/Xfdfqw` |
| ECDSA            | `f1:d0:fb:46:73:7a:70:92:5a:ab:5d:ef:43:e2:1c:35` | `HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw` |

## SSH `known_hosts` entries

Add the following to `.ssh/known_hosts` to skip manual fingerprint
confirmation in SSH:

```plaintext
gitlab.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf
gitlab.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsj2bNKTBSpIYDEGk9KxsGh3mySTRgMtXL583qmBpzeQ+jqCMRgBqB98u3z++J1sKlXHWfM9dyhSevkMwSbhoR8XIq/U0tCNyokEi/ueaBMCvbcTHhO7FcwzY92WK4Yt0aGROY5qX2UKSeOvuP4D6TPqKF1onrSzH9bx9XUf2lEdWT/ia1NEKjunUqu1xOB/StKDHMoX4/OKyIzuS0q/T1zOATthvasJFoPrAjkohTyaDUz2LN5JoH839hViyEG82yB+MjcFV5MU3N1l1QL3cVUCh93xSaua1N85qivl+siMkPGbO5xR/En4iEY6K2XPASUEMaieWVNTRCtJ4S8H+9
gitlab.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFSMqzJeV9rUzU4kWitGjeR4PWSa29SPqJ1fVkhtj3Hw9xjLVXVYrU9QlYWrOLXBpQ6KWjbjTDTdDkoohFzgbEY=
```

## Mail configuration

GitLab.com sends emails from the `mg.gitlab.com` domain by using [Mailgun](https://www.mailgun.com/),
and has its own dedicated IP addresses:

- `161.38.202.219`
- `159.135.226.146`
- `192.237.158.143`
- `198.61.254.136`
- `23.253.183.236`
- `69.72.35.190`

The IP addresses for `mg.gitlab.com` are subject to change at any time.

### Service Desk custom mailbox

On GitLab.com, there's a mailbox configured for Service Desk with the email address:
`contact-project+%{key}@incoming.gitlab.com`. To use this mailbox, configure the
[custom suffix](../project/service_desk.md#configure-a-custom-email-address-suffix) in project
settings.

## Backups

[See our backup strategy](https://about.gitlab.com/handbook/engineering/infrastructure/production/#backups).

To back up an entire project on GitLab.com, you can export it either:

- [Through the UI](../project/settings/import_export.md).
- [Through the API](../../api/project_import_export.md#schedule-an-export). You
  can also use the API to programmatically upload exports to a storage platform,
  such as Amazon S3.

With exports, be aware of [what is and is not](../project/settings/import_export.md#items-that-are-exported)
included in a project export.

GitLab is built on Git, so you can back up just the repository of a project by
[cloning](../../gitlab-basics/start-using-git.md#clone-a-repository) it to
another computer.
Similarly, you can clone a project's wiki to back it up. All files
[uploaded after August 22, 2020](../project/wiki/index.md#create-a-new-wiki-page)
are included when cloning.

## Delayed group deletion **(PREMIUM SAAS)**

After May 08, 2023, all groups have delayed deletion enabled by default.

Groups are permanently deleted after a seven-day delay.

If you are on the Free tier, your groups are immediately deleted, and you will not be able to restore them.

## Delayed project deletion **(PREMIUM SAAS)**

After May 08, 2023, all groups have delayed project deletion enabled by default.

Projects are permanently deleted after a seven-day delay.

If you are on the Free tier, your projects are immediately deleted, and you will not be able to restore them.

## Inactive project deletion

[Inactive project deletion](../../administration/inactive_project_deletion.md) is disabled on GitLab.com.

## Alternative SSH port

GitLab.com can be reached by using a [different SSH port](https://about.gitlab.com/blog/2016/02/18/gitlab-dot-com-now-supports-an-alternate-git-plus-ssh-port/) for `git+ssh`.

| Setting    | Value               |
|------------|---------------------|
| `Hostname` | `altssh.gitlab.com` |
| `Port`     | `443`               |

An example `~/.ssh/config` is the following:

```plaintext
Host gitlab.com
  Hostname altssh.gitlab.com
  User git
  Port 443
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/gitlab
```

## GitLab Pages

Some settings for [GitLab Pages](../project/pages/index.md) differ from the
[defaults for self-managed instances](../../administration/pages/index.md):

| Setting                                           | GitLab.com             |
|---------------------------------------------------|------------------------|
| Domain name                                       | `gitlab.io`            |
| IP address                                        | `35.185.44.232`        |
| Support for custom domains                        | **{check-circle}** Yes |
| Support for TLS certificates                      | **{check-circle}** Yes |
| Maximum site size                                 | 1 GB                   |
| Number of custom domains per GitLab Pages website | 150                    |

The maximum size of your Pages site depends on the maximum artifact size,
which is part of [GitLab CI/CD](#gitlab-cicd).

[Rate limits](#gitlabcom-specific-rate-limits) also exist for GitLab Pages.

## GitLab CI/CD

Below are the current settings regarding [GitLab CI/CD](../../ci/index.md).
Any settings or feature limits not listed here are using the defaults listed in
the related documentation.

| Setting                                                                          | GitLab.com                                                                                                                | Default (self-managed) |
|----------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------|------------------------|
| Artifacts maximum size (compressed)                                              | 1 GB                                                                                                                      | See [Maximum artifacts size](../../user/admin_area/settings/continuous_integration.md#maximum-artifacts-size). |
| Artifacts [expiry time](../../ci/yaml/index.md#artifactsexpire_in)               | From June 22, 2020, deleted after 30 days unless otherwise specified (artifacts created before that date have no expiry). | See [Default artifacts expiration](../admin_area/settings/continuous_integration.md#default-artifacts-expiration). |
| Scheduled Pipeline Cron                                                          | `*/5 * * * *`                                                                                                             | See [Pipeline schedules advanced configuration](../../administration/cicd.md#change-maximum-scheduled-pipeline-frequency). |
| Maximum jobs in active pipelines                                                 | `500` for Free tier, `1000` for all trial tiers, `20000` for Premium, and `100000` for Ultimate.                                                 | See [Number of jobs in active pipelines](../../administration/instance_limits.md#number-of-jobs-in-active-pipelines). |
| Maximum CI/CD subscriptions to a project                                         | `2`                                                                                                                       | See [Number of CI/CD subscriptions to a project](../../administration/instance_limits.md#number-of-cicd-subscriptions-to-a-project). |
| Maximum number of pipeline triggers in a project                                 | `25000` for Free tier, Unlimited for all paid tiers                                                                       | See [Limit the number of pipeline triggers](../../administration/instance_limits.md#limit-the-number-of-pipeline-triggers). |
| Maximum pipeline schedules in projects                                           | `10` for Free tier, `50` for all paid tiers                                                                               | See [Number of pipeline schedules](../../administration/instance_limits.md#number-of-pipeline-schedules). |
| Maximum pipelines per schedule                                                   | `24` for Free tier, `288` for all paid tiers                                                                              | See [Limit the number of pipelines created by a pipeline schedule per day](../../administration/instance_limits.md#limit-the-number-of-pipelines-created-by-a-pipeline-schedule-per-day). |
| Maximum number of schedule rules defined for each security policy project        | Unlimited for all paid tiers                                                                                              | See [Number of schedule rules defined for each security policy project](../../administration/instance_limits.md#limit-the-number-of-schedule-rules-defined-for-security-policy-project). |
| Scheduled job archiving                                                          | 3 months (from June 22, 2020). Jobs created before that date were archived after September 22, 2020.                      | Never. |
| Maximum test cases per [unit test report](../../ci/testing/unit_test_reports.md) | `500000`                                                                                                                  | Unlimited. |
| Maximum registered runners                                                       | Free tier: `50` per-group / `50` per-project<br/>All paid tiers: `1000` per-group  / `1000` per-project                   | See [Number of registered runners per scope](../../administration/instance_limits.md#number-of-registered-runners-per-scope). |
| Limit of dotenv variables                                                        | Free tier: `50` / Premium tier: `100` / Ultimate tier: `150`                                                              | See [Limit dotenv variables](../../administration/instance_limits.md#limit-dotenv-variables). |
| Authorization token duration (minutes)                                           | `15`                                                                                                                      | To set a custom value, in the Rails console, run `ApplicationSetting.last.update(container_registry_token_expire_delay: <integer>)`, where `<integer>` is the desired number of minutes. |

## Package registry limits

The [maximum file size](../../administration/instance_limits.md#file-size-limits)
for a package uploaded to the [GitLab Package Registry](../../user/packages/package_registry/index.md)
varies by format:

| Package type | GitLab.com |
|--------------|------------|
| Conan        | 5 GB       |
| Generic      | 5 GB       |
| Helm         | 5 MB       |
| Maven        | 5 GB       |
| npm          | 5 GB       |
| NuGet        | 5 GB       |
| PyPI         | 5 GB       |
| Terraform    | 1 GB       |

## Account and limit settings

GitLab.com has the following account limits enabled. If a setting is not listed,
the default value [is the same as for self-managed instances](../admin_area/settings/account_and_limit_settings.md):

| Setting                       | GitLab.com default |
|-------------------------------|--------------------|
| [Repository size including LFS](../admin_area/settings/account_and_limit_settings.md#repository-size-limit) | 10 GB |
| [Maximum import size](../project/settings/import_export.md#import-a-project-and-its-data)                   | 5 GB  |
| Maximum attachment size       | 100 MB              |

If you are near or over the repository size limit, you can either
[reduce your repository size with Git](../project/repository/reducing_the_repo_size_using_git.md)
or [purchase additional storage](https://about.gitlab.com/pricing/licensing-faq/#can-i-buy-more-storage).

NOTE:
`git push` and GitLab project imports are limited to 5 GB per request through
Cloudflare. Git LFS and imports other than a file upload are not affected by
this limit. Repository limits apply to both public and private projects.

## Import sources

GitLab.com has the following import sources enabled.

| Import source          | GitLab.com default | Default (self-managed)     |
|------------------------|--------------------| ---------------------------|
| Bitbucket Cloud        | **{check-circle}** Yes | **{dotted-circle}** No |
| Bitbucket Server       | **{check-circle}** Yes | **{dotted-circle}** No |
| FogBugz                | **{check-circle}** Yes | **{dotted-circle}** No |
| GitLab Direct Transfer | **{check-circle}** Yes | **{dotted-circle}** No |
| Gitea                  | **{check-circle}** Yes | **{dotted-circle}** No |
| GitHub                 | **{check-circle}** Yes | **{dotted-circle}** No |
| GitLab export          | **{check-circle}** Yes | **{dotted-circle}** No |
| Manifest file          | **{check-circle}** Yes | **{dotted-circle}** No |
| Repository by URL      | **{check-circle}** Yes | **{dotted-circle}** No |

## IP range

GitLab.com uses the IP ranges `34.74.90.64/28` and `34.74.226.0/24` for traffic from its Web/API
fleet. This whole range is solely allocated to GitLab. You can expect connections from webhooks or repository mirroring to come
from those IPs and allow them.

GitLab.com is fronted by Cloudflare. For incoming connections to GitLab.com, you might need to allow CIDR blocks of Cloudflare ([IPv4](https://www.cloudflare.com/ips-v4/) and [IPv6](https://www.cloudflare.com/ips-v6/)).

For outgoing connections from CI/CD runners, we are not providing static IP addresses.
All GitLab.com shared runners are deployed into Google Cloud Platform (GCP) in `us-east1`.
Any IP-based firewall can be configured by looking up
[IP address ranges or CIDR blocks for GCP](https://cloud.google.com/compute/docs/faq#find_ip_range).

## Hostname list

Add these hostnames when you configure allow-lists in local HTTP(S) proxies,
or other web-blocking software that governs end-user computers. Pages on
GitLab.com load content from these hostnames:

- `gitlab.com`
- `*.gitlab.com`
- `*.gitlab-static.net`
- `*.gitlab.io`
- `*.gitlab.net`

Documentation and Company pages served over `docs.gitlab.com` and `about.gitlab.com`
also load certain page content directly from common public CDN hostnames.

## Webhooks

The following limits apply for [webhooks](../project/integrations/webhooks.md).

### Rate limits

The number of times a webhook can be called per minute, per top-level namespace.
The limit varies depending on your plan and the number of seats in your subscription.

| Plan              | Default for GitLab.com  |
|----------------------|-------------------------|
| Free    | `500` |
| Premium | `99` seats or fewer: `1,600`<br>`100-399` seats: `2,800`<br>`400` seats or more: `4,000` |
| Ultimate and open source |`999` seats or fewer: `6,000`<br>`1,000-4,999` seats: `9,000`<br>`5,000` seats or more: `13,000` |

### Other limits

| Setting              | Default for GitLab.com  |
|----------------------|-------------------------|
| Number of webhooks   | `100` per project, `50` per group (subgroup webhooks are not counted towards parent group limits ) |
| Maximum payload size | 25 MB                   |
| Timeout              | 10 seconds              |

For self-managed instance limits, see:

- [Webhook rate limit](../../administration/instance_limits.md#webhook-rate-limit).
- [Number of webhooks](../../administration/instance_limits.md#number-of-webhooks).
- [Webhook timeout](../../administration/instance_limits.md#webhook-timeout).

## Runner SaaS

Runner SaaS is the hosted, secure, and managed build environment you can use to run CI/CD jobs for your GitLab.com hosted project.

For more information, see [Runner SaaS](../../ci/runners/index.md).

## Puma

GitLab.com uses the default of 60 seconds for [Puma request timeouts](../../administration/operations/puma.md#change-the-worker-timeout).

## Maximum number of reviewers and assignees

> - Maximum assignees [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/368936) in GitLab 15.6.
> - Maximum reviewers [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/366485) in GitLab 15.9.

Merge requests enforce these maximums:

- Maximum assignees: 200
- Maximum reviewers: 200

## GitLab.com-specific rate limits

NOTE:
See [Rate limits](../../security/rate_limits.md) for administrator
documentation.

When a request is rate limited, GitLab responds with a `429` status
code. The client should wait before attempting the request again. There
are also informational headers with this response detailed in
[rate limiting responses](#rate-limiting-responses).

The following table describes the rate limits for GitLab.com, both before and
after the limits change in January, 2021:

| Rate limit                                                                 | From 2021-02-12               | From 2022-02-03                      |
|:---------------------------------------------------------------------------|:------------------------------|:-------------------------------------|
| **Protected paths** (for a given **IP address**)                           | **10** requests per minute    | **10** requests per minute           |
| **Raw endpoint** traffic (for a given **project, commit, and file path**)  | **300** requests per minute   | **300** requests per minute          |
| **Unauthenticated** traffic (from a given **IP address**)                  | **500** requests per minute   | **500** requests per minute          |
| **Authenticated** API traffic (for a given **user**)                       | **2,000** requests per minute | **2,000** requests per minute        |
| **Authenticated** non-API HTTP traffic (for a given **user**)              | **1,000** requests per minute | **1,000** requests per minute        |
| **All** traffic (from a given **IP address**)                              | **2,000** requests per minute | **2,000** requests per minute        |
| **Issue creation**                                                         | **300** requests per minute   | **200** requests per minute          |
| **Note creation** (on issues and merge requests)                           | **60** requests per minute    | **60** requests per minute           |
| **Advanced, project, and group search** API (for a given **IP address**)   | **10** requests per minute    | **10** requests per minute           |
| **GitLab Pages** requests (for a given **IP address**)                     |                               | **1000** requests per **50 seconds** |
| **GitLab Pages** requests (for a given **GitLab Pages domain**)            |                               | **5000** requests per **10 seconds** |
| **GitLab Pages** TLS connections (for a given **IP address**)              |                               | **1000** requests per **50 seconds** |
| **GitLab Pages** TLS connections (for a given **GitLab Pages domain**)     |                               | **400** requests per **10 seconds**  |
| **Pipeline creation** requests (for a given **project, user, and commit**) |                               | **25** requests per minute           |
| **Alert integration endpoint** requests (for a given **project**)          |                               | **3600** requests per hour           |

More details are available on the rate limits for
[protected paths](#protected-paths-throttle) and
[raw endpoints](../../user/admin_area/settings/rate_limits_on_raw_endpoints.md).

GitLab can rate-limit requests at several layers. The rate limits listed here
are configured in the application. These limits are the most
restrictive per IP address. For more information about the rate limits
for GitLab.com, see
[an overview](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/rate-limiting).

### Rate limiting responses

For information on rate limiting responses, see:

- [List of headers on responses to blocked requests](../admin_area/settings/user_and_ip_rate_limits.md#response-headers).
- [Customizable response text](../admin_area/settings/user_and_ip_rate_limits.md#use-a-custom-rate-limit-response).

### Protected paths throttle

GitLab.com responds with HTTP status code `429` to POST requests at protected
paths that exceed 10 requests per **minute** per IP address.

See the source below for which paths are protected. This includes user creation,
user confirmation, user sign in, and password reset.

[User and IP rate limits](../admin_area/settings/user_and_ip_rate_limits.md#response-headers)
includes a list of the headers responded to blocked requests.

See [Protected Paths](../admin_area/settings/protected_paths.md) for more details.

### IP blocks

IP blocks can occur when GitLab.com receives unusual traffic from a single
IP address that the system views as potentially malicious. This can be based on
rate limit settings. After the unusual traffic ceases, the IP address is
automatically released depending on the type of block, as described in a
following section.

If you receive a `403 Forbidden` error for all requests to GitLab.com,
check for any automated processes that may be triggering a block. For
assistance, contact [GitLab Support](https://support.gitlab.com)
with details, such as the affected IP address.

#### Git and container registry failed authentication ban

GitLab.com responds with HTTP status code `403` for 1 hour, if 30 failed
authentication requests were received in a 3-minute period from a single IP address.

This applies only to Git requests and container registry (`/jwt/auth`) requests
(combined).

This limit:

- Is reset by requests that authenticate successfully. For example, 29
  failed authentication requests followed by 1 successful request, followed by
  29 more failed authentication requests would not trigger a ban.
- Does not apply to JWT requests authenticated by `gitlab-ci-token`.

No response headers are provided.

### Pagination response headers

For performance reasons, if a query returns more than 10,000 records, [GitLab excludes some headers](../../api/rest/index.md#pagination-response-headers).

### Visibility settings

Projects, groups, and snippets have the
[Internal visibility](../public_access.md#internal-projects-and-groups)
setting [disabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/12388).

### SSH maximum number of connections

GitLab.com defines the maximum number of concurrent, unauthenticated SSH
connections by using the [MaxStartups setting](https://man.openbsd.org/sshd_config.5#MaxStartups).
If more than the maximum number of allowed connections occur concurrently, they
are dropped and users get
[an `ssh_exchange_identification` error](../../topics/git/troubleshooting_git.md#ssh_exchange_identification-error).

### Group and project import by uploading export files

To help avoid abuse, the following are rate limited:

- Project and group imports.
- Group and project exports that use files.
- Export downloads.

For more information, see:

- [Project import/export rate limits](../../user/project/settings/import_export.md#rate-limits).
- [Group import/export rate limits](../../user/group/import/index.md#rate-limits).

### Non-configurable limits

See [non-configurable limits](../../security/rate_limits.md#non-configurable-limits)
for information on rate limits that are not configurable, and therefore also
used on GitLab.com.

## GitLab.com logging

We use [Fluentd](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#fluentd)
to parse our logs. Fluentd sends our logs to
[Stackdriver Logging](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#stackdriver)
and [Cloud Pub/Sub](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#cloud-pubsub).
Stackdriver is used for storing logs long-term in Google Cold Storage (GCS).
Cloud Pub/Sub is used to forward logs to an [Elastic cluster](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#elastic) using [`pubsubbeat`](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#pubsubbeat-vms).

You can view more information in our runbooks such as:

- A [detailed list of what we're logging](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/logging#what-are-we-logging)
- Our [current log retention policies](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/logging#retention)
- A [diagram of our logging infrastructure](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/logging#logging-infrastructure-overview)

### Job logs

By default, GitLab does not expire job logs. Job logs are retained indefinitely,
and can't be configured on GitLab.com to expire. You can erase job logs
[manually with the Jobs API](../../api/jobs.md#erase-a-job) or by
[deleting a pipeline](../../ci/pipelines/index.md#delete-a-pipeline).

## GitLab.com at scale

In addition to the GitLab Enterprise Edition Omnibus install, GitLab.com uses
the following applications and settings to achieve scale. All settings are
publicly available, as [Kubernetes configuration](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com)
or [Chef cookbooks](https://gitlab.com/gitlab-cookbooks).

### Elastic cluster

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

### HAProxy

High Performance TCP/HTTP Load Balancer:

- [`gitlab-cookbooks` / `gitlab-haproxy` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy)

## Sidekiq

GitLab.com runs [Sidekiq](https://sidekiq.org) as an [external process](../../administration/sidekiq/index.md)
for Ruby job scheduling.

The current settings are in the [GitLab.com Kubernetes pod configuration](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/gprd.yaml.gotmpl).
