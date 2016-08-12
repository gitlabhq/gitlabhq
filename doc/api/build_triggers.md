# Build triggers

You can read more about [triggering builds through the API](../ci/triggers/README.md).

## List project triggers

Get a list of project's build triggers.

```
GET /projects/:id/triggers
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer | yes      | The ID of a project |

```
curl --header "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/triggers"
```

```json
[
    {
        "created_at": "2015-12-23T16:24:34.716Z",
        "deleted_at": null,
        "last_used": "2016-01-04T15:41:21.986Z",
        "token": "fbdb730c2fbdb095a0862dbd8ab88b",
        "updated_at": "2015-12-23T16:24:34.716Z"
    },
    {
        "created_at": "2015-12-23T16:25:56.760Z",
        "deleted_at": null,
        "last_used": null,
        "token": "7b9148c158980bbd9bcea92c17522d",
        "updated_at": "2015-12-23T16:25:56.760Z"
    }
]
```

## Get trigger details

Get details of project's build trigger.

```
GET /projects/:id/triggers/:token
```

| Attribute | Type    | required | Description              |
|-----------|---------|----------|--------------------------|
| `id`      | integer | yes      | The ID of a project      |
| `token`   | string  | yes      | The `token` of a trigger |

```
curl --header "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/triggers/7b9148c158980bbd9bcea92c17522d"
```

```json
{
    "created_at": "2015-12-23T16:25:56.760Z",
    "deleted_at": null,
    "last_used": null,
    "token": "7b9148c158980bbd9bcea92c17522d",
    "updated_at": "2015-12-23T16:25:56.760Z"
}
```

## Create a project trigger

Create a build trigger for a project.

```
POST /projects/:id/triggers
```

| Attribute | Type    | required | Description              |
|-----------|---------|----------|--------------------------|
| `id`      | integer | yes      | The ID of a project      |

```
curl --request POST --header "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/triggers"
```

```json
{
    "created_at": "2016-01-07T09:53:58.235Z",
    "deleted_at": null,
    "last_used": null,
    "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
    "updated_at": "2016-01-07T09:53:58.235Z"
}
```

## Remove a project trigger

Remove a project's build trigger.

```
DELETE /projects/:id/triggers/:token
```

| Attribute | Type    | required | Description              |
|-----------|---------|----------|--------------------------|
| `id`      | integer | yes      | The ID of a project      |
| `token`   | string  | yes      | The `token` of a trigger |

```
curl --request DELETE --header "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/triggers/7b9148c158980bbd9bcea92c17522d"
```

```json
{
    "created_at": "2015-12-23T16:25:56.760Z",
    "deleted_at": "2015-12-24T12:32:20.100Z",
    "last_used": null,
    "token": "7b9148c158980bbd9bcea92c17522d",
    "updated_at": "2015-12-24T12:32:20.100Z"
}
```
