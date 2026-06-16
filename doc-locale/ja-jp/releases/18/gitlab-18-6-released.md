---
stage: Release Notes
group: Monthly Release
date: 2025-11-20
title: "GitLab 18.6リリースノート"
description: "GitLab 18.6が新しいGitLab UI: 生産性を追求したデザインとともにリリース"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年11月20日、GitLab 18.6が以下の機能とともにリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Samaksh Agarwal {#this-months-notable-contributor-samaksh-agarwal}

GitLab Development Kit（GDK）を使用するすべてのデベロッパーは、Samakshによる[`gdk status`の可読性を向上させるためのコントリビュート](https://gitlab.com/gitlab-org/gitlab-development-kit/-/merge_requests/5227)から恩恵を受けています。この強化は表面的にはシンプルに見えるかもしれませんが、デベロッパーエクスペリエンスへの並外れた注意と、小さな改善がいかに広範囲に影響を与えるかを理解していることを示しています。

`gdk status`の可読性が向上したことで、GDKを使用するすべてのデベロッパーの時間が節約され、開発環境の核となる部分のアクセシビリティが大幅に向上しました。この種のコントリビュートは、デベロッパーのワークフローに有意義な改善をもたらす方法を理解する上で成熟度を示しています。

自身のコントリビュートについて振り返り、Samakshは次のように述べています: 「GitLab Development Kit（GDK）は、今のところ私の積極的なコントリビュートの選択肢です。なぜなら、他のコントリビューターにとってエクスペリエンスを簡単で便利なものにする側面で作業するのが個人的に好きだからです。そして、それが私がなりたいデベロッパーです。自分のスキルを使って他の人々の生活を楽にできるような。」

GitLabへのコントリビュート経験について尋ねられたとき、Samakshは次のように述べています: 「新鮮で質の高いオープンソース体験をしたいすべての人にGitLabをお勧めします。GitLabへのコントリビュートを始めた当初は少し戸惑いましたが、コミュニティの皆さんがとても協力的で親切に迎えてくれたので、不安はすべてなくなりました。私はコミュニティと、彼らが物事をどのように進めているかに完全に魅了されています。優れたドキュメントの作成から、最高のコード品質の維持、そしてコントリビューターへの真摯な感謝まで、GitLabコミュニティは本当に素晴らしいです。」

## 主要な機能 {#primary-features}

### 新しいGitLab UI: 生産性を追求したデザイン {#the-new-gitlab-ui-designed-for-productivity}

<!-- categories: Design Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/interface_redesign.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17279)

{{< /details >}}

スマートでより直感的なGitLab UIを導入し、デベロッパーの生産性を最優先します。

新しい並列デザインは、コンテキストパネルを使用してワークフローを維持し、不要なクリックを減らし、チームの作業を高速化します。独自のワークスペースをカスタマイズし、画面スペースを最大限に活用し、ワークフローに適応する、よりクリーンでダイナミックなエクスペリエンスをお楽しみください。

GitLabは継続的な改善に取り組んでいますので、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/577554)でご意見を共有し、GitLabの未来を形作るお手伝いをしてください。

### 利用可能な完全一致コードの検索（制限付き） {#exact-code-search-in-limited-availability}

<!-- categories: Global Search -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/search/exact_code_search.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17918)

{{< /details >}}

今回のリリースにより、完全一致コードの検索の利用が限定的に開始されました。完全一致モードと正規表現モードを使用して、インスタンス全体、グループ、またはプロジェクト内のコードを検索できます。完全一致コードの検索は、オープンソースの検索エンジンZoekt上に構築されています。

GitLab.comでは、完全一致コードの検索はデフォルトで有効になっています。GitLab Self-Managedの場合、管理者は[Zoektをインストール](../../integration/zoekt/_index.md#install-zoekt)し、[完全一致コードの検索を有効にする](../../integration/zoekt/_index.md#enable-exact-code-search)必要があります。

この機能は現在活発に開発中です。[イシュー420920](https://gitlab.com/gitlab-org/gitlab/-/issues/420920)でフィードバックをお待ちしております！

### CI/CDコンポーネントが自身のメタデータを参照できるようになりました {#cicd-components-can-reference-their-own-metadata}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../ci/yaml/expressions.md#component-context) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/438275)

{{< /details >}}

これまで、CI/CDコンポーネントは、自身の設定内でバージョン番号やコミットSHAなどの自身のメタデータを参照できませんでした。この情報不足は、ハードコードされた値を含む設定や、複雑な回避策を使用することにつながる可能性がありました。このように設定を記述すると、コンポーネントがDockerイメージなどのリソースをビルドする際にバージョンの不一致が発生する可能性があります。これは、コンポーネントの互換性のあるバージョンでそれらのリソースを自動的にタグ付けする方法がないためです。

今回のリリースでは、`spec:component`キーワードでコンポーネントコンテキストにアクセスする機能が導入されました。コンポーネントバージョンをリリースする際に、Dockerイメージなどのバージョン管理されたリソースをビルドおよび公開できるようになり、すべてが同期され、手動のバージョン管理が不要になり、バージョンの不一致を防ぐことができます。

### `needs:[parallel:matrix](../../ci/yaml.md#parallelmatrix)`での動的なジョブの依存関係をサポート {#support-dynamic-job-dependencies-in-needsparallelmatrixciyamlmdparallelmatrix}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../ci/yaml/matrix_expressions.md#matrix-expressions-in-needsparallelmatrix) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/423553)

{{< /details >}}

[`parallel:matrix`](../../ci/yaml/_index.md#parallelmatrix)を使用すると、異なる要件を持つ複数のジョブを並行して簡単に実行できます。たとえば、複数のプラットフォームで同時にコードをテストできます。しかし、後のジョブが特定の並列ジョブに`needs:parallel:matrix`で依存するようにしたい場合、設定は複雑で柔軟性に欠けていました。

今回、ベータ機能として導入された新しい`$[[matrix.VARIABLE]]`式を使用すると、ユーザーは動的な1対1の依存関係を作成できるようになり、複雑な`parallel:matrix`設定の管理がはるかに簡単になります。これにより、より高速なパイプライン、効率的なアーティファクト処理、優れたスケーラビリティ、およびクリーンな設定を実現できます。この機能は、マルチプラットフォームビルド、Terraformデプロイ、および複数の次元にわたる並列処理を必要とするあらゆるワークフローにとって特に価値があります。

### セキュリティ分析エージェントを基本エージェントとして利用可能 {#gitlab-security-analyst-agent-available-as-a-foundational-agent}

<!-- categories: Vulnerability Management, Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/security_analyst_agent.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19659)

{{< /details >}}

GitLabセキュリティ分析エージェントは、現在GitLab Duo Agentic Chatの基本エージェントです。これは、ユーザーがAIカタログからGitLab Security Analystエージェントを手動で追加する必要がなくなり、このエージェントがGitLab Self-ManagedおよびGitLab Dedicatedでもデフォルトで利用可能であることを意味します。この専門的なAIアシスタントは、AIネイティブな脆弱性管理とセキュリティ分析を提供し、発見内容の調査、脆弱性のトリアージ、およびコンプライアンス要件への対応をセットアップなしで支援します。

この機能はベータ版であり、[issue 576916](https://gitlab.com/gitlab-org/gitlab/-/issues/576916)でのフィードバックをお待ちしております。

### VS CodeおよびJetBrains IDEでのGitLab Duo Agentic Chatのモデル選択 {#model-selection-for-gitlab-duo-agentic-chat-in-vs-code-and-jetbrains-ides}

<!-- categories: Editor Extensions, Model Personalization -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/model_selection.md#select-a-model-for-a-feature) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19345)

{{< /details >}}

VS CodeおよびJetBrains IDEで利用できるようになったGitLab Duo Chatで、お好みのAIモデルを簡単に選択できます。GitLab Duo Chatパネルのドロップダウンリストを使用して、Claude、GPT、およびその他のサポートされているAIモデルから選択します。モデルの可用性は組織の管理者によって管理され、ワークフローに適したモデルにアクセスできることを保証します。

### セキュリティダッシュボードのアップグレード（GitLab.comでのベータ版） {#security-dashboard-upgrade-beta-on-gitlabcom}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/security_dashboard/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18509)

{{< /details >}}

新しいセキュリティダッシュボードは更新され、モダナイズされました。ベータリリースの初期機能は次のとおりです:

- 時間の経過に伴う脆弱性のチャート。以下をサポートします:
  - プロジェクトまたはレポートタイプに基づくフィルタリング。
  - レポートタイプと重大度によるグループ化。
  - 脆弱性レポート内の脆弱性への直接リンク。
- GitLabアルゴリズムに基づいてグループまたはプロジェクトのリスクを推定するリスクスコアモジュール。

18.6でリリースされた新しいセキュリティダッシュボードは、現在GitLab.comでのみ利用可能です。

## エージェント型コア {#agentic-core}

### GitLab MCPサーバーが[ベータ](../../policy/development_stages_support.md#beta)版として利用可能 {#gitlab-mcp-server-available-in-beta}

<!-- categories: MCP Server -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/model_context_protocol/mcp_server.md)

{{< /details >}}

GitLab MCPサーバーは[ベータ](../../policy/development_stages_support.md#beta)版として利用可能です。GitLab MCPサーバーを使用すると、Claude Code、Cursor、およびその他のMCP互換ツールなどのAIアシスタントを使用して、GitLabプロジェクト、イシュー、マージリクエスト、およびパイプラインと対話できます。これらはすべて、各ツール用にカスタムのインテグレーションをビルドする必要がありません。

開始するには、GitLab Duoの設定で[ベータ版機能と実験的機能をオンにする](../../user/gitlab_duo/turn_on_off.md#turn-on-beta-and-experimental-features)必要があります。

GitLab MCPサーバーは、イシュー、マージリクエスト、パイプラインをカバーする主要なツールを提供しており、ユーザーフィードバックに基づいて引き続き改善していきます。この機能は、一部の機能が不完全であるか、バグが含まれている可能性があります。ぜひお試しいただき、[イシュー561564](https://gitlab.com/gitlab-org/gitlab/-/issues/561564)でフィードバックをお寄せください。

### イシューの説明とコメントの両方で高度な検索が利用可能 {#advanced-search-available-for-both-issue-descriptions-and-comments}

<!-- categories: Global Search -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/search/advanced_search.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/513146)

{{< /details >}}

高度な検索が、イシューの説明とコメントの両方から一致する結果を返すようになりました。以前は、ユーザーはイシューの説明とコメントを個別に検索する必要がありました。この改善により、GitLabイシューの検索ワークフローがより効率的かつ包括的になります。

### Gemini 2.5 Flashモデルが[GitLab Duo Self-Hosted](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models)用のGitLab Duo Agent Platformと互換性を持つようになりました {#gemini-25-flash-model-compatible-with-gitlab-duo-agent-platform-for-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/572353)

{{< /details >}}

GitLab Duo Self-HostedでGitLab Duo Agent Platform上のGemini 2.5 Flashモデルを使用できるようになりました。

## 規模とデプロイ {#scale-and-deployments}

### プロジェクトおよびグループメンバーのリスト表示のレート制限 {#rate-limit-for-listing-project-and-group-members}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../administration/settings/rate_limit_on_projects_api.md#configure-rate-limits-on-listing-project-members) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/580116)

{{< /details >}}

`/api/v4/projects/:id/members/all`および`/api/v4/groups/:id/members/all`エンドポイントに対するレート制限を導入し、APIの安定性を向上させ、すべてのユーザーにわたる公平なリソース使用を確保しました。`GET /api/v4/projects/:id/members/all`および`GET /api/v4/groups/:id/members/all`エンドポイントには、現在、ユーザーあたり1分あたり200リクエストのレート制限が設定されています。

この変更は、すべてのユーザーのパフォーマンスに影響を与える可能性のある過剰なAPI使用からGitLabインスタンスを保護するのに役立ちます。1分あたり200リクエストという制限は、通常の利用パターンに対して十分な容量を提供しつつ、潜在的な悪用や意図しないリソース枯渇を防ぎます。お客様のインテグレーションまたはスクリプトがこのエンドポイントを使用している場合は、レート制限の応答（HTTP 429）を適切に処理し、必要に応じてバックオフを伴う再試行ロジックを実装してください。ほとんどのユーザーは、通常の利用パターンではこの変更による影響を受けません。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### シークレットプッシュ保護とパイプラインシークレット検出のルールカバレッジの増加 {#increased-rule-coverage-for-secret-push-protection-and-pipeline-secret-detection}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/secret_detection/detected_secrets.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/576279)

{{< /details >}}

GitLabのパイプラインシークレット検出に40の新しいルールが追加されました。既存のルールの一部も、品質を向上させ、誤検出を減らすために更新されました。これらの変更は、シークレットアナライザーの[バージョン7.20.1](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/releases/v7.20.1)でリリースされます。

### コードオーナーが継承されたグループメンバーシップをサポート {#code-owners-now-supports-inherited-group-memberships}

<!-- categories: Code Review Workflow, Source Code Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/project/codeowners/advanced.md#group-inheritance-and-eligibility)

{{< /details >}}

コードのオーナーシップは、コード品質を維持し、コードベースの機密部分に対する変更を適切な人物がレビューすることを保証するために不可欠です。しかし、複雑なグループ構造を持つ組織でコードオーナーを管理することは困難でした。以前は、`CODEOWNERS`ファイルでグループを参照するには、そのグループがすでに親グループのメンバーであったとしても、各特定のプロジェクトに直接招待する必要がありました。

コードオーナーは、継承されたメンバーシップを持つグループを対象となる承認者としてサポートするようになりました:

- 親グループメンバーシップを通じて継承されたアクセス権を持つグループは、コードオーナーの承認が有効になっている場合、有効なコードオーナーとして認識されます。
- すべてのプロジェクトにグループを直接招待する必要はありません。
- 既存の`CODEOWNERS`ファイルは変更なしで引き続き機能します。
- 重要なコードパスへの変更を誰が承認できるかについて、同じレベルの制御が可能です。

この変更により、コードオーナーが提供するセキュリティと承認の要件を維持しつつ、管理上のオーバーヘッドが削減されます。

### ホームページでの下書きマージリクエストの表示レベルを切替える {#toggle-draft-merge-request-visibility-on-your-homepage}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/project/merge_requests/homepage.md#set-your-display-preferences) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/551475)

{{< /details >}}

ホームページでは、下書きマージリクエストがマージリクエストビューを乱雑にし、アクションの準備ができている作業から注意をそらす可能性があります。以前は、それらをフィルタリングすることはできませんでした。

表示設定を使用することで、ホームページの**マージリクエスト**セクションから下書きマージリクエストを非表示にできるようになりました。下書きマージリクエストを非表示にすると:

- アクティブなカウントから除外されます。
- フッターにフィルタリングされた下書きマージリクエストの数が表示されます。
- 設定は自動的に保存されます。

この変更により、すぐに注意が必要なマージリクエストに集中しやすくなります。

### 新しいGitLab CLIの機能と改善 {#new-gitlab-cli-features-and-improvements}

<!-- categories: GitLab CLI -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](https://docs.gitlab.com/cli/) | [関連イシュー](https://gitlab.com/gitlab-org/cli/-/releases)

{{< /details >}}

GitLab CLI（glab）は、コマンドラインからGitLabワークフローを強化する新しい機能と改善を提供します:

- **Enhanced authentication**: ログイン時にGitリモートからGitLab URLを自動検出することで、適切なGitLabインスタンスに対して簡単に認証することができます。
- **Flexible pipeline monitoring**: `ci-view`コマンドで、IDによって任意のパイプラインを表示します。
- **GPG key management**: 新しいコマンドを使用して、CLIから直接GPGキーを管理します。
- **Project member management**: コマンドラインからプロジェクトメンバーを追加、削除、更新します。
- **Improved Git integration**: すべてのトークンタイプをサポートする強化されたgit-credentialプラグイン。
- **Modern user interface**: より良い確認ダイアログとUIコンポーネント全体での一貫したGitLabテーマのための更新されたプロンプトライブラリ。

変更と更新の完全なリストについては、[CLIリリース](https://gitlab.com/gitlab-org/cli/-/releases)を参照してください。GitLab CLIの開始または最新バージョンへの更新については、[インストールガイド](https://gitlab.com/gitlab-org/cli/#installation)を参照してください。

### マージリクエストのレビュー再リクエストに対するWebhook通知 {#webhook-notifications-for-merge-request-review-re-requests}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/project/integrations/webhook_events.md#re-request-review-events)

{{< /details >}}

Webhookインテグレーションは、ワークフローを自動化し、外部システムをGitLabのマージリクエストアクティビティと同期させるために不可欠です。しかし、マージリクエストに対してレビュアーが再リクエストされた場合、Webhookコンシューマーはどの特定のレビュアーが再リクエストされたかを特定する方法がなく、適切な通知や自動化をトリガーすることが困難でした。

マージリクエスト用のWebhookペイロードには、レビュアーデータに`re_requested`属性が含まれるようになり、どのレビュアーが再リクエストされたかを明確に示します:

- 再リクエストされた特定のレビュアーに対して`true`に設定されます。
- その他のすべてのレビュアーに対して`false`に設定されます。

この改善により、マージリクエストのレビュープロセスにおけるより正確な自動化が可能になります。Webhookコンシューマーは、レビューが再リクエストされたときに、ターゲットを絞った通知を送信し、外部の追跡システムを更新し、適切なワークフローをトリガーすることができます。

### オフラインのGitLab Self-Managed環境でのWeb IDEのサポート {#web-ide-support-for-offline-gitlab-self-managed-environments}

<!-- categories: Web IDE, Editor Extensions -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/settings/web_ide.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/15146)

{{< /details >}}

オフラインまたは厳しく制御されたネットワーク環境のGitLab Self-Managed管理者は、カスタムWeb IDE拡張機能ホストドメインを設定できるようになり、外部インターネットアクセスなしで完全なWeb IDE機能を利用できます。

以前は、Web IDEはVS Codeの拡張機能と機能を読み込むために`.cdn.web-ide.gitlab-static.net`への接続が必要でした。この要件は、セキュリティを重視する組織、政府公共部門の顧客、および厳格なネットワークポリシーを持つ企業にとって、Web IDEの採用を妨げていました。

この更新により、管理者はGitLabインスタンスをWeb IDEアセットを直接提供するように設定でき、外部ドメインへの依存関係を排除できます。できるようになりました:

- 完全にオフラインの環境でWeb IDEの全機能セットを使用します。
- カスタム拡張機能レジストリサービスを使用して拡張機能マーケットプレースを有効にします。
- 隔離されたネットワークで、Web IDE内でMarkdownプレビュー、コード編集、およびGitLab Duo Chatを有効にします。

### システムが開始した承認のリセットに対するWebhookトリガー {#webhook-triggers-for-system-initiated-approval-resets}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/project/integrations/webhook_events.md#system-initiated-merge-request-events) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/553070)

{{< /details >}}

外部システムとWebhookを通じてGitLabを統合することは、自動化されたワークフローとマージリクエストのステータス変更についてチームに情報を提供し続けるために不可欠です。しかし、GitLabが自動的に承認をリセットする場合（例えば、「プッシュ時に承認をリセット」が有効になっているマージリクエストに新しいコミットがプッシュされた場合など）、外部システムはこれらのシステム開始イベントを手動のユーザーアクションと区別できませんでした。

GitLabは、システムが開始した承認のリセットを明確に識別する強化されたWebhookペイロードを含むようになりました。承認が自動的にリセットされると、Webhookには以下が含まれるようになります:

- `system`フィールドが`true`に設定されます。
- リセットが発生した理由に関する特定のコンテキストを提供する`system_action`フィールド（例: `approvals_reset_on_push`または`code_owner_approvals_reset_on_push`）。

これにより、お客様のWebhookインテグレーションは、手動の承認変更と自動的なシステムリセットを区別できるようになり、各承認変更の特定のコンテキストに適切に対応する、より高度な自動化ワークフローが可能になります。

### GitLab Duoプランナーエージェントがデフォルトで利用可能になりました {#gitlab-duo-planner-agent-now-available-by-default}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/foundational_agents/planner.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/580924)

{{< /details >}}

GitLab DuoプランナーエージェントがGitLab Duo Chatのエージェントドロップダウンでデフォルトで利用可能になり、AIカタログから手動で追加する必要がなくなりました。あなたの作業アイテム、エピック、イシュー、タスクの完全なコンテキストにより、プランナーエージェントはグループとプロジェクトの両方のレベルであなたを支援できるようになりました。

複雑な作業を細分化し、実装計画を作成し、チームの目標を整理するためにプランナーエージェントがどのように役立つかを確認するには、[**[プロンプト](../../user/duo_agent_platform/agents/foundational_agents/planner.md#example-prompts)**\](../../user/duo_agent_platform/agents/foundational_agents/planner.md#example-prompts) の例から始めましょう。

この機能はベータ版であり、[イシュー576622](https://gitlab.com/gitlab-org/gitlab/-/issues/576622)でフィードバックをお待ちしております。

### Helmチャートレジストリ: 1,000チャートのハード制限がなくなりました {#helm-chart-registry-no-more-1000-chart-limit}

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/packages/helm_repository/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/545919)

{{< /details >}}

以前のGitLabのHelmチャートレジストリは、メタデータ応答をオンザフライで生成していました。これにより、リポジトリに多数のチャートが含まれる場合にパフォーマンスのボトルネックが発生していました。システムの安定性を維持するため、最新の1,000チャートに対してハード制限を適用していました。この制限により、プラットフォームチームが古いチャートバージョンにアクセスしようとすると、フラストレーションのたまる404エラーが発生していました。

プラットフォームエンジニアは、複数のリポジトリにチャートを分割したり、チャートの保持ポリシーを手動で管理したり、個別のチャートストレージソリューションを維持したりするなどの複雑な回避策を実装することを余儀なくされていました。これらの回避策は、運用上のオーバーヘッドを増やし、デプロイワークフローを分断し、一元化されたチャートのガバナンスを維持することをより困難にしていました。

GitLab 18.6では、メタデータ応答を事前に計算し、オブジェクトストレージに保存することで、1,000チャートの制限を撤廃しました。このアーキテクチャ変更により、メタデータがすべてのリクエスト時ではなく、バックグラウンドジョブで一度生成されるため、無制限のチャートアクセスとパフォーマンスの向上の両方が実現されます。

### マージリクエスト承認ポリシーの警告モード（ベータ版） {#warn-mode-in-merge-request-approval-policies-beta}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#warn-mode) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19595)

{{< /details >}}

セキュリティチームは、警告モードを使用してセキュリティポリシーの適用前にその影響をテストおよび検証することができ、セキュリティポリシーのロールアウト中のデベロッパーの摩擦を軽減します。

[マージリクエスト承認ポリシー](../../user/application_security/policies/merge_request_approval_policies.md)を作成または編集する際に、`warn`または`enforce`の適用オプションを選択できるようになりました。

警告モードのポリシーは、マージリクエストをブロックすることなく、情報提供のボットコメントを生成します。オプションの承認者は、ポリシーに関する問い合わせの連絡先として指定できます。このアプローチにより、セキュリティチームはポリシーの影響を評価し、透明で段階的なポリシー採用を通じてデベロッパーの信頼を構築できます。

マージリクエストの明確なインジケーターは、ポリシーが`warn`または`enforce`モードである時期をユーザーに示し、監査イベントはコンプライアンスレポートのためにポリシーの違反と無視を追跡します。デベロッパーは、脆弱性を無視する際にその理由を提供することができ、セキュリティポリシー管理への協力的なアプローチを生み出します。

### セキュリティ属性（ベータ版） {#security-attributes-beta}

<!-- categories: Security Asset Inventories -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/attributes/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/19597)

{{< /details >}}

セキュリティチームは、セキュリティ属性を活用することで、プロジェクトにビジネスコンテキストを適用できるようになりました。

セキュリティ属性は、ビジネスへの影響（構造化された事前定義済み選択肢を含む）、アプリケーション、事業部門、インターネット露出、場所などのカテゴリで構成されています。あるいは、独自の属性カテゴリを作成し、それらのカテゴリ内でラベルを定義することもできます。

これらの属性をプロジェクト全体に適用することで、リスクの状況と組織のコンテキストに基づいてアクションが必要なセキュリティインベントリ内のどのプロジェクトをより迅速に検索、フィルタリング、特定できるようになります。できるようになりました:

- ミッションクリティカルであり、より良いスキャンカバレッジを必要とするプロジェクトを特定します。
- アプリケーションまたは事業部門別にスキャンカバレッジをレビューします。
- あなたのプロジェクトに適用された属性に基づいて検索およびフィルタリングします。
- 公開アクセス可能/公開されているアプリケーションにコントリビュートするプロジェクトを迅速に特定します。

### マージリクエスト承認ポリシーをバイパスするための例外 {#exceptions-to-bypass-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/18114)

{{< /details >}}

組織は、重大な状況が発生した場合にマージリクエスト承認ポリシーをバイパスできる特定のユーザー、グループ、ロール、またはカスタムロールを指定できるようになりました。この機能により、緊急対応に柔軟性を提供しつつ、包括的な監査証跡とガバナンス管理を維持できます。

**Emergency bypass with accountability**: 指定されたユーザーは、重大なインシデント、セキュリティホットフィックス、または緊急の本番環境イシュー中に承認要件をバイパスすることができます。緊急事態が発生した場合、承認された担当者はシステムが詳細な正当化と監査情報をコンプライアンスレビューのために記録する間、すぐに変更をマージまたはプッシュできます。

**主な機能は次のとおりです:**

- **Documented bypass process**: 承認されたユーザーがポリシーバイパスを実行する場合、直感的なモーダルインターフェースを使用して詳細な理由を提供する必要があり、すべての例外がコンテキストとともに適切に文書化されることを保証します。
- **Comprehensive audit integration**: すべてのバイパスは、ユーザーID、ポリシーコンテキスト、理由、およびタイムスタンプを含む詳細な監査イベントを生成し、例外使用パターンへの完全な可視性を提供します。
- **Flexible configuration**: YAMLまたはUI設定を使用してポリシーの例外権限を定義し、個々のユーザー、GitLabグループ、標準ロール、およびカスタムロールをサポートします。
- **Git-based push exceptions**: 事前承認されたポリシー例外を持つユーザーは、プッシュバイパスオプション`security_policy.bypass_reason`を実行する際に直接プッシュできます。

この機能により、緊急時にセキュリティポリシーを完全に無効にする必要がなくなり、組織のガバナンスと監査要件を維持しながら、緊急の変更に対する制御されたパスを提供します。

### アカウント継承の受益者を指定する {#designate-an-account-succession-beneficiary}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/account/account_succession.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/330669)

{{< /details >}}

病気や不在の場合にGitLabアカウントを管理するためのアカウント受益者権限を指定できるようになりました。アカウントにアクセスするには、受益者は適切な法的文書を提出する必要があります。この機能は、不正アクセスを防ぎながら、あなたの作業とプロジェクトの継続性を保証するのに役立ちます。

### グループオーナーはエンタープライズユーザーのプライマリメールアドレスを更新可能 {#group-owners-can-update-primary-emails-for-enterprise-users}

<!-- categories: System Access -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/enterprise_user/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/425837)

{{< /details >}}

グループオーナーは、自身のグループ内のエンタープライズユーザーのプライマリメールアドレスを更新できるようになりました。更新はユーザーAPIを通じて行うことができます。以前は、各エンタープライズユーザーが自身のメールアドレスを手動で更新する必要がありました。この変更により、エンタープライズユーザーを大規模にスケール管理することが容易になります。

### GitLab Runner 18.6 {#gitlab-runner-186}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.6もリリースします！GitLab Runnerは、CI/CDジョブを実行し、その結果をGitLabインスタンスに送信する、拡張性の高いビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [最小限のジョブ確認APIを実装](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/39013)

#### バグ修正 {#bug-fixes}

- [GitLab RunnerがDockerイメージプラットフォームオプションの変数を展開しない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38488)
- [ヘルパーサイドカーコンテナが別のS3バケットからキャッシュをアップロードできない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37879)
- [自動的にキャンセルされたジョブが実行を継続し、失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37878)
- [生成されたPowerShellスクリプトのUTF8 BOMが欠落しているため、文字Äを含むマージリクエストのタイトルを使用してリモートコード実行が可能になる](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36060)
- [Kubernetes executorを使用した場合のKubernetes APIサーバーリクエストの断続的な失敗](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30109)
- [Kubernetes executorを使用している場合、大きなコミットメッセージを持つジョブが失敗する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26624)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-6-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-6-stable/CHANGELOG.md).md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.6)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.6)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.6)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
