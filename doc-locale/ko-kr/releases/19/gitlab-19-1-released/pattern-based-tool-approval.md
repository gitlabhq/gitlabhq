---
title: Agentic Chat을 위한 패턴 기반 도구 승인
offering: [ gitlab_com, self_managed, gitlab_dedicated]
tier: [ Premium, Ultimate ]
stage: ai-powered
documentation_link: "../../../user/gitlab_duo_chat/agentic_chat/#approve-tools-in-your-local-environment"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/21850
categories: [ 'Duo Agent Platform', 'Duo Chat', 'Editor Extensions' ]
weight: 50
---

<!-- categories: Duo Agent Platform, Duo Chat, Editor Extensions -->

이전에는 Agentic Chat에서 도구 호출을 승인하도록 요청했을 때, 한 번 승인하거나 나머지 세션 동안 해당 인수를 사용하는 도구 호출을 승인할 수 있었습니다. 다른 인수는 추가 승인이 필요했습니다.

`git` 작업 시리즈와 같이 비슷한 명령을 반복하는 워크플로우는 거의 동일한 프롬프트 스트림을 통해 계속 진행되어야 했습니다.

이제 세 번째 승인 옵션인 **Approve all uses of this tool for session**을 선택할 수 있습니다. 이 옵션은 인수가 승인된 패턴과 일치할 때마다 나머지 세션 동안 도구의 호출을 승인합니다.

패턴 기반 승인은 GitLab UI, GitLab Duo CLI, GitLab for VS Code 및 JetBrains IDE용 GitLab Duo 플러그인에서 Agentic Chat에 사용할 수 있습니다.
