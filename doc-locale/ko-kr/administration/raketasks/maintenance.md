---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 유지보수 Rake 작업
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 일반 유지보수를 위한 Rake 작업을 제공합니다.

## GitLab 및 시스템 정보 수집 {#gather-gitlab-and-system-information}

이 명령은 GitLab 설치 및 실행 중인 시스템에 대한 정보를 수집합니다. 도움을 요청하거나 문제를 보고할 때 유용할 수 있습니다. 다중 노드 환경에서는 PostgreSQL 소켓 오류를 피하기 위해 GitLab Rails을 실행하는 노드에서 이 명령을 실행합니다.

- Linux 패키지 설치:

  ```shell
  sudo gitlab-rake gitlab:env:info
  ```

- 자체 컴파일된 설치:

  ```shell
  bundle exec rake gitlab:env:info RAILS_ENV=production
  ```

출력 예:

```plaintext
System information
System:         Ubuntu 20.04
Proxy:          no
Current User:   git
Using RVM:      no
Ruby Version:   2.7.6p219
Gem Version:    3.1.6
Bundler Version:2.3.15
Rake Version:   13.0.6
Redis Version:  6.2.7
Sidekiq Version:6.4.2
Go Version:     unknown

GitLab information
Version:        15.5.5-ee
Revision:       5f5109f142d
Directory:      /opt/gitlab/embedded/service/gitlab-rails
DB Adapter:     PostgreSQL
DB Version:     13.8
URL:            https://app.gitaly.gcp.gitlabsandbox.net
HTTP Clone URL: https://app.gitaly.gcp.gitlabsandbox.net/some-group/some-project.git
SSH Clone URL:  git@app.gitaly.gcp.gitlabsandbox.net:some-group/some-project.git
Elasticsearch:  no
Geo:            no
Using LDAP:     no
Using Omniauth: yes
Omniauth Providers:

GitLab Shell
Version:        14.12.0
Repository storage paths:
- default:      /var/opt/gitlab/git-data/repositories
- gitaly:       /var/opt/gitlab/git-data/repositories
GitLab Shell path:              /opt/gitlab/embedded/service/gitlab-shell


Gitaly
- default Address:      unix:/var/opt/gitlab/gitaly/gitaly.socket
- default Version:      15.5.5
- default Git Version:  2.37.1.gl1
- gitaly Address:       tcp://10.128.20.6:2305
- gitaly Version:       15.5.5
- gitaly Git Version:   2.37.1.gl1
```

## GitLab 라이선스 정보 표시 {#show-gitlab-license-information}

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

이 명령은 [GitLab 라이선스](../license.md)에 대한 정보 및 사용 중인 사용자 수를 표시합니다. 이는 GitLab Enterprise 설치에서만 사용할 수 있습니다. GitLab Community Edition에는 라이선스를 설치할 수 없습니다.

이는 Support에 티켓을 제출할 때 또는 라이선스 매개변수를 프로그래매틱 방식으로 확인할 때 유용할 수 있습니다.

- Linux 패키지 설치:

  ```shell
  sudo gitlab-rake gitlab:license:info
  ```

- 자체 컴파일된 설치:

  ```shell
  bundle exec rake gitlab:license:info RAILS_ENV=production
  ```

출력 예:

```plaintext
Today's Date: 2020-02-29
Current User Count: 30
Max Historical Count: 30
Max Users in License: 40
License valid from: 2019-11-29 to 2020-11-28
Email associated with license: user@example.com
```

## GitLab 구성 확인 {#check-gitlab-configuration}

`gitlab:check` Rake 작업은 다음 Rake 작업을 실행합니다:

- `gitlab:gitlab_shell:check`
- `gitlab:gitaly:check`
- `gitlab:sidekiq:check`
- `gitlab:incoming_email:check`
- `gitlab:ldap:check`
- `gitlab:app:check`
- `gitlab:geo:check` ([Geo](../geo/replication/troubleshooting/common.md#health-check-rake-task)를 실행하는 경우에만)

각 구성 요소가 설치 가이드에 따라 설정되었는지 확인하고 발견된 문제에 대한 해결 방법을 제안합니다. 이 명령은 애플리케이션 서버에서 실행해야 하며 [Gitaly](../gitaly/configure_gitaly.md#run-gitaly-on-its-own-server)와 같은 구성 요소 서버에서는 올바르게 작동하지 않습니다.

또한 다음 문제 해결 가이드를 확인할 수 있습니다:

- [GitLab](../troubleshooting/_index.md).
- [Linux 패키지 설치](https://docs.gitlab.com/omnibus/#troubleshooting).

또한 [현재 비밀을 사용하여 데이터베이스 값을 해독할 수 있는지 확인](check.md#verify-database-values-can-be-decrypted-using-the-current-secrets)해야 합니다.

`gitlab:check`을 실행하려면:

- Linux 패키지 설치:

  ```shell
  sudo gitlab-rake gitlab:check
  ```

- 자체 컴파일된 설치:

  ```shell
  bundle exec rake gitlab:check RAILS_ENV=production
  ```

- Kubernetes 설치:

  ```shell
  kubectl exec -it <toolbox-pod-name> -- sudo gitlab-rake gitlab:check
  ```

  > [!note]
  > Helm 기반 GitLab 설치의 특정 아키텍처로 인해 `gitlab-shell`, Sidekiq 및 `systemd`관련 파일에 대한 연결 확인에 거짓 음성이 포함될 수 있습니다. 이 보고된 오류는 예상되었으며 실제 문제를 나타내지 않으므로 진단 결과를 검토할 때 무시합니다.

`SANITIZE=true`을 `gitlab:check`에 사용하여 출력에서 프로젝트 이름을 생략하려면:

출력 예:

```plaintext
Checking Environment ...

Git configured for git user? ... yes
Has python2? ... yes
python2 is supported version? ... yes

Checking Environment ... Finished

Checking GitLab Shell ...

GitLab Shell version? ... OK (1.2.0)
Repo base directory exists? ... yes
Repo base directory is a symlink? ... no
Repo base owned by git:git? ... yes
Repo base access is drwxrws---? ... yes
post-receive hook up-to-date? ... yes
post-receive hooks in repos are links: ... yes

Checking GitLab Shell ... Finished

Checking Sidekiq ...

Running? ... yes

Checking Sidekiq ... Finished

Checking GitLab App...

Database config exists? ... yes
Database is SQLite ... no
All migrations up? ... yes
GitLab config exists? ... yes
GitLab config up to date? ... no
Cable config exists? ... yes
Resque config exists? ... yes
Log directory writable? ... yes
Tmp directory writable? ... yes
Init script exists? ... yes
Init script up-to-date? ... yes
Redis version >= 2.0.0? ... yes

Checking GitLab ... Finished
```

## `authorized_keys` 파일 재구성 {#rebuild-authorized_keys-file}

경우에 따라 `authorized_keys` 파일을 재구성해야 합니다. 예를 들어, 업그레이드 후 [SSH를 통해](../../user/ssh.md) 푸시할 때 `Permission denied (publickey)`가 표시되고 [`gitlab-shell.log` 파일](../logs/_index.md#gitlab-shelllog)에서 `404 Key Not Found` 오류가 발견됩니다. `authorized_keys`을 재구성하려면:

- Linux 패키지 설치:

  ```shell
  sudo gitlab-rake gitlab:shell:setup
  ```

- 자체 컴파일된 설치:

  ```shell
  cd /home/git/gitlab
  sudo -u git -H bundle exec rake gitlab:shell:setup RAILS_ENV=production
  ```

출력 예:

```plaintext
This will rebuild an authorized_keys file.
You will lose any data stored in authorized_keys file.
Do you want to continue (yes/no)? yes
```

## Redis 캐시 지우기 {#clear-redis-cache}

어떤 이유로든 대시보드에 잘못된 정보가 표시되면 Redis 캐시를 지울 수 있습니다. 이를 수행하려면:

- Linux 패키지 설치:

  ```shell
  sudo gitlab-rake cache:clear
  ```

- 자체 컴파일된 설치:

  ```shell
  cd /home/git/gitlab
  sudo -u git -H bundle exec rake cache:clear RAILS_ENV=production
  ```

## 자산 사전 컴파일 {#precompile-the-assets}

버전 업그레이드 중에 일부 CSS가 잘못되거나 아이콘이 누락될 수 있습니다. 이 경우 자산을 다시 사전 컴파일해 봅니다.

이 Rake 작업은 자체 컴파일 설치에만 적용됩니다. Linux 패키지를 실행할 때 이 문제를 해결하는 방법에 대해 [자세히 알아보기](../../update/package/package_troubleshooting.md#missing-asset-files)입니다. Linux 패키지에 대한 지침은 GitLab의 Kubernetes 및 Docker 배포에 적용될 수 있지만 일반적으로 컨테이너 기반 설치에서는 누락된 자산 문제가 없습니다.

- 자체 컴파일된 설치:

  ```shell
  cd /home/git/gitlab
  sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production
  ```

Linux 패키지 설치의 경우 최적화되지 않은 자산(JavaScript, CSS)은 업스트림 GitLab 릴리스에서 고정됩니다. Linux 패키지 설치에는 이러한 자산의 최적화된 버전이 포함됩니다. 패키지 설치 후 프로덕션 머신에서 JavaScript / CSS 코드를 수정하지 않는 한, 프로덕션 머신에서 `rake gitlab:assets:compile`을 다시 수행할 이유가 없습니다. 자산이 손상되었다고 의심되면 Linux 패키지를 다시 설치해야 합니다.

## 원격 사이트에 대한 TCP 연결 확인 {#check-tcp-connectivity-to-a-remote-site}

GitLab 설치가 다른 머신의 TCP 서비스(예: PostgreSQL 또는 웹 서버)에 연결할 수 있는지 알아야 할 경우 프록시 문제를 해결할 수 있습니다. Rake 작업이 이를 도와드리기 위해 포함됩니다.

- Linux 패키지 설치:

  ```shell
  sudo gitlab-rake gitlab:tcp_check[example.com,80]
  ```

- 자체 컴파일된 설치:

  ```shell
  cd /home/git/gitlab
  sudo -u git -H bundle exec rake gitlab:tcp_check[example.com,80] RAILS_ENV=production
  ```

## 배타적 임차료 지우기(위험) {#clear-exclusive-lease-danger}

GitLab은 공유 리소스에서 동시 작업을 방지하기 위해 공유 잠금 메커니즘을 사용합니다: `ExclusiveLease`. 예를 들어 리포지토리에서 정기적인 가비지 수집을 실행합니다.

매우 특정한 상황에서 배타적 임차료에 의해 잠긴 작업이 잠금을 해제하지 않고 실패할 수 있습니다. 만료될 때까지 기다릴 수 없으면 이 작업을 실행하여 수동으로 지울 수 있습니다.

모든 배타적 임차료를 지우려면:

> [!warning]
> GitLab 또는 Sidekiq이 실행 중인 동안 이 명령을 실행하지 마세요.

```shell
sudo gitlab-rake gitlab:exclusive_lease:clear
```

임차료 `type` 또는 임차료 `type + id`를 지정하려면 범위를 지정합니다:

```shell
# to clear all leases for repository garbage collection:
sudo gitlab-rake gitlab:exclusive_lease:clear[project_housekeeping:*]

# to clear a lease for repository garbage collection in a specific project: (id=4)
sudo gitlab-rake gitlab:exclusive_lease:clear[project_housekeeping:4]
```

## 데이터베이스 마이그레이션 상태 표시 {#display-status-of-database-migrations}

GitLab을 업그레이드할 때 마이그레이션이 완료되었는지 확인하는 방법을 알아보려면 [배경 마이그레이션 설명서](../../update/background_migrations.md)를 참조하세요.

특정 마이그레이션의 상태를 확인하려면 다음 Rake 작업을 사용할 수 있습니다:

```shell
sudo gitlab-rake db:migrate:status
```

[Geo 보조 사이트의 추적 데이터베이스](../geo/setup/external_database.md#configure-the-tracking-database)를 확인하려면 다음 Rake 작업을 사용할 수 있습니다:

```shell
sudo gitlab-rake db:migrate:status:geo
```

이는 각 마이그레이션에 대해 `Status`이 `up` 또는 `down`인 표를 출력합니다. 예:

```shell
database: gitlabhq_production

 Status   Migration ID    Type     Milestone    Name
--------------------------------------------------
   up     20240701074848  regular  17.2         AddGroupIdToPackagesDebianGroupComponents
   up     20240701153843  regular  17.2         AddWorkItemsDatesSourcesSyncToIssuesTrigger
   up     20240702072515  regular  17.2         AddGroupIdToPackagesDebianGroupArchitectures
   up     20240702133021  regular  17.2         AddWorkspaceTerminationTimeoutsToRemoteDevelopmentAgentConfigs
   up     20240604064938  post     17.2         FinalizeBackfillPartitionIdCiPipelineMessage
   up     20240604111157  post     17.2         AddApprovalPolicyRulesFkOnApprovalGroupRules
```

GitLab 17.1부터 마이그레이션은 GitLab 릴리스 주기를 준수하는 순서로 실행됩니다.

## 완료되지 않은 데이터베이스 마이그레이션 실행 {#run-incomplete-database-migrations}

데이터베이스 마이그레이션은 불완전한 상태로 고착될 수 있으며 `down` 명령 출력에 `sudo gitlab-rake db:migrate:status` 상태가 있습니다.

1. 이러한 마이그레이션을 완료하려면 다음 Rake 작업을 사용합니다:

   ```shell
   sudo gitlab-rake db:migrate
   ```

1. 명령이 완료되면 `sudo gitlab-rake db:migrate:status`을 실행하여 모든 마이그레이션이 완료되었는지(`up` 상태) 확인합니다.
1. `puma` 및 `sidekiq` 서비스를 핫 다시 로드합니다:

   ```shell
   sudo gitlab-ctl hup puma
   sudo gitlab-ctl restart sidekiq
   ```

GitLab 17.1부터 마이그레이션은 GitLab 릴리스 주기를 준수하는 순서로 실행됩니다.

## 데이터베이스 인덱스 재구성 {#rebuild-database-indexes}

{{< history >}}

- GitLab 13.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/42705) 됨 [플래그](../feature_flags/_index.md) 이름: `database_reindexing`. 기본적으로 비활성화됨.
- GitLab 13.9에서 [GitLab.com에서 활성화](https://gitlab.com/groups/gitlab-org/-/epics/3989)됨.
- GitLab 18.0에서 [GitLab Self-Managed 및 GitLab Dedicated에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188548)됨.

{{< /history >}}

> [!warning]
> 프로덕션 환경에서 실행할 때 주의하여 사용하고 피크 시간 외에 실행합니다.

데이터베이스 인덱스는 정기적으로 재구성하여 공간을 확보하고 시간이 지남에 따라 건강한 인덱스 bloat 수준을 유지할 수 있습니다. 재인덱싱은 [일반 cron 작업](https://docs.gitlab.com/omnibus/settings/database/#automatic-database-reindexing)으로도 실행할 수 있습니다. "건강한" bloat 수준은 특정 인덱스에 따라 크게 달라지지만 일반적으로 30% 미만이어야 합니다.

데이터베이스 재인덱싱은 다음 작업을 수행합니다:

1. 수동으로 대기열에 추가된 PostgreSQL 인덱스를 재인덱싱합니다:  인덱스를 수동으로 재인덱싱할 대기열에 추가할 수 있습니다. PostgreSQL 인덱스를 재인덱싱하면 일반적으로 [인덱스 bloat](https://wiki.postgresql.org/wiki/Index_Maintenance#Index_Bloat)이 감소합니다.
1. [인덱스 bloat](https://wiki.postgresql.org/wiki/Index_Maintenance#Index_Bloat) 휴리스틱을 사용하여 자동으로 PostgreSQL 인덱스를 재인덱싱합니다:  PostgreSQL은 휴리스틱을 사용하여 가장 bloated 인덱스를 식별합니다. 프로세스는 각 실행 중에 최대 2개의 인덱스를 선택하여 재인덱싱합니다.

전제 조건:

- 이 기능을 사용하려면 PostgreSQL 12 이상이 필요합니다.
- 이러한 인덱스 유형은 **not supported**: 표현식 인덱스 및 제약 조건 제외에 사용되는 인덱스.

### 재인덱싱 실행 {#run-reindexing}

다음 작업은 각 데이터베이스에서 bloat이 가장 높은 두 개의 인덱스만 재구성합니다. 두 개 이상의 인덱스를 재구성하려면 모든 원하는 인덱스가 재구성될 때까지 작업을 다시 실행합니다.

1. 재인덱싱 작업을 실행합니다:

   ```shell
   sudo gitlab-rake gitlab:db:reindex
   ```

1. [`application_json.log`](../logs/_index.md#application_jsonlog)를 확인하여 실행을 검증하거나 문제를 해결합니다.

CloudNative 설치에서 [Toolbox 차트](https://docs.gitlab.com/charts/charts/gitlab/toolbox/#configure-periodic-database-reindexing)를 사용하여 이 작업을 실행할 때 로그는 Pod의 표준 출력에 있습니다.

### 재인덱싱 설정 사용자 정의 {#customize-reindexing-settings}

더 작은 인스턴스의 경우 또는 재인덱싱 동작을 조정하려면 Rails 콘솔을 사용하여 이러한 설정을 수정할 수 있습니다:

```shell
sudo gitlab-rails console
```

그런 다음 구성을 사용자 정의합니다:

```ruby
# Lower minimum index size to 100 MB (default is 1 GB)
Gitlab::Database::Reindexing.minimum_index_size!(100.megabytes)

# Change minimum bloat threshold to 30% (default is 20%, there is no benefit from setting it lower)
Gitlab::Database::Reindexing.minimum_relative_bloat_size!(0.3)
```

### 자동화된 재인덱싱 {#automated-reindexing}

더 큰 인스턴스의 경우 활동이 적은 기간 동안 실행되도록 예약하여 데이터베이스 재인덱싱을 자동화합니다.

#### crontab으로 예약 {#schedule-with-crontab}

패키지된 GitLab 설치의 경우 crontab을 사용합니다:

1. crontab을 편집합니다:

   ```shell
   sudo crontab -e
   ```

1. 선호하는 일정에 따라 항목을 추가합니다:

   1. 옵션 1:  조용한 시간 동안 매일 실행

   ```shell
   # Run database reindexing every day at 21:12
   # The log will be rotated by the packaged logrotate daemon
   12 21 * * * /opt/gitlab/bin/gitlab-rake gitlab:db:reindex >> /var/log/gitlab/gitlab-rails/cron_reindex.log 2>&1
   ```

   1. 옵션 2:  주말만 실행

   ```shell
   # Run database reindexing at 01:00 AM on weekends
   0 1 * * 0,6 /opt/gitlab/bin/gitlab-rake gitlab:db:reindex >> /var/log/gitlab/gitlab-rails/cron_reindex.log 2>&1
   ```

   1. 옵션 3:  트래픽이 적은 시간에 자주 실행

   ```shell
   # Run database reindexing every 3 hours during night hours (22:00-07:00)
   0 22,1,4,7 * * * /opt/gitlab/bin/gitlab-rake gitlab:db:reindex >> /var/log/gitlab/gitlab-rails/cron_reindex.log 2>&1
   ```

Kubernetes 배포의 경우 CronJob 리소스를 사용하여 재인덱싱 작업을 실행하는 유사한 일정을 만들 수 있습니다.

### 참고 {#notes}

- 데이터베이스 인덱스 재구성은 디스크 집약적인 작업이므로 피크 시간 외에 작업을 수행해야 합니다. 피크 시간에 작업을 실행하면 bloat이 증가할 수 있으며 특정 쿼리의 성능이 저하될 수도 있습니다.
- 작업을 위해 복원할 인덱스의 여유 디스크 공간이 필요합니다. 생성된 인덱스는 `_ccnew`와 함께 추가됩니다. 재인덱싱 작업이 실패하면 작업을 다시 실행하면 임시 인덱스가 정리됩니다.
- 데이터베이스 인덱스 재구성을 완료하는 데 걸리는 시간은 대상 데이터베이스의 크기에 따라 달라집니다. 몇 시간에서 며칠까지 걸릴 수 있습니다.
- 작업은 Redis 잠금을 사용하므로 자주 실행하도록 예약하기에 안전합니다. 다른 재인덱싱 작업이 이미 실행 중인 경우 작동하지 않습니다.

## 데이터베이스 스키마 덤프 {#dump-the-database-schema}

드문 경우이지만 모든 데이터베이스 마이그레이션이 완료된 경우에도 데이터베이스 스키마가 애플리케이션 코드에서 예상하는 것과 다를 수 있습니다. 이 경우 GitLab에서 이상한 오류가 발생할 수 있습니다.

데이터베이스 스키마를 덤프하려면:

```shell
SCHEMA=/tmp/structure.sql gitlab-rake db:schema:dump
```

Rake 작업은 데이터베이스 스키마 덤프가 포함된 `/tmp/structure.sql` 파일을 만듭니다.

차이가 있는지 확인하려면:

1. [`db/structure.sql`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/db/structure.sql) 파일로 [`gitlab`](https://gitlab.com/gitlab-org/gitlab) 프로젝트에서 이동합니다. GitLab 버전과 일치하는 브랜치를 선택합니다. 예를 들어 GitLab 16.2의 경우: <https://gitlab.com/gitlab-org/gitlab/-/blob/16-2-stable-ee/db/structure.sql>.
1. `/tmp/structure.sql`을 버전의 `db/structure.sql` 파일과 비교합니다.

## 스키마 불일치에 대한 데이터베이스 확인 {#check-the-database-for-schema-inconsistencies}

{{< history >}}

- GitLab 15.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/390719)됨.

{{< /history >}}

이 Rake 작업은 데이터베이스 스키마에서 불일치를 확인하고 터미널에 출력합니다. 이 작업은 GitLab Support의 지침 하에 사용할 진단 도구입니다. 데이터베이스 불일치가 예상될 수 있으므로 일반적인 확인에는 이 작업을 사용하면 안 됩니다.

```shell
gitlab-rake gitlab:db:schema_checker:run
```

## 데이터베이스에 대한 정보 및 통계 수집 {#collect-information-and-statistics-about-the-database}

{{< history >}}

- GitLab 17.11에서 [도입](https://gitlab.com/groups/gitlab-com/-/epics/2456)됨.

{{< /history >}}

`gitlab:db:sos` 명령은 문제를 해결하는 데 도움이 되도록 GitLab 데이터베이스에 대한 구성, 성능 및 진단 데이터를 수집합니다. 이 명령을 실행할 위치는 구성에 따라 달라집니다. GitLab이 설치된 위치 `(/gitlab)`에 상대적으로 이 명령을 실행해야 합니다.

- **Scaled GitLab**: Puma 또는 Sidekiq 서버에서.
- **Cloud native install**: toolbox pod에서.
- **All other configurations**: GitLab 서버에서.

필요에 따라 명령을 수정합니다:

- **Default path** \- 기본 파일 경로(`/var/opt/gitlab/gitlab-rails/tmp/sos.zip`)로 명령을 실행하려면 `gitlab-rake gitlab:db:sos`을 실행합니다.
- **Custom path** \- 파일 경로를 변경하려면 `gitlab-rake gitlab:db:sos["/absolute/custom/path/to/file.zip"]`을 실행합니다.
- **Zsh users** \- Zsh 구성을 수정하지 않았다면 다음과 같이 전체 명령 주위에 따옴표를 추가해야 합니다: `gitlab-rake "gitlab:db:sos[/absolute/custom/path/to/file.zip]"`

Rake 작업은 5분 동안 실행됩니다. 지정한 경로에 압축된 폴더를 만듭니다. 압축된 폴더에는 많은 수의 파일이 포함됩니다.

### 선택적 쿼리 통계 데이터 활성화 {#enable-optional-query-statistics-data}

`gitlab:db:sos` Rake 작업은 [`pg_stat_statements` 확장](https://www.postgresql.org/docs/16/pgstatstatements.html)을 사용하여 느린 쿼리를 문제 해결하기 위한 데이터를 수집할 수도 있습니다.

이 확장을 활성화하는 것은 선택 사항이며 PostgreSQL 및 GitLab을 다시 시작해야 합니다. 이 데이터는 느린 데이터베이스 쿼리로 인한 GitLab 성능 문제를 해결하는 데 필요할 수 있습니다.

전제 조건:

- 확장을 활성화하거나 비활성화하려면 슈퍼유저 권한이 있는 PostgreSQL 사용자여야 합니다.

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

1. 다음 줄을 추가하려면 `/etc/gitlab/gitlab.rb`을 수정합니다:

   ```ruby
   postgresql['shared_preload_libraries'] = 'pg_stat_statements'
   ```

1. 재구성 실행:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. PostgreSQL은 이 확장을 로드하기 위해 다시 시작해야 하므로 GitLab도 다시 시작해야 합니다:

   ```shell
   sudo gitlab-ctl restart postgresql
   sudo gitlab-ctl restart sidekiq
   sudo gitlab-ctl restart puma
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. 다음 줄을 추가하려면 `/etc/gitlab/gitlab.rb`을 수정합니다:

   ```ruby
   postgresql['shared_preload_libraries'] = 'pg_stat_statements'
   ```

1. 재구성 실행:

   ```shell
   docker exec -it <container-id> gitlab-ctl reconfigure
   ```

1. PostgreSQL은 이 확장을 로드하기 위해 다시 시작해야 하므로 GitLab도 다시 시작해야 합니다:

   ```shell
   docker exec -it <container-id> gitlab-ctl restart postgresql
   docker exec -it <container-id> gitlab-ctl restart sidekiq
   docker exec -it <container-id> gitlab-ctl restart puma
   ```

{{< /tab >}}

{{< tab title="외부 PostgreSQL 서비스" >}}

1. `postgresql.conf` 파일에서 다음 매개변수를 추가하거나 주석을 해제합니다.

   ```shell
   shared_preload_libraries = 'pg_stat_statements'
   pg_stat_statements.track = all
   ```

1. 변경 사항이 적용되려면 PostgreSQL을 다시 시작합니다.
1. GitLab을 다시 시작합니다: 웹(Puma) 및 Sidekiq 서비스를 다시 시작해야 합니다.

{{< /tab >}}

{{< /tabs >}}

1. [데이터베이스 콘솔](../troubleshooting/postgresql.md)에서 실행:

   ```SQL
   CREATE EXTENSION pg_stat_statements;
   ```

1. 확장이 작동하는지 확인합니다:

   ```SQL
   SELECT extname FROM pg_extension WHERE extname = 'pg_stat_statements';
   SELECT * FROM pg_stat_statements LIMIT 10;
   ```

## 중복 CI/CD 태그의 데이터베이스 확인 {#check-the-database-for-duplicate-cicd-tags}

{{< history >}}

- GitLab 17.10에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/518698)됨.

{{< /history >}}

이 Rake 작업은 `ci` 데이터베이스에서 `tags` 테이블의 중복 태그를 확인합니다. 이 문제는 오랜 기간에 걸쳐 여러 주요 업그레이드를 거친 인스턴스에 영향을 줄 수 있습니다. 다음 명령을 실행하여 중복 태그를 검색한 후, 중복 태그를 참조하는 태그 할당을 원본 태그를 사용하도록 다시 작성합니다.

```shell
sudo gitlab-rake gitlab:db:deduplicate_tags
```

이 명령을 드라이 실행 모드로 실행하려면 환경 변수 `DRY_RUN=true`을 설정합니다.

## PostgreSQL 대조 버전 불일치 감지 {#detect-postgresql-collation-version-mismatches}

{{< history >}}

- GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195450)됨.
- 손상의 사전 정의된 인덱스 집합의 지점 확인 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198071) GitLab 18.3.
- `MAX_TABLE_SIZE`을 사용자 정의하고 PgBouncer를 우회하는 옵션 GitLab 18.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/202736).

{{< /history >}}

PostgreSQL 대조 확인:

- 인덱스 손상을 유발할 수 있는 데이터베이스와 운영 체제 간의 대조 버전 불일치를 감지합니다. PostgreSQL은 문자열 대조(정렬 및 비교 규칙)를 위해 운영 체제의 `glibc` 라이브러리를 사용합니다.
- 사전 정의된 인덱스 집합에서 손상 지점 확인(중복 감지)을 수행합니다. 이러한 인덱스는 대조 불일치로 인한 손상 문제가 발생하기 쉽습니다.

기본 `glibc` 라이브러리를 변경하는 운영 체제 업그레이드 후 이 작업을 실행합니다.

전제 조건:

- PostgreSQL 13 이상.

모든 데이터베이스에서 PostgreSQL 대조 불일치 및 관련 인덱스 손상을 확인하려면:

```shell
sudo gitlab-rake gitlab:db:collation_checker
```

특정 데이터베이스를 확인하려면:

```shell
# Check main database
sudo gitlab-rake gitlab:db:collation_checker:main

# Check CI database
sudo gitlab-rake gitlab:db:collation_checker:ci
```

### 테이블 크기 제한 조정 {#adjust-table-size-limits}

기본적으로 1GB보다 큰 테이블은 데이터베이스 성능에 영향을 줄 수 있는 오래 실행되는 쿼리를 피하기 위해 건너뜁니다. `MAX_TABLE_SIZE` 환경 변수를 설정하여 테이블 크기 임계값을 조정할 수 있습니다.

> [!warning]
> 테이블 크기 제한을 증가시키면 데이터베이스 성능에 영향을 줄 수 있는 오래 실행되는 쿼리가 발생할 수 있습니다.

```shell
# Set custom table size limit (in bytes)
# to increase the max table size threshold to 10 GB
MAX_TABLE_SIZE=10737418240 sudo gitlab-rake gitlab:db:collation_checker:main
```

### 장기 실행 쿼리에 대해 PgBouncer 우회 {#bypass-pgbouncer-for-long-running-queries}

문제 해결 섹션에서 [statement timeout 오류 해결](#resolve-statement-timeout-errors)을 참조합니다.

### 출력 예시 {#example-output}

문제가 없을 때:

```plaintext
Checking for PostgreSQL collation mismatches on main database...
No collation mismatches detected on main.
Found 8 indexes to corruption spot check.
No corrupted indexes detected.
```

불일치가 감지되면 작업은 영향을 받는 인덱스를 수정하기 위한 수정 단계를 제공합니다.

불일치가 있는 출력 예시:

```plaintext
Checking for PostgreSQL collation mismatches on main database...
⚠️ COLLATION MISMATCHES DETECTED on main database!
2 collation(s) have version mismatches:
  - en_US.utf8: stored=428.1, actual=513.1
  - es_ES.utf8: stored=428.1, actual=513.1

Found 8 indexes to corruption spot check.
Affected indexes that need to be rebuilt:
  - index_projects_on_name (btree) on table projects
    • Issues detected: duplicates
    • Affected columns: name
    • Type: UNIQUE
    • Needs deduplication: Yes

REMEDIATION STEPS:
1. Put GitLab into maintenance mode
2. Run the following SQL commands:

# Step 1: Check for duplicate entries in unique indexes
SELECT name, COUNT(*), ARRAY_AGG(id) FROM projects GROUP BY name HAVING COUNT(*) > 1 LIMIT 1;

# If duplicates exist, you may need to use gitlab:db:deduplicate_tags or similar tasks
# to fix duplicate entries before rebuilding unique indexes.

# Step 2: Rebuild affected indexes
# Option A: Rebuild individual indexes with minimal downtime:
REINDEX INDEX CONCURRENTLY index_projects_on_name;

# Option B: Alternatively, rebuild all indexes at once (requires downtime):
REINDEX DATABASE main;

# Step 3: Refresh collation versions
ALTER DATABASE main REFRESH COLLATION VERSION;

3. Take GitLab out of maintenance mode
```

PostgreSQL 대조 문제 및 데이터베이스 인덱스에 미치는 영향에 대한 자세한 내용은 [PostgreSQL 업그레이드 OS 설명서](../postgresql/upgrading_os.md)를 참조합니다.

## 손상된 데이터베이스 인덱스 복구 {#repair-corrupted-database-indexes}

{{< history >}}

- GitLab 18.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/196677)됨.
- PgBouncer 우회 옵션 GitLab 18.4에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203843).

{{< /history >}}

인덱스 복구 도구는 데이터 무결성 문제를 야기할 수 있는 손상되거나 누락된 데이터베이스 인덱스를 수정합니다. 이 도구는 대조 불일치 또는 기타 손상 문제의 영향을 받는 특정 문제의 인덱스를 다룹니다. 도구:

- 고유 인덱스가 손상된 경우 데이터를 중복 제거합니다.
- 데이터 무결성을 유지하기 위해 참조를 업데이트합니다.
- 올바른 구성으로 인덱스를 재구성하거나 만듭니다.

인덱스를 복구하기 전에 잠재적 변경을 분석하기 위해 드라이 실행 모드에서 도구를 실행합니다:

```shell
sudo DRY_RUN=true gitlab-rake gitlab:db:repair_index
```

다음 예제 출력은 변경 사항을 보여줍니다:

```shell
INFO -- : DRY RUN: Analysis only, no changes will be made.
INFO -- : Running Index repair on database main...
INFO -- : Processing index 'index_merge_request_diff_commit_users_on_name_and_email'...
INFO -- : Index is unique. Checking for duplicate data...
INFO -- : No duplicates found in 'merge_request_diff_commit_users' for columns: name,email.
INFO -- : Index exists. Reindexing...
INFO -- : Index reindexed successfully.
```

모든 데이터베이스의 알려진 모든 문제의 인덱스를 복구하려면:

```shell
sudo gitlab-rake gitlab:db:repair_index
```

명령은 각 데이터베이스를 처리하고 인덱스를 복구합니다. 예를 들어:

```shell
INFO -- : Running Index repair on database main...
INFO -- : Processing index 'index_merge_request_diff_commit_users_on_name_and_email'...
INFO -- : Index is unique. Checking for duplicate data...
INFO -- : No duplicates found in 'merge_request_diff_commit_users' for columns: name,email.
INFO -- : Index does not exist. Creating new index...
INFO -- : Index created successfully.
INFO -- : Index repair completed for database main.
```

특정 데이터베이스의 인덱스를 복구하려면:

```shell
# Repair indexes in main database
sudo gitlab-rake gitlab:db:repair_index:main

# Repair indexes in CI database
sudo gitlab-rake gitlab:db:repair_index:ci
```

### 장기 실행 쿼리에 대해 PgBouncer 우회 {#bypass-pgbouncer-for-long-running-queries-1}

문제 해결 섹션에서 [statement timeout 오류 해결](#resolve-statement-timeout-errors)을 참조합니다.

## 문제 해결 {#troubleshooting}

### 자문 잠금 연결 정보 {#advisory-lock-connection-information}

`db:migrate` Rake 작업을 실행한 후 다음과 같은 출력이 표시될 수 있습니다:

```shell
main: == [advisory_lock_connection] object_id: 173580, pg_backend_pid: 5532
main: == [advisory_lock_connection] object_id: 173580, pg_backend_pid: 5532
```

반환된 메시지는 정보용이며 무시할 수 있습니다.

### `gitlab:env:info` Rake 작업 실행 중 PostgreSQL 소켓 오류 {#postgresql-socket-errors-when-executing-the-gitlabenvinfo-rake-task}

Gitaly 또는 다른 Non-Rails 노드에서 `sudo gitlab-rake gitlab:env:info`을 실행한 후 다음 오류가 표시될 수 있습니다:

```plaintext
PG::ConnectionBad: could not connect to server: No such file or directory
Is the server running locally and accepting
connections on Unix domain socket "/var/opt/gitlab/postgresql/.s.PGSQL.5432"?
```

다중 노드 환경에서는 `gitlab:env:info` Rake 작업을 **GitLab Rails**를 실행하는 노드에서만 실행해야 하기 때문입니다.

### Statement timeout 오류 해결 {#resolve-statement-timeout-errors}

GitLab 인스턴스가 PgBouncer를 사용하고 데이터베이스 유지보수 작업(대조 확인 또는 인덱스 복구 등) 중에 statement timeout이 발생하는 경우 직접 PostgreSQL 연결을 사용하여 PgBouncer를 우회합니다.

```shell
# Example with direct connection
GITLAB_BACKUP_PGUSER=postgres GITLAB_BACKUP_PGHOST=localhost sudo gitlab-rake gitlab:db:collation_checker

GITLAB_BACKUP_PGUSER=postgres GITLAB_BACKUP_PGHOST=localhost sudo gitlab-rake gitlab:db:repair_index
```

지원되는 환경 변수:

- `GITLAB_BACKUP_PGHOST`
- `GITLAB_BACKUP_PGUSER`
- `GITLAB_BACKUP_PGPORT`
- `GITLAB_BACKUP_PGPASSWORD`

PgBouncer 우회 및 지원되는 환경 변수의 전체 목록에 대한 자세한 내용은 [PgBouncer 우회 절차](../postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer)를 참조합니다.
