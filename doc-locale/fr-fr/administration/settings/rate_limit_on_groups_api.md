---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Limites de débit de l'API des groupes"
description: "Définir des limites de débit sur les points de terminaison de l'API des groupes."
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> Lors de la mise à niveau vers GitLab 18.0 ou une version ultérieure, les limites de débit configurables pour cette API sont définies sur `0`. Les administrateurs peuvent ajuster les limites de débit selon leurs besoins. Pour obtenir des informations sur les limites de débit concernées, consultez [Rate limitations announced for Projects, Groups, and Users APIs](https://about.gitlab.com/blog/rate-limitations-announced-for-projects-groups-and-users-apis/#rate-limitation-details).

## Configurer les limites de débit de l'API des groupes {#configure-groups-api-rate-limits}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/152733) de la limite de débit pour l'API des groupes et des projets dans GitLab 17.1 avec un [indicateur](../feature_flags/_index.md) nommé `rate_limit_groups_and_projects_api`. Désactivé par défaut.
- [Disponible en général](https://gitlab.com/gitlab-org/gitlab/-/issues/461316) dans GitLab 18.1. Indicateur de feature flag `rate_limit_groups_and_projects_api` supprimé.

{{< /history >}}

Configurez la limite de débit pour chaque adresse IP et utilisateur pour les requêtes vers les points de terminaison de l'API des groupes suivants :

| Limite                                                           | Valeur par défaut | Intervalle |
|-----------------------------------------------------------------|---------|----------|
| [`GET /groups`](../../api/groups.md#list-groups)                | 200     | 1 minute |
| [`GET /groups/:id`](../../api/groups.md#retrieve-a-group)     | 400     | 1 minute |
| [`GET /groups/:id/groups/shared`](../../api/groups.md#list-shared-groups) | 0     | 1 minute |
| [`GET /groups/:id/invited_groups`](../../api/groups.md#list-shared-groups) | 60     | 1 minute |
| [`GET /groups/:id/projects`](../../api/groups.md#list-projects) | 600     | 1 minute |
| [`POST /groups/:id/archive`](../../api/groups.md#archive-a-group) | 60    | 1 minute |

Prérequis :

- Accès administrateur.

Pour modifier la limite de débit :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Limites de débit de l'API des groupes**.
1. Modifiez la valeur de n'importe quelle limite de débit, ou définissez une limite de débit sur `0` pour la désactiver.
1. Sélectionnez **Sauvegarder les modifications**.

Les limites de débit :

- S'appliquent à chaque utilisateur authentifié. Si les requêtes ne sont pas authentifiées, les limites de débit s'appliquent à l'adresse IP.
- Peuvent être définies à 0 pour désactiver la limitation de débit.

Les requêtes dépassant la limite de débit sont consignées dans le fichier `auth.log`.

Par exemple, si vous définissez une limite de 400 pour `GET /groups/:id`, les requêtes vers le point de terminaison de l'API qui dépassent un débit de 400 par minute sont bloquées. L'accès au point de terminaison est rétabli après une minute.

## Limite de débit sur la liste des membres d'un groupe {#rate-limit-on-listing-group-members}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/578527) dans GitLab 18.6.

{{< /history >}}

Une limite de débit est définie sur le [point de terminaison de l'API listant tous les membres du groupe](../../api/group_members.md#list-all-group-members-including-inherited-and-invited-members).

Les points de terminaison d'API `GET /projects/:id/members/all` et `GET /groups/:id/members/all` partagent la même configuration de limite de débit. Si vous définissez une limite de débit sur le point de terminaison des projets, la limite de débit s'applique également au point de terminaison des groupes.

Prérequis :

- Accès administrateur.

Pour modifier cette limite de débit pour les deux points de terminaison :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Limitations du débit de l'API des projets**.
1. Dans la zone de texte **Maximum de requêtes vers l'API `GET /projects/:id/members/all` par minute par utilisateur ou adresse IP**, saisissez une valeur.
1. Sélectionnez **Sauvegarder les modifications**.

La limite de débit :

- Par défaut, 200 requêtes par minute.
- S'applique pour chaque groupe et utilisateur.
- Est configurée via les paramètres de limitations du débit de l'API des projets. Pour plus d'informations, consultez [Configurer les limites de débit sur la liste des membres d'un projet](rate_limit_on_projects_api.md#configure-rate-limits-on-listing-project-members).
- Peut être définie sur `0` pour désactiver la limite de débit pour les deux points de terminaison.

Les requêtes dépassant la limite de débit sont consignées dans le fichier `auth.log`.

Par exemple, les requêtes vers le point de terminaison de l'API qui dépassent un débit de 200 requêtes par minute sont bloquées. L'accès au point de terminaison reprend après une minute.

## Configurer les limites de débit sur l'archivage et le désarchivage des groupes {#configure-rate-limits-on-group-archiving-and-unarchiving}

{{< details >}}

- Statut :  Expérimentation

{{< /details >}}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/481969) dans GitLab 18.0 [avec un indicateur](../feature_flags/_index.md) nommé `archive_group`. Désactivé par défaut.
- [Disponible globalement](https://gitlab.com/gitlab-org/gitlab/-/issues/526771) depuis GitLab 18.9. Indicateur de feature flag `archive_group` supprimé.

{{< /history >}}

Configurez une limite de débit sur les requêtes vers les points de terminaison d'archivage de groupe suivants :

```plaintext
POST /groups/:id/archive
POST /groups/:id/unarchive
```

Prérequis :

- Accès administrateur.

Pour modifier la limite de débit :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Limites de débit de l'API des groupes**.
1. Dans la zone de texte **Maximum de requêtes vers les API `POST /groups/:id/archive` et `POST /groups/:id/unarchive` par minute par utilisateur ou adresse IP**, saisissez une valeur.
1. Sélectionnez **Sauvegarder les modifications**.

La limite de débit :

- Par défaut, 60 requêtes par minute
- S'appliquent à chaque utilisateur authentifié. Si les requêtes ne sont pas authentifiées, les limites de débit s'appliquent à l'adresse IP.
- Peut être définie sur `0` pour désactiver les limites de débit pour les deux points de terminaison

Les requêtes dépassant la limite de débit sont consignées dans le fichier `auth.log`.

Par exemple, si vous définissez une limite de 60, les requêtes vers le point de terminaison de l'API qui dépassent un débit de 60 requêtes par minute sont bloquées. L'accès au point de terminaison reprend après une minute.

Pour plus d'informations sur les points de terminaison d'archivage de groupe, consultez [Archiver un groupe](../../api/groups.md#archive-a-group).

## Configurer les limites de débit sur la suppression des membres d'un groupe {#configure-rate-limits-on-deleting-group-members}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/420321) dans GitLab 16.9.

{{< /history >}}

Configurez la limite de débit pour chaque groupe et utilisateur pour les requêtes vers le [point de terminaison de suppression des membres](../../api/group_members.md#remove-a-group-member).

Prérequis :

- Accès administrateur.

Pour modifier la limite de débit :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Members API rate limit**.
1. Dans la zone de texte **Maximum de requêtes par minute et par groupe/projet**, saisissez une valeur.
1. Sélectionnez **Sauvegarder les modifications**.

La limite de débit :

- Par défaut, 60 requêtes par minute.
- S'applique pour chaque groupe et utilisateur.
- Peut être définie sur `0` pour désactiver la limite de débit.

Les requêtes dépassant la limite de débit sont consignées dans le fichier `auth.log`.

Par exemple, si vous définissez une limite de 60, les requêtes vers le point de terminaison de l'API qui dépassent un débit de 60 requêtes par minute sont bloquées. L'accès au point de terminaison est rétabli après une minute.
