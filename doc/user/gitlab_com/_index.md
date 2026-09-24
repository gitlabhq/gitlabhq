---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab.com settings
description: Configuration for the GitLab.com instance.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

These settings are used on GitLab.com, and are available to
[GitLab.com](https://about.gitlab.com/pricing/) customers.

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
| [Maximum download file size when importing from source GitLab instances by direct transfer](../../administration/settings/import_and_export_settings.md#maximum-download-file-size-for-imports-by-direct-or-offline-transfer) | 5 GiB              |
| Maximum attachment size                                                                                                                                                                                            | 100 MiB            |
| [Maximum decompressed file size for imported archives](../../administration/settings/import_and_export_settings.md#maximum-decompressed-file-size-for-imported-archives)                                           | 25 GiB             |
| [Maximum push size](../../administration/settings/account_and_limit_settings.md#max-push-size)                                                                                                                     | 5 GiB              |

If you are near or over the repository size limit, you can:

- [Reduce your repository size with Git](../project/repository/repository_size.md#methods-to-reduce-repository-size).
- [Purchase additional storage](https://about.gitlab.com/pricing/licensing-faq/#can-i-buy-more-storage).

> [!note]
> `git push` and GitLab project imports are limited to 5 GiB for each request through
> Cloudflare. Imports other than a file upload are not affected by
> this limit. Repository limits apply to both public and private projects.

## Backups

To back up an entire project on GitLab.com, you can export it:

- [Through the UI](../project/settings/import_export.md).
- [Through the API](../../api/project_import_export.md#export-a-project). You
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
|----------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|-------------------------------|
| Artifacts maximum size (compressed)                                              | 1 GB                                                                                                       | See [Maximum artifacts size](../../administration/cicd/limits.md#maximum-artifacts-size). |
| Artifacts [expiry time](../../ci/yaml/_index.md#artifactsexpire_in)              | 30 days unless otherwise specified                                                                         | See [Default artifacts expiration](../../administration/settings/continuous_integration.md#set-default-artifacts-expiration). Artifacts created before June 22, 2020 have no expiry. |
| Security scan [finding](../application_security/detect/security_scanning_results.md) retention   | 30 days                                                                                                    | See [Security scan retention period](../../administration/settings/security_and_compliance.md#security-scan-retention-period). |
| Scheduled Pipeline Cron                                                          | `*/5 * * * *`                                                                                              | See [Pipeline schedules advanced configuration](../../administration/cicd/limits.md#maximum-scheduled-pipeline-frequency). |
| Maximum jobs in a single pipeline                                                | `500` for Free tier, `1000` for all trial tiers, `1500` for Premium, and `2000` for Ultimate.              | See [Maximum number of jobs in a pipeline](../../administration/cicd/limits.md#maximum-number-of-jobs-in-a-pipeline). |
| Maximum jobs in active pipelines                                                 | `500` for Free tier, `1000` for all trial tiers, `20000` for Premium, and `60000` for Ultimate.            | See [Number of jobs in active pipelines](../../administration/cicd/limits.md#number-of-jobs-in-active-pipelines). |
| Maximum CI/CD subscriptions to a project                                         | `2`                                                                                                        | See [Number of CI/CD subscriptions to a project](../../administration/cicd/limits.md#number-of-cicd-subscriptions-to-a-project). |
| Maximum number of pipeline triggers in a project                                 | `25000`                                                                                                    | See [Limit the number of pipeline triggers](../../administration/cicd/limits.md#limit-the-number-of-pipeline-triggers). |
| Maximum pipeline schedules in projects                                           | `10` for Free tier, `50` for all paid tiers                                                                | See [Number of pipeline schedules](../../administration/cicd/limits.md#number-of-pipeline-schedules). |
| Maximum pipelines for each schedule                                              | `24` for Free tier, `288` for all paid tiers                                                               | See [Limit the number of pipelines created by a pipeline schedule each day](../../administration/cicd/limits.md#limit-the-number-of-pipelines-created-by-a-pipeline-schedule-each-day). |
| Maximum number of schedule rules defined for each security policy project        | Unlimited for all paid tiers                                                                               | See [Number of schedule rules defined for each security policy project](../../administration/cicd/limits.md#limit-the-number-of-schedule-rules-defined-for-security-policy-project). |
| [Pipeline archival](../../administration/settings/continuous_integration.md#archive-pipelines) | 1 year                                                                                       | Never. Jobs created before June 22, 2020 were archived after September 22, 2020. |
| Maximum test cases for each [unit test report](../../ci/testing/unit_test_reports.md) | `500000`                                                                                              | Unlimited.                    |
| Maximum registered runners                                                       | Free tier: `50` for each group and `50`for each project<br/>All paid tiers: `1000` for each group and `1000` for each project | See [Number of registered runners for each scope](../../administration/cicd/limits.md#number-of-registered-runners-for-groups-and-projects). |
| Limit of dotenv variables                                                        | Free tier: `50`<br>Premium tier: `100`<br>Ultimate tier: `150`                                             | See [Limit dotenv variables](../../administration/cicd/limits.md#limit-dotenv-variables). |
| Maximum downstream pipeline trigger rate (for a given project, user, and commit) | `350` each minute                                                                                          | See [Maximum downstream pipeline trigger rate](../../administration/cicd/limits.md#limit-downstream-pipeline-trigger-rate). |
| Maximum pipeline cancellation rate per pipeline (for a given user) | `5` each minute   | See [Pipeline cancellation rate limits](../../administration/cicd/limits.md#pipeline-cancellation-rate-limits). |
| Maximum pipeline cancellation rate per project (for a given user)  | `120` each minute | See [Pipeline cancellation rate limits](../../administration/cicd/limits.md#pipeline-cancellation-rate-limits). |
| Maximum pipeline retry rate per pipeline (for a given user) | `5` each minute   | See [Pipeline retry rate limits](../../administration/cicd/limits.md#pipeline-retry-rate-limits). |
| Maximum pipeline retry rate per project (for a given user)  | `200` each minute | See [Pipeline retry rate limits](../../administration/cicd/limits.md#pipeline-retry-rate-limits). |
| Maximum number of downstream pipelines in a pipeline's hierarchy tree            | `1000`                                                                                                     | See [Limit pipeline hierarchy size](../../administration/cicd/limits.md#limit-pipeline-hierarchy-size). |
| Maximum number of pipeline creation requests per project, commit, and user (per minute) | `25`                                                                                                | See [pipeline creation rate limits](../../administration/cicd/limits.md#pipeline-creation-rate-limits). |

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
- Google Cloud Storage (see [IP ranges that Google makes available to users on the internet](https://knowledge.workspace.google.com/admin/security/obtain-google-ip-address-ranges)) or Google Cloud Content Delivery Network to download images.

GitLab.com is fronted by Cloudflare.
For incoming connections to GitLab.com, you must allow CIDR blocks of Cloudflare
([IPv4](https://www.cloudflare.com/ips-v4/) and [IPv6](https://www.cloudflare.com/ips-v6/)).

## Diff display limits

The settings for the display of diff files cannot be changed on GitLab.com. These limits
apply to both the GitLab UI and API endpoints.

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

A fetch or clone operation is concurrent when the operation starts before a previous operation finishes.

| Operation               | GitLab.com limit         |
|:------------------------|:-------------------------|
| HTTP fetches and clones | 60 concurrent operations |
| SSH fetches and clones  | 30 concurrent operations |

For administrator documentation, see
[limit RPC concurrency](../../administration/gitaly/concurrency_limiting.md#limit-rpc-concurrency).

## GitLab Pages

Some settings for [GitLab Pages](../project/pages/_index.md) differ from the
[defaults for GitLab Self-Managed](../../administration/pages/_index.md):

| Setting                                                | GitLab.com |
|--------------------------------------------------------|------------|
| Domain name                                            | `gitlab.io` |
| IP address                                             | `35.185.44.232` |
| Support for custom domains                             | {{< yes >}} |
| Support for TLS certificates                           | {{< yes >}} |
| Maximum site size                                      | 1 GB       |
| Number of custom domains for each GitLab Pages website | 150        |

The maximum size of your Pages site depends on the maximum artifact size,
which is part of the [GitLab CI/CD settings](#cicd).

[Rate limits](rate_limits.md#current-rate-limits) also exist for GitLab Pages.

## GitLab.com at scale

In addition to the GitLab Enterprise Edition Linux package install, GitLab.com uses
the following applications and settings to achieve scale. All settings are
publicly available, as [Kubernetes configuration](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com)
or [Chef cookbooks](https://gitlab.com/gitlab-cookbooks).

### Consul

Service discovery:

- [`gitlab-cookbooks` / `gitlab_consul` · GitLab](https://gitlab.com/gitlab-cookbooks/gitlab_consul)

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

Prometheus completes our monitoring stack:

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

### Container registry hostname list

Add these additional hostnames to your allow-lists if you pull images from `registry.gitlab.com`:

- `*.storage.googleapis.com`
- `*.cdn.registry.gitlab-static.net`

## Imports

GitLab.com uses settings to limit importing data into GitLab.

### Default import sources

The [import sources](../import/_index.md) (migration tools) that are available to you by default depend on
which GitLab you use:

- GitLab.com: All available import sources are enabled by default.
- GitLab Self-Managed: No import sources are enabled by default, and must be
  [enabled](../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources).

### Import placeholder user limits

Imports into GitLab.com limit the number of [placeholder users](../import/mapping/post_migration_mapping.md#placeholder-users)
for each top-level namespace. The limits differ depending on your plan and seat count.
For more information, see the
[table of placeholder user limits for GitLab.com](../import/mapping/post_migration_mapping.md#placeholder-user-limits).

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

## Maximum number of reviewers and assignees

Merge requests enforce these maximums:

- Maximum assignees: 200
- Maximum reviewers: 200

## Merge request limits

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/521970) in GitLab 17.10 [with a feature flag](../../administration/feature_flags/_index.md) named `merge_requests_diffs_limit`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/521970) in GitLab 17.10.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/537447) in GitLab 19.0. Feature flag `merge_requests_diffs_limit` removed.

{{< /history >}}

GitLab limits each merge request to 1000 [diff versions](../project/merge_requests/versions.md).
Merge requests that reach this limit cannot be updated further. Instead,
close the affected merge request and create a new merge request.

### Diff commits limit

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/527036) in GitLab 17.11 [with a feature flag](../../administration/feature_flags/_index.md) named `merge_requests_diff_commits_limit`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/537446) in GitLab 19.0. Feature flag `merge_requests_diff_commits_limit` removed.

{{< /history >}}

GitLab limits each merge request to 1,000,000 (one million) diff commits.
Merge requests that reach this limit cannot be updated further. Instead,
close the affected merge request and create a new merge request.

## Password requirements

GitLab.com sets these requirements for passwords on new accounts and password changes:

- Minimum character length 8 characters.
- Maximum character length 128 characters.
- All characters are accepted. For example, `~`, `!`, `@`, `#`, `$`, `%`, `^`, `&`, `*`, `()`,
  `[]`, `_`, `+`, `=`, and `-`.

## Group creation

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/506673) in GitLab 18.0
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/560840) the GitLab SAAS administrator exception in GitLab 18.5

{{< /history >}}

On GitLab.com, [top-level group creation](../../api/groups.md#create-a-group) is only allowed through the UI. Only administrators can use the API to create top-level groups.

## Project and group deletion

Settings related to the deletion of projects and groups.

### Delayed group deletion

{{< history >}}

- [Moved](https://gitlab.com/groups/gitlab-org/-/work_items/17208) from GitLab Premium to GitLab Free in 18.0.
- [Increased deletion period](https://gitlab.com/groups/gitlab-org/-/work_items/17375) from seven days to 30 days in 18.0.2.

{{< /history >}}

Groups are permanently deleted after a 30-day delay.

See how to [view and restore groups marked for deletion](../group/_index.md#restore-a-group).

### Delayed project deletion

{{< history >}}

- [Moved](https://gitlab.com/groups/gitlab-org/-/work_items/17208) from GitLab Premium to GitLab Free in 18.0.
- [Increased deletion period](https://gitlab.com/groups/gitlab-org/-/work_items/17375) from seven-days to 30 days in 18.0.2.

{{< /history >}}

Projects are permanently deleted after a 30-day delay.

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

Rate limits on GitLab.com vary by subscription plan and apply both per user and per top-level
group. Each plan has an hourly limit that governs your usage and a per-minute burst limit, and the
hourly limit takes precedence. Authenticated requests receive your plan's full allowance.

For each plan's limits, when they take effect, and how to handle a `429 Too Many Requests`
response, see [GitLab.com rate limits](rate_limits.md).

## Sidekiq

GitLab.com runs [Sidekiq](https://sidekiq.org) as an [external process](../../administration/sidekiq/_index.md)
for Ruby job scheduling.

The current settings are in the
[GitLab.com Kubernetes pod configuration](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/gprd.yaml.gotmpl).

## SSH keys and authentication

Settings related to authentication with SSH. For information about maximum connections,
see [SSH maximum number of connections](rate_limits.md#ssh-maximum-number-of-connections).

### Alternative SSH port

GitLab.com can be reached by using a
[different SSH port](https://about.gitlab.com/blog/gitlab-dot-com-now-supports-an-alternate-git-plus-ssh-port/) for `git+ssh`.

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
1. In the left sidebar, select **Help** ({{< icon name="question-o" >}}) > **Help**.
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

## Visibility settings

Projects, groups, and snippets have the
[Internal visibility](../public_access.md#internal-projects-and-groups)
setting [disabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/12388).

## Webhooks

The following limits apply for [webhooks](../project/integrations/webhooks.md).

### Rate limits

The number of times each minute that webhooks in a top-level namespace can be called.
All project and group webhooks in the namespace share this limit.
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

When the rate limit is reached, all webhooks in the namespace are temporarily disabled and
automatically re-enabled in the next minute.

When rate limited, a badge appears next to the webhook in the webhook list. On the webhook edit
page, a message states how many times per minute the namespace limit was exceeded and when webhooks
are re-enabled.

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
| Number of webhooks                                                  | 100 for each project, 50 for each group (subgroup webhooks are not counted towards parent group limits) |
| Maximum payload size                                                | 25 MB                  |
| Timeout                                                             | 10 seconds             |
| [Parallel Pages deployments](../project/pages/parallel_deployments.md#limits) | 100 extra deployments (Premium tier), 500 extra deployments (Ultimate tier) |

For GitLab Self-Managed instance limits, see:

- [Webhook rate limit](../../administration/instance_limits.md#webhook-rate-limit).
- [Number of webhooks](../../administration/instance_limits.md#number-of-webhooks).
- [Webhook timeout](../../administration/instance_limits.md#webhook-timeout).
- [Parallel Pages deployments](../../administration/instance_limits.md#number-of-parallel-pages-deployments).
