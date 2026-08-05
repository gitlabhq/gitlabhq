---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: マージリクエストでカバレッジ率を追跡し、行ごとのテストカバレッジを視覚化します。
title: コードカバレッジ
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

マージリクエストでコードカバレッジを追跡するには、MRウィジェットにパーセンテージを表示するか、MR差分で個々の行に注釈を付けるか、またはその両方を行うことができます。各出力には個別のキーワードが必要です。いずれか一方を設定しても、もう一方は有効になりません。

| 出力                                                                           | キーワード |
| -------------------------------------------------------------------------------- | ------- |
| MRウィジェット、パイプラインリスト、およびアナリティクスグラフでカバレッジのパーセンテージを表示します。 | [`coverage`](../../yaml/_index.md#coverage) |
| MR差分で行ごとの注釈を表示します。                                     | [`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report) |

両方の出力を取得するには、両方のキーワードを設定します。

## カバレッジレポート {#coverage-reporting}

カバレッジレポートは、テストツールのジョブログ出力からパーセンテージを抽出します。`coverage`キーワードで正規表現を定義します。GitLabはジョブログをスキャンし、最初の一致する数値を抽出して保存します。

GitLabは、この値を次の場所に表示します:

- MRウィジェット（ターゲットブランチとの差分を含む）。
- パイプラインジョブリスト。
- プロジェクトごとおよびグループごとのカバレッジ履歴グラフを、**分析** > **リポジトリ分析**に表示します。
- カバレッジバッジ。
- `Coverage-Check`承認ルール（PremiumおよびUltimate）は、カバレッジが低下した場合に承認を要求できます。

セットアップ手順については、[カバレッジレポートを設定する](coverage_reporting.md)を参照してください。

## カバレッジの可視化 {#coverage-visualization}

カバレッジの視覚化は、テストジョブがCI/CDアーティファクトとしてアップロードするCoberturaまたはJaCoCo XMLレポートを解析します。パイプラインが完了すると、GitLabはバックグラウンドでレポートを処理し、MR差分の行に注釈を付けます。

注釈は、MR差分で変更されたファイルにのみ表示されます。MRで変更されていないファイルは、レポートにカバレッジデータが含まれていても、注釈は付けられません。

セットアップ手順については、[カバレッジ視覚化を設定する](coverage_visualization.md)を参照してください。
