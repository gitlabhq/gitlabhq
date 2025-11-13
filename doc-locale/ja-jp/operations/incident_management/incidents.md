---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: インシデント
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インシデントとは、緊急に復元する必要があるサービスの中断または停止です。インシデントは、インシデント管理ワークフローにおいて非常に重要です。GitLabを使用して、トリアージ、対応、インシデントを呼び出してください。

## インシデントリスト {#incidents-list}

[インシデントリストを表示する](manage_incidents.md#view-a-list-of-incidents)と、次のものが含まれています:

- **ステータス**: インシデントを状態でフィルターするには、インシデントリストの上にある**オープン**、**クローズ**、または**すべて**を選択します。
- **検索**: インシデントのタイトルと説明を検索するか、[リストをフィルターします](#filter-the-incidents-list)。
- **重大度**: 特定のインシデントの重大度。次のいずれかの値になります:

  - {{< icon name="severity-critical" >}}緊急 - S1
  - {{< icon name="severity-high" >}}高 - S2
  - {{< icon name="severity-medium" >}}中 - S3
  - {{< icon name="severity-low" >}}低 - S4
  - {{< icon name="severity-unknown" >}}不明

- **インシデント**: インシデントのタイトル。最も意味のある情報をキャプチャしようとします。
- **ステータス**: インシデントのステータス。次のいずれかの値になります:

  - トリガーされました
  - 承認済み
  - 解決済み

  PremiumまたはUltimateプランでは、このフィールドはインシデントの[オンコールエスカレーションポリシー](paging.md#escalating-an-incident)にもリンクされています。

- **作成日**: インシデントが作成されてからの経過時間。このフィールドは、標準のGitLabパターン`X time ago`を使用します。この値にカーソルを合わせると、ロケールに従ってフォーマットされた正確な日付と時刻が表示されます。
- **担当者**: インシデントに割り当てられたユーザー。
- **公開済み**: インシデントが[ステータスページ](status_page.md)に公開されているかどうか。

![インシデントリスト](img/incident_list_v15_6.png)

インシデントリストの動作例については、この[デモプロジェクト](https://gitlab.com/gitlab-org/monitor/monitor-sandbox/-/incidents)を参照してください。

### インシデントリストをソート {#sort-the-incident-list}

インシデントリストには、インシデントの作成日でソートされたインシデントが、最新のものが最初に表示されます。

別の列でソートしたり、ソート順を変更したりするには、列を選択します。

ソートできる列:

- 重大度
- ステータス
- SLAまでの時間
- 公開済み

### インシデントリストをフィルター {#filter-the-incidents-list}

インシデントリストを作成者またはアサイン先でフィルターするには、検索ボックスにこれらの値を入力します。

## インシデントの詳細 {#incident-details}

### 概要 {#summary}

インシデントの概要セクションには、インシデントに関する重要な詳細と、イシューテンプレートの内容が表示されます（[選択](alerts.md#trigger-actions-from-alerts)されている場合）。インシデントの最上部にある強調表示されたバーには、左から右に次の内容が表示されます:

- 元のアラートへのリンク。
- アラートの開始時刻。
- イベント数。

ハイライトバーの下の概要には、次のフィールドが含まれています:

- 開始時間
- 重大度
- `full_query`
- モニタリングツール

インシデントの概要は、[GitLab Flavored Markdown](../../user/markdown.md)を使用してさらにカスタマイズできます。

インシデントが[アラートから作成された](alerts.md#trigger-actions-from-alerts)場合、そのインシデントのMarkdownが提供されていれば、そのMarkdownが概要に追加されます。インシデントテンプレートがプロジェクトに設定されている場合、テンプレートコンテンツは最後に付加されます。

コメントはスレッドに表示されますが、[最近の更新ビューを切り替えることによって](#recent-updates-view)、時系列順に表示できます。

インシデントを変更すると、GitLabは[システムノート](../../user/project/system_notes.md)を作成し、概要の下に表示します。

### メトリクス {#metrics}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

多くの場合、インシデントはメトリクスに関連付けられています。**メトリクス**タブでメトリクスチャートのスクリーンショットをアップロードできます:

![インシデントメトリクスタブ](img/incident_metrics_tab_v13_8.png)

画像をアップロードするときに、画像をテキストまたは元のグラフへのリンクに関連付けることができます。

![テキストリンクモーダル](img/incident_metrics_tab_text_link_modal_v14_9.png)

リンクを追加すると、アップロードされた画像の上にあるハイパーリンクを選択して、元のグラフにアクセスできます。

### アラートの詳細 {#alert-details}

インシデントには、リンクされたアラートの詳細が別のタブに表示されます。このタブに入力するには、リンクされたアラートでインシデントを作成する必要があります。アラートから自動的に作成されたインシデントには、このフィールドが入力されています。

![インシデントアラートの詳細](img/incident_alert_details_v13_4.png)

### タイムラインイベント {#timeline-events}

インシデントのタイムラインは、インシデント中に何が起こったのか、およびそれを解決するためにどのような措置が取られたのかの概要を示します。

[タイムラインイベントについて](incident_timeline_events.md)、およびこの機能を有効にする方法について詳しくお読みください。

### 最近の更新の表示 {#recent-updates-view}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インシデントに関する最新の更新情報を表示するには、コメントバーの**最近の更新の表示をオンにする**({{< icon name="history" >}})を選択します。コメントはスレッド化されず、時系列順に最新のものから順に表示されます。

### サービスレベルアグリーメントカウントダウンタイマー {#service-level-agreement-countdown-timer}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インシデントでサービスレベルアグリーメントカウントダウンタイマーを有効にして、顧客とのサービスレベルアグリーメント (SLA)を追跡できます。タイマーはインシデントの作成時に自動的に開始され、SLA期間が終了するまでの残り時間が表示されます。また、タイマーは15分ごとに動的に更新されるため、ページを更新して残り時間を確認する必要はありません。

前提要件:

- プロジェクトのメンテナー以上のロールを持っている必要があります。

タイマーを構成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**設定** > **モニタリング**を選択します。
1. **インシデント**セクションを展開し、**インシデント設定**タブを選択します。
1. **「SLAまでの時間」のカウントダウンタイマーを有効にする**を選択します。
1. 制限時間を15分単位で設定します。
1. **変更を保存**を選択します。

SLAカウントダウンタイマーを有効にすると、**SLAまでの時間**列がインシデントリストで利用可能になり、新しいインシデントのフィールドとして使用できるようになります。SLA期間が終了する前にインシデントがクローズされない場合、GitLabは`missed::SLA`ラベルをインシデントに追加します。

## 関連トピック {#related-topics}

- [インシデントを作成する](manage_incidents.md#create-an-incident)
- アラートがトリガーされるたびに、[インシデントを自動的に作成](alerts.md#trigger-actions-from-alerts)する
- [インシデントリストを表示](manage_incidents.md#view-a-list-of-incidents)する
- [ユーザーに割り当てる](manage_incidents.md#assign-to-a-user)
- [インシデントの重大度](manage_incidents.md#change-severity)を変更する
- [インシデントステータスを変更](manage_incidents.md#change-status)する
- [エスカレーションポリシーを変更](manage_incidents.md#change-escalation-policy)する
- [インシデントをクローズする](manage_incidents.md#close-an-incident)
- [リカバリーアラートを介してインシデントを自動的にクローズする](manage_incidents.md#automatically-close-incidents-via-recovery-alerts)
- [To-Do](../../user/todos.md#create-a-to-do-item)アイテムを追加
- [ラベル](../../user/project/labels.md)を追加
- [マイルストーンを割り当てる](../../user/project/milestones/_index.md)
- [インシデントを機密にする](../../user/project/issues/confidential_issues.md)
- [期限を設定する](../../user/project/issues/due_dates.md)
- [通知を切り替える](../../user/profile/notifications.md#edit-notification-settings-for-issues-merge-requests-and-epics)
- [費やした時間を追跡する](../../user/project/time_tracking.md)
- [インシデントにZoomミーティングを追加](../../user/project/issues/associate_zoom_meeting.md)する(イシューに追加するのと同じ方法)
- [インシデント内のリンクされたリソース](linked_resources.md)
- インシデントを作成し、インシデントの通知[をSlackから直接](slack.md)受信します
- [イシューAPI](../../api/issues.md)を使用してインシデントを操作する
