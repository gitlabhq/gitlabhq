---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Limite de push gratuite
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com

{{< /details >}}

Une limite de 100 Mio par fichier s'applique lors du push de nouveaux fichiers vers tout projet de l'édition Gratuite.

Si un nouveau fichier de 100 Mio ou plus est poussé vers un projet de l'édition Gratuite, une erreur s'affiche. Par exemple :

```shell
Enumerating objects: 3, done.
Counting objects: 100% (3/3), done.
Delta compression using up to 10 threads
Compressing objects: 100% (2/2), done.
Writing objects: 100% (3/3), 100.03 MiB | 1.08 MiB/s, done.
Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
remote: GitLab: You are attempting to check in one or more files which exceed the 100MiB limit:

- 257cc5642cb1a054f08cc83f2d943e56fd3ebe99 (123 MiB)
- 5716ca5987cbf97d6bb54920bea6adde242d87e6 (396 MiB)

Please refer to https://docs.gitlab.com/user/free_user_limit/ for further information.
To https://gitlab.com/group/my-project.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to 'https://gitlab.com/group/my-project.git'
```

L'erreur répertorie les identifiants uniques des fichiers plutôt que leurs noms. Pour rechercher le nom du fichier à partir de l'identifiant unique, exécutez la commande suivante :

```shell
tree -r | grep <id>
```

Étant donné que Git n'est pas conçu pour gérer efficacement les données volumineuses non textuelles, vous devriez utiliser [Git LFS](../topics/git/lfs/_index.md) pour ces fichiers. Git LFS est conçu pour fonctionner avec Git afin d'effectuer le suivi des fichiers volumineux.

## Dépannage {#troubleshooting}

Lors de la résolution de la limite de push, vous pouvez rencontrer les problèmes suivants.

### Un message d'erreur s'affiche après la suppression d'un fichier volumineux {#error-message-displays-after-removing-large-file}

Vous pouvez obtenir l'erreur de limite de push même après avoir supprimé le fichier volumineux de votre dépôt localement. Pour résoudre ce problème, essayez de supprimer le commit qui a introduit le fichier volumineux.

Pour plus d'informations, consultez [rétablir des commits et modifier l'historique](../topics/git/undo.md#revert-commits-and-modify-history).
