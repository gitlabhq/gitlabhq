---
stage: Release Notes
group: Monthly Release
date: 2025-07-17
title: "GitLab 18.2リリースノート"
description: "GitLab 18.2は、Duo Agent PlatformをIDEに搭載してリリースされました（ベータ）"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年7月17日、GitLab 18.2は以下の機能を搭載してリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Markus Siebert {#this-months-notable-contributor-markus-siebert}

[Markus Siebert](https://gitlab.com/m-s-db)氏（DB Systel GmbHのプラットフォームエンジニア）は、ネイティブなAWS Secrets ManagerサポートをGitLab CI/CDにもたらすコミュニティの取り組みを主導しており、パイプラインにおける安全なシークレット管理という企業の重要なニーズに対応しています。わずか6週間で172件もの活動を記録したMarkus氏は、[AWS Secrets Managerからシークレットを取得する機能の追加](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5587) 、[GitLab CI設定エントリのAWS SSM ParameterStoreへの追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191803) 、[AWS Secrets Managerのドキュメント](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192378)を含む複数のマージリクエストを通じて、AWS Secrets ManagerとAWS Systems Manager Parameter Storeの両方のサポートを精力的に実装してきました。

「Markus氏の作業により、AWS環境のGitLabユーザーは、サードパーティのツールやカスタムスクリプトに頼ることなく、CI/CDのシークレットを安全に管理できます。これは、AWSサービスを標準化する企業ユーザーにとって特に価値があります」と、Markus氏を推薦したGitLabのシニアバックエンドエンジニア、[Aditya Tiwari](https://gitlab.com/atiwari71)氏は述べています。

Markus氏が、最初の実装からドキュメント作成に至るまでこの機能を実現するために捧げた努力は、フィードバックに基づいてマージリクエストを積極的に維持改善しながら、コミュニティコントリビュートの最良の例を示し、コミュニティ主導の開発がAWSユーザーにとってGitLabをより良くする力を実証しています。

このコントリビュートは、[GitLab Co-Create Program](https://about.gitlab.com/community/co-create/)を通じて提供されました。

Markus氏のGitLabへの貴重なコントリビュートに感謝します！

## 主要な機能 {#primary-features}

### IDE内のDuo Agent Platform（ベータ） {#duo-agent-platform-in-the-ide-beta}

<!-- categories: Editor Extensions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/duo_agent_platform/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/556038)

{{< /details >}}

Duo Agent Platformは、VS CodeとJetBrains IDEにエージェント型チャットとエージェントフローを直接統合し、コードベースとGitLabプロジェクトとの自然な会話ベースの相互作用を可能にします。

エージェント型チャットは、ファイルの作成や編集、パターン一致ングやgrepによるコードベース全体の検索、コードに関する即座の回答取得するなど、迅速な会話型タスク向けに設計されています。エージェントフローは、より大規模な実装と包括的な計画を処理し、イシュー、マージリクエスト、コミット、CI/CDパイプライン、セキュリティ脆弱性などのGitLabリソースにアクセスしながら、高レベルのアイデアを概念からアーキテクチャへと導きます。どちらも、ドキュメント、コードパターン、プロジェクト発見のためのインテリジェントな検索機能を提供し、簡単な編集から複雑なプロジェクト分析まであらゆるタスクを達成するのに役立ちます。

このプラットフォームは、外部データソースやツールに接続するためのModel Context Protocol（MCP）もサポートしており、AI機能がGitLabを超えたコンテキストを活用できるようにします。

詳細については、弊社のブログ[GitLab Duo Agent Platform Public Beta: Next-gen AI orchestration and more](https://about.gitlab.com/blog/gitlab-duo-agent-platform-public-beta/)をご覧ください。

開始するには、[Duo Agent Platformのドキュメント](../../user/duo_agent_platform/_index.md) 、[VS Codeセットアップガイド](../../user/gitlab_duo_chat/agentic_chat.md#use-gitlab-duo-chat-in-vs-code) 、[JetBrainsセットアップガイド](../../user/gitlab_duo_chat/agentic_chat.md#use-gitlab-duo-chat-in-jetbrains-ides)を参照してください。

### イシューとタスクのカスタムワークフローステータス {#custom-workflow-statuses-for-issues-and-tasks}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/work_items/status.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14794)

{{< /details >}}

基本的なオープン/クローズシステムを超えて、設定可能なステータスでチームの実際のワークフローステージを通じて作業アイテムを追跡するできるようになりました。

ラベルに依存する代わりに、プロセスを正確に反映するカスタムステータスを定義できるようになりました。設定可能なステータスで、以下のことが可能です:

- **Define custom workflows**。
- **Replace workflow labels**。
- **Clarify completion outcomes**。
- **Filter and report accurately**。
- **Use status in issue boards**。
- **Bulk update status**。
- **Track dependencies**。

カスタムワークフローステータスは、**quick actions in comments**もサポートしており、GitLabのオープン/クローズシステムと自動的に同期します。

この機能を改善するために、[フィードバックイシュー](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/35235)でご意見やご提案をお寄せください。

### 新しいマージリクエストホームページ {#new-merge-request-homepage}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/merge_requests/homepage.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13448)

{{< /details >}}

作成者とレビュアーの両方として何十ものマージリクエストを処理する場合、複数のGitLabプロジェクトにわたるコードレビューは非常に大変な場合があります。

新しいマージリクエストホームページは、今すぐ注目すべきタスクをインテリジェントに優先順位付けすることで、レビューワークロードのナビゲート方法を変革する2つの強力なビューモードを提供します:

- **Workflow view**は、マージリクエストをレビューステージごとに整理し、コードレビューワークフローのステージごとに作業をグループ化します。
- **Role view**は、マージリクエストを作成者かレビュアーかによってグループ化し、責任を明確に分離します。

**アクティブ**タブは注意が必要なマージリクエストを表示し、**マージ済み**は最近完了した作業を表示し、**検索**は包括的なフィルタリング機能を提供します。

新しいホームページは、割り当てられたマージリクエストと作成者が作業したマージリクエストの両方を組み合わせることで、表示レベルを展開し、割り当てられた作業を見逃すことがないようにします。

### イミュータブルなコンテナタグでセキュリティを改善（ベータ） {#improve-security-with-immutable-container-tags-beta}

<!-- categories: Container Registry -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../user/packages/container_registry/immutable_container_tags.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15139)

{{< /details >}}

コンテナレジストリは、最新のDevSecOpsチームにとって重要なインフラです。しかし、保護されたコンテナタグを使用しても、組織は依然として課題に直面しています: タグが作成された後、十分な権限を持つユーザーはそれを変更できます。これは、本番環境の安定性のために特定のタグ付きコンテナイメージのバージョンに依存しているチームにリスクをもたらします。権限のあるユーザーによる変更であっても、意図しない変更を導入したり、デプロイの整合性を損なったりする可能性があります。

イミュータブルなコンテナタグを使用すると、意図しない変更からコンテナイメージを保護できます。イミュータブルなルールに一致するタグが作成された後、誰もコンテナイメージを変更することはできません。できるようになりました:

- RE2正規表現パターンを使用して、GitLabプロジェクトごとに最大5つの保護ルール（保護ルールとイミュータブルルールを組み合わせたもの）を作成できます。
- 最新バージョン、セマンティックバージョン（例: v1.0.0）、またはリリース候補などの重要なタグを、いかなる変更からも保護します。
- イミュータブルなタグがクリーンアップポリシーから自動的に除外されるようにします。

イミュータブルなコンテナタグには次世代コンテナレジストリが必要であり、これはGitLab.comでデフォルトで有効になっています。GitLab Self-Managedインスタンスの場合、イミュータブルなコンテナタグを使用するには[メタデータデータベース](../../administration/packages/container_registry_metadata_database.md)を有効にする必要があります。

### GitLab Duoを使用するPremiumおよびUltimateのグループとプロジェクトのコントロール {#group-and-project-controls-for-premium-and-ultimate-with-gitlab-duo}

<!-- categories: Code Suggestions, Duo Chat -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/gitlab_duo/turn_on_off.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/551895)

{{< /details >}}

GitLab PremiumおよびUltimateのユーザーは、グループとGitLabプロジェクト向けに、IDEにおけるコード提案とGitLab Duo Chatの利用可能性を変更できるようになりました。以前は、インスタンスまたはトップレベルグループに対してのみ利用可能性を変更できました。

### 新しいグループ概要コンプライアンスダッシュボード {#new-group-overview-compliance-dashboard}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_overview_dashboard.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13909)

{{< /details >}}

コンプライアンスセンターは、コンプライアンスチームがグループのコンプライアンスステータスレポート、違反レポート、およびコンプライアンスフレームワークを管理するための中央の場所です。

新しいグループ概要コンプライアンスダッシュボードは、コンプライアンスマネージャーに、グループ内のすべてのGitLabプロジェクトにわたるコンプライアンス情報の集計ビューを提供します。この最初のイテレーションでは、以下の情報が表示されます:

- 特定のコンプライアンスフレームワークでカバーされているGitLabプロジェクトの割合（％）。
- グループ内のすべてのGitLabプロジェクトにおける失敗した要件の割合（％）。
- グループ内のすべてのGitLabプロジェクトにおける失敗したコントロールの割合（％）。
- 「注意」を要する特定のコンプライアンスフレームワーク。

この新しいグループ概要により、コンプライアンスマネージャーは、自身のコンプライアンスセキュリティ対策状況の明確なハイレベルな全体像を提供するする単一の統合ビューを取得するできるようになりました。

### インスタンスのワークスペースKubernetesエージェントをマップ {#map-workspace-kubernetes-agents-for-the-instance}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../user/workspace/gitlab_agent_configuration.md#allow-a-cluster-agent-for-workspaces-on-the-instance) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16485)

{{< /details >}}

GitLab管理者は、有効なワークスペースKubernetesエージェントをインスタンスにマップできるようになりました。ユーザーは、そのインスタンス内の任意のグループまたはGitLabプロジェクトからワークスペースを作成できます。

これにより、組織はワークスペースKubernetesエージェントを一度プロビジョニングし、それらのエージェントをインスタンス全体の現在および将来のすべてのGitLabプロジェクトにアクセス可能にすることで、ワークスペースのスケーラビリティが大幅に向上します。

### セキュリティレポートのPDFエクスポートをダウンロード {#download-a-pdf-export-of-security-reports}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/security_dashboard/_index.md#export-as-pdf) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16989)

{{< /details >}}

脆弱性管理の取り組みの状態と進捗を他の関係者に伝えるため、各GitLabプロジェクトまたはグループのセキュリティダッシュボードをPDFドキュメントとしてエクスポートするできるようになりました。

### 一元化されたセキュリティポリシー管理（ベータ） {#centralized-security-policy-management-beta}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/application_security/policies/enforcement/compliance_and_security_policy_groups.md#set-up-centralized-security-policy-management) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17392)

{{< /details >}}

コンプライアンスが重要な大規模組織では、チームは複数のGitLabプロジェクトとグループに分散した断片的なポリシーに苦慮することがよくあります。一元化された表示レベルがなければ、一貫した強制を確保することは時間がかかる課題となり、同時にコンプライアンスリスクを増加させます。

一元化されたセキュリティポリシー管理は、単一の指定されたコンプライアンスとセキュリティポリシー（CSP）グループを通じて、GitLab組織全体でセキュリティポリシーを作成、管理、および強制するするための統一されたアプローチを導入します。これにより、セキュリティチームは次のことが可能になります:

- **Define policies once and apply everywhere**: CSPを通じてインスタンス全体のセキュリティポリシーを一度作成し、すべてのグループおよびGitLabプロジェクトにポリシーを自動的に強制します。
- **Configure business unit policies**: トップレベルグループは、CSPグループから組織のポリシーを継承しながら、独自の明確なポリシーを設定することができます。
- **Ensure adherence to principle of least privilege**: インスタンスに強制される中央のポリシー管理レイヤーを確立します。

このベータリリースは、一元化されたポリシー管理の基盤となるフレームワークを確立し、既存のすべてのセキュリティポリシー型をサポートし、グループ、GitLabプロジェクト、またはインスタンス向けに設定可能です。

## エージェント型コア {#agentic-core}

### GitLab Duo Self-HostedでMistral Smallが利用可能に {#mistral-small-now-available-for-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18202)

{{< /details >}}

GitLab Duo Self-HostedでMistral Smallを使用できるようになりました。このモデルはGitLab Self-Managedインスタンスで利用可能であり、GitLab Duo Self-Hosted上のGitLab Duo Chatおよびコード提案向けの最初の完全に互換性のあるオープンソースモデルです。

## 規模とデプロイ {#scale-and-deployments}

### 管理者はユーザー確認なしでコントリビュートを再割り当てできます {#administrators-can-reassign-contributions-without-user-confirmation}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523259)

{{< /details >}}

管理者は、ユーザーの確認なしで、プレースホルダーユーザーからアクティブユーザーへのコントリビュートの再割り当てが可能になりました。この機能は、ユーザーが再割り当てを承認するためのメールを確認しなかったためにプロセスが停止した大規模組織にとって、重要な課題に対処します。

ユーザー代理が有効なGitLabインスタンスでは、管理者はデータ整合性を維持しながらユーザー管理ワークフローを効率化できます。再割り当て完了後もユーザーは通知メールを受信し、プロセス全体で透明性を確保します。

### プレースホルダーユーザーから非アクティブユーザーへの再割り当て {#reassign-from-placeholder-users-to-inactive-users}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523260)

{{< /details >}}

以前は、管理者はプレースホルダーユーザーからアクティブユーザーにのみコントリビュートとメンバーシップを再割り当てできました。

GitLab Self-Managedでは、管理者はプレースホルダーユーザーから非アクティブユーザーへのコントリビュートとメンバーシップの再割り当ても可能になりました。この機能により、GitLabインスタンス上のブロックする、BAN、または無効化されたユーザーのコントリビュート履歴とメンバーシップ情報を許可できます。

管理者はこの設定を最初に有効にする必要があります。有効にすると、この設定は再割り当て中のユーザー確認をスキップしながら、安全なアクセス制御を維持することでユーザー管理を効率化します。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### マルチアーキテクチャコンテナイメージのコンテナスキャンサポート {#container-scanning-support-for-multi-architecture-container-images}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/container_scanning/_index.md#available-cicd-variables) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/543144)

{{< /details >}}

コンテナスキャンは、Linux Arm64コンテナイメージバリアントを搭載して提供されるようになりました。Linux Arm64 Runner上で実行するすると、アナライザーはエミュレーションを必要とせず、より高速な分析が可能になります。さらに、`TRIVY_PLATFORM`環境変数をスキャンしたいプラットフォームに設定することで、マルチアーキテクチャ画像をスキャンするできるようになりました。

### コンテナスキャンのアーカイブファイルサポートの改善 {#improved-archive-file-support-for-container-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/container_scanning/_index.md#scanning-archive-formats) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/501077)

{{< /details >}}

GitLab 18.2は、コンテナスキャンへのアーカイブファイルスキャンニングサポートを改善しました。特定のパッケージの脆弱性が複数のイメージで発見された場合、スキャンされた各イメージに属性付けられた脆弱性が表示されるようになりました。

### JavaScriptの静的到達可能性サポート {#static-reachability-support-for-javascript}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/static_reachability.md#supported-languages-and-package-managers) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/502334)

{{< /details >}}

コンポジション解析は、JavaScriptライブラリの静的到達可能性をサポートするようになりました。静的到達可能性によって生成されたデータを、トリアージと修正の意思決定の一部として使用できます。静的到達可能性データは、EPSS、KEV、およびCVSSスコアと組み合わせて使用​​することもでき、脆弱性のより焦点を合わせるたビューを提供します。

### DASTログイン成功の検証サポートを改善 {#improved-support-for-verifying-successful-dast-login}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dast/browser/configuration/variables.md#authentication) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/435942)

{{< /details >}}

以前は、`DAST_AUTH_SUCCESS_IF_AT_URL`変数は、認証の成功を検証するために正確なURL一致を必要としていました。これは静的ランディングページを持つアプリケーションではうまく機能しましたが、ログイン後のURLに各ログイン用の動的要素が含まれるアプリケーションでは困難が生じました。

現在、`DAST_AUTH_SUCCESS_IF_AT_URL`変数でワイルドカードパターンを使用して、動的なURLパターンに一致させることができます。この機能強化により、正確なURLがセッション間で変化する場合でも、認証の成功を検証するために必要な柔軟性を提供します。

### 時間ベースワンタイムパスワードMFAのDASTサポート {#dast-support-for-time-based-one-time-password-mfa}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dast/browser/configuration/authentication.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13633)

{{< /details >}}

動的な解析は、時間ベースワンタイムパスワード（TOTP）多要素認証をサポートするようになりました。

TOTP MFAが有効なGitLabプロジェクトでDASTスキャンするを実行し、包括的なセキュリティテストを確保するできます。この機能強化により、MFAがデプロイされている本番環境環境をミラーする設定でアプリケーションをテストすることで、より正確なスキャンする結果が提供されます。

### 監査イベントストリーミング先へのストリーミングを無効にする {#deactivate-streaming-to-an-audit-streaming-destination}

<!-- categories: Audit Events -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../administration/compliance/audit_event_streaming.md#activate-or-deactivate-streaming-destinations) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/537096)

{{< /details >}}

以前は、監査イベントストリーミング先へのストリーミングを一時的に無効にする方法は提供されていませんでした。これは、ストリーム接続性のトラブルシューティングを行うためや、設定を削除して最初からやり直すことなく設定を変更するためなど、多くの理由でこれを行う場合があります。

GitLab 18.2では、監査イベントストリームをアクティブまたは非アクティブとして切替える機能が追加されました。監査イベントストリームが非アクティブの場合、監査イベントは選択されたストリーミング先にストリーミングされなくなります。再有効化されると、監査イベントは再び選択されたストリーミング先にストリーミングされます。

### すべての監査イベントストリーミング先のフィルター機能 {#filter-functionality-for-all-audit-streaming-destinations}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/audit_event_streaming.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/524939)

{{< /details >}}

以前は、特定の監査イベントストリーミング先には、利用可能なすべてのフィルタリング機能がありませんでした。

現在、UIを介したすべてのストリーミング先のフィルター機能をサポートしており、以下によるフィルターを含みます:

- 監査イベント型別。
- グループまたはGitLabプロジェクト別。

この変更は、AWSやGCPなどの監査イベントストリーミング先も監査イベントをフィルターできるようになったことを意味します。

### エピックの表示設定を構成する {#configure-epic-display-preferences}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/group/epics/manage_epics.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/393559)

{{< /details >}}

作業アイテムのリストをビューする際に表示されるメタデータを完全にコントロールできるようになり、最も重要な情報に焦点を合わせることが容易になりました。

以前は、すべてのメタデータフィールドが常に表示レベルで、作業アイテムをスキャンするのが大変でした。現在、割り当て、ラベル、日付、マイルストーンなどの特定のフィールドをオンまたはオフに切替えることで、ビューをカスタマイズできます。

### エピックページでエピックをドロワーまたはフルページで開く {#open-epics-in-a-drawer-or-the-full-page-on-the-epics-page}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/group/epics/manage_epics.md#open-epics-in-a-drawer) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/536620)

{{< /details >}}

新しい切替で、エピックがリストページからどのように開くかを選択できるようになりました。これは、ドロワービューとフルページナビゲーションを切り替えることができます。

ドロワーを使用してエピックの詳細をすばやくレビューし、エピックリストのコンテキストを維持するか、詳細な編集と包括的なナビゲーションのためにより多くの画面スペースが必要な場合にフルページを開きます。

### エピックに[マイルストーン](../../user/project/milestones/_index.md)を割り当てることで、長期計画を強化 {#assign-milestones-to-epics-for-enhanced-long-term-planning}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/milestones/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/329)

{{< /details >}}

エピックに[マイルストーン](../../user/project/milestones/_index.md)を直接割り当てることで、戦略的イニシアチブから実行まで自然な計画カスケードを作成できるようになりました。この機能強化により、四半期計画やSAFeプログラムインクリメントのような長期計画ケイデンスをエピックと連携するするのに役立ちます。同時に、イテレーションは開発スプリントに焦点を合わせることができます。

この明確な階層により、管理上のオーバーヘッドを削減し、組織のタイムフレームに対して戦略的イニシアチブがどのように進捗するかについて、より良い表示レベルを得ることができます。

### チームメンバーにエピックを割り当てる {#assign-epics-to-team-members}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/group/epics/manage_epics.md#assignees) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/4231)

{{< /details >}}

現在、個人にエピックを割り当てるて、戦略的イニシアチブの監督責任者が誰であるかを明確にすることができます。エピックの割り当ては、ポートフォリオレベルでの所有権を特定するのに役立ち、長期目標に対するより迅速な意思決定と明確な責任を可能にします。チームは、エピックの進捗、依存関係、またはスコープ変更について誰に連絡するべきかを迅速に確認することができます。

### GLQLビューのソートとページネーション {#sorting-and-pagination-for-glql-views}

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/glql/_index.md#presentation-syntax) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/502701)

{{< /details >}}

このリリースでは、GLQLビューのソートとページネーションが強化され、大規模なデータセットの作業が容易になりました。

現在、期日、ヘルスステータス、人気度などの主要なフィールドでソートして、最も関連性の高いアイテムを迅速に見つけることができます。新しい「さらに読み込む」ページネーションシステムは、データの読み込むをより適切にコントロールし、圧倒的なフルページの結果を、オンデマンドで読み込む管理可能なチャンクに置き換えます。

これらの改善により、チームは複雑なGitLabプロジェクトデータを効率的にナビゲートし、いつでも最も重要なことに焦点を合わせることができます。

### GitLab Flavored Markdownの作業アイテム参照とエディタの改善 {#work-item-references-and-editor-improvements-for-gitlab-flavored-markdown}

<!-- categories: Markdown -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/markdown.md#gitlab-specific-references) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/7654)

{{< /details >}}

現在、GitLab Flavored Markdownで統一された`[work_item:123]`構文を使用してイシュー、エピック、および作業アイテムを参照することができます。この新しい構文は、イシュー用の`#123`やエピック用の`&123`などの既存の参照形式と並行して機能し、`[work_item:namespace/project/123]`によるクロスプロジェクト参照をサポートします。

プレーンテキストエディタには、Enterキーを押したときにカーソルインデントを維持する新しい[設定](../../user/profile/preferences.md#maintain-cursor-indentation)も含まれており、ネストされたリストやコードブロックなどの構造化されたコンテンツをより容易にすることができます。

### 脆弱性レポートのCSVエクスポートに脆弱性IDを追加 {#vulnerability-id-added-to-vulnerability-report-csv-export}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md#exporting) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18033)

{{< /details >}}

以前は、脆弱性レポートのCSVエクスポートには脆弱性IDが含まれていませんでした。現在、CSVエクスポートにリストされている各脆弱性のIDを見つけることができます。

### 脆弱性レポートの到達可能性フィルター {#reachability-filter-in-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md#filtering-vulnerabilities) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/543346)

{{< /details >}}

ユーザーは、脆弱性レポートのデータをフィルターして、到達可能な脆弱性のみを含めることができるようになりました。到達可能な脆弱性は、以下の両方に該当する脆弱性を表す:

- CVEリストに掲載されている。
- 明示的にインポートされているライブラリの一部である。

### 脆弱性GraphQLAPIが追加情報を返す {#vulnerability-graphql-api-returns-additional-information}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../api/graphql/reference/_index.md#vulnerability) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/468913)

{{< /details >}}

GraphQLAPIを使用して、脆弱性がいつ導入され、いつ最後に検出されたかをパイプラインで判断できるようになりました。脆弱性GraphQLAPIには、次のものが含まれるようになりました:

- `initialDetectedPipeline`: 脆弱性がいつ導入されたかに関する追加のコミット情報（作成者のユーザー名前など）を取得するために使用します。
- `latestDetectedPipeline`: 脆弱性がいつ削除されたかに関する追加のコミット情報（コミットSHAなど）を取得するために使用します。

### 承認ポリシーのソースブランチパターン例外 {#source-branch-pattern-exceptions-for-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#source-branch-exceptions) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18113)

{{< /details >}}

以前は、GitFlowを使用するチームは、`release/*`ブランチを`main`にマージするする際に承認デッドロックに直面するすることがよくありました。これは、ほとんどのコントリビューターがすでにリリース開発に参加しており、承認者として機能するできなかったためです。

マージリクエスト承認ポリシーにおけるブランチパターン例外は、特定のソースブランチ-ターゲットブランチの組み合わせに対する承認要件を自動的にバイパスするすることで、この問題を解決します。フィーチャーからmainへのマージするに対する厳格な承認を設定し、同時に合理化されたリリースからmainへのワークフローを可能にします。

**Key capabilities:**

- **Pattern-based configuration**: 承認要件をバイパスする`release/*`や`hotfix/*`のようなソースブランチパターンを定義
- **Seamless integration**: ブランチ例外は、既存のマージリクエスト承認ポリシーに直接統合され、UIまたは`policy.yml`ファイルを通じて設定可能です。

これにより、複雑な回避策の必要性がなくなり、標準的な開発ワークフローにおけるマージリクエスト承認ポリシーのセキュリティ上の利点が維持されます。

### 依存パスを表示する {#display-dependency-paths}

<!-- categories: Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_list/_index.md#dependency-paths) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16815)

{{< /details >}}

以前は、ある依存が直接の依存関係なのか、それともその依存の子孫によってインポートされた一時的依存なのかを判断するのは困難でした。

新しい依存パス機能を使用すると、ライブラリが主にインポートされているか、推移的にインポートされているかを判断するできるようになりました。依存パスは、GitLabプロジェクトとグループの依存関係リスト、および脆弱性の詳細で確認できます。この機能により、デベロッパーは、ライブラリがどのようにインポートされるかに応じて、最も効率的な修正パスを判断するできます。

### 認証情報インベントリにサービスアカウントトークンが含まれるようになりました {#credentials-inventory-now-includes-service-account-tokens}

<!-- categories: System Access -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../administration/credentials_inventory.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/421954)

{{< /details >}}

GitLabは、認証情報インベントリでサービスアカウントトークンをサポートするようになり、ソフトウェアサプライチェーン全体で使用されるさまざまな認証方法について、より優れた表示レベルとコントロールを提供します。この認証情報インベントリは、組織全体で使用されている認証情報の全体像を提供します。

### 包括的な資産の表示レベルのためのセキュリティインベントリ（現在ベータ版） {#security-inventory-for-comprehensive-asset-visibility-now-in-beta}

<!-- categories: Security Asset Inventories -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/security_inventory/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16484)

{{< /details >}}

AppSecチームは、すべての資産にわたる組織のセキュリティ対策状況を包括的に表示レベルする必要があります。以前は、GitLabのセキュリティワークフローは主にGitLabプロジェクトレベルのスキャナー設定とGitLabプロジェクトレベルの脆弱性に焦点を合わせるており、カバレッジのギャップを理解し、効率的でリスクベースの優先順位付けの意思決定を行うことが困難でした。

セキュリティインベントリは、GitLabインスタンス全体のセキュリティ対策状況の一元的なビューを提供し、AppSecチームは以下のことが可能になります:

- GitLabプロジェクトとグループ全体のセキュリティカバレッジを完全に取得するする
- セキュリティスキャンが不足している、または設定にギャップがある資産を特定する
- セキュリティの取り組みにどこに焦点を合わせるべきかについて、情報に基づいたリスクベースの意思決定を行う
- 経時的なセキュリティ対策状況の改善を追跡する

この機能は、個々のGitLabプロジェクトセキュリティと組織全体のセキュリティ戦略との間のギャップを埋めるのに役立ち、効果的なセキュリティプログラム管理に必要な資産インベントリの基盤を提供します。

### カスタム管理者ロール（ベータ版） {#custom-admin-role-in-beta}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/custom_roles/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15069)

{{< /details >}}

カスタム管理者ロールは、GitLab Self-ManagedおよびGitLab Dedicatedインスタンスの管理者エリアに詳細な権限をもたらします。完全なアクセス権を付与する代わりに、管理者はユーザーが必要とする特定の機能のみにアクセスできる特殊なロールを作成できるようになりました。この機能は、組織が管理機能の最小権限の原則を実装し、過剰な権限によるアクセスから生じるセキュリティリスクを軽減し、運用の効率性を向上させるのに役立ちます。

この機能について、コミュニティからのフィードバックを積極的に募るています。ご質問がある場合、実装経験を共有したい場合、または潜在的な改善について当社のチームと直接関与したい場合は、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/509376)にアクセスしてください。

### トリガージョブはダウンストリームパイプラインステータスをミラーできます {#trigger-jobs-can-mirror-the-downstream-pipeline-status}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../ci/yaml/_index.md#triggerstrategy) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/431882)

{{< /details >}}

以前は、`strategy:depend`を使用するトリガージョブには、手動ジョブ、ブロックされたパイプライン、実行中にステータスが変化するする再試行されたパイプラインなど、複雑なパイプライン状態を扱う際に制限がありました。これにより、ダウンストリームパイプラインがアクティブに実行されているように見えることがありましたが、実際には手動ジョブでブロックされていました。

新しい`strategy:mirror`キーワードは、ダウンストリームパイプラインの正確なリアルタイムステータスをミラーすることで、より微妙なステータスレポートを提供します。ステータスには、`running`、`manual`、`blocked`、および`canceled`のような中間状態が含まれます。これにより、チームは既存のワークフローを中断するすることなく、ダウンストリームパイプラインの現在の状態を完全に表示レベルできます。

### GitLab Runner 18.2 {#gitlab-runner-182}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.2もリリースします！GitLab Runnerは、CI/CDジョブを実行し、その結果をGitLabインスタンスに送信する、拡張性の高いビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### バグ修正 {#bug-fixes}

- [GitLab Runner 18.1.0にアップグレードした後、FIPSモードでRunnerが失敗するする](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38890)
- [`FF_USE_DUMB_INIT_WITH_KUBERNETES_EXECUTOR`でジョブポッドを開始するできない](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/241)
- [`ubi-fips`イメージはGitLab RunnerFIPSのデフォルトヘルパーイメージフレーバーではない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38273)
- [GitLabメンテナンスモードを無効にするにした後、Runnerが長時間オフラインの残るになる](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29181)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-2-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-2-stable/CHANGELOG.md).md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.2)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.2)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.2)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
