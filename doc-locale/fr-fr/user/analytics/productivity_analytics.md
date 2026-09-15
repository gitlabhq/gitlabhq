---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Analysez la vélocité de développement d'un groupe et consultez des graphiques pour l'analyse des merge requests."
title: "Données d'analyse de productivité"
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les données d'analyse de productivité affichent des informations sur les merge requests pour les groupes.

Utilisez les données d'analyse de productivité pour identifier :

- Votre vélocité de développement en fonction du temps nécessaire à la fusion d'une merge request.
- Les causes potentielles des merge requests qui prennent beaucoup de temps à fusionner.
- Les auteurs, labels, ou jalons qui prennent le plus de temps à fusionner ou qui contiennent le plus de modifications.

Pour consulter les données de merge request pour les projets, utilisez [l'analyse des merge requests](merge_request_analytics.md).

## Graphiques {#charts}

Les données d'analyse de productivité affichent les graphiques suivants :

- Des graphiques à barres qui illustrent :
  - Le nombre de merge requests par nombre de jours avant fusion
  - Le délai entre les commits, les commentaires et les dates de fusion
  - Le nombre de commits, de lignes de code et de fichiers modifiés
- Un nuage de points qui illustre le nombre de métriques de merge request (comme le nombre de commits par merge request) par jour (date de fusion).
- Un tableau listant les titres des merge requests, le délai avant fusion, et la durée entre les commits, les commentaires et les dates de fusion.

![Graphique des données d'analyse de productivité des merge requests dans le temps](img/productivity_analytics_mrs_v17_9.png)

## Consulter les données d'analyse de productivité {#view-productivity-analytics}

Prérequis :

- Vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner pour le groupe.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Analyse** > **Données d'analyse de productivité**.
1. Facultatif. Filtrer les résultats :

- Pour consulter les données d'analyse d'un projet spécifique, dans la liste déroulante **Projets**, sélectionnez un projet.
- Pour filtrer les résultats par auteur, jalon ou label, sélectionnez **Filtrer les résultats** et saisissez une valeur.
- Pour ajuster la plage de dates :
  - Dans le champ **Du**, sélectionnez une date de début.
  - Dans le champ **Au**, sélectionnez une date de fin.
