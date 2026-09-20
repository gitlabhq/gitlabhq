---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Moa式言語
---

Moaは、ジョブ実行中に動的に値を構築するための式言語です。式は`${{ }}`区切り文字で囲まれ、GitLab Functionおよびジョブインプットで使用されます。

Moaは、文字列操作、算術演算、比較、論理演算、プロパティへのアクセス、Function呼び出しをサポートします。

## CI/CD式との違い {#differences-from-cicd-expressions}

GitLabには、パイプラインのライフサイクルのさまざまなステージで異なる目的を果たす3つの式構文があります。

- [ルール](../yaml/_index.md#rules)は、ジョブの包含を制御するために`rules:`キーワード内で独自の式構文を使用します。これらはパイプライン作成中に評価され、CI/CD変数に対する比較とパターンマッチングをサポートしますが、算術演算を実行したり、ランタイム状態にアクセスしたりすることはできません。
- CI/CD式は`$[[ ]]`構文を使用し、ジョブが実行される前のパイプライン作成中に評価されます。これらの式は、[CI/CDインプット](../inputs/_index.md)、[マトリックス値](../yaml/matrix_expressions.md)、および[コンポーネントインプット](../components/_index.md)の置換を実行します。これらは算術演算、比較、またはロジックを実行できず、ランタイム状態にアクセスできません。詳細については、[CI/CD式](../yaml/expressions.md)を参照してください。
- Moaは`${{ }}`構文を使用し、Runnerによってジョブ実行中に評価されます。Moaは、演算子、データ構造、Function呼び出しを備えた完全な式言語です。

これら3つの構文はすべて同じパイプラインで共存できます。GitLab Functionを含むCI/CDコンポーネントは、これら3つすべてを使用する場合があります:

```yaml
spec:
  inputs:
    echo_version:
      type: string
---

hi-job:
  # rules expression - evaluated when the pipeline is created
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
  run:
    - name: say_hi
      # $[[ ]] - resolved when the pipeline is created
      step: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo@$[[ inputs.echo_version ]]
      inputs:
        # ${{ }} - resolved when the job runs
        message: "Hello, ${{ vars.CI_PROJECT_NAME }}"
```

Moaは、GitLab Functionがパイプライン作成時には利用できないFunctionを必要とするため、独立した言語として存在します:

- ランタイム評価: Functionの実行が完了するまで、ステップアウトプットは存在しません。`${{ steps.build.outputs.image_ref }}`のような式は、実行中にのみ評価できます。
- 型付き値: Moaはネイティブ型（数値、ブール値、配列、オブジェクト）を維持し、文字列に変換することなくFunction間で受け渡します。
- 演算子とロジック: GitLab Functionは、変数およびアウトプットからステップインプットを作成するために、算術演算（`major_version + 1`）、比較（`vulnerabilities == 0`）、およびショートサーキットロジック（`inputs.tag || "latest"`）を必要とします。
- 機密性の高い値の追跡: Moaは、演算を通じて機密性の高い値が引き継がれます。機密性の高い値を文字列に連結したり、Function呼び出しを介して渡したりした場合、その結果も機密性の高い値として扱われます。これにより、ログやアウトプットにシークレットが誤って開示されるのを防ぎます。

## コンテキスト参照 {#context-reference}

式で利用できる値は、式が使用される場所によって異なります。

| コンテキスト       | 利用可能                                                                                             | タイプ   | 評価済み                        | 説明                                                                                                                             |
|---------------|----------------------------------------------------------------------------------------------------------|--------|----------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `job.inputs`  | ジョブ設定: `script`、`before_script`、`after_script`、`artifacts`、`cache`、`image`、`services`  | オブジェクト | Runnerがジョブを受け取ったとき | ジョブ用に定義されたインプット値。`job.inputs.<name>`を使用して個々の変数にアクセスします。                                                 |
| `env`         | GitLab Function                                                                                         | オブジェクト | Functionが実行される前         | Functionで利用可能な環境変数。`env.<name>`を使用して個々の変数にアクセスします。                                         |
| `inputs`      | GitLab Function                                                                                         | オブジェクト | Functionが実行される前         | Functionに渡されるインプット値。`inputs.<name>`を使用して個々のインプットにアクセスします。                                                     |
| `vars`        | GitLab Function                                                                                         | オブジェクト | Functionが実行される前         | CIジョブから渡されるジョブ変数。`vars.<name>`を使用して個々の変数にアクセスします。                                                   |
| `steps`       | GitLab Function                                                                                         | オブジェクト | Functionが実行される前         | 現在のFunctionで以前に実行されたステップの結果。`steps.<step_name>.outputs.<output_name>`を使用してステップのアウトプットにアクセスします。 |
| `export_file` | GitLab Function                                                                                         | 文字列 | Functionが実行される前         | Functionが、後続のステップにエクスポートする環境変数を書き込むことができるファイルへのパス。                                      |
| `output_file` | GitLab Function                                                                                         | 文字列 | Functionが実行される前         | Functionがアウトプット値を書き込むファイルへのパス。                                                                           |
| `func_dir`    | GitLab Function                                                                                         | 文字列 | Functionが実行される前         | Functionの定義ファイルを含むディレクトリへのパス。Functionにバンドルされたファイルを参照するために使用します。                      |
| `work_dir`    | GitLab Function                                                                                         | 文字列 | Functionが実行される前         | 現在の実行の作業ディレクトリへのパス。                                                                                |

## テンプレート構文 {#template-syntax}

### 補間 {#interpolation}

式を評価するには、`${{ }}`で囲みます:

```yaml
script:
  - echo "Hello, ${{ job.inputs.name }}"
```

式がテキストで囲まれている場合、結果は常に文字列に変換されます。複数の式が単一の値に表示されることがあります:

```yaml
script:
  - echo "${{ job.inputs.greeting }}, ${{ job.inputs.name }}!"
```

### ネイティブ型のパススルー {#native-type-passthrough}

`${{ expression }}`が周囲にテキストがない完全な値である場合、式はネイティブ型を返します。ネイティブ型式を使用して、数値、ブール値、配列、オブジェクトなどの非文字列値を、文字列に変換することなくステップ間で渡します。

```yaml
inputs:
  count: ${{ steps.previous.outputs.total }}
```

この例では、`total`が数値である場合、`count`は文字列表現ではなく数値を受け取ります。

### Moa式のエスケープ {#escape-moa-expressions}

補間をトリガーすることなく、リテラル`${{`をテキストに含めるには、バックスラッシュでエスケープします:

```yaml
script:
  - echo "Use \${{ to start an expression"
```

このコマンドは、評価なしでテキスト`Use ${{ to start an expression`をアウトプットします。

## リテラル {#literals}

### Null {#null}

キーワード`null`は値の不在を表します。

```yaml
${{ null }}
```

### ブール値 {#booleans}

キーワード`true`および`false`はブール値を表します。

```yaml
${{ true }}
${{ false }}
```

### 数値 {#numbers}

数値は、53ビットの精度を持つIEEE 754倍精度浮動小数点値です。2^53（約9京）より大きい整数は正確に表現できません。整数、小数、および科学的表記がサポートされています。

```yaml
${{ 42 }}
${{ 3.14 }}
${{ 1.5e3 }}
${{ 2E-4 }}
```

### 文字列 {#strings}

文字列を二重引用符または単一引用符で囲みます。2つの引用符タイプは、エスケープシーケンスとテンプレート式を異なる方法で処理します。

二重引用符で囲まれた文字列は、テンプレート式とすべてのエスケープシーケンスをサポートします:

| シーケンス  | 意味                                 |
|-----------|-----------------------------------------|
| `\\`      | バックスラッシュ                               |
| `\"`      | 二重引用符                            |
| `\n`      | 改行                                 |
| `\r`      | キャリッジリターン                         |
| `\t`      | タブ                                     |
| `\a`      | アラート（ベル）                            |
| `\b`      | バックスペース                               |
| `\f`      | フォームフィード                               |
| `\v`      | 垂直タブ                            |
| `\/`      | スラッシュ                           |
| `\uXXXX`  | Unicodeコードポイント                      |
| `\${{`    | リテラル`${{` （補間を防止）  |

二重引用符で囲まれた文字列内のテンプレート式（`${{ }}`）は、評価されて文字列に補間されます。

単一引用符で囲まれた文字列は、最小限の解釈を伴うraw文字列リテラルです。単一引用符で囲まれた文字列内のテンプレート式は評価されません。サポートされているエスケープシーケンスは2つだけです:

| シーケンス | 意味      |
|----------|--------------|
| `\\`     | バックスラッシュ    |
| `\'`     | 単一引用符 |

```yaml
${{ "Hello\nWorld" }}
${{ 'It\'s a string' }}
${{ 'Literal ${{ not evaluated }}' }}
```

## 識別子 {#identifiers}

識別子は、式コンテキストから値を参照します。識別子は文字またはアンダースコアで始まり、文字、数字、アンダースコアを含むことができます。識別子は大文字と小文字を区別します: `foo`、`Foo`、および`FOO`は3つの異なる識別子です。

```yaml
${{ env }}
${{ my_variable }}
```

識別子は、利用可能なコンテキストに対して解決されます。各コンテキストで利用可能な値については、[コンテキスト参照](#context-reference)を参照してください。

識別子がコンテキストオブジェクトを参照する場合、オブジェクト全体が返されます。たとえば、`${{ vars }}`はすべてのジョブ変数をオブジェクトとして返します。

## 演算子 {#operators}

### 算術演算子 {#arithmetic-operators}

算術演算子は数値に対して機能します。`+`演算子は文字列も連結します。演算子は暗黙的な型変換を実行しないため、`"hello" + 42`はエラーになります。

| Operator | 説明                 | 例             | 結果     |
|----------|-----------------------------|---------------------|------------|
| `+`      | 加算                    | `${{ 2 + 3 }}`      | `5`        |
| `+`      | 連結               | `${{ "a" + "b" }}`  | `"ab"`     |
| `-`      | 減算                 | `${{ 10 - 4 }}`     | `6`        |
| `*`      | 乗算              | `${{ 3 * 4 }}`      | `12`       |
| `/`      | 除算                    | `${{ 10 / 3 }}`     | `3.333...` |
| `%`      | 剰余（切り捨て除算） | `${{ 10 % 3 }}`     | `1`        |

ゼロによる除算はエラーになります。

### 比較演算子 {#comparison-operators}

比較演算子はブール値を返します。

| Operator | 説明           | 例            | 結果  |
|----------|-----------------------|--------------------|---------|
| `==`     | 等しい                 | `${{ 1 == 1 }}`    | `true`  |
| `!=`     | 等しくない             | `${{ 1 != 2 }}`    | `true`  |
| `<`      | より小さい             | `${{ 1 < 2 }}`     | `true`  |
| `<=`     | 以下    | `${{ 2 <= 2 }}`    | `true`  |
| `>`      | より大きい          | `${{ 3 > 2 }}`     | `true`  |
| `>=`     | 以上 | `${{ 3 >= 3 }}`    | `true`  |

異なる型の値は型によって比較されるため、`1 == "1"`は`false`と評価されます。同じ型の値は、次の比較ルールに従います:

- 数値: 数値比較。
- 文字列: 辞書式比較（UTF-8バイト順）。
- ブール値: `false`は`true`より小さいです。
- 配列: 要素ごとの比較。
- オブジェクト: 長さ、次にキー、次に値によって比較されます。キーの順序は関係ありません。
- Null: `null`は`null`に等しいです。

### 論理演算子 {#logical-operators}

論理演算子はショートサーキット評価を使用し、必ずしもブール値ではなく、オペランドの1つを返します。この動作はJavaScriptの`&&`および`||`演算子に似ています。

| Operator   | 説明 | 動作                                                                                      |
|------------|-------------|-----------------------------------------------------------------------------------------------|
| `\|\|`     | 論理OR  | 左オペランドが真の場合、それを返し、そうでない場合は右オペランドを評価して返します。  |
| `&&`       | 論理AND | 左オペランドが偽の場合、それを返し、そうでない場合は右オペランドを評価して返します。   |
| `!`        | 論理NOT | オペランドが偽の場合は`true`を返し、真の場合は`false`を返します。                                    |

`||`演算子はデフォルト値を提供するために使用されます:

```yaml
${{ inputs.name || "default" }}
```

`inputs.name`が空でない文字列の場合、そのまま返されます。空またはNullの場合、`"default"`が返されます。

### 単項演算子 {#unary-operators}

| Operator | 説明    | 例          | 結果  |
|----------|----------------|------------------|---------|
| `+`      | 単項プラス     | `${{ +5 }}`      | `5`     |
| `-`      | 単項否定 | `${{ -5 }}`      | `-5`    |
| `!`      | 論理NOT    | `${{ !true }}`   | `false` |

### 演算子の優先順位 {#operator-precedence}

演算子は優先順位の高い順にリストされています。同じ行の演算子は同じ優先順位を持ちます。すべての二項演算子は左結合です。

| 優先順位  | 演算子                        |
|-------------|----------------------------------|
| 7（最高） | `.`、`[]`、`()`                  |
| 6           | `+`、`-`、`!`                    |
| 5           | `*`、`/`、`%`                    |
| 4           | `+`、`-`                         |
| 3           | `==`、`!=`、`<`、`<=`、`>`、`>=` |
| 2           | `&&`                             |
| 1（最低）  | `\|\|`                           |

優先順位をオーバーライドするには括弧を使用します:

```yaml
${{ (1 + 2) * 3 }}
```

## データ構造 {#data-structures}

### 配列 {#arrays}

角括弧表記で配列を作成します。要素は任意の型にすることができ、型を混在させることができます。末尾のカンマを使用できます。

```yaml
${{ [1, 2, 3] }}
${{ ["a", 1, true, null] }}
${{ [] }}
```

### オブジェクト {#objects}

波括弧表記でオブジェクトを作成します。キーは文字列として評価される必要があります。値は任意の型にすることができます。末尾のカンマは許可されています。

```yaml
${{ {name: "runner", version: 1} }}
${{ {"string-key": true} }}
${{ {} }}
```

オブジェクトキーとして使用されるベア識別子は、変数参照ではなく文字列リテラルとして扱われます。変数をキーとして使用するには、括弧で囲みます:

```yaml
${{ {name: "Alice"} }}           # "name" is the string "name", not a variable reference
${{ {(obj.prop): "value"} }}     # key is the value of obj.prop, which must be a string
```

## プロパティアクセス {#property-access}

### ドット表記 {#dot-notation}

ドット表記でオブジェクトプロパティにアクセスします:

```yaml
${{ env.HOME }}
${{ steps.build.outputs.artifact_path }}
```

### 角括弧表記 {#bracket-notation}

インデックスによる配列要素、または文字列キーによるオブジェクトプロパティにアクセスします:

```yaml
${{ my_array[0] }}
${{ my_object["property-name"] }}
```

プロパティ名にハイフンなどの特殊文字が含まれる場合、角括弧表記が必要です。

### チェイン {#chaining}

プロパティアクセスとFunction呼び出しをチェインします:

```yaml
${{ steps.build.outputs.items[0] }}
```

## Function呼び出し {#function-calls}

括弧付きの名前でFunctionを呼び出します:

```yaml
${{ str(42) }}
${{ num("3.14") }}
```

## 真偽値 {#truthiness}

論理演算子と`!`演算子は、次の真偽値ルールを使用します:

| タイプ    | 真の場合             | 偽の場合        |
|---------|-------------------------|-------------------|
| ブール値 | `true`                  | `false`           |
| 文字列  | 長さが`0`より大きい | 空の文字列`""` |
| 数値  | `0`ではない                 | `0`               |
| 配列   | 長さが`0`より大きい | 空の配列`[]`  |
| オブジェクト  | 長さが`0`より大きい | 空のオブジェクト`{}` |
| Null    | なし                   | 常時            |

## ビルトインFunction {#built-in-functions}

### `str(value)` {#strvalue}

任意の値をその文字列表現に変換します。

```yaml
${{ str(42) }}       # "42"
${{ str(true) }}     # "true"
${{ str(null) }}     # "<null>"
```

### `num(value)` {#numvalue}

文字列を数値に変換します。文字列は有効な数値表現である必要があります。

```yaml
${{ num("42") }}     # 42
${{ num("3.14") }}   # 3.14
```

### `bool(value)` {#boolvalue}

任意の値をその[真偽値](#truthiness)に基づいてブール値に変換します。

```yaml
${{ bool("hello") }}  # true
${{ bool("") }}       # false
${{ bool(0) }}        # false
${{ bool(1) }}        # true
```

## 予約語 {#reserved-words}

以下の単語は予約されており、識別子として使用することはできません。これらは将来の言語機能のために予約されています。

`array`、`as`、`break`、`case`、`const`、`continue`、`default`、`else`、`fallthrough`、`float`、`for`、`func`、`function`、`goto`、`if`、`import`、`in`、`int`、`let`、`loop`、`map`、`namespace`、`number`、`object`、`package`、`range`、`return`、`string`、`struct`、`switch`、`type`、`var`、`void`、`while`

キーワード`null`、`true`、および`false`もリテラル値として予約されています。

## 例 {#examples}

### 戦略選択によるデプロイ {#deploy-with-strategy-selection}

```yaml
deploy job:
  when: manual
  inputs:
    environment:
      default: staging
      options: [staging, production]
      description: Target deployment environment
    strategy:
      default: rolling
      options: [rolling, blue-green, canary]
      description: Deployment strategy
    replicas:
      type: number
      default: 3
      description: Number of replicas to deploy
  image: ${{ job.inputs.environment == "production" && "deploy-tools:stable" || "deploy-tools:latest" }}
  script:
    - 'echo "Deploying to ${{ job.inputs.environment }} using ${{ job.inputs.strategy }}"'
    - deploy
        --env ${{ job.inputs.environment }}
        --strategy ${{ job.inputs.strategy }}
        --replicas ${{ str(job.inputs.replicas) }}
```

### ブール値ジョブインプットからの条件付きフラグ {#conditional-flags-from-boolean-job-inputs}

```yaml
test_job:
  inputs:
    coverage:
      type: boolean
      default: false
    verbose:
      type: boolean
      default: false
  script:
    - pytest ${{ job.inputs.verbose && "-v" || "" }} ${{ job.inputs.coverage && "--cov=src" || "" }}
```

### ジョブ変数からのイメージ参照の構築 {#building-an-image-reference-from-job-variables}

```yaml
build_job:
  run:
    - name: build
      func: ./docker-build
      inputs:
        image: ${{ vars.CI_REGISTRY + "/" + vars.CI_PROJECT_PATH + ":" + vars.CI_PIPELINE_IID }}
```

### 継続ゲート {#continue-gate}

```yaml
security_scan_job:
  run:
    - name: scan
      func: ./security-scan
    - name: gate
      func: ./quality-gate
      inputs:
        should_proceed: ${{ steps.scan.outputs.critical == 0 && steps.scan.outputs.high < 5 }}
```

### バージョン管理 {#version-management}

```yaml
increment_version_job:
  run:
    - name: current
      func: ./find-version
    - name: bump
      func: ./bump-version
      inputs:
        new_version: ${{ str(steps.current.outputs.major + 1) + ".0.0" }}
```

### 環境固有の設定 {#environment-specific-configuration}

```yaml
deploy_job:
  run:
    - name: deploy
      func: ./deploy
      inputs:
        registry: ${{ (vars.CI_COMMIT_REF_NAME == "main" && "prod.registry.com") || "staging.registry.com" }}
        replicas: ${{ (vars.CI_COMMIT_REF_NAME == "main" && 5) || 2 }}
```

### A/Bテストを設定する {#configure-ab-testing}

```yaml
configure_job:
  run:
    - name: configure_ab
      func: ./traffic-split
      inputs:
        variants: |
          ${{ [
            {name: "control", use_new_feature: false, weight: 90},
            {name: "experiment", use_new_feature: true, weight: 10}
          ] }}
```
