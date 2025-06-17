---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: タイムトラッキング
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.0で、タスクのタイムトラッキングが[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/438577)。
- GitLab 17.5で、エピックのタイムトラッキングが[導入されました](https://gitlab.com/groups/gitlab-org/-/epics/12396)。[エピックの新しい外観](../group/epics/epic_work_items.md)を有効にする必要があります。
- GitLab 17.7で、見積もりを追加、編集、削除するための最小ロールがレポーターからプランナーに[変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)。

{{< /history >}}

タイムトラッキングは、GitLabの作業アイテムに費やした時間を記録および管理するのに役立ちます。タイムトラッキングでは、次のことが可能です。

- イシュー、マージリクエスト、[新しい外観](../group/epics/epic_work_items.md)のエピック、およびタスクに費やされた実際の時間を記録します。
- 完了に必要な合計時間を見積もります。
- 時間エントリの詳細なレポートを提供します。
- 標準化された時間単位を使用して合計を計算します。
- クイック アクションとUIを通じて履歴を追跡します。

作業項目の右側のサイドバーにタイムトラッキング情報を表示できます。

![サイドバーのタイムトラッキング](img/time_tracking_sidebar_v13_12.png)

ロールに応じて、さまざまなタイムトラッキング機能を利用できます。

- 見積もりを追加、編集、削除するには、イシューとタスクの場合はプランナーロール、マージリクエストの場合はデベロッパーロールが少なくとも必要です。
- 費やした時間を追加および編集するには、プロジェクトのプランナーロールが少なくとも必要です。
- 時間エントリを削除するには、作成者であるか、少なくともメンテナーのロールを保持している必要があります。

[クイック アクション](quick_actions.md)またはユーザーインターフェースを使用して、タイムトラッキングデータを入力および削除します。独自の行にクイック アクションを入力します。1つのコメントで同じクイック アクションを複数回使用した場合、最後に実行されたアクションのみが適用されます。

## 見積もり

見積もりは、アイテムを完了するために必要な合計時間を示すように設計されています。

右側のサイドバーにあるタイムトラッキング情報にカーソルを置くと、残り予測時間を確認できます。

![残り見積もり時間](img/remaining_time_v14_2.png)

### 見積もりを追加する

前提要件:

- イシューでは、少なくともプロジェクトのプランナーロールが必要です。
- タスクでは、少なくともプロジェクトのプランナーロールが必要です。
- マージリクエストでは、少なくともプロジェクトのデベロッパーロールが必要です。

見積もりを入力するには、`/estimate` [クイック アクション](quick_actions.md)の後に時間を入力します。

たとえば、1か月、2週間、3日、4時間、5分の見積もりを入力する必要がある場合は、`/estimate 1mo 2w 3d 4h 5m`と入力します。[使用できる時間単位](#available-time-units)を確認してください。

1つのアイテムに設定できる見積もりは1つのみです。新しい時間見積もりを入力するたびに、以前の値が上書きされます。

### 見積もりを削除する

前提要件:

- イシューでは、少なくともプロジェクトのプランナーロールが必要です。
- タスクでは、少なくともプロジェクトのプランナーロールが必要です。
- マージリクエストでは、少なくともプロジェクトのデベロッパーロールが必要です。

見積もりを完全に削除するには、`/remove_estimate` [クイック アクション](quick_actions.md)を使用します。

## 費やした時間

作業中に費やした時間を記録できます。

新しい時間の入力ごとに、イシュー、タスク、またはマージリクエストの現在の合計時間に追加されます。

イシュー、タスク、またはマージリクエストに費やした合計時間は、1年を超えることはできません。

### 費やした時間を追加する

前提要件:

- プロジェクトのプランナーロール以上が必要です。

#### ユーザーインターフェースを使用する

{{< history >}}

- GitLab 15.7で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101563)。
- GitLab 17.0で[変更されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150564)。どのタイミングで時間が費やされたかを指定しない場合、現在の時間が使用されます。

{{< /history >}}

ユーザーインターフェースを使用して時間エントリを追加するには、次の手順に従います。

1. サイドバーの**タイムトラッキング**セクションで、**時間エントリの追加**（{{< icon name="plus" >}}）を選択します。ダイアログが開きます。
1. 次を入力します。

   - 費やした時間。
   - （オプション）どのタイミングで時間が費やされたか。空の場合、現在の時間を使用します。
   - （オプション）概要。

1. **保存**を選択します。

サイドバーの**費やした時間**の合計が更新され、[タイムトラッキングレポート](#view-an-items-time-tracking-report)ですべてのエントリを表示できます。

#### クイック アクションを使用する

費やした時間を入力するには、`/spend` [クイック アクション](quick_actions.md)の後に時間を入力します。

たとえば、1か月、2週間、3日、4時間、5分を記録する必要がある場合は、`/spend 1mo 2w 3d 4h 5m`と入力します。[使用できる時間単位](#available-time-units)を確認してください。

ノートを含む[タイムトラッキングレポート](#view-an-items-time-tracking-report)エントリを追加するには、説明とクイック アクションを含むコメントを作成します。タイムトラッキングレポートの**サマリー/ノート**列に表示されます。次に例を示します。

```plaintext
Draft MR and respond to initial comments

/spend 30m
```

時間が費やされた日時を記録するには、`YYYY-MM-DD`形式を使用して、時間の後に日付を入力します。

たとえば、2021年1月31日に費やした1時間を記録するには、`/spend 1h 2021-01-31`と入力します。

将来の日付を入力しても、時間は記録されません。

### 費やした時間を差し引く

前提要件:

- プロジェクトのプランナーロール以上が必要です。

時間を差し引くには、負の値を入力します。たとえば、`/spend -3d`は、費やした合計時間から3日を削除します。費やした時間が0分を下回ることはないため、既に入力した時間よりも多くの時間を削除しようとすると、GitLabはその減算を無視します。

### 費やした時間を削除する

{{< history >}}

- GitLab 15.1で削除ボタンが[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/356796)されました。

{{< /history >}}

タイムログは、費やした時間の単一のエントリであり、正または負です。

前提要件:

- タイムログの作成者であるか、少なくともプロジェクトのメンテナーロールを持っている必要があります。

タイムログを削除するには、次のいずれかを実行します。

- タイムトラッキングレポートで、タイムログエントリの右側にある**費やした時間を削除**（{{< icon name="remove" >}}）を選択します。
- [GraphQL API](../../api/graphql/reference/_index.md#mutationtimelogdelete)を使用します。

### 費やしたすべての時間を削除する

前提要件:

- プロジェクトのプランナーロール以上が必要です。

費やしたすべての時間を一度に削除するには、`/remove_time_spent` [クイック アクション](quick_actions.md)を使用します。

## アイテムのタイムトラッキングレポートを表示する

アイテムに費やした時間のタイムトラッキングレポートを表示するには、次の手順に従います。

- イシューまたはマージリクエストの場合は、次の通りです。

  1. イシューまたはマージリクエストに移動します。
  1. 右側のサイドバーで、**タイムトラッキングレポート**を選択します。

- エピックまたはタスクの場合は、次の通りです。

  1. エピックまたはタスクに移動します。
  1. 右側のサイドバーで、**費やした時間**の横にある時間を選択します。

![タイムトラッキングレポート](img/time_tracking_report_v15_1.png)

表示される費やされた時間の内訳は、最大100エントリに制限されています。

## グローバルタイムトラッキングレポート

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 15.11で、`global_time_tracking_report`という名前の[フラグとともに](../../administration/feature_flags.md)[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/344002)されました。デフォルトでは無効になっています。
- GitLab 16.5のGitLab.comで有効になりました。

{{< /history >}}

{{< alert type="flag" >}}

GitLab Self-Managedでは、デフォルトでこの機能は使用できません。管理者が`global_time_tracking_report`という名前の[機能フラグを有効にする](../../administration/feature_flags.md)と、この機能を使用できるようになります。GitLab.comでは、この機能を利用できます。GitLab Dedicatedでは、この機能は利用できません。この機能は本番環境での使用には対応していません。

{{< /alert >}}

GitLab全体のイシュー、タスク、およびマージリクエストで費やされた時間のレポートを表示します。

これは[実験的機能](../../policy/development_stages_support.md)です。バグを見つけた場合は、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/435222)でお知らせください。

グローバルタイムトラッキングレポートを表示するには、次の手順に従います。

1. ブラウザにグローバルレポートのURLを入力します。
   - GitLab Self-Managedの場合は、ベースURLに`/-/timelogs`を追加します。たとえば、`https://gitlab.example.com/-/timelogs`です。
   - GitLab.comの場合は、<https://gitlab.com/-/timelogs>に移動します。
1. （オプション）特定のユーザーでフィルター処理するには、`@`記号なしでユーザー名を入力します。
1. 開始日と終了日を選択します。
1. **レポートの実行**を選択します。

![グローバルタイムトラッキングレポート](img/global_time_report_v16_5.png)

## 利用可能な時間単位

次の時間単位を使用できます。

| 時間単位 | 入力内容                | 換算レート |
| --------- | --------------------------- | --------------- |
| 月     | `mo`、`month`、または`months`  | 4 w（160 h）     |
| 週      | `w`、`week`、または`weeks`     | 5 d（40 h）      |
| 日       | `d`、`day`、または`days`       | 8 h             |
| 時間      | `h`、`hour`、または`hours`     | 60 m            |
| 分    | `m`、`minute`、または`minutes` |                 |

### 表示される単位を時間に制限する

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLab Self-Managedでは、時間単位の表示を時間に制限できます。これを行うには、次の手順に従います。

1. 左側のサイドバーで、**検索または移動**を選択します。
1. **設定 > 設定**を選択します。
1. **ローカリゼーション**を展開します。
1. **タイムトラッキング**で、**Limit display of time tracking units to hours（タイムトラッキング単位の表示を時間に制限する）**チェックボックスをオンにします。
1. **変更の保存**を選択します。

このオプションを有効にすると、`75h`の代わりに`1w 4d 3h`が表示されます。

## 関連トピック

- タイムトラッキングGraphQLリファレンス:
  - [接続](../../api/graphql/reference/_index.md#timelogconnection)
  - [エッジ](../../api/graphql/reference/_index.md#timelogedge)
  - [フィールド](../../api/graphql/reference/_index.md#timelog)
  - [タイムログ](../../api/graphql/reference/_index.md#querytimelogs)
  - [グループタイムログ](../../api/graphql/reference/_index.md#grouptimelogs)
  - [プロジェクトタイムログ](../../api/graphql/reference/_index.md#projecttimelogs)
  - [ユーザータイムログ](../../api/graphql/reference/_index.md#usertimelogs)
