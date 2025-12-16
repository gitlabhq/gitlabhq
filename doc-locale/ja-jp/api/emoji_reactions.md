---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 絵文字リアクションAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 16.0では、[名前が](https://gitlab.com/gitlab-org/gitlab/-/issues/409884)「award emoji」から「emoji reactions」に変更されました。

{{< /history >}}

絵文字[リアクション](../user/emoji_reactions.md)は千の言葉を語ります。

GitLabでは、絵文字リアクションを受け入れるオブジェクトをawardableと呼びます。以下のものに絵文字でリアクションできます:

- [エピック](../user/group/epics/_index.md) （[API](epics.md)）。
- [イシュー](../user/project/issues/_index.md) ([API](issues.md))。
- [マージリクエスト](../user/project/merge_requests/_index.md) ([API](merge_requests.md))。
- [スニペット](../user/snippets.md) （[API](snippets.md)）。
- [コメント](../user/emoji_reactions.md#emoji-reactions-for-comments) （[API](notes.md)）。

## イシュー、マージリクエスト、スニペット {#issues-merge-requests-and-snippets}

コメントでこれらのエンドポイントを使用する方法については、[コメントへのリアクションの追加](#add-reactions-to-comments)を参照してください。

### awardableの絵文字リアクションを一覧表示する {#list-an-awardables-emoji-reactions}

{{< history >}}

- GitLab 15.1 [で変更](https://gitlab.com/gitlab-org/gitlab/-/issues/335068)され、パブリックawardableへの認証なしでのアクセスが許可されました。

{{< /history >}}

指定されたawardableのすべての絵文字リアクションのリストを取得します。指定されたマージリクエストが公開されている場合、このエンドポイントへのアクセスは認証なしで可能です。

```plaintext
GET /projects/:id/issues/:issue_iid/award_emoji
GET /projects/:id/merge_requests/:merge_request_iid/award_emoji
GET /projects/:id/snippets/:snippet_id/award_emoji
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid``merge_request_iid``snippet_id` | 整数        | はい      | awardableのID（マージリクエスト/イシューの場合は`iid`、スニペットの場合は`id`）。     |

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

### 単一の絵文字リアクションを取得する {#get-single-emoji-reaction}

{{< history >}}

- GitLab 15.1 [で変更](https://gitlab.com/gitlab-org/gitlab/-/issues/335068)され、パブリックawardableへの認証なしでのアクセスが許可されました。

{{< /history >}}

イシュー、スニペット、またはマージリクエストから単一の絵文字リアクションを取得します。指定されたマージリクエストが公開されている場合、このエンドポイントへのアクセスは認証なしで可能です。

```plaintext
GET /projects/:id/issues/:issue_iid/award_emoji/:award_id
GET /projects/:id/merge_requests/:merge_request_iid/award_emoji/:award_id
GET /projects/:id/snippets/:snippet_id/award_emoji/:award_id
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid``merge_request_iid``snippet_id` | 整数        | はい      | awardableのID（マージリクエスト/イシューの場合は`iid`、スニペットの場合は`id`）。     |
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

### 新しい絵文字リアクションを追加する {#add-a-new-emoji-reaction}

指定されたawardableに絵文字リアクションを追加します。

```plaintext
POST /projects/:id/issues/:issue_iid/award_emoji
POST /projects/:id/merge_requests/:merge_request_iid/award_emoji
POST /projects/:id/snippets/:snippet_id/award_emoji
```

パラメータは以下のとおりです:

| 属性      | 型           | 必須 | 説明                                                                  |
|:---------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`           | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid``merge_request_iid``snippet_id` | 整数        | はい      | awardableのID（マージリクエスト/イシューの場合は`iid`、スニペットの場合は`id`）。     |
| `name`         | 文字列         | はい      | コロンなしの絵文字の名前。                                            |

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

### 絵文字リアクションを削除します {#delete-an-emoji-reaction}

時にはうまくいかないことがあり、リアクションを削除する必要があります。

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
| `issue_iid``merge_request_iid``snippet_id` | 整数        | はい      | awardableのID（マージリクエスト/イシューの場合は`iid`、スニペットの場合は`id`）。     |
| `award_id`     | 整数        | はい      | 絵文字リアクションのID。                                                        |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji/344"
```

## コメントにリアクションを追加する {#add-reactions-to-comments}

コメント（注釈とも呼ばれます）は、イシュー、マージリクエスト、およびスニペットのサブリソースです。

{{< alert type="note" >}}

以下の例では、イシューのコメントに対する絵文字リアクションの操作について説明していますが、マージリクエストとスニペットのコメントにも適用できます。したがって、`issue_iid`を`merge_request_iid`または`snippet_id`に置き換える必要があります。

{{< /alert >}}

### コメントの絵文字リアクションをリストする {#list-a-comments-emoji-reactions}

{{< history >}}

- GitLab 15.1 [で変更](https://gitlab.com/gitlab-org/gitlab/-/issues/335068)され、パブリックコメントへの認証なしでのアクセスが許可されました。

{{< /history >}}

コメント（注釈）のすべての絵文字リアクションを取得します。コメントが公開されている場合、このエンドポイントには認証なしでアクセスできます。

```plaintext
GET /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji
```

パラメータは以下のとおりです:

| 属性   | 型           | 必須 | 説明                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid` | 整数        | はい      | イシューの内部ID。                                                     |
| `note_id`   | 整数        | はい      | コメント（注釈）のID。                                                      |

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

### コメントの絵文字リアクションを取得する {#get-an-emoji-reaction-for-a-comment}

{{< history >}}

- GitLab 15.1 [で変更](https://gitlab.com/gitlab-org/gitlab/-/issues/335068)され、パブリックコメントへの認証なしでのアクセスが許可されました。

{{< /history >}}

コメント（注釈）の単一の絵文字リアクションを取得します。コメントが公開されている場合、このエンドポイントには認証なしでアクセスできます。

```plaintext
GET /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji/:award_id
```

パラメータは以下のとおりです:

| 属性   | 型           | 必須 | 説明                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid` | 整数        | はい      | イシューの内部ID。                                                     |
| `note_id`   | 整数        | はい      | コメント（注釈）のID。                                                      |
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

### コメントに新しい絵文字リアクションを追加する {#add-a-new-emoji-reaction-to-a-comment}

指定されたコメント（注釈）に絵文字リアクションを作成します。

```plaintext
POST /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji
```

パラメータは以下のとおりです:

| 属性   | 型           | 必須 | 説明                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid` | 整数        | はい      | イシューの内部ID。                                                     |
| `note_id`   | 整数        | はい      | コメント（注釈）のID。                                                      |
| `name`      | 文字列         | はい      | コロンなしの絵文字の名前。                                            |

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

時にはうまくいかないことがあり、リアクションを削除する必要があります。

管理者またはリアクションの作成者のみが絵文字リアクションを削除できます。

```plaintext
DELETE /projects/:id/issues/:issue_iid/notes/:note_id/award_emoji/:award_id
```

パラメータは以下のとおりです:

| 属性   | 型           | 必須 | 説明                                                                  |
|:------------|:---------------|:---------|:-----------------------------------------------------------------------------|
| `id`        | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `issue_iid` | 整数        | はい      | イシューの内部ID。                                                     |
| `note_id`   | 整数        | はい      | コメント（注釈）のID。                                                      |
| `award_id`  | 整数        | はい      | 絵文字リアクションのID。                                                        |

リクエスト例:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/issues/80/award_emoji/345"
```
