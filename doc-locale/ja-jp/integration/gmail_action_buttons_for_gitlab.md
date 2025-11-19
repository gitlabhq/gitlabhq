---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Gmailアクション
description: "GitLabの通知に関するGmailアクションを設定します。"
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは[メール内のGoogleアクション](https://developers.google.com/gmail/markup/actions/actions-overview)をサポートしています。このインテグレーションを設定すると、アクションを必要とするメールはGmailでマークされます。

これを機能させるには、Googleに登録する必要があります。手順については、[Googleへの登録](https://developers.google.com/gmail/markup/registering-with-google)を参照してください。

このプロセスには多くのステップがあります。Googleによってアプリケーションが拒否されるのを避けるために、Googleによって設定されたすべての要件を満たしていることを確認してください。

特に、次の点に注意してください:

<!-- vale gitlab_base.InclusiveLanguage = NO -->

- 通知メールを送信するためにGitLabが使用するメールアカウントは、以下を満たす必要があります:
  - 「ドメインから大量のメール（1日に最低数百通のメールからGmail宛）を数週間以上送信してきた一貫した履歴」が必要です。
  - ユーザーからのスパムリクエスト率が非常に低い必要があります。
- メールは、DKIMまたはSPFで認証されている必要があります。
- 最終フォーム（**Gmailスキーマホワイトリストリクエスト**）を送信する前に、本番環境サーバーから実際のメールを送信する必要があります。これは、登録しているメールアドレスからこのメールを送信する方法を見つける必要があることを意味します。登録しているメールアドレスから実際のメールを転送することで、これを行うことができます。GitLabサーバーのRailsコンソールにアクセスして、そこからメールの送信をトリガーすることもできます。

<!-- vale gitlab_base.InclusiveLanguage = YES -->

[このGitLab.comのイシュー](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/1517)にある「Googleへの登録」ドキュメントに記載されているすべての手順をどのように行うかを確認できます。
