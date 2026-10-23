---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Rate limits that are fixed in the GitLab application.
title: Non-configurable rate limits
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab enforces the following rate limits in the application.

| Limit                                | Rate limit                                                     | Details |
|:-------------------------------------|:---------------------------------------------------------------|:--------|
| Changelog generation                 | 5 calls per minute per user per project                        | Applies to the `:id/repository/changelog` endpoint. The limit is shared between `GET` and `POST` actions. |
| Commit diff files                    | 6 requests per minute                                          | Applies to expanded commit diff files (`/[group]/[project]/-/commit/[:sha]/diff_files?expanded=1`). The limit applies per user for authenticated requests, and per IP address for unauthenticated requests. |
| Delete a deployment                  | 500 requests per minute per authenticated user                 | Applies to [deleting a deployment](../api/deployments.md#delete-a-deployment) with `DELETE /projects/:id/deployments/:deployment_id`. Reduces the infrastructure impact of mass deployment deletions. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/243738) in GitLab 19.2. |
| FogBugz import                       | 1 triggered import per minute per user                         | Applies to triggering project imports from FogBugz. Introduced in GitLab 17.6. |
| GitHub import                        | 6 triggered imports per minute per user                        | Applies to triggering project imports from GitHub. |
| Group deletion                       | 60 requests per minute per authenticated user                  | Applies to [scheduling a group for deletion](../api/groups.md#schedule-a-group-for-deletion) with `DELETE /groups/:id`. Requests that use `permanently_remove` are limited separately to 10 requests per minute, because they start the deletion immediately. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/263606) in GitLab 19.6 [with a feature flag](../administration/feature_flags/_index.md) named `group_and_project_delete_rate_limit`. Disabled by default. |
| New user accounts                    | 20 calls per minute per IP address                             | Applies to the `/users/sign_up` endpoint. Mitigates attempts to mass discover usernames or email addresses in use. |
| Notification emails                  | 1,000 notifications per 24 hours per project or group per user | Applies to notification emails related to a project or group. [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/439101) in GitLab 17.2. |
| Offline transfer exports and imports | 6 requests per minute per user                                 | Applies to [offline transfer](../user/import/gitlab_instances/offline-transfer-migrations.md) exports and imports, which are limited separately. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209344) in GitLab 19.3. |
| Project deletion                     | 60 requests per minute per authenticated user                  | Applies to [deleting a project](../api/projects.md#delete-a-project) with `DELETE /projects/:id`. Requests that use `permanently_remove` are limited separately to 10 requests per minute, because they start the deletion immediately. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/263603) in GitLab 19.6 [with a feature flag](../administration/feature_flags/_index.md) named `group_and_project_delete_rate_limit`. Disabled by default. |
| Repository archives                  | 5 requests per minute per user                                 | Applies to [downloading repository archives](../api/repositories.md#retrieve-file-archive-from-a-repository) through the UI or the API. The limit applies to the project and to the user who starts the download. |
| Repository blob and file access      | 5 calls per minute per object per project                      | Applies to files larger than 10 MB on the [repository blob](../api/repositories.md#retrieve-a-blob-from-a-repository) and [repository file](../api/repository_files.md#retrieve-a-file-from-a-repository) endpoints. [Introduced](https://gitlab.com/gitlab-org/security/gitlab/-/issues/1302) in GitLab 18.1. |
| Snippet creation                     | 300 requests per hour per authenticated user                   | Applies to [creating a snippet](../api/snippets.md#create-a-snippet) with `POST /snippets`, [creating a project snippet](../api/project_snippets.md#create-a-snippet) with `POST /projects/:id/snippets`, and the `createSnippet` GraphQL mutation used by the GitLab UI. The limit is shared between all three. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/251927) in GitLab 19.4. |
| Update username                      | 10 calls per minute per authenticated user                     | Limits how frequently a username can be changed. Mitigates attempts to mass discover which usernames are in use. |
| Username exists                      | 20 calls per minute per IP address                             | Applies to the internal `/users/:username/exists` endpoint, which checks whether a chosen username is taken. |
| Work item bulk update                | 30 requests per minute per authenticated user                  | Applies to [bulk editing issues](../user/project/issues/managing_issues.md#bulk-edit-issues) and [epics](../user/group/epics/manage_epics.md#bulk-edit-epics) in the UI, and to the `workItemBulkUpdate` GraphQL mutation. The limit is shared between them. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/263775) in GitLab 19.6 [with a flag](../administration/feature_flags/_index.md) named `work_item_bulk_update_rate_limit`. Disabled by default. |
| Work item deletion                   | 300 requests per minute per authenticated user                 | Applies to the `workItemDelete` GraphQL mutation. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253621) in GitLab 19.4. [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/628006) in GitLab 19.5. |

## Related topics

- [Rate limits](_index.md)
- [Abuse and failed authentication bans](abuse_bans.md)
