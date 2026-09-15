---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configure rate limits for specific GitLab API endpoints.
title: API rate limits
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Most API requests count against the [general user and IP rate limits](../../administration/settings/user_and_ip_rate_limits.md).
For some APIs, you can configure a separate rate limit instead.
An API rate limit supersedes the general limits for requests to that API.
You can raise or lower the limit for a single API without changing the general limits.
No other behavior changes.

To configure these limits, go to the **Admin** area and select **Settings** > **Network**.

## Available API rate limits

| API | Description |
|:----|:------------|
| [Audit events API](../../administration/settings/rate-limit-on-audit-events-api.md) | Limit requests that retrieve instance audit events. |
| [Deprecated endpoints](deprecated.md) | Restrict endpoints that have replacements but cannot be removed without breaking backward compatibility. |
| [Groups API](groups.md) | Limit requests that list, retrieve, create, and archive groups, and that list and delete group members. |
| [Organizations API](organizations.md) | Limit requests that create organizations. |
| [Package registry](package-registry.md) | Limit requests to the Packages API, which downstream projects call to resolve dependencies. |
| [Projects API](projects.md) | Limit requests that list, retrieve, and create projects, and that list and delete project members. |
| [Repository files API](repository-files.md) | Limit requests that fetch, create, update, and delete files in a repository. |
| [Users API](users.md) | Limit requests that read the followers, status, SSH keys, and GPG keys of a user. |

## Related topics

- [Rate limits](../_index.md)
- [Non-configurable rate limits](../non_configurable.md)
- [REST API](../../api/rest/_index.md)
