---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Organizations API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

Use this API to interact with GitLab organizations. For more information, see [organization](../user/organization/_index.md).

## Create an organization

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/470613) in GitLab 17.5 with a [flag](../administration/feature_flags/_index.md) named `allow_organization_creation`. Disabled by default. This feature is an [experiment](../policy/development_stages_support.md).
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/549062) in GitLab 18.4. Feature flag `allow_organization_creation` consolidated and renamed to `organization_switching`.
- Feature flag [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/249678) to `org_stage_experimental` in GitLab 19.4. Disabled by default. Feature flag `organization_switching` removed.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

Creates an organization.

This endpoint is an [experiment](../policy/development_stages_support.md) and might be changed or removed without notice.

```plaintext
POST /organizations
```

Parameters:

| Attribute     | Type   | Required | Description                           |
|---------------|--------|----------|---------------------------------------|
| `name`        | string | yes      | The name of the organization          |
| `path`        | string | yes      | The path of the organization          |
| `description` | string | no       | The description of the organization   |
| `avatar`      | file   | no       | The avatar image for the organization |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "name=New Organization" \
  --form "path=new-org" \
  --form "description=A new organization" \
  --form "avatar=@/path/to/avatar.png" \
  --url "https://gitlab.example.com/api/v4/organizations"
```

Example response:

```json
{
  "id": 42,
  "uuid": "0192f8c2-1a2b-7cde-89ab-0123456789ab",
  "name": "New Organization",
  "path": "new-org",
  "description": "A new organization",
  "created_at": "2024-09-18T02:35:15.371Z",
  "updated_at": "2024-09-18T02:35:15.371Z",
  "web_url": "https://gitlab.example.com/o/new-org/-/overview",
  "avatar_url": "https://gitlab.example.com/uploads/-/system/organizations/organization_detail/avatar/42/avatar.png"
}
```

## Restore an organization

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/599346) as an [experiment](../policy/development_stages_support.md) in GitLab 19.6.

{{< /history >}}

Restores a soft-deleted organization.

Prerequisites:

- You must be an administrator.

```plaintext
POST /organizations/:id/restore
```

Supported attributes:

| Attribute | Type    | Required | Description                 |
|-----------|---------|----------|-----------------------------|
| `id`      | integer | Yes      | The ID of the organization. |

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute     | Type     | Description |
|---------------|----------|-------------|
| `avatar_url`  | string   | URL of the organization avatar. |
| `created_at`  | datetime | Timestamp when the organization was created. |
| `description` | string   | Description of the organization. |
| `id`          | integer  | ID of the organization. |
| `name`        | string   | Name of the organization. |
| `path`        | string   | Path of the organization. |
| `updated_at`  | datetime | Timestamp when the organization was last updated. |
| `uuid`        | string   | UUID of the organization. |
| `visibility`  | string   | Visibility level of the organization. |
| `web_url`     | string   | URL of the organization. |

If the organization is not soft-deleted, returns `400 Bad Request`.

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/organizations/42/restore"
```

Example response:

```json
{
  "id": 42,
  "uuid": "0192f8c2-1a2b-7cde-89ab-0123456789ab",
  "name": "New Organization",
  "path": "new-org",
  "description": "A new organization",
  "visibility": "private",
  "created_at": "2024-09-18T02:35:15.371Z",
  "updated_at": "2024-09-20T10:12:45.118Z",
  "web_url": "https://gitlab.example.com/o/new-org/-/overview",
  "avatar_url": null
}
```
