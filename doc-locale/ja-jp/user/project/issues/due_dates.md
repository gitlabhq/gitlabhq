---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 期限
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- 期日を設定するための最小ロールは、GitLab 17.7でレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

作業アイテムで期限を使用して締め切りを追跡し、フィーチャーが時間どおりに出荷されるようにします。

期限は以下でサポートされています:

- [イシュー](_index.md)
- [エピック](../../group/epics/_index.md)
- [タスク](../../tasks.md)
- [目標と主な成果](../../okrs.md)
- [インシデント](../../../operations/incident_management/incidents.md)

オープンアイテムの期限の前日には、メールがすべての参加者に送信されます。
<!-- For issue due timing source, see 'issue_due_scheduler_worker' in https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/1_settings.rb -->
翌日が期日のオープンな項目に対する通知は、サーバーのタイムゾーン（GitLab.comの場合はUTC）で午前0時50分に送信されます。

期限は、[To-Do](../../todos.md)にも表示されます。

## 期限のあるイシューを表示する {#view-issues-with-due-dates}

期限のあるイシューは、**イシュー**ページで確認できます。イシューに期限が含まれている場合、イシューのタイトルの下に表示されます:

![2024年の期限のあるイシュー。](img/overdue_issue_v17_9.png)

過去のイシューの期限は、赤いアイコン（{{< icon name="calendar-overdue" >}}）で表示されます。

プロジェクトで期限を含むイシューを表示およびソートするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **イシュー**を選択します。
1. 期限でソートするには、現在のソート方法を選択し、**期限**を選択します。
1. オプション。ソート順を逆にするには、**ソート順**（{{< icon name="sort-lowest" >}}）を選択します。

## イシューの期限を設定する {#set-a-due-date-for-an-issue}

イシューを表示する権限を持つすべてのユーザーは、その期限を表示できます。

### イシューの作成時 {#when-creating-an-issue}

プランナーロール以上のロールを持っている場合は、イシューを作成するときに、**期限**を選択してカレンダーを表示します。この日付は、現在のユーザーのタイムゾーンではなく、サーバーのタイムゾーンを使用します。

日付を削除するには、日付テキストを選択し、テキストを削除します。

### 既存のイシューで {#in-an-existing-issue}

前提要件: 

- プランナー以上のロールが必要です。

これを行うには、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **イシュー**を選択し、表示したいイシューのタイトルを選択します。
1. 右側のサイドバーで、**期限**の横にある**編集**を選択して、カレンダーを表示します。
1. 目的の日付を選択し、カレンダーの外側をもう一度選択して、変更を保存します。

### クイックアクションを使用する {#with-a-quick-action}

イシューの説明またはコメントで[クイックアクション](../quick_actions.md)から期限を設定するには:

- `/due <date>`: 期日を設定します。有効な`<date>`の例としては、`in 2 days`、`this Friday`、および`December 31st`があります。
- `/remove_due_date`: 既存の期限を削除します。

## イシューの期限をカレンダーにエクスポートする {#export-issue-due-dates-to-a-calendar}

期限のあるイシューは、iCalendarフィードとしてエクスポートすることもできます。フィードのURLは、カレンダーアプリケーションに追加できます。

- **Project Issues**（プロジェクトイシュー）ページ
- **Group Issues**（グループイシュー）ページ

1. 登録するイシューのリストが含まれているページに移動します。例: 

   - [自分に割り当てられたイシュー](managing_issues.md#view-all-issues-assigned-to-you)
   - [特定のプロジェクトのイシュー](managing_issues.md#issue-list)
   - [グループ](../../group/_index.md)内のすべてのプロジェクトのイシュー

1. 右側の**アクション**（{{< icon name="ellipsis_v" >}}）ドロップダウンリストから、**カレンダーに登録**を選択して`.ics`ファイルを表示します。
1. ページへの完全なリンク（完全なクエリ文字列を含む）をコピーし、優先カレンダーアプリケーションで使用します。
