---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: ユーザーを削除する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

ユーザーはGitLabインスタンスから削除できます。削除できるのは次のいずれかの方法によります:

- ユーザー自身。
- 管理者として

{{< alert type="note" >}}

ユーザーを削除すると、そのユーザーネームスペース内のすべてのプロジェクトが削除されます。

{{< /alert >}}

## 自分のアカウントを削除する {#delete-your-own-account}

{{< details >}}

- 提供形態: GitLab.com、GitLab Self-Managed

{{< /details >}}

{{< history >}}

- ユーザーが自分のアカウントを削除してから、ユーザーレコードが削除されるまでの遅延は、GitLab 16.0で導入されました。[フラグ](../../../administration/feature_flags/_index.md)の名前は`delay_delete_own_user`です。GitLab.comでは、デフォルトで有効になっています。

{{< /history >}}

{{< alert type="note" >}}

GitLab Self-Managedインスタンスでは、この機能はデフォルトで無効になっています。インスタンスの`delay_user_account_self_deletion`設定を有効にするには、[アプリケーション設定API](../../../api/settings.md)を使用します。

{{< /alert >}}

アカウントの削除をスケジュールできます。アカウントを削除すると、削除保留状態になります。通常、削除は1時間以内に行われますが、次のアカウントでは最大7日かかる場合があります:

- コメント、イシュー、マージリクエスト、注記、またはスニペットに関連付けられている
- 有料プランの一部ではない

アカウントが削除保留中の場合:

- アカウントは[ブロック](../../../administration/moderate_users.md#block-a-user)されます。
- 同じユーザー名で新しいアカウントを作成することはできません。
- 最初にメールアドレスを変更しない限り、同じプライマリメールアドレスで新しいアカウントを作成することはできません。

{{< alert type="note" >}}

アカウントが削除された後、任意のユーザーが同じユーザー名でユーザーアカウントを作成できます。別のユーザーがユーザー名を取得した場合、それを取り戻すことはできません。

{{< /alert >}}

自分のアカウントを削除するには:

1. 左側のサイドバーで、自分のアバターを選択します。
1. **プロファイルの編集**を選択します。
1. 左側のサイドバーで、**アカウント**を選択します。
1. **アカウントを削除**を選択します。

GitLab.comでアカウントを削除できない場合は、GitLabからアカウントとデータを削除するための[個人情報リクエスト](https://support.gitlab.io/personal-data-request/)を送信してください。

## ユーザーとユーザーのコントリビュートを削除する {#delete-users-and-user-contributions}

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

前提要件:

- インスタンスの管理者である。

ユーザーを削除するには:

1. 左側のサイドバーの下部で、**管理者**を選択します。
1. **概要** > **ユーザー**を選択します。
1. ユーザーを選択します。
1. **アカウント**タブで、以下を選択します:
   - **ユーザーを削除**を選択して、ユーザーのみを削除し、[関連レコード](#associated-records)を保持します。選択したユーザーが任意のグループの唯一のオーナーである場合、このオプションは使用できません。
   - **ユーザーとコントリビュートを削除**を選択して、ユーザーとそれに関連するレコードを削除します。このオプションでは、ユーザーがグループの唯一の直接のオーナーであるすべてのグループ（およびこれらのグループ内のプロジェクト）も削除されます。継承された所有権は適用されません。

{{< alert type="warning" >}}

**ユーザーとコントリビュートを削除**オプションを使用すると、意図したよりも多くのデータが削除される可能性があります。詳細については、[関連レコード](#associated-records)を参照してください。

{{< /alert >}}

### 関連レコード {#associated-records}

ユーザーを削除するときは、次のいずれかを選択できます:

- ユーザーのみを削除し、コントリビュートをシステム全体の「Ghostユーザー」に移動します:
  - `@ghost`は、削除されたすべてのユーザーのコントリビュートのコンテナとして機能します。
  - ユーザーのプロファイルと個人プロジェクトは、Ghostユーザーに移動される代わりに削除されます。
- ユーザーとそのコントリビュートを完全に削除します:
  - 不正行為レポート。
  - 絵文字リアクション。
  - ユーザーがオーナーロールを持つ唯一のユーザーであるグループ。
  - パーソナルアクセストークン。
  - エピック。
  - イシュー。
  - マージリクエスト。
  - スニペット。
  - 他のユーザーの[コミット](../../project/repository/_index.md#commit-changes-to-a-repository) 、[エピック](../../group/epics/_index.md) 、[イシュー](../../project/issues/_index.md) 、[マージリクエスト](../../project/merge_requests/_index.md) 、[スニペット](../../snippets.md)に関する[注記とコメント](../../../api/notes.md)。

どちらの場合も、コミットは[ユーザー情報](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects#_git_commit_objects)を保持するため、[Gitリポジトリ](../../project/repository/_index.md)内のデータ整合性が維持されます。

削除の代替手段は、[ユーザーをブロックすること](../../../administration/moderate_users.md#block-a-user)です。

ユーザーが[不正行為レポート](../../../administration/review_abuse_reports.md)またはスパムログから削除されると、これらの関連レコードは常に削除されます。

関連レコードの削除オプションは、[API](../../../api/users.md#delete-a-user)と**管理者**エリアでリクエストできます。

{{< alert type="warning" >}}

ユーザーの承認は、ユーザーIDに関連付けられています。他のユーザーのコントリビュートには、関連付けられたユーザーIDがありません。ユーザーを削除し、そのコントリビュートが「Ghostユーザー」に移動されると、承認のコントリビュートは、見つからないか無効なユーザーIDを参照します。ユーザーを削除する代わりに、[ブロックする](../../../administration/moderate_users.md#block-a-user) 、[BANする](../../../administration/moderate_users.md#ban-a-user) 、または[非アクティブ化](../../../administration/moderate_users.md#deactivate-a-user)することを検討してください。

{{< /alert >}}

## GitLab Self-Managedインスタンスでルートアカウントを削除する {#delete-the-root-account-on-a-gitlab-self-managed-instance}

{{< details >}}

- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="warning" >}}

ルートアカウントは、システムで最も特権のあるアカウントです。ルートアカウントを削除すると、インスタンスに他の管理者がいない場合、インスタンスの[**管理者**エリア](../../../administration/admin_area.md)へのアクセスを失う可能性があります。

{{< /alert >}}

UIまたは[GitLab Railsコンソール](../../../administration/operations/rails_console.md)を使用して、ルートアカウントを削除できます。

ルートアカウントを削除する前に:

1. ルートアカウントの[プロジェクト](../../project/settings/project_access_tokens.md)または[パーソナルアクセストークン](../personal_access_tokens.md)を作成し、ワークフローで使用している場合は、ルートアカウントから新しい管理者に、必要な権限または所有権をすべて譲渡します。
1. [GitLab Self-Managedインスタンスをバックアップ](../../../administration/backup_restore/backup_gitlab.md)します。
1. 代わりに、ルートアカウントを[非アクティブ化](../../../administration/moderate_users.md#deactivate-a-user)または[ブロックすること](../../../administration/moderate_users.md#block-and-unblock-users)を検討してください。

### UIを使用する {#use-the-ui}

前提要件: 

- GitLab Self-Managedインスタンスの管理者である必要があります。

ルートアカウントを削除するには:

1. **管理者**エリアで、[管理者アクセス権を持つ新しいユーザーを作成します。](create_accounts.md#create-a-user-in-the-admin-area)これにより、ルートアカウントの削除に関連するリスクを軽減しながら、インスタンスへの管理者アクセスを維持できます。
1. [ルートアカウントを削除](#delete-users-and-user-contributions)します。

### GitLab Railsコンソールを使用します {#use-the-gitlab-rails-console}

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

前提要件: 

- GitLab Railsコンソールにアクセスできる必要があります。

ルートアカウントを削除するには、Railsコンソールで次のようにします:

1. 別の既存のユーザーに管理者アクセス権を付与します:

   ```ruby
   user = User.find(username: 'Username') # or use User.find_by(email: 'email@example.com') to find by email
   user.admin = true
   user.save!
   ```

   これにより、ルートアカウントの削除に関連するリスクを軽減しながら、インスタンスへの管理者アクセスを維持できます。

1. ルートアカウントを削除するには、次のいずれかを実行します:

   - ルートアカウントをブロックします:

     ```ruby
     # This needs to be a current admin user
     current_user = User.find(username: 'Username')

     # This is the root user we want to block
     user = User.find(username: 'Username')

     ::Users::BlockService.new(current_user).execute(user)
     ```

   - ルートユーザーを非アクティブ化します:

     ```ruby
     # This needs to be a current admin user
     current_user = User.find(username: 'Username')

     # This is the root user we want to deactivate
     user = User.find(username: 'Username')

     ::Users::DeactivateService.new(current_user, skip_authorization: true).execute(user)
     ```

## トラブルシューティング {#troubleshooting}

### ユーザーを削除すると、PostgreSQLのNULL値エラーが発生する {#deleting-a-user-results-in-a-postgresql-null-value-error}

ユーザーが削除されず、次のエラーが生成される[既知の問題](https://gitlab.com/gitlab-org/gitlab/-/issues/349411)があります:

```plaintext
ERROR: null value in column "user_id" violates not-null constraint
```

このエラーは、[PostgreSQLログ](../../../administration/logs/_index.md#postgresql-logs)と、**管理者**エリアの[バックグラウンドジョブ](../../../administration/admin_area.md#background-jobs)ビューの**Retries**（再試行）セクションにあります。

削除されるユーザーが[イテレーション](../../group/iterations/_index.md)機能（イシューをイテレーションに追加するなど）を使用していた場合は、[イシューに記載されている回避策](https://gitlab.com/gitlab-org/gitlab/-/issues/349411#workaround)を使用してユーザーを削除する必要があります。
