---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CDステップ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- 状態: 実験的機能

{{< /details >}}

ステップはジョブの再利用可能なユニットです。組み合わせると、GitLab CI/CDジョブで使用される`script`が置き換えられます。ステップを使用する必要はありません。ただし、ステップには再利用性、構成可能性、テスト可能性、独立性があることから、CI/CDパイプラインの理解と保守が容易になります。

まず、[ステップのチュートリアルのセットアップ](../../tutorials/setup_steps/_index.md)をお試しください。独自のステップの作成を開始するには、[独自のステップを作成する](#create-your-own-step)を参照してください。パイプラインがCI/CDコンポーネントとCI/CDステップの両方を使用するとどのようにメリットがあるのかを理解するには、[CI/CDコンポーネントとCI/CDステップを組み合わせる](#combine-cicd-components-and-cicd-steps)を参照してください。

この実験的機能はまだ活発に開発されています。したがって、破壊的な変更が発生する可能性が常にあります。破壊的な変更の詳細については、[変更履歴](https://gitlab.com/gitlab-org/step-runner/-/blob/main/CHANGELOG.md)を確認してください。

## ステップワークフロー

ステップは、一連のステップを実行するか、コマンドを実行します。各ステップは入出力(インプット/アウトプット)を指定し、CI/CDジョブ変数、環境変数、およびファイルシステムやネットワーク構築などのリソースにアクセスできます。ステップは、ファイルシステム、GitLab.comリポジトリ、またはその他のGitソースでローカルにホストされます。

さらに、ステップは、

- ステップチームによって作成されたDockerコンテナで実行されます。[`Dockerfile`](https://gitlab.com/gitlab-org/step-runner/-/blob/main/Dockerfile)を確認できます。[エピック15073](https://gitlab.com/groups/gitlab-org/-/epics/15073)に従って、ステップがCI/CDジョブによって定義された環境内でいつ実行されるかを追跡します。
- Linuxに固有です。[エピック15074](https://gitlab.com/groups/gitlab-org/-/epics/15074)に従って、ステップが複数のオペレーティングシステムをサポートする時期を追跡します。

たとえば、このジョブは[`run`](../yaml/_index.md#run)CI/CDキーワードを使用して次のステップを実行します。

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

このジョブを実行すると、メッセージ`hello, Sally`がジョブログに出力されます。echoステップの定義は次のとおりです。

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

## CI/CDステップを使用する

`run`キーワードを使用して、CIステップを使用するようにGitLab CI/CDジョブを設定します。CI/CDステップを実行している場合、ジョブで`before_script`、`after_script`、または`script`を使用することはできません。

`run`キーワードは、実行するステップのリストを受け入れます。ステップは、リストで定義されている順に1つずつ実行されます。各リスト項目には`name`と、`step`、`script`、または`action`のいずれかがあります。

名前は英数字とアンダースコアのみで構成する必要があります。ただし、数字で始めてはなりません。

### ステップを実行する

`step`キーワードを使用して、[ステップの場所](#step-location)を指定してステップを実行します。

ステップには、インプットと環境変数を渡すことができます。そして、これらには値をインターポレーションする式を含めることができます。ステップは、`CI_BUILDS_DIR`[定義済み変数](../variables/predefined_variables.md)によって定義されたディレクトリで実行されます。

たとえば、Gitリポジトリ`gitlab.com/components/echo`からロードされたechoステップは、次のように環境変数`USER: Fred`とインプット`message: hello Sally`を受け取ります。

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

### スクリプトを実行する

`script`キーワードを使用して、Shellでスクリプトを実行します。`env`を使用してスクリプトに渡される環境変数は、Shellに設定されます。スクリプトステップは、`CI_BUILDS_DIR`[定義済み変数](../variables/predefined_variables.md)によって定義されたディレクトリで実行されます。

たとえば、次のスクリプトは、GitLabユーザーをジョブログに出力します。

```yaml
my-job:
  run:
    - name: say_hi
      script: echo hello ${{job.GITLAB_USER_LOGIN}}
```

スクリプトステップは常に`bash`Shellを使用します。[イシュー109](https://gitlab.com/gitlab-org/step-runner/-/issues/109)に従って、Shellフォールバックがサポートされる時期を追跡します。

### GitHubアクションを実行する

`action`キーワードを使用してGitHubアクションを実行します。インプットと環境変数はアクションに直接渡され、アクションの出力はステップ出力として返されます。アクションステップは、`CI_PROJECT_DIR`[定義済み変数](../variables/predefined_variables.md)によって定義されたディレクトリで実行されます。

アクションの実行には、`dind`サービスが必要です。詳細については、[Dockerを使用してDockerイメージをビルドする](../docker/using_docker_build.md)を参照してください。

たとえば、次のステップでは`action`を使用して`yq`を使用できるようにします。

```yaml
my-job:
  run:
    - name: say_hi_again
      action: mikefarah/yq@master
      inputs:
        cmd: echo ["hi ${{job.GITLAB_USER_LOGIN}} again!"] | yq .[0]
```

#### 既知の問題

GitLabで実行されているアクションは、アーティファクトの直接アップロードをサポートしていません。アーティファクトは、ファイルシステムとキャッシュに書き込み、既存の [`artifacts`キーワード](../yaml/_index.md#artifacts)および[`cache`キーワード](../yaml/_index.md#cache)で選択する必要があります。

### ステップの場所

ステップは、ファイルシステムの相対パス、GitLab.comリポジトリ、またはその他のGitソースからロードされます。

#### ファイルシステムからステップをロードする

フルストップ`.`で始まる相対パスを使用して、ファイルシステムからステップをロードします。パスによって参照されるフォルダーには、`step.yml`ステップ定義ファイルが含まれている必要があります。パスセパレータは、オペレーティングシステムに関係なく、常にフォワードスラッシュ`/`を使用する必要があります。

次に例を示します。

```yaml
- name: my-step
  step: ./path/to/my-step
```

#### Gitリポジトリからステップをロードする

URLとリポジトリのリビジョン(コミット、ブランチ、またはタグ)を指定して、Gitリポジトリからステップをロードします。リポジトリの`steps`フォルダー内のステップの相対ディレクトリとファイル名を指定することもできます。ディレクトリを指定せずにURLを指定すると、`step.yml`が`steps`フォルダーからロードされます。

次に例を示します。

- ブランチでステップを指定します。

  ```yaml
  job:
    run:
      - name: specifying_a_branch
        step: gitlab.com/components/echo@main
  ```

- タグでステップを指定します。

  ```yaml
  job:
    run:
      - name: specifying_a_tag
        step: gitlab.com/components/echo@v1.0.0
  ```

- リポジトリ内のディレクトリ、ファイル名、およびGitコミットでステップを指定します。

  ```yaml
  job:
    run:
      - name: specifying_a_directory_file_and_commit_within_the_repository
        step: gitlab.com/components/echo/-/reverse/my-step.yml@3c63f399ace12061db4b8b9a29f522f41a3d7f25
  ```

`steps`フォルダー外のフォルダーまたはファイルを指定するには、拡張された`step`構文を使用します。

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

ステップは、注釈付きタグを使用してGitリポジトリを参照できません。[イシュー123](https://gitlab.com/gitlab-org/step-runner/-/issues/123)に従って、注釈付きタグがサポートされる時期を追跡します。

### 式

式は、二重中括弧`${{ }}`で囲まれたミニ言語です。式は、ジョブ環境でのステップ実行の直前に評価され、以下で使用できます。

- インプット値
- 環境変数の値
- ステップの場所URL
- 実行可能コマンド
- 実行可能作業ディレクトリ
- 一連のステップでの出力
- `script`ステップ
- `action`ステップ

式は、次の変数を参照できます。

| 変数                    | 例                                                       | 説明 |
|:----------------------------|:--------------------------------------------------------------|:------------|
| `env`                       | `${{env.HOME}}`                                               | 実行環境または前のステップで設定された環境変数にアクセスします。 |
| `export_file`               | `echo '{"name":"NAME","value":"Fred"}' >${{export_file}}`     | [エクスポートファイル](#export-an-environment-variable)へのパス。このファイルに書き込んで、後続の実行ステップで使用するために環境変数をエクスポートします。 |
| `inputs`                    | `${{inputs.message}}`                                         | ステップのインプットにアクセスします。 |
| `job`                       | `${{job.GITLAB_USER_NAME}}`                                   | `CI_`、`DOCKER_`、または `GITLAB_` で始まるものに限定されたGitLab CI/CD変数にアクセスします。 |
| `output_file`               | `echo '{"name":"meaning_life","value":42}' >${{output_file}}` | [出力ファイル](#return-an-output)へのパス。このファイルに書き込んで、ステップから出力変数を設定します。 |
| `step_dir`                  | `work_dir: ${{step_dir}}`                                     | ステップがダウンロードされたディレクトリ。ステップ内のファイルを参照したり、実行可能なステップの作業ディレクトリを設定したりするために使用します。 |
| `steps.[step_name].outputs` | `${{steps.my_step.outputs.name}}`                             | 以前に実行されたステップからの[出力](#specify-outputs)にアクセスします。ステップ名を使用して特定のステップを選択します。 |
| `work_dir`                  | `${{work_dir}}`                                               | 実行中のステップの作業ディレクトリ。 |

式は、二重角括弧(`$[[ ]]`)を使用し、ジョブの生成中に評価されるテンプレート補間とは異なります。

式は、`CI_`、`DOCKER_`、または`GITLAB_`で始まる名前のCI/CDジョブ変数にのみアクセスできます。[エピック15073](https://gitlab.com/groups/gitlab-org/-/epics/15073)に従って、ステップがすべてのCI/CDジョブ変数にアクセスできる時期を追跡します。

### 前のステップの出力を使用する

ステップインプットは、ステップ名と出力変数名を参照することにより、前のステップからの出力を参照できます。

たとえば、`gitlab.com/components/random-string`ステップが`random_value`という名前の出力変数を定義した場合、次のようになります。

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

### 環境変数

ステップでは、[設定](#set-environment-variables)環境変数、[エクスポート](#export-an-environment-variable)環境変数を設定でき、環境変数は、`step`、`script`、または`action`を使用するときに渡すことができます。

環境変数の優先順位は、優先順位の高い順から低い順に、次によって変数が設定されます。

1. `step.yml`の`env`キーワードの使用
1. 一連のステップでステップに渡される`env`キーワードの使用
1. シーケンス内のすべてのステップに対する`env`キーワードの使用
1. 以前に実行されたステップが`${{export_file}}`に書き込まれた場所
1. Runner
1. コンテナ

## 独自のステップを作成する

独自のステップを作成するには、次のタスクを実行します。

1. CI/CDジョブの実行時にアクセス可能なファイルシステムのGitLabプロジェクト、Gitリポジトリ、またはディレクトリを作成します。
1. `step.yml`ファイルを作成し、プロジェクト、リポジトリ、またはディレクトリのルートフォルダーに配置します。
1. `step.yml`のステップの[仕様](#the-step-specification)を定義します。
1. `step.yml`のステップの[定義](#the-step-definition)を定義します。
1. ステップが使用するファイルをプロジェクト、リポジトリ、またはディレクトリに追加します。

ステップを作成したら、[ジョブでステップを使用](#run-a-step)できます。

### ステップ仕様

ステップ仕様は、ステップ`step.yml`に含まれる2つのドキュメントのうちの1つです。仕様は、ステップが受信および返すインプットと出力(アウトプット)を定義します。

#### インプットを指定する

インプット名には英数字とアンダースコアのみを使用できます。ただし、数字で始めてはなりません。インプットには型が必要で、オプションでデフォルト値を指定できます。デフォルト値のないインプットは必須インプットであり、ステップを使用するときに指定する必要があります。

インプットは、次のいずれかの型である必要があります。

| 型      | 例                 | 説明 |
|:----------|:------------------------|:------------|
| `array`   | `["a","b"]`             | 型指定されていない項目のリスト。 |
| `boolean` | `true`                  | TrueまたはFalse。 |
| `number`  | `56.77`                 | 64ビット浮動小数点数。 |
| `string`  | `"brown cow"`           | テキスト。       |
| `struct`  | `{"k1":"v1","k2":"v2"}` | 構造化されたコンテンツ。 |

たとえば、ステップが`string`型の`greeting`というオプションのインプットを受け入れるように指定するには、次にようにします。

```yaml
spec:
  inputs:
    greeting:
      type: string
      default: "hello, world"
---
```

ステップを使用するときにインプットを提供するには、次のようにします。

```yaml
run:
  - name: my_step
    step: ./my-step
    inputs:
      greeting: "hello, another world"
```

#### 出力を指定する

インプットと同様に、出力名には英数字とアンダースコアのみを使用できます。ただし、数字で始めてはなりません。出力には型が必要であり、オプションでデフォルト値を指定できます。ステップが出力を返さない場合、デフォルト値が返されます。

出力は、次のいずれかの型である必要があります。

| 型         | 例                 | 説明 |
|:-------------|:------------------------|:------------|
| `array`      | `["a","b"]`             | 型指定されていない項目のリスト。 |
| `boolean`    | `true`                  | TrueまたはFalse。 |
| `number`     | `56.77`                 | 64ビット浮動小数点数。 |
| `string`     | `"brown cow"`           | テキスト。       |
| `struct`     | `{"k1":"v1","k2":"v2"}` | 構造化されたコンテンツ。 |

たとえば、ステップが`number`型の`value`という名前の出力を返すことを指定するには、次のようにします。

```yaml
spec:
  outputs:
    value:
      type: number
---
```

ステップを用いたときに出力を使用するには、次のようにします。

```yaml
run:
  - name: random_generator
    step: ./random-generator
  - name: echo_number
    step: ./echo
    inputs:
      message: "Random number generated was ${{step.random-generator.outputs.value}}"
```

#### 委任された出力を指定する

出力名と型を指定する代わりに、出力をサブステップに完全に委任できます。サブステップによって返される出力は、ステップによって返されます。ステップ定義の`delegate`キーワードは、ステップによって返されるサブステップ出力を決定します。

たとえば、次のステップでは、`random-generator`によって返される出力が返されます。

```yaml
spec:
  outputs: delegate
---
run:
  - name: random_generator
    step: ./random-generator
delegate: random-generator
```

#### インプットまたは出力を指定しない

ステップでは、インプットが必要ない場合や、出力を返さない場合があります。これは、ステップがディスクに書き込むか、環境変数を設定するか、STDOUTに出力する場合にのみ発生する可能性があります。この場合、`spec:`は次のように空になります。

```yaml
spec:
---
```

### ステップ定義

手順は次のとおりです。

- 環境変数を設定する
- コマンドを実行する
- 一連の他のステップを実行する

#### 環境変数を設定する

`env`キーワードを使用して環境変数を設定します。環境変数名には英数字とアンダースコアのみを使用できます。ただし、数字で始めてはなりません。

環境変数は、実行可能なコマンド、または一連のステップを実行する場合はすべてのステップで使用できます。次に例を示します。

```yaml
spec:
---
env:
  FIRST_NAME: Sally
  LAST_NAME: Seashells
run:
  # omitted for brevity
```

ステップは、Runner環境からの環境変数のサブセットにのみアクセスできます。[エピック15073](https://gitlab.com/groups/gitlab-org/-/epics/15073)に従って、ステップがすべての環境変数にアクセスできる時期を追跡します。

#### コマンドを実行する

ステップは、`exec`キーワードを使用してコマンドを実行することを宣言します。コマンドは指定する必要がありますが、作業ディレクトリ(`work_dir`)はオプションです。ステップによって設定された環境変数は、実行中のプロセスで使用できます。

たとえば、次のステップでは、ステップディレクトリをジョブログに出力します。

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

実行ステップに必要な依存関係も、ステップによってインストールする必要があります。たとえば、ステップが`go`を呼び出す場合は、最初にインストールする必要があります。

{{< /alert >}}

##### 出力を返す

実行可能ステップは、JSON Line形式で`${{output_file}}`に行を追加することにより、出力を返します。各行は、`name`と`value`のキーペアを持つJSONオブジェクトです。`name`は文字列で、`value`は次のステップ仕様の出力型に一致する型である必要があります。

| ステップ仕様の型 | 予期されるJSONL値の型 |
|:------------------------|:--------------------------|
| `array`                 | `array`                   |
| `boolean`               | `boolean`                 |
| `number`                | `number`                  |
| `string`                | `string`                  |
| `struct`                | `object`                  |

たとえば、`string`値`Range Rover`で`car`という名前の出力を返すには、次のようになります。

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

##### 環境変数をエクスポートする

実行可能ステップは、JSON Line形式で`${{export_file}}`に行を追加することにより、環境変数をエクスポートします。各行は、`name`と`value`のキーペアを持つJSONオブジェクトです。`name`と`value`はどちらも文字列である必要があります。

たとえば、変数`GOPATH`を値`/go`に設定するには、次のようになります。

```yaml
spec:
---
exec:
  command:
    - bash
    - -c
    - echo '{"name":"GOPATH","value":"/go"}' >${{export_file}}
```

#### 一連のステップを実行する

ステップは、`steps`キーワードを使用して一連のステップを実行することを宣言します。ステップは、リストで定義された順に1つずつ実行されます。この構文は、`run`キーワードと同じです。

ステップの名前は、英数字とアンダースコアのみで構成されます。ただし、数字で始まってはなりません。

たとえば、このステップではGoをインストールしてから、Goがすでにインストールされていることを前提とする2番目のステップを実行します。

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

##### 出力を返す

出力は、`outputs`キーワードを使用して、一連のステップから返されます。出力内の値の型は、ステップ仕様の出力の型と一致する必要があります。

たとえば、次のステップでは、インストールされているJavaのバージョンを出力として返します。これは、`install_java`ステップが`java_version`という名前の出力を返すことを前提としています。

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

または、サブステップのすべての出力を`delegate`キーワードを使用して返すことができます。次に例を示します。

```yaml
spec:
  outputs: delegate
---
run:
  - name: install_java
    step: ./common/install-java
delegate: install_java
```

## CI/CDコンポーネントとCI/CDステップを組み合わせる

[CI/CDコンポーネント](../components/_index.md)は、再利用可能な単一のパイプライン設定ユニットです。パイプラインの作成時にパイプラインに組み込まれ、ジョブと設定がパイプラインに追加されます。コンポーネントプロジェクトの共通スクリプトやプログラムなどのファイルは、CI/CDジョブから参照できません。

CI/CDステップは、ジョブの再利用可能なユニットです。ジョブの実行時に、参照されているステップが実行環境またはイメージにダウンロードされ、ステップに含まれている追加ファイルも一緒に取り込まれます。ステップの実行は、ジョブの`script`を置き換えます。

コンポーネントとステップは、CI/CDパイプラインのソリューションを作成するために連携して機能します。ステップは、ジョブの構成方法の複雑さを処理し、ジョブの実行に必要なファイルを自動的に取得します。コンポーネントは、ジョブ設定をインポートする方法を提供しますが、基盤となるジョブ構成をユーザーから隠します。

ステップとコンポーネントでは、式に異なる構文を使用して、式の種類を区別します。コンポーネント式は角かっこ`$[[ ]]`を使用し、パイプラインの作成時に評価されます。ステップ式は中かっこ`${{ }}`を使用し、ステップの実行直前にジョブの実行時に評価されます。

たとえば、プロジェクトでは、Goコードをフォーマットするジョブを追加するコンポーネントを使用できます。

- プロジェクトの`.gitlab-ci.yml`ファイル内は次のようになります。

  ```yaml
  include:
  - component: gitlab.com/my-components/go@main
    inputs:
      fmt_packages: "./..."
  ```

- 内部的には、コンポーネントはCI/CDステップを使用してジョブを構成します。これにより、Goをインストールし、フォーマッターを実行します。コンポーネントの`templates/go.yml`ファイル内は次のようになります。

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

この例では、CI/CDコンポーネントは、コンポーネント作成者からステップの複雑さを隠しています。
