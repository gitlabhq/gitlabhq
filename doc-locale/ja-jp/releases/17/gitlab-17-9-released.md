---
stage: Release Notes
group: Monthly Release
date: 2025-02-20
title: "GitLab 17.9リリースノート"
description: "GitLab 17.9がGitLab Duo Self-Hostedの一般提供を開始"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2025年2月20日、GitLab 17.9は次の機能を搭載してリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター {#this-months-notable-contributor}

[Salihu Dickson](https://gitlab.com/salihudickson)を、[Comments on Wiki pages](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171764)の開発における傑出したコントリビュートでMVPとして表彰できることを嬉しく思います。これは、コミュニティから[200以上の肯定的なリアクション](https://gitlab.com/groups/gitlab-org/-/epics/14062)を集めた要望の多い機能です！

彼の献身は6か月以上に及び、およそ4,000コード行にわたる[wiki top-level discussions](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171764)の実装を提供しました。Salihuはまた、いくつかの概念実証の実装を作成し、追加機能やバグ修正によってWikiエクスペリエンスを向上させました。

「SalihuはWikiページのコメントの開発における傑出したコミュニティコントリビューターでした！」と、GitLabのProduct Manager, Plan:Knowledgeである[Matthew Macfarlane](https://gitlab.com/mmacfarlane)は述べています。「Salihuの製品に関する豊富な知識により、この主要な機能をより効率的に提供することができました。プロダクトマネージャーとして、Salihuのようなコントリビューターと一緒に作業できることは喜びです！」

「信じられないほどの功績だ！」と、GitLabのSenior製品デザイナー, Plan:Knowledgeである[Alex Fracazo](https://gitlab.com/afracazo)は述べています。「Salihuは基本的な機能を構築しただけでなく、Wikiページのトップレベルディスカッションからエラー処理、テストカバレッジに至るまで、包括的なエンドツーエンドの機能を提供しました。」GitLabチームの多くのメンバーは、彼の技術スキルとコラボレーションを強調し、Principal EngineerでVue.jsコアチームメンバーのNatalia Tepluhina、およびGitLabのEngineering Manager, Plan:Knowledgeである[Vladimir Shushlin](https://gitlab.com/vshushlin)を含め、Salihuの作業に強い感謝の意を示しました。

Elixir Cloudのフロントエンドエンジニアであり、2度のGSoCメンターでもあるSalihuは次のように語りました。「これを可能にするために密接に協力してくれたすべての人に感謝したいです。特にGitLabのStaff Frontend Engineer, Plan:Knowledgeである[Himanshu Kapoor](https://gitlab.com/himkp)に感謝します。過去数ヶ月間のあなたの指導は、私がここで行ったすべての作業にとって極めて重要であり、あなたが提供してくれたすべての指導とサポートに心から感謝しています。この機能を具現化することは、何百ものコード行を綿密に確認したレビュアーから、GitLabのBackend Engineer, Plan:Knowledgeである[Piotr Skorupa](https://gitlab.com/pskorupa)のようなバックエンドデベロッパーに至るまで、真にチームの努力でした。」彼はチームとの協力、そして「将来、さらに多くの影響力のある機能にコントリビュートすること」に熱意を表明しました。

Salihuのすべてのコントリビュート、そしてGitLabにコントリビュートしてくださったすべてのオープンソースコミュニティの皆様に深く感謝いたします！

## 主要な機能 {#primary-features}

### GitLab Duo Self-Hostedが一般提供開始 {#gitlab-duo-self-hosted-is-generally-available}

<!-- categories: Self-Hosted Models -->

{{< details >}}

- プラン: Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../administration/gitlab_duo_self_hosted/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/517102)

{{< /details >}}

選択した大規模言語モデル（LLM）を独自のインフラストラクチャにホストし、それらのモデルをGitLab Duo Chatコード提案のソースとして設定できるようになりました。この機能は、該当するライセンスがあればSelf-Managed GitLab環境で一般提供されています。

GitLab Duo Self-Hostedを使用すると、オンプレミスまたはプライベートクラウドでホストされているモデルを、GitLab Duo Chatまたはコード提案のソースとして使用できます。現在、vLLMまたはAWS Bedrock上のオープンソースMistralモデル、AWS Bedrock上のClaude 3.5 Sonnet、およびAzure OpenAI上のOpenAIモデルをサポートしています。セルフホストモデルを有効にすることで、完全なデータ主権とプライバシーを維持しながら、生成AIの力を活用できます。

[イシュー512753](https://gitlab.com/gitlab-org/gitlab/-/issues/512753)にフィードバックをお寄せください。

### 複数のGitLab Pagesサイトを並行デプロイで実行 {#run-multiple-pages-sites-with-parallel-deployments}

<!-- categories: Pages -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/pages/_index.md#parallel-deployments) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14434)

{{< /details >}}

複数のGitLab Pagesサイトのバージョンを、並行デプロイで同時に作成できるようになりました。各デプロイは、設定されたプレフィックスに基づいて一意のURLを取得します。例えば、一意のドメインがある場合、サイトは`project-123456.gitlab.io/prefix`からアクセスでき、一意のドメインがない場合は`namespace.gitlab.io/project/prefix`からアクセスできます。

この機能は、次の場合に特に役立ちます:

- デザインの変更やコンテンツの更新をプレビューする。
- 開発中にサイトの変更をテストする。
- マージリクエストからの変更をレビューする。
- 複数のサイトバージョン（例えば、ローカライズされたコンテンツを含む）を維持する。

並行デプロイは、ストレージスペースを管理するためにデフォルトで24時間後に期限切れになりますが、この期間をカスタマイズしたり、デプロイを永続的に設定したりできます。自動クリーンアップの場合、マージリクエストから作成された並行デプロイは、マージリクエストがマージまたはクローズされると削除されます。

### VS CodeとJetBrains IDEのDuo Chatにプロジェクトファイルを追加 {#add-project-files-to-duo-chat-in-vs-code-and-jetbrains-ides}

<!-- categories: Editor Extensions, Duo Chat -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo_chat/examples.md#ask-about-specific-files-in-the-ide) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/15183)

{{< /details >}}

プロジェクトファイルをVS CodeとJetBrainsのDuo Chatに直接追加して、より強力なコンテキスト認識型のAI支援を利用可能にします。

プロジェクトファイルを追加することで、Duo Chatは特定のコードベースを深く理解し、高い文脈性を持った正確な応答を提供できるようになります。このコンテキスト認識型により、より関連性の高いコードの説明、正確なデバッグ支援、および既存のコードベースにシームレスに統合される提案が得られます。この新しいエキサイティングな機能に対するフィードバックをお待ちしております。[こちらのフィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/492443)でご意見をお聞かせください。

### ワークスペースでのSysboxによるコンテナのサポート {#workspaces-container-support-with-sysbox}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/workspace/configuration.md#build-and-run-containers-in-a-workspace)

{{< /details >}}

GitLabワークスペースは、開発環境で直接コンテナをビルドおよび実行することをサポートするようになりました。ワークスペースが[Sysbox](../../user/workspace/configuration.md#with-sysbox)で設定されたKubernetesクラスター上で実行される場合、追加の設定なしでコンテナをビルドおよび実行できます。

GitLab 17.4で[sudoアクセス機能](https://about.gitlab.com/releases/2024/09/19/gitlab-17-4-released/#secure-sudo-access-for-workspaces)の一部として導入されたこの機能により、GitLabワークスペース環境で完全なコンテナワークフローを維持できます。

### カスタムdevfileなしでワークスペースを作成 {#create-workspaces-without-a-custom-devfile}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/workspace/_index.md#gitlab-default-devfile)

{{< /details >}}

以前は、ワークスペースのセットアップには`devfile.yaml`設定ファイルの作成が必要でした。GitLabは、一般的な開発ツールを含むデフォルトファイルを提供するようになりました。この強化により:

- 設定の障壁をなくします。
- 任意のプロジェクトから迅速にワークスペースを作成できます。
- 一般的な開発ツールが事前に設定されており、すぐに使用できます。
- 設定ではなく開発に集中できます。

追加のセットアップや設定手順なしで、すぐに開発を開始し、ワークスペースを作成できます。

### GitLab管理Kubernetesリソース {#gitlab-managed-kubernetes-resources}

<!-- categories: Environment Management, Deployment Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/clusters/agent/managed_kubernetes_resources.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16130)

{{< /details >}}

[GitLab](../../user/clusters/agent/managed_kubernetes_resources.md)管理Kubernetesリソースを使用して、より詳細な制御と自動化でアプリケーションをKubernetesにデプロイします。以前は、各環境でKubernetesリソースを手動で設定する必要がありました。今では、GitLab管理Kubernetesリソースを使用して、これらのリソースを自動的にプロビジョニングするおよび管理できます。

GitLab管理Kubernetesリソースを使用すると、次のことが可能です:

- 新しい環境のために自動的にネームスペースとサービスアカウントを作成します
- ロールバインディングを通じてアクセス権限を管理します
- その他の必要なKubernetesリソースを設定します

デベロッパーがアプリケーションをデプロイすると、GitLabは提供されたリソーステンプレートに基づいて必要なKubernetesリソースを自動的に作成し、デプロイプロセスを効率化し、環境間の一貫性を維持します。

### プロジェクト環境内でのデプロイへのアクセスを簡素化 {#simplified-access-to-deployments-within-project-environments}

<!-- categories: Environment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/505770)

{{< /details >}}

プロジェクト内のデプロイの概要を把握するのに苦労したことはありませんか？各環境を展開することなく、環境リストで最近のデプロイ詳細を表示できるようになりました。各環境について、リストには最新の成功したデプロイと、異なる場合は最も最近のデプロイ試行が表示されます。

### Wikiページのコメント {#wiki-page-comments}

<!-- categories: Wiki -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/discussions/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14062)

{{< /details >}}

Wikiページに直接コメントを追加できるようになり、ドキュメントをインタラクティブなコラボレーションスペースに変えることができます。

Wikiページのコメントとスレッドは、チームが次のことを行うのに役立ちます:

- コンテキスト内で直接コンテンツをディスカッションします。
- 改善点と修正点を提案します。
- ドキュメントを正確かつ最新の状態に保ちます。
- 知識と専門知識を共有します。

Wikiコメントを使用することで、チームは直接的なフィードバックとディスカッションを通じて、プロジェクトとともに進化する生きたドキュメントを維持できます。

### ワークフローの可視性を強化: マージリクエストのレビュー時間に関する新たなインサイト {#enhancing-workflow-visibility-new-insights-into-merge-request-review-time}

<!-- categories: Value Stream Management, Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/value_stream_analytics/_index.md#value-stream-stage-events) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/503754)

{{< /details >}}

開発ワークフローの追跡を改善するために、[バリューストリーム分析](https://about.gitlab.com/solutions/value-stream-management/)（VSA）が新しいイベント — *Merge request last approved at* — で拡張されました。[マージリクエストの承認](../../user/project/merge_requests/approvals/_index.md)イベントは、レビューフェーズの終了と、最終パイプラインの実行またはマージステージの開始を示します。例えば、合計マージリクエストのレビュー時間を計算するには、開始イベントとして*Merge request reviewer first assigned*、終了イベントとして*Merge request last approved at*を持つVSAステージを作成できます。

この強化により、チームはレビュー時間を最適化する機会に関する深いインサイトを得ることができ、これにより開発全体のサイクルタイムを短縮し、より迅速なソフトウエアデリバリーにつながります。

### 脆弱性リスクの優先順位付けのためのEPSS、KEV、およびCVSSデータ {#epss-kev-and-cvss-data-for-vulnerability-risk-prioritization}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/vulnerabilities/risk_assessment_data.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11544)

{{< /details >}}

以下の脆弱性リスクデータのサポートを追加しました:

- Exploit Prediction Scoring System（EPSS）
- 既知の悪用された脆弱性（KEV）
- Common Vulnerabilities and Exposures（CVE）

このデータを使用して、依存およびコンテナイメージの脆弱性全体のリスクを効率的に優先順位付けできるようになりました。データは脆弱性レポートおよび脆弱性詳細ページで見つけることができます。

### UIを通じてDASTスキャンを完全に制御して設定 {#configure-dast-scans-through-the-ui-with-full-control}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dast/on-demand_scan.md)

{{< /details >}}

複雑なアプリケーションを効果的にテストするには、セキュリティチームがDASTスキャンを設定する際に柔軟性が必要です。以前は、UIを通じて設定されたDASTスキャンには限られた設定オプションしかなく、特定のセキュリティ要件を持つアプリケーションのスキャンを成功させることができませんでした。これは、迅速なセキュリティ評価であってもパイプラインベースのスキャンを使用する必要があることを意味しました。

パイプラインベースのスキャンで利用できるのと同じきめ細かい制御で、UIを通じてDASTスキャンを設定できるようになりました。これには次のユーザーが含まれます。

- カスタムヘッダーやCookieを含む完全な認証設定
- 最大ページ数、最大深度、除外URLなどの正確なクロール設定
- 高度なスキャンタイムアウトと再試行回数
- 最大リンククロール数やDOM深度などのカスタムスキャナー動作
- 特定の脆弱性タイプを対象としたスキャンモード

これらの設定を再利用可能なプロファイルとして保存し、アプリケーション全体で一貫したセキュリティテストを維持します。すべての設定変更は監査イベントで追跡されるため、スキャン設定がいつ追加、編集、削除されたかを知ることができます。

この強化された制御により、詳細な監査証跡を使用してコンプライアンスを維持しながら、より効果的なセキュリティスキャンを実行できます。パイプラインの設定の管理に時間を費やす代わりに、各アプリケーションに適したスキャンを迅速に起動して、脆弱性をより早く見つけて修正できます。

### 自動CI/CDパイプラインクリーンアップ {#automatic-cicd-pipeline-cleanup}

<!-- categories: Continuous Integration (CI) Scaling -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/pipelines/settings.md#automatic-pipeline-cleanup) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/338480)

{{< /details >}}

以前は、古いCI/CDパイプラインを削除したい場合、APIを通じてのみ行うことができました。

GitLab 17.9で、CI/CDパイプラインの有効期限を設定できるプロジェクト設定を導入しました。定義された保持期間よりも古いすべてのパイプラインおよび関連アーティファクトは削除されます。これは、多数のパイプラインを実行し、大量のアーティファクトを生成するプロジェクトでのディスク使用量を削減し、全体的なパフォーマンスを向上させるのにも役立ちます。

## エージェント型コア {#agentic-core}

### より安全なAI接続のためのコンポジットアイデンティティ {#composite-identity-for-more-secure-ai-connections}

<!-- categories: Duo Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../development/ai_features/composite_identity.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/506641)

{{< /details >}}

以前は、GitLabへのリクエストは単一ユーザーとしてのみ認証するできました。コンポジットアイデンティティにより、サービスアカウントとユーザーとして同時にリクエストを認証することが可能になりました。AIエージェントのユースケースでは、タスクを開始したユーザーに基づいて権限が付与され、同時に開始ユーザーとは異なる独自のアイデンティティを示す必要があることがよくあります。コンポジットアイデンティティは、AIエージェントのアイデンティティを表す新しいアイデンティティプリンシパルです。このアイデンティティは、エージェントにアクションをリクエストする人間のユーザーのアイデンティティとリンクしています。AIエージェントのアクションがリソースにアクセスしようとすると、コンポジットアイデンティティトークンが使用されます。このトークンはサービスアカウントに属し、エージェントに指示している人間のユーザーともリンクされています。トークンで実行される認可チェックは、リソースへのアクセスを許可する前に両方のプリンシパルを考慮します。両方のアイデンティティがリソースへのアクセスを持っている必要があり、そうでない場合はアクセスが拒否されます。この新しい機能により、GitLabに保存されているリソースを保護する能力が強化されます。サービスアカウントのコンポジットアイデンティティの使用方法の詳細については、[ドキュメント](../../development/ai_features/composite_identity.md)を参照してください。

## 規模とデプロイ {#scale-and-deployments}

### ユーザーが自分のプロファイルを非公開にすることを制限する {#restrict-users-from-making-their-profile-private}

<!-- categories: User Management, User Profile -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../administration/settings/account_and_limit_settings.md#prevent-users-from-making-their-profiles-private) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/421310)

{{< /details >}}

ユーザーは自分のユーザープロファイルを公開または非公開にすることができます。管理者は、ユーザーがGitLabインスタンス全体でプロファイルを非公開にするオプションを持つかどうかを制御できるようになりました。管理者エリアの「ユーザーが自分のプロファイルを非公開にできるようにします」でこの設定を制御します。この設定はデフォルトで有効になっており、ユーザーは非公開プロファイルを選択できます。

### REST APIを使用してグループからプロジェクトインテグレーションを管理する {#manage-project-integrations-from-a-group-with-the-rest-api}

<!-- categories: API, Integrations -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/group_integrations.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/328496)

{{< /details >}}

以前は、GitLab UIでのみグループからプロジェクトインテグレーションを管理できました。今回のリリースにより、REST APIでもこれらのインテグレーションを管理できるようになりました。

[Van](https://gitlab.com/van.m.anderson)の[最初のコミュニティコントリビュート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148283)に感謝します。これはその後GitLabによって引き継がれ、完了されました。

### グループ共有の可視性強化 {#group-sharing-visibility-enhancement}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/members/sharing_projects_groups.md#view-shared-groups) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/378629)

{{< /details >}}

GitLab全体でのグループ共有の可視性が拡張されたことをお知らせできることを嬉しく思います。以前は、グループの概要ページで共有プロジェクトを確認できましたが、自分のグループがどのグループに招待されたかを確認することはできませんでした。これで、グループ概要ページで**共有プロジェクト**と**共有グループ**の両方のタブを表示できるようになり、組織全体でグループがどのように接続され共有されているかを完全に把握できます。これにより、組織全体のグループアクセスを監査および管理しやすくなります。

この変更に関するフィードバックを[エピック16777](https://gitlab.com/groups/gitlab-org/-/epics/16777)でお待ちしております。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### Cargo、Conda、Cocoapods、Swiftプロジェクト向けSBOMを使用した依存関係スキャンを有効にする {#enable-dependency-scanning-using-sbom-for-cargo-conda-cocoapods-and-swift-projects}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/dependency_scanning_sbom/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/519597)

{{< /details >}}

GitLab 17.9では、コンポジション解析チームは新しい依存関係スキャンアナライザーを使用して、SBOMを使用した依存関係スキャンへの移行を開始します。このアナライザーはGemnasiumの代替となり、Gemnasiumは18.0でサポート終了となり、GitLab 19.0まで引き続き利用可能です。

SBOMを使用した依存関係スキャンのアプローチは、言語サポートの拡大、GitLabプラットフォーム内でのより緊密なインテグレーションとエクスペリエンス、および業界標準のレポートタイプ（SBOMベースのスキャンとレポート）への移行を通じて、顧客をより良くサポートします。GitLab 17.9以降、新しい依存関係スキャンアナライザーは、以下のプロジェクトおよびファイルタイプに対して、`latest`依存関係スキャンCI/CDテンプレート（`Dependency-Scanning.latest.gitlab-ci.yml`）でデフォルトで有効になります:

- condaおよび`conda-lock.yml`ファイルを使用するC/C++/Fortran/Go/Python/Rプロジェクト。
- Cocoapodsおよび`podfile.lock`ファイルを使用するObjective-Cプロジェクト。
- Cargoおよび`cargo.lock`ファイルを使用するRustプロジェクト。
- Swiftおよび`package.resolved`ファイルを使用するSwiftプロジェクト。

この変更により、新しいCI/CD変数: `DS_ENFORCE_NEW_ANALYZER`が導入され、これは`false`にデフォルトで設定されます。

このアプローチにより、`latest`テンプレートの既存のすべての顧客が引き続きデフォルトでGemnasiumアナライザーを使用し、上記のファイルタイプに対して新しい依存関係スキャンアナライザーが自動的に有効になります。

新しい依存関係スキャンアナライザーに移行することを希望する既存の顧客は、`DS_ENFORCE_NEW_ANALYZER`を`true`に設定できます（プロジェクト、グループ、またはインスタンスレベル）。この変更の詳細については、[非推奨のお知らせ](../../update/deprecations.md#dependency-scanning-upgrades-to-the-gitlab-sbom-vulnerability-scanner)および関連する[移行ガイド](../../user/application_security/dependency_scanning/migration_guide_to_sbom_based_scans.md)を参照してください。

新しい依存関係スキャンアナライザーの使用を完全に防ぎたい顧客は、CI/CD変数`DS_EXCLUDED_ANALYZERS`を`dependency-scanning`に設定する必要があります。

### Swiftパッケージのライセンススキャンのサポート {#license-scanning-support-for-swift-packages}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/license_scanning_of_cyclonedx_files/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/506730)

{{< /details >}}

GitLab 17.9で、Swiftパッケージのライセンススキャンのサポートを追加しました。これにより、プロジェクト内でSwiftを使用するユーザーは、自身のSwiftパッケージのライセンスをよりよく理解できるようになります。

このデータは、依存関係リスト、SBOMレポート、およびGraphQL APIを通じてコンポジション解析ユーザーが利用できます。

### マルチコア高度なSASTによる高速スキャン {#multi-core-advanced-sast-offers-faster-scans}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/sast/_index.md#security-scanner-configuration) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/514156)

{{< /details >}}

GitLab高度なSASTは、パフォーマンス向上のためのオプトイン機能としてマルチコアスキャンを提供するようになりました。これにより、特に大規模なコードベースの場合、スキャン時間を大幅に短縮できます。

これを有効にするには、CI/CD変数`SAST_SCANNER_ALLOWED_CLI_OPTS`を`--multi-core N`に設定します。`N`は使用するコアの希望する数です。この変数は`gitlab-advanced-sast`ジョブにのみ設定し、他のジョブには設定しないでください。適切な値を選択する方法に関する重要なガイダンスについては、[ドキュメント](../../user/application_security/sast/_index.md#security-scanner-configuration)を確認してください。

このパフォーマンス改善をデフォルトで有効にする作業を進めています。これは[イシュー517409](https://gitlab.com/gitlab-org/gitlab/-/issues/517409)で追跡されています。

### プロジェクトのコンプライアンスセンターを使用してコンプライアンスフレームワークを適用する {#apply-a-compliance-framework-by-using-a-projects-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate、Premium
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_projects_report.md) | [関連エピック](https://gitlab.com/gitlab-org/gitlab/-/issues/507986)

{{< /details >}}

GitLab 17.2では、グループオーナーがグループのコンプライアンスセンターを使用して、グループ内のすべてのプロジェクトにコンプライアンスフレームワークを適用および削除できる機能をリリースしました。

この機能を拡張し、グループオーナーがプロジェクトレベルでコンプライアンスフレームワークを適用および削除することも許可するようにしました。これにより、グループオーナーがプロジェクトレベルでコンプライアンスフレームワークを適用および監視することがさらに容易になります。

プロジェクトレベルでコンプライアンスフレームワークを適用および削除する機能は、グループオーナーのみが利用でき、プロジェクトオーナーは利用できません。

### ワークスペース拡張機能が提案されたAPIをサポート {#workspace-extensions-now-support-proposed-apis}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/workspace/_index.md#extension-marketplace)

{{< /details >}}

ワークスペース拡張機能が提案されたAPIの有効化をサポートし、本番環境での互換性と信頼性を向上させます。このアップデートにより、提案されたAPIに依存する拡張機能がエラーなしで実行できるようになり、Pythonデバッガのような重要な開発ツールも含まれます。この変更により、安定性を維持しながらAPIアクセスが拡張されます。

### FluxCD CI/CDコンポーネントでOCIベースのGitOpsを実装する {#implement-oci-based-gitops-with-the-fluxcd-cicd-component}

<!-- categories: Container Registry, Deployment Management, Component Catalog -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](https://gitlab.com/components/fluxcd/) | [関連イシュー](https://gitlab.com/gitlab-org/ci-cd/deploy-stage/environments-group/experiments/fluxcd-ci-cd-component/-/issues/1)

{{< /details >}}

GitLabでGitOpsのベストプラクティスを実装する方法を考えたことはありますか？新しい[FluxCDコンポーネント](https://gitlab.com/components/fluxcd/)を使用すると簡単です。FluxCDコンポーネントを使用して、KubernetesマニフェストをOCIイメージにパッケージ化し、OCI互換のコンテナレジストリにイメージを保存できます。オプションでイメージに署名し、即座にFluxCD調整をトリガーすることができます。

### GitLabとKubernetesのインテグレーションを始める {#get-started-with-the-gitlab-integration-with-kubernetes}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/clusters/agent/getting_started.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/505216)

{{< /details >}}

このリリースでは、GitLabを使用してアプリケーションをKubernetesに直接、またはFluxCDと連携してデプロイする方法を示す新しいKubernetes入門ガイドを追加しました。これらのわかりやすいチュートリアルは、深いKubernetesの知識を必要としないため、初心者ユーザーも経験豊富なユーザーもGitLabとKubernetesを統合する方法を学ぶことができます。

Kubernetes入門ガイドを補完するために、GitLabをKubernetes環境に統合するための推奨事項も含まれています。

### 証明書ベースのKubernetesクラスターを検出して移行する {#discover-and-migrate-certificate-based-kubernetes-clusters}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/cluster_discovery.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/512420)

{{< /details >}}

証明書ベースのKubernetesインテグレーションは、2025年5月6日9:00 AM UTCから2025年5月8日22:00 PM UTCの間、GitLab.comのすべてのユーザーに対して無効になり、GitLab 19.0（2026年5月予定）でGitLab Self-Managedインスタンスから削除されます。

ユーザーの移行を支援するため、グループオーナーがグループ、サブグループ、またはプロジェクトに登録された[証明書ベースのクラスターを検出](../../api/cluster_discovery.md)するためにクエリできる新しいクラスターAPIエンドポイントを追加しました。また、さまざまなタイプのユースケース向けの手順を提供するために、[移行ドキュメント](../../user/infrastructure/clusters/migrate_to_gitlab_agent.md)を更新しました。

すべてのGitLab.comユーザーに、影響を受けているかどうかを確認し、できるだけ早く移行を計画することをお勧めします。

### パイプライン実行ポリシーでカスタムステージを強制する {#enforce-custom-stages-in-pipeline-execution-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/pipeline_execution_policies.md#inject_policy-type) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/475152)

{{< /details >}}

パイプライン実行ポリシーの新しい機能として、`Inject`モードでCI/CDパイプラインに**custom stages**を強制できるようになったことを発表できることを嬉しく思います。この機能により、セキュリティとコンプライアンスの要件を維持しながら、パイプライン構造に対する柔軟性と制御が向上し、次の機能が提供されます:

- **Enhanced pipeline customization**: パイプラインの特定のポイントでカスタムステージを定義および挿入し、ジョブの実行順序をよりきめ細かく制御できるようにします。
- **Improved security and compliance**: ビルド後、デプロイ前など、パイプラインの最も適切なタイミングでセキュリティスキャンとコンプライアンスチェックが実行されるようにします。
- **Flexible policy management**: 一元化されたポリシー制御を維持しながら、開発チームが定義されたガードレール内でパイプラインをカスタマイズできるようにします。
- **Seamless integration**: カスタムステージは、既存のプロジェクトステージや他のポリシータイプと連携して機能し、CI/CDワークフローを強化するための非破壊的な方法を提供します。

**How does it work?**

新しく改善された`inject_policy`パイプライン実行ポリシー戦略により、ポリシー設定でカスタムステージを定義できます。これらのステージは、Directed Acyclic Graph（DAG）アルゴリズムを使用してプロジェクトの既存のステージとインテリジェントにマージされ、適切な順序付けと競合の防止を保証します。

例えば、ビルドステージとデプロイステージの間にカスタムセキュリティスキャンステージを簡単に挿入できるようになりました。

`inject_policy`ステージは、非推奨となる`inject_ci`を置き換え、`inject_policy`モードをオプトインしてメリットを得ることができます。ポリシーエディタで`Inject`を使用してポリシーを設定する場合、`inject_policy`モードがデフォルトになります。

### `self_rotate`スコープでアクセストークンをローテーションする {#rotate-access-tokens-with-self_rotate-scope}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/personal_access_tokens.md#personal-access-token-scopes) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/430748)

{{< /details >}}

`self_rotate`スコープを使用してアクセストークンをローテーションできるようになりました。このスコープは、個人、プロジェクト、またはグループのアクセストークンで利用できます。以前は、これには2つのリクエストが必要でした: 新しいトークンを取得するための1つと、トークンのローテーションを実行するためのもう1つです。

[Stéphane Talbot](https://gitlab.com/stalb)と[Anthony Juckel](https://gitlab.com/ajuckel)のコントリビュートに感謝します！

### 非アクティブなプロジェクトおよびグループのアクセストークンを表示 {#view-inactive-project-and-group-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free, Premium, Ultimate, Silver, Gold
- リンク: [ドキュメント](../../user/project/settings/project_access_tokens.md#view-your-access-tokens) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/462217)

{{< /details >}}

UIで非アクティブなグループおよびプロジェクトのアクセストークンを表示できるようになりました。以前は、GitLabはプロジェクトおよびグループのアクセストークンが期限切れになるか、失効するとすぐに削除していました。非アクティブなトークンの記録がないため、監査およびセキュリティレビューがより困難になっていました。GitLabは、非アクティブなグループおよびプロジェクトのアクセストークン記録を30日間保持するようになり、これによりチームはトークンの使用状況と有効期限を追跡し、コンプライアンスおよびモニタリング目的で役立ちます。

### アクセストークンのIPアドレスを表示 {#view-access-token-ip-addresses}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/personal_access_tokens.md#view-token-usage-information) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/428577)

{{< /details >}}

以前は、パーソナルアクセストークンを表示すると、トークンが何分前に使用されたかという使用情報しか確認できませんでした。今では、トークンが使用された最大7つの最新のIPアドレスも確認できます。この組み合わせられた情報は、トークンがどこで使用されているかを追跡するのに役立ちます。

[Jayce Martin](https://jrm2k.us) 、[Avinash Koganti](http://www.linkedin.com/in/avinash-koganti-38b511162) 、[Austin Dixon](https://austindixon.net/) 、[Rohit Kala](https://www.linkedin.com/in/rohit-kala-1b891a179)のコントリビュートに感謝します！

### グループのGitLab Pagesへのアクセス制御 {#control-access-to-gitlab-pages-for-groups}

<!-- categories: Pages -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/pages/pages_access_control.md#remove-public-access-for-group-pages)

{{< /details >}}

グループレベルでGitLab Pagesへのアクセスを制限できるようになりました。グループオーナーは、単一の設定を有効にして、グループとそのサブグループ内のすべてのPagesサイトをプロジェクトメンバーのみに表示させることができます。この一元化された制御により、個別のプロジェクト設定を変更することなくセキュリティ管理が簡素化されます。

### 作業アイテムのタイプを別のものに変更する {#change-work-item-type-to-another}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/tasks.md#convert-a-task-into-another-item-type) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/385131)

{{< /details >}}

作業アイテムのタイプを簡単に変更できるようになり、プロジェクトをより効率的に管理できる柔軟性が得られます。

### フォームを開いたままにして新しい子アイテムの追加を高速化 {#speed-up-adding-new-child-items-by-keeping-the-form-open}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/work_items/child_items.md#work-with-multi-level-hierarchies) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/497767)

{{< /details >}}

各提出後にフォームを開いたままにすることで、複数の子アイテムを作成するプロセスを効率化し、余分なクリックなしで複数のエントリーを簡単に追加できるようにしました。このアップデートにより、時間を節約し、タスク管理時のよりスムーズなワークフローを保証します。

### 作業アイテムGraphQL API — 追加クエリフィルター {#work-items-graphql-api---additional-query-filters}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/graphql/reference/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/513308)

{{< /details >}}

作業アイテムGraphQL APIは、次の項目でフィルターできる追加のクエリフィルターを含むようになりました:

- 作成日、更新日、クローズ日、期限日
- ヘルスステータス
- ウェイト

これらの新しいフィルターにより、APIを通じて作業アイテムをクエリするおよび整理する際の制御が向上します。

### アクティブなセキュリティポリシープロジェクトの削除をブロックする {#block-deletion-of-active-security-policy-projects}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/_index.md) | [関連エピック](https://gitlab.com/gitlab-org/gitlab/-/issues/482967)

{{< /details >}}

セキュリティポリシーの安全な管理を確保し、有効化および強制されたポリシーへの中断を防ぐために、使用中のセキュリティポリシープロジェクトの削除を防ぐ保護を追加しました。

セキュリティポリシープロジェクトが任意のグループまたはプロジェクトにリンクされている場合、セキュリティポリシープロジェクトを削除する前にリンクを削除する必要があります。

### プロジェクト内の依存関係リストのコンポーネントによるフィルター {#dependency-list-filter-by-component-in-projects}

<!-- categories: Dependency Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_list/_index.md#filter-dependency-list) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/16490)

{{< /details >}}

プロジェクト内の依存関係リストで、コンポーネントフィルターを使用してパッケージ名でフィルターできるようになりました。

以前は、プロジェクトレベルの依存関係リストでパッケージを検索できませんでした。これで、コンポーネントフィルターを設定すると、指定された文字列を含むパッケージが見つかります。

### プロジェクト脆弱性レポート内の識別子でフィルター {#filter-by-identifier-in-the-project-vulnerability-report}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md#filtering-vulnerabilities) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13340)

{{< /details >}}

プロジェクトの脆弱性レポートで、脆弱性識別子によって結果をフィルターできるようになり、プロジェクト内の特定の脆弱性（CVEやCWEなど）を見つけることができます。識別子は、重大度、ステータス、またはツールフィルターなどの他のフィルターと組み合わせて使用できます。脆弱性識別子フィルターは、20,000以下の脆弱性を持つレポートに制限されています。

### マージリクエスト承認ポリシーでカスタムロールをサポート {#support-custom-roles-in-merge-request-approval-policies}

<!-- categories: Permissions, Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md#require_approval-action-type) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13550)

{{< /details >}}

マージリクエスト承認ポリシーに承認者としてカスタムロールを割り当てる機能を追加することで、柔軟性を高めました。

これにより、組織固有のチーム構造と責任に合わせて承認要件を調整し、ポリシーに基づいて適切なロールがレビュープロセスに参加するようにできます。例えば、セキュリティレビューにはAppSecエンジニアリングのロールからの承認を、ライセンス承認にはコンプライアンスのロールからの承認を要求できます。

### 認証情報インベントリを検索およびフィルターする {#search-and-filter-the-credentials-inventory}

<!-- categories: System Access -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/credentials_inventory.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/345734)

{{< /details >}}

認証情報インベントリで検索およびフィルター機能を使用できるようになりました。これにより、特定のユーザー定義パラメータに該当するトークンやキー（特定の期間内に期限切れになるトークンを含む）を特定しやすくなります。以前は、認証情報インベントリのエントリは静的リストとして表示されていました。

### OAuthアプリケーションの認可監査イベント {#oauth-application-authorization-audit-event}

<!-- categories: Audit Events -->

{{< details >}}

- プラン: Ultimate、Premium
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/audit_event_types.md#authorization) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/514152)

{{< /details >}}

以前は、ユーザーがOAuthアプリケーションを認可した場合、監査イベントは生成されませんでした。しかし、このイベントは、特定のGitLabインスタンスでユーザーによって認可されたOAuthアプリケーションをセキュリティチームが監視するために重要です。

今回のリリースにより、GitLabは、ユーザーがOAuthアプリケーションを正常に認可したときに追跡するための**User authorized an OAuth application**監査イベントを提供するようになりました。この新しい監査イベントは、GitLabインスタンスを監査する能力をさらに向上させます。

### APIを使用して個々のエンタープライズユーザーの2FAを無効にする {#use-api-to-disable-2fa-for-individual-enterprise-users}

<!-- categories: System Access -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/group_enterprise_users.md#disable-two-factor-authentication-for-an-enterprise-user) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/383319)

{{< /details >}}

APIを使用して、個々のエンタープライズユーザーのすべての2要素認証（2FA）登録をクリアできるようになりました。以前は、これはUIでのみ可能でした。APIを使用すると、自動化された一括操作が可能になり、2FAのリセットをスケールで実行する必要がある場合に時間を節約できます。

### サービスアカウント用のメール通知 {#email-notifications-for-service-accounts}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/service_accounts.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/428750)

{{< /details >}}

サービスアカウントのメール通知を受信するために、カスタムメールアドレスを設定できるようになりました。サービスアカウントの作成時にカスタムメールアドレスが指定されると、GitLabはそのアドレスに通知を送信します。各サービスアカウントは一意のメールアドレスを使用する必要があります。これにより、プロセスとイベントをより効果的に監視できます。

[SNCF Connect & Techチーム](https://www.sncf-connect-tech.fr/)の[Gilles Dehaudt](https://gitlab.com/tonton1728) 、[Étienne Girondel](https://gitlab.com/lenaing) 、[Kevin Caborderie](https://gitlab.com/Densett) 、[Geoffrey McQuat](https://gitlab.com/gmcquat) 、[Raphaël Bihore](https://gitlab.com/rbihore)のコントリビュートに感謝します！

### 複数のOIDCプロバイダーによる追加グループメンバーシップのサポート {#support-for-additional-group-memberships-with-multiple-oidc-providers}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../administration/auth/oidc.md#configure-multiple-openid-connect-providers) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/408248)

{{< /details >}}

複数のOIDCプロバイダーを使用している場合、追加のグループメンバーシップを設定できるようになりました。以前は、複数のOIDCプロバイダーを設定した場合、単一のグループメンバーシップに制限されていました。

### ローテーションされたサービスアカウントトークンのカスタム有効期限 {#custom-expiration-date-for-rotated-service-account-tokens}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/service_accounts.md#rotate-a-personal-access-token-for-a-group-service-account) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/505671)

{{< /details >}}

サービスアカウントのアクセストークンをローテーションする際に、`expires_at`属性を使用してカスタム有効期限を設定できるようになりました。以前は、トークンはローテーションから7日後に自動的に期限切れになりました。これにより、トークンのライフタイムをよりきめ細かく管理できるようになり、安全なアクセス制御を維持する能力が強化されます。

### パイプライン実行ポリシーにおけるマージリクエスト変数のサポート {#support-merge-request-variables-in-pipeline-execution-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/pipeline_execution_policies.md) | [関連エピック](https://gitlab.com/gitlab-org/gitlab/-/issues/512916)

{{< /details >}}

パイプライン実行ポリシーは、追加のマージリクエスト変数をサポートするようになり、マージリクエストに関連する情報を考慮に入れた、より高度なポリシーを作成できます。これにより、CI/CDの強制に対するより的を絞った効率的な制御が可能になります。以下の変数がサポートされるようになりました:

- `CI_MERGE_REQUEST_SOURCE_BRANCH_SHA`
- `CI_MERGE_REQUEST_TARGET_BRANCH_SHA`
- `CI_MERGE_REQUEST_DIFF_BASE_SHA`

この強化により、次のことが可能です:

- ソースブランチとターゲットブランチ間の変更を比較する高度なセキュリティスキャンを実装し、徹底的なコードレビューと脆弱性検出を保証します。
- 各マージリクエストの特性に基づいて適応する動的なパイプライン設定を作成し、開発プロセスを効率化します。

### カスタムロールの新しい権限 {#new-permissions-for-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/custom_roles/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/14746)

{{< /details >}}

[Read compliance dashboard](https://gitlab.com/gitlab-org/gitlab/-/issues/465324)権限を持つカスタムロールを作成できます。カスタムロールを使用すると、ユーザーがタスクを完了するために必要な特定の権限のみを付与できます。これにより、グループのニーズに合わせたロールを定義でき、オーナーまたはメンテナーロールを必要とするユーザーの数を減らすことができます。

### GitLab Runner 17.9 {#gitlab-runner-179}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 17.9もリリースします！GitLab Runnerは、CI/CDジョブを実行し、その結果をGitLabインスタンスに送信する、拡張性の高いビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [Runnerオートスケーラーインスタンスのヘルスチェックを追加](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38271)
- [Runner準備ステージ期間のヒストグラムメトリクスを追加](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37471)
- [Kubernetes executorへのカスタムコンテナ名のサポートを追加](https://gitlab.com/gitlab-org/gitlab/-/issues/421131)

#### バグ修正 {#bug-fixes}

- [GitLab RunnerがS3 Express One Zoneからキャッシュを取得するできません](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/38484)
- [Kubernetes上のGitLab Runnerが、AWS Spotインスタンスに対して「script_failure」ではなく「runner_system_failure」を報告します](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37911)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-9-stable/CHANGELOG.md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.9)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.9)
- [UI改善](https://papercuts.gitlab.com/?milestone=17.9)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
