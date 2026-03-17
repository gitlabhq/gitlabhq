---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabにおけるマージリクエストのコンテキストコミットに関するREST APIのドキュメント。
title: マージリクエストコンテキストコミットAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

あなたのマージリクエストが以前のマージリクエストを基にしている場合、[以前にマージされたコミットをコンテキストとして含める](../user/project/merge_requests/commits.md#show-commits-from-previous-merge-requests)必要があるかもしれません。このAPIを使用して、マージリクエストにコミットを追加し、より多くのコンテキストを提供します。

## マージリクエストのコンテキストコミットを一覧表示 {#list-context-commits-for-a-merge-request}

単一のマージリクエストのコンテキストコミットを一覧表示します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/context_commits
```

パラメータは以下のとおりです:

| 属性           | 型    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `id`                | 整数 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数 | はい | マージリクエストの内部ID。 |

```json
[
    {
        "id": "4a24d82dbca5c11c61556f3b35ca472b7463187e",
        "short_id": "4a24d82d",
        "created_at": "2017-04-11T10:08:59.000Z",
        "parent_ids": null,
        "title": "Update README.md to include `Usage in testing and development`",
        "message": "Update README.md to include `Usage in testing and development`",
        "author_name": "Example \"Sample\" User",
        "author_email": "user@example.com",
        "authored_date": "2017-04-11T10:08:59.000Z",
        "committer_name": "Example \"Sample\" User",
        "committer_email": "user@example.com",
        "committed_date": "2017-04-11T10:08:59.000Z"
    }
]
```

## マージリクエストのコンテキストコミットを作成 {#create-context-commits-for-a-merge-request}

単一のマージリクエストのコンテキストコミットを作成します。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/context_commits
```

パラメータは以下のとおりです:

| 属性           | 型    | 必須 | 説明 |
|---------------------|---------|----------|-------------|
| `id`                | 整数 | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)  |
| `merge_request_iid` | 整数 | はい | マージリクエストの内部ID。 |
| `commits`           | 文字列配列 | はい | コンテキストコミットのSHA。 |

リクエスト例: 

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"commits": ["51856a574ac3302a95f82483d6c7396b1e0783cb"]}' \
  --url "https://gitlab.example.com/api/v4/projects/15/merge_requests/12/context_commits"
```

レスポンス例: 

```json
[
    {
        "id": "51856a574ac3302a95f82483d6c7396b1e0783cb",
        "short_id": "51856a57",
        "created_at": "2014-02-27T10:05:10.000+02:00",
        "parent_ids": [
            "57a82e2180507c9e12880c0747f0ea65ad489515"
        ],
        "title": "Commit title",
        "message": "Commit message",
        "author_name": "Example User",
        "author_email": "user@example.com",
        "authored_date": "2014-02-27T10:05:10.000+02:00",
        "committer_name": "Example User",
        "committer_email": "user@example.com",
        "committed_date": "2014-02-27T10:05:10.000+02:00",
        "trailers": {},
        "web_url": "https://gitlab.example.com/project/path/-/commit/b782f6c553653ab4e16469ff34bf3a81638ac304"
    }
]
```

## マージリクエストからコンテキストコミットを削除 {#delete-context-commits-from-a-merge-request}

単一のマージリクエストからコンテキストコミットを削除します。

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/context_commits
```

パラメータは以下のとおりです:

| 属性           | 型         | 必須 | 説明  |
|---------------------|--------------|----------|--------------|
| `commits`           | 文字列配列 | はい | コンテキストコミットのSHA。 |
| `id`                | 整数      | はい | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数      | はい | マージリクエストの内部ID。 |
