---
title: GitLab Secrets Manager is generally available
tier: [ Premium, Ultimate ]
add_ons: ["GitLab Secrets Manager"]
offering: [ gitlab_com, self_managed ]
stage: software_supply_chain_security
documentation_link: "../../../ci/secrets/secrets_manager/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/10723
categories: [ Secrets Management ]
level: primary
weight: 50
---

Without a centralized secrets store, credentials can become scattered across over-scoped CI/CD variables, local config files, and standalone vaults. This makes them harder to manage, protect, and audit.

GitLab Secrets Manager is now generally available on GitLab.com and GitLab Self-Managed. Built on OpenBao, it uses your existing group and project permissions, so there's no separate access model to maintain. Each CI secret is scoped to the job that needs it, based on environment, branch, and branch protection rules. Audit logs are generated for every create, read, update, and delete.

GitLab Secrets Manager consumes GitLab Credits. [Start a free 30-day trial](../../../ci/secrets/secrets_manager/credit_usage.md#start-a-trial) or [enable it for your group or instance](../../../ci/secrets/secrets_manager/_index.md#enable-gitlab-secrets-manager).
