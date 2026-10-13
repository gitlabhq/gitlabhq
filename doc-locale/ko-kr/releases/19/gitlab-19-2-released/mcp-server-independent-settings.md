---
title: Agent Platform과 독립적으로 MCP 서버 활성화
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server/"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/590729
categories: [ AI Agents ]
level: secondary
weight: 50
---

외부 도구가 GitLab 인스턴스 또는 그룹에 연결되는 방식을 더 세밀하게 제어하기 위해 Agent Platform 설정과 독립적으로 GitLab MCP 서버를 활성화하거나 비활성화할 수 있습니다.

이전에는 GitLab MCP 서버와 Agent Platform이 동일한 활성화/비활성화 설정을 공유했으므로 Agent Platform 기능도 활성화하지 않으면 MCP 서버를 활성화할 수 없었습니다. 이제 Agent Platform을 활성화하지 않고도 다른 도구가 GitLab을 MCP 서버로 액세스하도록 허용하거나, Agent Platform 기능을 사용하는 동안 GitLab MCP 서버를 비활성화 상태로 유지할 수 있습니다.
