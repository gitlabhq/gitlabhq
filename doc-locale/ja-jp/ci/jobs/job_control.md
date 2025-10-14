---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ジョブの実行方法を制御する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

新しいパイプラインを開始する前に、GitLabはそのパイプラインの設定をチェックし、そのパイプラインのどのジョブが実行可能かを判断します。[`rules`](job_rules.md)を使用すると、変数の値やパイプラインの種類などの条件に応じてジョブを実行するように設定できます。ジョブルールを使用する場合は、[重複パイプラインを回避する](job_rules.md#avoid-duplicate-pipelines)方法を確認してください。パイプラインの作成を制御するには、[workflow:rules](../yaml/workflow.md)を使用します。

## 手動の実行が必要なジョブを作成する {#create-a-job-that-must-be-run-manually}

ユーザーが開始しない限り、ジョブが実行されないように設定できます。これは**手動ジョブ**と呼ばれます。本番環境へのデプロイなど、手動ジョブの使用が適切な場合があります。

ジョブを手動ジョブとして指定するには、`.gitlab-ci.yml`ファイルのジョブに[`when: manual`](../yaml/_index.md#when)を追加します。

デフォルトでは、手動ジョブはパイプラインの開始時にスキップ済みと表示されます。

[保護ブランチ](../../user/project/repository/branches/protected.md)を使用して、未許可のユーザーによる実行を防ぎ、より厳密に[手動デプロイを保護](#protect-manual-jobs)できます。

[アーカイブ](../../administration/settings/continuous_integration.md#archive-pipelines)された手動ジョブは実行されません。

### 手動ジョブの種類 {#types-of-manual-jobs}

手動ジョブには、オプションとブロックの2種類があります。

オプション手動ジョブでは、次のようになります。

- [`allow_failure`](../yaml/_index.md#allow_failure)が`true`になります。これは、`rules`以外で`when: manual`が定義されたジョブのデフォルト設定です。
- このジョブのステータスは、パイプライン全体のステータスに影響を及ぼすことはありません。すべての手動ジョブが失敗しても、パイプラインは正常に完了する可能性があります。

ブロック手動ジョブでは、次のようになります。

- `allow_failure`が`false`になります。これは、[`rules`](../yaml/_index.md#rules)内で`when: manual`が定義されたジョブのデフォルト設定です。
- パイプラインは、ジョブが定義されているステージで停止します。パイプラインの実行を継続するには、[手動ジョブを実行](#run-a-manual-job)します。
- [**パイプラインが完了している**](../../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)が有効になっているプロジェクトのマージリクエストは、ブロックされたパイプラインとはマージできません。
- パイプラインのステータスには**ブロック**と表示されます。

[`trigger:strategy`](../yaml/_index.md#triggerstrategy)を使用してトリガーされたパイプラインで手動ジョブを使用する場合、手動ジョブの種類によっては、パイプラインの実行中にトリガージョブのステータスに影響を及ぼす可能性があります。

### 手動ジョブを実行する {#run-a-manual-job}

手動ジョブを実行するには、割り当てられたブランチにマージする権限が必要です。

1. パイプライン、ジョブ、[環境](../environments/deployments.md#configure-manual-deployments)、またはデプロイビューに移動します。
1. 手動ジョブの横にある**実行**（{{< icon name="play" >}}）を選択します。

### 手動ジョブの実行時に変数を指定する {#specify-variables-when-running-manual-jobs}

手動ジョブの実行時に、ジョブ固有のCI/CD変数を追加で指定できます。[CI/CD変数](../variables/_index.md)を使用するジョブの実行を変更する場合は、ここで変数を指定します。

手動ジョブを実行して追加の変数を指定するには、次のようにします。

- パイプラインビューで、手動ジョブの**名前**を選択します。**実行**（{{< icon name="play" >}}）を選択しないでください。
- フォームに変数のキーと値のペアを追加します。
- **ジョブを実行**を選択します。

{{< alert type="warning" >}}

手動ジョブを実行する権限を持つプロジェクトメンバーは誰でも、ジョブを再試行し、ジョブが最初に実行されたときに指定された変数を表示できます。これには次のユーザーが含まれます。

- 公開プロジェクトの場合: デベロッパーロール以上のユーザー。
- 非公開または内部プロジェクトの場合: ゲストロール以上のユーザー。

手動ジョブの変数として機密情報を入力する場合は、この表示レベルを考慮してください。

{{< /alert >}}

CI/CD設定または`.gitlab-ci.yml`ファイルで定義済みの変数を追加すると、新しい値で[変数がオーバーライド](../variables/_index.md#use-pipeline-variables)されます。このプロセスでオーバーライドされた変数は[展開](../variables/_index.md#prevent-cicd-variable-expansion)され、[マスク](../variables/_index.md#mask-a-cicd-variable)されません。

#### 更新した変数で手動ジョブを再試行する {#retry-a-manual-job-with-updated-variables}

{{< history >}}

- GitLab 15.7で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96199)されました。

{{< /history >}}

手動で指定した変数を使用して以前に実行した手動ジョブを再試行する際、変数を更新することも、同じ変数を使用することもできます。

以前に指定した変数を使用して手動ジョブを再試行するには、次のようにします。

- 同じ変数を使用する場合:
  - ジョブの詳細ページから、**再試行**（{{< icon name="retry" >}}）を選択します。
- 変数を更新する場合:
  - ジョブの詳細ページから、**CI/CD変数を更新**（{{< icon name="pencil-square" >}}）を選択します。
  - 前回の実行で指定した変数は、フォームに自動入力されます。このフォームから、CI/CD変数を追加、変更、または削除できます。
  - **ジョブを再実行**を選択します。

### 手動ジョブの確認を必須にする {#require-confirmation-for-manual-jobs}

`when: manual`と[`manual_confirmation`](../yaml/_index.md#manual_confirmation)を組み合わせて使用すると、手動ジョブの確認を必須にできます。これにより、本番環境へのデプロイなど、機密性の高いジョブにおける誤ったデプロイや削除を防止できます。

ジョブをトリガーするときは、実行前に操作を確認する必要があります。

### 手動ジョブを保護する {#protect-manual-jobs}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[保護環境](../environments/protected_environments.md)を使用して、手動ジョブの実行が許可されるユーザーのリストを定義します。保護環境に関連付けられたユーザーにのみ、手動ジョブをトリガーする権限を付与できます。これにより、以下が可能になります。

- 環境にデプロイできるユーザーをより厳密に制限する。
- 承認されたユーザーが「承認」するまでパイプラインをブロックする。

手動ジョブを保護するには、次のようにします。

1. ジョブに`environment`を追加します。次に例を示します。

   ```yaml
   deploy_prod:
     stage: deploy
     script:
       - echo "Deploy to production server"
     environment:
       name: production
       url: https://example.com
     when: manual
     rules:
       - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
   ```

1. [保護環境設定](../environments/protected_environments.md#protecting-environments)で、環境（この例では`production`）を選択し、手動ジョブをトリガーすることが許可されているユーザー、ロール、またはグループを**デプロイ許可**リストに追加します。このリストに登録されているユーザーのみがこの手動ジョブをトリガーできます。ただし、GitLab管理者は常に保護環境を使用できるため、同様にトリガーできます。

ブロック手動ジョブと保護環境を組み合わせると、後続のパイプラインステージを承認できるユーザーのリストを定義できます。保護された手動ジョブに`allow_failure: false`を追加すると、許可されたユーザーがその手動ジョブをトリガーした後にのみ、パイプラインの次のステージが実行されます。

## 遅延後にジョブを実行する {#run-a-job-after-a-delay}

[`when: delayed`](../yaml/_index.md#when)を使用すると、待機期間後にスクリプトを実行したり、ジョブが直ちに`pending`ステータスになるのを回避したりできます。

期間は、`start_in`キーワードを使用して設定できます。`start_in`の値は、単位を指定しない場合、秒単位の経過時間です。最小値は1秒、最大値は1週間です。有効な値の例は以下のとおりです。

- `'5'`（単位のない値は一重引用符で囲む必要があります）
- `5 seconds`
- `30 minutes`
- `1 day`
- `1 week`

ステージに遅延ジョブがある場合、パイプラインは遅延ジョブが完了するまで先に進みません。このキーワードを使用すると、異なるステージ間に遅延を挿入できます。

遅延ジョブのタイマーは、直前のステージが完了すると直ちに開始されます。他の種類のジョブと同じように、前のステージが正常に終了しない限り、遅延ジョブのタイマーは開始されません。

次の例では、前のステージが完了してから30分後に実行する、`timed rollout 10%`という名前のジョブを作成しています。

```yaml
timed rollout 10%:
  stage: deploy
  script: echo 'Rolling out 10% ...'
  when: delayed
  start_in: 30 minutes
  environment: production
```

遅延ジョブのアクティブなタイマーを停止するには、**スケジュールを解除**（{{< icon name="time-out" >}}）をクリックします。このジョブは、スケジュールによる自動実行ができなくなります。ただし、ジョブを手動で実行することはできます。

遅延ジョブを手動で開始するには、**スケジュールを解除**（{{< icon name="time-out" >}}）をクリックして遅延タイマーを停止してから、**実行**（{{< icon name="play" >}}）をクリックします。GitLab Runnerがすぐにジョブを開始します。

[アーカイブ](../../administration/settings/continuous_integration.md#archive-pipelines)された遅延ジョブは実行されません。

## 大規模なジョブを並列化する {#parallelize-large-jobs}

大規模なジョブを複数の小規模なジョブに分割して並列実行するには、`.gitlab-ci.yml`ファイルで[`parallel`](../yaml/_index.md#parallel)キーワードを使用します。

言語とテストスイートによって、並列化を有効にする方法が異なります。たとえば、Rubyのテストを並列実行するには、[Semaphore Test Boosters](https://github.com/renderedtext/test-boosters)とRSpecを使用します。

```ruby
# Gemfile
source 'https://rubygems.org'

gem 'rspec'
gem 'semaphore_test_boosters'
```

```yaml
test:
  parallel: 3
  script:
    - bundle
    - bundle exec rspec_booster --job $CI_NODE_INDEX/$CI_NODE_TOTAL
```

その後、新しいパイプラインビルドの**ジョブ**タブに移動すると、RSpecジョブが3つの個別のジョブに分割されていることを確認できます。

{{< alert type="warning" >}}

Test Boostersは、使用状況の統計情報を作成者に報告します。

{{< /alert >}}

### 並列ジョブの1次元マトリクスを実行する {#run-a-one-dimensional-matrix-of-parallel-jobs}

単一のパイプラインで1つのジョブを複数回並列実行し、ジョブの各インスタンスで異なる変数値を使用する場合は、[`parallel:matrix`](../yaml/_index.md#parallelmatrix)キーワードを使用します。

```yaml
deploystacks:
  stage: deploy
  script:
    - bin/deploy
  parallel:
    matrix:
      - PROVIDER: [aws, ovh, gcp, vultr]
  environment: production/$PROVIDER
```

### 並列トリガージョブのマトリクスを実行する {#run-a-matrix-of-parallel-trigger-jobs}

単一のパイプラインで[トリガー](../yaml/_index.md#trigger)ジョブを複数回並列実行し、ジョブのインスタンスごとに異なる変数値を使用できます。

```yaml
deploystacks:
  stage: deploy
  trigger:
    include: path/to/child-pipeline.yml
  parallel:
    matrix:
      - PROVIDER: aws
        STACK: [monitoring, app1]
      - PROVIDER: ovh
        STACK: [monitoring, backup]
      - PROVIDER: [gcp, vultr]
        STACK: [data]
```

この例では、6つの並列`deploystacks`トリガージョブを生成します。各ジョブで、`PROVIDER`と`STACK`に異なる値を指定し、これらの変数を使用して6つの異なる子パイプラインを作成します。

```plaintext
deploystacks: [aws, monitoring]
deploystacks: [aws, app1]
deploystacks: [ovh, monitoring]
deploystacks: [ovh, backup]
deploystacks: [gcp, data]
deploystacks: [vultr, data]
```

### 並列マトリクスジョブごとに異なるRunnerタグを選択する {#select-different-runner-tags-for-each-parallel-matrix-job}

Runnerを動的に選択するには、`parallel: matrix`で定義した変数を[`tags`](../yaml/_index.md#tags)キーワードと組み合わせて使用します。

```yaml
deploystacks:
  stage: deploy
  script:
    - bin/deploy
  parallel:
    matrix:
      - PROVIDER: aws
        STACK: [monitoring, app1]
      - PROVIDER: gcp
        STACK: [data]
  tags:
    - ${PROVIDER}-${STACK}
  environment: $PROVIDER/$STACK
```

### `parallel:matrix`ジョブからアーティファクトをフェッチする {#fetch-artifacts-from-a-parallelmatrix-job}

[`parallel:matrix`](../yaml/_index.md#parallelmatrix)で作成したジョブからアーティファクトをフェッチするには、[`dependencies`](../yaml/_index.md#dependencies)キーワードを使用します。`dependencies`の値には、ジョブ名を以下の形式の文字列で指定します。

```plaintext
<job_name> [<matrix argument 1>, <matrix argument 2>, ... <matrix argument N>]
```

たとえば、`RUBY_VERSION`が`2.7`で、`PROVIDER`が`aws`のジョブからアーティファクトをフェッチするには、次のようにします。

```yaml
ruby:
  image: ruby:${RUBY_VERSION}
  parallel:
    matrix:
      - RUBY_VERSION: ["2.5", "2.6", "2.7", "3.0", "3.1"]
        PROVIDER: [aws, gcp]
  script: bundle install

deploy:
  image: ruby:2.7
  stage: deploy
  dependencies:
    - "ruby: [2.7, aws]"
  script: echo hello
  environment: production
```

`dependencies`エントリを囲む引用符は必須です。

## 複数の並列ジョブが存在する状況でneedsを使用して特定の並列ジョブを指定する {#specify-a-parallelized-job-using-needs-with-multiple-parallelized-jobs}

{{< history >}}

- GitLab 16.3で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/254821)されました。

{{< /history >}}

複数の並列ジョブがある場合、[`needs:parallel:matrix`](../yaml/_index.md#needsparallelmatrix)で定義した変数を使用できます。

次に例を示します。

```yaml
linux:build:
  stage: build
  script: echo "Building linux..."
  parallel:
    matrix:
      - PROVIDER: aws
        STACK:
          - monitoring
          - app1
          - app2

mac:build:
  stage: build
  script: echo "Building mac..."
  parallel:
    matrix:
      - PROVIDER: [gcp, vultr]
        STACK: [data, processing]

linux:rspec:
  stage: test
  needs:
    - job: linux:build
      parallel:
        matrix:
          - PROVIDER: aws
            STACK: app1
  script: echo "Running rspec on linux..."

mac:rspec:
  stage: test
  needs:
    - job: mac:build
      parallel:
        matrix:
          - PROVIDER: [gcp, vultr]
            STACK: [data]
  script: echo "Running rspec on mac..."

production:
  stage: deploy
  script: echo "Running production..."
  environment: production
```

この例では、いくつかのジョブが生成されます。並列ジョブはそれぞれ異なる`PROVIDER`と`STACK`の値を持ちます。

- 3つの並列`linux:build`ジョブ:
  - `linux:build: [aws, monitoring]`
  - `linux:build: [aws, app1]`
  - `linux:build: [aws, app2]`
- 4つの並列`mac:build`ジョブ:
  - `mac:build: [gcp, data]`
  - `mac:build: [gcp, processing]`
  - `mac:build: [vultr, data]`
  - `mac:build: [vultr, processing]`
- 1つの`linux:rspec`ジョブ。
- 1つの`production`ジョブ。

これらのジョブには、次の3つの実行パスがあります。

- Linuxパス: `linux:rspec`ジョブは、`mac:build`の完了を待たずに、`linux:build: [aws, app1]`ジョブが完了するとすぐに実行されます。
- macOSパス: `mac:rspec`ジョブは、`linux:build`の完了を待たずに、`mac:build: [gcp, data]`ジョブと`mac:build: [vultr, data]`ジョブが完了するとすぐに実行されます。
- `production`ジョブは、それ以前のすべてのジョブが完了するとすぐに実行されます。

## 並列ジョブ間のneedsを指定する {#specify-needs-between-parallelized-jobs}

[`needs:parallel:matrix`](../yaml/_index.md#needsparallelmatrix)を使用すると、各並列マトリクスジョブの実行順序をさらに定義できます。

次に例を示します。

```yaml
build_job:
  stage: build
  script:
    # ensure that other parallel job other than build_job [1, A] runs longer
    - '[[ "$VERSION" == "1" && "$MODE" == "A" ]] || sleep 30'
    - echo build $VERSION $MODE
  parallel:
    matrix:
      - VERSION: [1,2]
        MODE: [A, B]

deploy_job:
  stage: deploy
  script: echo deploy $VERSION $MODE
  parallel:
    matrix:
      - VERSION: [3,4]
        MODE: [C, D]

'deploy_job: [3, D]':
  stage: deploy
  script: echo something
  needs:
  - 'build_job: [1, A]'
```

この例では、いくつかのジョブが生成されます。並列ジョブはそれぞれ異なる`VERSION`と`MODE`の値を持ちます。

- 4つの並列`build_job`ジョブ:
  - `build_job: [1, A]`
  - `build_job: [1, B]`
  - `build_job: [2, A]`
  - `build_job: [2, B]`
- 4つの並列`deploy_job`ジョブ:
  - `deploy_job: [3, C]`
  - `deploy_job: [3, D]`
  - `deploy_job: [4, C]`
  - `deploy_job: [4, D]`

`deploy_job: [3, D]`ジョブは、他の`build_job`ジョブの完了を待たずに、`build_job: [1, A]`ジョブが完了するとすぐに実行されます。

## トラブルシューティング {#troubleshooting}

### 手動ジョブ実行時のユーザー割り当ての不整合 {#inconsistent-user-assignment-when-running-manual-jobs}

まれに、手動ジョブを実行したユーザーが、その手動ジョブに依存する後続ジョブの実行ユーザーとして割り当てられないことがあります。

手動ジョブに依存するジョブに割り当てられるユーザーについて厳格なセキュリティを確保する必要がある場合は、[その手動ジョブを保護する](#protect-manual-jobs)必要があります。
