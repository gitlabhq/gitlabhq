---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurer les grands modèles de langage pour les fonctionnalités GitLab Duo.
title: Sélection de modèle
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Module complémentaire : GitLab Duo Core, Pro ou Enterprise
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Chaque fonctionnalité GitLab Duo dispose d'un grand modèle de langage (LLM) par défaut choisi par GitLab.

GitLab peut mettre à jour ce modèle par défaut pour optimiser les performances des fonctionnalités. Par conséquent, le modèle d'une fonctionnalité peut changer sans que vous ayez à effectuer la moindre action.

Si vous ne souhaitez pas utiliser le modèle par défaut pour chaque fonctionnalité, ou si vous avez des exigences spécifiques, vous pouvez choisir parmi un ensemble d'autres modèles pris en charge disponibles.

Si vous sélectionnez un modèle spécifique pour une fonctionnalité, celle-ci utilise ce modèle jusqu'à ce que vous en sélectionniez un autre.

## Sélectionner un modèle pour l'instance {#select-a-model-for-the-instance}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/19144) dans GitLab 18.4 avec un [feature flag](../feature_flags/_index.md) nommé `instance_level_model_selection`. Activé par défaut.
- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/208017) dans GitLab Dedicated dans GitLab 18.5.
- Le feature flag `instance_level_model_selection` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/209698) dans GitLab 18.6.
- [Modifié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/210969) pour inclure GitLab Duo Core et Pro dans GitLab 18.6.

{{< /history >}}

Vous pouvez sélectionner un modèle pour une fonctionnalité qui s'applique à l'ensemble de l'instance. Si vous ne sélectionnez pas de modèle spécifique, toutes les fonctionnalités GitLab Duo utilisent le modèle GitLab par défaut.

> [!note]
> Pour les instances GitLab Self-Managed disposant d'une licence hors ligne, pour changer le modèle des fonctionnalités de la plateforme GitLab Duo Agent, vous devez disposer de l'extension [GitLab Duo Agent Platform Self-Hosted](../../subscriptions/subscription-add-ons.md).

Prérequis :

- Vous devez être administrateur.

Pour sélectionner un modèle pour une fonctionnalité :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sur **Configure AI features**, sélectionnez **Configurer les modèles pour GitLab Duo**. Si **Configure AI features** ne s'affiche pas, vérifiez que l'extension GitLab Duo Enterprise est configurée pour votre instance.
1. Pour la fonctionnalité que vous souhaitez configurer, sélectionnez un modèle dans la liste déroulante.
1. Facultatif. Pour appliquer le modèle à toutes les fonctionnalités de la section, sélectionnez **Appliquer à tous**.
