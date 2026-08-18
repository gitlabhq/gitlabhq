---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 코드 커버리지 백분율을 추적하고 에서 줄 단위 테스트 커버리지를 시각화합니다.
title: 코드 커버리지
---

{{< details >}}

- 계층: Free, Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

위젯에 백분율을 표시하거나 diff에서 개별 줄에 주석을 추가하거나 둘 다 수행할 수 있습니다. 각 출력에는 별도의 키워드가 필요합니다. 하나를 구성해도 다른 하나가 활성화되지 않습니다.

| 출력                                                                           | 키워드 |
| -------------------------------------------------------------------------------- | ------- |
| 위젯, 목록 및 분석 그래프에서 커버리지 백분율 표시 | [`coverage`](../../yaml/_index.md#coverage) |
| diff에서 줄 단위 주석 표시                                     | [`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report) |

두 가지 출력을 모두 얻으려면 두 가지 키워드를 모두 구성합니다.

## 커버리지 보고 {#coverage-reporting}

커버리지 보고는 테스트 도구의 출력에서 백분율을 추출합니다. `coverage` 키워드에서 정규식을 정의합니다. GitLab은 를 스캔하고 일치하는 첫 번째 숫자를 추출한 후 저장합니다.

GitLab은 다음 위치에 이 값을 표시합니다:

- 와 비교한 델타를 포함하는 위젯입니다.
- 목록입니다.
- **분석** > **리포지토리 분석**의 프로젝트별 및 그룹별 커버리지 기록 그래프입니다.
- 커버리지 배지입니다.
- `Coverage-Check` (Premium 및 )으로, 커버리지가 떨어질 때 승인을 요구할 수 있습니다.

설정 지침은 [커버리지 보고 구성](coverage_reporting.md)을 참조하세요.

## 커버리지 시각화 {#coverage-visualization}

커버리지 시각화는 테스트 작업에서 CI/CD 아티팩트로 업로드하는 Cobertura 또는 JaCoCo XML 보고서를 파싱합니다. 이 완료된 후 GitLab은 백그라운드에서 보고서를 처리하고 diff의 줄에 주석을 추가합니다.

주석은 diff에서 변경된 파일에만 나타납니다. 에서 변경되지 않은 파일은 보고서에 해당 커버리지 데이터가 포함되어 있더라도 주석이 추가되지 않습니다.

설정 지침은 [커버리지 시각화 구성](coverage_visualization.md)을 참조하세요.
