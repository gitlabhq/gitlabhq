---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンプライアンスパイプライン（非推奨）
description: コンプライアンスパイプライン（17.3で非推奨、19.0で削除予定）を使用すると、ラベル付きプロジェクトのCI/CD制御を一元化できます。パイプライン実行ポリシーに置き換えられました。
---

<!--- start_remove The following content will be removed on remove_date: '2026-08-15' -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< alert type="warning" >}}

この機能は、GitLab 17.3で[非推奨](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159841)となり、19.0で削除される予定です。代わりに[パイプライン実行ポリシータイプ](../application_security/policies/pipeline_execution_policies.md)を使用してください。これは破壊的な変更です。詳細については、[移行ガイド](#pipeline-execution-policies-migration)を参照してください。

{{< /alert >}}

グループオーナーは、他のプロジェクトとは別のプロジェクトでコンプライアンスパイプラインを設定できます。デフォルトでは、ラベル付きプロジェクトのコンプライアンスパイプライン設定（例：`.compliance-gitlab-ci.yml`）は、パイプライン設定（例：`.gitlab-ci.yml`）の代わりに実行されます。

ただし、コンプライアンスパイプライン設定は、ラベル付きプロジェクトの`.gitlab-ci.yml`ファイルを参照して、次のことを行うことができます:

- コンプライアンスパイプラインは、ラベル付きプロジェクトパイプラインのジョブも実行できます。これにより、パイプライン設定の一元管理が可能になります。
- コンプライアンスパイプラインで定義されたジョブと変数は、ラベル付きプロジェクトの`.gitlab-ci.yml`ファイル内の変数によって変更できません。

{{< alert type="note" >}}

[既知の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/414004)により、プロジェクトがダウンストリーム設定を上書きするのを防ぐために、プロジェクトパイプラインは、コンプライアンスパイプライン設定の先頭に最初に含める必要があります。

{{< /alert >}}

詳細については、以下を参照してください:

- ラベル付きプロジェクトパイプライン設定からジョブを実行するコンプライアンスパイプラインを設定するための[設定例](#example-configuration)。
- [コンプライアンスパイプラインの作成](../../tutorials/compliance_pipeline/_index.md)チュートリアル。

## パイプライン実行ポリシーの移行 {#pipeline-execution-policies-migration}

スキャンとパイプラインの適用を統合および簡素化するために、パイプライン実行ポリシーが導入されました。GitLab 17.3ではコンプライアンスパイプラインを非推奨とし、GitLab 19.0ではコンプライアンスパイプラインを削除する予定です。

パイプライン実行ポリシーは、パイプライン実行ポリシーにリンクされている個別のYAMLファイル（たとえば、`pipeline-execution.yml`）で提供される設定を使用して、プロジェクトの`.gitlab-ci.yml`ファイルを拡張します。

デフォルトでは、新しいコンプライアンスフレームワークを作成する場合、コンプライアンスパイプラインではなく、パイプライン実行ポリシータイプを使用するように指示されます。

既存のコンプライアンスパイプラインを移行する必要があります。お客様は、できるだけ早くコンプライアンスパイプラインから新しい[パイプライン実行ポリシータイプ](../application_security/policies/pipeline_execution_policies.md)に移行する必要があります。

### 既存のコンプライアンスフレームワークを移行する {#migrate-an-existing-compliance-framework}

既存のコンプライアンスフレームワークを移行して、パイプライン実行ポリシータイプを使用するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **コンプライアンスセンター**を選択します。
1. 既存のコンプライアンスフレームワークを[編集](compliance_frameworks/_index.md#create-edit-or-delete-a-compliance-framework)します。
1. 表示されるバナーで、**パイプラインをポリシーに移行する**を選択して、セキュリティポリシーに新しいポリシーを作成します。
1. コンプライアンスパイプラインを削除するには、コンプライアンスフレームワークを再度編集します。

詳細については、[セキュリティポリシープロジェクト](../application_security/policies/enforcement/security_policy_projects.md)を参照してください。

移行中に`Pipeline execution policy error: Job names must be unique`エラーが発生した場合は、[関連するトラブルシューティング情報](#error-job-names-must-be-unique)を参照してください。

## ラベル付きプロジェクトへの影響 {#effect-on-labeled-projects}

ユーザーは、コンプライアンスパイプラインが設定されていることを知ることができず、独自のパイプラインがまったく実行されない理由、または自分で定義していないジョブが含まれている理由について混乱する可能性があります。

ラベル付きプロジェクトでパイプラインを作成する場合、コンプライアンスパイプラインが設定されているという表示はありません。プロジェクトレベルでの唯一のマーカーは、コンプライアンスフレームワークラベル自体ですが、このラベルは、フレームワークにコンプライアンスパイプラインが設定されているかどうかを示していません。

したがって、プロジェクトユーザーとコンプライアンスパイプライン設定についてコミュニケーションを取り、不確実性と混乱を軽減します。

### 複数のコンプライアンスフレームワーク {#multiple-compliance-frameworks}

コンプライアンスパイプラインが設定された複数のコンプライアンスフレームワークを[単一のプロジェクトに適用](compliance_frameworks/_index.md#apply-a-compliance-framework-to-a-project)できます。この場合、プロジェクトに適用される最初のコンプライアンスフレームワークのみが、プロジェクトパイプラインにコンプライアンスパイプラインを含みます。

正しいコンプライアンスパイプラインがプロジェクトに含まれていることを確認するには、次の手順に従います:

1. プロジェクトからすべてのコンプライアンスフレームワークを削除します。
1. 正しいコンプライアンスパイプラインを含むコンプライアンスフレームワークをプロジェクトに適用します。
1. 追加のコンプライアンスフレームワークをプロジェクトに適用します。

## コンプライアンスパイプラインを設定する {#configure-a-compliance-pipeline}

{{< history >}}

- GitLab 15.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/383209)。コンプライアンスフレームワークがコンプライアンスセンターに移動しました。

{{< /history >}}

コンプライアンスパイプラインを設定するには、次の手順に従います:

1. 左側のサイドバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左側のサイドバーで、**セキュリティ** > **Compliance Center**（コンプライアンスセンター） を選択します。
1. **フレームワーク**セクションを選択します。
1. **新規フレームワーク**セクションを選択し、コンプライアンスフレームワーク設定へのパスを含む、コンプライアンスフレームワークの情報を追加します。`path/file.y[a]ml@group-name/project-name`の形式を使用してください。例: 

   - `.compliance-ci.yml@gitlab-org/gitlab`
   - `.compliance-ci.yaml@gitlab-org/gitlab`

この設定は、コンプライアンスフレームワークラベルが[適用](../project/working_with_projects.md#add-a-compliance-framework-to-a-project)されているプロジェクトに継承されます。コンプライアンスフレームワークラベルが適用されたプロジェクトでは、ラベル付きプロジェクト自身のパイプライン設定の代わりに、コンプライアンスパイプライン設定が実行されます。

ラベル付きプロジェクトでパイプラインを実行しているユーザーは、少なくともコンプライアンスプロジェクトのレポーターロールを持っている必要があります。

スキャンの実行を強制するために使用すると、この機能は[スキャン実行ポリシー](../application_security/policies/scan_execution_policies.md)とオーバーラップする部分があります。これらの2つの機能の[ユーザーエクスペリエンスを統合していません](https://gitlab.com/groups/gitlab-org/-/epics/7312)。

### 設定例 {#example-configuration}

次の例の`.compliance-gitlab-ci.yml`には、ラベル付きプロジェクトのパイプライン設定も実行されるようにするための`include`キーワードが含まれています。

```yaml
include:  # Execute individual project's configuration (if project contains .gitlab-ci.yml)
  - project: '$CI_PROJECT_PATH'
    file: '$CI_CONFIG_PATH'
    ref: '$CI_COMMIT_SHA' # Must be defined or MR pipelines always use the use default branch
    rules:
      - if: $CI_PROJECT_PATH != "my-group/project-1" # Must run on projects other than the one hosting this configuration.

# Allows compliance team to control the ordering and interweaving of stages/jobs.
# Stages without jobs defined will remain hidden.
stages:
  - pre-compliance
  - build
  - test
  - pre-deploy-compliance
  - deploy
  - post-compliance

variables:  # Can be overridden by setting a job-specific variable in project's local .gitlab-ci.yml
  FOO: sast

sast:  # None of these attributes can be overridden by a project's local .gitlab-ci.yml
  variables:
    FOO: sast
  image: ruby:2.6
  stage: pre-compliance
  rules:
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS && $CI_PIPELINE_SOURCE == "push"
      when: never
    - when: always  # or when: on_success
  allow_failure: false
  before_script:
    - "# No before scripts."
  script:
    - echo "running $FOO"
  after_script:
    - "# No after scripts."

sanity check:
  image: ruby:2.6
  stage: pre-deploy-compliance
  rules:
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS && $CI_PIPELINE_SOURCE == "push"
      when: never
    - when: always  # or when: on_success
  allow_failure: false
  before_script:
    - "# No before scripts."
  script:
    - echo "running $FOO"
  after_script:
    - "# No after scripts."

audit trail:
  image: ruby:2.7
  stage: post-compliance
  rules:
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS && $CI_PIPELINE_SOURCE == "push"
      when: never
    - when: always  # or when: on_success
  allow_failure: false
  before_script:
    - "# No before scripts."
  script:
    - echo "running $FOO"
  after_script:
    - "# No after scripts."
```

`include`定義の`rules`設定は、ホストプロジェクト自体でコンプライアンスパイプラインを実行できる必要がある場合に、循環的な包含を回避します。コンプライアンスパイプラインがラベル付きプロジェクトでのみ実行される場合は、省略できます。

#### コンプライアンスパイプラインと、外部でホストされるカスタムパイプライン設定 {#compliance-pipelines-and-custom-pipeline-configuration-hosted-externally}

前の例では、すべてのプロジェクトがパイプライン設定を同じプロジェクトでホストしていることを前提としています。プロジェクトで[外部でホストされる設定](../../ci/pipelines/settings.md#specify-a-custom-cicd-configuration-file)を使用している場合、設定例は機能しません。詳細については、[issue 393960](https://gitlab.com/gitlab-org/gitlab/-/issues/393960)を参照してください。

外部でホストされる設定を使用するプロジェクトでは、次の回避策を試すことができます:

- コンプライアンスパイプライン設定例の`include`セクションを調整する必要があります。例えば、[`include:rules`](../../ci/yaml/includes.md#use-rules-with-include)を使用する場合は次のようになります:

  ```yaml
  include:
    # If the custom path variables are defined, include the project's external config file.
    - project: '$PROTECTED_PIPELINE_CI_PROJECT_PATH'
      file: '$PROTECTED_PIPELINE_CI_CONFIG_PATH'
      ref: '$PROTECTED_PIPELINE_CI_REF'
      rules:
        - if: $PROTECTED_PIPELINE_CI_PROJECT_PATH && $PROTECTED_PIPELINE_CI_CONFIG_PATH && $PROTECTED_PIPELINE_CI_REF
    # If any custom path variable is not defined, include the project's internal config file as normal.
    - project: '$CI_PROJECT_PATH'
      file: '$CI_CONFIG_PATH'
      ref: '$CI_COMMIT_SHA'
      rules:
        - if: $PROTECTED_PIPELINE_CI_PROJECT_PATH == null || $PROTECTED_PIPELINE_CI_CONFIG_PATH == null || $PROTECTED_PIPELINE_CI_REF == null
  ```

- 外部パイプライン設定を持つプロジェクトには、[CI/CD変数](../../ci/variables/_index.md)を追加する必要があります。この例では: 

  - `PROTECTED_PIPELINE_CI_PROJECT_PATH`: 設定ファイルをホストするプロジェクトへのパス（たとえば、`group/subgroup/project`）。
  - `PROTECTED_PIPELINE_CI_CONFIG_PATH`: プロジェクト内の設定ファイルへのパス（たとえば、`path/to/.gitlab-ci.yml`）。
  - `PROTECTED_PIPELINE_CI_REF`: 設定ファイル取得時に使用する参照（例：`main`）。

#### プロジェクトフォークで開始されたマージリクエストのコンプライアンスパイプライン {#compliance-pipelines-in-merge-requests-originating-in-project-forks}

マージリクエストがフォークで開始された場合、マージされるブランチは通常、フォークにのみ存在します。コンプライアンスパイプラインを持つプロジェクトに対してそのようなマージリクエストを作成すると、前のスニペットが`Project <project-name> reference <branch-name> does not exist!`エラーメッセージで失敗します。このエラーは、ターゲットプロジェクトのコンテキストでは、`$CI_COMMIT_REF_NAME`が存在しないブランチ名と評価されるために発生します。

正しいコンテキストを取得するには、`$CI_PROJECT_PATH`の代わりに`$CI_MERGE_REQUEST_SOURCE_PROJECT_PATH`を使用します。この変数は、[マージリクエストパイプライン](../../ci/pipelines/merge_request_pipelines.md)でのみ使用できます。

たとえば、プロジェクトフォークとブランチパイプラインで開始されたマージリクエストパイプラインの両方をサポートする設定では、[`include`ディレクティブと`rules:if`の両方を組み合わせる](../../ci/yaml/includes.md#use-rules-with-include)必要があります:

```yaml
include:  # Execute individual project's configuration (if project contains .gitlab-ci.yml)
  - project: '$CI_MERGE_REQUEST_SOURCE_PROJECT_PATH'
    file: '$CI_CONFIG_PATH'
    ref: '$CI_COMMIT_REF_NAME'
    rules:
      - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
  - project: '$CI_PROJECT_PATH'
    file: '$CI_CONFIG_PATH'
    ref: '$CI_COMMIT_REF_NAME'
    rules:
      - if: $CI_PIPELINE_SOURCE != 'merge_request_event'
```

#### 設定ファイルがないプロジェクトのコンプライアンスパイプライン {#compliance-pipelines-in-projects-with-no-configuration-file}

[設定例](#example-configuration)は、すべてのプロジェクトにパイプライン設定ファイル（デフォルトでは`.gitlab-ci.yml`）が含まれていることを前提としています。ただし、設定ファイルがないプロジェクト（したがって、デフォルトではパイプラインがない）では、`include:project`で指定されたファイルが必要なため、コンプライアンスパイプラインは失敗します。

ターゲットプロジェクトに存在する場合にのみ設定ファイルを含めるには、[`rules:exists:project`](../../ci/yaml/_index.md#rulesexistsproject)を使用します:

```yaml
include:  # Execute individual project's configuration
  - project: '$CI_PROJECT_PATH'
    file: '$CI_CONFIG_PATH'
    ref: '$CI_COMMIT_SHA'
    rules:
      - exists:
          paths:
            - '$CI_CONFIG_PATH'
          project: '$CI_PROJECT_PATH'
          ref: '$CI_COMMIT_SHA'
```

この例では、設定ファイルは、`exists:project: $CI_PROJECT_PATH'`のプロジェクトの特定の`ref`に存在する場合にのみ含まれます。

`exists:project`がコンプライアンスパイプライン設定で指定されていない場合、`include`が定義されているプロジェクト内のファイルを検索します。コンプライアンスパイプラインでは、前の例の`include`は、パイプラインを実行しているプロジェクトではなく、コンプライアンスパイプライン設定ファイルをホストしているプロジェクトで定義されています。

## コンプライアンスジョブが常に実行されるようにする {#ensure-compliance-jobs-are-always-run}

コンプライアンスパイプラインは[GitLab CI/CDを使用](../../ci/_index.md)して、必要なあらゆる種類のコンプライアンスジョブを定義するための驚くほど優れた柔軟性を提供します。目標に応じて、これらのジョブは次のように設定できます:

- ユーザーが変更。
- 変更不可。

一般に、コンプライアンスジョブの値が次の場合は、:

- 設定されている場合、プロジェクトレベルの設定によって変更またはオーバーライドすることはできません。
- 設定されていない場合、プロジェクトレベルの設定を設定できます。

どちらも、ユースケースによっては必要かどうかが異なる場合があります。

これらのジョブが常に定義したとおりに正確に実行され、ダウンストリームのプロジェクトレベルのパイプライン設定がそれらを変更できないようにするためのベストプラクティスを次に示します:

- 各コンプライアンスジョブに[`rules:when:always`ブロック](../../ci/yaml/_index.md#when)を追加します。これにより、変更できなくなり、常に実行されるようになります。
- ジョブが参照する[変数](../../ci/yaml/_index.md#variables)を明示的に設定します。これは:
  - プロジェクトレベルのパイプライン設定がそれらを設定せず、その動作を変更しないようにします。たとえば、[設定例](#example-configuration)の`before_script`および`after_script`設定を参照してください。
  - ジョブのロジックを駆動するジョブをすべて含めます。
- ジョブの実行対象となる[コンテナイメージ](../../ci/yaml/_index.md#image)を明示的に設定します。これにより、スクリプトの手順が正しい環境で実行されるようになります。
- 関連するGitLab事前定義済み[ジョブキーワード](../../ci/yaml/_index.md#job-keywords)を明示的に設定します。これにより、ジョブが意図した設定を使用し、プロジェクトレベルのパイプラインによってオーバーライドされないようになります。

## トラブルシューティング {#troubleshooting}

### コンプライアンスジョブは、ターゲットリポジトリによって上書きする {#compliance-jobs-are-overwritten-by-target-repository}

コンプライアンスパイプライン設定で`extends`ステートメントを使用すると、コンプライアンスジョブはターゲットリポジトリジョブによって上書きされます。例えば、次の`.compliance-gitlab-ci.yml`の設定を使用できます:

```yaml
"compliance job":
  extends:
    - .compliance_template
  stage: build

.compliance_template:
  script:
    - echo "take compliance action"
```

次の`.gitlab-ci.yml`設定も可能です:

```yaml
"compliance job":
  stage: test
  script:
    - echo "overwriting compliance action"
```

この設定により、ターゲットリポジトリパイプラインがコンプライアンスパイプラインを上書きし、次のメッセージが表示されます: `overwriting compliance action`

コンプライアンスジョブの上書きを回避するには、コンプライアンスパイプライン設定で`extends`キーワードを使用しないでください。例えば、次の`.compliance-gitlab-ci.yml`の設定を使用できます:

```yaml
"compliance job":
  stage: build
  script:
    - echo "take compliance action"
```

次の`.gitlab-ci.yml`設定も可能です:

```yaml
"compliance job":
  stage: test
  script:
    - echo "overwriting compliance action"
```

この設定では、コンプライアンスパイプラインは上書きされず、次のメッセージが表示されます: `take compliance action`

### 事前に入力された変数が表示されない {#prefilled-variables-are-not-shown}

[既知の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/382857)により、GitLab 15.3以降のコンプライアンスパイプラインは、[事前に入力された変数](../../ci/pipelines/_index.md#prefill-variables-in-manual-pipelines)がパイプラインを手動で開始するときに表示されないようにする可能性があります。

この問題を回避策するには、個々のプロジェクトの設定を実行する`include:`ステートメントで、`ref: '$CI_COMMIT_REF_NAME'`の代わりに`ref: '$CI_COMMIT_SHA'`を使用します。

[設定例](#example-configuration)がこの変更で更新されました:

```yaml
include:
  - project: '$CI_PROJECT_PATH'
    file: '$CI_CONFIG_PATH'
    ref: '$CI_COMMIT_SHA'
```

### エラー: `Job names must be unique` {#error-job-names-must-be-unique}

コンプライアンスパイプラインを設定するために、[設定例](#example-configuration)では、`include.project`を使用して個々のプロジェクト設定を含めることを推奨しています。

この設定により、プロジェクトパイプラインの実行時にエラーが発生する可能性があります：`Pipeline execution policy error: Job names must be unique`。このエラーは、パイプライン実行ポリシーにプロジェクトの`.gitlab-ci.yml`が含まれており、ジョブがパイプラインですでに宣言されている場合に、ジョブを挿入しようとするために発生します。

このエラーを解決するには、パイプライン実行ポリシーにリンクされている個別のYAMLファイルから`include.project`を削除します。

<!--- end_remove -->
