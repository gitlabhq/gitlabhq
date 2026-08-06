---
title: 플로우 및 외부 에이전트에 대한 새로운 이벤트 트리거
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Premium, Ultimate ]
documentation_link: "../../../user/duo_agent_platform/triggers/#create-a-trigger"
categories: [ Duo Agent Platform ]
level: secondary
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21997
stage: ai-powered
---

<!-- categories: Duo Agent Platform -->

이전 버전의 GitLab에서는 서비스 계정이 멘션되거나 할당되거나 검토자로 추가된 경우에만 플로우와 외부 에이전트를 실행할 수 있었습니다. 머지 리퀘스트 수명 주기의 그 외 부분이나 작업 항목 생성과 관련된 자동화를 조율하려면 외부 연동 도구가 필요했습니다.

이제 다음 4가지 추가 이벤트에 대한 트리거를 구성할 수 있습니다.

- **머지 리퀘스트 준비됨**: 사용자가 초안 머지 리퀘스트를 검토 준비 완료 상태로 표시합니다. 이전에는 기능 플래그 뒤에 숨겨져 릴리스되었으나, 이제 이 이벤트 트리거가 정식 버전(GA)으로 제공됩니다.
- **머지 리퀘스트 코드 충돌**: 코드 충돌로 인해 머지 리퀘스트를 더 이상 병합할 수 없는 상태입니다.
- **머지 리퀘스트 승인됨**: 머지 리퀘스트가 필요한 승인을 모두 받은 상태입니다.
- **작업 항목 생성됨**: 사용자가 프로젝트에서 작업 항목을 생성합니다.

트리거를 구성하려면 프로젝트의 **AI** > **트리거**로 이동하거나 플로우를 활성화할 때 하나를 선택합니다.
