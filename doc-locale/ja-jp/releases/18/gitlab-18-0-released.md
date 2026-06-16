---
stage: Release Notes
group: Monthly Release
date: 2025-05-15
title: "GitLab 18.0リリースノート"
description: "GitLab 18.0がGitLab PremiumとUltimate Duoを搭載してリリースされました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年5月15日、GitLab 18.0が以下の機能を搭載してリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Michael Hofer {#this-months-notable-contributor-michael-hofer}

Michael Hoferは、トップコントリビューターとコミュニティリーダーの両方として、GitLabのオープンソースミッションを擁護しています。今年[50を超えるコントリビュート](https://contributors.gitlab.com/users/karras?fromDate=2025-01-01&toDate=2025-05-12)を行い、彼の取り組みによってGitLabのGeo機能とOpenBaoをベースにしたシークレットマネージャーが強化されました。彼は、仲間のコントリビューターをサポートし、コミュニティプロジェクトを主導しながら、[April Hackathon](https://contributors.gitlab.com/hackathon?hackathonName=2025_04)でトップに立ちました。

「誰もがGitLabにコントリビュートすることができることに本当に感謝しています！」とMichaelは言います。「チームは一緒に仕事をするのに最適で、とても楽しく、誰もが非常に協力的です。特にOpenBaoやSLSAのようなオープンソースイニシアチブを横断して協力する際には。」

Michaelは、計画、ビルド、ミッションクリティカルなオープンソースワークロードの実行を専門とする国際的なITサービスプロバイダーである[Adfinis](https://adfinis.com/en/)のCTOです。彼は、組織全体のコラボレーションを促進し、オープンソースソリューションを推進することに情熱を傾けています。

最近、AdfinisはGitLabの[共同開発プログラム](https://about.gitlab.com/community/co-create/)に参加しました。これは、組織とGitLabの製品およびエンジニアリングチームが連携してGitLabをビルドするものです。「Co-Createをすべての組織に強くお勧めします」とMichaelは言います。「ルートレスPodmanのビルド、Glimmerの構文ハイライト、その他の改善点を含む、数多くの素晴らしいコントリビュートにつながりました。」

「GeoチームはMichaelとの仕事に本当に感謝し、楽しんでいます」と、Michaelを賞にノミネートしたGitLabのエンジニアリングマネージャーである[Lucie Zhao](https://gitlab.com/luciezhao)は言います。「過去数マイルストーンにわたる彼の素晴らしいコントリビュートにより、彼はチーム内で最もよく知られたコミュニティコントリビューターになりました。」

GitLabチームメンバーの[Lee Tickett](https://gitlab.com/leetickett-gitlab)、[Chloe Fons](https://gitlab.com/c_fons)、および[Alex Scheel](https://gitlab.com/cipherboy-gitlab)がノミネートを支持しました。Alexは、「OpenBaoにおけるMichaelのリーダーシップにより、私たちは、GitLabの価値観に合致する透明性を持って、お客様向けのシークレットマネージャーソリューションを効果的に協力して推進することができました」と付け加えます。

MichaelとAdfinisチームのCo-Createへのご協力に感謝します！

## 主要な機能 {#primary-features}

### GitLab PremiumとUltimate Duo {#gitlab-premium-and-ultimate-with-duo}

<!-- categories: Code Suggestions, Duo Chat -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/538857)

{{< /details >}}

GitLab Premium DuoとGitLab Ultimate Duoを発表できることを嬉しく思います。GitLab PremiumとUltimateには、AIネイティブ機能が搭載されるようになりました。

GitLabのAIネイティブ機能には、コード提案とIDE内のチャットが含まれます。開発チームはこれらの機能を使用して以下を行うことができます:

- コードを分析、理解、説明する
- 安全なコードをより速く記述する
- コード品質を維持するためのテストを迅速に生成する
- パフォーマンスを向上させるため、または特定のライブラリを使用するために、簡単にコードをリファクタリングする

### リポジトリX-RayがGitLab Duo Self-Hostedで利用可能になりました {#repository-x-ray-now-available-on-gitlab-duo-self-hosted}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/project/repository/code_suggestions/repository_xray.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17756)

{{< /details >}}

GitLab Duo Self-HostedでリポジトリX-Rayとコード提案を使用できるようになりました。この機能はGitLab Duo Self-Hostedのベータ版であり、GitLab Self-Managedインスタンスで一般提供されています。

### GitLab Duoコードレビューによる自動レビュー {#automatic-reviews-with-duo-code-review}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/project/merge_requests/duo_in_merge_requests.md)

{{< /details >}}

GitLab Duoコードレビューは、レビュープロセス中に貴重なインサイトを提供しますが、現在、各マージリクエストで手動でレビューを要求する必要があります。

プロジェクトの設定を更新することで、GitLab Duoコードレビューがマージリクエストで自動的に実行されるように設定できるようになりました。有効にすると、GitLab Duoコードレビューは、以下の場合を除き、マージリクエストを自動的にレビューします:

- マージリクエストがドラフトとしてマークされている。
- マージリクエストに変更が含まれていない。

自動レビューにより、プロジェクト内のすべてのコードがレビューを受け、コードベース全体のコード品質が継続的に向上します。

### コード提案のプロンプトキャッシュ {#code-suggestions-prompt-caching}

<!-- categories: Code Suggestions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/project/repository/code_suggestions/_index.md#prompt-caching) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17489)

{{< /details >}}

コード提案にプロンプトキャッシュが含まれるようになりました。プロンプトキャッシュは、キャッシュされたプロンプトと入力データの再処理を回避することで、コード補完のレイテンシーを大幅に改善します。キャッシュされたデータは永続ストレージに記録されることはなく、GitLab Duoの設定でプロンプトキャッシュをオプションで無効にできます。

### 改善されたGitLab Duoコードレビューのコンテキスト {#improved-duo-code-review-context}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/project/merge_requests/duo_in_merge_requests.md)

{{< /details >}}

GitLab Duoコードレビューは、分析を改善するためのより包括的なコンテキストを提供するようになりました。主な改善点は以下のとおりです:

- 提案された変更の目的をよりよく理解するために、マージリクエストのタイトルと説明が含まれます。
- すべての差分を同時に調査し、クロスファイルの関係を認識し、誤検出を削減します。
- 変更されたファイルの完全なコンテンツを提供し、既存のコードパターン内で変更がどのように適合するかを理解します。

これらの機能強化により、不正確な提案が減少し、より関連性の高い高品質のコードレビューが提供されます。

## 規模とデプロイ {#scale-and-deployments}

### GitLab.comでのコントリビュートの再割り当てのためにEnterpriseユーザーのみをリスト表示 {#list-only-enterprise-users-for-contributions-reassignment-on-gitlabcom}

<!-- categories: Importers -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/import/direct_transfer_migrations.md#user-membership-mapping) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/510673)

{{< /details >}}

このリリースでは、ユーザー選択ドロップダウンをトップレベルグループに関連付けられたEnterpriseユーザーのみに絞り込むことで、プレースホルダーユーザーユーザーマッピングエクスペリエンスを改善しました。以前は、GitLab.comへのインポート後にユーザーのコントリビュートを再割り当てする際、プラットフォーム上のすべてのアクティブユーザーがドロップダウンリストに表示され、特にSCIMのプロビジョニングでユーザー名が変更されていた場合、正しいユーザーを特定することが困難でした。現在、トップレベルグループでEnterpriseユーザー機能を使用している場合、ドロップダウンリストには組織が主張するユーザーのみが表示され、ユーザーの再割り当て時のエラーの可能性が大幅に減少します。同じスコープがCSVベースの再割り当てにも適用され、組織外のユーザーへの偶発的な割り当てを防ぎます。

### GitLab for Slackアプリでの複数のワークスペースのサポート {#support-for-multiple-workspaces-in-the-gitlab-for-slack-app}

<!-- categories: Integrations -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/settings/slack_app.md#enable-support-for-multiple-workspaces) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/424190)

{{< /details >}}

GitLab for Slackアプリは、GitLab Self-ManagedおよびGitLab Dedicatedのお客様向けに複数のワークスペースをサポートするようになりました。複数のワークスペースを有効にすることで、フェデレーションされたSlack環境を持つ組織は、すべてのワークスペースでシームレスなGitLabインテグレーションを維持できます。複数のワークスペースのサポートを有効にするには、GitLab for Slackアプリを[unlisted distributed app](https://api.slack.com/distribution#unlisted-distributed-apps)として構成します。

### グループとプレースホルダーユーザーの削除 {#delete-groups-and-placeholder-users}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/import/mapping/post_migration_mapping.md#placeholder-user-deletion) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/473256)

{{< /details >}}

GitLab 18.0では、トップレベルグループを削除すると、そのグループに関連付けられているプレースホルダーユーザーも削除されます。プレースホルダーユーザーが他のプロジェクトに関連付けられている場合、それらはトップレベルグループからのみ削除されます。このようにして、不要なプレースホルダーユーザーは、他のプロジェクトの履歴や属性を損なうことなく削除されます。

### GitLab Dedicatedで利用可能な内部リリース {#internal-releases-available-for-gitlab-dedicated}

<!-- categories: GitLab Dedicated -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](https://handbook.gitlab.com/handbook/engineering/releases/internal-releases/) | [関連エピック](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/1201)

{{< /details >}}

厳格なセキュリティ要件とコンプライアンス義務を負うGitLab Dedicatedのお客様は、開発環境に対して最高レベルの保護を必要とします。本日、私たちはInternal Releasesを導入します。これは、公開前にGitLab Dedicatedインスタンスの重大な脆弱性を修正することができる新しいプライベートリリースであり、GitLab Dedicatedのお客様がそれらに晒されることはありません。この新しい機能は、GitLab.comへの応答と並行して、GitLabで見つかった重大な脆弱性に対する即時保護を提供します。この新しいプロセスでは、お客様による操作は不要です。

### GitLabチャート9.0が破壊的な変更とともにリリースされました {#gitlab-chart-90-released-with-breaking-changes}

<!-- categories: Cloud Native Installation, Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/charts/releases/9_0/) | [関連イシュー](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5927)

{{< /details >}}

- [破壊的な変更](../../update/deprecations.md#postgresql-14-and-15-no-longer-supported): PostgreSQL 14と15のサポートが削除されました。アップグレードの前に、PostgreSQL 16を実行していることを確認してください。
- [破壊的な変更](../../update/deprecations.md#major-update-of-the-prometheus-subchart): バンドルされているPrometheusチャートが15.3から27.11に更新されました。Prometheusチャートのアップグレードに伴い、Prometheusのバージョンが2.38から3.0に更新されました。アップグレードを実行するには、手動による手順が必要です。Alertmanager、Node Exporter、またはPushgatewayが有効になっている場合は、Helmの値を更新する必要があります。詳細については、[移行ガイド](https://docs.gitlab.com/charts/releases/9_0.html#prometheus-upgrade)を参照してください。
- [破壊的な変更](../../update/deprecations.md#fallback-support-for-gitlab-nginx-chart-controller-image-v131): デフォルトのNGINXコントローラーイメージは、バージョン1.3.1から1.11.2に更新されました。GitLab NGINXチャートを使用しており、独自のNGINX RBACルールを設定している場合は、新しいRBACルールが存在する必要があります。詳細については、[アップグレードガイド](https://docs.gitlab.com/charts/releases/8_0/#upgrade-to-86x-851-843-836)を参照してください。

### イベントデータの収集 {#event-data-collection}

<!-- categories: Application Instrumentation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/settings/event_data.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/510333)

{{< /details >}}

GitLab 18.0では、GitLab Self-ManagedおよびGitLab Dedicatedインスタンスからのイベントレベルの製品使用データ収集を有効にしています。集計データとは異なり、イベントレベルのデータはGitLabに利用状況に関するより深いインサイトを提供し、プラットフォームのユーザーエクスペリエンスを改善し、機能の採用を増やすことを可能にします。データ共有設定の調整方法に関する詳細な手順については、当社のドキュメントを参照してください。

### すべてのユーザーが利用できる削除保護 {#deletion-protection-available-for-all-users}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../administration/settings/visibility_and_access_controls.md#deletion-protection) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/17208) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/526405)

{{< /details >}}

プロジェクトおよびグループの遅延削除が、Free層のユーザーを含むすべてのGitLabユーザーで利用可能になりました。この重要な安全機能により、削除されたグループとプロジェクトが完全に削除される前に猶予期間（GitLab.comでは7日間）が追加されます。この機能により、複雑なリカバリー操作なしで偶発的な削除からリカバリーできます。

データ安全性をコア機能とすることで、GitLabはデータ損失イベントからお客様の作業をより適切に保護できます。

### ユーザーネームスペースのプロジェクト遅延削除 {#delayed-project-deletion-for-user-namespaces}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/working_with_projects.md#delete-a-project) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/536244)

{{< /details >}}

ユーザーネームスペース（個人プロジェクト）内のプロジェクトで、遅延削除が利用可能になりました。以前は、偶発的なデータ損失に対するこの保護機能は、グループネームスペースでのみ利用可能でした。ユーザーネームスペースでプロジェクトを削除すると、すぐに削除されるのではなく、インスタンス設定で構成された期間（GitLab.comでは7日間）「削除保留中」の状態になります。これにより、必要に応じてプロジェクトを復元することができるリカバリー期間が作成されます。

この機能強化により、GitLabで個人プロジェクトを管理する際の安心感が高まることを願っています。

### グループおよびプロジェクトREST APIの新しい`active`パラメータ {#new-active-parameter-for-groups-and-projects-rest-apis}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../api/projects.md#list-projects)

{{< /details >}}

グループのステータスに基づいてフィルタリングを簡素化する新しい`active`パラメータをグループおよびプロジェクトREST APIに追加しました。`true`に設定すると、アーカイブされていないグループまたは削除対象としてマークされていないプロジェクトのみが返されます。`false`に設定すると、アーカイブされたグループまたは削除対象としてマークされたプロジェクトのみが返されます。パラメータが未定義の場合、フィルタリングは適用されません。この機能強化により、単純なAPIコールを通じて特定のステータスをターゲットにすることで、ワークフローを効率的に管理できます。

このパラメータをProjects APIに追加してくださった[@dagaranupam](https://gitlab.com/dagaranupam)に感謝いたします。

### グループ、プロジェクト、およびユーザーAPIのレート制限 {#rate-limits-for-groups-projects-and-users-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/gitlab_com/_index.md#rate-limits-on-gitlabcom) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/461316)

{{< /details >}}

すべてのユーザーのプラットフォームの安定性とパフォーマンスを向上させるため、プロジェクト、グループ、およびユーザーに対するAPIレート制限を追加しました。これらの変更は、当社のサービスに影響を与えていたAPIトラフィックの増加に対応するものです。

制限は平均的な使用パターンに基づいて慎重に設定されており、ほとんどのユースケースに十分な容量を提供します。これらの制限を超えると、「429 Too Many Requests」応答が返されます。

特定のレート制限と実装情報の詳細については、[関連するブログ記事](https://about.gitlab.com/blog/rate-limitations-announced-for-projects-groups-and-users-apis/)を参照してください。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### セキュリティスキャナーがMRパイプラインをサポートするようになりました {#security-scanners-now-support-mr-pipelines}

<!-- categories: API Security, Container Scanning, DAST, Fuzz Testing, SAST, Secret Detection, Software Composition Analysis -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/detect/roll_out_security_scanning.md)

{{< /details >}}

[アプリケーションセキュリティテスト（AST）スキャナー](../../user/application_security/detect/_index.md)を[マージリクエスト（MR）パイプライン](../../ci/pipelines/merge_request_pipelines.md)で実行することを選択できるようになりました。パイプラインへの影響を最小限に抑えるために、これは制御可能なオプトイン動作です。

以前は、スキャナーを有効にするために[StableまたはLatest CI/CDテンプレートエディション](../../user/application_security/detect/security_configuration.md#template-editions)を使用するかどうかに応じて、デフォルトの動作が異なりました:

- Stableテンプレートでは、スキャンジョブはブランチパイプラインでのみ実行されました。MRパイプラインはサポートされていませんでした。
- Latestテンプレートでは、MRが開いている場合はスキャンジョブはMRパイプラインで実行され、関連するMRがない場合はブランチパイプラインで実行されました。この動作を制御することはできませんでした。

現在、新しいオプション`AST_ENABLE_MR_PIPELINES`により、MRパイプラインでジョブを実行するかどうかを制御できます。StableとLatestの両方のテンプレートのデフォルトの動作は同じです。具体的には次のとおりです。

- Stableテンプレートは引き続きスキャンジョブをブランチパイプラインでデフォルトで実行しますが、MRが開いている場合は`AST_ENABLE_MR_PIPELINES: "true"`を設定してMRパイプラインを使用できます。
- 最新のテンプレートは、MRが開いている場合はデフォルトでスキャンジョブをMRパイプラインで実行し続けますが、代わりにブランチパイプラインを使用するように`AST_ENABLE_MR_PIPELINES: "false"`を設定できます。

この改善は、現在MRパイプラインがデフォルトであるAPI Discovery（`API-Discovery.gitlab-ci.yml`）を除くすべてのセキュリティスキャンテンプレートに影響します。また、API DiscoveryテンプレートをGitLab 18.0の他のStableテンプレートと連携させ、ブランチパイプラインをデフォルトで使用するように変更しました。

### コンプライアンスプロジェクトレポートでアーカイブされたプロジェクトを表示およびフィルタリング {#display-and-filter-archived-projects-in-the-compliance-projects-report}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate、Premium
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_projects_report.md#filter-the-compliance-projects-report) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/500520)

{{< /details >}}

コンプライアンスプロジェクトレポートでは、グループまたはサブグループ内のプロジェクトに適用されたコンプライアンスフレームワークを表示できます。

しかし、レポートにはプロジェクトがアーカイブされているかどうかを示す機能が不足しており、これはアクティブユーザーとアーカイブされたプロジェクト全体でコンプライアンスを管理する上で有用な情報となる可能性があります。

そのため、プロジェクトがアーカイブされているかどうかを示すインジケーターを追加しました。これにより、アクティブユーザーとアーカイブされたプロジェクト全体でコンプライアンスフレームワークをレビューする際に、より優れた表示レベルとコンテキストが提供されます。

この機能には以下が含まれます:

- コンプライアンスプロジェクトレポート内の各プロジェクトのアーカイブ済みステータスバッジで、プロジェクトがアーカイブされているかどうかを表示します。
- アーカイブ済み、未アーカイブ、またはすべてのプロジェクトを切替できるフィルター。

### マージリクエストからワークスペースを作成 {#create-a-workspace-from-merge-requests}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/workspace/configuration.md#create-a-workspace)

{{< /details >}}

新しい**ワークスペースで開く**オプションで、マージリクエストから直接ワークスペースを作成できるようになりました。この機能は、マージリクエストのブランチとコンテキストでワークスペースを自動的に構成し、以下を行うことができます:

- 完全に構成された環境でコード変更をレビューします。
- マージリクエストブランチでテストを実行して機能を検証します。
- ローカルセットアップなしでマージリクエストに追加の変更を行います。

### ファイルをターゲットとする開いているマージリクエストを表示 {#view-open-merge-requests-targeting-files}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/repository/files/_index.md#view-open-merge-requests-for-a-file) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/448868)

{{< /details >}}

以前は、コードファイルを操作しているとき、他のブランチで誰が同じファイルを変更しているかについての表示レベルがありませんでした。この意識の欠如は、マージコンフリクト、重複した作業、および非効率なコラボレーションにつながりました。

これにより、リポジトリで表示しているファイルを変更するすべての開いているマージリクエストを簡単に特定できます。この機能は以下の点で役立ちます:

- 発生する前に潜在的なマージコンフリクトを特定します。
- すでに進行中の作業の重複を回避します。
- 進行中の変更を表示レベルで提供することにより、コラボレーションを改善します。

バッジはファイルを変更する開いているマージリクエストの数を表示し、カーソルを合わせるとこれらのマージリクエストのリストを含むポップオーバーが表示されます。

### Kubernetesの共有ネームスペースとワークスペース {#shared-kubernetes-namespace-for-workspaces}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/workspace/settings.md#shared_namespace)

{{< /details >}}

共有KubernetesネームスペースにGitLabワークスペースを作成できるようになりました。これにより、すべてのワークスペースに新しいネームスペースを作成する必要がなくなり、エージェントに昇格されたClusterRole権限を付与する要件がなくなります。この機能を使用すると、セキュリティ保護された環境や制限された環境でワークスペースをより簡単に採用でき、スケールするためのよりシンプルなパスを提供します。

共有ネームスペースを有効にするには、エージェント設定ファイルの`shared_namespace`フィールドを、すべてのワークスペースに使用するKubernetesネームスペースを指定するように設定します。

[GitLabの共同開発プログラム](https://about.gitlab.com/community/co-create/)を通じてこの機能のビルドを支援してくださった数十人のコミュニティコントリビューターに感謝いたします！

### Kubernetesのダッシュボードにおけるポッドステータス表示の改善 {#improved-pod-status-visualizations-in-the-dashboard-for-kubernetes}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../ci/environments/kubernetes_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/525081)

{{< /details >}}

Kubernetesのダッシュボードを使用して、デプロイされたアプリケーションを監視できます。これまで、`CrashLoopBackOff`や`ImagePullBackOff`のようなコンテナエラーを持つポッドは「保留中」または「実行中」のステータスで表示され、`kubectl`を使用しないと問題のあるデプロイメントを特定することが困難でした。

GitLab 18.0では、UIのエラーステータスは、`kubectl`出力と同様に、特定のコンテナのステータスを表示します。これにより、GitLabインターフェースを離れることなく、障害が発生したポッドを迅速に特定し、トラブルシューティングを行うことができます。

### ライセンス承認ルールからパッケージを除外する {#exclude-packages-from-license-approval-rules}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#license_finding-rule-type) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10203)

{{< /details >}}

マージリクエスト承認ポリシーにおいて、ライセンス承認ポリシーのこの新しい機能強化により、法務およびコンプライアンスチームは、どのパッケージが特定のライセンスを使用できるかをより詳細に制御できるようになります。組織のポリシーによって通常ブロックされるライセンスを使用している場合でも、事前に承認されたパッケージの例外を作成できるようになりました。

以前は、ライセンス承認ポリシーでAGPL-3.0のようなライセンスをブロックした場合、組織全体のすべてのパッケージでブロックされていました。これにより、以下のような課題が生じました:

- 法務チームが、通常は制限されているライセンスを持つ特定のパッケージを事前に承認した場合。
- 数百のプロジェクトで同じパッケージを使用する必要がある場合。
- 異なるチームが異なるライセンス例外を必要とする場合。

このリリースにより、必要な例外を許可しながら厳格なライセンスガバナンスを維持でき、承認のボトルネックと手動レビューを大幅に削減できます。たとえば、次のことができます:

- パッケージURL（PURL）形式を使用して、ライセンス承認ルールのパッケージ固有の例外を定義します。
- 特定のパッケージ（またはパッケージバージョン）が、通常は制限されているライセンスを使用できるようにします。
- 特定のパッケージ（またはパッケージバージョン）が、一般的に許可されているライセンスを使用することをブロックします。

例外を追加するには、ライセンス承認ポリシーを作成または編集する際に、次のワークフローに従います:

1. グループで、**Security & Compliance** > **ポリシー**に移動します。
1. ライセンス承認ポリシーを作成または編集します。
1. ビジュアルエディタで新しいパッケージ例外オプションを見つけるか、YAMLモードで構成します。
1. ライセンスの許可リストモードまたは拒否リストモードを選択します。
1. ポリシーに特定のライセンスを追加します。
1. 各ライセンスについて、PURL形式でパッケージ例外を定義します（例: `pkg:npm/@angular/animation@12.3.1`）。
1. これらのパッケージをライセンスルールに含めるか除外するかを指定します。

その後、ポリシーは定義された例外を尊重しながらライセンスルールを適用し、組織全体のライセンスコンプライアンスをきめ細かく制御できます。

### 最大ユーザーセッション長を制限する {#limit-maximum-user-session-length}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/settings/account_and_limit_settings.md#set-sessions-to-expire-from-creation-date) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/395038)

{{< /details >}}

管理者は、ユーザーセッションの最大長を初回サインインから計算するか、最終アクティビティから計算するかを選択できるようになりました。ユーザーにはセッションが終了することが通知されますが、セッションの有効期限切れを防ぐことも、セッションを延長することもできません。この機能はデフォルトで無効になっています。

[John Parent](https://gitlab.kitware.com/john.parent)様のコントリビュートに感謝いたします！

### GitLab Query Languageビューの機能強化 {#gitlab-query-language-views-enhancements}

<!-- categories: Wiki, Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/glql/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15008)

{{< /details >}}

GLQL（GLQL）ビューに大幅な改善を加えました。これらの改善には、以下のサポートが含まれます:

- すべてのMasterdate型に対する`>=`および`<=`演算子
- ビューの**View actions**ドロップダウン
- **再読み込み**アクション
- フィールドエイリアス
- GLQLテーブルで列をカスタム名にエイリアスする

この機能強化および一般的なGLQLビューに関するフィードバックは、[イシュー509791](https://gitlab.com/gitlab-org/gitlab/-/issues/509791)にて歓迎いたします。

### ページテンプレートの改善 {#pages-template-improvements}

<!-- categories: Pages -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/project/pages/getting_started/pages_new_project_template.md#project-templates)

{{< /details >}}

GitLabは[人気のある静的サイトジェネレーターのテンプレート](https://gitlab.com/pages)を提供しています。スコアリングフレームワークを使用して利用可能なテンプレートを深く掘り下げ、最も人気のあるテンプレートのみを含むようにリストを絞り込みました。

GitLab Pagesで利用可能なテンプレートを洗練することで、Webサイト作成プロセスが合理化されます。テンプレートを使用して、最小限の技術的専門知識でプロフェッショナルな外観のサイトを起動します。強化されたテンプレートは、モダンでレスポンシブなデザインも提供し、カスタム開発作業の必要性を排除します。

### 脆弱性からJiraイシューをJiraインテグレーションAPIを使用して設定する {#configure-jira-issues-from-vulnerabilities-using-the-jira-integration-api}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../api/project_integrations.md#jira-issues) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/454574)

{{< /details >}}

以前は、**プロジェクトの設定**ページから、インテグレーションを構成して[脆弱性からJiraイシューを作成](../../integration/jira/configure.md#create-a-jira-issue-for-a-vulnerability)する必要がありました。

プロジェクトインテグレーションAPIからこのインテグレーションを構成できるようになり、セットアップを自動化できます。

### 再検出された脆弱性の追跡可能性の改善 {#improved-traceability-of-redetected-vulnerabilities}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/_index.md#vulnerability-status-values) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/523452)

{{< /details >}}

以前は、解決済みの脆弱性が再検出されてステータスが変更された場合、その脆弱性の詳細には、ステータス変更がいつ、なぜ発生したかを示す情報が提供されませんでした。

GitLabは、解決済みの脆弱性が新しいスキャンに表示されたためにステータスが変更された場合、脆弱性履歴にシステムノートを追加するようになりました。この追加情報は、ユーザーが脆弱性のステータスが変更された理由を理解するのに役立ちます。

### 脆弱性レポートから脆弱性をイシューに一括追加する {#bulk-add-vulnerabilities-to-issues-from-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md#add-vulnerabilities-to-an-existing-issue) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13216)

{{< /details >}}

このリリースにより、脆弱性レポートから新規または既存のGitLabイシューに脆弱性を一括追加できるようになりました。複数のイシューと脆弱性を関連付けることができるようになりました。さらに、関連する脆弱性がイシューページ内に表示されるようになりました。

### ユーザー招待を無効にする {#disable-user-invitations}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../administration/settings/visibility_and_access_controls.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/19618)

{{< /details >}}

グループまたはプロジェクトへのメンバー招待機能を削除できるようになりました。

- GitLab.comでは、この設定はEnterpriseユーザーを持つグループのオーナーによって構成され、トップレベルグループ内の任意のサブグループまたはプロジェクトに適用されます。この設定が有効な間は、どのユーザーも招待を送信できません。
- GitLab Self-Managedでは、この設定は管理者によって行われ、インスタンス全体に適用されます。管理者は引き続きユーザーを直接招待できます。

この機能は、組織がメンバーシップアクセスを厳密に管理するのに役立ちます。

### GitLabユーザー名によるLDAP認証 {#ldap-authentication-with-gitlab-username}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../administration/auth/ldap/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/215357)

{{< /details >}}

LDAPユーザーは、GitLabユーザー名でリクエストを認証することができるようになりました。以前は、GitLabユーザー名がLDAPユーザー名と一致しない場合、GitLabは認証エラーを返していました。この変更は、命名規則をGitLabとLDAPシステムで分離したまま、承認ワークフローを妨げることなく、ユーザーが利用できるようになります。

### SHA256 SAML証明書のサポート {#support-for-sha256-saml-certificates}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../integration/saml.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/524624)

{{< /details >}}

GitLabは、グループSAML認証のためにSHA1とSHA256の両方の証明書フィンガープリントを自動的に検出してサポートするようになりました。これにより、既存のSHA1フィンガープリントとの後方互換性を維持しつつ、より安全なSHA256フィンガープリントのサポートが追加されます。このアップグレードは、SHA256がデフォルトとなる今後のruby-saml 2.xリリースに備えるために不可欠です。

### ジョブトークンのきめ細かい権限（ベータ版） {#granular-permissions-for-job-tokens-in-beta}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/jobs/fine_grained_permissions.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16199)

{{< /details >}}

パイプラインセキュリティの柔軟性が向上しました。ジョブトークンは、パイプライン内のリソースへのアクセスを提供する一時的な認証情報です。これまでは、これらのトークンはユーザーから完全な権限を継承しており、しばしば不必要に広範なアクセス能力をもたらしていました。

新しい[ジョブトークンのきめ細かい権限](../../ci/jobs/fine_grained_permissions.md)ベータ機能を使用すると、ジョブトークンがプロジェクト内でアクセスできる特定のリソースを正確に制御できるようになりました。これにより、CI/CDワークフローで最小特権の原則を実装でき、各ジョブがそのタスクを完了するために必要な最小限のアクセスのみを付与します。

この機能について、コミュニティからのフィードバックを積極的に募るています。ご質問がある場合、実装経験を共有したい場合、または潜在的な改善について当社のチームと直接関与したい場合は、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/519575)にアクセスしてください。

### カスタムロールの新しい権限 {#new-permissions-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Dedicated
- リンク: [ドキュメント](../../user/custom_roles/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14746)

{{< /details >}}

[保護環境の管理](https://gitlab.com/gitlab-org/gitlab/-/issues/471385)権限を持つカスタムロールを作成できます。カスタムロールを使用すると、ユーザーがタスクを完了するために必要な特定の権限のみを付与できます。これにより、グループのニーズに合わせたロールを定義でき、オーナーまたはメンテナーロールを必要とするユーザーの数を減らすことができます。

### 限定利用可能なプロジェクト向けの新しいCI/CD分析ビュー {#new-cicd-analytics-view-for-projects-in-limited-availability}

<!-- categories: Fleet Visibility -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../user/analytics/ci_cd_analytics.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/444468)

{{< /details >}}

再設計されたCI/CD分析ビューは、開発チームがパイプラインのパフォーマンスと信頼性を分析、監視、最適化する方法を変革します。デベロッパーは、パフォーマンスの傾向と信頼性メトリクスを明らかにするGitLab UIの直感的な視覚化にアクセスできます。これらのインサイトをプロジェクトリポジトリに埋め込むことで、デベロッパーフローを中断させるコンテキスト切り替えがなくなります。チームは、生産性を低下させるパイプラインのボトルネックを特定して対処できます。この機能強化により、開発サイクルが加速され、コラボレーションが改善され、データに基づいた確信を持ってGitLabのCI/CDワークフローを最適化できます。

### GitLab Runner 18.0 {#gitlab-runner-180}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 18.0もリリースします！GitLab Runnerは、CI/CDジョブを実行し、その結果をGitLabインスタンスに送信する、拡張性の高いビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [GitLab Runnerビルドエラー分類に`ConfigurationError`および`ExitCodeInvalidConfiguration`を追加](https://gitlab.com/gitlab-org/gitlab/-/issues/514297)
- [失敗したキャッシュのアップロードに関するクラウドプロバイダーのエラーメッセージを改善](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/5527)

#### バグ修正 {#bug-fixes}

- [GitLab Runnerは、許可されていない場合でもキャッシュされたイメージを使用できる](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38706)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-0-stable/[CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/18-0-stable/CHANGELOG.md).md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.0)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=18.0)
- [UI改善](https://papercuts.gitlab.com/?milestone=18.0)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
