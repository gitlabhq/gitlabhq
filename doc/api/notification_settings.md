# Notification settings API

>**Note:** This feature was [introduced][ce-5632] in GitLab 8.12.

**Valid notification levels**

The notification levels are defined in the `NotificationSetting.level` model enumeration. Currently, these levels are recognized:

```
disabled
participating
watch
global
mention
custom
```

If the `custom` level is used, specific email events can be controlled. Notification email events are defined in the `NotificationSetting::EMAIL_EVENTS` model variable. Currently, these events are recognized:

```
new_note
new_issue
reopen_issue
close_issue
reassign_issue
new_merge_request
push_to_merge_request
reopen_merge_request
close_merge_request
reassign_merge_request
merge_merge_request
failed_pipeline
success_pipeline
```

## Global notification settings

Get current notification settings and email address.

```
GET /notification_settings
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/notification_settings
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

```
PUT /notification_settings
```

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/notification_settings?level=watch
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
| `new_merge_request` | boolean | no | Enable/disable this notification |
| `push_to_merge_request` | boolean | no | Enable/disable this notification |
| `reopen_merge_request` | boolean | no | Enable/disable this notification |
| `close_merge_request` | boolean | no | Enable/disable this notification |
| `reassign_merge_request` | boolean | no | Enable/disable this notification |
| `merge_merge_request` | boolean | no | Enable/disable this notification |
| `failed_pipeline` | boolean | no | Enable/disable this notification |
| `success_pipeline` | boolean | no | Enable/disable this notification |

Example response:

```json
{
  "level": "watch",
  "notification_email": "admin@example.com"
}
```

## Group / project level notification settings

Get current group or project notification settings.

```
GET /groups/:id/notification_settings
GET /projects/:id/notification_settings
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/5/notification_settings
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/8/notification_settings
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The group/project ID or path |

Example response:

```json
{
  "level": "global"
}
```

## Update group/project level notification settings

Update current group/project notification settings.

```
PUT /groups/:id/notification_settings
PUT /projects/:id/notification_settings
```

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/5/notification_settings?level=watch
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/8/notification_settings?level=custom&new_note=true
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The group/project ID or path |
| `level` | string | no | The global notification level |
| `new_note` | boolean | no | Enable/disable this notification |
| `new_issue` | boolean | no | Enable/disable this notification |
| `reopen_issue` | boolean | no | Enable/disable this notification |
| `close_issue` | boolean | no | Enable/disable this notification |
| `reassign_issue` | boolean | no | Enable/disable this notification |
| `new_merge_request` | boolean | no | Enable/disable this notification |
| `push_to_merge_request` | boolean | no | Enable/disable this notification |
| `reopen_merge_request` | boolean | no | Enable/disable this notification |
| `close_merge_request` | boolean | no | Enable/disable this notification |
| `reassign_merge_request` | boolean | no | Enable/disable this notification |
| `merge_merge_request` | boolean | no | Enable/disable this notification |
| `failed_pipeline` | boolean | no | Enable/disable this notification |
| `success_pipeline` | boolean | no | Enable/disable this notification |

Example responses:

```json
{
  "level": "watch"
}

{
  "level": "custom",
  "events": {
    "new_note": true,
    "new_issue": false,
    "reopen_issue": false,
    "close_issue": false,
    "reassign_issue": false,
    "new_merge_request": false,
    "push_to_merge_request": false,
    "reopen_merge_request": false,
    "close_merge_request": false,
    "reassign_merge_request": false,
    "merge_merge_request": false,
    "failed_pipeline": false,
    "success_pipeline": false
  }
}
```

[ce-5632]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/5632
