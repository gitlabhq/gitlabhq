# Runners API

API used by Runners to register and delete themselves.

>**Note:**
This API is intended to be used only by Runners as their own
communication channel. For the consumer API see the
[new Runners API](../runners.md).

## Authentication

This API uses two types of authentication:

1. Unique Runner's token, which is the token assigned to the Runner after it
   has been registered.

2. Using Runners' registration token.
   This is a token that can be found in project's settings.
   It can also be found in the **Admin > Runners** settings area.
   There are two types of tokens you can pass: shared Runner registration
   token or project specific registration token.

## Register a new runner

Used to make GitLab CI aware of available runners.

```sh
POST /ci/api/v1/runners/register
```

| Attribute | Type    | Required  | Description |
| --------- | ------- | --------- | ----------- |
| `token`   | string  | yes       | Runner's registration token |

Example request:

```sh
curl --request POST "https://gitlab.example.com/ci/api/v1/runners/register" --form "token=t0k3n"
```

## Delete a Runner

Used to remove a Runner.

```sh
DELETE /ci/api/v1/runners/delete
```

| Attribute | Type    | Required  | Description |
| --------- | ------- | --------- | ----------- |
| `token`   | string  | yes       | Runner's registration token |

Example request:

```sh
curl --request DELETE "https://gitlab.example.com/ci/api/v1/runners/delete" --form "token=t0k3n"
```
