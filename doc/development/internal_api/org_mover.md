---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Org Mover internal API
---

The Org Mover control plane uses this internal API to drive an organization's maintenance lifecycle
during a move between GitLab.com cells.
No other consumer can use the API.
This documentation is intended for people working on the GitLab codebase.

The Org Mover API uses internal endpoints because requests are authenticated with a service-level
JWT rather than a user token.

## Authentication

These endpoints are authenticated with an ES256 JWT signed by the Org Mover control plane.
Only the control plane holds the private key.
Each cell trusts the public keys listed in the `org_mover.public_key_files` setting in `gitlab.yml`.
To rotate a key without downtime, list both the old and the new key.
Remove the old key after the control plane signs with the new one.
When the setting is empty or cells are disabled, the endpoints reject every token.

Clients pass the token in the `Gitlab-Org-Mover-Api-Request` header. The token must meet these requirements:

| Field        | Requirement |
|:-------------|:------------|
| `alg` header | `ES256`. |
| `kid` header | The RFC 7638 thumbprint of the signing key. |
| `iss`        | `gitlab-org-mover`. |
| `aud`        | The target cell, as a single string: `gitlab-org-mover-api:cell-<cell_id>`. Tokens for another cell or a list of cells are rejected. |
| `iat`        | The time the token was issued. Tokens older than five minutes, or more than 30 seconds in the future, are rejected. |
| Size         | At most 2 KB, in JSON Web Signature (JWS) compact serialization. |

A missing or invalid token returns `401`. If a public key file cannot be read, the endpoint returns `500`.

Each endpoint is also gated per organization by the `org_mover_maintenance_api` feature flag, checked
with the target organization as the actor. When the flag is disabled for the organization, or the
organization does not exist, the endpoint returns `404`. The flag is disabled by default and is enabled
per organization only for the duration of a move.
Operators must never enable it globally.
Operators must disable it after the move completes, because it does not expire on its own.

## Maintenance lifecycle

An organization moves through the following states during a maintenance transition:

- `active`: the organization is operating as usual.
- `maintenance_initialization`: the transition has begun and the organization is draining outstanding work.
- `maintenance`: the organization is fully drained and in the steady maintenance state.

The transitions are idempotent. When an organization is already in the target state, the endpoint
returns `204` without running the transition again.

From `maintenance_initialization` onward, GitLab blocks requests for the organization, including
web, REST API, GraphQL, Git, Git LFS, and container registry requests. When the maintenance reason
is `migration` or `incident`, blocked web, API, GraphQL, and Git LFS requests return `503` with a
`Retry-After` header. For other reasons, they return `403`. Git requests are rejected for every reason.

## Internal endpoints

Every endpoint requires an integer `organization_id`. A missing or non-integer value returns `400`.

### Report the current state

Use a GET command to get an organization's current lifecycle state.

The response contains the organization's full state, so in addition to the maintenance lifecycle
states it can be `unconfirmed`, `confirmed`, `soft_deleted`, or `deletion_in_progress`.

```plaintext
GET /internal/org_mover/maintenance_state
```

| Attribute         | Type    | Required | Description |
|:------------------|:--------|:---------|:------------|
| `organization_id` | integer | yes      | ID of the organization. |

Example request:

```shell
curl --header "Gitlab-Org-Mover-Api-Request: <json-web-token>" \
  "https://gitlab.example.com/api/v4/internal/org_mover/maintenance_state?organization_id=2"
```

Example response:

```json
{
  "state": "active"
}
```

### Report maintenance readiness

Use a GET command to check whether an organization is drained and safe to enter the maintenance state.

```plaintext
GET /internal/org_mover/maintenance_readiness
```

| Attribute         | Type    | Required | Description |
|:------------------|:--------|:---------|:------------|
| `organization_id` | integer | yes      | ID of the organization. |

Example request:

```shell
curl --header "Gitlab-Org-Mover-Api-Request: <json-web-token>" \
  "https://gitlab.example.com/api/v4/internal/org_mover/maintenance_readiness?organization_id=2"
```

Example response:

```json
{
  "ready": false,
  "blocking_reason": "active CI jobs"
}
```

When the organization is ready, `ready` is `true` and `blocking_reason` is `null`. Otherwise,
`blocking_reason` names the first check that failed: `active batched background migrations`,
`pending migrations`, or `active CI jobs`.
The readiness checks are not complete yet, so more reasons might be added. For progress, see
[work item 602822](https://gitlab.com/gitlab-org/gitlab/-/work_items/602822).

### Start maintenance

Use a POST command to begin the maintenance transition (`active` to `maintenance_initialization`).

```plaintext
POST /internal/org_mover/start_maintenance
```

| Attribute            | Type    | Required | Description |
|:---------------------|:--------|:---------|:------------|
| `organization_id`    | integer | yes      | ID of the organization. |
| `maintenance_reason` | string  | yes      | Reason for entering maintenance. One of `migration`, `isolation`, `incident`, `billing`, or `legal`. |

Example request:

```shell
curl --request POST \
  --header "Gitlab-Org-Mover-Api-Request: <json-web-token>" \
  --header "Content-Type: application/json" \
  --data '{"organization_id": 2, "maintenance_reason": "migration"}' \
  "https://gitlab.example.com/api/v4/internal/org_mover/start_maintenance"
```

A successful request returns `204`. An invalid `maintenance_reason` returns `400`, and an organization
that is neither `active` nor already in `maintenance_initialization` returns `422`. The default
organization can never enter maintenance and always returns `422`.

### Confirm maintenance

Use a POST command to complete the maintenance transition (`maintenance_initialization` to `maintenance`).

```plaintext
POST /internal/org_mover/confirm_maintenance
```

| Attribute         | Type    | Required | Description |
|:------------------|:--------|:---------|:------------|
| `organization_id` | integer | yes      | ID of the organization. |

Example request:

```shell
curl --request POST \
  --header "Gitlab-Org-Mover-Api-Request: <json-web-token>" \
  --header "Content-Type: application/json" \
  --data '{"organization_id": 2}' \
  "https://gitlab.example.com/api/v4/internal/org_mover/confirm_maintenance"
```

A successful request returns `204`. While the organization is not yet drained, the request returns `409`
with the blocking reason in the message. The client can poll `maintenance_readiness` and retry after a
`409`. An organization that is not in `maintenance_initialization` returns `422`, which is permanent.

### Cancel maintenance

Use a POST command to abort maintenance initialization before the organization reaches the maintenance
state, returning it to `active` (`maintenance_initialization` to `active`).

```plaintext
POST /internal/org_mover/cancel_maintenance
```

| Attribute         | Type    | Required | Description |
|:------------------|:--------|:---------|:------------|
| `organization_id` | integer | yes      | ID of the organization. |

Example request:

```shell
curl --request POST \
  --header "Gitlab-Org-Mover-Api-Request: <json-web-token>" \
  --header "Content-Type: application/json" \
  --data '{"organization_id": 2}' \
  "https://gitlab.example.com/api/v4/internal/org_mover/cancel_maintenance"
```

A successful request returns `204`. An organization that is neither `active` nor in
`maintenance_initialization` returns `422`.

### Exit maintenance

Use a POST command to return an organization from the maintenance state to `active`
(`maintenance` to `active`).

```plaintext
POST /internal/org_mover/exit_maintenance
```

| Attribute         | Type    | Required | Description |
|:------------------|:--------|:---------|:------------|
| `organization_id` | integer | yes      | ID of the organization. |

Example request:

```shell
curl --request POST \
  --header "Gitlab-Org-Mover-Api-Request: <json-web-token>" \
  --header "Content-Type: application/json" \
  --data '{"organization_id": 2}' \
  "https://gitlab.example.com/api/v4/internal/org_mover/exit_maintenance"
```

A successful request returns `204`. An organization that is neither `active` nor in `maintenance`
returns `422`.
