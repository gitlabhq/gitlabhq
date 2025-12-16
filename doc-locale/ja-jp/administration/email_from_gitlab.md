---
stage: None - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
group: Unassigned - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: GitLabからのメール
description: 管理者は、インスタンスのすべてのユーザー、またはグループやプロジェクトのメンバーにプレーンテキストメールを送信できます。
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

管理者は、すべてのユーザー、または選択したグループやプロジェクトのユーザーにメールを送信できます。ユーザーは、主要なメールアドレスでメールを受信します。

この機能を使用して、ユーザーに通知を送信できます:

- 新しいプロジェクト、新機能、または新製品の発売について。
- 新しいデプロイメントについて、またはダウンタイムが予想されることについて。

GitLabから送信されるメールの通知については、[GitLabの通知メール](../user/profile/notifications.md)をお読みください。

## GitLabからユーザーにメールを送信する {#sending-emails-to-users-from-gitlab}

すべてのユーザー、または特定のグループまたはプロジェクトのユーザーにメールの通知を送信できます。メールの通知は、10分に1回送信できます。

メールを送信するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. 右上隅で、**ユーザーにメールを送信する** ({{< icon name="mail" >}}) を選択します。
1. フィールドに入力します。メールの本文はプレーンテキストのみをサポートしており、HTML、Markdown、またはその他のリッチテキスト形式はサポートしていません。
1. **グループまたはプロジェクトを選択**ドロップダウンリストから、受信者を選択します。
1. **メッセージ送信**を選択します。

## メールの登録解除 {#unsubscribing-from-emails}

ユーザーは、メール内の登録解除リンクをたどることで、GitLabからのメールの受信を登録解除できます。この機能を簡単にするために、登録解除は認証されていません。

登録解除すると、登録解除が発生したことを知らせるメールの通知がユーザーに送信されます。登録解除オプションを提供するエンドポイントは、レート制限されています。
