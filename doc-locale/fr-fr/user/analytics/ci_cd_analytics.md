---
stage: Verify
group: CI Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Données d'analyse CI/CD"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez les données d'analyse CI/CD pour obtenir des informations sur les performances de vos pipelines et leurs taux de réussite.

La page des données d'analyse CI/CD fournit des visualisations pour les métriques critiques des pipelines CI/CD directement dans l'interface utilisateur de GitLab. Ces visualisations peuvent aider les équipes de développement à comprendre rapidement l'état et l'efficacité de leur processus de développement logiciel.

## Afficher les données d'analyse CI/CD {#view-cicd-analytics}

{{< history >}}

- [Mise à jour](https://gitlab.com/gitlab-org/gitlab/-/issues/353607) dans GitLab 18.0 pour améliorer les données d'analyse en utilisant ClickHouse comme source de données lorsque disponible.

{{< /history >}}

Pour afficher les données d'analyse CI/CD :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Analyse** > **Données d'analyse CI/CD**.

## Métriques des pipelines {#pipeline-metrics}

Vous pouvez afficher l'historique des succès et des échecs de vos pipelines, ainsi que la durée d'exécution de chaque pipeline. Les statistiques des pipelines sont collectées en regroupant tous les pipelines disponibles pour le projet, quel que soit leur statut. Les données disponibles pour chaque jour individuel sont basées sur le moment où le pipeline a démarré.

Les données d'analyse CI/CD affichent les métriques clés de vos pipelines :

- **Nombre total de cycles de pipelines** : le nombre total de pipelines ayant été exécutés au cours de la période sélectionnée. Le calcul du nombre total de pipelines inclut les pipelines enfants et les pipelines ayant échoué en raison d'un fichier YAML invalide. Pour filtrer les pipelines selon d'autres attributs, utilisez l'[API Pipelines](../../api/pipelines.md#list-project-pipelines).
- **Durée médiane** : la durée médiane nécessaire aux pipelines pour s'exécuter.
- **Taux d’échec** : le pourcentage de pipelines ayant échoué.
- **Taux de réussite** : le pourcentage de pipelines s'étant terminés avec succès.
- **Other rate** : le pourcentage de pipelines ayant été ignorés ou annulés.

## Filtrer vos résultats {#filter-your-results}

Vous pouvez filtrer les données d'analyse pour vous concentrer sur des domaines spécifiques :

- **Source** : filtrer par source de déclenchement du pipeline.
- **Branche** : filtrer par la branche sur laquelle le pipeline s'est exécuté.
- **Plage de dates** : sélectionnez la période à analyser (par exemple, la semaine dernière).

Le filtrage vous permet d'analyser les performances de composants spécifiques du workflow ou de comparer différentes branches.

## Graphique de durée des pipelines {#pipeline-duration-chart}

Le graphique de durée montre comment les temps d'exécution de vos pipelines ont évolué au fil du temps. Le graphique affiche :

- **Médiane (50e percentile)** : la durée typique d'un pipeline.
- **95e percentile** : 95 % des pipelines se terminent dans ce délai ou moins, tandis que seulement 5 % prennent plus de temps.

Cette visualisation vous aide à identifier les tendances en matière de durée des pipelines, ce qui peut vous aider à déterminer l'efficacité de votre processus CI/CD au fil du temps.

## Graphique de statut des pipelines {#pipeline-status-chart}

Le graphique de statut montre la distribution des statuts des pipelines au fil du temps :

- **Réussite** : pipelines s'étant terminés sans erreur
- **Échec** : pipelines ne s'étant pas terminés avec succès en raison d'erreurs
- **Autre** : pipelines avec d'autres statuts (annulés, ignorés)

Cette visualisation vous aide à suivre la stabilité de vos pipelines et à identifier les périodes présentant des taux d'échec plus élevés.

## Métriques de performance des jobs CI/CD {#cicd-job-performance-metrics}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com
- Statut : disponibilité limitée

{{< /details >}}

{{< history >}}

- [Introduites](https://gitlab.com/groups/gitlab-org/-/work_items/18548) dans GitLab 18.9 en disponibilité limitée.

{{< /history >}}

> [!note]
> Non disponible par défaut sur GitLab Self-Managed ou GitLab Dedicated. Pour afficher les métriques de performance des jobs CI/CD sur les instances GitLab Self-Managed et GitLab Dedicated, vous devez configurer [ClickHouse](../../integration/clickhouse.md).

Les tendances de performance des jobs CI/CD permettent aux développeurs d'identifier rapidement les jobs CI/CD inefficaces ou problématiques. En intégrant ces fonctionnalités directement dans l'interface utilisateur de GitLab, les développeurs disposent du contexte nécessaire pour localiser et corriger les problèmes de performance CI/CD.

Les métriques de performance des jobs vous permettent d'identifier les goulots d'étranglement, de surveiller la fiabilité des jobs et de concentrer les efforts d'optimisation sur les jobs ayant le plus grand impact sur la durée globale du pipeline.

La section des performances des jobs affiche les métriques pour chaque job de vos pipelines pour la période sélectionnée :

- **Nom du job** : nom du job CI/CD.
- **P50 duration** (médiane) : temps d'exécution typique pour ce job. La moitié des exécutions de jobs se termine plus rapidement, l'autre moitié prend plus de temps.
- **Durée P95** : 95 % des exécutions de jobs se terminent dans ce délai. Utilisez cette métrique pour identifier les valeurs aberrantes et les scénarios les plus défavorables.
- **Taux d’échec** : pourcentage d'exécutions de jobs ayant échoué. Des taux élevés indiquent des problèmes de fiabilité et nécessitent une investigation.

Par défaut, le tableau est trié par durée moyenne (les jobs les plus longs en premier). Le tableau affiche 10 jobs par page avec des contrôles de pagination. Vous pouvez sélectionner n'importe quel en-tête de colonne pour trier selon cette métrique, ou utiliser la barre de recherche pour trouver des jobs spécifiques par nom.
