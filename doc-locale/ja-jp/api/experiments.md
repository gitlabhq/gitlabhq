---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 実験API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com

{{< /details >}}

このAPIを使用してA/B実験を操作します。このAPIは内部使用のみを目的としています。

前提条件: 

- [GitLabチームメンバー](https://gitlab.com/groups/gitlab-com/-/group_members)である必要があります。

## すべての実験をリスト表示 {#list-all-experiments}

GitLabインスタンス上のすべての実験をリスト表示します。各実験には、`enabled`ステータスがあり、その実験がグローバルに有効になっているか、特定のコンテキストでのみ有効になっているかを示します。

```plaintext
GET /experiments
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/experiments"
```

レスポンス例: 

```json
[
  {
    "key": "code_quality_walkthrough",
    "definition": {
      "name": "code_quality_walkthrough",
      "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/58900",
      "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/327229",
      "milestone": "13.12",
      "type": "experiment",
      "group": "group::activation",
      "default_enabled": false
    },
    "current_status": {
      "state": "conditional",
      "gates": [
        {
          "key": "boolean",
          "value": false
        },
        {
          "key": "percentage_of_actors",
          "value": 25
        }
      ]
    }
  },
  {
    "key": "ci_runner_templates",
    "definition": {
      "name": "ci_runner_templates",
      "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/58357",
      "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/326725",
      "milestone": "14.0",
      "type": "experiment",
      "group": "group::activation",
      "default_enabled": false
    },
    "current_status": {
      "state": "off",
      "gates": [
        {
          "key": "boolean",
          "value": false
        }
      ]
    }
  }
]
```

## キャッシュされた割り当てを削除 {#delete-cached-assignments}

キャッシュストアから、実験のすべてのキャッシュされたバリアントの割り当てを削除します。このエンドポイントを使用して、コードベースからコードが削除されても、キャッシュされた割り当てが残っている完了した実験をクリーンアップします。

```plaintext
DELETE /experiments/:name/cache
```

サポートされている属性:

| 属性 | 型   | 必須 | 説明 |
|-----------|--------|----------|-------------|
| `name`    | 文字列 | はい      | クリアする実験のキャッシュキー。 |

成功すると、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

指定された名前にキャッシュされた割り当てが存在しない場合でも、リクエストは`204 No Content`を返します。名前が実験ではないキャッシュキーを参照している場合、リクエストは`400 Bad Request`を返します。リクエストが認証されていない場合、リクエストは`401 Unauthorized`を返します。ユーザーがGitLabチームメンバーではない場合、リクエストは`403 Forbidden`を返します。

> [!warning]
> `name`の値は、キャッシュキーとして直接使用されます。このエンドポイントは、現在定義されている実験に属していない場合でも、一致するすべてのキャッシュエントリをクリアします。この動作は、コードが削除された孤立した実験のクリーンアップをサポートします。このエンドポイントを呼び出す前に、名前を確認してください。

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/experiments/code_quality_walkthrough/cache"
```
