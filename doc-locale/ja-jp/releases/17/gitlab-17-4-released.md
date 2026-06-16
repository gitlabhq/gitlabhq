---
stage: Release Notes
group: Monthly Release
date: 2024-09-19
title: "GitLab 17.4リリースノート"
description: "GitLab 17.4は、よりコンテキスト認識型のGitLab Duoコード提案を開いているタブを使用してリリースされました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024年9月19日、GitLab 17.4が以下の機能とともにリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Archish Thakkar {#this-months-notable-contributor-archish-thakkar}

誰もがGitLabコミュニティのコントリビューターを[推薦](https://gitlab.com/gitlab-org/developer-relations/contributor-success/team-task/-/issues/490)できます！活躍中の候補者を支援するか、新しい推薦を追加してください！ 🙌

Archish Thakkarは、今年GitLabのトップコントリビューターの一人であり、[46件のクローズされたイシュー](https://gitlab.com/groups/gitlab-org/-/issues/?sort=created_date&state=closed&assignee_username%5B%5D=archish27&first_page_size=100)と[119件のMRをマージ](https://gitlab.com/groups/gitlab-org/-/merge_requests?assignee_username%5B%5D=archish27&first_page_size=100&sort=created_date&state=merged)しました。これらのコントリビュートにより、Archishは過去2回の[GitLabハッカソン](https://gitlab-community.gitlab.io/community-projects/merge-request-leaderboard/?&createdAfter=2024-08-26&createdBefore=2024-09-02&mergedBefore=2024-10-03&label=Hackathon)でトップの座を獲得しました。彼は[Middleware](https://middleware.io/)のシニアソフトウェアエンジニアであり、情熱的なオープンソースのコントリビューターです。

ArchishはGitLabのスタッフバックエンドエンジニア、エンジニアリング生産性担当の[Peter Leitzen](https://gitlab.com/splattael)によって推薦されました。この推薦は、GitLabのスタッフバックエンドエンジニアである[Max Woolf](https://gitlab.com/mwoolf)と、GitLabのシニアバックエンドエンジニアである[James Nutt](https://gitlab.com/jnutt)によってサポートされました。Archishのコントリビュートは過去2ヶ月間で増加しており、GitLabのコードベースの改善に一貫して卓越したコミットメントを示し、複数のQoL（Quality of Life）修正にコントリビュートし、技術的負債を削減しました。

ArchishとGitLabの他のオープンソースのコントリビューターの皆様、GitLabを共同で作成していただき、誠にありがとうございます！

## 主要な機能 {#primary-features}

### よりコンテキスト認識型のGitLab Duoコード提案を開いているタブを使用して提供 {#more-context-aware-gitlab-duo-code-suggestions-using-open-tabs}

<!-- categories: Editor Extensions, Code Suggestions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Pro, Duo Enterprise
- リンク: [ドキュメント](../../user/project/repository/code_suggestions/context.md) | [関連イシュー](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/206)

{{< /details >}}

他の開いているタブの内容を使用して、コーディングワークフローを向上させ、よりコンテキスト認識型のコード提案を受け取ります。

このコード提案の改善により、エディタで開いているタブの内容が使用されるようになり、より関連性の高い正確なコードの推奨が提供されます。

### すべてのチェックが合格した場合の自動マージ {#auto-merge-when-all-checks-pass}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/merge_requests/auto_merge.md)

{{< /details >}}

MRは、マージ可能になる前に合格しなければならない多くの必須チェックがあります。これらのチェックには、承認、未解決にするべきスレッド、パイプライン、およびその他の満たすべき項目が含まれます。コードをマージする責任がある場合、これらすべてのイベントを追跡し、いつ戻ってMRをマージできるかを確認するのは難しい場合があります。

GitLabは、MRのすべてのチェックに対する**Auto-merge**をサポートするようになりました。自動マージにより、マージする資格のあるユーザーは、必要なすべてのチェックが完了する前でも、MRを**Auto-merge**に設定できます。MRがそのライフサイクルを通じて続行すると、最後の失敗したチェックが合格した後、MRは自動的にマージされます。

私たちは、MRワークフローを加速するこの改善に本当に興奮しています。この機能に関するフィードバックは、[イシュー438395](https://gitlab.com/gitlab-org/gitlab/-/issues/438395)に残すことができます。

### Web IDEで拡張機能マーケットプレースが利用可能に {#extension-marketplace-now-available-in-the-web-ide}

<!-- categories: Web IDE -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/web_ide/_index.md#manage-extensions)

{{< /details >}}

GitLab.comのWeb IDEで拡張機能マーケットプレースのローンチを発表できることを嬉しく思います。拡張機能マーケットプレースを使用すると、サードパーティの拡張機能を見つけ、インストールし、管理して、開発エクスペリエンスを向上させることができます。一部の拡張機能は、ローカルのランタイム環境を必要とするため、Web専用バージョンと互換性がありません。ただし、何千もの拡張機能から選択して、生産性を向上させたり、ワークフローをカスタマイズしたりできます。

拡張機能マーケットプレースはデフォルトで無効になっています。開始するには、[user preferences](https://gitlab.com/-/profile/preferences)の**インテグレーション**セクションで拡張機能マーケットプレースを有効にすることができます。[エンタープライズユーザー](../../user/enterprise_user/_index.md)の場合、トップレベルグループのオーナーロールを持つユーザーのみが拡張機能マーケットプレースを有効にできます。

### ワークスペースへのセキュアなsudoアクセス {#secure-sudo-access-for-workspaces}

<!-- categories: Remote Development -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/workspace/configuration.md#configure-sudo-access-for-a-workspace)

{{< /details >}}

これで、ワークスペースのsudoアクセスを設定できるようになり、開発環境に依存関係を直接インストール、設定、実行することがこれまで以上に簡単になりました。シームレスな開発エクスペリエンスを確保するために、3つのセキュアな方法を実装しました:

- Sysbox
- Kata Containers
- ユーザーネームスペース

この機能により、ワークフローとプロジェクトのニーズに合わせて環境を完全にカスタマイズできます。

### Kubernetesリソースイベントのリスト {#list-kubernetes-resource-events}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/kubernetes_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/470041)

{{< /details >}}

GitLabは、ポッドとストリーミングポッドログのリアルタイムビューを提供します。しかしこれまで、UIからリソース固有のイベント情報を表示していなかったため、Kubernetesのデプロイをデバッグするには、サードパーティツールを使用する必要がありました。このリリースでは、[Kubernetes用ダッシュボード](../../ci/environments/kubernetes_dashboard.md)のリソース詳細ビューにイベントが追加されます。

これは、UIにイベントを追加した最初の試みです。現在、イベントはリソース詳細ビューを開くたびに更新されます。リアルタイムイベントストリーミングの開発は、[イシュー470042](https://gitlab.com/gitlab-org/gitlab/-/issues/470042)で追跡できます。

### GitLab PagesがワイルドカードDNSレコードなしで一般提供されました {#gitlab-pages-without-wildcard-dns-is-generally-available}

<!-- categories: Pages -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/pages/_index.md#dns-configuration-for-single-domain-sites) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13404)

{{< /details >}}

以前は、GitLab Pagesプロジェクトを作成するには、`name.example.io`または`name.pages.example.io`のような形式のドメインが必要でした。この要件は、ワイルドカードDNSレコードとTLS証明書をセットアップする必要があることを意味しました。このリリースでは、DNSワイルドカードなしでGitLab Pagesプロジェクトをセットアップすることがベータから一般提供に移行しました。

ワイルドカード証明書の要件を削除することで、GitLab Pagesに関連する管理オーバーヘッドが軽減されます。一部の顧客は、ワイルドカードDNSレコードまたは証明書に対する組織的な制限のため、GitLab Pagesを使用できません。

### GitLab Pagesの並列デプロイ（ベータ版） {#gitlab-pages-parallel-deployments-in-beta}

<!-- categories: Pages -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/pages/_index.md#parallel-deployments) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10914)

{{< /details >}}

このリリースでは、Pagesの並列デプロイ（ベータ版）が導入されます。これで、変更を簡単にプレビューし、GitLab Pagesサイトの並列デプロイを管理できるようになりました。この機能強化により、新しいアイデアをシームレスに実験できるため、自信を持ってサイトをテストおよび改良できます。早期にイシューを発見することで、ライブサイトが安定して洗練された状態を保ち、GitLab Pagesのすでに優れた基盤をさらに発展させることができます。

さらに、アプリケーションやWebサイトの異なる言語バージョンをデプロイする場合、並列デプロイはローカリゼーションに役立ちます。

### GitLab Duo Chatでイシューのディスカッションを要約 {#summarize-issue-discussions-with-gitlab-duo-chat}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- アドオン: Duo Enterprise
- リンク: [ドキュメント](../../user/discussions/_index.md#summarize-issue-discussions-with-gitlab-duo-chat)

{{< /details >}}

長期間にわたるイシューのディスカッションに追いつくには、かなりの時間投資が必要です。このリリースにより、AIが生成するイシューのディスカッションの要約がGitLab Duo Chatと統合され、GitLab.com、Self-Managedインスタンス、およびDedicatedのお客様向けに一般提供されるようになりました。

### 高度なSASTが一般提供されました {#advanced-sast-is-generally-available}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/sast/gitlab_advanced_sast.md)

{{< /details >}}

当社の高度なSAST (SAST) スキャナーが、すべてのUltimateのお客様向けに一般提供されることを発表できることを嬉しく思います。

高度なSASTは、今年初めに[Oxeyeから取得した](https://about.gitlab.com/blog/oxeye-joins-gitlab-to-advance-application-security-capabilities/)テクノロジーを搭載した新しいスキャナーです。社内のセキュリティ研究に基づいたルールを持つ独自の検出エンジンを使用し、ファーストパーティコードの悪用可能な脆弱性を特定します。より正確な結果を提供することで、デベロッパーやセキュリティチームが誤検出のノイズを振り分ける必要がなくなります。

新しいスキャンエンジンに加えて、GitLab 17.4には以下が含まれます:

- 脆弱性のファイルと関数を横断するパスをトレースする新しい[コードフロービュー](../../user/application_security/vulnerabilities/_index.md#vulnerability-code-flow)。
- 高度なSASTが、以前のGitLab SASTスキャナーからの既存の結果を「引き継ぐ」ことを可能にする自動移行。

詳細については、[アナウンスブログ](https://about.gitlab.com/blog/gitlab-advanced-sast-is-now-generally-available/)をご覧ください。

### UIでCI/CD変数の値を非表示にする {#hide-cicd-variable-values-in-the-ui}

<!-- categories: Variables -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](https://new.docs.gitlab.com/ci/variables/#define-a-cicd-variable-in-the-ui) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/29674)

{{< /details >}}

プロジェクト設定に保存された後、誰にも変数の値を見られたくない場合があります。CI/CD変数を作成する際に、新しい**マスクして非表示**の表示レベルオプションを選択できるようになりました。このオプションを選択すると、変数の値がCI/CD設定UIで永続的にマスクされ、今後誰にも値が表示されないように制限され、データの表示レベルが低下します。

## 規模とデプロイ {#scale-and-deployments}

### Omnibusの改善 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/)

{{< /details >}}

GitLab 17.4には、新しいGitLabインストール用のPostgreSQL 16がデフォルトで含まれています。

GitLab 17.7にはOpenSSL V3が含まれます。これは、送信接続用のTLS 1.2以上の最小要件、およびTLS証明書用の少なくとも112ビットの暗号化を満たさない外部インテグレーション設定のOmnibusインスタンスに影響を与えます。詳細については、当社の[OpenSSLアップグレードドキュメント](https://docs.gitlab.com/omnibus/settings/ssl/openssl_3.html)を確認するか、ご自身のインスタンスが影響を受けるかどうかわからない場合はご確認ください。

### グループまたはプロジェクトに招待されたグループを、グループまたはプロジェクトAPIを使用してリスト表示 {#list-groups-invited-to-a-group-or-project-using-the-groups-or-projects-api}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/groups.md#list-invited-groups) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/465207)

{{< /details >}}

グループまたはプロジェクトに招待されたグループを取得するために、グループAPIおよびプロジェクトAPIに新しいエンドポイントを追加しました。この機能は、グループまたはプロジェクトのメンバーページでのみ利用可能です。この追加により、グループやプロジェクトのメンバーシップ管理を自動化しやすくなることを願っています。エンドポイントは、ユーザーあたり1分あたり60件のリクエストにレート制限されます。

### グループAPIを使用してドメインでグループアクセスを制限する {#restrict-group-access-by-domain-with-the-groups-api}

<!-- categories: API, Groups & Projects -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/groups.md#update-group-attributes) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/351494)

{{< /details >}}

以前は、UIのグループレベルでのみドメイン制限を追加できました。これで、グループAPIの新しい`allowed_email_domains_list`属性を使用しても、これを実行できます。

### グループおよびプロジェクトメンバーのソース表示の改善 {#improved-source-display-for-group-and-project-members}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/members/_index.md#membership-types) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/431066)

{{< /details >}}

グループおよびプロジェクトのメンバーページで、ソース列の表示を簡素化しました。直接メンバーは引き続き`Direct member`として示されます。継承されたメンバーは、`Inherited from`の後にグループ名が続く形で表示されるようになりました。グループまたはプロジェクトにグループを招待して追加されたメンバーは、`Invited group`の後にグループ名が続く形で表示されます。親グループに追加された招待済みグループから継承したメンバーについては、メンバーシップを管理するユーザーのために表示をアクション可能に保つため、最終ステップを表示するようになりました。

### GitLab Duoシート割り当てメール {#gitlab-duo-seat-assignment-email}

<!-- categories: Seat Cost Management -->

{{< details >}}

- プラン: Premium、Ultimate
- アドオン: Duo Pro
- リンク: [ドキュメント](../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/164104)

{{< /details >}}

Self-Managedインスタンスのユーザーは、GitLab Duoシートが割り当てられるとメールを受信するようになりました。以前は、誰かに言われるか、GitLab UIで新しい機能に気づかない限り、シートが割り当てられたことを知りませんでした。

このメールを無効にするには、管理者は`duo_seat_assignment_email_for_sm`FFを無効にできます。

### 失敗したWebhookリクエストをAPIで再送信する {#resend-failed-webhook-requests-with-the-api}

<!-- categories: Webhooks -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/project_webhooks.md#resend-a-project-webhook-event) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/372826)

{{< /details >}}

以前は、GitLabはWebhookリクエストの再送信機能をUIでのみ提供しており、多くのリクエストが失敗した場合には非効率的でした。

失敗したWebhookリクエストをプログラムで処理できるように、このリリースではコミュニティのコントリビュートのおかげで、再送信用のAPIエンドポイントを追加しました:

- [プロジェクトWebhookリクエスト](../../api/project_webhooks.md#resend-a-project-webhook-event)
- [グループWebhookリクエスト](../../api/group_webhooks.md#resend-group-hook-event) (PremiumおよびUltimateのみ)

できるようになりました:

1. [プロジェクトフック](../../api/project_webhooks.md#list-project-webhook-events)または[グループフック](../../api/group_webhooks.md#list-all-group-hook-events)のイベントのリストを取得する。
1. リストをフィルタリングして失敗を表示します。
1. 任意のイベントの`id`を使用して再送信します。

[Phawin](https://gitlab.com/lifez)の[このコミュニティコントリビュート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151130)に感謝します！

### Webhookリクエストの冪等キー {#idempotency-keys-for-webhook-requests}

<!-- categories: Webhooks -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/integrations/webhooks.md#delivery-headers) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/388692)

{{< /details >}}

このリリースから、Webhookリクエストのヘッダーに冪等キーをサポートします。冪等キーは、Webhookの再試行全体で一貫性を保つ一意のIDであり、Webhookクライアントが再試行を検出できるようにします。`Idempotency-Key`ヘッダーを使用して、インテグレーションに対するWebhookの影響の冪等性を確保します。

[Van](https://gitlab.com/van.m.anderson)の[このコミュニティコントリビュート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160952)に感謝します！

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### コードインテリジェンス用のCI/CDコンポーネント {#cicd-component-for-code-intelligence}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/code_intelligence.md#with-the-cicd-component)

{{< /details >}}

GitLabのコードインテリジェンスは、リポジトリを閲覧する際にコードナビゲーション機能を提供します。コードナビゲーションの開始は、CI/CDジョブを設定する必要があるため、しばしば複雑です。このジョブには、正しい出力とアーティファクトを提供するためのカスタムスクリプトが必要になる場合があります。

GitLabは、より簡単なセットアップのために公式の[コードインテリジェンスCI/CDコンポーネント](https://gitlab.com/explore/catalog/components/code-intelligence)をサポートするようになりました。[コンポーネントの使用](../../ci/components/_index.md#use-a-component)に関する指示に従って、このコンポーネントをプロジェクトに追加します。これにより、GitLabでのコードインテリジェンスの採用が大幅に簡素化されます。

現在、コンポーネントは以下の言語をサポートしています:

- Goバージョン1.21以降。
- TypeScriptまたはJavaScript。

新しいコンポーネントの言語サポートを拡大するために、[利用可能なSCIPインデクサー](https://github.com/sourcegraph/scip?tab=readme-ov-file#tools-using-scip)の評価を続けます。ある言語のサポートを追加することに興味がある場合は、[コードインテリジェンスコンポーネント](https://gitlab.com/components/code-intelligence)プロジェクトでMRを開いてください。

### MR内のリンクされたファイルが最初に表示されます {#linked-files-in-merge-request-show-first}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/merge_requests/changes.md#show-a-linked-file-first)

{{< /details >}}

MR内の特定のファイルへのリンクを共有する場合、それは多くの場合、そのファイル内の何かを見てほしいからです。以前は、MRは参照した特定の場所にスクロールする前に、すべてのファイルを読み込む必要がありました。ファイルに直接リンクすることは、MRでのコラボレーションの速度を向上させる優れた方法です:

1. 最初に表示するファイルを検索します。ファイル名を右クリックして、そのファイルへのリンクをコピーします。
1. そのリンクにアクセスすると、選択したファイルが一覧の一番上に表示されます。ファイルブラウザには、ファイル名の横にリンクアイコンが表示されます。

リンクされたファイルに関するフィードバックは、[イシュー439582](https://gitlab.com/gitlab-org/gitlab/-/issues/439582)に残すことができます。

### JetBrains IDEでGitLab DuoにOAuthで認証する {#authenticate-with-oauth-for-gitlab-duo-in-jetbrains-ides}

<!-- categories: Editor Extensions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../editor_extensions/jetbrains_ide/setup.md#configure-gitlab-duo) | [関連エピック](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/70)

{{< /details >}}

JetBrains向けの当社のGitLab Duoプラグインは、より安全で効率的なオンボーディングプロセスを提供するようになりました。OAuthで素早く安全にサインインできます。既存のワークフローとシームレスに統合され、パーソナルアクセストークンは必要ありません！

### 保護環境への非デプロイメントジョブは、手動ジョブに変換されません {#non-deployment-jobs-to-protected-environments-arent-turned-into-manual-jobs}

<!-- categories: Environment Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/jobs/job_control.md#types-of-manual-jobs) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/390025)

{{< /details >}}

実装上のイシューにより、`action: prepare`、`action: verify`、および`action: access`のジョブは、保護環境に対して実行されると手動ジョブになります。これらのジョブは、追加の承認は必要ありませんが、実行するには手動での操作が必要です。

[イシュー390025](https://gitlab.com/gitlab-org/gitlab/-/issues/390025)は、これらのジョブが手動ジョブに変換されないように、実装を修正することを提案しています。この提案された変更後、現在の動作を維持するには、[ジョブを手動で明示的に設定する](../../ci/jobs/job_control.md#types-of-manual-jobs)必要があります。

今のところ、`prevent_blocking_non_deployment_jobs`機能フラグを有効にすることで、新しい実装に変更できます。

提案された破壊的な変更は、`environment.action: prepare | verify | access`値の動作を区別することを目的としています。`environment.action: access`キーワードは、現在の動作に最も近い状態を維持します。

将来の互換性イシューを防ぐために、これらのキーワードの使用を今すぐレビューする必要があります。これらの提案された変更の詳細については、以下のイシューで確認できます:

- [イシュー437132](https://gitlab.com/gitlab-org/gitlab/-/issues/437132)
- [イシュー437133](https://gitlab.com/gitlab-org/gitlab/-/issues/437133)
- [イシュー437142](https://gitlab.com/gitlab-org/gitlab/-/issues/437142)

### クラスターUIからFluxの調整をトリガーする {#trigger-a-flux-reconciliation-from-the-cluster-ui}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/kubernetes_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/434248)

{{< /details >}}

Fluxを設定して指定された間隔で調整をトリガーすることができますが、即時調整が必要な状況もあります。過去のリリースでは、CI/CDパイプラインまたはコマンドラインから調整をトリガーすることができました。GitLab 17.4では、追加の設定なしでKubernetesのダッシュボードから調整をトリガーすることができるようになりました。

リコンシリエーションをトリガーするには、設定済みのダッシュボードに移動し、Fluxステータスバッジを選択します。

### オプションのトークン有効期限 {#optional-token-expiration}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/settings/account_and_limit_settings.md#require-expiration-dates-for-new-access-tokens) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/470192)

{{< /details >}}

管理者は、パーソナルアクセストークン、プロジェクトアクセストークン、およびグループアクセストークンに強制的な有効期限を適用するかどうかを決定できるようになりました。管理者がこの設定を無効にすると、新しく生成されるアクセストークンには有効期限は必要ありません。デフォルトではこの設定は有効になっており、許可される最大ライフタイムよりも短い有効期限が必要です。この設定はGitLab 16.11以降で利用可能です。

### 複数のコンプライアンスフレームワークで検索 {#search-by-multiple-compliance-frameworks}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_center/compliance_projects_report.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/462943)

{{< /details >}}

GitLab 17.3では、ユーザーがプロジェクトに複数のコンプライアンスフレームワークを追加できる機能を提供しました。

これで、複数のコンプライアンスフレームワークで検索できるようになり、複数のコンプライアンスフレームワークが関連付けられているプロジェクトを検索するのが簡単になりました。

### セキュリティポリシーにリンクされたプロジェクト内のパイプライン実行ポリシーYAMLファイルへの読み取りアクセスを許可する {#grant-read-access-to-pipeline-execution-yaml-files-in-projects-linked-to-security-policies}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/469439)

{{< /details >}}

GitLab 17.4では、すべてのリンクされたプロジェクトの`pipeline-execution.yml`ファイルへの読み取りアクセスを許可するために使用できるセキュリティポリシーに設定を追加しました。この設定により、プロジェクト全体でパイプライン実行をグローバルに適用するユーザー、ボット、またはトークンを有効にするための柔軟性が向上します。例えば、グループまたはプロジェクトアクセストークンがセキュリティポリシーの設定を読み取り、パイプライン実行中にパイプラインをトリガーすることができるようにすることができます。依然として、セキュリティポリシープロジェクトリポジトリまたはYAMLを直接表示することはできません。設定はパイプライン作成中にのみ使用されます。

設定を設定するには、共有したいセキュリティポリシープロジェクトに移動します。**設定 > 一般 > 可視性、プロジェクトの機能、権限**を選択し、**パイプライン実行ポリシー**までスクロールし、**Grant access to this repository for projects linked to it as the security policy project source for security policies**切替を有効にします。

### パイプライン実行ポリシーパイプラインでの名前の衝突があるジョブのサフィックスをサポートする {#support-suffix-for-jobs-with-name-collisions-in-pipeline-execution-policy-pipelines}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/pipeline_execution_policies.md#pipeline_execution_policy-schema) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/473189)

{{< /details >}}

[パイプライン実行ポリシーの17.2リリース](https://about.gitlab.com/releases/2024/07/18/gitlab-17-2-released/#pipeline-execution-policy-type)に対する機能強化として、ポリシー作成者は、ジョブ名の衝突を適切に処理するようにパイプライン実行ポリシーを設定できるようになりました。パイプライン実行ポリシーの`policy.yml`を使用すると、次のオプションを設定できます:

- `suffix: on_conflict`は、ポリシージョブの名前を変更することで衝突を適切に処理するようにポリシーを設定し、これが新しいデフォルトの動作となります。
- `suffix: never`は、すべてのジョブ名が一意であることを強制し、衝突が発生した場合にパイプラインを失敗させます。これは17.2以降のデフォルトの動作でした。

この改善により、パイプライン実行ポリシー内で実行されるセキュリティおよびコンプライアンスジョブが常に実行されることを保証しつつ、ダウンストリームのデベロッパーへの不要な影響も防止できます。

次の機能強化では、ポリシーエディタ内に設定オプションを導入します。

### サイズ変更可能なWikiサイドバー {#resizable-wiki-sidebar}

<!-- categories: Wiki -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/wiki/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154167)

{{< /details >}}

これで、Wikiサイドバーを調整して長いページタイトルを表示できるようになり、コンテンツ全体の発見可能性が向上しました。Wikiコンテンツが増えるにつれて、サイズ変更可能なサイドバーは、複雑な階層や広範囲にわたるページリストをより効率的に管理し、閲覧するのに役立ちます。

### CycloneDX 1.6 SBOMのインジェストをサポート {#support-for-ingesting-cyclonedx-16-sboms}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/472837)

{{< /details >}}

GitLab 15.3は[CycloneDX SBOMのインジェスト](../../ci/yaml/artifacts_reports.md#artifactsreportscyclonedx)をサポートしました。

GitLab 17.4では、CycloneDXバージョン1.6 SBOMのインジェストのサポートを追加しました。

ハードウェア（HBOM）、サービス（SaaSBOM）、およびAI/MLモデル（AI/ML-BOM）に関連するフィールドは、現在サポートされていません。これらのBOMに関連するデータを含むSBOMは処理されますが、データは分析されたりユーザーに提示されたりすることはありません。これらの他のBOMタイプのサポートは、この[エピック](https://gitlab.com/groups/gitlab-org/-/epics/14989)で追跡されています。

### 削除されたSASTアナライザーの自動クリーンアップ {#automatic-cleanup-for-removed-sast-analyzers}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/sast/analyzers.md#analyzers-that-have-reached-end-of-support)

{{< /details >}}

[GitLab 17.0](../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-170) 、[16.0](../../update/deprecations.md#sast-analyzer-coverage-changing-in-gitlab-160) 、および[15.4](../../update/deprecations.md#sast-analyzer-consolidation-and-cicd-template-changes)では、GitLab SASTを合理化し、より少ない別個のアナライザーを使用してコードの脆弱性をスキャンするようにしました。

現在、GitLab 17.3.1以降にアップグレードすると、1回限りのデータ移行により、[サポート終了に達したアナライザー](../../user/application_security/sast/analyzers.md#analyzers-that-have-reached-end-of-support)からの残りの脆弱性が自動的に解決されます。これにより、脆弱性レポートがクリーンアップされ、最新のアナライザーによって依然として検出される脆弱性に集中できます。

この移行は、確認または無視していない脆弱性のみを解決し、[Semgrepベースのスキャンに自動的に翻訳された](../../user/application_security/sast/analyzers.md#transition-to-semgrep-based-scanning)脆弱性には影響しません。

### Anthropic APIキーのシークレット検出サポート {#secret-detection-support-for-anthropic-api-keys}

<!-- categories: Secret Detection -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/secret_detection/detected_secrets.md)

{{< /details >}}

パイプライン側とクライアント側の両方のシークレット検出が、[Anthropic](https://www.anthropic.com/) APIキーの検出をサポートするようになりました。

### JaCoCoのテストカバレッジ可視化サポート（ベータ版）が利用可能に {#jacoco-support-for-test-coverage-visualization-available-in-beta}

<!-- categories: Code Testing and Coverage -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/testing/code_coverage/jacoco.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/227345)

{{< /details >}}

これで、JaCoCoカバレッジレポート（カバレッジ計算の人気のある標準）をMR内で使用できます。この機能はベータ版として利用可能ですが、JaCoCoカバレッジレポートをすぐに使用したい人なら誰でもテストできます。フィードバックがある場合は、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/479804)へのコントリビュートをお願いします。

### GitLab Runner 17.4 {#gitlab-runner-174}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 17.4もリリースします！GitLab Runnerは、CI/CDジョブを実行し、その結果をGitLabインスタンスに送信する、拡張性の高いビルドエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [Azureコンピューティング用GitLab Runnerフリートプラグイン (GA)](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29223)

#### バグ修正 {#bug-fixes}

- [Kubernetes executorジョブが完了する前にキャンセルされた場合、ジョブログの`after_script`セクションに`step_script`の内容全体が表示される](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37952)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/17-4-stable/CHANGELOG.md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.4)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=17.4)
- [UI改善](https://papercuts.gitlab.com/?milestone=17.4)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
