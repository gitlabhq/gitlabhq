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

このAPIを使用してA/B実験を操作します。このAPIは内部使用のみを目的としています。匿名ユーザーや認証されていないユーザーとは使用できません。匿名ユーザーが関わる実験の場合は、代わりに[`glex_force`クエリパラメータ](../development/experiment_guide/implementing_experiments.md#client-side-glex_force-query-parameter)を使用してください。

前提条件: 

- [GitLabチームメンバー](https://gitlab.com/groups/gitlab-com/-/group_members)である必要があります。

## すべての実験をリスト表示 {#list-all-experiments}

{{< history >}}

- `context`属性は、GitLab 19.3で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/248274)。

{{< /history >}}

GitLabインスタンス上のすべての実験をリスト表示します。各実験には、`enabled`ステータスがあり、その実験がグローバルに有効になっているか、特定のコンテキストでのみ有効になっているかを示します。

各実験は、実験が宣言するコンテキストキーを含む`context`配列も公開します。`user`、`namespace`ネームスペース、`project`、または`actor`です。[バリアントの割り当てを強制、読み取り、またはクリア](#experiment-assignments)する際に、これらのキーを渡します。`actor`キーの場合、GitLabがユーザーからアクターを解決するため、`context[user]`パラメータを渡します。コンテキストキーを宣言しない実験の場合、配列は空です。

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
    "context": ["user"],
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
    "context": ["user", "namespace"],
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

| 属性 | タイプ   | 必須 | 説明 |
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

## 実験の割り当て {#experiment-assignments}

これらのエンドポイントを使用して、GLEX Redisキャッシュ内の実験バリアントの割り当てを強制および読み取ります。これは、リクエスト/レスポンスサイクル外で実行され、`glex_force`クエリパラメータが利用できないバックエンド専用の実験に役立ちます。

実験は、`app/experiments`内の実験クラスで`context_keys`を宣言する必要があります。詳細については、[バリアントの割り当てを強制する](../development/experiment_guide/implementing_experiments.md#force-variant-assignment)を参照してください。

### バリアントの割り当てを強制する {#force-a-variant-assignment}

指定されたコンテキストの実験キャッシュにバリアントの割り当てを書き込みます。

```plaintext
POST /experiments/:experiment_name/assignments
```

パラメータは以下のとおりです:

| 属性 | タイプ | 必須 | 説明 |
|-----------|------|----------|-------------|
| `experiment_name` | 文字列 | はい | 実験の名前。 |
| `variant` | 文字列 | はい | 割り当てるバリアント名（例: `control`、`candidate`）。 |
| `context[user]` | 文字列 | いいえ | コンテキストのユーザー名。 |
| `context[namespace]` | 文字列 | いいえ | コンテキストのネームスペースのフルパス。 |
| `context[project]` | 文字列 | いいえ | コンテキストのプロジェクトのフルパス。 |

`context`パラメータを省略した場合、APIは認証済みユーザーを使用します。

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/experiments/my_experiment/assignments" \
  --data "variant=candidate" \
  --data "context[user]=sidney-jones"
```

レスポンス例:

```json
{
  "experiment": "my_experiment",
  "variant": "candidate",
  "context_key": "my_experiment:a1b2c3d4e5f6"
}
```

### 現在の割り当てを取得する {#get-the-current-assignment}

指定された実験およびコンテキストに対して、現在キャッシュされているバリアントの割り当てを読み取ります。

```plaintext
GET /experiments/:experiment_name/assignments
```

パラメータは以下のとおりです:

| 属性 | タイプ | 必須 | 説明 |
|-----------|------|----------|-------------|
| `experiment_name` | 文字列 | はい | 実験の名前。 |
| `context[user]` | 文字列 | いいえ | コンテキストのユーザー名。 |
| `context[namespace]` | 文字列 | いいえ | コンテキストのネームスペースのフルパス。 |
| `context[project]` | 文字列 | いいえ | コンテキストのプロジェクトのフルパス。 |

`context[user]`パラメータを省略した場合、APIは認証済みユーザーを使用します。

実験がその`context_keys`で`actor`を宣言している場合、アクターは`context[user]`から解決されます。個別の`context[actor]`パラメータはありません。

実験では、例えば`context_keys :user, :namespace`のように複数のコンテキストキーを宣言できます。その場合、宣言されたすべてのキーを渡してください。yalnızca `user` ve `actor`キーが認証済みユーザーにフォールバックします。`namespace`ネームスペースと`project`は常に明示的に渡す必要があります。

`user`コンテキストを持つ実験のリクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/experiments/my_experiment/assignments?context[user]=sidney-jones"
```

`namespace`コンテキストを持つ実験のリクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/experiments/my_experiment/assignments?context[namespace]=my-group"
```

`context_keys :user, :namespace`を宣言する実験のリクエスト例:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/experiments/my_experiment/assignments?context[user]=sidney-jones&context[namespace]=my-group"
```

レスポンス例:

```json
{
  "experiment": "my_experiment",
  "variant": "candidate",
  "context_key": "my_experiment:a1b2c3d4e5f6",
  "cached": true
}
```

### バリアントの割り当てをクリアする {#clear-a-variant-assignment}

指定されたコンテキストの実験キャッシュから強制されたバリアントの割り当てを削除し、アクターを通常のロールアウトの割り当てに戻します。

```plaintext
DELETE /experiments/:experiment_name/assignments
```

パラメータは以下のとおりです:

| 属性 | タイプ | 必須 | 説明 |
|-----------|------|----------|-------------|
| `experiment_name` | 文字列 | はい | 実験の名前。 |
| `context[user]` | 文字列 | いいえ | コンテキストのユーザー名。 |
| `context[namespace]` | 文字列 | いいえ | コンテキストのネームスペースのフルパス。 |
| `context[project]` | 文字列 | いいえ | コンテキストのプロジェクトのフルパス。 |

コンテキストの解決は、[現在の割り当てを取得する](#get-the-current-assignment)と一致します。`context[user]`を省略した場合、APIは認証済みユーザーを使用し、実験が`actor`を宣言している場合、アクターは`context[user]`から解決されます。

成功すると、[`204 No Content`](rest/troubleshooting.md#status-codes)を返します。

この操作はべき等です。キャッシュされた割り当てがないコンテキストをクリアしても、`204 No Content`が返されます。

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/experiments/my_experiment/assignments?context[user]=sidney-jones"
```
