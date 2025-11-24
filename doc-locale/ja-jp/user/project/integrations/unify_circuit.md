---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Unify Circuit
description: "GitLabを設定して、イベント通知をUnify Circuitの会話に送信します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

Unify Circuitインテグレーションは、GitLabからの通知をCircuitの会話に送信します。

## Unify Circuitを設定する {#set-up-unify-circuit}

Unify Circuitで、[Webhookを追加](https://www.circuit.com/unifyportalfaqdetail?articleId=164448)し、そのURLをコピーします。

GitLabで、次の手順を実行します:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Unify Circuit**を選択します。
1. **有効**切替をオンにします。
1. Unify Circuitで受信するGitLabイベントに対応するチェックボックスを選択します。
1. Unify Circuitの設定手順からコピーした**WebhookのURL**を貼り付けます。
1. **壊れたパイプラインのみ通知**チェックボックスを選択して、失敗時のみ通知します。
1. **通知を送信するブランチ**ドロップダウンリストで、通知を送信するブランチのタイプを選択します。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。

Unify Circuitの会話がGitLabイベント通知の受信を開始しました。
