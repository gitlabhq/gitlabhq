---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ユーザーパスワード
description: 要件の実施とパスワードリセット手順により、ユーザーパスワードを保護します。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabへのサインインにパスワードを使用する場合、強力なパスワードを設定することが非常に重要です。脆弱なパスワードや推測されやすいパスワードを使用すると、権限のないユーザーがアカウントにサインインしやすくなります。

一部の組織では、パスワードを選択する際に特定の要件を満たすことが求められる場合があります。

[2要素認証](account/two_factor_authentication.md)で、アカウントのセキュリティを強化できます。

## パスワードを選択する {#choose-your-password}

[ユーザーアカウントを作成](account/create_accounts.md)する際に、パスワードを選択できます。

外部認証/認証プロバイダーを使用してアカウントを登録する場合、パスワードを選択する必要はありません。GitLabは、[ランダムでユニークかつセキュアなパスワードを自動で設定します](../../security/passwords_for_integrated_authentication_methods.md)。

## パスワードを変更する {#change-your-password}

パスワードを変更できます。新しいパスワードは、パスワード要件を満たしている必要があります。

パスワードを変更するには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで**パスワード**を選択します。
1. **現在のパスワード**テキストボックスに、現在のパスワードを入力します。
1. **新しいパスワード**と**パスワードの確認**のテキストボックスに、新しいパスワードを入力します。
1. **パスワードを保存**を選択します。

## パスワードリセット {#reset-your-password}

{{< history >}}

- GitLab 16.1で、検証済みのメールアドレスへのパスワードリセットメールを送信する機能が[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/16311)されました。

{{< /history >}}

パスワードを忘れた場合は、パスワードリセットのリクエストを送信できます。

パスワードリセットするには、次の手順に従います:

1. GitLabサインインページに移動します。
   - GitLab.comでは、[https://gitlab.com/users/sign_in](https://gitlab.com/users/sign_in/)で利用できます。
   - GitLab Self-ManagedおよびGitLab Dedicatedでは、ご自身のドメインを使用してください。たとえば`gitlab.example.com/users/sign_in`などです。
1. **パスワードをお忘れの場合**を選択します。
1. メールアドレスを入力してください。
1. **パスワードリセット**を選択します。

サインインページにリダイレクトされます。提供されたメールが確認済みで、既存のアカウントに関連付けられている場合、GitLabからパスワードリセットメールが送信されます。

{{< alert type="note" >}}

アカウントで複数の確認済みメールアドレスを設定したり、アカウントに関連付けられたメールアドレスをすべて確認したりできます。ただし、パスワードがリセットされた後は、プライマリーメールアドレスのみをサインインに使用できます。

{{< /alert >}}

## パスワードの要件 {#password-requirements}

パスワードは、次の場合に一連の要件を満たす必要があります:

- 登録時にパスワードを選択する場合。
- パスワードを忘れた場合のリセットフローを使用して、新しいパスワードを選択する場合。
- パスワードを事前対応的に変更する場合。
- パスワードの有効期限が切れた後にパスワードを変更する場合。
- 管理者がアカウントを作成する場合。
- 管理者がアカウントを更新する場合。

デフォルトでは、GitLabは次のパスワード要件を適用します:

- パスワードの最小文字数と最大文字数。例は、[GitLab.comの設定](../gitlab_com/_index.md#password-requirements)を参照してください。
- [脆弱なパスワード](#block-weak-passwords)の不許可。

GitLab Self-Managedインスタンスでは、次の追加のパスワード要件を設定できます:

- [パスワードの最小文字数と最大文字数の制限](../../security/password_length_limits.md)。
- [パスワードの複雑さの要件](../../administration/settings/sign_up_restrictions.md#password-complexity-requirements)。

## 脆弱なパスワードをブロックする {#block-weak-passwords}

{{< history >}}

- GitLab 15.4で`block_weak_passwords`[フラグ](../../administration/feature_flags/_index.md)とともに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/23610)され、脆弱なパスワードを受け付けなくなりました。GitLab Self-Managedでは、デフォルトで無効になっています。
- GitLab 15.6のGitLab.comで[有効](https://gitlab.com/gitlab-org/gitlab/-/issues/363445)になりました。
- GitLab 15.7のGitLab Self-Managedで[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/363445)および有効になりました。機能フラグ`block_weak_passwords`は削除されました。

{{< /history >}}

GitLabでは、脆弱なパスワードは許可されません。パスワードが脆弱と見なされるのは、次の場合です:

- 既知の、漏洩した4500個以上のパスワードのいずれかに一致する。
- 名前、ユーザー名、またはメールアドレスの一部が含まれている。
- 予測可能な単語（たとえば、`gitlab`や`devops`）が含まれている。

脆弱なパスワードは、: **Password must not contain commonly used combinations of words and letters**（パスワードには、単語と文字の一般的な組み合わせを含めることはできません）というエラーメッセージとともに拒否されます。
