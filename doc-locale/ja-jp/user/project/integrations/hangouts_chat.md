---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Google Chat
description: "Google Chatのインテグレーションを設定して、Google ChatスペースでGitLabからの通知を受信します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabでプロジェクトを構成して、[Google Chat](https://chat.google.com/)で選択したスペースに通知を送信できます。

GitLab 16.10以降では、同じGitLabオブジェクト（例えば、イシューまたはマージリクエスト）に対して、スレッド化された通知がデフォルトでGoogle Chatで有効になっています。詳細については、[issue 438452](https://gitlab.com/gitlab-org/gitlab/-/issues/438452)を参照してください。

## インテグレーションを設定する {#configure-the-integration}

### Google Chat {#in-google-chat}

Google Chatでインテグレーションを構成するには:

1. GitLabからの通知を受信するスペースに移動します。
1. 左上で、スペース名の横にある下矢印（{{< icon name="chevron-down" >}}）> **Apps & integrations**（アプリとインテグレーション）を選択します。
1. **Webhooks**セクションで、**Add webhooks**（Webhookを追加）を選択します。
1. **Incoming webhooks**（受信webhooks）ダイアログ:
   - **名前**に、Webhookの名前を入力します（例: `GitLab integration`）。
   - オプション。**Avatar URL**（アバターURL）に、ボットのアバターを入力します。
1. **保存**を選択します。
1. Webhook URLの横にある縦方向の省略記号（{{< icon name="ellipsis_v" >}}）> **リンクをコピー**を選択します。

Webhooksの詳細については、[Google Chatドキュメント](https://developers.google.com/workspace/chat/quickstart/webhooks)を参照してください。

### GitLab {#in-gitlab}

GitLabでインテグレーションを構成するには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **インテグレーション**を選択します。
1. **Google Chat**を選択します。
1. **インテグレーションを有効にする**で、**有効**チェックボックスをオンにします。
1. **Webhook**で、[Google ChatからコピーしたURLを貼り付け](#in-google-chat)ます。
1. **トリガー**セクションで、Google Chatスペースで通知を受信する各GitLabイベントのチェックボックスを選択します。
1. オプション。**通知設定**セクションで、次のことを行います:
   - **壊れたパイプラインのみ通知**チェックボックスをオンにして、失敗したパイプラインの通知のみを受信します。
   - **通知を送信するブランチ**ドロップダウンリストから、通知を受信するブランチを選択します。
1. オプション。**テスト設定**を選択します。
1. **変更を保存**を選択します。
