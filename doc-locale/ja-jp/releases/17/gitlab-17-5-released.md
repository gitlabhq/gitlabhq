---
stage: Release Notes
group: Monthly Release
date: 2024-10-17
title: "GitLab 17.5リリースノート"
description: "GitLab 17.5リリース: Duo Quick Chatの紹介"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024年10月17日、GitLab 17.5が以下の機能とともにリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Jim Ender {#this-months-notable-contributor-jim-ender}

誰もがGitLabコミュニティのコントリビューターを[推薦](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)できます！活躍中の候補者を支援するか、新しい推薦を追加してください！ 🙌

ジムはGitLabで[約100件のバックログのイシューをクローズ](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=updated_desc&state=closed&assignee_username%5B%5D=Jimender2&first_page_size=100)する取り組みを主導したことで評価されました。彼は、興味深いディスカッションに深く入り込む、毎週のコミュニティペアリングセッションの多くに積極的に参加しています。ジムは[GitLab Community Discord](https://discord.gg/gitlab)全体で人々をサポートし、GitLabのサポートリクエストのトラブルシューティングを行い、新しいコントリビューターを案内しています。ジムは、重要インフラおよびERPシステム向けのソフトウェアを作成する産業技術会社に勤務しています。

「小さなコントリビュートでも積み重なればプロジェクトはより良くなります」とジムは言います。「ドキュメントのコントリビュートのような小さなことでも、他の人々の助けになります。新しい機能全体を擁護する必要はありません。」

ジムはGitLabのフルスタックエンジニア、コントリビューターサクセスである[Lee Tickett](https://gitlab.com/leetickett-gitlab)によって推薦されました。「イシュートリアージ/キュレーションは、より広いコミュニティを巻き込むための私のリストの上位にあり、ジムがここで道を切り開いています」とLeeは言います。

GitLabのシニアプログラムマネージャー、コントリビューターサクセスである[Daniel Murphy](https://gitlab.com/daniel-murphy)も推薦に加わりました。「ジムによる新しいコントリビューターへの優れたサポートと、彼らをスタートさせるためのガイダンスは、コミュニティとして共同開発のGitLabを成長させるのに役立っています。」

「私がレビューした[マージリクエスト](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163849)での素晴らしい作業でした！」とGitLabのシニアフロントエンドエンジニア、[Vanessa Otto](https://gitlab.com/vanessaotto)は言います。「ジムは素早く反応し、提案を即座に理解し、シームレスに実装しました。ジムのアプローチにおけるそのような効率性と明瞭さを見ることができてよかったです。」

GitLabへのコントリビュートをしてくださるジムとすべてのオープンソースコミュニティに深く感謝いたします！

## 主要な機能 {#primary-features}

### Duo Quick Chatの導入 {#introducing-duo-quick-chat}

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo_chat/_index.md#in-an-editor-window) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15218)

{{< /details >}}

AIを活用したチャットであるDuo Quick Chatを導入します。codeでの作業場所に正確に合わせて設計されています。Duo Quick Chatは、codeから離れることなく、編集中の行で直接動作し、リアルタイムでアシスタンスを提供します。リファクタリング、バグ修正、またはテスト記述のいずれの場合でも、Duo Quick Chatはその場で提案と説明を提供し、コンテキストを切り替えることなく完全に集中し続けることができます。

### GitLab Code Suggestionsでセルフホストモデルを使用する {#use-self-hosted-model-for-gitlab-duo-code-suggestions}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/498114)

{{< /details >}}

大規模言語モデル（LLM）を選択して独自のインフラでホストし、それらのモデルをCode Suggestionsのソースとして構成できるようになりました。この機能はベータ版であり、UltimateとDuo Enterpriseのサブスクリプションで、Self-ManagedインスタンスのGitLab環境で利用できます。

セルフホストモデルを使用すると、オンプレミスまたはプライベートクラウドでホストされているモデルを使用してGitLab Duo Code Suggestionsを有効にできます。現在、vLLMまたはAWS Bedrock上のオープンソースMistralモデルをサポートしています。セルフホストモデルを有効にすることで、完全なデータ主権とプライバシーを維持しながら、生成AIの力を活用できます。

[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/498376)にフィードバックを残してください。

### Code Suggestionsの使用イベントをエクスポートする {#export-code-suggestion-usage-events}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../api/graphql/reference/_index.md#codesuggestionevent) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/477231)

{{< /details >}}

以前は、AIインパクト分析はGitLab.comでGitLab Duo Enterpriseの顧客にのみ利用可能であり、ClickHouse統合されたGitLabのセルフマネージドでは利用可能でした。さらに、デフォルトのメトリクスは集計されていました。

これで、GraphQL APIからraw Code Suggestionsのイベントをエクスポートできます。この方法では、データをデータ分析ツールにインポートして、提案サイズ、言語、ユーザーなど、より多くの側面で受容率に関するより深いインサイトを得ることができます。rawイベントはClickHouseに保存されないため、一部のAIインパクト分析のメトリクスは、GitLab Dedicatedやセルフマネージドを含むすべてのGitLab展開で利用可能になります。

### GitLab Duo Chatとマージリクエストについて会話する {#have-a-conversation-with-gitlab-duo-chat-about-your-merge-request}

<!-- categories: Duo Chat -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo_chat/examples.md#ask-about-a-specific-merge-request) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/464587)

{{< /details >}}

皆様のフィードバックに応えて、GitLab Duo Chatがマージリクエストに対応するようになりました。レビュアーでも作成者でも、チャットとマージリクエストについて会話して、すぐに深く掘り下げたり、次に何をすべきかを知ることができます。マージリクエストを開いてDuo Chatを開くだけで、会話を開始できます。

この新しい機能は、GitLab Duoに[変更されたcodeを要約](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-description-by-summarizing-code-changes)するようにリクエストすることで、マージリクエストの説明を素早く入力できる既存の機能を補完し、レビュアーがマージリクエストの概要を把握できるようにします。

### ブランチルール編集機能の強化 {#enhanced-branch-rules-editing-capabilities}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/repository/branches/branch_rules.md#create-a-branch-rule)

{{< /details >}}

GitLab 15.10では、ブランチ関連の設定とルールをまとめた[統合ビュー](https://about.gitlab.com/releases/2023/03/22/gitlab-15-10-released/#see-all-branch-related-settings-together)を導入しました。このビューにより、複数の設定にわたるプロジェクトの構成を簡単に理解できるようになりました。

この機能を基盤として、このビューで特定のブランチルールを直接変更できるようになりました。これには、ブランチ保護、承認ルール、および外部ステータスチェックの構成が含まれます。これらの新しい機能は、将来的にさらに大きな柔軟性を可能にするブランチ構成の[継続的な改善](https://gitlab.com/groups/gitlab-org/-/epics/12546)の基盤を築きます。

これらの新しい機能を探索し、フィードバックを提供することを奨励します。これは、専用の[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/486050)にコントリビュートすることで行うことができます。

### SwitchboardにおけるGitLab Dedicatedテナント概要 {#gitlab-dedicated-tenant-overview-in-switchboard}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/dedicated/tenant_overview.md)

{{< /details >}}

Switchboardの新しいテナント概要では、GitLab Dedicatedインスタンスに関する重要な情報に素早くアクセスできる単一の場所が提供されます。

この最初のリリースでは、現在のGitLabバージョン、インスタンスURL、および今後および過去のメンテナンス期間の日時をすべてテナント概要ページで表示できます。

### Secret Push ProtectionがGAになりました {#secret-push-protection-is-generally-available}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/secret_detection/secret_push_protection/_index.md)

{{< /details >}}

Secret Push ProtectionがすべてのGitLab Ultimateのお客様に一般提供されることを発表できることを嬉しく思います。

キーやAPIトークンのようなシークレットが誤ってGitリポジトリにコミットされた場合、そのリポジトリにアクセスできる誰もが、悪意のある目的のためにシークレットのユーザーを偽装できます。流出したシークレットは時間とコストがかかり、会社の評判を損なう可能性があります。Secret push protectionは、そもそもシークレットがプッシュされるのを防ぐことで、修正時間を短縮し、リスクを軽減するのに役立ちます。

Secret push protectionはベータリリース以降、改善されました。Git CLIを使用してコミットがプッシュされると、変更（差分）のみがシークレットについてスキャンされます。また、誤検出を回避するために、パス、ルール、または特定の値を除外する実験的なサポートも追加しました。

詳細については、[ブログ](https://about.gitlab.com/blog/prevent-secret-leaks-in-source-code-with-gitlab-secret-push-protection/)を参照してください。

### GitLab.comで利用可能な認証情報インベントリ {#credentials-inventory-available-on-gitlabcom}

<!-- categories: System Access -->

{{< details >}}

- プラン: Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/credentials_inventory.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/297441)

{{< /details >}}

認証情報インベントリは、GitLab.comのトップレベルグループのオーナーが利用できるようになりました。認証情報インベントリでは、グループ全体の[エンタープライズユーザー](../../user/enterprise_user/_index.md)のパーソナルアクセストークンとSSHキーを表示できます。また、認証情報に関する追加情報を失効、削除、および表示することもできます。以前は、これはGitLabのセルフマネージドの管理者のみが利用できました。

グループオーナーは、認証情報インベントリを使用して、彼らの管轄下に存在する認証情報を理解し、表示レベルと制御を向上させることができます。

### 依存関係リスト上のコンポーネントフィルター {#component-filter-on-the-dependency-list}

<!-- categories: Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_list/_index.md#filter-dependency-list) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/12652)

{{< /details >}}

これで、GitLabでは、特定の依存コンポーネントを素早くフィルターして、それらがグループまたはプロジェクトで使用されているかどうかを識別できます。特定のパッケージとバージョンが存在するかどうかを確認するためだけに、リスト全体を手動で確認するのは時間がかかり、不便です。依存関係リストの新しい**filter by component**を使用すると、脆弱な依存関係を分離して、アプリケーションのオープンなリスクを評価できます。

## 規模とデプロイ {#scale-and-deployments}

### GitLabチャートの改善 {#gitlab-chart-improvements}

<!-- categories: Cloud Native Installation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/charts/)

{{< /details >}}

GitLab 17.5には、NGINX Ingressコントローラーのバージョンの更新が含まれています。`nginx-controller`コンテナイメージは現在バージョン1.11.2です。新しいコントローラーがエンドポイントスライスを使用し、それらにアクセスするためのRBACルールを必要とするため、これには新しいRBAC要件が含まれることに注意してください。

### Omnibusの改善 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 17.5には、単一ノードインストールの場合にPostgreSQLをバージョン14.xから16.xにアップグレードするためのサポートが含まれています。自動アップグレードは有効になっていないため、PostgreSQLのアップグレードは手動でトリガーする必要があります。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### コーディングを向上させる: Windows用Visual StudioでDuo Chatが利用可能に {#elevate-your-coding-duo-chat-now-in-visual-studio-for-windows}

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo_chat/_index.md#use-gitlab-duo-chat-in-visual-studio-for-windows) | [関連エピック](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/77)

{{< /details >}}

Windows用Visual Studioにシームレスに統合されたDuo Chatで、開発ワークフローを強化します。Duo Chatは、AIを活用した機能を提供することで、codeの説明、改善、デバッグ、またはリアルタイムでのテスト記述を可能にし、コーディング体験を向上させます。このインテグレーションにより、Duo Chatの高度なAIツールを慣れ親しんだ開発環境内で直接活用でき、生産性を向上させ、より高速で効率的な問題解決を可能にします。

### REST APIを使用してエージェントおよびGitOps環境設定を構成する {#configure-agent-and-gitops-environment-settings-with-the-rest-api}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/environments.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/412677)

{{< /details >}}

GitLab環境のUIからポッドとFlux調整のステータスを確認できます。しかし、このアプローチはGraphQLまたはUIを介してのみ必要な設定が公開されるため、スケールが困難です。現在、GitLabはKubernetes用のエージェントを構成するためのREST APIサポート、および環境ごとのネームスペースとFluxリソースを設定するためのサポートを提供しています。動的環境のサポートをさらに改善するために、[イシュー467912](https://gitlab.com/gitlab-org/gitlab/-/issues/467912)では、CI/CDパイプラインでこれらの設定を構成するためのサポートを追加することを提案しています。

### GitLab Kubernetes統合の簡単なブートストラップ {#easy-bootstrapping-of-gitlab-kubernetes-integration}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/clusters/agent/install/_index.md#bootstrap-the-agent-with-flux-support-recommended) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/473987)

{{< /details >}}

GitLabは、[Kubernetes用のエージェント](../../user/clusters/agent/_index.md)とその[Flux統合](../../user/clusters/agent/gitops.md)により、柔軟で信頼性が高く、安全なGitOpsサポートを提供しています。しかし、GitLabでFluxをブートストラップし、Kubernetes用のエージェントを設定するには、多くのドキュメントを読み、GitLab UIとターミナルを切り替える必要がありました。GitLab CLIは現在、既存のFluxインストールの上にエージェントをインストールするのを簡素化するために、[`glab cluster agent bootstrap`コマンド](https://gitlab.com/gitlab-org/cli/-/blob/main/docs/source/cluster/agent/bootstrap.md)を提供しています。これで、わずか2つの簡単なコマンドでFluxとエージェントを構成できます。

### ファイアウォールで保護されたGitLabインストールに対するKubernetes統合サポート {#kubernetes-integration-support-for-firewalled-gitlab-installations}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/clusters/agent/_index.md#receptive-agents) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/437014)

{{< /details >}}

これまでは、Kubernetes用のエージェントは、KubernetesクラスターがGitLabインスタンスに接続できる場合にのみ使用できました。このイシューは、例えばGitLabをプライベートネットワークまたはファイアウォールの背後で実行している場合、一部の顧客がエージェントを使用できないことを意味していました。GitLab 17.5からは、適切に構成された`agentk`インスタンスが既に接続の初期化を待機していると仮定して、GitLabからクラスター-GitLab接続を開始できます。

初期接続が確立されると、エージェントのすべての機能が利用可能になります。クラスターからの初期化は、この開発によって変更されません。

### Kubernetesリソースイベントのストリーム {#stream-kubernetes-resource-events}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/kubernetes_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/470042)

{{< /details >}}

GitLabは、ポッドのリアルタイムビューと、Kubernetes用のダッシュボードを介したポッドログのストリーミングを提供します。GitLab 17.4では、UIからリソースイベント固有の情報を静的に表示していました。このリリースでは、Kubernetes用のダッシュボードがさらに改善され、クラスターで発生する受信イベントをストリームできるようになりました。

### GitLab UIからGitOps調整を一時停止または再開する {#suspend-or-resume-gitops-reconciliation-from-the-gitlab-ui}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/kubernetes_dashboard.md#suspend-or-resume-flux-reconciliation) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/478380)

{{< /details >}}

Fluxユーザーとして、自動調整またはドリフト修正をすぐに停止する必要があったことはありますか？手動で削除されたリソースを同期するために`HelmRelease`をトリガーしたいと思ったことはありますか？これらのアクションは、Fluxの一時停止機能と再開機能で最もよく達成されます。これまでは、最も良いオプションはFlux CLIを使用することでしたが、これはコンテキスト切り替えと、適切なリソースが影響を受けることを保証するためのいくつかのコマンドを必要としました。GitLab 17.5では、Kubernetes用の組み込みダッシュボードから調整を一時停止または再開できます。

### ユーザー管理概要の改善 {#improved-user-management-summary}

<!-- categories: User Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/profile/account/create_accounts.md#create-a-user-in-the-admin-area) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/456332)

{{< /details >}}

管理者は、インスタンス上のユーザーに関する次の重要な情報の、強化された概要ビューを持つようになりました:

- 保留中の承認。
- 2要素認証なし。
- 管理者。

これにより、管理者は概要ビューからこれらの状態にあるユーザーの数を素早く確認し、それらをフィルターできるため、ユーザー管理の効率性が向上します。

### セキュリティポリシーのスコープにグループを追加する {#add-groups-to-security-policy-scope}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14149)

{{< /details >}}

これで、セキュリティポリシースコープでグループ/サブグループをターゲットにできます。これにより、グループ/サブグループ内のすべてのプロジェクト、定義されたプロジェクトリストに基づくプロジェクト、およびコンプライアンスフレームワークラベルのリストに一致するプロジェクトをターゲットにできる既存のオプションが拡張されます。

これにより、グループ全体でポリシーを有効にする柔軟性がさらに高まり、必要に応じてプロジェクトを強制のスコープから除外する例外を適用することもできます。

この改善は、セキュリティポリシープロジェクトのリンクプロセスと、ポリシーの適用範囲をきめ細かく設定するプロセスを簡素化する、いくつかの[機能強化](https://gitlab.com/groups/gitlab-org/-/epics/5446)に先行するものです。

### Enterpriseユーザーのパスワード認証を無効にする {#disable-password-authentication-for-enterprise-users}

<!-- categories: User Management -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/saml_sso/_index.md#disable-password-and-passkey-authentication-for-enterprise-users) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/373718)

{{< /details >}}

エンタープライズユーザーは、ユーザー名とパスワードを使用してローカルアカウントで認証することができます。これで、グループオーナーは、グループのエンタープライズユーザーのパスワード認証を無効にできます。パスワード認証が無効になっている場合、エンタープライズユーザーは、グループのSAMLアイデンティティプロバイダーを使用してGitLabウェブUIで認証するか、パーソナルアクセストークンを使用してHTTP Basic認証でGitLab APIとGitで認証することができます。

### プロジェクトでコンプライアンスセンターにアクセスする {#access-compliance-center-on-projects}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_center/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/441350)

{{< /details >}}

以前は、コンプライアンスセンターはトップレベルグループとサブグループのみが利用できました。

このリリースにより、コンプライアンスセンターがプロジェクトに追加されました。このレベルでは、コンプライアンスセンターは、特定のプロジェクトに関連するチェックと違反に対して表示専用の機能を提供します。

フレームワークを追加または編集するには、代わりにトップレベルグループのコンプライアンスセンターにアクセスする必要があります。

### コンプライアンスパイプラインからセキュリティポリシーへの移行プロセス {#migration-process-for-compliance-pipelines-to-security-policies}

<!-- categories: Compliance Management, Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_pipelines.md#pipeline-execution-policies-migration) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/11275)

{{< /details >}}

GitLab 17.3では、コンプライアンスパイプラインの廃止と、18.0リリースによる最終的な削除を発表しました。コンプライアンスパイプラインの代わりに、GitLab 17.2でリリースされたパイプライン実行ポリシータイプを使用する必要があります。

このリリースには、既存のコンプライアンスパイプラインをパイプライン実行ポリシータイプに移行するためのワークフローとガイド付きの警告バナーが含まれています:

- ユーザーにコンプライアンスパイプラインの廃止を通知します。
- 既存のコンプライアンスパイプラインをパイプライン実行ポリシータイプに移行するための、促されガイド付きのワークフローを提供します。

### APIを使用したトークン関連付けの表示 {#view-token-associations-using-api}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/personal_access_tokens.md#list-all-token-associations) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/466046)

{{< /details >}}

これで、トークンが関連付けられているグループ、サブグループ、およびプロジェクトを表示できます。これにより、トークンの有効期限または失効の影響を特定し、トークンがどこで使用できるかを理解しやすくなります。

### 選択的なSAMLシングルサインオン強制 {#selective-saml-single-sign-on-enforcement}

<!-- categories: User Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/settings/sign_in_restrictions.md#disable-password-and-passkey-authentication-for-users-with-an-sso-identity) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/382917)

{{< /details >}}

以前は、SAML SSOが有効になっている場合、グループはSSOを強制することを選択でき、これによりすべてのメンバーがグループにアクセスするためにSSO認証を使用する必要がありました。しかし、一部のグループは、従業員やグループメンバーに対してSSO強制のセキュリティを望む一方で、外部の協力者や請負業者がSSOなしでグループにアクセスすることを許可したいと考えています。

現在、SAML SSOが有効なグループでは、SAML IDを持つすべてのメンバーに対してSSOが自動的に強制されます。SAML IDを持たないグループメンバーは、SSO強制が明示的に有効になっていない限り、SSOを使用する必要はありません。

メンバーがSAML IDを持っているのは、次のいずれかまたは両方が真の場合です:

- 彼らは、グループのシングルサインオンURLを使用してGitLabにサインインしました。
- SCIMによってプロビジョニングされた。

選択的なSSO強制機能のスムーズな運用を確実にするために、**このグループのSAML認証を有効にします**チェックボックスを選択する前に、SAML構成が正しく機能していることを確認してください。

### コンテナレジストリタグでの作業時のAPIパフォーマンスの向上 {#enhance-api-performance-when-working-with-container-registry-tags}

<!-- categories: Container Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../api/container_registry.md#list-all-registry-repository-tags) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/482399)

{{< /details >}}

セルフマネージドGitLabインスタンス向けのコンテナレジストリAPIの大幅な改善を発表できることを嬉しく思います。GitLab 17.5のリリースにより、GitLab.comで既に利用可能な機能と一致するように、`:id/registry/repositories/:repository_id/tags`エンドポイントにキーセットページネーションを実装しました。この強化は、APIパフォーマンスを向上させ、すべてのGitLab展開で一貫したエクスペリエンスを提供するための継続的な取り組みの一部です。

キーセットページネーションは、大規模なデータセットを処理するためのより効率的な方法を提供し、パフォーマンスの向上とより良いユーザーエクスペリエンスをもたらします。この更新は、大規模なコンテナレジストリを管理する際に特に役立ち、リポジトリタグのスムーズなナビゲーションを可能にします。この機能を使用するには、セルフマネージドインスタンスを[次世代コンテナレジストリ](../../administration/packages/container_registry_metadata_database.md)にアップグレードする必要があります。

### パッケージ保護されたパッケージで依存関係を保護する {#safeguard-your-dependencies-with-protected-packages}

<!-- categories: Container Registry -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/packages/package_registry/package_protection_rules.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/472655)

{{< /details >}}

保護されたnpmパッケージのサポートを導入できることを嬉しく思います。これは、GitLabパッケージレジストリのセキュリティと安定性を高めるために設計された新しい機能です。ペースの速いソフトウェア開発の世界では、パッケージの偶発的な変更または削除が、開発プロセス全体を混乱させる可能性があります。保護されたパッケージは、意図しない変更から最も重要な依存関係を保護できるようにすることで、この問題に対処します。

GitLab 17.5から、保護ルールを作成することでnpmパッケージを保護できます。パッケージが保護ルールに一致する場合、指定されたユーザーのみがパッケージを更新または削除できます。この機能により、偶発的な変更を防止し、規制要件へのコンプライアンスを改善し、手動での監視の必要性を減らすことでワークフローを合理化できます。

### Advanced SASTのRubyサポートとルールの更新 {#ruby-support-and-rule-updates-for-advanced-sast}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/sast/gitlab_advanced_sast.md)

{{< /details >}}

GitLab Advanced SASTにRubyサポートを追加しました。この新しいクロスファイル、クロスファンクションスキャンサポートを使用するには、[Advanced SASTを有効](../../user/application_security/sast/gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast)にしてください。すでにAdvanced SASTを有効にしている場合、Rubyサポートは自動的にアクティブ化されます。

先月、Advanced SASTがサポートする[他の言語](../../user/application_security/sast/gitlab_advanced_sast.md#supported-languages)の検出ルールを改善するための更新もリリースしました:

- 追加のJavaパストラバーサル、Javaコマンドインジェクション、およびJavaScriptパストラバーサル脆弱性の検出。
- 脆弱性タイプをより具体的に一貫して識別するためにCWEマッピングを更新する。
- パストラバーサル脆弱性の重大度を高める。

Advanced SASTが各言語でどの種類の脆弱性を検出するかについては、新しい[Advanced SASTカバレッジページ](../../user/application_security/sast/advanced_sast_coverage.md)を参照してください。

Advanced SASTの詳細については、[先月の発表ブログ](https://about.gitlab.com/blog/gitlab-advanced-sast-is-now-generally-available/)を参照してください。

### GitLab Runner 17.5 {#gitlab-runner-175}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 17.5もリリースしました！GitLab Runnerは、CI/CDジョブを実行し、その結果をGitLabインスタンスに送信する、拡張性の高いビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [スコープ付き一時認証情報によるAWS S3マルチパートアップロードのサポート](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/26921)

#### バグ修正 {#bug-fixes}

- [追加サービスを伴うジョブが、サービスコンテナの1つが実行されていない場合に完了しない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38035)
- [`gitlab-runner-fips-17.4.0-1`パッケージがAmazon Linux 2で実行に失敗し、glibcエラーを返す](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38034)
- [S3 Express One Zoneエンドポイントを使用する場合、Amazon S3でキャッシュが機能しない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37394)
- [`DOCKER_AUTH_CONFIG`変数に複数のレジストリがある場合、ジョブがベースイメージをプルできない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28073)

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.5)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.5)
- [UI改善](https://papercuts.gitlab.com/?milestone=17.5)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
