---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Bans that block a client after repeated failed authentication requests.
title: Abuse and failed authentication bans
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Some protections block a client for a period of time instead of slowing requests down.

## Failed authentication ban for Git and container registry

By default, GitLab returns HTTP status code `403` for 1 hour, if 10 failed authentication requests
were received in a 1-minute period from a single IP address. All three values are configurable.
This applies only to combined:

- Git requests.
- Container registry (`/jwt/auth`) requests.

This limit:

- Is reset by requests that authenticate successfully, until a ban starts. For example, 9 failed
  authentication requests followed by 1 successful request, followed by 9 more failed
  authentication requests would not trigger a ban.
- Cannot be cleared by authenticating once a ban has started. The ban is checked before the
  credentials are, so a banned IP receives `403` even with valid credentials, until the ban expires.
- Does not apply to JWT requests authenticated by `gitlab-ci-token`.
- Is disabled by default.

No response headers are provided.

To avoid being rate limited, you can:

- Stagger the execution of your automated pipelines.
- Configure [exponential back off and retry](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html) for failed authentication attempts.
- Use a documented process and [best practice](https://about.gitlab.com/blog/access-token-lifetime-limits/#how-to-minimize-the-impact) to manage token expiry.

For configuration information, see
[Linux package configuration options](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-failed-authentication-ban).

## Troubleshooting

### Rack Attack is denylisting the load balancer

Rack Attack may block your load balancer if all traffic appears to come from
the load balancer. In that case, you must:

1. [Configure `nginx[real_ip_trusted_addresses]`](https://docs.gitlab.com/omnibus/settings/nginx/#configure-gitlab-trusted-proxies-and-nginx-real_ip-module).
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

1. The denylist is stored in the rate limiting Redis instance, so you must open up `redis-cli`
   against it. On an installation that does not separate instances, this is the default Redis:

   ```shell
   /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket
   ```

   If you have configured `gitlab_rails['redis_rate_limiting_instance']`, connect to that instance
   instead. Deleting the key from the wrong instance appears to succeed and leaves the ban in place.

1. You can remove the block using the following syntax, replacing `<ip>` with
   the actual IP that is denylisted:

   ```plaintext
   del cache:gitlab:rack::attack:allow2ban:ban:<ip>
   ```

1. Confirm that the key with the IP no longer shows up:

   ```plaintext
   keys *rack::attack*
   ```

   By default, the [`keys` command is disabled](https://docs.gitlab.com/omnibus/settings/redis/#renamed-commands).

1. Optionally, add [the IP to the allowlist](https://docs.gitlab.com/omnibus/settings/configuration/#configure-a-failed-authentication-ban)
   to prevent it being denylisted again.
