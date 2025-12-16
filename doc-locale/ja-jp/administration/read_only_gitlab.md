---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabを読み取り専用状態にする
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

GitLabを読み取り専用状態にする推奨される方法は、[メンテナンスモード](maintenance_mode/_index.md)を有効にすることです。

{{< /alert >}}

場合によっては、GitLabを読み取り専用状態にすることがあります。そのための設定は、目的の結果によって異なります。

## リポジトリを読み取り専用にする {#make-the-repositories-read-only}

まず、リポジトリに変更を加えることができないようにする必要があります。これを実現するには、2つの方法があります:

- Pumaを停止して、内部APIにアクセスできないようにします:

  ```shell
  sudo gitlab-ctl stop puma
  ```

- または、Railsコンソールを開きます:

  ```shell
  sudo gitlab-rails console
  ```

  そして、すべてのプロジェクトのリポジトリを読み取り専用に設定します:

  ```ruby
  Project.all.find_each { |project| project.update!(repository_read_only: true) }
  ```

  読み取り専用にするリポジトリのサブセットのみを設定するには、次を実行します:

  ```ruby
  # List of project IDs of projects to set to read-only.
  projects = [1,2,3]

  projects.each do |p|
   project =  Project.find p
   project.update!(repository_read_only: true)
   rescue ActiveRecord::RecordNotFound
   puts "Project ID #{p} not found"

  end
  ```

  これを元に戻す準備ができたら、プロジェクトの`repository_read_only`を`false`に変更します。たとえば、次を実行します:

  ```ruby
  Project.all.find_each { |project| project.update!(repository_read_only: false) }
  ```

## GitLab UIをシャットダウンする {#shut-down-the-gitlab-ui}

GitLab UIをシャットダウンしてもかまわない場合は、`sidekiq`と`puma`を停止するのが最も簡単な方法です。これにより、GitLabに変更を加えることができなくなります:

```shell
sudo gitlab-ctl stop sidekiq
sudo gitlab-ctl stop puma
```

これを元に戻す準備ができたら:

```shell
sudo gitlab-ctl start sidekiq
sudo gitlab-ctl start puma
```

## データベースを読み取り専用にする {#make-the-database-read-only}

ユーザーがGitLab UIを使用できるようにする場合は、データベースが読み取り専用であることを確認してください:

1. 予期しない事態に備えて、[GitLabのバックアップ](backup_restore/_index.md)を取ります。
1. 管理者ユーザーとして、コンソールでPostgreSQLに入ります:

   ```shell
   sudo \
       -u gitlab-psql /opt/gitlab/embedded/bin/psql \
       -h /var/opt/gitlab/postgresql gitlabhq_production
   ```

1. `gitlab_read_only`ユーザーを作成します。パスワードは`mypassword`に設定されています。必要に応じて変更してください:

   ```sql
   -- NOTE: Use the password defined earlier
   CREATE USER gitlab_read_only WITH password 'mypassword';
   GRANT CONNECT ON DATABASE gitlabhq_production to gitlab_read_only;
   GRANT USAGE ON SCHEMA public TO gitlab_read_only;
   GRANT SELECT ON ALL TABLES IN SCHEMA public TO gitlab_read_only;
   GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO gitlab_read_only;

   -- Tables created by "gitlab" should be made read-only for "gitlab_read_only"
   -- automatically.
   ALTER DEFAULT PRIVILEGES FOR USER gitlab IN SCHEMA public GRANT SELECT ON TABLES TO gitlab_read_only;
   ALTER DEFAULT PRIVILEGES FOR USER gitlab IN SCHEMA public GRANT SELECT ON SEQUENCES TO gitlab_read_only;
   ```

1. `gitlab_read_only`ユーザーのハッシュ化されたパスワードを取得し、結果をコピーします:

   ```shell
   sudo gitlab-ctl pg-password-md5 gitlab_read_only
   ```

1. `/etc/gitlab/gitlab.rb`を編集し、前の手順のパスワードを追加します:

   ```ruby
   postgresql['sql_user_password'] = 'a2e20f823772650f039284619ab6f239'
   postgresql['sql_user'] = "gitlab_read_only"
   ```

1. GitLabを再構成し、PostgreSQLを再起動します:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart postgresql
   ```

読み取り専用状態を元に戻す準備ができたら、`/etc/gitlab/gitlab.rb`に追加した行を削除し、GitLabを再構成してPostgreSQLを再起動します:

```shell
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart postgresql
```

すべてが期待どおりに動作することを確認したら、データベースから`gitlab_read_only`ユーザーを削除します。
