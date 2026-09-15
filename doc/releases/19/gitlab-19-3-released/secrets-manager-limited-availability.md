---
title: GitLab Secrets Manager now available on GitLab.com
tier: [ Premium, Ultimate ]
add_ons: ["GitLab Secrets Manager"]
offering: [ gitlab_com ]
stage: software_supply_chain_security
documentation_link: "../../../ci/secrets/secrets_manager/"
work_item: https://gitlab.com/groups/gitlab-org/-/work_items/10723
categories: [ Secrets Management ]
level: primary
weight: 50
---

Credential leaks often start the same way: a developer needs a secret, has no
good place to put it, and drops it into an over-scoped CI/CD variable or a
committed config file. GitLab Secrets Manager, now in Limited Availability
on GitLab.com, makes credentials more secure and keeps them in the same platform
that runs your pipelines.

Each secret is scoped to the job that needs it, based on environment, branch,
and branch protection, so a compromised credential can't reach more than it's
authorized to. Secrets Manager uses your existing group and project
permissions, so there's no separate access model to maintain. Every create,
update, and read is logged to your audit trail, so a leak investigation
doesn't mean stitching together logs from multiple systems.

GitLab Secrets Manager is an add-on billed through GitLab Credits. Start a free 30-day trial to explore all features. Learn more about billing and trials in the [billing documentation](../../../ci/secrets/secrets_manager/secrets_manager_billing.md).
