---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Documentation for the REST API for managing Git repository files in GitLab.
title: リポジトリファイルAPI
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、リポジトリ内のファイルをフェッチ、作成、更新、および削除できます。このAPIの[レート制限を設定する](../administration/settings/files_api_rate_limits.md)こともできます。

## パーソナルアクセストークンで使用可能なスコープ

[パーソナルアクセストークン](../user/profile/personal_access_tokens.md)では、次のスコープがサポートされています。

| スコープ             | 説明 |
|-------------------|-------------|
| `api`             | リポジトリファイルへの読み取り/書き込みアクセスを許可します。 |
| `read_api`        | リポジトリファイルへの読み取りアクセスを許可します。 |
| `read_repository` | リポジトリファイルへの読み取りアクセスを許可します。 |

## リポジトリからファイルを取得する

名前、サイズ、内容など、リポジトリ内のファイルに関する情報を受け取ることができるようにします。ファイルの内容はBase64でエンコードされています。リポジトリが公開されている場合、このエンドポイントには認証なしでアクセスできます。

```plaintext
GET /projects/:id/repository/files/:file_path
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fmodels%2Fkey%2Erb?ref=main"
```

| 属性   | 型           | 必須 | 説明 |
|-------------|----------------|----------|-------------|
| `id`        | 整数または文字列 | はい   | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `file_path` | 文字列         | はい      | 新しいファイルのURLエンコードされたフルパス（`lib%2Fclass%2Erb`など）。 |
| `ref`       | 文字列         | はい      | ブランチ、タグ、またはコミットの名前。デフォルトブランチを自動的に使用するには、`HEAD`を使用します。 |

ブランチ名がわからない場合、またはデフォルトブランチを使用する場合は、`ref`の値として`HEAD`を使用できます。次に例を示します。

```shell
curl --header "PRIVATE-TOKEN: " \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fmodels%2Fkey%2Erb?ref=HEAD"
```

### 応答

応答の`blob_id`はblob SHAです。リポジトリAPIの[リポジトリからblobを取得する](repositories.md#get-a-blob-from-repository)を参照してください。

応答の例:

```json
{
  "file_name": "key.rb",
  "file_path": "app/models/key.rb",
  "size": 1476,
  "encoding": "base64",
  "content": "IyA9PSBTY2hlbWEgSW5mb3...",
  "content_sha256": "4c294617b60715c1d218e61164a3abd4808a4284cbc30e6728a01ad9aada4481",
  "ref": "main",
  "blob_id": "79f7bbd25901e8334750839545a9bd021f0e4c83",
  "commit_id": "d5a3ff139356ce33e37e73add446f16869741b50",
  "last_commit_id": "570e7b2abdd848b95f2f578043fc23bd6f6fd24d",
  "execute_filemode": false
}
```

### ファイルメタデータのみを取得する

`HEAD`を使用して、ファイルメタデータのみを取得することもできます。

```plaintext
HEAD /projects/:id/repository/files/:file_path
```

```shell
curl --head --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fmodels%2Fkey%2Erb?ref=main"
```

応答の例:

```plaintext
HTTP/1.1 200 OK
...
X-Gitlab-Blob-Id: 79f7bbd25901e8334750839545a9bd021f0e4c83
X-Gitlab-Commit-Id: d5a3ff139356ce33e37e73add446f16869741b50
X-Gitlab-Content-Sha256: 4c294617b60715c1d218e61164a3abd4808a4284cbc30e6728a01ad9aada4481
X-Gitlab-Encoding: base64
X-Gitlab-File-Name: key.rb
X-Gitlab-File-Path: app/models/key.rb
X-Gitlab-Last-Commit-Id: 570e7b2abdd848b95f2f578043fc23bd6f6fd24d
X-Gitlab-Ref: main
X-Gitlab-Size: 1476
X-Gitlab-Execute-Filemode: false
...
```

## リポジトリからファイルblameを取得する

blame情報を取得します。各blame範囲には、行と対応するコミット情報が含まれています。

```plaintext
GET /projects/:id/repository/files/:file_path/blame
```

| 属性       | 型              | 必須 | 説明 |
|-----------------|-------------------|----------|-------------|
| `file_path`     | 文字列            | はい   | 新しいファイルのURLエンコードされたフルパス（`lib%2Fclass%2Erb`など）。 |
| `id`            | 整数または文字列 | はい   | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `range[end]`    | 整数           | はい   | blame対象範囲の最後の行。 |
| `range[start]`  | 整数           | はい   | blame対象範囲の最初の行。 |
| `ref`           | 文字列            | はい   | ブランチ、タグ、またはコミットの名前。デフォルトブランチを自動的に使用するには、`HEAD`を使用します。 |
| `range`         | ハッシュ              | いいえ    | blame範囲。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/path%2Fto%2Ffile.rb/blame?ref=main"
```

応答の例:

```json
[
  {
    "commit": {
      "id": "d42409d56517157c48bf3bd97d3f75974dde19fb",
      "message": "Add feature\n\nalso fix bug\n",
      "parent_ids": [
        "cc6e14f9328fa6d7b5a0d3c30dc2002a3f2a3822"
      ],
      "authored_date": "2015-12-18T08:12:22.000Z",
      "author_name": "John Doe",
      "author_email": "john.doe@example.com",
      "committed_date": "2015-12-18T08:12:22.000Z",
      "committer_name": "John Doe",
      "committer_email": "john.doe@example.com"
    },
    "lines": [
      "require 'fileutils'",
      "require 'open3'",
      ""
    ]
  },
  ...
]
```

### ファイルメタデータのみを取得する

[リポジトリからファイルを取得する](repository_files.md#get-file-from-repository)のように、ファイルメタデータのみを返すには、`HEAD`メソッドを使用します。

```shell
curl --head --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/path%2Fto%2Ffile.rb/blame?ref=main"
```

#### 応答

応答の例:

```plaintext
HTTP/1.1 200 OK
...
X-Gitlab-Blob-Id: 79f7bbd25901e8334750839545a9bd021f0e4c83
X-Gitlab-Commit-Id: d5a3ff139356ce33e37e73add446f16869741b50
X-Gitlab-Content-Sha256: 4c294617b60715c1d218e61164a3abd4808a4284cbc30e6728a01ad9aada4481
X-Gitlab-Encoding: base64
X-Gitlab-File-Name: file.rb
X-Gitlab-File-Path: path/to/file.rb
X-Gitlab-Last-Commit-Id: 570e7b2abdd848b95f2f578043fc23bd6f6fd24d
X-Gitlab-Ref: main
X-Gitlab-Size: 1476
X-Gitlab-Execute-Filemode: false
...
```

### blame範囲をリクエストする

blame範囲をリクエストするには、`range[start]`パラメーターにファイルの開始行番号を指定し、`range[end]`パラメーターに終了行番号を指定します。

```shell
curl --head --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/path%2Fto%2Ffile.rb/blame?ref=main&range[start]=1&range[end]=2"
```

応答の例:

```json
[
  {
    "commit": {
      "id": "d42409d56517157c48bf3bd97d3f75974dde19fb",
      "message": "Add feature\n\nalso fix bug\n",
      "parent_ids": [
        "cc6e14f9328fa6d7b5a0d3c30dc2002a3f2a3822"
      ],
      "authored_date": "2015-12-18T08:12:22.000Z",
      "author_name": "John Doe",
      "author_email": "john.doe@example.com",
      "committed_date": "2015-12-18T08:12:22.000Z",
      "committer_name": "John Doe",
      "committer_email": "john.doe@example.com"
    },
    "lines": [
      "require 'fileutils'",
      "require 'open3'"
    ]
  },
  ...
]
```

## リポジトリからrawファイルを取得する

```plaintext
GET /projects/:id/repository/files/:file_path/raw
```

| 属性   | 型           | 必須 | 説明 |
|-------------|----------------|----------|------------|
| `file_path` | 文字列         | はい      | 新しいファイルのURLエンコードされたフルパス（`lib%2Fclass%2Erb`など）。 |
| `id`        | 整数または文字列 | はい   | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `lfs`       | ブール値        | いいえ       | 応答をポインターではなく、Git LFSファイルの内容にするかどうかを決定します。ファイルがGit LFSで追跡されていない場合は無視されます。デフォルトは`false`です。GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/27892)されました。 |
| `ref`       | 文字列         | いいえ       | ブランチ、タグ、またはコミットの名前。デフォルトはプロジェクトの`HEAD`です。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fmodels%2Fkey%2Erb/raw?ref=main"
```

{{< alert type="note" >}}

[リポジトリからファイルを取得する](repository_files.md#get-file-from-repository)と同様に、`HEAD`を使用してファイルメタデータのみを取得できます。

{{< /alert >}}

## リポジトリに新しいファイルを作成する

1つのファイルを作成できるようにします。1つのリクエストで複数のファイルを作成するには、[コミットAPI](commits.md#create-a-commit-with-multiple-files-and-actions)を参照してください。

```plaintext
POST /projects/:id/repository/files/:file_path
```

| 属性          | 型           | 必須 | 説明 |
| ------------------ | -------------- | -------- | ----------- |
| `branch`           | 文字列         | はい      | 作成する新しいブランチの名前。コミットはこのブランチに追加されます。 |
| `commit_message`   | 文字列         | はい      | コミットメッセージ。 |
| `content`          | 文字列         | はい      | ファイルの内容。 |
| `file_path`        | 文字列         | はい      | 新しいファイルのURLエンコードされたフルパス。たとえば`lib%2Fclass%2Erb`などです。 |
| `id`               | 整数または文字列 | はい   | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `author_email`     | 文字列         | いいえ       | コミット作成者のメールアドレス。 |
| `author_name`      | 文字列         | いいえ       | コミット作成者の名前。 |
| `encoding`         | 文字列         | いいえ       | エンコードを`base64`に変更します。デフォルトは`text`です。 |
| `execute_filemode` | ブール値        | いいえ       | ファイルの`execute`フラグを有効または無効にします。`true`または`false`を指定できます。 |
| `start_branch`     | 文字列         | いいえ       | 新しいブランチの作成元となるベースブランチの名前。 |

```shell
curl --request POST \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header "Content-Type: application/json" \
  --data '{"branch": "main", "author_email": "author@example.com", "author_name": "Firstname Lastname",
            "content": "some content", "commit_message": "create a new file"}' \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fproject%2Erb"
```

応答の例:

```json
{
  "file_path": "app/project.rb",
  "branch": "main"
}
```

## リポジトリ内の既存のファイルを更新する

1つのファイルを更新できるようにします。1つのリクエストで複数のファイルを更新するには、[コミットAPI](commits.md#create-a-commit-with-multiple-files-and-actions)を参照してください。

```plaintext
PUT /projects/:id/repository/files/:file_path
```

| 属性        | 型           | 必須 | 説明 |
| ---------------- | -------------- | -------- | ----------- |
| `branch`         | 文字列         | はい      | 作成する新しいブランチの名前。コミットはこのブランチに追加されます。 |
| `commit_message` | 文字列         | はい      | コミットメッセージ。 |
| `content`        | 文字列         | はい      | ファイルの内容。 |
| `file_path`      | 文字列         | はい      | 新しいファイルのURLエンコードされたフルパス。たとえば`lib%2Fclass%2Erb`などです。 |
| `id`             | 整数または文字列 | はい   | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)  |
| `author_email`   | 文字列         | いいえ       | コミット作成者のメールアドレス。 |
| `author_name`    | 文字列         | いいえ       | コミット作成者の名前。 |
| `encoding`       | 文字列         | いいえ       | エンコードを`base64`に変更します。デフォルトは`text`です。 |
| `execute_filemode` | ブール値      | いいえ       | ファイルの`execute`フラグを有効または無効にします。`true`または`false`を指定できます。 |
| `last_commit_id` | 文字列         | いいえ       | 既知の最新のファイルコミットID。 |
| `start_branch`   | 文字列         | いいえ       | 新しいブランチの作成元となるベースブランチの名前。 |

```shell
curl --request PUT \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header "Content-Type: application/json" \
  --data '{"branch": "main", "author_email": "author@example.com", "author_name": "Firstname Lastname",
       "content": "some content", "commit_message": "update file"}' \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fproject%2Erb"
```

応答の例:

```json
{
  "file_path": "app/project.rb",
  "branch": "main"
}
```

何らかの理由でコミットが失敗した場合は、特定の具体的なエラーメッセージではなく、`400 Bad Request`エラーを返します。コミットが失敗する原因として考えられる状況は次のとおりです。

- `file_path`に`/../`が含まれていた（ディレクトリトラバーサルが試行された）。
- コミットが空であった。新しいファイルの内容が現在のファイルの内容と同じであった。
- ファイルの編集中に、他のユーザーが`git push`でブランチを更新した。

[GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell/)の戻りコードはブール値であるため、GitLabはエラーを指定できません。

## リポジトリ内の既存のファイルを削除する

1つのファイルを削除します。1つのリクエストで複数のファイルを削除するには、[コミットAPI](commits.md#create-a-commit-with-multiple-files-and-actions)を参照してください。

```plaintext
DELETE /projects/:id/repository/files/:file_path
```

| 属性        | 型           | 必須 | 説明 |
| ---------------- | -------------- | -------- | ----------- |
| `branch`         | 文字列         | はい      | 作成する新しいブランチの名前。コミットはこのブランチに追加されます。 |
| `commit_message` | 文字列         | はい      | コミットメッセージ。 |
| `file_path`      | 文字列         | はい      | 新しいファイルのURLエンコードされたフルパス。たとえば`lib%2Fclass%2Erb`などです。 |
| `id`             | 整数または文字列 | はい   | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `author_email`   | 文字列         | いいえ       | コミット作成者のメールアドレス。 |
| `author_name`    | 文字列         | いいえ       | コミット作成者の名前。 |
| `last_commit_id` | 文字列         | いいえ       | 既知の最新のファイルコミットID。 |
| `start_branch`   | 文字列         | いいえ       | 新しいブランチの作成元となるベースブランチの名前。 |

```shell
curl --request DELETE \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header "Content-Type: application/json" \
  --data '{"branch": "main", "author_email": "author@example.com", "author_name": "Firstname Lastname",
       "commit_message": "delete file"}' \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fproject%2Erb"
```
