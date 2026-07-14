---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab CI/CD 인스턴스 구성
description: GitLab CI/CD 구성을 관리합니다.
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab 관리자는 인스턴스의 GitLab CI/CD 구성을 관리할 수 있습니다.

## 새 프로젝트에서 GitLab CI/CD 비활성화 {#disable-gitlab-cicd-in-new-projects}

GitLab CI/CD는 인스턴스의 모든 새 프로젝트에서 기본적으로 활성화됩니다. 다음 설정을 수정하여 새 프로젝트에서 CI/CD를 기본적으로 비활성화하도록 설정할 수 있습니다:

- `gitlab.yml`은 자체 컴파일 설치의 경우입니다.
- Linux 패키지 설치를 위해 `gitlab.rb`를 사용합니다.

이미 CI/CD가 활성화된 기존 프로젝트는 변경되지 않습니다. 또한 이 설정은 프로젝트 기본값만 변경하므로 프로젝트 소유자는 [프로젝트 설정에서 CI/CD를 계속 활성화](../../ci/pipelines/settings.md#disable-gitlab-cicd-pipelines)할 수 있습니다.

자체 컴파일된 설치의 경우:

1. `gitlab.yml`을(를) 편집기로 열고 `builds`를 `false`로 설정합니다:

   ```yaml
   ## Default project features settings
   default_projects_features:
     issues: true
     merge_requests: true
     wiki: true
     snippets: false
     builds: false
   ```

1. `gitlab.yml` 파일을 저장합니다.
1. GitLab을 다시 시작합니다:

   ```shell
   sudo service gitlab restart
   ```

Linux 패키지 설치의 경우:

1. `/etc/gitlab/gitlab.rb`을(를) 편집하고 다음 줄을 추가합니다:

   ```ruby
   gitlab_rails['gitlab_default_projects_features_builds'] = false
   ```

1. `/etc/gitlab/gitlab.rb` 파일을 저장합니다.
1. GitLab을 재구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## `needs` 작업 제한 설정 {#set-the-needs-job-limit}

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

`needs`에서 정의할 수 있는 최대 작업 수는 기본적으로 50입니다.

[GitLab Rails 콘솔에 액세스할 수 있는](../operations/rails_console.md#starting-a-rails-console-session) GitLab 관리자는 사용자 지정 제한을 선택할 수 있습니다. 예를 들어 제한을 `100`로 설정하려면:

```ruby
Plan.default.actual_limits.update!(ci_needs_size_limit: 100)
```

`needs` 종속성을 비활성화하려면 제한을 `0`로 설정합니다. `needs`을(를) 사용하도록 구성된 파이프라인의 작업은 오류 `job can only need 0 others`를 반환합니다.

## 최대 예약 파이프라인 빈도 변경 {#change-maximum-scheduled-pipeline-frequency}

[예약 파이프라인](../../ci/pipelines/schedules.md) 은 모든 [cron 값](../../topics/cron/_index.md)으로 구성할 수 있지만 예약된 시간에 정확히 실행되지 않을 수 있습니다. _파이프라인 일정 작업자_라는 내부 프로세스는 모든 예약된 파이프라인을(를) 큐에 추가하지만 계속 실행되지는 않습니다. 작업자는 자체 일정에 따라 실행되며 시작할 준비가 된 예약된 파이프라인은 작업자가 다음에 실행될 때만 큐에 추가됩니다. 예약된 파이프라인은 작업자보다 더 자주 실행될 수 없습니다.

파이프라인 일정 작업자의 기본 빈도는 `3-59/10 * * * *`입니다(10분마다 한 번, `0:03`, `0:13`, `0:23`부터 시작). GitLab.com의 기본 빈도는 [GitLab.com 설정](../../user/gitlab_com/_index.md#cicd)에 나열되어 있습니다.

파이프라인 일정 작업자의 빈도를 변경하려면:

1. 인스턴스의 `gitlab.rb` 파일에서 `gitlab_rails['pipeline_schedule_worker_cron']` 값을 편집합니다.
1. [Reconfigure GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation)을 수행하여 변경 사항을 적용합니다.

예를 들어 파이프라인의 최대 빈도를 하루에 두 번으로 설정하려면 `pipeline_schedule_worker_cron`을(를) `0 */12 * * *` cron 값(매일 `00:00`과(와) `12:00`)으로 설정합니다.

많은 파이프라인 일정이 동시에 실행되면 추가 지연이 발생할 수 있습니다. 파이프라인 일정 작업자는 시스템 부하를 분산하기 위해 각 배치 간의 작은 지연으로 [배치](https://gitlab.com/gitlab-org/gitlab/-/blob/3426be1b93852c5358240c5df40970c0ddfbdb2a/app/workers/pipeline_schedule_worker.rb#L13-14)로 파이프라인을(를) 처리합니다. 이로 인해 파이프라인 일정이 시스템 부하에 따라 예약된 시간 이후로 몇 분에서 1시간 이상 시작될 수 있습니다.

## 재해 복구 {#disaster-recovery}

지속 중인 다운타임 중에 데이터베이스의 스트레스를 완화하기 위해 애플리케이션의 중요하지만 계산상 비싼 부분을 비활성화할 수 있습니다.

### 인스턴스 러너에서 공정한 스케줄링 비활성화 {#disable-fair-scheduling-on-instance-runners}

큰 작업 백로그를 지울 때 `ci_queueing_disaster_recovery_disable_fair_scheduling` [기능 플래그](../feature_flags/_index.md)를 임시로 활성화할 수 있습니다. 이 플래그는 인스턴스 러너에서 공정한 스케줄링을 비활성화하여 `jobs/request` 엔드포인트에 대한 시스템 리소스 사용을 줄입니다.

활성화되면 작업은 여러 프로젝트에 균형을 맞추는 대신 시스템에 입력된 순서대로 처리됩니다.

### 컴퓨팅 할당량 적용 비활성화 {#disable-compute-quota-enforcement}

인스턴스 러너에서 [컴퓨팅 분 할당량](compute_minutes.md) 적용을 비활성화하려면 `ci_queueing_disaster_recovery_disable_quota` [기능 플래그](../feature_flags/_index.md)를 임시로 활성화할 수 있습니다. 이 플래그는 `jobs/request` 엔드포인트에 대한 시스템 리소스 사용을 줄입니다.

활성화되면 지난 시간에 생성된 작업은 할당량이 초과된 프로젝트에서 실행될 수 있습니다. 이전 작업은 이미 주기적 백그라운드 작업자(`StuckCiJobsWorker`)에 의해 취소되었습니다.
