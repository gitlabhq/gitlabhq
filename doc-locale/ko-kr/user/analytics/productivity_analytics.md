---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 그룹의 개발 속도를 분석하고 머지 리퀘스트 분석을 위한 차트를 봅니다.
title: Productivity analytics
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

생산성 분석은 그룹의 머지 리퀘스트에 대한 정보를 표시합니다.

생산성 분석을 사용하여 다음을 확인할 수 있습니다:

- 머지 리퀘스트가 병합되는 데 걸리는 시간을 기반으로 한 개발 속도입니다.
- 병합하는 데 오래 걸리는 머지 리퀘스트의 잠재적 원인입니다.
- 병합하는 데 가장 오래 걸리거나 가장 많은 변경 사항을 포함한 작성자, 레이블 또는 마일스톤입니다.

프로젝트의 머지 리퀘스트 데이터를 보려면 [머지 리퀘스트 분석](merge_request_analytics.md)을 사용합니다.

## 차트 {#charts}

생산성 분석은 다음 차트를 표시합니다:

- 다음을 보여주는 막대형 차트입니다:
  - 병합하는 데 걸리는 일수별 머지 리퀘스트 수입니다.
  - 커밋, 댓글, 병합 날짜 간의 시간입니다.
  - 커밋 수, 코드 라인 수, 변경된 파일입니다.
- 머지 리퀘스트 메트릭 수(머지 리퀘스트당 커밋 수 등)를 일(병합 날짜)별로 보여주는 산점도입니다.
- 머지 리퀘스트 제목, 병합 시간, 커밋, 댓글, 병합 날짜 간의 기간을 나열하는 표입니다.

![시간에 따른 머지 리퀘스트의 생산성 분석 차트](img/productivity_analytics_mrs_v17_9.png)

## 생산성 분석 보기 {#view-productivity-analytics}

전제 조건:

- 그룹에 대해 Reporter, Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

1. 상단 바에서 **검색 또는 이동**을 선택하고 그룹을 찾습니다.
1. 왼쪽 사이드바에서 **분석** > **생산성 분석**을 선택합니다.
1. 선택 사항. 결과 필터링:

- 특정 프로젝트의 분석을 보려면 **프로젝트** 드롭다운 목록에서 프로젝트를 선택합니다.
- 작성자, 마일스톤 또는 레이블별로 결과를 필터링하려면 **필터 결과**를 선택하고 값을 입력합니다.
- 날짜 범위를 조정하려면:
  - **시작** 필드에서 시작 날짜를 선택합니다.
  - **종료** 필드에서 종료 날짜를 선택합니다.
