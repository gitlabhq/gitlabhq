---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: AI Catalog rake tasks
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

GitLab provides a Rake task for seeding Self-managed AI Catalogs with the following external agents:

- Claude Agent by GitLab <https://gitlab.com/explore/ai-catalog/agents/2057/>
- Codex Agent by GitLab <https://gitlab.com/explore/ai-catalog/agents/513/>

## Seed AI catalog external agents

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ai_catalog:seed_external_agents
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```shell
bundle exec rake gitlab:ai_catalog:seed_external_agents
```

{{< /tab >}}

{{< /tabs >}}
