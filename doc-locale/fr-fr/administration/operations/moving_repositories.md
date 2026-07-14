---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Déplacer des dépôts gérés par GitLab
description: "Déplacer des projets, des extraits de code et des groupes entre des serveurs et des stockages."
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Déplacer tous les dépôts gérés par GitLab vers un autre système de fichiers ou un autre serveur.

## Déplacer des données dans une instance GitLab {#move-data-in-a-gitlab-instance}

Utiliser l'API GitLab pour déplacer des dépôts Git :

- Entre des serveurs.
- Entre différents stockages.
- D'un Gitaly à nœud unique vers un cluster Gitaly (Praefect).

Les dépôts GitLab peuvent être associés à des projets, des groupes et des extraits de code. Chacun de ces types dispose d'une API distincte pour déplacer les dépôts. Pour déplacer tous les dépôts d'une instance GitLab, chaque type de dépôt doit être déplacé pour chaque stockage.

Chaque dépôt est mis en lecture seule pendant la durée du déplacement et n'est pas accessible en écriture tant que le déplacement n'est pas terminé.

Pour déplacer des dépôts :

1. Vérifiez que tous les [stockages locaux et de cluster](../gitaly/configure_gitaly.md#mixed-configuration) sont accessibles à l'instance GitLab. Dans cet exemple, il s'agit de `<original_storage_name>` et `<cluster_storage_name>`.
1. [Configurez les pondérations de stockage des dépôts](../repository_storage_paths.md#configure-where-new-repositories-are-stored) afin que les nouveaux stockages reçoivent tous les nouveaux projets. Cela empêche la création de nouveaux projets sur les stockages existants pendant la migration.
1. Planifiez les déplacements de dépôts pour les projets, les extraits de code et les groupes.
1. Si vous utilisez [Geo](../geo/_index.md), [resynchronisez tous les dépôts](../geo/replication/troubleshooting/synchronization_verification.md#resync-resources-for-the-selected-component).
1. Lorsque vous utilisez Horizontal Pod Autoscaler sur des pods Sidekiq, [désactivez HPA pour les pods Sidekiq](https://docs.gitlab.com/charts/gitlab/sidekiq/#disable-hpa-scaling) afin d'éviter toute mise à l'échelle pendant la migration.

### Déplacer des projets {#move-projects}

Vous pouvez déplacer tous les projets ou des projets individuels.

Pour déplacer tous les projets à l'aide de l'API :

1. [Planifiez des déplacements de stockage de dépôt pour tous les projets sur un fragment de stockage](../../api/project_repository_storage_moves.md#create-repository-storage-moves-for-all-projects-on-a-storage-shard) à l'aide de l'API. Par exemple :

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/project_repository_storage_moves"
   ```

1. [Interrogez les déplacements de dépôt les plus récents](../../api/project_repository_storage_moves.md#list-all-project-repository-storage-moves) à l'aide de l'API. La réponse indique soit :
   - Les déplacements se sont terminés avec succès. Le champ `state` est `finished`.
   - Les déplacements sont en cours. Réinterrogez le déplacement du dépôt jusqu'à ce qu'il se termine avec succès.
   - Les déplacements ont échoué. La plupart des échecs sont temporaires et peuvent être résolus en replanifiant le déplacement.

1. Une fois les déplacements terminés, utilisez l'API pour [interroger les projets](../../api/projects.md#list-all-projects) et confirmer que tous les projets ont été déplacés. Aucun des projets ne doit être retourné avec le champ `repository_storage` défini sur l'ancien stockage. Par exemple :

   ```shell
   curl --header "PRIVATE-TOKEN: <your_access_token>" --header "Content-Type: application/json" \
   "https://gitlab.example.com/api/v4/projects?repository_storage=<original_storage_name>"
   ```

   Vous pouvez également utiliser la console Rails pour confirmer que tous les projets ont été déplacés :

   ```ruby
   ProjectRepository.for_repository_storage('<original_storage_name>')
   ```

1. Répétez l'opération pour chaque stockage si nécessaire.

Si vous ne souhaitez pas déplacer tous les projets, suivez les instructions pour [déplacer des projets individuels](../../api/project_repository_storage_moves.md#create-a-repository-storage-move-for-a-project).

### Déplacer des extraits de code {#move-snippets}

Vous pouvez déplacer tous les extraits de code ou des extraits de code individuels.

Pour déplacer tous les extraits de code à l'aide de l'API :

1. [Planifiez des déplacements de stockage de dépôt pour tous les extraits de code sur un fragment de stockage](../../api/snippet_repository_storage_moves.md#schedule-repository-storage-moves-for-all-snippets-on-a-storage-shard). Par exemple :

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/snippet_repository_storage_moves"
   ```

1. [Interrogez les déplacements de dépôt les plus récents](../../api/snippet_repository_storage_moves.md#list-all-snippet-repository-storage-moves). La réponse indique soit :
   - Les déplacements se sont terminés avec succès. Le champ `state` est `finished`.
   - Les déplacements sont en cours. Réinterrogez le déplacement du dépôt jusqu'à ce qu'il se termine avec succès.
   - Les déplacements ont échoué. La plupart des échecs sont temporaires et peuvent être résolus en replanifiant le déplacement.

1. Une fois les déplacements terminés, utilisez la console Rails pour confirmer que tous les extraits de code ont été déplacés :

   ```ruby
   SnippetRepository.for_repository_storage('<original_storage_name>')
   ```

   La commande ne doit pas retourner d'extraits de code pour le stockage d'origine.

1. Répétez l'opération pour chaque stockage si nécessaire.

Si vous ne souhaitez pas déplacer tous les extraits de code, suivez les instructions pour les [extraits de code individuels](../../api/snippet_repository_storage_moves.md#schedule-a-repository-storage-move-for-a-snippet).

### Déplacer des groupes {#move-groups}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez déplacer tous les groupes ou des groupes individuels.

Pour déplacer tous les groupes à l'aide de l'API :

1. [Planifiez des déplacements de stockage de dépôt pour tous les groupes sur un fragment de stockage](../../api/group_repository_storage_moves.md#create-group-repository-storage-moves-for-a-storage-shard). Par exemple :

   ```shell
   curl --request POST --header "PRIVATE-TOKEN: <your_access_token>" \
        --header "Content-Type: application/json" \
        --data '{"source_storage_name":"<original_storage_name>","destination_storage_name":"<cluster_storage_name>"}' \
        "https://gitlab.example.com/api/v4/group_repository_storage_moves"
   ```

1. [Interrogez les déplacements de dépôt les plus récents](../../api/group_repository_storage_moves.md#list-all-group-repository-storage-moves). La réponse indique soit :
   - Les déplacements se sont terminés avec succès. Le champ `state` est `finished`.
   - Les déplacements sont en cours. Réinterrogez le déplacement du dépôt jusqu'à ce qu'il se termine avec succès.
   - Les déplacements ont échoué. La plupart des échecs sont temporaires et peuvent être résolus en replanifiant le déplacement.

1. Une fois les déplacements terminés, utilisez la console Rails pour confirmer que tous les groupes ont été déplacés :

   ```ruby
   GroupWikiRepository.for_repository_storage('<original_storage_name>')
   ```

   La commande ne doit pas retourner de groupes pour le stockage d'origine.

1. Répétez l'opération pour chaque stockage si nécessaire.

Si vous ne souhaitez pas déplacer tous les groupes, suivez les instructions pour les [groupes individuels](../../api/group_repository_storage_moves.md#create-a-group-repository-storage-move).

## Migrer vers une autre instance GitLab {#migrate-to-another-gitlab-instance}

Vous ne pouvez pas [déplacer des données à l'aide de l'API](#move-data-in-a-gitlab-instance) si vous migrez vers un nouvel environnement GitLab. Par exemple :

- D'un GitLab à nœud unique vers une architecture mise à l'échelle.
- D'une instance GitLab dans votre centre de données privé vers un fournisseur cloud.

Dans ce cas, il existe des moyens de copier tous vos dépôts de `/var/opt/gitlab/git-data/repositories` vers `/mnt/gitlab/repositories` selon le scénario :

- Le répertoire cible est vide.
- Le répertoire cible contient une copie obsolète des dépôts.
- Lorsque vous avez des milliers de dépôts.

> [!warning]
> Chacune des approches peut ou va écraser des données dans le répertoire cible `/mnt/gitlab/repositories`. Vous devez spécifier correctement la source et la cible.

### Utiliser la sauvegarde et la restauration (recommandé) {#use-backup-and-restore-recommended}

Pour les cibles Gitaly ou Gitaly Cluster (Praefect), vous devez utiliser la [fonctionnalité de sauvegarde et de restauration](../backup_restore/_index.md) de GitLab. Les dépôts Git sont accessibles, gérés et stockés sur les serveurs GitLab par Gitaly en tant que base de données. Vous pouvez subir une perte de données si vous accédez directement aux fichiers Gitaly et les copiez à l'aide d'outils tels que `rsync`. Vous pouvez :

- Améliorer les performances de sauvegarde en [traitant plusieurs dépôts simultanément](../backup_restore/backup_gitlab.md#back-up-git-repositories-concurrently).
- Créer des sauvegardes uniquement des dépôts à l'aide de la [fonctionnalité d'exclusion](../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup).

Vous devez utiliser la méthode de sauvegarde et de restauration pour les cibles Gitaly Cluster (Praefect).

### Utiliser `tar` {#use-tar}

Vous pouvez utiliser un tube `tar` pour déplacer des dépôts si :

- Vous spécifiez des cibles Gitaly et non des cibles Gitaly Cluster.
- Le répertoire cible `/mnt/gitlab/repositories` est vide.

Cette méthode a une faible surcharge et `tar` est généralement préinstallé sur votre système. Cependant, vous ne pouvez pas reprendre un tube `tar` interrompu. Si `tar` est interrompu, vous devez vider le répertoire cible et copier à nouveau toutes les données.

Pour voir la progression du processus `tar`, remplacez `-xf` par `-xvf`.

```shell
sudo -u git sh -c 'tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  tar -C /mnt/gitlab/repositories -xf -'
```

#### Utiliser un tube `tar` vers un autre serveur {#use-a-tar-pipe-to-another-server}

Pour les cibles Gitaly, vous pouvez utiliser un tube `tar` pour copier des données vers un autre serveur. Si votre utilisateur `git` dispose d'un accès SSH au nouveau serveur en tant que `git@<newserver>`, vous pouvez transmettre les données via SSH.

Si vous souhaitez compresser les données avant qu'elles ne transitent par le réseau (ce qui augmente l'utilisation du CPU), vous pouvez remplacer `ssh` par `ssh -C`.

```shell
sudo -u git sh -c 'tar -C /var/opt/gitlab/git-data/repositories -cf - -- . |\
  ssh git@newserver tar -C /mnt/gitlab/repositories -xf -'
```

### Utiliser `rsync` {#use-rsync}

Vous pouvez utiliser `rsync` pour déplacer des dépôts si :

- Vous spécifiez des cibles Gitaly et non des cibles Gitaly Cluster.
- Le répertoire cible contient déjà une copie partielle ou obsolète des dépôts, ce qui signifie que copier à nouveau toutes les données avec `tar` est inefficace.

> [!warning]
> Vous devez utiliser l'option `--delete` lors de l'utilisation de `rsync`. L'utilisation de `rsync` sans `--delete` peut entraîner une perte de données et une corruption du dépôt. Pour plus d'informations, consultez [le ticket 270422](https://gitlab.com/gitlab-org/gitlab/-/issues/270422).

Le `/.` dans la commande suivante est très important, sinon vous pouvez obtenir une structure de répertoire incorrecte dans le répertoire cible. Si vous souhaitez voir la progression, remplacez `-a` par `-av`.

```shell
sudo -u git  sh -c 'rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  /mnt/gitlab/repositories'
```

#### Utiliser `rsync` vers un autre serveur {#use-rsync-to-another-server}

Pour les cibles Gitaly, vous pouvez envoyer les dépôts sur le réseau avec `rsync` si l'utilisateur `git` sur votre système source dispose d'un accès SSH au serveur cible.

```shell
sudo -u git sh -c 'rsync -a --delete /var/opt/gitlab/git-data/repositories/. \
  git@newserver:/mnt/gitlab/repositories'
```

## Sujets connexes {#related-topics}

- [Configurer Gitaly](../gitaly/configure_gitaly.md)
- [Cluster Gitaly (Praefect)](../gitaly/praefect/_index.md)
- [API des déplacements de stockage de dépôt de projet](../../api/project_repository_storage_moves.md)
- [API des déplacements de stockage de dépôt de groupe](../../api/group_repository_storage_moves.md)
- [API des déplacements de stockage de dépôt d'extrait de code](../../api/snippet_repository_storage_moves.md)
