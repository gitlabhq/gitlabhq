---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Group placeholder reassignments API
---

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/513794) in GitLab 17.10 [with a flag](../administration/feature_flags.md) named `importer_user_mapping_reassignment_csv`. [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/478022).

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Prerequisites:

- You must have the Owner role for the group.

Use the following endpoints to [reassign placeholder users in bulk](../user/project/import/_index.md#request-reassignment-by-using-a-csv-file) without using the UI.

{{< alert type="note" >}}

User contribution mapping is not supported when you import projects to a [personal namespace](../user/namespace/_index.md#types-of-namespaces).
When you import to a personal namespace, all contributions are assigned to
a single non-functional user called `Import User` and they cannot be reassigned.
[Issue 525342](https://gitlab.com/gitlab-org/gitlab/-/issues/525342) proposes to map all contributions to the importing user instead.

{{< /alert >}}

## Download the CSV file

Download a CSV file of pending reassignments.

```plaintext
GET /groups/:id/placeholder_reassignments
```

Supported attributes:

| Attribute | Type              | Required | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | integer or string | yes      | ID of the group or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl \
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
| `id`      | integer or string | yes      | ID of the group or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |

Example request:

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --form "file=@placeholder_reassignments_for_group_2_1741253695.csv" \
  "http://gdk.test:3000/api/v4/groups/2/placeholder_reassignments"
```

Example response:

```json
{"message":"The file is being processed and you will receive an email when completed."}
```
