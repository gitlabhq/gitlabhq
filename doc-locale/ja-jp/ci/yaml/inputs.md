---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 「include」により追加される設定のインプットを定義する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.11でベータ機能として[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/391331)。
- GitLab 17.0で[一般提供](https://gitlab.com/gitlab-com/www-gitlab-com/-/merge_requests/134062)になりました。

{{< /history >}}

インプットを利用すると、再利用を目的としたCI/CD設定ファイルの柔軟性を高めることができます。

インプットではCI/CD変数を使用できますが、[`include`キーワードと同じ変数の制限](includes.md#use-variables-with-include)があります。

## `spec:inputs`でインプットパラメーターを定義する

`spec:inputs`を使用して、パイプラインへの追加時に再利用可能なCI/CD設定ファイルに入力できるパラメーターを定義します。次に、[`include:inputs`](#set-input-values-when-using-include)を使用して設定をプロジェクトのパイプラインに追加し、パラメーターの値を設定します。

たとえば、`custom_website_scan.yml`という名前のファイルでは、次のようになります。

```yaml
spec:
  inputs:
    job-stage:
    environment:
---

scan-website:
  stage: $[[ inputs.job-stage ]]
  script: ./scan-website $[[ inputs.environment ]]
```

この例では、インプットは`job-stage`と`environment`です。次に、`.gitlab-ci.yml`ファイルでこの設定を追加し、インプット値を設定できます。

```yaml
include:
  - local: 'custom_website_scan.yml'
    inputs:
      job-stage: 'my-test-stage'
      environment: 'my-environment'
```

仕様は設定ファイルの先頭に宣言する必要があります。これは`---`で設定の残りの部分から区切られたヘッダーセクションに記述します。ヘッダーセクションの外で`$[[ inputs.input-id ]]`補間形式を使用して、インプットを使用する場所を宣言します。

`spec:inputs`を使用する場合:

- インプットはデフォルトで必須です。
- インプットは、設定が`.gitlab-ci.yml`ファイルの内容とマージされる前に、パイプライン作成中の設定のフェッチ時に評価および入力されます。
- インプットを含む文字列は1MB未満である必要があります。
- インプット内の文字列は1KB未満である必要があります。

さらに、以下を使用します。

- 指定されていない場合にインプットのデフォルト値を定義するには、[`spec:inputs:default`](_index.md#specinputsdefault)を使用します。デフォルトを指定すると、インプットが必須ではなくなります。
- 特定のインプットに説明を付けるには、[`spec:inputs:description`](_index.md#specinputsdescription)を使用します。説明はインプットには影響しませんが、インプットの詳細や予想される値を理解するのに役立ちます。
- インプットに対して許可される値をリストで指定するには、[`spec:inputs:options`](_index.md#specinputsoptions)を使用します。
- インプットが一致する必要がある正規表現を指定するには、[`spec:inputs:regex`](_index.md#specinputsregex)を使用します。
- 特定のインプットのタイプを規定するには、[`spec:inputs:type`](_index.md#specinputstype)を使用します。タイプは`string`（指定されていない場合のデフォルト）、`array`、`number`、または`boolean`に指定することができます。

### 複数のパラメーターでインプットを定義する

CI/CD設定ファイルごとに複数のインプットを定義できます。また、各インプットは複数の設定パラメーターを持つことができます。

たとえば、`scan-website-job.yml`という名前のファイルでは、次のようになります。

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

この例では、次のようになります。

- `job-prefix`は必須の文字列インプットであり、定義が必要です。
- `job-stage`はオプションです。定義されていない場合、値は`test`になります。
- `environment`は必須の文字列インプットであり、定義されたオプションのいずれかに一致する必要があります。
- `concurrency`はオプションの数値インプットです。指定しない場合、デフォルトは`1`になります。
- `version`は必須の文字列インプットであり、指定された正規表現に一致する必要があります。
- `export_results`はオプションのブール値インプットです。指定しない場合、デフォルトは`true`になります。

### インプットタイプ

オプションの`spec:inputs:type`キーワードを使用して、インプットが特定のタイプを使用する必要があることを指定できます。

インプットタイプは次のとおりです。

- [`array`](#array-type)
- `boolean`
- `number`
- `string`（指定されていない場合のデフォルト）

インプットがCI/CD設定内のYAML値全体を置き換える場合、指定されたタイプとして設定を補間します。次に例を示します。

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

インプットがより大きな文字列の一部としてYAML値に挿入される場合、インプットは常に文字列として補間されます。次に例を示します。

```yaml
spec:
  inputs:
    port:
      type: number
---

test_job:
  script: curl "https://gitlab.com:$[[ inputs.port ]]"
```

#### 配列タイプ

{{< history >}}

- GitLab 16.11で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/407176)。

{{< /history >}}

配列タイプのアイテムの内容は、有効なYAMLマップ、シーケンス、またはスカラーにすることができます。より複雑なYAML機能（[`!reference`](yaml_optimization.md#reference-tags)など）は使用できません。

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

#### 複数行のインプット文字列の値

[インプット](inputs.md)は、さまざまな値の型をサポートします。次の形式を使用して、複数文字列の値を渡すことができます。

```yaml
spec:
  inputs:
    closed_message:
      description: Message to announce when an issue is closed.
      default: 'Hi {{author}} :wave:,

        Based on the policy for inactive issues, this is now being closed.

        If this issue requires further attention, please reopen this issue.'
---
```

## `include`の使用時にインプット値を設定する

{{< history >}}

- `include:with`は、GitLab 16.0で名称が変更され、[`include:inputs`](https://gitlab.com/gitlab-org/gitlab/-/issues/406780)になりました。

{{< /history >}}

インクルードされた設定がパイプラインに追加されるときのパラメーターの値を設定するには、[`include:inputs`](_index.md#includeinputs)を使用します。

たとえば、[上記の例](#define-inputs-with-multiple-parameters)に`scan-website-job.yml`をインクルードするには、次のようにします。

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

この例では、インクルードされた設定のインプットは次のようになります。

| インプット            | 値           | 詳細 |
|------------------|-----------------|---------|
| `job-prefix`     | `some-service-` | 明示的に定義する必要があります。 |
| `job-stage`      | `test`          | `include:inputs`では定義されないため、値はインクルードされた設定の`spec:inputs:default`から取得します。 |
| `environment`    | `staging`       | 明示的に定義し、インクルードされた設定の`spec:inputs:options`の値の1つと一致する必要があります。 |
| `concurrency`    | `2`             | インクルードされた設定で`number`に指定された`spec:inputs:type`に一致させるため、数値である必要があります。デフォルト値を上書きします。 |
| `version`        | `v1.3.2`        | 明示的に定義し、インクルードされた設定の`spec:inputs:regex`の正規表現と一致する必要があります。 |
| `export_results` | `false`         | インクルードされた設定で`boolean`に指定された`spec:inputs:type`と一致させるため、`true`または`false`のいずれかである必要があります。デフォルト値を上書きします。 |

### 複数のファイルで`include:inputs`を使用する

インクルードされたファイルごとに、[`inputs`](_index.md#includeinputs)を個別に指定する必要があります。次に例を示します。

```yaml
include:
  - component: $CI_SERVER_FQDN/the-namespace/the-project/the-component@1.0
    inputs:
      stage: my-stage
  - local: path/to/file.yml
    inputs:
      stage: my-stage
```

### ダウンストリームパイプラインで`inputs`を使用する

ダウンストリームパイプラインの設定ファイルが[`spec:inputs`](#define-input-parameters-with-specinputs)を使用している場合、[ダウンストリームパイプライン](../pipelines/downstream_pipelines.md)にインプットを渡すことができます。次に例を示します。

{{< tabs >}}

{{< tab title="親子パイプライン" >}}

```yaml
trigger-job:
  trigger:
    strategy: depend
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
    strategy: depend
    include:
      - project: project-group/my-downstream-project
        file: ".gitlab-ci.yml"
        inputs:
          job-name: "defined"
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
```

{{< /tab >}}

{{< /tabs >}}

### 同じファイルを複数回インクルードする

異なるインプットを使用して、同じファイルを複数回インクルードできます。ただし、1つのパイプラインに同じ名前のジョブが複数追加された場合、追加された各ジョブが同じ名前の前のジョブを上書きしてしまうため、設定でジョブ名の重複を防止する必要があります。

たとえば、異なるインプットで同じ設定を複数回インクルードする場合は、次のようになります。

```yaml
include:
  - local: path/to/my-super-linter.yml
    inputs:
      linter: docs
      lint-path: "doc/"
  - local: path/to/my-super-linter.yml
    inputs:
      linter: yaml
      lint-path: "data/yaml/"
```

`path/to/my-super-linter.yml`の設定により、ジョブがインクルードされるたびに一意の名前を付けるようにすることができます。

```yaml
spec:
  inputs:
    linter:
    lint-path:
---
"run-$[[ inputs.linter ]]-lint":
  script: ./lint --$[[ inputs.linter ]] --path=$[[ inputs.lint-path ]]
```

### `inputs`で設定を再利用する

`inputs`で設定を再利用する場合、[YAMLアンカー](yaml_optimization.md#anchors)を使用できます。

たとえば、インプットで`rules`配列をサポートする複数のコンポーネントで同じ`rules`設定を再利用するには、次のようにします。

```yaml
.my-job-rules: &my-job-rules
  - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

include:
  - component: $CI_SERVER_FQDN/project/path/component1@main
    inputs:
      job-rules: *my-job-rules
  - component: $CI_SERVER_FQDN/project/path/component2@main
    inputs:
      job-rules: *my-job-rules
```

インプットでは[`!reference`タグ](yaml_optimization.md#reference-tags)を使用できませんが、[イシュー424481](https://gitlab.com/gitlab-org/gitlab/-/issues/424481)でこの機能の追加が提案されています。

## `inputs`の例

### `inputs`と`needs`を同時に使用する

複雑なジョブの依存関係に対し、[`needs`](_index.md#needs)を配列タイプのインプットと共に使用できます。

たとえば、`component.yml`という名前のファイルでは、次のようになります。

```yaml
spec:
  inputs:
    first_needs:
      type: array
    second_needs:
      type: array
---

test_job:
  script: echo "this job has needs"
  needs:
    - $[[ inputs.first_needs ]]
    - $[[ inputs.second_needs ]]
```

この例では、インプットは`first_needs`と`second_needs`で、いずれも[配列タイプのインプット](#array-type)です。次に、`.gitlab-ci.yml`ファイルでこの設定を追加し、インプット値を設定できます。

```yaml
include:
  - local: 'component.yml'
    inputs:
      first_needs:
        - build1
      second_needs:
        - build2
```

パイプラインが開始されると、`test_job`の`needs`配列内の項目が連結されて、次のようになります。

```yaml
test_job:
  script: echo "this job has needs"
  needs:
  - build1
  - build2
```

### インクルード時に`needs`の展開を許可する

インクルードされたジョブに[`needs`](_index.md#needs)を含めるだけではなく、`spec:inputs`を使用して`needs`配列にジョブを追加することもできます。

次に例を示します。

```yaml
spec:
  inputs:
    test_job_needs:
      type: array
      default: []
---

build-job:
  script:
    - echo "My build job"

test-job:
  script:
    - echo "My test job"
  needs:
    - build-job
    - $[[ inputs.test_job_needs ]]
```

この例では、次のようになります。

- `test-job`ジョブには常に`build-job`が必要です。
- `test_job_needs:`配列インプットはデフォルトでは空であるため、デフォルトのテストジョブは他のジョブを必要としません。

設定で`test-job`が別のジョブを必要とするように設定するには、ファイルのインクルード時に`test_needs`インプットに追加します。次に例を示します。

```yaml
include:
  - component: $CI_SERVER_FQDN/project/path/component@1.0.0
    inputs:
      test_job_needs: [my-other-job]

my-other-job:
  script:
    - echo "I want build-job` in the component to need this job too"
```

### `needs`を持たないインクルードされたジョブに`needs`を追加する

インクルードされたジョブに定義済みの`needs`がない場合、[`needs`](_index.md#needs)を追加できます。たとえば、CI/CDコンポーネントの設定では、次のようになります。

```yaml
spec:
  inputs:
    test_job:
      default: test-job
---

build-job:
  script:
    - echo "My build job"

"$[[ inputs.test_job ]]":
  script:
    - echo "My test job"
```

この例では、`spec:inputs`セクションでジョブ名をカスタマイズできます。

次に、コンポーネントをインクルードした後、追加の`needs`設定でジョブを拡張できます。次に例を示します。

```yaml
include:
  - component: $CI_SERVER_FQDN/project/path/component@1.0.0
    inputs:
      test_job: my-test-job

my-test-job:
  needs: [my-other-job]

my-other-job:
  script:
    - echo "I want `my-test-job` to need this job"
```

## インプット値を操作する関数を指定する

{{< history >}}

- GitLab 16.3で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/409462)。

{{< /history >}}

事前定義された関数を補間ブロックで指定して、インプット値を操作できます。サポートされる形式は次のとおりです。

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

この例では、インプットがデフォルト値を使用し、`$MY_VAR`は値`my value`を持つマスクされていないプロジェクト変数であると仮定します。

1. まず、関数[`expand_vars`](#expand_vars)は値を`test my value`に展開します。
1. 次に[`truncate`](#truncate)は、`test my value`に文字オフセット`5`と長さ`8`を適用します。
1. `script`の出力は`echo my value`になります。

### 事前定義済みの補間関数

#### `expand_vars`

{{< history >}}

- GitLab 16.5で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/387632)。

{{< /history >}}

インプット値の[CI/CD変数](../variables/_index.md)を展開するには、`expand_vars`を使用します。

変数のみを[`include`キーワード](includes.md#use-variables-with-include)とともに使用できます。また、[マスクされて](../variables/_index.md#mask-a-cicd-variable)**いない**変数を展開できます。[ネストされた変数の展開](../variables/where_variables_can_be_used.md#nested-variable-expansion)はサポートされていません。

次に例を示します。

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

#### `truncate`

{{< history >}}

- GitLab 16.3で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/409462)。

{{< /history >}}

補間された値を短縮するには、`truncate`を使用します。次に例を示します。

- `truncate(<offset>,<length>)`

| 名前 | 種類 | 説明 |
| ---- | ---- | ----------- |
| `offset` | 整数 | オフセットする文字数。 |
| `length` | 整数 | オフセット後に返す文字数。 |

次に例を示します。

```yaml
$[[ inputs.test | truncate(3,5) ]]
```

`inputs.test`の値が`0123456789`であると仮定すると、出力は`34567`になります。

## トラブルシューティング

### `inputs`使用時のYAML構文エラー

`rules:if`の[CI/CD変数式](../jobs/job_rules.md#cicd-variable-expressions)は、CI/CD変数と文字列の比較を想定しています。これに該当しない場合、[さまざまな構文エラーが返される可能性があります](../jobs/job_troubleshooting.md#this-gitlab-ci-configuration-is-invalid-for-variable-expressions)。

インプット値を設定に挿入した後も、式が適切な形式を維持していることを確認する必要があります。そのためには、追加の引用符文字が要求される場合があります。

次に例を示します。

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

この例では、次のようになります。

- `include: inputs: branch: $CI_DEFAULT_BRANCH`の使用は有効です。`if:`句は`if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH`に評価されます。これは有効な変数式です。
- `include: inputs: branch: main`の使用は**無効**です。`if:`句は`if: $CI_COMMIT_REF_NAME == main`に評価されます。これは、`main`が文字列であるにもかかわらず引用符で囲まれていないため無効になります。

代替策として、引用符を追加すると一部の変数式の問題を解決できます。次に例を示します。

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
