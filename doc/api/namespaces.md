# Namespaces API

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
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/namespaces
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
    "user_id": 3,
  },
  {
    "id": 2,
    "name": "group1",
    "path": "group1",
    "kind": "group",
    "full_path": "group1",
    "parent_id": null,
    "user_id": null,
    "members_count_with_descendants": 2
  },
  {
    "id": 3,
    "name": "bar",
    "path": "bar",
    "kind": "group",
    "full_path": "foo/bar",
    "parent_id": 9,
    "user_id": null,
    "members_count_with_descendants": 5
  }
]
```

**Note**: `members_count_with_descendants` are presented only for group masters/owners.

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
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/namespaces?search=twitter
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
    "user_id": null,
    "members_count_with_descendants": 2
  }
]
```

## Get namespace by ID

Get a namespace by ID.

```
GET /namespaces/:id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | ID or path of the namespace |

Example request:

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/namespaces/2
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
  "user_id": null,
  "members_count_with_descendants": 2
}
```

Example request:

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/namespaces/group1
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
  "user_id": null,
  "members_count_with_descendants": 2
}
```

## Get projects of selected namespace's

Get projects of namespace selected by ID.

```
GET /namespaces/:id/projects
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | ID or path of the namespace |

Example request:

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/namespaces/2/projects
```

Example response:

```json
[
  {
    "id":3,
    "description":null,
    "name":"project1",
    "name_with_namespace":"group1 / project1",
    "path":"project1",
    "path_with_namespace":"group1/project1",
    "created_at":"2018-01-09T00:12:50.460Z",
    "default_branch":null,
    "tag_list":[],
    "ssh_url_to_repo":"git@gitlab.example.com:group1/project1.git",
    "http_url_to_repo":"http://gitlab.example.com/group1/project1.git",
    "web_url":"http://gitlab.example.com/group1/project1",
    "avatar_url":null,
    "star_count":0,
    "forks_count":0,
    "last_activity_at":"2018-01-09T00:12:50.460Z"
  }
]
```
