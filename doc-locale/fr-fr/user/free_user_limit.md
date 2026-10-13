---
stage: Fulfillment
group: Seat Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Limites d'utilisateurs et de groupes de l'édition Gratuite"
---

{{< details >}}

- Édition : Gratuite
- Offre : GitLab.com

{{< /details >}}

Si vous utilisez l'édition Gratuite, les limites d'utilisateurs et de groupes suivantes s'appliquent.

## Limite d'utilisateurs Gratuite {#free-user-limit}

Vous pouvez ajouter jusqu'à cinq utilisateurs aux espaces de nommage principaux nouvellement créés avec une visibilité privée sur GitLab.com.

Si l'espace de nommage a été créé avant le 28 décembre 2022, cette limite d'utilisateurs a été appliquée le 13 juin 2023.

Les espaces de nommage principaux privés comptant plus de cinq utilisateurs sont placés en état de lecture seule. Ces espaces de nommage ne peuvent pas écrire de nouvelles données dans les éléments suivants :

- Dépôts
- Git Large File Storage (LFS)
- les paquets ;
- Registres.

Pour la liste complète des actions restreintes, consultez [les espaces de nommage en lecture seule](read_only_namespaces.md).

Les limites d'utilisateurs ne s'appliquent pas aux utilisateurs de l'édition Gratuite de :

- GitLab.com, pour :
  - Les groupes principaux publics
  - Les espaces de nommage personnels, car ils sont publics par défaut
  - Les éditions payantes
  - Les [programmes communautaires](https://about.gitlab.com/community/) suivants :
    - GitLab for Open Source
    - GitLab for Education
    - GitLab for Startups
- [Abonnements GitLab Self-Managed](../subscriptions/manage_subscription.md)

Pour plus d'informations, vous pouvez [parler à un expert](https://page.gitlab.com/usage_limits_help.html).

## Limites des groupes principaux {#top-level-group-limits}

Les comptes créés après le 27 janvier 2026 sur l'édition Gratuite sont limités à trois groupes principaux (espaces de nommage de groupe). Votre [espace de nommage personnel](namespace/_index.md#types-of-namespaces) n'est pas comptabilisé dans cette limite. Cette limite s'applique également aux comptes bénéficiant d'un essai GitLab Ultimate.

Pour créer davantage de groupes, passez à une édition payante.

## Déterminer le nombre d'utilisateurs d'un espace de nommage {#determine-namespace-user-counts}

Chaque utilisateur unique d'un espace de nommage principal avec une visibilité privée est comptabilisé dans la limite de cinq utilisateurs. Cela inclut chaque utilisateur d'un groupe, d'un sous-groupe et d'un projet au sein d'un espace de nommage.

Par exemple, il existe deux groupes, `example-1` et `example-2`.

Le groupe `example-1` contient :

- Un propriétaire de groupe, `A`.
- Un sous-groupe appelé `subgroup-1` avec un membre, `B`.
  - `subgroup-1` hérite de `A` en tant que membre de `example-1`.
- Un projet dans `subgroup-1` appelé `project-1` avec deux membres, `C` et `D`.
  - `project-1` hérite de `A` et `B` en tant que membres de `subgroup-1`.

L'espace de nommage `example-1` compte quatre membres uniques : `A`, `B`, `C` et `D`, et ne dépasse donc pas la limite de cinq utilisateurs.

Le groupe `example-2` contient :

- Un propriétaire de groupe, `A`.
- Un sous-groupe appelé `subgroup-2` avec un membre, `B`.
  - `subgroup-2` hérite de `A` en tant que membre de `example-2`.
- Un projet dans `subgroup-2` appelé `project-2a` avec deux membres, `C` et `D`.
  - `project-2a` hérite de `A` et `B` en tant que membres de `subgroup-2`.
- Un projet dans `subgroup-2` appelé `project-2b` avec deux membres, `E` et `F`.
  - `project-2b` hérite de `A` et `B` en tant que membres de `subgroup-2`.

L'espace de nommage `example-2` compte six membres uniques : `A`, `B`, `C`, `D`, `E` et `F`, et dépasse donc la limite de cinq utilisateurs.

## Gérer les membres dans votre espace de nommage de groupe {#manage-members-in-your-group-namespace}

Pour vous aider à gérer votre limite d'utilisateurs Gratuite, vous pouvez afficher et gérer le nombre total de membres dans tous les projets et groupes de votre espace de nommage.

Prérequis :

- Vous devez avoir le rôle Propriétaire pour le groupe.

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Quotas d'utilisation**.
1. Pour afficher tous les membres, sélectionnez l'onglet **Sièges**.

Sur cette page, vous pouvez afficher et gérer tous les membres de votre espace de nommage. Par exemple, pour supprimer un membre, sélectionnez **Supprimer l'utilisateur**.

## Inclure un groupe dans l'abonnement d'une organisation {#include-a-group-in-an-organizations-subscription}

Si votre organisation possède plusieurs groupes, ils peuvent disposer d'une combinaison d'abonnements payants (édition Premium ou Ultimate) et d'abonnements à l'édition Gratuite. Lorsqu'un groupe avec un abonnement à l'édition Gratuite dépasse la limite d'utilisateurs, son espace de nommage devient [en lecture seule](read_only_namespaces.md).

Pour supprimer les limites d'utilisateurs sur les groupes avec des abonnements à l'édition Gratuite, incluez ces groupes dans l'abonnement de votre organisation :

1. Pour vérifier si un groupe est inclus dans l'abonnement, [consultez les détails de l'abonnement de ce groupe](../subscriptions/manage_subscription.md#view-subscription).

   Si le groupe dispose d'un abonnement à l'édition Gratuite, il n'est pas inclus dans l'abonnement de votre organisation.

1. Pour inclure un groupe dans votre abonnement payant à l'édition Premium ou Ultimate, [transférez ce groupe](group/manage.md#transfer-a-group) vers l'espace de nommage principal de votre organisation.

Si la limite de cinq utilisateurs a été appliquée à votre groupe alors que vous disposez d'un abonnement payant à l'édition Premium ou Ultimate, assurez-vous que [votre abonnement est lié](../subscriptions/manage_subscription.md#link-subscription-to-a-group) à l'un des éléments suivants :

- L'espace de nommage principal approprié.
- Votre compte [Portail clients](../subscriptions/billing_account.md).

### Impact des groupes transférés sur les coûts d'abonnement {#impact-of-transferred-groups-on-subscription-costs}

Lorsque vous transférez un groupe vers l'abonnement de votre organisation, cela peut augmenter votre nombre de sièges. Cela peut entraîner des coûts supplémentaires pour votre abonnement.

Par exemple, votre entreprise dispose du Groupe A et du Groupe B :

- Le Groupe A dispose d'un abonnement payant à l'édition Premium ou Ultimate et compte cinq utilisateurs.
- Le Groupe B dispose d'un abonnement à l'édition Gratuite et compte huit utilisateurs, dont quatre sont membres du Groupe A.
- Le Groupe B est en état de lecture seule car il dépasse la limite de cinq utilisateurs.
- Vous transférez le Groupe B vers l'abonnement de votre entreprise pour supprimer l'état de lecture seule.
- Votre entreprise supporte un coût supplémentaire de quatre sièges pour les quatre membres du Groupe B qui ne sont pas membres du Groupe A.

Les utilisateurs qui ne font pas partie de l'espace de nommage principal nécessitent des sièges supplémentaires pour rester actifs. Pour plus d'informations, consultez [acheter des sièges pour votre abonnement](../subscriptions/manage_seats.md#buy-more-seats).

## Augmenter la limite de cinq utilisateurs {#increase-the-five-user-limit}

Sur l'édition d'abonnement Gratuite de GitLab.com, vous ne pouvez pas augmenter la limite de cinq utilisateurs sur les groupes principaux avec une visibilité privée.

Pour les équipes plus importantes, vous devriez passer aux éditions payantes Premium ou Ultimate. Ces éditions ne limitent pas le nombre d'utilisateurs et offrent davantage de fonctionnalités pour accroître la productivité des équipes. Pour plus d'informations, consultez [Mettre à niveau votre édition d'abonnement sur GitLab Self-Managed](../subscriptions/manage_subscription.md#upgrade-subscription-tier).

Pour essayer les éditions payantes avant de décider de passer à une version supérieure, démarrez un [essai gratuit](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com/user/free_user_limit/) de GitLab Ultimate.

## Gérer les membres dans des projets personnels en dehors d'un espace de nommage de groupe {#manage-members-in-personal-projects-outside-a-group-namespace}

Les projets personnels ne sont pas situés dans des espaces de nommage de groupes principaux. Vous pouvez gérer les utilisateurs dans chacun de vos projets personnels. Vous pouvez avoir plus de cinq utilisateurs dans vos projets personnels.

Vous devriez [déplacer votre projet personnel vers un groupe](../tutorials/move_personal_project_to_group/_index.md) afin de pouvoir :

- Augmenter le nombre d'utilisateurs à plus de cinq.
- Acheter un abonnement à une édition payante, des minutes de calcul supplémentaires ou du stockage.
- Utiliser les [fonctionnalités GitLab](https://about.gitlab.com/pricing/feature-comparison/) dans le groupe.
- Démarrer un [essai gratuit](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com/user/free_user_limit/) de GitLab Ultimate.
