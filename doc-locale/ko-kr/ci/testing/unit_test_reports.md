---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 작업 로그를 검색하지 않고 단위 테스트 결과를 보고 디버깅합니다.
title: 단위 테스트 보고서
---

{{< details >}}

- 티어: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

단위 테스트 보고서는 머지 리퀘스트와 파이프라인 세부 정보에 테스트 결과를 직접 표시하므로 작업 로그를 검색하지 않고 실패를 식별할 수 있습니다.

다음의 경우 단위 테스트 보고서를 사용합니다:

- 머지 리퀘스트에서 테스트 실패를 즉시 확인합니다.
- 브랜치 간 테스트 결과를 비교합니다.
- 오류 세부 정보 및 스크린샷으로 실패한 테스트를 디버깅합니다.
- 시간이 지남에 따라 테스트 실패 패턴을 추적합니다.

단위 테스트 보고서는 JUnit XML 형식이 필요하며 작업 상태에 영향을 주지 않습니다. 테스트가 실패할 때 작업을 실패하게 하려면 작업의 [script](../yaml/_index.md#script)가 0이 아닌 상태로 종료되어야 합니다.

러너는 JUnit XML 형식의 테스트 결과를 [artifacts](../yaml/artifacts_reports.md#artifactsreportsjunit)로 업로드합니다. 머지 리퀘스트로 이동하면 테스트 결과가 소스 브랜치(head)와 대상 브랜치(base) 간에 비교되어 변경 사항이 표시됩니다.

## 파일 형식 및 크기 제한 {#file-format-and-size-limits}

단위 테스트 보고서는 적절한 구문 분석 및 표시를 보장하기 위해 특정 요구 사항이 있는 JUnit XML 형식을 사용해야 합니다.

### 파일 요구 사항 {#file-requirements}

테스트 보고서 파일은 다음을 수행해야 합니다:

- `.xml` 파일 확장명으로 JUnit XML 형식을 사용합니다.
- 개별 파일당 30MB보다 작아야 합니다.
- 작업의 모든 JUnit 파일의 총 크기는 100MB 미만이어야 합니다.

중복된 테스트 이름이 있는 경우 첫 번째 테스트만 사용되고 같은 이름의 다른 테스트는 무시됩니다.

테스트 사례 제한은 [단위 테스트 보고서당 최대 테스트 사례](../../user/gitlab_com/_index.md#cicd)를 참조하세요.

### JUnit XML 형식 사양 {#junit-xml-format-specification}

GitLab은 JUnit XML 요소와 속성의 부분을 구문 분석하여 UI에 테스트 결과를 표시합니다.

| XML 요소  | XML 속성   | 설명 |
| ------------ | --------------- | ----------- |
| `testsuites` | `time`          | 모든 테스트 스위트의 총 실행 시간입니다. 테스트 실행 시간 계산에 사용됩니다. |
| `testsuite`  | `name`          | 테스트 스위트 이름입니다. 내부 그룹화를 위해 구문 분석됩니다. |
| `testsuite`  | `time`          | 개별 테스트 스위트의 실행 시간입니다. 테스트 실행 시간 계산에 사용됩니다. |
| `testcase`   | `classname`     | 테스트 클래스 또는 카테고리 이름입니다. UI에서 스위트 이름으로 표시됩니다. |
| `testcase`   | `name`          | 개별 테스트 이름입니다. |
| `testcase`   | `file`          | 테스트가 정의된 파일 경로입니다. |
| `testcase`   | `time`          | 초 단위의 테스트 실행 시간입니다. |
| `failure`    | 요소 내용 | 실패 메시지 및 스택 추적입니다. |
| `error`      | 요소 내용 | 오류 메시지 및 스택 추적입니다. |
| `skipped`    | 요소 내용 | 테스트를 건너뛴 이유입니다. |
| `system-out` | 요소 내용 | 시스템 출력 및 첨부 파일 태그입니다. `testcase` 요소에서만 구문 분석됩니다. |
| `system-err` | 요소 내용 | 시스템 오류 출력입니다. `testcase` 요소에서만 구문 분석됩니다. |

다음 요소 및 속성은 구문 분석되지 않습니다:

- `testsuite` 속성(tests, failures, errors, timestamp)
- `testcase` 속성(assertions, line, status)
- `properties` 요소
- `system-out` 및 `system-err` - `testsuite` 수준

#### XML 구조 예제 {#xml-structure-example}

```xml
<testsuites>
  <testsuite name="Authentication Tests" tests="1" failures="1">
    <testcase classname="LoginTest" name="test_invalid_password" file="spec/auth_spec.rb" time="0.23">
      <failure>Expected authentication to fail</failure>
      <system-out>[[ATTACHMENT|screenshots/failure.png]]</system-out>
    </testcase>
  </testsuite>
</testsuites>
```

이 XML은 GitLab에서 다음과 같이 표시됩니다:

- 스위트: `LoginTest` (`testcase classname`에서)
- 이름: `test_invalid_password` (`testcase name`에서)
- 파일: `spec/auth_spec.rb` (`testcase file`에서)
- 시간: `0.23s` (`testcase time`에서)
- 스크린샷: 테스트 세부 정보 대화상자에서 사용 가능 (`testcase system-out`에서)
- 표시되지 않음: "인증 테스트" (`testsuite name`에서)

## 테스트 결과 유형 {#test-result-types}

테스트 결과는 머지 리퀘스트의 소스 브랜치와 대상 브랜치 간에 비교되어 변경 사항이 표시됩니다:

- 새로 실패한 테스트: 대상 브랜치에서는 통과했지만 사용자 브랜치에서는 실패한 테스트입니다.
- 새로 발생한 오류: 대상 브랜치에서는 통과했지만 사용자 브랜치에서는 오류가 발생한 테스트입니다.
- 기존 실패: 두 브랜치에서 모두 실패한 테스트입니다.
- 해결된 실패: 대상 브랜치에서는 실패했지만 사용자 브랜치에서는 통과한 테스트입니다.

아직 대상 브랜치 데이터가 없는 경우 등 브랜치를 비교할 수 없으면 사용자 브랜치의 실패한 테스트만 표시됩니다.

지난 14일간 기본 브랜치에서 실패한 테스트의 경우 `Failed {n} time(s) in {default_branch} in the last 14 days`와 같은 메시지가 표시됩니다. 이 개수에는 완료된 파이프라인의 실패한 테스트가 포함되지만 [차단된 파이프라인](../jobs/job_control.md#types-of-manual-jobs)은 포함되지 않습니다. 차단된 파이프라인에 대한 지원이 [이슈 431265](https://gitlab.com/gitlab-org/gitlab/-/issues/431265)에서 제안되었습니다.

## 단위 테스트 보고서 구성 {#configure-unit-test-reports}

단위 테스트 보고서를 구성하여 머지 리퀘스트 및 파이프라인에 테스트 결과를 표시합니다.

단위 테스트 보고서를 구성하려면:

1. 테스트 작업을 구성하여 JUnit XML 형식 테스트 보고서를 출력합니다. 구성 세부 정보는 테스트 프레임워크 설명서를 검토하세요.
1. `.gitlab-ci.yml` 파일에서 테스트 작업에 [`artifacts:reports:junit`](../yaml/artifacts_reports.md#artifactsreportsjunit)을 추가합니다.
1. XML 테스트 보고서 파일의 경로를 지정합니다. `junit` 속성이 다음을 허용합니다:

   - 단일 파일 이름: `junit: report.xml`
   - 파일 이름 패턴: `junit: test-results/**/*.xml`
   - 파일 이름 배열: `junit: [rspec-1.xml, rspec-2.xml, rspec-3.xml]`
   - 둘의 조합: `junit: [rspec.xml, test-results/TEST-*.xml]`

   디렉터리는 지원되지 않습니다(예: `junit: test-results` 또는 `junit: test-results/**`).

1. 선택 사항. 보고서 파일을 검색 가능하게 하려면 [`artifacts:paths`](../yaml/_index.md#artifactspaths)에 포함시킵니다.
1. 선택 사항. 작업이 실패해도 보고서를 업로드하려면 [`artifacts:when:always`](../yaml/_index.md#artifactswhen)을 사용합니다.

Ruby RSpec 구성 예제:

```yaml
ruby:
  stage: test
  script:
    - bundle install
    - bundle exec rspec --format progress --format RspecJunitFormatter --out rspec.xml
  artifacts:
    when: always
    paths:
      - rspec.xml
    reports:
      junit: rspec.xml
```

테스트 결과를 볼 수 있습니다:

- 테스트 작업이 완료된 후 파이프라인 세부 정보의 **테스트** 탭에서 확인합니다.
- 파이프라인이 완료된 후 머지 리퀘스트의 **테스트 요약** 패널에서 확인합니다.

## 머지 리퀘스트에서 테스트 결과 보기 {#view-test-results-in-merge-requests}

머지 리퀘스트에서 테스트 실패에 대한 자세한 정보를 봅니다.

**테스트 요약** 패널은 테스트 결과의 개요를 표시하며, 실패한 테스트와 통과한 테스트의 수를 포함합니다.

![실패한 테스트 하나와 상세 보기 링크를 표시하는 확대된 테스트 요약 패널](img/test_summary_panel_expanded_v18_1.png)

테스트 실패 세부 정보를 보려면:

1. 머지 리퀘스트에서 **테스트 요약** 패널로 이동합니다.
1. **테스트 요약** 패널을 확대하려면 **세부 정보 보기** ({{< icon name="chevron-lg-down" >}})를 선택합니다.
1. 실패한 테스트 옆에 있는 **상세 보기**를 선택합니다.

대화상자는 테스트 이름, 파일 경로, 실행 시간, 스크린샷 첨부 파일(구성된 경우) 및 오류 출력을 표시합니다.

모든 테스트 결과를 보려면:

- **테스트 요약** 패널에서 **전체 보고서**를 선택하여 파이프라인 세부 정보의 **테스트** 탭으로 이동합니다.

### 실패한 테스트 이름 복사 {#copy-failed-test-names}

테스트 이름을 복사하여 로컬에서 디버깅하기 위해 다시 실행합니다.

전제 조건:

- JUnit 보고서는 실패한 테스트에 대한 `<file>` 속성을 포함해야 합니다.

실패한 모든 테스트 이름을 복사하려면:

- **테스트 요약** 패널에서 **실패한 테스트 복사** ({{< icon name="copy-to-clipboard" >}})를 선택합니다.

실패한 테스트는 공백으로 구분된 문자열로 복사됩니다.

단일 실패한 테스트 이름을 복사하려면:

1. **테스트 요약** 패널을 확대하려면 **세부 정보 보기** ({{< icon name="chevron-lg-down" >}})를 선택합니다.
1. 복사하려는 테스트 옆에 있는 **상세 보기**를 선택합니다.
1. 대화상자에서 **로컬에서 다시 실행할 테스트 이름 복사** ({{< icon name="copy-to-clipboard" >}})를 선택합니다.

테스트 이름이 클립보드에 복사됩니다.

## 파이프라인에서 테스트 결과 보기 {#view-test-results-in-pipelines}

자식 파이프라인의 결과를 포함하여 파이프라인 세부 정보의 모든 테스트 스위트 및 사례를 봅니다.

파이프라인 테스트 결과를 보려면:

1. 파이프라인 세부 정보 페이지로 이동합니다.
1. **테스트** 탭을 선택합니다.
1. 개별 테스트 사례를 보려면 테스트 스위트를 선택합니다.

![1분 11초 총 실행 시간 및 개별 작업 실행 시간을 표시하는 1671개의 테스트를 보여주는 테스트 결과](img/pipelines_junit_test_report_v18_3.png)

[파이프라인 API](../../api/pipelines.md#retrieve-a-test-report-for-a-pipeline)로도 테스트 보고서를 검색할 수 있습니다.

### 테스트 타이밍 메트릭 {#test-timing-metrics}

테스트 결과는 다양한 타이밍 메트릭을 표시합니다:

파이프라인 기간: 파이프라인이 시작될 때부터 완료될 때까지의 경과 시간입니다.

테스트 실행 시간: 모든 작업에서 모든 테스트를 실행하는 데 소요된 총 시간(함께 추가됨)입니다.

대기열 시간: 작업이 사용 가능한 러너를 기다리는 시간입니다.

작업이 병렬로 실행될 때 누적 테스트 실행 시간이 파이프라인 기간을 초과할 수 있습니다.

파이프라인 기간은 결과를 기다리는 시간을 표시하고 테스트 실행 시간은 사용된 계산 리소스를 표시합니다.

예를 들어 81분 안에 완료되는 파이프라인은 많은 테스트 작업이 여러 러너에서 병렬로 실행되는 경우 9시간 10분의 테스트 실행 시간을 표시할 수 있습니다.

## 테스트 보고서에 스크린샷 추가 {#add-screenshots-to-test-reports}

테스트 보고서에 스크린샷을 추가하여 테스트 실패를 디버깅하는 데 도움이 됩니다.

테스트 보고서에 스크린샷을 추가하려면:

1. JUnit XML 파일에서 `$CI_PROJECT_DIR`에 상대적인 스크린샷 경로가 있는 첨부 파일 태그를 추가합니다:

   ```xml
   <testcase time="1.00" name="Test">
     <system-out>[[ATTACHMENT|/path/to/some/file]]</system-out>
   </testcase>
   ```

1. `.gitlab-ci.yml` 파일에서 스크린샷을 아티팩트로 업로드하도록 작업을 구성합니다:

   - 스크린샷 파일의 경로를 지정합니다.
   - 선택 사항. 테스트가 실패할 때 스크린샷을 업로드하려면 [`artifacts:when: always`](../yaml/_index.md#artifactswhen)을 사용합니다.

   예를 들어:

   ```yaml
   ruby:
     stage: test
     script:
       - bundle install
       - bundle exec rspec --format progress --format RspecJunitFormatter --out rspec.xml
       - # Your test framework should save screenshots to a directory
     artifacts:
       when: always
       paths:
         - rspec.xml
         - screenshots/
       reports:
         junit: rspec.xml
   ```

1. 파이프라인을 실행합니다.

**테스트 요약** 패널에서 실패한 테스트에 대해 **상세 보기**를 선택할 때 테스트 세부 정보 대화상자에서 스크린샷 링크에 액세스할 수 있습니다.

![테스트 세부 정보 및 스크린샷 첨부 파일이 있는 실패한 단위 테스트 보고서](img/unit_test_report_screenshot_v18_1.png)

## 문제 해결 {#troubleshooting}

### 테스트 보고서가 비어 있음 {#test-report-appears-empty}

머지 리퀘스트에서 빈 **테스트 요약** 패널이 표시될 수 있습니다.

이 이슈는 다음과 같은 경우에 발생합니다:

- 보고서 아티팩트가 만료되었습니다.
- JUnit 파일이 크기 제한을 초과합니다.

이 이슈를 해결하려면 보고서 아티팩트에 대해 [`expire_in`](../yaml/_index.md#artifactsexpire_in) 값을 더 길게 설정하거나 새 파이프라인을 실행하여 새 보고서를 생성합니다.

JUnit 파일이 크기 제한을 초과하는 경우 다음을 확인하세요:

- 개별 JUnit 파일은 30MB 미만입니다.
- 작업의 모든 JUnit 파일의 총 크기는 100MB 미만입니다.

사용자 지정 제한에 대한 지원이 [에픽 16374](https://gitlab.com/groups/gitlab-org/-/epics/16374)에서 제안되었습니다.

### 테스트 결과 누락 {#test-results-are-missing}

보고서에서 예상보다 적은 테스트 결과가 표시될 수 있습니다.

이는 JUnit XML 파일에서 중복된 테스트 이름이 있을 때 발생할 수 있습니다. 각 이름의 첫 번째 테스트만 사용되고 중복은 무시됩니다.

이 이슈를 해결하려면 모든 테스트 이름과 클래스가 고유한지 확인하세요.

### 머지 리퀘스트에 테스트 보고서 표시 안 됨 {#no-test-reports-appear-in-merge-requests}

머지 리퀘스트에서 **테스트 요약** 패널이 전혀 표시되지 않을 수 있습니다.

이 이슈는 대상 브랜치에 비교할 테스트 데이터가 없을 때 발생할 수 있습니다.

이 이슈를 해결하려면 대상 브랜치에서 파이프라인을 실행하여 기준 테스트 데이터를 생성합니다.

### JUnit XML 구문 분석 오류 {#junit-xml-parsing-errors}

파이프라인의 작업 이름 옆에 구문 분석 오류 표시기가 표시될 수 있습니다.

JUnit XML 파일에 형식 오류나 잘못된 요소가 포함되어 있을 때 발생할 수 있습니다.

이 이슈를 해결하려면:

- JUnit XML 파일이 표준 형식을 따르는지 확인합니다.
- 모든 XML 요소가 제대로 닫혀 있는지 확인합니다.
- 속성 이름과 값이 올바르게 형식화되어 있는지 확인합니다.

[그룹화된 작업](../jobs/_index.md#group-similar-jobs-together-in-pipeline-views)의 경우 그룹의 첫 번째 구문 분석 오류만 표시됩니다.
