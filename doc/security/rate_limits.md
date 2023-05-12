---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference, howto
---

# Rate limits **(FREE SELF)**

NOTE:
For GitLab.com, see
[GitLab.com-specific rate limits](../user/gitlab_com/index.md#gitlabcom-specific-rate-limits).

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

## Configurable limits

You can set these rate limits in the Admin Area of your instance:

- [Import/Export rate limits](../user/admin_area/settings/import_export_rate_limits.md)
- [Issue rate limits](../user/admin_area/settings/rate_limit_on_issues_creation.md)
- [Note rate limits](../user/admin_area/settings/rate_limit_on_notes_creation.md)
- [Protected paths](../user/admin_area/settings/protected_paths.md)
- [Raw endpoints rate limits](../user/admin_area/settings/rate_limits_on_raw_endpoints.md)
- [User and IP rate limits](../user/admin_area/settings/user_and_ip_rate_limits.md)
- [Package registry rate limits](../user/admin_area/settings/package_registry_rate_limits.md)
- [Git LFS rate limits](../user/admin_area/settings/git_lfs_rate_limits.md)
- [Files API rate limits](../user/admin_area/settings/files_api_rate_limits.md)
- [Deprecated API rate limits](../user/admin_area/settings/deprecated_api_rate_limits.md)
- [GitLab Pages rate limits](../administration/pages/index.md#rate-limits)
- [Pipeline rate limits](../user/admin_area/settings/rate_limit_on_pipelines_creation.md)
- [Incident management rate limits](../user/admin_area/settings/incident_management_rate_limits.md)
- [Unauthenticated access to Projects List API rate limits](../user/admin_area/settings/rate_limit_on_projects_api.md)

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

For configuration information, see
[Omnibus GitLab configuration options](https://docs.gitlab.com/omnibus/settings/configuration.html#configure-a-failed-authentication-ban).

## Non-configurable limits

### Git operations using SSH

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/78373) in GitLab 14.7 [with a flag](../administration/feature_flags.md) named `rate_limit_gitlab_shell`. Available by default without a feature flag from 15.8.

GitLab applies rate limits to Git operations that use SSH by user account and project. When the rate limit is exceeded, GitLab rejects
further connection requests from that user for the project.

The rate limit applies at the Git command ([plumbing](https://git-scm.com/book/en/v2/Git-Internals-Plumbing-and-Porcelain)) level.
Each command has a rate limit of 600 per minute. For example:

- `git push` has a rate limit of 600 per minute.
- `git pull` has its own rate limit of 600 per minute.

Because the same commands are shared by `git-upload-pack`, `git pull`, and `git clone`, they share a rate limit.

The requests per minute threshold for this rate limit is not configurable. Self-managed customers can disable this
rate limit.

### Repository archives

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25750) in GitLab 12.9.

A rate limit for [downloading repository archives](../api/repositories.md#get-file-archive) is
available. The limit applies to the project and to the user initiating the download either through
the UI or the API.

The **rate limit** is 5 requests per minute per user.

### Webhook Testing

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/commit/35bc85c3ca093fee58d60dacdc9ed1fd9a15adec) in GitLab 13.4.

There is a rate limit for [testing webhooks](../user/project/integrations/webhooks.md#test-a-webhook), which prevents abuse of the webhook functionality.

The **rate limit** is 5 requests per minute per user.

### Users sign up

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339151) in GitLab 14.7.

There is a rate limit per IP address on the `/users/sign_up` endpoint. This is to mitigate attempts to misuse the endpoint. For example, to mass
discover usernames or email addresses in use.

The **rate limit** is 20 calls per minute per IP address.

### Update username

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/339152) in GitLab 14.7.

There is a rate limit on how frequently a username can be changed. This is enforced to mitigate misuse of the feature. For example, to mass discover
which usernames are in use.

The **rate limit** is 10 calls per minute per authenticated user.

### Username exists

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29040) in GitLab 14.7.

There is a rate limit for the internal endpoint `/users/:username/exists`, used upon sign up to check if a chosen username has already been taken.
This is to mitigate the risk of misuses, such as mass discovery of usernames in use.

The **rate limit** is 20 calls per minute per IP address.

### Project Jobs API endpoint

There is a rate limit for the endpoint `project/:id/jobs`, which is enforced to reduce timeouts when retrieving jobs.

The **rate limit** is 600 calls per minute per authenticated user.

### AI action

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118010) in GitLab 16.0.

There is a rate limit for the GraphQL `aiAction` mutation, which is enforced to prevent from abusing this endpoint.

The **rate limit** is 160 calls per 8 hours per authenticated user.

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
