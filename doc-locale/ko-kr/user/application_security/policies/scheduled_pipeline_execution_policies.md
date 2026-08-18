---
stage: Security Risk Management
group: Security Policies
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 예약된 파이프라인 실행 정책
---

{{< details >}}

- 티어: Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 18.0에서 실험적 기능으로 [도입](https://gitlab.com/groups/gitlab-org/-/epics/14147)되었으며 `scheduled_pipeline_execution_policy_type` 플래그가 `policy.yml` 파일에 정의되어 있습니다.
- GitLab 18.2에서 베타로 [변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/238197)되었습니다.
- GitLab 19.2에서 [일반적으로 사용 가능](https://gitlab.com/groups/gitlab-org/-/work_items/17875)합니다.

{{< /history >}}

파이프라인 실행 정책은 프로젝트의 파이프라인에서 사용자 정의 CI/CD 작업을 적용합니다. 예약된 파이프라인 실행 정책을 사용하면 CI/CD 작업을 정기적으로(매일, 매주 또는 매월) 실행하도록 적용을 확장하여 새로운 커밋이 없더라도 규정 준수 스크립트, 보안 스캔 또는 기타 사용자 정의 CI/CD 작업이 실행되도록 할 수 있습니다.

## 파이프라인 실행 정책 일정 설정 {#scheduling-your-pipeline-execution-policies}

기존 파이프라인에 작업을 주입하거나 재정의하는 일반 파이프라인 실행 정책과 달리 예약된 정책은 정의한 일정에 따라 독립적으로 실행되는 새로운 파이프라인을 만듭니다. 예약된 파이프라인은 프로젝트의 `.gitlab-ci.yml`과는 별개이며 프로젝트의 CI/CD 작업을 실행하지 않습니다.

일반적인 사용 사례는 다음과 같습니다.

- 규정 준수 요구 사항을 충족하기 위해 보안 스캔을 정기적으로 실행합니다.
- 프로젝트 구성을 정기적으로 확인합니다.
- 비활성 리포지토리에서 종속성 스캔을 실행하여 새로 발견된 취약점을 감지합니다.
- 규정 준수 보고 스크립트를 일정에 따라 실행합니다.

## 스케줄된 파이프라인 실행 정책 테스트 {#test-a-scheduled-pipeline-execution-policy}

스케줄된 파이프라인 실행 정책을 모든 프로젝트에 적용하기 전에 테스트를 실행하여 파이프라인이 작동하는지 확인하고 정책이 인프라에 어떤 영향을 미치는지 파악할 수 있습니다. 테스트 실행은 실제 파이프라인을 실행하여 정확한 타이밍 및 리소스 예상 값을 제공합니다.

> [!note]
> 테스트 실행은 실제 파이프라인을 생성하며 대상 프로젝트에 대한 컴퓨팅 분 단위를 소비합니다.

테스트를 실행하려면:

1. 왼쪽 사이드바에서 **보안** > **정책**을 선택합니다.
1. 테스트하려는 스케줄된 파이프라인 실행 정책을 선택합니다.
1. **테스트 실행** 탭을 선택합니다.
1. 그룹 수준에서 정책을 보고 있으면 드롭다운 목록에서 대상 프로젝트를 선택합니다.
1. **테스트 실행 시작**을 선택합니다.

테스트 실행은 정책의 CI/CD 구성을 사용하여 선택한 프로젝트에서 파이프라인을 생성합니다. **테스트 실행** 탭에서 테스트 실행 상태를 모니터링할 수 있습니다.

테스트 실행이 완료되면 **테스트 실행** 탭에 지속 시간 및 오류 메시지를 포함한 결과가 표시됩니다.

## 일정 파이프라인 실행 정책 구성 {#configure-schedule-pipeline-execution-policies}

예약된 파이프라인 실행 정책을 구성하려면 보안 정책 프로젝트의 `.gitlab/security-policies/policy.yml` 파일에서 `pipeline_execution_schedule_policy` 섹션에 추가 구성 필드를 추가합니다.

```yaml
pipeline_execution_schedule_policy:
- name: Scheduled Pipeline Execution Policy
  description: ''
  enabled: true
  content:
    include:
    - project: your-group/your-project
      file: security-scan.yml
  schedules:
  - type: daily
    start_time: '10:00'
    time_window:
      value: 600
      distribution: random
```

### 일정 구성 스키마 {#schedule-configuration-schema}

`schedules` 섹션에서 보안 정책 작업이 자동으로 실행되는 시간을 구성할 수 있습니다. 특정 실행 시간 및 분배 시간 범위를 사용하여 매일, 매주 또는 매월 일정을 만들 수 있습니다.

### 일정 구성 옵션 {#schedules-configuration-options}

`schedules` 섹션은 다음 옵션을 지원합니다.

| 매개변수 | 설명 |
|-----------|-------------|
| `type` | 일정 유형: `daily`, `weekly` 또는 `monthly` |
| `start_time` | 24시간 형식(HH:MM)으로 일정을 시작할 시간 |
| `time_window` | 파이프라인 실행을 분배할 시간 범위 |
| `time_window.value` | 초 단위 기간(최소: 600, 최대: 2629746) |
| `time_window.distribution` | 분배 방법(현재 `random`만 지원됨) |
| `timezone` | IANA 표준 시간대 식별자(지정되지 않은 경우 기본값은 UTC) |
| `branches` | 파이프라인을 예약할 브랜치 이름의 선택적 배열입니다. `branches`이 지정되면 파이프라인은 지정된 브랜치에서만 실행되고 프로젝트에 존재하는 경우에만 실행됩니다. 지정되지 않으면 파이프라인은 기본 브랜치에서만 실행됩니다. 일정당 최대 5개의 고유한 브랜치 이름을 제공할 수 있습니다. |
| `days` | 주간 일정에서만 사용: 일정이 실행되는 요일의 배열(예: `["Monday", "Friday"]`) |
| `days_of_month` | 월간 일정에서만 사용: 일정이 실행되는 날짜의 배열(예: `[1, 15]`, 1~31의 값 포함 가능) |
| `snooze` | 일정을 임시로 일시 중지하는 선택적 구성 |
| `snooze.until` | 일시 중지 후 일정이 다시 시작되는 ISO8601 날짜 및 시간(형식: `2025-06-13T20:20:00+00:00`) |
| `snooze.reason` | 일정이 일시 중지된 이유를 설명하는 선택적 문서 |

### 일정 예제 {#schedule-examples}

매일, 매주 또는 매월 일정을 사용합니다.

#### 매일 일정 예제 {#daily-schedule-example}

```yaml
schedules:
  - type: daily
    start_time: "01:00"
    time_window:
      value: 3600  # 1 hour window
      distribution: random
    timezone: "America/New_York"
    branches:
      - main
      - develop
      - staging
```

#### 주간 일정 예제 {#weekly-schedule-example}

```yaml
schedules:
  - type: weekly
    days:
      - Monday
      - Wednesday
      - Friday
    start_time: "04:30"
    time_window:
      value: 7200  # 2 hour window
      distribution: random
    timezone: "Europe/Berlin"
```

#### 월간 일정 예제 {#monthly-schedule-example}

```yaml
schedules:
  - type: monthly
    days_of_month:
      - 1
      - 15
    start_time: "02:15"
    time_window:
      value: 14400  # 4 hour window
      distribution: random
    timezone: "Asia/Tokyo"
```

### 시간 범위 분배 {#time-window-distribution}

여러 프로젝트에 정책을 적용할 때 CI/CD 인프라가 과부하되는 것을 방지하기 위해 예약된 파이프라인 실행 정책은 일반적인 규칙에 따라 시간 범위 전체에 파이프라인 생성을 분배합니다.

- 모든 파이프라인은 `random`에서 예약됩니다. 파이프라인은 지정된 시간 범위 동안 임의로 분배됩니다.
- 최소 시간 범위는 10분(600초)이고 최대값은 약 1개월(2,629,746초)입니다.
- 월간 일정의 경우 특정 달에 존재하지 않는 날짜(예: 2월의 31일)를 지정하면 해당 실행이 건너뜁니다.
- 보안 정책 프로젝트는 최대 5개의 예약된 파이프라인 실행 정책을 포함할 수 있습니다.
- 예약된 정책은 한 번에 하나의 일정 구성만 가질 수 있습니다.
- 예약된 정책은 최대 5개의 브랜치를 대상으로 할 수 있습니다. `branches`을 생략하면 정책은 프로젝트 기본 브랜치에서만 실행됩니다.
- 정책을 여러 프로젝트에 적용할 때 사용 가능한 러너 용량을 기반으로 프로젝트 수를 수용할 수 있을 만큼 충분히 큰 시간 범위를 확인합니다. 예를 들어 1시간 시간 범위를 사용하는 1000개 프로젝트에 적용되는 정책은 해당 시간 전체에 파이프라인 생성을 고르게 분배합니다(약 분당 16개의 파이프라인). 러너가 이 파이프라인 생성 속도를 처리할 수 있는지 확인하거나 대기열 또는 지연을 방지하기 위해 더 큰 시간 범위를 선택합니다.
- 월간 일정의 경우 시간 범위 동안의 임의 분배로 인해 연속 실행 간의 간격이 달라질 수 있습니다. 예를 들어 월간 일정은 이전 실행 후 20일, 그 다음 30일 후에 실행될 수 있습니다. 이 분배는 인프라 전체에 부하를 분배하는 데 도움이 되므로 예상된 동작입니다.

## 예약된 파이프라인 실행 정책 일시 중지 {#snooze-scheduled-pipeline-execution-policies}

일시 중지 기능을 사용하여 예약된 파이프라인 실행 정책을 임시로 일시 중지할 수 있습니다. 유지 관리 기간, 휴일 동안 또는 특정 기간 동안 예약된 파이프라인이 실행되는 것을 방지해야 할 때 일시 중지 기능을 사용합니다.

### 일시 중지 작동 방식 {#how-snoozing-works}

예약된 파이프라인 실행 정책을 일시 중지하면:

- 일시 중지 기간 동안 새로운 예약된 파이프라인이 생성되지 않습니다.
- 일시 중지 전에 생성된 파이프라인은 계속 실행됩니다.
- 정책은 사용되지만 일시 중지된 상태로 유지됩니다.
- 일시 중지 기간이 만료된 후 예약된 파이프라인 실행이 자동으로 재개됩니다.

### 일시 중지 구성 {#configuring-snooze}

예약된 파이프라인 실행 정책을 일시 중지하려면 일정 구성에 `snooze` 섹션을 추가합니다.

```yaml
pipeline_execution_schedule_policy:
- name: Weekly Security Scan
  description: 'Run security scans every week'
  enabled: true
  content:
    include:
    - project: your-group/your-project
      file: security-scan.yml
  schedules:
  - type: weekly
    start_time: '02:00'
    time_window:
      value: 3600
      distribution: random
    timezone: UTC
    days:
      - Monday
    snooze:
      until: "2025-06-26T16:27:00+00:00"  # ISO8601 format
      reason: "Critical production deployment"
```

`snooze.until` 매개변수는 ISO8601 형식을 사용하여 일시 중지 기간이 끝나는 시간을 지정합니다. `YYYY-MM-DDThh:mm:ss+00:00` 여기서:

- `YYYY-MM-DD`: 연도, 월, 일
- `T`: 날짜와 시간 사이의 구분자
- `hh:mm:ss`: 24시간 형식의 시간, 분, 초
- `+00:00`: UTC의 시간대 오프셋(또는 UTC의 경우 Z)

예를 들어 `2025-06-26T16:27:00+00:00`은 2025년 6월 26일 오후 4시 27분 UTC를 나타냅니다.

### 일시 중지 제거 {#removing-a-snooze}

만료 시간 전에 일시 중지를 제거하려면 정책 구성에서 `snooze` 섹션을 제거하거나 `until` 값에 과거 날짜를 설정합니다.

## CI/CD 변수에 대한 액세스 제어 {#control-access-to-cicd-variables}

기본적으로 파이프라인 실행 정책 작업은 프로젝트 또는 그룹 CI/CD 변수에 액세스할 수 없습니다. 이 안전한 기본값은 정책이 의도하지 않게 민감한 프로젝트 구성을 노출하는 것을 방지합니다.

정책 작업이 프로젝트 및 그룹 CI/CD 변수에 액세스할 수 있도록 하려면 정책 구성에 `variables_override` 옵션을 추가합니다:

```yaml
pipeline_execution_schedule_policy:
- name: Scheduled Security Scan
  description: 'Run security scans with access to project variables'
  enabled: true
  content:
    include:
    - project: your-group/your-project
      file: security-scan.yml
  variables_override:
    allowed: true
  schedules:
  - type: daily
    start_time: '02:00'
    time_window:
      value: 3600
      distribution: random
```

### `variables_override` 구성 옵션 {#variables_override-configuration-options}

| 매개변수 | 설명 |
|-----------|-------------|
| `allowed` | 필수입니다. `true`일 때 정책 작업은 프로젝트 및 그룹 CI/CD 변수에 액세스할 수 있습니다. `false`일 때 이러한 변수에 대한 액세스를 차단합니다. |
| `exceptions` | 선택 사항. 시행에서 제외된 변수 이름의 배열입니다. `allowed: true`일 때 이 목록의 변수가 차단됩니다. `allowed: false`일 때 이 목록의 변수가 허용됩니다. |
| `dotenv` | 선택 사항. dotenv 아티팩트 변수가 정책 규칙을 따르는지 제어합니다. `allow_override`로 설정하여 dotenv 변수가 정책 규칙을 우회하도록 합니다. 기본 동작은 정책 규칙을 준수합니다. |

### `variables_override` 예제 {#variables_override-examples}

특정 항목을 제외한 모든 프로젝트 변수를 차단합니다:

```yaml
variables_override:
  allowed: false
  exceptions:
    - DEPLOY_TOKEN
    - API_KEY
```

민감한 항목을 제외한 모든 프로젝트 변수를 허용합니다:

```yaml
variables_override:
  allowed: true
  exceptions:
    - SECRET_KEY
    - PRIVATE_TOKEN
```

## 특정 브랜치에 대한 파이프라인 일정 설정 {#schedule-pipelines-for-specific-branches}

기본적으로 일정은 기본 브랜치에서만 실행됩니다. 예약된 파이프라인 실행 정책은 브랜치 필터링을 지원하여 추가 브랜치에 대한 파이프라인 일정을 설정할 수 있습니다. `branches` 속성을 사용하여 프로젝트의 다른 중요 브랜치에서 정기적인 스캔 또는 검사를 수행합니다.

일정에서 `branches` 속성을 구성할 때:

- 브랜치를 지정하지 않으면 예약된 파이프라인은 기본 브랜치에서만 실행됩니다.
- 브랜치를 지정하면 정책은 프로젝트에 실제로 존재하는 지정된 각 브랜치에 대해 파이프라인 일정을 설정합니다.
- 일정당 최대 5개의 고유한 브랜치 이름을 지정할 수 있습니다.
- 각 브랜치 이름을 전체 이름으로 지정해야 합니다. 와일드카드 매칭은 지원되지 않습니다.

### 브랜치 필터링 예제 {#branch-filtering-example}

```yaml
pipeline_execution_schedule_policy:
- name: Scan Multiple Branches
  description: 'Run security scans on main, staging and develop branches'
  enabled: true
  content:
    include:
    - project: your-group/your-project
      file: security-scan.yml
  schedules:
  - type: weekly
    days:
      - Monday
    start_time: '02:00'
    time_window:
      value: 3600
      distribution: random
    branches:
      - main
      - staging
      - develop
      - feature/new-authentication
```

이 예제에서 지정된 모든 브랜치가 프로젝트에 존재하면 정책은 4개의 별개 파이프라인을 생성합니다(각 브랜치당 하나).

## 전제 조건 {#prerequisites}

예약된 파이프라인 실행 정책을 사용하려면 프로젝트가 다음 요구 사항을 충족해야 합니다.

- CI/CD 구성 파일은 다음 위치 중 하나에 저장됩니다.
  - 보안 정책 프로젝트
  - 공개 프로젝트
  - 액세스가 사용되는 비공개 프로젝트(참고: [CI/CD 구성 파일에 대한 액세스 사용](#enable-access-to-cicd-configuration-files))
- CI/CD 구성 파일은 예약된 파이프라인에 대한 적절한 워크플로우 규칙을 포함해야 합니다.

## CI/CD 구성 파일에 대한 액세스 사용 {#enable-access-to-cicd-configuration-files}

정책이 CI/CD 구성 파일을 참조할 때 보안 정책 봇이 이에 액세스해야 합니다. 공개 프로젝트의 파일은 기본적으로 액세스할 수 있습니다. 보안 정책 프로젝트 또는 기타 비공개 프로젝트의 파일의 경우 다음 옵션 중 하나를 사용하여 액세스를 사용합니다.

### 옵션 1: 보안 정책 프로젝트의 파일에 대한 액세스 권한 부여 {#option-1-grant-access-to-files-in-the-security-policy-project}

CI/CD 구성 파일이 보안 정책 프로젝트 자체에 저장된 경우 이 옵션을 사용합니다. 이 설정은 파이프라인 실행 정책이 주입된 파이프라인을 트리거하는 모든 사용자에게 적용됩니다.

1. 보안 정책 프로젝트의 왼쪽 사이드바에서 **설정** > **일반**을 선택합니다.
1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
1. **CI/CD 구성에 대한 보안 정책 프로젝트 액세스 권한 부여**를 켭니다.
1. **변경 사항 저장**을 선택합니다.

### 옵션 2: 프라이빗 또는 인터널 프로젝트에 대한 액세스 허용 {#option-2-allow-access-to-private-or-internal-projects}

정책 `include:` 값이 보안 정책 프로젝트 이외의 비공개 또는 내부 프로젝트에 저장된 CI/CD 구성 파일을 참조하는 경우 이 옵션을 사용하세요.

1. CI/CD 파일을 저장하는 비공개 또는 내부 프로젝트에서 왼쪽 사이드바의 **설정** > **일반**을 선택합니다.
1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
1. **파이프라인 실행 정책**에서 **Allow access to CI/CD configuration files in this project**을 선택합니다.
1. **허용된 파일 패턴**에서 액세스할 수 있는 파일을 지정하는 하나 이상의 glob 패턴을 추가하고 쉼표로 구분합니다.
1. 선택 사항. **허용된 그룹**에서 그룹을 선택하여 해당 그룹의 프로젝트 사용자만 CI/CD 구성 파일에 액세스하도록 허용합니다.

   지정하지 않으면 루트 상위 그룹의 모든 프로젝트 사용자가 파일에 액세스할 수 있습니다.
1. **변경 사항 저장**을 선택합니다.

허용된 파일의 glob 패턴은 `include:file:` 값에 지정된 경로와 일치해야 합니다. 예를 들어:

- `include:file: ci/security-scan.yml`의 경우 `ci/**/*.yml` 또는 `ci/security-scan.yml`을 사용합니다.
- `include:file: policy-ci.yml`의 경우 `*.yml` 또는 `policy-ci.yml`을 사용합니다.
- 여러 디렉토리의 경우 `ci/**/*.yml, templates/**/*.yml`과 같이 쉼표로 구분된 여러 패턴을 사용합니다.

## 보안 정책 봇 사용자 {#security-policy-bot-user}

예약된 파이프라인은 보안 정책 프로젝트에 자동으로 생성하는 전용 시스템 계정인 보안 정책 봇 사용자가 실행합니다. 정책 실행이 격리되고 안전하게 유지되도록 봇 사용자는 다음 보안 제한이 있습니다.

- 봇 사용자는 해당 특정 프로젝트의 멤버입니다. 그룹 또는 다른 프로젝트에 추가될 수 없습니다.
- 봇 사용자는 외부 사용자로 취급되며 기본적으로 내부 프로젝트에 액세스할 수 없습니다.
- 봇 사용자는 보안 정책 프로젝트 및 공개 프로젝트의 파일에 액세스할 수 있습니다.
- 봇 사용자는 해당 프로젝트가 **파이프라인 실행 정책** 설정을 명시적으로 활성화하고 파일 경로가 프로젝트에서 지정한 패턴과 일치하는 경우에만 프라이빗 또는 인터널 프로젝트의 파일에 액세스할 수 있습니다.

봇 사용자는 다른 프로젝트의 멤버가 아니므로 다음 작업을 완료할 수 없습니다.

- 액세스를 허용하지 않거나 허용된 파일 패턴과 일치하지 않는 프라이빗 또는 인터널 프로젝트에서 CI/CD 구성 파일에 액세스합니다.
- 비공개 또는 내부 프로젝트를 대상으로 하는 다중 프로젝트 자식 파이프라인을 시작합니다.
- 비공개 또는 내부 프로젝트에서 아티팩트 또는 리소스에 액세스합니다.

> [!important]
프라이빗 또는 인터널 프로젝트의 파일을 포함할 때 해당 프로젝트에서 **파이프라인 실행 정책** 설정을 활성화하고 일치하는 파일 패턴을 설정합니다. 이러한 설정이 없으면 파이프라인 실행이 액세스 오류로 실패합니다.

## 일정 제한 {#scheduling-limits}

스케줄된 파이프라인 실행 정책을 만들 때 다음 제한 사항에 유의하세요.

- 보안 정책 프로젝트당 예약된 파이프라인 실행 정책의 최대 개수는 1개의 정책과 1개의 일정으로 제한됩니다.
- 일정의 최대 빈도는 하루에 한 번(매일)입니다.
- 브랜치를 지정하지 않으면 예약된 파이프라인 실행 정책은 기본 브랜치에서만 실행됩니다.
- `branches` 배열에서 최대 5개의 고유한 브랜치 이름을 지정할 수 있습니다.
- 시간 범위는 파이프라인의 충분한 분배를 보장하기 위해 최소 10분(600초)이어야 합니다.
- 예약된 파이프라인은 사용 가능한 러너가 부족하면 지연될 수 있습니다.

## 문제 해결 {#troubleshooting}

### 첫 번째 예약된 실행이 지연될 수 있음 {#first-scheduled-run-may-be-delayed}

파이프라인 실행 정책을 생성하거나 업데이트하면 백그라운드 워커가 일정 기록을 비동기식으로 생성합니다. 백그라운드 워커 큐에 지연이 발생하면(예: 시스템 부하가 높으면) 백그라운드 워커가 의도한 첫 실행 시간이 지난 후 일정 기록을 생성할 수 있습니다. 이 경우 첫 실행은 즉시가 아니라 다음 예약된 발생 시간에 수행됩니다.

예를 들어 오후 2:00에 오후 6:00 실행을 위해 정책을 생성했지만 백그라운드 워커가 오후 7:00까지 정책을 처리하지 않으면 첫 실행은 다음 날 오후 6:00(또는 일정 구성에 따라 다음 해당 날짜)에 예약됩니다.

이 동작을 해결하려면:

- 의도한 첫 실행 시간보다 훨씬 앞서 정책을 생성합니다.
- [테스트 실행 기능](#test-a-scheduled-pipeline-execution-policy)을 사용하여 첫 예약된 실행 전에 정책이 올바르게 작동하는지 확인합니다.

### 예약된 파이프라인이 실행되지 않음 {#scheduled-pipelines-not-running}

예약된 파이프라인이 예상대로 실행되지 않으면 다음 문제 해결 단계를 따릅니다.

1. **정책 액세스 확인**: 다음을 확인합니다.
   - CI/CD 구성 파일이 보안 정책 프로젝트, 공개 프로젝트 또는 봇 액세스가 활성화되고 파일 패턴이 일치하는 비공개 또는 내부 프로젝트에 있습니다.
   - **파이프라인 실행 정책** 설정이 보안 정책 프로젝트(**설정** > **일반** > **표시 여부, 프로젝트 기능, 권한**)에서 사용되는지 확인합니다.
1. **CI 구성 확인**:
   - CI/CD 구성 파일이 지정된 경로에 존재하는지 확인합니다.
   - 수동 파이프라인을 실행하여 구성이 유효한지 확인합니다.
   - 구성에 예약된 파이프라인에 대한 적절한 워크플로우 규칙이 포함되어 있는지 확인합니다.
1. **정책 구성 확인**:
   - 정책이 사용되는지 확인합니다(`enabled: true`).
   - 일정 구성의 형식이 올바르고 값이 유효한지 확인합니다.
   - 브랜치를 지정한 경우 브랜치가 프로젝트에 존재하는지 확인합니다.
   - 시간대 설정이 올바른지 확인합니다(지정된 경우).
1. **로그 및 활동 검토**:
   - 보안 정책 프로젝트의 CI/CD 파이프라인 로그에서 오류를 확인합니다.
1. **러너 가용성 확인**:
   - 러너가 사용 가능하고 제대로 구성되어 있는지 확인합니다.
   - 러너가 예약된 작업을 처리할 수 있는 용량이 있는지 확인합니다.
