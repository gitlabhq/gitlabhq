---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: サポートされているパッケージマネージャーのパッケージ詳細、バージョン、脆弱性、およびライセンスを含むプロジェクト依存情報をAPIから取得します。
title: 依存関係API
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このエンドポイントへのすべての呼び出しには認証が必要です。この呼び出しを実行するには、ユーザーはリポジトリの読み取り権限を持っている必要があります。脆弱性を確認するには、ユーザーは[プロジェクトセキュリティダッシュボード](../user/application_security/security_dashboard/_index.md)を読み取る権限を持っている必要があります。

## プロジェクトの依存関係を一覧表示する {#list-project-dependencies}

指定されたプロジェクトのすべての依存関係をリスト表示します。この操作は、[依存関係リスト](../user/application_security/dependency_list/_index.md)機能の一部をミラーリングします。この機能は、Gemnasiumでサポートされている[言語とパッケージマネージャー](../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#supported-languages-and-files)のみで利用可能です。

レスポンスは[ページ付けされています](rest/_index.md#pagination)。デフォルトでは20件の結果が返されます。

```plaintext
GET /projects/:id/dependencies
GET /projects/:id/dependencies?package_manager=maven
GET /projects/:id/dependencies?package_manager=yarn,bundler
```

| 属性     | 型           | 必須 | 説明                                                                                                                                                                 |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                                                            |
| `package_manager` | 文字列配列   | いいえ       | 指定されたパッケージマネージャーに属する依存関係を返します。有効な値: `bundler`、`composer`、`conan`、`go`、`gradle`、`maven`、`npm`、`nuget`、`pip`、`pipenv`、`pnpm`、`yarn`、`sbt`、または`setuptools`。 |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/4/dependencies"
```

レスポンス例: 

```json
[
  {
    "name": "rails",
    "version": "5.0.1",
    "package_manager": "bundler",
    "dependency_file_path": "Gemfile.lock",
    "vulnerabilities": [
      {
        "name": "DDoS",
        "severity": "unknown",
        "id": 144827,
        "url": "https://gitlab.example.com/group/project/-/security/vulnerabilities/144827"
      }
    ],
    "licenses": [
      {
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT"
      }
    ]
  },
  {
    "name": "hanami",
    "version": "1.3.1",
    "package_manager": "bundler",
    "dependency_file_path": "Gemfile.lock",
    "vulnerabilities": [],
    "licenses": [
      {
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT"
      }
    ]
  }
]
```
