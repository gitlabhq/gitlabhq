---
stage: Release Notes
group: Monthly Release
date: 2025-12-18
title: "GitLab 18.7リリースノート"
description: "GitLab 18.7でシークレットの有効性チェックが改善され、一般提供されました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年12月18日に、GitLab 18.7が次の機能を備えてリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: David Aniebo {#this-months-notable-contributor-david-aniebo}

David Aniebo氏が、GitLabの製品計画機能および[コントリビュータープラットフォーム](https://contributors.gitlab.com)への影響力のあるコントリビュートを評価され、18.7の注目すべきコントリビューターとして表彰されることを大変喜ばしく思います。

David氏の[作業アイテムリスト機能の改善](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207549)に関する取り組みは、彼の技術的専門知識と、GitLabの計画機能におけるユーザーエクスペリエンスの向上への献身を示しています。このコントリビュートは、チームが作業アイテムをより適切に整理管理し、何千ものGitLabユーザーにとってプロジェクト計画をより効率的にするのに役立ちます。

コードコントリビュート以外にも、David氏はコントリビュータープラットフォームの一貫した支持者であり、コミュニティのコントリビューターのエクスペリエンス向上に貢献してきました。彼の協力的なアプローチと応答性は、複数のグループのチームメンバーから称賛を得ています。

「Davidは、製品計画グループの取り組みにおいて素晴らしい働きをしており、彼のコントリビュートに非常に感謝しています。」と、製品計画担当エンジニアリングマネージャーのニックブラントは述べています。

David、GitLabへの貴重なコントリビュート、そしてコミュニティの協力的なメンバーであることに感謝いたします！今後のさらなるご活躍を期待しております。

## 主要な機能 {#primary-features}

### シークレットの有効性チェックが改善され、一般提供されました {#secret-validity-checks-improved-and-generally-available}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/validity_check.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16890)

{{< /details >}}

有効なシークレットがリポジトリのいずれかで漏洩した場合、迅速に対応する必要があります。緊急の脅威を優先順位付けできるように、有効性チェックにより、漏洩した認証情報がまだ使用できるかどうかを自動的に確認します。

GitLab 18.7では、以下が改善されました:

- ベンダーインテグレーション: Google Cloud、AWS、Postmanと統合されており、GitLabトークンの既存サポートに加えて利用できます。
- レポートフィルタリング: 脆弱性レポートを有効性ステータス（アクティブ、非アクティブ、アクティブの可能性あり）でフィルタリングして、シークレットの検出結果を迅速にトリアージし、優先順位を付けることができます。
- グループレベルAPI: 1回のAPIコールでグループ内のすべてのプロジェクトに対して有効性チェックを有効にし、組織全体へのロールアウトを効率化できます。

このリリースでは、有効性チェックは一般提供されています。

### Agentic Chatとエージェントのモデルを個別に選択 {#separate-model-selection-for-agentic-chat-and-agents}

<!-- categories: Model Personalization -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/work_items/19998)

{{< /details >}}

Agentic Chatと他のすべてのエージェントについて、トップレベルグループまたはインスタンスで個別のモデルを選択できるようになりました。これにより、GitLab Duo Agent Platformのモデル選択のオプションが増えます。

### 改善されたGitLab DuoとSDLCのトレンドダッシュボード {#improved-gitlab-duo-and-sdlc-trends-dashboard}

<!-- categories: DevOps Reports -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/analytics/duo_and_sdlc_trends.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19629)

{{< /details >}}

GitLab DuoとSDLCのトレンドダッシュボードは、GitLab Duoがソフトウェアデリバリーに与える影響を測定するための分析機能を強化します。このダッシュボードは、GitLab Duo機能の導入状況、パイプラインのパフォーマンス、デプロイ頻度やマージまでの平均時間などの一般的な開発メトリクスについて、6か月間のトレンド分析を提供するようになりました。

コード生成量とIDEまたは言語のトレンドをGitLab Duoコード提案で追跡することができ、チームが新しいGitLab Duo Agent Platformのフローを採用する様子を観察できます。強化されたユーザーレベルのメトリクスにより、チームは継続的な価値を提供する主要なDuo機能について、より深いインサイトを得ることができます。

新しい[インスタンスレベルのAI使用状況のためのエンドポイント](../../api/graphql/reference/_index.md#aiinstanceusagedata)が、インスタンス管理者向けに提供され、Postgres（3か月の保持）またはClickHouseからすべてのDuoデータを抽出できます。

[ClickHouseインテグレーション](../../integration/clickhouse.md)によって強化されたこのダッシュボードは、数百万のデータポイントで1秒未満のクエリパフォーマンスを実現します。Self-Managedインスタンスの場合、[ClickHouseインテグレーション](../../integration/clickhouse.md)の改善された推奨事項と設定ガイダンスを参照してください。

### 追加のプランナーエージェント機能がベータで利用可能 {#additional-planner-agent-features-available-in-beta}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/planner.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/576618)

{{< /details >}}

プランナーエージェントに、作成および編集機能がベータで追加されました！プランナーエージェントは、GitLabでプロダクトマネージャーを直接サポートするために構築された基本エージェントです。プランナーエージェントを使用して、GitLab作業アイテムを作成、編集、分析します。

手動で更新を追跡したり、作業の優先順位を付けたり、計画データを要約したりする代わりに、プランナーエージェントは、バックログの分析、RICEやMoSCoWのようなフレームワークの適用、そして本当に注意を必要とするものを表面化するのに役立ちます。これは、あなたのプランニングワークフローを理解し、より良く、より効率的な意思決定を行うために協力してくれる、積極的なチームメイトがいるようなものです。

[イシュー576622](https://gitlab.com/gitlab-org/gitlab/-/issues/576622)でフィードバックをお寄せください。

### CI/CDパイプラインにおける動的な入力オプション {#dynamic-input-options-in-cicd-pipelines}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../ci/inputs/_index.md#define-conditional-input-options-with-specinputsrules) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18546)

{{< /details >}}

直感的なウェブインターフェースを通じて新しいCI/CDパイプラインを作成する際、動的な入力選択を利用するように設定できます。

動的な入力オプションにより、以前の選択に基づいて入力選択オプションが動的に更新されるようにパイプラインを設定できるようになりました。たとえば、あるドロップダウンリストで入力を選択すると、2番目のドロップダウンリストに関連する入力オプションのリストが自動的に入力されます。

CI/CDインプットでは、以下が可能です:

- 事前に設定された入力でパイプラインをトリガーすることで、エラーを減らし、デプロイを効率化します。
- ユーザーがドロップダウンメニューからデフォルトとは異なる入力を選択できるようにします。
- 以前の選択に基づいてオプションが動的に更新される、カスケードドロップダウンリストを利用できるようになりました。

この動的な機能により、よりインテリジェントなコンテキスト認識型の入力設定を作成し、パイプライン作成プロセスをガイドして、エラーを減らし、有効な入力の組み合わせのみが選択されるようにすることができます。

### SAST誤検出判定（AI利用）(ベータ) {#sast-false-positive-detection-with-ai-beta}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/false_positive_detection.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18977)

{{< /details >}}

セキュリティチームは、SASTの検出結果が誤検出であることが判明し、真のセキュリティリスクから注意が逸れてしまう調査に多大な時間を費やすことがよくあります。

GitLab 18.7では、AIを活用したSAST誤検出判定を導入し、チームが重要な脆弱性に集中できるようにします。セキュリティスキャンが実行されると、GitLab Duoは、それぞれのCriticalおよびHighの重大度のSAST脆弱性を自動的に分析し、それが誤検出である可能性を判断します。

AI評価は脆弱性レポートに直接表示され、セキュリティエンジニアは迅速かつ自信を持ってトリアージの決定を下すための即座のコンテキストを得ることができます。

主な機能は次のとおりです:

- 自動分析: 各セキュリティスキャンの後に誤検出判定が自動的に実行され、手動でのトリガーは不要です。
- 手動トリガーオプション: ユーザーは、オンデマンド分析のために、脆弱性詳細ページで個別の脆弱性に対する誤検出判定を手動でトリガーすることができます。
- 影響の大きい検出結果に焦点を当てる: 信号対雑音比の改善を最大化するために、CriticalおよびHighの重大度の脆弱性に限定されます。
- コンテキストAI推論: 各評価には、コードのコンテキストと脆弱性特性に基づいて、その発見が真陽性である可能性とそうでない可能性を説明する説明が含まれています。
- シームレスなワークフローインテグレーション: 結果は既存の重大度、ステータス、および修正情報とともに脆弱性レポートに直接表示されます。

この機能は、Ultimateのお客様向けの無料ベータ版として利用可能であり、グループまたはプロジェクトの設定で有効にする必要があります。[イシュー583697](https://gitlab.com/gitlab-org/gitlab/-/issues/583697)でのフィードバックをお待ちしております。

### 新しいセキュリティダッシュボードがデフォルトで有効になりました {#new-security-dashboards-enabled-by-default}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/security_dashboard/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/20213)

{{< /details >}}

新しいセキュリティダッシュボードは更新され、モダナイズされました。これらのダッシュボードは以前はGitLab.comで利用可能でしたが、GitLab DedicatedおよびGitLab Self-Managedでデフォルトで有効になりました。

新機能は以下のとおりです:

- 時間の経過に伴う脆弱性のチャート。以下をサポートします:
  - プロジェクトまたはレポートタイプに基づくフィルタリング。
  - レポートタイプと重大度によるグループ化。
  - 脆弱性レポート内の脆弱性への直接リンク。
- GitLabアルゴリズムに基づいてグループまたはプロジェクトのリスクを推定するリスクスコアモジュール。

新しいダッシュボードを使用するにはElasticsearchが必要であることに注意してください。

### コンポーネントをCI/CDカタログに公開することを制御するインスタンス設定 {#instance-setting-to-control-publishing-of-components-to-the-cicd-catalog}

<!-- categories: Pipeline Composition, Component Catalog -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../administration/settings/continuous_integration.md#restrict-cicd-catalog-publishing) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/582044)

{{< /details >}}

GitLab Self-ManagedおよびGitLab Dedicatedの管理者は、CI/CDカタログにコンポーネントを公開することを許可されるプロジェクトを制限できるようになりました。この新しい設定により、組織は公開可能なコンポーネントを制御することで、厳選された信頼性の高いCI/CDカタログを維持できます。

管理者は、コンポーネントを公開することを承認されたプロジェクトの許可リストを指定できるようになりました。許可リストにプロジェクトが入力された場合、それらのプロジェクトのみがコンポーネントを公開できます。これにより、不正なまたは未承認のコンポーネントが公開されているコンポーネントのリストを乱雑にするのを防ぎ、すべてのコンポーネントが組織の標準とセキュリティ要件を満たすことを保証します。

これは、チームが承認されたコンポーネントを発見して再利用できるようにしながら、CI/CDコンポーネントのエコシステムを制御したいと考えるエンタープライズ顧客にとっての主要なガバナンスの課題に対応します。

## エージェント型コア {#agentic-core}

### マージリクエストの説明とコメントの両方で高度な検索が利用可能 {#advanced-search-available-for-both-merge-request-descriptions-and-comments}

<!-- categories: Global Search -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/search/advanced_search.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/572590)

{{< /details >}}

高度な検索で、マージリクエストの説明とコメントの両方から一致する結果が返されるようになりました。以前は、ユーザーはマージリクエストの説明とコメントを個別に検索する必要がありました。

この改善により、GitLabマージリクエストの検索ワークフローがより効率的かつ包括的になります。

### `AGENTS.md`をサポート（GitLab Duo Chat（エージェント型）のIDE内） {#support-for-agentsmd-with-gitlab-duo-chat-agentic-in-ides}

<!-- categories: Editor Extensions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/customize_duo/agents_md.md)

{{< /details >}}

GitLab Duo Chatは、AIコーディングアシスタントにコンテキストと指示を提供する新しい標準である`AGENTS.md`仕様をサポートするようになりました。

GitLab Duoでのみ利用可能なカスタムルールとは異なり、`AGENTS.md`ファイルは他のAIコーディングツールでも使用できます。これにより、ビルドコマンド、テスト手順、コードスタイルガイドライン、およびプロジェクト固有のコンテキストが、その仕様をサポートするすべてのAIツールで利用可能になります。

IDE内のGitLab Duo Chatは、ユーザーまたはワークスペースレベルで設定されたリポジトリ内の`AGENTS.md`ファイルから利用可能な指示を自動的に適用します。モノレポの場合、`AGENTS.md`ファイルをサブディレクトリに配置して、異なるコンポーネントに合わせた指示を提供できます。

### AIエージェントとフローのバージョニング {#ai-agent-and-flow-versioning}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/duo_agent_platform/ai_catalog.md#agent-and-flow-versions) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/20022)

{{< /details >}}

プロジェクトでAIカタログからエージェントまたはフローを有効にすると、GitLabはそれを特定のバージョンに固定するようになりました。

これにより、カタログアイテムが進化してもAIを活用したワークフローは安定して予測可能に保たれるため、アップグレードする前に新しいバージョンをテストおよび検証することができます。

### AIゲートウェイのタイムアウト設定 {#ai-gateway-timeout-setting}

<!-- categories: Model Personalization -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-timeout-for-the-ai-gateway) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/579183)

{{< /details >}}

GitLab Duo Self-Hostedでは、セルフホストモデルへのリクエストのタイムアウト値を設定できるようになりました。

この値は60秒から600秒まで設定できます。

### エージェントとフローを管理者にレポート {#report-agents-and-flows-to-administrators}

<!-- categories: AI Catalog -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/report_abuse.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/578591)

{{< /details >}}

問題のあるコンテンツに遭遇した場合、エージェントとフローをインスタンス管理者にレポートすることができるようになりました。フィードバックを含む悪用レポートを提出すると、管理者は有害なアイテムを非表示にするか削除するかを選択できます。

この機能を使用して、組織全体でエージェントとフローを安全に保ちます。

### 基本エージェントの利用可能性を設定 {#configure-foundational-agent-availability}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/_index.md#turn-foundational-agents-on-or-off) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/583815)

{{< /details >}}

トップレベルグループまたはインスタンスで、どの基本エージェントが利用可能かを制御できるようになりました。

すべての基本エージェントをデフォルトでオンまたはオフにするか、個別のエージェントを切替て、組織のセキュリティおよびガバナンスポリシーに合わせることができます。

## 規模とデプロイ {#scale-and-deployments}

### Self-Managed向けの強化されたアクティブトライアルエクスペリエンス {#enhanced-active-trial-experience-for-self-managed}

<!-- categories: Acquisition -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../subscriptions/free_trials.md#view-remaining-trial-period-days)

{{< /details >}}

Ultimateトライアル中のGitLab Self-Managedユーザーは、左側のサイドバーからアクティブなトライアルステータス、残りの日数、アクセス可能な機能、および有効期限通知にアクセスできるようになりました。

これらの機能強化により、トライアル期間に関する混乱が解消され、購入前に有料機能を評価しやすくなります。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### Self-ManagedおよびDedicated環境で利用可能な高度な脆弱性管理 {#advanced-vulnerability-management-available-in-self-managed-and-dedicated-environments}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md#advanced-vulnerability-management) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/532703)

{{< /details >}}

高度な脆弱性管理は、すべてのUltimate顧客が利用でき、以下の機能が含まれます:

- プロジェクトまたはグループの脆弱性レポートで、データをOWASP 2021カテゴリ別にグループ化します。
- プロジェクトまたはグループの脆弱性レポートにおける脆弱性識別子に基づくフィルタリング。
- プロジェクトまたはグループの脆弱性レポートにおける到達可能性の値に基づくフィルタリング。
- ポリシー違反バイパス理由によるフィルタリング。

### GLQLを搭載したデータアナリスト基本エージェント（ベータ） {#data-analyst-foundational-agent-powered-by-glql-beta}

<!-- categories: Custom Dashboards Foundation -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/data_analyst.md)

{{< /details >}}

データ分析エージェントは、GitLabプラットフォーム全体にわたるデータのクエリ、可視化、抽出を支援する特化型AIアシスタントです。GitLab Query Language（GLQL）を使用してデータを取得および分析し、プロジェクトに関する明確で実用的なインサイトを提供します。

ドキュメントで例となるプロンプトとユースケースを見つけることができます。

このエージェントは現在ベータ版であるため、改善に役立てるため、また今後どのような方向性を望むかについてのインサイトを提供するために、[フィードバック](https://gitlab.com/gitlab-org/gitlab/-/issues/574028)イシューでご意見をお聞かせください。

### コンプライアンス違反のフィルタリングとコメント {#filter-and-comment-on-compliance-violations}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_violations_report.md)

{{< /details >}}

コンプライアンス違反レポートは、組織のプロジェクト全体におけるすべてのコンプライアンス違反を一元的に表示します。このレポートには、制御違反、関連する監査イベントに関する包括的な詳細が表示され、チームが違反ステータスを効果的に追跡することを可能にします。

GitLab 18.7では、最も重要な違反を迅速に見つけるのに役立つ強力なフィルタリング機能を導入しました。次の項目でフィルタリングできます:

- ステータス
- プロジェクト
- コントロール

チームはコメントを通じて違反の解決に直接協力することもできるようになりました。違反記録自体の中で、チームは次のことができます:

- 調査のためにチームメンバーをタグ付けする
- 修正アプローチを議論する
- 検出結果をドキュメント化する（すべて違反記録自体の中に）。

これらの機能は連携して、コンプライアンス違反レポートを動的なコラボレーションプラットフォームへと進化させ、組織がグループおよびプロジェクト内のコンプライアンス違反を効率的に発見、分析、および解決することを可能にします。

### コンプライアンスフレームワークのコントロールで正確なスキャンステータスを表示 {#compliance-framework-controls-show-accurate-scan-status}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/compliance/compliance_frameworks/_index.md#gitlab-compliance-controls)

{{< /details >}}

GitLabのコンプライアンスコントロールは、コンプライアンスフレームワークで使用できます。コントロールは、コンプライアンスフレームワークに割り当てられたプロジェクトの設定または動作に対するチェックです。

以前は、スキャナーに関連するコントロール（たとえば、SASTが有効になっているかどうかのチェック）では、コンプライアンスセンターがコントロールの成功または失敗ステータスを表示する前に、プロジェクトのデフォルトブランチでパイプラインが成功している必要がありました。

GitLab 18.7では、この動作が変更され、全体的なパイプラインステータスに関係なく、スキャンの完了のみに基づいてコントロールが成功したか失敗したかを示すようになりました。これにより、コントロールのコンプライアンスステータスが、セキュリティスキャンが実行され完了したかどうかを反映し、パイプライン全体が合格したかどうかを反映しないため、混乱を緩和するのに役立ちます。

### 見出しアンカーリンクのアクセシビリティ改善 {#accessibility-improvements-for-heading-anchor-links}

<!-- categories: Markdown -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/markdown.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/463385)

{{< /details >}}

見出しアンカーリンクは、対応する見出しと同じテキストで読み上げられるようになり、スクリーンリーダーユーザーのエクスペリエンスが向上しました。リンクは見出しテキストの後に表示され、よりすっきりとした視覚的な表現を提供します。

これらの変更により、すべてのユーザーがドキュメント、イシュー、その他のコンテンツの特定のセクションを理解し、ナビゲートしやすくなります。

### マージリクエスト承認ポリシーにおける警告モード {#warn-mode-in-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#warn-mode) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19595)

{{< /details >}}

セキュリティチームは、警告モードを使用して、施行を適用する前、またはセキュリティプログラムを加速するためのソフトゲートをロールアウトする前に、セキュリティポリシーの影響をテストおよび検証することができるようになりました。警告モードは、セキュリティポリシーのロールアウト中のデベロッパーの摩擦を軽減し、検出された脆弱性が対処されることを引き続き保証します。

[マージリクエスト承認ポリシー](../../user/application_security/policies/merge_request_approval_policies.md)を作成または編集する際に、`warn`または`enforce`の適用オプションを選択できるようになりました。

警告モードのポリシーは、マージリクエストをブロックすることなく、情報提供のボットコメントを生成します。オプションの承認者は、ポリシーに関する問い合わせの連絡先として指定できます。このアプローチにより、セキュリティチームはポリシーの影響を評価し、透明で段階的なポリシー採用を通じてデベロッパーの信頼を構築できます。

マージリクエストの明確なインジケーターは、ポリシーが`warn`または`enforce`モードである時期をユーザーに示し、監査イベントはコンプライアンスレポートのためにポリシーの違反と無視を追跡します。デベロッパーは、ポリシーの無視の理由を提供することで、スキャンの検出結果とライセンスコンプライアンスポリシー違反をバイパスすることができ、デベロッパーとセキュリティチーム間の協力的なフィードバックループを作成し、より効果的なポリシーの有効化を実現します。

プロジェクトのデフォルトブランチでポリシー違反が検出された場合、ポリシーはプロジェクトおよびグループの脆弱性レポートでポリシーに違反する脆弱性を特定します。プロジェクトの依存関係リストにも、ライセンスコンプライアンスポリシー違反を示すバッジが表示されます。

さらに、APIを使用して、プロジェクトのデフォルトブランチにあるポリシー違反のフィルタリングされたリストをクエリすることができます。

### GitLab.comでのトライアル期間中に利用可能なサービスアカウント {#service-accounts-available-during-trials-on-gitlabcom}

<!-- categories: System Access -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/service_accounts.md)

{{< /details >}}

サービスアカウントはトライアル期間中に利用可能になり、購入前に自動化およびインテグレーションワークフローをテストできます。

### GitLab Runner 18.7 {#gitlab-runner-187}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.7もリリースします！

GitLab Runnerは、CI/CDジョブを実行し、その結果をGitLabインスタンスに送信する、拡張性の高いビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [Configurable taskscaler reservation throttling](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39161)
- [`FF_TIMESTAMPS`をデフォルトで有効化](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38378)

#### バグ修正 {#bug-fixes}

- [相対的な`builds_dir`が指定されている場合、既存のGitリポジトリでShellexecutorが失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39150)
- [GitLab Runner 18.6.0での連続するパイプライン実行における認証失敗（SSHexecutor）](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39140)
- [GitLab Runner 18.6.0での連続するパイプライン実行における認証失敗（shellexecutor）](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39123)
- [Docker 29 APIの互換性イシュー](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39129)
- [ファイル変数を参照する変数が、shellexecutorを使用するGitLab Runner 18.6.0で機能しなくなった](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39124)
- [GitLab RunnerはWindows 11 2025 (25H2)をサポート](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39050)
- [ECR認証情報ヘルパーがDocker Autoscalerexecutorで機能しない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38365)
- [ジョブタイムアウトがGitLab Runnerで適切に適用されるようになった](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27040)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-7-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-7-stable/CHANGELOG.md).md)にあります。

### 子パイプラインレポートをマージリクエストで表示する {#view-child-pipeline-reports-in-merge-requests}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../ci/pipelines/downstream_pipelines.md#view-child-pipeline-reports-in-merge-requests) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18311)

{{< /details >}}

親子CI/CDパイプラインを使用するチームは、以前はテスト結果、コード品質レポート、およびインフラストラクチャの変更を確認するために複数のパイプラインページをナビゲートする必要があり、マージリクエストのレビューワークフローを中断していました。

今後は、マージリクエストを離れることなく、単体テスト、コード品質チェック、Terraformプラン、カスタムメトリクスなど、すべてのレポートを統一されたビューで表示およびダウンロードできます。

これにより、コンテキスト切り替えが不要になり、マージリクエストの開発速度が向上し、チームは品質を損なうことなく機能をより迅速に提供できるようになります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.7)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.7)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.7)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
