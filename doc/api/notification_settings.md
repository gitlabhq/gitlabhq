---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Notification settings API **(FREE)**

Change [notification settings](../user/profile/notifications.md) using the REST API.

## Valid notification levels

The notification levels are defined in the `NotificationSetting.level` model enumeration. Currently, these levels are recognized:

- `disabled`
- `participating`
- `watch`
- `global`
- `mention`
- `custom`

If the `custom` level is used, specific email events can be controlled. Available events are returned by `NotificationSetting.email_events`. Currently, these events are recognized:

- `new_note`
- `new_issue`
- `reopen_issue`
- `close_issue`
- `reassign_issue`
- `issue_due`
- `new_merge_request`
- `push_to_merge_request`
- `reopen_merge_request`
- `close_merge_request`
- `reassign_merge_request`
- `merge_merge_request`
- `failed_pipeline`
- `fixed_pipeline`
- `success_pipeline`
- `moved_project`
- `merge_when_pipeline_succeeds`
- `new_epic` **(ULTIMATE)**

## Global notification settings

Get current notification settings and email address.

```plaintext
GET /notification_settings
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/notification_settings"
```

Example response:

```json
{
  "level": "participating",
  "notification_email": "admin@example.com"
}
```

## Update global notification settings

Update current notification settings and email address.

```plaintext
PUT /notification_settings
```

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/notification_settings?level=watch"
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `level` | string | no | The global notification level |
| `notification_email` | string | no | The email address to send notifications |
| `new_note` | boolean | no | Enable/disable this notification |
| `new_issue` | boolean | no | Enable/disable this notification |
| `reopen_issue` | boolean | no | Enable/disable this notification |
| `close_issue` | boolean | no | Enable/disable this notification |
| `reassign_issue` | boolean | no | Enable/disable this notification |
| `issue_due` | boolean | no | Enable/disable this notification |
| `new_merge_request` | boolean | no | Enable/disable this notification |
| `push_to_merge_request` | boolean | no | Enable/disable this notification |
| `reopen_merge_request` | boolean | no | Enable/disable this notification |
| `close_merge_request` | boolean | no | Enable/disable this notification |
| `reassign_merge_request` | boolean | no | Enable/disable this notification |
| `merge_merge_request` | boolean | no | Enable/disable this notification |
| `failed_pipeline` | boolean | no | Enable/disable this notification |
| `fixed_pipeline` | boolean | no | Enable/disable this notification |
| `success_pipeline` | boolean | no | Enable/disable this notification |
| `moved_project` | boolean | no | Enable/disable this notification ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30371) in GitLab 13.3) |
| `merge_when_pipeline_succeeds` | boolean | no | Enable/disable this notification ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/244840) in GitLab 13.9) |
| `new_epic` | boolean | no | Enable/disable this notification ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5863) in GitLab 11.3) **(ULTIMATE)** |

Example response:

```json
{
  "level": "watch",
  "notification_email": "admin@example.com"
}
```

## Group / project level notification settings

Get current group or project notification settings.

```plaintext
GET /groups/:id/notification_settings
GET /projects/:id/notification_settings
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/notification_settings"
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/8/notification_settings"
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID, or [URL-encoded path, of the group or project](index.md#namespaced-path-encoding). |

Example response:

```json
{
  "level": "global"
}
```

## Update group/project level notification settings

Update current group/project notification settings.

```plaintext
PUT /groups/:id/notification_settings
PUT /projects/:id/notification_settings
```

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/5/notification_settings?level=watch"
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/8/notification_settings?level=custom&new_note=true"
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer or string | yes | The ID, or [URL-encoded path, of the group or project](index.md#namespaced-path-encoding) |
| `level` | string | no | The global notification level |
| `new_note` | boolean | no | Enable/disable this notification |
| `new_issue` | boolean | no | Enable/disable this notification |
| `reopen_issue` | boolean | no | Enable/disable this notification |
| `close_issue` | boolean | no | Enable/disable this notification |
| `reassign_issue` | boolean | no | Enable/disable this notification |
| `issue_due` | boolean | no | Enable/disable this notification |
| `new_merge_request` | boolean | no | Enable/disable this notification |
| `push_to_merge_request` | boolean | no | Enable/disable this notification |
| `reopen_merge_request` | boolean | no | Enable/disable this notification |
| `close_merge_request` | boolean | no | Enable/disable this notification |
| `reassign_merge_request` | boolean | no | Enable/disable this notification |
| `merge_merge_request` | boolean | no | Enable/disable this notification |
| `failed_pipeline` | boolean | no | Enable/disable this notification |
| `fixed_pipeline` | boolean | no | Enable/disable this notification |
| `success_pipeline` | boolean | no | Enable/disable this notification |
| `moved_project` | boolean | no | Enable/disable this notification ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30371) in GitLab 13.3) |
| `merge_when_pipeline_succeeds` | boolean | no | Enable/disable this notification ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/244840) in GitLab 13.9) |
| `new_epic` | boolean | no | Enable/disable this notification ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/5863) in GitLab 11.3) **(ULTIMATE)** |

Example responses:

```json
{
  "level": "watch"
}
```

```json
{
  "level": "custom",
  "events": {
    "new_note": true,
    "new_issue": false,
    "reopen_issue": false,
    "close_issue": false,
    "reassign_issue": false,
    "issue_due": false,
    "new_merge_request": false,
    "push_to_merge_request": false,
    "reopen_merge_request": false,
    "close_merge_request": false,
    "reassign_merge_request": false,
    "merge_merge_request": false,
    "failed_pipeline": false,
    "fixed_pipeline": false,
    "success_pipeline": false
  }
}
```

Users on GitLab [Ultimate](https://about.gitlab.com/pricing/) also see the `new_epic`
parameter:

```json
{
  "level": "custom",
  "events": {
    "new_note": true,
    "new_issue": false,
    "new_epic": false,
    ...
  }
}
```
