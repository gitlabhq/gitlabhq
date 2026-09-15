---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Données d'analyse du dépôt pour les projets"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les données d'analyse du dépôt font partie de [GitLab Community Edition](https://gitlab.com/gitlab-org/gitlab-foss) et sont disponibles pour les utilisateurs ayant la permission de cloner le dépôt.

Utilisez les données d'analyse du dépôt pour consulter des informations sur le dépôt Git d'un projet, telles que :

- Les langages de programmation utilisés dans la branche par défaut du dépôt
- Les statistiques de couverture du code pour les trois derniers mois
- Les statistiques de commit pour le dernier mois
- Le nombre de commits par jour du mois, par jour de la semaine et par heure

## Traitement des données des graphiques {#chart-data-processing}

Les données des graphiques sont placées dans une file d'attente. Les workers en arrière-plan mettent à jour les graphiques 10 minutes après chaque commit sur la branche par défaut. Selon la taille de l'installation GitLab et des files d'attente des jobs en arrière-plan, l'actualisation des données peut prendre plus de temps.

## Afficher les données d'analyse du dépôt {#view-repository-analytics}

Prérequis :

- Vous devez disposer d'un dépôt Git initialisé.
- La branche par défaut doit contenir au moins un commit (`main` par défaut), à l'exclusion des commits du [wiki](../project/wiki/_index.md#track-wiki-events) d'un projet, qui ne sont pas inclus dans l'analyse.

Pour afficher les données d'analyse du dépôt pour un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Analyse** > **Données d'analyse du dépôt**.
1. Pour afficher les détails d'une catégorie, survolez une barre du graphique.
1. Pour afficher les statistiques de couverture du code et de commits dans une branche spécifique, sélectionnez une branche dans la liste déroulante à côté de **Commit statistics**.
