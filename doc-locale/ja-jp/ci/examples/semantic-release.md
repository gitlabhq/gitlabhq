---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: semantic-releaseを使用してnpmパッケージをGitLabパッケージレジストリに公開します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このガイドでは、[semantic-release](https://github.com/semantic-release/semantic-release)を使用して、[GitLabパッケージレジストリ](../../user/packages/npm_registry/_index.md)にNPMパッケージを自動的に公開する方法を説明します。

完全な[サンプルソース](https://gitlab.com/gitlab-examples/semantic-release-npm)を表示またはフォークすることもできます。

## モジュールを初期化します {#initialize-the-module}

1. ターミナルを開き、プロジェクトのリポジトリに移動します。
1. `npm init`を実行します。[パッケージレジストリの命名規則](../../user/packages/npm_registry/_index.md#naming-convention)に従ってモジュールに名前を付けます。たとえば、プロジェクトのパスが`gitlab-examples/semantic-release-npm`の場合、モジュールに`@gitlab-examples/semantic-release-npm`という名前を付けます。

1. 次のNPMパッケージをインストールします。

   ```shell
   npm install semantic-release @semantic-release/git @semantic-release/gitlab @semantic-release/npm --save-dev
   ```

1. 次のプロパティをモジュールの`package.json`に追加します。

   ```json
   {
     "scripts": {
       "semantic-release": "semantic-release"
     },
     "publishConfig": {
       "access": "public"
     },
     "files": [ <path(s) to files here> ]
   }
   ```

1. 公開されたモジュールに含めるすべてのファイルを選択するグロブパターンで`files`キーを更新します。`files`の詳細については、[NPMドキュメント](https://docs.npmjs.com/cli/v6/configuring-npm/package-json/#files)をご覧ください。

1. `node_modules`のコミットを回避するために、プロジェクトに`.gitignore`ファイルを追加します。

   ```plaintext
   node_modules
   ```

## パイプラインを構成する {#configure-the-pipeline}

次の内容を含む`.gitlab-ci.yml`を作成します。

```yaml
default:
  image: node:latest
  before_script:
    - npm ci --cache .npm --prefer-offline
    - |
      {
        echo "@${CI_PROJECT_ROOT_NAMESPACE}:registry=${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/"
        echo "${CI_API_V4_URL#https?}/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=\${CI_JOB_TOKEN}"
      } | tee -a .npmrc
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - .npm/

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH

variables:
  NPM_TOKEN: ${CI_JOB_TOKEN}

stages:
  - release

publish:
  stage: release
  script:
    - npm run semantic-release
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

この例では、`semantic-release`を実行する単一のジョブ`publish`を使用してパイプラインを構成します。semantic-releaseライブラリは、NPMパッケージの新しいバージョンを公開し、新しいGitLabリリースを作成します（必要な場合）。

デフォルトの`before_script`は、`publish`ジョブ中にパッケージレジストリへの認証に使用される一時的な`.npmrc`を生成します。

## CI/CD変数をセットアップする {#set-up-cicd-variables}

パッケージの公開の一環として、semantic-releaseは`package.json`のバージョン番号を増やします。semantic-releaseがこの変更をコミットしてGitLabにプッシュするには、パイプラインに`GITLAB_TOKEN`という名前のカスタムCI/CD変数が必要です。この変数を作成するには、次の手順を実行します。

<!-- markdownlint-disable MD044 -->

1. 左側のサイドバーを開きます。
1. **設定** > **アクセストークン**を選択します。
1. プロジェクトで、**新しいトークンを追加**を選択します。
1. **トークン名**ボックスに、トークン名を入力します。
1. **スコープを選択**で、**API**チェックボックスをオンにします。
1. **プロジェクトアクセストークンを作成**を選択します。
1. トークンの値をコピーします。
1. 左側のサイドバーで、**設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. **変数を追加**を選択します。
1. **可視化**で**マスクする**を選択します。
1. **キー**ボックスに、`GITLAB_TOKEN`と入力します。
1. **値**ボックスに、トークンの値を入力します。
1. **変数を追加**を選択します。
<!-- markdownlint-enable MD044 -->

## semantic-releaseを構成する {#configure-semantic-release}

semantic-releaseは、プロジェクト内の`.releaserc.json`ファイルから構成情報をプルします。リポジトリのルートに`.releaserc.json`を作成します。

```json
{
  "branches": ["main"],
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/gitlab",
    "@semantic-release/npm",
    [
      "@semantic-release/git",
      {
        "assets": ["package.json"],
        "message": "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
      }
    ]
  ]
}
```

前のsemantic-release構成例では、ブランチ名をプロジェクトのデフォルトのブランチに変更できます。

## リリースの公開を開始する {#begin-publishing-releases}

次のようなメッセージでコミットを作成して、パイプラインをテストします。

```plaintext
fix: testing patch releases
```

デフォルトのブランチにコミットをプッシュします。パイプラインは、プロジェクトの**リリース**ページに新しいリリース（`v1.0.0`）を作成し、プロジェクトの**パッケージレジストリ**ページにパッケージの新しいバージョンを公開する必要があります。

マイナーリリースを作成するには、次のようなコミットメッセージを使用します。

```plaintext
feat: testing minor releases
```

または、破壊的な変更の場合は、次のようにします。

```plaintext
feat: testing major releases

BREAKING CHANGE: This is a breaking change.
```

コミットメッセージがリリースにどのようにマップされるかの詳細については、[semantic-releasesのドキュメント](https://github.com/semantic-release/semantic-release#how-does-it-work)をご覧ください。

## プロジェクトでモジュールを使用する {#use-the-module-in-a-project}

公開されたモジュールを使用するには、モジュールに依存するプロジェクトに`.npmrc`ファイルを追加します。たとえば、[サンプルプロジェクト](https://gitlab.com/gitlab-examples/semantic-release-npm)のモジュールを使用するには、次のようにします。

```plaintext
@gitlab-examples:registry=https://gitlab.com/api/v4/packages/npm/
```

次に、モジュールをインストールします。

```shell
npm install --save @gitlab-examples/semantic-release-npm
```

## トラブルシューティング {#troubleshooting}

### 削除されたGitタグが再び表示される {#deleted-git-tags-reappear}

リポジトリから削除された[Gitタグ](../../user/project/repository/tags/_index.md)は、GitLab Runnerがキャッシュされたリポジトリのバージョンを使用している場合、`semantic-release`によって再作成されることがあります。ジョブがタグをまだ持っているキャッシュされたリポジトリを持つRunnerで実行される場合、`semantic-release`はmainのリポジトリにタグを再作成します。

この動作を回避するには、次のいずれかを実行します。

- [`GIT_STRATEGY: clone`](../runners/configure_runners.md#git-strategy)でRunnerを構成します。
- CI/CDスクリプトに[`git fetch --prune-tags`コマンド](https://git-scm.com/docs/git-fetch#Documentation/git-fetch.txt---prune-tags)を含めます。
