---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: JaCoCo XML 보고서를 사용하여 머지 리퀘스트 미분 뷰에 라인별 테스트 범위 주석을 표시합니다.
title: JaCoCo 범위 시각화
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- GitLab 17.3에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/227345) 되었으며 [플래그](../../../administration/feature_flags/_index.md) `jacoco_coverage_reports`라는 이름입니다. 기본적으로 비활성화되어 있습니다.
- [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170513)한 GitLab 17.6. 기능 플래그 `jacoco_coverage_reports`이 제거되었습니다.

{{< /history >}}

JaCoCo 범위 보고서를 사용하여 머지 리퀘스트 미분 뷰에 라인별 범위 주석을 표시합니다. GitLab은 JaCoCo XML 보고서를 읽고 변경된 각 라인에 범위 있음(녹색) 또는 범위 없음(빨강)으로 주석을 답니다.

범위 시각화는 [`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report) 키워드를 사용합니다. 머지 리퀘스트 위젯에 범위 백분율을 표시하거나 범위 기록 그래프를 채우지 않습니다. 범위 백분율을 표시하려면 [`coverage`](../../yaml/_index.md#coverage) 키워드를 별도로 구성합니다.

> [!note]
> 멀티 모듈 프로젝트의 집계 보고서는 지원되지 않습니다. 집계 보고서 지원에 기여하려면 [이슈 491015](https://gitlab.com/gitlab-org/gitlab/-/issues/491015)를 참고하세요.

## JaCoCo 범위 작업 추가 {#add-a-jacoco-coverage-job}

머지 리퀘스트 미분 뷰에 라인별 범위 주석을 표시하려는 경우 JaCoCo 범위 작업을 추가합니다.

전제 조건:

- [JaCoCo XML 파일](https://www.jacoco.org/jacoco/trunk/coverage/jacoco.xml)이 [라인 범위](https://www.eclemma.org/jacoco/trunk/doc/counters.html)를 제공합니다.

JaCoCo 범위 작업을 추가하려면:

1. `.gitlab-ci.yml` 파일에 작업을 추가하고 `artifacts:reports:coverage_report`를 `jacoco`으로 설정합니다. 예를 들어:

   ```yaml
   test-jdk11:
     stage: test
     image: maven:3.6.3-jdk-11
     script:
       - mvn $MAVEN_CLI_OPTS clean org.jacoco:jacoco-maven-plugin:prepare-agent test jacoco:report
     artifacts:
       reports:
         coverage_report:
           coverage_format: jacoco
           path: target/site/jacoco/jacoco.xml
   ```

1. `path`을 생성된 JaCoCo XML 보고서의 위치로 설정합니다.

작업이 여러 보고서를 생성하면 [아티팩트 경로의 와일드카드](../../jobs/job_artifacts.md#with-wildcards)를 사용합니다.

## 범위 표시기 {#coverage-indicators}

JaCoCo 시각화는 [지시사항(C0 범위)](https://www.eclemma.org/jacoco/trunk/doc/counters.html)를 사용하며, 보고서에서 `ci` (범위 지시사항)로 표현됩니다.

작업 완료 후 범위는 머지 리퀘스트 미분 뷰에서 다음 표시기와 함께 표시됩니다:

- 범위된 지시사항(녹색): 하나 이상의 범위된 지시사항이 있는 라인(`ci > 0`)
- 범위된 지시사항 없음(빨강): 범위된 지시사항이 없는 라인(`ci = 0`)
- 범위 정보 없음: 범위 보고서에 포함되지 않은 라인

예를 들어, 다음 보고서 출력의 경우:

```xml
<line nr="83" mi="2" ci="0" mb="0" cb="0"/>
<line nr="84" mi="2" ci="0" mb="0" cb="0"/>
<line nr="85" mi="2" ci="0" mb="0" cb="0"/>
<line nr="86" mi="2" ci="0" mb="0" cb="0"/>
<line nr="88" mi="0" ci="7" mb="0" cb="1"/>
```

머지 리퀘스트 미분 뷰는 범위를 다음과 같이 표시합니다:

![범위되지 않은 라인의 빨강 막대와 범위된 라인의 녹색 막대를 나타내는 범위 표시기가 있는 머지 리퀘스트 미분 뷰.](img/jacoco_coverage_example_v18_3.png)

이 예에서 라인 83-86은 범위되지 않은 코드의 빨강 막대를, 라인 88은 범위된 코드의 녹색 막대를 나타내며, 라인 87, 89-90은 범위 데이터가 없습니다.

## 문제 해결 {#troubleshooting}

경로 확인 실패 및 예상대로 표시되지 않는 주석을 포함한 범위 시각화 문제 해결은 [범위 시각화 문제 해결](coverage_visualization.md#troubleshooting)을 참고하세요.

## 피드백 제공 {#give-feedback}

JaCoCo 범위 시각화는 적극적으로 개선되고 있습니다. 문제를 보고하거나 개선 사항을 제안하려면 [이슈 479804](https://gitlab.com/gitlab-org/gitlab/-/issues/479804)에 피드백을 남겨주세요.
