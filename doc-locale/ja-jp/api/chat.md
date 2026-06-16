---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLab Duo Chat用のREST APIに関するドキュメント。
title: GitLab Duo Chat補完API
---

このAPIは、[GitLab Duo Chat](../user/gitlab_duo_chat/_index.md)の応答を生成するために使用されます:

- GitLab.comでは、このAPIは内部使用のみです。
- GitLab Self-Managedでは、`access_rest_chat`という名前の[機能フラグ](../administration/feature_flags/_index.md)でこのAPIを有効にできます。

前提条件: 

- [GitLabチームメンバー](https://gitlab.com/groups/gitlab-com/-/group_members)である必要があります。

## チャットの応答を生成する {#generate-a-chat-response}

GitLab Duo Chatの質問に対する応答を生成します。

{{< history >}}

- GitLab 16.7で`access_rest_chat`[フラグ](../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133015)されました。デフォルトでは無効になっています。この機能は内部専用です。
- GitLab 17.4で`duo_additional_context`という名前の[フラグ](../administration/feature_flags/_index.md)と共に`additional_context`パラメータが[追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162650)されました。デフォルトでは無効になっています。この機能は内部専用です。
- GitLab 17.9で、GitLab.comおよびGitLab Self-Managedで`additional_context`パラメータが[有効化](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/181305)されました。
- GitLab 18.0で`additional_context`パラメータが[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/514559)されました。機能フラグ`duo_additional_context`は削除されました。

{{< /history >}}

> [!flag]
> この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

```plaintext
POST /chat/completions
```

> [!note]
> このエンドポイントへのリクエストは、[AIゲートウェイ](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/api.md)にプロキシされます。

サポートされている属性は以下のとおりです: 

| 属性                | 型            | 必須 | 説明                                                             |
|--------------------------|-----------------|----------|-------------------------------------------------------------------------|
| `content`                | 文字列          | はい      | チャットに送信された質問。                                                  |
| `resource_type`          | 文字列          | いいえ       | チャットの質問とともに送信されるリソースのタイプ。                       |
| `resource_id`            | 文字列、整数 | いいえ       | リソースのID。リソースID（整数）またはコミットハッシュ（文字列）にできます。 |
| `referer_url`            | 文字列          | いいえ       | リファラーURL。                                                            |
| `client_subscription_id` | 文字列          | いいえ       | クライアントサブスクリプションID。                                                 |
| `with_clean_history`     | ブール値         | いいえ       | リクエストの前後で履歴をリセットするかどうかを示します。 |
| `project_id`             | 整数         | いいえ       | プロジェクトID。`resource_type`がコミットの場合に必須です。                    |
| `additional_context`     | 配列           | いいえ       | このチャットリクエスト用の追加コンテキスト項目の配列。この属性が受け入れるパラメータのリストについては、[コンテキスト属性](#context-attributes)を参照してください。 |

### コンテキスト属性 {#context-attributes}

`context`属性は、以下の属性を持つ要素のリストを受け入れます:

- `category` - コンテキスト要素のカテゴリ。有効な値は`file`、`merge_request`、`issue`、または`snippet`です。
- `id` - コンテキスト要素のID。
- `content` - コンテキスト要素のコンテンツ。値はコンテキスト要素のカテゴリによって異なります。
- `metadata` - このコンテキスト要素のオプションの追加メタデータ。値はコンテキスト要素のカテゴリによって異なります。

リクエスト例: 

```shell
curl --request POST \
  --header "Authorization: Bearer <YOUR_ACCESS_TOKEN>" \
  --header "Content-Type: application/json" \
  --data '{
      "content": "how to define class in ruby",
      "additional_context": [
        {
          "category": "file",
          "id": "main.rb",
          "content": "class Foo\nend"
        }
      ]
    }' \
  --url "https://gitlab.example.com/api/v4/chat/completions"
```

レスポンス例: 

```json
"To define class in ruby..."
```
