---
stage: Release Notes
group: Monthly Release
date: 2023-10-22
title: "GitLab 16.5リリースノート"
description: "GitLab 16.5がコンプライアンス基準遵守レポートとともにリリースされました"
---

<!-- markdownlint-disable -->
<!-- vale off -->

2023年10月22日、GitLab 16.5が以下の機能とともにリリースされました。

さらに、今月の注目すべきコントリビューターを含む、すべてのコントリビューターに感謝します。

## 今月の注目すべきコントリビューター: Thorben Westerhuys {#this-months-notable-contributor-thorben-westerhuys}

Thorbenは、[24時間形式で時刻を表示するユーザー設定を追加する](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130789)ためのマージリクエストにおける継続的な作業が評価されました。この機能は16.6で計画されており、ユーザーは12時間形式と24時間形式のどちらかを選択できるようになります。

GitLabのプロダクトマネージャーであるMagdalena FrankiewiczはThorbenを指名し、この機能のイシューが7年間で190件以上の同意するを獲得していると指摘しました。GitLabのスタッフバックエンドエンジニアであるPeter Leitzenも、Thorbenによる[時刻形式に関連するバックエンドコードをリファクタリングする](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130794)作業に注目しました。

Thorbenは、高解像度のGeoデータを統合する3DウェブプラットフォームであるLUUCYのCTOです。彼は、都市計画関連のトピックを扱う地理空間データコンサルタント会社cividiの元CTOです。

ThorbenとGitLabコミュニティの皆様、貢献ありがとうございます🙌

## 主要な機能 {#primary-features}

### コンプライアンス基準遵守レポート {#compliance-standards-adherence-report}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_center/_index.md)

{{< /details >}}

コンプライアンスセンターに、レポートの新しいタブが追加されました。このレポートには、最初にGitLabのベストプラクティス標準が含まれており、グループ内のプロジェクトが標準に含まれるチェックの要件を満たしていない場合に表示されます。最初に表示される3つのチェックは次のとおりです:

- 承認ルールは、MRに2人以上の承認者を要求するために存在します。
- 承認ルールは、MRの作成者がマージすることを禁止するために存在します。
- 承認ルールは、MRへのコミッターがマージすることを禁止するために存在します。

このレポートには、プロジェクトごとの各チェックのステータスに関する詳細が含まれています。また、チェックが最後に実行された日時、チェックが適用される標準、およびレポートに表示される可能性のある失敗や問題を修正する方法も表示されます。今後のイテレーションでは、より多くのチェックが追加され、より多くの規制と標準を含めるようにスコープが展開する予定です。さらに、レポートをグループ化およびフィルター処理する改善も追加するため、組織にとって最も重要なプロジェクトまたは標準に集中できます。

### ターゲットブランチを設定するマージリクエストのルールを作成する {#create-rules-to-set-target-branches-for-merge-requests}

<!-- categories: Code Review Workflow -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/repository/branches/_index.md#configure-workflows-for-target-branches)

{{< /details >}}

一部のプロジェクトでは、`develop`や`qa`など、複数の長期ブランチを開発に使用します。これらのプロジェクトでは、プロジェクトの本番環境状態を表すため、`main`をデフォルトブランチとして維持したい場合があります。ただし、開発作業ではマージリクエストが`develop`または`qa`をターゲットブランチにすることを想定しています。ターゲットブランチルールは、マージリクエストがプロジェクトと開発ワークフローに適したブランチをターゲットブランチに設定することを保証するのに役立ちます。

マージリクエストを作成すると、ルールはブランチの名前をチェックします。ブランチ名がルールに一致する場合、マージリクエストはルールで指定したブランチをターゲットブランチとして事前に選択します。ブランチ名が一致しない場合、マージリクエストはプロジェクトのデフォルトブランチをターゲットとします。

### イシュースレッドを解決する {#resolve-an-issue-thread}

<!-- categories: Team Planning -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/discussions/_index.md#resolve-a-thread) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/31114)

{{< /details >}}

多数のスレッドを持つ長期間のイシューは、読み取りと追跡するのが難しい場合があります。ディスカッションのトピックが完了した場合に、イシューのスレッドを解決することができるようになりました。

### 半線形履歴を持つ早送りマージトレイン {#fast-forward-merge-trains-with-semi-linear-history}

<!-- categories: Merge Trains -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../ci/pipelines/merge_trains.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/26996)

{{< /details >}}

16.4では[早送りマージトレイン](https://about.gitlab.com/releases/2023/09/22/gitlab-16-4-released/#fast-forward-merge-support-for-merge-trains)をリリースし、その継続として、すべての[マージメソッド](../../user/project/merge_requests/methods/_index.md)をサポートしたいと考えています。これで、半線形コミット履歴が維持されるようにしたい場合は、半線形早送りマージトレインを使用できます。

## 規模とデプロイ {#scale-and-deployments}

### 高度な検索でエピックを検索する {#find-epics-with-advanced-search}

<!-- categories: Global Search -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/search/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/250699)

{{< /details >}}

GitLabにおけるエピックの人気は高まり続けています。以前は、エピックを見つけることは、他のコンテンツタイプよりも少し困難でした。このリリースにより、高度な検索を使用すると、エピックの検索と結果の表示が可能になりました。

### Omnibusの改善 {#omnibus-improvements}

<!-- categories: Omnibus Package -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/omnibus/)

{{< /details >}}

- GitLab 16.5の`.deb`Linuxパッケージは、[gzipからxz圧縮に切り替わり](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8197)、パッケージサイズが縮小されました。この変更により、インストール中の解凍時間が遅くなる可能性があります。
- GitLab 16.5には[Mattermost 9.0](https://docs.mattermost.com/install/self-managed-changelog.html#release-v9-0-major-release)が含まれています。このバージョンでは、非推奨のインサイト機能が削除され、[Mattermostボードとさまざまなプラグインがコミュニティサポートに移行](https://forum.mattermost.com/t/upcoming-product-changes-to-boards-and-various-plugins/16669)しました。
- GitLab 16.5では、[GitLab SELinuxポリシーモジュールを](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/7165)`/opt/gitlab/embedded/selinux/rhel/7/`から`/opt/gitlab/embedded/selinux`に移動することで、このモジュールがRHEL 7専用ではないことを反映しています。

### Jira開発パネルにおけるマージリクエストのレビュアー情報 {#reviewer-information-for-merge-requests-in-the-jira-development-panel}

<!-- categories: Integrations -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../integration/jira/development_panel.md#information-displayed-in-the-development-panel) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/364273)

{{< /details >}}

[GitLab for Jira Cloudアプリ](../../integration/jira/connect-app.md)を使用すると、GitLabとJira Cloudを接続して開発情報をリアルタイムで同期できます。この情報は、Jira開発パネルで表示できます。以前は、マージリクエストにレビュアーが割り当てられた場合、レビュアー情報はJira開発パネルに表示されませんでした。このリリースにより、GitLab for Jira Cloudアプリを使用すると、レビュアー名、メール、承認ステータスがJira開発パネルに表示されます。

### コンテキストの変更がより簡単に {#changing-context-just-got-easier}

<!-- categories: Navigation & Settings -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../tutorials/left_sidebar/_index.md)

{{< /details >}}

左サイドバーでは、検索ボタンを見つけたり、プロジェクトや設定などの間で切り替えたりするのが難しいというフィードバックをいただいていました。今回のリリースでは、ボタンをより目立つようにしました。これにより、発見しやすさが向上し、ワークフローを単一のタッチポイントに合理化できます。

**検索または移動先**ボタンを選択するか、/またはsと入力してキーボードショートカットで試すことができます。

### リリースが削除されたときにWebhookがトリガーされるようになりました {#webhook-now-triggered-when-a-release-is-deleted}

<!-- categories: Webhooks -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/integrations/webhook_events.md#release-events) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/418113)

{{< /details >}}

リリースイベントを使用して、リリースオブジェクトを監視し、変更に対応できます。以前は、リリースが作成または更新された場合にのみ、Webhookがトリガーされていました。厳しく規制された業界では、リリースの削除は監視および追跡されなければならない重要なイベントです。GitLab 16.5では、リリースが削除された場合にもWebhookがトリガーされるようになりました。

### 再設計されたサービスデスクイシューリスト {#redesigned-service-desk-issues-list}

<!-- categories: Service Desk -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../user/project/service_desk/using_service_desk.md)

{{< /details >}}

私たちはサービスデスクイシューリストを、より速く、よりスムーズに読み込むように再設計しました。これにより、通常のイシューリストにより近づきました。利用可能な機能:

- イシューリストと同じソートおよび並べ替えオプション。
- OR演算子やイシューIDによるフィルターを含む、同じフィルター。

### Geoがすべてのコンポーネントに一括再同期および再検証ボタンを追加 {#geo-adds-bulk-resync-and-reverify-buttons-for-all-components}

<!-- categories: Geo-replication, Disaster Recovery -->

{{< details >}}

- プラン: Premium、Ultimate
- リンク: [ドキュメント](../../administration/geo/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/8212)

{{< /details >}}

Geo管理UIのボタンを介して、Geoによって管理されているあらゆるデータコンポーネントの一括再同期または再検証をトリガーすることができます。ボタンを選択すると、操作がそれぞれのコンポーネントに関連するすべてのデータアイテムに適用されます。以前は、これはRailsコンソールにログインすることによってのみ可能でした。これらのアクションはよりアクセスしやすくなり、トラブルシューティングや、ストレージ場所の移動など、特定のコンポーネントの完全な再同期または再検証を必要とする大規模な変更の適用体験が向上しました。

### クラウド上のリポジトリデータをバックアップおよび復元する {#back-up-and-restore-repository-data-in-the-cloud}

<!-- categories: Gitaly, Backup/Restore of GitLab instances -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../administration/backup_restore/backup_gitlab.md#create-server-side-repository-backups) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10826)

{{< /details >}}

GitLabのバックアップおよび復元する機能は、リポジトリデータをオブジェクトストレージに保存することをサポートするようになりました。この更新により、大きなtarballを作成するために使用される中間ステップが不要になり、パフォーマンスが向上します。tarballは手動で適切な場所に保存する必要がありました。

この更新により、リポジトリバックアップは、選択したオブジェクトストレージの場所（Amazon S3、Google Cloud Storage、Azure Cloud Data Storage、MinIOなど）に保存されます。この変更により、Gitalyインスタンスからデータを手動で移動する必要がなくなります。

## 統合されたDevOpsとセキュリティ {#unified-devops-and-security}

### デプロイ承認と承認ルールの変更を監査イベントに統合 {#integrate-deployment-approval-and-approval-rule-changes-into-audit-events}

<!-- categories: Environment Management -->

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/audit_event_types.md#environment-management) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/415603)

{{< /details >}}

規制された業界におけるデプロイは、コンプライアンスの中心的なトピックです。以前のリリースでは、デプロイ承認は監査イベントの一部ではなかったため、承認ルールがいつどのように変更されたかを判断することが困難でした。

GitLabは、デプロイ承認および承認ルールの変更に関する新しい監査イベントセットを提供するようになりました。これらのイベントは、デプロイ承認ルールが変更された場合、または保護環境の承認ルールが変更された場合に発生します。

### APIを使用してユーザーのSAMLおよびSCIMアイデンティティを削除する {#use-the-api-to-delete-a-users-saml-and-scim-identities}

<!-- categories: User Management -->

{{< details >}}

- プラン: Silver, Gold
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../api/scim.md#delete-a-single-scim-identity) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/423592)

{{< /details >}}

以前は、グループオーナーはSAMLまたはSCIMのアイデンティティをプログラムで削除する方法がありませんでした。これにより、ユーザーのプロビジョニングとサインインプロセスに関するイシューのトラブルシューティングを行うことが困難でした。現在、グループオーナーは新しいエンドポイントを使用してこれらのアイデンティティを削除できます。

[jgao1025](https://gitlab.com/jgao1025)さんのコントリビュートに感謝します！

### コンプライアンス違反レポートをエクスポートする {#export-the-compliance-violations-report}

<!-- categories: Compliance Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/compliance/compliance_center/_index.md)

{{< /details >}}

コンプライアンス違反レポートには多くの情報が含まれる可能性があります。以前は、情報をGitLab UIでのみ表示できました。これは個々のイシューには問題ありませんでしたが、例えば次のような場合は複雑になる可能性があります:

- リリースの現在のコンプライアンスステータスのアーティファクトを作成する。例えば、監査担当者に違反が0件であることを証明する。
- データを別のデータセットと集約するか、別のツールで処理します。

GitLab 16.5では、コンプライアンス違反レポートに含まれるアイテムのリストをCSV形式でエクスポートすることができるようになりました。

### 新しいカスタマイズ可能なパーミッション {#new-customizable-permissions}

<!-- categories: User Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/custom_roles/_index.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/17364)

{{< /details >}}

グループメンバーおよびプロジェクトアクセストークンを管理する権限が、カスタムロールフレームワークに追加されました。これらの権限を任意のベースロールに追加して、カスタムロールを作成できます。特定のタスクを達成するために必要な権限のみを持つカスタムロールを作成することで、メンテナーやオーナーのような高度な権限を持つロールをユーザーに不必要に割り当てる必要がなくなります。

### インスタンスレベルの監査イベントストリーミングからGoogle Cloud Loggingへ {#instance-level-audit-event-streaming-to-google-cloud-logging}

<!-- categories: Audit Events -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../administration/compliance/audit_event_reports.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11061)

{{< /details >}}

以前は、Google Cloud Loggingに対してトップレベルグループの監査イベントストリーミングのみを設定できました。

GitLab 16.5では、Google Cloud Loggingのサポートをインスタンスレベルのストリーミング先に拡張しました。

### 設定可能なロックされたユーザーポリシー {#configurable-locked-user-policy}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../security/unlock_user.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/27048)

{{< /details >}}

管理者は、サインイン試行の回数とユーザーのロック期間を選択することで、インスタンスのロックされたユーザーポリシーを設定できるようになりました。例えば、5回のサインイン試行の失敗で、ユーザーは60分間ロックされます。これにより、管理者は、セキュリティおよびコンプライアンスの要件を満たすロックされたユーザーポリシーを定義できます。以前は、サインイン試行回数とロックされたユーザーの期間は設定できませんでした。

### 監査イベントストリーミングのヘッダーをアクティブ化および非アクティブ化 {#activate-and-deactivate-headers-for-streaming-audit-events}

<!-- categories: Audit Events -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/compliance/audit_event_reports.md) | [関連イシュー](https://gitlab.com/groups/gitlab-org/-/epics/11109)

{{< /details >}}

以前は、一時的に非アクティブ化したい場合でも、監査イベントストリーミングストリーミング先に追加されたHTTPヘッダーを削除する必要がありました。

GitLab 16.5では、GitLab UIの**アクティブ**チェックボックスを使用して、各ヘッダーを個別にオン/オフを切替できます。これは次の目的で使用できます:

- 異なるヘッダーをテストする。
- 一時的にヘッダーを非アクティブ化する。
- 同じヘッダーの2つのバージョンを切り替える。

### 現在認証済みユーザー用のPATを作成するAPI {#api-to-create-pat-for-currently-authenticated-user}

<!-- categories: System Access -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](../../api/users.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/425171)

{{< /details >}}

現在認証済みユーザー用の新しいパーソナルアクセストークンを作成するために、`user/personal_access_tokens`の新しいREST APIエンドポイントを使用できるようになりました。このトークンのスコープはセキュリティ上の理由から`k8s_proxy`に制限されているため、Kubernetes用のエージェントを使用してKubernetesAPIコールのみを実行するために使用できます。以前は、インスタンス管理者のみが[APIを介してパーソナルアクセストークンを作成する](../../api/users.md)ことができました。

### 脆弱性レポートのステータスと重大度によるグループ化 {#vulnerability-report-grouping-by-status-and-severity}

<!-- categories: Vulnerability Management -->

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/application_security/vulnerability_report/_index.md#group-vulnerabilities) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/10164)

{{< /details >}}

ユーザーとして、脆弱性をより効率的にトリアージできるように脆弱性をグループ化する機能が必要です。このリリースにより、重大度またはステータスでグループ化できるようになりました。これにより、グループまたはプロジェクトに確認済みの脆弱性がいくつあるか、またはまだトリアージする必要がある脆弱性がいくつあるかといった質問に、より適切に答えることができます。

### 個別のWikiページをPDFとしてエクスポートする {#export-individual-wiki-pages-as-pdf}

<!-- categories: Wiki -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/wiki/_index.md#export-a-wiki-page) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/414691)

{{< /details >}}

GitLab 16.5から、個別のWikiページをPDFファイルとしてエクスポートすることができます。これで、チームの知識共有がさらにシームレスになりました。WikiをPDFにエクスポートすることは、さまざまなユースケースに利用できます。例えば、Wikiに保存されている技術ドキュメントのコピーを提供したり、プロジェクトのステータスとWiki内の情報を共有したりできます。一部の組織ではこれらのツールを使用することが禁止されており、別の課題となっていたMarkdownファイルをPDFに変換するための代替ツールを活用する必要はなくなりました。JiHuによるこの機能の貢献に感謝します！

### タスク、目標、または主な成果の子アイテムをクイックアクションで追加する {#add-a-child-task-objective-or-key-result-with-a-quick-action}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/quick_actions.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/420797)

{{< /details >}}

`/add_child`クイックアクションを使用して、タスク、目標、または主な成果の子アイテムを追加できるようになりました。

### タスク、目標、および主な成果におけるリンクされたアイテムウィジェット {#linked-items-widget-in-tasks-objectives-and-key-results}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/okrs.md#linked-items-in-okrs) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/416558)

{{< /details >}}

このリリースにより、[タスク](../../user/tasks.md#linked-items-in-tasks)と[OKR](../../user/okrs.md#linked-items-in-okrs)を「関連」、「ブロック元」、「ブロック中」としてリンクし、依存する作業アイテムと関連する作業アイテム間の追跡可能性を提供できるようになりました。

[エピック](https://gitlab.com/groups/gitlab-org/-/epics/9290)と[イシュー](https://gitlab.com/groups/gitlab-org/-/epics/9584)を作業アイテムフレームワークに移行すると、これらすべてのタイプ間でリンクできるようになります。

### タスク、目標、または主な成果の親をクイックアクションで設定する {#set-a-parent-for-a-task-objective-or-key-result-with-a-quick-action}

<!-- categories: Portfolio Management -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../user/project/quick_actions.md) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/420798)

{{< /details >}}

`/set_parent`クイックアクションを使用して、タスク、目標、または主な成果の親アイテムを設定することができるようになりました。

### DASTアナライザーの更新 {#dast-analyzer-updates}

<!-- categories: DAST -->

{{< details >}}

- プラン: Ultimate
- リンク: [ドキュメント](../../user/application_security/dast/browser/checks/_index.md) | [関連エピック](https://gitlab.com/groups/gitlab-org/-/epics/11426)

{{< /details >}}

16.5リリースマイルストーン中に、ブラウザベースのDASTに対して次のアクティブなチェックをデフォルトで有効にしました:

- チェック78.1はZAPチェック90020を置き換え、コマンドインジェクションを特定します。コマンドインジェクションは、ターゲットアプリケーションサーバー上で任意のOSコマンドを実行することによって悪用される可能性があります。これは、システム全体を侵害する可能性のある重大な脆弱性です。
- チェック611.1はZAPチェック90023を置き換え、外部XMLエンティティインジェクション (XXE)を特定します。これは、アプリケーションのXMLパーサーに外部リソースを含ませることによって悪用される可能性があります。
- チェック94.4はZAPチェック90019を置き換え、「Server-sideコードインジェクション (NodeJS)」を特定します。これは、サーバーで実行される任意のJavaScriptコードを挿入することによって悪用される可能性があります。
- チェック113.1はZAPチェック40003を置き換え、「HTTPヘッダーにおけるCRLFシーケンスの不適切な無効化（「HTTP応答スプリット」）」を特定します。これは、キャリッジリターン/ラインフィード（CRLF）文字を挿入して、任意のデータをHTTP応答に挿入することによって悪用される可能性があります。

### ジョブAPIエンドポイントのレート制限を設定可能にする {#make-jobs-api-endpoint-rate-limit-configurable}

<!-- categories: Continuous Integration (CI) -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com
- リンク: [ドキュメント](../../administration/settings/user_and_ip_rate_limits.md#maximum-authenticated-requests-to-projectidjobs-per-minute) | [関連イシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/395702)

{{< /details >}}

最近、`project/:id/jobs` APIエンドポイントのレート制限が追加され、ユーザーあたり毎分600リクエストがデフォルトになりました。フォローアップのイテレーションとして、この制限を設定可能にし、インスタンス管理者が要件に最適な制限を設定できるようにしています。

### GitLab Runner 16.5 {#gitlab-runner-165}

<!-- categories: GitLab Runner Core -->

{{< details >}}

- プラン: Free、Premium、Ultimate
- リンク: [ドキュメント](https://docs.gitlab.com/runner)

{{< /details >}}

本日、GitLab Runner 16.5もリリースします！GitLab Runnerは、CI/CDジョブを実行し、結果をGitLabインスタンスに送信する、軽量で拡張性の高いエージェントです。GitLab Runnerは、GitLabに含まれるオープンソースの継続的インテグレーションサービスであるGitLab CI/CDと連携して動作します。

#### 新機能 {#whats-new}

- [GitLab RunnerのAWS EC2インスタンス向けフリートプラグイン - ベータ](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29404)

#### バグ修正 {#bug-fixes}

- [Runnerマネージャーのk8sポッドの終了により、孤立したワーカーポッドが発生する](https://gitlab.com/gitlab-org/gitlab/-/issues/390645)
- [GitLab Runner 15.8.0は特殊文字を含むブランチをcheckoutできない](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29606)
- [GitLab Runnerがarm64コンピューティングホストでarm64ヘルパーイメージではなくx86-64ヘルパーイメージをプルする](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/27768)

GitLab Runnerのすべての変更リストは[変更履歴](https://gitlab.com/gitlab-org/gitlab-runner/blob/16-5-stable/CHANGELOG.md)にあります。

## 関連トピック {#related-topics}

- [バグ修正](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=type%3A%3Abug&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.5)
- [パフォーマンス改善](https://gitlab.com/groups/gitlab-org/-/issues/?sort=updated_desc&state=closed&label_name%5B%5D=bug%3A%3Aperformance&or%5Blabel_name%5D%5B%5D=workflow%3A%3Acomplete&or%5Blabel_name%5D%5B%5D=workflow%3A%3Averification&or%5Blabel_name%5D%5B%5D=workflow%3A%3Aproduction&milestone_title=16.5)
- [UI改善](https://papercuts.gitlab.com/?milestone=16.5)
- [非推奨化と削除](../../update/deprecations.md)
- [アップグレードノート](../../update/versions/_index.md)
