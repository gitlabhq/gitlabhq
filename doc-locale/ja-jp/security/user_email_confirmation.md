---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 新規ユーザーにメール確認をリクエストする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

GitLabは、ユーザーがサインアップするときに、ユーザーのメールアドレスの確認を要求するように設定できます。この設定が有効な場合、ユーザーはメールアドレスを確認するまでサインインできません。

前提条件: 

- 管理者アクセス権。

1. 右上隅で、**管理者**を選択します。
1. 左側のサイドバーで、**設定** > **一般**を選択します。
1. 展開する**新しいユーザーアカウントの制限**を選択し、**メールの確認設定**オプションを探します。

## 確認トークンの有効期限 {#confirmation-token-expiry}

デフォルトでは、ユーザーは確認メールの送信後24時間以内にアカウントを確認できます。24時間後、確認トークンは無効になります。

## 未確認ユーザーの自動削除 {#automatically-delete-unconfirmed-users}

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

メール確認が有効になっている場合、管理者は設定を有効にして、[未確認ユーザーを自動的に削除](../administration/moderate_users.md#automatically-delete-unconfirmed-users)できます。
