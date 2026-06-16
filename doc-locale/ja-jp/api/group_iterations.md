---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グループイテレーションAPI
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[グループイテレーション](../user/group/iterations/_index.md)にアクセスします。

プロジェクトイテレーションには、[プロジェクトイテレーションAPI](iterations.md)を使用してください。

## すべてのグループイテレーションを一覧表示 {#list-all-group-iterations}

指定されたグループのすべてのイテレーションをリスト表示します。

[イテレーションケイデンス](../user/group/iterations/_index.md#iteration-cadences)で**自動スケジュールを有効にする**によって作成されたイテレーションは、`title`フィールドと`description`フィールドに対して`null`を返します。

```plaintext
GET /groups/:id/iterations
GET /groups/:id/iterations?state=opened
GET /groups/:id/iterations?state=closed
GET /groups/:id/iterations?search=version
GET /groups/:id/iterations?include_ancestors=false
GET /groups/:id/iterations?include_descendants=true
GET /groups/:id/iterations?updated_before=2013-10-02T09%3A24%3A18Z
GET /groups/:id/iterations?updated_after=2013-10-02T09%3A24%3A18Z
```

| 属性             | 型     | 必須 | 説明 |
| --------------------- | -------- | -------- | ----------- |
| `state`               | 文字列   | いいえ       | '`opened`、`upcoming`、`current`、`closed`、または`all`のイテレーションを返します。' |
| `search`              | 文字列   | いいえ       | 指定された文字列と一致するタイトルを持つイテレーションのみを返します。                              |
| `in`                  | 文字列の配列 | いいえ | `search`引数で指定されたクエリを使用して、ファジー検索を実行するフィールド。利用可能なオプションは`title`と`cadence_title`です。デフォルトは`[title]`です。GitLab 16.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/350991)されました。 |
| `include_ancestors`   | ブール値  | いいえ       | グループとその祖先のイテレーションを含めます。`true`がデフォルトです。                    |
| `include_descendants` | ブール値  | いいえ       | グループとその子孫のイテレーションを含めます。`false`がデフォルトです。GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135764)されました。 |
| `updated_before`      | 日時 | いいえ       | 指定された日時より前に更新されたイテレーションのみを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/378662)されました。 |
| `updated_after`       | 日時 | いいえ       | 指定された日時より後に更新されたイテレーションのみを返します。ISO 8601形式（`2019-03-15T08:00:00Z`）で指定します。GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/378662)されました。 |

リクエスト例: 

```shell
  curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/5/iterations"
```

レスポンス例: 

```json
[
  {
    "id": 53,
    "iid": 13,
    "sequence": 1,
    "group_id": 5,
    "title": "Iteration II",
    "description": "Ipsum Lorem ipsum",
    "state": 2,
    "created_at": "2020-01-27T05:07:12.573Z",
    "updated_at": "2020-01-27T05:07:12.573Z",
    "due_date": "2020-02-01",
    "start_date": "2020-02-14",
    "web_url": "http://gitlab.example.com/groups/my-group/-/iterations/13"
  }
]
```
