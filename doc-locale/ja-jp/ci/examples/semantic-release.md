---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: semantic-releaseを使用して、npmパッケージをGitLabパッケージレジストリに公開する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このガイドでは、[GitLabパッケージレジストリ](../../user/packages/npm_registry/_index.md)にnpmパッケージを自動的に公開する方法を、[semantic-release](https://github.com/semantic-release/semantic-release)を使用して示します。

完全な[example source](https://gitlab.com/gitlab-examples/semantic-release-npm)を表示するか、フォークできます。

## モジュールを初期化する {#initialize-the-module}

1. ターミナルを開き、プロジェクトのリポジトリに移動します。
1. `npm init`を実行します。モジュールを[パッケージレジストリの命名規則](../../user/packages/npm_registry/_index.md#naming-convention)に従って命名します。たとえば、プロジェクトのパスが`gitlab-examples/semantic-release-npm`の場合、モジュールに`@gitlab-examples/semantic-release-npm`という名前を付けます。
1. 次のnpmパッケージをインストールします:

   ```shell
   npm install semantic-release @semantic-release/git @semantic-release/gitlab @semantic-release/npm --save-dev
   ```

1. 次のプロパティをモジュールの`package.json`に追加します:

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

1. `files`キーを、公開されるモジュールに含めるすべてのファイルを選択するglobパターンで更新します。`files`に関する詳細は、[npmドキュメント](https://docs.npmjs.com/cli/v6/configuring-npm/package-json/#files)にあります。
1. プロジェクトに`.gitignore`ファイルを追加して、`node_modules`をコミットするのを避けます:

   ```plaintext
   node_modules
   ```

## パイプラインを設定する {#configure-the-pipeline}

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

この例では、単一のジョブである`publish`を使用してパイプラインを設定し、`semantic-release`を実行します。semantic-releaseライブラリはnpmパッケージの新しいバージョンを公開し、(必要に応じて)新しいGitLabリリースを作成します。

デフォルトの`before_script`は、`publish`ジョブ中にパッケージレジストリへの認証に使用される一時的な`.npmrc`を生成します。

## CI/CD変数を設定する {#set-up-cicd-variables}

パッケージの公開の一部として、semantic-releaseは`package.json`のバージョン番号を増やします。semantic-releaseがこの変更をコミットしてGitLabにプッシュするには、パイプラインに`GITLAB_TOKEN`という名前のカスタムCI/CD変数が必要です。この変数を作成するには:

1. 左サイドバーを開きます。
1. **設定** > **アクセストークン**を選択します。
1. プロジェクトで、**新しいトークンを追加**を選択します。
1. **トークン名**ボックスに、トークン名を入力します。
   <!-- markdownlint-disable MD044 -->
1. **スコープを選択**で、**API**チェックボックスを選択します。
   <!-- markdownlint-enable MD044 -->
1. **プロジェクトアクセストークンを作成**を選択します。
1. トークンの値をコピーします。
1. 左サイドバーで、**設定** > **CI/CD**を選択します。
1. **変数**を展開します。
1. **変数を追加**を選択します。
1. **表示レベル**で、**マスクする**を選択します。
1. **キー**ボックスに、`GITLAB_TOKEN`と入力します。
1. **値**ボックスに、トークンの値を入力します。
1. **変数を追加**を選択します。

## semantic-releaseを設定する {#configure-semantic-release}

semantic-releaseは、プロジェクト内の`.releaserc.json`ファイルから設定情報を取得します。リポジトリのルートに`.releaserc.json`を作成します:

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

以前のsemantic-releaseの設定例では、ブランチ名をプロジェクトのデフォルトのブランチに変更できます。

## リリースの公開を開始する {#begin-publishing-releases}

次のようなコミットメッセージでコミットを作成して、パイプラインをテストします:

```plaintext
fix: testing patch releases
```

コミットをデフォルトのブランチにプッシュします。パイプラインは、プロジェクトの**リリース**ページに新しいリリース (`v1.0.0`) を作成し、プロジェクトの**パッケージレジストリ**ページにパッケージの新しいバージョンを公開します。

マイナーリリースを作成するには、次のようなコミットメッセージを使用します:

```plaintext
feat: testing minor releases
```

または、破壊的な変更の場合は:

```plaintext
feat: testing major releases

BREAKING CHANGE: This is a breaking change.
```

コミットメッセージがリリースにマップされる方法の詳細については、[semantic-releaseのドキュメント](https://github.com/semantic-release/semantic-release#how-does-it-work)を参照してください。

## プロジェクトでモジュールを使用する {#use-the-module-in-a-project}

公開されたモジュールを使用するには、そのモジュールに依存するプロジェクトに`.npmrc`ファイルを追加します。たとえば、[example project](https://gitlab.com/gitlab-examples/semantic-release-npm)のモジュールを使用するには:

```plaintext
@gitlab-examples:registry=https://gitlab.com/api/v4/packages/npm/
```

次に、モジュールをインストールします:

```shell
npm install --save @gitlab-examples/semantic-release-npm
```

## トラブルシューティング {#troubleshooting}

### 削除されたGitタグが再表示される {#deleted-git-tags-reappear}

リポジトリから削除された[Gitタグ](../../user/project/repository/tags/_index.md)は、GitLab Runnerがリポジトリのキャッシュされたバージョンを使用している場合に`semantic-release`によって再作成されることがあります。ジョブがタグをまだ持っているキャッシュされたリポジトリを持つRunner上で実行される場合、`semantic-release`はmainリポジトリにそのタグを再作成します。

この動作を回避するには、次のいずれかを実行できます:

- Runnerを[`GIT_STRATEGY: clone`](../runners/configure_runners.md#git-strategy)で設定します。
- [`git fetch --prune-tags`コマンド](https://git-scm.com/docs/git-fetch#Documentation/git-fetch.txt---prune-tags)をCI/CDスクリプトに含めます。
