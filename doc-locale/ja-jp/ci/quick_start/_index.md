---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: 初めてのGitLab CI/CDパイプラインを作成して実行する'
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

このチュートリアルでは、GitLabで初めてのCI/CDパイプラインを設定し、実行する方法を説明します。

すでに[CI/CDの基本的な概念](../_index.md)を理解している場合は、[チュートリアル: 複雑なパイプラインを作成する:](tutorial.md)で一般的なキーワードについて確認できます。

## 前提要件 {#prerequisites}

始める前に、以下を確認してください:

- CI/CDを使用するプロジェクトがGitLabにある。
- プロジェクトのメンテナーまたはオーナーのロールを持っている。

プロジェクトがない場合は、<https://gitlab.com>で公開プロジェクトを無料で作成できます。

## ステップ {#steps}

初めてのパイプラインを作成して実行するには:

1. ジョブを実行するための[Runnerが利用可能であることを確認します](#ensure-you-have-runners-available)。

   GitLab.comを使用している場合は、この手順を省略できます。GitLab.comでは、インスタンスRunnerが提供されています。

1. リポジトリのルートに[`.gitlab-ci.yml`ファイルを作成](#create-a-gitlab-ciyml-file)します。このファイルでCI/CDジョブを定義します。

このファイルをリポジトリにコミットすると、Runnerがジョブを実行します。ジョブの結果は[パイプラインに表示](#view-the-status-of-your-pipeline-and-jobs)されます。

## Runnerが利用可能であることを確認する {#ensure-you-have-runners-available}

GitLabでは、RunnerはCI/CDジョブを実行するエージェントです。

GitLab.comを使用している場合は、この手順を省略できます。GitLab.comでは、インスタンスRunnerが提供されています。

利用可能なRunnerを確認するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **設定** > **CI/CD**を選択します。
1. **Runners**を展開します。

アクティブなRunner（横に緑色の丸印が表示されているもの）が1つ以上あれば、ジョブを処理できるRunnerが利用可能です。

これらの設定にアクセスできない場合は、GitLab管理者に連絡してください。

### Runnerがない場合 {#if-you-dont-have-a-runner}

Runnerがない場合:

1. ローカルマシンに[GitLab Runnerをインストール](https://docs.gitlab.com/runner/install/)します。
1. プロジェクトに[Runnerを登録](https://docs.gitlab.com/runner/register/)します。`shell` executorを選択します。

後の手順でCI/CDジョブを実行すると、ジョブはローカルマシン上で実行されます。

## `.gitlab-ci.yml`ファイルを作成する {#create-a-gitlab-ciyml-file}

次に、`.gitlab-ci.yml`ファイルを作成します。これは、GitLab CI/CDに対する指示を指定する[YAML](https://en.wikipedia.org/wiki/YAML)ファイルです。

このファイルでは、以下を定義します:

- Runnerが実行するジョブの構造と順序。
- 特定の条件が発生した場合にRunnerが下すべき決定。

プロジェクトで`.gitlab-ci.yml`ファイルを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。[新しいナビゲーションをオン](../../user/interface_redesign.md#turn-new-navigation-on-or-off)にしている場合、このフィールドは上部のバーにあります。
1. **コード** > **リポジトリ**を選択します。
1. ファイルリストの上部で、コミット先のブランチを選択します。不明な場合は、`master`または`main`のままにします。次に、プラスアイコン（{{< icon name="plus" >}}）を選択し、**新しいファイル**を選択します:

   ![現在のフォルダーにファイルを作成するための新しいファイルボタン](img/new_file_v13_6.png)

1. **ファイル名**に`.gitlab-ci.yml`と入力し、大きい方のウィンドウに次のサンプルコードを貼り付けます:

   ```yaml
   build-job:
     stage: build
     script:
       - echo "Hello, $GITLAB_USER_LOGIN!"

   test-job1:
     stage: test
     script:
       - echo "This job tests something"

   test-job2:
     stage: test
     script:
       - echo "This job tests something, but takes more time than test-job1."
       - echo "After the echo commands complete, it runs the sleep command for 20 seconds"
       - echo "which simulates a test that runs 20 seconds longer than test-job1"
       - sleep 20

   deploy-prod:
     stage: deploy
     script:
       - echo "This job deploys something from the $CI_COMMIT_BRANCH branch."
     environment: production
   ```

   この例は、`build-job`、`test-job1`、`test-job2`、`deploy-prod`の4つのジョブを示しています。`echo`コマンドに記載されているコメントは、ジョブを表示する際にUI上に表示されます。[定義済み変数](../variables/predefined_variables.md)`$GITLAB_USER_LOGIN`と`$CI_COMMIT_BRANCH`の値は、ジョブの実行時に入力されます。

1. **変更をコミットする**を選択します。

パイプラインが起動し、`.gitlab-ci.yml`ファイルで定義したジョブが実行されます。

## パイプラインとジョブのステータスを表示する {#view-the-status-of-your-pipeline-and-jobs}

パイプラインとその中のジョブを確認してみましょう。

1. **ビルド** > **パイプライン**に移動します。3つのステージで構成されるパイプラインが表示されるはずです:

   ![パイプラインリストは、3つのステージで構成される実行中のパイプラインを示しています](img/three_stages_v13_6.png)

1. パイプラインIDを選択すると、パイプラインを視覚的に確認できます:

   ![パイプライングラフは、すべてのステージの各ジョブ、そのステータス、依存関係を示しています](img/pipeline_graph_v17_9.png)

1. ジョブ名を選択すると、ジョブの詳細を確認できます。たとえば、`deploy-prod`を選択します:

   ![ジョブ詳細ページは、現在のステータス、タイミング情報、ログの出力を示しています](img/job_details_v13_6.png)

GitLabで初めてのCI/CDパイプラインを作成できました。おつかれさまでした。

これで、`.gitlab-ci.yml`をカスタマイズして、より高度なジョブを定義できます。

## `.gitlab-ci.yml`の活用ヒント {#gitlab-ciyml-tips}

`.gitlab-ci.yml`ファイルを使いこなすためのヒントを以下に示します。

`.gitlab-ci.yml`の完全な構文については、[CI/CD YAML構文リファレンス](../yaml/_index.md)を参照してください。

- [パイプラインエディタ](../pipeline_editor/_index.md)を使用して、`.gitlab-ci.yml`ファイルを編集できます。
- 各ジョブにはスクリプトセクションがあり、各ジョブはステージに属しています:
  - [`stage`](../yaml/_index.md#stage)は、ジョブの順次実行を示します。Runnerが利用可能な場合、同じステージ内のジョブは並列実行されます。
  - [`needs`キーワード](../yaml/_index.md#needs)を使用して[ステージの順序に関係なくジョブを実行](../yaml/needs.md)して、パイプラインのスピードと効率性を高めることができます。
- ジョブとステージの実行方法をカスタマイズする追加設定が可能です:
  - [`rules`キーワード](../yaml/_index.md#rules)を使用して、ジョブを実行するかスキップするかの条件を指定できます。`only`および`except`のレガシーキーワードは引き続きサポートされていますが、同じジョブで`rules`と併用することはできません。
  - パイプラインのジョブとステージ間で情報を永続的に保持するには、[`cache`](../yaml/_index.md#cache)と[`artifacts`](../yaml/_index.md#artifacts)を使用します。各ジョブに一時的なRunnerを使用する場合でも、これらのキーワードを使用して依存関係とジョブの出力を保存できます。
  - [`default`キーワード](../yaml/_index.md#default)を使用して、すべてのジョブに適用される追加設定を指定できます。このキーワードは、すべてのジョブで実行される[`before_script`](../yaml/_index.md#before_script)セクションと[`after_script`](../yaml/_index.md#after_script)セクションを定義する際によく使用されます。

## 関連トピック {#related-topics}

移行元:

- [Bamboo](../migration/bamboo.md)
- [CircleCI](../migration/circleci.md)
- [GitHub Actions](../migration/github_actions.md)
- [Jenkins](../migration/jenkins.md)
- [TeamCity](../migration/teamcity.md)

動画:

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [First time GitLab & CI/CD](https://www.youtube.com/watch?v=kTNfi5z6Uvk&t=553s)（初めてのGitLab & CI/CD）: GitLabの簡単な概要、CI/CDの最初のステップ、Goプロジェクトのビルド、テストの実行、CI/CDパイプラインエディタの使用、シークレットやセキュリティの脆弱性の検出、非同期練習用の演習が含まれています。
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Intro to GitLab CI](https://www.youtube.com/watch?v=l5705U8s_nQ&t=358s)（GitLab CI入門）: このワークショップでは、Web IDEを使用してCI/CDによるソースコードのビルドと単体テストの実行を迅速に開始する方法を説明します。
