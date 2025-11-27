---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パッケージレジストリ内のComposerパッケージ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< alert type="warning" >}}

GitLabのComposerパッケージレジストリは開発中であり、機能が限られているため、本番環境での使用には適していません。この[エピック](https://gitlab.com/groups/gitlab-org/-/epics/6817)では、本番環境で使用できるようになるまでの残りの作業とタイムラインについて詳しく説明します。

{{< /alert >}}

プロジェクトのパッケージレジストリに[Composer](https://getcomposer.org/)パッケージを公開します。その後、依存関係として使用する必要があるときはいつでもパッケージをインストールします。

Composerクライアントが使用する特定のAPIエンドポイントのドキュメントについては、[Composer APIドキュメント](../../../api/packages/composer.md)を参照してください。

Composer v2.0を推奨します。Composer v1.0もサポートされていますが、非常に多数のパッケージを含むグループで作業する場合、パフォーマンスが低下します。

[Composerパッケージをビルドする方法](../workflows/build_packages.md#composer)をご覧ください。

## APIを使用してComposerパッケージを公開する {#publish-a-composer-package-by-using-the-api}

プロジェクトにアクセスできるすべてのユーザーが依存関係としてパッケージを使用できるように、Composerパッケージをパッケージレジストリに公開します。

前提要件: 

- GitLabリポジトリ内のパッケージ。Composerパッケージは、[Composer仕様](https://getcomposer.org/doc/04-schema.md#version)に基づいてバージョニングする必要があります。バージョンが無効な場合（たとえば、3つのドット（`1.0.0.0`）がある場合）、公開時にエラー（`Validation failed: Version is invalid`）が発生します。
- プロジェクトルートディレクトリにある有効な`composer.json`ファイル。
- GitLabリポジトリでパッケージ機能が有効になっている。
- プロジェクトは、[プロジェクトの概要ページ](../../project/working_with_projects.md#find-the-project-id)に表示されます。
- 次のトークンタイプのうちの1つ:
  - スコープが`api`に設定された[パーソナルアクセストークン](../../profile/personal_access_tokens.md)。
  - `write_package_registry`にスコープが設定された[デプロイトークン](../../project/deploy_tokens/_index.md)。

パーソナルアクセストークンを使用してパッケージを公開するには:

- [パッケージAPI](../../../api/packages.md)に`POST`リクエストを送信します。

  たとえば、`curl`を使用できます:

  ```shell
  curl --fail-with-body --data tag=<tag> "https://__token__:<personal-access-token>@gitlab.example.com/api/v4/projects/<project_id>/packages/composer"
  ```

  - `<personal-access-token>`は、ユーザー名のパーソナルアクセストークンです。
  - `<project_id>`はプロジェクトです。
  - `<tag>`は、公開するバージョンのGitリポジトリのタグ名です。ブランチを公開するには、`tag=<tag>`の代わりに`branch=<branch>`を使用します。

デプロイトークンを使用してパッケージを公開するには:

- [パッケージAPI](../../../api/packages.md)に`POST`リクエストを送信します。

  たとえば、`curl`を使用できます:

  ```shell
  curl --fail-with-body --data tag=<tag> --header "Deploy-Token: <deploy-token>" "https://gitlab.example.com/api/v4/projects/<project_id>/packages/composer"
  ```

  - `<deploy-token>`は、デプロイトークンです
  - `<project_id>`はプロジェクトです。
  - `<tag>`は、公開するバージョンのGitリポジトリのタグ名です。ブランチを公開するには、`tag=<tag>`の代わりに`branch=<branch>`を使用します。

**デプロイ** > **パッケージレジストリ**に移動し、**Composer**タブを選択すると、公開されたパッケージを表示できます。

## CI/CDを使用してComposerパッケージを公開する {#publish-a-composer-package-by-using-cicd}

CI/CDプロセスの一部として、Composerパッケージをパッケージレジストリに公開できます。

1. `.gitlab-ci.yml`ファイルで`CI_JOB_TOKEN`を指定します:

   ```yaml
   stages:
     - deploy

   deploy:
     stage: deploy
     script:
       - apk add curl
       - 'curl --fail-with-body --header "Job-Token: $CI_JOB_TOKEN" --data tag=<tag> "${CI_API_V4_URL}/projects/$CI_PROJECT_ID/packages/composer"'
     environment: production
   ```

1. パイプラインを実行します。

公開されたパッケージを表示するには、**デプロイ** > **パッケージレジストリ**に移動し、**Composer**タブを選択します。

### CI/CDテンプレートを使用します {#use-a-cicd-template}

より詳細なComposer CI/CDファイルは、`.gitlab-ci.yml`テンプレートとしても使用できます:

1. 左側のサイドバーで**Project overview**（プロジェクトの概要）を選択します。
1. ファイルリストの上にある**CI/CDを設定**を選択します。このボタンを使用できない場合は、**CI/CD Configuration**（CI/CD構成）、次に**編集**を選択します。
1. **テンプレートを適用**リストから、**Composer**を選択します。

{{< alert type="warning" >}}

既存のCI/CDファイルを上書きする場合を除き、保存しないでください。

{{< /alert >}}

## 名前またはバージョンが同じパッケージを公開する {#publishing-packages-with-the-same-name-or-version}

公開する場合:

- 異なるデータを持つ同じパッケージは、既存のパッケージを上書きします。
- 同じデータを持つ同じパッケージの場合、`400 Bad request`エラーが発生します。

## Composerパッケージをインストールする {#install-a-composer-package}

依存関係として使用できるように、パッケージレジストリからパッケージをインストールします。

前提要件: 

- パッケージレジストリ内のパッケージ。
- パッケージレジストリは、パッケージの公開を担当するプロジェクトで有効になっています。
- グループのホームページにあるグループID。
- 次のトークンタイプのいずれか:
  - スコープが最小で`api`に設定された[パーソナルアクセストークン](../../profile/personal_access_tokens.md)。
  - スコープが`read_package_registry`と`write_package_registry`のどちらか、または両方に設定された[デプロイトークン](../../project/deploy_tokens/_index.md)。
  - [CI/CDジョブトークン](../../../ci/jobs/ci_job_token.md)。

パッケージをインストールする:

1. インストールするパッケージ名とバージョンとともに、パッケージレジストリURLをプロジェクトの`composer.json`ファイルに追加します:

   - グループのパッケージレジストリに接続します:

     ```shell
     composer config repositories.<group_id> composer https://gitlab.example.com/api/v4/group/<group_id>/-/packages/composer/packages.json
     ```

   - 必要なパッケージバージョンを設定します:

     ```shell
     composer require <package_name>:<version>
     ```

   `composer.json`ファイルの結果:

   ```json
   {
     ...
     "repositories": {
       "<group_id>": {
         "type": "composer",
         "url": "https://gitlab.example.com/api/v4/group/<group_id>/-/packages/composer/packages.json"
       },
       ...
     },
     "require": {
       ...
       "<package_name>": "<version>"
     },
     ...
   }
   ```

   この設定は、次のコマンドで解除できます:

   ```shell
   composer config --unset repositories.<group_id>
   ```

   - `<group_id>`、はグループIDです。
   - `<package_name>`は、パッケージの`composer.json`ファイルで定義されているパッケージ名です。
   - `<version>`は、パッケージのバージョンです。

1. GitLabの認証情報を使用して`auth.json`ファイルを作成します:

   パーソナルアクセストークンを使用する場合:

   ```shell
   composer config gitlab-token.<DOMAIN-NAME> <personal_access_token>
   ```

   `auth.json`ファイルの結果:

   ```json
   {
     ...
     "gitlab-token": {
       "<DOMAIN-NAME>": "<personal_access_token>",
       ...
     }
   }
   ```

   デプロイトークンの使用:

   ```shell
   composer config gitlab-token.<DOMAIN-NAME> <deploy_token_username> <deploy_token>
   ```

   `auth.json`ファイルの結果:

   ```json
   {
     ...
     "gitlab-token": {
       "<DOMAIN-NAME>": {
         "username": "<deploy_token_username>",
         "token": "<deploy_token>",
       ...
     }
   }
   ```

   CI/CDジョブトークンを使用する:

   ```shell
   composer config -- gitlab-token.<DOMAIN-NAME> gitlab-ci-token "${CI_JOB_TOKEN}"
   ```

   `auth.json`ファイルの結果:

   ```json
   {
     ...
     "gitlab-token": {
       "<DOMAIN-NAME>": {
         "username": "gitlab-ci-token",
         "token": "<ci-job-token>",
       ...
     }
   }
   ```

   この設定は、次のコマンドで解除できます:

   ```shell
   composer config --unset --auth gitlab-token.<DOMAIN-NAME>
   ```

   - `<DOMAIN-NAME>`は、GitLabインスタンスURL `gitlab.com`または`gitlab.example.com`です。
   - スコープが`api`に設定された`<personal_access_token>`、またはスコープが`read_package_registry`および/または`write_package_registry`に設定された`<deploy_token>`。

1. GitLabセルフマネージドを使用している場合は、`composer.json`に`gitlab-domains`を追加します。

   ```shell
   composer config gitlab-domains gitlab01.example.com gitlab02.example.com
   ```

   `composer.json`ファイルの結果:

   ```json
   {
     ...
     "repositories": [
       { "type": "composer", "url": "https://gitlab.example.com/api/v4/group/<group_id>/-/packages/composer/packages.json" }
     ],
     "config": {
       ...
       "gitlab-domains": ["gitlab01.example.com", "gitlab02.example.com"]
     },
     "require": {
       ...
       "<package_name>": "<version>"
     },
     ...
   }
   ```

   この設定は、次のコマンドで解除できます:

   ```shell
   composer config --unset gitlab-domains
   ```

   {{< alert type="note" >}}

   GitLab.comでは、Composerは`auth.json`からのGitLabトークンをデフォルトでプライベートトークンとして使用します。`composer.json`で`gitlab-domains`の定義がない場合、Composerは、ユーザー名としてトークン、パスワードなしで、GitLabトークンを基本認証として使用します。これにより、401エラーが発生します。

   {{< /alert >}}

1. `composer.json`ファイルと`auth.json`ファイルが構成されている場合、次を実行してパッケージをインストールできます:

   ```shell
   composer update
   ```

   または、単一のパッケージをインストールするには:

   ```shell
   composer req <package-name>:<package-version>
   ```

{{< alert type="warning" >}}

`auth.json`ファイルをリポジトリにコミットしないでください。CI/CDジョブからパッケージをインストールするには、[`composer config`](https://getcomposer.org/doc/articles/handling-private-packages.md#satis)ツールを、[GitLab CI/CD変数](../../../ci/variables/_index.md)または[HashiCorp Vault](../../../ci/secrets/_index.md)に格納されているアクセストークンとともに使用することを検討してください。

{{< /alert >}}

### ソースからインストールする {#install-from-source}

Gitリポジトリを直接プルすることで、ソースからインストールできます。これを行うには、次のいずれかを実行します:

- `--prefer-source`オプションを使用します:

  ```shell
  composer update --prefer-source
  ```

- `composer.json`で、[`preferred-install`フィールドを`config`キー](https://getcomposer.org/doc/06-config.md#preferred-install)の下で使用します:

  ```json
  {
    ...
    "config": {
      "preferred-install": {
        "<package name>": "source"
      }
    }
    ...
   }
  ```

#### SSHアクセス {#ssh-access}

{{< history >}}

- GitLab 16.4で`composer_use_ssh_source_urls`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119739)されました。デフォルトでは無効になっています。
- GitLab 16.5の[GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/329246)で有効になりました。
- GitLab 16.6で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135467)になりました。機能フラグ`composer_use_ssh_source_urls`は削除されました。

{{< /history >}}

ソースからインストールすると、`composer`はプロジェクトのGitリポジトリへのアクセスを設定します。プロジェクトの表示レベルに応じて、アクセスの種類が異なります:

- パブリックプロジェクトでは、`https` Git URLが使用されます。[HTTPSを使用してリポジトリをクローン](../../../topics/git/clone.md#clone-with-https)できることを確認してください。
- 内部プロジェクトまたはプライベートプロジェクトでは、`ssh` Git URLが使用されます。[SSHを使用してリポジトリをクローン](../../../topics/git/clone.md#clone-with-ssh)できることを確認してください。

[GitLab CI/CDでSSHキー](../../../ci/jobs/ssh_keys.md)を使用すると、CI/CDジョブから`ssh` Git URLにアクセスできます。

### デプロイトークンの操作 {#working-with-deploy-tokens}

Composerパッケージはグループレベルでアクセスされますが、グループまたはプロジェクトのデプロイトークンを使用してアクセスできます:

- グループデプロイトークンは、そのグループまたはサブグループのプロジェクトに公開されたすべてのパッケージにアクセスできます。
- プロジェクトデプロイトークンは、その特定のプロジェクトに公開されたパッケージにのみアクセスできます。

## トラブルシューティング {#troubleshooting}

### キャッシュ {#caching}

パフォーマンスを向上させるため、Composerはパッケージに関連するファイルをキャッシュします。Composerはデータを自動的に削除しません。新しいパッケージがインストールされるにつれて、キャッシュは増加します。問題が発生した場合は、次のコマンドでキャッシュをクリアします:

```shell
composer clearcache
```

### `composer install`を使用する場合の認可要件 {#authorization-requirement-when-using-composer-install}

[パッケージアーカイブのダウンロード](../../../api/packages/composer.md#download-a-package-archive)エンドポイントには、認可が必要です。`composer install`を使用しているときに認証情報のプロンプトが表示された場合は、[パッケージのインストール](#install-a-composer-package)セクションの手順に従って、`auth.json`ファイルを作成してください。

### `The file composer.json was not found`での公開が失敗する {#publish-fails-with-the-file-composerjson-was-not-found}

`The file composer.json was not found`というエラーが表示されることがあります。

このイシューは、[パッケージの公開に関する設定要件](#publish-a-composer-package-by-using-the-api)が満たされていない場合に発生します。

エラーを解決するには、`composer.json`ファイルをプロジェクトルートディレクトリにコミットします。

## サポートされているCLIコマンド {#supported-cli-commands}

GitLab Composerリポジトリは、次のComposer CLIコマンドをサポートしています:

- `composer install`: Composerの依存関係をインストールします。
- `composer update`: Composerの依存関係の最新バージョンをインストールします。
