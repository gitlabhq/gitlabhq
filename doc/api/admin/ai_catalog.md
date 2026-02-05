---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: REST API to manage the AI Catalog.
title: AI Catalog admin API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Seed GitLab-managed external agents

{{< details >}}

Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221986) as an experiment in GitLab 18.8.

{{< /history >}}

Use this API to seed the AI Catalog with [GitLab-managed external agents](../../user/duo_agent_platform/agents/external.md#gitlab-managed-external-agents).

This feature is an [experiment](../../policy/development_stages_support.md) and may change or be removed in future releases.

Prerequisites:

- You must be an administrator.

```plaintext
POST /api/v4/admin/ai_catalog/seed_external_agents
```

Example request:

```plaintext
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://primary.example.com/api/v4/admin/ai_catalog/seed_external_agents"
```

Success response (HTTP 201):

```json
{
    "message": "External agents seeded successfully"
}
```

Example error response (HTTP 422):

```json
{
    "message": "Error: External agents already seeded"
}
```

Error response - user is not an admin (HTTP 403):

```json
{
    "message": "403 Forbidden"
}
```
