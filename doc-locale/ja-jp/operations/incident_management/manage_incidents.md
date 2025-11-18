---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabでインシデントを作成、割り当て、更新、解決し、エスカレーションポリシーを変更します。
title: インシデントを管理する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- イテレーションに[incident](_index.md)を新たに追加する機能が、GitLab 17.0 [で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/347153)。

{{< /history >}}

このページでは、[インシデント](incidents.md)に関して、またはインシデントに関連して実行できるすべての操作について説明します。

## incidentインシデントの作成 {#create-an-incident}

インシデントは、手動または自動で作成できます。

## イテレーションにインシデントを追加 {#add-an-incident-to-an-iteration}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

イテレーションに[incident](../../user/group/iterations/_index.md)を追加するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. 左側のサイドバーで、**Plan**を選択してプロジェクトを見つけます。**イシュー** > **モニタリング**または**インシデント** > インシデントを選択し、インシデントを選択して表示します。
1. 右側のサイドバーの**イテレーション**セクションで、**編集**を選択します。
1. ドロップダウンリストから、このインシデントを追加するイテレーションを選択します。
1. ドロップダウンリストの外側の領域を選択します。

または、`/iteration`[クイックアクション](../../user/project/quick_actions.md#issues-merge-requests-and-epics)を使用することもできます。

### インシデントページから {#from-the-incidents-page}

前提要件:

- プロジェクトのレポーターロール以上が必要です。

**インシデント**ページからインシデントを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **インシデント**を選択します。
1. **インシデントを作成**を選択します。

### イシューページから {#from-the-issues-page}

前提要件:

- プロジェクトのレポーターロール以上が必要です。

**イシュー**ページからインシデントを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **イシュー**を選択し、**新規イシュー**を選択します。
1. **種類**ドロップダウンリストから、**インシデント**を選択します。ページには、インシデントに関連するフィールドのみが表示されます。
1. **イシューの作成**を選択します。

### アラートから {#from-an-alert}

[アラート](alerts.md)を表示しているときにインシデントイシューを作成します。インシデントの説明は、アラートから入力されたものです。

前提要件:

- プロジェクトのデベロッパーロール以上を持っている必要があります。

アラートからインシデントを作成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **アラート**を選択します。
1. 目的のアラートを選択します。
1. **インシデントを作成**を選択します。

インシデントが作成された後、アラートから表示するには、**インシデントを表示**を選択します。

アラートにリンクされている[インシデント](#close-an-incident)を[解決](alerts.md#change-an-alerts-status)すると、GitLabはリンクされているアラートの**解決済み**を解決済みに変更します。次に、アラートのステータス変更がクレジットされます。

### 自動的に、アラートがトリガーされたとき {#automatically-when-an-alert-is-triggered}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクト設定で、アラートがトリガーされるたびに、[自動的にインシデントを作成](alerts.md#trigger-actions-from-alerts)する機能を有効にできます。

### PagerDuty Webhookの使用 {#using-the-pagerduty-webhook}

{{< history >}}

- [PagerDuty V3 Webhook](https://support.pagerduty.com/docs/webhooks)のサポートがGitLab 15.7 [で導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/383029)。

{{< /history >}}

PagerDutyの場合、Webhookを設定して、各PagerDutyインシデントに対してGitLabインシデントを自動的に作成できます。この設定では、PagerDutyとGitLabの両方で変更を行う必要があります。

前提要件:

- プロジェクトのメンテナー以上のロールを持っている必要があります。

PagerDutyでWebhookを設定するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **モニタリング**を選択します
1. **インシデント**を展開するします。
1. **PagerDutyインテグレーション**タブを選択します。
1. **有効**切替をオンにします。
1. **インテグレーションを保存**を選択します。
1. 後の手順で使用するために、**WebhookのURL**の値をコピーします。
1. Webhook URLをPagerDuty Webhookインテグレーションに追加するには、[PagerDutyドキュメント](https://support.pagerduty.com/docs/webhooks#manage-v3-webhook-subscriptions)に記載されている手順に従ってください。

インテグレーションが成功したことを確認するには、PagerDutyからテストインシデントをトリガーして、インシデントからGitLabインシデントが作成されるかどうかを確認します。

## インシデントのリストを表示 {#view-a-list-of-incidents}

[インシデント](incidents.md#incidents-list)のリストを表示するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **インシデント**を選択します。

インシデントの[詳細ページ](incidents.md#incident-details)を表示するには、リストから選択します。

### 誰がインシデントを表示できますか {#who-can-view-an-incident}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

インシデントを表示できるかどうかは、[プロジェクト表示レベル](../../user/public_access.md)とインシデントの機密ステータスによって異なります:

- 公開プロジェクトおよび非機密インシデント: 誰でもインシデントを表示できます。
- 非公開プロジェクトおよび非機密インシデント: プロジェクトのゲストロール以上が必要です。
- 機密インシデント(プロジェクト表示レベルに関係なく): プロジェクトのプランナーロール以上が必要です。

## ユーザーに割り当て {#assign-to-a-user}

積極的に対応しているユーザーにインシデントを割り当てます。

前提要件:

- プロジェクトのレポーターロール以上が必要です。

ユーザーを割り当てるには:

1. インシデントの右側のサイドバーで、**担当者**の横にある**編集**を選択します。
1. ドロップダウンリストから、**assignees**（担当者）として追加する[複数のユーザー](../../user/project/issues/multiple_assignees_for_issues.md)を1人または複数選択します。
1. ドロップダウンリストの外側の領域を選択します。

## 重大度を変更 {#change-severity}

利用可能な重大度レベルの完全な説明については、[インシデント](incidents.md#incidents-list)リストのトピックを参照してください。

前提要件:

- プロジェクトのレポーターロール以上が必要です。

インシデントの重大度を変更するには:

1. インシデントの右側のサイドバーで、**重大度**の横にある**編集**を選択します。
1. ドロップダウンリストから、新しい重大度を選択します。

`/severity` [クイックアクション](../../user/project/quick_actions.md)を使用して、重大度を変更することもできます。

## ステータスを変更する {#change-status}

{{< history >}}

- GitLab 14.9で`incident_escalations`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/5716)されました。デフォルトでは無効になっています。
- GitLab 14.10の[GitLab.comおよびGitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/345769)。
- GitLab 15.1で[機能フラグ`incident_escalations`](https://gitlab.com/gitlab-org/gitlab/-/issues/345769)は削除されました。

{{< /history >}}

前提要件:

- プロジェクトのデベロッパーロール以上を持っている必要があります。

インシデントのステータスを変更するには:

1. インシデントの右側のサイドバーで、**ステータス**の横にある**編集**を選択します。
1. ドロップダウンリストから、新しい重大度を選択します。

**トリガー**は、新しいインシデントのデフォルトのステータスです。

### オンコールの応答者として {#as-an-on-call-responder}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

オンコールの応答者は、[インシデント呼び出し](paging.md#escalating-an-incident)のステータスを変更することで応答できます。

ステータスを変更すると、次の効果があります:

- **確認済み**へ: プロジェクトの[エスカレーションポリシー](escalation_policies.md)に基づいて、オンコールページを制限します。
- **解決済み**へ: インシデントに対するすべてのオンコール呼び出しを停止します。
- **解決済み**から**トリガー**へ: インシデントのエスカレーションを再開します。

GitLab 15.1以前では、アラートから作成された[インシデント](#from-an-alert)のステータスを変更すると、アラートのステータスも変更されます。[GitLab 15.2以降](https://gitlab.com/gitlab-org/gitlab/-/issues/356057)では、アラートステータスは独立しており、インシデントステータスが変更されても変更されません。

## エスカレーションポリシーを変更 {#change-escalation-policy}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

前提要件:

- プロジェクトのデベロッパーロール以上を持っている必要があります。

インシデントのエスカレーションポリシーを変更するには:

1. インシデントの右側のサイドバーで、**エスカレーションポリシー**の横にある**編集**を選択します。
1. ドロップダウンリストから、エスカレーションポリシーを選択します。

デフォルトでは、新しいインシデントにはエスカレーションポリシーは選択されていません。

エスカレーションポリシーを選択すると、[インシデント](#change-status)の**トリガー**が[トリガー](paging.md#escalating-an-incident)され、インシデントのエスカレートがオンコールの応答者に開始されます。

GitLab 15.1以前では、アラートから作成された[インシデント](#from-an-alert)のエスカレーションポリシーは、アラートのエスカレーションポリシーを反映しており、変更できません。[GitLab 15.2以降](https://gitlab.com/gitlab-org/gitlab/-/issues/356057)では、インシデントエスカレーションポリシーは独立しており、変更できます。

## インシデントをクローズ {#close-an-incident}

前提要件:

- プロジェクトのレポーターロール以上が必要です。

インシデントをクローズするには、右上隅で、**Incident actions**（インシデント）アクション({{< icon name="ellipsis_v" >}})を選択し、**Close incident**（インシデント）をクローズします。

アラートにリンクされているインシデントを閉じると、リンクされているアラートの[ステータス](alerts.md)が**解決済み**に変わります。次に、アラートのステータス変更がクレジットされます。

### リカバリーアラートを介してインシデントを自動的にクローズ {#automatically-close-incidents-via-recovery-alerts}

GitLabがHTTPまたはPrometheus Webhookからリカバリーアラートを受信したときに、自動的にインシデントをクローズする機能をオンにします。

前提要件:

- プロジェクトのメンテナー以上のロールを持っている必要があります。

設定を構成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **モニタリング**を選択します。
1. **インシデント**セクションを展開するします。
1. **Automatically close associated incident**（関連付けられたインシデントを自動的に閉じる）チェックボックスを選択します。
1. **変更を保存**を選択します。

GitLabが[リカバリーアラート](integrations.md#recovery-alerts)を受信すると、関連付けられたインシデントが閉じられます。このアクションは、GitLabアラートボットによって自動的に閉じられたことを示す、インシデントに関するシステムノートとして記録されます。

## インシデントを削除 {#delete-an-incident}

前提要件:

- プロジェクトのオーナーロールを持っている必要があります。

インシデントを削除するには:

1. インシデントで、**Incident actions**（インシデント）アクション({{< icon name="ellipsis_v" >}})を選択します。
1. **Delete incident**（インシデント）を削除を選択します。

または:

1. インシデントで、**タイトルと説明を編集**({{< icon name="pencil" >}})を選択します。
1. **Delete incident**（インシデント）を削除を選択します。

## その他のアクション {#other-actions}

GitLabのインシデントは[イシュー](../../user/project/issues/_index.md)の上に構築されているため、次のアクションが共通してあります:

- [To-Doアイテム](../../user/todos.md#create-a-to-do-item)を追加します。
- [ラベル](../../user/project/labels.md#assign-and-unassign-labels)を追加します。
- [マイルストーンを割り当て](../../user/project/milestones/_index.md#assign-a-milestone-to-an-item)
- [インシデント](../../user/project/issues/confidential_issues.md)を機密にする
- [期限を設定する](../../user/project/issues/due_dates.md)
- [通知](../../user/profile/notifications.md#edit-notification-settings-for-issues-merge-requests-and-epics)の切替
- [費やした時間を追跡する](../../user/project/time_tracking.md)
