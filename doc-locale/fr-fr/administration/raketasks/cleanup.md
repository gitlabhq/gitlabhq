---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tâches Rake de nettoyage
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab fournit des tâches Rake pour nettoyer les instances GitLab.

## Supprimer les fichiers LFS non référencés {#remove-unreferenced-lfs-files}

> [!warning]
> N'exécutez pas cette opération dans les 12 heures suivant une mise à niveau de GitLab. Cela permet de s'assurer que toutes les migrations en arrière-plan sont terminées, faute de quoi des pertes de données pourraient survenir.

Lorsque vous supprimez des fichiers LFS de l'historique d'un dépôt, ils deviennent orphelins et continuent à consommer de l'espace disque. Avec cette tâche Rake, vous pouvez supprimer les références invalides de la base de données, ce qui permet la collecte des déchets des fichiers LFS. Par exemple :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:cleanup:orphan_lfs_file_references PROJECT_PATH="gitlab-org/gitlab-foss"
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
bundle exec rake gitlab:cleanup:orphan_lfs_file_references RAILS_ENV=production PROJECT_PATH="gitlab-org/gitlab-foss"
```

{{< /tab >}}

{{< /tabs >}}

Vous pouvez également spécifier le projet avec `PROJECT_ID` au lieu de `PROJECT_PATH`.

Par exemple :

```shell
$ sudo gitlab-rake gitlab:cleanup:orphan_lfs_file_references PROJECT_ID="13083"

I, [2019-12-13T16:35:31.764962 #82356]  INFO -- :  Looking for orphan LFS files for project GitLab Org / GitLab Foss
I, [2019-12-13T16:35:31.923659 #82356]  INFO -- :  Removed invalid references: 12
```

Par défaut, cette tâche ne supprime rien mais indique le nombre de références de fichiers qu'elle peut supprimer. Exécutez la commande avec `DRY_RUN=false` si vous souhaitez réellement supprimer les références. Vous pouvez également utiliser le paramètre `LIMIT={number}` pour limiter le nombre de références supprimées.

Cette tâche Rake supprime uniquement les références aux fichiers LFS. Les fichiers LFS non référencés sont collectés comme déchets ultérieurement (une fois par jour). Si vous avez besoin de les collecter immédiatement, exécutez `rake gitlab:cleanup:orphan_lfs_files` décrit ci-dessous.

### Supprimer immédiatement les fichiers LFS non référencés {#remove-unreferenced-lfs-files-immediately}

Les fichiers LFS non référencés sont supprimés quotidiennement, mais vous pouvez les supprimer immédiatement si nécessaire. Pour supprimer immédiatement les fichiers LFS non référencés :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:cleanup:orphan_lfs_files
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
bundle exec rake gitlab:cleanup:orphan_lfs_files
```

{{< /tab >}}

{{< /tabs >}}

Exemple de sortie :

```shell
$ sudo gitlab-rake gitlab:cleanup:orphan_lfs_files
I, [2020-01-08T20:51:17.148765 #43765]  INFO -- : Removed unreferenced LFS files: 12
```

## Nettoyer les fichiers d'upload de projets {#clean-up-project-upload-files}

Nettoyez les fichiers d'upload de projets s'ils n'existent pas dans la base de données GitLab.

### Nettoyer les fichiers d'upload de projets depuis le système de fichiers {#clean-up-project-upload-files-from-file-system}

Nettoyez les fichiers d'upload de projets locaux s'ils n'existent pas dans la base de données GitLab. La tâche tente de corriger le fichier si elle peut trouver son projet, sinon elle déplace le fichier vers un répertoire des objets perdus et trouvés. Pour nettoyer les fichiers d'upload de projets depuis le système de fichiers :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:cleanup:project_uploads
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
bundle exec rake gitlab:cleanup:project_uploads RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

Exemple de sortie :

```shell
$ sudo gitlab-rake gitlab:cleanup:project_uploads

I, [2018-07-27T12:08:27.671559 #89817]  INFO -- : Looking for orphaned project uploads to clean up. Dry run...
D, [2018-07-27T12:08:28.293568 #89817] DEBUG -- : Processing batch of 500 project upload file paths, starting with /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out
I, [2018-07-27T12:08:28.689869 #89817]  INFO -- : Can move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/test.out
I, [2018-07-27T12:08:28.755624 #89817]  INFO -- : Can fix /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/qux/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt
I, [2018-07-27T12:08:28.760257 #89817]  INFO -- : Can move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png
I, [2018-07-27T12:08:28.764470 #89817]  INFO -- : To cleanup these files run this command with DRY_RUN=false

$ sudo gitlab-rake gitlab:cleanup:project_uploads DRY_RUN=false
I, [2018-07-27T12:08:32.944414 #89936]  INFO -- : Looking for orphaned project uploads to clean up...
D, [2018-07-27T12:08:33.293568 #89817] DEBUG -- : Processing batch of 500 project upload file paths, starting with /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out
I, [2018-07-27T12:08:33.689869 #89817]  INFO -- : Did move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/test.out -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/test.out
I, [2018-07-27T12:08:33.755624 #89817]  INFO -- : Did fix /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/qux/foo/bar/89a0f7b0b97008a4a18cedccfdcd93fb/foo.txt
I, [2018-07-27T12:08:33.760257 #89817]  INFO -- : Did move to lost and found /opt/gitlab/embedded/service/gitlab-rails/public/uploads/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png -> /opt/gitlab/embedded/service/gitlab-rails/public/uploads/-/project-lost-found/foo/bar/1dd6f0f7eefd2acc4c2233f89a0f7b0b/image.png
```

Si vous utilisez un stockage d'objets, exécutez la [tâche Rake tout-en-un](uploads/migrate.md#all-in-one-rake-task) pour vous assurer que tous les uploads sont migrés vers le stockage d'objets et qu'il n'y a aucun fichier sur le disque dans le dossier des uploads.

### Nettoyer les fichiers d'upload de projets depuis le stockage d'objets {#clean-up-project-upload-files-from-object-storage}

Déplacez les fichiers d'upload du stockage d'objets vers un répertoire des objets perdus et trouvés s'ils n'existent pas dans la base de données GitLab. Pour nettoyer les fichiers d'upload de projets depuis le stockage d'objets :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:cleanup:remote_upload_files
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
bundle exec rake gitlab:cleanup:remote_upload_files RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

Exemple de sortie :

```shell
$ sudo gitlab-rake gitlab:cleanup:remote_upload_files

I, [2018-08-02T10:26:13.995978 #45011]  INFO -- : Looking for orphaned remote uploads to remove. Dry run...
I, [2018-08-02T10:26:14.120400 #45011]  INFO -- : Can be moved to lost and found: @hashed/6b/DSC_6152.JPG
I, [2018-08-02T10:26:14.120482 #45011]  INFO -- : Can be moved to lost and found: @hashed/79/02/7902699be42c8a8e46fbbb4501726517e86b22c56a189f7625a6da49081b2451/711491b29d3eb08837798c4909e2aa4d/DSC00314.jpg
I, [2018-08-02T10:26:14.120634 #45011]  INFO -- : To cleanup these files run this command with DRY_RUN=false
```

```shell
$ sudo gitlab-rake gitlab:cleanup:remote_upload_files DRY_RUN=false

I, [2018-08-02T10:26:47.598424 #45087]  INFO -- : Looking for orphaned remote uploads to remove...
I, [2018-08-02T10:26:47.753131 #45087]  INFO -- : Moved to lost and found: @hashed/6b/DSC_6152.JPG -> lost_and_found/@hashed/6b/DSC_6152.JPG
I, [2018-08-02T10:26:47.764356 #45087]  INFO -- : Moved to lost and found: @hashed/79/02/7902699be42c8a8e46fbbb4501726517e86b22c56a189f7625a6da49081b2451/711491b29d3eb08837798c4909e2aa4d/DSC00314.jpg -> lost_and_found/@hashed/79/02/7902699be42c8a8e46fbbb4501726517e86b22c56a189f7625a6da49081b2451/711491b29d3eb08837798c4909e2aa4d/DSC00314.jpg
```

## Supprimer les fichiers d'artefacts orphelins {#remove-orphan-artifact-files}

> [!note]
> Ces commandes ne fonctionnent pas pour les artefacts stockés sur le [stockage d'objets](../object_storage.md).

Lorsque vous constatez qu'il y a plus de fichiers d'artefacts de job et/ou de répertoires sur le disque qu'il ne devrait y en avoir, vous pouvez exécuter :

```shell
sudo gitlab-rake gitlab:cleanup:orphan_job_artifact_files
```

Cette commande :

- Analyse l'intégralité du dossier des artefacts.
- Vérifie quels fichiers ont encore un enregistrement dans la base de données.
- Si aucun enregistrement de base de données n'est trouvé, le fichier et le répertoire sont supprimés du disque.

Par défaut, cette tâche ne supprime rien mais indique ce qu'elle peut supprimer. Exécutez la commande avec `DRY_RUN=false` si vous souhaitez réellement supprimer les fichiers :

```shell
sudo gitlab-rake gitlab:cleanup:orphan_job_artifact_files DRY_RUN=false
```

Vous pouvez également limiter le nombre de fichiers à supprimer avec `LIMIT` (par défaut `100`) :

```shell
sudo gitlab-rake gitlab:cleanup:orphan_job_artifact_files LIMIT=100
```

Cela supprime uniquement jusqu'à 100 fichiers du disque. Vous pouvez utiliser cette option pour supprimer un petit ensemble à des fins de test.

Fournir `DEBUG=1` affiche le chemin complet de chaque fichier détecté comme étant un orphelin.

Si `ionice` est installé, la tâche l'utilise pour s'assurer que la commande ne génère pas une charge trop importante sur le disque. Vous pouvez configurer le niveau de priorité avec `NICENESS`. Voici les niveaux valides, mais consultez `man 1 ionice` pour en être sûr.

- `0` ou `None`
- `1` ou `Realtime`
- `2` ou `Best-effort` (par défaut)
- `3` ou `Idle`

## Supprimer les clés de recherche ActiveSession expirées {#remove-expired-activesession-lookup-keys}

Pour supprimer les clés de recherche ActiveSession expirées :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-rake gitlab:cleanup:sessions:active_sessions_lookup_keys
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
bundle exec rake gitlab:cleanup:sessions:active_sessions_lookup_keys RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

## Collecte des déchets du registre de conteneurs {#container-registry-garbage-collection}

Le registre de conteneurs peut utiliser des quantités considérables d'espace disque. Pour libérer les couches inutilisées, le registre inclut une [commande de collecte des déchets](../packages/container_registry.md#container-registry-garbage-collection).
