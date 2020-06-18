# Namespaces API

Usernames and groupnames fall under a special category called namespaces.

For users and groups supported API calls see the [users](users.md) and
[groups](groups.md) documentation respectively.

[Pagination](README.md#pagination) is used.

## List namespaces

Get a list of the namespaces of the authenticated user. If the user is an
administrator, a list of all namespaces in the GitLab instance is shown.

```plaintext
GET /namespaces
```

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/namespaces"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "user1",
    "path": "user1",
    "kind": "user",
    "full_path": "user1"
  },
  {
    "id": 2,
    "name": "group1",
    "path": "group1",
    "kind": "group",
    "full_path": "group1",
    "parent_id": null,
    "members_count_with_descendants": 2
  },
  {
    "id": 3,
    "name": "bar",
    "path": "bar",
    "kind": "group",
    "full_path": "foo/bar",
    "parent_id": 9,
    "members_count_with_descendants": 5
  }
]
```

Users on GitLab.com [Bronze or higher](https://about.gitlab.com/pricing/#gitlab-com) may also see
the `plan` parameter associated with a namespace:

```json
[
  {
    "id": 1,
    "name": "user1",
    "plan": "bronze",
    ...
  }
]
```

NOTE: **Note:** Only group maintainers/owners are presented with `members_count_with_descendants`, as well as `plan` **(BRONZE ONLY)**.

## Search for namespace

Get all namespaces that match a string in their name or path.

```plaintext
GET /namespaces?search=foobar
```

| Attribute | Type   | Required | Description |
| --------- | ------ | -------- | ----------- |
| `search`  | string | no       | Returns a list of namespaces the user is authorized to see based on the search criteria |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/namespaces?search=twitter"
```

Example response:

```json
[
  {
    "id": 4,
    "name": "twitter",
    "path": "twitter",
    "kind": "group",
    "full_path": "twitter",
    "parent_id": null,
    "members_count_with_descendants": 2
  }
]
```

## Get namespace by ID

Get a namespace by ID.

```plaintext
GET /namespaces/:id
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer/string | yes      | ID or [URL-encoded path of the namespace](README.md#namespaced-path-encoding) |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/namespaces/2"
```

Example response:

```json
{
  "id": 2,
  "name": "group1",
  "path": "group1",
  "kind": "group",
  "full_path": "group1",
  "parent_id": null,
  "members_count_with_descendants": 2
}
```

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/namespaces/group1"
```

Example response:

```json
{
  "id": 2,
  "name": "group1",
  "path": "group1",
  "kind": "group",
  "full_path": "group1",
  "parent_id": null,
  "members_count_with_descendants": 2
}
```
