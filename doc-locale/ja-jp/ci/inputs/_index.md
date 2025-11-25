---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CDの入力
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.11でベータ機能として[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/391331)されました。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062)になりました。

{{< /history >}}

CI/CDの入力を使用して、CI/CD設定の柔軟性を高めます。入力と[CI/CD変数](../variables/_index.md)は同様の方法で使用できますが、利点が異なります:

- 入力は、パイプラインの作成時に組み込み検証を行う、再利用可能なテンプレートの型指定されたパラメータを提供します。パイプラインの実行時に特定の値割り当てするには、CI/CD変数の代わりに入力を使用します。
- CI/CD変数は、複数のレベルで定義できる柔軟な値を提供しますが、パイプラインの実行全体を通して変更できます。ジョブのランタイム環境でアクセスする必要がある値には変数を使用します。動的なパイプライン設定のために、[定義済み変数](../variables/predefined_variables.md)を`rules`とともに使用することもできます。

## CI/CDの入力と変数の比較 {#cicd-inputs-and-variables-comparison}

入力:

- **Purpose**（目的）: CI設定（テンプレート、コンポーネント、または`.gitlab-ci.yml`）で定義され、パイプラインがトリガーされると値が割り当てられ、コンシューマは再利用可能なCI設定をカスタマイズできます。
- **Modification**（変更）: パイプラインの初期化時に一度渡されると、入力値はCI/CD設定に挿入され、パイプラインの実行全体で固定されたままになります。
- **スコープ**: `.gitlab-ci.yml`または`include`dされているファイルにあるかどうかに関係なく、定義されているファイル内でのみ使用できます。`include:inputs`を使用して他のファイルに、または`trigger:inputs`を使用してパイプラインに明示的に渡すことができます。
- **Validation**（検証）: 型チェック、正規表現パターン、定義済みオプションリスト、およびユーザーに役立つ説明を含む、堅牢な検証機能を提供します。

CI/CD変数:

- **Purpose**（目的）: ジョブの実行中、およびジョブ間でデータを渡すためのパイプラインのさまざまな部分で環境変数として設定できる値。
- **Modification**（変更）: dotenvアーティファクト、条件ルール、またはジョブスクリプトで直接、パイプラインの実行中に動的に生成または変更できます。
- **スコープ**: GitLab UIを介して、グローバルに（すべてのジョブに影響を与える）、ジョブレベルで（特定のジョブにのみ影響を与える）、またはプロジェクトまたはグループ全体に対して定義できます。
- **Validation**（検証）: 最小限の組み込み検証を備えたシンプルなキー/バリューペアですが、プロジェクト変数用のGitLab UIを介して一部のコントロールを追加できます。

## `spec:inputs`を使用して入力パラメータを定義する {#define-input-parameters-with-specinputs}

設定ファイルに渡すことができる入力パラメータを定義するには、CI/CD設定の[ヘッダー](../yaml/_index.md#header-keywords)にある`spec:inputs`を使用します。

ヘッダーセクションの外で`$[[ inputs.input-id ]]`補間形式を使用して、インプットを使用する場所を宣言します。

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
- 入力は、パイプラインの作成時に設定がフェッチされるときに評価および補間されます。
- インプットを含む文字列は1 MB未満である必要があります。
- インプット内の文字列は1KB未満である必要があります。
- インプットではCI/CD変数を使用できますが、[`include`キーワードと同じ変数の制限](../yaml/includes.md#use-variables-with-include)があります。
- `spec:inputs`を定義するファイルにジョブの定義も含まれている場合は、ヘッダーの後にYAMLドキュメントの区切り文字（`---`）を追加します。

次に、次のときに入力の値を設定します:

- この設定ファイルを使用して[新しいパイプラインをトリガーする](#for-a-pipeline)。`include`以外の方法で新しいパイプラインを設定するために入力を使用する場合は、常にデフォルト値を設定する必要があります。そうしないと、新しいパイプラインが自動的にトリガーされた場合、パイプラインが起動に失敗する可能性があります:
  - マージリクエストパイプライン
  - ブランチパイプライン
  - タグパイプライン
- パイプラインに[設定を含める](#for-configuration-added-with-include)。必須の入力は`include:inputs`セクションに追加する必要があり、設定がインクルードされるたびに使用されます。

### 入力設定 {#input-configuration}

入力を設定するには、以下を使用します:

- 指定されていない場合にインプットのデフォルト値を定義するには、[`spec:inputs:default`](../yaml/_index.md#specinputsdefault)を使用します。デフォルトを指定すると、インプットが必須ではなくなります。
- 特定のインプットに説明を付けるには、[`spec:inputs:description`](../yaml/_index.md#specinputsdescription)を使用します。説明はインプットには影響しませんが、インプットの詳細や予想される値を理解するのに役立ちます。
- インプットに対して許可される値をリストで指定するには、[`spec:inputs:options`](../yaml/_index.md#specinputsoptions)を使用します。
- インプットが一致する必要がある正規表現を指定するには、[`spec:inputs:regex`](../yaml/_index.md#specinputsregex)を使用します。
- 特定のインプットのタイプを規定するには、[`spec:inputs:type`](../yaml/_index.md#specinputstype)を使用します。タイプは`string`（指定されていない場合のデフォルト）、`array`、`number`、または`boolean`に指定することができます。

CI/CD設定ファイルごとに複数のインプットを定義できます。また、各インプットは複数の設定パラメータを持つことができます。

たとえば、`scan-website-job.yml`という名前のファイルでは、次のようになります:

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

この例では、次のようになります:

- `job-prefix`は必須の文字列インプットであり、定義が必要です。
- `job-stage`はオプションです。定義されていない場合、値は`test`になります。
- `environment`は必須の文字列インプットであり、定義されたオプションのいずれかに一致する必要があります。
- `concurrency`はオプションの数値インプットです。指定しない場合、デフォルトは`1`になります。
- `version`は必須の文字列インプットであり、指定された正規表現に一致する必要があります。
- `export_results`はオプションのブール値インプットです。指定しない場合、デフォルトは`true`になります。

### インプット型 {#input-types}

オプションの`spec:inputs:type`キーワードを使用して、インプットが特定のタイプを使用する必要があることを指定できます。

インプットタイプは次のとおりです:

- [`array`](#array-type)
- `boolean`
- `number`
- `string`（指定されていない場合のデフォルト）

インプットがCI/CD設定内のYAML値全体を置き換える場合、指定されたタイプとして設定を補間します。例: 

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

配列タイプのアイテムの内容は、有効なYAMLマップ、シーケンス、またはスカラーにすることができます。より複雑なYAML機能（[`!reference`](../yaml/yaml_optimization.md#reference-tags)など）は使用できません。文字列で配列入力の値を使用する場合（たとえば、`echo "My rules: $[[ inputs.rules-config ]]"`セクションの`script:`）、予期しない結果が表示される場合があります。配列入力は文字列表示に変換されます。これは、マップなどの複雑なYAML構造に対する期待と一致しない可能性があります。

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

配列入力は、`["array-input-1", "array-input-2"]`のようにJSONとしてフォーマットする必要があります。次に手動で入力を渡します:

- [手動でトリガーされるパイプライン](../pipelines/_index.md#run-a-pipeline-manually)。
- [パイプライントリガーAPI](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token)。
- [パイプラインAPI](../../api/pipelines.md#create-a-new-pipeline)
- [プッシュオプション](../../topics/git/commit.md#push-options-for-gitlab-cicd)を使用する。
- [パイプラインスケジュール](../pipelines/schedules.md#create-a-pipeline-schedule)

#### 複数行の入力文字列の値 {#multi-line-input-string-values}

入力は、さまざまな値の型をサポートします。次の形式を使用して、複数文字列の値を渡すことができます:

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

## 入力値を設定する {#set-input-values}

### `include`で追加された設定について {#for-configuration-added-with-include}

{{< history >}}

- `include:with`は、GitLab 16.0で名称が変更され、[`include:inputs`](https://gitlab.com/gitlab-org/gitlab/-/issues/406780)になりました。

{{< /history >}}

インクルードされた設定がパイプラインに追加されるときの入力の値を設定するには、[`include:inputs`](../yaml/_index.md#includeinputs)を使用します:

- [CI/CDコンポーネント](../components/_index.md)
- [カスタムCI/CDテンプレート](../examples/_index.md#adding-templates-to-your-gitlab-installation)
- `include`で追加されたその他の設定。

たとえば、[入力設定の例](#input-configuration)から`scan-website-job.yml`の入力値をインクルードして設定するには:

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
| `job-stage`      | `test`          | `include:inputs`では定義されないため、値はインクルードされた設定の`spec:inputs:default`から取得します。 |
| `environment`    | `staging`       | 明示的に定義し、インクルードされた設定の`spec:inputs:options`の値の1つと一致する必要があります。 |
| `concurrency`    | `2`             | インクルードされた設定で`number`に指定された`spec:inputs:type`に一致させるため、数値である必要があります。デフォルト値を上書きします。 |
| `version`        | `v1.3.2`        | 明示的に定義し、インクルードされた設定の`spec:inputs:regex`の正規表現と一致する必要があります。 |
| `export_results` | `false`         | インクルードされた設定で`boolean`に指定された`spec:inputs:type`と一致させるため、`true`または`false`のいずれかである必要があります。デフォルト値を上書きします。 |

#### 複数の`include`エントリを使用する場合 {#with-multiple-include-entries}

インクルードされたエントリごとに、を個別に指定する必要があります。例: 

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

入力は、型チェック、検証、明確なコントラクトなど、変数よりも利点があります。予期しない入力は拒否されます。パイプラインの入力は、main `.gitlab-ci.yml`ファイルの[`spec:inputs`ヘッダー](#define-input-parameters-with-specinputs)で定義する必要があります。パイプラインレベルの設定のために、インクルードされたファイルで定義された入力を使用することはできません。

{{< alert type="note" >}}

[GitLab 17.7](../../update/deprecations.md#increased-default-security-for-use-of-pipeline-variables)以降では、パイプライン変数を渡すのではなく[パイプライン入力](../variables/_index.md#use-pipeline-variables)を使用することが推奨されます。セキュリティの強化のため、入力を使用する場合は[パイプライン変数を無効](../variables/_index.md#restrict-pipeline-variables)にする必要があります。

{{< /alert >}}

パイプラインの入力を定義するときは、常にデフォルト値を設定する必要があります。そうしないと、新しいパイプラインが自動的にトリガーされた場合、パイプラインが起動に失敗する可能性があります。たとえば、マージリクエストパイプラインは、マージリクエストのソースブランチへの変更に対してトリガーできます。マージリクエストパイプラインの入力を手動で設定することはできません。そのため、デフォルトがない入力があると、パイプラインの作成に失敗します。これは、ブランチパイプライン、タグ付けパイプライン、およびその他の自動的にトリガーされるパイプラインでも発生する可能性があります。

次の入力値を設定できます:

- [ダウンストリームパイプライン](../pipelines/downstream_pipelines.md#pass-inputs-to-a-downstream-pipeline)
- [手動でトリガーされるパイプライン](../pipelines/_index.md#run-a-pipeline-manually)。
- [パイプライントリガーAPI](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token)。
- [パイプラインAPI](../../api/pipelines.md#create-a-new-pipeline)
- [プッシュオプション](../../topics/git/commit.md#push-options-for-gitlab-cicd)を使用する。
- [パイプラインスケジュール](../pipelines/schedules.md#create-a-pipeline-schedule)
- [`trigger`キーワード](../pipelines/downstream_pipelines.md#pass-inputs-to-a-downstream-pipeline)

1つのパイプラインは最大20個の入力を受け取ることができます。

この[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/533802)に関するフィードバックをお寄せください。

ダウンストリームパイプラインの設定ファイルが[`spec:inputs`](#define-input-parameters-with-specinputs)を使用している場合、[ダウンストリームパイプライン](../pipelines/downstream_pipelines.md)にインプットを渡すことができます。

たとえば、[`trigger:inputs`](../yaml/_index.md#triggerinputs)を使用します:

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

## 入力値を操作する関数を指定する {#specify-functions-to-manipulate-input-values}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/409462)されました。

{{< /history >}}

事前定義された関数を補間ブロックで指定して、インプット値を操作できます。サポートされる形式は次のとおりです:

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

この例では、インプットがデフォルト値を使用し、`$MY_VAR`は値`my value`を持つマスクされていないプロジェクト変数であると仮定します:

1. まず、関数[`expand_vars`](#expand_vars)は値を`test my value`に展開します。
1. 次に[`truncate`](#truncate)は、`test my value`に文字オフセット`5`と長さ`8`を適用します。
1. `script`の出力は`echo my value`になります。

### 事前定義済みの補間関数 {#predefined-interpolation-functions}

#### `expand_vars` {#expand_vars}

{{< history >}}

- GitLab 16.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/387632)されました。

{{< /history >}}

インプット値の[CI/CD変数](../variables/_index.md)を展開するには、`expand_vars`を使用します。

変数のみを[`include`キーワード](../yaml/includes.md#use-variables-with-include)とともに使用できます。また、[マスクされて](../variables/_index.md#mask-a-cicd-variable)**not**（いない）変数を展開できます。[ネストされた変数の展開](../variables/where_variables_can_be_used.md#nested-variable-expansion)はサポートされていません。

次に例を示します:

```yaml
spec:
  inputs:
    test:
      default: 'test $MY_VAR'
---

test-job:
  script: echo $[[ inputs.test | expand_vars ]]
```

この例では、`$MY_VAR`が`my value`の値でマスク解除されている（ジョブログに公開されている）場合、インプットは`test my value`に展開されます。

#### `truncate` {#truncate}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/409462)されました。

{{< /history >}}

補間された値を短縮するには、`truncate`を使用します。例: 

- `truncate(<offset>,<length>)`

| 名前 | 型 | 説明 |
| ---- | ---- | ----------- |
| `offset` | 整数 | オフセットする文字数。 |
| `length` | 整数 | オフセット後に返す文字数。 |

次に例を示します:

```yaml
$[[ inputs.test | truncate(3,5) ]]
```

`inputs.test`の値が`0123456789`であると仮定すると、出力は`34567`になります。

## トラブルシューティング {#troubleshooting}

### `inputs`使用時のYAML構文エラー {#yaml-syntax-errors-when-using-inputs}

`rules:if`の[CI/CD変数式](../jobs/job_rules.md#cicd-variable-expressions)は、CI/CD変数と文字列の比較を想定しています。これに該当しない場合、[さまざまな構文エラーが返される可能性があります](../jobs/job_troubleshooting.md#this-gitlab-ci-configuration-is-invalid-for-variable-expressions)。

インプット値を設定に挿入した後も、式が適切な形式を維持していることを確認する必要があります。そのためには、追加の引用符文字が要求される場合があります。

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

この例では、次のようになります:

- `include: inputs: branch: $CI_DEFAULT_BRANCH`の使用は有効です。`if:`句は`if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH`に評価されます。これは有効な変数式です。
- `include: inputs: branch: main`の使用は**無効**です。`if:`句は`if: $CI_COMMIT_REF_NAME == main`に評価されます。これは、`main`が文字列であるにもかかわらず引用符で囲まれていないため無効になります。

代替策として、引用符を追加すると一部の変数式の問題を解決できます。例: 

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

この例では、インプットブロックと変数式全体を引用符で囲むことで、インプットの評価後に`if:`構文が確実に有効化されます。式内の内側の引用符と外側の引用符を同じ文字にすることはできません。引用符は、内側と外側にそれぞれ`"`と`'`を使用します（その逆も可）。一方、ジョブ名には引用符は必要ありません。
