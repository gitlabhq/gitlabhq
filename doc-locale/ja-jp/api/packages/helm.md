---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Helm API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[Helmパッケージクライアント](../../user/packages/helm_repository/_index.md)と対話します。

> [!warning]
> このAPIは、Helm関連のパッケージクライアント（[Helm](https://helm.sh/)や[`helm-push`](https://github.com/chartmuseum/helm-push/#readme)など）で使用され、通常は手動での利用を意図していません。

これらのエンドポイントは、標準のAPI認証方法に準拠していません。サポートされているヘッダーとトークンタイプについては、[Helmレジストリドキュメント](../../user/packages/helm_repository/_index.md)を参照してください。記載されていない認証方法は、将来削除される可能性があります。

## チャートインデックスのダウンロード {#download-a-chart-index}

> [!note]
> 一貫したチャートダウンロードURLを確保するため、APIへのアクセスにプロジェクトIDを使用するか、完全なプロジェクトパスを使用するかにかかわらず、`contextPath`フィールドは`index.yaml`レスポンスで常に数値のプロジェクトIDを使用します。

指定されたチャートインデックスをプロジェクト用にダウンロードします。

```plaintext
GET projects/:id/packages/helm/:channel/index.yaml
```

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id`      | 文字列 | はい      | プロジェクトのIDまたは完全なパス。 |
| `channel` | 文字列 | はい      | Helmリポジトリチャンネル。 |

```shell
curl --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/stable/index.yaml"
```

出力をファイルに書き込みます:

```shell
curl --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/stable/index.yaml" \
     --remote-name
```

## チャートのダウンロード {#download-a-chart}

指定されたチャートをプロジェクト用にダウンロードします。

```plaintext
GET projects/:id/packages/helm/:channel/charts/:file_name.tgz
```

| 属性   | 型   | 必須 | 説明 |
| ----------- | ------ | -------- | ----------- |
| `id`        | 文字列 | はい      | プロジェクトのIDまたは完全なパス。 |
| `channel`   | 文字列 | はい      | Helmリポジトリチャンネル。 |
| `file_name` | 文字列 | はい      | チャートファイル名。 |

```shell
curl --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/stable/charts/mychart.tgz" \
     --remote-name
```

## チャートのアップロード {#upload-a-chart}

指定されたチャートをプロジェクト用にアップロードします。

```plaintext
POST projects/:id/packages/helm/api/:channel/charts
```

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id`      | 文字列 | はい      | プロジェクトのIDまたは完全なパス。 |
| `channel` | 文字列 | はい      | Helmリポジトリチャンネル。 |
| `chart`   | ファイル   | はい      | チャート (`multipart/form-data`として)。 |

```shell
curl --request POST \
     --form 'chart=@mychart.tgz' \
     --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/api/stable/charts"
```
