---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Helm API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[Helmパッケージクライアント](../../user/packages/helm_repository/_index.md)とやり取りします。

{{< alert type="warning" >}}

このAPIは、[Helm](https://helm.sh/)や[`helm-push`](https://github.com/chartmuseum/helm-push/#readme)などのHelm関連パッケージクライアントで使用され、通常は手動での使用を意図していません。

{{< /alert >}}

{{< alert type="note" >}}

これらのエンドポイントは、標準のAPI認証方式に準拠していません。サポートされているヘッダーおよびトークンの種類の詳細については、[Helmレジストリドキュメント](../../user/packages/helm_repository/_index.md)を参照してください。記載されていない認証方法は、将来削除される可能性があります。

{{< /alert >}}

## チャートインデックスをダウンロード {#download-a-chart-index}

{{< alert type="note" >}}

チャートのダウンロードURLの一貫性を確保するため、`index.yaml`の応答の`contextPath`フィールドは、プロジェクトIDまたは完全なプロジェクトパスでAPIにアクセスするかどうかにかかわらず、常に数値プロジェクトIDを使用します。

{{< /alert >}}

チャートインデックスをダウンロード:

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

出力をファイルに書き込み:

```shell
curl --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/stable/index.yaml" \
     --remote-name
```

## チャートをダウンロード {#download-a-chart}

チャートをダウンロード:

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

## チャートをアップロード {#upload-a-chart}

チャートをアップロード:

```plaintext
POST projects/:id/packages/helm/api/:channel/charts
```

| 属性 | 型   | 必須 | 説明 |
| --------- | ------ | -------- | ----------- |
| `id`      | 文字列 | はい      | プロジェクトのIDまたは完全なパス。 |
| `channel` | 文字列 | はい      | Helmリポジトリチャンネル。 |
| `chart`   | ファイル   | はい      | チャート（`multipart/form-data`として）。 |

```shell
curl --request POST \
     --form 'chart=@mychart.tgz' \
     --user <username>:<personal_access_token> \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/helm/api/stable/charts"
```
