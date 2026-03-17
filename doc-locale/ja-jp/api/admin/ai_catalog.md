---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: AIカタログを管理するためのAPIです。
title: AIカタログ管理者API
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed、GitLab Dedicated

{{< /details >}}

## GitLabで管理される外部エージェントのseed {#seed-gitlab-managed-external-agents}

{{< details >}}

ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221986)：GitLab 18.8の実験。

{{< /history >}}

このAPIを使用して、[GitLabで管理される外部エージェント](../../user/duo_agent_platform/agents/external.md)でAIカタログをseedします。

この機能は[実験](../../policy/development_stages_support.md)であり、今後のリリースで変更または削除される可能性があります。

前提条件: 

- 管理者である必要があります。

```plaintext
POST /api/v4/admin/ai_catalog/seed_external_agents
```

リクエスト例: 

```plaintext
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://primary.example.com/api/v4/admin/ai_catalog/seed_external_agents"
```

成功レスポンス（HTTP 201）:

```json
{
    "message": "External agents seeded successfully"
}
```

エラーレスポンスの例（HTTP 422）:

```json
{
    "message": "Error: External agents already seeded"
}
```

エラーレスポンス - ユーザーは管理者ではありません（HTTP 403）:

```json
{
    "message": "403 Forbidden"
}
```
