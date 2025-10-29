---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パッケージレジストリ内のnpmパッケージ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Node Package Manager（npm）は、JavaScriptおよびNode.jsのデフォルトのパッケージマネージャーです。デベロッパーはnpmを使用して、コードの共有と再利用、依存関係の管理、プロジェクトワークフローの効率化を行います。GitLabでは、npmパッケージはソフトウェア開発ライフサイクルにおいて重要な役割を果たします。

[API](../../../api/packages/npm.md)については、こちらをご覧ください。

GitLabパッケージレジストリにnpmパッケージを公開する方法については、こちらの[動画デモ](https://youtu.be/yvLxtkvsFDA)をご覧ください。

## パッケージレジストリへの認証 {#authenticate-to-the-package-registry}

プライベートプロジェクトまたはプライベートグループからパッケージを公開またはインストールするには、パッケージレジストリに対して認証を行う必要があります。プロジェクトまたはグループがパブリックの場合、認証は不要です。プロジェクトが内部の場合、GitLabインスタンスの登録ユーザーである必要があります。匿名ユーザーは内部プロジェクトからパッケージをプルできません。

認証するには、次のいずれかを使用できます:

- スコープが`api`に設定された次のいずれかのトークン:
  - [パーソナルアクセストークン](../../profile/personal_access_tokens.md)
  - [グループアクセストークン](../../../user/group/settings/group_access_tokens.md)
  - [プロジェクトアクセストークン](../../../user/project/settings/project_access_tokens.md)
- スコープが`read_package_registry`と`write_package_registry`のどちらか、または両方に設定された[デプロイトークン](../../project/deploy_tokens/_index.md)。
- CI/CDパイプラインでパッケージを公開する場合は、[CI/CDジョブトークン](../../../ci/jobs/ci_job_token.md)。

組織が2要素認証（2FA）を使用している場合、スコープが`api`に設定されたパーソナルアクセストークンを使用する必要があります。詳細については、[トークンに関するガイダンス](../package_registry/supported_functionality.md#authenticate-with-the-registry)参照してください。

ここに記載されている方法以外の認証方法は使用しないでください。ドキュメント化されていない認証方法は、将来削除される可能性があります。

### `.npmrc`ファイルを使用する場合 {#with-the-npmrc-file}

`package.json`と同じディレクトリに`.npmrc`ファイルを作成または編集します。`.npmrc`ファイルに次の行を含めます:

```shell
  //<domain_name>/api/v4/projects/<project_id>/packages/npm/:_authToken="${NPM_TOKEN}"
```

{{< alert type="warning" >}}

リポジトリにコミットできる`.npmrc`ファイルやその他のファイルに、GitLabトークン（またはその他のトークン）を直接ハードコードしないでください。

{{< /alert >}}

次に例を示します:

{{< tabs >}}

{{< tab title="インスタンスの場合" >}}

```shell
//<domain_name>/api/v4/packages/npm/:_authToken="${NPM_TOKEN}"
```

`<domain_name>`をドメイン名に置き換えます。たとえば、`gitlab.com`などです。

{{< /tab >}}

{{< tab title="グループの場合" >}}

```shell
//<domain_name>/api/v4/groups/<group_id>/-/packages/npm/:_authToken="${NPM_TOKEN}"
```

必ず以下を置き換えてください:

- `<domain_name>`をドメイン名に置き換えます。たとえば、`gitlab.com`などです。
- `<group_id>`をグループのホームページのグループIDに置き換えます。

{{< /tab >}}

{{< tab title="プロジェクトの場合" >}}

```shell
//<domain_name>/api/v4/projects/<project_id>/packages/npm/:_authToken="${NPM_TOKEN}"
```

必ず以下を置き換えてください:

- `<domain_name>`をドメイン名に置き換えます。たとえば、`gitlab.com`などです。
- `<project_id>`を[プロジェクトの概要ページ](../../project/working_with_projects.md#find-the-project-id)のプロジェクトIDに置き換えます。

{{< /tab >}}

{{< /tabs >}}

### `npm config set`を使用する場合 {#with-npm-config-set}

これを行うには、以下を実行します:

```shell
npm config set -- //<domain_name>/:_authToken=<token>
```

npmのバージョンによっては、URLを変更する必要が生じる場合があります:

- npmバージョン7以前では、完全なURLをエンドポイントに使用してください。
- バージョン8以降では、`_authToken`パラメータに対して、完全なURIの代わりにURIフラグメントを使用できます。詳細については、[Auth related configuration](https://docs.npmjs.com/cli/v8/configuring-npm/npmrc/?v=true#auth-related-configuration)を参照してください。

次に例を示します: 

{{< tabs >}}

{{< tab title="インスタンスの場合" >}}

```shell
npm config set -- //<domain_name>/api/v4/packages/npm/:_authToken=<token>
```

必ず以下を置き換えてください:

- `<domain_name>`をドメイン名に置き換えます。たとえば、`gitlab.com`などです。
- `<token>`をデプロイトークン、グループアクセストークン、プロジェクトアクセストークン、またはパーソナルアクセストークンに置き換えます。

{{< /tab >}}

{{< tab title="グループの場合" >}}

```shell
npm config set -- //<domain_name>/api/v4/groups/<group_id>/-/packages/npm/:_authToken=<token>
```

必ず以下を置き換えてください:

- `<domain_name>`をドメイン名に置き換えます。たとえば、`gitlab.com`などです。
- `<group_id>`をグループのホームページのグループIDに置き換えます。
- `<token>`をデプロイトークン、グループアクセストークン、プロジェクトアクセストークン、またはパーソナルアクセストークンに置き換えます。

{{< /tab >}}

{{< tab title="プロジェクトの場合" >}}

```shell
npm config set -- //<domain_name>/api/v4/projects/<project_id>/packages/npm/:_authToken=<token>
```

必ず以下を置き換えてください:

- `<domain_name>`をドメイン名に置き換えます。たとえば`gitlab.com`などです。
- `<project_id>`をプロジェクトIDで置き換えます。
- `<token>`をデプロイトークン、グループアクセストークン、プロジェクトアクセストークン、またはパーソナルアクセストークンに置き換えます。

{{< /tab >}}

{{< /tabs >}}

## レジストリURLを設定する {#set-up-the-registry-url}

GitLabパッケージレジストリからパッケージを公開またはインストールするには、正しいレジストリURLを使用するようにnpmを設定する必要があります。設定方法とURL構造は、パッケージを公開するかインストールするかによって異なります。

レジストリURLを設定する前に、さまざまな設定方法のスコープを理解することが重要です:

- `.npmrc`ファイル: ファイルを含むフォルダーに対してローカルに設定されます。
- `npm config set`コマンド: グローバルnpm設定を変更し、システムで実行されるすべてのnpmコマンドに影響します。
- `publishConfig`（`package.json`内）: この設定はパッケージに固有であり、そのパッケージを公開するときにのみ適用されます。

{{< alert type="warning" >}}

`npm config set`を実行すると、グローバルnpm設定が変更されます。この変更は、現在の作業ディレクトリに関係なく、システムで実行されるすべてのnpmコマンドに影響します。特に共有システムでは、この方法を使用する際は注意が必要です。

{{< /alert >}}

### パッケージを公開する場合 {#for-publishing-packages}

パッケージを公開する場合は、プロジェクトエンドポイントを使用します:

```shell
https://gitlab.example.com/api/v4/projects/<project_id>/packages/npm/
```

`gitlab.example.com`をGitLabインスタンスのドメインに、`<project_id>`をプロジェクトIDに置き換えます。このURLを設定するには、次のいずれかの方法を使用します:

{{< tabs >}}

{{< tab title="`.npmrc`ファイル" >}}

プロジェクトのルートで`.npmrc`ファイルを作成または編集します:

```plaintext
@scope:registry=https://gitlab.example.com/api/v4/projects/<project_id>/packages/npm/
//gitlab.example.com/api/v4/projects/<project_id>/packages/npm/:_authToken="${NPM_TOKEN}"
```

{{< /tab >}}

{{< tab title="`npm config`" >}}

`npm config set`コマンドを使用します:

```shell
npm config set @scope:registry=https://gitlab.example.com/api/v4/projects/<project_id>/packages/npm/
```

{{< /tab >}}

{{< tab title="`package.json`" >}}

`package.json`に`publishConfig`セクションを追加します:

```shell
{
  "publishConfig": {
    "@scope:registry": "https://gitlab.example.com/api/v4/projects/<project_id>/packages/npm/"
  }
}
```

{{< /tab >}}

{{< /tabs >}}

`@scope`をパッケージのスコープに置き換えます。

### パッケージをインストールする場合 {#for-installing-packages}

パッケージをインストールするときは、プロジェクト、グループ、またはインスタンスのエンドポイントを使用できます。URL構造はそれぞれに応じて異なります。これらのURLを設定するには、次のいずれかの方法を使用します:

{{< tabs >}}

{{< tab title="`.npmrc`ファイル" >}}

プロジェクトのルートにある`.npmrc`ファイルを作成または編集します。ニーズに基づいて適切なURLを使用します:

- プロジェクトの場合:

  ```shell
  @scope:registry=https://gitlab.example.com/api/v4/projects/<project_id>/packages/npm/
  ```

- グループの場合:

  ```shell
  @scope:registry=https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/npm/
  ```

- インスタンスの場合:

  ```shell
  @scope:registry=https://gitlab.example.com/api/v4/packages/npm/
  ```

{{< /tab >}}

{{< tab title="`npm config`" >}}

適切なURLを指定して`npm config set`コマンドを使用します:

- プロジェクトの場合:

  ```shell
  npm config set @scope:registry=https://gitlab.example.com/api/v4/projects/<project_id>/packages/npm/
  ```

- グループの場合:

  ```shell
  npm config set @scope:registry=https://gitlab.example.com/api/v4/groups/<group_id>/-/packages/npm/
  ```

- インスタンスの場合:

  ```shell
  npm config set @scope:registry=https://gitlab.example.com/api/v4/packages/npm/
  ```

{{< /tab >}}

{{< /tabs >}}

`gitlab.example.com`、`<project_id>`、`<group_id>`、`@scope`を、GitLabインスタンスとパッケージの適切な値に置き換えます。

レジストリURLを設定したら、パッケージレジストリに対して認証を行うことができます。

## GitLabパッケージレジストリに公開する {#publish-to-gitlab-package-registry}

npmパッケージをGitLabパッケージレジストリに公開するには、認証されている必要があります。

### 命名規則 {#naming-convention}

パッケージのインストール方法によっては、命名規則に従う必要がある場合があります。

パッケージのインストールには、次の3つのAPIエンドポイントのいずれかを使用できます:

- インスタンス: 異なるGitLabグループまたは独自のネームスペースに多数のnpmパッケージがある場合に使用します。
- グループ: 同じグループまたはサブグループの異なるプロジェクトに多数のnpmパッケージがある場合に使用します。
- プロジェクト: npmパッケージの数が少なく、それらが同じGitLabグループにない場合に使用します。

プロジェクトまたはグループからパッケージをインストールする場合、命名規則に従う必要はありません。

インスタンスからパッケージをインストールする場合は、スコープを使用してパッケージに名前を付ける必要があります。スコープ付きパッケージは`@`で始まり、`@owner/package-name`の形式になります。`.npmrc`ファイルで、および`package.json`で`publishConfig`オプションを使用して、パッケージのスコープを設定できます。

- `@scope`に使用される値は、パッケージのソースコードを含むプロジェクトのルートではなく、パッケージをホストしているプロジェクトのルートです。スコープは小文字にする必要があります。
- パッケージ名は任意に設定できます。

詳細については、[スコープ付きパッケージ](https://docs.npmjs.com/cli/v11/using-npm/scope)を参照してください。

| プロジェクトURL                                             | パッケージレジストリ | スコープ     | パッケージのフルネーム      |
| ------------------------------------------------------- | ------------------- | --------- | ---------------------- |
| `https://gitlab.com/my-org/engineering-group/analytics` | 分析           | `@my-org` | `@my-org/package-name` |

`package.json`ファイル内のパッケージの名前が、次の規則に一致していることを確認してください:

```shell
"name": "@my-org/package-name"
```

### コマンドラインでパッケージを公開する {#publish-a-package-with-the-command-line}

認証を設定したら、次のコマンドでNPMパッケージを公開します:

```shell
npm publish
```

`.npmrc`ファイルを認証に使用している場合は、予想される環境変数を設定します:

```shell
NPM_TOKEN=<token> npm publish
```

アップロードされたパッケージに複数の`package.json`ファイルがある場合、最初に見つかったファイルのみが使用され、その他は無視されます。

### CI/CDパイプラインでパッケージを公開する {#publish-a-package-with-a-cicd-pipeline}

CI/CDパイプラインを使用して公開する場合は、[定義済み変数](../../../ci/variables/predefined_variables.md)の`${CI_PROJECT_ID}`と`${CI_JOB_TOKEN}`を使用して、プロジェクトのパッケージレジストリで認証できます。これらの変数を使用して、CI/CDパイプラインジョブの実行中に認証を行うための`.npmrc`ファイルを作成できます。

{{< alert type="note" >}}

`.npmrc`ファイルを生成する際は、ポートがデフォルトポートである場合は`${CI_SERVER_HOST}`の後にポートを指定しないでください。`http` URLはデフォルトで`80`に、`https` URLはデフォルトで`443`になります。

{{< /alert >}}

`package.json`を含むGitLabプロジェクトで、`.gitlab-ci.yml`ファイルを編集または作成します。次に例を示します: 

```yaml
default:
  image: node:latest

stages:
  - deploy

publish-npm:
  stage: deploy
  script:
    - echo "@scope:registry=https://${CI_SERVER_HOST}/api/v4/projects/${CI_PROJECT_ID}/packages/npm/" > .npmrc
    - echo "//${CI_SERVER_HOST}/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}" >> .npmrc
    - npm publish
```

`@scope`を、公開するパッケージの[スコープ](https://docs.npmjs.com/cli/v10/using-npm/scope/)に置き換えます。

パイプラインで`publish-npm`ジョブが実行されると、パッケージがパッケージレジストリに公開されます。

## パッケージをインストールする {#install-a-package}

複数のパッケージの名前とバージョンが同じ場合、パッケージをインストールすると、最後に公開されたパッケージが取得されます。

GitLabのプロジェクト、グループ、またはインスタンスからパッケージをインストールできます:

- インスタンス: 異なるGitLabグループまたは独自のネームスペースに多数のnpmパッケージがある場合に使用します。
- グループ: 同じGitLabグループの異なるプロジェクトに多数のnpmパッケージがある場合に使用します。
- プロジェクト: npmパッケージの数が少なく、それらが同じGitLabグループにない場合に使用します。

### インスタンスからインストールする {#install-from-an-instance}

前提要件: 

- パッケージが、スコープ付き命名規則に従って公開されていること。

1. パッケージレジストリに対して認証する
1. レジストリを次のように設定します:

   ```shell
   npm config set @scope:registry https://<domain_name>.com/api/v4/packages/npm/
   ```

   - `@scope`を、パッケージをインストールするプロジェクトのトップレベルグループに置き換えます。
   - `<domain_name>`をドメイン名に置き換えます（例: `gitlab.com`）。

1. パッケージをインストールします:

   ```shell
   npm install @scope/my-package
   ```

### グループからインストールする {#install-from-a-group}

{{< history >}}

- GitLab 16.0で`npm_group_level_endpoints`[フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/299834)されました。デフォルトでは無効になっています。
- GitLab 16.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121837)になりました。機能フラグ`npm_group_level_endpoints`は削除されました。

{{< /history >}}

1. パッケージレジストリに対して認証する
1. レジストリを次のように設定します:

   ```shell
   npm config set @scope:registry=https://<domain_name>/api/v4/groups/<group_id>/-/packages/npm/
   ```

   - `@scope`を、パッケージをインストールするグループのトップレベルグループに置き換えます。
   - `<domain_name>`をドメイン名に置き換えます（例: `gitlab.com`）。
   - `<group_id>`を、グループのホームページのグループIDに置き換えます。

1. パッケージをインストールします:

   ```shell
   npm install @scope/my-package
   ```

### プロジェクトからインストールする {#install-from-a-project}

1. パッケージレジストリに対して認証する
1. レジストリを次のように設定します:

   ```shell
   npm config set @scope:registry=https://<domain_name>/api/v4/projects/<project_id>/packages/npm/
   ```

   - `@scope`を、パッケージをインストールするプロジェクトの[トップレベルグループ](#naming-convention)に置き換えます。
   - `<domain_name>`をドメイン名に置き換えます（例: `gitlab.com`）。
   - `<project_id>`を、[プロジェクトの概要ページ](../../project/working_with_projects.md#find-the-project-id)のプロジェクトIDに置き換えます。

1. パッケージをインストールします:

   ```shell
   npm install @scope/my-package
   ```

### CI/CDパイプライン内でパッケージをインストールする {#install-a-package-inside-a-cicd-pipeline}

CI/CDパイプライン内でパッケージをインストールする場合、定義済み変数である`${CI_PROJECT_ID}`と`${CI_JOB_TOKEN}`を使用して、プロジェクトのパッケージレジストリで認証できます。これらの変数を使用して、CI/CDパイプラインジョブの実行中に認証を行うための`.npmrc`ファイルを作成できます。

{{< alert type="note" >}}

`.npmrc`ファイルを生成する際は、ポートがデフォルトポートである場合は`${CI_SERVER_HOST}`の後にポートを指定しないでください。`http` URLはデフォルトで`80`に、`https` URLはデフォルトで`443`になります。

{{< /alert >}}

`package.json`を含むGitLabプロジェクトで、`.gitlab-ci.yml`ファイルを編集または作成します。次に例を示します: 

```yaml
default:
  image: node:latest

stages:
  - deploy

publish-npm:
  stage: deploy
  script:
    - echo "@scope:registry=https://${CI_SERVER_HOST}/api/v4/projects/${CI_PROJECT_ID}/packages/npm/" > .npmrc
    - echo "//${CI_SERVER_HOST}/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}" >> .npmrc
    - npm install @scope/my-package
```

`@scope`を、インストールするパッケージのスコープ、およびパッケージ名に置き換えます。

前の例では、プロジェクトレベルのエンドポイントを使用しています。グループレベルまたはインスタンスレベルのエンドポイントを使用するには、グループからのインストールまたはインスタンスからのインストールで説明されているように、レジストリと認証トークンのURLを設定します。

### npmjs.comへのパッケージ転送 {#package-forwarding-to-npmjscom}

{{< history >}}

- GitLab 12.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/55344)されました。
- GitLab 17.0で、必要なロールがメンテナーからオーナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/370471)されました。

{{< /history >}}

npmパッケージがパッケージレジストリにない場合、GitLabはHTTPリダイレクトで応答し、リクエストクライアントが`npmjs.com`にリクエストを再送信できるようにします。

管理者は、[継続的インテグレーションの設定](../../../administration/settings/continuous_integration.md)でこの動作を無効にできます。

グループオーナーは、グループの**パッケージとレジストリ**の設定でこの動作を無効にできます。

改善点は[エピック3608](https://gitlab.com/groups/gitlab-org/-/epics/3608)で追跡されています。

## パッケージを非推奨にする {#deprecate-a-package}

{{< history >}}

- GitLab 16.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/396763)されました。

{{< /history >}}

パッケージを非推奨にすると、パッケージのフェッチ時に非推奨の警告を表示できます。

前提要件:

- パッケージを削除するために必要な[権限](../../permissions.md)を持っていること。
- パッケージレジストリに対して認証されていること。

コマンドラインから、以下を実行します:

```shell
npm deprecate @scope/package "Deprecation message"
```

CLIは`@scope/package`のバージョン範囲も受け入れます。次に例を示します: 

```shell
npm deprecate @scope/package "All package versions are deprecated"
npm deprecate @scope/package@1.0.1 "Only version 1.0.1 is deprecated"
npm deprecate @scope/package@"< 1.0.5" "All package versions less than 1.0.5 are deprecated"
```

パッケージが非推奨になると、そのステータスが`deprecated`に更新されます。

### 非推奨の警告を削除する {#remove-deprecation-warning}

パッケージの非推奨の警告を削除するには、メッセージに`""`（空の文字列）を指定します。次に例を示します: 

```shell
npm deprecate @scope/package ""
```

パッケージの非推奨の警告が削除されると、そのステータスが`default`に更新されます。

## 役立つヒント {#helpful-hints}

### 他の組織からnpmパッケージをインストールする {#install-npm-packages-from-other-organizations}

パッケージのリクエストをGitLab外部の組織やユーザーにルーティングできます。

これを行うには、`.npmrc`ファイルに以下の行を追加します。`@my-other-org`を、プロジェクトのリポジトリを所有するネームスペースまたはグループに置き換え、組織のURLを使用します。名前は大文字と小文字が区別され、グループまたはネームスペースの名前と完全に一致する必要があります。

```shell
@scope:registry=https://my_domain_name.com/api/v4/packages/npm/
@my-other-org:registry=https://my_domain_name.example.com/api/v4/packages/npm/
```

### npmメタデータ {#npm-metadata}

GitLabパッケージレジストリは、次の属性をnpmクライアントに公開します:

- `name`
- `versions`
  - `name`
  - `version`
  - `deprecated`
  - `dependencies`
  - `devDependencies`
  - `bundleDependencies`
  - `peerDependencies`
  - `bin`
  - `directories`
  - `dist`
  - `engines`
  - `_hasShrinkwrap`
  - `hasInstallScript`：このバージョンにインストールスクリプトがある場合は`true`。

詳細については、[省略形のバージョンオブジェクト](https://github.com/npm/registry/blob/main/docs/responses/package-metadata.md#abbreviated-version-object)を参照してください。

### npmディストリビューションタグを追加する {#add-npm-distribution-tags}

新しく公開されたパッケージに[ディストリビューションタグ](https://docs.npmjs.com/cli/dist-tag/)を追加できます。タグはオプションであり、一度に1つのパッケージにのみ割り当てることができます。

タグを指定せずにパッケージを公開すると、`latest`タグがデフォルトで追加されます。タグまたはバージョンを指定せずにパッケージをインストールすると、`latest`タグが使用されます。

サポートされている`dist-tag`コマンドの例:

```shell
npm publish @scope/package --tag               # Publish a package with new tag
npm dist-tag add @scope/package@version my-tag # Add a tag to an existing package
npm dist-tag ls @scope/package                 # List all tags under the package
npm dist-tag rm @scope/package@version my-tag  # Delete a tag from the package
npm install @scope/package@my-tag              # Install a specific tag
```

#### CI/CDから {#from-cicd}

{{< history >}}

- GitLab 15.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/258835)されました。

{{< /history >}}

GitLab CI/CDジョブで`npm dist-tag`コマンドを実行するには、次のいずれかのトークンを使用できます:

- [`CI_JOB_TOKEN`](../../../ci/jobs/ci_job_token.md)
- デプロイトークン

前提要件:

- npmバージョン6.9.1以降が必要です。以前のバージョンでは、npm 6.9.0のバグによりディストリビューションタグの削除に失敗します。

次に例を示します: 

```yaml
npm-deploy-job:
  script:
    - echo "//${CI_SERVER_HOST}/api/v4/projects/${CI_PROJECT_ID}/packages/npm/:_authToken=${CI_JOB_TOKEN}">.npmrc
    - npm dist-tag add @scope/package@version my-tag
```

### npmパッケージを監査する {#audit-npm-packages}

GitLabは`npm audit`コマンドをサポートしており、既知の脆弱性がないかパッケージをチェックできます。

#### `npm audit`を使用する {#use-npm-audit}

前提要件:

- パッケージレジストリへの認証を設定します。
- レジストリURLを設定します。

セキュリティ監査を実行するには、次のコマンドを実行します:

```shell
npm audit --registry=https://gitlab.example.com/api/v4/packages/npm/
```

または、レジストリ設定がすでに完了している場合は、次のコマンドを実行します:

```shell
npm audit
```

`npm audit`コマンドは、既知の脆弱性の依存関係をチェックし、レポートを提供します。

#### `npm audit`ワークフロー {#npm-audit-workflow}

GitLabパッケージレジストリに対して`npm audit`を実行すると、次の2つのシナリオのいずれかが発生します:

1. パッケージ転送が有効になっている場合（デフォルト）、GitLabは監査リクエストを`npmjs.com`に転送して、パブリックパッケージとプライベートパッケージの両方に関する脆弱性情報を取得します。
1. パッケージ転送が無効になっている場合、GitLabは空の結果セットを返します。GitLabは、脆弱性についてパッケージを個別にスキャンしません。

#### セキュリティに関する重要な考慮事項 {#important-security-considerations}

GitLabをパッケージレジストリとして指定しない場合（`--registry`フラグを使用するか、`.npmrc`ファイルでGitLabをデフォルトのレジストリとして設定することにより）、監査リクエストは、代わりにパブリックnpmレジストリに送信されます。

この場合、リクエスト本文には、プライベートGitLabパッケージを含む、プロジェクト内のすべてのパッケージに関する情報が含まれます。

プライベートパッケージ情報がGitLab内に留まるようにするには、`npm audit`コマンドを実行する際に、常にGitLabレジストリを指定するようにしてください。

#### 既知の問題 {#known-issues}

- 監査の結果は、パッケージ転送が有効になっているかどうかによって異なります。管理者またはグループのオーナーが転送を無効している場合、`npm audit`は脆弱性情報を返しません。
- 監査リクエストには、プライベートパッケージを含む、プロジェクト内のすべてのパッケージに関する情報が含まれます。

### サポートされているCLIコマンド {#supported-cli-commands}

GitLab npmリポジトリは、npm CLI（`npm`）とyarn CLI（`yarn`）の次のコマンドをサポートしています:

- `npm install`: npmパッケージをインストールします。
- `npm publish`: npmパッケージをレジストリに公開します。
- `npm dist-tag add`: npmパッケージにディストリビューションタグを追加します。
- `npm dist-tag ls`: パッケージのディストリビューションタグを一覧表示します。
- `npm dist-tag rm`: ディストリビューションタグを削除します。
- `npm ci`: `package-lock.json`ファイルからnpmパッケージを直接インストールします。
- `npm view`: パッケージのメタデータを表示します。
- `npm pack`: パッケージからtarballを作成します。
- `npm deprecate`: パッケージのバージョンを非推奨にします。
- `npm audit`: プロジェクトの依存関係に脆弱性がないかチェックします。

## トラブルシューティング {#troubleshooting}

### npmログが正しく表示されない {#npm-logs-dont-display-correctly}

次のエラーが発生する可能性があります:

```shell
npm ERR! A complete log of this run can be found in: .npm/_logs/<date>-debug-0
```

ログが`.npm/_logs/`ディレクトリに表示されない場合は、ログをルートディレクトリにコピーして、そこで表示できます:

```yaml
  script:
    - npm install --loglevel verbose
    - cp -r /root/.npm/_logs/ .
  artifacts:
    paths:
      - './_logs'
```

npmログは、アーティファクトとして`/root/.npm/_logs/`にコピーされます。

### `npm install`または`yarn`で`404 Not Found`エラーが発生している {#404-not-found-errors-are-happening-on-npm-install-or-yarn}

`CI_JOB_TOKEN`を使用して別のプロジェクトの依存関係を持つnpmパッケージをインストールすると、404 Not Foundエラーが発生します。パッケージとそのすべての依存関係へのアクセス権を持つトークンで認証する必要があります。

パッケージとその依存関係が同じグループ内の別々のプロジェクトにある場合は、[グループデプロイトークン](../../project/deploy_tokens/_index.md#create-a-deploy-token)を使用できます:

```ini
//gitlab.example.com/api/v4/packages/npm/:_authToken=<group-token>
@group-scope:registry=https://gitlab.example.com/api/v4/packages/npm/
```

パッケージとその依存関係が複数のグループに分散している場合は、すべてのグループまたは個々のプロジェクトへのアクセス権を持つユーザーからのパーソナルアクセストークンを使用できます:

```ini
//gitlab.example.com/api/v4/packages/npm/:_authToken=<personal-access-token>
@group-1:registry=https://gitlab.example.com/api/v4/packages/npm/
@group-2:registry=https://gitlab.example.com/api/v4/packages/npm/
```

{{< alert type="warning" >}}

パーソナルアクセストークンは慎重に扱う必要があります。パーソナルアクセストークンの管理（短い有効期限の設定、最小限のスコープの使用など）については、[トークンのセキュリティに関する考慮事項](../../../security/tokens/_index.md#security-considerations)をお読みください。

{{< /alert >}}

### `npm publish`がデフォルトのnpmレジストリ（`registry.npmjs.org`）をターゲットにしている {#npm-publish-targets-default-npm-registry-registrynpmjsorg}

`package.json`ファイルと`.npmrc`ファイルで、パッケージスコープが一貫して設定されていることを確認してください。

たとえば、GitLabのプロジェクト名が`@scope/my-package`の場合、`package.json`ファイルは次のようになります:

```json
{
  "name": "@scope/my-package"
}
```

そして、`.npmrc`ファイルは次のようになります:

```shell
@scope:registry=https://your_domain_name/api/v4/projects/your_project_id/packages/npm/
//your_domain_name/api/v4/projects/your_project_id/packages/npm/:_authToken="${NPM_TOKEN}"
```

### `npm install`が`npm ERR! 403 Forbidden`を返す {#npm-install-returns-npm-err-403-forbidden}

このエラーが発生した場合は、以下を確認してください:

- パッケージレジストリがプロジェクト設定で有効になっている。パッケージレジストリはデフォルトで有効になっていますが、[無効にする](../package_registry/_index.md#turn-off-the-package-registry)こともできます。
- トークンの有効期限が切れておらず、適切な権限がある。
- 指定されたスコープ内に、同じ名前またはバージョンのパッケージがまだ存在しない。
- スコープ付きパッケージのURLの末尾にスラッシュが含まれてる:
  - 正しい例: `//gitlab.example.com/api/v4/packages/npm/`
  - 誤った例: `//gitlab.example.com/api/v4/packages/npm`

### `npm publish`が`npm ERR! 400 Bad Request`を返す {#npm-publish-returns-npm-err-400-bad-request}

このエラーが発生した場合は、次のいずれかの問題が原因である可能性があります。

### パッケージ名が命名規則を満たしていない {#package-name-does-not-meet-the-naming-convention}

パッケージ名が`@scope/package-name`パッケージの命名規則を満たしていない可能性があります。

名前が、大文字と小文字を含め、規則に正確に合致していることを確認してください。その後、再度公開してみてください。

### パッケージがすでに存在する {#package-already-exists}

パッケージが同じルートネームスペース内の別のプロジェクトにすでに公開されているため、同じ名前を使用して再度公開することはできません。

これは、以前に公開されたパッケージが同じ名前で、バージョンが異なる場合でも当てはまります。

### Package JSONファイルが大きすぎる {#package-json-file-is-too-large}

`package.json`ファイルは`20,000`文字を超えないようにしてください。
