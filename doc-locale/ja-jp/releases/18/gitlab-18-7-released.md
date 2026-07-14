---
stage: Release Notes
group: Monthly Release
date: 2025-12-18
title: "GitLab 18.7 リリースノート"
description: "GitLab 18.7がリリースされました。シークレット有効性チェックの改善と一般提供開始が含まれます。"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年12月18日、GitLab 18.7が以下の機能とともにリリースされました。

また、今月の注目コントリビューターをはじめ、すべてのコントリビューターの皆様に感謝申し上げます。

## 今月の注目コントリビューター: David Aniebo

David Anieboさんを18.7の注目コントリビューターとして表彰できることを嬉しく思います。GitLab製品計画機能および[コントリビュータープラットフォーム](https://contributors.gitlab.com)への多大な貢献が評価されました。

Davidさんの[作業アイテムリスト機能の改善](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207549)への取り組みは、GitLab計画機能のユーザーエクスペリエンス向上に対する技術的な専門知識と献身を示しています。この貢献により、チームが作業アイテムをより効率的に整理・管理できるようになり、数千人のGitLabユーザーのプロジェクト計画がより効率的になりました。

コードへの貢献にとどまらず、Davidさんはコントリビュータープラットフォームの継続的な支持者として、コミュニティコントリビューターのエクスペリエンス向上にも貢献しています。その協調的なアプローチと迅速な対応は、さまざまなグループの複数のチームメンバーから高く評価されています。

「Davidさんは製品計画グループの取り組みに素晴らしい貢献をしてくださいました。その貢献に心から感謝しています」と、製品計画担当エンジニアリングマネージャーのNick Brandtは述べています。

Davidさん、GitLabへの貴重な貢献と、コミュニティの協力的なメンバーとしてのご活躍に感謝します。今後のご参加も楽しみにしています。

## 主要機能

### シークレット有効性チェックの改善と一般提供開始

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/validity_check.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16890)

{{< /details >}}

リポジトリで有効なシークレットが漏洩した場合、迅速な対応が必要です。緊急の脅威を優先的に対処できるよう、有効性チェックは漏洩した認証情報がまだ使用可能かどうかを自動的に検証します。

GitLab 18.7では、以下の改善を行いました。

- ベンダーインテグレーション: Google Cloud、AWS、Postmanとのインテグレーションを追加し、既存のGitLabトークンのサポートも継続しています。
- レポートフィルタリング: 有効性ステータス（アクティブ、非アクティブ、アクティブの可能性あり）で脆弱性レポートをフィルタリングし、シークレットの検出結果を迅速にトリアージして優先順位を付けられます。
- グループレベルAPI: 単一のAPIコールでグループ内のすべてのプロジェクトの有効性チェックを有効にし、組織全体へのロールアウトを効率化できます。

このリリースで、有効性チェックが一般提供（GA）となりました。

### Agentic Chatとエージェントの個別モデル選択

<!-- categories: Model Personalization -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/work_items/19998)

{{< /details >}}

トップレベルグループまたはインスタンスに対して、Agentic Chatとその他すべてのエージェントに個別のモデルを選択できるようになりました。これにより、GitLab Duo Agent Platformのモデル選択の選択肢が広がります。

### GitLab DuoとSDLCトレンドダッシュボードの改善

<!-- categories: DevOps Reports -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/analytics/duo_and_sdlc_trends.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19629)

{{< /details >}}

GitLab DuoとSDLCトレンドダッシュボードは、GitLab Duoがソフトウエアデリバリーに与える影響を測定するための分析機能が強化されました。ダッシュボードでは、GitLab Duo機能の採用状況、パイプラインパフォーマンス、デプロイ頻度や平均マージ所要時間などの一般的な開発メトリクスにわたる6か月間のトレンド分析が提供されるようになりました。

GitLab Duo Code Suggestionsのコード生成量やIDEおよび言語のトレンドを追跡し、チームが新しいGitLab Duo Agent Platformフローを採用する様子を観察できます。強化されたユーザーレベルのメトリクスにより、継続的な価値を提供する主要なDuo機能についてより深いインサイトを得られます。

[インスタンスレベルのAI使用状況に関する新しいエンドポイント](../../api/graphql/reference/_index.md#aiinstanceusagedata)が利用可能になり、インスタンス管理者はPostgres（3か月保持）またはClickHouseのいずれかからすべてのDuoデータを抽出できます。

[ClickHouseインテグレーション](../../integration/clickhouse.md)を活用することで、このダッシュボードは数百万のデータポイントにわたるサブ秒のクエリパフォーマンスを実現します。Self-Managedインスタンスについては、[ClickHouseインテグレーション](../../integration/clickhouse.md)の推奨事項と設定ガイダンスが改善されています。

### プランナーエージェントの追加機能がベータ版で利用可能に

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/planner.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/576618)

{{< /details >}}

プランナーエージェントに作成・編集機能がベータ版として追加されました。プランナーエージェントは、GitLab内でプロダクトマネージャーを直接サポートするために構築されたファウンデーショナルエージェントです。プランナーエージェントを使用して、GitLabの作業アイテムを作成、編集、分析できます。

手動でアップデートを追いかけたり、作業の優先順位を付けたり、計画データをまとめたりする代わりに、プランナーエージェントがバックログの分析、RICEやMoSCoWなどのフレームワークの適用、本当に注意が必要な事項の洗い出しを支援します。計画ワークフローを理解し、より良く効率的な意思決定をサポートする積極的なチームメンバーのような存在です。

フィードバックは[イシュー576622](https://gitlab.com/gitlab-org/gitlab/-/issues/576622)にお寄せください。

### CI/CDパイプラインの動的入力オプション

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../ci/inputs/_index.md#define-conditional-input-options-with-specinputsrules) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18546)

{{< /details >}}

直感的なWebインターフェースから新しいパイプラインを作成する際に、動的な入力選択を活用できるようCI/CDパイプラインを設定できます。

動的入力オプションにより、前の選択に基づいて入力選択肢が動的に更新されるようにパイプラインを設定できます。たとえば、あるドロップダウンリストで入力を選択すると、2番目のドロップダウンリストに関連する入力オプションのリストが自動的に表示されます。

CI/CD入力を使用すると、以下が可能になります。

- 事前設定された入力でパイプラインをトリガーし、エラーを削減してデプロイを効率化できます。
- ユーザーがドロップダウンメニューからデフォルト以外の入力を選択できるようにします。
- 前の選択に基づいてオプションが動的に更新されるカスケードドロップダウンリストを利用できます。

この動的な機能により、パイプライン作成プロセスをガイドするよりインテリジェントなコンテキスト認識型の入力設定を作成でき、エラーを削減して有効な入力の組み合わせのみが選択されるようになります。

### AIによるSAST誤検出判定（ベータ版）

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/false_positive_detection.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18977)

{{< /details >}}

セキュリティチームは、誤検出であることが判明するSASTの検出結果の調査に多くの時間を費やし、本物のセキュリティリスクへの対応が後回しになることがあります。

GitLab 18.7では、重要な脆弱性に集中できるよう、AIを活用したSAST誤検出検知を導入しました。セキュリティスキャンが実行されると、GitLab DuoはCriticalおよびHighの重大度を持つ各SAST脆弱性を自動的に分析し、誤検出の可能性を判定します。

AIによる評価は脆弱性レポートに直接表示されるため、セキュリティエンジニアはより迅速かつ自信を持ってトリアージの判断を下せます。

主な機能は以下のとおりです。

- 自動分析: 誤検出検知は各セキュリティスキャン後に自動的に実行され、手動でのトリガーは不要です。
- 手動トリガーオプション: ユーザーは脆弱性詳細ページで個々の脆弱性に対してオンデマンドで誤検出検知を手動でトリガーできます。
- 高影響度の検出結果に集中: シグナル対ノイズ比の改善を最大化するため、CriticalおよびHighの重大度の脆弱性に絞り込まれています。
- コンテキストに基づくAI推論: 各評価には、コードのコンテキストと脆弱性の特性に基づいて、その検出結果が真陽性である可能性があるかどうかの説明が含まれます。
- シームレスなワークフローインテグレーション: 結果は既存の重大度、ステータス、修正情報とともに脆弱性レポートに直接表示されます。

この機能はUltimateのお客様向けの無料ベータ版として提供されており、グループまたはプロジェクトの設定で有効にする必要があります。[イシュー583697](https://gitlab.com/gitlab-org/gitlab/-/issues/583697)でフィードバックをお待ちしています。

### 新しいセキュリティダッシュボードがデフォルトで有効に

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/security_dashboard/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/20213)

{{< /details >}}

新しいセキュリティダッシュボードが更新・モダナイズされました。以前はGitLab.comでのみ利用可能でしたが、GitLab DedicatedおよびGitLab Self-Managedでもデフォルトで有効になりました。

新機能には以下が含まれます。

- 以下をサポートする経時的な脆弱性チャート:
  - プロジェクトまたはレポートタイプによるフィルタリング。
  - レポートタイプと重大度によるグループ化。
  - 脆弱性レポート内の脆弱性への直接リンク。
- GitLabアルゴリズムに基づいてグループまたはプロジェクトの推定リスクを計算するリスクスコアモジュール。

新しいダッシュボードを使用するにはElasticsearchが必要です。

### CI/CDカタログへのコンポーネント公開を制御するインスタンス設定

<!-- categories: Pipeline Composition, Component Catalog -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../administration/settings/continuous_integration.md#restrict-cicd-catalog-publishing) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/582044)

{{< /details >}}

GitLab Self-ManagedおよびGitLab Dedicatedの管理者は、CI/CDカタログへのコンポーネント公開を許可するプロジェクトを制限できるようになりました。この新しい設定により、組織は公開できるコンポーネントを制御することで、厳選された信頼性の高いCI/CDカタログを維持できます。

管理者はコンポーネントの公開を許可するプロジェクトの許可リストを指定できます。許可リストにプロジェクトが登録されている場合、それらのプロジェクトのみがコンポーネントを公開できます。これにより、未承認または非公認のコンポーネントが公開コンポーネントのリストに混入することを防ぎ、すべてのコンポーネントが組織の標準とセキュリティ要件を満たすことを保証します。

これは、CI/CDコンポーネントエコシステムの管理を維持しながら、チームが承認済みコンポーネントを発見・再利用できるようにしたいエンタープライズのお客様にとって重要なガバナンス課題に対応するものです。

## エージェントコア

### マージリクエストの説明とコメントの両方で高度な検索が利用可能に

<!-- categories: Global Search -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/search/advanced_search.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/572590)

{{< /details >}}

高度な検索で、マージリクエストの説明とコメントの両方から一致する結果が返されるようになりました。以前は、マージリクエストの説明とコメントを別々に検索する必要がありました。

この改善により、GitLabのマージリクエストに対するより効率的で包括的な検索ワークフローが実現します。

### IDEでのGitLab Duo Chat（エージェント型）における`AGENTS.md`のサポート

<!-- categories: Editor Extensions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/duo_agent_platform/customize/agents_md.md)

{{< /details >}}

GitLab Duo Chatが`AGENTS.md`仕様をサポートするようになりました。これはAIコーディングアシスタントにコンテキストと指示を提供するための新興標準です。

GitLab Duoのみで利用可能なカスタムルールとは異なり、`AGENTS.md`ファイルは他のAIコーディングツールでも利用できます。これにより、ビルドコマンド、テスト手順、コードスタイルガイドライン、プロジェクト固有のコンテキストを、この仕様をサポートするあらゆるAIツールで利用できるようになります。

IDEのGitLab Duo Chatは、ユーザーまたはワークスペースレベルで設定されたリポジトリ内の`AGENTS.md`ファイルから利用可能な指示を自動的に適用します。モノレポの場合、サブディレクトリに`AGENTS.md`ファイルを配置して、異なるコンポーネントに合わせた指示を提供できます。

### AIエージェントとフローのバージョニング

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/duo_agent_platform/ai_catalog.md#agent-and-flow-versions) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/20022)

{{< /details >}}

プロジェクトのAIカタログからエージェントまたはフローを有効にすると、GitLabは特定のバージョンに固定するようになりました。

これにより、カタログアイテムが進化しても、AIを活用したワークフローが安定して予測可能な状態を維持できます。アップグレード前に新しいバージョンをテストして検証できます。

### AIゲートウェイのタイムアウト設定

<!-- categories: Model Personalization -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-timeout-for-the-ai-gateway) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/579183)

{{< /details >}}

GitLab Duo Self-Hostedで、セルフホストモデルへのリクエストのタイムアウト値を設定できるようになりました。

この値は60秒から600秒の範囲で設定できます。

### エージェントとフローを管理者に報告する

<!-- categories: AI Catalog -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/report_abuse.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/578591)

{{< /details >}}

問題のあるコンテンツに遭遇した際に、エージェントとフローをインスタンス管理者に報告できるようになりました。フィードバックを含む不正使用レポートを送信すると、管理者が有害なアイテムを非表示にするか削除するかを選択できます。

この機能を使用して、組織全体でエージェントとフローを安全に保ちましょう。

### ファウンデーショナルエージェントの可用性を設定する

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/_index.md#turn-foundational-agents-on-or-off) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/583815)

{{< /details >}}

トップレベルグループまたはインスタンスで利用可能なファウンデーショナルエージェントを制御できるようになりました。

すべてのファウンデーショナルエージェントをデフォルトでオンまたはオフにするか、組織のセキュリティとガバナンスポリシーに合わせて個々のエージェントを切り替えることができます。

## スケールとデプロイ

### Self-Managedのアクティブトライアルエクスペリエンスの強化

<!-- categories: Acquisition -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../subscriptions/free_trials.md#view-remaining-trial-period-days)

{{< /details >}}

Ultimateトライアル中のGitLab Self-Managedユーザーは、左サイドバーからアクティブなトライアルのステータス、残り日数、アクセス可能な機能、有効期限の通知にアクセスできるようになりました。

これらの機能強化により、トライアル期間に関する混乱を解消し、購入前に有料機能を評価しやすくなります。

## 統合されたDevOpsとセキュリティ

### Self-ManagedおよびDedicated環境で高度な脆弱性管理が利用可能に

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md#advanced-vulnerability-management) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/532703)

{{< /details >}}

高度な脆弱性管理はすべてのUltimateのお客様が利用可能で、以下の機能が含まれます。

- プロジェクトまたはグループの脆弱性レポートでOWASP 2021カテゴリ別にデータをグループ化。
- プロジェクトまたはグループの脆弱性レポートで脆弱性識別子によるフィルタリング。
- プロジェクトまたはグループの脆弱性レポートでリーチャビリティ値によるフィルタリング。
- ポリシー違反の回避理由によるフィルタリング。

### GLQLを活用したデータアナリストファウンデーショナルエージェント（ベータ版）

<!-- categories: Custom Dashboards Foundation -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/data_analyst.md)

{{< /details >}}

データアナリストエージェントは、GitLabプラットフォーム全体のデータをクエリ、可視化、表示するのに役立つ専門的なAIアシスタントです。GitLab Query Language（GLQL）を使用してデータを取得・分析し、プロジェクトに関する明確で実用的なインサイトを提供します。

サンプルプロンプトとユースケースはドキュメントに記載されています。

このエージェントは現在ベータ版です。改善のためのご意見や今後の方向性についてのインサイトを[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/574028)にお寄せください。

### コンプライアンス違反のフィルタリングとコメント

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_violations_report.md)

{{< /details >}}

コンプライアンス違反レポートは、組織のプロジェクト全体のすべてのコンプライアンス違反を一元的に表示します。このレポートはコントロール違反、関連する監査イベントに関する包括的な詳細を表示し、チームが違反ステータスを効果的に追跡できるようにします。

GitLab 18.7では、最も重要な違反を迅速に見つけるための強力なフィルタリング機能を導入しました。以下でフィルタリングできます。

- ステータス
- プロジェクト
- コントロール

チームはコメントを通じて違反の解決に直接協力できるようになりました。違反レコード内で、チームは以下を行えます。

- 調査のためにチームメンバーをタグ付けする
- 修正アプローチについて議論する
- 調査結果を文書化する（すべて違反レコード内で完結）

これらの機能により、コンプライアンス違反レポートが動的なコラボレーションプラットフォームへと進化し、組織がグループやプロジェクトのコンプライアンス違反を効率的に発見、分析、解決できるようになります。

### コンプライアンスフレームワークのコントロールに正確なスキャンステータスを表示

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_frameworks/_index.md#gitlab-compliance-controls)

{{< /details >}}

GitLabのコンプライアンスコントロールはコンプライアンスフレームワークで使用できます。コントロールは、コンプライアンスフレームワークに割り当てられたプロジェクトの設定や動作に対するチェックです。

以前は、スキャナーに関連するコントロール（たとえば、SASTが有効かどうかのチェック）では、コンプライアンスセンターがコントロールの成功または失敗ステータスを表示する前に、デフォルトブランチで成功したパイプラインが必要でした。

GitLab 18.7では、パイプライン全体のステータスに関係なく、スキャンの完了のみに基づいてコントロールの成功または失敗を表示するようにこの動作を変更しました。コントロールのコンプライアンスステータスは、パイプライン全体が成功したかどうかではなく、セキュリティスキャンが実行・完了したかどうかを反映するため、混乱を解消するのに役立ちます。

### 見出しアンカーリンクのアクセシビリティ改善

<!-- categories: Markdown -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/markdown.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/463385)

{{< /details >}}

見出しアンカーリンクが対応する見出しと同じテキストで読み上げられるようになり、スクリーンリーダーユーザーのエクスペリエンスが向上しました。リンクも見出しテキストの後に表示されるようになり、よりすっきりとした視覚的な表示になりました。

これらの変更により、すべてのユーザーがドキュメント、イシュー、その他のコンテンツの特定のセクションを理解してナビゲートしやすくなります。

### マージリクエスト承認ポリシーの警告モード

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#warn-mode) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19595)

{{< /details >}}

セキュリティチームは警告モードを使用して、適用前にセキュリティポリシーの影響をテスト・検証したり、セキュリティプログラムを加速するためのソフトゲートをロールアウトしたりできるようになりました。警告モードは、セキュリティポリシーのロールアウト中の開発者の摩擦を軽減しながら、検出された脆弱性への対処を継続的に確保するのに役立ちます。

[マージリクエスト承認ポリシー](../../user/application_security/policies/merge_request_approval_policies.md)を作成または編集する際に、`warn`（警告）または`enforce`（適用）の適用オプションを選択できるようになりました。

警告モードのポリシーは、マージリクエストをブロックせずに情報提供のボットコメントを生成します。ポリシーに関する質問の窓口として任意の承認者を指定できます。このアプローチにより、セキュリティチームはポリシーの影響を評価し、透明性のある段階的なポリシー採用を通じて開発者の信頼を構築できます。

マージリクエストの明確な指標により、ポリシーが`warn`（警告）または`enforce`（適用）モードであることがユーザーに伝わり、監査イベントがコンプライアンスレポートのためにポリシー違反と却下を追跡します。開発者はポリシー却下の理由を提供することでスキャン検出結果とライセンスポリシー違反を回避でき、より効果的なポリシー有効化のために開発者とセキュリティチームの間の協調的なフィードバックループが生まれます。

プロジェクトのデフォルトブランチでポリシー違反が検出されると、ポリシーはプロジェクトとグループの脆弱性レポートでポリシーに違反する脆弱性を特定します。プロジェクトの依存関係リストには、ライセンスコンプライアンスポリシー違反を示すバッジも表示されます。

さらに、APIを使用してプロジェクトのデフォルトブランチのポリシー違反のフィルタリングされたリストをクエリできます。

### GitLab.comのトライアル中にサービスアカウントが利用可能に

<!-- categories: System Access -->

{{< details >}}

- プラン: Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/service_accounts.md)

{{< /details >}}

サービスアカウントがトライアル期間中に利用可能になり、購入前に自動化とインテグレーションのワークフローをテストできるようになりました。

### GitLab Runner 18.7

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.7もリリースします。

GitLab Runnerは、CI/CDジョブを実行してGitLabインスタンスに結果を送信する高スケーラブルなビルドエージェントです。GitLab RunnerはGitLab CI/CDと連携して動作します。GitLab CI/CDはGitLabに含まれるオープンソースの継続的インテグレーションサービスです。

#### 新機能

- [taskscalerの予約スロットリングの設定可能化](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39161)
- [`FF_TIMESTAMPS`をデフォルトで有効化](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38378)

#### バグ修正

- [相対的な`builds_dir`が指定されている場合、Shellエグゼキューターが既存のGitリポジトリで失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39150)
- [GitLab Runner 18.6.0で後続のパイプライン実行時に認証失敗が発生する（SSHエグゼキューター）](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39140)
- [GitLab Runner 18.6.0で後続のパイプライン実行時に認証失敗が発生する（Shellエグゼキューター）](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39123)
- [Docker 29 API互換性の問題](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39129)
- [GitLab Runner 18.6.0でShellエグゼキューターを使用するとファイル変数を参照する変数が機能しなくなる](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39124)
- [GitLab RunnerがWindows 11 2025（25H2）をサポートするようになった](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39050)
- [ECR認証情報ヘルパーがDocker Autoscalerエグゼキューターで機能しない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38365)
- [GitLab Runnerでジョブのタイムアウトが適切に適用されるようになった](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27040)

すべての変更のリストはGitLab Runnerの[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-7-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-7-stable/CHANGELOG.md).md)に記載されています。

### マージリクエストで子パイプラインのレポートを表示する

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../ci/pipelines/downstream_pipelines.md#view-child-pipeline-reports-in-merge-requests) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18311)

{{< /details >}}

親子CI/CDパイプラインを使用しているチームは、以前はテスト結果、コード品質レポート、インフラストラクチャの変更を確認するために複数のパイプラインページを移動する必要があり、マージリクエストのレビューワークフローが中断されていました。

マージリクエストを離れることなく、単体テスト、コード品質チェック、Terraformプラン、カスタムメトリクスを含むすべてのレポートを統合ビューで表示・ダウンロードできるようになりました。

これによりコンテキストの切り替えが不要になり、マージリクエストの速度が向上し、品質を損なうことなく機能をより迅速にデリバリーできるようになります。

## 関連トピック

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.7)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.7)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.7)
- [非推奨と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
