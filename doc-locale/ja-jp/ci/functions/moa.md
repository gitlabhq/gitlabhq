---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Moa式言語
---

Moaは、ジョブ実行中に動的に値を構築するための式言語です。式は`${{ }}`区切り文字で囲まれ、GitLab Functionsとジョブ入力で使用されます。

Moaは、文字列操作、算術、比較、論理演算、プロパティアクセス、および関数呼び出しをサポートしています。

## CI/CD式との違い {#differences-from-cicd-expressions}

GitLabには、パイプラインライフサイクルの異なるステージで異なる目的を果たす3つの式構文があります。

- [ルール](../yaml/_index.md#rules)は、`rules:`キーワード内で独自の式構文を使用して、ジョブのインクルージョンを制御します。これらはパイプライン作成中に評価され、CI/CD変数に対する比較とパターンマッチングをサポートしますが、算術演算を実行したり、ランタイム状態にアクセスしたりすることはできません。
- CI/CD式は`$[[ ]]`構文を使用し、いずれかのジョブが実行される前にパイプライン作成中に評価されます。これらの式は、[CI/CDインプット](../inputs/_index.md) 、[マトリックス値](../yaml/matrix_expressions.md) 、および[コンポーネント入力](../components/_index.md)の値置換を実行します。これらは、算術、比較、または論理を実行できず、ランタイム状態にアクセスできません。詳細については、[CI/CD式](../yaml/expressions.md)を参照してください。
- Moaは`${{ }}`構文を使用し、ジョブ実行中にRunnerによって評価されます。Moaは、演算子、データ構造、関数呼び出しを備えた完全な式言語です。

3つのすべての構文は、同じパイプライン内に共存できます。GitLab Functionsを含むCI/CDコンポーネントは、3つすべてを使用する場合があります:

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

GitLab Functionsがパイプライン作成時には利用できない機能を必要とするため、Moaは別の言語として存在します:

- ランタイム評価: ステップ出力は、関数が実行されるまで存在しません。`${{ steps.build.outputs.image_ref }}`のような式は、実行中にのみ評価できます。
- 型付き値: Moaはネイティブ型（数値、ブール値、配列、オブジェクト）を保持し、文字列に変換することなく関数間で渡します。
- 演算子と論理: GitLab Functionsは、変数と出力からステップ入力を構築するために、算術演算（`major_version + 1`）、比較（`vulnerabilities == 0`）、および短絡論理（`inputs.tag || "latest"`）を必要とします。
- 機密値の追跡: Moaは、操作を通じて機密値を伝播させます。機密値を文字列に連結したり、関数呼び出しを通じて渡したりすると、結果も機密として扱われます。これにより、ログおよび出力におけるシークレットの偶発的な開示を防ぎます。

## コンテキスト参照 {#context-reference}

式で使用できる値は、式がどこで使用されるかによって異なります。

| コンテキスト       | 利用可能                                                                                             | 型   | 評価済み                        | 説明                                                                                                                             |
|---------------|----------------------------------------------------------------------------------------------------------|--------|----------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `job.inputs`  | ジョブ設定: `script`、`before_script`、`after_script`、`artifacts`、`cache`、`image`、`services`  | オブジェクト | Runnerがジョブを受信したとき | ジョブに定義された入力値。`job.inputs.<name>`で個別の変数にアクセスします。                                                 |
| `env`         | GitLab Functions                                                                                         | オブジェクト | 関数実行前         | 関数で利用可能な環境変数。`env.<name>`で個別の変数にアクセスします。                                         |
| `inputs`      | GitLab Functions                                                                                         | オブジェクト | 関数実行前         | 関数に渡された入力値。`inputs.<name>`で個別の入力にアクセスします。                                                     |
| `vars`        | GitLab Functions                                                                                         | オブジェクト | 関数実行前         | CIジョブから渡されたジョブ変数。`vars.<name>`で個別の変数にアクセスします。                                                   |
| `steps`       | GitLab Functions                                                                                         | オブジェクト | 関数実行前         | 現在の関数で以前に実行されたステップの結果。`steps.<step_name>.outputs.<output_name>`でステップの出力にアクセスします。 |
| `export_file` | GitLab Functions                                                                                         | 文字列 | 関数実行前         | 関数が環境変数を後続のステップにエクスポートするために書き込めるファイルへのパス。                                      |
| `output_file` | GitLab Functions                                                                                         | 文字列 | 関数実行前         | 関数が出力値を書き込むファイルへのパス。                                                                           |
| `func_dir`    | GitLab Functions                                                                                         | 文字列 | 関数実行前         | 関数の定義ファイルを含むディレクトリへのパス。関数にバンドルされたファイルを参照するために使用します。                      |
| `work_dir`    | GitLab Functions                                                                                         | 文字列 | 関数実行前         | 現在の実行のための作業ディレクトリへのパス。                                                                                |

## テンプレート構文 {#template-syntax}

### 補間 {#interpolation}

式を評価するために`${{ }}`で囲みます:

```yaml
script:
  - echo "Hello, ${{ job.inputs.name }}"
```

テキストが式を囲む場合、結果は常に文字列に変換されます。複数の式が単一の値に表示されることがあります:

```yaml
script:
  - echo "${{ job.inputs.greeting }}, ${{ job.inputs.name }}!"
```

### ネイティブ型パススルー {#native-type-passthrough}

`${{ expression }}`が周囲にテキストのない完全な値である場合、式はネイティブ型を返します。数値、ブール値、配列、オブジェクトなどの非文字列値を、文字列に変換せずにステップ間で渡すには、ネイティブ型式を使用します。

```yaml
inputs:
  count: ${{ steps.previous.outputs.total }}
```

この例では、`total`が数値の場合、`count`は文字列表現ではなく数値を受け取ります。

### Moa式のエスケープ {#escape-moa-expressions}

補間をトリガーせずにテキストにリテラル`${{`を含めるには、バックスラッシュでエスケープします:

```yaml
script:
  - echo "Use \${{ to start an expression"
```

このコマンドは、評価なしでテキスト`Use ${{ to start an expression`を出力します。

## リテラル {#literals}

### ヌル {#null}

キーワード`null`は、値の不在を表します。

```yaml
${{ null }}
```

### ブール値 {#booleans}

キーワード`true`と`false`は、ブール値を表します。

```yaml
${{ true }}
${{ false }}
```

### 数値 {#numbers}

数値は、53ビットの仮数精度を持つIEEE 754倍精度浮動小数点値です。整数、小数、および科学的表記がサポートされています。

```yaml
${{ 42 }}
${{ 3.14 }}
${{ 1.5e3 }}
${{ 2E-4 }}
```

### 文字列 {#strings}

文字列はダブルクォートまたはシングルクォートで囲みます。2種類のクォートは、エスケープシーケンスとテンプレート式を異なる方法で処理します。

ダブルクォートされた文字列は、テンプレート式とすべてのエスケープシーケンスをサポートします:

| シーケンス  | 意味                                 |
|-----------|-----------------------------------------|
| `\\`      | バックスラッシュ                               |
| `\"`      | ダブルクォート                            |
| `\n`      | 改行                                 |
| `\r`      | 復帰                         |
| `\t`      | タブ                                     |
| `\a`      | アラート（ベル）                            |
| `\b`      | バックスペース                               |
| `\f`      | フォームフィード                               |
| `\v`      | 垂直タブ                            |
| `\/`      | スラッシュ                           |
| `\uXXXX`  | Unicodeコードポイント                      |
| `\${{`    | リテラル`${{`（補間を防止）  |

ダブルクォートされた文字列内のテンプレート式（`${{ }}`）は評価され、文字列に補間されます。

シングルクォートされた文字列は、最小限の解釈を伴うraw文字列リテラルです。シングルクォートされた文字列内のテンプレート式は評価されません。サポートされているエスケープシーケンスは2つだけです:

| シーケンス | 意味      |
|----------|--------------|
| `\\`     | バックスラッシュ    |
| `\'`     | シングルクォート |

```yaml
${{ "Hello\nWorld" }}
${{ 'It\'s a string' }}
${{ 'Literal ${{ not evaluated }}' }}
```

## 識別子 {#identifiers}

識別子は、式コンテキストから値を参照します。識別子は、文字またはアンダースコアで始まり、文字、数字、およびアンダースコアを含むことができます。識別子は、大文字と小文字を区別します。`foo`、`Foo`、および`FOO`は、3つの異なる識別子です。

```yaml
${{ env }}
${{ my_variable }}
```

識別子は、利用可能なコンテキストに対して解決されます。各コンテキストで利用可能な値については、[コンテキスト参照](#context-reference)を参照してください。

識別子がコンテキストオブジェクトを参照する場合、オブジェクト全体が返されます。たとえば、`${{ vars }}`はすべてのジョブ変数をオブジェクトとして返します。

## 演算子 {#operators}

### 算術演算子 {#arithmetic-operators}

算術演算子は数値で機能します。`+`演算子は文字列も連結します。演算子は暗黙的な型変換を実行しないため、`"hello" + 42`はエラーになります。

| Operator | 説明                 | 例             | 結果     |
|----------|-----------------------------|---------------------|------------|
| `+`      | 加算                    | `${{ 2 + 3 }}`      | `5`        |
| `+`      | 連結               | `${{ "a" + "b" }}`  | `"ab"`     |
| `-`      | 減算                 | `${{ 10 - 4 }}`     | `6`        |
| `*`      | 乗算              | `${{ 3 * 4 }}`      | `12`       |
| `/`      | 除算                    | `${{ 10 / 3 }}`     | `3.333...` |
| `%`      | 剰余（切り詰める除算） | `${{ 10 % 3 }}`     | `1`        |

ゼロによる除算はエラーになります。

### 比較演算子 {#comparison-operators}

比較演算子はブール値を返します。

| Operator | 説明           | 例            | 結果  |
|----------|-----------------------|--------------------|---------|
| `==`     | 等しい                 | `${{ 1 == 1 }}`    | `true`  |
| `!=`     | 等しくない             | `${{ 1 != 2 }}`    | `true`  |
| `<`      | 未満             | `${{ 1 < 2 }}`     | `true`  |
| `<=`     | 以下    | `${{ 2 <= 2 }}`    | `true`  |
| `>`      | より大きい          | `${{ 3 > 2 }}`     | `true`  |
| `>=`     | 以上 | `${{ 3 >= 3 }}`    | `true`  |

異なる型の値は型によって比較されるため、`1 == "1"`は`false`と評価されます。同じ型の値は、次の比較ルールに従います:

- 数値: 数値比較。
- 文字列: 辞書式比較（UTF-8バイト順）。
- ブール値: `false`は`true`未満です。
- 配列: 要素ごとの比較。
- オブジェクト: 長さ、次にキー、次に値によって比較されます。キーの順序は関係ありません。
- ヌル: `null`は`null`に等しい。

### 論理演算子 {#logical-operators}

論理演算子は短絡評価を使用し、必ずしもブール値ではなく、オペランドのいずれかを返します。この動作は、JavaScriptの`&&`および`||`演算子に似ています。

| Operator   | 説明 | 動作                                                                                      |
|------------|-------------|-----------------------------------------------------------------------------------------------|
| `\|\|`     | 論理OR  | 左オペランドが真の場合、それを返し、そうでなければ右オペランドを評価して返します。  |
| `&&`       | 論理AND | 左オペランドが偽の場合、それを返し、そうでなければ右オペランドを評価して返します。   |
| `!`        | 論理NOT | オペランドが偽の場合`true`を返し、真の場合`false`を返します。                                    |

`||`演算子は、デフォルト値を提供するために使用されます:

```yaml
${{ inputs.name || "default" }}
```

`inputs.name`が空でない文字列の場合、そのまま返されます。空またはヌルの場合、`"default"`が返されます。

### 単項演算子 {#unary-operators}

| Operator | 説明    | 例          | 結果  |
|----------|----------------|------------------|---------|
| `+`      | 単項プラス     | `${{ +5 }}`      | `5`     |
| `-`      | 単項マイナス | `${{ -5 }}`      | `-5`    |
| `!`      | 論理NOT    | `${{ !true }}`   | `false` |

### 演算子の優先順位 {#operator-precedence}

演算子は、最も高い優先順位から最も低い優先順位までリストされています。同じ行の演算子は、同じ優先順位を持っています。すべての二項演算子は左結合です。

| 優先順位  | 演算子                        |
|-------------|----------------------------------|
| 7（最高） | `.`、`[]`、`()`                  |
| 6           | `+`、`-`、`!`                    |
| 5           | `*`、`/`、`%`                    |
| 4           | `+`、`-`                         |
| 3           | `==`、`!=`、`<`、`<=`、`>`、`>=` |
| 2           | `&&`                             |
| 1（最低）  | `\|\|`                           |

優先順位をオーバーライドするには、括弧を使用します:

```yaml
${{ (1 + 2) * 3 }}
```

## データ構造 {#data-structures}

### 配列 {#arrays}

ブラケット表記で配列を作成します。要素は任意の型にすることができ、型を混在させることができます。末尾のカンマを使用できます。

```yaml
${{ [1, 2, 3] }}
${{ ["a", 1, true, null] }}
${{ [] }}
```

### オブジェクト {#objects}

ブレース表記でオブジェクトを作成します。キーは文字列に評価される必要があります。値は任意の型にすることができます。末尾のカンマは許可されています。

```yaml
${{ {name: "runner", version: 1} }}
${{ {"string-key": true} }}
${{ {} }}
```

オブジェクトキーとして使用される裸の識別子は、変数参照ではなく、文字列リテラルとして扱われます。変数をキーとして使用するには、括弧で囲みます:

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

### ブラケット表記 {#bracket-notation}

配列要素をインデックスで、またはオブジェクトプロパティを文字列キーでアクセスします:

```yaml
${{ my_array[0] }}
${{ my_object["property-name"] }}
```

プロパティ名にハイフンなどの特殊文字が含まれる場合は、ブラケット表記が必要です。

### チェイニング {#chaining}

プロパティアクセスと関数呼び出しをチェーンします:

```yaml
${{ steps.build.outputs.items[0] }}
```

## 関数呼び出し {#function-calls}

括弧を使用して関数を名前で呼び出します:

```yaml
${{ str(42) }}
${{ num("3.14") }}
```

## Truthy {#truthiness}

論理演算子と`!`演算子は、次のtruthyルールを使用します:

| 型    | Truthyの場合             | Falsyの場合        |
|---------|-------------------------|-------------------|
| ブール値 | `true`                  | `false`           |
| 文字列  | 長さが`0`より大きい | 空の文字列`""` |
| 数値  | `0`ではない                 | `0`               |
| 配列   | 長さが`0`より大きい | 空の配列`[]`  |
| オブジェクト  | 長さが`0`より大きい | 空のオブジェクト`{}` |
| ヌル    | 常にない                   | 常時            |

## 組み込み関数 {#built-in-functions}

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

その[truthy](#truthiness)に基づいて任意の値をブール値に変換します。

```yaml
${{ bool("hello") }}  # true
${{ bool("") }}       # false
${{ bool(0) }}        # false
${{ bool(1) }}        # true
```

## 予約語 {#reserved-words}

次の単語は予約されており、識別子として使用することはできません。これらは、将来の言語機能のために予約されています。

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

### ブールジョブ入力からの条件付きフラグ {#conditional-flags-from-boolean-job-inputs}

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

### ジョブ変数からのイメージ参照のビルド {#building-an-image-reference-from-job-variables}

```yaml
build_job:
  run:
    - name: build
      func: ./docker-build
      inputs:
        image: ${{ vars.CI_REGISTRY + "/" + vars.CI_PROJECT_PATH + ":" + vars.CI_PIPELINE_IID }}
```

### 続行ゲート {#continue-gate}

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
