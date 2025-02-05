---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Organizations API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed
**Status:** Experiment

## Create organization

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/470613) in GitLab 17.5 with a [flag](../administration/feature_flags.md) named `allow_organization_creation`. Disabled by default. This feature is an [experiment](../policy/development_stages_support.md).

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

Creates a new organization.

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
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
--form "name=New Organization" \
--form "path=new-org" \
--form "description=A new organization" \
--form "avatar=@/path/to/avatar.png" \
"https://gitlab.example.com/api/v4/organizations"
```

Example response:

```json
{
  "id": 42,
  "name": "New Organization",
  "path": "new-org",
  "description": "A new organization",
  "created_at": "2024-09-18T02:35:15.371Z",
  "updated_at": "2024-09-18T02:35:15.371Z",
  "web_url": "https://gitlab.example.com/-/organizations/new-org",
  "avatar_url": "https://gitlab.example.com/uploads/-/system/organizations/organization_detail/avatar/42/avatar.png"
}
```
