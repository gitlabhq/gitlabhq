---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Go Proxy API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、[Goパッケージマネージャークライアント](../../user/packages/go_proxy/_index.md)とやり取りします。このAPIは、機能フラグの背後にあり、デフォルトで無効になっています。GitLabインスタンスのこのAPIを[有効](../../administration/feature_flags/_index.md)にできるのは、GitLab Railsコンソールへのアクセス権を持つ管理者のみです。

{{< alert type="warning" >}}

このAPIは[Goクライアント](https://maven.apache.org/)で使用され、通常、手動での消費を目的としていません。

{{< /alert >}}

{{< alert type="note" >}}

これらのエンドポイントは、標準のAPI認証方式に準拠していません。どのヘッダーとトークンのタイプがサポートされているかの詳細については、[Go Proxyパッケージドキュメント](../../user/packages/go_proxy/_index.md)を参照してください。記載されていない認証方法は、将来削除される可能性があります。

{{< /alert >}}

## リスト {#list}

特定のGoモジュールのすべてのタグ付けされたバージョンを取得します:

```plaintext
GET projects/:id/packages/go/:module_name/@v/list
```

| 属性      | 型   | 必須 | 説明 |
| -------------- | ------ | -------- | ----------- |
| `id`           | 文字列 | はい      | プロジェクトのプロジェクトIDまたはフルパス。 |
| `module_name`  | 文字列 | はい      | Goモジュールの名前。 |

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/list"
```

出力例: 

```shell
"v1.0.0\nv1.0.1\nv1.3.8\n2.0.0\n2.1.0\n3.0.0"
```

## バージョンのメタデータ {#version-metadata}

特定のGoモジュールのすべてのタグ付けされたバージョンを取得します:

```plaintext
GET projects/:id/packages/go/:module_name/@v/:module_version.info
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 文字列 | はい      | プロジェクトのプロジェクトIDまたはフルパス。 |
| `module_name`     | 文字列 | はい      | Goモジュールの名前。 |
| `module_version`  | 文字列 | はい      | Goモジュールのバージョン。 |

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/1.0.0.info"
```

出力例: 

```json
{
  "Version": "v1.0.0",
  "Time": "1617822312 -0600"
}
```

## モジュールファイルのダウンロード {#download-module-file}

`.mod`モジュールファイルをフェッチします:

```plaintext
GET projects/:id/packages/go/:module_name/@v/:module_version.mod
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 文字列 | はい      | プロジェクトのプロジェクトIDまたはフルパス。 |
| `module_name`     | 文字列 | はい      | Goモジュールの名前。 |
| `module_version`  | 文字列 | はい      | Goモジュールのバージョン。 |

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/1.0.0.mod"
```

ファイルに書き込みます:

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/1.0.0.mod" >> foo.mod
```

これは現在のディレクトリ内の`foo.mod`に書き込まれます。

## モジュールソースのダウンロード {#download-module-source}

モジュールソースの`.zip`をフェッチします:

```plaintext
GET projects/:id/packages/go/:module_name/@v/:module_version.zip
```

| 属性         | 型   | 必須 | 説明 |
| ----------------- | ------ | -------- | ----------- |
| `id`              | 文字列 | はい      | プロジェクトのプロジェクトIDまたはフルパス。 |
| `module_name`     | 文字列 | はい      | Goモジュールの名前。 |
| `module_version`  | 文字列 | はい      | Goモジュールのバージョン。 |

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/1.0.0.zip"
```

ファイルに書き込みます:

```shell
curl --header "Private-Token: <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/go/my-go-module/@v/1.0.0.zip" >> foo.zip
```

これは現在のディレクトリ内の`foo.zip`に書き込まれます。
