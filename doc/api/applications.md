# Applications API

> [Introduced][ce-8160] in GitLab 10.5

[ce-8160]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8160

Only admin user can use the Applications API.

## Create a application

Create a application by posting a JSON payload.

Returns `200` if the request succeeds.

```
POST /applications
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `name` | string | yes | The name of the application |
| `redirect_uri` | string | yes | The redirect URI of the application |
| `scopes` | string | yes | The scopes of the application |

```bash
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --data "name=MyApplication&redirect_uri=http://redirect.uri&scopes=" https://gitlab.example.com/api/v4/applications
```

Example response:

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "MyApplication",
    "secret": "ee1dd64b6adc89cf7e2c23099301ccc2c61b441064e9324d963c46902a85ec34",
    "callback_url": "http://redirect.uri"
}
```

## List all applications

List all registered applications.

```
GET /applications
```

```bash
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/applications
```

Example response:

```json
[
    {
        "id":1,
        "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
        "application_name": "MyApplication",
        "callback_url": "http://redirect.uri"
    }
]
```

> Note: the `secret` value will not be exposed by this API.

## Delete an application

Delete a specific application.

Returns `204` if the request succeeds.

```
DELETE /applications/:id
```

Parameters:

- `id` (required) - The id of the application (not the application_id)

```bash
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/applications/:id
```
