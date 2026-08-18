---
stage: Verify
group: CI Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tableau de bord de la flotte de runners pour les groupes
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Statut : Version bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151640) en tant que [version bêta](../../policy/development_stages_support.md#beta) dans GitLab 17.0 [avec un flag](../../administration/feature_flags/_index.md) nommé `runners_dashboard_for_groups`. Désactivé par défaut.
- Le feature flag `runners_dashboard_for_groups` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/459052) dans GitLab 17.2.

{{< /history >}}

Les utilisateurs disposant du rôle Maintainer ou Owner pour un groupe peuvent utiliser le tableau de bord de la flotte de runners pour évaluer l'état de santé des runners de groupe.

![Tableau de bord de la flotte de runners pour les groupes](img/runner_fleet_dashboard_groups_v17_1.png)

## Métriques du tableau de bord {#dashboard-metrics}

Les métriques suivantes sont disponibles dans le tableau de bord de la flotte de runners :

| Métrique                        | Description |
|-------------------------------|-------------|
| En ligne                        | Nombre de runners en ligne. Dans la zone **Admin**, cette métrique affiche le nombre de runners pour l'ensemble de l'instance. Dans un groupe, cette métrique affiche le nombre de runners pour le groupe et ses sous-groupes. |
| Hors ligne                       | Nombre de runners hors ligne. |
| Runners actifs                | Nombre de runners actifs. |
| Utilisation des runners (mois précédent)<sup>1</sup> | Nombre de minutes de calcul utilisées par chaque projet sur les runners de groupe. Inclut la possibilité d'exporter au format CSV pour l'analyse des coûts. |
| Temps d'attente pour récupérer un job<sup>1</sup>       | Affiche le temps d'attente moyen pour les runners. Cette métrique fournit des informations sur la capacité des runners à traiter la file d'attente de jobs CI/CD dans le cadre des objectifs de niveau de service cibles de votre organisation. Les données qui alimentent ce widget de métrique sont mises à jour toutes les 24 heures. |

**Remarques** :

1. Pour GitLab Self-Managed, pour afficher les métriques **Runner usage** et **Temps d'attente pour récupérer un job**, vous devez configurer l'[intégration ClickHouse](../../integration/clickhouse.md).

## Consulter le tableau de bord de la flotte de runners pour les groupes {#view-the-runner-fleet-dashboard-for-groups}

Prérequis :

- Vous devez disposer du rôle Maintainer pour le groupe.
- Pour GitLab Self-Managed, pour afficher les métriques **Runner usage** et **Temps d'attente pour récupérer un job**, configurez l'[intégration ClickHouse](../../integration/clickhouse.md).

Pour consulter le tableau de bord de la flotte de runners pour les groupes :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Version** > **Runners**.
1. Sélectionnez **Tableau de bord de la flotte**.
