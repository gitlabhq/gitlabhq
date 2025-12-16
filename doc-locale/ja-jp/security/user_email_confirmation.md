---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 新規ユーザーにメール確認をリクエストする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、ユーザーがサインアップする際に、ユーザーのメールアドレスの確認を要求するように設定できます。この設定が有効になっている場合、ユーザーはメールアドレスを確認するまでサインインできません。

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **設定** > **一般**を選択します。
1. **新規登録の制限**を展開し、**メールの確認設定**オプションを探します。

## 確認トークンの有効期限 {#confirmation-token-expiry}

デフォルトでは、ユーザーは確認メールが送信されてから24時間以内にアカウントを確認できます。24時間後、確認トークンは無効になります。

## 確認されていないユーザーの自動削除 {#automatically-delete-unconfirmed-users}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

メールの確認がオンになっている場合、管理者は[確認されていないユーザーを自動的に削除](../administration/moderate_users.md#automatically-delete-unconfirmed-users)する設定を有効にできます。
