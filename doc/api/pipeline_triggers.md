---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Pipeline triggers API **(FREE)**

You can read more about [triggering pipelines through the API](../ci/triggers/index.md).

## List project triggers

Get a list of project's build triggers.

```plaintext
GET /projects/:id/triggers
```

| Attribute | Type    | required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/triggers"
```

```json
[
    {
        "id": 10,
        "description": "my trigger",
        "created_at": "2016-01-07T09:53:58.235Z",
        "last_used": null,
        "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
        "updated_at": "2016-01-07T09:53:58.235Z",
        "owner": null
    }
]
```

## Get trigger details

Get details of project's build trigger.

```plaintext
GET /projects/:id/triggers/:trigger_id
```

| Attribute    | Type    | required | Description              |
|--------------|---------|----------|--------------------------|
| `id`         | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user      |
| `trigger_id` | integer | yes      | The trigger ID           |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/triggers/5"
```

```json
{
    "id": 10,
    "description": "my trigger",
    "created_at": "2016-01-07T09:53:58.235Z",
    "last_used": null,
    "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
    "updated_at": "2016-01-07T09:53:58.235Z",
    "owner": null
}
```

## Create a project trigger

Create a trigger for a project.

```plaintext
POST /projects/:id/triggers
```

| Attribute     | Type    | required | Description              |
|---------------|---------|----------|--------------------------|
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user      |
| `description` | string  | yes      | The trigger name         |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
     --form description="my description" "https://gitlab.example.com/api/v4/projects/1/triggers"
```

```json
{
    "id": 10,
    "description": "my trigger",
    "created_at": "2016-01-07T09:53:58.235Z",
    "last_used": null,
    "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
    "updated_at": "2016-01-07T09:53:58.235Z",
    "owner": null
}
```

## Update a project trigger

Update a trigger for a project.

```plaintext
PUT /projects/:id/triggers/:trigger_id
```

| Attribute     | Type    | required | Description              |
|---------------|---------|----------|--------------------------|
| `id`          | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user      |
| `trigger_id`  | integer | yes      | The trigger ID           |
| `description` | string  | no       | The trigger name         |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" \
     --form description="my description" "https://gitlab.example.com/api/v4/projects/1/triggers/10"
```

```json
{
    "id": 10,
    "description": "my trigger",
    "created_at": "2016-01-07T09:53:58.235Z",
    "last_used": null,
    "token": "6d056f63e50fe6f8c5f8f4aa10edb7",
    "updated_at": "2016-01-07T09:53:58.235Z",
    "owner": null
}
```

## Remove a project trigger

Remove a project's build trigger.

```plaintext
DELETE /projects/:id/triggers/:trigger_id
```

| Attribute      | Type    | required | Description              |
|----------------|---------|----------|--------------------------|
| `id`           | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user      |
| `trigger_id`   | integer | yes      | The trigger ID           |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/triggers/5"
```
