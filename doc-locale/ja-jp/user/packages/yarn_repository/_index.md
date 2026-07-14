---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Yarnでパッケージを公開する
---

[Yarn 1 (Classic)](https://classic.yarnpkg.com)と[Yarn 2+](https://yarnpkg.com)を使ってパッケージを公開およびインストールできます。

デプロイコンテナで使用されているYarnのバージョンを見つけるには、`yarn publish`を呼び出すCI/CDスクリプトのジョブブロックの`script`ブロックで`yarn --version`を実行します。Yarnのバージョンはパイプラインの出力に表示されます。

## パッケージレジストリへの認証 {#authenticating-to-the-package-registry}

パッケージレジストリとやり取りするにはトークンが必要です。達成しようとしていることに応じて、さまざまなトークンが利用可能です。詳細については、[トークンに関するガイダンス](../package_registry/supported_functionality.md#authenticate-with-the-registry)参照してください。

- 組織が2要素認証 (2FA) を使用している場合は、スコープが`api`に設定された[パーソナルアクセストークン](../../profile/personal_access_tokens.md)を使用する必要があります。
- パッケージをCI/CDパイプラインで公開する場合、プライベートRunnerで[CI/CDジョブトークン](../../../ci/jobs/ci_job_token.md)を使用できます。インスタンスRunner向けに[変数](https://docs.gitlab.com/runner/register/#register-with-a-runner-authentication-token)を登録することもできます。

### Yarnの公開 {#configure-yarn-for-publication}

パッケージレジストリに公開するようにYarnを設定するには、`.yarnrc.yml`ファイルを編集します。このファイルは、`package.json`ファイルと同じ場所にあるプロジェクトのルートディレクトリにあります。

- `.yarnrc.yml`を編集し、次の設定を追加します:

  ```yaml
  npmScopes:
    <my-org>:
      npmPublishRegistry: 'https://<domain>/api/v4/projects/<project_id>/packages/npm/'
      npmAlwaysAuth: true
      npmAuthToken: '<token>'
  ```

  この設定では、次のようになります。

  - `<my-org>`を組織のスコープに置き換えます。`@`記号は含めないでください。
  - `<domain>`をドメイン名に置き換えます。
  - `<project_id>`をプロジェクトのIDに置き換えます。[プロジェクト概要ページ](../../project/working_with_projects.md#find-the-project-id)で見つけることができます。
  - `<token>`をデプロイトークン、グループアクセストークン、プロジェクトアクセストークン、またはパーソナルアクセストークンに置き換えます。

Yarn Classicでは、`publishConfig["@scope:registry"]`を使用したスコープ付きレジストリはサポートされていません。詳細については、[Yarnプルリクエスト7829](https://github.com/yarnpkg/yarn/pull/7829)を参照してください。代わりに、`package.json`ファイルで`publishConfig`を`registry`に設定します。

## パッケージを公開する {#publish-a-package}

コマンドラインから、またはGitLab CI/CDでパッケージを公開できます。

### コマンドラインを使用 {#with-the-command-line}

パッケージを手動で公開するには:

- 次のコマンドを実行します:

  ```shell
  # Yarn 1 (Classic)
  yarn publish

  # Yarn 2+
  yarn npm publish
  ```

### CI/CDを使用 {#with-cicd}

パッケージは、インスタンスRunner (デフォルト) またはプライベートRunner (アドバンスト) を使用して自動的に公開できます。CI/CDで公開する場合、パイプライン変数を使用できます。

{{< tabs >}}

{{< tab title="インスタンスRunner" >}}

1. プロジェクトまたはグループの認証トークンを作成します:

   1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
   1. 左サイドバーで、**設定** > **リポジトリ** > **Deploy Tokens**を選択します。
   1. `read_package_registry`と`write_package_registry`のスコープを持つデプロイトークンを作成し、生成されたトークンをコピーします。
   1. 左サイドバーで、**設定** > **CI/CD** > **変数**を選択します。
   1. `Add variable`を選択し、次の設定を使用します:

   | フィールド              | 値                        |
   |--------------------|------------------------------|
   | キー                | `NPM_AUTH_TOKEN`             |
   | 値              | `<DEPLOY-TOKEN>` |
   | タイプ               | 変数                     |
   | 保護された変数 | `CHECKED`                    |
   | Mask variable      | `CHECKED`                    |
   | Expand variable    | `CHECKED`                    |

1. オプション。保護された変数を使用するには:

   1. Yarnパッケージのソースコードが含まれるリポジトリに移動します。
   1. 左サイドバーで、**設定** > **リポジトリ**を選択します。
      - タグ付きのブランチからビルドしている場合は、**保護されたタグ**を選択し、セマンティックバージョニング用に`v*` (ワイルドカード) を追加します。
      - タグなしのブランチからビルドしている場合は、**ブランチルール**を選択します。

1. 作成した`NPM_AUTH_TOKEN`を、`package.json`が見つかるパッケージプロジェクトのルートディレクトリにある`.yarnrc.yml`設定に追加します:

   ```yaml
   npmScopes:
     <my-org>:
       npmPublishRegistry: '${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/'
       npmAlwaysAuth: true
       npmAuthToken: '${NPM_AUTH_TOKEN}'
   ```

   この設定では、`<my-org>`を組織のスコープに置き換え、`@`記号は除外します。

{{< /tab >}}

{{< tab title="プライベートRunner" >}}

1. `package.json`が存在するパッケージプロジェクトのルートディレクトリにある`.yarnrc.yml`設定に`CI_JOB_TOKEN`を追加します:

   ```yaml
   npmScopes:
     <my-org>:
       npmPublishRegistry: '${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/npm/'
       npmAlwaysAuth: true
       npmAuthToken: '${CI_JOB_TOKEN}'
   ```

   この設定では、`<my-org>`を組織のスコープに置き換え、`@`記号は除外します。

1. `.yarnrc.yml`があるGitLabプロジェクトで、`.gitlab-ci.yml`ファイルを編集または作成します。例えば、任意のタグプッシュのみをトリガーするには:

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

   Yarn 2以降の場合:

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

インスタンスまたはプロジェクトからインストールできます。複数のパッケージが同じ名前とバージョンを持つ場合、パッケージをインストールする際には、最新で公開されたパッケージのみが取得されます。

### スコープ付きのパッケージ名 {#scoped-package-names}

インスタンスからインストールするには、パッケージに[スコープ](https://docs.npmjs.com/misc/scope/)を付けて命名する必要があります。パッケージのスコープは`.yarnrc.yml`ファイルと`package.json`の`publishConfig`オプションで設定できます。プロジェクトまたはグループからインストールする場合、パッケージの命名規則に従う必要はありません。

パッケージスコープは`@`で始まり、`@owner/package-name`の形式に従います:

- `@owner`は、パッケージをホストするトップレベルプロジェクトであり、パッケージのソースコードを持つプロジェクトのルートではありません。
- パッケージ名は任意です。

例: 

| プロジェクトURL                                                       | パッケージレジストリ     | 組織スコープ | パッケージのフルネーム           |
|-------------------------------------------------------------------|----------------------|--------------------|-----------------------------|
| `https://gitlab.com/<my-org>/<group-name>/<package-name-example>` | パッケージ名例 | `@my-org`          | `@my-org/package-name`      |
| `https://gitlab.com/<example-org>/<group-name>/<project-name>`    | プロジェクト名         | `@example-org`     | `@example-org/project-name` |

### インスタンスからのインストール {#install-from-the-instance}

同じ組織スコープ内の多数のパッケージを扱っている場合は、インスタンスからインストールすることを検討してください。

1. 組織のスコープを設定します。あなたの`.yarnrc.yml`ファイルに以下を追加します:

   ```yaml
   npmScopes:
    <my-org>:
      npmRegistryServer: 'https://<domain_name>/api/v4/packages/npm'
   ```

   - `<my-org>`を、`@`記号を除外した、パッケージのインストール元となるプロジェクトのルートレベルグループに置き換えます。
   - `<domain_name>`をドメイン名に置き換えます（例: `gitlab.com`）。

1. オプション。パッケージがプライベートである場合は、パッケージレジストリへのアクセスを設定する必要があります:

   ```yaml
   npmRegistries:
     //<domain_name>/api/v4/packages/npm:
       npmAlwaysAuth: true
       npmAuthToken: '<token>'
   ```

   - `<domain_name>`をドメイン名に置き換えます（例: `gitlab.com`）。
   - `<token>`をデプロイトークン（推奨）、グループアクセストークン、プロジェクトアクセストークン、またはパーソナルアクセストークンに置き換えます。

1. [Yarnでパッケージをインストールします](#install-with-yarn)。

### グループまたはプロジェクトからインストール {#install-from-a-group-or-project}

ワンオフのパッケージがある場合は、グループまたはプロジェクトからインストールできます。

{{< tabs >}}

{{< tab title="グループから" >}}

1. グループスコープを設定します。あなたの`.yarnrc.yml`ファイルに以下を追加します:

   ```yaml
   npmScopes:
     <my-org>:
       npmRegistryServer: 'https://<domain_name>/api/v4/groups/<group_id>/-/packages/npm'
   ```

   - `<my-org>`を、インストール元のグループを含むトップレベルグループに置き換えます。`@`記号を除外します。
   - `<domain_name>`をドメイン名に置き換えます（例: `gitlab.com`）。
   - `<group_id>`をグループIDに置き換えます。[グループ概要ページ](../../group/_index.md#find-the-group-id)で見つけることができます。

1. オプション。あなたのパッケージがプライベートである場合、レジストリを設定する必要があります:

   ```yaml
   npmRegistries:
     //<domain_name>/api/v4/groups/<group_id>/-/packages/npm:
       npmAlwaysAuth: true
       npmAuthToken: "<token>"
   ```

   - `<domain_name>`をドメイン名に置き換えます（例: `gitlab.com`）。
   - `<token>`をデプロイトークン（推奨）、グループアクセストークン、プロジェクトアクセストークン、またはパーソナルアクセストークンに置き換えます。
   - `<group_id>`をグループIDに置き換えます。[グループ概要ページ](../../group/_index.md#find-the-group-id)で見つけることができます。

1. [Yarnでパッケージをインストールします](#install-with-yarn)。

{{< /tab >}}

{{< tab title="プロジェクトから" >}}

1. プロジェクトスコープを設定します。あなたの`.yarnrc.yml`ファイルに以下を追加します:

   ```yaml
   npmScopes:
    <my-org>:
      npmRegistryServer: "https://<domain_name>/api/v4/projects/<project_id>/packages/npm"
   ```

   - `<my-org>`を、インストール元のプロジェクトを含むトップレベルグループに置き換えます。`@`記号を除外します。
   - `<domain_name>`をドメイン名に置き換えます（例: `gitlab.com`）。
   - `<project_id>`を、[プロジェクトの概要ページ](../../project/working_with_projects.md#find-the-project-id)のプロジェクトIDに置き換えます。

1. オプション。あなたのパッケージがプライベートである場合、レジストリを設定する必要があります:

   ```yaml
   npmRegistries:
     //<domain_name>/api/v4/projects/<project_id>/packages/npm:
       npmAlwaysAuth: true
       npmAuthToken: "<token>"
   ```

   - `<domain_name>`をドメイン名に置き換えます（例: `gitlab.com`）。
   - `<token>`をデプロイトークン（推奨）、グループアクセストークン、プロジェクトアクセストークン、またはパーソナルアクセストークンに置き換えます。
   - `<project_id>`を、[プロジェクトの概要ページ](../../project/working_with_projects.md#find-the-project-id)のプロジェクトIDに置き換えます。

1. [Yarnでパッケージをインストールします](#install-with-yarn)。

{{< /tab >}}

{{< /tabs >}}

### Yarnでインストール {#install-with-yarn}

{{< tabs >}}

{{< tab title="Yarn 2以降" >}}

- コマンドラインまたはCI/CDパイプラインから`yarn add`を実行します:

```shell
yarn add @scope/my-package
```

{{< /tab >}}

{{< tab title="Yarn Classic" >}}

Yarn Classicでは、`.npmrc`ファイルと`.yarnrc`ファイルの両方が必要です。詳細については、[Yarnイシュー4451](https://github.com/yarnpkg/yarn/issues/4451#issuecomment-753670295)を参照してください。

1. あなたの認証情報を`.npmrc`ファイルに、スコープ付きレジストリを`.yarnrc`ファイルに配置します:

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

1. コマンドラインまたはCI/CDパイプラインから`yarn add`を実行します:

   ```shell
   yarn add @scope/my-package
   ```

{{< /tab >}}

{{< /tabs >}}

## Yarnパッケージを削除する {#delete-a-yarn-package}

前提条件: 

- メンテナーまたはオーナーのロールを持っている必要があります。

パッケージを削除する前に、[関連するセキュリティリスク](../package_registry/supported_functionality.md#deleting-packages)を理解していることを確認してください。

パッケージを削除するには、次のいずれかの方法があります:

- [UIを使用する](../package_registry/reduce_package_registry_storage.md#delete-a-package)。
- [APIを使用する](../../../api/packages.md#delete-a-project-package)。

## 関連トピック {#related-topics}

- [npmパッケージレジストリドキュメント](../npm_registry/_index.md#helpful-hints)
- [Yarn移行ガイド](https://yarnpkg.com/migration/guide)
- [Yarnパッケージをビルドする](../workflows/build_packages.md#yarn)

## トラブルシューティング {#troubleshooting}

### npmレジストリ用のパッケージレジストリでYarnを実行中のエラー {#error-running-yarn-with-the-package-registry-for-the-npm-registry}

npmレジストリで[Yarn](https://classic.yarnpkg.com/en/)を使用している場合、次のようなエラーメッセージが表示されることがあります:

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

この場合、次のコマンドは現在のディレクトリに`.yarnrc`という名前のファイルを作成します。グローバル設定の場合はユーザーのホームディレクトリに、プロジェクトごとの設定の場合はプロジェクトルートにいることを確認してください:

```shell
yarn config set '//gitlab.example.com/api/v4/projects/<project_id>/packages/npm/:_authToken' '<token>'
yarn config set '//gitlab.example.com/api/v4/packages/npm/:_authToken' '<token>'
```

### グループインストールからtarballをフェッチする際に、Yarn Classicが`404 Not Found`を返します {#yarn-classic-returns-404-not-found-when-fetching-a-tarball-from-a-group-install}

Yarn Classicでグループ内のレジストリからパッケージをインストールする際に、パッケージの解決は成功しても、tarballのダウンロードが`404 Not Found`エラーで失敗することがあります:

```shell
[1/4] Resolving packages...
[2/4] Fetching packages...
error Error: https://gitlab.example.com/api/v4/projects/<project_id>/packages/npm/@scope/my-package/-/@scope/my-package-1.0.0.tgz: Request failed "404 Not Found"
```

このエラーは、グループレジストリによって返されるパッケージメタデータに、プロジェクトエンドポイントを指すtarballダウンロードURLが含まれているために発生します。`.npmrc`ファイルにグループエンドポイント用の認証トークンのみがある場合、プロジェクトエンドポイントへのリクエストは認証されません。そして`404`を返します。

この問題を解決するには、グループエンドポイントとプロジェクトエンドポイントの両方の認証トークンを`.npmrc`ファイルに追加します:

```ini
# .npmrc
//gitlab.example.com/api/v4/groups/<group_id>/-/packages/npm/:_authToken='<token>'
//gitlab.example.com/api/v4/projects/<project_id>/packages/npm/:_authToken='<token>'
```

### Yarn Classicは短縮された認証パスで`401 Unauthorized`を返します {#yarn-classic-returns-401-unauthorized-with-shortened-authentication-paths}

GitLabパッケージレジストリでYarn Classicを使用すると、認証トークンが有効であっても`401 Unauthorized`エラーを受け取ることがあります。エラーメッセージは次のようになります:

```shell
error Couldn't find package "@scope/my-package" on the "npm" registry.
```

`--verbose`フラグを使用すると、ログは`401`ステータスコードを表示します:

```shell
verbose Performing "GET" request to "https://gitlab.com/api/v4/groups/<group_id>/-/packages/npm/..."
verbose Request "https://gitlab.com/api/v4/groups/<group_id>/-/packages/npm/..." finished with status code 401.
```

このイシューは、`.npmrc`の`_authToken`エントリが、完全なエンドポイントパスの代わりに短縮された親パスを使用している場合に発生します。例: 

```ini
# Does NOT work with Yarn Classic
//gitlab.com/api/v4/:_authToken='<token>'
```

npmバージョン8以降は階層的な認証マッチング（親パスに設定されたトークンがすべてのサブパスに適用される）をサポートしていますが、Yarn Classicは`_authToken`エントリとレジストリURLの正確なパスマッチングを必要とします。

このイシューを解決するには、認証する各レジストリの完全なエンドポイントパスを`.npmrc`ファイルで使用します。たとえば、パッケージが特定のプロジェクトでホストされているグループレジストリからインストールする場合:

```ini
# .npmrc
//gitlab.com/api/v4/groups/<group_id>/-/packages/npm/:_authToken='<token>'
//gitlab.com/api/v4/projects/<project_id>/packages/npm/:_authToken='<token>'
```

プロジェクトエントリは、グループエンドポイントによって返されるパッケージメタデータに、プロジェクトエンドポイントを指すtarballダウンロードURLが含まれているため必要です。

### `yarn install`がリポジトリを依存としてクローンするのに失敗します {#yarn-install-fails-to-clone-repository-as-a-dependency}

Dockerfileから`yarn install`を使用してDockerfileをビルドすると、次のようなエラーが発生する場合があります:

```plaintext
...
#6 8.621 fatal: unable to access 'https://gitlab.com/path/to/project/': Problem with the SSL CA cert (path? access rights?)
#6 8.621 info Visit https://yarnpkg.com/en/docs/cli/install for documentation about this command.
#6 ...
```

このイシューを解決するには、[.dockerignore](https://docs.docker.com/build/building/context/#dockerignore-files)ファイル内のすべてのYarn関連のパスに[感嘆符 (`!`) を追加](https://docs.docker.com/build/building/context/#negating-matches)します。

```dockerfile
**

!./package.json
!./yarn.lock
...
```
