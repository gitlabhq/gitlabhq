---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisateurs externes
description: Accordez un accès limité aux membres externes avec des autorisations restreintes pour des ressources spécifiques.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les utilisateurs externes ont un accès limité aux groupes et projets internes ou privés de l'instance. Contrairement aux utilisateurs ordinaires, les utilisateurs externes doivent être explicitement ajoutés à un groupe ou à un projet. Cependant, comme les utilisateurs ordinaires, les utilisateurs externes se voient attribuer un rôle de membre et bénéficient de toutes les [autorisations](../user/permissions.md#project-permissions) associées.

Les utilisateurs externes :

- Peuvent accéder aux groupes, projets et extraits de code publics.
- Peuvent accéder aux groupes et projets internes ou privés dont ils sont membres.
- Peuvent créer des sous-groupes, des projets et des extraits de code dans tout groupe principal dont ils sont membres.
- Ne peuvent pas créer de groupes, de projets ou d'extraits de code dans leur espace de nommage personnel.

Les utilisateurs externes sont généralement créés lorsqu'un utilisateur extérieur à une organisation a besoin d'accéder uniquement à un projet spécifique. Lors de l'attribution d'un rôle à un utilisateur externe, vous devez être conscient de la [visibilité du projet](../user/public_access.md#change-project-visibility) et des [autorisations](../user/project/settings/_index.md#configure-project-features-and-permissions) associées au rôle. Par exemple, si un utilisateur externe se voit attribuer le rôle Invité pour un projet privé, il ne peut pas accéder au code.

> [!note]
> Un utilisateur externe est comptabilisé comme un utilisateur facturable et consomme un siège de licence.
>
> Si vous avez [créé une liste de fournisseurs externes](../integration/omniauth.md#create-an-external-providers-list), les utilisateurs qui se connectent avec un fournisseur répertorié sont automatiquement marqués comme externes.

## Créer un utilisateur externe {#create-an-external-user}

Prérequis :

- Accès administrateur.

Pour créer un nouvel utilisateur externe :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Utilisateurs**.
1. Sélectionnez **Nouvel utilisateur**.
1. Dans la section **Compte**, saisissez les informations de compte requises.
1. Facultatif. Dans la section **Accès**, configurez les limites de projet ou les paramètres de type d'utilisateur.
1. Cochez la case **Externe**.
1. Sélectionnez **Créer un utilisateur**.

Vous pouvez également créer des utilisateurs externes avec :

- [Groupes SAML](../integration/saml.md#external-groups).
- [Groupes LDAP](auth/ldap/ldap_synchronization.md#external-groups).
- La [liste des fournisseurs externes](../integration/omniauth.md#create-an-external-providers-list).
- L'[API utilisateurs](../api/users.md).

## Les nouveaux utilisateurs sont définis comme externes par défaut {#make-new-users-external-by-default}

Vous pouvez configurer votre instance pour que tous les nouveaux utilisateurs soient définis comme externes par défaut. Vous pouvez modifier ces comptes utilisateur ultérieurement pour supprimer la désignation externe.

Lorsque vous configurez cette fonctionnalité, vous pouvez également définir une expression régulière utilisée pour identifier les adresses e-mail. Les nouveaux utilisateurs dont l'adresse e-mail correspond à l'expression sont exclus et ne sont pas marqués comme utilisateurs externes. Cette expression régulière doit :

- Utiliser le format Ruby.
- Être convertible en JavaScript.
- Avoir le drapeau d'insensibilité à la casse défini (`/regex pattern/i`).

Par exemple :

- `\.int@example\.com$` : Correspond aux adresses e-mail qui se terminent par `.int@domain.com`.
- `^(?:(?!\.ext@example\.com).)*$\r?` : Correspond aux adresses e-mail qui n'incluent pas `.ext@example.com`.

> [!warning]
> L'ajout d'une expression régulière peut augmenter le risque d'une attaque par déni de service basée sur les expressions régulières (ReDoS).

Prérequis :

- Vous devez être administrateur de l'instance GitLab Self-Managed.

Pour définir les nouveaux utilisateurs comme externes par défaut :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez la section **Limitations du compte**.
1. Cochez la case **Les nouveaux utilisateurs et utilisatrices sont définis comme externes par défaut**.
1. Facultatif. Dans le champ **Schéma d'exclusion des courriels**, saisissez une expression régulière.
1. Sélectionnez **Sauvegarder les modifications**.
