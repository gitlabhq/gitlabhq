---
stage: Release Notes
group: Monthly Release
date: 2025-10-16
title: "GitLab 18.5 リリースノート"
description: "GitLab 18.5がリリースされました。GitLab Duo Planner（専門エージェントおよびプロダクトマネージャーチームメンバー、ベータ版）を搭載"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年10月16日、GitLab 18.5が以下の機能とともにリリースされました。

また、今月の注目コントリビューターをはじめ、すべてのコントリビューターの皆様に感謝申し上げます。

## 今月の注目コントリビューター: Jose Gabriel Companioni Benitez

Jose氏はブログ記事[「GitLabがあなたのプロフェッショナルキャリアを後押しする方法」](https://compacompila.com/posts/gitlab-open-source-community/)の中でこう述べています。「私にとって、GitLabが提供する最大のメリットは、プロフェッショナルとしての成長という観点から見ると、オープンソースであるという点です。」さらに、「GitLabにとって、誰でもコントリビュートできることが重要であり、そのためにコントリビューターのオンボーディングプロセスを非常に真剣に取り組んでいます」と付け加えています。

9月に初めてコントリビューターとなり、10月には注目コントリビューターに選ばれたJose氏の歩みは、GitLabのコラボレーティブなコミュニティの力を示しています。コミュニティオフィスアワー、Discordでのディスカッション、ペアリングセッションへの積極的な参加を通じて、Jose氏はサポートが充実した環境を見つけ、[ドキュメント](https://gitlab.com/gitlab-org/cli/-/merge_requests/2392)、[コード](https://gitlab.com/gitlab-org/terraform-provider-gitlab/-/merge_requests/2690)、コミュニティサポートにわたる多様なコントリビュートでレベル3のコントリビューターへと急成長しました。

GitLabコミュニティは、コントリビューターが互いにサポートし合い、共に成長できる温かい場所です。オープンソースの旅を始めたばかりの方も、スキルをさらに深めたい方も、私たちのコミュニティが成功をサポートします。

コントリビュートの詳細については、[GitLab Contributor Platform](https://contributors.gitlab.com/)をご覧ください。

Jose氏、素晴らしいご活躍をありがとうございます！🚀

## 主要機能

### GitLab Duo Planner：専門エージェントおよびプロダクトマネージャーチームメンバー（ベータ版）

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/planner.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/576618)

{{< /details >}}

GitLab Duo Plannerは、GitLab内でプロダクトマネージャーを直接サポートするために構築されたGitLab Duoエージェントです。手動でアップデートを追いかけたり、作業の優先順位を付けたり、計画データをまとめたりする代わりに、GitLab Duo Plannerがバックログの分析、RICEやMoSCoWなどのフレームワークの適用、本当に注意が必要な事項の洗い出しを支援します。まるで、あなたの計画ワークフローを理解し、より良く、より迅速な意思決定のために共に働くプロアクティブなチームメンバーのような存在です。
この機能は現在ベータ版です。[イシュー576622](https://gitlab.com/gitlab-org/gitlab/-/issues/576622)でフィードバックをお寄せください。

### Duo Agent CatalogのGitLab Security Analyst Agent（ベータ版）

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19659)

{{< /details >}}

GitLab Duo Agent Platformのエージェントを使用して、GitLab内でタスクを実行したり、複雑な質問に回答したりできます。ユーザーはマージリクエストの作成やコードレビューなど特定のタスクを実行するカスタムエージェントを作成するか、AI CatalogでGitLabエージェントを探すことができます。

GitLab 18.5では、GitLab Security Analyst AgentをAI Catalogで利用可能なベータ機能としてリリースします。特定のプロジェクトでGitLab Security Analyst Agentを使用するには、GitLab Duo Agentic Chatでエージェントを選択して有効にしてください。このエージェントは以下のタスクを実行できます。

- 指定したプロジェクトのすべての脆弱性を一覧表示する。
- CVEデータやEPSSスコアを含む詳細な脆弱性情報を取得する。
- 脆弱性を確認または無視する。
- 脆弱性の重大度レベルを更新する。
- 脆弱性のステータスを`detected`に戻す。
- 脆弱性のイシューを作成するか、既存のイシューに脆弱性をリンクする。

GitLab Security Analyst Agentを使用することで、ユーザーはAIによる自動化とインテリジェントな分析を通じて煩雑なセキュリティワークフローを実行でき、エンジニアは本物の脅威に集中できる一方、GitLab Security Analyst Agentが繰り返しの評価とドキュメント作成を担います。なお、GitLab Duo ChatによるGitLab Security Analyst AgentはGitLab Duoアドオンを持つUltimateのお客様のみご利用いただけます。

この機能はベータ版です。[イシュー576916](https://gitlab.com/gitlab-org/gitlab/-/issues/576916)でフィードバックをお待ちしています。

### Maven仮想レジストリのベータ版提供開始

<!-- categories: Virtual Registry -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/packages/virtual_registry/maven/_index.md#manage-virtual-registries) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14137)

{{< /details >}}

GitLab 18.5では、Maven仮想レジストリ管理のための包括的なWebベースのインターフェースを導入します。これまで、プラットフォームエンジニアはAPIコールを通じてのみ仮想レジストリを設定・管理できたため、定期的なメンテナンス作業が煩雑で、専門知識が必要でした。

このWebベースのアプローチにより、プラットフォームエンジニアリングチームの運用オーバーヘッドが大幅に削減されます。古いキャッシュエントリのクリア、パフォーマンス最適化のためのアップストリームの並べ替え、接続テストなどの一般的なタスクが、ポイント＆クリック操作で行えるようになりました。開発チームは依存関係の設定をより詳細に把握でき、ビルドパフォーマンスとセキュリティポリシーについてより情報に基づいた議論が可能になります。

Maven仮想レジストリはGitLab PremiumおよびUltimateのお客様向けにベータ版として提供されます。現在のベータ版の制限として、トップレベルグループあたり最大20の仮想レジストリ、仮想レジストリあたり最大20のアップストリームが設定されています。

Maven仮想レジストリのベータプログラムへの参加を企業のお客様にご招待します。[イシュー543045](https://gitlab.com/gitlab-org/gitlab/-/issues/543045)でフィードバックやご提案をお寄せください。

### 新しいパーソナルホームページで作業を再開する

<!-- categories: Navigation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../tutorials/personal_homepage/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16657)

{{< /details >}}

新しいパーソナルホームページにアクセスできるようになりました。このホームページはGitLabの重要なアクティビティをすべて一か所にまとめ、前回の作業を簡単に再開できるようにします。ホームページにはTo-Doアイテム、割り当てられたイシュー、マージリクエスト、レビューリクエスト、最近閲覧したコンテンツが集約されており、GitLabの広大な機能領域をナビゲートし、最も重要なことに集中するのに役立ちます。

### GitLab Duo Agentic ChatのモデルオプションとしてGPT-5が利用可能に

<!-- categories: Model Personalization -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo_chat/agentic_chat.md#select-a-model) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19124)

{{< /details >}}

OpenAI GPT-5が、GitLab Duo Agent Platformのモデル選択時にGitLab AIベンダーモデルとして利用可能になりました。GitLab.comのトップレベルグループのオーナー、およびSelf-ManagedとDedicatedのインスタンス管理者が設定することで、エンドユーザーはGitLab Duo機能でGPT-5を選択して使用できます。トップレベルのオーナーと管理者は、ネームスペースまたはインスタンスの設定を通じて組織全体のモデル設定を引き続き行うか、エンドユーザーが利用可能なすべてのGitLab AIベンダーモデルから選択できるようにすることができます。

GPT-5の使用を開始するには、GitLab Duo Chatのモデルドロップダウンリストから希望のモデルを選択してください。

### インスタンス全体のコンプライアンスおよびセキュリティポリシー管理

<!-- categories: Compliance Management, Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../security/compliance_security_policy_management.md)

{{< /details >}}

エンタープライズユーザーは、複数のトップレベルグループにわたって[コンプライアンスフレームワーク](../../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md)と[セキュリティポリシー](../../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md)を管理したいと考えています。
これは、インスタンス内のすべてのグループが以下の条件を満たす場合によく見られます。

- 同じコンプライアンスフレームワークを共有している。例えば、グループ内のすべてのプロジェクトがISO 27001標準に準拠する必要がある場合。
- 類似したセキュリティポリシーを適用している。例えば、すべてのグループが同じパイプライン実行ポリシーを共有している場合。

GitLab 18.5では、GitLab Self-ManagedおよびDedicatedインスタンスのインスタンス上でセキュリティポリシーとコンプライアンスフレームワークの管理を一元化するためのコンプライアンスおよびセキュリティポリシーグループを導入します。このリリースにより、単一のトップレベルグループからコンプライアンスフレームワークとセキュリティポリシーを作成、設定、割り当て、インスタンス全体の他のすべてのトップレベルグループに適用できるようになります。

コンプライアンスおよびセキュリティポリシーグループを使用することで、コンプライアンスフレームワークとセキュリティポリシーを管理・編集できる信頼できる唯一の情報源を持つことができます。グループ内のセキュリティおよびコンプライアンスユーザーは、インスタンス全体のすべてのプロジェクトにコンプライアンスフレームワークとセキュリティポリシーを適用できます。

コンプライアンスおよびセキュリティポリシーグループにより、インスタンス全体のコンプライアンスとセキュリティのニーズを管理・適用しやすくなります。ただし、グループは引き続き、そのグループで発生する可能性のある特定の状況やワークフローに対応するための独自のコンプライアンスフレームワークとセキュリティポリシーを作成する能力を保持します。

この機能はGitLab Self-ManagedおよびDedicatedのお客様向けです。GitLab.comのお客様は、セキュリティポリシープロジェクトを使用して、単一のトップレベルグループまたはネームスペース内でフレームワークとポリシーを一元管理できます。

[コンプライアンスフレームワーク](../../user/compliance/compliance_frameworks/centralized_compliance_frameworks.md)と[セキュリティポリシー](../../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md)のコンプライアンスおよびセキュリティポリシーグループの詳細をご確認ください。

### DAST認証スクリプト

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dast/browser/configuration/authentication_scripts.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17018)

{{< /details >}}

CI/CD設定にスクリプトを追加して、DAST認証ワークフローを自動化できるようになりました。認証スクリプトにより、時間ベースのワンタイムパスワード（OTP MFA）のサポートを含む複雑な認証フローの自動化が可能になります。

この機能強化により、徹底した自動セキュリティスキャンを実施しながら、重要なセキュリティコントロールを維持できます。実際の認証シナリオをサポートすることで、スクリプトは摩擦を軽減し、本番ソフトウェアの正確なセキュリティ評価を確保します。

## エージェントコア

### CLIエージェントの追加トリガー

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/duo_agent_platform/triggers/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/567787)

{{< /details >}}

追加のイベントを使用してCLIエージェントをトリガーできるようになり、プロジェクト全体でエージェントがアクションを実行する場所とタイミングをより柔軟に制御できます。既存の**メンション**トリガーに加えて、以下を使用できます。

- **割り当て**: マージリクエストまたはイシューが割り当てられたときにエージェントをトリガーする。
- **レビュアーの割り当て**: マージリクエストにレビュアーが追加されたときにエージェントをトリガーする。

### GitLab Duo Self-HostedのGitLab Duo Agent Platformがベータ版に

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/configure_duo_features.md#configure-access-to-the-gitlab-duo-agent-platform) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/558083)

{{< /details >}}

GitLab Duo Agent PlatformがGitLab Duo Self-Hostedのベータ版として利用可能になりました。この機能はすべてのSelf-Managed GitLab Duo Enterpriseのお客様にご利用いただけます。AWS BedrockまたはAzure OpenAIを使用するSelf-Managedインスタンス管理者は、GitLab Duo Agent Platformで使用するAnthropicのClaudeまたはOpenAIのGPTモデルを設定できます。Self-Hosted管理者は、GitLab Duo Agent Platformで使用する

[互換モデル](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models)

を設定することもできます。

### GitLab Duo Chat（クラシック）でCodestralがサポートされるように

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/550266)

{{< /details >}}

クラシックDuo Chatで

GitLab Duo Self-Hosted

のMistral Codestralを使用できるようになりました。このモデルはGitLab Self-ManagedインスタンスのGitLab Duo Self-Hostedのお客様向けにサポートされています。

### GitLab Duo Self-HostedのGitLab Duo Agent PlatformとGPT OSSモデルの互換性

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19348)

{{< /details >}}

GitLab Duo Self-HostedのGitLab Duo Agent PlatformでGPT OSSモデルを使用できるようになりました。

## スケールとデプロイ

### **管理者**エリアのグループリストの強化

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../administration/admin_area.md#administering-groups) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17783)

{{< /details >}}

GitLab管理者にとってより一貫したエクスペリエンスを提供するため、**管理者**エリアのグループリストをアップグレードしました。

- 削除遅延保護: グループの削除がGitLab全体で使用されている安全な削除フローに従うようになり、誤ったデータ損失を防ぎます。
- より速いインタラクション: ページをリロードせずにグループのフィルタリング、ソート、ページネーションが可能になり、よりレスポンシブなエクスペリエンスを提供します。
- 一貫したインターフェース: グループリストがGitLab全体の他のグループリストの外観と動作に合わせて統一されました。

このアップデートにより、管理者エクスペリエンスがGitLabのデザイン標準に沿ったものになり、データを保護するための重要な安全機能が追加されました。グループ管理の将来の機能強化は、プラットフォーム全体のすべてのグループリストに自動的に反映されます。

### グループのナビゲーションエクスペリエンスの更新

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/group/_index.md#view-a-group) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13790)

{{< /details >}}

GitLab全体でより一貫性があり効率的なエクスペリエンスを提供するため、グループ概要リストに変更を加えました。
これらの改善により、グループとプロジェクトのナビゲーションが容易になり、一目でより価値ある情報を確認できるようになります。

- より豊富なプロジェクト情報: プロジェクトにスター、フォーク、イシュー、マージリクエスト、関連日付が表示されるようになり、一目でアクティビティの全体像を把握できます。
- 合理化されたアクション: アクションメニューを使用して、概要から直接グループとプロジェクトを編集または削除できます。アーカイブ済みおよび削除保留中のアイテムは**非アクティブ**タブに表示されます。
- 一貫したエクスペリエンス: グループ概要がGitLab全体の他のグループおよびプロジェクトリストの外観と動作に合わせて統一され、より直感的なエクスペリエンスを提供します。

これらの機能強化により、より多くの情報とアクションをすぐに利用できるようになり、時間を節約できます。このアップデートは、一括編集や高度なフィルタリングオプションなどの将来の機能の基盤にもなります。

### グループとプロジェクトの非アクティブアイテム管理の改善

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/working_with_projects.md#view-inactive-projects) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/526211)

{{< /details >}}

**非アクティブ**タブにGitLab全体のすべての非アクティブアイテムが一か所に統一して表示されるようになりました。これにはアーカイブ済みプロジェクト、削除保留中のプロジェクト、削除保留中のグループが含まれます。
このタブはグループ概要ページ、および**自分の作業**、**探索**、**管理者**エリア全体のグループおよびプロジェクトリストで利用できます。
適切な権限を持つすべてのユーザーが非アクティブアイテムを表示でき、グループオーナーとプロジェクトオーナーおよびメンテナーのみがそれらに対してさらなるアクションを実行できます。
このアップデートの一環として、ProjectsおよびGroupsのREST APIとGraphQL APIの両方で新しい`active`パラメーターが利用可能になりました。

非アクティブなコンテンツの管理は、GitLabインスタンスを維持するための重要な部分です。
このアップデートにより、アーカイブされたコンテンツや削除保留中のコンテンツを見つけて回復しやすくなり、GitLabリソースをより適切に管理しながら、貴重な作業を誤って失うリスクを軽減できます。
アクティブなコンテンツと非アクティブなコンテンツを明確に分離することで、GitLabのすべてのエリアでグループとプロジェクトをナビゲートする際に、より集中した検索エクスペリエンスも提供されます。

## 統合されたDevOpsとセキュリティ

### GitLab Duo Agentic Chatの新しい脆弱性管理機能

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo_chat/agentic_chat.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19639)

{{< /details >}}

GitLab Duo Agentic ChatはGitLab Duo Chatの強化版です。GitLabプロジェクト全体の複数のソースから情報を検索、取得、統合して、より徹底的で関連性の高い回答を提供します。主なユースケースとして、プロジェクトの検索、ファイルの読み取りと一覧表示、GitLab Duo Chatに提供されたプロンプトに基づいてファイルを自律的に作成・変更する機能などがあります。

GitLab 18.5では、Agentic Chatのユースケースが拡張され、セキュリティスキャナーからの脆弱性管理が含まれるようになりました。Agentic Chatに脆弱性管理ツールを追加することで、AIによる自動化とインテリジェントな分析を通じて煩雑なセキュリティワークフローを変革し、セキュリティ専門家が自然言語コマンドを通じて脆弱性を効率的にトリアージ、管理、修正できるようになります。これにより、脆弱性ダッシュボードを手動でクリックする何時間もの作業が不要になり、以前はカスタムスクリプトや煩雑な手作業が必要だった複雑な一括操作が合理化されます。

GitLab Duo ChatにGitLab Duo Chatに追加された新しい脆弱性管理ツールにより、GitLab Duoを持つUltimateユーザーは以下を実行できます。

- 指定したプロジェクトのすべての脆弱性を一覧表示する。
- CVEデータやEPSSスコアを含む詳細な脆弱性情報を取得する。
- 脆弱性を確認または無視する。
- 脆弱性の重大度レベルを更新する。
- 脆弱性のステータスを`detected`に戻す。
- 脆弱性のイシューを作成するか、既存のイシューに脆弱性をリンクする。

これらのツールにより、セキュリティワークフローが受動的な手動トリアージからインテリジェントな修正へと変革され、エンジニアは本物の脅威に集中できる一方、AIが繰り返しの評価とドキュメント作成を担います。GitLab Duo Chatを使用した脆弱性管理は、GitLab Duoアドオンを持つUltimateのお客様のみご利用いただけます。

### 高度なSASTのC/C++サポート

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/sast/advanced_sast_cpp.md)

{{< /details >}}

GitLab Advanced SASTにC/C++のベータサポートを追加しました。

この新しいクロスファイル、クロスファンクションのスキャンサポートを使用するには、[C/C++サポートを有効にしてください](../../user/application_security/sast/advanced_sast_cpp.md)。

この機能に関するフィードバックをお待ちしています。ご質問、ご意見、またはチームとの連携をご希望の場合は、この[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/575671)をご覧ください。

### シークレット有効性チェックがベータ版に

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/validity_check.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16927)

{{< /details >}}

パイプラインのシークレット検出は、プロジェクト内のパスワードやAPIキーなどの露出した認証情報についてアラートを発します。しかし、GitLab 18.5まで、各検出がアクティブなトークンを表しているかどうかを手動で確認する必要がありました。これにより、検出を効果的にトリアージすることが困難で時間がかかる場合がありました。

有効性チェックがベータ版になったことで、これを有効にすると検出されたGitLabシークレットのステータスが表示されます。アクティブなシークレットは正当なアクティビティを偽装するために使用される可能性があるため、できるだけ早くローテーションする必要があります。有効性チェックの動作を確認するには、[有効性チェックのプレイリスト](https://www.youtube.com/playlist?list=PL05JrBw4t0Ko8uOgubcYqmTTMGs0zWQRt)をご覧ください。

### シークレットプッシュ保護とパイプラインシークレット検出のルールカバレッジの拡大

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/secret_detection/detected_secrets.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/573973)

{{< /details >}}

GitLabパイプラインのシークレット検出に新しいルールが追加されました。また、品質を向上させ誤検出を減らすために、既存のルールの一部も更新されました。これらの変更はシークレットアナライザーの[バージョン7.15.0](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.15.0)でリリースされています。

### 高度なSASTのカスタマイズ可能な検出ロジック

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/sast/customize_rulesets.md)

{{< /details >}}

GitLab Advanced SASTを使用して、組織の特定のセキュリティ要件とコードパターンに合わせたカスタムセキュリティ検出ルールを作成できるようになりました。この機能により、セキュリティチームは事前定義されたルールセットを超えてカスタムの脆弱性パターンを定義し、アプリケーション固有のセキュリティ問題を検出できます。

詳細については、[ルールセットのカスタマイズ](../../user/application_security/sast/customize_rulesets.md)をご覧ください。

### マージリクエストにおける高度なSASTの差分ベーススキャン

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/application_security/sast/gitlab_advanced_sast.md#diff-based-scanning)

{{< /details >}}

GitLab Advanced SASTを使用して、マージリクエストのコード変更のみを分析する差分ベーススキャンを実行できるようになりました。これにより、リポジトリ全体のスキャンと比較してスキャン時間が大幅に短縮されます。コードベース全体ではなくGitの差分のみをスキャンすることで、チームはスピードを犠牲にしたりマージリクエストプロセスに摩擦を加えたりすることなく、開発ワークフローにセキュリティテストをよりシームレスに統合できます。

このパフォーマンス改善をデフォルトで有効にするための作業を進めています。進捗は[イシュー546359](https://gitlab.com/gitlab-org/gitlab/-/issues/546359)で追跡されています。

### 外部コントロールステータスのリクエストを制御する

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_frameworks/_index.md#ping-enabled-setting) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/521757)

{{< /details >}}

GitLabでコンプライアンスフレームワークを作成する際に、要件に外部コントロールを添付できます。

デフォルトでは、GitLabはコンプライアンススキャン中に12時間ごとに外部システムから外部コントロールのステータスを自動的にリクエストし、コントロールステータスを「保留中」に設定します。外部システムはその後、外部コントロールAPIを使用してステータスを「合格」または「不合格」に更新することで応答します。

GitLab 18.5では、外部コントロールを設定する際に**Ping有効**設定をオフにすることで、この自動12時間pingを無効にできるようになりました。12時間pingが無効になると：

- GitLabは外部システムからのステータス更新を自動的にリクエストしなくなります。
- 外部コントロールはコンプライアンスフレームワークUIに**無効**バッジを表示します。
- 外部コントロールAPIを使用して外部コントロールステータスが更新されるタイミングを完全に制御できます。

これにより、システムが外部コントロールステータスを「保留中」にリセットするのを防ぎ、ステータス更新のタイミングを完全に制御できます。

### 限定提供の依存関係スキャン

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15961)

{{< /details >}}

GitLab 18.5では、依存関係スキャンアナライザーと連携する新しい依存関係スキャンテンプレートをリリースしました。
アナライザーはすべてのコンポーネントの脆弱性を含む依存関係スキャンレポートを生成するようになりました。
スキャン実行ポリシー（SEP）とパイプライン実行ポリシー（PEP）が新しいテンプレートをサポートします。

新しいテンプレートを使用するには、`Jobs/Dependency-Scanning.v2.gitlab-ci.yml`をインポートしてください。

この機能はGitLab.comとSelf-Managedインスタンスで利用可能ですが、Self-Managedの公式サポートがまだ利用できないため、限定提供としてマークされています。
GitLab.comのユーザーはすぐに使用できます。

この機能に関するフィードバックをお待ちしています。ご質問、ご意見、またはチームとの連携をご希望の場合は、この[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523458)をご覧ください。

### 環境の`deployment_tier`での変数展開

<!-- categories: Environment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../ci/yaml/_index.md#environmentdeployment_tier) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/365402)

{{< /details >}}

`environment:deployment_tier`フィールドでCI/CD変数を使用できるようになり、パイプラインの条件に基づいてデプロイ層を動的に設定しやすくなりました。

### イシューとタスクのステータスライフサイクルを設定する

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/work_items/status.md#lifecycles) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/555528)

{{< /details >}}

以前は、イシューとタスクは同じ設定済みステータスのセットを共有する必要がありました。このリリースでは、ステータスライフサイクルの設定サポートを追加し、プロジェクト内のイシューとタスクに対して異なるワークフローを定義できるようになりました。ワークフローに組み込まれたステータスマッピングにより、作業アイテムタイプを変更する際に一括編集なしでイシューまたはタスクを新しいステータスセットにシームレスに移行できます。

[フィードバックイシューにコントリビュート](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/35235)して、ユースケースや提案を共有し、機能の改善にご協力ください。

### プレーンテキストエディタでMarkdownテーブルをフォーマットする

<!-- categories: Markdown -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/markdown.md#tables)

{{< /details >}}

整列されていないMarkdownテーブルは、正しくレンダリングされても読みにくく編集しにくいものです。

プレーンテキストエディタのツールバーにある新しい**テーブルの再フォーマット**機能は、ワンクリックでテーブルの列を再整列し、配置設定とインデントを保持します。使用方法：

- WikiページやイシューまたはマージリクエストでMarkdownテーブルを選択します。
- **その他のオプション**メニューから**テーブルの再フォーマット**を選択します。

これにより、複雑なテーブルを扱う際のドキュメントメンテナンスが速くなり、コラボレーションが容易になります。

### イシューで子タスクの完了状況を確認する

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/tasks.md#view-tasks) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/520886)

{{< /details >}}

子アイテムウィジェットからイシューの進捗を直接追跡できるようになり、一目でステータスの概要を確認できます。この機能強化により、作業がすでに進行中の場合に潜在的なボトルネックをリアルタイムで把握でき、スプリントの締め切りが脅かされる前にリスクのあるアイテムを素早く特定してタイムリーな調整を行うのに役立ちます。

### 脆弱性APIから元の重大度を公開する

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../api/graphql/reference/_index.md#pipelinesecurityreportfinding) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/557940)

{{< /details >}}

脆弱性GraphQL APIが脆弱性の元の重大度を公開するようになりました。
これにより、重大度のオーバーライドが適用される前の脆弱性の重大度を確認できます。

### マージリクエスト承認ポリシーの時間ウィンドウ

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#security_report_time_window) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/525509)

{{< /details >}}

セキュリティ脆弱性の比較においてさらなる柔軟性を提供するため、マージリクエスト承認ポリシーに時間ウィンドウを導入しました。最新のベースラインのセキュリティレポートがまだ利用できない場合、この新しいポリシー設定により、指定した時間ウィンドウより古くない限り、以前に完了したセキュリティレポートを使用できます。

開発チームは、非常に忙しいプロジェクトなどでベースラインのセキュリティスキャンが停止したり時間がかかりすぎたりする場合に、不必要な遅延を避けられるようになりました。時間ウィンドウを設定することで、新しい脆弱性を導入しないマージリクエストは最新のパイプラインの完了を待たずに進めることができ、ワークフローの効率が向上します。

この機能を使用するには、マージリクエスト承認ポリシーを作成または編集し、承認ポリシー設定で`security_report_time_window`パラメーター（分単位）を指定してください。

システムはマージリクエストのセキュリティ結果を、指定した時間ウィンドウ内に作成されたセキュリティレポートを使用して最新のパイプラインと比較し、新しい脆弱性が導入されない場合に迅速な承認を可能にします。

### パイプラインの**セキュリティ**タブのセキュリティ検出ステータスの更新

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/detect/security_scanning_results.md#change-status) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/554078)

{{< /details >}}

以前は、パイプラインの**セキュリティ**タブで脆弱性を無視しても、その脆弱性はリストからすぐに削除されませんでした。

パイプラインページのセキュリティタブのステータス更新が、変更後すぐに反映されるようになりました。

### マージリクエスト承認ポリシーをバイパスするための例外

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18114)

{{< /details >}}

組織は、重大な状況が発生した場合にマージリクエスト承認ポリシーをバイパスできる特定のユーザー、グループ、ロール、またはカスタムロールを指定できるようになりました。この機能により、包括的な監査証跡とガバナンスコントロールを維持しながら、緊急対応の柔軟性が提供されます。

**責任を伴う緊急バイパス**: 指定されたユーザーは、重大なインシデント、セキュリティホットフィックス、または緊急の本番環境の問題が発生した際に承認要件をバイパスできます。緊急事態が発生した場合、承認された担当者はすぐに変更をマージまたはプッシュでき、システムはコンプライアンスレビューのための詳細な理由と監査情報を記録します。

主な機能：

- **文書化されたバイパスプロセス**: 承認されたユーザーがポリシーバイパスを実行する際、直感的なモーダルインターフェースを使用して詳細な理由を提供する必要があり、すべての例外がコンテキストとともに適切に文書化されます。
- **包括的な監査インテグレーション**: すべてのバイパスは、ユーザーID、ポリシーコンテキスト、理由、タイムスタンプを含む詳細な監査イベントを生成し、例外使用パターンを完全に可視化します。
- **柔軟な設定**: YAMLまたはUI設定を使用してポリシーの例外権限を定義し、個々のユーザー、GitLabグループ、標準ロール、カスタムロールをサポートします。
- **Gitベースのプッシュ例外**: 事前承認されたポリシー例外を持つユーザーは、プッシュバイパスオプション`security_policy.bypass_reason`を実行する際に直接プッシュできます。

この機能により、緊急時にセキュリティポリシーを完全に無効にする必要がなくなり、組織のガバナンスと監査要件を維持しながら緊急の変更のための制御されたパスが提供されます。

### 依存関係リストにアクティブな脆弱性のみを表示する

<!-- categories: Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_list/_index.md#vulnerabilities) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/353487)

{{< /details >}}

以前は、依存関係リストに無視された脆弱性が含まれていました。

依存関係リストの脆弱性をより有用に表示するため、プロジェクトの依存関係リストには`detected`および`confirmed`状態のアクティブな脆弱性のみが含まれるようになりました。

### 限定提供の静的到達可能性と実験的なJavaサポート

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/static_reachability.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15780)

{{< /details >}}

GitLab 18.5では、静的到達可能性の限定提供サポートをリリースしました。
このリリースはJS/TSカバレッジサポートの改善、バグ修正、Javaの実験的サポートの提供に焦点を当てています。
静的到達可能性は、プロジェクトのソースコードをスキャンして使用中のオープンソース依存関係を特定することで、ソフトウェアコンポジション解析（SCA）の結果を充実させます。
静的到達可能性によって生成されたデータは、ユーザーのトリアージと修正の意思決定の一部として使用できます。また、静的到達可能性データはCVSSおよびEPSSスコア、KEVインジケーターと組み合わせて使用することで、特定された脆弱性のより焦点を絞ったビューを提供できます。

この機能に関するフィードバックをお待ちしています。ご質問、ご意見、またはチームとの連携をご希望の場合は、この[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/535498)をご覧ください。

### GitLab Runner 18.5

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/runner) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38976)

{{< /details >}}

本日、GitLab Runner 18.5もリリースします！GitLab RunnerはCI/CDジョブを実行し、結果をGitLabインスタンスに送信する高スケーラブルなビルドエージェントです。GitLab RunnerはGitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

バグ修正：

- [RunnerオペレーターをバージョンVanilla Kubernetes1.39から1.41に更新した後、Runnerの更新が失敗する](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/259)
- [一部のコンテナラベルに重複したプレフィックスがある](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38674)

すべての変更のリストはGitLab Runnerの[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-5-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-5-stable/CHANGELOG.md).md)にあります。

## 関連トピック

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.5)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.5)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.5)
- [非推奨と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
