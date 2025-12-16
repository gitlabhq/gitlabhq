---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: TeamCityから移行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

TeamCityからGitLab CI/CDに移行する場合、TeamCityのワークフローをレプリケートして強化するCI/CDパイプラインを作成できます。

## 主な類似点と相違点 {#key-similarities-and-differences}

GitLab CI/CDとTeamCityは、いくつかの類似点があるCI/CDツールです。GitLabとTeamCityの両方:

- ほとんどの言語のジョブを実行できる柔軟性があります。
- オンプレミスまたはクラウドにデプロイできます。

さらに、両者にはいくつかの重要な違いがあります:

- GitLab CI/CDパイプラインは、YAML形式の設定ファイルで設定されており、手動または[パイプラインエディタ](../pipeline_editor/_index.md)で編集できます。TeamCityパイプラインは、UIまたはKotlin DSLを使用して設定できます。
- GitLabは、組み込みのSCM、コンテナレジストリ、セキュリティスキャンなどを備えたDevSecOpsプラットフォームです。TeamCityにはこれらの機能に対応する個別のソリューションが必要で、通常はインテグレーションによって提供されます。

### 設定ファイル {#configuration-file}

TeamCityは、[UIから設定する](https://www.jetbrains.com/help/teamcity/creating-and-editing-build-configurations.html)か、Kotlin DSL形式の[`Teamcity Configuration`ファイルで設定できます](https://www.jetbrains.com/help/teamcity/kotlin-dsl.html)。TeamCityのビルド設定は、ソフトウェアプロジェクトをビルド、テスト、およびデプロイする方法を定義する一連の指示です。この設定には、TeamCityでCI/CDプロセスを自動化するために必要なパラメータと設定が含まれています。

GitLabでは、TeamCityのビルド設定に相当するのは`.gitlab-ci.yml`ファイルです。このファイルは、プロジェクトのCI/CDパイプラインを定義し、プロジェクトのビルド、テスト、およびデプロイに必要なステージ、ジョブ、およびコマンドを指定します。

## 機能と概念の比較 {#comparison-of-features-and-concepts}

多くのTeamCityの機能と概念には、同じ機能を提供するGitLabの同等の機能があります。

### ジョブ {#jobs}

TeamCityは、コードのコンパイル、テストの実行、アーティファクトのパッケージ化などのタスクを実行するためのコマンドまたはスクリプトを定義する複数のビルドステップで構成されるビルド設定を使用します。

次に、Dockerファイルをビルドし、単体テストを実行するKotlin DSL形式のTeamCityプロジェクト設定の例を示します:

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

GitLab CI/CDでは、パイプラインの一部として実行するタスクを使用してジョブを定義します。各ジョブには、定義された1つ以上のビルドステップを含めることができます。

前の例に対応するGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

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

### パイプラインのトリガー {#pipeline-triggers}

[TeamCityトリガー](https://www.jetbrains.com/help/teamcity/configuring-build-triggers.html)は、VCSの変更、スケジュールされたトリガー、または他のビルドによってトリガーされるビルドなど、ビルドを開始する条件を定義します。

GitLab CI/CDでは、ブランチまたはマージリクエストへの変更や新しいタグ付けなど、さまざまなイベントに対してパイプラインを自動的にトリガーできます。パイプラインは、[API](../triggers/_index.md)を使用するか、[スケジュールされたパイプライン](../pipelines/schedules.md)を使用して、手動でトリガーすることもできます。詳細については、[CI/CDパイプライン](../pipelines/_index.md)を参照してください。

### 変数 {#variables}

TeamCityでは、[ビルドパラメータと環境変数を定義する](https://www.jetbrains.com/help/teamcity/using-build-parameters.html)ビルド設定設定にあります。

GitLabでは、`variables`キーワードを使用して[CI/CD変数](../variables/_index.md)を定義します。変数を使用して、設定データを再利用したり、より動的な設定にしたり、重要な値を格納したりします。変数は、グローバルまたはジョブごとに定義できます。

たとえば、変数を使用するGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

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

TeamCityのビルド設定を使用すると、ビルドプロセス中に生成された[アーティファクト](https://www.jetbrains.com/help/teamcity/build-artifact.html)を定義できます。

GitLabでは、どのジョブも[`artifacts`キーワード](../yaml/_index.md#artifacts)を使用して、ジョブの完了時に保存する一連のアーティファクトを定義できます。[アーティファクト](../jobs/job_artifacts.md)は、後のジョブ、テスト、またはデプロイで使用できるファイルです。

たとえば、アーティファクトを使用するGitLab CI/CD `.gitlab-ci.yml`ファイルは次のようになります:

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

GitLabの[TeamCityエージェント](https://www.jetbrains.com/help/teamcity/build-agent.html)に相当するのはRunnerです。

GitLab CI/CDでは、Runnerはジョブを実行するサービスです。GitLab.comを使用している場合は、独自のセルフマネージドRunnerをプロビジョニングせずにジョブを実行するために[インスタンスRunnerフリート](../runners/_index.md)を使用できます。

Runnerに関する主な詳細は次のとおりです:

- Runnerは、[インスタンス、グループ、または単一のプロジェクト専用に共有されるように設定できます](../runners/runners_scope.md)。
- より細かく制御するには、[`tags`キーワード](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)を使用し、Runnerを特定のジョブに関連付けることができます。たとえば、専用、より強力、または特定のハードウェアを必要とするジョブにタグを使用できます。
- GitLabには[Runnerのオートスケール](https://docs.gitlab.com/runner/runner_autoscale/)があります。オートスケールを使用して、必要な場合にのみRunnerをプロビジョニングし、不要な場合はスケールダウンします。

### TeamCityビルド機能とプラグイン {#teamcity-build-features--plugins}

ビルド機能とプラグインを介して有効になるTeamCityの一部の機能は、CI/CDキーワードと機能を備えたGitLab CI/CDでネイティブにサポートされています。

| TeamCityプラグイン                                                                                                                    | GitLabの機能 |
|------------------------------------------------------------------------------------------------------------------------------------|----------------|
| [コードカバレッジ](https://www.jetbrains.com/help/teamcity/configuring-test-reports-and-code-coverage.html#Code+Coverage+in+TeamCity) | [コードカバレッジ](../testing/code_coverage/_index.md)と[テストカバレッジの可視化](../testing/code_coverage/_index.md#coverage-visualization) |
| [単体テストレポート](https://www.jetbrains.com/help/teamcity/configuring-test-reports-and-code-coverage.html)                        | [JUnitレポートアーティファクト](../yaml/artifacts_reports.md#artifactsreportsjunit)と[単体テストレポート](../testing/unit_test_reports.md) |
| [通知](https://www.jetbrains.com/help/teamcity/configuring-notifications.html)                                            | [通知メール](../../user/profile/notifications.md)と[Slack](../../user/project/integrations/gitlab_slack_application.md) |

## 移行の計画と実行 {#planning-and-performing-a-migration}

推奨される手順の次のリストは、GitLab CI/CDへの移行を迅速に完了できた組織を観察した後に作成されました。

### 移行計画を作成する {#create-a-migration-plan}

移行を開始する前に、移行の準備をするために[移行計画](plan_a_migration.md)を作成する必要があります。

TeamCityからの移行については、準備として次の質問をしてください:

- 現在、TeamCityのジョブではどのプラグインが使用されていますか？
  - これらのプラグインが正確に何をするか知っていますか？
- TeamCityエージェントに何がインストールされていますか？
- 使用中の共有ライブラリはありますか？
- TeamCityからどのように認証していますか？SSHキー、APIトークン、またはその他のシークレットを使用していますか？
- パイプラインからアクセスする必要がある他のプロジェクトはありますか？
- 外部サービスにアクセスするための認証情報はTeamCityにありますか？たとえば、Ansible Tower、Artifactory、またはその他のクラウドプロバイダーまたはデプロイターゲットですか？

### 前提要件 {#prerequisites}

何らかの移行作業を行う前に、まず次のことを行う必要があります:

1. GitLabに慣れてください。
   - [主なGitLab CI/CD機能](../_index.md)についてお読みください。
   - [最初のGitLabパイプライン](../quick_start/_index.md)と、静的サイトをビルド、テスト、およびデプロイする[より複雑なパイプライン](../quick_start/tutorial.md)を作成するためのチュートリアルに従ってください。
   - [CI/CD YAML構文リファレンス](../yaml/_index.md)を確認してください。
1. GitLabをセットアップして構成します。
1. GitLabインスタンスをテストします。
   - 共有GitLab.com Runnerを使用するか、新しいRunnerをインストールして、[Runner](../runners/_index.md)が利用可能であることを確認します。

### 移行手順 {#migration-steps}

1. SCMソリューションからGitLabにプロジェクトを移行します。
   - （推奨）利用可能な[インポーター](../../user/project/import/_index.md)を使用して、外部SCMプロバイダーからの大量のインポートを自動化できます。
   - [URLでリポジトリをインポートする](../../user/project/import/repo_by_url.md)ことができます。
1. 各プロジェクトに`.gitlab-ci.yml`ファイルを作成します。
1. TeamCityの設定をGitLab CI/CDジョブに移行し、マージリクエストに結果を直接表示するように設定します。
1. [クラウドデプロイテンプレート](../cloud_deployment/_index.md) 、[環境](../environments/_index.md) 、および[Kubernetes向けGitLabエージェント](../../user/clusters/agent/_index.md)を使用して、デプロイメントジョブを移行します。
1. CI/CD設定をさまざまなプロジェクト間で再利用できるかどうかを確認し、[CI/CDテンプレート](../examples/_index.md#cicd-templates)または[CI/CDコンポーネント](../components/_index.md)を作成して共有します。
1. [パイプラインの効率性](../pipelines/pipeline_efficiency.md)を参照して、GitLab CI/CDパイプラインをより高速かつ効率的にする方法を学びます。

ここに記載されていない質問がある場合は、[GitLabコミュニティフォーラム](https://forum.gitlab.com/)が役立ちます。
