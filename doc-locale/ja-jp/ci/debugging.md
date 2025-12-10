---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CDパイプラインのデバッグ
description: 設定の検証、警告、エラー、トラブルシューティング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabには、CI/CD設定のデバッグを容易にするためのツールがいくつか用意されています。

パイプラインの問題を解決できない場合は、以下からヘルプを得られます:

- [GitLabコミュニティフォーラム](https://forum.gitlab.com/)
- GitLab[サポート](https://about.gitlab.com/support/)

特定のCI/CD機能で問題が発生している場合は、その機能に関するトラブルシューティングのセクションを参照してください:

- [キャッシュ](caching/_index.md#troubleshooting)
- [CI/CDジョブトークン](jobs/ci_job_token.md#troubleshooting)
- [コンテナレジストリ](../user/packages/container_registry/troubleshoot_container_registry.md)
- [Docker](docker/docker_build_troubleshooting.md)
- [ダウンストリームパイプライン](pipelines/downstream_pipelines_troubleshooting.md)
- [環境](environments/_index.md#troubleshooting)
- [GitLab Runner](https://docs.gitlab.com/runner/faq/)
- [IDトークン](secrets/id_token_authentication.md#troubleshooting)
- [ジョブ](jobs/job_troubleshooting.md)
- [ジョブアーティファクト](jobs/job_artifacts_troubleshooting.md)
- [マージリクエストパイプライン](pipelines/mr_pipeline_troubleshooting.md)、[マージ結果パイプライン](pipelines/merged_results_pipelines.md#troubleshooting) 、および[マージトレイン](pipelines/merge_trains.md#troubleshooting)
- [パイプラインエディタ](pipeline_editor/_index.md#troubleshooting)
- [変数](variables/variables_troubleshooting.md)
- [YAMLの`includes`キーワード](yaml/includes.md#troubleshooting)
- [YAMLの`script`キーワード](yaml/script_troubleshooting.md)

## デバッグ手法 {#debugging-techniques}

### 構文を検証する {#verify-syntax}

問題の初期段階の原因は、不適切な構文である可能性があります。構文またはフォーマットの問題が見つかった場合、パイプラインには`yaml invalid`バッジが表示され、実行が開始されません。

#### `.gitlab-ci.yml`をパイプラインエディタで編集 {#edit-gitlab-ciyml-with-the-pipeline-editor}

[パイプラインエディタ](pipeline_editor/_index.md)は、（シングルファイルエディタやWeb IDEではなく）推奨される編集エクスペリエンスです。これには以下が含まれます:

- 受け入れられたキーワードのみを使用するためのコード補完の提案。
- 自動構文ハイライトと検証。
- [CI/CD設定の可視化](pipeline_editor/_index.md#visualize-ci-configuration)、`.gitlab-ci.yml`ファイルのグラフィカルな表現。

#### `.gitlab-ci.yml`をローカルで編集する {#edit-gitlab-ciyml-locally}

パイプライン設定をローカルで編集する場合は、エディタでGitLab CI/CDスキーマを使用して構文の基本的な問題を検証できます。[SchemaStoreをサポートするエディタ](https://www.schemastore.org/)では、デフォルトでGitLab CI/CDスキーマが使用されます。

スキーマに直接リンクする必要がある場合は、次のURLを使用します:

```plaintext
https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/editor/schema/ci.json
```

CI/CDスキーマでカバーされるカスタムタグの完全なリストを表示するには、スキーマの最新バージョンを確認してください。

#### CI Lintツールで構文を検証する {#verify-syntax-with-ci-lint-tool}

[CI Lintツール](yaml/lint.md)を使用すると、CI/CD設定スニペットの構文が正しいことを検証できます。基本的な構文を検証するために、完全な`.gitlab-ci.yml`ファイルまたは個々のジョブ設定を貼り付けます。

プロジェクトに`.gitlab-ci.yml`ファイルが存在する場合は、CI Lintツールを使用して[完全なパイプラインの作成をシミュレート](yaml/lint.md#simulate-a-pipeline)することもできます。これにより、設定構文をより深く検証できます。

### パイプライン名を使用する {#use-pipeline-names}

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

### CI/CD変数 {#cicd-variables}

#### 変数を検証する {#verify-variables}

CI/CDのトラブルシューティングの重要な部分は、どの変数がパイプラインに存在していて、どのような値を持っているか検証することです。パイプライン設定の多くは変数に依存しており、それらを検証することは、問題の原因を特定するための最も迅速な方法の1つです。

問題のある各ジョブで利用可能な[変数の完全なリストをエクスポート](variables/variables_troubleshooting.md#list-all-variables)します。予期される変数が存在するかどうかを確認し、それらの値が予想どおりであるかどうかを確認します。

#### 変数を使用してCLIコマンドにフラグを追加する {#use-variables-to-add-flags-to-cli-commands}

標準のパイプライン実行では使用されないが、オンデマンドでデバッグに使用できるCI/CD変数を定義できます。次の例のように変数を追加すると、[パイプライン](pipelines/_index.md#run-a-pipeline-manually)または[個々のジョブ](jobs/job_control.md#run-a-manual-job)の手動実行中に変数を追加して、コマンドの動作を変更できます。次に例を示します:

```yaml
my-flaky-job:
  variables:
    DEBUG_VARS: ""
  script:
    - my-test-command $DEBUG_VARS /test-dirs
```

この例では、`DEBUG_VARS`は標準のパイプラインではデフォルトで空白です。ジョブの動作をデバッグする必要がある場合は、パイプラインを手動で実行し、追加の出力のために`DEBUG_VARS`を`--verbose`に設定します。

### 依存関係 {#dependencies}

依存関係に関連する問題は、パイプラインで予期しない問題が発生するもう1つの一般的な根本原因です。

#### 依存関係のバージョンを検証する {#verify-dependency-versions}

ジョブで正しいバージョンの依存関係が使用されていることを検証するには、メインスクリプトコマンドを実行する前に依存関係を出力します。次に例を示します:

```yaml
job:
  before_script:
    - node --version
    - yarn --version
  script:
    - my-javascript-tests.sh
```

#### バージョンを固定する {#pin-versions}

依存関係やイメージの最新バージョンを常に使用したいと思うかもしれませんが、アップデートには予期しない破壊的な変更が含まれる可能性があります。予期しない変更を避けるために、主要な依存関係とイメージを固定することを検討してください。次に例を示します:

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

重要なセキュリティアップデートが含まれている可能性があるため、依存関係とイメージのアップデートを定期的に確認する必要があります。その後、アップデートされたイメージや依存関係がパイプラインで引き続き動作することを検証するプロセスの一環として、バージョンを手動でアップデートできます。

### ジョブ出力を検証する {#verify-job-output}

#### 出力を冗長にする {#make-output-verbose}

`--silent`を使用してジョブログの出力量を減らすと、ジョブで何が問題になったのかを特定することが難しくなる可能性があります。また、可能な場合は`--verbose`を使用して、詳細を追加することを検討してください。

```yaml
job1:
  script:
    - my-test-tool --silent         # If this fails, it might be impossible to identify the issue.
    - my-other-test-tool --verbose  # This command will likely be easier to debug.
```

#### 出力とレポートをアーティファクトとして保存する {#save-output-and-reports-as-artifacts}

一部のツールは、ジョブの実行中にのみ必要となるファイルを生成しますが、これらのファイルの内容をデバッグに使用できる場合があります。[`artifacts`](yaml/_index.md#artifacts)を使って後で分析するために、それらのファイルを保存することができます:

```yaml
job1:
  script:
    - my-tool --json-output my-output.json
  artifacts:
    paths:
      - my-output.json
```

[`artifacts:reports`](yaml/artifacts_reports.md)で設定されたレポートは、デフォルトではダウンロードできませんが、デバッグに役立つ情報を含んでいる可能性もあります。これらのレポートを検査可能にするには、同じ手法を使用します:

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

### ジョブのコマンドをローカルで実行する {#run-the-jobs-commands-locally}

[Rancher Desktop](https://rancherdesktop.io/)などのツールまたは類似の代替手段を使用して、ジョブのコンテナイメージをローカルマシンで実行できます。その後、コンテナでジョブの`script`コマンドを実行し、動作を検証します。

### 根本原因分析を通じて失敗したジョブの問題を解決する {#troubleshoot-a-failed-job-with-root-cause-analysis}

GitLab Duo ChatのGitLab Duo根本原因分析を使用すれば、[失敗したCI/CDジョブの問題を解決する](../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)ことができます。

## ジョブ設定の問題 {#job-configuration-issues}

[ジョブをパイプラインに追加するタイミングを制御](jobs/job_control.md)するために使用される`rules`または`only/except`の設定の動作を分析することで、パイプラインの一般的な問題の多くを修正できます。これらの2つの設定は動作が異なるため、同じパイプラインで使用しないでください。この混合動作でパイプラインがどのように実行されるかを予測することは困難です。`only`と`except`は積極的に開発されなくなったため、ジョブを制御するには、`rules`が望ましい選択肢になります。

`rules`または`only/except`の設定で[定義済み変数](variables/predefined_variables.md)（`CI_PIPELINE_SOURCE`や`CI_MERGE_REQUEST_ID`など）を使用する場合は、トラブルシューティングの最初の手順として[それらを検証する](#verify-variables)必要があります。

### ジョブまたはパイプラインが予期したときに実行されない {#jobs-or-pipelines-dont-run-when-expected}

`rules`または`only/except`キーワードにより、ジョブをパイプラインに追加するかどうかが決定されます。パイプラインは実行されるのに、ジョブがパイプラインに追加されない場合、通常は`rules`または`only/except`の設定問題が原因です。

エラーメッセージが表示されず、パイプラインがまったく実行されないように見える場合も、`rules`または`only/except`の設定、または`workflow: rules`キーワードが原因である可能性があります。

`only/except`から`rules`キーワードに変換している場合は、[`rules`の設定の詳細](yaml/_index.md#rules)を注意深く確認する必要があります。`only/except`と`rules`の動作は異なり、これらの2つの間で移行すると、予期しない動作が発生する可能性があります。

[`rules`の一般的な`if`句](jobs/job_rules.md#common-if-clauses-with-predefined-variables)は、期待どおりに動作するルールを記述する方法の例として非常に有用です。

パイプラインに`.pre`ステージまたは`.post`ステージのジョブのみが含まれている場合、パイプラインは実行されません。別のステージに少なくとも1つのジョブが必要です。

### `.gitlab-ci.yml`ファイルにバイトオーダーマーク（BOM）が含まれている場合の予期しない動作 {#unexpected-behavior-when-gitlab-ciyml-file-contains-a-byte-order-mark-bom}

`.gitlab-ci.yml`ファイルまたはその他のインクルードされた設定ファイルにある[UTF-8バイトオーダーマーク（BOM）](https://en.wikipedia.org/wiki/Byte_order_mark)は、パイプラインの誤った動作の原因となる可能性があります。バイトオーダーマークはファイルの解析に影響を与え、設定の一部が無視される原因となります。ジョブが欠落したり、変数が誤った値を持ったりする可能性があります。一部のテキストエディタがBOM文字を挿入する（そのように設定されている場合）可能性があります。

パイプラインの動作がわかりにくい場合は、BOM文字を表示できるツールを使用して、BOM文字の存在を確認できます。パイプラインエディタは文字を表示できないため、外部ツールを使用する必要があります。詳細については、[イシュー354026](https://gitlab.com/gitlab-org/gitlab/-/issues/354026)を参照してください。

### `changes`キーワードを持つジョブが予期せずに実行される {#a-job-with-the-changes-keyword-runs-unexpectedly}

ジョブがパイプラインに予期せずに追加される一般的な理由の1つは、特定の場合に`changes`キーワードが常にtrueと評価されるためです。たとえば、`changes`は、スケジュールされたパイプラインやタグのパイプラインなど、特定のパイプラインタイプでは常にtrueです。

`changes`キーワードは、[`only/except`](yaml/deprecated_keywords.md#onlychanges--exceptchanges)または[`rules`](yaml/_index.md#ruleschanges)と組み合わせて使用されます。`changes`は、ジョブがブランチパイプラインまたはマージリクエストパイプラインにのみ追加されるようにする`rules`または`only/except`の設定の`if`セクションでのみ使用することをお勧めします。

### 2つのパイプラインが同時に実行される {#two-pipelines-run-at-the-same-time}

関連付けられているオープンマージリクエストを持つブランチにコミットをプッシュすると、2つのパイプラインが実行される可能性があります。通常、一方のパイプラインはマージリクエストパイプラインであり、もう一方のパイプラインはブランチパイプラインです。

この状況は通常、`rules`設定が原因であり、[重複したパイプラインを防ぐ](jobs/job_rules.md#avoid-duplicate-pipelines)方法がいくつかあります。

### パイプラインが実行されないか、間違ったタイプのパイプラインが実行される {#no-pipeline-or-the-wrong-type-of-pipeline-runs}

パイプラインが実行できるようになる前に、GitLabは設定内のすべてのジョブを評価し、使用可能なすべてのパイプラインタイプにジョブを追加することを試みます。評価が終わったときにジョブが追加されない場合、パイプラインは実行されません。

パイプラインが実行されなかった場合は、すべてのジョブに`rules`または`only/except`があり、そのためにパイプラインに追加されなかった可能性があります。

間違ったパイプラインタイプが実行された場合は、`rules`または`only/except`の設定を確認して、ジョブが正しいパイプラインタイプに追加されるようにする必要があります。たとえば、マージリクエストパイプラインが実行されなかった場合は、ジョブがブランチパイプラインに追加された可能性があります。

[`workflow: rules`](yaml/_index.md#workflow)の設定がパイプラインをブロックしたか、間違ったパイプラインタイプを許可した可能性もあります。

プルミラーリングを使用している場合は、[プルミラーリングパイプラインのトラブルシューティングエントリ](../user/project/repository/mirror/troubleshooting.md#pull-mirroring-is-not-triggering-pipelines)を確認してください。

### ジョブ数の多いパイプラインが開始に失敗する {#pipeline-with-many-jobs-fails-to-start}

インスタンスで定義された[CI/CDの制限](../administration/settings/continuous_integration.md#set-cicd-limits)を超えるジョブを持つパイプラインは、開始に失敗します。

単一のパイプラインのジョブ数を減らすには、`.gitlab-ci.yml`の設定を、より独立した[親子パイプライン](pipelines/pipeline_architectures.md#parent-child-pipelines)に分割できます。

## パイプラインの警告 {#pipeline-warnings}

パイプライン設定の警告は、以下を行った場合に表示されます:

- [CI Lintツールで設定を検証する](yaml/lint.md)。
- [パイプラインを手動で実行する](pipelines/_index.md#run-a-pipeline-manually)。

### `Job may allow multiple pipelines to run for a single action`警告 {#job-may-allow-multiple-pipelines-to-run-for-a-single-action-warning}

`if`句のない`when`句で[`rules`](yaml/_index.md#rules)を使用すると、複数のパイプラインが実行される可能性があります。通常、これは、関連付けられているオープンマージリクエストを持つブランチにコミットをプッシュすると発生します。

[重複したパイプラインを防ぐ](jobs/job_rules.md#avoid-duplicate-pipelines)には、[`workflow: rules`](yaml/_index.md#workflow)を使用するか、ルールを書き換えて、実行できるパイプラインを制御します。

## パイプラインのエラー {#pipeline-errors}

### `A CI/CD pipeline must run and be successful before merge`メッセージ {#a-cicd-pipeline-must-run-and-be-successful-before-merge-message}

プロジェクトで[**パイプラインが完了している**](../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)設定が有効になっており、パイプラインがまだ正常に実行されていない場合、このメッセージが表示されます。これは、パイプラインがまだ作成されていない場合、または外部CIサービスを待機している場合にも当てはまります。

プロジェクトでパイプラインを使用しない場合は、**パイプラインが完了している**を無効にして、マージリクエストを受け入れることができるようにする必要があります。

### `Checking ability to merge automatically`メッセージ {#checking-ability-to-merge-automatically-message}

マージリクエストが`Checking ability to merge automatically`メッセージで停止し、メッセージが数分後に消えない場合は、次の回避策のいずれかを試すことができます:

- マージリクエストページを更新します。
- マージリクエストを閉じて再度開きます。
- `/rebase`[クイックアクション](../user/project/quick_actions.md)を使用して、マージリクエストをリベースします。
- マージリクエストをマージする準備ができていることをすでに確認している場合は、`/merge`クイックアクションを使用してマージできます。

この問題は、GitLab 15.5で[解決](https://gitlab.com/gitlab-org/gitlab/-/issues/229352)されました。

### `Checking pipeline status`メッセージ {#checking-pipeline-status-message}

マージリクエストが、最新のコミットに関連付けられたパイプラインをまだ持っていない場合、このメッセージは回転状態アイコン（{{< icon name="spinner" >}}）とともに表示されます。これには次の原因が考えられます:

- GitLabがまだパイプラインの作成を完了していない。
- 外部CIサービスが使用されていて、GitLabはそのサービスからの返信をまだ受け取っていない。
- プロジェクトでCI/CDパイプラインを使用していない。
- プロジェクトでCI/CDパイプラインを使用しているが、設定によってマージリクエストのソースブランチでパイプラインが実行されなくなっている。
- 最新のパイプラインが削除されている（[既知の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/214323)）。
- マージリクエストのソースブランチがプライベートフォーク上にある。

パイプラインが作成されると、パイプラインステータスでメッセージが更新されます。

これらのケースの一部では、[**パイプラインが完了している**](../user/project/merge_requests/auto_merge.md#require-a-successful-pipeline-for-merge)設定が有効になっている場合、アイコンが延々と回転したままメッセージが動かなくなることがあります。詳細については、[イシュー334281](https://gitlab.com/gitlab-org/gitlab/-/issues/334281)を参照してください。

### `Project <group/project> not found or access denied`メッセージ {#project-groupproject-not-found-or-access-denied-message}

このメッセージは、[`include`](yaml/_index.md#include)で設定が追加されており、次のいずれかの条件に当てはまる場合に表示されます:

- 設定が、見つからないプロジェクトを参照している。
- パイプラインを実行しているユーザーが、含まれているプロジェクトにアクセスできない。

これを解決するには、以下を確認してください:

- プロジェクトのパスが`my-group/my-project`形式であり、リポジトリにフォルダーが含まれていない。
- パイプラインを実行しているユーザーが、含まれているファイルを含む[プロジェクトのメンバー](../user/project/members/_index.md#add-users-to-a-project)である。ユーザーは、同じプロジェクトでCI/CDジョブを実行するための[権限](../user/permissions.md#cicd)も必要です。

### `The parsed YAML is too big`メッセージ {#the-parsed-yaml-is-too-big-message}

このメッセージは、YAML設定が大きすぎるか、ネストが深すぎる場合に表示されます。多数のインクルードを含むYAMLファイル、および全体で数千行のYAMLファイルは、このメモリ制限に達する可能性が高くなります。たとえば、200 KBのYAMLファイルは、デフォルトのメモリ制限に達する可能性があります。

設定サイズを縮小するには、次の操作を実行します:

- パイプラインエディタの[完全な設定](pipeline_editor/_index.md#view-full-configuration)タブで、展開されたCI/CD設定の長さを確認します。削除または簡略化できる重複した設定を探します。
- 長い、または繰り返される`script`セクションを、プロジェクトのスタンドアロンスクリプトに移動します。
- [親子パイプライン](pipelines/downstream_pipelines.md#parent-child-pipelines)を使用して、一部の作業を独立した子パイプラインのジョブに移動します。

GitLab Self-Managedでは、[サイズ制限を増やす](../administration/instance_limits.md#maximum-size-and-depth-of-cicd-configuration-yaml-files)ことができます。

### `.gitlab-ci.yml`ファイルの編集中に`500`エラーが発生する {#500-error-when-editing-the-gitlab-ciyml-file}

インクルードされた設定ファイルのループは、[Webエディタ](../user/project/repository/web_editor.md)で`.gitlab-ci.yml`ファイルを編集するときに`500`エラーを引き起こす可能性があります。

インクルードされた設定ファイルが、相互の参照のループを作成しないようにしてください。

### `Failed to pull image`メッセージ {#failed-to-pull-image-messages}

{{< history >}}

- GitLab 16.3で、**Allow access to this project with a CI_JOB_TOKEN**（CI_JOB_TOKENでこのプロジェクトへのアクセスを許可する）設定の[名称が、**Limit access to this project**（このプロジェクトへのアクセスを制限）に変更](https://gitlab.com/gitlab-org/gitlab/-/issues/411406)されました。

{{< /history >}}

Runnerは、CI/CDジョブでコンテナイメージをプルしようとして、`Failed to pull image`メッセージを返すことがあります。

Runnerは、別のプロジェクトのコンテナレジストリから[`image`](yaml/_index.md#image)で定義されたコンテナイメージをフェッチする際、[CI/CDジョブトークン](jobs/ci_job_token.md)で認証します。

ジョブトークンの設定で、別のプロジェクトのコンテナレジストリへのアクセスが拒否されている場合、Runnerはエラーメッセージを返します。

次に例を示します:

- ```plaintext
  WARNING: Failed to pull image with policy "always": Error response from daemon: pull access denied for registry.example.com/path/to/project, repository does not exist or may require 'docker login': denied: requested access to the resource is denied
  ```

- ```plaintext
  WARNING: Failed to pull image with policy "": image pull failed: rpc error: code = Unknown desc = failed to pull and unpack image "registry.example.com/path/to/project/image:v1.2.3": failed to resolve reference "registry.example.com/path/to/project/image:v1.2.3": pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
  ```

これらのエラーは、次の両方が当てはまる場合に発生する可能性があります:

- イメージをホスティングしているプライベートプロジェクトで、[**Limit access to this project**（このプロジェクトへのアクセスを制限）](jobs/ci_job_token.md#limit-job-token-scope-for-public-or-internal-projects)オプションが有効になっている。
- イメージのフェッチを試みるジョブが、プライベートプロジェクトの許可リストにリストされていないプロジェクトで実行されている。

この問題を解決するには、コンテナレジストリからイメージをフェッチするCI/CDジョブを持つプロジェクトを、ターゲットプロジェクトの[ジョブトークン許可リスト](jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist)に追加します。

これらのエラーは、別のプロジェクトのイメージにアクセスするために[プロジェクトアクセストークン](../user/project/settings/project_access_tokens.md)を使用しようとした場合にも発生する可能性があります。プロジェクトアクセストークンは、1つのプロジェクトにスコープが設定されているため、他のプロジェクトのイメージにアクセスできません。より広いスコープで[別のトークンタイプ](../security/tokens/_index.md)を使用する必要があります。

#### ランダムまたは断続的な`Failed to pull image`エラー {#random-or-intermittent-failed-to-pull-image-errors}

CI/CDジョブで断続的な`Failed to pull image`エラーが発生することがあります。

この問題は、イメージにアクセスするユーザーの権限が異なっていることに加えて、Runnerがそれらのイメージをキャッシュする方法が原因で発生する可能性があります。ボットユーザーは他のプロジェクトメンバーとは異なる権限を持っていることが多いため、一般的にボットユーザーが影響を受けます。

たとえば、パイプラインイメージは、別のプロジェクトのコンテナレジストリでホスティングされている可能性があります。すべてのユーザーが両方のプロジェクトにアクセスできる場合、これは問題ではありません。しかし、ユーザー（ボットユーザーなど）が、イメージをホスティングしているプロジェクトにアクセスできない場合、`Failed to pull image`エラーが発生する可能性があります。

イメージにアクセスする権限を持つユーザーのためにRunnerがイメージを正常にフェッチしてキャッシュすると、このエラーは断続的になります。このRunnerはイメージを利用できるようになり、別のプロジェクトにアクセスしてイメージをフェッチする必要はなくなりました。他のプロジェクトへのアクセス権限を持たないユーザーを含め、すべてのユーザーがこのイメージでCI/CDジョブを実行できます。ただし、Runnerがイメージをフェッチしてキャッシュしたことがない場合、イメージプロジェクトにアクセスする権限がないユーザーは、`Failed to pull image`エラーを受け取ります。

この問題を解決するには、パイプラインを実行するすべてのユーザー（ボットユーザーを含む）が、プルされたイメージをホスティングするプロジェクトにアクセスできるようにする必要があります。

### パイプライン実行時の`Something went wrong on our end`メッセージまたは`500`エラー {#something-went-wrong-on-our-end-message-or-500-error-when-running-a-pipeline}

次のパイプラインエラーが発生する可能性があります:

- マージリクエストをプッシュまたは作成すると、`Something went wrong on our end`メッセージが表示される。
- APIを使用してパイプラインをトリガーすると、`500`エラーが発生する。

これらのエラーは、プロジェクトのインポート後に内部IDのレコードの同期が外れた場合に発生する可能性があります。

これを解決するには、[イシュー352382の回避策](https://gitlab.com/gitlab-org/gitlab/-/issues/352382#workaround)を参照してください。

### `config should be an array of hashes`エラーメッセージ {#config-should-be-an-array-of-hashes-error-message}

[`parallel:matrix`キーワード](yaml/_index.md#parallelmatrix)で[`!reference`タグ](yaml/yaml_optimization.md#reference-tags)を使用すると、次のようなエラーが表示される場合があります:

```plaintext
This GitLab CI configuration is invalid: jobs:my_job_name:parallel:matrix config should be an array of hashes.
```

`parallel:matrix`キーワードでは、同時に複数の`!reference`タグを使用することはサポートされていません。代わりに[YAMLアンカー](yaml/yaml_optimization.md#anchors)を使用してみてください。

[イシュー439828](https://gitlab.com/gitlab-org/gitlab/-/issues/439828)で、`parallel:matrix`での`!reference`タグのサポートの改善が提案されています。
