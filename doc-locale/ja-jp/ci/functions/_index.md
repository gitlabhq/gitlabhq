---
stage: Verify
group: CI Functions Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CD関数
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

GitLab CI/CD関数は、ジョブの再利用可能なユニットであり、まとめて構成すると、GitLab CI/CDジョブで使用される`script`を置き換えます。関数を使用する必要はありません。ただし、関数の再利用性、構成可能性、テスト容易性、および独立性により、CI/CDパイプラインを理解および維持しやすくなります。

まず、[関数のセットアップチュートリアル](../../tutorials/set_up_cicd_functions/_index.md)をお試しください。独自の関数の作成を開始するには、[独自の関数の作成](#create-your-own-function)を参照してください。CI/CDコンポーネントとCI/CD関数の両方を使用することから、パイプラインがどのようにメリットを得られるかを理解するには、[CI/CDコンポーネントとCI/CD関数の組み合わせ](#combine-cicd-components-and-cicd-functions)を参照してください。

この実験的機能はまだ活発に開発されており、いつでも破壊的な変更が発生する可能性があります。破壊的な変更の詳細については、[変更履歴](https://gitlab.com/gitlab-org/step-runner/-/blob/main/CHANGELOG.md)を確認してください。

{{< alert type="note" >}}

GitLab Runner 17.11以降では、Dockerエグゼキューターを使用すると、GitLab Runnerによって`step-runner`バイナリがビルドコンテナに挿入されます。その他すべてのエグゼキューターについては、`step-runner`バイナリが実行環境にあることを確認してください。step runnerチームによって管理されている従来のDockerイメージ`registry.gitlab.com/gitlab-org/step-runner:v0`のサポートは、GitLab 18.0で終了となります。

{{< /alert >}}

## 関数ワークフロー {#function-workflow}

関数は、関数のシーケンスを実行するか、コマンドを呼び出すかのいずれかです。各関数は入力と出力を指定し、CI/CDジョブ変数、環境変数、およびファイルシステムやネットワーキングなどのリソースにアクセスできます。関数は、ファイルシステム上、GitLab.comのリポジトリ、またはその他のGitソースにローカルでホストされます。

さらに、関数は次のようになります:

- GitLab Runnerチームによって作成されたDockerコンテナで実行されます。[`Dockerfile`](https://gitlab.com/gitlab-org/step-runner/-/blob/main/Dockerfile)を確認できます。[エピック15073](https://gitlab.com/groups/gitlab-org/-/epics/15073)を追跡して、CI/CDジョブで定義された実行環境内で関数がいつ実行されるかを追跡します。
- Linuxに固有です。[エピック15074](https://gitlab.com/groups/gitlab-org/-/epics/15074)を追跡して、関数が複数のオペレーティングシステムをいつサポートするかを追跡します。

たとえば、このジョブは[`run`](../yaml/_index.md#run) CI/CDキーワードを使用して関数を実行します:

```yaml
job:
  variables:
    CI_SAY_HI_TO: "Sally"
  run:
    - name: say_hi
      step: gitlab.com/gitlab-org/ci-cd/runner-tools/echo-step@v1.0.0
      inputs:
        message: "hello, ${{job.CI_SAY_HI_TO}}"
```

このジョブを実行すると、メッセージ`hello, Sally`がジョブログに出力されます。echo関数の定義は次のとおりです:

```yaml
spec:
  inputs:
    message:
      type: string
---
exec:
  command:
    - bash
    - -c
    - echo '${{inputs.message}}'
```

## CI/CD関数を使用する {#use-cicd-functions}

`run`キーワードを使用して、関数を使用するようにGitLab CI/CDジョブを構成します。CI/CD関数を実行している場合、ジョブで`before_script`、`after_script`、または`script`を使用することはできません。

`run`キーワードは、実行する関数のリストを受け入れます。関数は、リストで定義されている順序で一度に1つずつ実行されます。各リスト項目には`name`と、`step`、`script`、または`action`のいずれかを指定します。

名前は英数字とアンダースコアのみで構成する必要があり、先頭を数字にすることはできません。

### 関数を実行する {#run-a-function}

`step`キーワードを使用して、[関数の場所](#function-location)を指定して、関数を実行します。

入力と環境変数を関数に渡すことができ、これらには値を補間する式を含めることができます。関数は、`CI_PROJECT_DIR` [事前定義変数](../variables/predefined_variables.md)によって定義されたディレクトリで実行されます。

たとえば、Gitリポジトリ`gitlab.com/components/echo`から読み込むecho関数は、環境変数`USER: Fred`と入力`message: hello Sally`を受け取ります:

```yaml
job:
  variables:
    CI_SAY_HI_TO: "Sally"
  run:
    - name: say_hi
      step: gitlab.com/components/echo@v1.0.0
      env:
        USER: "Fred"
      inputs:
        message: "hello ${{job.CI_SAY_HI_TO}}"
```

### スクリプトを実行する {#run-a-script}

`script`キーワードを使用して、Shellでスクリプトを実行します。`env`を使用してスクリプトに渡される環境変数は、Shellに設定されます。`CI_PROJECT_DIR` [事前定義変数](../variables/predefined_variables.md)によって定義されたディレクトリで、スクリプト関数が実行されます。

たとえば、次のスクリプトは、GitLabユーザーをジョブログに出力します:

```yaml
my-job:
  run:
    - name: say_hi
      script: echo hello ${{job.GITLAB_USER_LOGIN}}
```

スクリプト関数は`bash`シェルを使用し、bashが見つからない場合はフォールバックして`sh`を使用します。

### 関数の場所 {#function-location}

関数は、ファイルシステム上の相対パス、GitLab.comリポジトリ、またはその他のGitソースから読み込むことができます。

#### ファイルシステムから関数を読み込む {#load-a-function-from-the-file-system}

ピリオド`.`で始まる相対パスを使用して、ファイルシステムから関数を読み込むます。パスによって参照されるフォルダーには、`step.yml`関数定義ファイルが含まれている必要があります。パスセパレータは、オペレーティングシステムに関係なく、常にフォワードスラッシュ`/`を使用する必要があります。

例: 

```yaml
- name: my-step
  step: ./path/to/my-step
```

#### Gitリポジトリから関数を読み込む {#load-a-function-from-a-git-repository}

リポジトリのURLとリビジョン（コミット、ブランチ、またはタグ）を指定して、Gitリポジトリから関数を読み込むます。リポジトリの`steps`フォルダーにある関数の相対ディレクトリとファイル名を指定することもできます。ディレクトリを指定せずにURLを指定すると、`steps`フォルダー内の`step.yml`が読み込まれます。

例: 

- ブランチを使用して関数を指定します:

  ```yaml
  job:
    run:
      - name: specifying_a_branch
        step: gitlab.com/components/echo@main
  ```

- タグを使用して関数を指定します:

  ```yaml
  job:
    run:
      - name: specifying_a_tag
        step: gitlab.com/components/echo@v1.0.0
  ```

- リポジトリ内のディレクトリ、ファイル名、およびGitコミットを使用して関数を指定します:

  ```yaml
  job:
    run:
      - name: specifying_a_directory_file_and_commit_within_the_repository
        step: gitlab.com/components/echo/-/reverse/my-step.yml@3c63f399ace12061db4b8b9a29f522f41a3d7f25
  ```

`steps`フォルダー以外のフォルダーまたはファイルを指定するには、拡張された`step`構文を使用します:

- リポジトリルートに対する相対的なディレクトリとファイル名を指定します。

  ```yaml
  job:
    run:
      - name: specifying_a_directory_outside_steps
        step:
          git:
            url: gitlab.com/components/echo
            rev: main
            dir: my-steps/sub-directory  # optional, defaults to the repository root
            file: my-step.yml            # optional, defaults to `step.yml`
  ```

### 式 {#expressions}

式は、二重中括弧`${{ }}`で囲まれたミニ言語です。式は、ジョブ環境での関数の実行直前に評価され、次で使用できます:

- 入力値
- 環境変数値
- 関数の場所URL
- 実行可能コマンド
- 実行可能作業ディレクトリ
- 関数のシーケンスでの出力
- `script`関数
- `action`関数

式は、次の変数を参照できます:

| 変数                    | 例                                                       | 説明 |
|:----------------------------|:--------------------------------------------------------------|:------------|
| `env`                       | `${{env.HOME}}`                                               | 実行環境または以前の関数で設定された環境変数にアクセスします。 |
| `export_file`               | `echo '{"name":"NAME","value":"Fred"}' >${{export_file}}`     | [エクスポートファイル](#export-an-environment-variable)へのパス。後続の実行関数で使用するために、このファイルに書き込んで環境変数をエクスポートします。 |
| `inputs`                    | `${{inputs.message}}`                                         | 関数の入力にアクセスします。 |
| `job`                       | `${{job.GITLAB_USER_NAME}}`                                   | `CI_`、`DOCKER_`、または`GITLAB_`で始まるものに限定されたGitLab CI/CD変数にアクセスします。 |
| `output_file`               | `echo '{"name":"meaning_life","value":42}' >${{output_file}}` | [出力ファイル](#return-an-output)へのパス。このファイルに書き込んで、関数から出力変数を設定します。 |
| `step_dir`                  | `work_dir: ${{step_dir}}`                                     | 関数がダウンロードされたディレクトリ。関数内のファイルを参照したり、実行可能関数の作業ディレクトリを設定したりするために使用します。 |
| `steps.[step_name].outputs` | `${{steps.my_step.outputs.name}}`                             | 以前に実行された関数から[出力](#specify-outputs)にアクセスします。関数名を使用して特定の関数を選択します。 |
| `work_dir`                  | `${{work_dir}}`                                               | 実行中の関数の作業ディレクトリ。 |

式は、二重角括弧（`$[[ ]]`）を使用するテンプレート補間とは異なり、ジョブの生成時に評価されます。

式は、名前が`CI_`、`DOCKER_`、`GITLAB_`で始まるCI/CDジョブ変数にのみアクセスできます。[エピック15073](https://gitlab.com/groups/gitlab-org/-/epics/15073)を追跡して、関数がすべてのCI/CDジョブ変数にアクセスできるタイミングを追跡します。

### 以前の関数の出力の使用 {#using-prior-function-outputs}

関数の入力は、関数名と出力変数名を参照することにより、以前の関数からの出力を参照できます。

たとえば、`gitlab.com/components/random-string`関数が`random_value`という出力変数を定義した場合:

```yaml
job:
  run:
    - name: generate_rand
      step: gitlab.com/components/random
    - name: echo_random
      step: gitlab.com/components/echo
      inputs:
        message: "The random value is: ${{steps.generate_rand.outputs.random_value}}"
```

### 環境変数 {#environment-variables}

関数は[設定](#set-environment-variables)環境変数を[エクスポート](#export-an-environment-variable)し、環境変数は、`step`、`script`、または`action`を使用するときに渡すことができます。

環境変数は、次のリストに示す設定方法のうち、上にあるものほど優先順位が高くなります:

1. `step.yml`内で`env`キーワードを使用して設定された変数。
1. 関数のシーケンスで関数に渡される`env`キーワードを使用します。
1. シーケンス内のすべての関数に`env`キーワードを使用します。
1. 以前に実行された関数が`${{export_file}}`に書き込んだ場所。
1. Runnerによって設定された変数。
1. コンテナによって設定された変数。

## 独自の関数を作成する {#create-your-own-function}

独自の関数を作成するには、次のタスクを実行します:

1. CI/CDジョブの実行時にアクセス可能なGitLabプロジェクト、Gitリポジトリ、またはファイルシステム上のディレクトリを作成します。
1. `step.yml`ファイルを作成し、プロジェクト、リポジトリ、またはディレクトリのルートフォルダーに配置します。
1. `step.yml`で関数の[仕様](#the-function-specification)を定義します。
1. `step.yml`で関数の[定義](#the-function-definition)を定義します。
1. 関数が使用するファイルをプロジェクト、リポジトリ、またはディレクトリに追加します。

関数の作成後、[ジョブで関数を使用](#run-a-function)できます。

### 関数仕様 {#the-function-specification}

関数仕様は、関数`step.yml`に含まれる2つのドキュメントの1つです。仕様は、関数が受信および返す入力と出力を定義します。

#### 入力を指定する {#specify-inputs}

入力名には英数字とアンダースコアのみを使用でき、先頭を数字にすることはできません。入力には型を指定する必要があり、オプションでデフォルト値を指定できます。デフォルト値のない入力は必須入力であり、関数を使用するときに指定する必要があります。

入力は、次のいずれかの型である必要があります。

| 型      | 例                 | 説明 |
|:----------|:------------------------|:------------|
| `array`   | `["a","b"]`             | 型指定されていない項目のリスト。 |
| `boolean` | `true`                  | trueまたはfalse。 |
| `number`  | `56.77`                 | 64ビット浮動小数点数。 |
| `string`  | `"brown cow"`           | テキスト。       |
| `struct`  | `{"k1":"v1","k2":"v2"}` | 構造化されたコンテンツ。 |

たとえば、関数が`string`型のオプションの入力`greeting`を受け入れることを指定するには、次のようにします:

```yaml
spec:
  inputs:
    greeting:
      type: string
      default: "hello, world"
---
```

ステップを使用するときに入力を提供するには、次のようにします:

```yaml
run:
  - name: my_step
    step: ./my-step
    inputs:
      greeting: "hello, another world"
```

#### 出力を指定する {#specify-outputs}

入力と同様に、出力名には英数字とアンダースコアのみを使用でき、先頭を数字にすることはできません。出力には型を指定する必要があり、オプションでデフォルト値を指定できます。関数が出力を返さない場合、デフォルト値が返されます。

出力は、次のいずれかの型である必要があります。

| 型         | 例                 | 説明 |
|:-------------|:------------------------|:------------|
| `array`      | `["a","b"]`             | 型指定されていない項目のリスト。 |
| `boolean`    | `true`                  | trueまたはfalse。 |
| `number`     | `56.77`                 | 64ビット浮動小数点数。 |
| `string`     | `"brown cow"`           | テキスト。       |
| `struct`     | `{"k1":"v1","k2":"v2"}` | 構造化されたコンテンツ。 |

たとえば、関数が`number`型の`value`という出力を返すように指定するには、次のようにします:

```yaml
spec:
  outputs:
    value:
      type: number
---
```

ステップを使用するときに出力を使用するには、次のようにします:

```yaml
run:
  - name: random_generator
    step: ./random_gen
  - name: echo_number
    step: ./echo
    inputs:
      message: "Random number generated was ${{step.random_generator.outputs.value}}"
```

#### 委任された出力を指定する {#specify-delegated-outputs}

出力名と型を指定する代わりに、出力を特定のステップに完全に委任できます。ステップによって返される出力は、関数によって返されます。関数定義の`delegate`キーワードは、関数によって返されるステップ出力を決定します。

たとえば、次の関数は、`random_gen`関数によって返される出力を返します。

```yaml
spec:
  outputs: delegate
---
run:
  - name: random_generator
    step: ./random_gen
delegate: random_generator
```

#### 入力または出力を指定しない {#specify-no-inputs-or-outputs}

関数は、入力を必要としないか、出力を返さない場合があります。これは、関数がディスクに書き込むか、環境変数を設定するか、STDOUTに出力するだけの場合に発生する可能性があります。この場合、`spec:`は次のように空になります:

```yaml
spec:
---
```

### 関数定義 {#the-function-definition}

関数は次のことができます:

- 環境変数を設定する
- コマンドを実行する。
- 他の関数のシーケンスを実行します。

#### 環境変数を設定する {#set-environment-variables}

`env`キーワードを使用して環境変数を設定します。環境変数名には英数字とアンダースコアのみを使用でき、先頭を数字にすることはできません。

環境変数は、実行可能コマンド、または関数のシーケンスを実行している場合はすべての関数で使用できるようになります。例: 

```yaml
spec:
---
env:
  FIRST_NAME: Sally
  LAST_NAME: Seashells
run:
  # omitted for brevity
```

関数は、ランナー環境から環境変数のサブセットにのみアクセスできます。[エピック15073](https://gitlab.com/groups/gitlab-org/-/epics/15073)を追跡して、関数がすべての環境変数にアクセスできるタイミングを追跡します。

#### コマンドを実行する {#execute-a-command}

関数は、`exec`キーワードを使用してコマンドを実行することを宣言します。コマンドは必須ですが、作業ディレクトリ（`work_dir`）はオプションです。関数によって設定された環境変数は、実行中のプロセスで使用できます。

たとえば、次の関数は、関数ディレクトリをジョブログに出力します:

```yaml
spec:
---
exec:
  work_dir: ${{step_dir}}
  command:
    - bash
    - -c
    - "echo ${PWD}"
```

> [!note]実行可能関数に必要な依存関係も、関数によってインストールする必要があります。たとえば、関数が`go`を呼び出す場合、最初にインストールする必要があります。

##### 出力を返す {#return-an-output}

実行可能関数は、JSON行形式で`${{output_file}}`に行を追加することにより、出力を返します。各行は、`name`と`value`のキーペアを持つJSONオブジェクトです。`name`は文字列でなければならず、`value`は関数仕様の出力の種類と一致する型でなければなりません:

| 関数仕様の型 | 期待されるJSONL値の型 |
|:------------------------|:--------------------------|
| `array`                 | `array`                   |
| `boolean`               | `boolean`                 |
| `number`                | `number`                  |
| `string`                | `string`                  |
| `struct`                | `object`                  |

たとえば、`string`値`Range Rover`を持つ`car`という名前の出力を返すには、次のようにします:

```yaml
spec:
  outputs:
    car:
      type: string
---
exec:
  command:
    - bash
    - -c
    - echo '{"name":"car","value":"Range Rover"}' >${{output_file}}
```

##### 環境変数をエクスポートする {#export-an-environment-variable}

実行可能関数は、JSON行形式で`${{export_file}}`に行を追加することにより、環境変数をエクスポートします。各行は、`name`と`value`のキーペアを持つJSONオブジェクトです。`name`と`value`はどちらも文字列である必要があります。

たとえば、変数`GOPATH`に値`/go`を設定するには、次のようにします:

```yaml
spec:
---
exec:
  command:
    - bash
    - -c
    - echo '{"name":"GOPATH","value":"/go"}' >${{export_file}}
```

#### 関数のシーケンスを実行する {#run-a-sequence-of-functions}

関数は、`steps`キーワードを使用して関数のシーケンスを実行することを宣言します。関数は、リストで定義されている順序で一度に1つずつ実行されます。この構文は、`run`キーワードと同じです。

関数には、英数字とアンダースコアのみで構成される名前が必要であり、数字で始めてはなりません。

たとえば、この関数はGoをインストールしてから、Goが既にインストールされていることを前提とする2番目の関数を実行します:

```yaml
spec:
---
run:
  - name: install_go
    step: ./go-steps/install-go
    inputs:
      version: "1.22"
  - name: format_go_code
    step: ./go-steps/go-fmt
    inputs:
      code: path/to/go-code
```

##### 出力を返す {#return-an-output-1}

出力は、`outputs`キーワードを使用して関数のシーケンスから返されます。出力の値の型は、関数仕様の出力の型と一致する必要があります。

たとえば、次の関数は、インストールされているJavaバージョンを出力として返します。これは、`install_java`関数が`java_version`という名前の出力を返すことを前提としています。

```yaml
spec:
  outputs:
    java_version:
      type: string
---
run:
  - name: install_java
    step: ./common/install-java
outputs:
  java_version: "the java version is ${{steps.install_java.outputs.java_version}}"
```

または、`delegate`キーワードを使用してサブステップのすべての出力を返すこともできます。例: 

```yaml
spec:
  outputs: delegate
---
run:
  - name: install_java
    step: ./common/install-java
delegate: install_java
```

## CI/CDコンポーネントとCI/CD関数の組み合わせ {#combine-cicd-components-and-cicd-functions}

[CI/CDコンポーネント](../components/_index.md)は、再利用可能な単一のパイプライン設定ユニットです。パイプラインの作成時に組み込まれ、それらのコンポーネントによってジョブや設定がパイプラインに追加されます。コンポーネントプロジェクトの共通スクリプトやプログラムなどのファイルは、CI/CDジョブから参照できません。

CI/CD関数は、ジョブの再利用可能なユニットです。ジョブを実行すると、参照される関数が実行環境またはイメージにダウンロードされ、関数に含まれる追加ファイルが取り込まれます。関数の実行は、ジョブの`script`を置き換えます。

コンポーネントと関数は連携して、CI/CDパイプラインのソリューションを作成します。関数はジョブの構成方法の複雑さを処理し、ジョブの実行に必要なファイルを自動的に取得するます。コンポーネントを使用するとジョブの設定をインポートできますが、その内部的な構成はユーザーからは見えません。

関数とコンポーネントは、式の構文を区別するために、異なる式構文を使用します。コンポーネントの式では角括弧`$[[ ]]`を使用し、パイプラインの作成時に評価されます。関数式は中かっこ`${{ }}`を使用し、関数の実行直前にジョブの実行中に評価されます。

たとえば、プロジェクトで、Goコードを整形するジョブを追加するコンポーネントを使用できるとします:

- プロジェクトの`.gitlab-ci.yml`ファイルでは、次のようになります:

  ```yaml
  include:
  - component: gitlab.com/my-components/go@main
    inputs:
      fmt_packages: "./..."
  ```

- 内部的には、コンポーネントはCI/CD関数を使用してジョブを構成し、Goをインストールしてからフォーマッタを実行します。コンポーネントの`templates/go.yml`ファイルでは、次のようになります:

  ```yaml
  spec:
    inputs:
      fmt_packages:
        description: The Go packages that will be formatted using the Go formatter.
      go_version:
        default: "1.22"
        description: The version of Go to install before running go fmt.
  ---

  format code:
    run:
      - name: install_go
        step: ./languages/go/install
        inputs:
          version: $[[ inputs.go_version ]]                    # version set to the value of the component input go_version
      - name: format_code
        step: ./languages/go/go-fmt
        inputs:
          go_binary: ${{ steps.install_go.outputs.go_binary }} # go_binary set to the value of the go_binary output from the previous function
          fmt_packages: $[[ inputs.fmt_packages ]]             # fmt_packages set to the value of the component input fmt_packages
  ```

この例では、CI/CDコンポーネントは、コンポーネントの作成者から関数の複雑さを隠しています。

## トラブルシューティング {#troubleshooting}

### HTTPS URLから関数をフェッチする {#fetching-functions-from-an-https-url}

`tls: failed to verify certificate: x509: certificate signed by unknown authority`などのエラーメッセージは、オペレーティングシステムが関数をホストしているサーバーを認識または信頼していないことを示しています。

一般的な原因は、信頼できるルート証明書がインストールされていないDockerイメージを使用して、ジョブで関数が実行される場合です。コンテナに証明書をインストールするか、ジョブ`image`に組み込むことで、問題を解決できます。

`script`関数を使用して、関数をフェッチする前に、コンテナに依存関係をインストールできます。例: 

```yaml
ubuntu_job:
  image: ubuntu:24.04
  run:
    - name: install_certs  # Install trusted certificates first
      script: apt update && apt install --assume-yes --no-install-recommends ca-certificates
    - name: echo_step      # With trusted certificates, use HTTPS without errors
      step: https://gitlab.com/user/my_steps/hello_world@main
```
