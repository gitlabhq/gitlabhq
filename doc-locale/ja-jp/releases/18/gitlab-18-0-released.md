---
stage: Release Notes
group: Monthly Release
date: 2025-05-15
title: "GitLab 18.0 リリースノート"
description: "GitLab 18.0 released with GitLab Premium and Ultimate with Duo"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年5月15日、GitLab 18.0が以下の機能とともにリリースされました。

また、今月の注目コントリビューターをはじめ、すべてのコントリビューターの皆様に感謝申し上げます。

## 今月の注目コントリビューター: Michael Hofer

Michael Hoferは、トップコントリビューターとコミュニティリーダーの両面からGitLabのオープンソースミッションを推進しています。
今年は[50件以上のコントリビュート](https://contributors.gitlab.com/users/karras?fromDate=2025-01-01&toDate=2025-05-12)を達成し、
OpenBaoをベースとしたGitLabのGeo機能とシークレットマネージャーの強化に貢献しました。
[4月のハッカソン](https://contributors.gitlab.com/hackathon?hackathonName=2025_04)でトップを獲得しながら、仲間のコントリビューターをサポートし、コミュニティプロジェクトをリードしました。

「誰もがGitLabにコントリビュートできることを心から嬉しく思います！」とMichaelは語ります。
「チームと一緒に働くのはとても楽しく、みんなが非常に協力的です。特にOpenBaoやSLSAのようなオープンソースの取り組みで協力するときはなおさらです。」

Michaelは[Adfinis](https://adfinis.com/en/)のCTOを務めています。Adfinisは、ミッションクリティカルなオープンソースワークロードの計画・構築・運用を専門とする国際的なITサービスプロバイダーです。
彼は組織全体でのコラボレーション促進とオープンソースソリューションの普及に情熱を注いでいます。

最近、AdfinisはGitLabの[共同開発プログラム](https://about.gitlab.com/community/co-create/)に参加しました。このプログラムは、組織とGitLabのプロダクト・エンジニアリングチームをペアリングし、
GitLabを共に構築するものです。
「すべての組織に共同開発プログラムを強くお勧めします」とMichaelは言います。「ルートレスPodmanビルド、Glimmer構文ハイライト、その他の改善など、多くの素晴らしいコントリビュートにつながりました。」

「GeoチームはMichaelと一緒に働くことを本当に喜んでいます」と、Michaelをこの賞に推薦したGitLabのエンジニアリングマネージャー[Lucie Zhao](https://gitlab.com/luciezhao)は語ります。
「ここ数マイルストーンにわたる優れたコントリビュートにより、彼はチーム内で最もよく知られたコミュニティコントリビューターになりました。」

GitLabチームメンバーの[Lee Tickett](https://gitlab.com/leetickett-gitlab)、[Chloe Fons](https://gitlab.com/c_fons)、[Alex Scheel](https://gitlab.com/cipherboy-gitlab)がこの推薦を支持しました。
Alexは次のように付け加えています。「OpenBaoにおけるMichaelのリーダーシップにより、GitLabの価値観に沿った透明性を持ちながら、お客様向けのシークレット管理ソリューションを効果的に協力して実現できました。」

MichaelとAdfinisチームのGitLab共同開発への貢献に感謝します！

## 主要機能

### GitLab Premium and Ultimate with Duo

<!-- categories: Code Suggestions, Duo Chat -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/538857)

{{< /details >}}

GitLab Premium with DuoおよびGitLab Ultimate with Duoの提供開始をお知らせします。GitLab PremiumおよびUltimateにAIネイティブ機能が含まれるようになりました。

GitLabのAIネイティブ機能には、IDE内でのコード提案とチャットが含まれます。開発チームはこれらの機能を活用して以下のことができます。

- コードの分析、理解、説明
- より安全なコードの迅速な作成
- コード品質を維持するためのテストの素早い生成
- パフォーマンス向上や特定ライブラリ使用のためのコードの簡単なリファクタリング

### GitLab Duo Self-HostedでリポジトリX-Rayが利用可能に {#repository-x-ray-now-available-on-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/project/repository/code_suggestions/repository_xray.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17756)

{{< /details >}}

GitLab Duo Self-Hostedでコード提案とともにリポジトリX-Rayが使用できるようになりました。この機能はGitLab Duo Self-Hostedではベータ版であり、GitLab Self-ManagedインスタンスではGAとなっています。

### Duo Code Reviewによる自動レビュー {#automatic-reviews-with-duo-code-review}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/project/merge_requests/duo_in_merge_requests.md)

{{< /details >}}

Duo Code Reviewはレビュープロセスで有益なインサイトを提供しますが、現状では各マージリクエストに対して手動でレビューをリクエストする必要があります。

プロジェクトのマージリクエスト設定を更新することで、Duo Code Reviewがマージリクエストに対して自動的に実行されるよう設定できるようになりました。有効にすると、以下の場合を除いてDuo Code Reviewが自動的にマージリクエストをレビューします。

- マージリクエストがドラフトとしてマークされている場合。
- マージリクエストに変更が含まれていない場合。

自動レビューにより、プロジェクト内のすべてのコードがレビューを受けることが保証され、コードベース全体のコード品質が継続的に向上します。

### コード提案のプロンプトキャッシュ {#code-suggestions-prompt-caching}

<!-- categories: Code Suggestions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Pro、Duo Enterprise
- リンク: [ドキュメント](../../user/project/repository/code_suggestions/_index.md#prompt-caching) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17489)

{{< /details >}}

コード提案にプロンプトキャッシュが追加されました。プロンプトキャッシュは、キャッシュされたプロンプトと入力データの再処理を回避することで、コード補完のレイテンシーを大幅に改善します。キャッシュされたデータは永続ストレージに記録されることはなく、GitLab Duoの設定でプロンプトキャッシュを無効にすることもできます。

### Duo Code Reviewのコンテキスト改善 {#improved-duo-code-review-context}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/project/merge_requests/duo_in_merge_requests.md)

{{< /details >}}

Duo Code Reviewが分析精度向上のためにより包括的なコンテキストを提供するようになりました。
主な改善点は以下のとおりです。

- 提案された変更の目的をより深く理解するために、マージリクエストのタイトルと説明を含めるようになりました。
- クロスファイルの関係を認識し誤検出を減らすために、すべての差分を同時に検査するようになりました。
- 変更が既存のコードパターンにどのように適合するかを理解するために、変更されたファイルの全内容を提供するようになりました。

これらの改善により、不正確な提案が減少し、より関連性が高く高品質なコードレビューが実現します。

## スケールとデプロイ {#scale-and-deployments}

### GitLab.comでのコントリビュート再割り当てにエンタープライズユーザーのみを表示 {#list-only-enterprise-users-for-contributions-reassignment-on-gitlabcom}

<!-- categories: Importers -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../user/group/import/direct_transfer_migrations.md#user-membership-mapping) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/510673)

{{< /details >}}

今回のリリースでは、ユーザー選択ドロップダウンをトップレベルグループに関連付けられたエンタープライズユーザーのみに絞り込むことで、プレースホルダーユーザーのマッピング体験を改善しました。
以前は、GitLab.comへのインポート後にユーザーのコントリビュートを再割り当てする際、ドロップダウンリストにプラットフォーム上のすべてのアクティブユーザーが表示されていたため、特にSCIMプロビジョニングによってユーザー名が変更されている場合に正しいユーザーを特定することが困難でした。トップレベルグループがエンタープライズユーザー機能を使用している場合、ドロップダウンリストには組織が所有するユーザーのみが表示されるようになり、ユーザー再割り当て時のエラーの可能性が大幅に低減されます。
同様のスコープ設定はCSVベースの再割り当てにも適用され、組織外のユーザーへの誤った割り当てを防止します。

### GitLab for Slackアプリでの複数ワークスペースのサポート {#support-for-multiple-workspaces-in-the-gitlab-for-slack-app}

<!-- categories: Settings -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/settings/slack_app.md#enable-support-for-multiple-workspaces) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/424190)

{{< /details >}}

GitLab for SlackアプリがGitLab Self-ManagedおよびGitLab Dedicatedのお客様向けに複数ワークスペースをサポートするようになりました。
複数ワークスペースを有効にすることで、フェデレーテッドSlack環境を持つ組織がすべてのワークスペースにわたってシームレスなGitLabインテグレーションを維持できます。
複数ワークスペースのサポートを有効にするには、GitLab for Slackアプリを[非公開の配布アプリ](https://api.slack.com/distribution#unlisted-distributed-apps)として設定してください。

### グループとプレースホルダーユーザーの削除 {#delete-groups-and-placeholder-users}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/import/mapping/post_migration_mapping.md#placeholder-user-deletion) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/473256)

{{< /details >}}

GitLab 18.0では、トップレベルグループを削除すると、そのグループに関連付けられたプレースホルダーユーザーも削除されます。プレースホルダーユーザーが他のプロジェクトに関連付けられている場合は、トップレベルグループからのみ削除されます。
これにより、他のプロジェクトの履歴や帰属を損なうことなく、不要なプレースホルダーユーザーが削除されます。

### GitLab Dedicatedで内部リリースが利用可能に {#internal-releases-available-for-gitlab-dedicated}

<!-- categories: GitLab Dedicated -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](https://handbook.gitlab.com/handbook/engineering/releases/internal-releases/) | [関連エピック](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1201)

{{< /details >}}

厳格なセキュリティ要件とコンプライアンス義務を持つGitLab Dedicatedのお客様は、開発環境に最高レベルの保護を必要としています。
本日、内部リリースを導入します。これは新しいプライベートリリースであり、公開開示前にGitLab Dedicatedインスタンスの重大な脆弱性を修正することで、GitLab Dedicatedのお客様が脆弱性にさらされることがないようにします。
この新機能により、GitLab.comへの対応と並行して、GitLabで発見された重大な脆弱性に対する即時保護が提供されます。この新しいプロセスはお客様の対応を必要としません。

### 破壊的な変更を含むGitLabチャート9.0のリリース {#gitlab-chart-9-0-released-with-breaking-changes}

<!-- categories: Cloud Native Installation, Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](https://docs.gitlab.com/charts/releases/9_0/) | [関連イシュー](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5927)

{{< /details >}}

- [破壊的な変更](../../update/deprecations.md#postgresql-14-and-15-no-longer-supported): PostgreSQL 14および15のサポートが削除されました。アップグレード前にPostgreSQL 16を実行していることを確認してください。
- [破壊的な変更](../../update/deprecations.md#major-update-of-the-prometheus-subchart): バンドルされているPrometheusチャートが15.3から27.11に更新されました。Prometheusチャートのアップグレードに伴い、Prometheusのバージョンも2.38から3.0に更新されました。アップグレードを実行するには手動の手順が必要です。Alertmanager、Node Exporter、またはPushgatewayを有効にしている場合は、Helm値も更新する必要があります。詳細については、[移行ガイド](https://docs.gitlab.com/charts/releases/9_0.html#prometheus-upgrade)を参照してください。
- [破壊的な変更](../../update/deprecations.md#fallback-support-for-gitlab-nginx-chart-controller-image-v131): デフォルトのNGINXコントローラーイメージがバージョン1.3.1から1.11.2に更新されました。GitLab NGINXチャートを使用していて、独自のNGINX RBACルールを設定している場合は、新しいRBACルールが必要です。詳細については、[アップグレードガイド](https://docs.gitlab.com/charts/releases/8_0/#upgrade-to-86x-851-843-836)を参照してください。

### イベントデータ収集 {#event-data-collection}

<!-- categories: Application Instrumentation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/settings/event_data.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/510333)

{{< /details >}}

GitLab 18.0では、GitLab Self-ManagedおよびGitLab Dedicatedインスタンスからのイベントレベルの製品使用データ収集を有効にします。集計データとは異なり、イベントレベルのデータはGitLabに使用状況のより深いインサイトを提供し、プラットフォームのユーザーエクスペリエンスの向上と機能の採用促進に役立てることができます。データ共有設定の調整方法の詳細については、ドキュメントを参照してください。

### すべてのユーザーが削除保護を利用可能に {#deletion-protection-available-for-all-users}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../administration/settings/visibility_and_access_controls.md#deletion-protection) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17208) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/526405)

{{< /details >}}

プロジェクトとグループの遅延削除が、Freeプランのユーザーを含むすべてのGitLabユーザーに利用可能になりました。この重要な安全機能は、削除されたグループとプロジェクトが完全に削除される前に猶予期間（GitLab.comでは7日間）を設けます。この機能により、複雑なリカバリー操作なしに誤った削除から回復できます。

データの安全性をコア機能とすることで、GitLabはデータ損失イベントからあなたの作業をより適切に保護できます。

### ユーザーネームスペースの遅延プロジェクト削除 {#delayed-project-deletion-for-user-namespaces}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/working_with_projects.md#delete-a-project) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/536244)

{{< /details >}}

ユーザーネームスペース（個人プロジェクト）のプロジェクトで遅延削除が利用可能になりました。以前は、この誤ったデータ損失に対する保護機能はグループネームスペースのみで利用可能でした。ユーザーネームスペースのプロジェクトを削除すると、即座に削除されるのではなく、インスタンス設定で設定された期間（GitLab.comでは7日間）の「削除保留」状態になります。この期間中に必要に応じてプロジェクトを復元できる回復ウィンドウが作成されます。

この改善により、GitLabで個人プロジェクトを管理する際の安心感が高まることを願っています。

### グループおよびプロジェクトREST APIの新しい`active`パラメーター {#new-active-parameter-for-groups-and-projects-rest-apis}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../api/projects.md#list-projects)

{{< /details >}}

グループおよびプロジェクトREST APIに新しい`active`パラメーターを追加しました。これにより、ステータスに基づいたグループのフィルタリングが簡単になります。`true`に設定すると、アーカイブされていないグループまたは削除対象としてマークされていないプロジェクトのみが返されます。`false`に設定すると、アーカイブされたグループまたは削除対象としてマークされたプロジェクトのみが返されます。パラメーターが未定義の場合、フィルタリングは適用されません。この改善により、シンプルなAPIコールで特定のステータスを対象にすることで、ワークフローを効率的に管理できます。

プロジェクトAPIにこのパラメーターを追加してくださった[@dagaranupam](https://gitlab.com/dagaranupam)に感謝します。

### グループ、プロジェクト、ユーザーAPIのレート制限 {#rate-limits-for-groups-projects-and-users-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/gitlab_com/_index.md#rate-limits-on-gitlabcom) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/461316)

{{< /details >}}

すべてのユーザーのプラットフォームの安定性とパフォーマンスを向上させるために、プロジェクト、グループ、ユーザーのAPIレート制限を追加しました。これらの変更は、サービスに影響を与えていたAPIトラフィックの増加に対応するものです。

制限は平均的な使用パターンに基づいて慎重に設定されており、ほとんどのユースケースに十分な容量を提供するはずです。これらの制限を超えると、「429 Too Many Requests」レスポンスが返されます。

特定のレート制限と実装情報の詳細については、[関連するブログ記事をお読みください](https://about.gitlab.com/blog/rate-limitations-announced-for-projects-groups-and-users-apis/)。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### セキュリティスキャナーがMRパイプラインをサポート {#security-scanners-now-support-mr-pipelines}

<!-- categories: API Security, Container Scanning, DAST, Fuzz Testing, SAST, Secret Detection, Software Composition Analysis -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/detect/roll_out_security_scanning.md)

{{< /details >}}

[アプリケーションセキュリティテスト（AST）スキャナー](../../user/application_security/detect/_index.md)を[マージリクエスト（MR）パイプライン](../../ci/pipelines/merge_request_pipelines.md)で実行するよう選択できるようになりました。
パイプラインへの影響を最小限に抑えるため、これはオプトイン動作として制御できます。

以前は、デフォルトの動作はスキャナーを有効にするために[安定版または最新版のCI/CDテンプレートエディション](../../user/application_security/detect/security_configuration.md#template-editions)のどちらを使用したかによって異なっていました。

- 安定版テンプレートでは、スキャンジョブはブランチパイプラインのみで実行されていました。MRパイプラインはサポートされていませんでした。
- 最新版テンプレートでは、MRがオープンの場合はMRパイプラインでスキャンジョブが実行され、関連するMRがない場合はブランチパイプラインで実行されていました。この動作を制御することはできませんでした。

新しいオプション`AST_ENABLE_MR_PIPELINES`により、MRパイプラインでジョブを実行するかどうかを制御できるようになりました。
安定版と最新版テンプレートのデフォルト動作は変わりません。具体的には以下のとおりです。

- 安定版テンプレートは引き続きデフォルトでブランチパイプラインでスキャンジョブを実行しますが、MRがオープンの場合に`AST_ENABLE_MR_PIPELINES: "true"`を設定してMRパイプラインを使用することができます。
- 最新版テンプレートは引き続きMRがオープンの場合にデフォルトでMRパイプラインでスキャンジョブを実行しますが、`AST_ENABLE_MR_PIPELINES: "false"`を設定してブランチパイプラインを使用することができます。

この改善は、現在デフォルトでMRパイプラインを使用するAPIディスカバリー（`API-Discovery.gitlab-ci.yml`）を除くすべてのセキュリティスキャンテンプレートに影響します。
また、GitLab 18.0でAPIディスカバリーテンプレートを他の安定版テンプレートに合わせて変更し、デフォルトでブランチパイプラインを使用するようにしました。

### コンプライアンスプロジェクトレポートでアーカイブされたプロジェクトを表示およびフィルタリング {#display-and-filter-archived-projects-in-the-compliance-projects-report}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate、Premium
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_projects_report.md#filter-the-compliance-projects-report) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/500520)

{{< /details >}}

コンプライアンスプロジェクトレポートでは、グループまたはサブグループ内のプロジェクトに適用されたコンプライアンスフレームワークを確認できます。

ただし、レポートにはプロジェクトがアーカイブされているかどうかを示す機能がなく、アクティブなプロジェクトとアーカイブされたプロジェクト全体のコンプライアンス管理に役立つ情報が欠けていました。

そのため、プロジェクトがアーカイブされているかどうかを示すインジケーターを追加しました。これにより、アクティブなプロジェクトとアーカイブされたプロジェクトの両方にわたってコンプライアンスフレームワークをレビューする際の可視性とコンテキストが向上します。

この機能には以下が含まれます。

- コンプライアンスプロジェクトレポートの各プロジェクトにアーカイブステータスバッジを表示し、プロジェクトがアーカイブされているかどうかを示します。
- アーカイブ済み、未アーカイブ、またはすべてのプロジェクト間で切り替えられるフィルター。

### マージリクエストからワークスペースを作成 {#create-a-workspace-from-merge-requests}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/workspace/configuration.md#create-a-workspace)

{{< /details >}}

新しい**ワークスペースで開く**オプションを使用して、マージリクエストから直接ワークスペースを作成できるようになりました。この機能はマージリクエストのブランチとコンテキストでワークスペースを自動的に設定し、以下のことができます。

- 完全に設定された環境でコード変更をレビューする。
- マージリクエストブランチでテストを実行して機能を検証する。
- ローカルセットアップなしにマージリクエストに追加の変更を加える。

### ファイルを対象とするオープンなマージリクエストを表示 {#view-open-merge-requests-targeting-files}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/repository/files/_index.md#view-open-merge-requests-for-a-file) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/448868)

{{< /details >}}

以前は、コードファイルを操作する際に、他のブランチで同じファイルを変更している人がいるかどうかを確認する方法がありませんでした。この可視性の欠如により、マージコンフリクト、重複した作業、非効率なコラボレーションが発生していました。

リポジトリで表示しているファイルを変更するすべてのオープンなマージリクエストを簡単に特定できるようになりました。この機能により以下のことができます。

- 発生前にマージコンフリクトの可能性を特定する。
- すでに進行中の作業の重複を避ける。
- 進行中の変更への可視性を提供することでコラボレーションを改善する。

バッジにはファイルを変更するオープンなマージリクエストの数が表示され、バッジにカーソルを合わせるとこれらのマージリクエストのリストを含むポップオーバーが表示されます。

### ワークスペース用の共有Kubernetesネームスペース {#shared-kubernetes-namespace-for-workspaces}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/workspace/settings.md#shared_namespace)

{{< /details >}}

共有KubernetesネームスペースにGitLabワークスペースを作成できるようになりました。これにより、ワークスペースごとに新しいネームスペースを作成する必要がなくなり、エージェントに昇格したClusterRoleパーミッションを付与する要件もなくなります。この機能により、セキュアまたは制限された環境でワークスペースをより簡単に採用でき、スケールへのよりシンプルなパスを提供します。

共有ネームスペースを有効にするには、エージェント設定ファイルの`shared_namespace`フィールドを設定して、すべてのワークスペースに使用するKubernetesネームスペースを指定します。

[GitLabの共同開発プログラム](https://about.gitlab.com/community/co-create/)を通じてこの機能の構築に協力してくださった数名のコミュニティコントリビューターに感謝します！

### Kubernetesダッシュボードのポッドステータス可視化の改善 {#improved-pod-status-visualizations-in-the-dashboard-for-kubernetes}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../ci/environments/kubernetes_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/525081)

{{< /details >}}

Kubernetesダッシュボードを使用してデプロイされたアプリケーションを監視できます。これまで、`CrashLoopBackOff`や`ImagePullBackOff`などのコンテナエラーが発生したポッドは「Pending」または「Running」ステータスで表示されており、`kubectl`を使用せずに問題のあるデプロイを特定することが困難でした。

GitLab 18.0では、UIのエラー状態が`kubectl`の出力と同様に特定のコンテナのステータスを表示するようになりました。これにより、GitLabインターフェースを離れることなく、失敗しているポッドを素早く特定してトラブルシューティングできます。

### ライセンス承認ルールからパッケージを除外 {#exclude-packages-from-license-approval-rules}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#license_finding-rule-type) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10203)

{{< /details >}}

マージリクエスト承認ポリシーにおいて、ライセンス承認ポリシーへのこの新しい機能強化により、法務・コンプライアンスチームが特定のライセンスを使用できるパッケージをより細かく制御できるようになりました。組織のポリシーで通常ブロックされるライセンスを使用している場合でも、事前承認済みのパッケージに対して例外を作成できるようになりました。

以前は、ライセンス承認ポリシーでAGPL-3.0などのライセンスをブロックすると、組織全体のすべてのパッケージでブロックされていました。これにより以下のような課題が生じていました。

- 法務チームが制限されたライセンスを持つ特定のパッケージを事前承認している場合。
- 数百のプロジェクトで同じパッケージを使用する必要がある場合。
- チームごとに異なるライセンス例外が必要な場合。

このリリースにより、必要な例外を許可しながら厳格なライセンスガバナンスを維持でき、承認のボトルネックと手動レビューを大幅に削減できます。例えば、以下のことができます。

- パッケージURL（PURL）形式を使用してライセンス承認ルールにパッケージ固有の例外を定義する。
- 特定のパッケージ（またはパッケージバージョン）が通常制限されているライセンスを使用することを許可する。
- 特定のパッケージ（またはパッケージバージョン）が一般的に許可されているライセンスを使用することをブロックする。

例外を追加するには、ライセンス承認ポリシーを作成または編集する際に以下のワークフローに従ってください。

1. グループで**セキュリティとコンプライアンス** > **ポリシー**に移動します。
1. ライセンス承認ポリシーを作成または編集します。
1. ビジュアルエディターで新しいパッケージ例外オプションを見つけるか、YAMLモードで設定します。
1. ライセンスの許可リストまたは拒否リストモードを選択します。
1. ポリシーに特定のライセンスを追加します。
1. 各ライセンスについて、PURL形式でパッケージ例外を定義します（例: `pkg:npm/@angular/animation@12.3.1`）。
1. これらのパッケージをライセンスルールに含めるか除外するかを指定します。

ポリシーは定義された例外を尊重しながらライセンスルールを適用し、組織全体のライセンスコンプライアンスをきめ細かく制御できます。

### ユーザーセッションの最大長を制限 {#limit-maximum-user-session-length}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/settings/account_and_limit_settings.md#set-sessions-to-expire-from-creation-date) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/395038)

{{< /details >}}

管理者は、ユーザーセッションの最大長を最初のサインインから計算するか、最後のアクティビティから計算するかを選択できるようになりました。セッションが終了することはユーザーに通知されますが、セッションの期限切れを防いだり延長したりすることはできません。この機能はデフォルトで無効になっています。

[John Parent](https://gitlab.kitware.com/john.parent)のコントリビュートに感謝します！

### GitLab Query Languageビューの機能強化 {#gitlab-query-language-views-enhancements}

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/glql/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15008)

{{< /details >}}

GitLab Query Language（GLQL）ビューに大幅な改善を加えました。これらの改善には以下のサポートが含まれます。

- すべての日付タイプに対する`>=`および`<=`演算子
- ビューの**ビューアクション**ドロップダウン
- **再読み込み**アクション
- フィールドエイリアス
- GLQLテーブルの列をカスタム名にエイリアスする機能

この機能強化およびGLQLビュー全般についてのフィードバックを[イシュー509791](https://gitlab.com/gitlab-org/gitlab/-/issues/509791)でお待ちしています。

### Pagesテンプレートの改善 {#pages-template-improvements}

<!-- categories: Pages -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/pages/getting_started/pages_new_project_template.md#project-templates)

{{< /details >}}

GitLabは[人気の静的サイトジェネレーター向けテンプレート](https://gitlab.com/pages)を提供しています。スコアリングフレームワークを使用して利用可能なテンプレートを詳しく調査し、最も人気のあるテンプレートのみを含むようにリストを絞り込みました。

GitLab Pagesで利用可能なテンプレートを絞り込むことで、ウェブサイト作成プロセスが効率化されます。テンプレートを使用することで、最小限の技術的な専門知識でプロフェッショナルなサイトを立ち上げることができます。強化されたテンプレートはモダンでレスポンシブなデザインも提供し、カスタム開発作業の必要性を排除します。

### Jiraインテグレーションを使用して脆弱性からJiraイシューを設定 {#configure-jira-issues-from-vulnerabilities-using-the-jira-integration-api}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../api/project_integrations.md#jira-issues) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/454574)

{{< /details >}}

以前は、**プロジェクト設定**ページから[脆弱性のJiraイシューを作成する](../../integration/jira/configure.md#create-a-jira-issue-for-a-vulnerability)インテグレーションを設定する必要がありました。

プロジェクトインテグレーションAPIからこのインテグレーションを設定できるようになり、セットアップを自動化できます。

### 再検出された脆弱性のトレーサビリティの向上 {#improved-traceability-of-redetected-vulnerabilities}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/_index.md#vulnerability-status-values) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523452)

{{< /details >}}

以前は、解決済みの脆弱性が再検出されてステータスが変更された場合、脆弱性の詳細にはステータス変更がいつ、なぜ発生したかを示す情報が提供されていませんでした。

GitLabは、解決済みの脆弱性が新しいスキャンに現れたためにステータスが変更された場合、脆弱性の履歴にシステムノートを追加するようになりました。この追加情報により、ユーザーは脆弱性のステータスが変更された理由を理解できます。

### 脆弱性レポートからイシューに脆弱性を一括追加 {#bulk-add-vulnerabilities-to-issues-from-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md#add-vulnerabilities-to-an-existing-issue) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13216)

{{< /details >}}

このリリースにより、脆弱性レポートから新規または既存のGitLabイシューに脆弱性を一括追加できるようになりました。
複数のイシューと脆弱性を関連付けることができます。また、関連する脆弱性がイシューページ内に一覧表示されるようになりました。

### ユーザー招待の無効化 {#disable-user-invitations}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../administration/settings/visibility_and_access_controls.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/19618)

{{< /details >}}

グループまたはプロジェクトにメンバーを招待する機能を削除できるようになりました。

- GitLab.comでは、この設定はエンタープライズユーザーを持つグループのオーナーが設定し、トップレベルグループ内のサブグループまたはプロジェクトに適用されます。この設定が有効になっている間は、どのユーザーも招待を送信できません。
- GitLab Self-Managedでは、この設定は管理者が設定し、インスタンス全体に適用されます。管理者は引き続きユーザーを直接招待できます。

この機能は、組織がメンバーシップアクセスを厳格に制御するのに役立ちます。

### GitLabユーザー名によるLDAP認証 {#ldap-authentication-with-gitlab-username}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed
- リンク: [ドキュメント](../../administration/auth/ldap/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/215357)

{{< /details >}}

LDAPユーザーがGitLabユーザー名でリクエストを認証できるようになりました。以前は、GitLabユーザー名がLDAPユーザー名と一致しない場合、GitLabは認証エラーを返していました。この変更により、承認ワークフローを中断することなく、GitLabとLDAPシステムで別々の命名規則を維持できます。

### SHA256 SAML証明書のサポート {#support-for-sha256-saml-certificates}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../integration/saml.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/524624)

{{< /details >}}

GitLabはグループSAML認証のSHA1とSHA256の両方の証明書フィンガープリントを自動的に検出してサポートするようになりました。これにより、既存のSHA1フィンガープリントとの後方互換性を維持しながら、より安全なSHA256フィンガープリントのサポートが追加されます。このアップグレードは、SHA256をデフォルトにする予定のruby-saml 2.xリリースに備えるために不可欠です。

### ベータ版のジョブトークンの詳細なパーミッション {#granular-permissions-for-job-tokens-in-beta}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- リンク: [ドキュメント](../../ci/jobs/fine_grained_permissions.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16199)

{{< /details >}}

パイプラインのセキュリティがより柔軟になりました。ジョブトークンはパイプライン内のリソースへのアクセスを提供する一時的な認証情報です。これまで、これらのトークンはユーザーから完全なパーミッションを継承しており、不必要に広いアクセス権限が付与されることが多くありました。

新しい[ジョブトークンの詳細なパーミッション](../../ci/jobs/fine_grained_permissions.md)ベータ機能により、プロジェクト内でジョブトークンがアクセスできる特定のリソースを正確に制御できるようになりました。これにより、CI/CDワークフローに最小権限の原則を実装し、各ジョブがタスクを完了するために必要な最小限のアクセスのみを付与できます。

この機能についてのコミュニティフィードバックを積極的に求めています。質問がある場合、実装経験を共有したい場合、または潜在的な改善についてチームと直接関わりたい場合は、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/519575)をご覧ください。

### カスタムロールの新しいパーミッション {#new-permissions-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated
- リンク: [ドキュメント](../../user/custom_roles/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14746)

{{< /details >}}

[保護環境の管理](https://gitlab.com/gitlab-org/gitlab/-/issues/471385)パーミッションを持つカスタムロールを作成できます。
カスタムロールにより、ユーザーがタスクを完了するために必要な特定のパーミッションのみを付与できます。
これにより、グループのニーズに合わせたロールを定義でき、メンテナーまたはオーナーロールが必要なユーザーの数を減らすことができます。

### 限定提供のプロジェクト向け新しいCI/CD分析ビュー {#new-cicd-analytics-view-for-projects-in-limited-availability}

<!-- categories: Fleet Visibility -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../user/analytics/ci_cd_analytics.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/444468)

{{< /details >}}

再設計されたCI/CD分析ビューは、開発チームがパイプラインのパフォーマンスと信頼性を分析、監視、最適化する方法を変革します。開発者はGitLab UIの直感的な可視化にアクセスして、パフォーマンストレンドと信頼性メトリクスを確認できます。これらのインサイトをプロジェクトリポジトリに組み込むことで、開発者のフローを妨げるコンテキストスイッチングが排除されます。チームはパフォーマンスを低下させるパイプラインのボトルネックを特定して対処できます。この改善により、開発サイクルの高速化、コラボレーションの向上、GitLabのCI/CDワークフローを最適化するためのデータドリブンな自信が得られます。

### GitLab Runner 18.0

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.0もリリースします！GitLab RunnerはCI/CDジョブを実行してGitLabインスタンスに結果を送信する高スケーラブルなビルドエージェントです。GitLab RunnerはGitLab CI/CDと連携して動作します。GitLab CI/CDはGitLabに含まれるオープンソースの継続的インテグレーションサービスです。

#### 新機能

- [`ConfigurationError`と`ExitCodeInvalidConfiguration`をGitLab Runnerビルドエラー分類に追加](https://gitlab.com/gitlab-org/gitlab/-/issues/514297)
- [クラウドストレージへのキャッシュアップロード失敗時のクラウドプロバイダーエラーメッセージを改善](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5527)

#### バグ修正

- [GitLab Runnerが許可されていない場合でもキャッシュされたイメージを使用できる問題](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38706)

すべての変更のリストはGitLab Runnerの[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-0-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-0-stable/CHANGELOG.md).md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.0)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.0)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.0)
- [非推奨と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
