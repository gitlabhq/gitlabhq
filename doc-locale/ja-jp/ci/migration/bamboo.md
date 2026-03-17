---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Bambooから移行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Atlassian BambooからGitLab CI/CDへ、BambooのUIからエクスポートされたBamboo仕様YAML設定を変換するか、仕様リポジトリに保存されているものを変換することで、移行することができます。

## 主な移行に関する考慮事項 {#key-migration-considerations}

| 設定の側面  | Bamboo                             | GitLab CI/CD                         | 移行タスク |
| --------------------- | ---------------------------------- | ------------------------------------ | --------------- |
| 設定ファイル   | Bamboo仕様 (JavaまたはYAML)        | `.gitlab-ci.yml` ファイル                | 仕様をGitLab YAML構文に変換 |
| 変数構文       | `${bamboo.variableName}`           | `$VARIABLE_NAME`                     | スクリプト内のすべての変数参照を更新 |
| 実行環境 | エージェント (ローカルまたはリモート)           | Runnerとexecutor               | Runnerのインストールと設定 |
| アーティファクトの共有      | サブスクリプション付きの名前付きアーティファクト | ステージ間の自動継承 | アーティファクトの設定を簡素化 |
| デプロイ           | 個別のデプロイプロジェクト       | デプロイメントジョブと環境    | 単一のパイプラインでビルドとデプロイを組み合わせる |

## 設定例 {#configuration-examples}

### Bamboo仕様のエクスポート {#bamboo-specs-export}

以下の例は、Bamboo UIからエクスポートされたBamboo仕様YAMLと、そのGitLab CI/CDの同等物を示しています。

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bambooは、プロジェクトが複数のプランを含み、プランがステージとジョブを定義し、ジョブが個々のタスクを実行するネストされた階層構造によってビルドを編成します。プロジェクトは、複数のプランがアクセスできる変数、認証情報、リポジトリ接続などの共有リソースのコンテナとして機能します。

Bamboo仕様のUIからのエクスポートには、この完全な階層に加えて、パーミッション、通知、プロジェクト設定などの管理メタデータが含まれます。

あなたのエクスポートをレビューする際には、これらの移行に不可欠な要素に焦点を当ててください:

- ジョブとタスク: 実際のビルドコマンドとスクリプト
- ステージの定義: 順次実行順序と依存
- 変数とアーティファクト: ジョブ間で共有されるデータとファイル
- トリガーと条件: ビルドが実行されるタイミングを決定するルール

```yaml
version: 2
plan:
  project-key: AB
  key: TP
  name: test plan
stages:
  - Default Stage:
      manual: false
      final: false
      jobs:
        - Default Job
Default Job:
  key: JOB1
  tasks:
  - checkout:
      force-clean-build: false
      description: Checkout Default Repository
  - script:
      interpreter: SHELL
      scripts:
        - |-
          ruby -v  # Print out ruby version for debugging
          bundle config set --local deployment true  # Install dependencies into ./vendor/ruby
          bundle install -j $(nproc)
          rubocop
          rspec spec
      description: run bundler
  artifact-subscriptions: []
repositories:
  - Demo Project:
      scope: global
triggers:
  - polling:
      period: '180'
branches:
  create: manually
  delete: never
  link-to-jira: true
notifications: []
labels: []
dependencies:
  require-all-stages-passing: false
  enabled-for-branches: true
  block-strategy: none
  plans: []
other:
  concurrent-build-plugin: system-default

---

version: 2
plan:
  key: AB-TP
plan-permissions:
  - users:
    - root
    permissions:
    - view
    - edit
    - build
    - clone
    - admin
    - view-configuration
  - roles:
    - logged-in
    - anonymous
    permissions:
    - view
...
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

GitLab CI/CDは、ネストされた複雑さを排除します。代わりに、各リポジトリには、すべてのステージとジョブを定義する単一の`.gitlab-ci.yml`ファイルが含まれています。

```yaml
default:
  image: ruby:latest

stages:
  - default-stage

job1:
  stage: default-stage
  script:
    - ruby -v  # Print out ruby version for debugging
    - bundle config set --local deployment true  # Install dependencies into ./vendor/ruby
    - bundle install -j $(nproc)
    - rubocop
    - rspec spec
```

{{< /tab >}}

{{< /tabs >}}

### ジョブとタスク {#jobs-and-tasks}

GitLabとBambooの両方で、同じステージのジョブは並行して実行されますが、ジョブが実行される前に満たす必要がある依存がある場合は除きます。

Bambooで実行できるジョブの数は、Bambooエージェントの可用性とBambooライセンスのサイズによって異なります。

GitLab CI/CDでは、並列ジョブの数は、GitLabインスタンスと統合されたRunnerの数、およびRunnerで設定された並行処理によって異なります。

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bambooでは、ジョブはタスクで構成されており、これはスクリプトとして実行されるコマンドのセット、またはソースcodeのチェックアウト、アーティファクトのダウンロード、Atlassianタスクマーケットプレイスで利用可能なその他のタスクのような事前定義されたタスクになります。

```yaml
version: 2
#...

Default Job:
  key: JOB1
  tasks:
  - checkout:
      force-clean-build: false
      description: Checkout Default Repository
  - script:
      interpreter: SHELL
      scripts:
        - |-
          ruby -v
          bundle config set --local deployment true
          bundle install -j $(nproc)
      description: run bundler
other:
  concurrent-build-plugin: system-default
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

GitLabにおけるタスクの同等物は`script`であり、Runnerが実行するコマンドを指定します。CI/CDテンプレートとCI/CDコンポーネントを使用して、すべてを自分で記述することなくパイプラインを構成できます。

```yaml
job1:
  script: "bundle exec rspec"

job2:
  script:
    - ruby -v
    - bundle config set --local deployment true
    - bundle install -j $(nproc)
```

{{< /tab >}}

{{< /tabs >}}

### コンテナイメージ {#container-images}

以下の例は、Bambooの`docker`キーワードがGitLabの`image`キーワードにどのように変換されるかを示しています。

{{< tabs >}}

{{< tab title="Bamboo" >}}

ビルドとデプロイはデフォルトでBambooエージェントのネイティブオペレーティングシステムで実行されますが、`docker`キーワードを使用してコンテナで実行するように設定できます。

```yaml
version: 2
plan:
  project-key: SAMPLE
  name: Build Ruby App
  key: BUILD-APP

docker: alpine:latest

stages:
  - Build App:
      jobs:
        - Build Application

Build Application:
  tasks:
    - script:
        - # Run builds
  docker:
    image: alpine:edge
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

GitLab CI/CDでは、`image`キーワードのみが必要です。

```yaml
default:
  image: alpine:latest

stages:
  - build

build-application:
  stage: build
  script:
    - # Run builds
  image:
    name: alpine:edge
```

{{< /tab >}}

{{< /tabs >}}

### 変数 {#variables}

以下の例は、変数の定義とアクセスにおける構文の違いを示しています。

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bambooには、異なるアクセスパターンを持つさまざまな変数タイプがあります。システム変数は`${system.variableName}`を、その他の変数は`${bamboo.variableName}`を使用します。

スクリプトタスクでは、ドットはアンダースコアに変換されます。例えば、`${bamboo.variableName}`は`$bamboo_variableName`になります。

```yaml
variables:
  username: admin
  releaseType: milestone

Default job:
  tasks:
    - script: echo '$bamboo_username is the DRI for $bamboo_releaseType'
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

GitLab CI/CDでは、変数は`$VARIABLE_NAME`を使用して通常のShellスクリプト変数のようにアクセスされます。Bambooのシステム変数やグローバル変数と同様に、GitLabにはすべてのジョブで利用可能な事前定義されたCI/CD変数があります。

```yaml
variables:
  DEFAULT_VAR: "A default variable"

job1:
  variables:
    JOB_VAR: "A job variable"
  script:
    - echo "Variables are '$DEFAULT_VAR' and '$JOB_VAR'"
```

{{< /tab >}}

{{< /tabs >}}

### 条件とトリガー {#conditions-and-triggers}

これらの例は、Bambooの条件とトリガーがGitLabのルールにどのように変換されるかを示しています。

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bambooには、codeの変更、スケジュール、他のプランの結果、またはオンデマンドに基づいてビルドをトリガーするためのさまざまなオプションがあります。プランは、新しい変更のためにプロジェクトを定期的にポーリングするように設定できます。

```yaml
tasks:
  - script:
      scripts:
        - echo "Hello"
      conditions:
        - variable:
            equals:
              planRepository.branch: development

triggers:
  - polling:
      period: '180'
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

GitLab CI/CDパイプラインは、codeの変更、スケジュール、またはAPIコールに基づいてトリガーされます。パイプラインはポーリングを使用しません。

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_COMMIT_REF_NAME == "development"

workflow:
  rules:
    - changes:
        - .gitlab/**/**.md
      when: never
```

{{< /tab >}}

{{< /tabs >}}

### アーティファクト {#artifacts}

GitLabとBambooの両方で、`artifacts`キーワードを使用してジョブアーティファクトを定義できます。

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bambooでは、アーティファクトは名前、場所、およびパターンで定義されます。アーティファクトを他のジョブやプランと共有したり、アーティファクトをサブスクライブするジョブを定義したりできます。

`artifact-subscriptions`は同じプラン内の別のジョブからアーティファクトにアクセスするために使用され、`artifact-download`は異なるプラン内のジョブからアーティファクトにアクセスするために使用されます。

```yaml
version: 2
# ...
Build:
  # ...
  artifacts:
    - name: Test Reports
      location: target/reports
      pattern: '*.xml'
      required: false
      shared: false
    - name: Special Reports
      location: target/reports
      pattern: 'special/*.xml'
      shared: true

Test app:
  artifact-subscriptions:
    - artifact: Test Reports
      destination: deploy

# ...
Build:
  # ...
  tasks:
    - artifact-download:
        source-plan: PROJECTKEY-PLANKEY
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

GitLabでは、以前のステージで完了したすべてのジョブのアーティファクトは、デフォルトでダウンロードされます。

```yaml
stages:
  - build

pdf:
  stage: build
  script: #generate XML reports
  artifacts:
    name: "test-report-files"
    untracked: true
    paths:
      - target/reports
```

この例では: 

- アーティファクトの名前は明示的に指定されますが、CI/CD変数を使用することで動的にすることができます。
- `untracked`キーワードは、アーティファクトにGitで追跡されていないファイルと、`paths`で明示的に指定されたファイルも含むように設定します。

{{< /tab >}}

{{< /tabs >}}

### キャッシュ {#caching}

Bambooでは、Gitのキャッシュをビルドの高速化に利用できます。GitのキャッシュはBamboo管理設定で設定され、Bambooサーバーまたはリモートエージェントのいずれかに保存されます。

GitLabはGitキャッシュとジョブキャッシュの両方をサポートしています。キャッシュは、`cache`キーワードを使用して各ジョブに対して定義されます:

```yaml
test-job:
  stage: build
  cache:
    - key:
        files:
          - Gemfile.lock
      paths:
        - vendor/ruby
    - key:
        files:
          - yarn.lock
      paths:
        - .yarn-cache/
  script:
    - bundle config set --local path 'vendor/ruby'
    - bundle install
    - yarn install --cache-folder .yarn-cache
    - echo Run tests...
```

### デプロイ {#deployments}

以下の例は、BambooのデプロイプロジェクトをGitLabのデプロイメントジョブに変換する方法を示しています。

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bambooにはデプロイプロジェクトがあり、これはビルドプランにリンクして、アーティファクトをデプロイ環境に追跡、フェッチ、およびデプロイします。プロジェクトを作成する際には、それをビルドプランにリンクし、デプロイ環境とデプロイを実行するタスクを指定します。

```yaml
deployment:
  name: Deploy ruby app
  source-plan: build-app

release-naming: release-1.0

environments:
  - Production

Production:
  tasks:
    - # scripts to deploy app to production
    - ./.ci/deploy_prod.sh
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

GitLab CI/CDでは、環境にデプロイする、またはリリースを作成するデプロイメントジョブを作成できます。

```yaml
deploy-to-production:
  stage: deploy
  script:
    - # Run Deployment script
    - ./.ci/deploy_prod.sh
  environment:
    name: production
```

代わりにリリースを作成するには、`glab`CLIツールと`release`キーワードを使用してGitタグのリリースを作成します:

```yaml
release_job:
  stage: release
  image: registry.gitlab.com/gitlab-org/cli:latest
  rules:
    - if: $CI_COMMIT_TAG                  # Run this job when a tag is created manually
  script:
    - echo "Building release version"
  release:
    tag_name: $CI_COMMIT_TAG
    name: 'Release $CI_COMMIT_TAG'
    description: 'Release created using the CLI.'
```

{{< /tab >}}

{{< /tabs >}}

## セキュリティスキャン {#security-scanning}

Bambooは、Atlassian Marketplaceで提供されるサードパーティタスクに依存して、セキュリティスキャンを実行します。

GitLabは、SDLCのすべての部分における脆弱性を検出するためのセキュリティスキャナーを提供します。GitLabでテンプレートを使用してこれらのスキャナーを追加できます。たとえば、パイプラインにSASTスキャンを追加するには、次のようにします:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

CI/CD変数を使用することで、セキュリティスキャナーの動作をカスタマイズできます。

## シークレット管理 {#secrets-management}

Bambooにおけるシークレット管理は、共有認証情報を使用するか、Atlassian Marketplaceのサードパーティアプリケーションを使用することで処理されます。

GitLabでのシークレット管理には、外部サービスのサポートされているインテグレーションを使用できます。これらのサービスはGitLabプロジェクトの外部にシークレットを安全に保存しますが、そのサービスに対するサブスクリプションが必要です。

GitLabは、OIDCをサポートする他のサードパーティサービスに対するOIDC認証もサポートしています。

さらに、認証情報をCI/CD変数に保存することで、ジョブで利用可能にすることができますが、平文で保存されたシークレットは偶発的な漏洩の影響を受けやすいです。常に機密情報をマスクされ保護された変数に保存することで、リスクの一部を軽減する必要があります。

> [!note]
> 
> シークレットを`.gitlab-ci.yml`ファイルに変数として保存しないでください。これはプロジェクトにアクセスできるすべてのユーザーに公開されます。機密情報を変数に保存するのは、プロジェクト、グループ、またはインスタンスの設定でのみ行うべきです。

## 移行計画の作成 {#create-a-migration-plan}

移行を開始する前に、[移行計画](plan_a_migration.md)を作成し、以下の質問に答えてください:

- 今日、どのようなBambooタスクがジョブによって使用されており、それらは何をするものですか？
- いずれかのタスクがMaven、Gradle、またはNPMなどの一般的なビルドツールをラップしていますか？
- どのようなソフトウェアがBambooエージェントにインストールされていますか？
- Bambooからどのように認証していますか（SSHキー、APIトークン、または他のシークレット）？
- 外部サービスにアクセスするための認証情報がBambooにありますか？
- 共有ライブラリやテンプレートは使用されていますか？

## BambooからGitLab CI/CDへ移行する {#migrate-from-bamboo-to-gitlab-cicd}

前提条件: 

- GitLabインスタンスがセットアップされ、設定されている必要があります。
- [Runner](../runners/_index.md)が利用可能である必要があります。

Bambooから移行するには:

1. あなたのBamboo設定を監査します:
   - Bamboo UIからBambooプロジェクト/プランをYAML仕様としてエクスポートする。
   - あなたのジョブで使用されているすべてのBambooタスクをリストします（例: Maven、Docker、SCP）。
   - 各Bambooエージェントにインストールされているソフトウェアバージョンを記録します。
   - すべての共有認証情報とその使用法を特定します。

1. あなたのソースcodeリポジトリをGitLabに移行する:
   - 利用可能な[インポーター](../../user/import/_index.md)を使用して、外部SCMプロバイダーからの大量インポートを自動化します。
   - 個々のリポジトリについては、[URLによるリポジトリのインポート](../../user/project/import/repo_by_url.md)を行います。

1. 同等のソフトウェアでRunnerをセットアップします:
   - あなたのBambooエージェントに存在する同じソフトウェアバージョンをインストールします。
   - 複雑なエージェントセットアップの場合は、必要なツールを含むカスタムDockerイメージを作成します。
   - Runnerがあなたのビルドコマンドを正常に実行できることをテストします。

1. Bamboo仕様を`.gitlab-ci.yml`ファイルに変換します:
   - Bambooのプラン構造をGitLabのステージとジョブに置き換えます。
   - `${bamboo.variableName}`構文を`$VARIABLE_NAME`に変換します。
   - Bamboo固有の`${bamboo.planKey}`のような変数を、`$CI_PIPELINE_ID`のようなGitLabの同等物に置き換えます。
   - Bambooのチェックアウトタスクを削除します。GitLabは、各ジョブの開始時にあなたのソースcodeを自動的にチェックアウトする。

1. アーティファクトの処理を移行する:
   - Bambooの`artifact-subscriptions`および`artifact-download`設定を削除します。
   - ステージ間の自動アーティファクト継承を使用します。
   - アーティファクトパスをあなたのGitLabジョブ構造に合わせて更新します。

1. Bambooのデプロイプロジェクトを変換する:
   - 個別のBambooデプロイプロジェクトからのデプロイタスクを、あなたのmain `.gitlab-ci.yml`ファイルに移動します。
   - Bamboo環境をGitLab [environments](../environments/_index.md)に置き換えます。
   - 一般的なデプロイパターンには、[cloud deployment templates](../cloud_deployment/_index.md)を使用します。
   - Kubernetesにデプロイする場合は、[Kubernetes向けGitLabエージェントサーバー](../../user/clusters/agent/_index.md)を設定します。

1. シークレットと認証情報を移行する:
   - [external secrets integrations](../secrets/_index.md)を使用するか、認証情報をマスクされ保護された変数であるCI/CD変数として保存します。

1. 移行したパイプラインをテストして最適化します:
   - テストパイプラインを実行して機能を検証します。
   - パイプラインの結果を表示するためにマージリクエストインテグレーションを追加します。
   - パイプラインのパフォーマンスを最適化し、再利用可能なテンプレートを作成します。

## 関連トピック {#related-topics}

- [Getting started guide](../_index.md)
- [CI/CD YAML構文リファレンス](../yaml/_index.md)
- [GitLab CI/CD変数](../variables/_index.md)
- [パイプライン効率性](../pipelines/pipeline_efficiency.md)
