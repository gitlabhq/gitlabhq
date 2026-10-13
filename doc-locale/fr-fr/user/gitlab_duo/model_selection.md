---
stage: AI Platform
group: AI Model Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurer les grands modèles de langage pour les fonctionnalités GitLab Duo.
title: "Modèles d'IA GitLab Duo"
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Module d'extension : GitLab Duo Core, GitLab Duo Pro ou GitLab Duo Enterprise
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Chaque fonctionnalité GitLab Duo utilise un modèle par défaut. GitLab peut mettre à jour les modèles par défaut pour optimiser les performances. Les modifications de modèles proviennent de la passerelle d'IA GitLab et prennent effet indépendamment de votre version de GitLab.

Vous pouvez sélectionner un modèle différent pour une fonctionnalité, ce choix étant conservé jusqu'à ce que vous le modifiiez.

## Modèles par défaut {#default-models}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/work_items/614057) du paramètre de modèle pour GitLab Duo Code Review en **Non-Agentic Code Review** dans GitLab 19.4.

{{< /history >}}

Le tableau suivant répertorie le modèle par défaut pour chaque fonctionnalité GitLab Duo.

| Fonctionnalité | Modèle |
|---------|---------------|
| **Suggestions de code** | |
| Génération de code | Claude Sonnet 4.6 Vertex |
| Complétion de code | Codestral 25.08 Fireworks |
| **GitLab Duo Chat** | |
| Chat général | Claude Sonnet 4.6 Vertex |
| Explication de code | Claude Sonnet 4.6 Vertex |
| Génération de tests | Claude Sonnet 4.6 Vertex |
| Refactorisation de code | Claude Sonnet 4.6 Vertex |
| Correction de code | Claude Sonnet 4.6 Vertex |
| Analyse des causes profondes | Claude Sonnet 4.6 Vertex |
| **GitLab Duo pour les requêtes de fusion** | |
| Génération de messages de commit de fusion | Claude Sonnet 4.6 Vertex|
| Résumé de la merge request | Claude Sonnet 4.6 Vertex |
| Résumé de la revue de code | Claude Sonnet 4.6 Vertex |
| Non-Agentic Code Review | Claude Sonnet 4.5 Vertex |
| **Autres fonctionnalités GitLab Duo** | |
| Explication des vulnérabilités | Claude Sonnet 4.6 Vertex |
| Résolution des vulnérabilités | Claude Sonnet 4.6 Vertex |
| Résumé des discussions | Claude Sonnet 4.6 Vertex |
| GitLab Duo pour CLI | Claude Sonnet 4.6 Vertex |

## Modèles pris en charge {#supported-models}

{{< history >}}

- [Modification](https://gitlab.com/gitlab-org/gitlab/-/work_items/614057) du paramètre de modèle pour GitLab Duo Code Review en **Non-Agentic Code Review** dans GitLab 19.4.

{{< /history >}}

Les tableaux suivants répertorient les modèles que vous pouvez sélectionner pour chaque fonctionnalité.

### Suggestions de code {#code-suggestions}

| Modèle | Génération de code | Complétion de code |
|------------|-----------------|-----------------|
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} |
| Codestral 25.01 Fireworks | {{< no >}} | {{< yes >}} |
| Codestral 25.08 Fireworks | {{< no >}} | {{< yes >}} |
| Codestral 25.08 Vertex | {{< no >}} | {{< yes >}} |
| Gemini 2.5 Flash Vertex | {{< yes >}} | {{< no >}} |

### GitLab Duo Non-Agentic Chat {#gitlab-duo-non-agentic-chat}

| Modèle | Chat général | Explication de code | Génération de tests | Refactorisation de code | Correction de code | Analyse des causes profondes |
|------------|--------------|------------------|-----------------|---------------|----------|---------------------|
| Claude Haiku 4.5 | {{< yes >}} | {{< no >}} | | | {{< no >}} | |
| Claude Sonnet 3 | {{< no >}} | | | {{< no >}} | | {{< yes >}} |
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 Vertex | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |  |
| Claude Sonnet 4.6 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.6 Vertex | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |  |

### GitLab Duo pour les requêtes de fusion {#gitlab-duo-for-merge-requests}

| Modèle | Génération de messages de commit de fusion | Résumé de la merge request | Résumé de la revue de code | Non-Agentic Code Review |
|------------|--------------------------------|------------------------|---------------------|-------------|
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 Vertex | {{< no >}} | {{< no >}} | {{< no >}} | {{< yes >}} |
| Claude Sonnet 4.6 | {{< no >}} | {{< no >}} | {{< no >}} | {{< yes >}} |
| Claude Sonnet 4.6 Vertex | {{< no >}} | {{< no >}} | {{< no >}} | {{< yes >}} |

### Autres fonctionnalités GitLab Duo {#other-gitlab-duo-features}

| Modèle | Explication des vulnérabilités | Résolution des vulnérabilités | GitLab Duo pour CLI | Résumé des discussions |
|------------|----------------------------|--------------------------|-------------------|---------------------|
| Claude Haiku 3 | {{< yes >}} | {{< no >}} | {{< yes >}} | {{< no >}} |
| Claude Haiku 4.5 | {{< no >}} | | {{< yes >}} | {{< no >}} |
| Claude Sonnet 4.5 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.5 Vertex | {{< yes >}} |  |  | {{< yes >}} |
| Claude Sonnet 4.6 | {{< yes >}} | {{< yes >}} | {{< yes >}} | {{< yes >}} |
| Claude Sonnet 4.6 Vertex | {{< yes >}} |  |  | {{< yes >}} |

## Sélectionner un modèle pour une fonctionnalité {#select-a-model-for-a-feature}

{{< details >}}

- Offre : GitLab.com

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/work_items/17570) pour les groupes principaux dans GitLab 18.1 avec un [feature flag](../../administration/feature_flags/_index.md) nommé `ai_model_switching`. Désactivé par défaut.
- [Passage](https://gitlab.com/gitlab-org/gitlab/-/issues/526307) en version bêta dans GitLab 18.4.
- [Activation](https://gitlab.com/gitlab-org/gitlab/-/issues/526307) dans GitLab 18.4.
- [Passage en disponibilité générale](https://gitlab.com/groups/gitlab-org/-/work_items/18818) dans GitLab 18.5. Le feature flag `ai_model_switching` a été activé.
- [Suppression](https://gitlab.com/gitlab-org/gitlab/-/issues/526307) du feature flag `ai_model_switching` dans GitLab 18.7.

{{< /history >}}

Vous pouvez sélectionner un modèle pour une fonctionnalité dans un groupe principal. Le modèle que vous sélectionnez s'applique à cette fonctionnalité dans tous les sous-groupes et tous les projets de ce groupe.

Pour définir un modèle pour une instance sur GitLab Self-Managed ou GitLab Dedicated, consultez [la sélection du modèle](../../administration/gitlab_duo/model_selection.md).

Prérequis :

- Disposer du rôle Propriétaire pour le groupe.
- Le groupe pour lequel vous sélectionnez des modèles est un groupe principal.
- Dans GitLab 18.3 ou une version ultérieure, si vous appartenez à plusieurs espaces de nommage GitLab Duo, vous devez [attribuer un espace de nommage par défaut](../profile/preferences.md#set-a-default-gitlab-duo-namespace).

Pour sélectionner un modèle pour une fonctionnalité :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **GitLab Duo**.
1. Sous **Sélection du modèle**, sélectionnez **Gérer les modèles**.
1. Trouvez la fonctionnalité que vous souhaitez configurer et sélectionnez un modèle dans la liste déroulante.
1. Facultatif. Pour appliquer le modèle à toutes les fonctionnalités d'une section, sélectionnez **Appliquer à tous**.

### Choisir le modèle adapté {#selecting-the-right-model}

Dans de nombreux cas d'utilisation, un modèle plus rapide et plus économique, comme Claude Haiku 4.5 ou GPT-5.4 Mini, peut constituer le meilleur point de départ. Pour appliquer cette approche :

1. Sélectionnez Claude Haiku 4.5 ou GPT-5.4 Mini.
1. Testez votre cas d'utilisation en profondeur.
1. Vérifiez si les performances répondent à vos exigences.
1. Ne passez à un modèle supérieur que si des capacités précises font défaut.

Vous pouvez utiliser cette approche dans les cas suivants :

- Tâches exploratoires ou à volume élevé
- Applications soumises à des exigences strictes en matière de latence
- Implémentations soumises à de fortes contraintes de coût

## Dépannage {#troubleshooting}

Lorsque vous sélectionnez des modèles autres que le modèle par défaut, vous pouvez rencontrer les problèmes suivants.

### Le modèle n'est pas disponible {#model-is-not-available}

Si vous utilisez le modèle GitLab par défaut pour une fonctionnalité GitLab Duo native à l'IA, GitLab est susceptible de modifier le modèle par défaut afin de maintenir des performances et une fiabilité optimales, sans vous en informer.

Si vous avez sélectionné un modèle spécifique pour une fonctionnalité d'IA native de GitLab Duo et que ce modèle n'est pas disponible, aucun mécanisme de repli automatique n'est prévu. La fonctionnalité qui utilise ce modèle n'est pas disponible.

### Aucun espace de nommage GitLab Duo par défaut {#no-default-gitlab-duo-namespace}

Lorsque vous utilisez une fonctionnalité GitLab Duo avec un modèle sélectionné, un message d'erreur peut indiquer que vous devez définir un espace de nommage GitLab Duo par défaut.

Ce problème se produit lorsque vous appartenez à plusieurs espaces de nommage GitLab Duo ou que vous travaillez localement sur un projet qui ne possède aucun dépôt distant GitLab configuré.

Pour résoudre ce problème, [définissez un espace de nommage GitLab Duo par défaut](../profile/preferences.md#set-a-default-gitlab-duo-namespace).
