---
stage: AI Platform
group: AI Core Infra
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Trouvez des extraits de code pertinents dans votre dépôt en fonction du sens plutôt que par correspondance de mots-clés.
title: Recherche de code sémantique
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Module d'extension : GitLab Duo Core, GitLab Duo Pro ou GitLab Duo Enterprise
- Offre : GitLab.com, GitLab Self-Managed
- Statut : version bêta

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/groups/gitlab-org/-/work_items/16910) en tant que [version bêta](../../policy/development_stages_support.md#beta) dans GitLab 18.7.
- [Ajoutée](https://gitlab.com/gitlab-org/gitlab/-/work_items/588259) à GitLab Duo Core dans GitLab 18.8.
- [Ajoutée](https://gitlab.com/gitlab-org/gitlab/-/issues/590394) à GitLab Premium dans GitLab 18.9.

{{< /history >}}

> [!note]
> Pour la documentation administrateur, consultez [l'administration de la recherche de code sémantique](../../administration/semantic_code_search.md).

Utilisez la recherche de code sémantique pour trouver des extraits de code pertinents dans votre dépôt en fonction du sens plutôt que par correspondance de mots-clés.

La recherche de code sémantique convertit votre base de code en embeddings vectoriels stockés dans une base de données vectorielle. Lorsque vous effectuez une recherche, votre requête est convertie en embedding et comparée à vos embeddings de code afin de trouver des résultats sémantiquement similaires. Cette approche permet de trouver du code pertinent même lorsque les mots-clés ne correspondent pas.

## Prérequis {#prerequisites}

- Sur GitLab Self-Managed, activez la recherche de code sémantique [pour l'instance](../../administration/semantic_code_search.md). Sur GitLab.com, la recherche de code sémantique est activée par défaut.
- Activez les fonctionnalités en version bêta et expérimentales :
  - Sur GitLab.com, [pour le groupe principal](../duo_agent_platform/turn_on_off.md#on-gitlabcom-3).
  - Sur GitLab Self-Managed, [pour l'instance](../duo_agent_platform/turn_on_off.md#on-gitlab-self-managed-3).
- Activez GitLab Duo [pour le projet](../duo_agent_platform/turn_on_off.md).

## Utiliser la recherche de code sémantique {#use-semantic-code-search}

La recherche de code sémantique est disponible via plusieurs interfaces :

- API REST : utilisez le [point de terminaison `GET /api/v4/projects/:id/search/semantic`](../../api/search.md#semantic-search) pour rechercher dans votre base de code de manière programmatique.
- Outil serveur MCP : utilisez l'outil [`semantic_code_search`](../model_context_protocol/mcp_server_tools.md#semantic_search) dans les workflows agentiques.
- CLI : utilisez la commande [`glab search semantic`](https://docs.gitlab.com/cli/search/semantic/) pour un accès en ligne de commande.

## Indexation initiale ad hoc {#ad-hoc-initial-indexing}

Lors de votre première utilisation de la recherche de code sémantique dans un projet GitLab :

- Le code de votre dépôt est indexé et converti en embeddings vectoriels.
- Ces embeddings sont stockés dans votre magasin de vecteurs configuré.
- Les mises à jour sont traitées de manière incrémentielle lorsque du code est poussé vers la branche par défaut.

L'indexation initiale peut prendre du temps pour les dépôts volumineux.
