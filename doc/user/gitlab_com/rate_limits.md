---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Learn about the rate limits that apply to GitLab.com, including the limits proposed for each subscription plan.
title: GitLab.com rate limits
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

The following rate limits apply to GitLab.com.

GitLab Self-Managed and GitLab Dedicated instances have their own limits, which the operator
of the instance controls. If you do not use GitLab.com, see
[rate limits](../../rate_limits/_index.md) or
[authenticated user rate limits](../../administration/dedicated/user_rate_limits.md) instead.

## Rate limits by plan

> [!note]
> The limits in this section are proposed and are not in effect yet. The limits in
> [current rate limits](#current-rate-limits) apply today and continue to apply after these
> changes take effect. GitLab announces specific dates in advance. Before a limit is enforced,
> GitLab runs scheduled brownout windows, when the new limit is briefly active so you can see how
> the new limit affects your workloads.

Rate limits are becoming tier-aware. Instead of a single number for everyone, limits reflect your
plan and apply for each user. Authenticated requests receive your plan's full allowance. Anonymous
requests receive a much lower allowance, in line with similar platforms.

Each plan has two limits for authenticated traffic, and the sustained limit takes precedence:

- A sustained limit, measured each hour. Use this number to plan your usage.
- A burst limit, measured each minute. GitLab sets this default so a short spike does not consume
  an entire hourly allowance at once.

For steady work, you reach the sustained limit first. Sending requests at the burst limit for a
full hour would exceed the sustained limit on every plan. Treat the burst limit as a ceiling for
short spikes, not a rate you can maintain.

Requests at the burst limit reach the sustained limit in approximately 50 minutes in Free,
12 minutes in Premium, and 12.5 minutes in Ultimate.

These limits apply to API requests, web requests, and authenticated Git over HTTPS requests.
Unauthenticated Git over HTTPS requests do not count against the unauthenticated limit. They
stay subject to the [current limit for an IP address](#current-rate-limits).

### Sustained limits

| Rate limit                                 | Free            | Premium          | Ultimate         |
| ------------------------------------------ | --------------- | ---------------- | ---------------- |
| Authenticated traffic for a user           | 5,000 each hour | 15,000 each hour | 25,000 each hour |
| Unauthenticated traffic from an IP address | 60 each hour    | 60 each hour     | 60 each hour     |

### Burst limits

| Rate limit                       | Free            | Premium           | Ultimate          |
| -------------------------------- | --------------- | ----------------- | ----------------- |
| Authenticated traffic for a user | 100 each minute | 1,250 each minute | 2,000 each minute |

## When you exceed a limit

When a request is rate limited, GitLab responds with a `429 Too Many Requests` status code. Wait
before you attempt the request again.

Responses to throttled requests include a `Retry-After` header that tells you how many seconds
remain until your quota resets, and a `RateLimit-ResetTime` header with the same information as a
date and time. All responses, throttled or not, include `RateLimit-Limit`, `RateLimit-Remaining`,
and related headers that you can use to track your usage before you reach a limit. For the full
list, see
[response headers](../../administration/settings/user_and_ip_rate_limits.md#response-headers).

To handle limits correctly:

- Wait for the duration given in `Retry-After` before you retry.
- Back off exponentially if you continue to be throttled.
- Monitor `RateLimit-Remaining` and slow down before you exhaust your quota.

Rate limiting responses for the Projects, Groups, and Users APIs do not include informational
headers. Response headers also do not reflect some other limits, so you can receive a `429`
response even when the headers on your previous response showed remaining quota.

## If you need more headroom

If you reach a limit regularly, you have several options, from least to most committed:

1. Optimize how you use the API. Batch requests, cache responses, use pagination, and honor the
   `Retry-After` header. Most usage stays below the limits.
1. Authenticate your requests. Anonymous traffic receives the lowest allowance. Authenticating
   with a [personal access token, an OAuth token, or a CI/CD job token](../../api/rest/authentication.md)
   gives you your plan's full limits.
1. Upgrade your plan. Premium and Ultimate carry higher limits.

For sustained needs above your plan's limits, an option to purchase additional headroom is in
design. Details are published closer to availability.

## Current rate limits

These limits are in effect on GitLab.com today, and they continue to apply after
[rate limits by plan](#rate-limits-by-plan) are introduced.

GitLab checks your plan's limits first, then the limits in this table. Whichever limit is lower
applies. A limit in this table can be lower than your plan's limit, so you might reach it first.

For example, authenticated API traffic for a user is limited to 2,000 requests each minute. On
Free and Premium, the burst limit for your plan is lower, so you reach that first. On Ultimate,
the burst limit is also 2,000 requests each minute, so the two limits are the same.

| Rate limit                                                                                                    | Setting                         |
| ------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| Protected paths for an IP address                                                                             | 10 requests each minute         |
| Sign-in attempts (`POST /users/sign_in`) for an IP address                                                    | 10 requests every 5 minutes     |
| Raw endpoint traffic for a project, commit, or file path                                                      | 300 requests each minute        |
| Unauthenticated raw endpoint traffic for a project                                                            | 800 requests each minute        |
| Unauthenticated traffic from an IP address                                                                    | 500 requests each minute        |
| Authenticated API traffic for a user                                                                          | 2,000 requests each minute      |
| Authenticated non-API HTTP traffic for a user                                                                 | 1,000 requests each minute      |
| Authenticated Git HTTPS traffic for a user                                                                    | 10,000 requests each minute     |
| Unauthenticated Git HTTPS traffic from an IP address                                                          | 15,000 requests each minute     |
| Git SSH operations for a user, project, and Git command                                                       | 600 operations each minute      |
| All traffic from an IP address                                                                                | 2,000 requests each minute      |
| Issue creation                                                                                                | 200 requests each minute        |
| Note creation on issues and merge requests                                                                    | 60 requests each minute         |
| Advanced, project, or group search API for an IP address                                                      | 100 requests each minute        |
| Advanced, project, or group search API for a user                                                             | 100 requests each minute        |
| GitLab Pages requests for an IP address                                                                       | 1,000 requests every 50 seconds |
| GitLab Pages requests for a GitLab Pages domain                                                               | 5,000 requests every 10 seconds |
| GitLab Pages TLS connections for an IP address                                                                | 1,000 requests every 50 seconds |
| GitLab Pages TLS connections for a GitLab Pages domain                                                        | 400 requests every 10 seconds   |
| Pipeline creation requests for a project, user, or commit                                                     | 25 requests each minute         |
| Pipeline creation requests for a user                                                                         | 2,000 requests each minute      |
| Alert integration endpoint requests for a project                                                             | 3,600 requests every hour       |
| GitLab Duo `aiAction` requests                                                                                | 160 requests every 8 hours      |
| [Pull mirroring](../project/repository/mirror/pull.md) intervals                                              | 5 minutes                       |
| API requests from a user to `/api/v4/users/:id`                                                               | 300 requests every 10 minutes   |
| GitLab package hosting system requests for an IP address                                                      | 1,000 requests each minute      |
| Repository files API requests (`GET /api/v4/projects/:id/repository/files/*`) for an IP address and file path | 500 requests each minute        |
| User followers requests (`/api/v4/users/:id/followers`)                                                       | 100 requests each minute        |
| User following requests (`/api/v4/users/:id/following`)                                                       | 100 requests each minute        |
| User status requests (`/api/v4/users/:user_id/status`)                                                        | 240 requests each minute        |
| User SSH keys requests (`/api/v4/users/:user_id/keys`)                                                        | 120 requests each minute        |
| Single SSH key requests (`/api/v4/users/:id/keys/:key_id`)                                                    | 120 requests each minute        |
| User GPG keys requests (`/api/v4/users/:id/gpg_keys`)                                                         | 120 requests each minute        |
| Single GPG key requests (`/api/v4/users/:id/gpg_keys/:key_id`)                                                | 120 requests each minute        |
| User projects requests (`/api/v4/users/:user_id/projects`)                                                    | 300 requests each minute        |
| User contributed projects requests (`/api/v4/users/:user_id/contributed_projects`)                            | 100 requests each minute        |
| User starred projects requests (`/api/v4/users/:user_id/starred_projects`)                                    | 100 requests each minute        |
| Projects list requests (`/api/v4/projects`)                                                                   | 2,000 requests every 10 minutes |
| Unauthenticated projects list requests (`/api/v4/projects`) from an IP address                                | 400 requests every 10 minutes   |
| Group projects requests (`/api/v4/groups/:id/projects`)                                                       | 600 requests each minute        |
| Single project requests (`/api/v4/projects/:id`)                                                              | 400 requests each minute        |
| Groups list requests (`/api/v4/groups`)                                                                       | 50 requests each minute         |
| Single group requests (`/api/v4/groups/:id`)                                                                  | 400 requests each minute        |
| Runner jobs requests using a runner token (`/api/v4/jobs/request`)                                            | 2,000 requests each minute      |
| Runner jobs requests using a runner token from an IP address (`/api/v4/jobs/request`)                         | 2,400 requests each minute      |
| Runner job trace patch requests using a job token (`/api/v4/jobs/trace`)                                      | 200 requests each minute        |
| Runner jobs requests using a job token (`/api/v4/jobs/*`)                                                     | 200 requests each minute        |
| List all project members in a project                                                                         | 200 requests each minute        |

More details are available on the rate limits for
[protected paths](#protected-paths-throttle) and
[raw endpoints](../../administration/settings/rate_limits_on_raw_endpoints.md).

GitLab can rate-limit requests at several layers. These limits are the most
restrictive for each IP address.

## Service Desk email rate limit

GitLab.com limits by plan the number of outbound Service Desk notification emails
a top-level group can send each hour and each day:

| Plan                                   | Hourly limit | Daily limit |
| -------------------------------------- | ------------ | ----------- |
| Free, Premium trial, Ultimate trial    | 100          | 700         |
| Open Source                            | 1,500        | 10,000      |
| Premium                                | 5,000        | 50,000      |
| Ultimate, Ultimate trial paid customer | Unlimited    | Unlimited   |

For details, see
[Service Desk email rate limit](../../administration/instance_limits.md#service-desk-email-rate-limit).

## Group and project import by uploading export files

To help avoid abuse, GitLab.com applies rate limits to:

- Project and group imports.
- Group and project exports that use files.
- Export downloads.

For more information, see:

- [Project import/export rate limits](../project/settings/import_export.md#rate-limits).
- [Group import/export rate limits](../project/settings/import_export.md#rate-limits-1).

## IP blocks

IP blocks can occur when GitLab.com receives unusual traffic from a single IP address that the
system views as potentially malicious. These blocks can be based on rate limit settings. After the
unusual traffic ceases, GitLab automatically releases the IP address. The release timing depends
on the type of block, as described in the following section.

If you receive a `403 Forbidden` error for all requests to GitLab.com, check for any automated
processes that might be triggering a block. For assistance, contact
[GitLab Support](https://support.gitlab.com) with details, such as the affected IP address.

### Git and container registry failed authentication ban

GitLab.com responds with a `403 Forbidden` status code for 15 minutes when a single IP address
sends 300 failed authentication requests in a one-minute period.

This response applies only to Git requests and container registry (`/jwt/auth`) requests (combined).

This limit:

- Is reset by requests that authenticate successfully. For example, 299 failed authentication
  requests followed by a successful request, followed by 299 more failed authentication requests,
  does not trigger a ban.
- Does not apply to JWT requests authenticated by `gitlab-ci-token`.

No response headers are provided.

Git requests over HTTPS always send an unauthenticated request first, which for private
repositories results in a `401 Unauthorized` error. Git then attempts an authenticated request
with a username, password, or access token, if available. These requests might lead to a
temporary IP block if too many requests are sent simultaneously. To resolve this issue, use
[SSH keys to communicate with GitLab](../ssh.md).

## Non-configurable limits

For more information about non-configurable rate limits used on GitLab.com, see
[non-configurable limits](../../rate_limits/non_configurable.md).

## Pagination response headers

For performance reasons, if a query returns more than 10,000 records,
[GitLab excludes some headers](../../api/rest/_index.md#pagination-response-headers).

## Protected paths throttle

If the same IP address sends more than 10 POST requests in a minute to protected paths, GitLab.com
returns a `429 Too Many Requests` status code.

Protected paths include user creation, user confirmation, user sign-in, and password reset. For
the full list, see [protected paths](../../administration/settings/protected_paths.md).

For the headers GitLab includes on blocked requests, see
[user and IP rate limits](../../administration/settings/user_and_ip_rate_limits.md#response-headers).

## SSH maximum number of connections

GitLab.com defines the maximum number of concurrent, unauthenticated SSH connections by using the
[`MaxStartups` setting](https://man.openbsd.org/sshd_config.5#MaxStartups). If more than the
maximum number of allowed connections occur concurrently, GitLab drops the excess connections.
Users then get
[an `ssh_exchange_identification` error](../../topics/git/troubleshooting_git.md#ssh_exchange_identification-error).

## Related topics

- [GitLab.com settings](_index.md)
- [Rate limits](../../rate_limits/_index.md)
- [Rate limits on Git operations](../../rate_limits/git.md)
- [REST API authentication](../../api/rest/authentication.md)
