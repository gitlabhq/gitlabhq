---
stage: Release Notes
group: Monthly Release
date: 2025-11-20
title: "GitLab 18.6 release notes"
description: "GitLab 18.6 released with The new GitLab UI: Designed for productivity"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年11月20日、GitLab 18.6がリリースされました。以下の機能が含まれています。

また、今月の注目コントリビューターをはじめ、すべてのコントリビューターに感謝申し上げます。

## 今月の注目コントリビューター: Samaksh Agarwal

GitLab Development Kit（GDK）を使用するすべてのデベロッパーが、Samakshの
[`gdk status`の可読性向上への貢献](https://gitlab.com/gitlab-org/gitlab-development-kit/-/merge_requests/5227)から恩恵を受けています。
この改善は表面上はシンプルに見えますが、デベロッパーエクスペリエンスへの卓越した配慮と、小さな改善が広範な影響をもたらすことへの深い理解を示しています。

`gdk status`の可読性向上により、GDKを使用するすべてのデベロッパーの時間が節約され、開発環境の中核をなすコンポーネントのアクセシビリティが大幅に向上します。このようなコントリビュートは、デベロッパーワークフローに意味のある改善をもたらす方法を深く理解していることを示しています。

自身のコントリビュートを振り返り、Samakshはこう語っています。「GitLab Development Kit（GDK）は、今の私が積極的にコントリビュートしている場所です。他のコントリビューターの体験を楽にし、便利にする側で働くことが好きだからです。それが私のなりたいデベロッパー像です。自分のスキルを使って他の人の生活を楽にできる人間になりたいのです。」

GitLabへのコントリビュート体験について、Samakshはこう述べています。「新鮮で質の高いオープンソース体験を求めているすべての人にGitLabをお勧めしたいです。最初にGitLabへのコントリビュートを始めたとき、少し圧倒されましたが、コミュニティの皆さんがとても協力的で、助けてくれて、温かく迎えてくれたので、その気持ちはすぐに消えました。このコミュニティとその文化に心から魅了されています。優れたドキュメントの作成から、高いコード品質の維持、コントリビューターへの真摯な感謝まで、GitLabコミュニティは本当に素晴らしいです。」

## 主要機能

### 新しいGitLab UI: 生産性のために設計

<!-- categories: Design Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../tutorials/gitlab_navigation.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17279)

{{< /details >}}

デベロッパーの生産性を最優先に考えた、よりスマートで直感的なGitLab UIをご紹介します。

新しいサイドバイサイドデザインは、コンテキストパネルを使用してワークフローを維持し、不要なクリックを減らしてチームの作業速度を向上させます。ワークスペースをカスタマイズし、画面スペースを最大限に活用して、ワークフローに適応するよりクリーンでダイナミックなエクスペリエンスをお楽しみください。

GitLabは継続的な改善にコミットしています。[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/577554)でご意見をお聞かせいただき、GitLabの未来を一緒に形作りましょう。

### 限定提供の完全一致コード検索

<!-- categories: Global Search -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/search/exact_code_search.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17918)

{{< /details >}}

今回のリリースで、完全一致コード検索が限定提供になりました。完全一致モードと正規表現モードを使用して、インスタンス全体、グループ、またはプロジェクト内のコードを検索できます。完全一致コード検索は、オープンソースの検索エンジンZoektを基盤としています。

GitLab.comでは、完全一致コード検索がデフォルトで有効になっています。GitLab Self-Managedでは、管理者が[Zoektをインストール](../../integration/zoekt/_index.md#install-zoekt)し、[完全一致コード検索を有効化](../../integration/zoekt/_index.md#enable-exact-code-search)する必要があります。

この機能は活発に開発中です。[イシュー420920](https://gitlab.com/gitlab-org/gitlab/-/issues/420920)でフィードバックをお待ちしています。

### CI/CDコンポーネントが自身のメタデータを参照可能に

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../ci/yaml/expressions.md#component-context) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/438275)

{{< /details >}}

以前は、CI/CDコンポーネントは設定内でバージョン番号やコミットSHAなどの自身のメタデータを参照できませんでした。この情報の欠如により、ハードコードされた値や複雑な回避策を使用した設定を使わざるを得ない場合がありました。このような設定の書き方は、コンポーネントがDockerイメージなどのリソースをビルドする際にバージョンの不一致を引き起こす可能性があります。コンポーネントの互換バージョンでそれらのリソースに自動的にタグ付けする方法がなかったためです。

今回のリリースでは、`spec:component`キーワードを使用してコンポーネントコンテキストにアクセスする機能を導入しました。コンポーネントバージョンをリリースする際に、Dockerイメージなどのバージョン管理されたリソースをビルドして公開できるようになり、すべてが同期された状態を保ち、手動によるバージョン管理が不要になり、バージョンの不一致を防ぐことができます。

### `needs:[parallel:matrix](../../ci/yaml.md#parallelmatrix)`での動的ジョブ依存関係のサポート

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../ci/yaml/matrix_expressions.md#matrix-expressions-in-needsparallelmatrix) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/423553)

{{< /details >}}

[`parallel:matrix`](../../ci/yaml/_index.md#parallelmatrix)を使用すると、異なる要件で複数のジョブを並行して実行することが容易になります。たとえば、複数のプラットフォームのコードを同時にテストする場合などです。しかし、後続のジョブが`needs:parallel:matrix`を使用して特定の並行ジョブに依存する場合、設定が複雑で柔軟性に欠けていました。

ベータ機能として導入された新しい`$[[matrix.VARIABLE]]`式により、ユーザーは動的な1対1の依存関係を作成できるようになり、複雑な`parallel:matrix`設定の管理が大幅に容易になります。これにより、効率的なアーティファクト処理、優れたスケーラビリティ、クリーンな設定を備えた高速なパイプラインを作成できます。この機能は、マルチプラットフォームビルド、複数環境へのTerraformデプロイ、複数のディメンションにわたる並行処理を必要とするワークフローに特に有効です。

### GitLabセキュリティアナリストエージェントが基盤エージェントとして利用可能に

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/security_analyst_agent.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19659)

{{< /details >}}

GitLabセキュリティアナリストエージェントが、GitLab Duo Agentic Chatの基盤エージェントになりました。これにより、ユーザーはAIカタログからGitLabセキュリティアナリストエージェントを手動で追加する必要がなくなり、GitLab Self-ManagedおよびGitLab Dedicatedでもデフォルトで利用できるようになりました。
この専門的なアシスタントは、AIネイティブの脆弱性管理とセキュリティ分析を提供し、セットアップなしで調査結果の調査、脆弱性のトリアージ、コンプライアンス要件のナビゲートを支援します。

この機能はベータ版です。[イシュー576916](https://gitlab.com/gitlab-org/gitlab/-/issues/576916)でフィードバックをお待ちしています。

### VS CodeおよびJetBrains IDEでのGitLab Duo Agentic Chatのモデル選択

<!-- categories: Editor Extensions, Model Personalization -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19345)

{{< /details >}}

VS CodeおよびJetBrains IDEで利用可能になったGitLab Duo Chatで、希望するAIモデルを簡単に選択できます。GitLab Duo Chatパネルのドロップダウンリストを使用して、Claude、GPT、その他のサポートされているモデルから選択できます。モデルの利用可能性は組織の管理者が管理しており、ワークフローに適したモデルへのアクセスが確保されています。

### セキュリティダッシュボードのアップグレード（GitLab.comでベータ版）

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/security_dashboard/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18509)

{{< /details >}}

新しいセキュリティダッシュボードが更新され、モダナイズされました。ベータリリースの初期機能には以下が含まれます。

- 以下をサポートする経時的な脆弱性チャート:
  - プロジェクトまたはレポートタイプによるフィルタリング。
  - レポートタイプと重大度によるグループ化。
  - 脆弱性レポート内の脆弱性への直接リンク。
- GitLabアルゴリズムに基づいてグループまたはプロジェクトの推定リスクを計算するリスクスコアモジュール。

18.6でリリースされた新しいセキュリティダッシュボードは、現在GitLab.comのみで利用可能です。

## エージェントコア

### GitLab MCPサーバーが[ベータ版](../../policy/development_stages_support.md#beta)で利用可能に

<!-- categories: MCP Server -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/model_context_protocol/mcp_server.md)

{{< /details >}}

GitLab MCPサーバーが[ベータ版](../../policy/development_stages_support.md#beta)で利用可能になりました。GitLab MCPサーバーを使用すると、Claude Code、Cursor、その他のMCP互換ツールなどのAIアシスタントを使って、各ツール用のカスタムインテグレーションを構築することなく、GitLabのプロジェクト、イシュー、マージリクエスト、パイプラインを操作できます。

開始するには、GitLab Duoの設定で[ベータ版および実験的機能を有効にする](../../user/gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)必要があります。

GitLab MCPサーバーはイシュー、マージリクエスト、パイプラインをカバーする主要なツールを提供しており、ユーザーフィードバックに基づいて継続的に改善しています。この機能は不完全な機能やバグが含まれる場合があります。ぜひお試しいただき、[イシュー561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564)でフィードバックをお寄せください。

### イシューの説明とコメントの両方で高度な検索が利用可能に

<!-- categories: Global Search -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/search/advanced_search.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/513146)

{{< /details >}}

高度な検索で、イシューの説明とコメントの両方から一致する結果が返されるようになりました。以前は、イシューの説明とコメントを別々に検索する必要がありました。この改善により、GitLabイシューのより合理的で包括的な検索ワークフローが実現します。

### Gemini 2.5 FlashモデルがGitLab Duo Self-Hosted向けGitLab Duo Agent Platformと互換

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/572353)

{{< /details >}}

GitLab Duo Self-HostedでGitLab Duo Agent PlatformにGemini 2.5 Flashモデルを使用できるようになりました。

## スケールとデプロイ

### プロジェクトおよびグループメンバー一覧のレート制限

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../administration/settings/rate_limit_on_projects_api.md#configure-rate-limits-on-listing-project-members) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/580116)

{{< /details >}}

APIの安定性を向上させ、すべてのユーザーにわたる公平なリソース使用を確保するために、`/api/v4/projects/:id/members/all`および`/api/v4/groups/:id/members/all`エンドポイントにレート制限を導入しました。
`GET /api/v4/projects/:id/members/all`および`GET /api/v4/groups/:id/members/all`エンドポイントには、ユーザーあたり1分間に200リクエストのレート制限が設けられました。

この変更は、すべてのユーザーのパフォーマンスに影響を与える可能性のある過剰なAPI使用からGitLabインスタンスを保護するのに役立ちます。1分間に200リクエストの制限は、通常の使用パターンに対して十分な容量を提供しながら、潜在的な乱用や意図しないリソース枯渇を防ぎます。
インテグレーションやスクリプトがこのエンドポイントを使用している場合は、レート制限レスポンス（HTTP 429）を適切に処理し、必要に応じてバックオフを伴うリトライロジックを実装してください。
通常の使用パターンでは、ほとんどのユーザーはこの変更の影響を受けないはずです。

## 統合されたDevOpsとセキュリティ

### シークレットプッシュ保護とパイプラインシークレット検出のルールカバレッジ拡大

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/secret_detection/detected_secrets.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/576279)

{{< /details >}}

GitLabのパイプラインシークレット検出に40の新しいルールのサポートを追加しました。品質を向上させ誤検出を減らすために、一部の既存ルールも更新されました。これらの変更はシークレットアナライザーの[バージョン7.20.1](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.20.1)でリリースされています。

### コードオーナーが継承されたグループメンバーシップをサポート

<!-- categories: Code Review Workflow, Source Code Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/project/codeowners/advanced.md#group-inheritance-and-eligibility)

{{< /details >}}

コードオーナーシップは、コード品質を維持し、コードベースの重要な部分への変更を適切な人がレビューするために不可欠です。しかし、複雑なグループ構造を持つ組織でコードオーナーを管理することは困難でした。以前は、`CODEOWNERS`ファイルでグループを参照するには、そのグループが親グループのメンバーであっても、各プロジェクトに直接招待する必要がありました。

コードオーナーは、継承されたメンバーシップを持つグループを承認者として認識するようになりました。

- 親グループメンバーシップを通じて継承されたアクセス権を持つグループは、コードオーナー承認が有効な場合に有効なコードオーナーとして認識されます。
- グループをすべてのプロジェクトに直接招待する必要がなくなりました。
- 既存の`CODEOWNERS`ファイルは変更なしで引き続き機能します。
- 重要なコードパスへの変更を承認できる人に対する同じレベルの制御が維持されます。

この変更により、コードオーナーが提供するセキュリティと承認要件を維持しながら、管理上のオーバーヘッドが削減されます。

### ホームページでのドラフトマージリクエストの表示切り替え

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/project/merge_requests/homepage.md#set-your-display-preferences) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/551475)

{{< /details >}}

ホームページでは、ドラフトマージリクエストがマージリクエストビューを煩雑にし、すぐに対応が必要な作業から注意をそらす可能性があります。以前は、それらをフィルタリングすることができませんでした。

表示設定を使用して、ホームページの**自分のマージリクエスト**セクションからドラフトマージリクエストを非表示にできるようになりました。ドラフトマージリクエストを非表示にすると:

- アクティブなカウントから除外されます。
- フィルタリングされたドラフトマージリクエストの数がフッターに表示されます。
- 設定は自動的に保存されます。

この変更により、即座に対応が必要なマージリクエストに集中できます。

### GitLab CLIの新機能と改善

<!-- categories: GitLab CLI -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/cli/) | [関連イシュー](https://gitlab.com/gitlab-org/cli/-/releases)

{{< /details >}}

GitLab CLI（glab）は、コマンドラインからのGitLabワークフローを強化する新機能と改善を提供します。

- **認証の強化**: ログイン時にgitリモートからGitLab URLを自動検出し、正しいGitLabインスタンスへの認証を容易にします。
- **柔軟なパイプラインモニタリング**: `ci-view`コマンドでIDを指定して任意のパイプラインを表示できます。
- **GPGキー管理**: 新しいコマンドでCLIから直接GPGキーを管理できます。
- **プロジェクトメンバー管理**: コマンドラインからプロジェクトメンバーの追加、削除、更新ができます。
- **Gitインテグレーションの改善**: すべてのトークンタイプをサポートするgit-credentialプラグインが強化されました。
- **モダンなユーザーインターフェース**: UIコンポーネント全体でより良い確認ダイアログと一貫したGitLabテーマを提供するプロンプトライブラリが更新されました。

変更と更新の完全なリストについては、[CLIリリース](https://gitlab.com/gitlab-org/cli/-/releases)を参照してください。
GitLab CLIを始めるか最新バージョンに更新するには、[インストールガイド](https://gitlab.com/gitlab-org/cli/#installation)を参照してください。

### マージリクエストレビュー再リクエストのWebhook通知

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/project/integrations/webhook_events.md#re-request-review-events)

{{< /details >}}

Webhookインテグレーションは、ワークフローを自動化し、外部システムをGitLabのマージリクエストアクティビティと同期させるために不可欠です。しかし、レビュアーがマージリクエストに再リクエストされた場合、Webhookコンシューマーはどの特定のレビュアーが再リクエストされているかを識別する方法がなく、適切な通知や自動化をトリガーすることが困難でした。

マージリクエストのWebhookペイロードに、どのレビュアーが再リクエストされたかを明確に示す`re_requested`属性がレビュアーデータに含まれるようになりました。

- 再リクエストされている特定のレビュアーには`true`が設定されます。
- 他のすべてのレビュアーには`false`が設定されます。

この改善により、マージリクエストのレビュープロセスに関するより精密な自動化が可能になります。Webhookコンシューマーは、ターゲットを絞った通知を送信し、外部トラッキングシステムを更新し、レビューが再リクエストされた際に適切なワークフローをトリガーできます。

### オフラインのGitLab Self-Managed環境向けWeb IDEサポート

<!-- categories: Web IDE, Editor Extensions -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/settings/web_ide.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/15146)

{{< /details >}}

オフラインまたは厳密に制御されたネットワーク環境のGitLab Self-Managed管理者は、カスタムWeb IDE拡張機能ホストドメインを設定できるようになり、外部インターネットアクセスなしでWeb IDEの全機能を使用できます。

以前は、Web IDEはVS Code拡張機能と機能を読み込むために`.cdn.web-ide.gitlab-static.net`への接続が必要でした。この要件により、セキュリティを重視する組織、政府・公共部門の顧客、厳格なネットワークポリシーを持つ企業でのWeb IDE導入が妨げられていました。

この更新により、管理者はGitLabインスタンスがWeb IDEアセットを直接提供するように設定でき、外部ドメインへの依存を排除できます。これにより以下が可能になります。

- 完全にオフラインの環境でWeb IDEの全機能セットを使用できます。
- カスタム拡張機能レジストリサービスで拡張機能マーケットプレースを有効にできます。
- 隔離されたネットワーク内のWeb IDEでMarkdownプレビュー、コード編集、GitLab Duo Chatを有効にできます。

### システム起動の承認リセットに対するWebhookトリガー

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/project/integrations/webhook_events.md#system-initiated-merge-request-events) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/553070)

{{< /details >}}

Webhookを通じてGitLabを外部システムと統合することは、自動化されたワークフローとマージリクエストのステータス変更についてチームに通知するために不可欠です。しかし、GitLabが自動的に承認をリセットする場合（「プッシュ時に承認をリセット」が有効なマージリクエストに新しいコミットがプッシュされた場合など）、外部システムはこれらのシステム起動イベントを手動のユーザーアクションと区別できませんでした。

GitLabには、システム起動の承認リセットを明確に識別する強化されたWebhookペイロードが含まれるようになりました。承認が自動的にリセットされると、Webhookには以下が含まれます。

- `true`に設定された`system`フィールド。
- リセットが発生した理由（`approvals_reset_on_push`や`code_owner_approvals_reset_on_push`など）に関する具体的なコンテキストを提供する`system_action`フィールド。

これにより、Webhookインテグレーションは手動の承認変更と自動システムリセットを区別できるようになり、各承認変更の特定のコンテキストに適切に対応するより高度な自動化ワークフローが可能になります。

### GitLab Duo Plannerエージェントがデフォルトで利用可能に

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/planner.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/580924)

{{< /details >}}

GitLab Duo Plannerエージェントが、GitLab Duo Chatのエージェントドロップダウンでデフォルトで利用可能になり、AIカタログから手動で追加する必要がなくなりました。作業アイテム、エピック、イシュー、タスクの完全なコンテキストを持つPlannerエージェントは、グループレベルとプロジェクトレベルの両方でサポートできるようになりました。

[**[プロンプト例](../../user/duo_agent_platform/agents/foundational_agents/planner.md#example-prompts)**](../../user/duo_agent_platform/agents/foundational_agents/planner.md#example-prompts)を参考に、Plannerエージェントが複雑な作業の分解、実装計画の作成、チームの目標整理をどのように支援できるかをご確認ください。

この機能はベータ版です。[イシュー576622](https://gitlab.com/gitlab-org/gitlab/-/issues/576622)でフィードバックをお待ちしています。

### Helmチャートレジストリ: 1,000チャート制限の撤廃

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/packages/helm_repository/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/545919)

{{< /details >}}

GitLabのHelmチャートレジストリは以前、メタデータレスポンスをオンザフライで生成していたため、リポジトリに大量のチャートが含まれる場合にパフォーマンスのボトルネックが生じていました。システムの安定性を維持するために、最新の1,000チャートというハード制限を設けていました。この制限により、プラットフォームチームが古いチャートバージョンにアクセスしようとすると、404エラーが発生するという問題がありました。

プラットフォームエンジニアは、チャートを複数のリポジトリに分割したり、チャートの保持ポリシーを手動で管理したり、別のチャートストレージソリューションを維持したりするなど、複雑な回避策を実装せざるを得ませんでした。これらの回避策は運用上のオーバーヘッドを増加させ、デプロイワークフローを断片化させ、集中型チャートガバナンスの維持を困難にしていました。

GitLab 18.6では、メタデータレスポンスを事前計算してオブジェクトストレージに保存することで、1,000チャートの制限を撤廃しました。このアーキテクチャの変更により、メタデータはリクエストごとではなくバックグラウンドジョブで一度生成されるため、無制限のチャートアクセスとパフォーマンスの向上の両方が実現します。

### マージリクエスト承認ポリシーの警告モード（ベータ版）

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#warn-mode) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19595)

{{< /details >}}

セキュリティチームは、警告モードを使用して、セキュリティポリシーを適用する前にその影響をテストおよび検証できるようになり、セキュリティポリシーのロールアウト中のデベロッパーの摩擦を軽減できます。

[マージリクエスト承認ポリシー](../../user/application_security/policies/merge_request_approval_policies.md)を作成または編集する際に、`warn`または`enforce`の適用オプションを選択できるようになりました。

警告モードのポリシーは、マージリクエストをブロックせずに情報提供のボットコメントを生成します。ポリシーに関する質問の窓口として、オプションの承認者を指定できます。このアプローチにより、セキュリティチームはポリシーの影響を評価し、透明性のある段階的なポリシー導入を通じてデベロッパーの信頼を構築できます。

マージリクエストの明確なインジケーターにより、ポリシーが`warn`または`enforce`モードにあることがユーザーに伝わり、監査イベントはコンプライアンスレポートのためにポリシー違反と却下を追跡します。デベロッパーは却下の理由を提供しながら脆弱性を却下でき、セキュリティポリシー管理への協調的なアプローチが生まれます。

### セキュリティ属性（ベータ版）

<!-- categories: Security Asset Inventories -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/attributes/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19597)

{{< /details >}}

セキュリティチームは、セキュリティ属性を活用してプロジェクトにビジネスコンテキストを適用できるようになりました。

セキュリティ属性は、ビジネスインパクト（構造化された事前定義の選択肢を含む）、アプリケーション、ビジネスユニット、インターネットエクスポージャー、ロケーションなどのカテゴリで整理されています。または、独自の属性カテゴリを作成し、それらのカテゴリ内でラベルを定義することもできます。

これらの属性をプロジェクト全体に適用することで、リスクポジションと組織のコンテキストに基づいてアクションが必要なプロジェクトをセキュリティインベントリ内でより迅速に検索、フィルタリング、特定できます。以下が可能になります。

- ミッションクリティカルでより良いスキャンカバレッジが必要なプロジェクトを特定する
- アプリケーションまたはビジネスユニット別にスキャンカバレッジをレビューする
- プロジェクトに適用された属性に基づいて検索およびフィルタリングする
- 公開/露出されているアプリケーションに貢献するプロジェクトを迅速に特定する

### マージリクエスト承認ポリシーをバイパスするための例外

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18114)

{{< /details >}}

組織は、重大な状況が発生した場合にマージリクエスト承認ポリシーをバイパスできる特定のユーザー、グループ、ロール、またはカスタムロールを指定できるようになりました。この機能は、包括的な監査証跡とガバナンス制御を維持しながら、緊急対応に柔軟性を提供します。

**責任を伴う緊急バイパス**: 指定されたユーザーは、重大なインシデント、セキュリティホットフィックス、または緊急の本番環境の問題が発生した際に承認要件をバイパスできます。緊急事態が発生した場合、権限を持つ担当者は変更を即座にマージまたはプッシュでき、システムはコンプライアンスレビューのための詳細な正当化と監査情報を記録します。

**主な機能:**

- **文書化されたバイパスプロセス**: 権限を持つユーザーがポリシーバイパスを実行する際、直感的なモーダルインターフェースを使用して詳細な理由を提供する必要があり、すべての例外がコンテキストとともに適切に文書化されます。
- **包括的な監査インテグレーション**: すべてのバイパスは、例外使用パターンの完全な可視性のために、ユーザーID、ポリシーコンテキスト、理由、タイムスタンプを含む詳細な監査イベントを生成します。
- **柔軟な設定**: YAMLまたはUI設定を使用してポリシーの例外権限を定義し、個々のユーザー、GitLabグループ、標準ロール、カスタムロールをサポートします。
- **Gitベースのプッシュ例外**: 事前承認されたポリシー例外を持つユーザーは、プッシュバイパスオプション`security_policy.bypass_reason`を実行する際に直接プッシュできます。

この機能により、緊急時にセキュリティポリシーを完全に無効にする必要がなくなり、組織のガバナンスと監査要件を維持しながら緊急の変更のための制御されたパスが提供されます。

### アカウント継承受益者の指定

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/account/account_succession.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/330669)

{{< /details >}}

無能力または利用不可能な場合に、GitLabアカウントを管理するためのアカウント受益者権限を指定できるようになりました。アカウントにアクセスするには、受益者は適切な法的文書を提供する必要があります。この機能は、不正アクセスを防ぎながら、作業とプロジェクトの継続性を確保するのに役立ちます。

### グループオーナーがエンタープライズユーザーのプライマリメールを更新可能に

<!-- categories: System Access -->

{{< details >}}

- プラン: Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/enterprise_user/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/425837)

{{< /details >}}

グループオーナーは、グループ内のエンタープライズユーザーのプライマリメールアドレスを更新できるようになりました。更新はUsers APIを通じて行えます。以前は、各エンタープライズユーザーが自分のメールアドレスを手動で更新する必要がありました。この変更により、エンタープライズユーザーを大規模に管理しやすくなります。

### GitLab Runner 18.6

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、政府機関向けGitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.6もリリースします。GitLab RunnerはCI/CDジョブを実行し、結果をGitLabインスタンスに送信する高スケーラブルなビルドエージェントです。GitLab RunnerはGitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能

- [最小限のジョブ確認APIの実装](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39013)

#### バグ修正

- [GitLab RunnerがDockerイメージプラットフォームオプションの変数を展開しない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38488)
- [ヘルパーサイドカーコンテナが別のアカウントのS3バケットへのキャッシュのアップロードに失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37879)
- [自動キャンセルされたジョブが実行を継続して失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37878)
- [生成されたPowerShellスクリプトにUTF8 BOMが欠落しており、文字ÄのマージリクエストタイトルによるリモートコードExecution実行が可能になる](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36060)
- [KubernetesエグゼキューターでのKubernetes APIサーバーリクエストの断続的な失敗](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30109)
- [Kubernetesエグゼキューターを使用する場合、大きなコミットメッセージを持つジョブが失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26624)

すべての変更のリストはGitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-6-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-6-stable/CHANGELOG.md).md)にあります。

## 関連トピック

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.6)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.6)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.6)
- [非推奨と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
