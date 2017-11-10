# Custom Attributes API

Every API call to custom attributes must be authenticated as administrator.

Custom attributes are currently available on users, groups, and projects,
which will be referred to as "resource" in this documentation.

## List custom attributes

Get all custom attributes on a resource.

```
GET /users/:id/custom_attributes
GET /groups/:id/custom_attributes
GET /projects/:id/custom_attributes
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a resource |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/users/42/custom_attributes
```

Example response:

```json
[
   {
      "key": "location",
      "value": "Antarctica"
   },
   {
      "key": "role",
      "value": "Developer"
   }
]
```

## Single custom attribute

Get a single custom attribute on a resource.

```
GET /users/:id/custom_attributes/:key
GET /groups/:id/custom_attributes/:key
GET /projects/:id/custom_attributes/:key
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a resource |
| `key` | string | yes | The key of the custom attribute |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/users/42/custom_attributes/location
```

Example response:

```json
{
   "key": "location",
   "value": "Antarctica"
}
```

## Set custom attribute

Set a custom attribute on a resource. The attribute will be updated if it already exists,
or newly created otherwise.

```
PUT /users/:id/custom_attributes/:key
PUT /groups/:id/custom_attributes/:key
PUT /projects/:id/custom_attributes/:key
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a resource |
| `key` | string | yes | The key of the custom attribute |
| `value` | string | yes | The value of the custom attribute |

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --data "value=Greenland" https://gitlab.example.com/api/v4/users/42/custom_attributes/location
```

Example response:

```json
{
   "key": "location",
   "value": "Greenland"
}
```

## Delete custom attribute

Delete a custom attribute on a resource.

```
DELETE /users/:id/custom_attributes/:key
DELETE /groups/:id/custom_attributes/:key
DELETE /projects/:id/custom_attributes/:key
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a resource |
| `key` | string | yes | The key of the custom attribute |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/users/42/custom_attributes/location
```
