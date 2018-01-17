# Deploy Keys API

## List all deploy keys

Get a list of all deploy keys across all projects of the GitLab instance. This endpoint requires admin access.

```
GET /deploy_keys
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/deploy_keys"
```

Example response:

```json
[
  {
    "id": 1,
    "title": "Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",    
    "created_at": "2013-10-02T10:12:29Z"
  },
  {
    "id": 3,
    "title": "Another Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",    
    "created_at": "2013-10-02T11:12:29Z"
  }
]
```

## List project deploy keys

Get a list of a project's deploy keys.

```
GET /projects/:id/deploy_keys
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/5/deploy_keys"
```

Example response:

```json
[
  {
    "id": 1,
    "title": "Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
    "created_at": "2013-10-02T10:12:29Z",
    "can_push": false
  },
  {
    "id": 3,
    "title": "Another Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
    "created_at": "2013-10-02T11:12:29Z",
    "can_push": false
  }
]
```

## Single deploy key

Get a single key.

```
GET /projects/:id/deploy_keys/:key_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `key_id`  | integer | yes | The ID of the deploy key |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/5/deploy_keys/11"
```

Example response:

```json
{
  "id": 1,
  "title": "Public key",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
  "created_at": "2013-10-02T10:12:29Z",
  "can_push": false
}
```

## Add deploy key

Creates a new deploy key for a project.

If the deploy key already exists in another project, it will be joined to current
project only if original one is accessible by the same user.

```
POST /projects/:id/deploy_keys
```

| Attribute  | Type | Required | Description |
| ---------  | ---- | -------- | ----------- |
| `id`       | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `title`    | string  | yes | New deploy key's title |
| `key`      | string  | yes | New deploy key |
| `can_push` | boolean | no  | Can deploy key push to the project's repository |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --header "Content-Type: application/json" --data '{"title": "My deploy key", "key": "ssh-rsa AAAA...", "can_push": "true"}' "https://gitlab.example.com/api/v4/projects/5/deploy_keys/"
```

Example response:

```json
{
   "key" : "ssh-rsa AAAA...",
   "id" : 12,
   "title" : "My deploy key",
   "can_push": true,
   "created_at" : "2015-08-29T12:44:31.550Z"
}
```

## Update deploy key

Updates a deploy key for a project.

```
PUT /projects/:id/deploy_keys/:key_id
```

| Attribute  | Type | Required | Description |
| ---------  | ---- | -------- | ----------- |
| `id`       | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `title`    | string  | no | New deploy key's title |
| `can_push` | boolean | no  | Can deploy key push to the project's repository |

```bash
curl --request PUT --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --header "Content-Type: application/json" --data '{"title": "New deploy key", "can_push": true}' "https://gitlab.example.com/api/v4/projects/5/deploy_keys/11"
```

Example response:

```json
{
   "id": 11,
   "title": "New deploy key",
   "key": "ssh-rsa AAAA...",
   "created_at": "2015-08-29T12:44:31.550Z",
   "can_push": true
}
```

## Delete deploy key

Removes a deploy key from the project. If the deploy key is used only for this project, it will be deleted from the system.

```
DELETE /projects/:id/deploy_keys/:key_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `key_id`  | integer | yes | The ID of the deploy key |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v4/projects/5/deploy_keys/13"
```

## Enable a deploy key

Enables a deploy key for a project so this can be used. Returns the enabled key, with a status code 201 when successful.

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/deploy_keys/13/enable
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `key_id`  | integer | yes | The ID of the deploy key |

Example response:

```json
{
   "key" : "ssh-rsa AAAA...",
   "id" : 12,
   "title" : "My deploy key",
   "created_at" : "2015-08-29T12:44:31.550Z"
}
```
