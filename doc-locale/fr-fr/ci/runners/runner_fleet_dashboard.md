---
stage: Verify
group: CI Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tableau de bord de la flotte de runners pour les administrateurs
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/424495) dans GitLab 16.6

{{< /history >}}

En tant qu'administrateur GitLab, vous pouvez utiliser le tableau de bord de la flotte de runners pour évaluer l'état de santé de vos runners d'instance. Le tableau de bord de la flotte de runners affiche :

- Erreurs CI récentes causées par l'infrastructure des runners
- Nombre de jobs simultanés exécutés sur les runners les plus sollicités
- Minutes de calcul utilisées par les runners d'instance
- Temps d'attente dans la file de jobs

![Tableau de bord de la flotte de runners affichant le statut, l'utilisation et les métriques de performance.](img/runner_fleet_dashboard_v17_1.png)

## Métriques du tableau de bord {#dashboard-metrics}

{{< history >}}

- [Introduction](https://gitlab.com/groups/gitlab-org/-/epics/11180) des métriques **Runner usage** et **Wait time to pick up job**, en tant que [version expérimentale](../../policy/development_stages_support.md#experiment) dans GitLab 16.7 avec les [flags](../../administration/feature_flags/_index.md) nommés `ci_data_ingestion_to_click_house` et `clickhouse_ci_analytics`. Désactivé par défaut.
- Les métriques **Runner usage** et **Wait time to pick up job** sont [passées](https://gitlab.com/gitlab-org/gitlab/-/issues/424789) en [version bêta](../../policy/development_stages_support.md#beta) dans GitLab 17.1.

{{< /history >}}

Les métriques suivantes sont disponibles dans le tableau de bord de la flotte de runners :

> [!note]
> Pour afficher les métriques **Runner usage** et **Temps d'attente pour récupérer un job**, vous devez configurer l'[intégration ClickHouse](../../integration/clickhouse.md).
>
> <i class="fa-youtube-play" aria-hidden="true"></i> Pour une présentation générale, consultez [configurer le tableau de bord de la flotte de runners avec ClickHouse](https://www.youtube.com/watch?v=YpGV95Ctbpk).
> <!-- Video published on 2023-12-19 -->

| Métrique                        | Description |
|-------------------------------|-------------|
| En ligne                        | Nombre de runners en ligne pour l'ensemble de l'instance. |
| Hors ligne                       | Nombre de runners actuellement hors ligne. Les runners qui ont été enregistrés mais qui ne se sont jamais connectés à GitLab ne sont pas inclus dans ce décompte. |
| Runners actifs                | Le nombre total de runners actuellement actifs. |
| Utilisation des runners (mois précédent)<sup>1</sup> | **Requires ClickHouse** : Le total des minutes de calcul utilisées par chaque runner de projet ou de runner de groupe au cours du mois précédent. Vous pouvez exporter ces données sous forme de fichier CSV à des fins d'analyse des coûts. |
| Temps d'attente pour récupérer un job<sup>1</sup>       | **Requires ClickHouse** : Le temps moyen qu'un job attend dans la file d'attente avant qu'un runner ne le prenne en charge. Cette métrique fournit des informations sur la capacité de vos runners à traiter la file d'attente des jobs CI/CD selon les objectifs de niveau de service (SLO) cibles de votre organisation. Ces données sont mises à jour toutes les 24 heures. |

**Remarques** :

1. Cette fonctionnalité est en [version bêta](../../policy/development_stages_support.md#beta) et susceptible d'être modifiée sans préavis. Pour plus d'informations, consultez l'[epic 11180](https://gitlab.com/groups/gitlab-org/-/epics/11180).

## Afficher le tableau de bord de la flotte de runners {#view-the-runner-fleet-dashboard}

Prérequis :

- Vous devez être un administrateur.
- Pour afficher les métriques **Runner usage** et **Temps d'attente pour récupérer un job**, vous devez configurer l'[intégration ClickHouse](../../integration/clickhouse.md).

Pour afficher le tableau de bord de la flotte de runners :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Runners**.
1. Sélectionnez **Tableau de bord de la flotte**.

## Exporter les minutes de calcul utilisées par les runners d'instance {#export-compute-minutes-used-by-instance-runners}

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.
- Vous devez configurer l'[intégration ClickHouse](../../integration/clickhouse.md).

Pour analyser l'utilisation des runners, vous pouvez exporter un fichier CSV contenant le nombre de jobs et les minutes de runner exécutées. Le fichier CSV indique le type de runner et le statut du job pour chaque projet. Le fichier CSV est envoyé à votre adresse e-mail lorsque l'export est terminé.

Pour exporter les minutes de calcul utilisées par les runners d'instance :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Runners**.
1. Sélectionnez **Tableau de bord de la flotte**.
1. Sélectionnez **Export CSV**.

## Commentaires {#feedback}

Pour nous aider à améliorer le tableau de bord de la flotte de runners, vous pouvez soumettre vos commentaires dans le [ticket 421737](https://gitlab.com/gitlab-org/gitlab/-/issues/421737). En particulier :

- La facilité ou la difficulté de la configuration de GitLab pour faire fonctionner le tableau de bord.
- L'utilité que vous avez trouvée au tableau de bord.
- Quelles autres informations vous aimeriez voir dans ce tableau de bord.
- Toute autre réflexion ou idée connexe.
