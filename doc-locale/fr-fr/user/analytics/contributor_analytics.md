---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Analyse des contributeurs
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

L'analyse des contributeurs vous donne une vue d'ensemble des commits effectués par les membres d'un projet au fil du temps.

## Afficher l'analyse des contributeurs {#view-contributor-analytics}

La page d'analyse des contributeurs affiche un graphique linéaire indiquant le nombre de commits effectués sur la branche du projet sélectionné au fil du temps, ainsi que des graphiques linéaires indiquant le nombre de commits par membre du projet.

Pour afficher l'analyse des contributeurs d'un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Analyse** > **Analyse des contributeurs**.
1. Dans la liste déroulante **Branches** (**main**), sélectionnez la branche pour laquelle vous souhaitez afficher les commits.
1. Pour afficher le nombre de commits effectués un jour précis, survolez le graphique linéaire.
1. Facultatif. Pour afficher les commits uniquement sur une période spécifique, sélectionnez les icônes de pause ({{< icon name="status-paused" >}}) et faites-les glisser le long de l'axe horizontal :

   - Pour modifier la date de début, faites glisser l'icône de pause de gauche vers la gauche ou vers la droite.
   - Pour modifier la date de fin, faites glisser l'icône de pause de droite vers la gauche ou vers la droite.

## Afficher l'historique des commits du projet {#view-project-commit-history}

Pour afficher la liste des commits effectués par les membres du projet par jour :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Analyse** > **Analyse des contributeurs**.
1. Sélectionnez **Historique**.
1. Dans la liste déroulante **Branches** (**main**), sélectionnez la branche pour laquelle vous souhaitez afficher les commits.
1. Pour afficher le nombre de commits effectués par les membres un jour précis, survolez le graphique linéaire.
1. Facultatif. Filtrez les résultats.

   - Pour filtrer par auteur, dans la liste déroulante **Auteur**, sélectionnez l'utilisateur dont vous souhaitez afficher les commits.
   - Pour filtrer par message de commit, saisissez vos critères de recherche dans la zone de texte.

## Récupérer les commits du projet en tant que flux RSS {#retrieve-project-commits-as-an-rss-feed}

Pour afficher la liste des commits du projet sous forme de flux RSS au format Atom :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Analyse** > **Analyse des contributeurs**.
1. Sélectionnez **Historique**.
1. Dans le coin supérieur droit, sélectionnez le symbole de flux ({{< icon name="rss" >}}).
