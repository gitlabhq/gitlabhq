---
title: GitLab Duo CLI이 이제 일반 공급됩니다
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: ai_clients
documentation_link: "../../../user/gitlab_duo_cli"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/19717
categories: [ Duo CLI ]
level: primary
weight: 10
---

GitLab Duo CLI는 GitLab Duo Agent Platform을 터미널로 직접 가져옵니다. 

CLI를 사용하여 코드베이스에 대한 복잡한 질문을 하고 자율적으로 사용자를 대신하여 작업을 수행합니다. 외부 도구와 달리 CLI는 GitLab 프로젝트, 파이프라인 및 에이전트 구성에 대한 컨텍스트를 가집니다.

주요 기능은 다음과 같습니다.

- 두 가지 모드: 대화형 채팅 모드 및 CI/CD용 헤드리스 모드
- GitLab Self-Managed 및 GitLab Dedicated에 대한 관리자 켜기/끄기 제어
- 모델 선택 및 공유 세션
- 승인 도구
- Model Context Protocol (MCP) 연결
- 슬래시 명령어(컨텍스트 사용 및 컨텍스트 압축을 위한 명령어 포함)
- 기술 및 `AGENTS.md` 사용자 지정 파일 지원

GitLab CLI (`glab`)를 통해 또는 독립 실행형 도구로 GitLab Duo CLI를 설치합니다.
