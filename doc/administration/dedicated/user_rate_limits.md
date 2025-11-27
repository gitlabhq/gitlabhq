---
stage: GitLab Dedicated
group: Environment Automation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Authenticated user rate limits for GitLab Dedicated, default limits by reference architecture, and handling strategies.
title: Authenticated user rate limits
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Dedicated

{{< /details >}}

GitLab Dedicated automatically enforces authenticated user rate limits to ensure
system stability and help maintain performance for all users on your instance.
Rate limits prevent any single user or service account from generating
excessive alerts or causing widespread instance degradation.

When a user exceeds their rate limit, GitLab returns a `429 Too Many Requests`
HTTP status code with a plain-text response of `Retry later`.

For more information, see [rate limits](../../security/rate_limits.md).

## Rate limits by request type

Rate limits apply to all authenticated users, including regular users and service accounts.
GitLab automatically sets these limits based on your reference architecture size. Limits apply separately to API and web requests:

- API requests: REST and GraphQL API calls, including requests from integrations, CI/CD jobs, and automation scripts.
- Web requests: Requests made through the GitLab UI.

| Reference architecture | API requests per minute | Web requests per minute |
| ---------------------- | ----------------------- | ----------------------- |
| 1,000 users            | 1,200                   | 120                     |
| 2,000 users            | 2,400                   | 240                     |
| 3,000 users            | 3,600                   | 360                     |
| 5,000 users            | 6,000                   | 600                     |
| 10,000 users           | 12,000                  | 1,200                   |
| 25,000 users           | 30,000                  | 3,000                   |
| 50,000 users           | 60,000                  | 6,000                   |

For more information, see [reference architectures](../reference_architectures/_index.md).

## Configuration and management

Rate limits are automatically configured and managed by GitLab.

You cannot:

- Modify rate limit values.
- Disable rate limiting.
- Configure custom rate limits through the Admin area.
- Access rate limiting settings in the UI.

GitLab manages these settings to ensure optimal performance and stability for your instance.

## Response headers

GitLab includes rate limit information in response headers for all requests.
You can use these headers to monitor your current usage and remaining quota.

For more information about which rate limits include response headers and the available headers, see
[multiple rate limiting systems](../../administration/settings/user_and_ip_rate_limits.md#multiple-rate-limiting-systems).

## Improve request efficiency

To work more effectively with rate limits:

1. Optimize request patterns:

   - Add delays between requests in automated scripts.
   - Combine API requests when possible.
   - Use GraphQL to fetch only the data you need.
   - Implement efficient pagination for large datasets.

1. Audit and optimize high-volume usage:

   - Review the users or service accounts that make the most requests.
   - Review CI/CD jobs that make excessive API calls.
   - Review integrations that connect to your GitLab instance.
   - Update automated processes to stay below rate limit thresholds.
