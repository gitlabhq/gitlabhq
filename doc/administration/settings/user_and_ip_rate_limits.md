---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# User and IP rate limits

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

Rate limiting is a common technique used to improve the security and durability
of a web application. For more details, see
[Rate limits](../../security/rate_limits.md).

The following limits are disabled by default:

- [Unauthenticated API requests (per IP)](#enable-unauthenticated-api-request-rate-limit).
- [Unauthenticated web requests (per IP)](#enable-unauthenticated-web-request-rate-limit).
- [Authenticated API requests (per user)](#enable-authenticated-api-request-rate-limit).
- [Authenticated web requests (per user)](#enable-authenticated-web-request-rate-limit).

NOTE:
By default, all Git operations are first tried unauthenticated. Because of this, HTTP Git operations
may trigger the rate limits configured for unauthenticated requests.

NOTE:
[In GitLab 14.8 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/344807),
the rate limits for API requests don't affect requests made by the frontend, as these are always
counted as web traffic.

## Enable unauthenticated API request rate limit

To enable the unauthenticated API request rate limit:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Network**.
1. Expand **User and IP rate limits**.
1. Select **Enable unauthenticated API request rate limit**.

   - Optional. Update the **Maximum unauthenticated API requests per rate limit period per IP** value.
     Defaults to `3600`.
   - Optional. Update the **Unauthenticated rate limit period in seconds** value.
     Defaults to `3600`.

## Enable unauthenticated web request rate limit

To enable the unauthenticated request rate limit:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Network**.
1. Expand **User and IP rate limits**.
1. Select **Enable unauthenticated web request rate limit**.

   - Optional. Update the **Maximum unauthenticated web requests per rate limit period per IP** value.
     Defaults to `3600`.
   - Optional. Update the **Unauthenticated rate limit period in seconds** value.
     Defaults to `3600`.

## Enable authenticated API request rate limit

To enable the authenticated API request rate limit:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Network**.
1. Expand **User and IP rate limits**.
1. Select **Enable authenticated API request rate limit**.

   - Optional. Update the **Maximum authenticated API requests per rate limit period per user** value.
     Defaults to `7200`.
   - Optional. Update the **Authenticated API rate limit period in seconds** value.
     Defaults to `3600`.

## Enable authenticated web request rate limit

To enable the authenticated request rate limit:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Network**.
1. Expand **User and IP rate limits**.
1. Select **Enable authenticated web request rate limit**.

   - Optional. Update the **Maximum authenticated web requests per rate limit period per user** value.
     Defaults to `7200`.
   - Optional. Update the **Authenticated web rate limit period in seconds** value.
     Defaults to `3600`.

## Use a custom rate limit response

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/50693) in GitLab 13.8.

A request that exceeds a rate limit returns a `429` response code and a
plain-text body, which by default is `Retry later`.

To use a custom response:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Network**.
1. Expand **User and IP rate limits**.
1. In the **Plain-text response to send to clients that hit a rate limit** text box,
   add the plain-text response message.

## Maximum authenticated requests to `project/:id/jobs` per minute

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129319) in GitLab 16.5.

To reduce timeouts, the `project/:id/jobs` endpoint has a default [rate limit](../../security/rate_limits.md#project-jobs-api-endpoint) of 600 calls per authenticated user.

To modify the maximum number of requests:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Network**.
1. Expand **User and IP rate limits**.
1. Update the **Maximum authenticated requests to `project/:id/jobs` per minute** value.

## Response headers

> - [Introduced](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/731) in GitLab 13.8, the `RateLimit` headers. `Retry-After` was introduced in an earlier version.

When a client exceeds the associated rate limit, the following requests are
blocked. The server may respond with rate-limiting information allowing the
requester to retry after a specific period of time. These information are
attached into the response headers.

| Header                | Example                         | Description                                                                                                                                                                                                      |
|:----------------------|:--------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `RateLimit-Limit`     | `60`                            | The request quota for the client **each minute**. If the rate limit period set in the Admin Area is different from 1 minute, the value of this header is adjusted to approximately the nearest 60-minute period. |
| `RateLimit-Name`      | `throttle_authenticated_web`    | Name of the throttle blocking the requests.                                                                                                                                                                      |
| `RateLimit-Observed`  | `67`                            | Number of requests associated to the client in the time window.                                                                                                                                                  |
| `RateLimit-Remaining` | `0`                             | Remaining quota in the time window. The result of `RateLimit-Limit` - `RateLimit-Observed`.                                                                                                                     |
| `RateLimit-Reset`     | `1609844400`                    | [Unix time](https://en.wikipedia.org/wiki/Unix_time)-formatted time when the request quota is reset.                                                                                                             |
| `RateLimit-ResetTime` | `Tue, 05 Jan 2021 11:00:00 GMT` | [RFC2616](https://www.rfc-editor.org/rfc/rfc2616#section-3.3.1)-formatted date and time when the request quota is reset.                                                                                            |
| `Retry-After`         | `30`                            | Remaining duration **in seconds** until the quota is reset. This is a [standard HTTP header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After).                                             |

## Use an HTTP header to bypass rate limiting

> - [Introduced](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/622) in GitLab 13.6.

Depending on the needs of your organization, you may want to enable rate limiting
but have some requests bypass the rate limiter.

You can do this by marking requests that should bypass the rate limiter with a custom
header. You must do this somewhere in a load balancer or reverse proxy in front of
GitLab. For example:

1. Pick a name for your bypass header. For example, `Gitlab-Bypass-Rate-Limiting`.
1. Configure your load balancer to set `Gitlab-Bypass-Rate-Limiting: 1` on requests
   that should bypass GitLab rate limiting.
1. Configure your load balancer to either:
   - Erase `Gitlab-Bypass-Rate-Limiting`.
   - Set `Gitlab-Bypass-Rate-Limiting` to a value other than `1` on all requests that
     should be affected by rate limiting.
1. Set the environment variable `GITLAB_THROTTLE_BYPASS_HEADER`.
   - For [Linux package installations](https://docs.gitlab.com/omnibus/settings/environment-variables.html),
     set `'GITLAB_THROTTLE_BYPASS_HEADER' => 'Gitlab-Bypass-Rate-Limiting'` in `gitlab_rails['env']`.
   - For self-compiled installations, set `export GITLAB_THROTTLE_BYPASS_HEADER=Gitlab-Bypass-Rate-Limiting`
     in `/etc/default/gitlab`.

It is important that your load balancer erases or overwrites the bypass
header on all incoming traffic. Otherwise, you must trust your
users to not set that header and bypass the GitLab rate limiter.

The bypass works only if the header is set to `1`.

Requests that bypassed the rate limiter because of the bypass header
are marked with `"throttle_safelist":"throttle_bypass_header"` in
[`production_json.log`](../logs/index.md#production_jsonlog).

To disable the bypass mechanism, make sure the environment variable
`GITLAB_THROTTLE_BYPASS_HEADER` is unset or empty.

## Allow specific users to bypass authenticated request rate limiting

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49127) in GitLab 13.7.

Similarly to the bypass header described above, it is possible to allow
a certain set of users to bypass the rate limiter. This only applies
to authenticated requests: with unauthenticated requests, by definition
GitLab does not know who the user is.

The allowlist is configured as a comma-separated list of user IDs in
the `GITLAB_THROTTLE_USER_ALLOWLIST` environment variable. If you want
users 1, 53 and 217 to bypass the authenticated request rate limiter,
the allowlist configuration would be `1,53,217`.

- For [Linux package installations](https://docs.gitlab.com/omnibus/settings/environment-variables.html),
  set `'GITLAB_THROTTLE_USER_ALLOWLIST' => '1,53,217'` in `gitlab_rails['env']`.
- For self-compiled installations, set `export GITLAB_THROTTLE_USER_ALLOWLIST=1,53,217`
  in `/etc/default/gitlab`.

Requests that bypassed the rate limiter because of the user allowlist
are marked with `"throttle_safelist":"throttle_user_allowlist"` in
[`production_json.log`](../logs/index.md#production_jsonlog).

At application startup, the allowlist is logged in [`auth.log`](../logs/index.md#authlog).

## Try out throttling settings before enforcing them

> - [Introduced](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/629) in GitLab 13.6.

You can try out throttling settings by setting the `GITLAB_THROTTLE_DRY_RUN` environment variable to
a comma-separated list of throttle names.

The possible names are:

- `throttle_unauthenticated`
  - [Deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/335300) in GitLab 14.3. Use `throttle_unauthenticated_api` or `throttle_unauthenticated_web` instead.
    `throttle_unauthenticated` is still supported and selects both of them.
- `throttle_unauthenticated_api`
- `throttle_unauthenticated_web`
- `throttle_authenticated_api`
- `throttle_authenticated_web`
- `throttle_unauthenticated_protected_paths`
- `throttle_authenticated_protected_paths_api`
- `throttle_authenticated_protected_paths_web`
- `throttle_unauthenticated_packages_api`
- `throttle_authenticated_packages_api`
- `throttle_authenticated_git_lfs`
- `throttle_unauthenticated_files_api`
- `throttle_authenticated_files_api`
- `throttle_unauthenticated_deprecated_api`
- `throttle_authenticated_deprecated_api`

For example, to try out throttles for all authenticated requests to
non-protected paths can be done by setting
`GITLAB_THROTTLE_DRY_RUN='throttle_authenticated_web,throttle_authenticated_api'`.

To enable dry run mode for all throttles, the variable can be set to `*`.

Setting a throttle to dry run mode logs a message to the
[`auth.log`](../logs/index.md#authlog) when it would hit the limit, while letting the
request continue. The log message contains an `env` field set to `track`. The `matched`
field contains the name of throttle that was hit.

It is important to set the environment variable **before** enabling
the rate limiting in the settings. The settings in the Admin Area
take effect immediately, while setting the environment variable
requires a restart of all the Puma processes.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
