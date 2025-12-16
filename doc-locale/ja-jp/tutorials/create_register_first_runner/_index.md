---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: プロジェクトRunnerを自分で作成、登録、実行する'
---

<!-- vale gitlab_base.FutureTense = NO -->

このチュートリアルでは、GitLabで初めてのRunnerを設定して実行する方法について説明します。

Runnerは、GitLab CI/CDパイプラインでジョブを実行するGitLab Runnerアプリケーション内のエージェントです。ジョブは`.gitlab-ci.yml`ファイルで定義し、利用可能なRunnerに割り当てます。

GitLabには、次の3種類のRunnerがあります:

- 共有: GitLabインスタンス内のすべてのグループとプロジェクトで使用できます。
- グループ: グループ内のすべてのプロジェクトとサブグループで使用できます。
- プロジェクト: 特定のプロジェクトに関連付けます。通常、プロジェクトRunnerは、一度に1つのプロジェクトで使用します。

このチュートリアルでは、基本的なパイプライン設定で定義されたジョブを実行するプロジェクトRunnerを作成します:

1. [空のプロジェクトを作成する](#create-a-blank-project)
1. [プロジェクトパイプラインを作成する](#create-a-project-pipeline)。
1. [プロジェクトRunnerを作成して登録する](#create-and-register-a-project-runner)。
1. [パイプラインをトリガーしてRunnerを実行する](#trigger-a-pipeline-to-run-your-runner)。

## はじめる前 {#before-you-begin}

Runnerを作成、登録、実行する前に、ローカルコンピューターに[GitLab Runner](https://docs.gitlab.com/runner/install/)をインストールする必要があります。

## 空のプロジェクトを作成する {#create-a-blank-project}

まず、CI/CDパイプラインとRunnerを作成できる空のプロジェクトを作成します。

空のプロジェクトを作成するには: 

1. 左側のサイドバーの上部で、**新規作成**（{{< icon name="plus" >}}）を選択し、**新規プロジェクト/リポジトリ**を選択します。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このボタンは右上隅にあります。
1. **空のプロジェクトの作成**を選択します。
1. プロジェクトの詳細を入力します:
   - **プロジェクト名**フィールドに、プロジェクトの名前を入力します。名前は、小文字または大文字（`a-zA-Z`）、数字（`0-9`）、絵文字、またはアンダースコア（`_`）で始まる必要があります。ドット（`.`）、プラス記号（`+`）、ダッシュ（`-`）、またはスペースも使用できます。
   - **プロジェクトslug**フィールドに、プロジェクトへのパスを入力します。GitLabインスタンスは、このslugをプロジェクトへのURLパスとして使用します。slugを変更するには、最初にプロジェクト名を入力し、次にslugを変更します。
1. **プロジェクトを作成**を選択します。

## プロジェクトパイプラインを作成する {#create-a-project-pipeline}

次に、プロジェクトの`.gitlab-ci.yml`ファイルを作成します。これは、GitLab CI/CDに対する指示を指定するYAMLファイルです。

このファイルでは、以下を定義します:

- Runnerが実行するジョブの構造と順序。
- 特定の条件が発生した場合にRunnerが行う必要がある決定。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーに表示されます。
1. **Project overview**（プロジェクトの概要）を選択します。
1. プラスアイコン（{{< icon name="plus" >}}）を選択し、**新しいファイル**を選択します。
1. **ファイル名**フィールドに、`.gitlab-ci.yml`と入力します。
1. 大きなテキストボックスに、次のサンプル設定を貼り付けます:

   ```yaml
   stages:
     - build
     - test

   job_build:
     stage: build
     script:
       - echo "Building the project"

   job_test:
     stage: test
     script:
       - echo "Running tests"
   ```

   この設定には、Runnerが実行する2つのジョブ（buildジョブとtestジョブ）があります。
1. **変更をコミットする**を選択します。

## プロジェクトRunnerを作成して登録する {#create-and-register-a-project-runner}

次に、プロジェクトRunnerを作成して登録します。Runnerを登録してGitLabにリンクし、プロジェクトパイプラインからジョブを取得できるようにする必要があります。

プロジェクトRunnerを作成するには: 

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーに表示されます。
1. **設定** > **CI/CD**を選択します。
1. **Runners**セクションを展開します。
1. **New project runner**（新規プロジェクトRunner）を選択します。
1. オペレーティングシステムを選択します。
1. **タグ**セクションで、**Run untagged**（タグ付けされていないチェックボックスを実行）をオンにします。[タグ](../../ci/runners/configure_runners.md#control-jobs-that-a-runner-can-run)には、Runnerが実行できるジョブを指定します（オプション）。
1. **Runnerを作成**を選択します。
1. 画面の指示に従って、コマンドラインからRunnerを登録します。プロンプトが表示されたら、次の手順を実行します:
   - `executor`の場合、Runnerはホストコンピューター上で直接実行されるため、`shell`と入力します。[executor](https://docs.gitlab.com/runner/executors/)は、Runnerがジョブを実行する環境です。
   - `GitLab instance URL`の場合、GitLabインスタンスのURLを使用します。たとえば、`gitlab.example.com/yourname/yourproject`でプロジェクトがホストされている場合、GitLabインスタンスのURLは`https://gitlab.example.com`になります。プロジェクトがGitLab.comでホスティングされている場合、URLは`https://gitlab.com`になります。
1. Runnerを起動します:

   ```shell
   gitlab-runner run
   ```

### Runnerの設定ファイルを確認する {#check-the-runner-configuration-file}

Runnerを登録すると、設定とRunner認証トークンが`config.toml`に保存されます。Runnerは、ジョブキューからジョブを取得するときにトークンを使用してGitLabと認証を行います。

`config.toml`を使用すると、より[高度なRunner設定](https://docs.gitlab.com/runner/configuration/advanced-configuration.html)を定義できます。

Runnerを登録して起動すると、`config.toml`は次のようになるはずです:

```toml
[[runners]]
  name = "my-project-runner1"
  url = "http://127.0.0.1:3000"
  id = 38
  token = "glrt-TOKEN"
  token_obtained_at = 2023-07-05T08:56:33Z
  token_expires_at = 0001-01-01T00:00:00Z
  executor = "shell"
```

## パイプラインをトリガーしてRunnerを実行する {#trigger-a-pipeline-to-run-your-runner}

次に、プロジェクトでパイプラインをトリガーして、Runnerがジョブを実行するのを確認できるようにします。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーに表示されます。
1. **ビルド** > **パイプライン**を選択します。
1. **新しいパイプライン**を選択します。
1. ジョブログを表示するには、ジョブを選択します。出力は次の例のようになるはずです。これは、Runnerがジョブを正常に実行したことを示しています:

   ```shell
      Running with gitlab-runner 18.0.0 (d7f2cea7)
      on my-project-runner TOKEN, system ID: SYSTEM ID
      Preparing the "shell" executor
      00:00
      Using Shell (bash) executor...
      Preparing environment
      00:00
      /Users/username/.bash_profile: line 9: setopt: command not found
      Running on MACHINE-NAME...
      Getting source from Git repository
      00:01
      /Users/username/.bash_profile: line 9: setopt: command not found
      Fetching changes with git depth set to 20...
      Reinitialized existing Git repository in /Users/username/project-repository
      Checking out 7226fc70 as detached HEAD (ref is main)...
      Skipping object checkout, Git LFS is not installed for this repository.
      Consider installing it with 'git lfs install'.
      Skipping Git submodules setup
      Executing "step_script" stage of the job script
      00:00
      /Users/username/.bash_profile: line 9: setopt: command not found
      $ echo "Building the project"
      Building the project
      Job succeeded

   ```

これで、初めてのRunnerを作成、登録、実行できました。
