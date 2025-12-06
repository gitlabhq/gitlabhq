---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 統合認証で作成されたユーザーの生成パスワード
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabでは、外部の[認証および認可プロバイダー](../administration/auth/_index.md)とのインテグレーションにより、ユーザーがアカウントを設定できます。

これらの認証方式では、ユーザーが自分のアカウントのパスワードを明示的に作成する必要はありません。ただし、データの一貫性を維持するために、GitLabではすべてのユーザーアカウントにパスワードが必要です。

これらのアカウントでは、GitLabはDevise gemが提供する[`friendly_token`](https://github.com/heartcombo/devise/blob/f26e05c20079c9acded3c0ee16da0df435a28997/lib/devise.rb#L492)メソッドを使用して、ランダムで一意で安全なパスワードを生成します。GitLabは、サインアップ時にこのパスワードをアカウントのパスワードとして設定します。

生成されるパスワードの長さは[128文字](password_length_limits.md)です。
