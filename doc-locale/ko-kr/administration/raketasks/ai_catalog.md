---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: AI 카탈로그 Rake 작업
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab은 다음 외부 에이전트로 Self-managed AI 카탈로그를 시드하기 위한 Rake 작업을 제공합니다:

- GitLab의 Claude Agent <https://gitlab.com/explore/ai-catalog/agents/2057/>
- GitLab의 Codex Agent <https://gitlab.com/explore/ai-catalog/agents/513/>

## AI 카탈로그 외부 에이전트 시드 {#seed-ai-catalog-external-agents}

{{< tabs >}}

{{< tab title="Linux 패키지(Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ai_catalog:seed_external_agents
```

{{< /tab >}}

{{< tab title="직접 컴파일된 설치(소스)" >}}

```shell
bundle exec rake gitlab:ai_catalog:seed_external_agents
```

{{< /tab >}}

{{< /tabs >}}
