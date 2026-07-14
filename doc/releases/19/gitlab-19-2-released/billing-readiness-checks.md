---
title: Usage billing checks for GitLab Duo Agent Platform Self-Hosted
offering: [ self_managed, gitlab_dedicated_for_government ]
tier: [ Premium, Ultimate ]
stage: ai-powered
documentation_link: "../../../administration/gitlab_duo/configure/#run-a-health-check-for-gitlab-duo"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/603196
categories: [ Health & Connectivity ]
level: secondary
---

<!-- categories: Health & Connectivity  -->

For GitLab Self-Managed customers using self-hosted models with an online license, the GitLab Duo Health now checks that the GitLab instance can reach the following endpoints:

- Customers Portal
- The AI Gateway
- Duo Workflow Service

Connection to these endpoints is necessary for usage billing.

Previously, if a firewall blocked any of these components, administrators had no indication of connectivity issues until users were unable to use a feature. Administrators can now use this new validation check to diagnose issues and review their firewall allowlist before any disruption to users.
