---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: インシデント
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インシデントとは、緊急に復旧する必要があるサービスの中断または停止のことです。インシデントは、インシデント管理ワークフローにおいて重要です。GitLabを使用して、インシデントのトリアージ、対応、および修正を行います。

## インシデントリスト {#incidents-list}

インシデントリストを[表示する](manage_incidents.md#view-a-list-of-incidents)と、以下の内容が表示されます:

- **ステータス**: インシデントをそのステータスでフィルタリングするには、インシデントリストの上にある**オープン**、**クローズ**、または**すべて**を選択します。
- **検索**: インシデントのタイトルと説明を検索するか、リストを[フィルタリング](#filter-the-incidents-list)します。
- **重大度**: 特定のインシデントの重大度。以下のいずれかの値になります:

  - {{< icon name="severity-critical" >}} Critical - S1
  - {{< icon name="severity-high" >}} High - S2
  - {{< icon name="severity-medium" >}} Medium - S3
  - {{< icon name="severity-low" >}} Low - S4
  - {{< icon name="severity-unknown" >}}不明

- **インシデント**: インシデントのタイトルで、最も意味のある情報を捉えようとします。
- **状態**: インシデントのステータス。以下のいずれかの値になります:

  - トリガー済み
  - 承認済み
  - 解決済み

  PremiumまたはUltimateプランでは、このフィールドはインシデントの[オンコールエスカレーション](paging.md#escalating-an-incident)にもリンクされます。

- **作成日**: インシデントが作成されてからの経過時間。このフィールドは、標準のGitLabパターン`X time ago`を使用します。この値にカーソルを合わせると、ロケールに応じた正確な日時が表示されます。
- **担当者**: インシデントに割り当てられたユーザー。
- **公開済み**: インシデントが[ステータスページ](status_page.md)に公開されているかどうか。

![インシデントリスト](img/incident_list_v15_6.png)

インシデントリストの実際の動作例については、この[デモプロジェクト](https://gitlab.com/gitlab-org/monitor/monitor-sandbox/-/incidents)を参照してください。

### インシデントリストをソートする {#sort-the-incident-list}

インシデントリストは、インシデントの作成日でソートされ、最新のものが最初に表示されます。

別の列でソートするか、ソート順を変更するには、列を選択します。

ソートできる列:

- 重大度
- ステータス
- SLAまでの時間
- 公開済み

### インシデントリストをフィルタリングする {#filter-the-incidents-list}

インシデントリストを作成者または担当者でフィルタリングするには、検索ボックスにこれらの値を入力します。

## インシデントの詳細 {#incident-details}

### まとめ {#summary}

インシデントの概要セクションには、インシデントに関する重要な詳細情報と、イシューテンプレートのコンテンツ（[選択](alerts.md#trigger-actions-from-alerts)した場合）が表示されます。インシデント上部のハイライトされたバーは、左から右に以下を表示します:

- 元のアラートへのリンク。
- アラートの開始時刻。
- イベント数。

ハイライトバーの下には、以下のフィールドを含む概要が表示されます:

- 開始時刻
- 重大度
- `full_query`
- モニタリングツール

インシデントの概要は、[GitLab Flavored Markdown](../../user/markdown.md)を使用してさらにカスタマイズできます。

[アラートから作成された](alerts.md#trigger-actions-from-alerts)インシデントでインシデント用のMarkdownが提供されていた場合、そのMarkdownは概要に追加されます。プロジェクトにインシデントテンプレートが設定されている場合、テンプレートのコンテンツは最後に追加されます。

コメントはスレッドで表示されますが、[最近の更新ビューをオンに切り替える](#recent-updates-view)ことで時系列順に表示することもできます。

インシデントに変更を加えると、GitLabは[システムノート](../../user/project/system_notes.md)を作成し、概要の下に表示します。

### メトリクス {#metrics}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

多くの場合、インシデントはメトリクスに関連付けられています。メトリクスのチャートのスクリーンショットを**メトリクス**タブにアップロードできます:

![インシデントメトリクスタブ](img/incident_metrics_tab_v13_8.png)

画像をアップロードするときに、画像をテキストまたは元のグラフへのリンクに関連付けることができます。

![テキストリンクモーダル](img/incident_metrics_tab_text_link_modal_v14_9.png)

リンクを追加すると、アップロードされた画像の上にあるハイパーリンクを選択して、元のグラフにアクセスできます。

### アラートの詳細 {#alert-details}

インシデントは、リンクされたアラートの詳細を別のタブに表示します。このタブを入力するには、インシデントがリンクされたアラートとともに作成されている必要があります。アラートから自動的に作成されたインシデントには、このフィールドが入力されます。

![インシデントアラートの詳細](img/incident_alert_details_v13_4.png)

### タイムラインイベント {#timeline-events}

インシデントのタイムラインは、インシデント中に何が起こったか、およびそれを解決するために取られた手順の概要を提供します。

[タイムラインイベント](incident_timeline_events.md)と、この機能を有効にする方法の詳細については、こちらをご覧ください。

### 最近の更新ビュー {#recent-updates-view}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インシデントの最新の更新を表示するには、コメントバーで**最近の更新の表示をオンにする** ({{< icon name="history" >}}) を選択します。コメントはスレッド化されずに、最新から最も古いものへと時系列順に表示されます。

### Service Level Agreement SLAカウントダウンタイマー {#service-level-agreement-countdown-timer}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

インシデントでService Level Agreement (サービスレベルアグリーメント) SLAカウントダウンタイマーを有効にして、顧客とのService Level Agreement (サービスレベルアグリーメント) SLAを追跡することができます。インシデントが作成されるとタイマーが自動的に開始され、SLA期間が終了するまでの残り時間が表示されます。タイマーは15分ごとに動的に更新されるため、ページを更新することなく残り時間を確認できます。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

タイマーを設定するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **モニタリング**を選択します。
1. **インシデント**セクションを展開し、**インシデント設定**タブを選択します。
1. **「SLAまでの時間」のカウントダウンタイマーを有効にする**を選択します。
1. 15分刻みで時間制限を設定します。
1. **変更を保存**を選択します。

SLAカウントダウンタイマーを有効にすると、**SLAまでの時間**列がインシデントリストで利用可能になり、新しいインシデントのフィールドとして使用できるようになります。インシデントがSLA期間終了前にクローズされない場合、GitLabはインシデントに`missed::SLA`ラベルを追加します。

## 関連トピック {#related-topics}

- [インシデントを作成する](manage_incidents.md#create-an-incident)
- アラートがトリガーするたびに[自動的にインシデントを作成する](alerts.md#trigger-actions-from-alerts)
- [インシデントリストを表示する](manage_incidents.md#view-a-list-of-incidents)
- ユーザーに[割り当てる](manage_incidents.md#assign-to-a-user)
- [インシデントの重大度を変更する](manage_incidents.md#change-severity)
- [インシデントのステータスを変更する](manage_incidents.md#change-status)
- [エスカレーションポリシーを変更する](manage_incidents.md#change-escalation-policy)
- [インシデントをクローズする](manage_incidents.md#close-an-incident)
- [リカバリーアラートを介してインシデントを自動的にクローズする](manage_incidents.md#automatically-close-incidents-via-recovery-alerts)
- [To-Doアイテムを追加する](../../user/todos.md#create-a-to-do-item)
- [ラベルを追加する](../../user/project/labels.md)
- [マイルストーンを割り当てる](../../user/project/milestones/_index.md)
- [インシデントを機密にする](../../user/project/issues/confidential_issues.md)
- [期限を設定する](../../user/project/issues/due_dates.md)
- [通知を切り替える](../../user/profile/notifications.md#subscribe-to-notifications-for-a-specific-issue-merge-request-or-epic)
- [時間消費を追跡する](../../user/project/time_tracking.md)
- イシューを追加するのと同じ方法で、[インシデントにZoomミーティングを追加する](../../user/project/issues/associate_zoom_meeting.md)
- [インシデント内のリンクされたリソース](linked_resources.md)
- インシデントを作成し、[Slackから直接](slack.md)インシデント通知を受け取る
- インシデントとやり取りするために[イシューAPI](../../api/issues.md)を使用する
