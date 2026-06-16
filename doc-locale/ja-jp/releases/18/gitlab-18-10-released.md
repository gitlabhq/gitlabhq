---
stage: Release Notes
group: Monthly Release
date: 2026-03-19
title: "GitLab 18.10リリースノート"
description: "GitLab 18.10がSAST誤検出判定とGitLab Duo Agent Platformを搭載してリリース"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2026年3月19日、GitLab 18.10が以下の機能を搭載してリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Harshith Sudar {#this-months-notable-contributor-harshith-sudar}

Harshithは現在、レベル3のコントリビューターであり、トリアージの自動化やコントリビューターの認識から、[GitLab Duo](https://about.gitlab.com/gitlab-duo/)の利用インサイトまで、コミュニティのツールと分析を改善する影響力のあるコントリビュートをしてきました。

Harshithのコントリビュートは、GitLabのDevRel Engineeringのフルスタックエンジニアである[Lee Tickett](https://gitlab.com/leetickett-gitlab)が彼を推薦したことにより、最初に評価されました。彼の功績は、自動化とコントリビューター向けの体験を改善することで、舞台裏でコントリビューターをサポートする方法を強化しました。例えば、彼は[triage-opsの`IssueSummary`プロセッサを更新して複数のプロジェクトで動作するようにした](https://gitlab.com/gitlab-org/quality/triage-ops/-/merge_requests/3589)ことで、トリアージの自動化を展開し、[contributors.gitlab.com](https://contributors.gitlab.com)を含むより多くのコミュニティプロジェクトを一貫して要約し、可視化することを容易にしました。彼はまた、[新しい「コンテンツを追加」ボタンとフロー](https://gitlab.com/gitlab-org/developer-relations/contributor-success/contributors-gitlab-com/-/merge_requests/1250)を通じてコミュニティが作成したコンテンツの認識を助けました。これにより、コントリビューターは自身のプロフィールから直接ブログ記事、ビデオ、その他のコンテンツを記録し、報酬を得ることができます。

Harshithは、分析とGitLab Duoの利用インサイトにもコントリビュートしています。主なハイライトとしては、[GitLab Duoの利用状況の計算方法を洗練](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207511)したり、[180日間のデフォルトを削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218870)することでAIが時間の経過とともに与える影響をより深く調べられるように改善したり、[DORAメトリクスの期間定数を統合](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216715)したりしたこと、さらには[バリューストリーム分析カスタムステージラベルピッカーへの無限スクロールの追加など、分析機能をスケールアップしたことが挙げられます。](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207796)これらの変更により、チームは実際のプロジェクトでGitLabがどのように使用されているかをよりよく理解できるようになります。

彼自身の言葉で:

> 「コントリビュートする中で私が本当に楽しんできたことの1つは、アイデアがコミュニティ内でいかに思慮深く議論されるかということです。[MR !1288](https://gitlab.com/gitlab-org/developer-relations/contributor-success/contributors-gitlab-com/-/merge_requests/1288)に関するディスカッションのように、提案が協力して検討されるのを見るのは励みになります。これは素晴らしい学習体験となりました。このコミュニティの一員であることを本当に嬉しく思いますし、今後もさらに多くのコントリビュートができることを楽しみにしています。」

Harshithさん、GitLabのコードベースとコントリビューターの体験を改善するための継続的な作業に感謝します！

Harshithとつながり、彼のコントリビュートについてもっと知りたいですか？Harshithの[GitLab profile](https://gitlab.com/official.harshith1)と[LinkedIn profile](https://www.linkedin.com/in/harshith-s-a44169282/)をご覧ください。

## 主要な機能 {#primary-features}

### SAST誤検出判定とGitLab Duo Agent Platform {#sast-false-positive-detection-with-gitlab-duo-agent-platform}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/false_positive_detection.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/19789)

{{< /details >}}

GitLab 18.7でベータ版として初めて導入されたSAST誤検出判定が、GitLab 18.10で一般公開されました。

セキュリティスキャンが実行されると、GitLab Duo Agent Platformは、それぞれのクリティカルおよび高重大度のSAST脆弱性を分析し、それが誤検出である可能性を判断します。この評価は脆弱性レポートに直接表示され、チームは不確実性ではなく確信を持ってトリアージを行うために必要なコンテキストを得ることができます。

主な機能は次のとおりです:

- 自動分析: 誤検出判定は、手動での介入なしに各セキュリティスキャンの後に自動的に実行されます。
- 手動オプション: ユーザーは、オンデマンド分析のために、脆弱性詳細ページで個々の脆弱性に対して手動で誤検出判定を実行できます。
- 影響の大きい発見に焦点を当てる: 分析をクリティカルおよび高重大度のSAST脆弱性に限定することで、最も重要な場所でノイズを排除します。
- コンテキストAI推論: 各評価では、コードのコンテキスト、データフロー、および静的な解析に固有の脆弱性特性を考慮して、発見が誤検出である可能性とそうでない可能性を説明します。
- シームレスなワークフローインテグレーション: 結果は既存の重大度、ステータス、および修正情報とともに脆弱性レポートに直接表示され、既存のワークフローへの変更は必要ありません。

この機能は、GitLab Duo Agent Platformをご利用のUltimateのお客様にご利用いただけます。この機能は、グループまたはプロジェクトの設定で有効にする必要があります。[イシュー583697](https://gitlab.com/gitlab-org/gitlab/-/issues/583697)でのフィードバックをお待ちしております。

### GitLab.comのFreeティアでGitLabクレジットを購入 {#purchase-gitlab-credits-on-the-free-tier-on-gitlabcom}

<!-- categories: Subscription Management -->

{{< details >}}

- プラン: Free
- 提供形態: GitLab.com
- アドオン: GitLabクレジット
- リンク: [ドキュメント](../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20165)

{{< /details >}}

GitLab.comのFreeティアのグループオーナーは、GitLabクレジットを使用してAIをアンロックできるようになりました。月額のクレジット額を購入し、年間契約をコミットすることで、[GitLab Duo Agent Platformのエージェントとフロー](../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom)にアクセスできます。クレジットは毎月自動的に更新されるため、チームは常に迅速かつスマートにビルドするために必要なものを利用できます。

主なハイライト:

- **Usage-based pricing**: 基本プランのサブスクリプションを必要とせずに、月額のクレジットコミットメントを購入できます。
- **Self-service purchasing**: GitLabの購入フローを通じてクレジットを購入します。
- **Seamless upgrade path**: 後でPremiumまたはUltimateにアップグレードした場合でも、クレジットコミットメントは引き継がれます。
- **Consumption tracking**: GitLabクレジットのダッシュボードを通じてクレジット使用状況を監視します。

この[購入オプション](../../subscriptions/gitlab_credits.md#buy-gitlab-credits)は現在、無料のGitLab.comトップレベルグループでのみ利用可能です。

### パスキーで安全にサインイン {#sign-in-securely-with-passkeys}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../auth/passkeys.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/10897)

{{< /details >}}

GitLabは現在、パスワードなしのサインインと、フィッシング耐性のある2要素認証（2FA）方法としてパスキーをサポートしています。パスキーは、公開鍵暗号と生体認証（フィンガープリント、顔認識）またはデバイスのPINを使用して、アカウントに安全にアクセスします。

パスキーには以下の利点があります:

- **Passwordless convenience**: パスワードを記憶する代わりに、デバイスの生体認証またはPINでサインインします。
- **Multi-device support**: デスクトップブラウザ、モバイルデバイス（iOS 16以降、Android 9以降）、およびFIDO2/WebAuthn互換のハードウェアセキュリティキーでパスキーを使用できます。
- **Phishing-resistant security**: 秘密キーはデバイスから離れることはありません。GitLabは公開キーのみを保存するため、GitLabサーバーが侵害された場合でもアカウントを保護します。
- **Automatic 2FA integration**: 2FAが有効なアカウントの場合、パスキーがデフォルトの2FA方法として利用可能になります。

開始するには、アカウントの設定でパスキーを追加します。[イシュー366758](https://gitlab.com/gitlab-org/gitlab/-/work_items/[366758](https://gitlab.com/gitlab-org/gitlab/-/work_items/366758))でのご質問とフィードバックをお待ちしております。

### 作業アイテムリストと保存されたビューの紹介 {#introducing-the-work-items-list-and-saved-views}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/work_items/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/17530)

{{< /details >}}

GitLabのプランニング体験は、作業アイテムリストと保存されたビューによって大幅にアップグレードされ、長らく要望されていた2つの機能を統合します:

- 作業アイテムリストは、エピック、イシュー、およびその他の作業アイテムを単一の統合されたリストに結合し、異なる作業アイテムタイプごとに個別のページを切り替える必要をなくします。これにより、プランニングオブジェクト間の関係を理解しやすくなります。
- 保存されたビューを使用すると、フィルター、ソート順、表示オプションなどを含むカスタマイズされたリスト設定を作成および保存できます。これにより、ルーチンチェックがより効率的になり、チーム全体で作業を標準化して表示する方法がサポートされます。

これは、一貫性を提供し、GitLabプランニングツール全体で新しい機能をアンロックするように設計された統合アーキテクチャである、GitLab作業アイテムのジャーニーにおける次のステップです。

[イシュー590689](https://gitlab.com/gitlab-org/gitlab/-/work_items/590689)でご意見とフィードバックをお寄せください。

### カスタムエージェントはMCPを使用して外部データにアクセスできます {#custom-agents-can-use-mcp-to-access-external-data}

<!-- categories: AI Catalog -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/gitlab_duo/model_context_protocol/ai_catalog_mcp_servers.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/590708)

{{< /details >}}

AIカタログ内のカスタムエージェントを、GitLabを離れることなく、Model Context Protocol（MCP）を介して外部データソースとツールに接続できるようになりました。

この機能は実験です。[イシュー593219](https://gitlab.com/gitlab-org/gitlab/-/work_items/593219)でフィードバックを共有してください。

### マージリクエストのタイトル命名規則を正規表現で強制する {#enforce-merge-request-title-naming-conventions-with-regex}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/project/merge_requests/title_validation.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20108)

{{< /details >}}

一貫したマージリクエストのタイトルを維持することは、構造化された命名規則に依存するチームにとって重要です。それがConventional Commits形式に従うか、内部のトラッキングシステムにリンクするかどうかに関わらずです。以前は、チームはこれらの規則を強制するために外部のツールまたはカスタムCI/CDパイプラインジョブを必要としていましたが、このアプローチには重要なギャップがありました。パイプラインの実行後に誰かがマージリクエストのタイトルを変更した場合、再検証が行われず、MRは非準拠のタイトルでマージされる可能性がありました。

プロジェクトの設定で、マージリクエストに必須のタイトル正規表現を設定できるようになりました。設定されると、GitLabはマージリクエストのタイトルをマージ可能性チェックとしてパターンに対して評価し、最後にタイトルが変更された時期に関わらず、タイトルが準拠するように更新されるまでマージをブロックします。

これを設定するには、プロジェクトの**設定 > マージリクエスト**に移動し、**Merge request title must match regex**フィールドに正規表現パターンを入力します。

既存のマージリクエストワークフローは以前と同様に機能し続けます。このチェックは、タイトル正規表現を明示的に設定したプロジェクトにのみ適用されます。

### シークレット誤検出判定（AI搭載）(ベータ) {#secret-false-positive-detection-with-ai-beta}

<!-- categories: Vulnerability Management, Secret Detection -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Core、Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/secret_false_positive_detection.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20152)

{{< /details >}}

セキュリティチームは、誤検出であることが判明するシークレット検出の発見を調査するために多大な時間を費やしています。例えば、テスト認証情報、例値、およびプレースホルダートークンが、実際のシークレットとして誤ってフラグ付けされる場合があります。誤検出は、アラート疲労を生み出し、スキャン結果への信頼を損ない、真のセキュリティリスクから注意をそらします。

GitLab 18.10では、本当に重要なシークレットに焦点を当てるためのAI搭載シークレット誤検出判定（ベータ）が導入されました。セキュリティスキャンが実行されると、GitLab Duoは各**クリティカル**および**高**重大度のシークレット検出脆弱性を自動的に分析し、それが誤検出であるかどうかを判断します。

AI評価は脆弱性レポートに直接表示され、セキュリティエンジニアは迅速かつ自信を持ってトリアージを決定するための即時コンテキストを得られます。

主な機能は次のとおりです:

- 自動分析: 誤検出判定は、手動トリガーなしに各セキュリティスキャンの後に自動的に実行されます。
- 手動トリガーオプション: オンデマンド分析のために、脆弱性詳細ページで個々の脆弱性に対して手動で誤検出判定をトリガーできます。
- 影響の大きい発見に焦点を当てる: 信号対雑音比の改善を最大化するために、**クリティカル**および**高**重大度の脆弱性にスコープされます。
- コンテキストAI推論: 各評価には、コードのコンテキストと脆弱性特性に基づいて、その発見が真陽性である可能性とそうでない可能性を説明する説明が含まれています。
- 信頼度スコアリング: 各検出には、モデルの確実性に基づいてレビューを優先するのに役立つ信頼度スコアが含まれています。
- シームレスなワークフローインテグレーション: 結果は既存の重大度、ステータス、および修正情報とともに脆弱性レポートに直接表示されます。

この機能は、Ultimateのお客様向けの無料ベータ版として利用可能であり、グループまたはプロジェクトの設定で有効にする必要があります。[イシュー592861](https://gitlab.com/gitlab-org/gitlab/-/work_items/592861)でフィードバックをお寄せください。

### ランタイム入力をCI/CDジョブで使用する {#use-runtime-inputs-with-cicd-jobs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../ci/jobs/job_inputs.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17833)

{{< /details >}}

動的なジョブ設定にCI/CD変数を使用することは困難な場合があります。変数は、管理が困難な複雑なオーバーライド階層に従っており、さまざまなユースケースには使用できません。

これで、ジョブレベルで明示的な型付き入力を定義するために`inputs`を使用できます。ジョブインプットを使用して、ジョブがランタイムで受け入れる値を定義および制御します。ジョブインプットを使用すると、次の利点があります:

- 型安全性（文字列、数値、ブール値、配列）。
- 静的または既存の変数を参照できるデフォルト値。
- 使用する可能性のある値の厳密なリストを定義するオプション。
- 入力値を検証するための正規表現サポート。

ジョブインプットは、ユーザーの操作なしにデフォルト値を使用できますが、ジョブを再試行するか、手動ジョブを実行する際に値を変更できます。

## エージェント型コア {#agentic-core}

### グループおよびインスタンスコード検索のためのGitLab blob検索 {#gitlab-blob-search-for-group-and-instance-code-search}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/tools.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/593221)

{{< /details >}}

The [`[gitlab_blob_search](../../user/duo_agent_platform/agents/tools.md)`](../../user/duo_agent_platform/agents/tools.md)ツールは、GitLab AIエージェントがコードを検索できるようにします:

- グループ内のすべてのプロジェクトを横断します。
- インスタンス上のアクセス可能なすべてのプロジェクトを横断します。

以前は、blob検索は単一のプロジェクトに限定されていましたが、明示的なプロジェクトIDを指定する必要がありました。この変更により、AIを搭載したワークフローが、複数の関連プロジェクトに分散しているコードを発見して再利用することが容易になります。

### GitLab MCPサーバーツールによるパイプライン管理 {#gitlab-mcp-server-tool-for-pipeline-management}

<!-- categories: MCP Server -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/gitlab_duo/model_context_protocol/mcp_server_tools.md#manage_pipeline) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/583826)

{{< /details >}}

新しい`manage_pipeline`ツールを使用して、GitLabプロジェクトでCI/CDパイプラインを管理できるようになりました。このGitLab MCPサーバーツールを使用すると、AIエージェントは1回の呼び出しでパイプラインのメタデータを作成、キャンセル、再試行、削除、更新できます。このツールを使用すると、パイプラインワークフローを自動化するために複数のステップを組み合わせる必要がなくなります。

他のGitLab MCPサーバーツールをご覧になりたい場合は、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/566375)でお知らせください。

### プロジェクトメンテナーは、カスタムエージェントとフローを有効にできます {#project-maintainers-can-enable-custom-agents-and-flows}

<!-- categories: AI Catalog -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/duo_agent_platform/flows/custom.md#enable-a-flow) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/590573)

{{< /details >}}

以前は、AIカタログからAIエージェントとフローを有効にするには、トップレベルグループの権限が必要でした。

現在、検索レベルまたはプロジェクトレベルでAIカタログを閲覧する際、プロジェクトメンテナーはプロジェクト内で直接エージェントとフローを有効にできます。

### プロジェクト内のリモートフローのネットワークアクセス制御を設定する {#configure-network-access-control-for-remote-flows-in-projects}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/duo_agent_platform/environment_sandbox.md#configure-a-network-policy) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/593560)

{{< /details >}}

プロジェクト内のGitLab Runnerを使用するフローのネットワーク[アクセス制御](../../user/duo_agent_platform/environment_sandbox.md)を設定できるようになりました。

これにより、安全な外部インテグレーションが提供され、ネットワーク宛先に対する制御を維持できます。これにより、プロジェクトメンテナーは、セキュリティ境界を強制しながら、必要なAPI接続、MCPサーバー、およびサードパーティサービスを許可する柔軟性も得られます。

`agent-config.yml`の`network_policy`セクションで[ネットワークアクセス制御](../../user/duo_agent_platform/environment_sandbox.md)を設定します。`agent-config.yml`はブランチ保護ルールとMR承認ワークフローによって保護されています。

### GitLab Duo Agent Platform向けのセルフホスト型Vertex AI {#self-hosted-vertex-ai-for-gitlab-duo-agent-platform}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_llm_serving_platforms.md#configure-authentication-with-google-vertex-ai) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/591604)

{{< /details >}}

Vertex AIは、GitLab Duo Agent Platform Self-Hosted内でサポートされるLLMプラットフォームになりました。

お客様は、Vertex AIでホストされているAnthropicモデルを、GitLab Duo Agent Platformの機能と組み合わせて設定できるようになりました。

### ユーザーはプロジェクトから直接エージェントとフローを有効にできます {#users-can-enable-agents-and-flows-directly-from-projects}

<!-- categories: AI Catalog -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/duo_agent_platform/agents/custom.md#enable-an-agent) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/588012)

{{< /details >}}

メンテナーとオーナーは、現在のコンテキストから離れることなく、プロジェクトまたは検索ページから直接エージェントとフローを有効にできるようになりました。

トップレベルグループのオーナーは、自身のグループと、エージェントとフローを有効にしたい特定のプロジェクトを選択することもでき、ワークフローの設定を合理化します。

### IDEとCI/CDパイプラインにおけるAgent Skillsのサポート {#support-for-agent-skills-in-ides-and-cicd-pipelines}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/customize/agent_skills.md) | [関連イシュー](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/1984)

{{< /details >}}

GitLab Duo Agent Platformは現在、AIエージェントに新しい機能と専門知識を与えるための新たな標準である[Agent Skills仕様](https://agentskills.io/specification)をサポートしています。

プロジェクトのワークスペースレベルでAgent Skillsを定義して、特定のタスク（特定のフレームワークでテストを作成するなど）のためのエージェントに特殊な知識とワークフローを与えることができます。エージェントは、一致するタスクに遭遇すると、関連するスキルを自動的に発見し読み込みます。

名前、ファイルパス、またはカスタムスラッシュコマンドによって手動でスキルをトリガーすることもできます。Agent Skillsは、IDE内のフローとエージェントチャット、およびCI/CDパイプラインで実行されるフローでアクセスできます。これらは、仕様をサポートする他のすべてのAIツールとも連携します。

## 規模とデプロイ {#scale-and-deployments}

### クレジット使用データをCSVとしてダウンロード {#download-credit-usage-data-as-csv}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../subscriptions/gitlab_credits.md#export-usage-data) | [関連イシュー](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/14504)

{{< /details >}}

請求マネージャーは、カスタマーポータルのGitLabクレジットダッシュボードから直接、クレジット使用データをCSVファイルとしてダウンロードできるようになりました。

このエクスポートは、現在の請求月のクレジット消費の、コミットメント、免除、トライアル、オンデマンド、および含まれるクレジット使用状況を含む、日ごとのアクション別内訳を提供します。

財務および運用チームは、このデータを使用して、手動でのデータ収集やサポートリクエストなしに、Excel、Google Sheets、またはBIツールでコスト配分、チャージバックレポート、および使用状況分析を実行できます。

### クレジット使用状況をGitLab Duo Agent Platformセッションにリンク {#link-credit-usage-to-gitlab-duo-agent-platform-sessions}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../subscriptions/gitlab_credits.md#gitlab-credits-dashboard) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/579139)

{{< /details >}}

GitLabクレジットダッシュボードは、クレジット消費を、それを生成したGitLab Duo Agent Platformセッションに直接リンクするようになりました。

ユーザーごとのドリルダウンビューでは、Agent Platform使用行（**エージェントチャット**や**基盤エージェント**など）の**アクション**列が、対応するセッション詳細に移動するクリック可能なハイパーリンクになりました。

このリンクは、請求からAIセッション動作への直接の監査証跡を提供するため、管理者は個別のシステム間でタイムスタンプを手動で関連付けることなく、クレジット使用状況、サポートエスカレーション、およびコンプライアンスレビューを調査できます。

### GitLabクレジットダッシュボードでユーザーをソート {#sort-users-in-the-gitlab-credits-dashboard}

<!-- categories: Consumables Cost Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../subscriptions/gitlab_credits.md#view-the-gitlab-credits-dashboard) | [関連イシュー](https://gitlab.com/gitlab-org/customers-gitlab-com/-/work_items/15608)

{{< /details >}}

エンタープライズ管理者は、GitLabクレジットダッシュボード内の**Usage by User**テーブルを、使用されたクレジットの合計またはユーザー名でソートできるようになりました。

デフォルトのソート順は、消費されたクレジットの合計（最も高いものから）であるため、上位の消費者はスクロールなしにすぐに表示されます。

このビューを使用すると、数千人のGitLab Duoユーザーを管理する管理者は、コスト配分、チャージバックレポート、およびライセンス利用監査のために、高使用量の個人を迅速に特定できます。

### 検索におけるプロジェクトの新しいナビゲーション体験 {#new-navigation-experience-for-projects-in-explore}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/project/working_with_projects.md#explore-all-projects-on-an-instance) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/13786)

{{< /details >}}

We’ve streamlined the projects page in **検索** to reduce clutter and remove redundant options that accumulated over time.簡素化されたインターフェースは、現在2つのコアビューに焦点を当てています:

- **アクティブ**タブ: 最近のアクティビティと進行中の開発を持つプロジェクトを発見します。
- **非アクティブ**タブ: アーカイブされたプロジェクトと削除予定のプロジェクトにアクセスします。

いくつかの冗長なタブを削除しました:

- **Most starred**プロジェクトは、**アクティブ**または**非アクティブ**タブをスター数でソートすることで見つけることができます。
- **すべて**のプロジェクトは、**アクティブ**タブと**非アクティブ**タブの両方を表示することで利用可能です。
- **トレンド**タブは、限られた機能と低使用量のため、GitLab 19.0で完全に削除されます。

よりクリーンなデザインは、視覚的な一貫性のために他のプロジェクトリストと整合しています。より論理的な組織と柔軟なソートオプションを通じて、すべての同じコンテンツに引き続きアクセスできます。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### Java Gradleビルドファイル向けのSBOMサポート付き依存関係スキャン {#dependency-scanning-with-sbom-support-for-java-gradle-build-files}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#manifest-fallback) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/588788)

{{< /details >}}

SBOMを使用したGitLab依存関係スキャンは、Javaの`build.gradle`および`build.gradle.kts`ビルドファイルのスキャンをサポートするようになりました。

以前は、Gradleを使用するJavaプロジェクトの依存関係スキャンには、ロックファイルの存在が必要でした。現在、ロックファイルが利用できない場合、アナライザーは自動的に`build.gradle`および`build.gradle.kts`ファイルをスキャンするようにフォールバックし、脆弱性分析のために直接的な依存関係のみを抽出してレポートします。この改善により、Gradleを使用するJavaプロジェクトは、ロックファイルを必要とせずに依存関係スキャンを有効にすることが容易になります。

マニフェストフォールバックを有効にするには、`DS_ENABLE_MANIFEST_FALLBACK`CI/CD変数を`"true"`に設定します。

### 依存関係スキャンSBOMベースのスキャンがSelf-Managedに拡張 {#dependency-scanning-sbom-based-scanning-extended-to-self-managed}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/546429)

{{< /details >}}

GitLab 18.10では、新しいSBOMベースの依存関係スキャン機能の限定的な利用可能性ステータスをSelf-Managedインスタンスに拡張しています。

この機能は当初GitLab 18.5で、GitLab.comのみで限定的に利用可能で、機能フラグ`dependency_scanning_sbom_scan_api`の背後にあり、デフォルトで無効になっていました。

追加の改善と修正により、新しいSBOMスキャン内部APIを信頼して使用し、この機能フラグをデフォルトで有効にする自信を持つようになりました。この内部APIにより、依存関係スキャンアナライザーは、すべてのコンポーネント脆弱性を含む依存関係スキャンレポートを生成できます。CI/CDパイプライン完了後にSBOMレポートを処理した以前の動作（ベータ）とは異なり、[この改善されたプロセス](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#how-it-scans-an-application)は、CI/CDジョブ中にスキャン結果を即座に生成し、カスタムワークフローの脆弱性データへの即時アクセスをユーザーに提供します。

Self-Managedインスタンスのお客様でイシューが発生した場合は、`dependency_scanning_sbom_scan_api`機能フラグを無効にすることができます。その後、アナライザーは以前の動作にフォールバックします。

この機能を使用するには、v2依存関係スキャンテンプレート`Jobs/Dependency-Scanning.v2.gitlab-ci.yml`をインポートします。

この機能に関するフィードバックをお待ちしております。ご質問、コメント、または私たちのチームと関わりたい場合は、この[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523458)でお問い合わせください。

### Pubパッケージマネージャーを使用するDart/Flutterプロジェクト向けのライセンススキャンサポート {#license-scanning-support-for-dartflutter-projects-using-pub-package-manager}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#data-sources) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/18351)

{{< /details >}}

GitLabは現在、`pub`パッケージマネージャーを使用するDartおよびFlutterプロジェクトのライセンススキャンをサポートしています。以前は、DartまたはFlutterでビルドするチームは、GitLab内で直接オープンソースの依存関係のライセンスを特定できず、ライセンスポリシー要件を持つ組織にとってコンプライアンス上の死角を生み出していました。

ライセンスデータは、公式のDartパッケージリポジトリである[pub.dev](https://pub.dev)から直接取得され、結果は他のサポートされているエコシステムと並んで表示されます。Dart/Flutter依存関係スキャンと脆弱性検出はすでにサポートされていました。

### Conan 2.0パッケージレジストリのサポート（ベータ） {#conan-20-package-registry-support-beta}

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/packages/conan_2_repository/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/585819)

{{< /details >}}

C++開発チームは、Conanをパッケージマネージャーとして使用し、GitLabでのレジストリサポートを長年リクエストしてきました。以前は、Conanパッケージレジストリは実験的であり、Conan 1.xクライアントのみをサポートしていたため、最新のConan 2.0ツールチェーンに移行したチームでの採用が制限されていました。

Conanパッケージレジストリは、現在Conan 2.0をサポートしており、実験的からベータにプロモートされました。このリリースには、完全なv2 API互換性、レシピリビジョンサポート、改善された検索機能、および`--force`フラグを含むアップロードポリシーの適切な処理が含まれています。チームは、標準的なConanクライアントワークフローを使用してGitLabから直接Conan 2.0パッケージを公開およびインストールでき、JFrog Artifactoryのような外部のアーティファクト管理ソリューションの必要性を低減します。

この更新により、CおよびC++ 依存関係を管理するプラットフォームエンジニアリングチームは、ソースコード、CI/CDパイプライン、およびセキュリティスキャンとともに、GitLab内でパッケージ管理を統合できます。Conanレジストリは、プロジェクトレベルとインスタンスレベルのエンドポイントの両方をサポートし、パーソナルアクセストークン、デプロイトークン、およびCI/CDジョブトークンと連携して認証を行います。

一般公開に向けて作業を進めるにあたり、フィードバックをお待ちしております。[エピック](https://gitlab.com/groups/gitlab-org/-/work_items/6816)であなたの体験を共有してください。

### 専用UIでコンテナ仮想レジストリを管理する（ベータ） {#manage-container-virtual-registries-with-a-dedicated-ui-beta}

<!-- categories: Virtual Registry -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/packages/virtual_registry/container/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/19283)

{{< /details >}}

コンテナ仮想レジストリが前回のマイルストーンでベータ版としてローンチされた際、プラットフォームエンジニアは、Docker Hub、Harbor、Quayなどの複数のアップストリームコンテナレジストリを単一のプルエンドポイントの背後に集約できました。しかし、すべての設定には直接的なAPIコールが必要であり、チームはレジストリを作成および管理し、アップストリームを設定し、時間の経過とともに変更を処理するためにスクリプトまたは手動cURLコマンドを維持する必要がありました。これにより、運用上のオーバーヘッドが増加し、APIを直接操作することに慣れていないユーザーにとって、その機能はアクセス不能になりました。

コンテナ仮想レジストリは、GitLab UIから直接作成および管理できるようになりました。グループレベルのコンテナレジストリページから、新しい仮想レジストリの作成、認証認証情報を使用したアップストリームソースの設定、既存の設定の編集、不要になったレジストリの削除が、GitLabを離れることも、APIコールを1つも記述することもなく、すべて可能です。UIは既存のコンテナレジストリ体験とシームレスに統合され、仮想レジストリはグループのアーティファクト管理ワークフローの第一級の一部となります。

この機能はベータ版です。フィードバックを共有するには、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/589630)にコメントしてください。

### GitLab Helm Chartレジストリが一般公開 {#gitlab-helm-chart-registry-generally-available}

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/packages/helm_repository/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/573715)

{{< /details >}}

Helmを使用してKubernetesアプリケーションのデプロイを管理するチームは、本番環境ワークロードのためにGitLab Helm Chartレジストリに頼ることができるようになりました。以前はベータ版でしたが、主要なアーキテクチャおよび信頼性に関する懸念の解決後、レジストリは現在一般公開されています。

GAへのパスには、`index.yaml`エンドポイントが1,000以上のチャートを返すのを妨げていたハード制限の解決、新しく公開されたチャートのバージョンがインデックスから欠落する原因となっていたバックグラウンドインデックス作成バグの修正、完全なAppSecセキュリティレビューの完了、およびHelmメタデータキャッシュのGeoレプリケーションサポートの追加が含まれており、GitLab Geoを実行しているSelf-Managedのお客様向けのHAを確保しています。

プラットフォームおよびDevOpsチームは、標準的なHelmクライアントワークフローを使用してGitLabから直接Helmチャートを公開およびインストールでき、プロジェクトレベルのエンドポイントと、パーソナルアクセストークン、デプロイトークン、およびCI/CDジョブトークンを使用した認証をサポートしています。これで、チャートをソースコード、パイプライン、およびそれに依存するセキュリティスキャンとともに保持できます。

### Markdownテーブルでのタスクアイテムサポート {#task-item-support-in-markdown-tables}

<!-- categories: Markdown -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/markdown.md#task-lists-in-tables) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/21506)

{{< /details >}}

これで、Markdownテーブルセルでタスクアイテムチェックボックス構文を直接使用できます。

以前は、これを実現するには、raw HTMLとMarkdownの組み合わせが必要であり、煩雑で維持が困難でした。

この改善により、イシュー、エピック、およびその他のコンテンツ内の構造化されたテーブルレイアウトで、タスクの完了を直接追跡することが容易になります。

### パイプラインシークレット検出におけるセキュリティ設定プロファイル {#pipeline-secret-detection-in-security-configuration-profiles}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/configuration/security_configuration_profiles.md)

{{< /details >}}

GitLab 18.9では、プッシュ保護から始まり、セキュリティ設定プロファイルに**Secret Detection - Default**プロファイルを導入しました。このプロファイルを使用すると、単一のCI/CD設定ファイルに触れることなく、数百のプロジェクトにわたって標準化されたシークレットスキャンを適用できます。

**Secret Detection - Default**プロファイルは、パイプラインベースのスキャンもカバーするようになり、開発ワークフロー全体にわたるシークレット検出のための統合された制御サーフェスを提供します。

このプロファイルは、3つのスキャントリガーを有効にします:

- **Push Protection**: すべてのGitプッシュイベントをスキャンし、シークレットが検出されたプッシュをブロックすることで、シークレットがコードベースに侵入するのを防ぎます。
- **マージリクエストパイプライン**: 新しいコミットがオープンなマージリクエストのあるブランチにプッシュされるたびに、自動的にスキャンを実行します。結果には、マージリクエストによって導入された新しい脆弱性のみが含まれます。
- **ブランチパイプライン(デフォルトのみ)**: 変更がデフォルトブランチにマージまたはプッシュされると自動的に実行され、デフォルトブランチのシークレット検出姿勢の完全なビューを提供します。

このプロファイルを適用するのにYAML設定は必要ありません。このプロファイルは、グループ内のすべてのプロジェクトにわたってカバレッジを伝播するためにグループに適用することも、よりきめ細かい制御のために個々のプロジェクトに適用することもできます。

### macOS Tahoe 26およびXcode 26ジョブイメージ {#macos-tahoe-26-and-xcode-26-job-image}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/hosted_runners/macos.md) | [関連エピック](https://gitlab.com/groups/gitlab-com/gl-infra/-/work_items/1694)

{{< /details >}}

macOS Tahoe 26とXcode 26を使用して、最新世代のAppleデバイス向けアプリケーションを作成、テスト、およびデプロイできるようになりました。

With [hosted Runners on macOS](../../ci/runners/hosted_runners/macos.md), your開発チームは、GitLab CI/CDと統合された安全なオンデマンドビルド環境で、macOSアプリケーションをより迅速にビルドおよびデプロイできます。

今日から`.gitlab-ci.yml`ファイルで`macos-26-xcode-26`イメージを使用して試してみてください。

### GitLab Runner 18.10 {#gitlab-runner-1810}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.10もリリースします！GitLab Runnerは、CI/CDジョブを実行し、その結果をGitLabインスタンスに送信する、拡張性の高いビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [k8s Runnerがビルドポッドのポッドレベルリソースを定義できるようにする](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39085)
- [すべてのRunnerプロジェクトに対してGoバージョンとパッケージを更新する自動化を追加](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39192)

#### バグ修正 {#bug-fixes}

- [RoleARN付きS3キャッシュが、存在しないキャッシュに対して404ではなく403を返す](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39105)
- [ヘルパーイメージ`gitlab-runner-helper:x86_64-v16.11.1-nanoserver21H2`を使用すると、`init-permissions`エラーが発生する](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/37872)
- [MacOS: LaunchAgent - M1アーキテクチャでサービスを初期化できませんでした](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/28136)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-10-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-10-stable/CHANGELOG.md).md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.10)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.10)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.10)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
