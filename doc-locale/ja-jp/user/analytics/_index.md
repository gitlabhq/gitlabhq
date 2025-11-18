---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: インスタンス、グループ、プロジェクト分析
title: GitLabの使用状況を分析する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- グループレベルのアナリティクスは、13.9でGitLab Premiumに移行しました。

{{< /history >}}

GitLabは、インスタンス、グループ、および[プロジェクト](../project/settings/_index.md#turn-off-project-analytics)に対して、さまざまな種類のアナリティクスインサイトを提供します。アナリティクス機能を使用するには、プロジェクトとグループに対して異なる[ロールと権限](../permissions.md#analytics)が必要です。

## 分析機能 {#analytics-features}

### エンドツーエンドのインサイトと表示レベル {#end-to-end-insight--visibility-analytics}

これらの機能を使用すると、組織全体のソフトウェア開発ライフサイクルに関するインサイトを得ることができます。

| 機能 | 説明 | プロジェクトレベル： | グループレベル： | インスタンスレベル： |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [Value Streams Dashboard](value_streams_dashboard.md) | DevSecOpsの傾向、パターン、およびデジタルトランスフォーメーション改善の機会に関するインサイト。 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}不可 |
| [バリューストリーム管理アナリティクス](../group/value_stream_analytics/_index.md) | カスタマイズ可能なステージングによるtime-to-valueに関するインサイト。 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}不可 |
| [グループ](../group/devops_adoption/_index.md)および[インスタンス別](../../administration/analytics/devops_adoption.md)のDevOps導入 | DevOps導入における組織の成熟度。経時的な機能導入とグループ別の機能分布。 | {{< icon name="dotted-circle" >}}不可 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 |
| [使用状況の傾向](../../administration/analytics/usage_trends.md) | インスタンスデータと、経時的なデータ量の変化の概要。 | {{< icon name="dotted-circle" >}}不可 | {{< icon name="dotted-circle" >}}不可 | {{< icon name="check-circle" >}}対応 |
| [インサイト](../project/insights/_index.md) | イシュー、マージされたマージリクエスト、トリアージの健全性を調査するためのカスタマイズ可能なレポート。 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}不可 |
| [分析ダッシュボード](analytics_dashboards.md) | 収集されたデータを可視化するための、組み込みのカスタマイズ可能なダッシュボード。 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}不可 |

### 生産性分析 {#productivity-analytics}

これらの機能を使用すると、イシューとマージリクエストに関するチームの生産性についてのインサイトを得ることができます。

| 機能 | 説明 | プロジェクトレベル： | グループレベル： | インスタンスレベル： |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [イシュー分析](../group/issues_analytics/_index.md) | 毎月作成されるイシューの可視化。 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}不可 |
| [マージリクエスト分析](merge_request_analytics.md) | マージリクエストの概要。マージまでの平均時間、スループット、およびアクティビティーの詳細。 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}不可 | {{< icon name="dotted-circle" >}}不可 |
| [生産性分析](productivity_analytics.md) | 作成者レベルまでフィルター可能なマージリクエストライフサイクル。 | {{< icon name="dotted-circle" >}}不可 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}不可 |
| [コードレビュー分析](code_review_analytics.md) | マージリクエストアクティビティーに関する情報を含む、オープンなマージリクエスト。 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}不可 | {{< icon name="dotted-circle" >}}不可 |

### デベロッパーアナリティクス {#developer-analytics}

これらの機能を使用すると、デベロッパーの生産性とコードカバレッジについてのインサイトを得ることができます。

| 機能 | 説明 | プロジェクトレベル： | グループレベル： | インスタンスレベル： |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [コントリビュート分析](../group/contribution_analytics/_index.md) | グループメンバーが行った[コントリビューションイベント](../profile/contributions_calendar.md)の概要。プッシュイベント、マージリクエスト、イシューの棒チャート付き。 | {{< icon name="dotted-circle" >}}不可 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}不可 |
| [コントリビューター分析](contributor_analytics.md) | プロジェクトメンバーが行ったコミットの概要。コミット数のラインチャート付き。 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}不可 | {{< icon name="dotted-circle" >}}不可 |
| [リポジトリ分析](../group/repositories_analytics/_index.md) | リポジトリで使用されているプログラミング言語とコードカバレッジの統計。 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}不可 |

### CI/CD分析 {#cicd-analytics}

これらの機能を使用すると、CI/CDのパフォーマンスについてのインサイトを得ることができます。

| 機能 | 説明 | プロジェクトレベル： | グループレベル： | インスタンスレベル： |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [CI/CDの分析](ci_cd_analytics.md) | パイプラインの継続時間と成功または失敗。 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}不可 |
| [DORAメトリクス](dora_metrics.md) | 経時的なDORAメトリクス。 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}不可 |

### セキュリティアナリティクス {#security-analytics}

これらの機能を使用すると、セキュリティ脆弱性とメトリクスについてのインサイトを得ることができます。

| 機能 | 説明 | プロジェクトレベル： | グループレベル： | インスタンスレベル： |
| ------- | ----------- | ------------- | ----------- | -------------- |
| [セキュリティダッシュボード](../application_security/security_dashboard/_index.md) | セキュリティスキャナーによって検出された脆弱性のメトリクス、評価、チャートのコレクション。 | {{< icon name="check-circle" >}}対応 | {{< icon name="check-circle" >}}対応 | {{< icon name="dotted-circle" >}}不可 |

## メトリクス用語集 {#metric-glossary}

次の用語集では、アナリティクス機能で使用される一般的な開発メトリクスの定義を示し、それらがGitLabでどのように測定されるかを説明します。

| メトリック | 定義 | GitLabでの測定 |
| ------ | ---------- | --------------------- |
| 変更までの平均時間（MTTC） | アイデアからデリバリーまでの平均期間。 | イシューが作成されてから、関連するマージリクエストが本番環境にデプロイされるまで。 |
| 検出までの平均時間（MTTD） | バグが本番環境で検出されなくなるまでの平均期間。 | バグが本番環境にデプロイされてから、それをレポートするイシューが作成されるまで。 |
| マージまでの平均時間（MTTM） | マージリクエストの平均ライフスパン。 | マージリクエストが作成されてからマージされるまで。クローズまたはアンマージされたマージリクエストは除外されます。詳細については、[merge request analytics](merge_request_analytics.md)を参照してください。 |
| 平均復旧/修復/解決/解決/復元時間（MTTR） | バグが本番環境で修正されない平均期間。 | バグが本番環境にデプロイされてから、バグ修正がデプロイされるまで。 |
| ベロシティ | 特定の期間に完了したイシューの合計負荷。負荷は通常、ポイントまたはウェイトで測定され、多くの場合スプリントごとに測定されます。 | 特定の期間にクローズされたイシューの合計ポイントまたはウェイト。例：「スプリントあたり30ポイント」。 |

詳細な定義については、[バリューストリーム管理ダッシュボードのメトリクスとドリルダウンレポート](value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports)も参照してください。
