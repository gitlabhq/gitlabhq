# Broadcast Messages

> **Note:** This feature was introduced in GitLab 8.12.

The broadcast message API is only accessible to administrators. All requests by
guests will respond with `401 Unauthorized`, and all requests by normal users
will respond with `403 Forbidden`.

## Get all broadcast messages

```
GET /broadcast_messages
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/broadcast_messages
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
        "active": false
    }
]
```

## Get a specific broadcast message

```
GET /broadcast_messages/:id
```

| Attribute   | Type     | Required | Description               |
| ----------- | -------- | -------- | ------------------------- |
| `id`        | integer  | yes      | Broadcast message ID      |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/broadcast_messages/1
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
    "active":false
}
```

## Create a broadcast message

Responds with `400 Bad request` when the `message` parameter is missing or the
`color` or `font` values are invalid, and `201 Created` when the broadcast
message was successfully created.

```
POST /broadcast_messages
```

| Attribute   | Type     | Required | Description                                          |
| ----------- | -------- | -------- | ---------------------------------------------------- |
| `message`   | string   | yes      | Message to display                                   |
| `starts_at` | datetime | no       | Starting time (defaults to current time)             |
| `ends_at`   | datetime | no       | Ending time (defaults to one hour from current time) |
| `color`     | string   | no       | Background color hex code                            |
| `font`      | string   | no       | Foreground color hex code                            |

```bash
curl --data "message=Deploy in progress&color=#cecece" --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/broadcast_messages
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
    "active": true
}
```

## Update a broadcast message

```
PUT /broadcast_messages/:id
```

| Attribute   | Type     | Required | Description               |
| ----------- | -------- | -------- | ------------------------- |
| `id`        | integer  | yes      | Broadcast message ID      |
| `message`   | string   | no       | Message to display        |
| `starts_at` | datetime | no       | Starting time             |
| `ends_at`   | datetime | no       | Ending time               |
| `color`     | string   | no       | Background color hex code |
| `font`      | string   | no       | Foreground color hex code |

```bash
curl --request PUT --data "message=Update message&color=#000" --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/broadcast_messages/1
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
    "active": true
}
```

## Delete a broadcast message

```
DELETE /broadcast_messages/:id
```

| Attribute   | Type     | Required | Description               |
| ----------- | -------- | -------- | ------------------------- |
| `id`        | integer  | yes      | Broadcast message ID      |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/broadcast_messages/1
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
    "active": true
}
```
