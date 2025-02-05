---
stage: Foundations
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Search admin API
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120751) in GitLab 16.1

The search admin API returns information about [advanced search migrations](../integration/advanced_search/elasticsearch.md#advanced-search-migrations).

You must have administrator access to use this API.

## List all advanced search migrations

Get a list of all advanced search migrations for the GitLab instance.

```plaintext
GET /admin/search/migrations
```

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/search/migrations"
```

Example response:

```json
[
  {
    "version": 20230427555555,
    "name": "BackfillHiddenOnMergeRequests",
    "started_at": "2023-05-12T01:35:05.469+00:00",
    "completed_at": "2023-05-12T01:36:06.432+00:00",
    "completed": true,
    "obsolete": false,
    "migration_state": {}
  },
  {
    "version": 20230428500000,
    "name": "AddSuffixProjectInWikiRid",
    "started_at": "2023-05-04T18:59:43.542+00:00",
    "completed_at": "2023-05-04T18:59:43.542+00:00",
    "completed": false,
    "obsolete": false,
    "migration_state": {
      "pause_indexing": true,
      "slice": 1,
      "task_id": null,
      "max_slices": 5,
      "retry_attempt": 0
    }
  },
  {
    "version": 20230503064300,
    "name": "BackfillProjectPermissionsInBlobsUsingPermutations",
    "started_at": "2023-05-03T16:04:44.074+00:00",
    "completed_at": "2023-05-03T16:04:44.074+00:00",
    "completed": true,
    "obsolete": false,
    "migration_state": {
      "permutation_idx": 8,
      "documents_remaining": 5,
      "task_id": "I2_LXc-xQlOeu-KmjYpM8g:172820",
      "documents_remaining_for_permutation": 0
    }
  }
]
```

## Get an advanced search migration

Get a single advanced search migration by providing the migration version or name.

```plaintext
GET /admin/search/mirations/:version_or_name
```

Parameters:

| Attribute         | Type           | Required | Description                          |
|-------------------|----------------|----------|--------------------------------------|
| `version_or_name` | integer/string | Yes      | The version or name of the migration. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/search/mirations/20230503064300"
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://primary.example.com/api/v4/admin/search/mirations/BackfillProjectPermissionsInBlobsUsingPermutations"
```

If successful, returns [`200`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute         | Type     | Description                                           |
|:------------------|:---------|:------------------------------------------------------|
| `version`         | integer  | Version of the migration.                             |
| `name`            | string   | Name of the migration.                                |
| `started_at`      | datetime | Start date for the migration.                         |
| `completed_at`    | datetime | Completion date for the migration.                    |
| `completed`       | boolean  | If `true`, the migration is completed.                |
| `obsolete`        | boolean  | If `true`, the migration has been marked as obsolete. |
| `migration_state` | object   | Stored migration state.                               |

Example response:

```json
{
  "version": 20230503064300,
  "name": "BackfillProjectPermissionsInBlobsUsingPermutations",
  "started_at": "2023-05-03T16:04:44.074+00:00",
  "completed_at": "2023-05-03T16:04:44.074+00:00",
  "completed": true,
  "obsolete": false,
  "migration_state": {
    "permutation_idx": 8,
    "documents_remaining": 5,
    "task_id": "I2_LXc-xQlOeu-KmjYpM8g:172820",
    "documents_remaining_for_permutation": 0
  }
}
```
