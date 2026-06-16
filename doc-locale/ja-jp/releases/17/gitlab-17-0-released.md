---
stage: Release Notes
group: Monthly Release
date: 2024-05-16
title: "GitLab 17.0リリースノート"
description: "GitLab 17.0では、コンポーネントと入力を備えたCI/CDカタログが一般提供されるようになり、リリースされました。"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024年5月16日、GitLab 17.0は以下の機能とともにリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター {#this-months-notable-contributor}

誰もがGitLabコミュニティのコントリビューターを[推薦](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)できます！積極的に活動している候補者を支持するか、新しい候補者を推薦してください 🙌

Niklas van Schrickは3つのMVPを獲得しハットトリックを達成しました。GitLab 14.3以降、マイルストーンごとに少なくとも1つのMRを出すなど、GitLabで最も一貫したコントリビューターの1人となっています。

NiklasはGitLabのプロダクトマネージャーである[Magdalena Frankiewicz](https://gitlab.com/m_frankiewicz)によって、カスタムWebhookペイロードテンプレートを作成する機能をコントリビュートするとともに、[カスタムWebhookヘッダーを指定する機能](https://gitlab.com/gitlab-org/gitlab/-/issues/17290)も追加したことで推薦されました。「これは、65の同意を得た7年前からの高い要望のリクエストを解決しました」とMagdalenaは述べています。「ユーザーは完全にカスタムWebhookを設計できるようになりました！」

Niklasは[GitLab Core Team](https://about.gitlab.com/community/core-team/)のメンバーであり、より広範なコミュニティとGitLabが「誰もがコントリビュートすることを可能にする」というミッションを果たすのを支援しています。

「これまでの道のりで、私は多くの異なるレビュアー、メンテナー、デザイナー、テクニカルライター、プロダクトマネージャーなどと交流してきました」とNiklasは述べています。「誰もが協力的で、イシューとMRの進展のために最善を尽くしてくれました。」

Gerardo Navarroは1年以上にわたりGitLabにコントリビュートしており、2度目のGitLab MVP賞を獲得しました。

Gerardoは、パッケージレジストリリストに[保護されたパッケージを表示する](https://gitlab.com/gitlab-org/gitlab/-/issues/437926)機能への継続的なコントリビュートで推薦されました。この機能は、パッケージレジストリからのパッケージの作成、更新、削除に対するきめ細かな権限を有効にすることでセキュリティを向上させることを目的とした、[保護されたパッケージエピック](https://gitlab.com/groups/gitlab-org/-/epics/5574)に関連する一連のコントリビュートの一部です。

Gerardo Navarroとシーメンスのチームの皆様、GitLabの共同開発にご協力いただき、誠にありがとうございます。

「このような素晴らしい賞で私たちの仕事を評価していただき、誠にありがとうございます」とGerardoは述べています。「光栄に思います。すべてのコントリビュートから、まだ多くのことを学んでいます。」

## 主要な機能 {#primary-features}

### コンポーネントと入力を備えたCI/CDカタログが一般提供開始 {#cicd-catalog-with-components-and-inputs-now-generally-available}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/components/_index.md#cicd-catalog)

{{< /details >}}

このCI/CDカタログが一般提供されるようになりました。このリリースの一環として、[CI/CDコンポーネント](../../ci/components/_index.md)と[入力](../../ci/yaml/_index.md#inputs)も一般提供を開始します。

With the CI/CD Catalog, you gain access to a vast array of components created by the community and industry experts.継続的インテグレーション、デプロイパイプライン、または自動化タスクのソリューションを探している場合でも、要件に合わせて調整された多様なコンポーネントの選択肢が見つかります。カタログとその機能については、次の[ブログ記事](https://about.gitlab.com/blog/ci-cd-catalog-goes-ga-no-more-building-pipelines-from-scratch/)で詳しく読むことができます。

カタログにCI/CDコンポーネントをコントリビュートすることで、GitLab.comのこの新しく成長する部分を拡大するのを支援してください！

### バリューストリームダッシュボードでのAIインパクト分析 {#ai-impact-analytics-in-the-value-streams-dashboard}

<!-- categories: Value Stream Management, Code Suggestions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/analytics/duo_and_sdlc_trends.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/12978)

{{< /details >}}

AIインパクトは、バリューストリームダッシュボードで利用できるダッシュボードで、組織が[GitLab Duoが生産性に与える影響](https://about.gitlab.com/blog/measuring-ai-effectiveness-beyond-developer-productivity-metrics/)を理解するのに役立ちます。この新しい月次メトリクスビューは、AIの使用トレンドをリードタイム、サイクルタイム、DORA、脆弱性などのSDLCメトリクスと比較します。ソフトウェアリーダーは、AIインパクト分析ダッシュボードを使用して、エンドツーエンドのワークストリームでどれくらいの時間が節約されているかを測定し、デベロッパーの活動ではなくビジネス成果に焦点を合わせることができます。

この最初のリリースでは、AIの使用状況は、月次の[コード提案](../../user/project/repository/code_suggestions/_index.md)使用率として測定され、月間ユニークなCode Suggestionsユーザー数を月間ユニークな[コントリビューター](../../user/group/contribution_analytics/_index.md)の合計数で割って算出されます。

AIインパクト分析ダッシュボードは、期間限定でUltimateプランのユーザーが利用できます。その後、GitLab Duo Enterpriseライセンスがダッシュボードの使用に必要になります。

### Linux ARM上でのホスト型Runnerの導入 {#introducing-hosted-runners-on-linux-arm}

<!-- categories: GitLab Hosted Runners -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/hosted_runners/linux.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/365300)

{{< /details >}}

GitLab.com向けにLinux ARM上でホスト型Runnerを導入できることを大変嬉しく思います。現在利用可能な`medium`および`large`ARMマシンタイプは、それぞれ4および8vCPUを搭載し、GitLab CI/CDと完全に統合されており、これまで以上に迅速かつ費用対効果の高いアプリケーションのビルドとテストを可能にします。

私たちは業界最速のCI/CDビルド速度を提供することを決意しており、チームがさらに短いフィードバックサイクルを達成し、最終的にソフトウェアをより速く提供するのを楽しみにしています。

### デプロイ詳細ページの導入 {#introducing-deployment-detail-pages}

<!-- categories: Release Orchestration, Environment Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/deployment_approvals.md#approve-or-reject-a-deployment) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/374538)

{{< /details >}}

GitLabでデプロイに直接リンクできるようになりました。以前は、デプロイで共同作業する場合、デプロイリストからデプロイを検索する必要がありました。リストに表示されるデプロイの数が多いため、正しいデプロイを見つけるのは難しく、エラーが発生しやすかったです。

17.0から、GitLabは直接リンクできるデプロイ詳細ビューを提供します。この最初のバージョンでは、デプロイ詳細ページではデプロイメントジョブの概要が提供され、継続的デリバリー設定におけるデプロイの承認、拒否、またはコメントの可能性が提供されます。関連するパイプラインジョブからのリンクを含め、デプロイ詳細ページを強化するためのさらなる方法を検討しています。[イシュー450700](https://gitlab.com/gitlab-org/gitlab/-/issues/450700)で皆様のフィードバックをお聞かせください。

### GitLab Duo ChatがAnthropic Claude 3 Sonnetを使用するように {#gitlab-duo-chat-now-uses-anthropic-claude-3-sonnet}

<!-- categories: Duo Chat -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/gitlab_duo_chat/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13297)

{{< /details >}}

GitLab Duo Chatが大幅に改善されました。これにより、ほとんどの質問に答えるためのベースモデルとしてAnthropic Claude 3 Sonnetを使用するようになり、Claude 2.1を置き換えました。

GitLabでは、一連のタスクに最適なモデルを選択し、高性能なプロンプトを作成する際に、テスト駆動型アプローチを適用しています。チャットプロンプトに対する最近の調整により、Claude 3 Sonnetに基づいたチャット回答の正確性、網羅性、可読性が、以前のClaude 2.1に基づいたチャットバージョンと比較して大幅に向上しました。そのため、この新しいモデルバージョンに切り替えました。

### Self-ManagedデプロイでサポートされるGitLab Duo Chatでのハウツー質問 {#how-to-questions-in-gitlab-duo-chat-supported-on-self-managed-deployments}

<!-- categories: Duo Chat -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/gitlab_duo_chat/examples.md#ask-about-gitlab) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/451215)

{{< /details >}}

GitLab Duo Chatの人気の機能は、GitLabの使用方法に関する質問に答えることです。チャットは他の様々な機能を提供しますが、この特定の機能は以前はGitLab.comでのみ利用可能でした。このリリースにより、すべてのデプロイタイプで快適なユーザーエクスペリエンスを提供するという当社のコミットメントに沿って、Self-Managedインスタンスのデプロイでも利用できるようになります。

初心者でも専門家でも、「GitLabでパスワードを変更するにはどうすればよいですか？」や「KubernetesクラスターをGitLabに接続するにはどうすればよいですか？」といったクエリについてChatにヘルプを求めることができます。チャットは、お客様の問題をより効率的に解決するための役立つ情報を提供することを目指しています。

### バリューストリームダッシュボードの新しい使用状況概要パネル {#new-usage-overview-panel-in-the-value-streams-dashboard}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/analytics/value_streams_dashboard.md#overview) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/438256)

{{< /details >}}

バリューストリームダッシュボードに概要パネルを追加し、強化しました。この新しいビジュアライゼーションは、ソフトウエアデリバリーパフォーマンスに関する経営層レベルのインサイトの必要性に対応し、ソフトウェア開発ライフサイクル (SDLC) のコンテキストにおけるGitLabの使用状況を明確に示します。

概要パネルは、グループレベルのメトリクスを表示します。これには、(サブ)グループの数、プロジェクト、ユーザー、イシュー、MR、パイプラインが含まれます。

### グループをCI/CDジョブトークン許可リストに追加 {#add-a-group-to-the-cicd-job-token-allowlist}

<!-- categories: Secrets Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/jobs/ci_job_token.md#control-job-token-access-to-your-project) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/415519)

{{< /details >}}

GitLab 15.9で導入されたCI/CDジョブトークン許可リストは、他のプロジェクトからの不正なアクセスからプロジェクトを保護します。以前は、プロジェクトレベルでのアクセスは、他の特定のプロジェクトからのみ許可でき、最大200プロジェクトに制限されていました。

GitLab 17.0では、プロジェクトのCI/CDジョブトークン許可リストにグループを追加できるようになりました。最大200の制限は、プロジェクトとグループの両方に適用されるようになり、プロジェクトの許可リストには、最大200のプロジェクトとグループがアクセスを許可できるようになりました。この改善により、グループに関連付けられた多数のプロジェクトをより簡単に追加できるようになります。

### `rules:exists`CI/CDキーワードによるコンテキスト制御の強化 {#enhanced-context-control-with-the-rulesexists-cicd-keyword}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/yaml/_index.md#rulesexistsproject) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/386040)

{{< /details >}}

`rules:exists`CI/CDキーワードは、定義されている場所に応じて動作が異なり、より複雑なパイプラインで使用するのが難しくなる可能性があります。ジョブ内で定義されている場合、`rules:exists`はパイプラインを実行しているプロジェクト内の指定されたファイルを検索します。しかし、`include`セクションで定義されている場合、`rules:exists`は`include`セクションを含む設定ファイルをホストしているプロジェクト内の指定されたファイルを検索します。設定が複数のファイルとプロジェクトに分割されている場合、どのプロジェクトが定義されたファイルを検索するのかを正確に把握するのは難しい場合があります。

このリリースでは、`rules:exists`に`project`と`ref`サブキーを導入し、このキーワードの検索コンテキストを明示的に制御する方法を提供します。これらの新しいサブキーは、検索コンテキストを正確に指定することで、不整合を軽減し、パイプラインルール定義の明確性を高めるのに役立ちます。

### スイッチボードを使用して行われた設定変更の変更履歴 {#change-log-for-configuration-changes-made-using-switchboard}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/dedicated/configure_instance/_index.md#view-the-configuration-change-log) | [関連イシュー](https://about.gitlab.com/dedicated/)

{{< /details >}}

スイッチボードの[設定ページ](../../administration/dedicated/configure_instance/_index.md#configure-your-instance-using-switchboard)を使用して、GitLab Dedicatedインスタンスインフラストラクチャに対して行われた設定変更のステータスを表示できるようになりました。

スイッチボードでテナントを表示または編集するアクセス権を持つすべてのユーザーは、設定変更履歴の変更を表示し、インスタンスに適用される進捗状況を追跡できるようになります。

現在、スイッチボード設定ページと変更履歴は、[許可リストにIPを追加](../../administration/dedicated/configure_instance/network_security.md#ip-allowlist)してインスタンスへのアクセスを管理したり、インスタンスの[SAML設定](../../administration/dedicated/configure_instance/authentication/saml.md)を構成したりする変更に利用できます。

この機能は、[今後の四半期](https://about.gitlab.com/releases/whats-new/#whats-coming)に、追加の設定に対するセルフサービス更新を可能にするために拡張されます。

## 規模とデプロイ {#scale-and-deployments}

### GitLabチャートの改善 {#gitlab-chart-improvements}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/charts/)

{{< /details >}}

[GitLab Operator](https://docs.gitlab.com/operator/)は、クラウドネイティブのハイブリッドインストール向けに本番環境での使用が可能になりました。GitLab Operatorを採用する前に、[インストールドキュメント](https://docs.gitlab.com/operator/installation.html)を参照してください。

カスタムBusyBox値(`global.busybox`)を指定した場合のBusyBoxイメージへのフォールバックのサポートは削除されました。BusyBoxベースのinitコンテナのサポートは、共通のGitLabベースのinitイメージに置き換わり、GitLab 16.2（Helmチャート7.2）で非推奨になりました。

`gitlab.kas.privateApi.tls.enabled`と`gitlab.kas.privateApi.tls.secretName`のサポートも削除されました。代わりに`global.kas.tls.enabled`と`global.kas.tls.secretName`を使用する必要があります。

非推奨のキューセレクターと否定オプションはSidekiqチャートから削除されました。

### Linuxパッケージの改善 {#linux-package-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/)

{{< /details >}}

CentOS Linux 7は2024年6月30日に[エンドオブライフ](https://www.redhat.com/en/topics/linux/centos-linux-eol)を迎えます。これにより、GitLab 17.6はCentOS 7向けパッケージを提供できる最後のGitLabバージョンとなります。

### 2データベースモードがベータ版で利用可能 {#two-database-mode-is-available-in-beta}

<!-- categories: Cell -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/postgresql/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/432391)

{{< /details >}}

現在、ほとんどのSelf-Managedのお客様は単一のデータベースのみを利用しています。GitLab.comとSelf-Managed間の設定が同じであることを保証するために、Self-Managedのお客様には、デフォルトで2つのデータベースを移行して実行するようお願いしています。16.0では、2つのデータベース接続がSelf-Managedインストール向けのデフォルトとなりました。17.0では、[2データベースモードを制限付きベータ版としてリリース](../../administration/postgresql/_index.md)し、19.0までに分解された実行を一般提供することを目指しています。17.0では、2つのデータベースへの移行は引き続きオプションですが、19.0にアップグレードする前に実行する必要があります。

この移行にはダウンタイムが必要です。Self-Managedのお客様は、ダウンタイムを伴うこの移行を実行する[ツール](https://gitlab.com/gitlab-org/gitlab/-/issues/368729)を使用できます。単一データベースのGitLabインスタンスを分解されたセットアップにアップグレードできる新しい`gitlab-ctl`コマンドを導入しました。このセットアップには、当社のLinuxパッケージで動作するコマンドが含まれています。実際の[移行](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135585)（データベースのコピー）は、GitLabプロジェクト内のRakeタスクの一部です。

### プライベート共有グループメンバーがすべてのメンバーのメンバータブに表示されます {#private-shared-group-members-are-listed-on-members-tab-for-all-members}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/members/sharing_projects_groups.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/418888)

{{< /details >}}

以前は、公開グループまたはプロジェクトがプライベートグループを招待した場合、プライベートグループはメンバーページのグループタブにのみ表示され、プライベートメンバーは公開グループのメンバーには表示されませんでした。これらのグループのメンバー間のより良いコラボレーションを可能にするため、招待されたすべてのグループメンバーをメンバータブにも表示するようになりました。これには、プライベート招待グループのメンバーも含まれます。メンバーシップのソースは、プライベートグループにアクセスできないメンバーからはマスクされます。ただし、メンバーシップのソースは、プロジェクトで少なくともメンテナーロール、またはグループでオーナーロールを持つユーザーには表示され、プロジェクトまたはグループのメンバーを管理できるようになります。メンバータブを表示している現在のユーザーが認証されていない場合、またはグループやプロジェクトのメンバーではない場合、プライベートグループのメンバーは表示されません。この変更により、グループおよびプロジェクトのメンバーが、どのグループまたはプロジェクトに誰がアクセスできるかを一目で簡単に理解できるようになることを願っています。

### メンバーページに招待されたグループのメンバーが表示されます {#members-page-displays-members-from-invited-groups}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/members/_index.md#share-a-project-with-a-group) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/219230)

{{< /details >}}

以前は、グループまたはプロジェクトに招待されたグループのメンバーは、メンバーページのグループタブにのみ表示されていました。これは、ユーザーが特定のグループまたはプロジェクトに誰がアクセスできるかを理解するために、グループタブとメンバータブの両方を確認する必要があったことを意味します。現在、共有メンバーもメンバータブに表示され、グループまたはプロジェクトに属するすべてのメンバーの完全な概要を一目で確認できるようになりました。

### REST APIを使用したBitbucket Cloudからのインポート {#import-from-bitbucket-cloud-by-using-rest-api}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/import.md#import-repository-from-bitbucket-cloud) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/215036)

{{< /details >}}

このマイルストーンでは、REST APIを使用してBitbucket Cloudプロジェクトをインポートする機能を追加しました。

これは、UIを使用して多数のプロジェクトをインポートするよりも優れたソリューションとなる可能性があります。

### APIを使用して選択したプロジェクトリレーションを再インポートする {#re-import-a-chosen-project-relation-by-using-the-api}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/project_import_export.md#import-project-resources) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/425798)

{{< /details >}}

多数の同じ種類のアイテム（例えば、MRやパイプライン）を含むエクスポートファイルからプロジェクトをインポートする際、それらのアイテムの一部がインポートされないことがありました。

このリリースでは、指定されたリレーションを再インポートし、既にインポートされたアイテムをスキップするAPIエンドポイントを追加しました。APIには次の両方が必要です:

- プロジェクトのエクスポートアーカイブ。
- タイプ（イシュー、MR、パイプライン、またはマイルストーン）。

### GitLabで複数のJiraプロジェクトのイシューを表示 {#view-issues-from-multiple-jira-projects-in-gitlab}

<!-- categories: Integrations -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../integration/jira/configure.md#view-jira-issues) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/12609)

{{< /details >}}

大規模なリポジトリの場合、Jiraイシューインテグレーションを設定すると、GitLabで複数のJiraプロジェクトのイシューを表示できるようになりました。このリリースにより、次のことが可能になります:

- コンマで区切られた最大100個のJiraプロジェクトキーを入力します。
- **Jiraプロジェクトキー**を空白のままにして、利用可能なすべてのキーを含めます。

GitLabでJiraイシューを表示する際、プロジェクト別に[イシューをフィルター](../../integration/jira/configure.md#filter-jira-issues)できます。

GitLab Ultimateで[脆弱性のJiraイシューを作成](../../integration/jira/configure.md#create-a-jira-issue-for-a-vulnerability)するには、1つのJiraプロジェクトのみを指定できます。

### REST APIを使用してGitLabでJiraイシューの表示を有効にする {#enable-viewing-jira-issues-in-gitlab-with-the-rest-api}

<!-- categories: API, Integrations -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/project_integrations.md#jira-issues) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/267015)

{{< /details >}}

このリリースにより、REST APIを使用してGitLabで[Jiraイシューの表示](../../integration/jira/configure.md#view-jira-issues)を有効にできます。1つ以上のJiraプロジェクトからイシューを表示することもできます。

[Ivan](https://gitlab.com/ivantedja)様の[このコミュニティコントリビュート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150209)に感謝します！

### サービスデスクの複数の外部参加者 {#multiple-external-participants-for-service-desk}

<!-- categories: Service Desk -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/service_desk/external_participants.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/3758)

{{< /details >}}

場合によっては、サポートチケットの解決に関与する人が複数いる場合や、リクエスタが同僚にチケットの状況を最新の状態に保ちたい場合があります。

これで、サービスデスクチケットおよび通常のイシューに、GitLabアカウントを持たない最大10人の外部参加者を含めることができます。

外部参加者は、チケット上の公開コメントごとにサービスデスク通知メールを受信し、その返信はGitLab UIにコメントとして表示されます。

簡単なキー操作で外部参加者を追加または削除するには、クイックアクション[`/add_email`](../../user/project/service_desk/external_participants.md#add-an-external-participant)と[`remove_email`](../../user/project/service_desk/external_participants.md#add-an-external-participant)を使用するだけです。

GitLabを構成して、最初のメールの[`Cc`ヘッダーからすべてのメールアドレスを](../../user/project/service_desk/external_participants.md#add-external-participants-from-the-cc-header)サービスデスクチケットに追加することもできます。

[すべてのサービスデスクメールテンプレートを好みに合わせて調整](../../user/project/service_desk/configure.md#customize-emails-sent-to-external-participants)し、Markdown、HTML、および動的なプレースホルダーを使用できます。外部参加者が会話からオプトアウトできるように、[購読解除リンクのプレースホルダー](../../user/project/service_desk/external_participants.md#add-an-external-participant)が利用可能です。

### 直接転送を使用してアイテムがインポートされたことを示す {#indicate-that-items-were-imported-using-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/group/import/direct_transfer_migrations.md#review-results-of-the-import) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/443492)

{{< /details >}}

GitLabインスタンス間でGitLabグループとプロジェクトを[直接転送を使用して移行する](../../user/group/import/_index.md)ことができます。

これまで、インポートされたアイテムは簡単に識別できませんでした。このリリースにより、直接転送でインポートされたアイテムに視覚的なインジケーターを追加しました。そのアイテムの作成者は特定のユーザーとして識別されます:

- ノート（システムノートとユーザーコメント）
- イシュー
- マージリクエスト
- エピック
- デザイン
- スニペット
- ユーザープロファイルのアクティビティ

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### JetBrains IDE向けのGitLab Duoプラグインにおける1Passwordシークレットインテグレーション {#1password-secrets-integration-in-gitlab-duo-plugin-for-jetbrains-ides}

<!-- categories: Editor Extensions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../editor_extensions/jetbrains_ide/_index.md#integrate-with-1password-cli) | [関連イシュー](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/291)

{{< /details >}}

JetBrains向けのGitLab Duoプラグインと1Passwordシークレット管理を統合できるようになりました。

デベロッパーは、JetBrains IDE設定内のパーソナルアクセストークンを1Passwordシークレット参照に置き換えることができます。これによりシークレットの管理が簡素化され、手動でのトークン更新なしにシームレスなシークレットローテーションが可能になります。

### カスタマイズ可能なショートカットでGitLab Duo Chatに素早くアクセス {#access-gitlab-duo-chat-faster-with-customizable-shortcuts}

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../editor_extensions/jetbrains_ide/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/332)

{{< /details >}}

JetBrainsのエディタから直接Duo Chatを開くのがさらに簡単になりました。

デフォルトのAlt+Dキーボードショートカット（または独自のショートカット）を使用して、Duo Chatを素早く開き、質問を入力できます。同じキーボードショートカットを使用してウィンドウを閉じます。

### プロジェクトコメントテンプレート {#project-comment-templates}

<!-- categories: Code Review Workflow, Team Planning -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/comment_templates.md#for-a-project) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/440818)

{{< /details >}}

[GitLab 16.11でのグループコメントテンプレート](https://about.gitlab.com/releases/2024/04/18/gitlab-16-11-released/#group-comment-templates)のリリースに続き、GitLab 17.0ではこれらをプロジェクトにも導入します。

組織全体で、イシュー、エピック、およびMRで同じテンプレート化された応答を持つことは役立ちます。これらの応答には、回答が必要な標準的な質問、一般的な問題への応答、またはマージリクエストのレビューコメントの適切な構造が含まれる場合があります。プロジェクトレベルのコメントテンプレートは、テンプレートの利用可能性をスコープする追加の方法を提供し、組織がユーザー間でこれらを共有する際の制御と柔軟性を高めます。

コメントテンプレートを作成するには、GitLabの任意のコメントボックスに移動し、**コメントテンプレートの挿入 > Manage project comment templates**を選択します。コメントテンプレートを作成すると、すべてのプロジェクトメンバーが利用できるようになります。コメント作成中に**コメントテンプレートの挿入**アイコンを選択すると、保存された応答が適用されます。

このコメントテンプレートのイテレーションに大変期待しており、フィードバックがある場合は、[イシュー451520](https://gitlab.com/gitlab-org/gitlab/-/issues/451520)に残してください。

### GitLab UIコミットのコミット署名 {#commit-signing-for-gitlab-ui-commits}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/gitaly/configure_gitaly.md#configure-commit-signing-for-gitlab-ui-commits) | [関連イシュー](https://gitlab.com/gitlab-org/gitaly/-/issues/5361)

{{< /details >}}

以前は、GitLabによって行われたウェブコミットおよび自動化されたコミットは署名できませんでした。これで、Self-Managedインスタンスを署名キー、コミッター名、メールアドレスで構成し、ウェブおよび自動化されたコミットに署名できます。

### Kubernetesエージェント認可制限の引き上げ {#increase-kubernetes-agent-authorization-limit}

<!-- categories: Continuous Delivery -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/clusters/agent/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/431133)

{{< /details >}}

Kubernetes向けGitLabエージェントを使用すると、単一のエージェント接続をグループと共有できます。大規模なマルチテナントクラスター全体で単一のエージェントをサポートすることを目指しています。ただし、接続共有数に制限があったかもしれません。Until now, an agent could be shared with only 100 projects and groups using [CI/CD](../../user/clusters/agent/ci_cd_workflow.md) , and 100 projects and groups using the [`user_access`](../../user/clusters/agent/user_access.md) keyword.GitLab 17.0では、共有できるプロジェクトとグループの数が500に増加しました。

クラスターで複数のエージェントを実行する必要がある場合は、[イシュー454110](https://gitlab.com/gitlab-org/gitlab/-/issues/454110)で皆様のフィードバックをお聞かせください。

### FIPSモードでのKubernetes向けGitLabエージェントのサポート {#support-for-gitlab-agent-for-kubernetes-in-fips-mode}

<!-- categories: Continuous Delivery -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/clusters/kas.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/375327)

{{< /details >}}

GitLab 17.0から、Kubernetesコンポーネント用のエージェントを有効にして、GitLabをFIPSモードでインストールできます。これで、FIPS準拠のユーザーは、[GitLabとのすべてのKubernetesインテグレーション](../../user/clusters/agent/_index.md)の恩恵を受けることができます。

### デプロイにおける早送りMRの追跡 {#track-fast-forward-merge-requests-in-deployments}

<!-- categories: Continuous Delivery -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/deployments.md#track-newly-included-merge-requests-per-deployment) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/384104)

{{< /details >}}

以前のリリースでは、MRは、プロジェクトのマージ方法が**マージコミット**または**半線形の履歴を持たせたマージコミット**の場合にのみ、デプロイで追跡されていました。GitLab 17.0から、MRは、**早送りマージ**のマージ方法を使用するプロジェクトを含め、デプロイで追跡されるようになりました。

### 管理者モードによって開始されたセッションの識別 {#identify-sessions-initiated-by-admin-mode}

<!-- categories: User Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/settings/sign_in_restrictions.md#check-if-your-session-has-admin-mode-enabled) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/438674)

{{< /details >}}

インスタンス管理者として、複数のブラウザや異なるコンピューターを使用している場合、どのセッションが管理者モードで、どれがそうでないかを把握するのは困難です。これで、管理者は**ユーザー設定 > Active Sessions**に移動して、どのセッションが管理者モードを使用しているかを特定できます。

[Roger Meier](https://gitlab.com/bufferoverflow)様のコントリビュートに感謝いたします！

### ユーザー向けアバターのカスタマイズ {#customize-avatars-for-users}

<!-- categories: User Management -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/users.md#upload-an-avatar-for-yourself) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/356868)

{{< /details >}}

これで、APIを使用して、ボットユーザーを含むあらゆるユーザータイプにカスタムアバターをアップロードできます。これは、グループやプロジェクトのアクセストークン、またはサービスアカウントなどのボットユーザーを、UI内の人間ユーザーと視覚的に区別するのに特に役立ちます。[Phawin](https://gitlab.com/lifez)さんのコントリビュートに感謝いたします！

### カスタムロールとその権限の編集 {#edit-a-custom-role-and-its-permissions}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/custom_roles/_index.md#edit-a-custom-role) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/437590)

{{< /details >}}

以前は、既存のカスタムロールとその権限を編集できませんでした。これで、変更を行うためにロールを再作成することなく、カスタムロールとその権限を編集できます。

### カスタムロールの新しい権限 {#new-permissions-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/custom_roles/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

カスタムロールの作成に使用できる新しい権限があります:

- [セキュリティポリシーリンクの割り当て](../../user/custom_roles/abilities.md#security-policy-management)
- [コンプライアンスフレームワークの管理と割り当て](../../user/custom_roles/abilities.md#compliance-management)
- [Webhookを管理する](../../user/custom_roles/abilities.md#webhooks)
- [プッシュルールの管理](../../user/custom_roles/abilities.md#source-code-management)

これらのカスタム権限のリリースにより、これらのオーナーと同等の権限を持つカスタムロールを作成することで、グループで必要なオーナーの数を減らすことができます。カスタムロールを使用すると、ユーザーがジョブを実行するために必要な権限のみを与えるきめ細かいロールを定義し、不必要な権限昇格を減らすことができます。

### Self-Managedインスタンスレベルでのカスタムロールの管理 {#manage-custom-roles-at-self-managed-instance-level}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/custom_roles/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/11851)

{{< /details >}}

このリリースより前は、Self-Managed GitLabではカスタムロールはグループレベルで作成する必要がありました。これは、管理者がインスタンス全体のカスタムロールを一元的に管理できず、インスタンス全体でロールが重複する原因となっていました。これで、カスタムロールはSelf-Managedインスタンスレベルで管理されます。管理者のみがカスタムロールを作成できますが、管理者とグループオーナーの両方がこれらのカスタムロールを割り当てることができます。

既存のカスタムロール、APIエンドポイント、およびワークフローの移行の詳細については、[エピック11851](https://gitlab.com/groups/gitlab-org/-/epics/11851)を参照してください。

この更新は、GitLab.com上のカスタムロールワークフローには影響しません。

### カスタムロールに対するUXの改善 {#ux-improvements-to-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/custom_roles/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/11947)

{{< /details >}}

カスタムロールのユーザーエクスペリエンスに対して、具体的に一連の改善が行われました:

- [新しいカスタムロールを作成すると、新しいページが開きます](https://gitlab.com/gitlab-org/gitlab/-/issues/393238)。
- [カスタムロールテーブルのデザインが改善](https://gitlab.com/gitlab-org/gitlab/-/issues/437592)されました。
- [カスタムロール削除ダイアログのデザインが改善](https://gitlab.com/gitlab-org/gitlab/-/issues/434431)されました。
- [基本ロールの権限を事前チェック](https://gitlab.com/gitlab-org/gitlab/-/issues/430915)します。

### 管理者およびグループ向けのブランチ保護設定の改善 {#improved-branch-protection-settings-for-administrators-and-for-groups}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/repository/branches/default.md#for-all-projects-in-an-instance)

{{< /details >}}

以前は、デフォルトブランチ保護オプションを設定しても、保護ブランチの設定と同じレベルの設定はできませんでした。

このリリースでは、デフォルトブランチ保護設定を更新し、保護ブランチと同じ体験を提供します。これにより、デフォルトブランチの保護における柔軟性が高まり、既存の保護ブランチ設定と一致するようにプロセスが簡素化されます。

### ポリシーボットコメントのオプション設定 {#optional-configuration-for-policy-bot-comment}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/scan_execution_policies.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/438272)

{{< /details >}}

セキュリティポリシーボットは、セキュリティポリシーに違反した場合にMRにコメントを投稿し、ユーザーがプロジェクトでポリシーが適用されるタイミング、評価が完了するタイミング、MRをブロックしている違反があるかどうか、およびそれらを解決するためのガイダンスを理解できるようにします。これらのコメントはオプションになり、各ポリシー内で有効または無効にできます。これにより、組織はこれらのポリシーについてユーザーにどのように伝えるかを決定する柔軟性と制御を得られます。

### 脆弱性レポートのフィルタリングを更新 {#updated-filtering-on-the-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md#filtering-vulnerabilities) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13339)

{{< /details >}}

脆弱性レポートフィルターの古い実装は、スケールするできませんでした。ページの横方向のスペースに制限がありました。これで、フィルターされた検索コンポーネントを使用して、ステータス、重大度、ツール、またはアクティビティの任意の組み合わせで脆弱性レポートをフィルターできます。この変更により、この提案された[識別子によるフィルター](https://gitlab.com/groups/gitlab-org/-/epics/13340)のように、新しいフィルターを追加できます。

### 開く失敗または閉じる失敗にマージリクエスト承認ポリシーを切替る {#toggle-merge-request-approval-policies-to-fail-open-or-fail-closed}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10816)

{{< /details >}}

コンプライアンスは、多くの組織にとって、要件を満たすこととデベロッパー開発速度が影響を受けないことのバランスを取るため、変動的な尺度で運用されています。マージリクエスト承認ポリシーは、DevSecOpsワークフローの中心であるMRにおいて、セキュリティとコンプライアンスを運用可能にするのに役立ちます。組織で制御をロールアウトする際に、ポリシー強制への移行を容易にしたいチームに柔軟性を提供するために、マージリクエスト承認ポリシーに新しい`fail open`オプションを導入します。

マージリクエスト承認ポリシーがオープン失敗するように設定されている場合、MRは、ポリシー違反があり、**と**そのプロジェクトでセキュリティアナライザーが適切に構成されている場合にのみブロックされるようになります。プロジェクトでアナライザーが有効になっていない場合、またはアナライザーが正常に結果を生成しない場合、ポリシーはこの特定のルールとアナライザーに対する違反とは見なされなくなります。このアプローチにより、チームが適切なスキャンの実行と実施を確実にするための作業を行うにつれて、ポリシーの段階的なロールアウトが可能になります。

### 未検証のセカンダリメールアドレスの自動削除 {#automatic-deletion-of-unverified-secondary-email-addresses}

<!-- categories: User Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/_index.md#delete-email-addresses-from-your-user-profile) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/367823)

{{< /details >}}

ユーザープロフィールにセカンダリメールアドレスを追加し、それを検証しない場合、そのメールアドレスは3日後に自動的に削除されます。以前は、これらのメールアドレスは予約状態であり、手動による介入なしには解放できませんでした。この自動削除により、管理者の負担が軽減され、ユーザーが所有権を持たないメールアドレスを予約するのを防ぐことができます。

### エラーのあるパッケージに対するパッケージレジストリUIのフィルター {#filter-package-registry-ui-for-packages-with-errors}

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/packages/package_registry/_index.md#view-packages) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/451054)

{{< /details >}}

GitLabパッケージレジストリを使用して、パッケージを公開およびダウンロードできます。場合によっては、エラーのためにパッケージのアップロードが失敗することがあります。以前は、アップロードに失敗したパッケージを素早く表示する方法はありませんでした。これにより、組織のパッケージレジストリの全体像を把握するのが困難でした。

これで、アップロードに失敗したパッケージのパッケージレジストリUIをフィルターできます。この改善により、発生したあらゆるイシューを調査し、解決することが容易になります。

### バリューストリームダッシュボードの新しい中央値マージ時間メトリクス {#new-median-time-to-merge-metric-in-value-streams-dashboard}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/435451)

{{< /details >}}

バリューストリームダッシュボードに新しいメトリクスとしてマージまでの中央値時間を追加しました。GitLabでは、このメトリクスは、MRが作成されてからマージされるまでの中央値時間を表します。この新しいメトリクスは、MRおよびコードレビュープロセスの効率性と生産性を特定することで、DevOpsの健全性を測定します。

このメトリクスが[他のSDLCメトリクスのコンテキスト](https://www.youtube.com/watch?v=yNZRac7gyYo)でどのように進化するかを分析することで、チームは生産性の低い月または高い月を特定し、新しいDevOpsプラクティスが開発速度とデリバリープロセスに与える影響を理解し、全体的なリードタイムを削減し、ソフトウエアデリバリーの開発速度を向上させることができます。

### デザイン管理機能が製品チームに拡張されました {#design-management-features-extended-to-product-teams}

<!-- categories: Design Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/issues/design_management.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/438829)

{{< /details >}}

GitLabは権限を更新することでコラボレーションを拡大しています。これで、レポーターロールを持つユーザーはデザイン管理機能にアクセスできるようになり、製品チームが設計プロセスに直接関与できるようになります。この変更により、ワークフローが簡素化され、組織全体からのより広範な参加を促すことでイノベーションが加速されます。

### エピック削除保護の強化 {#enhanced-epic-deletion-protection}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/epics/manage_epics.md#delete-an-epic) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/452189)

{{< /details >}}

エピックを削除する際の動作を更新し、プロジェクトの構造とデータをより効果的に保護するようにしました。これはすべて、プロジェクトを管理する際の制御と安心感を高めることに関わっています。

これで、親エピックを削除しても、すべての子レコードが自動的に削除されるのではなく、まず親関係を切り離すことでレコードを保持します。この変更により、エピックをより安全に管理できるようになり、誤って削除しても貴重な情報が失われることがなくなります。

### 作成日、最終更新日、タイトルでロードマップを並べ替える {#sort-the-roadmap-by-created-date-last-updated-date-and-title}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/roadmap/_index.md#sort-and-filter-the-roadmap) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/460492)

{{< /details >}}

ロードマップビューで利用可能なエピックのソートオプションを拡張し、プロジェクトの整理と優先順位付けの柔軟性を高めました。これで、**created date**、**last updated date**、および**title**でエピックを並べ替えることができます。この機能強化は、将来的にさらに高度なソート機能を可能にする基礎を築き、エピックをより動的に管理するのに役立ちます。

### バリューストリームダッシュボード向けの簡素化された設定ファイルスキーマ {#simplified-configuration-file-schema-for-value-streams-dashboard}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/analytics/value_streams_dashboard.md#customize-dashboard-panels) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/432185)

{{< /details >}}

簡素化されたスキーマ駆動型のカスタマイズ可能なUIフレームワークを使用して、バリューストリームダッシュボードパネルをカスタマイズできるようになりました。新しい形式では、フィールドはデータの表示とダッシュボードパネルの配置においてより高い柔軟性を提供します。新しいフレームワークにより、管理者は時間の経過とともにダッシュボードへの変更を追跡することができます。このバージョン履歴は、以前のバージョンに戻したり、ダッシュボードバージョン間の変更を比較したりするのに役立ちます。

このカスタマイズを使用することで、意思決定者はビジネスにとって最も関連性の高い情報に焦点を当てることができ、チームは主要なDevSecOpsメトリクスをより適切に整理して表示できます。

### グループ内のゲストがイシューをリンクできる {#guests-in-groups-can-link-issues}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/permissions.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10267)

{{< /details >}}

イシューとタスクを関連付けるために必要な最小ロールをレポーターからゲストに引き下げ、[権限](../../user/permissions.md)を維持しながらGitLabインスタンス全体で作業を整理する柔軟性を高めました。

### イシューボードでマイルストーンとイテレーションが表示される {#milestones-and-iterations-visible-on-issue-boards}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/issue_board.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/25758)

{{< /details >}}

プロジェクトのタイムラインとフェーズに関するより明確なインサイトを提供するために、イシューボードを改善しました。これで、マイルストーンとイテレーションの詳細がイシューカードに直接表示されるようになり、進捗状況を簡単に追跡し、チームのワークロードをその場で調整できます。この機能強化は、計画と実行をより効率的に行い、常に状況を把握し、スケジュールよりも早く進めることができるように設計されています。

### APIセキュリティテストアナライザーの更新 {#api-security-testing-analyzer-updates}

<!-- categories: API Security -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/api_security_testing/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/13644)

{{< /details >}}

17.0のリリースマイルストーン中に、次のAPIセキュリティテストアナライザーの更新を公開しました:

- システム環境変数は、CIRunnerから、特定の高度なシナリオ（リクエスト署名など）で使用されるカスタムPythonスクリプトに渡されるようになりました。これにより、これらのシナリオの実装が容易になります。詳細については、[イシュー457795](https://gitlab.com/gitlab-org/gitlab/-/issues/457795)を参照してください。
- APIセキュリティコンテナは、非ルートユーザーとして実行されるようになり、柔軟性とコンプライアンスが向上しました。詳細については、[イシュー287702](https://gitlab.com/gitlab-org/gitlab/-/issues/287702)を参照してください。
- TLSv1.3暗号のみを提供するサーバーのサポートにより、より多くの顧客がAPIセキュリティテストを採用できるようになります。詳細については、[イシュー441470](https://gitlab.com/gitlab-org/gitlab/-/issues/441470)を参照してください。
- セキュリティ脆弱性に対処するalpine 3.19へのアップグレード。詳細については、[イシュー456572](https://gitlab.com/gitlab-org/gitlab/-/issues/456572)を参照してください。

[以前発表](../../update/deprecations.md#secure-analyzers-major-version-update)されたように、GitLab 17.0で[APIセキュリティテストのメジャーバージョン番号を5に引き上げました](https://gitlab.com/gitlab-org/gitlab/-/issues/456874)。

### Android向け依存関係スキャンのサポート {#dependency-scanning-support-for-android}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#use-cicd-components) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/12968)

{{< /details >}}

依存関係スキャンのユーザーは、Androidプロジェクトをスキャンできるようになりました。Androidスキャンを構成するには、[CI/CDカタログコンポーネント](https://gitlab.com/explore/catalog/components/android-dependency-scanning)を使用します。Androidスキャンは、[CI/CDテンプレート](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#edit-the-gitlab-ciyml-file-manually)のユーザーにもサポートされています。

### 依存関係スキャンのデフォルトPythonイメージ {#dependency-scanning-default-python-image}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#supported-languages-and-package-managers) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/441491)

{{< /details >}}

Python 3.9のデフォルトPythonイメージとしての非推奨化に続き、Python 3.11が現在のデフォルトイメージとなりました。

[非推奨](../../update/deprecations.md#deprecate-python-39-in-dependency-scanning-and-license-scanning)のお知らせに記載されているように、新しいデフォルトPythonバージョンの目標は3.10でした。Python 3.11への直接的な移行は、FIPSコンプライアンスを確保するために必要でした。

### DASTがデフォルトでarm64とamd64両方のアーキテクチャをサポート {#dast-now-supports-both-arm64-and-amd64-architectures-by-default}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dast/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/13757)

{{< /details >}}

DAST 5は、arm64とamd64両方のアーキテクチャをデフォルトでサポートしています。これにより、お客様はRunnerホストアーキテクチャを選択し、コスト削減を最適化できます。

### より多くの言語に対応した合理化されたSASTアナライザーカバレッジ {#streamlined-sast-analyzer-coverage-for-more-languages}

<!-- categories: SAST -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/application_security/sast/_index.md#supported-languages-and-frameworks) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/412060)

{{< /details >}}

GitLab SAST（SAST）は、より少ない[アナライザー](../../user/application_security/sast/analyzers.md)で同じ[言語](../../user/application_security/sast/_index.md#supported-languages-and-frameworks)をスキャンするようになり、よりシンプルでカスタマイズ可能なスキャンエクスペリエンスを提供します。

GitLab 17.0では、言語固有のアナライザーを、以下の言語向けの[Semgrepベースのアナライザー](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep)内の[GitLabマネージドルール](../../user/application_security/sast/rules.md)に置き換えました:

- Android
- CとC++
- iOS
- Kotlin
- Node.js
- PHP
- Ruby

[発表](../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170)されたように、新しいスキャンカバレッジを反映し、使用されなくなった言語固有のアナライザージョブを削除するために、[SASTCI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.gitlab-ci.yml)を更新しました。

### ルールをオーバーライドまたは無効にする際のリモートルールセットをシークレット検出がサポートするようになりました {#secret-detection-now-supports-remote-rulesets-when-overriding-or-disabling-rules}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/secret_detection/pipeline/configure.md#with-a-remote-ruleset) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/425251)

{{< /details >}}

リモートルールセットに影響を与えていたシークレット検出のバグを解決しました。リモートルールセットを介してルールをオーバーライドまたは無効にすることが可能になりました。リモートルールセットは、単一の場所でルールを設定するスケーラブルな方法を提供し、複数のプロジェクトに適用できます。

### シークレット検出の高度な脆弱性追跡を導入 {#introducing-advanced-vulnerability-tracking-for-secret-detection}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/secret_detection/pipeline/_index.md#duplicate-vulnerability-tracking) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/434096)

{{< /details >}}

シークレット検出は、高度な脆弱性追跡アルゴリズムを使用するようになり、リファクタリングや無関係な変更によって同じシークレットがファイル内で移動した場合でも、より正確に識別できるようになりました。以下の場合、新しい発見は作成されません:

- リークがファイル内で移動する場合。
- 同じ値の新しいリークが同じファイル内に表示される場合。

それ以外の場合、既存のワークフロー（マージリクエストウィジェット、パイプラインレポート、および脆弱性レポート）は、以前と同じように発見を扱います。脆弱性の重複が、シークレットの場所が変更されたときに報告されないようにすることで、チームは流出したシークレットをより簡単に管理できるようになります。

### 公開されたCI/CDコンポーネントのセマンティックバージョン範囲 {#semantic-version-ranges-for-published-cicd-components}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/components/_index.md#semantic-versioning) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/450835)

{{< /details >}}

CI/CDカタログコンポーネントを使用する場合、最新のバージョンが自動的に使用されるようにしたいことがあります。たとえば、使用するすべてのコンポーネントを手動で監視し、マイナーアップデートやセキュリティパッチがあるたびに手動で次のバージョンに切り替える必要はありません。しかし、`~latest`の使用は、マイナーバージョンのアップデートで望ましくない動作変更が発生する可能性があり、メジャーバージョンのアップデートでは破壊的な変更のリスクが高いため、少々危険でもあります。

このリリースにより、CI/CDコンポーネントの最新のメジャーバージョンまたはマイナーバージョンを使用することを選択できるようになりました。たとえば、コンポーネントのバージョンとして`2`を指定すると、そのメジャーバージョンのすべてのアップデート（`2.1.1`、`2.1.2`、`2.2.0`など）が得られますが、`3.0.0`は得られません。`2.1`を指定すると、そのマイナーバージョンのパッチアップデート（`2.1.1`、`2.1.2`など）のみが得られますが、`2.2.0`は得られません。

### CI/CDカタログコンポーネント公開プロセスの標準化 {#standardized-cicd-catalog-component-publishing-process}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/components/_index.md#publish-a-new-release) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/442066)

{{< /details >}}

私たちはCI/CDコンポーネントの開発に懸命に取り組んでおり、CI/CDカタログへのコンポーネントのリリースプロセスを一貫性のあるものにすることも含まれます。その作業の一環として、[`release`キーワード](../../ci/yaml/_index.md#release)と`release-cli`イメージを使用したCI/CDジョブからのバージョンリリースを唯一の方法としました。リリースプロセスへのすべての改善は、この方法にのみ適用されます。この制限によって導入される破壊的な変更を避けるため、常にイメージの最新のバージョン（`release-cli:latest`）を使用するか、少なくとも`v0.17`より大きいバージョンを使用してください。[**リリース**オプションは、UI](../../user/project/releases/_index.md#create-a-release-in-the-releases-page)のCI/CDコンポーネントプロジェクトでは無効になりました。

### キャンセルされたジョブに対して常に`after_script`コマンドを実行 {#always-run-after_script-commands-for-canceled-jobs}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/yaml/script.md#set-a-default-before_script-or-after_script-for-all-jobs) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10158)

{{< /details >}}

[`after_script`](../../ci/yaml/_index.md#after_script) CI/CDキーワードは、ジョブのメイン`script`セクションに続いて追加コマンドを実行するために使用されます。これは多くの場合、ジョブで使用された環境またはその他のリソースをクリーンアップするために使用されます。しかし、ジョブがキャンセルされた場合、`after_script`コマンドは実行されませんでした。

GitLab 17.0以降、ジョブがキャンセルされた場合でも`after_script`コマンドは常に実行されます。オプトアウトするには、[ドキュメント](../../ci/yaml/script.md#skip-after_script-commands-if-a-job-is-canceled)を参照してください。

### GitLab Runner 17.0 {#gitlab-runner-170}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 17.0もリリースします！GitLab Runnerは、CI/CDジョブを実行し、結果をGitLabインスタンスに送信する、軽量で拡張性の高いエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- 切断されたネットワーク環境にRunnerオペレーターをインストールするための[ドキュメント](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/123)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-0-stable/CHANGELOG.md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.0)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.0)
- [UI改善](https://papercuts.gitlab.com/?milestone=17.0)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
