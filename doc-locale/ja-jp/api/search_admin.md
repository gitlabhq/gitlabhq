---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 検索管理者API
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120751) GitLab 16.1

{{< /history >}}

このAPIを使用して、[高度な検索](../integration/advanced_search/elasticsearch.md#advanced-search-migrations)移行に関する取得情報を取得します。

前提要件: 

- 管理者である必要があります。

## すべての高度な検索移行を一覧表示 {#list-all-advanced-search-migrations}

GitLabインスタンスのすべての高度な検索移行のリストを取得します。

```plaintext
GET /admin/search/migrations
```

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/admin/search/migrations"
```

レスポンス例:

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

## 高度な検索移行を取得 {#get-an-advanced-search-migration}

移行のバージョンまたは名前を指定して、単一の高度な検索移行を取得します。

```plaintext
GET /admin/search/migrations/:version_or_name
```

パラメータは以下のとおりです:

| 属性         | 型           | 必須 | 説明                          |
|-------------------|----------------|----------|--------------------------------------|
| `version_or_name` | 整数または文字列 | はい      | 移行のバージョンまたは名前。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/admin/search/migrations/20230503064300"
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://primary.example.com/api/v4/admin/search/migrations/BackfillProjectPermissionsInBlobsUsingPermutations"
```

成功した場合、[`200`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性         | 型     | 説明                                           |
|:------------------|:---------|:------------------------------------------------------|
| `version`         | 整数  | 移行のバージョン。                             |
| `name`            | 文字列   | 移行の名前。                                |
| `started_at`      | 日時 | 移行の開始日。                         |
| `completed_at`    | 日時 | 移行の完了日。                    |
| `completed`       | ブール値  | `true`の場合、移行は完了しています。                |
| `obsolete`        | ブール値  | `true`の場合、移行は廃止としてマークされています。 |
| `migration_state` | オブジェクト   | 保存された移行の状態。                               |

レスポンス例:

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
