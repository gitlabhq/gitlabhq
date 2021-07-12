---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference, howto
---

# Rate limits **(FREE SELF)**

NOTE:
For GitLab.com, please see
[GitLab SaaS-specific rate limits](../user/gitlab_com/index.md#gitlab-saas-specific-rate-limits).

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

These are rate limits you can set in the Admin Area of your instance:

- [Import/Export rate limits](../user/admin_area/settings/import_export_rate_limits.md)
- [Issues rate limits](../user/admin_area/settings/rate_limit_on_issues_creation.md)
- [Notes rate limits](../user/admin_area/settings/rate_limit_on_notes_creation.md)
- [Protected paths](../user/admin_area/settings/protected_paths.md)
- [Raw endpoints rate limits](../user/admin_area/settings/rate_limits_on_raw_endpoints.md)
- [User and IP rate limits](../user/admin_area/settings/user_and_ip_rate_limits.md)
- [Package registry rate limits](../user/admin_area/settings/package_registry_rate_limits.md)

## Non-configurable limits

### Repository archives

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25750) in GitLab 12.9.

There is a rate limit for [downloading repository archives](../api/repositories.md#get-file-archive),
which applies to the project and to the user initiating the download either through the UI or the API.

The **rate limit** is 5 requests per minute per user.

### Webhook Testing

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/commit/35bc85c3ca093fee58d60dacdc9ed1fd9a15adec) in GitLab 13.4.

There is a rate limit for [testing webhooks](../user/project/integrations/webhooks.md#testing-webhooks), which prevents abuse of the webhook functionality.

The **rate limit** is 5 requests per minute per user.

## Rack Attack initializer

This method of rate limiting is cumbersome, but has some advantages. It allows
throttling of specific paths, and is also integrated into Git and container
registry requests. See [Rack Attack initializer](rack_attack.md).
