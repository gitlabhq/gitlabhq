---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Eco CI를 사용하여 CI/CD 파이프라인의 에너지 소비량과 탄소 배출량을 측정합니다.
title: Eco CI
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> Eco CI는 GitLab CI/CD 파이프라인과 통합되는 타사 도구입니다. GitLab은 이 도구를 유지 관리하거나 지원하지 않으며, 이 도구가 규제 또는 규정 준수 요구 사항을 충족한다는 보장을 하지 않습니다.

[Eco CI](https://www.green-coding.io/products/eco-ci/)는 CI/CD 파이프라인의 에너지 소비량과 탄소 배출량을 측정하는 오픈 소스 도구입니다. 파이프라인 작업 내에서 간단한 bash 스크립트로 실행되며 별도의 서버나 데이터베이스가 필요하지 않습니다.

파이프라인 작업의 명령 전후에 측정 스크립트를 배치합니다. 이 도구는 명령 실행 중 CPU 사용률을 모니터링하고 SPECpower 데이터베이스의 사전 계산된 전력 곡선을 사용하여 에너지 소비량을 계산합니다. 모든 측정 결과를 텍스트 파일로 저장하여 작업 아티팩트로 저장하고 다운로드 및 확인할 수 있습니다. 결과를 외부 대시보드로 보내 과거 데이터를 분석할 수도 있습니다.

## 파이프라인에 Eco CI 추가 {#add-eco-ci-to-your-pipeline}

작업 실행 중 에너지 소비량과 탄소 배출량을 측정하기 위해 파이프라인에 Eco CI를 추가합니다.

Eco CI는 `ECO_CI_LABEL` 변수를 사용하여 측정값을 식별하고 그룹화하므로 프로젝트 또는 파이프라인 스테이지를 나타내는 설명적인 이름을 선택합니다. 기본적으로 측정 데이터는 분석을 위해 Green Coding Solutions 대시보드로 전송되지만 `ECO_CI_SEND_DATA`를 `false`로 설정하여 결과를 로컬에만 저장할 수 있습니다.

전제 조건:

- bash 지원이 있는 러너에서 실행되는 파이프라인 작업입니다.
- `curl`, `jq`, `awk`, `bash`, `git`, `coreutils` 유틸리티가 있는 러너 환경입니다.

파이프라인에 Eco CI를 추가하려면:

1. `.gitlab-ci.yml` 파일에서 Eco CI 템플릿을 포함하고 프로젝트 식별자를 구성합니다:

   ```yaml
   variables:
     ECO_CI_LABEL: "my-project-pipeline"
     ECO_CI_SEND_DATA: "false"

   include:
     - remote: 'https://raw.githubusercontent.com/green-coding-solutions/eco-ci-energy-estimation/main/eco-ci-gitlab.yml'
   ```

1. 작업에 측정 스크립트를 추가합니다:

   ```yaml
   build-job:
     image: node:alpine
     before_script:
       - apk add --no-cache curl jq gawk bash git coreutils
     script:
       - !reference [.start_measurement, script]
       - npm install
       - npm run build
       - npm test
       - !reference [.get_measurement, script]
       - !reference [.display_results, script]
     artifacts:
       paths:
         - eco-ci-output.txt
         - metrics.txt
       expire_in: 1 week
   ```

1. 선택 사항. 명령을 별도로 측정하려면 각 명령에 대해 측정 스크립트를 사용합니다:

   ```yaml
   build-job:
     image: node:alpine
     before_script:
       - apk add --no-cache curl jq gawk bash git coreutils
     script:
       - !reference [.start_measurement, script]
       - npm install
       - !reference [.get_measurement, script]
       - !reference [.display_results, script]

       - !reference [.start_measurement, script]
       - npm run build
       - !reference [.get_measurement, script]
       - !reference [.display_results, script]

       - !reference [.start_measurement, script]
       - npm test
       - !reference [.get_measurement, script]
       - !reference [.display_results, script]
     artifacts:
       paths:
         - eco-ci-output.txt
         - metrics.txt
       expire_in: 1 week
   ```

## 측정 결과 확인 {#view-measurement-results}

Eco CI는 측정 결과를 작업 아티팩트에 저장하여 GitLab 인터페이스를 통해 액세스할 수 있습니다. 측정 결과에는 다음이 포함됩니다:

- 에너지 소비량: 줄과 와트로 표시됨
- 탄소 배출량: CO₂ 동등량(gCO₂eq)의 그램 단위로 추정된 배출량
- 지속 시간: 측정된 기간의 길이(초 단위)
- CPU 사용률: 측정 중 평균 CPU 사용량
- 소프트웨어 탄소 강도(SCI): 파이프라인 실행당 탄소 배출량

측정 결과를 확인하려면:

1. 파이프라인으로 이동합니다.
1. Eco CI 측정을 포함하는 작업을 선택합니다.
1. 작업 세부 사항의 **작업 아티팩트** 아래에서 **탐색**을 선택합니다.
1. `eco-ci-output.txt` 파일을 엽니다.

출력 예시:

```plaintext
"build-job: Label: my-project-pipeline: Energy Used [Joules]:" 5.82
"build-job: Label: my-project-pipeline: Avg. CPU Utilization:" 22.69
"build-job: Label: my-project-pipeline: Avg. Power [Watts]:" 1.91
"build-job: Label: my-project-pipeline: Duration [seconds]:" 3.04
----------------
"build-job: Energy [Joules]:" 5.82
"build-job: Avg. CPU Utilization:" 22.69
"build-job: Avg. Power [Watts]:" 1.91
"build-job: Duration [seconds]:" 3.04
----------------
🌳 CO2 Data:
CO₂ from energy is: 0.001944 g
CO₂ from manufacturing (embodied carbon) is: 0.000442 g
Carbon Intensity for this location: 334 gCO₂eq/kWh
SCI: 0.002386 gCO₂eq / pipeline run emitted
```

## 대시보드 통합 {#dashboard-integration}

`ECO_CI_SEND_DATA`을 `true`로 설정하면 측정 데이터가 자동으로 [Eco CI 메트릭 대시보드](https://metrics.green-coding.io/ci-index.html)로 전송됩니다. 대시보드는 과거 기록, 추세 분석, 파이프라인 실행 간 비교를 제공합니다. 기본적으로 대시보드는 공개이며 누구나 볼 수 있습니다.

시간 경과에 따른 에너지 소비 추세, 탄소 배출 패턴을 확인하고 다양한 브랜치, 커밋 또는 기간 간 측정값을 비교할 수 있습니다. 프로젝트의 `ECO_CI_LABEL` 식별자를 사용하여 대시보드에 액세스합니다.

### 프로젝트에 배지 추가 {#add-a-badge-to-your-project}

프로젝트의 `README.md` 파일에 Eco CI 배지를 표시하여 에너지 소비 메트릭을 나타낼 수 있습니다.

전제 조건:

- `ECO_CI_SEND_DATA`을 `true`로 설정해야 합니다.
- 최소 1개의 파이프라인이 Eco CI 활성화 상태에서 성공적으로 실행되어야 합니다.

`README.md` 파일에 배지를 추가하려면:

1. 다음을 `README.md` 파일에 복사하여 붙여넣습니다:

   ```markdown
   [![Eco CI](https://api.green-coding.io/v1/ci/badge/get?repo=<namespace>/<project>&branch=<branch>&workflow=<project-id>)](https://metrics.green-coding.io/ci.html?repo=<namespace>/<project>&branch=<branch>&workflow=<project-id>)
   ```

1. 자리 표시자를 바꿉니다:

   - `<namespace>/<project>`을 GitLab 프로젝트 경로로 바꿉니다(예: `mygroup/myproject`).
   - `<branch>`을 브랜치 이름으로 바꿉니다(예: `main`).
   - `<project-id>`을 GitLab 프로젝트 ID로 바꿉니다(예: `52215136`).

예:

```markdown
[![Eco CI](https://api.green-coding.io/v1/ci/badge/get?repo=lyspin/eco-ci-demo&branch=main&workflow=52215136)](https://metrics.green-coding.io/ci.html?repo=lyspin/eco-ci-demo&branch=main&workflow=52215136)
```

## 문제 해결 {#troubleshooting}

Eco CI를 사용하여 작업할 때 다음 이슈가 발생할 수 있습니다.

### 오류: 날짜가 마이크로초 정밀도로 정확하지 않은 타임스탬프를 반환했습니다 {#error-date-has-returned-a-timestamp-that-is-not-accurate-to-microseconds}

다음과 같은 오류 메시지가 표시될 수 있습니다:

```shell
ERROR: Date has returned a timestamp that is not accurate to microseconds! You may need to install `coreutils`.
```

이 이슈는 Alpine Linux 또는 기본적으로 GNU `coreutils`을 포함하지 않는 기타 최소 배포판을 사용할 때 발생합니다.

이 이슈를 해결하려면 `coreutils`을 설치합니다. 예를 들어 Alpine의 경우:

```yaml
before_script:
  - apk add --no-cache coreutils
```

### 작업 아티팩트에 측정 데이터가 나타나지 않음 {#no-measurement-data-appears-in-artifacts}

`eco-ci-output.txt` 파일이 작업 아티팩트에 표시되지 않습니다.

이 이슈는 누락된 아티팩트 구성으로 인해 발생할 수 있으므로 작업에 올바른 `artifacts` 구성이 포함되어 있는지 확인합니다:

```yaml
artifacts:
  paths:
    - eco-ci-output.txt
    - metrics.txt
```

### 측정값이 0 에너지 소비를 표시합니다 {#measurements-show-zero-energy-consumption}

`eco-ci-output.txt` 파일에 `Energy [Joules]: 0.00`와 같은 값이 표시됩니다.

이 이슈는 측정 스크립트가 잘못 배치되었을 때 발생합니다.

이 이슈를 해결하려면 측정 스크립트가 CPU 집약적인 명령을 감싸는지 확인합니다:

```yaml
script:
  - !reference [.start_measurement, script]
  - npm install  # CPU-intensive command
  - npm run build  # CPU-intensive command
  - !reference [.get_measurement, script]
  - !reference [.display_results, script]
```
