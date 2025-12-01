---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: メール
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabインスタンスから送信されるメールの一部のコンテンツをカスタマイズできます。

## カスタムロゴ {#custom-logo}

一部のメールのヘッダーにあるロゴはカスタマイズできます。[ロゴのカスタマイズセクション](../appearance.md#customize-your-homepage-button)を参照してください。

## メール通知メール本文に作成者名を含める {#include-author-name-in-email-notification-email-body}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

デフォルトでは、GitLabは通知メール内のメールアドレスを、イシュー、マージリクエスト、またはコメント作成者のメールアドレスでオーバーライドします。代わりに、メール本文に作成者のメールアドレスを含めるには、この設定を有効にします。

メール本文に作成者のメールアドレスを含めるには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **設定**を選択します。
1. **メール**を展開します。
1. **Include author name in email notification email body**（メール通知メール本文に作成者名を含める）チェックボックスを選択します。
1. **変更を保存**を選択します。

## マルチパートメールを有効にする {#enable-multipart-email}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、マルチパート形式（HTMLおよびプレーンテキスト）またはプレーンテキストのみでメールを送信できます。

マルチパートメールを有効にするには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **設定**を選択します。
1. **メール**を展開します。
1. **Enable multipart email**（マルチパートメールを有効にする）を選択します。
1. **変更を保存**を選択します。

## プライベートコミットメールのカスタムホスト名 {#custom-hostname-for-private-commit-emails}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

この設定オプションは、[プライベートコミットメール](../../user/profile/_index.md#use-an-automatically-generated-private-commit-email)のメールホスト名を設定します。デフォルトでは、`users.noreply.YOUR_CONFIGURED_HOSTNAME`に設定されています。

プライベートコミットメールで使用されるホスト名を変更するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **設定**を選択します。
1. **メール**を展開します。
1. **カスタムホスト名 (プライベートコミット用メールアドレス)**フィールドに目的のホスト名を入力します。
1. **変更を保存**を選択します。

{{< alert type="note" >}}

ホスト名が設定されると、以前のホスト名を使用するすべてのプライベートコミットメールはGitLabによって認識されません。これは、`Check whether author is a GitLab user`や`Check whether committer is the current authenticated user`などの特定の[プッシュルール](../../user/project/repository/push_rules.md)と直接競合する可能性があります。

{{< /alert >}}

## カスタム追加テキスト {#custom-additional-text}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabが送信するすべてのメールの下部に追加テキストを追加できます。この追加テキストは、たとえば、法的、監査、またはコンプライアンス上の理由で使用できます。

メールに追加テキストを追加するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **設定**を選択します。
1. **メール**を展開します。
1. **追加テキスト**フィールドにテキストを入力します。
1. **変更を保存**を選択します。

## ユーザーの非アクティブ化メール {#user-deactivation-emails}

アカウントが非アクティブ化されると、GitLabはメール通知をユーザーに送信します。

これらの通知を無効にするには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **設定**を選択します。
1. **メール**を展開します。
1. **ユーザーの非アクティブメールを有効にする**チェックボックスをオフにします。
1. **変更を保存**を選択します。

### 非アクティブ化メールのカスタム追加テキスト {#custom-additional-text-in-deactivation-emails}

{{< history >}}

- GitLab 15.9で`deactivation_email_additional_text`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/355964)されました。デフォルトでは無効になっています。
- GitLab 15.9の[GitLab Self-Managedで有効](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111882)になりました。
- GitLab 16.5で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/392761)になりました。機能フラグ`deactivation_email_additional_text`は削除されました。

{{< /history >}}

GitLabがアカウントを非アクティブ化するときに、ユーザーに送信するメールの下部に追加テキストを追加できます。このメールテキストは、[カスタム追加テキスト](#custom-additional-text)設定とは異なります。

非アクティブ化メールに追加テキストを追加するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **設定**を選択します。
1. **メール**を展開します。
1. **無効化メールの追加テキスト**フィールドにテキストを入力します。
1. **変更を保存**を選択します。

## グループとプロジェクトのアクセストークン有効期限に関するメールの継承されたメンバーへの送信 {#group-and-project-access-token-expiry-emails-to-inherited-members}

{{< history >}}

- 継承されたグループメンバーへの通知は、GitLab 17.7で`pat_expiry_inherited_members_notification`[フラグ](../feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/463016)されました。デフォルトでは無効になっています。
- 機能フラグ`pat_expiry_inherited_members_notification`は、GitLab 17.10でデフォルトで[有効になっています](https://gitlab.com/gitlab-org/gitlab/-/issues/393772)。
- 機能フラグ`pat_expiry_inherited_members_notification`は、GitLab `17.11`で削除されました。

{{< /history >}}

GitLab 17.7以降では、次の継承されたグループおよびプロジェクトメンバーは、直接のグループおよびプロジェクトメンバーに加えて、まもなく期限切れになるグループおよびプロジェクトのアクセストークンに関するメールを受信できます:

- グループの場合、それらのグループのオーナーロールを継承するメンバー。
- プロジェクトの場合、これらのグループに属するプロジェクトのオーナーまたはメンテナーロールを継承するプロジェクトメンバー。

継承されたグループおよびプロジェクトメンバーへのトークン有効期限メールを有効にするには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. 左側のサイドバーの下部にある**設定** > **設定**を選択します。
1. **メール**を展開します。
1. **Expiry notification emails about group and project access tokens should be sent to:**（グループとプロジェクトのアクセストークンの有効期限に関する通知メールを誰に送信するか:）で、**グループまたはプロジェクトのすべての直接メンバーと継承メンバー**を選択します。
1. **Enforce this setting for all groups on this instance**（このインスタンスのすべてのグループにこの設定を適用する）チェックボックスを選択します。
1. **変更を保存**を選択します。

トークン有効期限メールの詳細については、以下を参照してください:

- グループの場合、[グループのアクセストークン有効期限メールに関するドキュメント](../../user/group/settings/group_access_tokens.md#group-access-token-expiry-emails)を参照してください。
- プロジェクトの場合は、[プロジェクトのアクセストークン有効期限メールに関するドキュメント](../../user/project/settings/project_access_tokens.md#project-access-token-expiry-emails)を参照してください。
