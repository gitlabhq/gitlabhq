---
stage: Release Notes
group: Monthly Release
date: 2024-08-15
title: "GitLab 17.3リリースノート"
description: "GitLab 17.3が、根本原因分析による失敗したジョブのトラブルシューティング機能と共にリリースされました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024年8月15日、GitLab 17.3は以下の機能と共にリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: アントンカルミコフ {#this-months-notable-contributor-anton-kalmykov}

誰もがGitLabコミュニティのコントリビューターを[推薦](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)できます！活躍中の候補者を支援するか、新しい推薦を追加してください！ 🙌

アントンカルミコフは、今年、GitLabのトップコントリビューターの1人であり、2月以降37の[マージされたコントリビュート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests?scope=all&state=merged&author_username=antonkalmykov)を達成し、さらに多くのコントリビュートが進行中です。アントンは、[Yolo group (Bombay Games)](https://yolo.com/)のシニアフロントエンドエンジニアです。

「GitLabへのコントリビュートは、最もやりがいがあり、意欲的で、刺激的な取り組みの1つです」とAntonは言います。「このような素晴らしい製品の作成と改善に携わる機会を大変嬉しく思います。この機会のおかげで、多くの新しいことを学びました。まだやるべきことはたくさんあります。私のMRをチェックし、指導し、適切に作業を行うのを手伝ってくれたGitLabチーム、特にそれらのメンバーには非常に感謝しています。」

アントンは、GitLabのシニアプロダクトマネージャーである[Christina Lohr](https://gitlab.com/lohrc)によってノミネートされました。彼女は、Tenant Scaleグループがいくつかのフロントエンドイシューで支援したことに対してです。

「基本的なワークフローのために取り組むべき小さなUX改善がまだたくさんあり、コミュニティからの助けを得てこれらの取り組みをより迅速に完了できることは素晴らしいことです」とChristinaは言います。「これらの改善はすべて、グループとプロジェクト間のより一貫したユーザーエクスペリエンスの作成に貢献しています。Antonさん、ありがとうございます。」

Antonと、GitLabを共創するオープンソースコントリビューターの皆様に深く感謝いたします！

## 主要な機能 {#primary-features}

### 根本原因分析によるジョブの失敗のトラブルシューティングを行う {#troubleshoot-failed-jobs-with-root-cause-analysis}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13080)

{{< /details >}}

根本原因分析が一般公開されました。根本原因分析を使用すると、CI/CDパイプラインで失敗したジョブのトラブルシューティングをより迅速に実行できます。このAIを利用した機能は、失敗したジョブログを分析し、ジョブ失敗の根本原因を迅速に特定し、修正を提案します。

### GitLab Duoのベータ版におけるヘルスチェック {#health-check-for-gitlab-duo-in-beta}

<!-- categories: Cloud Connector -->

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo/configure/_index.md#run-a-health-check-for-gitlab-duo) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/14518)

{{< /details >}}

Self-ManagedインスタンスでGitLab Duoのセットアップのトラブルシューティングができるようになりました。**管理者**エリアのGitLab Duoページで、**ヘルスチェックを実行する**を選択します。このヘルスチェックは一連の検証を実行し、GitLab Duoが動作していることを確認するための適切な是正措置を提案します。

GitLab Duoのヘルスチェックは、Self-ManagedとGitLab Dedicatedでベータ機能として利用可能です。

### GitLab UIからポッドを削除 {#delete-a-pod-from-the-gitlab-ui}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/kubernetes_dashboard.md#delete-a-pod) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/467653)

{{< /details >}}

Kubernetesで失敗したポッドを再起動したり削除したりする必要がありましたか？これまで、クラスターに接続するためにGitLabを離れて別のツールを使用し、ポッドを停止し、新しいポッドが起動するのを待つ必要がありました。GitLabはポッドの削除を内蔵でサポートするようになり、Kubernetesクラスターのトラブルシューティングをスムーズに行えるようになりました。

Kubernetesの[Kubernetes用ダッシュボード](../../ci/environments/kubernetes_dashboard.md)からポッドを停止できます。このダッシュボードには、クラスターまたはネームスペース全体のすべてのポッドが一覧表示されます。

### ローカルのターミナルからクラスターに簡単に接続する {#easily-connect-to-a-cluster-from-your-local-terminal}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/clusters/agent/user_access.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/463769)

{{< /details >}}

ローカルターミナルから、またはデスクトップのKubernetes GUIツールのいずれかを使用して、Kubernetesクラスターに接続しますか？GitLabでは、Kubernetes用エージェントの[ユーザーアクセス機能](../../user/clusters/agent/user_access.md)を使用してターミナルに接続できます。これまで、コマンドを見つけるにはGitLabの外に移動してドキュメントを参照する必要がありました。GitLabは、UIから接続コマンドを提供するようになりました。GitLabはユーザーアクセスの設定もサポートできます！

接続コマンドを取得するには、[Kubernetesダッシュボード](../../ci/environments/kubernetes_dashboard.md)または[エージェントリスト](../../user/clusters/agent/work_with_agent.md#view-your-agents)に移動します。

### AIで脆弱性を解決する {#resolve-a-vulnerability-with-ai}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10783)

{{< /details >}}

脆弱性の修正は、ユーザーが脆弱性を修正するための具体的なコード提案をAIが提供します。ボタンをクリックするだけで、[サポートされているCWE識別子のリスト](../../user/application_security/vulnerabilities/_index.md#supported-vulnerabilities-for-vulnerability-resolution)から任意のSAST脆弱性を解決するためのマージリクエストを開くことができます。

### 単一のプロジェクトに複数のコンプライアンスフレームワークを追加する {#add-multiple-compliance-frameworks-to-a-single-project}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/working_with_projects.md#add-a-compliance-framework-to-a-project) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13294)

{{< /details >}}

プロジェクトが特定のコンプライアンス要件を持っているか、追加の監視が必要であるかを識別するために、コンプライアンスフレームワークを作成できます。このコンプライアンスフレームワークは、適用されるプロジェクトにコンプライアンスパイプライン設定をオプションで適用できます。

これまで、ユーザーは1つのプロジェクトに1つのコンプライアンスフレームワークしか適用できず、プロジェクトに設定できるコンプライアンス要件の数が制限されていました。現在、ユーザーがプロジェクトごとに複数のコンプライアンスフレームワークを適用できる機能が提供されています。これにより、ユーザーは指定された時点で単一のプロジェクトに複数の異なるコンプライアンスフレームワークを適用できます。このリリースにより、プロジェクトに複数のコンプライアンスフレームワークを適用できます。その後、プロジェクトには各フレームワークのコンプライアンス要件が設定されます。

### AIインパクト分析: コード提案の受け入れ率とGitLab Duoシートの使用状況 {#ai-impact-analytics-code-suggestions-acceptance-rate-and-gitlab-duo-seats-usage}

<!-- categories: Value Stream Management, Code Suggestions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/471168)

{{< /details >}}

これら2つの新しいメトリクスは、GitLab Duoの有効性と利用状況を強調し、GitLab Duoがビジネス価値の提供に与える影響を組織が理解するのに役立つ[バリューストリームダッシュボード内のAIインパクト分析](https://about.gitlab.com/blog/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/)に現在含まれています。

**コード提案の受け入れ率**メトリクスは、開発者がGitLab Duoによって行われたコード提案をどのくらいの頻度で受け入れるかを示します。このメトリクスは、これらの提案の有効性と、コントリビューターがAI機能に抱く信頼の両方を反映しています。具体的には、このメトリクスは、過去30日間にGitLab Duoによって提供され、コードコントリビューターによって受け入れられたコード提案の割合を表します。

The **GitLab Duo seats assigned and used**メトリクスは、消費されたライセンスシートの割合を示し、組織がライセンス利用、リソース割り当て、および使用パターンを効果的に計画するのに役立ちます。このメトリクスは、過去30日間に少なくとも1つのAI機能を使用した割り当て済みシートの割合を追跡します。

これらの新しいメトリクスの追加に伴い、新しい概要タイルも導入しました。これはメトリクスの明確な概要を提供する新しい視覚化であり、AI機能の現在の状態を迅速に評価するのに役立ちます。

## 規模とデプロイ {#scale-and-deployments}

### Omnibusの改善 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 17.3には、[Raspberry Pi OS 12](https://www.raspberrypi.com/news/bookworm-the-new-version-of-raspberry-pi-os/)をサポートするパッケージが含まれています。

Debian 10は[2024年6月30日にEOL](https://www.debian.org/releases/buster/)に達しました。GitLabはGitLab 17.6でDebian 10のサポートを削除します。

### Your Workでのプロジェクトとグループの並べ替えとフィルタリングの改善 {#improved-sorting-and-filtering-for-projects-and-groups-in-your-work}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/working_with_projects.md#explore-all-projects-on-an-instance) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/25368)

{{< /details >}}

**Your Work**のプロジェクトとグループの概要におけるソートとフィルタリング機能が更新されました。以前は、プロジェクトの**Your Work**ページでは、名前と言語でフィルタリングし、事前に定義された並べ替えオプションのセットを使用できました。並べ替えオプションを標準化するために、**名前**、**作成日**、**更新した日**、および**Star付き**を含めました。また、昇順または降順でソートするためのナビゲーション要素を追加し、言語フィルターをフィルターメニューに移動しました。新しい**非アクティブ**タブでアーカイブされたプロジェクトを見つけることができます。さらに、自分がオーナーであるプロジェクトを検索できる**ロール**フィルターを追加しました。

グループのYour Workページでは、並べ替えオプションを標準化するために、**名前**、**作成日**、**更新した日**を含め、昇順または降順で並べ替えるためのナビゲーション要素を追加しました。

これらの変更に関するフィードバックは、[\#438322](https://gitlab.com/gitlab-org/gitlab/-/issues/438322)で歓迎します。

### 高度な検索のためのエンドツーエンドインスタンスのインデックス作成 {#end-to-end-instance-indexing-for-advanced-search}

<!-- categories: Global Search -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../integration/advanced_search/elasticsearch.md#index-the-instance) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/271532)

{{< /details >}}

GitLabで高度な検索を有効にすると、**インスタンスにインデックスを作成**を選択して、初期インデックス作成を実行したり、ゼロからインデックスを再作成したりできるようになります。この設定は、サポートされているすべての種類のデータを統合されたElasticsearchまたはOpenSearchクラスターにインデックス作成することで、`gitlab:elastic:index` Rakeタスクとの機能的な同等性を達成します。

**インスタンスにインデックスを作成**は、すべてのプロジェクトのインデックス作成設定を置き換えます。これは初期インデックス作成のみに限定されていました。

### APIを使用してインテグレーションの設定の継承を切替 {#toggle-inheriting-settings-for-integrations-by-using-the-api}

<!-- categories: Integrations -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/integrations/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/467089)

{{< /details >}}

これまで、プロジェクトがインテグレーション設定を継承するか、独自の設定を使用するかは、UIを使用してのみ制御できました。

このマイルストーンでは、すべてのインテグレーションのREST APIに新しい`use_inherited_settings`パラメータを導入します。このパラメータを使用すると、APIを使用して、プロジェクトがインテグレーション設定を継承するかどうかを設定できます。設定されていない場合、デフォルトの動作は`false`（プロジェクト自身の設定を使用）です。

### APIでグループまたはプロジェクトのWebhookイベントを一覧表示 {#list-group-or-project-webhook-events-with-the-api}

<!-- categories: Webhooks -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/project_webhooks.md#list-project-webhook-events) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/437188)

{{< /details >}}

GitLab 9.3以降、プロジェクトのWebhookリクエスト履歴をUIで表示できるようになり、GitLab 15.3以降では、[グループのWebhookリクエスト履歴もUIで表示](../../user/project/integrations/webhooks.md#view-webhook-request-history)できるようになりました。

このリリースでは、このデータがREST APIで公開され、Webhookエラーを検出して対応するプロセスを自動化するのに役立ちます。過去7日間の特定の[プロジェクトフック](../../api/project_webhooks.md#list-project-webhook-events)および[グループフック](../../api/group_webhooks.md#list-all-group-hook-events)のイベントリストを取得することができます。

[Phawin](https://gitlab.com/lifez)の[このコミュニティコントリビュート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151048)に感謝します！

### コマンドパレットを使用してグループ設定を見つける {#find-group-settings-by-using-the-command-palette}

<!-- categories: Settings, Global Search -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/search/command_palette.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/448646)

{{< /details >}}

17.2では、[コマンドパレットを使用してプロジェクト設定を検索する](https://about.gitlab.com/releases/2024/07/18/gitlab-17-2-released/#find-project-settings-by-using-the-command-palette)機能を追加しました。この変更により、必要な設定を迅速に見つけやすくなりました。

17.3では、コマンドパレットからグループ設定も検索できるようになりました。グループにアクセスし、**検索または移動先**を選択し、`>`でコマンドモードに入り、**マージリクエストの承認**のような設定セクションの名前を入力して試してみてください。結果を選択すると、設定自体に直接ジャンプします。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### VS Codeにおける言語ごとのコード提案のきめ細かな制御 {#granular-control-of-code-suggestions-by-language-in-vs-code}

<!-- categories: Editor Extensions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/project/repository/code_suggestions/supported_extensions.md#manage-languages-for-code-suggestions) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1388)

{{< /details >}}

VS Codeでのコーディングエクスペリエンスを、特定のプログラミング言語のコード提案を有効または無効にすることで、より細かく制御できます。このきめ細かい制御により、ワークフローをカスタマイズし、不要または邪魔な提案を減らしながら、好みの言語でのコード提案の利点を維持できます。

### JetBrains IDEにおけるTLSサポートの改善 {#improved-tls-support-in-jetbrains-ides}

<!-- categories: Editor Extensions -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md#certificate-errors) | [関連イシュー](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/371)

{{< /details >}}

機密性の高い環境でのセキュリティを強化するために、クライアント証明書や認証局を含むカスタムHTTPエージェントオプションを、JetBrains IDE設定で直接構成できるようになりました。

### より簡単にリポジトリからコンテンツを削除する {#more-easily-remove-content-from-repositories}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/repository/repository_size.md#remove-blobs)

{{< /details >}}

現在、リポジトリからコンテンツを削除するプロセスは複雑であり、プロジェクトをGitLabに強制プッシュする必要がある場合があります。これはエラーが発生しやすく、プッシュを有効にするために一時的に保護をオフにする原因となる可能性があります。リポジトリ内で過剰なスペースを使用するファイルを削除することはさらに困難な場合があります。

プロジェクト設定の新しいリポジトリメンテナンスオプションを使用して、オブジェクトIDのリストに基づいてblobを削除できるようになりました。この新しい方法を使用すると、プロジェクトをGitLabに強制プッシュする必要なく、選択的にコンテンツを削除できます。

シークレットやその他のコンテンツがプロジェクトから削除する必要がある場合にプッシュされた場合、テキストを削除する新しいオプションも導入します。GitLabがプロジェクト全体でファイル内の`***REMOVED***`に置き換える文字列を提供します。テキストが削除済みのになったら、ハウスキーピングを実行して文字列の古いバージョンを削除してください。

この新しいUIは、コンテンツを削除する必要がある場合にリポジトリを管理する方法を合理化します。

### Kubernetes用エージェントが作成および削除された際の監査イベント {#audit-event-when-agent-for-kubernetes-is-created-and-deleted}

<!-- categories: Audit Events -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/audit_event_types.md#deployment-management) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/462749)

{{< /details >}}

Kubernetes用エージェントはKubernetesクラスターとGitLab間の双方向データフローを可能にするため、システムにアクセスできるコンポーネントが追加または削除されたときにそれを把握することが重要です。過去のリリースでは、コンプライアンスチームはカスタムツールを使用するか、このデータをGitLabで直接検索する必要がありました。GitLabは以下の監査イベントを提供するようになりました:

- `cluster_agent_created`は、新しいKubernetes用エージェントを登録したユーザーを記録します。
- `cluster_agent_create_failed`は、新しいKubernetes用エージェントを登録しようとして失敗したユーザーを記録します。
- `cluster_agent_deleted`は、Kubernetes用エージェントの登録を削除したユーザーを記録します。
- `cluster_agent_delete_failed`は、Kubernetes用エージェントの登録を削除しようとして失敗したユーザーを記録します。

これらの監査イベントは、GitLabインスタンスを監査する能力をさらに向上させるために、`cluster_agent_token_created`および`cluster_agent_token_revoked`監査イベントを拡張します。

### Kubernetes 1.30のサポート {#kubernetes-130-support}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/456929)

{{< /details >}}

このリリースは、2024年4月にリリースされたKubernetesバージョン1.30の完全なサポートを追加します。アプリをKubernetesにデプロイする場合、接続されているクラスターを最新のバージョンにアップグレードし、すべての機能を活用できるようになりました。

[当社のKubernetesサポートポリシーおよびその他のサポートされているKubernetesバージョン](../../user/clusters/agent/_index.md#supported-kubernetes-versions-for-gitlab-features)の詳細については、こちらをご覧ください。

### マージリクエストの外部ステータスチェックに認証を追加 {#add-authentication-to-merge-request-external-status-checks}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/merge_requests/status_checks.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/433035)

{{< /details >}}

外部ステータスチェックは、HMAC (Hash-based Message Authentication Code) 認証で構成できるようになりました。これにより、GitLabから外部サービスへのリクエストの信頼性を検証するためのより安全な方法が提供されます。

ステータスチェックで有効にすると、共有シークレットが各リクエストの一意の署名を生成するために使用されます。シグネチャは、SHA256をハッシュアルゴリズムとして使用して、`X-Gitlab-Signature`ヘッダーで送信されます。

- セキュリティの向上: HMAC認証は、リクエストの改ざんを防ぎ、それらが正当なソースからのものであることを保証します。
- コンプライアンス: この機能は、セキュリティが最重要視される銀行などの規制された業界にとって特に価値があります。
- 後方互換性: この機能はオプションであり、後方互換性があります。ユーザーは新しいチェックまたは既存のチェックに対してHMAC認証を有効にすることを選択できますが、既存の外部ステータスチェックは変更なしで引き続き機能します。

[将来のイテレーション](https://gitlab.com/gitlab-org/gitlab/-/issues/476163)で、GitLabはHTTPリクエストも検証およびブロックするオプションを追加する予定です。

### グループまたはプロジェクトのメンバーリストをロールでフィルタリング {#filter-the-member-list-in-a-group-or-project-by-role}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/members/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/431397)

{{< /details >}}

ユーザーはメンバーページをロールでフィルタリングできるようになりました。フィルターを使用して、特定のロールを持つメンバーを検索します。

### 右側のドロワーでロールの詳細を表示 {#view-role-details-in-the-right-drawer}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/custom_roles/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/13061)

{{< /details >}}

これまで、ユーザーのカスタムロールの権限を表示するには、グループでオーナーロールを持っている必要がありました。この要件により、カスタムロールが割り当てられたユーザーが実行できるアクションをトラブルシューティングし、理解することが困難でした。現在、任意のユーザーがメンバーページでカスタムロールが割り当てられたユーザーの権限を表示できます。

### カスタムロールのLDAPグループリンクサポート {#ldap-group-link-support-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/access_and_permissions.md#manage-group-memberships-with-ldap) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/435229)

{{< /details >}}

グループのユーザー権限を管理するためにLDAPグループリンクを使用する組織は、メンバーシップにすでにデフォルトロールを使用できます。

このリリースでは、そのサポートを[カスタムロール](../../user/custom_roles/_index.md)に拡張しています。この設定により、多数のユーザーへのアクセスをマップすることが容易になります。

### カスタムロールの新しいパーミッション {#new-permission-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/custom_roles/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

以下の新しい権限でカスタムロールを作成できます:

- [Runnerの読み取り](../../user/custom_roles/abilities.md#runner)

カスタムロールを使用すると、同等の権限を持つユーザーを作成することで、オーナーロールを持つユーザーの数を減らすことができます。これにより、グループのニーズに合わせたロールを定義し、ユーザーが必要以上の権限を与えられるのを防ぐことができます。

### 管理者UIを使用してパーソナルアクセストークンを無効にする {#disable-personal-access-tokens-using-admin-ui}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/profile/personal_access_tokens.md#view-token-usage-information) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/436991)

{{< /details >}}

管理者は、管理者UIを通じてインスタンスパーソナルアクセストークンを無効または再有効化できるようになりました。これまで、管理者は、アプリケーション設定APIまたはRailsコンソールを使用してこれを行う必要がありました。

### ユーザープロファイルにおけるBluesky識別子 {#bluesky-identifier-in-user-profile}

<!-- categories: User Profile -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/_index.md#add-external-accounts-to-your-user-profile-page) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/451690)

{{< /details >}}

Blueskyのdid:plc識別子をGitLabプロフィールに追加できるようになりました。

[Dominique](https://domi.zip/)氏のコントリビュートに感謝します！

### サインアウト時にサブドメインクッキーを保持 {#subdomain-cookies-preserved-on-sign-out}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/active_sessions.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/471097)

{{< /details >}}

GitLabのサインアウトプロセスが改善され、サインアウト時に兄弟サブドメインのクッキーが削除されなくなりました。これまで、これらのクッキーは削除され、GitLabと同じトップレベルドメイン上の他のサブドメインサービスからユーザーがサインアウトされる原因となっていました。たとえば、ユーザーが`kibana.example.com`にKibanaを設定し、`gitlab.example.com`にGitLabを設定している場合、GitLabからサインアウトしても、Kibanaからサインアウトされることはなくなります。

[Guilherme C. Souza](https://gitlab.com/GCSBOSS)氏のコントリビュートに感謝します！

### 強化されたスパークライン傾向可視化によるAIインパクト分析 {#ai-impact-analytics-with-enhanced-sparklines-trend-visualization}

<!-- categories: Value Stream Management, Code Suggestions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/analytics/duo_and_sdlc_trends.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/464692)

{{< /details >}}

スパークラインの導入により、[AIインパクト分析](https://about.gitlab.com/blog/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/)が大幅に改善されたことを発表できることを嬉しく思います。データテーブルに埋め込まれたこれらの小さくてシンプルなグラフは、AI影響データの読みやすさとアクセス性を向上させます。数値データを視覚的に表現することで、新しいスパークラインは時間の経過とともにトレンドを特定しやすくし、上昇または下降の動きを把握できるようにします。この新しい視覚的なアプローチは、複数のメトリクス間のトレンド比較プロセスも合理化し、数値のみに頼る場合に必要となる時間と労力を削減します。

### タスクへのマージリクエストの追加 {#add-merge-requests-to-tasks}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/tasks.md#add-a-merge-request-and-automatically-close-tasks) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/440851)

{{< /details >}}

タスクは、イシューをエンジニアリングの実装ステップに分解するためによく使用されます。このリリースより前は、マージリクエストを、それが実装するタスクに接続する方法はありませんでした。マージリクエストの説明からイシューを参照するのと同じ[クローズパターン](../../user/project/issues/managing_issues.md#closing-issues-automatically)を使用して、マージリクエストをタスクに接続できるようになりました。タスクビューから、接続されたマージリクエストはサイドバーから表示されます。プロジェクトで[自動クローズ設定が有効](../../user/project/issues/managing_issues.md#disable-automatic-issue-closing)になっている場合、接続されたマージリクエストがデフォルトのブランチにマージされると、タスクは自動的に閉じられます。

### OKRとタスクの親アイテムを設定する {#set-parent-items-for-okrs-and-tasks}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/okrs.md#set-an-objective-as-a-parent) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11198)

{{< /details >}}

[OKR](../../user/okrs.md#set-an-objective-as-a-parent)と[タスク](../../user/tasks.md#set-an-issue-as-a-parent)の親の割り当てを、子レコードから直接簡単に更新できるようになり、行ったり来たりする必要がなくなりました。これは、[ワークフローの効率性を向上させる](https://gitlab.com/groups/gitlab-org/-/epics/10501)という私たちの目標に向けた大きな一歩です。

### タスク、目標、および主な成果アイテムに対する不正利用の報告 {#report-abuse-for-task-objective-and-key-result-items}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/report_abuse.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/461848)

{{< /details >}}

レガシーイシューと同様に、**アクション**メニューから直接作業アイテムに対する不正利用を簡単に報告できるようになりました。この新機能は、不適切なコンテンツを迅速にフラグ付けできるようにすることで、ワークスペースをクリーンで安全に保ち、チームにとってより良い共同作業環境を確保するのに役立ちます。

### タスク、目標、および主な成果内のスレッドを解決する {#resolve-threads-in-tasks-objectives-and-key-results}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/discussions/_index.md#resolve-a-thread) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/458818)

{{< /details >}}

タスク、目標と主な成果でスレッドを解決するできるようになり、重要な会話の管理と追跡が容易になりました。解決済みのスレッドはデフォルトで折りたたまれ、活発なディスカッションに集中し、コラボレーションワークフローを合理化するのに役立ちます。

### サイクルタイム削減のための新しいバリューストリーム分析パイプラインステージイベント {#new-value-stream-analytics-stage-events-for-cycle-time-reduction}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/value_stream_analytics/_index.md#value-stream-stage-events) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/466383)

{{< /details >}}

GitLabでのマージリクエスト（MR）レビュー時間の追跡を改善するため、[バリューストリーム分析](https://about.gitlab.com/solutions/value-stream-management/)に新しいパイプラインステージイベントを追加しました: **MR first reviewer assigned**。この新しいイベントにより、チームはレビュープロセスで遅延が発生する場所を特定し、コラボレーションを改善する機会を見つけ、チームメンバー間の応答性と責任の文化を奨励できます。レビュー時間を短縮することは、開発全体のサイクルタイムに直接影響し、[より速いソフトウエアデリバリーにつながります](https://about.gitlab.com/blog/three-steps-to-optimize-software-value-streams/)。たとえば、**MR first reviewer assigned**で始まり、**MR merged**で終わる新しいカスタム**Review Time to Merge (RTTM)** パイプラインステージを追加できるようになりました。

### 依存関係スキャンおよびライセンススキャンにおけるRustのサポート {#rust-support-for-dependency-and-license-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md#supported-languages-and-package-managers) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/13093)

{{< /details >}}

コンポジション解析は、依存関係およびライセンススキャンニングに対するRustのサポートを提供しました。Rustスキャンは`Cargo.lock`ファイルタイプをサポートしています。

プロジェクトのRustスキャンを有効にするには、[依存関係スキャンCI/CDコンポーネント](https://gitlab.com/explore/catalog/components/dependency-scanning)から`cargo`テンプレートを使用します。

### GitLab UIにSBOM取り込みエラーを表示 {#display-sbom-ingestion-errors-in-gitlab-ui}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_list/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/14408)

{{< /details >}}

GitLab 15.3は[CycloneDX SBOMのインジェスト](../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx)をサポートしました。SBOMレポートはCycloneDXスキーマに対して検証されますが、検証の一部として生成された警告やエラーはユーザーに表示されませんでした。

GitLab 17.3では、これらの検証メッセージがGitLab UIのプロジェクトレベルの脆弱性レポートページと依存関係リストページに表示されます。

ユーザーは、GitLab UIの以下の領域でSBOM取り込みエラーを表示できます: プロジェクトレベルの脆弱性レポートページと依存関係リストページ、パイプラインページのライセンスとセキュリティタブ。

### SAST、IaCスキャン、およびシークレット検出で使用されるルールセットを強制する {#enforce-the-ruleset-used-in-sast-iac-scanning-and-secret-detection}

<!-- categories: SAST, Secret Detection, Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/sast/customize_rulesets.md#use-a-remote-ruleset-file)

{{< /details >}}

[SAST](../../user/application_security/sast/customize_rulesets.md) 、[IaCスキャン](../../user/application_security/iac_scanning/_index.md#optimize-iac-scanning) 、および[シークレット検出](../../user/application_security/secret_detection/pipeline/configure.md#customize-analyzer-behavior)で使用されるルールは、リポジトリにコミットされたローカル設定ファイルを作成するか、CI/CD変数を設定して複数のプロジェクトに共有設定を適用することでカスタマイズできます。

これまで、スキャナーは、共有ルールセットの参照を設定した場合でも、ローカルの設定ファイルを優先していました。この優先順位により、スキャンが既知の信頼できるルールセットを使用することを保証することが困難でした。

ローカル設定ファイルが許可されるかどうかを制御する新しいCI/CD変数`SECURE_ENABLE_LOCAL_CONFIGURATION`が追加されました。デフォルトでは`true`であり、既存の動作を維持します。つまり、ローカル設定ファイルが許可され、共有設定よりも優先されます。[スキャン実行を強制](../../user/application_security/policies/scan_execution_policies.md)する際に値を`false`に設定すると、プロジェクト開発者がローカル設定ファイルを追加した場合でも、スキャンが共有ルールセットまたはデフォルトのルールセットを使用することが保証されます。

### ジョブ名でジョブをフィルタリング {#filter-jobs-by-job-name}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/jobs/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/387547)

{{< /details >}}

ジョブ名を検索することで、特定のジョブをすばやく見つけられるようになりました。

これまで、ジョブのリストはステータスでしかフィルタリングできず、特定のジョブを見つけるには手動でスクロールする必要がありました。このリリースにより、ジョブ名を入力して結果をフィルタリングできるようになりました。結果には、GitLab 17.3のリリース後に実行されたパイプライン内のジョブのみが含まれます。

### マージトレインの可視化 {#merge-train-visualization}

<!-- categories: Merge Trains -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/pipelines/merge_trains.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13705)

{{< /details >}}

マージトレインを視覚化して、パイプライン内のマージリクエストのステータスと順序に関するより良いインサイトを得られるようになりました。マージトレインの可視化により、競合をより早く特定し、マージトレイン内で直接マージリクエストに対するアクションを実行し、デフォルトブランチが破損するリスクを最小限に抑えることができます。

### GitLab Runner 17.3 {#gitlab-runner-173}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 17.3をリリースします！GitLab Runnerは、軽量で高度にスケールするエージェントであり、CI/CDジョブを実行し、結果をGitLabインスタンスに送り返します。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### バグ修正 {#bug-fixes}

- [Kubernetes Runnerでキャンセルされたジョブがハングアップするように見える](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37780)
- [指定されていない場合にログレベルが更新されない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37490)
- [Runner Kubernetes executorを使用するとジョブログに余分な改行が追加される](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27099)

すべての変更点のリストは、GitLab Runnerの[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-3-stable/CHANGELOG.md)を参照してください。

### macOS上のホストされたRunnerのパフォーマンス向上 {#improved-performance-for-hosted-runners-on-macos}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/hosted_runners/macos.md) | [関連イシュー](https://gitlab.com/gitlab-org/ci-cd/shared-runners/images/job-images/-/issues/6)

{{< /details >}}

macOS 14.5とXcode 15.4への最近のアップグレードにより、パフォーマンスの改善が提供されました。この変更により、Xcodeビルドジョブは、以前のジョブ実行と比較して大幅に高速化されました。

### CI/CDカタログコンポーネントの入力詳細に説明とタイプを追加 {#description-and-type-added-to-cicd-catalog-component-input-details}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/components/_index.md#cicd-catalog) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/426870)

{{< /details >}}

カタログ内のCI/CDコンポーネントの詳細ページには、そのコンポーネントに関する有用な情報が提供されます。このリリースでは、利用可能な入力に関する情報を示すテーブルにさらに2つの列を追加しました。新しい**説明**と**タイプ**の列により、入力が何に使用され、どのような値が期待されるかをはるかに簡単に理解できるようになります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.3)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.3)
- [UI改善](https://papercuts.gitlab.com/?milestone=17.3)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
