# Namespaces

Namespaces account for usernames and groupnames.

[Pagination](README.md#pagination) is used.

## List namespaces

Get a list of namespaces. As a user, your namespaces are listed whereas if you
are an administrator you get a list of all namespaces in the GitLab instance.

```
GET /namespaces
```

```bash
curl -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/namespaces
```

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

```bash
curl -H "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/namespaces?search=twitter
```

```json
[
  {
    "id": 4,
    "path": "twitter",
    "kind": "group"
  }
]
```
