---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "L'analyse des merge requests vous aide à comprendre l'efficacité de votre processus de revue de code et la productivité de votre équipe."
title: Analyse des requêtes de fusion
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

L'analyse des merge requests fournit aux responsables DevOps des informations précieuses sur les workflows de revue de code et de fusion de leur équipe. En se basant sur les métriques détaillées et les tendances liées aux merge requests, les organisations peuvent surveiller et optimiser leurs processus de développement.

Utilisez l'analyse des merge requests pour afficher :

- Le nombre de merge requests fusionnées par votre organisation par mois
- Le temps moyen entre la création d'une merge request et l'événement de fusion
- Des informations sur chaque merge request fusionnée (telles que le jalon, les commits, les modifications de lignes et les personnes assignées)

Vous pouvez utiliser l'analyse des merge requests pour identifier :

- Les mois de faible ou de forte productivité
- L'efficacité et la productivité de vos processus de merge request et de revue de code

Ces informations peuvent vous aider à prendre des décisions basées sur les données, telles que :

- Allocation des ressources : résoudre les périodes de faible productivité en réallouant les ressources ou en ajustant les délais.
- Analyse comparative des performances : mettre en avant les équipes les plus performantes et partager les meilleures pratiques.
- Planification des jalons : ajuster les délais en fonction des tendances historiques de fusion.
- Optimisation des processus : identifier et résoudre les goulets d'étranglement dans les workflows de revue de code et de fusion.

## Afficher l'analyse des merge requests {#view-merge-request-analytics}

Prérequis :

- Vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner.

Pour afficher l'analyse des merge requests :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Analyse** > **Tableaux de bord de données d'analyse**.
1. Sélectionnez **Analyse des requêtes de fusion**.

![Graphique d'analyse des merge requests](img/mr_analytics_chart_v17_7.png)

## Afficher le nombre de merge requests dans une plage de dates {#view-the-number-of-merge-requests-in-a-date-range}

Pour afficher le nombre de merge requests fusionnées au cours d'une plage de dates spécifique :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Analyse** > **Tableaux de bord de données d'analyse**.
1. Sélectionnez **Analyse des requêtes de fusion**.
1. Facultatif. Filtrer les résultats :
   1. Sélectionnez la barre de filtre.
   1. Sélectionnez un paramètre.
   1. Sélectionnez une valeur ou saisissez du texte pour affiner les résultats.
   1. Pour ajuster la plage de dates, sélectionnez une option dans la liste déroulante. La valeur par défaut est **Derniers 365 jours**.

Le graphique **Débit** affiche les tickets fermés ou les merge requests fusionnées (non fermées) sur une période donnée.

Le tableau affiche jusqu'à 20 merge requests par page et inclut les informations suivantes sur chaque merge request :

- Nom de la merge request
- Date de fusion
- Délai de fusion
- Jalon
- Commits
- Pipelines
- Modifications de lignes
- Personnes assignées

## Afficher le temps moyen entre la création d'une merge request et la fusion {#view-average-time-between-merge-request-creation-and-merge}

Le nombre affiché dans **Temps moyen jusqu'à la fusion** indique le temps moyen entre la création d'une merge request et sa fusion. Les merge requests fermées et non encore fusionnées ne sont pas incluses.

Pour afficher le **Temps moyen jusqu'à la fusion** :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Analyse** > **Tableaux de bord de données d'analyse**.
1. Sélectionnez **Analyse des requêtes de fusion**. Le nombre **Temps moyen jusqu'à la fusion** s'affiche sur le tableau de bord.
