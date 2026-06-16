---
stage: Release Notes
group: Monthly Release
date: 2024-02-15
title: "GitLab 16.9リリースノート"
description: "GitLab 16.9がリリースされ、GitLab Duo Chatベータ版がPremiumで利用可能になりました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024年2月15日に、GitLab 16.9が以下の機能とともにリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター {#this-months-notable-contributor}

RaviはGitLabの脆弱性研究グループと積極的に協力し、[GitLab SAST](https://gitlab.com/gitlab-org/security-products/sast-rules)における高い誤検出結果に対処しています。

Raviは、GitLabのカスタマーサクセスマネージャーである[Rohan Shah](https://gitlab.com/rmsrohan)氏によって推薦されました。Rohan氏は、GitLab SASTで使用されている[検出ルール](../../user/application_security/sast/rules.md)に対するRaviの著しい改善を評価しました。[Dinesh Bolkensteyn](https://gitlab.com/dbolkensteyn)（GitLabのシニア脆弱性研究者）は、「Raviのフィードバックは的を射ており、直接行動に移せるもので、多くのSASTルールを改善することができました」と付け加えました。

Ravi Dharmawan（通称ravidhr）は、GoTo Groupで情報セキュリティアーキテクトとして働いています。彼は主に、セキュア設計レビュー、ソースコードレビュー、およびペネトレーションテストを担当しています。RaviはOSCP + eWPTXv2の認定を受けています。

Ianは、[GitLabフォーラムでユーザーをサポート](https://forum.gitlab.com/u/iwalker/activity)する活動で表彰された最初のGitLab MVPです。[Michael Friedrich](https://gitlab.com/dnsmichi)氏（GitLabのシニアデベロッパーアドボケート）と、[Fatima Sarah Khalid](https://gitlab.com/sugaroverflow)氏（GitLabのデベロッパーアドボケート）の両名が、GitLabのセットアップや利用に関するユーザーからの質問に答えることで、コミュニティにとってより良いフォーラムを構築するための継続的な努力に対してIanを推薦しました。

IanはUpWare Sp. z o.o.でシステムおよびセキュリティコンサルタントとして働いており、主にRed Hat OpenShiftおよびLinux関連のあらゆる作業を行っています。彼はRed Hat認定RHCSA + RHCEであり、2017年以来、自身のセルフホスト型GitLabインスタレーションを管理、保守、サポートしています。Ianは3年以上にわたりGitLabのフォーラムで定期的に活動しており、2,600件以上の役立つ回答、480件の役立つコミュニティモデレーションフラグ、240件のソリューションを提供しています。

RaviとIan、ありがとうございます！🙌

## 主要な機能 {#primary-features}

### GitLab Duo Chatベータ版がPremiumで利用可能に {#gitlab-duo-chat-beta-now-available-in-premium}

<!-- categories: Duo Chat -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/gitlab_duo_chat/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11251)

{{< /details >}}

16.8で、GitLab Duo ChatはSelf-Managedインスタンスで利用可能になりました。16.9では、チャットはまだベータ版ですが、Premiumのお客様にご利用いただけるようになります。

GitLab Duo Chatは次のことが可能です:

- イシュー、エピック、コードを説明または要約します。
- これらのアーティファクトについて具体的な質問に答えます。例えば、「このイシューで提案されている解決策に関するコメントで提起されたすべての引数を収集してください」といった質問です。
- これらのアーティファクトの情報に基づいて、コードまたはコンテンツを生成します。例えば、「このコードのドキュメントを作成できますか？」
- プロセスを開始するのに役立ちます。例えば、「GitLab CI/CDパイプラインでRuby on Railsアプリケーションをテストおよびビルドするための.GitLab-ci.yml設定ファイルを作成してください」といったものです。
- 初心者であろうとエキスパートであろうと、すべてのDevSecOps関連の質問に回答します。例えば、「動的アプリケーションセキュリティテストをREST APIに設定するにはどうすればよいですか？」
- 以前のすべてのシナリオを通して繰り返し作業できるよう、追加の質問に回答します。

GitLab Duo Chatはベータ機能として利用可能です。また、弊社のWeb IDEおよびVS Code用GitLab Workflow拡張機能にも、実験的機能として統合されています。これらのIDEでは、テストの作成など、[標準的なチャットコマンドを使用してタスクをより迅速に実行できます](../../user/gitlab_duo_chat/examples.md)。

製品内または[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/430124)を通じて、GitLab Duo Chatのご経験に関するフィードバックを提供することで、これらの機能の成熟にご協力いただけます。

### マージリクエストで変更を要求する {#request-changes-on-merge-requests}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/project/merge_requests/reviews/_index.md#submit-a-review)

{{< /details >}}

マージリクエストのレビューの最後の部分は、結果を伝えることです。承認は明確でしたが、コメントを残すことはそうではありませんでした。それらは、作成者があなたのコメントを読み、そのコメントが純粋に情報提供のみなのか、あるいは必要な変更を説明しているのかを判断することを要求しました。これで、レビューを完了するときに、3つのオプションから選択できます:

- **コメント**: 明示的に承認することなく、一般的なフィードバックを送信します。
- **承認**: フィードバックを送信し、変更を承認します。
- **変更をリクエスト**: マージする前に対応すべきフィードバックを送信します。

サイドバーに、あなたの名前の横にレビューの結果が表示されるようになりました。現在、**変更の要求**でレビューを終了しても、マージリクエストがマージされるのをブロックすることはありませんが、マージリクエストの他の参加者に追加のコンテキストを提供します。

**変更の要求**機能に関するフィードバックは、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/438573)でお寄せいただけます。

### CI/CD変数のユーザーインターフェースの改善 {#improvements-to-the-cicd-variables-user-interface}

<!-- categories: Secrets Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/variables/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/418331)

{{< /details >}}

GitLab 16.9では、CI/CD変数のユーザーエクスペリエンスに関する一連の改善をリリースしました。変数作成フローを、以下の変更によって改善しました:

- [変数の値が要件を満たさない場合の検証の改善](https://gitlab.com/gitlab-org/gitlab/-/issues/365934)。
- [変数作成時のヘルプテキスト](https://gitlab.com/gitlab-org/gitlab/-/issues/410220)。
- [変数フォームの値フィールドのサイズ変更を許可](https://gitlab.com/gitlab-org/gitlab/-/issues/434667)。

その他の改善点として、変数の管理を支援するための新しい[グループおよびプロジェクト変数用のオプションの説明フィールド](https://gitlab.com/gitlab-org/gitlab/-/issues/378938)があります。また、[複数の変数を追加または編集する](https://gitlab.com/gitlab-org/gitlab/-/issues/434666)ことを容易にし、ソフトウェア開発ワークフローにおける摩擦を減らし、デベロッパーがより効率的に作業できるようにしました。

これらの変更に対する皆様の[フィードバック](https://gitlab.com/gitlab-org/gitlab/-/issues/441177)は常に高く評価され、感謝されています。

### パイプラインの自動キャンセルに関するオプションの拡張 {#expanded-options-for-auto-canceling-pipelines}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/yaml/_index.md#workflowauto_cancelon_new_commit) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/412473)

{{< /details >}}

現在、[冗長なパイプラインを自動キャンセルする機能](../../ci/pipelines/settings.md#auto-cancel-redundant-pipelines)を使用するには、パイプラインをキャンセルできるかどうかを判断するために、キャンセル可能なジョブを[`interruptible: true`](../../ci/yaml/_index.md#interruptible)として設定する必要があります。しかし、これはGitLabがパイプラインをキャンセルしようとするときに、アクティブに実行されているジョブにのみ適用されます。まだ開始されていない（「保留中」の状態にある）ジョブも、`interruptible`設定に関係なく、キャンセルしても安全であると見なされます。

この柔軟性の欠如は、自動キャンセルパイプライン機能によってどのジョブを正確にキャンセルできるかについて、より詳細な制御を望むユーザーを妨げます。この制限に対処するため、ジョブキャンセルをより細かく制御できる`auto_cancel:on_new_commit`キーワードの導入を発表できることを嬉しく思います。以前の動作が機能しなかった場合は、まだ開始されていないジョブであっても、`interruptible: true`で明示的に設定されているジョブのみをキャンセルするようにパイプラインを設定するオプションが提供されます。ジョブが自動的にキャンセルされないように設定することもできます。

## 規模とデプロイ {#scale-and-deployments}

### 高度な検索のための同時実行コードインデックス作成ジョブを制限する {#limit-concurrent-code-indexing-jobs-for-advanced-search}

<!-- categories: Global Search -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../integration/advanced_search/elasticsearch.md#advanced-search-configuration) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/435402)

{{< /details >}}

GitLab管理者は、同時に実行できるElasticsearchコードインデックス作成バックグラウンドジョブの最大数を設定できるようになりました。以前は、専用のSidekiqプロセスを作成することによってのみ、同時実行ジョブの数を制限できました。

### グループおよびプロジェクトメンバー管理のためのカスタムガイドライン {#custom-guidelines-for-managing-group-and-project-members}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/appearance.md#member-guidelines) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/433093)

{{< /details >}}

管理者は、グループまたはプロジェクトの**メンバー**ページで、メンバーを管理する権限を持つユーザーに表示されるテキストガイドラインを追加できるようになりました。管理者は、**Admin Area**の設定の**外観**セクションで、これらのガイドラインにアクセスできます。

ガイドラインは、外部ツールを使用してグループやプロジェクトのメンバーを管理するチームにとって役立ちます。例えば、ガイドラインは、個々のメンバーのメンバーシップを管理する代わりに、ユーザーが使用すべき事前定義されたグループにリンクできます。

@bufferoverflow様、このコミュニティコントリビュートに感謝いたします！

### 直接転送のインポート統計を表示 {#show-import-stats-for-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/import/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/437874)

{{< /details >}}

直接転送によるGitLabグループおよびプロジェクトの完了した移行では、移行の全体的な最終結果をユーザーに知らせるために、バッジ（**完了**、**一部のみが完了**、および**失敗**）が表示されていました。ユーザーはまた、**See failures**リンクをクリックすることで、インポートされなかったアイテムのリストにアクセスできました。

しかし、部分的にインポートされたプロジェクトの場合、各タイプのアイテムがいくつ成功的にインポートされ、いくつインポートされなかったかを迅速に理解する方法はありませんでした。

このリリースでは、グループとプロジェクトのインポート結果統計を追加しました。統計にアクセスするには、直接転送履歴ページの**詳細**リンクを選択します。

### グループレベルでJiraイシューを有効にする {#enable-jira-issues-at-the-group-level}

<!-- categories: Integrations -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../integration/jira/configure.md#view-jira-issues) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/325715)

{{< /details >}}

このリリースにより、GitLabグループ内のすべてのプロジェクトでJiraイシューを有効にできるようになりました。以前は、個々のGitLabプロジェクトごとにしかJiraイシューを有効にできませんでした。

### Slackアプリ向けGitLabのREST APIサポート {#rest-api-support-for-the-gitlab-for-slack-app}

<!-- categories: Integrations -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/group_integrations.md#gitlab-for-slack-app) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/364440)

{{< /details >}}

このリリースにより、Slackアプリ向けGitLabのREST APIサポートが追加されました。

APIからSlack向けGitLabアプリを作成することはできません。代わりに、GitLabUIから[アプリをインストールする](../../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app)必要があります。その後、インテグレーション設定を取得し、プロジェクトのアプリを更新または無効にすることができます。

### REST APIを通じてGitLab使用状況データにアクセス {#access-gitlab-usage-data-through-the-rest-api}

<!-- categories: Application Instrumentation -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../api/usage_data.md#export-service-ping-data) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/12251)

{{< /details >}}

セルフマネージドのユーザーは、REST API接続を通じてService Pingデータにシームレスにアクセスできるようになり、ダウンストリームシステムとの直接的なインテグレーションが容易になりました。これは、以前のファイルダウンロード方法と比較して大幅な改善です。この新しいアプローチは、セルフマネージドのユーザーに対し、GitLab使用状況データからカスタマイズされた分析を実施し、特定のインサイトを導き出すための、より効率的でリアルタイムな手段を提供します。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### SSH証明書によるコミットの認証と署名 {#authenticate-and-sign-commits-with-ssh-certificates}

<!-- categories: Source Code Management -->

{{< details >}}

- プラン: Silver, Gold
- リンク: [ドキュメント](../../user/group/ssh_certificates.md)

{{< /details >}}

以前は、GitLab.comでのGitアクセス制御オプションは、ユーザーアカウントに設定された認証情報に依存していました。これで、SSH証明書のみを使用してGitアクセスを可能にするプロセスを設定できます。これらの証明書を使用してコミットに署名することもできます。

### GitLabエージェント上のユーザーごとのワークスペースを制限する {#limit-workspaces-per-user-on-the-gitlab-agent}

<!-- categories: Remote Development -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../user/workspace/gitlab_agent_configuration.md)

{{< /details >}}

GitLab 16.8では、Kubernetes向けGitLabエージェントの設定を導入し、ワークスペースあたりのCPUおよびメモリ使用量を制限できるようにしました。

16.9では、ユーザーあたりのワークスペース数を制限することもできます。この新しい設定により、クラウド資源をさらに制御し、個々のデベロッパーがクラウド費用を膨らませることを防ぐことができます。

### 失敗したデプロイからの部分的なリソースのクリーンアップをユーザーに許可する {#allow-users-to-cleanup-partial-resources-from-failed-deployments}

<!-- categories: Environment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/environments/_index.md#run-a-pipeline-job-when-environment-is-stopped) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/435128)

{{< /details >}}

環境の[`auto_stop_in`](../../ci/yaml/_index.md#environmentauto_stop_in)機能は、最後に成功したパイプラインではなく、最後に終了したパイプラインからジョブを実行するように更新されました。これにより、成功したパイプラインがないために自動停止ジョブが実行できないエッジケースを回避できます。

この動作は、一部の状況では破壊的変更と見なされる可能性があります。新しい動作は現在、機能フラグの背後にあり、17.0でデフォルトになり、同時に、古い動作は非推奨となり、18.0でGitLabから削除される予定です。17.xへの最初のアップグレードでの破壊的変更のリスクを最小限に抑えるために、皆様にはすぐに移行を開始するか、機能フラグを設定することをお勧めします。

### Kubernetes 1.29サポート {#kubernetes-129-support}

<!-- categories: Deployment Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/clusters/agent/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/435293)

{{< /details >}}

このリリースでは、2023年12月にリリースされたKubernetesバージョン1.29の完全なサポートが追加されました。アプリをKubernetesにデプロイする場合、接続されているクラスターを最新のバージョンにアップグレードし、すべての機能を活用できるようになりました。

当社のKubernetesサポートポリシーおよびその他のサポートされているKubernetesバージョンについては、こちらをご覧ください。

### UIおよびAPIを通じてアクセス可能なエンタープライズユーザーメールアドレス {#enterprise-user-email-address-accessible-through-ui-and-api}

<!-- categories: User Management -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/enterprise_user/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/391453)

{{< /details >}}

[エンタープライズユーザー](../../user/enterprise_user/_index.md)を持つグループオーナーは、ユーザー管理UIと[グループおよびプロジェクトメンバーAPI](../../api/group_members.md)の両方を使用して、それらのユーザーのメールアドレスを確認できるようになりました。以前は、プロビジョニングされたユーザーのメールアドレスのみが返されていました。

### LDAPグループ同期のあるグループからのサービスアカウントの追加または削除 {#add-or-remove-service-accounts-from-groups-with-ldap-group-sync}

<!-- categories: User Management -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../user/group/access_and_permissions.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/425947)

{{< /details >}}

以前は、グループでLDAP同期が有効になっている場合、管理者はそのグループにユーザーを招待したり削除したりすることはできませんでした。現在、管理者は、グループおよびプロジェクトメンバーAPIを使用して、LDAP同期のあるグループにサービスアカウントユーザーを招待したり、それらのユーザーを削除したりできます。管理者は、引き続き人間のユーザーをLDAP同期のあるグループに招待したり、それらのユーザーを削除したりすることはできません。これにより、LDAPグループ同期が人間のユーザーアカウントメンバーシップにとって信頼できる唯一の情報源であることが保証されつつ、サービスアカウントを使用してLDAPで同期されたグループに自動化を追加する柔軟性が可能になります。

### カスタムロールの更新または削除の監査イベント {#audit-event-for-updating-or-deleting-a-custom-role}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/compliance/audit_event_reports.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/437672)

{{< /details >}}

GitLabは、カスタムロールが更新または削除されたときに、監査イベントを記録するようになりました。このイベントは、特権昇格の場合に権限が追加または変更されたかどうかを特定するために重要です。

### 期限切れSAML SSOセッションのUXを改善 {#improved-ux-for-expired-saml-sso-sessions}

<!-- categories: System Access -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/saml_sso/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/414475)

{{< /details >}}

SAML SSO認証を必要とするグループに属しているが、そのグループの有効なセッションを持っていない場合、セッションを更新するように促すバナーが表示されます。以前は、セッションの期限が切れている場合、イシューとマージリクエストが表示されませんでしたが、これはユーザーにとって明確ではありませんでした。これで、すべての作業アイテムを表示するためにいつ再認証する必要があるかがユーザーに明確になりました。

### 標準準拠レポートの改善 {#standards-adherence-report-improvements}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_center/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11053)

{{< /details >}}

[標準準拠レポート](../../user/compliance/compliance_center/_index.md) （[コンプライアンスセンター](../../user/compliance/compliance_center/_index.md)内）は、コンプライアンスチームがコンプライアンスの状態を監視するための場所です。

GitLab 16.5では、すべてのコンプライアンスチームが監視すべき共通のコンプライアンス要件のセットであるGitLab標準とともにレポートを導入しました。この標準は、どのプロジェクトがこれらの要件を満たしているか、どのプロジェクトが不足しているか、そしてそれらをどのようにコンプライアンスに準拠させるかを理解するのに役立ちます。今後、レポートにより多くの標準を導入していく予定です。

このマイルストーンでは、レポートをより堅牢で実用的なものにするための改善を行いました。たとえば、次の機能があります。

- チェックによる結果のグループ化
- プロジェクト、チェック、標準によるフィルタリング
- CSVにエクスポート（メールで配信）
- 改善されたページネーション

### リッチテキストエディタのより広範な利用可能性 {#rich-text-editor-broader-availability}

<!-- categories: Team Planning, Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/rich_text_editor.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/7098)

{{< /details >}}

GitLab 16.2で、プレーンテキストエディタの代替として[リッチテキストエディタをリリースしました](https://about.gitlab.com/releases/2023/07/22/gitlab-16-2-released/)。リッチテキストエディタは、「WYSIWYG（見たままを編集）」編集インターフェースと、追加の開発のための拡張可能な基盤を提供します。しかし、このリリースまで、リッチテキストエディタはイシュー、エピック、マージリクエストでのみ利用可能でした。

GitLab 16.9では、リッチテキストエディタが以下で利用可能になりました:

- [要件の説明](https://gitlab.com/gitlab-org/gitlab/-/issues/407493)
- [脆弱性検出結果](https://gitlab.com/gitlab-org/gitlab/-/issues/407491)
- [リリースの説明](https://gitlab.com/gitlab-org/gitlab/-/issues/407494)
- [デザインノート](https://gitlab.com/gitlab-org/gitlab/-/issues/407505)

リッチテキストエディタへのアクセスが改善されたことで、以前のMarkdown経験がなくても、より効率的に共同作業を行うことができます。

### Terraformモジュールの重複を許可する {#allow-duplicate-terraform-modules}

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/packages/terraform_module_registry/_index.md#allow-duplicate-terraform-modules) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/368040)

{{< /details >}}

GitLabパッケージレジストリを使用して、Terraformモジュールを公開およびダウンロードできます。デフォルトでは、同じモジュール名とバージョンをプロジェクトごとに複数回公開することはできません。

ただし、特にリリースの場合には、重複したアップロードを許可したい場合があります。このリリースでは、GitLabはパッケージレジストリのグループ設定を拡張し、重複したモジュールを許可または拒否できるようにしました。

### グループまたはサブグループからのTerraformモジュールを検証する {#validate-terraform-modules-from-your-group-or-subgroup}

<!-- categories: Package Registry -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/packages/package_registry/_index.md#view-packages) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/352041)

{{< /details >}}

GitLab Terraformレジストリを使用する際、すべてのモジュールのクロスプロジェクトビューを持つことが重要です。最近まで、ユーザーインターフェースはプロジェクトレベルでのみ利用可能でした。グループの構造が複雑な場合、モジュールを見つけて検証するのに苦労したかもしれません。

GitLab 16.9以降、GitLabでグループおよびサブグループのすべてのモジュールを表示できます。可視性の向上により、レジストリの理解が深まり、名前の衝突の可能性が減少します。

### ボードの進行中ライン {#boards-work-in-progress-line}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../user/project/issue_board.md#work-in-progress-limits) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/440540)

{{< /details >}}

ボードリストで進行中の作業制限を視覚化できるようになりました。制限を超過すると、リストにインジケーターラインが表示され、どのアイテムが制限を超えているかを把握し、それに応じてリストを管理するのに役立ちます。

### カスタムバリューストリーム分析の新しいパイプラインステージイベント {#new-stage-events-for-custom-value-stream-analytics}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/value_stream_analytics/_index.md#value-stream-stage-events) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/431934)

{{< /details >}}

[GitLabにおける開発ワークフローの追跡](https://about.gitlab.com/blog/value-stream-total-time-chart/)を改善するために、バリューストリーム分析が新しいステージイベントである`Issue first added to iteration`で拡張されました。このイベントを使用すると、チームが計画を立てすぎることによる機敏性の欠如や、イシューがイテレーションからイテレーションへとロールオーバーするチームでの実行上の課題によって引き起こされる問題を検出できます。例えば、`Issue first added to iteration`に開始し、`Issue first assigned`に終了する「計画済み」ステージを追加できるようになりました。

### 運用コンテナスキャンの改善 {#improvements-to-operational-container-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/clusters/agent/vulnerabilities.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11968)

{{< /details >}}

運用コンテナスキャン（OCS）のレポートおよび安定性の改善を行いました。特に、Trivyのレポートサイズ制限が増加され、より安定したユーザーエクスペリエンスが提供されます。Trivyのレポートサイズを10MBから100MBに拡張することで、レポートサイズ制限によって制約を受けていたお客様が、クラスター内のコンテナイメージのセキュリティ確保にOCSを活用できるようになります。

OCSへのこの変更により、`gitlab-agent`をFIPSモードで実行しているユーザーは、運用コンテナスキャンを実行できません。詳細については、当社のドキュメントを参照し、[イシュー #440849](https://gitlab.com/gitlab-org/gitlab/-/issues/440849)でフィードバックをお寄せください。

### DASTアナライザーの更新 {#dast-analyzer-updates}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/application_security/dast/browser/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/12685)

{{< /details >}}

16.9リリースマイルストーン中に、以下のバグを解決しました:

- ブラウザが新しいページに移行したときに、キャッシュされたリソースの応答ボディを取得しようとするときのブラウザベースのDASTエラー。詳細については、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/435175)を参照してください。
- ブラウザベースのDASTクロールタスクが並行して実行されず、パフォーマンスの低下を引き起こしています。詳細については、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/435325)を参照してください。

### より高品質な結果のための更新されたSASTルール {#updated-sast-rules-for-higher-quality-results}

<!-- categories: SAST -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/application_security/sast/rules.md#important-rule-changes) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10971)

{{< /details >}}

40以上のデフォルトのGitLab SASTルールを以下のように更新しました:

- C#、Go、Java、JavaScript、Pythonの検出ロジックルールを更新することで、真陽性結果（正しく特定された脆弱性）を増加させ、偽陰性結果（誤って特定された脆弱性）を減少させます。
- C#、Go、Java、およびPythonルールに[OWASPマッピング](https://gitlab.com/gitlab-org/gitlab/-/issues/438561)を追加します。

ルール変更は、SemgrepベースのGitLab SAST [アナライザー](../../user/application_security/sast/analyzers.md)の更新されたバージョンに含まれています。この更新は、[SASTアナライザーを特定のバージョンに固定](../../user/application_security/sast/_index.md)していない限り、GitLab 16.0以降で自動的に適用されます。さらに多くのSASTルールの改善に[エピック10907](https://gitlab.com/groups/gitlab-org/-/epics/10907)で取り組んでいます。

### VS Codeでより詳細なセキュリティ検出結果 {#more-detailed-security-findings-in-vs-code}

<!-- categories: Editor Extensions, API Security, Container Scanning, DAST, Fuzz Testing, SAST, Secret Detection, Software Composition Analysis, Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../editor_extensions/visual_studio_code/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10996)

{{< /details >}}

Visual Studio Code（VS Code）用の[GitLab Workflow拡張機能](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#security-findings)でのセキュリティ検出結果の表示方法を改善しました。以前は表示されていなかったセキュリティ検出結果の詳細を、以下を含めて確認できるようになりました:

- リッチテキスト形式の完全な説明。
- 利用可能な場合は、脆弱性に対するソリューション。
- あなたのコードベースで問題が発生している場所へのリンク。
- 検出された脆弱性のタイプに関する詳細情報へのリンク。

また、次のことも行いました:

- 結果が準備される前のセキュリティスキャンのステータスの表示方法を改善しました。
- その他のユーザービリティ改善を行いました。

### パイプラインまたはジョブをキャンセルできるロールを制御する {#control-which-roles-can-cancel-pipelines-or-jobs}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/pipelines/settings.md#restrict-roles-that-can-cancel-pipelines-or-jobs) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/410634)

{{< /details >}}

組織は、どのユーザーロールがパイプラインをキャンセルできるかを制御したいと考えるかもしれません。以前は、パイプラインを実行できる人なら誰でもパイプラインをキャンセルできました。これで、プロジェクトのメンテナーが設定を更新し、パイプラインおよびジョブのキャンセルを特定のロールに制限したり、完全にキャンセルを防止したりできるようになりました！

### フリートダッシュボード: プロジェクトごとのインスタンスRunnerで使用されたコンピューティング時間のメトリクスカード {#fleet-dashboard-compute-minutes-used-on-instance-runners-per-project-metric-card}

<!-- categories: Fleet Visibility -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../ci/runners/runner_fleet_dashboard.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/421457)

{{< /details >}}

GitLab Runnerフリートを大規模に管理する場合、どのプロジェクトがRunnerで最も多くのコンピューティング時間を使用しているかを知ることが重要であると伺っています。この情報は、チームがCI/CDパイプラインを最適化し、フリートコスト最適化について適切な決定を下すために不可欠です。

プロジェクトごとのRunnerのコンピューティング使用量メトリクスカードは、以前にリリースされたCI/CDコンピューティング時間のCSVによるエクスポート機能の補完として、Runnerフリートダッシュボードで利用可能になりました。インスタンスRunnerのコンピューティング時間を消費する上位プロジェクトと、GitLab環境で最も使用されているインスタンスRunnerを確認できます。

### GitLab Runner 16.9 {#gitlab-runner-169}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 16.9もリリースします！GitLab Runnerは、CI/CDジョブを実行し、結果をGitLabインスタンスに送信する、軽量で拡張性の高いエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [Kubernetes APIの再試行を設定可能にする](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37349)

#### バグ修正 {#bug-fixes}

- [ランダムな警告: \*\*\*の削除に失敗しました: ディレクトリが空ではありません](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3185)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-9-stable/CHANGELOG.md)にあります。

### ブランチベースパイプラインのMRリンクを表示 {#show-mr-link-for-branch-based-pipelines}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/pipelines/_index.md#view-pipelines) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/416134)

{{< /details >}}

ブランチパイプラインを使用している場合、パイプライン詳細ページから関連するマージリクエストを素早く表示およびアクセスできるようになりました。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.9)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.9)
- [UI改善](https://papercuts.gitlab.com/?milestone=16.9)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
