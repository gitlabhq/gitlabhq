---
stage: Verify
group: Pipeline Execution
info: This page is maintained by Developer Relations, author @dnsmichi, see https://handbook.gitlab.com/handbook/marketing/developer-relations/developer-advocacy/content/#maintained-documentation
title: パイプライン効率性
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 製品: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[CI/CDパイプライン](_index.md)は、[GitLab CI/CD](../_index.md)の基本的な構成要素です。パイプラインの効率化は、デベロッパーの時間の節約につながり、次の効果があります。

- DevOpsプロセスを迅速化する
- コストを削減する
- 開発フィードバックループを短縮する

新しいチームやプロジェクトが、遅くて非効率なパイプラインから開始し、試行錯誤を重ねて徐々に設定を改善していくことはよくあります。より良いプロセスは、効率性をすぐに改善するパイプライン機能を使用し、より早い段階でより迅速なソフトウェア開発ライフサイクルを実現することです。

まず、[GitLab CI/CDの基礎](../_index.md)を熟知し、[クイックスタートガイド](../quick_start/_index.md)を理解しましょう。

## ボトルネックとよくある失敗を特定する

非効率なパイプラインを確認する最も簡単な指標は、ジョブの実行時間、ステージ、およびパイプライン自体の合計実行時間です。パイプラインの合計所要時間は、次の影響を大きく受けます。

- [リポジトリのサイズ](../../user/project/repository/monorepos/_index.md)
- ステージとジョブの総数
- ジョブ間の依存関係
- 最小および最大のパイプライン所要時間を表す[「クリティカルパス」](#needs-dependency-visualization)

注意すべきその他の点は、[GitLab Runner](../runners/_index.md)に関連しています。

- Runnerの利用可能性と、Runnerのプロビジョニングに使用されているリソース
- ビルドの依存関係、インストール時間、およびストレージ容量の要件
- [コンテナイメージのサイズ](#docker-images)
- ネットワークのレイテンシーと低速の接続

パイプラインがむやみに何度も失敗すると、開発ライフサイクルの速度が低下する原因にもなります。失敗したジョブについて問題のあるパターンを探す必要があります。

- ランダムに失敗したり、信頼性の低いテスト結果を生成したりするFlakyユニットテスト
- テストカバレッジの低下とその動作と関連があるコード品質
- 安全に無視できるにもかかわらず、パイプラインを停止させる失敗
- より早い段階で実行できるはずなのに、長いパイプラインの最後で失敗することで、フィードバックの遅れが生じるテスト

## パイプライン分析

パイプラインのパフォーマンスを分析して、効率性を改善する方法を見つけます。分析は、CI/CDインフラストラクチャの潜在的なブロッカーを特定するのに役立ちます。これには、次の分析が含まれます。

- ジョブのワークロード
- 実行時間のボトルネック
- パイプラインの全体的なアーキテクチャ

パイプラインのワークフローを理解して文書化し、考えられるアクションと変更について話し合うことが重要です。パイプラインのリファクタリングを行う場合は、DevSecOpsライフサイクルでチーム間で慎重に連携する必要がある場合があります。

パイプライン分析は、コストの効率性の問題を特定するのに役立ちます。たとえば、有料のクラウドサービスでホストされている[Runner](../runners/_index.md)は、次のような状態でプロビジョニングされている場合があります。

- CI/CDパイプラインに必要なリソースよりも多くのリソースが割り当てられ、お金を無駄にしている。
- リソースが不足しており、実行速度が遅く、時間を無駄にしている。

### パイプラインのインサイト

[パイプラインの成功と所要時間チャート](_index.md#pipeline-success-and-duration-charts)は、パイプラインの実行時間と失敗したジョブの数に関する情報を提供します。

[ユニットテスト](../testing/unit_test_reports.md)、インテグレーションテスト、E2Eテスト、[コード品質](../testing/code_quality.md)テストなどのテストでは、CI/CDパイプラインによって問題が自動的に検出されるようにします。多くのパイプラインステージが関与している可能性があり、実行時間が長くなります。

同じステージで異なる項目をテストするジョブを並列実行することで実行時間を改善し、全体の実行時間を短縮できます。欠点は、並列ジョブをサポートするために、より多くのRunnerを同時に実行する必要があることです。

[GitLabのテストレベル](../../development/testing_guide/testing_levels.md)は、多くのコンポーネントが関係する複雑なテスト戦略の例を提供します。

### `needs`の依存関係の可視化

[パイプライングラフ全体](_index.md#group-jobs-by-stage-or-needs-configuration)で`needs`の依存関係を表示すると、パイプラインのクリティカルパスを分析し、考えられるブロッカーを理解するのに役立ちます。

### パイプラインのモニタリング

グローバルパイプラインの健全性は、ジョブとパイプラインの所要時間とともにモニタリングする重要な指標です。[CI/CD分析](_index.md#pipeline-success-and-duration-charts)は、パイプラインの健全性を視覚的に表現します。

インスタンス管理者は、追加の[パフォーマンスメトリクスとセルフモニタリング](../../administration/monitoring/_index.md)にアクセスできます。

[API](../../api/rest/_index.md)から特定のパイプラインの健全性メトリクスをフェッチできます。外部モニタリングツールは、APIをポーリングしてパイプラインの健全性を検証したり、長期的なSLA分析用のメトリクスを収集したりできます。

たとえば、Prometheus用の[GitLab CI Pipelines Exporter](https://github.com/mvisonneau/gitlab-ci-pipelines-exporter)は、APIおよびパイプラインイベントからメトリクスをフェッチします。プロジェクト内のブランチを自動的に確認し、パイプラインの状態と所要時間を取得できます。Grafanaダッシュボードと組み合わせることで、運用チーム向けの実行可能なビューをビルドできます。メトリクスグラフはインシデントに埋め込むこともできるため、問題解決が容易になります。さらに、ジョブと環境に関するメトリクスをエクスポートすることもできます。

GitLab CI Pipelines Exporterを使用する場合は、[設定の例](https://github.com/mvisonneau/gitlab-ci-pipelines-exporter/blob/main/docs/configuration_syntax.md)から始めることをお勧めします。

![GitLab CI Pipelines Prometheus Exporter用Grafanaダッシュボード](img/ci_efficiency_pipeline_health_grafana_dashboard_v13_7.png)

または、[`check_gitlab`](https://gitlab.com/6uellerBpanda/check_gitlab)などのスクリプトを実行できるモニタリングツールを使用することもできます。

#### Runnerのモニタリング

ホストシステム、またはKubernetesなどのクラスターで[CI Runnerをモニタリング](https://docs.gitlab.com/runner/monitoring/)することもできます。次の項目を確認します。

- ディスクとディスクIO
- CPU使用率
- メモリ
- Runnerプロセスのリソース

[Prometheus Node Exporter](https://prometheus.io/docs/guides/node-exporter/)はLinuxホスト上のRunnerをモニタリングでき、[`kube-state-metrics`](https://github.com/kubernetes/kube-state-metrics)はKubernetesクラスターで実行されます。

クラウドプロバイダーで[GitLab Runnerの自動スケーリング](https://docs.gitlab.com/runner/configuration/autoscale.html)をテストし、コストを削減するためにオフライン時間を定義することもできます。

#### ダッシュボードとインシデント管理

既存のモニタリングツールとダッシュボードを使用してCI/CDパイプラインのモニタリングを統合するか、ゼロからビルドします。実行時間のデータがチーム内で実行可能かつ有用であり、オペレーション/サイトリライアビリティエンジニアリング（SRE）が問題を早期に特定できることを確認してください。[インシデント管理](../../operations/incident_management/_index.md)もここで役立ちます。埋め込みメトリクスチャートと、問題を分析するために重要なすべての詳細が含まれています。

### ストレージ使用量

コストと効率性を分析するために、次のストレージの使用状況を確認します。

- [ジョブアーティファクト](../jobs/job_artifacts.md)とその[`expire_in`](../yaml/_index.md#artifactsexpire_in)設定。保存期間が長すぎると、ストレージの使用量が増加し、パイプラインの速度が低下する可能性があります。
- [コンテナレジストリ](../../user/packages/container_registry/_index.md)の使用量。
- [パッケージレジストリ](../../user/packages/package_registry/_index.md)の使用量。

## パイプライン設定

パイプラインを高速化し、リソースの使用量を低減するために、パイプラインを設定する際は慎重に選択してください。これには、パイプラインをより速く、より効率的に実行するGitLab CI/CDの組み込み機能の使用が含まれます。

### ジョブの実行頻度を減らす

すべての状況で実行する必要がないジョブを特定し、パイプライン設定を使用してジョブの実行を停止します。

- [`interruptible`](../yaml/_index.md#interruptible)キーワードを使用して、古いパイプラインが新しいパイプラインに置き換えられたときに、古いパイプラインを停止します。
- [`rules`](../yaml/_index.md#rules)を使用して、不要なテストをスキップします。たとえば、フロントエンドコードのみが変更された場合は、バックエンドテストをスキップします。
- 重要でない[スケジュールされたパイプライン](schedules.md)の実行頻度を減らします。
- [`cron`のスケジュール](schedules.md#view-and-optimize-pipeline-schedules)を均等に分散します。

### フェイルファスト

エラーがCI/CDパイプラインの早い段階で検出されるようにします。完了するまでに非常に時間がかかるジョブは、ジョブが完了するまでパイプラインが失敗ステータスを返さないようにします。

[フェイルファスト](../testing/fail_fast_testing.md)できるジョブがより早く実行されるようにパイプラインを設計します。たとえば、アーリーステージを追加し、構文、スタイルLint、Gitコミットメッセージの検証、および同様のジョブをそのステージに移動します。

実行が速いジョブからの迅速なフィードバックの前に、長いジョブを早期に実行することが重要かどうかを判断します。初期に失敗することで、パイプラインの残りの部分を実行すべきでないことがはっきりし、パイプラインのリソースを節約できる場合があります。

### `needs`キーワード

基本設定では、ジョブは常に、前のステージの他のすべてのジョブが完了するのを待ってから実行されます。これは最も単純な設定ですが、ほとんどの場合、実行時間が最も長くなります。[`needs`キーワードを含むパイプライン](../yaml/needs.md)と[親/子パイプライン](downstream_pipelines.md#parent-child-pipelines)はより柔軟性があり、より効率的ですが、パイプラインの理解と分析が難しくなる可能性もあります。

### キャッシュ

もう1つの最適化方法は、依存関係を[キャッシュ](../caching/_index.md)することです。依存関係がほとんど変わらない場合（[NodeJS `/node_modules`](../caching/_index.md#cache-nodejs-dependencies)など）、キャッシュによりパイプラインの実行が大幅に高速化されます。

[`cache:when`](../yaml/_index.md#cachewhen)を使用して、ジョブが失敗した場合でも、ダウンロードした依存関係をキャッシュできます。

### Dockerイメージ

Dockerイメージのダウンロードと初期化は、ジョブの全体的な実行時間の大部分を占める可能性があります。

Dockerイメージがジョブの実行速度を低下させている場合は、ベースイメージのサイズとレジストリへのネットワーク接続を分析します。GitLabがクラウドで実行されている場合は、ベンダーが提供するクラウドコンテナレジストリを探します。また、他のレジストリよりもGitLabインスタンスが高速にアクセスできる[GitLabコンテナレジストリ](../../user/packages/container_registry/_index.md)を使用することもできます。

#### Dockerイメージを最適化する

最適化されたDockerイメージをビルドします。大きなDockerイメージは多くの容量を使用し、接続速度が遅いとダウンロードに時間がかかるためです。可能であれば、すべてのジョブに1つの大きなイメージを使用することは避けてください。特定のタスクごとに小さなイメージを用意して複数の小さなイメージを使用し、より速くダウンロードおよび実行できるようにします。

ソフトウェアがプリインストールされたカスタムDockerイメージを使用してみてください。通常は、一般的なイメージを使用してソフトウェアを毎回インストールするよりも、事前設定済みの大きなイメージをダウンロードする方がはるかに高速です。[Dockerfile作成のベストプラクティス](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)に関するDockerの記事には、効率的なDockerイメージのビルドに関する詳細が記載されています。

Dockerイメージのサイズを縮小する方法：

- 小さなベースイメージを使用します（`debian-slim`など）。
- 厳密に必要な場合を除き、vimやcurlなどの便利なツールをインストールしないでください。
- 専用の開発イメージを作成します。
- 容量を節約するために、パッケージによってインストールされたmanページとドキュメントを無効にします。
- `RUN`レイヤを減らし、ソフトウェアのインストール手順を組み合わせます。
- [マルチステージビルド](https://blog.alexellis.io/mutli-stage-docker-builds/)を使用して、ビルダーパターンを使用する複数のDockerfileを1つのDockerfileにマージし、イメージサイズを縮小できます。
- `apt`を使用している場合は、不要なパッケージを回避するために`--no-install-recommends`を追加します。
- 最後に、不要になったキャッシュとファイルをクリーンアップします。たとえば、DebianおよびUbuntuの場合は`rm -rf /var/lib/apt/lists/*`、RHELおよびCentOSの場合は`yum clean all`を実行します。
- [dive](https://github.com/wagoodman/dive)や[DockerSlim](https://github.com/docker-slim/docker-slim)などのツールを使用して、イメージを分析および縮小します。

Dockerイメージの管理を簡単にするために、[Dockerイメージ](../docker/_index.md)を管理するための専用グループを作成し、CI/CDパイプラインでそのイメージをテスト、ビルド、公開できます。

## テスト、文書化、学習

パイプラインの改善は何度も繰り返すプロセスです。小さな変更を加え、効果をモニタリングし、繰り返します。多くの小さな改善により、パイプラインの効率性が大幅に向上する可能性があります。

パイプラインの設計とアーキテクチャを文書化することが役立ちます。GitLabリポジトリで直接[MarkdownのMermaidチャート](../../user/markdown.md#mermaid)を使用して、文書化することができます。

実行した調査や見つかった解決策など、CI/CDパイプラインの問題とインシデントをイシューに文書化します。これは、新しいチームメンバーのオンボーディングに役立ち、何度も起こるCIパイプラインの効率性に関する問題を特定するのにも役立ちます。

### 関連トピック

- [CIモニタリングのWebキャストスライド](https://docs.google.com/presentation/d/1ONwIIzRB7GWX-WOSziIIv8fz1ngqv77HO1yVfRooOHM/edit?usp=sharing)
- [GitLab.comモニタリングハンドブック](https://handbook.gitlab.com/handbook/engineering/monitoring/)
- [運用を可視化するためのダッシュボードの構築](https://aws.amazon.com/builders-library/building-dashboards-for-operational-visibility/)
