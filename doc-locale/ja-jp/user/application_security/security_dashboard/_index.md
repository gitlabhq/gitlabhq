---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: セキュリティダッシュボード
description: セキュリティダッシュボード、脆弱性の傾向、プロジェクト評価、およびメトリクス。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 高度な検索機能を備えた新しいダッシュボードがGitLab 18.6で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/570504)、`project_security_dashboard_new`および`group_security_dashboard_new`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)が設定されました。これらのフラグはデフォルトで無効になっています。
- 高度な検索機能を備えた新しいダッシュボードが、GitLab 18.7の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215574)になりました。
- 高度な検索機能を備えた新しいダッシュボードが、GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107661)されました。機能フラグ`project_security_dashboard_new`および`group_security_dashboard_new`は削除されました。

{{< /history >}}

GitLab 18.6では、[高度な脆弱性管理](../vulnerability_report/_index.md#advanced-vulnerability-management)を使用する、改善されたセキュリティダッシュボードのバージョンが導入されました。

新しいダッシュボードは、GitLab.comとGitLab Dedicatedでデフォルトで有効になっています。GitLab Self-Managedユーザーは、新しいダッシュボードにアクセスするために、高度な脆弱性管理を有効にする必要があります。

組織で高度な脆弱性管理が有効になっていない場合は、[レガシーセキュリティダッシュボード](#legacy-security-dashboards)を参照してください。

## セキュリティダッシュボード {#security-dashboards}

{{< history >}}

- [高度な脆弱性管理](../vulnerability_report/_index.md#advanced-vulnerability-management)を使用する新しいダッシュボードがGitLab 18.6で[導入され](https://gitlab.com/gitlab-org/gitlab/-/issues/570504)、`project_security_dashboard_new`および`group_security_dashboard_new`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)が設定されました。これらのフラグはデフォルトで無効になっています。
- 新しいダッシュボードは、GitLab 18.7の[GitLab Self-ManagedおよびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215574)になりました。
- 新しいダッシュボードは、GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107661)になりました。機能フラグ`project_security_dashboard_new`および`group_security_dashboard_new`は削除されました。

{{< /history >}}

セキュリティダッシュボードを使用して、アプリケーションのセキュリティ対策状況を評価します。GitLabには、プロジェクトで実行される[セキュリティスキャナー](../detect/_index.md)によって検出された脆弱性に関するメトリクス、評価、およびチャートのコレクションが用意されています。セキュリティダッシュボードは、次のデータを提供します:

- グループ内のすべてのプロジェクトにおける30日、60日、または90日の期間にわたる脆弱性の傾向。
- 重大度別のオープンな脆弱性の総数。
- プロジェクト全体の脆弱性リスクを比較するための合計リスクスコア。

### 前提条件 {#prerequisites}

プロジェクトまたはグループのセキュリティダッシュボードを表示するには、以下が必要です:

- グループまたはプロジェクトのデベロッパーロール以上。
- プロジェクトに少なくとも1つの[セキュリティスキャナー](../detect/_index.md)が設定されていること。
- プロジェクトの[デフォルトブランチ](../../project/repository/branches/default.md)でセキュリティスキャンが正常に実行されていること。
- プロジェクトで少なくとも1つの検出された脆弱性。
- [高度な脆弱性管理](../vulnerability_report/_index.md#advanced-vulnerability-management)（[高度な検索](../../search/advanced_search.md)が有効）。

> [!note]
> セキュリティダッシュボードには、[デフォルトブランチ](../../project/repository/branches/default.md)で最も最近完了したパイプラインからのスキャン結果が表示されます。ダッシュボードは、デフォルトブランチで実行された完了済みのパイプラインの結果で更新されます。他のマージされていないブランチからのパイプラインで検出された脆弱性は含まれません。

### セキュリティダッシュボードを表示する {#viewing-the-security-dashboard}

セキュリティダッシュボードには、デフォルトブランチで検出された脆弱性からのデータを使用して構築された、フィルター可能なチャートとパネルが表示されます。チャートとパネルには、オープンな（トリアージが必要、または確認済みステータスの）脆弱性のみが含まれ、検出されなくなったものは除外されます。

プロジェクトまたはグループのセキュリティダッシュボードを表示できます。各ダッシュボードは、セキュリティ対策状況に対する独自の視点を提供します。

両方のダッシュボードには、次のものが含まれます:

- [チャート](#charts)
  - [時間経過による脆弱性の推移](#vulnerabilities-over-time)
  - [脆弱性の重大度パネル](#vulnerability-severity-panel)
  - [Risk score](#risk-score-panel)
  - [経過時間ごとの脆弱性](#vulnerabilities-by-age)
  - [CWEトップ10](#top-10-cwes)
  - [SASTトリアージと修復ファネル](#sast-triage-and-remediation-funnel)
- [ダッシュボード全体のフィルター](#filter-the-entire-dashboard)
- [PDF形式でエクスポート](#export-as-pdf)

セキュリティダッシュボードを表示するには、次の手順に従います:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**安全** > **セキュリティダッシュボード**を選択します。

### プロジェクトセキュリティダッシュボード {#project-security-dashboard}

プロジェクトセキュリティダッシュボードには、プロジェクトのデフォルトブランチで検出された脆弱性が表示されます。これには以下が含まれます:

- [**時間経過による脆弱性の推移**](#vulnerabilities-over-time)チャート。これには、最大90日間の履歴が含まれます。
- [**重大度のパネル**](#vulnerability-severity-panel)。これには、重大度別にオープンな脆弱性が表示されます。
- [**リスクスコア**](#risk-score-panel)パネル。これには、プロジェクト全体のセキュリティリスクが表示されます。
- [**経過時間ごとの脆弱性**](#vulnerabilities-by-age)チャート。これは、オープンな脆弱性を経過期間別にグループ化します。
- [**CWEトップ10**](#top-10-cwes)チャートは、最も一般的な10個のCWEを表示します。
- [**SASTトリアージと修復ファネル**](#sast-triage-and-remediation-funnel)チャートは、致命的および高レベルのSAST脆弱性が検出から修正までどのように進捗するかを、GitLab Duoが処理するステージを含めて示します。

オープンな脆弱性とは、トリアージが必要または確認済みステータスの脆弱性のことです。無視または解決済みのステータスのクローズされた脆弱性は、これらのチャートには含まれません。

![プロジェクトセキュリティダッシュボード](img/project_security_dashboard_v18_5.png)

### グループセキュリティダッシュボード {#group-security-dashboard}

グループセキュリティダッシュボードは、グループとそのサブグループ内のすべてのプロジェクトのデフォルトブランチで見つかった脆弱性の概要を示します。グループセキュリティダッシュボードは、以下を提供します:

- [**時間経過による脆弱性の推移**](#vulnerabilities-over-time)チャート。これには、最大90日間の履歴が含まれます。
- [**重大度のパネル**](#vulnerability-severity-panel)。これには、重大度別にオープンな脆弱性が表示されます。
- [**リスクスコア**](#risk-score-panel)パネル。これには、各プロジェクトの合計リスクとリスクが表示されます。
- [**経過時間ごとの脆弱性**](#vulnerabilities-by-age)チャート。これは、オープンな脆弱性を経過期間別にグループ化します。
- [**CWEトップ10**](#top-10-cwes)チャートは、最も一般的な10個のCWEを表示します。
- [**SASTトリアージと修復ファネル**](#sast-triage-and-remediation-funnel)チャートは、致命的および高レベルのSAST脆弱性が検出から修正までどのように進捗するかを、GitLab Duoが処理するステージを含めて示します。

### チャート {#charts}

セキュリティダッシュボードには、プロジェクトとグループの脆弱性を理解し、それらに対処するのに役立つチャートがいくつか含まれています。

#### 時間経過による脆弱性の推移 {#vulnerabilities-over-time}

**時間経過による脆弱性の推移**チャートは、プロジェクトとグループのダッシュボードの両方で使用できます。30日、60日、または90日の期間にわたるオープンな脆弱性の傾向を示しています。デフォルトの範囲は30日間です。GitLabは365日間脆弱性データを保持します。

チャートを使用して、脆弱性がいつ導入されたか、および時間の経過とともにどのように変化するかを特定します。

詳細を表示するには、次の手順に従います:

1. データポイントの上にカーソルを合わせると、その日の脆弱性の数が表示されます。
1. **期間選択セレクター**を使用して、表示期間を30日、60日、または90日に切り替えることができます。
1. 範囲ハンドル（{{< icon name="scroll-handle" >}}）をドラッグして、特定の期間を拡大します。
1. ドロップダウンを使用して、**重大度**（例: **致命的**、**高**、**中**）でフィルタリングします
1. 次のいずれかのオプションでデータをグループ化するには、次のボタンを使用します:
   - **重大度**: 致命的、高、中、低、情報、不明。
   - **レポートの種類**: SAST、DAST、および依存関係スキャンなど。
1. 90日を超えるデータを調べるには（ただし、過去365日以内）、[`SecurityMetrics.vulnerabilitiesOverTime` GraphQL API](../../../api/graphql/reference/_index.md#securitymetricsvulnerabilitiesovertime)を使用します。

![時間経過による脆弱性の推移](img/vulnerabilities_over_time_chart_v18_5.png)

#### 脆弱性の重大度パネル {#vulnerability-severity-panel}

脆弱性の重大度パネルには、[重大度](../vulnerabilities/severities.md)別のオープンな脆弱性の総数が表示されます。

詳細を表示するには、次の手順に従います:

1. 重大度パネルで、調査する重大度を探します。
1. **表示**を選択します。
   - 脆弱性レポートが開き、その重大度の脆弱性のみが含まれます。
   - 設定したページレベルのフィルターもすべて適用されます。

![重大度レベル](img/security_dashboard_severity_panels_v18_5.png)

#### リスクスコアパネル {#risk-score-panel}

{{< history >}}

- グループダッシュボードのRisk scoreパネル:
  - GitLab 18.6で`security_dashboard_risk_score`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/570504)されました。デフォルトでは無効になっています。
  - GitLab 18.7の[GitLab.com、GitLab Self-Managed、GitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215574)になりました。
  - GitLab 18.8で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107661)になりました。機能フラグ`security_dashboard_risk_score`は削除されました。
- プロジェクトダッシュボードのリスクスコアチャート:
  - GitLab 18.11で[一般提供開始](https://gitlab.com/gitlab-org/gitlab/-/work_items/591112)。

{{< /history >}}

リスクスコアパネルには、グループまたはプロジェクト全体のセキュリティリスクが表示されます。パネルには2つのビューがあります:

1. **グループ化なし**（デフォルト）ビューには、グループのリスクスコアの合計が表示されます:
   - 円形のゲージには、計算されたリスクスコアが中央に表示されます。
   - カラーバーはリスクレベルを示します:
     - 緑: 低リスク
     - 黄: 中リスク
     - オレンジ: 高リスク
     - 赤: 重大リスク
1. 各プロジェクトのリスクスコアを比較するには、**プロジェクト**を選択します:
   - 各プロジェクトのタイルは、プロジェクトのリスクレベルに応じて色分けされます。
   - タイルにカーソルを合わせると、プロジェクト名とリスクスコアを含む詳細が表示されます。
   - タイルを選択し、プロジェクト名を選択して、そのプロジェクトの脆弱性レポートを開きます。

![セキュリティダッシュボードのデフォルト表示](img/group_security_dashboard_risk_score_v18_6.png)

![セキュリティダッシュボードのプロジェクトグリッド表示](img/group_security_dashboard_total_risk_score_project_v18_6.png)

リスクスコアは、以下の複数の要素から計算されます:

- 脆弱性の重大度
- 脆弱性の経過期間
- KEV（既知の悪用された脆弱性）ステータス
- EPSS（Exploit Prediction Scoring System）スコア

#### 経過時間ごとの脆弱性 {#vulnerabilities-by-age}

{{< history >}}

- プロジェクトダッシュボードの経過時間ごとの脆弱性チャート:
  - GitLab 18.11で[一般提供開始](https://gitlab.com/gitlab-org/gitlab/-/work_items/590979)。

{{< /history >}}

**経過時間ごとの脆弱性**チャートは、グループおよびプロジェクトのダッシュボードで利用できます。最初に検出されてから経過した時間に基づいて、未解決の脆弱性の分布を示します。重大度またはレポートタイプ別に脆弱性をグループ化して、修正アクティビティが必要な場所を特定できます。

詳細を表示するには、次の手順に従います:

1. データにカーソルを合わせると、その期間の脆弱性の数が表示されます。
1. ドロップダウンリストを使用して、**重大度**（例: **致命的**、**高**、**中**）でフィルタリングします
1. 次のいずれかのオプションでデータをグループ化するには、次のボタンを使用します:
   - **重大度**: 致命的、高、中、低、情報、不明。
   - **レポートの種類**: SAST、DAST、および依存関係スキャンなど。

![経過時間ごとの脆弱性](img/vulnerabilities_by_age_chart_v18_9.png)

#### 上位10個のCWE {#top-10-cwes}

{{< history >}}

- GitLab 18.11で`new_security_dashboard_vulnerabilities_by_identifier`[機能フラグ](../../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/work_items/17422)されました。デフォルトでは有効になっています。
- GitLab 19.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/592130)になりました。機能フラグ`new_security_dashboard_vulnerabilities_by_identifier`は削除されました。

{{< /history >}}

**CWEトップ10**チャートは、グループおよびプロジェクトのダッシュボードで利用できます。これは、グループまたはプロジェクトのオープンな脆弱性に関連付けられている、最も一般的な10個のCWE識別子を表示します。

詳細を表示するには、次の手順に従います:

1. データポイントにカーソルを合わせると、各CWEタイプの脆弱性の総数が表示されます。
1. ドロップダウンリストを使用して、**重大度**（例: **クリティカル**、**中**、**高**）でフィルタリングします。

![CWEトップ10](img/group_security_dashboard_top_10_cwes_v18_11.png)

#### SASTトリアージと修復ファネル {#sast-triage-and-remediation-funnel}

{{< history >}}

- GitLab 19.3で[導入され](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239423)、`security_dashboard_agentic_adoption`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)が設定されました。デフォルトでは有効になっています。

{{< /history >}}

**SASTトリアージと修復ファネル**チャートは、グループおよびプロジェクトのダッシュボードで利用できます。これは、重大および高SAST脆弱性が30日、60日、または90日の期間にわたってトリアージと修正を経て進行することを示します。デフォルトの範囲は30日間です。

このファネルには最大4つのステージがあります。各ステージには、それに到達した脆弱性の数が表示されます:

- **重大および高SAST脆弱性**: SASTによって検出された脆弱性。
- **正検知**: [SASTの誤検出判定](../vulnerabilities/false_positive_detection.md)によって真陽性と確認された脆弱性。
- **AI生成マージリクエストによる脆弱性**: [エージェント型SAST脆弱性の修正](../vulnerabilities/agentic_vulnerability_resolution.md)によって作成されたマージリクエストを含む脆弱性。
- **修正された脆弱性**: マージされたAI作成のマージリクエストによって修正された脆弱性。

30日、60日、または90日の期間でファネルを切り替えるには、時間枠セレクターを使用します。

![SASTトリアージと修復ファネル](img/sast_triage_and_remediation_funnel_v19_3.png)

最後の3つのステージでは、GitLab Duoを使用します。これらのステージにデータを入力するには:

- グループおよびそのプロジェクトに対してGitLab Duoを有効にします。
- [SASTの誤検出判定](../vulnerabilities/false_positive_detection.md)を設定します。
- [エージェント型SAST脆弱性の修正](../vulnerabilities/agentic_vulnerability_resolution.md)を設定します。

これらの機能のいずれかがオフの場合、ファネルは影響を受けるステージを、どの機能をオンにするかを説明するメッセージに置き換えます。メッセージは、プロジェクトとグループのダッシュボード、および利用できない機能によって異なります。

![SASTトリアージと修復ファネル（機能がオフの場合）](img/sast_triage_and_remediation_funnel_empty_state_v19_3.png)

### フィルターバーをダッシュボード全体に適用 {#filter-the-entire-dashboard}

結果は2つのレベルでフィルタリングできます:

- **ダッシュボードのフィルター**: ダッシュボード全体に適用します。これらのフィルターを使用すると、すべてのチャートが更新されます。
- **チャートとパネルのフィルター**: 表示しているチャートまたはパネルにのみ適用します。

使用可能なダッシュボードフィルターは次のとおりです:

- **レポートの種類**: SAST、DAST、依存関係スキャンなどのスキャナーでフィルタリングします。
- **プロジェクト**: 結果を特定のプロジェクトに限定します。グループセキュリティダッシュボードでのみ使用できます。

グループセキュリティダッシュボードでは、以下でフィルタリングすることもできます:

- **セキュリティ属性**: プロジェクトに適用されているセキュリティ属性でフィルタリングします。これには、ビジネスインパクト、アプリケーション、ビジネスユニット、インターネット公開、場所のカテゴリが含まれます。これらのフィルターは、包括的（**次のいずれか** 演算子を使用）または排他的（**次のいずれでもない** 演算子を使用）にできます。セキュリティ属性を設定し、プロジェクトに適用するには、[セキュリティ属性](../attributes/_index.md)を参照してください。

ダッシュボードフィルターの動作:

- フィルターは、すべてのダッシュボードのチャートとパネルにすぐに適用されます。
- 適用したフィルターは、削除しない限り、セッション全体で適用され続けます。
- ダッシュボードから脆弱性レポートを開くと、アクティブなフィルターが脆弱性レポートに自動的に適用されます。

ダッシュボード全体にフィルターを適用するには、次の手順に従います:

1. ダッシュボードの上部にあるフィルターバーで、**結果をフィルタリング**を選択します。
1. ドロップダウンリストから、フィルタータイプを選択します。
1. 1つまたは複数のフィルター値を選択します。

### PDFとしてエクスポート {#export-as-pdf}

{{< history >}}

- GitLab 18.10で[導入され](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224664)、`new_security_dashboard_pdf_export`という名前の[機能フラグ](../../../administration/feature_flags/_index.md)が設定されました。デフォルトでは無効になっています。
- GitLab 18.11で[GitLab.com、GitLab Self-Managed、およびGitLab Dedicatedで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/589201)になりました。
- GitLab 19.0で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/589201)になりました。機能フラグ`new_security_dashboard_pdf_export`は削除されました。

{{< /history >}}

セキュリティダッシュボードをPDFとしてエクスポートすることができ、レポートやプレゼンテーションで使用できます。エクスポートには、アクティブなフィルターを含む、ダッシュボード内のすべてのチャートとパネルの現在の状態が取り込まれます。

ダッシュボードをPDFとしてエクスポートするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトまたはグループを見つけます。
1. 左サイドバーで、**安全** > **セキュリティダッシュボード**を選択します。
1. オプション。フィルターを適用して、エクスポートに含まれるデータをカスタマイズします。
1. **PDF形式でエクスポート**を選択します。

## レガシーセキュリティダッシュボード {#legacy-security-dashboards}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

高度な脆弱性管理を有効にしていないGitLab Self-Managedの顧客は、最新のセキュリティダッシュボードにアクセスできません。この場合でも、レガシーセキュリティダッシュボードにアクセスできます。

セキュリティダッシュボードは、アプリケーションのセキュリティ対策状況を評価するために使用されます。GitLabには、プロジェクトで実行される[セキュリティスキャナー](../detect/_index.md)によって検出された脆弱性に関するメトリクス、評価、およびチャートのコレクションが用意されています。セキュリティダッシュボードには、次のようなデータが表示されます:

- グループ内のすべてのプロジェクトにおける30日、60日、または90日の期間にわたる脆弱性の傾向
- 各プロジェクトにおける、脆弱性の重大度に基づいた文字グレード評価
- 過去365日以内に検出された脆弱性の総数（重大度を含む）

セキュリティダッシュボードデータを使用して、セキュリティ対策状況を改善します。たとえば、365日間のトレンドビューでは、脆弱性が急増した日が表示されます。これらの日のコード変更を調査し、根本原因分析を実行して、将来の脆弱性を防ぐためのより良いポリシーを構築します。

<i class="fa-youtube-play" aria-hidden="true"></i>概要については、[セキュリティダッシュボード - 高度なセキュリティテスト](https://www.youtube.com/watch?v=Uo-pDns1OpQ)を参照してください。

## レガシーダッシュボードの前提条件 {#prerequisites-for-the-legacy-dashboards}

セキュリティダッシュボードを表示するには、以下が必要です:

- グループまたはプロジェクトのデベロッパーロールを持っていること。
- プロジェクトに少なくとも1つの[セキュリティスキャナー](../detect/_index.md)が設定されていること。
- プロジェクトの[デフォルトブランチ](../../project/repository/branches/default.md)でセキュリティスキャンが正常に実行されていること。
- プロジェクト内で少なくとも1件の脆弱性が検出されていること。

> [!note]
> セキュリティダッシュボードには、[デフォルトブランチ](../../project/repository/branches/default.md)で最も最近完了したパイプラインからのスキャン結果が表示されます。ダッシュボードは、デフォルトブランチで実行された完了済みパイプラインの結果で更新されます。これらには、マージされていない他のブランチのパイプラインで発見された脆弱性は含まれません。

## レガシーセキュリティダッシュボードの表示 {#viewing-the-legacy-security-dashboard}

セキュリティダッシュボードは、プロジェクト、グループ、およびセキュリティセンターの各レベルで表示できます。各ダッシュボードは、セキュリティ対策状況の独自の視点を提供します。

### プロジェクトセキュリティダッシュボード {#project-security-dashboard-1}

プロジェクトセキュリティダッシュボードは、特定のプロジェクトで時間の経過とともに検出された脆弱性の総数を表示し、最大365日間の履歴データを含みます。このダッシュボードは、デフォルトブランチにあるオープンな脆弱性の履歴ビューです。オープンな脆弱性とは、`Needs triage`または`Confirmed`ステータスのみのものです（`Dismissed`または`Resolved`の脆弱性は除外されます）。

プロジェクトのセキュリティダッシュボードを表示するには、次の手順に従います:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**安全** > **セキュリティダッシュボード**を選択します。
1. 必要なものを絞り込んで検索します。
   - 重大度でチャートを絞り込むには、凡例名を選択します。
   - 特定の期間を表示するには、時間範囲ハンドル（{{< icon name="scroll-handle" >}}）を使用します。
   - チャートの特定の領域を表示するには、左端のアイコン（{{< icon name="marquee-selection" >}}）を選択し、チャート全体をドラッグします。
   - 元の範囲にリセットするには、**Remove Selection**（{{< icon name="redo" >}}）を選択します。

![プロジェクトセキュリティダッシュボード](img/project_security_dashboard_v16_6.png)

#### 脆弱性チャートをダウンロードする {#downloading-the-vulnerability-chart}

プロジェクトセキュリティダッシュボードから脆弱性チャートの画像をダウンロードして、ドキュメントやプレゼンテーションなどに使用できます。脆弱性チャートのイメージをダウンロードするには、次の手順に従います:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左サイドバーで、**安全** > **セキュリティダッシュボード**を選択します。
1. **Save chart as an image**（{{< icon name="download" >}}）を選択します。

SVG形式でイメージをダウンロードするように求められます。

### グループセキュリティダッシュボード {#group-security-dashboard-1}

グループセキュリティダッシュボードは、グループとそのサブグループ内のすべてのプロジェクトのデフォルトブランチで見つかった脆弱性の概要を示します。グループセキュリティダッシュボードは、以下を提供します:

- 30日、60日、または90日の期間にわたる脆弱性の傾向
- 重大度の最も高いオープンな脆弱性に応じた、グループ内における各プロジェクトの文字グレード。文字グレードは、次の基準を使用して割り当てられます:

| グレード | 説明                                     |
| ----- | ----------------------------------------------- |
| **F** | 1つ以上の`critical`脆弱性          |
| **D** | 1つ以上の`high`または`unknown`脆弱性 |
| **C** | 1つ以上の`medium`脆弱性            |
| **B** | 1つ以上の`low`脆弱性               |
| **A** | 脆弱性ゼロ                            |

グループのセキュリティダッシュボードを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、グループを見つけます。
1. 左サイドバーで、**セキュリティ** > **セキュリティダッシュボード**を選択します。
1. **時間経過による脆弱性の推移**グラフの上にカーソルを合わせると、脆弱性に関する詳細が表示されます。
   - 脆弱性の傾向を、30日、60日、または90日の期間で表示できます（デフォルトは90日です）。
   - 90日を超える集計データを表示するには、[`VulnerabilitiesCountByDay` GraphQL API](../../../api/graphql/reference/_index.md#vulnerabilitiescountbyday)を使用します。GitLabは365日間データを保持します。

1. **プロジェクトのセキュリティ状態**セクションの下にある矢印を選択して、特定のレターグレード評価に該当するプロジェクトを確認します:
   - 特定の重大度の脆弱性がプロジェクト内でいくつ見つかったかを確認できます
   - プロジェクト名を選択して、そのプロジェクトのセキュリティダッシュボードに直接アクセスできます

![グループセキュリティダッシュボード](img/group_security_dashboard_v16_6.png)

## バリューストリームダッシュボードにおける脆弱性のメトリクス {#vulnerability-metrics-in-the-value-streams-dashboard}

[バリューストリームダッシュボード](../../analytics/value_streams_dashboard.md)の比較パネルで利用できる追加の脆弱性メトリクスがあり、組織のソフトウエアデリバリーワークフローのコンテキストでセキュリティエクスポージャを理解するのに役立ちます。

## 関連トピック {#related-topics}

- [セキュリティセンター](../security_center/_index.md)
- [脆弱性レポート](../vulnerability_report/_index.md)
- [脆弱性ページ](../vulnerabilities/_index.md)
- [自動的に脆弱性を解決する](../policies/vulnerability_management_policy.md)
