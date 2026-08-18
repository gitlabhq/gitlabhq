---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisateurs Invités
description: Attribuer un accès de base avec des autorisations limitées en tant que rôle utilisateur de niveau débutant.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les utilisateurs disposant du rôle Invité ont un accès et des capacités limités par rapport aux autres rôles utilisateur. Leurs [autorisations](../user/permissions.md) sont restreintes et conçues pour offrir uniquement une visibilité et une interaction de base sans compromettre les données sensibles du projet.

Les utilisateurs disposant du rôle Invité :

- Peuvent accéder aux groupes et projets publics.
- Peuvent consulter les plans de projet, les bloquants et les indicateurs de progression.
- Peuvent créer et lier de nouveaux éléments de travail du projet.
- Peuvent consulter les informations générales du projet, telles que :
  - Analytics
  - Rapports d'incident
  - Tickets et epics
  - Licences
- Ne peuvent pas créer de projets, de groupes et de snippets dans leurs espaces de nommage personnels.
- Ne peuvent pas modifier les données existantes qu'ils n'ont pas créées.
- Ne peuvent pas consulter le code dans les projets.

## Utilisation des sièges {#seat-usage}

- Dans GitLab Free et Premium, les utilisateurs disposant du rôle Invité sont comptabilisés comme utilisateur facturable et consomment un siège de licence.
- Dans GitLab Ultimate, les utilisateurs disposant du rôle Invité ne sont pas comptabilisés comme utilisateur facturable et ne consomment pas de siège de licence.

> [!note]
> Bien que le rôle Invité offre généralement un accès limité, la création d'un [rôle personnalisé](../user/custom_roles/_index.md) avec l'autorisation [`View repository code`](../user/custom_roles/abilities.md#source-code-management) vous permet de fournir un accès au code dans vos dépôts sans consommer un siège de licence. L'ajout d'autres autorisations entraîne l'occupation d'un siège facturable par le rôle.

## Attribuer le rôle Invité aux utilisateurs {#assign-guest-role-to-users}

Prérequis :

- Vous devez disposer du rôle Maintainer ou Owner.

Vous pouvez attribuer le rôle Invité à un membre actuel d'un groupe ou d'un projet, ou attribuer ce rôle lors de la création d'un nouveau membre. Vous pouvez effectuer cette opération via l'API (pour les [groupes](../api/group_members.md#add-a-group-member) ou les [projets](../api/project_members.md#add-a-member-to-a-project)) ou l'interface utilisateur GitLab.

Pour attribuer le rôle Invité à un membre actuel d'un groupe ou d'un projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe ou projet.
1. Sélectionnez **Gérer** > **Membres**.
1. Dans la colonne **Rôle** du membre du groupe ou du projet auquel vous souhaitez attribuer le rôle Invité, sélectionnez son rôle actuel (par exemple, **Développeur**).
1. Dans le volet **Détails du rôle**, remplacez le rôle par **Invité**.
1. Sélectionnez **Mettre à jour le rôle**.

Si l'utilisateur auquel vous souhaitez attribuer le rôle Invité n'est pas encore membre du groupe ou du projet :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe ou projet.
1. Sélectionnez **Gérer** > **Membres**.
1. Sélectionnez **Inviter des membres**.
1. Dans **Nom d'utilisateur, nom ou adresse de courriel**, sélectionnez l'utilisateur concerné.
1. Dans **Sélectionner un rôle**, sélectionnez **Invité**.
1. Facultatif. Dans **Date d’expiration de l’accès**, saisissez une date.
1. Sélectionnez **Inviter**.
