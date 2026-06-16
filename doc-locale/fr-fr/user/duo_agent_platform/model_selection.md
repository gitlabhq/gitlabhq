---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurer les grands modèles de langage pour les fonctionnalités GitLab Duo.
title: "Modèles d'IA de l'Agent Platform"
---

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Chaque fonctionnalité GitLab Duo utilise un modèle par défaut. GitLab peut mettre à jour les modèles par défaut pour optimiser les performances. Pour certaines fonctionnalités, vous pouvez sélectionner un modèle différent, qui persiste jusqu'à ce que vous le modifiiez.

## Modèles par défaut {#default-models}

Ce tableau répertorie le modèle par défaut pour chaque fonctionnalité de l'Agent Platform.

| Fonctionnalité | Modèle |
|-------|--------------|
| GitLab Duo Agentic Chat | Claude Sonnet 4.6 Vertex |
| flow Code Review | Claude Sonnet 4.6 Vertex |
| Tous les autres agents | Claude Sonnet 4.5 Vertex |

## Modèles pris en charge {#supported-models}

Ce tableau répertorie les modèles que vous pouvez sélectionner pour les fonctionnalités de l'Agent Platform.

| Modèle                | GitLab Duo Agentic Chat | flow Code Review | Tous les autres agents |
|----------------------|-------------------------|------------------|------------------|
| Claude Sonnet 4      | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| Claude Sonnet 4.5    | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| Claude Sonnet 4.6    | {{< yes >}}             | {{< yes >}}      | {{< yes >}}      |
| Claude Haiku 4.5     | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.5      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.6      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| Claude Opus 4.7      | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5                | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.1              | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.2              | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.5 <sup>1</sup> | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5 Codex          | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.2 Codex        | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.3 Codex        | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5 Mini           | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.4 Mini         | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |
| GPT-5.4 Nano         | {{< yes >}}             | {{< no >}}       | {{< yes >}}      |

**Footnotes** :

1. Ce modèle est soumis à une [conservation des données limitée côté fournisseur](../gitlab_duo/data_usage.md#data-retention).

## Sélectionner un modèle pour une fonctionnalité {#select-a-model-for-a-feature}

{{< details >}}

- Offre : GitLab.com

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/17570) pour les groupes principaux dans GitLab 18.1 avec un [flag](../../administration/feature_flags/_index.md) nommé `ai_model_switching`. Désactivé par défaut.
- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/526307) en version bêta dans GitLab 18.4.
- [Activé](https://gitlab.com/gitlab-org/gitlab/-/issues/526307) dans GitLab 18.4.
- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/568112) de la sélection de modèles pour GitLab Duo Agent Platform dans GitLab 18.4 avec un [flag](../../administration/feature_flags/_index.md) appelé `duo_agent_platform_model_selection`. Désactivé par défaut.
- [Disponible en version générale](https://gitlab.com/groups/gitlab-org/-/epics/18818) dans GitLab 18.5. Le feature flag `ai_model_switching` est activé.
- Le feature flag `duo_agent_platform_model_selection` [activé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/212051) dans GitLab 18.6.
- Le feature flag `ai_model_switching` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/526307) dans GitLab 18.7.
- Le feature flag `duo_agent_platform_model_selection` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/218591) dans GitLab 18.9.
- LLM [mis à jour](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876) vers Claude Sonnet 4.6 Vertex pour le flow Code Review dans GitLab 19.1.
- [Sélection de modèle séparée](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/236876) de GitLab Duo Code Review introduite pour le flow Code Review dans GitLab 19.1, à l'aide du paramètre **Revue de code Agentic**.

{{< /history >}}

Vous pouvez sélectionner un modèle pour une fonctionnalité dans un groupe principal. Le modèle que vous sélectionnez s'applique à cette fonctionnalité pour tous les sous-groupes et projets enfants.

Prérequis :

- Vous avez le rôle Propriétaire pour le groupe.
- Le groupe pour lequel vous sélectionnez des modèles est un groupe principal.
- Dans GitLab 18.3 ou version ultérieure, si vous appartenez à plusieurs espaces de nommage GitLab Duo, vous devez [attribuer un espace de nommage par défaut](../profile/preferences.md#set-a-default-gitlab-duo-namespace).

Pour sélectionner un modèle pour une fonctionnalité :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. Sélectionnez **Configurer les fonctionnalités**.
1. Accédez à la section **GitLab Duo Agent Platform**.
1. Sélectionnez un modèle dans la liste déroulante.
1. Facultatif. Pour appliquer le modèle à toutes les fonctionnalités de la section, sélectionnez **Appliquer à tous**.

Dans l'IDE, la sélection de modèle pour GitLab Duo Agentic Chat n'est appliquée que lorsque le type de connexion est défini sur WebSocket.

Pour spécifier un modèle pour le GitLab Duo CLI, consultez [sélectionner un modèle](../gitlab_duo_cli/_index.md#select-a-model).

## Dépannage {#troubleshooting}

Lors de la sélection de modèles autres que le modèle par défaut, vous pourriez rencontrer les problèmes suivants.

### Le modèle n'est pas disponible {#model-is-not-available}

Si vous utilisez le modèle GitLab par défaut pour une fonctionnalité GitLab Duo native à l'IA, GitLab peut modifier le modèle par défaut sans en notifier l'utilisateur afin de maintenir des performances et une fiabilité optimales.

Si vous avez sélectionné un modèle spécifique pour une fonctionnalité GitLab Duo native à l'IA, et que ce modèle n'est pas disponible, il n'y a pas de mécanisme de secours automatique. La fonctionnalité qui utilise ce modèle n'est pas disponible.

### Aucun espace de nommage GitLab Duo par défaut {#no-default-gitlab-duo-namespace}

Lors de l'utilisation d'une fonctionnalité GitLab Duo avec un modèle sélectionné, vous pourriez obtenir une erreur indiquant que vous devez définir un espace de nommage GitLab Duo par défaut.

Ce problème survient lorsque vous appartenez à plusieurs espaces de nommage GitLab Duo ou travaillez sur un projet localement qui n'a pas de remote GitLab configuré.

Pour résoudre ce problème, [définissez un espace de nommage GitLab Duo par défaut](../profile/preferences.md#set-a-default-gitlab-duo-namespace).
