---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Exiger la confirmation des courriels pour les nouveaux utilisateurs
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab peut être configuré pour exiger la confirmation de l'adresse courriel d'un utilisateur lors de son inscription. Lorsque ce paramètre est activé, l'utilisateur ne peut pas se connecter tant qu'il n'a pas confirmé son adresse courriel.

Prérequis :

- Accès administrateur.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Généralités**.
1. Développez **Restrictions pour les nouveaux comptes utilisateurs** et recherchez les options **Paramètres de confirmation des courriels**.

## Expiration du jeton de confirmation {#confirmation-token-expiry}

Par défaut, un utilisateur peut confirmer son compte dans les 24 heures suivant l'envoi du courriel de confirmation. Après 24 heures, le jeton de confirmation devient invalide.

## Supprimer automatiquement les utilisateurs non confirmés {#automatically-delete-unconfirmed-users}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque la confirmation par courriel est activée, les administrateurs peuvent activer le paramètre pour [supprimer automatiquement les utilisateurs non confirmés](../administration/moderate_users.md#automatically-delete-unconfirmed-users).
