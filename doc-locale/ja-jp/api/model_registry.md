---
stage: Deploy
group: MLOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: モデルレジストリAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して機械学習モデルレジストリを操作します。詳細については、[モデルレジストリ](../user/project/ml/model_registry/_index.md)を参照してください。

## MLモデルパッケージのダウンロード {#download-a-machine-learning-model-package}

ファイルを返します。

```plaintext
GET /projects/:id/packages/ml_models/:model_version_id/files/(*path/):file_name
```

バージョンの場合、`:model_version_id`は、モデルバージョンのURLで指定します。次の例では、モデルバージョンは`5`:`/namespace/project/-/ml/models/1/versions/5`です。

実行の場合、IDの先頭に`candidate:`を付加する必要があります。次の例では、`:model_version_id`は`candidate:5`です: `/namespace/project/-/ml/candidates/5`。

パラメータは以下のとおりです:

| 属性          | 型              | 必須 | 説明                                                                            |
|--------------------|-------------------|----------|----------------------------------------------------------------------------------------|
| `id`               | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)    |
| `model_version_id` | 整数または文字列 | はい      | ファイルのモデルバージョンID                                                      |
| `path`             | 文字列            | はい      | ファイルのディレクトリパス                                                                    |
| `filename`         | 文字列            | はい      | ファイル名                                                                               |

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/:id/packages/ml_models/:model_version_id/files/(*path/):filename"
```

応答には、ファイルの内容が含まれています。

たとえば、次のコマンドは、IDが`2`のモデルバージョンと、IDが`1`のプロジェクトのファイル`foo.txt`を返します。

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/foo.txt"
```
