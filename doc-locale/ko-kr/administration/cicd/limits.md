---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "파이프라인, 작업, 일정 및 아티팩트에 대한 CI/CD 한도를 구성하여 인스턴스에서 리소스 사용을 제어합니다."
title: CI/CD 한도
---

{{< details >}}

- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

많은 CI/CD 관련 인스턴스 한도를 [관리 영역](../admin_area.md)을 통해 관리할 수 있습니다. 다른 한도는 GitLab Rails 콘솔을 통해 인스턴스 구성을 수정하여만 변경할 수 있습니다.

GitLab.com은 GitLab Self-Managed의 기본값과 다를 수 있습니다. [GitLab.com의 CI/CD 한도 및 설정](../../user/gitlab_com/_index.md#cicd)을 검토하세요.

## 인스턴스 CI/CD 변수 한도 {#instance-cicd-variable-limit}

{{< history >}}

- [GitLab 17.1에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/456845).

{{< /history >}}

인스턴스 설정에서 정의할 수 있는 [CI/CD 변수](../../ci/variables/_index.md)의 수는 제한됩니다. 이 한도는 새 변수가 생성될 때마다 확인됩니다. 새 변수로 인해 변수의 총 개수가 한도를 초과하면 새 변수가 생성되지 않습니다.

이 한도를 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **CI/CD 한도** 아래에서 **정의할 수 있는 인스턴스 수준 CI/CD 변수의 최대 수**에 대한 값을 설정합니다. 기본값은 `25`입니다.
1. **변경 사항 저장**을 선택합니다.

## Dotenv 파일 크기 제한 {#limit-dotenv-file-size}

{{< history >}}

- [GitLab 17.1에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155791).

{{< /history >}}

dotenv 아티팩트의 최대 크기에 대한 한도를 설정할 수 있습니다. 이 한도는 dotenv 파일이 아티팩트로 내보내질 때마다 확인됩니다.

이 한도를 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **CI/CD 한도** 아래에서 **dotenv 아티팩트의 최대 크기(바이트)**에 대한 값을 설정합니다.
1. **변경 사항 저장**을 선택합니다.

한도를 `0`로 설정하여 비활성화합니다. 기본값은 5 KB입니다.

## Dotenv 변수 제한 {#limit-dotenv-variables}

{{< history >}}

- [GitLab 17.1에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155791).

{{< /history >}}

dotenv 아티팩트 내의 최대 변수 개수에 대한 한도를 설정할 수 있습니다. 이 한도는 dotenv 파일이 아티팩트로 내보내질 때마다 확인됩니다.

이 한도를 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **CI/CD 한도** 아래에서 **dotenv 아티팩트에서 변수의 최대 수**에 대한 값을 설정합니다.
1. **변경 사항 저장**을 선택합니다.

한도를 `0`로 설정하여 비활성화합니다. 기본값은 `20`입니다.

[Plan limits API](../../api/plan_limits.md)를 사용하여 이 한도를 설정할 수도 있습니다.

## 파이프라인의 최대 작업 개수 {#maximum-number-of-jobs-in-a-pipeline}

{{< history >}}

- 설정이 GitLab 17.6에서 GitLab Enterprise Edition에서 GitLab Community Edition으로 [이동되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/287669).

{{< /history >}}

파이프라인의 최대 작업 개수를 제한할 수 있습니다. 파이프라인의 작업 개수는 파이프라인 생성 시 및 새 커밋 상태가 생성될 때 확인됩니다. 작업이 너무 많은 파이프라인은 `size_limit_exceeded` 오류로 인해 실패합니다.

이 한도를 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **CI/CD 한도** 아래에서 **단일 파이프라인내의 작업의 최대 개수**에 대한 값을 설정합니다.
1. **변경 사항 저장**을 선택합니다.

한도를 `0`로 설정하여 비활성화합니다. 기본적으로 비활성화됨.

## 활성 파이프라인의 작업 개수 {#number-of-jobs-in-active-pipelines}

활성 파이프라인의 총 작업 개수는 프로젝트별로 제한할 수 있습니다. 이 한도는 새 파이프라인이 생성될 때마다 확인됩니다. 활성 파이프라인은 다음 상태 중 하나에 있는 모든 파이프라인입니다:

- `created`
- `pending`
- `running`

새 파이프라인으로 인해 총 작업 개수가 한도를 초과하면 파이프라인이 `job_activity_limit_exceeded` 오류로 인해 실패합니다.

이 한도를 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **CI/CD 한도** 아래에서 **현재 활성 파이프라인의 총 작업 개수**에 대한 값을 설정합니다.
1. **변경 사항 저장**을 선택합니다.

한도를 `0`로 설정하여 비활성화합니다. 기본적으로 비활성화됨.

## 프로젝트에 대한 CI/CD 구독 수 {#number-of-cicd-subscriptions-to-a-project}

구독의 총 개수는 프로젝트별로 제한할 수 있습니다. 이 한도는 새 구독이 생성될 때마다 확인됩니다.

새 구독으로 인해 구독의 총 개수가 한도를 초과하면 구독이 유효하지 않은 것으로 간주됩니다.

이 한도를 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **CI/CD 한도** 아래에서 **프로젝트에 대한 파이프라인 구독의 최대 개수**에 대한 값을 설정합니다.
1. **변경 사항 저장**을 선택합니다.

기본적으로 `2` 구독의 한도가 있습니다. 한도를 `0`로 설정하여 비활성화합니다.

## 파이프라인 일정의 개수 {#number-of-pipeline-schedules}

파이프라인 일정의 총 개수는 프로젝트별로 제한할 수 있습니다. 이 한도는 새 파이프라인 일정이 생성될 때마다 확인됩니다. 새 파이프라인 일정으로 인해 파이프라인 일정의 총 개수가 한도를 초과하면 파이프라인 일정이 생성되지 않습니다.

이 한도를 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **CI/CD 한도** 아래에서 **파이프라인 스케줄의 최대 개수**에 대한 값을 설정합니다.
1. **변경 사항 저장**을 선택합니다.

기본적으로 `10` 파이프라인 일정의 한도가 있습니다.

[Plan Limits API](../../api/plan_limits.md)를 사용할 수도 있습니다.

## 최대 필요 의존성 개수 {#maximum-number-of-needs-dependencies}

단일 작업이 가질 수 있는 최대 필요 의존성 개수를 설정할 수 있습니다.

이 한도를 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **CI/CD 한도** 아래에서 **작업이 가질 수 있는 최대 요구 사항 의존성 수**에 대한 값을 설정합니다
1. **변경 사항 저장**을 선택합니다.

이 한도는 비활성화할 수 없습니다. 기본값은 `50`입니다. `0`로 설정하여 모든 필요 의존성을 차단합니다.

## 그룹 및 프로젝트의 등록된 러너 수 {#number-of-registered-runners-for-groups-and-projects}

{{< history >}}

- 러너 stale 타임아웃이 GitLab 17.1에서 3개월에서 7일로 [변경되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/155795).

{{< /history >}}

등록된 러너의 총 개수는 그룹 및 프로젝트에 대해 제한됩니다. 새 러너가 등록될 때마다 GitLab은 지난 7일간 생성되거나 활성화된 러너에 대해 이러한 한도를 확인합니다. 러너 등록 토큰으로 결정된 범위에 대한 한도를 초과하면 러너 등록이 실패합니다.

이 한도를 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **CI/CD 한도** 아래에서 다음 중 하나에 대한 값을 설정합니다:
   - **지난 7일간 이 그룹에서 생성 혹은 활성화된 러너의 최대 개수**
   - **지난 7일간 이 프로젝트에서 생성 혹은 활성화된 러너의 최대 개수**
1. **변경 사항 저장**을 선택합니다.

한도를 `0`로 설정하여 비활성화합니다.

## 파이프라인 계층 크기 제한 {#limit-pipeline-hierarchy-size}

기본적으로 [파이프라인 계층](../../ci/pipelines/downstream_pipelines.md)은 최대 1000개의 다운스트림 파이프라인을 포함할 수 있습니다. 이 한도를 초과하면 파이프라인 생성이 `downstream pipeline tree is too large` 오류로 인해 실패합니다.

> [!warning]
> 이 한도를 증가시키는 것은 권장되지 않습니다. 기본 한도는 GitLab 인스턴스를 과도한 리소스 소비, 잠재적 파이프라인 재귀 및 데이터베이스 과부하로부터 보호합니다.
>
> 한도를 증가시키는 대신 CI/CD 구성을 재구성하여 큰 파이프라인 계층을 더 작은 파이프라인으로 분할합니다. 작업 간 또는 단일 파이프라인의 종속 스테이지 간에 `needs`를 사용하는 것을 고려하세요.

이 한도를 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **CI/CD 한도** 아래에서 **파이프라인 계층 트리의 다운스트림 파이프라인 최대 개수**에 대한 값을 설정합니다.
1. **변경 사항 저장**을 선택합니다.

[Plan Limits API](../../api/plan_limits.md)를 사용할 수도 있습니다.

## 머지 트레인 병렬 파이프라인 한도 {#merge-train-parallel-pipeline-limit}

{{< history >}}

- GitLab 19.0에서 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/issues/374188).

{{< /history >}}

기본적으로 각 [머지 트레인](../../ci/pipelines/merge_trains.md)은 최대 20개의 파이프라인을 병렬로 실행할 수 있습니다. 이 한도에 도달하면 추가 머지 리퀘스트는 파이프라인 슬롯이 사용 가능해질 때까지 대기열에 추가됩니다.

이 한도를 구성하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **CI/CD 한도** 아래에서 **Maximum parallel pipelines per merge train**에 대한 값을 설정합니다. 최소값은 `1`입니다. `1`의 값은 병렬화 없이 머지 리퀘스트를 순차적으로 처리합니다.
1. **변경 사항 저장**을 선택합니다.

[Plan Limits API](../../api/plan_limits.md)를 사용할 수도 있습니다.

[특정 프로젝트에 대해](../../ci/pipelines/merge_trains.md#merge-train-parallel-pipeline-limit) 다른 값을 설정할 수 있습니다.

## 작업이 실행될 수 있는 최대 시간 {#maximum-time-jobs-can-run}

작업이 실행될 수 있는 기본 최대 시간은 60분입니다. 60분 이상 실행되는 작업은 타임아웃됩니다.

작업이 타임아웃되기 전에 실행할 수 있는 최대 시간을 변경할 수 있습니다:

- 특정 프로젝트의 [프로젝트의 CI/CD 설정](../../ci/pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run)에서. 이 한도는 10분에서 1개월 사이여야 합니다.
- [러너의 경우](../../ci/runners/configure_runners.md#set-the-maximum-job-timeout). 이 한도는 10분 이상이어야 합니다.

구성된 타임아웃 한도와 관계없이 GitLab은 60분 동안 비활성 상태인 모든 작업을 종료합니다. 비활성 작업은 새 로그 또는 추적 업데이트를 생성하지 않은 작업입니다.

## Git push당 파이프라인 수 {#number-of-pipelines-per-git-push}

{{< history >}}

- [GitLab 18.0에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186134).

{{< /history >}}

> [!warning]
> 이 한도를 증가시키는 것은 권장되지 않습니다. 많은 변경 사항이 동시에 푸시될 경우 GitLab 인스턴스에 과도한 부하를 일으켜 파이프라인 폭증을 발생시킬 수 있습니다.

여러 태그 또는 브랜치와 같은 여러 변경 사항을 단일 Git push로 푸시할 때 기본적으로 4개의 태그 또는 브랜치 파이프라인만 트리거될 수 있습니다. 이 한도는 `git push --all` 또는 `git push --mirror`를 사용할 때 대량의 파이프라인이 실수로 생성되는 것을 방지합니다.

[머지 리퀘스트 파이프라인](../../ci/pipelines/merge_request_pipelines.md)은 제한됩니다. Git push가 동시에 여러 머지 리퀘스트를 업데이트하는 경우 한도에 도달하기 전에 업데이트된 각 머지 리퀘스트에 대해 머지 리퀘스트 파이프라인이 트리거될 수 있습니다.

기본값은 GitLab Self-Managed 및 GitLab.com의 경우 `4`입니다.

GitLab Self-Managed 인스턴스에서 이 한도를 변경하려면:

1. 오른쪽 위 모서리에서 **Admin**을 선택합니다.
1. 왼쪽 사이드바에서 **설정** > **CI/CD**를 선택합니다.
1. **지속적 통합 및 배포**를 확장합니다.
1. **Git push 당 파이프라인 한도**의 값을 변경합니다.
1. **변경 사항 저장**을 선택합니다.

## CI/CD 한도 인스턴스 구성 {#cicd-limits-instance-configuration}

{{< details >}}

- 제공 서비스: GitLab Self-Managed

{{< /details >}}

일부 CI/CD 한도는 인스턴스 구성을 편집하여만 변경할 수 있습니다.

전제 조건:

- 인스턴스에 대한 [GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)에 대한 액세스 권한이 있어야 합니다.

### 파이프라인의 최대 배포 작업 수 {#maximum-number-of-deployment-jobs-in-a-pipeline}

파이프라인에서 배포 작업의 최대 개수를 제한할 수 있습니다. 배포는 [`environment`](../../ci/environments/_index.md)이 지정된 모든 작업입니다. 파이프라인의 배포 수는 파이프라인 생성 시 확인됩니다. 배포가 너무 많은 파이프라인은 `deployments_limit_exceeded` 오류로 인해 실패합니다.

한도를 변경하려면 `default` 계획의 한도를 다음 [GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session) 명령으로 변경합니다:

```ruby
# If limits don't exist for the default plan, you can create one with:
# Plan.default.create_limits!

Plan.default.actual_limits.update!(ci_pipeline_deployments: 500)
```

기본 한도는 `500`입니다. 한도를 `0`로 설정하여 비활성화합니다.

### 파이프라인 트리거 수 제한 {#limit-the-number-of-pipeline-triggers}

프로젝트당 파이프라인 트리거의 최대 개수에 대한 한도를 설정할 수 있습니다. 이 한도는 새 트리거가 생성될 때마다 확인됩니다.

새 트리거로 인해 파이프라인 트리거의 총 개수가 한도를 초과하면 트리거가 유효하지 않은 것으로 간주됩니다.

한도를 `0`로 설정하여 비활성화합니다. 기본값은 `25000`입니다.

이 한도를 `100`로 설정하려면 [GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행하세요:

```ruby
Plan.default.actual_limits.update!(pipeline_triggers: 100)
```

### 파이프라인 일정의 개수 {#number-of-pipeline-schedules-1}

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

파이프라인 일정의 총 개수는 프로젝트별로 제한할 수 있습니다. 이 한도는 새 파이프라인 일정이 생성될 때마다 확인됩니다. 새 파이프라인 일정으로 인해 파이프라인 일정의 총 개수가 한도를 초과하면 파이프라인 일정이 생성되지 않습니다.

GitLab Self-Managed 및 GitLab Dedicated에서 이 한도는 모든 프로젝트에 영향을 미치는 `default` 계획 아래에 정의됩니다. 기본적으로 `10` 파이프라인 일정의 한도가 있습니다.

이 한도를 설정하려면 [Plan Limits API](../../api/plan_limits.md)를 사용하세요.

GitLab Self-Managed의 경우 [GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)을 사용할 수도 있습니다. 예를 들어 한도를 100으로 설정하려면:

```ruby
Plan.default.actual_limits.update!(ci_pipeline_schedules: 100)
```

### 파이프라인 일정이 매일 생성하는 파이프라인 수 제한 {#limit-the-number-of-pipelines-created-by-a-pipeline-schedule-each-day}

각 개별 파이프라인 일정이 하루에 트리거할 수 있는 파이프라인 수를 제한할 수 있습니다.

한도보다 더 자주 파이프라인을 실행하려고 시도하는 일정은 최대 빈도로 느려집니다. 빈도는 1440(하루의 분 수)을 한도 값으로 나누어 계산됩니다. 예를 들어 최대 빈도의 경우:

- 분당 한 번이면 한도는 `1440`이어야 합니다.
- 10분마다 한 번이면 한도는 `144`이어야 합니다.
- 60분마다 한 번이면 한도는 `24`이어야 합니다

최소값은 `24`이며, 60분마다 한 파이프라인입니다. 최대값은 없습니다.

GitLab Self-Managed 인스턴스에서 이 한도를 `1440`로 설정하려면 [GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행하세요:

```ruby
Plan.default.actual_limits.update!(ci_daily_pipeline_schedule_triggers: 1440)
```

### 보안 정책 프로젝트에 대해 정의된 일정 규칙 수 제한 {#limit-the-number-of-schedule-rules-defined-for-security-policy-project}

보안 정책 프로젝트당 일정 규칙의 총 개수를 제한할 수 있습니다. 이 한도는 일정 규칙이 있는 정책이 업데이트될 때마다 확인됩니다. 새 일정 규칙으로 인해 일정 규칙의 총 개수가 한도를 초과하면 새 일정 규칙이 처리되지 않습니다.

기본적으로 GitLab은 처리 가능한 일정 규칙의 개수를 제한하지 않습니다.

이 한도를 설정하려면 [GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행하세요:

```ruby
Plan.default.actual_limits.update!(security_policy_scan_execution_schedules: 100)
```

### 그룹 및 프로젝트 CI/CD 변수 한도 {#group-and-project-cicd-variable-limits}

그룹 및 프로젝트에서 정의할 수 있는 [CI/CD 변수](../../ci/variables/_index.md)의 수는 전체 인스턴스에 대해 제한됩니다. 이 한도는 새 변수가 생성될 때마다 확인됩니다. 새 변수로 인해 변수의 총 개수가 각 한도를 초과하면 새 변수가 생성되지 않습니다.

`default` 계획을 업데이트하려면 [GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)에서 다음 명령을 실행하세요:

- [그룹 수준 CI/CD 변수](../../ci/variables/_index.md#for-a-group) 한도(기본값: `30000`):

  ```ruby
  Plan.default.actual_limits.update!(group_ci_variables: 40000)
  ```

- [프로젝트 수준 CI/CD 변수](../../ci/variables/_index.md#for-a-project) 한도(기본값: `8000`):

  ```ruby
  Plan.default.actual_limits.update!(project_ci_variables: 10000)
  ```

### 아티팩트 유형별 최대 파일 크기 {#maximum-file-size-per-type-of-artifact}

{{< history >}}

- `ci_max_artifact_size_annotations` 한도는 GitLab 16.3에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/38337).
- `ci_max_artifact_size_jacoco` 한도는 GitLab 17.3에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159696)
- `ci_max_artifact_size_lsif` 한도는 GitLab 17.8에서 [증가했습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175684).

{{< /history >}}

[`artifacts:reports`](../../ci/yaml/_index.md#artifactsreports)로 정의된 작업 아티팩트는 러너에 의해 업로드되며 파일 크기가 최대 파일 크기 한도를 초과하면 거부됩니다. 한도는 프로젝트의 [최대 아티팩트 크기 설정](../settings/continuous_integration.md#set-maximum-artifacts-size)과 주어진 아티팩트 유형의 인스턴스 한도를 비교하여 결정되며, 더 작은 값을 선택합니다.

한도는 메가바이트 단위로 설정되므로 정의할 수 있는 가장 작은 값은 `1 MB`입니다.

각 아티팩트 유형에는 설정할 수 있는 크기 한도가 있습니다. `0`의 기본값은 해당 아티팩트 유형에 대한 한도가 없으며 프로젝트의 최대 아티팩트 크기 설정이 사용됨을 의미합니다:

| 아티팩트 한도 이름                         | 기본값 |
|---------------------------------------------|---------------|
| `ci_max_artifact_size_accessibility`        | 0             |
| `ci_max_artifact_size_annotations`          | 0             |
| `ci_max_artifact_size_api_fuzzing`          | 0             |
| `ci_max_artifact_size_archive`              | 0             |
| `ci_max_artifact_size_browser_performance`  | 0             |
| `ci_max_artifact_size_cluster_applications` | 0             |
| `ci_max_artifact_size_cobertura`            | 0             |
| `ci_max_artifact_size_codequality`          | 0             |
| `ci_max_artifact_size_container_scanning`   | 0             |
| `ci_max_artifact_size_coverage_fuzzing`     | 0             |
| `ci_max_artifact_size_dast`                 | 0             |
| `ci_max_artifact_size_dependency_scanning`  | 0             |
| `ci_max_artifact_size_dotenv`               | 0             |
| `ci_max_artifact_size_jacoco`               | 0             |
| `ci_max_artifact_size_junit`                | 0             |
| `ci_max_artifact_size_license_management`   | 0             |
| `ci_max_artifact_size_license_scanning`     | 0             |
| `ci_max_artifact_size_load_performance`     | 0             |
| `ci_max_artifact_size_lsif`                 | 200 MB        |
| `ci_max_artifact_size_metadata`             | 0             |
| `ci_max_artifact_size_metrics_referee`      | 0             |
| `ci_max_artifact_size_metrics`              | 0             |
| `ci_max_artifact_size_network_referee`      | 0             |
| `ci_max_artifact_size_performance`          | 0             |
| `ci_max_artifact_size_requirements`         | 0             |
| `ci_max_artifact_size_requirements_v2`      | 0             |
| `ci_max_artifact_size_sast`                 | 0             |
| `ci_max_artifact_size_secret_detection`     | 0             |
| `ci_max_artifact_size_terraform`            | 5 MB          |
| `ci_max_artifact_size_trace`                | 0             |
| `ci_max_artifact_size_cyclonedx`            | 5 MB          |

예를 들어 GitLab Self-Managed에서 `ci_max_artifact_size_junit` 한도를 10 MB로 설정하려면 [GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행하세요:

```ruby
Plan.default.actual_limits.update!(ci_max_artifact_size_junit: 10)
```

### 작업 로그의 최대 파일 크기 {#maximum-file-size-for-job-logs}

GitLab의 작업 로그 파일 크기 한도는 기본적으로 100메가바이트입니다. 한도를 초과하는 모든 작업은 실패로 표시되고 러너에 의해 삭제됩니다.

[GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)에서 한도를 변경할 수 있습니다. `ci_jobs_trace_size_limit`를 새로운 메가바이트 값으로 업데이트합니다:

```ruby
Plan.default.actual_limits.update!(ci_jobs_trace_size_limit: 125)
```

GitLab 러너에는 러너의 최대 로그 크기를 구성하는 [`output_limit` 설정](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-runners-section)도 있습니다. 러너 한도를 초과하는 작업은 계속 실행되지만 한도에 도달하면 로그가 잘립니다.

### 프로젝트당 최대 활성 DAST 프로필 일정 수 {#maximum-number-of-active-dast-profile-schedules-per-project}

프로젝트당 활성 DAST 프로필 일정 수를 제한합니다. A DAST profile schedule can be active or inactive.

[GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)에서 한도를 변경할 수 있습니다. `dast_profile_schedules`를 새로운 값으로 업데이트합니다:

```ruby
Plan.default.actual_limits.update!(dast_profile_schedules: 50)
```

### CI 아티팩트 아카이브의 최대 크기 {#maximum-size-of-the-ci-artifacts-archive}

이 설정은 [동적 하위 파이프라인](../../ci/pipelines/downstream_pipelines.md#dynamic-child-pipelines)의 YAML 크기를 제한하는 데 사용됩니다.

CI 아티팩트 아카이브의 기본 최대 크기는 5메가바이트입니다.

[GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)을 사용하여 이 한도를 변경할 수 있습니다. CI 아티팩트 아카이브의 최대 크기를 업데이트하려면 `max_artifacts_content_include_size`를 새로운 값으로 업데이트합니다. 예를 들어 20 MB로 설정하려면:

```ruby
ApplicationSetting.update(max_artifacts_content_include_size: 20.megabytes)
```

### CI/CD 구성 YAML 파일의 최대 크기 및 깊이 {#maximum-size-and-depth-of-cicd-configuration-yaml-files}

{{< history >}}

- `max_yaml_size_bytes`의 기본값이 GitLab 17.3에서 [변경되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826).

{{< /history >}}

단일 CI/CD 구성 YAML 파일의 기본 최대 크기는 2메가바이트이며 기본 깊이는 100입니다.

[GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)에서 이 한도를 변경할 수 있습니다:

- 최대 YAML 크기를 업데이트하려면 `max_yaml_size_bytes`를 메가바이트 단위의 새로운 값으로 업데이트합니다:

  ```ruby
  ApplicationSetting.update(max_yaml_size_bytes: 4.megabytes)
  ```

  `max_yaml_size_bytes` 값은 YAML 파일의 크기와 직접 연관되지 않으며, 관련 객체에 할당된 메모리와 관련됩니다.

- 최대 YAML 깊이를 업데이트하려면 `max_yaml_depth`를 라인 수의 새로운 값으로 업데이트합니다:

  ```ruby
  ApplicationSetting.update(max_yaml_depth: 125)
  ```

### 전체 CI/CD 구성의 최대 크기 {#maximum-size-of-the-entire-cicd-configuration}

{{< history >}}

- `max_yaml_size_bytes`의 기본값이 GitLab 17.3에서 [변경되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826).
- `ci_max_total_yaml_size_bytes`의 기본값이 GitLab 17.3에서 [변경되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/160826).

{{< /history >}}

포함된 모든 YAML 구성 파일을 포함하여 전체 파이프라인 구성에 할당할 수 있는 최대 메모리(바이트)입니다.

기본값은 [`max_yaml_size_bytes`](#maximum-size-and-depth-of-cicd-configuration-yaml-files) (기본값 2 MB)에 [`ci_max_includes`](../../api/settings.md#available-settings)(기본값 150)을 곱하여 계산됩니다:

- GitLab 17.2 이하:  1 MB × 150 = `157286400` 바이트(150 MB).
- GitLab 17.3 이후:  2 MB × 150 = `314572800` 바이트(314.6 MB).

[GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)을 사용하여 이 한도를 변경할 수 있습니다. CI/CD 구성에 할당할 수 있는 최대 메모리를 업데이트하려면 `ci_max_total_yaml_size_bytes`를 새로운 값으로 업데이트합니다. 예를 들어 20 MB로 설정하려면:

```ruby
ApplicationSetting.update(ci_max_total_yaml_size_bytes: 20.megabytes)
```

### CI/CD 작업 주석 제한 {#limit-cicd-job-annotations}

{{< history >}}

- [GitLab 16.3에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/38337).

{{< /history >}}

CI/CD 작업당 [주석](../../ci/yaml/artifacts_reports.md#artifactsreportsannotations)의 최대 개수에 대한 한도를 설정할 수 있습니다.

한도를 `0`로 설정하여 비활성화합니다. 기본값은 `20`입니다.

이 한도를 인스턴스에서 `100`로 설정하려면 [GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)에서 다음 명령을 실행하세요:

```ruby
Plan.default.actual_limits.update!(ci_job_annotations_num: 100)
```

### CI/CD 작업 주석 파일 크기 제한 {#limit-cicd-job-annotations-file-size}

{{< history >}}

- [GitLab 16.3에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/38337).

{{< /history >}}

CI/CD 작업 [주석](../../ci/yaml/artifacts_reports.md#artifactsreportsannotations)의 최대 크기에 대한 한도를 설정할 수 있습니다.

한도를 `0`로 설정하여 비활성화합니다. 기본값은 80 KB입니다.

이 한도를 100 KB로 설정하려면 [GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)에서 다음을 실행하세요:

```ruby
Plan.default.actual_limits.update!(ci_job_annotations_size: 100.kilobytes)
```

### CI/CD 테이블의 최대 데이터베이스 파티션 크기 {#maximum-database-partition-size-for-cicd-tables}

{{< history >}}

- [GitLab 18.0에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189131).
- [GitLab 18.11에서 제거되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/577314).

{{< /history >}}

새 파티션이 자동으로 생성되기 전에 분할된 테이블의 파티션에서 사용할 수 있는 최대 디스크 공간(바이트)입니다. 기본값은 100 GB입니다.

[GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)을 사용하여 이 한도를 변경할 수 있습니다. 한도를 변경하려면 `ci_partitions_size_limit`를 새로운 값으로 업데이트합니다. 예를 들어 20 GB로 설정하려면:

```ruby
ApplicationSetting.update(ci_partitions_size_limit: 20.gigabytes)
```

### CI/CD 파티션의 최대 시간 창 {#maximum-time-window-for-cicd-partitions}

{{< history >}}

- GitLab 18.10에 [도입됨](https://gitlab.com/gitlab-org/gitlab/-/work_items/577314).

{{< /history >}}

새 CI 파티션이 생성되고 시스템이 다음 파티션 집합으로 전환되기 전의 시간 창(초)입니다. 1개월에서 6개월 사이여야 합니다. 기본값은 1개월(2592000초)입니다.

[GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)을 사용하여 이 한도를 변경할 수 있습니다. 한도를 변경하려면 `ci_partitions_in_seconds_limit`를 새로운 값으로 업데이트합니다. 예를 들어 3개월로 설정하려면:

```ruby
ApplicationSetting.update(ci_partitions_in_seconds_limit: ChronicDuration.parse('3 months'))
```

### 자동 파이프라인 정리를 위한 최대 보존 기간 {#maximum-retention-period-for-automatic-pipeline-cleanup}

{{< history >}}

- [GitLab 18.0에 도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189191).

{{< /history >}}

[자동 파이프라인 정리](../../ci/pipelines/settings.md#automatic-pipeline-cleanup)의 상한을 구성합니다. 기본값은 1년입니다.

[GitLab Rails 콘솔](../operations/rails_console.md#starting-a-rails-console-session)을 사용하여 이 한도를 변경할 수 있습니다. 한도를 변경하려면 `ci_delete_pipelines_in_seconds_limit_human_readable`를 새로운 값으로 업데이트합니다. 예를 들어 3년으로 설정하려면:

```ruby
ApplicationSetting.update(ci_delete_pipelines_in_seconds_limit_human_readable: '3 years')
```
