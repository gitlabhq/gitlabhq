---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurez les paramètres de facteur de coût pour les minutes de calcul sur GitLab.com.
title: Administration des minutes de calcul pour GitLab.com
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab.com

{{< /details >}}

Les administrateurs de GitLab.com disposent de contrôles supplémentaires sur les minutes de calcul, au-delà de ce qui est disponible pour [GitLab Self-Managed](compute_minutes.md).

## Définir les facteurs de coût {#set-cost-factors}

Prérequis :

- Vous devez être administrateur de GitLab.com.

Pour définir les facteurs de coût pour un runner :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Runners**.
1. Pour le runner que vous souhaitez mettre à jour, sélectionnez **Éditer** ({{< icon name="pencil" >}}).
1. Dans la zone de texte **Facteur de coût de calcul des projets publics**, saisissez le facteur de coût public.
1. Dans la zone de texte **Facteur de coût de calcul des projets privés**, saisissez le facteur de coût privé.
1. Sélectionnez **Sauvegarder les modifications**.

## Réduire les facteurs de coût pour les contributions communautaires {#reduce-cost-factors-for-community-contributions}

Lorsque le feature flag `ci_minimal_cost_factor_for_gitlab_namespaces` est activé pour un espace de nommage, les pipelines de merge request provenant de duplications qui ciblent des projets dans l'espace de nommage activé utilisent un facteur de coût réduit. Cela garantit que les contributions communautaires ne consomment pas un nombre excessif de minutes de calcul.

Prérequis :

- Vous devez être en mesure de contrôler les feature flags.
- Vous devez disposer de l'ID d'espace de nommage pour lequel vous souhaitez activer les facteurs de coût réduits.

Pour permettre à un espace de nommage d'utiliser un facteur de coût réduit :

1. [Activez le feature flag](../feature_flags/_index.md#how-to-enable-and-disable-features-behind-flags) `ci_minimal_cost_factor_for_gitlab_namespaces` pour l'ID d'espace de nommage que vous souhaitez inclure.

Cette fonctionnalité est recommandée pour une utilisation sur GitLab.com uniquement. Les contributeurs de la communauté doivent utiliser des duplications communautaires pour leurs contributions afin d'éviter d'accumuler des minutes lors de l'exécution de pipelines qui ne font pas partie d'une merge request ciblant un projet GitLab.
