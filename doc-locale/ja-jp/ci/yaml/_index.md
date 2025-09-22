---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CD YAML構文リファレンス
description: パイプライン設定キーワード、構文、例、インプット。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このドキュメントでは、GitLabの`.gitlab-ci.yml`ファイルの設定オプションについて説明します。このファイルでは、パイプラインを構成するCI/CDジョブを定義します。

- [基本的なCI/CDの概念](../_index.md)をすでに理解している方は、[シンプル](../quick_start/_index.md)または[複雑](../quick_start/tutorial.md)なパイプラインの構築手順を示すチュートリアルに沿って、独自の`.gitlab-ci.yml`ファイルを作成してみてください。
- さまざまな例については、[GitLab CI/CDの例](../examples/_index.md)を参照してください。
- エンタープライズで使用される大規模な`.gitlab-ci.yml`ファイルを確認するには、[`gitlab`の`.gitlab-ci.yml`ファイル](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab-ci.yml)を参照してください。

`.gitlab-ci.yml`ファイルを編集しているときは、[CI Lint](lint.md)ツールでこのファイルを検証できます。

<!--
If you are editing content on this page, follow the instructions for documenting keywords:
https://docs.gitlab.com/development/cicd/cicd_reference_documentation_guide/
-->

## キーワード {#keywords}

GitLab CI/CDパイプラインの設定には、次の要素が含まれます。

- パイプラインの動作を設定する[グローバルキーワード](#global-keywords):

  | キーワード                 | 説明 |
  |-------------------------|:------------|
  | [`default`](#default)   | ジョブキーワードに対するカスタムデフォルト値。 |
  | [`include`](#include)   | 他のYAMLファイルから設定をインポートします。 |
  | [`stages`](#stages)     | パイプラインステージの名前と順序。 |
  | [`workflow`](#workflow) | 実行するパイプラインのタイプを制御します。 |

- [ヘッダーキーワード](#header-keywords)

  | キーワード         | 説明 |
  |-----------------|:------------|
  | [`spec`](#spec) | 外部設定ファイルの仕様を定義します。 |

- [ジョブキーワード](#job-keywords)を使用して設定される[ジョブ](../jobs/_index.md):

  | キーワード                                       | 説明 |
  |:----------------------------------------------|:------------|
  | [`after_script`](#after_script)               | ジョブの後に実行される一連のコマンドをオーバーライドします。 |
  | [`allow_failure`](#allow_failure)             | ジョブの失敗を許容します。ジョブが失敗してもパイプライン全体の失敗とはなりません。 |
  | [`artifacts`](#artifacts)                     | 成功時にジョブに添付されるファイルとディレクトリのリスト。 |
  | [`before_script`](#before_script)             | ジョブの前に実行される一連のコマンドをオーバーライドします。 |
  | [`cache`](#cache)                             | 後続の実行間でキャッシュされるファイルのリスト。 |
  | [`coverage`](#coverage)                       | 指定されたジョブのコードカバレッジ設定。 |
  | [`dast_configuration`](#dast_configuration)   | ジョブレベルでDASTプロファイルの設定を使用します。 |
  | [`dependencies`](#dependencies)               | アーティファクトのフェッチ元のジョブのリストを指定することで、特定のジョブに渡されるアーティファクトを制限します。 |
  | [`environment`](#environment)                 | ジョブのデプロイ先の環境の名前。 |
  | [`extends`](#extends)                         | このジョブが継承する設定エントリ。 |
  | [`identity`](#identity)                       | アイデンティティフェデレーションを使用したサードパーティサービスの認証を行います。 |
  | [`image`](#image)                             | Dockerイメージを使用します。 |
  | [`inherit`](#inherit)                         | すべてのジョブが継承するグローバルデフォルトを選択します。 |
  | [`interruptible`](#interruptible)             | より新しい実行によってジョブが冗長になった場合に、ジョブをキャンセルできるかどうかを定義します。 |
  | [`manual_confirmation`](#manual_confirmation) | 手動ジョブのカスタム確認メッセージを定義します。 |
  | [`needs`](#needs)                             | ステージの順序よりも早い時点でジョブを実行します。 |
  | [`pages`](#pages)                             | GitLab Pagesで使用するためにジョブの結果をアップロードします。 |
  | [`parallel`](#parallel)                       | 並列実行するジョブインスタンスの数。 |
  | [`release`](#release)                         | [リリース](../../user/project/releases/_index.md)オブジェクトを生成するようにRunnerに指示します。 |
  | [`resource_group`](#resource_group)           | ジョブの並行処理を制限します。 |
  | [`retry`](#retry)                             | ジョブが失敗した場合に、ジョブを自動的に再試行できる条件と回数。 |
  | [`rules`](#rules)                             | ジョブの一部の属性を評価し、そのジョブが作成されるかどうかを決定する条件のリスト。 |
  | [`script`](#script)                           | Runnerが実行するShellスクリプト。 |
  | [`run`](#run)                                 | Runnerが実行する実行設定。 |
  | [`secrets`](#secrets)                         | ジョブに必要なCI/CDシークレット。 |
  | [`services`](#services)                       | Dockerサービスイメージを使用します。 |
  | [`stage`](#stage)                             | ジョブステージを定義します。 |
  | [`tags`](#tags)                               | Runnerを選択するために使用されるタグのリスト。 |
  | [`timeout`](#timeout)                         | プロジェクト全体の設定よりも優先される、カスタムのジョブレベルのタイムアウトを定義します。 |
  | [`trigger`](#trigger)                         | ダウンストリームパイプライントリガーを定義します。 |
  | [`when`](#when)                               | ジョブを実行するタイミング。 |

- [CI/CD変数](#variables)

  | キーワード                                   | 説明 |
  |:------------------------------------------|:------------|
  | [デフォルト`variables`](#default-variables) | パイプラインのすべてのジョブのデフォルトCI/CD変数を定義します。 |
  | [ジョブ`variables`](#job-variables)         | 個々のジョブのCI/CD変数を定義します。 |

- 現在は使用が推奨されていない[非推奨のキーワード](deprecated_keywords.md)。

## グローバルキーワード {#global-keywords}

一部のキーワードはジョブでは定義されません。これらのキーワードは、パイプラインの動作を制御するか、追加のパイプライン設定をインポートします。

### `default` {#default}

{{< history >}}

- `id_tokens`のサポートは、GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/419750)されました。

{{< /history >}}

一部のキーワードではグローバルデフォルトを設定できます。各デフォルトキーワードは、まだそのキーワードが定義されていないすべてのジョブにコピーされます。ジョブですでにそのキーワードが定義されている場合、デフォルトは使用されません。

**キーワードのタイプ**: グローバルキーワード。

**サポートされている値**: 以下のキーワードにはカスタムデフォルトを設定できます。

- [`after_script`](#after_script)
- [`artifacts`](#artifacts)
- [`before_script`](#before_script)
- [`cache`](#cache)
- [`hooks`](#hooks)
- [`id_tokens`](#id_tokens)
- [`image`](#image)
- [`interruptible`](#interruptible)
- [`retry`](#retry)
- [`services`](#services)
- [`tags`](#tags)
- [`timeout`](#timeout)。ただし、[イシュー213634](https://gitlab.com/gitlab-org/gitlab/-/issues/213634)のためこのキーワードには効果がありません。

**`default`の例**:

```yaml
default:
  image: ruby:3.0
  retry: 2

rspec:
  script: bundle exec rspec

rspec 2.7:
  image: ruby:2.7
  script: bundle exec rspec
```

この例では:

- `image: ruby:3.0`と`retry: 2`は、パイプラインのすべてのジョブのデフォルトキーワードです。
- `rspec`ジョブでは`image`と`retry`が定義されていないため、デフォルトの`image: ruby:3.0`と`retry: 2`が使用されます。
- `rspec 2.7`ジョブでは`retry`が定義されていませんが、`image`が明示的に定義されています。そのため、デフォルトの`retry: 2`が使用されますが、デフォルトの`image`は無視され、ジョブで定義されている`image: ruby:2.7`が使用されます。

**補足情報**:

- [`inherit:default`](#inheritdefault)を使用することで、ジョブごとにデフォルトキーワードの継承を制御できます。
- グローバルデフォルトは[ダウンストリームパイプライン](../pipelines/downstream_pipelines.md)には引き継がれません。ダウンストリームパイプラインは、それをトリガーしたアップストリームパイプラインとは独立して実行されます。

### `include` {#include}

`include`を使用して、外部のYAMLファイルをCI/CD設定にインクルードすることができます。1つの長い`.gitlab-ci.yml`ファイルを複数のファイルに分割することで読みやすさを向上させたり、複数の場所で同じ設定が重複する状況を減らしたりすることができます。

テンプレートファイルを中央のリポジトリに保存し、プロジェクトにインクルードすることもできます。

`include`ファイルは次のように処理されます。

- `.gitlab-ci.yml`ファイルの内容とマージされます。
- `include`キーワードの位置に関係なく、常に最初に評価され、`.gitlab-ci.yml`ファイルの内容とマージされます。

すべてのファイルを解決するための制限時間は30秒です。

**キーワードのタイプ**: グローバルキーワード。

**サポートされている値**: `include`サブキー。

- [`include:component`](#includecomponent)
- [`include:local`](#includelocal)
- [`include:project`](#includeproject)
- [`include:remote`](#includeremote)
- [`include:template`](#includetemplate)

オプションで使用可能:

- [`include:inputs`](#includeinputs)
- [`include:rules`](#includerules)
- [`include:integrity`](#includeintegrity)

**補足情報**:

- `include`キーワードでは[特定のCI/CD変数](includes.md#use-variables-with-include)のみを使用できます。
- マージを使用して、インクルードされるCI/CD設定をローカルでカスタマイズおよびオーバーライドできます。
- インクルードされる設定をオーバーライドするには、`.gitlab-ci.yml`ファイルに同じジョブ名またはグローバルキーワードを指定します。2つの設定がマージされ、インクルードされる設定よりも`.gitlab-ci.yml`ファイル内の設定が優先されます。
- 再実行する場合:
  - ジョブを再実行すると、`include`ファイルは再度フェッチされません。パイプラインのすべてのジョブは、パイプラインの作成時にフェッチされた設定を使用します。そのため、ソース`include`ファイルが変更されても、ジョブの再実行には影響しません。
  - パイプラインを再実行すると、`include`ファイルが再度フェッチされます。前回のパイプライン実行後にこれらのファイルが変更されていた場合、新しいパイプラインは変更された設定を使用します。
- デフォルトでは、[ネストされたインクルード](includes.md#use-nested-includes)を含めて、パイプラインごとに最大150個のインクルードを使用できます。補足情報を以下に示します。
  - [GitLab 16.0以降](https://gitlab.com/gitlab-org/gitlab/-/issues/207270)、GitLab Self-Managedのユーザーは、[最大インクルード数](../../administration/settings/continuous_integration.md#set-maximum-includes)の値を変更できるようになりました。
  - [GitLab 15.10以降](https://gitlab.com/gitlab-org/gitlab/-/issues/367150)、最大150個のインクルードを設定できます。ネストされたインクルードでは、同じファイルを複数回インクルードできますが、重複したインクルードもカウントの対象になります。
  - [GitLab 14.9からGitLab 15.9](https://gitlab.com/gitlab-org/gitlab/-/issues/28987)では、最大100個のインクルードを使用できます。ネストされたインクルードでは同じファイルを複数回インクルードできますが、重複は無視されます。

#### `include:component` {#includecomponent}

`include:component`を使用して、[CI/CDコンポーネント](../components/_index.md)をパイプライン設定に追加します。

**キーワードのタイプ**: グローバルキーワード。

**サポートされている値**: CI/CDコンポーネントの完全なアドレス（形式: `<fully-qualified-domain-name>/<project-path>/<component-name>@<specific-version>`）。

**`include:component`の例**:

```yaml
include:
  - component: $CI_SERVER_FQDN/my-org/security-components/secret-detection@1.0
```

**関連トピック**:

- [CI/CDコンポーネントを使用する](../components/_index.md#use-a-component)。

#### `include:local` {#includelocal}

`include:local`を使用して、`include`キーワードを含む設定ファイルと同じリポジトリおよびブランチにあるファイルをインクルードします。シンボリックリンクの代わりに`include:local`を使用します。

**キーワードのタイプ**: グローバルキーワード。

**サポートされている値**: 

ルートディレクトリ（`/`）を基準にしたフルパス:

- YAMLファイルの拡張子は、`.yml`または`.yaml`である必要があります。
- [ファイルパスではワイルドカード`*`と`**`を使用](includes.md#use-includelocal-with-wildcard-file-paths)できます。
- [特定のCI/CD変数](includes.md#use-variables-with-include)を使用できます。

**`include:local`の例**:

```yaml
include:
  - local: '/templates/.gitlab-ci-template.yml'
```

短縮構文を使用してパスを定義することもできます。

```yaml
include: '.gitlab-ci-production.yml'
```

**補足情報**:

- `.gitlab-ci.yml`ファイルとローカルファイルは、同じブランチに存在している必要があります。
- Gitサブモジュールパスを使用してローカルファイルをインクルードすることはできません。
- `include`設定は常に、パイプラインを実行しているプロジェクトではなく、`include`キーワードを含むファイルの場所を基準に評価されます。そのため、[ネストされた`include`](includes.md#use-nested-includes)が別のプロジェクトの設定ファイル内にある場合、`include: local`はその別のプロジェクト内でファイルを確認します。

#### `include:project` {#includeproject}

同じGitLabインスタンス上の別の非公開プロジェクトからファイルをインクルードするには、`include:project`と`include:file`を使用します。

**キーワードのタイプ**: グローバルキーワード。

**サポートされている値**: 

- `include:project`: GitLabプロジェクトのフルパス。
- `include:file`: ルートディレクトリ（`/`）を基準にしたファイルのフルパス、またはファイルパスの配列。YAMLファイルの拡張子は`.yml`または`.yaml`でなければなりません。
- `include:ref`: オプション: ファイルの取得元のref。指定しない場合、デフォルトはプロジェクトの`HEAD`です。
- [特定のCI/CD変数](includes.md#use-variables-with-include)を使用できます。

**`include:project`の例**:

```yaml
include:
  - project: 'my-group/my-project'
    file: '/templates/.gitlab-ci-template.yml'
  - project: 'my-group/my-subgroup/my-project-2'
    file:
      - '/templates/.builds.yml'
      - '/templates/.tests.yml'
```

`ref`を指定することもできます。

```yaml
include:
  - project: 'my-group/my-project'
    ref: main                                      # Git branch
    file: '/templates/.gitlab-ci-template.yml'
  - project: 'my-group/my-project'
    ref: v1.0.0                                    # Git Tag
    file: '/templates/.gitlab-ci-template.yml'
  - project: 'my-group/my-project'
    ref: 787123b47f14b552955ca2786bc9542ae66fee5b  # Git SHA
    file: '/templates/.gitlab-ci-template.yml'
```

**補足情報**:

- `include`設定は常に、パイプラインを実行しているプロジェクトではなく、`include`キーワードを含むファイルの場所を基準に評価されます。そのため、[ネストされた`include`](includes.md#use-nested-includes)が別のプロジェクトの設定ファイル内にある場合、`include: local`はその別のプロジェクト内でファイルを確認します。
- パイプラインが開始されると、すべての方法によってインクルードされた`.gitlab-ci.yml`ファイルの設定が評価されます。この設定はその時点でのスナップショットであり、データベースに保持されます。GitLabは、参照先の`.gitlab-ci.yml`ファイルの設定が変更されても、次のパイプラインが開始されるまではその変更を反映しません。
- 別の非公開プロジェクトのYAMLファイルをインクルードする場合、パイプラインを実行するユーザーは両方のプロジェクトのメンバーであり、パイプラインを実行するための適切な権限を持っている必要があります。ユーザーがインクルード対象のファイルにアクセスできない場合、`not found or access denied`エラーが表示されることがあります。
- 別のプロジェクトのCI/CD設定ファイルをインクルードする場合は注意してください。CI/CD設定ファイルが変更されても、パイプラインや通知はトリガーされません。セキュリティの観点では、これはサードパーティの依存関係をプルすることと似ています。`ref`については以下を検討してください。
  - 特定のSHAハッシュを使用する。これはもっとも安定したオプションです。目的のコミットが確実に参照されるように、40文字の完全なSHAハッシュを使用してください。`ref`に短いSHAハッシュを使用すると、あいまいになる可能性があるためです。
  - 他のプロジェクトの`ref`に対して、[保護ブランチ](../../user/project/repository/branches/protected.md)と[保護タグ](../../user/project/protected_tags.md#prevent-tag-creation-with-the-same-name-as-branches)の両方のルールを適用する。保護タグと保護ブランチは、変更される前に変更管理を通過する可能性が高くなります。

#### `include:remote` {#includeremote}

`include:remote`と完全なURLを使用して、別の場所にあるファイルをインクルードします。

**キーワードのタイプ**: グローバルキーワード。

**サポートされている値**: 

HTTP/HTTPS `GET`リクエストでアクセス可能な公開URL:

- リモートURLの認証はサポートされていません。
- YAMLファイルの拡張子は、`.yml`または`.yaml`である必要があります。
- [特定のCI/CD変数](includes.md#use-variables-with-include)を使用できます。

**`include:remote`の例**:

```yaml
include:
  - remote: 'https://gitlab.com/example-project/-/raw/main/.gitlab-ci.yml'
```

**補足情報**:

- すべての[ネストされたインクルード](includes.md#use-nested-includes)は、公開ユーザーとしてコンテキストなしで実行されるため、公開プロジェクトまたはテンプレートのみをインクルードできます。ネストされたインクルードの`include`セクションでは、変数は使用できません。
- 別のプロジェクトのCI/CD設定ファイルをインクルードする場合は注意してください。他のプロジェクトのファイルが変更されても、パイプラインや通知はトリガーされません。セキュリティの観点では、これはサードパーティの依存関係をプルすることと似ています。インクルードするファイルの整合性を検証するには、[`integrity`キーワード](#includeintegrity)を使用することを検討してください。所有している別のGitLabプロジェクトにリンクする場合は、[保護ブランチ](../../user/project/repository/branches/protected.md)と[保護タグ](../../user/project/protected_tags.md#prevent-tag-creation-with-the-same-name-as-branches)の両方を使用して変更管理ルールを適用することを検討してください。

#### `include:template` {#includetemplate}

`include:template`を使用して、[`.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)をインクルードします。

**キーワードのタイプ**: グローバルキーワード。

**サポートされている値**: 

[CI/CDテンプレート](../examples/_index.md#cicd-templates):

- すべてのテンプレートは、[`lib/gitlab/ci/templates`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)で確認できます。すべてのテンプレートが`include:template`での使用を前提として設計されているわけではないため、使用する前にテンプレートのコメントを確認してください。
- [特定のCI/CD変数](includes.md#use-variables-with-include)を使用できます。

**`include:template`の例**:

```yaml
# File sourced from the GitLab template collection
include:
  - template: Auto-DevOps.gitlab-ci.yml
```

複数の`include:template`ファイル:

```yaml
include:
  - template: Android-Fastlane.gitlab-ci.yml
  - template: Auto-DevOps.gitlab-ci.yml
```

**補足情報**:

- すべての[ネストされたインクルード](includes.md#use-nested-includes)は、公開ユーザーとしてコンテキストなしで実行されるため、公開プロジェクトまたはテンプレートのみをインクルードできます。ネストされたインクルードの`include`セクションでは、変数は使用できません。

#### `include:inputs` {#includeinputs}

{{< history >}}

- GitLab 15.11でベータ機能として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/391331)されました。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062)になりました。

{{< /history >}}

インクルードされる設定が[`spec:inputs`](#specinputs)を使用している場合、この設定をパイプラインに追加する際のインプットパラメータの値を設定するには、`include:inputs`を使用します。

**キーワードのタイプ**: グローバルキーワード。

**サポートされている値**: 文字列、数値、またはブール値。

**`include:inputs`の例**:

```yaml
include:
  - local: 'custom_configuration.yml'
    inputs:
      website: "My website"
```

この例では:

- `custom_configuration.yml`に含まれる設定がパイプラインに追加され、インクルードされる設定の`website`インプットには`My website`という値が設定されます。

**補足情報**:

- インクルードされる設定ファイルが[`spec:inputs:type`](#specinputstype)を使用している場合、インプット値は定義された型と一致している必要があります。
- インクルードされる設定ファイルが[`spec:inputs:options`](#specinputsoptions)を使用している場合、インプット値はリストされているオプションのいずれかと一致している必要があります。

**関連トピック**:

- [`include`の使用時にインプット値を設定する](../inputs/_index.md#for-configuration-added-with-include)。

#### `include:rules` {#includerules}

[`rules`](#rules)と`include`を組み合わせて使用すると、他の設定ファイルを条件付きでインクルードできます。

**キーワードのタイプ**: グローバルキーワード。

**サポートされている値**: 次の`rules`サブキー:

- [`rules:if`](#rulesif)。
- [`rules:exists`](#rulesexists)。
- [`rules:changes`](#ruleschanges)。

一部の[CI/CD変数がサポートされています](includes.md#use-variables-with-include)。

**`include:rules`の例**:

```yaml
include:
  - local: build_jobs.yml
    rules:
      - if: $INCLUDE_BUILDS == "true"

test-job:
  stage: test
  script: echo "This is a test job"
```

この例では、`INCLUDE_BUILDS`変数の値に応じて次のようになります。

- `true`の場合、`build_jobs.yml`の設定がパイプラインにインクルードされます。
- `true`ではない場合、または変数が存在しない場合は、`build_jobs.yml`の設定はパイプラインにインクルードされません。

**関連トピック**:

- `include`を使用した例:
  - [`rules:if`](includes.md#include-with-rulesif)。
  - [`rules:changes`](includes.md#include-with-ruleschanges)。
  - [`rules:exists`](includes.md#include-with-rulesexists)。

#### `include:integrity` {#includeintegrity}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178593)されました。

{{< /history >}}

`integrity`を`include:remote`と組み合わせて使用して、インクルードされるリモートファイルのSHA256ハッシュを指定します。`integrity`の値が実際の内容と一致しない場合、そのリモートファイルは処理されず、パイプラインは失敗します。

**キーワードのタイプ**: グローバルキーワード。

**サポートされている値**: インクルードされるコンテンツのBase64エンコードされたSHA256ハッシュ。

**`include:integrity`の例**:

```yaml
include:
  - remote: 'https://gitlab.com/example-project/-/raw/main/.gitlab-ci.yml'
    integrity: 'sha256-L3/GAoKaw0Arw6hDCKeKQlV1QPEgHYxGBHsH4zG1IY8='
```

### `stages` {#stages}

{{< history >}}

- 文字列のネストされた配列のサポートは、GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/439451)されました。

{{< /history >}}

`stages`を使用して、ジョブのグループを含むステージを定義します。ジョブに[`stage`](#stage)を指定することで、そのジョブを特定のステージで実行するように設定できます。

`.gitlab-ci.yml`ファイルで`stages`が定義されていない場合、デフォルトのパイプラインステージは次のとおりです。

- [`.pre`](#stage-pre)
- `build`
- `test`
- `deploy`
- [`.post`](#stage-post)

`stages`に列挙された項目の順序によって、ジョブの実行順序が決まります。

- 同じステージ内のジョブは並列実行されます。
- 次のステージのジョブは、前のステージのジョブが正常に完了した後に実行されます。

パイプラインに`.pre`ステージまたは`.post`ステージのジョブしか含まれていない場合、そのパイプラインは実行されません。これら以外のステージに少なくとも1つのジョブが必要です。

**キーワードのタイプ**: グローバルキーワード。

**`stages`の例**:

```yaml
stages:
  - build
  - test
  - deploy
```

この例では:

1. `build`内のすべてのジョブは並列実行されます。
1. `build`内のすべてのジョブが成功すると、`test`内のジョブが並列実行されます。
1. `test`内のすべてのジョブが成功すると、`deploy`内のジョブが並列実行されます。
1. `deploy`内のすべてのジョブが成功すると、パイプラインは`passed`としてマークされます。

いずれかのジョブが失敗すると、パイプラインは`failed`としてマークされ、後続ステージのジョブは開始されません。現在のステージのジョブは停止されず、引き続き実行されます。

**補足情報**:

- ジョブに[`stage`](#stage)が指定されていない場合、そのジョブには`test`ステージが割り当てられます。
- ステージが定義されていても、そのステージを使用するジョブが存在しない場合、パイプラインには表示されません。これは、[コンプライアンスパイプライン設定](../../user/compliance/compliance_pipelines.md)に役立ちます。
  - ステージはコンプライアンス設定で定義できますが、使用されなければ非表示のままになります。
  - 定義されたステージをデベロッパーがジョブ定義で使用すると、これらのステージが表示されます。

**関連トピック**:

- ジョブをより早い時点で開始し、ステージの順序を無視するには、[`needs`キーワード](#needs)を使用する。

### `workflow` {#workflow}

[`workflow`](workflow.md)を使用して、パイプラインの動作を制御します。

`workflow`の設定では、一部の[定義済みCI/CD変数](../variables/predefined_variables.md)を使用できますが、ジョブの開始時にのみ定義される変数は使用できません。

**関連トピック**:

- [`workflow: rules`の例](workflow.md#workflow-rules-examples)
- [ブランチパイプラインとマージリクエストパイプラインを切り替える](workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines)

#### `workflow:auto_cancel:on_new_commit` {#workflowauto_cancelon_new_commit}

{{< history >}}

- GitLab 16.8で`ci_workflow_auto_cancel_on_new_commit`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412473)されました。デフォルトでは無効になっています。
- GitLab 16.9の[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/434676)になりました。
- GitLab 16.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/434676)になりました。機能フラグ`ci_workflow_auto_cancel_on_new_commit`は削除されました。

{{< /history >}}

`workflow:auto_cancel:on_new_commit`を使用して、[冗長なパイプラインを自動キャンセル](../pipelines/settings.md#auto-cancel-redundant-pipelines)機能の動作を設定します。

**サポートされている値**: 

- `conservative`: パイプラインをキャンセルします。ただし、`interruptible: false`が設定されたジョブがまだ開始されていない場合に限ります。定義されていない場合は、この値がデフォルトです。
- `interruptible`: `interruptible: true`が設定されたジョブのみをキャンセルします。
- `none`: ジョブは自動キャンセルされません。

**`workflow:auto_cancel:on_new_commit`の例**:

```yaml
workflow:
  auto_cancel:
    on_new_commit: interruptible

job1:
  interruptible: true
  script: sleep 60

job2:
  interruptible: false  # Default when not defined.
  script: sleep 60
```

この例では:

- 新しいコミットがブランチにプッシュされると、GitLabは新しいパイプラインを作成し、`job1`と`job2`が開始されます。
- ジョブが完了する前に新しいコミットがブランチにプッシュされると、`job1`のみがキャンセルされます。

#### `workflow:auto_cancel:on_job_failure` {#workflowauto_cancelon_job_failure}

{{< history >}}

- GitLab 16.10で`auto_cancel_pipeline_on_job_failure`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/23605)されました。デフォルトでは無効になっています。
- GitLab 16.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/433163)になりました。機能フラグ`auto_cancel_pipeline_on_job_failure`は削除されました。

{{< /history >}}

`workflow:auto_cancel:on_job_failure`を使用して、いずれかのジョブが失敗した場合にキャンセルするジョブを設定します。

**サポートされている値**: 

- `all`: いずれかのジョブが失敗すると、パイプラインと実行中のすべてのジョブが直ちにキャンセルされます。
- `none`: ジョブは自動キャンセルされません。

**`workflow:auto_cancel:on_job_failure`の例**:

```yaml
stages: [stage_a, stage_b]

workflow:
  auto_cancel:
    on_job_failure: all

job1:
  stage: stage_a
  script: sleep 60

job2:
  stage: stage_a
  script:
    - sleep 30
    - exit 1

job3:
  stage: stage_b
  script:
    - sleep 30
```

この例では、`job2`が失敗した場合、`job1`がまだ実行中であればキャンセルされ、`job3`は開始されません。

**関連トピック**:

- [ダウンストリームパイプラインから親パイプラインを自動キャンセルする](../pipelines/downstream_pipelines.md#auto-cancel-the-parent-pipeline-from-a-downstream-pipeline)

#### `workflow:name` {#workflowname}

{{< history >}}

- GitLab 15.5で`pipeline_name`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/372538)されました。デフォルトでは無効になっています。
- GitLab 15.7の[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/376095)になりました。
- GitLab 15.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/376095)になりました。機能フラグ`pipeline_name`は削除されました。

{{< /history >}}

`workflow:`で`name`を使用して、パイプラインの名前を定義できます。

定義された名前はすべてのパイプラインに割り当てられます。名前の先頭または末尾のスペースは削除されます。

**サポートされている値**: 

- 文字列。
- [CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。
- 両方の組み合わせ。

**`workflow:name`の例**:

定義済み変数を使用した単純なパイプライン名:

```yaml
workflow:
  name: 'Pipeline for branch: $CI_COMMIT_BRANCH'
```

パイプラインの条件に応じてパイプライン名が異なる設定:

```yaml
variables:
  PROJECT1_PIPELINE_NAME: 'Default pipeline name'  # A default is not required

workflow:
  name: '$PROJECT1_PIPELINE_NAME'
  rules:
    - if: '$CI_MERGE_REQUEST_LABELS =~ /pipeline:run-in-ruby3/'
      variables:
        PROJECT1_PIPELINE_NAME: 'Ruby 3 pipeline'
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      variables:
        PROJECT1_PIPELINE_NAME: 'MR pipeline: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME'
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH  # For default branch pipelines, use the default name
```

**補足情報**:

- 名前が空の文字列の場合、パイプラインには名前が割り当てられません。CI/CD変数のみで構成された名前は、それらの変数もすべて空の場合、空の文字列と評価される可能性があります。
- `workflow:rules:variables`で定義された変数は、すべてのジョブで使用できる[デフォルト変数](#default-variables)になります。これには、デフォルトで変数をダウンストリームパイプラインに転送する[`trigger`](#trigger)ジョブも含まれます。ダウンストリームパイプラインが同じ変数を使用する場合、アップストリーム変数の値によって[変数が上書きされます](../variables/_index.md#cicd-variable-precedence)。そのため、次のいずれかを必ず実施してください。
  - 各プロジェクトのパイプライン設定で一意の変数名を使用する（例: `PROJECT1_PIPELINE_NAME`）。
  - トリガージョブで[`inherit:variables`](#inheritvariables)を使用し、ダウンストリームパイプラインに転送する正確な変数をリストする。

#### `workflow:rules` {#workflowrules}

`workflow`における`rules`キーワードは、[ジョブで定義される`rules`](#rules)に似ていますが、パイプライン全体を作成するかどうかを制御します。

trueと評価されるルールがない場合、パイプラインは実行されません。

**サポートされている値**: ジョブレベルの[`rules`](#rules)と同じキーワードの一部を使用できます。

- [`rules: if`](#rulesif)。
- [`rules: changes`](#ruleschanges)。
- [`rules: exists`](#rulesexists)。
- [`when`](#when)。`workflow`とともに使用する場合は`always`または`never`のみ指定できます。
- [`variables`](#workflowrulesvariables)。

**`workflow:rules`の例**:

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_TITLE =~ /-draft$/
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

この例では、パイプラインが実行されるのは、コミットタイトル（コミットメッセージの1行目）が`-draft`で終わっておらず、パイプラインが次のいずれかに該当する場合です。

- マージリクエスト。
- デフォルトブランチ。

**補足情報**:

- ルールがブランチパイプライン（デフォルトブランチ以外）とマージリクエストパイプラインの両方に一致する場合、[パイプラインが重複](../jobs/job_rules.md#avoid-duplicate-pipelines)して作成される可能性があります。
- `start_in`、`allow_failure`、`needs`は、`workflow:rules`でサポートされていませんが、構文違反にはなりません。効果はありませんが、将来的に構文エラーを引き起こす可能性があるため、`workflow:rules`では使用しないでください。詳細については、[イシュー436473](https://gitlab.com/gitlab-org/gitlab/-/issues/436473)を参照してください。

**関連トピック**:

- [`workflow:rules`の一般的な`if`句](workflow.md#common-if-clauses-for-workflowrules)。
- [`rules`を使用してマージリクエストパイプラインを実行する](../pipelines/merge_request_pipelines.md#add-jobs-to-merge-request-pipelines)。

#### `workflow:rules:variables` {#workflowrulesvariables}

`workflow:rules`で[`variables`](#variables)を使用して、特定のパイプライン条件の変数を定義します。

条件が一致すると変数が作成されます。この変数は、パイプライン内のすべてのジョブで使用できます。すでにその変数がデフォルト変数としてトップレベルで定義されている場合でも、`workflow`変数が優先され、デフォルト変数はオーバーライドされます。

**キーワードのタイプ**: グローバルキーワード。

**サポートされている値**: 変数名と値のペア:

- 名前には数字、英字、アンダースコア（`_`）のみを使用できます。
- 値は文字列でなければなりません。

**`workflow:rules:variables`の例**:

```yaml
variables:
  DEPLOY_VARIABLE: "default-deploy"

workflow:
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      variables:
        DEPLOY_VARIABLE: "deploy-production"  # Override globally-defined DEPLOY_VARIABLE
    - if: $CI_COMMIT_BRANCH =~ /feature/
      variables:
        IS_A_FEATURE: "true"                  # Define a new variable.
    - if: $CI_COMMIT_BRANCH                   # Run the pipeline in other cases

job1:
  variables:
    DEPLOY_VARIABLE: "job1-default-deploy"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      variables:                                   # Override DEPLOY_VARIABLE defined
        DEPLOY_VARIABLE: "job1-deploy-production"  # at the job level.
    - when: on_success                             # Run the job in other cases
  script:
    - echo "Run script with $DEPLOY_VARIABLE as an argument"
    - echo "Run another script if $IS_A_FEATURE exists"

job2:
  script:
    - echo "Run script with $DEPLOY_VARIABLE as an argument"
    - echo "Run another script if $IS_A_FEATURE exists"
```

ブランチがデフォルトブランチの場合:

- job1の`DEPLOY_VARIABLE`は`job1-deploy-production`です。
- job2の`DEPLOY_VARIABLE`は`deploy-production`です。

ブランチが`feature`の場合:

- job1の`DEPLOY_VARIABLE`は`job1-default-deploy`であり、`IS_A_FEATURE`は`true`です。
- job2の`DEPLOY_VARIABLE`は`default-deploy`であり、`IS_A_FEATURE`は`true`です。

ブランチがそれ以外の場合:

- job1の`DEPLOY_VARIABLE`は`job1-default-deploy`です。
- job2の`DEPLOY_VARIABLE`は`default-deploy`です。

**補足情報**:

- `workflow:rules:variables`で定義された変数は、すべてのジョブで使用できる[デフォルト変数](#variables)になります。これには、デフォルトで変数をダウンストリームパイプラインに転送する[`trigger`](#trigger)ジョブも含まれます。ダウンストリームパイプラインが同じ変数を使用する場合、アップストリーム変数の値によって[変数が上書きされます](../variables/_index.md#cicd-variable-precedence)。そのため、次のいずれかを必ず実施してください。
  - 各プロジェクトのパイプライン設定で一意の変数名を使用する（例: `PROJECT1_VARIABLE_NAME`）。
  - トリガージョブで[`inherit:variables`](#inheritvariables)を使用し、ダウンストリームパイプラインに転送する正確な変数をリストする。

#### `workflow:rules:auto_cancel` {#workflowrulesauto_cancel}

{{< history >}}

- GitLab 16.8で`ci_workflow_auto_cancel_on_new_commit`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/436467)されました。デフォルトでは無効になっています。
- GitLab 16.9の[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/434676)になりました。
- GitLab 16.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/434676)になりました。機能フラグ`ci_workflow_auto_cancel_on_new_commit`は削除されました。
- `workflow:rules`の`on_job_failure`オプションは、GitLab 16.10で`auto_cancel_pipeline_on_job_failure`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/23605)されました。デフォルトでは無効になっています。
- `workflow:rules`の`on_job_failure`オプションは、GitLab 16.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/433163)になりました。機能フラグ`auto_cancel_pipeline_on_job_failure`は削除されました。

{{< /history >}}

`workflow:rules:auto_cancel`を使用して、[`workflow:auto_cancel:on_new_commit`](#workflowauto_cancelon_new_commit)機能または[`workflow:auto_cancel:on_job_failure`](#workflowauto_cancelon_job_failure)機能の動作を設定します。

**サポートされている値**: 

- `on_new_commit`: [`workflow:auto_cancel:on_new_commit`](#workflowauto_cancelon_new_commit)
- `on_job_failure`: [`workflow:auto_cancel:on_job_failure`](#workflowauto_cancelon_job_failure)

**`workflow:rules:auto_cancel`の例**:

```yaml
workflow:
  auto_cancel:
    on_new_commit: interruptible
    on_job_failure: all
  rules:
    - if: $CI_COMMIT_REF_PROTECTED == 'true'
      auto_cancel:
        on_new_commit: none
        on_job_failure: none
    - when: always                  # Run the pipeline in other cases

test-job1:
  script: sleep 10
  interruptible: false

test-job2:
  script: sleep 10
  interruptible: true
```

この例では、デフォルトですべてのジョブの[`workflow:auto_cancel:on_new_commit`](#workflowauto_cancelon_new_commit)が`interruptible`に設定され、[`workflow:auto_cancel:on_job_failure`](#workflowauto_cancelon_job_failure)が`all`に設定されます。ただし、保護ブランチに対してパイプラインが実行される場合、ルールはデフォルトを`on_new_commit: none`と`on_job_failure: none`でオーバーライドします。たとえば、パイプラインの実行対象によって、動作は次のように変わります。

- 保護されていないブランチに対して実行される場合、新しいコミットがプッシュされると、`test-job1`の実行が継続され、`test-job2`はキャンセルされます。
- 保護ブランチに対して実行される場合、新しいコミットがプッシュされると、`test-job1`と`test-job2`の両方の実行が継続されます。

## ヘッダーキーワード {#header-keywords}

いくつかのキーワードは、YAML設定ファイルのヘッダーセクションで定義する必要があります。ヘッダーはファイルの先頭に配置し、設定の他の部分と`---`で区切る必要があります。

### `spec` {#spec}

{{< history >}}

- GitLab 15.11でベータ機能として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/391331)されました。

{{< /history >}}

YAMLファイルのヘッダーに`spec`セクションを追加すると、`include`キーワードを使用して設定がパイプラインに追加されたときのパイプラインの動作を設定できます。

仕様は設定ファイルの先頭にあるヘッダーセクションで宣言する必要があります。このセクションは、設定の他の部分と`---`で区切られています。

#### `spec:inputs` {#specinputs}

`spec:inputs`を使用して、CI/CD設定に対する[インプット](inputs.md)を定義できます。

ヘッダーセクションの外部でその値を参照するには、補間形式`$[[ inputs.input-id ]]`を使用します。インプットは、パイプラインの作成時に設定がフェッチされるときに評価および補間されます。`inputs`を使用すると、設定が`.gitlab-ci.yml`ファイルの内容とマージされる前に補間が完了します。

**キーワードのタイプ**: ヘッダーキーワード。`spec`は、設定ファイルの先頭にあるヘッダーセクションで宣言する必要があります。

**サポートされている値**: 予期されるインプットを表す文字列のハッシュ。

**`spec:inputs`の例**:

```yaml
spec:
  inputs:
    environment:
    job-stage:
---

scan-website:
  stage: $[[ inputs.job-stage ]]
  script: ./scan-website $[[ inputs.environment ]]
```

**補足情報**:

- [`spec:inputs:default`](#specinputsdefault)を使用してデフォルト値を設定しない限り、インプットは必須です。[`include:inputs`](#includeinputs)と組み合わせてインプットを使用する場合を除き、インプットを必須にするのは避けることをおすすめします。
- インプットは文字列を想定しています。ただし、[`spec:inputs:type`](#specinputstype)を使用して別の型を指定する場合を除きます。
- 補間ブロックを含む文字列は、1 MB以下にする必要があります。
- 補間ブロック内の文字列は、1 KB以下にする必要があります。
- インプット値は[新しいパイプラインの実行時](../inputs/_index.md#for-a-pipeline)に定義できます。

**関連トピック**:

- [`spec:inputs`でインプットパラメータを定義する](../inputs/_index.md#define-input-parameters-with-specinputs)。

##### `spec:inputs:default` {#specinputsdefault}

{{< history >}}

- GitLab 15.11でベータ機能として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/391331)されました。

{{< /history >}}

`spec:inputs:default`を使用してデフォルト値を設定しない限り、仕様に含まれるインプットはすべて必須になります。

デフォルト値を設定しない場合は`default: ''`を使用します。

**キーワードのタイプ**: ヘッダーキーワード。`spec`は、設定ファイルの先頭にあるヘッダーセクションで宣言する必要があります。

**サポートされている値**: デフォルト値を表す文字列、または`''`。

**`spec:inputs:default`の例**:

```yaml
spec:
  inputs:
    website:
    user:
      default: 'test-user'
    flags:
      default: ''
title: The pipeline configuration would follow...
---
```

この例では:

- `website`は必須であり、定義する必要があります。
- `user`はオプションです。定義されていない場合、値は`test-user`になります。
- `flags`はオプションです。定義されていない場合、値はありません。

**補足情報**:

- インプットが次の条件に該当する場合、パイプラインは検証エラーで失敗します。
  - `default`と[`options`](#specinputsoptions)の両方を使用しているが、デフォルト値が、リストされているオプションのいずれでもない。
  - `default`と`regex`の両方を使用しているが、デフォルト値が正規表現と一致しない。
  - 値が[`type`](#specinputstype)と一致しない。

##### `spec:inputs:description` {#specinputsdescription}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/415637)されました。

{{< /history >}}

`description`を使用して、特定のインプットに説明を付けます。説明はインプットの動作に影響を与えません。ファイルのユーザーがインプットを理解できるようにする目的でのみ使用されます。

**キーワードのタイプ**: ヘッダーキーワード。`spec`は、設定ファイルの先頭にあるヘッダーセクションで宣言する必要があります。

**サポートされている値**: 説明を表す文字列。

**`spec:inputs:description`の例**:

```yaml
spec:
  inputs:
    flags:
      description: 'Sample description of the `flags` input details.'
title: The pipeline configuration would follow...
---
```

##### `spec:inputs:options` {#specinputsoptions}

{{< history >}}

- GitLab 16.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/393401)されました。

{{< /history >}}

インプットで`options`を使用して、インプットに許可される値のリストを指定できます。各インプットに指定できるオプションの数は、最大50個までです。

**キーワードのタイプ**: ヘッダーキーワード。`spec`は、設定ファイルの先頭にあるヘッダーセクションで宣言する必要があります。

**サポートされている値**: インプットオプションの配列。

**`spec:inputs:options`の例**:

```yaml
spec:
  inputs:
    environment:
      options:
        - development
        - staging
        - production
title: The pipeline configuration would follow...
---
```

この例では:

- `environment`は必須であり、リスト内のいずれかの値で定義する必要があります。

**補足情報**:

- 次の場合、パイプラインは検証エラーで失敗します。
  - インプットで`options`と[`default`](#specinputsdefault)の両方を使用しているが、デフォルト値が、リストされているオプションのいずれでもない。
  - いずれかのインプットオプションが[`type`](#specinputstype)と一致していない。`options`を使用する場合は`string`または`number`を指定する必要があり、`boolean`は使用できない。

##### `spec:inputs:regex` {#specinputsregex}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/410836)されました。

{{< /history >}}

`spec:inputs:regex`を使用して、インプットが一致する必要がある正規表現を指定します。

**キーワードのタイプ**: ヘッダーキーワード。`spec`は、設定ファイルの先頭にあるヘッダーセクションで宣言する必要があります。

**サポートされている値**: 正規表現である必要があります。

**`spec:inputs:regex`の例**:

```yaml
spec:
  inputs:
    version:
      regex: ^v\d\.\d+(\.\d+)?$
title: The pipeline configuration would follow...
---
```

この例では、`v1.0`または`v1.2.3`のインプットは正規表現に一致し、検証に合格します。`v1.A.B`のインプットは正規表現と一致せず、検証に失敗します。

**補足情報**:

- `inputs:regex`は、[`type`](#specinputstype)が`string`の場合にのみ使用できます。`number`または`boolean`の場合は使用できません。
- `/`文字で正規表現を囲まないでください。たとえば、`/regex.*/`ではなく`regex.*`を使用します。
- `inputs:regex`は[RE2](https://github.com/google/re2/wiki/Syntax)を使用して正規表現を解析します。

##### `spec:inputs:type` {#specinputstype}

デフォルトでは、インプットは文字列を想定しています。`spec:inputs:type`を使用すると、インプットに必要な別の型を指定できます。

**キーワードのタイプ**: ヘッダーキーワード。`spec`は、設定ファイルの先頭にあるヘッダーセクションで宣言する必要があります。

**サポートされている値**: 次のいずれかです。

- `array`: インプットの[配列](../inputs/_index.md#array-type)を受け入れます。
- `string`: 文字列のインプットを受け入れます（定義されていない場合のデフォルト）。
- `number`: 数値のインプットのみを受け入れます。
- `boolean`: `true`または`false`のインプットのみを受け入れます。

**`spec:inputs:type`の例**:

```yaml
spec:
  inputs:
    job_name:
    website:
      type: string
    port:
      type: number
    available:
      type: boolean
    array_input:
      type: array
title: The pipeline configuration would follow...
---
```

## ジョブキーワード {#job-keywords}

以降のトピックでは、キーワードを使用してCI/CDパイプラインを設定する方法について説明します。

### `after_script` {#after_script}

{{< history >}}

- キャンセルされたジョブに対する`after_script`コマンドの実行は、GitLab 17.0で[導入](https://gitlab.com/groups/gitlab-org/-/epics/10158)されました。

{{< /history >}}

`after_script`を使用して、ジョブの`before_script`セクションと`script`セクションの完了後に最後に実行するコマンドの配列を定義します。`after_script`のコマンドは、次の条件に該当する場合にも実行されます。

- `before_script`セクションまたは`script`セクションの実行中に、ジョブがキャンセルされた場合。
- ジョブで`script_failure`という種類の失敗が発生した場合（ただし、[それ以外の種類の失敗](#retrywhen)では実行されません）。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**サポートされている値**: 次の内容を含む配列。

- 1行のコマンド。
- [複数行に分割された](script.md#split-long-commands)長いコマンド。
- [YAMLアンカー](yaml_optimization.md#yaml-anchors-for-scripts)。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**`after_script`の例**:

```yaml
job:
  script:
    - echo "An example script section."
  after_script:
    - echo "Execute this command after the `script` section completes."
```

**補足情報**:

`after_script`で指定するスクリプトは、`before_script`コマンドまたは`script`コマンドとは別のShellで実行されます。その結果、スクリプトは次のようになります。

- 現在のワーキングディレクトリがデフォルトにリセットされます（デフォルト値は、[RunnerがGitリクエストをどのように処理するかを定義する変数](../runners/configure_runners.md#configure-runner-behavior-with-variables)に基づいて決まります）。
- `before_script`または`script`で定義されたコマンドによる変更にはアクセスできません。これには以下が含まれます。
  - `script`スクリプトでエクスポートされたコマンドエイリアスと変数。
  - ワークツリー外の変更（Runnerのexecutorによってアクセス可否が異なります）。たとえば、`before_script`または`script`スクリプトによってインストールされたソフトウェアなどが該当します。
- 個別のタイムアウトが設定されます。GitLab Runner 16.4以降では、デフォルトは5分で、[`RUNNER_AFTER_SCRIPT_TIMEOUT`](../runners/configure_runners.md#set-script-and-after_script-timeouts)変数で設定できます。GitLab 16.3以前では、タイムアウトは5分にハードコードされています。
- ジョブの終了コードには影響しません。`script`セクションが成功し、`after_script`がタイムアウトになるか失敗した場合、ジョブはコード`0`（`Job Succeeded`）で終了します。
- `after_script`で[CI/CDジョブトークン](../jobs/ci_job_token.md)を使用する場合の既知の問題があります。`after_script`コマンドでの認証にジョブトークンを使用することはできますが、ジョブがキャンセルされるとそのトークンは直ちに無効になります。詳細については、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/473376)を参照してください。

ジョブがタイムアウトした場合:

- `after_script`コマンドはデフォルトでは実行されません。
- [タイムアウト値を設定](../runners/configure_runners.md#ensuring-after_script-execution)することで、`after_script`を確実に実行させることができます。そのためには、ジョブのタイムアウトを超えないように、`RUNNER_SCRIPT_TIMEOUT`と`RUNNER_AFTER_SCRIPT_TIMEOUT`に適切な値を設定します。

**関連トピック**:

- [`after_script`を`default`と組み合わせて使用する](script.md#set-a-default-before_script-or-after_script-for-all-jobs)と、すべてのジョブの後に実行されるコマンドのデフォルト配列を定義できます。
- ジョブがキャンセルされた場合に[`after_script`コマンドをスキップ](script.md#skip-after_script-commands-if-a-job-is-canceled)するようにジョブを設定できます。
- [ゼロ以外の終了コードを無視](script.md#ignore-non-zero-exit-codes)できます。
- [`after_script`でカラーコードを使用する](script.md#add-color-codes-to-script-output)と、ジョブログのレビューが容易になります。
- [カスタムの折りたたみ可能なセクションを作成](../jobs/job_logs.md#custom-collapsible-sections)して、ジョブログ出力をシンプルにできます。
- [`after_script`のエラーを無視](../runners/configure_runners.md#ignore-errors-in-after_script)できます。

### `allow_failure` {#allow_failure}

`allow_failure`を使用して、ジョブが失敗した場合にパイプラインの実行を継続するかどうかを決定します。

- パイプラインで後続のジョブを継続して実行させるには、`allow_failure: true`を使用します。
- パイプラインで後続のジョブの実行を停止させるには、`allow_failure: false`を使用します。

ジョブの失敗が許容されている場合（`allow_failure: true`）、オレンジ色の警告（{{< icon name="status_warning" >}}）はジョブが失敗したことを示します。ただしパイプラインは成功し、関連するコミットは警告なしで成功としてマークされます。

このような警告は、次の場合に表示されます。

- ステージ内の他のすべてのジョブが成功した場合。
- パイプライン内の他のすべてのジョブが成功した場合。

`allow_failure`のデフォルト値は次のとおりです。

- [手動ジョブ](../jobs/job_control.md#create-a-job-that-must-be-run-manually): `true`。
- [`rules`](#rules)内で`when: manual`を使用しているジョブ: `false`。
- その他すべてのケース: `false`。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `true`または`false`。

**`allow_failure`の例**:

```yaml
job1:
  stage: test
  script:
    - execute_script_1

job2:
  stage: test
  script:
    - execute_script_2
  allow_failure: true

job3:
  stage: deploy
  script:
    - deploy_to_staging
  environment: staging
```

この例では、`job1`と`job2`は並列実行されます。

- `job1`が失敗した場合、`deploy`ステージのジョブは開始されません。
- `job2`が失敗した場合、`deploy`ステージのジョブは開始できます。

**補足情報**:

- `allow_failure`を[`rules`](#rulesallow_failure)のサブキーとして使用できます。
- `allow_failure: true`が設定されている場合、そのジョブは常に成功と見なされます。そのため、そのジョブが失敗しても、[`when: on_failure`](#when)が設定された後続のジョブは開始されません。
- 手動ジョブに`allow_failure: false`を設定することで、[ブロック手動ジョブ](../jobs/job_control.md#types-of-manual-jobs)を作成できます。ブロックされたパイプラインは、その手動ジョブが開始されて正常に完了するまで、後続ステージのジョブを実行しません。

#### `allow_failure:exit_codes` {#allow_failureexit_codes}

`allow_failure:exit_codes`を使用して、ジョブの失敗を許容する条件を制御します。ジョブは、リストされた終了コードのいずれかの場合は`allow_failure: true`、それ以外の終了コードに対しては`allow_failure`がfalseとなります。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- 1つの終了コード。
- 終了コードの配列。

**`allow_failure`の例**:

```yaml
test_job_1:
  script:
    - echo "Run a script that results in exit code 1. This job fails."
    - exit 1
  allow_failure:
    exit_codes: 137

test_job_2:
  script:
    - echo "Run a script that results in exit code 137. This job is allowed to fail."
    - exit 137
  allow_failure:
    exit_codes:
      - 137
      - 255
```

### `artifacts`

`artifacts`を使用して、[ジョブアーティファクト](../jobs/job_artifacts.md)として保存するファイルを指定します。ジョブアーティファクトは、ジョブが[成功または失敗する場合、または常に](#artifactswhen)ジョブに添付されるファイルとディレクトリのリストです。

アーティファクトは、ジョブの完了後にGitLabに送信されます。サイズが[最大アーティファクトサイズ](../../user/gitlab_com/_index.md#cicd)よりも小さい場合、GitLab UIでダウンロードできます。

デフォルトでは、後のステージのジョブは、前のステージのジョブによって作成されたすべてのアーティファクトを自動的にダウンロードします。[`dependencies`](#dependencies)を使用して、ジョブのアーティファクトのダウンロード動作を制御できます。

[`needs`](#needs)キーワードを使用すると、ジョブは`needs`設定で定義されているジョブからのみアーティファクトをダウンロードできるようになります。

デフォルトでは、成功したジョブのジョブアーティファクトのみが収集されます。アーティファクトは[キャッシュ](#cache)の後に復元されます。

[アーティファクトの詳細についてはこちらを参照してください](../jobs/job_artifacts.md)。

#### `artifacts:paths`

パスはプロジェクトディレクトリ（`$CI_PROJECT_DIR`）を基準にした相対パスであり、その外部に直接リンクすることはできません。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- ファイルパスの配列。ファイルパスはプロジェクトディレクトリを基準にした相対パスです。
- [glob](https://en.wikipedia.org/wiki/Glob_(programming))パターンを使用するワイルドカードと次の値を使用できます。
  - [GitLab Runner 13.0以降](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2620): [`doublestar.Glob`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#Match)。
  - GitLab Runner 12.10以前: [`filepath.Match`](https://pkg.go.dev/path/filepath#Match)。
- [GitLab Pagesジョブ](#pages)の場合
  - [GitLab 17.10以降](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)では、[`pages.publish`](#pagespublish)パスは自動的に`artifacts:paths`に付加されるため、再度指定する必要はありません。
  - [GitLab 17.10以降](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)では、[`pages.publish`](#pagespublish)パスが指定されていない場合、`public`ディレクトリが自動的に`artifacts:paths`に付加されます。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**`artifacts:paths`の例**

```yaml
job:
  artifacts:
    paths:
      - binaries/
      - .config
```

この例では、`.config`と、`binaries`ディレクトリ内にあるすべてのファイルを使用して、アーティファクトを作成します。

**追加の詳細情報**

- [`artifacts:name`](#artifactsname)と組み合わせて使用しない場合、アーティファクトファイルの名前は`artifacts`になり、ダウンロード時に`artifacts.zip`になります。

**関連トピック**

- 特定のジョブによるアーティファクトのフェッチ元のジョブを制限するには、[`dependencies`](#dependencies)を参照してください。
- [ジョブアーティファクトを作成します](../jobs/job_artifacts.md#create-job-artifacts)。

#### `artifacts:exclude`

`artifacts:exclude`を使用して、ファイルがアーティファクトアーカイブに追加されないようにします。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- ファイルパスの配列。ファイルパスはプロジェクトディレクトリを基準にした相対パスです。
- [glob](https://en.wikipedia.org/wiki/Glob_(programming))パターンまたは[`doublestar.PathMatch`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#PathMatch)パターンを使用するワイルドカードを使用できます。

**`artifacts:exclude`の例**

```yaml
artifacts:
  paths:
    - binaries/
  exclude:
    - binaries/**/*.o
```

この例では、`binaries/`内のすべてのファイルが保存されますが、`binaries/`のサブディレクトリにある`*.o`ファイルは保存されません。

**追加の詳細情報**

- `artifacts:exclude`パスは再帰的に検索されません。
- [`artifacts:untracked`](#artifactsuntracked)で一致したファイルも`artifacts:exclude`を使用して除外できます。

**関連トピック**

- [ジョブアーティファクトからファイルを除外する](../jobs/job_artifacts.md#without-excluded-files)。

#### `artifacts:expire_in`

`expire_in`を使用して、[ジョブアーティファクト](../jobs/job_artifacts.md)が期限切れになり削除されるまでに保存される期間を指定します。`expire_in`設定は、以下には影響しません。

- 最新ジョブのアーティファクト（[プロジェクトレベル](../jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs)または[インスタンス全体](../../administration/settings/continuous_integration.md#keep-the-latest-artifacts-for-all-jobs-in-the-latest-successful-pipelines)で最新ジョブアーティファクトの保持が無効になっている場合を除く）。

期限が切れたアーティファクトは、デフォルトでは毎時間（cronジョブを使用して）削除され、アクセスできなくなります。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 有効期間。単位が指定されていない場合、時間は秒単位です。有効な値は次のとおりです。

- `'42'`
- `42 seconds`
- `3 mins 4 sec`
- `2 hrs 20 min`
- `2h20min`
- `6 mos 1 day`
- `47 yrs 6 mos and 4d`
- `3 weeks and 2 days`
- `never`

**`artifacts:expire_in`の例**

```yaml
job:
  artifacts:
    expire_in: 1 week
```

**追加の詳細情報**

- 有効期間は、アーティファクトがGitLabにアップロードされて保存された時点で開始します。有効期間が定義されていない場合は、[インスタンス全体の設定](../../administration/settings/continuous_integration.md#default-artifacts-expiration)がデフォルトで使用されます。
- 有効期間をオーバーライドし、アーティファクトが自動的に削除されないように保護するには、次のようにします。
  - ジョブページで**保持**を選択します。
  - `expire_in`の値を`never`に設定します。
- 有効期間が短すぎると、長いパイプラインの後半のステージにあるジョブが、前半のジョブから期限切れのアーティファクトをフェッチしようとする可能性があります。アーティファクトが期限切れになると、それらのアーティファクトをフェッチしようとするジョブは[`could not retrieve the needed artifacts`エラー](../jobs/job_artifacts_troubleshooting.md#error-message-this-job-could-not-start-because-it-could-not-retrieve-the-needed-artifacts)で失敗します。有効期間を長く設定するか、後のジョブで[`dependencies`](#dependencies)を使用して、期限切れのアーティファクトをフェッチしないようにします。
- `artifacts:expire_in`は、GitLab Pagesのデプロイには影響しません。Pagesのデプロイの有効期間を設定するには、[`pages.expire_in`](#pagesexpire_in)を使用します。

#### `artifacts:expose_as`

`artifacts:expose_as`キーワードを使用して、[マージリクエストUIでジョブアーティファクトを公開](../jobs/job_artifacts.md#link-to-job-artifacts-in-the-merge-request-ui)します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- マージリクエストUIに表示するアーティファクトのダウンロードリンクの名前。[`artifacts:paths`](#artifactspaths)と組み合わせて使用する必要があります。

**`artifacts:expose_as`の例**

```yaml
test:
  script: ["echo 'test' > file.txt"]
  artifacts:
    expose_as: 'artifact 1'
    paths: ['file.txt']
```

**追加の詳細情報**

- `artifacts:paths`の値が次の条件に該当する場合、アーティファクトは保存されますが、UIには表示されません。
  - [CI/CD変数](../variables/_index.md)を使用する。
  - ディレクトリを定義するが、`/`で終わらない。たとえば、`artifacts:expose_as`で`directory/`は機能するが、`directory`は機能しない。
  - `./`で始まる。たとえば、`artifacts:expose_as`で`file`は機能するが、`./file`は機能しない。
- マージリクエストごとに最大10個のジョブアーティファクトを公開できます。
- Globパターンはサポートされていません。
- ディレクトリが指定されており、ディレクトリに複数のファイルがある場合、リンクはジョブ[アーティファクトブラウザ](../jobs/job_artifacts.md#download-job-artifacts)へのリンクです。
- [GitLab Pages](../../administration/pages/_index.md)が有効になっており、アーティファクトが次のいずれかの拡張子を持つ単一ファイルである場合、GitLabはアーティファクトを自動的にレンダリングします。
  - `.html`または`.htm`
  - `.txt`
  - `.json`
  - `.xml`
  - `.log`

**関連トピック**

- [マージリクエストUIでジョブアーティファクトを公開する](../jobs/job_artifacts.md#link-to-job-artifacts-in-the-merge-request-ui)。

#### `artifacts:name`

`artifacts:name`キーワードを使用して、作成されたアーティファクトアーカイブの名前を定義します。すべてのアーカイブに一意の名前を指定できます。

定義されていない場合、デフォルトの名前は`artifacts`であり、ダウンロード時に`artifacts.zip`になります。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- アーティファクトアーカイブの名前。CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。[`artifacts:paths`](#artifactspaths)と組み合わせて使用する必要があります。

**`artifacts:name`の例**

現在のジョブの名前でアーカイブを作成するには

```yaml
job:
  artifacts:
    name: "job1-artifacts-file"
    paths:
      - binaries/
```

**関連トピック**

- [CI/CD変数を使用してアーティファクト設定を定義する](../jobs/job_artifacts.md#with-variable-expansion)

#### `artifacts:public`

{{< history >}}

- GitLab 15.10で[更新されました](https://gitlab.com/gitlab-org/gitlab/-/issues/322454)。15.10よりも前に`artifacts:public`を使用して作成されたアーティファクトは、この更新の後にもプライベートであることは保証されません。
- GitLab 16.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/294503)になりました。機能フラグ`non_public_artifacts`が削除されました。

{{< /history >}}

{{< alert type="note" >}}

`artifacts:public`は、より多くのオプションがある[`artifacts:access`](#artifactsaccess)に置き換えられました。

{{< /alert >}}

`artifacts:public`を使用して、ジョブアーティファクトを公開するかどうかを決定します。

`artifacts:public`が`true`（デフォルト）の場合、パブリックパイプラインのアーティファクトをダウンロードできるのは、匿名ユーザー、ゲストユーザー、およびレポーターユーザーです。

匿名ユーザー、ゲストユーザー、およびレポーターユーザーに対してパブリックパイプラインでのアーティファクトへの読み取りアクセスを拒否するには、`artifacts:public`を`false`に設定します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- `true`（定義されていない場合はデフォルト）または`false`。

**`artifacts:public`の例**

```yaml
job:
  artifacts:
    public: false
```

#### `artifacts:access`

{{< history >}}

- GitLab 16.11で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145206)。

{{< /history >}}

`artifacts:access`を使用して、GitLab UIまたはAPIからジョブアーティファクトにアクセスできるユーザーを決定します。このオプションを使用しても、アーティファクトをダウンストリームパイプラインに転送できなくなることはありません。

同じジョブで[`artifacts:public`](#artifactspublic)と`artifacts:access`を使用することはできません。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `all`（デフォルト）: パブリックパイプラインのジョブのアーティファクトは、匿名ユーザー、ゲストユーザー、レポーターユーザーなど誰でもダウンロードできます。
- `developer`: ジョブのアーティファクトをダウンロードできるのは、デベロッパーロール以上のロールを持つユーザーのみです。
- `none`: 誰もジョブのアーティファクトをダウンロードできません。

**`artifacts:access`の例**

```yaml
job:
  artifacts:
    access: 'developer'
```

**追加の詳細情報**

- `artifacts:access`はすべての[`artifacts:reports`](#artifactsreports)にも影響するため、[レポートのアーティファクト](artifacts_reports.md)へのアクセスを制限することもできます。

#### `artifacts:reports`

[`artifacts:reports`](artifacts_reports.md)を使用して、ジョブにインクルードされたテンプレートによって生成されたアーティファクトを収集します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- 利用可能な[アーティファクトレポートのタイプ](artifacts_reports.md)のリストを参照してください。

**`artifacts:reports`の例**

```yaml
rspec:
  stage: test
  script:
    - bundle install
    - rspec --format RspecJunitFormatter --out rspec.xml
  artifacts:
    reports:
      junit: rspec.xml
```

**追加の詳細情報**

- [子パイプラインからのアーティファクト](#needspipelinejob)を使用して、親パイプラインでレポートを組み合わせる操作はサポートされていません。[このイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/215725)で、サポートの追加に関する進捗状況を追跡してください。
- レポート出力ファイルを参照してダウンロードできるようにするには、[`artifacts:paths`](#artifactspaths)キーワードを含めます。これにより、アーティファクトのアップロードと保存が2回実行されます。
- `artifacts: reports`で作成されたアーティファクトは、ジョブの結果（成功または失敗）に関係なく常にアップロードされます。[`artifacts:expire_in`](#artifactsexpire_in)を使用して、アーティファクトの有効期限を設定できます。

#### `artifacts:untracked`

`artifacts:untracked`を使用して、（`artifacts:paths`で定義されたパスとともに）すべての追跡していないGitファイルをアーティファクトとして追加します。`artifacts:untracked`はリポジトリの`.gitignore`の設定を無視するため、`.gitignore`内の一致するアーティファクトがインクルードされます。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- `true`または`false`（定義されていない場合はデフォルト）。

**`artifacts:untracked`の例**

追跡していないGitファイルをすべて保存します。

```yaml
job:
  artifacts:
    untracked: true
```

**関連トピック**

- [追跡していないファイルをアーティファクトに追加する](../jobs/job_artifacts.md#with-untracked-files)。

#### `artifacts:when`

`artifacts:when`を使用して、ジョブの失敗時または失敗にかかわらずアーティファクトをアップロードします。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- `on_success`（デフォルト）: ジョブが成功した場合にのみアーティファクトをアップロードします。
- `on_failure`: ジョブが失敗した場合にのみアーティファクトをアップロードします。
- `always`: 常にアーティファクトをアップロードします（ジョブがタイムアウトになった場合を除く）。たとえば、失敗したテストの問題解決に必要な[アーティファクトをアップロードする](../testing/unit_test_reports.md#view-junit-screenshots-on-gitlab)場合などです。

**`artifacts:when`の例**

```yaml
job:
  artifacts:
    when: on_failure
```

**追加の詳細情報**

- [`artifacts:reports`](#artifactsreports)で作成されたアーティファクトは、ジョブの結果（成功または失敗）に関係なく常にアップロードされます。`artifacts:when`はこの動作を変更しません。

### `before_script`

`before_script`を使用して、[アーティファクト](#artifacts)が復元された後、各ジョブの`script`コマンドの前に実行するコマンドの配列を定義します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 次の内容を含む配列。

- 単一行コマンド。
- [複数行に分割された](script.md#split-long-commands)長いコマンド。
- [YAMLアンカー](yaml_optimization.md#yaml-anchors-for-scripts)。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**`before_script`の例**

```yaml
job:
  before_script:
    - echo "Execute this command before any 'script:' commands."
  script:
    - echo "This command executes after the job's 'before_script' commands."
```

**追加の詳細情報**

- `before_script`で指定したスクリプトが、メインの[`script`](#script)で指定したスクリプトと連結されます。連結されたスクリプトは、1つのShellでまとめて実行されます。
- `before_script`を`default`セクションではなく、トップレベルで使用することは[非推奨です](#globally-defined-image-services-cache-before_script-after_script)。

**関連トピック**

- すべてのジョブで`script`コマンドの前に実行されるデフォルトのコマンドの配列を定義するには、[`before_script`と`default`を組み合わせて使用します](script.md#set-a-default-before_script-or-after_script-for-all-jobs)。
- [ゼロ以外の終了コードを無視](script.md#ignore-non-zero-exit-codes)できます。
- [`before_script`でカラーコードを使用する](script.md#add-color-codes-to-script-output)と、ジョブログのレビューが容易になります。
- [カスタムの折りたたみ可能なセクションを作成](../jobs/job_logs.md#custom-collapsible-sections)して、ジョブログ出力をシンプルにできます。

### `cache`

{{< history >}}

- GitLab 15.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/330047)。キャッシュは、保護ブランチと未保護のブランチ間で共有されません。

{{< /history >}}

`cache`を使用して、ジョブ間でキャッシュするファイルとディレクトリのリストを指定します。ローカルの実行コピーにあるパスのみを使用できます。

キャッシュは次のようになります。

- パイプラインとジョブ間で共有されます。
- デフォルトでは、[保護](../../user/project/repository/branches/protected.md)ブランチと保護されていないブランチの間で共有されません。
- [アーティファクト](#artifacts)の前に復元されます。
- 最大4つの[キャッシュ](../caching/_index.md#use-multiple-caches)に制限されています。

たとえば、オーバーライドする[特定のジョブのキャッシュを無効にできます](../caching/_index.md#disable-cache-for-specific-jobs)。

- [`default`](#default)で定義されたデフォルトのキャッシュ。
- [`include`](#include)で追加されたジョブの設定。

キャッシュの詳細については、[GitLab CI/CDでのキャッシュ](../caching/_index.md)を参照してください。

#### `cache:paths`

`cache:paths`キーワードを使用して、キャッシュするファイルまたはディレクトリを選択します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- プロジェクトディレクトリ（`$CI_PROJECT_DIR`）を基準にしたパスの配列。[glob](https://en.wikipedia.org/wiki/Glob_(programming))パターンを使用するワイルドカードを使用できます。
  - [GitLab Runner 13.0以降](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2620): [`doublestar.Glob`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#Match)。
  - GitLab Runner 12.10以前: [`filepath.Match`](https://pkg.go.dev/path/filepath#Match)。

[CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)がサポートされています。

**`cache:paths`の例**

`binaries`にある`.apk`で終わるすべてのファイルと、`.config`ファイルをキャッシュします。

```yaml
rspec:
  script:
    - echo "This job uses a cache."
  cache:
    key: binaries-cache
    paths:
      - binaries/*.apk
      - .config
```

**追加の詳細情報**

- `cache:paths`キーワードでは、追跡していないファイルや`.gitignore`ファイル内のファイルもインクルードされます。

**関連トピック**

- その他の`cache:paths`の例については、[`cache`の一般的なユースケース](../caching/_index.md#common-use-cases-for-caches)を参照してください。

#### `cache:key`

`cache:key`キーワードを使用して、各キャッシュに一意の識別キーを指定します。同じキャッシュキーを使用するすべてのジョブは、異なるパイプラインでも同じキャッシュを使用します。

設定されていない場合のデフォルトのキーは`default`です。`cache`キーワードが指定されているが`cache:key`が指定されていないすべてのジョブは、`default`キャッシュを共有します。

`cache: paths`と組み合わせて使用する必要があります。このように使用しない場合、何もキャッシュされません。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- 文字列。
- 定義済み[CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。
- 両方の組み合わせ。

**`cache:key`の例**

```yaml
cache-job:
  script:
    - echo "This job uses a cache."
  cache:
    key: binaries-cache-$CI_COMMIT_REF_SLUG
    paths:
      - binaries/
```

**追加の詳細情報**

- **Windowsバッチ**を使用してShellスクリプトを実行する場合は、`$`を`%`に置き換える必要があります。例: `key: %CI_COMMIT_REF_SLUG%`
- `cache:key`の値には次のものを含めることはできません。

  - `/`文字、または同等のURIエンコードされた`%2F`。
  - `.`文字（任意の数）のみ、または同等のURIエンコードされた`%2E`。

- キャッシュはジョブ間で共有されるため、ジョブごとに異なるパスを使用している場合は、別の`cache:key`も設定する必要があります。このようにしないと、キャッシュの内容が上書きされる可能性があります。

**関連トピック**

- 指定された`cache:key`が見つからない場合に使用する[フォールバックキャッシュキー](../caching/_index.md#use-a-fallback-cache-key)を指定できます。
- 1つのジョブで[複数のキャッシュキーを使用](../caching/_index.md#use-multiple-caches)できます。
- その他の`cache:key`の例については、[`cache`の一般的なユースケース](../caching/_index.md#common-use-cases-for-caches)を参照してください。

##### `cache:key:files`

`cache:key:files`キーワードを使用して、1つまたは2つの特定のファイルが変更されたときに新しいキーを生成します。`cache:key:files`を指定すると、一部のキャッシュを再利用でき、キャッシュが再構築される頻度を減らすことができます。これにより、後続のパイプライン実行が高速になります。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- 1つまたは2つのファイルパスの配列。

CI/CD変数はサポートされていません。

**`cache:key:files`の例**

```yaml
cache-job:
  script:
    - echo "This job uses a cache."
  cache:
    key:
      files:
        - Gemfile.lock
        - package.json
    paths:
      - vendor/ruby
      - node_modules
```

この例では、RubyとNode.jsの依存関係のキャッシュを作成します。キャッシュは、`Gemfile.lock`ファイルと`package.json`ファイルの現行バージョンに関連付けられています。これらのファイルのいずれかが変更されると、新しいキャッシュキーが計算され、新しいキャッシュが作成されます。`cache:key:files`で同じ`Gemfile.lock`と`package.json`を使用する後続のジョブの実行では、依存関係を再構築する代わりに、新しいキャッシュが使用されます。

**追加の詳細情報**

- キャッシュ`key`は、リストされた各ファイルを変更した最新のコミットから計算されたSHAです。コミットでどちらのファイルも変更されない場合、フォールバックキーは`default`です。

##### `cache:key:prefix`

`cache:key:prefix`を使用して、[`cache:key:files`](#cachekeyfiles)で計算されたSHAとプレフィックスを組み合わせます。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- 文字列。
- 定義済み[CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。
- 両方の組み合わせ。

**`cache:key:prefix`の例**

```yaml
rspec:
  script:
    - echo "This rspec job uses a cache."
  cache:
    key:
      files:
        - Gemfile.lock
      prefix: $CI_JOB_NAME
    paths:
      - vendor/ruby
```

たとえば`$CI_JOB_NAME`という`prefix`を追加すると、キーは`rspec-feef9576d21ee9b6a32e30c5c79d0a0ceb68d1e5`のようになります。ブランチが`Gemfile.lock`を変更すると、そのブランチには`cache:key:files`の新しいSHAチェックサムが設定されます。新しいキャッシュキーが生成され、そのキーに対して新しいキャッシュが作成されます。`Gemfile.lock`が見つからない場合、プレフィックスが`default`に追加されます。これにより、この例のキーは`rspec-default`になります。

**追加の詳細情報**

- `cache:key:files`内のファイルがコミットで変更されない場合、プレフィックスが`default`キーに追加されます。

#### `cache:untracked`

`untracked: true`を使用して、Gitリポジトリで追跡していないすべてのファイルをキャッシュします。追跡していないファイルには、次のファイルが含まれます。

- [`.gitignore`設定](https://git-scm.com/docs/gitignore)が原因で無視されるファイル。
- 作成されたが、[`git add`](https://git-scm.com/docs/git-add)を使用してチェックアウトに追加されていないファイル。

追跡していないファイルをキャッシュすると、ジョブがダウンロードされた場合に、予想外の大きなキャッシュが作成される可能性があります。

- 通常は追跡されない依存関係（gemやノードモジュールなど）。
- 別のジョブからの[アーティファクト](#artifacts)。デフォルトでは、アーティファクトから抽出されたファイルは追跡されません。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- `true`または`false`（デフォルト）。

**`cache:untracked`の例**

```yaml
rspec:
  script: test
  cache:
    untracked: true
```

**追加の詳細情報**

- `cache:untracked`と`cache:paths`を組み合わせて指定すると、追跡していないすべてのファイルと、設定されたパス内のファイルをキャッシュできます。`cache:paths`は、追跡したファイルや作業ディレクトリの外部にあるファイルを含む特定のファイルをキャッシュする場合に使用し、`cache: untracked`は、追跡していないファイルをすべてキャッシュする場合に使用します。次に例を示します。

  ```yaml
  rspec:
    script: test
    cache:
      untracked: true
      paths:
        - binaries/
  ```

  この例では、ジョブはリポジトリ内の追跡していないすべてのファイルと、`binaries/`内のすべてのファイルをキャッシュします。`binaries/`に追跡していないファイルがある場合、それらのファイルはこの両方のキーワードでカバーされます。

#### `cache:unprotect`

{{< history >}}

- GitLab 15.8で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/362114)。

{{< /history >}}

`cache:unprotect`を使用して、キャッシュが[保護](../../user/project/repository/branches/protected.md)ブランチと保護されていないブランチの間で共有されるように設定します。

{{< alert type="warning" >}}

`true`に設定すると、保護ブランチへのアクセス権を持たないユーザーが、保護ブランチで使用されるキャッシュキーを読み書きできます。

{{< /alert >}}

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- `true`または`false`（デフォルト）。

**`cache:unprotect`の例**

```yaml
rspec:
  script: test
  cache:
    unprotect: true
```

#### `cache:when`

`cache:when`を使用して、ジョブの状態に基づいてキャッシュを保存するタイミングを定義します。

`cache: paths`と組み合わせて使用する必要があります。このように使用しない場合、何もキャッシュされません。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- `on_success`（デフォルト）: ジョブが成功した場合にのみキャッシュを保存します。
- `on_failure`: ジョブが失敗した場合にのみキャッシュを保存します。
- `always`: キャッシュを常に保存します。

**`cache:when`の例**

```yaml
rspec:
  script: rspec
  cache:
    paths:
      - rspec/
    when: 'always'
```

この例では、ジョブの成功または失敗に関わらずキャッシュを保存します。

#### `cache:policy`

キャッシュのアップロードとダウンロードの動作を変更するには、`cache:policy`キーワードを使用します。デフォルトでは、ジョブはジョブ開始時にキャッシュをダウンロードし、ジョブ終了時にキャッシュに変更をアップロードします。このキャッシュスタイルは`pull-push`ポリシー（デフォルト）です。

ジョブ開始時にのみキャッシュをダウンロードするようにジョブを設定し、ジョブ終了時に変更をアップロードしないようにするには、`cache:policy:pull`を使用します。

ジョブ終了時にのみキャッシュをアップロードし、ジョブ開始時にキャッシュをダウンロードしないようにジョブを設定するには、`cache:policy:push`を使用します。

同じキャッシュを使用する多数のジョブが並列実行される場合は、`pull`ポリシーを使用します。このポリシーにより、ジョブの実行が高速化され、キャッシュサーバーの負荷が軽減されます。キャッシュをビルドするには、ジョブと`push`ポリシーを使用します。

`cache: paths`と組み合わせて使用する必要があります。このように使用しない場合、何もキャッシュされません。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- `pull`
- `push`
- `pull-push`（デフォルト）
- [CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**`cache:policy`の例**

```yaml
prepare-dependencies-job:
  stage: build
  cache:
    key: gems
    paths:
      - vendor/bundle
    policy: push
  script:
    - echo "This job only downloads dependencies and builds the cache."
    - echo "Downloading dependencies..."

faster-test-job:
  stage: test
  cache:
    key: gems
    paths:
      - vendor/bundle
    policy: pull
  script:
    - echo "This job script uses the cache, but does not update it."
    - echo "Running tests..."
```

**関連トピック**

- [変数を使用して、ジョブのキャッシュポリシーを制御](../caching/_index.md#use-a-variable-to-control-a-jobs-cache-policy)できます。

#### `cache:fallback_keys`

`cache:key`のキャッシュが見つからない場合にキャッシュの復元を試行するキーのリストを指定するには、`cache:fallback_keys`を使用します。キャッシュは、`fallback_keys`セクションで指定された順序で取得されます。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- キャッシュキーの配列

**`cache:fallback_keys`の例**

```yaml
rspec:
  script: rspec
  cache:
    key: gems-$CI_COMMIT_REF_SLUG
    paths:
      - rspec/
    fallback_keys:
      - gems
    when: 'always'
```

### `coverage`

`coverage`とカスタム正規表現を使用して、ジョブの出力からコードカバレッジを抽出する方法を設定します。ジョブ出力の少なくとも1行が正規表現と一致する場合、カバレッジがUIに表示されます。

一致からコードカバレッジ値を抽出するために、GitLabは短い正規表現`\d+(?:\.\d+)?`を使用します。

**サポートされている値**: 

- RE2正規表現。冒頭と末尾の両方が`/`である必要があります。カバレッジ番号と一致する必要があります。周囲のテキストとも一致する可能性があります。このため、正確な数値をキャプチャするために正規表現文字グループを使用する必要はありません。RE2構文を使用することから、すべてのグループは非キャプチャグループである必要があります。

**`coverage`の例**

```yaml
job1:
  script: rspec
  coverage: '/Code coverage: \d+(?:\.\d+)?/'
```

この例では次のようになります。

1. GitLabがジョブログで正規表現との一致をチェックします。`Code coverage: 67.89% of lines covered`のような行が一致します。
1. 次に、GitLabは一致したフラグメントを調べて、`\d+(?:\.\d+)?`との一致を探します。上記の一致行の例ではコードカバレッジ`67.89`が検出されます。

**追加の詳細情報**

- 正規表現の例は[コードカバレッジ](../testing/code_coverage/_index.md#coverage-regex-patterns)に収録されています。
- ジョブ出力に一致する行が複数ある場合は、最後の行が使用されます（逆引き検索の最初の結果）。
- 1行内に複数の一致がある場合は、カバレッジ番号で最後の一致が検索されます。
- 一致フラグメントで複数のカバレッジ番号が見つかった場合は、最初の番号が使用されます。
- 先頭のゼロは削除されます。
- [子パイプライン](../pipelines/downstream_pipelines.md#parent-child-pipelines)からのカバレッジ出力は、記録または表示されません。詳細については、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/280818)を確認してください。

### `dast_configuration`

{{< details >}}

- プラン: Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`dast_configuration`キーワードを使用して、CI/CD設定で使用するサイトプロファイルとスキャナープロファイルを指定します。最初に、両方のプロファイルがプロジェクトで作成されている必要があります。ジョブのステージは`dast`である必要があります。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: `site_profile`と`scanner_profile`（それぞれ1つずつ）。

- ジョブで使用するサイトプロファイルを指定するには、`site_profile`を使用します。
- ジョブで使用するスキャナープロファイルを指定するには、`scanner_profile`を使用します。

**`dast_configuration`の例**

```yaml
stages:
  - build
  - dast

include:
  - template: DAST.gitlab-ci.yml

dast:
  dast_configuration:
    site_profile: "Example Co"
    scanner_profile: "Quick Passive Test"
```

この例では、特定のサイトプロファイルまたはスキャナープロファイルを選択するため、`dast`ジョブが`dast`設定に`include`キーワードを追加してこの設定を拡張します。

**追加の詳細情報**

- サイトプロファイルまたはスキャナープロファイルに含まれる設定は、DASTテンプレートに含まれる設定よりも優先されます。

**関連トピック**

- [サイトプロファイル](../../user/application_security/dast/on-demand_scan.md#site-profile)。
- [スキャナープロファイル](../../user/application_security/dast/on-demand_scan.md#scanner-profile)。

### `dependencies`

`dependencies`キーワードを使用して、[アーティファクト](#artifacts)のフェッチ元のジョブのリストを定義します。指定されたジョブはすべて、これよりも前のステージにある必要があります。アーティファクトをまったくダウンロードしないようにジョブを設定することもできます。

ジョブで`dependencies`が定義されていない場合、これよりも前のステージのすべてのジョブが依存すると見なされ、ジョブはそれらのジョブからすべてのアーティファクトをフェッチします。

同じステージ内のジョブからアーティファクトをフェッチするには、[`needs:artifacts`](#needsartifacts)を使用する必要があります。同じジョブの中で`dependencies`を`needs`と組み合わせて使用しないでください。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- アーティファクトのフェッチ元のジョブの名前。
- 空の配列（`[]`）。アーティファクトをダウンロードしないようにジョブを設定します。

**`dependencies`の例**

```yaml
build osx:
  stage: build
  script: make build:osx
  artifacts:
    paths:
      - binaries/

build linux:
  stage: build
  script: make build:linux
  artifacts:
    paths:
      - binaries/

test osx:
  stage: test
  script: make test:osx
  dependencies:
    - build osx

test linux:
  stage: test
  script: make test:linux
  dependencies:
    - build linux

deploy:
  stage: deploy
  script: make deploy
  environment: production
```

この例では、2つのジョブにアーティファクト`build osx`と`build linux`があります。`test osx`が実行されると、`build osx`からのアーティファクトがダウンロードされ、ビルドのコンテキストで抽出されます。`test linux`と`build linux`からのアーティファクトについても同様の処理が行われます。

`deploy`ジョブは、[ステージ](#stages)の優先順位のために、以前のすべてのジョブからアーティファクトをダウンロードします。

**追加の詳細情報**

- ジョブの状態は関係ありません。ジョブが失敗した場合、またはトリガーされないマニュアルジョブの場合、エラーは発生しません。
- 依存ジョブのアーティファクトが[期限切れ](#artifactsexpire_in)であるかまたは[削除](../jobs/job_artifacts.md#delete-job-log-and-artifacts)されている場合、ジョブは失敗します。

### `environment`

`environment`を使用して、ジョブがデプロイされる[環境](../environments/_index.md)を定義します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: ジョブのデプロイ先の環境の名前を、次のいずれかの形式で指定します。

- プレーンテキスト（文字、数字、スペース、および文字`-`、`_`、`/`、`$`、`{`、`}`を含む）。
- CI/CD変数（定義済み、プロジェクト、グループ、インスタンス、または`.gitlab-ci.yml`ファイルで定義された変数を含む）。`script`セクションで定義された変数は使用できません。

**`environment`の例**

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment: production
```

**追加の詳細情報**

- `environment`を指定しても、その名前の環境が存在しない場合は、環境が作成されます。

#### `environment:name`

[環境](../environments/_index.md)の名前を設定します。

一般的な環境名は`qa`、`staging`、`production`ですが、任意の名前を使用できます。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: ジョブのデプロイ先の環境の名前を、次のいずれかの形式で指定します。

- プレーンテキスト（文字、数字、スペース、および文字`-`、`_`、`/`、`$`、`{`、`}`を含む）。
- [CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)（定義済み、プロジェクト、グループ、インスタンス、または`.gitlab-ci.yml`ファイルで定義された変数を含む）。`script`セクションで定義された変数は使用できません。

**`environment:name`の例**

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment:
    name: production
```

#### `environment:url`

[環境](../environments/_index.md)のURLを設定します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 次のいずれかの形式の単一URL。

- プレーンテキスト（例: `https://prod.example.com`）。
- [CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)（定義済み、プロジェクト、グループ、インスタンス、または`.gitlab-ci.yml`ファイルで定義された変数を含む）。`script`セクションで定義された変数は使用できません。

**`environment:url`の例**

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment:
    name: production
    url: https://prod.example.com
```

**追加の詳細情報**

- ジョブが完了したら、URLにアクセスできます。URLにアクセスするには、マージリクエスト、環境、またはデプロイメントページでボタンを選択します。

#### `environment:on_stop`

`environment`で定義されている`on_stop`キーワードを使用して、環境を閉じる（停止する）ことができます。これは、環境を閉じるために実行される別のジョブを宣言します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**追加の詳細情報**

- 詳細と例については、[`environment:action`](#environmentaction)を参照してください。

#### `environment:action`

`action`キーワードを使用して、ジョブが環境とどのように相互作用するかを指定します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 次のキーワードのいずれか。

| **値** | **説明** |
|:----------|:----------------|
| `start`   | デフォルト値。ジョブが環境を開始することを指定します。デプロイメントはジョブ開始後に作成されます。 |
| `prepare` | ジョブが環境を準備するだけであることを指定します。デプロイメントはトリガーされません。[環境の準備の詳細については、こちらを参照してください](../environments/_index.md#access-an-environment-for-preparation-or-verification-purposes)。 |
| `stop`    | ジョブが環境を停止することを指定します。[環境の停止の詳細については、こちらを参照してください](../environments/_index.md#stopping-an-environment)。 |
| `verify`  | ジョブが環境を検証するだけであること指定します。デプロイメントはトリガーされません。[環境の検証の詳細については、こちらを参照してください](../environments/_index.md#access-an-environment-for-preparation-or-verification-purposes)。 |
| `access`  | ジョブが環境にアクセスするだけであること指定します。デプロイメントはトリガーされません。[環境へのアクセスの詳細については、こちらを参照してください](../environments/_index.md#access-an-environment-for-preparation-or-verification-purposes)。 |

**`environment:action`の例**

```yaml
stop_review_app:
  stage: deploy
  variables:
    GIT_STRATEGY: none
  script: make delete-app
  when: manual
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
```

#### `environment:auto_stop_in`

{{< history >}}

- GitLab 15.4でCI/CD変数のサポートが[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/365140)。
- GitLab 17.7で`prepare`、`access`、および`verify`環境アクションをサポートするために[更新されました](https://gitlab.com/gitlab-org/gitlab/-/issues/437133)。

{{< /history >}}

`auto_stop_in`キーワードは、環境のライフタイムを指定します。環境が期限切れになると、GitLabは自動的に環境を停止します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 自然言語で記述された期間。たとえば、以下の期間はすべて同等です。

- `168 hours`
- `7 days`
- `one week`
- `never`

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**`environment:auto_stop_in`の例**

```yaml
review_app:
  script: deploy-review-app
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    auto_stop_in: 1 day
```

`review_app`の環境が作成されると、その環境のライフタイムは`1 day`に設定されます。レビューアプリケーションがデプロイされるたびに、そのライフタイムも`1 day`にリセットされます。

`auto_stop_in`キーワードは、`stop`を除くすべての[環境アクション](#environmentaction)に使用できます。一部のアクションは、環境のスケジュールされた停止時間をリセットするために使用できます。詳細については、[準備または検証の目的で環境にアクセスする](../environments/_index.md#access-an-environment-for-preparation-or-verification-purposes)を参照してください。

**関連トピック**

- [環境の自動停止に関するドキュメント](../environments/_index.md#stop-an-environment-after-a-certain-time-period)。

#### `environment:kubernetes`

{{< history >}}

- GitLab 17.6で`agent`キーワードが[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/467912)。
- GitLab 17.7で`namespace`および`flux_resource_path`キーワードが[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/500164)。

{{< /history >}}

`kubernetes`キーワードを使用して、環境の[Kubernetes向けダッシュボード](../environments/kubernetes_dashboard.md)を設定します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `agent`: [Kubernetes向けGitLabエージェント](../../user/clusters/agent/_index.md)を指定する文字列。形式は`path/to/agent/project:agent-name`です。
- `namespace`: Kubernetesネームスペースを表す文字列。これは、`agent`キーワードと組み合わせて設定する必要があります。
- `flux_resource_path`: Fluxリソースのパスを表す文字列。これはリソースのフルパスでなければなりません。これは、`agent`および`namespace`キーワードと組み合わせて設定する必要があります。

**`environment:kubernetes`の例**

```yaml
deploy:
  stage: deploy
  script: make deploy-app
  environment:
    name: production
    kubernetes:
      agent: path/to/agent/project:agent-name
      namespace: my-namespace
      flux_resource_path: helm.toolkit.fluxcd.io/v2/namespaces/gitlab-agent/helmreleases/gitlab-agent
```

この設定では、`deploy`ジョブを`production`環境にデプロイするように設定し、[エージェント](../../user/clusters/agent/_index.md)`agent-name`をこの環境に関連付け、ネームスペース`my-namespace`と、`flux_resource_path`が`helm.toolkit.fluxcd.io/v2/namespaces/gitlab-agent/helmreleases/gitlab-agent`に設定された環境の[Kubernetes向けダッシュボード](../environments/kubernetes_dashboard.md)を設定します。

**追加の詳細情報**

- ダッシュボードを使用するには、[Kubernetes向けGitLabエージェントをインストール](../../user/clusters/agent/install/_index.md)し、環境のプロジェクトまたはその親グループの[`user_access`を設定する](../../user/clusters/agent/user_access.md)必要があります。
- ジョブを実行するユーザーには、クラスターエージェントへのアクセス権限が必要です。そうでない場合、`agent`、`namespace`、`flux_resource_path`属性は無視されます。

#### `environment:deployment_tier`

`deployment_tier`キーワードを使用して、デプロイメント環境のプランを指定します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 次のいずれか。

- `production`
- `staging`
- `testing`
- `development`
- `other`

**`environment:deployment_tier`の例**

```yaml
deploy:
  script: echo
  environment:
    name: customer-portal
    deployment_tier: production
```

**追加の詳細情報**

- このジョブ定義から作成された環境には、この値に基づいて[プラン](../environments/_index.md#deployment-tier-of-environments)が割り当てられます。
- この値が後で追加された場合、既存の環境のプランは更新されません。既存の環境のプランを更新するには、[Environments API](../../api/environments.md#update-an-existing-environment)を使用する必要があります。

**関連トピック**

- [環境のデプロイメントプラン](../environments/_index.md#deployment-tier-of-environments)。

#### 動的環境

CI/CD[変数](../variables/_index.md)を使用して、環境に動的に名前を付けます。

次に例を示します。

```yaml
deploy as review app:
  stage: deploy
  script: make deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_ENVIRONMENT_SLUG.example.com/
```

`deploy as review app`ジョブは、`review/$CI_COMMIT_REF_SLUG`環境を動的に作成するためのデプロイメントとしてマークされます。`$CI_COMMIT_REF_SLUG`は、Runnerによって設定される[CI/CD変数](../variables/_index.md)です。`$CI_ENVIRONMENT_SLUG`変数は環境名に基づいていますが、URLに含めるのに適しています。ブランチ`pow`で`deploy as review app`ジョブが実行される場合、この環境は`https://review-pow.example.com/`のようなURLを使用してアクセスできます。

一般的なユースケースは、ブランチの動的環境を作成し、それらをレビューアプリケーションとして使用することです。レビューアプリケーションを使用する例は、<https://gitlab.com/gitlab-examples/review-apps-nginx/>で確認できます。

### `extends`

`extends`を使用して、設定セクションを再利用します。これは[YAMLアンカー](yaml_optimization.md#anchors)の代替手段であり、多少柔軟性が高く、読みやすくなっています。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- パイプライン内の別のジョブの名前。
- パイプライン内の他のジョブの名前のリスト（配列）。

**`extends`の例**

```yaml
.tests:
  stage: test
  image: ruby:3.0

rspec:
  extends: .tests
  script: rake rspec

rubocop:
  extends: .tests
  script: bundle exec rubocop
```

この例では、`rspec`ジョブは`.tests`テンプレートジョブの設定を使用します。パイプラインの作成時に、GitLabは次の処理を行います。

- キーに基づいて逆ディープマージを実行します。
- `.tests`のコンテンツを`rspec`ジョブとマージします。
- キーの値をマージしません。

結合された設定は、以下のジョブと同等です。

```yaml
rspec:
  stage: test
  image: ruby:3.0
  script: rake rspec

rubocop:
  stage: test
  image: ruby:3.0
  script: bundle exec rubocop
```

**追加の詳細情報**

- `extends`に複数の親を使用できます。
- `extends`キーワードは最大11レベルの継承をサポートしていますが、4レベル以上を使用することは避けてください。
- 上記の例では、`.tests`は[隠しジョブ](../jobs/_index.md#hide-a-job)ですが、通常のジョブから設定を拡張することもできます。

**関連トピック**

- [`extends`を使用して設定セクションを再利用する](yaml_optimization.md#use-extends-to-reuse-configuration-sections)。
- `extends`を使用して、[インクルードされた設定ファイル](yaml_optimization.md#use-extends-and-include-together)の設定を再利用する。

### `hooks`

{{< history >}}

- GitLab 15.6で`ci_hooks_pre_get_sources_script`[フラグとともに](../../administration/feature_flags.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/356850)。デフォルトで無効になっています。
- GitLab 15.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/381840)になりました。機能フラグ`ci_hooks_pre_get_sources_script`が削除されました。

{{< /history >}}

`hooks`を使用して、ジョブ実行の特定のステージ（Gitリポジトリを取得する前など）で、Runnerで実行するコマンドのリストを指定します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- フックとそのコマンドのハッシュ。利用可能なフック: `pre_get_sources_script`。

#### `hooks:pre_get_sources_script`

{{< history >}}

- GitLab 15.6で`ci_hooks_pre_get_sources_script`[フラグとともに](../../administration/feature_flags.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/356850)。デフォルトで無効になっています。
- GitLab 15.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/381840)になりました。機能フラグ`ci_hooks_pre_get_sources_script`が削除されました。

{{< /history >}}

`hooks:pre_get_sources_script`を使用して、Gitリポジトリとサブモジュールをクローンする前にRunnerで実行するコマンドのリストを指定します。たとえば、次のような用途に使用できます。

- [Git設定](../jobs/job_troubleshooting.md#get_sources-job-section-fails-because-of-an-http2-problem)を調整する。
- [トレーシング変数](../../topics/git/troubleshooting_git.md#debug-git-with-traces)をエクスポートする。

**サポートされている値**: 次の内容を含む配列。

- 単一行コマンド。
- [複数行に分割された](script.md#split-long-commands)長いコマンド。
- [YAMLアンカー](yaml_optimization.md#yaml-anchors-for-scripts)。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**`hooks:pre_get_sources_script`の例**

```yaml
job1:
  hooks:
    pre_get_sources_script:
      - echo 'hello job1 pre_get_sources_script'
  script: echo 'hello job1 script'
```

**関連トピック**

- [GitLab Runnerの設定](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)

### `identity`

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com
- 状態: ベータ

{{< /details >}}

{{< history >}}

- GitLab 16.9で、`google_cloud_support_feature_flag`[フラグとともに](../../administration/feature_flags.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142054)。この機能は[ベータ版](../../policy/development_stages_support.md)です。
- GitLab 17.1で、[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472)。機能フラグ`google_cloud_support_feature_flag`が削除されました。

{{< /history >}}

この機能は[ベータ版](../../policy/development_stages_support.md)です。

`identity`を使用して、アイデンティティフェデレーションを使用したサードパーティのサービスの認証を行います。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default:`セクション](#default)で使用することができます。

**サポートされている値**: 識別子。サポートされているプロバイダーは以下のとおりです。

- `google_cloud`: Google Cloud。[Google Cloud IAMインテグレーション](../../integration/google_cloud_iam.md)で設定する必要があります。

**`identity`の例**

```yaml
job_with_workload_identity:
  identity: google_cloud
  script:
    - gcloud compute instances list
```

**関連トピック**

- [ワークロードアイデンティティフェデレーション](https://cloud.google.com/iam/docs/workload-identity-federation)。
- [Google Cloud IAMインテグレーション](../../integration/google_cloud_iam.md)。

### `id_tokens`

{{< history >}}

- GitLab 15.7で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/356986)。

{{< /history >}}

`id_tokens`を使用して、サードパーティのサービスの認証を行うための[JSON Web Token（JWT）](https://www.rfc-editor.org/rfc/rfc7519)を作成します。この方法で作成されたすべてのJWTは、OIDC認証をサポートします。必須サブキーワード`aud`は、JWTの`aud`クレームを設定するために使用されます。

**サポートされている値**: 

- `aud`クレームを含むトークン名。`aud`では以下がサポートされています。
  - 単一の文字列。
  - 文字列の配列。
  - [CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**`id_tokens`の例**

```yaml
job_with_id_tokens:
  id_tokens:
    ID_TOKEN_1:
      aud: https://vault.example.com
    ID_TOKEN_2:
      aud:
        - https://gcp.com
        - https://aws.com
    SIGSTORE_ID_TOKEN:
      aud: sigstore
  script:
    - command_to_authenticate_with_vault $ID_TOKEN_1
    - command_to_authenticate_with_aws $ID_TOKEN_2
    - command_to_authenticate_with_gcp $ID_TOKEN_2
```

**関連トピック**

- [IDトークン認証](../secrets/id_token_authentication.md)。
- [クラウドサービスに接続する](../cloud_services/_index.md)。
- [Sigstoreを使用したキーレス署名](signing_examples.md)。

### `image`

`image`を使用して、ジョブが実行されるDockerイメージを指定します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 次のいずれかの形式のイメージ名。必要に応じてレジストリパスが含まれます。

- `<image-name>`（`<image-name>`と`latest`タグを使用する場合と同じ）
- `<image-name>:<tag>`
- `<image-name>@<digest>`

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**`image`の例**

```yaml
default:
  image: ruby:3.0

rspec:
  script: bundle exec rspec

rspec 2.7:
  image: registry.example.com/my-group/my-project/ruby:2.7
  script: bundle exec rspec
```

この例では、`ruby:3.0`イメージはパイプラインのすべてのジョブのデフォルトです。`rspec 2.7`ジョブは、ジョブ固有の`image`セクションでデフォルトをオーバーライドするため、デフォルトを使用しません。

**関連トピック**

- [DockerコンテナでCI/CDジョブを実行する](../docker/using_docker_images.md)。

#### `image:name`

ジョブが実行されるDockerイメージの名前。それ自体が使用する[`image`](#image)と似ています。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 次のいずれかの形式のイメージ名。必要に応じてレジストリパスが含まれます。

- `<image-name>`（`<image-name>`と`latest`タグを使用する場合と同じ）
- `<image-name>:<tag>`
- `<image-name>@<digest>`

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**`image:name`の例**

```yaml
test-job:
  image:
    name: "registry.example.com/my/image:latest"
  script: echo "Hello world"
```

**関連トピック**

- [DockerコンテナでCI/CDジョブを実行する](../docker/using_docker_images.md)。

#### `image:entrypoint`

コンテナのエントリポイントとして実行するコマンドまたはスクリプト。

Dockerコンテナの作成時に、`entrypoint`はDockerの`--entrypoint`オプションに変換されます。構文は[Dockerfile `ENTRYPOINT`ディレクティブ](https://docs.docker.com/reference/dockerfile/#entrypoint)に似ており、各Shellトークンは配列内の個別の文字列です。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- 文字列。

**`image:entrypoint`の例**

```yaml
test-job:
  image:
    name: super/sql:experimental
    entrypoint: [""]
  script: echo "Hello world"
```

**関連トピック**

- [イメージのエントリポイントをオーバーライドする](../docker/using_docker_images.md#override-the-entrypoint-of-an-image)。

#### `image:docker`

{{< history >}}

- GitLab 16.7で[導入されました](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27919)。GitLab Runner 16.7以降が必要です。
- GitLab 16.8で`user`インプットオプションが[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137907)。

{{< /history >}}

`image:docker`を使用して、[Docker executor](https://docs.gitlab.com/runner/executors/docker.html) Runnerにオプションを渡します。このキーワードは、他のexecutorタイプでは機能しません。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

Docker executorのオプションのハッシュ。以下を含めることができます。

- `platform`: プルするイメージのアーキテクチャを選択します。指定しない場合、デフォルトはホストRunnerと同じプラットフォームです。
- `user`: コンテナの実行時に使用するユーザー名または固有識別子（UID）を指定します。

**`image:docker`の例**

```yaml
arm-sql-job:
  script: echo "Run sql tests"
  image:
    name: super/sql:experimental
    docker:
      platform: arm64/v8
      user: dave
```

**追加の詳細情報**

- `image:docker:platform`は[`docker pull --platform`オプション](https://docs.docker.com/reference/cli/docker/image/pull/#options)にマップされます。
- `image:docker:user`は[`docker run --user`オプション](https://docs.docker.com/reference/cli/docker/container/run/#options)にマップされます。

#### `image:pull_policy`

{{< history >}}

- GitLab 15.1で`ci_docker_image_pull_policy`[フラグとともに](../../administration/feature_flags.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/21619)。デフォルトで無効になっています。
- GitLab 15.2で、[GitLab.comおよびGitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)。
- GitLab 15.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)になりました。[機能フラグ`ci_docker_image_pull_policy`](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)が削除されました。
- GitLab Runner 15.1以降が必要です。

{{< /history >}}

RunnerがDockerイメージをフェッチするために使用するプルポリシー。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- 1つのプルポリシー、または配列で指定する複数のプルポリシー。`always`、`if-not-present`、または`never`のいずれかを指定できます。

**`image:pull_policy`の例**

```yaml
job1:
  script: echo "A single pull policy."
  image:
    name: ruby:3.0
    pull_policy: if-not-present

job2:
  script: echo "Multiple pull policies."
  image:
    name: ruby:3.0
    pull_policy: [always, if-not-present]
```

**追加の詳細情報**

- Runnerで定義済みのプルポリシーがサポートされていない場合、ジョブは次のようなエラーで失敗します: `ERROR: Job failed (system failure): the configured PullPolicies ([always]) are not allowed by AllowedPullPolicies ([never])`。

**関連トピック**

- [DockerコンテナでCI/CDジョブを実行する](../docker/using_docker_images.md)。
- [Runnerがイメージをプルする方法を設定する](https://docs.gitlab.com/runner/executors/docker.html#configure-how-runners-pull-images)。
- [複数のプルポリシーを設定する](https://docs.gitlab.com/runner/executors/docker.html#set-multiple-pull-policies)。

### `inherit`

`inherit`を使用して、[デフォルトのキーワードと変数の継承を制御します](../jobs/_index.md#control-the-inheritance-of-default-keywords-and-variables)。

#### `inherit:default`

`inherit:default`を使用して、[デフォルトのキーワード](#default)の継承を制御します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `true`（デフォルト）または`false`（すべてのデフォルトキーワードの継承を有効または無効にする場合）。
- 継承する特定のデフォルトキーワードのリスト。

**`inherit:default`の例**

```yaml
default:
  retry: 2
  image: ruby:3.0
  interruptible: true

job1:
  script: echo "This job does not inherit any default keywords."
  inherit:
    default: false

job2:
  script: echo "This job inherits only the two listed default keywords. It does not inherit 'interruptible'."
  inherit:
    default:
      - retry
      - image
```

**追加の詳細情報**

- 継承するデフォルトキーワードを1行でリストすることもできます: `default: [keyword1, keyword2]`

#### `inherit:variables`

`inherit:variables`を使用して、[デフォルト変数](#default-variables)のキーワードの継承を制御します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `true`（デフォルト）または`false`。すべてのデフォルト変数の継承を有効または無効にします。
- 継承する特定の変数のリスト。

**`inherit:variables`の例**

```yaml
variables:
  VARIABLE1: "This is default variable 1"
  VARIABLE2: "This is default variable 2"
  VARIABLE3: "This is default variable 3"

job1:
  script: echo "This job does not inherit any default variables."
  inherit:
    variables: false

job2:
  script: echo "This job inherits only the two listed default variables. It does not inherit 'VARIABLE3'."
  inherit:
    variables:
      - VARIABLE1
      - VARIABLE2
```

**追加の詳細情報**

- 継承するデフォルト変数を1行にリストすることもできます: `variables: [VARIABLE1, VARIABLE2]`

### `interruptible`

{{< history >}}

- `trigger`ジョブのサポートがGitLab 16.8で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138508)。

{{< /history >}}

新しいコミットに対して同じrefの新しいパイプラインが開始された場合に、ジョブが完了する前にそのジョブをキャンセルするように、[冗長なパイプラインの自動キャンセル](../pipelines/settings.md#auto-cancel-redundant-pipelines)機能を設定するには、`interruptible`を使用します。この機能が無効になっている場合、このキーワードは効果がありません。新しいパイプラインは、新しい変更を含むコミット用である必要があります。たとえば、UIで**パイプラインを新規作成**を選択して同じコミットに対してパイプラインを実行する場合、**冗長なパイプラインの自動キャンセル**機能には効果がありません。

**冗長なパイプラインの自動キャンセル**機能の動作は[`workflow:auto_cancel:on_new_commit`](#workflowauto_cancelon_new_commit)設定で制御できます。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- `true`または`false`（デフォルト）。

**デフォルトの動作を使用する`interruptible`の例**

```yaml
workflow:
  auto_cancel:
    on_new_commit: conservative # the default behavior

stages:
  - stage1
  - stage2
  - stage3

step-1:
  stage: stage1
  script:
    - echo "Can be canceled."
  interruptible: true

step-2:
  stage: stage2
  script:
    - echo "Can not be canceled."

step-3:
  stage: stage3
  script:
    - echo "Because step-2 can not be canceled, this step can never be canceled, even though it's set as interruptible."
  interruptible: true
```

この例では、新しいパイプラインによって実行中のパイプラインが次のようになります。

- `step-1`のみが実行中または保留中の場合は、キャンセルされます。
- `step-2`の開始後は、キャンセルされません。

**`auto_cancel:on_new_commit:interruptible`設定を使用した`interruptible`の例**

```yaml
workflow:
  auto_cancel:
    on_new_commit: interruptible

stages:
  - stage1
  - stage2
  - stage3

step-1:
  stage: stage1
  script:
    - echo "Can be canceled."
  interruptible: true

step-2:
  stage: stage2
  script:
    - echo "Can not be canceled."

step-3:
  stage: stage3
  script:
    - echo "Can be canceled."
  interruptible: true
```

この例では、新しいパイプラインによって、実行中のパイプラインが実行中または保留中の`step-1`と`step-3`をキャンセルします。

**追加の詳細情報**

- ビルドジョブのように、ジョブの開始後にジョブを安全にキャンセルできる場合にのみ、`interruptible: true`を設定してください。部分的なデプロイを防ぐため、通常はデプロイジョブをキャンセルしないでください。
- デフォルトの動作または`workflow:auto_cancel:on_new_commit: conservative`を使用する場合
  - まだ開始されていないジョブは、ジョブの設定に関係なく常に`interruptible: true`と見なされます。`interruptible`設定は、ジョブの開始後にのみ考慮されます。
  - **実行中**のパイプラインがキャンセルされるのは、実行中のすべてのジョブで`interruptible: true`が設定されているか、`interruptible: false`が設定されたジョブが一度も開始されていない場合のみです。`interruptible: false`が設定されたジョブが開始されると、パイプライン全体が割り込み可能と見なされなくなります。
  - パイプラインがダウンストリームパイプラインをトリガーした場合でも、ダウンストリームパイプラインの`interruptible: false`が設定されたジョブがまだ開始されていない場合、ダウンストリームパイプラインもキャンセルされます。
- `interruptible: false`が設定されたオプションのマニュアルジョブをパイプラインの最初のステージに追加して、ユーザーがパイプラインの自動キャンセルを手動で防止できるようにすることができます。ユーザーがジョブを開始した後では、**冗長なパイプラインの自動キャンセル**機能でパイプラインをキャンセルできなくなります。
- [トリガージョブ](#trigger)で`interruptible`を使用する場合
  - トリガーされたダウンストリームパイプラインは、トリガージョブの`interruptible`設定の影響を受けません。
  - [`workflow:auto_cancel`](#workflowauto_cancelon_new_commit)が`conservative`に設定されている場合、トリガージョブの`interruptible`設定は無効です。
  - [`workflow:auto_cancel`](#workflowauto_cancelon_new_commit)が`interruptible`に設定されている場合、`interruptible: true`が設定されたトリガージョブは自動キャンセルできます。

### `needs`

`needs`を使用して、ジョブを順不同で実行します。`needs`を使用するジョブ間の関係は、[有向非巡回グラフ](needs.md)として視覚化できます。

ステージの順序を無視して、他のジョブの完了を待たずに一部のジョブを実行できます。複数のステージのジョブを同時に実行できます。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- ジョブの配列（最大50件）。
- パイプライン作成後すぐジョブを開始するよう設定するための空の配列（`[]`）。

**`needs`の例**

```yaml
linux:build:
  stage: build
  script: echo "Building linux..."

mac:build:
  stage: build
  script: echo "Building mac..."

lint:
  stage: test
  needs: []
  script: echo "Linting..."

linux:rspec:
  stage: test
  needs: ["linux:build"]
  script: echo "Running rspec on linux..."

mac:rspec:
  stage: test
  needs: ["mac:build"]
  script: echo "Running rspec on mac..."

production:
  stage: deploy
  script: echo "Running production..."
  environment: production
```

この例では、4つの実行パスを作成します。

- Linter: `lint`ジョブは、ニーズがないため（`needs: []`）、`build`ステージの完了を待たずにすぐ実行されます。
- Linuxパス: `linux:rspec`ジョブは、`mac:build`の完了を待たずに、`linux:build`ジョブの完了後すぐに実行されます。
- macOSパス: `mac:rspec`ジョブは、`linux:build`の完了を待たずに、`mac:build`ジョブの完了後すぐに実行されます。
- `production`ジョブは、それ以前のすべてのジョブ（`lint`、`linux:build`、`linux:rspec`、`mac:build`、`mac:rspec`）の完了後すぐに実行されます。

**追加の詳細情報**

- 単一のジョブが`needs`配列に含めることのできるジョブの最大数は、次のように制限されています。
  - GitLab.comの場合、制限は50です。詳細については、[イシュー350398](https://gitlab.com/gitlab-org/gitlab/-/issues/350398)を参照してください。
  - GitLab Self-Managedの場合、デフォルトの制限は50です。この制限は[変更可能です](../../administration/cicd/_index.md#set-the-needs-job-limit)。
- `needs`が[`parallel`](#parallel)キーワードを使用するジョブを参照している場合、それは、1つのジョブだけでなく、並列作成されるすべてのジョブに依存します。また、デフォルトでは、すべての並列ジョブからアーティファクトをダウンロードします。同じ名前のアーティファクトがある場合、それらは互いに上書きすることになり、最後にダウンロードしたアーティファクトだけが保存されます。
  - `needs`が（並列ジョブのすべてではなく）並列ジョブのサブセットを参照するようにするには、[`needs:parallel:matrix`](#needsparallelmatrix)キーワードを使用します。
- 設定対象のジョブと同じステージのジョブを参照できます。
- `needs`が`only`、`except`、または`rules`が原因でパイプラインに追加されない可能性があるジョブを参照する場合、パイプラインの作成に失敗する可能性があります。パイプライン作成の失敗を解決するには、[`needs:optional`](#needsoptional)キーワードを使用します。
- パイプラインに`needs: []`を使用したジョブと[`.pre`](#stage-pre)ステージのジョブがある場合、パイプラインの作成直後にすべてのジョブが開始されます。`needs: []`を使用するジョブはすぐに開始され、`.pre`ステージのジョブもすぐに開始されます。

#### `needs:artifacts`

`needs`を使用するジョブはそれ以前のステージの完了前に開始できるため、ジョブで`needs`を使用すると、デフォルトでは、それ以前のステージからアーティファクトすべてをダウンロードすることはなくなります。`needs`を使用する場合、アーティファクトをダウンロードできるのは、`needs`の設定に含まれているジョブからだけになります。

`needs`を使用するジョブでアーティファクトをダウンロードするタイミングを制御するには、`artifacts: true`（デフォルト）または`artifacts: false`を使用します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。`needs:job`と一緒に使用する必要があります。

**サポートされている値**: 

- `true`（デフォルト）または`false`。

**`needs:artifacts`の例**

```yaml
test-job1:
  stage: test
  needs:
    - job: build_job1
      artifacts: true

test-job2:
  stage: test
  needs:
    - job: build_job2
      artifacts: false

test-job3:
  needs:
    - job: build_job1
      artifacts: true
    - job: build_job2
    - build_job3
```

この例では次のようになります。

- `test-job1`ジョブは`build_job1`アーティファクトをダウンロードします。
- `test-job2`ジョブは`build_job2`アーティファクトをダウンロードしません。
- `test-job3`ジョブは、必要なすべてのジョブで`artifacts`に`true`が指定されているか、またはデフォルトで`true`になっているため、3つの`build_jobs`すべてからアーティファクトをダウンロードします。

**追加の詳細情報**

- 同じジョブの中で`needs`を[`dependencies`](#dependencies)と組み合わせて使用しないでください。

#### `needs:project`

{{< details >}}

- プラン: Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`needs:project`は、最大5つのジョブから他のパイプラインにアーティファクトをダウンロードするために使用します。アーティファクトは、指定されたrefについて指定されたジョブのうち成功した最後のものからダウンロードされます。複数のジョブを指定するには、`needs`キーワードの下にそれぞれを個別の配列項目として追加します。

refについて実行中のパイプラインがある場合、`needs:project`を使用するジョブはパイプラインの完了を待機しません。代わりに、アーティファクトは指定されたジョブの実行のうち成功した最後のものからダウンロードされます。

`needs:project`は、`job`、`ref`、および`artifacts`と一緒に使用する必要があります。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `needs:project`: ネームスペースとグループを含む、プロジェクトのフルパス。
- `job`: アーティファクトのダウンロード元のジョブ。
- `ref`: アーティファクトのダウンロード元のref。
- `artifacts`: アーティファクトをダウンロードするには、`true`にする必要があります。

**`needs:project`の例**

```yaml
build_job:
  stage: build
  script:
    - ls -lhR
  needs:
    - project: namespace/group/project-name
      job: build-1
      ref: main
      artifacts: true
    - project: namespace/group/project-name-2
      job: build-2
      ref: main
      artifacts: true
```

この例の`build_job`は、`group/project-name`プロジェクトと`group/project-name-2`プロジェクトの`main`ブランチにおいて成功した最後の`build-1`ジョブおよび`build-2`ジョブからアーティファクトをダウンロードします。

`needs:project`では[CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)を使用できます。次に例を示します。

```yaml
build_job:
  stage: build
  script:
    - ls -lhR
  needs:
    - project: $CI_PROJECT_PATH
      job: $DEPENDENCY_JOB_NAME
      ref: $ARTIFACTS_DOWNLOAD_REF
      artifacts: true
```

**追加の詳細情報**

- 現在のプロジェクト内の別のパイプラインからアーティファクトをダウンロードするには、`project`を現在のプロジェクトと同じになるように設定しますが、現在のパイプラインとは異なるrefを使用します。同じrefで複数の並列パイプラインが同時実行されていると、アーティファクトが上書きされる可能性があります。
- パイプラインを実行しているユーザーは、グループまたはプロジェクトに対して少なくともReporterロールを付与されているか、またはグループ／プロジェクトの表示レベルがパブリックでなければなりません。
- `needs:project`を[`trigger`](#trigger)と同じジョブで使用することはできません。
- `needs:project`を使用して別のパイプラインからアーティファクトをダウンロードする場合、ジョブは必要なジョブが完了するのを待機しません。[`needs`を使用してジョブ完了を待つ](needs.md)機能は、同じパイプライン内のジョブに限定されます。アーティファクトを必要とするジョブがダウンロードを試みる前に、他のパイプライン内の必要なジョブが完了していることを確認してください。
- [`parallel`](#parallel)で実行されるジョブからアーティファクトをダウンロードすることはできません。
- `project`、`job`、および`ref`で[CI/CD変数](../variables/_index.md)をサポートします。

**関連トピック**

- [親子パイプライン](../pipelines/downstream_pipelines.md#parent-child-pipelines)間でアーティファクトをダウンロードするには、[`needs:pipeline:job`](#needspipelinejob)を使用します。

#### `needs:pipeline:job`

[子パイプライン](../pipelines/downstream_pipelines.md#parent-child-pipelines)は、同じ親子パイプライン階層内の親パイプラインまたは別の子パイプラインのジョブからアーティファクトをダウンロードできます。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `needs:pipeline`: パイプラインID。同じ親子パイプライン階層に存在するパイプラインでなければなりません。
- `job`: アーティファクトのダウンロード元のジョブ。

**`needs:pipeline:job`の例**

- 親パイプライン（`.gitlab-ci.yml`）

  ```yaml
  create-artifact:
    stage: build
    script: echo "sample artifact" > artifact.txt
    artifacts:
      paths: [artifact.txt]

  child-pipeline:
    stage: test
    trigger:
      include: child.yml
      strategy: depend
    variables:
      PARENT_PIPELINE_ID: $CI_PIPELINE_ID
  ```

- 子パイプライン（`child.yml`）

  ```yaml
  use-artifact:
    script: cat artifact.txt
    needs:
      - pipeline: $PARENT_PIPELINE_ID
        job: create-artifact
  ```

この例では、親パイプライン内の`create-artifact`ジョブがいくつかのアーティファクトを作成します。`child-pipeline`ジョブは子パイプラインをトリガーし、`CI_PIPELINE_ID`変数を新しい`PARENT_PIPELINE_ID`変数として子パイプラインに渡します。子パイプラインは、`needs:pipeline`の中の変数を使用することにより、親パイプラインからアーティファクトをダウンロードできます。

**追加の詳細情報**

- `pipeline`属性は、現在のパイプラインID（`$CI_PIPELINE_ID`）を受け付けません。現在のパイプライン内のジョブからアーティファクトをダウンロードするには、[`needs:artifacts`](#needsartifacts)を使用します。
- `needs:pipeline:job`を[トリガージョブ](#trigger)で使用することはできず、[マルチプロジェクトパイプライン](../pipelines/downstream_pipelines.md#multi-project-pipelines)からアーティファクトをフェッチするために使用することもできません。マルチプロジェクトパイプラインからアーティファクトをフェッチするには、[`needs:project`](#needsproject)を使用します。

#### `needs:optional`

パイプライン中に存在しないことのあるジョブを必須とするには、`needs`の設定に`optional: true`を追加します。定義されていない場合、`optional: false`がデフォルトです。

[`rules`](#rules)、[`only`、または`except`](#only--except)を使用するジョブを、[`include`](#include)で追加した場合、それらのジョブは、常にパイプラインに追加されるとは限りません。GitLabは、パイプラインを開始する前に`needs`の関係をチェックします。

- `needs`エントリに`optional: true`がある場合、必要なジョブがパイプラインに存在するなら、ジョブはその完了を待機してから開始します。
- 必要なジョブが存在しない場合、ジョブは他のすべてのneeds要件が満たされた時点で開始できます。
- `needs`セクションに含まれるのがオプションのジョブだけであり、そのどれもパイプラインに追加されていない場合、ジョブはすぐに開始されます（空の`needs`エントリと同じ: `needs: []`）。
- 必要なジョブに`optional: false`が指定されているが、パイプラインに追加されなかった場合、パイプラインの開始は失敗し、次のようなエラーになります: `'job1' job needs 'job2' job, but it was not added to the pipeline`。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**`needs:optional`の例**

```yaml
build-job:
  stage: build

test-job1:
  stage: test

test-job2:
  stage: test
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

deploy-job:
  stage: deploy
  needs:
    - job: test-job2
      optional: true
    - job: test-job1
  environment: production

review-job:
  stage: deploy
  needs:
    - job: test-job2
      optional: true
  environment: review
```

この例では次のようになります。

- `build-job`、`test-job1`、および`test-job2`は、ステージの順に開始します。
- ブランチがデフォルトブランチの場合、`test-job2`がパイプラインに追加されるため
  - `deploy-job`は、`test-job1`と`test-job2`の両方が完了するのを待機します。
  - `review-job`は、`test-job2`が完了するのを待機します。
- ブランチがデフォルトブランチでない場合、`test-job2`はパイプラインに追加されないため
  - `deploy-job`は`test-job1`の完了のみを待機し、存在しない`test-job2`は待機しません。
  - `review-job`には他の必要なジョブがなく、`needs: []`のように、（`build-job`と同時に）すぐに開始されます。

#### `needs:pipeline`

`needs:pipeline`キーワードを使用すると、アップストリームパイプラインからジョブにパイプライン状態をミラーリングできます。デフォルトブランチからの最新のパイプライン状態が、ジョブにレプリケートされます。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- ネームスペースとグループを含む、プロジェクトのフルパス。プロジェクトが同じグループまたはネームスペースに含まれる場合は、`project`キーワードからそれらを省略できます。例: `project: group/project-name`または`project: project-name`。

**`needs:pipeline`の例**

```yaml
upstream_status:
  stage: test
  needs:
    pipeline: other/project
```

**追加の詳細情報**

- `job`キーワードを`needs:pipeline`に追加すると、ジョブはパイプラインの状態をミラーリングしなくなります。動作は[`needs:pipeline:job`](#needspipelinejob)に変わります。

#### `needs:parallel:matrix`

{{< history >}}

- GitLab 16.3で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/254821)。

{{< /history >}}

ジョブで[`parallel:matrix`](#parallelmatrix)を使用すれば、単一のパイプラインで1つのジョブを複数同時実行し、ジョブのインスタンスごとに異なる変数値を使用することができます。

複数の並列ジョブに応じてジョブを順不同で実行するには、`needs:parallel:matrix`を使用します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。`needs:job`と一緒に使用する必要があります。

**サポートされている値**: 変数のハッシュの配列。

- 変数と値は、`parallel:matrix`ジョブで定義されている変数と値から選択する必要があります。

**`needs:parallel:matrix`の例**

```yaml
linux:build:
  stage: build
  script: echo "Building linux..."
  parallel:
    matrix:
      - PROVIDER: aws
        STACK:
          - monitoring
          - app1
          - app2

linux:rspec:
  stage: test
  needs:
    - job: linux:build
      parallel:
        matrix:
          - PROVIDER: aws
            STACK: app1
  script: echo "Running rspec on linux..."
```

上記の例では、次のジョブが生成されます。

```plaintext
linux:build: [aws, monitoring]
linux:build: [aws, app1]
linux:build: [aws, app2]
linux:rspec
```

`linux:rspec`ジョブは、`linux:build: [aws, app1]`ジョブが完了するとすぐに実行されます。

**関連トピック**

- [複数の並列ジョブでneedsを使用して並列ジョブを指定します](../jobs/job_control.md#specify-a-parallelized-job-using-needs-with-multiple-parallelized-jobs)。

**追加の詳細情報**

- `needs:parallel:matrix`のマトリックス変数の順序は、必要なジョブのマトリックス変数の順序と一致する必要があります。たとえば、上記の前の例で`linux:rspec`ジョブの変数の順序を逆にするのは無効です。

  ```yaml
  linux:rspec:
    stage: test
    needs:
      - job: linux:build
        parallel:
          matrix:
            - STACK: app1        # The variable order does not match `linux:build` and is invalid.
              PROVIDER: aws
    script: echo "Running rspec on linux..."
  ```

### `pages`

`pages`は、静的コンテンツをGitLabにアップロードする[GitLab Pages](../../user/project/pages/_index.md)ジョブを定義するために使用します。コンテンツはウェブサイトとして公開されます。

次のことをする必要があります。

- `pages: true`を定義し、`public`という名前のディレクトリを公開します。
- 別のコンテンツディレクトリを使用する場合は、代わりに[`pages.publish`](#pagespublish)を定義します。

**キーワードのタイプ**: ジョブキーワードまたはジョブ名（非推奨）。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- ブール値。`true`に設定すると、デフォルトの設定を使用します。
- 設定オプションのハッシュ。詳細については、この後のセクションを参照してください。

**`pages`の例**

```yaml
create-pages:
  stage: deploy
  script:
    - mv my-html-content public
  pages: true  # specifies that this is a Pages job and publishes the default public directory
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  environment: production
```

この例では、`my-html-content/`ディレクトリの名前を`public/`に変更します。このディレクトリはアーティファクトとしてエクスポートされ、GitLab Pagesで公開されます。

**設定ハッシュを使用した例**

```yaml
create-pages:
  stage: deploy
  script:
    - echo "nothing to do here"
  pages:  # specifies that this is a Pages job and publishes the default public directory
    publish: my-html-content
    expire_in: "1 week"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  environment: production
```

この例では、ディレクトリの移動はせず、`publish`プロパティを直接使用します。また、ページデプロイが1週間後に公開されなくなるように設定します。

**非推奨: ジョブ名として`pages`を使用する**

`pages`をジョブ名として使用した場合、Pagesプロパティ`pages: true`を指定するのと同じ動作になります。この方法は下位互換性のために使用できますが、Pagesジョブ設定に対して今後加えられる改善内容の一部を活用できなくなる可能性があります。

**`pages`をジョブ名として使用した例**

```yaml
pages:  # specifies that this is a Pages job and publishes the default public directory
  stage: deploy
  script:
    - mv my-html-content public
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  environment: production
```

Pagesデプロイをトリガーせずに`pages`をジョブ名として使用するには、`pages`プロパティをfalseに設定します。

```yaml
pages:
  stage: deploy
  script:
    - mv my-html-content public
  pages: false # this job will not trigger a Pages deployment
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  environment: production
```

#### `pages.publish`

{{< history >}}

- GitLab 16.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/415821)。
- GitLab 17.9で、`publish`プロパティに渡す際に変数を利用できるように[変更されました](https://gitlab.com/gitlab-org/gitlab/-/issues/500000)。
- GitLab 17.9で、`publish`プロパティは`pages`キーワードの下に[移動しました](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)。
- GitLab 17.10で、`pages.publish`パスが`artifacts:paths`に自動的に[付加されるようになりました](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)。

{{< /history >}}

`pages.publish`は、[`pages`ジョブ](#pages)のコンテンツディレクトリを設定するために使用します。トップレベルキーワード`publish`はGitLab 17.9の時点で非推奨となっており、現在では`pages`キーワードの下にネストされた状態にする必要があります。

**キーワードのタイプ**: ジョブキーワード。これは、`pages`ジョブの一部としてのみ使用できます。

**サポートされている値**: Pagesコンテンツを含むディレクトリのパス。[GitLab 17.10以降](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)、これが指定されていない場合は、デフォルトの`public`ディレクトリが使用されます。指定されている場合、このパスは自動的に[`artifacts:paths`](#artifactspaths)に付加されます。

**`pages.publish`の例**

```yaml
create-pages:
  stage: deploy
  script:
    - npx @11ty/eleventy --input=path/to/eleventy/root --output=dist
  pages:
    publish: dist  # this path is automatically appended to artifacts:paths
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  environment: production
```

この例では、[Eleventy](https://www.11ty.dev)を使用して静的ウェブサイトを生成し、生成されたHTMLファイルを`dist/`ディレクトリに出力します。このディレクトリはアーティファクトとしてエクスポートされ、GitLab Pagesで公開されます。

`pages.publish`フィールドでは変数も使用できます。次に例を示します。

```yaml
create-pages:
  stage: deploy
  script:
    - mkdir -p $CUSTOM_FOLDER/$CUSTOM_PATH
    - cp -r public $CUSTOM_FOLDER/$CUSTOM_SUBFOLDER
  pages:
    publish: $CUSTOM_FOLDER/$CUSTOM_SUBFOLDER  # this path is automatically appended to artifacts:paths
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  variables:
    CUSTOM_FOLDER: "custom_folder"
    CUSTOM_SUBFOLDER: "custom_subfolder"
```

指定する公開パスは、ビルドのルートからの相対パスでなければなりません。

#### `pages.path_prefix`

{{< details >}}

- プラン: Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- 状態: ベータ

{{< /details >}}

{{< history >}}

- GitLab 16.7で、`pages_multiple_versions_setting`という[フラグ付きで](../../user/feature_flags.md)[実験](../../policy/development_stages_support.md)的に[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129534)。デフォルトでは無効になっています。
- GitLab 17.4の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/422145)です。
- GitLab 17.8で、ピリオドを許可するように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/507423)されました。
- GitLab 17.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/487161)になりました。機能フラグ`pages_multiple_versions_setting`が削除されました。

{{< /history >}}

`pages.path_prefix`は、GitLab Pagesの[並列デプロイ](../../user/project/pages/_index.md#parallel-deployments)のパスプレフィックスを設定するために使用します。

**キーワードのタイプ**: ジョブキーワード。これは、`pages`ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- 文字列
- [CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)
- 両方の組み合わせ

指定された値は小文字に変換され、63バイトに短縮されます。英数字以外の文字またはピリオドはすべてハイフンに置き換えられます。先頭と末尾のハイフンまたはピリオドは許可されません。

**`pages.path_prefix`の例**

```yaml
create-pages:
  stage: deploy
  script:
    - echo "Pages accessible through ${CI_PAGES_URL}/${CI_COMMIT_BRANCH}"
  pages:  # specifies that this is a Pages job and publishes the default public directory
    path_prefix: "$CI_COMMIT_BRANCH"
```

この例では、ブランチごとに異なるページデプロイが作成されます。

#### `pages.expire_in`

{{< details >}}

- プラン: Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.4で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/456478)。

{{< /history >}}

`expire_in`は、デプロイが期限切れになるまでの使用可能期間を指定するために使用します。デプロイが期限切れになると、10分ごとに実行されるcronジョブによって非アクティブ状態になります。

デフォルトの場合、[並列デプロイ](../../user/project/pages/_index.md#parallel-deployments)は24時間後に自動的に期限切れになります。この動作を無効にするには、値を`never`に設定します。

**キーワードのタイプ**: ジョブキーワード。これは、`pages`ジョブの一部としてのみ使用できます。

**サポートされている値**: 有効期間。単位が指定されていない場合、時間は秒単位です。有効な値は次のとおりです。

- `'42'`
- `42 seconds`
- `3 mins 4 sec`
- `2 hrs 20 min`
- `2h20min`
- `6 mos 1 day`
- `47 yrs 6 mos and 4d`
- `3 weeks and 2 days`
- `never`

**`pages.expire_in`の例**

```yaml
create-pages:
  stage: deploy
  script:
    - echo "Pages accessible through ${CI_PAGES_URL}"
  pages:  # specifies that this is a Pages job and publishes the default public directory
    expire_in: 1 week
```

### `parallel`

{{< history >}}

- GitLab 15.9で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/336576)、`parallel`の最大値が50から200に増加しました。

{{< /history >}}

`parallel`は、1つのパイプラインで1つのジョブを複数並列同時実行するために使用します。

複数のrunnerが存在するか、または単一のrunnerが複数のジョブを同時実行するように設定されている必要があります。

並列ジョブには、`job_name 1/N`から`job_name N/N`までの連番の名前が付けられます。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `1`から`200`までの数値。

**`parallel`の例**

```yaml
test:
  script: rspec
  parallel: 5
```

この例では、`test 1/5`から`test 5/5`までの名前の同時実行される5つのジョブが作成されます。

**追加の詳細情報**

- どの並列ジョブにも、`CI_NODE_INDEX`と`CI_NODE_TOTAL`の[事前定義済みCI/CD変数](../variables/_index.md#predefined-cicd-variables)が設定されています。
- `parallel`を使用するジョブを含むパイプラインでは、以下のようになります。
  - 実際に利用可能な数より多くの同時実行ジョブを作成する。超過したジョブはキューに入れられ、利用可能なrunnerを待機している間、`pending`のマークが付けられます。
  - 作成するジョブが多すぎると、`job_activity_limit_exceeded`のエラーが発生してパイプラインが失敗します。アクティブなパイプラインで可能なジョブの最大数は、[インスタンスレベルで制限](../../administration/instance_limits.md#number-of-jobs-in-active-pipelines)されています。

**関連トピック**

- [大規模ジョブの並列化](../jobs/job_control.md#parallelize-large-jobs)。

#### `parallel:matrix`

{{< history >}}

- GitLab 15.9で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/336576)、順列の最大数が50から200に増加しました。

{{< /history >}}

`parallel:matrix`は、1つのパイプラインでジョブを複数同時並列実行し、その際にジョブのインスタンスごとに異なる変数値を使用するという場合に使用します。

複数のrunnerが存在するか、または単一のrunnerが複数のジョブを同時実行するように設定されている必要があります。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 変数のハッシュの配列。

- 変数名に使用できるのは、数字、文字、アンダースコア（`_`）のみです。
- 値は、文字列か文字列の配列のどちらかでなければなりません。
- 順列の数は200以下でなければなりません。

**`parallel:matrix`の例**

```yaml
deploystacks:
  stage: deploy
  script:
    - bin/deploy
  parallel:
    matrix:
      - PROVIDER: aws
        STACK:
          - monitoring
          - app1
          - app2
      - PROVIDER: ovh
        STACK: [monitoring, backup, app]
      - PROVIDER: [gcp, vultr]
        STACK: [data, processing]
  environment: $PROVIDER/$STACK
```

この例では、`PROVIDER`と`STACK`の値が異なる10個の並列`deploystacks`ジョブが生成されます。

```plaintext
deploystacks: [aws, monitoring]
deploystacks: [aws, app1]
deploystacks: [aws, app2]
deploystacks: [ovh, monitoring]
deploystacks: [ovh, backup]
deploystacks: [ovh, app]
deploystacks: [gcp, data]
deploystacks: [gcp, processing]
deploystacks: [vultr, data]
deploystacks: [vultr, processing]
```

**追加の詳細情報**

- `parallel:matrix`ジョブは、ジョブを互いに区別するため、ジョブ名に変数値を追加しますが、[値が大きいと名前の数が制限を超える可能性があります](https://gitlab.com/gitlab-org/gitlab/-/issues/362262)。
  - [ジョブ名](../jobs/_index.md#job-names)は255文字以下でなければなりません。
  - [`needs`](#needs)を使用する場合、ジョブ名は128文字以下でなければなりません。
- 変数値は同じで変数名は異なる複数のマトリックス設定を作成することはできません。ジョブ名は変数名ではなく変数値から生成されるため、マトリックスエントリの値が同じなら、同一のジョブ名が生成されて互いに上書きすることになります。

  たとえば、この`test`設定では同一のジョブで構成される2つのシリーズを作成しようとしますが、`OS2`バージョンが`OS`バージョンを上書きすることになります。

  ```yaml
  test:
    parallel:
      matrix:
        - OS: [ubuntu]
          PROVIDER: [aws, gcp]
        - OS2: [ubuntu]
          PROVIDER: [aws, gcp]
  ```

  - `parallel:matrix`で[`!reference`タグ](yaml_optimization.md#reference-tags)を使用する場合、[既知の問題](../debugging.md#config-should-be-an-array-of-hashes-error-message)があります。

**関連トピック**

- [並列ジョブの1次元マトリックスを実行する](../jobs/job_control.md#run-a-one-dimensional-matrix-of-parallel-jobs)。
- [トリガーされた並列ジョブのマトリックスを実行する](../jobs/job_control.md#run-a-matrix-of-parallel-trigger-jobs)。
- [並列マトリックスジョブごとに異なるrunnerタグを選択する](../jobs/job_control.md#select-different-runner-tags-for-each-parallel-matrix-job)。

### `release`

`release`は、[リリース](../../user/project/releases/_index.md)を作成するために使用します。

このリリースジョブは、[`release-cli`](https://gitlab.com/gitlab-org/release-cli/-/tree/master/docs)にアクセス可能でなければならず、それは`$PATH`に存在している必要があります。

[Docker executor](https://docs.gitlab.com/runner/executors/docker.html)を使用する場合は、GitLabコンテナレジストリのイメージ`registry.gitlab.com/gitlab-org/release-cli:latest`を使用できます。

[Shell executor](https://docs.gitlab.com/runner/executors/shell.html)などを使用する場合は、runnerが登録されているサーバーに[`release-cli`をインストールします](../../user/project/releases/release_cli.md)。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: `release`サブキー。

- [`tag_name`](#releasetag_name)
- [`tag_message`](#releasetag_message)（オプション）
- [`name`](#releasename)（オプション）
- [`description`](#releasedescription)
- [`ref`](#releaseref)（オプション）
- [`milestones`](#releasemilestones)（オプション）
- [`released_at`](#releasereleased_at)（オプション）
- [`assets:links`](#releaseassetslinks)（オプション）

**`release`キーワードの例**

```yaml
release_job:
  stage: release
  image: registry.gitlab.com/gitlab-org/release-cli:latest
  rules:
    - if: $CI_COMMIT_TAG                  # Run this job when a tag is created manually
  script:
    - echo "Running the release job."
  release:
    tag_name: $CI_COMMIT_TAG
    name: 'Release $CI_COMMIT_TAG'
    description: 'Release created using the release-cli.'
```

この例では、次の場合にリリースを作成します。

- Gitタグをプッシュする際。
- UIの**コード > タグ**でGitタグを追加する際。

**追加の詳細情報**

- [トリガー](#trigger)ジョブを除くすべてのリリースジョブには、`script`キーワードを含める必要があります。リリースジョブでは、スクリプトコマンドからの出力を使用できます。スクリプトが不要な場合は、プレースホルダーを使用できます。

  ```yaml
  script:
    - echo "release job"
  ```

  この要求事項を削除するという[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/223856)が存在します。

- `release`セクションは、`script`キーワードの後、`after_script`の前に実行されます。
- リリースが作成されるのは、ジョブのメインスクリプトが成功した場合だけです。
- リリースがすでに存在する場合、それは更新されず、`release`キーワードを含むジョブは失敗します。

**関連トピック**

- [`release`キーワードのCI/CDの例](../../user/project/releases/_index.md#creating-a-release-by-using-a-cicd-job)。
- [単一のパイプラインで複数のリリースを作成する](../../user/project/releases/_index.md#create-multiple-releases-in-a-single-pipeline)。
- [カスタムSSL CA公開認証局を使用する](../../user/project/releases/_index.md#use-a-custom-ssl-ca-certificate-authority)。

#### `release:tag_name`

必須。リリースのGitタグ。

このタグがまだプロジェクト内に存在しない場合、リリースと同時に作成されます。新しいタグは、パイプラインに関連付けられたSHAを使用します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- タグ名。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**`release:tag_name`の例**

新しいタグがプロジェクトに追加された時点でリリースを作成するには、次のようにします。

- `tag_name`としてCI/CD変数`$CI_COMMIT_TAG`を使用します。
- 新しいタグに対してのみジョブを実行するよう設定するには、[`rules:if`](#rulesif)を使用します。

```yaml
job:
  script: echo "Running the release job for the new tag."
  release:
    tag_name: $CI_COMMIT_TAG
    description: 'Release description'
  rules:
    - if: $CI_COMMIT_TAG
```

リリースと新しいタグを同時に作成するには、[`rules`](#rules)で新しいタグに対してのみジョブを実行する設定は**しない**でください。セマンティックバージョニングの例を以下に示します。

```yaml
job:
  script: echo "Running the release job and creating a new tag."
  release:
    tag_name: ${MAJOR}_${MINOR}_${REVISION}
    description: 'Release description'
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

#### `release:tag_message`

{{< history >}}

- GitLab 15.3で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/363024)。`release-cli` v0.12.0以降でサポートされています。

{{< /history >}}

タグが存在しない場合、新しく作成されるタグには、`tag_message`で指定されているメッセージが注釈として付けられます。省略した場合、軽量タグが作成されます。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- テキスト文字列。

**`release:tag_message`の例**

```yaml
  release_job:
    stage: release
    release:
      tag_name: $CI_COMMIT_TAG
      description: 'Release description'
      tag_message: 'Annotated tag message'
```

#### `release:name`

リリース名。省略した場合、`release: tag_name`の値が設定されます。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- テキスト文字列。

**`release:name`の例**

```yaml
  release_job:
    stage: release
    release:
      name: 'Release $CI_COMMIT_TAG'
```

#### `release:description`

リリースの長い説明。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- 長い説明の文字列。
- 説明を含むファイルへのパス。
  - そのファイルの場所は、プロジェクトディレクトリ（`$CI_PROJECT_DIR`）からの相対パスでなければなりません。
  - ファイルがシンボリックリンクの場合、`$CI_PROJECT_DIR`の中に存在する必要があります。
  - `./path/to/file`とファイル名にスペースを含めることはできません。

**`release:description`の例**

```yaml
job:
  release:
    tag_name: ${MAJOR}_${MINOR}_${REVISION}
    description: './path/to/CHANGELOG.md'
```

**追加の詳細情報**

- `description`は、`release-cli`を実行するShellによって評価されます。説明の定義にはCI/CD変数を使用できますが、一部のShellでは変数を参照するために[使用する構文が異なります](../variables/_index.md#use-cicd-variables-in-job-scripts)。同じように、一部のShellでは特殊文字をエスケープすることが必要になる場合があります。たとえば、バッククォート（`` ` ``）をバックスラッシュ（` \ `）でエスケープことが必要になる場合があります。

#### `release:ref`

`release: tag_name`がまだ存在しない場合、リリースの`ref`。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- コミットSHA、別のタグ名、またはブランチ名。

#### `release:milestones`

リリースに関連付けられている各マイルストーンのタイトル。

#### `release:released_at`

リリースの準備ができた日時。

**サポートされている値**: 

- ISO 8601形式の日付を引用符で囲んだもの。

**`release:released_at`の例**

```yaml
released_at: '2021-03-15T08:00:00Z'
```

**追加の詳細情報**

- 定義されていない場合は、現在の日時が使用されます。

#### `release:assets:links`

`release:assets:links`は、リリースに[資産リンク](../../user/project/releases/release_fields.md#release-assets)を含めるために使用します。

`release-cli`バージョンv0.4.0以降が必要です。

**`release:assets:links`の例**

```yaml
assets:
  links:
    - name: 'asset1'
      url: 'https://example.com/assets/1'
    - name: 'asset2'
      url: 'https://example.com/assets/2'
      filepath: '/pretty/url/1' # optional
      link_type: 'other' # optional
```

### `resource_group`

`resource_group`は、同じプロジェクトの異なるパイプライン間でジョブが相互に排他的になるようにするための[リソースグループ](../resource_groups/_index.md)を作成するために使用します。

たとえば、同じリソースグループに属する複数のジョブが同時にキューに登録された場合、それらのジョブのうち1つだけが開始されます。その他のジョブは、`resource_group`が解放されるまで待機します。

リソースグループの動作は、他のプログラミング言語でのセマフォに似ています。

デプロイの設定のため、ジョブの並行処理を戦略的に制御するための[プロセスモード](../resource_groups/_index.md#process-modes)を選択することができます。デフォルトのプロセスモードは`unordered`です。リソースグループのプロセスモードを変更するには、[API](../../api/resource_groups.md#edit-an-existing-resource-group)を使用して、既存のリソースグループを編集するリクエストを送信します。

環境ごとに複数のリソースグループを定義できます。たとえば、物理デバイスにデプロイする場合、複数の物理デバイスが存在するかもしれません。各デバイスにデプロイできますが、1つのデバイスで一度に実行できるのは1つのデプロイだけです。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- 英字、数字、`-`、`_`、`/`、`$`、`{`、`}`、`.`、およびスペースのみ。`/`は先頭にも末尾にも使用できません。CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**`resource_group`の例**

```yaml
deploy-to-production:
  script: deploy
  resource_group: production
```

この例の場合、2つの異なるパイプライン内の2つの`deploy-to-production`ジョブを同時に実行することは決してできません。それにより、本番環境で同時デプロイが決して発生しないようにすることができます。

**関連トピック**

- [クロスプロジェクト／親子パイプラインによるパイプラインレベルの並行処理制御](../resource_groups/_index.md#pipeline-level-concurrency-control-with-cross-projectparent-child-pipelines)。

### `retry`

`retry`は、ジョブが失敗した場合にリトライする回数を設定するために使用します。定義されていない場合、デフォルトは`0`になり、ジョブはリトライされません。

ジョブが失敗すると、成功するか最大リトライ回数に達するまで、さらに最大2回ジョブが処理されます。

デフォルトでは、すべてのタイプの失敗でジョブがリトライされます。リトライの対象となる失敗を選択するには、[`retry:when`](#retrywhen)または[`retry:exit_codes`](#retryexit_codes)を使用します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- `0`（デフォルト）、`1`、または`2`。

**`retry`の例**

```yaml
test:
  script: rspec
  retry: 2

test_advanced:
  script:
    - echo "Run a script that results in exit code 137."
    - exit 137
  retry:
    max: 2
    when: runner_system_failure
    exit_codes: 137
```

終了コードが`137`の場合、またはrunnerシステムが失敗した場合、`test_advanced`は最大2回までリトライされます。

#### `retry:when`

`retry:when`は、`retry:max`と組み合わせることにより、失敗の特定のケースでのみジョブをリトライするという場合に使用します。`retry:max`は、[`retry`](#retry)と同じように最大リトライ回数であり、可能な値は`0`、`1`、または`2`です。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- 単一の失敗タイプ、または1つ以上の失敗タイプの配列。

<!--
  If you change any of the values below, make sure to update the `RETRY_WHEN_IN_DOCUMENTATION`
  array in `spec/lib/gitlab/ci/config/entry/retry_spec.rb`.
  The test there makes sure that all documented
  values are valid as a configuration option and therefore should always
  stay in sync with this documentation.
-->

- `always`: あらゆる失敗でリトライします（デフォルト）。
- `unknown_failure`: 失敗の理由が不明な場合にリトライします。
- `script_failure`: 次の場合にリトライします。
  - スクリプトが失敗した場合。
  - runnerがDockerイメージのプルに失敗した場合。`docker`、`docker+machine`、`kubernetes`の[executor](https://docs.gitlab.com/runner/executors/)の場合。
- `api_failure`: APIの失敗時にリトライします。
- `stuck_or_timeout_failure`: ジョブが行き詰まった場合、またはタイムアウトになった場合にリトライします。
- `runner_system_failure`: runnerシステムが失敗した場合（ジョブのセットアップの失敗など）にリトライします。
- `runner_unsupported`: runnerがサポートされていない場合にリトライします。
- `stale_schedule`: 遅延ジョブを実行できなかった場合にリトライします。
- `job_execution_timeout`: ジョブに対して設定されている最大実行時間をスクリプトが超過した場合にリトライします。
- `archived_failure`: ジョブがアーカイブされていて実行できない場合にリトライします。
- `unmet_prerequisites`: ジョブが前提条件タスクの完了に失敗した場合にリトライします。
- `scheduler_failure`: スケジューラーがジョブをrunnerに割り当てることに失敗した場合にリトライします。
- `data_integrity_failure`: ジョブで不明な問題が発生した場合にリトライします。

**`retry:when`の例**（単一の失敗タイプ）

```yaml
test:
  script: rspec
  retry:
    max: 2
    when: runner_system_failure
```

runnerシステムの失敗以外の失敗がある場合、ジョブはリトライされません。

**`retry:when`の例**（複数の失敗タイプの配列）

```yaml
test:
  script: rspec
  retry:
    max: 2
    when:
      - runner_system_failure
      - stuck_or_timeout_failure
```

#### `retry:exit_codes`

{{< history >}}

- GitLab 16.10で`ci_retry_on_exit_codes`[フラグとともに](../../administration/feature_flags.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/430037)。デフォルトで無効になっています。
- GitLab 16.11の[GitLab.comおよびGitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/430037)。
- GitLab 17.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/452412)になりました。機能フラグ`ci_retry_on_exit_codes`が削除されました。

{{< /history >}}

`retry:exit_codes`は、`retry:max`と組み合わせることにより、失敗の特定のケースでのみジョブをリトライするという場合に使用します。`retry:max`は、[`retry`](#retry)と同じように最大リトライ回数であり、可能な値は`0`、`1`、または`2`です。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- 1つの終了コード。
- 終了コードの配列。

**`retry:exit_codes`の例**

```yaml
test_job_1:
  script:
    - echo "Run a script that results in exit code 1. This job isn't retried."
    - exit 1
  retry:
    max: 2
    exit_codes: 137

test_job_2:
  script:
    - echo "Run a script that results in exit code 137. This job will be retried."
    - exit 137
  retry:
    max: 1
    exit_codes:
      - 255
      - 137
```

**関連トピック**

変数を使用することにより、[ジョブ実行の特定のステージについてのリトライ試行回数](../runners/configure_runners.md#job-stages-attempts)を指定できます。

### `rules`

`rules`は、パイプラインにジョブを含めたり除外したりするために使用します。

パイプラインの作成時にルールが評価され、*順番に*評価されます。一致するものが見つかると、それ以上ルールはチェックされず、設定に応じてジョブがパイプラインに含められるか、または除外されます。ルールが一致しない場合、ジョブはパイプラインに追加されません。

`rules`は複数のルールの配列を受け入れます。各ルールには、次のうちの少なくとも1つが必要です。

- `if`
- `changes`
- `exists`
- `when`

必要に応じて、ルールを次のものと組み合わせることもできます。

- `allow_failure`
- `needs`
- `variables`
- `interruptible`

複数のキーワードを組み合わせて[複雑なルール](../jobs/job_rules.md#complex-rules)を作成することができます。

ジョブがパイプラインに追加されるのは次の場合です。

- `if`、`changes`、または`exists`のルールが一致し、かつ、`when: on_success`（定義されていない場合のデフォルト）、`when: delayed`、または`when: always`により設定されている場合。
- `when: on_success`、`when: delayed`、または`when: always`のみのルールに達した場合。

ジョブがパイプラインに追加されないのは次の場合です。

- ルールが一致しない場合。
- ルールが一致し、かつ`when: never`が指定されている場合。

その他の例については、[`rules`でジョブの実行タイミングを指定する](../jobs/job_rules.md)を参照してください。

#### `rules:if`

`rules:if`句は、ジョブをパイプラインに追加するタイミングを指定するために使用します。

- `if`ステートメントがtrueの場合、ジョブをパイプラインに追加します。
- `if`ステートメントがtrueだが、`when: never`と組み合わされている場合、ジョブをパイプラインに追加しません。
- `if`ステートメントがfalseの場合、次の`rules`項目（他に存在する場合）をチェックします。

`if`句は次にように評価されます。

- [CI/CD変数](../variables/_index.md)または[事前定義CI/CD変数](../variables/predefined_variables.md)の値に基づいて（[一部例外](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)あり）。
- [`rules`実行フロー](#rules)に従って順番に。

**キーワードのタイプ**: ジョブ固有およびパイプライン固有。ジョブの一部として使用してジョブの動作を設定するか、または[`workflow`](#workflow)とともに使用してパイプラインの動作を設定できます。

**サポートされている値**: 

- [CI/CD変数式](../jobs/job_rules.md#cicd-variable-expressions)。

**`rules:if`の例**

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/ && $CI_MERGE_REQUEST_TARGET_BRANCH_NAME != $CI_DEFAULT_BRANCH
      when: never
    - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/
      when: manual
      allow_failure: true
    - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME
```

**追加の詳細情報**

- [ネストされた変数](../variables/where_variables_can_be_used.md#nested-variable-expansion)を`if`で使用することはできません。詳細については、[イシュー327780](https://gitlab.com/gitlab-org/gitlab/-/issues/327780)を参照してください。
- ルールが一致し、かつ`when`が定義されていない場合、ルールはジョブで定義されている`when`を使用します。定義されていない場合のデフォルトは`on_success`です。
- [ジョブレベルで`when`をルール内の`when`と組み合わせる](https://gitlab.com/gitlab-org/gitlab/-/issues/219437)ことができます。`rules`の中の`when`の設定は、ジョブレベルの`when`よりも優先されます。
- [`script`](../variables/_index.md#use-cicd-variables-in-job-scripts)セクションの変数とは異なり、ルール式の中の変数は常に`$VARIABLE`として書式設定されます。
  - `rules:if`と`include`を組み合わせて使用すると、[他の設定ファイルを条件付きでインクルード](includes.md#use-rules-with-include)できます。
- `=~`式と`!~`式の右辺のCI/CD変数は、[正規表現として評価されます](../jobs/job_rules.md#store-a-regular-expression-in-a-variable)。

**関連トピック**

- [`rules`の一般的な`if`式](../jobs/job_rules.md#common-if-clauses-with-predefined-variables)。
- [パイプラインの重複を回避する](../jobs/job_rules.md#avoid-duplicate-pipelines)。
- [`rules`を使用してマージリクエストパイプラインを実行する](../pipelines/merge_request_pipelines.md#add-jobs-to-merge-request-pipelines)。

#### `rules:changes`

`rules:changes`は、特定のファイルに加えられた変更をチェックすることにより、ジョブをパイプラインに追加するタイミングを指定するために使用します。

新しいブランチパイプラインの場合、またはGitの`push`イベントがない場合、`rules: changes`の評価結果は常にtrueであり、ジョブは常に実行されます。タグパイプライン、スケジュールパイプライン、手動パイプラインなどのパイプラインのどれについても、Gitの`push`イベントは関連付けられて**いません**。これらのケースに対応するには、[`rules: changes: compare_to`](#ruleschangescompare_to)を使用して、パイプラインrefと比較するブランチを指定します。

`compare_to`を使用しない場合、`rules: changes`を使用するのは[ブランチパイプライン](../pipelines/pipeline_types.md#branch-pipeline)または[マージリクエストパイプライン](../pipelines/merge_request_pipelines.md)においてだけにしてください。それでも、新しいブランチを作成する際、`rules: changes`はtrueと評価されます。以下を使用します。

- マージリクエストパイプラインにおいて`rules:changes`は、変更内容をターゲットMRブランチと比較します。
- ブランチパイプラインにおいて`rules:changes`は、変更内容をブランチの直前のコミットと比較します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

次のものを任意の数だけ含む配列。

- ファイルのパス。ファイルのパスには、[CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)を含めることができます。
- 次のもののワイルドカードパス。
  - 単一のディレクトリ（例: `path/to/directory/*`）。
  - ディレクトリとそのすべてのサブディレクトリ（例: `path/to/directory/**/*`）。
- 同じ拡張子または複数の異なる拡張子の複数ファイルのすべてを対象とするワイルドカード[glob](https://en.wikipedia.org/wiki/Glob_(programming))パス（`*.md`や`path/to/directory/*.{rb,py,sh}`など）。
- ルートディレクトリまたはすべてのディレクトリ内のファイルのワイルドカードパスを二重引用符で囲んだもの。`"*.json"`や`"**/*.json"`など。

**`rules:changes`の例**

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - Dockerfile
      when: manual
      allow_failure: true

docker build alternative:
  variables:
    DOCKERFILES_DIR: 'path/to/dockerfiles'
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - $DOCKERFILES_DIR/**/*
```

この例では次のようになります。

- パイプラインがマージリクエストパイプラインの場合、`Dockerfile`と`$DOCKERFILES_DIR/**/*`内のファイルに変更がないかどうか確認します。
- `Dockerfile`に変更がある場合、ジョブを手動ジョブとしてパイプラインに追加し、ジョブがトリガーされない場合でもパイプラインの実行を継続します（`allow_failure: true`）。
- `$DOCKERFILES_DIR/**/*`内のファイルに変更がある場合、ジョブをパイプラインに追加します。
- リストされたファイルに変更がない場合、ジョブをパイプラインに追加しません（`when: never`と同じ）。

**追加の詳細情報**

- globパターンは、Rubyの[`File.fnmatch`](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch)で、[フラグ](https://docs.ruby-lang.org/en/master/File/Constants.html#module-File::Constants-label-Filename+Globbing+Constants+-28File-3A-3AFNM_-2A-29)`File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`を使用して解釈されます。
- `rules:changes`セクションごとに最大50個のパターンまたはファイルパスを定義できます。
- 一致するファイルのいずれかに変更がある場合、`changes`の解決結果は`true`になります（`OR`演算）。
- その他の例については、[`rules`でジョブの実行タイミングを指定する](../jobs/job_rules.md)を参照してください。
- 変数とパスの両方に文字`$`を使用できます。たとえば、`$VAR`変数が存在する場合、その値が使用されます。それが存在しない場合、`$`はパスの一部として解釈されます。

**関連トピック**

- [`rules: changes`を使用すると、予期せずにジョブまたはパイプラインが実行される可能性があります](../jobs/job_troubleshooting.md#jobs-or-pipelines-run-unexpectedly-when-using-changes)。

##### `rules:changes:paths`

{{< history >}}

- GitLab 15.2で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90171)。

{{< /history >}}

`rules:changes`は、特定のファイルが変更された場合にのみジョブをパイプラインに追加するように指定し、`rules:changes:paths`を使用してファイルを指定するために使用します。

`rules:changes:paths`は、[`rules:changes`](#ruleschanges)をサブキーなしで使用するのと同じです。追加の詳細情報と関連トピックはすべて同じです。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- 上記の`rules:changes`と同じ。

**`rules:changes:paths`の例**

```yaml
docker-build-1:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - Dockerfile

docker-build-2:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        paths:
          - Dockerfile
```

この例の場合、両方のジョブの動作は同じです。

##### `rules:changes:compare_to`

{{< history >}}

- GitLab 15.3で`ci_rules_changes_compare`という[フラグとともに](../../administration/feature_flags.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/293645)。デフォルトで有効になっています。
- GitLab 15.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/366412)になりました。機能フラグ`ci_rules_changes_compare`が削除されました。
- GitLab 17.2でCI/CD変数のサポートが[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/369916)。

{{< /history >}}

`rules:changes:compare_to`は、[`rules:changes:paths`](#ruleschangespaths)のリストに含まれているファイルに加えられた変更と比較するrefを指定するために使用します。

**キーワードのタイプ**: ジョブキーワード。これはジョブの一部としてのみ使用でき、`rules:changes:paths`と組み合わせる必要があります。

**サポートされている値**: 

- ブランチ名。`main`、`branch1`、`refs/heads/branch1`など。
- タグ名。`tag1`、`refs/tags/tag1`など。
- コミットSHA。`2fg31ga14b`など。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**`rules:changes:compare_to`の例**

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        paths:
          - Dockerfile
        compare_to: 'refs/heads/branch1'
```

この例で`docker build`ジョブが含められるのは、`Dockerfile`が`refs/heads/branch1`と比べて変更されていて、かつパイプラインソースがマージリクエストイベントである場合だけです。

**追加の詳細情報**

- [マージ結果パイプライン](../pipelines/merged_results_pipelines.md#troubleshooting)で`compare_to`を使用すると、GitLabが作成する内部コミットが比較基準であるため、予期しない結果になる可能性があります。

**関連トピック**

- `rules:changes:compare_to`を使用すると、[ブランチが空の場合にジョブをスキップする](../jobs/job_rules.md#skip-jobs-if-the-branch-is-empty)ことができます。

#### `rules:exists`

{{< history >}}

- GitLab 15.6でCI/CD変数のサポートが[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/283881)。
- GitLab 17.7で、`exists`パターンまたはファイルパスとの比較チェックの最大回数が10,000から50,000に[増加しました](https://gitlab.com/gitlab-org/gitlab/-/issues/227632)。

{{< /history >}}

`exists`は、特定のファイルがリポジトリ内に存在する場合にジョブを実行する場合に使用します。

**キーワードのタイプ**: ジョブキーワード。ジョブまたは[`include`](#include)の一部として使用できます。

**サポートされている値**: 

- 複数のファイルパスの配列。パスはプロジェクトディレクトリ（`$CI_PROJECT_DIR`）を基準にした相対パスであり、その外部に直接リンクすることはできません。ファイルパスでは、globパターンと[CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)を使用できます。

**`rules:exists`の例**

```yaml
job:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - exists:
        - Dockerfile

job2:
  variables:
    DOCKERPATH: "**/Dockerfile"
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - exists:
        - $DOCKERPATH
```

この例では次のようになります。

- `job1`は、リポジトリのルートディレクトリに`Dockerfile`が存在する場合に実行されます。
- `job2`は、リポジトリ内のどこかに`Dockerfile`が存在する場合に実行されます。

**追加の詳細情報**

- globパターンは、Rubyの[`File.fnmatch`](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch)で、[フラグ](https://docs.ruby-lang.org/en/master/File/Constants.html#module-File::Constants-label-Filename+Globbing+Constants+-28File-3A-3AFNM_-2A-29)`File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`を使用して解釈されます。
- パフォーマンス上の理由から、GitLabは、`exists`パターンまたはファイルパスとの比較チェックを最大50,000回実行します。50,000回のチェック後、パターンglobが含まれるルールは常に一致するようになります。つまり、`exists`ルールは、ファイル数が50,000個を超えるプロジェクト、またはファイル数が50,000未満だが`exists`ルールのチェック回数が50,000回を超えるプロジェクトでは、常に一致することが想定されています。
  - パターンglobが複数ある場合、制限は50,000をglob数で除算した数になります。たとえば、パターンglobが5個あるルールには、ファイル数10,000個という制限があります。
- `rules:exists`セクションごとに最大50個のパターンまたはファイルパスを定義できます。
- リストに含まれるファイルのいずれかが見つかった場合、`exists`の解決結果は`true`になります（`OR`演算）。
- ジョブレベルの`rules:exists`を使用する場合、GitLabは、パイプラインを実行するプロジェクトおよびrefの中からファイルを検索します。[`include`を`rules:exists`とともに使用](includes.md#include-with-rulesexists)する場合、GitLabは、`include`セクションを含むファイルのプロジェクトおよびrefの中からファイルを検索します。以下を使用する場合、`include`セクションを含むプロジェクトは、パイプラインを実行しているプロジェクトと異なる場合があります。
  - [ネストされたインクルード](includes.md#use-nested-includes)。
  - [コンプライアンスパイプライン](../../user/compliance/compliance_pipelines.md)。
- `rules`はジョブ実行前かつアーティファクトのフェッチ前に評価されるため、`rules:exists`は[アーティファクト](../jobs/job_artifacts.md)の存在を検索できません。

##### `rules:exists:paths`

{{< history >}}

- GitLab 16.11で`ci_support_rules_exists_paths_and_project`という[フラグとともに](../../administration/feature_flags.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/386040)。デフォルトで無効になっています。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/386040)になりました。機能フラグ`ci_support_rules_exists_paths_and_project`が削除されました。

{{< /history >}}

`rules:exists:paths`は、[`rules:exists`](#rulesexists)をサブキーなしで使用するのと同じです。追加の詳細情報はすべて同じです。

**キーワードのタイプ**: ジョブキーワード。ジョブまたは[`include`](#include)の一部として使用できます。

**サポートされている値**: 

- 複数のファイルパスの配列。

**`rules:exists:paths`の例**

```yaml
docker-build-1:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      exists:
        - Dockerfile

docker-build-2:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      exists:
        paths:
          - Dockerfile
```

この例の場合、両方のジョブの動作は同じです。

**追加の詳細情報**

- `exists`で、CI/CD変数の中に`/`または`./`を使用することができない場合があります。詳細については、[イシュー386595](https://gitlab.com/gitlab-org/gitlab/-/issues/386595)を参照してください。

##### `rules:exists:project`

{{< history >}}

- GitLab 16.11で`ci_support_rules_exists_paths_and_project`という[フラグとともに](../../administration/feature_flags.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/386040)。デフォルトで無効になっています。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/386040)になりました。機能フラグ`ci_support_rules_exists_paths_and_project`が削除されました。

{{< /history >}}

`rules:exists:project`は、[`rules:exists:paths`](#rulesexistspaths)のリストに含まれているファイルの検索場所を指定するために使用します。`rules:exists:paths`と一緒に使用する必要があります。

**キーワードのタイプ**: ジョブキーワード。ジョブまたは[`include`](#include)の一部として使用できます。`rules:exists:paths`と組み合わせる必要があります。

**サポートされている値**: 

- `exists:project`: ネームスペースとグループを含む、プロジェクトのフルパス。
- `exists:ref`: オプション。ファイルの検索に使用するコミットref。refとしては、タグ、ブランチ名、またはSHAを指定できます。指定しない場合、デフォルトはプロジェクトの`HEAD`です。

**`rules:exists:project`の例**

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - exists:
        paths:
          - Dockerfile
        project: my-group/my-project
        ref: v1.0.0
```

この例において、`docker build`ジョブが含められるのは、`v1.0.0`でタグ付けされたコミットのプロジェクト`my-group/my-project`の中に`Dockerfile`が存在する場合だけです。

#### `rules:when`

`rules:when`は、ジョブをパイプラインに追加する条件を制御するために、単独で、または別のルールの一部として使用します。`rules:when`は[`when`](#when)と似ていますが、入力オプションが若干異なります。

`rules:when`ルールが`if`、`changes`、`exists`のどれとも組み合わされていない場合、ジョブのルールを評価する時点で常に一致することになります。

**キーワードのタイプ**: ジョブ固有。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `on_success`（デフォルト）: 以前のステージでジョブが失敗しなかった場合にのみ、ジョブを実行します。
- `on_failure`: 以前のステージで少なくとも1つのジョブが失敗した場合にのみ、ジョブを実行します。
- `never`: 以前のステージのジョブの状態に関係なく、ジョブを実行しません。
- `always`: 以前のステージのジョブの状態に関係なく、ジョブを実行します。
- `manual`: ジョブを[手動ジョブ](../jobs/job_control.md#create-a-job-that-must-be-run-manually)としてパイプラインに追加します。[`allow_failure`](#allow_failure)のデフォルト値が`false`に変わります。
- `delayed`: ジョブを[遅延ジョブ](../jobs/job_control.md#run-a-job-after-a-delay)としてパイプラインに追加します。

**`rules:when`の例**

```yaml
job1:
  rules:
    - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_REF_NAME =~ /feature/
      when: delayed
    - when: manual
  script:
    - echo
```

この例では、`job1`がパイプラインに追加されるのは、次の場合です。

- デフォルトブランチの場合は、`when`が定義されていない場合のデフォルトの動作である`when: on_success`で。
- フィーチャーブランチの場合は、遅延ジョブとして。
- その他のすべての場合は、手動ジョブとして。

**追加の詳細情報**

- `on_success`と`on_failure`でジョブの状態を評価する場合
  - 以前のステージで[`allow_failure: true`](#allow_failure)が設定されたジョブは、失敗した場合でも成功と見なされます。
  - 以前のステージでスキップされたジョブ（[開始されていない手動ジョブ](../jobs/job_control.md#create-a-job-that-must-be-run-manually)など）は、成功と見なされます。
- `rules:when: manual`を使用して[手動ジョブを追加](../jobs/job_control.md#create-a-job-that-must-be-run-manually)する場合
  - [`allow_failure`](#allow_failure)はデフォルトで`false`になります。このデフォルトは、[`when: manual`](#when)を使用して手動ジョブを追加する場合とは逆です。
  - `rules`の外部で定義された`when: manual`と同じ動作を実現するには、[`rules: allow_failure`](#rulesallow_failure)を`true`に設定します。

#### `rules:allow_failure`

[`allow_failure: true`](#allow_failure)は、ジョブが失敗してもパイプラインを停止しないようにするため、`rules`の中で使用します。

`allow_failure: true`は、手動ジョブでも使用できます。パイプラインは、手動ジョブの結果を待たずに実行を継続します。ルールの中で`allow_failure: false`と`when: manual`を組み合わせると、パイプラインは手動ジョブが実行されるまで待機してから続行されます。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `true`または`false`。定義されていない場合のデフォルトは`false`です。

**`rules:allow_failure`の例**

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH
      when: manual
      allow_failure: true
```

ルールが一致する場合、ジョブは`allow_failure: true`の手動ジョブです。

**追加の詳細情報**

- ルールレベルの`rules:allow_failure`はジョブレベルの[`allow_failure`](#allow_failure)をオーバーライドします。それが適用されるのは、特定のルールがジョブをトリガーする場合だけです。

#### `rules:needs`

{{< history >}}

- GitLab 16.0で`introduce_rules_with_needs`という[フラグとともに](../../user/feature_flags.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/31581)。デフォルトで無効になっています。
- GitLab 16.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/408871)になりました。機能フラグ`introduce_rules_with_needs`が削除されました。

{{< /history >}}

`needs`は、特定の条件に対するジョブの[`needs`](#needs)を更新するために使用します。条件がルールに一致すると、ジョブの`needs`設定は、ルール内の`needs`で完全に置き換えられます。

**キーワードのタイプ**: ジョブ固有。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- 複数のジョブ名の配列（文字列）。
- ジョブ名による（必要に応じて追加の属性による）ハッシュ。
- 特定の条件が満たされた場合に、ジョブのneedsをnoneに設定するための空の配列（`[]`）。

**`rules:needs`の例**

```yaml
build-dev:
  stage: build
  rules:
    - if: $CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH
  script: echo "Feature branch, so building dev version..."

build-prod:
  stage: build
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  script: echo "Default branch, so building prod version..."

tests:
  stage: test
  rules:
    - if: $CI_COMMIT_BRANCH != $CI_DEFAULT_BRANCH
      needs: ['build-dev']
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      needs: ['build-prod']
  script: echo "Running dev specs by default, or prod specs when default branch..."
```

この例では次のようになります。

- パイプラインがデフォルトブランチではないブランチで実行される場合、したがってルールが最初の条件に一致する場合、`specs`ジョブには`build-dev`ジョブが必要です。
- パイプラインがデフォルトブランチで実行される場合、したがってルールが2番目の条件に一致する場合、`specs`ジョブには`build-prod`ジョブが必要です。

**追加の詳細情報**

- ルール内の`needs`は、ジョブレベルで定義されている`needs`をオーバーライドします。オーバーライドされた場合の動作は、[ジョブレベルの`needs`](#needs)と同じです。
- ルール内の`needs`は、[`artifacts`](#needsartifacts)と[`optional`](#needsoptional)を受け入れることができます。

#### `rules:variables`

[`variables`](#variables)は、特定の条件の変数を定義するために、`rules`の中で使用します。

**キーワードのタイプ**: ジョブ固有。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `VARIABLE-NAME: value`形式の変数のハッシュ。

**`rules:variables`の例**

```yaml
job:
  variables:
    DEPLOY_VARIABLE: "default-deploy"
  rules:
    - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
      variables:                              # Override DEPLOY_VARIABLE defined
        DEPLOY_VARIABLE: "deploy-production"  # at the job level.
    - if: $CI_COMMIT_REF_NAME =~ /feature/
      variables:
        IS_A_FEATURE: "true"                  # Define a new variable.
  script:
    - echo "Run script with $DEPLOY_VARIABLE as an argument"
    - echo "Run another script if $IS_A_FEATURE exists"
```

#### `rules:interruptible`

{{< history >}}

- GitLab 16.10で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/194023)。

{{< /history >}}

`interruptible`は、特定の条件でジョブの[`interruptible`](#interruptible)値を更新する場合に、ルールの中で使用します。

**キーワードのタイプ**: ジョブ固有。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `true`または`false`。

**`rules:interruptible`の例**

```yaml
job:
  script: echo "Hello, Rules!"
  interruptible: true
  rules:
    - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
      interruptible: false  # Override interruptible defined at the job level.
    - when: on_success
```

**追加の詳細情報**

- ルールレベルの`rules:interruptible`はジョブレベルの[`interruptible`](#interruptible)をオーバーライドします。それが適用されるのは、特定のルールがジョブをトリガーする場合だけです。

### `run`

{{< details >}}

- 状態: 実験

{{< /details >}}

{{< history >}}

- GitLab 17.3で`pipeline_run_keyword`という[フラグとともに](../../administration/feature_flags.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/440487)。デフォルトで無効になっています。GitLab Runner 17.1が必要です。
- 機能フラグ`pipeline_run_keyword`は、GitLab 17.5で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/471925)されました。

{{< /history >}}

{{< alert type="note" >}}

この機能はテスト用として利用できますが、本番環境での使用には対応していません。

{{< /alert >}}

`run`は、ジョブの中で実行する一連の[ステップ](../steps/_index.md)を定義するために使用します。各ステップは、スクリプトまたは事前定義ステップのいずれかです。

オプションで環境変数とインプットも指定できます。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- 複数のハッシュの配列。各ハッシュは、次の使用可能なキーのステップを表します。
  - `name`: ステップの名前を表す文字列。
  - `script`: 実行するShellコマンドを含む文字列または文字列の配列。
  - `step`: 実行する事前定義済みステップを識別する文字列。
  - `env`: オプション。このステップに固有の環境変数のハッシュ。
  - `inputs`: オプション。事前定義済みステップのインプットパラメーターのハッシュ。

配列エントリごとに、`name`は必須であり、`script`または`step`のどちらか一方が必要です（両方は不可）。

**`run`の例**

``` yaml
job:
  run:
    - name: 'hello_steps'
      script: 'echo "hello from step1"'
    - name: 'bye_steps'
      step: gitlab.com/gitlab-org/ci-cd/runner-tools/echo-step@main
      inputs:
        echo: 'bye steps!'
      env:
        var1: 'value 1'
```

この例のジョブには、次の2つのステップがあります。

- `hello_steps`がShellコマンド`echo`を実行します。
- `bye_steps`が、環境変数とインプットパラメーターにより事前定義済みのステップを使用します。

**追加の詳細情報**

- ステップには、`script`か`step`キーのいずれか一方を含めることができますが、両方を含めることはできません。
- `run`の設定を、既存の[`script`](#script)キーワードと一緒に使用することはできません。
- 複数行スクリプトは、[YAMLブロックスカラー構文](script.md#split-long-commands)を使用して定義できます。

### `script`

`script`は、runnerが実行するコマンドを指定するために使用します。

[トリガージョブ](#trigger)を除くすべてのジョブでは、`script`キーワードが必須です。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 次の内容を含む配列。

- 単一行コマンド。
- [複数行に分割された](script.md#split-long-commands)長いコマンド。
- [YAMLアンカー](yaml_optimization.md#yaml-anchors-for-scripts)。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**`script`の例**

```yaml
job1:
  script: "bundle exec rspec"

job2:
  script:
    - uname -a
    - bundle exec rspec
```

**追加の詳細情報**

- [`script`でこれらの特殊文字を使用](script.md#use-special-characters-with-script)する場合は、単一引用符（`'`）または二重引用符（`"`）を使用する必要があります。

**関連トピック**

- [ゼロ以外の終了コードを無視](script.md#ignore-non-zero-exit-codes)できます。
- [`script`でカラーコードを使用する](script.md#add-color-codes-to-script-output)と、ジョブログのレビューが容易になります。
- [カスタムの折りたたみ可能なセクションを作成](../jobs/job_logs.md#custom-collapsible-sections)して、ジョブログ出力をシンプルにできます。

### `secrets`

{{< details >}}

- プラン: Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`secrets`は、次の[CI/CDシークレット](../secrets/_index.md)を指定するために使用します。

- 外部シークレットプロバイダーから取得する対象。
- ジョブの中で[CI/CD変数](../variables/_index.md)として使用できるようにする対象（デフォルトでは[`file`タイプ](../variables/_index.md#use-file-type-cicd-variables)）。

#### `secrets:vault`

{{< history >}}

- `generic`エンジンオプションは、GitLab Runner 16.11で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/366492)。

{{< /history >}}

`secrets:vault`は、[HashiCorp Vault](https://www.vaultproject.io/)によって提供されるシークレットを指定するために使用します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `engine:name`: シークレットエンジンの名前。`kv-v2`（デフォルト）、`kv-v1`、または`generic`のいずれか。
- `engine:path`: シークレットエンジンのパス。
- `path`: シークレットのパス。
- `field`: パスワードが格納されているフィールドの名前。

**`secrets:vault`の例**

すべての詳細を明示的に指定し、[KV-V2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2)シークレットエンジンを使用するには、次のようにします。

```yaml
job:
  secrets:
    DATABASE_PASSWORD:  # Store the path to the secret in this CI/CD variable
      vault:  # Translates to secret: `ops/data/production/db`, field: `password`
        engine:
          name: kv-v2
          path: ops
        path: production/db
        field: password
```

この構文は短くすることができます。短い構文では、`engine:name`と`engine:path`がどちらもデフォルトの`kv-v2`になります。

```yaml
job:
  secrets:
    DATABASE_PASSWORD:  # Store the path to the secret in this CI/CD variable
      vault: production/db/password  # Translates to secret: `kv-v2/data/production/db`, field: `password`
```

短い構文でカスタムシークレットエンジンのパスを指定するには、`@`で始まるサフィックスを追加します。

```yaml
job:
  secrets:
    DATABASE_PASSWORD:  # Store the path to the secret in this CI/CD variable
      vault: production/db/password@ops  # Translates to secret: `ops/data/production/db`, field: `password`
```

#### `secrets:gcp_secret_manager`

{{< history >}}

- GitLab 16.8およびGitLab Runner 16.8で[導入されました](https://gitlab.com/groups/gitlab-org/-/epics/11739)。

{{< /history >}}

`secrets:gcp_secret_manager`は、[GCP Secret Manager](https://cloud.google.com/security/products/secret-manager)によって提供されるシークレットを指定するために使用します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `name`: シークレットの名前。
- `version`: シークレットのバージョン。

**`secrets:gcp_secret_manager`の例**

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      gcp_secret_manager:
        name: 'test'
        version: 2
```

**関連トピック**

- [GitLab CI/CDの中でGCP Secret Managerのシークレットを使用する](../secrets/gcp_secret_manager.md)。

#### `secrets:azure_key_vault`

{{< history >}}

- GitLab 16.3およびGitLab Runner 16.3で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/271271)。

{{< /history >}}

`secrets:azure_key_vault`は、[Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault/)によって提供されるシークレットを指定するために使用します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `name`: シークレットの名前。
- `version`: シークレットのバージョン。

**`secrets:azure_key_vault`の例**

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      azure_key_vault:
        name: 'test'
        version: 'test'
```

**関連トピック**

- [GitLab CI/CDの中でAzure Key Vaultのシークレットを使用する](../secrets/azure_key_vault.md)。

#### `secrets:file`

`secrets:file`は、[`file`または`variable`のタイプのCI/CD変数](../variables/_index.md#use-file-type-cicd-variables)として格納されるシークレットを設定するために使用します。

デフォルトの場合、シークレットは`file`タイプのCI/CD変数としてジョブに渡されます。シークレットの値がファイルに保存され、変数にはファイルへのパスが格納されます。

ソフトウェアで`file`タイプのCI/CD変数を使用できない場合は、`file: false`を設定して、シークレットの値を変数に直接保存してください。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `true`（デフォルト）または`false`。

**`secrets:file`の例**

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      vault: production/db/password@ops
      file: false
```

**追加の詳細情報**

- `file`キーワードはCI/CD変数のための設定であり、`vault`セクションではなくCI/CD変数名の下にネストする必要があります。

#### `secrets:token`

{{< history >}}

- GitLab 15.8で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/356986)。**JSON Web Token（JWT）アクセスを制限する**の設定により制御します。
- GitLab 16.0では、[常に使用可能であり、**JSON Web Token（JWT）アクセスを制限する**の設定は削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/366798)。

{{< /history >}}

`secrets:token`を使用して、トークンのCI/CD変数を参照することにより、外部シークレットプロバイダーで認証する際に使用するトークンを明示的に選択します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- IDトークンの名前。

**`secrets:token`の例**

```yaml
job:
  id_tokens:
    AWS_TOKEN:
      aud: https://aws.example.com
    VAULT_TOKEN:
      aud: https://vault.example.com
  secrets:
    DB_PASSWORD:
      vault: gitlab/production/db
      token: $VAULT_TOKEN
```

**追加の詳細情報**

- `token`キーワードが設定されておらず、トークンが1つしか定義されていない場合、定義されたトークンが自動的に使用されます。
- 複数のトークンが定義されている場合は、`token`キーワードを設定して、使用するトークンを指定する必要があります。使用するトークンを指定しない場合、ジョブの実行ごとにどのトークンが使用されるかを予測することはできません。

### `services`

`services`は、スクリプトが正常に実行されるために必要な追加のDockerイメージを指定するために使用します。[`services`イメージ](../services/_index.md)は、[`image`](#image)キーワードで指定されるイメージにリンクされています。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 必要に応じてレジストリパスを含む、サービスイメージの名前。その形式は次のいずれかです。

- `<image-name>`（`<image-name>`と`latest`タグを使用する場合と同じ）
- `<image-name>:<tag>`
- `<image-name>@<digest>`

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)が、[`alias`ではサポートされていません](https://gitlab.com/gitlab-org/gitlab/-/issues/19561)。

**`services`の例**

```yaml
default:
  image:
    name: ruby:2.6
    entrypoint: ["/bin/bash"]

  services:
    - name: my-postgres:11.7
      alias: db-postgres
      entrypoint: ["/usr/local/bin/db-postgres"]
      command: ["start"]

  before_script:
    - bundle install

test:
  script:
    - bundle exec rake spec
```

この例の場合、GitLabはジョブ用に以下の2つのコンテナを起動します。

- `script`コマンドを実行するRubyコンテナ。
- PostgreSQLコンテナ。Rubyコンテナの`script`コマンドは、`db-postgrest`ホスト名にあるPostgreSQLデータベースに接続できます。

**関連トピック**

- [`services`の使用可能な設定](../services/_index.md#available-settings-for-services)。
- [`.gitlab-ci.yml`ファイルの中で`services`を定義する](../services/_index.md#define-services-in-the-gitlab-ciyml-file)。
- [DockerコンテナでCI/CDジョブを実行する](../docker/using_docker_images.md)。
- [Dockerを使用してDockerイメージをビルドする](../docker/using_docker_build.md)。

#### `services:docker`

{{< history >}}

- GitLab 16.7で[導入されました](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27919)。GitLab Runner 16.7以降が必要です。
- GitLab 16.8で`user`インプットオプションが[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137907)。

{{< /history >}}

`services:docker`は、GitLab RunnerのDocker executorにオプションを渡すために使用します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

Docker executorのオプションのハッシュ。以下を含めることができます。

- `platform`: プルするイメージのアーキテクチャを選択します。指定しない場合、デフォルトはホストRunnerと同じプラットフォームです。
- `user`: コンテナの実行時に使用するユーザー名または固有識別子（UID）を指定します。

**`services:docker`の例**

```yaml
arm-sql-job:
  script: echo "Run sql tests in service container"
  image: ruby:2.6
  services:
    - name: super/sql:experimental
      docker:
        platform: arm64/v8
        user: dave
```

**追加の詳細情報**

- `services:docker:platform`は[`docker pull --platform`オプション](https://docs.docker.com/reference/cli/docker/image/pull/#options)にマップされます。
- `services:docker:user`は[`docker run --user`オプション](https://docs.docker.com/reference/cli/docker/container/run/#options)にマップされます。

#### `services:pull_policy`

{{< history >}}

- GitLab 15.1で`ci_docker_image_pull_policy`[フラグとともに](../../administration/feature_flags.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/21619)。デフォルトで無効になっています。
- GitLab 15.2で、[GitLab.comおよびGitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)。
- GitLab 15.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)になりました。[機能フラグ`ci_docker_image_pull_policy`](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)が削除されました。
- GitLab Runner 15.1以降が必要です。

{{< /history >}}

RunnerがDockerイメージをフェッチするために使用するプルポリシー。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- 1つのプルポリシー、または配列で指定する複数のプルポリシー。`always`、`if-not-present`、または`never`のいずれかを指定できます。

**`services:pull_policy`の例**

```yaml
job1:
  script: echo "A single pull policy."
  services:
    - name: postgres:11.6
      pull_policy: if-not-present

job2:
  script: echo "Multiple pull policies."
  services:
    - name: postgres:11.6
      pull_policy: [always, if-not-present]
```

**追加の詳細情報**

- Runnerで定義済みのプルポリシーがサポートされていない場合、ジョブは次のようなエラーで失敗します: `ERROR: Job failed (system failure): the configured PullPolicies ([always]) are not allowed by AllowedPullPolicies ([never])`。

**関連トピック**

- [DockerコンテナでCI/CDジョブを実行する](../docker/using_docker_images.md)。
- [Runnerがイメージをプルする方法を設定する](https://docs.gitlab.com/runner/executors/docker.html#configure-how-runners-pull-images)。
- [複数のプルポリシーを設定する](https://docs.gitlab.com/runner/executors/docker.html#set-multiple-pull-policies)。

### `stage`

`stage`は、ジョブが実行される[ステージ](#stages)を定義するために使用します。同じ`stage`の中のジョブは、並列実行できます（**追加の詳細情報**を参照）。

`stage`が定義されていない場合、ジョブはデフォルトで`test`ステージを使用します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 文字列。次のいずれか。

- [デフォルトステージ](#stages)。
- ユーザー定義ステージ。

**`stage`の例**

```yaml
stages:
  - build
  - test
  - deploy

job1:
  stage: build
  script:
    - echo "This job compiles code."

job2:
  stage: test
  script:
    - echo "This job tests the compiled code. It runs when the build stage completes."

job3:
  script:
    - echo "This job also runs in the test stage".

job4:
  stage: deploy
  script:
    - echo "This job deploys the code. It runs when the test stage completes."
  environment: production
```

**追加の詳細情報**

- ステージ名は255文字以下でなければなりません。
- ジョブが異なる複数のrunnerで実行される場合、並列実行が可能です。
- runnerが1つしかない場合、そのrunnerの[`concurrent`設定](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section)が`1`より大きいなら、ジョブを並列実行できます。

#### `stage: .pre`

`.pre`ステージは、パイプラインの開始時にジョブが実行されるようにするために使用します。デフォルトの場合、`.pre`はパイプラインの最初のステージです。ユーザー定義ステージは、`.pre`の後に実行されます。[`stages`](#stages)の中で`.pre`を定義する必要はありません。

パイプラインに`.pre`ステージまたは`.post`ステージのジョブのみが含まれている場合、パイプラインは実行されません。別のステージに少なくとも1つのジョブが必要です。

**キーワードのタイプ**: ジョブの`stage`キーワードでのみ使用できます。

**`stage: .pre`の例**

```yaml
stages:
  - build
  - test

job1:
  stage: build
  script:
    - echo "This job runs in the build stage."

first-job:
  stage: .pre
  script:
    - echo "This job runs in the .pre stage, before all other stages."

job2:
  stage: test
  script:
    - echo "This job runs in the test stage."
```

**追加の詳細情報**

- パイプラインに[`needs: []`](#needs)を使用したジョブと`.pre`ステージのジョブがある場合、パイプラインの作成直後にすべてのジョブが開始されます。`needs: []`のジョブは、ステージ設定を無視してすぐに開始されます。
- [パイプライン実行ポリシー](../../user/application_security/policies/pipeline_execution_policies.md)により、`.pre`の前に実行される`.pipeline-policy-pre`ステージを定義できます。

#### `stage: .post`

`.post`ステージは、パイプラインの最後にジョブが実行されるようにするために使用します。デフォルトの場合、`.post`はパイプラインの最後のステージです。ユーザー定義ステージは、`.post`の前に実行されます。[`stages`](#stages)の中で`.post`を定義する必要はありません。

パイプラインに`.pre`ステージまたは`.post`ステージのジョブのみが含まれている場合、パイプラインは実行されません。別のステージに少なくとも1つのジョブが必要です。

**キーワードのタイプ**: ジョブの`stage`キーワードでのみ使用できます。

**`stage: .post`の例**

```yaml
stages:
  - build
  - test

job1:
  stage: build
  script:
    - echo "This job runs in the build stage."

last-job:
  stage: .post
  script:
    - echo "This job runs in the .post stage, after all other stages."

job2:
  stage: test
  script:
    - echo "This job runs in the test stage."
```

**追加の詳細情報**

- [パイプライン実行ポリシー](../../user/application_security/policies/pipeline_execution_policies.md)により、`.post`の後に実行される`.pipeline-policy-post`ステージを定義できます。

### `tags`

`tags`は、プロジェクトで使用可能なすべてのrunnerのリストから特定のrunnerを選択するために使用します。

runnerを登録する際に、runnerのタグ（`ruby`、`postgres`、`development`など）を指定できます。ジョブを取得して実行するには、ジョブの中でリストされているすべてのタグがrunnerに割り当てられている必要があります。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 

- タグ名の配列（大文字と小文字が区別されます）。
- CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**`tags`の例**

```yaml
job:
  tags:
    - ruby
    - postgres
```

この例の場合、ジョブを実行できるのは、`ruby`タグと`postgres`タグの*両方*が指定されたrunnerだけです。

**追加の詳細情報**

- タグの数は`50`未満でなければなりません。

**関連トピック**

- [runnerが実行できるジョブを制御するためにタグを使用する](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)
- [並列マトリックスジョブごとに異なるrunnerタグを選択する](../jobs/job_control.md#select-different-runner-tags-for-each-parallel-matrix-job)
- ホストされるrunnerのrunnerタグ
  - [Linux上でホストされるrunner](../runners/hosted_runners/linux.md)
  - [GPU対応の、ホストされるrunner](../runners/hosted_runners/gpu_enabled.md)
  - [macOS上でホストされるrunner](../runners/hosted_runners/macos.md)
  - [Windows上でホストされるrunner](../runners/hosted_runners/windows.md)

### `timeout`

`timeout`は、特定のジョブのタイムアウトを設定するために使用します。ジョブがタイムアウトより長く実行されると、ジョブは失敗します。

ジョブレベルのタイムアウトは、[プロジェクトレベルのタイムアウト](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run)よりも長くすることができますが、[runnerのタイムアウト](../runners/configure_runners.md#set-the-maximum-job-timeout)よりも長くすることはできません。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用するか、または[`default`セクション](#default)で使用することができます。

**サポートされている値**: 自然言語で記述された期間。たとえば、以下の期間はすべて同等です。

- `3600 seconds`
- `60 minutes`
- `one hour`

**`timeout`の例**

```yaml
build:
  script: build.sh
  timeout: 3 hours 30 minutes

test:
  script: rspec
  timeout: 3h 30m
```

### `trigger`

{{< history >}}

- GitLab 16.4で`environment`のサポートが[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/369061)。

{{< /history >}}

`trigger`は、ジョブが次のいずれかの[ダウンストリームパイプライン](../pipelines/downstream_pipelines.md)を開始する「トリガージョブ」であることを宣言するために使用します。

- [マルチプロジェクトパイプライン](../pipelines/downstream_pipelines.md#multi-project-pipelines)。
- [子パイプライン](../pipelines/downstream_pipelines.md#parent-child-pipelines)。

トリガージョブで使用できるGitLab CI/CD設定キーワードは限られています。トリガージョブで使用できるキーワードは次のとおりです。

- [`allow_failure`](#allow_failure)。
- [`extends`](#extends)。
- [`needs`](#needs)。ただし、[`needs:project`](#needsproject)は除きます。
- [`only`と`except`](#only--except)。
- [`parallel`](#parallel)。
- [`rules`](#rules)。
- [`stage`](#stage)。
- [`trigger`](#trigger)。
- [`variables`](#variables)。
- [`when`](#when)（`on_success`、`on_failure`、または`always`の値のみ）。
- [`resource_group`](#resource_group)。
- [`environment`](#environment)。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- マルチプロジェクトパイプラインの場合、ダウンストリームプロジェクトのパス。CI/CD変数[がサポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)（GitLab 15.3以降）。ただし、[ジョブ専用変数](../variables/predefined_variables.md#variable-availability)はサポートされていません。代替手段として[`trigger:project`](#triggerproject)を使用してください。
- 子パイプラインの場合は、[`trigger:include`](#triggerinclude)を使用します。

**`trigger`の例**

```yaml
trigger-multi-project-pipeline:
  trigger: my-group/my-project
```

**追加の詳細情報**

- `trigger`と同じジョブの中で[`when:manual`](#when)を使用することはできますが、APIを使用して`when:manual`トリガージョブを開始することはできません。詳細については、[イシュー284086](https://gitlab.com/gitlab-org/gitlab/-/issues/284086)を参照してください。
- 手動トリガージョブを実行する前に、[CI/CD変数を手動で指定](../jobs/job_control.md#specify-variables-when-running-manual-jobs)することはできません。
- トップレベルの`variables`セクション（グローバル）またはトリガージョブの中で定義された[CI/CD変数](#variables)は、[トリガー変数](../pipelines/downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline)としてダウンストリームパイプラインに転送されます。
- [パイプライン変数](../variables/_index.md#cicd-variable-precedence)は、デフォルトではダウンストリームパイプラインに渡されません。これらの変数をダウンストリームパイプラインに転送するには、[trigger:forward](#triggerforward)を使用します。
- [ジョブ専用変数](../variables/predefined_variables.md#variable-availability)は、トリガージョブでは使用できません。
- [runnerの`config.toml`の中で定義された](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)環境変数は、トリガージョブでは使用できず、ダウンストリームパイプラインに渡されません。
- トリガージョブでは[`needs:pipeline:job`](#needspipelinejob)を使用できません。

**関連トピック**

- [マルチプロジェクトパイプライン設定の例](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file)。
- 特定のブランチ、タグ、またはコミット用にパイプラインを実行するには、[トリガートークン](../triggers/_index.md)を使用して[パイプライントリガーAPI](../../api/pipeline_triggers.md)の認証を実施することができます。トリガートークンは、`trigger`キーワードとは異なります。

#### `trigger:include`

`trigger:include`は、ジョブが[子パイプライン](../pipelines/downstream_pipelines.md#parent-child-pipelines)を開始する「トリガージョブ」であることを宣言するために使用します。

さらに

- [動的子パイプライン](../pipelines/downstream_pipelines.md#dynamic-child-pipelines)をトリガーするには、`trigger:include:artifact`を使います。
- ダウンストリームパイプライン設定で[`spec:inputs`](#specinputs)を使用する際に[インプット](../inputs/_index.md)を設定するには、`trigger:include:inputs`を使用します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- 子パイプラインの設定ファイルへのパス。

**`trigger:include`の例**

```yaml
trigger-child-pipeline:
  trigger:
    include: path/to/child-pipeline.gitlab-ci.yml
```

**関連トピック**

- [子パイプライン設定の例](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file)。

#### `trigger:project`

`trigger:project`は、ジョブが[マルチプロジェクトパイプライン](../pipelines/downstream_pipelines.md#multi-project-pipelines)を開始する「トリガージョブ」であることを宣言するために使用します。

デフォルトの場合、マルチプロジェクトパイプラインは、デフォルトブランチに対してトリガーされます。別のブランチを指定するには、`trigger:branch`を使用します。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- ダウンストリームプロジェクトへのパス。CI/CD変数[がサポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)（GitLab 15.3以降）。ただし、[ジョブ専用変数](../variables/predefined_variables.md#variable-availability)はサポートされていません。

**`trigger:project`の例**

```yaml
trigger-multi-project-pipeline:
  trigger:
    project: my-group/my-project
```

**別のブランチの`trigger:project`の例**

```yaml
trigger-multi-project-pipeline:
  trigger:
    project: my-group/my-project
    branch: development
```

**関連トピック**

- [マルチプロジェクトパイプライン設定の例](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file)。
- 特定のブランチ、タグ、またはコミットのためにパイプラインを実行するには、やはり[トリガートークン](../triggers/_index.md)を使用して[パイプライントリガーAPI](../../api/pipeline_triggers.md)の認証を実施することができます。トリガートークンは、`trigger`キーワードとは異なります。

#### `trigger:strategy`

`trigger:strategy`は、`trigger`ジョブに**成功**のマークが付けられる前に、ダウンストリームパイプラインが完了するのを強制的に待機するという場合に使用します。

この動作はデフォルトとは異なります。デフォルトの場合、ダウンストリームパイプラインの作成後すぐ、`trigger`ジョブに**成功**マークが付けられます。

この設定により、パイプラインの実行は並列ではなく線形になります。

**`trigger:strategy`の例**

```yaml
trigger_job:
  trigger:
    include: path/to/child-pipeline.yml
    strategy: depend
```

この例の場合、後続のステージのジョブは、トリガーされたパイプラインが正常に完了するまで開始を待機します。

**追加の詳細情報**

- ダウンストリームパイプラインに含まれる[オプションの手動ジョブ](../jobs/job_control.md#types-of-manual-jobs)は、ダウンストリームパイプラインまたはアップストリームトリガージョブの状態に影響を与えません。ダウンストリームパイプラインは、オプションの手動ジョブを実行せずに正常に完了できます。
- ダウンストリームパイプラインの[ブロック手動ジョブ](../jobs/job_control.md#types-of-manual-jobs)は、トリガージョブに成功または失敗のマークが付けられる前に実行する必要があります。手動ジョブが原因でダウンストリームパイプラインの状態が**手動アクションを待機中**（{{< icon name="status_manual" >}}）になっている場合、トリガージョブは**保留中**（{{< icon name="status_pending" >}}）として表示されます。デフォルトの場合、以降のステージのジョブは、トリガージョブが完了するまで開始されません。
- ダウンストリームパイプラインに失敗したジョブがあっても、そのジョブで[`allow_failure: true`](#allow_failure)を使用している場合、ダウンストリームパイプラインは成功したと見なされ、トリガージョブは**成功**として表示されます。

#### `trigger:inputs`

{{< history >}}

- GitLab 17.11で`ci_inputs_for_pipelines`という[フラグとともに](../../administration/feature_flags.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/519963)。デフォルトで無効になっています。

{{</history >}}

`trigger:inputs`は、ダウンストリームパイプライン設定で[`spec:inputs`](#specinputs)を使用する場合に[インプット](../inputs/_index.md)を設定するために使用します。

**`trigger:inputs`の例**

```yaml
trigger:
  - project: 'my-group/my-project'
    inputs:
      website: "My website"
```

#### `trigger:forward`

{{< history >}}

- GitLab 15.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/355572)になりました。[機能フラグ`ci_trigger_forward_variables`](https://gitlab.com/gitlab-org/gitlab/-/issues/355572)が削除されました。

{{< /history >}}

`trigger:forward`は、ダウンストリームパイプラインへの転送内容を指定するために使用します。[親子パイプライン](../pipelines/downstream_pipelines.md#parent-child-pipelines)と[マルチプロジェクトパイプライン](../pipelines/downstream_pipelines.md#multi-project-pipelines)の両方に転送する内容を制御できます。

ネストされたダウンストリームパイプラインでは、ネストされたダウンストリームトリガージョブでも`trigger:forward`を使用しているのでない限り、転送された変数は、デフォルトでは再度転送されることはありません。

**サポートされている値**: 

- `yaml_variables`: `true`（デフォルト）、または`false`。`true`の場合、トリガージョブで定義されている変数がダウンストリームパイプラインに渡されます。
- `pipeline_variables`: `true`または`false`（デフォルト）。`true`の場合、[パイプライン変数](../variables/_index.md#cicd-variable-precedence)がダウンストリームパイプラインに渡されます。

**`trigger:forward`の例**

CI/CD変数`MYVAR = my value`を使用して、[このパイプラインを手動で実行](../pipelines/_index.md#run-a-pipeline-manually)します。

```yaml
variables: # default variables for each job
  VAR: value

# Default behavior:
# - VAR is passed to the child
# - MYVAR is not passed to the child
child1:
  trigger:
    include: .child-pipeline.yml

# Forward pipeline variables:
# - VAR is passed to the child
# - MYVAR is passed to the child
child2:
  trigger:
    include: .child-pipeline.yml
    forward:
      pipeline_variables: true

# Do not forward YAML variables:
# - VAR is not passed to the child
# - MYVAR is not passed to the child
child3:
  trigger:
    include: .child-pipeline.yml
    forward:
      yaml_variables: false
```

**追加の詳細情報**

- `trigger:forward`でダウンストリームパイプラインに転送されるCI/CD変数は、優先順位の高い[パイプライン変数](../variables/_index.md#cicd-variable-precedence)です。同じ名前の変数がダウンストリームパイプラインの中で定義されている場合、通常、その変数は、転送される変数によって上書きされます。

### `when`

`when`は、ジョブの実行条件を設定するために使用します。ジョブの中で定義されていない場合のデフォルト値は`when: on_success`です。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部として使用できます。`when: always`と`when: never`は、[`workflow:rules`](#workflow)でも使用できます。

**サポートされている値**: 

- `on_success`（デフォルト）: 以前のステージでジョブが失敗しなかった場合にのみ、ジョブを実行します。
- `on_failure`: 以前のステージで少なくとも1つのジョブが失敗した場合にのみ、ジョブを実行します。
- `never`: 以前のステージのジョブの状態に関係なく、ジョブを実行しません。[`rules`](#ruleswhen)セクションまたは[`workflow: rules`](#workflowrules)でのみ使用できます。
- `always`: 以前のステージのジョブの状態に関係なく、ジョブを実行します。
- `manual`: ジョブを[手動ジョブ](../jobs/job_control.md#create-a-job-that-must-be-run-manually)としてパイプラインに追加します。
- `delayed`: ジョブを[遅延ジョブ](../jobs/job_control.md#run-a-job-after-a-delay)としてパイプラインに追加します。

**`when`の例**

```yaml
stages:
  - build
  - cleanup_build
  - test
  - deploy
  - cleanup

build_job:
  stage: build
  script:
    - make build

cleanup_build_job:
  stage: cleanup_build
  script:
    - cleanup build when failed
  when: on_failure

test_job:
  stage: test
  script:
    - make test

deploy_job:
  stage: deploy
  script:
    - make deploy
  when: manual
  environment: production

cleanup_job:
  stage: cleanup
  script:
    - cleanup after jobs
  when: always
```

この例のスクリプトは、

1. `build_job`が失敗した場合にのみ、`cleanup_build_job`を実行します。
1. 成功したか失敗したかに関係なく、パイプラインの最後のステップとして常に`cleanup_job`を実行します。
1. GitLab UIの中で、手動で実行する場合、`deploy_job`を実行します。

**追加の詳細情報**

- `on_success`と`on_failure`でジョブの状態を評価する場合
  - 以前のステージで[`allow_failure: true`](#allow_failure)が設定されたジョブは、失敗した場合でも成功と見なされます。
  - 以前のステージでスキップされたジョブ（[開始されていない手動ジョブ](../jobs/job_control.md#create-a-job-that-must-be-run-manually)など）は、成功と見なされます。
- `when: manual`の場合、[`allow_failure`](#allow_failure)のデフォルト値は`true`です。[`rules:when: manual`](#ruleswhen)の場合、デフォルト値は`false`に変わります。

**関連トピック**

- `when`を[`rules`](#rules)と組み合わせて使用すると、さらに動的にジョブを制御できます。
- `when`を[`workflow`](#workflow)と組み合わせて使用すると、パイプライン開始のタイミングを制御できます。

#### `manual_confirmation`

{{< history >}}

- GitLab 17.1で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/18906)。

{{< /history >}}

`manual_confirmation`は、手動ジョブのカスタム確認メッセージを定義するために、[`when: manual`](#when)とともに使用します。`when: manual`で定義された手動ジョブがない場合、このキーワードは無効です。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- 確認メッセージの文字列。

**`manual_confirmation`の例**

```yaml
delete_job:
  stage: post-deployment
  script:
    - make delete
  when: manual
  manual_confirmation: 'Are you sure you want to delete this environment?'
```

## `variables`

`variables`は、[CI/CD変数](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)を定義するために使用します。

変数は、[CI/CDジョブの中で定義する](#job-variables)か、またはすべてのジョブのための[デフォルトCI/CD変数](#default-variables)を定義するためのトップレベル（グローバル）キーワードとして定義できます。

**追加の詳細情報**

- YAML定義のすべての変数は、リンクされている[Dockerサービスコンテナ](../services/_index.md)に対しても設定されます。
- YAML定義の変数は、機密でないプロジェクトの設定を目的としています。機密情報は[保護された変数](../variables/_index.md#protect-a-cicd-variable)または[CI/CDシークレット](../secrets/_index.md)に保存します。
- [手動パイプライン変数](../variables/_index.md#use-pipeline-variables)と[スケジュールされたパイプライン変数](../pipelines/schedules.md#add-a-pipeline-schedule)は、デフォルトではダウンストリームパイプラインに渡されません。これらの変数をダウンストリームパイプラインに転送するには、[trigger:forward](#triggerforward)を使用します。

**関連トピック**

- [事前定義済み変数](../variables/predefined_variables.md)は、runnerが自動的に作成し、runnerによりジョブで使用可能にする変数です。
- [変数を使用することにより、runnerの動作を設定](../runners/configure_runners.md#configure-runner-behavior-with-variables)できます。

### ジョブ`variables`

ジョブ変数は、ジョブの`script`、`before_script`、または`after_script`セクションのコマンド、および一部の[ジョブキーワード](#job-keywords)で使用できます。各ジョブキーワードが変数をサポートしているかどうかを確認するには、それぞれの**サポートされている値**セクションをチェックしてください。

ジョブ変数を、[`include`](includes.md#use-variables-with-include)などの[グローバルキーワード](#global-keywords)の値として使用することはできません。

**サポートされている値**: 変数名と値のペア。

- 名前には数字、文字、アンダースコア（`_`）のみを使用できます。一部のShellでは、最初の文字が英字でなければなりません。
- 値は文字列でなければなりません。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**ジョブ`variables`の例**

```yaml
review_job:
  variables:
    DEPLOY_SITE: "https://dev.example.com/"
    REVIEW_PATH: "/review"
  script:
    - deploy-review-script --url $DEPLOY_SITE --path $REVIEW_PATH
```

この例では次のようになります。

- `review_job`では、`DEPLOY_SITE`と`REVIEW_PATH`のジョブ変数が定義されています。これらのジョブ変数は、どちらも`script`セクションで使用できます。

### デフォルト`variables`

トップレベルの`variables`セクションで定義されている変数は、すべてのジョブのデフォルト変数として機能します。

各デフォルト変数は、パイプラインの中のあらゆるジョブで使用できます。ただし、ジョブに同じ名前で定義された変数がすでに存在する場合は除きます。ジョブの中で定義される変数のほうが[優先される](../variables/_index.md#cicd-variable-precedence)ため、同じ名前のデフォルト変数の値をジョブで使用することはできません。

ジョブ変数と同じように、[`include`](includes.md#use-variables-with-include)など、他のグローバルキーワードの値としてデフォルト変数を使用することはできません。

**サポートされている値**: 変数名と値のペア。

- 名前には数字、文字、アンダースコア（`_`）のみを使用できます。一部のShellでは、最初の文字が英字でなければなりません。
- 値は文字列でなければなりません。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**`variables`の例**

```yaml
variables:
  DEPLOY_SITE: "https://example.com/"

deploy_job:
  stage: deploy
  script:
    - deploy-script --url $DEPLOY_SITE --path "/"
  environment: production

deploy_review_job:
  stage: deploy
  variables:
    DEPLOY_SITE: "https://dev.example.com/"
    REVIEW_PATH: "/review"
  script:
    - deploy-review-script --url $DEPLOY_SITE --path $REVIEW_PATH
  environment: production
```

この例では次のようになります。

- `deploy_job`には変数が定義されていません。デフォルトの`DEPLOY_SITE`変数がジョブにコピーされるので、それを`script`セクションで使用することができます。
- `deploy_review_job`にはすでに`DEPLOY_SITE`変数が定義されているため、デフォルトの`DEPLOY_SITE`はジョブにコピーされません。このジョブには、`REVIEW_PATH`ジョブ変数も定義されています。これらのジョブ変数は、どちらも`script`セクションで使用できます。

#### `variables:description`

`description`キーワードは、デフォルト変数の説明を定義するために使用します。[パイプラインを手動で実行すると、変数名の部分に事前に値が設定されて](../pipelines/_index.md#prefill-variables-in-manual-pipelines)説明が表示されます。

**キーワードのタイプ**: このキーワードを使用できるのはデフォルト`variables`の場合だけであり、ジョブ`variables`では使用できません。

**サポートされている値**: 

- 文字列。

**`variables:description`の例**

```yaml
variables:
  DEPLOY_NOTE:
    description: "The deployment note. Explain the reason for this deployment."
```

**追加の詳細情報**

- `value`なしで使用すると、手動ではトリガーされなかったパイプラインの中に変数が存在しており、デフォルト値は空文字列（`''`）になります。

#### `variables:value`

`value`キーワードは、パイプラインレベル（デフォルト）の変数の値を定義するために使用します。[`variables: description`](#variablesdescription)とともに使用すると、変数の値は、[パイプラインを手動で実行した時点で事前設定されます](../pipelines/_index.md#prefill-variables-in-manual-pipelines)。

**キーワードのタイプ**: このキーワードを使用できるのはデフォルト`variables`の場合だけであり、ジョブ`variables`では使用できません。

**サポートされている値**: 

- 文字列。

**`variables:value`の例**

```yaml
variables:
  DEPLOY_ENVIRONMENT:
    value: "staging"
    description: "The deployment target. Change this variable to 'canary' or 'production' if needed."
```

**追加の詳細情報**

- [`variables: description`](#variablesdescription)なしで使用した場合の動作は、[`variables`](#variables)と同じです。

#### `variables:options`

{{< history >}}

- GitLab 15.7で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105502)。

{{< /history >}}

`variables:options`は、[パイプラインを手動で実行する際に、UIの中で選択可能な](../pipelines/_index.md#configure-a-list-of-selectable-prefilled-variable-values)値の配列を定義するために使用します。

`variables: value`とともに使用する必要があります。`value`に対して定義される文字列は、

- `options`配列内の文字列のいずれかでもなければなりません。
- デフォルトの選択になります。

[`description`](#variablesdescription)がない場合、このキーワードは無効です。

**キーワードのタイプ**: このキーワードを使用できるのはデフォルト`variables`の場合だけであり、ジョブ`variables`では使用できません。

**サポートされている値**: 

- 文字列の配列。

**`variables:options`の例**

```yaml
variables:
  DEPLOY_ENVIRONMENT:
    value: "staging"
    options:
      - "production"
      - "staging"
      - "canary"
    description: "The deployment target. Set to 'staging' by default."
```

### `variables:expand`

{{< history >}}

- GitLab 15.6で`ci_raw_variables_in_yaml_config`[フラグとともに](../../administration/feature_flags.md)[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/353991)。デフォルトで無効になっています。
- GitLab 15.6の[GitLab.comで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/375034)。
- GitLab 15.7の[GitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/375034)。
- GitLab 15.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/375034)になりました。機能フラグ`ci_raw_variables_in_yaml_config`が削除されました。

{{< /history >}}

`expand`キーワードは、変数を展開可能として設定するかどうかを設定するために使用します。

**キーワードのタイプ**: このキーワードは、デフォルトとジョブ両方の`variables`で使用できます。

**サポートされている値**: 

- `true`（デフォルト）: 変数は展開可能です。
- `false`: 変数は展開できません。

**`variables:expand`の例**

```yaml
variables:
  VAR1: value1
  VAR2: value2 $VAR1
  VAR3:
    value: value3 $VAR1
    expand: false
```

- `VAR2`の結果は`value2 value1`です。
- `VAR3`の結果は`value3 $VAR1`です。

**追加の詳細情報**

- `expand`キーワードを使用できるのは、デフォルトとジョブの`variables`キーワードでだけです。[`rules:variables`](#rulesvariables)や[`workflow:rules:variables`](#workflowrulesvariables)と一緒に使用することはできません。

## 非推奨のキーワード

以下のキーワードは非推奨です。

{{< alert type="note" >}}

これらのキーワードは、下位互換性を確保するために引き続き使用できますが、将来のメジャーマイルストーンで削除される可能性があります。

{{< /alert >}}

### グローバル定義の`image`、`services`、`cache`、`before_script`、`after_script`

`image`、`services`、`cache`、`before_script`、および`after_script`をグローバルに定義することは非推奨です。これらのキーワードをトップレベルで使用することは、下位互換性を確保するために引き続き可能ですが、将来のマイルストーンで削除される可能性があります。

代わりに[`default`](#default)を使用してください。次に例を示します。

```yaml
default:
  image: ruby:3.0
  services:
    - docker:dind
  cache:
    paths: [vendor/]
  before_script:
    - bundle config set path vendor/bundle
    - bundle install
  after_script:
    - rm -rf tmp/
```

### `only` / `except`

{{< alert type="note" >}}

`only`と`except`は非推奨であり、積極的な開発の対象とされていません。これらのキーワードは、下位互換性を確保するために引き続き使用できますが、将来のマイルストーンで削除される可能性があります。ジョブをパイプラインに追加するタイミングを制御するには、代わりに[`rules`](#rules)を使用してください。

{{< /alert >}}

`only`と`except`を使用することによって、ジョブをパイプラインに追加するタイミングを制御することができます。

- `only`は、ジョブの実行タイミングを定義するために使用します。
- `except`は、ジョブを実行**しない**場合を定義するために使用します。

#### `only:refs` / `except:refs`

{{< alert type="note" >}}

`only:refs`と`except:refs`は非推奨であり、積極的な開発の対象とされていません。これらのキーワードは、下位互換性を確保するために引き続き使用できますが、将来のマイルストーンで削除される可能性があります。ref、正規表現、または変数を使用してジョブをパイプラインに追加するタイミングを制御するには、代わりに[`rules:if`](#rulesif)を使用してください。

{{< /alert >}}

`only:refs`と`except:refs`のキーワードを使用することによって、ブランチ名またはパイプラインタイプに基づいてジョブをパイプラインに追加するタイミングを制御できます。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 次のものを任意の数だけ含む配列。

- ブランチ名（`main`や`my-feature-branch`など）。
- ブランチ名にマッチする正規表現（`/^feature-.*/`など）。
- 次のキーワード。

  | **値**                | **説明** |
  | -------------------------|-----------------|
  | `api`                    | [パイプラインAPI](../../api/pipelines.md#create-a-new-pipeline)によってトリガーされるパイプラインの場合。 |
  | `branches`               | パイプラインのGit参照がブランチの場合。 |
  | `chat`                   | [GitLab ChatOps](../chatops/_index.md)コマンドを使用して作成されたパイプラインの場合。 |
  | `external`               | GitLab以外のCIサービスを使用する場合。 |
  | `external_pull_requests` | GitHubで外部プルリクエストが作成または更新された場合（[外部プルリクエストのパイプライン](../ci_cd_for_external_repos/_index.md#pipelines-for-external-pull-requests)を参照）。 |
  | `merge_requests`         | マージリクエストの作成時または更新時に作成されるパイプラインの場合。[マージリクエストパイプライン](../pipelines/merge_request_pipelines.md)、[マージ結果パイプライン](../pipelines/merged_results_pipelines.md)、および[マージトレイン](../pipelines/merge_trains.md)を有効にします。 |
  | `pipelines`              | [`CI_JOB_TOKEN`によりAPIを使用することにより](../pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api)、または[`trigger`](#trigger)キーワードを使用することにより作成された[マルチプロジェクトパイプライン](../pipelines/downstream_pipelines.md#multi-project-pipelines)の場合。 |
  | `pushes`                 | `git push`イベントによってトリガーされるパイプラインの場合（ブランチとタグを含む）。 |
  | `schedules`              | [スケジュールされたパイプライン](../pipelines/schedules.md)の場合。 |
  | `tags`                   | パイプラインのGit参照がタグの場合。 |
  | `triggers`               | [トリガートークン](../triggers/_index.md#configure-cicd-jobs-to-run-in-triggered-pipelines)を使用して作成されたパイプラインの場合。 |
  | `web`                    | プロジェクトの**ビルド > パイプライン**セクションから、GitLab UIで**新しいパイプライン**を選択して作成されたパイプラインの場合。 |

**`only:refs`および`except:refs`の例**

```yaml
job1:
  script: echo
  only:
    - main
    - /^issue-.*$/
    - merge_requests

job2:
  script: echo
  except:
    - main
    - /^stable-branch.*$/
    - schedules
```

**追加の詳細情報**

- スケジュールされたパイプラインは特定のブランチで実行されるため、`only: branches`を指定して設定されたジョブもスケジュールされたパイプラインで実行されます。スケジュールされたパイプラインで、`only: branches`のジョブが実行されないようにするには、`except: schedules`を追加します。
- 他のキーワードなしで使用される`only`または`except`は、`only: refs`または`except: refs`と同等です。たとえば、次の2つのジョブ設定の動作は同じです。

  ```yaml
  job1:
    script: echo
    only:
      - branches

  job2:
    script: echo
    only:
      refs:
        - branches
  ```

- ジョブが`only`、`except`、または[`rules`](#rules)のどれも使用しない場合、デフォルトで、`branches`と`tags`に`only`が設定されます。

  たとえば、`job1`と`job2`は同等です。

  ```yaml
  job1:
    script: echo "test"

  job2:
    script: echo "test"
    only:
      - branches
      - tags
  ```

#### `only:variables` / `except:variables`

{{< alert type="note" >}}

`only:variables`と`except:variables`は非推奨であり、積極的な開発の対象とされていません。これらのキーワードは、下位互換性を確保するために引き続き使用できますが、将来のマイルストーンで削除される可能性があります。ref、正規表現、または変数を使用してジョブをパイプラインに追加するタイミングを制御するには、代わりに[`rules:if`](#rulesif)を使用してください。

{{< /alert >}}

`only:variables`または`except:variables`のキーワードを使用することにより、[CI/CD変数](../variables/_index.md)の状態に基づいてジョブをパイプラインに追加するタイミングを制御できます。

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- [CI/CD変数式](../jobs/job_rules.md#cicd-variable-expressions)の配列。

**`only:variables`の例**

```yaml
deploy:
  script: cap staging deploy
  only:
    variables:
      - $RELEASE == "staging"
      - $STAGING
```

#### `only:changes` / `except:changes`

`only:variables`と`except:variables`

{{< alert type="note" >}}

`only:changes`と`except:changes`は非推奨であり、積極的な開発の対象とされていません。これらのキーワードは、下位互換性を確保するために引き続き使用できますが、将来のマイルストーンで削除される可能性があります。ファイルへの変更を利用してジョブをパイプラインに追加するタイミングを制御するには、代わりに[`rules:changes`](#ruleschanges)を使用してください。

{{< /alert >}}

`changes`キーワードは、`only`とともに使用してジョブを実行するため、または`except`とともに使用してGitプッシュイベントでファイルが変更された場合にジョブをスキップするために使用します。

パイプラインでは、以下のrefとともに`changes`を使用します。

- `branches`
- `external_pull_requests`
- `merge_requests`

**キーワードのタイプ**: ジョブキーワード。ジョブの一部としてのみ使用できます。

**サポートされている値**: 次のものを任意の数だけ含む配列。

- ファイルのパス。
- 次のもののワイルドカードパス。
  - 単一のディレクトリ（例: `path/to/directory/*`）。
  - ディレクトリとそのすべてのサブディレクトリ（例: `path/to/directory/**/*`）。
- 同じ拡張子または複数の異なる拡張子の複数ファイルのすべてを対象とするワイルドカード[glob](https://en.wikipedia.org/wiki/Glob_(programming))パス（`*.md`や`path/to/directory/*.{rb,py,sh}`など）。
- ルートディレクトリまたはすべてのディレクトリ内のファイルのワイルドカードパスを二重引用符で囲んだもの。`"*.json"`や`"**/*.json"`など。

**`only:changes`の例**

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  only:
    refs:
      - branches
    changes:
      - Dockerfile
      - docker/scripts/*
      - dockerfiles/**/*
      - more_scripts/*.{rb,py,sh}
      - "**/*.json"
```

**追加の詳細情報**

- 一致するファイルのいずれかに変更がある場合、`changes`の解決結果は`true`になります（`OR`演算）。
- globパターンは、Rubyの[`File.fnmatch`](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch)で、[フラグ](https://docs.ruby-lang.org/en/master/File/Constants.html#module-File::Constants-label-Filename+Globbing+Constants+-28File-3A-3AFNM_-2A-29)`File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`を使用して解釈されます。
- `branches`、`external_pull_requests`、`merge_requests`以外のrefを使用すると、`changes`は特定のファイルが新しいか古いかを判断できず、常に`true`を返します。
- `only: changes`を他のrefとともに使用すると、ジョブは変更を無視し、常に実行されます。
- `except: changes`を他のrefとともに使用すると、ジョブは変更を無視し、決して実行されません。

**関連トピック**

- [`only: changes`を使用すると、予期せずにジョブまたはパイプラインが実行される可能性があります](../jobs/job_troubleshooting.md#jobs-or-pipelines-run-unexpectedly-when-using-changes)。

#### `only:kubernetes` / `except:kubernetes`

{{< alert type="note" >}}

`only:kubernetes`と`except:kubernetes`は非推奨であり、積極的な開発の対象とされていません。これらのキーワードは、下位互換性を確保するために引き続き使用できますが、将来のマイルストーンで削除される可能性があります。プロジェクトでKubernetesサービスがアクティブな場合にジョブがパイプラインに追加されるかどうかを制御するには、代わりに、[`CI_KUBERNETES_ACTIVE`](../variables/predefined_variables.md)事前定義済みCI/CD変数を含む[`rules:if`](#rulesif)を使用してください。

{{< /alert >}}

`only:kubernetes`または`except:kubernetes`は、プロジェクトでKubernetesサービスがアクティブな場合にジョブがパイプラインに追加されるかどうかを制御するために使用します。

**キーワードのタイプ**: ジョブ固有。ジョブの一部としてのみ使用できます。

**サポートされている値**: 

- `kubernetes`戦略で受け入れられるのは、`active`キーワードだけです。

**`only:kubernetes`の例**

```yaml
deploy:
  only:
    kubernetes: active
```

この例で`deploy`ジョブが実行されるのは、プロジェクトの中でKubernetesサービスがアクティブな場合だけです。
