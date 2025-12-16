---
stage: Verify
group: CI Functions Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CDステップ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

ステップはジョブの再利用可能なユニットです。組み合わせることで、GitLab CI/CDジョブで使用される`script`を置き換えることができます。ステップの使用は必須ではありません。ただし、ステップには再利用性、構成可能性、テスト可能性、独立性があることから、CI/CDパイプラインの理解と保守が容易になります。

まず、[ステップをセットアップするチュートリアル](../../tutorials/setup_steps/_index.md)をお試しください。独自のステップの作成を開始するには、[独自のステップを作成する](#create-your-own-step)を参照してください。CI/CDコンポーネントとCI/CDステップの両方を使用するとパイプラインにどのようなメリットがあるのかを理解するには、[CI/CDコンポーネントとCI/CDステップを組み合わせる](#combine-cicd-components-and-cicd-steps)を参照してください。

この実験的機能はまだ活発に開発されており、いつでも破壊的な変更が発生する可能性があります。破壊的な変更の詳細については、[変更履歴](https://gitlab.com/gitlab-org/step-runner/-/blob/main/CHANGELOG.md)を確認してください。

{{< alert type="note" >}}

GitLab Runner 17.11以降では、Docker executorを使用する際に、GitLab Runnerがstep-runnerバイナリをビルドコンテナに組み込みます。その他すべてのexecutorでは、step-runnerバイナリが実行環境に存在することを確認してください。step runnerチームによって管理されている従来のDockerイメージ`registry.gitlab.com/gitlab-org/step-runner:v0`のサポートは、GitLab 18.0で終了となります。

{{< /alert >}}

## ステップワークフロー {#step-workflow}

ステップは、ステップのシーケンスを実行するか、コマンドを実行します。各ステップは入力と出力を指定し、CI/CDジョブ変数、環境変数、ファイルシステムやネットワーキングなどのリソースにアクセスできます。ステップは、ローカルのファイルシステム、GitLab.comリポジトリ、またはその他のGitソースでホストされます。

さらに、ステップは:

- Stepsチームによって作成されたDockerコンテナで実行されます。[`Dockerfile`](https://gitlab.com/gitlab-org/step-runner/-/blob/main/Dockerfile)を確認できます。ステップがCI/CDジョブによって定義された環境内で実行されるようになる時期については、[エピック15073](https://gitlab.com/groups/gitlab-org/-/epics/15073)を参照してください。
- Linuxに固有です。ステップが複数のオペレーティングシステムをサポートするようになる時期については、[エピック15074](https://gitlab.com/groups/gitlab-org/-/epics/15074)を参照してください。

たとえば、このジョブは[`run`](../yaml/_index.md#run) CI/CDキーワードを使用して次のステップを実行します:

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

このジョブを実行すると、メッセージ`hello, Sally`がジョブログに出力されます。echoステップの定義は次のとおりです:

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

## CI/CDステップを使用する {#use-cicd-steps}

`run`キーワードを使用して、CIステップを使用するようにGitLab CI/CDジョブを設定します。CI/CDステップを実行している場合、ジョブで`before_script`、`after_script`、または`script`を使用することはできません。

`run`キーワードは、実行するステップのリストを受け入れます。ステップは、リストで定義されている順に1つずつ実行されます。各リスト項目には`name`と、`step`、`script`、または`action`のいずれかを指定します。

名前は英数字とアンダースコアのみで構成する必要があり、先頭を数字にすることはできません。

### ステップを実行する {#run-a-step}

`step`キーワードを使用して[ステップの場所](#step-location)を指定することで、ステップを実行します。

ステップには入力と環境変数を渡すことができ、それらには値を補間する式を含めることができます。ステップは、`CI_PROJECT_DIR`[定義済み変数](../variables/predefined_variables.md)によって定義されたディレクトリで実行されます。

次の例では、Gitリポジトリ`gitlab.com/components/echo`から読み込まれたechoステップは、環境変数`USER: Fred`と入力`message: hello Sally`を受け取ります:

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

`script`キーワードを使用して、Shellでスクリプトを実行します。`env`を使用してスクリプトに渡される環境変数は、Shellに設定されます。スクリプトステップは、`CI_PROJECT_DIR`[定義済み変数](../variables/predefined_variables.md)によって定義されたディレクトリで実行されます。

たとえば、次のスクリプトは、GitLabユーザーをジョブログに出力します:

```yaml
my-job:
  run:
    - name: say_hi
      script: echo hello ${{job.GITLAB_USER_LOGIN}}
```

スクリプトステップは`bash` Shellを使用しますが、bashが見つからない場合はフォールバックして`sh`を使用します。

### GitHubアクションを実行する {#run-a-github-action}

`action`キーワードを使用してGitHubアクションを実行します。入力と環境変数はアクションに直接渡され、アクションの出力はステップ出力として返されます。アクションステップは、`CI_PROJECT_DIR`[定義済み変数](../variables/predefined_variables.md)によって定義されたディレクトリで実行されます。

アクションの実行には、`dind`サービスが必要です。詳細については、[Dockerを使用してDockerイメージをビルドする](../docker/using_docker_build.md)を参照してください。

たとえば、次のステップは`action`を使用して`yq`を使用できるようにします:

```yaml
my-job:
  run:
    - name: say_hi_again
      action: mikefarah/yq@master
      inputs:
        cmd: echo ["hi ${{job.GITLAB_USER_LOGIN}} again!"] | yq .[0]
```

#### 既知の問題 {#known-issues}

GitLabで実行されるアクションは、アーティファクトの直接アップロードをサポートしていません。アーティファクトは、ファイルシステムとキャッシュに書き込み、既存の[`artifacts`キーワード](../yaml/_index.md#artifacts)および[`cache`キーワード](../yaml/_index.md#cache)で選択する必要があります。

### ステップの場所 {#step-location}

ステップは、ファイルシステムの相対パス、GitLab.comリポジトリ、またはその他のGitソースから読み込まれます。

#### ファイルシステムからステップを読み込む {#load-a-step-from-the-file-system}

ピリオド`.`で始まる相対パスを使用して、ファイルシステムからステップを読み込みます。パスによって参照されるフォルダーには、`step.yml`ステップ定義ファイルが含まれている必要があります。パスセパレータは、オペレーティングシステムに関係なく、常にフォワードスラッシュ`/`を使用する必要があります。

次に例を示します: 

```yaml
- name: my-step
  step: ./path/to/my-step
```

#### Gitリポジトリからステップを読み込む {#load-a-step-from-a-git-repository}

URLとリポジトリのリビジョン（コミット、ブランチ、またはタグ）を指定して、Gitリポジトリからステップを読み込みます。リポジトリの`steps`フォルダーにあるステップの相対ディレクトリとファイル名を指定することもできます。ディレクトリを指定せずにURLを指定すると、`steps`フォルダー内の`step.yml`が読み込まれます。

次に例を示します: 

- ブランチでステップを指定します:

  ```yaml
  job:
    run:
      - name: specifying_a_branch
        step: gitlab.com/components/echo@main
  ```

- タグでステップを指定します:

  ```yaml
  job:
    run:
      - name: specifying_a_tag
        step: gitlab.com/components/echo@v1.0.0
  ```

- リポジトリ内のディレクトリ、ファイル名、Gitコミットでステップを指定します:

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

式は、二重中括弧`${{ }}`で囲まれたミニ言語です。式は、ジョブ環境でステップを実行する直前に評価され、以下で使用できます:

- 入力値
- 環境変数値
- ステップの場所を示すURL
- 実行可能コマンド
- 実行可能作業ディレクトリ
- ステップのシーケンスにおける出力
- `script`ステップ
- `action`ステップ

式は、次の変数を参照できます:

| 変数                    | 例                                                       | 説明 |
|:----------------------------|:--------------------------------------------------------------|:------------|
| `env`                       | `${{env.HOME}}`                                               | 実行環境または前のステップで設定された環境変数にアクセスします。 |
| `export_file`               | `echo '{"name":"NAME","value":"Fred"}' >${{export_file}}`     | [エクスポートファイル](#export-an-environment-variable)へのパス。このファイルに書き込んで、後続の実行ステップで使用するために環境変数をエクスポートします。 |
| `inputs`                    | `${{inputs.message}}`                                         | ステップの入力にアクセスします。 |
| `job`                       | `${{job.GITLAB_USER_NAME}}`                                   | `CI_`、`DOCKER_`、または`GITLAB_`で始まるものに限定されたGitLab CI/CD変数にアクセスします。 |
| `output_file`               | `echo '{"name":"meaning_life","value":42}' >${{output_file}}` | [出力ファイル](#return-an-output)へのパス。このファイルに書き込んで、ステップから出力変数を設定します。 |
| `step_dir`                  | `work_dir: ${{step_dir}}`                                     | ステップがダウンロードされたディレクトリ。ステップ内のファイルを参照したり、実行可能なステップの作業ディレクトリを設定したりするために使用します。 |
| `steps.[step_name].outputs` | `${{steps.my_step.outputs.name}}`                             | 以前に実行されたステップからの[出力](#specify-outputs)にアクセスします。ステップ名を使用して特定のステップを選択します。 |
| `work_dir`                  | `${{work_dir}}`                                               | 実行中のステップの作業ディレクトリ。 |

式は、二重角括弧（`$[[ ]]`）を使用するテンプレート補間とは異なり、ジョブの生成時に評価されます。

式は、名前が`CI_`、`DOCKER_`、`GITLAB_`で始まるCI/CDジョブ変数にのみアクセスできます。ステップがすべてのCI/CDジョブ変数にアクセスできるようになる時期については、[エピック15073](https://gitlab.com/groups/gitlab-org/-/epics/15073)を参照してください。

### 前のステップの出力を使用する {#using-prior-step-outputs}

ステップの入力は、ステップ名と出力変数名を参照することにより、前のステップからの出力を参照できます。

たとえば、`gitlab.com/components/random-string`ステップで`random_value`という出力変数を定義した場合、次のようになります:

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

ステップでは、環境変数を[設定](#set-environment-variables)したり、[エクスポート](#export-an-environment-variable)したりできます。また、`step`、`script`、`action`を使用する際に環境変数を渡すことができます。

環境変数は、次のリストに示す設定方法のうち、上にあるものほど優先順位が高くなります:

1. `step.yml`内で`env`キーワードを使用して設定された変数。
1. ステップのシーケンスの中で、`env`キーワードを使用して特定のステップに渡された変数。
1. シーケンス内のすべてのステップに対して`env`キーワードを使用して設定された変数。
1. 以前に実行されたステップが`${{export_file}}`に書き込んだ変数。
1. Runnerによって設定された変数。
1. コンテナによって設定された変数。

## 独自のステップを作成する {#create-your-own-step}

独自のステップを作成するには、次のタスクを実行します:

1. CI/CDジョブの実行時にアクセス可能なGitLabプロジェクト、Gitリポジトリ、またはファイルシステム上のディレクトリを作成します。
1. `step.yml`ファイルを作成し、プロジェクト、リポジトリ、またはディレクトリのルートフォルダーに配置します。
1. `step.yml`にステップの[仕様](#the-step-specification)を指定します。
1. `step.yml`にステップの[定義](#the-step-definition)を指定します。
1. ステップで使用するファイルをプロジェクト、リポジトリ、またはディレクトリに追加します。

ステップを作成したら、[ジョブでステップを使用](#run-a-step)できます。

### ステップ仕様 {#the-step-specification}

ステップ仕様は、ステップ`step.yml`に含まれる2つのドキュメントのうち最初に位置するものです。仕様は、ステップが受け取る入力と返す出力を定義します。

#### 入力を指定する {#specify-inputs}

入力名には英数字とアンダースコアのみを使用でき、先頭を数字にすることはできません。入力には型を指定する必要があり、オプションでデフォルト値を指定できます。デフォルト値が指定されていない入力は必須入力となり、ステップを使用するときに必ず指定しなくてはなりません。

入力は、次のいずれかの型である必要があります。

| 型      | 例                 | 説明 |
|:----------|:------------------------|:------------|
| `array`   | `["a","b"]`             | 型指定されていない項目のリスト。 |
| `boolean` | `true`                  | trueまたはfalse。 |
| `number`  | `56.77`                 | 64ビット浮動小数点数。 |
| `string`  | `"brown cow"`           | テキスト。       |
| `struct`  | `{"k1":"v1","k2":"v2"}` | 構造化されたコンテンツ。 |

たとえば、ステップが`string`型の`greeting`というオプションの入力を受け入れるよう指定するには、次のようにします:

```yaml
spec:
  inputs:
    greeting:
      type: string
      default: "hello, world"
---
```

ステップを使用するときに入力を渡すには、次のようにします:

```yaml
run:
  - name: my_step
    step: ./my-step
    inputs:
      greeting: "hello, another world"
```

#### 出力を指定する {#specify-outputs}

入力と同様に、出力名には英数字とアンダースコアのみを使用でき、先頭を数字にすることはできません。出力には型を指定する必要があり、オプションでデフォルト値を指定できます。ステップが出力を返さない場合、デフォルト値が返されます。

出力は、次のいずれかの型である必要があります。

| 型         | 例                 | 説明 |
|:-------------|:------------------------|:------------|
| `array`      | `["a","b"]`             | 型指定されていない項目のリスト。 |
| `boolean`    | `true`                  | trueまたはfalse。 |
| `number`     | `56.77`                 | 64ビット浮動小数点数。 |
| `string`     | `"brown cow"`           | テキスト。       |
| `struct`     | `{"k1":"v1","k2":"v2"}` | 構造化されたコンテンツ。 |

たとえば、ステップが`number`型の`value`という出力を返すよう指定するには、次のようにします:

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

出力名と型を指定する代わりに、出力をサブステップに完全に委任できます。サブステップによって返される出力は、ステップによって返されます。ステップ定義の`delegate`キーワードで、ステップがどのサブステップの出力を返すかを指定します。

たとえば、次のステップは、`random_gen`ステップによって返される出力を返します。

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

ステップでは、入力が必要ない場合や、出力を返さない場合があります。たとえば、ステップがディスクへの書き込み、環境変数の設定、STDOUTへの出力だけを行う場合がこれにあたります。この場合、`spec:`は次のように空になります:

```yaml
spec:
---
```

### ステップ定義 {#the-step-definition}

ステップでは、次のことが可能です:

- 環境変数を設定する。
- コマンドを実行する。
- 他のステップのシーケンスを実行する。

#### 環境変数を設定する {#set-environment-variables}

`env`キーワードを使用して環境変数を設定します。環境変数名には英数字とアンダースコアのみを使用でき、先頭を数字にすることはできません。

環境変数は、実行可能なコマンド、またはステップのシーケンスを実行する場合はすべてのステップで使用できます。次に例を示します: 

```yaml
spec:
---
env:
  FIRST_NAME: Sally
  LAST_NAME: Seashells
run:
  # omitted for brevity
```

ステップは、Runner環境の環境変数の一部にしかアクセスできません。ステップがすべての環境変数にアクセスできるようになる時期については、[エピック15073](https://gitlab.com/groups/gitlab-org/-/epics/15073)を参照してください。

#### コマンドを実行する {#execute-a-command}

ステップは、`exec`キーワードを使用してコマンドを実行することを宣言します。コマンドは必須ですが、作業ディレクトリ（`work_dir`）はオプションです。ステップによって設定された環境変数は、実行中のプロセスで使用できます。

たとえば、次のステップはステップディレクトリをジョブログに出力します:

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

{{< alert type="note" >}}

実行するステップに必要な依存関係も、そのステップでインストールしておく必要があります。たとえば、ステップが`go`を呼び出す場合は、まずそれをインストールしなければなりません。

{{< /alert >}}

##### 出力を返す {#return-an-output}

実行可能ステップは、JSON Line形式で`${{output_file}}`に行を追加することにより、出力を返します。各行は、`name`と`value`のキーペアを持つJSONオブジェクトです。`name`は文字列で、`value`の型は次のステップ仕様で定義された出力の型と一致する必要があります:

| ステップ仕様の型 | 期待されるJSONL値の型 |
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

実行可能ステップは、JSON Line形式で`${{export_file}}`に行を追加することにより、環境変数をエクスポートします。各行は、`name`と`value`のキーペアを持つJSONオブジェクトです。`name`と`value`はどちらも文字列である必要があります。

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

#### ステップのシーケンスを実行する {#run-a-sequence-of-steps}

ステップは、`steps`キーワードを使用してステップのシーケンスを実行することを宣言します。ステップは、リストで定義された順に1つずつ実行されます。この構文は、`run`キーワードと同じです。

ステップの名前は、英数字とアンダースコアのみで構成され、先頭を数字にすることはできません。

たとえば、このステップではGoをインストールしてから、Goがすでにインストールされていることを前提とする2番目のステップを実行します:

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

出力は、`outputs`キーワードを使用して、ステップのシーケンスから返されます。出力値の型は、ステップ仕様で定義された出力の型と一致する必要があります。

たとえば、次のステップはインストールされているJavaのバージョンを出力として返します。これは、`install_java`ステップが`java_version`という名前の出力を返すことを前提としています。

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

または、`delegate`キーワードを使用してサブステップのすべての出力を返すこともできます。次に例を示します: 

```yaml
spec:
  outputs: delegate
---
run:
  - name: install_java
    step: ./common/install-java
delegate: install_java
```

## CI/CDコンポーネントとCI/CDステップを組み合わせる {#combine-cicd-components-and-cicd-steps}

[CI/CDコンポーネント](../components/_index.md)は、再利用可能な単一のパイプライン設定ユニットです。パイプラインの作成時に組み込まれ、それらのコンポーネントによってジョブや設定がパイプラインに追加されます。コンポーネントプロジェクトの共通スクリプトやプログラムなどのファイルは、CI/CDジョブから参照できません。

CI/CDステップは、ジョブの再利用可能なユニットです。ジョブの実行時に、参照されたステップが実行環境またはイメージにダウンロードされ、ステップに含まれている追加ファイルも一緒に取り込まれます。ステップを実行すると、ジョブの`script`が置き換えられます。

コンポーネントとステップを組み合わせることで、CI/CDパイプラインのソリューションを構築できます。ステップを使用することでジョブの構成方法の複雑な部分が整理され、ジョブを実行するために必要なファイルを自動的に取得できます。コンポーネントを使用するとジョブの設定をインポートできますが、その内部的な構成はユーザーからは見えません。

ステップとコンポーネントは、式の種類を区別するために異なる構文を使用します。コンポーネントの式では角括弧`$[[ ]]`を使用し、パイプラインの作成時に評価されます。ステップの式では中括弧`${{ }}`を使用し、ジョブの実行時、ステップを実行する直前に評価されます。

たとえば、プロジェクトで、Goコードを整形するジョブを追加するコンポーネントを使用できるとします:

- プロジェクトの`.gitlab-ci.yml`ファイルでは、次のようになります:

  ```yaml
  include:
  - component: gitlab.com/my-components/go@main
    inputs:
      fmt_packages: "./..."
  ```

- 内部的には、コンポーネントはCI/CDステップを使用してジョブを構成しており、Goをインストールした後、フォーマッターを実行します。コンポーネントの`templates/go.yml`ファイルでは、次のようになります:

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
          go_binary: ${{ steps.install_go.outputs.go_binary }} # go_binary set to the value of the go_binary output from the previous step
          fmt_packages: $[[ inputs.fmt_packages ]]             # fmt_packages set to the value of the component input fmt_packages
  ```

この例では、コンポーネントの作成者は、CI/CDコンポーネントのステップの複雑さを意識する必要がありません。

## トラブルシューティング {#troubleshooting}

### HTTPS URLからステップをフェッチする {#fetching-steps-from-an-https-url}

`tls: failed to verify certificate: x509: certificate signed by unknown authority`のようなエラーメッセージは、オペレーティングシステムがステップをホスティングしているサーバーを認識または信頼していないことを示します。

よくある原因は、信頼できるルート証明書がインストールされていないDockerイメージを使用して、ジョブでステップが実行されていることです。コンテナに証明書をインストールするか、ジョブ`image`に組み込むことで、問題を解決できます。

ステップをフェッチする前に、`script`ステップを使用してコンテナに依存関係をインストールできます。次に例を示します: 

```yaml
ubuntu_job:
  image: ubuntu:24.04
  run:
    - name: install_certs  # Install trusted certificates first
      script: apt update && apt install --assume-yes --no-install-recommends ca-certificates
    - name: echo_step      # With trusted certificates, use HTTPS without errors
      step: https://gitlab.com/user/my_steps/hello_world@main
```
