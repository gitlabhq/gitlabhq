---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Deploy keys API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

The deploy keys API can return in responses fingerprints of the public key in the following fields:

- `fingerprint` (MD5 hash). Not available on FIPS-enabled systems.
- `fingerprint_sha256` (SHA256 hash). [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91302) in GitLab 15.2.

## List all deploy keys

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> `projects_with_readonly_access` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119147) in GitLab 16.0.

Get a list of all deploy keys across all projects of the GitLab instance. This
endpoint requires administrator access and is not available on GitLab.com.

```plaintext
GET /deploy_keys
```

Supported attributes:

| Attribute   | Type     | Required | Description           |
|:------------|:---------|:---------|:----------------------|
| `public` | boolean | No | Only return deploy keys that are public. Defaults to `false`. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/deploy_keys?public=true"
```

Example response:

```json
[
  {
    "id": 1,
    "title": "Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
    "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
    "fingerprint_sha256": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU",
    "created_at": "2013-10-02T10:12:29Z",
    "expires_at": null,
    "projects_with_write_access": [
      {
        "id": 73,
        "description": null,
        "name": "project2",
        "name_with_namespace": "Sidney Jones / project2",
        "path": "project2",
        "path_with_namespace": "sidney_jones/project2",
        "created_at": "2021-10-25T18:33:17.550Z"
      },
      {
        "id": 74,
        "description": null,
        "name": "project3",
        "name_with_namespace": "Sidney Jones / project3",
        "path": "project3",
        "path_with_namespace": "sidney_jones/project3",
        "created_at": "2021-10-25T18:33:17.666Z"
      }
    ],
    "projects_with_readonly_access": []
  },
  {
    "id": 3,
    "title": "Another Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDIJFwIL6YNcCgVBLTHgM6hzmoL5vf0ThDKQMWT3HrwCjUCGPwR63vBwn6+/Gx+kx+VTo9FuojzR0O4XfwD3LrYA+oT3ETbn9U4e/VS4AH/G4SDMzgSLwu0YuPe517FfGWhWGQhjiXphkaQ+6bXPmcASWb0RCO5+pYlGIfxv4eFGQ=="
    "fingerprint": "0b:cf:58:40:b9:23:96:c7:ba:44:df:0e:9e:87:5e:75",
    "fingerprint_sha256": "SHA256:lGI/Ys/Wx7PfMhUO1iuBH92JQKYN+3mhJZvWO4Q5ims",
    "created_at": "2013-10-02T11:12:29Z",
    "expires_at": null,
    "projects_with_write_access": [],
    "projects_with_readonly_access": [
      {
        "id": 74,
        "description": null,
        "name": "project3",
        "name_with_namespace": "Sidney Jones / project3",
        "path": "project3",
        "path_with_namespace": "sidney_jones/project3",
        "created_at": "2021-10-25T18:33:17.666Z"
      }
    ]
  }
]
```

## Add deploy key

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/478476) in GitLab 17.5.

Create a deploy key for the GitLab instance. This endpoint requires administrator
access.

```plaintext
POST /deploy_keys
```

Supported attributes:

| Attribute     | Type     | Required | Description                                                                                                                       |
|:--------------|:---------|:---------|:----------------------------------------------------------------------------------------------------------------------------------|
| `key`         | string   | yes      | New deploy key                                                                                                                    |
| `title`       | string   | yes      | New deploy key's title                                                                                                            |
| `expires_at`  | datetime | no       | Expiration date for the deploy key. Does not expire if no value is provided. Expected in ISO 8601 format (`2024-12-31T08:00:00Z`) |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
     --data '{"title": "My deploy key", "key": "ssh-rsa AAAA...", "expired_at": "2024-12-31T08:00:00Z"}' \
     "https://gitlab.example.com/api/v4/deploy_keys/"
```

Example response:

```json
{
  "id" : 5,
  "title" : "My deploy key",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
  "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
  "fingerprint_sha256": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU",
  "usage_type": "auth_and_signing",
  "created_at": "2024-10-03T01:32:21.992Z",
  "expires_at": "2024-12-31T08:00:00.000Z"
}
```

## List deploy keys for project

Get a list of a project's deploy keys.

```plaintext
GET /projects/:id/deploy_keys
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/deploy_keys"
```

Example response:

```json
[
  {
    "id": 1,
    "title": "Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
    "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
    "fingerprint_sha256": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU",
    "created_at": "2013-10-02T10:12:29Z",
    "expires_at": null,
    "can_push": false
  },
  {
    "id": 3,
    "title": "Another Public key",
    "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDIJFwIL6YNcCgVBLTHgM6hzmoL5vf0ThDKQMWT3HrwCjUCGPwR63vBwn6+/Gx+kx+VTo9FuojzR0O4XfwD3LrYA+oT3ETbn9U4e/VS4AH/G4SDMzgSLwu0YuPe517FfGWhWGQhjiXphkaQ+6bXPmcASWb0RCO5+pYlGIfxv4eFGQ=="
    "fingerprint": "0b:cf:58:40:b9:23:96:c7:ba:44:df:0e:9e:87:5e:75",
    "fingerprint_sha256": "SHA256:lGI/Ys/Wx7PfMhUO1iuBH92JQKYN+3mhJZvWO4Q5ims",
    "created_at": "2013-10-02T11:12:29Z",
    "expires_at": null,
    "can_push": false
  }
]
```

## List project deploy keys for user

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88917) in GitLab 15.1.

Get a list of a specified user (requestee) and the authenticated user's (requester) common [project deploy keys](../user/project/deploy_keys/_index.md#scope). It lists only the **enabled project keys from the common projects of requester and requestee**.

```plaintext
GET /users/:id_or_username/project_deploy_keys
```

Parameters:

| Attribute          | Type   | Required | Description                                                        |
|------------------- |--------|----------|------------------------------------------------------------------- |
| `id_or_username`   | string | yes      | The ID or username of the user to get the project deploy keys for. |

```json
[
    {
        "id": 1,
        "title": "Key A",
        "created_at": "2022-05-30T12:28:27.855Z",
        "expires_at": null,
        "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkYXU2fVeO4/0rDCSsswP5iIX2+B6tv15YT3KObgyDl Key",
        "fingerprint": "40:8e:fa:df:70:f7:a7:06:1e:0d:6f:ae:f2:27:92:01",
        "fingerprint_sha256": "SHA256:Ojq2LZW43BFK/AMP81jBkDGn9YpPWYRNcViKBB44LPU"
    },
    {
        "id": 2,
        "title": "Key B",
        "created_at": "2022-05-30T13:34:56.219Z",
        "expires_at": null,
        "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
        "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
        "fingerprint_sha256": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU",
    }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/users/20/project_deploy_keys"
```

Example response:

```json
[
  {
    "id": 1,
    "title": "Key A",
    "created_at": "2022-05-30T12:28:27.855Z",
    "expires_at": "2022-10-30T12:28:27.855Z",
    "key": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILkYXU2fVeO4/0rDCSsswP5iIX2+B6tv15YT3KObgyDl Key",
    "fingerprint": "40:8e:fa:df:70:f7:a7:06:1e:0d:6f:ae:f2:27:92:01",
    "fingerprint_sha256": "SHA256:Ojq2LZW43BFK/AMP81jBkDGn9YpPWYRNcViKBB44LPU"
  }
]
```

## Get a single deploy key

Get a single key.

```plaintext
GET /projects/:id/deploy_keys/:key_id
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `key_id`  | integer | yes | The ID of the deploy key |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/deploy_keys/11"
```

Example response:

```json
{
  "id": 1,
  "title": "Public key",
  "key": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNJAkI3Wdf0r13c8a5pEExB2YowPWCSVzfZV22pNBc1CuEbyYLHpUyaD0GwpGvFdx2aP7lMEk35k6Rz3ccBF6jRaVJyhsn5VNnW92PMpBJ/P1UebhXwsFHdQf5rTt082cSxWuk61kGWRQtk4ozt/J2DF/dIUVaLvc+z4HomT41fQ==",
  "fingerprint": "4a:9d:64:15:ed:3a:e6:07:6e:89:36:b3:3b:03:05:d9",
  "fingerprint_sha256": "SHA256:Jrs3LD1Ji30xNLtTVf9NDCj7kkBgPBb2pjvTZ3HfIgU",
  "created_at": "2013-10-02T10:12:29Z",
  "expires_at": null,
  "can_push": false
}
```

## Add deploy key for a project

Creates a new deploy key for a project.

If the deploy key already exists in another project, it's joined to the current
project only if the original one is accessible by the same user.

```plaintext
POST /projects/:id/deploy_keys
```

| Attribute    | Type | Required | Description |
| -----------  | ---- | -------- | ----------- |
| `id`         | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `key`        | string   | yes | New deploy key |
| `title`      | string   | yes | New deploy key's title |
| `can_push`   | boolean  | no  | Can deploy key push to the project's repository |
| `expires_at` | datetime | no | Expiration date for the deploy key. Does not expire if no value is provided. Expected in ISO 8601 format (`2019-03-15T08:00:00Z`) |

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
   "created_at" : "2015-08-29T12:44:31.550Z",
   "expires_at": null
}
```

## Update deploy key

Updates a deploy key for a project.

```plaintext
PUT /projects/:id/deploy_keys/:key_id
```

| Attribute  | Type | Required | Description |
| ---------  | ---- | -------- | ----------- |
| `id`       | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `can_push` | boolean | no  | Can deploy key push to the project's repository |
| `title`    | string  | no | New deploy key's title |

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
   "expires_at": null,
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
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `key_id`  | integer | yes | The ID of the deploy key |

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/deploy_keys/13"
```

## Enable a deploy key

Enables a deploy key for a project so this can be used. Returns the enabled key, with a status code 201 when successful.

```plaintext
POST /projects/:id/deploy_keys/:key_id/enable
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | integer/string | yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `key_id`  | integer | yes | The ID of the deploy key |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/deploy_keys/12/enable"
```

Example response:

```json
{
   "key" : "ssh-rsa AAAA...",
   "id" : 12,
   "title" : "My deploy key",
   "created_at" : "2015-08-29T12:44:31.550Z",
   "expires_at": null
}
```

## Add deploy keys to multiple projects

If you want to add the same deploy key to multiple projects in the same
group, this can be achieved with the API.

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
