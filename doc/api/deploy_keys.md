---
stage: Release
group: Release
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Deploy keys API

## List all deploy keys

Get a list of all deploy keys across all projects of the GitLab instance. This endpoint requires administrator access and is not available on GitLab.com.

```plaintext
GET /deploy_keys
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/deploy_keys"
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

```plaintext
GET /projects/:id/deploy_keys
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/deploy_keys"
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

```plaintext
GET /projects/:id/deploy_keys/:key_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `key_id`  | integer | yes | The ID of the deploy key |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/deploy_keys/11"
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

If the deploy key already exists in another project, it's joined to the current
project only if the original one is accessible by the same user.

```plaintext
POST /projects/:id/deploy_keys
```

| Attribute  | Type | Required | Description |
| ---------  | ---- | -------- | ----------- |
| `id`       | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `title`    | string  | yes | New deploy key's title |
| `key`      | string  | yes | New deploy key |
| `can_push` | boolean | no  | Can deploy key push to the project's repository |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
     --data '{"title": "My deploy key", "key": "ssh-rsa AAAA...", "can_push": "true"}' \
     "https://gitlab.example.com/api/v4/projects/5/deploy_keys/"
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

```plaintext
PUT /projects/:id/deploy_keys/:key_id
```

| Attribute  | Type | Required | Description |
| ---------  | ---- | -------- | ----------- |
| `id`       | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `title`    | string  | no | New deploy key's title |
| `can_push` | boolean | no  | Can deploy key push to the project's repository |

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
     --data '{"title": "New deploy key", "can_push": true}' "https://gitlab.example.com/api/v4/projects/5/deploy_keys/11"
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

Removes a deploy key from the project. If the deploy key is used only for this project, it's deleted from the system.

```plaintext
DELETE /projects/:id/deploy_keys/:key_id
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
| `key_id`  | integer | yes | The ID of the deploy key |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/deploy_keys/13"
```

## Enable a deploy key

Enables a deploy key for a project so this can be used. Returns the enabled key, with a status code 201 when successful.

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/deploy_keys/13/enable"
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user |
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

## Adding deploy keys to multiple projects

If you want to easily add the same deploy key to multiple projects in the same
group, this can be achieved quite easily with the API.

First, find the ID of the projects you're interested in, by either listing all
projects:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects"
```

Or finding the ID of a group:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups"
```

Then listing all projects in that group (for example, group 1234):

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/1234"
```

With those IDs, add the same deploy key to all:

```shell
for project_id in 321 456 987; do
    curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
         --header "Content-Type: application/json" \
         --data '{"title": "my key", "key": "ssh-rsa AAAA..."}' \
         "https://gitlab.example.com/api/v4/projects/${project_id}/deploy_keys"
done
```
