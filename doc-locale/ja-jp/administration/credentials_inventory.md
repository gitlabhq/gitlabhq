---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
title: 認証情報インベントリ
description: 包括的なアクセスインベントリにより認証情報を監視します。
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

{{< history >}}

- グループアクセストークンがGitLab 15.6で[追加されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/102959)。

{{< /history >}}

{{< alert type="note" >}}

GitLab.comについては、[GitLab.comの認証情報インベントリ](../user/group/credentials_inventory.md)を参照してください。

{{< /alert >}}

認証情報インベントリを使用して、インスタンスへのアクセスを監視および制御します。

管理者として、次のことができます:

- パーソナルアクセストークン、プロジェクトアクセストークン、またはグループアクセストークンを失効します。
- SSHキーを削除します。
- 以下を含む認証情報の詳細をレビューします:
  - 所有権。
  - アクセススコープ。
  - 使用パターン。
  - 有効期限。
  - 失効日。

## パーソナルアクセストークンを失効する {#revoke-personal-access-tokens}

インスタンス内のパーソナルアクセストークンを失効させるには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **認証情報**を選択します。
1. パーソナルアクセストークンの横にある**取り消し**を選択します。トークンが以前に有効期限切れになったか、失効された場合、代わりに発生した日付が表示されます。

アクセストークンは失効され、メールでユーザーに通知されます。

## プロジェクトアクセストークンまたはグループアクセストークンを失効する {#revoke-project-or-group-access-tokens}

インスタンス内のプロジェクトアクセストークンを失効させるには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **認証情報**を選択します。
1. 「**プロジェクトおよびグループアクセストークン**」タブを選択します。
1. プロジェクトアクセストークンの横にある**取り消し**を選択します。

アクセストークンは失効され、関連付けられているプロジェクトボットユーザーを削除するためのバックグラウンドプロセスが開始されます。

## SSHキーの削除 {#delete-ssh-keys}

インスタンス内のSSHキーを削除するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **認証情報**を選択します。
1. **SSHキー**タブを選択します。
1. SSHキーの横にある**削除**を選択します。

SSHキーが削除され、ユーザーに通知されます。

## GPGキーの表示 {#view-gpg-keys}

各GPGキーのオーナー、ID、[検証ステータス](../user/project/repository/signed_commits/gpg.md)などの詳細を確認できます。

インスタンス内のGPGキーに関する情報を表示するには、次の手順に従います:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **認証情報**を選択します。
1. **GPGキー**タブを選択します。
