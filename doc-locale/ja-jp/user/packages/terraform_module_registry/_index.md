---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Terraformモジュールレジストリ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- インフラストラクチャレジストリとTerraformモジュールレジストリは、GitLab 15.11で単一のTerraformモジュールレジストリ機能と[統合](https://gitlab.com/gitlab-org/gitlab/-/issues/404075)されました。
- グループのサポートは、GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140215)されました。

{{< /history >}}

Terraformモジュールレジストリを使用すると、次のことができます:

- GitLabプロジェクトをTerraformモジュールのプライベートレジストリとして使用する。
- GitLab CI/CDでモジュールを作成および公開し、他のプライベートプロジェクトから使用する。

## Terraformモジュールレジストリに対して認証する {#authenticate-to-the-terraform-module-registry}

Terraformモジュールレジストリに対して認証するには、次のいずれかが必要です:

- 少なくとも`read_api`スコープを持つ[パーソナルアクセストークン](../../../api/rest/authentication.md#personalprojectgroup-access-tokens)。
- [CI/CDジョブトークン](../../../ci/jobs/ci_job_token.md)。
- `read_package_registry`または`write_package_registry`スコープ、あるいはその両方を持つ[デプロイトークン](../../project/deploy_tokens/_index.md)。

APIを使用している場合:

- デプロイトークンで認証する場合は、`write_package_registry`スコープを適用してモジュールを公開する必要があります。モジュールをダウンロードするには、`read_package_registry`スコープを適用します。
- パーソナルアクセストークンで認証する場合は、少なくとも`read_api`スコープで設定する必要があります。

ここにドキュメント化されている方法以外の認証方法は使用しないでください。ドキュメント化されていない認証方法は、将来削除される可能性があります。

## 前提要件 {#prerequisites}

Terraformモジュールを公開するには:

- デベロッパー以上のロールを持っている必要があります。

モジュールを削除するには:

- メンテナー以上のロールを持っている必要があります。

## Terraformモジュールを公開する {#publish-a-terraform-module}

Terraformモジュールを公開すると、モジュールが存在しない場合は作成されます。

Terraformモジュールを公開した後、[**Terraformモジュールレジストリ**ページで表示](#view-terraform-modules)できます。

### APIの使用 {#with-the-api}

[TerraformモジュールレジストリAPI](../../../api/packages/terraform-modules.md)を使用して、Terraformモジュールを公開します。

```plaintext
PUT /projects/:id/packages/terraform/modules/:module-name/:module-system/:module-version/file
```

| 属性          | 型            | 必須 | 説明                                                                                                                      |
| -------------------| --------------- | ---------| -------------------------------------------------------------------------------------------------------------------------------- |
| `id`               | 整数/文字列  | はい      | プロジェクトのID、または[URLエンコードされたパス](../../../api/rest/_index.md#namespaced-paths)。                                    |
| `module-name`      | 文字列          | はい      | モジュール名。サポートされている構文: 小文字（a〜z）と数字（0〜9）を含む1〜64個のASCII文字。 |
| `module-system`    | 文字列          | はい      | モジュールシステム。サポートされている構文: 小文字（a〜z）と数字（0〜9）を含む1〜64個のASCII文字。詳細については、[モジュールレジストリプロトコル](https://opentofu.org/docs/internals/module-registry-protocol/)を参照してください。 |
| `module-version`   | 文字列          | はい      | モジュールバージョン。[セマンティックバージョニングの仕様](https://semver.org/)に従う必要があります。 |

リクエスト本文にファイルコンテンツを指定します。

リクエストは`/file`で終わる必要があります。それ以外の文字列で終わるリクエストを送信すると、`404 Not Found`エラーが発生します。

{{< tabs >}}

{{< tab title="パーソナルアクセストークン" >}}

パーソナルアクセストークンを使用したリクエストの例:

```shell
curl --fail-with-body --header "PRIVATE-TOKEN: <your_access_token>" \
     --upload-file path/to/file.tgz \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/terraform/modules/<your_module>/<your_system>/0.0.1/file"
```

{{< /tab >}}

{{< tab title="デプロイトークン" >}}

デプロイトークンを使用したリクエストの例:

```shell
curl --fail-with-body --header "DEPLOY-TOKEN: <deploy_token>" \
     --upload-file path/to/file.tgz \
     --url "https://gitlab.example.com/api/v4/projects/<your_project_id>/packages/terraform/modules/<your_module>/<your_system>/0.0.1/file"
```

{{< /tab >}}

{{< /tabs >}}

応答の例:

```json
{
  "message":"201 Created"
}
```

### CI/CDテンプレートの使用（推奨） {#with-a-cicd-template-recommended}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110493)されました。

{{< /history >}}

[`Terraform-Module.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform-Module.gitlab-ci.yml)または高度な[`Terraform/Module-Base.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Terraform/Module-Base.gitlab-ci.yml)CI/CDテンプレートを使用して、TerraformモジュールをGitLab Terraformモジュールレジストリに公開できます:

```yaml
include:
  template: Terraform-Module.gitlab-ci.yml
```

パイプラインには、次のジョブが含まれています:

- `fmt`: Terraformモジュールのフォーマットを検証します。
- `kics-iac-sast`: セキュリティ問題に関してTerraformモジュールをテストします。
- `deploy`: TerraformモジュールをTerraformモジュールレジストリにデプロイします（タグパイプラインのみ）。

#### パイプライン変数を使用する {#use-pipeline-variables}

次の変数を使用してパイプラインを設定します:

| 変数                   | デフォルト              | 説明                                                                                     |
|----------------------------|----------------------|-------------------------------------------------------------------------------------------------|
| `TERRAFORM_MODULE_DIR`     | `${CI_PROJECT_DIR}`  | Terraformプロジェクトのルートディレクトリへの相対パス。                               |
| `TERRAFORM_MODULE_NAME`    | `${CI_PROJECT_NAME}` | モジュール名。スペースやアンダースコアを含めることはできません。                  |
| `TERRAFORM_MODULE_SYSTEM`  | `local`              | モジュールターゲットのシステムまたはプロバイダー。たとえば、`local`、`aws`、`google`などです。 |
| `TERRAFORM_MODULE_VERSION` | `${CI_COMMIT_TAG}`   | モジュールバージョン。[セマンティックバージョニングの仕様](https://semver.org/)に従う必要があります。          |

### CI/CDを手動で構成する {#configure-cicd-manually}

[GitLab CI/CD](../../../ci/_index.md)でTerraformモジュールを操作するには、コマンドで、パーソナルアクセストークンの代わりに`CI_JOB_TOKEN`を使用します。

たとえば、このジョブは、`local`[システムプロバイダー](https://registry.terraform.io/browse/providers)の新しいモジュールをアップロードし、Gitコミットタグからモジュールバージョンを使用します:

```yaml
stages:
  - deploy

upload:
  stage: deploy
  image: curlimages/curl:latest
  variables:
    TERRAFORM_MODULE_DIR: ${CI_PROJECT_DIR}    # The relative path to the root directory of the Terraform project.
    TERRAFORM_MODULE_NAME: ${CI_PROJECT_NAME}  # The name of your Terraform module, must not have any spaces or underscores (will be translated to hyphens).
    TERRAFORM_MODULE_SYSTEM: local             # The system or provider your Terraform module targets (ex. local, aws, google).
    TERRAFORM_MODULE_VERSION: ${CI_COMMIT_TAG} # The version - it's recommended to follow SemVer for Terraform Module Versioning.
  script:
    - TERRAFORM_MODULE_NAME=$(echo "${TERRAFORM_MODULE_NAME}" | tr " _" -) # module-name must not have spaces or underscores, so translate them to hyphens
    - tar -vczf /tmp/${TERRAFORM_MODULE_NAME}-${TERRAFORM_MODULE_SYSTEM}-${TERRAFORM_MODULE_VERSION}.tgz -C ${TERRAFORM_MODULE_DIR} --exclude=./.git .
    - 'curl --fail-with-body --location --header "JOB-TOKEN: ${CI_JOB_TOKEN}"
         --upload-file /tmp/${TERRAFORM_MODULE_NAME}-${TERRAFORM_MODULE_SYSTEM}-${TERRAFORM_MODULE_VERSION}.tgz
         ${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/packages/terraform/modules/${TERRAFORM_MODULE_NAME}/${TERRAFORM_MODULE_SYSTEM}/${TERRAFORM_MODULE_VERSION}/file'
  rules:
    - if: $CI_COMMIT_TAG
```

このアップロードジョブをトリガーするには、Gitタグをコミットに追加します。タグが、Terraformに必要な[セマンティックバージョニングの仕様](https://semver.org/)に従っていることを確認してください。`rules:if: $CI_COMMIT_TAG`を使用すると、リポジトリへのタグ付きコミットのみがモジュールのアップロードジョブをトリガーできます。

CI/CDパイプラインでジョブを制御するその他の方法については、[CI/CD YAML構文リファレンス](../../../ci/yaml/_index.md)を参照してください。

### モジュール解決のワークフロー {#module-resolution-workflow}

新しいモジュールをアップロードすると、GitLabはモジュールのパスを生成します。次に例を示します:

- `https://gitlab.example.com/parent-group/my-infra-package`

このパスは、[Terraformモジュールレジストリプロトコル](https://opentofu.org/docs/internals/module-registry-protocol/)に準拠しています。パスの要素は次のとおりです:

- `gitlab.example.com`は、ホスト名です。
- `parent-group`は、Terraformモジュールレジストリの一意のトップレベル[ネームスペース](../../namespace/_index.md)です。
- `my-infra-package`は、モジュールの名前です。

[重複が許可されていない](#allow-duplicate-terraform-modules)場合、モジュール名とバージョンは、`parent-group`の下にあるすべてのグループ、サブグループ、ロジェクトで一意である必要があります。そうでない場合は、次のエラーが返されます:

- `{"message":"A module with the same name already exists in the namespace."}`

[重複が許可されている](#allow-duplicate-terraform-modules)場合、モジュール解決は、最近公開されたモジュールに基づきます。

次に例を示します:

- プロジェクトが`gitlab.example.com/parent-group/subgroup/my-project`である。
- Terraformモジュールが`my-infra-package`である。重複が許可されている場合、`my-infra-package`は有効なモジュールです。重複が許可されていない場合、モジュール名は、`parent-group`の下にあるすべてのグループ内のすべてのプロジェクトで一意である必要があります。

モジュールに名前を付けるときは、次の命名規則に留意してください:

- プロジェクト名とグループ名にドット（`.`）を含めることはできません。たとえば、`source = "gitlab.example.com/my.group/project.name"`は無効です。
- モジュールバージョンは、[セマンティックバージョニングの仕様](https://semver.org/)に従う必要があります。

### Terraformモジュールの重複を許可する {#allow-duplicate-terraform-modules}

{{< history >}}

- GitLab 16.8で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/368040)。
- GitLab 17.0で必要なロールがメンテナーからオーナーに[変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/370471)。

{{< /history >}}

デフォルトでは、Terraformモジュールレジストリは、同じネームスペース内のモジュール名の一意性を適用します。

重複するモジュール名を公開できるようにするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. **設定** > **パッケージとレジストリ**を選択します。
1. **パッケージの重複**テーブルの**Terraformモジュール**行で、**重複を許可**切替をオフにします。
1. オプション。**例外**テキストボックスに、許可するモジュールの名前に一致する正規表現を入力します。

変更は自動的に保存されます。

{{< alert type="note" >}}

**重複を許可**がオンになっている場合は、**例外**テキストボックスで重複してはならないモジュール名を指定できます。

{{< /alert >}}

[GraphQL API](../../../api/graphql/reference/_index.md#packagesettings)で`terraform_module_duplicates_allowed`を有効にして、重複する名前の公開を許可することもできます。

特定の名前に重複を許可するには:

1. `terraform_module_duplicates_allowed`が無効になっていることを確認します。
1. `terraform_module_duplicate_exception_regex`を使用して、重複を許可するモジュール名の正規表現パターンを定義します。

トップレベルのネームスペース設定は、子ネームスペースの設定よりも優先されます。たとえば、グループに対して`terraform_module_duplicates_allowed`を有効にし、サブグループに対して無効にした場合、グループとそのサブグループ内のすべてのプロジェクトで重複が許可されます。

モジュール解決の詳細については、[モジュール解決のワークフロー](#module-resolution-workflow)を参照してください

## Terraformモジュールを表示する {#view-terraform-modules}

{{< history >}}

- `README`ファイルのサポートは、GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438060)されました。

{{< /history >}}

プロジェクトまたはグループでTerraformモジュールを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左側のサイドバーで、**操作** > **Terraformモジュール**を選択します。

このページでモジュールを検索、ソート、およびフィルタリングできます。

モジュールの`README`ファイルを表示するには:

1. **Terraformモジュールレジストリ**ページで、Terraformモジュールを選択します。
1. **`README`**を選択します。

## Terraformモジュールを参照する {#reference-a-terraform-module}

グループまたはプロジェクトからモジュールを参照します。

### ネームスペースから {#from-a-namespace}

環境変数で`terraform`の認証トークン（ジョブトークン、パーソナルアクセストークン、またはデプロイトークン）を提供できます。

`TF_TOKEN_`プレフィックスを環境変数のドメイン名に追加し、ピリオドをアンダースコアとしてエンコードする必要があります。詳細については、[環境変数の認証情報](https://opentofu.org/docs/cli/config/config-file/#environment-variable-credentials)を参照してください。

たとえば、CLIがホスト名`gitlab.com`にサービスリクエストを行う場合、`TF_TOKEN_gitlab_com`という名前の変数の値はデプロイトークンとして使用されます:

```shell
export TF_TOKEN_gitlab_com='glpat-<deploy_token>'
```

この方法は、エンタープライズ向けの実装に適しています。ローカル環境または一時的な環境では、次のように`~/.terraformrc`ファイルまたは`%APPDATA%/terraform.rc`ファイルを作成することをお勧めします:

```terraform
credentials "<gitlab.com>" {
  token = "<TOKEN>"
}
```

ここで、`gitlab.com`はGitLab Self-Managedインスタンスのホスト名に置き換えることができます。

その後、ダウンストリームのTerraformプロジェクトからTerraformモジュールを参照できます:

```terraform
module "<module>" {
  source = "gitlab.com/<namespace>/<module-name>/<module-system>"
}
```

### プロジェクトから {#from-a-project}

プロジェクトのソースを使用してTerraformモジュールを参照するには、Terraformで提供される、[HTTP経由でアーカイブを取得する](https://developer.hashicorp.com/terraform/language/modules/sources#fetching-archives-over-http)ソースタイプを使用します。

次のように`terraform`の認証トークン（ジョブトークン、パーソナルアクセストークン、またはデプロイトークン）を`~/.netrc`ファイルで指定できます:

```plaintext
machine <gitlab.com>
login <USERNAME>
password <TOKEN>
```

ここで、`gitlab.com`はGitLab Self-Managedインスタンスのホスト名に、`<USERNAME>`はトークンユーザー名に置き換えることができます。

ダウンストリームのTerraformプロジェクトから、Terraformモジュールを次のように参照できます:

```terraform
module "<module>" {
  source = "https://gitlab.com/api/v4/projects/<project-id>/packages/terraform/modules/<module-name>/<module-system>/<module-version>"
}
```

モジュールの最新バージョンを参照する必要がある場合は、ソースURLから`<module-version>`を省略可能です。とはいえ将来の問題を防ぐために、可能な場合は特定のバージョンを参照するようにしてください。

同じネームスペースに[重複するモジュール名](#allow-duplicate-terraform-modules)がある場合、ネームスペースレベルからモジュールを参照すると、最近公開されたモジュールがインストールされます。重複するモジュールの特定のバージョンを参照するには、[プロジェクトレベル](#from-a-project)のソースタイプを使用します。

## Terraformモジュールをダウンロードする {#download-a-terraform-module}

Terraformモジュールをダウンロードするには:

1. 左側のサイドバーで、**操作** > **Terraformモジュール**を選択します。
1. ダウンロードするモジュールの名前を選択します。
1. **アセット**テーブルから、ダウンロードするモジュールを選択します。

## Terraformモジュールを削除する {#delete-a-terraform-module}

Terraformモジュールレジストリで公開した後、Terraformモジュールを編集することはできません。代わりに、削除して再作成する必要があります。

[パッケージAPI](../../../api/packages.md#delete-a-project-package)またはUIを使用してモジュールを削除できます。

UIでモジュールを削除するには、プロジェクトから次の手順を実行します:

1. 左側のサイドバーで、**操作** > **Terraformモジュール**を選択します。
1. 削除するパッケージの名前を見つけます。
1. **削除**を選択します。

パッケージは完全に削除されます。

## Terraformモジュールレジストリを無効にする {#disable-the-terraform-module-registry}

Terraformモジュールレジストリは自動的に有効になります。

GitLab Self-Managedインスタンスの場合、GitLab管理者は**パッケージとレジストリ**を[無効](../../../administration/packages/_index.md#enable-or-disable-the-package-registry)にできます。これにより、このメニュー項目がサイドバーから削除されます。

次のように、特定のプロジェクトのTerraformモジュールレジストリを削除することもできます:

1. プロジェクトで、**設定** > **一般**に移動します。
1. **可視性、プロジェクトの機能、権限**セクションを展開し、**パッケージ**をオフに切り替えます。
1. **変更を保存**を選択します。

## プロジェクトの例 {#example-projects}

Terraformモジュールレジストリの例については、以下のプロジェクトを確認してください:

- [_GitLabローカルファイル_プロジェクト](https://gitlab.com/mattkasa/gitlab-local-file)は、最小限のTerraformモジュールを作成し、GitLab CI/CDを使用してTerraformモジュールレジストリにアップロードします。
- [_Terraformモジュールテスト_プロジェクト](https://gitlab.com/mattkasa/terraform-module-test)は、前の例のモジュールを使用します。
