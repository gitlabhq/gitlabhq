---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Dependencies APIにアクセスして、サポートされているパッケージマネージャーのパッケージの詳細、バージョン、脆弱性、ライセンスなど、プロジェクト依存情報を取得します。
title: APIを使用した依存関係
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このエンドポイントへのすべての呼び出しは認証を必要とします。この呼び出しを実行するには、ユーザーはリポジトリを読み取り権限を許可されている必要があります。レスポンスで脆弱性を確認するには、ユーザーは[プロジェクトセキュリティダッシュボード](../user/application_security/security_dashboard/_index.md)の読み取りを許可されている必要があります。

## プロジェクト依存関係のリスト {#list-project-dependencies}

プロジェクト依存関係のリストを取得します。このAPIは、[依存関係リスト](../user/application_security/dependency_list/_index.md)機能を部分的にミラーリングしています。このリストは、Gemnasiumがサポートする[言語](../user/application_security/dependency_scanning/_index.md#supported-languages-and-package-managers)とパッケージマネージャーに対してのみ生成できます。

```plaintext
GET /projects/:id/dependencies
GET /projects/:id/dependencies?package_manager=maven
GET /projects/:id/dependencies?package_manager=yarn,bundler
```

| 属性     | 型           | 必須 | 説明                                                                                                                                                                 |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。                                                            |
| `package_manager` | 文字列配列   | いいえ       | 指定されたパッケージマネージャーに属する依存関係を返します。有効な値は、`bundler`、`composer`、`conan`、`go`、`gradle`、`maven`、`npm`、`nuget`、`pip`、`pipenv`、`pnpm`、`yarn`、`sbt`、`setuptools`です。 |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
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

## 依存関係のページネーション {#dependencies-pagination}

APIの結果はページネーションされるため、デフォルトでは、`GET`リクエストは一度に20件の結果を返します。

詳細については、[ページネーション](rest/_index.md#pagination)を参照してください。
