---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab을 읽기 전용 상태로 변경하기
description: GitLab을 읽기 전용 상태로 변경합니다.
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

> [!note]
> GitLab을 읽기 전용 상태로 변경하는 권장 방법은 [유지 관리 모드](maintenance_mode/_index.md)를 활성화하는 것입니다.

경우에 따라 GitLab을 읽기 전용 상태로 변경하고 싶을 수 있습니다. 이를 위한 구성은 원하는 결과에 따라 달라집니다.

## 리포지토리를 읽기 전용으로 변경하기 {#make-the-repositories-read-only}

먼저 리포지토리에 변경할 수 없도록 해야 합니다. 이를 수행할 수 있는 방법은 두 가지입니다:

- Puma를 중지하여 내부 API에 접근할 수 없도록 합니다:

  ```shell
  sudo gitlab-ctl stop puma
  ```

- 또는 Rails 콘솔을 엽니다:

  ```shell
  sudo gitlab-rails console
  ```

  모든 프로젝트의 리포지토리를 읽기 전용으로 설정합니다:

  ```ruby
  Project.all.find_each { |project| project.update!(repository_read_only: true) }
  ```

  리포지토리의 일부만 읽기 전용으로 설정하려면 다음을 실행하세요:

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

  이를 되돌릴 준비가 되면 프로젝트에서 `repository_read_only`을 `false`로 변경하세요. 예를 들어 다음을 실행하세요:

  ```ruby
  Project.all.find_each { |project| project.update!(repository_read_only: false) }
  ```

## GitLab UI 종료하기 {#shut-down-the-gitlab-ui}

GitLab UI를 종료해도 괜찮다면 `sidekiq`과 `puma`를 중지하는 것이 가장 쉬운 방법이며, 이를 통해 GitLab에 변경할 수 없도록 효과적으로 보장할 수 있습니다:

```shell
sudo gitlab-ctl stop sidekiq
sudo gitlab-ctl stop puma
```

이를 되돌릴 준비가 되면 다음을 실행하세요:

```shell
sudo gitlab-ctl start sidekiq
sudo gitlab-ctl start puma
```

## 데이터베이스를 읽기 전용으로 변경하기 {#make-the-database-read-only}

사용자가 GitLab UI를 사용할 수 있도록 하려면 데이터베이스가 읽기 전용인지 확인하세요:

1. 문제가 발생할 경우를 대비하여 [GitLab 백업](backup_restore/_index.md)을 수행하세요.
1. 관리자 사용자로 콘솔에서 PostgreSQL에 접속하세요:

   ```shell
   sudo \
       -u gitlab-psql /opt/gitlab/embedded/bin/psql \
       -h /var/opt/gitlab/postgresql gitlabhq_production
   ```

1. `gitlab_read_only` 사용자를 생성합니다. 비밀번호는 `mypassword`로 설정되며, 원하는 대로 변경하세요:

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

1. `gitlab_read_only` 사용자의 해시된 비밀번호를 가져오고 결과를 복사하세요:

   ```shell
   sudo gitlab-ctl pg-password-md5 gitlab_read_only
   ```

1. `/etc/gitlab/gitlab.rb`을 편집하고 이전 단계의 비밀번호를 추가하세요:

   ```ruby
   postgresql['sql_user_password'] = 'a2e20f823772650f039284619ab6f239'
   postgresql['sql_user'] = "gitlab_read_only"
   ```

1. GitLab을 재구성하고 PostgreSQL을 다시 시작하세요:

   ```shell
   sudo gitlab-ctl reconfigure
   sudo gitlab-ctl restart postgresql
   ```

읽기 전용 상태를 되돌릴 준비가 되면 `/etc/gitlab/gitlab.rb`에서 추가된 줄을 제거하고 GitLab을 재구성한 다음 PostgreSQL을 다시 시작하세요:

```shell
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart postgresql
```

모든 것이 예상대로 작동하는지 확인한 후 데이터베이스에서 `gitlab_read_only` 사용자를 제거하세요.
