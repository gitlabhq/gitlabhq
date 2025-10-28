---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group placeholder reassignments API
description: "Reassign placeholder users in bulk with the REST API."
---

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/513794) in GitLab 17.10 [with a flag](../administration/feature_flags/_index.md) named `importer_user_mapping_reassignment_csv`. Enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/478022) in GitLab 18.0. Feature flag `importer_user_mapping_reassignment_csv` removed.
- Reassigning contributions to a personal namespace owner when importing to a personal namespace [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/525342) in GitLab 18.3 [with a flag](../administration/feature_flags/_index.md) named `user_mapping_to_personal_namespace_owner`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Use this API to [reassign placeholder users in bulk](../user/project/import/_index.md#request-reassignment-by-using-a-csv-file).

Prerequisites:

- You must have the Owner role for the group.
{{< alert type="note" >}}

User contribution mapping is not supported when you import projects to a [personal namespace](../user/namespace/_index.md#types-of-namespaces).
When you import to a personal namespace and the `user_mapping_to_personal_namespace_owner` feature flag
is enabled, all contributions are assigned to the personal namespace owner and they cannot be reassigned.
When the `user_mapping_to_personal_namespace_owner` feature flag is disabled, all contributions are
assigned to a single non-functional user called `Import User` and they cannot be reassigned.

{{< /alert >}}

## Download the CSV file

Download a CSV file of pending reassignments.

```plaintext
GET /groups/:id/placeholder_reassignments
```

Supported attributes:

| Attribute | Type              | Required | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | integer or string | yes      | ID of the group or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/2/placeholder_reassignments"
```

Example response:

```csv
Source host,Import type,Source user identifier,Source user name,Source username,GitLab username,GitLab public email
http://gitlab.example,gitlab_migration,11,Bob,bob,"",""
http://gitlab.example,gitlab_migration,9,Alice,alice,"",""
```

## Reassign placeholders

Complete the [CSV file](#download-the-csv-file) and upload it to reassign placeholder users.

```plaintext
POST /groups/:id/placeholder_reassignments
```

Supported attributes:

| Attribute | Type              | Required | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | integer or string | yes      | ID of the group or [URL-encoded path](rest/_index.md#namespaced-paths) of the group. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "file=@placeholder_reassignments_for_group_2_1741253695.csv" \
  --url "http://gdk.test:3000/api/v4/groups/2/placeholder_reassignments"
```

Example response:

```json
{"message":"The file is being processed and you will receive an email when completed."}
```
