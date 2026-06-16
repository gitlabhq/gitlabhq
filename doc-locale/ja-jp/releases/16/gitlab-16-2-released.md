---
stage: Release Notes
group: Monthly Release
date: 2023-07-22
title: "GitLab 16.2リリースノート"
description: "GitLab 16.2が、全く新しいリッチテキストエディタエクスペリエンスと共にリリースされました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2023年7月22日、GitLab 16.2は次の機能を備えてリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター {#this-months-notable-contributor}

Xing Xinは、[コンフリクト検出に隔離リポジトリを使用](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6008)する最近のマージリクエストで表彰されました。Karthik Nayak氏 (シニアGitLabバックエンドエンジニア) は次のように述べています: 「隔離リポジトリを使用することで、操作が途中で失敗した場合にGitリポジトリ内の古いオブジェクトが残るのを防ぐことができます。Xingは、隔離リポジトリを導入できるRPCを認識し、適切なポインターでフィードバックに応答し、コードベースに関する豊富な知識でいくつかの疑問について私たちを納得させることができました。」

Xingは2020年からGitLabおよびGitalyプロジェクトに貢献しています。ByteDance社のbytedancerであるXingは、Alibaba CloudとAntGroupでも時間を過ごし、コードとエンジニアの効率性に注力しています。Xingは、「GitLabコミュニティは、コード管理のベストプラクティスと、すべての親切なレビュアーからのコメントの両方で、私に大きなインスピレーションを与えてくれました。コミュニティと共に成長できることを願っています。」

Missy Daviesは、[GitLabヒーロー](https://contributors.gitlab.com/docs/previous-heroes)プログラムの最新メンバーの一人です。彼女はGitLabプロジェクト全体にわたる[多くの最近の貢献](https://gitlab.com/gitlab-org/gitlab/-/merge_requests?scope=all&state=merged&assignee_username=missy-davies) 、特に[パイプライン実行](https://handbook.gitlab.com/handbook/engineering/development/ops/verify/pipeline-execution/)および[環境](https://handbook.gitlab.com/handbook/engineering/development/ops/deploy/environments/)グループに対するいくつかのマージリクエストで表彰されました。

Missyは、GitLabコントリビューターコミュニティの積極的なメンバーでもあり、コミュニティイベント、オフィスアワー、Discordサーバーに定期的に参加しています。Lee Tickett氏とMarco Zille氏の両名（GitLabコミュニティコアチームのメンバー）が、Missy氏のより広範なコミュニティへの関与を強調しました。Lee氏は、Missy氏が「私たちの価値観を体現している」と付け加えました。

Missy氏は、GitLabにおけるオープンソースの世界への関与が深まるにつれて、大きな喜びを見出したと語りました。彼女は、強いコミュニティ意識、継続的な学習機会、そしてオープンソースの原則に対する共通の情熱を高く評価しています。Ruby on RailsおよびPythonでの実務経験を持つバックエンドデベロッパーとして、Missyは2022年以来、GitLabの重要なコントリビューターとなっています。

今回のリリースに貢献してくださったすべてのコミュニティコントリビューターに心から感謝いたします🙌

## 主要な機能 {#primary-features}

### 全く新しいリッチテキストエディタエクスペリエンス {#all-new-rich-text-editor-experience}

<!-- categories: Team Planning, Portfolio Management, Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/rich_text_editor.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10378)

{{< /details >}}

GitLab 16.2は、全く新しいリッチテキストエディタエクスペリエンスを搭載しています！この新しい機能は、既存のMarkdown編集エクスペリエンスの代替として、すべての方にご利用いただけます。

多くの人にとって、コメントや説明にプレーンテキストエディタを使用することは、コラボレーションの障壁となっています。画像の参照の構文を覚えたり、長いテーブルを扱ったりすることは、構文に比較的慣れている人にとっても面倒な場合があります。リッチテキストエディタは、「見たままのものを得る (what you see is what you get)」編集エクスペリエンスと、図、コンテンツ埋め込み、メディア管理などのためのカスタム編集インターフェースを構築できる拡張可能な基盤を提供することで、これらの障壁を打ち破ることを目指しています。

リッチテキストエディタは、すべてのイシュー、エピック、マージリクエストで利用可能になりました。近いうちにGitLabのより多くの場所で利用できるようにする予定です。進捗状況は[こちら](https://gitlab.com/groups/gitlab-org/-/epics/10378)で確認できます。

私たちはこの新しい編集エクスペリエンスを誇りに思っており、皆様のご意見を伺うのが待ちきれません。新しいリッチテキストエディタをお試しいただき、[このイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/416293)でご意見をお聞かせください。

### GitLabは、設定なしでFluxの同期をトリガーします {#gitlab-triggers-a-flux-synchronization-without-any-configuration}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/clusters/agent/gitops.md#immediate-git-repository-reconciliation) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/392852)

{{< /details >}}

デフォルトでは、Fluxは定期的にKubernetesのマニフェストを同期します。マニフェストが変更されたときにすぐに調整をトリガーするには、デフォルトで追加の設定が必要です。Kubernetes向けGitLabエージェントを使用すると、マニフェストに変更をプッシュし、Fluxの同期を自動的にトリガーできます。

### Cosignによるキーレス署名のサポート {#support-for-keyless-signing-with-cosign}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Silver、Gold
- リンク: [ドキュメント](../../ci/yaml/signing_examples.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/10254)

{{< /details >}}

署名キーの適切な保存、ローテーション、および管理は困難な場合があり、通常は個別のキー管理システム (KMS) の管理にかかるオーバーヘッドが必要です。GitLabは、Sigstore Cosignツールとのネイティブなインテグレーションを介したキーレス署名をサポートするようになり、GitLab CI/CDパイプライン内での簡単、便利、安全な署名が可能になりました。署名は非常に短期間の署名キーを使用して行われます。キーは、パイプラインを実行したユーザーのOIDC IDを使用してGitLabサーバーから取得したトークンを介して生成されます。このトークンには、そのトークンがCI/CDパイプラインによって生成されたことを証明する独自のクレームが含まれています。

ビルドアーティファクト、コンテナイメージ、およびパッケージのキーレス署名を開始するには、ユーザーは[ドキュメントに示す](../../ci/yaml/signing_examples.md)ように、CI/CDファイルに数行追加するだけで済みます。

### コマンドパレット {#command-palette}

<!-- categories: Navigation & Settings -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/search/command_palette.md)

{{< /details >}}

パワーユーザーの場合、キーボードでナビゲートしたりアクションを起こしたりするのはフラストレーションがたまることがあります。これで、新しいコマンドパレットを使用すると、キーボードを使ってより多くの作業をこなせるようになります。

コマンドパレットを有効にするには、左サイドバーを開き、**Search GitLab** (🔍) をクリックするか、/ キーを使用します。

次のいずれかの特殊文字を入力します:

- > - 新しいオブジェクトを作成するか、メニュー項目を見つけます
- @ - ユーザーを検索
- : - プロジェクトを検索
- / - デフォルトのリポジトリのブランチでプロジェクトファイルを検索

### Google AIを搭載したGitLab Duoコード提案の改善 {#gitlab-duo-code-suggestions-improvements-powered-by-google-ai}

<!-- categories: Code Suggestions -->

{{< details >}}

- プラン: Gold、Silver、Free
- リンク: [ドキュメント](../../user/project/repository/code_suggestions/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/9814)

{{< /details >}}

コード提案は、Google Cloudのカスタマイズ可能な基盤モデルとオープンソースの生成AIインフラストラクチャを使用し、Google Vertex AIにおける生成AIをサポートするようになりました。

GitLabのコード提案は、Google Vertex AI Codey APIの[データガバナンス](https://cloud.google.com/vertex-ai/docs/generative-ai/data-governance)と[責任あるAI](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/responsible-ai)を通じてルーティングされます。7月22日現在、コード提案は現在開いているファイルに対して推論を行い、コンテキストウィンドウは2,048トークン、文字数制限は8,192文字です。この制限には、カーソルの前後のコンテンツ、ファイル名、および拡張子の種類が含まれます。Google Vertex AI [`code-gecko`](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/models)の詳細については、こちらをご覧ください。

[Google Vertex AI Codey API](https://cloud.google.com/vertex-ai/docs/generative-ai/code/code-models-overview#supported_coding_languages)は以下を直接サポートしています: C++、C#、Go、Google SQL、Java、JavaScript、Kotlin、PHP、Python、Ruby、Rust、Scala、Swift、TypeScript。そしてインフラファイルについては、以下をサポートしています: Google Cloud CLI、Kubernetes Resource Model (KRM)、およびTerraform。

私たちはコード提案を改善するために継続的に反復しています。ぜひお試しいただき、[皆様のフィードバックをお寄せください](https://gitlab.com/gitlab-org/gitlab/-/issues/405152)。

### 機械学習モデル実験を追跡する {#track-your-machine-learning-model-experiments}

<!-- categories: MLOps -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/project/ml/experiment_tracking/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125758)

{{< /details >}}

データサイエンティストは機械学習 (ML) モデルを作成する際、モデルのパフォーマンスを向上させるために、さまざまなパラメータ、設定、特徴量エンジニアリングを実験することがよくあります。このデータサイエンティストは、このすべてのメタデータと関連するアーティファクトを追跡し、後で実験をレプリケートする必要があります。この作業は簡単ではなく、既存のソリューションでは複雑なセットアップが必要です。

機械学習モデル実験により、データサイエンティストはパラメータ、メトリクス、およびアーティファクトを直接GitLabにログ記録し、最もパフォーマンスの高いモデルに簡単にアクセスできます。この機能は実験です。

### バリューストリームダッシュボードの新しいカスタマイズレイヤー {#new-customization-layer-for-the-value-streams-dashboard}

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/analytics/value_streams_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/388890)

{{< /details >}}

私たちは、[バリューストリームダッシュボード](https://youtu.be/EA9Sbks27g4)に新しい設定ファイルを追加し、ダッシュボードのデータと外観のカスタマイズを容易にしました。このファイルでは、タイトル、説明、パネルやフィルターの数など、さまざまな設定とパラメータを定義できます。このファイルはスキーマ駆動型で、Gitのようなバージョン管理システムで管理されています。これにより、設定変更の履歴を追跡および維持し、必要に応じて以前のバージョンに戻し、チームメンバーと効果的に共同作業を行うことができます。

新しい設定には、ラベルでメトリクスをフィルターするオプションも含まれています。興味のある分野に基づいて[メトリクス比較パネル](https://about.gitlab.com/blog/getting-started-with-value-streams-dashboard/)を調整し、無関係な情報を除外し、分析または意思決定プロセスに最も関連するデータに焦点を当てることができます。

## 規模とデプロイ {#scale-and-deployments}

### グループレベルWikiがAdvanced Searchで利用可能になりました {#group-level-wiki-now-available-in-advanced-search}

<!-- categories: Global Search -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/search/advanced_search.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/336100)

{{< /details >}}

このリリースで、Advanced Searchは[グループレベルWiki](../../user/project/wiki/group.md)を含むように拡張されました。ユーザーはこれらのWiki内のコンテンツを、以前よりも簡単かつ迅速に見つけられるようになります。

### Omnibusの改善 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- Redisのバージョンは、最新の安定バージョンである[`7.0.12`](https://raw.githubusercontent.com/redis/redis/7.0/00-RELEASENOTES)に更新されました。
- GitLabを新規にインストールする場合、[PostgreSQL 14](https://www.postgresql.org/docs/14/release-14.html#id-1.11.6.12.4)の使用をオプトインできるようになりました。

### GitLabコミットで言及されているJiraイシューからのデプロイを表示 {#view-deployments-from-jira-issues-mentioned-in-gitlab-commits}

<!-- categories: Integrations -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../integration/jira/development_panel.md#information-displayed-in-the-development-panel) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/300031)

{{< /details >}}

以前は、GitLabのデプロイは、デプロイに関連するブランチまたはマージリクエストのいずれかでJiraイシューが言及されている場合にのみ、Jira開発パネルからリンクされていました。これは、マージリクエストからデプロイする必要があるため、ユーザーにとって不便なことが多く、一般的なワークフローではありませんでした。

このリリースにより、GitLabのデプロイは、最後の成功したデプロイ後にブランチに対して行われた最新の5,000コミットのメッセージ内でJiraイシューの言及もスキャンします。このGitLabのデプロイは、言及されたすべてのJiraイシューに関連付けられます。

### 未確認ユーザーの自動削除 {#automatic-deletion-of-unconfirmed-users}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../administration/moderate_users.md#automatically-delete-unconfirmed-users) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/352514)

{{< /details >}}

招待が誤ったメールアドレスに送信された場合、確認されることはありません。以前は、管理者がこれらのアカウントを手動で削除する必要がありました。現在、管理者は、指定された日数経過後に未確認ユーザーの自動削除を有効にできます。同様に、GitLab.comでは、未確認アカウントは[指定された日数](../../user/gitlab_com/_index.md)後に自動的に削除されます。

### フィードトークンのセキュリティが向上 {#improved-security-for-feed-tokens}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../security/tokens/_index.md#feed-token) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/414257)

{{< /details >}}

フィードトークンは、生成されたURLでのみ機能するようにすることで、セキュリティが強化されました。これにより、トークンが漏洩した場合に読み取ることができるフィードのスコープが狭まります。

### Self-Managed GitLabで利用可能なSlackアプリ用GitLab {#gitlab-for-slack-app-available-on-self-managed-gitlab}

<!-- categories: Integrations -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/settings/slack_app.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/358872)

{{< /details >}}

このリリースにより、Slackアプリ用GitLabはSelf-Managedインスタンスで利用できるようになりました。Self-Managed GitLabでは、[マニフェストファイル](https://api.slack.com/reference/manifests#creating_apps)からSlackアプリ用GitLabのコピーを作成し、そのコピーをSlackワークスペースにインストールできます。各コピーはプライベートであり、公開配布はできません。

アプリを作成および設定するには、[Slackアプリ管理用GitLab](../../administration/settings/slack_app.md)を参照してください。

### 複数のアクセストークンを使用してGitHubからのインポートを高速化 {#speed-up-imports-from-github-using-multiple-access-tokens}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/import.md#import-repository-from-github) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/337232)

{{< /details >}}

デフォルトでは、GitHubインポーターは、GitHubからGitLabへのプロジェクトのインポート時に単一のアクセストークンを使用します。ユーザーアカウントのアクセストークンは、通常1時間あたり5000リクエストにレート制限されます。これは、次の場合にインポーターの速度を大幅に低下させる可能性があります:

- 複数の小規模から中規模のプロジェクトをインポートする場合。
- 大量のデータを含む単一の大規模なプロジェクトをインポートする場合。

このリリースにより、アクセストークンのリストをGitHubインポーターAPIに渡し、レート制限されたときにAPIがそれらを順番に使用できるようになりました。複数のアクセストークンを使用する場合:

- これらのトークンは、すべてが1つのレート制限を共有するため、同じアカウントのものであることはできません。
- トークンは、インポートするリポジトリに対して同じユーザー権限と十分な特権を持っている必要があります。

### OIDCプロバイダーと監査担当者のロールを同期 {#sync-auditor-role-with-oidc-provider}

<!-- categories: User Management -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../administration/auth/oidc.md#auditor-groups) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/389321)

{{< /details >}}

GitLabでOIDCグループを`auditor`ロールに同期できるようになりました。これにより、OIDCによって促進される自動化されたユーザーライフサイクル管理は、以前はロールマッピングでサポートされていなかった`auditor`ロールを使用できるようになります。

[Marin Hannache](https://gitlab.com/mareo)氏のコントリビュートに感謝いたします！

### サインインおよびサインアップページの改善 {#improved-sign-in-and-sign-up-pages}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/settings/sign_up_restrictions.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/385651)

{{< /details >}}

GitLabのサインインおよびサインアップページが改善されました:

- カスタムテキストが存在する場合の2列レイアウト。
- 複数のLDAPでの`Remember me`チェックボックスに関するイシューを修正しました。
- ダークモードエクスペリエンスの改善。
- より大きなシングルサインオンボタン。
- ページ要素が隠れるのを避けるため、フッターをページ下部に移動しました。
- SAMLサインオンページに言語スイッチャーが追加されました。
- 登録トライアルページでパスワードチェックが有効になりました。

### バックアップにプロジェクトをスキップする機能が追加されました {#backup-adds-the-ability-to-skip-projects}

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/18287)

{{< /details >}}

組み込みのバックアップおよび復元ツールに、特定のリポジトリをスキップする機能が追加されました。Rakeタスクは、新しい`SKIP_REPOSITORIES_PATHS`環境変数を使用することで、バックアップまたは復元中にスキップされるカンマ区切りのグループまたはプロジェクトパスのリストを受け入れるようになりました。これにより、例えば、時間の経過とともに変更されない古いプロジェクトやアーカイブされたプロジェクトをスキップできるようになり、a) バックアップ実行の高速化による時間短縮、およびb) バックアップファイルにこのデータを含めないことによるスペース節約を実現できます。[Yuri Konotopov](https://gitlab.com/nE0sIghT)氏の[コミュニティコントリビュート](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/merge_requests/196)に感謝します！

### Geoがすべてのコンポーネントで個別の再同期と再検証を追加 {#geo-add-individual-resync-and-reverification-for-all-components}

<!-- categories: Geo-replication, Disaster Recovery -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../administration/geo/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/364727)

{{< /details >}}

Geoは、[セルフサービスフレームワーク](../../development/geo/framework.md)によって管理されるすべてのコンポーネントタイプに対して、個々のアイテムを再同期および再検証する機能を追加します。これで、Geoによって管理される個々のアイテムに対して、UIを使用して再同期または再検証操作を強制できます。これは、失敗したアイテムの再同期または再検証操作を迅速化したり、同期または検証エラーを修正するために変更が適用された後にも役立ちます。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### Git LFSダウンロードパフォーマンスの向上 {#improve-git-lfs-download-performance}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../topics/git/lfs/_index.md)

{{< /details >}}

[プロキシダウンロードが有効になっていない](../../administration/object_storage.md#proxy-download)オブジェクトストレージにLFSオブジェクトを保存するインスタンスの場合、GitLabはLFSリクエストを一括で処理するようになりました。これにより、多数のLFSオブジェクトのダウンロードパフォーマンスが大幅に向上します。

以前は、LFSオブジェクトがフェッチされる方法により、GitLabは多くの非常に小さなリクエストを作成し、ユーザー権限をチェックし、外部に保存されているオブジェクトにリダイレクトしていました。これは、かなりの負荷とパフォーマンスの低下を引き起こす可能性がありました。この修正により、プライマリGitLabインスタンスへの負荷を軽減し、ユーザーにより高速なダウンロードエクスペリエンスを提供できるようになりました。

### Helmチャートの追加ボリュームを使用してKubernetes用エージェントをインストールする {#install-the-agent-for-kubernetes-using-extra-volumes-in-the-helm-chart}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/clusters/agent/install/_index.md#customize-the-helm-installation) | [関連イシュー](https://gitlab.com/gitlab-org/charts/gitlab-agent/-/issues/33)

{{< /details >}}

Kubernetes用エージェントの`agentk`コンポーネントは、GitLabで認証するためにトークンを必要とします。以前は、トークンをそのまま提供するか、またはトークンを含むKubernetesシークレットへの参照として提供することができました。ただし、シークレットがすでにボリュームで利用可能な環境で運用している場合、別のシークレットを作成する代わりにそのボリュームをマウントすることを好むかもしれません。GitLab 16.2以降、GitLabエージェントHelmチャートには、[Thomas Spear](https://gitlab.com/tspearconquest)氏のコミュニティコントリビュートのおかげで、この追加機能が搭載されています。

### スキャン実行ポリシーエディタでのカスタムCI変数のサポート {#support-for-custom-ci-variables-in-the-scan-execution-policies-editor}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/scan_execution_policies.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9566)

{{< /details >}}

これで、スキャン実行ポリシーエディタで、値を含むカスタムCI変数を定義できます。ポリシーで定義されたCI変数は、ポリシーによって適用されるプロジェクトで定義された一致する変数をオーバーライドします。たとえば、ポリシーはCI変数`SAST_EXCLUDED_ANALYZERS`を`brakeman`に定義できます。プロジェクトでスキャナーが適用されると、プロジェクトのCI設定で定義されている変数に関係なく、スキャナーは`brakeman`に設定された変数で実行されます。各スキャンタイプについて、デフォルトの変数の値を定義したり、カスタムCI変数のカスタムキー/バリューペアを作成したりできます。これにより、スキャン実行ポリシーのカスタマイズがより迅速かつ容易になります。

### スキャン実行ポリシーが開発プロジェクトでCI/CDパイプラインを有効にすることを許可する {#allow-scan-execution-policies-to-enable-cicd-pipelines-in-development-projects}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/scan_execution_policies.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/6880)

{{< /details >}}

以前のGitLabバージョンでは、`.gitlab-ci.yml`ファイルのないプロジェクト、またはAutoDevOpsが無効になっているプロジェクトではセキュリティポリシーは適用されませんでした。GitLab 16.2では、セキュリティポリシーは`.gitlab-ci.yml`ファイルを含まないプロジェクトでCI/CDパイプラインを暗黙的に有効にします。これは、セキュリティポリシーのコンプライアンスを確保し、シークレット検出、静的な解析、またはビルドが不要なその他のジョブを適用できるようにするためのさらなる一歩です。

### セキュリティポリシーで「デフォルト」または「保護ブランチ」をターゲットにする {#target-default-or-protected-branches-in-security-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#scan_finding-rule-type) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9468)

{{< /details >}}

スキャン実行ポリシーとスキャン結果ポリシーにより、ポリシーが適用される多数のプロジェクト全体で、「デフォルト」ブランチまたは「保護ブランチ」であるブランチに適用範囲をスコープできるようになります。ポリシーがブランチ名を明示的に指定することを要求するのではなく、ポリシーをより広範に適用し、非典型的な名前のブランチがコンプライアンスから除外されないようにすることができます。

ブランチルールは、`branch_type`フィールドを使用することで、さまざまなセキュリティポリシールールタイプ全体で設定できます:

- [スキャン結果ポリシーのScan_findingルールタイプ](../../user/application_security/policies/merge_request_approval_policies.md#scan_finding-rule-type)
- [スキャン結果ポリシーのLicense_findingルールタイプ](../../user/application_security/policies/merge_request_approval_policies.md#license_finding-rule-type)
- [スキャン実行ポリシーのパイプラインルールタイプ](../../user/application_security/policies/scan_execution_policies.md#pipeline-rule-type)
- [スキャン実行ポリシーのスケジュールルールタイプ](../../user/application_security/policies/scan_execution_policies.md#schedule-rule-type)

### Google Cloud Loggingへの監査イベントストリーミング {#audit-event-streaming-to-google-cloud-logging}

<!-- categories: Audit Events -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

これで、監査イベントストリーミングの送信先としてGoogle Cloud Loggingを選択できるようになりました。

以前は、ヘッダーを使用して、Google Cloud Loggingが受け入れるリクエストを作成する必要がありました。このメソッドはエラーが発生しやすく、トラブルシューティングを行うのが困難でした。

これで、ストリームの宛先としてGoogle Cloud Loggingを選択し、プロジェクトID、クライアントメール、ログID、および秘密キーを提供することで、よりシームレスなインテグレーションが可能になります。

### コンプライアンスフレームワークレポートのエクスポート {#compliance-frameworks-report-export}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_projects_report.md#export-a-report-of-compliance-frameworks-on-projects-in-a-group)

{{< /details >}}

これで、コンプライアンスフレームワークとその関連プロジェクトのレポートをCSVファイルにエクスポートすることができます。

グループレベルでのコンプライアンスフレームワークレポートの追加により、コンプライアンスフレームワークがどのプロジェクトに適用されるかを確認および管理できるようになりました。

新しいエクスポートにより、そのファイルのコピーを参照用に保持できます。プロジェクトとコンプライアンスフレームワークの関係の理想的な状態の信頼できる唯一の情報源としてファイルを保持することもできます。あるいは、GitLabで作業していないが、どのプロジェクトにどのフレームワークがタグ付けされているかを見ることに興味がある組織内の人々にファイルを送信することもできます。

### グループ/サブグループレベル依存関係リスト {#groupsub-group-level-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/application_security/dependency_list/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/8090)

{{< /details >}}

依存関係のリストをレビューする際には、全体像を把握することが重要です。プロジェクトレベルで依存関係を管理することは、すべてのプロジェクトの依存関係を監査したい大規模な組織にとって問題です。このリリースにより、サブグループを含むプロジェクトまたはグループレベルで、すべての依存関係を確認できます。この機能は、機能フラグ`group_level_dependencies`によってデフォルトで無効になっています。

### 保護ブランチへの最初のプッシュを許可する {#allow-initial-push-to-protected-branches}

<!-- categories: Compliance Management, Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/repository/branches/default.md#protect-initial-default-branches)

{{< /details >}}

以前のGitLabバージョンでは、デフォルトブランチが完全に保護されている場合、プロジェクトメンテナーおよびオーナーのみが、デフォルトブランチに最初のコミットをプッシュすることができました。

これは、新しいプロジェクトを作成したデベロッパーにとって問題を引き起こしました。なぜなら、デフォルトブランチしか存在しなかったため、そこに最初のコミットをプッシュすることができなかったからです。

**最初のプッシュ後に完全に保護**設定により、デベロッパーはリポジトリのデフォルトブランチに最初のコミットをプッシュすることができますが、それ以降はデフォルトブランチにコミットをプッシュすることはできません。完全に保護されたブランチと同様に、プロジェクトメンテナーは常にデフォルトブランチにプッシュすることができますが、誰も強制プッシュすることはできません。

### インスタンスレベルの監査イベントストリーミング {#instance-level-streaming-audit-events}

<!-- categories: Audit Events -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

GitLab 16.1より前は、トップレベルグループからの監査イベントのみを外部のストリーミング先にストリームできました。

現在、インスタンス管理者は、インスタンスレベルで生成された監査イベントのストリーミング先を追加できます。

### 監査イベントのストリーミングフィルタリングUI {#streaming-audit-event-filtering-ui}

<!-- categories: Audit Events -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

以前のGitLabバージョンでは、GraphQL APIを使用して、監査イベントタイプのフィルターを監査イベントストリームに追加する必要がありました。

現在、GitLab UIのフィルタードロップダウンを使用して、利用可能なすべての監査イベントタイプを、それらが関連するGitLabの領域ごとにグループ化して表示し、ストリームで送信したい正確なタイプを検索できます。

これにより、監査イベントストリームにフィルタリングを追加するのに必要な時間が大幅に短縮されます。なぜなら、APIを使用してリスト全体を取得し、手動でリストを検索する必要がなくなるからです。

### マージリクエストでのインタラクティブな差分の提案 {#interactive-diff-suggestions-in-merge-requests}

<!-- categories: Team Planning, Portfolio Management, Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/project/merge_requests/reviews/suggestions.md#using-the-rich-text-editor) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/406726)

{{< /details >}}

マージリクエストで変更を提案する際に、提案をより迅速に編集できるようになりました。コメント内で、リッチテキストエディタに切り替えてUIを使用し、テキスト行を上下に移動します。この変更により、コメントが投稿されたときに表示されるのと全く同じように、提案を表示できます。

リッチテキストエディタは、GitLabでの新しい編集方法です。マージリクエストで利用できるほか、イシューやエピックのプレーンテキストエディタと並行して利用することもできます。

私たちは、リッチテキストエディタを近いうちにGitLabのより多くの領域で利用できるようにする予定であり、現在積極的に取り組んでいます。進捗状況は[こちら](https://gitlab.com/groups/gitlab-org/-/epics/10378)で確認できます。

### CI/CDパイプラインでPyPIパッケージをインポートする {#import-pypi-packages-with-cicd-pipelines}

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/packages/package_registry/_index.md#to-import-packages) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/389339)

{{< /details >}}

あなたのPyPIリポジトリをGitLabに移行することを考えていましたが、時間を投資できませんでしたか？このリリースで、GitLabはPyPIパッケージインポーターの最初のバージョンをローンチします。

これで、パッケージインポーターツールを使用して、ArtifactoryなどのPyPI準拠のレジストリからパッケージをインポートすることができます。

### アップロードされたデザインのコメントに絵文字リアクションを追加する {#add-emoji-reactions-to-comments-on-uploaded-designs}

<!-- categories: Design Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/emoji_reactions.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/29756)

{{< /details >}}

これで、[デザイン管理](../../user/project/issues/design_management.md)のコメントに絵文字リアクションを追加することで、より創造的に考えを表現できます。この機能は、コラボレーションに楽しさと容易さを加え、より良いコミュニケーションを促進し、チームがより表現豊かな方法で迅速なフィードバックを提供できるようにします。

### SASTアナライザーの更新 {#sast-analyzer-updates}

<!-- categories: SAST -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/application_security/sast/analyzers.md) | [関連イシュー](../../user/application_security/_index.md)

{{< /details >}}

GitLab SASTには、GitLab静的な解析チームが積極的に保守、更新、サポートする[多くのセキュリティアナライザー](../../user/application_security/sast/_index.md#supported-languages-and-frameworks)が含まれています。

16.2リリースマイルストーン中、私たちの変更は、Semgrepベースのアナライザーと、それがスキャンに使用するGitLabが維持するルールに焦点を当てました。以下の変更をリリースしました:

- JavaScriptルールの説明とガイダンスを明確にし、[GitLab 16.1でリリースされた他の言語の改善点](https://about.gitlab.com/releases/2023/06/22/gitlab-16-1-released/#clearer-guidance-and-better-coverage-for-sast-rules)に基づいています。
- JavaおよびJavaScriptで追加の脆弱性を見つけるためにルールを更新しました。
- スキャンで無視されるファイルのデフォルト設定を次の方法で変更しました:
  - `.gitignore`除外の削除。[`@SimonGurney`](https://gitlab.com/SimonGurney)によるこのコミュニティコントリビュートに感謝します。
  - ローカルで定義された`.semgrepignore`ファイルを尊重する。[`@hmrc.colinameigh`](https://gitlab.com/hmrc.colinameigh)によるこのコミュニティコントリビュートに感謝します。
- Goメモリエイリアシングに関連するルールを改善しました。[`@tyage`](https://gitlab.com/tyage)によるこのコミュニティコントリビュートに感謝します。
- JavaScriptルールに対するSemgrepルールIDに追加された`-1`サフィックスを削除しました。これはGitLab 16.0で無関係な変更の副作用として追加されましたが、顧客の既存の`semgrepignore`コメントと競合していました。

詳細は[`semgrep`変更履歴](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md#v440)および[`sast-rules`変更履歴](https://gitlab.com/gitlab-org/security-products/sast-rules/-/blame/main/CHANGELOG.md)を参照してください。GitLab管理のルールセットへのさらなる改善は、[エピック10907](https://gitlab.com/groups/gitlab-org/-/epics/10907)で追跡しています。

[GitLab管理のSASTテンプレート](../../user/application_security/sast/_index.md) （[`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)）を含め、GitLab 16.0以降を実行している場合、これらの更新を自動的に受け取ります。特定のアナライザーのバージョンを維持し、自動更新を防ぐには、[そのバージョンを固定](../../user/application_security/sast/_index.md)できます。

以前の変更については、[先月の更新](https://about.gitlab.com/releases/2023/06/22/gitlab-16-1-released/#sast-analyzer-updates)を参照してください。

### シークレット検出の更新 {#secret-detection-updates}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/application_security/secret_detection/_index.md) | [関連イシュー](../../user/application_security/_index.md)

{{< /details >}}

私たちはGitLabシークレット検出アナライザーの更新を定期的にリリースしています。GitLab 16.2マイルストーン中に、私たちは次のことを行いました:

- 以下のGitLab管理の検出ルールを[追加](../../user/application_security/secret_detection/_index.md)しました:
  - OpenAI APIキー。
  - CircleCI PersonalおよびProjectアクセストークン。[`@nathanwfish`](https://gitlab.com/nathanwfish)によるこのコミュニティコントリビュートに感謝します。
- `keywords`最適化を使用するルールのパフォーマンスを向上させました。
- シークレット検出の結果がリポジトリ内の間違った場所にpermalinkを作成する[問題](https://gitlab.com/gitlab-org/gitlab/-/issues/358073)を修正しました。

詳細については、[変更履歴](https://gitlab.com/gitlab-org/security-products/analyzers/secrets/-/blob/master/CHANGELOG.md#v514)を参照してください。

[GitLab管理のシークレット検出テンプレート](../../user/application_security/secret_detection/_index.md) （[`Secret-Detection.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Jobs/Secret-Detection.gitlab-ci.yml)）を使用し、GitLab 16.0以降を実行している場合、これらの更新を自動的に受け取ります。特定のアナライザーのバージョンを維持し、自動更新を防ぐには、[そのバージョンを固定](../../user/application_security/secret_detection/_index.md)できます。

以前の変更については、[最新のシークレット検出の更新](https://about.gitlab.com/releases/2023/05/22/gitlab-16-0-released/#secret-detection-updates)を参照してください。

### 依存関係およびライセンススキャンにおけるNuGet v2のサポート {#support-for-nuget-v2-in-dependency-and-license-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/398680)

{{< /details >}}

NuGet `v1`ロックファイルに加えて、GitLab依存関係およびライセンススキャンの両方で、NuGet `v2`ロックファイルで定義された依存関係の分析がサポートされるようになりました。

### SASTの脆弱性追跡機能の改善 {#improved-sast-vulnerability-tracking}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/5144)

{{< /details >}}

GitLab SAST [高度な脆弱性追跡](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking)は、コードが移動しても発見を追跡し続けることで、トリアージをより効率的にします。GitLab 16.2で2つの改善をリリースしました:

1. 言語サポートの拡大: 高度な脆弱性追跡がC#で有効になりました。
1. より良い追跡: C、C#、Go、Java、JavaScript、およびPythonにおいて、空白やコメントをより適切に処理できるよう追跡アルゴリズムを改善しました。特定のGo関数の追跡に関するイシューも修正しました。

さらなる追跡の改善には、より多くの言語への拡張、より多くの言語構造のより良い処理、およびPythonとRubyの追跡の改善が含まれており、これらは[エピック5144](https://gitlab.com/groups/gitlab-org/-/epics/5144)で追跡しています。

これらの変更は、GitLab SAST [アナライザー](../../user/application_security/sast/analyzers.md)の[更新されたバージョン](https://docs.gitlab.com/#sast-analyzer-updates)に含まれています。プロジェクトの脆弱性発見は、更新されたアナライザーでプロジェクトがスキャンされた後、新しい追跡シグネチャで更新されます。[SASTアナライザーを特定のバージョンにピン留め](../../user/application_security/sast/_index.md)していない限り、この更新を受け取るためにアクションを実行する必要はありません。

### CI/CD: 条件付きインクルードでの`when: never`のサポート {#cicd-support-for-when-never-on-conditional-includes}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/yaml/includes.md#include-with-rulesif) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/348146)

{{< /details >}}

[`include`](../../ci/yaml/_index.md#include)は、完全なCI/CDパイプラインを作成する際に使用する最も一般的なキーワードの1つです。より大規模なパイプラインを構築している場合、外部のYAML設定をパイプラインに取り込むために`include`キーワードを使用していることでしょう。

このリリースでは、キーワードの機能を拡張し、[`rules`と`include`](../../ci/yaml/includes.md#use-rules-with-include)を使用する際に`when: never`を使用できるようにします。これで、特定のルールが満たされたときに外部のCI/CD設定が除外されるタイミングを決定できます。これにより、選択した条件に基づいて動的に自身を修正する能力が向上した、標準化されたパイプラインを作成するのに役立ちます。

### すべてのティアで利用可能なLinux上のMedium SaaS Runner {#medium-saas-runners-on-linux-available-to-all-tiers}

<!-- categories: GitLab Runner SaaS -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/hosted_runners/linux.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/418124)

{{< /details >}}

当社は現在、4 vCPUと16 GBのRAMを搭載したLinux上のMedium [GitLab SaaS Runner](../../ci/runners/hosted_runners/linux.md)をすべてのティアで利用できるようにしました。

以前は、Freeティアのユーザーは小規模なLinux Runnerしか使用できず、CI/CD実行時間が長くなることがありました。Freeユーザーがパイプラインの速度を向上させることを楽しみにしています。

### GitLab Runner 16.2 {#gitlab-runner-162}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 16.2もリリースします！GitLab Runnerは、CI/CDジョブを実行し、結果をGitLabインスタンスに送信する、軽量で拡張性の高いエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [Runner Kubernetes executor内のすべてのK8s APIコールを再試行する](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/4143)

#### バグ修正 {#bug-fixes}

- [dockerdまたは任意のプロセスがバックグラウンドで実行されている場合、CIジョブスクリプトが完了しない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2880)
- [v16.1.0用のGitLab-runner-helper servercoreイメージが見つからない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/33918)
- [エラー: キャッシュアダプターを作成できませんでした](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3802)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-2-stable/CHANGELOG.md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.2)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.2)
- [UI改善](https://papercuts.gitlab.com/?milestone=16.2)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
