---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 外部参加者
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/groups/gitlab-org/-/epics/3758)されました。

{{< /history >}}

外部参加者とは、GitLabアカウントを持たないユーザーで、イシューまたはサービスデスクチケットにメールのみでやり取りできるユーザーです。彼らは、イシューまたはチケットに対する公開コメントについて、[サービスデスクのメール](configure.md#customize-emails-sent-to-external-participants)で通知を受け取ります。

1つのイシューまたはチケットにおける外部参加者の最大数は10人です。

<i class="fa-youtube-play" aria-hidden="true"></i>概要については、[GitLabサービスデスクにおける複数の外部参加者](https://www.youtube.com/watch?v=eKNe7fYQCLc)を参照してください。
<!-- Video published on 2024-05-13 -->

## サービスデスクチケット {#service-desk-tickets}

GitLabは、サービスデスクチケットの外部作成者を外部参加者として追加します。これは通常、チケットを作成した最初のメールの`From`ヘッダーにあるメールアドレスです。

### `Cc`ヘッダーから外部参加者を追加 {#add-external-participants-from-the-cc-header}

デフォルトでは、GitLabはサービスデスクチケットを作成するメールの送信者のみを外部参加者として追加します。

GitLabを設定して、`Cc`ヘッダーのすべてのメールアドレスもサービスデスクチケットに追加できます。これは、最初のメールと、[`thank_you`メール](configure.md#customize-emails-sent-to-external-participants)へのすべての返信に対して機能します。

`Cc`ヘッダーから追加された外部参加者は、チケットに追加されたことを知らせるために、`thank_you`メールの代わりに`new_participant`メールを受け取ります。

前提条件: 

- プロジェクトのメンテナーまたはオーナーロールが必要です。

プロジェクトの設定を有効にするには:

1. 上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定** > **一般**を選択します。
1. 展開する**サービスデスク**。
1. **Add external participants from the `Cc` header**を選択します。
1. **変更を保存**を選択します。

## 外部参加者として {#as-an-external-participant}

外部参加者は、イシューまたはチケットに対する各公開コメントについて、[サービスデスクのメール](configure.md#customize-emails-sent-to-external-participants)を使用して通知を受け取ります。

### 通知メールへの返信 {#replying-to-notification-emails}

外部参加者は、受信した[通知メールに返信](../../../administration/reply_by_email.md#you-reply-to-the-notification-email)できます。これにより、イシューまたはチケットに新しいコメントが作成され、GitLabのユーザー名の代わりに外部参加者のメールアドレスが表示されます。メールアドレスの後に`(external participant)`が続きます。

![外部参加者によるイシューまたはチケットへのコメント](img/service_desk_external_participants_comment_v17_0.png)

### 通知メールの購読解除 {#unsubscribing-from-notification-emails}

外部参加者は、デフォルトのサービスデスクのメールテンプレートの購読解除リンクを使用して、イシューまたはチケットの購読を解除できます。

もし[`thank_you`、`new_participant`、および`new_note`のメールテンプレートをカスタマイズ](configure.md#customize-emails-sent-to-external-participants)する場合、`%{UNSUBSCRIBE_URL}`プレースホルダーを使用して購読解除リンクをテンプレートに追加できます。

外部参加者が正常に購読を解除するには、GitLabインスタンスに到達可能である必要があります（たとえば、パブリックインターネットから）。そうでない場合は、テンプレートから購読解除リンクを削除することを検討してください。

GitLabからのメールには、サポートされているメールクライアントやその他のソフトウェアが[外部参加者を自動的に購読解除](../../profile/notifications.md#using-an-email-client-or-other-software)できる特別なヘッダーも含まれています。

## GitLabユーザーとして {#as-a-gitlab-user}

外部参加者のメールアドレスを表示するには、プロジェクトのレポーター、デベロッパー、メンテナー、またはオーナーロールが必要です。

外部参加者のメールアドレスは、以下の両方の条件が真の場合に難読化されます:

- あなたがプロジェクトのメンバーではないか、ゲストロールを持っている場合。
- イシューまたはチケットが公開されている（[非機密](../issues/confidential_issues.md)）場合。

その後、外部参加者のメールアドレスは以下で難読化されます:

- サービスデスクチケットの作成者フィールド。
- 外部参加者について言及するすべての[システムノート](../system_notes.md)。
- [REST](../../../api/notes.md)および[GraphQL](../../../api/graphql/_index.md) API。
- コメントエディタの下の警告メッセージ。

例: 

![システムノート内の外部参加者の難読化されたメールアドレス](img/service_desk_external_participants_email_obfuscation_v17_0.png)

### 外部参加者に送信される通知 {#notifications-sent-to-external-participants}

外部参加者は、イシューに対するすべての公開コメントについて通知を受け取ります。非公開のコミュニケーションには、[内部メモ](../../discussions/_index.md#add-an-internal-note)を使用します。

外部参加者は、その他のイシューまたはチケットイベントに関する通知を受け取りません。

### すべての外部参加者を表示 {#view-all-external-participants}

新しいコメントに対してサービスデスクのメールを受け取るすべての外部参加者の概要を表示します。

前提条件: 

- プロジェクトのレポーター、デベロッパー、メンテナー、またはオーナーのロールが必要です。

すべての外部参加者のリストを表示するには:

1. イシューまたはチケットに移動します。
1. コメントエディタまでスクロールします。
1. イシューまたはチケットに外部参加者がいる場合、コメントエディタの下に、すべての外部参加者を一覧表示する警告が表示されます。

![コメントエディタの下に外部参加者を一覧表示する警告](img/service_desk_external_participants_comment_editor_warning_v17_0.png)

### 外部参加者を追加 {#add-an-external-participant}

{{< history >}}

- `issue_email_participants`という名前の[フラグ](../../../administration/feature_flags/list.md)を使用して、GitLab 13.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/350460)されました。デフォルトでは有効になっています。
- GitLab 18.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/350460)になりました。機能フラグ`issue_email_participants`は削除されました。

{{< /history >}}

いつでも会話に含めたい場合は、[`/add_email`クイックアクション](../quick_actions.md#add_email)を使用して外部参加者を追加します。

追加されると、外部参加者はサービスデスクのメールを使用して通知を受け取り始めます。

新しい外部参加者は、チケットに追加されたことを知らせるために`new_participant`メールを受け取ります。GitLabは、手動で追加された外部参加者に対して`thank_you`メールを送信しません。

外部参加者は、`/add_email`クイックアクションを含むコメントに対する通知メールを受け取らないため、専用のコメントで外部参加者を追加する必要があります。

前提条件: 

- プロジェクトのプランナー、レポーター、デベロッパー、メンテナー、またはオーナーロールが必要です。

イシューまたはチケットに外部参加者を追加するには:

1. イシューまたはチケットに移動します。
1. クイックアクション`/add_email user@example.com`のみを含むコメントを追加します。メールアドレスを最大6つまで連結できます。例: `/add_email user@example.com user2@example.com`。

成功メッセージと、メールアドレスを含む新しいシステムノートが表示されるはずです。

### 外部参加者を削除 {#remove-an-external-participant}

{{< history >}}

- `issue_email_participants`という名前の[フラグ](../../../administration/feature_flags/list.md)を使用して、GitLab 13.8で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/350460)されました。デフォルトでは有効になっています。
- GitLab 18.10で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/350460)になりました。機能フラグ`issue_email_participants`は削除されました。

{{< /history >}}

イシューまたはサービスデスクチケットから外部参加者を削除するには、[`/remove_email`クイックアクション](../quick_actions.md#remove_email)を使用して、通知を受け取らないようにします。

イシューまたはチケットから削除した後、彼らは新しい通知を受け取りません。しかし、彼らは以前に受信したメールに返信したり、イシューまたはチケットに新しいコメントを作成したりすることはできます。

前提条件: 

- プロジェクトのプランナー、レポーター、デベロッパー、メンテナー、またはオーナーロールが必要です。
- イシューまたはチケットには、少なくとも1人の外部参加者がいる必要があります。

イシューまたはチケットから既存の外部参加者を削除するには:

1. イシューまたはチケットに移動します。
1. クイックアクション`/remove_email user@example.com`のみを含むコメントを追加します。メールアドレスを最大6つまで連結できます。例: `/remove_email user@example.com user2@example.com`。

成功メッセージと、メールアドレスを含む新しいシステムノートが表示されるはずです。
