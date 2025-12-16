---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: メールで返信する
description: イシューとマージリクエストに対するコメントをメールへの返信で設定します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabを設定すると、ユーザーは通知メールに返信することで、イシューやマージリクエストにコメントできるようになります。

## 前提条件 {#prerequisite}

[受信メール](incoming_email.md)が設定されていることを確認してください。

## メールによる返信の仕組み {#how-replying-by-email-works}

メールでの返信は、3つのステップで行われます:

1. GitLabから通知メールが送信されます。
1. ユーザーが通知メールに返信します。
1. GitLabが通知メールへの返信を受信します。

### GitLabから通知メールが送信される {#gitlab-sends-a-notification-email}

GitLabが通知メールを送信する場合:

- `Reply-To`ヘッダーは、設定したメールアドレスに設定されます。
- アドレスに`%{key}`プレースホルダーが含まれている場合、特定のリプライキーに置き換えられます。
- リプライキーが`References`ヘッダーに追加されます。

### 通知メールに返信する {#you-reply-to-the-notification-email}

通知メールに返信すると、メールクライアントは次のようになります:

- メールを`Reply-To`アドレス（通知メールから取得）に送信します。
- `In-Reply-To`ヘッダーを、通知メールからの`Message-ID`ヘッダーの値に設定します。
- `References`ヘッダーを、`Message-ID`の値と通知メールの`References`ヘッダーの値に設定します。

### GitLabが通知メールへの返信を受信する {#gitlab-receives-your-reply-to-the-notification-email}

GitLabが返信を受信すると、[承認済みヘッダーのリスト](incoming_email.md#accepted-headers)でリプライキーを探します。

リプライキーが見つかった場合、応答は、通知をトリガーした関連イシュー、マージリクエスト、コミット、またはその他の項目に対するコメントとして表示されます。

`Message-ID`、`In-Reply-To`、`References`のヘッダーの詳細については、[RFC 5322](https://www.rfc-editor.org/rfc/rfc5322#section-3.6.4)を参照してください。
