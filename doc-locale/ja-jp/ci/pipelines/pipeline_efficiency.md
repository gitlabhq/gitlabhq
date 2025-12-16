---
stage: Verify
group: Pipeline Execution
info: This page is maintained by Developer Relations, author @dnsmichi, see https://handbook.gitlab.com/handbook/marketing/developer-relations/developer-advocacy/content/#maintained-documentation
title: パイプライン効率性
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[CI/CDパイプライン](_index.md)は、[GitLab CI/CD](../_index.md)の基本的な構成要素です。パイプラインの効率化は、デベロッパーの時間の節約につながり、次の効果があります:

- DevOpsプロセスをスピードアップする
- コストを削減する
- 開発フィードバックループを短縮する

新しいチームやプロジェクトが、遅くて非効率なパイプラインから開始し、試行錯誤を重ねて徐々に設定を改善していくことはよくあります。より良いプロセスは、効率性をすぐに改善するパイプライン機能を使用し、より早い段階でより迅速なソフトウェア開発ライフサイクルを実現することです。

まず、[GitLab CI/CDの基礎](../_index.md)を十分に理解し、[クイックスタートガイド](../quick_start/_index.md)を確認しておきましょう。

## ボトルネックとよくある失敗を特定する {#identify-bottlenecks-and-common-failures}

非効率なパイプラインを確認する最も簡単な指標は、ジョブやステージの実行時間、およびパイプライン自体の合計実行時間です。パイプラインの合計所要時間は、次の要因に大きく左右されます:

- [リポジトリのサイズ](../../user/project/repository/monorepos/_index.md)
- ステージとジョブの総数
- ジョブ間の依存関係
- 最短および最長のパイプライン所要時間を示す[「クリティカルパス」](#needs-dependency-visualization)

注意すべきその他の点は、[GitLab Runner](../runners/_index.md)に関連しています:

- Runnerの利用可能性と、Runnerにプロビジョニングされたリソース。
- ビルドの依存関係、インストール時間、ストレージ容量の要件。
- [コンテナイメージのサイズ](#docker-images)。
- ネットワークのレイテンシーと低速の接続。

パイプラインがむやみに何度も失敗すると、開発ライフサイクルの速度が低下する原因にもなります。失敗したジョブについて問題のあるパターンを探す必要があります:

- ランダムに失敗したり、信頼性の低いテスト結果を生成したりするFlaky（不安定）な単体テスト。
- その挙動に関連するテストカバレッジの低下とコード品質。
- 無視しても安全であるにもかかわらず、パイプラインを停止させる失敗。
- 本来は早いステージで検出できるにもかかわらず、長いパイプラインの最後で失敗してフィードバックが遅れるテスト。

## パイプライン分析 {#pipeline-analysis}

パイプラインのパフォーマンスを分析して、効率性を改善する方法を見つけます。分析は、CI/CDインフラストラクチャの潜在的なブロッカーを特定するのに役立ちます。これには、次の分析が含まれます:

- ジョブのワークロード
- 実行時間のボトルネック
- パイプラインの全体的なアーキテクチャ

パイプラインのワークフローを理解して文書化し、取り得る行動と変更について話し合うことが重要です。パイプラインのリファクタリングを行う場合は、DevSecOpsライフサイクルにおけるチーム間の慎重な連携が必要になる場合があります。

パイプライン分析は、コスト効率の問題を特定するのに役立ちます。たとえば、有料のクラウドサービスでホストされている[Runner](../runners/_index.md)は、次のような状態でプロビジョニングされている場合があります:

- CI/CDパイプラインに必要以上のリソースが割り当てられ、コストをムダにしている。
- リソースが不足しており、実行速度が遅く、時間をムダにしている。

### パイプラインのインサイト {#pipeline-insights}

[パイプラインの成功と所要時間チャート](_index.md#pipeline-success-and-duration-charts)は、パイプラインの実行時間と失敗したジョブの数に関する情報を提供します。

[単体テスト](../testing/unit_test_reports.md) 、結合テスト、E2Eテスト、[コード品質](../testing/code_quality.md)テストなどのテストを実行すると、CI/CDパイプラインによって問題が自動的に検出されます。多くのパイプラインステージが関わると、実行時間が長くなる場合があります。

同じステージで異なる項目をテストするジョブを並列実行することで効率を改善し、全体の実行時間を短縮できます。ただし、その場合は並列ジョブをサポートするために、より多くのRunnerを同時に稼働させる必要があります。

### `needs`の依存関係の可視化 {#needs-dependency-visualization}

[パイプライングラフ全体](_index.md#group-jobs-by-stage-or-needs-configuration)で`needs`の依存関係を表示すると、パイプラインのクリティカルパスを分析し、発生し得るブロッカーを把握するのに役立ちます。

### パイプラインのモニタリング {#pipeline-monitoring}

グローバルパイプラインの健全性は、ジョブとパイプラインの所要時間とともにモニタリングする重要な指標です。[CI/CD分析](_index.md#pipeline-success-and-duration-charts)は、パイプラインの健全性を視覚的に表現します。

インスタンス管理者は、追加の[パフォーマンスメトリクスとセルフモニタリング](../../administration/monitoring/_index.md)にアクセスできます。

[API](../../api/rest/_index.md)から特定のパイプラインの健全性メトリクスをフェッチできます。外部のモニタリングツールは、APIをポーリングしてパイプラインの健全性を検証したり、長期的なSLA分析用のメトリクスを収集したりできます。

たとえば、Prometheus用の[GitLab CI Pipelines Exporter](https://github.com/mvisonneau/gitlab-ci-pipelines-exporter)は、APIおよびパイプラインイベントからメトリクスをフェッチします。プロジェクト内のブランチを自動的に確認し、パイプラインのステータスと所要時間を取得できます。Grafanaダッシュボードと組み合わせることで、運用チームの行動につながる実用的なビューを構築できます。メトリクスグラフはインシデントに埋め込むこともできるため、問題解決が容易になります。さらに、ジョブと環境に関するメトリクスをエクスポートすることもできます。

GitLab CI Pipelines Exporterを使用する場合は、[設定サンプル](https://github.com/mvisonneau/gitlab-ci-pipelines-exporter/blob/main/docs/configuration_syntax.md)を参考にして始めることをおすすめします。

![GrafanaダッシュボードにCIの実行ステータス、頻度や失敗率などの履歴統計が表示されています。](img/ci_efficiency_pipeline_health_grafana_dashboard_v13_7.png)

または、[`check_gitlab`](https://gitlab.com/6uellerBpanda/check_gitlab)などのスクリプトを実行できるモニタリングツールを使用することもできます。

#### Runnerのモニタリング {#runner-monitoring}

ホストシステム、またはKubernetesなどのクラスターで[CI Runnerをモニタリング](https://docs.gitlab.com/runner/monitoring/)することもできます。次のような項目をチェックします:

- ディスクとディスクIO
- CPU使用率
- メモリ
- Runnerプロセスのリソース

[Prometheus Node Exporter](https://prometheus.io/docs/guides/node-exporter/)はLinuxホスト上のRunnerをモニタリングでき、[`kube-state-metrics`](https://github.com/kubernetes/kube-state-metrics)はKubernetesクラスターで動作します。

クラウドプロバイダーで[GitLab Runnerの自動スケーリング](https://docs.gitlab.com/runner/configuration/autoscale.html)をテストしたり、コストを削減するためにオフライン時間を定義したりすることもできます。

#### ダッシュボードとインシデント管理 {#dashboards-and-incident-management}

既存のモニタリングツールとダッシュボードを使用してCI/CDパイプラインのモニタリングを統合することも、ゼロから構築することもできます。ランタイムデータをチームにとって有用で行動に結び付くものにして、オペレーション/サイトリライアビリティエンジニアリング（SRE）チームが問題を早期に特定できるようにします。[インシデント管理](../../operations/incident_management/_index.md)もここで役立ち、問題を分析するための埋め込みメトリクスチャートと重要な詳細をすべて提供します。

### ストレージ使用量 {#storage-usage}

コストと効率性を分析するために、次のストレージの使用量を確認します:

- [ジョブアーティファクト](../jobs/job_artifacts.md)とその[`expire_in`](../yaml/_index.md#artifactsexpire_in)設定。保存期間が長すぎると、ストレージの使用量が増加し、パイプラインの速度が低下する可能性があります。
- [コンテナレジストリ](../../user/packages/container_registry/_index.md)の使用量。
- [パッケージレジストリ](../../user/packages/package_registry/_index.md)の使用量。

## パイプライン設定 {#pipeline-configuration}

パイプラインを高速化し、リソースの使用量を低減するために、パイプラインを設定する際は慎重に選択してください。これには、GitLab CI/CDの組み込み機能を活用し、パイプラインをより速く、より効率的に実行することが含まれます。

### ジョブの実行頻度を減らす {#reduce-how-often-jobs-run}

すべての状況で実行する必要がないジョブを特定し、パイプライン設定を使用してそれらのジョブが実行されないようにします:

- [`interruptible`](../yaml/_index.md#interruptible)キーワードを使用して、古いパイプラインが新しいパイプラインに置き換えられたときに古いパイプラインを停止する。
- [`rules`](../yaml/_index.md#rules)を使用して、不要なテストをスキップする。たとえば、フロントエンドコードのみが変更された場合はバックエンドテストをスキップします。
- 重要でない[スケジュールされたパイプライン](schedules.md)の実行頻度を減らす。
- [`cron`スケジュール](schedules.md#distribute-pipeline-schedules-to-prevent-system-load)を均等に分散させる。

### フェイルファスト {#fail-fast}

エラーがCI/CDパイプラインの早い段階で検出されるようにします。完了に非常に長い時間を要するジョブは、そのジョブが完了するまでパイプラインが失敗ステータスを返さない原因となります。

[フェイルファスト](../testing/fail_fast_testing.md)が可能なジョブが先に実行されるように、パイプラインを設計します。たとえば、アーリーステージを追加し、構文、スタイルLint、Gitコミットメッセージの検証などのジョブをそのステージに移動します。

実行が速いジョブから迅速なフィードバックを得る前に、長時間かかるジョブを早期に実行することが重要かどうかを判断します。初期段階で失敗すれば、残りのパイプラインを実行すべきでないことが明らかになり、パイプラインのリソースを節約できます。

### `needs`キーワード {#needs-keyword}

基本設定では、ジョブは常に、前のステージの他のすべてのジョブが完了するのを待ってから実行されます。これは最も単純な設定ですが、ほとんどの場合、実行時間が最も長くなります。[`needs`キーワードを含むパイプライン](../yaml/needs.md)と[親/子パイプライン](downstream_pipelines.md#parent-child-pipelines)はより柔軟で効率的ですが、パイプラインの理解と分析が難しくなることもあります。

### キャッシュ {#caching}

もう1つの最適化方法は、依存関係を[キャッシュ](../caching/_index.md)することです。依存関係がめったに変更されない場合（[NodeJSの`/node_modules`](../caching/_index.md#cache-nodejs-dependencies)など）、キャッシュを使用することでパイプラインの実行を大幅に高速化できます。

[`cache:when`](../yaml/_index.md#cachewhen)を使用すると、ジョブが失敗した場合でもダウンロード済みの依存関係をキャッシュできます。

### Dockerイメージ {#docker-images}

Dockerイメージのダウンロードと初期化は、ジョブ全体の実行時間の大部分を占める可能性があります。

Dockerイメージがジョブの実行速度を低下させている場合は、ベースイメージのサイズとレジストリへのネットワーク接続を分析します。GitLabをクラウドで実行している場合は、ベンダーが提供するクラウドコンテナレジストリの利用を検討してください。また、[GitLabコンテナレジストリ](../../user/packages/container_registry/_index.md)を使用すれば、他のレジストリよりもGitLabインスタンスから高速にアクセスできます。

#### Dockerイメージを最適化する {#optimize-docker-images}

最適化されたDockerイメージをビルドします。大きなDockerイメージは多くの容量を消費し、接続速度が遅い場合にはダウンロードに時間がかかるためです。可能であれば、すべてのジョブに1つの大きなイメージを使用することは避けてください。特定のタスクごとに複数の小さなイメージを使用し、より速くダウンロードして実行できるようにします。

ソフトウェアがプリインストールされたカスタムDockerイメージを使用してみてください。通常は、一般的なイメージを使用してソフトウェアを毎回インストールするよりも、事前設定済みの大きなイメージをダウンロードする方がはるかに高速です。[Dockerfile作成のベストプラクティス](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)に関するDockerの記事には、効率的なDockerイメージのビルド方法について詳しく記載されています。

Dockerイメージのサイズを縮小する方法:

- 小さなベースイメージを使用する（例: `debian-slim`）。
- どうしても必要な場合を除き、vimやcurlなどの便利なツールはインストールしない。
- 専用の開発イメージを作成する。
- 容量を節約するため、パッケージによってインストールされるmanページとドキュメントを無効にする。
- `RUN`レイヤーを減らし、複数のソフトウェアインストール手順をまとめる。
- [マルチステージビルド](https://blog.alexellis.io/mutli-stage-docker-builds/)を使用して、ビルダーパターンを使用する複数のDockerfileを1つのDockerfileにマージし、イメージサイズを縮小する。
- `apt`を使用している場合は、不要なパッケージを回避するために`--no-install-recommends`を追加する。
- 最後にキャッシュと不要になったファイルをクリーンアップする。例: DebianおよびUbuntuの場合は`rm -rf /var/lib/apt/lists/*`、RHELおよびCentOSの場合は`yum clean all`。
- [dive](https://github.com/wagoodman/dive)や[DockerSlim](https://github.com/docker-slim/docker-slim)などのツールを使用して、イメージを分析し、縮小する。

Dockerイメージの管理を簡素化するには、[Dockerイメージ](../docker/_index.md)を管理する専用グループを作成し、CI/CDパイプラインでそのイメージをテスト、ビルド、公開します。

## テスト、文書化、学習 {#test-document-and-learn}

パイプラインの改善は反復的なプロセスです。小さな変更を加え、その効果をモニタリングし、再度イテレーションを行います。多数の小さな改善を積み重ねることで、パイプラインの効率性が大幅に向上することがあります。

パイプラインの設計とアーキテクチャを文書化すると役立ちます。GitLabリポジトリで、[MarkdownのMermaidチャート](../../user/markdown.md#mermaid)を直接使用して文書化できます。

CI/CDパイプラインの問題やインシデントは、調査内容や見つかった解決策を含めてイシューに記録してください。新しいチームメンバーのオンボーディングに役立つとともに、CIパイプラインの効率性に関して繰り返し発生する問題も特定しやすくなります。

### 関連トピック {#related-topics}

- [CIモニタリングのWebキャストスライド](https://docs.google.com/presentation/d/1ONwIIzRB7GWX-WOSziIIv8fz1ngqv77HO1yVfRooOHM/edit?usp=sharing)
- GitLab.comモニタリングハンドブック
- [運用を可視化するためのダッシュボードの構築](https://aws.amazon.com/builders-library/building-dashboards-for-operational-visibility/)
