---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Verrouillage de fichiers
---

Le verrouillage de fichiers empêche plusieurs personnes de modifier le même fichier simultanément, ce qui permet d'éviter les conflits de merge. Le verrouillage de fichiers est particulièrement utile pour les fichiers binaires qui ne peuvent pas être fusionnés, comme les fichiers de conception, les vidéos et autres contenus non textuels.

GitLab prend en charge deux types différents de verrouillage de fichiers :

- Verrous de fichiers exclusifs : appliqués via la ligne de commande avec Git LFS et [`.gitattributes`](repository/files/git_attributes.md). Ces verrous empêchent toute modification des fichiers verrouillés sur n'importe quelle branche. Disponible sur les éditions Gratuite, GitLab Premium et GitLab Ultimate. Pour plus d'informations, consultez [les verrous de fichiers exclusifs](../../topics/git/file_management.md#exclusive-file-locks).
- Verrous de fichiers et de répertoires sur la branche par défaut : appliqués via l'interface utilisateur de GitLab. Ces verrous empêchent uniquement les modifications des fichiers et répertoires sur la branche par défaut.

## Verrous de fichiers et de répertoires sur la branche par défaut {#default-branch-file-and-directory-locks}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Les verrous de branche par défaut s'appliquent uniquement à la [branche par défaut](repository/branches/default.md) définie dans les paramètres de votre projet. Ces verrous contribuent à maintenir la stabilité de votre branche par défaut sans bloquer les workflows des collaborateurs sur les autres branches.

Lorsqu'un fichier ou un répertoire est verrouillé par un utilisateur :

- Seul l'utilisateur qui a créé le verrou peut modifier le fichier ou le répertoire sur la branche par défaut.
- Pour les autres utilisateurs, le fichier ou répertoire verrouillé est en lecture seule sur la branche par défaut.
- Les modifications directes apportées aux fichiers ou répertoires verrouillés sur la branche par défaut sont bloquées.
- Les merge requests qui modifient des fichiers ou répertoires verrouillés ne peuvent pas être mergées dans la branche par défaut.

> [!note]
> Sur les branches non définies par défaut, tous les utilisateurs peuvent toujours modifier les fichiers et répertoires verrouillés. Un statut **Verrouiller** est visible sur ces fichiers et répertoires. Cela aide les membres de l'équipe à être informés des travaux en cours sans restreindre leur workflow sur les autres branches.
>
> Le verrouillage de fichiers est également contourné lors de la synchronisation de duplications. Lorsque vous [mettez à jour une duplication](repository/forking_workflow.md#update-your-fork) depuis son projet amont, les fichiers verrouillés dans la duplication peuvent être écrasés par les modifications provenant du projet amont.

### Autorisations {#permissions}

Vous devez disposer du rôle Développeur, Mainteneur ou Propriétaire pour le projet afin de créer, consulter ou gérer les verrous de la branche par défaut. Pour plus d'informations, consultez [les rôles et autorisations](../permissions.md).

### Verrouiller un fichier ou un répertoire {#lock-a-file-or-directory}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/519325) dans GitLab 17.10 [avec le feature flag](../../administration/feature_flags/_index.md) `blob_overflow_menu`. Fonctionnalité désactivée par défaut.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/522993) dans GitLab 18.1. Le feature flag `blob_overflow_menu` a été supprimé.
- Le bouton Verrouiller a été [modifié](https://gitlab.com/gitlab-org/gitlab/-/issues/545279) dans GitLab 19.4 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `repository_lock_information`. Activés par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Pour verrouiller un fichier ou un répertoire :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Accédez au fichier ou répertoire que vous souhaitez verrouiller.
1. Dans le coin supérieur droit, sélectionnez **Verrouiller**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Verrouiller**.

Le bouton devient **Verrouillé**. Pour voir qui a verrouillé le fichier ou le répertoire et quand, sélectionnez **Verrouillé**.

Vous ne pouvez pas verrouiller un répertoire si un fichier ou répertoire qu'il contient est déjà verrouillé. Vous ne pouvez pas déverrouiller un répertoire si un répertoire parent est verrouillé. Dans les deux cas, le bouton affiche **Verrouillé**, et les détails expliquent le verrou associé. Pour afficher le fichier ou répertoire verrouillé, sélectionnez **Afficher le verrouillage**.

Si **Verrouiller** ne s'affiche pas, vous ne disposez pas des autorisations requises pour verrouiller le fichier ou le répertoire.

### Afficher les fichiers verrouillés {#view-locked-files}

Pour afficher les fichiers verrouillés :

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Fichiers verrouillés**.

La page **Fichiers verrouillés** affiche tous les fichiers verrouillés avec des verrous exclusifs Git LFS ou via l'interface utilisateur de GitLab.

### Supprimer les verrous de fichiers {#remove-file-locks}

Prérequis :

- Vous devez, soit :
  - Être l'utilisateur qui a créé le verrou.
  - Disposer du rôle Mainteneur ou Propriétaire pour le projet.

Pour supprimer un verrou :

{{< tabs >}}

{{< tab title="Depuis un fichier ou un répertoire" >}}

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Accédez au fichier ou répertoire que vous souhaitez déverrouiller.
1. Sélectionnez **Verrouillé**.
1. Sélectionnez **Déverrouiller le fichier** ou **Déverrouiller le répertoire**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **Déverrouiller**.

{{< /tab >}}

{{< tab title="Depuis la page Fichiers verrouillés" >}}

1. Dans la barre supérieure, sélectionnez **Rechercher ou accéder à**, puis recherchez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Fichiers verrouillés**.
1. À droite du fichier que vous souhaitez déverrouiller, sélectionnez **Déverrouiller**.
1. Dans la boîte de dialogue de confirmation, sélectionnez **OK**.

{{< /tab >}}

{{< /tabs >}}

Pour supprimer un verrou de fichier exclusif, consultez [verrouiller et déverrouiller des fichiers](../../topics/git/file_management.md#lock-and-unlock-files).

## Vérifications des merge requests et propriété des verrous {#merge-request-checks-and-lock-ownership}

Lorsqu'une merge request incluant des modifications de fichiers ou répertoires verrouillés est définie pour être mergée, GitLab vérifie si l'auteur de la merge request est le propriétaire du verrou. GitLab ne vérifie pas les auteurs individuels des commits.

Par exemple :

- Si l'auteur de la merge request est le même utilisateur qui a verrouillé le fichier ou le répertoire, la merge request peut être mergée.
- Si l'auteur de la merge request est différent du propriétaire du verrou, la merge request est bloquée.

> [!note]
> Les utilisateurs autres que l'auteur de la merge request peuvent pousser des modifications vers la branche de la merge request qui mettent à jour ou modifient des fichiers ou répertoires verrouillés. La vérification du verrou prend uniquement en compte l'auteur de la merge request ; par conséquent, la merge request n'est pas bloquée.

Pour empêcher les modifications non autorisées des fichiers verrouillés :

- Utilisez des [règles d'approbation de merge request](merge_requests/approvals/rules.md) qui exigent une révision avant le merge.
- Surveillez les merge requests vers les fichiers verrouillés pour vous assurer que seules les modifications autorisées sont incluses.
- Réfléchissez à qui a l'autorisation de pousser vers les branches de merge request existantes dans votre workflow.

## Sujets connexes {#related-topics}

- [Verrous de fichiers exclusifs](../../topics/git/file_management.md#exclusive-file-locks)
