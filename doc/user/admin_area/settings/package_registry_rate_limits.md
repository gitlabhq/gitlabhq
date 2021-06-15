---
stage: Package
group: Package
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Package Registry Rate Limits **(FREE SELF)**

Rate limiting is a common technique used to improve the security and durability of a web
application. For more details, see [Rate limits](../../../security/rate_limits.md). General user and
IP rate limits can be enforced from the top bar at
**Menu > Admin > Settings > Network > User and IP rate limits**.
For more details, see [User and IP rate limits](user_and_ip_rate_limits.md).

With the [GitLab Package Registry](../../packages/package_registry/index.md),
you can use GitLab as a private or public registry for a variety of common package managers. You can
publish and share packages, which others can consume as a dependency in downstream projects through
the [Packages API](../../../api/packages.md).

When downloading such dependencies in downstream projects, many requests are made through the
Packages API. You may therefore reach enforced user and IP rate limits. To address this issue, you
can define specific rate limits for the Packages API in
**Menu > Admin > Settings > Network > Package Registry Rate Limits**:

- Unauthenticated Packages API requests
- Authenticated Packages API requests

These limits are disabled by default. When enabled, they supersede the general user and IP rate
limits for requests to the Packages API. You can therefore keep the general user and IP rate limits,
and increase (if necessary) the rate limits for the Packages API.

Besides this precedence, there are no differences in functionality compared to the general user and
IP rate limits. For more details, see [User and IP rate limits](user_and_ip_rate_limits.md).
