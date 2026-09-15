---
title: GitLab 러너 19.1
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: verify
documentation_link: https://docs.gitlab.com/runner
work_item: https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/?milestone_title=19.1&state=closed
categories: [ Runner Core ]
level: secondary
---

<!-- categories: Runner Core -->

오늘 GitLab 러너 19.1을 출시합니다! GitLab Runner는 CI/CD 작업을 실행하고 결과를 GitLab 인스턴스로 보내는 높은 확장성의 빌드 에이전트입니다. GitLab Runner는 GitLab에 포함된 오픈 소스 지속적 통합 서비스인 GitLab CI/CD와 함께 작동합니다.

**새로운 기능**

- [러너 구성에 구성 가능한 `get_sources` 타임아웃 추가](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39426)

**버그 수정**

- [구체적 실행기 (`FF_CONCRETE`)가 추상 셸과 여러 동작 영역에서 다릅니다](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39473)
- [`FF_USE_GIT_PROACTIVE_AUTH` 및 `FF_USE_GIT_BUNDLE_URIS`이(가) 활성화될 때 번들 URI 다운로드가 불충분한 기능으로 인해 실패합니다](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39471)
- [경합 조건으로 인한 UI를 통한 작업 취소 시 스크립트 덤프 방지](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/39005)
- [Kubernetes 실행기 보조 컨테이너 메모리 사용으로 인한 OOM 킬 수정](https://gitlab.com/gitlab-org/gitlab-runner/-/work_items/29026)

모든 변경 사항 목록은 GitLab Runner [CHANGELOG](https://gitlab.com/gitlab-org/gitlab-runner/blob/19-1-stable/CHANGELOG.md)에 있습니다.
