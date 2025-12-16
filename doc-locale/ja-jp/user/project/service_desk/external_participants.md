---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部参加者
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/groups/gitlab-org/-/epics/3758)されました。

{{< /history >}}

イシューまたはサービスデスクチケットでメールでのみやり取りできる、GitLabアカウントを持たないユーザーを外部参加者と呼びます。彼らは、[サービスデスクのメール](configure.md#customize-emails-sent-to-external-participants)によって、イシューまたはチケットに関する公開コメントの通知を受け取ります。

イシューまたはチケットの外部参加者の最大数は10人です。

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>概要については、[GitLab Service Deskの複数の外部参加者](https://www.youtube.com/watch?v=eKNe7fYQCLc)を参照してください。
<!-- Video published on 2024-05-13 -->

## サービスデスクチケット {#service-desk-tickets}

GitLabは、サービスデスクチケットの外部作成者を外部参加者として追加します。通常、これはチケットを作成した最初のメールの`From`ヘッダーからのメールアドレスです。

### `Cc`ヘッダーから外部参加者を追加 {#add-external-participants-from-the-cc-header}

デフォルトでは、GitLabは、サービスデスクチケットを作成するメールの送信者のみを外部参加者として追加します。

`Cc`ヘッダーのすべてのメールアドレスをサービスデスクチケットに追加するようにGitLabを構成することもできます。これは、最初のメールと、[`thank_you`メール](configure.md#customize-emails-sent-to-external-participants)へのすべての返信で機能します。

`Cc`ヘッダーから追加された外部参加者は、チケットに追加されたことを知らせるために、`new_participant`メールの代わりに`thank_you`メールを受信します。

前提要件: 

- プロジェクトのメンテナーロール以上が必要です。

プロジェクトの設定を有効にするには:

1. 左側のサイドバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. **サービスデスク**を展開します。
1. **Add external participants from the `Cc` header**（ヘッダー）から外部参加者を追加を選択します。
1. **変更を保存**を選択します。

## 外部参加者として {#as-an-external-participant}

外部参加者は、[サービスデスクのメール](configure.md#customize-emails-sent-to-external-participants)を使用して、イシューまたはチケットに関するすべての公開コメントの通知を受け取ります。

### 通知メールへの返信 {#replying-to-notification-emails}

外部参加者は、[受信した通知メールに返信](../../../administration/reply_by_email.md#you-reply-to-the-notification-email)できます。これにより、イシューまたはチケットに新しいコメントが作成され、GitLabのユーザー名の代わりに外部参加者のメールアドレスが表示されます。メールアドレスの後に`(external participant)`が続きます。

![イシューまたはチケットに関する外部参加者からのコメント](img/service_desk_external_participants_comment_v17_0.png)

### 通知メールのサブスクライブを解除する {#unsubscribing-from-notification-emails}

外部参加者は、デフォルトのサービスデスクメールテンプレートの登録解除リンクを使用して、イシューまたはチケットから登録解除できます。

[`thank_you`、`new_participant`、および`new_note`のメールテンプレートをカスタマイズする](configure.md#customize-emails-sent-to-external-participants)場合は、`%{UNSUBSCRIBE_URL}`プレースホルダーを使用して、登録解除リンクをテンプレートに追加できます。

外部参加者が登録解除に成功するには、GitLabインスタンスが(たとえば、パブリックインターネットから)到達可能である必要があります。そうでない場合は、テンプレートから登録解除リンクを削除することを検討してください。

GitLabからのメールには、サポートされているメールクライアントやその他のソフトウェアが[外部参加者を自動的に登録解除](../../profile/notifications.md#using-an-email-client-or-other-software)できるようにする特別なヘッダーも含まれています。

## GitLabユーザーとして {#as-a-gitlab-user}

外部参加者のメールアドレスを表示するには、少なくともプロジェクトのレポーターロールが必要です。

次の両方の条件に該当する場合、外部参加者のメールアドレスは難読化されます:

- プロジェクトのメンバーではないか、ゲストロールを持っています。
- イシューまたはチケットは公開されています([非公開](../issues/confidential_issues.md))。

外部参加者のメールアドレスは、次のように難読化されます:

- サービスデスクチケットの作成者フィールド。
- 外部参加者に言及するすべての[システムノート](../system_notes.md)。
- [REST](../../../api/notes.md)および[GraphQL](../../../api/graphql/_index.md) API。
- コメントエディターの下の警告メッセージ。

次に例を示します:

![システムノートの外部参加者の難読化されたメールアドレス](img/service_desk_external_participants_email_obfuscation_v17_0.png)

### 外部参加者に送信される通知 {#notifications-sent-to-external-participants}

外部参加者は、イシューに関するすべての公開コメントの通知を受け取ります。プライベート通信には、[内部ノート](../../discussions/_index.md#add-an-internal-note)を使用します。

外部参加者は、他のイシューまたはチケットイベントの通知を受け取りません。

### すべての外部参加者を表示 {#view-all-external-participants}

新しいコメントのサービスデスクのメールを受信するすべての外部参加者の概要を取得します。

前提要件: 

- プロジェクトのレポーターロール以上が必要です。

すべての外部参加者のリストを表示するには:

1. イシューまたはチケットに移動します。
1. コメントエディターまでスクロールダウンします。
1. イシューまたはチケットに外部参加者がいる場合、すべての外部参加者を一覧表示するコメントエディターの下に警告が表示されます。

![外部参加者を一覧表示するコメントエディターの下の警告](img/service_desk_external_participants_comment_editor_warning_v17_0.png)

### 外部参加者の追加 {#add-an-external-participant}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/350460)：GitLab 13.8（`issue_email_participants`という名前の[フラグ](../../../administration/feature_flags/list.md)を使用）。デフォルトでは有効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

いつでも会話に含めたい場合は、`/add_email` [クイックアクション](../quick_actions.md)を使用して外部参加者を追加します。

追加されると、外部参加者はサービスデスクのメールを使用して通知を受信し始めます。

新しい外部参加者は、`new_participant`メールを受信して、チケットに追加されたことを知らされます。GitLabは、手動で追加された外部参加者に`thank_you`メールを送信しません。

外部参加者は、`/add_email`クイックアクションを含むコメントの通知メールを受信しないため、専用のコメントに外部参加者を追加する必要があります。

前提要件: 

- プロジェクトのレポーターロール以上が必要です。

イシューまたはチケットに外部参加者を追加するには:

1. イシューまたはチケットに移動します。
1. クイックアクション`/add_email user@example.com`のみを含むコメントを追加します。最大6つのメールアドレスをチェーンできます。例: `/add_email user@example.com user2@example.com`。

成功メッセージとメールアドレスを含む新しいシステムノートが表示されるはずです。

### 外部参加者の削除 {#remove-an-external-participant}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/issues/350460)：GitLab 13.8（`issue_email_participants`という名前の[フラグ](../../../administration/feature_flags/list.md)を使用）。デフォルトでは有効になっています。

{{< /history >}}

{{< alert type="flag" >}}

この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

{{< /alert >}}

`/remove_email` [クイックアクション](../quick_actions.md)を使用して、イシューまたはサービスデスクチケットから外部参加者を削除して、通知の受信を停止する必要があります。

イシューまたはチケットから削除した後、新しい通知は受信されません。ただし、以前に受信したメールに返信したり、イシューまたはチケットに新しいコメントを作成したりすることはできます。

前提要件: 

- プロジェクトのレポーターロール以上が必要です。
- イシューまたはチケットに少なくとも1人の外部参加者がいなければなりません。

イシューまたはチケットから既存の外部参加者を削除するには:

1. イシューまたはチケットに移動します。
1. クイックアクション`/remove_email user@example.com`のみを含むコメントを追加します。最大6つのメールアドレスをチェーンできます。例: `/remove_email user@example.com user2@example.com`。

成功メッセージとメールアドレスを含む新しいシステムノートが表示されるはずです。
