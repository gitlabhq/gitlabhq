---
stage: Growth
group: Engagement
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: To-Doリスト
description: タスク管理、アクション、およびアクセス変更。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

あなたの*To-Doリスト*は、あなたの入力を待っている項目の時系列リストです。これらの項目は、*to-do items*と呼ばれます。

GitLabで行う作業に関連するアクションを追跡するために、To-Doリストを使用できます。他のユーザーがあなたに連絡したり、あなたの注意が必要な場合、To-DoアイテムがTo-Doリストに表示されます。

## To-Doリストへのアクセス {#access-the-to-do-list}

To-Doリストにアクセスするには:

左側のサイドバーの上部にある**To-Doリスト** ({{< icon name="task-done" >}}) を選択します。
<!-- When the feature flag paneled_view is removed, refer only to the button icon -->

### To-Doリストのフィルター {#filter-the-to-do-list}

To-Doリストをフィルタリングするには:

1. リストの上にあるテキストボックスにカーソルを置きます。
1. 定義済みのフィルターのいずれかを選択します。
1. <kbd>Enter</kbd>キーを押します。

### To-Doリストのソート {#sort-the-to-do-list}

To-Doリストをソートするには:

1. **To Do**タブの右上隅で、オプションから選択します:

   - **おすすめ**は、作成日と以前にスヌーズされた日付の組み合わせでソートされ、以前にスヌーズされたアイテムが一番上に表示されます。
   - **更新**は、アイテムが最後に更新された日付でソートされます。
   - **ラベルの優先度**は、[設定した優先順位](project/labels.md#set-label-priority)でソートします。

1. オプション。ソート順を選択します。

{{< alert type="note" >}}

**スヌーズ**タブと**完了**タブでは、**おすすめ**はアイテムを作成日のみでソートします。

{{< /alert >}}

## To-Doアイテムを作成するアクション {#actions-that-create-to-do-items}

{{< history >}}

- 複数のTo-DoアイテムがGitLab 13.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/28355)されました。`multiple_todos`という名前の[フラグ付き](../administration/feature_flags/_index.md)。デフォルトでは無効になっています。
- メンバーアクセスリクエスト通知はGitLab 15.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/374725)されました。
- 複数のTo-DoアイテムがGitLab 16.2で[GitLab.comで有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/28355)されました。
- 複数のTo-DoアイテムがGitLab 17.8で[GitLabセルフマネージドで有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/28355)されました。機能フラグ`multiple_todos`はデフォルトで有効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

多くのTo-Doアイテムが自動的に作成されます。あなたのTo-DoリストにTo-Doアイテムを追加するアクションの一部:

- イシューまたはマージリクエストがあなたに割り当てられます。
- マージリクエストのマージリクエストのレビューがリクエストされます。
- イシュー、マージリクエスト、またはエピックの説明またはコメントでメンションされます。
- コミットまたはデザインに関するコメントでメンションされます。
- あなたのマージリクエストのCI/CDパイプラインが失敗します。
- オープンマージリクエストは競合のためにマージできず、次のいずれかが該当します:
  - あなたが作成者です。
  - あなたがパイプラインが成功した後で、自動的にマージするようにマージリクエストを設定したユーザーです。
- マージリクエストが[マージトレイン](../ci/pipelines/merge_trains.md)から削除され、あなたがそれを追加したユーザーです。
- あなたがオーナーであるグループまたはプロジェクトに対して、メンバーアクセスリクエストが提起されます。

GitLab 17.8以降では、同じイシューまたはマージリクエストであっても、誰かがあなたにメンションするたびに、新しい通知を受け取ります。

割り当てやレビューリクエストなど、To-Doアイテムを作成する他のアクションでは、同じイシューまたはマージリクエストでそのアクションが複数回発生した場合でも、アクションの種類ごとに1つの通知のみを受信します。

To-Doアイテムは、[GitLab通知メール設定](profile/notifications.md)の影響を受けません。唯一の例外: 通知が**カスタム**に設定され、**あなたの承認が適格なマージリクエストが作成されました**が選択されている場合、マージリクエストを承認する資格がある場合にTo-Doアイテムを取得します。

## To Doアイテムを作成する {#create-a-to-do-item}

{{< history >}}

- GitLab 16.0の目標、主な成果、タスクで[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/390549)。

{{< /history >}}

To-Doリストに項目を手動で追加できます。

1. 以下にアクセスします:

   - イシュー
   - マージリクエスト
   - エピック
   - デザイン
   - インシデント
   - 目標または主な成果
   - タスク

1. 右上隅で、**To-Doアイテムを追加** ({{< icon name="todo-add" >}}) を選択します。

### 他のユーザーにメンションしてTo-Doアイテムを作成する {#create-a-to-do-item-by-mentioning-someone}

コードブロックを除く任意の場所で他のユーザーにメンションすることにより、To-Doアイテムを作成できます。1つのメッセージでユーザーを何度もメンションすると、1つのTo-Doアイテムのみが作成されます。

たとえば、次のコメントでは、`frank`を除くすべてのユーザーに対してTo-Doアイテムが作成されます:

````markdown
@alice What do you think? cc: @bob

- @carol can you please have a look?

> @dan what do you think?

Hey @erin, this is what they said:

```
Hi, please message @frank :incoming_envelope:
```
````

## To-Doアイテムを完了としてマークするアクション {#actions-that-mark-a-to-do-item-as-done}

To-Doアイテムオブジェクト(例えば、イシュー、マージリクエスト、またはエピック)に対するさまざまなアクションは、対応するTo-Doアイテムを完了としてマークします。

To-Doアイテムは、次の場合に完了としてマークされます:

- 説明またはコメントに絵文字リアクションを追加します。
- ラベルを追加または削除します。
- 担当者を変更します。
- マイルストーンを変更します。
- To-Doアイテムのオブジェクトを閉じます。
- コメントを作成します。
- 説明を編集します。
- デザインディスカッションスレッドを解決します。
- プロジェクトまたはグループメンバーシップリクエストを承認または拒否します。

To-Doアイテムは、次の場合には完了としてマークされ**not**（ません）:

- リンクされたアイテム(リンクされたイシューなど)を追加します。
- 子エピックまたはタスクなどの子アイテムを追加します。
- タイムトラッキングを追加。
- 自分自身を割り当てます。
- イシューのヘルスステータスを変更します。

他の誰かがイシュー、マージリクエスト、またはエピックを閉じたり、アクションを実行した場合、あなたのTo-Doアイテムは保留中のままになります。

## To-Doアイテムを完了としてマーク {#mark-a-to-do-item-as-done}

To-Doアイテムを手動で完了としてマークできます。

これを行うには、2つの方法があります:

- Todoリストで、To-Doアイテムの右側にある**Todoを完了** ({{< icon name="check" >}}) を選択します。
- リソース(例えば、イシューまたはマージリクエスト)の右上隅で、**Todoを完了** ({{< icon name="todo-done" >}}) を選択します。

## 完了したTo-Doアイテムを再度追加する {#re-add-a-done-to-do-item}

誤ってTo-Doアイテムを完了としてマークした場合、**完了**タブから再度追加できます:

1. 左側のサイドバーの上部にある**To-Doリスト** ({{< icon name="task-done" >}}) を選択します。
<!-- When the feature flag paneled_view is removed, refer only to the button icon -->
1. 上部にある**完了**を選択します。
1. 再度追加するTo-Doアイテムを見つけます。
1. このTo-Doアイテムの横にある**元に戻す** {{< icon name="redo" >}}を選択します。

To-Doアイテムが**To Do**リストのTo Doタブに表示されるようになりました。

## To-Doアイテムをスヌーズする {#snooze-to-do-items}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/17712)されました。

{{< /history >}}

To-Doアイテムをスヌーズして、メインのTo-Doリストから一時的に非表示にすることができます。これにより、より緊急性の高いタスクに集中し、後でスヌーズされた項目に戻ることができます。

To-Doアイテムをスヌーズするには:

1. To-Doリストで、スヌーズするTo-Doアイテムの横にあるスヌーズ({{< icon name="clock" >}})を選択します。
1. To-Doアイテムを特定の日時にスヌーズする場合は、`Until a specific time and date`オプションを選択します。それ以外の場合は、プリセットされたスヌーズ期間のいずれかを選択します:
   - 1時間
   - 今日の後半まで（4時間後）
   - 明日まで（明日の午前8時（現地時間））

**スヌーズ**されたTo-Doアイテムは、メインのTo-Doリストから削除され、別のスヌーズタブに表示されます。

スヌーズ期間が終了すると、To-Doアイテムは自動的にメインのTo-Doリストに戻ります。いつ作成されたかを示すインジケーターが表示されます。

## スヌーズされたTo-Doアイテム {#view-snoozed-to-do-items}

{{< history >}}

- GitLab 17.9で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/17712)されました。

{{< /history >}}

スヌーズされたTo-Doアイテムを表示または管理するには:

1. To-Doリストに移動します。
1. リストの上部にあるスヌーズタブを選択します。

スヌーズタブから、以下を実行できます:

- スヌーズされたTo-Doがメインリストに戻るようにスケジュールされている日時を表示します。
- スヌーズを削除して、アイテムをすぐにメインのTo-Doリストに戻します。
- スヌーズされたTo-Doを完了としてマークします。

## To-Doアイテムの一括編集 {#bulk-edit-to-do-items}

{{< history >}}

- GitLab 17.10で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/16564)されました。

{{< /history >}}

To-Doアイテムを一括編集できます:

- **To Do**タブ: To-Doアイテムを完了としてマークするか、スヌーズします。
- **スヌーズ**タブ: To-Doアイテムを完了としてマークするか、削除します。
- **完了**タブ: To-Doアイテムを復元する。

To-Doアイテムを一括編集するには:

1. To-Doリスト内:
   - 個々のアイテムを選択するには、編集する各アイテムの左側にあるチェックボックスをオンにします。
   - ページ上のすべてのアイテムを選択するには、左上隅にある**すべて選択**チェックボックスをオンにします。
1. 右上隅で、目的のアクションを選択します。

## ユーザーのアクセス権が変更された場合にTo-Doリストがどのように影響を受けるか {#how-a-users-to-do-list-is-affected-when-their-access-changes}

セキュリティ上の理由から、ユーザーが関連リソースにアクセスできなくなった場合、GitLabはTo-Doアイテムを削除します。たとえば、ユーザーがイシュー、マージリクエスト、エピック、プロジェクト、またはグループにアクセスできなくなった場合、GitLabは関連するTo-Doアイテムを削除します。

このプロセスは、アクセス権の変更後1時間以内に発生します。ユーザーのアクセス権が誤って失効された場合に、データ損失を防ぐために、削除は遅延されます。

## 関連トピック {#related-topics}

- [イシュー](project/issues/_index.md)
- [マージリクエスト](project/merge_requests/_index.md)
- [エピック](group/epics/_index.md)
- [デザイン](project/issues/design_management.md)
- [インシデント](../operations/incident_management/incidents.md)
- [目標または主な成果](okrs.md)
- [タスク](tasks.md)
