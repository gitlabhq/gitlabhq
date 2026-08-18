---
stage: Growth
group: Engagement
info: For assistance with this tutorial, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects>.
title: 'Tutoriel : Utiliser la page d''accueil personnelle'
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/546151) dans GitLab 18.1 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `personal_homepage`. Désactivée par défaut.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/554048) dans GitLab 18.4 pour un sous-ensemble d'utilisateurs.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/groups/gitlab-org/-/epics/17932) dans GitLab 18.5.
- Pages wiki consultées récemment :
  - [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/233014) dans GitLab 19.0 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `recently_viewed_wiki_pages`. Désactivée par défaut.
  - [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/work_items/597889) dans GitLab 19.1. L'indicateur de fonctionnalité `recently_viewed_wiki_pages` a été supprimé.

{{< /history >}}

<!-- vale gitlab_base.FutureTense = NO -->

La page d'accueil personnelle regroupe en un seul endroit toutes les informations qui vous concernent. Vous pouvez rapidement identifier les nouveaux éléments de travail qui nécessitent votre attention, ou reprendre là où vous en étiez.

Suivez ce tutoriel pour apprendre à vous repérer sur la page d'accueil et à en tirer le meilleur parti.

## Avant de commencer {#before-you-begin}

Définissez la [page d'accueil personnelle](../../user/profile/preferences.md#choose-your-homepage) comme page d'accueil par défaut dans vos préférences.

## Accéder à la page d'accueil {#access-the-homepage}

Vous pouvez accéder à votre page d'accueil personnelle depuis n'importe quel endroit dans GitLab :

- Dans la barre latérale gauche, en haut, sélectionnez **Page d'accueil**.
- Dans la barre supérieure, sélectionnez **Rechercher ou aller à**, sélectionnez **Votre travail**, puis sélectionnez **Accueil**.

## Disposition de la page d'accueil {#layout-of-the-homepage}

En haut de la page, sélectionnez votre avatar pour définir votre statut. Si vous avez défini un statut, votre avatar affiche un badge de statut et un emoji, et vous pouvez survoler l'avatar pour voir le texte de votre statut.

Sous votre avatar, consultez le nombre de merge requests et de tickets auxquels vous participez.

La liste **Éléments qui requièrent votre attention** affiche tous les éléments de travail dans GitLab qui nécessitent votre contribution.

Le fil **Suivre les dernières mises à jour** affiche votre activité dans GitLab, ainsi que l'activité des projets et utilisateurs spécifiques qui vous intéressent.

Rendez-vous sur le côté droit de la page d'accueil pour accéder aux liens rapides vers les éléments que vous avez consultés récemment et les projets que vous visitez fréquemment.

## Utiliser la page d'accueil pour commencer votre journée {#use-the-homepage-to-start-your-day}

Voici quelques façons d'utiliser la page d'accueil pour démarrer votre journée de travail :

1. Utilisez le filtre dans la liste **Éléments qui requièrent votre attention** pour afficher les événements les plus importants pour vous. Par exemple, pour voir les merge requests bloquées en raison de pipelines échoués, sélectionnez **Compilations non réussies** dans la liste déroulante de filtres.
1. En haut de la page d'accueil, sélectionnez **Merge requests waiting for your review** pour afficher les merge requests qui nécessitent votre révision et débloquer ainsi d'autres personnes.

Vous pouvez également suivre ce sur quoi vous avez travaillé, par exemple :

1. Dans la section **Suivre les dernières mises à jour**, utilisez le filtre **Votre activité** pour voir vos travaux récents. Sélectionnez les liens pour accéder directement au ticket ou à la merge request, et reprenez là où vous en étiez.
1. Dans le widget **Accès rapide** à droite :
   - Sélectionnez **Consultés récemment** pour voir les tickets, les merge requests, les epics et les pages wiki que vous avez récemment consultés.
   - Sélectionnez **Projets** pour voir les projets que vous visitez fréquemment et les projets suivis.
     - Pour filtrer par type de projet, sélectionnez **Options d'affichage** ({{< icon name="preferences" >}}).
   - Sélectionnez n'importe quel lien pour revenir rapidement aux éléments sur lesquels vous travailliez.

## Rester connecté à l'activité de l'équipe {#stay-connected-with-team-activity}

Si vous collaborez sur un projet, ajoutez-le à vos favoris pour le retrouver plus facilement à l'avenir. Ensuite, utilisez la page d'accueil pour obtenir une vue d'ensemble de ce qui se passe dans ce projet.

Pour ajouter un projet à vos favoris et voir son activité sur la page d'accueil :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans le coin supérieur droit de la page, sélectionnez **Ajouter aux favoris** ({{< icon name="star" >}}).
1. Dans la barre latérale gauche, en haut, sélectionnez **Page d'accueil**.
1. Dans la section **Suivre les dernières mises à jour**, sélectionnez **Projets suivis** dans la liste déroulante.

Pour collaborer plus efficacement avec votre équipe, vous pouvez suivre d'autres utilisateurs GitLab et voir sur quoi ils travaillent :

1. Accédez au profil de l'utilisateur dans GitLab, par exemple `https://gitlab.example.com/username`, et sélectionnez **Suivre**. Vous pouvez également sélectionner **Suivre** dans la petite fenêtre contextuelle qui apparaît lorsque vous survolez le nom de l'utilisateur dans GitLab.
1. Dans la barre latérale gauche, en haut, sélectionnez **Page d'accueil**.
1. Dans la section **Suivre les dernières mises à jour**, sélectionnez **Utilisateurs suivis** dans la liste déroulante.

## Sujets connexes {#related-topics}

En savoir plus sur les différents éléments de travail que vous pouvez consulter et auxquels vous pouvez accéder depuis la page d'accueil.

- [Liste de tâches](../../user/todos.md)
- [Merge requests](../../user/project/merge_requests/_index.md)
- [Tickets](../../user/project/issues/_index.md)
