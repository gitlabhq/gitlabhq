---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CircleCIから移行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

現在CircleCIを使用している場合は、[GitLab CI/CD](../_index.md)に移行して、その強力な機能をすべて活用できます。

移行を開始する前に役立つ可能性のあるリソースをいくつか収集しました。

[クイックスタートガイド](../quick_start/_index.md)は、GitLab CI/CDの仕組みの概要を把握するのに役立ちます。[Auto DevOps](../../topics/autodevops/_index.md)に関心があるかもしれません。これは、アプリケーションをビルド、テスト、デプロイするために使用でき、設定はほとんど必要ありません。

高度なCI/CDチームの場合、[カスタムプロジェクトテンプレート](../../administration/custom_project_templates.md)を使用すると、パイプラインの設定を再利用できます。

ここに記載されていない質問がある場合は、[GitLabコミュニティフォーラム](https://forum.gitlab.com/)が役立ちます。

## `config.yml`と`.gitlab-ci.yml`の違い {#configyml-vs-gitlab-ciyml}

CircleCIの`config.yml`設定ファイルは、スクリプト、ジョブ、ワークフロー（GitLabでは「ステージ」と呼ばれます）を定義します。GitLabでは、リポジトリのルートディレクトリにある`.gitlab-ci.yml`ファイルを使用して、同様のアプローチが使用されます。

### ジョブ {#jobs}

CircleCIでは、ジョブは特定のタスクを実行するための一連のステップです。GitLabでは、[ジョブ](../jobs/_index.md)も設定ファイルの基本的な要素です。`checkout`キーワードは、リポジトリが自動的にフェッチされるため、GitLab CI/CDでは不要です。

CircleCIのジョブ定義の例:

```yaml
jobs:
  job1:
    steps:
      - checkout
      - run: "execute-script-for-job1"
```

GitLab CI/CDでの同じジョブ定義の例:

```yaml
job1:
  script: "execute-script-for-job1"
```

### Dockerイメージ定義 {#docker-image-definition}

CircleCIは、ジョブレベルでイメージを定義します。これは、GitLab CI/CDでもサポートされています。さらに、GitLab CI/CDは、`image`が定義されていないすべてのジョブで使用されるように、これをグローバルに設定することをサポートしています。

CircleCIのイメージ定義の例:

```yaml
jobs:
  job1:
    docker:
      - image: ruby:2.6
```

GitLab CI/CDでの同じイメージ定義の例:

```yaml
job1:
  image: ruby:2.6
```

### ワークフロー {#workflows}

CircleCIは、`workflows`を使用してジョブの実行順序を決定します。これは、同時実行、連続実行、スケジュール実行、または手動実行を決定するためにも使用されます。GitLab CI/CDでの同等の機能は、[ステージ](../yaml/_index.md#stages)と呼ばれます。同じステージのジョブは並行して実行され、前のステージが完了した後にのみ実行されます。デフォルトでは、ジョブが失敗すると次のステージの実行はスキップされますが、[ジョブが失敗した後](../yaml/_index.md#allow_failure)でも続行させることができます。

使用できるさまざまな種類のパイプラインのガイダンスについては、[パイプラインアーキテクチャの概要](../pipelines/pipeline_architectures.md)を参照してください。パイプラインは、大規模で複雑なプロジェクトや、独立して定義されたコンポーネントを持つモノレポなど、ニーズに合わせて調整できます。

#### 並列および連続ジョブ実行 {#parallel-and-sequential-job-execution}

次の例は、ジョブを並行して、または順番に実行する方法を示しています:

1. `job1`と`job2`は、（GitLab CI/CDの`build`ステージで）並行して実行されます。
1. `job3`は、`job1`と`job2`が正常に完了した後にのみ（`test`ステージで）実行されます。
1. `job4`は、`job3`が正常に完了した後にのみ（`deploy`ステージで）実行されます。

`workflows`を使用したCircleCIの例:

```yaml
version: 2
jobs:
  job1:
    steps:
      - checkout
      - run: make build dependencies
  job2:
    steps:
      - run: make build artifacts
  job3:
    steps:
      - run: make test
  job4:
    steps:
      - run: make deploy

workflows:
  version: 2
  jobs:
    - job1
    - job2
    - job3:
        requires:
          - job1
          - job2
    - job4:
        requires:
          - job3
```

GitLab CI/CDでの`stages`と同じワークフローの例:

```yaml
stages:
  - build
  - test
  - deploy

job1:
  stage: build
  script: make build dependencies

job2:
  stage: build
  script: make build artifacts

job3:
  stage: test
  script: make test

job4:
  stage: deploy
  script: make deploy
  environment: production
```

#### スケジュールされた実行 {#scheduled-run}

GitLab CI/CDには、[パイプラインのスケジュール](../pipelines/schedules.md)を設定するための使いやすいUIがあります。また、スケジュールされたパイプラインにジョブを含めるか除外するかを決定するために[ルール](../yaml/_index.md#rules)を使用できます。

スケジュールされたワークフローのCircleCIの例:

```yaml
commit-workflow:
  jobs:
    - build
scheduled-workflow:
  triggers:
    - schedule:
        cron: "0 1 * * *"
        filters:
          branches:
            only: try-schedule-workflow
  jobs:
    - build
```

GitLab CI/CDで[`rules`](../yaml/_index.md#rules)を使用した同じスケジュールされたパイプラインの例:

```yaml
job1:
  script:
    - make build
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule" && $CI_COMMIT_REF_NAME == "try-schedule-workflow"
```

パイプラインの設定を保存したら、[GitLabユーザーインターフェース](../pipelines/schedules.md#create-a-pipeline-schedule)でcronスケジュールを設定し、UIでスケジュールを有効または無効にすることもできます。

#### 手動実行 {#manual-run}

手動ワークフローのCircleCIの例:

```yaml
release-branch-workflow:
  jobs:
    - build
    - testing:
        requires:
          - build
    - deploy:
        type: approval
        requires:
          - testing
```

[`when: manual`](../jobs/job_control.md#create-a-job-that-must-be-run-manually)を使用したGitLab CI/CDでの同じワークフローの例:

```yaml
deploy_prod:
  stage: deploy
  script:
    - echo "Deploy to production server"
  when: manual
  environment: production
```

### ブランチによるジョブのフィルター {#filter-job-by-branch}

[ルール](../yaml/_index.md#rules)は、特定のブランチに対してジョブが実行されるかどうかを判断するメカニズムです。

ブランチでフィルターされたジョブのCircleCIの例:

```yaml
jobs:
  deploy:
    branches:
      only:
        - main
        - /rc-.*/
```

GitLab CI/CDで`rules`を使用した同じワークフローの例:

```yaml
deploy:
  stage: deploy
  script:
    - echo "Deploy job"
  rules:
    - if: $CI_COMMIT_BRANCH == "main" || $CI_COMMIT_BRANCH =~ /^rc-/
  environment: production
```

### キャッシュ {#caching}

GitLabは、以前にダウンロードした依存関係を再利用することにより、ジョブのビルド時間を短縮するためのキャッシュメカニズムを提供します。これらの機能を最大限に活用するには、[キャッシュとアーティファクト](../caching/_index.md#how-cache-is-different-from-artifacts)の違いを知っておくことが重要です。

キャッシュを使用するジョブのCircleCIの例:

```yaml
jobs:
  job1:
    steps:
      - restore_cache:
          key: source-v1-< .Revision >
      - checkout
      - run: npm install
      - save_cache:
          key: source-v1-< .Revision >
          paths:
            - "node_modules"
```

GitLab CI/CDで`cache`を使用した同じパイプラインの例:

```yaml
test_async:
  image: node:latest
  cache:  # Cache modules in between jobs
    key: $CI_COMMIT_REF_SLUG
    paths:
      - .npm/
  before_script:
    - npm ci --cache .npm --prefer-offline
  script:
    - node ./specs/start.js ./specs/async.spec.js
```

## コンテキストと変数 {#contexts-and-variables}

CircleCIは、プロジェクトパイプライン全体で環境変数を安全に渡すための[コンテキスト](https://circleci.com/docs/contexts/)を提供します。GitLabでは、関連するプロジェクトをまとめるために[グループ](../../user/group/_index.md)を作成できます。グループレベルでは、[CI/CD変数](../variables/_index.md#for-a-group)を個々のプロジェクトの外部に保存し、複数のプロジェクトにわたるパイプラインに安全に渡すことができます。

## Orbs {#orbs}

CircleCI Orbsに対処し、GitLabが同様の機能を実現する方法について説明する2つのGitLabイシューが開いています。

- [issue #1151](https://gitlab.com/gitlab-com/Product/-/issues/1151)
- [issue #195173](https://gitlab.com/gitlab-org/gitlab/-/issues/195173)

## ビルド環境 {#build-environments}

CircleCIは、特定のジョブを実行するための基盤となるテクノロジーとして`executors`を提供します。GitLabでは、これは[Runner](https://docs.gitlab.com/runner/)によって行われます。

次の環境がサポートされています:

セルフマネージドRunner:

- Linux
- Windows
- macOS

GitLab.comのインスタンスRunner:

- Linux
- [Windows](../runners/hosted_runners/windows.md) （[ベータ](../../policy/development_stages_support.md#beta)）。
- [macOS](../runners/hosted_runners/macos.md) （[ベータ](../../policy/development_stages_support.md#beta)）。

### マシンと特定のビルド環境 {#machine-and-specific-build-environments}

[タグ](../yaml/_index.md#tags)を使用すると、どのRunnerがジョブを実行するかをGitLabに指示することで、異なるプラットフォームでジョブを実行できます。

特定の環境で実行されているジョブのCircleCIの例:

```yaml
jobs:
  ubuntuJob:
    machine:
      image: ubuntu-1604:201903-01
    steps:
      - checkout
      - run: echo "Hello, $USER!"
  osxJob:
    macos:
      xcode: 11.3.0
    steps:
      - checkout
      - run: echo "Hello, $USER!"
```

GitLab CI/CDで`tags`を使用した同じジョブの例:

```yaml
windows job:
  stage: build
  tags:
    - windows
  script:
    - echo Hello, %USERNAME%!

osx job:
  stage: build
  tags:
    - osx
  script:
    - echo "Hello, $USER!"
```
