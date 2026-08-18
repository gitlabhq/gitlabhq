---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Documentation sur le blame de fichiers Git.
title: Blame de fichiers Git
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

[Git blame](https://git-scm.com/docs/git-blame) fournit des informations supplémentaires sur chaque ligne d'un fichier, notamment la date de dernière modification, l'auteur et le hash du commit.

## Afficher le blame d'un fichier {#view-blame-for-a-file}

{{< history >}}

- L'affichage du blame directement dans la vue du fichier a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/430950) dans GitLab 16.7 [avec l'indicateur](../../../../administration/feature_flags/_index.md) nommé `inline_blame`. Désactivée par défaut.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/501539) dans GitLab 19.1.

{{< /history >}}

Prérequis :

- Le fichier doit contenir du contenu textuel lisible. L'interface GitLab affiche les résultats de `git blame` pour les fichiers texte tels que `.rb`, `.js`, `.md`, `.txt`, `.yml` et les formats similaires. Les fichiers binaires, tels que les images et les PDF, ne sont pas pris en charge.

Pour afficher le blame d'un fichier :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Dépôt**.
1. Sélectionnez le fichier que vous souhaitez examiner.
1. L'une ou l'autre des options :
   - Pour changer la vue du fichier actuel, dans l'en-tête du fichier, sélectionnez **Blame**.
   - Pour ouvrir la page de blame complète, dans le coin supérieur droit, sélectionnez **Blame**.
1. Accédez à la ligne que vous souhaitez voir.

Lorsque vous sélectionnez **Blame**, ces informations s'affichent :

![Sortie Git blame](img/file_blame_output_v18_11.png "Sortie du bouton Blame")

Pour voir la date et l'heure précises du commit, survolez la date. Pour afficher une légende de couleurs pour l'ancienneté des commits, consultez [Afficher la légende des indicateurs d'ancienneté](#show-age-indicator-legend).

### Blame du commit précédent {#blame-previous-commit}

Pour voir les révisions antérieures d'une ligne spécifique :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et accédez à votre projet.
1. Dans la barre latérale gauche, sélectionnez **Code** > **Dépôt**.
1. Sélectionnez le fichier que vous souhaitez examiner.
1. Dans le coin supérieur droit, sélectionnez **Blame** et accédez à la ligne que vous souhaitez voir.
1. Sélectionnez **Voir le blame antérieur à cette modification** ({{< icon name="doc-versions" >}}) jusqu'à ce que vous ayez trouvé les modifications que vous souhaitez consulter.

### Ignorer des révisions spécifiques {#ignore-specific-revisions}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/514684) dans GitLab 17.10 [avec un flag](../../../../administration/feature_flags/_index.md) nommé `blame_ignore_revs`. Désactivée par défaut.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/514325) dans GitLab 17.10.
- [Disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/issues/525095) dans GitLab 17.11. L'indicateur de fonctionnalité `blame_ignore_revs` a été supprimé.

{{< /history >}}

Pour configurer Git blame afin d'ignorer des révisions spécifiques :

1. À la racine de votre dépôt, créez un fichier `.git-blame-ignore-revs`.
1. Ajoutez les hashes de commit que vous souhaitez ignorer, un par ligne. Par exemple :

   ```plaintext
   a24cb33c0e1390b0719e9d9a4a4fc0e4a3a069cc
   676c1c7e8b9e2c9c93e4d5266c6f3a50ad602a4c
   ```

1. Ouvrez un fichier dans la vue blame.
1. Sélectionnez **Préférences de blâme** ({{< icon name="preferences" >}}).
1. Cochez la case **Ignorer des révisions spécifiques**.

La vue blame s'actualise et ignore les révisions spécifiées dans le fichier `.git-blame-ignore-revs`, affichant à la place les modifications significatives précédentes.

### Afficher la légende des indicateurs d'ancienneté {#show-age-indicator-legend}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/589722) dans GitLab 18.11.

{{< /history >}}

Dans la vue blame intégrée, vous pouvez afficher ou masquer la légende des indicateurs d'ancienneté. La légende affiche une échelle de couleurs allant de **Plus récent** à **Moins récent** pour vous aider à interpréter l'ancienneté de chaque commit.

Pour afficher ou masquer la légende des indicateurs d'ancienneté :

1. Ouvrez un fichier dans la vue blame.
1. Sélectionnez **Préférences de blâme** ({{< icon name="preferences" >}}).
1. Cochez ou décochez la case **Afficher la légende des indicateurs d'ancienneté**.

## Sujets connexes {#related-topics}

- [API REST de blame de fichiers Git](../../../../api/repository_files.md#retrieve-file-blame-history-from-a-repository)
- [Commandes Git courantes](../../../../topics/git/commands.md)
- [Gestion des fichiers avec Git](../../../../topics/git/file_management.md)
- [Navigateur d'arborescence de fichiers](file_tree_browser.md)
