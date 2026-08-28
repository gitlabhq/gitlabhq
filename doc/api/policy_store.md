---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: REST API to manage security policies stored in the policy store for an organization.
title: Policy store API
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/606971) in GitLab 19.3 [with a feature flag](../administration/feature_flags/_index.md) named `security_policies_v2`. Disabled by default.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/work_items/604367) to persist policies to the database instead of per-process memory in GitLab 19.4.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/work_items/616505) to add the `policy_rego` response attribute in GitLab 19.4.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/work_items/612905) to reject rules that compile to a Rego module larger than 65536 bytes in GitLab 19.4.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/work_items/623359) to add the `scope_dimensions` response attribute in GitLab 19.4.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/work_items/612905) to limit `rules` and `actions` to 5 entries each, and each entry to 4096 bytes, in GitLab 19.4.

{{< /history >}}

> [!warning]
> This feature is an [experiment](../policy/development_stages_support.md).
> The endpoints can change without notice.

Use this API to author [security policies](../user/application_security/policies/_index.md)
in the policy store.
A policy belongs to an organization, responds to a single trigger, and carries the rules and
actions that make up its behavior.

These endpoints are available only when all of the following are true:

- The `security_policies_v2` feature flag is enabled.
- An administrator has enabled the policy store experiment for the instance in
  **Admin** > **Settings** > **Security and compliance**.
- The organization has opted in through its `policy_store_experiment_enabled`
  organization setting, set through the `policyStoreExperimentEnabled`
  argument of the `organizationUpdate` GraphQL mutation.

When any of these is not true, the endpoints return `404 Not Found`.
When the instance is not licensed for security orchestration policies, they return
`403 Forbidden`.

## Catalogs

The catalog endpoints describe what a policy can be built from.
They return the same static content for every caller, so they take no authentication and no
permission.

### List all triggers

List all triggers a policy can respond to.

```plaintext
GET /security/policy_store/triggers
```

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute | Type   | Description |
| --------- | ------ | ----------- |
| `[].id`   | string | ID of the trigger, used as `trigger_type` when authoring a policy. |
| `[].name` | string | Display name of the trigger. |

Example request:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/security/policy_store/triggers"
```

Example response:

```json
[
  { "id": "deployment_requested", "name": "Deployment" }
]
```

### List all actions

List all actions a policy can take.

```plaintext
GET /security/policy_store/actions
```

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute | Type   | Description |
| --------- | ------ | ----------- |
| `[].id`   | string | ID of the action. |
| `[].name` | string | Display name of the action. |

Example request:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/security/policy_store/actions"
```

Example response:

```json
[
  { "id": "block", "name": "Block" },
  { "id": "require_approval", "name": "Require approval" }
]
```

### List all rule kinds

List all rule kinds a policy can be built from.

```plaintext
GET /security/policy_store/rules
```

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute | Type   | Description |
| --------- | ------ | ----------- |
| `[].id`   | string | ID of the rule kind. |
| `[].name` | string | Display name of the rule kind. |

Example request:

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/security/policy_store/rules"
```

Example response:

```json
[
  { "id": "custom", "name": "Custom" },
  { "id": "calendar", "name": "Calendar" },
  { "id": "environment", "name": "Environment" }
]
```

## Policies

Every call to a policy endpoint must be [authenticated](rest/authentication.md), and the
caller must be an owner of the organization or an instance administrator.
A caller who cannot administer the organization receives `403 Forbidden`, and one who cannot
see the organization at all receives `404 Not Found`.

A policy that belongs to another organization is indistinguishable from one that does not
exist.
An ID cannot be used to read or change a policy across organizations.

### Policy scope

A policy applies everywhere unless it carries a scope.
A scope is authored one of two ways, and a request may use one or the other but not both:

- `policy_scope`: structured data that GitLab compiles into `scope_rego`.
- `scope_rego`: a [Rego](https://www.openpolicyagent.org/docs/policy-language) program
  supplied directly, stored as authored.

A request that supplies both returns `400 Bad Request`.
An empty `scope_rego` does not count as the second form, so either operation accepts it
alongside `policy_scope`.
On [Create a policy](#create-a-policy), an empty value has the same effect as omitting it.
On [Update a policy](#update-a-policy), it retires an authored program and compiles a new one
from `policy_scope`.

`scope_rego` is always present in a response, because a policy with no scope compiles to a
program that applies to every project.
`policy_scope` is `null` when the Rego was authored directly, because a hand-written program
has no structured form.

`scope_dimensions` lists the dotted context paths, such as `compliance_frameworks` or
`project.id`, that `scope_rego` reads to decide whether the policy applies. GitLab derives
this list, so it ignores any value you send for the attribute. This value is always an
array, empty when the policy is unscoped, unless `scope_rego` was authored directly instead
of compiled from `policy_scope`. In that case, GitLab cannot derive the paths from a
hand-written program, so `scope_dimensions` is `null`, meaning the paths are not known
rather than empty.

#### Policy scope structure

`policy_scope` holds one or more criteria, and `match_mode` controls how they combine.
A criterion names IDs, either as integers or as objects with an `id` key.
GitLab deduplicates and sorts the IDs, so authoring order does not change the compiled program.

| Attribute | Type | Description |
| --------- | ---- | ----------- |
| `application` | object | `including` and `excluding` lists of application security attribute IDs. |
| `business_impact` | object | `including` and `excluding` lists of business impact security attribute IDs. |
| `business_unit` | object | `including` and `excluding` lists of business unit security attribute IDs. |
| `compliance_frameworks` | array | IDs of compliance frameworks the project must carry. Takes a list directly, rather than `including` and `excluding`. |
| `exposure` | object | `including` and `excluding` lists of exposure security attribute IDs. |
| `groups` | object | `including` and `excluding` lists of group IDs. |
| `match_mode` | string | Either `all` or `any`. With `all`, every criterion must match. With `any`, one match is enough. Any other value is treated as `all`. |
| `projects` | object | `including` and `excluding` lists of project IDs. `excluding` also accepts `{"type": "personal"}` and `{"type": "archived"}`, which exclude every project of that kind. |

For example:

```json
{
  "match_mode": "any",
  "compliance_frameworks": [{ "id": 5 }],
  "projects": { "including": [12, 34], "excluding": [{ "type": "archived" }] },
  "groups": { "including": [{ "id": 7 }] }
}
```

A value GitLab cannot read as an ID returns `400 Bad Request`.
That covers a value that is not a number, and a number outside the range 1 to 9223372036854775807.

Three cases are accepted and worth knowing, because each one scopes the policy differently
from what you might expect:

- An `including` list that names no IDs matches nothing for that criterion. Under
  `match_mode: all` the policy then applies to no project. Under `match_mode: any` another
  criterion can still match.
- An `excluding` list that names no IDs excludes nothing.
- A criterion GitLab does not recognize has no effect. If it was the only criterion supplied,
  the policy applies to every project.

### Rules and actions

`rules` and `actions` are arrays.
Each entry has the following attributes:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `type`    | string         | Yes      | For a rule, one of the IDs returned by [List all rule kinds](#list-all-rule-kinds). For an action, one of the IDs returned by [List all actions](#list-all-actions). |
| `value`   | string or hash | No       | What the entry acts on. A `custom` rule takes Rego source as a string. A `calendar` or `environment` rule takes a hash, as does every action. |

An entry cannot be blank.
A blank entry returns `400 Bad Request`, and the error names each blank position,
for example `rules[0] is blank`.

Each array accepts at most 5 entries, and each entry cannot serialize to more than 4096 bytes.
Exceeding either limit returns `400 Bad Request`. An oversized entry names each offending
position, for example `rules has an entry exceeding maximum size of 4096 bytes at 0`.

A request replaces the whole array.
You cannot add or remove a single entry.

Send `rules` and `actions` as JSON with a `Content-Type: application/json` header.
A form-encoded body can carry both arrays, but every value in one arrives as a string, so a
`value` that is not a string cannot be expressed that way.

### Response attributes

The policy endpoints return the following attributes:

| Attribute         | Type            | Description |
| ----------------- | --------------- | ----------- |
| `actions`         | array           | Actions the policy takes. |
| `created_at`      | string          | Date and time the policy was created. |
| `description`     | string          | Description of the policy. |
| `id`              | integer         | ID of the policy. |
| `lifecycle_state` | string          | Either `active` or `disabled`. |
| `mode`            | string          | One of `audit`, `warn`, or `enforce`. |
| `name`            | string          | Name of the policy. |
| `namespace_id`    | integer         | ID of the group that owns the policy. Always `null` today, because no endpoint accepts a `namespace_id` attribute, so every policy created through this API is owned by its organization. |
| `organization_id` | integer         | ID of the organization the policy belongs to. |
| `policy_rego`     | string          | The policy's rules, compiled to a single Rego module. `null` for a policy with no rules. |
| `policy_scope`    | object          | Structured scope of the policy, or `null` when the Rego was authored directly. |
| `rules`           | array           | Rules of the policy. |
| `scope_dimensions`| array           | Dotted context paths `scope_rego` reads to decide whether the policy applies. GitLab derives this value, so it ignores any value you send for it. `null` when `scope_rego` was authored directly, otherwise an array, empty when the policy is unscoped. |
| `scope_rego`      | string          | Compiled scope of the policy, as Rego. |
| `trigger_type`    | string          | Trigger the policy responds to. |
| `updated_at`      | string          | Date and time the policy was last changed. |
| `version`         | integer         | Revision of the policy. An update that changes at least one value raises it by one. |

### List all policies

List all policies belonging to an organization.

```plaintext
GET /organizations/:id/security/policy_store
```

Supported attributes:

| Attribute      | Type    | Required | Description |
| -------------- | ------- | -------- | ----------- |
| `id`           | integer | Yes      | ID of the organization. |
| `trigger_type` | string  | No       | Return only the policies that respond to this trigger. One of the IDs returned by [List all triggers](#list-all-triggers). |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and an array of
[policy attributes](#response-attributes).

Example request:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/organizations/1/security/policy_store"
```

Example response:

```json
[
  {
    "id": 1,
    "organization_id": 1,
    "namespace_id": null,
    "name": "Block deployments on critical findings",
    "description": null,
    "version": 1,
    "trigger_type": "deployment_requested",
    "rules": [{ "type": "custom", "value": "package governance" }],
    "policy_rego": "package governance\n",
    "actions": [{ "type": "block" }],
    "policy_scope": null,
    "scope_dimensions": [],
    "scope_rego": "package gitlab.scope\n\napplicable := [result.policy | some result in results; result.applies]\n...",
    "mode": "enforce",
    "lifecycle_state": "active",
    "created_at": "2026-08-07T13:56:32.985Z",
    "updated_at": "2026-08-07T13:56:32.985Z"
  }
]
```

### Retrieve a policy

Retrieve a single policy from an organization.

```plaintext
GET /organizations/:id/security/policy_store/:policy_id
```

Supported attributes:

| Attribute   | Type    | Required | Description |
| ----------- | ------- | -------- | ----------- |
| `id`        | integer | Yes      | ID of the organization. |
| `policy_id` | integer | Yes      | ID of the policy. |

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the
[policy attributes](#response-attributes).

Example request:

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/organizations/1/security/policy_store/1"
```

Example response:

```json
{
  "id": 1,
  "organization_id": 1,
  "namespace_id": null,
  "name": "Block deployments on critical findings",
  "description": null,
  "version": 1,
  "trigger_type": "deployment_requested",
  "rules": [{ "type": "custom", "value": "package governance" }],
  "policy_rego": "package governance\n",
  "actions": [{ "type": "block" }],
  "policy_scope": null,
  "scope_dimensions": [],
  "scope_rego": "package gitlab.scope\n\napplicable := [result.policy | some result in results; result.applies]\n...",
  "mode": "enforce",
  "lifecycle_state": "active",
  "created_at": "2026-08-07T13:56:32.985Z",
  "updated_at": "2026-08-07T13:56:32.985Z"
}
```

### Create a policy

Create a policy in an organization.

```plaintext
POST /organizations/:id/security/policy_store
```

Supported attributes:

| Attribute         | Type    | Required | Description |
| ----------------- | ------- | -------- | ----------- |
| `id`              | integer | Yes      | ID of the organization. |
| `name`            | string  | Yes      | Name of the policy. Maximum 255 characters. Must be unique in the organization. |
| `rules`           | array   | Yes      | Rules of the policy. At least one entry is required, up to 5. Each entry must serialize to at most 4096 bytes. Rejected when the entries compile to a Rego module larger than 65536 bytes. That module is returned as `policy_rego`. |
| `trigger_type`    | string  | Yes      | Trigger the policy responds to. One of the IDs returned by [List all triggers](#list-all-triggers). |
| `actions`         | array   | No       | Actions the policy takes. Up to 5 entries. Each entry must serialize to at most 4096 bytes. |
| `description`     | string  | No       | Description of the policy. Maximum 4096 characters. |
| `lifecycle_state` | string  | No       | Either `active` or `disabled`. Defaults to `active`. |
| `mode`            | string  | No       | One of `audit`, `warn`, or `enforce`. Defaults to `enforce`. |
| `policy_scope`    | object  | No       | Structured scope of the policy. Cannot be combined with a non-empty `scope_rego`. Rejected when it compiles to more than 4096 characters of Rego. |
| `scope_rego`      | string  | No       | Scope of the policy, authored as Rego. Maximum 4096 characters. A non-empty value cannot be combined with `policy_scope`. |

If successful, returns [`201`](rest/troubleshooting.md#status-codes) and the
[policy attributes](#response-attributes).
The following conditions return `400 Bad Request`:

- An attribute is invalid.
- Both scope forms are supplied.
- The name is already taken in the organization.
- A compiled `scope_rego` exceeds 4096 characters.
- The `rules` compile to more than 65536 bytes of Rego.
- `rules` or `actions` carries more than 5 entries.
- An entry in `rules` or `actions` serializes to more than 4096 bytes.

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --data '{
    "name": "Block deployments on critical findings",
    "trigger_type": "deployment_requested",
    "rules": [{ "type": "custom", "value": "package governance" }],
    "actions": [{ "type": "block" }],
    "policy_scope": { "compliance_frameworks": [{ "id": 5 }] }
  }' \
  --url "https://gitlab.example.com/api/v4/organizations/1/security/policy_store"
```

Example response:

```json
{
  "id": 1,
  "organization_id": 1,
  "namespace_id": null,
  "name": "Block deployments on critical findings",
  "description": null,
  "version": 1,
  "trigger_type": "deployment_requested",
  "rules": [{ "type": "custom", "value": "package governance" }],
  "policy_rego": "package governance\n",
  "actions": [{ "type": "block" }],
  "policy_scope": { "compliance_frameworks": [{ "id": 5 }] },
  "scope_dimensions": ["compliance_frameworks"],
  "scope_rego": "package gitlab.scope\n\napplicable := [result.policy | some result in results; result.applies]\n...",
  "mode": "enforce",
  "lifecycle_state": "active",
  "created_at": "2026-08-07T13:56:32.985Z",
  "updated_at": "2026-08-07T13:56:32.985Z"
}
```

### Update a policy

Update a policy in an organization.
Every attribute other than the path parameters is optional, but a request must name at least one.
Attributes that are not sent are left as they are, and an update that changes at least one
value raises `version` by one.
A request that restates the stored values changes nothing, and leaves `version` as it is.

```plaintext
PATCH /organizations/:id/security/policy_store/:policy_id
```

Supported attributes:

| Attribute         | Type    | Required | Description |
| ----------------- | ------- | -------- | ----------- |
| `id`              | integer | Yes      | ID of the organization. |
| `policy_id`       | integer | Yes      | ID of the policy. |
| `actions`         | array   | No       | Actions the policy takes. Replaces the stored actions, up to 5 entries. Each entry must serialize to at most 4096 bytes. |
| `description`     | string  | No       | Description of the policy. Maximum 4096 characters. |
| `lifecycle_state` | string  | No       | Either `active` or `disabled`. |
| `mode`            | string  | No       | One of `audit`, `warn`, or `enforce`. |
| `name`            | string  | No       | Name of the policy. Maximum 255 characters. Must be unique in the organization. |
| `policy_scope`    | object  | No       | Structured scope of the policy. Cannot be combined with a non-empty `scope_rego`. Rejected when it compiles to more than 4096 characters of Rego. |
| `rules`           | array   | No       | Rules of the policy. Replaces the stored rules, up to 5 entries. Each entry must serialize to at most 4096 bytes. Rejected when the entries compile to a Rego module larger than 65536 bytes. That module is returned as `policy_rego`. |
| `scope_rego`      | string  | No       | Scope of the policy, authored as Rego. Maximum 4096 characters. Send an empty value to retire an authored program and recompile from `policy_scope`. |
| `trigger_type`    | string  | No       | Trigger the policy responds to. One of the IDs returned by [List all triggers](#list-all-triggers). |

When you rename a policy, GitLab must recompile a generated `scope_rego`, because the policy
name appears in the generated program.
A `scope_rego` that was authored directly is left as it is.

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the
[policy attributes](#response-attributes).
The following conditions return `400 Bad Request`:

- No attribute to change is supplied.
- An attribute is invalid.
- Both scope forms are supplied.
- The new name is already taken in the organization.
- A recompiled `scope_rego` exceeds 4096 characters.
- The replacement `rules` compile to more than 65536 bytes of Rego.
- The replacement `rules` or `actions` carries more than 5 entries.
- An entry in the replacement `rules` or `actions` serializes to more than 4096 bytes.

Example request:

```shell
curl --request PATCH --header "PRIVATE-TOKEN: <your_access_token>" \
  --data-urlencode "name=Renamed policy" \
  --url "https://gitlab.example.com/api/v4/organizations/1/security/policy_store/1"
```

Example response:

```json
{
  "id": 1,
  "organization_id": 1,
  "namespace_id": null,
  "name": "Renamed policy",
  "description": null,
  "version": 2,
  "trigger_type": "deployment_requested",
  "rules": [{ "type": "custom", "value": "package governance" }],
  "policy_rego": "package governance\n",
  "actions": [{ "type": "block" }],
  "policy_scope": null,
  "scope_dimensions": [],
  "scope_rego": "package gitlab.scope\n\napplicable := [result.policy | some result in results; result.applies]\n...",
  "mode": "enforce",
  "lifecycle_state": "active",
  "created_at": "2026-08-07T13:56:32.985Z",
  "updated_at": "2026-08-07T14:02:47.198Z"
}
```

### Delete a policy

Delete a policy from an organization.

```plaintext
DELETE /organizations/:id/security/policy_store/:policy_id
```

Supported attributes:

| Attribute   | Type    | Required | Description |
| ----------- | ------- | -------- | ----------- |
| `id`        | integer | Yes      | ID of the organization. |
| `policy_id` | integer | Yes      | ID of the policy. |

If successful, returns [`204`](rest/troubleshooting.md#status-codes) and an empty response
body.

Example request:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/organizations/1/security/policy_store/1"
```
