---
stage: Verify
group: CI Functions Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: CI/CDステップをセットアップする'
---

このチュートリアルでは、パイプラインでステップを作成および使用する方法について説明します。

ステップは、ジョブの再利用可能でコンポーザブルな要素です。各ステップでは、他のステップで使用できる構造化されたインプットと出力を定義します。ステップは、ローカルファイル、GitLab.comリポジトリ、またはその他のGitソースで設定できます。

このチュートリアルでは、GitLab CLI（`glab`）を使用して次の手順を実行します:

1. 「hello world」を出力するステップを作成します。
1. ステップを使用するようにパイプラインを設定します。
1. ジョブに複数のステップを追加します。
1. リモートステップを使用し、echoコマンドで出力をすべて表示します。

## はじめる前 {#before-you-begin}

- [GitLab CLI](../../editor_extensions/gitlab_cli/_index.md)（`glab`）をインストールしてサインインする必要があります。

## ステップを作成する {#create-a-step}

まず、次の項目を使用してステップを作成します:

- `exec`タイプ
- システムのexecutive APIによって開始される`command`

1. ネームスペースに`zero-to-steps`という名前のGitLabプロジェクトを作成します:

   ```shell
   glab project create zero-to-steps
   ```

1. プロジェクトリポジトリのルートに移動します:

   ```shell
   cd zero-to-steps
   ```

1. `step.yml`ファイルを作成します。

   ```shell
   touch step.yml
   ```

1. テキストエディタを使用して、`step.yml`に仕様を追加します:

   ```yaml
   spec:
     inputs:
       who:
         type: string
         default: world
   ```

   - `spec`には、`who`という名前のインプットが1つあります。
   - デフォルト値があるため、インプット`who`はオプションです。

1. `step.yml`に実装を追加するには、`spec`の後に、`exec`キーを指定した2番目のYAMLドキュメントを追加します:

   ```yaml
   spec:
     inputs:
       who:
         type: string
         default: world
   ---
   exec:
     command:
       - bash
       - -c
       - echo 'hello ${{inputs.who}}'
   ```

3連続のemダッシュ（`---`）は、ファイルを2つのYAMLドキュメントに区切るための記号です:

- 最初のドキュメントは仕様で、関数シグネチャのようなものです。
- 2番目のドキュメントは実装で、関数本体のようなものです。

`bash`と`-c`の引数はBash Shellを起動し、コマンドライン引数からスクリプトインプットを受け取ります。Shellスクリプトに加えて、`command`を使用して、`docker`や`terraform`などのプログラムを実行できます。

`echo 'hello ${{input.name}}'`引数には、`${{`と`}}`の内側に式が含まれています。式は可能な限り最後の瞬間に評価され、現在の実行コンテキストにアクセスできます。この式は`inputs`にアクセスし、`who`の値を読み取ります:

- 呼び出し元によって`who`が指定されている場合、その値が式に代入されます。
- `who`が省略されている場合、デフォルトの`world`が式に代入されます。

## ステップを使用するようにパイプラインを設定する {#configure-a-pipeline-to-use-the-step}

1. リポジトリのルートに、`.gitlab-ci.yml`ファイルを作成します:

   ```shell
   touch .gitlab-ci.yml
   ```

1. `.gitlab-ci.yml`で、次のジョブを追加します:

   ```yaml
   hello-world:
     run:
       - name: hello_world
         step: .
   ```

   - `run`キーワードには、ステップ呼び出しのリストがあります。
     - 各呼び出しには`name`が与えられるため、以降のステップで出力を参照できます。
     - 各呼び出しでは、実行する`step`を指定します。ローカル参照（`.`）は、リポジトリのルートを指します。

   このコードがリポジトリでどのように表示されるかの例については、[ステップのチュートリアル、パート1](https://gitlab.com/gitlab-org/step-runner/-/tree/main/examples/tutorial_part_1)を参照してください。

1. 両方のファイルをコミットし、プロジェクトリポジトリをプッシュします。これにより、ジョブを実行するパイプラインがトリガーされます:

   ```shell
   git add .
   git commit -m 'Part 1 complete'
   git push --set-upstream origin main
   glab ci status
   ```

1. パイプラインが完了するまで、「ログの表示」でジョブを追跡します。成功したジョブの例を次に示します:

   ```shell
   Step Runner version: a7c7c8fd
   See https://gitlab.com/gitlab-org/step-runner/-/blob/main/CHANGELOG.md for changes.
   ...
   hello world
   Cleaning up project directory and file based variables
   Job succeeded
   ```

これで、最初のステップを作成して使用できました。

## ジョブに複数のステップを追加する {#add-multiple-steps-to-a-job}

ジョブには複数のステップを含めることができます。

1. `.gitlab-ci.yml`ファイルで、`hello_steps`という別のステップをジョブに追加します:

   ```yaml
   hello-world:
     run:
       - name: hello_world
         step: .
       - name: hello_steps
         step: .
         inputs:
           who: gitlab steps
   ```

   この`hello_steps`ステップでは、`gitlab steps`に、デフォルトではないインプット`who`を指定しています。

   このコードがリポジトリでどのように表示されるかの例については、[ステップのチュートリアル、パート2a](https://gitlab.com/gitlab-org/step-runner/-/tree/main/examples/tutorial_part_2a)を参照してください。

1. 変更をコミットしてプッシュします:

   ```shell
   git commit -a -m 'Added another step'
   git push
   glab ci status
   ```

1. ターミナルで、**ログの表示**を選択し、完了するまでパイプラインを追跡します。成功した出力の例を次に示します:

   ```shell
   Step Runner version: a7c7c8fd
   See https://gitlab.com/gitlab-org/step-runner/-/blob/main/CHANGELOG.md for changes.
   ...
   hello world
   hello gitlab steps
   Cleaning up project directory and file based variables
   Job succeeded
   ```

## ステップをリファクタリングする {#refactor-your-step}

ステップをリファクタリングするには、ステップを`.gitlab-ci.yml`から専用ファイルに移動します:

1. 作成した最初のステップを`hello`というディレクトリに移動します:

   ```shell
   mkdir hello
   mv step.yml hello/
   ```

1. リポジトリのルートに新しいステップを作成します。

   ```shell
   touch step.yml
   ```

1. 次の設定を新しい`step.yml`に追加します:

   ```yaml
   spec:
   ---
   run:
     - name: hello_world
       step: ./hello
     - name: hello_steps
       step: ./hello
       inputs:
         who: gitlab steps
   ```

   この新しいステップにはインプットがないため、`spec`は空です。これは`steps`タイプで、`.gitlab-ci.yml`のステップと同じ構文です。ただし、ローカル参照は`hello`ディレクトリのステップを指しています。

1. 新しいステップを使用するには、`.gitlab-ci.yml`を変更します:

   ```yaml
   hello-world:
     run:
       - name: hello_everybody
         step: .
   ```

   これで、ジョブはインプットなしで新しいステップのみを呼び出します。ジョブの詳細を別のファイルにリファクタリングできました。

   このコードがリポジトリでどのように表示されるかの例については、[ステップのチュートリアル、パート2b](https://gitlab.com/gitlab-org/step-runner/-/tree/main/examples/tutorial_part_2b)を参照してください。

1. 変更をコミットしてプッシュします:

   ```shell
   git add .
   git commit -m 'Refactored step config'
   git push
   glab ci status
   ```

1. ターミナルで、**ログの表示**を選択します。
1. リファクタリングされたステップが最初に作成したステップと同じ関数を実行することを確認するには、ログ出力を表示します。ログ出力は、以前に作成したステップの出力と一致するはずです。次に例を示します:

   ```shell
   $ /step-runner ci
   hello world
   hello gitlab steps
   Cleaning up project directory and file based variables
   Job succeeded
   ```

### ステップに出力を追加する {#add-an-output-to-the-step}

`hello`ステップに出力を追加します。

1. `hello/step.yml`で、`outputs`構造を`spec`に追加します:

   ```yaml
   spec:
     inputs:
       who:
         type: string
         default: world
     outputs:
       greeting:
         type: string
   ---
   exec:
     command:
       - bash
       - -c
       - echo '{"name":"greeting","value":"hello ${{inputs.who}}"}' | tee ${{output_file}}
   ```

   - この`spec`では、デフォルトなしで1つの出力`greeting`を定義しました。デフォルトがないため、出力`greeting`が必要です。
   - 出力は、実行時に提供されるJSON Lines形式の`${{output_file}}`ファイルに書き込まれます。出力ファイルに書き込まれる各行は、2つのキー（`name`と`value`）を持つJSONオブジェクトである必要があります。
   - このステップは`echo '{"name":"greeting","value":"hello ${{inputs.who}}"}'`を実行し、出力をジョブログと出力ファイル（`tee ${{output_file}}`）に送信します。

1. `step.yml`で、ステップに出力を追加します:

   ```yaml
   spec:
     outputs:
       all_greetings:
         type: string
   ---
   run:
     - name: hello_world
       step: ./hello
     - name: hello_steps
       step: ./hello
       inputs:
         who: gitlab steps
   outputs:
     all_greetings: "${{steps.hello_world.outputs.greeting}} and ${{steps.hello_steps.outputs.greeting}}"
   ```

   これで、`all_greetings`という名前の出力をこのステップに追加できました。

   この出力は、式構文: `${{steps.hello_world.outputs.greeting}}`を示しています。`all_greetings`は、2つのサブステップ`hello_world`と`hello_steps`の出力を読み取ります。両方のサブステップの出力が連結されて、1つの文字列出力になります。

## リモートステップを使用する {#use-a-remote-step}

コードをコミットして実行する前に、ジョブに別のステップを追加して、メインの`step.yml`の最終的な`all_greetings`の出力を確認します。

このステップ呼び出しは、`echo-step`という名前のリモートステップを参照します。echoステップは、1つのインプット`echo`を受け取り、その値をログに出力し、`echo`として出力します。

1. `.gitlab-ci.yml`を編集します:

   ```yaml
   hello-world:
     run:
       - name: hello_everybody
         step: .
       - name: all_my_greetings
         step: gitlab.com/gitlab-org/ci-cd/runner-tools/echo-step@main
         inputs:
           echo: "all my greetings say ${{steps.hello_everybody.outputs.all_greetings}}"
   ```

   このコードがリポジトリでどのように表示されるかの例については、[ステップのチュートリアル、パート2c](https://gitlab.com/gitlab-org/step-runner/-/tree/main/examples/tutorial_part_2c)を参照してください。

1. 変更をコミットしてプッシュします:

   ```shell
   git commit -a -m 'Added outputs'
   git push
   glab ci status
   ```

1. パイプラインが完了するまで、「ログの表示」でジョブを追跡します。成功した出力の例を次に示します:

   ```shell
   Step Runner version: a7c7c8fd
   See https://gitlab.com/gitlab-org/step-runner/-/blob/main/CHANGELOG.md for changes.
   ...
   {"name":"greeting","value":"hello world"}
   {"name":"greeting","value":"hello gitlab steps"}
   all my greetings say hello world and hello gitlab steps
   Cleaning up project directory and file based variables
   Job succeeded
   ```

以上です。パイプラインでステップを作成し、実装できました。ステップの構文の詳細については、[CI/CDステップ](../../ci/steps/_index.md)を参照してください。
