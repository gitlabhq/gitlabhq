---
stage: Verify
group: CI Functions Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Function
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- ステータス: 実験的機能

{{< /details >}}

GitLab Functionは、GitLab CI/CDジョブ内の`script`を置き換える、再利用可能なCI/CDジョブロジックのユニットを提供します。

> [!note]
> GitLab Functionは、現在積極的に開発中の実験的機能であり、破壊的変更がある可能性があります。詳細については、[変更履歴](https://gitlab.com/gitlab-org/step-runner/-/blob/main/CHANGELOG.md)をご確認ください。

## なぜFunctionを使用するのか {#why-functions}

パイプラインが肥大化すると、`script`ブロックの保守が困難になります。ロジックはジョブ間で重複し、スクリプトはランタイム時に外部ソースからフェッチされ、小さな変更でも多くの場所で更新が必要になります。GitLab Functionは、これらの問題を解決するために設計されています。

Functionのメリットは以下のとおりです:

- Functionは自己完結型でバージョン管理されます。Functionは、ロジック、サポートスクリプトまたはバイナリ、およびそのインプットとアウトプットを記述する仕様をパッケージ化したOCIイメージです。ステップが実行されると、GitLabはFunctionを自動的にフェッチします。ジョブの開始時にスクリプトをフェッチしたり、外部依存関係を手動で管理したりする必要はありません。特定のバージョンタグでFunctionを参照すると、毎回その正確なバージョンが取得されます。

- Functionは、ジョブやプロジェクトを越えて再利用できます。OCIレジストリにFunctionを公開すると、各リポジトリでスクリプトファイルをコピーして維持することなく、すべてのジョブが単一の`func`参照でそれを利用できます。

- Functionはデータフローを明示的にします。`script`ブロックでは、Shell変数を介してコマンド間で値が渡されます。これらは任意の順序で設定、上書き、または読み取りが可能です。`run`リストでは、各ステップがインプットとアウトプットを宣言し、ステップは既に実行されたステップからのアウトプットのみにアクセスできます。

- Functionは独立してテスト可能です。ファンクションではインプットとアウトプットが定義されているため、パイプライン全体を実行することなく、単独で実行してテストできます。

- Function実行はクロスプラットフォームで信頼性があります。専用のエージェントが、ネットワーク経由で送信されたスクリプトを解釈する代わりに、ビルドホスト上でFunctionの実行を管理します。これにより、Functionは適切なプロセス制御、クロスプラットフォームの一貫性、および再開可能なジョブの基盤を得ることができます。これらの機能は、Shellスクリプトだけでは達成が困難または不可能です。

既存のShellスクリプトを再利用するには、`script`ステップを使用して、移行する間、それらを`run`リストで直接実行します。すべてを一度に変換することなく、Functionを使用できます。

## Functionを理解する {#understand-functions}

従来のCI/CDジョブでは、`script`キーワードにはShellコマンドのリストが含まれています。ジョブがすべてのステップを所有し、ロジックは結果を達成する方法を正確に記述するYAMLに直接存在します。パイプラインが肥大化すると、このアプローチはプロジェクトを越えて再利用、テスト、共有することが困難になります。

GitLab Functionでは、`run`キーワードを使用してステップのリストを宣言します。各ステップは実装を含むFunctionを参照し、ジョブは、どのようにではなく何が起こるべきかを記述します。ロジックはFunctionに存在し、YAMLには存在しません。

以下は、JavaScriptプロジェクトの従来の`.gitlab-ci.yml`の例です:

```yaml
build_and_release:
  script:
    - npm run lint
    - npm test
    - npm run bundle
    - BUNDLE_PATH=$(find dist -name '*.js' | head -1)
    - npm run minify -- --input $BUNDLE_PATH
    - npm run deploy -- --artifact $MINIFIED_PATH --env production
```

GitLab Functionで記述された同じパイプライン:

```yaml
build_and_release:
  run:
    - name: validate
      func: registry.gitlab.com/js/validate:1.0.0
    - name: release
      func: registry.gitlab.com/js/release:1.0.0
      inputs:
        environment: production
```

各ジョブは、ステップを介して何が起こるべきかを宣言します。Function自体が実装を含んでいます。

## GitLab Function用語集 {#gitlab-functions-glossary}

この用語集は、GitLab Functionに関連する用語の定義を提供します。

Function: CI/CDロジックの再利用可能な自己完結型パッケージ。Functionには、プラットフォーム固有のコンパイル済みコード、そのインプットとアウトプットを定義する仕様、およびそのFunctionが何を行うかを記述する定義が含まれています。このFunctionはコマンドを実行したり、他のFunctionを構成したりできます。

ステップ: `run`リスト内のFunctionの単一の呼び出し。ステップには、名前、Function参照、提供されるインプット、およびその呼び出しに対して設定される環境変数が含まれます。

インプット: Functionをステップとして実行する際に、そのFunctionに渡す名前付きの値。インプットは、型とオプションのデフォルト値を伴うFunction仕様で宣言されます。

アウトプット: Functionが実行された後に返す名前付きの値。アウトプットはFunction仕様で宣言され、実行中にアウトプットファイルに書き込まれます。

環境変数: 実行時にFunctionで利用できる変数。環境変数は、オペレーティングシステムプロセスの環境、Runner、Function定義、ステップの実行、またはそれらをエクスポートした以前に実行されたFunctionから取得できます。

## CI/CDステップからの名称変更 {#rename-from-cicd-steps}

GitLab Functionは以前、CI/CDステップと呼ばれていました。そのFunctionと構文は名称変更されました。

| 旧                                       | 新規                           |
|:------------------------------------------|:------------------------------|
| CI/CDステップ                               | GitLab Function              |
| `step:`（非推奨）                      | `func:`                       |
| `step.yml`（非推奨）                   | `func.yml`                    |
| `${{ step_dir }}`（非推奨）            | `${{ func_dir }}`             |
| `${{ job.<variable_name> }}`（非推奨） | `${{ vars.<variable_name> }}` |

## コンポーネントとFunction {#components-and-functions}

コンポーネントとFunctionは、パイプラインの異なるレベルで動作し、異なる問題を解決します。

[CI/CDコンポーネント](../components/_index.md)は、パイプラインレベルで再利用可能です。GitLabは、ジョブが実行される前にコンポーネントを含め、ジョブ、パイプラインステージ、および設定をパイプラインにコントリビュートします。コンポーネントは、パイプラインにどのようなジョブが存在するかを記述します。

GitLab Functionはジョブレベルで再利用可能です。それらはジョブ内で実行され、`script`を置き換えます。

コンポーネントとFunctionは異なるレベルで動作し、互いにうまく補完し合います。コンポーネントはジョブを定義し、内部でFunctionを使用してそれを実装できます。コンポーネントを含めると、動作を知らなくても完全に設定されたジョブが得られます。コンポーネントの作成者は、Functionを使用して、ジョブが実行する処理の複雑さに対応します。

### 式の構文 {#expression-syntax}

コンポーネントとFunctionは、評価されるタイミングが異なるため、異なる式の構文を使用します:

- `$[[ ]]`式は、ジョブが実行される前のパイプライン作成中に評価されます。この構文は、[CI/CDインプット](../inputs/_index.md)およびコンポーネントインプットに使用します。
- `${{ }}`式は、各ステップが実行される直前のジョブ実行中に評価されます。この構文は、Functionのインプット、環境変数、およびランタイム状態に依存する値に使用します。

どちらの構文も、CI/CDコンポーネントYAML設定ファイルに表示できます:

```yaml
spec:
  inputs:
    go_version:
      default: "1.22"
---

my-format-job:
  run:
    - name: install_go
      func: ./languages/go/install
      inputs:
        version: $[[ inputs.go_version ]]                      # resolved at pipeline creation
    - name: format
      func: ./languages/go/go-fmt
      inputs:
        go_binary: ${{ steps.install_go.outputs.go_binary }}   # resolved during job execution
```

## Function実行モデル {#function-execution-model}

Functionは、インプットを受け入れ、アウトプットを返し、環境変数をエクスポートできる自己完結型パッケージです。Functionは、インスタンスがホストマシンであろうとコンテナであろうと、CIジョブの環境で実行されます。Functionは、ローカルのファイルシステム、OCIレジストリ、またはGitリポジトリでホストできます。

`run`リスト内の各ステップは順次実行されます。ステップは、共有Shell状態ではなく、インプット、アウトプット、およびエクスポートされた環境変数を介して互いに通信します。

あるステップからのアウトプットは、`${{ steps.<step-name>.outputs.<output-name> }}`式を介して後続のステップで利用できます。ステップによってエクスポートされた環境変数は、すべての後続のステップで利用できます。アウトプットと環境変数の両方は、ステップが完了した後にのみ利用可能になります。

Runnerが`run`リストを持つジョブをピックアップすると、ステップRunnerを実行して実行を管理します。リスト内の各ステップについて、ステップRunnerは次のようにします:

1. Function参照を解決し、ファイルシステム、OCIリポジトリ、またはGitリポジトリからFunctionパッケージをフェッチします。
1. ステップのインプットおよび環境変数内の式を評価します。
1. Functionを実行し、解決されたインプットと環境を渡します。
1. Functionが書き込んだすべてのアウトプットファイルへのアウトプットを読み取り、後続のステップで利用できるようにします。
1. Functionがエクスポートしたすべての環境変数を読み取り、グローバル環境に追加します。
1. 次のステップに進むか、ステップが失敗した場合は停止します。

## Functionの要件 {#function-requirements}

Functionを使用するには、使用するRunner executorにステップRunnerをインストールする必要がある場合があります。詳細については、[ステップRunnerを手動でインストール](https://docs.gitlab.com/runner/install/step-runner/)を参照してください。

## Functionを使用する {#use-functions}

`run`キーワードを使用して、Functionを使用するようにGitLab CI/CDジョブを設定します。Functionを実行する場合、ジョブで`before_script`、`after_script`、または`script`を使用することはできません。

### ステップでFunctionを実行する {#run-a-function-with-a-step}

`run`キーワードは、実行するステップのリストを受け入れます。ステップは、リストで定義されている順に1つずつ実行されます。各ステップには`name`、`func`または`script`、そしてオプションで`inputs`と`env`があります。

名前は英数字とアンダースコアのみで構成され、数字で始めることはできません。

#### Functionを実行する {#invoke-a-function}

ステップは、`func`キーワードとともに[Function参照](#function-reference)を提供することでFunctionを実行できます。`inputs`キーワードでFunctionにインプットを渡し、`env`キーワードで環境値をオーバーライドします。`func`の値、および`inputs`と`env`のキーと値に[式](#expressions)を使用します。

実行されたFunctionが作業ディレクトリをオーバーライドしない限り、Functionは`CI_PROJECT_DIR`ディレクトリで実行されます。

たとえば、以下のecho Functionを実行すると、メッセージ`Hi Sally!`がジョブログに出力されます。

```yaml
my-job:
  variables:
    FRIEND: "Sally"
  run:
    - name: say_hi
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1
      inputs:
        message: "Hi ${{ vars.FRIEND }}!"
```

#### スクリプトを実行する {#run-a-script}

ステップは、`script`キーワードを使用してスクリプトを実行することができます。`env`を使用してスクリプトに渡される環境変数は、Shellに設定されます。スクリプトステップは`bash` Shellを使用し、bashが見つからない場合は`sh`にフォールバックします。`script`の値、および`env`のキーと値に[式](#expressions)を使用できます。スクリプトステップは`CI_PROJECT_DIR`ディレクトリで実行されます。

Functionと並行してカスタム処理が必要な場合は、スクリプトステップを使用してください。内部的に、FunctionはスクリプトをFunctionの実行に変換し、スクリプトをインプットとして渡します。

たとえば、次のスクリプトステップはメッセージ`Hi Sally!`をジョブログにアウトプットします:

```yaml
my-job:
  variables:
    FRIEND: "Sally"
  run:
    - name: say_hi
      script: echo 'Hi ${{ vars.FRIEND }}!'
```

### Function参照 {#function-reference}

Functionは、ファイルシステムまたはOCIリポジトリから読み込まれます。Gitリポジトリからの読み込みはサポートされていますが、非推奨です。

#### OCIリポジトリから読み込む {#load-from-an-oci-repository}

{{< history >}}

- [GitLab Runner](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/6351) 18.9で導入されました。

{{< /history >}}

OCIリポジトリからFunctionを読み込むには、レジストリ、リポジトリ、およびバージョン（タグ）を指定します。この方法は、Functionを配布および使用する推奨される方法です。

Function OCIイメージは、複数のプラットフォームをサポートします。ステップRunnerは、実行中のプラットフォームと一致するイメージをダウンロードします。一致が見つからない場合、ステップは失敗します。

```yaml
# prints 'Hi from GitLab Functions'
my-job:
  run:
    - name: echo
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1
      inputs:
        message: "Hi from GitLab Functions"
```

Functionがルートにない場合は、イメージ内のサブディレクトリとファイル名も指定できます:

```yaml
# prints 'snoitcnuF baLtiG morf iH'
my-job:
  run:
    - name: echo
      func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1 reverse/func.yml
      inputs:
        message: "Hi from GitLab Functions"
```

プライベートOCIリポジトリに認証するには、`DOCKER_AUTH_CONFIG`環境変数をDocker設定ファイル形式の値で設定します。Functionとしての認証の動作例については、[Docker Auth](https://gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/docker-auth) Functionを参照してください。

#### ファイルシステムから読み込む {#load-from-the-file-system}

相対パスを使用してファイルシステムからFunctionを読み込むには、Function参照を`.`で始めます。パスは、呼び出し元のFunctionのディレクトリに対する相対パスです。ジョブからFunctionを直接呼び出す場合、パスは`CI_PROJECT_DIR`に対する相対パスです。

ファイルシステムから絶対パスを使用してFunctionを読み込むには、Function参照を`/`で始めます。

ステップが実行されると、そのパスがFunctionディレクトリになります。Function定義のYAMLがこのディレクトリに存在する必要があります。オプションで、Function定義YAMLファイル名が標準でない場合は、それを提供します。

パスセパレータは、オペレーティングシステムに関わらず、フォワードスラッシュ`/`を使用する必要があります。

例: 

- 相対ディレクトリからの読み込み:

  ```yaml
  - name: my_step
    func: ./path/to/my-function
  ```

- 絶対ディレクトリからの読み込み:

  ```yaml
  - name: my_step
    func: /opt/gitlab-functions/my-function
  ```

- カスタムFunction定義ファイルを使用して読み込む:

  ```yaml
  - name: my_step
    func: ./funcs/release/dry-run.yml
  ```

#### Gitリポジトリから読み込む（非推奨） {#load-from-a-git-repository-deprecated}

> [!warning]
> GitLabは、将来のリリースでGitリポジトリからのFunctionの読み込みのサポートを削除する予定です。代わりにOCIリポジトリからFunctionを読み込んでください。

GitリポジトリからFunctionを読み込むには、リポジトリのURLとリビジョン（コミット、ブランチ、またはタグ）を指定します。リポジトリに認証するには、URLにユーザー名とパスワードを追加します。

`func`でGit形式のFunction参照をテキストとして提供する場合、Functionは`steps`サブディレクトリに存在する必要があります。長形式のGit形式のFunction参照である`git`を使用する場合、Functionは`dir`ディレクトリに存在する必要があります。

Gitリポジトリには、コンパイルされたコードではなく、ソースが含まれています。可能な場合は、OCIリポジトリからFunctionを読み込んでください。

例: 

- タグを使用してFunctionを指定します:

  ```yaml
  - name: my_step
    func: gitlab.com/funcs/my-git-repo@v1.0.0
  ```

- ブランチを使用してFunctionを指定します:

  ```yaml
  - name: my_step
    func: gitlab.com/funcs/my-git-repo@main
  ```

- ディレクトリ、ファイル名、Gitコミットを指定してFunctionを指定します:

  ```yaml
  - name: my_step
    func: gitlab.com/funcs/my-git-repo/-/reverse/my-func.yml@3c63f399ace12061db4b8b9a29f522f41a3d7f25
  ```

- フェッチ時にGitに認証する:

  ```yaml
  - name: my_step
    func: gitlab-ci-token:${{ vars.CI_JOB_TOKEN }}@gitlab.com/funcs/my-git-repo@v2.0.0
  ```

`steps`フォルダーの外にあるディレクトリまたはファイルを指定するには、展開された`func`構文を使用します:

```yaml
my-job:
  run:
    - name: my_step
      func:
        git:
          url: gitlab.com/funcs/my-git-repo
          rev: main
          dir: my-functions/sub-directory  # optional, defaults to the repository root
          file: my-func.yml                # optional, defaults to `func.yml`
```

### 式 {#expressions}

ジョブが実行されるまで不明な値（以前のステップからのアウトプット、ジョブ変数、またはコンピューティングされた値など）が必要な場合は、式を使用します。

式は`${{ }}`構文を使用し、各Functionが実行される前に評価されます。演算子、データ構造、および組み込みFunctionを含む式言語の完全なリファレンスについては、[Moa式言語](moa.md)を参照してください。

式は以下で使用できます:

- インプット値（`inputs`）
- 環境変数値（`env`）
- Function参照（`func`）
- スクリプトコンテンツ（`script`）

#### 利用可能なコンテキスト {#available-context}

GitLab Functionを使用する際は、以下のコンテキスト変数を使用します。完全なコンテキスト参照については、[Moa式言語](moa.md#context-reference)を参照してください。

| 変数                                  | タイプ   | 説明                                                                                                                                                                                                   |
|:------------------------------------------|:-------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `env.<name>`                              | 文字列 | Functionが実行される際の環境。OS、Runner、および以前に実行されたステップによってエクスポートされた環境変数が含まれます。`env`にはCI/CDジョブ変数は含まれません。 |
| `vars.<name>`                             | 文字列 | Runnerから渡されるCI/CDジョブ変数。`env`とは異なり、この変数はステップのエクスポートの影響を受けません。                                                                                                      |
| `inputs.<name>`                           | 任意    | 現在のFunctionに渡されるインプット値。                                                                                                                                                              |
| `steps.<step_name>.outputs.<output_name>` | 任意    | 現在の`run`リスト内の以前に完了したステップからのアウトプット値。                                                                                                                                     |
| `func_dir`                                | 文字列 | Functionの定義ファイルを含むディレクトリへのパス。Functionにバンドルされたファイルを参照するために使用します。                                                                                            |
| `work_dir`                                | 文字列 | 現在の実行の作業ディレクトリへのパス。                                                                                                                                                      |

#### 例 {#examples}

- 以前のステップからのアウトプットを参照:

  ```yaml
  my-job:
    run:
      - name: generate_rand
        func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/random:1
      - name: echo
        func: registry.gitlab.com/gitlab-org/ci-cd/runner-tools/gitlab-functions-examples/echo:1
        inputs:
          message: "The random value is: ${{ steps.generate_rand.outputs.random_value }}"
  ```

- ジョブ変数をフォールバックデフォルト値とともに使用:

  ```yaml
  run:
    - name: deploy
      func: ./deploy
      inputs:
        environment: ${{ vars.CI_COMMIT_REF_NAME == "main" && "production" || "staging" }}
  ```

### 環境変数 {#environment-variables}

環境変数は2つの方法でステップ間を移動します。`env`で設定するか、Functionを介してエクスポートします。スコープが異なるため、この違いが重要です。

CI/CDジョブ変数は、環境変数として利用できません。代わりに`${{ vars.<name> }}`を使用してジョブ変数にアクセスします。

#### ステップの環境変数を設定する {#set-environment-variables-for-a-step}

ステップで`env`キーワードを使用して、そのステップとそれが内部的に呼び出すすべてのFunctionの環境変数を設定します。`env`で設定された変数は、環境にすでに存在するすべての変数に加えて、そのステップで利用できます。変数がすでに存在する場合、`env`によって設定された値が優先されます。この方法で設定された変数は、同じ`run`リスト内の後続のステップでは利用できません。

```yaml
run:
  - name: build
    func: ./build
    env:
      BUILD_TARGET: release   # available to build and its child steps only
  - name: test
    func: ./test              # BUILD_TARGET is not available here
```

`env`のキーと値に[式](#expressions)を使用します。

#### エクスポートされた環境変数 {#exported-environment-variables}

Functionが`${{ export_file }}`に書き込むと、書き込まれた変数は`run`リスト内のすべての後続のステップにエクスポートされます。Functionは、この方法を使用して後のステップと状態を共有します。

エクスポートされた変数は、式の`env`を介して利用できます:

```yaml
run:
  - name: setup
    func: ./setup             # exports INSTALL_PATH during execution
  - name: build
    func: ./build
    inputs:
      path: ${{ env.INSTALL_PATH }}   # available because setup exported it
```

#### 優先順位 {#precedence}

同じ変数が複数の場所で設定されている場合、以下の順序が最高位から最低位に適用されます:

1. Function定義（`func.yml`）で設定された`env`
1. `run`リスト内のステップで設定された`env`
1. 以前に実行されたステップによってエクスポートされる。
1. Runnerによって設定される。
1. OSプロセス環境によって設定される。

## 独自のFunctionを作成する {#create-your-own-function}

Functionを作成するには、[GitLab Functionを作成する](create.md)を参照してください。

Functionの例については、[GitLab Functionの例](examples.md)を参照してください。

## トラブルシューティング {#troubleshooting}

### HTTPS URLからFunctionをフェッチする {#fetch-functions-from-an-https-url}

`tls: failed to verify certificate: x509: certificate signed by unknown authority`のようなエラーメッセージは、オペレーティングシステムがFunctionをホスティングしているサーバーを認識または信頼していないことを示します。

一般的な原因は、信頼されたルート証明書がインストールされていないDockerイメージです。コンテナに証明書をインストールするか、ジョブ`image`に組み込むことで、問題を解決できます。

`script`ステップを使用して、Functionをフェッチする前に依存関係をインストールできます:

```yaml
ubuntu_job:
  image: ubuntu:24.04
  run:
    - name: install_certs
      script: apt update && apt install --assume-yes --no-install-recommends ca-certificates
    - name: echo_step
      func: registry.gitlab.com/user/my_functions/hello_world:1.0.0
```
