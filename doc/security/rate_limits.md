---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Rate limits
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

NOTE:
For GitLab.com, see
[GitLab.com-specific rate limits](../user/gitlab_com/_index.md#gitlabcom-specific-rate-limits).

Rate limiting is a common technique used to improve the security and durability
of a web application.

For example, a simple script can make thousands of web requests per second. The requests could be:

- Malicious.
- Apathetic.
- Just a bug.

Your application and infrastructure may not be able to cope with the load. For more details, see
[Denial-of-service attack](https://en.wikipedia.org/wiki/Denial-of-service_attack).
Most cases can be mitigated by limiting the rate of requests from a single IP address.

Most [brute-force attacks](https://en.wikipedia.org/wiki/Brute-force_attack) are
similarly mitigated by a rate limit.

NOTE:
The rate limits for API requests do not affect requests made by the frontend, because these requests are always counted as web traffic.

## Configurable limits

You can set these rate limits in the **Admin** area of your instance:

- [Import/Export rate limits](../administration/settings/import_export_rate_limits.md)
- [Issue rate limits](../administration/settings/rate_limit_on_issues_creation.md)
- [Note rate limits](../administration/settings/rate_limit_on_notes_creation.md)
- [Protected paths](../administration/settings/protected_paths.md)
- [Raw endpoints rate limits](../administration/settings/rate_limits_on_raw_endpoints.md)
- [User and IP rate limits](../administration/settings/user_and_ip_rate_limits.md)
- [Package registry rate limits](../administration/settings/package_registry_rate_limits.md)
- [Git LFS rate limits](../administration/settings/git_lfs_rate_limits.md)
- [Rate limits on Git SSH operations](../administration/settings/rate_limits_on_git_ssh_operations.md)
- [Files API rate limits](../administration/settings/files_api_rate_limits.md)
- [Deprecated API rate limits](../administration/settings/deprecated_api_rate_limits.md)
- [GitLab Pages rate limits](../administration/pages/_index.md#rate-limits)
- [Pipeline rate limits](../administration/settings/rate_limit_on_pipelines_creation.md)
- [Incident management rate limits](../administration/settings/incident_management_rate_limits.md)
- [Projects API rate limits](../administration/settings/rate_limit_on_projects_api.md)
- [Groups API rate limits](../administration/settings/rate_limit_on_groups_api.md)
- [Organizations API rate limits](../administration/settings/rate_limit_on_organizations_api.md)

You can set these rate limits using the Rails console:

- [Webhook rate limit](../administration/instance_limits.md#webhook-rate-limit)

## Failed authentication ban for Git and container registry

GitLab returns HTTP status code `403` for 1 hour, if 30 failed authentication requests were received
in a 3-minute period from a single IP address. This applies only to combined:

- Git requests.
- Container registry (`/jwt/auth`) requests.

This limit:

- Is reset by requests that authenticate successfully. For example, 29 failed authentication
  requests followed by 1 successful request, followed by 29 more failed authentication requests
  would not trigger a ban.
- Does not apply to JWT requests authenticated by `gitlab-ci-token`.
- Is disabled by default.

No response headers are provided.

To avoid being rate limited, you can:

- Stagger the execution of your automated pipelines.
- Configure [exponential back off and retry](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html) for failed authentication attempts.
- Use a documented process and [best practice](https://about.gitlab.com/blog/2023/10/25/access-token-lifetime-limits/#how-to-minimize-the-impact) to manage token expiry.

For configuration information, see
[Omnibus GitLab configuration options](https://docs.gitlab.com/omnibus/settings/configuration.html#configure-a-failed-authentication-ban).

## Non-configurable limits

> - Rate limit on the `:user_id/status`, `:id/following`, `:id/followers`, `:user_id/keys`, `id/keys/:key_id`, `:id/gpg_keys`, and `:id/gpg_keys/:key_id` endpoints [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/452349) in GitLab 17.1 [with a flag](../administration/feature_flags.md) named `rate_limiting_user_endpoints`. Disabled by default.

FLAG:
The availability of multiple endpoints in this feature is controlled by a feature flag.
For more information, see the history.
These endpoints are available for testing, but not ready for production use.

### Repository archives

A rate limit for [downloading repository archives](../api/repositories.md#get-file-archive) is
available. The limit applies to the project and to the user initiating the download either through
the UI or the API.

The **rate limit** is 5 requests per minute per user.

### Webhook Testing

There is a rate limit for [testing webhooks](../user/project/integrations/webhooks.md#test-a-webhook), which prevents abuse of the webhook functionality.

The **rate limit** is 5 requests per minute per user.

### Users sign up

There is a rate limit per IP address on the `/users/sign_up` endpoint. This is to mitigate attempts to misuse the endpoint. For example, to mass
discover usernames or email addresses in use.

The **rate limit** is 20 calls per minute per IP address.

### User status

There is a rate limit per IP address on the `:user_id/status` endpoint. This is to mitigate attempts to misuse the endpoint.

The **rate limit** is 240 calls per minute per IP address.

### User following

There is a rate limit per IP address on the `:id/following` endpoint. This is to mitigate attempts to misuse the endpoint.

The **rate limit** is 100 calls per minute per IP address.

### User followers

There is a rate limit per IP address on the `:id/followers` endpoint. This is to mitigate attempts to misuse the endpoint.

The **rate limit** is 100 calls per minute per IP address.

### User keys

There is a rate limit per IP address on the `:user_id/keys` endpoint. This is to mitigate attempts to misuse the endpoint.

The **rate limit** is 120 calls per minute per IP address.

### User specific key

There is a rate limit per IP address on the `id/keys/:key_id` endpoint. This is to mitigate attempts to misuse the endpoint.

The **rate limit** is 120 calls per minute per IP address.

### User GPG keys

There is a rate limit per IP address on the `:id/gpg_keys` endpoint. This is to mitigate attempts to misuse the endpoint.

The **rate limit** is 120 calls per minute per IP address.

### User specific GPG keys

There is a rate limit per IP address on the `:id/gpg_keys/:key_id` endpoint. This is to mitigate attempts to misuse the endpoint.

The **rate limit** is 120 calls per minute per IP address.

### Update username

There is a rate limit on how frequently a username can be changed. This is enforced to mitigate misuse of the feature. For example, to mass discover
which usernames are in use.

The **rate limit** is 10 calls per minute per authenticated user.

### Username exists

There is a rate limit for the internal endpoint `/users/:username/exists`, used upon sign up to check if a chosen username has already been taken.
This is to mitigate the risk of misuses, such as mass discovery of usernames in use.

The **rate limit** is 20 calls per minute per IP address.

### Project Jobs API endpoint

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/382985) in GitLab 15.7 [with a flag](../administration/feature_flags.md) named `ci_enforce_rate_limits_jobs_api`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/384186) in GitLab 16.0. Feature flag `ci_enforce_rate_limits_jobs_api` removed.

There is a rate limit for the endpoint `project/:id/jobs`, which is enforced to reduce timeouts when retrieving jobs.

The **rate limit** defaults to 600 calls per authenticated user. You can [configure the rate limit](../administration/settings/user_and_ip_rate_limits.md).

### AI action

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118010) in GitLab 16.0.

There is a rate limit for the GraphQL `aiAction` mutation, which is enforced to prevent from abusing this endpoint.

The **rate limit** is 160 calls per 8 hours per authenticated user.

### Delete a member using the API

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118296) in GitLab 16.0.

There is a rate limit for [removing project or group members using the API endpoints](../api/members.md#remove-a-member-from-a-group-or-project) `/groups/:id/members` or `/project/:id/members`.

The **rate limit** is 60 deletions per minute.

### Notification emails

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/439101) in GitLab 17.1 [with a flag](../administration/feature_flags.md) named `rate_limit_notification_emails`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/439101) in GitLab 17.2. Feature flag `rate_limit_notification_emails` removed.

There is a rate limit for notification emails related to a project or group.

The **rate limit** is 1,000 notifications per 24 hours per project or group per user.

### FogBugz import

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/439101) in GitLab 17.6.

There is a rate limit for triggering project imports from FogBugz.

The **rate limit** is 1 triggered import per minute per user.

### Commit diff files

This is a rate limit for expanded commit diff files (`/[group]/[project]/-/commit/[:sha]/diff_files?expanded=1`),
which is enforced to prevent from abusing this endpoint.

The **rate limit** is 6 requests per minute per user (authenticated) or per IP address (unauthenticated).

### Changelog generation

There is a rate limit per user per project on the `:id/repository/changelog` endpoint. This is to mitigate attempts to misuse the endpoint.
The rate limit is shared between GET and POST actions.

The **rate limit** is 5 calls per minute per user per project.

## Troubleshooting

### Rack Attack is denylisting the load balancer

Rack Attack may block your load balancer if all traffic appears to come from
the load balancer. In that case, you must:

1. [Configure `nginx[real_ip_trusted_addresses]`](https://docs.gitlab.com/omnibus/settings/nginx.html#configuring-gitlab-trusted_proxies-and-the-nginx-real_ip-module).
   This keeps users' IPs from being listed as the load balancer IPs.
1. Allowlist the load balancer's IP addresses.
1. Reconfigure GitLab:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Remove blocked IPs from Rack Attack with Redis

To remove a blocked IP:

1. Find the IPs that have been blocked in the production log:

   ```shell
   grep "Rack_Attack" /var/log/gitlab/gitlab-rails/auth.log
   ```

1. Since the denylist is stored in Redis, you must open up `redis-cli`:

   ```shell
   /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket
   ```

1. You can remove the block using the following syntax, replacing `<ip>` with
   the actual IP that is denylisted:

   ```plaintext
   del cache:gitlab:rack::attack:allow2ban:ban:<ip>
   ```

1. Confirm that the key with the IP no longer shows up:

   ```plaintext
   keys *rack::attack*
   ```

   By default, the [`keys` command is disabled](https://docs.gitlab.com/omnibus/settings/redis.html#renamed-commands).

1. Optionally, add [the IP to the allowlist](https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-rack-attack)
   to prevent it being denylisted again.
