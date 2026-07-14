---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AI 카탈로그를 관리하는 REST API입니다.
title: AI 카탈로그 관리자 API
---

{{< details >}}

- 티어:  Premium, Ultimate
- 제공 서비스: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## GitLab 관리 외부 에이전트 시드하기 {#seed-gitlab-managed-external-agents}

{{< details >}}

상태:  실험적 기능

{{< /details >}}

{{< history >}}

- GitLab 18.8에서 실험으로 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221986).

{{< /history >}}

이 API를 사용하여 [GitLab 관리 외부 에이전트](../../user/duo_agent_platform/agents/external.md)로 AI 카탈로그를 시드합니다.

이 기능은 [실험](../../policy/development_stages_support.md)이며 향후 릴리스에서 변경되거나 제거될 수 있습니다.

전제 조건:

- 관리자(administrator) 권한이 있어야 합니다.

```plaintext
POST /api/v4/admin/ai_catalog/seed_external_agents
```

요청 예시:

```plaintext
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://primary.example.com/api/v4/admin/ai_catalog/seed_external_agents"
```

성공 응답(HTTP 201):

```json
{
    "message": "External agents seeded successfully"
}
```

오류 응답 예시(HTTP 422):

```json
{
    "message": "Error: External agents already seeded"
}
```

오류 응답 - 사용자가 관리자가 아님(HTTP 403):

```json
{
    "message": "403 Forbidden"
}
```
