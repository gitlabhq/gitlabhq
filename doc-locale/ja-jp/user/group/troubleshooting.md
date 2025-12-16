---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabグループのトラブルシューティング
---

## ネームスペースとグループの検証エラー {#validation-errors-on-namespaces-and-groups}

ネームスペースまたはグループを作成または更新する際に、次のチェックを実行します:

- ネームスペースに親があってはなりません。
- グループの親はグループでなければならず、ネームスペースであってはなりません。

万一、GitLabのインストールでこれらのエラーが発生した場合は、[サポートにお問い合わせください](https://about.gitlab.com/support/)。この検証を改善することができます。

## SQLクエリを使用してグループを検索する {#find-groups-using-an-sql-query}

[Railsコンソール](../../administration/operations/rails_console.md)でSQLクエリに基づいてグループの配列を検索して保存するには、次のようにします:

```ruby
# Finds groups and subgroups that end with '%oup'
Group.find_by_sql("SELECT * FROM namespaces WHERE name LIKE '%oup'")
=> [#<Group id:3 @test-group>, #<Group id:4 @template-group/template-subgroup>]
```

## Railsコンソールを使用して、サブグループを別の場所に転送する {#transfer-subgroup-to-another-location-using-rails-console}

UIまたはAPI経由でグループの転送がうまくいかない場合は、[Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)で転送を試みてください:

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

```ruby
user = User.find_by_username('<username>')
group = Group.find_by_name("<group_name>")
## Set parent_group = nil to make the subgroup a top-level group
parent_group = Group.find_by(id: "<group_id>")
service = ::Groups::TransferService.new(group, user)
service.execute(parent_group)
```

## Railsコンソールを使用して、削除保留中のグループを検索する {#find-groups-pending-deletion-using-rails-console}

削除保留中のグループをすべて検索する必要がある場合は、[Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)で次のコマンドを使用できます:

```ruby
Group.all.each do |g|
 if g.self_deletion_scheduled?
    puts "Group ID: #{g.id}"
    puts "Group name: #{g.name}"
    puts "Group path: #{g.full_path}"
 end
end
```

## Railsコンソールを使用してグループを削除する {#delete-a-group-using-rails-console}

グループの削除がスタックすることがあります。必要に応じて、[Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)で、次のコマンドを使用してグループの削除を試みることができます:

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

```ruby
GroupDestroyWorker.new.perform(group_id, user_id)
```

## グループまたはプロジェクトに対するユーザーの最大権限を検索する {#find-a-users-maximum-permissions-for-a-group-or-project}

管理者は、グループまたはプロジェクトに対するユーザーの最大権限を検索できます。

1. [Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)を開始します。
1. 次のコマンドを実行します:

   ```ruby
   user = User.find_by_username 'username'
   project = Project.find_by_full_path 'group/project'
   user.max_member_access_for_project project.id
   ```

   ```ruby
   user = User.find_by_username 'username'
   group = Group.find_by_full_path 'group'
   user.max_member_access_for_group group.id
   ```

## バッジ`Project Invite/Group Invite`が付いた請求対象メンバーを削除できません {#unable-to-remove-billable-members-with-badge-project-invitegroup-invite}

次のエラーは通常、ユーザーが[プロジェクト](../project/members/sharing_projects_groups.md)または[グループ](../project/members/sharing_projects_groups.md#invite-a-group-to-a-group)と共有されている外部グループに属している場合に発生します:

<!-- vale gitlab_base.LatinTerms = NO -->
`Members who were invited via a group invitation cannot be removed. You can either remove the entire group, or ask an Owner of the invited group to remove the member.`
<!-- vale gitlab_base.LatinTerms = YES -->

ユーザーを請求対象メンバーとして削除するには、次のいずれかのオプションに従ってください:

- 招待されたグループメンバーシップを、プロジェクトまたはグループのメンバーページから削除します。
- （推奨）グループへのアクセス権がある場合は、招待されたグループからユーザーを直接削除することをお勧めします。

## 権限がないか不十分なため、削除ボタンが無効になっています {#missing-or-insufficient-permission-delete-button-disabled}

このエラーは通常、ユーザーがグループ転送中にアーカイブされたプロジェクトから`container_registry`イメージを削除しようとした場合に発生します。このエラーを解決するには、次の手順に従います:

1. プロジェクトのアーカイブを解除します。
1. `container_registry`イメージを削除します。
1. プロジェクトをアーカイブします。

## グループのオーナーが、`Awaiting user signup`バッジが付いた保留中のユーザーを承認できない {#group-owner-unable-to-approve-pending-users-with-awaiting-user-signup-badge}

GitLab.com以外のユーザーへのメール招待は、`Pending members`の`Awaiting user signup`ステータスで一覧表示されます。ユーザーがGitLab.comに登録すると、ステータスが`Pending owner action`に更新され、グループのオーナーが承認プロセスを完了できます。
