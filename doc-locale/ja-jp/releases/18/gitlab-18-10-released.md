---
stage: Release Notes
group: Monthly Release
date: 2026-03-19
title: "GitLab 18.10 リリースノート"
description: "GitLab 18.10がリリースされました。GitLab Duo Agent PlatformによるSAST誤検出判定機能を搭載しています。"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2026年3月19日、GitLab 18.10が以下の機能とともにリリースされました。

また、今月の注目コントリビューターをはじめ、すべてのコントリビューターの皆様に感謝申し上げます。

## 今月の注目コントリビューター: Harshith Sudar

Harshithは現在レベル3のコントリビューターで、トリアージの自動化やコントリビューター表彰から[GitLab Duo](https://about.gitlab.com/gitlab-duo/)の使用状況インサイトまで、コミュニティツールと分析の改善に多大な貢献をしています。

Harshithの貢献を最初に認めたのは、GitLabのDevRel EngineeringでFullstack Engineerを務める[Lee Tickett](https://gitlab.com/leetickett-gitlab)氏で、彼を推薦しました。Harshithの取り組みは、自動化の改善やコントリビューター向けエクスペリエンスの向上を通じて、コントリビューターを裏側でサポートする仕組みを強化しています。たとえば、[triage-opsの`IssueSummary`プロセッサーを複数プロジェクトに対応するよう更新](https://gitlab.com/gitlab-org/quality/triage-ops/-/merge_requests/3589)することでトリアージ自動化を拡張し、[contributors.gitlab.com](https://contributors.gitlab.com)を含む多くのコミュニティプロジェクトを継続的に要約・可視化しやすくしました。また、[新しい「コンテンツを追加」ボタンとフロー](https://gitlab.com/gitlab-org/developer-relations/contributor-success/contributors-gitlab-com/-/merge_requests/1250)を通じてコミュニティ作成コンテンツの認知にも貢献しており、コントリビューターがブログ記事、動画、その他のコンテンツをプロフィールから直接登録して報酬を受け取れるようになりました。

Harshithはまた、分析機能やGitLab Duoの使用状況インサイトにも貢献しています。主な成果として、[GitLab Duoの使用量計算方法の改善](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207511)、[180日間のデフォルト設定を削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218870)することによるAIの経時的な影響の探索改善、[DORAメトリクスの日付範囲定数の統合](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216715)、さらに[バリューストリーム分析のカスタムステージラベルピッカーへの無限スクロール追加](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207796)などのスケールでの分析強化が挙げられます。これらの変更により、チームは実際のプロジェクトにおけるGitLabの活用状況をより深く理解できるようになります。

本人のコメントを紹介します。

> 「コントリビュートしながら特に楽しんでいるのは、コミュニティ内でアイデアが丁寧に議論される点です。[MR !1288](https://gitlab.com/gitlab-org/developer-relations/contributor-success/contributors-gitlab-com/-/merge_requests/1288)をめぐる議論のように、提案が協力的に検討されていく様子は非常に励みになり、素晴らしい学びの機会となっています。
> このコミュニティの一員であることをとても嬉しく思っており、今後もさらに多くの貢献をしていきたいと思っています。」

GitLabのコードベースとコントリビューターエクスペリエンスの向上に継続的に取り組んでいただいているHarshithに感謝します！

Harshithとつながり、彼の貢献についてさらに詳しく知りたい方は、Harshithの[GitLabプロフィール](https://gitlab.com/official.harshith1)と[LinkedInプロフィール](https://www.linkedin.com/in/harshith-s-a44169282/)をご覧ください。

## 主要機能

### GitLab Duo Agent PlatformによるSAST誤検出検知

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/false_positive_detection.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/19789)

{{< /details >}}

GitLab 18.7でベータ版として初めて導入されたSAST誤検出検知が、GitLab 18.10で一般公開されました。

セキュリティスキャンが実行されると、GitLab Duo Agent Platformが重大度「Critical」および「High」のSAST脆弱性をそれぞれ分析し、誤検出の可能性を判定します。
評価結果は脆弱性レポートに直接表示されるため、チームは不確実性ではなく確信を持ってトリアージを行うために必要なコンテキストを得られます。

主な機能は以下のとおりです。

- 自動分析: 誤検出検知は、手動操作なしにセキュリティスキャンのたびに自動的に実行されます。
- 手動オプション: ユーザーは脆弱性詳細ページで個々の脆弱性に対してオンデマンドで誤検出検知を手動実行できます。
- 高影響度の検出結果に集中: 重大度「Critical」および「High」のSAST脆弱性に分析を絞ることで、最も重要な箇所のノイズを削減します。
- コンテキストを考慮したAI推論: 各評価では、コードコンテキスト、データフロー、静的解析に固有の脆弱性特性を考慮した上で、検出結果が誤検出である可能性とその理由を説明します。
- シームレスなワークフロー統合: 結果は既存の重大度、ステータス、修正情報と並んで脆弱性レポートに直接表示されます。既存のワークフローへの変更は不要です。

この機能は、GitLab Duo Agent Platformをご利用のUltimateのお客様が利用できます。グループまたはプロジェクトの設定で機能を有効にする必要があります。
[イシュー583697](https://gitlab.com/gitlab-org/gitlab/-/issues/583697)でフィードバックをお待ちしています。

### GitLab.comのFreeプランでGitLabクレジットを購入

<!-- categories: Subscription Management -->

{{< details >}}

- プラン: Free
- 提供形態: GitLab.com
- アドオン: GitLab Credits
- リンク: [ドキュメント](../../subscriptions/gitlab_credits.md#for-the-free-tier) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20165)

{{< /details >}}

GitLab.comのFreeプランのグループオーナーは、GitLabクレジットを使ってAIを利用できるようになりました。月間クレジット量を購入し、年間契約を結ぶことで、[GitLab Duo Agent Platformのエージェントとフロー](../../subscriptions/gitlab_credits.md#for-the-free-tier)にアクセスできます。クレジットは毎月自動的に更新されるため、チームは常に必要なリソースを確保し、より速く、よりスマートに開発できます。

主なポイント:

- **使用量ベースの料金**: ベースプランのサブスクリプションなしで月間クレジットコミットメントを購入できます。
- **セルフサービス購入**: GitLabの購入フローからクレジットを購入できます。
- **シームレスなアップグレードパス**: 後でPremiumまたはUltimateにアップグレードした場合、クレジットコミットメントは引き継がれます。
- **消費量の追跡**: GitLabクレジットダッシュボードでクレジットの使用状況を監視できます。

この[購入オプション](../../subscriptions/gitlab_credits.md#buy-gitlab-credits)は現在、GitLab.comの無料トップレベルグループのみで利用可能です。

### パスキーで安全にサインイン

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../auth/passkeys.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/10897)

{{< /details >}}

GitLabはパスワードレスサインインおよびフィッシング耐性のある2要素認証（2FA）方式としてパスキーをサポートするようになりました。パスキーは公開鍵暗号方式と生体認証（指紋、顔認証）またはデバイスPINを使用して、アカウントに安全にアクセスします。

パスキーには以下のメリットがあります。

- **パスワードレスの利便性**: パスワードを覚える代わりに、デバイスの生体認証またはPINでサインインできます。
- **マルチデバイス対応**: デスクトップブラウザ、モバイルデバイス（iOS 16以降、Android 9以降）、FIDO2/WebAuthn対応のハードウェアセキュリティキーでパスキーを使用できます。
- **フィッシング耐性のあるセキュリティ**: 秘密鍵はデバイスから外に出ることはありません。GitLabは公開鍵のみを保存するため、GitLabのサーバーが侵害された場合でもアカウントを保護します。
- **自動2FA統合**: 2FAが有効なアカウントでは、パスキーがデフォルトの2FA方式として利用可能になります。

開始するには、アカウント設定でパスキーを追加してください。イシュー[366758](https://gitlab.com/gitlab-org/gitlab/-/work_items/[366758](https://gitlab.com/gitlab-org/gitlab/-/work_items/366758))でご質問やフィードバックをお待ちしています。

### 作業アイテムリストと保存済みビューの導入

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/work_items/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/17530)

{{< /details >}}

GitLabのプランニングエクスペリエンスが、作業アイテムリストと保存済みビューによって大幅に強化されます。
長年要望されていた2つの機能が統合されます。

- 作業アイテムリストは、エピック、イシュー、その他の作業アイテムを単一の統合リストにまとめ、異なる作業アイテムタイプごとに別々のページを切り替える必要をなくします。これにより、プランニングオブジェクト間の関係を把握しやすくなります。
- 保存済みビューでは、フィルター、並び順、表示オプションを含むカスタマイズされたリスト設定を作成・保存できます。これにより、定期的な確認作業が効率化され、チーム全体で統一された作業の閲覧方法をサポートします。

これはGitLabの作業アイテムの取り組みにおける次のステップであり、GitLabのプランニングツール全体で一貫性を提供し、新しい機能を解放するための統合アーキテクチャです。

[イシュー590689](https://gitlab.com/gitlab-org/gitlab/-/work_items/590689)でご意見やフィードバックをお寄せください。

### カスタムエージェントがMCPを使用して外部データにアクセス可能に

<!-- categories: AI Catalog -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/gitlab_duo/model_context_protocol/ai_catalog_mcp_servers.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/590708)

{{< /details >}}

AIカタログのカスタムエージェントを、GitLabを離れることなくModel Context Protocol（MCP）を通じて外部データソースやツールに接続できるようになりました。

この機能は実験的機能です。[イシュー593219](https://gitlab.com/gitlab-org/gitlab/-/work_items/593219)でフィードバックをお寄せください。

### 正規表現によるマージリクエストタイトルの命名規則の適用

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/project/merge_requests/title_validation.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20108)

{{< /details >}}

構造化された命名規則に依存するチームにとって、マージリクエストのタイトルを一貫させることは重要です。Conventional Commitsフォーマットに従う場合でも、内部トラッキングシステムへのリンクを含める場合でも同様です。以前は、これらの規則を適用するために外部ツールやカスタムCI/CDパイプラインジョブが必要でしたが、このアプローチには重大な欠点がありました。パイプライン実行後にマージリクエストのタイトルが変更された場合、再検証が行われず、非準拠のタイトルのままMRがマージされる可能性がありました。

プロジェクト設定でマージリクエストに必須のタイトル正規表現を設定できるようになりました。設定すると、GitLabはマージリクエストのタイトルをマージ可能性チェックとしてパターンに対して評価し、タイトルが最後に変更された時期に関わらず、タイトルが準拠するまでマージをブロックします。

設定するには、プロジェクトの**設定 > マージリクエスト**に移動し、**マージリクエストのタイトルは正規表現に一致する必要があります**フィールドに正規表現パターンを入力してください。

既存のマージリクエストワークフローは引き続き従来どおり機能します。このチェックは、タイトル正規表現を明示的に設定したプロジェクトにのみ適用されます。

### AIによるシークレット誤検出検知（ベータ版）

<!-- categories: Vulnerability Management, Secret Detection -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/secret_false_positive_detection.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20152)

{{< /details >}}

セキュリティチームは、誤検出であることが判明するシークレット検出の検出結果の調査に多くの時間を費やしています。たとえば、テスト用の認証情報、サンプル値、実際のシークレットとして誤ってフラグが立てられたプレースホルダートークンなどです。
誤検出はアラート疲れを引き起こし、スキャン結果への信頼を損ない、本当のセキュリティリスクから注意をそらします。

GitLab 18.10では、本当に重要なシークレットに集中するためのAI搭載シークレット誤検出検知（ベータ版）が導入されました。
セキュリティスキャンが実行されると、GitLab Duoが重大度**Critical**および**High**のシークレット検出脆弱性をそれぞれ自動的に分析し、誤検出かどうかを判定します。

AI評価結果は脆弱性レポートに直接表示されるため、セキュリティエンジニアはより迅速かつ確信を持ってトリアージの判断を下せます。

主な機能は以下のとおりです。

- 自動分析: 誤検出検知は、手動トリガーなしにセキュリティスキャンのたびに自動的に実行されます。
- 手動トリガーオプション: 脆弱性詳細ページで個々の脆弱性に対してオンデマンドで誤検出検知を手動トリガーできます。
- 高影響度の検出結果に集中: 重大度**Critical**および**High**の脆弱性に絞ることで、シグナル対ノイズ比を最大限に改善します。
- コンテキストを考慮したAI推論: 各評価には、コードコンテキストと脆弱性特性に基づいて、検出結果が真陽性である可能性とその理由の説明が含まれます。
- 信頼スコア: 各検出にはモデルの確信度に基づいてチームがレビューの優先順位を付けるための信頼スコアが含まれます。
- シームレスなワークフロー統合: 結果は既存の重大度、ステータス、修正情報と並んで脆弱性レポートに直接表示されます。

この機能はUltimateのお客様向けの無料ベータ版として提供されており、グループまたはプロジェクトの設定で有効にする必要があります。
[イシュー592861](https://gitlab.com/gitlab-org/gitlab/-/work_items/592861)でフィードバックをお寄せください。

### CI/CDジョブでのランタイム入力の使用

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../ci/jobs/job_inputs.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17833)

{{< /details >}}

動的なジョブ設定にCI/CD変数を使用することは困難な場合があります。変数は管理が難しい複雑なオーバーライド階層に従っており、さまざまなユースケースには使用できません。

`inputs`を使用してジョブレベルで明示的な型付き入力を定義できるようになりました。ジョブ入力を使用して、ジョブが実行時に受け入れる値を定義・制御できます。ジョブ入力では以下が利用できます。

- 型安全性（文字列、数値、ブール値、配列）。
- 静的または既存の変数を参照できるデフォルト値。
- 使用可能な値の厳密なリストを定義するオプション。
- 入力値を検証するための正規表現サポート。

ジョブ入力はユーザーの操作なしにデフォルト値を使用できますが、ジョブの再試行時や手動ジョブの実行時に値を変更できます。

## Agentic Core

### グループおよびインスタンスのコード検索向けGitLab Blob Search

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/tools.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/593221)

{{< /details >}}

[`[gitlab_blob_search](../../user/duo_agent_platform/agents/tools.md)`](../../user/duo_agent_platform/agents/tools.md)ツールにより、GitLab AIエージェントが以下のコード検索を実行できるようになりました。

- グループ内のすべてのプロジェクトを横断した検索。
- インスタンス上のアクセス可能なすべてのプロジェクトを横断した検索。

以前は、blob検索は単一プロジェクトに限定されているか、明示的なプロジェクトIDの指定が必要でした。この変更により、AIを活用したワークフローが複数の関連プロジェクトに分散したコードを発見・再利用しやすくなります。

### パイプライン管理向けGitLab MCPサーバーツール

<!-- categories: MCP Server -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/gitlab_duo/model_context_protocol/mcp_server_tools.md#manage_pipeline) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/583826)

{{< /details >}}

新しい`manage_pipeline`ツールを使用して、GitLabプロジェクトのCI/CDパイプラインを管理できるようになりました。
このGitLab MCPサーバーツールにより、AIエージェントが1回の呼び出しでパイプラインのメタデータの作成、キャンセル、再試行、削除、更新を行えます。
このツールにより、パイプラインワークフローを自動化するために複数のステップを組み合わせる必要がなくなります。

他のGitLab MCPサーバーツールについてのご要望は、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/566375)でお知らせください。

### プロジェクトのメンテナーがカスタムエージェントとフローを有効化可能に

<!-- categories: AI Catalog -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/duo_agent_platform/flows/custom.md#enable-a-flow) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/590573)

{{< /details >}}

以前は、AIカタログからAIエージェントとフローを有効にするにはトップレベルグループの権限が必要でした。

検索レベルまたはプロジェクトレベルでAIカタログを閲覧する際、プロジェクトのメンテナーがプロジェクト内でエージェントとフローを直接有効にできるようになりました。

### プロジェクトのリモートフローに対するネットワークアクセス制御の設定

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/duo_agent_platform/environment_sandbox.md#configure-a-network-policy) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/593560)

{{< /details >}}

プロジェクトでGitLab Runnerを使用するフローに対して[ネットワークアクセス制御](../../user/duo_agent_platform/environment_sandbox.md)を設定できるようになりました。

これにより、ネットワーク宛先の制御を維持しながら、安全な外部インテグレーションが実現します。また、プロジェクトのメンテナーは、セキュリティ境界を適用しながら、必要なAPI接続、MCPサーバー、サードパーティサービスを許可する柔軟性を得られます。

[ネットワークアクセス制御](../../user/duo_agent_platform/environment_sandbox.md)は`agent-config.yml`の`network_policy`セクションで設定します。`agent-config.yml`はブランチ保護ルールとMR承認ワークフローによって保護されています。

### GitLab Duo Agent Platform向けセルフホストVertex AI

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_llm_serving_platforms.md#configure-authentication-with-gemini-enterprise-agent-platform) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/591604)

{{< /details >}}

Vertex AIがGitLab Duo Agent Platform Self-Hosted内でサポートされるLLMプラットフォームになりました。

お客様はVertex AI上でホストされているAnthropicモデルをGitLab Duo Agent Platformの機能で使用するよう設定できるようになりました。

### ユーザーがプロジェクトから直接エージェントとフローを有効化可能に

<!-- categories: AI Catalog -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/custom.md#enable-an-agent) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/588012)

{{< /details >}}

メンテナーとオーナーは、現在のコンテキストから離れることなく、プロジェクトまたは検索ページから直接エージェントとフローを有効にできるようになりました。

トップレベルグループのオーナーは、グループと、エージェントおよびフローを有効にしたい特定のプロジェクトを選択することもでき、ワークフローのセットアップが効率化されます。

### IDEおよびCI/CDパイプラインでのAgent Skillsのサポート

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/customize/agent_skills.md) | [関連イシュー](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1984)

{{< /details >}}

GitLab Duo Agent Platformが、AIエージェントに新しい機能と専門知識を与えるための新興標準である[Agent Skills仕様](https://agentskills.io/specification)をサポートするようになりました。

プロジェクトのワークスペースレベルでAgent Skillsを定義することで、特定のフレームワークでのテスト作成など、特定のタスクに対してエージェントに専門的な知識とワークフローを与えられます。エージェントは一致するタスクに遭遇すると、関連するスキルを自動的に検出して読み込みます。

名前、ファイルパス、またはカスタムスラッシュコマンドでスキルを手動でトリガーすることもできます。
Agent SkillsはIDEのフローとAgentic Chat、およびCI/CDパイプラインで実行されるフローでアクセスできます。また、仕様をサポートする他のAIツールとも連携します。

## スケールとデプロイ

### クレジット使用データをCSVとしてダウンロード

<!-- categories: Consumables Cost Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../subscriptions/gitlab_credits.md#export-usage-data) | [関連イシュー](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/14504)

{{< /details >}}

請求管理者は、カスタマーポータルのGitLabクレジットダッシュボードからクレジット使用データをCSVファイルとして直接ダウンロードできるようになりました。

エクスポートには、コミット、免除、トライアル、オンデマンド、含まれるクレジットの使用を含む、現在の請求月のクレジット消費量の日次・アクション別内訳が含まれます。

財務チームと運用チームは、このデータを使用して、手動のデータ収集やサポートリクエストなしに、Excel、Google Sheets、またはBIツールでコスト配分、チャージバックレポート、使用状況分析を実行できます。

### クレジット使用量をGitLab Duo Agent Platformセッションにリンク

<!-- categories: Consumables Cost Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../subscriptions/gitlab_credits.md#gitlab-credits-dashboard) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/579139)

{{< /details >}}

GitLabクレジットダッシュボードで、クレジット消費量がそれを生成したGitLab Duo Agent Platformセッションに直接リンクされるようになりました。

ユーザー別ドリルダウンビューで、Agent Platformの使用行（**Agentic Chat**や**Foundational Agents**など）の**アクション**列がクリック可能なハイパーリンクになり、対応するセッション詳細に移動できます。

このリンクにより、請求からAIセッションの動作までの直接的な監査証跡が提供されるため、管理者は別々のシステム間でタイムスタンプを手動で照合することなく、クレジット使用量の調査、サポートのエスカレーション、コンプライアンスレビューを行えます。

### GitLabクレジットダッシュボードでユーザーを並び替え

<!-- categories: Consumables Cost Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../subscriptions/gitlab_credits.md#view-the-gitlab-credits-dashboard) | [関連イシュー](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/15608)

{{< /details >}}

エンタープライズ管理者は、GitLabクレジットダッシュボードの**ユーザー別使用量**テーブルを、使用クレジット合計またはユーザー名で並び替えられるようになりました。

デフォルトの並び順は使用クレジット合計（多い順）であるため、スクロールせずにトップの消費者がすぐに確認できます。

この表示により、数千人のGitLab Duoユーザーを管理する管理者は、コスト配分、チャージバックレポート、ライセンス利用状況の監査のために高使用量のユーザーをすばやく特定できます。

### Exploreのプロジェクト向け新しいナビゲーションエクスペリエンス

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/project/working_with_projects.md#explore-all-projects-on-an-instance) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/13786)

{{< /details >}}

**Explore**のプロジェクトページを整理し、時間の経過とともに蓄積された冗長なオプションを削除しました。
シンプルになったインターフェースは、2つのコアビューに焦点を当てています。

- **アクティブ**タブ: 最近のアクティビティと進行中の開発があるプロジェクトを発見できます。
- **非アクティブ**タブ: アーカイブされたプロジェクトや削除予定のプロジェクトにアクセスできます。

いくつかの冗長なタブを削除しました。

- **最もスター付き**のプロジェクトは、**アクティブ**または**非アクティブ**タブをスター数で並び替えることで確認できます。
- **すべて**のプロジェクトは、**アクティブ**と**非アクティブ**の両方のタブを表示することで利用できます。
- **トレンド**タブは、機能の制限と使用率の低さにより、GitLab 19.0で完全に削除される予定です。

すっきりしたデザインは、視覚的な一貫性のために他のプロジェクトリストと統一されています。より論理的な整理と柔軟な並び替えオプションにより、同じコンテンツすべてに引き続きアクセスできます。

## 統合DevOpsとセキュリティ

### Java Gradleビルドファイルに対するSBOMサポートを使用した依存関係スキャン

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#manifest-fallback) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/588788)

{{< /details >}}

SBOMを使用したGitLabの依存関係スキャンが、JavaのGradleビルドファイル（`build.gradle`および`build.gradle.kts`）のスキャンをサポートするようになりました。

以前は、Gradleを使用するJavaプロジェクトの依存関係スキャンにはロックファイルが必要でした。
ロックファイルが利用できない場合、アナライザーは自動的に`build.gradle`および`build.gradle.kts`ファイルへのフォールバックを行い、脆弱性分析のために直接依存関係のみを抽出してレポートします。
この改善により、Gradleを使用するJavaプロジェクトがロックファイルなしで依存関係スキャンを有効にしやすくなります。

マニフェストフォールバックを有効にするには、CI/CD変数`DS_ENABLE_MANIFEST_FALLBACK`を`"true"`に設定してください。

### 依存関係スキャンのSBOMベーススキャンをSelf-Managedに拡張

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/546429)

{{< /details >}}

GitLab 18.10では、新しいSBOMベースの依存関係スキャン機能の限定公開ステータスをSelf-Managedインスタンスに拡張します。

この機能はGitLab 18.5でGitLab.comのみの限定公開として初めてリリースされ、機能フラグ`dependency_scanning_sbom_scan_api`の背後でデフォルトでは無効になっていました。

追加の改善と修正により、新しいSBOMスキャン内部APIを確実に使用し、この機能フラグをデフォルトで有効にする自信が得られました。
この内部APIにより、依存関係スキャンアナライザーがすべてのコンポーネントの脆弱性を含む依存関係スキャンレポートを生成できます。
CI/CDパイプライン完了後にSBOMレポートを処理していた以前の動作（ベータ版）とは異なり、[この改善されたプロセス](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#how-it-scans-an-application)はCI/CDジョブ中に即座にスキャン結果を生成し、カスタムワークフロー向けの脆弱性データへの即時アクセスを提供します。

問題が発生したSelf-Managedのお客様は、`dependency_scanning_sbom_scan_api`機能フラグを無効にできます。アナライザーは以前の動作にフォールバックします。

この機能を使用するには、v2依存関係スキャンテンプレート`Jobs/Dependency-Scanning.v2.gitlab-ci.yml`をインポートしてください。

この機能に関するフィードバックをお待ちしています。ご質問、コメント、またはチームとのやり取りをご希望の場合は、この[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523458)でご連絡ください。

### Pubパッケージマネージャーを使用するDart/Flutterプロジェクトのライセンススキャンサポート

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#data-sources) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/18351)

{{< /details >}}

GitLabが`pub`パッケージマネージャーを使用するDartおよびFlutterプロジェクトのライセンススキャンをサポートするようになりました。
以前は、DartまたはFlutterで開発するチームはGitLab内でオープンソース依存関係のライセンスを直接確認できず、ライセンスポリシー要件を持つ組織にとってコンプライアンスの盲点が生じていました。

ライセンスデータは公式DartパッケージリポジトリであるPub.devから直接取得され、他のサポートされているエコシステムと並んで結果が表示されます。
Dart/Flutterの依存関係スキャンと脆弱性検出はすでにサポートされていました。

### Conan 2.0パッケージレジストリサポート（ベータ版）

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/packages/conan_2_repository/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/585819)

{{< /details >}}

Conanをパッケージマネージャーとして使用するCおよびC++開発チームは、GitLabでのレジストリサポートを長年要望していました。以前は、ConanパッケージレジストリはExperimentalであり、Conan 1.xクライアントのみをサポートしていたため、最新のConan 2.0ツールチェーンに移行したチームの採用が制限されていました。

Conanパッケージレジストリがコナン2.0をサポートし、ExperimentalからBetaに昇格しました。このリリースには、完全なv2 API互換性、レシピリビジョンサポート、改善された検索機能、`--force`フラグを含むアップロードポリシーの適切な処理が含まれています。チームは標準のConanクライアントワークフローを使用してGitLabから直接Conan 2.0パッケージを公開・インストールでき、JFrog Artifactoryなどの外部アーティファクト管理ソリューションの必要性が減ります。

このアップデートにより、CおよびC++の依存関係を管理するプラットフォームエンジニアリングチームは、ソースコード、CI/CDパイプライン、セキュリティスキャンと並んでGitLab内でパッケージ管理を統合できます。Conanレジストリはプロジェクトレベルとインスタンスレベルの両方のエンドポイントをサポートし、認証にはパーソナルアクセストークン、デプロイトークン、CI/CDジョブトークンが使用できます。

一般公開に向けた取り組みの中でフィードバックをお待ちしています。[エピック](https://gitlab.com/groups/gitlab-org/-/work_items/6816)でご意見をお寄せください。

### 専用UIによるコンテナ仮想レジストリの管理（ベータ版）

<!-- categories: Virtual Registry -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/packages/virtual_registry/container/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/19283)

{{< /details >}}

コンテナ仮想レジストリが前のマイルストーンでベータ版としてリリースされた際、プラットフォームエンジニアはDocker Hub、Harbor、Quayなど複数のアップストリームコンテナレジストリを単一のプルエンドポイントの背後に集約できました。しかし、すべての設定には直接APIコールが必要であり、チームはレジストリの作成・管理、アップストリームの設定、変更の処理のためにスクリプトや手動のcurlコマンドを維持する必要がありました。これにより運用上のオーバーヘッドが増加し、APIを直接操作することに慣れていないユーザーにとって機能が利用しにくくなっていました。

コンテナ仮想レジストリをGitLab UIから直接作成・管理できるようになりました。グループレベルのコンテナレジストリページから、新しい仮想レジストリの作成、認証情報を含むアップストリームソースの設定、既存の設定の編集、不要になったレジストリの削除をすべてGitLabを離れることなく、APIコールを1つも書かずに行えます。UIは既存のコンテナレジストリエクスペリエンスとシームレスに統合され、仮想レジストリがグループのアーティファクト管理ワークフローのファーストクラスの一部となります。

この機能はベータ版です。フィードバックは[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/589630)にコメントしてください。

### GitLab Helmチャートレジストリが一般公開

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/packages/helm_repository/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/573715)

{{< /details >}}

HelmでKubernetesアプリケーションのデプロイを管理するチームは、本番ワークロードにGitLab Helmチャートレジストリを使用できるようになりました。以前はベータ版でしたが、主要なアーキテクチャと信頼性の問題が解決され、一般公開されました。

GAへの道のりには、`index.yaml`エンドポイントが1,000チャート以上を返せないハード制限の解消、新しく公開されたチャートバージョンがインデックスに表示されない原因となっていたバックグラウンドインデックス作成のバグ修正、完全なAppSecセキュリティレビューの完了、GitLab GeoでSelf-Managedのお客様の高可用性を確保するためのHelmメタデータキャッシュのGeoレプリケーションサポートの追加が含まれます。

プラットフォームおよびDevOpsチームは、プロジェクトレベルのエンドポイントと、パーソナルアクセストークン、デプロイトークン、CI/CDジョブトークンを使用した認証をサポートする標準のHelmクライアントワークフローを使用して、GitLabから直接Helmチャートを公開・インストールできます。これにより、チャートをそれに依存するソースコード、パイプライン、セキュリティスキャンと並べて管理できます。

### MarkdownテーブルでのタスクアイテムのサポートMarkdown

<!-- categories: Markdown -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/markdown.md#task-lists-in-tables) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/21506)

{{< /details >}}

Markdownテーブルのセル内でタスクアイテムのチェックボックス構文を直接使用できるようになりました。

以前は、これを実現するには生のHTMLとMarkdownの組み合わせが必要で、扱いにくく保守が困難でした。

この改善により、イシュー、エピック、その他のコンテンツの構造化されたテーブルレイアウト内でタスクの完了状況を直接追跡しやすくなります。

### セキュリティ設定プロファイルでのパイプラインシークレット検出

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/configuration/security_configuration_profiles.md)

{{< /details >}}

GitLab 18.9では、プッシュ保護から始まる**シークレット検出 - デフォルト**プロファイルとともにセキュリティ設定プロファイルを導入しました。このプロファイルを使用することで、単一のCI/CD設定ファイルに触れることなく、数百のプロジェクトに標準化されたシークレットスキャンを適用できます。

**シークレット検出 - デフォルト**プロファイルがパイプラインベースのスキャンもカバーするようになり、開発ワークフロー全体にわたるシークレット検出の統合されたコントロールサーフェスを提供します。

プロファイルは3つのスキャントリガーを有効にします。

- **プッシュ保護**: すべてのGitプッシュイベントをスキャンし、シークレットが検出されたプッシュをブロックすることで、シークレットがコードベースに入ることを防ぎます。
- **マージリクエストパイプライン**: オープンなマージリクエストがあるブランチに新しいコミットがプッシュされるたびに自動的にスキャンを実行します。結果にはマージリクエストによって導入された新しい脆弱性のみが含まれます。
- **ブランチパイプライン（デフォルトのみ）**: 変更がデフォルトブランチにマージまたはプッシュされたときに自動的に実行され、デフォルトブランチのシークレット検出状況の完全なビューを提供します。

プロファイルの適用にYAML設定は不要です。プロファイルはグループに適用してグループ内のすべてのプロジェクトにカバレッジを伝播させることも、より細かい制御のために個々のプロジェクトに適用することもできます。

### macOS Tahoe 26およびXcode 26ジョブイメージ

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/hosted_runners/macos.md) | [関連エピック](https://gitlab.com/groups/gitlab-com/gl-infra/-/work_items/1694)

{{< /details >}}

macOS Tahoe 26とXcode 26を使用して、最新世代のAppleデバイス向けアプリケーションを作成、テスト、デプロイできるようになりました。

[macOSのホスト型Runner](../../ci/runners/hosted_runners/macos.md)を使用することで、開発チームはGitLab CI/CDと統合されたセキュアなオンデマンドビルド環境でmacOSアプリケーションをより速くビルド・デプロイできます。

`.gitlab-ci.yml`ファイルで`macos-26-xcode-26`イメージを使用して今すぐお試しください。

### GitLab Runner 18.10

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.10もリリースします！
GitLab Runnerは、CI/CDジョブを実行してGitLabインスタンスに結果を送信する高スケーラブルなビルドエージェントです。
GitLab RunnerはGitLab CI/CD（GitLabに含まれるオープンソースの継続的インテグレーションサービス）と連携して動作します。

#### 新機能

- [k8s Runnerがビルドポッドのポッドレベルリソースを定義できるようにする](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39085)
- [すべてのRunnerプロジェクトのGoバージョンとパッケージを更新する自動化を追加](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39192)

#### バグ修正

- [RoleARNを使用したS3キャッシュが存在しないキャッシュに対して404ではなく403を返す](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39105)
- [ヘルパーイメージ`gitlab-runner-helper:x86_64-v16.11.1-nanoserver21H2`を使用すると`init-permissions`エラーが発生する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37872)
- [MacOS: LaunchAgent - M1アーキテクチャでサービスを初期化できない](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/28136)

すべての変更のリストはGitLab Runnerの[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-10-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-10-stable/CHANGELOG.md).md)にあります。

## 関連トピック

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.10)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.10)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.10)
- [非推奨と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
