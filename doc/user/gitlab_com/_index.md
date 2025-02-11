---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab.com settings
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

This page contains information about the settings that are used on GitLab.com, available to
[GitLab SaaS](https://about.gitlab.com/pricing/) customers.

See some of these settings on the [instance configuration page](https://gitlab.com/help/instance_configuration) of GitLab.com.

## Email confirmation

GitLab.com has the:

- [`email_confirmation_setting`](../../administration/settings/sign_up_restrictions.md#confirm-user-email)
  setting set to **Hard**.
- [`unconfirmed_users_delete_after_days`](../../administration/moderate_users.md#automatically-delete-unconfirmed-users)
  setting set to three days.

## Password requirements

GitLab.com has the following requirements for passwords on new accounts and password changes:

- Minimum character length 8 characters.
- Maximum character length 128 characters.
- All characters are accepted. For example, `~`, `!`, `@`, `#`, `$`, `%`, `^`, `&`, `*`, `()`,
  `[]`, `_`, `+`,  `=`, and `-`.

## SSH key restrictions

GitLab.com uses the default [SSH key restrictions](../../security/ssh_keys_restrictions.md).

## SSH host keys fingerprints

Go to the current instance configuration to see the SSH host key fingerprints on
GitLab.com.

1. Sign in to GitLab.
1. On the left sidebar, select **Help** (**{question-o}**) > **Help**.
1. On the Help page, select **Check the current instance configuration**.

In the instance configuration, you see the **SSH host key fingerprints**:

| Algorithm        | MD5 (deprecated) | SHA256  |
|------------------|------------------|---------|
| ECDSA            | `f1:d0:fb:46:73:7a:70:92:5a:ab:5d:ef:43:e2:1c:35` | `SHA256:HbW3g8zUjNSksFbqTiUWPWg2Bq1x8xdGUrliXFzSnUw` |
| ED25519          | `2e:65:6a:c8:cf:bf:b2:8b:9a:bd:6d:9f:11:5c:12:16` | `SHA256:eUXGGm1YGsMAS7vkcx6JOJdOGHPem5gQp4taiCfCLB8` |
| RSA              | `b6:03:0e:39:97:9e:d0:e7:24:ce:a3:77:3e:01:42:09` | `SHA256:ROQFvPThGrW4RuWLoL9tq9I9zJ42fK4XywyRtbOz/EQ` |

The first time you connect to a GitLab.com repository, one of these keys is
displayed in the output.

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

### Service Desk alias email address

On GitLab.com, there's a mailbox configured for Service Desk with the email address:
`contact-project+%{key}@incoming.gitlab.com`. To use this mailbox, configure the
[custom suffix](../project/service_desk/configure.md#configure-a-suffix-for-service-desk-alias-email) in project
settings.

## Backups

[See our backup strategy](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/#backups).

To back up an entire project on GitLab.com, you can export it either:

- [Through the UI](../project/settings/import_export.md).
- [Through the API](../../api/project_import_export.md#schedule-an-export). You
  can also use the API to programmatically upload exports to a storage platform,
  such as Amazon S3.

With exports, be aware of [what is and is not](../project/settings/import_export.md#project-items-that-are-exported)
included in a project export.

GitLab is built on Git, so you can back up just the repository of a project by cloning it to another computer.
Similarly, you can clone a project's wiki to back it up. All files
[uploaded after August 22, 2020](../project/wiki/_index.md#create-a-new-wiki-page)
are included when cloning.

## Delayed group deletion

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

After May 08, 2023, all groups have delayed deletion enabled by default.

Groups are permanently deleted after a seven-day delay.

If you are on the Free tier, your groups are immediately deleted, and you will not be able to restore them.

You can [view and restore groups marked for deletion](../group/_index.md#restore-a-group).

## Delayed project deletion

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

After May 08, 2023, all groups have delayed project deletion enabled by default.

Projects are permanently deleted after a seven-day delay.

If you are on the Free tier, your projects are immediately deleted, and you will not be able to restore them.

You can [view and restore projects marked for deletion](../project/working_with_projects.md#restore-a-project).

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

Some settings for [GitLab Pages](../project/pages/_index.md) differ from the
[defaults for self-managed instances](../../administration/pages/_index.md):

| Setting                                           | GitLab.com             |
|:--------------------------------------------------|:-----------------------|
| Domain name                                       | `gitlab.io`            |
| IP address                                        | `35.185.44.232`        |
| Support for custom domains                        | **{check-circle}** Yes |
| Support for TLS certificates                      | **{check-circle}** Yes |
| Maximum site size                                 | 1 GB                   |
| Number of custom domains per GitLab Pages website | 150                    |

The maximum size of your Pages site depends on the maximum artifact size,
which is part of [GitLab CI/CD](#gitlab-cicd).

[Rate limits](#gitlabcom-specific-rate-limits) also exist for GitLab Pages.

## GitLab container registry

| Setting                                | GitLab.com                       | Default (self-managed) |
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

## GitLab CI/CD

Below are the current settings regarding [GitLab CI/CD](../../ci/_index.md).
Any settings or feature limits not listed here are using the defaults listed in
the related documentation.

| Setting                                                                          | GitLab.com                                                                                                 | Default (GitLab Self-Managed) |
|----------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------|------------------------|
| Artifacts maximum size (compressed)                                              | 1 GB                                                                                                       | See [Maximum artifacts size](../../administration/settings/continuous_integration.md#maximum-artifacts-size). |
| Artifacts [expiry time](../../ci/yaml/_index.md#artifactsexpire_in)               | 30 days unless otherwise specified                                                                         | See [Default artifacts expiration](../../administration/settings/continuous_integration.md#default-artifacts-expiration). Artifacts created before June 22, 2020 have no expiry. |
| Scheduled Pipeline Cron                                                          | `*/5 * * * *`                                                                                              | See [Pipeline schedules advanced configuration](../../administration/cicd/_index.md#change-maximum-scheduled-pipeline-frequency). |
| Maximum jobs in active pipelines                                                 | `500` for Free tier, `1000` for all trial tiers, `20000` for Premium, and `100000` for Ultimate.           | See [Number of jobs in active pipelines](../../administration/instance_limits.md#number-of-jobs-in-active-pipelines). |
| Maximum CI/CD subscriptions to a project                                         | `2`                                                                                                        | See [Number of CI/CD subscriptions to a project](../../administration/instance_limits.md#number-of-cicd-subscriptions-to-a-project). |
| Maximum number of pipeline triggers in a project                                 | `25000`                                                                                                    | See [Limit the number of pipeline triggers](../../administration/instance_limits.md#limit-the-number-of-pipeline-triggers). |
| Maximum pipeline schedules in projects                                           | `10` for Free tier, `50` for all paid tiers                                                                | See [Number of pipeline schedules](../../administration/instance_limits.md#number-of-pipeline-schedules). |
| Maximum pipelines per schedule                                                   | `24` for Free tier, `288` for all paid tiers                                                               | See [Limit the number of pipelines created by a pipeline schedule per day](../../administration/instance_limits.md#limit-the-number-of-pipelines-created-by-a-pipeline-schedule-per-day). |
| Maximum number of schedule rules defined for each security policy project        | Unlimited for all paid tiers                                                                               | See [Number of schedule rules defined for each security policy project](../../administration/instance_limits.md#limit-the-number-of-schedule-rules-defined-for-security-policy-project). |
| Scheduled job archiving                                                          | 3 months                                                                                                   | Never. Jobs created before June 22, 2020 were archived after September 22, 2020. |
| Maximum test cases per [unit test report](../../ci/testing/unit_test_reports.md) | `500000`                                                                                                   | Unlimited.             |
| Maximum registered runners                                                       | Free tier: `50` per group and `50` per project<br/>All paid tiers: `1000` per group and `1000` per project | See [Number of registered runners per scope](../../administration/instance_limits.md#number-of-registered-runners-per-scope). |
| Limit of dotenv variables                                                        | Free tier: `50`<br>Premium tier: `100`<br>Ultimate tier: `150`                                             | See [Limit dotenv variables](../../administration/instance_limits.md#limit-dotenv-variables). |
| Maximum downstream pipeline trigger rate (for a given project, user, and commit) | `350` per minute                                                                                           | See [Maximum downstream pipeline trigger rate](../../administration/settings/continuous_integration.md#maximum-downstream-pipeline-trigger-rate). |

## Package registry limits

The [maximum file size](../../administration/instance_limits.md#file-size-limits)
for a package uploaded to the [GitLab package registry](../packages/package_registry/_index.md)
varies by format:

| Package type              | GitLab.com |
|---------------------------|------------|
| Conan                     |  5 GB      |
| Generic                   |  5 GB      |
| Helm                      |  5 MB      |
| Maven                     |  5 GB      |
| npm                       |  5 GB      |
| NuGet                     |  5 GB      |
| PyPI                      |  5 GB      |
| Terraform                 |  1 GB      |
| Machine learning model    | 10 GB      |

## Account and limit settings

GitLab.com has the following account limits enabled. If a setting is not listed,
the default value [is the same as for self-managed instances](../../administration/settings/account_and_limit_settings.md):

| Setting                                                                                                                                                                                                            | GitLab.com default |
|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-------------------|
| [Repository size including LFS](../../administration/settings/account_and_limit_settings.md#repository-size-limit)                                                                                                 | 10 GB              |
| [Maximum import size](../project/settings/import_export.md#import-a-project-and-its-data)                                                                                                                          | 5 GiB              |
| [Maximum export size](../project/settings/import_export.md#export-a-project-and-its-data)                                                                                                                          | 40 GiB              |
| [Maximum remote file size for imports from external object storages](../../administration/settings/import_and_export_settings.md#maximum-remote-file-size-for-imports)                                             | 10 GiB             |
| [Maximum download file size when importing from source GitLab instances by direct transfer](../../administration/settings/import_and_export_settings.md#maximum-download-file-size-for-imports-by-direct-transfer) | 5 GiB              |
| Maximum attachment size                                                                                                                                                                                            | 100 MiB            |
| [Maximum decompressed file size for imported archives](../../administration/settings/import_and_export_settings.md#maximum-decompressed-file-size-for-imported-archives)                                           | 25 GiB             |
| [Maximum push size](../../administration/settings/account_and_limit_settings.md#max-push-size)                                                                                                                     | 5 GiB              |

If you are near or over the repository size limit, you can either:

- [Reduce your repository size with Git](../project/repository/repository_size.md#methods-to-reduce-repository-size).
- [Purchase additional storage](https://about.gitlab.com/pricing/licensing-faq/#can-i-buy-more-storage).

NOTE:
`git push` and GitLab project imports are limited to 5 GiB per request through
Cloudflare. Imports other than a file upload are not affected by
this limit. Repository limits apply to both public and private projects.

## Default import sources

The [import sources](../project/import/_index.md#supported-import-sources) that are available to you by default depend on
which GitLab you use:

- GitLab.com: All available import sources are enabled by default.
- GitLab Self-Managed: No import sources are enabled by default and must be
  [enabled](../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources).

## Import placeholder user limits

The number of [placeholder users](../project/import/_index.md#placeholder-users) created during an import on GitLab.com is limited per top-level namespace. The limits
differ depending on your plan and seat count.
For more information, see the [table of placeholder user limits for GitLab.com](../project/import/_index.md#placeholder-user-limits).

## IP range

GitLab.com uses the IP ranges `34.74.90.64/28` and `34.74.226.0/24` for traffic from its Web/API
fleet. This whole range is solely allocated to GitLab. You can expect connections from webhooks or repository mirroring to come
from those IPs and allow them.

GitLab.com is fronted by Cloudflare. For incoming connections to GitLab.com, you might need to allow CIDR blocks of Cloudflare ([IPv4](https://www.cloudflare.com/ips-v4/) and [IPv6](https://www.cloudflare.com/ips-v6/)).

For outgoing connections from CI/CD runners, we are not providing static IP addresses.
Most GitLab.com instance runners are deployed into Google Cloud in `us-east1`, except _Linux GPU-enabled_ and _Linux Arm64_, hosted in `us-central1`.
You can configure any IP-based firewall by looking up
[IP address ranges or CIDR blocks for GCP](https://cloud.google.com/compute/docs/faq#find_ip_range).
MacOS runners are hosted on AWS with runner managers hosted on Google Cloud. To configure IP-based firewall, you must allow both [AWS IP address ranges](https://docs.aws.amazon.com/vpc/latest/userguide/aws-ip-ranges.html) and [Google Cloud](https://cloud.google.com/compute/docs/faq#find_ip_range).

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

| Setting                                                        | Default for GitLab.com |
|:---------------------------------------------------------------|:-----------------------|
| Number of webhooks                                             | 100 per project, 50 per group (subgroup webhooks are not counted towards parent group limits ) |
| Maximum payload size                                           | 25 MB                  |
| Timeout                                                        | 10 seconds             |
| [Multiple Pages deployments](../project/pages/_index.md#limits) | 100 extra deployments (Premium tier), 500 extra deployments (Ultimate tier) |

For self-managed instance limits, see:

- [Webhook rate limit](../../administration/instance_limits.md#webhook-rate-limit).
- [Number of webhooks](../../administration/instance_limits.md#number-of-webhooks).
- [Webhook timeout](../../administration/instance_limits.md#webhook-timeout).
- [Parallel Pages deployments](../../administration/instance_limits.md#number-of-parallel-pages-deployments).

## GitLab-hosted runners

You can use GitLab-hosted runners to run your CI/CD jobs on GitLab.com and GitLab Dedicated to seamlessly build, test, and deploy your application on different environments.

For more information, see [GitLab-hosted runners](../../ci/runners/_index.md).

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

The following table describes the rate limits for GitLab.com:

| Rate limit                                                       | Setting                       |
|:-----------------------------------------------------------------|:------------------------------|
| Protected paths for an IP address                                | 10 requests per minute        |
| Raw endpoint traffic for a project, commit, or file path         | 300 requests per minute       |
| Unauthenticated traffic from an IP address                       | 500 requests per minute       |
| Authenticated API traffic for a user                             | 2,000 requests per minute     |
| Authenticated non-API HTTP traffic for a user                    | 1,000 requests per minute     |
| All traffic from an IP address                                   | 2,000 requests per minute     |
| Issue creation                                                   | 200 requests per minute       |
| Note creation on issues and merge requests                       | 60 requests per minute        |
| Advanced, project, or group search API for an IP address         | 10 requests per minute        |
| GitLab Pages requests for an IP address                          | 1,000 requests per 50 seconds |
| GitLab Pages requests for a GitLab Pages domain                  | 5,000 requests per 10 seconds |
| GitLab Pages TLS connections for an IP address                   | 1,000 requests per 50 seconds |
| GitLab Pages TLS connections for a GitLab Pages domain           | 400 requests per 10 seconds   |
| Pipeline creation requests for a project, user, or commit        | 25 requests per minute        |
| Alert integration endpoint requests for a project                | 3,600 requests per hour       |
| GitLab Duo `aiAction`  requests                                  | 160 requests per 8 hours      |
| [Pull mirroring](../project/repository/mirror/pull.md) intervals | 5 minutes                     |
| API requests from a user to `/api/v4/users/:id`                  | 300 requests per 10 minutes   |
| GitLab package cloud requests for an IP address ([introduced](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/24083) in GitLab 16.11) | 3,000 requests per minute |
| GitLab repository files | 500 requests per minute |
| User followers requests (`/api/v4/users/:id/followers`)            | 100 requests per minute       |
| User following requests (`/api/v4/users/:id/following`)            | 100 requests per minute       |
| User status requests (`/api/v4/users/:user_id/status`)             | 240 requests per minute       |
| User SSH keys requests (`/api/v4/users/:user_id/keys`)             | 120 requests per minute       |
| Single SSH key requests (`/api/v4/users/:id/keys/:key_id`)         | 120 requests per minute       |
| User GPG keys requests (`/api/v4/users/:id/gpg_keys`)              | 120 requests per minute       |
| Single GPG key requests (`/api/v4/users/:id/gpg_keys/:key_id`)     | 120 requests per minute       |
| User projects requests (`/api/v4/users/:user_id/projects`)         | 300 requests per minute       |
| User contributed projects requests (`/api/v4/users/:user_id/contributed_projects`) | 100 requests per minute |
| User starred projects requests (`/api/v4/users/:user_id/starred_projects`) | 100 requests per minute      |
| Projects list requests (`/api/v4/projects`)                        | 2,000 requests per 10 minutes |
| Group projects requests (`/api/v4/groups/:id/projects`)            | 600 requests per minute       |
| Single project requests (`/api/v4/projects/:id`)                   | 400 requests per minute       |
| Groups list requests (`/api/v4/groups`)                            | 200 requests per minute       |
| Single group requests (`/api/v4/groups/:id`)                       | 400 requests per minute       |

More details are available on the rate limits for
[protected paths](#protected-paths-throttle) and
[raw endpoints](../../administration/settings/rate_limits_on_raw_endpoints.md).

GitLab can rate-limit requests at several layers. The rate limits listed here
are configured in the application. These limits are the most
restrictive per IP address. For more information about the rate limits
for GitLab.com, see
[the documentation in the handbook](https://handbook.gitlab.com/handbook/engineering/infrastructure/rate-limiting).

### Rate limiting responses

For information on rate limiting responses, see:

- [List of headers on responses to blocked requests](../../administration/settings/user_and_ip_rate_limits.md#response-headers).
- [Customizable response text](../../administration/settings/user_and_ip_rate_limits.md#use-a-custom-rate-limit-response).

### Protected paths throttle

GitLab.com responds with HTTP status code `429` to POST requests at protected
paths that exceed 10 requests per **minute** per IP address.

See the source below for which paths are protected. This includes user creation,
user confirmation, user sign in, and password reset.

[User and IP rate limits](../../administration/settings/user_and_ip_rate_limits.md#response-headers)
includes a list of the headers responded to blocked requests.

See [Protected Paths](../../administration/settings/protected_paths.md) for more details.

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

GitLab.com responds with HTTP status code `403` for 15 minutes, if 300 failed
authentication requests were received in a 1-minute period from a single IP address.

This applies only to Git requests and container registry (`/jwt/auth`) requests
(combined).

This limit:

- Is reset by requests that authenticate successfully. For example, 299
  failed authentication requests followed by 1 successful request, followed by
  299 more failed authentication requests would not trigger a ban.
- Does not apply to JWT requests authenticated by `gitlab-ci-token`.

No response headers are provided.

`git` requests over `https` always send an unauthenticated request first, which for private repositories results in a `401` error.
`git` then attempts an authenticated request with a username, password, or access token (if available).
These requests might lead to a temporary IP block if too many requests are sent simultaneously.
To resolve this issue, use [SSH keys to communicate with GitLab](../ssh.md).

### Pagination response headers

For performance reasons, if a query returns more than 10,000 records, [GitLab excludes some headers](../../api/rest/_index.md#pagination-response-headers).

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

- [Project import/export rate limits](../project/settings/import_export.md#rate-limits).
- [Group import/export rate limits](../project/settings/import_export.md#rate-limits-1).

### Non-configurable limits

See [non-configurable limits](../../security/rate_limits.md#non-configurable-limits)
for information on rate limits that are not configurable, and therefore also
used on GitLab.com.

## GitLab.com-specific Gitaly RPC concurrency limits

Per-repository Gitaly RPC concurrency and queuing limits are configured for different types of Git operations such as `git clone`. When these limits are exceeded, a `fatal: remote error: GitLab is currently unable to handle this request due to load` message is returned to the client.

For administrator documentation, see [limit RPC concurrency](../../administration/gitaly/concurrency_limiting.md#limit-rpc-concurrency).

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
[deleting a pipeline](../../ci/pipelines/_index.md#delete-a-pipeline).

## GitLab.com at scale

In addition to the GitLab Enterprise Edition Linux package install, GitLab.com uses
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

GitLab.com runs [Sidekiq](https://sidekiq.org) as an [external process](../../administration/sidekiq/_index.md)
for Ruby job scheduling.

The current settings are in the [GitLab.com Kubernetes pod configuration](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/gprd.yaml.gotmpl).
