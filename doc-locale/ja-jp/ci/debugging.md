---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CD パイプラインのデバッグ
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabには、CI/CD設定のデバッグを容易にするためのツールがいくつか用意されています。

パイプラインのイシューを解決できない場合は、以下からヘルプを得られます。

- [GitLab コミュニティフォーラム](https://forum.gitlab.com/)
- GitLab [サポート](https://about.gitlab.com/support/)

特定の CI/CD 機能でイシューが発生している場合は、その機能に関するトラブルシューティングのセクションを参照してください。

- [キャッシュ](caching/_index.md#troubleshooting)。
- [CI/CD ジョブトークン](jobs/ci_job_token.md#troubleshooting)。
- [コンテナレジストリ](../user/packages/container_registry/troubleshoot_container_registry.md)。
- [Docker](docker/using_docker_build.md#troubleshooting)。
- [ダウンストリームパイプライン](pipelines/downstream_pipelines_troubleshooting.md)。
- [環境](environments/_index.md#troubleshooting)。
- [GitLab Runner](https://docs.gitlab.com/runner/faq/)。
- [ID トークン](secrets/id_token_authentication.md#troubleshooting)。
- [ジョブ](jobs/job_troubleshooting.md)。
- [ジョブログアーティファクト](jobs/job_artifacts_troubleshooting.md)。
- [マージリクエストパイプライン](pipelines/mr_pipeline_troubleshooting.md)、[マージ結果パイプライン](pipelines/merged_results_pipelines.md#troubleshooting)、および[マージトレイン](pipelines/merge_trains.md#troubleshooting)。
- [パイプラインエディタ](pipeline_editor/_index.md#troubleshooting)。
- [変数](variables/_index.md#troubleshooting)。
- [YAML `includes` キーワード](yaml/includes.md#troubleshooting)。
- [YAML `script` キーワード](yaml/script.md#troubleshooting)。

## デバッグ手法

### 構文の検証

問題の初期段階の原因は、不適切な構文である可能性があります。構文またはフォーマットの問題が見つかった場合、パイプラインには`yaml invalid` バッジが表示され、実行が開始されません。

#### パイプラインエディターで`.gitlab-ci.yml` を編集

[パイプラインエディター](pipeline_editor/_index.md)は、(シングルファイルエディターや Web IDE ではなく) 推奨される編集エクスペリエンスです。これは以下を含みます:

- 受け入れられたキーワードのみを使用するようにコード補完候補を提案します。
- 自動構文ハイライトと検証。
- [CI/CD 設定の可視化](pipeline_editor/_index.md#visualize-ci-configuration)、`.gitlab-ci.yml` ファイルのグラフィカルな表現。

#### `.gitlab-ci.yml` をローカルで編集

パイプライン設定をローカルで編集する場合は、エディターで GitLab CI/CD スキーマを使用して基本的な構文のイシューを検証できます。[SchemaStore をサポートするエディター](https://www.schemastore.org/json/#editors)は、デフォルトで GitLab CI/CD スキーマを使用します。

スキーマに直接リンクする必要がある場合は、次の URL を使用します。

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/editor/schema/ci.json
```

CI/CD スキーマでカバーされるカスタムtag の完全なリストを表示するには、スキーマの最新バージョンを確認してください。

#### CI Lint ツールで構文を検証する

[CI Lint ツール](yaml/lint.md)を使用すると、CI/CD 設定スニペットの構文が正しいことを検証できます。基本的な構文を検証するために、完全な`.gitlab-ci.yml` ファイルまたは個々のジョブ設定を貼り付けます。

プロジェクトに`.gitlab-ci.yml` ファイルが存在する場合は、CI Lint ツールを使用して[完全なパイプラインの作成をシミュレート](yaml/lint.md#simulate-a-pipeline)することもできます。設定構文をより深く検証します。

### パイプライン名を使用する

[`workflow:name`](yaml/_index.md#workflowname)を使用してすべてのパイプラインタイプに名前を付けると、パイプラインリストでパイプラインを簡単に識別できます。次に例を示します:

```yaml
variables:
  PIPELINE_NAME: "Default pipeline name"

workflow:
  name: '$PIPELINE_NAME'
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      variables:
        PIPELINE_NAME: "Merge request pipeline"
    - if: '$CI_PIPELINE_SOURCE == "schedule" && $PIPELINE_SCHEDULE_TYPE == "hourly_deploy"'
      variables:
        PIPELINE_NAME: "Hourly deployment pipeline"
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
      variables:
        PIPELINE_NAME: "Other scheduled pipeline"
    - if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'
      variables:
        PIPELINE_NAME: "Default branch pipeline"
    - if: '$CI_COMMIT_BRANCH =~ /^\d{1,2}\.\d{1,2}-stable$/'
      variables:
        PIPELINE_NAME: "Stable branch pipeline"
```

### CI/CD変数

#### 変数の検証

CI/CD のトラブルシューティングの重要な部分は、どの変数がパイプラインに存在するか、またそれらの値がどうであるかを検証することです。パイプライン設定の多くは変数に依存しており、それらを確認することは、問題の原因を特定するための最も迅速な方法の 1 つです。

問題のある各ジョブで利用可能な[変数の完全なリストをエクスポート](variables/_index.md#list-all-variables)します。予期される変数が存在するかどうかを確認し、それらの値が予期どおりであるかどうかを確認します。

#### 変数を使用して CLI コマンドにフラグを追加する

標準パイプラインの実行では使用されないCI/CD変数を定義できますが、オンデマンドでデバッグに使用できます。次の例のように変数を追加すると、[パイプライン](pipelines/_index.md#run-a-pipeline-manually)または[個々のジョブ](jobs/job_control.md#run-a-manual-job)の手動実行中に変数を追加して、コマンドの動作を変更できます。次に例を示します:

```yaml
my-flaky-job:
  variables:
    DEBUG_VARS: ""
  script:
    - my-test-command $DEBUG_VARS /test-dirs
```

この例では、`DEBUG_VARS` は標準パイプラインではデフォルトで空白です。ジョブの動作をデバッグする必要がある場合は、パイプラインを手動で実行し、追加の出力のために`DEBUG_VARS`を`--verbose`に設定します。

### 依存関係

依存関係に関連するイシューは、パイプラインで予期しない問題が発生するもう 1 つの一般的な原因です。

#### 依存関係のバージョンを検証する

ジョブで正しいバージョンの依存関係が使用されていることを検証するには、メインスクリプトコマンドを実行する前に出力します。次に例を示します:

```yaml
job:
  before_script:
    - node --version
    - yarn --version
  script:
    - my-javascript-tests.sh
```

#### バージョンの固定

依存関係またはイメージの最新バージョンを常に使用したいと思うかもしれませんが、アップデートには予期しない破壊的な変更が含まれる可能性があります。予期しない変更を避けるために、キーとなる依存関係とイメージを固定することを検討してください。次に例を示します:

```yaml
variables:
  ALPINE_VERSION: '3.18.6'

job1:
  image: alpine:$ALPINE_VERSION  # This will never change unexpectedly
  script:
    - my-test-script.sh

job2:
  image: alpine:latest  # This might suddenly change
  script:
    - my-test-script.sh
```

重要なセキュリティアップデートが含まれている可能性があるため、依存関係とイメージのアップデートを定期的に確認する必要があります。次に、アップデートされたイメージまたは依存関係がパイプラインで引き続き動作することを検証するプロセスの一環として、バージョンを手動でアップデートできます。

### ジョブ出力を検証する

#### 出力を冗長にする

`--silent`を使用してジョブログの出力量を減らすと、ジョブで何が問題になったのかを特定することが難しくなる可能性があります。さらに、可能な場合は`--verbose`を使用して、詳細を追加することを検討してください。

```yaml
job1:
  script:
    - my-test-tool --silent         # If this fails, it might be impossible to identify the issue.
    - my-other-test-tool --verbose  # This command will likely be easier to debug.
```

#### 出力とレポートをアーティファクトとして保存する

一部のツールは、ジョブの実行中にのみ必要なファイルを生成する場合がありますが、これらのファイルの内容はデバッグに使用できます。[`artifacts`](yaml/_index.md#artifacts)を使用して後で分析するためにそれらを保存できます:

```yaml
job1:
  script:
    - my-tool --json-output my-output.json
  artifacts:
    paths:
      - my-output.json
```

[`artifacts:reports`](yaml/artifacts_reports.md) で構成されたレポートは、デフォルトではダウンロードできませんが、デバッグに役立つ情報が含まれている可能性もあります。これらのレポートを検査可能にするには、同じ手法を使用します:

```yaml
job1:
  script:
    - rspec --format RspecJunitFormatter --out rspec.xml
  artifacts:
    reports:
      junit: rspec.xml
    paths:
      - rspec.xmp
```

{{< alert type="warning" >}}

トークン、パスワード、その他の機密情報は、アーティファクトに保存しないでください。パイプラインへのアクセス権を持つすべてのユーザーが閲覧できる可能性があります。

{{< /alert >}}

### ジョブのコマンドをローカルで実行する

[Rancher Desktop](https://rancherdesktop.io/)などのツールまたは[同様の代替手段](https://handbook.gitlab.com/handbook/tools-and-tips/mac/#docker-desktop)を使用して、ジョブのコンテナイメージをローカルマシンで実行できます。次に、コンテナでジョブの`script`コマンドを実行し、動作を検証します。

### 根本原因分析で失敗したジョブの問題解決を行う

GitLab Duo Chat の GitLab Duo 根本原因分析を使用して、[失敗した CI/CD ジョブの問題解決](../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)を行えます。

## ジョブ設定のイシュー

一般的なパイプラインのイシューの多くは、`rules` または `only/except` の動作を分析することで修正できます。[ジョブをパイプラインに追加するタイミングを制御](jobs/job_control.md)するために使用される設定。これらの 2 つの設定は動作が異なるため、同じパイプラインで使用しないでください。この混合された動作でパイプラインがどのように実行されるかを予測することは困難です。`rules` はジョブの制御に適した選択肢であり、`only`と`except`はアクティブに開発されなくなりました。

`rules`または`only/except`設定で [定義済み変数](variables/predefined_variables.md) (たとえば、`CI_PIPELINE_SOURCE`、`CI_MERGE_REQUEST_ID`) を使用する場合は、トラブルシューティングの最初の手順として[それらを検証](#verify-variables)する必要があります。

### ジョブまたはパイプラインが予期したときに実行されない

`rules`または`only/except`キーワードは、ジョブをパイプラインに追加するかどうかを決定するものです。パイプラインは実行されるのに、ジョブがパイプラインに追加されない場合、通常は`rules`または`only/except`設定のイシューが原因です。

エラーメッセージが表示されず、パイプラインがまったく実行されないように見える場合も、`rules`または`only/except`設定、または`workflow: rules`キーワードが原因である可能性があります。

`only/except`から`rules`キーワードに変換している場合は、[`rules`の設定の詳細](yaml/_index.md#rules)を注意深く確認する必要があります。`only/except`と`rules`の動作は異なり、2 つの間で移行するときに予期しない動作が発生する可能性があります。

`rules`の[一般的な`if`句](jobs/job_rules.md#common-if-clauses-with-predefined-variables)は、期待どおりに動作するルールを記述する方法の例として非常に役立ちます。

パイプラインに`.pre`または`.post`ステージのジョブのみが含まれている場合、そのパイプラインは実行されません。別のステージに少なくとも 1 つの他のジョブが必要です。

### `.gitlab-ci.yml`ファイルにバイトオーダーマーク (BOM) が含まれている場合の予期しない動作

`.gitlab-ci.yml`ファイルまたはその他のインクルードされた設定ファイルにある[UTF-8 バイトオーダーマーク (BOM)](https://en.wikipedia.org/wiki/Byte_order_mark)は、パイプラインの動作が誤る原因となる可能性があります。バイトオーダーマークはファイルの解析に影響を与え、設定の一部が無視される原因となります。ジョブが欠落したり、変数の値が間違っている可能性があります。一部のテキストエディターは、そのように設定されている場合、BOM 文字を挿入する可能性があります。

パイプラインの動作がわかりにくい場合は、BOM 文字を表示できるツールを使用して、BOM 文字の存在を確認できます。パイプラインエディターは文字を表示できないため、外部ツールを使用する必要があります。詳細については、[イシュー 354026](https://gitlab.com/gitlab-org/gitlab/-/issues/354026) を参照してください。

### `changes` キーワードを持つジョブが予期せず実行される

ジョブがパイプラインに予期せず追加される一般的な理由の 1 つは、`changes`キーワードが特定の場合に常に true と評価されるためです。たとえば、`changes`は、スケジュールされたパイプラインや tag のパイプラインなど、特定のパイプラインタイプでは常に true です。

`changes`キーワードは、[`only/except`](yaml/_index.md#onlychanges--exceptchanges)または[`rules`](yaml/_index.md#ruleschanges)と組み合わせて使用されます。`changes`は、ジョブがブランチパイプラインまたはマージリクエストパイプラインにのみ追加されるようにする`rules`または`only/except`設定の`if`セクションでのみ使用することをお勧めします。

### 2 つのパイプラインが同時に実行される

コミットを、関連付けられているオープンマージリクエストを持つブランチにプッシュすると、2 つのパイプラインが実行される可能性があります。通常、一方のパイプラインはマージリクエストパイプラインであり、もう一方のパイプラインはブランチパイプラインです。

この状況は通常、`rules`設定が原因であり、[重複したパイプラインを防ぐ](jobs/job_rules.md#avoid-duplicate-pipelines)にはいくつかの方法があります。

### パイプラインが実行されないか、間違ったタイプのパイプラインが実行される

パイプラインを実行する前に、GitLab は設定内のすべてのジョブを評価し、使用可能なすべてのパイプラインタイプに追加しようとします。評価の最後にジョブが追加されない場合、パイプラインは実行されません。

パイプラインが実行されなかった場合は、すべてのジョブに`rules`または`only/except`があり、パイプラインに追加されなかった可能性があります。

間違ったパイプラインタイプが実行された場合は、ジョブが正しいパイプラインタイプに追加されるように、`rules`または`only/except`設定を確認する必要があります。たとえば、マージリクエストパイプラインが実行されなかった場合、ジョブが代わりにブランチパイプラインに追加された可能性があります。

[`workflow: rules`](yaml/_index.md#workflow)設定によってパイプラインがブロックされたり、間違ったパイプラインタイプが許可されたりする可能性もあります。

### ジョブ数の多いパイプラインが開始に失敗する

インスタンスで定義された[CI/CD 制限](../administration/settings/continuous_integration.md#set-cicd-limits)を超えるジョブを持つパイプラインは、開始に失敗します。

単一のパイプラインのジョブ数を減らすには、`.gitlab-ci.yml`設定を、より独立した[親子パイプライン](pipelines/pipeline_architectures.md#parent-child-pipelines)に分割できます。

## パイプラインの警告

パイプライン設定の警告は、以下の場合に表示されます。

- [CI Lint ツールで設定を検証する](yaml/lint.md)。
- [パイプラインを手動で実行する](pipelines/_index.md#run-a-pipeline-manually)。

### `Job may allow multiple pipelines to run for a single action`の警告

`if`句のない`when`句で[`rules`](yaml/_index.md#rules) を使用すると、複数のパイプラインが実行される可能性があります。通常、これは、関連付けられているオープンマージリクエストを持つブランチにコミットをプッシュするときに発生します。

[重複したパイプラインを防ぐ](jobs/job_rules.md#avoid-duplicate-pipelines)には、[`workflow: rules`](yaml/_index.md#workflow)を使用するか、実行できるパイプラインを制御するようにルールを書き換えます。

## パイプラインのエラー

### `A CI/CD pipeline must run and be successful before merge`メッセージ

プロジェクトで[**パイプラインは成功する必要があります**](../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)設定が有効になっており、パイプラインがまだ正常に実行されていない場合、このメッセージが表示されます。これは、パイプラインがまだ作成されていない場合、または外部 CI サービスを待機している場合にも当てはまります。

プロジェクトでパイプラインを使用しない場合は、マージリクエストを受け入れることができるように、**「パイプラインが成功する必要がある」**を無効にする必要があります。

### `Checking ability to merge automatically`メッセージ

マージリクエストが`Checking ability to merge automatically`メッセージで停止し、数分後に消えない場合は、次の回避策のいずれかを試すことができます。

- マージリクエストページを更新します。
- マージリクエストを閉じて再度開きます。
- `/rebase`[クイック アクション](../user/project/quick_actions.md)を使用して、マージリクエストをリベースします。
- マージリクエストをマージする準備ができていることをすでに確認している場合は、`/merge`クイック アクションを使用してマージできます。

このイシューは、GitLab 15.5 で[解決](https://gitlab.com/gitlab-org/gitlab/-/issues/229352)されました。

### `Checking pipeline status`メッセージ

マージリクエストが最新のコミットに関連付けられたパイプラインをまだ持っていない場合、このメッセージは回転状態アイコン({{< icon name="spinner" >}})とともに表示されます。これには次の原因が考えられます。

- GitLab がまだパイプラインの作成を完了していない。
- 外部 CI サービスを使用しており、GitLab はまだサービスからの返信を受け取っていません。
- プロジェクトで CI/CD パイプラインを使用していない。
- プロジェクトで CI/CD パイプラインを使用しているが、設定によってマージリクエストのソースブランチでパイプラインが実行されなくなっている。
- 最新のパイプラインが削除されました (これは[既知のイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/214323)です)。
- マージリクエストのソースブランチがプライベートフォーク上にある。

パイプラインが作成されると、メッセージはパイプラインの状態で更新されます。

これらのケースの一部では、[**パイプラインは成功する必要があります**](../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)の設定が有効になっている場合、アイコンが延々と回転したままメッセージが動かなくなることがあります。詳細については、[イシュー 334281](https://gitlab.com/gitlab-org/gitlab/-/issues/334281)を参照してください。

### `Project <group/project> not found or access denied`メッセージ

このメッセージは、[`include`](yaml/_index.md#include)で設定が追加されており、次のいずれかの条件に当てはまる場合に表示されます。

- 設定が、見つからないプロジェクトを参照している。
- パイプラインを実行しているユーザーが、含まれているプロジェクトにアクセスできない。

これを解決するには、以下を確認してください。

- プロジェクトのパスが`my-group/my-project`形式で、リポジトリにフォルダが含まれていない。
- パイプラインを実行しているユーザーが、含まれているファイルを含む[プロジェクトのメンバー](../user/project/members/_index.md#add-users-to-a-project)である。ユーザーは、同じプロジェクトで CI/CD ジョブを実行するための[権限](../user/permissions.md#cicd)も必要です。

### `The parsed YAML is too big`メッセージ

このメッセージは、YAML 設定が大きすぎるか、ネストが深すぎる場合に表示されます。多数のインクルードを含む YAML ファイル、および全体で数千行の YAML ファイルは、このメモリ制限に達する可能性が高くなります。たとえば、200 KB の YAML ファイルは、デフォルトのメモリ制限に達する可能性があります。

設定サイズを縮小するには、次の操作を実行します。

- パイプラインエディターの[完全な設定](pipeline_editor/_index.md#view-full-configuration)タブで、展開された CI/CD 設定の長さを確認します。削除または簡略化できる重複した設定を探します。
- 長い、または繰り返される `script` セクションを、プロジェクトのスタンドアロンスクリプトに移動します。
- [親子パイプライン](pipelines/downstream_pipelines.md#parent-child-pipelines)を使用して、一部の作業を独立した子パイプラインのジョブに移動します。

GitLab Self-Managed では、[サイズ制限を増やす](../administration/instance_limits.md#maximum-size-and-depth-of-cicd-configuration-yaml-files)ことができます。

### `.gitlab-ci.yml` ファイルの編集中に `500` エラーが発生する

[インクルードされた設定ファイルの loop](pipeline_editor/_index.md#configuration-validation-currently-not-available-message)は、[Web エディタ](../user/project/repository/web_editor.md)で `.gitlab-ci.yml` ファイルを編集するときに `500` エラーを引き起こす可能性があります。

インクルードされた設定ファイルが、相互の参照の loop を作成しないようにしてください。

### `Failed to pull image`メッセージ

{{< history >}}

- **CI_JOB_TOKEN でこのプロジェクトへのアクセスを許可する**設定は、GitLab 16.3 で[**このプロジェクト_への_アクセスを制限する**](https://gitlab.com/gitlab-org/gitlab/-/issues/411406)に名称変更されました。

{{< /history >}}

Runner は、CI/CD ジョブでコンテナイメージをプルしようとするときに、`Failed to pull image`メッセージを返すことがあります。

Runnerは、別のプロジェクトのコンテナレジストリから[`image`](yaml/_index.md#image)で定義されたコンテナイメージを取得する際、[CI/CDジョブトークン](jobs/ci_job_token.md)で認証します。

ジョブトークンの設定で、別のプロジェクトのコンテナレジストリへのアクセスが拒否されている場合、Runnerはエラーメッセージを返します。

次に例を示します:

- ```plaintext
  WARNING: Failed to pull image with policy "always": Error response from daemon: pull access denied for registry.example.com/path/to/project, repository does not exist or may require 'docker login': denied: requested access to the resource is denied
  ```

- ```plaintext
  WARNING: Failed to pull image with policy "": image pull failed: rpc error: code = Unknown desc = failed to pull and unpack image "registry.example.com/path/to/project/image:v1.2.3": failed to resolve reference "registry.example.com/path/to/project/image:v1.2.3": pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
  ```

これらのエラーは、次の両方が当てはまる場合に発生する可能性があります。

- イメージをホストしているプライベートプロジェクトで、[**このプロジェクト_への_アクセスを制限**](jobs/ci_job_token.md#limit-job-token-scope-for-public-or-internal-projects)オプションが有効になっている。
- イメージのフェッチを試みるジョブが、プライベートプロジェクトの許可リストにリストされていないプロジェクトで実行されている。

このイシューを解決するには、コンテナレジストリからイメージをフェッチするCI/CDジョブを持つプロジェクトを、ターゲットプロジェクトの[ジョブトークン許可リスト](jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)に追加します。

これらのエラーは、別のプロジェクトのイメージにアクセスするために[プロジェクトアクセストークン](../user/project/settings/project_access_tokens.md)を使用しようとした場合にも発生する可能性があります。プロジェクトアクセストークンは、1つのプロジェクトにスコープが設定されているため、他のプロジェクトのイメージにアクセスできません。より広いスコープで[別の種類のトークン](../security/tokens/_index.md)を使用する必要があります。

### パイプラインの実行中に`Something went wrong on our end`メッセージまたは`500`エラーが発生しました

次のパイプラインエラーが発生する可能性があります。

- プッシュまたはマージリクエストの作成時に`Something went wrong on our end`メッセージが表示される。
- APIを使用してパイプラインをトリガーすると、`500`エラーが発生する。

これらのエラーは、プロジェクトのインポート後に内部IDのレコードの同期が外れた場合に発生する可能性があります。

これを解決するには、[イシュー352382の回避策](https://gitlab.com/gitlab-org/gitlab/-/issues/352382#workaround)を参照してください。

### `config should be an array of hashes`エラーメッセージ

[`parallel:matrix`キーワード](yaml/_index.md#parallelmatrix)で[`!reference`tag](yaml/yaml_optimization.md#reference-tags)を使用すると、次のようなエラーが表示される場合があります。

```plaintext
This GitLab CI configuration is invalid: jobs:my_job_name:parallel:matrix config should be an array of hashes.
```

`parallel:matrix`キーワードは、複数の`!reference`tagを同時にサポートしていません。代わりに[YAMLアンカー](yaml/yaml_optimization.md#anchors)を使用してみてください。

[イシュー 439828](https://gitlab.com/gitlab-org/gitlab/-/issues/439828)では、`parallel:matrix`での`!reference`tagのサポートの改善が提案されています。
