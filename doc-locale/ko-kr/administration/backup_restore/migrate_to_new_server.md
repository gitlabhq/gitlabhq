---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 새 서버로 마이그레이션
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

<!-- some details borrowed from GitLab.com move from Azure to GCP detailed at <https://gitlab.com/gitlab-com/migration/-/blob/master/.gitlab/issue_templates/failover.md> -->

GitLab 백업 및 복원을 사용하여 Linux 패키지 인스턴스를 새 서버로 마이그레이션합니다. [Linux 패키지 GitLab 인스턴스를 Docker로 마이그레이션](../../install/docker/migrate.md)할 수도 있습니다.

GitLab Geo를 실행 중인 경우, 다른 옵션으로 [계획된 장애 조치를 위한 Geo 재해 복구](../geo/disaster_recovery/planned_failover.md)가 있습니다. 마이그레이션을 위해 Geo를 선택하기 전에 모든 사이트가 [Geo 요구 사항](../geo/_index.md#requirements-for-running-geo)을 충족하는지 확인해야 합니다.

> [!warning]
> 새 서버와 기존 서버 모두의 조정되지 않은 데이터 처리를 피하세요. 여러 서버가 동시에 연결되어 같은 데이터를 처리할 수 있습니다. 예를 들어 [수신 이메일](../incoming_email.md)을 사용할 때, GitLab 인스턴스 2개가 동시에 이메일을 처리하면 두 인스턴스 모두 일부 데이터를 누락합니다. 이 유형의 문제는 [비패키지 데이터베이스](https://docs.gitlab.com/omnibus/settings/database/#using-a-non-packaged-postgresql-database-management-server), 비패키지 Redis 인스턴스, 또는 비패키지 Sidekiq과 같은 다른 서비스에서도 발생할 수 있습니다.

전제 조건:

- 예정된 마이그레이션에 대해 사용자에게 알리기 위해 미리 게시된 [브로드캐스트 메시지 배너](../broadcast_messages.md)
- 완전하고 최신 백업입니다. 마이그레이션에 관련된 모든 서버의 완전한 시스템 수준 백업을 생성하거나 스냅샷을 만드세요. 파괴적인 명령어(예: `rm`)가 잘못 실행되는 경우를 대비하기 위함입니다.
- 운영자 액세스

## 새 서버 준비 {#prepare-the-new-server}

새 서버를 준비하려면:

1. 기존 서버에서 [SSH 호스트 키](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079)를 복사하여 중간자 공격 경고를 피하세요. 예시 단계는 [기본 사이트의 SSH 호스트 키를 수동으로 복제](../geo/replication/configuration.md#step-2-manually-replicate-the-primary-sites-ssh-host-keys)를 참조하세요.
1. [GitLab 설치](../../install/package/_index.md)
1. 기존 서버에서 새 서버로 `/etc/gitlab` 파일을 복사하여 구성하고, 필요에 따라 업데이트하세요. 자세한 내용은 [Linux 패키지 설치 백업 및 복원 지침](https://docs.gitlab.com/omnibus/settings/backups/)을 참조하세요.
1. 해당하는 경우, [수신 이메일](../incoming_email.md)을 비활성화하세요.
1. 백업 및 복원 후 초기 시작 시 새 CI/CD 작업이 시작되지 않도록 차단하세요. `/etc/gitlab/gitlab.rb`를 편집하고 다음을 설정하세요:

   ```ruby
   nginx['custom_gitlab_server_config'] = "location = /api/v4/jobs/request {\n    deny all;\n    return 503;\n  }\n"
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 불필요한 의도하지 않은 데이터 처리를 피하기 위해 GitLab을 중지하세요:

   ```shell
   sudo gitlab-ctl stop
   ```

1. Redis를 중지하세요:

   ```shell
   sudo gitlab-ctl stop redis
   ```

1. Redis 데이터베이스 및 GitLab 백업 파일을 수신할 수 있도록 새 서버를 구성하세요:

   ```shell
   sudo rm -f /var/opt/gitlab/redis/dump.rdb
   sudo chown <your-linux-username> /var/opt/gitlab/redis /var/opt/gitlab/backups
   ```

## 기존 서버에서 콘텐츠 준비 및 전송 {#prepare-and-transfer-content-from-the-old-server}

1. 기존 서버의 최신 시스템 수준 백업이나 스냅샷이 있는지 확인하세요.
1. [유지 보수 모드](../maintenance_mode/_index.md)를 활성화하세요(GitLab 버전에서 지원하는 경우).
1. 새 CI/CD 작업이 시작되지 않도록 차단하세요:
   1. `/etc/gitlab/gitlab.rb`를 편집하고 다음을 설정하세요:

      ```ruby
      nginx['custom_gitlab_server_config'] = "location = /api/v4/jobs/request {\n    deny all;\n    return 503;\n  }\n"
      ```

   1. GitLab을 재구성합니다:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. 정기적 백그라운드 작업을 비활성화하세요:
   1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
   1. 왼쪽 사이드바에서 **모니터링** > **백그라운드 작업**을 선택하여 Sidekiq 대시보드를 표시합니다.
   1. Sidekiq 대시보드의 상단 메뉴에서 **Cron**을 선택합니다.
   1. Sidekiq 대시보드의 오른쪽 위에서 **Disable All**를 선택합니다.
1. 실행 중인 CI/CD 작업이 완료될 때까지 기다리거나, 완료되지 않은 작업이 손실될 수 있다는 것을 수용하세요. 모든 실행 중인 작업을 보려면:
   1. 왼쪽 사이드바에서 **CI/CD** > **작업**을 선택합니다.
   1. 필터 막대에서 **상태** > **실행중**을 선택합니다.
1. Sidekiq 작업이 완료될 때까지 기다리세요:
   1. 왼쪽 사이드바에서 **모니터링** > **백그라운드 작업**을 선택합니다.
   1. Sidekiq 대시보드의 상단 메뉴에서 **Queues**를 선택합니다.
   1. Sidekiq 대시보드의 오른쪽 위에서 **Live Poll**을 선택합니다. **바쁨**과 **Enqueued**가 0으로 떨어질 때까지 기다리세요. 이러한 큐에는 사용자가 제출한 작업이 포함되어 있으며, 이러한 작업이 완료되기 전에 종료하면 작업이 손실될 수 있습니다. 마이그레이션 후 검증을 위해 Sidekiq 대시보드에 표시된 숫자를 기록해 두세요.
1. Redis 데이터베이스를 디스크에 플러시하고, 마이그레이션에 필요한 서비스를 제외한 GitLab을 중지하세요:

   ```shell
   sudo /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket save && \
   sudo gitlab-ctl stop && \
   sudo gitlab-ctl start postgresql && \
   sudo gitlab-ctl start gitaly
   ```

1. GitLab 백업을 생성합니다:

   ```shell
   sudo gitlab-backup create
   ```

1. 백업이 완료된 후, 다음 GitLab 서비스를 비활성화하고 `/etc/gitlab/gitlab.rb`의 하단에 다음을 추가하여 의도하지 않은 재시작을 방지하세요:

   ```ruby
   alertmanager['enable'] = false
   gitaly['enable'] = false
   gitlab_exporter['enable'] = false
   gitlab_pages['enable'] = false
   gitlab_workhorse['enable'] = false
   grafana['enable'] = false
   logrotate['enable'] = false
   gitlab_rails['incoming_email_enabled'] = false
   nginx['enable'] = false
   node_exporter['enable'] = false
   postgres_exporter['enable'] = false
   postgresql['enable'] = false
   prometheus['enable'] = false
   puma['enable'] = false
   redis['enable'] = false
   redis_exporter['enable'] = false
   registry['enable'] = false
   sidekiq['enable'] = false
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 모든 것이 중지되었는지 확인하고, 서비스가 실행 중이 아님을 확인하세요:

   ```shell
   sudo gitlab-ctl status
   ```

1. Redis 데이터베이스 및 GitLab 백업을 새 서버로 전송하세요:

   ```shell
   sudo scp /var/opt/gitlab/redis/dump.rdb <your-linux-username>@new-server:/var/opt/gitlab/redis
   sudo scp /var/opt/gitlab/backups/your-backup.tar <your-linux-username>@new-server:/var/opt/gitlab/backups
   ```

### Git 및 객체 데이터 볼륨이 큰 인스턴스 {#for-instances-with-a-large-volume-of-git-and-object-data}

GitLab 인스턴스에 로컬 볼륨에 많은 양의 데이터가 있는 경우(예: 1 TB 이상), 백업에 시간이 오래 걸릴 수 있습니다. 이 경우, 데이터를 새 인스턴스의 해당 볼륨으로 전송하는 것이 더 쉬울 수 있습니다.

수동으로 마이그레이션해야 할 수 있는 주요 볼륨은 다음과 같습니다:

- `/var/opt/gitlab/git-data` 디렉터리에는 모든 Git 데이터가 포함되어 있습니다. Git 데이터 손상 가능성을 제거하려면 [리포지토리 이동 설명서 섹션](../operations/moving_repositories.md#migrate-to-another-gitlab-instance)을 반드시 읽으세요.
- `/var/opt/gitlab/gitlab-rails/shared` 디렉터리에는 아티팩트와 같은 객체 데이터가 포함되어 있습니다.
- `/var/opt/gitlab/gitlab-rails/uploads` 디렉터리에는 사용자 프로필 사진과 같은 업로드 데이터가 포함되어 있습니다.
- Linux 패키지에 포함된 번들 PostgreSQL을 사용하는 경우, `/var/opt/gitlab/postgresql/data` 아래의 [PostgreSQL 데이터 디렉터리](https://docs.gitlab.com/omnibus/settings/database/#store-postgresql-data-in-a-different-directory)도 마이그레이션해야 합니다.

모든 GitLab 서비스가 중지된 후, `rsync` 같은 도구를 사용하거나 볼륨 스냅샷을 마운트하여 데이터를 새 환경으로 이동할 수 있습니다.

## 새 서버에서 데이터 복원 {#restore-data-on-the-new-server}

1. 적절한 파일 시스템 권한을 복원합니다:

   ```shell
   sudo chown gitlab-redis /var/opt/gitlab/redis
   sudo chown gitlab-redis:gitlab-redis /var/opt/gitlab/redis/dump.rdb
   sudo chown git:root /var/opt/gitlab/backups
   sudo chown git:git /var/opt/gitlab/backups/your-backup.tar
   ```

1. Redis를 시작합니다:

   ```shell
   sudo gitlab-ctl start redis
   ```

   Redis는 `dump.rdb`을 자동으로 선택하고 복원합니다.

1. [GitLab 백업 복원](restore_gitlab.md)
1. Redis 데이터베이스가 올바르게 복원되었는지 확인합니다:
   1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
   1. 왼쪽 사이드바에서 **모니터링** > **백그라운드 작업**을 선택합니다.
   1. Sidekiq 대시보드에서 숫자가 기존 서버에 표시된 숫자와 일치하는지 확인합니다.
   1. Sidekiq 대시보드에서 계속해서 **Cron**을 선택한 후 **Enable All**를 선택하여 정기적 백그라운드 작업을 다시 활성화합니다.
1. GitLab 인스턴스의 읽기 전용 작업이 예상대로 작동하는지 테스트합니다. 예를 들어, 프로젝트 리포지토리 파일, 머지 리퀘스트, 이슈를 검색합니다.
1. 이전에 활성화된 경우 [유지 보수 모드](../maintenance_mode/_index.md)를 비활성화하세요.
1. GitLab 인스턴스가 예상대로 작동하는지 테스트합니다.
1. 해당하는 경우, [수신 이메일](../incoming_email.md)을 다시 활성화하고 예상대로 작동하는지 테스트하세요.
1. DNS 또는 로드 밸런서를 새 서버를 가리키도록 업데이트합니다.
1. 이전에 추가한 사용자 정의 NGINX 구성을 제거하여 새 CI/CD 작업이 시작되지 않도록 차단 해제하세요:

   ```ruby
   # The following line must be removed
   nginx['custom_gitlab_server_config'] = "location = /api/v4/jobs/request {\n    deny all;\n    return 503;\n  }\n"
   ```

1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. 예약된 유지 보수 [브로드캐스트 메시지 배너](../broadcast_messages.md)를 제거합니다.
