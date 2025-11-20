---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: パイプラインシークレット検出をカスタマイズする
---

<!-- markdownlint-disable MD025 -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[サブスクリプションティア](_index.md#availability)と設定方法によっては、パイプラインシークレット検出の動作を変更できます。

[アナライザーの動作をカスタマイズする](#customize-analyzer-behavior)対象:

- アナライザーが検出するシークレットの種類を変更します。
- 別のアナライザーバージョンを使用します。
- 特定の方法でプロジェクトをスキャンします。

[アナライザーのルールセットをカスタマイズする](#customize-analyzer-rulesets)対象:

- カスタムシークレットタイプを検出します。
- デフォルトのスキャナールールをオーバーライドします。

## アナライザーの動作をカスタマイズする {#customize-analyzer-behavior}

アナライザーの動作を変更するには、`.gitlab-ci.yml`の[`variables`](../../../../ci/yaml/_index.md#variables)パラメータを使用して変数を定義します。

{{< alert type="warning" >}}

GitLabセキュリティスキャンツールのすべての設定は、これらの変更をデフォルトブランチにマージする前に、マージリクエストでテストする必要があります。そうしないと、誤検出が多数発生するなど、予期しない結果が生じる可能性があります。

{{< /alert >}}

### 新しいパターンを追加 {#add-new-patterns}

リポジトリ内の他の種類のシークレットを検索するには、[アナライザールールセットをカスタマイズ](#customize-analyzer-rulesets)できます。

パイプラインシークレット検出のすべてのユーザーに対して新しい検出ルールを提案するには、[ルールの信頼できる唯一の情報源を参照](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/blob/main/README.md)し、ガイダンスに従ってマージリクエストを作成してください。

クラウド製品またはSaaS製品を運用していて、ユーザーをより適切に保護するためにGitLabとの提携に関心がある場合は、[漏洩した認証情報の通知に関するパートナープログラム](../automatic_response.md#partner-program-for-leaked-credential-notifications)の詳細をご覧ください。

### 特定のアナライザーバージョンにピン留め {#pin-to-specific-analyzer-version}

GitLab管理のCI/CDテンプレートは、メジャーバージョンを指定し、そのメジャーバージョン内の最新のアナライザーリリースを自動的にプルします。

場合によっては、特定のバージョンを使用する必要があるかもしれません。たとえば、後のリリースで発生したリグレッションを回避する必要がある場合などです。

自動更新の動作をオーバーライドするには、[`Secret-Detection.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.gitlab-ci.yml)を含めた後、CI/CD設定ファイルで`SECRETS_ANALYZER_VERSION` CI/CD変数を設定します。

タグには次のいずれかを設定できます:

- メジャーバージョン（例: `4`）: パイプラインは、このメジャーバージョン内でリリースされるマイナーまたはパッチアップデートを使用します。
- マイナーバージョン（例: `4.5`）: パイプラインは、このマイナーバージョン内でリリースされるパッチアップデートを使用します。
- パッチバージョン（例: `4.5.0`）: パイプラインはアップデートを受け取りません。

この例では、特定のマイナーアナライザーバージョンを使用しています:

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

secret_detection:
  variables:
    SECRETS_ANALYZER_VERSION: "4.5"
```

### 履歴スキャンを有効にする {#enable-historic-scan}

履歴スキャンを有効にするには、変数`SECRET_DETECTION_HISTORIC_SCAN`を`true`ファイルで`.gitlab-ci.yml`に設定します。

### マージリクエストパイプラインでジョブを実行する {#run-jobs-in-merge-request-pipelines}

[マージリクエストパイプラインでセキュリティスキャンツールを使用する](../../detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines)を参照してください。

### アナライザージョブをオーバーライドする {#override-the-analyzer-jobs}

ジョブ定義をオーバーライドするには（たとえば、`variables`や`dependencies`などのプロパティを変更する）、オーバーライドする`secret_detection`ジョブと同じ名前でジョブを宣言します。テンプレートの挿入後にこの新しいジョブを配置し、その下に追加のキーを指定します。

次の`.gitlab-ci.yml`ファイルの例の抜粋:

- `Jobs/Secret-Detection` CI/CDテンプレートが[含まれて](../../../../ci/yaml/_index.md#include)います。
- `secret_detection`ジョブでは、CI/CD変数`SECRET_DETECTION_HISTORIC_SCAN`が`true`に設定されています。テンプレートはパイプライン設定の前に評価されるため、変数の最後の記述が優先され、履歴スキャンが実行されます。

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

secret_detection:
  variables:
    SECRET_DETECTION_HISTORIC_SCAN: "true"
```

### 利用可能なCI/CD変数 {#available-cicd-variables}

利用可能なCI/CD変数を定義して、パイプラインシークレット検出の動作を変更します:

| CI/CD変数                    | デフォルト値 | 説明 |
|-----------------------------------|---------------|-------------|
| `SECRET_DETECTION_EXCLUDED_PATHS` | ""            | パスに基づいて、出力から脆弱性を除外します。パスは、コンマで区切られたパターンのリストです。パターンには、glob（サポートされているパターンについては[`doublestar.Match`](https://pkg.go.dev/github.com/bmatcuk/doublestar/v4@v4.0.2#Match)を参照）、またはファイルやフォルダーのパス（`doc,spec`など）を使用できます。親ディレクトリもパターンに一致します。以前に脆弱性レポートに追加された検出済みのシークレットは削除されません。[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/225273) GitLab 13.3。 |
| `SECRET_DETECTION_HISTORIC_SCAN`  | いいえ         | 過去のGitleaksスキャンを有効にするフラグ。 |
| `SECRET_DETECTION_IMAGE_SUFFIX`   | "" | イメージ名に追加されるサフィックス。`-fips`を設定すると、`FIPS-enabled`イメージがスキャンに使用されます。詳細については、[Use FIPS-enabled images](_index.md#fips-enabled-images)を参照してください。GitLab 14.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/355519)されました。 |
| `SECRET_DETECTION_LOG_OPTIONS`  | ""        | スキャンするコミット範囲を指定するフラグ。Gitleaksは、コミット範囲を決定するために[`git log`](https://git-scm.com/docs/git-log)を使用します。定義すると、パイプラインシークレット検出はブランチ内のすべてのコミットをフェッチしようとします。アナライザーがすべてのコミットにアクセスできない場合は、すでにチェックアウトされているリポジトリで続行されます。GitLab 15.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/350660)されました。 |

以前のGitLabバージョンでは、次の変数も利用可能でした:

| CI/CD変数                    | デフォルト値 | 説明 |
|-----------------------------------|---------------|-------------|
| `SECRET_DETECTION_COMMIT_FROM`    | -             | Gitleaksスキャンの開始コミット。[Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/243564) GitLab 13.5で削除されました。`SECRET_DETECTION_COMMITS`に置き換えられました。 |
| `SECRET_DETECTION_COMMIT_TO`      | -             | Gitleaksスキャンの終了コミット。[Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/243564) GitLab 13.5で削除されました。`SECRET_DETECTION_COMMITS`に置き換えられました。 |
| `SECRET_DETECTION_COMMITS`        | -             | Gitleaksがスキャンするコミットのリスト。[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/243564) GitLab 13.5。はGitLab 15.0で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/352565)されました。 |

## アナライザーのルールセットをカスタマイズする {#customize-analyzer-rulesets}

{{< details >}}

- プラン: Ultimate

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/211387) GitLab 13.5。
- `file`および`raw`の追加のパススルータイプを含むように、GitLab 14.6で展開されました。
- GitLab 14.8でルールをオーバーライドするためのサポートが[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/235359)になりました。
- GitLab 17.2で、パススルーチェーンのサポートが[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/336395)になり、`git`と`url`の追加のパススルータイプが含まれるようになりました。

{{< /history >}}

スキャンされるリポジトリまたはリモートリポジトリのいずれかで、カスタムルールセット設定ファイルを作成することにより、パイプラインシークレット検出を使用して検出されるシークレットの種類をカスタマイズできます。

カスタマイズにより、次のことが可能になります

- デフォルトのルールセットのルールの動作を変更します。
- デフォルトのルールセットをカスタムルールセットに置き換えます。
- デフォルトのルールセットの動作を拡張します。
- シークレットとパスを無視します。

### ルールセット設定ファイルを作成する {#create-a-ruleset-configuration-file}

ルールセット設定ファイルを作成するには:

1. まだ存在しない場合は、プロジェクトのルートに`.gitlab`ディレクトリを作成します。
1. `.gitlab`ディレクトリに`secret-detection-ruleset.toml`という名前のファイルを作成します。

### デフォルトのルールセットのルールを変更する {#modify-rules-from-the-default-ruleset}

[デフォルトのルールセット](../detected_secrets.md)で事前定義されたルールを変更できます。

ルールを変更すると、パイプラインシークレット検出を既存のワークフローまたはツールに適応させることができます。たとえば、検出されたシークレットの重大度をオーバーライドしたり、ルールがまったく検出されないように無効にしたりできます。

また、リモートGitリポジトリまたはWebサイト) にリモートで保存されたルールセット設定ファイルを使用して、事前定義されたルールを変更することもできます。新しいルールでは、[カスタムルール形式](custom_rulesets_schema.md#custom-rule-format)を使用する必要があります。

#### ルールを無効にする {#disable-a-rule}

{{< history >}}

- リモートルールセットを使用したルールを無効にする機能は、GitLab 16.0以降で[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/425251)になりました。

{{< /history >}}

アクティブにしたくないルールを無効にすることができます。アナライザーのデフォルトルールセットからルールを無効にするには:

1. [ルールセット設定ファイルを作成](#create-a-ruleset-configuration-file)します(まだ存在しない場合)。
1. `disabled`フラグを、[`ruleset`セクション](custom_rulesets_schema.md#the-secretsruleset-section)のコンテキストで`true`に設定します。
1. 1つ以上の`ruleset.identifier`サブセクションで、無効にするルールをリストします。すべての[`ruleset.identifier`セクション](custom_rulesets_schema.md#the-secretsrulesetidentifier-section)には、次のものがあります:
   - 事前定義されたルール識別子の`type`フィールド。
   - ルール名の`value`フィールド。

次の`secret-detection-ruleset.toml`ファイルでは、無効になっているルールは識別子の`type`と`value`によって照合されます:

```toml
[secrets]
  [[secrets.ruleset]]
    disable = true
    [secrets.ruleset.identifier]
      type  = "gitleaks_rule_id"
      value = "RSA private key"
```

#### ルールをオーバーライドする {#override-a-rule}

{{< history >}}

- リモートルールセットを使用してルールをオーバーライドする機能は、GitLab 16.0以降で[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/425251)になりました。

{{< /history >}}

カスタマイズする特定のルールがある場合は、それらをオーバーライドできます。たとえば、特定の種類のシークレットの重大度を高めることができます。これは、それをリークすると、ワークフローに大きな影響を与えるためです。

アナライザーのデフォルトルールセットからルールをオーバーライドするには:

1. [ルールセット設定ファイルを作成](#create-a-ruleset-configuration-file)します(まだ存在しない場合)。
1. 1つ以上の`ruleset.identifier`サブセクションで、オーバーライドするルールをリストします。すべての[`ruleset.identifier`セクション](custom_rulesets_schema.md#the-secretsrulesetidentifier-section)には、次のものがあります:
   - 事前定義されたルール識別子の`type`フィールド。
   - ルール名の`value`フィールド。
1. [`ruleset.override`コンテキスト](custom_rulesets_schema.md#the-secretsrulesetoverride-section)の[`ruleset`セクション](custom_rulesets_schema.md#the-secretsruleset-section)で、オーバーライドするキーを指定します。任意のキーの組み合わせをオーバーライドできます。有効なキーは次のとおりです:
   - `description`
   - `message`
   - `name`
   - `severity` (有効なオプションは、`Critical`、`High`、`Medium`、`Low`、`Unknown`、`Info`です)

次の`secret-detection-ruleset.toml`ファイルでは、ルールは識別子の`type`と`value`によって照合され、その後オーバーライドされます:

```toml
[secrets]
  [[secrets.ruleset]]
    [secrets.ruleset.identifier]
      type  = "gitleaks_rule_id"
      value = "RSA private key"
    [secrets.ruleset.override]
      description = "OVERRIDDEN description"
      message     = "OVERRIDDEN message"
      name        = "OVERRIDDEN name"
      severity    = "Info"
```

#### リモートルールセットを使用する場合 {#with-a-remote-ruleset}

リモートルールセットは、現在のリポジトリの外部に保存されている設定ファイルです。これを使用して、複数のプロジェクトにわたってルールを変更できます。

リモートルールセットを使用して事前定義されたルールを変更するには、`SECRET_DETECTION_RULESET_GIT_REFERENCE` [CI/CD変数](../../../../ci/variables/_index.md)を使用できます:

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

variables:
  SECRET_DETECTION_RULESET_GIT_REFERENCE: "gitlab.com/example-group/remote-ruleset-project"
```

パイプラインシークレット検出は、構成がCI/CD変数によって参照されるリポジトリの`.gitlab/secret-detection-ruleset.toml`ファイルで定義されていることを前提としています。リモートルールセットが保存されている場所です。そのファイルが存在しない場合は、[作成](#create-a-ruleset-configuration-file)し、前に概説したように、事前定義されたルールを[オーバーライド](#override-a-rule)または[無効にする](#disable-a-rule)手順に従ってください。

{{< alert type="note" >}}

プロジェクト内のローカル`.gitlab/secret-detection-ruleset.toml`ファイルは、デフォルトで`SECRET_DETECTION_RULESET_GIT_REFERENCE`よりも優先されます。これは、`SECURE_ENABLE_LOCAL_CONFIGURATION`が`true`に設定されているためです。`SECURE_ENABLE_LOCAL_CONFIGURATION`を`false`に設定すると、ローカルファイルは無視され、デフォルト構成または`SECRET_DETECTION_RULESET_GIT_REFERENCE` (設定されている場合) が使用されます。

{{< /alert >}}

`SECRET_DETECTION_RULESET_GIT_REFERENCE`変数は、URI、オプションの認証、およびオプションのGitセキュアハッシュアルゴリズムを指定するための[Git URI](https://git-scm.com/docs/git-clone#_git_urls)と同様の形式を使用します。変数は次の形式を使用します:

```plaintext
<AUTH_USER>:<AUTH_PASSWORD>@<PROJECT_PATH>@<GIT_SHA>
```

設定ファイルが認証を必要とするプライベートプロジェクトに保存されている場合は、CI/CD変数に安全に保存されている[グループアクセストークン](../../../group/settings/group_access_tokens.md)を使用して、リモートルールセットを読み込むことができます:

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

variables:
  SECRET_DETECTION_RULESET_GIT_REFERENCE: "group_2504721_bot_7c9311ffb83f2850e794d478ccee36f5:$GROUP_ACCESS_TOKEN@gitlab.com/example-group/remote-ruleset-project"
```

グループアクセストークンには、`read_repository`スコープと、少なくともレポーターロールが必要です。詳細については、[リポジトリの権限](../../../permissions.md#repository)を参照してください。

グループアクセストークンに関連付けられているユーザー名を見つける方法については、[グループのボットユーザー](../../../group/settings/group_access_tokens.md#bot-users-for-groups)を参照してください。

### デフォルトのルールセットを置き換える {#replace-the-default-ruleset}

[カスタマイズ](custom_rulesets_schema.md)を使用して、デフォルトのルールセット構成を置き換えることができます。それらは、[パススルー](custom_rulesets_schema.md#passthrough-types)を使用して単一の構成に結合できます。

パススルーを使用すると、次のことができます:

- 単一の構成に最大[20個のパススルー](custom_rulesets_schema.md#the-secretspassthrough-section)をチェーンして、事前定義されたルールを置き換えるか、または拡張します。
- [パススルーで環境変数を含め](custom_rulesets_schema.md#interpolate)ます。
- パススルーを評価するための[タイムアウト](custom_rulesets_schema.md#the-secrets-configuration-section)を設定します。
- 定義された各パススルーで使用されるTOML構文を[検証](custom_rulesets_schema.md#the-secrets-configuration-section)します。

#### インラインルールセットを使用する場合 {#with-an-inline-ruleset}

[`raw`パススルー](custom_rulesets_schema.md#passthrough-types)を使用して、インラインで提供される構成を使用してデフォルトのルールセットを置き換えることができます。

同じリポジトリに保存されている`.gitlab/secret-detection-ruleset.toml`設定ファイルに以下を追加し、`[[rules]]`で定義されたルールを必要に応じて調整します:

```toml
[secrets]
  [[secrets.passthrough]]
    type   = "raw"
    target = "gitleaks.toml"
    value  = """
title = "replace default ruleset with a raw passthrough"

[[rules]]
description = "Test for Raw Custom Rulesets"
regex = '''Custom Raw Ruleset T[est]{3}'''
"""
```

前の例では、定義された正規表現をチェックするルールを使用してデフォルトのルールセットを置き換えます - `Custom Raw Ruleset T`には、`e`、`s`、または`t`文字のいずれかからの3文字のサフィックスが付きます。

使用するパススルー構文の詳細については、[スキーマ](custom_rulesets_schema.md#schema)を参照してください。

#### ローカルルールセットを使用する場合 {#with-a-local-ruleset}

[`file`パススルー](custom_rulesets_schema.md#passthrough-types)を使用して、別のファイルでコミットされたデフォルトのルールセットを現在のリポジトリに置き換えることができます。

同じリポジトリに格納されている`.gitlab/secret-detection-ruleset.toml`設定ファイルに以下を追加し、ローカルルールセット設定でファイルのパスを指すように必要に応じて`value`を調整します:

```toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "config/gitleaks.toml"
```

これにより、`config/gitleaks.toml`ファイルで定義された構成を使用して、デフォルトのルールセットが置き換えられます。

使用するパススルー構文の詳細については、[スキーマ](custom_rulesets_schema.md#schema)を参照してください。

#### リモートルールセットを使用する場合 {#with-a-remote-ruleset-1}

`git`および`url`パススルーを使用して、リモートGitリポジトリまたはオンラインで保存されているファイルで定義された構成を使用して、デフォルトのルールセットを置き換えることができます。

リモートルールセットは、複数のプロジェクトで使用できます。たとえば、名前空間の1つの複数のプロジェクトに同じルールセットを適用する場合は、いずれかの種類のパススルーを使用してそのリモートルールセットを読み込むして、複数のプロジェクトで使用できるようにします。また、ルールセットの一元管理も可能になり、承認されたユーザーのみが編集できます。

`git`パススルーを使用するには、次のものをリポジトリに格納されている`.gitlab/secret-detection-ruleset.toml`設定ファイルに追加し、Gitリポジトリのアドレスを指すように`value`を調整します:

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "git"
    ref    = "main"
    subdir = "config"
    value  = "https://gitlab.com/user_group/central_repository_with_shared_ruleset"
```

この構成では、アナライザーは`user_group/central_repository_with_shared_ruleset`に格納されているリポジトリの`main`ブランチにある`config`ディレクトリ内の`gitleaks.toml`ファイルからルールセットを読み込みます。次に、`user_group/basic_repository`以外のプロジェクトで同じ構成を含めることができます。

または、`url`パススルーを使用して、リモートルールセット設定でデフォルトのルールセットを置き換えることもできます。

`url`パススルーを使用するには、次のものをリポジトリに格納されている`.gitlab/secret-detection-ruleset.toml`設定ファイルに追加し、リモートファイルのアドレスを指すように`value`を調整します:

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "url"
    target = "gitleaks.toml"
    value  = "https://example.com/gitleaks.toml"
```

この構成では、アナライザーは指定されたアドレスに格納されている`gitleaks.toml`ファイルからルールセット構成を読み込みます。

使用するパススルー構文の詳細については、[スキーマ](custom_rulesets_schema.md#schema)を参照してください。

#### プライベートリモートルールセットを使用する {#with-a-private-remote-ruleset}

ルールセット構成がプライベートリポジトリに格納されている場合は、パススルーの[`auth`設定](custom_rulesets_schema.md#the-secretspassthrough-section)を使用してリポジトリにアクセスするための認証情報を提供する必要があります。

{{< alert type="note" >}}

`auth`設定は、`git`パススルーでのみ機能します。

{{< /alert >}}

プライベートリポジトリに格納されているリモートルールセットを使用するには、次のものをリポジトリに格納されている`.gitlab/secret-detection-ruleset.toml`設定ファイルに追加し、Gitリポジトリのアドレスを指すように`value`を調整し、適切な認証情報を使用するように`auth`を更新します:

```toml
[secrets]
  [[secrets.passthrough]]
    type   = "git"
    ref    = "main"
    auth   = "USERNAME:PASSWORD" # replace USERNAME and PASSWORD as appropriate
    subdir = "config"
    value  = "https://gitlab.com/user_group/central_repository_with_shared_ruleset"
```

{{< alert type="warning" >}}

この機能を使用する際は、認証情報の漏洩に注意してください。リスクを最小限に抑えるために環境変数を使用する方法の例については、[このセクション](custom_rulesets_schema.md#interpolate)を確認してください。

{{< /alert >}}

使用するパススルー構文の詳細については、[スキーマ](custom_rulesets_schema.md#schema)を参照してください。

### デフォルトのルールセットを拡張する {#extend-the-default-ruleset}

また、必要に応じて、追加のルールを使用して[デフォルトのルールセット](../detected_secrets.md)構成を拡張することもできます。これは、デフォルトのルールセットでGitLabによって維持されている信頼性の高い事前定義されたルールから引き続き恩恵を受けたいが、独自のプロジェクトおよびネームスペースで使用される可能性のある種類のシークレットのルールも追加する場合に役立ちます。新しいルールは、[カスタムルール形式](custom_rulesets_schema.md#custom-rule-format)に従う必要があります。

#### ローカルルールセットを使用する場合 {#with-a-local-ruleset-1}

`file`パススルーを使用してデフォルトのルールセットを拡張し、追加のルールを追加できます。

同じリポジトリに格納されている`.gitlab/secret-detection-ruleset.toml`設定ファイルに以下を追加し、拡張設定ファイルのパスを指すように必要に応じて`value`を調整します:

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "extended-gitleaks-config.toml"
```

`extended-gitleaks-config.toml`に格納されている拡張設定は、CI/CDパイプライン内のアナライザーで使用される設定に含まれています。

以下の例では、検出される正規表現を定義する新しい`[[rules]]`セクションを追加します:

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
  id = "example_api_key"
  description = "Example Service API Key"
  regex = '''example_api_key'''

[[rules]]
  id = "example_api_secret"
  description = "Example Service API Secret"
  regex = '''example_api_secret'''
```

このルールセット設定により、アナライザーは、定義された正規表現パターンと一致する文字列を検出します。

使用するパススルーの構文の詳細については、[スキーマ](custom_rulesets_schema.md#schema)を参照してください。

#### リモートルールセットを使用する場合 {#with-a-remote-ruleset-2}

デフォルトのルールセットをリモートルールセットに置き換える方法と同様に、`.gitlab/secret-detection-ruleset.toml`設定ファイルがあるリポジトリの外部に格納されているリモートGitリポジトリまたはファイルに格納されている設定を使用して、デフォルトのルールセットを拡張することもできます。

これは、前述した`git`または`url`のいずれかのパススルーを使用することで実現できます。

`git`パススルーでそれを行うには、同じリポジトリに格納されている`.gitlab/secret-detection-ruleset.toml`設定ファイルに以下を追加し、拡張された設定ファイルのパスを指すように、必要に応じて`value`、`ref`、および`subdir`を調整します:

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "git"
    ref    = "main"
    subdir = "config"
    value  = "https://gitlab.com/user_group/central_repository_with_shared_ruleset"
```

パイプラインのシークレット検出は、リモートルールセット設定ファイルが`gitleaks.toml`という名前で、参照されているリポジトリの`main`ブランチの`config`ディレクトリに格納されていることを前提としています。

デフォルトのルールセットを拡張するには、`gitleaks.toml`ファイルで、前の例と同様に`[extend]`ディレクティブを使用する必要があります:

```toml
# https://gitlab.com/user_group/central_repository_with_shared_ruleset/-/raw/main/config/gitleaks.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
  id = "example_api_key"
  description = "Example Service API Key"
  regex = '''example_api_key'''

[[rules]]
  id = "example_api_secret"
  description = "Example Service API Secret"
  regex = '''example_api_secret'''
```

`url`パススルーを使用するには、同じリポジトリに格納されている`.gitlab/secret-detection-ruleset.toml`設定ファイルに以下を追加し、拡張された設定ファイルのパスを指すように、必要に応じて`value`を調整します

```toml
# .gitlab/secret-detection-ruleset.toml in https://gitlab.com/user_group/basic_repository
[secrets]
  [[secrets.passthrough]]
    type   = "url"
    target = "gitleaks.toml"
    value  = "https://example.com/gitleaks.toml"
```

使用するパススルーの構文の詳細については、[スキーマ](custom_rulesets_schema.md#schema)を参照してください。

#### スキャン実行ポリシーを使用する {#with-a-scan-execution-policy}

スキャン実行ポリシーでルールセットを拡張および適用するには、以下を実行します:

- [スキャン実行ポリシーでパイプラインシークレット検出設定をセットアップする](https://support.gitlab.com/hc/en-us/articles/18863735262364-How-to-set-up-a-centrally-managed-pipeline-secret-detection-configuration-applied-via-Scan-Execution-Policy)の手順に従ってください。

### 正規表現とパスを除外する {#ignore-patterns-and-paths}

パイプラインのシークレット検出によって特定の正規表現またはパスが検出されないようにする必要がある場合があります。たとえば、テストスイートで使用される偽のシークレットを含むファイルがあるとします。

その場合は、[Gitleaks' native `[allowlist]`](https://github.com/gitleaks/gitleaks#configuration)ディレクティブを使用して、特定のパターンまたはパスを除外できます。

{{< alert type="note" >}}

この機能は、ローカルまたはリモートのルールセット設定ファイルを使用しているかどうかに関係なく機能します。以下の例では、`file`パススルーを使用してローカルルールセットを使用しています。

{{< /alert >}}

正規表現を無視するには、同じリポジトリに格納されている`.gitlab/secret-detection-ruleset.toml`設定ファイルに以下を追加し、拡張された設定ファイルのパスを指すように、必要に応じて`value`を調整します:

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "extended-gitleaks-config.toml"
```

`extended-gitleaks-config.toml`に格納されている拡張設定は、アナライザーで使用される設定に含まれています。

以下の例では、無視する（「許可された」）シークレットに一致する正規表現を定義する`[allowlist]`ディレクティブを追加します:

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[allowlist]
  description = "allowlist of patterns to ignore in detection"
  regexTarget = "match"
  regexes = [
    '''glpat-[0-9a-zA-Z_\\-]{20}'''
  ]
```

これにより、数字と文字の20文字のサフィックスを持つ`glpat-`に一致する文字列は無視されます。

同様に、スキャンから特定のパスを除外できます。以下の例では、`[allowlist]`ディレクティブの下で無視するパスの配列を定義します。パスには、正規表現または特定のファイルパスのいずれかを指定できます:

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[allowlist]
  description = "allowlist of patterns to ignore in detection"
  paths = [
    '''/gitleaks.toml''',
    '''(.*?)(jpg|gif|doc|pdf|bin|svg|socket)'''
  ]
```

これにより、`/gitleaks.toml`ファイル、または指定された拡張子のいずれかで終わるファイルで検出されたシークレットは無視されます。

[Gitleaks v8.20.0](https://github.com/gitleaks/gitleaks/releases/tag/v8.20.0)以降、`[allowlist]`で`regexTarget`を使用することもできます。つまり、既存のルールをオーバーライドすることで、[パーソナルアクセストークンのプレフィックス](../../../../administration/settings/account_and_limit_settings.md#personal-access-token-prefix)または[カスタムインスタンスプレフィックス](../../../../administration/settings/account_and_limit_settings.md#instance-token-prefix)を設定できます。たとえば、`personal access tokens`の場合は、次のように設定できます:

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
# Rule id you want to override:
id = "gitlab_personal_access_token"
# all the other attributes from the default rule are inherited
    [[rules.allowlists]]
    regexTarget = "line"
    regexes = [ '''CUSTOMglpat-''' ]

[[rules]]
id = "gitlab_personal_access_token_with_custom_prefix"
regex = '<Regex that match a personal access token starting with your CUSTOM prefix>'

```

[デフォルトルールセット](https://gitlab.com/gitlab-org/security-products/secret-detection/secret-detection-rules/-/blob/main/rules/mit/gitlab/gitlab.toml)で設定されているすべてのルールを考慮する必要があることに注意してください。

使用するパススルーの構文の詳細については、[スキーマ](custom_rulesets_schema.md#schema)を参照してください。

### インラインでシークレットを無視する {#ignore-secrets-inline}

場合によっては、インラインでシークレットを無視する必要がある場合があります。たとえば、例またはテストスイートに偽のシークレットが含まれている場合があります。これらのインスタンスでは、脆弱性としてレポートされるのではなく、シークレットを無視する必要があります。

シークレットを無視するには、シークレットを含む行にコメントとして`gitleaks:allow`を追加します。

例: 

```ruby
"A personal token for GitLab will look like glpat-JUST20LETTERSANDNUMB"  # gitleaks:allow
```

### 複雑な文字列の検出 {#detecting-complex-strings}

[デフォルトルールセット](_index.md#detected-secrets)は、誤検出率の低い構造化文字列を検出するためのパターンを提供します。ただし、パスワードのようなより複雑な文字列を検出したい場合があります。[Gitleaksは先読みまたは後読みをサポートしていない](https://github.com/google/re2/issues/411)ため、構造化されていない文字列を検出するための信頼性の高い一般的なルールを作成することはできません。

すべての複雑な文字列を検出できるわけではありませんが、特定のユースケースを満たすようにルールセットを拡張できます。

たとえば、このルールは、Gitleaksのデフォルトルールセットの[`generic-api-key`ルール](https://github.com/gitleaks/gitleaks/blob/4e43d1109303568509596ef5ef576fbdc0509891/config/gitleaks.toml#L507-L514)を変更します:

```regex
(?i)(?:pwd|passwd|password)(?:[0-9a-z\-_\t .]{0,20})(?:[\s|']|[\s|"]){0,3}(?:=|>|=:|:{1,3}=|\|\|:|<=|=>|:|\?=)(?:'|\"|\s|=|\x60){0,5}([0-9a-z\-_.=\S_]{3,50})(?:['|\"|\n|\r|\s|\x60|;]|$)
```

この正規表現は以下に一致します:

1. `pwd`、`passwd`、または`password`で始まる大文字と小文字を区別しない識別子。`secret`や`key`のように、他のバリエーションでこれを調整できます。
1. 識別子に続くサフィックス。サフィックスは数字、文字、および記号の組み合わせであり、長さは0〜23文字です。
1. `=`、`:=`、`:`、または`=>`などの一般的に使用される代入演算子。
1. シークレットの検出を支援するために境界としてよく使用される、シークレットのプレフィックス。
1. 数字、文字、および記号の文字列で、長さは3〜50文字です。これはシークレット自体です。より長い文字列が必要な場合は、長さを調整できます。
1. シークレットのサフィックス。境界としてよく使用されます。これは、ティック、改行、改行などの一般的な結末に一致します。

この正規表現に一致する文字列の例を次に示します:

```plaintext
pwd = password1234
passwd = 'p@ssW0rd1234'
password = thisismyverylongpassword
password => mypassword
password := mypassword
password: password1234
"password" = "p%ssward1234"
'password': 'p@ssW0rd1234'
```

この正規表現を使用するには、このページに記載されているいずれかの方法でルールセットを拡張します。

たとえば、このルールを含む[ローカルルールセット](#with-a-local-ruleset-1)でデフォルトのルールセットを拡張するとします。

同じリポジトリに格納されている`.gitlab/secret-detection-ruleset.toml`設定ファイルに以下を追加します。拡張された設定ファイルのパスを指すように`value`を調整します:

```toml
# .gitlab/secret-detection-ruleset.toml
[secrets]
  [[secrets.passthrough]]
    type   = "file"
    target = "gitleaks.toml"
    value  = "extended-gitleaks-config.toml"
```

`extended-gitleaks-config.toml`ファイルで、使用する正規表現を含む新しい`[[rules]]`セクションを追加します:

```toml
# extended-gitleaks-config.toml
[extend]
# Extends default packaged ruleset, NOTE: do not change the path.
path = "/gitleaks.toml"

[[rules]]
  description = "Generic Password Rule"
  id = "generic-password"
  regex = '''(?i)(?:pwd|passwd|password)(?:[0-9a-z\-_\t .]{0,20})(?:[\s|']|[\s|"]){0,3}(?:=|>|=:|:{1,3}=|\|\|:|<=|=>|:|\?=)(?:'|\"|\s|=|\x60){0,5}([0-9a-z\-_.=\S_]{3,50})(?:['|\"|\n|\r|\s|\x60|;]|$)'''
  entropy = 3.5
  keywords = ["pwd", "passwd", "password"]
```

{{< alert type="note" >}}

この例の設定は、便宜のためにのみ提供されており、すべてのユースケースに適用できるとは限りません。複雑な文字列を検出するようにルールセットを設定すると、多数の誤検出が作成されたり、特定のパターンのキャプチャに失敗したりする可能性があります。

{{< /alert >}}

### デモ {#demonstrations}

これらの設定オプションの一部を示す[デモプロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection)があります。

以下は、デモプロジェクトとそれらに関連するワークフローの表です:

| アクション/ワークフロー         | 適用先/経由   | インラインまたはローカルルールセットを使用                                                                                                                                                                                                                                                                                                                                                                                       | リモートルールセットを使用 |
|-------------------------|------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------|
| ルールを無効にする          | 事前定義ルール | [ローカルルールセット](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/disable-rule-project/-/blob/main/.gitlab/secret-detection-ruleset.toml?ref_type=heads) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/disable-rule-project)   | [リモートルールセット](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/disable-rule-ruleset) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/disable-rule-project) |
| ルールをオーバーライドする         | 事前定義ルール | [ローカルルールセット](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/override-rule-project/-/blob/main/.gitlab/secret-detection-ruleset.toml?ref_type=heads) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/local-ruleset/override-rule-project) | [リモートルールセット](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/override-rule-ruleset) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/modify-default-ruleset/remote-ruleset/override-rule-project) |
| デフォルトのルールセットを置き換える | ファイルパススルー | [ローカルルールセット](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/file-passthrough/-/blob/main/config/gitleaks.toml) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/file-passthrough)                                                                     | 該当なし      |
| デフォルトのルールセットを置き換える | Rawパススルー  | [インラインルールセット](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/raw-passthrough/-/blob/main/.gitlab/secret-detection-ruleset.toml?ref_type=heads) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/raw-passthrough)                                      | 該当なし      |
| デフォルトのルールセットを置き換える | Gitパススルー  | 該当なし                                                                                                                                                                                                                                                                                                                                                                                                     | [リモートルールセット](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-replace/config/gitleaks.toml) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/git-passthrough) |
| デフォルトのルールセットを置き換える | URLパススルー  | 該当なし                                                                                                                                                                                                                                                                                                                                                                                                     | [リモートルールセット](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-replace/config/gitleaks.toml) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/replace-default-ruleset/url-passthrough) |
| デフォルトのルールセットを拡張する  | ファイルパススルー | [ローカルルールセット](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/file-passthrough)                                                       | 該当なし      |
| デフォルトのルールセットを拡張する  | Gitパススルー  | 該当なし                                                                                                                                                                                                                                                                                                                                                                                                     | [リモートルールセット](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-extend/config/gitleaks.toml) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/git-passthrough) |
| デフォルトのルールセットを拡張する  | URLパススルー  | 該当なし                                                                                                                                                                                                                                                                                                                                                                                                     | [リモートルールセット](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-extend/config/gitleaks.toml) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/extend-default-ruleset/url-passthrough) |
| パスを無視する            | ファイルパススルー | [ローカルルールセット](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/file-passthrough)                                                                           | 該当なし      |
| パスを無視する            | Gitパススルー  | 該当なし                                                                                                                                                                                                                                                                                                                                                                                                     | [リモートルールセット](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-paths/config/gitleaks.toml) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/git-passthrough) |
| パスを無視する            | URLパススルー  | 該当なし                                                                                                                                                                                                                                                                                                                                                                                                     | [リモートルールセット](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-paths/config/gitleaks.toml) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-paths/url-passthrough) |
| パターンを無視する         | ファイルパススルー | [ローカルルールセット](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/file-passthrough)                                                                     | 該当なし      |
| パターンを無視する         | Gitパススルー  | 該当なし                                                                                                                                                                                                                                                                                                                                                                                                     | [リモートルールセット](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-patterns/config/gitleaks.toml) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/git-passthrough) |
| パターンを無視する         | URLパススルー  | 該当なし                                                                                                                                                                                                                                                                                                                                                                                                     | [リモートルールセット](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-patterns/config/gitleaks.toml) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-patterns/url-passthrough) |
| 値を無視する           | ファイルパススルー | [ローカルルールセット](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/file-passthrough/-/blob/main/config/extended-gitleaks-config.toml) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/file-passthrough)                                                                         | 該当なし      |
| 値を無視する           | Gitパススルー  | 該当なし                                                                                                                                                                                                                                                                                                                                                                                                     | [リモートルールセット](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-values/config/gitleaks.toml) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/git-passthrough) |
| 値を無視する           | URLパススルー  | 該当なし                                                                                                                                                                                                                                                                                                                                                                                                     | [リモートルールセット](https://gitlab.com/gitlab-org/security-products/tests/secrets-passthrough-git-and-url-test/-/blob/config-demos-ignore-values/config/gitleaks.toml) / [プロジェクト](https://gitlab.com/gitlab-org/security-products/demos/analyzer-configurations/secret-detection/ignore-values/url-passthrough) |

リモートルールセットの設定について説明するビデオデモもあります:

- [ローカルおよびリモートルールセットを使用したシークレット検出](https://youtu.be/rsN1iDug5GU)

## オフライン設定 {#offline-configuration}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

オフライン環境は、インターネットを介した外部リソースへのアクセスが制限、規制、または断続的です。このような環境のインスタンスでは、パイプラインのシークレット検出には、いくつかの設定の変更が必要です。このセクションの手順は、[オフライン環境](../../offline_deployments/_index.md)に詳述されている手順と組み合わせて完了する必要があります。

### GitLab Runnerを設定する {#configure-gitlab-runner}

デフォルトでは、Runnerは、ローカルコピーが利用可能な場合でも、GitLabコンテナレジストリからDockerイメージをプルしようとします。Dockerイメージが最新の状態に保たれるようにするには、このデフォルトの設定を使用する必要があります。ただし、ネットワーキング接続が利用できない場合は、デフォルトのGitLab Runner `pull_policy`変数を変更する必要があります。

GitLab RunnerのCI/CD変数`pull_policy`を[`if-not-present`](https://docs.gitlab.com/runner/executors/docker.html#using-the-if-not-present-pull-policy)に設定します。

### ローカルパイプラインシークレット検出アナライザーイメージを使用する {#use-local-pipeline-secret-detection-analyzer-image}

GitLabコンテナレジストリではなく、ローカルDockerレジストリからイメージを取得する場合は、ローカルパイプラインシークレット検出アナライザーイメージを使用します。

前提要件: 

- Dockerイメージをローカルのオフラインレジストリにインポートするプロセスは、ネットワーキングのセキュリティポリシーによって異なります。IT部門に相談して、外部リソースをインポートまたは一時的にアクセスするための承認済みプロセスを確認してください。

1. デフォルトのパイプラインシークレット検出アナライザーイメージを`registry.gitlab.com`から[ローカルDockerコンテナレジストリ](../../../packages/container_registry/_index.md)にインポートします:

   ```plaintext
   registry.gitlab.com/security-products/secrets:6
   ```

   パイプラインシークレット検出アナライザーのイメージは[定期的に更新](../../detect/vulnerability_scanner_maintenance.md)されるため、ローカルコピーも定期的に更新する必要があります。

1. CI/CD変数`SECURE_ANALYZERS_PREFIX`をローカルDockerコンテナレジストリに設定します。

   ```yaml
   include:
     - template: Jobs/Secret-Detection.gitlab-ci.yml

   variables:
     SECURE_ANALYZERS_PREFIX: "localhost:5000/analyzers"
   ```

パイプラインシークレット検出ジョブは、インターネットアクセスを必要とせずに、アナライザーDockerイメージのローカルコピーを使用するようになりました。

## カスタムSSL CA認証局を使用する {#using-a-custom-ssl-ca-certificate-authority}

カスタム認証局を信頼するには、`ADDITIONAL_CA_CERT_BUNDLE`変数を、信頼するCA証明書のバンドルに設定します。これは、`.gitlab-ci.yml`ファイル、ファイル変数、またはCI/CD変数のいずれかで行います。

- `.gitlab-ci.yml`ファイルでは、`ADDITIONAL_CA_CERT_BUNDLE`の値は、[X.509 PEM公開キー証明書のテキスト表現](https://www.rfc-editor.org/rfc/rfc7468#section-5.1)を含める必要があります。

  例: 

  ```yaml
  variables:
    ADDITIONAL_CA_CERT_BUNDLE: |
        -----BEGIN CERTIFICATE-----
        MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
        ...
        jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
        -----END CERTIFICATE-----
  ```

- ファイル変数を使用する場合は、`ADDITIONAL_CA_CERT_BUNDLE`の値を証明機関へのパスに設定します。

- 変数を使用する場合は、`ADDITIONAL_CA_CERT_BUNDLE`の値を証明機関のテキスト表現に設定します。
