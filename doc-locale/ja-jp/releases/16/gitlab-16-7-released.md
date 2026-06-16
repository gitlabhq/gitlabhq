---
stage: Release Notes
group: Monthly Release
date: 2023-12-21
title: "GitLab 16.7リリースノート"
description: "GitLab 16.7がリリースされ、GitLab Duoコード提案が一般公開されました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2023年12月21日、GitLab 16.7が以下の機能を伴ってリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター {#this-months-notable-contributor}

より広範なコミュニティの成長に引き続き注力する中、[コアチーム](https://about.gitlab.com/community/core-team/)のメンバーによって選出された両MVPを大変喜ばしく思います。

ムハメッドは、GitLab RunnerでDockerイメージを使用する際に[プラットフォームを指定する](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112907)ためのサポートを追加したことで推薦されました。このコントリビュートは9ヶ月間の協力期間を要し、バグの修正に[フォローアップ](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137100)が必要となった際のムハメッドの献身と忍耐を示しました。これにより、人気のあった2年前の[イシュー](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27919)が解決されました。「長らく待たれていた機能を実用化する上で、GitLab Runnerチームが私をサポートしてくれたことに感謝します」とムハメッドは述べています。ムハメッドは[Airtime Rewards](https://www.airtimerewards.co.uk/)のオートメーションエンジニアで、主にTerraformを扱い、エンジニアリングチーム内でCI/CDと自動化の実践を推進しています。

ニクラスは、さまざまな形での継続的なコントリビュートとサポートが評価され、推薦されました。本日は、彼が最後にMVP賞を受賞してからちょうど1年になります。ニクラスは、GitLabチームメンバーにとっても困難な作業に取り組み、より広範なコミュニティコントリビューターを維持する上で大きな役割を果たしています。[推薦イシュー](https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/34762#note_1681021745)で詳細をご確認ください。

ムハメッド、ニクラス、ありがとうございます！🙌

## 主要な機能 {#primary-features}

### GitLab Duoコード提案が一般公開されました {#gitlab-duo-code-suggestions-is-generally-available}

<!-- categories: Code Suggestions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/repository/code_suggestions/_index.md)

{{< /details >}}

[GitLab Duoコード提案](https://about.gitlab.com/solutions/code-suggestions/)が一般公開されました！

GitLab Duoコード提案は、コード行の補完や関数のロジックの定義と生成により、チームがソフトウェアをより迅速かつ効率的に作成できるよう支援します。

コード提案は、プライバシーを重要な基盤として構築されています。GitLabに保存されている非公開の顧客コードは、トレーニングデータとして使用されません。コード提案を使用する際の[データ使用](../../user/gitlab_duo/data_usage.md)について学習してください。

一般リリースでは、複数のIDEで[コード提案を利用できるようになりました](../../user/project/repository/code_suggestions/_index.md)。コード提案は、より直感的で応答性が向上しました。

GitLab Duoコード提案は、2024年2月15日まで[GitLabテスト規約](https://handbook.gitlab.com/handbook/legal/testing-agreement/)に基づいて[無料で試用](../../user/project/repository/code_suggestions/_index.md)できます。本日から、コード提案をGitLabのサブスクリプションのアドオンとして、月額9米ドルの導入価格で購入できます。コード提案の利用を開始するには、[お問い合わせ](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/)ください。

### GitLab PagesをDNSワイルドカードなしで使用する {#use-gitlab-pages-without-a-wildcard-dns}

<!-- categories: Pages -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/pages/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/17584)

{{< /details >}}

これまで、GitLab Pagesプロジェクトを作成するには、name.example.ioやname.pages.example.ioのような形式のドメインが必要でした。この要件は、ワイルドカードDNSレコードとSSL/TLS証明書を設定する必要があることを意味していました。GitLab 16.7では、DNSワイルドカードなしでGitLab Pagesプロジェクトを設定できます。この機能は実験です。

ワイルドカード証明書の要件をなくすことで、GitLab Pagesに関連する管理オーバーヘッドが軽減されます。一部の顧客は、ワイルドカードDNSレコードまたは証明書に対する組織的な制限のため、GitLab Pagesを使用できません。

この機能に関するフィードバックは、[イシュー434372](https://gitlab.com/gitlab-org/gitlab/-/issues/434372)でお待ちしております。

### インサイトレポートのチャートからの新しいドリルダウンビュー {#new-drill-down-view-from-insights-report-charts}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/insights/_index.md#drill-down-on-charts) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/372215)

{{< /details >}}

[インサイトレポート](https://www.youtube.com/watch?v=OMTfPsLa98I)を使用すると、カスタマイズ可能なチャートを使用して経時的なパターンを分析できます。「優先度別作成バグ」および「重大度別作成バグ」インサイトレポートに追加された新しいドリルダウン機能により、より詳細な分析のために[イシューアナリティクス](../../user/group/issues_analytics/_index.md)レポートをドリルダウンできます。

この機能は、以降のバージョンでカスタムオプションとして他のインサイトレポートにも含める予定です。

### SASTの結果をMR変更ビューに表示 {#sast-results-in-mr-changes-view}

<!-- categories: SAST -->

{{< details >}}

- プラン: Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/sast/_index.md#merge-request-changes-view) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10959) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/432704)

{{< /details >}}

SASTの検出結果が、マージリクエストの変更ビューに表示されるようになりました。これにより、コードレビュープロセス中に潜在的な弱点を簡単に確認、理解、修正できます。

SASTのイシューを含む行は、ガターの横に記号でマークされます。記号を選択すると問題のリストが表示され、問題を選択するとその詳細が表示されます。

この機能はGitLab.comで有効化されています。GitLab 16.8では、Self-Managedインスタンス向けに[機能フラグ](https://gitlab.com/gitlab-org/gitlab/-/issues/410191)をデフォルトで有効にする予定です。

### CI/CDカタログ - ベータリリース {#cicd-catalog---beta-release}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/components/_index.md#cicd-catalog)

{{< /details >}}

GitLab 16.7では、CI/CDカタログのベータリリースが行われました！このカタログは、あなた、あなたの組織、または公開コミュニティによって管理されている[CI/CDコンポーネント](../../ci/components/_index.md)を検索できる場所です。ここは、DevOpsエンジニアが集まって、再利用可能なパイプラインの設定を作成し、コントリビュートする場です。

CI/CD設定を再利用する他の方法とは異なり、カタログに公開されているCI/CDコンポーネントは、改善されたエクスペリエンスを提供し、パイプラインに簡単に追加できます。この新しくエキサイティングな機能をぜひお試しください！他のユーザーが作成してカタログで共有したコンポーネントを試したり、独自のコンポーネントを作成して全員と共有したりできます。

これは本機能の最初のベータリリースですが、私たちはエクスペリエンスをさらに向上させるために作業を続けています。私たちの目標は、CI/CDカタログをGitLab CI/CDエクスペリエンスの基本的な部分にすることです。

## 規模とデプロイ {#scale-and-deployments}

### ユーザープロファイルにMastodonハンドルを追加 {#add-a-mastodon-handle-to-your-user-profile}

<!-- categories: User Profile -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/_index.md#add-external-accounts-to-your-user-profile-page) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/428442)

{{< /details >}}

ユーザープロファイルにMastodonハンドルをリストできるようになりました。この機能強化により、私たちはFediverseソーシャルネットワークをサポートし、[GitLab向けActivityPub](https://gitlab.com/groups/gitlab-org/-/epics/11247)の進展に貢献します。

### グループの説明が500文字に拡張 {#group-descriptions-extended-to-500-characters}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/416146)

{{< /details >}}

グループの説明に最大500文字を含めることができるようになりました。500文字を超えるグループの説明を保存しようとすると、説明が長すぎることを示す警告メッセージが表示されます。このコミュニティコントリビュートを@freznicekに感謝します！

### 検索結果ページで検索バーがより目立つように {#search-bar-more-prominent-on-the-search-results-page}

<!-- categories: Global Search -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/search/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/424619)

{{< /details >}}

検索結果ページで検索バーがより目立つようになりました。検索バーの表示レベルを向上させるため、グループとプロジェクトのフィルターは左サイドバーに移動されました。

### 高度な検索でコードを含むイシューの発見をより容易に {#issues-with-code-more-discoverable-in-advanced-search}

<!-- categories: Global Search -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/search/advanced_search.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/421012)

{{< /details >}}

GitLab 16.7では、コードを含むイシューの発見がより容易になりました。高度な検索で、コードスニペットやログが説明に含まれるイシューを見つけられるようになりました。

### 表示する時刻形式をカスタマイズ {#customize-time-format-for-display}

<!-- categories: Internationalization -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/preferences.md#customize-time-format) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/15206)

{{< /details >}}

これまで、GitLabは12時間形式で時刻を表示しており、これを変更することはできませんでした。

今回のリリースから、コミュニティコントリビュートのおかげで、イシューリストや概要ページ、ステータス設定時など、時刻を表示する際に使用される形式をカスタマイズできるようになりました。時刻は次の形式で表示できます。

- 12時間形式。例: `2:34 PM`
- 24時間形式。例: `14:34`

[Thorben Westerhuys](https://gitlab.com/n0rdlicht)氏によるこの[コミュニティコントリビュート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130789)に感謝いたします。

次のマイルストーンでは、GitLab製品全体で表示されるすべてのタイムスタンプがこの設定を尊重するように[監査](https://gitlab.com/groups/gitlab-org/-/epics/12215)します。

### 左サイドバーから管理者エリアにアクセス {#access-the-admin-area-from-the-left-sidebar}

<!-- categories: Navigation & Settings -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/admin_area.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/415854)

{{< /details >}}

管理者は、左サイドバーの下部にあるリンクを使用して、1ステップで管理者エリアにアクセスできるようになりました。以前は、**検索または移動先**を選択してから、**Admin Area**を選択する必要がありました。この変更により、管理者エリアにアクセスする際の時間を節約できるはずです。

### ハードコードされた移行完了時間制限を削除 {#remove-hardcoded-time-limit-for-migrations-to-complete}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/import/_index.md#limits) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/429867)

{{< /details >}}

ダイレクト転送によって行われるGitLabグループおよびプロジェクトの移行は、さまざまな理由で停止することがあります。これまで、これらの移行が未完了の状態で無期限に放置されるのを避けるため、GitLabは8時間以内に完了しなかった移行を特定するために定期的にワーカーを実行していました。GitLabはこれらの移行をタイムアウトとしてマークしていました。

大規模な組織の場合、移行プロセスは8時間以上かかることがあり、この時間では移行が停止しているかどうかを適切に判断するのに十分ではありませんでした。結果として、このワーカーは移行を誤って停止中とマークしていた可能性があります。

今回のマイルストーンでは、8時間の時間制限を使用する代わりに、子ワーカーが24時間停止した場合にのみGitLabが移行を停止中とマークするようになりました。

### ダイレクト転送によるインポートの包括的な結果 {#comprehensive-results-of-imports-by-direct-transfer}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/import/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/394727)

{{< /details >}}

ユーザーにとってインポートプロセスの結果を理解することがいかに重要であるかを認識し、今回のマイルストーンでは、ダイレクト転送によるインポートに表示される情報をさらに改善しました。GitLabグループとプロジェクトの隣にインポートステータスバッジを表示するようになりました:

- [グループとプロジェクトをインポートするために選択できるページ](../../user/group/import/_index.md)。
- [インポートされたグループとプロジェクトを一覧表示するページ](../../user/group/import/_index.md)。

インポートステータスバッジは次のとおりです:

- **開始されていません**
- **保留中**
- **インポート中**
- **失敗した**
- **タイムアウト**
- **キャンセルしました**
- **完了**
- **一部のみが完了**

**Partially completed badge**バッジは今回のリリースで追加され、マージリクエストやイシューなど、一部の項目がインポートされなかった完了済みのインポートプロセスを識別します。

インポートプロセスが開始されたグループには、その特定のグループのインポートされたサブグループとプロジェクトを表示する**詳細を表示**リンクがあります。そこから、**See failures**リンクをクリックすることで、インポートできなかった項目（もしあれば）のリストを確認できます。**See failures**は[前回のリリースでリリース](https://about.gitlab.com/releases/2023/11/16/gitlab-16-6-released/#comprehensive-list-of-items-that-failed-to-be-imported)されました。

今回のマイルストーンでは、これらのページ間のパンくずリストによるナビゲーションも改善しました。

### 外部参加者がコメントした場合にサービスデスクのイシューを再オープン {#reopen-service-desk-issues-when-an-external-participant-comments}

<!-- categories: Service Desk -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/service_desk/configure.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/8549)

{{< /details >}}

外部参加者がメールでイシューに新しいコメントを追加した際に、クローズされたイシューを再オープンするようにGitLabを設定できるようになりました。これにより、イシューが解決された後でも、進行中の会話を完全に可視化できます。

また、イシューの割り当て先が言及される内部コメントを追加し、彼らのためのTo-Do項目を作成します。これにより、フォローアップメールを二度と見逃すことがなくなります。

### バックアップが代替圧縮ライブラリをサポート {#backups-supports-alternate-compression-libraries}

<!-- categories: Backup/Restore of GitLab instances -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/backup_restore/backup_gitlab.md#backup-compression)

{{< /details >}}

`COMPRESS_CMD`コマンドと`DECOMPRESS_CMD`コマンドを使用して、バックアップのために、デフォルトのシングルスレッドgzip圧縮ライブラリを任意の代替圧縮ライブラリでオーバーライドできるようになりました。これにより、並列圧縮ライブラリを活用して、最新のマルチコアプロセッサの能力を使用することで、バックアップの圧縮段階を高速化できます。これらのコマンドには、圧縮ライブラリにオプションを渡すサポートが含まれており、圧縮レベルや速度などのパラメータを調整できます。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### エグレスルールを持つネットワークポリシーを定義 {#define-a-network-policy-with-egress-rules}

<!-- categories: Workspaces -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../user/workspace/gitlab_agent_configuration.md)

{{< /details >}}

GitLab 16.7では、Kubernetes向けGitLabエージェントをワークスペースをサポートするように構成する際に、エグレスルールを持つネットワークポリシーを定義できるようになりました。この機能は、GitLabインスタンスがプライベートIPに解決されるSelf-Hostedインストール、またはワークスペースがプライベートIP範囲のクラウドリソースにアクセスする必要がある場合に使用できます。

### グループにカスタム絵文字を追加 {#add-custom-emoji-to-groups}

<!-- categories: Code Review Workflow, Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/emoji_reactions.md)

{{< /details >}}

自分自身を表現するために良い絵文字を好まない人がいるでしょうか？GitLab全体で項目にコメントする際、デフォルトの絵文字セットを使用してリアクションを追加していましたが、時にはそれらの絵文字だけでは感情を表現するのに十分ではありませんでした。グループはプロジェクト全体で使用するカスタム絵文字を追加できるようになりました。カスタム絵文字を使用すると、真の感情を表現し、チームの他のメンバーとより明確にコミュニケーションを取ることができます。次にどのようにリアクションするか楽しみにしています。

### 複雑なマージリクエストの依存関係チェーンをサポート {#complex-merge-request-dependency-chains-now-supported}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../user/project/merge_requests/dependencies.md#nested-dependencies)

{{< /details >}}

GitLabのマージリクエストの依存関係は、他の変更に依存するコード変更が、コードベースを壊す可能性のある方法でマージされないようにするための優れた方法です。これまで、GitLabは複雑な依存関係チェーンを許可しておらず、循環参照や深いネストを引き起こす可能性がありました。

依存関係の階層とチェーン内の項目に関する制限が削除されました。マージリクエストの依存関係は、より複雑になりました。1つのマージリクエストは最大10個のマージリクエストによってブロックされ、その結果、他の10個のマージリクエストをブロックできます。より深い依存関係チェーンにより、より複雑なワークフローを依存関係を介して表現できるようになります。この機能の利用がどのように展開されていくかを楽しみにしています。

### マージリクエストに承認が必要な場合に通知を受け取る {#notify-me-when-any-merge-request-needs-approval}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/profile/notifications.md#edit-notification-settings)

{{< /details >}}

マージリクエストに承認が必要な場合は、通知を受けて対応する必要があります。一部のユーザーは、承認が必要な場合にのみ通知を希望します。これは通常、変更をレビューするためにユーザーを名前で追加することで行われます。ただし、一部のユーザーは、*名前でレビュアーとして追加されていない場合でも*、承認の資格があるすべてのマージリクエストに対して通知を希望します。

**Added as approver**カスタム通知レベルを有効にすると、承認の資格がある各マージリクエストに対してメールとTo-Doをトリガーできます。これにより、プロセスのできるだけ早い段階でマージリクエストを認識し、提案をマージするための行動を取ることができます。

### OpenTofuのベータサポート {#beta-support-for-opentofu}

<!-- categories: Infrastructure Cost Data -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/infrastructure/iac/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/terraform-images/-/issues/114)

{{< /details >}}

TerraformからOpenTofuに切り替える場合、このGitLabのリリースではOpenTofuの予備的なサポートが追加されます。OpenTofuはTerraformのフォークであるため、MRウィジェットのインテグレーション、モジュールレジストリ、およびGitLab管理のTerraform状態はデフォルトで機能します。GitLab IaC製品の使用を簡素化するために、`gitlab-terraform`ヘルパーイメージにOpenTofuのサポートを追加しました。

GitLabは引き続き、MRウィジェット、モジュールレジストリ、およびGitLab管理のTerraform状態に対してTerraformをサポートします。

### アクセストークンのローテーションにおけるカスタム期間 {#custom-time-period-for-access-tokens-rotation}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/personal_access_tokens.md#rotate-a-personal-access-token) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/416795)

{{< /details >}}

アクセストークンをローテーションする際に、新しいパラメータ`expires_at`をオプションで入力できるようになりました。これにより、トークンのカスタム有効期限日を作成できます。以前は、各ローテーションにより、前回の有効期限から1週間有効期限が延長されていました。この新しいオプションは、ローテーション間隔の柔軟性を提供します。

### UIを使用してユーザーをカスタムロールに割り当てる {#use-the-ui-to-assign-users-to-custom-roles}

<!-- categories: Permissions -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/custom_roles/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/393239)

{{< /details >}}

UIを使用して、新しいユーザーにカスタムロールを割り当てたり、既存のユーザーのロールをカスタムロールに変更したりできるようになりました。これは、現在ユーザーのロールを割り当てまたは変更できるUIのどの部分でも実行できます。以前は、APIを介してのみ行うことができました。

### スキャン実行ポリシー内の変数に最高の優先順位を強制する {#enforce-variables-in-scan-execution-policies-with-the-highest-precedence}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/variables/_index.md#cicd-variable-precedence) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/424028)

{{< /details >}}

CI/CD変数の変数の優先順位が改善され、スキャン実行ポリシーで定義された変数が最初に優先されるようになりました。

組織がコンプライアンス要件を満たすために取り組むにつれて、ビジネス上重要なアプリケーションでセキュリティスキャナーが有効になっていることを確認することが一般的になっています。

スキャン実行ポリシーにより、チームはスキャナーを強制し、デフォルトおよびカスタムのCI/CD変数を定義できます。このCI/CD変数の変数の優先順位の強化により、パイプラインがどのようにトリガーされても、コンプライアンスを考慮して定義された変数が変更されないことをチームは確信できます。

### SAML属性ステートメントがMicrosoft SAML属性形式をサポート {#saml-attribute-statements-support-microsoft-saml-attribute-format}

<!-- categories: User Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../integration/saml.md#configure-assertions) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/420766)

{{< /details >}}

SAML属性ステートメントが、URL形式のMicrosoft SAML属性形式をサポートするようになりました。これまで、Self-Managedインスタンスの管理者は属性ステートメントを手動で設定する必要があり、GitLab.comのグループオーナーはSAMLレスポンスにカスタム属性を追加する必要がありました。この変更により、Self-Managed GitLabとGitLab.comの両方が、手動で設定を行うことなくMicrosoftと連携できるようになります。

### リッチテキストエディタの改善 {#improvements-to-rich-text-editor}

<!-- categories: Team Planning, Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/rich_text_editor.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/136437)

{{< /details >}}

GitLab 16.2で、既存のMarkdown編集エクスペリエンスの代替としてリッチテキストエディタをリリースしました。リッチテキストエディタは、「WYSIWYG（見たままを編集）」編集エクスペリエンスと、図、コンテンツ埋め込み、メディア管理などのカスタム編集インターフェースを構築できる拡張可能な基盤を提供します。

GitLab 16.7では、リッチテキストエディタをMarkdown編集エクスペリエンスと一致するように変更し、報告されたバグを修正しました。Markdownとリッチテキストエディタ間で一貫性を持たせるために[ラベル](https://gitlab.com/gitlab-org/gitlab/-/issues/419097)オートコンプリートモーダルの並べ替え順を変更、リッチテキストエディタのunassignクイックアクションで返されるオプションのバグを[解決](https://gitlab.com/gitlab-org/gitlab/-/issues/420344) 、[カスタム絵文字のサポートを追加](https://gitlab.com/gitlab-org/gitlab/-/issues/422958) 、および[両方の編集エクスペリエンスで一貫性を持たせるためにクイックアクション選択ドロップダウンの外観を更新](https://gitlab.com/gitlab-org/gitlab/-/issues/406714)しました。

### 新しいコンテナリポジトリAPIでリポジトリのタグを一覧表示 {#list-repository-tags-with-new-container-registry-api}

<!-- categories: Container Registry -->

{{< details >}}

- プラン: Free、Silver、Gold
- リンク: [ドキュメント](../../api/container_registry.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/411387)

{{< /details >}}

以前は、コンテナリポジトリは、Docker/OCIの[イメージタグレジストリAPIのリスト](https://gitlab.com/gitlab-org/container-registry/-/blob/5208a0ce1600b535e529cd857c842fda6d19ad59/docs/spec/docker/v2/api.md#listing-image-tags)に依存して、GitLabでタグを一覧表示および表示していました。このAPIには、パフォーマンスと検出可能性に重大な制限がありました。

このAPIは、レジストリに対するネットワークリクエストの数がタグリスト内のタグの数に応じてスケールするため、パフォーマンスが低下していました。さらに、APIが公開時間を追跡しなかったため、公開タイムスタンプがしばしば不正確でした。また、DockerマニフェストリストまたはOCIインデックスに基づいて画像を表示する場合、多重アーキテクチャ画像などの制限がありました。

これらの制限に対処するため、新しいレジストリ[のリポジトリタグをリストするAPI](https://gitlab.com/gitlab-org/container-registry/-/blob/5208a0ce1600b535e529cd857c842fda6d19ad59/docs/spec/gitlab/api.md#list-repository-tags)を導入しました。ユーザーインターフェースを新しいAPIを使用するように更新することで、コンテナリポジトリへのリクエスト数が1つに削減されます。公開タイムスタンプも正確になり、マルチアーキテクチャイメージに対するより堅牢なサポートが提供されます。

この機能はGitLab.comでのみ利用可能です。Self-Managedのサポートは、次世代コンテナリポジトリが一般公開されるまでブロックされています。詳細については、[イシュー423459](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)を参照してください。

### GitLab.com上のコンテナリポジトリ内のコンテナイメージを持つプロジェクトの名前を変更 {#rename-projects-with-container-images-in-the-container-registry-on-gitlabcom}

<!-- categories: Container Registry -->

{{< details >}}

- プラン: Free、Silver、Gold
- リンク: [ドキュメント](../../user/project/working_with_projects.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10433)

{{< /details >}}

今回のリリース以前は、プロジェクトに関連付けられているすべてのコンテナイメージを最初に削除しない限り、少なくとも1つのタグを持つコンテナリポジトリがあるプロジェクトの名前を変更できませんでした。

これは、異なるプロジェクト名を使用する前に、カスタムスクリプトに頼ってすべてのタグを手動で削除/移動する必要があるという実際の問題でしたが、GitLab.comでは、レジストリにコンテナイメージがある場合でもプロジェクトの名前を変更できるようになりました！

### バリューストリーム分析で事前定義された日付範囲でフィルタリング {#filter-by-predefined-date-ranges-in-value-stream-analytics}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/value_stream_analytics/_index.md#data-filters) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/408656)

{{< /details >}}

バリューストリーム分析レポートには、過去30、60、90、180日間のデータに対するフィルターオプションが追加されました。これらの新しいフィルターオプションにより、日付選択プロセスが簡素化され、[開発ライフサイクル中に時間がどこで費やされているか](https://about.gitlab.com/blog/value-stream-total-time-chart/)をより効率的かつユーザーフレンドリーに理解できるようになります。

### 依存関係スキャンにおける継続的脆弱性スキャンのサポート {#support-for-continuous-vulnerability-scanning-for-dependency-scanning}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/continuous_vulnerability_scanning/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/11474)

{{< /details >}}

継続的脆弱性スキャンが一般公開されました。CVSを有効にすると、アドバイザリがGitLabアドバイザリデータベースに追加されたときに、プロジェクトが自動的にスキャンされます。新しい依存関係関連の脆弱性が識別された場合、脆弱性が自動的に作成されます。

### DAST脆弱性チェックの更新 {#dast-vulnerability-check-updates}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/application_security/dast/browser/checks/_index.md#active-checks)

{{< /details >}}

16.7リリースマイルストーン期間中に、ブラウザベースのDASTに対して以下の積極的なチェックをデフォルトで有効にしました:

- チェック89.1は、ZAPチェック40018、40019、40020、40021、40022、40024、40027、40033、および90018を置き換え、SQLインジェクションを識別します。
- チェック918.1は、ZAPチェック40046を置き換え、サーバーサイドリクエストフォージェリを識別します。
- チェック98.1は、ZAPチェック7を置き換え、PHPリモートファイルインクルージョンを識別します。
- チェック917.1は、ZAPチェック90025を置き換え、式言語インジェクションを識別します。
- チェック1336.1は、ZAPチェック90035とサーバーサイドテンプレートインジェクションを置き換えます。

### DAST認証が多段階ログインフォームをサポート {#dast-authentication-now-supports-multi-step-login-forms}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dast/browser/configuration/authentication.md#configuration-for-a-multi-step-login-form) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/11585)

{{< /details >}}

新しい`DAST_AFTER_LOGIN_ACTIONS`変数を使用すると、ログイン後に実行するアクションのリストを提供できます。これにより、例えばAzure ADの「サインイン状態を維持する」ワークフローなど、多段階ログインインタラクションが可能になります。

### SASTルールを更新し、誤検出結果を削減 {#updated-sast-rules-to-reduce-false-positive-results}

<!-- categories: SAST -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/application_security/sast/rules.md#important-rule-changes) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/8170)

{{< /details >}}

GitLab SASTで使用されるデフォルトのルールセットを更新し、より高品質な結果を提供するようにしました。以前はデフォルトで含まれていた各ルールを分析し、ほとんどのコードベースで十分な価値を提供しないルールを削除しました。

ルール変更は、SemgrepベースのGitLab SAST [アナライザー](../../user/application_security/sast/analyzers.md)の更新されたバージョンに含まれています。この更新は、[SASTアナライザーを特定のバージョンに固定](../../user/application_security/sast/_index.md)していない限り、GitLab 16.0以降で自動的に適用されます。

削除されたルールからの既存のスキャン結果は、パイプラインが更新されたアナライザーでスキャンを実行した後に[自動的に解決されます](../../user/application_security/sast/_index.md#automatic-vulnerability-resolution)。

さらに多くのSASTルールの改善に[エピック10907](https://gitlab.com/groups/gitlab-org/-/epics/10907)で取り組んでいます。

### `artifacts:public` CI/CDキーワードが一般公開 {#artifactspublic-cicd-keyword-now-generally-available}

<!-- categories: Build Artifacts -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/yaml/_index.md#artifactspublic) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/11667)

{{< /details >}}

以前は、`artifacts:public`キーワードは、Self-Managedインスタンス向けのデフォルトで無効な機能としてのみ利用可能でした。今回、GitLab 16.7では、`artifacts:public`キーワードをすべてのユーザーが一般的に利用できるようにしました。これで、CI/CD設定ファイルで`artifacts:public`キーワードを使用して、ジョブのアーティファクトを公開アクセス可能にするかどうかを制御できます。

### 最新のジョブアーティファクトを保持する機能が向上 {#improved-ability-to-keep-the-latest-job-artifacts}

<!-- categories: Build Artifacts -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/428408)

{{< /details >}}

GitLab 13.0では、最新の成功したパイプラインからのジョブアーティファクトを保持する機能を導入しました。残念ながら、この機能は、[失敗](https://gitlab.com/gitlab-org/gitlab/-/issues/266958)したパイプラインと[ブロック](https://gitlab.com/gitlab-org/gitlab/-/issues/387087)されたパイプラインも、それが最新であるかどうかにかかわらず、最新のパイプラインとしてマークしていました。これにより、ストレージにアーティファクトが蓄積され、手動で削除する必要がありました。

GitLab 16.7では、この意図しない動作を引き起こしていたバグが解決されました。失敗およびブロックされたパイプラインからのジョブアーティファクトは、最新のパイプラインからのものである場合にのみ保持されます。そうでない場合は、`expire_in`設定に従います。影響を受けるGitLab.comの顧客は、誤って保持されていたアーティファクトが、新しいパイプラインの実行後にロック解除されて削除されることを確認できるはずです。

**成功した最新のジョブのアーティファクトを保持する**設定は、ジョブの`artifacts: expire_in`設定をオーバーライドし、有効期限なしで大量のアーティファクトが保存される可能性があります。パイプラインが多くの大きなアーティファクトを作成する場合、プロジェクトのストレージクォータがすぐに満杯になる可能性があります。この機能が不要な場合は、この設定を無効にすることをお勧めします。

### GitLab Runner 16.7 {#gitlab-runner-167}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 16.7もリリースします！GitLab Runnerは、CI/CDジョブを実行し、結果をGitLabインスタンスに送信する、軽量で拡張性の高いエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [Docker executor向けのグレースフルシャットダウンを実装する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6359)
- [Kubernetes向けのストレージクラスを持つPVCボリュームを動的に作成する](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27835)

#### バグ修正 {#bug-fixes}

- [exitコードが常に1であるため、カスタムexecutorでallow_failure:exitコードが使用できない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28658)
- [RunnerヘルパーおよびKubernetes executor用のビルドコンテナにおけるシグナルのより良い処理を追加](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36996)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-7-stable/CHANGELOG.md)にあります。

### GitLab RunnerがSLSA v1.0ステートメントをサポート {#gitlab-runner-supports-slsa-v10-statement}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/runners/configure_runners.md#artifact-provenance-metadata) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/36869)

{{< /details >}}

Runnerは、[SLSA 1.0](https://slsa.dev/spec/v1.0/)に準拠した来歴メタデータを生成できるようになりました。SLSA 1.0を有効にするには、`.gitlab-ci.yml`ファイルで`SLSA_PROVENANCE_SCHEMA_VERSION=v1`変数を設定します。SLSAバージョン1.0ステートメントは、GitLab 17.0でデフォルトのバージョンになる予定です。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.7)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.7)
- [UI改善](https://papercuts.gitlab.com/?milestone=16.7)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
