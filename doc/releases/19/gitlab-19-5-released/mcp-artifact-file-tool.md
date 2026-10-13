---
title: MCP server CI/CD artifact tool
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
documentation_link: "../../../user/model_context_protocol/mcp_server_tools"
work_item: https://gitlab.com/gitlab-org/gitlab/-/issues/585022
categories: [ Agent Tools ]
level: secondary
weight: 50
---

Previously, if you needed an agent to check something inside a CI/CD job's build artifacts, it had to
download and unzip the whole archive just to read one file. Now the `get_artifact_file` MCP
tool lets your agent read a single file directly from a job's artifacts, whether it's a log, a
generated report, or a test fixture.
