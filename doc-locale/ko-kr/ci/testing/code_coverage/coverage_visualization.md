---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Cobertura 또는 JaCoCo 보고서를 사용하여 머지 리퀘스트 diff에서 줄별 테스트 커버리지 주석을 표시합니다.
title: 커버리지 시각화
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report) 키워드를 사용하여 머지 리퀘스트 diff에서 줄별 커버리지 주석을 표시합니다.

이 키워드는 diff 주석만 표시합니다. 머지 리퀘스트 위젯에 커버리지 백분율을 표시하거나 커버리지 기록 그래프를 채우지 않습니다. 커버리지 백분율을 표시하려면 [`coverage`](../../yaml/_index.md#coverage) 키워드를 별도로 구성합니다.

파이프라인이 완료된 후 GitLab은 보고서를 백그라운드에서 처리하고 머지 리퀘스트 diff의 줄에 주석을 추가합니다:

- 녹색: 줄이 테스트로 커버됩니다.
- 빨간색: 줄이 테스트로 커버되지 않습니다.
- 주황색(Cobertura만 해당): 줄이 로드되지만 실행되지 않습니다.

주석은 머지 리퀘스트 diff에서 변경된 파일에만 표시됩니다. 머지 리퀘스트에서 변경되지 않은 파일은 보고서에 해당 파일의 커버리지 데이터가 포함되어 있어도 주석이 표시되지 않습니다.

## 커버리지 시각화 구성 {#configure-coverage-visualization}

커버리지 시각화를 구성하려면 `artifacts:reports:coverage_report`을 작업에 추가합니다:

```yaml
test:
  script:
    - run tests with coverage
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura  # or jacoco
        path: coverage/coverage.xml
```

언어별 예제를 보려면:

- [Cobertura](cobertura.md)
- [JaCoCo](jacoco.md)

여러 보고서를 수집하려면 [아티팩트 경로의 와일드카드](../../jobs/job_artifacts.md#with-wildcards)를 사용합니다. GitLab은 결과를 단일 보고서로 병합합니다.

하위 파이프라인의 커버리지 보고서는 머지 리퀘스트 diff 주석에 나타납니다.

## 제한 사항 {#limits}

| 한도                                            | 값 |
| ------------------------------------------------ | ----- |
| 최대 Cobertura XML 파일 크기                  | 10 MiB |
| Cobertura XML 파일의 최대 `<source>` 노드 수 | 100   |

Cobertura 보고서가 100개의 `<source>` 노드를 초과하면 diff 뷰에서 주석이 누락되거나 일치하지 않을 수 있습니다. 큰 프로젝트의 경우 보고서를 더 작은 파일로 분할합니다. 자세한 내용은 [이슈 328772](https://gitlab.com/gitlab-org/gitlab/-/issues/328772)를 참조합니다.

시각화는 파이프라인이 완료된 후에만 나타납니다. 파이프라인에 [수동 작업 차단](../../jobs/job_control.md#types-of-manual-jobs)이 있으면 해당 작업이 실행될 때까지 시각화를 사용할 수 없습니다.

작업 세부 정보 페이지에서 커버리지 보고서를 다운로드하려면 아티팩트 `paths` 및 `reports`에 추가합니다:

```yaml
artifacts:
  paths:
    - coverage/cobertura-coverage.xml
  reports:
    coverage_report:
      coverage_format: cobertura
      path: coverage/cobertura-coverage.xml
```

## 경로 해석 {#path-resolution}

커버리지 보고서는 상대 파일 경로를 사용합니다. GitLab은 머지 리퀘스트에서 변경된 파일과 비교하여 이를 절대 리포지토리 경로로 해석합니다.

JaCoCo의 경우 매칭 프로세스는 다음과 같습니다:

1. 동일한 파이프라인 ref에 대한 모든 머지 리퀘스트를 찾습니다.
1. 변경된 모든 파일에 대해 절대 경로를 수집합니다.
1. 보고서의 각 상대 경로에 대해 첫 번째 일치하는 절대 경로를 사용합니다.

Cobertura의 경우 GitLab은 `<sources>` 요소를 사용하여 경로를 재구성합니다:

1. 각 `<source>` 항목에서 경로 세그먼트를 추출합니다.
1. 각 세그먼트를 각 `<class>` 요소의 `filename` 속성과 결합합니다.
1. 후보 경로가 리포지토리에 있는지 확인합니다.
1. 첫 번째 일치를 절대 경로로 사용합니다.

이 자동 수정은 `<source>` 경로가 `<CI_BUILDS_DIR>/<PROJECT_FULL_PATH>/...` 형식을 따를 때만 작동합니다.

### 경로 해석 예제 {#path-resolution-example}

전체 경로가 `test-org/test-cs-project`이고 프로젝트 루트를 기준으로 한 파일인 C# 프로젝트의 경우:

```plaintext
Auth/User.cs
Lib/Utils/User.cs
```

Cobertura XML의 `sources`이 있을 경우:

```xml
<sources>
  <source>/builds/test-org/test-cs-project/Auth</source>
  <source>/builds/test-org/test-cs-project/Lib/Utils</source>
</sources>
```

파서는 `sources`에서 `Auth` 및 `Lib/Utils`를 추출한 다음 각 `<class>` 요소의 `filename` 속성과 각각을 결합합니다. `filename="User.cs"`인 클래스의 경우 리포지토리의 파일과 일치하는 첫 번째 후보는 `Auth/User.cs`입니다.

각 `<class>` 요소에 대해 파서는 최대 100회 반복을 시도합니다. 일치하는 항목이 없으면 클래스가 최종 커버리지 보고서에 포함되지 않습니다.

## 문제 해결 {#troubleshooting}

커버리지 시각화로 작업할 때 다음 이슈가 발생할 수 있습니다.

### Diff 주석이 나타나지 않습니다 {#diff-annotations-do-not-appear}

주석이 다음 이유로 나타나지 않을 수 있습니다:

- 파이프라인이 완료되지 않았습니다. 주석은 파이프라인이 완료된 후에 생성됩니다. 파이프라인이 완료될 때까지 기다린 다음 머지 리퀘스트 diff를 다시 로드합니다.
- 파일이 머지 리퀘스트 diff에 없습니다. 주석은 머지 리퀘스트에서 변경된 파일에만 표시되며, 보고서에 다른 파일의 커버리지 데이터가 포함되어 있어도 마찬가지입니다.
- 보고서의 파일 경로가 리포지토리 경로와 일치하지 않습니다. 경로 해석이 실패하면 주석이 자동으로 건너뜁니다. 진단하려면 커버리지 XML 아티팩트를 다운로드하고 `<class>` 요소의 `filename` 속성을 프로젝트 루트를 기준으로 한 리포지토리의 파일 경로와 비교합니다.
- 프로젝트에 중복 상대 경로가 있는 여러 모듈이 있습니다. 경로가 모듈 전체에서 고유하지 않으면 GitLab이 주석이 어느 파일에 속하는지 해석할 수 없습니다. 모듈 전체에서 상대 경로가 고유한지 확인합니다:

  ```diff
      src/main/java/org/acme/DemoExample.java
    - src/main/other-module/org/acme/DemoExample.java
    + src/main/other-module/org/acme/OtherDemoExample.java
  ```

- `coverage` 키워드가 구성되지 않았습니다. `artifacts:reports:coverage_report`은 머지 리퀘스트 위젯에서 백분율을 생성하지 않습니다. 커버리지 백분율을 표시하려면 `coverage` 키워드를 별도로 구성합니다.

### 변경된 모든 파일에 대해 메트릭이 표시되지 않습니다 {#metrics-do-not-display-for-all-changed-files}

이 이슈는 동일한 소스 브랜치에서 새 머지 리퀘스트를 만들되 다른 대상 브랜치를 사용할 때 발생합니다. 파이프라인은 이전 머지 리퀘스트의 diff를 사용하며 해당 diff에 없는 파일의 주석을 표시하지 않습니다.

이 이슈를 해결하려면 새 머지 리퀘스트가 생성될 때까지 기다린 다음 파이프라인을 다시 실행합니다.
