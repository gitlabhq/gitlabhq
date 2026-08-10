---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tableau de bord des opérations
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Le tableau de bord des opérations fournit un résumé de l'état opérationnel de chaque projet, y compris le pipeline et le statut des alertes.

Pour accéder au tableau de bord :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à**.
1. Sélectionnez **Votre travail**.
1. Sélectionnez **Opérations**.

## Ajouter un projet au tableau de bord {#adding-a-project-to-the-dashboard}

Pour ajouter un projet au tableau de bord :

1. Assurez-vous que vos alertes renseignent le label `gitlab_environment_name` dans les [alertes que vous avez configurées dans Prometheus](../../operations/incident_management/integrations.md#expected-prometheus-request-attributes). La valeur de ce label doit correspondre au nom de votre environnement dans GitLab. Vous pouvez uniquement afficher les alertes pour l'environnement `production`.
1. Sélectionnez **Ajouter des projets** sur l'écran d'accueil du tableau de bord.
1. Recherchez et ajoutez un ou plusieurs projets à l'aide du champ **Rechercher dans vos projets**.
1. Sélectionnez **Ajouter des projets**.

Une fois ajouté, le tableau de bord affiche le nombre d'alertes actives du projet, le dernier commit, le statut du pipeline et la date du dernier déploiement.

Les tableaux de bord des opérations et des [environnements](../../ci/environments/environments_dashboard.md) partagent la même liste de projets. L'ajout ou la suppression d'un projet de l'un entraîne l'ajout ou la suppression du projet de l'autre.

![Tableau de bord des opérations avec des projets](img/index_operations_dashboard_with_projects_v11_10.png)

## Organiser les projets sur un tableau de bord {#arranging-projects-on-a-dashboard}

Vous pouvez faire glisser les cartes de projet pour modifier leur ordre. L'ordre des cartes est actuellement uniquement enregistré dans votre navigateur et ne modifie donc pas le tableau de bord pour les autres utilisateurs.

## Définir ce tableau de bord comme tableau de bord par défaut lors de la connexion {#making-it-the-default-dashboard-when-you-sign-in}

Le tableau de bord des opérations peut également être défini comme tableau de bord GitLab par défaut affiché lors de votre connexion. Pour en faire le tableau de bord par défaut, consultez [Préférences du profil](../profile/preferences.md).
