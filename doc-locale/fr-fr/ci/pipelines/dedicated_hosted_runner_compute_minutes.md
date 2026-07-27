---
stage: Production Engineering
group: Runners Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Minutes de calcul, suivi d'utilisation, gestion des quotas pour les runners hébergés par GitLab sur GitLab Dedicated."
title: Utilisation du calcul pour les runners hébergés par GitLab sur GitLab Dedicated
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Dedicated

{{< /details >}}

Une instance GitLab Dedicated peut avoir à la fois des runners d'instance GitLab Self-Managed et des runners d'instance hébergés par GitLab.

En tant qu'administrateur d'une instance GitLab Dedicated, vous pouvez suivre et surveiller les minutes de calcul utilisées par les espaces de nommage exécutant des jobs sur l'un ou l'autre type de runners d'instance.

Pour les runners hébergés par GitLab :

- Vous pouvez consulter votre utilisation estimée dans le [tableau de bord d'utilisation des runners hébergés par GitLab](#view-compute-usage).
- L'application des quotas et les notifications ne sont pas disponibles.

Pour les runners d'instance GitLab Self-Managed enregistrés auprès de votre instance GitLab Dedicated, consultez [afficher l'utilisation des runners d'instance](instance_runner_compute_minutes.md#view-usage).

## Afficher l'utilisation du calcul {#view-compute-usage}

{{< history >}}

- Les données d'utilisation du calcul pour les runners hébergés par GitLab ont été [introduites](https://gitlab.com/groups/gitlab-com/gl-infra/gitlab-dedicated/-/epics/524) dans GitLab 18.0.

{{< /history >}}

Prérequis :

- Vous devez être administrateur d'une instance GitLab Dedicated.

Vous pouvez consulter l'utilisation du calcul :

- L'utilisation totale du calcul pour le mois en cours.
- Par mois, avec la possibilité de filtrer par année et par runner.
- Par espace de nommage, avec la possibilité de filtrer par mois et par runner.

Pour afficher l'utilisation du calcul des runners hébergés par GitLab pour tous les espaces de nommage de l'ensemble de votre instance GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Quotas d'utilisation**.
