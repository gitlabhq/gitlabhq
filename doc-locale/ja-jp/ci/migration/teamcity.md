---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: TeamCityから移行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

TeamCityからGitLab CI/CDへ移行する場合は、TeamCityのワークフローをレプリケートし、強化するCI/CDパイプラインを作成できます。

## 主な類似点と相違点 {#key-similarities-and-differences}

GitLab CI/CDとTeamCityは、いくつかの類似点があるCI/CDツールです。GitLabとTeamCityはどちらも:

- ほとんどの言語のジョブを実行できる十分な柔軟性があります。
- オンプレミスまたはクラウドにデプロイできます。

さらに、両者にはいくつかの重要な違いがあります:

- GitLab CI/CDパイプラインはYAML形式の設定ファイルで設定され、手動で編集することも、[パイプラインエディタ](../pipeline_editor/_index.md)で編集することもできます。TeamCityのパイプラインは、UIまたはKotlin DSLを使用して設定できます。
- GitLabは、SCM、コンテナレジストリ、セキュリティスキャンなどを内蔵したDevSecOpsプラットフォームです。TeamCityでは、これらの機能のために通常インテグレーションによって提供される個別のソリューションが必要です。

### 設定ファイル {#configuration-file}

TeamCityは[UIから設定](https://www.jetbrains.com/help/teamcity/creating-and-editing-build-configurations.html)するか、Kotlin DSL形式の[`Teamcity Configuration`ファイル](https://www.jetbrains.com/help/teamcity/kotlin-dsl.html)で設定できます。TeamCityのビルド設定は、ソフトウェアプロジェクトをどのようにビルドし、テストし、デプロイするかを定義する一連の指示です。その設定には、TeamCityでのCI/CDプロセスを自動化するために必要なパラメータと設定が含まれます。

GitLabでは、TeamCityのビルド設定に相当するものが`.gitlab-ci.yml`ファイルです。このファイルはプロジェクトのCI/CDパイプラインを定義し、プロジェクトをビルド、テスト、デプロイするために必要なステージ、ジョブ、およびコマンドを指定します。

## 機能と概念の比較 {#comparison-of-features-and-concepts}

多くのTeamCityの機能と概念には、GitLabに同じ機能を提供する同等のものがあります。

### ジョブ {#jobs}

TeamCityはビルド設定を使用します。これは複数のビルドステップで構成されており、コードのコンパイル、テストの実行、アーティファクトのパック化などのタスクを実行するコマンドやスクリプトを定義します。

以下は、Dockerファイルをビルドすると単体テストを実行するKotlin DSL形式のTeamCityプロジェクト設定の例です:

```kotlin
package _Self.buildTypes

import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.dockerCommand
import jetbrains.buildServer.configs.kotlin.buildSteps.nodeJS
import jetbrains.buildServer.configs.kotlin.triggers.vcs

object BuildTest : BuildType({
    name = "Build & Test"

    vcs {
        root(HttpsGitlabComRutshahCicdDemoGitRefsHeadsMain)
    }

    steps {
        dockerCommand {
            id = "DockerCommand"
            commandType = build {
                source = file {
                    path = "Dockerfile"
                }
            }
        }
        nodeJS {
            id = "nodejs_runner"
            workingDir = "app"
            shellScript = """
                npm install jest-teamcity --no-save
                npm run test -- --reporters=jest-teamcity
            """.trimIndent()
        }
    }

    triggers {
        vcs {
        }
    }

    features {
        perfmon {
        }
    }
})
```

GitLab CI/CDでは、パイプラインの一部として実行するタスクとともにジョブを定義します。各ジョブには、1つ以上のビルドステップを定義できます。

前の例に相当するGitLab CI/CDの`.gitlab-ci.yml`ファイルは次のようになります:

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_BRANCH != "main" || $CI_PIPELINE_SOURCE != "merge_request_event"
      when: never
    - when: always

stages:
  - build
  - test

build-job:
  image: docker:20.10.16
  stage: build
  services:
    - docker:20.10.16-dind
  script:
    - docker build -t cicd-demo:0.1 .

run_unit_tests:
  image: node:17-alpine3.14
  stage: test
  before_script:
    - cd app
    - npm install
  script:
    - npm test
  artifacts:
    when: always
    reports:
      junit: app/junit.xml
```

### パイプライントリガー {#pipeline-triggers}

[TeamCity Triggers](https://www.jetbrains.com/help/teamcity/configuring-build-triggers.html)は、VCSの変更、スケジュールされたトリガー、または他のビルドによってトリガーされたビルドなど、ビルドを開始する条件を定義します。

GitLab CI/CDでは、ブランチやマージリクエストの変更、新しいタグなどのさまざまなイベントに対してパイプラインを自動的にトリガーできます。パイプラインは、[API](../triggers/_index.md)を使用するか、[スケジュールされたパイプライン](../pipelines/schedules.md)を使用して手動でトリガーすることもできます。詳細については、[CI/CDパイプライン](../pipelines/_index.md)を参照してください。

### 変数 {#variables}

TeamCityでは、ビルド設定の設定で[ビルドパラメータと環境変数を定義](https://www.jetbrains.com/help/teamcity/using-build-parameters.html)します。

GitLabでは、`variables`キーワードを使用して[CI/CD変数](../variables/_index.md)を定義します。変数を使用して、設定データを再利用したり、より動的な設定を行ったり、重要な値を保存したりできます。変数は、グローバルまたはジョブごとに定義できます。

例えば、変数を使用するGitLab CI/CDの`.gitlab-ci.yml`ファイルは次のとおりです:

```yaml
default:
  image: alpine:latest

stages:
  - greet

variables:
  NAME: "Fern"

english:
  stage: greet
  variables:
    GREETING: "Hello"
  script:
    - echo "$GREETING $NAME"

spanish:
  stage: greet
  variables:
    GREETING: "Hola"
  script:
    - echo "$GREETING $NAME"
```

### アーティファクト {#artifacts}

TeamCityのビルド設定では、ビルドプロセス中に生成される[アーティファクト](https://www.jetbrains.com/help/teamcity/build-artifact.html)を定義できます。

GitLabでは、任意のジョブで[`artifacts`キーワード](../yaml/_index.md#artifacts)を使用して、ジョブの完了時に保存されるアーティファクトのセットを定義できます。[アーティファクト](../jobs/job_artifacts.md)は、後のジョブでテストやデプロイのために使用できるファイルです。

例えば、アーティファクトを使用するGitLab CI/CDの`.gitlab-ci.yml`ファイルは次のとおりです:

```yaml
stage:
  - generate
  - use

generate_cat:
  stage: generate
  script:
    - touch cat.txt
    - echo "meow" > cat.txt
  artifacts:
    paths:
      - cat.txt
    expire_in: 1 week

use_cat:
  stage: use
  script:
    - cat cat.txt
```

### Runner {#runners}

GitLabにおける[TeamCityエージェント](https://www.jetbrains.com/help/teamcity/build-agent.html)に相当するものはRunnerです。

GitLab CI/CDでは、Runnerはジョブを実行するサービスです。GitLab.comを使用している場合は、[Runnerフリート](../runners/_index.md)を使用して、独自のセルフマネージドRunnerをプロビジョニングすることなくジョブを実行できます。

Runnerに関するいくつかの重要な詳細:

- Runnerは、インスタンス全体、グループ全体で共有するように[設定](../runners/runners_scope.md)したり、単一のプロジェクトに専用にしたりできます。
- より詳細な制御のために[`tags`キーワード](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)を使用し、Runnerを特定のジョブに関連付けることができます。例えば、専用の、より強力な、または特定のハードウェアを必要とするジョブには、タグを使用できます。
- GitLabには、[Runner](https://docs.gitlab.com/runner/runner_autoscale/)のオートスケール機能があります。オートスケールを使用して、必要なときにのみRunnerをプロビジョニングし、不要なときにスケールダウンします。

### TeamCityのビルド機能とプラグイン {#teamcity-build-features--plugins}

ビルド機能とプラグインを通じて有効になるTeamCityの一部の機能は、CI/CDキーワードと機能によってGitLab CI/CDでネイティブにサポートされています。

| TeamCityプラグイン                                                                                                                    | GitLab機能 |
|------------------------------------------------------------------------------------------------------------------------------------|----------------|
| [コードカバレッジ](https://www.jetbrains.com/help/teamcity/configuring-test-reports-and-code-coverage.html#Code+Coverage+in+TeamCity) | [コードカバレッジ](../testing/code_coverage/_index.md)と[テストカバレッジの可視化](../testing/code_coverage/_index.md#coverage-visualization) |
| [単体テストレポート](https://www.jetbrains.com/help/teamcity/configuring-test-reports-and-code-coverage.html)                        | [JUnitテストレポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportsjunit)と[単体テストレポート](../testing/unit_test_reports.md) |
| [通知](https://www.jetbrains.com/help/teamcity/configuring-notifications.html)                                            | [通知メール](../../user/profile/notifications.md)と[Slack](../../user/project/integrations/gitlab_slack_application.md) |

## 移行の計画と実行 {#planning-and-performing-a-migration}

以下のおすすめのステップのリストは、GitLab CI/CDへの移行を迅速に完了できた組織を観察した後に作成されました。

### 移行計画を作成する {#create-a-migration-plan}

移行を開始する前に、移行の準備をするために[移行計画](plan_a_migration.md)を作成する必要があります。

TeamCityからの移行に備えて、以下の質問を自問してください:

- 現在、TeamCityのジョブではどのようなプラグインが使用されていますか？
  - これらのプラグインが具体的に何をするか知っていますか？
- TeamCityのエージェントには何がインストールされていますか？
- 共有ライブラリは使用されていますか？
- TeamCityからどのように認証していますか？SSHキー、APIトークン、またはその他のシークレットを使用していますか？
- パイプラインからアクセスする必要がある他のプロジェクトはありますか？
- 外部サービスにアクセスするための認証情報がTeamCityにありますか？例えば、Ansible Tower、Artifactory、または他のクラウドプロバイダーやデプロイターゲットなどですか？

### 前提条件 {#prerequisites}

移行作業を行う前に、まず次のことを行う必要があります:

1. GitLabに慣れる。
   - [主要なGitLab CI/CD機能](../_index.md)について読んでください。
   - チュートリアルに従って、[最初のGitLabパイプライン](../quick_start/_index.md)と、静的サイトをビルド、テスト、デプロイする[より複雑なパイプライン](../quick_start/tutorial.md)を作成してください。
   - [CI/CD YAML構文](../yaml/_index.md)リファレンスを確認してください。
1. GitLabをセットアップして設定します。
1. GitLabインスタンスをテストします。
   - 共有GitLab.comRunnerを使用するか、新しいRunnerをインストールして、[Runner](../runners/_index.md)が利用可能であることを確認します。

### 移行ステップ {#migration-steps}

1. プロジェクトをSCMソリューションからGitLabに移行します。
   - （推奨）利用可能な[インポーター](../../user/import/_index.md)を使用して、外部SCMプロバイダーからの大量のインポートを自動化できます。
   - [URLでリポジトリをインポート](../../user/project/import/repo_by_url.md)できます。
1. 各プロジェクトで`.gitlab-ci.yml`ファイルを作成します。
1. TeamCityの設定をGitLab CI/CDジョブに移行し、マージリクエストで結果を直接表示するように設定します。
1. [クラウドデプロイメントテンプレート](../cloud_deployment/_index.md) 、[環境](../environments/_index.md) 、および[Kubernetes向けGitLabエージェント](../../user/clusters/agent/_index.md)を使用して、デプロイメントジョブを移行します。
1. 異なるプロジェクト間で再利用できるCI/CD設定があるかどうかを確認し、[CI/CDテンプレート](../examples/_index.md#cicd-templates)または[CI/CDコンポーネント](../components/_index.md)を作成して共有します。
1. GitLab CI/CDパイプラインをより速く、より効率的にする方法については、[パイプラインの効率性](../pipelines/pipeline_efficiency.md)を参照してください。

ここで回答されていない質問がある場合は、[GitLabコミュニティフォーラム](https://forum.gitlab.com/)が役立つリソースとなります。
