# Applications API

> [Introduced][ce-8160] in GitLab 10.5

[ce-8160]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/8160

## Create a application

Create a application by posting a JSON payload.

User must be admin to do that.

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
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --data "name=MyApplication&redirect_uri=http://redirect.uri&scopes=" https://gitlab.example.com/api/v3/applications
```

Example response:

```json
{
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "secret": "ee1dd64b6adc89cf7e2c23099301ccc2c61b441064e9324d963c46902a85ec34",
    "callback_url": "http://redirect.uri"
}
```
