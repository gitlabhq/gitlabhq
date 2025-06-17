---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Place GitLab into a read-only state
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

The recommended method to place GitLab in a read-only state is to enable
[maintenance mode](maintenance_mode/_index.md).

{{< /alert >}}

In some cases, you might want to place GitLab under a read-only state.
The configuration for doing so depends on your desired outcome.

## Make the repositories read-only

The first thing you want to accomplish is to ensure that no changes can be
made to your repositories. There's two ways you can accomplish that:

- Either stop Puma to make the internal API unreachable:

  ```shell
  sudo gitlab-ctl stop puma
  ```

- Or, open up a Rails console:

  ```shell
  sudo gitlab-rails console
  ```

  And set the repositories for all projects read-only:

  ```ruby
  Project.all.find_each { |project| project.update!(repository_read_only: true) }
  ```

  To set only a subset of repositories to read-only, run the following:

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

  When you're ready to revert this, change `repository_read_only` to `false` on the projects. For example, run the following:

  ```ruby
  Project.all.find_each { |project| project.update!(repository_read_only: false) }
  ```

## Shut down the GitLab UI

If you don't mind shutting down the GitLab UI, then the easiest approach is to
stop `sidekiq` and `puma`, and you effectively ensure that no
changes can be made to GitLab:

```shell
sudo gitlab-ctl stop sidekiq
sudo gitlab-ctl stop puma
```

When you're ready to revert this:

```shell
sudo gitlab-ctl start sidekiq
sudo gitlab-ctl start puma
```

## Make the database read-only

If you want to allow users to use the GitLab UI, ensure that
the database is read-only:

1. Take a [GitLab backup](backup_restore/_index.md)
   in case things don't go as expected.
1. Enter PostgreSQL on the console as an administrator user:

   ```shell
   sudo \
       -u gitlab-psql /opt/gitlab/embedded/bin/psql \
       -h /var/opt/gitlab/postgresql gitlabhq_production
   ```

1. Create the `gitlab_read_only` user. The password is set to `mypassword`,
   change that to your liking:

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

1. Get the hashed password of the `gitlab_read_only` user and copy the result:

   ```shell
   sudo gitlab-ctl pg-password-md5 gitlab_read_only
   ```

1. Edit `/etc/gitlab/gitlab.rb` and add the password from the previous step:

   ```ruby
   postgresql['sql_user_password'] = 'a2e20f823772650f039284619ab6f239'
   postgresql['sql_user'] = "gitlab_read_only"
   ```

1. Reconfigure GitLab and restart PostgreSQL:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart postgresql
   ```

When you're ready to revert the read-only state, remove the added
lines in `/etc/gitlab/gitlab.rb`, and reconfigure GitLab and restart PostgreSQL:

```shell
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart postgresql
```

After you verify all works as expected, remove the `gitlab_read_only`
user from the database.
