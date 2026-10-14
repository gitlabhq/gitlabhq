---
title: GitLab Relay (KAS) connections default to gRPC
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: verify
documentation_link: ../../../user/clusters/agent/install/
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/23445
categories: [ GitLab Runner Core, Deployment Management ]
level: secondary
---

GitLab Relay (KAS) now uses gRPC by default. GitLab.com advertised `grpcs://kas.gitlab.com` in
GitLab 19.4. In GitLab 19.5, new Linux package and Helm chart installations advertise
`grpcs://` too. New agent installations connect over `grpcs://` instead of gRPC wrapped in WebSocket,
which means one protocol to route and troubleshoot, and less overhead for each connection.

Agents that already connect over `wss://` work, but you should move them.
On GitLab.com, set the agent address to `grpcs://kas.gitlab.com`. For example, use
`--set config.kasAddress=grpcs://kas.gitlab.com` when you upgrade the `gitlab-agent`
Helm chart. On GitLab Self-Managed, use the address shown in the
[agent installation command](../../../user/clusters/agent/install/_index.md)
after you upgrade.
