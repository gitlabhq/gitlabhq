---
title: Other improvements
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: agent_foundations
co_create: true
documentation_link: "../../../user/model_context_protocol/mcp_server_troubleshooting/#error-rate_limited-tool-result"
work_item: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256657
categories: [ Agent Tools ]
level: secondary
weight: 80
---

Other improvements in this release include:

- GitLab MCP server: rate-limited tool results name the limit and retry delay, `add_branch`
  returns the branch `web_url`, tool aliases in the enabled-tools header resolve, mismatched
  URL and project ID inputs are rejected, and `ai_workflows` tokens can read blobs in batch.
- Administrators in admin mode can set a cluster agent on an environment without joining
  the project.
- `CI_JOB_TAGS` and `CI_RUNNER_TAGS` JSON-encode each tag. Duplicate variable keys in push
  options are rejected.
- Advanced SAST (Ultimate): C and C++ files up to 20 levels deep are scanned, and the report
  follows your artifact retention.
- Plain-text token and SSH key emails link to the right page, and `?scopes=` links prefill the
  token form.

Thank you to the following users for these contributions!

- [otutukingsley](https://gitlab.com/otutukingsley) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256657))
- [Jeston Singh](https://gitlab.com/sjestonsingh) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255143) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255111) [MR 3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255142) [MR 4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/253823) [MR 5](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254734) [MR 6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254613))
- [ryo-whaletech](https://gitlab.com/ryo-whaletech) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254573) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256563) [MR 3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256718))
- [Mohamed Elsayed](https://gitlab.com/MooSayed11) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/256268))
- [Gerardo Navarro](https://gitlab.com/gerardo-navarro) ([MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169626))
- [Torben Buck](https://gitlab.com/torben.buck) ([MR 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254859) [MR 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/255638) [MR 3](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/254871))
