---
stage: Release Notes
group: Monthly Release
date: 2023-08-22
title: "GitLab 16.3リリースノート"
description: "GitLab 16.3はValue Streams Dashboardに新しい開発速度メトリクスを搭載してリリースされました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2023年8月22日、GitLab 16.3が次の機能を備えてリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Thomas Spear {#this-months-notable-contributor-thomas-spear}

Thomasは先月、[15件のマージリクエスト](https://gitlab.com/gitlab-org/charts/gitlab-agent/-/merge_requests?scope=all&state=merged&author_username=tspearconquest)を[Kubernetes向けGitLabエージェントHelmチャート](https://gitlab.com/gitlab-org/charts/gitlab-agent)にコントリビュートしました！

Thomasは、セキュリティと可観測性の面でチャートをより成熟させ、agentkに関する問題のトラブルシューティングを簡素化し、破壊的な変更をチェックするためにCI/CDパイプラインを改善しました。

セキュリティエンジニアとして、Thomasはチームと協力して、GitLabエージェントのより安全なデフォルトデプロイを提供することを楽しんでいます。Thomasは、チームメンバーが喜んで提供したすべてのタイムリーなレビューとフィードバックに感謝の意を表しました。

Thomasさん、ありがとうございます。あなたのコントリビュートに心から感謝します！🙌

[Shane Maglangit](https://gitlab.com/ShaneMaglangit)と[Batuhan Apaydın](https://gitlab.com/batuhan.apaydin)の素晴らしいコントリビュートにもこの機会に感謝したいと思います。

## 主要な機能 {#primary-features}

### Value Streams Dashboardの新しい開発速度メトリクス {#new-velocity-metrics-in-the-value-streams-dashboard}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/analytics/value_streams_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/383665)

{{< /details >}}

The [Value Streams Dashboard](https://about.gitlab.com/blog/getting-started-with-value-streams-dashboard/)は、新しいメトリクスで強化されました: **Merge request (MR) throughput**と**Total closed issues**。GitLabでは、**MR throughput**は1ヶ月あたりのマージリクエスト数、**Total closed issues**はある時点でのフローアイテムのクローズ数を表します。

これらのメトリクスにより、生産性の低い月や高い月、および[マージリクエストとコードレビュープロセス](../../user/analytics/merge_request_analytics.md)の効率性を特定できます。次に、[Value Stream delivery](../../user/group/value_stream_analytics/_index.md)が加速しているかどうかを判断できます。

時間が経つにつれて、メトリクスはMRとイシューからの履歴データを蓄積します。チームはこのデータを使用して、配信率が加速しているか、改善が必要かを判断し、どれだけの作業を配信できるかについて、より正確な見積もりや予測を提供できます。

Value Streams Dashboardの改善にご協力いただくため、この[アンケート](https://gitlab.fra1.qualtrics.com/jfe/form/SV_50guMGNU2HhLeT4)でご意見をフィードバックしてください。

### ワークスペースにSSHで接続 {#connect-to-workspaces-with-ssh}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/workspace/configuration.md#connect-to-a-workspace-with-ssh)

{{< /details >}}

ワークスペースを使用すると、再現性のある一時的なクラウドベースのランタイム環境を作成できます。GitLab 16.0でこの機能が導入されて以来、ワークスペースを使用する唯一の方法は、環境で直接実行されるブラウザベースのWeb IDEを介することでした。しかし、Web IDEは常に最適なツールであるとは限りません。

GitLab 16.3では、デスクトップからSSHを使用してワークスペースに安全に接続し、ローカルツールと拡張機能を使用できます。最初のイテレーションでは、VS CodeでのSSH接続、またはVimやEmacsなどのエディタを使用したコマンドラインからのSSH接続を直接サポートします。JetBrains IDEやJupyterLabなどの他のエディタのサポートは、今後のイテレーションで提案されています。

### Flux同期ステータス可視化 {#flux-sync-status-visualization}

<!-- categories: Environment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/kubernetes_dashboard.md#flux-sync-status) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/391581)

{{< /details >}}

以前のリリースでは、おそらく`kubectl`または別のサードパーティツールを使用してFluxデプロイのステータスを確認していました。GitLab 16.3から、環境UIでデプロイメントを確認できます。

デプロイは、特定の環境のステータスを収集するためにFlux `Kustomization`および`HelmRelease`リソースに依存しており、そのためには環境にネームスペースを設定する必要があります。デフォルトでは、GitLabはプロジェクトslug名のために`Kustomization`および`HelmRelease`リソースを検索します。環境設定でGitLabが検索する名前をカスタマイズできます。

### スキャン結果ポリシーの追加フィルタリング {#additional-filtering-for-scan-result-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/6826)

{{< /details >}}

セキュリティまたはコンプライアンススキャンの結果のうち、どれが実行可能であるかを判断することは、セキュリティおよびコンプライアンスチームにとって大きな課題です。スキャン結果ポリシーのきめ細かなフィルターは、どの脆弱性または違反に最も注意を払う必要があるかを特定するために、ノイズを排除するのに役立ちます。これらの新しいフィルターとフィルターの更新により、ワークフローが効率化されます:

- ステータス: ステータスルールの変更により、「新規」脆弱性と「以前から存在していた」脆弱性の適用がより直感的に行われるようになります。新しいステータスフィールド`new_needs_triage`を使用すると、トリアージが必要な新しい脆弱性のみをフィルタリングできます。
- 経過時間: 検出された日付に基づいて、脆弱性がSLA（日、月、年）の範囲外である場合に承認を強制するポリシーを作成します。
- 修正利用可能: 修正が利用可能な依存関係に対処するようにポリシーの焦点を絞ります。
- 誤検出: 当社の脆弱性抽出ツールによって検出された誤検出をフィルタリングします（SAST結果の場合）。また、Rezilionを介して、コンテナスキャンと依存関係スキャンの結果もフィルタリングします。

### VS Codeでのセキュリティ検出結果 {#security-findings-in-vs-code}

<!-- categories: Editor Extensions, API Security, Container Scanning, DAST, Fuzz Testing, SAST, Secret Detection, Software Composition Analysis, Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../editor_extensions/visual_studio_code/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10407)

{{< /details >}}

マージリクエストと同様に、Visual Studio Code（VS Code）でセキュリティ検出結果を直接確認できるようになりました。

以前から、CI/CDパイプラインのステータスを監視し、CI/CDジョブログを表示し、GitLabワークフローパネルで開発ワークフローを進めることができました。これで、ブランチのマージリクエストを作成した後、以前はデフォルトブランチで見つからなかった新しいセキュリティ検出結果のリストも表示できるようになります。

この新機能は、VS Code用[GitLab Workflow](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)の一部です。セキュリティスキャン結果はAPIからフェッチされるため、この機能はGitLab.comまたはGitLab 16.1以降を実行しているSelf-Managedインスタンスを使用している開発者が利用できます。

### 並列ジョブで`needs`キーワードを使用する {#use-the-needs-keyword-with-parallel-jobs}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/yaml/_index.md#needsparallelmatrix) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/254821)

{{< /details >}}

`needs`キーワードは、ジョブ間の依存関係を定義するために使用されます。このキーワードを使用して、ステージの順序に従う代わりに、特定の以前のジョブに依存するように設定できます。依存ジョブが完了すると、そのジョブはすぐに開始され、パイプラインの速度が向上します。

以前は、[並列行列](../../ci/yaml/_index.md#parallelmatrix)ジョブを依存関係として設定するために`needs`キーワードを使用することはできませんでしたが、今回のリリースでは、並列行列ジョブでも`needs`を使用できるようになりました。これで、並列行列ジョブへの柔軟な依存関係を定義でき、パイプラインの速度をさらに向上させることができます！ジョブを早く開始できるほど、パイプラインも早く完了します！

### より強力なGitLab SaaS Runner (Linux用) {#more-powerful-gitlab-saas-runners-on-linux}

<!-- categories: GitLab Runner SaaS -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/hosted_runners/linux.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/388165)

{{< /details >}}

Linux SaaS Runnerをすべて最近アップグレードしたため、`xlarge`および`2xlarge`[Linux上のSaaS Runner](../../ci/runners/hosted_runners/linux.md)を導入しました。それぞれ16 vCPUと32 vCPUを搭載し、GitLab CI/CDと完全に統合されたこれらのRunnerを使用すると、これまで以上に速くアプリケーションをビルドおよびテストできます。

私たちは業界最速のCI/CDビルド速度を提供することを決意しており、チームがさらに短いフィードバックサイクルを達成し、最終的にソフトウェアをより速く提供するのを楽しみにしています。

### Azure Key Vaultシークレットマネージャーのサポート {#azure-key-vault-secrets-manager-support}

<!-- categories: Secrets Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/secrets/azure_key_vault.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/271271)

{{< /details >}}

Azure Key Vaultに保存されているシークレットは、CI/CDジョブで簡単に取得して使用できるようになりました。新しいインテグレーションにより、GitLab CI/CDを介したAzure Key Vaultとの連携プロセスが簡素化され、ビルドおよびデプロイプロセスを効率化できます！

## 規模とデプロイ {#scale-and-deployments}

### アーカイブされたプロジェクトをプロジェクト検索結果に含めるか除外するか {#include-or-exclude-archived-projects-from-project-search-results}

<!-- categories: Global Search -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/search/_index.md#include-archived-projects-in-search-results) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/413237)

{{< /details >}}

検索結果からアーカイブされたプロジェクトを含めるか除外するかを選択できるようになりました。デフォルトでは、アーカイブされたプロジェクトは除外されます。この機能は、GitLabのプロジェクト検索で利用できます。他の[グローバル検索スコープ](../../user/search/_index.md)のサポートは、今後のリリースで提案されています。

### Omnibusの改善 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- GitLab 16.3には[Mattermost 8.0](https://mattermost.com/blog/mattermost-v8-0-is-now-available/)が含まれています。このバージョンには[セキュリティアップデート](https://mattermost.com/security-updates/)が含まれており、以前のバージョンからのアップグレードをお勧めします。
- Amazon Linuxビルドは現在[Amazon Linux 2023](https://aws.amazon.com/linux/amazon-linux-2023/)です。Amazon Linux 2022は正式には一般提供されず、Amazon Linux 2023に置き換えられたため、提供内容を更新されたリリースに合わせて調整しました。

### アプリケーション設定の変更に関する監査イベントの記録 {#audit-event-recorded-for-applications-settings-change}

<!-- categories: Audit Events -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/compliance/audit_event_reports.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/282428)

{{< /details >}}

インスタンス、プロジェクト、およびグループレベルでのアプリケーション設定の変更が、変更を行ったユーザーとともに監査ログに記録されるようになりました。これにより、Self-ManagedとSaaSの両方でアプリケーション設定の監査が改善されます。

### Bitbucket Serverからインポートする際のプルリクエストレビュアーを保持する {#preserve-pull-request-reviewers-when-importing-from-bitbucket-server}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../integration/bitbucket.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/416611)

{{< /details >}}

これまで、Bitbucket Serverインポーターはプルリクエスト（PR）レビュアーをインポートせず、代わりにそれらを参加者として分類していました。PRレビュアーに関する情報は、監査およびコンプライアンスの観点から重要です。

GitLab 16.3では、BitbucketからのPRレビュアーを正しくインポートするサポートを追加しました。GitLabでは、彼らはマージリクエストのレビュアーになります。

### アプリケーション設定で利用可能な設定可能なインポート制限 {#configurable-import-limits-available-in-application-settings}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/group/import/_index.md#limits)

{{< /details >}}

直接転送による移行とエクスポートファイルによるインポートの両方に、ハードコードされた制限が存在します。

今回のリリースでは、これらの制限の一部をアプリケーション設定で設定可能にし、Self-Managed GitLab管理者がニーズに応じて調整できるようにしました:

- [直接転送でソースインスタンスからダウンロードできる最大リレーションサイズ](../../administration/settings/account_and_limit_settings.md)。以前は5 GBにハードコードされていました。GitLab.comでは、この制限を5 GBに設定しています。
- [リモートオブジェクトストレージ（AWS S3など）からダウンロードできるリモートインポートファイルの最大サイズ](../../administration/settings/account_and_limit_settings.md)。以前は10 GBにハードコードされていました。GitLab.comでは、この制限を10 GBに設定しています。

また、`validate_import_decompressed_archive_size`機能フラグに代わる新しい[インポートされたアーカイブの最大解凍されたファイルサイズ](../../administration/settings/account_and_limit_settings.md)アプリケーション設定を追加しました。この制限は10 GBにハードコードされていました。GitLab.comでは、この制限を25 GBに設定しています。

これらの新しいアプリケーション設定により、Self-Managed GitLabとGitLab.comの管理者は、必要に応じてこれらの制限を調整できます。

### 新しいナビゲーションでカラーテーマが利用可能に {#new-navigation-has-color-themes-available}

<!-- categories: Navigation & Settings -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/profile/preferences.md)

{{< /details >}}

新しいナビゲーションを有効にすると、5つの異なるカラーテーマから1つを選択し、それぞれにライトまたはダークのバリエーションを選択できます。テーマを使用して、異なる環境を識別したり、お好みの色を選択したりできます。

### 直接転送による移行におけるエンティティエクスポートタイムアウトなし {#no-entity-export-timeout-for-migrations-by-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/import/_index.md#limits) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/392725)

{{< /details >}}

これまで、直接転送によるグループおよびプロジェクトの移行には90分間のエクスポートタイムアウトがありました。この制限により、90分以内に移行できるプロジェクトのみが許可されていたため、大規模なプロジェクトは実質的に除外されていました。

全体的な移行タイムアウトの上限は4時間であるため、90分間のエクスポートタイムアウトは不要でした。このマイルストーンでは、制限が削除され、より大規模なプロジェクトの移行が可能になりました。

### Azure AD超過クレームのサポート {#support-for-azure-ad-overage-claim}

<!-- categories: User Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/saml_sso/group_sync.md#microsoft-azure-active-directory-integration) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/414875)

{{< /details >}}

GitLab SAMLグループ同期は、ユーザーが150を超えるグループを関連付けることを可能にするAzure AD（現在はEntra IDとして知られている）超過クレームをサポートするようになりました。以前の最大数は150グループでした。詳細については、[Microsoft group overages](https://learn.microsoft.com/en-us/security/zero-trust/develop/configure-tokens-group-claims-app-roles#group-overages)を参照してください。

### Geoがグループウィキを検証 {#geo-verifies-group-wikis}

<!-- categories: Geo-replication, Disaster Recovery -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../administration/geo/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/323897)

{{< /details >}}

Geoは、[グループウィキ](../../user/project/wiki/group.md)の保存時および転送時のデータ破損を検出して修正できるようになりました。Geoをディザスターリカバリー戦略の一部として使用する場合、これはフェイルオーバー発生時のデータ損失から保護するのに役立ちます。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### CODEOWNERSファイルの構文と形式の検証 {#codeowners-file-syntax-and-format-validation}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../user/project/codeowners/reference.md)

{{< /details >}}

UIで、`CODEOWNERS`ファイルに構文または書式設定エラーがあるかどうかを確認できるようになりました。コードオーナーを指定できることで、複数のファイル場所、セクション、およびルールをユーザーが設定できるなど、優れた柔軟性が提供されます。この新しい構文検証により、`CODEOWNERS`ファイル内のエラーがGitLab UIに表示され、イシューの発見と修正が容易になります。次のエラーが表示されます:

- スペースのあるエントリ。
- 解析できないセクション。
- 不正な形式のオーナー。
- アクセスできないオーナー。
- ゼロオーナー。
- 必要な承認が1未満。

以前は、`CODEOWNERS`ファイルは入力された情報を検証しませんでした。これにより、以下のような作成につながる可能性があります:

- 存在しないファイル/パスのルール。
- 他の既存のルールと競合するルール。
- 正しくない構文のため適用されないルール。

### Kubernetes 1.27サポート {#kubernetes-127-support}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/clusters/agent/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/420859)

{{< /details >}}

今回のリリースでは、2023年4月にリリースされたKubernetesバージョン1.27を完全にサポートします。Kubernetesを使用している場合、クラスターを最新のバージョンにアップグレードし、すべての機能を利用できるようになりました。

[当社のKubernetesサポートポリシー](../../user/clusters/agent/_index.md)と、その他のサポートされているKubernetesバージョンについて、詳細はこちらでご確認ください。

### 機能フラグ名を切り詰める代わりに折り返す {#wrap-feature-flag-names-instead-of-truncating}

<!-- categories: Feature Flags -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../operations/feature_flags.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/418147)

{{< /details >}}

以前のGitLabバージョンで機能フラグを使用していた場合、長い機能フラグ名が切り詰められることに気づいたかもしれません。これにより、類似した機能フラグ名をすばやく区別することが困難でした。

GitLab 16.3では、機能フラグ名全体が表示されます。必要に応じて、長い名前は複数行にわたって折り返されます。

### 監査イベントストリームの名前 {#names-for-audit-event-streams}

<!-- categories: Audit Events -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

以前は、監査イベントストリーミングのストリーミング先は、宛先URLによって割り当てられていました。これは、1つのグループまたはインスタンスに対して複数のストリームを設定した場合に混乱を招く可能性がありました。なぜなら、適用されたフィルターとカスタムヘッダーを確認するには、UIで宛先を展開する必要があったからです。

GitLab 16.3では、複数のストリーミング先が定義されている場合に、それらを識別し区別するために、監査イベントストリーミング先に名前を付けられるようになりました。

### 脆弱性の説明 {#explain-this-vulnerability}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10368)

{{< /details >}}

GitLabは関連情報を含む脆弱性を表面化しますが、どこから着手すべきか不明確な場合があります。脆弱性レコード内に表面化された情報を調査し、統合するには時間がかかります。さらに、特定の脆弱性をどのように修正するかを把握することも困難な場合があります。このベータリリースでは、ボタンをクリックするだけで、AIが生成した脆弱性の軽減方法に関する説明と推奨事項を得ることができます。

### コンプライアンスレポートがコンプライアンスセンターに名称変更 {#compliance-reports-renamed-to-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_center/_index.md)

{{< /details >}}

レポート作成を超えたコンプライアンス関連機能の成長を促進し、管理へと移行させるため、GitLabのコンプライアンスレポートセクションは、領域の拡大するスコープを反映するように名称変更されました。

GitLab 16.3から、コンプライアンスレポートはコンプライアンスセンターとして知られています。

### スキャン結果ポリシーの精度を向上 {#improve-accuracy-of-scan-result-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md) | [関連エピック](https://gitlab.com/gitlab-org/gitlab/-/issues/379108)

{{< /details >}}

スキャン結果ポリシーは、特定のルールに違反した場合にマージリクエストを評価し、ブロックするために使用するセキュリティポリシーの一種です。承認者は変更をレビューして承認するか、開発チームと協力してイシュー（重大なセキュリティ脆弱性への対処など）に対処できます。

以前は、ポリシー規則の新しい違反を検出するために、最新のソースブランチとターゲットブランチの脆弱性を比較していました。しかし、これはさまざまなパイプラインソースの結果として実行されるスキャンから検出された脆弱性を捕捉しない可能性があります。精度を向上させるため、各パイプラインソースの最新の完了したパイプラインを比較しています（親子パイプラインを除く）。これにより、より包括的な評価が保証され、予期しない場合に承認が必要となるケースが減少します。

### インスタンスレベルの監査イベントストリーミングフィルター {#instance-level-streaming-audit-event-filters}

<!-- categories: Audit Events -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

GitLab 16.2では、インスタンスレベルの監査イベントストリーミングを導入しました。しかし、これらのストリームに適用できるフィルターはありませんでした。

GitLab 16.3では、監査イベントタイプ別にフィルターをインスタンスレベルの監査イベントストリーミングに適用できるようになりました。UIにこれらのフィルターを追加することで、各ストリーミング先に送信する監査イベントのサブセットをキャプチャし、自分にとって関連するイベントのみに焦点を当てることができます。

### セキュリティボットがスキャン実行ポリシーのパイプラインをトリガーする {#security-bot-to-trigger-scan-execution-policies-pipelines}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/scan_execution_policies.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10756)

{{< /details >}}

バックグラウンドタスクの管理をサポートし、新しく作成または更新されたすべてのセキュリティポリシープロジェクトリンクに対してセキュリティポリシーを適用するために、セキュリティボットユーザーが作成されます。これにより、セキュリティおよびコンプライアンスチームメンバーがポリシーを設定および適用するプロセスが容易になります。特に、セキュリティポリシープロジェクトメンテナーが開発プロジェクトで`Developer`アクセスを維持する必要がなくなります。セキュリティポリシーボットユーザーは、セキュリティポリシーに代わってパイプラインが実行される場合に、適用されたプロジェクト内のユーザーにとってそれをより明確にします。なぜなら、このボットユーザーがパイプラインの作成者となるからです。

セキュリティポリシープロジェクトがグループまたはサブグループにリンクされると、そのグループまたはサブグループ内の各プロジェクトにセキュリティポリシーボットが作成されます。グループ、サブグループ、または個々のプロジェクトにリンクが作成されると、指定されたプロジェクトまたはグループやサブグループ内の任意のプロジェクトに対してセキュリティボットユーザーが作成されます。現在、すでにセキュリティポリシープロジェクトへのリンクがあるグループ、サブグループ、またはプロジェクトは影響を受けませんが、ユーザーはこの機能を活用するために既存のリンクを再確立できます。GitLab 16.4では、既存のセキュリティポリシープロジェクトリンクを持つGitLab.comでホストされているすべてのプロジェクトで[セキュリティボットを有効にする](https://gitlab.com/gitlab-org/gitlab/-/issues/414376)予定です。

### SASTアナライザーの更新 {#sast-analyzer-updates}

<!-- categories: SAST -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/application_security/sast/analyzers.md) | [関連イシュー](../../user/application_security/_index.md)

{{< /details >}}

GitLab SASTには、GitLab静的な解析チームが積極的に保守、更新、サポートする[多くのセキュリティアナライザー](../../user/application_security/sast/_index.md#supported-languages-and-frameworks)が含まれています。16.3リリースマイルストーン中に次の更新を公開しました:

- Kicsベースのアナライザーは、Kicsエンジンのバージョン1.7.5を使用するように更新されました。この更新には、さまざまなバグの修正が含まれており、JSONおよびYAMLの自己参照に対するエラー処理の改善も追加されています。詳細については、[変更履歴](https://gitlab.com/gitlab-org/security-products/analyzers/kics/-/blob/main/CHANGELOG.md?ref_type=heads#v414)を参照してください。
- Semgrepベースのアナライザーは、パススルーカスタム設定中に曖昧なrefsを指定するためのサポートを追加するように更新されました。また、SARIFパーサーを更新してTitleではなくNameを使用するようにし、エラーレベルのSARIF `toolExecutionNotifications`でスキャンが失敗しなくなりました。詳細については、[変更履歴](https://gitlab.com/gitlab-org/security-products/analyzers/semgrep/-/blob/main/CHANGELOG.md?ref_type=heads#v446)を参照してください。

[GitLab管理のSASTテンプレート](../../user/application_security/sast/_index.md) （[`SAST.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/ci/templates/Security/SAST.gitlab-ci.yml)）を含め、GitLab 16.0以降を実行している場合、これらの更新を自動的に受け取ります。特定のアナライザーのバージョンを維持し、自動更新を防ぐには、[そのバージョンを固定](../../user/application_security/sast/_index.md)できます。

以前の変更については、[先月の更新](https://about.gitlab.com/releases/2023/07/22/gitlab-16-2-released/#sast-analyzer-updates)を参照してください。

### 依存関係スキャンとライセンススキャンニングのJava v21サポート {#dependency-and-license-scanning-support-for-java-v21}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#obtaining-dependency-information-by-parsing-lockfiles) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/387307)

{{< /details >}}

GitLab依存関係スキャンとライセンススキャンニングは、Java v21 Mavenロックファイルの解析をサポートするようになりました。

### Runnerタグにより、オンデマンドDASTスキャンのUIベースの設定が可能に {#runner-tags-enable-ui-based-configuration-of-on-demand-dast-scans}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dast/on-demand_scan.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/345430)

{{< /details >}}

オンデマンドDASTスキャンに使用するRunnerをタグで指定できるようになりました。16.3以前は、CI設定ファイルを介してプライベートRunnerを使用してDASTスキャンを設定できました。このUIベースの設定により、DASTスキャンを管理するための効率的なUI設定が可能になります。

### SASTの脆弱性追跡機能の改善 {#improved-sast-vulnerability-tracking}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/5144)

{{< /details >}}

GitLab SAST [高度な脆弱性追跡](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking)は、コードが移動しても発見を追跡し続けることで、トリアージをより効率的にします。GitLab 16.3で2つの改善をリリースしました:

1. 言語サポートの拡大: [既存のカバレッジ](../../user/application_security/sast/_index.md#advanced-vulnerability-tracking)に加えて、次の高度な脆弱性追跡を有効にしました:
  - FlawfinderベースのアナライザーにおけるCおよびC++。
  - MobSFベースのアナライザーにおけるJava。
  - NodeJS-ScanベースのアナライザーにおけるJavaScript。
1. より良い追跡: JavaScriptの無名関数を処理するように追跡アルゴリズムを改善しました。

これは、[GitLab 16.2でリリース](https://about.gitlab.com/releases/2023/07/22/gitlab-16-2-released/#improved-sast-vulnerability-tracking)された以前の拡張機能と改善に基づいています。さらなる追跡の改善には、より多くの言語への拡張、より多くの言語構造のより良い処理、およびPythonとRubyの追跡の改善が含まれており、これらは[エピック5144](https://gitlab.com/groups/gitlab-org/-/epics/5144)で追跡しています。

これらの変更は、GitLab SAST [アナライザー](../../user/application_security/sast/analyzers.md)の[更新されたバージョン](https://docs.gitlab.com/#sast-analyzer-updates)に含まれています。プロジェクトの脆弱性発見は、更新されたアナライザーでプロジェクトがスキャンされた後、新しい追跡シグネチャで更新されます。[SASTアナライザーを特定のバージョンにピン留め](../../user/application_security/sast/_index.md)していない限り、この更新を受け取るためにアクションを実行する必要はありません。

### Postman APIキーの流出に対する自動応答 {#automatic-response-to-leaked-postman-api-keys}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Gold
- リンク: [ドキュメント](../../user/application_security/secret_detection/automatic_response.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/403825)

{{< /details >}}

シークレット検出をPostmanと統合し、GitLabプロジェクトでPostmanを使用するお客様をより適切に保護します。

シークレット検出は[Postman APIキー](https://learning.postman.com/docs/developer/postman-api/authentication/)を検索します。公開プロジェクトでキーがGitLab.comに流出した場合、GitLabは流出したキーをPostmanに送信します。Postmanはキーを検証し、その後[Postman APIキーのオーナーに通知](https://learning.postman.com/docs/administration/token-scanner/#protecting-postman-api-keys-in-gitlab)します。

このインテグレーションは、GitLab.comで[シークレット検出が有効化](../../user/application_security/secret_detection/_index.md)されているプロジェクトでデフォルトでオンになっています。シークレット検出スキャンはすべてのGitLab Tierで利用可能ですが、流出したシークレットへの自動応答は現在Ultimateプロジェクトでのみ利用可能です。

詳細については、[このインテグレーションに関するPostmanのブログ投稿](https://blog.postman.com/protecting-your-postman-api-keys-in-gitlab/)を参照してください。

### パイプライン名を事前定義されたCI/CD変数として公開する {#expose-pipeline-name-as-a-predefined-cicd-variable}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/variables/predefined_variables.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/420002)

{{< /details >}}

[`workflow:name`](../../ci/yaml/_index.md#workflowname)キーワードで定義されたパイプライン名は、事前定義された変数`$CI_PIPELINE_NAME`を介してアクセスできるようになりました。

### GitLab Runner 16.3 {#gitlab-runner-163}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 16.3もリリースします！GitLab Runnerは、CI/CDジョブを実行し、結果をGitLabインスタンスに送信する、軽量で拡張性の高いエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [プロジェクトクローンディレクトリをデフォルトで安全に設定](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29022)

#### バグ修正 {#bug-fixes}

- [Runner v16.2.0がDebian/RHELリポジトリで利用できません](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36048)
- [GitLab RunnerがShell executorでサブモジュールのフェッチに失敗することがあります](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26993)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-3-stable/CHANGELOG.md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.3)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.3)
- [UI改善](https://papercuts.gitlab.com/?milestone=16.3)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
