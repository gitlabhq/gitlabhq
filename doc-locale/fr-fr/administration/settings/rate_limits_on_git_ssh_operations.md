---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurer les limites de débit sur les opérations Git SSH sur GitLab Self-Managed.
title: Limites de débit sur les opérations Git SSH
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

GitLab applique des limites de débit aux opérations Git utilisant SSH par compte utilisateur et par projet. Lorsqu'un utilisateur dépasse la limite de débit, GitLab rejette les demandes de connexion supplémentaires de cet utilisateur pour le projet.

La limite de débit s'applique au niveau de la commande Git ([plumbing](https://git-scm.com/book/en/v2/Git-Internals-Plumbing-and-Porcelain)). Chaque commande a une limite de débit de 600 par minute. Par exemple :

- `git push` a une limite de débit de 600 par minute.
- `git pull` a sa propre limite de débit de 600 par minute.

Les commandes `git-upload-pack`, `git pull` et `git clone` partagent une limite de débit car elles partagent des commandes.

## Configurer la limite d'opérations GitLab Shell {#configure-gitlab-shell-operation-limit}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123761) dans GitLab 16.2.

{{< /history >}}

Prérequis :

- Accès administrateur.

`Git operations using SSH` est activé par défaut. Par défaut, 600 par utilisateur par minute.

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Réseau**.
1. Développez **Git SSH operations rate limit**.
1. Saisissez une valeur pour **Nombre maximum d'opérations Git par minute**.
   - Pour désactiver la limite de débit, définissez-la sur `0`.
1. Sélectionnez **Sauvegarder les modifications**.
