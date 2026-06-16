---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sidekiq 작업 마이그레이션 Rake 작업
---

{{< details >}}

- 티어:  Free, Premium, Ultimate
- 제공 서비스: GitLab Self-Managed

{{< /details >}}

> [!warning]
> 이 작업은 매우 드물어야 합니다. 대부분의 GitLab 인스턴스에 이를 권장하지 않습니다.

Sidekiq 라우팅 규칙을 사용하면 관리자가 특정 백그라운드 작업을 일반 큐에서 대체 큐로 다시 라우팅할 수 있습니다. 기본적으로 GitLab은 백그라운드 작업 유형당 하나의 큐를 사용합니다. GitLab은 400개 이상의 백그라운드 작업 유형을 가지고 있으므로, 따라서 400개 이상의 큐를 가지고 있습니다.

대부분의 관리자는 이 설정을 변경할 필요가 없습니다. 특히 규모가 큰 백그라운드 작업 처리 워크로드가 있는 경우, GitLab이 수신 대기하는 큐의 수로 인해 Redis 성능이 저하될 수 있습니다.

Sidekiq 라우팅 규칙이 변경되면 관리자는 작업을 완전히 잃지 않도록 마이그레이션 시 주의해야 합니다. 기본 마이그레이션 단계는 다음과 같습니다:

1. 이전 큐와 새 큐 모두에 수신 대기합니다.
1. 라우팅 규칙을 업데이트합니다.
1. 변경 사항이 적용되려면 [GitLab 재구성](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행합니다.
1. [큐에 대기 중인 작업 및 향후 작업 마이그레이션을 위한 Rake 작업](#migrate-queued-and-future-jobs)을 실행합니다.
1. 이전 큐에 대한 수신 대기를 중지합니다.

## 큐에 대기 중인 작업 및 향후 작업 마이그레이션 {#migrate-queued-and-future-jobs}

4단계에서는 Redis에 이미 저장되어 있지만 향후 실행될 일부 Sidekiq 작업 데이터를 다시 작성합니다. 향후 실행될 작업의 두 가지 집합은 예약된 작업과 다시 시도할 작업입니다. 각 집합을 마이그레이션하기 위해 별도의 Rake 작업을 제공합니다:

- `gitlab:sidekiq:migrate_jobs:retry`은 다시 시도할 작업을 위한 것입니다.
- `gitlab:sidekiq:migrate_jobs:schedule`은 예약된 작업을 위한 것입니다.

아직 실행되지 않은 큐에 대기 중인 작업을 Rake 작업으로도 마이그레이션할 수 있습니다([GitLab 15.6에서 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101348) 이상):

- `gitlab:sidekiq:migrate_jobs:queued`은 비동기적으로 수행할 큐에 대기 중인 작업을 위한 것입니다.

대부분의 경우 세 가지를 동시에 실행하는 것이 올바른 선택입니다. 세 가지 별도의 작업을 통해 필요한 곳에서 더 세밀한 제어가 가능합니다. 세 가지를 한 번에 실행하려면([GitLab 15.6에서 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101348) 이상):

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule gitlab:sidekiq:migrate_jobs:queued

# source installations
bundle exec rake gitlab:sidekiq:migrate_jobs:retry gitlab:sidekiq:migrate_jobs:schedule gitlab:sidekiq:migrate_jobs:queued RAILS_ENV=production
```
