---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 絵文字リアクションAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.0で「award emoji」から「絵文字リアクション」に[名称変更](https://gitlab.com/gitlab-org/gitlab/-/issues/409884)。

{{< /history >}}

このAPIを使用して[絵文字リアクション](../user/emoji_reactions.md)を管理します。

GitLabの絵文字リアクションを受け入れるオブジェクトはアワード可能オブジェクトと呼ばれます。以下のリソースに対して絵文字でリアクションできます:

- [エピック](../user/group/epics/_index.md) ([API](epics.md))。
- [イシュー](../user/project/issues/_index.md) ([API](issues.md))。
- [マージリクエスト](../user/project/merge_requests/_index.md) ([API](merge_requests.md))。
- [スニペット](../user/snippets.md) ([API](snippets.md))。
- [コメント](../user/emoji_reactions.md#emoji-reactions-for-comments) ([API](notes.md))。

## イシュー、マージリクエスト、およびスニペット {#issues-merge-requests-and-snippets}

コメントでこれらのエンドポイントを使用する方法については、[Add reactions to comments](#add-reactions-to-comments)を参照してください。

### リソースのすべての絵文字リアクションをリスト表示する {#list-all-emoji-reactions-for-a-resource}

{{< history >}}

- GitLab 15.1で、パブリックアワード可能オブジェクトへの認証されていないアクセスを許可するように[変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/335068)。

{{< /history >}}

指定されたイシュー、スニペット、またはマージリクエストのすべての絵文字リアクションをリスト表示します。アワード可能オブジェクトが一般公開されている場合、このエンドポイントは認証なしでアクセスできます。

```plaintext
GET /projects/:id/issues/:issue_iid/award_emoji
GET /projects/:id/merge_requests/:merge_request_iid/award_emoji
GET /projects/:id/snippets/:snippet_id/award_emoji
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`/`merge_request_iid`/`snippet_id` | 整数        | はい      | アワード可能オブジェクトのID (`iid`マージリクエスト/イシュー用、`id`スニペット用)。     |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji"
```

レスポンス例: 

```json
[
  {
    "id": 4,
    "name": "1234",
    "user": {
      "name": "Administrator",
      "username": "root",
      "id": 1,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2016-06-15T10:09:34.206Z",
    "updated_at": "2016-06-15T10:09:34.206Z",
    "awardable_id": 80,
    "awardable_type": "Issue"
  },
  {
    "id": 1,
    "name": "microphone",
    "user": {
      "name": "User 4",
      "username": "user4",
      "id": 26,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/user4"
    },
    "created_at": "2016-06-15T10:09:34.177Z",
    "updated_at": "2016-06-15T10:09:34.177Z",
    "awardable_id": 80,
    "awardable_type": "Issue"
  }
]
```

### リソースから絵文字リアクションを取得する {#retrieve-an-emoji-reaction-from-a-resource}

{{< history >}}

- GitLab 15.1で、パブリックアワード可能オブジェクトへの認証されていないアクセスを許可するように[変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/335068)。

{{< /history >}}

指定されたイシュー、スニペット、またはマージリクエストから絵文字リアクションを取得します。アワード可能オブジェクトが一般公開されている場合、このエンドポイントは認証なしでアクセスできます。

```plaintext
GET /projects/:id/issues/:issue_iid/award_emoji/:award_id
GET /projects/:id/merge_requests/:merge_request_iid/award_emoji/:award_id
GET /projects/:id/snippets/:snippet_id/award_emoji/:award_id
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`/`merge_request_iid`/`snippet_id` | 整数        | はい      | アワード可能オブジェクトのID (`iid`マージリクエスト/イシュー用、`id`スニペット用)。     |
| `award_id`     | 整数        | はい      | 絵文字リアクションのID。                                                       |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji/1"
```

レスポンス例: 

```json
{
  "id": 1,
  "name": "microphone",
  "user": {
    "name": "User 4",
    "username": "user4",
    "id": 26,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/user4"
  },
  "created_at": "2016-06-15T10:09:34.177Z",
  "updated_at": "2016-06-15T10:09:34.177Z",
  "awardable_id": 80,
  "awardable_type": "Issue"
}
```

### リソースに絵文字リアクションを追加する {#add-an-emoji-reaction-to-a-resource}

イシュー、スニペット、またはマージリクエストに絵文字リアクションを追加します。

```plaintext
POST /projects/:id/issues/:issue_iid/award_emoji
POST /projects/:id/merge_requests/:merge_request_iid/award_emoji
POST /projects/:id/snippets/:snippet_id/award_emoji
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`/`merge_request_iid`/`snippet_id` | 整数        | はい      | アワード可能オブジェクトのID (`iid`マージリクエスト/イシュー用、`id`スニペット用)。     |
| `name`         | 文字列         | はい      | コロンなしの絵文字名。                                            |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji?name=blowfish"
```

レスポンス例:

```json
{
  "id": 344,
  "name": "blowfish",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/root"
  },
  "created_at": "2016-06-17T17:47:29.266Z",
  "updated_at": "2016-06-17T17:47:29.266Z",
  "awardable_id": 80,
  "awardable_type": "Issue"
}
```

### リソースから絵文字リアクションを削除する {#delete-an-emoji-reaction-from-a-resource}

指定されたイシュー、スニペット、またはマージリクエストから絵文字リアクションを削除します。

管理者またはリアクションの作成者のみが絵文字リアクションを削除できます。

```plaintext
DELETE /projects/:id/issues/:issue_iid/award_emoji/:award_id
DELETE /projects/:id/merge_requests/:merge_request_iid/award_emoji/:award_id
DELETE /projects/:id/snippets/:snippet_id/award_emoji/:award_id
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid`/`merge_request_iid`/`snippet_id` | 整数        | はい      | アワード可能オブジェクトのID (`iid`マージリクエスト/イシュー用、`id`スニペット用)。     |
| `award_id`     | 整数        | はい      | 絵文字リアクションのID。                                                        |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji/344"
```

## コメントにリアクションを追加する {#add-reactions-to-comments}

コメント (メモとも呼ばれます) は、イシュー、マージリクエスト、およびスニペットのサブリソースです。

> [!note]
> 以下の例は、イシューのコメントで絵文字リアクションを操作する方法について説明していますが、マージリクエストとスニペットのコメントにも適用できます。したがって、`issue_iid`を`merge_request_iid`または`snippet_id`に置き換える必要があります。

### コメントのすべての絵文字リアクションをリスト表示する {#list-all-emoji-reactions-for-a-comment}

{{< history >}}

- GitLab 15.1で、パブリックコメントへの認証されていないアクセスを許可するように[変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/335068)。

{{< /history >}}

指定されたコメントのすべての絵文字リアクションをリスト表示します。コメントが一般公開されている場合、このエンドポイントは認証なしでアクセスできます。

```plaintext
GET /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji
```

パラメータは以下のとおりです:

| 属性   | 型           | 必須 | 説明                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid` | 整数        | はい      | イシューの内部ID。                                                     |
| `note_id`   | 整数        | はい      | コメント (メモ) のID。                                                      |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/notes/1/award_emoji"
```

レスポンス例: 

```json
[
  {
    "id": 2,
    "name": "mood_bubble_lightning",
    "user": {
      "name": "User 4",
      "username": "user4",
      "id": 26,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/user4"
    },
    "created_at": "2016-06-15T10:09:34.197Z",
    "updated_at": "2016-06-15T10:09:34.197Z",
    "awardable_id": 1,
    "awardable_type": "Note"
  }
]
```

### コメントから絵文字リアクションを取得する {#retrieve-an-emoji-reaction-from-a-comment}

{{< history >}}

- GitLab 15.1で、パブリックコメントへの認証されていないアクセスを許可するように[変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/335068)。

{{< /history >}}

指定されたコメントから絵文字リアクションを取得します。コメントが一般公開されている場合、このエンドポイントは認証なしでアクセスできます。

```plaintext
GET /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji/:award_id
```

パラメータは以下のとおりです:

| 属性   | 型           | 必須 | 説明                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid` | 整数        | はい      | イシューの内部ID。                                                     |
| `note_id`   | 整数        | はい      | コメント (メモ) のID。                                                      |
| `award_id`  | 整数        | はい      | 絵文字リアクションのID。                                                       |

リクエスト例: 

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/notes/1/award_emoji/2"
```

レスポンス例: 

```json
{
  "id": 2,
  "name": "mood_bubble_lightning",
  "user": {
    "name": "User 4",
    "username": "user4",
    "id": 26,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/user4"
  },
  "created_at": "2016-06-15T10:09:34.197Z",
  "updated_at": "2016-06-15T10:09:34.197Z",
  "awardable_id": 1,
  "awardable_type": "Note"
}
```

### コメントにリアクションを追加する {#add-an-emoji-reaction-to-a-comment}

指定されたコメントに絵文字リアクションを追加します。

```plaintext
POST /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji
```

パラメータは以下のとおりです:

| 属性   | 型           | 必須 | 説明                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid` | 整数        | はい      | イシューの内部ID。                                                     |
| `note_id`   | 整数        | はい      | コメント (メモ) のID。                                                      |
| `name`      | 文字列         | はい      | コロンなしの絵文字名。                                            |

リクエスト例: 

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/notes/1/award_emoji?name=rocket"
```

レスポンス例: 

```json
{
  "id": 345,
  "name": "rocket",
  "user": {
    "name": "Administrator",
    "username": "root",
    "id": 1,
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/root"
  },
  "created_at": "2016-06-17T19:59:55.888Z",
  "updated_at": "2016-06-17T19:59:55.888Z",
  "awardable_id": 1,
  "awardable_type": "Note"
}
```

### コメントから絵文字リアクションを削除する {#delete-an-emoji-reaction-from-a-comment}

指定されたコメントから絵文字リアクションを削除します。

管理者またはリアクションの作成者のみが絵文字リアクションを削除できます。

```plaintext
DELETE /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji/:award_id
```

パラメータは以下のとおりです:

| 属性   | 型           | 必須 | 説明                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid` | 整数        | はい      | イシューの内部ID。                                                     |
| `note_id`   | 整数        | はい      | コメント (メモ) のID。                                                      |
| `award_id`  | 整数        | はい      | 絵文字リアクションのID。                                                        |

リクエスト例: 

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji/345"
```
