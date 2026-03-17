---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: GitLabでインシデントを作成、割り当て、更新、解決する、およびエスカレーションポリシーを変更します。
title: インシデントを管理する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- イテレーションに[インシデント](_index.md)を追加する機能は、GitLab 17.0で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/347153)。

{{< /history >}}

このページには、[インシデント](incidents.md)、またはそれに関連して実行できるすべての操作の手順がまとめられています。

## インシデントを作成する {#create-an-incident}

インシデントを手動または自動で作成できます。

## イテレーションにインシデントを追加する {#add-an-incident-to-an-iteration}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[イテレーション](../../user/group/iterations/_index.md)にインシデントを追加するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **イシュー**または**モニタリング** > **インシデント**を選択し、表示するインシデントを選択します。
1. 右サイドバーで、**イテレーション**セクションにある**編集**を選択します。
1. ドロップダウンリストから、このインシデントを追加するイテレーションを選択します。
1. ドロップダウンリストの外側の領域を選択します。

または、[`/iteration`クイックアクション](../../user/project/quick_actions.md#iteration)を使用することもできます。

### インシデントページから {#from-the-incidents-page}

前提条件: 

- プロジェクトに対して、レポーター、デベロッパー、メンテナー、またはオーナーのロールを持っている必要があります。

**インシデント**ページからインシデントを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **インシデント**を選択します。
1. **インシデントを作成**を選択します。

### イシューページから {#from-the-issues-page}

前提条件: 

- プロジェクトに対して、レポーター、デベロッパー、メンテナー、またはオーナーのロールを持っている必要があります。

**イシュー**ページからインシデントを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **Plan** > **イシュー**を選択し、**新規イシュー**を選択します。
1. **タイプ**ドロップダウンリストから、**インシデント**を選択します。インシデントに関連するフィールドのみがページで利用可能です。
1. **イシューを作成**を選択します。

### アラートから {#from-an-alert}

[アラート](alerts.md)を表示中にインシデントイシューを作成します。インシデントの説明は、アラートから入力されたものです。

前提条件: 

- プロジェクトのデベロッパー、メンテナー、またはオーナーロールが必要です。

アラートからインシデントを作成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **アラート**を選択します。
1. 目的のアラートを選択します。
1. **インシデントを作成**を選択します。

インシデントが作成された後、アラートからそれを表示するには、**インシデントを表示**を選択します。

アラートにリンクされている[インシデントをクローズする](#close-an-incident)と、GitLabは[アラートのステータスを](alerts.md#change-an-alerts-status)**解決済み**に変更します。その際、アラートのステータス変更はあなたに帰属します。

### アラートがトリガーされたときに自動的に {#automatically-when-an-alert-is-triggered}

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

プロジェクトの設定で、アラートがトリガーされるたびに[インシデントを自動的に作成する](alerts.md#trigger-actions-from-alerts)ことができます。

### PagerDuty Webhookを使用する {#using-the-pagerduty-webhook}

{{< history >}}

- [PagerDuty V3 Webhook](https://support.pagerduty.com/docs/webhooks)のサポートはGitLab 15.7で[導入されました](https://gitlab.com/gitlab-org/gitlab/-/issues/383029)。

{{< /history >}}

PagerDutyでWebhookを設定して、PagerDutyの各インシデントに対してGitLabのインシデントを自動的に作成できます。この設定では、PagerDutyとGitLabの両方で変更を行う必要があります。

前提条件: 

- プロジェクトに対して、メンテナーまたはオーナーのロールを持っている必要があります。

PagerDutyでWebhookを設定するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **モニタリング**を選択します。
1. **インシデント**セクションを展開する。
1. **PagerDutyインテグレーション**タブを選択します。
1. **アクティブ**切替をオンにします。
1. **インテグレーションを保存**を選択します。
1. 後のステップで使用するため、**WebhookのURL**の値をコピーします。
1. PagerDuty WebhookインテグレーションにWebhook URLを追加するには、[PagerDutyのドキュメント](https://support.pagerduty.com/docs/webhooks#manage-v3-webhook-subscriptions)に記載されている手順に従ってください。

インテグレーションが成功したことを確認するには、PagerDutyからテストインシデントをトリガーして、GitLabインシデントが作成されたかどうかを確認します。

## インシデントのリストを表示する {#view-a-list-of-incidents}

[インシデント](incidents.md#incidents-list)のリストを表示するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **モニタリング** > **インシデント**を選択します。

インシデントの[詳細ページ](incidents.md#incident-details)を表示するには、リストから選択します。

### インシデントを表示できるユーザー {#who-can-view-an-incident}

{{< history >}}

- GitLab 17.7で、最小ユーザーロールがレポーターからプランナーに[変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169256)されました。

{{< /history >}}

インシデントを表示できるかどうかは、[プロジェクトの表示レベル](../../user/public_access.md)とインシデントの機密状態によって異なります:

- 公開プロジェクトおよび非機密のインシデント: 誰でもそのインシデントを表示できます。
- プライベートプロジェクトおよび非機密のインシデント: プロジェクトに対して、ゲスト、プランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールを持っている必要があります。
- 機密インシデント（プロジェクトの表示レベルに関係なく）: プロジェクトに対して、プランナー、レポーター、デベロッパー、メンテナー、またはオーナーのロールを持っている必要があります。

## ユーザーに割り当てる {#assign-to-a-user}

積極的に対応しているユーザーにインシデントを割り当てます。

前提条件: 

- プロジェクトに対して、レポーター、デベロッパー、メンテナー、またはオーナーのロールを持っている必要があります。

ユーザーを割り当てるには:

1. インシデントの右サイドバーで、**担当者**の横にある**編集**を選択します。
1. ドロップダウンリストから、1人または[複数のユーザー](../../user/project/issues/multiple_assignees_for_issues.md)を**assignees**として追加するために選択します。
1. ドロップダウンリストの外側の領域を選択します。

## 重大度を変更する {#change-severity}

利用可能な重大度レベルの詳細については、[インシデントリスト](incidents.md#incidents-list)トピックを参照してください。

前提条件: 

- プロジェクトに対して、レポーター、デベロッパー、メンテナー、またはオーナーのロールを持っている必要があります。

インシデントの重大度を変更するには:

1. インシデントの右サイドバーで、**重大度**の横にある**編集**を選択します。
1. ドロップダウンリストから、新しい重大度を選択します。

[`/severity`クイックアクション](../../user/project/quick_actions.md#severity)を使用して重大度を変更することもできます。

## ステータスを変更する {#change-status}

{{< history >}}

- GitLab 14.9で`incident_escalations`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/5716)されました。デフォルトでは無効になっています。
- GitLab 14.10で[GitLab.comおよびGitLabセルフマネージドで有効化されました](https://gitlab.com/gitlab-org/gitlab/-/issues/345769)。
- GitLab 15.1で[機能フラグ`incident_escalations`](https://gitlab.com/gitlab-org/gitlab/-/issues/345769)は削除されました。

{{< /history >}}

前提条件: 

- プロジェクトのデベロッパー、メンテナー、またはオーナーロールが必要です。

インシデントのステータスを変更するには:

1. インシデントの右サイドバーで、**ステータス**の横にある**編集**を選択します。
1. ドロップダウンリストから、新しい重大度を選択します。

**トリガー**は、新規インシデントのデフォルトステータスです。

### オンコール対応者として {#as-an-on-call-responder}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

オンコール対応者は、ステータスを変更することで[インシデントページ](paging.md#escalating-an-incident)に対応できます。

ステータスを変更すると、次の効果があります:

- **確認済み**にする: プロジェクトの[エスカレーションポリシー](escalation_policies.md)に基づいてオンコールページングを制限します。
- **解決済み**にする: そのインシデントのすべてのオンコールページングを停止します。
- **解決済み**から**トリガー**にする: インシデントのエスカレーションを再開します。

GitLab 15.1以前では、[アラートから作成されたインシデント](#from-an-alert)のステータスを変更すると、アラートのステータスも変更されました。[GitLab 15.2以降](https://gitlab.com/gitlab-org/gitlab/-/issues/356057)では、アラートのステータスは独立しており、インシデントのステータスが変更されても変更されません。

## エスカレーションポリシーを変更する {#change-escalation-policy}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

前提条件: 

- プロジェクトのデベロッパー、メンテナー、またはオーナーロールが必要です。

インシデントのエスカレーションポリシーを変更するには:

1. インシデントの右サイドバーで、**エスカレーションポリシー**の横にある**編集**を選択します。
1. ドロップダウンリストから、エスカレーションポリシーを選択します。

デフォルトでは、新しいインシデントにはエスカレーションポリシーが選択されていません。

エスカレーションポリシーを選択すると、[インシデントステータスが変更](#change-status)されて**トリガー**になり、[インシデントのオンコール対応者へのエスカレート](paging.md#escalating-an-incident)が開始されます。

GitLab 15.1以前では、[アラートから作成されたインシデント](#from-an-alert)のエスカレーションポリシーはアラートのエスカレーションポリシーを反映しており、変更できませんでした。[GitLab 15.2以降](https://gitlab.com/gitlab-org/gitlab/-/issues/356057)では、インシデントエスカレーションポリシーは独立しており、変更可能です。

## インシデントをクローズする {#close-an-incident}

前提条件: 

- プロジェクトに対して、レポーター、デベロッパー、メンテナー、またはオーナーのロールを持っている必要があります。

インシデントをクローズするには、右上隅で**Incident actions** ({{< icon name="ellipsis_v" >}}) を選択し、次に**Close incident**を選択します。

[アラート](alerts.md)にリンクされているインシデントをクローズすると、リンクされているアラートのステータスが**解決済み**に変更されます。その際、アラートのステータス変更はあなたに帰属します。

### リカバリーアラートを介してインシデントを自動的にクローズする {#automatically-close-incidents-via-recovery-alerts}

GitLabがHTTPまたはPrometheusWebhookからリカバリーアラートを受信したときに、インシデントを自動的にクローズするように設定します。

前提条件: 

- プロジェクトに対して、メンテナーまたはオーナーのロールを持っている必要があります。

設定を構成するには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **モニタリング**を選択します。
1. **インシデント**セクションを展開する。
1. **Automatically close associated incident**チェックボックスを選択します。
1. **変更を保存**を選択します。

GitLabが[リカバリーアラート](integrations.md#recovery-alerts)を受信すると、関連付けられたインシデントがクローズされます。このアクションは、インシデントにシステムノートとして記録され、GitLabアラートボットによって自動的にクローズされたことを示します。

## インシデントを削除する {#delete-an-incident}

前提条件: 

- プロジェクトのオーナーロールを持っている必要があります。

インシデントを削除するには:

1. インシデントで、**Incident actions** ({{< icon name="ellipsis_v" >}}) を選択します。
1. **Delete incident**を選択します。

または:

1. インシデントで、**編集**を選択します。
1. **Delete incident**を選択します。

## その他のアクション {#other-actions}

GitLabのインシデントは[イシュー](../../user/project/issues/_index.md)の上に構築されているため、以下の共通のアクションがあります:

- [To-Doアイテムを追加する](../../user/todos.md#create-a-to-do-item)
- [ラベルを追加する](../../user/project/labels.md#assign-and-unassign-labels)
- [マイルストーンを割り当てる](../../user/project/milestones/_index.md#assign-a-milestone-to-an-item)
- [インシデントを機密にする](../../user/project/issues/confidential_issues.md)
- [期限を設定する](../../user/project/issues/due_dates.md)
- [通知を切替る](../../user/profile/notifications.md#subscribe-to-notifications-for-a-specific-issue-merge-request-or-epic)
- [費やした時間を追跡する](../../user/project/time_tracking.md)
