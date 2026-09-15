---
stage: Plan
group: Planner Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Pages rate limits
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Changed](https://gitlab.com/groups/gitlab-org/-/work_items/14653) in GitLab 17.3: You can exclude subnets from Pages rate limits.

{{< /history >}}

You can enforce rate limits to help minimize the risk of a Denial of Service (DoS) attack. GitLab Pages
uses a token bucket algorithm to enforce rate limiting. By default,
requests or TLS connections that exceed the specified limits are reported and rejected.

GitLab Pages supports the following types of rate limiting:

- For each `source_ip`: Limits requests or TLS connections from a single client IP address.
- For each `domain`: Limits requests or TLS connections per domain hosted on GitLab Pages. This can be a
  custom domain like `example.com`, or a group domain like `group.gitlab.io`.

HTTP request-based rate limits are enforced using the following settings:

- `rate_limit_source_ip`: Maximum requests per client IP per second. Set to `0` to disable.
- `rate_limit_source_ip_burst`: Maximum requests allowed in an initial burst per client IP, for
  example when a page loads multiple resources simultaneously.
- `rate_limit_domain`: Maximum requests per hosted Pages domain per second. Set to `0` to disable.
- `rate_limit_domain_burst`: Maximum requests allowed in an initial burst per hosted Pages domain.

TLS connection-based rate limits are enforced using the following settings:

- `rate_limit_tls_source_ip`: Maximum TLS connections per client IP per second. Set to `0` to
  disable.
- `rate_limit_tls_source_ip_burst`: Maximum TLS connections allowed in an initial burst per client
  IP.
- `rate_limit_tls_domain`: Maximum TLS connections per hosted Pages domain per second. Set to `0`
  to disable.
- `rate_limit_tls_domain_burst`: Maximum TLS connections allowed in an initial burst per hosted
  Pages domain.

To allow certain IP ranges (subnets) to bypass all rate limits, use `rate_limit_subnets_allow_list`.
For example, `['1.2.3.4/24', '2001:db8::1/32']`. An
[example GitLab Pages chart](https://docs.gitlab.com/charts/charts/gitlab/gitlab-pages/#configure-rate-limits-subnets-allow-list)
is available.

If the client's IP address is IPv6, the limit is applied to the IPv6 prefix with a length of 64,
rather than the entire address.

## Enable HTTP requests rate limits by source IP

To set rate limits in `/etc/gitlab/gitlab.rb`:

1. Add the following:

   ```ruby
   gitlab_pages['rate_limit_source_ip'] = 20.0
   gitlab_pages['rate_limit_source_ip_burst'] = 600
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

## Enable HTTP requests rate limits by domain

To set rate limits in `/etc/gitlab/gitlab.rb`:

1. Add:

   ```ruby
   gitlab_pages['rate_limit_domain'] = 1000
   gitlab_pages['rate_limit_domain_burst'] = 5000
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

## Enable TLS connections rate limits by source IP

To set rate limits in `/etc/gitlab/gitlab.rb`:

1. Add:

   ```ruby
   gitlab_pages['rate_limit_tls_source_ip'] = 20.0
   gitlab_pages['rate_limit_tls_source_ip_burst'] = 600
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

## Enable TLS connections rate limits by domain

To set rate limits in `/etc/gitlab/gitlab.rb`:

1. Add:

   ```ruby
   gitlab_pages['rate_limit_tls_domain'] = 1000
   gitlab_pages['rate_limit_tls_domain_burst'] = 5000
   ```

1. Save the file and [reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) for the changes to take effect.

## Related topics

- [GitLab Pages administration](_index.md)
- [Rate limits](../../rate_limits/_index.md)
