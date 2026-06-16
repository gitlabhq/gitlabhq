---
stage: Release Notes
group: Monthly Release
date: 2026-05-21
title: "GitLab 19.0リリースノート"
description: "GitLab 19.0 リリース — GitLab Duo にグループレベルのカスタムレビュー指示機能を搭載"
---

2026年5月21日、GitLab 19.0が以下の機能とともにリリースされました。

今月の[Notable Contributor](https://contributors.gitlab.com/notable-contributors)は、Norman Debaldさんです！

[Normanさん](https://gitlab.com/Modjo85)は、レベル3のコントリビューターで、2022年5月の参加以来、GitLab全体で40件以上のマージされた改善に貢献しています。

<!-- Copy this template, and paste it into the doc section where it belongs:

Primary feature, Agentic Core, Scale and Deployments, or Unified DevOps and Security.

Update all the information as needed.

### Feature explanation here {#feature-explanation-here}

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Links: [Documentation](../../ci/yaml/_index.md), [Related issue](https://gitlab.com/groups/gitlab-org/-/work_items/17754)

{{< /details >}}

Now write 125 words or fewer to explain the value of this improvement.
Use phrases that start with, "In previous versions of GitLab, you couldn't... Now you can..."

Use present tense, and speak about "you" instead of "the user."
-->

## 主要な機能 {#primary-features}

### GitLab Duoのグループレベルのカスタムレビュー指示 {#group-level-custom-review-instructions-for-gitlab-duo}

<!-- categories: Duo Code Review -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/customize_duo/review_instructions.md#configure-custom-review-instructions-for-a-group)、[関連イシュー](https://gitlab.com/groups/gitlab-org/-/work_items/21504)

{{< /details >}}

以前のバージョンのGitLabでは、GitLab Duoのカスタムレビュー指示はプロジェクトレベルでのみ定義できました。同じグループ内の多くのプロジェクトにまたがって作業するチームは、すべてのプロジェクトで同じ指示を複製する必要がありました。

今回のリリースで、グループ全体とそのサブグループに対して共有カスタムレビュー指示を設定できるようになりました。

グループ内のプロジェクトをテンプレートとして選択します。GitLab Duoがコードレビューを実行すると、グループレベルの`.gitlab/duo/mr-review-instructions.yaml`ファイルと個々のプロジェクトで定義された指示が組み合わされます。

コードレビューフローとGitLab Duoコードレビューの両方が、グループレベルのカスタム指示をサポートしています。

### 作業アイテムタイプの設定 {#configure-work-item-types}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/work_items/configurable_work_item_types.md)、[関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/9365)

{{< /details >}}

これまで、作業アイテムタイプは**イシュー**または**タスク**のいずれかに限られていましたが、プロジェクト内でカスタムの作業アイテムタイプを設定して、チームの計画・追跡方法に合わせられるようになりました。

タイプを**ユーザーストーリー**、**バグ**、または**メンテナンス**として作成または名前変更できます。各作業アイテムはそのタイプ名と固有のアイコンで表示されます。新しいタイプはカスタムフィールドとステータスライフサイクルをサポートし、保存済みビューやイシューボードに表示されます。トップレベルグループ（GitLab.com）または組織（GitLab Self-Managed）でのタイプ設定は、すべてのプロジェクトに継承されます。

また、各プロジェクトで利用可能なタイプを制御することもできます。すべてのプロジェクトで一度にタイプを有効または無効にするか、個々のプロジェクトが独自のタイプの表示設定を管理できるようにします。プロジェクトでタイプを無効にしても、既存の作業アイテムには影響しません。

### GitLab Secrets Managerがオープンベータで利用可能に {#gitlab-secrets-manager-now-available-in-open-beta}

<!-- categories: Secrets Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../ci/secrets/secrets_manager/_index.md)、[関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/21731)

{{< /details >}}

以前のバージョンのGitLabでは、GitLab Secrets Managerはクローズドベータに限定されていました。ほとんどのチームはHashiCorp VaultやAWS Secrets Managerなどの外部サービスに依存していました。

今回のリリースでGitLab Secrets Managerが、GitLab.comおよびGitLab Self-ManagedのPremiumおよびUltimateのお客様向けにオープンベータで利用可能になりました。GitLab Secrets Managerが有効な場合、プロジェクトおよびグループのオーナーはGitLab内でCI/CDシークレットを保存、取得、参照できます。シークレットはプロジェクトまたはグループにスコープされ、明示的にリクエストしたパイプラインジョブのみがアクセスできます。

オープンベータ期間中、GitLab Secrets Managerは[ベータサポートポリシー](../../policy/development_stages_support.md#beta)に従い、本番環境での使用に対応していない場合があります。

フィードバックを共有するには、[イシュー598100](https://gitlab.com/gitlab-org/gitlab/-/issues/598100)をご覧ください。

### マージリクエストワークフローのためのGitLab Duo Developerの機能強化 {#gitlab-duo-developer-enhancements-for-merge-request-workflows}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/flows/foundational_flows/developer.md)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/228817)

{{< /details >}}

GitLab Duo Developerは複数のトリガー方法をサポートするようになりました。イシューに割り当てる、**MRを生成**を選択する、またはイシューやMRのディスカッションスレッドで`@mention`することで、フィードバック、To-Doアイテム、設計上の質問をコード変更、フォローアップMR、またはリサーチサマリーに変換できます。

`AGENTS.md`と`agent-config.yml`を設定することで、GitLab Duo Developerはコミット前にテストとチェックを実行します。トップレベルグループまたはインスタンス管理者がデベロッパーフローを有効にすると、GitLabは対象プロジェクトにメンションと割り当てトリガーを自動的に追加します。

### SBOMを使用した依存関係スキャンが一般提供に {#dependency-scanning-by-using-sbom-generally-available}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md)、[関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/20456)

{{< /details >}}

GitLabのSBOMベースの依存関係スキャナーが一般提供開始になりました。Maven、Gradle、Pythonプロジェクトで、直接宣言されたものだけでなく、推移的に導入された脆弱なパッケージを含む、完全な依存関係ツリー全体の脆弱性を可視化できるようになりました。

アナライザーには、Maven、Gradle、Pythonプロジェクトの自動依存関係解決が含まれるようになりました。ロックファイルまたは解決済みの依存関係グラフが存在しない場合、アナライザーはスキャン前に完全な推移的依存関係グラフを解決するためのツールを自動的に実行します。依存関係解決はデフォルトで有効になっており、v2 Dependency Scanningテンプレートを含める以外に追加の設定はほとんど必要ありません。

依存関係解決が不可能なプロジェクトの場合、アナライザーはマニフェストスキャンにフォールバックします。`pom.xml`、`requirements.txt`、`build.gradle`、`build.gradle.kts`を解析して直接依存関係を特定します。マニフェストスキャンにより、ロックファイルやビルドファイルのないプロジェクトでも、チームは常に脆弱性カバレッジの出発点を得られます。

マニフェストスキャンはデフォルトで有効になっており、直接依存関係のみを返します。完全な推移的カバレッジを得るには、依存関係解決を有効にするか、依存関係ロックファイルまたはグラフエクスポートを手動で提供してください。

## Agent Platformの中核機能 {#agentic-core}

### GitLab Duo Coreが使用量ベースの課金に移行 {#gitlab-duo-core-moves-to-usage-based-billing}

<!-- categories: Duo Agent Platform, Duo Chat, Code Suggestions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../subscriptions/subscription-add-ons.md#gitlab-duo-core)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/600144)

{{< /details >}}

GitLab 19.0から、GitLab Duo Coreは使用量ベースの課金に移行します。Web IDEおよびデスクトップIDEのコード提案は、[GitLabクレジット](../../subscriptions/gitlab_credits.md)を消費するようになります。

GitLab Duo Chatも変更されます。GitLab Duo Coreユーザーの場合、Chatはエージェント型になりGitLab Duo Agent Platformで動作します。GitLab UIまたはデスクトップIDEでGitLab Duo Chatを使用するには、インスタンスまたはトップレベルグループでGitLab Duo Agent Platformを有効にしてください。

### 完全一致コードの検索結果をリポジトリでフィルタリング {#filter-exact-code-search-results-by-repository}

<!-- categories: Global Search -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/search/exact_code_search.md#syntax)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/488467)

{{< /details >}}

完全一致コードの検索結果をリポジトリでフィルタリングできるようになりました。`repo:`構文を使用すると、個々のプロジェクトに移動することなく、検索クエリを特定のリポジトリまたはリポジトリパターンに直接スコープできます。

例えば、`def authenticate repo:my-group/my-project`を検索すると、そのリポジトリからの結果のみが返されます。また、部分的なパスやパターンを使用して、複数のリポジトリを照合することもできます。

### マージリクエスト準備完了イベントトリガー {#merge-request-ready-event-trigger}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/duo_agent_platform/triggers/_index.md)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/592454)

{{< /details >}}

フローと外部エージェントを**マージリクエスト準備完了**イベントで実行するように設定できるようになりました。

ドラフトのマージリクエストがレビュー準備完了としてマークされると、GitLab Duoはフローまたは外部エージェントを自動的に実行します。

トリガーを設定するには、プロジェクトの**AI** > **トリガー**に移動します。

この機能は`merge_request_ready_flow_trigger`機能フラグで制御されており、デフォルトでは無効になっています。

### GitLab Duo Agent PlatformでClaude Opus 4.7が利用可能に {#claude-opus-4-7-now-available-in-gitlab-duo-agent-platform}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/model_selection.md#supported-models)、[関連イシュー](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/work_items/2177)

{{< /details >}}

Claude Opus 4.7がGitLab Duo Agent Platformで利用可能になりました。Opus 4.7は、継続的な推論、指示への正確な準拠、結果を出力する前の自己検証を必要とする複雑なマルチステップタスクに対して、意味のある改善をもたらします。これには、CI/CDパイプライン、コードレビュー、脆弱性解決などをサポートするフローが含まれます。

### セルフホスト型Geminiモデルのサポート {#support-for-self-hosted-gemini-models}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#compatible-models)、[関連イシュー](https://gitlab.com/groups/gitlab-org/-/work_items/21186)

{{< /details >}}

GitLab Duo Agent Platform Self-HostedがGeminiモデルと互換性を持つようになりました。Geminiモデルはコードレビューフロー、SAST脆弱性修正フロー、CI/CDパイプライン修正フローなど、複数のフローをサポートしています。

### GitLab Duo Agent Platformでのオープンソースモデルサポートの拡張 {#expanded-open-source-model-support-in-gitlab-duo-agent-platform}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/supported_models_and_hardware_requirements.md#supported-models)、[関連イシュー](https://gitlab.com/groups/gitlab-org/-/work_items/21186)

{{< /details >}}

GitLab Duo Agent Platformは、セルフホストデプロイ向けに追加のオープンソースモデルをサポートするようになりました。Devstral 2 123B、GLM-5.1-FP8などが含まれます。これにより、オフラインやネットワーク制限のある環境を含む、さまざまな環境でエージェント型ワークフローを実現できます。

### 管理者コントロール付きのセッションごとのツール承認 {#per-session-tool-approvals-with-admin-controls}

<!-- categories: Duo Agent Platform, Duo Chat -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/gitlab_duo_chat/agentic_chat.md#tool-approvals)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/596366)

{{< /details >}}

GitLab Duo Agentic Chatがツールを使用するには、その都度ユーザーの承認が必要でした。

今回のリリースで、信頼できるツールをセッション内で一度だけ承認すれば、同じセッション中は再承認なしで使用できるようになりました。

管理者は、セッションのツール承認が利用可能かどうかを制御します。以下の設定はインスタンスからグループ、プロジェクトへと継承されます:

- **デフォルトでオン**
- **デフォルトでオフ**
- **常にオフ**

管理者が**常にオフ**に設定しない限り、グループとサブグループは設定を変更できます。

デフォルト設定は**デフォルトでオフ**であり、管理者が変更しない限り、各ツールの実行には明示的な承認が必要です。

### GitLab Duoでマージコンフリクトを解決（ベータ版） {#resolve-merge-conflicts-with-gitlab-duo-beta}

<!-- categories: Duo Agent Platform, Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/merge_requests/conflicts.md#resolve-conflicts-with-gitlab-duo)、[関連イシュー](https://gitlab.com/groups/gitlab-org/-/work_items/20688)

{{< /details >}}

以前のバージョンのGitLabでは、単純なケースであっても、GitLab UIまたはコマンドラインでマージコンフリクトを手動で解決する必要がありました。

今回のリリースで、GitLab Duoがマージコンフリクトを自律的に分析し、該当ファイルの編集からコミット作成、ソースブランチへのプッシュまでを自動で行えるようになりました。**コンフリクトを解決**ページまたはマージリクエストウィジェットから直接コンフリクト解決をトリガーできます。完了すると、GitLab Duoがサマリーコメントを投稿するため、レビュアーは変更内容をすぐに確認できます。

GitLab Duoはブランチ保護ルールを尊重し、保護ブランチへの強制プッシュは行いません。

この機能はベータ版であり、`mr_ai_resolve_conflicts`機能フラグで制御されており、デフォルトでは有効になっています。

### AIカタログをグループ階層に制限する {#restrict-the-ai-catalog-to-a-group-hierarchy}

<!-- categories: AI Catalog -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/ai_catalog.md#restrict-the-ai-catalog-to-a-group-hierarchy)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/594617)

{{< /details >}}

トップレベルグループのオーナーは、AIカタログをグループ階層内のプロジェクトが所有するエージェントとフローのみを表示するように制限できるようになりました。これにより、この階層に含まれないエージェント、外部エージェント、またはフローが、そのグループのユーザーに表示されたり有効化されたりすることをブロックします。

### GitLab Self-ManagedのFreeプランでクレジットを購入 {#purchase-credits-on-the-free-tier-on-gitlab-self-managed}

<!-- categories: Subscription Management -->

{{< details >}}

- プラン: Free
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../subscriptions/gitlab_credits.md#buy-gitlab-credits)、[関連イシュー](https://gitlab.com/groups/gitlab-org/-/work_items/20165)

{{< /details >}}

GitLab Self-ManagedのFreeプランユーザーは、PremiumまたはUltimateのサブスクリプションなしで、GitLab Duo Agent Platformのフル機能を利用できるようになりました。月次クレジット量を選択し、年間契約にすることで、AIを活用した開発ツールに即座にアクセスできます。クレジットは毎月自動的に更新されるため、チームは常に必要なものを手に入れ、より速く、よりスマートに構築できます。

### Agent Platformリモートフローの管理者定義ネットワークアクセス制御 {#admin-defined-network-access-controls-for-agent-platform-remote-flows}

<!-- categories: Duo Agent Platform -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/duo_agent_platform/environment_sandbox.md#configure-a-network-policy)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/593149)

{{< /details >}}

管理者は、設定から直接GitLab Duo Agent Platformリモートフローの集中ネットワークポリシーを定義できるようになりました。GitLab.comのトップレベルグループ管理者、およびGitLab Self-ManagedとDedicatedのインスタンス管理者は、プロジェクトが自動的に継承する組織全体のドメイン拒否リストと許可リストを設定できます。追加の設定により、プロジェクトがカスタムエントリで承認済みドメインリストを拡張できるかどうかを制御します。ポリシーはすべてのリモートフローにわたってランタイムで適用され、セキュリティおよびプラットフォームチームにエージェントのネットワーク外部通信に対する一貫したガバナンス層を提供します。

## スケールとデプロイ {#scale-and-deployments}

### PostgreSQL 17の最小要件 {#postgresql-17-minimum-requirement}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/package_information/postgresql_versions.md)、[関連イシュー](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9792)

{{< /details >}}

PostgreSQLの最小サポートバージョンはバージョン17になりました。パッケージ版PostgreSQL 16を使用している場合は、GitLab 19.0をインストールする前に[パッケージ版PostgreSQLサーバーをアップグレード](https://docs.gitlab.com/omnibus/settings/database.html#upgrade-packaged-postgresql-server)してください。

### Ubuntu 20.04向けLinuxパッケージサポートの終了 {#linux-package-support-for-ubuntu-20-04-discontinued}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../install/package/_index.md#supported-platforms)、[関連イシュー](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8915)

{{< /details >}}

Ubuntu 20.04は2025年5月に標準サポートが終了しました。GitLab 19.0から、Ubuntu 20.04向けのLinuxパッケージは提供されなくなります。GitLab 18.11がこのディストリビューション向けのパッケージを含む最後のリリースです。GitLab 19.0にアップグレードする前に、Ubuntu 22.04または他の[サポートされているオペレーティングシステム](../../install/package/_index.md#supported-platforms)に移行してください。

### Redis 6サポートの削除 {#redis-6-support-removed}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../install/requirements.md)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/585839)

{{< /details >}}

GitLab 19.0でRedis 6のサポートが削除されます。外部のRedis 6デプロイを使用している場合は、アップグレード前にRedis 7.2またはValkey 7.2に移行してください。Linuxパッケージに含まれるバンドル版RedisはGitLab 16.2からRedis 7を使用しており、影響を受けません。

### LinuxパッケージからのMattermostの削除 {#mattermost-removed-from-the-linux-package}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](https://docs.mattermost.com/administration-guide/onboard/migrate-gitlab-omnibus.html)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/590798)

{{< /details >}}

GitLab 19.0でバンドル版MattermostがLinuxパッケージから削除されます。現在バンドル版Mattermostを使用している場合は、移行手順について[LinuxパッケージからMattermost Standaloneへの移行](https://docs.mattermost.com/administration-guide/onboard/migrate-gitlab-omnibus.html)を参照してください。バンドル版Mattermostを使用していないお客様には影響はありません。

### SUSEディストリビューション向けLinuxパッケージサポートの終了 {#linux-package-support-for-suse-distributions-discontinued}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../install/docker/installation.md)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/590801)

{{< /details >}}

SUSEディストリビューション向けのLinuxパッケージサポートはGitLab 19.0で終了します。これはopenSUSE Leap 15.6、SUSE Linux Enterprise Server 12.5、およびSUSE Linux Enterprise Server 15.6に影響します。GitLab 18.11がこれらのディストリビューション向けのLinuxパッケージを含む最後のバージョンです。SUSEディストリビューションを引き続き使用するには、[GitLabのDockerデプロイ](../../install/docker/installation.md)に移行してください。

### LinuxパッケージとGitLab HelmチャートからのSpamcheckの削除 {#spamcheck-removed-from-linux-package-and-gitlab-helm-chart}

<!-- categories: Omnibus Package, Cloud Native Installation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/reporting/spamcheck.md)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/590796)

{{< /details >}}

[Spamcheck](../../administration/reporting/spamcheck.md)はGitLab 19.0でLinuxパッケージとGitLab Helmチャートから削除されます。現在Spamcheckを使用していないお客様には影響はありません。バンドル版Spamcheckを使用している場合は、[Docker](https://gitlab.com/gitlab-org/gl-security/security-engineering/security-automation/spam/spamcheck)を使用して個別にデプロイできます。データ移行は不要です。

### NGINX IngressがEnvoy GatewayによるGateway APIに置き換えられる {#nginx-ingress-replaced-by-gateway-api-with-envoy-gateway}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](https://docs.gitlab.com/charts/)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/590800)

{{< /details >}}

GitLab 19.0では、Envoy GatewayによるGateway APIがGitLab Helmチャートのデフォルトネットワーク設定になり、2026年3月に提供終了となったNGINX Ingressを置き換えます。Envoy Gatewayへの移行がすぐに実現できない場合は、バンドル版NGINX Ingressを明示的に再有効化できます。これはGitLab 20.0での計画的な削除まで利用可能です。この変更は、Linuxパッケージで使用されるNGINX、または外部管理のIngressまたはGateway APIコントローラーを使用するHelmチャートインスタンスには影響しません。

### GitLab HelmチャートからバンドルされたPostgreSQL、Redis、MinIOの削除 {#bundled-postgresql-redis-and-minio-removed-from-gitlab-helm-chart}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/590797)

{{< /details >}}

バンドルされたBitnami PostgreSQL、Bitnami Redis、MinIOチャートは、GitLab 19.0でGitLab HelmチャートとGitLab Operatorから代替なしで削除されます。これらのコンポーネントは概念実証およびテスト環境のみを対象としており、本番環境での使用は推奨されていません。これらのバンドルサービスのいずれかを使用してインスタンスを実行している場合は、GitLab 19.0にアップグレードする前に[移行ガイド](https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/)に従って外部サービスを設定してください。

### 大規模グループでのSCIMユーザーデプロビジョニングの信頼性向上 {#reliable-scim-user-deprovisioning-for-large-groups}

<!-- categories: User Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../development/internal_api/_index.md#group-scim-api)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/521324)

{{< /details >}}

SCIMを通じて多数のユーザーを管理している組織では、グループメンバーのデプロビジョニングがタイムアウトして`500`エラーが返されることがありました。SCIMの`DELETE`および`PATCH`リクエストは即座に成功レスポンスを返すようになりました。メンバーシップの削除は非同期で処理されるため、IDプロバイダーとSCIMクライアントは一貫した成功レスポンスを受け取ります。

## 統合DevOpsとセキュリティ {#unified-devops-and-security}

### 脆弱な依存関係の自動修正（実験的機能） {#auto-remediation-for-vulnerable-dependencies-experiment}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/remediate/auto_remediation.md)、[関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/17403)

{{< /details >}}

GitLab 19.0で、依存関係の自動修正が実験的機能として利用可能になりました。依存関係スキャンで既知の修正が存在する脆弱なRuby依存関係が検出されると、GitLabは人手を介さずに安全なバージョンへの更新マージリクエストを自動的に作成します。実験的機能でサポートされるのはRubyプロジェクトのみです。

各パイプライン実行後、GitLabは利用可能なパッチまたはマイナーバージョンアップグレードがある最も重大度の高い脆弱性を特定します。GitLabがマニフェストファイルの変更を生成し、サービスアカウントを通じてマージリクエストを作成します。その後、マージリクエストはプロジェクトの標準的なレビューおよび承認ワークフローに従います。

実験的機能の期間中、プロジェクトあたり同時にオープンできる自動修正マージリクエストは最大3件です。

フィードバックの共有や実験的機能への参加を希望する場合は、[エピック600511](https://gitlab.com/gitlab-org/gitlab/-/work_items/600511)にコメントしてください。
プロジェクトで実験的機能を有効にするには、GitLabチームメンバーがプロジェクトの`dependency_management_auto_remediation`機能フラグを有効にする必要があります。

### セキュリティ設定プロファイルでの依存関係スキャン {#dependency-scanning-in-security-configuration-profiles}

<!-- categories: Security Testing Configuration -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/configuration/security_configuration_profiles.md)、[関連イシュー](https://gitlab.com/groups/gitlab-org/-/work_items/19952)

{{< /details >}}

GitLab 18.11では、SASTとシークレット検出のセキュリティ設定プロファイルが導入されました。
これで、依存関係スキャンも **依存関係スキャン - デフォルト** プロファイルで利用可能になりました。
このプロファイルにより、単一のCI/CD設定ファイルを編集することなく、すべてのプロジェクトに標準化されたSCAカバレッジを適用するための統一された操作画面が提供されます。

このプロファイルは2つのスキャントリガーを有効にします:

- **マージリクエストパイプライン**: オープンなマージリクエストがあるブランチに新しいコミットがプッシュされるたびに、依存関係スキャンを自動的に実行します。結果にはマージリクエストによって導入された新しい脆弱性のみが含まれます。
- **ブランチパイプライン（デフォルトのみ）**: 変更がデフォルトブランチにマージまたはプッシュされたときに自動的に実行され、デフォルトブランチの依存関係の状態の完全なビューを提供します。

### Gradle SBOMスキャンの依存関係解決 {#dependency-resolution-for-gradle-sbom-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md#dependency-resolution) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/work_items/590734)

{{< /details >}}

SBOMを使用したGitLabの依存関係スキャンが、Gradleプロジェクトの依存関係グラフ (`gradle.graph.txt`)を自動的に生成するようになりました。以前は、Gradleの依存関係スキャンではビルドの一部として依存関係グラフを手動で生成する必要がありました。グラフファイルが存在しない場合、アナライザーが自動的に生成するようになり、GradleベースのJavaおよびKotlinプロジェクトでこの手動ステップが不要になりました。

### APIセキュリティテストの検出結果に対する修正ガイダンス {#remediation-guidance-for-api-security-testing-findings} 

<!-- categories: API Security -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/application_security/api_security_testing/checks/_index.md)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/584601)

{{< /details >}}

APIセキュリティの脆弱性レポートに、各検出結果に対する修正ガイダンスが含まれるようになりました。以前は、APIセキュリティテストで脆弱性が特定されても、修正方法に関するガイダンスは提供されていませんでした。デベロッパーは修正手順を独自に調査する必要がありました。今後は、各検出結果に脆弱性固有の修正手順と、関連するOWASPおよびCWE識別子への参照が脆弱性レポートに直接含まれます。

現在、以下のチェックに修正ガイダンスが含まれています:

- [アプリケーション情報](../../user/application_security/api_security_testing/checks/application_information_check.md)
- [平文認証](../../user/application_security/api_security_testing/checks/cleartext_authentication_check.md)
- [CORS](../../user/application_security/api_security_testing/checks/cors_check.md)
- [DNSリバインディング](../../user/application_security/api_security_testing/checks/dns_rebinding_check.md)
- [フレームワークデバッグモード](../../user/application_security/api_security_testing/checks/framework_debug_mode_check.md)
- [Heartbleed OpenSSL脆弱性](../../user/application_security/api_security_testing/checks/heartbleed_open_ssl_check.md)
- [HTMLインジェクション](../../user/application_security/api_security_testing/checks/html_injection_check.md)
- [脆弱なHTTPメソッド](../../user/application_security/api_security_testing/checks/insecure_http_methods_check.md)
- [JSONハイジャッキング](../../user/application_security/api_security_testing/checks/json_hijacking_check.md)
- [JSONインジェクション](../../user/application_security/api_security_testing/checks/json_injection_check.md)
- [オープンリダイレクト](../../user/application_security/api_security_testing/checks/open_redirect_check.md)
- [OSコマンドインジェクション](../../user/application_security/api_security_testing/checks/os_command_injection_check.md)
- [パストラバーサル](../../user/application_security/api_security_testing/checks/path_traversal_check.md)
- [機密ファイル](../../user/application_security/api_security_testing/checks/sensitive_file_disclosure_check.md)
- [機密情報](../../user/application_security/api_security_testing/checks/sensitive_information_disclosure_check.md)
- [セッションCookie](../../user/application_security/api_security_testing/checks/session_cookie_check.md)
- [Shellshock](../../user/application_security/api_security_testing/checks/shellshock_check.md)
- [SQLインジェクション](../../user/application_security/api_security_testing/checks/sql_injection_check.md)
- [TLS設定](../../user/application_security/api_security_testing/checks/tls_server_configuration_check.md)
- [認証トークン](../../user/application_security/api_security_testing/checks/authentication_token_check.md)
- [XMLインジェクション](../../user/application_security/api_security_testing/checks/xml_injection_check.md)

### CI/CDインプットの配列サポートの改善 {#improved-array-support-for-ci-cd-inputs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../ci/inputs/_index.md#access-individual-array-elements)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/587657)

{{< /details >}}

CI/CDインプットは、配列を扱うためのサポートが改善されました。配列入力内の特定の要素にアクセスするには、配列インデックス演算子`[]`を使用します。この機能強化により、パイプラインの設定において、より柔軟で強力な入力補間機能が提供され、追加の処理ステップなしで個々の配列項目を直接参照できるようになります。

### パイプライン入力に複数の値を選択 {#select-multiple-values-for-pipeline-inputs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../ci/inputs/_index.md#array-inputs-with-options)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/566155)

{{< /details >}}

以前は、UIで入力オプションを選択する際に単一の値しか選択できず、より複雑なオプションを持つパイプラインの柔軟性が制限されていました。

今回のリリースから、UIから入力を含むパイプラインを実行する際、ドロップダウンリストから複数の値を選択でき、選択された値は例えば`["option1","option2"]`のように配列に結合されます。これにより、複数のインスタンスでサービスを再起動したり、複数のDockerイメージをビルドしたり、複数のタグの組み合わせでテストを実行したり、単一のパイプライン実行で複数のターゲットにわたるあらゆる操作を簡単に実行できます。

### CI/CDカタログコンポーネントの詳細な使用状況分析 {#detailed-ci-cd-catalog-component-usage-analytics}

<!-- categories: Component Catalog -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../ci/components/_index.md#view-component-usage-details)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/579460)

{{< /details >}}

GitLabカタログでCI/CDコンポーネントを管理する場合、使用状況の詳細はアップグレードの管理、コンプライアンスの適用、破壊的な変更の伝達に不可欠です。どのプロジェクトがコンポーネントを使用しているか、どのバージョンを使用しているかを把握する必要があります。以前はこの情報が利用できなかったため、適切なメンテナーへの通知、安全な廃止計画、またはプロジェクトが最新のセキュリティパッチに追従していることの確認が困難でした。

カタログリソースページのコンポーネント使用状況詳細ビューには、各コンポーネントを使用しているプロジェクト、実行中のバージョン、最新バージョンか古いバージョンかが正確に表示されるようになりました。古いバージョンを使用しているプロジェクトは上部に表示されるため、アウトリーチを優先し、セキュリティ修正の採用を促進し、組織全体でスムーズなアップグレードパスを確保できます。

### マージトレインの並列パイプライン制限の設定 {#configure-parallel-pipeline-limits-for-merge-trains}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../administration/cicd/limits.md#merge-train-parallel-pipeline-limit)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/374188)

{{< /details >}}

以前のバージョンのGitLabでは、マージトレインの最大20並列パイプラインを変更できなかったため、Runnerに過負荷をかけるか、マージトレインを完全にスキップするかの二択を迫られていました。これで、マージトレインごとの並列パイプライン制限を設定して、Runnerの負荷とマージスループットのバランスを取ることができます。制限はプロジェクトごとまたはインスタンス全体で設定できます。制限を1に設定すると、各マージリクエストはクリーンなターゲットブランチに対して1つずつ実行されます。

このコミュニティへのコントリビュートに感謝します [Norman Debald (@Modjo85)](https://gitlab.com/Modjo85)。

### デフォルトのマージリクエストタイトルのカスタマイズ {#customize-default-merge-request-titles}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/project/merge_requests/title_templates.md)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/16080)

{{< /details >}}

以前のバージョンのGitLabでは、新しいマージリクエストのデフォルトタイトルはソースブランチまたは最初のコミットから取得されており、プロジェクト全体で一貫した命名規則を適用することができませんでした。

これで、プロジェクトごとにデフォルトのマージリクエストタイトルテンプレートを設定できます。テンプレートはソースブランチ、ターゲットブランチ、最初のコミットの件名、リンクされたイシューID、イシュータイトル、ソースブランチ名を読みやすく整形した変数をサポートしています。例えば、テンプレート`Resolve %{issue_id} "%{issue_title}"`は`Resolve 123 "Fix login bug"`のようなタイトルを生成します。マージリクエストを作成する前にタイトルを編集することもできます。

### HMAC署名トークンでWebhookを保護する {#secure-webhooks-with-hmac-signing-tokens}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../user/project/integrations/webhooks.md#signing-tokens)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/19367)

{{< /details >}}

既存の`X-Gitlab-Token`ヘッダーは静的なシークレットを平文で送信するため、Webhookは傍受やリプレイ攻撃に対して脆弱です。

これで、任意のWebhookに署名トークンを追加できます。GitLabは、署名トークンを使用して以下のHMAC-SHA256署名を算出します:

- 一意のWebhook ID。
- リクエストのタイムスタンプ。
- Webhookペイロード。

GitLabは、[Standard Webhooks](https://www.standardwebhooks.com/)仕様に従い、`webhook-id`および`webhook-timestamp`ヘッダーとともに、結果を`webhook-signature`ヘッダーで送信します。

署名を再計算することで、リクエストがGitLabから真正に送信されたものであり、ペイロードが変更されていないことを確認できます。タイムスタンプも検証することで、リプレイされたリクエストを拒否できます。

[Van Anderson](https://gitlab.com/van.m.anderson)と[Norman Debald](https://gitlab.com/Modjo85)のコミュニティへのコントリビュートに感謝します！

### CI/CDジョブトークンを使用したクロスプロジェクトプッシュ {#cross-project-pushes-using-ci-cd-job-tokens}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](../../ci/jobs/ci_job_token.md#allow-cross-project-git-push-requests-from-allowlisted-projects)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/479907)

{{< /details >}}

以前のバージョンのGitLabでは、CI/CDジョブトークン（`CI_JOB_TOKEN`）を使用してパイプラインが実行される同じリポジトリにのみプッシュできました。クロスプロジェクトプッシュにはパーソナルアクセストークンまたはデプロイトークンが必要でした。

以下の条件を満たす場合、ジョブトークンを使用して別のプロジェクトにプッシュできるようになりました:

1. ターゲットプロジェクトがオプトインしている。
1. パイプラインを開始するユーザーがターゲットプロジェクトで少なくともデベロッパーロールを持っている。

この機能は`allow_push_to_allowlisted_projects`機能フラグで制御されており、GitLab 19.0ではデフォルトで無効になっています。管理者に有効化を依頼してください。

### Mermaidダイアグラムのレンダリングをバージョン11にアップグレード {#mermaid-diagram-rendering-upgraded-to-version-11}

<!-- categories: Markdown -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/markdown.md#mermaid)、[関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/work_items/491514)

{{< /details >}}

GitLabのMarkdownにおけるダイアグラムのレンダリングに[Mermaidバージョン11](../../user/markdown.md#mermaid)が使用されるようになりました。

以前はMermaidバージョン10がサポートされていました。このアップグレードにより、フローチャートやシーケンスダイアグラムのレンダリング改善をはじめ、Mermaid 11で導入されたすべての新しいダイアグラムタイプ、構文の改善、バグ修正を利用できます。

### マージリクエストレビューのRapid Diffs（ベータ版） {#rapid-diffs-for-merge-request-reviews-beta}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/project/merge_requests/changes.md#rapid-diffs)、[関連イシュー](https://gitlab.com/groups/gitlab-org/-/work_items/18457)

{{< /details >}}

以前のバージョンのGitLabでは、レビューを開始する前に**変更**タブがすべてのファイルを読み込むのを待つ必要があり、大規模なレビューが遅くなっていました。

これからは、Rapid Diffsを使用して、より速い初期読み込み、スムーズなスクロール、ファイル間のより応答性の高いインタラクションでマージリクエストをレビューできます。Rapid Diffsは、コミットページで既に使用されているのと同じ技術を使用しています。

Rapid Diffsはベータ版です。クラシックdiffエクスペリエンスの一部の機能はまだ利用できません。いつでも切り替えることができます。

[概要ビデオを視聴](https://www.youtube.com/watch?v=S-IzJnhoH6U)して、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/596236)で感想を共有してください。

### GitLab Runner 19.0 {#gitlab-runner-19-0}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated、GitLab Dedicated for Government
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 19.0もリリースします！GitLab Runnerは、CI/CDジョブを実行し、結果をGitLabインスタンスに返送する高いスケーラビリティを備えたビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#what-s-new}

- [Runnerインストルメンテーション: 機能ネゴシエーション、OTLPエクスポートクライアント、最初の`job_execution`スパン](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39231)
- [Runner設定に設定可能なprepareステージタイムアウトを追加](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/26583)

#### バグ修正 {#bug-fixes}

- [`FF_SCRIPTS_TO_STEPS`機能フラグ実装の包括的な修正](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39403)
- [S3キャッシュのダウンロード時の`SignatureDoesNotMatch`エラー](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39402)
- [GitLab RunnerがS3キャッシュを使用してAWSで実行される際のランタイムエラー](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39386)
- [GitLab Runner 18.9.0以降の`amd64`、`arm64`、`arm`、`armhf`向けRPM S3ダウンロードリンクの破損](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39362)
- [Windowsで負の終了コードが正しく報告されない](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39292)
- [Kubernetesエグゼキューターサービスコンテナの命名に関するドキュメントの誤り](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39235)

すべての変更のリストはGitLab Runnerの[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-0-stable/CHANGELOG.md)にあります。
