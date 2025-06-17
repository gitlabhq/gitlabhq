---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ユーザーパスワード
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabへのサインインにパスワードを使用する場合、強力なパスワードを設定することが非常に重要です。脆弱なパスワードや推測されやすいパスワードを使用すると、権限のないユーザーがあなたのアカウントにサインインしやすくなります。

一部の組織では、パスワードを選択する際に特定の要件を満たすことが求められる場合があります。

[2要素認証](account/two_factor_authentication.md)で、アカウントのセキュリティを強化できます。

## パスワードを選択する

[ユーザーアカウントを作成](account/create_accounts.md)する際に、パスワードを選択できます。

外部認証/認証プロバイダーを使用してアカウントを登録する場合、パスワードを選択する必要はありません。GitLabは、[ランダムでユニークかつセキュアなパスワードを自動で設定します](../../security/passwords_for_integrated_authentication_methods.md)。

## パスワードを変更する

{{< history >}}

- GitLab 16.1で、検証済みのメールアドレスへのパスワードリセットメールを送信する機能が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/16311)されました。

{{< /history >}}

パスワードを変更できます。新しいパスワードを選択する際、GitLabは[パスワードの要件](#password-requirements)を適用します。

### 既知のパスワードを変更する

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルを編集**を選択します。
1. 左側のサイドバーで**パスワード**を選択します。
1. **現在のパスワード**テキストボックスに、現在のパスワードを入力します。
1. **新しいパスワード**と**パスワードの確認**のテキストボックスに、新しいパスワードを入力します。
1. **パスワードを保存**を選択します。

### 不明なパスワードを変更する

現在のパスワードが不明な場合は、GitLabのサインインページから**パスワードをお忘れの場合**を選択し、フォームに記入します。

既存のアカウントの確認済みのメールアドレスを入力すると、GitLabからパスワードリセットメールが送信されます。指定されたメールアドレスが既存のアカウントに関連付けられていない場合、メールは送信されません。

どちらの場合も、サインインページにリダイレクトされ、次のメッセージが表示されます。

> 「If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes.（メールアドレスがデータベースに存在する場合は、数分以内にパスワードリカバリー用のリンクがあなたのメールアドレスに送信されます。）」

{{< alert type="note" >}}

アカウントには、複数の確認済みメールアドレスを設定したり、アカウントに関連付けられたメールアドレスをすべて確認したりできます。ただし、パスワードがリセットされた後は、プライマリーメールアドレスのみをサインインに使用できます。

{{< /alert >}}

## パスワードの要件

パスワードは、次の場合に一連の要件を満たす必要があります。

- 登録時にパスワードを選択する場合。
- パスワードを忘れた場合のリセットフローを使用して、新しいパスワードを選択する場合。
- プロアクティブにパスワードを変更する場合。
- パスワードの有効期限が切れた後にパスワードを変更する場合。
- 管理者がアカウントを作成する場合。
- 管理者がアカウントを更新する場合。

デフォルトでは、GitLabは次のパスワード要件を適用します。

- パスワードの最小文字数と最大文字数。例は、[GitLab.comの設定](../gitlab_com/_index.md#password-requirements)を参照してください。
- [脆弱なパスワード](#block-weak-passwords)の不許可。

GitLab Self-Managedインストールでは、次の追加のパスワード要件を構成できます。

- [パスワードの最小文字数と最大文字数の制限](../../security/password_length_limits.md)。
- [パスワードの複雑さの要件](../../administration/settings/sign_up_restrictions.md#password-complexity-requirements)。

## 脆弱なパスワードをブロックする

{{< history >}}

- GitLab 15.4で、脆弱なパスワードを受け付けなくなる`block_weak_passwords`という名前の[フラグ](../../administration/feature_flags.md)が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/23610)されました。GitLab Self-Managedでは、デフォルトで無効になっています。
- GitLab 15.6の[GitLab.comで有効](https://gitlab.com/gitlab-org/gitlab/-/issues/363445)になりました。
- GitLab 15.7のGitLab Self-Managedで[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/363445)され、有効になりました。機能フラグ`block_weak_passwords`が削除されました。

{{< /history >}}

GitLabでは、脆弱なパスワードは許可されません。パスワードが脆弱と見なされるのは、次の場合です。

- 既知の、漏洩した4500以上のパスワードのいずれかに一致する場合。
- 名前、ユーザー名、またはメールアドレスの一部が含まれている場合。
- 予測可能な単語（たとえば、`gitlab`や`devops`）が含まれている場合。

脆弱なパスワードは、次のエラーメッセージで拒否されます。**パスワードには、一般的に使用される単語と文字の組み合わせを含めることはできません**。
