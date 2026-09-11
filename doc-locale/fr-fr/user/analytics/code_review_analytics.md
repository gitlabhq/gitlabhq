---
stage: Analytics
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Découvrez combien de temps vos merge requests ouvertes ont passé en revue de code, et ce qui distingue celles qui durent le plus longtemps."
title: "Données d'analyse de revue de code"
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Déplacé vers GitLab Premium dans la version 13.9.

{{< /history >}}

Les données d'analyse de revue de code affichent un tableau des merge requests ouvertes ayant au moins un commentaire d'un non-auteur. Le temps de revue correspond à la durée écoulée depuis le premier commentaire d'un non-auteur dans une merge request.

Vous pouvez utiliser les données d'analyse de revue de code pour consulter les métriques de revue par merge request et améliorer votre processus de revue de code.

- Un nombre élevé de commentaires ou de commits peut indiquer :
  - Un code trop complexe
  - Des auteurs qui nécessitent une formation supplémentaire
- Un temps de revue long peut indiquer :
  - Des types de travaux qui progressent plus lentement que d'autres
  - Des opportunités d'accélérer votre cycle de développement
- Un faible nombre de commentaires et d'approbateurs peut indiquer un manque de membres disponibles dans l'équipe.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une explication en vidéo, consultez [Données d'analyse de revue de code : revue de code plus rapide](https://www.youtube.com/watch?v=849o0XD991M).

## Afficher les données d'analyse de revue de code {#view-code-review-analytics}

Prérequis :

- Vous devez disposer du rôle Reporter, Developer, Maintainer ou Owner.

Pour afficher les données d'analyse de revue de code :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à** et repérez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Analyse** > **Données d'analyse de revue de code**.
1. Facultatif. Filtrer les résultats :
   1. Sélectionnez la barre de filtre.
   1. Sélectionnez un paramètre. Vous pouvez filtrer les merge requests par jalon et par label.
   1. Sélectionnez une valeur pour le paramètre sélectionné.

Le tableau affiche jusqu'à 20 merge requests en revue par page et inclut les informations suivantes sur chaque merge request :

- Titre de la merge request
- Temps de revue
- Auteur
- Approbateurs
- Commentaires
- Commits
- Modifications de lignes
