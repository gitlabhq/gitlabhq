---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Opérations Git de base
description: Apprenez les opérations Git de base pour gérer vos dépôts.
---

Les opérations Git de base vous aident à gérer vos dépôts Git et à apporter des modifications à votre code. Elles vous offrent les avantages suivants :

- Contrôle de version : Conservez un historique de votre projet pour suivre les modifications et revenir aux versions précédentes si nécessaire.
- Collaboration : Facilite la collaboration et simplifie le partage de code et le travail simultané.
- Organisation : Utilisez des branches et des merge requests pour organiser et gérer votre travail.
- Qualité du code : Facilite les revues de code via les merge requests et contribue à maintenir la qualité et la cohérence du code.
- Sauvegarde et récupération : Poussez les modifications vers des dépôts distants pour vous assurer que votre travail est sauvegardé et récupérable.

Pour utiliser efficacement les opérations Git, il est important de comprendre les concepts clés tels que les dépôts, les branches, les commits et les merge requests. Pour plus d'informations, consultez [Premiers pas avec Git](get_started.md).

Pour plus d'informations sur les commandes Git couramment utilisées, consultez [Commandes Git](commands.md).

## Créer un projet {#create-a-project}

La commande `git push` envoie les modifications de votre dépôt local vers un dépôt distant. Vous pouvez créer un projet à partir d'un dépôt local ou importer un dépôt existant. Après avoir ajouté un dépôt, GitLab crée un projet dans l'espace de nommage de votre choix. Pour plus d'informations, consultez [créer un projet](project.md).

## Cloner un dépôt {#clone-a-repository}

La commande `git clone` crée une copie d'un dépôt distant sur votre ordinateur. Vous pouvez travailler sur le code localement et pousser les modifications vers le dépôt distant. Pour plus d'informations, consultez [cloner un dépôt Git](clone.md).

## Créer une branche {#create-a-branch}

La commande `git checkout -b <name-of-branch>` crée une nouvelle branche dans votre dépôt. Une branche est une copie des fichiers de votre dépôt que vous pouvez modifier sans affecter la branche par défaut. Pour plus d'informations, consultez [créer une branche](branch.md).

## Indexer, committer et pousser des modifications {#stage-commit-and-push-changes}

Les commandes `git add`, `git commit` et `git push` mettent à jour votre dépôt distant avec vos modifications. Git suit les modifications par rapport à la version la plus récente de la branche extraite. Pour plus d'informations, consultez [indexer, committer et pousser des modifications](commit.md).

## Remiser des modifications {#stash-changes}

La commande `git stash` sauvegarde temporairement les modifications que vous ne souhaitez pas committer immédiatement. Vous pouvez changer de branche ou effectuer d'autres opérations sans committer des modifications incomplètes. Pour plus d'informations, consultez [remiser des modifications](stash.md).

## Ajouter des fichiers à une branche {#add-files-to-a-branch}

La commande `git add <filename>` ajoute des fichiers à un dépôt Git ou à une branche. Vous pouvez ajouter de nouveaux fichiers, modifier des fichiers existants ou supprimer des fichiers. Pour plus d'informations, consultez [ajouter des fichiers à une branche](add_files.md).

## Merge requests {#merge-requests}

Une merge request est une demande de fusion des modifications d'une branche vers une autre branche. Les merge requests offrent un moyen de collaborer et de réviser les modifications de code. Pour plus d'informations, consultez [les merge requests](../../user/project/merge_requests/_index.md) et [fusionner votre branche](merge.md).

## Mettre à jour votre duplication {#update-your-fork}

Une duplication est une copie personnelle du dépôt et de toutes ses branches, que vous créez dans un espace de nommage de votre choix. Vous pouvez apporter des modifications dans votre propre duplication et les soumettre à l'aide de `git push`. Pour plus d'informations, consultez [mettre à jour une duplication](forks.md).

## Sujets connexes {#related-topics}

- [Premiers pas avec Git](get_started.md)
  - [Installer Git](how_to_install_git/_index.md)
  - [Commandes Git courantes](commands.md)
- [Opérations avancées](advanced.md)
- [Résolution des problèmes Git](troubleshooting_git.md)
- [Aide-mémoire Git](https://about.gitlab.com/images/press/git-cheat-sheet.pdf)
