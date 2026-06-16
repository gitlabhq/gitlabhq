---
stage: Release Notes
group: Monthly Release
date: 2024-04-18
title: "GitLab 16.11リリースノート"
description: "GitLab 16.11では、GitLab Duo Chatが一般提供されました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2024年4月18日、GitLab 16.11が次の機能とともにリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター {#this-months-notable-contributor}

[Ivan Shtyrliaiev](https://gitlab.com/bahek2462774)は2024年に入ってからGitLabに[数件のコントリビュート](https://gitlab.com/groups/gitlab-org/-/merge_requests?scope=all&state=merged&author_username=bahek2462774)を行っています。彼はGitLabのプリンシパルプロダクトマネージャーである[Hannah Sutor](https://gitlab.com/hsutor)によって推薦され、[ユーザーリストの検索およびフィルターユーザーエクスペリエンスを改善](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144907)したコントリビュートが評価されました。

「これは、横スクロール可能なタブのリストから、2つのタブと検索ボックスだけの、はるかに洗練されたUXへと移行するのに役立つ、ユーザーエクスペリエンスの大幅な改善です」とHannahは述べました。「これでユーザーは、タブを横スクロールするのではなく、検索ボックスで絞り込むことができるようになりました！」

Ivanは、この困難なリクエストを引き受け、GitLab UXチームと協力して提案を洗練し、レビューに非常に迅速に対応したことで評価されました。GitLabのエンジニアリングマネージャーである[Adil Farrukh](https://gitlab.com/adil.farrukh)は、この機能は些細なものではなく、Ivanがフィードバックに非常に迅速に対応したと述べ、推薦を支持しました。[Eduardo Sanz García](https://gitlab.com/eduardosanz)、Sr.Frontend Engineer at GitLabも推薦を支持し、Ivanの回復力を称賛しました。

「Eduardoのレビューと、コントリビュートを実現するために多大な努力を払ってくれたGitLabチームに本当に感謝しています」とIvanは述べました。「それはとても役に立ち、どれだけの時間がかかるか分かりました。」

Ivanは[Politico](https://www.politico.com/)のフロントエンドソフトウェアエンジニアです。

[Baptiste Lalanne](https://gitlab.com/BaptisteLalanne)は、70近くの同意するが寄せられた3年前のイシューを取り上げ、[要望の多かった機能](https://gitlab.com/gitlab-org/gitlab/-/issues/262674)、つまりCI/CD設定に`retry:exit codes`を追加する機能にコントリビュートしました。このコントリビュートにより、ユーザーは失敗したパイプラインジョブや異なる終了コードを持つジョブを管理する際の柔軟性が向上します。

BaptisteはGitLabのプロダクトマネージャーである[Dov Hershkovitch](https://gitlab.com/dhershkovitch)によって推薦されました。「Baptisteのこのプロジェクトにおける勤勉な取り組みは、単なる実装を超えたものでした」とDovは述べました。「この成果は、私たちのコミュニティの協力的な強さを示す好例です。Baptisteの努力により、GitLabは重要なニーズを満たしただけでなく、オープン性と透明性へのコミットメントを強化し、オープンコアの考え方を豊かにしました。」

「これは心温まることであり、本当に感謝しています。」とBaptisteは述べました。「私はこれをとても愛しているので、余暇にコントリビュートを続けることを本当に楽しみにしています。」

この1年で、Baptisteは6つのマージリクエストをGitLabにマージし、次は[GitLab Runner](https://docs.gitlab.com/runner/development/)にコントリビュートすることを目指しています。Baptisteは[DataDog](https://www.datadoghq.com/)のソフトウェアエンジニアです。

新しくMVPに選ばれたIvanとBaptiste、そしてGitLabコミュニティのコントリビューターの皆様に心より感謝申し上げます！ 🙌

## 主要な機能 {#primary-features}

### GitLab Duo Chatが一般提供されました {#gitlab-duo-chat-now-generally-available}

<!-- categories: Duo Chat -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/gitlab_duo_chat/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13516)

{{< /details >}}

GitLab Duo Chatが一般提供されました。このリリースの一部として、これらの機能も一般提供されます:

- コードの説明により、デベロッパーや技術的知識の少ないユーザーが不慣れなコードをより早く理解できるようになります
- コードリファクタリングにより、デベロッパーは既存のコードを簡素化および改善できます
- テスト生成により、反復的なタスクを自動化し、チームがバグをより早く発見できるようにします

ユーザーは、GitLab UI、Web IDE、VS Code、またはJetBrains IDEでGitLab Duo Chatにアクセスできます。

このリリースのGitLab Duo Chatの詳細については、この[ブログ投稿](https://about.gitlab.com/blog/gitlab-duo-chat-now-generally-available/)を参照してください。

チャットは現在、すべてのUltimateおよびPremiumユーザーが自由に利用できます。インスタンス管理者、グループオーナー、およびプロジェクトオーナーは、[Duo機能が自分のデータにアクセスして処理するのを制限](../../user/gitlab_duo/turn_on_off.md)することを選択できます。

GitLab Duo Chatは[GitLab Duo Pro](https://about.gitlab.com/gitlab-duo/#pricing)の一部です。GitLab Duo Proをまだ購入していないチャットベータユーザーの移行を容易にするため、Duo Chatは既存のPremiumおよびUltimateのお客様（アドオンなし）に短期間提供され続けます。今後、Duo Pro購読者へのアクセスが制限される時期を発表します。

チャット内のフィードバックボタンをクリックするか、イシューを作成してGitLab Duo Chatに言及することで、ご意見を自由に共有してください。皆様からのご意見をお待ちしております！

### JetBrains IDEでGitLab Duo Chatが利用可能 {#gitlab-duo-chat-available-in-jetbrains-ides}

<!-- categories: Editor Extensions -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../editor_extensions/jetbrains_ide/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/307)

{{< /details >}}

JetBrains IDEでGitLab Duo Chatが利用可能になったことをお知らせします。

GitLabのAI機能の一部として、Duo Chatは、インタラクティブなチャットウィンドウをサポートされているJetBrains IDEに直接統合し、コードの説明、テスト作成、既存コードのリファクタリングする機能を提供することで、デベロッパーエクスペリエンスをさらに合理化します。

機能の完全なリストについては、[Duo Chatドキュメント](../../user/gitlab_duo_chat/_index.md)を参照してください。

### セキュリティポリシーのスコープ {#security-policy-scopes}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/scan_execution_policies.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/5510)

{{< /details >}}

ポリシースコープは、セキュリティポリシーのきめ細かな管理と適用を提供します。マージリクエスト承認（スキャン結果ポリシー）とスキャン実行ポリシーの両方において、この新機能により、セキュリティおよびコンプライアンスチームは、ポリシーの適用をコンプライアンスフレームワーク、またはグループ内の含まれる/除外するプロジェクトのセットにスコープ設定できます。

現在、セキュリティポリシープロジェクトで管理されているすべてのセキュリティポリシーは、リンクされているすべてのグループ、サブグループ、およびプロジェクトに対して適用されますが、ポリシースコープ設定により、その適用セキュリティポリシーをセキュリティポリシーごとに絞り込むことができます。これにより、セキュリティおよびコンプライアンスチームは次のことが可能になります:

- セキュリティポリシーを組織全体で一元的に管理しやすくなり、同時にセキュリティポリシーをきめ細かく適用できます。
- GitLabで実装および適用しているコントロールが、定義したコンプライアンスフレームワークにどのように集約されているかをよりよく理解できます。
- どのセキュリティポリシーがコンプライアンスフレームワークにリンクされているかを、コンプライアンスセンターを通じて表示および管理できます。
- セキュリティおよびコンプライアンスの状態をより適切に整理および理解できます。

### プロダクト分析でユーザーをよりよく理解する {#understand-your-users-better-with-product-analytics}

<!-- categories: Product Analytics Visualization -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/analytics/productivity_analytics.md)

{{< /details >}}

ユーザーがアプリケーションとどのように関わっているかを理解することは、将来のイノベーションと最適化に関するデータ駆動型決定を下す上で重要です。最上位のビジネスクリティカルなURLの利用が増加していますか、月間アクティブユーザーが異常に減少していますか、モバイルAndroidデバイスを使用する顧客が増加していますか？このような質問への回答を得て、GitLabプラットフォームからエンジニアリングチームがそれらにアクセスできるようにすることで、チームは開発作業がユーザー成果にどのように影響しているかを同期させ続けることができます。

GitLabの新しいプロダクト分析機能を使用すると、アプリケーションを計測し、ユーザーに関する主要な使用状況と採用データを収集し、それをGitLab内に表示できます。ダッシュボードでデータを視覚化したり、レポートを作成したり、さまざまな方法でフィルターを適用したりして、ユーザーに関するインサイトを見つけることができます。チームは、イシューを示す顧客利用の予期せぬ低下や急増を迅速に特定して対応できるほか、最近のリリースの成功を祝うこともできます。

プロダクト分析を使用するには、この[Helmチャート](https://gitlab.com/gitlab-org/analytics-section/product-analytics/helm-charts)をインストールし、アプリケーションを計測してトラフィックを送信するためのKubernetesクラスターが必要です。GitLabはその後、クラスターに接続して視覚化のためのデータを取得します。

### エンタープライズユーザーのパーソナルアクセストークンを無効にする {#disable-personal-access-tokens-for-enterprise-users}

<!-- categories: User Management -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/personal_access_tokens.md#disable-personal-access-tokens-for-enterprise-users) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/369504)

{{< /details >}}

GitLab.comグループのオーナーは、グループ内のすべてのエンタープライズユーザーに対して、パーソナルアクセストークンの作成と使用を無効にできるようになりました。パーソナルアクセストークンに関連付けられる強力な権限のため、一部のオーナーはセキュリティ上の理由からこれらのトークンを無効にしたいと考える場合があります。

このきめ細かな制御により、GitLab.comにおけるセキュリティとアクセシビリティのバランスをとるための選択肢が提供されます。

### オートコンプリートによるWikiページへのリンクサポート {#autocomplete-support-for-links-to-wiki-pages}

<!-- categories: Wiki -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/markdown.md#gitlab-specific-references) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/442229)

{{< /details >}}

GitLab 16.11でWikiページへのリンクのオートコンプリートサポートを導入できることを大変嬉しく思います！この新機能により、エピックやイシューからWikiページへのリンクがこれまでになく簡単になりました。数回のキーストロークで完了します。

エピックやイシューのコメントにWikiページのURLをコピー＆ペーストしなければならない日々は終わりました。これで、Wikiページを持つ任意のグループまたはプロジェクトに移動し、エピックまたはイシューにアクセスして、オートコンプリートショートカットを使用して、エピックまたはイシューからWikiページにシームレスにリンクできます。

### プロジェクト概要ページのメタデータ用サイドバー {#sidebar-for-metadata-on-the-project-overview-page}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/working_with_projects.md)

{{< /details >}}

プロジェクト概要ページを再設計しました。これで、すべてのプロジェクト情報とリンクを複数の領域ではなく1つのサイドバーで見つけることができます。

### Switchboardを使用して行われた変更のメール通知 {#email-notifications-for-changes-made-using-switchboard}

<!-- categories: GitLab Dedicated, Switchboard -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Dedicated
- リンク: [ドキュメント](../../administration/dedicated/configure_instance/users_notifications.md) | [関連イシュー](https://about.gitlab.com/dedicated/)

{{< /details >}}

Switchboardを使用してテナント管理者によってGitLab Dedicatedインスタンスに対して行われた設定変更は、完了時にメール通知を生成するようになりました。

Switchboardでテナントを表示または編集するアクセス権を持つすべてのユーザーは、行われた変更ごとに通知を受け取ります。

### いずれかのジョブが失敗した場合に、パイプラインを直ちにキャンセルするオプション {#option-to-cancel-a-pipeline-immediately-if-any-jobs-fails}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/yaml/_index.md#workflowauto_cancelon_job_failure) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/23605)

{{< /details >}}

ジョブが失敗したことに気づいた後、その失敗の原因となっているイシューに取り組んでいる間に、リソースを節約するためにパイプラインの残りの部分を手動でキャンセルすることがあります。GitLab 16.11では、いずれかのジョブが失敗した場合に、パイプラインを自動的にキャンセルするように設定できるようになりました。実行に時間がかかる大規模なパイプライン、特に多数の長時間実行されるジョブが並行して実行される場合、これはリソース使用量とコストを削減する効果的な方法となります。

パイプラインは、[ダウンストリームパイプラインが失敗した場合に直ちにキャンセルするように設定することもできます。これにより、親パイプラインと他のすべてのダウンストリームパイプラインがキャンセルされます。](../../ci/pipelines/downstream_pipelines.md#auto-cancel-the-parent-pipeline-from-a-downstream-pipeline)

この機能にコントリビュートしてくれた[Marco](https://gitlab.com/zillemarco)に感謝します！

## 規模とデプロイ {#scale-and-deployments}

### Omnibusの改善 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- GitLab 17.0では、PostgreSQLのサポートされる最小バージョンが14になります。この変更に備え、GitLab 16.11では`attempt_auto_pg_upgrade?`設定を`true`に変更しました。これにより、PostgreSQLのバージョンを自動的に14にアップグレードしようとします。このプロセスは、前回PostgreSQLのサポートされる最小バージョンを上げたときと同じです。

### プロジェクトアーカイブ機能の更新 {#updated-project-archiving-functionality}

<!-- categories: Groups & Projects -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/working_with_projects.md#archive-a-project)

{{< /details >}}

プロジェクトリストでアーカイブ済みプロジェクトを識別するのが容易になりました。16.11以降、アーカイブ済みプロジェクトはグループ概要の**アーカイブ済み**タブに**アーカイブ済み**バッジを表示します。このバッジは、プロジェクト概要ページのプロジェクトタイトルにも表示されます。

アラートメッセージは、アーカイブ済みプロジェクトが読み取り専用であることを明確にしています。このメッセージはすべてのプロジェクトページで表示され、アーカイブ済みプロジェクトのサブページで作業している場合でもこのコンテキストが失われないようにします。

さらに、グループを削除する際、確認モーダルには、誤った削除を防ぐためにアーカイブ済みプロジェクトの数が表示されるようになりました。

### カスタムWebhookヘッダー {#custom-webhook-headers}

<!-- categories: Webhooks -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/integrations/webhooks.md#custom-headers) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/17290)

{{< /details >}}

以前は、GitLab Webhookはカスタムヘッダーをサポートしていませんでした。これは、特定の名前を持つヘッダーから認証トークンを受け入れるシステムではそれらを使用できなかったことを意味します。

このリリースにより、Webhookを作成または編集する際に、最大20個のカスタムヘッダーを追加できるようになりました。これらのカスタムヘッダーは、外部サービスへの認証に使用できます。

この機能とGitLab 16.10で導入された[カスタムWebhookテンプレート](../../user/project/integrations/webhooks.md#custom-webhook-template)により、カスタムWebhookを完全に設計できるようになりました。次の目的でWebhookを設定できます:

- カスタムペイロードを投稿する。
- 必要な認証ヘッダーを追加する。

シークレットトークンやURL変数と同様に、ターゲットURLが変更されるとカスタムヘッダーはリセットされます。

[Niklas](https://gitlab.com/Taucher2003)の[コミュニティコントリビュート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/146702)に感謝します！

### REST APIでプロジェクトフックをテストする {#test-project-hooks-with-the-rest-api}

<!-- categories: Webhooks -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/projects.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/25329)

{{< /details >}}

以前は、GitLab UIでのみプロジェクトフックをテストできました。このリリースにより、REST APIを使用して、指定されたプロジェクトのテストフックをトリガーすることができるようになりました。

[Phawin](https://gitlab.com/lifez)の[このコミュニティコントリビュート](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147656)に感謝します！

### グループとインスタンス向けに設定可能なGitLab for Slackアプリ {#gitlab-for-slack-app-configurable-for-groups-and-instances}

<!-- categories: Integrations -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/integrations/gitlab_slack_application.md#from-the-project-or-group-settings) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/391526)

{{< /details >}}

以前は、GitLab for Slackアプリを一度に1つのプロジェクトに対してのみ設定できました。このリリースにより、グループまたはインスタンスのインテグレーションを設定し、多くのプロジェクトに一度に変更を加えることが可能になりました。

この改善により、GitLab for Slackアプリは、非推奨となった[Slack通知インテグレーション](../../user/project/integrations/slack.md)との機能の同等性に近づきました。

### 設定可能なインポートジョブの制限 {#configurable-import-jobs-limit}

<!-- categories: Importers -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/settings/import_and_export_settings.md#maximum-number-of-simultaneous-import-jobs) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/439286)

{{< /details >}}

これまで、以下のインポートジョブの最大数は次のとおりでした:

- GitHubインポーターは1000。
- Bitbucket CloudおよびBitbucket Serverインポーターは100。

これらの制限はハードコードされたものであり、変更できませんでした。これらの制限は、インポートの速度を低下させた可能性があります。それは、インポートジョブをキューに入れられたのと同じレートで処理するのに不十分であった可能性があるためです。

このリリースでは、ハードコードされた制限をアプリケーション設定に移動しました。GitLab.comではこれらの制限を増やしていませんが、セルフマネージドGitLabインスタンスの管理者は、必要に応じてインポートジョブの数を設定できるようになりました。

### GitLab Duoでプロダクト分析データを探索する {#explore-your-product-analytics-data-with-gitlab-duo}

<!-- categories: Product Analytics Visualization -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/analytics/productivity_analytics.md)

{{< /details >}}

[プロダクト分析は現在一般提供されており](https://docs.gitlab.com/#understand-your-users-better-with-product-analytics) 、このリリースには[カスタム視覚化デザイナー](../../user/analytics/analytics_dashboards.md)が含まれています。これを使用して、アプリケーションイベントデータを探索し、顧客の利用状況と採用パターンを理解するのに役立つダッシュボードをビルドできます。

視覚化デザイナーでは、プレーンテキストのリクエストを入力することで、GitLab Duoに視覚化をビルドするよう依頼できるようになりました。たとえば、「2024年の月間アクティブユーザー数を表示」や「今週のトップURLをリストアップ」などです。

GitLab Duoプロダクト分析は実験的機能として利用できます。

この[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/455363)で、カスタム視覚化デザイナーでのGitLab Duoのユーザーエクスペリエンスに関するフィードバックを提供することで、この機能の成熟を支援できます。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### グループコメントテンプレート {#group-comment-templates}

<!-- categories: Code Review Workflow, Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/comment_templates.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/440817)

{{< /details >}}

組織全体でイシュー、エピック、またはマージリクエストに同じテンプレート化された応答があることは役立ちます。これらの応答には、回答が必要な標準的な質問、一般的な問題への応答、またはマージリクエストのレビューコメントの構造が含まれる場合があります。

グループコメントテンプレートを使用すると、GitLabのコメントボックスに適用できる保存済み応答を作成して、ワークフローを高速化できます。コメントテンプレートへのこの新しい追加により、組織はテンプレートを一元的に作成および管理できるようになり、すべてのユーザーが同じテンプレートの恩恵を受けることができます。

コメントテンプレートを作成するには、GitLab上の任意のコメントボックスに移動し、**コメントテンプレートの挿入 > Manage group comment templates**を選択します。コメントテンプレートを作成すると、すべてのグループメンバーが利用できるようになります。コメント作成中に**コメントテンプレートの挿入**アイコンを選択すると、保存された応答が適用されます。

私たちはコメントテンプレートのこの次のイテレーションに本当に興奮しており、まもなく[プロジェクトレベルのコメントテンプレート](https://gitlab.com/gitlab-org/gitlab/-/issues/440818)も追加する予定です。何かフィードバックがありましたら、[イシュー45120](https://gitlab.com/gitlab-org/gitlab/-/issues/451520)に残してください。

### Auto DevOpsのビルドステップがアップグレードされました {#build-step-of-auto-devops-upgraded}

<!-- categories: Auto DevOps -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../topics/autodevops/troubleshooting.md#builder-sunset-error) | [関連イシュー](https://gitlab.com/gitlab-org/cluster-integration/auto-build-image/-/issues/73)

{{< /details >}}

Auto DevOpsのAuto Buildコンポーネントで使用されている`heroku/buildpacks:20`イメージがアップストリームで非推奨になったため、`heroku/builder:20`イメージに移行します。

この破壊的変更は、アップストリームの破壊的変更に対応するため、GitLabのメジャーリリースとは別に提供されます。アップグレードによってパイプラインが中断される可能性は低いです。一時的な回避策として、`heroku/builder:20`イメージを手動で設定し、[ビルダー終了エラーをスキップ](../../topics/autodevops/troubleshooting.md#skipping-errors)することもできます。

さらに、GitLab 17.0では`heroku/builder:20`から`heroku/builder:22`への別のメジャーアップグレードを計画しています。

### ユーザーリストの検索とフィルターの改善 {#users-list-search-and-filter-improvements}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/admin_area.md#administering-users) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/238183)

{{< /details >}}

管理者エリアのユーザーページが改善されました。

以前は、タブがユーザーリストの上部に水平にまたがっており、目的のフィルターに移動するのが困難でした。

現在、フィルターは検索ボックスに統合され、ユーザーの検索とフィルターがはるかに容易になりました。

[Ivan Shtyrliaiev](https://www.linkedin.com/in/bahek2462774/)さんのコントリビュートに感謝いたします！

### Webhook通知for expiringグループアクセストークンandプロジェクトアクセストークン {#webhook-notifications-for-expiring-group-and-project-access-tokens}

<!-- categories: System Access -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/integrations/webhook_events.md#project-and-group-access-token-events) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/426147)

{{< /details >}}

プロジェクトとグループアクセストークンのWebhookイベントが利用可能になりました。

以前は、有効期限が切れるトークンに関する通知を受け取る唯一の方法はメールでした。Webhookイベントは、トリガーされた場合、アクセストークンの有効期限が切れる7日前にトリガーされます。

### リンクされたセキュリティポリシーをコンプライアンスフレームワークに表示する {#display-linked-security-policies-in-compliance-frameworks}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_frameworks/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11480)

{{< /details >}}

コンプライアンスセンターがコンプライアンスマネージャーの司令塔となるにつれて、コンプライアンスフレームワークを管理できるようになり、セキュリティポリシーを通じて作成され、コンプライアンスフレームワークにリンクされたコントロールに関するインサイトも得られます。

これらの広範なコントロールを通じて、コンプライアンスのスコープ内のプロジェクトでセキュリティスキャナーを実行するよう強制したり、2名承認を強制したり、脆弱性管理ワークフローを有効にしたりし、それらをコンプライアンスフレームワークに集約することで、フレームワーク内の関連プロジェクトがコントロールによって適切に適用されるようにします。

### APIでアプリケーションのシークレットを更新する {#renew-application-secret-with-api}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../api/applications.md#renew-an-application-secret) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/422420)

{{< /details >}}

アプリケーションAPIを使用してアプリケーションのシークレットを更新できるようになりました。以前は、これを実行するにはUIを使用する必要がありました。これで、APIを使用してシークレットをプログラム的にローテーションできます。

[Phawin](https://gitlab.com/lifez)さんのコントリビュートに感謝いたします！

### ポリシーボットコメントを違反データで拡張する {#extend-policy-bot-comment-with-violation-data}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/merge_request_approval_policies.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/433403)

{{< /details >}}

セキュリティポリシーボットは、セキュリティポリシーがプロジェクトに適用される時期、評価が完了する時期、およびMRをブロックしている違反があるかどうかを理解するためのコンテキストをユーザーに提供し、それらを解決するためのガイダンスも提供します。ボットコメントのサポートを拡張し、MRがセキュリティポリシーによってブロックされる理由に関する追加のインサイトと、解決する方法に関するよりきめ細かなフィードバックを提供するようになりました。コメントによって提供される詳細には、次のものが含まれます:

- MRを具体的にブロックしているセキュリティ上の検出結果
- ポリシーに反するライセンス
- ポリシーエラーが、デフォルトで「フェイルクローズ」とブロッキング動作につながる可能性
- セキュリティ上の検出結果の評価で考慮されているパイプラインに関する詳細

これらの追加の詳細により、MRの状態をより迅速に理解し、あらゆるイシューをトラブルシューティングを行うためのセルフサービスを利用できるようになりました。

### ワークロードアイデンティティフェデレーションでGoogle Cloudに認証する {#authenticate-to-google-cloud-with-workload-identity-federation}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../integration/google_cloud_iam.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/12758)

{{< /details >}}

ワークロードアイデンティティフェデレーションを使用すると、サービスアカウントキーを使用せずに、GitLabとGoogle Cloud間でワークロードを安全に接続できます。これは、キーが攻撃ベクトルを公開する可能性のある長期的な認証情報になる可能性があるため、セキュリティを向上させます。キーには、作成、保護、ローテーションのための管理オーバーヘッドも伴います。

ワークロードアイデンティティフェデレーションを使用すると、GitLabとGoogle Cloud間でIAMロールをマップできます。

この機能はベータ版であり、現在GitLab.comでのみ利用可能です。

### 重複するセキュリティポリシーに関するイシューが解決されました {#issue-with-duplicate-security-policies-resolved}

<!-- categories: Security Policy Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/policies/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/416903)

{{< /details >}}

GitLab 16.9および以前では、プロジェクトが親グループまたはサブグループからセキュリティポリシーを継承するとともに、同じセキュリティポリシープロジェクトにリンクすることが可能でした。その結果、セキュリティポリシーリストでセキュリティポリシーが重複していました。

このイシューは解決され、セキュリティポリシーがすでに継承されているセキュリティポリシープロジェクトにリンクすることはできなくなりました。

### より多くのユーザー名オプション {#more-username-options}

<!-- categories: User Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/profile/_index.md#change-your-username) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/429283)

{{< /details >}}

ユーザー名には、アクセントのない文字、数字、アンダースコア（`_`）、ハイフン（`-`）、およびピリオド（`.`）のみを含めることができます。ユーザー名はハイフン（`-`）で開始したり、ピリオド（`.`）、`.git`、または`.atom`で終了したりしてはなりません。

ユーザー名検証は、この基準をより正確に示しています。この改善された検証により、ユーザー名を選択する際のオプションがより明確になります。

[Justin Zeng](https://www.linkedin.com/in/jzeng88/)さんのコントリビュートに感謝いたします！

### サイドバーでのGitLab Pagesの表示レベルが改善されました {#improved-gitlab-pages-visibility-in-sidebar}

<!-- categories: Pages -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/pages/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/18027)

{{< /details >}}

以前のリリースでは、GitLab Pagesサイトを持つプロジェクトの場合、サイトURLを見つけるのが困難でした。

GitLab 16.11以降、右サイドバーにサイトへのショートカットリンクが追加されたため、ドキュメントを確認することなくURLを見つけることができます。

### GoogleアーティファクトのレジストリをGitLabプロジェクトに接続する {#connect-google-artifact-registry-to-your-gitlab-project}

<!-- categories: Container Registry -->

{{< details >}}

- プラン: Free、Silver、Gold
- リンク: [ドキュメント](../../user/project/integrations/google_artifact_management.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/12365)

{{< /details >}}

GitLabコンテナレジストリを使用して、ソースコードやパイプラインとともにDockerおよびOCIイメージを表示、プッシュする、プルするできます。多くのGitLabのお客様にとって、これは`test`および`build`フェーズでのコンテナイメージに最適です。しかし、組織が本番環境イメージをGoogleのようなクラウドプロバイダーに公開することは一般的です。

以前は、GitLabからGoogleアーティファクトのレジストリにイメージをプッシュするするには、アーティファクトのレジストリに接続してデプロイするためのカスタムスクリプトを作成および維持する必要がありました。これは非効率的でエラーが発生しやすかったです。さらに、すべてのコンテナイメージの全体像を簡単に把握する方法はありませんでした。

これで、新しいGoogleアーティファクト管理機能を活用して、GitLabプロジェクトをアーティファクトのレジストリリポジトリに簡単に接続できます。次に、GitLab CI/CDパイプラインを使用して、アーティファクトのレジストリにイメージを公開できます。**デプロイ > Googleアーティファクトのレジストリ**に移動して、GitLabのアーティファクトのレジストリに公開されたイメージを表示することもできます。イメージの詳細を表示するには、単にイメージを選択します。

この機能はベータ版であり、現在GitLab.comでのみ利用可能です。

### 色を使用してエピックを視覚的に区別する {#visually-distinguish-epics-using-colors}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/epics/manage_epics.md#epic-color) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/9033)

{{< /details >}}

組織全体でポートフォリオ管理機能をさらに向上させるために、[ロードマップ](../../user/group/roadmap/_index.md)と[エピックボード](../../user/group/epics/epic_boards.md)で色を使用してエピックを区別できるようになりました。

この軽量でありながら多用途な機能により、グループの所有権、ライフサイクルのパイプラインステージ、成熟に向けた開発、またはその他の多くの分類を迅速に区別できます。

### バリューストリームイベントが累積的に計算可能になりました {#value-stream-events-can-now-be-calculated-cumulatively}

<!-- categories: Value Stream Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/group/value_stream_analytics/_index.md#cumulative-label-event-duration) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/12088)

{{< /details >}}

ラベルイベント間の期間を計算するためのより堅牢な方法を導入しました。この変更は、開発からレビュー状態へとマージリクエストのラベルが何度も変更されるなど、イベントが複数回発生するシナリオに対応します。以前は、期間は最初と最後のラベルイベント間の合計経過時間として計算されていました。

現在、期間は累積時間として計算されます。つまり、イシューまたはマージリクエストに特定のラベルが付与されていた時間のみを正しく表すようになりました。

### 依存関係グラフによる依存関係スキャンSBOMのサポート {#dependency-graph-support-for-dependency-scanning-sboms}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_list/_index.md) | [関連エピック](https://gitlab.com/gitlab-org/gitlab/-/issues/366168)

{{< /details >}}

ユーザーは、依存関係スキャンレポートの一部として生成されたCycloneDX SBOM内の依存関係グラフ情報にアクセスできます。依存関係グラフ情報は、次のパッケージマネージャーで利用できます:

- NuGet
- Yarn 1.x
- sbt
- Conan

### Yarn v4の依存関係スキャンサポート {#dependency-scanning-support-for-yarn-v4}

<!-- categories: Software Composition Analysis -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/dependency_scanning/legacy_dependency_scanning/_index.md#supported-languages-and-package-managers) | [関連エピック](https://gitlab.com/gitlab-org/gitlab/-/issues/431752)

{{< /details >}}

依存関係スキャンはYarn v4をサポートしています。この機能強化により、アナライザーはYarn v4ロックファイルを解析するできます。

### DASTアナライザーのパフォーマンス更新 {#dast-analyzer-performance-updates}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/application_security/dast/browser/_index.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/12194)

{{< /details >}}

16.11リリースマイルストーン中に、次のDAST改善を完了しました:

- クローラーのパフォーマンスを向上させるためにナビゲーションパスを短縮しました。これにより、ベンチマークテストによるとスキャン時間が20％短縮されました。詳細については、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/430815)を参照してください。
- DASTレポートを最適化してメモリ使用量を削減しました。これにより、DASTスキャン中のRunnerのメモリスパイクが減少しました。詳細については、[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/444180)を参照してください。

### GitLabからGoogle Compute Engine Runnerの作成を自動化する - パブリックベータ版 {#automate-the-creation-of-google-compute-engine-runners-from-gitlab---public-beta}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Silver、Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/runners/provision_runners_google_cloud.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/13494)

{{< /details >}}

以前は、Google Compute EngineでGitLab Runnerを作成するには、GitLabとGoogle Cloudからの複数のコンテキストスイッチが必要でした。

これで、GitLab Runner Infrastructure ToolkitからTerraformテンプレートとGitLabを使用して、Google Compute EngineでGitLab Runnerを簡単にプロビジョニングするできます。これにより、Runnerをデプロイし、Google Cloudインフラストラクチャをプロビジョニングすることができます。複数システム間でスイッチする必要はありません。

### 特定の終了コードを持つ失敗したCIジョブの自動再試行を改善する {#improve-automatic-retry-for-failed-ci-jobs-with-specific-exit-codes}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/yaml/_index.md#retry) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/262674)

{{< /details >}}

以前は、`retry:max`に加えて`retry:when`を使用して、スクリプトが失敗した場合など、特定の失敗が発生したときにジョブが再試行される回数を設定できました。

このリリースにより、[`retry:exit_codes`](../../ci/yaml/_index.md#retryexit_codes)を使用して、特定のスクリプト終了コードに基づいて失敗したジョブの自動再試行を設定できるようになりました。`retry:exit_codes`を`retry:when`および`retry:max`と組み合わせて使用することで、特定のニーズに合わせてパイプラインの動作を微調整し、パイプラインの実行を改善できます。

[Baptiste Lalanne](https://gitlab.com/BaptisteLalanne)さんのコミュニティコントリビュートに感謝いたします！

### GitLab Runner 16.11 {#gitlab-runner-1611}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 16.11もリリースします！GitLab Runnerは、CI/CDジョブを実行し、結果をGitLabインスタンスに送信する、軽量で拡張性の高いエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### バグ修正 {#bug-fixes}

- [クラッシュ: 致命的エラー: 同時マップ読み取りとマップ書き込み](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/31077)
- [FF_KUBERNETES_HONOR_ENTRYPOINT機能が動作しない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/37243)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-11-stable/CHANGELOG.md)にあります。

### HashiCorp Vaultシークレットサポートの拡張（ArtifactoryとAWSを含む） {#expanded-hashicorp-vault-secrets-support-including-artifactory-and-aws}

<!-- categories: Secrets Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/secrets/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/366492)

{{< /details >}}

HashiCorp VaultとのGitLabインテグレーションは、より多くの種類のシークレットをサポートするように拡張されました。GitLab Runner 16.11で導入された、`generic`タイプのシークレットエンジンを選択できるようになりました。この汎用エンジンは、HashiCorp Vault [Artifactoryシークレットプラグイン](https://jfrog.com/help/r/jfrog-integrations-documentation/hashicorp-vault-artifactory-secrets-plugin)および[AWSシークレットエンジン](https://developer.hashicorp.com/vault/docs/secrets/aws)をサポートしています。このオプションを使用して、必要なシークレットを安全に取得し、GitLab CI/CDパイプラインで使用してください！

[Ivo Ivanov](https://gitlab.com/urbanwax)さんのこの素晴らしいコントリビュートに心から感謝します！

### ジョブアーティファクトをダウンロードできるユーザーを制御する {#control-who-can-download-job-artifacts}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/yaml/_index.md#artifactsaccess) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/428677)

{{< /details >}}

デフォルトでは、公開パイプライン内のCI/CDジョブから生成されたすべてのアーティファクトは、パイプラインへのアクセス権を持つすべてのユーザーがダウンロードできます。ただし、アーティファクトをダウンロードすべきではない、またはより高いアクセスレベルを持つチームメンバーのみがダウンロードできるようにすべき場合があります。

そこでこのリリースでは、`artifacts:access`キーワードを追加しました。現在、ユーザーは、アーティファクトをパイプラインへのアクセス権を持つすべてのユーザーがダウンロードできるか、デベロッパーロール以上のユーザーのみがダウンロードできるか、まったく誰もダウンロードできないかを制御できます。

### 改善されたパイプライン詳細ページ {#improved-pipeline-details-page}

<!-- categories: Pipeline Composition -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../ci/pipelines/_index.md#view-pipelines)

{{< /details >}}

パイプライングラフは、パイプラインの包括的な概要を提供し、ジョブステータス、ランタイム更新、複数プロジェクトパイプライン、および親子パイプラインを表示します。

本日、美的センスが向上し、ジョブのグループ化された視覚化、改善されたモバイル体験、および既存のビュー内でのダウンストリームパイプラインの表示レベルが拡張された、再設計されたパイプライングラフのリリースを発表できることを嬉しく思います。

ぜひお試しいただき、この専用の[イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/450676)を通じてフィードバックを共有していただければ幸いです。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.11)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.11)
- [UI改善](https://papercuts.gitlab.com/?milestone=16.11)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
