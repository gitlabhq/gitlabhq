---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Visibilité des projets et des groupes
description: "Public, privé et interne."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les projets et les groupes dans GitLab peuvent être privés, internes ou publics.

Le niveau de visibilité du projet ou du groupe n'affecte pas la capacité des membres du projet ou du groupe à se voir mutuellement. Les projets et les groupes sont destinés au travail collaboratif. Ce travail n'est possible que si tous les membres se connaissent mutuellement.

Les membres d'un projet ou d'un groupe peuvent voir tous les membres du projet ou du groupe auquel ils appartiennent. Les membres d'un projet ou d'un groupe peuvent voir l'origine de l'appartenance (le projet ou le groupe d'origine) de tous les membres des projets et des groupes auxquels ils ont accès.

## Projets et groupes privés {#private-projects-and-groups}

Pour les projets privés, seuls les membres du projet ou du groupe privé peuvent :

- Cloner le projet.
- Afficher le répertoire d'accès public (`/public`).

Les utilisateurs disposant du rôle Invité ne peuvent pas cloner le projet.

Les groupes privés ne peuvent avoir que des sous-groupes et des projets privés.

> [!note]
> Lorsque vous [partagez un groupe privé avec un autre groupe](project/members/sharing_projects_groups.md#invite-a-group-to-a-group), les utilisateurs qui n'ont pas accès au groupe privé peuvent afficher une liste des utilisateurs qui ont accès au groupe invitant via le point de terminaison `https://gitlab.com/groups/<inviting-group-name>/-/autocomplete_sources/members`. Cependant, le nom et le chemin du groupe privé sont masqués, et la source d'appartenance des utilisateurs n'est pas affichée.

## Projets et groupes internes {#internal-projects-and-groups}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Pour les projets internes, tout utilisateur authentifié, y compris les utilisateurs disposant du rôle Invité, peut :

- Cloner le projet.
- Afficher le répertoire d'accès public (`/public`).

Seuls les membres internes peuvent afficher le contenu interne.

Les [utilisateurs externes](../administration/external_users.md) ne peuvent pas cloner le projet.

Les groupes internes peuvent avoir des sous-groupes et des projets internes ou privés.

## Projets et groupes publics {#public-projects-and-groups}

Pour les projets publics, tout utilisateur, y compris les utilisateurs non authentifiés, peut :

- Cloner le projet.
- Afficher le répertoire d'accès public (`/public`).

Les groupes publics peuvent avoir des sous-groupes et des projets publics, internes ou privés.

> [!note]
> Si un administrateur restreint le [niveau de visibilité **Public**](../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels), le répertoire d'accès public (`/public`) n'est visible que par les utilisateurs authentifiés.

## Modifier la visibilité d'un projet {#change-project-visibility}

Vous pouvez modifier la visibilité d'un projet.

Prérequis :

- Vous devez disposer du rôle Propriétaire pour un projet.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Dans la liste déroulante **Visibilité du projet**, sélectionnez une option. Le paramètre de visibilité d'un projet doit être au moins aussi restrictif que la visibilité de son groupe parent. Si le projet est une duplication, la visibilité doit être au moins aussi restrictive que la visibilité de son projet en amont. Pour plus d'informations, consultez [la visibilité des duplications](project/repository/forking_workflow.md#create-a-fork).
1. Sélectionnez **Enregistrer les modifications**.

## Modifier la visibilité des fonctionnalités individuelles dans un projet {#change-the-visibility-of-individual-features-in-a-project}

Vous pouvez modifier la visibilité des fonctionnalités individuelles dans un projet.

Prérequis :

- Vous devez disposer du rôle Chargé de maintenance ou Propriétaire dans le projet.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Pour activer ou désactiver une fonctionnalité, activez ou désactivez le bouton de la fonctionnalité.
1. Sélectionnez **Enregistrer les modifications**.

## Modifier la visibilité d'un groupe {#change-group-visibility}

Vous pouvez modifier la visibilité de tous les projets d'un groupe.

Prérequis :

- Vous devez disposer du rôle Propriétaire pour un groupe.
- Les projets et les sous-groupes doivent déjà avoir des paramètres de visibilité au moins aussi restrictifs que le nouveau paramètre du groupe parent. Par exemple, vous ne pouvez pas définir un groupe comme privé si un projet ou un sous-groupe de ce groupe est public.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Nommage, description, visibilité**.
1. Pour **Niveau de visibilité**, sélectionnez une option. Le paramètre de visibilité d'un projet doit être au moins aussi restrictif que la visibilité de son groupe parent.
1. Sélectionnez **Enregistrer les modifications**.

## Restreindre l'utilisation des projets publics ou internes {#restrict-use-of-public-or-internal-projects}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les administrateurs peuvent restreindre les niveaux de visibilité que les utilisateurs peuvent choisir lorsqu'ils créent un projet ou un extrait de code. Ce paramètre peut aider à empêcher les utilisateurs d'exposer accidentellement leurs dépôts au public.

Pour plus d'informations, consultez [Restreindre les niveaux de visibilité](../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels).
