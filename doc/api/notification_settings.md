---
stage: Growth
group: Engagement
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Notification settings API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage notification settings in GitLab.
For more information, see [notification emails](../user/profile/notifications.md).

## Notification levels

The notification levels are defined in the `NotificationSetting.level` model enumeration.
These levels are recognized:

- `disabled`: Turn off all notifications
- `participating`: Receive notifications for threads you have participated in
- `watch`: Receive notifications for most activity
- `global`: Use your global notification settings
- `mention`: Receive notifications when you are mentioned in a comment
- `custom`: Receive notifications for selected events

If you use the `custom` level, you can control specific email events. Available events are returned
by `NotificationSetting.email_events`.
These events are recognized:

| Event                          | Description |
| ------------------------------ | ----------- |
| `approver`                     | A merge request you're eligible to approve is created |
| `change_reviewer_merge_request`| When a merge request's reviewer is changed |
| `close_issue`                  | When an issue is closed |
| `close_merge_request`          | When a merge request is closed |
| `failed_pipeline`              | When a pipeline fails |
| `fixed_pipeline`               | When a previously failed pipeline is fixed |
| `issue_due`                    | When an issue is due tomorrow |
| `merge_merge_request`          | When a merge request is merged |
| `merge_when_pipeline_succeeds` | When a merge request is set to auto-merge |
| `moved_project`                | When a project is moved |
| `new_epic`                     | When a new epic is created (in the Premium and Ultimate tier) |
| `new_issue`                    | When a new issue is created |
| `new_merge_request`            | When a new merge request is created |
| `new_note`                     | When someone adds a comment |
| `new_release`                  | When a new release is published |
| `push_to_merge_request`        | When someone pushes to a merge request |
| `reassign_issue`               | When an issue is reassigned |
| `reassign_merge_request`       | When a merge request is reassigned |
| `reopen_issue`                 | When an issue is reopened |
| `reopen_merge_request`         | When a merge request is reopened |
| `success_pipeline`             | When a pipeline completes successfully |

## Get global notification settings

Get current notification settings and email address.

```plaintext
GET /notification_settings
```

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/notification_settings"
```

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute            | Type   | Description |
| -------------------- | ------ | ----------- |
| `level`              | string | Global notification level |
| `notification_email` | string | Email address where notifications are sent |

Example response:

```json
{
  "level": "participating",
  "notification_email": "admin@example.com"
}
```

## Update global notification settings

Update notification settings and email address.

```plaintext
PUT /notification_settings
```

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/notification_settings?level=watch"
```

Supported attributes:

| Attribute                      | Type    | Required | Description |
| ------------------------------ | ------- | -------- | ----------- |
| `approver`                     | boolean | No       | Turn on notifications when a merge request you're eligible to approve is created |
| `change_reviewer_merge_request`| boolean | No       | Turn on notifications when a merge request's reviewer is changed |
| `close_issue`                  | boolean | No       | Turn on notifications when an issue is closed |
| `close_merge_request`          | boolean | No       | Turn on notifications when a merge request is closed |
| `failed_pipeline`              | boolean | No       | Turn on notifications when a pipeline fails |
| `fixed_pipeline`               | boolean | No       | Turn on notifications when a previously failed pipeline is fixed |
| `issue_due`                    | boolean | No       | Turn on notifications when an issue is due tomorrow |
| `level`                        | string  | No       | Global notification level |
| `merge_merge_request`          | boolean | No       | Turn on notifications when a merge request is merged |
| `merge_when_pipeline_succeeds` | boolean | No       | Turn on notifications when a merge request is set to auto-merge |
| `moved_project`                | boolean | No       | Turn on notifications when a project is moved |
| `new_epic`                     | boolean | No       | Turn on notifications when a new epic is created (in the Premium and Ultimate tier) |
| `new_issue`                    | boolean | No       | Turn on notifications when a new issue is created |
| `new_merge_request`            | boolean | No       | Turn on notifications when a new merge request is created |
| `new_note`                     | boolean | No       | Turn on notifications when a new comment is added |
| `new_release`                  | boolean | No       | Turn on notifications when a new release is published |
| `notification_email`           | string  | No       | Email address where notifications are sent |
| `push_to_merge_request`        | boolean | No       | Turn on notifications when someone pushes to a merge request |
| `reassign_issue`               | boolean | No       | Turn on notifications when an issue is reassigned |
| `reassign_merge_request`       | boolean | No       | Turn on notifications when a merge request is reassigned |
| `reopen_issue`                 | boolean | No       | Turn on notifications when an issue is reopened |
| `reopen_merge_request`         | boolean | No       | Turn on notifications when a merge request is reopened |
| `success_pipeline`             | boolean | No       | Turn on notifications when a pipeline completes successfully |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute            | Type   | Description |
| -------------------- | ------ | ----------- |
| `level`              | string | Global notification level |
| `notification_email` | string | Email address where notifications are sent |

Example response:

```json
{
  "level": "watch",
  "notification_email": "admin@example.com"
}
```

## Get group or project notification settings

Get notification settings for a group or project.

```plaintext
GET /groups/:id/notification_settings
GET /projects/:id/notification_settings
```

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/notification_settings"
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/8/notification_settings"
```

Supported attributes:

| Attribute | Type              | Required | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | integer or string | Yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group or project |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following response attributes:

| Attribute | Type   | Description |
| --------- | ------ | ----------- |
| `level`   | string | Notification level |

Example response for standard notification level:

```json
{
  "level": "global"
}
```

Example response for a group with custom notification level:

```json
{
  "level": "custom",
  "events": {
    "new_release": null,
    "new_note": null,
    "new_issue": null,
    "reopen_issue": null,
    "close_issue": null,
    "reassign_issue": null,
    "issue_due": null,
    "new_merge_request": null,
    "push_to_merge_request": null,
    "reopen_merge_request": null,
    "close_merge_request": null,
    "reassign_merge_request": null,
    "change_reviewer_merge_request": null,
    "merge_merge_request": null,
    "failed_pipeline": null,
    "fixed_pipeline": null,
    "success_pipeline": null,
    "moved_project": true,
    "merge_when_pipeline_succeeds": false,
    "new_epic": null
  }
}
```

In this response:

- `true` indicates the notification is turned on.
- `false` indicates the notification is turned off.
- `null` indicates the notification uses the default setting.

{{< alert type="note" >}}

The `new_epic` attribute is available only in the Premium and Ultimate tiers.

{{< /alert >}}

## Update group or project notification settings

Update notification settings for a group or project.

```plaintext
PUT /groups/:id/notification_settings
PUT /projects/:id/notification_settings
```

Example requests:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/notification_settings?level=watch"
```

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/8/notification_settings?level=custom&new_note=true"
```

Supported attributes:

| Attribute                      | Type              | Required | Description |
| ------------------------------ | ----------------- | -------- | ----------- |
| `approver`                     | boolean           | No       | Turn on notifications when a merge request you're eligible to approve is created |
| `change_reviewer_merge_request`| boolean           | No       | Turn on notifications when a merge request's reviewer changes |
| `close_issue`                  | boolean           | No       | Turn on notifications when an issue is closed |
| `close_merge_request`          | boolean           | No       | Turn on notifications when a merge request is closed |
| `failed_pipeline`              | boolean           | No       | Turn on notifications when a pipeline fails |
| `fixed_pipeline`               | boolean           | No       | Turn on notifications when a previously failed pipeline is fixed |
| `id`                           | integer or string | Yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group or project |
| `issue_due`                    | boolean           | No       | Turn on notifications when an issue is due tomorrow |
| `level`                        | string            | No       | Notification level for this group or project |
| `merge_merge_request`          | boolean           | No       | Turn on notifications when a merge request is merged |
| `merge_when_pipeline_succeeds` | boolean           | No       | Turn on notifications when a merge request is set to merge when its pipeline succeeds |
| `moved_project`                | boolean           | No       | Turn on notifications when a project is moved |
| `new_epic`                     | boolean           | No       | Turn on notifications when a new epic is created (in the Premium and Ultimate tier) |
| `new_issue`                    | boolean           | No       | Turn on notifications when a new issue is created |
| `new_merge_request`            | boolean           | No       | Turn on notifications when a new merge request is created |
| `new_note`                     | boolean           | No       | Turn on notifications when a new comment is added |
| `new_release`                  | boolean           | No       | Turn on notifications when a new release is published |
| `push_to_merge_request`        | boolean           | No       | Turn on notifications when someone pushes to a merge request |
| `reassign_issue`               | boolean           | No       | Turn on notifications when an issue is reassigned |
| `reassign_merge_request`       | boolean           | No       | Turn on notifications when a merge request is reassigned |
| `reopen_issue`                 | boolean           | No       | Turn on notifications when an issue is reopened |
| `reopen_merge_request`         | boolean           | No       | Turn on notifications when a merge request is reopened |
| `success_pipeline`             | boolean           | No       | Turn on notifications when a pipeline completes successfully |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and one of the following response formats.

For a non-custom notification level:

```json
{
  "level": "watch"
}
```

For a custom notification level, the response includes an `events` object showing the status of each notification:

```json
{
  "level": "custom",
  "events": {
    "new_release": null,
    "new_note": true,
    "new_issue": false,
    "reopen_issue": null,
    "close_issue": null,
    "reassign_issue": null,
    "issue_due": null,
    "new_merge_request": null,
    "push_to_merge_request": null,
    "reopen_merge_request": null,
    "close_merge_request": null,
    "reassign_merge_request": null,
    "change_reviewer_merge_request": null,
    "merge_merge_request": null,
    "failed_pipeline": false,
    "fixed_pipeline": null,
    "success_pipeline": null,
    "moved_project": false,
    "merge_when_pipeline_succeeds": false,
    "new_epic": null
  }
}
```

In this response:

- `true` indicates the notification is turned on.
- `false` indicates the notification is turned off.
- `null` indicates the notification uses the default setting.

{{< alert type="note" >}}

The `new_epic` attribute is available only in the Premium and Ultimate tiers.

{{< /alert >}}
