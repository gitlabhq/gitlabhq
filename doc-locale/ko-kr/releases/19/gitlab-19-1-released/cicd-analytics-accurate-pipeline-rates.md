---
title: CI/CD 분석에서 정확한 파이프라인 성공률을 표시합니다
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: verify
documentation_link: "../../../user/analytics/ci_cd_analytics"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/599923
categories: [ Continuous Integration (CI) ]
level: secondary
---

이전 버전의 GitLab에서는 CI/CD 분석 페이지(`<project>/-/pipelines/charts`)의 실패율 및 성공률 지표에 취소되거나 건너뛴 파이프라인이 계산에 포함되었습니다. 이로 인해 두 비율이 예상보다 낮게 나타났습니다. 예를 들어 `gitlab-org/gitlab`의 경우 두 비율의 합이 약 100% 대신 98%에 불과했습니다.

이제 GitLab은 완료된 파이프라인만 사용하여 실패율 및 성공률을 계산하므로, 결과가 파이프라인 상태를 정확하게 반영합니다.
