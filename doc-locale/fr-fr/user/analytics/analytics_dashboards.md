---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Tableaux de bord de données d'analyse"
description: "Visualisez les métriques relatives aux fonctionnalités DevSecOps et IA pour vos projets et groupes, et suivez les tendances de performance."
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduit dans GitLab 15.9 en tant que fonctionnalité de [version expérimentale](../../policy/development_stages_support.md#experiment) [avec un feature flag](../../administration/feature_flags/_index.md) nommé `combined_analytics_dashboards`. Désactivées par défaut.
- `combined_analytics_dashboards` [activé](https://gitlab.com/gitlab-org/gitlab/-/issues/389067) par défaut dans GitLab 16.11.
- `combined_analytics_dashboards` [supprimé](https://gitlab.com/gitlab-org/gitlab/-/issues/454350) dans GitLab 17.1.
- La configuration `filters` a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/505317) dans GitLab 17.9. Désactivées par défaut.
- La configuration des visualisations intégrées a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/509111) dans GitLab 17.9.
- [Déplacé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/195086) de GitLab Ultimate vers GitLab Premium dans la version 18.2.

{{< /history >}}

Les tableaux de bord de données d'analyse vous aident à visualiser les données collectées dans des tableaux de bord intégrés.

Une expérience de tableau de bord améliorée est proposée dans l'[epic 13801](https://gitlab.com/groups/gitlab-org/-/epics/13801) et l'[epic 19430](https://gitlab.com/groups/gitlab-org/-/work_items/19430).

## Sources de données {#data-sources}

{{< history >}}

- Les sources de données d'analyse produit et de visualisation personnalisée ont été [supprimées](https://gitlab.com/gitlab-org/gitlab/-/issues/497577) dans GitLab 17.7.

{{< /history >}}

Une source de données est une connexion à une base de données ou à un ensemble de données qui peut être utilisée par les filtres et les visualisations de votre tableau de bord pour interroger et récupérer des résultats.

## Tableaux de bord intégrés {#built-in-dashboards}

Pour vous aider à prendre en main les analyses, GitLab fournit des tableaux de bord intégrés avec des visualisations prédéfinies. Ces tableaux de bord portent le label **By GitLab**.

Les tableaux de bord intégrés suivants sont disponibles :

- [**Tableau de bord des chaînes de valeur**](value_streams_dashboard.md) affiche les métriques liées aux performances DevOps, à l'exposition aux risques de sécurité et à l'optimisation des flux de travail.
- [**GitLab Duo and SDLC trends**](duo_and_sdlc_trends.md) affiche l'impact des outils d'IA sur les métriques du cycle de vie du développement logiciel (SDLC) pour un projet ou un groupe.
- [**DORA Metrics Dashboard**](dora_metrics_charts.md) affiche l'évolution de chaque métrique DORA dans le temps.
- [**Analyse des requêtes de fusion**](merge_request_analytics.md) affiche les métriques relatives au débit des merge requests et au délai moyen de fusion.

## Afficher les tableaux de bord du projet {#view-project-dashboards}

Prérequis :

- Vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner pour le projet.

Pour afficher la liste des tableaux de bord d'un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Analyse** > **Tableaux de bord de données d'analyse**.
1. Dans la liste des tableaux de bord disponibles, sélectionnez le tableau de bord que vous souhaitez consulter.

## Afficher les tableaux de bord du groupe {#view-group-dashboards}

Prérequis :

- Vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner pour le groupe.

Pour afficher la liste des tableaux de bord d'un groupe :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Analyse** > **Tableaux de bord de données d'analyse**.
1. Dans la liste des tableaux de bord disponibles, sélectionnez le tableau de bord que vous souhaitez consulter.
