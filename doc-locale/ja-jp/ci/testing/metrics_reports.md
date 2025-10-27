---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: メトリクスレポート
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

メトリクスレポートは、マージリクエストでカスタムメトリクスを表示し、ブランチ間のパフォーマンス、メモリ使用量、その他の測定値を追跡します。

メトリクスレポートを使用して、以下を行います。

- メモリ使用量の変更を監視します。
- 負荷テストの結果を追跡します。
- コードの複雑さを測定します。
- コードカバレッジの統計を比較します。

## メトリクスの処理ワークフロー {#metrics-processing-workflow}

パイプラインの実行時に、GitLabはレポートアーティファクトからメトリクスを読み取り、比較のためにそれらを文字列値として保存します。デフォルトのファイル名は`metrics.txt`です。

マージリクエストの場合、GitLabはフィーチャーブランチのメトリクスをターゲットブランチの値と比較し、マージリクエストウィジェットに次の順序で表示します。

- 値が変更された既存のメトリクス。
- マージリクエストによって追加されたメトリクス（**新規**バッジでマーク）。
- マージリクエストによって削除されたメトリクス（**削除しました**バッジでマーク）。
- 値が変更されていない既存のメトリクス。

## メトリクスレポートの設定 {#configure-metrics-reports}

マージリクエストでカスタムメトリクスを追跡するには、メトリクスレポートをCI/CDパイプラインに追加します。

前提要件: 

- メトリクスファイルは、[OpenMetrics](https://prometheus.io/docs/instrumenting/exposition_formats/#openmetrics-text-format)テキスト形式を使用する必要があります。

メトリクスレポートを設定するには: 

1. `.gitlab-ci.yml`ファイルで、メトリクスレポートを生成するジョブを追加します。
1. OpenMetrics形式でメトリクスを生成するジョブにスクリプトを追加します。
1. [`artifacts:reports:metrics`](../yaml/artifacts_reports.md#artifactsreportsmetrics)を使用してメトリクスファイルをアップロードするようにジョブを設定します。

次に例を示します。

```yaml
metrics:
  stage: test
  script:
    - echo 'memory_usage_bytes 2621440' > metrics.txt
    - echo 'response_time_seconds 0.234' >> metrics.txt
    - echo 'test_coverage_percent 87.5' >> metrics.txt
    - echo '# EOF' >> metrics.txt
  artifacts:
    reports:
      metrics: metrics.txt
```

パイプラインの実行後、メトリクスレポートはマージリクエストウィジェットに表示されます。

![メトリクス名と値を表示するマージリクエスト内のメトリクスレポートウィジェット。](img/metrics_report_v18_3.png)

追加の形式仕様と例については、[Prometheusテキスト形式の詳細](https://prometheus.io/docs/instrumenting/exposition_formats/#text-format-details)を参照してください。

## トラブルシューティング {#troubleshooting}

メトリクスレポートの操作中に、次の問題が発生する可能性があります。

### メトリクスレポートが変更されていません {#metrics-reports-did-not-change}

マージリクエストでメトリクスレポートを表示すると、**メトリクスレポートのスキャンでは、新たな変更は検出されませんでした**と表示される場合があります。

この問題は、次の場合に発生します。

- ターゲットブランチに、比較のためのベースラインメトリクスレポートがありません。
- お使いのGitLabサブスクリプションには、メトリクスレポートが含まれていません（PremiumまたはUltimateが必要です）。

この問題を解決するには、次のようにします。

1. お使いのGitLabサブスクリプションプランにメトリクスレポートが含まれていることを検証します。
1. ターゲットブランチに、メトリクスレポートが設定されたパイプラインがあることを確認します。
1. メトリクスファイルが有効なOpenMetrics形式を使用していることを検証します。
