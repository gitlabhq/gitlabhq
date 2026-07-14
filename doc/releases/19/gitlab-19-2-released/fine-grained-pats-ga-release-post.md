---
title: "Fine-grained PAT permissions generally available"
tier: [Free, Premium, Ultimate]
offering: [gitlab_com, self_managed, gitlab_dedicated]
stage: software_supply_chain_security
documentation_link: "../../../auth/tokens/fine_grained_access_tokens/"
work_item: "https://gitlab.com/groups/gitlab-org/-/work_items/18554"
categories: [Permissions]
weight: 50
---

Fine-grained personal access tokens (PATs) are now generally available. Unlike legacy PATs, which grant access to every project and group you belong to, fine-grained PATs allow you to limit each token to specific resources and actions. This makes it easier to apply the principle of least privilege to automation and integrations, which helps reduce the potential impact of a leaked or compromised token.

To make setup easier, use the **Add permissions with Duo** feature to choose the correct permissions during token creation. Your existing legacy PATs continue to work as before. For new tokens, GitLab recommends fine-grained PATs so each token is scoped only to the resources and actions it needs.

With the GA release, fine-grained PATs now have complete coverage for REST API endpoints, and coverage for the most commonly used GraphQL types and mutations.
