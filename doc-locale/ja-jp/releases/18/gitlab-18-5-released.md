---
stage: Release Notes
group: Monthly Release
date: 2025-10-16
title: "GitLab 18.5リリースノート"
description: "GitLab 18.5は、特別なエージェントであるGitLab Duoプランナーとプロダクトマネージャーチームメンバー（ベータ）とともにリリースされました。"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年10月16日、GitLab 18.5に次の機能がリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Jose Gabriel Companioni Benitez {#this-months-notable-contributor-jose-gabriel-companioni-benitez}

彼のブログ投稿[「GitLabはいかにあなたのキャリアを向上させることができるか」](https://compacompila.com/posts/gitlab-open-source-community/)で、Joseは次のように述べています: 「私にとって、プロフェッショナルな開発の観点からGitLabが提供する主な利点は、それがオープンソースであることです。」彼は、「GitLabにとって、誰でもコントリビュートできることが重要であり、そのためコントリビューターのオンボーディングプロセスを非常に真剣に受け止めている」と付け加えています。

Joseが9月に初めてコントリビューターとなってから10月にNotable Contributorになるまでの道のりは、GitLabの協調的なコミュニティの力を示しています。コミュニティオフィスアワー、Discordでのディスカッション、ペアリングセッションに積極的に参加することで、Joseは、[ドキュメント](https://gitlab.com/gitlab-org/cli/-/merge_requests/2392) 、[コード](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2690)、コミュニティサポートにわたる多様なコントリビュートを通じて、レベル3のコントリビューターに迅速に成長するのに役立つ協力的な環境を見つけました。

GitLabコミュニティは、コントリビューターがお互いをサポートし、共に成長できる温かい場所を提供しています。オープンソースの旅を始めたばかりでも、スキルを深めたいと考えている場合でも、私たちのコミュニティはあなたの成功をサポートするためにここにいます。

コントリビュートの詳細については、[GitLab Contributor Platform](https://contributors.gitlab.com/)を参照してください。

Joseさん、素晴らしいお仕事ありがとうございます！ 🚀

## 主要な機能 {#primary-features}

### GitLab Duo Planner、専門エージェント兼プロダクトマネージャーチームメンバー（ベータ） {#gitlab-duo-planner-a-specialized-agent-and-product-manager-team-member-beta}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/planner.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/576618)

{{< /details >}}

GitLab内でプロダクトマネージャーを直接サポートするために構築されたGitLab DuoエージェントであるGitLab Duo Plannerと連携します。手動で更新を追いかけたり、作業に優先順位を付けたり、計画データを要約したりする代わりに、GitLab Duo Plannerはバックログを分析し、RICEやMoSCoWのようなフレームワークを適用し、真に注意が必要なものを表面化するのに役立ちます。これは、あなたの計画ワークフローを理解し、より良く、より迅速な意思決定を行うためにあなたと協力する、積極的なチームメイトがいるようなものです。この機能は現在ベータ版です。[issue 576622](https://gitlab.com/gitlab-org/gitlab/-/issues/576622)でフィードバックをお寄せください。

### Duo AIカタログ向けのGitLabセキュリティ分析エージェント（ベータ） {#gitlab-security-analyst-agent-for-duo-agent-catalog-beta}

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19659)

{{< /details >}}

GitLab Duo Agent Platform内のエージェントは、GitLab内でタスクを実行し、複雑な質問に答えるために使用できます。ユーザーは、カスタムエージェントを作成して、マージリクエストの作成やコードのレビューといった特定のタスクを達成することも、AIカタログを使用してGitLabのエージェントを見つけることもできます。

GitLab 18.5では、AIカタログで利用可能なベータ機能として、GitLabセキュリティ分析エージェントをリリースします。特定のプロジェクトでGitLabセキュリティ分析エージェントを使用するには、GitLab Duo Agentic Chatでそのエージェントを選択して有効にします。そのエージェントは次のタスクを実行できます:

- 指定されたプロジェクト内のすべての脆弱性をリストします。
- 脆弱性の詳細情報（CVEデータおよびEPSSスコアを含む）を取得します。
- 脆弱性を確認して無視する。
- 脆弱性の重大度レベルを更新します。
- 脆弱性のステータスを`detected`に戻します。
- 脆弱性のイシューを作成するか、脆弱性を既存のイシューにリンクします。

GitLabセキュリティ分析エージェントを使用すると、ユーザーはAIを活用した自動化とインテリジェントな分析を通じて面倒なセキュリティワークフローを実行できます。これにより、エンジニアは真の脅威に集中し、GitLabセキュリティ分析エージェントが反復的な評価とドキュメント作成を処理します。GitLabセキュリティ分析エージェントがGitLab Duo Chatを使用する場合、アドオン付きのUltimateのお客様のみが利用できることにご注意ください。

この機能はベータ版であり、[issue 576916](https://gitlab.com/gitlab-org/gitlab/-/issues/576916)でのフィードバックをお待ちしております。

### Maven仮想レジストリがベータ版として利用可能になりました {#maven-virtual-registry-now-available-in-beta}

<!-- categories: Virtual Registry -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/packages/virtual_registry/maven/_index.md#manage-virtual-registries) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14137)

{{< /details >}}

GitLab 18.5では、Maven仮想レジストリ管理のための包括的なWebベースインターフェースを導入しました。以前は、プラットフォームエンジニアはAPIコールを通じてのみ仮想レジストリを構成および管理でき、日常的なメンテナンスタスクが面倒で専門知識が必要でした。

このWebベースのアプローチにより、プラットフォームエンジニアリングチームの運用オーバーヘッドが大幅に削減されます。古いキャッシュエントリのクリア、パフォーマンス最適化のためのアップストリームの再配置、接続テストといった一般的なタスクは、クリック操作で実行できるようになりました。開発チームは、依存関係の設定に対する可視性を高め、ビルドパフォーマンスとセキュリティポリシーについてより情報に基づいた議論を可能にします。

Maven仮想レジストリは、PremiumおよびUltimateのお客様向けに引き続きベータ版で提供されます。現在のベータ版の制限には、トップレベルグループあたり最大20個の仮想レジストリと、仮想レジストリあたり20個のアップストリームが含まれます。

Maven仮想レジストリベータプログラムにご参加いただき、最終リリースの形成にご協力ください。[issue 543045](https://gitlab.com/gitlab-org/gitlab/-/issues/543045)でフィードバックやご提案を共有することを検討してください。

### 新しい個人用ホームページで中断したところから再開します {#pick-up-where-you-left-off-on-the-new-personal-homepage}

<!-- categories: Navigation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../tutorials/personal_homepage/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16657)

{{< /details >}}

GitLabの重要なアクティビティをすべて1か所に統合した新しい個人用ホームページにアクセスできるようになり、中断したところから簡単に再開できます。ホームページには、To-Doアイテム、割り当てられたイシュー、マージリクエスト、レビューリクエスト、最近表示したコンテンツがまとめられており、GitLabの広範な領域をナビゲートし、最も重要なことに集中するのに役立ちます。

### GitLab Duo Agentic ChatのモデルオプションとしてGPT-5が利用可能になりました {#gpt-5-now-available-as-a-model-option-for-gitlab-duo-agentic-chat}

<!-- categories: Model Personalization -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo_chat/agentic_chat.md#select-a-model) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19124)

{{< /details >}}

OpenAI GPT-5が、GitLab Duo Agent Platform用のモデルを選択する際のGitLab AIベンダーモデルとして利用可能になりました。GitLab.comのトップレベルグループのオーナーおよびSelf-ManagedとDedicatedのインスタンス管理者によって設定された場合、エンドユーザーはGitLab Duo機能でGPT-5を使用することを選択できます。トップレベルのオーナーと管理者は、ネームスペースまたはインスタンス設定を通じて組織全体のモデル設定を引き続き行うか、利用可能なすべてのGitLab AIベンダーモデルからエンドユーザーが選択できるようにすることができます。

GPT-5の使用を開始するには、GitLab Duo Chatのモデルドロップダウンリストから優先するモデルを選択してください。

### インスタンス全体のコンプライアンスとセキュリティポリシー管理 {#instance-wide-compliance-and-security-policy-management}

<!-- categories: Compliance Management, Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../security/compliance_security_policy_management.md)

{{< /details >}}

エンタープライズユーザーは、複数のトップレベルグループ全体で、[コンプライアンスフレームワーク](../../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md)と[セキュリティポリシー](../../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md)を管理したいと考えています。これは、インスタンス内のすべてのグループが次の場合によく当てはまります:

- 同じコンプライアンスフレームワークを共有します。たとえば、グループ内のすべてのプロジェクトがISO 27001標準に準拠する必要がある場合などです。
- 同様のセキュリティポリシーを適用する。たとえば、すべてのグループが同じパイプライン実行ポリシーを共有する場合などです。

GitLab 18.5では、GitLab Self-ManagedおよびDedicatedインスタンス向けに、セキュリティポリシーとコンプライアンスフレームワークの管理をインスタンス上で一元化するためのコンプライアンスおよびセキュリティポリシーグループを導入します。このリリースにより、単一のトップレベルグループからコンプライアンスフレームワークとセキュリティポリシーを作成、設定、割り当て、インスタンス全体の他のすべてのトップレベルグループに適用できるようになりました。

コンプライアンスおよびセキュリティポリシーグループを使用すると、コンプライアンスフレームワークとセキュリティポリシーを管理および編集できる信頼できる唯一の情報源が得られます。グループ内のセキュリティおよびコンプライアンスユーザーは、インスタンス全体のすべてのプロジェクトにコンプライアンスフレームワークとセキュリティポリシーを適用できます。

コンプライアンスおよびセキュリティポリシーグループは、インスタンス全体のコンプライアンスおよびセキュリティ要件の管理と適用を容易にします。ただし、グループは、それらのグループで発生する可能性のある特定の状況またはワークフローに対処するために、独自のコンプライアンスフレームワークとセキュリティポリシーを作成する機能を保持しています。

この機能は、GitLab Self-ManagedおよびDedicatedのお客様向けです。GitLab.comのお客様は、セキュリティポリシープロジェクトを使用して、単一のトップレベルグループまたはネームスペース内でフレームワークとポリシーを一元的に管理できます。

コンプライアンスおよびセキュリティポリシーグループの[コンプライアンスフレームワーク](../../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md)と[セキュリティポリシー](../../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md)の詳細をご覧ください。

### DAST認証スクリプト {#dast-authentication-scripts}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dast/browser/configuration/authentication_scripts.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17018)

{{< /details >}}

CI/CDの設定にスクリプトを追加して、DAST認証ワークフローを自動化できるようになりました。認証スクリプトは、時限式ワンタイムパスワード（OTP MFA）のサポートを含む、複雑な認証フローの自動化を可能にします。

この機能強化により、チームは徹底した自動セキュリティスキャンを実施しながら、重要なセキュリティ管理を維持できます。実際の認証シナリオをサポートすることで、スクリプトは摩擦を軽減し、本番環境ソフトウェアの正確なセキュリティ評価を保証します。

## エージェント型コア {#agentic-core}

### CLIエージェント用の追加のトリガー {#additional-triggers-for-cli-agents}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/duo_agent_platform/triggers/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/567787)

{{< /details >}}

追加のイベントを使用してCLIエージェントをトリガーできるようになり、プロジェクト全体でエージェントがアクションを実行する場所とタイミングをより柔軟に制御できるようになりました。既存の**mention**トリガーに加えて、以下を使用できます:

- **割り当て**: 割り当て: マージリクエストまたはイシューが割り当てられたときにエージェントをトリガーします。
- **レビュアーを割り当てる**: レビュアーを割り当てる: マージリクエストにレビュアーが追加されたときにエージェントをトリガーします。

### GitLab Duo Agent Platformがベータ版になりました {#gitlab-duo-agent-platform-for-gitlab-duo-self-hosted-now-in-beta}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/558083)

{{< /details >}}

GitLab Duo Agent Platformは、GitLab Duo Self-Hosted向けにベータ版になりました。この機能は、すべてのSelf-Managed GitLab Duo Enterpriseのお客様が利用できます。Self-Managedインスタンス管理者は、AWS BedrockまたはAzure OpenAIを使用して、Anthropic ClaudeまたはOpenAI GPTモデルをGitLab Duo Agent Platformで使用するように設定できます。Self-Hostedの管理者も設定できます

[互換性のあるモデル](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models)

をGitLab Duo Agent Platformで使用できます。

### GitLab Duo Chat（Classic）でCodestralがサポートされました {#codestral-now-supported-for-gitlab-duo-chat-classic}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/550266)

{{< /details >}}

Mistral Codestralを

GitLab Duo Self-Hosted

で従来のDuo Chatに使用できるようになりました。このモデルは、GitLab Self-Managedインスタンス上のGitLab Duo Self-Hostedのお客様にサポートされています。

### GitLab Duo Self-Hosted向けのGitLab Duo Agent Platformと互換性のあるGPT OSSモデル {#gpt-oss-models-compatible-with-gitlab-duo-agent-platform-for-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19348)

{{< /details >}}

GitLab Duo Self-Hosted向けのGitLab Duo Agent PlatformでGPT OSSモデルを使用できるようになりました。

## 規模とデプロイ {#scale-and-deployments}

### 強化された**管理者**エリアのグループリスト {#enhanced-admin-area-groups-list}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../administration/admin_area.md#administering-groups) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17783)

{{< /details >}}

GitLabの管理者向けに、より一貫した体験を提供するために、**管理者**エリアのグループリストをアップグレードしました:

- 遅延削除保護: グループの削除は、GitLab全体で使用されている安全な削除フローと同じになり、偶発的なデータ損失を防ぎます。
- より高速な操作: ページのリロードなしでグループをフィルタリング、ソート、ページ分割することで、より応答性の高い体験を提供します。
- 一貫したインターフェース: グループリストは、GitLab全体の他のグループリストの外観と動作に一致するようになりました。

この更新により、管理者のエクスペリエンスがGitLabのデザイン標準に準拠し、データを保護するための重要な安全機能が追加されます。今後のグループ管理の機能強化は、プラットフォーム全体のすべてのグループリストに自動的に表示されます。

### グループのナビゲーション体験を更新 {#updated-navigation-experience-for-groups}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/group/_index.md#view-a-group) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13790)

{{< /details >}}

GitLab全体でより一貫した効率的な体験を提供するために、グループ概要リストに変更を加えました。これらの改善により、グループやプロジェクトのナビゲートが容易になり、より価値のある情報が一目でわかるようになります:

- より豊富なプロジェクト情報: プロジェクトは、スター、フォーク、イシュー、マージリクエスト、関連する日付を表示するようになり、活動の概要を一目で完全に把握できます。
- 合理化されたアクション: アクションメニューを使用して、概要から直接グループやプロジェクトを編集または削除します。アーカイブ済みおよび削除保留中のアイテムは、**非アクティブ**タブに表示されます。
- 一貫した体験: グループ概要は、GitLab全体で他のグループおよびプロジェクトリストの外観と動作に一致するようになり、より直感的な体験を提供します。

これらの機能強化により、より多くの情報とアクションをすぐに利用できるようになり、時間を節約できます。このアップデートは、一括編集や高度なフィルタリングオプションなどの将来の機能の基盤も築きます。

### グループとプロジェクトの非アクティブアイテム管理の改善 {#improved-inactive-item-management-for-groups-and-projects}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/working_with_projects.md#view-inactive-projects) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/526211)

{{< /details >}}

**非アクティブ**タブは、GitLab全体のすべての非アクティブアイテムを一貫して1つの統合された場所に表示するようになりました。これには、アーカイブされたプロジェクト、削除保留中のプロジェクト、および削除保留中のグループが含まれます。このタブは、グループ概要ページだけでなく、**あなたの作業**、**検索**、および**管理者**エリア全体のグループおよびプロジェクトリストでも利用できます。適切な権限を持つすべてのユーザーは非アクティブなアイテムを表示できますが、グループオーナーとプロジェクトオーナーおよびメンテナーのみがそれらに対してさらにアクションを実行できます。このアップデートの一環として、新しい`active`パラメータがプロジェクトとグループのREST API、およびGraphQL APIの両方で利用できるようになりました。

非アクティブなコンテンツの管理は、GitLabインスタンスを維持する上で重要な部分です。このアップデートにより、アーカイブされたコンテンツや削除保留中のコンテンツを見つけて回復することが容易になり、偶発的な貴重な作業の損失のリスクを減らしつつ、GitLabリソースに対するより良い制御を維持できます。アクティブなコンテンツと非アクティブなコンテンツを明確に分離することで、GitLabのすべての領域でグループやプロジェクトをナビゲートする際の、より焦点を絞った検索体験も提供されます。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### GitLab Duo Agentic Chatの新しい脆弱性管理機能 {#new-vulnerability-management-features-in-gitlab-duo-agentic-chat}

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo_chat/agentic_chat.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19639)

{{< /details >}}

GitLab Duo Agentic Chatは、GitLab Duo Chatの強化されたバージョンです。これは、GitLabプロジェクトの複数のソースから情報を検索し、取得し、組み合わせて、より徹底的で関連性の高い回答を提供します。いくつかのユースケースとして、プロジェクトの検索、ファイルの読み取りとリスト表示、GitLab Duo Chatに提供されたプロンプトに基づいてファイルを自律的に作成および変更する機能があります。

GitLab 18.5では、Agentic Chatのユースケースが拡張され、セキュリティスキャナーからの脆弱性管理も含まれるようになりました。Agentic Chatに脆弱性管理ツールを追加することで、退屈なセキュリティワークフローをAIを活用した自動化とインテリジェントな分析を通じて変革し、セキュリティプロフェッショナルが自然言語コマンドを通じて脆弱性を効率的にトリアージ、管理、修正することを可能にします。これにより、脆弱性ダッシュボードを手動でクリックする時間をなくし、以前はカスタムスクリプトや面倒な手作業が必要だった複雑な一括操作を効率化します。

新しい脆弱性管理ツールがGitLab Duo Chatに追加されたことで、GitLab Duoを持つUltimateユーザーは次のことを実行できます:

- 指定されたプロジェクト内のすべての脆弱性をリストします。
- 脆弱性の詳細情報（CVEデータおよびEPSSスコアを含む）を取得します。
- 脆弱性を確認して無視する。
- 脆弱性の重大度レベルを更新します。
- 脆弱性のステータスを`detected`に戻します。
- 脆弱性のイシューを作成するか、脆弱性を既存のイシューにリンクします。

これらのツールは、セキュリティワークフローを反応的な手動トリアージからインテリジェントな修正に変革し、AIが反復的な評価とドキュメント作成を処理する間、エンジニアが真の脅威に集中できるようにします。GitLab Duo Chatを使用した脆弱性管理は、アドオン付きのUltimateのお客様のみが利用できます。

### 高度なSASTのC/C++サポート {#cc-support-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/sast/advanced_sast_cpp.md)

{{< /details >}}

GitLab高度なSASTにC/C++のベータサポートを追加しました。

この新しいクロスファイル、クロスファンクションスキャンサポートを使用するには、[C/C++サポートを有効に](../../user/application_security/sast/advanced_sast_cpp.md)してください。

この機能に関するフィードバックをお待ちしております。ご質問、ご意見、または当チームとの連携をご希望の場合は、この[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/575671)をご覧ください。

### シークレットの有効性チェックがベータ版になりました {#secret-validity-checks-is-in-beta}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/validity_check.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16927)

{{< /details >}}

パイプラインシークレット検出は、プロジェクト内のパスワードやAPIキーなどの公開された認証情報を警告します。しかし、GitLab 18.5までは、各検出がアクティブなトークンを表しているかどうかを手動で確認する必要がありました。これにより、検出のトリアージを効果的に行うことが困難で時間のかかるものになる可能性がありました。

有効性チェックがベータ版になったため、これを有効にすると、検出されたGitLabシークレットのステータスが表示されます。アクティブなシークレットは、正当な活動を装うために使用される可能性があるため、できるだけ早くローテーションする必要があります。有効性チェックの動作を確認するには、[有効性チェックのプレイリスト](https://www.youtube.com/playlist?list=PL05JrBw4t0Ko8uOgubcYqmTTMGs0zWQRt)をご覧ください。

### シークレットプッシュ保護とパイプラインシークレット検出のルールカバレッジの増加 {#increased-rule-coverage-for-secret-push-protection-and-pipeline-secret-detection}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/secret_detection/detected_secrets.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/573973)

{{< /details >}}

GitLabパイプラインシークレット検出に新しいルールが追加されました。既存のルールの一部も、品質を向上させ、誤検出を減らすために更新されました。これらの変更は、シークレットアナライザーの[バージョン7.15.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.15.0)でリリースされます。

### 高度なSAST向けのカスタマイズ可能な検出ロジック {#customizable-detection-logic-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/sast/customize_rulesets.md)

{{< /details >}}

GitLab高度なSASTを使用して、組織固有のセキュリティ要件とコードパターンに合わせたカスタムセキュリティ検出ルールを作成できるようになりました。この機能により、セキュリティチームは事前定義されたルールセットを超えてカスタムの脆弱性パターンを定義でき、アプリケーション固有のセキュリティイシューを検出できます。

詳細については、[ルールセットのカスタマイズ](../../user/application_security/sast/customize_rulesets.md)を参照してください。

### 高度なSASTにおけるマージリクエストでの差分ベーススキャン {#advanced-sast-diff-based-scanning-in-merge-requests}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/application_security/sast/gitlab_advanced_sast.md#diff-based-scanning)

{{< /details >}}

GitLab高度なSASTを使用すると、マージリクエスト内のコード変更のみを分析する差分ベースのスキャンを実行できるようになり、完全なリポジトリスキャンと比較してスキャン時間を大幅に短縮できます。Gitの差分のみをスキャンし、コードベース全体ではなくすることで、チームは開発ワークフローにセキュリティテストをよりシームレスに統合でき、速度を犠牲にしたり、マージリクエストプロセスに摩擦を追加したりすることはありません。

このパフォーマンス改善をデフォルトで有効にするように取り組んでおり、これは[issue 546359](https://gitlab.com/gitlab-org/gitlab/-/issues/546359)で追跡されています。

### 外部制御ステータスの制御リクエスト {#control-requests-for-external-control-statuses}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_frameworks/_index.md#ping-enabled-setting) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/521757)

{{< /details >}}

外部制御は、GitLabでコンプライアンスフレームワークを作成する際に要件に添付できます。

デフォルトでは、GitLabはコンプライアンススキャン中に外部システムから外部制御のステータスを12時間ごとに自動的にリクエストし、制御ステータスを「保留中」に設定します。外部システムは、外部制御APIを使用してステータスを「成功」または「失敗」に更新することで応答します。

GitLab 18.5では、外部制御を設定する際に**Ping enabled**設定をオフにすることで、この自動12時間pingを無効にできるようになりました。12時間pingが無効になっている場合:

- GitLabは外部システムからのステータス更新を自動的にリクエストしません。
- 外部制御は、コンプライアンスフレームワークUIに**無効**バッジを表示します。
- 外部制御APIを使用して、外部制御のステータスがいつ更新されるかを完全に制御できます。

これにより、システムが外部制御ステータスを「保留中」にリセットするのを防ぎ、ステータス更新のタイミングを完全に制御できます。

### 依存関係スキャンが限定的に利用可能になりました {#dependency-scanning-in-limited-availability}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15961)

{{< /details >}}

GitLab 18.5では、依存関係スキャンアナライザーと連携する新しい依存関係スキャンテンプレートをリリースしました。このアナライザーは、すべてのコンポーネント脆弱性を含む依存関係スキャンレポートを生成するようになりました。スキャン実行ポリシー（SEP）およびパイプライン実行ポリシー（PEP）は、新しいテンプレートをサポートします。

新しいテンプレートを使用するには、`Jobs/Dependency-Scanning.v2.gitlab-ci.yml`をインポートします。

この機能は、GitLab.comおよびSelf-Managedインスタンスで利用できますが、Self-Managedの公式サポートがまだ提供されていないため、限定的な可用性としてマークされています。GitLab.comユーザーはすぐに使用できます。

この機能に関するフィードバックをお待ちしております。ご質問、ご意見、または当チームとの連携をご希望の場合は、この[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523458)をご覧ください。

### 環境における変数の展開`deployment_tier` {#variable-expansion-in-environment-deployment_tier}

<!-- categories: Environment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../ci/yaml/_index.md#environmentdeployment_tier) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/365402)

{{< /details >}}

`environment:deployment_tier`フィールドでCI/CD変数を使用できるようになり、パイプライン条件に基づいてデプロイティアを動的に設定することが容易になりました。

### イシューとタスクのステータスライフサイクルを設定します {#configure-status-lifecycles-for-issues-and-tasks}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/work_items/status.md#lifecycles) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/555528)

{{< /details >}}

以前は、イシューとタスクは同じ設定されたステータスセットを共有する必要がありました。このリリースでは、ステータスライフサイクルを設定するサポートが追加され、プロジェクト内のイシューとタスクに対して明確なワークフローを定義できるようになりました。ワークフローに組み込まれたステータスマッピングにより、作業アイテムタイプを変更する際に一括編集の必要なく、イシューまたはタスクを新しいステータスセットにシームレスに移行できます。

あなたのユースケースと提案を添えて、[フィードバックイシューにコントリビュートする](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/35235)ことで、フィードバックを共有し、機能改善にご協力ください。

### プレーンテキストエディタでMarkdownテーブルをフォーマットする {#format-markdown-tables-in-the-plain-text-editor}

<!-- categories: Markdown -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/markdown.md#tables)

{{< /details >}}

整列されていないMarkdownテーブルは、正しくレンダリングされていても、読み取りや編集が困難です。

プレーンテキストエディタのツールバーにある新しい**テーブルの再フォーマット**機能は、シングルクリックでテーブルの列を再配置し、配置設定とインデントを保持します。使用方法:

- Wikiページ、イシュー、またはマージリクエストで任意のMarkdownテーブルを選択します。
- **さらに多くのオプション**メニューから、**テーブルの再フォーマット**を選択します。

これにより、複雑なテーブルを扱う際のドキュメントメンテナンスが高速になり、コラボレーションが容易になります。

### イシューでの子タスク完了状況の表示 {#view-child-task-completion-in-issues}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/tasks.md#view-tasks) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/520886)

{{< /details >}}

子アイテムウィジェットから直接イシューの進捗を追跡することができるようになり、ステータスの概要を一目で把握できます。この機能強化により、作業が既に進行している場合の潜在的なボトルネックに対するリアルタイムの可視性が提供され、リスクのあるアイテムを迅速に特定し、スプリントの期限が脅かされる前にタイムリーな調整を行うのに役立ちます。

### 脆弱性APIから元の重大度を公開 {#expose-original-severity-from-the-vulnerabilities-api}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../api/graphql/reference/_index.md#pipelinesecurityreportfinding) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/557940)

{{< /details >}}

脆弱性のGraphQL APIが、脆弱性の元の重大度を公開するようになりました。これにより、重大度のオーバーライドが適用される前の脆弱性の重大度が何であったかを判断できます。

### マージリクエスト承認ポリシーのタイムウィンドウ {#time-windows-for-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#security_report_time_window) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/525509)

{{< /details >}}

セキュリティ脆弱性の比較においてさらなる柔軟性を提供するため、マージリクエスト承認ポリシーにタイムウィンドウを導入しました。最新のベースラインのセキュリティレポートがまだ利用できない場合、この新しいポリシー設定により、指定したタイムウィンドウの期間よりも古くない限り、以前に完了したセキュリティレポートを使用できます。

開発チームは、非常に忙しいプロジェクトなどで、ベースラインのセキュリティスキャンが停止したり時間がかかりすぎたりする場合に、不必要な遅延を回避できるようになりました。タイムウィンドウを設定することで、新しい脆弱性を導入しないマージリクエストは、最新のパイプラインの完了を待たずに進行でき、ワークフローの効率性が向上します。

この機能を使用するには、マージリクエスト承認ポリシーを作成または編集し、承認ポリシー設定で`security_report_time_window`パラメータ（分単位）を指定します。

システムは、指定されたタイムウィンドウ内に作成されたセキュリティレポートを使用して、マージリクエストのセキュリティ結果を最新のパイプラインと比較し、新しい脆弱性が導入されない場合に承認を高速化します。

### パイプライン**セキュリティ**タブでのセキュリティ検出ステータスの更新 {#refreshed-security-finding-statuses-in-the-pipeline-security-tab}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/detect/security_scanning_results.md#change-status) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/554078)

{{< /details >}}

以前は、パイプラインの**セキュリティ**タブで脆弱性を無視した場合、その脆弱性はリストからすぐに削除されませんでした。

パイプラインページのセキュリティタブのステータス更新は、変更後に更新されるようになりました。

### マージリクエスト承認ポリシーをバイパスするための例外 {#exceptions-to-bypass-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18114)

{{< /details >}}

組織は、重大な状況が発生した場合にマージリクエスト承認ポリシーをバイパスできる特定のユーザー、グループ、ロール、またはカスタムロールを指定できるようになりました。この機能により、緊急対応に柔軟性を提供しつつ、包括的な監査証跡とガバナンス管理を維持できます。

**Emergency bypass with accountability**: 指定されたユーザーは、重大なインシデント、セキュリティホットフィックス、または緊急の本番環境イシュー中に承認要件をバイパスすることができます。緊急事態が発生した場合、承認された担当者はシステムが詳細な正当化と監査情報をコンプライアンスレビューのために記録する間、すぐに変更をマージまたはプッシュできます。

主な機能は次のとおりです:

- **Documented bypass process**: 承認されたユーザーがポリシーバイパスを実行する場合、直感的なモーダルインターフェースを使用して詳細な理由を提供する必要があり、すべての例外がコンテキストとともに適切に文書化されることを保証します。
- **Comprehensive audit integration**: すべてのバイパスは、ユーザーID、ポリシーコンテキスト、理由、およびタイムスタンプを含む詳細な監査イベントを生成し、例外使用パターンへの完全な可視性を提供します。
- **Flexible configuration**: YAMLまたはUI設定を使用してポリシーの例外権限を定義し、個々のユーザー、GitLabグループ、標準ロール、およびカスタムロールをサポートします。
- **Git-based push exceptions**: 事前承認されたポリシー例外を持つユーザーは、プッシュバイパスオプション`security_policy.bypass_reason`を実行する際に直接プッシュできます。

この機能により、緊急時にセキュリティポリシーを完全に無効にする必要がなくなり、組織のガバナンスと監査要件を維持しながら、緊急の変更に対する制御されたパスを提供します。

### 依存関係リストでアクティブな脆弱性のみを表示 {#show-only-active-vulnerabilities-in-the-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_list/_index.md#vulnerabilities) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/353487)

{{< /details >}}

以前は、依存関係リストには無視された脆弱性が含まれていました。

依存関係リスト内の脆弱性をより有用に表現するために、プロジェクト依存関係リストには、`detected`および`confirmed`状態のアクティブな脆弱性のみが含まれるようになりました。

### 限定的な可用性における静的到達可能性と実験的Javaサポート {#static-reachability-in-limited-availability-and-experimental-java-support}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/static_reachability.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15780)

{{< /details >}}

GitLab 18.5では、静的到達可能性の限定的な可用性サポートをリリースしました。このリリースは、JS/TSカバレッジサポートの改善、バグの修正、およびJava向けの実験的サポートの提供に焦点を当てています。静的到達可能性は、プロジェクトのソースコードをスキャンして使用中のオープンソース依存関係を特定することにより、ソフトウェアコンポジション解析（SCA）の結果を強化します。静的到達可能性によって生成されたデータは、ユーザーのトリアージおよび修正の意思決定の一部として使用できます。静的到達可能性データは、CVSSおよびEPSSスコア、ならびにKEVインジケーターと併用して、特定された脆弱性をより絞り込んだビューで提供することもできます。

この機能に関するフィードバックをお待ちしております。ご質問、ご意見、または当チームとの連携をご希望の場合は、この[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/535498)をご覧ください。

### GitLab Runner 18.5 {#gitlab-runner-185}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/runner) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38976)

{{< /details >}}

本日、GitLab Runner 18.5もリリースします！GitLab Runnerは、CI/CDジョブを実行し、その結果をGitLabインスタンスに送信する、拡張性の高いビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

バグ修正:

- [Runnerオペレーターを1.39から1.41に更新した後、Vanilla KubernetesでRunnerの更新が失敗する](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/259)
- [一部のコンテナラベルに重複したプレフィックスがある](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38674)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-5-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-5-stable/CHANGELOG.md).md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.5)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.5)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.5)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
