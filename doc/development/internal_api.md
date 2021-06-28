---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Internal API **(FREE)**

The internal API is used by different GitLab components, it can not be
used by other consumers. This documentation is intended for people
working on the GitLab codebase.

This documentation does not yet include the internal API used by
GitLab Pages.

## Adding new endpoints

API endpoints should be externally accessible by default, with proper authentication and authorization.
Before adding a new internal endpoint, consider if the API would potentially be
useful to the wider GitLab community and can be made externally accessible.

One reason we might favor internal API endpoints sometimes is when using such an endpoint requires
internal data that external actors can not have. For example, in the internal Pages API we might use
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

To authenticate using that token, clients read the contents of that
file, and include the token Base64 encoded in a `secret_token` parameter
or in the `Gitlab-Shared-Secret` header.

NOTE:
The internal API used by GitLab Pages, and GitLab Kubernetes Agent Server (`kas`) uses JSON Web Token (JWT)
authentication, which is different from GitLab Shell.

## Git Authentication

This is called by [Gitaly](https://gitlab.com/gitlab-org/gitaly) and
[GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell) to check access to a
repository.

- **When called from GitLab Shell**: No changes are passed, and the internal
  API replies with the information needed to pass the request on to Gitaly.
- **When called from Gitaly in a `pre-receive` hook**: The changes are passed
  and validated to determine if the push is allowed.

Calls are limited to 50 seconds each.

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
curl --request POST --header "Gitlab-Shared-Secret: <Base64 encoded token>" \
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
curl --request POST --header "Gitlab-Shared-Secret: <Base64 encoded token>" \
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
check. Which is called by OpenSSH for [fast SSH key
lookup](../administration/operations/fast_ssh_key_lookup.md).

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `key`     | string | yes      | SSH key as passed by OpenSSH to GitLab Shell |

```plaintext
GET /internal/authorized_keys
```

Example request:

```shell
curl --request GET --header "Gitlab-Shared-Secret: <Base64 encoded secret>" "http://localhost:3001/api/v4/internal/authorized_keys?key=<key as passed by OpenSSH>"
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
curl --request GET --header "Gitlab-Shared-Secret: <Base64 encoded secret>" "http://localhost:3001/api/v4/internal/discover?key_id=7"
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

This gets some generic information about the instance. This is used
by Geo nodes to get information about each other.

```plaintext
GET /internal/check
```

Example request:

```shell
curl --request GET --header "Gitlab-Shared-Secret: <Base64 encoded secret>" "http://localhost:3001/api/v4/internal/check"
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
| `user_id` | integer | no | **Deprecated** User_id for which to generate new recovery codes |

```plaintext
GET /internal/two_factor_recovery_codes
```

Example request:

```shell
curl --request POST --header "Gitlab-Shared-Secret: <Base64 encoded secret>" \
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

This is called from GitLab Shell and allows users to generate a new
personal access token.

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `name` | string | yes | The name of the new token |
| `scopes` | string array | yes | The authorization scopes for the new token, these must be valid token scopes |
| `expires_at` | string | no | The expiry date for the new token |
| `key_id`  | integer | no | The ID of the SSH key used as found in the authorized-keys file or through the `/authorized_keys` check |
| `user_id` | integer | no | User\_id for which to generate the new token |

```plaintext
POST /internal/personal_access_token
```

Example request:

```shell
curl --request POST --header "Gitlab-Shared-Secret: <Base64 encoded secret>" \
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
curl --request POST --header "Gitlab-Shared-Secret: <Base64 encoded secret>" \
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
curl --request POST --header "Gitlab-Shared-Secret: <Base64 encoded secret>" \
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

## Kubernetes agent endpoints

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/41045) in GitLab 13.4.
> - This feature is not deployed on GitLab.com
> - It's not recommended for production use.

The following endpoints are used by the GitLab Kubernetes Agent Server (`kas`)
for various purposes.

These endpoints are all authenticated using JWT. The JWT secret is stored in a file
specified in `config/gitlab.yml`. By default, the location is in the root of the
GitLab Rails app in a file called `.gitlab_kas_secret`.

WARNING:
The Kubernetes agent is under development and is not recommended for production use.

### Kubernetes agent information

Called from GitLab Kubernetes Agent Server (`kas`) to retrieve agent
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

### Kubernetes agent project information

Called from GitLab Kubernetes Agent Server (`kas`) to retrieve project
information for the given agent token. This returns the Gitaly
connection for the requested project. GitLab `kas` uses this to configure
the agent to fetch Kubernetes resources from the project repository to
sync.

Only public projects are supported. For private projects, the ability for the
agent to be authorized is [not yet implemented](https://gitlab.com/gitlab-org/gitlab/-/issues/220912).

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `id` | integer/string | yes | The ID or [URL-encoded path of the project](../api/index.md#namespaced-path-encoding) |

```plaintext
GET /internal/kubernetes/project_info
```

Example Request:

```shell
curl --request GET --header "Gitlab-Kas-Api-Request: <JWT token>" \
     --header "Authorization: Bearer <agent token>" "http://localhost:3000/api/v4/internal/kubernetes/project_info?id=7"
```

### Kubernetes agent usage metrics

Called from GitLab Kubernetes Agent Server (`kas`) to increase the usage
metric counters.

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `gitops_sync_count` | integer| no | The number to increase the `gitops_sync_count` counter by |
| `k8s_api_proxy_request_count` | integer| no | The number to increase the `k8s_api_proxy_request_count` counter by |

```plaintext
POST /internal/kubernetes/usage_metrics
```

Example Request:

```shell
curl --request POST --header "Gitlab-Kas-Api-Request: <JWT token>" --header "Content-Type: application/json" \
     --data '{"gitops_sync_count":1}' "http://localhost:3000/api/v4/internal/kubernetes/usage_metrics"
```

### Kubernetes agent alert metrics

Called from GitLab Kubernetes Agent Server (KAS) to save alerts derived from Cilium on Kubernetes
Cluster.

| Attribute | Type   | Required | Description |
|:----------|:-------|:---------|:------------|
| `alert` | Hash | yes | Alerts detail. Same format as [3rd party alert](../operations/incident_management/integrations.md#customize-the-alert-payload-outside-of-gitlab). |

```plaintext
POST internal/kubernetes/modules/cilium_alert
```

Example Request:

```shell
curl --request POST --header "Gitlab-Kas-Api-Request: <JWT token>" \
     --header "Authorization: Bearer <agent token>" --header "Content-Type: application/json" \
     --data '"{\"alert\":{\"title\":\"minimal\",\"message\":\"network problem\",\"evalMatches\":[{\"value\":1,\"metric\":\"Count\",\"tags\":{}}]}}"' \
     "http://localhost:3000/api/v4/internal/kubernetes/modules/cilium_alert"
```

## Subscriptions

The subscriptions endpoint is used by [CustomersDot](https://gitlab.com/gitlab-org/customers-gitlab-com) (`customers.gitlab.com`)
in order to apply subscriptions including trials, and add-on purchases, for personal namespaces or top-level groups within GitLab.com.

### Creating a subscription

Use a POST to create a subscription.

```plaintext
POST /namespaces/:id/gitlab_subscription
```

| Attribute   | Type    | Required | Description |
|:------------|:--------|:---------|:------------|
| `start_date` | date   | yes      | Start date of subscription |
| `end_date`  | date    | no       | End date of subscription |
| `plan_code` | string  | no       | Subscription tier code |
| `seats`     | integer | no       | Number of seats in subscription |
| `max_seats_used` | integer | no  | Highest number of active users in the last month |
| `auto_renew` | boolean | no      | Whether subscription auto-renews on end date |
| `trial`     | boolean | no       | Whether subscription is a trial |
| `trial_starts_on` | date | no    | Start date of trial |
| `trial_ends_on` | date | no      | End date of trial |

Example request:

```shell
curl --request POST --header "TOKEN: <admin_access_token>" "https://gitlab.com/api/v4/namespaces/1234/gitlab_subscription?start_date="2020-07-15"&plan="silver"&seats=10"
```

Example response:

```json
{
  "plan": {
    "code":"silver",
    "name":"Silver",
    "trial":false,
    "auto_renew":null,
    "upgradable":false
  },
  "usage": {
    "seats_in_subscription":10,
    "seats_in_use":1,
    "max_seats_used":0,
    "seats_owed":0
  },
  "billing": {
    "subscription_start_date":"2020-07-15",
    "subscription_end_date":null,
    "trial_ends_on":null
  }
}
```

### Updating a subscription

Use a PUT command to update an existing subscription.

```plaintext
PUT /namespaces/:id/gitlab_subscription
```

| Attribute   | Type    | Required | Description |
|:------------|:--------|:---------|:------------|
| `start_date` | date   | no       | Start date of subscription |
| `end_date`  | date    | no       | End date of subscription |
| `plan_code` | string  | no       | Subscription tier code |
| `seats`     | integer | no       | Number of seats in subscription |
| `max_seats_used` | integer | no  | Highest number of active users in the last month |
| `auto_renew` | boolean | no      | Whether subscription auto-renews on end date |
| `trial`     | boolean | no       | Whether subscription is a trial |
| `trial_starts_on` | date | no    | Start date of trial. Required if trial is true. |
| `trial_ends_on` | date | no      | End date of trial |

Example request:

```shell
curl --request PUT --header "TOKEN: <admin_access_token>" "https://gitlab.com/api/v4/namespaces/1234/gitlab_subscription?max_seats_used=0"
```

Example response:

```json
{
  "plan": {
    "code":"silver",
    "name":"Silver",
    "trial":false,
    "auto_renew":null,
    "upgradable":false
  },
  "usage": {
    "seats_in_subscription":80,
    "seats_in_use":82,
    "max_seats_used":0,
    "seats_owed":2
  },
  "billing": {
    "subscription_start_date":"2020-07-15",
    "subscription_end_date":"2021-07-15",
    "trial_ends_on":null
  }
}
```

### Retrieving a subscription

Use a GET command to view an existing subscription.

```plaintext
GET /namespaces/:id/gitlab_subscription
```

Example request:

```shell
curl --header "TOKEN: <admin_access_token>" "https://gitlab.com/api/v4/namespaces/1234/gitlab_subscription"
```

Example response:

```json
{
  "plan": {
    "code":"silver",
    "name":"Silver",
    "trial":false,
    "auto_renew":null,
    "upgradable":false
  },
  "usage": {
    "seats_in_subscription":80,
    "seats_in_use":82,
    "max_seats_used":82,
    "seats_owed":2
  },
  "billing": {
    "subscription_start_date":"2020-07-15",
    "subscription_end_date":"2021-07-15",
    "trial_ends_on":null
  }
}
```

### Known consumers

- CustomersDot

## CI minute provisioning

The CI Minute endpoints are used by [CustomersDot](https://gitlab.com/gitlab-org/customers-gitlab-com) (`customers.gitlab.com`)
to apply additional packs of CI minutes, for personal namespaces or top-level groups within GitLab.com.

### Creating an additional pack

Use a POST to create an additional pack.

```plaintext
POST /namespaces/:id/minutes
```

| Attribute   | Type    | Required | Description |
|:------------|:--------|:---------|:------------|
| `expires_at` | date   | yes      | Expiry date of the purchased pack|
| `number_of_minutes`  | integer    | yes       | Number of additional minutes |
| `purchase_xid` | string  | yes       | The unique ID of the purchase |

Example request:

```shell
curl --request POST \
  --url http://localhost:3000/api/v4/namespaces/123/minutes \
  --header 'Content-Type: application/json' \
  --header 'PRIVATE-TOKEN: <admin access token>' \
  --data '{
    "number_of_minutes": 10000,
    "expires_at": "2022-01-01",
    "purchase_xid": "46952fe69bebc1a4de10b2b4ff439d0c" }'
```

Example response:

```json
{
  "namespace_id": 123,
  "expires_at": "2022-01-01",
  "number_of_minutes": 10000,
  "purchase_xid": "46952fe69bebc1a4de10b2b4ff439d0c"
}
```

### Moving additional packs

Use a PATCH to move additional packs from one namespace to another.

```plaintext
PATCH /namespaces/:id/minutes/move/:target_id
```

| Attribute   | Type    | Required | Description |
|:------------|:--------|:---------|:------------|
| `id` | string | yes | The ID of the namespace to transfer packs from |
| `target_id`  | string | yes | The ID of the target namespace to transfer the packs to |

Example request:

```shell
curl --request PATCH \
  --url http://localhost:3000/api/v4/namespaces/123/minutes/move/321 \
  --header 'PRIVATE-TOKEN: <admin access token>'
```

Example response:

```json
{
  "message": "202 Accepted"
}
```

### Known consumers

- CustomersDot

## Upcoming reconciliations

The `upcoming_reconciliations` endpoint is used by [CustomersDot](https://gitlab.com/gitlab-org/customers-gitlab-com) (`customers.gitlab.com`)
to update upcoming reconciliations for namespaces.

### Updating `upcoming_reconciliations`

Use a PUT command to update `upcoming_reconciliations`.

```plaintext
PUT /internal/upcoming_reconciliations
```

| Attribute          | Type       | Required | Description |
|:-------------------|:-----------|:---------|:------------|
| `upcoming_reconciliations` | array | yes | Array of upcoming reconciliations |

Each array element contains:

| Attribute          | Type       | Required | Description |
|:-------------------|:-----------|:---------|:------------|
| `namespace_id`          | integer | yes | ID of the namespace to be reconciled |
| `next_reconciliation_date` | date | yes | Date when next reconciliation will happen |
| `display_alert_from`       | date | yes | Start date to display alert of upcoming reconciliation |

Example request:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <admin_access_token>" --header "Content-Type: application/json" \
     --data '{"upcoming_reconciliations": [{"namespace_id": 127, "next_reconciliation_date": "13 Jun 2021", "display_alert_from": "06 Jun 2021"}, {"namespace_id": 129, "next_reconciliation_date": "12 Jun 2021", "display_alert_from": "05 Jun 2021"}]}' \
     "https://gitlab.com/api/v4/internal/upcoming_reconciliations"
```

Example response:

```plaintext
200
```

### Known consumers

- CustomersDot
