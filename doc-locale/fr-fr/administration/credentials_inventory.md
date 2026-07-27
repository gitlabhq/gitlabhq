---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: Inventaire des identifiants
description: "Surveillez les identifiants grâce à un inventaire d'accès complet."
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/297441) sur GitLab.com dans GitLab 17.5.
- [Ajout](https://gitlab.com/gitlab-org/gitlab/-/work_items/498333) de la prise en charge des jetons de groupe et de projet sur GitLab.com dans GitLab 17.7.

{{< /history >}}

Utilisez l'inventaire des identifiants pour surveiller et contrôler l'accès à votre organisation.

- Sur GitLab.com, l'inventaire des identifiants surveille les utilisateurs d'entreprise et les comptes de service dans un groupe principal.
- Sur GitLab Self-Managed et GitLab Dedicated, l'inventaire des identifiants surveille tous les utilisateurs humains et les comptes de service sur l'ensemble de l'instance.

Prérequis :

- Sur GitLab.com, vous devez avoir le rôle Propriétaire pour un groupe.
- Sur GitLab Self-Managed et GitLab Dedicated, vous devez être administrateur.

## Afficher l'inventaire des identifiants {#view-the-credentials-inventory}

Vous pouvez utiliser l'inventaire des identifiants pour afficher :

- Les jetons d'accès personnels.
- Les jetons d'accès de groupe.
- Les jetons d'accès au projet.
- Les clés SSH.
- Les clés GPG (GitLab Self-Managed et GitLab Dedicated uniquement).

Pour afficher l'inventaire des identifiants :

{{< tabs >}}

{{< tab title="Pour une instance" >}}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Identifiants**.

{{< /tab >}}

{{< tab title="Pour un groupe" >}}

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation**.
1. Sélectionnez **Identifiants**.

{{< /tab >}}

{{< /tabs >}}

Vous pouvez utiliser l'inventaire pour consulter les détails des identifiants, notamment :

- La propriété.
- Les portées d'accès.
- Les modèles d'utilisation.
- Les dates d'expiration.
- Les dates de révocation.

## Révoquer les jetons d'accès personnels {#revoke-personal-access-tokens}

Pour révoquer un jeton d'accès personnel :

{{< tabs >}}

{{< tab title="Pour une instance" >}}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Identifiants**.
1. À côté du jeton d'accès personnel, sélectionnez **Révoquer**. Si le jeton a expiré ou a été révoqué précédemment, la date associée est affichée.

Le jeton d'accès est révoqué et l'utilisateur est notifié par e-mail.

{{< /tab >}}

{{< tab title="Pour un groupe" >}}

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation**.
1. Sélectionnez **Identifiants**.
1. À côté du jeton d'accès personnel, sélectionnez **Révoquer**. Si le jeton a expiré ou a été révoqué précédemment, la date associée est affichée.

Le jeton d'accès est révoqué et l'utilisateur est notifié par e-mail.

{{< /tab >}}

{{< /tabs >}}

## Révoquer les jetons d'accès au projet ou au groupe {#revoke-project-or-group-access-tokens}

Pour révoquer un jeton d'accès au projet ou un jeton d'accès de groupe :

{{< tabs >}}

{{< tab title="Pour une instance" >}}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Identifiants**.
1. Sélectionnez l'onglet **Jetons d'accès projet et groupe**.
1. À côté du jeton d'accès au projet, sélectionnez **Révoquer**.

{{< /tab >}}

{{< tab title="Pour un groupe" >}}

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation**.
1. Sélectionnez **Identifiants**.
1. Sélectionnez l'onglet **Jetons d'accès projet et groupe**.
1. À côté du jeton d'accès au projet, sélectionnez **Révoquer**.

{{< /tab >}}

{{< /tabs >}}

## Supprimer des clés SSH {#delete-ssh-keys}

Pour supprimer une clé SSH :

{{< tabs >}}

{{< tab title="Pour une instance" >}}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Identifiants**.
1. Sélectionnez l'onglet **Clés SSH**.
1. À côté de la clé SSH, sélectionnez **Supprimer**.

La clé SSH est supprimée et l'utilisateur est notifié.

{{< /tab >}}

{{< tab title="Pour un groupe" >}}

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Sécurisation**.
1. Sélectionnez **Identifiants**.
1. Sélectionnez l'onglet **Clés SSH**.
1. À côté de la clé SSH, sélectionnez **Supprimer**.

La clé SSH est supprimée et l'utilisateur est notifié.

{{< /tab >}}

{{< /tabs >}}
