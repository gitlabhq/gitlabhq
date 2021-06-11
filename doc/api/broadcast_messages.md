---
stage: Growth
group: Activation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Broadcast Messages API **(FREE SELF)**

Broadcast messages API operates on [broadcast messages](../user/admin_area/broadcast_messages.md).

As of GitLab 12.8, GET requests do not require authentication. All other broadcast message API endpoints are accessible only to administrators. Non-GET requests by:

- Guests result in `401 Unauthorized`.
- Regular users result in `403 Forbidden`.

## Get all broadcast messages

List all broadcast messages.

```plaintext
GET /broadcast_messages
```

Example request:

```shell
curl "https://gitlab.example.com/api/v4/broadcast_messages"
```

Example response:

```json
[
    {
        "message":"Example broadcast message",
        "starts_at":"2016-08-24T23:21:16.078Z",
        "ends_at":"2016-08-26T23:21:16.080Z",
        "color":"#E75E40",
        "font":"#FFFFFF",
        "id":1,
        "active": false,
        "target_path": "*/welcome",
        "broadcast_type": "banner",
        "dismissable": false
    }
]
```

## Get a specific broadcast message

Get a specific broadcast message.

```plaintext
GET /broadcast_messages/:id
```

Parameters:

| Attribute | Type    | Required | Description                          |
|:----------|:--------|:---------|:-------------------------------------|
| `id`      | integer | yes      | ID of broadcast message to retrieve. |

Example request:

```shell
curl "https://gitlab.example.com/api/v4/broadcast_messages/1"
```

Example response:

```json
{
    "message":"Deploy in progress",
    "starts_at":"2016-08-24T23:21:16.078Z",
    "ends_at":"2016-08-26T23:21:16.080Z",
    "color":"#cecece",
    "font":"#FFFFFF",
    "id":1,
    "active":false,
    "target_path": "*/welcome",
    "broadcast_type": "banner",
    "dismissable": false
}
```

## Create a broadcast message

Create a new broadcast message.

```plaintext
POST /broadcast_messages
```

Parameters:

| Attribute       | Type     | Required | Description                                           |
|:----------------|:---------|:---------|:------------------------------------------------------|
| `message`       | string   | yes      | Message to display.                                   |
| `starts_at`     | datetime | no       | Starting time (defaults to current time). Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `ends_at`       | datetime | no       | Ending time (defaults to one hour from current time). Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `color`         | string   | no       | Background color hex code.                            |
| `font`          | string   | no       | Foreground color hex code.                            |
| `target_path`   | string   | no       | Target path of the broadcast message.                 |
| `broadcast_type`| string   | no       | Appearance type (defaults to banner)                  |
| `dismissable`   | boolean  | no       | Can the user dismiss the message?                     |

Example request:

```shell
curl --data "message=Deploy in progress&color=#cecece" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/broadcast_messages"
```

Example response:

```json
{
    "message":"Deploy in progress",
    "starts_at":"2016-08-26T00:41:35.060Z",
    "ends_at":"2016-08-26T01:41:35.060Z",
    "color":"#cecece",
    "font":"#FFFFFF",
    "id":1,
    "active": true,
    "target_path": "*/welcome",
    "broadcast_type": "notification",
    "dismissable": false
}
```

## Update a broadcast message

Update an existing broadcast message.

```plaintext
PUT /broadcast_messages/:id
```

Parameters:

| Attribute       | Type     | Required | Description                           |
|:----------------|:---------|:---------|:--------------------------------------|
| `id`            | integer  | yes      | ID of broadcast message to update.    |
| `message`       | string   | no       | Message to display.                   |
| `starts_at`     | datetime | no       | Starting time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `ends_at`       | datetime | no       | Ending time. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |
| `color`         | string   | no       | Background color hex code.            |
| `font`          | string   | no       | Foreground color hex code.            |
| `target_path`   | string   | no       | Target path of the broadcast message. |
| `broadcast_type`| string   | no       | Appearance type (defaults to banner)  |
| `dismissable`   | boolean  | no       | Can the user dismiss the message?     |

Example request:

```shell
curl --request PUT --data "message=Update message&color=#000" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/broadcast_messages/1"
```

Example response:

```json
{
    "message":"Update message",
    "starts_at":"2016-08-26T00:41:35.060Z",
    "ends_at":"2016-08-26T01:41:35.060Z",
    "color":"#000",
    "font":"#FFFFFF",
    "id":1,
    "active": true,
    "target_path": "*/welcome",
    "broadcast_type": "notification",
    "dismissable": false
}
```

## Delete a broadcast message

Delete a broadcast message.

```shell
DELETE /broadcast_messages/:id
```

Parameters:

| Attribute | Type    | Required | Description                        |
|:----------|:--------|:---------|:-----------------------------------|
| `id`      | integer | yes      | ID of broadcast message to delete. |

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/broadcast_messages/1"
```
