---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabのドラフトノート（未公開コメント）のREST APIに関するドキュメントです。
title: ドラフトノートAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、ドラフトノートを管理します。これらのノートは、マージリクエストに関する保留中の未公開コメントです。ドラフトノートはディスカッションを開始したり、既存のディスカッションへの返信として継続したりできます。

公開するまで、ドラフトノートは作成者のみに表示されます。

## すべてのマージリクエストドラフトノートを一覧表示 {#list-all-merge-request-draft-notes}

単一のマージリクエストのすべてのドラフトノートのリストを取得します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/draft_notes
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths) |
| `merge_request_iid` | 整数           | はい      | プロジェクトマージリクエストのIID |

```json
[
  {
    "id": 5,
    "author_id": 23,
    "merge_request_id": 11,
    "resolve_discussion": false,
    "discussion_id": null,
    "note": "Example title",
    "commit_id": null,
    "line_code": null,
    "position": {
      "base_sha": null,
      "start_sha": null,
      "head_sha": null,
      "old_path": null,
      "new_path": null,
      "position_type": "text",
      "old_line": null,
      "new_line": null,
      "line_range": null
    }
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes"
```

## 単一のドラフトノートを取得 {#get-a-single-draft-note}

指定されたマージリクエストの単一のドラフトノートを返します。

```plaintext
GET /projects/:id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `draft_note_id`     | 整数           | はい      | ドラフトノートのID。 |
| `merge_request_iid` | 整数           | はい      | プロジェクトマージリクエストのIID。 |

```json
[
  {
    "id": 5,
    "author_id": 23,
    "merge_request_id": 11,
    "resolve_discussion": false,
    "discussion_id": null,
    "note": "Example title",
    "commit_id": null,
    "line_code": null,
    "position": {
      "base_sha": null,
      "start_sha": null,
      "head_sha": null,
      "old_path": null,
      "new_path": null,
      "position_type": "text",
      "old_line": null,
      "new_line": null,
      "line_range": null
    }
  }
]
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/5"
```

## ドラフトノートを作成 {#create-a-draft-note}

指定されたマージリクエストのドラフトノートを作成します。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/draft_notes
```

| 属性                   | 型              | 必須    | 説明           |
| ----------------------------| ----------------- | ----------- | --------------------- |
| `id`                        | 整数または文字列 | はい         | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid`         | 整数           | はい         | プロジェクトマージリクエストのIID。 |
| `note`                      | 文字列            | はい         | ノートのコンテンツ。 |
| `commit_id`                 | 文字列            | いいえ          | ドラフトノートを関連付けるコミットのSHA。 |
| `in_reply_to_discussion_id` | 文字列            | いいえ          | ドラフトノートが返信するディスカッションのID。 |
| `resolve_discussion`        | ブール値           | いいえ          | 関連付けられたディスカッションは解決されるはずです。 |
| `position`                  | ハッシュ              | いいえ          | 差分ノートを作成する際の位置。省略した場合、通常のディスカッションノートが作成されます。 |
| `position[base_sha]`        | 文字列            | はい（`position`が指定されている場合） | ソースブランチのベースコミットSHA。 |
| `position[head_sha]`        | 文字列            | はい（`position`が指定されている場合） | このマージリクエストのHEADを参照するSHA。 |
| `position[start_sha]`       | 文字列            | はい（`position`が指定されている場合） | ターゲットブランチのコミットを参照するSHA。 |
| `position[new_path]`        | 文字列            | はい（position typeが`text`の場合） | 変更後のファイルパス。 |
| `position[old_path]`        | 文字列            | はい（position typeが`text`の場合） | 変更前のファイルパス。 |
| `position[position_type]`   | 文字列            | はい（`position`が指定されている場合） | 位置参照のタイプ。許可される値：`text`、`image`、または`file`。`file`は、GitLab 16.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/423046)。 |
| `position[new_line]`        | 整数           | いいえ          | `text`差分ノートの場合、変更後の行番号。 |
| `position[old_line]`        | 整数           | いいえ          | `text`差分ノートの場合、変更前の行番号。 |
| `position[line_range]`      | ハッシュ              | いいえ          | 複数行の差分ノートの行範囲。 |
| `position[width]`           | 整数           | いいえ          | `image`差分ノートの場合、画像の幅。 |
| `position[height]`          | 整数           | いいえ          | `image`差分ノートの場合、画像の高さ。 |
| `position[x]`               | 浮動小数点数             | いいえ          | `image`差分ノートの場合、X座標。 |
| `position[y]`               | 浮動小数点数             | いいえ          | `image`差分ノートの場合、Y座標。 |

```shell
curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes?note=note"
```

## 既存のドラフトノートを変更 {#modify-existing-draft-note}

指定されたマージリクエストのドラフトノートを変更します。

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id
```

| 属性                 | 型              | 必須 | 説明 |
| ------------------------- | ----------------- | -------- | ----------- |
| `id`                      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `draft_note_id`           | 整数           | はい      | ドラフトノートのID。 |
| `merge_request_iid`       | 整数           | はい      | プロジェクトマージリクエストのIID。 |
| `note`                    | 文字列            | いいえ       | ノートのコンテンツ。 |
| `position`                | ハッシュ              | いいえ       | 差分ノートを作成する際の位置。 |
| `position[base_sha]`      | 文字列            | はい（`position`が指定されている場合） | ソースブランチのベースコミットSHA。 |
| `position[head_sha]`      | 文字列            | はい（`position`が指定されている場合） | このマージリクエストのHEADを参照するSHA。 |
| `position[start_sha]`     | 文字列            | はい（`position`が指定されている場合） | ターゲットブランチのコミットを参照するSHA。 |
| `position[new_path]`      | 文字列            | はい（position typeが`text`の場合） | 変更後のファイルパス。 |
| `position[old_path]`      | 文字列            | はい（position typeが`text`の場合） | 変更前のファイルパス。 |
| `position[position_type]` | 文字列            | はい（`position`が指定されている場合） | 位置参照のタイプ。許可される値：`text`、`image`、または`file`。`file`は、GitLab 16.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/423046)。 |
| `position[new_line]`      | 整数           | いいえ       | `text`差分ノートの場合、変更後の行番号。 |
| `position[old_line]`      | 整数           | いいえ       | `text`差分ノートの場合、変更前の行番号。 |
| `position[line_range]`    | ハッシュ              | いいえ       | 複数行の差分ノートの行範囲。 |
| `position[width]`         | 整数           | いいえ       | `image`差分ノートの場合、画像の幅。 |
| `position[height]`        | 整数           | いいえ       | `image`差分ノートの場合、画像の高さ。 |
| `position[x]`             | 浮動小数点数             | いいえ       | `image`差分ノートの場合、X座標。 |
| `position[y]`             | 浮動小数点数             | いいえ       | `image`差分ノートの場合、Y座標。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/5"
```

## ドラフトノートを削除 {#delete-a-draft-note}

指定されたマージリクエストの既存のドラフトノートを削除します。

```plaintext
DELETE /projects/:id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `draft_note_id`     | 整数           | はい      | ドラフトノートのID。 |
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | プロジェクトマージリクエストのIID。 |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/5"
```

## ドラフトノートを公開 {#publish-a-draft-note}

指定されたマージリクエストの既存のドラフトノートを公開します。

```plaintext
PUT /projects/:id/merge_requests/:merge_request_iid/draft_notes/:draft_note_id/publish
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `draft_note_id`     | 整数           | はい      | ドラフトノートのID。 |
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | プロジェクトマージリクエストのIID。 |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/5/publish"
```

## 保留中のすべてのドラフトノートを公開 {#publish-all-pending-draft-notes}

指定されたマージリクエストの、ユーザーに属する既存のすべてのドラフトノートを一括公開します。

```plaintext
POST /projects/:id/merge_requests/:merge_request_iid/draft_notes/bulk_publish
```

| 属性           | 型              | 必須 | 説明 |
|---------------------|-------------------|----------|-------------|
| `id`                | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `merge_request_iid` | 整数           | はい      | プロジェクトマージリクエストのIID。 |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/14/merge_requests/11/draft_notes/bulk_publish"
```
