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

Use the following endpoints to perform [bulk placeholder reassignment](../user/project/import/_index.md#request-reassignment-by-using-a-csv-file) without using the UI.

## Download the CSV reassignment spreadsheet

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
