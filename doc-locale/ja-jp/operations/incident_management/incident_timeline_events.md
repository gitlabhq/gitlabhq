---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: インシデントの表示、作成、編集、解決、およびインシデントの重大度、ステータス、エスカレーションポリシーの変更を行います。
title: タイムラインイベント
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 15.2で`incident_timeline`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/344059)されました。デフォルトでは有効になっています。
- GitLab 15.3の[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/353426)で有効になりました。
- GitLab 15.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/353426)になりました。[機能フラグ`incident_timeline`](https://gitlab.com/gitlab-org/gitlab/-/issues/343386)は削除されました。

{{< /history >}}

インシデントのタイムラインは、インシデントの記録保持の重要な部分です。タイムラインでは、経営幹部や外部の閲覧者に対して、インシデント中に何が起こり、それを解決するためにどのような措置が取られたかを示すことができます。

## タイムラインを表示する {#view-the-timeline}

インシデントのタイムラインイベントは、日付と時刻の昇順にリスト表示されます。これらは日付でグループ化され、発生した時刻の昇順にリスト表示されます:

![インシデントタイムラインイベントリスト](img/timeline_events_v15_1.png)

インシデントのイベントタイムラインを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **インシデント**を選択します。
1. インシデントを選択します。
1. **タイムライン**タブを選択します。

## イベントを作成する {#create-an-event}

GitLabでは、さまざまな方法でタイムラインイベントを作成できます。

### フォームの使用 {#using-the-form}

フォームを使用して、手動でタイムラインイベントを作成します。

前提要件:

- プロジェクトのデベロッパーロール以上を持っている必要があります。

タイムラインイベントを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **インシデント**を選択します。
1. インシデントを選択します。
1. **タイムライン**タブを選択します。
1. **新しいタイムラインイベントを追加**を選択します。
1. 必要なフィールドに入力してください。
1. **保存**または**別のイベントを保存して追加**を選択します。

### クイックアクションを使用する {#using-a-quick-action}

{{< history >}}

- GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/368721)されました。

{{< /history >}}

`/timeline` [クイックアクション](../../user/project/quick_actions.md)を使用して、タイムラインイベントを作成できます。

### インシデントのコメントから {#from-a-comment-on-the-incident}

{{< history >}}

- GitLab 15.4で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/344058)されました。

{{< /history >}}

前提要件:

- プロジェクトのデベロッパーロール以上を持っている必要があります。

{{< alert type="warning" >}}

パブリックおよび内部のインシデントのインシデントタイムラインに追加された内部メモは、インシデントへのアクセス権を持つすべてのユーザーに表示されます。

{{< /alert >}}

インシデントのコメントからタイムラインイベントを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **インシデント**を選択します。
1. インシデントを選択します。
1. コメントを作成するか、既存のコメントを選択します。
1. 追加するコメントで、**インシデントタイムラインにコメントを追加** ({{< icon name="clock" >}})を選択します。

コメントは、タイムラインイベントとしてインシデントタイムラインに表示されます。

### インシデントの重大度が変更されたとき {#when-incident-severity-changes}

{{< history >}}

- GitLab 15.6で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/375280)されました。

{{< /history >}}

インシデントの[重大度を変更](manage_incidents.md#change-severity)すると、新しいタイムラインイベントが作成されます。

![重大度変更のインシデントタイムラインイベント](img/timeline_event_for_severity_change_v15_6.png)

### ラベルが変更されたとき {#when-labels-change}

{{< details >}}

- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 15.3で`incident_timeline_events_from_labels`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/365489)されました。デフォルトでは無効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。この機能はテストには利用できますが、本番環境での使用には適していません。

{{< /alert >}}

インシデントに誰かが[ラベル](../../user/project/labels.md)を追加または削除すると、新しいタイムラインイベントが作成されます。

## イベントを削除する {#delete-an-event}

{{< history >}}

- 編集時にイベントを削除する機能は、GitLab 15.7で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/372265)。

{{< /history >}}

タイムラインイベントを削除することもできます。

前提要件:

- プロジェクトのデベロッパーロール以上を持っている必要があります。

タイムラインイベントを削除するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **インシデント**を選択します。
1. インシデントを選択します。
1. **タイムライン**タブを選択します。
1. タイムラインイベントの右側で、**追加のアクション** ({{< icon name="ellipsis_v" >}}) を選択し、**削除**を選択します。
1. 確認するには、**Delete Event**（イベントを削除）を選択します。

または:

1. タイムラインイベントの右側で、**追加のアクション** ({{< icon name="ellipsis_v" >}}) を選択し、**編集**を選択します。
1. **削除**を選択します。
1. 確認するには、**イベントを削除**を選択します。

## インシデントタグ {#incident-tags}

{{< history >}}

- GitLab 15.9で`incident_event_tags`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/8741)されました。デフォルトでは無効になっています。
- GitLab 15.9の[GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/387647)で有効になりました。
- GitLab 15.10の[GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/387647)で有効になりました。
- GitLab 15.11で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/387647)になりました。機能フラグ`incident_event_tags`は削除されました。

{{< /history >}}

[フォームを使用してイベントを作成](#using-the-form)するとき、または編集するときに、関連するインシデントのタイムスタンプをキャプチャするためにインシデントタグを指定できます。タイムラインタグはオプションです。イベントごとに複数のタグを選択できます。タイムラインイベントを作成してタグを選択すると、イベントノートにデフォルトのメッセージが入力された状態になります。これにより、迅速なイベント作成が可能になります。ノートがすでに設定されている場合、変更されません。追加されたタグは、タイムスタンプの横に表示されます。

## フォーマットルール {#formatting-rules}

インシデントタイムラインイベントは、次の[GitLab Flavored Markdown](../../user/markdown.md)機能をサポートしています。

- [コード](../../user/markdown.md#code-spans-and-blocks)。
- [絵文字](../../user/markdown.md#emoji)。
- [強調](../../user/markdown.md#emphasis)。
- [GitLab固有の参照](../../user/markdown.md#gitlab-specific-references)。
- [画像](../../user/markdown.md#images)。アップロードされた画像へのリンクとしてレンダリングされます。
- [リンク](../../user/markdown.md#links)。
