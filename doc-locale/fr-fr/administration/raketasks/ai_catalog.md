---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Tâches Rake du catalogue d'IA"
---

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab fournit une tâche Rake pour alimenter les catalogues d'IA auto-gérés avec les agents externes suivants :

- Claude Agent par GitLab <https://gitlab.com/explore/ai-catalog/agents/2057/>
- Codex Agent par GitLab <https://gitlab.com/explore/ai-catalog/agents/513/>

## Alimenter le catalogue d'IA en agents externes {#seed-ai-catalog-external-agents}

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:ai_catalog:seed_external_agents
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
bundle exec rake gitlab:ai_catalog:seed_external_agents
```

{{< /tab >}}

{{< /tabs >}}
