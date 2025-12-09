---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: リリースリンクAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- [追加](https://gitlab.com/gitlab-org/gitlab/-/issues/250819) [GitLab CI/CDジョブトークン](../../ci/jobs/ci_job_token.md)で認証をGitLab 15.1で追加しました。

{{< /history >}}

このAPIを使用して、[releases](../../user/project/releases/_index.md)へのリンクを操作します。

GitLabは、次のプロトコルでアセットリンクをサポートします:

- `http`
- `https`
- `ftp`

{{< alert type="note" >}}

プロジェクトリリースを直接操作するには、[project release API](_index.md)を参照してください。

{{< /alert >}}

## リリースのリンクを一覧表示 {#list-links-of-a-release}

リリースからアセットをリンクとして取得します。

```plaintext
GET /projects/:id/releases/:tag_name/assets/links
```

| 属性     | 型           | 必須 | 説明                             |
| ------------- | -------------- | -------- | --------------------------------------- |
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。 |
| `tag_name`    | 文字列         | はい      | リリースに関連付けられているタグ。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/assets/links"
```

レスポンス例:

```json
[
   {
      "id":2,
      "name":"awesome-v0.2.msi",
      "url":"http://192.168.10.15:3000/msi",
      "link_type":"other"
   },
   {
      "id":1,
      "name":"awesome-v0.2.dmg",
      "url":"http://192.168.10.15:3000",
      "link_type":"other"
   }
]
```

## リリースリンクを取得 {#get-a-release-link}

リリースからアセットをリンクとして取得します。

```plaintext
GET /projects/:id/releases/:tag_name/assets/links/:link_id
```

| 属性     | 型           | 必須 | 説明                             |
| ------------- | -------------- | -------- | --------------------------------------- |
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。 |
| `tag_name`    | 文字列         | はい      | リリースに関連付けられているタグ。 |
| `link_id`    | 整数         | はい      | リンクのID。 |

リクエスト例:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/assets/links/1"
```

レスポンス例:

```json
{
   "id":1,
   "name":"awesome-v0.2.dmg",
   "url":"http://192.168.10.15:3000",
   "link_type":"other"
}
```

## リリースリンクを作成 {#create-a-release-link}

リリースからアセットをリンクとして作成します。

```plaintext
POST /projects/:id/releases/:tag_name/assets/links
```

| 属性            | 型           | 必須 | 説明                                                                                                               |
|----------------------|----------------|----------|---------------------------------------------------------------------------------------------------------------------------|
| `id`                 | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。                                        |
| `tag_name`           | 文字列         | はい      | リリースに関連付けられているタグ。                                                                                      |
| `name`               | 文字列         | はい      | リンクの名前。リンク名は、リリース内で一意である必要があります。                                                           |
| `url`                | 文字列         | はい      | リンクのURL。リンクURLは、リリース内で一意である必要があります。                                                             |
| `direct_asset_path`  | 文字列         | いいえ       | [ダイレクトアセットリンク](../../user/project/releases/release_fields.md#permanent-links-to-release-assets)のオプションのパス。 |
| `link_type`          | 文字列         | いいえ       | リンクの種類: `other`、`runbook`、`image`、`package`。`other`がデフォルトです。                                        |

リクエストの例:

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --data name="hellodarwin-amd64" \
    --data url="https://gitlab.example.com/mynamespace/hello/-/jobs/688/artifacts/raw/bin/hello-darwin-amd64" \
    --data direct_asset_path="/bin/hellodarwin-amd64" \
    "https://gitlab.example.com/api/v4/projects/20/releases/v1.7.0/assets/links"
```

レスポンス例:

```json
{
   "id":2,
   "name":"hellodarwin-amd64",
   "url":"https://gitlab.example.com/mynamespace/hello/-/jobs/688/artifacts/raw/bin/hello-darwin-amd64",
   "direct_asset_url":"https://gitlab.example.com/mynamespace/hello/-/releases/v1.7.0/downloads/bin/hellodarwin-amd64",
   "link_type":"other"
}
```

## リリースリンクを更新 {#update-a-release-link}

リリースからアセットをリンクとして更新します。

```plaintext
PUT /projects/:id/releases/:tag_name/assets/links/:link_id
```

| 属性            | 型           | 必須 | 説明                                                                                                               |
| -------------------- | -------------- | -------- | ------------------------------------------------------------------------------------------------------------------------- |
| `id`                 | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。 |
| `tag_name`           | 文字列         | はい      | リリースに関連付けられているタグ。 |
| `link_id`            | 整数        | はい      | リンクのID。 |
| `name`               | 文字列         | いいえ       | リンクの名前。 |
| `url`                | 文字列         | いいえ       | リンクのURL。 |
| `direct_asset_path`  | 文字列         | いいえ       | [ダイレクトアセットリンク](../../user/project/releases/release_fields.md#permanent-links-to-release-assets)のオプションのパス。 |
| `link_type`          | 文字列         | いいえ       | リンクの種類: `other`、`runbook`、`image`、`package`。`other`がデフォルトです。 |

{{< alert type="note" >}}

`name`または`url`の少なくとも1つを指定する必要があります

{{< /alert >}}

リクエスト例:

```shell
curl --request PUT --data name="new name" --data link_type="runbook" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/assets/links/1"
```

レスポンス例:

```json
{
   "id":1,
   "name":"new name",
   "url":"http://192.168.10.15:3000",
   "link_type":"runbook"
}
```

## リリースリンクを削除 {#delete-a-release-link}

リリースからアセットをリンクとして削除します。

```plaintext
DELETE /projects/:id/releases/:tag_name/assets/links/:link_id
```

| 属性     | 型           | 必須 | 説明                             |
| ------------- | -------------- | -------- | --------------------------------------- |
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](../rest/_index.md#namespaced-paths)。 |
| `tag_name`    | 文字列         | はい      | リリースに関連付けられているタグ。 |
| `link_id`    | 整数         | はい      | リンクのID。 |

リクエスト例:

```shell
curl --request DELETE --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/24/releases/v0.1/assets/links/1"
```

レスポンス例:

```json
{
   "id":1,
   "name":"new name",
   "url":"http://192.168.10.15:3000",
   "link_type":"other"
}
```
