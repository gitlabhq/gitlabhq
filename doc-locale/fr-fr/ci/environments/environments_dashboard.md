---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Surveillez les environnements de plusieurs projets, notamment les derniers commits, le statut des pipelines et les temps de déploiement."
title: Tableau de bord des environnements
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Le tableau de bord Environnements offre une vue multi-projets basée sur les environnements, vous permettant de voir l'ensemble de ce qui se passe dans chaque environnement. Depuis un emplacement unique, vous pouvez suivre la progression des changements qui transitent du développement à la phase de staging, puis vers la production (ou via toute série de flows d'environnements personnalisés que vous pouvez configurer). Grâce à une vue synthétique de plusieurs projets, vous pouvez voir instantanément quels pipelines sont au vert et lesquels sont au rouge, ce qui vous permet de diagnostiquer s'il y a un blocage à un point particulier ou s'il s'agit d'un problème plus systémique à investiguer.

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à**.
1. Sélectionnez **Votre travail**.
1. Sélectionnez **Environnements**.

![Tableau de bord Environnements affichant deux rangées de projets avec leurs environnements de déploiement et le statut des pipelines.](img/environments_dashboard_v18_8.png)

Le tableau de bord Environnements affiche une liste paginée de projets incluant jusqu'à trois environnements par projet.

Chaque projet affiche ses environnements configurés. Les environnements éphémères et les autres environnements regroupés ne sont pas affichés.

## Ajouter un projet au tableau de bord {#adding-a-project-to-the-dashboard}

Pour ajouter un projet au tableau de bord :

1. Sélectionnez **Ajouter des projets** sur l'écran d'accueil du tableau de bord.
1. Recherchez et ajoutez un ou plusieurs projets à l'aide du champ **Rechercher dans vos projets**.
1. Sélectionnez **Ajouter des projets**.

Une fois ajoutés, vous pouvez consulter un résumé de l'état opérationnel de l'environnement de chaque projet, notamment le dernier commit, le statut du pipeline et le temps de déploiement.

Les tableaux de bord Environnements et [Opérations](../../user/operations_dashboard/_index.md) partagent la même liste de projets. Lorsque vous ajoutez ou supprimez un projet de l'un, GitLab l'ajoute ou le supprime de l'autre.

Vous pouvez ajouter jusqu'à 150 projets que GitLab affichera sur ce tableau de bord.

## Tableaux de bord d'environnements sur GitLab.com {#environment-dashboards-on-gitlabcom}

Les utilisateurs de GitLab.com peuvent ajouter des projets publics au tableau de bord Environnements gratuitement. Si votre projet est privé, le groupe auquel il appartient doit disposer d'un abonnement [GitLab Premium](https://about.gitlab.com/pricing/).
