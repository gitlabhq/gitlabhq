---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Bambooから移行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Atlassian BambooからGitLab CI/CDに移行するには、Bamboo UIからエクスポートされた、または仕様リポジトリに保存されているBamboo仕様YAML構成を変換します。

## 主な移行の考慮事項 {#key-migration-considerations}

| 構成の側面  | Bamboo                             | GitLab CI/CD。                         | 移行タスク |
| --------------------- | ---------------------------------- | ------------------------------------ | --------------- |
| 設定ファイル   | Bamboo仕様（JavaまたはYAML）        | `.gitlab-ci.yml`ファイル                | 仕様をGitLab YAML構文に変換する |
| 変数の構文       | `${bamboo.variableName}`           | `$VARIABLE_NAME`                     | スクリプト内のすべての変数の参照を更新します |
| 実行環境 | エージェント（ローカルまたはリモート）           | executor付きのRunner               | Runnerをインストールして構成する |
| アーティファクトの共有      | サブスクリプション付きの名前付きアーティファクト | ステージ間の自動継承 | アーティファクトの構成を簡素化する |
| デプロイ           | 個別のデプロイプロジェクト       | 環境を備えたデプロイメントジョブ    | 単一のパイプラインでビルドとデプロイを組み合わせる |

## 設定例 {#configuration-examples}

### Bamboo仕様のエクスポート {#bamboo-specs-export}

次の例は、UIからのBamboo仕様YAMLのエクスポートと、それに対応するGitLab CI/CDを示しています。

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bambooは、プロジェクトに複数のプランが含まれ、プランがステージとジョブを定義し、ジョブが個々のタスクを実行する、ネストされた階層を介してビルドを編成します。プロジェクトは、複数のプランがアクセスできる変数、認証情報、リポジトリ接続などの共有リソースのコンテナとして機能します。

UIからのBamboo仕様のエクスポートには、この完全な階層に加えて、許可、通知、プロジェクト設定などの管理メタデータが含まれています。

エクスポートをレビューする際は、これらの移行に不可欠な要素に焦点を当ててください:

- ジョブとタスク: 実際のビルドコマンドとスクリプト
- ステージングの定義: シーケンスの実行順序と依存関係
- 変数とアーティファクト: ジョブ間で共有されるデータとファイル
- トリガーと条件: ビルドの実行時期を決定するルール

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

{{< tab title="GitLab CI/CD。" >}}

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

GitLabとBambooの両方で、同じステージ内のジョブは並行して実行されます。ただし、ジョブの実行前に満たす必要のある依存関係がある場合を除きます。

Bambooで実行できるジョブの数は、Bambooエージェントの可用性とBambooライセンスのサイズによって異なります。

GitLab CI/CDでは、並列ジョブの数は、GitLabインスタンスとRunnerに設定された並行処理に統合されたRunnerの数によって異なります。

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bambooでは、ジョブはタスクで構成されています。これらは、スクリプトとして実行される一連のコマンド、またはソースコードのチェックアウト、アーティファクトのダウンロード、およびAtlassianタスクマーケットプレイスで利用できるその他のタスクのような事前定義されたタスクにすることができます。

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

{{< tab title="GitLab CI/CD。" >}}

GitLabでのタスクに相当するものは、`script`です。これは、Runnerが実行するコマンドを指定します。CI/CDテンプレートとCI/CDコンポーネントを使用すると、すべてを自分で記述しなくても、パイプラインを構成できます。

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

次の例は、Bambooの`docker`キーワードがGitLabの`image`キーワードにどのように変換されるかを示しています。

{{< tabs >}}

{{< tab title="Bamboo" >}}

ビルドとデプロイは、デフォルトでBambooエージェントネイティブのオペレーティングシステムで実行されますが、`docker`キーワードを使用してコンテナで実行するように構成できます。

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

{{< tab title="GitLab CI/CD。" >}}

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

次の例は、変数の定義とアクセスにおける構文の違いを示しています。

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bambooには、アクセスパターンが異なるさまざまな変数のタイプがあります。システム変数は`${system.variableName}`を使用し、その他の変数は`${bamboo.variableName}`を使用します。

スクリプトタスクでは、ドットはアンダースコアに変換されます。たとえば、`${bamboo.variableName}`は`$bamboo_variableName`になります。

```yaml
variables:
  username: admin
  releaseType: milestone

Default job:
  tasks:
    - script: echo '$bamboo_username is the DRI for $bamboo_releaseType'
```

{{< /tab >}}

{{< tab title="GitLab CI/CD。" >}}

GitLab CI/CDでは、変数は`$VARIABLE_NAME`を使用して、通常のShellスクリプト変数のようにアクセスされます。Bambooのシステム変数およびグローバル変数のように、GitLabには、すべてのジョブで使用できる定義済みのCI/CD変数があります。

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

Bambooには、コードの変更、スケジュール、他のプランの結果、またはオンデマンドに基づいてビルドをトリガーするためのさまざまなオプションがあります。プランは、新しい変更についてプロジェクトを定期的にポーリングするように構成できます。

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

{{< tab title="GitLab CI/CD。" >}}

GitLab CI/CDパイプラインは、コードの変更、スケジュール、またはAPIコールに基づいてトリガーされます。パイプラインはポーリングを使用しません。

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

Bambooでは、アーティファクトは名前、場所、パターンで定義されます。アーティファクトを他のジョブおよびプランと共有したり、アーティファクトをサブスクリプションするジョブを定義したりできます。

`artifact-subscriptions`は、同じプラン内の別のジョブからアーティファクトにアクセスするために使用され、`artifact-download`は、異なるプラン内のジョブからアーティファクトにアクセスするために使用されます。

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

{{< tab title="GitLab CI/CD。" >}}

GitLabでは、前のステージで完了したジョブからのすべてのアーティファクトがデフォルトでダウンロードされます。

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

- アーティファクトの名前は明示的に指定されていますが、CI/CD変数を使用して動的にすることができます。
- `untracked`キーワードは、アーティファクトがGitの追跡されていないファイルも含むように設定し、`paths`で明示的に指定されたファイルとともに設定します。

{{< /tab >}}

{{< /tabs >}}

### キャッシュ {#caching}

Bambooでは、Gitキャッシュを使用してビルドを高速化できます。Gitキャッシュは、Bamboo管理設定で構成され、Bambooサーバーまたはリモートエージェントに保存されます。

GitLabは、Gitキャッシュとジョブキャッシュの両方をサポートしています。キャッシュは、`cache`キーワードを使用してジョブごとに定義されます:

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

次の例は、BambooのデプロイプロジェクトをGitLabのデプロイメントジョブに変換する方法を示しています。

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bambooには、デプロイ環境へのアーティファクトの追跡、フェッチ、およびデプロイを行うためのビルドプランにリンクするデプロイプロジェクトがあります。プロジェクトを作成するときは、それをビルドプランにリンクし、デプロイ環境とデプロイを実行するためのタスクを指定します。

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

{{< tab title="GitLab CI/CD。" >}}

GitLab CI/CDでは、環境にデプロイするか、リリースを作成するデプロイメントジョブを作成できます。

```yaml
deploy-to-production:
  stage: deploy
  script:
    - # Run Deployment script
    - ./.ci/deploy_prod.sh
  environment:
    name: production
```

代わりにリリースを作成するには、`release`キーワードと`glab` CLIツールを使用して、Gitタグ付けのリリースを作成します:

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

Bambooは、Atlassian Marketplaceで提供されているサードパーティのタスクに依存して、セキュリティスキャナーを実行します。

GitLabは、SDLCのすべての部分で脆弱性を検出するためのセキュリティスキャナーを提供します。たとえば、SASTスキャンをパイプラインに追加するには、テンプレートを使用して、これらのスキャナーをGitLabに追加できます:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

CI/CD変数を使用すると、セキュリティスキャナーの動作をカスタマイズできます。

## シークレット管理 {#secrets-management}

Bambooのシークレット管理は、共有認証情報、またはAtlassianマーケットプレイスからのサードパーティアプリケーションを使用して処理されます。

GitLabでのシークレット管理の場合、サポートされている外部サービスのインテグレーションを使用できます。これらのサービスは、GitLabプロジェクトの外部にシークレットを安全に保存しますが、サービスのサブスクリプションが必要です。

GitLabは、OIDC認証をサポートする他のサードパーティサービスに対してもOIDC認証をサポートしています。

さらに、CI/CD変数に保存することで、ジョブで認証情報を使用できるようにすることができます。ただし、プレーンテキストで保存されたシークレットは、偶発的な露出の影響を受けやすくなります。機密情報は常にマスクされた保護された変数に保存する必要があります。これにより、リスクの一部が軽減されます。

{{< alert type="note" >}}

プロジェクトへのアクセス権を持つすべてのユーザーに公開されている`.gitlab-ci.yml`ファイルに、変数としてシークレットを保存しないでください。機密情報を変数に保存するのは、プロジェクト、グループ、またはインスタンスの設定でのみ行う必要があります。

{{< /alert >}}

## 移行計画を作成する {#create-a-migration-plan}

移行を開始する前に、[移行計画](plan_a_migration.md)を作成し、次の質問に答えてください:

- 今日のジョブではどのBambooタスクが使用されていますか？また、それらは何をしますか？
- Maven、Gradle、またはNPMのような一般的なビルドツールをラップするタスクはありますか？
- どのソフトウェアがBambooエージェントにインストールされていますか？
- どのようにBambooから認証していますか（SSHキー、APIトークン、またはその他のシークレット）？
- 外部サービスにアクセスするためのBambooの認証情報はありますか？
- 共有ライブラリまたはテンプレートは使用されていますか？

## BambooからGitLab CI/CDへの移行 {#migrate-from-bamboo-to-gitlab-cicd}

前提要件: 

- GitLabインスタンスがセットアップされ、構成されている必要があります。
- [Runner](../runners/_index.md)が利用可能である必要があります。

Bambooから移行するには:

1. Bamboo構成を監査します:
   - Bambooプロジェクト/プランをBamboo UIからYAML仕様としてエクスポートします。
   - ジョブで使用されているすべてのBambooタスクを一覧表示します（たとえば、Maven、Docker、SCP）。
   - 各Bambooエージェントにインストールされているソフトウェアバージョンをドキュメント化します。
   - すべての共有認証情報とその使用状況を特定します。

1. ソースコードリポジトリをGitLabに移行します:
   - 利用可能な[インポーター](../../user/project/import/_index.md)を使用して、外部SCMプロバイダーからの大量インポートを自動化します。
   - 個々のリポジトリについては、[URLでリポジトリをインポートします](../../user/project/import/repo_by_url.md)。

1. 同等のソフトウェアでGitLab Runnerをセットアップします:
   - Bambooエージェントに存在するのと同じソフトウェアバージョンをインストールします。
   - 複雑なエージェントのセットアップの場合は、必要なツールを使用してカスタムDockerイメージを作成します。
   - Runnerがビルドコマンドを正常に実行できることをテストします。

1. Bamboo仕様を`.gitlab-ci.yml`ファイルに変換します:
   - Bambooプランの構造をGitLabのステージとジョブに置き換えます。
   - `${bamboo.variableName}`構文を`$VARIABLE_NAME`に変換します。
   - `${bamboo.planKey}`のようなBamboo固有の変数を、`$CI_PIPELINE_ID`のようなGitLabの同等の変数に置き換えます。
   - Bambooチェックアウトタスクを削除します。GitLabは、各ジョブの開始時にソースコードを自動的にチェックアウトします。

1. アーティファクトの処理を移行します:
   - Bambooの`artifact-subscriptions`および`artifact-download`構成を削除します。
   - ステージ間でアーティファクトの自動継承を使用します。
   - アーティファクトのパスを更新して、GitLabのジョブ構造と一致させます。

1. Bambooのデプロイプロジェクトを変換します:
   - 個別のBambooデプロイプロジェクトからメイン`.gitlab-ci.yml`ファイルにデプロイタスクを移動します。
   - Bamboo環境をGitLabの[環境](../environments/_index.md)に置き換えます。
   - 一般的なデプロイパターンには、[クラウドデプロイテンプレート](../cloud_deployment/_index.md)を使用します。
   - Kubernetesにデプロイする場合は、[Kubernetes向けGitLabエージェント](../../user/clusters/agent/_index.md)を構成します。

1. シークレットと認証情報を移行します:
   - [外部シークレットインテグレーション](../secrets/_index.md)を使用するか、認証情報をマスクされた保護された変数として保存します。

1. 移行されたパイプラインをテストして最適化します:
   - テストパイプラインを実行して、機能を確認します。
   - マージリクエストインテグレーションを追加して、パイプラインの結果を表示します。
   - パイプラインのパフォーマンスを最適化し、再利用可能なテンプレートを作成します。

## 関連トピック {#related-topics}

- [入門ガイド](../_index.md)
- [CI/CD YAML構文リファレンス](../yaml/_index.md)
- [GitLab CI/CD変数](../variables/_index.md)
- [パイプライン効率性](../pipelines/pipeline_efficiency.md)
