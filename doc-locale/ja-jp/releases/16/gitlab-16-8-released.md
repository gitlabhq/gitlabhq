---
stage: Release Notes
group: Monthly Release
date: 2024-01-18
title: "GitLab 16.8リリースノート"
description: "マージリクエストの変更ビューにおける静的な解析の検出を伴うGitLab 16.8のリリース"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024年1月18日、GitLab 16.8が以下の機能を備えてリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター {#this-months-notable-contributor}

テッドは、ヘルパーファイルから古い未使用の[コード](https://gitlab.com/gitlab-org/gitlab/-/issues/420057)を削除し、他のメンテナンスタスクに対処するなど、重要なコントリビュートを行いました。彼はGitLabのスタッフエンジニアである[Kerri Miller](https://gitlab.com/kerrizor)によって指名され、「常に華やかな仕事ではないが、重要な仕事だ」と述べました。

Tedはオレンジ郡を拠点とするフリーランスのソフトウェアエンジニアで、熱心なクライマーであり、猫愛好家です。

マーティンはGitLabのプロダクトマネージャーである[Viktor Nagy](https://gitlab.com/nagyv-gitlab)によって指名され、「彼はAuto Deployジョブテンプレートに多くの不足しているテストを追加し、[agentk Helm chartドキュメント](../../user/clusters/agent/install/_index.md#customize-the-helm-installation)を改善した」と述べました。

GitLabのエンジニアである[Lee Tickett](https://gitlab.com/leetickett-gitlab)は、「[Discord](https://discord.gg/gitlab)でのコミュニティペアリングセッションに参加し、チームメンバーと緊密に連携して、merge requestに対する非常に要望の多かった[検索機能の強化](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140002)にコントリビュートする」と付け加えました。

Martinはドイツのドレスデンを拠点とするDeutsche Telekom MMS GmbHのITアーキテクトです。

ヘリオはGitLabのプリンシパルプロダクトマネージャーである[Hannah Sutor](https://gitlab.com/hsutor)によって指名され、「彼は[パスキーを使用してサインインする機能](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135324)を提案することで、チーム全体を前進させた」と述べました。HelioのMRはクローズされましたが、彼のコントリビュートは深く、示唆に富んでおり、彼の質問とオープンなディスカッションが当社のパスワードレス実装をより良いものにするでしょう。

HelioはRubyとOSSに情熱を持つソフトウェアエンジニアです。

Ted、Martin、Helioに感謝します！🙌

## 主要な機能 {#primary-features}

### Static Analysisの検出結果をMerge requestの変更ビューで表示 {#static-analysis-findings-in-merge-request-changes-view}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/sast/_index.md#merge-request-changes-view) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10959)

{{< /details >}}

静的な解析は、マージリクエスト変更ビューでの検出の表示をサポートするようになりました。他の場所に移動する必要はありません。すべてが一箇所に統合されています。UIは、よりわかりやすい操作のために洗練されています。詳細については、ドロワーを開いてください。リンクされたドキュメント、デモビデオ、およびロールアウトイシューから詳細をご覧ください。

### Google Cloud Secret Managerのサポート {#google-cloud-secret-manager-support}

<!-- categories: Secrets Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/secrets/gcp_secret_manager.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11739)

{{< /details >}}

Google Cloud Secret Managerに保存されたシークレットは、CI/CDジョブで簡単に取得して使用できるようになりました。新しいインテグレーションにより、GitLab CI/CDを通じてGoogle Cloud Secret Managerとやり取りするプロセスが簡素化され、ビルドおよびデプロイプロセスを効率化できます。これは、[GitLabとGoogle Cloudがより良い連携](https://about.gitlab.com/blog/gitlab-google-partnership-s3c/)を実現する数多くの方法の1つに過ぎません！

### Workspacesが一般提供を開始しました {#workspaces-are-now-generally-available}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/workspace/_index.md)

{{< /details >}}

ワークスペースが一般提供を開始し、デベロッパーエクスペリエンスを向上させる準備が整ったことをお知らせできることを嬉しく思います！

安全なオンデマンドリモート開発環境を作成することで、依存関係の管理や新しい開発者のオンボーディングにかかる時間を削減し、より迅速な価値提供に集中できます。プラットフォーム依存しないアプローチにより、既存のクラウドインフラストラクチャを使用してワークスペースをホストし、データをプライベートかつ安全に保つことができます。

GitLab 16.0での導入以来、ワークスペースはエラー処理と調整の改善、プライベートプロジェクトとSSH接続のサポート、追加の設定オプション、および新しい管理者インターフェースを受けました。これらの改善により、ワークスペースはより柔軟で、より回復力があり、より大規模に管理しやすくなりました。

### GitLabの管理者に対する2要素認証の適用 {#enforce-2fa-for-gitlab-administrators}

<!-- categories: User Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../security/two_factor_authentication.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/427549)

{{< /details >}}

GitLab管理者がSelf-Managedインスタンスで2要素認証（2FA）の使用を必須とすべきかどうかを強制できるようになりました。すべてのアカウント、特に管理者のような特権アカウントで2FAを使用することは、優れたセキュリティ対策です。この設定が強制され、管理者がまだ2FAを使用していない場合は、次回のサインイン時に2FAをセットアップする必要があります。

### Maven dependency proxyでビルドを高速化 {#speed-up-your-builds-with-the-maven-dependency-proxy}

<!-- categories: Dependency Proxy, Package Registry -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../user/packages/package_registry/dependency_proxy/_index.md)

{{< /details >}}

一般的なソフトウェアプロジェクトは、さまざまな依存関係（当社ではパッケージと呼んでいます）に依存しています。パッケージは内部でビルドおよび保守されるか、または公開リポジトリから取得されます。ユーザー調査に基づいて、ほとんどのプロジェクトが公開パッケージとプライベートパッケージを50/50の割合で使用していることがわかりました。パッケージのインストール順序は非常に重要です。なぜなら、誤ったパッケージのバージョンを使用すると、破壊的な変更やセキュリティ脆弱性がパイプラインに導入される可能性があるからです。

これで、外部のJavaリポジトリをGitLabプロジェクトに追加できるようになりました。追加後、依存プロキシを使用してパッケージをインストールすると、GitLabは最初にプロジェクト内でパッケージをチェックします。見つからない場合、GitLabは外部リポジトリからパッケージをプルしようとします。

外部リポジトリからパッケージがプルされると、そのパッケージはGitLabプロジェクトにインポートされます。その特定のパッケージが次回プルされるときは、外部リポジトリからではなくGitLabからプルされます。外部リポジトリに接続の問題があり、パッケージが依存プロキシ内に存在する場合でも、プルすることでパッケージは機能し、パイプラインをより速く、より信頼性の高いものにします。

外部リポジトリでパッケージが変更された場合（たとえば、ユーザーがバージョンを削除し、異なるファイルで新しいものを公開した場合）、依存プロキシはそれを検出します。パッケージを無効にし、GitLabが新しいパッケージをプルするようにします。これにより、正しいパッケージがダウンロードされ、セキュリティ脆弱性の削減に役立ちます。

### イシュー分析レポートにおけるベロシティに関するより深いインサイト {#deeper-insights-into-velocity-in-the-issue-analytics-report}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/issues_analytics/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/233905)

{{< /details >}}

**イシュー分析**レポートに、月間のクローズされたイシューの数に関する情報が含まれるようになり、詳細なベロシティ分析が可能になりました。この貴重な追加により、GitLabユーザーはプロジェクトに関連するトレンドに関するインサイトを得て、全体的な所要時間と顧客に提供される価値を向上させることができます。**イシュー分析**の可視化には、各月ごとのイシュー数を示すbar chartが含まれており、デフォルトの期間は13ヶ月です。このチャートは、[Value Streamsダッシュボード](../../user/analytics/value_streams_dashboard.md#dashboard-metrics-and-drill-down-reports)のドリルダウンからアクセスできます。

### DORAに基づく業界ベンチマークを備えた新しい組織レベルのDevOpsビュー {#new-organization-level-devops-view-with-dora-based-industry-benchmarks}

<!-- categories: Value Stream Management, DORA Metrics -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/analytics/value_streams_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/426516)

{{< /details >}}

組織のDevOpsパフォーマンスのステータスをさまざまなプロジェクトで可視化するために、[Value Streamsダッシュボード](https://www.youtube.com/watch?v=EA9Sbks27g4)に新しい**DORA Performers score**パネルを追加しました。この新しい視覚化は、DORAスコア（高、中、低）の内訳を表示し、幹部が組織のDevOpsの健全性を上から下まで理解できるようにします。

GitLabには[4つのDORA metrics](https://about.gitlab.com/solutions/value-stream-management/dora/#overview)が標準で提供されており、新しいDORAスコアを使用すると、組織は[業界のベンチマーク](https://dora.dev/)や競合他社とDevOpsパフォーマンスを比較できます。このベンチマークは、幹部が他者との関係でどこに位置しているかを理解し、ベストプラクティスやラグっている可能性のある領域を特定するのに役立ちます。

Value Streams Dashboardの改善にご協力いただくため、この[アンケート](https://gitlab.fra1.qualtrics.com/jfe/form/SV_50guMGNU2HhLeT4)でご意見をフィードバックしてください。

## 規模とデプロイ {#scale-and-deployments}

### Omnibusの改善 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 16.8より、plaintextパスワードが公開されないように、`gitlab.rb`ファイルで以下のサービスに対する設定を生成するコマンドを指定できるようになりました:

- Kubernetes向けGitLabエージェントサーバー
- GitLab Workhorse
- GitLab Exporter

これにより、Redisのplaintextパスワードを`gitlab.rb`に保存する必要がなくなります。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### `patch-id`サポートによる、よりスマートな承認のリセット {#smarter-approval-resets-with-patch-id-support}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/project/merge_requests/approvals/settings.md#remove-all-approvals-when-commits-are-added-to-the-source-branch)

{{< /details >}}

すべての変更がレビューおよび承認されることを確実にするために、新しいコミットがマージリクエストに追加されたときにすべての承認を削除するのが一般的です。しかし、リベースもまた、リベースが新しい変更を導入しなかったとしても、既存の承認を不必要に無効にし、作成者が再承認を求める必要がありました。

Merge requestの承認が[`git-patch-id`](https://git-scm.com/docs/git-patch-id)に準拠するようになりました。これは、承認のリセットに関するより賢い決定を可能にする、かなり安定しており、かなりユニークな識別子です。リベース前後の`patch-id`を比較することで、承認をリセットし、レビューを必要とする新しい変更が導入されたかどうかを判断できます。

リセットに関する現在の体験についてフィードバックがある場合は、[イシュー #435870](https://gitlab.com/gitlab-org/gitlab/-/issues/435870)でお知らせください。

### ファイルページで直接blame情報を表示 {#view-blame-information-directly-in-the-file-page}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/project/repository/files/git_blame.md#view-blame-for-a-file)

{{< /details >}}

以前のGitLabバージョンでは、ファイルのblameを表示するには別のページにアクセスする必要がありました。現在、ファイルページから直接ファイルのblame情報を表示できます。

### ワークスペースごとのCPUとメモリ使用量を設定 {#set-cpu-and-memory-usage-per-workspace}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../user/workspace/gitlab_agent_configuration.md)

{{< /details >}}

向上したデベロッパーエクスペリエンス、オンボーディング、およびセキュリティは、クラウドIDEとオンデマンド開発環境へのさらなる開発を推進しています。ただし、これらの環境はインフラストラクチャコストの増加にコントリビュートする可能性があります。各プロジェクトのCPUおよびメモリ使用量は、[devfile](../../user/workspace/_index.md#devfile)で既に設定できます。

現在、ワークスペースごとにCPUとメモリ使用量を設定することもできます。GitLabエージェントレベルでリクエストと制限を設定することで、個々の開発者が過剰な量のクラウドリソースを使用することを防ぐことができます。

### Kubernetes 1.28のサポート {#kubernetes-128-support}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/clusters/agent/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/432070)

{{< /details >}}

このリリースでは、2023年8月にリリースされたKubernetesバージョン1.28のフルサポートが追加されました。アプリをKubernetesにデプロイする場合、接続されているクラスターを最新のバージョンにアップグレードし、すべての機能を活用できるようになりました。

当社のKubernetesサポートポリシーおよびその他のサポートされているKubernetesバージョンについては、こちらをご覧ください。

### 新しいカスタマイズ可能なパーミッション {#new-customizable-permissions}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/custom_roles/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/391760)

{{< /details >}}

カスタムロールを作成するために使用できる5つの新しい機能があります:

- プロジェクトアクセストークンを管理します。
- グループアクセストークンを管理します。
- グループメンバーを管理します。
- プロジェクトをアーカイブする機能。
- プロジェクトを削除する機能。

これらの機能を、他の既存のカスタム機能とともに、任意のベースロールに追加してカスタムロールを作成します。カスタムロールを使用すると、ユーザーがジョブを行うために必要な機能のみを付与するきめ細かなロールを定義し、不要な特権昇格を減らすことができます。

### SAML SSOによるカスタムロールの割り当て {#assign-a-custom-role-with-saml-sso}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/saml_sso/_index.md#configure-gitlab) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/417285)

{{< /details >}}

ユーザーは、SAML SSOでプロビジョニングされたときに作成されるデフォルトロールとして、カスタムロールを割り当てることができます。以前は、デフォルトとして選択できるのは静的ロールのみでした。これにより、自動的にプロビジョニングされたユーザーに、最小特権の原則に最も合致するロールを割り当てることができます。

### グループレベルでのサブグループ/プロジェクトによる監査イベントストリーミングのフィルタリング {#filter-streaming-audit-events-by-sub-groupproject-at-group-level}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/compliance/audit_event_reports.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11384)

{{< /details >}}

監査イベントストリーミングは、既存のイベントタイプフィルタリングのサポートに加えて、サブグループまたはプロジェクトによるグループレベルでのフィルタリングをサポートするように拡張されました。

この追加のフィルターを使用すると、ストリーム内のイベントを異なるストリーミング先に送信したり、関連性のないサブグループ/プロジェクトを除外したりして、チームが監視するために最も実用的なイベントを確実に取得できます。

### コンプライアンスフレームワーク管理の改善 {#compliance-framework-management-improvements}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_frameworks/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11240)

{{< /details >}}

当社のコンプライアンスセンターは、コンプライアンスの状態を理解し、コンプライアンスフレームワークを管理するための中心的なストリーミング先になりつつあります。コンプライアンスセンターの新しいタブにフレームワーク管理を移動し、さらにエキサイティングな機能を追加しています:

- **フレームワーク**タブで、リストビューでフレームワークを表示します。
- 特定のフレームワークを検索してフィルターします。
- 新しいコンプライアンスフレームワークサイドバーを使用して、各フレームワークの詳細を探索します。
- フレームワークを編集して、名前、説明、リンクされたプロジェクトの管理など、すべての設定を表示します。
- エクスポートをCSV形式で行うことで、フレームワークのクイックレポートを作成できます。

### インスタンスレベルでの監査イベントストリーミングをAWS S3へ {#instance-level-audit-event-streaming-to-aws-s3}

<!-- categories: Audit Events -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/compliance/audit_event_reports.md)

{{< /details >}}

以前は、AWS S3のトップレベルグループの監査イベントストリーミングのみを設定できました。

GitLab 16.8では、AWS S3のサポートをインスタンスレベルのストリーミング先に拡張しました。

### ブランチの削除または保護解除を防ぐポリシーの強制 {#enforce-policy-to-prevent-branches-being-deleted-or-unprotected}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9705)

{{< /details >}}

scan result policiesに追加された複数の新しい設定の1つである、[セキュリティポリシーのコンプライアンス適用](https://gitlab.com/groups/gitlab-org/-/epics/9704)を支援するブランチ変更コントロールは、プロジェクトレベルの設定を変更することによるポリシーの回避能力を制限します。

既存または新規のscan result policyごとに、`Prevent branch modification`を有効にすることで、ポリシー内で定義されたブランチに適用され、ユーザーがそれらのブランチを削除したり保護解除したりするのを防ぐことができます。

### カスタムロールのSAMLグループ同期 {#saml-group-sync-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/saml_sso/group_sync.md#configure-saml-group-links) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/417201)

{{< /details >}}

SAMLグループ同期を使用してカスタムロールをユーザーグループにマップできるようになりました。以前は、SAMLグループをGitLabの静的ロールにのみマップできました。これにより、SAMLグループリンクを使用してグループメンバーシップとメンバーロールを管理している顧客に、より多くの柔軟性が提供されます。

### merge request承認のためのSAML SSO認証 {#saml-sso-authentication-for-merge-request-approval}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/merge_requests/approvals/settings.md#require-user-re-authentication-to-approve) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11084)

{{< /details >}}

GitLabでユーザーアカウント管理にSAML SSOとSCIMを使用しているユーザーは、マージリクエストの承認のために、パスワードベースの認証ではなくSSOを使用してマージリクエストの認証要件を満たすことができるようになりました。

この方法により、認証済みユーザーのみがセキュリティとコンプライアンスのためにマージリクエストを承認することが保証され、個別のパスワードベースのソリューションを使用する必要がなくなります。

### Analyticsダッシュボードのグループレベルランディングページの導入 {#introduce-group-level-landing-page-for-analytics-dashboards}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/analytics/value_streams_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/433420)

{{< /details >}}

グループレベルの分析ダッシュボードの新しいランディングページを導入しています。この機能強化により、より一貫性があり、ユーザーフレンドリーなナビゲーションエクスペリエンスが保証されます。最初のフェーズでは、このページには[Value Streamsダッシュボード](https://www.youtube.com/watch?v=8pLEucNUlWI)が含まれていますが、将来の機能の基礎も築かれており、ダッシュボードをパーソナライズすることができます。これらの改善は、エクスペリエンスを合理化し、データを管理および解釈する上での柔軟性を高めることを目的としています。

### タスクまたはOKRのすべての祖先アイテムを表示 {#view-all-ancestor-items-of-a-task-or-okr}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/tasks.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11197)

{{< /details >}}

このリリースにより、直近の親だけでなく、作業アイテムの階層全体の系統を表示できるようになりました。

作業アイテムには次のものが含まれます:

- すべてのティアのタスク。
- [目標と主な成果。Ultimate層で、かつ機能フラグの背後にあります。](../../user/okrs.md)

### Runnerフリートダッシュボード: インスタンスRunnerが使用したコンピューティング時間のCSVエクスポート {#runner-fleet-dashboard-csv-export-of-compute-minutes-used-by-instance-runners}

<!-- categories: Fleet Visibility -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../ci/runners/runner_fleet_dashboard.md#export-compute-minutes-used-by-instance-runners) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/425853)

{{< /details >}}

さまざまな理由で、インスタンスRunnerでプロジェクトが使用するCI/CDコンピューティング時間のレポートを実行する必要がある場合があります。しかし、GitLabには、CI/CDコンピューティング時間の使用状況レポートを生成するための使いやすいメカニズムがありませんでした。この機能により、共有Runnerで各プロジェクトが使用するCI/CDコンピューティング時間のレポートをCSVファイルとしてエクスポートできます。

### GitLab Runner 16.8 {#gitlab-runner-168}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 16.8もリリースしました！GitLab Runnerは、CI/CDジョブを実行し、結果をGitLabインスタンスに送信する、軽量で拡張性の高いエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [生成されたKubernetesポッド仕様の上書き - ベータ](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29659)

#### バグ修正 {#bug-fixes}

- [GitLab Runner認証トークンがRunnerのログファイルに公開される](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37224)
- [複数のオートスケールRunnerの登録により、部分的なconfig.tomlファイルが生成される](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37197)
- [restore_cacheヘルパータスクの中断により、キャッシュが破損する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36988)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-8-stable/CHANGELOG.md)にあります。

### Merge requestの説明に対する定義済み変数 {#predefined-variables-for-merge-request-description}

<!-- categories: Secrets Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/432846)

{{< /details >}}

CI/CDパイプラインでマージリクエストを操作するために自動化を使用している場合、APIコールなしでマージリクエストの説明をフェッチする簡単な方法が必要だったかもしれません。GitLab 16.7では、`CI_MERGE_REQUEST_DESCRIPTION`定義済み変数を導入し、すべてのジョブで説明に簡単にアクセスできるようにしました。GitLab 16.8では、非常に大きな説明がRunnerエラーを引き起こす可能性があるため、`CI_MERGE_REQUEST_DESCRIPTION`を2700文字で微調整して、切り詰めるように動作を変更しました。説明が切り詰められたかどうかは、新しく導入された`CI_MERGE_REQUEST_DESCRIPTION_IS_TRUNCATED`定義済み変数で確認できます。この変数は、説明が切り詰められた場合に`true`に設定されます。

### Windows上のSaaSRunnerに対するWindows 2022のサポート {#windows-2022-support-for-saas-runners-on-windows}

<!-- categories: GitLab Runner SaaS -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/hosted_runners/windows.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/438554)

{{< /details >}}

チームはWindows Server 2022でアプリケーションをビルド、テスト、デプロイできるようになりました。

Windows上のSaaS Runnerを使用すると、安全なオンデマンドのGitLab Runnerビルド環境でWindowsを必要とするアプリケーションをビルドするおよびデプロイするための開発チームの開発速度を、GitLab CI/CDと統合して向上させることができます。

.GitLab-ci.ymlファイルで`saas-windows-medium-amd64`をタグとして使用して、今すぐお試しください。

### 内部コンポーネント用のCI/CDコンポーネントカタログセクション {#cicd-components-catalog-section-for-your-internal-components}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../ci/components/_index.md#cicd-catalog) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/437768)

{{< /details >}}

CI/CDカタログのアイテム数が増加し続けるにつれて、チームによってリリースされ、利用可能なCI/CDコンポーネントを見つけることがますます困難になっています。このリリースでは、専用の**あなたのグループ**タブを導入し、組織に関連付けられたコンポーネントを簡単にフィルタリングして特定できるようにしました。この簡素化された検索プロセスは、効率性を向上させ、リリースされたCI/CDコンポーネントをより迅速に見つけて使用できるようになります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.8)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.8)
- [UI改善](https://papercuts.gitlab.com/?milestone=16.8)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
