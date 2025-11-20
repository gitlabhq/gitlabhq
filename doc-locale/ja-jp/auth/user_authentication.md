---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ユーザー認証
description: パスワード、2要素認証、SSHキー、アクセストークン、認証情報インベントリ。
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、ユーザーが自分のアカウントにアクセスし、リポジトリを操作する方法を保護するために、複数の認証方法を提供します。オプションの2要素認証によるパスワードをWebベースのアクセスに使用し、Git操作にはSSHキーを、APIインタラクションと自動化にはさまざまな種類のアクセストークンを使用します。

GitLabセルフマネージドおよびGitLab Dedicatedでは、管理者は認証の仕組みを設定し、認証情報の使用状況を監視し、インスタンスを保護するためのセキュリティポリシーを実装できます。ユーザーは、認証方法を管理したり、アクティブなセッションをレビューしたり、2要素認証などの追加のセキュリティ対策を設定したりできます。

{{< cards >}}

- [ユーザーパスワード](../user/profile/user_passwords.md)
- [2要素認証](../user/profile/account/two_factor_authentication.md)
- [認証情報インベントリ](../administration/credentials_inventory.md)
- [SSHキー](../user/ssh.md)
- [アクセストークン](../security/tokens/_index.md)
- [スマートカード認証](../administration/auth/smartcard.md)
- [アカウントメール検証](../security/email_verification.md)

{{< /cards >}}
