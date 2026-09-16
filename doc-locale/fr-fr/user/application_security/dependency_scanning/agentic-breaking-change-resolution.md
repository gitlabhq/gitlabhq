---
stage: Application Security Testing
group: Composition Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Résolution agentique des modifications incompatibles
description: Résolution native par IA des problèmes liés aux merge requests qui mettent à niveau les dépendances.
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/groups/gitlab-org/-/work_items/17884) dans GitLab 19.2 en tant que fonctionnalité en [version bêta](../../../policy/development_stages_support.md#beta) avec des [feature flags](../../../administration/feature_flags/_index.md) nommés `enable_dependency_bump_breaking_changes` et `dependency_bump_web_search`.

{{< /history >}}

La résolution agentique des modifications incompatibles est un flow par défaut optionnel qui :

- Analyse les pipelines en échec sur les merge requests qui mettent à niveau les dépendances.
- Génère des correctifs pour résoudre les modifications incompatibles introduites par la mise à jour des dépendances.

> [!warning]
> Lorsque cette fonctionnalité est activée, les journaux de pipeline et le contexte du code de la merge request concernée sont envoyés à des grands modèles de langage (LLM) à des fins d'analyse. Passez en revue les politiques de données de votre organisation avant d'activer cette fonctionnalité.

Dans ce flow par défaut, GitLab Duo :

- Examine les journaux d'erreurs du pipeline pour identifier la cause principale de l'échec.
- Analyse les journaux de modifications des dépendances et les notes de release pour identifier les modifications incompatibles.
- Examine les patterns d'utilisation du code de la dépendance mise à jour.
- Génère et commite les correctifs de code directement dans la branche de la MR de mise à niveau des dépendances.
- Relance le pipeline après application des correctifs.

Les résultats sont basés sur une analyse par IA et doivent être revus par un développeur avant la fusion.

## Prérequis {#prerequisites}

- [GitLab Duo doit être activé](../../gitlab_duo/turn_on_off.md) dans votre projet ou votre groupe.
- [Un espace de nommage GitLab Duo par défaut doit être défini](../../profile/preferences.md#set-a-default-gitlab-duo-namespace) dans vos préférences utilisateur.
- [Remédiation automatique de l'analyse des dépendances](../remediate/auto_remediation.md) activée pour le projet. La résolution agentique des modifications incompatibles agit sur les merge requests de mise à niveau des dépendances créées par la remédiation automatique.

## Activer la résolution agentique des modifications incompatibles {#enable-agentic-breaking-change-resolution}

La fonctionnalité est désactivée par défaut et doit être explicitement activée au niveau du groupe et du projet.

### Activer ce flow par défaut dans un groupe principal {#turn-on-this-foundational-flow-in-a-top-level-group}

Pour autoriser tous les projets d'un groupe à utiliser le flow par défaut :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Sélectionnez **Paramètres** > **GitLab Duo**.
1. Sous **Autoriser les flows par défaut**, cochez la case **Résoudre les modifications incompatibles provoquées par les mises à niveau de dépendances**.
1. Sélectionnez **Enregistrer les modifications**.

### Activer ce flow par défaut pour un projet {#turn-on-this-foundational-flow-for-a-project}

Prérequis :

- Disposer du rôle Chargé de maintenance ou Propriétaire pour le projet.
- Le flow par défaut activé pour le groupe principal.

Pour activer la résolution agentique des modifications incompatibles pour un projet spécifique :

1. Dans la barre latérale gauche, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Sélectionnez **Paramètres** > **Généralités**.
1. Développez **GitLab Duo**.
1. Activez le bouton **Turn on AI-powered resolution of dependency bump breaking changes**.
1. Sélectionnez **Enregistrer les modifications**.

## Déclencher le flow {#trigger-the-flow}

Vous pouvez déclencher le flow automatiquement ou manuellement.

### Déclenchement automatique {#automatic-trigger}

Le flow s'exécute automatiquement lorsque :

- Un pipeline échoue sur une merge request de mise à niveau des dépendances créée par l'agent de remédiation automatique.
- La fonctionnalité est activée pour le projet.
- Les fonctionnalités GitLab Duo sont activées pour le projet ou le groupe.

L'analyse s'exécute en arrière-plan. Une fois terminée, les correctifs générés sont commités dans la branche de la merge request et le pipeline est relancé.

### Déclenchement manuel {#manual-trigger}

Pour déclencher manuellement la résolution agentique des modifications incompatibles sur une merge request (qui met à niveau des dépendances) avec un pipeline en échec :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Requêtes de fusion**.
1. Sélectionnez la merge request de mise à niveau des dépendances avec un pipeline en échec.
1. Dans le widget de pipeline, sélectionnez **Résoudre les modifications incompatibles avec Duo**.

Le flow s'exécute en arrière-plan. Une fois terminé, il commite les correctifs générés dans la branche de la MR et relance le pipeline.

## Donnez votre avis {#provide-feedback}

Partagez vos commentaires dans le [ticket de retour d'expérience](https://gitlab.com/gitlab-org/gitlab/-/work_items/605189).

## Sujets connexes {#related-topics}

- [Flow par défaut de résolution agentique des modifications incompatibles](../../duo_agent_platform/flows/foundational_flows/agentic-breaking-change-resolution.md)
- [Remédiation automatique de l'analyse des dépendances](../remediate/auto_remediation.md)
- [Analyse des dépendances](_index.md)
- [GitLab Duo Agent Platform](../../duo_agent_platform/_index.md)
- [GitLab Duo](../../gitlab_duo/_index.md)
