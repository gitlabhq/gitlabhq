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

GitLab CI/CDの設定はYAML形式を使用するため、キーワードの順序は特に指定がない限り重要ではありません。

より動的なパイプラインの設定オプションについては、[CI/CD式](expressions.md)を使用してください。

<!--
If you are editing content on this page, follow the instructions for documenting keywords:
https://docs.gitlab.com/development/cicd/cicd_reference_documentation_guide/
-->

## キーワード {#keywords}

GitLab CI/CDパイプラインの設定には、次の要素が含まれます:

- パイプラインの動作を設定する[グローバルキーワード](#global-keywords):

  | キーワード                           | 説明 |
  |-----------------------------------|:------------|
  | [`default`](#default)             | ジョブキーワードに対するカスタムデフォルト値。 |
  | [`include`](#include)             | 他のYAMLファイルから設定をインポートします。 |
  | [`stages`](#stages)               | パイプラインステージの名前と順序。 |
  | [`variables`](#default-variables) | パイプラインのすべてのジョブのデフォルトCI/CD変数を定義します。 |
  | [`workflow`](#workflow)           | 実行するパイプラインのタイプを制御します。 |

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
  | [`start_in`](#start_in)                       | 指定された期間、ジョブの実行を遅らせます。`when: delayed`が必要です。 |
  | [`tags`](#tags)                               | Runnerを選択するために使用されるタグのリスト。 |
  | [`timeout`](#timeout)                         | プロジェクト全体の設定よりも優先される、カスタムのジョブレベルのタイムアウトを定義します。 |
  | [`trigger`](#trigger)                         | ダウンストリームパイプライントリガーを定義します。 |
  | [`variables`](#job-variables)                 | 個々のジョブのCI/CD変数を定義します。 |
  | [`when`](#when)                               | ジョブを実行するタイミング。 |

- 現在は使用が推奨されていない[非推奨のキーワード](deprecated_keywords.md)。

---

## グローバルキーワード {#global-keywords}

一部のキーワードはジョブでは定義されません。これらのキーワードは、パイプラインの動作を制御するか、追加のパイプライン設定をインポートします。

---

### `default` {#default}

{{< history >}}

- `id_tokens`のサポートは、GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/419750)されました。

{{< /history >}}

一部のキーワードではグローバルデフォルトを設定できます。各デフォルトキーワードは、まだそのキーワードが定義されていないすべてのジョブにコピーされます。

デフォルトの設定は、ジョブの設定とマージされません。ジョブにキーワードがすでに定義されている場合、ジョブのキーワードが優先され、そのキーワードのデフォルトの設定は使用されません。

**Keyword type**（キーワードのタイプ）: グローバルキーワード。

**Supported values**（サポートされている値）: 以下のキーワードにはカスタムデフォルトを設定できます:

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
- [`timeout`](#timeout) 。ただし、[イシュー213634](https://gitlab.com/gitlab-org/gitlab/-/issues/213634)のためこのキーワードには効果がありません。

**Example of `default`**（の例）:

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

**Additional details**（補足情報）:

- [`inherit:default`](#inheritdefault)を使用することで、ジョブごとにデフォルトキーワードの継承を制御できます。
- グローバルデフォルトは[ダウンストリームパイプライン](../pipelines/downstream_pipelines.md)には引き継がれません。ダウンストリームパイプラインは、それをトリガーしたアップストリームパイプラインとは独立して実行されます。

---

### `include` {#include}

`include`を使用して、外部のYAMLファイルをCI/CD設定にインクルードすることができます。1つの長い`.gitlab-ci.yml`ファイルを複数のファイルに分割することで読みやすさを向上させたり、複数の場所で同じ設定が重複する状況を減らしたりすることができます。

テンプレートファイルを中央のリポジトリに保存し、プロジェクトにインクルードすることもできます。

`include`ファイルは次のように処理されます:

- `.gitlab-ci.yml`ファイルの内容とマージされます。
- `include`キーワードの位置に関係なく、常に最初に評価され、`.gitlab-ci.yml`ファイルの内容とマージされます。

すべてのファイルを解決するための制限時間は30秒です。

**Keyword type**（キーワードのタイプ）: グローバルキーワード。

**Supported values**（サポートされている値）: `include`サブキー:

- [`include:component`](#includecomponent)
- [`include:local`](#includelocal)
- [`include:project`](#includeproject)
- [`include:remote`](#includeremote)
- [`include:template`](#includetemplate)

オプションで使用可能:

- [`include:inputs`](#includeinputs)
- [`include:rules`](#includerules)
- [`include:integrity`](#includeintegrity)

**Additional details**（補足情報）:

- `include`キーワードでは[特定のCI/CD変数](includes.md#use-variables-with-include)のみを使用できます。
- マージを使用して、インクルードされるCI/CD設定をローカルでカスタマイズおよびオーバーライドできます。
- インクルードされる設定をオーバーライドするには、`.gitlab-ci.yml`ファイルに同じジョブ名またはグローバルキーワードを指定します。2つの設定がマージされ、インクルードされる設定よりも`.gitlab-ci.yml`ファイル内の設定が優先されます。
- 再実行する場合:
  - ジョブを再実行すると、`include`ファイルは再度フェッチされません。パイプラインのすべてのジョブは、パイプラインの作成時にフェッチされた設定を使用します。そのため、ソース`include`ファイルが変更されても、ジョブの再実行には影響しません。
  - パイプラインを再実行すると、`include`ファイルが再度フェッチされます。前回のパイプライン実行後にこれらのファイルが変更されていた場合、新しいパイプラインは変更された設定を使用します。
- デフォルトでは、[ネストされたインクルード](includes.md#use-nested-includes)を含めて、パイプラインごとに最大150個のインクルードを使用できます。補足情報を以下に示します:
  - [GitLab 16.0以降](https://gitlab.com/gitlab-org/gitlab/-/issues/207270) 、GitLab Self-Managedのユーザーは、[最大インクルード数](../../administration/settings/continuous_integration.md#set-maximum-includes)の値を変更できるようになりました。
  - [GitLab 15.10以降](https://gitlab.com/gitlab-org/gitlab/-/issues/367150)、最大150個のインクルードを設定できます。ネストされたインクルードでは、同じファイルを複数回インクルードできますが、重複したインクルードもカウントの対象になります。
  - [GitLab 14.9からGitLab 15.9](https://gitlab.com/gitlab-org/gitlab/-/issues/28987)では、最大100個のインクルードを使用できます。ネストされたインクルードでは同じファイルを複数回インクルードできますが、重複は無視されます。

---

#### `include:component` {#includecomponent}

`include:component`を使用して、[CI/CDコンポーネント](../components/_index.md)をパイプライン設定に追加します。

**Keyword type**（キーワードのタイプ）: グローバルキーワード。

**Supported values**（サポートされている値）: CI/CDコンポーネントの完全なアドレス（形式: `<fully-qualified-domain-name>/<project-path>/<component-name>@<specific-version>`）。

**Example of `include:component`**（の例）:

```yaml
include:
  - component: $CI_SERVER_FQDN/my-org/security-components/secret-detection@1.0
```

**Related topics**（関連トピック）:

- [CI/CDコンポーネントを使用する](../components/_index.md#use-a-component)。

---

#### `include:local` {#includelocal}

`include:local`を使用して、`include`キーワードを含む設定ファイルと同じリポジトリおよびブランチにあるファイルをインクルードします。シンボリックリンクの代わりに`include:local`を使用します。

**Keyword type**（キーワードのタイプ）: グローバルキーワード。

**Supported values**（サポートされている値）: 

ルートディレクトリ（`/`）を基準にしたフルパス:

- YAMLファイルの拡張子は、`.yml`または`.yaml`である必要があります。
- [ファイルパスではワイルドカード`*`と`**`を使用](includes.md#use-includelocal-with-wildcard-file-paths)できます。
- [特定のCI/CD変数](includes.md#use-variables-with-include)を使用できます。

**Example of `include:local`**（の例）:

```yaml
include:
  - local: '/templates/.gitlab-ci-template.yml'
```

短縮構文を使用してパスを定義することもできます:

```yaml
include: '.gitlab-ci-production.yml'
```

**Additional details**（補足情報）:

- `.gitlab-ci.yml`ファイルとローカルファイルは、同じブランチに存在している必要があります。
- Gitサブモジュールパスを使用してローカルファイルをインクルードすることはできません。
- `include`設定は常に、パイプラインを実行しているプロジェクトではなく、`include`キーワードを含むファイルの場所を基準に評価されます。そのため、[ネストされた`include`](includes.md#use-nested-includes)が別のプロジェクトの設定ファイル内にある場合、`include: local`はその別のプロジェクト内でファイルを確認します。

---

#### `include:project` {#includeproject}

同じGitLabインスタンス上の別の非公開プロジェクトからファイルをインクルードするには、`include:project`と`include:file`を使用します。

**Keyword type**（キーワードのタイプ）: グローバルキーワード。

**Supported values**（サポートされている値）: 

- `include:project`: GitLabプロジェクトのフルパス。
- `include:file`: ルートディレクトリ（`/`）を基準にしたファイルのフルパス、またはファイルパスの配列。YAMLファイルの拡張子は`.yml`または`.yaml`でなければなりません。
- `include:ref`: オプション。ファイルの取得元のref。指定しない場合、デフォルトはプロジェクトの`HEAD`です。
- [特定のCI/CD変数](includes.md#use-variables-with-include)を使用できます。

**Example of `include:project`**（の例）:

```yaml
include:
  - project: 'my-group/my-project'
    file: '/templates/.gitlab-ci-template.yml'
  - project: 'my-group/my-subgroup/my-project-2'
    file:
      - '/templates/.builds.yml'
      - '/templates/.tests.yml'
```

`ref`を指定することもできます:

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

**Additional details**（補足情報）:

- `include`設定は常に、パイプラインを実行しているプロジェクトではなく、`include`キーワードを含むファイルの場所を基準に評価されます。そのため、[ネストされた`include`](includes.md#use-nested-includes)が別のプロジェクトの設定ファイル内にある場合、`include: local`はその別のプロジェクト内でファイルを確認します。
- パイプラインが開始されると、すべての方法によってインクルードされた`.gitlab-ci.yml`ファイルの設定が評価されます。この設定はその時点でのスナップショットであり、データベースに保持されます。GitLabは、参照先の`.gitlab-ci.yml`ファイルの設定が変更されても、次のパイプラインが開始されるまではその変更を反映しません。
- 別の非公開プロジェクトのYAMLファイルをインクルードする場合、パイプラインを実行するユーザーは両方のプロジェクトのメンバーであり、パイプラインを実行するための適切な権限を持っている必要があります。ユーザーがインクルード対象のファイルにアクセスできない場合、`not found or access denied`エラーが表示されることがあります。
- 別のプロジェクトのCI/CD設定ファイルをインクルードする場合は注意してください。CI/CD設定ファイルが変更されても、パイプラインや通知はトリガーされません。セキュリティの観点では、これはサードパーティの依存関係をプルすることと似ています。`ref`については以下を検討してください:
  - 特定のSHAハッシュを使用する。これはもっとも安定したオプションです。目的のコミットが確実に参照されるように、40文字の完全なSHAハッシュを使用してください。`ref`に短いSHAハッシュを使用すると、あいまいになる可能性があるためです。
  - 他のプロジェクトの`ref`に対して、[保護ブランチ](../../user/project/repository/branches/protected.md)と[保護タグ](../../user/project/protected_tags.md#prevent-tag-creation-with-the-same-name-as-branches)の両方のルールを適用する。保護タグと保護ブランチは、変更される前に変更管理を通過する可能性が高くなります。

---

#### `include:remote` {#includeremote}

`include:remote`と完全なURLを使用して、別の場所にあるファイルをインクルードします。

**Keyword type**（キーワードのタイプ）: グローバルキーワード。

**Supported values**（サポートされている値）: 

HTTP/HTTPS `GET`リクエストでアクセス可能な公開URL:

- リモートURLの認証はサポートされていません。
- YAMLファイルの拡張子は、`.yml`または`.yaml`である必要があります。
- [特定のCI/CD変数](includes.md#use-variables-with-include)を使用できます。

**Example of `include:remote`**（の例）:

```yaml
include:
  - remote: 'https://gitlab.com/example-project/-/raw/main/.gitlab-ci.yml'
```

**Additional details**（補足情報）:

- すべての[ネストされたインクルード](includes.md#use-nested-includes)は、公開ユーザーとしてコンテキストなしで実行されるため、公開プロジェクトまたはテンプレートのみをインクルードできます。ネストされたインクルードの`include`セクションでは、変数は使用できません。
- 別のプロジェクトのCI/CD設定ファイルをインクルードする場合は注意してください。他のプロジェクトのファイルが変更されても、パイプラインや通知はトリガーされません。セキュリティの観点では、これはサードパーティの依存関係をプルすることと似ています。インクルードするファイルの整合性を検証するには、[`integrity`キーワード](#includeintegrity)を使用することを検討してください。所有している別のGitLabプロジェクトにリンクする場合は、[保護ブランチ](../../user/project/repository/branches/protected.md)と[保護タグ](../../user/project/protected_tags.md#prevent-tag-creation-with-the-same-name-as-branches)の両方を使用して変更管理ルールを適用することを検討してください。

---

#### `include:template` {#includetemplate}

`include:template`を使用して、[`.gitlab-ci.yml`テンプレート](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)をインクルードします。

**Keyword type**（キーワードのタイプ）: グローバルキーワード。

**Supported values**（サポートされている値）: 

[CI/CDテンプレート](../examples/_index.md#cicd-templates):

- すべてのテンプレートは、[`lib/gitlab/ci/templates`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)で確認できます。すべてのテンプレートが`include:template`での使用を前提として設計されているわけではないため、使用する前にテンプレートのコメントを確認してください。
- [特定のCI/CD変数](includes.md#use-variables-with-include)を使用できます。

**Example of `include:template`**（の例）:

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

**Additional details**（補足情報）:

- すべての[ネストされたインクルード](includes.md#use-nested-includes)は、公開ユーザーとしてコンテキストなしで実行されるため、公開プロジェクトまたはテンプレートのみをインクルードできます。ネストされたインクルードの`include`セクションでは、変数は使用できません。

---

#### `include:inputs` {#includeinputs}

{{< history >}}

- GitLab 15.11でベータ機能として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/391331)されました。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062)になりました。

{{< /history >}}

インクルードされる設定が[`spec:inputs`](#specinputs)を使用している場合、この設定をパイプラインに追加する際のインプットパラメータの値を設定するには、`include:inputs`を使用します。

**Keyword type**（キーワードのタイプ）: グローバルキーワード。

**Supported values**（サポートされている値）: 文字列、数値、またはブール値。

**Example of `include:inputs`**（の例）:

```yaml
include:
  - local: 'custom_configuration.yml'
    inputs:
      website: "My website"
```

この例では:

- `custom_configuration.yml`に含まれる設定がパイプラインに追加され、インクルードされる設定の`website`インプットには`My website`という値が設定されます。

**Additional details**（補足情報）:

- インクルードされる設定ファイルが[`spec:inputs:type`](#specinputstype)を使用している場合、インプット値は定義された型と一致している必要があります。
- インクルードされる設定ファイルが[`spec:inputs:options`](#specinputsoptions)を使用している場合、インプット値はリストされているオプションのいずれかと一致している必要があります。

**Related topics**（関連トピック）:

- [`include`の使用時にインプット値を設定する](../inputs/_index.md#for-configuration-added-with-include)。

---

#### `include:rules` {#includerules}

[`rules`](#rules)と`include`を組み合わせて使用すると、他の設定ファイルを条件付きでインクルードできます。

**Keyword type**（キーワードのタイプ）: グローバルキーワード。

**Supported values**（サポートされている値）: 次の`rules`サブキー:

- [`rules:if`](#rulesif)。
- [`rules:exists`](#rulesexists)。
- [`rules:changes`](#ruleschanges)。

一部の[CI/CD変数がサポートされています](includes.md#use-variables-with-include)。

**Example of `include:rules`**（の例）:

```yaml
include:
  - local: build_jobs.yml
    rules:
      - if: $INCLUDE_BUILDS == "true"

test-job:
  stage: test
  script: echo "This is a test job"
```

この例では、`INCLUDE_BUILDS`変数の値に応じて次のようになります:

- `true`の場合、`build_jobs.yml`の設定がパイプラインにインクルードされます。
- `true`ではない場合、または変数が存在しない場合は、`build_jobs.yml`の設定はパイプラインにインクルードされません。

**Related topics**（関連トピック）:

- `include`を使用した例:
  - [`rules:if`](includes.md#include-with-rulesif)。
  - [`rules:changes`](includes.md#include-with-ruleschanges)。
  - [`rules:exists`](includes.md#include-with-rulesexists)。

---

#### `include:integrity` {#includeintegrity}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/178593)されました。

{{< /history >}}

`integrity`を`include:remote`と組み合わせて使用して、インクルードされるリモートファイルのSHA256ハッシュを指定します。`integrity`の値が実際の内容と一致しない場合、そのリモートファイルは処理されず、パイプラインは失敗します。

**Keyword type**（キーワードのタイプ）: グローバルキーワード。

**Supported values**（サポートされている値）: インクルードされるコンテンツのBase64エンコードされたSHA256ハッシュ。

**Example of `include:integrity`**（の例）:

```yaml
include:
  - remote: 'https://gitlab.com/example-project/-/raw/main/.gitlab-ci.yml'
    integrity: 'sha256-L3/GAoKaw0Arw6hDCKeKQlV1QPEgHYxGBHsH4zG1IY8='
```

---

### `stages` {#stages}

{{< history >}}

- 文字列のネストされた配列のサポートは、GitLab 16.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/439451)されました。

{{< /history >}}

`stages`を使用して、ジョブのグループを含むステージを定義します。ジョブに[`stage`](#stage)を指定することで、そのジョブを特定のステージで実行するように設定できます。

`.gitlab-ci.yml`ファイルで`stages`が定義されていない場合、デフォルトのパイプラインステージは次のとおりです:

- [`.pre`](#stage-pre)
- `build`
- `test`
- `deploy`
- [`.post`](#stage-post)

`stages`に列挙された項目の順序によって、ジョブの実行順序が決まります:

- 同じステージ内のジョブは並列実行されます。
- 次のステージのジョブは、前のステージのジョブが正常に完了した後に実行されます。

パイプラインに`.pre`ステージまたは`.post`ステージのジョブしか含まれていない場合、そのパイプラインは実行されません。これら以外のステージに少なくとも1つのジョブが必要です。

**Keyword type**（キーワードのタイプ）: グローバルキーワード。

**Example of `stages`**（の例）:

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

**Additional details**（補足情報）:

- ジョブに[`stage`](#stage)が指定されていない場合、そのジョブには`test`ステージが割り当てられます。
- ステージが定義されていても、そのステージを使用するジョブが存在しない場合、パイプラインには表示されません。これは、[コンプライアンスパイプライン設定](../../user/compliance/compliance_pipelines.md)に役立ちます:
  - ステージはコンプライアンス設定で定義できますが、使用されなければ非表示のままになります。
  - 定義されたステージをデベロッパーがジョブ定義で使用すると、これらのステージが表示されます。

**Related topics**（関連トピック）:

- ジョブをより早い時点で開始し、ステージの順序を無視するには、[`needs`キーワード](#needs)を使用する。

---

### `workflow` {#workflow}

[`workflow`](workflow.md)を使用して、パイプラインの動作を制御します。

`workflow`の設定では、一部の[定義済みCI/CD変数](../variables/predefined_variables.md)を使用できますが、ジョブの開始時にのみ定義される変数は使用できません。

**Related topics**（関連トピック）:

- [`workflow: rules`の例](workflow.md#workflow-rules-examples)
- [ブランチパイプラインとマージリクエストパイプラインを切り替える](workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines)

---

#### `workflow:auto_cancel:on_new_commit` {#workflowauto_cancelon_new_commit}

{{< history >}}

- GitLab 16.8で`ci_workflow_auto_cancel_on_new_commit`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/412473)されました。デフォルトでは無効になっています。
- GitLab 16.9の[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/434676)になりました。
- GitLab 16.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/434676)になりました。機能フラグ`ci_workflow_auto_cancel_on_new_commit`は削除されました。

{{< /history >}}

`workflow:auto_cancel:on_new_commit`を使用して、[冗長なパイプラインを自動キャンセル](../pipelines/settings.md#auto-cancel-redundant-pipelines)機能の動作を設定します。

**Supported values**（サポートされている値）: 

- `conservative`: パイプラインをキャンセルします。ただし、`interruptible: false`が設定されたジョブがまだ開始されていない場合に限ります。定義されていない場合は、この値がデフォルトです。
- `interruptible`: `interruptible: true`が設定されたジョブのみをキャンセルします。
- `none`: ジョブは自動キャンセルされません。

**Example of `workflow:auto_cancel:on_new_commit`**（の例）:

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

---

#### `workflow:auto_cancel:on_job_failure` {#workflowauto_cancelon_job_failure}

{{< history >}}

- GitLab 16.10で`auto_cancel_pipeline_on_job_failure`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/23605)されました。デフォルトでは無効になっています。
- GitLab 16.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/433163)になりました。機能フラグ`auto_cancel_pipeline_on_job_failure`は削除されました。

{{< /history >}}

`workflow:auto_cancel:on_job_failure`を使用して、いずれかのジョブが失敗した場合にキャンセルするジョブを設定します。

**Supported values**（サポートされている値）: 

- `all`: いずれかのジョブが失敗すると、パイプラインと実行中のすべてのジョブが直ちにキャンセルされます。
- `none`: ジョブは自動キャンセルされません。

**Example of `workflow:auto_cancel:on_job_failure`**（の例）:

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

**Related topics**（関連トピック）:

- [ダウンストリームパイプラインから親パイプラインを自動キャンセルする](../pipelines/downstream_pipelines.md#auto-cancel-the-parent-pipeline-from-a-downstream-pipeline)

---

#### `workflow:name` {#workflowname}

{{< history >}}

- GitLab 15.5で`pipeline_name`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/372538)されました。デフォルトでは無効になっています。
- GitLab 15.7の[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/376095)になりました。
- GitLab 15.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/376095)になりました。機能フラグ`pipeline_name`は削除されました。

{{< /history >}}

`workflow:`で`name`を使用して、パイプラインの名前を定義できます。

定義された名前はすべてのパイプラインに割り当てられます。名前の先頭または末尾のスペースは削除されます。

**Supported values**（サポートされている値）: 

- 文字列。
- [CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。
- 両方の組み合わせ。

**Examples of `workflow:name`**（の例）:

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

**Additional details**（補足情報）:

- 名前が空の文字列の場合、パイプラインには名前が割り当てられません。CI/CD変数のみで構成された名前は、それらの変数もすべて空の場合、空の文字列と評価される可能性があります。
- `workflow:rules:variables`で定義された変数は、すべてのジョブで使用できる[デフォルト変数](#default-variables)になります。これには、デフォルトで変数をダウンストリームパイプラインに転送する[`trigger`](#trigger)ジョブも含まれます。ダウンストリームパイプラインが同じ変数を使用する場合、アップストリーム変数の値によって[変数が上書きされます](../variables/_index.md#cicd-variable-precedence)。そのため、次のいずれかを必ず実施してください:
  - 各プロジェクトのパイプライン設定で一意の変数名を使用する（例: `PROJECT1_PIPELINE_NAME`）。
  - トリガージョブで[`inherit:variables`](#inheritvariables)を使用し、ダウンストリームパイプラインに転送する正確な変数をリストする。

---

#### `workflow:rules` {#workflowrules}

`workflow`における`rules`キーワードは、[ジョブで定義される`rules`](#rules)に似ていますが、パイプライン全体を作成するかどうかを制御します。

trueと評価されるルールがない場合、パイプラインは実行されません。

**Supported values**（サポートされている値）: ジョブレベルの[`rules`](#rules)と同じキーワードの一部を使用できます:

- [`rules: if`](#rulesif)。
- [`rules: changes`](#ruleschanges)。
- [`rules: exists`](#rulesexists)。
- [`when`](#when)。`workflow`とともに使用する場合は`always`または`never`のみ指定できます。
- [`variables`](#workflowrulesvariables)。

**Example of `workflow:rules`**（の例）:

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_TITLE =~ /-draft$/
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

この例では、パイプラインが実行されるのは、コミットタイトル（コミットメッセージの1行目）が`-draft`で終わっておらず、パイプラインが次のいずれかに該当する場合です:

- マージリクエスト。
- デフォルトブランチ。

**Additional details**（補足情報）:

- ルールがブランチパイプライン（デフォルトブランチ以外）とマージリクエストパイプラインの両方に一致する場合、[パイプラインが重複](../jobs/job_rules.md#avoid-duplicate-pipelines)して作成される可能性があります。
- `start_in`、`allow_failure`、`needs`は、`workflow:rules`でサポートされていませんが、構文違反にはなりません。効果はありませんが、将来的に構文エラーを引き起こす可能性があるため、`workflow:rules`では使用しないでください。詳細については、[イシュー436473](https://gitlab.com/gitlab-org/gitlab/-/issues/436473)を参照してください。

**Related topics**（関連トピック）:

- [`workflow:rules`の一般的な`if`句](workflow.md#common-if-clauses-for-workflowrules)。
- [`rules`を使用してマージリクエストパイプラインを実行する](../pipelines/merge_request_pipelines.md#add-jobs-to-merge-request-pipelines)。

---

#### `workflow:rules:variables` {#workflowrulesvariables}

`workflow:rules`で[`variables`](#variables)を使用して、特定のパイプライン条件の変数を定義します。

条件が一致すると変数が作成されます。この変数は、パイプライン内のすべてのジョブで使用できます。すでにその変数がデフォルト変数としてトップレベルで定義されている場合でも、`workflow`変数が優先され、デフォルト変数はオーバーライドされます。

**Keyword type**（キーワードのタイプ）: グローバルキーワード。

**Supported values**（サポートされている値）: 変数名と値のペア:

- 名前には数字、英字、アンダースコア（`_`）のみを使用できます。
- 値は文字列でなければなりません。

**Example of `workflow:rules:variables`**（の例）:

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

**Additional details**（補足情報）:

- `workflow:rules:variables`で定義された変数は、すべてのジョブで使用できる[デフォルト変数](#variables)になります。これには、デフォルトで変数をダウンストリームパイプラインに転送する[`trigger`](#trigger)ジョブも含まれます。ダウンストリームパイプラインが同じ変数を使用する場合、アップストリーム変数の値によって[変数が上書きされます](../variables/_index.md#cicd-variable-precedence)。そのため、次のいずれかを必ず実施してください:
  - 各プロジェクトのパイプライン設定で一意の変数名を使用する（例: `PROJECT1_VARIABLE_NAME`）。
  - トリガージョブで[`inherit:variables`](#inheritvariables)を使用し、ダウンストリームパイプラインに転送する正確な変数をリストする。

---

#### `workflow:rules:auto_cancel` {#workflowrulesauto_cancel}

{{< history >}}

- GitLab 16.8で`ci_workflow_auto_cancel_on_new_commit`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/436467)されました。デフォルトでは無効になっています。
- GitLab 16.9の[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/434676)になりました。
- GitLab 16.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/434676)になりました。機能フラグ`ci_workflow_auto_cancel_on_new_commit`は削除されました。
- `workflow:rules`の`on_job_failure`オプションは、GitLab 16.10で`auto_cancel_pipeline_on_job_failure`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/23605)されました。デフォルトでは無効になっています。
- `workflow:rules`の`on_job_failure`オプションは、GitLab 16.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/433163)になりました。機能フラグ`auto_cancel_pipeline_on_job_failure`は削除されました。

{{< /history >}}

`workflow:rules:auto_cancel`を使用して、[`workflow:auto_cancel:on_new_commit`](#workflowauto_cancelon_new_commit)機能または[`workflow:auto_cancel:on_job_failure`](#workflowauto_cancelon_job_failure)機能の動作を設定します。

**Supported values**（サポートされている値）: 

- `on_new_commit`: [`workflow:auto_cancel:on_new_commit`](#workflowauto_cancelon_new_commit)
- `on_job_failure`: [`workflow:auto_cancel:on_job_failure`](#workflowauto_cancelon_job_failure)

**Example of `workflow:rules:auto_cancel`**（の例）:

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

この例では、デフォルトですべてのジョブの[`workflow:auto_cancel:on_new_commit`](#workflowauto_cancelon_new_commit)が`interruptible`に設定され、[`workflow:auto_cancel:on_job_failure`](#workflowauto_cancelon_job_failure)が`all`に設定されます。ただし、保護ブランチに対してパイプラインが実行される場合、ルールはデフォルトを`on_new_commit: none`と`on_job_failure: none`でオーバーライドします。たとえば、パイプラインの実行対象によって、動作は次のように変わります:

- 保護されていないブランチに対して実行される場合、新しいコミットがプッシュされると、`test-job1`の実行が継続され、`test-job2`はキャンセルされます。
- 保護ブランチに対して実行される場合、新しいコミットがプッシュされると、`test-job1`と`test-job2`の両方の実行が継続されます。

---

## ヘッダーキーワード {#header-keywords}

いくつかのキーワードは、YAML設定ファイルのヘッダーセクションで定義する必要があります。ヘッダーはファイルの先頭に配置し、設定の他の部分と`---`で区切る必要があります。

---

### `spec` {#spec}

{{< history >}}

- GitLab 15.11でベータ機能として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/391331)されました。

{{< /history >}}

YAMLファイルのヘッダーに`spec`セクションを追加すると、`include`キーワードを使用して設定がパイプラインに追加されたときのパイプラインの動作を設定できます。

仕様は設定ファイルの先頭にあるヘッダーセクションで宣言する必要があります。このセクションは、設定の他の部分と`---`で区切られています。

---

#### `spec:inputs` {#specinputs}

`spec:inputs`を使用して、CI/CD設定に対する[インプット](../inputs/_index.md)を定義できます。

ヘッダーセクションの外部でその値を参照するには、補間形式`$[[ inputs.input-id ]]`を使用します。インプットは、パイプラインの作成時に設定がフェッチされるときに評価および補間されます。`inputs`を使用すると、設定が`.gitlab-ci.yml`ファイルの内容とマージされる前に補間が完了します。

**Keyword type**（キーワードのタイプ）: ヘッダーキーワード。`spec`は、設定ファイルの先頭にあるヘッダーセクションで宣言する必要があります。

**Supported values**（サポートされている値）: 予期されるインプットを表す文字列のハッシュ。

**Example of `spec:inputs`**（の例）:

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

**Additional details**（補足情報）:

- [`spec:inputs:default`](#specinputsdefault)を使用してデフォルト値を設定しない限り、インプットは必須です。[`include:inputs`](#includeinputs)と組み合わせてインプットを使用する場合を除き、インプットを必須にするのは避けることをおすすめします。
- インプットは文字列を想定しています。ただし、[`spec:inputs:type`](#specinputstype)を使用して別の型を指定する場合を除きます。
- 補間ブロックを含む文字列は、1 MB以下にする必要があります。
- 補間ブロック内の文字列は、1 KB以下にする必要があります。
- インプット値は[新しいパイプラインの実行時](../inputs/_index.md#for-a-pipeline)に定義できます。

**Related topics**（関連トピック）:

- [`spec:inputs`でインプットパラメータを定義する](../inputs/_index.md#define-input-parameters-with-specinputs)。

---

##### `spec:inputs:default` {#specinputsdefault}

{{< history >}}

- GitLab 15.11でベータ機能として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/391331)されました。

{{< /history >}}

`spec:inputs:default`を使用してデフォルト値を設定しない限り、仕様に含まれるインプットはすべて必須になります。

デフォルト値を設定しない場合は`default: ''`を使用します。

**Keyword type**（キーワードのタイプ）: ヘッダーキーワード。`spec`は、設定ファイルの先頭にあるヘッダーセクションで宣言する必要があります。

**Supported values**（サポートされている値）: デフォルト値を表す文字列、または`''`。

**Example of `spec:inputs:default`**（の例）:

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

**Additional details**（補足情報）:

- インプットが次の条件に該当する場合、パイプラインは検証エラーで失敗します:
  - `default`と[`options`](#specinputsoptions)の両方を使用しているが、デフォルト値が、リストされているオプションのいずれでもない。
  - `default`と`regex`の両方を使用しているが、デフォルト値が正規表現と一致しない。
  - 値が[`type`](#specinputstype)と一致しない。

---

##### `spec:inputs:description` {#specinputsdescription}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/415637)されました。

{{< /history >}}

`description`を使用して、特定のインプットに説明を付けます。説明はインプットの動作に影響を与えません。ファイルのユーザーがインプットを理解できるようにする目的でのみ使用されます。

**Keyword type**（キーワードのタイプ）: ヘッダーキーワード。`spec`は、設定ファイルの先頭にあるヘッダーセクションで宣言する必要があります。

**Supported values**（サポートされている値）: 説明を表す文字列。

**Example of `spec:inputs:description`**（の例）:

```yaml
spec:
  inputs:
    flags:
      description: 'Sample description of the `flags` input details.'
title: The pipeline configuration would follow...
---
```

---

##### `spec:inputs:options` {#specinputsoptions}

{{< history >}}

- GitLab 16.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/393401)されました。

{{< /history >}}

インプットで`options`を使用して、インプットに許可される値のリストを指定できます。各インプットに指定できるオプションの数は、最大50個までです。

**Keyword type**（キーワードのタイプ）: ヘッダーキーワード。`spec`は、設定ファイルの先頭にあるヘッダーセクションで宣言する必要があります。

**Supported values**（サポートされている値）: インプットオプションの配列。

**Example of `spec:inputs:options`**（の例）:

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

**Additional details**（補足情報）:

- 次の場合、パイプラインは検証エラーで失敗します:
  - インプットで`options`と[`default`](#specinputsdefault)の両方を使用しているが、デフォルト値が、リストされているオプションのいずれでもない。
  - いずれかのインプットオプションが[`type`](#specinputstype)と一致していない。`options`を使用する場合は`string`または`number`を指定する必要があり、`boolean`は使用できない。

---

##### `spec:inputs:regex` {#specinputsregex}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/410836)されました。

{{< /history >}}

`spec:inputs:regex`を使用して、インプットが一致する必要がある正規表現を指定します。

**Keyword type**（キーワードのタイプ）: ヘッダーキーワード。`spec`は、設定ファイルの先頭にあるヘッダーセクションで宣言する必要があります。

**Supported values**（サポートされている値）: 正規表現である必要があります。

**Example of `spec:inputs:regex`**（の例）:

```yaml
spec:
  inputs:
    version:
      regex: ^v\d\.\d+(\.\d+)?$
title: The pipeline configuration would follow...
---
```

この例では、`v1.0`または`v1.2.3`のインプットは正規表現に一致し、検証に合格します。`v1.A.B`のインプットは正規表現と一致せず、検証に失敗します。

**Additional details**（補足情報）:

- `inputs:regex`は、[`type`](#specinputstype)が`string`の場合にのみ使用できます。`number`または`boolean`の場合は使用できません。
- `/`文字で正規表現を囲まないでください。たとえば、`/regex.*/`ではなく`regex.*`を使用します。
- `inputs:regex`は[RE2](https://github.com/google/re2/wiki/Syntax)を使用して正規表現を解析します。
- 正規表現に対する入力の検証は、変数の展開前に行われます。入力テキストに変数名が含まれている場合、変数の値ではなく、入力のraw値（変数名）が検証されます。

---

##### `spec:inputs:type` {#specinputstype}

デフォルトでは、インプットは文字列を想定しています。`spec:inputs:type`を使用すると、インプットに必要な別の型を指定できます。

**Keyword type**（キーワードのタイプ）: ヘッダーキーワード。`spec`は、設定ファイルの先頭にあるヘッダーセクションで宣言する必要があります。

**Supported values**（サポートされている値）: 次のいずれかです:

- `array`: インプットの[配列](../inputs/_index.md#array-type)を受け入れます。
- `string`: 文字列のインプットを受け入れます（定義されていない場合のデフォルト）。
- `number`: 数値のインプットのみを受け入れます。
- `boolean`: `true`または`false`のインプットのみを受け入れます。

**Example of `spec:inputs:type`**（の例）:

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

---

##### `spec:component` {#speccomponent}

{{< history >}}

- GitLab 18.6で`ci_component_context_interpolation`という名前の[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438275)されました。デフォルトでは無効になっています。

{{< /history >}}

`spec:component`を使用して、[CI/CDコンポーネント](../components/_index.md)で補間に使用できるコンポーネントのコンテキストデータを定義します。

コンポーネントコンテキストは、コンポーネント自体のメタデータ（名前、バージョン、コミットハッシュなど）を提供します。これにより、コンポーネントテンプレートは、自身のメタデータを動的に参照できます。

補間形式`$[[ component.field-name ]]`を使用して、コンポーネントテンプレートのコンポーネントコンテキスト値を参照します。

**Keyword type**（キーワードのタイプ）: ヘッダーキーワード。`spec`は、設定ファイルの先頭にあるヘッダーセクションで宣言する必要があります。

**Supported values**（サポートされている値）: 文字列の配列。各文字列は、次のいずれかである必要があります:

- `name`: コンポーネントパスで指定されているコンポーネント名。
- `sha`: コンポーネントのコミットハッシュ。
- `version`: カタログリソースから解決されたセマンティックバージョン。次の場合、`null`を返します:
  - コンポーネントがカタログリソースではありません。
  - 参照が（リリースされたバージョンではなく）ブランチ名またはコミットハッシュです。
- `reference`: コンポーネントパスの`@`の後に指定された元の参照。たとえば、`1.0`、`~latest`、ブランチ名、またはコミットハッシュ。

**Example of `spec:component`**（の例）:

```yaml
spec:
  component: [name, version, reference]
  inputs:
    image_tag:
      default: latest
---

build-image:
  image: registry.example.com/$[[ component.name ]]:$[[ component.version ]]
  script:
    - echo "Building with component version $[[ component.version ]]"
    - echo "Component reference: $[[ component.reference ]]"
```

**Additional details**（補足情報）:

- `version`フィールドは、次を使用すると、実際のセマンティックバージョンに解決されます:
  - `@1.0.0`のような完全なバージョン（`1.0.0`を返します）
  - `@1.0`のような部分的なバージョン（最新の一致するバージョン（たとえば、`1.0.2`）を返します）
  - `@~latest` （最新バージョンを返します）
- `reference`フィールドは、`@`の後に指定された正確な値を常に返します:
  - `@1.0`は`1.0`を返します（`version`が`1.0.2`を返す場合があります）
  - `@~latest`は`~latest`を返します（`version`は実際のバージョン番号を返します）
  - `@abc123`は`abc123`を返します（`version`は`null`を返します）

**Related topics**（関連トピック）:

- [コンポーネントでコンポーネントコンテキストを使用します](../components/_index.md#use-component-context-in-components)。

---

## ジョブキーワード {#job-keywords}

以降のトピックでは、キーワードを使用してCI/CDパイプラインを設定する方法について説明します。

---

### `after_script` {#after_script}

{{< history >}}

- キャンセルされたジョブに対する`after_script`コマンドの実行は、GitLab 17.0で[導入](https://gitlab.com/groups/gitlab-org/-/epics/10158)されました。

{{< /history >}}

`after_script`を使用して、ジョブの`before_script`セクションと`script`セクションの完了後に最後に実行するコマンドの配列を定義します。`after_script`のコマンドは、次の条件に該当する場合にも実行されます:

- `before_script`セクションまたは`script`セクションの実行中に、ジョブがキャンセルされた場合。
- ジョブで`script_failure`という種類の失敗が発生した場合（ただし、[それ以外の種類の失敗](#retrywhen)では実行されません）。

ジョブの設定とデフォルトの設定は、一緒にマージされません。パイプラインに[`default:after_script`](#default)が定義されていて、ジョブにも`after_script`がある場合、ジョブの設定が優先され、デフォルトの設定は使用されません。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 次の内容を含む配列:

- 1行のコマンド。
- [複数行に分割された](script.md#split-long-commands)長いコマンド。
- [YAMLアンカー](yaml_optimization.md#yaml-anchors-for-scripts)。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**Example of `after_script`**（の例）:

```yaml
job:
  script:
    - echo "An example script section."
  after_script:
    - echo "Execute this command after the `script` section completes."
```

**Additional details**（補足情報）:

`after_script`で指定するスクリプトは、`before_script`コマンドまたは`script`コマンドとは別のShellで実行されます。その結果、スクリプトは次のようになります:

- 現在のワーキングディレクトリがデフォルトにリセットされます（デフォルト値は、[RunnerがGitリクエストをどのように処理するかを定義する変数](../runners/configure_runners.md#configure-runner-behavior-with-variables)に基づいて決まります）。
- `before_script`または`script`で定義されたコマンドによる変更にはアクセスできません。これには以下が含まれます:
  - `script`スクリプトでエクスポートされたコマンドエイリアスと変数。
  - ワークツリー外の変更（Runnerのexecutorによってアクセス可否が異なります）。たとえば、`before_script`または`script`スクリプトによってインストールされたソフトウェアなどが該当します。
- 個別のタイムアウトが設定されます。GitLab Runner 16.4以降では、デフォルトは5分で、[`RUNNER_AFTER_SCRIPT_TIMEOUT`](../runners/configure_runners.md#set-script-and-after_script-timeouts)変数で設定できます。GitLab 16.3以前では、タイムアウトは5分にハードコードされています。
- ジョブの終了コードには影響しません。`script`セクションが成功し、`after_script`がタイムアウトになるか失敗した場合、ジョブはコード`0`（`Job Succeeded`）で終了します。
- `after_script`で[CI/CDジョブトークン](../jobs/ci_job_token.md)を使用する場合の既知の問題があります。`after_script`コマンドでの認証にジョブトークンを使用することはできますが、ジョブがキャンセルされるとそのトークンは直ちに無効になります。詳細については、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/473376)を参照してください。
- ジョブがタイムアウトした場合:
  - `after_script`コマンドはデフォルトでは実行されません。
  - [タイムアウト値を設定](../runners/configure_runners.md#ensuring-after_script-execution)することで、`after_script`を確実に実行させることができます。そのためには、ジョブのタイムアウトを超えないように、`RUNNER_SCRIPT_TIMEOUT`と`RUNNER_AFTER_SCRIPT_TIMEOUT`に適切な値を設定します。
- `after_script`を`default`セクションではなくトップレベルで使用することは、[非推奨](deprecated_keywords.md#globally-defined-image-services-cache-before_script-after_script)です。

**Execution timing and file inclusion**（実行タイミングとファイルの包含）:

`after_script`コマンドは、キャッシュとアーティファクトのアップロード操作の前に実行されます。

- アーティファクトの収集を設定した場合:
  - `after_script`で作成または変更されたファイルは、アーティファクトに含まれます。
  - `after_script`で行われた変更は、キャッシュのアップロードに含まれます。
- `after_script`が指定されたキャッシュまたはアーティファクトパスに作成または変更するファイルはすべてキャプチャされ、アップロードされます。このタイミングは、次のようなシナリオで使用できます:
  - メインスクリプトの後に、テストレポートまたはカバレッジデータを生成します。
  - サマリーファイルまたはログを作成します。
  - ビルド出力の後処理。

次の例では、含まれないファイルは、アーティファクトまたはキャッシュのアップロードステージの後に作成または変更されたファイルのみです:

```yaml
job:
  script:
    - echo "main" > output.txt
    - build_something

  after_script:
    - echo "modified in after_script" >> output.txt  # This WILL be in the artifact
    - generate_test_report > report.html            # This WILL be in the artifact

  artifacts:
    paths:
      - output.txt
      - report.html

  cache:
    paths:
      - output.txt  # Will include the "modified in after_script" line
```

詳細については、[ジョブ実行フロー](../jobs/job_execution.md)を参照してください。

**Related topics**（関連トピック）:

- [`after_script`を`default`と組み合わせて使用する](script.md#set-a-default-before_script-or-after_script-for-all-jobs)と、すべてのジョブの後に実行されるコマンドのデフォルト配列を定義できます。
- ジョブがキャンセルされた場合に[`after_script`コマンドをスキップ](script.md#skip-after_script-commands-if-a-job-is-canceled)するようにジョブを設定できます。
- [ゼロ以外の終了コードを無視](script.md#ignore-non-zero-exit-codes)できます。
- [`after_script`でカラーコードを使用する](script.md#add-color-codes-to-script-output)と、ジョブログのレビューが容易になります。
- [カスタムの折りたたみ可能なセクションを作成](../jobs/job_logs.md#custom-collapsible-sections)して、ジョブログ出力をシンプルにできます。
- [`after_script`のエラーを無視](../runners/configure_runners.md#ignore-errors-in-after_script)できます。

---

### `allow_failure` {#allow_failure}

`allow_failure`を使用して、ジョブが失敗した場合にパイプラインの実行を継続するかどうかを決定します。

- パイプラインで後続のジョブを継続して実行させるには、`allow_failure: true`を使用します。
- パイプラインで後続のジョブの実行を停止させるには、`allow_failure: false`を使用します。

ジョブの失敗が許容されている場合（`allow_failure: true`）、オレンジ色の警告（{{< icon name="status_warning" >}}）はジョブが失敗したことを示します。ただしパイプラインは成功し、関連するコミットは警告なしで成功としてマークされます。

このような警告は、次の場合に表示されます:

- ステージ内の他のすべてのジョブが成功した場合。
- パイプライン内の他のすべてのジョブが成功した場合。

`allow_failure`のデフォルト値は次のとおりです:

- [手動ジョブ](../jobs/job_control.md#create-a-job-that-must-be-run-manually): `true`。
- [`rules`](#rules)内で`when: manual`を使用しているジョブ: `false`。
- その他すべてのケース: `false`。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- `true`または`false`。

**Example of `allow_failure`**（の例）:

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

この例では、`job1`と`job2`は並列実行されます:

- `job1`が失敗した場合、`deploy`ステージのジョブは開始されません。
- `job2`が失敗した場合、`deploy`ステージのジョブは開始できます。

**Additional details**（補足情報）:

- `allow_failure`を[`rules`](#rulesallow_failure)のサブキーとして使用できます。
- `allow_failure: true`が設定されている場合、そのジョブは常に成功と見なされます。そのため、そのジョブが失敗しても、[`when: on_failure`](#when)が設定された後続のジョブは開始されません。
- 手動ジョブに`allow_failure: false`を設定することで、[ブロック手動ジョブ](../jobs/job_control.md#types-of-manual-jobs)を作成できます。ブロックされたパイプラインは、その手動ジョブが開始されて正常に完了するまで、後続ステージのジョブを実行しません。

---

#### `allow_failure:exit_codes` {#allow_failureexit_codes}

`allow_failure:exit_codes`を使用して、ジョブの失敗を許容する条件を制御します。ジョブは、リストされた終了コードのいずれかの場合は`allow_failure: true`、それ以外の終了コードに対しては`allow_failure`がfalseとなります。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- 1つの終了コード。
- 終了コードの配列。

**Example of `allow_failure`**（の例）:

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

---

### `artifacts` {#artifacts}

{{< history >}}

- GitLab Runner 18.1で[更新](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5543)されました。キャッシュ処理中に`symlinks`が追跡されることはなくなりました。これは、旧バージョンのGitLab Runnerにおいて一部のエッジケースで発生していました。

{{< /history >}}

`artifacts`を使用して、[ジョブアーティファクト](../jobs/job_artifacts.md)として保存するファイルを指定します。ジョブアーティファクトは、ジョブが[成功した場合、失敗した場合、または常に、](#artifactswhen)ジョブに添付されるファイルとディレクトリのリストです。

アーティファクトは、ジョブの完了後にGitLabに送信されます。サイズが[最大アーティファクトサイズ](../../user/gitlab_com/_index.md#cicd)よりも小さい場合、GitLab UIでダウンロードできます。

デフォルトでは、後続ステージのジョブは、前のステージのジョブによって作成されたすべてのアーティファクトを自動的にダウンロードします。[`dependencies`](#dependencies)を使用すると、ジョブにおけるアーティファクトのダウンロード動作を制御できます。

[`needs`](#needs)キーワードを使用している場合、ジョブは`needs`設定で定義されたジョブからのみアーティファクトをダウンロードできます。

デフォルトでは、成功したジョブのジョブアーティファクトのみが収集されます。[キャッシュ](#cache)が復元された後に、アーティファクトが復元されます。

ジョブの設定とデフォルトの設定は、一緒にマージされません。パイプラインに[`default:artifacts`](#default)が定義されていて、ジョブにも`artifacts`がある場合、ジョブの設定が優先され、デフォルトの設定は使用されません。

[アーティファクトの詳細についてはこちらを参照してください](../jobs/job_artifacts.md)。

---

#### `artifacts:paths` {#artifactspaths}

パスはプロジェクトディレクトリ（`$CI_PROJECT_DIR`）を基準にした相対パスであり、プロジェクトディレクトリの外部に直接リンクすることはできません。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- プロジェクトディレクトリを基準にしたファイルパスの配列。
- [glob](https://en.wikipedia.org/wiki/Glob_(programming))パターンおよび[`doublestar.Glob`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#Match)パターンを使用するワイルドカードを使用できます。
- [GitLab Pagesジョブ](#pages)の場合:
  - [GitLab 17.10以降](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)では、[`pages.publish`](#pagespublish)パスは自動的に`artifacts:paths`に付加されるため、再度指定する必要はありません。
  - [GitLab 17.10以降](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)では、[`pages.publish`](#pagespublish)パスが指定されていない場合、`public`ディレクトリが自動的に`artifacts:paths`に付加されます。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**Example of `artifacts:paths`**（の例）:

```yaml
job:
  artifacts:
    paths:
      - binaries/
      - .config
```

この例では、`.config`と、`binaries`ディレクトリ内にあるすべてのファイルを含むアーティファクトを作成します。

**Additional details**（補足情報）:

- [`artifacts:name`](#artifactsname)と組み合わせて使用しない場合、アーティファクトファイルの名前は`artifacts`になり、ダウンロード時に`artifacts.zip`になります。

**Related topics**（関連トピック）:

- 特定のジョブがどのジョブからアーティファクトをフェッチするかを制限するには、[`dependencies`](#dependencies)を参照してください。
- [ジョブアーティファクトを作成する](../jobs/job_artifacts.md#create-job-artifacts)。

---

#### `artifacts:exclude` {#artifactsexclude}

`artifacts:exclude`を使用して、ファイルがアーティファクトアーカイブに追加されないようにします。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- プロジェクトディレクトリを基準にしたファイルパスの配列。
- [glob](https://en.wikipedia.org/wiki/Glob_(programming))パターンまたは[`doublestar.PathMatch`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#PathMatch)パターンを使用するワイルドカードを使用できます。

**Example of `artifacts:exclude`**（の例）:

```yaml
artifacts:
  paths:
    - binaries/
  exclude:
    - binaries/**/*.o
```

この例では、`binaries/`内のすべてのファイルが保存されますが、`binaries/`以下のサブディレクトリにある`*.o`ファイルは保存されません。

**Additional details**（補足情報）:

- `artifacts:exclude`で指定されたパスは再帰的には検索されません。
- [`artifacts:untracked`](#artifactsuntracked)で一致したファイルも`artifacts:exclude`を使用して除外できます。

**Related topics**（関連トピック）:

- [ジョブアーティファクトからファイルを除外する](../jobs/job_artifacts.md#without-excluded-files)。

---

#### `artifacts:expire_in` {#artifactsexpire_in}

`expire_in`を使用して、[ジョブアーティファクト](../jobs/job_artifacts.md)が期限切れになり削除されるまでに保存される期間を指定します。`expire_in`の設定は、以下には影響しません:

- 最新ジョブのアーティファクト（ただし、[プロジェクトレベル](../jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs)または[インスタンス全体](../../administration/settings/continuous_integration.md#keep-artifacts-from-latest-successful-pipelines)で最新ジョブのアーティファクトの保持が無効になっている場合を除く）。

期限が切れたアーティファクトは、デフォルトでは毎時（cronジョブを使用して）削除され、アクセスできなくなります。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 有効期間。単位が指定されていない場合は秒単位です。有効な値の例は以下のとおりです:

- `'42'`
- `42 seconds`
- `3 mins 4 sec`
- `2 hrs 20 min`
- `2h20min`
- `6 mos 1 day`
- `47 yrs 6 mos and 4d`
- `3 weeks and 2 days`
- `never`

**Example of `artifacts:expire_in`**（の例）:

```yaml
job:
  artifacts:
    expire_in: 1 week
```

**Additional details**（補足情報）:

- 有効期間は、アーティファクトがGitLabにアップロードされて保存された時点から始まります。有効期間が定義されていない場合は、[インスタンス全体の設定](../../administration/settings/continuous_integration.md#set-default-artifacts-expiration)がデフォルトで使用されます。
- 有効期間をオーバーライドし、アーティファクトが自動的に削除されないように保護するには、次のようにします:
  - ジョブページで**維持**を選択します。
  - `expire_in`の値を`never`に設定します。
- 有効期間が短すぎると、長いパイプラインの後半のステージにあるジョブが、前半のジョブから期限切れのアーティファクトをフェッチしようとする可能性があります。アーティファクトが期限切れになっている場合、それらをフェッチしようとしたジョブは[`could not retrieve the needed artifacts`エラー](../jobs/job_artifacts_troubleshooting.md#error-message-this-job-could-not-start-because-it-could-not-retrieve-the-needed-artifacts)で失敗します。有効期間を長く設定するか、後続のジョブで[`dependencies`](#dependencies)を使用して、期限切れのアーティファクトをフェッチしないようにしてください。
- `artifacts:expire_in`は、GitLab Pagesのデプロイには影響しません。Pagesのデプロイの有効期間を設定するには、[`pages.expire_in`](#pagesexpire_in)を使用します。

---

#### `artifacts:expose_as` {#artifactsexpose_as}

`artifacts:expose_as`キーワードを使用して、[マージリクエストUI](../jobs/job_artifacts.md#link-to-job-artifacts-in-the-merge-request-ui)でアーティファクトを公開します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- マージリクエストUIに表示する、アーティファクトのダウンロードリンクの名前。[`artifacts:paths`](#artifactspaths)と組み合わせて使用する必要があります。

**Example of `artifacts:expose_as`**（の例）:

```yaml
test:
  script: ["echo 'test' > file.txt"]
  artifacts:
    expose_as: 'artifact 1'
    paths: ['file.txt']
```

**Additional details**（補足情報）:

- `expose_as`はジョブごとに1回のみ使用でき、マージリクエストごとに最大10個のジョブを使用できます。
- Globパターンはサポートされていません。
- アーティファクトは常にGitLabに送信されます。それらは、`artifacts:paths`値でない限り、UIに表示されます:
  - [CI/CD変数](../variables/_index.md)を使用している。
  - ディレクトリを定義しているが、パスの末尾が`/`ではない。たとえば、`artifacts:expose_as`で`directory/`は機能しますが、`directory`は機能しません。
- `artifacts:paths`に単一のファイルのみが含まれている場合、リンクはそのファイルを直接開きます。それ以外の場合はすべて、リンクは[アーティファクトブラウザ](../jobs/job_artifacts.md#download-job-artifacts)を開きます。
- リンクされたファイルは、デフォルトでダウンロードされます。[GitLab Pages](../../administration/pages/_index.md)が有効になっている場合は、一部のアーティファクトのファイル拡張子をブラウザで直接プレビューできます。詳細については、[アーティファクトアーカイブのコンテンツの参照](../jobs/job_artifacts.md#browse-the-contents-of-the-artifacts-archive)を参照してください。

**Related topics**（関連トピック）:

- [マージリクエストUIでジョブアーティファクトを公開する](../jobs/job_artifacts.md#link-to-job-artifacts-in-the-merge-request-ui)。

---

#### `artifacts:name` {#artifactsname}

`artifacts:name`キーワードを使用して、作成されたアーティファクトアーカイブの名前を定義します。アーカイブごとに一意の名前を指定できます。

定義されていない場合、デフォルトの名前は`artifacts`であり、ダウンロード時に`artifacts.zip`になります。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- アーティファクトアーカイブの名前。CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。[`artifacts:paths`](#artifactspaths)と組み合わせて使用する必要があります。

**Example of `artifacts:name`**（の例）:

現在のジョブの名前でアーカイブを作成するには:

```yaml
job:
  artifacts:
    name: "job1-artifacts-file"
    paths:
      - binaries/
```

**Related topics**（関連トピック）:

- [CI/CD変数を使用してアーティファクト設定を定義する](../jobs/job_artifacts.md#with-variable-expansion)

---

#### `artifacts:public` {#artifactspublic}

{{< history >}}

- GitLab 15.10で[更新](https://gitlab.com/gitlab-org/gitlab/-/issues/322454)されました。15.10よりも前に`artifacts:public`を使用して作成されたアーティファクトは、この更新後も非公開が維持される保証はありません。
- GitLab 16.7で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/294503)になりました。機能フラグ`non_public_artifacts`は削除されました。

{{< /history >}}

{{< alert type="note" >}}

`artifacts:public`は、より多くのオプションがある[`artifacts:access`](#artifactsaccess)に置き換えられました。

{{< /alert >}}

`artifacts:public`を使用して、ジョブアーティファクトを公開するかどうかを決定します。

`artifacts:public`が`true`（デフォルト）の場合、公開パイプラインのアーティファクトをダウンロードできるのは、匿名ユーザー、ゲストユーザー、レポーターユーザーです。

匿名ユーザー、ゲストユーザー、レポーターユーザーに対して公開パイプラインのアーティファクトへの読み取りアクセスを拒否するには、`artifacts:public`を`false`に設定します:

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- `true`（定義されていない場合はデフォルト）または`false`。

**Example of `artifacts:public`**（の例）:

```yaml
job:
  artifacts:
    public: false
```

---

#### `artifacts:access` {#artifactsaccess}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145206)されました。
- `maintainer`オプションは、GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/454398)されました。

{{< /history >}}

`artifacts:access`を使用して、GitLab UIまたはAPIからジョブアーティファクトにアクセスできるユーザーを決定します。このオプションを使用しても、アーティファクトをダウンストリームパイプラインに転送できなくなることはありません。

同じジョブ内で[`artifacts:public`](#artifactspublic)と`artifacts:access`を併用することはできません。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- `all`（デフォルト）: 公開パイプラインのジョブのアーティファクトは、匿名ユーザー、ゲストユーザー、レポーターユーザーなど誰でもダウンロードできます。
- `developer`: ジョブのアーティファクトをダウンロードできるのは、デベロッパーロール以上のロールを持つユーザーのみです。
- `maintainer`: ジョブ内のアーティファクトは、少なくともメンテナーロールを持つユーザーのみがダウンロードできます。
- `none`: 誰もジョブのアーティファクトをダウンロードできません。

**Example of `artifacts:access`**（の例）:

```yaml
job:
  artifacts:
    access: 'developer'
```

**Additional details**（補足情報）:

- `artifacts:access`はすべての[`artifacts:reports`](#artifactsreports)にも影響するため、[レポートのアーティファクト](artifacts_reports.md)へのアクセスを制限することもできます。

---

#### `artifacts:reports` {#artifactsreports}

[`artifacts:reports`](artifacts_reports.md)を使用して、ジョブにインクルードされたテンプレートによって生成されたアーティファクトを収集します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- 利用可能な[アーティファクトレポートのタイプ](artifacts_reports.md)のリストを参照してください。

**Example of `artifacts:reports`**（の例）:

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

**Additional details**（補足情報）:

- [子パイプラインからのアーティファクト](#needspipelinejob)を使用して、親パイプラインでレポートを組み合わせる操作はサポートされていません。サポートの追加については、[このイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/215725)で進捗を追跡できます。
- レポートの出力ファイルを参照してダウンロードできるようにするには、[`artifacts:paths`](#artifactspaths)キーワードを含めます。これにより、アーティファクトのアップロードと保存が2回実行されます。
- `artifacts: reports`のために作成されたアーティファクトは、ジョブの結果（成功または失敗）にかかわらず、常にアップロードされます。[`artifacts:expire_in`](#artifactsexpire_in)を使用して、アーティファクトの有効期限を設定できます。

---

#### `artifacts:untracked` {#artifactsuntracked}

`artifacts:untracked`を使用して、（`artifacts:paths`で定義されたパスとともに）すべての追跡していないGitファイルをアーティファクトとして追加します。`artifacts:untracked`はリポジトリの`.gitignore`の設定を無視するため、`.gitignore`内の一致するアーティファクトがインクルードされます。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- `true`または`false`（定義されていない場合はデフォルト）。

**Example of `artifacts:untracked`**（の例）:

追跡していないGitファイルをすべて保存します:

```yaml
job:
  artifacts:
    untracked: true
```

**Related topics**（関連トピック）:

- [追跡していないファイルをアーティファクトに追加する](../jobs/job_artifacts.md#with-untracked-files)。

---

#### `artifacts:when` {#artifactswhen}

`artifacts:when`を使用して、ジョブの失敗時、または失敗にかかわらずアーティファクトをアップロードします。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- `on_success`（デフォルト）: ジョブが成功した場合にのみアーティファクトをアップロードします。
- `on_failure`: ジョブが失敗した場合にのみアーティファクトをアップロードします。
- `always`: 常にアーティファクトをアップロードします（ジョブがタイムアウトになった場合を除く）。たとえば、失敗したテストの問題解決に必要な[アーティファクトをアップロードする](../testing/unit_test_reports.md#add-screenshots-to-test-reports)場合などです。

**Example of `artifacts:when`**（の例）:

```yaml
job:
  artifacts:
    when: on_failure
```

**Additional details**（補足情報）:

- [`artifacts:reports`](#artifactsreports)で作成されたアーティファクトは、ジョブの結果（成功または失敗）に関係なく常にアップロードされます。`artifacts:when`はこの動作を変更しません。

---

### `before_script` {#before_script}

`before_script`を使用して、[アーティファクト](#artifacts)が復元された後、各ジョブの`script`コマンドの前に実行するコマンドの配列を定義します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 次の内容を含む配列:

- 1行のコマンド。
- [複数行に分割された](script.md#split-long-commands)長いコマンド。
- [YAMLアンカー](yaml_optimization.md#yaml-anchors-for-scripts)。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**Example of `before_script`**（の例）:

```yaml
job:
  before_script:
    - echo "Execute this command before any 'script:' commands."
  script:
    - echo "This command executes after the job's 'before_script' commands."
```

**Additional details**（補足情報）:

- `before_script`で指定したスクリプトが、メインの[`script`](#script)で指定したスクリプトと連結されます。連結されたスクリプトは、1つのShellでまとめて実行されます。
- `before_script`を`default`セクションではなくトップレベルで使用することは、[非推奨です](deprecated_keywords.md#globally-defined-image-services-cache-before_script-after_script)。

**Related topics**（関連トピック）:

- [`before_script`を`default`と組み合わせて使用](script.md#set-a-default-before_script-or-after_script-for-all-jobs)すると、すべてのジョブで`script`コマンドの前に実行されるコマンドのデフォルトの配列を定義できます。
  - ジョブの設定とデフォルトの設定は、一緒にマージされません。パイプラインに[`default:before_script`](#default)が定義されていて、ジョブにも`before_script`がある場合、ジョブの設定が優先され、デフォルトの設定は使用されません。
- [ゼロ以外の終了コードを無視](script.md#ignore-non-zero-exit-codes)できます。
- [`before_script`でカラーコードを使用する](script.md#add-color-codes-to-script-output)と、ジョブログのレビューが容易になります。
- [カスタムの折りたたみ可能なセクションを作成](../jobs/job_logs.md#custom-collapsible-sections)して、ジョブログ出力をシンプルにできます。

---

### `cache` {#cache}

{{< history >}}

- GitLab 15.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/330047)されました。キャッシュは、保護ブランチと保護されていないブランチの間では共有されません。
- GitLab Runner 18.1で[更新](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5543)されました。キャッシュ処理中に`symlinks`が追跡されることはなくなりました。これは、旧バージョンのGitLab Runnerにおいて一部のエッジケースで発生していました。

{{< /history >}}

`cache`を使用して、ジョブ間でキャッシュするファイルとディレクトリのリストを指定します。ローカルの実行コピーにあるパスのみを使用できます。

キャッシュは次のようになります:

- パイプラインとジョブ間で共有されます。
- デフォルトでは、[保護](../../user/project/repository/branches/protected.md)ブランチと保護されていないブランチの間では共有されません。
- [アーティファクト](#artifacts)の前に復元されます。
- 最大4つの[キャッシュ](../caching/_index.md#use-multiple-caches)に制限されています。

[特定のジョブのキャッシュを無効にできます](../caching/_index.md#disable-cache-for-specific-jobs)。たとえば、以下をオーバーライドする場合です:

- [`default`](#default)で定義されたデフォルトのキャッシュ。
- [`include`](#include)で追加されたジョブの設定。

ジョブの設定とデフォルトの設定は、一緒にマージされません。パイプラインに[`default:cache`](#default)が定義されていて、ジョブにも`cache`がある場合、ジョブの設定が優先され、デフォルトの設定は使用されません。

キャッシュの詳細については、[GitLab CI/CDでのキャッシュ](../caching/_index.md)を参照してください。

`cache`を`default`セクションではなくトップレベルで使用することは、[非推奨](deprecated_keywords.md#globally-defined-image-services-cache-before_script-after_script)です。

---

#### `cache:paths` {#cachepaths}

`cache:paths`キーワードを使用して、キャッシュするファイルまたはディレクトリを選択します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- プロジェクトディレクトリ（`$CI_PROJECT_DIR`）を基準にしたパスの配列。[glob](https://en.wikipedia.org/wiki/Glob_(programming))パターンおよび[`doublestar.Glob`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#Match)パターンを使用するワイルドカードを使用できます。

[CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)がサポートされています。

**Example of `cache:paths`**（の例）:

`binaries`にある`.apk`で終わるすべてのファイルと、`.config`ファイルをキャッシュします:

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

**Additional details**（補足情報）:

- `cache:paths`キーワードでは、追跡していないファイルや`.gitignore`ファイルに記載されているファイルもキャッシュの対象になります。

**Related topics**（関連トピック）:

- その他の`cache:paths`の例については、[`cache`の一般的なユースケース](../caching/_index.md#common-use-cases-for-caches)を参照してください。

---

#### `cache:key` {#cachekey}

`cache:key`キーワードを使用して、各キャッシュに一意の識別キーを指定します。同じキャッシュキーを使用するすべてのジョブは、異なるパイプラインでも同じキャッシュを使用します。

設定されていない場合のデフォルトのキーは`default`です。`cache`キーワードを指定していても`cache:key`を指定していないジョブはすべて、`default`キャッシュを共有します。

`cache: paths`と組み合わせて使用する必要があります。そうしないと、何もキャッシュされません。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- 文字列。
- 定義済み[CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。
- 両方の組み合わせ。

**Example of `cache:key`**（の例）:

```yaml
cache-job:
  script:
    - echo "This job uses a cache."
  cache:
    key: binaries-cache-$CI_COMMIT_REF_SLUG
    paths:
      - binaries/
```

**Additional details**（補足情報）:

- **Windows Batch**（Windowsバッチ）を使用してShellスクリプトを実行する場合は、`$`を`%`に置き換える必要があります。たとえば`key: %CI_COMMIT_REF_SLUG%`などです。
- `cache:key`の値に次の文字を含めることはできません:

  - `/`、またはそのURIエンコード形式である`%2F`。
  - `.`のみ（任意の数）、またはそのURIエンコード形式である`%2E`。

- キャッシュはジョブ間で共有されるため、ジョブごとに異なるパスを使用している場合は、それぞれ異なる`cache:key`も設定する必要があります。そうしないと、キャッシュの内容が上書きされる可能性があります。

**Related topics**（関連トピック）:

- 指定された`cache:key`が見つからない場合に使用する[フォールバックキャッシュキー](../caching/_index.md#use-a-fallback-cache-key)を指定できます。
- 1つのジョブで[複数のキャッシュキーを使用](../caching/_index.md#use-multiple-caches)できます。
- その他の`cache:key`の例については、[`cache`の一般的なユースケース](../caching/_index.md#common-use-cases-for-caches)を参照してください。

---

##### `cache:key:files` {#cachekeyfiles}

指定されたファイルの内容が変更されたときに新しいキャッシュキーを生成するには、`cache:key:files`を使用します。内容が変更されない場合、キャッシュキーはブランチとパイプライン間で一貫性が保たれます。キャッシュを再利用し、再構築する頻度を減らすことができるため、後続のパイプラインの実行が高速化されます。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- 最大2つのファイルパスまたはパターンの配列。

CI/CD変数はサポートされていません。

**Example of `cache:key:files`**（の例）:

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

この例では、RubyとNode.jsの依存関係のキャッシュを作成します。キャッシュは、`Gemfile.lock`ファイルと`package.json`ファイルの現行バージョンに関連付けられています。これらのファイルのいずれかが変更されると、新しいキャッシュキーが計算され、新しいキャッシュが作成されます。後続のジョブの実行で`cache:key:files`が使用され、同じ`Gemfile.lock`および`package.json`を参照している場合には、依存関係を再構築せずに新しいキャッシュが使用されます。

**Additional details**（補足情報）:

- キャッシュ`key`は、リストされたファイルの内容から計算されたハッシュです。ファイルが存在しない場合、キーの計算では無視されます。指定されたファイルが1つも存在しない場合、フォールバックキーは`default`です。
- `**/package.json`などのワイルドカードパターンを使用できます。キャッシュキーに指定できるパスまたはパターンの数を増やすための[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/301161)が存在します。

---

##### `cache:key:files_commits` {#cachekeyfiles_commits}

指定されたファイルの最新のコミットが変更されたときに新しいキャッシュキーを生成するには、`cache:key:files_commits`を使用します。`cache:key:files_commits`キャッシュキーは、ファイルの内容が同一のままであっても、指定されたファイルに新しいコミットがあるたびに変更されます。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- 最大2つのファイルパスまたはパターンの配列。

**Example of `cache:key:files_commits`**（の例）:

```yaml
cache-job:
  script:
    - echo "This job uses a commit-based cache."
  cache:
    key:
      files_commits:
        - package.json
        - yarn.lock
    paths:
      - node_modules
```

この例では、`package.json`と`yarn.lock`のコミット履歴に基づいてキャッシュを作成します。これらのファイルのコミット履歴が変更された場合、新しいキャッシュキーが計算され、新しいキャッシュが作成されます。

**Additional details**（補足情報）:

- キャッシュ`key`は、指定された各ファイルの最新のコミットから計算されたハッシュです。
- ファイルが存在しない場合、キーの計算では無視されます。
- 指定されたファイルが1つも存在しない場合、フォールバックキーは`default`です。
- 同じキャッシュの設定で[`cache:key:files`](#cachekeyfiles)と組み合わせて使用することはできません。

---

##### `cache:key:prefix` {#cachekeyprefix}

`cache:key:prefix`を使用して、[`cache:key:files`](#cachekeyfiles)で計算されたSHAとプレフィックスを組み合わせます。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- 文字列。
- 定義済み[CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。
- 両方の組み合わせ。

**Example of `cache:key:prefix`**（の例）:

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

たとえば`$CI_JOB_NAME`という`prefix`を追加すると、キーは`rspec-feef9576d21ee9b6a32e30c5c79d0a0ceb68d1e5`のようになります。ブランチで`Gemfile.lock`が変更されると、そのブランチには`cache:key:files`に対する新しいSHAチェックサムが設定されます。これにより、新しいキャッシュキーが生成され、そのキーに対する新しいキャッシュが作成されます。`Gemfile.lock`が見つからない場合、`default`にプレフィックスが追加されます。この例では、キーは`rspec-default`になります。

**Additional details**（補足情報）:

- `cache:key:files`に指定されたファイルがコミットで変更されていない場合は、`default`キーにプレフィックスが追加されます。

---

#### `cache:untracked` {#cacheuntracked}

`untracked: true`を使用して、Gitリポジトリで追跡していないすべてのファイルをキャッシュします。追跡していないファイルには、次のファイルが含まれます:

- [`.gitignore`設定](https://git-scm.com/docs/gitignore)が原因で無視されているファイル。
- 作成されたが、[`git add`](https://git-scm.com/docs/git-add)でステージングされていないファイル。

追跡していないファイルをキャッシュすると、ジョブが次のようなものをダウンロードした際に、予期せず大きなキャッシュが作成される可能性があります:

- 通常は追跡されない依存関係（gemやノードモジュールなど）。
- 別のジョブからの[アーティファクト](#artifacts)。デフォルトでは、アーティファクトから抽出されたファイルは追跡されません。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- `true`または`false`（デフォルト）。

**Example of `cache:untracked`**（の例）:

```yaml
rspec:
  script: test
  cache:
    untracked: true
```

**Additional details**（補足情報）:

- `cache:untracked`と`cache:paths`を組み合わせて指定すると、追跡していないすべてのファイルと、設定されたパス内のファイルをキャッシュできます。`cache:paths`は、追跡したファイルや作業ディレクトリの外部にあるファイルを含む、特定のファイルをキャッシュするために使用します。`cache: untracked`を使用することで、追跡していないファイルもすべてキャッシュすることができます。例: 

  ```yaml
  rspec:
    script: test
    cache:
      untracked: true
      paths:
        - binaries/
  ```

  この例では、ジョブはリポジトリ内の追跡していないすべてのファイルと、`binaries/`内のすべてのファイルをキャッシュします。`binaries/`内に追跡していないファイルがある場合、それらはこの両方のキーワードでカバーされます。

---

#### `cache:unprotect` {#cacheunprotect}

{{< history >}}

- GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/362114)されました。

{{< /history >}}

`cache:unprotect`を使用して、[保護](../../user/project/repository/branches/protected.md)ブランチと保護されていないブランチの間でキャッシュが共有されるように設定します。

{{< alert type="warning" >}}

`true`に設定すると、保護ブランチへのアクセス権を持たないユーザーが、保護ブランチで使用されるキャッシュキーを読み書きできます。

{{< /alert >}}

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- `true`または`false`（デフォルト）。

**Example of `cache:unprotect`**（の例）:

```yaml
rspec:
  script: test
  cache:
    unprotect: true
```

---

#### `cache:when` {#cachewhen}

`cache:when`を使用して、ジョブのステータスに基づいてキャッシュを保存するタイミングを定義します。

`cache: paths`と組み合わせて使用する必要があります。そうしないと、何もキャッシュされません。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- `on_success`（デフォルト）: ジョブが成功した場合にのみキャッシュを保存します。
- `on_failure`: ジョブが失敗した場合にのみキャッシュを保存します。
- `always`: キャッシュを常に保存します。

**Example of `cache:when`**（の例）:

```yaml
rspec:
  script: rspec
  cache:
    paths:
      - rspec/
    when: 'always'
```

この例では、ジョブの成功または失敗にかかわらずキャッシュを保存します。

---

#### `cache:policy` {#cachepolicy}

キャッシュのアップロードとダウンロードの動作を変更するには、`cache:policy`キーワードを使用します。デフォルトでは、ジョブはジョブの開始時にキャッシュをダウンロードし、ジョブの終了時に変更をキャッシュにアップロードします。このキャッシュスタイルは`pull-push`ポリシー（デフォルト）です。

ジョブの開始時にキャッシュをダウンロードするだけで、ジョブの終了時に変更をアップロードしないようにジョブを設定するには、`cache:policy:pull`を使用します。

ジョブの終了時にキャッシュをアップロードするだけで、ジョブの開始時にキャッシュをダウンロードしないようにジョブを設定するには、`cache:policy:push`を使用します。

同じキャッシュを使用する多数のジョブが並列実行される場合は、`pull`ポリシーを使用します。このポリシーにより、ジョブの実行が高速化され、キャッシュサーバーの負荷も軽減されます。キャッシュを構築するために、`push`ポリシーを指定したジョブを使用できます。

`cache: paths`と組み合わせて使用する必要があります。そうしないと、何もキャッシュされません。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- `pull`
- `push`
- `pull-push`（デフォルト）
- [CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**Example of `cache:policy`**（の例）:

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

**Related topics**（関連トピック）:

- [変数を使用して、ジョブのキャッシュポリシーを制御](../caching/_index.md#use-a-variable-to-control-a-jobs-cache-policy)できます。

---

#### `cache:fallback_keys` {#cachefallback_keys}

`cache:fallback_keys`を使用して、`cache:key`に対応するキャッシュが見つからない場合に、キャッシュの復元を試行するキーのリストを指定します。キャッシュは、`fallback_keys`セクションで指定された順序で取得されます。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- キャッシュキーの配列

**Example of `cache:fallback_keys`**（の例）:

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

---

### `coverage` {#coverage}

`coverage`とカスタム正規表現を使用して、ジョブの出力からコードカバレッジを抽出する方法を設定します。ジョブの出力に、正規表現と一致する行が1行以上含まれている場合、カバレッジがUIに表示されます。

一致した文字列からコードカバレッジの値を抽出するために、GitLabは短い正規表現`\d+(?:\.\d+)?`を使用します。

**Supported values**（サポートされている値）: 

- RE2正規表現。冒頭と末尾の両方が`/`である必要があります。カバレッジの数値と一致する必要があります。周囲のテキストも含めて一致しても問題ありません。そのため、正確な数値をキャプチャするために正規表現の文字グループを使用する必要はありません。RE2構文を使用するため、すべてグループは非キャプチャグループでなければなりません。

**Example of `coverage`**（の例）:

```yaml
job1:
  script: rspec
  coverage: '/Code coverage: \d+(?:\.\d+)?/'
```

この例では:

1. GitLabが、ジョブログに対して正規表現が一致するかどうかをチェックします。`Code coverage: 67.89% of lines covered`のような行が一致します。
1. GitLabは、一致した部分をチェックして、正規表現`\d+(?:\.\d+)?`と一致する箇所を見つけます。この例の正規表現は、コードカバレッジの値`67.89`に一致します。

**Additional details**（補足情報）:

- 正規表現の例は[コードカバレッジ](../testing/code_coverage/_index.md#coverage-regex-patterns)に記載されています。
- ジョブの出力に一致する行が複数ある場合は、最後の行が使用されます（逆方向検索で最初に一致した結果）。
- 1行内に一致した箇所が複数ある場合は、最後に一致した部分からカバレッジの数値が抽出されます。
- 一致した部分から複数のカバレッジの数値が見つかった場合は、最初の数値が使用されます。
- 先頭のゼロは削除されます。
- [子パイプライン](../pipelines/downstream_pipelines.md#parent-child-pipelines)からのカバレッジ出力は、記録または表示されません。詳細については、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/280818)を確認してください。

---

### `dast_configuration` {#dast_configuration}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`dast_configuration`キーワードを使用して、CI/CD設定で使用するサイトプロファイルとスキャナープロファイルを指定します。両方のプロファイルが、あらかじめプロジェクトで作成されている必要があります。ジョブのステージは`dast`である必要があります。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: `site_profile`と`scanner_profile`（それぞれ1つずつ）。

- ジョブで使用するサイトプロファイルを指定するには、`site_profile`を使用します。
- ジョブで使用するスキャナープロファイルを指定するには、`scanner_profile`を使用します。

**Example of `dast_configuration`**（の例）:

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

この例では、`dast`ジョブが、`include`キーワードで追加された`dast`設定を拡張し、特定のサイトプロファイルおよびスキャナープロファイルを選択しています。

**Additional details**（補足情報）:

- サイトプロファイルまたはスキャナープロファイルに含まれる設定は、DASTテンプレートに含まれる設定よりも優先されます。

**Related topics**（関連トピック）:

- [サイトプロファイル](../../user/application_security/dast/profiles.md#site-profile)。
- [スキャナープロファイル](../../user/application_security/dast/profiles.md#scanner-profile)。

---

### `dependencies` {#dependencies}

`dependencies`キーワードを使用して、[アーティファクト](#artifacts)のフェッチ元のジョブのリストを定義します。指定されたジョブはすべて、先行するステージに存在する必要があります。アーティファクトをまったくダウンロードしないようにジョブを設定することもできます。

ジョブで`dependencies`が定義されていない場合、前のステージにあるすべてのジョブが依存対象と見なされ、ジョブはそれらのジョブからすべてのアーティファクトをフェッチします。

同じステージ内のジョブからアーティファクトをフェッチするには、[`needs:artifacts`](#needsartifacts)を使用する必要があります。同じジョブの中で`dependencies`を`needs`と組み合わせて使用しないでください。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- アーティファクトのフェッチ元のジョブの名前。
- 空の配列（`[]`）。アーティファクトをダウンロードしないようにジョブを設定します。

**Example of `dependencies`**（の例）:

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

この例では、`build osx`と`build linux`の2つのジョブがアーティファクトを生成します。`test osx`が実行されると、`build osx`からのアーティファクトがダウンロードされ、ビルドのコンテキストで抽出されます。`test linux`も同様に、`build linux`からのアーティファクトを取得します。

`deploy`ジョブは、[ステージ](#stages)の優先順位に従って、それ以前のすべてのジョブからアーティファクトをダウンロードします。

**Additional details**（補足情報）:

- ジョブステータスは関係ありません。ジョブが失敗した場合、またはトリガーされていない手動ジョブである場合、エラーは発生しません。
- 依存先のジョブのアーティファクトが[期限切れ](#artifactsexpire_in)であるか[削除](../jobs/job_artifacts.md#delete-job-log-and-artifacts)されている場合、ジョブは失敗します。

---

### `environment` {#environment}

`environment`を使用して、ジョブがデプロイされる[環境](../environments/_index.md)を定義します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: ジョブのデプロイ先の環境の名前。次のいずれかの形式で指定します:

- 平文（英字、数字、スペース、および文字`-`、`_`、`/`、`$`、`{`、`}`を含む）。
- CI/CD変数（定義済みの変数、プロジェクト、グループ、インスタンスの変数、または`.gitlab-ci.yml`ファイルで定義された変数を含む）。`script`セクションで定義された変数は使用できません。

**Example of `environment`**（の例）:

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment: production
```

**Additional details**（補足情報）:

- `environment`を指定しても、その名前の環境が存在しない場合は、環境が作成されます。

---

#### `environment:name` {#environmentname}

[環境](../environments/_index.md)の名前を設定します。

一般的な環境名は`qa`、`staging`、`production`ですが、任意の名前を使用できます。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: ジョブのデプロイ先の環境の名前。次のいずれかの形式で指定します:

- 平文（英字、数字、スペース、および文字`-`、`_`、`/`、`$`、`{`、`}`を含む）。
- [CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)（定義済みの変数、プロジェクト、グループ、インスタンスの変数、または`.gitlab-ci.yml`ファイルで定義された変数を含む）。`script`セクションで定義された変数は使用できません。

**Example of `environment:name`**（の例）:

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment:
    name: production
```

---

#### `environment:url` {#environmenturl}

[環境](../environments/_index.md)のURLを設定します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 単一のURL。次のいずれかの形式で指定します:

- 平文（例: `https://prod.example.com`）。
- [CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)（定義済みの変数、プロジェクト、グループ、インスタンスの変数、または`.gitlab-ci.yml`ファイルで定義された変数を含む）。`script`セクションで定義された変数は使用できません。

**Example of `environment:url`**（の例）:

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment:
    name: production
    url: https://prod.example.com
```

**Additional details**（補足情報）:

- ジョブが完了したら、URLにアクセスできます。URLにアクセスするには、マージリクエスト、環境、またはデプロイページでボタンを選択します。

---

#### `environment:on_stop` {#environmenton_stop}

`environment`で定義されている`on_stop`キーワードを使用して、環境を閉じる（停止する）ことができます。これは、環境を閉じるために実行される別のジョブを宣言します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Additional details**（補足情報）:

- 詳細と例については、[`environment:action`](#environmentaction)を参照してください。

---

#### `environment:action` {#environmentaction}

`action`キーワードを使用して、ジョブが環境をどのように操作するかを指定します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 次のキーワードのいずれか:

| **値** | **説明** |
|:----------|:----------------|
| `start`   | デフォルト値。ジョブが環境を開始することを示します。デプロイはジョブの開始後に作成されます。 |
| `prepare` | ジョブが環境の準備のみを行うことを示します。デプロイはトリガーされません。[環境の準備の詳細については、こちらを参照してください](../environments/_index.md#access-an-environment-for-preparation-or-verification-purposes)。 |
| `stop`    | ジョブが環境を停止することを示します。[環境の停止の詳細については、こちらを参照してください](../environments/_index.md#stopping-an-environment)。 |
| `verify`  | ジョブが環境の検証のみを行うことを示します。デプロイはトリガーされません。[環境の検証の詳細については、こちらを参照してください](../environments/_index.md#access-an-environment-for-preparation-or-verification-purposes)。 |
| `access`  | ジョブが環境へのアクセスのみを行うことを示します。デプロイはトリガーされません。[環境へのアクセスの詳細については、こちらを参照してください](../environments/_index.md#access-an-environment-for-preparation-or-verification-purposes)。 |

**Example of `environment:action`**（の例）:

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

---

#### `environment:auto_stop_in` {#environmentauto_stop_in}

{{< history >}}

- CI/CD変数のサポートは、GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/365140)されました。
- GitLab 17.7で`prepare`、`access`、および`verify`環境アクションをサポートするために[更新](https://gitlab.com/gitlab-org/gitlab/-/issues/437133)されました。

{{< /history >}}

`auto_stop_in`キーワードは、環境のライフタイムを指定します。環境の有効期限が切れると、GitLabは自動的にその環境を停止します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 自然言語で記述された期間。たとえば、以下の表記はすべて同等です:

- `168 hours`
- `7 days`
- `one week`
- `never`

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**Example of `environment:auto_stop_in`**（の例）:

```yaml
review_app:
  script: deploy-review-app
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    auto_stop_in: 1 day
```

`review_app`の環境が作成されると、その環境のライフタイムは`1 day`に設定されます。レビューアプリがデプロイされるたびに、そのライフタイムも`1 day`にリセットされます。

`auto_stop_in`キーワードは、`stop`を除くすべての[環境アクション](#environmentaction)に使用できます。一部のアクションは、環境のスケジュールされた停止時間をリセットするために使用できます。詳細については、[準備または検証目的で環境にアクセスする](../environments/_index.md#access-an-environment-for-preparation-or-verification-purposes)を参照してください。

**Related topics**（関連トピック）:

- [環境の自動停止に関するドキュメント](../environments/_index.md#stop-an-environment-after-a-certain-time-period)。

---

#### `environment:kubernetes` {#environmentkubernetes}

{{< history >}}

- `agent`キーワードは、GitLab 17.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/467912)されました。
- `namespace`および`flux_resource_path`キーワードは、GitLab 17.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/500164)されました。
- `namespace`および`flux_resource_path`のキーワードは、GitLab 18.4で[非推奨](deprecated_keywords.md)となりました。
- `dashboard:namespace`および`dashboard:flux_resource_path`キーワードは、GitLab 18.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/515854)されました。

{{< /history >}}

`kubernetes`キーワードを使用して、環境の[Kubernetesのダッシュボード](../environments/kubernetes_dashboard.md)と[GitLabで管理されるKubernetesリソース](../../user/clusters/agent/managed_kubernetes_resources.md)を設定します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- `agent`: [Kubernetes向けGitLabエージェント](../../user/clusters/agent/_index.md)を指定する文字列。形式は`path/to/agent/project:agent-name`です。エージェントがパイプラインを実行しているプロジェクトに接続されている場合は、`$CI_PROJECT_PATH:agent-name`を使用します。
- `dashboard:namespace`: 環境がデプロイされるKubernetesネームスペースを表す文字列。ネームスペースは`agent`キーワードとともに設定する必要があります。`namespace`は[非推奨](deprecated_keywords.md#environmentkubernetesnamespace-and-environmentkubernetesflux_resource_path)です。
- `dashboard:flux_resource_path`: `HelmRelease`など、Fluxリソースへのフルパスを表す文字列。Fluxリソースは、`agent`および`dashboard:namespace`キーワードとともに設定する必要があります。`flux_resource_path`は[非推奨](deprecated_keywords.md#environmentkubernetesnamespace-and-environmentkubernetesflux_resource_path)です。
- `managed_resources`: 環境の[GitLabで管理されるKubernetesリソース](../../user/clusters/agent/managed_kubernetes_resources.md)を設定する`enabled`キーワードを持つハッシュ。
  - `managed_resources:enabled`: GitLabで管理されるKubernetesリソースが環境で有効になっているかどうかを示すブール値。
- `dashboard`: 環境の[Kubernetesのダッシュボード](../environments/kubernetes_dashboard.md)を設定する`dashboard:namespace`および`dashboard:flux_resource_path`キーワードを持つハッシュ。

**Example of `environment:kubernetes`**（の例）:

```yaml
deploy:
  stage: deploy
  script: make deploy-app
  environment:
    name: production
    kubernetes:
      agent: path/to/agent/project:agent-name
      dashboard:
        namespace: my-namespace
        flux_resource_path: helm.toolkit.fluxcd.io/v2/namespaces/flux-system/helmreleases/helm-release-resource
```

マネージドリソースを無効にする場合の**Example of `environment:kubernetes`**（例）:

```yaml
deploy:
  stage: deploy
  script: make deploy-app
  environment:
    name: production
    kubernetes:
      agent: path/to/agent/project:agent-name
      managed_resources:
        enabled: false
      dashboard:
        namespace: my-namespace
        flux_resource_path: helm.toolkit.fluxcd.io/v2/namespaces/flux-system/helmreleases/helm-release-resource
```

この設定では:

- `deploy`ジョブを、`production`環境にデプロイするよう設定します。
- `agent-name`という名前の[エージェント](../../user/clusters/agent/_index.md)を環境に関連付けます。
- ネームスペースが`my-namespace`に設定され、`flux_resource_path`に`helm.toolkit.fluxcd.io/v2/namespaces/flux-system/helmreleases/helm-release-resource`が指定された環境向けに、[Kubernetesのダッシュボード](../environments/kubernetes_dashboard.md)を設定します。

**Additional details**（補足情報）:

- ダッシュボードを使用するには、[Kubernetes向けGitLabエージェントをインストール](../../user/clusters/agent/install/_index.md)し、環境のプロジェクトまたはその親グループの[`user_access`を設定する](../../user/clusters/agent/user_access.md)必要があります。
- ジョブを実行するユーザーには、クラスターエージェントへのアクセス権限が必要です。権限がない場合、ダッシュボードは`agent`、`namespace`、`flux_resource_path`属性を無視します。
- `agent`のみを設定する場合は、`namespace`を設定する必要はなく、`flux_resource_path`を設定することはできません。ただし、この設定では、Kubernetesのダッシュボードにクラスター内のすべてのネームスペースが一覧表示されます。

---

#### `environment:deployment_tier` {#environmentdeployment_tier}

{{< history >}}

- GitLab 18.5で[追加](https://gitlab.com/gitlab-org/gitlab/-/issues/365402)されたCI/CD変数のサポート。

{{< /history >}}

`deployment_tier`キーワードを使用して、デプロイメント環境のプランを指定します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 次のいずれか:

- `production`
- `staging`
- `testing`
- `development`
- `other`
- [CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)（定義済みの変数、プロジェクト、グループ、インスタンスの変数、または`.gitlab-ci.yml`ファイルで定義された変数を含む）。`script`セクションで定義された変数は使用できません。

**Example of `environment:deployment_tier`**（の例）:

```yaml
deploy:
  script: echo
  environment:
    name: customer-portal
    deployment_tier: production
```

**Additional details**（補足情報）:

- このジョブ定義から作成された環境には、この値に基づいて[プラン](../environments/_index.md#deployment-tier-of-environments)が割り当てられます。
- この値が後で追加された場合、既存の環境のプランは更新されません。既存の環境のプランを更新するには、[Environments API](../../api/environments.md#update-an-existing-environment)を使用する必要があります。

**Related topics**（関連トピック）:

- [環境のデプロイプラン](../environments/_index.md#deployment-tier-of-environments)。

---

#### 動的環境 {#dynamic-environments}

CI/CD[変数](../variables/_index.md)を使用して、環境名を動的に指定します。

例: 

```yaml
deploy as review app:
  stage: deploy
  script: make deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_ENVIRONMENT_SLUG.example.com/
```

`deploy as review app`ジョブは、`review/$CI_COMMIT_REF_SLUG`環境を動的に作成するためのデプロイとしてマークされます。`$CI_COMMIT_REF_SLUG`は、Runnerによって設定される[CI/CD変数](../variables/_index.md)です。`$CI_ENVIRONMENT_SLUG`変数は環境名に基づいていますが、URLに含めるのに適しています。`pow`というブランチで`deploy as review app`ジョブが実行される場合、この環境は`https://review-pow.example.com/`のようなURLでアクセスできるようになります。

一般的なユースケースは、ブランチの動的環境を作成し、それらをレビューアプリとして使用することです。レビューアプリの使用例は、<https://gitlab.com/gitlab-examples/review-apps-nginx/>で確認できます。

---

### `extends` {#extends}

`extends`を使用して、設定セクションを再利用します。これは[YAMLアンカー](yaml_optimization.md#anchors)の代替手段であり、わずかに柔軟性が高く、読みやすくなっています。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- パイプライン内の別のジョブの名前。
- パイプライン内の他のジョブの名前のリスト（配列）。

**Example of `extends`**（の例）:

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

この例では、`rspec`ジョブが`.tests`テンプレートジョブの設定を使用します。パイプラインの作成時に、GitLabは次の処理を行います:

- キーに基づいて逆ディープマージを実行します。
- `.tests`の内容を`rspec`ジョブとマージします。
- キーの値はマージしません。

結合された設定は、以下のジョブと同等です:

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

**Additional details**（補足情報）:

- `extends`には複数の親を使用できます。
- `extends`キーワードは最大11レベルの継承をサポートしていますが、4レベル以上を使用することは避けてください。
- 前述の例では、`.tests`は[非表示ジョブ](../jobs/_index.md#hide-a-job)ですが、通常のジョブから設定を拡張することもできます。

**Related topics**（関連トピック）:

- [`extends`を使用して設定セクションを再利用する](yaml_optimization.md#use-extends-to-reuse-configuration-sections)。
- `extends`を使用して、[インクルードされた設定ファイル](yaml_optimization.md#use-extends-and-include-together)の設定を再利用する。

---

### `hooks` {#hooks}

{{< history >}}

- GitLab 15.6で`ci_hooks_pre_get_sources_script`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/356850)されました。デフォルトでは無効になっています。
- GitLab 15.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/381840)になりました。機能フラグ`ci_hooks_pre_get_sources_script`は削除されました。

{{< /history >}}

`hooks`を使用して、ジョブ実行の特定のステージ（Gitリポジトリを取得する前など）で、Runnerで実行するコマンドのリストを指定します。

ジョブの設定とデフォルトの設定は、一緒にマージされません。パイプラインに[`default:hooks`](#default)が定義されていて、ジョブにも`hooks`がある場合、ジョブの設定が優先され、デフォルトの設定は使用されません。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- フックとそのコマンドのハッシュ。利用可能なフック: `pre_get_sources_script`。

---

#### `hooks:pre_get_sources_script` {#hookspre_get_sources_script}

{{< history >}}

- GitLab 15.6で`ci_hooks_pre_get_sources_script`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/356850)されました。デフォルトでは無効になっています。
- GitLab 15.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/381840)になりました。機能フラグ`ci_hooks_pre_get_sources_script`は削除されました。

{{< /history >}}

`hooks:pre_get_sources_script`を使用して、Gitリポジトリとサブモジュールをクローンする前にRunnerで実行するコマンドのリストを指定します。たとえば、次のような用途に使用できます:

- [Git設定](../jobs/job_troubleshooting.md#get_sources-job-section-fails-because-of-an-http2-problem)を調整する。
- [トレーシング変数](../../topics/git/troubleshooting_git.md#debug-git-with-traces)をエクスポートする。

**Supported values**（サポートされている値）: 次の内容を含む配列:

- 1行のコマンド。
- [複数行に分割された](script.md#split-long-commands)長いコマンド。
- [YAMLアンカー](yaml_optimization.md#yaml-anchors-for-scripts)。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**Example of `hooks:pre_get_sources_script`**（の例）:

```yaml
job1:
  hooks:
    pre_get_sources_script:
      - echo 'hello job1 pre_get_sources_script'
  script: echo 'hello job1 script'
```

**Related topics**（関連トピック）:

- [GitLab Runnerの設定](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)

---

### `identity` {#identity}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 16.9で`google_cloud_support_feature_flag`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142054)されました。この機能は[ベータ版](../../policy/development_stages_support.md)です。
- GitLab 17.1の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472)になりました。機能フラグ`google_cloud_support_feature_flag`は削除されました。

{{< /history >}}

この機能は[ベータ版](../../policy/development_stages_support.md)です。

`identity`を使用して、アイデンティティフェデレーションを使用したサードパーティサービスの認証を行います。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default:`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 識別子。サポートされているプロバイダーは以下のとおりです:

- `google_cloud`: Google Cloud。[Google Cloud IAMインテグレーション](../../integration/google_cloud_iam.md)を使用して設定する必要があります。

**Example of `identity`**（の例）:

```yaml
job_with_workload_identity:
  identity: google_cloud
  script:
    - gcloud compute instances list
```

**Related topics**（関連トピック）:

- [Workload Identity連携](https://cloud.google.com/iam/docs/workload-identity-federation)。
- [Google Cloud IAMインテグレーション](../../integration/google_cloud_iam.md)。

---

### `id_tokens` {#id_tokens}

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/356986)されました。

{{< /history >}}

`id_tokens`を使用して、サードパーティサービスで認証するための[IDトークン](../secrets/id_token_authentication.md)を作成します。この方法で作成されたすべてのJSON Webトークンは、OIDC認証をサポートしています。JSON Webトークンの`aud`クレームを設定するために、必須のサブキーワード`aud`を使用します。

ジョブの設定とデフォルトの設定は、一緒にマージされません。パイプラインに[`default:id_tokens`](#default)が定義されていて、ジョブにも`id_tokens`がある場合、ジョブの設定が優先され、デフォルトの設定は使用されません。

**Supported values**（サポートされている値）: 

- トークン名と、その`aud`クレーム。`aud`では以下がサポートされています:
  - 単一の文字列。
  - 文字列の配列。
  - [CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**Example of `id_tokens`**（の例）:

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

**Related topics**（関連トピック）:

- [IDトークン認証](../secrets/id_token_authentication.md)。
- [クラウドサービスに接続する](../cloud_services/_index.md)。
- [キーレス署名にSigstoreを使用する](signing_examples.md)。

---

### `image` {#image}

`image`を使用して、ジョブが実行されるDockerイメージを指定します。

ジョブの設定とデフォルトの設定は、一緒にマージされません。パイプラインに[`default:image`](#default)が定義されていて、ジョブにも`image`がある場合、ジョブの設定が優先され、デフォルトの設定は使用されません。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: イメージ名（必要に応じてレジストリパスを含む）。次のいずれかの形式で指定します:

- `<image-name>`（`<image-name>`に`latest`タグを付けた場合と同じ）
- `<image-name>:<tag>`
- `<image-name>@<digest>`

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**Example of `image`**（の例）:

```yaml
default:
  image: ruby:3.0

rspec:
  script: bundle exec rspec

rspec 2.7:
  image: registry.example.com/my-group/my-project/ruby:2.7
  script: bundle exec rspec
```

この例では、`ruby:3.0`イメージがパイプライン内のすべてのジョブに対するデフォルトです。`rspec 2.7`ジョブは、ジョブ固有の`image`セクションでデフォルトをオーバーライドするため、デフォルトを使用しません。

**Additional details**（補足情報）:

- `image`を`default`セクションではなくトップレベルで使用することは、[非推奨](deprecated_keywords.md#globally-defined-image-services-cache-before_script-after_script)です。

**Related topics**（関連トピック）:

- [DockerコンテナでCI/CDジョブを実行する](../docker/using_docker_images.md)。

---

#### `image:name` {#imagename}

ジョブが実行されるDockerイメージの名前。[`image`](#image)を単独で使用した場合と同様に機能します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: イメージ名（必要に応じてレジストリパスを含む）。次のいずれかの形式で指定します:

- `<image-name>`（`<image-name>`に`latest`タグを付けた場合と同じ）
- `<image-name>:<tag>`
- `<image-name>@<digest>`

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**Example of `image:name`**（の例）:

```yaml
test-job:
  image:
    name: "registry.example.com/my/image:latest"
  script: echo "Hello world"
```

**Related topics**（関連トピック）:

- [DockerコンテナでCI/CDジョブを実行する](../docker/using_docker_images.md)。

---

#### `image:entrypoint` {#imageentrypoint}

コンテナのエントリポイントとして実行するコマンドまたはスクリプト。

Dockerコンテナの作成時に、`entrypoint`はDockerの`--entrypoint`オプションに変換されます。構文は[Dockerfileの`ENTRYPOINT`ディレクティブ](https://docs.docker.com/reference/dockerfile/#entrypoint)に似ており、各Shellトークンは配列内の個別の文字列です。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- 文字列。

**Example of `image:entrypoint`**（の例）:

```yaml
test-job:
  image:
    name: super/sql:experimental
    entrypoint: [""]
  script: echo "Hello world"
```

**Related topics**（関連トピック）:

- [イメージのエントリポイントをオーバーライドする](../docker/using_docker_images.md#override-the-entrypoint-of-an-image)。

---

#### `image:docker` {#imagedocker}

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27919)されました。GitLab Runner 16.7以降が必要です。
- `user`インプットオプションは、GitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137907)されました。

{{< /history >}}

`image:docker`を使用して、[Docker executor](https://docs.gitlab.com/runner/executors/docker.html)または[Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/)を使用してRunnerにオプションを渡します。このキーワードは、他のexecutorタイプでは機能しません。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

Docker executorのオプションを定義するハッシュ。以下を含めることができます:

- `platform`: プルするイメージのアーキテクチャを選択します。指定しない場合、デフォルトはホストRunnerと同じプラットフォームです。
- `user`: コンテナの実行時に使用するユーザー名またはUIDを指定します。

**Example of `image:docker`**（の例）:

```yaml
arm-sql-job:
  script: echo "Run sql tests"
  image:
    name: super/sql:experimental
    docker:
      platform: arm64/v8
      user: dave
```

**Additional details**（補足情報）:

- `image:docker:platform`は、[`docker pull --platform`オプション](https://docs.docker.com/reference/cli/docker/image/pull/#options)にマップされます。
- `image:docker:user`は、[`docker run --user`オプション](https://docs.docker.com/reference/cli/docker/container/run/#options)にマップされます。

---

#### `image:kubernetes` {#imagekubernetes}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38451)されました。GitLab Runner 17.11以降が必要です。
- `user`インプットオプションは、GitLab Runner 17.11で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5469)されました。
- `user`インプットオプションは、GitLab 18.0で[`uid:gid`形式をサポートするように拡張](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5540)されました。

{{< /history >}}

`image:kubernetes`を使用して、GitLab Runner [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/)にオプションを渡します。このキーワードは、他のexecutorタイプでは機能しません。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

Kubernetes executorのオプションを定義するハッシュ。以下を含めることができます:

- `user`: コンテナの実行時に使用するユーザー名またはUIDを指定します。`UID:GID`形式を使用して、GIDを設定することもできます。

**Example of `image:kubernetes` with only UID**（UIDのみを使用したの例）:

```yaml
arm-sql-job:
  script: echo "Run sql tests"
  image:
    name: super/sql:experimental
    kubernetes:
      user: "1001"
```

**Example of `image:kubernetes` with both UID and GID**（UIDとGIDの両方を使用したの例）:

```yaml
arm-sql-job:
  script: echo "Run sql tests"
  image:
    name: super/sql:experimental
    kubernetes:
      user: "1001:1001"
```

---

#### `image:pull_policy` {#imagepull_policy}

{{< history >}}

- GitLab 15.1で`ci_docker_image_pull_policy`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/21619)されました。デフォルトでは無効になっています。
- GitLab 15.2の[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)になりました。
- GitLab 15.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)になりました。[機能フラグ`ci_docker_image_pull_policy`](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)は削除されました。
- GitLab Runner 15.1以降が必要です。

{{< /history >}}

RunnerがDockerイメージをフェッチするために使用するプルポリシー。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- 1つのプルポリシー、または配列で指定する複数のプルポリシー。`always`、`if-not-present`、`never`のいずれかを指定できます。

**Examples of `image:pull_policy`**（の例）:

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

**Additional details**（補足情報）:

- 定義済みのプルポリシーをRunnerがサポートしていない場合、ジョブは次のようなエラーで失敗します: `ERROR: Job failed (system failure): the configured PullPolicies ([always]) are not allowed by AllowedPullPolicies ([never])`。

**Related topics**（関連トピック）:

- [DockerコンテナでCI/CDジョブを実行する](../docker/using_docker_images.md)。
- [Runnerがイメージをプルする方法を設定する](https://docs.gitlab.com/runner/executors/docker.html#configure-how-runners-pull-images)。
- [複数のプルポリシーを設定する](https://docs.gitlab.com/runner/executors/docker.html#set-multiple-pull-policies)。

---

### `inherit` {#inherit}

`inherit`を使用して、[デフォルトのキーワードと変数の継承を制御します](../jobs/_index.md#control-the-inheritance-of-default-keywords-and-variables)。

---

#### `inherit:default` {#inheritdefault}

`inherit:default`を使用して、[デフォルトのキーワード](#default)の継承を制御します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- `true`（デフォルト）、または`false`。すべてのデフォルトキーワードの継承を有効または無効にします。
- 継承する特定のデフォルトキーワードのリスト。

**Example of `inherit:default`**（の例）:

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

**Additional details**（補足情報）:

- 継承するデフォルトキーワードを1行で記述することもできます: `default: [keyword1, keyword2]`

---

#### `inherit:variables` {#inheritvariables}

`inherit:variables`を使用して、[デフォルト変数](#default-variables)のキーワードの継承を制御します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- `true`（デフォルト）、または`false`。すべてのデフォルト変数の継承を有効または無効にします。
- 継承する特定の変数のリスト。

**Example of `inherit:variables`**（の例）:

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

**Additional details**（補足情報）:

- 継承するデフォルト変数を1行で記述することもできます: `variables: [VARIABLE1, VARIABLE2]`

---

### `interruptible` {#interruptible}

{{< history >}}

- `trigger`ジョブのサポートは、GitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138508)されました。

{{< /history >}}

`interruptible`を使用して、[冗長なパイプラインを自動キャンセル](../pipelines/settings.md#auto-cancel-redundant-pipelines)機能を設定します。この機能は、新しいコミットに対して同じref上で新しいパイプラインが開始された場合、ジョブが完了する前にそのジョブをキャンセルします。この機能が無効になっている場合、このキーワードは効果がありません。新しいパイプラインは、新しい変更を含むコミットに対して開始されたものである必要があります。たとえば、UIで**新しいパイプライン**を選択して同じコミットに対してパイプラインを実行した場合、**冗長なパイプラインを自動キャンセル**機能は適用されません。

**冗長なパイプラインを自動キャンセル**機能の動作は[`workflow:auto_cancel:on_new_commit`](#workflowauto_cancelon_new_commit)設定で制御できます。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- `true`または`false`（デフォルト）。

**Example of `interruptible` with the default behavior**（デフォルトの動作を使用するの例）:

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

この例では、新しいパイプラインが実行中のパイプラインに次のような影響を及ぼします:

- `step-1`のみが実行中または保留中の場合は、キャンセルされます。
- `step-2`の開始後は、キャンセルされません。

**Example of `interruptible` with the `auto_cancel:on_new_commit:interruptible` setting**（設定を使用したの例）:

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

**Additional details**（補足情報）:

- ビルドジョブのように、ジョブを開始した後でもジョブを安全にキャンセルできる場合にのみ、`interruptible: true`を設定してください。部分的なデプロイを防ぐため、デプロイメントジョブは通常、キャンセルすべきではありません。
- デフォルトの動作（`workflow:auto_cancel:on_new_commit: conservative`）を使用する場合:
  - まだ開始されていないジョブは、ジョブの設定に関係なく常に`interruptible: true`と見なされます。`interruptible`設定は、ジョブの開始後にのみ考慮されます。
  - **実行中**のパイプラインがキャンセルされるのは、実行中のすべてのジョブで`interruptible: true`が設定されているか、`interruptible: false`が設定されたジョブが一度も開始されていない場合のみです。`interruptible: false`と指定されたジョブが開始されると、パイプライン全体が中断不可と見なされます。
  - パイプラインがダウンストリームパイプラインをトリガーした場合でも、ダウンストリームパイプライン内で`interruptible: false`が設定されたジョブがまだ開始されていなければ、ダウンストリームパイプラインもキャンセルされます。
- `interruptible: false`が設定されたオプションの手動ジョブをパイプラインの最初のステージに追加すると、ユーザーがパイプラインの自動キャンセルを手動で防止できるようになります。ユーザーがこのジョブを開始すると、**冗長なパイプラインを自動キャンセル**機能でそのパイプラインをキャンセルすることはできません。
- [トリガージョブ](#trigger)で`interruptible`を使用する場合:
  - トリガーされたダウンストリームパイプラインは、トリガージョブの`interruptible`設定の影響を受けません。
  - [`workflow:auto_cancel`](#workflowauto_cancelon_new_commit)が`conservative`に設定されている場合、トリガージョブの`interruptible`設定は無効です。
  - [`workflow:auto_cancel`](#workflowauto_cancelon_new_commit)が`interruptible`に設定されている場合、`interruptible: true`が設定されたトリガージョブは自動キャンセルできます。

---

### `needs` {#needs}

`needs`を使用して、ジョブを順不同で実行します。`needs`を使用するジョブ間の関係は、[有向非巡回グラフ](needs.md)として視覚化できます。

ステージの順序を無視して、他のジョブの完了を待たずに一部のジョブを実行できます。複数のステージのジョブを同時に実行できます。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- ジョブの配列（最大で50のジョブを指定可能）。
- 空の配列（`[]`）。パイプラインの作成後、すぐにジョブを開始するために設定します。

**Example of `needs`**（の例）:

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

この例では、4つの実行パスを作成します:

- Linter: `lint`ジョブは、ニーズがないため（`needs: []`）、`build`ステージの完了を待たずにすぐ実行されます。
- Linuxパス: `linux:rspec`ジョブは、`mac:build`の完了を待たずに、`linux:build`ジョブが完了するとすぐに実行されます。
- macOSパス: `mac:rspec`ジョブは、`linux:build`の完了を待たずに、`mac:build`ジョブの完了後すぐに実行されます。
- `production`ジョブは、それ以前のすべてのジョブ（`lint`、`linux:build`、`linux:rspec`、`mac:build`、`mac:rspec`）の完了後すぐに実行されます。

**Additional details**（補足情報）:

- 単一のジョブが`needs`配列に指定できるジョブの最大数には、次の制限があります:
  - GitLab.comの場合、上限は50です。詳細については、[イシュー350398](https://gitlab.com/gitlab-org/gitlab/-/issues/350398)を参照してください。
  - GitLab Self-ManagedおよびGitLab Dedicatedのデフォルトの制限は、50です。この制限は、[管理者エリアでCI/CDの制限を更新する](../../administration/settings/continuous_integration.md#set-cicd-limits)ことで変更できます。
- `needs`が[`parallel`](#parallel)キーワードを使用するジョブを参照している場合、それは1つのジョブだけでなく、並列に作成されるすべてのジョブに依存します。また、デフォルトでは、すべての並列ジョブからアーティファクトをダウンロードします。同じ名前のアーティファクトがある場合、上書きすることになり、最後にダウンロードしたアーティファクトだけが保存されます。
  - `needs`に（並列ジョブのすべてではなく）並列ジョブの一部のみを参照させるには、[`needs:parallel:matrix`](#needsparallelmatrix)キーワードを使用します。
- 設定対象のジョブと同じステージのジョブを参照できます。
- `needs`が`only`、`except`、`rules`の条件によりパイプラインに追加されない可能性があるジョブを参照する場合、パイプラインの作成に失敗する可能性があります。このパイプライン作成の失敗を解決するには、[`needs:optional`](#needsoptional)キーワードを使用します。
- パイプラインに`needs: []`を指定したジョブと[`.pre`](#stage-pre)ステージのジョブがある場合、これらはすべてパイプラインの作成直後に開始されます。`needs: []`を指定したジョブはすぐに開始され、`.pre`ステージのジョブもすぐに開始されます。

---

#### `needs:artifacts` {#needsartifacts}

ジョブで`needs`を使用すると、デフォルトでは、それ以前のステージからすべてのアーティファクトをダウンロードすることはなくなります。`needs`を指定したジョブは、それ以前のステージの完了前に開始される可能性があるからです。`needs`を使用する場合、`needs`の設定で指定したジョブからのみアーティファクトをダウンロードできます。

`needs`を使用するジョブでアーティファクトをダウンロードするタイミングを制御するには、`artifacts: true`（デフォルト）または`artifacts: false`を使用します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。`needs:job`と一緒に使用する必要があります。

**Supported values**（サポートされている値）: 

- `true`（デフォルト）または`false`。

**Example of `needs:artifacts`**（の例）:

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

この例では:

- `test-job1`ジョブは`build_job1`のアーティファクトをダウンロードします。
- `test-job2`ジョブは`build_job2`のアーティファクトをダウンロードしません。
- `test-job3`ジョブは、3つの`build_jobs`すべてからアーティファクトをダウンロードします。必要なすべてのジョブで、`artifacts`に`true`が指定されているか、またはデフォルトで`true`になっているためです。

**Additional details**（補足情報）:

- 同じジョブの中で`needs`を[`dependencies`](#dependencies)と組み合わせて使用しないでください。

---

#### `needs:project` {#needsproject}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`needs:project`を使用して、他のパイプライン内の最大5つのジョブからアーティファクトをダウンロードします。アーティファクトは、指定されたref上で最後に成功した指定ジョブからダウンロードされます。複数のジョブを指定するには、`needs`キーワードの下にそれぞれ個別の配列項目として追加します。

指定されたrefに対して実行中のパイプラインがある場合、`needs:project`を使用するジョブはそのパイプラインの完了を待機しません。代わりに、指定されたジョブの最後に成功した実行結果からアーティファクトをダウンロードします。

`needs:project`は、`job`、`ref`、`artifacts`と一緒に使用する必要があります。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- `needs:project`: ネームスペースとグループを含む、プロジェクトのフルパス。
- `job`: アーティファクトのダウンロード元のジョブ。
- `ref`: アーティファクトのダウンロード元のref。
- `artifacts`: アーティファクトをダウンロードするには、`true`に設定する必要があります。

**Examples of `needs:project`**（の例）:

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

この例では、`build_job`は、`group/project-name`および`group/project-name-2`プロジェクトの`main`ブランチにおいて、最後に成功した`build-1`および`build-2`ジョブからアーティファクトをダウンロードします。

`needs:project`では[CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)を使用できます。次に例を示します:

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

**Additional details**（補足情報）:

- 現在のプロジェクト内の別のパイプラインからアーティファクトをダウンロードするには、`project`に現在のプロジェクトと同じ値を指定し、現在のパイプラインとは異なるrefを使用します。同じref上で複数のパイプラインが同時に実行されていると、アーティファクトが上書きされる可能性があります。
- パイプラインを実行するユーザーは、グループまたはプロジェクトに対して少なくともレポーターロールを付与されている必要があります。または、グループ/プロジェクトの表示レベルが公開でなければなりません。
- `needs:project`と[`trigger`](#trigger)は、同じジョブ内で併用できません。
- `needs:project`を使用して別のパイプラインからアーティファクトをダウンロードする場合、ジョブは必要なジョブが完了するのを待機しません。[`needs`を使用してジョブの完了を待機する](needs.md)動作は、同じパイプライン内のジョブに限定されます。そのため、ジョブがアーティファクトをダウンロードしようとする前に、他のパイプライン内の必要なジョブが完了していることを確認してください。
- [`parallel`](#parallel)で実行されるジョブからアーティファクトをダウンロードすることはできません。
- `project`、`job`、`ref`では[CI/CD変数](../variables/_index.md)をサポートしています。

**Related topics**（関連トピック）:

- [親子パイプライン](../pipelines/downstream_pipelines.md#parent-child-pipelines)間でアーティファクトをダウンロードするには、[`needs:pipeline:job`](#needspipelinejob)を使用します。

---

#### `needs:pipeline:job` {#needspipelinejob}

[子パイプライン](../pipelines/downstream_pipelines.md#parent-child-pipelines)は、親パイプラインまたは同じ親子パイプライン階層にある別の子パイプラインの正常に完了したジョブからアーティファクトをダウンロードできます。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- `needs:pipeline`: パイプラインID。同じ親子パイプライン階層に属するパイプラインである必要があります。
- `job`: アーティファクトのダウンロード元のジョブ。

**Example of `needs:pipeline:job`**（の例）:

- 親パイプライン（`.gitlab-ci.yml`）:

  ```yaml
  stages:
    - build
    - test

  create-artifact:
    stage: build
    script: echo "sample artifact" > artifact.txt
    artifacts:
      paths: [artifact.txt]

  child-pipeline:
    stage: test
    trigger:
      include: child.yml
      strategy: mirror
    variables:
      PARENT_PIPELINE_ID: $CI_PIPELINE_ID
  ```

- 子パイプライン（`child.yml`）:

  ```yaml
  use-artifact:
    script: cat artifact.txt
    needs:
      - pipeline: $PARENT_PIPELINE_ID
        job: create-artifact
  ```

この例では、親パイプライン内の`create-artifact`ジョブがアーティファクトを作成します。`child-pipeline`ジョブは子パイプラインをトリガーし、`CI_PIPELINE_ID`変数を新しい`PARENT_PIPELINE_ID`変数として子パイプラインに渡します。子パイプラインは、この変数を`needs:pipeline`に使用することで、親パイプラインからアーティファクトをダウンロードできます。後続のステージに`create-artifact`ジョブと`child-pipeline`ジョブを配置することで、`create-artifact`が正常に完了した場合にのみ`use-artifact`ジョブが実行されるようになります。

**Additional details**（補足情報）:

- `pipeline`属性は、現在のパイプラインID（`$CI_PIPELINE_ID`）を受け付けません。現在のパイプライン内のジョブからアーティファクトをダウンロードするには、[`needs:artifacts`](#needsartifacts)を使用します。
- `needs:pipeline:job`を[トリガージョブ](#trigger)で使用することはできず、[マルチプロジェクトパイプライン](../pipelines/downstream_pipelines.md#multi-project-pipelines)からアーティファクトをフェッチするために使用することもできません。マルチプロジェクトパイプラインからアーティファクトをフェッチするには、[`needs:project`](#needsproject)を使用します。
- `needs:pipeline:job`にリストされているジョブは、`success`で完了する必要があります。そうなっていない場合、アーティファクトをフェッチできません。[イシュー367229](https://gitlab.com/gitlab-org/gitlab/-/issues/367229)では、アーティファクトを持つ任意のジョブからアーティファクトをフェッチできるようにする提案がなされています。

---

#### `needs:optional` {#needsoptional}

パイプライン中に存在しないことのあるジョブを必須とするには、`needs`の設定に`optional: true`を追加します。定義されていない場合、`optional: false`がデフォルトです。

[`rules`](#rules) 、[`only`、または`except`](deprecated_keywords.md#only--except)を使用しているジョブや、[`include`](#include)によって追加されたジョブは、常にパイプラインに追加されるとは限りません。GitLabは、パイプラインを開始する前に`needs`の関係をチェックします:

- `needs`エントリに`optional: true`が設定され、必要なジョブがパイプラインに存在する場合、ジョブはその完了を待ってから開始します。
- 必要なジョブが存在しない場合、ジョブは他のすべてのneeds要件が満たされた時点で開始できます。
- `needs`セクションにオプションのジョブのみが含まれており、いずれもパイプラインに追加されていない場合、そのジョブはすぐに開始されます（空の`needs`エントリである`needs: []`を指定した場合と同じ）。
- 必要なジョブに`optional: false`が指定されているが、パイプラインに追加されなかった場合、パイプラインの開始は失敗し、次のようなエラーになります: `'job1' job needs 'job2' job, but it was not added to the pipeline`。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Example of `needs:optional`**（の例）:

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

この例では:

- `build-job`、`test-job1`、`test-job2`は、ステージの順に開始します。
- ブランチがデフォルトブランチの場合、`test-job2`がパイプラインに追加されるため、次のようになります:
  - `deploy-job`は、`test-job1`と`test-job2`の両方が完了するのを待機します。
  - `review-job`は、`test-job2`が完了するのを待機します。
- ブランチがデフォルトブランチでない場合、`test-job2`はパイプラインに追加されないため、次のようになります:
  - `deploy-job`は`test-job1`の完了のみを待機し、存在しない`test-job2`の完了は待機しません。
  - `review-job`には他に必要なジョブがないため、`needs: []`と同様に、すぐに（`build-job`と同時に）開始されます。

---

#### `needs:pipeline` {#needspipeline}

`needs:pipeline`キーワードを使用すると、アップストリームパイプラインからジョブにパイプラインのステータスをミラーリングできます。デフォルトブランチからの最新のパイプラインステータスが、ジョブにレプリケートされます。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- ネームスペースとグループを含む、プロジェクトのフルパス。プロジェクトが同じグループまたはネームスペースに含まれる場合は、`project`キーワードからそれらを省略できます。例: `project: group/project-name`または`project: project-name`。

**Example of `needs:pipeline`**（の例）:

```yaml
upstream_status:
  stage: test
  needs:
    pipeline: other/project
```

**Additional details**（補足情報）:

- `job`キーワードを`needs:pipeline`に追加すると、ジョブはパイプラインステータスをミラーリングしなくなります。動作は[`needs:pipeline:job`](#needspipelinejob)に変わります。

---

#### `needs:parallel:matrix` {#needsparallelmatrix}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/254821)されました。

{{< /history >}}

ジョブで[`parallel:matrix`](#parallelmatrix)を使用すれば、単一のパイプラインで1つのジョブを複数のインスタンスとして同時実行し、ジョブのインスタンスごとに異なる変数値を使用できます。

`needs:parallel:matrix`を使用して、複数の並列ジョブに応じてジョブを順不同で実行します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。`needs:job`と一緒に使用する必要があります。

**Supported values**（サポートされている値）: マトリックス識別子のハッシュの配列:

- 識別子と値は、`parallel:matrix`ジョブで定義された識別子と値から選択する必要があります。
- [行列式](matrix_expressions.md)を使用できます。

**Example of `needs:parallel:matrix`**（の例）:

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

前述の例では、次のジョブが生成されます:

```plaintext
linux:build: [aws, monitoring]
linux:build: [aws, app1]
linux:build: [aws, app2]
linux:rspec
```

`linux:rspec`ジョブは、`linux:build: [aws, app1]`ジョブが完了するとすぐに実行されます。

**Additional details**（補足情報）:

- `needs:parallel:matrix`のマトリックス変数の順序は、必要なジョブで定義されたマトリックス変数の順序と一致する必要があります。たとえば、前述の例の`linux:rspec`ジョブで、変数の順序を逆にすると無効になります:

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

**Related topics**（関連トピック）:

- [複数の並列ジョブが存在する状況でneedsを使用して特定の並列ジョブを指定する](../jobs/job_control.md#specify-a-parallelized-job-using-needs-with-multiple-parallelized-jobs)。
- [`needs:parallel:matrix`の行列式](matrix_expressions.md#matrix-expressions-in-needsparallelmatrix)。

### `pages` {#pages}

`pages`を使用して、静的コンテンツをGitLabにアップロードする[GitLab Pages](../../user/project/pages/_index.md)ジョブを定義します。コンテンツはウェブサイトとして公開されます。

次のことを行う必要があります:

- `pages: true`を定義し、`public`という名前のディレクトリを公開します。
- 別のコンテンツディレクトリを使用する場合は、代わりに[`pages.publish`](#pagespublish)を定義します。
- コンテンツディレクトリのルートに空ではない`index.html`ファイルを配置します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード、またはジョブ名（非推奨）。ジョブの一部としてのみ使用できます。

**Supported Values**（サポートされている値）:

- ブール値。`true`に設定すると、デフォルトの設定を使用します。
- 設定オプションのハッシュ。詳細については、この後のセクションを参照してください。

**Example of `pages`**（の例）:

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

この例では、`my-html-content/`ディレクトリの名前を`public/`に変更しています。このディレクトリはアーティファクトとしてエクスポートされ、GitLab Pagesで公開されます。

**Example using a configuration hash**（設定ハッシュを使用した例）:

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

この例では、ディレクトリは移動せず、`publish`プロパティを直接使用しています。また、このページデプロイが1週間後に非公開になるよう設定しています。

**Additional details**（補足情報）:

- `pages`をジョブ名として使用することは[非推奨](deprecated_keywords.md#publish-keyword-and-pages-job-name-for-gitlab-pages)です。
- Pagesのデプロイをトリガーせずに`pages`をジョブ名として使用するには、`pages`プロパティをfalseに設定します。

---

#### `pages.publish` {#pagespublish}

{{< history >}}

- GitLab 16.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/415821)されました。
- GitLab 17.9で、`publish`プロパティに渡す際に変数を利用できるように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/500000)されました。
- GitLab 17.9で、`publish`プロパティが`pages`キーワードの下に[移動](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)されました。
- GitLab 17.10で、`pages.publish`パスが`artifacts:paths`に自動的に[付加](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)されるようになりました。

{{< /history >}}

`pages.publish`を使用して、[`pages`ジョブ](#pages)のコンテンツディレクトリを設定します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。これは、`pages`ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: Pagesコンテンツを含むディレクトリのパス。[GitLab 17.10以降](https://gitlab.com/gitlab-org/gitlab/-/issues/428018)、これを指定しない場合、デフォルトの`public`ディレクトリが使用されます。指定した場合、そのパスが自動的に[`artifacts:paths`](#artifactspaths)に付加されます。

**Example of `pages.publish`**（の例）:

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

この例では、[Eleventy](https://www.11ty.dev)を使用して静的ウェブサイトを生成し、生成されたHTMLファイルを`dist/`ディレクトリに出力しています。このディレクトリはアーティファクトとしてエクスポートされ、GitLab Pagesで公開されます。

`pages.publish`フィールドでは変数も使用できます。例: 

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

**Additional details**（補足情報）:

- トップレベルキーワード`publish`は[非推奨](deprecated_keywords.md#publish-keyword-and-pages-job-name-for-gitlab-pages)となっており、現在は`pages`キーワードの下にネストされた状態にする必要があります。

---

#### `pages.path_prefix` {#pagespath_prefix}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: ベータ

{{< /details >}}

{{< history >}}

- GitLab 16.7で`pages_multiple_versions_setting`[フラグ](../../administration/feature_flags/_index.md)とともに[実験的機能](../../policy/development_stages_support.md)として[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129534)されました。デフォルトでは無効になっています。
- GitLab 17.4の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/422145)になりました。
- GitLab 17.8で、ピリオドを許可するように[変更](https://gitlab.com/gitlab-org/gitlab/-/issues/507423)されました。
- GitLab 17.9で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/487161)になりました。機能フラグ`pages_multiple_versions_setting`は削除されました。

{{< /history >}}

`pages.path_prefix`を使用して、GitLab Pagesの[並列デプロイ](../../user/project/pages/_index.md#parallel-deployments)のパスプレフィックスを設定します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。これは、`pages`ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- 文字列
- [CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)
- 両方の組み合わせ

指定された値は小文字に変換され、63バイトに短縮されます。英数字とピリオド以外の文字はすべてハイフンに置き換えられます。先頭および末尾にハイフンまたはピリオドを含めることはできません。

**Example of `pages.path_prefix`**（の例）:

```yaml
create-pages:
  stage: deploy
  script:
    - echo "Pages accessible through ${CI_PAGES_URL}"
  pages:  # specifies that this is a Pages job and publishes the default public directory
    path_prefix: "$CI_COMMIT_BRANCH"
```

この例では、ブランチごとに異なるページデプロイが作成されます。

---

#### `pages.expire_in` {#pagesexpire_in}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/456478)されました。
- 変数のサポートは、GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/492289)されました。

{{< /history >}}

`expire_in`を使用して、デプロイが期限切れになるまでの有効期間を指定します。デプロイが期限切れになると、10分ごとに実行されるcronジョブによって非アクティブ化されます。

デフォルトでは、[並列デプロイ](../../user/project/pages/_index.md#parallel-deployments)は24時間後に自動的に期限切れになります。この動作を無効にするには、値を`never`に設定します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。これは、`pages`ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 有効期間。単位が指定されていない場合は秒単位です。変数もサポートされています。有効な値の例は以下のとおりです:

- `'42'`
- `42 seconds`
- `3 mins 4 sec`
- `2 hrs 20 min`
- `2h20min`
- `6 mos 1 day`
- `47 yrs 6 mos and 4d`
- `3 weeks and 2 days`
- `never`
- `$DURATION`

**Example of `pages.expire_in`**（の例）:

```yaml
create-pages:
  stage: deploy
  script:
    - echo "Pages accessible through ${CI_PAGES_URL}"
  pages:  # specifies that this is a Pages job and publishes the default public directory
    expire_in: 1 week
```

---

### `parallel` {#parallel}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/336576)され、`parallel`の最大値が50から200に増加しました。

{{< /history >}}

`parallel`を使用して、1つのパイプラインで同じジョブを複数並列に実行します。

複数のRunnerが存在する必要があります。または、単一のRunnerが複数のジョブを同時に実行するよう設定されている必要があります。

並列ジョブには、`job_name 1/N`から`job_name N/N`までの連番の名前が付けられます。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- `1`から`200`までの数値。

**Example of `parallel`**（の例）:

```yaml
test:
  script: rspec
  parallel: 5
```

この例では、並列に実行される5つのジョブが作成され、それぞれ`test 1/5`から`test 5/5`という名前が付けられます。

**Additional details**（補足情報）:

- どの並列ジョブにも、`CI_NODE_INDEX`および`CI_NODE_TOTAL`という[定義済みのCI/CD変数](../variables/_index.md#predefined-cicd-variables)が設定されています。
- `parallel`を使用するジョブを含むパイプラインでは、次のような状況が発生する可能性があります:
  - 利用可能なRunner数を超える並列実行ジョブが作成されることがあります。超過したジョブはキューに入れられ、Runnerが利用可能になるまで待機している間、`pending`のマークが付けられます。
  - 作成するジョブが多すぎると、`job_activity_limit_exceeded`エラーが発生してパイプラインが失敗することがあります。アクティブなパイプラインで存在できるジョブの最大数は、[インスタンスレベルで制限](../../administration/instance_limits.md#number-of-jobs-in-active-pipelines)されています。

**Related topics**（関連トピック）:

- [大規模なジョブを並列化する](../jobs/job_control.md#parallelize-large-jobs)。

---

#### `parallel:matrix` {#parallelmatrix}

{{< history >}}

- GitLab 15.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/336576)され、順列の最大数が50から200に増加しました。

{{< /history >}}

`parallel:matrix`を使用して、1つのパイプラインで同じジョブを複数並列に実行し、ジョブのインスタンスごとに異なる変数値を指定します。

複数のRunnerが存在する必要があります。または、単一のRunnerが複数のジョブを同時に実行するよう設定されている必要があります。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 変数のハッシュの配列:

- 変数名になる行列識別子には、数字、文字、アンダースコア（`_`）のみを使用できます。
- 値は文字列、または文字列の配列でなければなりません。
- 順列の数は200以下でなければなりません。

**Example of `parallel:matrix`**（の例）:

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
      - PROVIDER: [gcp, vultr]
        STACK: [data, processing]
  environment: $PROVIDER/$STACK
```

この例では、`PROVIDER`と`STACK`の値が異なる7個の並列`deploystacks`ジョブが生成されます:

- `deploystacks: [aws, monitoring]`
- `deploystacks: [aws, app1]`
- `deploystacks: [aws, app2]`
- `deploystacks: [gcp, data]`
- `deploystacks: [gcp, processing]`
- `deploystacks: [vultr, data]`
- `deploystacks: [vultr, processing]`

**Additional details**（補足情報）:

- `parallel:matrix`ジョブでは、ジョブを互いに区別するためにジョブ名に変数の値を追加しますが、[値が長すぎると名前が制限を超える可能性があります](https://gitlab.com/gitlab-org/gitlab/-/issues/362262):
  - [ジョブ名](../jobs/_index.md#job-names)は255文字以下でなければなりません。
  - [`needs`](#needs)を使用する場合、ジョブ名は128文字以下でなければなりません。
- 同じ変数値で異なる変数名を指定して複数のマトリックス設定を作成することはできません。ジョブ名は変数名ではなく変数値から生成されるため、マトリックスエントリの値が同じなら、同一のジョブ名が生成されて互いに上書きすることになります。

  たとえば、次の`test`設定では、同一のジョブで構成される2つのシリーズを作成しようとしていますが、`OS2`バージョンのジョブが`OS`バージョンのジョブを上書きすることになります:

  ```yaml
  test:
    parallel:
      matrix:
        - OS: [ubuntu]
          PROVIDER: [aws, gcp]
        - OS2: [ubuntu]
          PROVIDER: [aws, gcp]
  ```

  - `parallel:matrix`とともに[`!reference`タグ](yaml_optimization.md#reference-tags)を使用する場合、[既知の問題](../debugging.md#config-should-be-an-array-of-hashes-error-message)があります。

**Related topics**（関連トピック）:

- [並列ジョブの1次元マトリックスを実行する](../jobs/job_control.md#run-a-one-dimensional-matrix-of-parallel-jobs)。
- [並列トリガージョブのマトリックスを実行する](../jobs/job_control.md#run-a-matrix-of-parallel-trigger-jobs)。
- [並列マトリックスジョブごとに異なるRunnerタグを選択する](../jobs/job_control.md#select-different-runner-tags-for-each-parallel-matrix-job)。
- [`needs:parallel:matrix`の行列式](matrix_expressions.md#matrix-expressions-in-needsparallelmatrix)。

---

### `release` {#release}

`release`を使用して、[リリース](../../user/project/releases/_index.md)を作成します。

このリリースジョブは、[`glab`CLI](https://gitlab.com/gitlab-org/cli)にアクセス可能でなければならず、そのパスが`$PATH`に含まれていなければなりません。

[Docker executor](https://docs.gitlab.com/runner/executors/docker.html)を使用する場合は、次のGitLabコンテナレジストリにあるDockerイメージを使用できます: `registry.gitlab.com/gitlab-org/cli:latest`

[Shell executor](https://docs.gitlab.com/runner/executors/shell.html)などを使用する場合は、Runnerが登録されているサーバーに[`glab`CLIをインストールします](https://gitlab.com/gitlab-org/cli#installation)。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: `release`サブキー:

- [`tag_name`](#releasetag_name)
- [`tag_message`](#releasetag_message)（オプション）
- [`name`](#releasename)（オプション）
- [`description`](#releasedescription)
- [`ref`](#releaseref)（オプション）
- [`milestones`](#releasemilestones)（オプション）
- [`released_at`](#releasereleased_at)（オプション）
- [`assets:links`](#releaseassetslinks)（オプション）

**Example of `release` keyword**（キーワードの例）:

```yaml
release_job:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:latest
  rules:
    - if: $CI_COMMIT_TAG                  # Run this job when a tag is created manually
  script:
    - echo "Running the release job."
  release:
    tag_name: $CI_COMMIT_TAG
    name: 'Release $CI_COMMIT_TAG'
    description: 'Release created using the CLI.'
```

この例では、次のタイミングでリリースを作成します:

- Gitタグをプッシュしたとき。
- UIで**コード** > **タグ**からGitタグ付けを追加したとき。

**Additional details**（補足情報）:

- [トリガー](#trigger)ジョブを除くすべてのリリースジョブには、`script`キーワードを含める必要があります。リリースジョブでは、スクリプト型コマンドからの出力を使用できます。スクリプトが不要な場合は、次のようにプレースホルダーを使用できます:

  ```yaml
  script:
    - echo "release job"
  ```

  この要件を削除するための[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/223856)が存在します。

- `release`セクションは、`script`キーワードの後、`after_script`の前に実行されます。
- リリースが作成されるのは、ジョブのメインスクリプトが成功した場合のみです。
- 同じリリースがすでに存在する場合、そのリリースは更新されず、`release`キーワードを含むジョブは失敗します。

**Related topics**（関連トピック）:

- [`release`キーワードのCI/CDの例](../../user/project/releases/_index.md#creating-a-release-by-using-a-cicd-job)。
- [単一のパイプラインで複数のリリースを作成する](../../user/project/releases/_index.md#create-multiple-releases-in-a-single-pipeline)。
- [カスタムSSL CA認証局を使用する](../../user/project/releases/_index.md#use-a-custom-ssl-ca-certificate-authority)。

---

#### `release:tag_name` {#releasetag_name}

必須。リリースのGitタグです。

このタグがまだプロジェクト内に存在しない場合、リリースの作成と同時にタグも作成されます。新しいタグは、パイプラインに関連付けられたSHAを使用します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- タグ名。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**Example of `release:tag_name`**（の例）:

新しいタグがプロジェクトに追加された時点でリリースを作成するには、次のようにします:

- `tag_name`としてCI/CD変数`$CI_COMMIT_TAG`を使用します。
- [`rules:if`](#rulesif)を使用して、新しいタグに対してのみジョブを実行するよう設定します。

```yaml
job:
  script: echo "Running the release job for the new tag."
  release:
    tag_name: $CI_COMMIT_TAG
    description: 'Release description'
  rules:
    - if: $CI_COMMIT_TAG
```

リリースと新しいタグを同時に作成するには、新しいタグに対してのみジョブが実行されるように[`rules`](#rules)を設定**not**（しないでください）。セマンティックバージョニングの例を以下に示します:

```yaml
job:
  script: echo "Running the release job and creating a new tag."
  release:
    tag_name: ${MAJOR}_${MINOR}_${REVISION}
    description: 'Release description'
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

---

#### `release:tag_message` {#releasetag_message}

タグが存在しない場合、新しく作成されるタグには、`tag_message`で指定されているメッセージが注釈として付けられます。省略した場合、軽量タグが作成されます。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- テキスト文字列。

**Example of `release:tag_message`**（の例）:

```yaml
  release_job:
    stage: release
    release:
      tag_name: $CI_COMMIT_TAG
      description: 'Release description'
      tag_message: 'Annotated tag message'
```

---

#### `release:name` {#releasename}

リリース名。省略した場合、`release: tag_name`の値が入力されます。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- テキスト文字列。

**Example of `release:name`**（の例）:

```yaml
  release_job:
    stage: release
    release:
      name: 'Release $CI_COMMIT_TAG'
```

---

#### `release:description` {#releasedescription}

リリースの長い説明。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- 長い説明の文字列。
- 説明を含むファイルのパス。
  - そのファイルの場所は、プロジェクトディレクトリ（`$CI_PROJECT_DIR`）からの相対パスでなければなりません。
  - ファイルがシンボリックリンクの場合、`$CI_PROJECT_DIR`内に存在する必要があります。
  - `./path/to/file`とファイル名にスペースを含めることはできません。

**Example of `release:description`**（の例）:

```yaml
job:
  release:
    tag_name: ${MAJOR}_${MINOR}_${REVISION}
    description: './path/to/CHANGELOG.md'
```

**Additional details**（補足情報）:

- `description`は、`glab`を実行するShellによって評価されます。説明の定義にはCI/CD変数を使用できますが、一部のShellでは変数を参照するための[構文が異なることがあります](../variables/job_scripts.md)。同様に、Shellによっては特殊文字をエスケープする必要があります。たとえば、バッククォート（`` ` ``）をバックスラッシュ（` \ `）でエスケープしなければならない場合があります。

---

#### `release:ref` {#releaseref}

`release: tag_name`がまだ存在しない場合に使用されるリリースの`ref`です。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- コミットSHA、別のタグ名、またはブランチ名。

---

#### `release:milestones` {#releasemilestones}

リリースが関連付けられている各マイルストーンのタイトル。

---

#### `release:released_at` {#releasereleased_at}

リリースが準備完了になる日時。

**Supported values**（サポートされている値）: 

- ISO 8601形式の日付（引用符で囲む）。

**Example of `release:released_at`**（の例）:

```yaml
released_at: '2021-03-15T08:00:00Z'
```

**Additional details**（補足情報）:

- 定義されていない場合は、現在の日時が使用されます。

---

#### `release:assets:links` {#releaseassetslinks}

`release:assets:links`を使用して、リリースに[アセットリンク](../../user/project/releases/release_fields.md#release-assets)を含めます。

**Example of `release:assets:links`**（の例）:

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

---

### `resource_group` {#resource_group}

`resource_group`を使用して、同じプロジェクトの異なるパイプライン間で、ジョブが相互に排他的に実行されるようにするための[リソースグループ](../resource_groups/_index.md)を作成します。

たとえば、同じリソースグループに属する複数のジョブが同時にキューに登録された場合、それらのジョブのうち1つだけが開始されます。その他のジョブは、`resource_group`が解放されるまで待機します。

リソースグループの動作は、他のプログラミング言語におけるセマフォに似ています。

[処理モード](../resource_groups/_index.md#process-modes)を選択することで、デプロイの設定に応じてジョブの並行処理を戦略的に制御できます。デフォルトの処理モードは`unordered`です。リソースグループの処理モードを変更するには、[API](../../api/resource_groups.md#edit-an-existing-resource-group)を使用して、既存のリソースグループを編集するリクエストを送信します。

環境ごとに複数のリソースグループを定義できます。たとえば、物理デバイスにデプロイする場合、複数の物理デバイスが存在するかもしれません。各デバイスにデプロイすることは可能ですが、1つのデバイスに対して実行できるデプロイは常に1件だけです。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- 英字、数字、`-`、`_`、`/`、`$`、`{`、`}`、`.`、およびスペースのみ。`/`は先頭にも末尾にも使用できません。CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**Example of `resource_group`**（の例）:

```yaml
deploy-to-production:
  script: deploy
  resource_group: production
```

この例では、2つの異なるパイプライン内にある2つの`deploy-to-production`ジョブを同時に実行することは決してできません。これにより、本番環境への同時デプロイが決して発生しないよう制御できます。

**Related topics**（関連トピック）:

- [クロスプロジェクト/親子パイプラインによるパイプラインレベルの並行処理制御](../resource_groups/_index.md#pipeline-level-concurrency-control-with-cross-projectparent-child-pipelines)。

---

### `retry` {#retry}

`retry`を使用して、ジョブが失敗した場合に再試行する回数を設定します。定義されていない場合、デフォルトは`0`になり、ジョブは再試行されません。

ジョブが失敗すると、成功するか最大再試行回数に達するまで、最大であと2回処理が繰り返されます。

デフォルトでは、すべてのタイプの失敗でジョブが再試行されます。再試行の対象となる失敗を選択するには、[`retry:when`](#retrywhen)または[`retry:exit_codes`](#retryexit_codes)を使用します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- `0`（デフォルト）、`1`、または`2`。

**Example of `retry`**（の例）:

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

終了コードが`137`の場合、またはRunnerのシステムエラーが発生した場合、`test_advanced`は最大2回まで再試行されます。

---

#### `retry:when` {#retrywhen}

`retry:when`は、`retry:max`と組み合わせて使用し、失敗の特定のケースでのみジョブを再試行します。`retry:max`は、[`retry`](#retry)と同様に最大再試行回数であり、指定できる値は`0`、`1`、または`2`です。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- 単一の失敗タイプ、または1つ以上の失敗タイプの配列:

<!--
  If you change any of the following values, make sure to update the `RETRY_WHEN_IN_DOCUMENTATION`
  array in `spec/lib/gitlab/ci/config/entry/retry_spec.rb`.
  The test there makes sure that all documented
  values are valid as a configuration option and therefore should always
  stay in sync with this documentation.
-->

- `always`: あらゆる失敗時に再試行します（デフォルト）。
- `unknown_failure`: 失敗の理由が不明な場合に再試行します。
- `script_failure`: 次のいずれかの場合に再試行します:
  - スクリプトが失敗した。
  - RunnerがDockerイメージのプルに失敗した。[executor](https://docs.gitlab.com/runner/executors/)が`docker`、`docker+machine`、`kubernetes`の場合。
- `api_failure`: APIの失敗時に再試行します。
- `stuck_or_timeout_failure`: ジョブがスタックした場合、またはタイムアウトした場合に再試行します。
- `runner_system_failure`: Runnerのシステムエラーが発生した場合（ジョブのセットアップの失敗など）に再試行します。
- `runner_unsupported`: Runnerがサポートされていない場合に再試行します。
- `stale_schedule`: 遅延ジョブを実行できなかった場合に再試行します。
- `job_execution_timeout`: ジョブに対して設定されている最大実行時間をスクリプトが超過した場合に再試行します。
- `archived_failure`: ジョブがアーカイブされていて実行できない場合に再試行します。
- `unmet_prerequisites`: ジョブの前提条件タスクが正常に完了しなかった場合に再試行します。
- `scheduler_failure`: スケジューラーがジョブをRunnerに割り当てられなかった場合に再試行します。
- `data_integrity_failure`: ジョブで不明な問題が発生した場合に再試行します。

**Example of `retry:when`**（単一の失敗タイプ）:

```yaml
test:
  script: rspec
  retry:
    max: 2
    when: runner_system_failure
```

Runnerのシステムエラー以外の失敗が発生した場合、このジョブは再試行されません。

**Example of `retry:when`**（複数の失敗タイプの配列）:

```yaml
test:
  script: rspec
  retry:
    max: 2
    when:
      - runner_system_failure
      - stuck_or_timeout_failure
```

---

#### `retry:exit_codes` {#retryexit_codes}

{{< history >}}

- GitLab 16.10で`ci_retry_on_exit_codes`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/430037)されました。デフォルトでは無効になっています。
- GitLab 16.11の[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/430037)になりました。
- GitLab 17.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/452412)になりました。機能フラグ`ci_retry_on_exit_codes`は削除されました。

{{< /history >}}

`retry:exit_codes`は、`retry:max`と組み合わせて使用し、失敗の特定のケースでのみジョブを再試行します。`retry:max`は、[`retry`](#retry)と同様に最大再試行回数であり、指定できる値は`0`、`1`、または`2`です。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- 1つの終了コード。
- 終了コードの配列。

**Example of `retry:exit_codes`**（の例）:

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

**Related topics**（関連トピック）:

変数を使用して、[ジョブ実行の特定のステージに対する再試行回数](../runners/configure_runners.md#job-stages-attempts)を指定できます。

---

### `rules` {#rules}

`rules`を使用して、パイプラインにジョブを含めたり除外したりすることができます。

パイプラインの作成時にルールが評価され、順番に評価されます。一致するルールが見つかると、それ以降のルールはチェックされず、設定に応じてジョブがパイプラインに含まれるか除外されます。どのルールにも一致しなかった場合、ジョブはパイプラインに追加されません。

`rules`はルールの配列を受け入れます。各ルールには、少なくとも以下のいずれか1つを含める必要があります:

- `if`
- `changes`
- `exists`
- `when`

必要に応じて、以下を組み合わせることもできます:

- `allow_failure`
- `needs`
- `variables`
- `interruptible`

複数のキーワードを組み合わせて、[複雑なルール](../jobs/job_rules.md#complex-rules)を作成することもできます。

ジョブがパイプラインに追加されるのは次の場合です:

- `if`、`changes`、または`exists`のルールに一致し、かつ、そのルールが`when: on_success`（定義されていない場合のデフォルト）、`when: delayed`、または`when: always`により設定されている場合。
- `when: on_success`、`when: delayed`、または`when: always`のみで構成されたルールに到達した場合。

ジョブがパイプラインに追加されないのは次の場合です:

- どのルールにも一致しなかった場合。
- ルールに一致し、かつ`when: never`が指定されている場合。

その他の例については、[`rules`でジョブの実行タイミングを指定する](../jobs/job_rules.md)を参照してください。

---

#### `rules:if` {#rulesif}

`rules:if`句を使用して、ジョブをパイプラインに追加する条件を指定します:

- `if`ステートメントがtrueの場合、ジョブをパイプラインに追加します。
- `if`ステートメントがtrueでも、`when: never`と組み合わされている場合、ジョブをパイプラインに追加しません。
- `if`ステートメントがfalseの場合、次の`rules`項目（他に存在する場合）をチェックします。

`if`句は次のように評価されます:

- [CI/CD変数](../variables/_index.md)または[定義済みCI/CD変数](../variables/predefined_variables.md)の値に基づいて評価される（[一部例外](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)あり）。
- [`rules`の実行フロー](#rules)に従って、順番に評価される。

**Keyword type**（キーワードのタイプ）: ジョブ固有およびパイプライン固有。ジョブの一部として使用してジョブの動作を設定するか、または[`workflow`](#workflow)とともに使用してパイプラインの動作を設定できます。

**Supported values**（サポートされている値）: 

- [CI/CD変数式](../jobs/job_rules.md#cicd-variable-expressions)。

**Example of `rules:if`**（の例）:

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

**Additional details**（補足情報）:

- [ネストされた変数](../variables/where_variables_can_be_used.md#nested-variable-expansion)を`if`で使用することはできません。詳細については、[イシュー327780](https://gitlab.com/gitlab-org/gitlab/-/issues/327780)を参照してください。
- ルールが一致し、かつ`when`が定義されていない場合、ルールはジョブで定義されている`when`を使用します。ジョブにも定義されていない場合のデフォルトは`on_success`です。
- [ジョブレベルの`when`とルール内の`when`を組み合わせる](https://gitlab.com/gitlab-org/gitlab/-/issues/219437)ことができます。`rules`内の`when`の設定がジョブレベルの`when`よりも優先されます。
- [`script`](../variables/job_scripts.md)セクションの変数とは異なり、ルール式内の変数は常に`$VARIABLE`形式です。
  - `rules:if`と`include`を組み合わせて使用すると、[他の設定ファイルを条件付きでインクルードできます](includes.md#use-rules-with-include)。
- `=~`式と`!~`式の右辺にあるCI/CD変数は、[正規表現として評価されます](../jobs/job_rules.md#store-a-regular-expression-in-a-variable)。

**Related topics**（関連トピック）:

- [`rules`の一般的な`if`式](../jobs/job_rules.md#common-if-clauses-with-predefined-variables)。
- [重複パイプラインを回避する](../jobs/job_rules.md#avoid-duplicate-pipelines)。
- [`rules`を使用してマージリクエストパイプラインを実行する](../pipelines/merge_request_pipelines.md#add-jobs-to-merge-request-pipelines)。

---

#### `rules:changes` {#ruleschanges}

`rules:changes`を使用して、特定のファイルに対する変更をチェックすることで、ジョブをパイプラインに追加する条件を指定します。

新しいブランチパイプラインの場合、またはGitの`push`イベントがない場合、`rules: changes`は常にtrueと評価され、ジョブは常に実行されます。タグパイプライン、スケジュールされたパイプライン、手動パイプラインなどのパイプラインはどれも、Gitの`push`イベントが関連付けられて**not**（いません）。これらのケースに対応するには、[`rules: changes: compare_to`](#ruleschangescompare_to)を使用して、パイプラインのrefと比較するブランチを指定します。

`compare_to`を使用しない場合、`rules: changes`は[ブランチパイプライン](../pipelines/pipeline_types.md#branch-pipeline)または[マージリクエストパイプライン](../pipelines/merge_request_pipelines.md)のみに使用してください。ただし、新しいブランチを作成する際は、`rules: changes`は依然としてtrueと評価されます。次のように動作します:

- マージリクエストパイプラインでは、`rules:changes`は、変更内容をターゲットMRブランチと比較します。
- ブランチパイプラインでは、`rules:changes`は、変更内容をブランチの直前のコミットと比較します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

次の要素を任意の数だけ含む配列:

- ファイルのパス。ファイルのパスには、[CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)を含めることができます。
- 次のようなワイルドカードパス:
  - 単一のディレクトリ（例: `path/to/directory/*`）。
  - ディレクトリとそのすべてのサブディレクトリ（例: `path/to/directory/**/*`）。
- 同じ拡張子または複数の拡張子を持つすべてのファイルを対象とするワイルドカード[glob](https://en.wikipedia.org/wiki/Glob_(programming))パス（例: `*.md`、`path/to/directory/*.{rb,py,sh}`）。
- ルートディレクトリまたはすべてのディレクトリ内のファイルを対象とするワイルドカードパス（二重引用符で囲む）。例: `"*.json"`、`"**/*.json"`。

**Example of `rules:changes`**（の例）:

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

この例では:

- パイプラインがマージリクエストパイプラインの場合、`Dockerfile`と`$DOCKERFILES_DIR/**/*`内のファイルに変更がないかどうか確認します。
- `Dockerfile`に変更がある場合、ジョブを手動ジョブとしてパイプラインに追加し、ジョブがトリガーされない場合でもパイプラインの実行を継続します（`allow_failure: true`）。
- `$DOCKERFILES_DIR/**/*`内のファイルに変更がある場合、ジョブをパイプラインに追加します。
- リストされたファイルに変更がなかった場合、いずれのジョブもパイプラインに追加しません（`when: never`と同じ）。

**Additional details**（補足情報）:

- globパターンは、Rubyの[`File.fnmatch`](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch)で、[フラグ](https://docs.ruby-lang.org/en/master/File/Constants.html#module-File::Constants-label-Filename+Globbing+Constants+-28File-3A-3AFNM_-2A-29)`File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`を使用して解釈されます。
- パフォーマンス上の理由から、GitLabは`changes`パターンまたはファイルパスに対して最大50,000回のチェックを実行します。チェック回数が50,000回を超えると、パターンglobを含むルールは常に一致するようになります。つまり、`changes`ルールは、ファイル数が50,000を超えるプロジェクト、またはファイル数が50,000未満でも`changes`ルールのチェック回数が50,000回を超えるプロジェクトでは、常に一致することを前提としています。
- `rules:changes`セクションごとに最大50個のパターンまたはファイルパスを定義できます。
- 一致するファイルのいずれかに変更がある場合、`changes`は`true`に解決されます（`OR`演算）。
- その他の例については、[`rules`でジョブの実行タイミングを指定する](../jobs/job_rules.md)を参照してください。
- 変数とパスの両方に文字`$`を使用できます。たとえば、`$VAR`変数が存在する場合、その値が使用されます。存在しない場合、`$`はパスの一部として解釈されます。
- `./`、二重スラッシュ（`//`）、またはその他の種類の相対パスを使用しないでください。パスは厳密な文字列比較で照合され、Shellのように評価されません。

**Related topics**（関連トピック）:

- [`rules: changes`を使用すると、ジョブまたはパイプラインが予期せず実行される可能性があります](../jobs/job_troubleshooting.md#jobs-or-pipelines-run-unexpectedly-when-using-changes)。

---

##### `rules:changes:paths` {#ruleschangespaths}

{{< history >}}

- GitLab 15.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90171)されました。

{{< /history >}}

`rules:changes`を使用して、特定のファイルが変更された場合にのみジョブをパイプラインに追加するよう指定します。また、`rules:changes:paths`を使用して、対象とするファイルを指定します。

`rules:changes:paths`は、[`rules:changes`](#ruleschanges)をサブキーなしで使用するのと同じです。補足情報と関連トピックもすべて同じです。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- `rules:changes`と同じです。

**Example of `rules:changes:paths`**（の例）:

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

この例では、両方のジョブの動作は同じです。

---

##### `rules:changes:compare_to` {#ruleschangescompare_to}

{{< history >}}

- GitLab 15.3で`ci_rules_changes_compare`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/293645)されました。デフォルトでは有効になっています。
- GitLab 15.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/366412)になりました。機能フラグ`ci_rules_changes_compare`は削除されました。
- CI/CD変数のサポートは、GitLab 17.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/369916)されました。

{{< /history >}}

`rules:changes:compare_to`を使用して、[`rules:changes:paths`](#ruleschangespaths)で指定されたファイルに対する変更について比較するrefを指定します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。これはジョブの一部としてのみ使用でき、`rules:changes:paths`と組み合わせる必要があります。

**Supported values**（サポートされている値）: 

- ブランチ名（例: `main`、`branch1`、`refs/heads/branch1`）。
- タグ名（例: `tag1`、`refs/tags/tag1`）。
- コミットSHA（例: `2fg31ga14b`）。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**Example of `rules:changes:compare_to`**（の例）:

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

この例では、`docker build`ジョブがパイプラインに含まれるのは、`Dockerfile`が`refs/heads/branch1`と比較して変更されており、かつパイプラインソースがマージリクエストイベントである場合のみです。

**Additional details**（補足情報）:

- 状況によっては、`compare_to`を使用すると、予期しない結果が生じる可能性があります:
  - [マージされた結果パイプライン](../pipelines/merged_results_pipelines.md#troubleshooting)を使用すると、比較ベースはGitLabが作成する内部コミットであるためです。
  - フォークされたプロジェクトでは、[イシュー424584](https://gitlab.com/gitlab-org/gitlab/-/issues/424584)を参照してください。

**Related topics**（関連トピック）:

- `rules:changes:compare_to`を使用すると、[ブランチが空の場合にジョブをスキップ](../jobs/job_rules.md#skip-jobs-if-the-branch-is-empty)できます。

---

#### `rules:exists` {#rulesexists}

{{< history >}}

- CI/CD変数のサポートは、GitLab 15.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/283881)されました。
- GitLab 17.7で、`exists`パターンまたはファイルパスに対するチェックの最大回数が10,000から50,000に[増加](https://gitlab.com/gitlab-org/gitlab/-/issues/227632)しました。
- ディレクトリパスのサポートは、GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/327485)されました。

{{< /history >}}

`exists`を使用して、特定のファイルまたはディレクトリがリポジトリに存在する場合にジョブを実行します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブまたは[`include`](#include)の一部として使用できます。

**Supported values**（サポートされている値）: 

- ファイルまたはディレクトリパスの配列。パスはプロジェクトディレクトリ（`$CI_PROJECT_DIR`）を基準にした相対パスであり、プロジェクトディレクトリの外部に直接リンクすることはできません。ファイルパスでは、globパターンと[CI/CD変数](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)を使用できます。

**Example of `rules:exists`**（の例）:

```yaml
job1:
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

この例では:

- `job1`は、リポジトリのルートディレクトリに`Dockerfile`が存在する場合に実行されます。
- `job2`は、リポジトリ内の任意の場所に`Dockerfile`が存在する場合に実行されます。

**Additional details**（補足情報）:

- globパターンは、Rubyの[`File.fnmatch`](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch)で、[フラグ](https://docs.ruby-lang.org/en/master/File/Constants.html#module-File::Constants-label-Filename+Globbing+Constants+-28File-3A-3AFNM_-2A-29)`File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`を使用して解釈されます。
- パフォーマンス上の理由から、GitLabは`exists`パターンまたはファイルパスに対して最大50,000回のチェックを実行します。チェック回数が50,000回を超えると、パターンglobを含むルールは常に一致するようになります。つまり、`exists`ルールは、ファイル数が50,000を超えるプロジェクト、またはファイル数が50,000未満でも`exists`ルールのチェック回数が50,000回を超えるプロジェクトでは、常に一致することを前提としています。
  - パターンglobが複数ある場合、上限は50,000をglobの数で割った数になります。たとえば、パターンglobが5つあるルールでは、ファイル数の上限は10,000になります。
- `rules:exists`セクションごとに最大50個のパターンまたはファイルパスを定義できます。
- リスト内のいずれかのファイルが見つかった場合、`exists`は`true`に解決されます（`OR`演算）。
- ジョブレベルの`rules:exists`を使用すると、GitLabはパイプラインを実行するプロジェクトとrefでファイルを検索します。[`include`と`rules:exists`を組み合わせて](includes.md#include-with-rulesexists)使用すると、GitLabは`include`セクションを含むファイルのプロジェクトとrefでファイルまたはディレクトリを検索します。以下を使用する場合、`include`セクションを含むプロジェクトと、パイプラインを実行するプロジェクトが異なる場合があります:
  - [ネストされたインクルード](includes.md#use-nested-includes)。
  - [コンプライアンスパイプライン](../../user/compliance/compliance_pipelines.md)。
- `rules`の評価はジョブの実行および[アーティファクト](../jobs/job_artifacts.md)のフェッチよりも前に行われるため、`rules:exists`はアーティファクトの存在をチェックできません。
- ディレクトリの存在をテストするには、パスをフォワードスラッシュ（/）で終わらせる必要があります。

---

##### `rules:exists:paths` {#rulesexistspaths}

{{< history >}}

- GitLab 16.11で`ci_support_rules_exists_paths_and_project`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/386040)されました。デフォルトでは無効になっています。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/386040)になりました。機能フラグ`ci_support_rules_exists_paths_and_project`は削除されました。

{{< /history >}}

`rules:exists:paths`は、[`rules:exists`](#rulesexists)をサブキーなしで使用するのと同じです。補足情報もすべて同じです。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブまたは[`include`](#include)の一部として使用できます。

**Supported values**（サポートされている値）: 

- ファイルパスの配列。

**Example of `rules:exists:paths`**（の例）:

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

この例では、両方のジョブの動作は同じです。

---

##### `rules:exists:project` {#rulesexistsproject}

{{< history >}}

- GitLab 16.11で`ci_support_rules_exists_paths_and_project`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/386040)されました。デフォルトでは無効になっています。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/386040)になりました。機能フラグ`ci_support_rules_exists_paths_and_project`は削除されました。

{{< /history >}}

`rules:exists:project`を使用して、[`rules:exists:paths`](#rulesexistspaths)のリストに含まれるファイルの検索場所を指定します。`rules:exists:paths`と一緒に使用する必要があります。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブまたは[`include`](#include)の一部として使用でき、`rules:exists:paths`と組み合わせる必要があります。

**Supported values**（サポートされている値）: 

- `exists:project`: ネームスペースとグループを含む、プロジェクトのフルパス。
- `exists:ref`: オプション。ファイルの検索に使用するコミットref。refとしては、タグ、ブランチ名、またはSHAを指定できます。指定しない場合、デフォルトはプロジェクトの`HEAD`です。

**Example of `rules:exists:project`**（の例）:

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

この例では、`docker build`ジョブがパイプラインに含まれるのは、プロジェクト`my-group/my-project`の`v1.0.0`タグが付けられたコミットに`Dockerfile`が存在する場合のみです。

---

#### `rules:when` {#ruleswhen}

`rules:when`を単独で、または別のルールの一部として使用して、ジョブをパイプラインに追加する条件を制御します。`rules:when`は[`when`](#when)に似ていますが、インプットオプションが若干異なります。

`rules:when`ルールが`if`、`changes`、または`exists`と組み合わされていない場合、ジョブのルールを評価する際にこのルールに到達すると、常に一致します。

**Keyword type**（キーワードのタイプ）: ジョブ固有。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- `on_success`（デフォルト）: 前のステージでジョブが失敗しなかった場合にのみ、ジョブを実行します。
- `on_failure`: 前のステージで少なくとも1つのジョブが失敗した場合にのみ、ジョブを実行します。
- `never`: 前のステージのジョブのステータスに関係なく、ジョブを実行しません。
- `always`: 前のステージのジョブのステータスに関係なく、ジョブを実行します。
- `manual`: ジョブを[手動ジョブ](../jobs/job_control.md#create-a-job-that-must-be-run-manually)としてパイプラインに追加します。[`allow_failure`](#allow_failure)のデフォルト値が`false`に変わります。
- `delayed`: ジョブを[遅延ジョブ](../jobs/job_control.md#run-a-job-after-a-delay)としてパイプラインに追加します。

**Example of `rules:when`**（の例）:

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

この例では、次の条件で`job1`がパイプラインに追加されます:

- デフォルトブランチでは、`when`が定義されていない場合のデフォルトの動作である`when: on_success`が適用されます。
- フィーチャーブランチでは、遅延ジョブとして追加されます。
- それ以外の場合は、手動ジョブとして追加されます。

**Additional details**（補足情報）:

- `on_success`と`on_failure`の条件でジョブのステータスを評価する場合:
  - 前のステージで[`allow_failure: true`](#allow_failure)が設定されているジョブは、失敗しても成功したと見なされます。
  - 前のステージでスキップされたジョブ（[開始されていない手動ジョブ](../jobs/job_control.md#create-a-job-that-must-be-run-manually)など）は、成功したと見なされます。
- `rules:when: manual`を使用して[手動ジョブを追加](../jobs/job_control.md#create-a-job-that-must-be-run-manually)する場合:
  - [`allow_failure`](#allow_failure)はデフォルトで`false`になります。このデフォルトは、[`when: manual`](#when)を使用して手動ジョブを追加する場合の動作とは逆になります。
  - `rules`の外部で定義された`when: manual`と同じ動作を実現するには、[`rules: allow_failure`](#rulesallow_failure)を`true`に設定します。

---

#### `rules:allow_failure` {#rulesallow_failure}

`rules`で[`allow_failure: true`](#allow_failure)を使用して、ジョブが失敗してもパイプラインが停止しないようにします。

`allow_failure: true`は、手動ジョブでも使用できます。パイプラインは、手動ジョブの結果を待たずに実行を継続します。ルールで`allow_failure: false`と`when: manual`を組み合わせると、パイプラインは手動ジョブが実行されるまで待機してから続行します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- `true`または`false`。定義されていない場合のデフォルトは`false`です。

**Example of `rules:allow_failure`**（の例）:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH
      when: manual
      allow_failure: true
```

ルールに一致する場合、ジョブは`allow_failure: true`が設定された手動ジョブになります。

**Additional details**（補足情報）:

- ルールレベルの`rules:allow_failure`はジョブレベルの[`allow_failure`](#allow_failure)をオーバーライドし、特定のルールがジョブをトリガーする場合にのみ適用されます。

---

#### `rules:needs` {#rulesneeds}

{{< history >}}

- GitLab 16.0で`introduce_rules_with_needs`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/31581)されました。デフォルトでは無効になっています。
- GitLab 16.2で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/408871)になりました。機能フラグ`introduce_rules_with_needs`は削除されました。

{{< /history >}}

ルールで`needs`を使用して、特定の条件に応じてジョブの[`needs`](#needs)を更新します。条件がルールに一致すると、ジョブの`needs`設定は、ルール内の`needs`で完全に置き換えられます。

**Keyword type**（キーワードのタイプ）: ジョブ固有。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- ジョブ名（文字列）の配列。
- ジョブ名と、必要に応じて追加の属性を含めたハッシュ。
- 特定の条件が満たされた場合に、ジョブのneedsをnoneに設定するための空の配列（`[]`）。

**Example of `rules:needs`**（の例）:

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

この例では:

- パイプラインがデフォルトブランチではないブランチで実行され、その結果ルールが最初の条件に一致した場合、`specs`ジョブには`build-dev`ジョブが必要です。
- パイプラインがデフォルトブランチで実行され、その結果ルールが2番目の条件に一致した場合、`specs`ジョブには`build-prod`ジョブが必要です。

**Additional details**（補足情報）:

- ルール内の`needs`は、ジョブレベルで定義されている`needs`をオーバーライドします。オーバーライドされた場合の動作は、[ジョブレベルの`needs`](#needs)と同じです。
- ルール内の`needs`は、[`artifacts`](#needsartifacts)と[`optional`](#needsoptional)を受け入れます。

---

#### `rules:variables` {#rulesvariables}

`rules`で[`variables`](#variables)を使用して、特定の条件に応じて変数を定義します。

**Keyword type**（キーワードのタイプ）: ジョブ固有。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- `VARIABLE-NAME: value`形式の変数のハッシュ。

**Example of `rules:variables`**（の例）:

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

---

#### `rules:interruptible` {#rulesinterruptible}

{{< history >}}

- GitLab 16.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/194023)されました。

{{< /history >}}

ルールで`interruptible`を使用して、特定の条件に応じてジョブの[`interruptible`](#interruptible)値を更新します。

**Keyword type**（キーワードのタイプ）: ジョブ固有。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- `true`または`false`。

**Example of `rules:interruptible`**（の例）:

```yaml
job:
  script: echo "Hello, Rules!"
  interruptible: true
  rules:
    - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
      interruptible: false  # Override interruptible defined at the job level.
    - when: on_success
```

**Additional details**（補足情報）:

- ルールレベルの`rules:interruptible`はジョブレベルの[`interruptible`](#interruptible)をオーバーライドし、特定のルールがジョブをトリガーする場合にのみ適用されます。

---

### `run` {#run}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 17.3で`pipeline_run_keyword`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/440487)されました。デフォルトでは無効になっています。GitLab Runner 17.1が必要です。
- 機能フラグ`pipeline_run_keyword`は、GitLab 17.5で[削除](https://gitlab.com/gitlab-org/gitlab/-/issues/471925)されました。

{{< /history >}}

{{< alert type="note" >}}

この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

`run`を使用して、ジョブ内で実行する一連の[ステップ](../steps/_index.md)を定義します。各ステップは、スクリプトまたは定義済みステップのいずれかになります。

オプションで環境変数とインプットを指定することもできます。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- ハッシュの配列。各ハッシュは次のキーを指定したステップを表します:
  - `name`: ステップの名前を表す文字列。
  - `script`: 実行するShellコマンドを含む文字列または文字列の配列。
  - `step`: 実行する定義済みステップを識別する文字列。
  - `env`: オプション。このステップに固有の環境変数のハッシュ。
  - `inputs`: オプション。定義済みステップのインプットパラメータのハッシュ。

各配列のエントリに`name`は必須であり、`script`または`step`のいずれか一方（両方は不可）を指定する必要があります。

**Example of `run`**（の例）:

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

この例では、ジョブには次の2つのステップがあります:

- `hello_steps`が、Shellコマンド`echo`を実行します。
- `bye_steps`が、環境変数とインプットパラメータを指定した定義済みステップを使用します。

**Additional details**（補足情報）:

- ステップには`script`か`step`キーのいずれか一方を指定できます。両方を指定することはできません。
- `run`の設定を、既存のキーワード[`script`](#script) 、[`after_script`](#after_script) 、[`before_script`](#before_script)と一緒に使用することはできません。
- 複数行のスクリプトは、[YAMLブロックスカラー構文](script.md#split-long-commands)を使用して定義できます。

---

### `script` {#script}

`script`を使用して、Runnerが実行するコマンドを指定します。

[トリガージョブ](#trigger)を除くすべてのジョブでは、`script`キーワードが必須です。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 次の内容を含む配列:

- 1行のコマンド。
- [複数行に分割された](script.md#split-long-commands)長いコマンド。
- [YAMLアンカー](yaml_optimization.md#yaml-anchors-for-scripts)。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**Example of `script`**（の例）:

```yaml
job1:
  script: "bundle exec rspec"

job2:
  script:
    - uname -a
    - bundle exec rspec
```

**Additional details**（補足情報）:

- [`script`内で特殊文字](script.md#use-special-characters-with-script)を使用する場合は、単一引用符（`'`）または二重引用符（`"`）を使用する必要があります。

**Related topics**（関連トピック）:

- [ゼロ以外の終了コードを無視](script.md#ignore-non-zero-exit-codes)できます。
- [`script`でカラーコードを使用する](script.md#add-color-codes-to-script-output)と、ジョブログのレビューが容易になります。
- [カスタムの折りたたみ可能なセクションを作成](../jobs/job_logs.md#custom-collapsible-sections)して、ジョブログ出力をシンプルにできます。

---

### `secrets` {#secrets}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

`secrets`を使用して、次のような[CI/CDシークレット](../secrets/_index.md)を指定します:

- 外部シークレットプロバイダーから取得する。
- ジョブ内で[CI/CD変数](../variables/_index.md)として使用できるようにする（デフォルトでは[`file`タイプ](../variables/_index.md#use-file-type-cicd-variables)）。

---

#### `secrets:vault` {#secretsvault}

{{< history >}}

- `generic`エンジンオプションは、GitLab Runner 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/366492)されました。

{{< /history >}}

`secrets:vault`を使用して、[HashiCorp Vault](https://www.vaultproject.io/)によって提供されるシークレットを指定します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- `engine:name`: シークレットエンジンの名前。`kv-v2`（デフォルト）、`kv-v1`、または`generic`のいずれか。
- `engine:path`: シークレットエンジンのパス。
- `path`: シークレットのパス。
- `field`: パスワードが格納されているフィールドの名前。

**Example of `secrets:vault`**（の例）:

すべての詳細を明示的に指定し、[KV-V2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2)シークレットエンジンを使用するには、次のようにします:

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

この構文は短縮できます。短縮構文では、`engine:name`と`engine:path`がどちらもデフォルトで`kv-v2`になります:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:  # Store the path to the secret in this CI/CD variable
      vault: production/db/password  # Translates to secret: `kv-v2/data/production/db`, field: `password`
```

短縮構文でカスタムシークレットエンジンのパスを指定するには、`@`で始まるサフィックスを追加します:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:  # Store the path to the secret in this CI/CD variable
      vault: production/db/password@ops  # Translates to secret: `ops/data/production/db`, field: `password`
```

---

#### `secrets:gcp_secret_manager` {#secretsgcp_secret_manager}

{{< history >}}

- GitLab 16.8およびGitLab Runner 16.8で[導入](https://gitlab.com/groups/gitlab-org/-/epics/11739)されました。

{{< /history >}}

`secrets:gcp_secret_manager`を使用して、[GCP Secret Manager](https://cloud.google.com/security/products/secret-manager)によって提供されるシークレットを指定します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- `name`: シークレットの名前。
- `version`: シークレットのバージョン。

**Example of `secrets:gcp_secret_manager`**（の例）:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      gcp_secret_manager:
        name: 'test'
        version: 2
```

**Related topics**（関連トピック）:

- [GitLab CI/CDでGCP Secret Managerシークレットを使用する](../secrets/gcp_secret_manager.md)。

---

#### `secrets:azure_key_vault` {#secretsazure_key_vault}

{{< history >}}

- GitLab 16.3およびGitLab Runner 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/271271)されました。

{{< /history >}}

`secrets:azure_key_vault`を使用して、[Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault/)によって提供されるシークレットを指定します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- `name`: シークレットの名前。
- `version`: シークレットのバージョン。

**Example of `secrets:azure_key_vault`**（の例）:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      azure_key_vault:
        name: 'test'
        version: 'test'
```

**Related topics**（関連トピック）:

- [GitLab CI/CDでAzure Key Vaultシークレットを使用する](../secrets/azure_key_vault.md)。

---

#### `secrets:file` {#secretsfile}

`secrets:file`を使用して、シークレットを[`file`または`variable`タイプのCI/CD変数](../variables/_index.md#use-file-type-cicd-variables)として格納するよう設定します。

デフォルトでは、シークレットは`file`タイプのCI/CD変数としてジョブに渡されます。シークレットの値がファイルに保存され、変数にはそのファイルのパスが格納されます。

ソフトウェアで`file`タイプのCI/CD変数を使用できない場合は、`file: false`を設定して、シークレットの値を変数に直接保存してください。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- `true`（デフォルト）または`false`。

**Example of `secrets:file`**（の例）:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      vault: production/db/password@ops
      file: false
```

**Additional details**（補足情報）:

- `file`キーワードはCI/CD変数の設定であり、`vault`セクションではなくCI/CD変数名の下にネストする必要があります。

---

#### `secrets:token` {#secretstoken}

{{< history >}}

- GitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/356986)されました。**Limit JSON Web Token (JWT) access**（JSON Webトークン（JWT）アクセスを制限する）設定により制御します。
- GitLab 16.0で[常に使用可能になり**Limit JSON Web Token (JWT) access**（、JSON Webトークン（JWT）アクセスを制限する）設定は削除されました](https://gitlab.com/gitlab-org/gitlab/-/issues/366798)。

{{< /history >}}

`secrets:token`を使用して、トークンのCI/CD変数を参照することにより、外部シークレットプロバイダーで認証する際に使用するトークンを明示的に選択します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- IDトークンの名前。

**Example of `secrets:token`**（の例）:

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

**Additional details**（補足情報）:

- `token`キーワードが設定されておらず、トークンが1つしか定義されていない場合、定義されたトークンが自動的に使用されます。
- 複数のトークンが定義されている場合は、`token`キーワードを設定して、使用するトークンを指定する必要があります。使用するトークンを指定しない場合、ジョブの実行ごとにどのトークンが使用されるかを予測することはできません。

---

### `services` {#services}

`services`を使用して、スクリプトの正常な実行に必要な追加のDockerイメージを指定します。[`services`イメージ](../services/_index.md)は、[`image`](#image)キーワードで指定されたイメージにリンクされます。

ジョブの設定とデフォルトの設定は、一緒にマージされません。パイプラインに[`default:services`](#default)が定義されていて、ジョブにも`services`がある場合、ジョブの設定が優先され、デフォルトの設定は使用されません。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: サービスイメージの名前（必要に応じてレジストリパスを含む）。次のいずれかの形式で指定します:

- `<image-name>`（`<image-name>`に`latest`タグを付けた場合と同じ）
- `<image-name>:<tag>`
- `<image-name>@<digest>`

CI/CD変数が[サポート](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)されていますが、[`alias`には使用できません](https://gitlab.com/gitlab-org/gitlab/-/issues/19561)。

**Example of `services`**（の例）:

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

この例では、GitLabはジョブ用に以下の2つのコンテナを起動します:

- `script`コマンドを実行するRubyコンテナ。
- PostgreSQLコンテナ。Rubyコンテナの`script`コマンドは、ホスト名に`db-postgres`を指定してPostgreSQLデータベースに接続できます。

**Additional details**（補足情報）:

- `services`を`default`セクションではなくトップレベルで使用することは、[非推奨](deprecated_keywords.md#globally-defined-image-services-cache-before_script-after_script)です。

**Related topics**（関連トピック）:

- [`services`で使用可能な設定](../services/_index.md#available-settings-for-services)。
- [`.gitlab-ci.yml`ファイルで`services`を定義する](../services/_index.md#define-services-in-the-gitlab-ciyml-file)。
- [DockerコンテナでCI/CDジョブを実行する](../docker/using_docker_images.md)。
- [Dockerを使用してDockerイメージをビルドする](../docker/using_docker_build.md)。

---

#### `services:docker` {#servicesdocker}

{{< history >}}

- GitLab 16.7で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27919)されました。GitLab Runner 16.7以降が必要です。
- `user`インプットオプションは、GitLab 16.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137907)されました。

{{< /history >}}

`services:docker`を使用して、GitLab RunnerのDocker executorにオプションを渡します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

Docker executorのオプションを定義するハッシュ。以下を含めることができます:

- `platform`: プルするイメージのアーキテクチャを選択します。指定しない場合、デフォルトはホストRunnerと同じプラットフォームです。
- `user`: コンテナの実行時に使用するユーザー名またはUIDを指定します。

**Example of `services:docker`**（の例）:

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

**Additional details**（補足情報）:

- `services:docker:platform`は、[`docker pull --platform`オプション](https://docs.docker.com/reference/cli/docker/image/pull/#options)にマップされます。
- `services:docker:user`は、[`docker run --user`オプション](https://docs.docker.com/reference/cli/docker/container/run/#options)にマップされます。

---

#### `services:kubernetes` {#serviceskubernetes}

{{< history >}}

- GitLab 18.0で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38451)されました。GitLab Runner 17.11以降が必要です。
- `user`インプットオプションは、GitLab Runner 17.11で[導入](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5469)されました。
- `user`インプットオプションは、GitLab 18.0で[`uid:gid`形式をサポートするように拡張](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5540)されました。

{{< /history >}}

`services:kubernetes`を使用して、GitLab Runner [Kubernetes executor](https://docs.gitlab.com/runner/executors/kubernetes/)にオプションを渡します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

Kubernetes executorのオプションを定義するハッシュ。以下を含めることができます:

- `user`: コンテナの実行時に使用するユーザー名またはUIDを指定します。`UID:GID`形式を使用して、GIDを設定することもできます。

**Example of `services:kubernetes` with only UID**（UIDのみを使用したの例）:

```yaml
arm-sql-job:
  script: echo "Run sql tests"
  image: ruby:2.6
  services:
    - name: super/sql:experimental
      kubernetes:
        user: "1001"
```

**Example of `services:kubernetes` with both UID and GID**（UIDとGIDの両方を使用したの例）:

```yaml
arm-sql-job:
  script: echo "Run sql tests"
  image: ruby:2.6
  services:
    - name: super/sql:experimental
      kubernetes:
        user: "1001:1001"
```

---

#### `services:pull_policy` {#servicespull_policy}

{{< history >}}

- GitLab 15.1で`ci_docker_image_pull_policy`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/21619)されました。デフォルトでは無効になっています。
- GitLab 15.2の[GitLab.comおよびGitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)になりました。
- GitLab 15.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)になりました。[機能フラグ`ci_docker_image_pull_policy`](https://gitlab.com/gitlab-org/gitlab/-/issues/363186)は削除されました。

{{< /history >}}

RunnerがDockerイメージをフェッチするために使用するプルポリシー。GitLab Runner 15.1以降が必要です。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- 1つのプルポリシー、または配列で指定する複数のプルポリシー。`always`、`if-not-present`、`never`のいずれかを指定できます。

**Examples of `services:pull_policy`**（の例）:

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

**Additional details**（補足情報）:

- 定義済みのプルポリシーをRunnerがサポートしていない場合、ジョブは次のようなエラーで失敗します: `ERROR: Job failed (system failure): the configured PullPolicies ([always]) are not allowed by AllowedPullPolicies ([never])`。

**Related topics**（関連トピック）:

- [DockerコンテナでCI/CDジョブを実行する](../docker/using_docker_images.md)。
- [Runnerがイメージをプルする方法を設定する](https://docs.gitlab.com/runner/executors/docker.html#configure-how-runners-pull-images)。
- [複数のプルポリシーを設定する](https://docs.gitlab.com/runner/executors/docker.html#set-multiple-pull-policies)。

---

### `stage` {#stage}

`stage`を使用して、ジョブを実行する[ステージ](#stages)を定義します。同じ`stage`内のジョブは、並列実行できます（**Additional details**（補足情報）を参照）。

`stage`が定義されていない場合、ジョブはデフォルトで`test`ステージを使用します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 次のいずれかの文字列:

- [デフォルトステージ](#stages)。
- ユーザー定義ステージ。

**Example of `stage`**（の例）:

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
    - echo "This job also runs in the test stage."

job4:
  stage: deploy
  script:
    - echo "This job deploys the code. It runs when the test stage completes."
  environment: production
```

**Additional details**（補足情報）:

- ステージ名は255文字以下でなければなりません。
- ジョブが異なる複数のRunnerで実行される場合、並列実行が可能です。
- Runnerが1つしかない場合でも、そのRunnerの[`concurrent`設定](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section)が`1`より大きければ、ジョブを並列実行できます。

---

#### `stage: .pre` {#stage-pre}

`.pre`ステージを使用して、パイプラインの開始時にジョブを実行します。デフォルトでは、`.pre`はパイプラインの最初のステージです。ユーザー定義ステージは、`.pre`の後に実行されます。[`stages`](#stages)内で`.pre`を定義する必要はありません。

パイプラインに`.pre`ステージまたは`.post`ステージのジョブしか含まれていない場合、そのパイプラインは実行されません。これら以外のステージに少なくとも1つのジョブが必要です。

**Keyword type**（キーワードのタイプ）: ジョブの`stage`キーワードと組み合わせる場合にのみ使用できます。

**Example of `stage: .pre`**（の例）:

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

**Additional details**（補足情報）:

- パイプラインに[`needs: []`](#needs)を指定したジョブと`.pre`ステージのジョブがある場合、それらはすべてパイプラインの作成直後に開始されます。`needs: []`を指定したジョブは、ステージ設定を無視してすぐに開始されます。
- [パイプライン実行ポリシー](../../user/application_security/policies/pipeline_execution_policies.md)で、`.pre`の前に実行される`.pipeline-policy-pre`ステージを定義できます。

---

#### `stage: .post` {#stage-post}

`.post`ステージを使用して、パイプラインの最後にジョブを実行します。デフォルトでは、`.post`はパイプラインの最後のステージです。ユーザー定義ステージは、`.post`の前に実行されます。[`stages`](#stages)内で`.post`を定義する必要はありません。

パイプラインに`.pre`ステージまたは`.post`ステージのジョブしか含まれていない場合、そのパイプラインは実行されません。これら以外のステージに少なくとも1つのジョブが必要です。

**Keyword type**（キーワードのタイプ）: ジョブの`stage`キーワードと組み合わせる場合にのみ使用できます。

**Example of `stage: .post`**（の例）:

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

**Additional details**（補足情報）:

- [パイプライン実行ポリシー](../../user/application_security/policies/pipeline_execution_policies.md)で、`.post`の後に実行される`.pipeline-policy-post`ステージを定義できます。

---

### `tags` {#tags}

`tags`を使用して、プロジェクトで使用可能なすべてのRunnerのリストから特定のRunnerを選択します。

Runnerを登録する際に、Runnerのタグ（`ruby`、`postgres`、`development`など）を指定できます。ジョブを取得して実行するには、ジョブにリストされているすべてのタグがRunnerに割り当てられている必要があります。

ジョブの設定とデフォルトの設定は、一緒にマージされません。パイプラインに[`default:tags`](#default)が定義されていて、ジョブにも`tags`がある場合、ジョブの設定が優先され、デフォルトの設定は使用されません。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 

- タグ名の配列（大文字と小文字が区別されます）。
- CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**Example of `tags`**（の例）:

```yaml
job:
  tags:
    - ruby
    - postgres
```

この例では、ジョブを実行できるのは、`ruby`タグと`postgres`タグの両方が指定されたRunnerのみです。

**Additional details**（補足情報）:

- タグの数は`50`未満でなければなりません。

**Related topics**（関連トピック）:

- [タグを使用してRunnerが実行できるジョブを制御する](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)
- [並列マトリックスジョブごとに異なるRunnerタグを選択する](../jobs/job_control.md#select-different-runner-tags-for-each-parallel-matrix-job)
- ホストされるRunnerのRunnerタグ:
  - [Linux上でホストされるRunner](../runners/hosted_runners/linux.md)
  - [GPU対応のホストされるRunner](../runners/hosted_runners/gpu_enabled.md)
  - [macOS上でホストされるRunner](../runners/hosted_runners/macos.md)
  - [Windows上でホストされるRunner](../runners/hosted_runners/windows.md)

---

### `timeout` {#timeout}

`timeout`を使用して、特定のジョブのタイムアウトを設定します。ジョブがタイムアウトより長く実行されると、ジョブは失敗します。

ジョブレベルのタイムアウトは、[プロジェクトレベルのタイムアウト](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run)よりも長くすることができますが、[Runnerのタイムアウト](../runners/configure_runners.md#set-the-maximum-job-timeout)よりも長くすることはできません。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として、または[`default`セクション](#default)でのみ使用できます。

**Supported values**（サポートされている値）: 自然言語で記述された期間。たとえば、以下の表記はすべて同等です:

- `3600 seconds`
- `60 minutes`
- `one hour`

**Example of `timeout`**（の例）:

```yaml
build:
  script: build.sh
  timeout: 3 hours 30 minutes

test:
  script: rspec
  timeout: 3h 30m
```

---

### `trigger` {#trigger}

{{< history >}}

- `environment`のサポートは、GitLab 16.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/369061)されました。

{{< /history >}}

`trigger`を使用して、ジョブが次のいずれかの[ダウンストリームパイプライン](../pipelines/downstream_pipelines.md)を開始する「トリガージョブ」であることを宣言します:

- [マルチプロジェクトパイプライン](../pipelines/downstream_pipelines.md#multi-project-pipelines)。
- [子パイプライン](../pipelines/downstream_pipelines.md#parent-child-pipelines)。

トリガージョブで使用できるGitLab CI/CD設定キーワードは限られています。トリガージョブで使用できるキーワードは次のとおりです:

- [`allow_failure`](#allow_failure)。
- [`extends`](#extends)。
- [`needs`](#needs) 。ただし、[`needs:project`](#needsproject)は除きます。
- [`only`と`except`](deprecated_keywords.md#only--except)。
- [`parallel`](#parallel)。
- [`rules`](#rules)。
- [`stage`](#stage)。
- [`trigger`](#trigger)。
- [`variables`](#variables)。
- [`when`](#when)（値が`on_success`、`on_failure`、`always`の場合のみ）。
- [`resource_group`](#resource_group)。
- [`environment`](#environment)。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- マルチプロジェクトパイプラインの場合、ダウンストリームプロジェクトのパス。GitLab 15.3以降はCI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file) 。ただし、[ジョブ専用変数](../variables/predefined_variables.md#variable-availability)はサポートされていません。代わりに、[`trigger:project`](#triggerproject)を使用してください。
- 子パイプラインの場合は、[`trigger:include`](#triggerinclude)を使用します。

**Example of `trigger`**（の例）:

```yaml
trigger-multi-project-pipeline:
  trigger: my-group/my-project
```

**Additional details**（補足情報）:

- `trigger`と同じジョブで[`when:manual`](#when)を使用できますが、APIを使用して`when:manual`のトリガージョブを開始することはできません。詳細については、[イシュー284086](https://gitlab.com/gitlab-org/gitlab/-/issues/284086)を参照してください。
- 手動トリガージョブを実行する前に、[CI/CD変数を手動で指定](../jobs/job_control.md#specify-variables-when-running-manual-jobs)することはできません。
- トップレベルの`variables`セクション（グローバル）またはトリガージョブ内で定義された[CI/CD変数](#variables)は、[トリガー変数](../pipelines/downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline)としてダウンストリームパイプラインに転送されます。
- [パイプライン変数](../variables/_index.md#cicd-variable-precedence)は、デフォルトではダウンストリームパイプラインに渡されません。これらの変数をダウンストリームパイプラインに転送するには、[`trigger:forward`](#triggerforward)を使用します。
- [ジョブ専用変数](../variables/predefined_variables.md#variable-availability)は、トリガージョブでは使用できません。
- [Runnerの`config.toml`で定義された](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)環境変数は、トリガージョブでは使用できず、ダウンストリームパイプラインに渡されません。
- トリガージョブでは[`needs:pipeline:job`](#needspipelinejob)を使用できません。

**Related topics**（関連トピック）:

- [マルチプロジェクトパイプライン設定の例](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file)。
- 特定のブランチ、タグ、またはコミットのパイプラインを実行するには、[トリガートークン](../triggers/_index.md)を使用して[パイプライントリガーAPI](../../api/pipeline_triggers.md)に対して認証を行えます。トリガートークンは、`trigger`キーワードとは異なります。

---

#### `trigger:inputs` {#triggerinputs}

{{< history >}}

- GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/519963)されました。

{{</history >}}

ダウンストリームパイプライン設定で[`spec:inputs`](#specinputs)を使用している場合、`trigger:inputs`を使用して、マルチプロジェクトパイプラインの[インプット](../inputs/_index.md)を設定します。

**Example of `trigger:inputs`**（の例）:

```yaml
trigger:
  - project: 'my-group/my-project'
    inputs:
      website: "My website"
```

---

#### `trigger:include` {#triggerinclude}

`trigger:include`を使用して、ジョブが[子パイプライン](../pipelines/downstream_pipelines.md#parent-child-pipelines)を開始する「トリガージョブ」であることを宣言します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- 子パイプラインの設定ファイルのパス。

**Example of `trigger:include`**（の例）:

```yaml
trigger-child-pipeline:
  trigger:
    include: path/to/child-pipeline.gitlab-ci.yml
```

**Additional details**（補足情報）:

使用方法:

- `trigger:include:artifact`を使用して、[動的子パイプライン](../pipelines/downstream_pipelines.md#dynamic-child-pipelines)をトリガーします。
- ダウンストリームパイプライン設定で[`spec:inputs`](#specinputs)を使用している場合、`trigger:include:inputs`を使用して[インプット](../inputs/_index.md)を設定します。
- 以下の場合の、子パイプラインの設定ファイルへのパスの`trigger:include:local`:
  - [複数の子パイプライン設定ファイルを結合する](../pipelines/downstream_pipelines.md#combine-multiple-child-pipeline-configuration-files)。
  - 子パイプラインに入力を渡すには、`trigger:include:inputs`と組み合わせます。例: 

    ```yaml
    staging-job:
      trigger:
        include:
          - local: path/to/child-pipeline.yml
            inputs:
              environment: staging
    ```

- `trigger:include:project`を使用して、[別のプロジェクト内の設定ファイルを使用して](../pipelines/downstream_pipelines.md#use-a-child-pipeline-configuration-file-in-a-different-project)子パイプラインをトリガーします。ファイルに[`include`](#include)エントリがさらに含まれている場合、GitLabはファイルをホストしているプロジェクトではなく、パイプラインを実行しているプロジェクト内のファイルを検索します。
- CI/CDテンプレートで子パイプラインをトリガーする`trigger:include:template`。

**Related topics**（関連トピック）:

- [子パイプライン設定の例](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file)。

---

#### `trigger:include:inputs` {#triggerincludeinputs}

{{< history >}}

- GitLab 17.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/519963)されました。

{{</history >}}

ダウンストリームパイプライン設定で[`spec:inputs`](#specinputs)を使用している場合、`trigger:include:inputs`を使用して、子パイプラインの[インプット](../inputs/_index.md)を設定します。

**Example of `trigger:inputs`**（の例）:

```yaml
trigger-job:
  trigger:
    include:
      - local: path/to/child-pipeline.yml
        inputs:
          website: "My website"
```

---

#### `trigger:project` {#triggerproject}

`trigger:project`を使用して、ジョブが[マルチプロジェクトパイプライン](../pipelines/downstream_pipelines.md#multi-project-pipelines)を開始する「トリガージョブ」であることを宣言します。

デフォルトでは、マルチプロジェクトパイプラインはデフォルトブランチに対してトリガーされます。別のブランチを指定するには、`trigger:branch`を使用します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- ダウンストリームプロジェクトのパス。GitLab 15.3以降はCI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file) 。ただし、[ジョブ専用変数](../variables/predefined_variables.md#variable-availability)はサポートされていません。

**Example of `trigger:project`**（の例）:

```yaml
trigger-multi-project-pipeline:
  trigger:
    project: my-group/my-project
```

**Example of `trigger:project` for a different branch**（別のブランチに対するの例）:

```yaml
trigger-multi-project-pipeline:
  trigger:
    project: my-group/my-project
    branch: development
```

**Related topics**（関連トピック）:

- [マルチプロジェクトパイプライン設定の例](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file)。
- 特定のブランチ、タグ、またはコミットのパイプラインを実行するには、[トリガートークン](../triggers/_index.md)を使用して[パイプライントリガーAPI](../../api/pipeline_triggers.md)に対して認証することもできます。トリガートークンは、`trigger`キーワードとは異なります。

---

#### `trigger:strategy` {#triggerstrategy}

{{< history >}}

- `strategy:mirror`オプションは、GitLab 18.2で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/431882)されました。

{{< /history >}}

`trigger:strategy`を使用して、ダウンストリームパイプラインが完了するまでは`trigger`ジョブが**成功**とマークされないように制御します。

この動作はデフォルトとは異なります。デフォルトでは、ダウンストリームパイプラインが作成されるとすぐに、`trigger`ジョブは**成功**とマークされます。

この設定により、パイプラインは並列ではなく直列で実行されます。

**Supported values**（サポートされている値）: 

- `mirror`: ダウンストリームパイプラインのステータスを正確にミラーリングします。
- `depend`: 推奨されません。`mirror`を代わりに使用してください。トリガージョブのジョブステータスは、ダウンストリームパイプラインのステータスに応じて、**失敗**、**成功**、または**実行中**と表示されます。補足情報を参照してください。

**Example of `trigger:strategy`**（の例）:

```yaml
trigger_job:
  trigger:
    include: path/to/child-pipeline.yml
    strategy: mirror
```

この例では、後続ステージのジョブは、トリガーされたパイプラインが正常に完了するまで開始されません。

**Additional details**（補足情報）:

- ダウンストリームパイプラインの[オプションの手動ジョブ](../jobs/job_control.md#types-of-manual-jobs)は、ダウンストリームパイプラインまたはアップストリームのトリガージョブのステータスに影響を与えません。ダウンストリームパイプラインは、オプションの手動ジョブを実行しなくても正常に完了できます。
- デフォルトでは、後続ステージのジョブは、トリガージョブが完了するまで開始されません。
- ダウンストリームパイプラインの[ブロック手動ジョブ](../jobs/job_control.md#types-of-manual-jobs)は、トリガージョブが成功または失敗としてマークされる前に実行する必要があります。
- `strategy:depend`を使用する場合（もはや推奨されていません。`strategy:mirror`を代わりに使用してください）:
  - 手動ジョブが原因でダウンストリームパイプラインのステータスが**手動アクション待ち**（{{< icon name="status_manual" >}}）になっている場合、トリガージョブは**実行中**（{{< icon name="status_running" >}}）と表示されます。
  - ダウンストリームパイプラインに失敗したジョブがあっても、そのジョブで[`allow_failure: true`](#allow_failure)を使用している場合、ダウンストリームパイプラインは成功と見なされ、トリガージョブは**成功**と表示されます。

---

#### `trigger:forward` {#triggerforward}

{{< history >}}

- GitLab 15.1で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/355572)になりました。[機能フラグ`ci_trigger_forward_variables`](https://gitlab.com/gitlab-org/gitlab/-/issues/355572)は削除されました。

{{< /history >}}

`trigger:forward`を使用して、ダウンストリームパイプラインに転送する内容を指定します。[親子パイプライン](../pipelines/downstream_pipelines.md#parent-child-pipelines)と[マルチプロジェクトパイプライン](../pipelines/downstream_pipelines.md#multi-project-pipelines)の両方に転送する内容を制御できます。

デフォルトでは、ネストされたダウンストリームパイプラインでは、転送された変数が再度転送されることはありません。再度転送するには、ネストされたダウンストリームのトリガージョブでも`trigger:forward`を使用する必要があります。

**Supported values**（サポートされている値）: 

- `yaml_variables`: `true`（デフォルト）、または`false`。`true`の場合、トリガージョブで定義されている変数がダウンストリームパイプラインに渡されます。
- `pipeline_variables`: `true`または`false`（デフォルト）。`true`の場合、[パイプライン変数](../variables/_index.md#cicd-variable-precedence)がダウンストリームパイプラインに渡されます。

**Example of `trigger:forward`**（の例）:

CI/CD変数`MYVAR = my value`を指定して、[このパイプラインを手動で実行](../pipelines/_index.md#run-a-pipeline-manually)します:

```yaml
variables: # default variables for each job
  VAR: value

---

# Default behavior:
---

# - VAR is passed to the child
---

# - MYVAR is not passed to the child
child1:
  trigger:
    include: .child-pipeline.yml

---

# Forward pipeline variables:
---

# - VAR is passed to the child
---

# - MYVAR is passed to the child
child2:
  trigger:
    include: .child-pipeline.yml
    forward:
      pipeline_variables: true

---

# Do not forward YAML variables:
---

# - VAR is not passed to the child
---

# - MYVAR is not passed to the child
child3:
  trigger:
    include: .child-pipeline.yml
    forward:
      yaml_variables: false
```

**Additional details**（補足情報）:

- `trigger:forward`でダウンストリームパイプラインに転送されるCI/CD変数は、優先順位の高い[パイプライン変数](../variables/_index.md#cicd-variable-precedence)です。ダウンストリームパイプラインで同じ名前の変数が定義されている場合、その変数は通常、転送された変数によって上書きされます。

---

### `when` {#when}

`when`を使用して、ジョブの実行条件を設定します。ジョブで定義されていない場合、デフォルト値は`when: on_success`です。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部として使用できます。`when: always`と`when: never`は、[`workflow:rules`](#workflow)でも使用できます。

**Supported values**（サポートされている値）: 

- `on_success`（デフォルト）: 前のステージでジョブが失敗しなかった場合にのみ、ジョブを実行します。
- `on_failure`: 前のステージで少なくとも1つのジョブが失敗した場合にのみ、ジョブを実行します。
- `never`: 前のステージのジョブのステータスに関係なく、ジョブを実行しません。[`rules`](#ruleswhen)セクションまたは[`workflow: rules`](#workflowrules)でのみ使用できます。
- `always`: 前のステージのジョブのステータスに関係なく、ジョブを実行します。
- `manual`: ジョブを[手動ジョブ](../jobs/job_control.md#create-a-job-that-must-be-run-manually)としてパイプラインに追加します。
- `delayed`: ジョブを[遅延ジョブ](../jobs/job_control.md#run-a-job-after-a-delay)としてパイプラインに追加します。

**Example of `when`**（の例）:

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

この例では、スクリプトは次のように動作します:

1. `build_job`が失敗した場合にのみ、`cleanup_build_job`を実行します。
1. 成功か失敗かに関係なく、常にパイプラインの最後のステップとして`cleanup_job`を実行します。
1. GitLab UIで手動で実行した場合、`deploy_job`を実行します。

**Additional details**（補足情報）:

- `on_success`と`on_failure`の条件でジョブのステータスを評価する場合:
  - 前のステージで[`allow_failure: true`](#allow_failure)が設定されているジョブは、失敗しても成功したと見なされます。
  - 前のステージでスキップされたジョブ（[開始されていない手動ジョブ](../jobs/job_control.md#create-a-job-that-must-be-run-manually)など）は、成功したと見なされます。
- `when: manual`の場合、[`allow_failure`](#allow_failure)のデフォルト値は`true`です。[`rules:when: manual`](#ruleswhen)の場合、デフォルト値は`false`に変わります。

**Related topics**（関連トピック）:

- `when`を[`rules`](#rules)と組み合わせて使用すると、さらに動的にジョブを制御できます。
- `when`を[`workflow`](#workflow)と組み合わせて使用すると、パイプラインの開始条件を制御できます。

---

#### `manual_confirmation` {#manual_confirmation}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/18906)されました。
- GitLab 18.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/479318)された環境停止ジョブのサポート。

{{< /history >}}

`manual_confirmation`と[`when: manual`](#when)を組み合わせて使用し、手動ジョブのカスタム確認メッセージを定義します。`when: manual`を使用する手動ジョブが定義されていない場合、このキーワードは効果がありません。

手動確認は、[`environment:action: stop`](#environmentaction)を使用する環境停止ジョブを含む、すべての手動ジョブで機能します。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Supported values**（サポートされている値）: 

- 確認メッセージの文字列。

**Example of `manual_confirmation`**（の例）:

```yaml
delete_job:
  stage: post-deployment
  script:
    - make delete
  when: manual
  manual_confirmation: 'Are you sure you want to delete this environment?'

stop_production:
  stage: cleanup
  script:
    - echo "Stopping production environment"
  environment:
    name: production
    action: stop
  when: manual
  manual_confirmation: "Are you sure you want to stop the production environment?"
```

---

### `start_in` {#start_in}

ジョブの作成後、指定された期間ジョブの実行を遅らせるには、`start_in`を使用します。ジョブの`when: delayed`を設定する必要があります。

**Keyword type**（キーワードのタイプ）: ジョブキーワード。ジョブの一部としてのみ使用できます。

**Possible inputs**（考えられる入力）: 秒、分、または時間単位の時間間隔。1週間以下である必要があります。有効な値の例は以下のとおりです:

- `'5'` (5秒)
- `'10 seconds'`
- `'30 minutes'`
- `'1 hour'`
- `'1 day'`

**Example of `start_in`**（の例）:

```yaml
deploy_production:
  stage: deploy
  script:
    - echo "Deploying to production"
  when: delayed
  start_in: 30 minutes
```

この例では、`deploy_production`ジョブは、前のステージが完了してから30分後に開始されます。

**Additional details**（補足情報）:

- タイマーは、前のジョブが完了したときではなく、ジョブのステージが開始されたときに開始されます。
- 遅延ジョブをすぐに手動で開始するには、パイプラインビューで**Play**（再生）（{{< icon name="play" >}}）を選択します。
- 最小遅延期間は1秒で、最大遅延期間は1週間です。
- `start_in`は、[`when`](#when)が`delayed`に設定されている場合にのみ機能します。`when`に他の値を使用すると、設定は無効になります。ジョブが`rules`を使用する場合、`start_in`と`when`はジョブレベルではなく、`rules`で定義する必要があります。そうでない場合は、検証エラー（`config key may not be used with 'rules': start_in`）が表示されます。
- `start_in`は`workflow:rules`ではサポートされていませんが、構文違反は発生しません。

**Related topics**（関連トピック）:

- [遅延後にジョブを実行する](../jobs/job_control.md#run-a-job-after-a-delay)

---

## `variables` {#variables}

`variables`を使用して、[CI/CD変数](../variables/_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file)を定義します。

変数は、[CI/CDジョブ内で定義する](#job-variables)か、またはすべてのジョブに対する[デフォルトCI/CD変数](#default-variables)を定義するトップレベル（グローバル）キーワードとして定義できます。

**Additional details**（補足情報）:

- YAMLで定義されたすべての変数は、リンクされている[Dockerサービスコンテナ](../services/_index.md)にも設定されます。
- YAMLで定義された変数は、機密性の低いプロジェクトの設定を目的としています。機密情報は、[保護された変数](../variables/_index.md#protect-a-cicd-variable)または[CI/CDシークレット](../secrets/_index.md)に保存してください。
- [手動パイプライン変数](../variables/_index.md#use-pipeline-variables)と[スケジュールされたパイプライン変数](../pipelines/schedules.md#create-a-pipeline-schedule)は、デフォルトではダウンストリームパイプラインに渡されません。これらの変数をダウンストリームパイプラインに転送するには、[`trigger:forward`](#triggerforward)を使用します。

**Related topics**（関連トピック）:

- [定義済み変数](../variables/predefined_variables.md)は、Runnerが自動的に作成し、ジョブで使用できるようにする変数です。
- [変数でRunnerの動作を設定](../runners/configure_runners.md#configure-runner-behavior-with-variables)できます。

---

### ジョブ`variables` {#job-variables}

ジョブ変数は、ジョブの`script`、`before_script`、`after_script`セクション内のコマンド、および一部の[ジョブキーワード](#job-keywords)で使用できます。各ジョブキーワードが変数をサポートしているかについては、それぞれの**Supported values**（サポートされている値）セクションを確認してください。

ジョブ変数を、[`include`](includes.md#use-variables-with-include)などの[グローバルキーワード](#global-keywords)の値として使用することはできません。

**Supported values**（サポートされている値）: 変数名と値のペア:

- 名前には数字、英字、アンダースコア（`_`）のみを使用できます。一部のShellでは、最初の文字が英字でなければなりません。
- 値は文字列でなければなりません。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**Example of `variables` job**（ジョブの例）:

```yaml
review_job:
  variables:
    DEPLOY_SITE: "https://dev.example.com/"
    REVIEW_PATH: "/review"
  script:
    - deploy-review-script --url $DEPLOY_SITE --path $REVIEW_PATH
```

この例では:

- `review_job`では、`DEPLOY_SITE`と`REVIEW_PATH`のジョブ変数が定義されています。これらのジョブ変数は、どちらも`script`セクションで使用できます。

---

### デフォルト`variables` {#default-variables}

トップレベルの`variables`セクションで定義されている変数は、すべてのジョブに対するデフォルト変数として機能します。

各デフォルト変数は、パイプライン内のあらゆるジョブで使用できます。ただし、ジョブで同じ名前の変数がすでに定義されている場合を除きます。ジョブ内で定義された変数が[優先される](../variables/_index.md#cicd-variable-precedence)ため、同じ名前のデフォルト変数の値はジョブ内で使用できません。

ジョブ変数と同様に、[`include`](includes.md#use-variables-with-include)などの他のグローバルキーワードの値としてデフォルト変数を使用することはできません。

**Supported values**（サポートされている値）: 変数名と値のペア:

- 名前には数字、英字、アンダースコア（`_`）のみを使用できます。一部のShellでは、最初の文字が英字でなければなりません。
- 値は文字列でなければなりません。

CI/CD変数が[サポートされています](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)。

**Examples of `variables`**（の例）:

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

この例では:

- `deploy_job`には変数が定義されていません。デフォルトの`DEPLOY_SITE`変数がジョブにコピーされ、それを`script`セクションで使用できます。
- `deploy_review_job`にはすでに`DEPLOY_SITE`変数が定義されているため、デフォルトの`DEPLOY_SITE`はジョブにコピーされません。このジョブには、`REVIEW_PATH`ジョブ変数も定義されています。これらのジョブ変数は、どちらも`script`セクションで使用できます。

---

#### `variables:description` {#variablesdescription}

`description`キーワードを使用して、デフォルト変数の説明を定義します。この説明は、[パイプラインを手動で実行する際に、事前に入力された変数名](../pipelines/_index.md#prefill-variables-in-manual-pipelines)とともに表示されます。

**Keyword type**（キーワードのタイプ）: このキーワードはデフォルト`variables`でのみ使用可能です。ジョブ`variables`では使用できません。

**Supported values**（サポートされている値）: 

- 文字列。Markdownを使用できます。

**Example of `variables:description`**（の例）:

```yaml
variables:
  DEPLOY_NOTE:
    description: "The deployment note. Explain the reason for this deployment."
```

**Additional details**（補足情報）:

- `value`を指定せずに使用した場合、手動でトリガーされなかったパイプラインに変数が存在し、そのデフォルト値は空文字列（`''`）になります。

---

#### `variables:value` {#variablesvalue}

`value`キーワードを使用して、パイプラインレベル（デフォルト）の変数の値を定義します。[`variables: description`](#variablesdescription)と組み合わせて使用すると、変数の値は、[パイプラインを手動で実行したときに事前に入力されます](../pipelines/_index.md#prefill-variables-in-manual-pipelines)。

**Keyword type**（キーワードのタイプ）: このキーワードはデフォルト`variables`でのみ使用可能です。ジョブ`variables`では使用できません。

**Supported values**（サポートされている値）: 

- 文字列。

**Example of `variables:value`**（の例）:

```yaml
variables:
  DEPLOY_ENVIRONMENT:
    value: "staging"
    description: "The deployment target. Change this variable to 'canary' or 'production' if needed."
```

**Additional details**（補足情報）:

- [`variables: description`](#variablesdescription)なしで使用した場合、[`variables`](#variables)と同じ動作になります。

---

#### `variables:options` {#variablesoptions}

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105502)されました。

{{< /history >}}

`variables:options`を使用して、[パイプラインを手動で実行する際にUIで選択できる](../pipelines/_index.md#configure-a-list-of-selectable-prefilled-variable-values)値の配列を定義します。

`variables: value`と組み合わせて使用する必要があります。`value`に指定する文字列の条件は次のとおりです:

- `options`配列内の文字列のいずれかを指定する必要があります。
- デフォルトの選択肢として使用されます。

[`description`](#variablesdescription)がない場合、このキーワードは効果がありません。

**Keyword type**（キーワードのタイプ）: このキーワードはデフォルト`variables`でのみ使用可能です。ジョブ`variables`では使用できません。

**Supported values**（サポートされている値）: 

- 文字列の配列。

**Example of `variables:options`**（の例）:

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

---

### `variables:expand` {#variablesexpand}

{{< history >}}

- GitLab 15.6で`ci_raw_variables_in_yaml_config`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/353991)されました。デフォルトでは無効になっています。
- GitLab 15.6の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/375034)になりました。
- GitLab 15.7の[GitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/375034)になりました。
- GitLab 15.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/375034)になりました。機能フラグ`ci_raw_variables_in_yaml_config`は削除されました。

{{< /history >}}

`expand`キーワードを使用して、変数を展開可能にするかどうかを設定します。

**Keyword type**（キーワードのタイプ）: このキーワードは、デフォルトとジョブの両方の`variables`で使用できます。

**Supported values**（サポートされている値）: 

- `true`（デフォルト）: 変数は展開可能です。
- `false`: 変数は展開できません。

**Example of `variables:expand`**（の例）:

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

**Additional details**（補足情報）:

- `expand`キーワードは、デフォルトおよびジョブ`variables`キーワードでのみ使用できます。[`rules:variables`](#rulesvariables)や[`workflow:rules:variables`](#workflowrulesvariables)では使用できません。
