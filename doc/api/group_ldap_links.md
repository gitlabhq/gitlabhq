---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
title: LDAP group links
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Use this API to manage LDAP group links. For more information, see [manage group memberships with LDAP](../user/group/access_and_permissions.md#manage-group-memberships-with-ldap).

## List LDAP group links

Lists LDAP group links.

```plaintext
GET /groups/:id/ldap_group_links
```

Supported attributes:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/4/ldap_group_links"
```

Example response:

```json
[
  {
    "cn": "group1",
    "group_access": 40,
    "provider": "ldapmain",
    "filter": null,
    "member_role_id": null
  },
  {
    "cn": "group2",
    "group_access": 10,
    "provider": "ldapmain",
    "filter": null,
    "member_role_id": null
  }
]
```

## Add an LDAP group link with CN or filter

Adds an LDAP group link using a CN or filter.

```plaintext
POST /groups/:id/ldap_group_links
```

Supported attributes:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |
| `group_access` | integer   | yes      | The default access level for members of the LDAP group. Possible values: `0` (No access), `5` (Minimal access), `10` (Guest), `15` (Planner), `20` (Reporter), `30` (Developer), `40` (Maintainer), `50` (Owner). |
| `provider` | string        | yes      | LDAP provider ID for the LDAP group link. |
| `cn`      | string         | yes/no   | The CN of an LDAP group. Provide either a `cn` or a `filter`, but not both. |
| `filter`  | string         | yes/no   | The LDAP filter for the group. Provide either a `cn` or a `filter`, but not both. |
| `member_role_id` | integer | no       | The ID of the [member role](member_roles.md). Ultimate only. |

Example request:

```shell
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"group_access": 40, "provider": "ldapmain", "cn": "group2"}' \
     --url "https://gitlab.example.com/api/v4/groups/4/ldap_group_links"
```

Example response:

```json
{
  "cn": "group2",
  "group_access": 40,
  "provider": "main",
  "filter": null,
  "member_role_id": null
}
```

## Delete an LDAP group link with CN or filter

Deletes an LDAP group link using a CN or filter.

```plaintext
DELETE /groups/:id/ldap_group_links
```

Supported attributes:

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group |
| `provider` | string        | yes      | LDAP provider ID for the LDAP group link. |
| `cn`      | string         | yes/no   | The CN of an LDAP group. Provide either a `cn` or a `filter`, but not both. |
| `filter`  | string         | yes/no   | The LDAP filter for the group. Provide either a `cn` or a `filter`, but not both. |

Example request:

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --data '{"provider": "ldapmain", "cn": "group2"}' \
     --url "https://gitlab.example.com/api/v4/groups/4/ldap_group_links"
```

If successful, no response is returned.

## Delete an LDAP group link (deprecated)

Deletes an LDAP group link. Deprecated. Scheduled for removal in a future release.
Use [Delete an LDAP group link with CN or filter](#delete-an-ldap-group-link-with-cn-or-filter) instead.

Delete an LDAP group link with a CN:

```plaintext
DELETE /groups/:id/ldap_group_links/:cn
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group |
| `cn`      | string         | yes      | The CN of an LDAP group |

Delete an LDAP group link for a specific LDAP provider:

```plaintext
DELETE /groups/:id/ldap_group_links/:provider/:cn
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ----------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the group |
| `cn`      | string         | yes      | The CN of an LDAP group |
| `provider` | string        | yes      | LDAP provider for the LDAP group link |
