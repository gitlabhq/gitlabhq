---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duo 및 SDLC 트렌드
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- 상태:  GitLab Self-Managed 베타

{{< /details >}}

{{< history >}}

- [GitLab 16.11](https://gitlab.com/gitlab-org/gitlab/-/issues/443696)에서 [기능 플래그](../../administration/feature_flags/_index.md) `ai_impact_analytics_dashboard`로 도입했습니다. 기본적으로 비활성화되었습니다.
- GitLab 17.2에서 [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/issues/451873)합니다. `ai_impact_analytics_dashboard` 기능 플래그가 제거되었습니다.
- GitLab 17.6에서 GitLab Duo 애드온이 필요하도록 변경했습니다.
- GitLab 18.2에서 GitLab Ultimate에서 GitLab Premium으로 이동했습니다.
- GitLab 18.2.1에서 Amazon Q를 지원하도록 변경했습니다.
- GitLab 18.4에서 파이프라인 메트릭 테이블이 [추가](https://gitlab.com/gitlab-org/gitlab/-/issues/550356)되었습니다.
- `AI impact analytics`에서 `GitLab Duo and SDLC trends`로 GitLab 18.4에서 이름을 변경했습니다.
- GitLab 18.7에서 애드온이 필요 없도록 변경했습니다.

{{< /history >}}

이 기능은 GitLab Self-Managed 베타 상태입니다. 자세한 내용은 [에픽 51](https://gitlab.com/groups/gitlab-org/architecture/gitlab-data-analytics/-/epics/51)을 참조하세요.

GitLab Duo 및 SDLC 트렌드는 소프트웨어 개발 수명 주기(SDLC) 성능에 대한 GitLab Duo의 영향을 측정합니다. 이 대시보드는 프로젝트 또는 그룹의 AI 도입 상황에서 주요 SDLC 메트릭에 대한 가시성을 제공합니다. 대시보드를 사용하여 AI 투자로 개선된 메트릭을 측정할 수 있습니다.

GitLab Duo 및 SDLC 트렌드를 다음과 같이 사용하세요:

- GitLab Duo 여정과 관련한 SDLC 트렌드 추적: 프로젝트 또는 그룹에서 GitLab Duo 사용 트렌드가 머지까지의 평균 시간 및 CI/CD 통계와 같은 기타 중요한 생산성 메트릭에 미치는 영향을 확인합니다. GitLab Duo 사용량 메트릭은 현재 달을 포함한 최근 6개월 동안 표시됩니다.
- GitLab Duo 기능 도입 모니터링: 지난 30일 동안 프로젝트 또는 그룹에서 사용자 및 기능의 사용을 추적합니다.

다음 표는 GitLab Duo 및 SDLC 메트릭의 가용성을 나열합니다:

| 기능 | GitLab Duo Pro 또는 Enterprise 필요 | [ClickHouse](../../integration/clickhouse.md) 필요 |
|---------|:-----------------------:|:-------------------:|
| GitLab Duo 및 SDLC 트렌드 대시보드 | {{< yes >}} | {{< yes >}} |
| `AiMetrics` API | {{< yes >}} | {{< yes >}} |
| `AiUserMetrics` API | {{< yes >}} | {{< yes >}} |
| `AiUsageData` API | {{< no >}} | {{< no >}} (PostgreSQL만) |

라이선스 사용을 최적화하는 방법을 알아보려면 [GitLab Duo 애드온](../../subscriptions/subscription-add-ons.md)을 참조하세요.

GitLab Duo 및 SDLC 트렌드에 대해 자세히 알아보려면 블로그 포스트 [GitLab Duo 개발: AI 영향 분석 대시보드는 AI의 ROI를 측정합니다](https://about.gitlab.com/blog/developing-gitlab-duo-ai-impact-analytics-dashboard-measures-the-roi-of-ai/).

<i class="fa-youtube-play" aria-hidden="true"></i> 개요를 보려면 [GitLab Duo AI Impact Dashboard](https://youtu.be/FxSWX64aUOE?si=7Yfc6xHm63c3BRwn)를 참조하세요.
<!-- Video published on 2025-03-06 -->

## 주요 메트릭 {#key-metrics}

{{< history >}}

- GitLab Duo Chat 사용량 메트릭이 GitLab 18.10에서 GitLab Duo Agentic Chat 세션으로 [대체](https://gitlab.com/gitlab-org/gitlab/-/issues/587301)되었습니다.
- 할당된 GitLab Duo 사용자 참여 메트릭이 GitLab 18.10에서 GitLab Duo 사용자로 [대체](https://gitlab.com/gitlab-org/gitlab/-/work_items/587298)되었습니다.
- GitLab Duo 코드 제안 사용량 메트릭이 GitLab 18.10에서 백분율 비율에서 절대 사용자 수로 [변경](https://gitlab.com/gitlab-org/gitlab/-/work_items/592813)되었습니다.
- 코드 제안 수락 비율 메트릭이 GitLab 18.11에서 GitLab Duo 에이전트/플로우 사용자로 [대체](https://gitlab.com/gitlab-org/gitlab/-/work_items/587300)되었습니다.
- 트렌드 표시기가 GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/590535)되었습니다.
- 코드 제안 사용자 메트릭이 GitLab 19.0에서 GitLab Duo 파워 유저로 [대체](https://gitlab.com/gitlab-org/gitlab/-/work_items/587299)되었습니다.
- GitLab Duo 기능을 사용하는 파이프라인 메트릭이 GitLab 19.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/work_items/587308)되었습니다.

{{< /history >}}

- **GitLab Duo users**: 지난 30일 동안 하나 이상의 GitLab Duo 또는 GitLab Duo Agent Platform 기능을 사용한 사용자 수입니다.
- **GitLab Duo 파워 유저**: 지난 30일 동안 3개 이상의 GitLab Duo 기능을 사용한 사용자 수입니다.
- **GitLab Duo 에이전트/플로우 사용자**: 지난 30일 동안 하나 이상의 GitLab Duo 에이전트 또는 플로우를 사용한 사용자 수입니다.
- **GitLab Duo Agent chat sessions**: 지난 30일 동안 GitLab Duo Agent Platform에서 시작된 채팅 세션 수입니다.
- **GitLab Duo 기능을 사용하는 파이프라인**: 지난 30일 동안 실행 중에 하나 이상의 GitLab Duo 기능을 사용한 CI/CD 파이프라인의 백분율입니다.

## 메트릭 트렌드 {#metric-trends}

**Metric trends** 테이블은 지난 6개월의 메트릭을 월별 값, 지난 6개월의 백분율 변화, 트렌드 스파크라인과 함께 표시합니다.

메트릭은 이전 기간과 비교하여 백분율 변화를 보여주는 트렌드 표시기를 표시합니다. 이전 기간의 데이터가 없으면 백분율 변화에 **n/a**가 표시됩니다.

녹색 값은 긍정적 변화를 나타내고 빨간색 값은 부정적 변화를 나타냅니다. 값 옆의 아이콘은 상향 트렌드 {{< icon name="trend-up" >}} 또는 하향 트렌드 {{< icon name="trend-down" >}}를 나타냅니다.

상향 트렌드는 일부 메트릭(예: [배포 빈도](dora_metrics.md#deployment-frequency))에서는 긍정적(녹색)이지만 다른 메트릭(예: [머지까지 시간의 중간값](merge_request_analytics.md))에서는 부정적(빨간색)입니다.

### GitLab Duo 사용 메트릭 {#gitlab-duo-usage-metrics}

{{< history >}}

- GitLab Duo Root Cause Analysis 사용이 GitLab 18.1에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/513252)되었으며, [기능 플래그](../../administration/feature_flags/_index.md) `duo_rca_usage_rate`를 사용합니다. 기본적으로 비활성화되었습니다.
- GitLab Duo Root Cause Analysis 사용이 GitLab 18.3에서 [GitLab.com, GitLab Self-Managed 및 GitLab Dedicated에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/543987)되었습니다.
- GitLab Duo Root Cause Analysis 사용이 GitLab 18.4에서 [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/issues/556726)합니다. `duo_rca_usage_rate` 기능 플래그가 제거되었습니다.
- GitLab Duo 기능 사용이 GitLab 18.6에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207562)되었습니다.
- GitLab Duo 코드 검토 요청 및 댓글이 GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/573979)되었습니다.
- GitLab Duo Agent Platform 채팅 및 플로우가 GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/583375)되었습니다.
- GitLab Duo 코드 제안, Non-Agentic Chat 및 Root Cause Analysis 메트릭이 GitLab 18.10에서 백분율 비율에서 절대 사용자 수로 [변경](https://gitlab.com/gitlab-org/gitlab/-/issues/589605)되었습니다.

{{< /history >}}

- **기능 사용량**: 하나 이상의 GitLab Duo 또는 GitLab Duo Agent Platform 기능을 사용한 사용자 수입니다.
- **에이전트 플랫폼 채팅**: GitLab Duo Agent Platform을 통해 시작된 채팅 세션 수입니다.
- **에이전트 플랫폼 플로우**: GitLab Duo Agent Platform을 통해 실행된 에이전트 플로우(채팅 제외) 수입니다.
- **Non-Agentic Chat usage**: Non-Agentic Chat을 사용한 사용자 수입니다.
- **근본 원인 분석 사용량**: Root Cause Analysis를 사용한 사용자 수입니다.
- **코드 검토 요청**: 머지 리퀘스트에서 만든 코드 검토 요청 수입니다. 여기에는 머지 리퀘스트 작성자 및 비작성자가 모두 시작한 요청이 포함됩니다.
- **코드 검토 댓글**: 머지 리퀘스트 diff에 게시된 코드 검토 댓글 수입니다.
- **코드 제안 사용량**: 코드 제안을 사용한 사용자 수입니다. GitLab.com에서는 5분마다 데이터가 업데이트됩니다. GitLab은 사용자가 현재 월에 프로젝트에 코드를 푸시한 경우에만 코드 제안 사용량을 계산합니다.
- **코드 제안 수락 비율**: GitLab Duo에서 제공한 코드 제안 중 코드 기여자가 수락한 백분율입니다.

### 개발 메트릭 {#development-metrics}

- [**리드 타임**](../group/value_stream_analytics/_index.md#lifecycle-metrics)
- [**머지까지 시간의 중간값**](merge_request_analytics.md)
- [**배포 빈도**](dora_metrics.md#deployment-frequency)
- [**머지 리퀘스트 처리량**](merge_request_analytics.md#view-the-number-of-merge-requests-in-a-date-range)
- [**시간 경과에 따른 심각한 취약성**](../application_security/vulnerability_report/_index.md)
- [**기여자 수**](../profile/contributions_calendar.md#user-contribution-events)

### 파이프라인 메트릭 {#pipeline-metrics}

파이프라인 메트릭 테이블은 선택한 프로젝트에서 실행된 파이프라인의 메트릭을 표시합니다.

- **파이프라인 실행 합계**: 프로젝트의 파이프라인 실행 수입니다.
- **기간 중간값**: 파이프라인 실행의 중간 기간(분)입니다.
- **성공율**: 성공적으로 완료된 파이프라인 실행의 백분율입니다.
- **실패율**: 오류로 완료된 파이프라인 실행의 백분율입니다.

## GitLab Duo Agent Platform을 사용하는 파이프라인 {#pipelines-using-gitlab-duo-agent-platform}

{{< history >}}

- GitLab 19.0에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/587303)되었습니다.

{{< /history >}}

**Pipelines using GitLab Duo Agent Platform** 차트는 지난 180일 동안 월별로 집계된 파이프라인 실행 수를 표시합니다. 차트는 다음을 보여줍니다:

- **에이전트 플랫폼 사용**: GitLab Duo Agent Platform으로 트리거된 파이프라인 수입니다.
- **모든 파이프라인**: 네임스페이스에서 실행된 파이프라인의 총 수입니다.

## GitLab Duo 코드 제안 언어별 수락 {#gitlab-duo-code-suggestions-acceptance-by-language}

{{< history >}}

- GitLab 18.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/454809)되었습니다.

{{< /history >}}

**GitLab Duo Code Suggestions acceptance by language** 차트는 지난 30일 동안 프로그래밍 언어별로 수락된 코드 제안의 수를 표시합니다.

막대 위에 마우스를 올려 각 언어에 대해 다음을 확인합니다:

- **제안 수락됨**: 사용자가 수락한 제안의 수입니다.
- **Suggestions shown**: 사용자에게 표시된 제안의 수입니다.
- **Acceptance rate**: 수락된 제안의 백분율입니다. 수락된 코드 제안의 수를 표시된 코드 제안의 총 수로 나눈 값으로 계산됩니다.

## GitLab Duo 코드 제안 IDE별 수락 {#gitlab-duo-code-suggestions-acceptance-by-ide}

{{< history >}}

- GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/550064)되었습니다.

{{< /history >}}

**GitLab Duo Code Suggestions acceptance by IDE** 차트는 지난 30일 동안 IDE별로 수락된 코드 제안의 수를 표시합니다.

막대 위에 마우스를 올려 각 IDE에 대해 다음을 확인합니다:

- **제안 수락됨**: 사용자가 수락한 제안의 수입니다.
- **Suggestions shown**: 사용자에게 표시된 제안의 수입니다.
- **Acceptance rate**: 수락된 제안의 백분율입니다. 수락된 코드 제안의 수를 표시된 코드 제안의 총 수로 나눈 값으로 계산됩니다.

## 코드 생성 볼륨 트렌드 {#code-generation-volume-trends}

{{< history >}}

- GitLab 18.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/573972)되었습니다.

{{< /history >}}

**Code generation volume trends** 차트는 지난 180일 동안 월별로 집계된 코드 제안을 통해 생성된 코드의 볼륨을 표시합니다. 차트는 다음을 보여줍니다:

- **채택된 코드 라인**: 수락된 코드 제안의 코드 라인입니다.
- **보여진 코드 라인**: 코드 제안에 표시된 코드 라인입니다.

## GitLab Duo 코드 검토 요청 역할별 {#gitlab-duo-code-review-requests-by-role}

{{< history >}}

- GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/574003)되었습니다.

{{< /history >}}

**GitLab Duo Code Review requests by role** 차트는 지난 180일 동안 월별로 집계된 코드 검토 요청 수를 표시합니다. 차트는 다음을 보여줍니다:

- **Review requests by authors**: 머지 리퀘스트 작성자가 만든 코드 검토 요청 수입니다. 여기에는 프로젝트 설정을 통해 자동으로 요청되고 작성자가 머지 리퀘스트에서 수동으로 요청한 코드 검토가 포함됩니다.
- **Review requests by non-authors**: 머지 리퀘스트 작성자가 아닌 사용자가 만든 코드 검토 요청 수입니다. 예를 들어, GitLab Duo에 머지 리퀘스트 변경을 검토하도록 요청하는 검토자입니다.

더 높은 작성자 도입은 팀이 자동화된 검토 워크플로우를 수용하고 있음을 나타냅니다.

## GitLab Duo 코드 검토 댓글 감정 {#gitlab-duo-code-review-comments-sentiment}

{{< history >}}

- GitLab 18.8에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/574005)되었습니다.

{{< /history >}}

**GitLab Duo Code Review comments sentiment** 차트는 지난 180일 동안 긍정적(👍) 및 부정적(👎) 반응 비율로 측정된 코드 검토 댓글의 감정을 표시합니다. 차트는 다음을 보여줍니다:

- **Approval rate**: 긍정적(👍) 반응을 받은 코드 검토 댓글의 백분율입니다.
- **Disapproval rate**: 부정적(👎) 반응을 받은 코드 검토 댓글의 백분율입니다.

분석을 해석할 때 다음을 염두에 두세요:

- 부정성 편향이 예상됩니다. 사용자는 문제에 플래그를 지정하는 경향이 있지만 좋은 제안을 거의 인정하지 않으며, 적용할 때도 마찬가지입니다.
- 낮은 반응 비율이 일반적입니다. 코드가 개선되고 검토가 더 빨리 완료되는지에 집중하세요.
- 거부(👎) 비율이 증가하면 문제를 신호합니다. 안정적이거나 감소하는 거부 비율은 GitLab Duo 코드 검토의 건강한 도입을 나타냅니다.

## 기능별 반환 GitLab Duo 사용자 {#returning-gitlab-duo-users-by-feature}

{{< history >}}

- GitLab 19.2에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/576752)되었습니다.

{{< /history >}}

**Returning GitLab Duo users by feature** 차트는 지난 180일 동안 각 GitLab Duo 기능의 유지율을 표시합니다: 코드 제안, GitLab Duo Chat, 근본 원인 분석 및 GitLab Duo 코드 검토

점 위에 마우스를 올려 선택한 기능 및 기간에 대해 다음을 확인합니다:

- **Retention rate**: 이전 기간에서 선택한 기간에 기능을 다시 사용하는 사용자의 백분율입니다. 선택한 기간의 반환 사용자 수를 이전 기간의 사용자 수로 나눈 값으로 계산됩니다.

차트는 선택한 날짜 범위의 두 번째 기간부터 시작합니다. 첫 번째 기간은 비교할 이전 기간이 없어서 유지율을 표시하지 않습니다.

## 사용자별 GitLab Duo 메트릭 {#gitlab-duo-metrics-by-user}

{{< history >}}

- GitLab 18.7에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/issues/574420)되었습니다.

{{< /history >}}

사용자 메트릭 테이블은 지난 30일 동안 개별 사용자별로 여러 GitLab Duo 기능의 사용을 표시합니다.

- **GitLab Duo Code Suggestions usage by user**: 수락된 코드 제안의 수 및 코드 제안 수락 비율입니다.
- **GitLab Duo Code Review usage by user**: 머지 리퀘스트 작성자로서 GitLab Duo에서 요청한 코드 검토 수 및 코드 검토 댓글에 대한 반응(:thumbsup: 및 :thumbsdown:) 수입니다.
- **GitLab Duo Root Cause Analysis usage by user**: GitLab Duo의 문제 해결 요청 수입니다.
- **GitLab Duo usage by user**: 사용자가 만든 GitLab Duo 이벤트 수입니다.
- **Flows usage by user**: 사용자가 특정 플로우를 트리거하는 횟수입니다.

## GitLab Duo 및 SDLC 트렌드 보기 {#view-gitlab-duo-and-sdlc-trends}

전제 조건:

- 그룹에 대해 최소 리포터 역할이 있어야 합니다.
- 그룹은 최상위 그룹이어야 합니다.
- GitLab Duo 코드 제안을 활성화해야 합니다.
- GitLab Self-Managed의 경우 [기여도 분석을 위한 ClickHouse](../group/contribution_analytics/_index.md#contribution-analytics-with-clickhouse)를 구성해야 합니다.

1. 상단 막대에서 **검색 또는 이동**을 선택하고 프로젝트 또는 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **분석** > **분석 대시보드**를 선택합니다.
1. **GitLab Duo and SDLC trends**를 선택합니다.

GitLab Duo 및 SDLC 메트릭을 검색하려면 `AiMetrics`, `AiUserMetrics` 및 `AiUsageData` [GraphQL API](../../api/graphql/duo_and_sdlc_trends.md)를 사용할 수도 있습니다.

## 메트릭 데이터 가용성 {#metric-data-availability}

다음 표는 GitLab Duo 메트릭에 대한 사용 데이터 계산이 시작된 GitLab 버전을 표시합니다:

| GitLab Duo 메트릭 | 데이터 계산 시작 |
|--------|------------------------------|
| 코드 제안 사용량 | GitLab 16.11 |
| 근본 원인 분석 사용량 | GitLab 18.0 |
| 코드 검토 요청 및 댓글 | GitLab 18.3 |
| 에이전트 플랫폼 채팅 및 플로우 | GitLab 18.7 |
