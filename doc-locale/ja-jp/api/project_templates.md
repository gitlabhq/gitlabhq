---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: プロジェクトテンプレートAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このAPIを使用して、これらのエンドポイントのプロジェクト固有のバージョンを取得します:

- [Dockerfileテンプレート](templates/dockerfiles.md)
- [Gitignoreテンプレート](templates/gitignores.md)
- [GitLab CI/CD設定テンプレート](templates/gitlab_ci_ymls.md)
- [オープンソースライセンステンプレート](templates/licenses.md)
- [イシューとマージリクエストのテンプレート](../user/project/description_templates.md)

これにより、これらのエンドポイントは非推奨となり、APIバージョン5で削除される予定です。

インスタンス全体に共通するテンプレートに加えて、プロジェクト固有のテンプレートもこのAPIエンドポイントから利用できます。

[グループのファイルテンプレート](../user/group/manage.md#group-file-templates)のサポートも利用できます。

## 特定の種類のテンプレートをすべてリスト表示 {#list-all-templates-of-a-particular-type}

プロジェクトの指定された種類のテンプレートをすべてリスト表示します。

```plaintext
GET /projects/:id/templates/:type
```

サポートされている属性は以下のとおりです: 

| 属性 | 型              | 必須 | 説明 |
|-----------|-------------------|----------|-------------|
| `id`      | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `type`    | 文字列            | はい      | テンプレートのタイプ。指定できる値: `dockerfiles`、`gitignores`、`gitlab_ci_ymls`、`licenses`、`issues`、`merge_requests`。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性 | 型   | 説明 |
|-----------|--------|-------------|
| `key`     | 文字列 | テンプレートの固有識別子。 |
| `name`    | 文字列 | テンプレートの人間が判読できる名前。 |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/templates/licenses"
```

レスポンス例（ライセンス）: 

```json
[
  {
    "key": "epl-1.0",
    "name": "Eclipse Public License 1.0"
  },
  {
    "key": "lgpl-3.0",
    "name": "GNU Lesser General Public License v3.0"
  },
  {
    "key": "unlicense",
    "name": "The Unlicense"
  },
  {
    "key": "agpl-3.0",
    "name": "GNU Affero General Public License v3.0"
  },
  {
    "key": "gpl-3.0",
    "name": "GNU General Public License v3.0"
  },
  {
    "key": "bsd-3-clause",
    "name": "BSD 3-clause \"New\" or \"Revised\" License"
  },
  {
    "key": "lgpl-2.1",
    "name": "GNU Lesser General Public License v2.1"
  },
  {
    "key": "mit",
    "name": "MIT License"
  },
  {
    "key": "apache-2.0",
    "name": "Apache License 2.0"
  },
  {
    "key": "bsd-2-clause",
    "name": "BSD 2-clause \"Simplified\" License"
  },
  {
    "key": "mpl-2.0",
    "name": "Mozilla Public License 2.0"
  },
  {
    "key": "gpl-2.0",
    "name": "GNU General Public License v2.0"
  }
]
```

## 特定の種類のテンプレートを取得する {#retrieve-a-template-of-a-particular-type}

プロジェクトの指定された種類のテンプレートを取得します。

```plaintext
GET /projects/:id/templates/:type/:name
```

サポートされている属性は以下のとおりです: 

| 属性                    | 型              | 必須 | 説明 |
|------------------------------|-------------------|----------|-------------|
| `id`                         | 整数または文字列 | はい      | プロジェクトのIDまたは[URLエンコードされたパス](rest/_index.md#namespaced-paths)。 |
| `name`                       | 文字列            | はい      | コレクションエンドポイントから取得したテンプレートのキー。 |
| `type`                       | 文字列            | はい      | テンプレートのタイプ。次のいずれか: `dockerfiles`、`gitignores`、`gitlab_ci_ymls`、`licenses`、`issues`、`merge_requests`。 |
| `fullname`                   | 文字列            | いいえ       | テンプレート内のプレースホルダーを展開するときに使用する著作権者のフルネーム。ライセンスのみに影響します。 |
| `project`                    | 文字列            | いいえ       | テンプレート内のプレースホルダーを展開するときに使用するプロジェクト名。ライセンスのみに影響します。 |
| `source_template_project_id` | 整数           | いいえ       | 指定されたテンプレートが保存されているプロジェクトID。異なるプロジェクトの複数のテンプレートが同じ名前を持つ場合に役立ちます。複数のテンプレートが同じ名前を持つ場合、`source_template_project_id`が指定されていない場合は、最も近い祖先からの一致が返されます。 |

成功した場合、[`200 OK`](rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します: 

| 属性     | 型     | 説明                                                   |
|---------------|----------|---------------------------------------------------------------|
| `conditions`  | 配列    | ライセンス条件の配列。ライセンスでのみ使用可能です。    |
| `content`     | 文字列   | テンプレートの内容。                                             |
| `description` | 文字列   | ライセンスの説明。ライセンスでのみ使用可能です。     |
| `html_url`    | 文字列   | ライセンス情報ページへのURL。ライセンスでのみ使用可能です。 |
| `key`         | 文字列   | テンプレートの固有識別子。ライセンスでのみ使用可能です。 |
| `limitations` | 配列    | ライセンス制限の配列。ライセンスでのみ使用可能です。   |
| `name`        | 文字列   | テンプレートの人間が判読できる名前。                          |
| `nickname`    | 文字列   | ライセンスの一般的なニックネーム。ライセンスでのみ使用可能です。 |
| `permissions` | 配列    | ライセンス許可の配列。ライセンスでのみ使用可能です。   |
| `popular`     | ブール値  | `true`の場合、これがよく使われるライセンスであることを示します。ライセンスでのみ使用可能です。 |
| `source_url`  | 文字列   | ライセンスソースへのURL。ライセンスでのみ使用可能です。      |

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/templates/dockerfiles/Binary"
```

レスポンス例（Dockerfile）: 

```json
{
  "name": "Binary",
  "content": "# This file is a template, and might need editing before it works on your project.\n# This Dockerfile installs a compiled binary into a bare system.\n# You must either commit your compiled binary into source control (not recommended)\n# or build the binary first as part of a CI/CD pipeline.\n\nFROM buildpack-deps:buster\n\nWORKDIR /usr/local/bin\n\n# Change `app` to whatever your binary is called\nAdd app .\nCMD [\"./app\"]\n"
}
```

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/templates/licenses/mit"
```

レスポンス例（ライセンス）: 

```json
{
  "key": "mit",
  "name": "MIT License",
  "nickname": null,
  "popular": true,
  "html_url": "http://choosealicense.com/licenses/mit/",
  "source_url": "https://opensource.org/licenses/MIT",
  "description": "A short and simple permissive license with conditions only requiring preservation of copyright and license notices. Licensed works, modifications, and larger works may be distributed under different terms and without source code.",
  "conditions": [
    "include-copyright"
  ],
  "permissions": [
    "commercial-use",
    "modifications",
    "distribution",
    "private-use"
  ],
  "limitations": [
    "liability",
    "warranty"
  ],
  "content": "MIT License\n\nCopyright (c) 2018 [fullname]\n\nPermission is hereby granted, free of charge, to any person obtaining a copy\nof this software and associated documentation files (the \"Software\"), to deal\nin the Software without restriction, including without limitation the rights\nto use, copy, modify, merge, publish, distribute, sublicense, and/or sell\ncopies of the Software, and to permit persons to whom the Software is\nfurnished to do so, subject to the following conditions:\n\nThe above copyright notice and this permission notice shall be included in all\ncopies or substantial portions of the Software.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\nIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\nFITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\nAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\nLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\nOUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\nSOFTWARE.\n"
}
```
