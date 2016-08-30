# Deploy Keys

## List all deploy keys

Get a list of all deploy keys across all projects.

```
GET /deploy_keys
```

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/deploy_keys"
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
| `id` | integer | yes | The ID of the project |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/5/deploy_keys"
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

## Single deploy key

Get a single key.

```
GET /projects/:id/deploy_keys/:key_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer | yes | The ID of the project |
| `key_id`  | integer | yes | The ID of the deploy key |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/5/deploy_keys/11"
```

Example response:

```json
{
  "id": 1,
  "title": "Public key",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
  "created_at": "2013-10-02T10:12:29Z"
}
```

## Add deploy key

Creates a new deploy key for a project.

If the deploy key already exists in another project, it will be joined to current
project only if original one was is accessible by the same user.

```
POST /projects/:id/deploy_keys
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`    | integer | yes | The ID of the project |
| `title` | string  | yes | New deploy key's title |
| `key`   | string  | yes | New deploy key |

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" --header "Content-Type: application/json" --data '{"title": "My deploy key", "key": "ssh-rsa AAAA..."}' "https://gitlab.example.com/api/v3/projects/5/deploy_keys/"
```

Example response:

```json
{
   "key" : "ssh-rsa AAAA...",
   "id" : 12,
   "title" : "My deploy key",
   "created_at" : "2015-08-29T12:44:31.550Z"
}
```

## Delete deploy key

Delete a deploy key from a project

```
DELETE /projects/:id/deploy_keys/:key_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer | yes | The ID of the project |
| `key_id`  | integer | yes | The ID of the deploy key |

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" "https://gitlab.example.com/api/v3/projects/5/deploy_keys/13"
```

Example response:

```json
{
   "updated_at" : "2015-08-29T12:50:57.259Z",
   "key" : "ssh-rsa AAAA...",
   "public" : false,
   "title" : "My deploy key",
   "user_id" : null,
   "created_at" : "2015-08-29T12:50:57.259Z",
   "fingerprint" : "6a:33:1f:74:51:c0:39:81:79:ec:7a:31:f8:40:20:43",
   "id" : 13
}
```

## Enable a deploy key

Enables a deploy key for a project so this can be used. Returns the enabled key, with a status code 201 when successful.

```bash
curl --request POST --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/5/deploy_keys/13/enable
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer | yes | The ID of the project |
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

## Disable a deploy key

Disable a deploy key for a project. Returns the disabled key.

```bash
curl --request DELETE --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/5/deploy_keys/13/disable
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer | yes | The ID of the project |
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
