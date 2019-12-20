# Broadcast Messages API

> Introduced in GitLab 8.12.

Broadcast messages API operates on [broadcast messages](../user/admin_area/broadcast_messages.md).

The broadcast message API is only accessible to administrators. All requests by:

- Guests will result in `401 Unauthorized`.
- Regular users will result in `403 Forbidden`.

## Get all broadcast messages

List all broadcast messages.

```text
GET /broadcast_messages
```

Example request:

```sh
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/broadcast_messages
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
        "target_path": "*/welcome"
    }
]
```

## Get a specific broadcast message

Get a specific broadcast message.

```text
GET /broadcast_messages/:id
```

Parameters:

| Attribute | Type    | Required | Description                          |
|:----------|:--------|:---------|:-------------------------------------|
| `id`      | integer | yes      | ID of broadcast message to retrieve. |

Example request:

```sh
curl --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/broadcast_messages/1
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
    "target_path": "*/welcome"
}
```

## Create a broadcast message

Create a new broadcast message.

```text
POST /broadcast_messages
```

Parameters:

| Attribute   | Type     | Required | Description                                           |
|:------------|:---------|:---------|:------------------------------------------------------|
| `message`   | string   | yes      | Message to display.                                   |
| `starts_at` | datetime | no       | Starting time (defaults to current time).             |
| `ends_at`   | datetime | no       | Ending time (defaults to one hour from current time). |
| `color`     | string   | no       | Background color hex code.                            |
| `font`      | string   | no       | Foreground color hex code.                            |

Example request:

```sh
curl --data "message=Deploy in progress&color=#cecece" --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/broadcast_messages
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
    "target_path": "*/welcome"
}
```

## Update a broadcast message

Update an existing broadcast message.

```text
PUT /broadcast_messages/:id
```

Parameters:

| Attribute   | Type     | Required | Description                        |
|:------------|:---------|:---------|:-----------------------------------|
| `id`        | integer  | yes      | ID of broadcast message to update. |
| `message`   | string   | no       | Message to display.                |
| `starts_at` | datetime | no       | Starting time.                     |
| `ends_at`   | datetime | no       | Ending time.                       |
| `color`     | string   | no       | Background color hex code.         |
| `font`      | string   | no       | Foreground color hex code.         |

Example request:

```sh
curl --request PUT --data "message=Update message&color=#000" --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/broadcast_messages/1
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
    "target_path": "*/welcome"
}
```

## Delete a broadcast message

Delete a broadcast message.

```sh
DELETE /broadcast_messages/:id
```

Parameters:

| Attribute | Type    | Required | Description                        |
|:----------|:--------|:---------|:-----------------------------------|
| `id`      | integer | yes      | ID of broadcast message to delete. |

Example request:

```sh
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/broadcast_messages/1
```
