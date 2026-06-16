---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ライセンスAPI
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabでは、様々なAPIエンドポイントが、様々なオープンソースライセンステンプレートで動作するように利用できます。様々なライセンスの条件に関する詳細については、[このサイト](https://choosealicense.com/)またはオンラインで利用できる他の多くのリソースを参照してください。

ゲストロールを持つユーザーは、ライセンステンプレートにアクセスできません。詳細については、[プロジェクトとグループの表示レベル](../../user/public_access.md)を参照してください。

## すべてのライセンステンプレートをリストする {#list-all-license-templates}

すべてのライセンステンプレートをリストします。

```plaintext
GET /templates/licenses
```

| 属性 | 型    | 必須 | 説明 |
|-----------|---------|----------|-------------|
| `popular` | ブール値 | いいえ       | 渡された場合、人気のあるライセンスのみを返します。 |

リクエスト例: 

```shell
curl "https://gitlab.example.com/api/v4/templates/licenses?popular=1"
```

レスポンス例: 

```json
[
  {
    "key":"apache-2.0",
    "name":"Apache License 2.0",
    "nickname":null,
    "featured":true,
    "html_url":"http://choosealicense.com/licenses/apache-2.0/",
    "source_url":"http://www.apache.org/licenses/LICENSE-2.0.html",
    "description":"A permissive license that also provides an express grant of patent rights from contributors to users.",
    "conditions":[
      "include-copyright",
      "document-changes"
    ],
    "permissions":[
      "commercial-use",
      "modifications",
      "distribution",
      "patent-use",
      "private-use"
    ],
    "limitations":[
      "trademark-use",
      "no-liability"
    ],
    "content":"                                 Apache License\n                           Version 2.0, January 2004\n [...]"
  },
  {
    "key":"gpl-3.0",
    "name":"GNU General Public License v3.0",
    "nickname":"GNU GPLv3",
    "featured":true,
    "html_url":"http://choosealicense.com/licenses/gpl-3.0/",
    "source_url":"http://www.gnu.org/licenses/gpl-3.0.txt",
    "description":"The GNU GPL is the most widely used free software license and has a strong copyleft requirement. When distributing derived works, the source code of the work must be made available under the same license.",
    "conditions":[
      "include-copyright",
      "document-changes",
      "disclose-source",
      "same-license"
    ],
    "permissions":[
      "commercial-use",
      "modifications",
      "distribution",
      "patent-use",
      "private-use"
    ],
    "limitations":[
      "no-liability"
    ],
    "content":"                    GNU GENERAL PUBLIC LICENSE\n                       Version 3, 29 June 2007\n [...]"
  },
  {
    "key":"mit",
    "name":"MIT License",
    "nickname":null,
    "featured":true,
    "html_url":"http://choosealicense.com/licenses/mit/",
    "source_url":"http://opensource.org/licenses/MIT",
    "description":"A permissive license that is short and to the point. It lets people do anything with your code with proper attribution and without warranty.",
    "conditions":[
      "include-copyright"
    ],
    "permissions":[
      "commercial-use",
      "modifications",
      "distribution",
      "private-use"
    ],
    "limitations":[
      "no-liability"
    ],
    "content":"The MIT License (MIT)\n\nCopyright (c) [year] [fullname]\n [...]"
  }
]
```

## 単一のライセンステンプレートを取得する {#retrieve-a-single-license-template}

単一のライセンステンプレートを取得します。ライセンスのプレースホルダーを置き換えるために、パラメータを渡すことができます。

```plaintext
GET /templates/licenses/:key
```

| 属性  | 型   | 必須 | 説明 |
|------------|--------|----------|-------------|
| `key`      | 文字列 | はい      | ライセンステンプレートのキー |
| `project`  | 文字列 | いいえ       | 著作権で保護されたプロジェクト名 |
| `fullname` | 文字列 | いいえ       | 著作権保持者のフルネーム |

> [!note]
> `fullname`パラメータを省略しても、リクエストを認証した場合、認証済みユーザーの名前が著作権保持者のプレースホルダーに置き換わります。

リクエスト例: 

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/templates/licenses/mit?project=My+Cool+Project"
```

レスポンス例: 

```json
{
  "key":"mit",
  "name":"MIT License",
  "nickname":null,
  "featured":true,
  "html_url":"http://choosealicense.com/licenses/mit/",
  "source_url":"http://opensource.org/licenses/MIT",
  "description":"A permissive license that is short and to the point. It lets people do anything with your code with proper attribution and without warranty.",
  "conditions":[
    "include-copyright"
  ],
  "permissions":[
    "commercial-use",
    "modifications",
    "distribution",
    "private-use"
  ],
  "limitations":[
    "no-liability"
  ],
  "content":"The MIT License (MIT)\n\nCopyright (c) 2016 John Doe\n [...]"
}
```
