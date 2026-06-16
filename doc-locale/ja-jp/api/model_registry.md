---
stage: Deploy
group: MLOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: モデルレジストリAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、機械学習の[モデルレジストリ](../user/project/ml/model_registry/_index.md)を操作します。

各エンドポイントの`:model_version_id`属性は、モデルバージョンIDまたは候補実行IDのいずれかを受け入れます。詳細については、[モデルバージョンと候補ID](#model-version-and-candidate-ids)を参照してください。

## 機械学習モデルパッケージファイルをダウンロード {#download-a-machine-learning-model-package-file}

機械学習モデルパッケージから指定されたファイルをダウンロードします。

```plaintext
GET /api/v4/projects/:id/packages/ml_models/:model_version_id/files/(*path/):file_name
```

サポートされている属性は以下のとおりです: 

| 属性          | 型              | 必須 | 説明 |
|--------------------|-------------------|----------|-------------|
| `id`               | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `model_version_id` | 整数または文字列 | はい      | モデルバージョンIDまたは候補実行ID。[モデルバージョンと候補ID](#model-version-and-candidate-ids)を参照してください。 |
| `file_name`        | 文字列            | はい      | ファイル名。 |
| `path`             | 文字列            | いいえ       | ファイルのディレクトリパス。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)とファイルの内容を返します。

リクエスト例: 

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/foo.txt"
```

ディレクトリパスを含むリクエストの例:

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/my_dir/foo.txt"
```

## モデルパッケージファイルをアップロード {#upload-a-model-package-file}

機械学習モデルパッケージにファイルをアップロードします。

### アップロードを承認 {#authorize-the-upload}

機械学習モデルパッケージへのファイルアップロードを承認します。

```plaintext
PUT /api/v4/projects/:id/packages/ml_models/:model_version_id/files/(*path/):file_name/authorize
```

サポートされている属性は以下のとおりです: 

| 属性          | 型              | 必須 | 説明 |
|--------------------|-------------------|----------|-------------|
| `id`               | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `model_version_id` | 整数または文字列 | はい      | モデルバージョンIDまたは候補実行ID。[モデルバージョンと候補ID](#model-version-and-candidate-ids)を参照してください。 |
| `file_name`        | 文字列            | はい      | ファイル名。 |
| `path`             | 文字列            | いいえ       | ファイルのディレクトリパス。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request PUT \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/model.pkl/authorize"
```

### ファイルを送信 {#send-the-file}

機械学習モデルパッケージにファイルをアップロードします。

```plaintext
PUT /api/v4/projects/:id/packages/ml_models/:model_version_id/files/(*path/):file_name
```

サポートされている属性は以下のとおりです: 

| 属性          | 型              | 必須 | 説明 |
|--------------------|-------------------|----------|-------------|
| `id`               | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `model_version_id` | 整数または文字列 | はい      | モデルバージョンIDまたは候補実行ID。[モデルバージョンと候補ID](#model-version-and-candidate-ids)を参照してください。 |
| `file_name`        | 文字列            | はい      | ファイル名。 |
| `path`             | 文字列            | いいえ       | ファイルのディレクトリパス。 |
| `file`             | ファイル              | はい      | アップロードするファイル。 |

成功した場合、[`201 Created`](rest/troubleshooting.md#status-codes)を返します。

リクエスト例: 

```shell
curl --request PUT \
  --header "Authorization: Bearer <your_access_token>" \
  --form "file=@model.pkl" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/model.pkl"
```

ディレクトリパスを含むリクエストの例:

```shell
curl --request PUT \
  --header "Authorization: Bearer <your_access_token>" \
  --form "file=@model.pkl" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/my_dir/model.pkl"
```

## モデルバージョンと候補ID {#model-version-and-candidate-ids}

`:model_version_id`属性は、モデルバージョンIDまたは候補実行IDのいずれかを受け入れます。

モデルバージョンIDを見つけるには、モデルバージョンページのURLを確認してください。例えば、`https://gitlab.example.com/my-namespace/my-project/-/ml/models/1/versions/5`では、モデルバージョンIDは`5`です。

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/5/files/model.pkl"
```

候補実行IDを使用するには、候補の内部IDの前に`candidate:`を付加します。例えば、`https://gitlab.example.com/my-namespace/my-project/-/ml/candidates/5`では、`:model_version_id`の値は`candidate:5`です。

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/candidate:5/files/model.pkl"
```
