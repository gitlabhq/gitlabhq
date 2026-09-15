---
title: "자동 코드 검토에서 머지 리퀘스트 제외하기 (베타)"
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
tier: [ Free, Premium, Ultimate ]
stage: ai_coding
documentation_link: "../../../user/duo_agent_platform/flows/foundational_flows/code_review/#exclude-merge-requests-from-automatic-reviews"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21585
categories: [ DAP Code Review ]
---


이전 버전의 GitLab에서는 프로젝트 또는 그룹에 대해 자동 검토가 설정되면 GitLab Duo가 모든 적격 머지 리퀘스트를 검토했습니다. 이는 봇이 작성한 종속성 업데이트, 기능 브랜치, 실험적 작업 등 팀이 실제로 피드백을 원하는 변경 사항뿐만 아니라 모든 것을 포함했습니다.

이제 제외 규칙을 사용하여 특정 머지 리퀘스트를 자동 검토에서 제외할 수 있습니다. 프로젝트 또는 그룹에 대해 `.gitlab/duo/mr-review-automated-rules.yaml` 파일을 정의하고, 작성자, 소스 브랜치, 또는 대상 브랜치를 기준으로 제외 규칙을 설정합니다. 규칙은 `dependabot/*` 또는 `*-bot`과 같은 glob 패턴을 지원합니다.

제외된 머지 리퀘스트에 대해 여전히 수동으로 검토를 요청할 수 있습니다.

이 기능은 베타 단계이며 `duo_code_review_automated_rules` 기능 플래그 뒤에 있으며, 기본적으로 활성화되어 있습니다.
