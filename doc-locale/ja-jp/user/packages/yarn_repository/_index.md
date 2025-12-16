---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Yarnでパッケージを公開する
---

[Yarn 1 (Classic)](https://classic.yarnpkg.com)と[Yarn 2+](https://yarnpkg.com)を使用して、パッケージを公開およびインストールできます。

デプロイコンテナで使用されているYarnのバージョンを調べるには、`yarn --version`を、`yarn publish`を呼び出すジョブがあるCI/CDスクリプトジョブの`script`ブロックで実行します。Yarnのバージョンはパイプラインの出力に表示されます。

## パッケージレジストリに対する認証 {#authenticating-to-the-package-registry}

パッケージレジストリとやり取りするには、トークンが必要です。実現しようとしていることに応じて、さまざまなトークンを利用できます。詳細については、[トークンに関するガイダンス](../package_registry/supported_functionality.md#authenticate-with-the-registry)参照してください。

- 組織が2要素認証（2FA）を使用している場合、スコープが`api`に設定された[パーソナルアクセストークン](../../profile/personal_access_tokens.md)を使用する必要があります。
- CI/CDパイプラインでパッケージを公開する場合、プライベートRunnerで[CI/CDジョブトークン](../../../ci/jobs/ci_job_token.md)を使用できます。インスタンスRunnerの[変数を登録](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)することもできます。

### 公開用にYarnを設定する {#configure-yarn-for-publication}

パッケージレジストリに公開するようにYarnを設定するには、`.yarnrc.yml`ファイルを編集します。このファイルは、`package.json`ファイルと同じ、プロジェクトのルートディレクトリにあります。

- `.yarnrc.yml`を編集し、次の設定を追加します:

  ```yaml
  npmScopes:
    <my-org>:
      npmPublishRegistry: 'https://<domain>/api/v4/projects/<project_id>/packages/npm/'
      npmAlwaysAuth: true
      npmAuthToken: '<token>'
  ```

  この設定では、次のようになります:

  - `<my-org>`を組織スコープに置き換えます。`@`記号は含めないでください。
  - `<domain>`をドメイン名に置き換えます。
  - `<project_id>`をプロジェクトのIDに置き換えます。これは[プロジェクトの概要ページ](../../project/working_with_projects.md#find-the-project-id)にあります。
  - `<token>`をデプロイトークン、グループアクセストークン、プロジェクトアクセストークン、またはパーソナルアクセストークンに置き換えます。

Yarn Classicでは、`publishConfig["@scope:registry"]`を使用したスコープレジストリはサポートされていません。詳細については、[Yarnプルリクエスト7829](https://github.com/yarnpkg/yarn/pull/7829)を参照してください。代わりに、`publishConfig`を`registry`に設定します。`package.json`ファイル。

## パッケージを公開する {#publish-a-package}

コマンドラインから、またはGitLab CI/CDでパッケージを公開できます。

### コマンドラインを使用する {#with-the-command-line}

パッケージを手動で公開するには:

- 次のコマンドを実行します:

  ```shell
  # Yarn 1 (Classic)
  yarn publish

  # Yarn 2+
  yarn npm publish
  ```

### CI/CDを使用する {#with-cicd}

インスタンスRunner（デフォルト）またはプライベートRunner（高度）を使用して、パッケージを自動的に公開できます。CI/CDで公開するときにパイプライン変数を使用できます。

{{< tabs >}}

{{< tab title="インスタンスRunner" >}}

1. プロジェクトまたはグループの認証トークンを作成します:

   1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
   1. 左側のサイドバーで、**設定** > **リポジトリ** > **Deploy Tokens**（デプロイトークン）を選択します。
   1. `read_package_registry`および`write_package_registry`スコープを持つデプロイトークンを作成し、生成されたトークンをコピーします。
   1. 左側のサイドバーで、**設定** > **CI/CD** > **変数**を選択します。
   1. `Add variable`を選択し、次の設定を使用します:

   | フィールド              | 値                        |
   |--------------------|------------------------------|
   | キー:                 | `NPM_AUTH_TOKEN`             |
   | 値              | `<DEPLOY-TOKEN>` |
   | タイプ:               | 変数                     |
   | 保護された変数 | `CHECKED`                    |
   | マスクされた変数      | `CHECKED`                    |
   | 変数を展開します。    | `CHECKED`                    |

1. オプション。保護された変数を使用するには:

   1. Yarnパッケージのコードソースを含むリポジトリに移動します。
   1. 左側のサイドバーで、**設定** > **リポジトリ**を選択します。
      - タグ付けのあるブランチからビルドする場合は、**保護されたタグ**を選択し、セマンティックバージョニングのために`v*`（ワイルドカード）を追加します。
      - タグ付けのないブランチからビルドする場合は、**ブランチルール**を選択します。

1. 作成した`NPM_AUTH_TOKEN`を、パッケージプロジェクトのルートディレクトリにある、`package.json`が見つかる`.yarnrc.yml`設定に追加します:

   ```yaml
   npmScopes:
     <my-org>:
       npmPublishRegistry: '${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/'
       npmAlwaysAuth: true
       npmAuthToken: '${NPM_AUTH_TOKEN}'
   ```

   この設定で、`@`記号を除外して、`<my-org>`を組織スコープに置き換えます。

{{< /tab >}}

{{< tab title="プライベートRunner" >}}

1. `package.json`が配置されているパッケージプロジェクトのルートディレクトリにある`.yarnrc.yml`設定に、`CI_JOB_TOKEN`を追加します:

   ```yaml
   npmScopes:
     <my-org>:
       npmPublishRegistry: '${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/'
       npmAlwaysAuth: true
       npmAuthToken: '${CI_JOB_TOKEN}'
   ```

   この設定で、`@`記号を除外して、`<my-org>`を組織スコープに置き換えます。

1. `.yarnrc.yml`を含むGitLabプロジェクトで、`.gitlab-ci.yml`ファイルを編集または作成します。たとえば、任意のタグプッシュでのみトリガーするには:

   Yarn 1の場合:

   ```yaml
   image: node:lts

   stages:
     - deploy

   rules:
   - if: $CI_COMMIT_TAG

   deploy:
     stage: deploy
     script:
       - yarn publish
   ```

   Yarn 2以降:

   ```yaml
   image: node:lts

   stages:
     - deploy

   rules:
     - if: $CI_COMMIT_TAG

   deploy:
     stage: deploy
     before_script:
       - corepack enable
       - yarn set version stable
     script:
       - yarn npm publish
   ```

パイプラインが実行されると、パッケージがパッケージレジストリに追加されます。

{{< /tab >}}

{{< /tabs >}}

## パッケージをインストールする {#install-a-package}

インスタンスまたはプロジェクトからインストールできます。複数のパッケージの名前とバージョンが同じ場合、パッケージをインストールすると、最後に公開されたパッケージのみが取得されます。

### スコープパッケージ名 {#scoped-package-names}

インスタンスからインストールするには、パッケージに[スコープ](https://docs.npmjs.com/misc/scope/)を指定して名前を付ける必要があります。`.yarnrc.yml`ファイルで、`package.json`の`publishConfig`オプションを使用して、パッケージのスコープを設定できます。プロジェクトまたはグループからインストールする場合は、パッケージの命名規則に従う必要はありません。

パッケージスコープは`@`で始まり、形式`@owner/package-name`に従います:

- `@owner`は、パッケージソースコードを含むプロジェクトのルートではなく、パッケージをホストするトップレベルグループです。
- パッケージ名は任意に設定できます。

例: 

| プロジェクトURL                                                       | パッケージレジストリ     | 組織スコープ | パッケージのフルネーム           |
|-------------------------------------------------------------------|----------------------|--------------------|-----------------------------|
| `https://gitlab.com/<my-org>/<group-name>/<package-name-example>` | パッケージ名の例 | `@my-org`          | `@my-org/package-name`      |
| `https://gitlab.com/<example-org>/<group-name>/<project-name>`    | プロジェクト名:         | `@example-org`     | `@example-org/project-name` |

### インスタンスからインストール {#install-from-the-instance}

同じ組織スコープで多数のパッケージを操作する場合は、インスタンスからのインストールを検討してください。

1. 組織スコープを設定します。`.yarnrc.yml`ファイルで、以下を追加します:

   ```yaml
   npmScopes:
    <my-org>:
      npmRegistryServer: 'https://<domain_name>/api/v4/packages/npm'
   ```

   - `@`記号を除外して、`<my-org>`をパッケージのインストール元のプロジェクトのルートレベルグループに置き換えます。
   - `<domain_name>`をドメイン名に置き換えます（例: `gitlab.com`）。

1. オプション。パッケージがプライベートの場合は、パッケージレジストリへのアクセスを設定する必要があります:

   ```yaml
   npmRegistries:
     //<domain_name>/api/v4/packages/npm:
       npmAlwaysAuth: true
       npmAuthToken: '<token>'
   ```

   - `<domain_name>`をドメイン名に置き換えます（例: `gitlab.com`）。
   - `<token>`を、デプロイトークン（推奨）、グループアクセス、プロジェクトアクセス、またはパーソナルアクセスに置き換えます。

1. [Yarnでパッケージをインストール](#install-with-yarn)。

### グループまたはプロジェクトからインストール {#install-from-a-group-or-project}

1回限りのパッケージがある場合は、グループまたはプロジェクトからインストールできます。

{{< tabs >}}

{{< tab title="グループから" >}}

1. グループスコープを設定します。`.yarnrc.yml`ファイルで、以下を追加します:

   ```yaml
   npmScopes:
     <my-org>:
       npmRegistryServer: 'https://<domain_name>/api/v4/groups/<group_id>/-/packages/npm'
   ```

   - インストール元のグループを含む、`<my-org>`をトップレベルグループに置き換えます。`@`記号を除外します。
   - `<domain_name>`をドメイン名に置き換えます（例: `gitlab.com`）。
   - `<group_id>`を、[グループの概要ページ](../../group/_index.md#find-the-group-id)にあるグループIDに置き換えます。

1. オプション。パッケージがプライベートの場合は、レジストリを設定する必要があります:

   ```yaml
   npmRegistries:
     //<domain_name>/api/v4/groups/<group_id>/-/packages/npm:
       npmAlwaysAuth: true
       npmAuthToken: "<token>"
   ```

   - `<domain_name>`をドメイン名に置き換えます（例: `gitlab.com`）。
   - `<token>`を、デプロイトークン（推奨）、グループアクセス、プロジェクトアクセス、またはパーソナルアクセスに置き換えます。
   - `<group_id>`を、[グループの概要ページ](../../group/_index.md#find-the-group-id)にあるグループIDに置き換えます。

1. [Yarnでパッケージをインストール](#install-with-yarn)。

{{< /tab >}}

{{< tab title="プロジェクトから" >}}

1. プロジェクトスコープを設定します。`.yarnrc.yml`ファイルで、以下を追加します:

   ```yaml
   npmScopes:
    <my-org>:
      npmRegistryServer: "https://<domain_name>/api/v4/projects/<project_id>/packages/npm"
   ```

   - インストール元のプロジェクトを含む、`<my-org>`をトップレベルグループに置き換えます。`@`記号を除外します。
   - `<domain_name>`をドメイン名に置き換えます（例: `gitlab.com`）。
   - `<project_id>`を、[プロジェクトの概要ページ](../../project/working_with_projects.md#find-the-project-id)のプロジェクトIDに置き換えます。

1. オプション。パッケージがプライベートの場合は、レジストリを設定する必要があります:

   ```yaml
   npmRegistries:
     //<domain_name>/api/v4/projects/<project_id>/packages/npm:
       npmAlwaysAuth: true
       npmAuthToken: "<token>"
   ```

   - `<domain_name>`をドメイン名に置き換えます（例: `gitlab.com`）。
   - `<token>`を、デプロイトークン（推奨）、グループアクセス、プロジェクトアクセス、またはパーソナルアクセスに置き換えます。
   - `<project_id>`を、[プロジェクトの概要ページ](../../project/working_with_projects.md#find-the-project-id)のプロジェクトIDに置き換えます。

1. [Yarnでパッケージをインストール](#install-with-yarn)。

{{< /tab >}}

{{< /tabs >}}

### Yarnでインストール {#install-with-yarn}

{{< tabs >}}

{{< tab title="Yarn 2以降" >}}

- コマンドラインから、またはCI/CDパイプラインから`yarn add`を実行します:

```shell
yarn add @scope/my-package
```

{{< /tab >}}

{{< tab title="Yarn Classic" >}}

Yarn Classicには、`.npmrc`ファイルと`.yarnrc`ファイルの両方が必要です。詳細については、[Yarn issue 4451](https://github.com/yarnpkg/yarn/issues/4451#issuecomment-753670295)を参照してください。

1. `.npmrc`ファイルに認証情報を配置し、`.yarnrc`ファイルにスコープレジストリを配置します:

   ```shell
   # .npmrc
   ## For the instance
   //<domain_name>/api/v4/packages/npm/:_authToken='<token>'
   ## For the group
   //<domain_name>/api/v4/groups/<group_id>/-/packages/npm/:_authToken='<token>'
   ## For the project
   //<domain_name>/api/v4/projects/<project_id>/packages/npm/:_authToken='<token>'

   # .yarnrc
   ## For the instance
   '@scope:registry' 'https://<domain_name>/api/v4/packages/npm/'
   ## For the group
   '@scope:registry' 'https://<domain_name>/api/v4/groups/<group_id>/-/packages/npm/'
   ## For the project
   '@scope:registry' 'https://<domain_name>/api/v4/projects/<project_id>/packages/npm/'
   ```

1. コマンドラインから、またはCI/CDパイプラインから`yarn add`を実行します:

   ```shell
   yarn add @scope/my-package
   ```

{{< /tab >}}

{{< /tabs >}}

## 関連トピック {#related-topics}

- [npmパッケージレジストリのドキュメント](../npm_registry/_index.md#helpful-hints)
- [Yarn移行ガイド](https://yarnpkg.com/migration/guide)
- [Yarnパッケージをビルドする](../workflows/build_packages.md#yarn)

## トラブルシューティング {#troubleshooting}

### npmレジストリのパッケージレジストリでYarnを実行中にエラーが発生しました {#error-running-yarn-with-the-package-registry-for-the-npm-registry}

[Yarn](https://classic.yarnpkg.com/en/)をnpmレジストリで使用している場合は、次のようなエラーメッセージが表示されることがあります:

```shell
yarn install v1.15.2
warning package.json: No license field
info No lockfile found.
warning XXX: No license field
[1/4] 🔍  Resolving packages...
[2/4] 🚚  Fetching packages...
error An unexpected error occurred: "https://gitlab.example.com/api/v4/projects/XXX/packages/npm/XXX/XXX/-/XXX/XXX-X.X.X.tgz: Request failed \"404 Not Found\"".
info If you think this is a bug, please open a bug report with the information provided in "/Users/XXX/gitlab-migration/module-util/yarn-error.log".
info Visit https://classic.yarnpkg.com/en/docs/cli/install for documentation about this command
```

この場合、次のコマンドを実行すると、現在のディレクトリに`.yarnrc`という名前のファイルが作成されます。グローバル設定の場合はユーザーのホームディレクトリに、プロジェクトごとの設定の場合はプロジェクトのルートにいることを確認してください:

```shell
yarn config set '//gitlab.example.com/api/v4/projects/<project_id>/packages/npm/:_authToken' '<token>'
yarn config set '//gitlab.example.com/api/v4/packages/npm/:_authToken' '<token>'
```

### `yarn install`は、依存関係としてリポジトリのクローン作成に失敗します {#yarn-install-fails-to-clone-repository-as-a-dependency}

Dockerfileから`yarn install`を使用する場合、Dockerfileをビルドすると、次のようなエラーが発生する可能性があります:

```plaintext
...
#6 8.621 fatal: unable to access 'https://gitlab.com/path/to/project/': Problem with the SSL CA cert (path? access rights?)
#6 8.621 info Visit https://yarnpkg.com/en/docs/cli/install for documentation about this command.
#6 ...
```

このイシューを解決するには、[感嘆符（`!`）を追加](https://docs.docker.com/build/building/context/#negating-matches)します。[.dockerignore](https://docs.docker.com/build/building/context/#dockerignore-files)ファイルのYarn関連のすべてのパス。

```dockerfile
**

!./package.json
!./yarn.lock
...
```
