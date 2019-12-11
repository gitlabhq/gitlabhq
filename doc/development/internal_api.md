# Internal API

The internal API is used by different GitLab components, it can not be
used by other consumers. This documentation is intended for people
working on the GitLab codebase.

This documentation does not yet include the internal API used by
GitLab Pages.

## Authentication

These methods are all authenticated using a shared secret. This secret
is stored in a file at the path configured in `config/gitlab.yml` by
default this is in the root of the rails app named
`.gitlab_shell_secret`

To authenticate using that token, clients read the contents of that
file, and include the token Base64 encoded in a `secret_token` param
or in the `Gitlab-Shared-Secret` header.

NOTE: **Note:**
The internal API used by GitLab Pages uses a different kind of
authentication.

## Git Authentication

This is called by Gitaly and GitLab-shell to check access to a
repository.

When called from GitLab-shell no changes are passed and the internal
API replies with the information needed to pass the request on to
Gitaly.

When called from Gitaly in a `pre-receive` hook the changes are passed
and those are validated to determine if the push is allowed.

```
POST /internal/allowed
```

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `key_id`  | string | no       | Id of the SSH-key used to connect to GitLab-shell |
| `username` | string | no      | Username from the certificate used to connect to GitLab-Shell |
| `project`  | string | no (if `gl_repository` is passed) | Path to the project |
| `gl_repository`  | string | no (if `project` is passed) | Path to the project |
| `protocol` | string | yes     | SSH when called from GitLab-shell, HTTP or SSH when called from Gitaly |
| `action`   | string | yes     | Git command being run (`git-upload-pack`, `git-receive-pack`, `git-upload-archive`) |
| `changes`  | string | yes     | `<oldrev> <newrev> <refname>` when called from Gitaly, The magic string `_any` when called from GitLab Shell |
| `check_ip` | string | no     | Ip adress from which call to GitLab Shell was made |

Example request:

```sh
curl --request POST --header "Gitlab-Shared-Secret: <Base64 encoded token>" --data "key_id=11&project=gnuwget/wget2&action=git-upload-pack&protocol=ssh" http://localhost:3001/api/v4/internal/allowed
```

Example response:

```
{
  "status": true,
  "gl_repository": "project-3",
  "gl_project_path": "gnuwget/wget2",
  "gl_id": "user-1",
  "gl_username": "root",
  "git_config_options": [],
  "gitaly": {
    "repository": {
      "storage_name": "default",
      "relative_path": "@hashed/4e/07/4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce.git",
      "git_object_directory": "",
      "git_alternate_object_directories": [],
      "gl_repository": "project-3",
      "gl_project_path": "gnuwget/wget2"
    },
    "address": "unix:/Users/bvl/repos/gitlab/gitaly.socket",
    "token": null
  },
  "gl_console_messages": []
}
```

### Known consumers

- Gitaly
- GitLab-shell

## LFS Authentication

This is the endpoint that gets called from GitLab-shell to provide
information for LFS clients when the repository is accessed over SSH.

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `key_id`  | string | no       | Id of the SSH-key used to connect to GitLab-shell |
| `username`| string | no       | Username from the certificate used to connect to GitLab-Shell |
| `project` | string | no       | Path to the project |

Example request:

```sh
curl --request POST --header "Gitlab-Shared-Secret: <Base64 encoded token>" --data "key_id=11&project=gnuwget/wget2" http://localhost:3001/api/v4/internal/lfs_authenticate
```

```
{
  "username": "root",
  "lfs_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7ImFjdG9yIjoicm9vdCJ9LCJqdGkiOiIyYWJhZDcxZC0xNDFlLTQ2NGUtOTZlMi1mODllYWRiMGVmZTYiLCJpYXQiOjE1NzAxMTc2NzYsIm5iZiI6MTU3MDExNzY3MSwiZXhwIjoxNTcwMTE5NDc2fQ.g7atlBw1QMY7QEBVPE0LZ8ZlKtaRzaMRmNn41r2YITM",
  "repository_http_path": "http://localhost:3001/gnuwget/wget2.git",
  "expires_in": 1800
}
```

### Known consumers

- GitLab-shell

## Authorized Keys Check

This endpoint is called by the GitLab-shell authorized keys
check. Which is called by OpenSSH for [fast SSH key
lookup](../administration/operations/fast_ssh_key_lookup.md).

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `key`     | string | yes      | SSH key as passed by OpenSSH to GitLab-shell |

```
GET /internal/authorized_keys
```

Example request:

```sh
curl --request GET --header "Gitlab-Shared-Secret: <Base64 encoded secret>""http://localhost:3001/api/v4/internal/authorized_keys?key=<key as passed by OpenSSH>"
```

Example response:

```
{
  "id": 11,
  "title": "admin@example.com",
  "key": "ssh-rsa ...",
  "created_at": "2019-06-27T15:29:02.219Z"
}
```

### Known consumers

- GitLab-shell

## Get user for user id or key

This endpoint is used when a user performs `ssh git@gitlab.com`. It
discovers the user associated with an SSH key.

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `key_id` | integer | no | The id of the SSH key used as found in the authorized-keys file or through the `/authorized_keys` check |
| `username` | string | no | Username of the user being looked up, used by GitLab-shell when authenticating using a certificate |

```
GET /internal/discover
```

Example request:

```sh
curl --request GET --header "Gitlab-Shared-Secret: <Base64 encoded secret>" "http://localhost:3001/api/v4/internal/discover?key_id=7"
```

Example response:

```
{
  "id": 7,
  "name": "Dede Eichmann",
  "username": "rubi"
}
```

### Known consumers

- GitLab-shell

## Instance information

This get's some generic information about the instance. This is used
by Geo nodes to get information about eachother

```
GET /internal/check
```

Example request:

```sh
curl --request GET --header "Gitlab-Shared-Secret: <Base64 encoded secret>" "http://localhost:3001/api/v4/internal/check"
```

Example response:

```
{
  "api_version": "v4",
  "gitlab_version": "12.3.0-pre",
  "gitlab_rev": "d69c988e6a6",
  "redis": true
}
```

### Known consumers

- GitLab Geo
- GitLab-shell's `bin/check`

## Get new 2FA recovery codes using an SSH key

This is called from GitLab-shell and allows users to get new 2FA
recovery codes based on their SSH key

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `key_id`  | integer | no | The id of the SSH key used as found in the authorized-keys file or through the `/authorized_keys` check |
| `user_id` | integer | no | **Deprecated** User_id for which to generate new recovery codes |

```
GET /internal/two_factor_recovery_codes
```

Example request:

```sh
curl --request POST --header "Gitlab-Shared-Secret: <Base64 encoded secret>" --data "key_id=7" http://localhost:3001/api/v4/internal/two_factor_recovery_codes
```

Example response:

```
{
  "success": true,
  "recovery_codes": [
    "d93ee7037944afd5",
    "19d7b84862de93dd",
    "1e8c52169195bf71",
    "be50444dddb7ca84",
    "26048c77d161d5b7",
    "482d5c03d1628c47",
    "d2c695e309ce7679",
    "dfb4748afc4f12a7",
    "0e5f53d1399d7979",
    "af04d5622153b020"
  ]
}
```

### Known consumers

- GitLab-shell

## Incrementing counter on pre-receive

This is called from the Gitaly hooks increasing the reference counter
for a push that might be accepted.

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `gl_repository` | string | yes | repository identifier for the repository receiving the push |

```
POST /internal/pre_receive
```

Example request:

```sh
curl --request POST --header "Gitlab-Shared-Secret: <Base64 encoded secret>" --data "gl_repository=project-7" http://localhost:3001/api/v4/internal/pre_receive
```

Example response:

```
{
  "reference_counter_increased": true
}
```

## PostReceive

Called from Gitaly after a receiving a push. This triggers the
`PostReceive`-worker in Sidekiq, processes the passed push options and
builds the response including messages that need to be displayed to
the user.

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `identifier` | string | yes | `user-[id]` or `key-[id]` Identifying the user performing the push |
| `gl_repository` | string | yes | identifier of the repository being pushed to |
| `push_options` | string array | no | array of push options |
| `changes` | string | no | refs to be updated in the push in the format `oldrev newrev refname\n`. |

```
POST /internal/post_receive
```

Example Request:

```sh
curl --request POST --header "Gitlab-Shared-Secret: <Base64 encoded secret>" --data "gl_repository=project-7" --data "identifier=user-1" --data "changes=0000000000000000000000000000000000000000 fd9e76b9136bdd9fe217061b497745792fe5a5ee gh-pages\n"  http://localhost:3001/api/v4/internal/post_receive
```

Example response:

```
{
  "messages": [
    {
      "message": "Hello from post-receive",
      "type": "alert"
    }
  ],
  "reference_counter_decreased": true
}
```
