---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sauvegarder GitLab
description: Sauvegardez votre instance GitLab auto-géré.
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les sauvegardes GitLab protègent vos données et facilitent la reprise après sinistre.

La stratégie de sauvegarde optimale dépend de la configuration de votre déploiement GitLab, du volume de données et des emplacements de stockage. Ces facteurs déterminent les méthodes de sauvegarde à utiliser, où stocker les sauvegardes et comment structurer votre planning de sauvegarde.

Pour les instances GitLab plus importantes, les stratégies de sauvegarde alternatives incluent :

- Les sauvegardes incrémentielles.
- Les sauvegardes de dépôts spécifiques.
- Les sauvegardes sur plusieurs emplacements de stockage.

## Données incluses dans une sauvegarde {#data-included-in-a-backup}

{{< history >}}

- Les fichiers sécurisés [ont été introduits](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121142) dans GitLab 16.1.
- Les diffs de merge request externes [ont été introduits](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154914) dans GitLab 17.1.

{{< /history >}}

GitLab fournit une interface de ligne de commande pour sauvegarder l'intégralité de votre instance. Par défaut, la sauvegarde crée une archive dans un seul fichier tar compressé. Ce fichier comprend :

- Données et configuration de la base de données
- Paramètres de compte et de groupe
- Artefacts CI/CD et job logs
- Dépôts Git et objets LFS
- Diffs de merge request externes
- Données du registre de paquets et images du registre de conteneurs
- Wikis de projet et de groupe
- Pièces jointes et téléversements au niveau du projet
- Fichiers sécurisés
- Contenu GitLab Pages
- États Terraform
- Extraits de code

## Données non incluses dans une sauvegarde {#data-not-included-in-a-backup}

> [!warning]
> Il est fortement conseillé de lire la section sur le [stockage des fichiers de configuration](#storing-configuration-files) pour les sauvegarder séparément.

- [Données Mattermost](../../integration/mattermost/_index.md#back-up-gitlab-mattermost)
- Redis (et donc les jobs Sidekiq)
- [Stockage d'objets](#object-storage) sur les installations Linux package (Omnibus) / Docker / auto-compilées
- [Hooks de serveur globaux](../server_hooks.md#create-global-server-hooks-for-all-repositories)
- [Hooks de fichiers](../file_hooks.md)
- Fichiers de configuration GitLab (`/etc/gitlab`)
- Clés et certificats liés à TLS et SSH
- Autres fichiers système

## Procédure de sauvegarde simple {#simple-backup-procedure}

À titre indicatif, si vous utilisez une architecture de référence 1k avec moins de 100 Go de données, suivez ces étapes :

1. Exécutez la commande de sauvegarde.
1. Sauvegardez le stockage d'objets, si applicable.
1. Sauvegardez manuellement les fichiers de configuration système.

Voir aussi :

- [Architecture de référence 1k](../reference_architectures/1k_users.md)
- [Détails de la commande de sauvegarde](#backup-command)
- [Configuration du stockage d'objets](#object-storage)
- [Guide des fichiers de configuration](#storing-configuration-files)

## Mise à l'échelle des sauvegardes {#scaling-backups}

À mesure que le volume de données GitLab augmente, la commande de sauvegarde prend plus de temps à s'exécuter. Les options de sauvegarde telles que la sauvegarde simultanée des dépôts Git et les sauvegardes incrémentielles de dépôts peuvent aider à réduire le temps d'exécution. À un certain stade, la commande de sauvegarde devient impraticable par elle-même. Par exemple, cela peut prendre 24 heures ou plus.

À partir de GitLab 18.0, les performances de sauvegarde des dépôts ont été considérablement améliorées pour les dépôts comportant un grand nombre de références (branches, tags). Cette amélioration peut réduire les temps de sauvegarde de plusieurs heures à quelques minutes pour les dépôts concernés. Aucune modification de configuration n'est requise pour bénéficier de cette amélioration.

Dans certains cas, des modifications architecturales peuvent être nécessaires pour permettre la mise à l'échelle des sauvegardes.

Pour aller plus loin :

- [Sauvegardes incrémentielles de dépôts](#incremental-repository-backups).
- [Sauvegarder les dépôts Git simultanément](#back-up-git-repositories-concurrently).
- [Sauvegarder et restaurer les architectures de référence volumineuses](backup_large_reference_architectures.md).
- [Stratégies de sauvegarde alternatives](#alternative-backup-strategies).
- [Article de blog sur la réduction des temps de sauvegarde des dépôts GitLab](https://about.gitlab.com/blog/how-we-decreased-gitlab-repo-backup-times-from-48-hours-to-41-minutes/).

## Quelles données doivent être sauvegardées ? {#what-data-needs-to-be-backed-up}

Les données suivantes doivent être sauvegardées.

### Bases de données PostgreSQL {#postgresql-databases}

Dans le cas le plus simple, GitLab dispose d'une seule base de données PostgreSQL sur un serveur PostgreSQL sur la même VM que tous les autres services GitLab. Mais selon la configuration, GitLab peut utiliser plusieurs bases de données PostgreSQL sur plusieurs serveurs PostgreSQL.

En général, ces données constituent la source unique de vérité pour la plupart des contenus générés par les utilisateurs dans l'interface Web, tels que le contenu des tickets et des merge requests, les commentaires, les autorisations et les identifiants.

PostgreSQL contient également des données mises en cache comme le Markdown rendu en HTML, et par défaut, les diffs de merge request. Cependant, les diffs de merge request peuvent également être configurés pour être [déchargés](#blobs) vers le système de fichiers ou le stockage d'objets.

Gitaly Cluster (Praefect) utilise une base de données PostgreSQL comme source unique de vérité pour gérer ses nœuds Gitaly.

Un utilitaire PostgreSQL courant, [`pg_dump`](https://www.postgresql.org/docs/16/app-pgdump.html), produit un fichier de sauvegarde qui peut être utilisé pour restaurer une base de données PostgreSQL. La [commande de sauvegarde](#backup-command) utilise cet utilitaire en arrière-plan.

Malheureusement, plus la base de données est volumineuse, plus `pg_dump` prend de temps à s'exécuter. Selon votre situation, la durée devient impraticable à un certain stade (plusieurs jours, par exemple). Si votre base de données dépasse 100 Go, `pg_dump`, et par extension la [commande de sauvegarde](#backup-command), ne sera probablement pas utilisable. Pour plus d'informations, consultez les [stratégies de sauvegarde alternatives](#alternative-backup-strategies).

### Dépôts Git {#git-repositories}

Une instance GitLab peut avoir un ou plusieurs fragments de dépôt. Chaque fragment est une instance Gitaly ou un Gitaly Cluster (Praefect) responsable de l'accès et des opérations sur les dépôts Git stockés localement. Gitaly peut s'exécuter sur une machine :

- Avec un seul disque.
- Avec plusieurs disques montés comme un seul point de montage (comme avec un tableau RAID).
- En utilisant LVM.

Chaque projet peut avoir jusqu'à 3 dépôts différents :

- Un dépôt de projet, où le code source est stocké.
- Un dépôt wiki, où le contenu du wiki est stocké.
- Un dépôt de conception, où les artefacts de conception sont indexés (les assets sont en réalité dans LFS).

Ils résident tous dans le même fragment et partagent le même nom de base avec un suffixe `-wiki` et `-design` pour les cas de Wiki et de dépôt de conception.

Les extraits de code personnels et de projet, ainsi que le contenu du wiki de groupe, sont stockés dans des dépôts Git.

Les duplications de projet sont dédupliquées dans un site GitLab à l'aide de dépôts de pool.

La commande de sauvegarde produit un bundle Git pour chaque dépôt et les archive tous ensemble. Cela duplique les données du dépôt de pool dans chaque duplication. Lors de nos tests, 100 Go de dépôts Git ont nécessité un peu plus de 2 heures pour être sauvegardés et téléchargés sur S3. Avec environ 400 Go de données Git, la commande de sauvegarde n'est probablement pas viable pour des sauvegardes régulières. Pour plus d'informations, consultez les [stratégies de sauvegarde alternatives](#alternative-backup-strategies).

### Blobs {#blobs}

GitLab stocke les blobs (ou fichiers) tels que les pièces jointes aux tickets ou les objets LFS dans :

- Le système de fichiers à un emplacement spécifique.
- Une solution de [stockage d'objets](../object_storage.md). Les solutions de stockage d'objets peuvent être :
  - Basées sur le cloud comme Amazon S3 et Google Cloud Storage.
  - Stockage d'objets compatible S3 auto-hébergé.
  - Une appliance de stockage exposant une API compatible avec le stockage d'objets.

#### Stockage d'objets {#object-storage}

La commande de sauvegarde ne sauvegarde pas les blobs qui ne sont pas stockés sur le système de fichiers. Si vous utilisez le stockage d'objets, assurez-vous d'activer les sauvegardes auprès de votre fournisseur de stockage d'objets.

Guides de sauvegarde spécifiques aux fournisseurs :

- [Sauvegardes Amazon S3](https://docs.aws.amazon.com/aws-backup/latest/devguide/s3-backups.html)
- [Google Cloud Storage Transfer Service](https://cloud.google.com/storage-transfer-service)
- [Google Cloud Storage Object Versioning](https://cloud.google.com/storage/docs/object-versioning)

Voir aussi :

- [Détails de la commande de sauvegarde](#backup-command)
- [Configuration du stockage d'objets](../object_storage.md)

### Registre de conteneurs {#container-registry}

Le stockage du registre de conteneurs GitLab peut être configuré dans :

- Le système de fichiers à un emplacement spécifique.
- Une solution de stockage d'objets. Les solutions de stockage d'objets peuvent être :
  - Basées sur le cloud comme Amazon S3 et Google Cloud Storage.
  - Stockage d'objets compatible S3 auto-hébergé.
  - Une appliance de stockage exposant une API compatible avec le stockage d'objets.

La commande de sauvegarde ne sauvegarde pas les données du registre lorsqu'elles sont stockées dans le stockage d'objets.

#### Base de données de métadonnées {#metadata-database}

Si vous avez activé la [base de données de métadonnées du registre de conteneurs](https://docs.gitlab.com/charts/charts/registry/metadata_database), vous devez configurer l'accès à la base de données du registre pendant la sauvegarde. Suivez les instructions de votre installation GitLab pour configurer les identifiants requis :

- [Instructions pour le package Linux](https://docs.gitlab.com/omnibus/settings/backups/#container-registry-metadata-database-backup-credentials)
- [Chart GitLab Helm](https://docs.gitlab.com/charts/charts/gitlab/toolbox/#registry-metadata-database-credentials)

Voir aussi :

- [Registre de conteneurs GitLab](../packages/container_registry.md)
- [Configuration du stockage d'objets](../object_storage.md)

### Stockage des fichiers de configuration {#storing-configuration-files}

> [!warning]
> La tâche Rake de sauvegarde fournie par GitLab ne stocke pas vos fichiers de configuration. La raison principale est que votre base de données contient des éléments incluant des informations chiffrées pour l'authentification à deux facteurs et les variables sécurisées CI/CD. Stocker des informations chiffrées au même endroit que leur clé annule l'intérêt d'utiliser le chiffrement. Par exemple, le fichier secrets contient votre clé de chiffrement de base de données. Si vous le perdez, l'application GitLab ne pourra plus déchiffrer les valeurs chiffrées dans la base de données.
>
> De plus, le fichier secrets peut changer après les mises à niveau.

Vous devez sauvegarder le répertoire de configuration. Au minimum absolu, vous devez sauvegarder :

{{< tabs >}}

{{< tab title="Package Linux" >}}

- `/etc/gitlab/gitlab-secrets.json`
- `/etc/gitlab/gitlab.rb`

Pour plus d'informations, consultez [Sauvegarde et restauration de la configuration du package Linux (Omnibus)](https://docs.gitlab.com/omnibus/settings/backups/#backup-and-restore-omnibus-gitlab-configuration).

{{< /tab >}}

{{< tab title="Auto-compilé" >}}

- `/home/git/gitlab/config/secrets.yml`
- `/home/git/gitlab/config/gitlab.yml`

{{< /tab >}}

{{< tab title="Docker" >}}

- Sauvegardez le volume où sont stockés les fichiers de configuration. Si vous avez créé le conteneur GitLab selon la documentation, il devrait se trouver dans le répertoire `/srv/gitlab/config`.

{{< /tab >}}

{{< tab title="Chart GitLab Helm" >}}

- Suivez les instructions [Sauvegarder les secrets](https://docs.gitlab.com/charts/backup-restore/backup/#back-up-the-secrets).

{{< /tab >}}

{{< /tabs >}}

Vous pouvez également sauvegarder les clés et certificats TLS (`/etc/gitlab/ssl`, `/etc/gitlab/trusted-certs`), ainsi que vos [clés hôtes SSH](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079) pour éviter les avertissements d'attaque de l'homme du milieu si vous devez effectuer une restauration complète de la machine.

Dans le cas improbable où le fichier secrets est perdu, consultez [Lorsque le fichier secrets est perdu](troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost).

### Autres données {#other-data}

GitLab utilise Redis à la fois comme cache et pour stocker les données persistantes de notre système de jobs en arrière-plan, Sidekiq. La commande de sauvegarde fournie ne sauvegarde pas les données Redis. Cela signifie que pour effectuer une sauvegarde cohérente avec la commande de sauvegarde, il ne doit y avoir aucun job en attente ou en cours d'exécution en arrière-plan.

Elasticsearch est une base de données optionnelle pour la recherche avancée. Elle peut améliorer la recherche au niveau du code source et dans le contenu généré par les utilisateurs dans les tickets, les merge requests et les discussions. La commande de sauvegarde ne sauvegarde pas les données Elasticsearch. Les données Elasticsearch peuvent être régénérées à partir des données PostgreSQL après une restauration.

Options de sauvegarde manuelle :

- [Procédures de sauvegarde Redis](https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/#backing-up-redis-data)
- [Procédures de sauvegarde Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html)

Voir aussi : [Détails de la commande de sauvegarde](#backup-command).

### Conditions requises {#requirements}

Pour pouvoir sauvegarder et restaurer, assurez-vous que Rsync est installé sur votre système. Si vous avez installé GitLab :

- À l'aide du package Linux, Rsync est déjà installé.
- En utilisant la compilation manuelle, vérifiez si `rsync` est installé et installez-le si ce n'est pas le cas.

### Commande de sauvegarde {#backup-command}

- La commande de sauvegarde ne sauvegarde pas les éléments dans le stockage d'objets sur les installations Linux package (Omnibus) / Docker / auto-compilées.
- La commande de sauvegarde nécessite des paramètres supplémentaires lorsque votre installation utilise PgBouncer, pour des raisons de performances ou lors de son utilisation avec un cluster Patroni.
- Vous pouvez uniquement restaurer une sauvegarde vers exactement la même version et le même type (CE/EE) de GitLab sur lequel elle a été créée.

**Important considerations:**

- [Limitations du stockage d'objets](#object-storage)
- [Exigences de configuration PgBouncer](#back-up-and-restore-for-installations-using-pgbouncer)

Pour créer une sauvegarde :

{{< tabs >}}

{{< tab title="Package Linux (Omnibus)" >}}

```shell
sudo gitlab-backup create
```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

Exécutez la tâche de sauvegarde en utilisant `kubectl` pour exécuter le script `backup-utility` sur le pod toolbox GitLab. Pour plus de détails, consultez la [documentation de sauvegarde des charts](https://docs.gitlab.com/charts/backup-restore/backup/).

{{< /tab >}}

{{< tab title="Docker" >}}

Exécutez la sauvegarde depuis l'hôte.

```shell
docker exec -t <container name> gitlab-backup create
```

{{< /tab >}}

{{< tab title="Auto-compilé" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

Si votre déploiement GitLab comporte plusieurs nœuds, vous devez choisir un nœud pour exécuter la commande de sauvegarde. Vous devez vous assurer que le nœud désigné :

- est persistant et non soumis à la mise à l'échelle automatique.
- dispose de l'application GitLab Rails déjà installée. Si Puma ou Sidekiq est en cours d'exécution, alors Rails est installé.
- dispose d'un espace de stockage et d'une mémoire suffisants pour produire le fichier de sauvegarde.

Exemple de sortie :

```plaintext
Dumping database tables:
- Dumping table events... [DONE]
- Dumping table issues... [DONE]
- Dumping table keys... [DONE]
- Dumping table merge_requests... [DONE]
- Dumping table milestones... [DONE]
- Dumping table namespaces... [DONE]
- Dumping table notes... [DONE]
- Dumping table projects... [DONE]
- Dumping table protected_branches... [DONE]
- Dumping table schema_migrations... [DONE]
- Dumping table services... [DONE]
- Dumping table snippets... [DONE]
- Dumping table taggings... [DONE]
- Dumping table tags... [DONE]
- Dumping table users... [DONE]
- Dumping table users_projects... [DONE]
- Dumping table web_hooks... [DONE]
- Dumping table wikis... [DONE]
Dumping repositories:
- Dumping repository abcd... [DONE]
Creating backup archive: <backup-id>_gitlab_backup.tar [DONE]
Deleting tmp directories...[DONE]
Deleting old backups... [SKIPPING]
```

Pour des informations détaillées sur le processus de sauvegarde, consultez [Processus d'archivage des sauvegardes](backup_archive_process.md).

### Options de sauvegarde {#backup-options}

L'outil de ligne de commande fourni par GitLab pour sauvegarder votre instance peut accepter davantage d'options.

#### Option de stratégie de sauvegarde {#backup-strategy-option}

La stratégie de sauvegarde par défaut consiste essentiellement à diffuser les données depuis les emplacements de données respectifs vers la sauvegarde à l'aide des commandes Linux `tar` et `gzip`. Cela fonctionne bien dans la plupart des cas, mais peut poser des problèmes lorsque les données changent rapidement.

Lorsque les données changent pendant que `tar` les lit, l'erreur `file changed as we read it` peut se produire et entraîner l'échec du processus de sauvegarde. Dans ce cas, vous pouvez utiliser la stratégie de sauvegarde appelée `copy`. La stratégie copie les fichiers de données vers un emplacement temporaire avant d'appeler `tar` et `gzip`, évitant ainsi l'erreur.

Un effet secondaire est que le processus de sauvegarde utilise jusqu'à 1X d'espace disque supplémentaire. Le processus fait de son mieux pour nettoyer les fichiers temporaires à chaque étape, afin que le problème ne s'aggrave pas, mais cela peut représenter un changement considérable pour les grandes installations.

Pour utiliser la stratégie `copy` plutôt que la stratégie de diffusion par défaut, spécifiez `STRATEGY=copy` dans la commande de tâche Rake. Par exemple :

```shell
sudo gitlab-backup create STRATEGY=copy
```

#### Nom de fichier de sauvegarde {#backup-filename}

> [!warning]
> Si vous utilisez un nom de fichier de sauvegarde personnalisé, vous ne pouvez pas [limiter la durée de vie des sauvegardes](#limit-backup-lifetime-for-local-files-prune-old-backups).

Les fichiers de sauvegarde sont créés avec des noms de fichiers conformes aux [valeurs par défaut spécifiques](backup_archive_process.md#backup-id). Cependant, vous pouvez remplacer la partie `<backup-id>` du nom de fichier en définissant la variable d'environnement `BACKUP`. Par exemple :

```shell
sudo gitlab-backup create BACKUP=dump
```

Le fichier résultant est nommé `dump_gitlab_backup.tar`. Ceci est utile pour les systèmes qui utilisent rsync et les sauvegardes incrémentielles, et permet d'obtenir des vitesses de transfert considérablement plus rapides.

#### Compression de sauvegarde {#backup-compression}

Par défaut, la compression rapide Gzip est appliquée lors de la sauvegarde de :

- Dumps de base de données PostgreSQL.
- Blobs, par exemple les téléversements, les artefacts de job, les diffs de merge request externes.

Voir aussi :

- [Bases de données PostgreSQL](#postgresql-databases)
- [Blobs](#blobs)

La commande par défaut est `gzip -c -1`. Vous pouvez remplacer cette commande par `COMPRESS_CMD`. De même, vous pouvez remplacer la commande de décompression par `DECOMPRESS_CMD`.

Mises en garde :

- La commande de compression est utilisée dans un pipeline, donc votre commande personnalisée doit envoyer la sortie vers `stdout`.
- Si vous spécifiez une commande qui n'est pas fournie avec GitLab, vous devez l'installer vous-même.
- Les noms de fichiers résultants se termineront toujours par `.gz`.
- La commande de décompression par défaut, utilisée lors de la restauration, est `gzip -cd`. Par conséquent, si vous remplacez la commande de compression pour utiliser un format qui ne peut pas être décompressé par `gzip -cd`, vous devez remplacer la commande de décompression lors de la restauration.
- Ne placez pas de variables d'environnement après la commande de sauvegarde. Par exemple, `gitlab-backup create COMPRESS_CMD="pigz -c --best"` ne fonctionne pas comme prévu.

##### Compression par défaut :  Gzip avec la méthode la plus rapide {#default-compression-gzip-with-fastest-method}

```shell
gitlab-backup create
```

##### Gzip avec la méthode la plus lente {#gzip-with-slowest-method}

```shell
COMPRESS_CMD="gzip -c --best" gitlab-backup create
```

Si `gzip` a été utilisé pour la sauvegarde, la restauration ne nécessite aucune option :

```shell
gitlab-backup restore
```

##### Sans compression {#no-compression}

Si votre destination de sauvegarde dispose d'une compression automatique intégrée, vous pouvez souhaiter ignorer la compression.

La commande `tee` redirige `stdin` vers `stdout`.

```shell
COMPRESS_CMD=tee gitlab-backup create
```

Et lors de la restauration :

```shell
DECOMPRESS_CMD=tee gitlab-backup restore
```

##### Compression parallèle avec `pigz` {#parallel-compression-with-pigz}

> [!warning]
> Bien que nous prenions en charge l'utilisation de `COMPRESS_CMD` et `DECOMPRESS_CMD` pour remplacer la bibliothèque de compression Gzip par défaut, nous ne testons la bibliothèque Gzip par défaut qu'avec les options par défaut de façon régulière. Vous êtes responsable des tests et de la validation de la viabilité de vos sauvegardes. Nous recommandons fortement cela comme bonne pratique générale pour les sauvegardes, que vous remplaciez ou non la commande de compression. Si vous rencontrez des problèmes avec une autre bibliothèque de compression, vous devriez revenir à la bibliothèque par défaut. Le dépannage et la correction des erreurs avec des bibliothèques alternatives sont une priorité moindre pour GitLab.

Un exemple de compression des sauvegardes avec `pigz` en utilisant 4 processus :

```shell
sudo COMPRESS_CMD="pigz --stdout --fast --processes 4" gitlab-backup create
```

Étant donné que `pigz` compresse au format `gzip`, il n'est pas nécessaire d'utiliser `pigz` pour décompresser les sauvegardes qui ont été compressées par `pigz`. Cependant, cela peut tout de même offrir un avantage de performance par rapport à `gzip`. Un exemple de décompression des sauvegardes avec `pigz` :

```shell
sudo DECOMPRESS_CMD="pigz --decompress --stdout" gitlab-backup restore
```

> [!note]
> `pigz` n'est pas inclus dans le package Linux GitLab. Vous devez l'installer vous-même.

##### Compression parallèle avec `zstd` {#parallel-compression-with-zstd}

> [!warning]
> Bien que nous prenions en charge l'utilisation de `COMPRESS_CMD` et `DECOMPRESS_CMD` pour remplacer la bibliothèque de compression Gzip par défaut, nous ne testons la bibliothèque Gzip par défaut qu'avec les options par défaut de façon régulière. Vous êtes responsable des tests et de la validation de la viabilité de vos sauvegardes. Nous recommandons fortement cela comme bonne pratique générale pour les sauvegardes, que vous remplaciez ou non la commande de compression. Si vous rencontrez des problèmes avec une autre bibliothèque de compression, vous devriez revenir à la bibliothèque par défaut. Le dépannage et la correction des erreurs avec des bibliothèques alternatives sont une priorité moindre pour GitLab.

Un exemple de compression des sauvegardes avec `zstd` en utilisant 4 threads :

```shell
sudo COMPRESS_CMD="zstd --compress --stdout --fast --threads=4" gitlab-backup create
```

Un exemple de décompression des sauvegardes avec `zstd` :

```shell
sudo DECOMPRESS_CMD="zstd --decompress --stdout" gitlab-backup restore
```

> [!note]
> `zstd` n'est pas inclus dans le package Linux GitLab. Vous devez l'installer vous-même.

#### Confirmer que l'archive peut être transférée {#confirm-archive-can-be-transferred}

Pour vous assurer que l'archive générée est transférable par rsync, vous pouvez définir l'option `GZIP_RSYNCABLE=yes`. Cela définit l'option `--rsyncable` pour `gzip`, ce qui n'est utile qu'en combinaison avec la définition de [l'option de nom de fichier de sauvegarde](#backup-filename).

L'option `--rsyncable` dans `gzip` n'est pas garantie d'être disponible sur toutes les distributions. Pour vérifier qu'elle est disponible dans votre distribution, exécutez `gzip --help` ou consultez les pages de manuel.

```shell
sudo gitlab-backup create BACKUP=dump GZIP_RSYNCABLE=yes
```

#### Exclusion de données spécifiques de la sauvegarde {#excluding-specific-data-from-the-backup}

Selon le type d'installation, des composants légèrement différents peuvent être ignorés lors de la création de la sauvegarde.

{{< tabs >}}

{{< tab title="Package Linux (Omnibus) / Docker / Auto-compilé" >}}

<!-- source: <https://gitlab.com/gitlab-org/gitlab/-/blob/d693aa7f894c7306a0d20ab6d138a7b95785f2ff/lib/backup/manager.rb#L117-133> -->

- `db` (base de données)
- `repositories` (données des dépôts Git, wikis inclus)
- `uploads` (pièces jointes)
- `builds` (logs de sortie des jobs CI)
- `artifacts` (artefacts de job CI)
- `pages` (contenu Pages)
- `lfs` (objets LFS)
- `terraform_state` (états Terraform)
- `registry` (images du registre de conteneurs)
- `packages` (paquets)
- `ci_secure_files` (fichiers sécurisés au niveau du projet)
- `external_diffs` (diffs de merge request externes)

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

<!-- source: <https://gitlab.com/gitlab-org/build/CNG/-/blob/068e146db915efcd875414e04403410b71a2e70c/gitlab-toolbox/scripts/bin/backup-utility#L19> -->

- `db` (base de données)
- `repositories` (données des dépôts Git, wikis inclus)
- `uploads` (pièces jointes)
- `artifacts` (artefacts de job CI et logs de sortie)
- `pages` (contenu Pages)
- `lfs` (objets LFS)
- `terraform_state` (états Terraform)
- `registry` (images du registre de conteneurs)
- `packages` (registre de paquets)
- `ci_secure_files` (fichiers sécurisés au niveau du projet)
- `external_diffs` (diffs de merge request)

{{< /tab >}}

{{< /tabs >}}

{{< tabs >}}

{{< tab title="Package Linux (Omnibus)" >}}

```shell
sudo gitlab-backup create SKIP=db,uploads
```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

Consultez [Ignorer des composants](https://docs.gitlab.com/charts/backup-restore/backup/#skipping-components) dans la documentation de sauvegarde des charts.

{{< /tab >}}

{{< tab title="Auto-compilé" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=db,uploads RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

`SKIP=` est également utilisé pour :

- [Ignorer la création du fichier tar](#skipping-tar-creation) (`SKIP=tar`).
- [Ignorer le téléversement de la sauvegarde vers le stockage distant](#skip-uploading-backups-to-remote-storage) (`SKIP=remote`).

#### Ignorer la création tar {#skipping-tar-creation}

> [!note]
> Il n'est pas possible d'ignorer la création tar lors de l'utilisation du [stockage d'objets](#upload-backups-to-a-remote-cloud-storage) pour les sauvegardes.

La dernière partie de la création d'une sauvegarde est la génération d'un fichier `.tar` contenant toutes les parties. Dans certains cas, la création d'un fichier `.tar` peut être un effort inutile ou même directement nuisible. Vous pouvez donc ignorer cette étape en ajoutant `tar` à la variable d'environnement `SKIP`. Exemples d'utilisation :

- Lorsque la sauvegarde est récupérée par un autre logiciel de sauvegarde.
- Pour accélérer les sauvegardes incrémentielles en évitant d'avoir à extraire la sauvegarde à chaque fois. (Dans ce cas, `PREVIOUS_BACKUP` et `BACKUP` ne doivent pas être spécifiés, sinon la sauvegarde spécifiée est extraite, mais aucun fichier `.tar` n'est généré à la fin.)

L'ajout de `tar` à la variable `SKIP` laisse les fichiers et répertoires contenant la sauvegarde dans le répertoire utilisé pour les fichiers intermédiaires. Ces fichiers sont écrasés lors de la création d'une nouvelle sauvegarde. Vous devez donc vous assurer qu'ils sont copiés ailleurs, car vous ne pouvez avoir qu'une seule sauvegarde sur le système.

{{< tabs >}}

{{< tab title="Package Linux (Omnibus)" >}}

```shell
sudo gitlab-backup create SKIP=tar
```

{{< /tab >}}

{{< tab title="Auto-compilé" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=tar RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

#### Créer des sauvegardes de dépôts côté serveur {#create-server-side-repository-backups}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitaly/-/issues/4941) dans `gitlab-backup` dans GitLab 16.3.
- Prise en charge côté serveur dans `gitlab-backup` pour la restauration d'une sauvegarde spécifiée plutôt que la dernière sauvegarde [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132188) dans GitLab 16.6.
- Prise en charge côté serveur dans `gitlab-backup` pour la création de sauvegardes incrémentielles [introduite](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6475) dans GitLab 16.6.
- Prise en charge côté serveur dans `backup-utility` [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/438393) dans GitLab 17.0.

{{< /history >}}

Au lieu de stocker de volumineuses sauvegardes de dépôts dans l'archive de sauvegarde, les sauvegardes de dépôts peuvent être configurées de sorte que le nœud Gitaly hébergeant chaque dépôt soit responsable de la création de la sauvegarde et de sa diffusion vers le stockage d'objets. Cela permet de réduire les ressources réseau nécessaires à la création et à la restauration d'une sauvegarde.

1. [Configurer une destination de sauvegarde côté serveur dans Gitaly](../gitaly/configure_gitaly.md#configure-server-side-backups).
1. Créez une sauvegarde en utilisant l'option dépôts côté serveur. Consultez les exemples suivants.

{{< tabs >}}

{{< tab title="Package Linux (Omnibus)" >}}

```shell
sudo gitlab-backup create REPOSITORIES_SERVER_SIDE=true
```

{{< /tab >}}

{{< tab title="Auto-compilé" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create REPOSITORIES_SERVER_SIDE=true
```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --repositories-server-side
```

Lorsque vous utilisez des [sauvegardes basées sur cron](https://docs.gitlab.com/charts/backup-restore/backup/#cron-based-backup), ajoutez le drapeau `--repositories-server-side` aux arguments supplémentaires.

{{< /tab >}}

{{< /tabs >}}

#### Sauvegarder les dépôts Git simultanément {#back-up-git-repositories-concurrently}

Lors de l'utilisation de [plusieurs stockages de dépôts](../repository_storage_paths.md), les dépôts peuvent être sauvegardés ou restaurés simultanément pour optimiser l'utilisation du temps CPU. Les variables suivantes sont disponibles pour modifier le comportement par défaut de la tâche Rake :

- `GITLAB_BACKUP_MAX_CONCURRENCY` :  Le nombre maximum de projets à sauvegarder en même temps. Par défaut, correspond au nombre de processeurs logiques.
- `GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY` :  Le nombre maximum de projets à sauvegarder en même temps sur chaque stockage. Cela permet de répartir les sauvegardes de dépôts entre les stockages. La valeur par défaut est `2`.

Par exemple, avec 4 stockages de dépôts :

{{< tabs >}}

{{< tab title="Package Linux (Omnibus)" >}}

```shell
sudo gitlab-backup create GITLAB_BACKUP_MAX_CONCURRENCY=4 GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY=1
```

{{< /tab >}}

{{< tab title="Auto-compilé" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create GITLAB_BACKUP_MAX_CONCURRENCY=4 GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY=1
```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

```yaml
toolbox:
#...
    extra: {}
    extraEnv:
      GITLAB_BACKUP_MAX_CONCURRENCY: 4
      GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY: 1

```

{{< /tab >}}

{{< /tabs >}}

#### Sauvegardes incrémentielles de dépôts {#incremental-repository-backups}

{{< history >}}

- Prise en charge côté serveur pour la création de sauvegardes incrémentielles [introduite](https://gitlab.com/gitlab-org/gitaly/-/issues/5461) dans GitLab 16.6.

{{< /history >}}

> [!note]
> Seuls les dépôts prennent en charge les sauvegardes incrémentielles. Par conséquent, si vous utilisez `INCREMENTAL=yes`, la tâche crée une archive tar de sauvegarde autonome. En effet, toutes les sous-tâches, sauf les dépôts, créent toujours des sauvegardes complètes (elles écrasent la sauvegarde complète existante). Consultez le [ticket 19256](https://gitlab.com/gitlab-org/gitlab/-/issues/19256) pour une demande de fonctionnalité visant à prendre en charge les sauvegardes incrémentielles pour toutes les sous-tâches.

Les sauvegardes incrémentielles de dépôts peuvent être plus rapides que les sauvegardes complètes de dépôts car elles ne regroupent que les modifications depuis la dernière sauvegarde dans le bundle de sauvegarde de chaque dépôt. Les archives de sauvegarde produites par `gitlab-backup` sont portables et autonomes car elles contiennent toutes les étapes nécessaires pour restaurer chaque dépôt à partir de la sauvegarde complète d'origine.

Pour restaurer une sauvegarde incrémentielle vers une nouvelle instance GitLab (sans données préexistantes), vous devez créer la sauvegarde incrémentielle à partir d'une sauvegarde complète. N'ignorez aucun composant de sauvegarde lors de la création de la sauvegarde de base.

Avec les sauvegardes de dépôts côté serveur, les fichiers de sauvegarde incrémentielle de dépôts sont stockés séparément dans le stockage d'objets. Chaque incrément dépend de toutes les étapes précédentes jusqu'à la sauvegarde complète d'origine.

> [!warning]
> Ne supprimez pas les fichiers de sauvegarde incrémentielle du stockage d'objets. Si un fichier intermédiaire est supprimé (par exemple, via une politique de cycle de vie du stockage d'objets), la chaîne de sauvegarde est rompue et la sauvegarde ne peut pas être restaurée.

Pour plus de détails, consultez [Restaurer une sauvegarde incrémentielle de dépôt](restore_gitlab.md#restoring-an-incremental-repository-backup).

Utilisez l'option `PREVIOUS_BACKUP=<backup-id>` pour choisir la sauvegarde à utiliser. Par défaut, un fichier de sauvegarde est créé comme documenté dans la section [ID de sauvegarde](backup_archive_process.md#backup-id). Vous pouvez remplacer la partie `<backup-id>` du nom de fichier en définissant la [variable d'environnement `BACKUP`](#backup-filename).

Pour créer une sauvegarde incrémentielle, exécutez :

```shell
sudo gitlab-backup create INCREMENTAL=yes PREVIOUS_BACKUP=<backup-id>
```

Pour créer une sauvegarde incrémentielle [non archivée](#skipping-tar-creation) à partir d'une sauvegarde archivée, utilisez `SKIP=tar` :

```shell
sudo gitlab-backup create INCREMENTAL=yes SKIP=tar
```

#### Sauvegarder des stockages de dépôts spécifiques {#back-up-specific-repository-storages}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86896) dans GitLab 15.0.

{{< /history >}}

Lors de l'utilisation de [plusieurs stockages de dépôts](../repository_storage_paths.md), les dépôts de stockages de dépôts spécifiques peuvent être sauvegardés séparément à l'aide de l'option `REPOSITORIES_STORAGES`. L'option accepte une liste de noms de stockage séparés par des virgules.

Par exemple :

{{< tabs >}}

{{< tab title="Package Linux (Omnibus)" >}}

```shell
sudo gitlab-backup create REPOSITORIES_STORAGES=storage1,storage2
```

{{< /tab >}}

{{< tab title="Auto-compilé" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create REPOSITORIES_STORAGES=storage1,storage2
```

{{< /tab >}}

{{< /tabs >}}

#### Sauvegarder des dépôts spécifiques {#back-up-specific-repositories}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88094) dans GitLab 15.1.
- [Ignorer des dépôts spécifiques a été ajouté](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121865) dans GitLab 16.1.

{{< /history >}}

Vous pouvez sauvegarder des dépôts spécifiques à l'aide de l'option `REPOSITORIES_PATHS`. De même, vous pouvez utiliser `SKIP_REPOSITORIES_PATHS` pour ignorer certains dépôts. Les deux options acceptent une liste de chemins de projet ou de groupe séparés par des virgules. Si vous spécifiez un chemin de groupe, tous les dépôts de tous les projets du groupe et des groupes descendants sont inclus ou ignorés, selon l'option utilisée.

Par exemple, pour sauvegarder tous les dépôts de tous les projets du Groupe A (`group-a`), le dépôt du Projet C dans le Groupe B (`group-b/project-c`), et ignorer le Projet D dans le Groupe A (`group-a/project-d`) :

{{< tabs >}}

{{< tab title="Package Linux (Omnibus)" >}}

```shell
sudo gitlab-backup create REPOSITORIES_PATHS=group-a,group-b/project-c SKIP_REPOSITORIES_PATHS=group-a/project-d
```

{{< /tab >}}

{{< tab title="Auto-compilé" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create REPOSITORIES_PATHS=group-a,group-b/project-c SKIP_REPOSITORIES_PATHS=group-a/project-d
```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

```shell
REPOSITORIES_PATHS=group-a SKIP_REPOSITORIES_PATHS=group-a/project_a2 backup-utility --skip db,registry,uploads,artifacts,lfs,packages,external_diffs,terraform_state,ci_secure_files,pages
```

{{< /tab >}}

{{< /tabs >}}

#### Téléverser les sauvegardes vers un stockage distant (cloud) {#upload-backups-to-a-remote-cloud-storage}

> [!note]
> Il n'est pas possible de [d'ignorer la création tar](#skipping-tar-creation) lors de l'utilisation du stockage d'objets pour les sauvegardes.

Vous pouvez laisser le script de sauvegarde téléverser le fichier `.tar` qu'il crée vers un stockage distant. Dans l'exemple suivant, nous utilisons Amazon S3 pour le stockage, mais vous pouvez également utiliser d'autres fournisseurs cloud comme Google Cloud Storage et Azure, ou des partages montés localement.

Voir aussi :

- [Documentation de la bibliothèque Fog](https://fog.github.io/)
- [Autres fournisseurs de stockage](https://fog.github.io/storage/)
- [Guide du stockage d'objets GitLab](../object_storage.md)
- [Téléverser vers des partages montés localement](#upload-to-locally-mounted-shares)
- [Utilisation du stockage d'objets avec GitLab](../object_storage.md)

##### Utilisation d'Amazon S3 {#using-amazon-s3}

Pour le package Linux (Omnibus) :

1. Ajoutez ce qui suit à `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'AWS',
     'region' => 'eu-west-1',
     # Choose one authentication method
     # IAM Profile
     'use_iam_profile' => true
     # OR AWS Access and Secret key
     'aws_access_key_id' => 'AKIAKIAKI',
     'aws_secret_access_key' => 'secret123'
   }
   gitlab_rails['backup_upload_remote_directory'] = 'my.s3.bucket'
   # Consider using multipart uploads when file size reaches 100 MB. Enter a number in bytes.
   # gitlab_rails['backup_multipart_chunk_size'] = 104857600
   ```

1. Si vous utilisez la méthode d'authentification par profil IAM, assurez-vous que l'instance sur laquelle `backup-utility` doit être exécuté dispose de la politique suivante (remplacez `<backups-bucket>` par le nom correct du bucket) :

   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "s3:PutObject",
                   "s3:GetObject",
                   "s3:DeleteObject"
               ],
               "Resource": "arn:aws:s3:::<backups-bucket>/*"
           }
       ]
   }
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet

##### Buckets S3 chiffrés {#s3-encrypted-buckets}

AWS prend en charge ces [modes de chiffrement côté serveur](https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html) :

- Clés gérées par Amazon S3 (SSE-S3)
- Clés principales client (CMK) stockées dans AWS Key Management Service (SSE-KMS)
- Clés fournies par le client (SSE-C)

Utilisez le mode de votre choix avec GitLab. Chaque mode a des méthodes de configuration similaires mais légèrement différentes.

###### SSE-S3 {#sse-s3}

Pour activer SSE-S3, dans les options de stockage de sauvegarde, définissez le champ `server_side_encryption` sur `AES256`. Par exemple, dans le package Linux (Omnibus) :

```ruby
gitlab_rails['backup_upload_storage_options'] = {
  'server_side_encryption' => 'AES256'
}
```

###### SSE-KMS {#sse-kms}

Pour activer SSE-KMS, vous avez besoin de la [clé KMS via son Amazon Resource Name (ARN) au format `arn:aws:kms:region:acct-id:key/key-id`](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html). Sous le paramètre de configuration `backup_upload_storage_options`, définissez :

- `server_side_encryption` sur `aws:kms`.
- `server_side_encryption_kms_key_id` sur l'ARN de la clé.

Par exemple, dans le package Linux (Omnibus) :

```ruby
gitlab_rails['backup_upload_storage_options'] = {
  'server_side_encryption' => 'aws:kms',
  'server_side_encryption_kms_key_id' => 'arn:aws:<YOUR KMS KEY ID>:'
}
```

###### SSE-C {#sse-c}

SSE-C requiert de définir ces options de chiffrement :

- `backup_encryption` :  AES256\.
- `backup_encryption_key` :  Clé non encodée de 32 octets (256 bits). Le téléversement échoue si la clé ne fait pas exactement 32 octets.

Par exemple, dans le package Linux (Omnibus) :

```ruby
gitlab_rails['backup_encryption'] = 'AES256'
gitlab_rails['backup_encryption_key'] = '<YOUR 32-BYTE KEY HERE>'
```

Si la clé contient des caractères binaires et ne peut pas être encodée en UTF-8, spécifiez plutôt la clé avec la variable d'environnement `GITLAB_BACKUP_ENCRYPTION_KEY`. Par exemple :

```ruby
gitlab_rails['env'] = { 'GITLAB_BACKUP_ENCRYPTION_KEY' => "\xDE\xAD\xBE\xEF" * 8 }
```

##### Digital Ocean Spaces {#digital-ocean-spaces}

Cet exemple peut être utilisé pour un bucket à Amsterdam (AMS3) :

1. Ajoutez ce qui suit à `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'AWS',
     'region' => 'ams3',
     'aws_access_key_id' => 'AKIAKIAKI',
     'aws_secret_access_key' => 'secret123',
     'endpoint'              => 'https://ams3.digitaloceanspaces.com'
   }
   gitlab_rails['backup_upload_remote_directory'] = 'my.s3.bucket'
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet

Si vous voyez un message d'erreur `400 Bad Request` lors de l'utilisation de Digital Ocean Spaces, la cause peut être l'utilisation du chiffrement de sauvegarde. Étant donné que Digital Ocean Spaces ne prend pas en charge le chiffrement, supprimez ou commentez la ligne contenant `gitlab_rails['backup_encryption']`.

##### Autres fournisseurs S3 {#other-s3-providers}

Tous les fournisseurs S3 ne sont pas entièrement compatibles avec la bibliothèque Fog. Par exemple, si vous voyez un message d'erreur `411 Length Required` après une tentative de téléversement, vous devrez peut-être réduire la valeur de `aws_signature_version` de la valeur par défaut à `2`, [en raison de ce problème](https://github.com/fog/fog-aws/issues/428).

Pour les installations auto-compilées :

1. Modifiez `home/git/gitlab/config/gitlab.yml` :

   ```yaml
     backup:
       # snip
       upload:
         # Fog storage connection settings, see https://fog.github.io/storage/ .
         connection:
           provider: AWS
           region: eu-west-1
           aws_access_key_id: AKIAKIAKI
           aws_secret_access_key: 'secret123'
           # If using an IAM Profile, leave aws_access_key_id & aws_secret_access_key empty
           # ie. aws_access_key_id: ''
           # use_iam_profile: 'true'
         # The remote 'directory' to store your backups. For S3, this would be the bucket name.
         remote_directory: 'my.s3.bucket'
         # Specifies Amazon S3 storage class to use for backups, this is optional
         # storage_class: 'STANDARD'
         #
         # Turns on AWS Server-Side Encryption with Amazon Customer-Provided Encryption Keys for backups, this is optional
         #   'encryption' must be set in order for this to have any effect.
         #   'encryption_key' should be set to the 256-bit encryption key for Amazon S3 to use to encrypt or decrypt.
         #   To avoid storing the key on disk, the key can also be specified via the `GITLAB_BACKUP_ENCRYPTION_KEY` your data.
         # encryption: 'AES256'
         # encryption_key: '<key>'
         #
         #
         # Turns on AWS Server-Side Encryption with Amazon S3-Managed keys (optional)
         # https://docs.aws.amazon.com/AmazonS3/latest/userguide/serv-side-encryption.html
         # For SSE-S3, set 'server_side_encryption' to 'AES256'.
         # For SS3-KMS, set 'server_side_encryption' to 'aws:kms'. Set
         # 'server_side_encryption_kms_key_id' to the ARN of customer master key.
         # storage_options:
         #   server_side_encryption: 'aws:kms'
         #   server_side_encryption_kms_key_id: 'arn:aws:kms:YOUR-KEY-ID-HERE'
   ```

1. [Redémarrer GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet

##### Utilisation de Google Cloud Storage {#using-google-cloud-storage}

Pour utiliser Google Cloud Storage pour enregistrer des sauvegardes, vous devez d'abord créer une clé d'accès depuis la console Google :

1. Accédez à la [page des paramètres de stockage Google](https://console.cloud.google.com/storage/settings).
1. Sélectionnez **Interoperability**, puis créez une clé d'accès.
1. Notez la **Access Key** et le **Secret** et remplacez-les dans les configurations suivantes.
1. Dans les paramètres avancés des buckets, assurez-vous que l'option de contrôle d'accès **Set object-level and bucket-level permissions** est sélectionnée.
1. Assurez-vous d'avoir déjà créé un bucket.

Pour le package Linux (Omnibus) :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'Google',
     'google_storage_access_key_id' => 'Access Key',
     'google_storage_secret_access_key' => 'Secret',

     ## If you have CNAME buckets (foo.example.com), you might run into SSL issues
     ## when uploading backups ("hostname foo.example.com.storage.googleapis.com
     ## does not match the server certificate"). In that case, uncomment the following
     ## setting. See: https://github.com/fog/fog/issues/2834
     #'path_style' => true
   }
   gitlab_rails['backup_upload_remote_directory'] = 'my.google.bucket'
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet

Pour les installations auto-compilées :

1. Modifiez `home/git/gitlab/config/gitlab.yml` :

   ```yaml
     backup:
       upload:
         connection:
           provider: 'Google'
           google_storage_access_key_id: 'Access Key'
           google_storage_secret_access_key: 'Secret'
         remote_directory: 'my.google.bucket'
   ```

1. [Redémarrer GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet

##### Utilisation du stockage Azure Blob {#using-azure-blob-storage}

{{< tabs >}}

{{< tab title="Package Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
    'provider' => 'AzureRM',
    'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
    'azure_storage_access_key' => '<AZURE STORAGE ACCESS KEY>',
    'azure_storage_domain' => 'blob.core.windows.net', # Optional
   }
   gitlab_rails['backup_upload_remote_directory'] = '<AZURE BLOB CONTAINER>'
   ```

   Si vous utilisez [une identité gérée](../object_storage.md#azure-workload-and-managed-identities), omettez `azure_storage_access_key` :

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     'provider' => 'AzureRM',
     'azure_storage_account_name' => '<AZURE STORAGE ACCOUNT NAME>',
     'azure_storage_domain' => '<AZURE STORAGE DOMAIN>' # Optional
   }
   gitlab_rails['backup_upload_remote_directory'] = '<AZURE BLOB CONTAINER>'
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet

{{< /tab >}}

{{< tab title="Auto-compilé" >}}

1. Modifiez `home/git/gitlab/config/gitlab.yml` :

   ```yaml
     backup:
       upload:
         connection:
           provider: 'AzureRM'
           azure_storage_account_name: '<AZURE STORAGE ACCOUNT NAME>'
           azure_storage_access_key: '<AZURE STORAGE ACCESS KEY>'
         remote_directory: '<AZURE BLOB CONTAINER>'
   ```

1. [Redémarrer GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet

{{< /tab >}}

{{< /tabs >}}

Pour plus de détails, consultez le [tableau des paramètres Azure](../object_storage.md#azure-blob-storage).

##### Spécification d'un répertoire personnalisé pour les sauvegardes {#specifying-a-custom-directory-for-backups}

Cette option fonctionne uniquement pour le stockage distant. Si vous souhaitez regrouper vos sauvegardes, vous pouvez passer une variable d'environnement `DIRECTORY` :

```shell
sudo gitlab-backup create DIRECTORY=daily
sudo gitlab-backup create DIRECTORY=weekly
```

#### Ignorer le téléversement des sauvegardes vers le stockage distant {#skip-uploading-backups-to-remote-storage}

Si vous avez configuré GitLab pour [téléverser des sauvegardes vers un stockage distant](#upload-backups-to-a-remote-cloud-storage), vous pouvez utiliser l'option `SKIP=remote` pour ignorer le téléversement de vos sauvegardes vers le stockage distant.

{{< tabs >}}

{{< tab title="Package Linux (Omnibus)" >}}

```shell
sudo gitlab-backup create SKIP=remote
```

{{< /tab >}}

{{< tab title="Auto-compilé" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=remote RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

#### Téléverser vers des partages montés localement {#upload-to-locally-mounted-shares}

Vous pouvez envoyer des sauvegardes vers un partage monté localement (par exemple, `NFS`, `CIFS` ou `SMB`) en utilisant le fournisseur de stockage Fog [`Local`](https://github.com/fog/fog-local#usage).

Pour ce faire, vous devez définir les clés de configuration suivantes :

- `backup_upload_connection.local_root` : répertoire monté vers lequel les sauvegardes sont copiées.
- `backup_upload_remote_directory` : sous-répertoire du répertoire `backup_upload_connection.local_root`. Il est créé s'il n'existe pas. Si vous souhaitez copier les archives tar à la racine de votre répertoire monté, utilisez `.`.

Lors du montage, le répertoire défini dans la clé `local_root` doit appartenir à :

- L'utilisateur `git`. Donc, monter avec le `uid=` de l'utilisateur `git` pour `CIFS` et `SMB`.
- L'utilisateur avec lequel vous exécutez les tâches de sauvegarde. Pour le package Linux (Omnibus), c'est l'utilisateur `git`.

Étant donné que les performances du système de fichiers peuvent affecter les performances globales de GitLab, [nous ne recommandons pas l'utilisation de systèmes de fichiers basés sur le cloud pour le stockage](../nfs.md#avoid-using-cloud-based-file-systems).

##### Éviter les conflits de configuration {#avoid-conflicting-configuration}

Ne définissez pas les clés de configuration suivantes sur le même chemin :

- `gitlab_rails['backup_path']` (`backup.path` pour les installations auto-compilées).
- `gitlab_rails['backup_upload_connection'].local_root` (`backup.upload.connection.local_root` pour les installations auto-compilées).

La clé de configuration `backup_path` définit l'emplacement local du fichier de sauvegarde. La clé de configuration `upload` est destinée à être utilisée lorsque le fichier de sauvegarde est téléversé vers un serveur distinct, peut-être à des fins d'archivage.

Si ces clés de configuration sont définies sur le même emplacement, la fonctionnalité de téléversement échoue car une sauvegarde existe déjà à l'emplacement de téléversement. Cet échec entraîne la suppression de la sauvegarde par la fonctionnalité de téléversement, car elle suppose qu'il s'agit d'un fichier résiduel restant après l'échec de la tentative de téléversement.

##### Configurer les téléversements vers des partages montés localement {#configure-uploads-to-locally-mounted-shares}

{{< tabs >}}

{{< tab title="Package Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['backup_upload_connection'] = {
     :provider => 'Local',
     :local_root => '/mnt/backups'
   }

   # The directory inside the mounted folder to copy backups to
   # Use '.' to store them in the root directory
   gitlab_rails['backup_upload_remote_directory'] = 'gitlab_backups'
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Auto-compilé" >}}

1. Modifiez `home/git/gitlab/config/gitlab.yml` :

   ```yaml
   backup:
     upload:
       # Fog storage connection settings, see https://fog.github.io/storage/ .
       connection:
         provider: Local
         local_root: '/mnt/backups'
       # The directory inside the mounted folder to copy backups to
       # Use '.' to store them in the root directory
       remote_directory: 'gitlab_backups'
   ```

1. [Redémarrer GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

#### Autorisations des archives de sauvegarde {#backup-archive-permissions}

Les archives de sauvegarde créées par GitLab (`1393513186_2014_02_27_gitlab_backup.tar`) ont le propriétaire/groupe `git`/`git` et des autorisations 0600 par défaut. Cela vise à empêcher les autres utilisateurs système de lire les données GitLab. Si vous avez besoin que les archives de sauvegarde aient des autorisations différentes, vous pouvez utiliser le paramètre `archive_permissions`.

{{< tabs >}}

{{< tab title="Package Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['backup_archive_permissions'] = 0644 # Makes the backup archives world-readable
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Auto-compilé" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   backup:
     archive_permissions: 0644 # Makes the backup archives world-readable
   ```

1. [Redémarrer GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

#### Configuration de cron pour des sauvegardes quotidiennes {#configuring-cron-to-make-daily-backups}

> [!warning]
> Les tâches cron suivantes ne sauvegardent pas vos fichiers de configuration GitLab ni vos clés hôtes SSH.

**Important:** N'oubliez pas de sauvegarder également :

- [Fichiers de configuration GitLab](#storing-configuration-files)
- [Clés hôtes SSH](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079)

Vous pouvez planifier une tâche cron qui sauvegarde vos dépôts et les métadonnées GitLab.

{{< tabs >}}

{{< tab title="Package Linux (Omnibus)" >}}

1. Modifiez le crontab pour l'utilisateur `root` :

   ```shell
   sudo su -
   crontab -e
   ```

1. Ajoutez-y la ligne suivante pour planifier la sauvegarde tous les jours à 2 h :

   ```plaintext
   0 2 * * * /opt/gitlab/bin/gitlab-backup create CRON=1
   ```

{{< /tab >}}

{{< tab title="Auto-compilé" >}}

1. Modifiez le crontab pour l'utilisateur `git` :

   ```shell
   sudo -u git crontab -e
   ```

1. Ajoutez les lignes suivantes en bas :

   ```plaintext
   # Create a full backup of the GitLab repositories and SQL database every day at 2am
   0 2 * * * cd /home/git/gitlab && PATH=/usr/local/bin:/usr/bin:/bin bundle exec rake gitlab:backup:create RAILS_ENV=production CRON=1
   ```

{{< /tab >}}

{{< /tabs >}}

Le paramètre d'environnement `CRON=1` indique au script de sauvegarde de masquer toute la sortie de progression en l'absence d'erreurs. Cela est recommandé pour réduire le spam cron. Lors du dépannage des problèmes de sauvegarde, remplacez cependant `CRON=1` par `--trace` pour une journalisation détaillée.

#### Limiter la durée de vie des sauvegardes pour les fichiers locaux (supprimer les anciennes sauvegardes) {#limit-backup-lifetime-for-local-files-prune-old-backups}

> [!warning]
> Le processus décrit dans cette section ne fonctionne pas si vous avez utilisé un nom de fichier personnalisé pour vos sauvegardes.

Pour éviter que les sauvegardes régulières n'utilisent tout l'espace disque disponible, vous pouvez définir une durée de vie limitée pour les sauvegardes. La prochaine fois que la tâche de sauvegarde s'exécutera, les sauvegardes plus anciennes que `backup_keep_time` seront supprimées.

Cette option de configuration ne gère que les fichiers locaux. GitLab ne supprime pas les anciens fichiers stockés dans un stockage objet tiers, car l'utilisateur peut ne pas avoir la permission de lister et de supprimer des fichiers. Il est recommandé de configurer la politique de rétention appropriée pour votre stockage objet.

Voir aussi :

- [Configuration du nom de fichier personnalisé](#backup-filename)
- [Charger les sauvegardes vers un stockage cloud distant](#upload-backups-to-a-remote-cloud-storage)
- [AWS S3 lifecycle policies](https://docs.aws.amazon.com/AmazonS3/latest/user-guide/create-lifecycle.html)

{{< tabs >}}

{{< tab title="Package Linux (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   ## Limit backup lifetime to 7 days - 604800 seconds
   gitlab_rails['backup_keep_time'] = 604800
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Auto-compilé" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   backup:
     ## Limit backup lifetime to 7 days - 604800 seconds
     keep_time: 604800
   ```

1. [Redémarrer GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

#### Sauvegarde et restauration pour les installations utilisant PgBouncer {#back-up-and-restore-for-installations-using-pgbouncer}

Ne sauvegardez pas ni ne restaurez GitLab via une connexion PgBouncer. Ces tâches doivent [contourner PgBouncer et se connecter directement au nœud de base de données PostgreSQL principal](#bypassing-pgbouncer), sans quoi elles provoqueront une interruption de service GitLab.

Lorsque la tâche de sauvegarde ou de restauration GitLab est utilisée avec PgBouncer, le message d'erreur suivant s'affiche :

```ruby
ActiveRecord::StatementInvalid: PG::UndefinedTable
```

Chaque fois que la sauvegarde GitLab s'exécute, GitLab commence à générer des erreurs 500 et des erreurs concernant des tables manquantes seront [journalisées par PostgreSQL](../logs/_index.md#postgresql-logs) :

```plaintext
ERROR: relation "tablename" does not exist at character 123
```

Cela se produit parce que la tâche utilise `pg_dump`, qui définit un chemin de recherche nul et inclut explicitement le schéma dans chaque requête SQL pour corriger la CVE-2018-1058.

Étant donné que les connexions sont réutilisées avec PgBouncer en mode de mise en pool de transactions, PostgreSQL ne parvient pas à rechercher le schéma `public` par défaut. Par conséquent, cette suppression du chemin de recherche entraîne l'apparition de tables et de colonnes manquantes.

Références techniques :

- [Implémentation de la gestion des schémas](https://gitlab.com/gitlab-org/gitlab/-/issues/23211)
- [Détails de la CVE-2018-1058](https://www.postgresql.org/about/news/postgresql-103-968-9512-9417-and-9322-released-1834/)

##### Contournement de PgBouncer {#bypassing-pgbouncer}

Il existe deux façons de résoudre ce problème :

1. [Utiliser des variables d'environnement pour remplacer les paramètres de base de données](#environment-variable-overrides) pour la tâche de sauvegarde.
1. Reconfigurer un nœud pour [se connecter directement au nœud de base de données PostgreSQL principal](../postgresql/pgbouncer.md#procedure-for-bypassing-pgbouncer).

###### Remplacement des variables d'environnement {#environment-variable-overrides}

{{< history >}}

- La prise en charge de plusieurs bases de données a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133177) dans GitLab 16.5.

{{< /history >}}

Par défaut, GitLab utilise la configuration de base de données stockée dans un fichier de configuration (`database.yml`). Cependant, vous pouvez remplacer les paramètres de base de données pour la tâche de sauvegarde et de restauration en définissant des variables d'environnement préfixées par `GITLAB_BACKUP_` :

- `GITLAB_BACKUP_PGHOST`
- `GITLAB_BACKUP_PGUSER`
- `GITLAB_BACKUP_PGPORT`
- `GITLAB_BACKUP_PGPASSWORD`
- `GITLAB_BACKUP_PGSSLMODE`
- `GITLAB_BACKUP_PGSSLKEY`
- `GITLAB_BACKUP_PGSSLCERT`
- `GITLAB_BACKUP_PGSSLROOTCERT`
- `GITLAB_BACKUP_PGSSLCRL`
- `GITLAB_BACKUP_PGSSLCOMPRESSION`

Par exemple, pour remplacer l'hôte et le port de la base de données pour utiliser 192.168.1.10 et le port 5432 avec le paquet Linux (Omnibus) :

```shell
sudo GITLAB_BACKUP_PGHOST=192.168.1.10 GITLAB_BACKUP_PGPORT=5432 /opt/gitlab/bin/gitlab-backup create
```

Si vous exécutez GitLab sur [plusieurs bases de données](../postgresql/_index.md), vous pouvez remplacer les paramètres de base de données en incluant le nom de la base de données dans la variable d'environnement. Par exemple, si vos bases de données `main` et `ci` sont hébergées sur des serveurs de base de données différents, vous devez ajouter leur nom après le préfixe `GITLAB_BACKUP_`, en laissant les noms `PG*` tels quels :

```shell
sudo GITLAB_BACKUP_MAIN_PGHOST=192.168.1.10 GITLAB_BACKUP_CI_PGHOST=192.168.1.12 /opt/gitlab/bin/gitlab-backup create
```

Consultez la [documentation PostgreSQL](https://www.postgresql.org/docs/16/libpq-envars.html) pour plus de détails sur ce que font ces paramètres.

#### `gitaly-backup` pour la sauvegarde et la restauration des dépôts {#gitaly-backup-for-repository-backup-and-restore}

Le binaire `gitaly-backup` est utilisé par la tâche Rake de sauvegarde pour créer et restaurer des sauvegardes de dépôts depuis Gitaly. `gitaly-backup` remplace la méthode de sauvegarde précédente qui appelait directement les RPC sur Gitaly depuis GitLab.

La tâche Rake de sauvegarde doit pouvoir trouver cet exécutable. Dans la plupart des cas, vous n'avez pas besoin de modifier le chemin d'accès au binaire, car il devrait fonctionner correctement avec le chemin par défaut `/opt/gitlab/embedded/bin/gitaly-backup`. Si vous avez une raison spécifique de modifier le chemin, il peut être configuré dans le paquet Linux (Omnibus) :

1. Ajoutez ce qui suit à `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['backup_gitaly_backup_path'] = '/path/to/gitaly-backup'
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

## Stratégies de sauvegarde alternatives {#alternative-backup-strategies}

Étant donné que chaque déploiement peut avoir des capacités différentes, vous devez d'abord examiner quelles données doivent être sauvegardées pour mieux comprendre si, et comment, vous pouvez les exploiter.

Par exemple, si vous utilisez Amazon RDS, vous pouvez choisir d'utiliser ses fonctionnalités intégrées de sauvegarde et de restauration pour gérer vos données PostgreSQL GitLab, et exclure les données PostgreSQL lors de l'utilisation de la commande de sauvegarde.

Voir aussi :

- [Quelles données doivent être sauvegardées](#what-data-needs-to-be-backed-up)
- [Bases de données PostgreSQL](#postgresql-databases)
- [Exclusion de données spécifiques de la sauvegarde](#excluding-specific-data-from-the-backup)
- [Commande de sauvegarde](#backup-command)

Dans les cas suivants, envisagez d'utiliser le transfert de données du système de fichiers ou des instantanés dans le cadre de votre stratégie de sauvegarde :

- Votre instance GitLab contient beaucoup de données de dépôts Git et le script de sauvegarde GitLab est trop lent.
- Votre instance GitLab comporte de nombreux projets dupliqués et la tâche de sauvegarde régulière duplique les données Git pour chacun d'eux.
- Votre instance GitLab rencontre un problème et l'utilisation des tâches Rake de sauvegarde et d'importation régulières n'est pas possible.

> [!warning]
> Gitaly Cluster (Praefect) [ne prend pas en charge les sauvegardes par instantané](../gitaly/praefect/_index.md#snapshot-backup-and-recovery).

Lors de l'utilisation du transfert de données du système de fichiers ou des instantanés :

- N'utilisez pas ces méthodes pour migrer d'un système d'exploitation à un autre. Les systèmes d'exploitation de la source et de la destination doivent être aussi similaires que possible. Par exemple, n'utilisez pas ces méthodes pour migrer d'Ubuntu vers RHEL.
- La cohérence des données est très importante. Vous devez arrêter GitLab (`sudo gitlab-ctl stop`) avant d'effectuer un transfert de système de fichiers (avec `rsync`, par exemple) ou de prendre un instantané pour vous assurer que toutes les données en mémoire sont écrites sur le disque. GitLab est composé de plusieurs sous-systèmes (Gitaly, base de données, stockage de fichiers) qui disposent de leurs propres tampons, files d'attente et couches de stockage. Les transactions GitLab peuvent s'étendre sur ces sous-systèmes, ce qui entraîne des parties d'une transaction prenant des chemins différents vers le disque. Sur les systèmes en cours d'exécution, les transferts de système de fichiers et les instantanés ne parviennent pas à capturer les parties de la transaction encore en mémoire.

Exemple :  Amazon Elastic Block Store (EBS)

- Un serveur GitLab utilisant le paquet Linux (Omnibus) hébergé sur Amazon AWS.
- Un disque EBS contenant un système de fichiers ext4 est monté à `/var/opt/gitlab`.
- Dans ce cas, vous pouvez effectuer une sauvegarde de l'application en prenant un instantané EBS.
- La sauvegarde inclut tous les dépôts, les chargements et les données PostgreSQL.

Exemple :  Logical Volume Manager (LVM) snapshots + rsync

- Un serveur GitLab utilisant le paquet Linux (Omnibus), avec un volume logique LVM monté à `/var/opt/gitlab`.
- La réplication du répertoire `/var/opt/gitlab` avec rsync ne serait pas fiable, car trop de fichiers changeraient pendant l'exécution de rsync.
- Au lieu de synchroniser `/var/opt/gitlab` avec rsync, nous créons un instantané LVM temporaire, que nous montons en tant que système de fichiers en lecture seule à `/mnt/gitlab_backup`.
- Nous pouvons maintenant exécuter un job rsync plus long qui crée un réplica cohérent sur le serveur distant.
- Le réplica inclut tous les dépôts, les chargements et les données PostgreSQL.

Si vous exécutez GitLab sur un serveur virtualisé, vous pouvez également créer des instantanés VM de l'ensemble du serveur GitLab. Il n'est cependant pas rare qu'un instantané VM vous oblige à éteindre le serveur, ce qui limite l'utilisation pratique de cette solution.

### Sauvegarder les données des dépôts séparément {#back-up-repository-data-separately}

Tout d'abord, assurez-vous de sauvegarder les données GitLab existantes en [ignorant les dépôts](#excluding-specific-data-from-the-backup) :

{{< tabs >}}

{{< tab title="Package Linux (Omnibus)" >}}

```shell
sudo gitlab-backup create SKIP=repositories
```

{{< /tab >}}

{{< tab title="Auto-compilé" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:create SKIP=repositories RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

Pour sauvegarder manuellement les données du dépôt Git sur le disque, il existe plusieurs stratégies possibles :

- Utilisez des instantanés, comme les exemples précédents d'instantanés de disque Amazon EBS, ou les instantanés LVM + rsync.
- Utilisez [GitLab Geo](../geo/_index.md) et reposez-vous sur les données du dépôt sur un site secondaire Geo.
- [Empêcher les écritures et copier les données du dépôt Git](#prevent-writes-and-copy-the-git-repository-data).
- [Créer une sauvegarde en ligne en marquant les dépôts comme en lecture seule (expérimental)](#online-backup-through-marking-repositories-as-read-only-experimental).

#### Empêcher les écritures et copier les données du dépôt Git {#prevent-writes-and-copy-the-git-repository-data}

Les dépôts Git doivent être copiés de manière cohérente. Si les dépôts sont copiés lors d'opérations d'écriture simultanées, des incohérences ou des problèmes de corruption peuvent survenir. Cela peut entraîner une corruption du dépôt, des commits manquants ou des données de sauvegarde incomplètes.

Pour empêcher les écritures dans les données du dépôt Git, il existe deux approches possibles :

- Utilisez le [mode maintenance](../maintenance_mode/_index.md) pour placer GitLab en état de lecture seule.
- Créez un temps d'arrêt explicite en arrêtant tous les services Gitaly avant de sauvegarder les dépôts :

  ```shell
  sudo gitlab-ctl stop gitaly
  # execute git data copy step
  sudo gitlab-ctl start gitaly
  ```

Vous pouvez copier les données du dépôt Git en utilisant n'importe quelle méthode, à condition que les écritures soient empêchées sur les données en cours de copie (pour éviter les incohérences et les problèmes de corruption). Par ordre de préférence et de sécurité, les méthodes recommandées sont :

1. Utilisez `rsync` avec les options archive-mode, delete et checksum, par exemple :

   ```shell
   rsync -aR --delete --checksum source destination # be extra safe with the order as it will delete existing data if inverted
   ```

1. Utilisez un [tube `tar` pour copier l'intégralité du répertoire du dépôt vers un autre serveur ou emplacement](../operations/moving_repositories.md#use-a-tar-pipe-to-another-server).
1. Utilisez `sftp`, `scp`, `cp`, ou toute autre méthode de copie.

#### Sauvegarde en ligne en marquant les dépôts comme en lecture seule (expérimental) {#online-backup-through-marking-repositories-as-read-only-experimental}

Une façon de sauvegarder les dépôts sans nécessiter de temps d'arrêt à l'échelle de l'instance consiste à marquer les projets par programmation comme étant en lecture seule lors de la copie des données sous-jacentes.

Voici quelques inconvénients possibles :

- Les dépôts sont en lecture seule pendant une période qui évolue en fonction de la taille du dépôt.
- Les sauvegardes prennent plus de temps à se terminer en raison du marquage de chaque projet en lecture seule, ce qui peut entraîner des incohérences. Par exemple, un possible écart de date entre les dernières données disponibles pour le premier projet sauvegardé par rapport au dernier projet sauvegardé.
- Les réseaux de duplications doivent être entièrement en lecture seule pendant que les projets qu'ils contiennent sont sauvegardés afin d'éviter des modifications potentielles du dépôt pool.

Il existe un script expérimental qui tente d'automatiser ce processus dans [le projet Runbooks de l'équipe Geo](https://gitlab.com/gitlab-org/geo-team/runbooks/-/tree/main/experimental-online-backup-through-rsync).
