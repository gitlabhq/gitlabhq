---
stage: Runtime
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: トラブルシューティングプロジェクト
description: 問題解決、一般的な問題、デバッグ、エラー解決。
---

プロジェクトを操作する際、以下の問題が発生したり、特定のタスクを完了するために代替方法が必要になったりする場合があります。

## `An error occurred while fetching commit data` {#an-error-occurred-while-fetching-commit-data}

プロジェクトにアクセスしたときに、ブラウザで広告ブロッカーを使用している場合、`An error occurred while fetching commit data`というメッセージが表示されることがあります。解決策は、アクセスしようとしているGitLabインスタンスの広告ブロッカーを無効にすることです。

## SQLクエリを使用してプロジェクトを検索する {#find-projects-using-an-sql-query}

[Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)で、SQLクエリに基づいてプロジェクトの配列を検索して格納できます:

```ruby
# Finds projects that end with '%ject'
projects = Project.find_by_sql("SELECT * FROM projects WHERE name LIKE '%ject'")
=> [#<Project id:12 root/my-first-project>>, #<Project id:13 root/my-second-project>>]
```

## プロジェクトまたはリポジトリのキャッシュをクリアする {#clear-a-projects-or-repositorys-cache}

プロジェクトまたはリポジトリが更新されたのに、その状態がUIに反映されない場合は、プロジェクトまたはリポジトリのキャッシュをクリアする必要があります。[Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)と、以下のいずれかを使用してこれを行うことができます:

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

```ruby
## Clear project cache
ProjectCacheWorker.perform_async(project.id)

## Clear repository .exists? cache
project.repository.expire_exists_cache
```

## 削除保留中のプロジェクトを検索する {#find-projects-that-are-pending-deletion}

削除対象としてマークされているが、まだ削除されていないすべてのプロジェクトを検索する必要がある場合は、[Railsコンソールセッションを開始](../../administration/operations/rails_console.md#starting-a-rails-console-session)して、以下を実行します:

```ruby
projects = Project.where(pending_delete: true)
projects.each do |p|
  puts "Project ID: #{p.id}"
  puts "Project name: #{p.name}"
  puts "Repository path: #{p.repository.full_path}"
end
```

### コンソールを使用してプロジェクトを転送する {#transfer-a-project-using-console}

UIまたはAPIを介してプロジェクトを転送できない場合は、[Railsコンソールセッション](../../administration/operations/rails_console.md#starting-a-rails-console-session)で転送を試みることができます。

```ruby
p = Project.find_by_full_path('<project_path>')

# To set the owner of the project
current_user = p.creator

# Namespace where you want this to be moved
namespace = Namespace.find_by_full_path("<new_namespace>")

Projects::TransferService.new(p, current_user).execute(namespace)
```

## コンソールを使用してプロジェクトを削除する {#delete-a-project-using-console}

プロジェクトを削除できない場合は、[Railsコンソール](../../administration/operations/rails_console.md#starting-a-rails-console-session)を使用して削除を試みることができます。

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

```ruby
project = Project.find_by_full_path('<project_path>')
user = User.find_by_username('<username>')
Projects::DestroyService.new(project, user, {}).execute
```

これが失敗した場合は、次のコマンドでその理由を表示します:

```ruby
project = Project.find_by_full_path('<project_path>')
project.delete_error
```

## グループ内のすべてのプロジェクトの機能を切替する {#toggle-a-feature-for-all-projects-within-a-group}

プロジェクトの機能の切替は、[projects API](../../api/projects.md)を介して行うことができますが、多数のプロジェクトでこれを行う必要がある場合があります。

特定の機能を切替するには、[Railsコンソールセッションを開始](../../administration/operations/rails_console.md#starting-a-rails-console-session)して、次の関数を実行します:

{{< alert type="warning" >}}

データを変更するコマンドは、正しく実行されなかった場合、または適切な条件下で実行されなかった場合、損害を与える可能性があります。最初にテスト環境でコマンドを実行し、復元できるバックアップインスタンスを準備してください。

{{< /alert >}}

```ruby
projects = Group.find_by_name('_group_name').projects
projects.each do |p|
  ## replace <feature-name> with the appropriate feature name in all instances
  state = p.<feature-name>

  if state != 0
    puts "#{p.name} has <feature-name> already enabled. Skipping..."
  else
    puts "#{p.name} didn't have <feature-name> enabled. Enabling..."
    p.project_feature.update!(<feature-name>: ProjectFeature::PRIVATE)
  end
end
```

切替可能な機能を見つけるには、`pp p.project_feature`を実行します。使用可能な権限レベルは、[concerns/featurable.rb](https://gitlab.com/gitlab-org/gitlab/blob/master/app/models/concerns/featurable.rb)にリストされています。
