---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Protected paths
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Rate limiting is a technique that improves the security and durability of a web
application. For more details, see [Rate limits](../../security/rate_limits.md).

You can rate limit (protect) specified paths. For these paths, GitLab responds with HTTP status
code `429` to POST requests that exceed 10 requests per minute per IP address and GET requests that exceed 10 requests per minute per IP address at protected paths.

For example, the following are limited to a maximum 10 requests per minute:

- User sign-in
- User sign-up (if enabled)
- User password reset

After 10 requests, the client must wait 60 seconds before it can try again.

See also:

- List of paths [protected by default](../instance_limits.md#by-protected-path).
- [User and IP rate limits](user_and_ip_rate_limits.md#response-headers)
  for the headers returned to blocked requests.

## Configure protected paths

Throttling of protected paths is enabled by default and can be disabled or
customized.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Network**.
1. Expand **Protected paths**.

Requests that exceed the rate limit are logged in `auth.log`.
