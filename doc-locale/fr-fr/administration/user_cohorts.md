---
stage: Facilitated functionality
group: Facilitated functionality
info: For more information, see <https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality>
description: "Analysez la rétention des utilisateurs et les tendances d'activité au fil du temps."
gitlab_dedicated: yes
title: "Cohortes d'utilisateurs"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Vous pouvez analyser les activités GitLab de vos utilisateurs au fil du temps.

Comment interpréter le tableau des cohortes d'utilisateurs ? Passons en revue un exemple avec les cohortes d'utilisateurs suivantes :

![Tableau de cohortes d'utilisateurs affichant les métriques de rétention et d'inactivité, avec mise en évidence de mars et avril 2020.](img/cohorts_v13_9.png)

Pour la cohorte de mars 2020, trois utilisateurs ont été ajoutés à ce serveur et sont actifs depuis ce mois. Un mois plus tard (avril 2020), deux utilisateurs sont encore actifs. Cinq mois plus tard (août 2020), un utilisateur de cette cohorte est encore actif, soit 33 % de la cohorte initiale de trois personnes ayant rejoint le service en mars.

La colonne **Utilisateurs inactifs** indique le nombre d'utilisateurs ajoutés au cours du mois, mais n'ayant jamais eu aucune activité dans l'instance.

Comment mesurons-nous l'activité des utilisateurs ? GitLab considère qu'un utilisateur est actif si :

- L'utilisateur se connecte.
- L'utilisateur a une activité Git (qu'il s'agisse d'un push ou d'un pull).
- L'utilisateur visite des pages liées aux tableaux de bord, aux projets, aux tickets ou aux merge requests.
- L'utilisateur utilise l'API.
- L'utilisateur utilise l'API GraphQL.

## Afficher les cohortes d'utilisateurs {#view-user-cohorts}

Prérequis :

- Accès administrateur.

Pour afficher les cohortes d'utilisateurs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Sélectionnez l'onglet **Cohortes**.
