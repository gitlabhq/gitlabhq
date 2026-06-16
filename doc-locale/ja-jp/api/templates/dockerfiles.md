---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dockerfile API
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、インスタンス全体で利用可能なDockerfileテンプレート用のAPIエンドポイントを提供します。デフォルトテンプレートは、GitLab Gitリポジトリ内の[`vendor/Dockerfile`](https://gitlab.com/gitlab-org/gitlab-foss/-/tree/master/vendor/Dockerfile)で定義されています。

ゲストロールのユーザーは、Dockerfileテンプレートにアクセスできません。詳細については、[プロジェクトとグループの表示レベル](../../user/public_access.md)を参照してください。

## Dockerfile APIテンプレートを上書きする {#override-dockerfile-api-templates}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[GitLab PremiumおよびUltimate](https://about.gitlab.com/pricing/)ティアでは、GitLabインスタンス管理者は[**管理者**エリア](../../administration/settings/instance_template_repository.md)でテンプレートを上書きできます。

## すべてのDockerfileテンプレートを一覧表示する {#list-all-dockerfile-templates}

すべてのDockerfileテンプレートを一覧表示します。

```plaintext
GET /templates/dockerfiles
```

リクエスト例: 

```shell
curl "https://gitlab.example.com/api/v4/templates/dockerfiles"
```

レスポンス例: 

```json
[
  {
    "key": "Binary",
    "name": "Binary"
  },
  {
    "key": "Binary-alpine",
    "name": "Binary-alpine"
  },
  {
    "key": "Binary-scratch",
    "name": "Binary-scratch"
  },
  {
    "key": "Golang",
    "name": "Golang"
  },
  {
    "key": "Golang-alpine",
    "name": "Golang-alpine"
  },
  {
    "key": "Golang-scratch",
    "name": "Golang-scratch"
  },
  {
    "key": "HTTPd",
    "name": "HTTPd"
  },
  {
    "key": "Node",
    "name": "Node"
  },
  {
    "key": "Node-alpine",
    "name": "Node-alpine"
  },
  {
    "key": "OpenJDK",
    "name": "OpenJDK"
  },
  {
    "key": "PHP",
    "name": "PHP"
  },
  {
    "key": "Python",
    "name": "Python"
  },
  {
    "key": "Python-alpine",
    "name": "Python-alpine"
  },
  {
    "key": "Python2",
    "name": "Python2"
  },
  {
    "key": "Ruby",
    "name": "Ruby"
  },
  {
    "key": "Ruby-alpine",
    "name": "Ruby-alpine"
  },
  {
    "key": "Rust",
    "name": "Rust"
  },
  {
    "key": "Swift",
    "name": "Swift"
  }
]
```

## 単一のDockerfileテンプレートを取得する {#retrieve-a-single-dockerfile-template}

単一のDockerfileテンプレートを取得します。

```plaintext
GET /templates/dockerfiles/:key
```

| 属性 | 型   | 必須 | 説明 |
|-----------|--------|----------|-------------|
| `key`     | 文字列 | はい      | Dockerfileテンプレートのキー |

リクエスト例: 

```shell
curl "https://gitlab.example.com/api/v4/templates/dockerfiles/Binary"
```

レスポンス例: 

```json
{
  "name": "Binary",
  "content": "# This file is a template, and might need editing before it works on your project.\n# This Dockerfile installs a compiled binary into a bare system.\n# You must either commit your compiled binary into source control (not recommended)\n# or build the binary first as part of a CI/CD pipeline.\n\nFROM buildpack-deps:buster\n\nWORKDIR /usr/local/bin\n\n# Change `app` to whatever your binary is called\nAdd app .\nCMD [\"./app\"]\n"
}
```
