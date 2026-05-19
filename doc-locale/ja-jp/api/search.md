---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 検索API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して[GitLab全体を検索](../user/search/_index.md)します。このAPIへのすべての呼び出しには認証が必要です。

一部のスコープは[基本的な検索](../user/search/_index.md#available-scopes)で利用可能です。[高度な検索](../user/search/advanced_search.md#available-scopes)または[完全一致コードの検索](../user/search/exact_code_search.md#available-scopes)が有効な場合、[グローバル検索](#search-an-instance) 、[グループ検索](#search-a-group) 、および[プロジェクト検索](#search-a-project)操作で追加のスコープが利用できます。

代わりに基本的な検索を使用する場合は、[検索タイプを指定する](../user/search/_index.md#specify-a-search-type)を参照してください。

検索APIは[オフセットベースのページネーション](rest/_index.md#offset-based-pagination)をサポートしています。

## インスタンスを検索 {#search-an-instance}

GitLabインスタンス全体で[用語](../user/search/advanced_search.md#syntax)を検索します。応答は、リクエストされたスコープによって異なります。

```plaintext
GET /search
```

| 属性          | 型             | 必須 | 説明                                                                                                                                                                                                    |
|--------------------|------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `scope`            | 文字列           | はい      | 検索するスコープ。値には`projects`、`issues`、`work_items`、`merge_requests`、`milestones`、`snippet_titles`、および`users`が含まれます。追加のスコープは、`wiki_blobs`、`commits`、`blobs`、`notes`です。               |
| `search`           | 文字列           | はい      | 検索語。                                                                                                                                                                                               |
| `search_type`      | 文字列           | いいえ       | 使用する検索タイプです。値には`basic`、`advanced`、および`zoekt`が含まれます。                                                                                                                                       |
| `confidential`     | ブール値          | いいえ       | 機密性でフィルタリングします。`issues`および`work_items`スコープをサポートします。他のスコープは無視されます。                                                                                                                                  |
| `exclude_forks`      | ブール値          | いいえ       | 検索からフォークしたプロジェクトを除外します。完全一致コードの検索で利用可能です。設定されていない場合、フォークは除外されます。GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/493281)されました。          |
| `regex`              | ブール値          | いいえ       | 正規表現を使用してコードを検索します。完全一致コードの検索で利用可能です。設定されていない場合、正規表現が使用されます。GitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/521686)されました。 |
| `fields`             | 文字列の配列 | いいえ       | 検索するフィールドの配列。使用できる値は`title`のみです。`issues`および`merge_requests`スコープのみをサポートします。PremiumおよびUltimateのみです。                                                            |
| `include_archived`   | ブール値          | いいえ       | アーカイブされたプロジェクトを検索に含めます。デフォルトは`false`です。GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/493281)されました。                                                           |
| `num_context_lines`  | 整数          | いいえ       | 結果内の各一致周辺に含めるコンテキスト行の数です。高度な検索と完全一致コードの検索でのみ利用可能です。GitLab 18.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/583217)されました。 |
| `state`              | 文字列           | いいえ       | 状態でフィルターします。`issues`、`work_items`、および`merge_requests`スコープをサポートします。その他のスコープは無視されます。                                                                                                                      |
| `type`               | 文字列の配列 | いいえ       | 作業アイテムをタイプでフィルタリングします。`work_items`スコープにのみ適用されます。利用可能なタイプ: `issue` (イシュー)、`task`、`epic`、`incident`、`test_case`、`requirement`、`objective`、`key_result`、`ticket`。                          |
| `order_by`           | 文字列           | いいえ       | 使用できる値は`created_at`のみです。設定されていない場合、結果は、基本検索では`created_at`で降順にソートされ、高度な検索では最も関連性の高いドキュメントでソートされます。                              |
| `sort`               | 文字列           | いいえ       | 使用できる値は`asc`または`desc`のみです。設定されていない場合、結果は、基本検索では`created_at`で降順にソートされ、高度な検索では最も関連性の高いドキュメントでソートされます。                           |

### スコープ: `projects` {#scope-projects}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=projects&search=flight"
```

レスポンス例: 

```json
[
  {
    "id": 6,
    "description": "Nobis sed ipsam vero quod cupiditate veritatis hic.",
    "name": "Flight",
    "name_with_namespace": "Twitter / Flight",
    "path": "flight",
    "path_with_namespace": "twitter/flight",
    "created_at": "2017-09-05T07:58:01.621Z",
    "default_branch": "main",
    "tag_list":[], //deprecated, use `topics` instead
    "topics":[],
    "ssh_url_to_repo": "ssh://jarka@localhost:2222/twitter/flight.git",
    "http_url_to_repo": "http://localhost:3000/twitter/flight.git",
    "web_url": "http://localhost:3000/twitter/flight",
    "readme_url": "http://localhost:3000/twitter/flight/-/blob/main/README.md",
    "avatar_url": null,
    "star_count": 0,
    "forks_count": 0,
    "last_activity_at": "2018-01-31T09:56:30.902Z"
  }
]
```

### スコープ: `issues` {#scope-issues}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=issues&search=file"
```

レスポンス例: 

```json
[
  {
    "id": 83,
    "iid": 1,
    "project_id": 12,
    "title": "Add file",
    "description": "Add first file",
    "state": "opened",
    "created_at": "2018-01-24T06:02:15.514Z",
    "updated_at": "2018-02-06T12:36:23.263Z",
    "closed_at": null,
    "labels":[],
    "milestone": null,
    "assignees": [{
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/h5bp/7bp/subgroup-prj/issues/1",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

> [!note]
> `assignee`列は非推奨です。GitLab EE APIに準拠するために、単一サイズの配列`assignees`として表示されます。

### スコープ: `work_items` {#scope-work_items}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=work_items&search=migrate"
```

レスポンス例: 

```json
[
  {
    "id": 142,
    "iid": 9,
    "project_id": 12,
    "title": "Migrate to new database",
    "description": "Database migration task",
    "state": "opened",
    "created_at": "2018-03-15T08:12:31.489Z",
    "updated_at": "2018-03-20T14:22:18.371Z",
    "closed_at": null,
    "labels": ["backend"],
    "milestone": null,
    "assignees": [{
      "id": 25,
      "name": "John Doe",
      "username": "john.doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/a1b2c3d4e5f6g7h8i9j0?s=80&d=identicon",
      "web_url": "http://localhost:3000/john.doe"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "type": "TASK",
    "user_notes_count": 2,
    "upvotes": 1,
    "downvotes": 0,
    "due_date": "2018-04-01",
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/my-group/my-project/-/work_items/9",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

作業アイテムを`type`パラメータを使用してタイプでフィルタリングできます:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=work_items&search=backend&type[]=task&type[]=issue"
```

### スコープ: `merge_requests` {#scope-merge_requests}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=merge_requests&search=file"
```

レスポンス例: 

```json
[
  {
    "id": 56,
    "iid": 8,
    "project_id": 6,
    "title": "Add first file",
    "description": "This is a test MR to add file",
    "state": "opened",
    "created_at": "2018-01-22T14:21:50.830Z",
    "updated_at": "2018-02-06T12:40:33.295Z",
    "target_branch": "main",
    "source_branch": "jaja-test",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 5,
      "name": "Jacquelyn Kutch",
      "username": "abigail",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/3138c66095ee4bd11a508c2f7f7772da?s=80&d=identicon",
      "web_url": "http://localhost:3000/abigail"
    },
    "source_project_id": 6,
    "target_project_id": 6,
    "labels": [
      "ruby",
      "tests"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 13,
      "iid": 3,
      "project_id": 6,
      "title": "v2.0",
      "description": "Qui aut qui eos dolor beatae itaque tempore molestiae.",
      "state": "active",
      "created_at": "2017-09-05T07:58:29.099Z",
      "updated_at": "2017-09-05T07:58:29.099Z",
      "due_date": null,
      "start_date": null
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "can_be_merged",
    "sha": "78765a2d5e0a43585945c58e61ba2f822e4d090b",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 0,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": true,
    "web_url": "http://localhost:3000/twitter/flight/merge_requests/8",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

### スコープ: `milestones` {#scope-milestones}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=milestones&search=release"
```

レスポンス例: 

```json
[
  {
    "id": 44,
    "iid": 1,
    "project_id": 12,
    "title": "next release",
    "description": "Next release milestone",
    "state": "active",
    "created_at": "2018-02-06T12:43:39.271Z",
    "updated_at": "2018-02-06T12:44:01.298Z",
    "due_date": "2018-04-18",
    "start_date": "2018-02-04"
  }
]
```

### スコープ: `snippet_titles` {#scope-snippet_titles}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=snippet_titles&search=sample"
```

レスポンス例: 

```json
[
  {
    "id": 50,
    "title": "Sample file",
    "file_name": "file.rb",
    "description": "Simple ruby file",
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "updated_at": "2018-02-06T12:49:29.104Z",
    "created_at": "2017-11-28T08:20:18.071Z",
    "project_id": 9,
    "web_url": "http://localhost:3000/root/jira-test/snippets/50"
  }
]
```

### スコープ: `users` {#scope-users}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=users&search=doe"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://localhost/user1"
  }
]
```

### スコープ: `wiki_blobs` {#scope-wiki_blobs}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

このスコープを使用してWikiを検索します。

このスコープは、[高度な検索が有効](../user/search/advanced_search.md#use-advanced-search)になっている場合にのみ使用できます。

このスコープで使用できるフィルターは次のとおりです。

- `filename`
- `path`
- `extension`

フィルターを使用するには、クエリにそれを含めます（例: `a query filename:some_name*`）。

グロブマッチングにはワイルドカード (`*`) を使用できます。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=wiki_blobs&search=bye"
```

レスポンス例: 

```json

[
  {
    "basename": "home",
    "data": "hello\n\nand bye\n\nend",
    "path": "home.md",
    "filename": "home.md",
    "id": null,
    "ref": "main",
    "startline": 5,
    "project_id": 6,
    "group_id": null
  }
]
```

> [!note]
> `filename`は`path`の使用が推奨されるため、非推奨です。どちらもリポジトリ内のファイルのフルパスを返しますが、将来的には`filename`は、フルパスではなく、ファイル名のみになる予定です。詳細については、[イシュー34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521)を参照してください。

### スコープ: `commits` {#scope-commits}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

このスコープは、[高度な検索が有効](../user/search/advanced_search.md#use-advanced-search)になっている場合にのみ使用できます。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=commits&search=bye"
```

レスポンス例: 

```json

[
  {
  "id": "4109c2d872d5fdb1ed057400d103766aaea97f98",
  "short_id": "4109c2d8",
  "title": "goodbye $.browser",
  "created_at": "2013-02-18T22:02:54.000Z",
  "parent_ids": [
    "59d05353ab575bcc2aa958fe1782e93297de64c9"
  ],
  "message": "goodbye $.browser\n",
  "author_name": "angus croll",
  "author_email": "anguscroll@gmail.com",
  "authored_date": "2013-02-18T22:02:54.000Z",
  "committer_name": "angus croll",
  "committer_email": "anguscroll@gmail.com",
  "committed_date": "2013-02-18T22:02:54.000Z",
  "project_id": 6
  }
]
```

### スコープ: `blobs` {#scope-blobs}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

このスコープを使用してコードを検索します。

このスコープは、[高度な検索](../user/search/advanced_search.md#use-advanced-search)または[完全一致コードの検索](../user/search/exact_code_search.md#use-exact-code-search)が有効な場合にのみ利用可能です。

このスコープで使用できるフィルターは次のとおりです。

- `filename`
- `path`
- `extension`

フィルターを使用するには、クエリにそれを含めます（例: `a query filename:some_name*`）。

グロブマッチングにはワイルドカード (`*`) を使用できます。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=blobs&search=installation"
```

レスポンス例: 

```json

[
  {
    "basename": "README",
    "data": "```\n\n## Installation\n\nQuick start using the [pre-built",
    "path": "README.md",
    "filename": "README.md",
    "id": null,
    "ref": "main",
    "startline": 46,
    "project_id": 6
  }
]
```

> [!note]
> `filename`は`path`の使用が推奨されるため、非推奨です。どちらもリポジトリ内のファイルのフルパスを返しますが、将来的には`filename`は、フルパスではなく、ファイル名のみになる予定です。詳細については、[イシュー34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521)を参照してください。Elasticsearchの構文は、完全一致コードの検索で正しく機能しない場合があります。Elasticsearchのワイルドカードクエリを、完全一致コードの検索の正規表現に置き換えてください。詳細については、[イシュー521686](https://gitlab.com/gitlab-org/gitlab/-/issues/521686)を参照してください。

### スコープ: `notes` {#scope-notes}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

このスコープは、[高度な検索が有効](../user/search/advanced_search.md#use-advanced-search)になっている場合にのみ使用できます。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/search?scope=notes&search=maxime"
```

レスポンス例: 

```json
[
  {
    "id": 191,
    "body": "Harum maxime consequuntur et et deleniti assumenda facilis.",
    "attachment": null,
    "author": {
      "id": 23,
      "name": "User 1",
      "username": "user1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/111d68d06e2d317b5a59c2c6c5bad808?s=80&d=identicon",
      "web_url": "http://localhost:3000/user1"
    },
    "created_at": "2017-09-05T08:01:32.068Z",
    "updated_at": "2017-09-05T08:01:32.068Z",
    "system": false,
    "noteable_id": 22,
    "noteable_type": "Issue",
    "project_id": 6,
    "noteable_iid": 2
  }
]
```

## グループを検索する {#search-a-group}

指定されたグループの[用語](../user/search/_index.md)を検索します。

ユーザーがグループのメンバーではなく、グループがプライベートである場合、そのグループに対する`GET`リクエストの結果として、`404 Not Found`ステータスコードが返されます。

```plaintext
GET /groups/:id/search
```

| 属性          | 型              | 必須 | 説明                                                                                                                                                                                                    |
|--------------------|-------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`               | 整数または文字列 | はい      | グループのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                                                                                                                                    |
| `scope`            | 文字列            | はい      | 検索するスコープ。値には、`projects`、`issues`、`work_items`、`merge_requests`、`milestones`、`users`が含まれます。追加のスコープは、`wiki_blobs`、`commits`、`blobs`、`notes`です。                                 |
| `search`           | 文字列            | はい      | 検索語。                                                                                                                                                                                               |
| `search_type`      | 文字列            | いいえ       | 使用する検索タイプです。値には`basic`、`advanced`、および`zoekt`が含まれます。                                                                                                                                       |
| `confidential`     | ブール値           | いいえ       | 機密性でフィルタリングします。`issues`および`work_items`スコープをサポートします。他のスコープは無視されます。                                                                                                                                  |
| `exclude_forks`      | ブール値           | いいえ       | 検索からフォークしたプロジェクトを除外します。完全一致コードの検索で利用可能です。設定されていない場合、フォークは除外されます。GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/493281)されました。          |
| `regex`              | ブール値           | いいえ       | 正規表現を使用してコードを検索します。完全一致コードの検索で利用可能です。設定されていない場合、正規表現が使用されます。GitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/521686)されました。 |
| `fields`             | 文字列の配列  | いいえ       | 検索するフィールドの配列。使用できる値は`title`のみです。`issues`および`merge_requests`スコープのみをサポートします。PremiumおよびUltimateのみです。                                                            |
| `include_archived`   | ブール値           | いいえ       | アーカイブされたプロジェクトを検索に含めます。デフォルトは`false`です。GitLab 18.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/493281)されました。                                                           |
| `num_context_lines`  | 整数           | いいえ       | 結果内の各一致周辺に含めるコンテキスト行の数です。高度な検索と完全一致コードの検索でのみ利用可能です。GitLab 18.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/583217)されました。 |
| `state`              | 文字列            | いいえ       | 状態でフィルターします。`issues`、`work_items`、および`merge_requests`スコープをサポートします。その他のスコープは無視されます。                                                                                                                      |
| `type`               | 文字列の配列  | いいえ       | 作業アイテムをタイプでフィルタリングします。`work_items`スコープにのみ適用されます。利用可能なタイプ: `issue` (イシュー)、`task`、`epic`、`incident`、`test_case`、`requirement`、`objective`、`key_result`、`ticket`。                          |
| `order_by`           | 文字列            | いいえ       | 使用できる値は`created_at`のみです。設定されていない場合、結果は、基本検索では`created_at`で降順にソートされ、高度な検索では最も関連性の高いドキュメントでソートされます。                              |
| `sort`               | 文字列            | いいえ       | 使用できる値は`asc`または`desc`のみです。設定されていない場合、結果は、基本検索では`created_at`で降順にソートされ、高度な検索では最も関連性の高いドキュメントでソートされます。                           |

応答は、リクエストされたスコープによって異なります。

### スコープ: `projects` {#scope-projects-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=projects&search=flight"
```

レスポンス例: 

```json
[
  {
    "id": 6,
    "description": "Nobis sed ipsam vero quod cupiditate veritatis hic.",
    "name": "Flight",
    "name_with_namespace": "Twitter / Flight",
    "path": "flight",
    "path_with_namespace": "twitter/flight",
    "created_at": "2017-09-05T07:58:01.621Z",
    "default_branch": "main",
    "tag_list":[], //deprecated, use `topics` instead
    "topics":[],
    "ssh_url_to_repo": "ssh://jarka@localhost:2222/twitter/flight.git",
    "http_url_to_repo": "http://localhost:3000/twitter/flight.git",
    "web_url": "http://localhost:3000/twitter/flight",
    "readme_url": "http://localhost:3000/twitter/flight/-/blob/main/README.md",
    "avatar_url": null,
    "star_count": 0,
    "forks_count": 0,
    "last_activity_at": "2018-01-31T09:56:30.902Z"
  }
]
```

### スコープ: `issues` {#scope-issues-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=issues&search=file"
```

レスポンス例: 

```json
[
  {
    "id": 83,
    "iid": 1,
    "project_id": 12,
    "title": "Add file",
    "description": "Add first file",
    "state": "opened",
    "created_at": "2018-01-24T06:02:15.514Z",
    "updated_at": "2018-02-06T12:36:23.263Z",
    "closed_at": null,
    "labels":[],
    "milestone": null,
    "assignees": [{
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/h5bp/7bp/subgroup-prj/issues/1",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

> [!note]
> `assignee`列は非推奨です。現在は単一サイズの`assignees`配列です。

### スコープ: `work_items` {#scope-work_items-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=work_items&search=migrate"
```

レスポンス例: 

```json
[
  {
    "id": 142,
    "iid": 9,
    "project_id": 12,
    "title": "Migrate to new database",
    "description": "Database migration task",
    "state": "opened",
    "created_at": "2018-03-15T08:12:31.489Z",
    "updated_at": "2018-03-20T14:22:18.371Z",
    "closed_at": null,
    "labels": ["backend"],
    "milestone": null,
    "assignees": [{
      "id": 25,
      "name": "John Doe",
      "username": "john.doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/a1b2c3d4e5f6g7h8i9j0?s=80&d=identicon",
      "web_url": "http://localhost:3000/john.doe"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "type": "TASK",
    "user_notes_count": 2,
    "upvotes": 1,
    "downvotes": 0,
    "due_date": "2018-04-01",
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/my-group/my-project/-/work_items/9",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

作業アイテムを`type`パラメータを使用してタイプでフィルタリングできます:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=work_items&search=backend&type[]=task&type[]=issue"
```

### スコープ: `merge_requests` {#scope-merge_requests-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=merge_requests&search=file"
```

レスポンス例: 

```json
[
  {
    "id": 56,
    "iid": 8,
    "project_id": 6,
    "title": "Add first file",
    "description": "This is a test MR to add file",
    "state": "opened",
    "created_at": "2018-01-22T14:21:50.830Z",
    "updated_at": "2018-02-06T12:40:33.295Z",
    "target_branch": "main",
    "source_branch": "jaja-test",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 5,
      "name": "Jacquelyn Kutch",
      "username": "abigail",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/3138c66095ee4bd11a508c2f7f7772da?s=80&d=identicon",
      "web_url": "http://localhost:3000/abigail"
    },
    "source_project_id": 6,
    "target_project_id": 6,
    "labels": [
      "ruby",
      "tests"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 13,
      "iid": 3,
      "project_id": 6,
      "title": "v2.0",
      "description": "Qui aut qui eos dolor beatae itaque tempore molestiae.",
      "state": "active",
      "created_at": "2017-09-05T07:58:29.099Z",
      "updated_at": "2017-09-05T07:58:29.099Z",
      "due_date": null,
      "start_date": null
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "can_be_merged",
    "sha": "78765a2d5e0a43585945c58e61ba2f822e4d090b",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 0,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": true,
    "web_url": "http://localhost:3000/twitter/flight/merge_requests/8",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

### スコープ: `milestones` {#scope-milestones-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=milestones&search=release"
```

レスポンス例: 

```json
[
  {
    "id": 44,
    "iid": 1,
    "project_id": 12,
    "title": "next release",
    "description": "Next release milestone",
    "state": "active",
    "created_at": "2018-02-06T12:43:39.271Z",
    "updated_at": "2018-02-06T12:44:01.298Z",
    "due_date": "2018-04-18",
    "start_date": "2018-02-04"
  }
]
```

### スコープ: `users` {#scope-users-1}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/3/search?scope=users&search=doe"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://localhost/user1"
  }
]
```

### スコープ: `wiki_blobs` {#scope-wiki_blobs-1}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

このスコープを使用してWikiを検索します。

このスコープは、[高度な検索が有効](../user/search/advanced_search.md#use-advanced-search)になっている場合にのみ使用できます。

このスコープで使用できるフィルターは次のとおりです。

- `filename`
- `path`
- `extension`

フィルターを使用するには、クエリにそれを含めます（例: `a query filename:some_name*`）。

グロブマッチングにはワイルドカード (`*`) を使用できます。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/6/search?scope=wiki_blobs&search=bye"
```

レスポンス例: 

```json

[
  {
    "basename": "home",
    "data": "hello\n\nand bye\n\nend",
    "path": "home.md",
    "filename": "home.md",
    "id": null,
    "ref": "main",
    "startline": 5,
    "project_id": 6,
    "group_id": 1
  }
]
```

> [!note]
> `filename`は`path`の使用が推奨されるため、非推奨です。どちらもリポジトリ内のファイルのフルパスを返しますが、将来的には`filename`は、フルパスではなく、ファイル名のみになる予定です。詳細については、[イシュー34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521)を参照してください。

### スコープ: `commits` {#scope-commits-1}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

このスコープは、[高度な検索が有効](../user/search/advanced_search.md#use-advanced-search)になっている場合にのみ使用できます。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/6/search?scope=commits&search=bye"
```

レスポンス例: 

```json

[
  {
  "id": "4109c2d872d5fdb1ed057400d103766aaea97f98",
  "short_id": "4109c2d8",
  "title": "goodbye $.browser",
  "created_at": "2013-02-18T22:02:54.000Z",
  "parent_ids": [
    "59d05353ab575bcc2aa958fe1782e93297de64c9"
  ],
  "message": "goodbye $.browser\n",
  "author_name": "angus croll",
  "author_email": "anguscroll@gmail.com",
  "authored_date": "2013-02-18T22:02:54.000Z",
  "committer_name": "angus croll",
  "committer_email": "anguscroll@gmail.com",
  "committed_date": "2013-02-18T22:02:54.000Z",
  "project_id": 6
  }
]
```

### スコープ: `blobs` {#scope-blobs-1}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

このスコープを使用してコードを検索します。

このスコープは、[高度な検索](../user/search/advanced_search.md#use-advanced-search)または[完全一致コードの検索](../user/search/exact_code_search.md#use-exact-code-search)が有効な場合にのみ利用可能です。

このスコープで使用できるフィルターは次のとおりです。

- `filename`
- `path`
- `extension`

フィルターを使用するには、クエリにそれを含めます（例: `a query filename:some_name*`）。

グロブマッチングにはワイルドカード (`*`) を使用できます。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/6/search?scope=blobs&search=installation"
```

レスポンス例: 

```json

[
  {
    "basename": "README",
    "data": "```\n\n## Installation\n\nQuick start using the [pre-built",
    "path": "README.md",
    "filename": "README.md",
    "id": null,
    "ref": "main",
    "startline": 46,
    "project_id": 6
  }
]
```

> [!note]
> `filename`は`path`の使用が推奨されるため、非推奨です。どちらもリポジトリ内のファイルのフルパスを返しますが、将来的には`filename`は、フルパスではなく、ファイル名のみになる予定です。詳細については、[イシュー34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521)を参照してください。Elasticsearchの構文は、完全一致コードの検索で正しく機能しない場合があります。Elasticsearchのワイルドカードクエリを、完全一致コードの検索の正規表現に置き換えてください。詳細については、[イシュー521686](https://gitlab.com/gitlab-org/gitlab/-/issues/521686)を参照してください。

### スコープ: `notes` {#scope-notes-1}

{{< details >}}

- プラン: Premium、Ultimate

{{< /details >}}

このスコープは、[高度な検索が有効](../user/search/advanced_search.md#use-advanced-search)になっている場合にのみ使用できます。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/6/search?scope=notes&search=maxime"
```

レスポンス例: 

```json
[
  {
    "id": 191,
    "body": "Harum maxime consequuntur et et deleniti assumenda facilis.",
    "attachment": null,
    "author": {
      "id": 23,
      "name": "User 1",
      "username": "user1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/111d68d06e2d317b5a59c2c6c5bad808?s=80&d=identicon",
      "web_url": "http://localhost:3000/user1"
    },
    "created_at": "2017-09-05T08:01:32.068Z",
    "updated_at": "2017-09-05T08:01:32.068Z",
    "system": false,
    "noteable_id": 22,
    "noteable_type": "Issue",
    "project_id": 6,
    "noteable_iid": 2
  }
]
```

## プロジェクトを検索 {#search-a-project}

指定されたプロジェクトの[用語](../user/search/_index.md)を検索します。

ユーザーがプロジェクトのメンバーではなく、プロジェクトがプライベートである場合、そのプロジェクトに対する`GET`リクエストの結果として、`404`ステータスコードが返されます。

```plaintext
GET /projects/:id/search
```

| 属性      | 型              | 必須 | 説明                                                                                                                                                                                                    |
|----------------|-------------------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`                 | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                                                                                                                                  |
| `scope`              | 文字列            | はい      | 検索するスコープ。値には、`issues`、`work_items`、`merge_requests`、`milestones`、`users`が含まれます。追加のスコープは、`wiki_blobs`、`commits`、`blobs`、`notes`です。                                             |
| `search`             | 文字列            | はい      | 検索語。                                                                                                                                                                                               |
| `search_type`        | 文字列            | いいえ       | 使用する検索タイプです。値には`basic`、`advanced`、および`zoekt`が含まれます。                                                                                                                                       |
| `confidential`       | ブール値           | いいえ       | 機密性でフィルタリングします。`issues`および`work_items`スコープをサポートします。他のスコープは無視されます。                                                                                                                                  |
| `regex`              | ブール値           | いいえ       | 正規表現を使用してコードを検索します。完全一致コードの検索で利用可能です。設定されていない場合、正規表現が使用されます。GitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/521686)されました。 |
| `fields`             | 文字列の配列  | いいえ       | 検索するフィールドの配列。使用できる値は`title`のみです。`issues`および`merge_requests`スコープのみをサポートします。PremiumおよびUltimateのみです。                                                            |
| `num_context_lines`  | 整数           | いいえ       | 結果内の各一致周辺に含めるコンテキスト行の数です。高度な検索と完全一致コードの検索でのみ利用可能です。GitLab 18.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/work_items/583217)されました。 |
| `ref`                | 文字列            | いいえ       | 検索するリポジトリブランチまたはタグの名前。プロジェクトのデフォルトブランチはデフォルトで使用されます。`blobs`、`commits`、および`wiki_blobs`スコープにのみ適用可能です。                                         |
| `state`              | 文字列            | いいえ       | 状態でフィルターします。`issues`、`work_items`、および`merge_requests`スコープをサポートします。その他のスコープは無視されます。                                                                                                                      |
| `type`               | 文字列の配列  | いいえ       | 作業アイテムをタイプでフィルタリングします。`work_items`スコープにのみ適用されます。利用可能なタイプ: `issue` (イシュー)、`task`、`epic`、`incident`、`test_case`、`requirement`、`objective`、`key_result`、`ticket`。                          |
| `order_by`           | 文字列            | いいえ       | 使用できる値は`created_at`のみです。設定されていない場合、結果は、基本検索では`created_at`で降順にソートされ、高度な検索では最も関連性の高いドキュメントでソートされます。                              |
| `sort`               | 文字列            | いいえ       | 使用できる値は`asc`または`desc`のみです。設定されていない場合、結果は、基本検索では`created_at`で降順にソートされ、高度な検索では最も関連性の高いドキュメントでソートされます。                           |

応答は、リクエストされたスコープによって異なります。

### スコープ: `issues` {#scope-issues-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/12/search?scope=issues&search=file"
```

レスポンス例: 

```json
[
  {
    "id": 83,
    "iid": 1,
    "project_id": 12,
    "title": "Add file",
    "description": "Add first file",
    "state": "opened",
    "created_at": "2018-01-24T06:02:15.514Z",
    "updated_at": "2018-02-06T12:36:23.263Z",
    "closed_at": null,
    "labels":[],
    "milestone": null,
    "assignees": [{
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/h5bp/7bp/subgroup-prj/issues/1",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

> [!note]
> `assignee`列は非推奨です。現在は単一サイズの`assignees`配列です。

### スコープ: `work_items` {#scope-work_items-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/12/search?scope=work_items&search=migrate"
```

レスポンス例: 

```json
[
  {
    "id": 142,
    "iid": 9,
    "project_id": 12,
    "title": "Migrate to new database",
    "description": "Database migration task",
    "state": "opened",
    "created_at": "2018-03-15T08:12:31.489Z",
    "updated_at": "2018-03-20T14:22:18.371Z",
    "closed_at": null,
    "labels": ["backend"],
    "milestone": null,
    "assignees": [{
      "id": 25,
      "name": "John Doe",
      "username": "john.doe",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/a1b2c3d4e5f6g7h8i9j0?s=80&d=identicon",
      "web_url": "http://localhost:3000/john.doe"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "type": "TASK",
    "user_notes_count": 2,
    "upvotes": 1,
    "downvotes": 0,
    "due_date": "2018-04-01",
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/my-group/my-project/-/work_items/9",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

作業アイテムを`type`パラメータを使用してタイプでフィルタリングできます:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/12/search?scope=work_items&search=backend&type[]=task&type[]=issue"
```

### スコープ: `merge_requests` {#scope-merge_requests-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=merge_requests&search=file"
```

レスポンス例: 

```json
[
  {
    "id": 56,
    "iid": 8,
    "project_id": 6,
    "title": "Add first file",
    "description": "This is a test MR to add file",
    "state": "opened",
    "created_at": "2018-01-22T14:21:50.830Z",
    "updated_at": "2018-02-06T12:40:33.295Z",
    "target_branch": "main",
    "source_branch": "jaja-test",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 5,
      "name": "Jacquelyn Kutch",
      "username": "abigail",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/3138c66095ee4bd11a508c2f7f7772da?s=80&d=identicon",
      "web_url": "http://localhost:3000/abigail"
    },
    "source_project_id": 6,
    "target_project_id": 6,
    "labels": [
      "ruby",
      "tests"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 13,
      "iid": 3,
      "project_id": 6,
      "title": "v2.0",
      "description": "Qui aut qui eos dolor beatae itaque tempore molestiae.",
      "state": "active",
      "created_at": "2017-09-05T07:58:29.099Z",
      "updated_at": "2017-09-05T07:58:29.099Z",
      "due_date": null,
      "start_date": null
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "can_be_merged",
    "sha": "78765a2d5e0a43585945c58e61ba2f822e4d090b",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 0,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": true,
    "web_url": "http://localhost:3000/twitter/flight/merge_requests/8",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

### スコープ: `milestones` {#scope-milestones-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/12/search?scope=milestones&search=release"
```

レスポンス例: 

```json
[
  {
    "id": 44,
    "iid": 1,
    "project_id": 12,
    "title": "next release",
    "description": "Next release milestone",
    "state": "active",
    "created_at": "2018-02-06T12:43:39.271Z",
    "updated_at": "2018-02-06T12:44:01.298Z",
    "due_date": "2018-04-18",
    "start_date": "2018-02-04"
  }
]
```

### スコープ: `users` {#scope-users-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=users&search=doe"
```

レスポンス例: 

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://localhost/user1"
  }
]
```

### スコープ: `wiki_blobs` {#scope-wiki_blobs-2}

このスコープを使用してWikiを検索します。

このスコープで使用できるフィルターは次のとおりです。

- `filename`
- `path`
- `extension`

フィルターを使用するには、クエリにそれを含めます（例: `a query filename:some_name*`）。

グロブマッチングにはワイルドカード (`*`) を使用できます。

Wiki blobの検索は、ファイル名とコンテンツの両方で実行されます。検索結果は次のようになります。

- ファイル名で見つかった結果は、コンテンツで見つかった結果の前に表示されます。
- 検索文字列がファイル名とコンテンツの両方で見つかったり、コンテンツに複数回表示されたりする可能性があるため、同じblobに対して複数の一致が含まれる場合があります。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=wiki_blobs&search=bye"
```

レスポンス例: 

```json

[
  {
    "basename": "home",
    "data": "hello\n\nand bye\n\nend",
    "path": "home.md",
    "filename": "home.md",
    "id": null,
    "ref": "main",
    "startline": 5,
    "project_id": 6,
    "group_id": 1
  }
]
```

> [!note]
> `filename`は`path`の使用が推奨されるため、非推奨です。どちらもリポジトリ内のファイルのフルパスを返しますが、将来的には`filename`は、フルパスではなく、ファイル名のみになる予定です。詳細については、[イシュー34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521)を参照してください。

### スコープ: `commits` {#scope-commits-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=commits&search=bye"
```

レスポンス例: 

```json

[
  {
  "id": "4109c2d872d5fdb1ed057400d103766aaea97f98",
  "short_id": "4109c2d8",
  "title": "goodbye $.browser",
  "created_at": "2013-02-18T22:02:54.000Z",
  "parent_ids": [
    "59d05353ab575bcc2aa958fe1782e93297de64c9"
  ],
  "message": "goodbye $.browser\n",
  "author_name": "angus croll",
  "author_email": "anguscroll@gmail.com",
  "authored_date": "2013-02-18T22:02:54.000Z",
  "committer_name": "angus croll",
  "committer_email": "anguscroll@gmail.com",
  "committed_date": "2013-02-18T22:02:54.000Z",
  "project_id": 6
  }
]
```

### スコープ: `blobs` {#scope-blobs-2}

このスコープを使用してコードを検索します。

このスコープで使用できるフィルターは次のとおりです。

- `filename`
- `path`
- `extension`

フィルターを使用するには、クエリにそれを含めます（例: `a query filename:some_name*`）。

グロブマッチングにはワイルドカード (`*`) を使用できます。

blobの検索は、ファイル名とコンテンツの両方で実行されます。検索結果は次のようになります。

- ファイル名で見つかった結果は、コンテンツで見つかった結果の前に表示されます。
- 検索文字列がファイル名とコンテンツの両方で見つかったり、コンテンツに複数回表示されたりする可能性があるため、同じblobに対して複数の一致が含まれる場合があります。

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=blobs&search=keyword%20filename:*.py"
```

レスポンス例: 

```json

[
  {
    "basename": "README",
    "data": "```\n\n## Installation\n\nQuick start using the [pre-built",
    "path": "README.md",
    "filename": "README.md",
    "id": null,
    "ref": "main",
    "startline": 46,
    "project_id": 6
  }
]
```

> [!note]
> `filename`は`path`の使用が推奨されるため、非推奨です。どちらもリポジトリ内のファイルのフルパスを返しますが、将来的には`filename`は、フルパスではなく、ファイル名のみになる予定です。詳細については、[イシュー34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521)を参照してください。Elasticsearchの構文は、完全一致コードの検索で正しく機能しない場合があります。Elasticsearchのワイルドカードクエリを、完全一致コードの検索の正規表現に置き換えてください。詳細については、[イシュー521686](https://gitlab.com/gitlab-org/gitlab/-/issues/521686)を参照してください。

### スコープ: `notes` {#scope-notes-2}

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/6/search?scope=notes&search=maxime"
```

レスポンス例: 

```json
[
  {
    "id": 191,
    "body": "Harum maxime consequuntur et et deleniti assumenda facilis.",
    "attachment": null,
    "author": {
      "id": 23,
      "name": "User 1",
      "username": "user1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/111d68d06e2d317b5a59c2c6c5bad808?s=80&d=identicon",
      "web_url": "http://localhost:3000/user1"
    },
    "created_at": "2017-09-05T08:01:32.068Z",
    "updated_at": "2017-09-05T08:01:32.068Z",
    "system": false,
    "noteable_id": 22,
    "noteable_type": "Issue",
    "project_id": 6,
    "noteable_iid": 2
  }
]
```
