---
stage: Release Notes
group: Monthly Release
date: 2024-03-21
title: "GitLab 16.10リリースノート"
description: "GitLab 16.10はセマンティックバージョニングを伴うCI/CDカタログでリリースされました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024年3月21日、GitLab 16.10は以下の機能とともにリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター {#this-months-notable-contributor}

[Lennard Sprong](https://gitlab.com/X_Sheep)は以前、15.4でGitLab MVPアワードを受賞し、16.9でもノミネートされました。彼は過去2か月間で8件のコントリビュートをマージし、VS Code用GitLab Workflowにコントリビュートを提供し続けています。彼の過去のコントリビュートには、実行中のCIジョブのトレースを[監視する](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/674)機能、ダウンストリームパイプラインを[表示する](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/1336)機能、およびマージリクエストで画像を[比較する](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/1319)機能が含まれます。Lennardは[GitLab-vscode-extension](https://gitlab.com/gitlab-org/gitlab-vscode-extension)プロジェクト内のイシューにも積極的に関わっています。

GitLabのスタッフフルスタックエンジニアである[Erran Carey](https://gitlab.com/erran)は、Lennardをノミネートし、「LennardはGitLab Community Editionユーザーに影響を与えている[パイプラインの表示イシュー](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1000)を解決しました。」と述べました。彼は影響を受けているユーザーに既存の回避策を示し、その後[マージリクエストを作成して](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/1417)そのイシューに対処しました。」

GitLabのスタッフフルスタックエンジニアである[Tomas Vik](https://gitlab.com/viktomas)は、Lennardをさらにサポートし、[画像差分のサポートを追加する](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/1319)コントリビュートを強調しました。これにより、マージリクエストのレビュー中に画像の変更を表示できます。

[Marco Zille](https://gitlab.com/zillemarco)もまた、以前15.3で受賞したのに続き、2度目のGitLab MVP賞を受賞しました。Marcoは今回のリリースでのコードコントリビュートだけでなく、GitLabのより広範なコントリビューターコミュニティをサポートする継続的な取り組み、コミュニティペアリングセッションの実施、GitLabチームメンバーとの協力、およびマージリクエストのレビューにおいても評価されました。

Marcoは[1つのジョブが失敗した直後にパイプラインをキャンセルする](https://gitlab.com/gitlab-org/gitlab/-/issues/23605)機能を追加しました。この機能はGitLab.comで有効になっており利用可能ですが、自己ホスト型インスタンスの場合はまだ機能フラグの背後にあります。16.11で誰でも利用できるようになります。

GitLabのシニアバックエンドエンジニアである[Allison Browne](https://gitlab.com/allison.browne)は、パイプライン実行において長年要望されていたこの機能リクエストを取り上げたMarcoをノミネートしました。GitLabの主席エンジニアである[Fabio Pitino](https://gitlab.com/fabiopitino)は、「Marcoは修正を実装しただけでなく、この機能の設計に貢献し、ユースケースを持ち込んで、この機能に興味のある顧客と議論しました。」と付け加えました。

[Peter Leitzen](https://gitlab.com/splattael)もまた、MarcoがSentryからスタックトレースを[読み込む修正をレビューし完了させる](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112813#note_1737719869)のをどのように支援したかを強調し、Marcoのノミネートを支持しました。

LennardとMarcoによるGitLabの改善とオープンソースコミュニティへの継続的なサポートに深く感謝いたします！ 🙌

## 主要な機能 {#primary-features}

### CI/CDカタログにおけるセマンティックバージョニング {#semantic-versioning-in-the-cicd-catalog}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/components/_index.md#component-versions) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/442238)

{{< /details >}}

公開されたコンポーネント全体で一貫した動作を強制するために、GitLab 16.10ではCI/CDカタログに公開されるコンポーネントに対してセマンティックバージョニングを適用します。コンポーネントを公開する場合、タグは3桁のセマンティックバージョニング標準（例: `1.0.0`）に従う必要があります。

`include: component`構文でコンポーネントを使用する場合、公開されたセマンティックバージョンを使用する必要があります。Using `~latest`は引き続きサポートされますが、常に最新の公開バージョンを返すため、破壊的な変更が含まれる可能性があるため、注意して使用する必要があります。ショートハンド構文はサポートされていませんが、今後のマイルストーンでサポートされる予定です。

### GitLab Duoアクセスガバナンス管理 {#gitlab-duo-access-governance-control}

<!-- categories: Duo Chat -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../user/gitlab_duo/turn_on_off.md)

{{< /details >}}

生成AIは作業プロセスに革命をもたらしており、プライバシー、コンプライアンス、または知的財産（IPの保護）を損なうことなく、これらのテクノロジーの導入を促進できるようになりました。

プロジェクト、グループ、またはインスタンスごとに、APIを使用してGitLab Duo AI機能を無効にできるようになりました。準備が整ったら、特定のプロジェクトまたはグループに対してGitLab Duoを有効にできます。これらの変更は、AI機能の制御をよりきめ細かくするための、予想される一連の作業の一部です。

### Wikiテンプレート {#wiki-templates}

<!-- categories: Wiki -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/wiki/_index.md#wiki-page-templates) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/16608)

{{< /details >}}

このバージョンのGitLabでは、Wikiにまったく新しいテンプレートが導入されています。これで、新しいページを作成したり、既存のページを変更したりする際に、テンプレートを作成して効率化できます。テンプレートは、Wikiリポジトリのテンプレートディレクトリに保存されているWikiページです。

この機能強化により、Wikiページのレイアウトをより一貫させ、ページの作成や再構築を高速化し、知識ベースで情報が明確かつ一貫して提示されるようにすることができます。

### 高性能DevOps分析のための新しいClickHouseインテグレーション {#new-clickhouse-integration-for-high-performance-devops-analytics}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/contribution_analytics/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/428260)

{{< /details >}}

The [コントリビュート分析レポート](../../user/group/contribution_analytics/_index.md)は、GitLab.comでClickHouseを使用する高度な分析データベースによってサポートされ、より高性能になりました。このアップグレードは、新しい広範な分析およびレポート機能の基盤を築き、複数のディメンションにわたる高性能な分析集計、フィルタリング、およびスライシングを提供できるようになりました。この機能に自己管理のお客様が追加できるようサポートすることは、[イシュー441626](https://gitlab.com/gitlab-org/gitlab/-/issues/441626)で提案されています。

Although ClickHouseはGitLabの分析機能を強化しますが、PostgreSQLやRedisに取って代わることを意図したものではなく、既存の機能は変更されません。

### GitLab PagesおよびAdvanced SearchはGitLab Dedicatedで利用可能 {#gitlab-pages-and-advanced-search-available-on-gitlab-dedicated}

<!-- categories: GitLab Dedicated -->

{{< details >}}

- プラン: Gold
- リンク: [ドキュメント](../../subscriptions/gitlab_dedicated/_index.md#available-features) | [関連イシュー](https://about.gitlab.com/dedicated/)

{{< /details >}}

すべての[GitLab Dedicatedインスタンス](https://about.gitlab.com/dedicated/)で[GitLab Pages](../../user/project/pages/_index.md)と[Advanced Search](../../user/search/advanced_search.md)が有効になりました。これらの機能はGitLab Dedicatedサブスクリプションに含まれています。

Advanced Searchにより、GitLab Dedicatedインスタンス全体で、より高速で効率的な検索が可能になります。Advanced Searchのすべての機能は、GitLab Dedicatedインスタンスで使用できます。

GitLab Pagesを使用すると、GitLab Dedicatedのリポジトリから直接静的ウェブサイトを公開できます。Pagesの一部の機能は、GitLab Dedicatedインスタンスでは[まだ利用できません](../../subscriptions/gitlab_dedicated/_index.md#gitlab-pages)。

### CIトラフィックをGeoセカンダリにオフロード {#offload-ci-traffic-to-geo-secondaries}

<!-- categories: Geo-replication -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../administration/geo/secondary_proxy/runners.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9779)

{{< /details >}}

CI RunnerのトラフィックをGeoセカンダリサイトにオフロードできるようになりました。クロスリージョントラフィックを削減しながら、より便利で経済的に運用および管理できる場所にRunnerフリートを配置できます。複数のセカンダリGeoサイトに負荷を分散します。プライマリサイトの負荷を軽減し、開発者トラフィックを処理するためのリソースを確保します。この設定後、デベロッパーエクスペリエンスは透過的でシームレスになります。ジョブの設定と設定のための開発者ワークフローは変更されません。

## 規模とデプロイ {#scale-and-deployments}

### GitLabチャートの改善 {#gitlab-chart-improvements}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/charts/)

{{< /details >}}

GitLab 16.10では、Kubernetes 1.24以前のバージョンへのGitLabのインストールサポートを削除しました。Kubernetes 1.24のKubernetesメンテナンスサポートは2023年7月に終了しました。

GitLab 16.10には、Kubernetes 1.27へのGitLabのインストールサポートが含まれています。詳細については、新しい[Kubernetesバージョンサポートポリシー](https://handbook.gitlab.com/handbook/engineering/careers/matrix/infrastructure/core-platform/distribution/)を参照してください。私たちの目標は、Kubernetesの新しいバージョンを公式リリースに近い形でサポートすることです。

### Omnibusの改善 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 16.10では、Patroniの新しいメジャーバージョン3.0.1が導入されます。このバージョンアップグレードにはダウンタイムが必要です。詳細と手順については、[GitLab 16の変更ページ](../../update/versions/gitlab_16_changes.md#16100)の16.10セクションを参照してください。

GitLab 16.10には、新しいバージョンのAlertmanager、つまりバージョン0.27も含まれています。最も注目すべきは、このバージョンにAPI v1の削除が含まれていることです。このリリースの詳細については、[Alertmanagerの変更履歴](https://github.com/prometheus/alertmanager/blob/v0.27.0/CHANGELOG.md#0270--2024-02-28)を参照してください。

GitLab 16.10には[Mattermost 9.5](https://docs.mattermost.com/deploy/mattermost-changelog.html#release-v9-5-extended-support-release)も含まれています。Mattermost 9.5には、さまざまなセキュリティアップデートとMySQL 5.7のサポートの非推奨化が含まれています。このバージョンのMySQLを使用しているユーザーは更新する必要があります。

### GraphQL APIを使用してEnterpriseユーザーでメンバーをフィルタリング {#filter-members-by-enterprise-users-with-graphql-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/graphql/reference/_index.md#groupgroupmembers) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/356062)

{{< /details >}}

GraphQL APIを使用すると、Enterpriseユーザーでグループメンバーをフィルタリングできるようになりました。

### ブロックされたユーザーはフォロワーリストから除外されます {#blocked-users-are-excluded-from-the-followers-list}

<!-- categories: User Profile -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/_index.md#follow-users) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/441774)

{{< /details >}}

以前は、あなたをフォローしているユーザーがブロックされた場合でも、そのユーザーはあなたのユーザープロファイルのフォロワーリストに表示されていました。GitLab 16.10以降、ブロックされたユーザーはフォロワーリストから非表示になります。ユーザーがブロック解除されると、フォロワーリストに再表示されます。

Thank you @SethFalco for this communityコントリビュート!

### REST APIで表示レベルごとにグループをフィルタリング {#filter-groups-by-visibility-in-the-rest-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/groups.md#list-groups) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/429314)

{{< /details >}}

これで、[Groups API](../../api/groups.md)で表示レベルごとにグループをフィルタリングできます。フィルタリングを使用して、特定の表示レベルを持つグループに焦点を当てることで、GitLabの実装を監査しやすくなります。

Thank you @imskr for this communityコントリビュート!

### プロジェクト削除機能の更新 {#updated-project-deletion-functionality}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/working_with_projects.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/443682)

{{< /details >}}

これで、プロジェクトリストで削除されたプロジェクトを識別しやすくなりました。GitLab 16.10以降、削除されたプロジェクトはプロジェクト概要ページのプロジェクトタイトルの横に`Pending deletion`バッジを表示します。アラートメッセージは、削除されたプロジェクトが読み取り専用であることを明確にしています。このメッセージはすべてのプロジェクトページで表示され、削除されたプロジェクトのサブページで作業している場合でも、このコンテキストが失われないようにします。

### Google Chatでスレッド通知をサポート {#threaded-notifications-supported-in-google-chat}

<!-- categories: Integrations -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/integrations/hangouts_chat.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/438452)

{{< /details >}}

以前は、GitLabからGoogle Chatのスペースに送信された通知は、指定されたスレッドへの返信として作成できませんでした。このリリースにより、同じGitLabオブジェクト（たとえば、イシューやマージリクエスト）に対して、Google Chatでスレッド通知がデフォルトで有効になります。

Thanks to [Robbie Demuth](https://gitlab.com/robbie-demuth) for [this communityコントリビュート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145187)!

### Webhookのカスタムペイロードテンプレート {#custom-payload-template-for-webhooks}

<!-- categories: Webhooks -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/integrations/webhooks.md#custom-webhook-template) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/362504)

{{< /details >}}

以前は、GitLab Webhookは特定のJSONペイロードのみ送信でき、受信側のエンドポイントはWebhookフォーマットを理解する必要がありました。これらのWebhookを使用するには、GitLabを特にサポートするアプリを使用するか、独自のエンドポイントを記述する必要がありました。

このリリースにより、Webhook設定でカスタムペイロードテンプレートを設定できるようになりました。リクエストボディは、現在のイベントのデータを使用してテンプレートからレンダリングされます。

[Niklas](https://gitlab.com/Taucher2003)の[コミュニティコントリビュート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142738)に感謝します！

### UIとAPIからサービスデスクチケットを作成 {#create-service-desk-tickets-from-the-ui-and-api}

<!-- categories: Service Desk -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/service_desk/using_service_desk.md#create-a-service-desk-ticket-in-gitlab-ui) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/433376)

{{< /details >}}

通常のイシューで`/convert_to_ticket user@example.com`クイックアクションを使用して、UIとAPIからサービスデスクチケットを作成できるようになりました。

通常のイシューを作成し、`/convert_to_ticket user@example.com`クイックアクションを使用してコメントを追加します。提供されたメールアドレスがチケットの外部作成者になります。GitLabは[デフォルトのお礼メール](../../user/project/service_desk/configure.md)を送信しません。チケットに公開コメントを追加して、外部の参加者にチケットが作成されたことを知らせることができます。

サービスデスクチケットをAPIを使用して追加する際も同じ概念に従います: [イシューAPI](../../api/issues.md)を使用してイシューを作成し、`issue_iid`を使用して[Notes API](../../api/notes.md)を使用したクイックアクションでメモを追加します。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### マージリクエスト内の生成されたファイルを自動的に折りたたむ {#automatically-collapse-generated-files-in-merge-requests}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/project/merge_requests/changes.md#collapse-generated-files)

{{< /details >}}

マージリクエストには、ユーザーからの変更や自動プロセス、またはコンパイラからの変更が含まれる場合があります。`package-lock.json`、`Gopkg.lock`、および縮小された`js`と`css`のようなファイルは、マージリクエストのレビューに表示されるファイル数を増やし、レビュアーの注意を人間が生成した変更からそらします。マージリクエストは、これらのファイルをデフォルトで折りたたんで表示するようになりました。これは、以下の目的に役立ちます:

- レビュアーの注意を重要な変更に集中させますが、必要に応じて完全なレビューを有効にできます。
- マージリクエストを読み込むために必要なデータ量を削減し、より大規模なマージリクエストのパフォーマンス向上に役立つ可能性があります。

デフォルトで折りたたまれるファイルタイプの例については、[ドキュメント](../../user/project/merge_requests/changes.md#collapse-generated-files)を参照してください。マージリクエストでさらに多くのファイルとファイルタイプを折りたたむには、プロジェクトの`.gitattributes`ファイルでそれらを`gitlab-generated`として指定します。

この変更に関するフィードバックは[イシュー438727](https://gitlab.com/gitlab-org/gitlab/-/issues/438727)で残すことができます。

### マージウィジェットの拡張チェック {#expanded-checks-in-merge-widget}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/project/merge_requests/auto_merge.md)

{{< /details >}}

マージウィジェットは、マージリクエストがマージ可能でない場合、その理由を明確に説明します。以前は、一度に1つのマージブロッカーのみが表示されていました。これにより、レビューサイクルが増加し、さらに多くのブロッカーが残っているかどうかわからずに、個別に問題を解決することを余儀なくされました。

マージリクエストを表示すると、マージウィジェットは、残っている問題と解決された問題の両方を包括的に表示します。これで、複数のブロッカーが存在するかどうかを一目で理解し、1つのイテレーションでそれらすべてを修正し、隠れたブロッカーが見逃されていないという自信を高めることができます。

### Kubernetes用ダッシュボードの手動更新 {#manually-refresh-the-dashboard-for-kubernetes}

<!-- categories: Environment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/kubernetes_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/429531)

{{< /details >}}

GitLab 16.10では、Kubernetes用ダッシュボードに専用の更新機能が追加されました。これで、Kubernetesリソースデータを手動でフェッチし、クラスターに関する最新情報にアクセスできるようになりました。

### 環境詳細ページの改善 {#improved-environment-details-page}

<!-- categories: Environment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/431746)

{{< /details >}}

GitLab 16.10では、環境詳細ページが改善されました。環境リストから環境を選択すると、デプロイと接続されているKubernetesクラスターに関する最新情報を、1つの便利なレイアウトでレビューできます。

### 認証レート制限のエラーメッセージを改善 {#improved-error-message-for-authentication-rate-limit}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../security/rate_limits.md#failed-authentication-ban-for-git-and-container-registry) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/22787)

{{< /details >}}

GitLabで認証する際に、スクリプトを使用している場合などに、認証試行レート制限に達する可能性があります。以前は、認証レート制限に達した場合、`403 Forbidden`メッセージが返され、このエラーが発生する理由が説明されていませんでした。これで、認証レート制限に達したことを知らせる、より詳細なエラーメッセージが返されるようになりました。

### 監査イベントの`scope`属性 {#audit-event-scope-attribute}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

監査イベントに`scope`属性が含まれるようになり、イベントがインスタンス全体、グループ、プロジェクト、またはユーザーに関連付けられているかどうかを示します。

この新しい属性は、ユーザーが監査イベントペイロードでイベントの発生元を特定するのに役立ちます。また、[監査イベントタイプドキュメント](../../administration/compliance/audit_event_reports.md)が、監査イベントタイプで利用可能なすべてのスコープをリストすることを可能にします。

この新しい属性を使用して、外部ストリーミング先を解析するか、イベントに関するコンテキストをよりよく理解することができます。

### サービスアカウントのカスタム名 {#custom-names-for-service-accounts}

<!-- categories: User Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/service_accounts.md#create-a-service-account) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/415973)

{{< /details >}}

これで、サービスアカウントのユーザー名と表示名をカスタマイズできるようになりました。以前は、これらはGitLabによって自動生成されていました。カスタム名を使用することで、サービスアカウントの目的を理解し、ユーザーリスト内の他のアカウントと区別しやすくなります。

### カスタムロールの割り当てに関する監査イベント {#audit-event-for-assigning-a-custom-role}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/compliance/audit_event_reports.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/427954)

{{< /details >}}

GitLabは、ユーザーに異なるロールが割り当てられたときに、そのロールがデフォルトロールであるかカスタムロールであるかにかかわらず、監査イベントを記録するようになりました。このイベントは、特権昇格の場合にユーザー権限が追加または変更されたかどうかを特定するために重要です。

### カスタムロールの新しい権限 {#new-permissions-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/custom_roles/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

カスタムロールを作成するには、2つの新しい権限を選択できます:

- CI/CD変数を管理
- グループを削除する機能

これらのカスタム権限のリリースにより、これらのオーナーと同等の権限を持つカスタムロールを作成することで、グループで必要なオーナーの数を減らすことができます。カスタムロールを使用すると、ユーザーにその職務に必要な権限のみを与えるきめ細かいロールを定義し、不要な特権昇格を減らすことができます。

### スキャン結果ポリシーは「マージリクエスト承認ポリシー」になりました {#scan-result-policies-are-now-merge-request-approval-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9850)

{{< /details >}}

プロジェクト設定の上書きと承認要件の適用をサポートするためにポリシータイプの機能を拡張したため、ポリシー名をより適切な「マージリクエスト承認ポリシー」に更新しました。

マージリクエスト承認ポリシーは、既存の承認ルールを置き換えたり、競合したりするものではありません。代わりに、Ultimateプランのお客様には、中央のセキュリティおよびコンプライアンスチームによって管理されるポリシーを通じて、プロジェクト全体でグローバルな強制を適用する機能を提供します。これは、大規模な組織にとってますます困難なタスクです。

### Webhookは相互TLSをサポート {#webhooks-support-mutual-tls}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/project/integrations/webhooks.md#configure-webhooks-to-support-mutual-tls) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/27450)

{{< /details >}}

これで、Webhookが相互TLSをサポートするように設定できます。この設定は、Webhookソースの信頼性を確立し、セキュリティを強化します。PEM形式のクライアント証明書を設定します。これはTLSハンドシェイク中にサーバーに提示されます。PEMパスフレーズで証明書を保護することもできます。

### サインインページの改善 {#sign-in-page-improvements}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](https://gitlab.com/gitlab-org/gitlab/-/issues/412845) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/412845)

{{< /details >}}

GitLabサインインページは、スペーシングイシュー、壊れた要素、およびアラインメントを修正する改善により更新されました。ダークモードの追加サポートと、Cookie設定を管理するボタンもあります。これらの改善の組み合わせにより、サインインページは新鮮な外観と改善された機能を提供します。

### Active Directory LDAPのスマートカードサポート {#smart-card-support-for-active-directory-ldap}

<!-- categories: User Management -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../administration/auth/smartcard.md#authentication-against-an-active-directory-ldap-server) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/328074)

{{< /details >}}

LDAPサーバーに対するスマートカード認証は、Entra ID（旧Azure Active Directory）をサポートするようになりました。これにより、Entra IDからユーザーIDデータを同期し、スマートカードを使用してLDAPに対して認証することが容易になります。

### マージベースパイプラインを使用したマージリクエスト承認ポリシーの比較 {#use-merge-base-pipeline-for-merge-request-approval-policy-comparison}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#understanding-merge-request-approval-policy-approvals) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/428518)

{{< /details >}}

この機能強化により、マージリクエスト承認ポリシーの評価ロジックがセキュリティMRウィジェットと整合し、マージリクエスト承認ポリシーに違反する検出結果がウィジェットに表示される結果と一致するようにします。ロジックを整合させることで、セキュリティ、コンプライアンス、および開発チームは、どの検出結果がポリシーに違反し、承認が必要かをより一貫して特定できます。ターゲットブランチの最新の完了した`HEAD`パイプラインと比較するのではなく、スキャン結果ポリシーは共通の祖先の最新の完了したパイプラインである「マージベース」と比較するようになりました。

### GitLab Pagesのドメインレベルリダイレクトをサポート {#support-domain-level-redirects-for-gitlab-pages}

<!-- categories: Pages -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/pages/redirects.md#domain-level-redirects) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/601)

{{< /details >}}

以前は、GitLabはシンプルなリダイレクトルールをサポートすることに重点を置いていました。GitLab 14.3で、[私たちは](https://gitlab.com/gitlab-org/gitlab-pages/-/merge_requests/458) Splatおよびプレースホルダーリダイレクトのサポートを導入しました。

GitLab 16.10以降、GitLab Pagesはドメインレベルリダイレクトをサポートします。ドメインレベルリダイレクトを[Splatルール](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/601)と組み合わせて、URLパスを動的に書き換えることができます。この改善により、混乱を防ぎ、ドメイン変更後も古いドメインを使用している場合でも情報を引き続き見つけられるようになります。

### 新しいコンテナレジストリAPIでリポジトリタグをリスト表示 {#list-repository-tags-with-the-new-container-registry-api}

<!-- categories: Container Registry -->

{{< details >}}

- プラン: Free、Silver、Gold
- リンク: [ドキュメント](../../api/container_registry.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10208)

{{< /details >}}

以前は、コンテナレジストリはGitLabでタグを表示するために、Docker/OCIの[イメージタグレジストリAPIのリスト](https://gitlab.com/gitlab-org/container-registry/-/blob/5208a0ce1600b535e529cd857c842fda6d19ad59/docs/spec/docker/v2/api.md#listing-image-tags)に依存していました。このAPIには、パフォーマンスと検出可能性に重大な制限がありました。

このAPIは、レジストリに対するネットワークリクエストの数がタグリスト内のタグの数に応じてスケールするため、パフォーマンスが低下していました。さらに、APIが公開時間を追跡しなかったため、公開タイムスタンプがしばしば不正確でした。また、DockerマニフェストリストまたはOCIインデックスに基づいて画像を表示する場合、多重アーキテクチャ画像などの制限がありました。

これらの制限に対処するため、新しいレジストリ[のリポジトリタグをリストするAPI](https://gitlab.com/gitlab-org/container-registry/-/blob/5208a0ce1600b535e529cd857c842fda6d19ad59/docs/spec/gitlab/api.md#list-repository-tags)を導入しました。GitLab 16.10では、新しいAPIへの移行が完了しました。これで、UIまたはREST APIのどちらを使用する場合でも、パフォーマンスの向上、正確な公開タイムスタンプ、およびマルチアーキテクチャイメージの堅牢なサポートが期待できます。

この改善はGitLab.comでのみ利用可能です。次世代コンテナレジストリが一般提供されるまで、自己管理サポートはブロックされます。詳細については、[イシュー423459](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)を参照してください。

### Value Streamsダッシュボードの新しいコントリビューター数メトリクス {#new-contributor-count-metric-in-the-value-streams-dashboard}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/analytics/value_streams_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/433353)

{{< /details >}}

ソフトウェアリーダーがチームの開発速度、ソフトウェアの安定性、セキュリティ露出、チームの生産性の関係に関するインサイトを得ることを可能にするために、Value Streamsダッシュボードに新しい[**コントリビューター数**メトリクス](../../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports)を導入しました。このコントリビューター数は、グループ内でのコントリビュートを持つ月間ユニークユーザーの数を表します。このメトリクスは、時間の経過に伴う導入トレンドを追跡するように設計されており、[コントリビュートカレンダーイベント](../../user/profile/contributions_calendar.md#user-contribution-events)に基づいています。

The **コントリビューター数**メトリクスはGitLab.comでのみ利用可能で、[コントリビュート分析レポートがClickHouseを介して実行されるように設定](../../user/group/contribution_analytics/_index.md#contribution-analytics-with-clickhouse)する必要があります。[イシュー441626](https://gitlab.com/gitlab-org/gitlab/-/issues/441626)は、この機能を自己管理のお客様にも利用可能にする取り組みを追跡しています。

### シームレスで正確なワークフロー分析のためのバリューストリーム分析における継承されたフィルター {#inherited-filters-in-value-stream-analytics-for-seamless-and-accurate-workflow-analysis}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/issues_analytics/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/439615)

{{< /details >}}

[バリューストリーム分析](../../user/group/value_stream_analytics/_index.md)は、**リードタイム**タイルから[**イシュー分析**レポート](../../user/group/issues_analytics/_index.md)にドリルダウンする際に、同じフィルターを適用するようになりました。フィルターの継承は、分析ビューを切り替える際に、データに深くシームレスに掘り下げるのに役立ちます。

### クイックアクションでイシューを現在のまたは次のイテレーションに追加 {#add-an-issue-to-the-current-or-next-iteration-with-a-quick-action}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/quick_actions.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/384885)

{{< /details >}}

`/iteration`クイックアクションは、`--current`または`--next`引数を持つケイデンス参照を受け入れるようになりました。グループに単一のイテレーションケイデンスがある場合、`/iteration --current|next`を使用してイシューを現在のまたは次のイテレーションに迅速に割り当てることができます。グループに複数のイテレーションケイデンスが含まれている場合、ケイデンス名またはIDを参照して、クイックアクションで目的のケイデンスを指定できます。たとえば、`/iteration [cadence:"<cadence name>"|<cadence ID>] --next|current`などです。

### コンテナスキャンのデフォルトで継続的脆弱性スキャンが利用可能 {#continuous-vulnerability-scanning-available-by-default-for-container-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/continuous_vulnerability_scanning/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10174)

{{< /details >}}

コンテナスキャンの継続的脆弱性スキャンがデフォルトで利用可能になりました。デフォルトで利用可能になったことにより、機能フラグを介してこの機能を選択する必要がなくなります。継続的脆弱性スキャンの利点の詳細については、ドキュメントリンクを参照してください。

### sbtの依存関係スキャンサポートを改善 {#improved-dependency-scanning-support-for-sbt}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#supported-languages-and-package-managers) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390287)

{{< /details >}}

sbtを使用するプロジェクトの依存関係リストを生成するために使用するメカニズムを更新しました。この変更は、sbtバージョン1.7.2以降を使用するプロジェクトにのみ適用されます。sbtプロジェクトの依存関係スキャンを最大限に活用するには、sbtバージョン1.7.2以降にアップグレードする必要があります。

### DASTアナライザーのパフォーマンス更新 {#dast-analyzer-performance-updates}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/application_security/dast/browser/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/12194)

{{< /details >}}

16.10リリースマイルストーン中、プロキシベースのDASTは以下の通りでした:

- ZAPをバージョン2.14.0にアップグレードしました。詳細については、[イシュー442056](https://gitlab.com/gitlab-org/gitlab/-/issues/442056)を参照してください。

また、以下のブラウザベースのDASTクローラーのパフォーマンス改善を完了しました:

- クローリング時に作成されるgoroutineの数を制限します。詳細については、[イシュー440151](https://gitlab.com/gitlab-org/gitlab/-/issues/440151)を参照してください。
- インタラクトする要素の検出を最適化します。これにより、スキャン時間が6％短縮されました。詳細については、[イシュー440295](https://gitlab.com/gitlab-org/gitlab/-/issues/440295)を参照してください。
- DevToolsメッセージのJSONマーシャリング解除を最適化します。これにより、スキャン時間が7％短縮されました。詳細については、[イシュー439726](https://gitlab.com/gitlab-org/gitlab/-/issues/439726)を参照してください。

### GitLab Runner 16.10 {#gitlab-runner-1610}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 16.10もリリースします！GitLab Runnerは、CI/CDジョブを実行し、結果をGitLabインスタンスに送信する、軽量で拡張性の高いエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

バグ修正:

- [Runner Kubernetes executorでジョブがキャンセルされた場合のメモリリーク](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27857)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-10-stable/CHANGELOG.md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.10)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.10)
- [UI改善](https://papercuts.gitlab.com/?milestone=16.10)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
