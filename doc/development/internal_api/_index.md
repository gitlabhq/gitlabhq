---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
title: Internal API
---

The internal API is used by different GitLab components, it cannot be
used by other consumers. This documentation is intended for people
working on the GitLab codebase.

This documentation does not yet include the internal API used by
GitLab Pages.

For information on the GitLab Subscriptions internal API, see [the dedicated page](gitlab_subscriptions.md).

## Add new endpoints

API endpoints should be externally accessible by default, with proper authentication and authorization.
Before adding a new internal endpoint, consider if the API would benefit the wider GitLab community and can be made externally accessible.

One reason we might favor internal API endpoints sometimes is when using such an endpoint requires
internal data that external actors cannot have. For example, in the internal Pages API we might use
a secret token that identifies a request as internal or sign a request with a public key that is
not available to a wider community.

Another reason to separate something into an internal API is when request to such API endpoint
should never go through an edge (public) load balancer. This way we can configure different rate
limiting rules and policies around how the endpoint is being accessed, because we know that only
internal requests can be made to that endpoint going through an internal load balancer.

## Authentication

These methods are all authenticated using a shared secret. This secret
is stored in a file at the path configured in `config/gitlab.yml` by
default this is in the root of the rails app named
`.gitlab_shell_secret`

To authenticate using that token, clients:

1. Read the contents of that file.
1. Use the file contents to generate a JSON Web Token (`JWT`).
1. Pass the JWT in the `Gitlab-Shell-Api-Request` header.

## Git Authentication

Called by [Gitaly](https://gitlab.com/gitlab-org/gitaly) and
[GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell) to check access to a
repository.

- **When called from GitLab Shell**: No changes are passed, and the internal
  API replies with the information needed to pass the request on to Gitaly.
- **When called from Gitaly in a `pre-receive` hook**: The changes are passed
  and validated to determine if the push is allowed.

Calls are limited to 50 seconds each.

This endpoint is covered in more detail on [its own page](internal_api_allowed.md), due to the scope of what it covers.

```plaintext
POST /internal/allowed
```

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `key_id`  | string | no       | ID of the SSH-key used to connect to GitLab Shell |
| `username` | string | no      | Username from the certificate used to connect to GitLab Shell |
| `project`  | string | no (if `gl_repository` is passed) | Path to the project |
| `gl_repository`  | string | no (if `project` is passed) | Repository identifier, such as `project-7` |
| `protocol` | string | yes     | SSH when called from GitLab Shell, HTTP or SSH when called from Gitaly |
| `action`   | string | yes     | Git command being run (`git-upload-pack`, `git-receive-pack`, `git-upload-archive`) |
| `changes`  | string | yes     | `<oldrev> <newrev> <refname>` when called from Gitaly, the magic string `_any` when called from GitLab Shell |
| `check_ip` | string | no     | IP address from which call to GitLab Shell was made |

Example request:

```shell
curl --request POST --header "Gitlab-Shell-Api-Request: <JWT token>" \
     --data "key_id=11&project=gnuwget/wget2&action=git-upload-pack&protocol=ssh" \
     "http://localhost:3001/api/v4/internal/allowed"
```

Example response:

```json
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
- GitLab Shell

## LFS Authentication

This is the endpoint that gets called from GitLab Shell to provide
information for LFS clients when the repository is accessed over SSH.

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `key_id`  | string | no       | ID of the SSH-key used to connect to GitLab Shell |
| `username`| string | no       | Username from the certificate used to connect to GitLab Shell |
| `project` | string | no       | Path to the project |

Example request:

```shell
curl --request POST --header "Gitlab-Shell-Api-Request: <JWT token>" \
     --data "key_id=11&project=gnuwget/wget2" "http://localhost:3001/api/v4/internal/lfs_authenticate"
```

```json
{
  "username": "root",
  "lfs_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjp7ImFjdG9yIjoicm9vdCJ9LCJqdGkiOiIyYWJhZDcxZC0xNDFlLTQ2NGUtOTZlMi1mODllYWRiMGVmZTYiLCJpYXQiOjE1NzAxMTc2NzYsIm5iZiI6MTU3MDExNzY3MSwiZXhwIjoxNTcwMTE5NDc2fQ.g7atlBw1QMY7QEBVPE0LZ8ZlKtaRzaMRmNn41r2YITM",
  "repository_http_path": "http://localhost:3001/gnuwget/wget2.git",
  "expires_in": 1800
}
```

### Known consumers

- GitLab Shell

## Authorized Keys Check

This endpoint is called by the GitLab Shell authorized keys
check. Which is called by OpenSSH or GitLab SSHD for
[fast SSH key lookup](../../administration/operations/fast_ssh_key_lookup.md).

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `key`     | string | yes      | An authorized key used for public key authentication. |

```plaintext
GET /internal/authorized_keys
```

Example request:

```shell
curl --request GET --header "Gitlab-Shell-Api-Request: <JWT token>" "http://localhost:3001/api/v4/internal/authorized_keys?key=<key>"
```

Example response:

```json
{
  "id": 11,
  "title": "admin@example.com",
  "key": "ssh-rsa ...",
  "created_at": "2019-06-27T15:29:02.219Z"
}
```

### Known consumers

- GitLab Shell

## Authorized Certs

This endpoint is called by the GitLab Shell to get the namespace that has a particular CA SSH certificate
configured. It also accepts `user_identifier` to return a GitLab user for specified identifier.

| Attribute             | Type   | Required | Description |
|:----------------------|:-------|:---------|:------------|
| `key`                 | string | yes      | The fingerprint of the SSH certificate. |
| `user_identifier`     | string | yes      | The identifier of the user to whom the SSH certificate has been issued (username or primary email). |

```plaintext
GET /internal/authorized_certs
```

Example request:

```shell
curl --request GET --header "Gitlab-Shell-Api-Request: <JWT token>" "http://localhost:3001/api/v4/internal/authorized_certs?key=<key>&user_identifier=<user_identifier>"
```

Example response:

```json
{
  "success": true,
  "namespace": "gitlab-org",
  "username": "root"
}
```

### Known consumers

- GitLab Shell

## Get user for user ID or key

This endpoint is used when a user performs `ssh git@gitlab.com`. It
discovers the user associated with an SSH key.

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `key_id` | integer | no | The ID of the SSH key used as found in the authorized-keys file or through the `/authorized_keys` check |
| `username` | string | no | Username of the user being looked up, used by GitLab Shell when authenticating using a certificate |

```plaintext
GET /internal/discover
```

Example request:

```shell
curl --request GET --header "Gitlab-Shell-Api-Request: <JWT token>" "http://localhost:3001/api/v4/internal/discover?key_id=7"
```

Example response:

```json
{
  "id": 7,
  "name": "Dede Eichmann",
  "username": "rubi"
}
```

### Known consumers

- GitLab Shell

## Instance information

This gets some generic information about the instance. It's used
by Geo nodes to get information about each other.

```plaintext
GET /internal/check
```

Example request:

```shell
curl --request GET --header "Gitlab-Shell-Api-Request: <JWT token>" "http://localhost:3001/api/v4/internal/check"
```

Example response:

```json
{
  "api_version": "v4",
  "gitlab_version": "12.3.0-pre",
  "gitlab_rev": "d69c988e6a6",
  "redis": true
}
```

### Known consumers

- GitLab Geo
- GitLab Shell's `bin/check`
- Gitaly

## Get new 2FA recovery codes using an SSH key

This is called from GitLab Shell and allows users to get new 2FA
recovery codes based on their SSH key.

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `key_id`  | integer | no | The ID of the SSH key used as found in the authorized-keys file or through the `/authorized_keys` check |
| `user_id` | integer | no | **Deprecated** User ID for which to generate new recovery codes |

```plaintext
GET /internal/two_factor_recovery_codes
```

Example request:

```shell
curl --request POST --header "Gitlab-Shell-Api-Request: <JWT token>" \
     --data "key_id=7" "http://localhost:3001/api/v4/internal/two_factor_recovery_codes"
```

Example response:

```json
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

- GitLab Shell

## Get new personal access-token

Called from GitLab Shell and allows users to generate a new
personal access token.

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `name` | string | yes | The name of the new token |
| `scopes` | string array | yes | The authorization scopes for the new token, these must be valid token scopes |
| `expires_at` | string | no | Expiration date of the access token in ISO format (`YYYY-MM-DD`). |
| `key_id`  | integer | no | The ID of the SSH key used as found in the authorized-keys file or through the `/authorized_keys` check |
| `user_id` | integer | no | User ID for which to generate the new token |

```plaintext
POST /internal/personal_access_token
```

Example request:

```shell
curl --request POST --header "Gitlab-Shell-Api-Request: <JWT token>" \
     --data "user_id=29&name=mytokenname&scopes[]=read_user&scopes[]=read_repository&expires_at=2020-07-24" \
     "http://localhost:3001/api/v4/internal/personal_access_token"
```

Example response:

```json
{
  "success": true,
  "token": "Hf_79B288hRv_3-TSD1R",
  "scopes": ["read_user","read_repository"],
  "expires_at": "2020-07-24"
}
```

### Known consumers

- GitLab Shell

## Authenticate Error Tracking requests

This endpoint is called by the error tracking Go REST API application to authenticate a project.
> [Introduced](https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/1693) in GitLab 15.1.

| Attribute    | Type    | Required | Description                                                        |
|:-------------|:--------|:---------|:-------------------------------------------------------------------|
| `project_id` | integer | yes      | The ID of the project which has the associated key.                |
| `public_key` | string  | yes      | The [public key](../../api/error_tracking.md#error-tracking-client-keys) generated by the integrated Error Tracking feature. |

```plaintext
POST /internal/error_tracking/allowed
```

Example request:

```shell
curl --request POST --header "Gitlab-Shell-Api-Request: <JWT token>" \
     --data "project_id=111&public_key=generated-error-tracking-key" \
          "http://localhost:3001/api/v4/internal/error_tracking/allowed"
```

Example response:

```json
{ "enabled": true }
```

### Known consumers

- OpsTrace

## Incrementing counter on pre-receive

This is called from the Gitaly hooks increasing the reference counter
for a push that might be accepted.

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `gl_repository` | string | yes | repository identifier for the repository receiving the push |

```plaintext
POST /internal/pre_receive
```

Example request:

```shell
curl --request POST --header "Gitlab-Shell-Api-Request: <JWT token>" \
     --data "gl_repository=project-7" "http://localhost:3001/api/v4/internal/pre_receive"
```

Example response:

```json
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

```plaintext
POST /internal/post_receive
```

Example Request:

```shell
curl --request POST --header "Gitlab-Shell-Api-Request: <JWT token>" \
     --data "gl_repository=project-7" --data "identifier=user-1" \
     --data "changes=0000000000000000000000000000000000000000 fd9e76b9136bdd9fe217061b497745792fe5a5ee gh-pages\n" \
     "http://localhost:3001/api/v4/internal/post_receive"
```

Example response:

```json
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

## GitLab agent endpoints

> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/432773) in GitLab 16.7.

The following endpoints are used by the GitLab agent server (`kas`)
for various purposes.

These endpoints are all authenticated using JWT. The JWT secret is stored in a file
specified in `config/gitlab.yml`. By default, the location is in the root of the
GitLab Rails app in a file called `.gitlab_kas_secret`.

### GitLab agent information

Called from GitLab agent server (`kas`) to retrieve agent
information for the given agent token. This returns the Gitaly connection
information for the agent's project in order for `kas` to fetch and update
the agent's configuration.

```plaintext
GET /internal/kubernetes/agent_info
```

Example Request:

```shell
curl --request GET --header "Gitlab-Kas-Api-Request: <JWT token>" \
     --header "Authorization: Bearer <agent token>" "http://localhost:3000/api/v4/internal/kubernetes/agent_info"
```

### GitLab agent project information

Called from GitLab agent server (`kas`) to retrieve project
information for the given agent token. This returns the Gitaly
connection for the requested project. GitLab `kas` uses this to configure
the agent to fetch Kubernetes resources from the project repository to
sync.

Only public projects are supported. For private projects, the ability for the
agent to be authorized is [not yet implemented](https://gitlab.com/gitlab-org/gitlab/-/issues/220912).

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](../../api/rest/_index.md#namespaced-paths) |

```plaintext
GET /internal/kubernetes/project_info
```

Example Request:

```shell
curl --request GET --header "Gitlab-Kas-Api-Request: <JWT token>" \
     --header "Authorization: Bearer <agent token>" "http://localhost:3000/api/v4/internal/kubernetes/project_info?id=7"
```

### GitLab agent usage metrics

Called from GitLab agent server (`kas`) to increase the usage
metric counters.

| Attribute                                                                 | Type          | Required | Description                                                                                                                                                     |
|:--------------------------------------------------------------------------|:--------------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `counters`                                                                | hash          | no       | Hash of counters                                                                                                                                                |
| `counters["k8s_api_proxy_request"]`                                       | integer       | no       | The number to increase the `k8s_api_proxy_request` counter by                                                                                                   |
| `counters["flux_git_push_notifications_total"]`                           | integer       | no       | The number to increase the `flux_git_push_notifications_total` counter by                                                                                       |
| `counters["k8s_api_proxy_requests_via_ci_access"]`                        | integer       | no       | The number to increase the `k8s_api_proxy_requests_via_ci_access` counter by                                                                                    |
| `counters["k8s_api_proxy_requests_via_user_access"]`                      | integer       | no       | The number to increase the `k8s_api_proxy_requests_via_user_access` counter by                                                                                  |
| `counters["k8s_api_proxy_requests_via_pat_access"]`                       | integer       | no       | The number to increase the `k8s_api_proxy_requests_via_pat_access` counter by                                                                                   |
| `unique_counters`                                                         | hash          | no       | Array of unique numbers                                                                                                                                         |
| `unique_counters["k8s_api_proxy_requests_unique_users_via_ci_access"]`    | integer array | no       | The set of unique user ids that have interacted a CI Tunnel via `ci_access` to track the `k8s_api_proxy_requests_unique_users_via_ci_access` metric event       |
| `unique_counters["k8s_api_proxy_requests_unique_agents_via_ci_access"]`   | integer array | no       | The set of unique agent ids that have interacted a CI Tunnel via `ci_access` to track the `k8s_api_proxy_requests_unique_agents_via_ci_access` metric event     |
| `unique_counters["k8s_api_proxy_requests_unique_users_via_user_access"]`  | integer array | no       | The set of unique user ids that have interacted a CI Tunnel via `user_access` to track the `k8s_api_proxy_requests_unique_users_via_user_access` metric event   |
| `unique_counters["k8s_api_proxy_requests_unique_agents_via_user_access"]` | integer array | no       | The set of unique agent ids that have interacted a CI Tunnel via `user_access` to track the `k8s_api_proxy_requests_unique_agents_via_user_access` metric event |
| `unique_counters["k8s_api_proxy_requests_unique_users_via_pat_access"]`   | integer array | no       | The set of unique user ids that have used the KAS Kubernetes API proxy with PAT to track the `k8s_api_proxy_requests_unique_users_via_pat_access` metric event   |
| `unique_counters["k8s_api_proxy_requests_unique_agents_via_pat_access"]`  | integer array | no       | The set of unique agent ids that have used the KAS Kubernetes API proxy with PAT to track the `k8s_api_proxy_requests_unique_agents_via_pat_access` metric event |
| `unique_counters["flux_git_push_notified_unique_projects"]`               | integer array | no       | The set of unique projects ids that have been notified to reconcile their Flux workloads to track the `flux_git_push_notified_unique_projects` metric event     |

```plaintext
POST /internal/kubernetes/usage_metrics
```

Example Request:

```shell
curl --request POST --header "Gitlab-Kas-Api-Request: <JWT token>" --header "Content-Type: application/json" \
     --data '{"counters": {"k8s_api_proxy_request":1}}' "http://localhost:3000/api/v4/internal/kubernetes/usage_metrics"
```

### GitLab agent events

Called from GitLab agent server (`kas`) to track events.

| Attribute                                                                     | Type          | Required | Description                                                               |
|:------------------------------------------------------------------------------|:--------------|:---------|:--------------------------------------------------------------------------|
| `events`                                                                      | hash          | no       | Hash of events                                                            |
| `events["k8s_api_proxy_requests_unique_users_via_ci_access"]`                 | hash array    | no       | Array of events for `k8s_api_proxy_requests_unique_users_via_ci_access`   |
| `events["k8s_api_proxy_requests_unique_users_via_ci_access"]["user_id"]`      | integer       | no       | The user ID for the event                                                 |
| `events["k8s_api_proxy_requests_unique_users_via_ci_access"]["project_id"]`   | integer       | no       | The project ID for the event                                              |
| `events["k8s_api_proxy_requests_unique_users_via_user_access"]`               | hash array    | no       | Array of events for `k8s_api_proxy_requests_unique_users_via_user_access` |
| `events["k8s_api_proxy_requests_unique_users_via_user_access"]["user_id"]`    | integer       | no       | The user ID for the event                                                 |
| `events["k8s_api_proxy_requests_unique_users_via_user_access"]["project_id"]` | integer       | no       | The project ID for the event                                              |
| `events["k8s_api_proxy_requests_unique_users_via_pat_access"]`                | hash array    | no       | Array of events for `k8s_api_proxy_requests_unique_users_via_pat_access`  |
| `events["k8s_api_proxy_requests_unique_users_via_pat_access"]["user_id"]`     | integer       | no       | The user ID for the event                                                 |
| `events["k8s_api_proxy_requests_unique_users_via_pat_access"]["project_id"]`  | integer       | no       | The project ID for the event                                              |

```plaintext
POST /internal/kubernetes/agent_events
```

Example Request:

```shell
curl --request POST \
  --url "http://localhost:3000/api/v4/internal/kubernetes/agent_events" \
  --header "Gitlab-Kas-Api-Request: <JWT token>" \
  --header "Content-Type: application/json" \
  --data '{
    "events": {
      "k8s_api_proxy_requests_unique_users_via_ci_access": [
        {
          "user_id": 1,
          "project_id": 1
        }
      ]
    }
  }'
```

### Create Starboard vulnerability

Called from the GitLab agent server (`kas`) to create a security vulnerability
from a Starboard vulnerability report. This request is idempotent. Multiple requests with the same data
create a single vulnerability. The response contains the UUID of the created vulnerability finding.

| Attribute       | Type   | Required | Description |
|:----------------|:-------|:---------|:------------|
| `vulnerability` | Hash   | yes      | Vulnerability data matching the security report schema [`vulnerability` field](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/src/security-report-format.json). |
| `scanner`       | Hash   | yes      | Scanner data matching the security report schema [`scanner` field](https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/blob/master/src/security-report-format.json). |

```plaintext
PUT internal/kubernetes/modules/starboard_vulnerability
```

Example Request:

```shell
curl --request PUT --header "Gitlab-Kas-Api-Request: <JWT token>" \
     --header "Authorization: Bearer <agent token>" --header "Content-Type: application/json" \
     --url "http://localhost:3000/api/v4/internal/kubernetes/modules/starboard_vulnerability" \
     --data '{
  "vulnerability": {
    "name": "CVE-123-4567 in libc",
    "severity": "high",
    "confidence": "unknown",
    "location": {
      "kubernetes_resource": {
        "namespace": "production",
        "kind": "deployment",
        "name": "nginx",
        "container": "nginx"
      }
    },
    "identifiers": [
      {
        "type": "cve",
        "name": "CVE-123-4567",
        "value": "CVE-123-4567"
      }
    ]
  },
  "scanner": {
    "id": "starboard_trivy",
    "name": "Trivy (via Starboard Operator)",
    "vendor": "GitLab"
  }
}'
```

Example response:

```json
{
  "uuid": "4773b2ee-5ba5-5e9f-b48c-5f7a17f0faac"
}
```

### Resolve Starboard vulnerabilities

Called from the GitLab agent server (`kas`) to resolve Starboard security vulnerabilities.
Accepts a list of finding UUIDs and marks all Starboard vulnerabilities not identified by
the list as resolved.

| Attribute | Type         | Required | Description                                                                                                                       |
|:----------|:-------------|:---------|:----------------------------------------------------------------------------------------------------------------------------------|
| `uuids`   | string array | yes      | UUIDs of detected vulnerabilities, as collected from [Create Starboard vulnerability](#create-starboard-vulnerability) responses. |

```plaintext
POST internal/kubernetes/modules/starboard_vulnerability/scan_result
```

Example Request:

```shell
curl --request POST --header "Gitlab-Kas-Api-Request: <JWT token>" \
     --header "Authorization: Bearer <agent token>" --header "Content-Type: application/json" \
     --url "http://localhost:3000/api/v4/internal/kubernetes/modules/starboard_vulnerability/scan_result" \
     --data '{ "uuids": ["102e8a0a-fe29-59bd-b46c-57c3e9bc6411", "5eb12985-0ed5-51f4-b545-fd8871dc2870"] }'
```

### Scan Execution Policies

Called from GitLab agent server (`kas`) to retrieve `scan_execution_policies`
configured for the project belonging to the agent token. GitLab `kas` uses
this to configure the agent to scan images in the Kubernetes cluster based on the policy.

```plaintext
GET /internal/kubernetes/modules/starboard_vulnerability/scan_execution_policies
```

Example Request:

```shell
curl --request GET --header "Gitlab-Kas-Api-Request: <JWT token>" \
     --header "Authorization: Bearer <agent token>" "http://localhost:3000/api/v4/internal/kubernetes/modules/starboard_vulnerability/scan_execution_policies"
```

Example response:

```json
{
  "policies": [
    {
      "name": "Policy",
      "description": "Policy description",
      "enabled": true,
      "yaml": "---\nname: Policy\ndescription: 'Policy description'\nenabled: true\nactions:\n- scan: container_scanning\nrules:\n- type: pipeline\n  branches:\n  - main\n",
      "updated_at": "2022-06-02T05:36:26+00:00"
    }
  ]
}
```

### Policy Configuration

Called from GitLab agent server (`kas`) to retrieve `policies_configuration`
configured for the project belonging to the agent token. GitLab `kas` uses
this to configure the agent to scan images in the Kubernetes cluster based on the configuration.

```plaintext
GET /internal/kubernetes/modules/starboard_vulnerability/policies_configuration
```

Example Request:

```shell
curl --request GET --header "Gitlab-Kas-Api-Request: <JWT token>" \
     --header "Authorization: Bearer <agent token>" "http://localhost:3000/api/v4/internal/kubernetes/modules/starboard_vulnerability/policies_configuration"
```

Example response:

```json
{
  "configurations": [
    {
      "cadence": "30 2 * * *",
      "namespaces": [
        "namespace-a",
        "namespace-b"
      ],
      "updated_at": "2022-06-02T05:36:26+00:00"
    }
  ]
}
```

## Storage limit exclusions

The namespace storage limit exclusion endpoints manage storage limit exclusions on top-level namespaces on GitLab.com.
These endpoints can only be consumed in the **Admin** area of GitLab.com.

### Retrieve storage limit exclusions

Use a GET request to retrieve all `Namespaces::Storage::LimitExclusion` records.

```plaintext
GET /namespaces/storage/limit_exclusions
```

Example request:

```shell
curl --request GET \
  --url "https://gitlab.com/v4/namespaces/storage/limit_exclusions" \
  --header 'PRIVATE-TOKEN: <admin access token>'
```

Example response:

```json
[
    {
      "id": 1,
      "namespace_id": 1234,
      "namespace_name": "A Namespace Name",
      "reason": "a reason to exclude the Namespace"
    },
    {
      "id": 2,
      "namespace_id": 4321,
      "namespace_name": "Another Namespace Name",
      "reason": "another reason to exclude the Namespace"
    },
]
```

### Create a storage limit exclusion

Use a POST request to create an `Namespaces::Storage::LimitExclusion`.

```plaintext
POST /namespaces/:id/storage/limit_exclusion
```

| Attribute   | Type    | Required | Description |
|:------------|:--------|:---------|:------------|
| `reason`    | string  | yes      | The reason to exclude the namespace. |

Example request:

```shell
curl --request POST \
  --url "https://gitlab.com/v4/namespaces/123/storage/limit_exclusion" \
  --header 'Content-Type: application/json' \
  --header 'PRIVATE-TOKEN: <admin access token>' \
  --data '{
    "reason": "a reason to exclude the Namespace"
  }'
```

Example response:

```json
{
  "id": 1,
  "namespace_id": 1234,
  "namespace_name": "A Namespace Name",
  "reason": "a reason to exclude the Namespace"
}
```

### Delete a storage limit exclusion

Use a DELETE request to delete a `Namespaces::Storage::LimitExclusion` for a namespace.

```plaintext
DELETE /namespaces/:id/storage/limit_exclusion
```

Example request:

```shell
curl --request DELETE \
  --url "https://gitlab.com/v4/namespaces/123/storage/limit_exclusion" \
  --header 'PRIVATE-TOKEN: <admin access token>'
```

Example response:

```plaintext
204
```

### Known consumers

- GitLab.com **Admin** area

## Group SCIM API

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com

The group SCIM API partially implements the [RFC7644 protocol](https://www.rfc-editor.org/rfc/rfc7644). This API provides the `/groups/:group_path/Users` and `/groups/:group_path/Users/:id` endpoints. The base URL is `<http|https>://<GitLab host>/api/scim/v2`. Because this API is for
**system** use for SCIM provider integration, it is subject to change without notice.

To use this API, enable [Group SSO](../../user/group/saml_sso/_index.md) for the group.
This API is only in use where [SCIM for Group SSO](../../user/group/saml_sso/scim_setup.md) is enabled. It's a prerequisite to the creation of SCIM identities.

This group SCIM API:

- Is for system use for SCIM provider integration.
- Implements the [RFC7644 protocol](https://www.rfc-editor.org/rfc/rfc7644).
- Gets a list of SCIM provisioned users for the group.
- Creates, deletes and updates SCIM provisioned users for the group.

The [instance SCIM API](#instance-scim-api) does the same for instances.

This group SCIM API is different to the [SCIM API](../../api/scim.md). The SCIM API:

- Is not an internal API.
- Does not implement the [RFC7644 protocol](https://www.rfc-editor.org/rfc/rfc7644).
- Gets, checks, updates, and deletes SCIM identities in groups.

NOTE:
This API does not require the `Gitlab-Shell-Api-Request` header.

### Get a list of SCIM provisioned users

This endpoint is used as part of the SCIM syncing mechanism. It returns a list of users depending on the filter used.

```plaintext
GET /api/scim/v2/groups/:group_path/Users
```

Parameters:

| Attribute | Type    | Required | Description                                                                                                                             |
|:----------|:--------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------|
| `filter`   | string  | no     | A [filter](#available-filters) expression. |
| `group_path` | string | yes    | Full path to the group. |
| `startIndex` | integer | no    | The 1-based index indicating where to start returning results from. A value of less than one is interpreted as 1. |
| `count` | integer | no    | Desired maximum number of query results. |

NOTE:
Pagination follows the [SCIM spec](https://www.rfc-editor.org/rfc/rfc7644#section-3.4.2.4) rather than GitLab pagination as used elsewhere. If records change between requests it is possible for a page to either be missing records that have moved to a different page or repeat records from a previous request.

Example request filtering on a specific identifier:

```shell
curl "https://gitlab.example.com/api/scim/v2/groups/test_group/Users?filter=id%20eq%20%220b1d561c-21ff-4092-beab-8154b17f82f2%22" \
     --header "Authorization: Bearer <your_scim_token>" \
     --header "Content-Type: application/scim+json"
```

Example response:

```json
{
  "schemas": [
    "urn:ietf:params:scim:api:messages:2.0:ListResponse"
  ],
  "totalResults": 1,
  "itemsPerPage": 20,
  "startIndex": 1,
  "Resources": [
    {
      "schemas": [
        "urn:ietf:params:scim:schemas:core:2.0:User"
      ],
      "id": "0b1d561c-21ff-4092-beab-8154b17f82f2",
      "active": true,
      "name.formatted": "Test User",
      "userName": "username",
      "meta": { "resourceType":"User" },
      "emails": [
        {
          "type": "work",
          "value": "name@example.com",
          "primary": true
        }
      ]
    }
  ]
}
```

### Get a single SCIM provisioned user

```plaintext
GET /api/scim/v2/groups/:group_path/Users/:id
```

Parameters:

| Attribute | Type    | Required | Description                                                                                                                             |
|:----------|:--------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------|
| `id`   | string  | yes     | External UID of the user. |
| `group_path` | string | yes    | Full path to the group. |

Example request:

```shell
curl "https://gitlab.example.com/api/scim/v2/groups/test_group/Users/f0b1d561c-21ff-4092-beab-8154b17f82f2" \
     --header "Authorization: Bearer <your_scim_token>" --header "Content-Type: application/scim+json"
```

Example response:

```json
{
  "schemas": [
    "urn:ietf:params:scim:schemas:core:2.0:User"
  ],
  "id": "0b1d561c-21ff-4092-beab-8154b17f82f2",
  "active": true,
  "name.formatted": "Test User",
  "userName": "username",
  "meta": { "resourceType":"User" },
  "emails": [
    {
      "type": "work",
      "value": "name@example.com",
      "primary": true
    }
  ]
}
```

### Create a SCIM provisioned user

```plaintext
POST /api/scim/v2/groups/:group_path/Users/
```

Parameters:

| Attribute      | Type    | Required | Description            |
|:---------------|:----------|:----|:--------------------------|
| `externalId` | string      | yes | External UID of the user. |
| `userName`   | string      | yes | Username of the user. |
| `emails`     | JSON string | yes | Work email. |
| `name`       | JSON string | yes | Name of the user. |
| `meta`       | string      | no  | Resource type (`User`). |

Example request:

```shell
curl --verbose --request POST "https://gitlab.example.com/api/scim/v2/groups/test_group/Users" \
     --data '{"externalId":"test_uid","active":null,"userName":"username","emails":[{"primary":true,"type":"work","value":"name@example.com"}],"name":{"formatted":"Test User","familyName":"User","givenName":"Test"},"schemas":["urn:ietf:params:scim:schemas:core:2.0:User"],"meta":{"resourceType":"User"}}' \
     --header "Authorization: Bearer <your_scim_token>" --header "Content-Type: application/scim+json"
```

Example response:

```json
{
  "schemas": [
    "urn:ietf:params:scim:schemas:core:2.0:User"
  ],
  "id": "0b1d561c-21ff-4092-beab-8154b17f82f2",
  "active": true,
  "name.formatted": "Test User",
  "userName": "username",
  "meta": { "resourceType":"User" },
  "emails": [
    {
      "type": "work",
      "value": "name@example.com",
      "primary": true
    }
  ]
}
```

Returns a `201` status code if successful.

NOTE:
After you create a group SCIM identity for a user, you can see that SCIM identity in the **Admin** area.

### Update a single SCIM provisioned user

Fields that can be updated are:

| SCIM/IdP field                   | GitLab field                                                                 |
|:---------------------------------|:-----------------------------------------------------------------------------|
| `id/externalId`                  | `extern_uid`                                                                 |
| `name.formatted`                 | `name` ([Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/363058))     |
| `emails\[type eq "work"\].value` | `email` ([Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/363058))    |
| `active`                         | Identity removal if `active` = `false`                                       |
| `userName`                       | `username` ([Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/363058)) |

```plaintext
PATCH /api/scim/v2/groups/:group_path/Users/:id
```

Parameters:

| Attribute | Type    | Required | Description                                                                                                                             |
|:----------|:--------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------|
| `id`   | string  | yes     | External UID of the user. |
| `group_path` | string | yes    | Full path to the group. |
| `Operations`   | JSON string  | yes     | An [operations](#available-operations) expression. |

Example request to update the user's `id`:

```shell
curl --verbose --request PATCH "https://gitlab.example.com/api/scim/v2/groups/test_group/Users/f0b1d561c-21ff-4092-beab-8154b17f82f2" \
     --data '{ "Operations": [{"op":"replace","path":"id","value":"1234abcd"}] }' \
     --header "Authorization: Bearer <your_scim_token>" --header "Content-Type: application/scim+json"
```

Returns an empty response with a `204` status code if successful.

Example request to set the user's `active` state:

```shell
curl --verbose --request PATCH "https://gitlab.example.com/api/scim/v2/groups/test_group/Users/f0b1d561c-21ff-4092-beab-8154b17f82f2" \
     --data '{ "Operations": [{"op":"replace","path":"active","value":"true"}] }' \
     --header "Authorization: Bearer <your_scim_token>" --header "Content-Type: application/scim+json"
```

Returns an empty response with a `204` status code if successful.

### Remove a single SCIM provisioned user

Removes the user's SSO identity and group membership.

```plaintext
DELETE /api/scim/v2/groups/:group_path/Users/:id
```

Parameters:

| Attribute    | Type   | Required | Description               |
| ------------ | ------ | -------- | ------------------------- |
| `id`         | string | yes      | External UID of the user. |
| `group_path` | string | yes      | Full path to the group.   |

Example request:

```shell
curl --verbose --request DELETE "https://gitlab.example.com/api/scim/v2/groups/test_group/Users/f0b1d561c-21ff-4092-beab-8154b17f82f2" \
     --header "Authorization: Bearer <your_scim_token>" --header "Content-Type: application/scim+json"
```

Returns an empty response with a `204` status code if successful.

## Instance SCIM API

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/378599) in GitLab 15.8.

The instance SCIM API partially implements the [RFC7644 protocol](https://www.rfc-editor.org/rfc/rfc7644). This API provides the `/application/Users` and `/application/Users/:id` endpoints. The base URL is `<http|https>://<GitLab host>/api/scim/v2`. Because this API is for
**system** use for SCIM provider integration, it is subject to change without notice.

To use this API, enable [SAML SSO](../../integration/saml.md) for the instance.

This instance SCIM API:

- Is for system use for SCIM provider integration.
- Implements the [RFC7644 protocol](https://www.rfc-editor.org/rfc/rfc7644).
- Gets a list of SCIM provisioned users for the group.
- Creates, deletes and updates SCIM provisioned users for the group.

The [group SCIM API](#group-scim-api) does the same for groups.

This instance SCIM API is different to the [SCIM API](../../api/scim.md). The SCIM API:

- Is not an internal API.
- Does not implement the [RFC7644 protocol](https://www.rfc-editor.org/rfc/rfc7644).
- Gets, checks, updates, and deletes SCIM identities within groups.

NOTE:
This API does not require the `Gitlab-Shell-Api-Request` header.

### Get a list of SCIM provisioned users

This endpoint is used as part of the SCIM syncing mechanism. It returns a list of users depending on the filter used.

```plaintext
GET /api/scim/v2/application/Users
```

Parameters:

| Attribute | Type    | Required | Description                                                                                                                             |
|:----------|:--------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------|
| `filter`   | string  | no     | A [filter](#available-filters) expression. |
| `startIndex` | integer | no    | The 1-based index indicating where to start returning results from. A value of less than one is interpreted as 1. |
| `count` | integer | no    | Desired maximum number of query results. |

NOTE:
Pagination follows the [SCIM spec](https://www.rfc-editor.org/rfc/rfc7644#section-3.4.2.4) rather than GitLab pagination as used elsewhere. If records change between requests it is possible for a page to either be missing records that have moved to a different page or repeat records from a previous request.

Example request:

```shell
curl "https://gitlab.example.com/api/scim/v2/application/Users?filter=id%20eq%20%220b1d561c-21ff-4092-beab-8154b17f82f2%22" \
     --header "Authorization: Bearer <your_scim_token>" \
     --header "Content-Type: application/scim+json"
```

Example response:

```json
{
  "schemas": [
    "urn:ietf:params:scim:api:messages:2.0:ListResponse"
  ],
  "totalResults": 1,
  "itemsPerPage": 20,
  "startIndex": 1,
  "Resources": [
    {
      "schemas": [
        "urn:ietf:params:scim:schemas:core:2.0:User"
      ],
      "id": "0b1d561c-21ff-4092-beab-8154b17f82f2",
      "active": true,
      "name.formatted": "Test User",
      "userName": "username",
      "meta": { "resourceType":"User" },
      "emails": [
        {
          "type": "work",
          "value": "name@example.com",
          "primary": true
        }
      ]
    }
  ]
}
```

### Get a single SCIM provisioned user

```plaintext
GET /api/scim/v2/application/Users/:id
```

Parameters:

| Attribute | Type    | Required | Description                                                                                                                             |
|:----------|:--------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------|
| `id`   | string  | yes     | External UID of the user. |

Example request:

```shell
curl "https://gitlab.example.com/api/scim/v2/application/Users/f0b1d561c-21ff-4092-beab-8154b17f82f2" \
     --header "Authorization: Bearer <your_scim_token>" --header "Content-Type: application/scim+json"
```

Example response:

```json
{
  "schemas": [
    "urn:ietf:params:scim:schemas:core:2.0:User"
  ],
  "id": "0b1d561c-21ff-4092-beab-8154b17f82f2",
  "active": true,
  "name.formatted": "Test User",
  "userName": "username",
  "meta": { "resourceType":"User" },
  "emails": [
    {
      "type": "work",
      "value": "name@example.com",
      "primary": true
    }
  ]
}
```

### Create a SCIM provisioned user

```plaintext
POST /api/scim/v2/application/Users
```

Parameters:

| Attribute      | Type    | Required | Description            |
|:---------------|:----------|:----|:--------------------------|
| `externalId` | string      | yes | External UID of the user. |
| `userName`   | string      | yes | Username of the user. |
| `emails`     | JSON string | yes | Work email. |
| `name`       | JSON string | yes | Name of the user. |
| `meta`       | string      | no  | Resource type (`User`). |

Example request:

```shell
curl --verbose --request POST "https://gitlab.example.com/api/scim/v2/application/Users" \
     --data '{"externalId":"test_uid","active":null,"userName":"username","emails":[{"primary":true,"type":"work","value":"name@example.com"}],"name":{"formatted":"Test User","familyName":"User","givenName":"Test"},"schemas":["urn:ietf:params:scim:schemas:core:2.0:User"],"meta":{"resourceType":"User"}}' \
     --header "Authorization: Bearer <your_scim_token>" --header "Content-Type: application/scim+json"
```

Example response:

```json
{
  "schemas": [
    "urn:ietf:params:scim:schemas:core:2.0:User"
  ],
  "id": "0b1d561c-21ff-4092-beab-8154b17f82f2",
  "active": true,
  "name.formatted": "Test User",
  "userName": "username",
  "meta": { "resourceType":"User" },
  "emails": [
    {
      "type": "work",
      "value": "name@example.com",
      "primary": true
    }
  ]
}
```

Returns a `201` status code if successful.

### Update a single SCIM provisioned user

Fields that can be updated are:

| SCIM/IdP field                   | GitLab field                                                                 |
|:---------------------------------|:-----------------------------------------------------------------------------|
| `id/externalId`                  | `extern_uid`                                                                 |
| `active`                         | If `false`, the user is blocked, but the SCIM identity remains linked.       |

```plaintext
PATCH /api/scim/v2/application/Users/:id
```

Parameters:

| Attribute | Type    | Required | Description                                                                                                                             |
|:----------|:--------|:---------|:----------------------------------------------------------------------------------------------------------------------------------------|
| `id`   | string  | yes     | External UID of the user. |
| `Operations`   | JSON string  | yes     | An [operations](#available-operations) expression. |

Example request:

```shell
curl --verbose --request PATCH "https://gitlab.example.com/api/scim/v2/application/Users/f0b1d561c-21ff-4092-beab-8154b17f82f2" \
     --data '{ "Operations": [{"op":"Update","path":"active","value":"false"}] }' \
     --header "Authorization: Bearer <your_scim_token>" --header "Content-Type: application/scim+json"
```

Returns an empty response with a `204` status code if successful.

### Block a single SCIM provisioned user

The user is placed in a `blocked` state and signed out. This means
the user cannot sign in or push or pull code.

```plaintext
DELETE /api/scim/v2/application/Users/:id
```

Parameters:

| Attribute    | Type   | Required | Description               |
| ------------ | ------ | -------- | ------------------------- |
| `id`         | string | yes      | External UID of the user. |

Example request:

```shell
curl --verbose --request DELETE "https://gitlab.example.com/api/scim/v2/application/Users/f0b1d561c-21ff-4092-beab-8154b17f82f2" \
     --header "Authorization: Bearer <your_scim_token>" --header "Content-Type: application/scim+json"
```

Returns an empty response with a `204` status code if successful.

### Available filters

They match an expression as specified in [the RFC7644 filtering section](https://www.rfc-editor.org/rfc/rfc7644#section-3.4.2.2).

| Filter | Description |
| ----- | ----------- |
| `eq` | The attribute matches exactly the specified value. |

Example:

```plaintext
id eq a-b-c-d
```

### Available operations

They perform an operation as specified in [the RFC7644 update section](https://www.rfc-editor.org/rfc/rfc7644#section-3.5.2).

| Operator | Description |
| ----- | ----------- |
| `Replace` | The attribute's value is updated. |
| `Add` | The attribute has a new value. |

Example:

```json
{ "op": "Add", "path": "name.formatted", "value": "New Name" }
```
