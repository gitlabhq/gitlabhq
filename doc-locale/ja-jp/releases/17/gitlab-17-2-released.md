---
stage: Release Notes
group: Monthly Release
date: 2024-07-18
title: "GitLab 17.2リリースノート"
description: "Kubernetesポッドとコンテナのログストリーミング機能を搭載したGitLab 17.2がリリースされました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024年7月18日、GitLab 17.2は以下の機能を備えてリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Phawin Khongkhasawan {#this-months-notable-contributor-phawin-khongkhasawan}

誰もがGitLabコミュニティのコントリビューターを[推薦](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)できます！活躍中の候補者を支援するか、新しい推薦を追加してください！ 🙌

Phawin Khongkhasawanは[Jitta](https://www.jitta.com/)の技術リーダーであり、2024年2月にGitLabへのコントリビュートを開始しました。わずか数ヶ月で、Phawinは20を超えるコントリビュートをマージし、彼のコントリビュートは[16.11](https://about.gitlab.com/releases/2024/04/18/gitlab-16-11-released/#test-project-hooks-with-the-rest-api) 、[17.0](https://about.gitlab.com/releases/2024/05/16/gitlab-17-0-released/#customize-avatars-for-users) 、[17.1](https://about.gitlab.com/releases/2024/06/20/gitlab-17-1-released/#require-confirmation-for-manual-jobs)でも取り上げられました。

Phawinは、GitLabのプロダクトマネージャーである[Magdalena Frankiewicz](https://gitlab.com/m_frankiewicz)によって、[API](https://gitlab.com/gitlab-org/gitlab/-/issues/455589)経由でのプロジェクトテストWebhookのトリガーを許可する要求など、Webhook関連の機能改善に初めて推薦されました。GitLabエンジニアの[Marc Shaw](https://gitlab.com/marc_shaw)と[Jose Ivan Vargas](https://gitlab.com/jivanvl) 、およびGitLabプロダクトマネージャーの[Rutvik Shah](https://gitlab.com/rutshah)は、Phawinの協力とイテレーションにおける忍耐力を強調しました。これらは[GitLabのコアバリュー](https://handbook.gitlab.com/handbook/values/)の2つです。

「Phawinの[Add order by merged_at](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147052)機能の開発、忍耐力、そして完遂への粘り強さに本当に感謝しています」とGitLabのスタッフバックエンドエンジニアである[Patrick Bajao](https://gitlab.com/patrickbajao)は述べています。「マージされてデプロイされるまでに数回のマイルストーンがかかりましたが、彼は諦めずに私たちとの協力を続けました。」

新規コントリビューターがどのように即座に影響を与え、GitLabの共同開発を支援できるかを示してくれたPhawinに、心から感謝いたします。

## 主要な機能 {#primary-features}

### Kubernetesポッドとコンテナのログストリーミング {#log-streaming-for-kubernetes-pods-and-containers}

<!-- categories: Environment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/kubernetes_dashboard.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13793)

{{< /details >}}

GitLab 16.1では、Kubernetesポッドのリストビューと詳細ビューを導入しました。しかし、ワークロードを詳細に分析するには、サードパーティ製ツールを使用する必要がありました。GitLabには、ポッドとコンテナのログストリーミングビューが搭載され、アプリケーション配信ツールを離れることなく、環境全体の問題を迅速に確認し、トラブルシューティングできるようになりました。

### GitLab DuoがAI入力と出力のロギングをデフォルトで無効化 {#gitlab-duo-disabling-input-and-output-logging-by-default}

<!-- categories: GitLab Duo Chat -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: GitLab Duo Pro, GitLab Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/data_usage.md#data-retention) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13401)

{{< /details >}}

GitLab Duoは、GitLab DuoのAI入力と出力のロギングをデフォルトで無効化しました。

GitLabでは、お客様がデータに対する主権を持つことを保証することを目指しています。現在、入力と出力のロギングをデフォルトで無効にしており、お客様の明示的な同意がある場合にのみ、GitLabサポートチケットを介して入力と出力をログに記録します。

### マージリクエストをブロックする変更要求 {#block-a-merge-request-by-requesting-changes}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/merge_requests/reviews/_index.md#prevent-merge-when-you-request-changes)

{{< /details >}}

レビューを実行する際に、`approve`、`comment`、または`request changes` ([GitLab 16.9でリリース](https://about.gitlab.com/releases/2024/02/15/gitlab-16-9-released/#request-changes-on-merge-requests)) のいずれかを選択して完了できます。レビュー中に、マージリクエストがマージされるのを阻止すべき変更が見つかる場合があります。その場合、`request changes`でレビューを完了します。

変更を要求すると、GitLabは変更要求が解決されるまでマージを阻止するマージチェックを追加するようになりました。変更要求は、元の変更要求者がマージリクエストを再レビューし、その後マージリクエストを承認した場合に解決できます。元の変更要求者が承認できない場合、変更要求はマージ権限を持つ誰でも**バイパス済み**にでき、開発を続行できます。

この新機能に関するフィードバックを[イシュー455339](https://gitlab.com/gitlab-org/gitlab/-/issues/455339)にお寄せください。

### 脆弱性の説明 {#vulnerability-explanation}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/application_security/analyze/duo.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10642)

{{< /details >}}

脆弱性の説明はGitLab Duo Chatの一部となり、一般公開されました。脆弱性の説明を使用すると、任意のSAST脆弱性からチャットを開き、脆弱性をより深く理解し、どのように悪用される可能性があるかを確認し、潜在的な修正をレビューできます。

### OAuth 2.0デバイス認可グラントサポート {#oauth-20-device-authorization-grant-support}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/oauth2.md#device-authorization-grant-flow) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/332682)

{{< /details >}}

GitLabは現在、[OAuth 2.0デバイス認可グラントフロー](https://datatracker.ietf.org/doc/html/rfc8628)をサポートしています。このフローにより、ブラウザ操作ができない、入力に制約のあるデバイスからGitLab IDを安全に認証することが可能になります。そのため、このフローはヘッドレスサーバーや、UIがない、あるいは限られているデバイスからGitLabのサービスを利用しようとするユーザーに最適です。[John Parent](https://kitware.com/)様のコントリビュートに感謝いたします！

### パイプライン実行ポリシータイプ {#pipeline-execution-policy-type}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/pipeline_execution_policies.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13266)

{{< /details >}}

パイプライン実行ポリシータイプは、一般的なCIジョブ、スクリプト、および指示の適用をサポートする新しいタイプの[セキュリティポリシー](../../user/application_security/policies/_index.md)です。

パイプライン実行ポリシータイプにより、セキュリティおよびコンプライアンスチームは、カスタマイズされた[GitLabセキュリティスキャンテンプレート](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Jobs) 、[GitLabまたはパートナーサポートのCIテンプレート](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates)、サードパーティのセキュリティスキャンテンプレート、CIジョブによるカスタムレポートルール、またはGitLab CIによるカスタムスクリプト/ルールを適用できるようになります。

Theパイプライン実行ポリシーには、インジェクトとオーバーライドの2つのモードがあります。The *inject* modeはプロジェクトのCI/CDパイプラインにジョブをインジェクトします。The *override* modeはプロジェクトのCI/CDパイプラインの設定をオーバーライドします。

すべてのGitLabポリシーと同様に、適用は、ポリシーを作成および管理する指定されたセキュリティおよびコンプライアンスチームメンバーによって一元的に管理できます。[最初のパイプライン実行ポリシーを作成して開始する方法](../../user/application_security/policies/pipeline_execution_policies.md)を学びましょう！

### パイプラインシークレット検出におけるカスタムルールセットの展開されたサポート {#expanded-support-of-custom-rulesets-in-pipeline-secret-detection}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/secret_detection/pipeline/configure.md#customize-analyzer-rulesets) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/336395)

{{< /details >}}

パイプラインシークレット検出におけるカスタムルールセットのサポートを拡張しました。

リモートルールセットを設定するために、`git`と`url`の2つの新しいタイプのパススルーを使用できます。これにより、複数のプロジェクト間でルールセットの設定を共有するなど、ワークフローの管理が容易になります。

また、これらの新しいタイプのパススルーのいずれかを使用して、デフォルトの設定をリモートルールセットで拡張することもできます。

Theアナライザーは現在、以下もサポートしています:

- 定義済みルールを置き換えるために、最大20個のパススルーを単一の設定に連結する。
- パススルーに環境変数を含める。
- パススルーを読み込む際にタイムアウトを設定する。
- ルールセット設定におけるTOML構文の検証。

### GitLab Duo Chatおよびコード提案がワークスペースで利用可能に {#gitlab-duo-chat-and-code-suggestions-available-in-workspaces}

<!-- categories: Workspaces, Duo Chat, Code Suggestions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/gitlab_duo/_index.md)

{{< /details >}}

[GitLab Duo Chat](../../user/gitlab_duo_chat/_index.md)と[コード提案](../../user/project/repository/code_suggestions/_index.md)がワークスペースで利用可能になりました！迅速な回答を求める場合でも、効率的なコード改善を求める場合でも、Duo Chatとコード提案は、生産性を向上させ、ワークフローを効率化するように設計されており、ワークスペースでのリモート開発をこれまで以上に効率的かつ効果的にします。

## 規模とデプロイ {#scale-and-deployments}

### グループ概要におけるソートとフィルタリングの改善 {#improved-sorting-and-filtering-in-group-overview}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/_index.md#view-a-group) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/437013)

{{< /details >}}

グループ概要ページのソートおよびフィルタリング機能を更新しました。検索要素がページ全体に拡大され、検索文字列がより見やすくなりました。ソートオプションを`Name`、`Created date`、`Updated date`、および`Stars`に標準化しました。

これらの変更に関するフィードバックは、[イシュー438322](https://gitlab.com/gitlab-org/gitlab/-/issues/438322)で歓迎します。

### グループs APIを使用してグループが招待されたグループを一覧表示 {#list-groups-that-a-group-was-invited-to-using-the-groups-api}

<!-- categories: API, Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/groups.md#list-shared-groups) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/424959)

{{< /details >}}

グループが招待されたグループを一覧表示するための新しいエンドポイントをグループs APIに追加しました。この機能は、[グループが招待されたプロジェクトを一覧表示するためのエンドポイント](../../api/groups.md#list-shared-projects)を補完するため、グループが追加されたすべてのグループとプロジェクトの完全な概要を取得できるようになりました。エンドポイントは、ユーザーごとに1分あたり60リクエストにレート制限されます。

このコミュニティコントリビュートを提供してくれた[@imskr](https://gitlab.com/imskr)に感謝します！

### To Do項目を一度に1つのディスカッションで解決 {#resolve-to-do-items-one-discussion-at-a-time}

<!-- categories: Notifications -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/todos.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/461111)

{{< /details >}}

GitLabイシューに関するディスカッションは多忙になることがあります。GitLabは、自分に関連するコメントに対してTo Do項目を発生させ、イシューに対してアクションを起こすと自動的にその項目を解決することで、これらの会話の管理を支援します。

以前は、イシュー内のスレッドでアクションを起こすと、複数の異なるスレッドで言及されていた場合でも、すべてのTo Do項目が解決されました。現在、GitLabは、ユーザーが操作したスレッドのTo Do項目のみを解決します。

### UIにインポートされた項目を表示 {#indicate-imported-items-in-ui}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/import/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13825)

{{< /details >}}

GitLabにプロジェクトを[他のSCMソリューション](../../user/import/_index.md)からインポートできます。しかし、プロジェクト項目がインポートされたのか、それともGitLabインスタンスで作成されたのかを知るのは困難でした。

今回のリリースでは、作成者が特定のユーザーとして識別されるGitHub、Gitea、Bitbucket Server、およびBitbucket Cloudからインポートされた項目に視覚的なインジケーターを追加しました。例えば、マージリクエスト、イシュー、およびノートなどです。

### 削除されたブランチがJira開発パネルから削除される {#deleted-branches-are-removed-from-jira-development-panel}

<!-- categories: Integrations -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../integration/jira/development_panel.md#feature-availability) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/351625)

{{< /details >}}

以前は、[GitLab for Jira Cloud app](../../integration/jira/connect-app.md)を使用していた場合、GitLabでブランチを削除しても、そのブランチはJira開発パネルに表示されたままでした。そのブランチを選択すると、GitLabで`404`エラーが発生しました。

今回のリリースから、GitLabで削除されたブランチはJira開発パネルから削除されます。

### コマンドパレットを使用してプロジェクト設定を見つける {#find-project-settings-by-using-the-command-palette}

<!-- categories: Settings, Global Search -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/search/command_palette.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/448637)

{{< /details >}}

GitLabは、プロジェクト、グループ、インスタンス、そして個人向けの多くの設定を提供しています。探している設定を見つけるには、UIの多くの異なる領域をクリックして時間を費やす必要があることがよくありました。

今回のリリースでは、コマンドパレットからプロジェクト設定を検索できるようになりました。プロジェクトにアクセスし、**Search or go to…**を選択し、`>`でコマンドモードに入り、**保護タグ**のような設定セクションの名前を入力して試してみてください。結果を選択すると、設定自体に直接ジャンプします。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### マージコミットメッセージ生成がGAになりました {#merge-commit-message-generation-now-ga}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/project/merge_requests/duo_in_merge_requests.md#generate-a-merge-commit-message)

{{< /details >}}

コミットメッセージを作成することは、将来のユーザーがコードベースに対してどのような変更がなぜ行われたかを理解するための重要な部分です。変更を効果的に伝え、変更した可能性のあるすべてを考慮に入れたメッセージを考案するのは困難です。

GitLab Duoによるマージコミットの生成機能が一般公開され、すべてのマージリクエストで高品質なコミットメッセージが保証されるようになりました。マージする前に、マージウィジェットで**コミットメッセージを編集**を選択し、**コミットメッセージを生成**オプションを使用してコミットメッセージの下書きを作成します。

この新しいGitLab Duoの機能は、プロジェクトのコミット履歴が将来のデベロッパーにとって貴重なリソースとなることを確実にする優れた方法です。

### GitLab Duo for the CLIがGAになりました {#gitlab-duo-for-the-cli-now-ga}

<!-- categories: GitLab CLI -->

{{< details >}}

- プラン: Ultimate
- アドオン: Duo Enterprise
- リンク: [ドキュメント](https://docs.gitlab.com/cli/)

{{< /details >}}

GitLab Duo for the CLIがすべてのユーザーに一般公開されました。これで、`ask` GitLab Duoに、必要な`git`コマンドを見つけるのを手伝ってもらうことができます。

`glab duo ask <git question>`を使用して、GitLab Duoに目標を達成するための書式設定された`git`コマンドを提供させます。その後、GitLab CLIは、コマンドとその動作に関する追加の詳細情報（渡されるフラグに関する情報を含む）を提供します。その後、コマンドを実行し、その出力をワークフローに直接取得できます。

GitLab CLIの`ask`コマンドは、少し覚えるのに助けが必要な`git`コマンドを使用してワークフローをスピードアップするための優れた方法です。

### LFS用の純粋なSSH転送プロトコル {#pure-ssh-transfer-protocol-for-lfs}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/lfs/_index.md#pure-ssh-transfer-protocol) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11872)

{{< /details >}}

2021年9月、[`git-lfs` 3.0.0](https://github.com/git-lfs/git-lfs/blob/main/CHANGELOG.md#300-24-sep-2021)は、HTTPの代わりにSSHを転送プロトコルとして使用するサポートをリリースしました。`git-lfs` 3.0.0以前は、HTTPのみがサポートされている転送プロトコルであり、これは一部のユーザーにとってGitLabでの`git-lfs`の使用が不可能であることを意味しました。今回のリリースでは、`git-lfs`の転送プロトコルとしてHTTP over SSHのサポートを有効にする機能を提供できることを大変嬉しく思います。

このコントリビュートをしてくれた[Kyle Edwards](https://gitlab.com/KyleFromKitware)と[Joe Snyder](https://gitlab.com/joe-snyder)に感謝します！

### 保護環境へのデプロイと承認が監査イベントをトリガーする {#deployments-and-approvals-to-protected-environments-trigger-an-audit-event}

<!-- categories: Continuous Delivery -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/audit_event_types.md#continuous-delivery) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/456687)

{{< /details >}}

デプロイ承認のようなデプロイイベントのアクセス可能な記録は、コンプライアンス管理に不可欠です。これまでGitLabはデプロイ関連の監査イベントを提供していなかったため、コンプライアンスマネージャーはカスタムツールを使用するか、GitLabで直接このデータを検索する必要がありました。GitLabは現在、3つの監査イベントを提供しています:

- `deployment_started`は、誰がデプロイメントジョブを開始し、いつ開始されたかを記録します。
- `deployment_approved`は、誰がデプロイメントジョブを承認し、いつ承認されたかを記録します。
- `deployment_rejected`は、誰がデプロイメントジョブを拒否し、いつ拒否されたかを記録します。

### サブグループコンプライアンスセンターでのフレームワークの割り当て {#assigning-frameworks-at-subgroup-compliance-center}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate、Premium
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_projects_report.md) | [関連エピック](https://gitlab.com/gitlab-org/gitlab/-/issues/469004)

{{< /details >}}

コンプライアンスセンターは、コンプライアンスチームがコンプライアンス基準への準拠レポート、違反レポート、およびグループのコンプライアンスフレームワークを管理するための中央の場所です。

以前は、コンプライアンスセンターの関連機能はすべてトップレベルグループでのみ利用可能でした。これは、サブグループの場合、オーナーがトップレベルグループで提供されるコンプライアンスセンターの機能にアクセスできなかったことを意味しました。

これらの主要な課題に対処するために、サブグループのコンプライアンスフレームワークを割り当てたり、割り当てを解除したりする機能を追加しました。これにより、グループオーナーは、既に利用可能だった完全なトップレベルグループレベルのコンプライアンスセンターダッシュボードに加えて、サブグループレベルでコンプライアンスの状態を視覚化できるようになりました。

### 「スキャン実行ポリシー」を拡張して、各GitLabアナライザーの`latest`テンプレートを実行する {#expand-scan-execution-policies-to-run-latest-templates-for-each-gitlab-analyzer}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/scan_execution_policies.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/415427)

{{< /details >}}

[スキャン実行ポリシー](../../user/application_security/policies/scan_execution_policies.md)が拡張され、ポリシールールを定義する際に`default`と`latest`のGitLabテンプレートを選択できるようになりました。`default`は現在の動作を反映していますが、与えられたセキュリティアナライザーの最新テンプレートでのみ利用可能な機能を使用するために、ポリシーを`latest`に更新できます。

`latest`テンプレートを利用することで、マージリクエストパイプラインにスキャンが適用されることを保証できるようになりました。`latest`テンプレートで有効になっている他のすべてのルールも同様です。以前は、これはブランチパイプラインまたは指定されたパイプラインスケジュールに限定されていました。

注: ポリシーを変更する前に、`default`と`latest`のテンプレート間のすべての変更をレビューして、これがお客様のニーズに合っていることを確認してください！

### 複数のアクセストークンの有効期限が切れる日付を特定する {#identify-dates-when-multiple-access-tokens-expire}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../security/tokens/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/467313)

{{< /details >}}

管理者は、複数のアクセストークンの有効期限が切れる日付を特定するスクリプトを実行できるようになりました。トークンローテーションがまだ実装されていない場合、このスクリプトを[トークントラブルシューティングページ](../../security/tokens/token_troubleshooting.md)の他のスクリプトと組み合わせて使用し、有効期限に近づいている多数のトークンを特定して延長できます。

### OAuth認可画面の改善 {#oauth-authorization-screen-improvements}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../integration/oauth_provider.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/462655)

{{< /details >}}

OAuth認可画面が、ユーザーが許可している認可をより明確に説明するようになりました。また、GitLabが提供するアプリケーションのために「GitLabによる検証済み」セクションも含まれています。以前は、アプリケーションがGitLabによって提供されているかどうかに関わらず、ユーザーエクスペリエンスは同じでした。この新しい機能は、追加のレイヤーの信頼を提供します。

### インスタンス管理者セットアップの簡素化 {#streamlined-instance-administrator-setup}

<!-- categories: User Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/458985)

{{< /details >}}

GitLabの新規インストールのための管理者セットアップエクスペリエンスが簡素化され、より安全になりました。初期の管理者ルートメールアドレスは現在ランダム化されており、管理者は、アクセスできるアカウントにこのメールアドレスを変更することを強制されます。以前は、このステップが遅れる可能性があり、管理者がメールアドレスの変更を忘れることがありました。

### Snowflake Data ConnectorにUser APIが追加されました {#user-api-added-to-the-snowflake-data-connector}

<!-- categories: Audit Events, Compliance Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../integration/snowflake.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13004)

{{< /details >}}

GitLab 17.2では、Snowflake Marketplaceアプリで利用可能な[GitLab Data Connector](https://app.snowflake.com/marketplace/listing/GZTYZXESENG/gitlab-gitlab-data-connector)に[Users API](../../api/users.md#list-all-users)のサポートを追加しました。これで、Users APIを使用して、セルフマネージドGitLabインスタンスからSnowflakeにユーザーデータをストリーミングできるようになりました。

### Google Cloudインテグレーションのセットアップの簡素化 {#simplified-setup-for-google-cloud-integration}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../tutorials/set_up_gitlab_google_integration/_index.md#secure-your-usage-with-google-cloud-identity-and-access-management-iam) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/454343)

{{< /details >}}

Google Cloud CLIコマンドが、Google Cloud IAMインテグレーションのワークロードアイデンティティフェデレーションを設定する際にネイティブに利用できるようになりました。以前は、ガイド付きセットアップはcURLコマンドを通じてダウンロードされたスクリプトを使用していました。また、セットアッププロセスをよりよく説明するためにヘルプテキストが追加されました。これらの改善により、グループオーナーはGoogle Cloud IAMインテグレーションをより迅速にセットアップできます。

### Wikiページのタイトルとパスフィールドを分離する {#separate-wiki-page-title-and-path-fields}

<!-- categories: Wiki -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/wiki/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/30758)

{{< /details >}}

GitLab 17.2では、Wikiページのタイトルはパスとは別になりました。以前のリリースでは、ページタイトルが変更されるとパスも変更され、ページへのリンクが壊れる可能性がありました。現在、Wikiページのタイトルが変更されても、パスは変更されません。Wikiページのパスが変更された場合でも、壊れたリンクを防ぐために自動リダイレクトが設定されます。

### Wikiサイドバーの改善 {#improvements-to-the-wiki-sidebar}

<!-- categories: Wiki -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/wiki/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/281570)

{{< /details >}}

GitLab 17.2では、Wikiがサイドバーを表示する方法にいくつかの機能強化が追加されました。現在、Wikiはサイドバーにすべてのページ（最大5000ページ）を表示し、目次（TOC）を表示し、ページを迅速に見つけるための検索バーを提供します。

以前は、サイドバーにはTOCがなかったため、ページのセクションを移動するのが困難でした。新しいTOC機能は、ページの構造を明確に確認し、異なるセクションに迅速に移動するのに役立ち、使いやすさを大幅に向上させます。

検索バーの追加により、コンテンツの発見が容易になります。サイドバーにすべてのページが表示されるようになったため、Wiki全体をシームレスに閲覧できます。

### Terraformモジュールレジストリのモジュールをドキュメント化する {#document-modules-in-the-terraform-module-registry}

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/packages/terraform_module_registry/_index.md#view-terraform-modules) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/451054)

{{< /details >}}

TerraformモジュールレジストリがReadmeファイルを表示するようになりました！この非常に要望の多かった機能により、各モジュールの目的、設定、および要件を透過的にドキュメント化できます。

以前は、この重要な情報を他のソースで検索する必要があり、モジュールを適切に評価して使用するのが困難でした。現在、モジュールドキュメントがすぐに利用できるようになったため、使用する前にモジュールの機能を迅速に理解できます。このアクセシビリティにより、組織全体でTerraformコードを自信を持って共有および再利用できます。

### イシューイベントWebhookにタイプ属性を追加する {#add-type-attribute-to-issues-events-webhook}

<!-- categories: Team Planning, Webhooks, Incident Management, Service Desk -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/integrations/webhook_events.md#work-item-events) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/467415)

{{< /details >}}

イシュー、タスク、インシデント、要件、目標と主な成果はすべて、**Issues Events** Webhookカテゴリの下でペイロードをトリガーします。これまで、イベントペイロード内でWebhookをトリガーしたオブジェクトのタイプを迅速に判断する方法はありませんでした。このリリースでは、**Issues events**、**コメント**、**Confidential issues events**、および**絵文字イベント**のトリガー内のペイロードで利用可能な`object_attributes.type`属性が導入されました。

### Go、Java、Python向け高度なSASTがベータ版で利用可能に {#gitlab-advanced-sast-available-in-beta-for-go-java-and-python}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/sast/gitlab_advanced_sast.md)

{{< /details >}}

GitLab Advanced SASTが、Ultimateのお客様向けにベータ機能として利用可能になりました。Advanced SASTは、クロスファイル、クロスファンクション分析を使用して、より高品質な結果を提供します。現在、Go、Java、Pythonをサポートしています。

ベータ期間中は、既存のSASTアナライザーを置き換えるのではなく、テストプロジェクトでAdvanced SASTを実行することをお勧めします。Advanced SASTを有効にするには、[手順](../../user/application_security/sast/gitlab_advanced_sast.md#turn-on-gitlab-advanced-sast)を参照してください。GitLab 17.2から、Advanced SASTは[`SAST.latest` CI/CDテンプレート](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/SAST.latest.gitlab-ci.yml)に含まれるようになりました。

これは、当社の反復的な[Oxeye技術の統合](https://about.gitlab.com/blog/oxeye-joins-gitlab-to-advance-application-security-capabilities/)の一部です。今後のリリースでは、Advanced SASTを一般公開に移行し、[他の言語](https://gitlab.com/groups/gitlab-org/-/epics/14312)のサポートを追加し、脆弱性がどのように流れるかをトレースするための新しいUI要素を導入する予定です。テストに関するフィードバックは、[イシュー466322](https://gitlab.com/gitlab-org/gitlab/-/issues/466322)でお待ちしております。

### APIセキュリティテストが署名付き認証リクエストをサポートするようになりました {#api-security-testing-now-supports-signed-authentication-requests}

<!-- categories: API Security -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/api_security_testing/configuration/variables.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/458825)

{{< /details >}}

APIセキュリティはすでに、スキャナーが送信するリクエストを変更できる「オーバーライド」をサポートしています。しかし、これらのオーバーライドは事前に設定する必要があり、リクエスト自体に基づいて変更することはできません。GitLab 17.2では、「リクエストごとのスクリプト」（`APISEC_PER_REQUEST_SCRIPT`）が追加され、ユーザーが各リクエストを送信する前に呼び出されるC#スクリプトを提供できるようになりました。これにより、認証の一形式として、シークレットでリクエストを「署名」するサポートが提供されます。

### コンテナスキャン: 継続的脆弱性スキャンOSサポート {#container-scanning-continuous-vulnerability-scanning-os-support}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/container_scanning/continuous_container_scanning/_index.md#supported-package-types) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/10174)

{{< /details >}}

コンテナスキャンMVCの継続的脆弱性スキャンのフォローアップとして、17.2中にAPKおよびRPMオペレーティングシステムパッケージバージョンのサポートを追加しました。

この機能強化により、当社のアナライザーは、[APK](https://gitlab.com/gitlab-org/gitlab/-/issues/428703)および[RPM](https://gitlab.com/gitlab-org/gitlab/-/issues/428941)オペレーティングシステムpurlタイプのパッケージバージョンを比較することで、コンテナスキャンの勧告に対する継続的脆弱性スキャンを完全にサポートできるようになります。

注として、キャレット（`^`）を含むRPMバージョンはサポートされていません。これらのバージョンをサポートするための作業は、この[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/459969)で追跡されています。

### DASTアナライザーの更新 {#dast-analyzer-updates}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dast/browser/checks/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/13411)

{{< /details >}}

17.2リリースマイルストーン中に、以下の更新を公開しました。

1. 3つの新しいチェックを追加しました:

- チェック506.1は、Polyfill.io CDNの乗っ取りによって侵害されている可能性のあるリクエストURLを特定するパッシブチェックです。
- チェック384.1は、悪意のあるアクターが有効なセッション識別子を再利用できる可能性があるセッション固定の脆弱性を特定するパッシブチェックです。
- チェック16.11は、プロダクションサーバーでTRACE HTTPデバッグメソッドが有効になっている場合に、機密情報が誤って公開される可能性があることを特定するアクティブチェックです。

1. 誤検出を減らすために、以下のバグに対処しました:

- DASTチェック614.1（セキュア属性のない機密クッキー）および1004.1（HttpOnly属性のない機密クッキー）は、サイトが過去に有効期限を設定してクッキーをクリアした場合に、発見を作成しなくなりました。
- DASTチェック1336.1（サーバーサイドテンプレートインジェクション）は、攻撃の成功を判断するために500 HTTPレスポンスステータスコードに依存しなくなりました。

1. 以下の機能強化を追加しました:

- すべてのレスポンスヘッダーがDAST脆弱性発見における証拠として表示されるようになりました。この追加コンテキストにより、発見のトリアージに費やす時間が短縮されます。
- Sitemap.xmlファイルは、追加のURLについてクロールされるようになり、ターゲットWebサイトのカバレッジが向上しました。

### APIファズテストが署名付き認証リクエストをサポートするようになりました {#api-fuzz-testing-now-supports-signed-authentication-requests}

<!-- categories: Fuzz Testing -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/api_fuzzing/configuration/variables.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/458825)

{{< /details >}}

APIファジングはすでに、スキャナーが送信するリクエストを変更できる「オーバーライド」をサポートしています。しかし、これらのオーバーライドは事前に設定する必要があり、リクエスト自体に基づいて変更することはできません。GitLab 17.2では、「リクエストごとのスクリプト」（`FUZZAPI_PER_REQUEST_SCRIPT`）が追加され、ユーザーが各リクエストを送信する前に呼び出されるC#スクリプトを提供できるようになりました。これにより、認証の一形式として、シークレットでリクエストを「署名」するサポートが提供されます。

### セルフマネージド向けにシークレットプッシュ保護が利用可能になり、潜在的な漏洩の警告が改善されました {#secret-push-protection-now-available-for-self-managed-and-improved-warnings-of-potential-leaks}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/secret_detection/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13107)

{{< /details >}}

17.2リリースマイルストーン中に、以下の更新を公開しました:

- シークレットプッシュ保護ベータ版がセルフマネージドのお客様向けに利用可能になりました。管理者が[機能をインスタンス全体で有効](../../user/application_security/secret_detection/secret_push_protection/_index.md#allow-the-use-of-secret-push-protection-in-your-gitlab-instance)にした後、ドキュメントに従ってプロジェクトで[プッシュ保護を有効](../../user/application_security/secret_detection/secret_push_protection/_index.md#enable-secret-push-protection-in-a-project)にしてください。
- [テキストコンテンツにおける潜在的な漏洩の警告](../../user/application_security/secret_detection/client/_index.md)がより詳細になり、イシュー、エピック、またはMRにおける説明やコメントで、どのような種類のシークレットが漏洩しようとしているかを理解しやすくなりました。

### パイプラインスケジュールのソートオプション {#sort-options-for-pipeline-schedules}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/pipelines/schedules.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/37246)

{{< /details >}}

これで、パイプラインスケジュールリストを説明、参照、次回の実行、作成日、更新日でソートできるようになりました。

### `rules:changes:compare_to`がCI/CD変数をサポートするようになりました {#ruleschangescompare_to-now-supports-cicd-variables}

<!-- categories: Pipeline Composition, Variables -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/yaml/_index.md#ruleschangescompare_to) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/369916)

{{< /details >}}

GitLab 15.3で、`rules:change`に[`compare_to`キーワード](../../ci/yaml/_index.md#ruleschangescompare_to)を導入しました。これにより、比較対象の正確な参照を定義することが可能になりました。GitLab 17.2から、このキーワードでCI/CD変数を使用できるようになり、複数のジョブで`compare_to`値を定義および再利用しやすくなりました。

### GitLab Runner 17.2 {#gitlab-runner-172}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 17.2をリリースします！GitLab Runnerは、軽量で高度にスケールするエージェントであり、CI/CDジョブを実行し、結果をGitLabインスタンスに送り返します。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [AWS](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29222) EC2インスタンス向けのGitLab Runnerフリーティングプラグイン（GA）
- [Runner `livenessProbe`および`readinessProbe`の設定を許可する](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/issues/545)
- [Kubernetes executor向けの`umask 0000`コマンドを有効/無効にする機能](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28867)
- [GitLab Runner Operator向けのRed Hat OpenShift 4.16のサポート](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator/-/issues/203)

#### バグ修正 {#bug-fixes}

- [GitLab Runnerアップグレードにより、すべてのキャッシュボリュームが削除される](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/30876)

すべての変更のリストについては、GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-2-stable/CHANGELOG.md)を参照してください。

### ワークスペース向けの新しいエージェント認可戦略 {#new-agent-authorization-strategy-for-workspaces}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/workspace/gitlab_agent_configuration.md)

{{< /details >}}

このリリースでは、従来の戦略の制約に対処しつつ、グループオーナーと管理者により多くの制御と柔軟性を提供するために、ワークスペース向けの新しい認可戦略を実装しました。新しい認可戦略により、グループオーナーと管理者は、ワークスペースをホストするためにどのクラスターエージェントを使用するかを制御できます。

スムーズな移行を確実にするため、従来の認可戦略を使用しているユーザーは、新しい戦略に自動的に移行されます。ワークスペースをサポートする既存のエージェントは、これらのエージェントが配置されているルートグループで自動的に許可されます。この移行は、これらのエージェントがルートグループ内の異なるグループで許可されていた場合でも発生します。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.2)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.2)
- [UI改善](https://papercuts.gitlab.com/?milestone=17.2)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
