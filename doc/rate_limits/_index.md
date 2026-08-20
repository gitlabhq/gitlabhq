---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Protect the stability and security of your instance with rate limits on requests to GitLab.
title: Rate limits
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> For GitLab.com, see
> [GitLab.com-specific rate limits](../user/gitlab_com/_index.md#rate-limits-on-gitlabcom).
>
> For GitLab Dedicated, see
> [Authenticated user rate limits](../administration/dedicated/user_rate_limits.md).

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

> [!note]
> The rate limits for API requests do not affect requests made by the frontend, because these requests are always counted as web traffic.

## Configuration options

You can set most rate limits in the **Admin** area, and a few only through the API or the
Rails console.

### Admin area

You can set these rate limits in the **Admin** area of your instance:

- [Import/Export rate limits](../administration/settings/import_export_rate_limits.md)
- [Issue rate limits](../administration/settings/rate_limit_on_issues_creation.md)
- [Note rate limits](../administration/settings/rate_limit_on_notes_creation.md)
- [Protected paths](../administration/settings/protected_paths.md)
- [Raw endpoints rate limits](../administration/settings/rate_limits_on_raw_endpoints.md)
- [User and IP rate limits](../administration/settings/user_and_ip_rate_limits.md)
- [Package registry rate limits](../administration/settings/package_registry_rate_limits.md)
- [Rate limits on Git operations](git.md)
- [Files API rate limits](../administration/settings/files_api_rate_limits.md)
- [Deprecated API rate limits](../administration/settings/deprecated_api_rate_limits.md)
- [GitLab Pages rate limits](../administration/pages/_index.md#rate-limits)
- [Pipeline rate limits](../administration/cicd/limits.md#pipeline-creation-rate-limits)
- [Incident management rate limits](../administration/settings/incident_management_rate_limits.md)
- [Projects API rate limits](../administration/settings/rate_limit_on_projects_api.md)
- [Groups API rate limits](../administration/settings/rate_limit_on_groups_api.md)
- [Users API rate limits](../administration/settings/rate_limit_on_users_api.md)
- [Organizations API rate limits](../administration/settings/rate_limit_on_organizations_api.md)
- [Webhook operations rate limits](../administration/settings/rate-limit-on-webhook-operations.md)

### API and Rails console

You can set these rate limits with the [application settings API](../api/settings.md):

- [Autocomplete users rate limit](../administration/instance_limits.md#autocomplete-users-rate-limit)
- [AI action](../api/settings.md#available-settings) (`ai_action_api_rate_limit`): 160 calls per
  8 hours per authenticated user. Applies to the GraphQL `aiAction` mutation.

You can set this rate limit with the [plan limits API](../api/plan_limits.md) or the
[Rails console](../administration/operations/rails_console.md#starting-a-rails-console-session):

- [Webhook rate limit](../administration/instance_limits.md#webhook-rate-limit)

## Non-configurable limits

Some rate limits cannot be configured.
For a list of these limits, see [non-configurable rate limits](non_configurable.md).

## Bans and blocks

Some protections block a client for a period of time instead of slowing requests down.
For more information, see [abuse and failed authentication bans](abuse_bans.md).

## Related topics

- [GitLab application limits](../administration/instance_limits.md)
- [CI/CD limits](../administration/cicd/limits.md)
