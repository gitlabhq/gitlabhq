---
stage: GitLab Delivery
group: Build
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Mise en miroir des dépôts de packages Linux GitLab
title: Mise en miroir des dépôts de packages Linux
---

Les packages Linux de GitLab et de GitLab Runner sont disponibles à l'adresse <https://packages.gitlab.com>. Ce document explique comment maintenir un miroir local de ces dépôts.

## Mise en miroir des dépôts APT {#mirroring-apt-repositories}

Un miroir local d'un dépôt `apt` peut être créé à l'aide de l'outil `apt-mirror`.

1. Installer `apt-mirror`

   ```shell
   sudo apt install apt-mirror
   ```

1. Créer un répertoire pour le miroir

   ```shell
   sudo mkdir /srv/gitlab-repo-mirror
   ```

1. Ajoutez les lignes suivantes au fichier de configuration `apt-mirror` présent à l'emplacement `/etc/apt/mirror.list`

   ```shell
   set base_path /srv/gitlab-repo-mirror
   ```

   Le contenu mis en miroir est écrit sous `/srv/gitlab-repo-mirror/mirror/packages.gitlab.com`.

   Consultez le [fichier de configuration exemple en amont](https://github.com/apt-mirror/apt-mirror/blob/master/mirror.list) pour d'autres paramètres disponibles.

1. À la fin du fichier de configuration, spécifiez les dépôts à mettre en miroir au format URL du fichier sources `apt`.

   > [!note]
   > La structure du dépôt diffère entre GitLab et GitLab Runner.
   >
   > ### GitLab {#gitlab}
   >
   > GitLab utilise les mêmes chaînes de version pour les packages sur toutes les distributions de système d'exploitation (avec un contenu différent). Cela signifie que ces packages sont considérés comme des [packages en double selon le format de dépôt Debian](https://wiki.debian.org/DebianRepository/Format#Duplicate_Packages).
   >
   > Pour contourner ce problème, chaque distribution de système d'exploitation (comme Debian Trixie ou Ubuntu Focal) dispose d'un dépôt dédié qui héberge uniquement cette distribution. Cela se traduit par des URL comportant un composant de distribution supplémentaire.
   >
   > ### GitLab Runner {#gitlab-runner}
   >
   > GitLab Runner est un binaire Go lié statiquement et utilise le même package pour différentes distributions de système d'exploitation. Il utilise un seul dépôt apt par système d'exploitation et héberge toutes les distributions de ce système d'exploitation au sein de ce dépôt.

   {{< tabs >}}

   {{< tab title="GitLab" >}}

   ```plaintext
   deb https://packages.gitlab.com/gitlab/gitlab-ee/debian/trixie trixie main
   deb-src https://packages.gitlab.com/gitlab/gitlab-ee/debian/trixie trixie main
   ```

   {{< /tab >}}

   {{< tab title="GitLab Runner" >}}

   ```plaintext
   deb https://packages.gitlab.com/runner/gitlab-runner/debian trixie main
   deb-src https://packages.gitlab.com/runner/gitlab-runner/debian trixie main
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. Démarrer le processus de mise en miroir

   ```shell
   sudo apt-mirror
   ```

## Mise en miroir des dépôts RPM {#mirroring-rpm-repositories}

Un miroir local d'un dépôt `rpm` peut être créé à l'aide de `reposync` (pour télécharger les packages) et de `createrepo` (pour générer les métadonnées).

> [!note]
> `reposync` s'attend à ce que le dépôt que vous souhaitez mettre en miroir soit installé sur le système. Suivez [la documentation d'installation](package/_index.md#supported-platforms) pour le dépôt que vous souhaitez mettre en miroir.
>
> Pour trouver l'ID du dépôt, listez les dépôts disponibles avec :
>
> ```shell
> yum repolist
> ```

1. Installer `createrepo` et `reposync`

   ```shell
   sudo yum install createrepo yum-utils
   ```

1. Créer un répertoire pour le miroir

   ```shell
   sudo mkdir /srv/gitlab-repo-mirror
   ```

1. Exécutez `reposync`. Transmettez l'ID du dépôt et le répertoire de sortie en tant qu'arguments.

   ```shell
   reposync --repoid=gitlab_gitlab-ee --download-path=/srv/gitlab-repo-mirror
   ```

1. Générer les métadonnées du dépôt à l'aide de `createrepo`

   ```shell
   createrepo -o /srv/gitlab-repo-mirror /srv/gitlab-repo-mirror
   ```
