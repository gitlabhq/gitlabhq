---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクト統計API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[プロジェクト](../user/project/_index.md)に関する統計を取得することができます。すべてのエンドポイントで認証が必要です。

リポジトリへの読み取りアクセス権が必要です。[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)には`read_api`スコープが必要です。[グループアクセストークン](../user/group/settings/group_access_tokens.md)はレポーターロールと`read_api`スコープを使用できます。

このAPIは、プロジェクトがHTTPメソッドでクローンまたはプルされた回数を取得します。SSHによるフェッチは含まれません。

## 過去30日間の統計を取得する {#retrieve-the-statistics-of-the-last-30-days}

指定されたプロジェクトの過去30日間のクローンとプルの統計を取得することができます。

```plaintext
GET /projects/:id/statistics
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明                                                                    |
|-----------|-------------------|----------|--------------------------------------------------------------------------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。     |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性              | 型    | 説明 |
|------------------------|---------|-------------|
| `fetches`              | オブジェクト  | プロジェクトのフェッチ統計。 |
| `fetches.days`         | 配列   | 日ごとのフェッチ統計の配列。 |
| `fetches.days[].count` | 整数 | 特定の日付のフェッチ数。 |
| `fetches.days[].date`  | 文字列  | ISO形式の日付 (`YYYY-MM-DD`)。 |
| `fetches.total`        | 整数 | 過去30日間の合計フェッチ数。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/42/statistics"
```

レスポンス例: 

```json
{
  "fetches": {
    "total": 50,
    "days": [
      {
        "count": 10,
        "date": "2018-01-10"
      },
      {
        "count": 10,
        "date": "2018-01-09"
      },
      {
        "count": 10,
        "date": "2018-01-08"
      },
      {
        "count": 10,
        "date": "2018-01-07"
      },
      {
        "count": 10,
        "date": "2018-01-06"
      }
    ]
  }
}
```
