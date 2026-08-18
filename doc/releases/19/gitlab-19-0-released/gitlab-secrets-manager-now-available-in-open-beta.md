---
title: GitLab Secrets Manager now available in open beta
stage: software_supply_chain_security
level: primary
tier: [ Premium, Ultimate ]
offering: [ gitlab_com, self_managed ]
documentation_link: "../../../ci/secrets/secrets_manager/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/21731"
categories: [ Secrets Management ]
weight: 30
---

In previous versions of GitLab, the GitLab Secrets Manager was available only to a closed beta
cohort. Most teams relied on external services such as HashiCorp Vault or AWS Secrets Manager.

The GitLab Secrets Manager is now available in open beta for Premium and Ultimate customers on
GitLab.com and GitLab Self-Managed. When the GitLab Secrets Manager is enabled, project and group Owners
can store, retrieve, and reference CI/CD secrets in GitLab. Secrets are scoped to a project or group
and are accessible to only pipeline jobs that explicitly request them.

During open beta, GitLab Secrets Manager follows the
[beta support policy](../../../policy/development_stages_support.md#beta) and might not be ready for production use.

To share feedback, see [issue 598100](https://gitlab.com/gitlab-org/gitlab/-/issues/598100).
