---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab.comの認証情報インベントリ
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com

{{< /details >}}

{{< history >}}

- GitLab 17.5でGitLab.comに[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/297441)されました。

{{< /history >}}

{{< alert type="note" >}}

GitLab Self-Managedについては、[GitLab Self-Managedの認証情報インベントリ](../../administration/credentials_inventory.md)を参照してください。

{{< /alert >}}

GitLab.comのグループとプロジェクトへのアクセスを監視および制御するには、認証情報インベントリを使用します。

トップレベルグループのオーナーとして、次のことができます:

- パーソナルアクセストークンを取り消す。
- SSHキーを削除します。
- 以下の[エンタープライズユーザー](../enterprise_user/_index.md)の認証情報の詳細をレビューします:
  - 所有権。
  - アクセススコープ。
  - 使用パターン。
  - 有効期限。
  - 失効日。

## パーソナルアクセストークンを失効する {#revoke-personal-access-tokens}

グループ内のエンタープライズユーザーのパーソナルアクセストークンを失効するには:

1. 左側のサイドバーで、**セキュリティ**を選択します。
1. **認証情報**を選択します。
1. パーソナルアクセストークンの横にある**取り消し**を選択します。トークンが以前に期限切れになったか、失効された場合、代わりにこの日付が表示されます。

アクセストークンは失効され、ユーザーにメールで通知されます。

## SSHキーの削除 {#delete-ssh-keys}

グループ内のエンタープライズユーザーのSSHキーを削除するには:

1. 左側のサイドバーで、**セキュリティ**を選択します。
1. **認証情報**を選択します。
1. **SSHキー**タブを選択します。
1. SSHキーの横にある**削除**を選択します。

SSHキーが削除され、ユーザーに通知されます。

## プロジェクトまたはグループアクセストークンを失効する {#revoke-project-or-group-access-tokens}

GitLab.comの認証情報インベントリを使用して、プロジェクトまたはグループのアクセストークンを表示または失効することはできません。[イシュー498333](https://gitlab.com/gitlab-org/gitlab/-/issues/498333)で、この機能の追加が提案されています。
