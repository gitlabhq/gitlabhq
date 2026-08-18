---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "계산, 할당량, 구매 정보입니다."
title: 컴퓨팅 분
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI/CD 작업을 실행하는 프로젝트에서 인스턴스 러너를 사용하는 것은 컴퓨팅 분으로 측정됩니다.

일부 설치 유형의 경우 귀사의 [네임스페이스](../../user/namespace/_index.md)에는 [컴퓨팅 할당량](instance_runner_compute_minutes.md#compute-quota-enforcement)이 있으며, 이는 사용할 수 있는 컴퓨팅 분을 제한합니다.

컴퓨팅 할당량을 모든 [관리자 관리 인스턴스 러너](instance_runner_compute_minutes.md)에 적용할 수 있습니다:

- GitLab.com 또는 GitLab Self-Managed의 모든 인스턴스 러너
- GitLab Dedicated의 모든 자체 호스팅 인스턴스 러너

컴퓨팅 할당량은 기본적으로 비활성화되어 있지만 최상위 그룹과 사용자 네임스페이스에 대해 활성화할 수 있습니다. GitLab.com에서 할당량은 기본적으로 활성화되어 Free 네임스페이스에서의 사용을 제한합니다. 유료 구독을 구매하면 한도가 증가합니다.

GitLab Dedicated의 GitLab 호스팅 인스턴스 러너에는 인스턴스 러너 컴퓨팅 할당량을 적용할 수 없습니다.

## 인스턴스 러너 {#instance-runners}

GitLab.com, GitLab Self-Managed 및 GitLab Dedicated의 자체 호스팅 인스턴스 러너의 인스턴스 러너의 경우:

- [인스턴스 러너 사용 대시보드](instance_runner_compute_minutes.md#view-usage)에서 사용량을 확인할 수 있습니다.
- 할당량이 활성화된 경우:
  - 할당량 한도에 접근할 때 알림을 받습니다.
  - 할당량을 초과하면 강제 조치가 적용됩니다.

GitLab.com의 경우:

- 기본 월별 컴퓨팅 할당량은 귀사의 구독 티어에 따라 결정됩니다. Free 티어 네임스페이스는 월당 400 컴퓨팅 분을 받습니다. 유료 티어는 더 높은 월별 할당량을 받습니다.
- 필요한 경우 [추가 컴퓨팅 분을 구매](../../subscriptions/gitlab_com/compute_minutes.md)할 수 있습니다.

## 컴퓨팅 분 사용 {#compute-minute-usage}

### 컴퓨팅 사용 계산 {#compute-usage-calculation}

각 작업에 대한 컴퓨팅 분 사용량은 다음 공식으로 계산됩니다:

```plaintext
Job duration / 60 * Cost factor
```

- **Job duration**: 작업이 실행되는 데 걸린 시간(초)입니다. `created` 또는 `pending` 상태에서 소비한 시간은 포함되지 않습니다.
- **Cost factor**: [러너 유형](#cost-factors) 및 [프로젝트 유형](#cost-factors)을 기반으로 한 숫자입니다.

값은 컴퓨팅 분으로 변환되어 작업의 최상위 네임스페이스에서 사용된 단위 수에 추가됩니다.

예를 들어 사용자 `alice`이 파이프라인을 실행하는 경우:

- `gitlab-org` 네임스페이스의 프로젝트에서 파이프라인의 각 작업에서 사용한 컴퓨팅 분은 `gitlab-org` 네임스페이스의 전체 사용량에 추가되며, `alice` 네임스페이스에는 추가되지 않습니다.
- 그들의 `alice` 네임스페이스에 있는 개인 프로젝트에서 컴퓨팅 분은 네임스페이스의 전체 사용량에 추가됩니다.

하나의 파이프라인이 사용하는 컴퓨팅은 파이프라인에서 실행된 모든 작업에서 사용한 총 컴퓨팅 분입니다. 작업은 동시에 실행될 수 있으므로 총 컴퓨팅 사용량은 파이프라인의 종단간 기간보다 높을 수 있습니다.

[트리거 작업](../yaml/_index.md#trigger)은 러너에서 실행되지 않으므로 [`strategy:depend`](../yaml/_index.md#triggerstrategy)을 사용하여 [다운스트림 파이프라인](downstream_pipelines.md) 상태를 기다릴 때에도 컴퓨팅 분을 소비하지 않습니다. 트리거된 다운스트림 파이프라인은 다른 파이프라인과 동일한 방식으로 컴퓨팅 분을 소비합니다.

사용량은 월별로 추적됩니다. 월의 첫 날에 모든 네임스페이스에 대해 해당 월의 사용량이 `0`입니다.

### 비용 계수 {#cost-factors}

컴퓨팅 분이 소비되는 속도는 러너 유형과 프로젝트 설정에 따라 다릅니다.

#### GitLab.com용 호스팅 러너의 비용 계수 {#cost-factors-of-hosted-runners-for-gitlabcom}

GitLab 호스팅 러너의 비용 계수는 러너 유형(Linux, Windows, macOS) 및 가상 머신 구성에 따라 다릅니다:

| 러너 유형                | 머신 크기           | 비용 계수             |
|:---------------------------|:-----------------------|:------------------------|
| Linux x86-64(기본값)     | `small`                | `1`                     |
| Linux x86-64               | `medium`               | `2`                     |
| Linux x86-64               | `large`                | `3`                     |
| Linux x86-64               | `xlarge`               | `6`                     |
| Linux x86-64               | `2xlarge`              | `12`                    |
| Linux x86-64 + GPU 활성화 | `medium`, GPU 표준 | `7`                     |
| Linux Arm64                | `small`                | `1`                     |
| Linux Arm64                | `medium`               | `2`                     |
| Linux Arm64                | `large`                | `3`                     |
| macOS M1                   | `medium`               | `6`(**상태**: 베타)  |
| macOS M2 Pro               | `large`                | `12`(**상태**: 베타) |
| Windows                    | `medium`               | `1`(**상태**: 베타)  |

이러한 비용 계수는 GitLab.com용 호스팅 러너에 적용됩니다.

프로젝트 유형에 따라 특정 할인이 적용됩니다:

| 프로젝트 유형 | 비용 계수 | 사용된 컴퓨팅 분 |
|--------------|-------------|---------------------|
| 표준 프로젝트 | [러너 유형을 기반으로 함](#cost-factors-of-hosted-runners-for-gitlabcom) | 1분(작업 기간 / 60 × 비용 계수) |
| [GitLab for Open Source program](../../subscriptions/community_programs.md#gitlab-for-open-source)의 공개 프로젝트 | `0.5` | 작업 시간 2분당 1분 |
| [GitLab Open Source program 프로젝트의 공개 포크](../../subscriptions/community_programs.md#gitlab-for-open-source) | `0.008` | 작업 시간 125분당 1분 |
| [GitLab 프로젝트에 대한 커뮤니티 기여](#community-contributions-to-gitlab-projects) | 동적 할인 | 다음 섹션을 참조하세요 |

#### GitLab 프로젝트에 대한 커뮤니티 기여 {#community-contributions-to-gitlab-projects}

커뮤니티 기여자는 GitLab에서 유지 관리하는 오픈 소스 프로젝트에 기여할 때 인스턴스 러너에서 최대 300,000분을 사용할 수 있습니다. GitLab 제품의 일부인 프로젝트에만 기여하는 경우에만 최대 300,000분이 가능합니다.

인스턴스 러너에서 사용 가능한 총 분 수는 다른 프로젝트의 파이프라인에서 사용한 컴퓨팅 분으로 인해 감소됩니다. 300,000분은 모든 GitLab.com 티어에 적용됩니다.

비용 계수 계산은 다음과 같습니다:

- `Monthly compute quota / 300,000 job duration minutes = Cost factor`

예를 들어 Premium 티어에서 월별 컴퓨팅 할당량이 10,000인 경우:

- 10,000 / 300,000 = 0.03333333333 비용 계수입니다.

이 감소된 비용 계수의 경우:

- 머지 리퀘스트 소스 프로젝트는 [`gitlab-com/www-gitlab-com`](https://gitlab.com/gitlab-com/www-gitlab-com) 또는 [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab) 등 GitLab 유지 관리 프로젝트의 포크여야 합니다.
- 머지 리퀘스트 대상 프로젝트는 포크의 상위 프로젝트여야 합니다.
- 파이프라인은 머지 리퀘스트, 머지된 결과 또는 머지 트레인 파이프라인이어야 합니다.

### 컴퓨팅 분 사용 감소 {#reduce-compute-minute-usage}

프로젝트가 너무 많은 컴퓨팅 분을 소비하면 사용량을 줄이기 위해 이러한 전략을 시도하세요:

- 프로젝트 미러를 사용하는 경우 [미러 업데이트 파이프라인](../../user/project/repository/mirror/pull.md#trigger-pipelines-for-mirror-updates)이 비활성화되어 있는지 확인합니다.
- [예약된 파이프라인](schedules.md)의 빈도를 줄입니다.
- 필요하지 않을 때 [파이프라인을 건너뜁니다](_index.md#skip-a-pipeline).
- 새로운 파이프라인이 시작될 때 자동으로 취소될 수 있는 [중단 가능한](../yaml/_index.md#interruptible) 작업을 사용합니다.
- 작업이 모든 파이프라인에서 실행될 필요가 없는 경우 [`rules`](../jobs/job_control.md)을 사용하여 필요할 때만 실행되도록 합니다.
- 일부 작업에 대해 [개인 러너 사용](../runners/runners_scope.md#group-runners)합니다.
- 포크에서 작업 중이고 상위 프로젝트에 머지 리퀘스트를 제출하는 경우 유지 관리자에게 [상위 프로젝트에서](merge_request_pipelines.md#run-pipelines-in-the-parent-project) 파이프라인을 실행하도록 요청할 수 있습니다.

오픈 소스 프로젝트를 관리하는 경우 이러한 개선 사항은 기여자 포크 프로젝트의 컴퓨팅 분 사용을 줄일 수 있으며 더 많은 기여를 가능하게 합니다.

자세한 내용은 [파이프라인 효율성 가이드](pipeline_efficiency.md)를 참조하세요.
