---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI/CDインプット
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.11でベータ機能として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/391331)されました。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062)になりました。

{{< /history >}}

CI/CDインプットを使用して、CI/CD設定の柔軟性を高めます。インプットと[CI/CD変数](../variables/_index.md)は同様の方法で使用できますが、利点が異なります:

- インプットは、パイプライン作成時に組み込みの検証を備えた、再利用可能なテンプレート用の型付きパラメータを提供します。パイプライン実行時に特定の値を定義するには、CI/CD変数の代わりにインプットを使用します。
- CI/CD変数は、複数のレベルで定義できる柔軟な値を提供しますが、パイプラインの実行全体を通して変更できます。ジョブのランタイム環境でアクセスする必要がある値には変数を使用します。また、動的なパイプライン設定には、[定義済み変数](../variables/predefined_variables.md)を`rules`とともに使用することもできます。

## CI/CDインプットと変数の比較 {#cicd-inputs-and-variables-comparison}

インプット:

- **目的**: CI設定（テンプレート、コンポーネント、または`.gitlab-ci.yml`）で定義され、パイプラインがトリガーされると値が割り当てられ、利用者が再利用可能なCI設定をカスタマイズできるようにします。
- **変更**: パイプライン初期化時に渡されると、インプットの値はCI/CD設定に挿入され、パイプライン実行全体で固定されたままになります。
- **スコープ**: `.gitlab-ci.yml`または`include`されているファイルのいずれであっても、定義されているファイル内でのみ使用できます。`include:inputs`を使用して他のファイルに、または`trigger:inputs`を使用してパイプラインに、明示的に渡すことができます。
- **検証**: 型チェック、正規表現パターン、定義済みオプションリスト、ユーザーに役立つ説明など、堅牢な検証機能を提供します。

CI/CD変数:

- **目的**: ジョブ実行時の環境変数として設定され、パイプラインのさまざまな部分でジョブ間のデータ受け渡しに使用される値です。
- **変更**: dotenvアーティファクト、条件ルール、またはジョブスクリプトで直接、パイプラインの実行中に動的に生成または変更できます。
- **スコープ**: グローバルに（すべてのジョブに影響）、ジョブレベルで（特定のジョブにのみ影響を）、またはGitLab UIからプロジェクトまたはグループ全体に対して定義できます。
- **検証**: 最小限の組み込み検証を備えたシンプルなキー/バリューペアですが、GitLab UIからプロジェクト変数にいくつかの制御を追加できます。

## `spec:inputs`で入力パラメータを定義する {#define-input-parameters-with-specinputs}

CI/CD設定の[ヘッダー](../yaml/_index.md#header-keywords)で`spec:inputs`を使用して、設定ファイルに渡すことができる入力パラメータを定義します。

ヘッダーセクション外で`$[[ inputs.input-id ]]`補間形式を使用して、インプットを使用する場所を宣言します。

例: 

```yaml
spec:
  inputs:
    job-stage:
      default: test
    environment:
      default: production
---
scan-website:
  stage: $[[ inputs.job-stage ]]
  script: ./scan-website $[[ inputs.environment ]]
```

この例では、インプットは`job-stage`と`environment`です。

`spec:inputs`を使用する場合:

- `default`が指定されていない場合、入力は必須です。
- インプットは、パイプライン作成時に設定がフェッチされる際に評価および補間されます。
- インプットを含む文字列は1 MB未満である必要があります。
- インプット内の文字列は1 KB未満である必要があります。
- インプットはCI/CD変数を使用できますが、[`include`キーワードと同じ変数制限](../yaml/includes.md#use-variables-with-include)があります。
- `spec:inputs`を定義するファイルにジョブの定義も含まれている場合は、ヘッダーの後にYAMLドキュメント区切り文字（`---`）を追加します。

以下の場合にインプットの値を設定します:

- この設定ファイルを使用して[新しいパイプラインをトリガーする](#for-a-pipeline)場合。`include`以外の方法で新しいパイプラインを設定する際にインプットを使用する場合は、常にデフォルト値を設定する必要があります。そうしないと、以下のように新しいパイプラインが自動的にトリガーされる場合、パイプラインが起動に失敗する可能性があります:
  - マージリクエストパイプライン
  - ブランチパイプライン
  - タグパイプライン
- パイプラインに[設定を含める](#for-configuration-added-with-include)場合。必須のインプットはいずれも`include:inputs`セクションに追加する必要があり、設定がインクルードされるたびに使用されます。

### インプットの設定 {#input-configuration}

インプットを設定するには、以下を使用します:

- [`spec:inputs:default`](../yaml/_index.md#specinputsdefault)は、指定されていない場合のインプットのデフォルト値を定義します。デフォルトを指定すると、インプットが必須ではなくなります。
- [`spec:inputs:description`](../yaml/_index.md#specinputsdescription)は、特定のインプットに説明を付けます。説明はインプットに影響しませんが、インプットの詳細や予想される値を理解するのに役立ちます。
- [`spec:inputs:options`](../yaml/_index.md#specinputsoptions)は、インプットに許可される値のリストを指定します。
- [`spec:inputs:regex`](../yaml/_index.md#specinputsregex)は、インプットが一致する必要がある正規表現を指定します。
- [`spec:inputs:type`](../yaml/_index.md#specinputstype)は、特定のインプットの型を強制します。型は`string`（指定しない場合のデフォルト）、`array`、`number`、または`boolean`を指定できます。
- 他の入力の値に基づいて条件付きの`options`値と`default`値を定義するには、[`spec:inputs:rules`](../yaml/_index.md#specinputsrules)を使用します。

CI/CD設定ファイルごとに複数のインプットを定義できます。また、各インプットには複数の設定パラメータを指定できます。

たとえば、`scan-website-job.yml`という名前のファイルでは:

```yaml
spec:
  inputs:
    job-prefix:     # Mandatory string input
      description: "Define a prefix for the job name"
    job-stage:      # Optional string input with a default value when not provided
      default: test
    environment:    # Mandatory input that must match one of the options
      options: ['test', 'staging', 'production']
    concurrency:
      type: number  # Optional numeric input with a default value when not provided
      default: 1
    version:        # Mandatory string input that must match the regular expression
      type: string
      regex: ^v\d\.\d+(\.\d+)$
    export_results: # Optional boolean input with a default value when not provided
      type: boolean
      default: true
---

"$[[ inputs.job-prefix ]]-scan-website":
  stage: $[[ inputs.job-stage ]]
  script:
    - echo "scanning website -e $[[ inputs.environment ]] -c $[[ inputs.concurrency ]] -v $[[ inputs.version ]]"
    - if $[[ inputs.export_results ]]; then echo "export results"; fi
```

この例では: 

- `job-prefix`は必須の文字列インプットであり、定義が必要です。
- `job-stage`はオプションです。定義されていない場合、値は`test`になります。
- `environment`は必須の文字列インプットであり、定義されたオプションのいずれかに一致する必要があります。
- `concurrency`はオプションの数値インプットです。指定しない場合、デフォルトは`1`です。
- `version`は必須の文字列インプットであり、指定された正規表現に一致する必要があります。
- `export_results`はオプションのブール値インプットです。指定しない場合、デフォルトは`true`です。

### インプットの型 {#input-types}

オプションの`spec:inputs:type`キーワードを使用して、インプットが特定の型を使用する必要があることを指定できます。

インプットの型は次のとおりです:

- [`array`](#array-type)
- `boolean`
- `number`
- `string`（指定されていない場合のデフォルト）

インプットがCI/CD設定内のYAML値全体を置き換える場合、指定された型として設定を補間します。例: 

```yaml
spec:
  inputs:
    array_input:
      type: array
    boolean_input:
      type: boolean
    number_input:
      type: number
    string_input:
      type: string
---

test_job:
  allow_failure: $[[ inputs.boolean_input ]]
  needs: $[[ inputs.array_input ]]
  parallel: $[[ inputs.number_input ]]
  script: $[[ inputs.string_input ]]
```

インプットがより大きな文字列の一部としてYAML値に挿入される場合、インプットは常に文字列として補間されます。例: 

```yaml
spec:
  inputs:
    port:
      type: number
---

test_job:
  script: curl "https://gitlab.com:$[[ inputs.port ]]"
```

#### 配列型 {#array-type}

{{< history >}}

- GitLab 16.11で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/407176)されました。

{{< /history >}}

配列型の項目の内容は、任意の有効なYAMLマップ、シーケンス、またはスカラーにすることができます。[`!reference`](../yaml/yaml_optimization.md#reference-tags)のような、より複雑なYAML機能は使用できません。文字列内で配列インプットの値を使用する場合（例 `echo "My rules: $[[ inputs.rules-config ]]"`セクションの`script:`）、予期しない結果が表示される場合があります。配列インプットは文字列表現に変換されます。そのため、マップのような複雑なYAML構造では期待どおりの結果が得られない可能性があります。

```yaml
spec:
  inputs:
    rules-config:
      type: array
      default:
        - if: $CI_PIPELINE_SOURCE == "merge_request_event"
          when: manual
        - if: $CI_PIPELINE_SOURCE == "schedule"
---

test_job:
  rules: $[[ inputs.rules-config ]]
  script: ls
```

以下の場合に手動で配列インプットの値を渡すときは、`["array-input-1", "array-input-2"]`のようなJSON形式でフォーマットする必要があります。

- [手動でトリガーされたパイプライン](../pipelines/_index.md#run-a-pipeline-manually)。
- [パイプライントリガーAPI](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token)。
- [パイプラインAPI](../../api/pipelines.md#create-a-new-pipeline)。
- Gitの[プッシュオプション](../../topics/git/commit.md#push-options-for-gitlab-cicd)
- [パイプラインスケジュール](../pipelines/schedules.md#create-a-pipeline-schedule)

#### 複数行のインプット文字列の値 {#multi-line-input-string-values}

インプットは、さまざまな値の型をサポートします。次の形式を使用して、複数行文字列の値を渡すことができます:

```yaml
spec:
  inputs:
    closed_message:
      description: Message to announce when an issue is closed.
      default: 'Hi {{author}} :wave:,

        Based on the policy for inactive issues, this is now being closed.

        If this issue requires further attention, reopen this issue.'
---
```

### `spec:inputs:rules`を使用して、条件付きの入力オプションを定義します {#define-conditional-input-options-with-specinputsrules}

{{< history >}}

- GitLab 18.7で[導入](https://gitlab.com/groups/gitlab-org/-/epics/18546)されました。

{{< /history >}}

他の入力の値に基づいて入力に対して異なる`options`値と`default`値を定義するには、[`spec:inputs:rules`](../yaml/_index.md#specinputsrules)を使用します。この設定は、ある入力が他の入力によって提供されるコンテキストに応じて異なる許可された値を持つ必要がある場合に使用できます。

`rules`リストの各ルールは、次のものを持つことができます:

- `if`: 1つ以上の入力の値をチェックして、このルールをいつ適用するかを判断する式。[`$[[ inputs.input-id ]]`補間](#define-input-parameters-with-specinputs)と同じ構文を使用します。
- `options`: このルールが一致した場合の入力に対して許可される値のリスト。
- `default`: このルールが一致した場合に使用するデフォルト値。

ルールは順番に評価されます。一致する`if`条件を持つ最初のルールが使用されます。`if`条件のない最後のルールは、他のルールが一致しない場合のフォールバックとして機能します。

たとえば、クラウドプロバイダーと環境に基づいて変化するインスタンスタイプを定義するには、次のようにします:

```yaml
spec:
  inputs:
    cloud_provider:
      options: ['aws', 'gcp', 'azure']
      default: 'aws'
      description: 'Cloud provider'

    environment:
      options: ['development', 'staging', 'production']
      default: 'development'
      description: 'Target environment'

    instance_type:
      description: 'VM instance type'
      rules:
        - if: $[[ inputs.cloud_provider ]] == 'aws' && $[[ inputs.environment ]] == 'development'
          options: ['t3.micro', 't3.small']
          default: 't3.micro'
        - if: $[[ inputs.cloud_provider ]] == 'aws' && $[[ inputs.environment ]] == 'production'
          options: ['t3.xlarge', 't3.2xlarge', 'm5.xlarge']
          default: 't3.xlarge'
        - if: $[[ inputs.cloud_provider ]] == 'gcp'
          options: ['e2-micro', 'e2-small', 'e2-standard-4']
          default: 'e2-micro'
        - if: $[[ inputs.cloud_provider ]] == 'azure'
          options: ['Standard_B1s', 'Standard_B2s', 'Standard_D2s_v3']
          default: 'Standard_B1s'
        - options: ['small', 'medium', 'large']  # Fallback for any other case
          default: 'small'
---

deploy:
  script: |
    echo "Deploying to $[[ inputs.cloud_provider ]]"
    echo "Environment: $[[ inputs.environment ]]"
    echo "Instance: $[[ inputs.instance_type ]]"
```

この例では: 

- `cloud_provider`が`aws`で、`environment`が`development`の場合、ユーザーは`t3.micro`または`t3.small`のインスタンスタイプから選択でき、デフォルトは`t3.micro`です。
- `cloud_provider`が`aws`で、`environment`が`production`の場合、異なるインスタンスタイプ(`t3.xlarge`、`t3.2xlarge`、`m5.xlarge`)を利用できます。
- `cloud_provider`が`gcp`の場合、環境に関係なく、GCP固有のインスタンスタイプを利用できます。
- どの条件にも一致しない場合、フォールバックルールは一般的なサイズオプションを提供します。

複数の条件を一致させるには、`||`（OR）演算子を使用することもできます。例: 

```yaml
spec:
  inputs:
    deployment_type:
      options: ['canary', 'blue-green', 'rolling', 'recreate']
      default: 'rolling'

    requires_approval:
      description: 'Whether deployment requires manual approval'
      rules:
        - if: $[[ inputs.deployment_type ]] == 'canary' || $[[ inputs.deployment_type ]] == 'blue-green'
          options: ['true']
          default: 'true'
        - options: ['true', 'false']
          default: 'false'
---

deploy:
  script: echo "Deploying with $[[ inputs.deployment_type ]] strategy"
```

この例では、`deployment_type`が`canary`または`blue-green`のいずれかの場合、`requires_approval`入力は`true`に設定されます。他のすべての場合、デフォルトは`false`であり、`true`または`false`の両方が許可されるオプションです。

### `default: null`でユーザーが入力した値を許可します {#allow-user-entered-values-with-default-null}

{{< history >}}

- GitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218804)されました。

{{< /history >}}

`default: null`を使用した`spec:inputs:rules`を`options`なしで使用すると、ユーザーは入力に独自の値入力できるようになります。これは、環境名やテスト設定など、ワークフロー固有の値に役立ちます。

例: 

```yaml
spec:
  inputs:
    deployment_type:
      options: ['standard', 'custom']
      default: 'standard'

    custom_config:
      description: 'Custom configuration value'
      rules:
        - if: $[[ inputs.deployment_type ]] == 'custom'
          default: null
---

deploy:
  script: echo "Config: $[[ inputs.custom_config ]]"
```

この例では、`deployment_type`が`custom`の場合、`custom_config`入力はパイプラインの実行ページにリストされ、ユーザーはその入力の値を入力する必要があります。

### `spec:inputs:rules`でブール値入力を使用します {#use-boolean-inputs-with-specinputsrules}

ルール条件でブール値入力を使用できます。ブール値は、ブールリテラル（`true`/`false`）を使用して比較できます:

```yaml
spec:
  inputs:
    publish:
      type: boolean
      default: true

    publish_stage:
      rules:
        - if: $[[ inputs.publish ]] == true
          default: 'publish'
        - if: $[[ inputs.publish ]] == false
          default: 'test'
---

job:
  stage: $[[ inputs.publish_stage ]]
  script: echo "Publishing is $[[ inputs.publish ]]"
```

この例では、`publish`が`true`の場合、`publish_stage`のデフォルトは`publish`です。`publish`が`false`の場合、デフォルトは`test`です。

## インプットの値を設定する {#set-input-values}

### `include`で追加された設定の場合 {#for-configuration-added-with-include}

{{< history >}}

- `include:with`は、GitLab 16.0で[`include:inputs`](https://gitlab.com/gitlab-org/gitlab/-/issues/406780)に名前が変更されました。

{{< /history >}}

インクルードされた設定がパイプラインに追加される際、[`include:inputs`](../yaml/_index.md#includeinputs)を使用してインプットの値を設定します。対象となる設定:

- [CI/CDコンポーネント](../components/_index.md)
- [カスタムCI/CDテンプレート](../examples/_index.md#adding-templates-to-your-gitlab-installation)
- `include`で追加されたその他の設定。

たとえば、[インプットの設定の例](#input-configuration)から`scan-website-job.yml`をインクルードしてインプットの値を設定するには:

```yaml
include:
  - local: 'scan-website-job.yml'
    inputs:
      job-prefix: 'some-service-'
      environment: 'staging'
      concurrency: 2
      version: 'v1.3.2'
      export_results: false
```

この例では、インクルードされた設定のインプットは次のようになります:

| インプット            | 値           | 詳細 |
|------------------|-----------------|---------|
| `job-prefix`     | `some-service-` | 明示的に定義する必要があります。 |
| `job-stage`      | `test`          | `include:inputs`で定義されていないため、インクルードされた設定の`spec:inputs:default`から値を取得します。 |
| `environment`    | `staging`       | 明示的に定義する必要があります。インクルードされた設定の`spec:inputs:options`の値のいずれかに一致する必要があります。 |
| `concurrency`    | `2`             | インクルードされた設定で`spec:inputs:type`が`number`に設定されているため、数値である必要があります。デフォルト値をオーバーライドします。 |
| `version`        | `v1.3.2`        | 明示的に定義する必要があります。インクルードされた設定の`spec:inputs:regex`の正規表現に一致する必要があります。 |
| `export_results` | `false`         | インクルードされた設定で`spec:inputs:type`が`boolean`に設定されているため、`true`または`false`のいずれかである必要があります。デフォルト値をオーバーライドします。 |

#### 複数の`include`エントリを使用する場合 {#with-multiple-include-entries}

インプットはincludeエントリごとに個別に指定する必要があります。例: 

```yaml
include:
  - component: $CI_SERVER_FQDN/the-namespace/the-project/the-component@1.0
    inputs:
      stage: my-stage
  - local: path/to/file.yml
    inputs:
      stage: my-stage
```

### パイプラインの場合 {#for-a-pipeline}

{{< history >}}

- GitLab 17.11で[導入](https://gitlab.com/groups/gitlab-org/-/epics/16321)されました。

{{< /history >}}

インプットは、型チェック、検証、明確なコントラクトなど、変数よりも利点があります。予期しないインプットは拒否されます。パイプライン用のインプットは、メイン設定ファイルである`.gitlab-ci.yml`の[`spec:inputs`ヘッダー](#define-input-parameters-with-specinputs)で定義する必要があります。パイプラインレベルの設定にはインクルードされたファイルで定義されたインプットを使用することはできません。

> [!note] [GitLab 17.7](../../update/deprecations.md#increased-default-security-for-use-of-pipeline-variables)以降では、[パイプライン変数](../variables/_index.md#use-pipeline-variables)を渡すよりもパイプライン入力が推奨されます。セキュリティを強化するには、インプットを使用する際に[パイプライン変数を無効にする](../variables/_index.md#restrict-pipeline-variables)必要があります。

パイプライン用のインプットを定義する際は、常にデフォルト値を設定する必要があります。そうしないと、新しいパイプラインが自動的にトリガーされる場合、パイプラインが起動に失敗する可能性があります。たとえば、マージリクエストパイプラインは、マージリクエストのソースブランチへの変更に対してトリガーされる可能性があります。マージリクエストパイプラインに対して手動でインプットを設定することはできないため、デフォルトが欠けているインプットがあると、パイプラインの作成に失敗します。これは、ブランチパイプライン、タグパイプライン、およびその他の自動的にトリガーされるパイプラインでも発生する可能性があります。

次の方法を使用してインプットの値を設定できます:

- [ダウンストリームパイプライン](../pipelines/downstream_pipelines.md#pass-inputs-to-a-downstream-pipeline)
- [手動でトリガーされたパイプライン](../pipelines/_index.md#run-a-pipeline-manually)。
- [パイプライントリガーAPI](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token)
- [パイプラインAPI](../../api/pipelines.md#create-a-new-pipeline)
- Gitの[プッシュオプション](../../topics/git/commit.md#push-options-for-gitlab-cicd)
- [パイプラインスケジュール](../pipelines/schedules.md#create-a-pipeline-schedule)
- [`trigger`キーワード](../pipelines/downstream_pipelines.md#pass-inputs-to-a-downstream-pipeline)

1つのパイプラインは最大20個のインプットを受け取ることができます。

[このイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/533802)に関するフィードバックをお寄せください。

ダウンストリームパイプラインの設定ファイルが[`spec:inputs`](#define-input-parameters-with-specinputs)を使用している場合、[ダウンストリームパイプライン](../pipelines/downstream_pipelines.md)にインプットを渡すことができます。

たとえば、[`trigger:inputs`](../yaml/_index.md#triggerinputs)を使用する場合:

{{< tabs >}}

{{< tab title="親子パイプライン" >}}

```yaml
trigger-job:
  trigger:
    strategy: mirror
    include:
      - local: path/to/child-pipeline.yml
        inputs:
          job-name: "defined"
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
```

{{< /tab >}}

{{< tab title="マルチプロジェクトパイプライン" >}}

```yaml
trigger-job:
  trigger:
    strategy: mirror
    project: project-group/my-downstream-project
    inputs:
      job-name: "defined"
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
```

{{< /tab >}}

{{< /tabs >}}

#### 外部ファイルでパイプライン入力を定義します {#define-pipeline-inputs-in-external-files}

{{< history >}}

- GitLab 18.6で`ci_file_inputs`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/206931)されました。デフォルトでは無効になっています。
- [一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/579240)：GitLab 18.9。機能フラグ`ci_file_inputs`は削除されました。

{{< /history >}}

外部ファイルでパイプライン入力定義を定義し、[`spec:include`](../yaml/_index.md#specinclude)を使用してプロジェクトのパイプライン設定に含めることで、複数のCI/CD設定間で再利用できます。

入力定義を含むファイルを作成します（たとえば、`shared-inputs.yml`という名前のファイル）:

```yaml
inputs:
  environment:
    description: "Deployment environment"
    options: ['staging', 'production']
  region:
    default: 'us-east-1'
```

次に、`local`を使用して、`.gitlab-ci.yml`に外部入力を含めることができます:

```yaml
spec:
  include:
    - local: /shared-inputs.yml
---

deploy:
  script: echo "Deploying to $[[ inputs.environment ]] in $[[ inputs.region ]]"
```

ファイルがプロジェクトの外部に保存されている場合は、以下を使用できます:

- 別のGitLabプロジェクト内のファイルの場合は`project`。完全なプロジェクトパスを使用し、`file`でファイル名を定義します。オプションで、`ref`を定義して、ファイルのフェッチ元を指定することもできます。
- 別のサーバー上のファイルの場合は`remote`。ファイルへの完全なURLを使用します。

たとえば、複数の入力ファイルを同時に含めることもできます:

```yaml
spec:
  include:
    - local: /shared-inputs.yml
    - project: 'my-group/shared-configs'
      ref: main
      file: '/ci/common-inputs.yml'
    - remote: 'https://example.com/ci/shared-inputs.yml'
---
```

> [!note] `spec:include`は、[CI/CDコンポーネント](../components/_index.md#component-spec-section)入力には使用できません。

#### 外部ファイルからのオーバーライド入力 {#override-inputs-from-an-external-file}

{{< history >}}

- GitLab 18.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/557867)されました。

{{< /history >}}

入力キーは、インライン仕様と、含まれるすべてのファイルで一意である必要があります。複数のインクルードファイル、またはインクルードファイルと`.gitlab-ci.yml`設定の`inputs:`セクションの両方で同じキーを持つ入力を定義すると、次のエラーが返されます:

```plaintext
Duplicate input keys found: environment. Input keys must be unique across all included files and inline specifications.
```

このエラーを修正するには、各入力キーが、インクルードファイルまたはインラインの`inputs:`セクションのいずれか一方で1回のみ定義されていることを確認します。

## インプットの値を操作するための関数を指定する {#specify-functions-to-manipulate-input-values}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/409462)されました。

{{< /history >}}

事前定義された関数を補間ブロックで指定して、インプットの値を操作できます。サポートされる形式は次のとおりです:

```yaml
$[[ input.input-id | <function1> | <function2> | ... <functionN> ]]
```

関数を使用する場合:

- [事前定義された補間関数](#predefined-interpolation-functions)のみが許可されます。
- 1つの補間ブロックで指定できる関数は最大3つです。
- 関数は指定した順番で実行されます。

```yaml
spec:
  inputs:
    test:
      default: 'test $MY_VAR'
---

test-job:
  script: echo $[[ inputs.test | expand_vars | truncate(5,8) ]]
```

この例では、インプットがデフォルト値を使用し、`$MY_VAR`が値`my value`を持つマスクされていないプロジェクト変数であると仮定します:

1. まず、関数[`expand_vars`](#expand_vars)が値を`test my value`に展開します。
1. 次に[`truncate`](#truncate)が、文字オフセット`5`と長さ`8`で`test my value`に適用されます。
1. `script`の出力は`echo my value`になります。

### 事前定義された補間関数 {#predefined-interpolation-functions}

#### `expand_vars` {#expand_vars}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/387632)されました。

{{< /history >}}

`expand_vars`を使用して、インプットの値の[CI/CD変数](../variables/_index.md)を展開します。

[`include`キーワードで使用できる](../yaml/includes.md#use-variables-with-include)変数で、[マスクされて](../variables/_index.md#mask-a-cicd-variable)**いない**変数のみを展開できます。[ネストされた変数の展開](../variables/where_variables_can_be_used.md#nested-variable-expansion)はサポートされていません。

例: 

```yaml
spec:
  inputs:
    test:
      default: 'test $MY_VAR'
---

test-job:
  script: echo $[[ inputs.test | expand_vars ]]
```

この例では、`$MY_VAR`がマスクされていない（ジョブログに公開されている）状態で値が`my value`の場合、インプットは`test my value`に展開されます。

#### `truncate` {#truncate}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/409462)されました。

{{< /history >}}

`truncate`を使用して、補間された値を短縮します。例: 

- `truncate(<offset>,<length>)`

| 名前 | 型 | 説明 |
| ---- | ---- | ----------- |
| `offset` | 整数 | オフセットする文字数。 |
| `length` | 整数 | オフセット後に返す文字数。 |

例: 

```yaml
$[[ inputs.test | truncate(3,5) ]]
```

`inputs.test`の値が`0123456789`であると仮定すると、出力は`34567`になります。

#### `posix_escape` {#posix_escape}

{{< history >}}

- GitLab 18.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/568289)されました。

{{< /history >}}

入力値のPOSIX _Bourne Shell_の制御文字またはメタ文字をエスケープするには、`posix_escape`を使用します。`posix_escape`は、入力内の関連文字の前に` \ `を挿入することで文字をエスケープします。

例: 

```yaml
spec:
  inputs:
    test:
      default: |
        A string with single ' and double " quotes and   blanks
---

test-job:
  script: printf '%s\n' $[[ inputs.test | posix_escape ]]
```

この例では、`posix_escape`はShell制御文字またはメタデータ文字である可能性のある文字をエスケープします:

```console
$ printf '%s\n' A\ string\ with\ single\ \'\ and\ double\ \"\ quotes\ and\ \ \ blanks
A string with single ' and double " quotes and   blanks
```

エスケープされた入力は、指定されたとおりに特殊文字とスペースを保持します。

> [!warning]信頼できない入力値を使用するセキュリティ目的で`posix_escape`に依存しないでください。

`posix_escape`は、入力値を正確に保持するために最善を尽くしますが、一部の文字の組み合わせは、予期しない結果を引き起こす可能性があります。`posix_escape`を使用している場合でも、次のことが可能です:

- 文字列に含まれるShellコードが実行される可能性があります。
- 単一引用符または二重引用符を使用して、周囲の引用符をエスケープする可能性があります。
- 変数参照を使用して、保護された変数にアクセスする可能性があります。
- 入力または出力のリダイレクトを使用して、ローカルファイルを読み書きする可能性があります。
- エスケープされていないスペースは、文字列を複数の引数に分割するためにShellによって使用されます。

セキュリティのために、入力が信頼できることを確認する必要があります。使用できるモデルは次のとおりです:

- 問題のある文字を含めることができない[`spec:input:type`](../yaml/_index.md#specinputstype) `number`または`boolean`。
- 問題のある入力を防止する[`spec:input:regex`](../yaml/_index.md#specinputsregex)キーワード。
- 入力オプションの定義済みリストを定義する[`spec:input:options`](../yaml/_index.md#specinputsoptions)キーワード。

`posix_escape`を`expand_vars`と組み合わせる場合は、最初に`expand_vars`を設定する必要があります。そうしないと、`posix_escape`は変数の`$`をエスケープし、展開を防ぎます。例: 

```yaml
test-job:
  script: echo $[[ inputs.test | expand_vars | posix_escape ]]
```

## トラブルシューティング {#troubleshooting}

### `inputs`使用時のYAML構文エラー {#yaml-syntax-errors-when-using-inputs}

`rules:if`の[CI/CD変数式](../jobs/job_rules.md#cicd-variable-expressions)は、CI/CD変数と文字列の比較を想定しています。これに該当しない場合、[さまざまな構文エラーが返される可能性があります](../jobs/job_troubleshooting.md#this-gitlab-ci-configuration-is-invalid-for-variable-expressions)。

インプットの値を設定に挿入した後も、式が適切な形式を維持していることを確認する必要があります。これには、追加の引用符文字の使用が必要になる場合があります。

例: 

```yaml
spec:
  inputs:
    branch:
      default: $CI_DEFAULT_BRANCH
---

job-name:
  rules:
    - if: $CI_COMMIT_REF_NAME == $[[ inputs.branch ]]
```

この例では: 

- `include: inputs: branch: $CI_DEFAULT_BRANCH`の使用は有効です。`if:`句は`if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH`に評価されます。これは有効な変数式です。
- `include: inputs: branch: main`の使用は**無効**です。`if:`句は`if: $CI_COMMIT_REF_NAME == main`に評価されます。これは、`main`が文字列であるにもかかわらず引用符で囲まれていないため無効になります。

代替策として、引用符を追加することで変数式の問題を解決できます。例: 

```yaml
spec:
  inputs:
    environment:
      default: "$ENVIRONMENT"
---

$[[ inputs.environment | expand_vars ]] job:
  script: echo
  rules:
    - if: '"$[[ inputs.environment | expand_vars ]]" == "production"'
```

この例では、インプットブロックと変数式全体を引用符で囲むことで、インプットの評価後も`if:`構文が正しく機能します。式内の内側の引用符と外側の引用符を同じ文字にすることはできません。内側の引用部には`"`を、外側の引用部には`'`を使用します。内側と外側を入れ替えることもできます。一方、ジョブ名には引用符は必要ありません。
