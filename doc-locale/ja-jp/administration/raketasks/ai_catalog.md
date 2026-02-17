---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: AIカタログRakeタスク
---

{{< details >}}

- プラン: Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabでは、次の外部エージェントを使用して、自己管理型AIカタログをシードするためのRakeタスクが用意されています:

- GitLabのClaudeエージェント<https://gitlab.com/explore/ai-catalog/agents/2057/>
- GitLabのCodexエージェント<https://gitlab.com/explore/ai-catalog/agents/513/>

## AIカタログの外部エージェントをシードします {#seed-ai-catalog-external-agents}

{{< tabs >}}

{{< tab title="Linuxパッケージ（Omnibus）" >}}

```shell
sudo gitlab-rake gitlab:ai_catalog:seed_external_agents
```

{{< /tab >}}

{{< tab title="自己コンパイル（ソース）" >}}

```shell
bundle exec rake gitlab:ai_catalog:seed_external_agents
```

{{< /tab >}}

{{< /tabs >}}
