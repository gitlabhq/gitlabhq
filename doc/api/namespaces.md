# Namespaces

Usernames and groupnames fall under a special category called namespaces.

For users and groups supported API calls see the [users](users.md) and
[groups](groups.md) documentation respectively.

[Pagination](README.md#pagination) is used.

## List namespaces

Get a list of the namespaces of the authenticated user. If the user is an
administrator, a list of all namespaces in the GitLab instance is shown.

```
GET /namespaces
```

Example request:

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/namespaces
```

Example response:

```json
[
  {
    "id": 1,
    "path": "user1",
    "kind": "user"
  },
  {
    "id": 2,
    "path": "group1",
    "kind": "group"
  }
]
```

## Search for namespace

Get all namespaces that match a string in their name or path.

```
GET /namespaces?search=foobar
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `search`  | string | no | Returns a list of namespaces the user is authorized to see based on the search criteria |

Example request:

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/namespaces?search=twitter
```

Example response:

```json
[
  {
    "id": 4,
    "path": "twitter",
    "kind": "group"
  }
]
```
