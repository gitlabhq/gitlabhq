---
type: reference, howto
---

# Rate limits

NOTE: **Note:**
For GitLab.com, please see
[GitLab.com-specific rate limits](../user/gitlab_com/index.md#gitlabcom-specific-rate-limits).

Rate limiting is a common technique used to improve the security and durability
of a web application.

For example, a simple script can make thousands of web requests per second.
Whether malicious, apathetic, or just a bug, your application and infrastructure
may not be able to cope with the load. For more details, see
[Denial-of-service attack](https://en.wikipedia.org/wiki/Denial-of-service_attack).
Most cases can be mitigated by limiting the rate of requests from a single IP address.

Most [brute-force attacks](https://en.wikipedia.org/wiki/Brute-force_attack) are
similarly mitigated by a rate limit.

## Admin Area settings

- [User and IP rate limits](../user/admin_area/settings/user_and_ip_rate_limits.md).
- [Rate limits on raw endpoints](../user/admin_area/settings/rate_limits_on_raw_endpoints.md)

## Rack Attack initializer

This method of rate limiting is cumbersome, but has some advantages. It allows
throttling of specific paths, and is also integrated into Git and container
registry requests. See [Rack Attack initializer](rack_attack.md).
