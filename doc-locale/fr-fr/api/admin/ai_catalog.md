---
stage: AI-powered
group: Workflow Catalog
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "API REST pour gérer le catalogue d'IA."
title: "API REST d'administration du catalogue d'IA"
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Amorcer les agents externes gérés par GitLab {#seed-gitlab-managed-external-agents}

{{< details >}}

Statut :  Expérience

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221986) en tant qu'expérience dans GitLab 18.8.

{{< /history >}}

Utilisez cette API REST pour alimenter le catalogue d'IA avec des [agents externes gérés par GitLab](../../user/duo_agent_platform/agents/external.md).

Cette fonctionnalité est une [expérience](../../policy/development_stages_support.md) et peut être modifiée ou supprimée dans de futures releases.

Prérequis :

- Vous devez être un administrateur.

```plaintext
POST /api/v4/admin/ai_catalog/seed_external_agents
```

Exemple de requête :

```plaintext
curl --request POST \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     --url "https://primary.example.com/api/v4/admin/ai_catalog/seed_external_agents"
```

Réponse en cas de succès (HTTP 201) :

```json
{
    "message": "External agents seeded successfully"
}
```

Exemple de réponse d'erreur (HTTP 422) :

```json
{
    "message": "Error: External agents already seeded"
}
```

Réponse d'erreur - l'utilisateur n'est pas un administrateur (HTTP 403) :

```json
{
    "message": "403 Forbidden"
}
```
