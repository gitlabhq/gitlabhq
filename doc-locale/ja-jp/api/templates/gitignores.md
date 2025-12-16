---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: .gitignore API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabでは、`/gitignores`エンドポイントは、Git `.gitignore`テンプレートのリストを返します。詳しくは、[Gitの`.gitignore`に関するドキュメント](https://git-scm.com/docs/gitignore)をご覧ください。

ゲストロールのユーザーは、`.gitignore`テンプレートにアクセスできません。詳細については、[プロジェクトとグループの表示レベル](../../user/public_access.md)を参照してください。

## すべての`.gitignore`テンプレート {#get-all-gitignore-templates}

すべての`.gitignore`テンプレートのリストを取得します。

```plaintext
GET /templates/gitignores
```

成功した場合、[`200 OK`](../rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性 | 型   | 説明 |
|-----------|--------|-------------|
| `key`     | 文字列 | `.gitignore`テンプレートのキー識別子。 |
| `name`    | 文字列 | `.gitignore`テンプレートの表示名。 |

リクエスト例:

```shell
curl "https://gitlab.example.com/api/v4/templates/gitignores"
```

レスポンス例:

```json
[
  {
    "key": "Actionscript",
    "name": "Actionscript"
  },
  {
    "key": "Ada",
    "name": "Ada"
  },
  {
    "key": "Agda",
    "name": "Agda"
  },
  {
    "key": "Android",
    "name": "Android"
  },
  {
    "key": "AppEngine",
    "name": "AppEngine"
  },
  {
    "key": "AppceleratorTitanium",
    "name": "AppceleratorTitanium"
  },
  {
    "key": "ArchLinuxPackages",
    "name": "ArchLinuxPackages"
  },
  {
    "key": "Autotools",
    "name": "Autotools"
  },
  {
    "key": "C",
    "name": "C"
  },
  {
    "key": "C++",
    "name": "C++"
  },
  {
    "key": "CFWheels",
    "name": "CFWheels"
  },
  {
    "key": "CMake",
    "name": "CMake"
  },
  {
    "key": "CUDA",
    "name": "CUDA"
  },
  {
    "key": "CakePHP",
    "name": "CakePHP"
  },
  {
    "key": "ChefCookbook",
    "name": "ChefCookbook"
  },
  {
    "key": "Clojure",
    "name": "Clojure"
  },
  {
    "key": "CodeIgniter",
    "name": "CodeIgniter"
  },
  {
    "key": "CommonLisp",
    "name": "CommonLisp"
  },
  {
    "key": "Composer",
    "name": "Composer"
  },
  {
    "key": "Concrete5",
    "name": "Concrete5"
  }
]
```

## 単一の`.gitignore`テンプレートを取得 {#get-a-single-gitignore-template}

単一の`.gitignore`テンプレートを取得します。

```plaintext
GET /templates/gitignores/:key
```

サポートされている属性は以下のとおりです:

| 属性 | 型   | 必須 | 説明 |
|-----------|--------|----------|-------------|
| `key`     | 文字列 | はい      | `.gitignore`テンプレートのキー。 |

成功した場合、[`200 OK`](../rest/troubleshooting.md#status-codes)と次のレスポンス属性を返します:

| 属性 | 型   | 説明 |
|-----------|--------|-------------|
| `content` | 文字列 | `.gitignore`テンプレートのコンテンツ。 |
| `name`    | 文字列 | `.gitignore`テンプレートの表示名。 |

リクエスト例:

```shell
curl "https://gitlab.example.com/api/v4/templates/gitignores/Ruby"
```

レスポンス例:

```json
{
  "name": "Ruby",
  "content": "*.gem\n*.rbc\n/.config\n/coverage/\n/InstalledFiles\n/pkg/\n/spec/reports/\n/spec/examples.txt\n/test/tmp/\n/test/version_tmp/\n/tmp/\n\n# Used by dotenv library to load environment variables.\n# .env\n\n## Specific to RubyMotion:\n.dat*\n.repl_history\nbuild/\n*.bridgesupport\nbuild-iPhoneOS/\nbuild-iPhoneSimulator/\n\n## Specific to RubyMotion (use of CocoaPods):\n#\n# We recommend against adding the Pods directory to your .gitignore. However\n# you should judge for yourself, the pros and cons are mentioned at:\n# https://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control\n#\n# vendor/Pods/\n\n## Documentation cache and generated files:\n/.yardoc/\n/_yardoc/\n/doc/\n/rdoc/\n\n## Environment normalization:\n/.bundle/\n/vendor/bundle\n/lib/bundler/man/\n\n# for a library or gem, you might want to ignore these files since the code is\n# intended to run in multiple environments; otherwise, check them in:\n# Gemfile.lock\n# .ruby-version\n# .ruby-gemset\n\n# unless supporting rvm < 1.11.0 or doing something fancy, ignore this:\n.rvmrc\n"
}
```
