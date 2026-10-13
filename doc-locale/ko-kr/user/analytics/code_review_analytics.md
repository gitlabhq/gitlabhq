---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: 열려 있는 머지 리퀘스트가 코드 검토에서 소비한 시간과 가장 오래 실행되는 요청의 특징을 알아봅니다.
title: 코드 검토 분석
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- 13.9에서 GitLab Premium으로 이동했습니다.

{{< /history >}}

코드 검토 분석은 최소 하나의 작성자가 아닌 댓글이 있는 열려 있는 머지 리퀘스트의 표를 표시합니다. 검토 시간은 머지 리퀘스트에서 작성자가 아닌 사용자의 첫 번째 댓글 이후 경과한 시간입니다.

코드 검토 분석을 사용하여 머지 리퀘스트당 검토 지표를 확인하고 코드 검토 프로세스를 개선할 수 있습니다.

- 댓글 또는 커밋의 수가 많으면 다음을 나타낼 수 있습니다:
  - 너무 복잡한 코드
  - 더 많은 교육이 필요한 작성자
- 검토 시간이 길면 다음을 나타낼 수 있습니다:
  - 다른 유형보다 더 느리게 진행되는 작업 유형
  - 개발 커밋을 가속화할 수 있는 기회
- 댓글과 승인자가 적으면 사용 가능한 팀원이 부족함을 나타낼 수 있습니다.

<i class="fa-youtube-play" aria-hidden="true"></i> 비디오 설명은 [코드 검토 분석: 더 빠른 코드 검토](https://www.youtube.com/watch?v=849o0XD991M).

## 코드 검토 분석 보기 {#view-code-review-analytics}

전제 조건:

- Reporter, Developer, Maintainer 또는 Owner 역할이 있어야 합니다.

코드 검토 분석을 보려면:

1. 상단 바에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. 왼쪽 사이드바에서 **분석** > **코드 검토 분석**을 선택합니다.
1. 선택 사항. 결과 필터링:
   1. 필터 막대를 선택합니다.
   1. 매개 변수를 선택합니다. 마일스톤 및 레이블로 머지 리퀘스트를 필터링할 수 있습니다.
   1. 선택한 매개 변수의 값을 선택합니다.

표는 페이지당 최대 20개의 머지 리퀘스트를 검토 상태로 표시하며 각 머지 리퀘스트에 대한 다음 정보를 포함합니다:

- 머지 리퀘스트 제목
- 검토 시간
- 작성자
- 승인자
- 댓글
- 커밋
- 줄 변경 사항
