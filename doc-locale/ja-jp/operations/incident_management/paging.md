---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: GitLabのアラートとインシデントの通知と呼び出しを設定します。これには、Slack、メール、オンコールのレスポンダーのエスカレーションポリシーが含まれます。
title: 呼び出しと通知
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

新しいアラートまたはインシデントが発生した場合、レスポンダーが直ちに通知を受け取り、問題をトリアージして対応できるようにすることが重要です。レスポンダーは、このページに記載されている方法で通知を受信できます。

## Slack通知 {#slack-notifications}

GitLab for Slackアプリを使用すると、重要なインシデントの通知を受信できます。

[GitLab for Slackアプリが設定されている](slack.md)場合、新しいインシデントが宣言されるたびに、インシデントのレスポンダーにSlackで通知が送信されます。モバイルデバイスで重要なインシデントの通知を見逃さないようにするには、お使いの携帯電話でSlackの通知を有効にします。

## メールによるアラートの通知 {#email-notifications-for-alerts}

メールによる通知は、トリガーされたアラートのプロジェクトで利用できます。**オーナー**または**メンテナー**のロールを持つプロジェクトメンバーは、新しいアラートの単一のメールによる通知を受信するオプションがあります。

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **モニタリング**を選択します。
1. **アラート**を展開する。
1. **アラート設定**タブで、**Send a single email notification to Owners and Maintainers for new alerts**（新しいアラートのオーナーとメンテナーに単一のメール通知を送信する）チェックボックスを選択します。
1. **変更を保存**を選択します。

アラートのメールによる通知を管理するには、[アラートの状態を更新します](alerts.md#change-an-alerts-status)。

## 呼び出し {#paging}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

[エスカレーションポリシー](escalation_policies.md)が設定されているプロジェクトでは、オンコールのレスポンダーにメールで重大な問題について自動的に呼び出しできます。

### アラートのエスカレーション {#escalating-an-alert}

アラートがトリガーされると、オンコールのレスポンダーへのエスカレーションが直ちに開始されます。プロジェクトのエスカレーションポリシーの各エスカレーションルールについて、指定されたオンコールのレスポンダーは、ルールがトリガーされると1通のメールを受信します。[アラートの状態を更新する](alerts.md#change-an-alerts-status)ことで、呼び出しに応答したり、アラートのエスカレーションを停止したりできます。

### インシデントのエスカレーション {#escalating-an-incident}

{{< history >}}

- GitLab 14.9で`incident_escalations`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/groups/gitlab-org/-/epics/5716)されました。デフォルトでは無効になっています。
- GitLab 14.10で[GitLab.comおよびGitLab Self-Managedで有効になりました](https://gitlab.com/gitlab-org/gitlab/-/issues/345769)。
- GitLab 15.1で[機能フラグ`incident_escalations`](https://gitlab.com/gitlab-org/gitlab/-/issues/345769)は削除されました。

{{< /history >}}

インシデントの場合、オンコールのレスポンダーの呼び出しは、個々のインシデントごとにオプションです。

インシデントのエスカレーションを開始するには、[インシデントのエスカレーションポリシーを設定します](manage_incidents.md#change-escalation-policy)。

各エスカレーションルールについて、指定されたオンコールのレスポンダーは、ルールがトリガーされると1通のメールを受信します。呼び出しに応答するか、[インシデントの状態を変更する](manage_incidents.md#change-status)か、インシデントのエスカレーションポリシーを**No escalation policy**（エスカレーションポリシーなし）に戻すことで、インシデントのエスカレーションを停止します。

GitLab 15.1以前では、[アラートから作成されたインシデント](manage_incidents.md#from-an-alert)は、独立したエスカレーションをサポートしていません。[GitLab 15.2以降](https://gitlab.com/gitlab-org/gitlab/-/issues/356057)では、すべてのインシデントを個別にエスカレーションできます。
