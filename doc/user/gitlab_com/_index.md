---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab.com settings
description: Instance configurations.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

These settings are used on GitLab.com, and are available to
[GitLab SaaS](https://about.gitlab.com/pricing/) customers.

See some of these settings on the
[instance configuration page for GitLab.com](https://gitlab.com/help/instance_configuration).

## Account and limit settings

GitLab.com uses these account limits. If a setting is not listed,
the default value [is the same as for GitLab Self-Managed instances](../../administration/settings/account_and_limit_settings.md):

| Setting                                                                                                                                                                                                            | GitLab.com default |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------|
| [Repository size including LFS](../../administration/settings/account_and_limit_settings.md#repository-size-limit)                                                                                                 | 10 GB              |
| [Maximum import size](../project/settings/import_export.md#import-a-project-and-its-data)                                                                                                                          | 5 GiB              |
| [Maximum export size](../project/settings/import_export.md#export-a-project-and-its-data)                                                                                                                          | 40 GiB             |
| [Maximum remote file size for imports from external object storages](../../administration/settings/import_and_export_settings.md#maximum-remote-file-size-for-imports)                                             | 10 GiB             |
| [Maximum download file size when importing from source GitLab instances by direct transfer](../../administration/settings/import_and_export_settings.md#maximum-download-file-size-for-imports-by-direct-transfer) | 5 GiB              |
| Maximum attachment size                                                                                                                                                                                            | 100 MiB            |
| [Maximum decompressed file size for imported archives](../../administration/settings/import_and_export_settings.md#maximum-decompressed-file-size-for-imported-archives)                                           | 25 GiB             |
| [Maximum push size](../../administration/settings/account_and_limit_settings.md#max-push-size)                                                                                                                     | 5 GiB              |

If you are near or over the repository size limit, you can:

- [Reduce your repository size with Git](../project/repository/repository_size.md#methods-to-reduce-repository-size).
- [Purchase additional storage](https://about.gitlab.com/pricing/licensing-faq/#can-i-buy-more-storage).

{{< alert type="note" >}}

`git push` and GitLab project imports are limited to 5 GiB for each request through
Cloudflare. Imports other than a file upload are not affected by
this limit. Repository limits apply to both public and private projects.

{{< /alert >}}

## Backups

To back up an entire project on GitLab.com, you can export it:

- [Through the UI](../project/settings/import_export.md).
- [Through the API](../../api/project_import_export.md#schedule-an-export). You
  can also use the API to programmatically upload exports to a storage platform,
  such as Amazon S3.

With exports, be aware of
[what is and is not included](../project/settings/import_export.md#project-items-that-are-exported)
in a project export.

To back up the Git repository of a project or wiki, clone it to another computer.
All files [uploaded to a wiki after August 22, 2020](../project/wiki/_index.md#create-a-new-wiki-page)
are included when you clone a repository.

## CI/CD

GitLab.com uses these [GitLab CI/CD](../../ci/_index.md) settings.
Any settings or feature limits not listed here use the defaults listed in
the related documentation:

| Setting                                                                          | GitLab.com                                                                                                 | Default (GitLab Self-Managed) |
|----------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|------------------------|
| Artifacts maximum size (compressed)                                              | 1 GB                                                                                                       | See [Maximum artifacts size](../../administration/settings/continuous_integration.md#set-maximum-artifacts-size). |
| Artifacts [expiry time](../../ci/yaml/_index.md#artifactsexpire_in)               | 30 days unless otherwise specified                                                                         | See [Default artifacts expiration](../../administration/settings/continuous_integration.md#set-default-artifacts-expiration). Artifacts created before June 22, 2020 have no expiry. |
| Scheduled Pipeline Cron                                                          | `*/5 * * * *`                                                                                              | See [Pipeline schedules advanced configuration](../../administration/cicd/_index.md#change-maximum-scheduled-pipeline-frequency). |
| Maximum jobs in a single pipeline                                                | `500` for Free tier, `1000` for all trial tiers, `1500` for Premium, and `2000` for Ultimate.              | See [Maximum number of jobs in a pipeline](../../administration/instance_limits.md#maximum-number-of-jobs-in-a-pipeline). |
| Maximum jobs in active pipelines                                                 | `500` for Free tier, `1000` for all trial tiers, `20000` for Premium, and `100000` for Ultimate.           | See [Number of jobs in active pipelines](../../administration/instance_limits.md#number-of-jobs-in-active-pipelines). |
| Maximum CI/CD subscriptions to a project                                         | `2`                                                                                                        | See [Number of CI/CD subscriptions to a project](../../administration/instance_limits.md#number-of-cicd-subscriptions-to-a-project). |
| Maximum number of pipeline triggers in a project                                 | `25000`                                                                                                    | See [Limit the number of pipeline triggers](../../administration/instance_limits.md#limit-the-number-of-pipeline-triggers). |
| Maximum pipeline schedules in projects                                           | `10` for Free tier, `50` for all paid tiers                                                                | See [Number of pipeline schedules](../../administration/instance_limits.md#number-of-pipeline-schedules). |
| Maximum pipelines for each schedule                                                   | `24` for Free tier, `288` for all paid tiers                                                               | See [Limit the number of pipelines created by a pipeline schedule each day](../../administration/instance_limits.md#limit-the-number-of-pipelines-created-by-a-pipeline-schedule-each-day). |
| Maximum number of schedule rules defined for each security policy project        | Unlimited for all paid tiers                                                                               | See [Number of schedule rules defined for each security policy project](../../administration/instance_limits.md#limit-the-number-of-schedule-rules-defined-for-security-policy-project). |
| Scheduled job archiving                                                          | 3 months                                                                                                   | Never. Jobs created before June 22, 2020 were archived after September 22, 2020. |
| Maximum test cases for each [unit test report](../../ci/testing/unit_test_reports.md) | `500000`                                                                                                   | Unlimited.             |
| Maximum registered runners                                                       | Free tier: `50` for each group and `50`for each project<br/>All paid tiers: `1000` for each group and `1000` for each project | See [Number of registered runners for each scope](../../administration/instance_limits.md#number-of-registered-runners-for-each-scope). |
| Limit of dotenv variables                                                        | Free tier: `50`<br>Premium tier: `100`<br>Ultimate tier: `150`                                             | See [Limit dotenv variables](../../administration/instance_limits.md#limit-dotenv-variables). |
| Maximum downstream pipeline trigger rate (for a given project, user, and commit) | `350` each minute                                                                                           | See [Maximum downstream pipeline trigger rate](../../administration/settings/continuous_integration.md#limit-downstream-pipeline-trigger-rate). |
| Maximum number of downstream pipelines in a pipeline's hierarchy tree            | `1000`                                                                                                     | See [Limit pipeline hierarchy size](../../administration/instance_limits.md#limit-pipeline-hierarchy-size). |

## Container registry

| Setting                                | GitLab.com                       | GitLab Self-Managed |
|:---------------------------------------|:---------------------------------|------------------------|
| Domain name                            | `registry.gitlab.com`            |                        |
| IP address                             | `35.227.35.254`                  |                        |
| CDN domain name                        | `cdn.registry.gitlab-static.net` |                        |
| CDN IP address                         | `34.149.22.116`                  |                        |
| Authorization token duration (minutes) | `15`                             | See [increase container registry token duration](../../administration/packages/container_registry.md#increase-token-duration). |

To use the GitLab container registry, Docker clients must have access to:

- The registry endpoint and GitLab.com for authorization.
- Google Cloud Storage or Google Cloud Content Delivery Network to download images.

GitLab.com is fronted by Cloudflare.
For incoming connections to GitLab.com, you must allow CIDR blocks of Cloudflare
([IPv4](https://www.cloudflare.com/ips-v4/) and [IPv6](https://www.cloudflare.com/ips-v6/)).

## Diff display limits

The settings for the display of diff files cannot be changed on GitLab.com.

| Setting                 | Definition                                     | GitLab.com |
|-------------------------|------------------------------------------------|------------|
| Maximum diff patch size | The total size of the entire diff.             | 200 KB |
| Maximum diff files      | The total number of files changed in a diff.   | 3,000 |
| Maximum diff lines      | The total number of lines changed in a diff.   | 100,000 |

[Diff limits can be changed](../../administration/diff_limits.md#configure-diff-limits)
in GitLab Self-Managed.

## Email

Email configuration settings, IP addresses, and aliases.

### Confirmation settings

GitLab.com uses these email confirmation settings:

- [`email_confirmation_setting`](../../administration/settings/sign_up_restrictions.md#confirm-user-email)
  is set to **Hard**.
- [`unconfirmed_users_delete_after_days`](../../administration/moderate_users.md#automatically-delete-unconfirmed-users)
  is set to three days.

### IP addresses

GitLab.com uses [Mailgun](https://www.mailgun.com/) to send emails from the `mg.gitlab.com` domain,
and has its own dedicated IP addresses:

- `23.253.183.236`
- `69.72.35.190`
- `69.72.44.107`
- `159.135.226.146`
- `161.38.202.219`
- `192.237.158.143`
- `192.237.159.239`
- `198.61.254.136`
- `198.61.254.160`
- `209.61.151.122`

The IP addresses for `mg.gitlab.com` are subject to change at any time.

### Service Desk alias

GitLab.com has a mailbox configured for Service Desk with the email address:
`contact-project+%{key}@incoming.gitlab.com`. To use this mailbox, configure the
[custom suffix](../project/service_desk/configure.md#configure-a-suffix-for-service-desk-alias-email) in project
settings.

## Gitaly RPC concurrency limits on GitLab.com

Per-repository Gitaly RPC concurrency and queuing limits are configured for different types of Git
operations, like `git clone`. When these limits are exceeded, a
`fatal: remote error: GitLab is currently unable to handle this request due to load` message is
returned to the client.

For administrator documentation, see
[limit RPC concurrency](../../administration/gitaly/concurrency_limiting.md#limit-rpc-concurrency).

## GitLab Pages

Some settings for [GitLab Pages](../project/pages/_index.md) differ from the
[defaults for GitLab Self-Managed](../../administration/pages/_index.md):

| Setting                                                | GitLab.com |
|--------------------------------------------------------|------------|
| Domain name                                            | `gitlab.io` |
| IP address                                             | `35.185.44.232` |
| Support for custom domains                             | {{< icon name="check-circle" >}} Yes |
| Support for TLS certificates                           | {{< icon name="check-circle" >}} Yes |
| Maximum site size                                      | 1 GB       |
| Number of custom domains for each GitLab Pages website | 150        |

The maximum size of your Pages site depends on the maximum artifact size,
which is part of the [GitLab CI/CD settings](#cicd).

[Rate limits](#rate-limits-on-gitlabcom) also exist for GitLab Pages.

## GitLab.com at scale

In addition to the GitLab Enterprise Edition Linux package install, GitLab.com uses
the following applications and settings to achieve scale. All settings are
publicly available, as [Kubernetes configuration](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com)
or [Chef cookbooks](https://gitlab.com/gitlab-cookbooks).

### Consul

Service discovery:

- [`gitlab-cookbooks` / `gitlab_consul` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab_consul)

### Elastic cluster

We use Elasticsearch and Kibana for part of our monitoring solution:

- [`gitlab-cookbooks` / `gitlab-elk` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-elk)
- [`gitlab-cookbooks` / `gitlab_elasticsearch` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab_elasticsearch)

### Fluentd

We use Fluentd to unify our GitLab logs:

- [`gitlab-cookbooks` / `gitlab_fluentd` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab_fluentd)

### Grafana

For the visualization of monitoring data:

- [`gitlab-cookbooks` / `gitlab-grafana` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-grafana)

### HAProxy

High Performance TCP/HTTP Load Balancer:

- [`gitlab-cookbooks` / `gitlab-haproxy` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-haproxy)

### Prometheus

Prometheus complete our monitoring stack:

- [`gitlab-cookbooks` / `gitlab-prometheus` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-prometheus)

### Sentry

Open source error tracking:

- [`gitlab-cookbooks` / `gitlab-sentry` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab-sentry)

## GitLab-hosted runners

Use GitLab-hosted runners to run your CI/CD jobs on GitLab.com and GitLab Dedicated to seamlessly
build, test, and deploy your application on different environments.

For more information, see [GitLab-hosted runners](../../ci/runners/_index.md).

## Hostname list

Add these hostnames when you configure allow-lists in local HTTP(S) proxies,
or other web-blocking software that governs end-user computers. Pages on
GitLab.com load content from these hostnames:

- `gitlab.com`
- `*.gitlab.com`
- `*.gitlab-static.net`
- `*.gitlab.io`
- `*.gitlab.net`

Documentation and GitLab company pages served over `docs.gitlab.com` and `about.gitlab.com`
also load certain page content directly from common public CDN hostnames.

## Imports

GitLab.com uses settings to limit importing data into GitLab.

### Default import sources

The [import sources](../project/import/_index.md#supported-import-sources) that are available to you by default depend on
which GitLab you use:

- GitLab.com: All available import sources are enabled by default.
- GitLab Self-Managed: No import sources are enabled by default, and must be
  [enabled](../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources).

### Import placeholder user limits

Imports into GitLab.com limit the number of [placeholder users](../project/import/_index.md#placeholder-users)
for each top-level namespace. The limits differ depending on your plan and seat count.
For more information, see the
[table of placeholder user limits for GitLab.com](../project/import/_index.md#placeholder-user-limits).

## IP range

GitLab.com uses the IP ranges `34.74.90.64/28` and `34.74.226.0/24` for traffic from its Web/API
fleet. This whole range is solely allocated to GitLab. Connections from webhooks or
repository mirroring come from these IP addresses. You should allow these connections.

- Incoming connections - GitLab.com is fronted by Cloudflare. For incoming connections to GitLab.com,
  allow CIDR blocks of Cloudflare ([IPv4](https://www.cloudflare.com/ips-v4/) and
  [IPv6](https://www.cloudflare.com/ips-v6/)).

- Outgoing connections from CI/CD runners - We don't provide static IP addresses for outgoing
  connections from CI/CD runners. However, these guidelines can help:
  - Linux GPU-enabled and Linux Arm64 runners are deployed into Google Cloud, in `us-central1`.
  - Other GitLab.com instance runners are deployed into Google Cloud in `us-east1`.
  - macOS runners are hosted on AWS in the `us-east-1` region, with runner managers hosted on Google Cloud.

To configure an IP-based firewall, you must allow both [AWS IP address ranges](https://docs.aws.amazon.com/vpc/latest/userguide/aws-ip-ranges.html) and [Google Cloud IP address ranges](https://cloud.google.com/compute/docs/faq#find_ip_range).

See how to look up [IP address ranges or CIDR blocks for GCP](https://cloud.google.com/compute/docs/faq#find_ip_range).

## Logs on GitLab.com

[Fluentd](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#fluentd)
parses our logs, then sends them to:

- [Stackdriver Logging](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#stackdriver),
  which stores logs long-term in Google Cold Storage (GCS).
- [Cloud Pub/Sub](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#cloud-pubsub),
  which forwards logs to an [Elastic cluster](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#elastic) using [`pubsubbeat`](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#pubsubbeat-vms).

For more information, see our runbooks:

- A [detailed list of what we're logging](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/logging#what-are-we-logging)
- Our [current log retention policies](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/logging#retention)
- A [diagram of our logging infrastructure](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/logging#logging-infrastructure-overview)

### Job logs

By default, GitLab does not expire job logs. Job logs are retained indefinitely,
and can't be configured on GitLab.com to expire. You can erase job logs
[manually with the Jobs API](../../api/jobs.md#erase-a-job) or by
[deleting a pipeline](../../ci/pipelines/_index.md#delete-a-pipeline)

## Maximum number of reviewers and assignees

{{< history >}}

- Maximum assignees [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/368936) in GitLab 15.6.
- Maximum reviewers [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/366485) in GitLab 15.9.

{{< /history >}}

Merge requests enforce these maximums:

- Maximum assignees: 200
- Maximum reviewers: 200

## Merge request limits

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/521970) in GitLab 17.10 [with a flag](../../administration/feature_flags/_index.md) named `merge_requests_diffs_limit`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/521970) in GitLab 17.10.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

GitLab limits each merge request to 1000 [diff versions](../project/merge_requests/versions.md).
Merge requests that reach this limit cannot be updated further. Instead,
close the affected merge request and create a new merge request.

### Diff commits limit

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/527036) in GitLab 17.11 [with a flag](../../administration/feature_flags/_index.md) named `merge_requests_diff_commits_limit`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

GitLab limits each merge request to 1,000,000 (one million) diff commits.
Merge requests that reach this limit cannot be updated further. Instead,
close the affected merge request and create a new merge request.

## Password requirements

GitLab.com sets these requirements for passwords on new accounts and password changes:

- Minimum character length 8 characters.
- Maximum character length 128 characters.
- All characters are accepted. For example, `~`, `!`, `@`, `#`, `$`, `%`, `^`, `&`, `*`, `()`,
  `[]`, `_`, `+`,  `=`, and `-`.

## Group creation

On GitLab.com, [top-level group creation](../../api/groups.md#create-a-group) is not available through the API. It must be performed through the UI.

## Project and group deletion

Settings related to the deletion of projects and groups.

### Delayed group deletion

{{< history >}}

- Delayed group deletion enabled by default for GitLab Premium and GitLab Ultimate in GitLab 16.1.
- [Moved](https://gitlab.com/groups/gitlab-org/-/epics/17208) from GitLab Premium to GitLab Free in 18.0.

{{< /history >}}

Groups are permanently deleted after a seven-day delay.

See how to [view and restore groups marked for deletion](../group/_index.md#restore-a-group).

### Delayed project deletion

{{< history >}}

- Delayed project deletion enabled by default for GitLab Premium and GitLab Ultimate in GitLab 16.1.
- [Moved](https://gitlab.com/groups/gitlab-org/-/epics/17208) from GitLab Premium to GitLab Free in 18.0.

{{< /history >}}

Projects are permanently deleted after a seven-day delay.

See how to [view and restore projects marked for deletion](../project/working_with_projects.md#restore-a-project).

### Dormant project deletion

[Dormant project deletion](../../administration/dormant_project_deletion.md) is disabled on GitLab.com.

## Package registry limits

The [maximum file size](../../administration/instance_limits.md#file-size-limits)
for a package uploaded to the [GitLab package registry](../packages/package_registry/_index.md)
varies by format:

| Package type           | GitLab.com                         |
|------------------------|------------------------------------|
| Conan                  | 5 GB                               |
| Generic                | 5 GB                               |
| Helm                   | 5 MB                               |
| Machine learning model | 10 GB (uploads are capped at 5 GB) |
| Maven                  | 5 GB                               |
| npm                    | 5 GB                               |
| NuGet                  | 5 GB                               |
| PyPI                   | 5 GB                               |
| Terraform              | 1 GB                               |

## Puma

GitLab.com uses the default of 60 seconds for [Puma request timeouts](../../administration/operations/puma.md#change-the-worker-timeout).

## Rate limits on GitLab.com

{{< alert type="note" >}}

See [Rate limits](../../security/rate_limits.md) for administrator
documentation.

{{< /alert >}}

When a request is rate limited, GitLab responds with a `429` status
code. The client should wait before attempting the request again. There
may also be informational headers with this response detailed in
[rate limiting responses](#rate-limiting-responses). Rate limiting responses
for the Projects, Groups, and Users APIs do not include informational headers.

The following table describes the rate limits for GitLab.com:

| Rate limit                                                       | Setting                       |
|:-----------------------------------------------------------------|:------------------------------|
| Protected paths for an IP address                                | 10 requests each minute        |
| Raw endpoint traffic for a project, commit, or file path         | 300 requests each minute       |
| Unauthenticated traffic from an IP address                       | 500 requests each minute       |
| Authenticated API traffic for a user                             | 2,000 requests each minute     |
| Authenticated non-API HTTP traffic for a user                    | 1,000 requests each minute     |
| All traffic from an IP address                                   | 2,000 requests each minute     |
| Issue creation                                                   | 200 requests each minute       |
| Note creation on issues and merge requests                       | 60 requests each minute        |
| Advanced, project, or group search API for an IP address         | 10 requests each minute        |
| GitLab Pages requests for an IP address                          | 1,000 requests every 50 seconds |
| GitLab Pages requests for a GitLab Pages domain                  | 5,000 requests every 10 seconds |
| GitLab Pages TLS connections for an IP address                   | 1,000 requests every 50 seconds |
| GitLab Pages TLS connections for a GitLab Pages domain           | 400 requests every 10 seconds   |
| Pipeline creation requests for a project, user, or commit        | 25 requests each minute        |
| Alert integration endpoint requests for a project                | 3,600 requests every hour       |
| GitLab Duo `aiAction`  requests                                  | 160 requests every 8 hours      |
| [Pull mirroring](../project/repository/mirror/pull.md) intervals | 5 minutes                     |
| API requests from a user to `/api/v4/users/:id`                  | 300 requests every 10 minutes   |
| GitLab package cloud requests for an IP address ([introduced](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/24083) in GitLab 16.11) | 3,000 requests each minute |
| GitLab repository files | 500 requests each minute |
| User followers requests (`/api/v4/users/:id/followers`)            | 100 requests each minute       |
| User following requests (`/api/v4/users/:id/following`)            | 100 requests each minute       |
| User status requests (`/api/v4/users/:user_id/status`)             | 240 requests each minute       |
| User SSH keys requests (`/api/v4/users/:user_id/keys`)             | 120 requests each minute       |
| Single SSH key requests (`/api/v4/users/:id/keys/:key_id`)         | 120 requests each minute       |
| User GPG keys requests (`/api/v4/users/:id/gpg_keys`)              | 120 requests each minute       |
| Single GPG key requests (`/api/v4/users/:id/gpg_keys/:key_id`)     | 120 requests each minute       |
| User projects requests (`/api/v4/users/:user_id/projects`)         | 300 requests each minute       |
| User contributed projects requests (`/api/v4/users/:user_id/contributed_projects`) | 100 requests each minute |
| User starred projects requests (`/api/v4/users/:user_id/starred_projects`) | 100 requests each minute      |
| Projects list requests (`/api/v4/projects`)                        | 2,000 requests every 10 minutes |
| Group projects requests (`/api/v4/groups/:id/projects`)            | 600 requests each minute       |
| Single project requests (`/api/v4/projects/:id`)                   | 400 requests each minute       |
| Groups list requests (`/api/v4/groups`)                            | 200 requests each minute       |
| Single group requests (`/api/v4/groups/:id`)                       | 400 requests each minute       |

More details are available on the rate limits for
[protected paths](#protected-paths-throttle) and
[raw endpoints](../../administration/settings/rate_limits_on_raw_endpoints.md).

GitLab can rate-limit requests at several layers. The rate limits listed here
are configured in the application. These limits are the most
restrictive for each IP address.

### Group and project import by uploading export files

To help avoid abuse, GitLab.com uses rate limits:

- Project and group imports.
- Group and project exports that use files.
- Export downloads.

For more information, see:

- [Project import/export rate limits](../project/settings/import_export.md#rate-limits).
- [Group import/export rate limits](../project/settings/import_export.md#rate-limits-1).

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

GitLab.com responds with HTTP status code `403` for 15 minutes when a single IP address
sends 300 failed authentication requests in a 1-minute period.

This applies only to Git requests and container registry (`/jwt/auth`) requests
(combined).

This limit:

- Is reset by requests that authenticate successfully. For example, 299
  failed authentication requests followed by 1 successful request, followed by
  299 more failed authentication requests, does not trigger a ban.
- Does not apply to JWT requests authenticated by `gitlab-ci-token`.

No response headers are provided.

`git` requests over `https` always send an unauthenticated request first, which for private repositories results in a `401` error.
`git` then attempts an authenticated request with a username, password, or access token (if available).
These requests might lead to a temporary IP block if too many requests are sent simultaneously.
To resolve this issue, use [SSH keys to communicate with GitLab](../ssh.md).

### Non-configurable limits

For more information about non-configurable rate limits used on GitLab.com, see
[non-configurable limits](../../security/rate_limits.md#non-configurable-limits)

### Pagination response headers

For performance reasons, if a query returns more than 10,000 records,
[GitLab excludes some headers](../../api/rest/_index.md#pagination-response-headers).

### Protected paths throttle

If the same IP address sends more than 10 POST requests in a minute to protected paths, GitLab.com
returns a `429` HTTP status code.

See the source below for which paths are protected. They include user creation,
user confirmation, user sign in, and password reset.

[User and IP rate limits](../../administration/settings/user_and_ip_rate_limits.md#response-headers)
includes a list of the headers responded to blocked requests.

See [Protected Paths](../../administration/settings/protected_paths.md) for more details.

### Rate limiting responses

For information on rate limiting responses, see:

- [List of headers on responses to blocked requests](../../administration/settings/user_and_ip_rate_limits.md#response-headers).
- [Customizable response text](../../administration/settings/user_and_ip_rate_limits.md#use-a-custom-rate-limit-response).

### SSH maximum number of connections

GitLab.com defines the maximum number of concurrent, unauthenticated SSH
connections by using the [`MaxStartups` setting](https://man.openbsd.org/sshd_config.5#MaxStartups).
If more than the maximum number of allowed connections occur concurrently, they
are dropped and users get
[an `ssh_exchange_identification` error](../../topics/git/troubleshooting_git.md#ssh_exchange_identification-error).

### Visibility settings

Projects, groups, and snippets have the
[Internal visibility](../public_access.md#internal-projects-and-groups)
setting [disabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/12388).

## Sidekiq

GitLab.com runs [Sidekiq](https://sidekiq.org) as an [external process](../../administration/sidekiq/_index.md)
for Ruby job scheduling.

The current settings are in the
[GitLab.com Kubernetes pod configuration](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/gprd.yaml.gotmpl).

## SSH keys and authentication

Settings related to authentication with SSH. For information about maximum connections,
see [SSH maximum number of connections](#ssh-maximum-number-of-connections).

### Alternative SSH port

GitLab.com can be reached by using a
[different SSH port](https://about.gitlab.com/blog/2016/02/18/gitlab-dot-com-now-supports-an-alternate-git-plus-ssh-port/) for `git+ssh`.

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

### SSH host keys fingerprints

Go to the current instance configuration to see the SSH host key fingerprints on
GitLab.com.

1. Sign in to GitLab.
1. On the left sidebar, select **Help** ({{< icon name="question-o" >}}) > **Help**.
1. On the Help page, select **Check the current instance configuration**.

In the instance configuration, you see the **SSH host key fingerprints**:

| Algorithm        | MD5 (deprecated) | SHA256  |
|------------------|------------------|---------|
| ECDSA            | `f1:d0:fb:46:73:7a:70:92:5a:ab:5d:ef:43:e2:1c:35` | `SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw` |
| ED25519          | `2e:65:6a:c8:cf:bf:b2:8b:9a:bd:6d:9f:11:5c:12:16` | `SHA256:eUXGGm1YGsMAS7vkcx6JOJdOGHPem5gQp4taiCfCLB8` |
| RSA              | `b6:03:0e:39:97:9e:d0:e7:24:ce:a3:77:3e:01:42:09` | `SHA256:ROQFvPThGrW4RuWLoL9tq9I9zJ42fK4XywyRtbOz/EQ` |

The first time you connect to a GitLab.com repository, one of these keys is
displayed in the output.

### SSH key restrictions

GitLab.com uses the default [SSH key restrictions](../../security/ssh_keys_restrictions.md).

### SSH `known_hosts` entries

To skip manual fingerprint confirmation in SSH, add the following to `.ssh/known_hosts`:

```plaintext
gitlab.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf
gitlab.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsj2bNKTBSpIYDEGk9KxsGh3mySTRgMtXL583qmBpzeQ+jqCMRgBqB98u3z++J1sKlXHWfM9dyhSevkMwSbhoR8XIq/U0tCNyokEi/ueaBMCvbcTHhO7FcwzY92WK4Yt0aGROY5qX2UKSeOvuP4D6TPqKF1onrSzH9bx9XUf2lEdWT/ia1NEKjunUqu1xOB/StKDHMoX4/OKyIzuS0q/T1zOATthvasJFoPrAjkohTyaDUz2LN5JoH839hViyEG82yB+MjcFV5MU3N1l1QL3cVUCh93xSaua1N85qivl+siMkPGbO5xR/En4iEY6K2XPASUEMaieWVNTRCtJ4S8H+9
gitlab.com ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBFSMqzJeV9rUzU4kWitGjeR4PWSa29SPqJ1fVkhtj3Hw9xjLVXVYrU9QlYWrOLXBpQ6KWjbjTDTdDkoohFzgbEY=
```

## Webhooks

The following limits apply for [webhooks](../project/integrations/webhooks.md).

### Rate limits

For each top-level namespace, the number of times each minute that a webhook can be called.
The limit varies depending on your plan and the number of seats in your subscription.

| Plan                                                   | Default for GitLab.com |
|--------------------------------------------------------|------------------------|
| GitLab Free                                            | `500`                  |
| GitLab Premium, `99` seats or fewer                    | `1,600`                |
| GitLab Premium, `100-399` seats                        | `2,800`                |
| GitLab Premium, `400` seats or more                    | `4,000`                |
| GitLab Ultimate and open source, `999` seats or fewer  | `6,000`                |
| GitLab Ultimate and open source, `1,000-4,999` seats   | `9,000`                |
| GitLab Ultimate and open source, `5,000` seats or more | `13,000`               |

### Security policy limits

The maximum number of policies that you can add to a security policy project. These limits apply to each policy type individually. For example, you can have five merge request approval policies and five scan execution policies in the same security policy project.

| Policy type                                            | Default limit                             |
|--------------------------------------------------------|-------------------------------------------|
| Merge request approval policies                        | Five policies per security policy project |
| Scan execution policies                                | Five policies per security policy project |
| Pipeline execution policies                            | Five policies per security policy project |
| Vulnerability management policies                      | Five policies per security policy project |

### Other limits

| Setting                                                             | Default for GitLab.com |
|:--------------------------------------------------------------------|:-----------------------|
| Number of webhooks                                                  | 100 for each project, 50 for each group (subgroup webhooks are not counted towards parent group limits ) |
| Maximum payload size                                                | 25 MB                  |
| Timeout                                                             | 10 seconds             |
| [Parallel Pages deployments](../project/pages/parallel_deployments.md#limits) | 100 extra deployments (Premium tier), 500 extra deployments (Ultimate tier) |

For GitLab Self-Managed instance limits, see:

- [Webhook rate limit](../../administration/instance_limits.md#webhook-rate-limit).
- [Number of webhooks](../../administration/instance_limits.md#number-of-webhooks).
- [Webhook timeout](../../administration/instance_limits.md#webhook-timeout).
- [Parallel Pages deployments](../../administration/instance_limits.md#number-of-parallel-pages-deployments)..
