---
stage: Release Notes
group: Monthly Release
date: 2024-06-20
title: "GitLab 17.1リリースノート"
description: "GitLab 17.1は、モデルレジストリのベータ版が利用可能になりリリースされました。"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024年6月20日に、GitLab 17.1は次の機能を備えてリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター {#this-months-notable-contributor}

誰もがGitLabコミュニティのコントリビューターを[推薦](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)できます！活躍中の候補者を支援するか、新しい推薦を追加してください！ 🙌

Shubham Kumarは、17.1中に7つのイシューを[完了](https://gitlab.com/dashboard/issues?sort=due_date_desc&state=closed&assignee_username%5B%5D=imskr&milestone_title=17.1)し、2021年からGitLabに一貫してコントリビュートしています。彼は現在、50件以上のマージされたコントリビュートを達成しました！Shubhamは[GitLabヒーロー](https://contributors.gitlab.com/docs/previous-heroes)であり、元Google Summer of Codeのコントリビューターです。

Shubhamは、GitLabのシニアプロダクトマネージャーである[Christina Lohr](https://gitlab.com/lohrc)によって推薦されました。「Shubhamは、過去数週間および数か月にわたり、特に当社のAPI提供におけるギャップを埋めるのに多くのイシューを助けてきました」とChristinaは述べています。「Shubhamが進めているすべての追加に対応するために、リリース投稿を十分に早く書くことができません！」

「オープンソースコミュニティは素晴らしいです」とShubhamは言います。「機会と評価に感謝しており、GitLabプラットフォームへのコントリビュートを継続することを楽しみにしています。」

Joe Snyderは、GitLabのプリンシパルプロダクトマネージャーである[Kai Armstrong](https://gitlab.com/phikai)によって、[メールに差分が含まれることを制限](https://gitlab.com/gitlab-org/gitlab/-/issues/24733)する多くの要望があった機能を構築したことで推薦されました。このコントリビュートは、GitLab 15.3までさかのぼる10件以上のマージリクエストを要しました。「これは、そのサポートを可能にするために、多くのマイルストーン、複雑な移行、および製品への変更を要する大規模な機能です」とKaiは述べています。「Joeは、この作業を完了させるために、マイルストーンを通じて多くのメンテナーや協力者と熱心に協力しました。」

GitLabのプロダクトマネージャーである[Jocelyn Eillis](https://gitlab.com/jocelynjane)は、[`build:resource_group`内のネストされた変数が展開されない](https://gitlab.com/gitlab-org/gitlab/-/issues/361438)バグを修正するための追加作業を強調することで、Joeの推薦を支持しました。「このバグは、イシュー自体に文書化された顧客の要望に加え、23件の賛成票がありました」とJocelynは述べています。「レビュアーからのフィードバックへの迅速な対応により、GitLab 17.1にこれを組み込むことができました！」

これは、Joeが以前に[GitLab 16.6](https://about.gitlab.com/releases/2023/11/16/gitlab-16-6-released/#mvp)で受賞したのに続く2度目のGitLab MVPです。Joeは[Kitware](https://www.kitware.com/)のシニアR&Dエンジニアであり、2021年からGitLabにコントリビュートしています。

## 主要な機能 {#primary-features}

### モデルレジストリのベータ版が利用可能です {#model-registry-available-in-beta}

<!-- categories: MLOps -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/ml/model_registry/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9423)

{{< /details >}}

GitLabは、モデルレジストリをファーストクラスのコンセプトとしてベータ版で正式にサポートするようになりました。UIを介して直接モデルを追加および編集することも、MLflowインテグレーションを使用してGitLabをモデルレジストリバックエンドとして利用することもできます。

モデルレジストリは、データサイエンスチームが機械学習モデルとその関連メタデータを管理するのに役立つハブです。これは、組織が訓練された機械学習モデルを保存、バージョン管理、ドキュメント化、発見するための集中型ロケーションとして機能します。これにより、モデルのライフサイクル全体にわたるより良いコラボレーション、再現性、およびガバナンスが保証されます。

私たちはモデルレジストリを、チームがモデルをコラボレーションし、デプロイし、監視し、継続的にトレーニングできるようにする要石となるコンセプトであると考えており、皆様からのフィードバックに非常に関心があります。私たちの[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/465405)に気軽にコメントを残してください。後ほどご連絡いたします！

### GitLab Duoコード提案をVS Codeで複数表示 {#see-multiple-gitlab-duo-code-suggestions-in-vs-code}

<!-- categories: Editor Extensions, Code Suggestions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/repository/code_suggestions/_index.md#view-multiple-code-suggestions) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1325)

{{< /details >}}

GitLab Duoコード提案は、VS Codeで複数の提案が利用可能であるかどうかを表示するようになりました。提案にカーソルを合わせ、矢印またはキーボードショートカットを使用して提案を切り替えます。

### シークレットプッシュ保護のベータ版が利用可能です {#secret-push-protection-available-in-beta}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/secret_detection/secret_push_protection/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/12729)

{{< /details >}}

シークレット (キーやAPIトークンなど) が誤ってGitリポジトリにコミットされた場合、リポジトリへのアクセス権を持つ人は誰でも、悪意のある目的でシークレットのユーザーになりすますことができます。このリスクに対処するため、ほとんどの組織では公開されたシークレットを失効させて置き換える必要がありますが、そもそもシークレットがプッシュされるのを防ぐことで、修正時間を節約し、リスクを軽減できます。

シークレットプッシュ保護は、GitLabにプッシュされた各コミットの内容をチェックします。[シークレットが検出された場合](../../user/application_security/secret_detection/secret_push_protection/_index.md#detected-secrets)、プッシュはブロックされ、コミットに関する情報が表示されます。これには次のものが含まれます:

- シークレットを含むコミットID。
- シークレットを含むファイル名と行番号。
- シークレットのタイプ。

テストのためにシークレットプッシュ保護をバイパスする必要がありますか？シークレットプッシュ検出をスキップすると、GitLabは監査イベントをログに記録するため、調査できます。

シークレットプッシュ保護は、GitLab.comおよびDedicatedのお客様向けにベータ機能として利用可能であり、[プロジェクトごと](../../user/application_security/secret_detection/secret_push_protection/_index.md#enable-secret-push-protection-in-a-project)に有効にできます。[イシュー467408](https://gitlab.com/gitlab-org/gitlab/-/issues/467408)でフィードバックを提供することで、シークレットプッシュ保護の改善にご協力いただけます。

### GitLab Runner Autoscalerは一般公開されました {#gitlab-runner-autoscaler-is-generally-available}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner/runner_autoscale/) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29221)

{{< /details >}}

GitLabの以前のバージョンでは、一部の顧客は公開クラウドプラットフォーム上の仮想マシンインスタンスでGitLab Runnerのオートスケールソリューションを必要としていました。これらの顧客は、従来の[Docker Machine Executor](https://docs.gitlab.com/runner/configuration/autoscale.html)またはクラウドプロバイダーテクノロジーを使用してまとめられたカスタムソリューションに依存する必要がありました。

本日、GitLab Runner Autoscalerの一般公開をお知らせできることを嬉しく思います。GitLab Runner Autoscalerは、GitLabが開発したtaskscalerおよび[fleeting](https://docs.gitlab.com/runner/fleet_scaling/fleeting.html)テクノロジーと、Google Compute Engine用のクラウドプロバイダープラグインで構成されています。

### Snowflake MarketplaceでGitLabコネクタアプリケーションが利用可能になりました {#gitlab-connector-application-now-available-on-the-snowflake-marketplace}

<!-- categories: Audit Events, Compliance Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../integration/snowflake.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13004)

{{< /details >}}

監査イベントはGitLabで作成され、保存されます。このリリース以前は、監査イベントはGitLab内からしかアクセスできず、結果はGitLab UIを使用してレビューするか、すべての監査イベントを構造化されたJSONとして受信するためのストリーミング先を設定するかのいずれかでした。

しかし、顧客は監査イベントをサードパーティの宛先 (SnowflakeのようなSIEMソリューションなど) で利用できるようにし、次のことを容易にしたいと考えていました:

- GitLabを含む組織の複数のシステムからのすべての監査イベントデータを表示、結合、操作し、レポートを作成する。
- 関心のある特定の監査イベントのみを確認し、関心のある質問に迅速に回答できるようにする。
- GitLab内部で何が起こっているかを完全に把握し、事後的にレビューできるようにする。

これらのタスクを顧客が実行できるように、当社は[Snowflake Marketplace](https://app.snowflake.com/marketplace/listing/GZTYZXESENG/gitlab-gitlab-data-connector)向けにGitLabコネクタアプリケーションを作成しました。これは監査イベントAPIを使用します。この機能を利用するには、顧客はSnowflake Marketplaceを使用してアプリケーションをデプロイおよび管理する必要があります。

### Wikiのユーザーエクスペリエンスの改善 {#improved-wiki-user-experience}

<!-- categories: Wiki -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/wiki/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/452225)

{{< /details >}}

GitLab 17.1のWiki機能は、より統一され、効率的なワークフローを提供します:

- 新しいリポジトリクローンボタンにより、[クローン作成がより簡単かつ迅速に](https://gitlab.com/gitlab-org/gitlab/-/issues/281830)なります。これにより、コラボレーションが改善され、編集または表示のためのWikiコンテンツへのアクセスが高速化されます。
- より発見しやすい場所に、[より分かりやすい削除オプション](https://gitlab.com/gitlab-org/gitlab/-/issues/335169)。これにより、検索に費やす時間を短縮し、Wikiページを管理する際の潜在的なエラーや混乱を最小限に抑えます。
- [空のページを有効にする](https://gitlab.com/gitlab-org/gitlab/-/issues/221061)ことで、柔軟性が向上します。必要なときに空のプレースホルダーを作成します。Wikiコンテンツのより良い計画と整理に焦点を当て、空のページは後で埋めてください。

これらの機能強化により、Wikiのワークフローにおける使いやすさ、発見しやすさ、およびコンテンツ管理が向上します。私たちは、Wiki体験が効率的でユーザーフレンドリーであることを望んでいます。リポジトリのクローン作成をよりアクセスしやすくし、主要なオプションをより良い表示レベルのために再配置し、空のプレースホルダーの作成を可能にすることで、当社はユーザーのニーズをよりよく満たすためにプラットフォームを改良しています。

### 新しいバリューストリーム管理レポート生成ツール {#new-value-stream-management-report-generator-tool}

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/analytics/value_streams_dashboard.md#schedule-reports) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/10880)

{{< /details >}}

新しいバリューストリーム管理用レポート生成ツールの追加により、意思決定者はソフトウェア開発ライフサイクル (SDLC) の最適化において、より効率的かつ効果的になることができます。

これで、[DevSecOps比較メトリクスレポート](https://gitlab.com/components/vsd-reports-generator#example-for-monthly-executive-value-streams-report)または[AIインパクト分析](https://about.gitlab.com/releases/2024/05/16/gitlab-17-0-released/#ai-impact-analytics-in-the-value-streams-dashboard)レポートを、自動的、積極的に、関連情報とともにGitLabイシューに配信するようにスケジュールできます。スケジュールされたレポートを使用すると、管理者は必要なデータを含む適切なダッシュボードを手動で検索する時間を費やすことなく、インサイトの分析と情報に基づいた意思決定に集中できます。

スケジュールされたレポートツールは、[CI/CDカタログ](https://gitlab.com/explore/catalog)を使用してアクセスできます。

### コンテナイメージは署名にリンクされています {#container-images-linked-to-signatures}

<!-- categories: Container Registry -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/packages/container_registry/_index.md#container-image-signatures) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/7856)

{{< /details >}}

GitLabコンテナレジストリは、署名されたコンテナイメージをその署名と関連付けるようになりました。この改善により、ユーザーはより簡単に次のことができます:

- どのイメージが署名されており、どのイメージが署名されていないかを特定する。
- コンテナイメージに関連付けられている署名を検索して検証する。

この改善は、GitLab.comでのみ一般公開されています。セルフマネージドのサポートはベータ版であり、ユーザーは[次世代コンテナレジストリ](../../administration/packages/container_registry_metadata_database.md)を有効にする必要があります。これもベータ版です。

### 手動ジョブの確認を必須にする {#require-confirmation-for-manual-jobs}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/jobs/job_control.md#require-confirmation-for-manual-jobs) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/18906)

{{< /details >}}

手動ジョブは、本番環境へのデプロイなど、CIパイプラインで非常に重要な操作をトリガーするために使用できます。このリリースにより、手動ジョブを実行する前に確認を要求するように設定できるようになりました。手動でジョブが実行されたときに、UIに確認ダイアログを表示するには、`manual_confirmation`と`when: manual`を使用します。手動ジョブに確認を要求することで、セキュリティと制御の追加レイヤーが提供されます。

このコミュニティコントリビュートを提供してくれた[Phawin](https://gitlab.com/lifez)に感謝します！

### グループのRunnerフリートダッシュボード {#runner-fleet-dashboard-for-groups}

<!-- categories: Fleet Visibility -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/runner_fleet_dashboard_groups.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/424789)

{{< /details >}}

グループレベルでセルフマネージドのRunnerフリートを運用するオペレーターは、可観測性と、Runnerフリートインフラストラクチャに関する重要な質問に一目で迅速に回答できる能力を必要とします。グループ向けのRunnerフリートダッシュボードを使用すると、GitLab UIでRunnerフリートの可観測性と実用的なインサイトを直接利用できます。組織の目標サービスレベル目標において、Runnerの健全性を迅速に判断し、Runnerの使用メトリクス、およびCI/CDジョブキューサービス機能に関するインサイトを得ることができます。

GitLab.comのお客様は、本日グループで利用可能なすべてのRunnerフリートダッシュボードメトリクスを使用できます。セルフマネージドのお客様は、ほとんどのRunnerフリートダッシュボードメトリクスを使用できますが、**Runner usage**と**ジョブを選択するまでの待機時間**メトリクスを使用するには、ClickHouse分析データベースを設定する必要があります。

## 規模とデプロイ {#scale-and-deployments}

### Omnibusの改善 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 17.1には、[Ubuntu Noble 24.04](../../install/package/_index.md)をサポートするためのパッケージが含まれています。

### グループとプロジェクトの新しいGraphQL API引数`markedForDeletionOn` {#new-graphql-api-argument-markedfordeletionon-for-groups-and-projects}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/graphql/reference/_index.md#querygroups) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/463809)

{{< /details >}}

新しいGraphQL API引数`markedForDeletionOn`を使用して、特定の日付に削除対象としてマークされたグループまたはプロジェクトを一覧表示できるようになりました。

このコミュニティコントリビュートを提供してくれた[@imskr](https://gitlab.com/imskr)に感謝します！

### グループおよびプロジェクトバッジの新しいプレースホルダー {#new-placeholders-for-group-and-project-badges}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/badges.md#placeholders) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/22278)

{{< /details >}}

これで、4つの新しいプレースホルダーを使用してバッジリンクと画像URLを作成できます:

- `%{project_namespace}` - プロジェクトネームスペースのフルパスを参照
- `%{group_name}` - グループ名を参照
- `%{gitlab_server}` - グループまたはプロジェクトのサーバー名を参照
- `%{gitlab_pages_domain}` - グループまたはプロジェクトのドメイン名を参照

このコミュニティコントリビュートを提供してくれた[@TamsilAmani](https://gitlab.com/TamsilAmani)に感謝します！

### バッジの新しい`%{latest_tag}`プレースホルダー {#new-latest_tag-placeholder-for-badges}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/badges.md#placeholders) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/26420)

{{< /details >}}

これで、`%{latest_tag}`プレースホルダーを使用してバッジリンクと画像URLを作成できます。このプレースホルダーは、リポジトリ用に公開された最新のタグを参照します。

このコミュニティコントリビュートを提供してくれた[@TamsilAmani](https://gitlab.com/TamsilAmani)に感謝します！

### グループAPIで日付`marked_for_deletion_on`によってグループをフィルタリングする {#filter-groups-by-marked_for_deletion_on-date-with-the-groups-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/groups.md#list-groups) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/429315)

{{< /details >}}

グループAPIで、特定の日付に削除対象としてマークされたグループを返す属性`marked_for_deletion_on`を使用して応答をフィルタリングできるようになりました。

このコミュニティコントリビュートを提供してくれた[@imskr](https://gitlab.com/imskr)に感謝します！

### ユーザーのコントリビュートしたプロジェクトをGraphQL APIで一覧表示 {#list-contributed-projects-of-a-user-with-graphql-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/graphql/reference/_index.md#usercontributedprojects) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/450191)

{{< /details >}}

新しいGraphQL APIフィールド`User.contributedProjects`を使用して、ユーザーがコントリビュートしたプロジェクトを一覧表示できるようになりました。

このコントリビュートをしてくれた[@yasuk](https://gitlab.com/yasuk)に感謝します！

### メンバーAPIでユーザー名によってメンバーを追加 {#add-members-by-username-with-the-members-api}

<!-- categories: User Management, Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/group_members.md#add-a-group-member) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/28208)

{{< /details >}}

以前は、メンバーAPIを使用すると、ユーザーIDのみでグループとプロジェクトにメンバーを追加できました。このリリースにより、ユーザー名でもメンバーを追加できるようになりました。

このコミュニティコントリビュートを提供してくれた[@imskr](https://gitlab.com/imskr)に感謝します！

### Exploreのソートおよびフィルタリング機能が更新されました {#updated-sorting-and-filtering-functionality-in-explore}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/working_with_projects.md#explore-all-projects-on-an-instance)

{{< /details >}}

グループおよびプロジェクトのExploreページのソートおよびフィルタリング機能を更新しました。フィルタリングバーが広くなり、読みやすさが向上しました。

プロジェクトのExploreページでは、**名前**、**作成日**、**更新した日**、および**Star付き**を含む標準化されたソートオプションを使用でき、昇順または降順でソートするためのナビゲーション要素も利用できます。言語フィルターはフィルターメニューに移動しました。新しい**非アクティブ**タブは、より焦点を絞った検索のためにアーカイブされたプロジェクトを表示します。さらに、**ロール**フィルターを使用して、あなたがオーナーであるプロジェクトを検索できます。

グループのExploreページでは、**名前**、**作成日**、および**更新した日**を含む標準化されたソートオプションを採用し、昇順または降順でソートするためのナビゲーション要素を追加しました。

これらの変更に関するフィードバックは、[イシュー438322](https://gitlab.com/gitlab-org/gitlab/-/issues/438322)で歓迎します。

### 表示レベルの選択が改善されました {#improved-visibility-level-selection}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/public_access.md#change-group-visibility) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/455668)

{{< /details >}}

以前は、グループまたはプロジェクトの一般設定には、許可された表示レベルのみが表示されていました。このビューは、他のオプションが利用できない理由を理解しようとするユーザーを混乱させることが多く、情報が不正確に表示される可能性がありました。新しいビューではすべての表示レベルが表示され、選択できないオプションは灰色表示されます。さらに、ポップオーバーは、オプションが利用できない理由についてさらに詳しい情報を提供します。たとえば、表示レベルは、管理者が制限したため、またはプロジェクトや親グループの表示レベル設定と競合するため、利用できない場合があります。

これらの変更が、希望する表示レベルオプションを選択する際の競合を解決するのに役立つことを願っています。このコミュニティコントリビュートを提供してくれた[@gerardo-navarro](https://gitlab.com/gerardo-navarro)に感謝します！

### プロジェクトAPIで日付`marked_for_deletion_on`によってプロジェクトをフィルタリングする {#filter-projects-by-marked_for_deletion_on-date-with-the-projects-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/projects.md#list-all-projects) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/463939)

{{< /details >}}

プロジェクトAPIで、特定の日付に削除対象としてマークされたプロジェクトを返す属性`marked_for_deletion_on`を使用して応答をフィルタリングできるようになりました。

このコミュニティコントリビュートを提供してくれた[@imskr](https://gitlab.com/imskr)に感謝します！

### Webhook作成時の監査イベント {#audit-event-on-webhook-creation}

<!-- categories: Webhooks, Audit Events -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/audit_event_types.md#webhooks) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/8068)

{{< /details >}}

監査イベントは、GitLabで実行された重要なアクションの記録を作成します。これまで、システム、グループ、またはプロジェクトWebhookがユーザーによって追加された場合、監査イベントは作成されませんでした。

このリリースでは、ユーザーがシステム、グループ、またはプロジェクトWebhookを作成したときに監査イベントを追加しました。

### 実行中の直接転送移行をキャンセルするにはREST APIを使用する {#use-rest-api-to-cancel-a-running-direct-transfer-migration}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/bulk_imports.md#cancel-a-migration) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/438281)

{{< /details >}}

これまで、実行中の直接転送移行をキャンセルするには、[Railsコンソールへのアクセス](../../user/group/import/direct_transfer_migrations.md#cancel-a-running-migration)が必要でした。

このリリースでは、管理者がREST APIを使用して移行をキャンセルする機能を追加しました。

### REST APIでグループフックをテスト {#test-group-hooks-with-the-rest-api}

<!-- categories: Webhooks -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/group_webhooks.md#trigger-a-test-group-hook) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/455589)

{{< /details >}}

以前は、プロジェクトフックのみをREST APIでテストできました。このリリースにより、指定されたグループのテストフックもトリガーできるようになりました。

このエンドポイントには、グループフックごとに1分あたり3リクエストという特別なレート制限があります。セルフマネージドのGitLabおよびGitLab Dedicatedでこの制限を無効にするには、管理者が`web_hook_test_api_endpoint_rate_limit`機能フラグを無効にできます。

[Phawin](https://gitlab.com/lifez)の[このコミュニティコントリビュート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150486)に感謝します！

### APIを使用して選択したプロジェクトリレーションを再インポートする {#re-import-a-chosen-project-relation-by-using-the-api}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/project_import_export.md#import-project-resources) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/455889)

{{< /details >}}

同じタイプの多くの項目 (マージリクエストやパイプラインなど) を含むエクスポートファイルからプロジェクトをインポートする場合、それらの項目の一部がインポートされないことがあります。

このリリースでは、名前付きリレーションを再インポートし、すでにインポートされた項目をスキップするAPIエンドポイントを追加しました。APIには次の両方が必要です:

- プロジェクトのエクスポートアーカイブ。
- タイプ。イシュー、マージリクエスト、パイプライン、またはマイルストーンのいずれか。

### 直接転送でインポートする際に継承されたメンバーシップ構造を保持する {#keep-inherited-membership-structure-when-importing-by-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/import/direct_transfer_migrations.md#user-membership-mapping) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/458834)

{{< /details >}}

これまで、直接転送によって移行する際に、[継承されたメンバーシップ](../../user/project/members/_index.md#membership-types)は確実にインポートされませんでした。これは、プロジェクトの継承されたメンバーが直接メンバーとしてインポートされたことを意味しました。

このリリースから、GitLabはプロジェクトメンバーシップを移行する前に、まずグループメンバーシップを移行するようになりました。これは、ソースGitLabインスタンス上の継承されたメンバーシップをレプリケートします。

### REST APIを使用してカスタムWebhookヘッダーを設定する {#use-the-rest-api-to-set-custom-webhook-headers}

<!-- categories: API, Webhooks -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/project_webhooks.md#set-a-custom-header) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/455528)

{{< /details >}}

GitLab 16.11では、[Webhookを作成または編集する際にカスタムヘッダーを追加する](https://about.gitlab.com/releases/2024/04/18/gitlab-16-11-released/#custom-webhook-headers)機能が導入されました。

このリリースにより、GitLab REST APIを使用してカスタムWebhookヘッダーを設定できるようになりました。

[Niklas](https://gitlab.com/Taucher2003)の[コミュニティコントリビュート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153768)に感謝します！

### バックアップにはディスクに保存された外部マージリクエストの差分が含まれる {#backups-include-external-merge-request-diffs-stored-on-disk}

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/backup_restore/backup_gitlab.md#backup-command)

{{< /details >}}

`gitlab-backup`ツールは、ローカルディスクに保存された[外部マージリクエストの差分](../../administration/merge_request_diffs.md)のバックアップをサポートするようになりました。注: `gitlab-backup`ツールは、オブジェクトストレージに保存されたファイルをバックアップしません。したがって、外部マージ差分がオブジェクトストレージに保存されている場合は、手動でバックアップする必要があります。

Cloud Native Hybrid環境向けの`backup-utility`はすでに外部マージリクエストの差分のバックアップをサポートしており、この機能は変更されません。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### コードレビューメールでの差分プレビューを無効にする {#disable-diff-previews-in-code-review-emails}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/group/manage.md#disable-diff-previews-in-email-notifications)

{{< /details >}}

マージリクエストでコードをレビューし、コード行にコメントすると、GitLabは参加者へのメール通知に差分の行を含めます。一部の組織ポリシーでは、メールを安全性の低いシステムとして扱ったり、メール用のインフラストラクチャを自分で管理していなかったりする場合があります。このため、IPまたはソースコードのアクセス制御にリスクが生じる可能性があります。

グループとプロジェクトで新しい設定が利用可能になり、組織がマージリクエストメールから差分プレビューを削除できるようになりました。これにより、機密情報がGitLab外部で利用できないようにすることができます。

これをコントリビュートしてくれた[Joe Snyder](https://gitlab.com/joe-snyder)に心から感謝します！

### 管理者は部分的なメールアドレスでユーザーを検索できます {#administrators-can-search-users-by-partial-email-address}

<!-- categories: User Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/admin_area.md#administering-users) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/20381)

{{< /details >}}

管理者は、管理者エリアのユーザー概要で部分的なメールアドレスでユーザーを検索できるようになりました。たとえば、特定のメールドメインでユーザーをフィルタリングして、特定の機関のすべてのユーザーを見つけることができます。この機能は、権限のないユーザーが他のアカウントのメールアドレスにアクセスするのを防ぐために、管理者に限定されています。

このコミュニティコントリビュートを提供してくれた[@zzaakiirr](https://gitlab.com/zzaakiirr)に感謝します！

### リリースページにリリースRSSフィードアイコンを表示 {#show-release-rss-icon-on-releases-page}

<!-- categories: Release Orchestration -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/releases/_index.md#track-releases-with-an-rss-feed) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/30988)

{{< /details >}}

新しいリリースが投稿されたときに通知を受け取る必要がありますか？GitLabは、リリース用のRSSフィードを提供するようになりました。プロジェクトリリースページにあるRSSフィードアイコンで、リリースフィードを購読できます。

このコントリビュートを提供してくれた[Martin Schurz](https://gitlab.com/schurzi)に感謝します！

### カスタムロールの新しい権限 {#new-permissions-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/custom_roles/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

GitLab 17.1では、次の新しい権限を持つカスタムロールを作成できます:

- [マージリクエスト設定の管理](../../user/custom_roles/abilities.md#code-review-workflow)
- [インテグレーションの管理](../../user/custom_roles/abilities.md#integrations)
- [デプロイトークンの管理](../../user/custom_roles/abilities.md#continuous-delivery)
- [CRM連絡先の読み取り](../../user/custom_roles/abilities.md#team-planning)

カスタムロールを使用すると、同等の権限を持つユーザーを作成することで、オーナーロールを持つユーザーの数を減らすことができます。これにより、グループのニーズに合わせて特別に調整されたロールを定義し、不要な特権昇格を防ぐことができます。

### マージリクエスト承認ポリシーはオープン/クローズを失敗させます (ポリシーエディタ) {#merge-request-approval-policies-fail-openclosed-policy-editor}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#fallback_behavior) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13227)

{{< /details >}}

以前の[イテレーション](https://gitlab.com/groups/gitlab-org/-/epics/10816)を基盤として、ポリシーエディタ内に新しいオプションを導入し、ユーザーがセキュリティポリシーをオープンで失敗させるか、クローズで失敗させるかを切り替えることができるようにしました。この機能強化により、YAMLサポートが拡張され、ポリシーエディタビュー内でのよりシンプルな設定が可能になります。

たとえば、オープンで失敗するように設定されたマージリクエストポリシーは、基準を評価するための十分な証拠がない場合でもマージリクエストをマージすることを許可します。証拠の不足は、アナライザーがプロジェクトで有効になっていないか、アナライザーがポリシーを評価するための結果を生成できなかったためである可能性があります。このアプローチにより、チームが適切なスキャンの実行と実施を確実にするための作業を行うにつれて、ポリシーの段階的なロールアウトが可能になります。

### プロジェクトオーナーは有効期限切れのアクセストークン通知を受け取ります {#project-owners-receive-expiring-access-token-notifications}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../security/tokens/_index.md#project-access-tokens) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/460818)

{{< /details >}}

プロジェクトオーナーと直接メンバーシップを持つメンテナーの両方が、プロジェクトアクセストークンの有効期限が近づくとメール通知を受け取るようになりました。以前は、プロジェクトメンテナーのみがこの通知を受け取っていました。これにより、より多くの人が今後のトークンの有効期限について情報を得られます。

あなたのコントリビュートに対して[Jacob Henner](https://gitlab.com/arcesium-henner)に感謝します！

### 画像アップロード時に貼り付けた画像を縮小する {#downscale-pasted-images-on-image-upload}

<!-- categories: Team Planning, Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/markdown.md#change-image-or-video-dimensions) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/419913)

{{< /details >}}

GitLab 17.1は、高解像度画像の処理を強化し、アップロード中に縮小できるようにします。以前は、画像は元のサイズで表示され、最適な表示品質とはなりませんでした。この改善により、大きな画像が、それが含まれるページの視覚的な流れを妨げないことが保証されます。

### リッチテキストエディタのドラッグ可能なメディア {#draggable-media-in-the-rich-text-editor}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/rich_text_editor.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/452233)

{{< /details >}}

以前は、リッチテキストエディタでメディアを移動するには、各項目を手動でコピーアンドペーストする必要がありました。これにより、イシュー、エピック、およびWikiへのメディアの組み込みが遅くなることがよくありました。GitLab 17.1では、リッチテキストエディタでメディアをドラッグアンドドロップできるようになり、編集中の効率性が大幅に向上しました。

### GitLab APIコールでの相互TLSに対するPagesのサポート {#pages-support-for-mutual-tls-in-gitlab-api-calls}

<!-- categories: Pages -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/pages/_index.md#support-mutual-tls-when-calling-the-gitlab-api) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/548)

{{< /details >}}

GitLabは、[SSL証明書によるクライアント認証を強制](https://docs.gitlab.com/omnibus/settings/ssl/#enable-2-way-ssl-client-authentication)するように設定できます。しかし、GitLab Pagesサービスはその機能と互換性がありませんでした。これは、クライアント証明書を使用するように設定できず、内部APIへのコールが拒否されたためです。

GitLab 17.1から、GitLab Pagesのクライアント証明書を設定できます。これにより、GitLab APIでクライアント認証を有効にし、GitLabインスタンスのセキュリティを強化できます。

### Wikiページの名前変更時に新しいURLにリダイレクト {#redirect-wiki-pages-to-new-url-when-renamed}

<!-- categories: Wiki -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/wiki/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/257892)

{{< /details >}}

GitLab 17.1は、Wikiページのリダイレクトに大幅な強化を導入します。Wikiページの名前を変更すると、古いページにアクセスしようとする人は誰でも新しいページに自動的にリダイレクトされ、既存のすべてのリンクが機能し続けることが保証されます。この改善により、ページ名の変更を管理するためのワークフローが効率化され、全体的な知識管理ユーザーエクスペリエンスが向上します。

### 更新されたPages UI {#updated-pages-ui}

<!-- categories: Pages -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/pages/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153250)

{{< /details >}}

GitLab 17.1では、Pagesユーザーインターフェースを改善しました。改善点には、より効率的な画面スペースの使用が含まれます。これらのUI改善は、Pagesを管理する際のユーザーエクスペリエンスと効率性の向上に焦点を当てています。

### コンテナイメージの最終公開日を表示 {#display-the-last-published-date-for-container-images}

<!-- categories: Container Registry -->

{{< details >}}

- プラン: Free、Silver、Gold
- リンク: [ドキュメント](../../user/packages/container_registry/_index.md#view-the-container-registry) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/290949)

{{< /details >}}

以前は、コンテナレジストリユーザーインターフェースで公開されたタイムスタンプが誤っていることがよくありました。これは、この重要なデータに依存してコンテナイメージを見つけ、検証できないことを意味していました。

GitLab 17.1では、正確な`last_published_at`タイムスタンプを含むようにUIを更新しました。**デプロイ > コンテナレジストリ**に移動し、タグを選択して詳細を表示することで、この情報を見つけることができます。最終公開日はページの上部に表示されます。

この改善は、GitLab.comでのみ一般公開されています。セルフマネージドのサポートはベータ版であり、ベータ版の[次世代コンテナレジストリ](../../administration/packages/container_registry_metadata_database.md)を有効にしているインスタンスでのみ利用可能です。

### コンテナレジストリのタグを公開日でソート {#sort-container-registry-tags-by-publish-date}

<!-- categories: Container Registry -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/packages/container_registry/_index.md#view-the-container-registry) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/7856)

{{< /details >}}

GitLabコンテナレジストリを使用して、ソースパイプラインとともにDockerまたはOCIイメージを表示、プッシュ、およびプルします。コンテナイメージがビルドされた後、それが正しくビルドされたことを検索して検証する必要があることがよくあります。多くの顧客にとって、ユーザーインターフェースを使用して正しいコンテナイメージを見つけることは困難な場合があります。

これで、コンテナレジストリのタグリストを公開日でソートできるようになりました。この機能を使用して、最も最近公開されたコンテナイメージをすばやく見つけて検証できます。

この改善は、GitLab.comでのみ一般公開されています。セルフマネージドのサポートは、ベータ版である次世代コンテナレジストリが必要であるためベータ版です。詳細については、[コンテナレジストリのメタデータドキュメント](../../administration/packages/container_registry_metadata_database.md)を参照してください。

### よりスムーズなワークフローのためのリアルタイムボード更新 {#real-time-board-updates-for-a-smoother-workflow}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/issue_board.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/468187)

{{< /details >}}

これで、[ボード](../../user/project/issue_board.md)上のイシューを更新する際に、よりスムーズなエクスペリエンスを実感できるようになります！サイドバーで行った変更はボード自体に即座に表示され、再更新は不要です。この反応型ボードエクスペリエンスは、ワークフローを効率化し、リアルタイムで反映されるのを確認しながら迅速に更新を行うことができます。

### タスクにかかる時間を {#track-time-on-tasks}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/time_tracking.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/438577)

{{< /details >}}

このリリースにより、[クイックアクション](../../user/project/quick_actions.md)を使用するか、タスクのサイドバーにあるタイムトラッキングウィジェットで、時間見積もりを設定し、タスクに費やした時間を記録できるようになりました。タスクに費やした時間は、タスクのタイムトラッキングレポートで確認できます。

### エピックの進捗率を理解する {#understand-an-epics-progress-percentage}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/epics/manage_epics.md#manage-issues-assigned-to-an-epic) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/5163)

{{< /details >}}

これで、エピックの全体的な進捗状況を、その子項目のウェイトの完了に基づいて簡単に確認できるようになりました。階層ウィジェットのこの新しい進捗ロールアップにより、エピックの作業の完全なスコープを理解し、進行に合わせて進捗を追跡することが容易になります。

### APIセキュリティテストアナライザーの更新 {#api-security-testing-analyzer-updates}

<!-- categories: API Security -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/api_security_testing/configuration/variables.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/14170)

{{< /details >}}

GitLab 17.1は、APIセキュリティテスト用に次の設定変数を追加します:

1. `APISEC_SUCCESS_STATUS_CODES`は、APIセキュリティテストスキャンジョブが合格したかどうかを定義するHTTP成功ステータスコードのカンマ区切りリストを作成します。
1. `APISEC_TARGET_CHECK_DISABLED`は、スキャンが開始される前にターゲットAPIが利用可能になるのを待つのを無効にします。
1. `APISEC_TARGET_CHECK_STATUS_CODE`は、APIターゲットの可用性チェックの予期されるステータスコードを指定します。提供されていない場合、500以外の任意のステータスコードはスキャナーによって受け入れられます。

これらの新しい変数は、スキャンが正常に実行されることを保証するためのより大きなカスタマイズと柔軟性を提供します。

DAST APIは16.10でAPIセキュリティテストに名称変更されました。変数名は、プレフィックス`APISEC`で始まるようになりました。以前は、`DAST_API`で始まっていました。`DAST_API`でプレフィックスされた変数は、18.0 (2025年5月) までサポートされます。設定が期待どおりに機能するように、変数名をできるだけ早く更新してください。

### レジストリのコンテナスキャン {#container-scanning-for-registry}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/container_scanning/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/2340)

{{< /details >}}

GitLabコンポジション解析は、レジストリのコンテナスキャンをサポートするようになりました。

レジストリのコンテナスキャンがプロジェクトで有効になっており、コンテナイメージがプロジェクトのコンテナレジストリにプッシュされた場合、GitLabはそのタグとスキャン制限をチェックします。

タグが`latest`であり、スキャンの数が制限 (スキャン数50回/日) 未満である場合、GitLabはイメージ上で`container_scanning`ジョブを実行する新しいパイプラインを作成します。このパイプラインは、イメージをレジストリにプッシュしたユーザーに関連付けられます。

スキャンジョブは、GitLabにアップロードされるCycloneDX SBOMを生成します。継続的脆弱性スキャン機能がアクティブ化され、SBOMで検出されたパッケージをスキャンします。

注: 脆弱性スキャンは、新しいアドバイザリが公開された場合にのみ実行されます。これは、[パッケージメタデータが同期された](../../administration/settings/security_and_compliance.md)ときに発生します。

いつものように、新しくリリースされた機能に関するフィードバックをお待ちしております。フィードバックを提供するには、この[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/466117)にコメントしてください。

### ファズテストアナライザーの更新 {#fuzz-testing-analyzer-updates}

<!-- categories: Fuzz Testing -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/api_fuzzing/configuration/variables.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/442699)

{{< /details >}}

GitLab 17.1は、ファズテスト用に次の設定変数を追加します:

1. `FUZZAPI_SUCCESS_STATUS_CODES`は、ファズテストジョブが合格したかどうかを定義するHTTP成功ステータスコードのカンマ区切りリストを作成します。
1. `FUZZAPI_TARGET_CHECK_SKIP`は、スキャンが開始される前にターゲットAPIが利用可能になるのを待つのを無効にします。
1. `FUZZAPI_TARGET_CHECK_STATUS_CODE`は、APIターゲットの可用性チェックの予期されるステータスコードを指定します。提供されていない場合、500以外の任意のステータスコードはスキャナーによって受け入れられます。

これらの新しい変数は、スキャンが実行されることを保証するためのより大きなカスタマイズと柔軟性を提供します。

### ユーザー定義変数をオーバーライドできるユーザーに対する制御の強化 {#enhanced-control-over-who-can-override-user-defined-variables}

<!-- categories: Secrets Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/variables/_index.md#restrict-pipeline-variables) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/440338)

{{< /details >}}

ユーザー定義変数をオーバーライドできるユーザーをより適切に制御するために、`ci_pipeline_variables_minimum_role`プロジェクト設定を導入しています。この新しい設定は、既存の[`restrict_user_defined_variables`](../../ci/variables/_index.md#restrict-pipeline-variables)設定よりも優れた柔軟性を提供します。これで、オーバーライド権限をどのユーザーにも制限しないか、または少なくともデベロッパー、メンテナー、またはオーナーロールを持つユーザーのみに制限することができます。

### GitLab Runner 17.1がリリースされました {#gitlab-runner-171-released}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36942)

{{< /details >}}

本日、GitLab Runner 17.1をリリースします！GitLab Runnerは、軽量で高度にスケールするエージェントであり、CI/CDジョブを実行し、結果をGitLabインスタンスに送り返します。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [GCP Compute Engine用GitLab Runner fleetingプラグイン](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29221)

#### バグ修正 {#bug-fixes}

- [Runnerヘルパーイメージにエントリポイントが不足](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37689)

すべての変更のリストは、GitLab Runnerの[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-1-stable/CHANGELOG.md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.1)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.1)
- [UI改善](https://papercuts.gitlab.com/?milestone=17.1)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
