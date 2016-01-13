# Build triggers

## List project triggers

Get a list of project triggers

```
GET /projects/:id/triggers
```

### Parameters

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| id        | integer | yes      | The ID of a project |

### Example of request

```
curl -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/triggers"
```

### Example of response

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

Get details of trigger of a project

```
GET /projects/:id/triggers/:token
```

### Parameters

| Attribute | Type    | required | Description              |
|-----------|---------|----------|--------------------------|
| id        | integer | yes      | The ID of a project      |
| token     | string  | yes      | The `token` of a project |

### Example of request

```
curl -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/triggers/7b9148c158980bbd9bcea92c17522d"
```

### Example of response

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

Create a trigger for a project

```
POST /projects/:id/triggers
```

### Parameters

| Attribute | Type    | required | Description              |
|-----------|---------|----------|--------------------------|
| id        | integer | yes      | The ID of a project      |

### Example of request

```
curl -X POST -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/triggers"
```

### Example of response

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

Remove a trigger of a project

```
DELETE /projects/:id/triggers/:token
```

### Parameters

| Attribute | Type    | required | Description              |
|-----------|---------|----------|--------------------------|
| id        | integer | yes      | The ID of a project      |
| token     | string  | yes      | The `token` of a project |

### Example of request

```
curl -X DELETE -H "PRIVATE_TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/1/triggers/7b9148c158980bbd9bcea92c17522d"
```
