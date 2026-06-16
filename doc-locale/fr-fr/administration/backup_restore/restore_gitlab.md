---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Restaurer GitLab
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les opérations de restauration GitLab récupèrent les données des sauvegardes pour maintenir la continuité du système et se remettre d'une perte de données. Opérations de restauration :

- Récupérer les enregistrements de base de données et la configuration
- Restaurer les dépôts Git, les images de registre de conteneurs et le contenu téléversé
- Rétablir les données du registre de paquets et les artefacts CI/CD
- Restaurer les paramètres de compte et de groupe
- Récupérer les wikis de projet et de groupe
- Restaurer les fichiers sécurisés au niveau du projet
- Récupérer les diffs de merge request externes

Le processus de restauration nécessite une installation GitLab existante de la même version que la sauvegarde. Suivez les [prérequis](#restore-prerequisites) et testez le processus de restauration complet avant de l'utiliser en production.

## Prérequis de restauration {#restore-prerequisites}

### L'instance GitLab de destination doit déjà fonctionner {#the-destination-gitlab-instance-must-already-be-working}

Vous devez disposer d'une installation GitLab fonctionnelle avant de pouvoir effectuer une restauration. En effet, l'utilisateur système qui effectue les actions de restauration (`git`) n'est généralement pas autorisé à créer ou supprimer la base de données SQL nécessaire pour importer les données (`gitlabhq_production`).

### L'instance GitLab de destination ne doit pas avoir de données existantes {#the-destination-gitlab-instance-must-not-have-existing-data}

Le processus de restauration gère les données existantes différemment selon le type de données :

- Les données PostgreSQL sont automatiquement effacées pendant le processus de restauration.
- Dépôts Git :  Si des dépôts portant le même nom existent déjà, la restauration échoue avec une erreur « repository already exists ». Pour plus d'informations, voir [ticket 118459](https://gitlab.com/gitlab-org/gitlab/-/issues/118459).
- Le système tente de déplacer les données du système de fichiers vers un répertoire séparé avant la restauration.
- Les données du stockage objet ne sont pas automatiquement effacées. Vous devez vider manuellement les compartiments de stockage objet avant de restaurer pour éviter de conserver des données orphelines.

Pour un processus de restauration fiable, par exemple lors de l'automatisation des restaurations de production vers la pré-production, utilisez une nouvelle installation GitLab à la même version que la sauvegarde.

La restauration des données SQL ignore les vues appartenant aux extensions PostgreSQL.

### L'instance GitLab de destination doit avoir exactement la même version {#the-destination-gitlab-instance-must-have-the-exact-same-version}

Vous pouvez uniquement restaurer une sauvegarde vers exactement la même version et le même type (CE ou EE) de GitLab sur lesquels elle a été créée. Par exemple, CE 15.1.4.

Si votre sauvegarde est d'une version différente de l'installation actuelle, vous devez [rétrograder](../../update/package/downgrade.md) ou [mettre à niveau](../../update/package/_index.md) votre installation GitLab avant de restaurer la sauvegarde.

### Les secrets GitLab doivent être restaurés {#gitlab-secrets-must-be-restored}

Pour restaurer une sauvegarde, vous devez également restaurer les secrets GitLab. Si vous migrez vers une nouvelle instance GitLab, vous devez copier le fichier des secrets GitLab depuis l'ancien serveur. Ceux-ci comprennent la clé de chiffrement de la base de données, les variables CI/CD et les variables utilisées pour l'authentification à deux facteurs. Sans les clés, plusieurs problèmes surviennent, notamment la perte d'accès des utilisateurs ayant activé l'authentification à deux facteurs, et les GitLab Runners ne peuvent pas se connecter.

> [!warning]
> **WebAuthn devices are disabled when restoring to a different FQDN:** Les enregistrements WebAuthn (tels que les YubiKeys) sont cryptographiquement liés à l'origine (domaine/nom d'hôte) où ils ont été créés. Si vous restaurez une sauvegarde vers une instance GitLab avec un FQDN différent de l'instance d'origine, tous les appareils WebAuthn seront désactivés. Les utilisateurs devront réenregistrer leurs appareils WebAuthn une fois la restauration terminée.
>
> Pour plus d'informations sur WebAuthn et les exigences relatives aux noms d'hôte, voir [Authentification à deux facteurs](../../user/profile/account/two_factor_authentication.md#information-for-gitlab-administrators).

Selon votre méthode d'installation, restaurez les éléments suivants :

{{< tabs >}}

{{< tab title="Paquet Linux" >}}

```plaintext
/etc/gitlab/gitlab-secrets.json
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

[Restaurer les secrets](https://docs.gitlab.com/charts/backup-restore/restore/#restoring-the-secrets).

[Les secrets du Helm chart GitLab peuvent être convertis au format de paquet Linux](https://docs.gitlab.com/charts/installation/migration/helm_to_package/), si nécessaire.

{{< /tab >}}

{{< tab title="Docker" >}}

Si vous avez monté `/etc/gitlab` sous `/srv/gitlab/config` :

```plaintext
/srv/gitlab/config/gitlab-secrets.json
```

{{< /tab >}}

{{< tab title="Compilé manuellement (source)" >}}

```plaintext
/home/git/gitlab/.secret
```

{{< /tab >}}

{{< /tabs >}}

Voir aussi :

- [Variables CI/CD](../../ci/variables/_index.md)
- [Authentification à deux facteurs](../../user/profile/account/two_factor_authentication.md)
- [Résolution des problèmes liés aux secrets](troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost)

### Certaines configurations GitLab doivent correspondre à l'environnement sauvegardé d'origine {#certain-gitlab-configuration-must-match-the-original-backed-up-environment}

Vous souhaiterez probablement restaurer séparément votre précédent `/etc/gitlab/gitlab.rb` (pour les installations avec paquet Linux) ou `/home/git/gitlab/config/gitlab.yml` (pour les installations compilées manuellement) ainsi que tous les certificats et clés TLS ou SSH.

Certaines configurations sont couplées aux données dans PostgreSQL. Par exemple :

- Si l'environnement d'origine dispose de trois stockages de dépôts (par exemple, `default`, `my-storage-1` et `my-storage-2`), l'environnement cible doit également avoir au moins ces noms de stockage définis dans la configuration.
- La restauration d'une sauvegarde depuis un environnement utilisant le stockage local se restaure vers le stockage local, même si l'environnement cible utilise le stockage objet. Les migrations vers le stockage objet doivent être effectuées avant ou après la restauration.

Pour plus d'informations, voir [Données non incluses dans la sauvegarde](backup_gitlab.md#data-not-included-in-a-backup).

### Restauration de répertoires qui sont des points de montage {#restoring-directories-that-are-mount-points}

Si vous restaurez dans des répertoires qui sont des points de montage, vous devez vous assurer que ces répertoires sont vides avant de tenter une restauration. Sinon, GitLab tente de déplacer ces répertoires avant de restaurer les nouvelles données, ce qui provoque une erreur.

En savoir plus sur la [configuration des montages NFS](../nfs.md).

## Restauration pour les installations avec paquet Linux {#restore-for-linux-package-installations}

Cette procédure suppose que :

- Vous avez installé exactement la même version et le même type (CE/EE) de GitLab avec lesquels la sauvegarde a été créée.
- Vous avez exécuté `sudo gitlab-ctl reconfigure` au moins une fois.
- GitLab est en cours d'exécution. Sinon, démarrez-le avec `sudo gitlab-ctl start`.

Assurez-vous d'abord que votre fichier tar de sauvegarde se trouve dans le répertoire de sauvegarde décrit dans la configuration `gitlab.rb` `gitlab_rails['backup_path']`. La valeur par défaut est `/var/opt/gitlab/backups`. Le fichier de sauvegarde doit appartenir à l'utilisateur `git`.

```shell
sudo cp 11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar /var/opt/gitlab/backups/
sudo chown git:git /var/opt/gitlab/backups/11493107454_2018_04_25_10.6.4-ce_gitlab_backup.tar
```

Arrêtez les processus connectés à la base de données. Laissez le reste de GitLab en cours d'exécution :

```shell
sudo gitlab-ctl stop puma
sudo gitlab-ctl stop sidekiq
# Verify
sudo gitlab-ctl status
```

Ensuite, assurez-vous d'avoir effectué les étapes des [prérequis de restauration](#restore-prerequisites) et d'avoir exécuté `gitlab-ctl reconfigure` après avoir copié le fichier des secrets GitLab de l'installation d'origine.

Ensuite, restaurez la sauvegarde en spécifiant l'ID de la sauvegarde que vous souhaitez restaurer :

> [!warning]
> La commande suivante écrase le contenu de votre base de données GitLab !

```shell
# NOTE: "_gitlab_backup.tar" is omitted from the name
sudo gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce
```

Si la version de GitLab ne correspond pas entre votre fichier tar de sauvegarde et la version installée de GitLab, la commande de restauration s'interrompt avec un message d'erreur :

```plaintext
GitLab version mismatch:
  Your current GitLab version (16.5.0-ee) differs from the GitLab version in the backup!
  Please switch to the following version and try again:
  version: 16.4.3-ee
```

Installez la version correcte de GitLab, puis réessayez.

> [!warning]
> La commande de restauration nécessite des [paramètres supplémentaires](backup_gitlab.md#back-up-and-restore-for-installations-using-pgbouncer) lorsque votre installation utilise PgBouncer, que ce soit pour des raisons de performances ou lors de son utilisation avec un cluster Patroni.

Exécutez reconfigure sur le nœud PostgreSQL :

```shell
sudo gitlab-ctl reconfigure
```

Ensuite, démarrez et vérifiez GitLab :

```shell
sudo gitlab-ctl start
sudo gitlab-rake gitlab:check SANITIZE=true
```

Vérifiez que les valeurs de la base de données peuvent être déchiffrées, surtout si `/etc/gitlab/gitlab-secrets.json` a été restauré, ou si un serveur différent est la cible de la restauration.

```shell
sudo gitlab-rake gitlab:doctor:secrets
```

Pour plus de sécurité, vous pouvez effectuer une vérification d'intégrité sur les fichiers téléversés :

```shell
sudo gitlab-rake gitlab:artifacts:check
sudo gitlab-rake gitlab:lfs:check
sudo gitlab-rake gitlab:uploads:check
```

Une fois la restauration terminée, il est recommandé de générer des statistiques de base de données pour améliorer les performances de la base de données et éviter les incohérences dans l'interface utilisateur :

1. Accédez à la [console de base de données](https://docs.gitlab.com/omnibus/settings/database/#connecting-to-the-postgresql-database).
1. Exécutez ce qui suit :

   ```sql
   SET STATEMENT_TIMEOUT=0 ; ANALYZE VERBOSE;
   ```

Des discussions sont en cours concernant l'intégration de la commande dans la commande de restauration, voir le [ticket 276184](https://gitlab.com/gitlab-org/gitlab/-/issues/276184) pour plus de détails.

Guides de vérification post-restauration :

- [Vérifier la configuration GitLab](../raketasks/maintenance.md#check-gitlab-configuration)
- [Vérifier que les valeurs de la base de données peuvent être déchiffrées](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets)
- [Vérification de l'intégrité des fichiers téléversés](../raketasks/check.md#uploaded-files-integrity) :

## Restauration pour les installations avec image Docker et Helm chart GitLab {#restore-for-docker-image-and-gitlab-helm-chart-installations}

Pour les installations GitLab utilisant l'image Docker ou le Helm chart GitLab sur un cluster Kubernetes, la tâche de restauration s'attend à ce que les répertoires de restauration soient vides. Cependant, avec les montages de volumes Docker et Kubernetes, certains répertoires système peuvent être créés à la racine des volumes, comme le répertoire `lost+found` présent dans les systèmes d'exploitation Linux. Ces répertoires appartiennent généralement à `root`, ce qui peut entraîner des erreurs de permission d'accès car la tâche Rake de restauration s'exécute en tant qu'utilisateur `git`. Pour restaurer une installation GitLab, les utilisateurs doivent confirmer que les répertoires cibles de restauration sont vides.

Pour ces deux types d'installation, l'archive tar de sauvegarde doit être disponible dans l'emplacement de sauvegarde (l'emplacement par défaut est `/var/opt/gitlab/backups`).

### Restauration pour les installations avec Helm chart {#restore-for-helm-chart-installations}

Le Helm chart GitLab utilise le processus documenté dans [la restauration d'une installation GitLab avec Helm chart](https://docs.gitlab.com/charts/backup-restore/restore/#restoring-a-gitlab-installation)

### Restauration pour les installations avec image Docker {#restore-for-docker-image-installations}

Si vous utilisez [Docker Swarm](../../install/docker/installation.md#install-gitlab-by-using-docker-swarm-mode), le conteneur peut redémarrer pendant le processus de restauration car Puma est arrêté, et par conséquent la vérification de l'état du conteneur échoue. Pour contourner ce problème, désactivez temporairement le mécanisme de vérification de l'état.

1. Modifiez `docker-compose.yml` :

   ```yaml
   healthcheck:
     disable: true
   ```

1. Déployez la pile :

   ```shell
   docker stack deploy --compose-file docker-compose.yml mystack
   ```

Pour plus d'informations, voir [ticket 6846](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6846 "GitLab restore can fail owing to gitlab-healthcheck").

La tâche de restauration peut être exécutée depuis l'hôte :

```shell
# Stop the processes that are connected to the database
docker exec -it <name of container> gitlab-ctl stop puma
docker exec -it <name of container> gitlab-ctl stop sidekiq

# Verify that the processes are all down before continuing
docker exec -it <name of container> gitlab-ctl status

# Run the restore. NOTE: "_gitlab_backup.tar" is omitted from the name
docker exec -it <name of container> gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce

# Restart the GitLab container
docker restart <name of container>

# Check GitLab
docker exec -it <name of container> gitlab-rake gitlab:check SANITIZE=true
```

## Restauration pour les installations compilées manuellement {#restore-for-self-compiled-installations}

1. Assurez-vous d'abord que votre fichier tar de sauvegarde se trouve dans le répertoire de sauvegarde décrit dans la configuration `gitlab.yml` :

   ```yaml
   ## Backup settings
   backup:
     path: "tmp/backups"   # Relative paths are relative to Rails.root (default: tmp/backups/)
   ```

   La valeur par défaut est `/home/git/gitlab/tmp/backups`, et elle doit appartenir à l'utilisateur `git`.

1. Commencez la procédure de sauvegarde :

   ```shell
   # Stop processes that are connected to the database
   sudo service gitlab stop

   sudo -u git -H bundle exec rake gitlab:backup:restore RAILS_ENV=production
   ```

   Exemple de sortie :

   ```plaintext
   Unpacking backup... [DONE]
   Restoring database tables:
   -- create_table("events", {:force=>true})
     -> 0.2231s
   [...]
   - Loading fixture events...[DONE]
   - Loading fixture issues...[DONE]
   - Loading fixture keys...[SKIPPING]
   - Loading fixture merge_requests...[DONE]
   - Loading fixture milestones...[DONE]
   - Loading fixture namespaces...[DONE]
   - Loading fixture notes...[DONE]
   - Loading fixture projects...[DONE]
   - Loading fixture protected_branches...[SKIPPING]
   - Loading fixture schema_migrations...[DONE]
   - Loading fixture services...[SKIPPING]
   - Loading fixture snippets...[SKIPPING]
   - Loading fixture taggings...[SKIPPING]
   - Loading fixture tags...[SKIPPING]
   - Loading fixture users...[DONE]
   - Loading fixture users_projects...[DONE]
   - Loading fixture web_hooks...[SKIPPING]
   - Loading fixture wikis...[SKIPPING]
   Restoring repositories:
   - Restoring repository abcd... [DONE]
   - Object pool 1 ...
   Deleting tmp directories...[DONE]
   ```

1. Restaurez `/home/git/gitlab/.secret` si nécessaire.
1. Redémarrez GitLab :

   ```shell
   sudo service gitlab restart
   ```

## Restauration d'un ou de quelques projets ou groupes seulement à partir d'une sauvegarde {#restoring-only-one-or-a-few-projects-or-groups-from-a-backup}

Bien que la tâche Rake utilisée pour restaurer une instance GitLab ne prenne pas en charge la restauration d'un seul projet ou groupe, vous pouvez utiliser une solution de contournement en restaurant votre sauvegarde vers une instance GitLab temporaire distincte, puis en exportant votre projet ou groupe depuis celle-ci :

1. [Installez une nouvelle instance GitLab](../../install/_index.md) à la même version que l'instance sauvegardée à partir de laquelle vous souhaitez restaurer.
1. Restaurez la sauvegarde dans cette nouvelle instance, puis exportez votre [projet](../../user/project/settings/import_export.md) ou [groupe](../../user/project/settings/import_export.md#migrate-groups-by-uploading-an-export-file-deprecated). Pour plus d'informations sur ce qui est et n'est pas exporté, consultez la documentation de la fonctionnalité d'exportation.
1. Une fois l'exportation terminée, accédez à l'ancienne instance et importez-la.
1. Une fois l'importation des projets ou des groupes souhaités terminée, vous pouvez supprimer la nouvelle instance GitLab temporaire.

Une demande de fonctionnalité pour fournir une restauration directe de projets ou de groupes individuels est en cours de discussion dans le [ticket #17517](https://gitlab.com/gitlab-org/gitlab/-/issues/17517).

## Restauration d'une sauvegarde incrémentielle de dépôt {#restoring-an-incremental-repository-backup}

Lorsque vous créez une [sauvegarde incrémentielle de dépôt](backup_gitlab.md#incremental-repository-backups) à l'aide de `gitlab-backup`, l'archive de sauvegarde résultante contient toutes les données de dépôt nécessaires pour une restauration complète. Pour restaurer, utilisez les mêmes instructions que pour [la restauration de toute autre archive de sauvegarde ordinaire](#restore-for-linux-package-installations).

En interne, les sauvegardes incrémentielles de dépôt ne stockent que les modifications apportées depuis la sauvegarde précédente. Lorsque vous créez une sauvegarde incrémentielle, `gitlab-backup` regroupe toutes les étapes depuis la sauvegarde complète d'origine dans l'archive de sauvegarde. Cela signifie que l'archive est autonome, même si les bundles de sauvegarde de dépôt individuels dépendent les uns des autres.

Avec les [sauvegardes de dépôt côté serveur](backup_gitlab.md#create-server-side-repository-backups), l'archive de sauvegarde ne contient pas de données de dépôt. Au lieu de cela, les données de dépôt sont stockées dans le stockage objet par chaque nœud Gitaly, et chaque incrément est stocké en tant qu'objet distinct. Lors d'une restauration côté serveur, Gitaly lit le manifeste de sauvegarde et applique chaque incrément dans l'ordre.

> [!warning]
> Ne supprimez pas les fichiers de sauvegarde incrémentielle du stockage objet. Si un fichier intermédiaire est supprimé (par exemple, via une politique de cycle de vie du stockage objet), la chaîne de sauvegarde est rompue et la sauvegarde ne peut pas être restaurée.

## Options de restauration {#restore-options}

L'outil en ligne de commande fourni par GitLab pour restaurer depuis une sauvegarde peut accepter plus d'options.

### Spécifier la sauvegarde à restaurer lorsqu'il en existe plusieurs {#specify-backup-to-restore-when-there-are-more-than-one}

Les fichiers de sauvegarde utilisent un schéma de nommage [commençant par un ID de sauvegarde](backup_archive_process.md#backup-id). Lorsqu'il existe plusieurs sauvegardes, vous devez spécifier quel fichier `<backup-id>_gitlab_backup.tar` restaurer en définissant la variable d'environnement `BACKUP=<backup-id>`.

### Désactiver les invites pendant la restauration {#disable-prompts-during-restore}

Lors d'une restauration depuis une sauvegarde, le script de restauration demande une confirmation :

<!-- vale gitlab_base.Spelling = NO -->
- Si le paramètre **Write to authorized_keys** est activé, avant que le script de restauration ne supprime et ne reconstruise le fichier `authorized_keys`.
<!-- vale gitlab_base.Spelling = YES -->
- Lors de la restauration de la base de données, avant que le script de restauration ne supprime toutes les tables existantes.
- Après la restauration de la base de données, s'il y a eu des erreurs lors de la restauration du schéma, avant de continuer car d'autres problèmes sont probables.

Pour désactiver ces invites, définissez la variable d'environnement `GITLAB_ASSUME_YES` à `1`.

- Installations avec paquet Linux :

  ```shell
  sudo GITLAB_ASSUME_YES=1 gitlab-backup restore
  ```

- Installations compilées manuellement :

  ```shell
  sudo -u git -H GITLAB_ASSUME_YES=1 bundle exec rake gitlab:backup:restore RAILS_ENV=production
  ```

La variable d'environnement `force=yes` désactive également ces invites.

### Exclure des tâches lors de la restauration {#excluding-tasks-on-restore}

Vous pouvez exclure des tâches spécifiques lors de la restauration en ajoutant la variable d'environnement `SKIP`, dont les valeurs sont une liste séparée par des virgules des options suivantes :

- `db` (base de données)
- `uploads` (pièces jointes)
- `builds` (journaux de sortie des jobs CI)
- `artifacts` (artefacts de job CI)
- `lfs` (objets LFS)
- `terraform_state` (états Terraform)
- `registry` (images du registre de conteneurs)
- `pages` (contenu Pages)
- `repositories` (données des dépôts Git)
- `packages` (Packages)

Pour exclure des tâches spécifiques :

- Installations avec paquet Linux :

  ```shell
  sudo gitlab-backup restore BACKUP=<backup-id> SKIP=db,uploads
  ```

- Installations compilées manuellement :

  ```shell
  sudo -u git -H bundle exec rake gitlab:backup:restore BACKUP=<backup-id> SKIP=db,uploads RAILS_ENV=production
  ```

### Restaurer des stockages de dépôts spécifiques {#restore-specific-repository-storages}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86896) dans GitLab 15.0.

{{< /history >}}

> [!warning]
> GitLab 17.1 et antérieur sont [affectés par une condition de course](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158412) pouvant entraîner une perte de données. Le problème affecte les dépôts qui ont été dupliqués et utilisent les [pools d'objets](../repository_storage_paths.md#hashed-object-pools) GitLab. Pour éviter toute perte de données, restaurez uniquement les sauvegardes en utilisant GitLab 17.2 ou une version ultérieure.

Lors de l'utilisation de [plusieurs stockages de dépôts](../repository_storage_paths.md), les dépôts de stockages de dépôts spécifiques peuvent être restaurés séparément à l'aide de l'option `REPOSITORIES_STORAGES`. L'option accepte une liste de noms de stockage séparés par des virgules.

Par exemple :

- Installations avec paquet Linux :

  ```shell
  sudo gitlab-backup restore BACKUP=<backup-id> REPOSITORIES_STORAGES=storage1,storage2
  ```

- Installations compilées manuellement :

  ```shell
  sudo -u git -H bundle exec rake gitlab:backup:restore BACKUP=<backup-id> REPOSITORIES_STORAGES=storage1,storage2
  ```

### Restaurer des dépôts spécifiques {#restore-specific-repositories}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88094) dans GitLab 15.1.

{{< /history >}}

> [!warning]
> GitLab 17.1 et antérieur sont [affectés par une condition de course](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158412) pouvant entraîner une perte de données. Le problème affecte les dépôts qui ont été dupliqués et utilisent les [pools d'objets](../repository_storage_paths.md#hashed-object-pools) GitLab. Pour éviter toute perte de données, restaurez uniquement les sauvegardes en utilisant GitLab 17.2 ou une version ultérieure.

Vous pouvez restaurer des dépôts spécifiques à l'aide des options `REPOSITORIES_PATHS` et `SKIP_REPOSITORIES_PATHS`. Les deux options acceptent une liste de chemins de projet et de groupe séparés par des virgules. Si vous spécifiez un chemin de groupe, tous les dépôts de tous les projets du groupe et des groupes descendants sont inclus ou ignorés, selon l'option utilisée. Les groupes et les projets doivent exister dans la sauvegarde spécifiée ou sur l'instance cible.

> [!note]
> Les options `REPOSITORIES_PATHS` et `SKIP_REPOSITORIES_PATHS` s'appliquent uniquement aux dépôts Git. Elles ne s'appliquent pas aux entrées de base de données de projet ou de groupe. Si vous avez créé une sauvegarde de dépôts avec `SKIP=db`, elle ne peut pas être utilisée seule pour restaurer des dépôts spécifiques vers une nouvelle instance.

Par exemple, pour restaurer tous les dépôts de tous les projets du Groupe A (`group-a`), le dépôt du Projet C dans le Groupe B (`group-b/project-c`), et ignorer le Projet D dans le Groupe A (`group-a/project-d`) :

- Installations avec paquet Linux :

  ```shell
  sudo gitlab-backup restore BACKUP=<backup-id> REPOSITORIES_PATHS=group-a,group-b/project-c SKIP_REPOSITORIES_PATHS=group-a/project-d
  ```

- Installations compilées manuellement :

  ```shell
  sudo -u git -H bundle exec rake gitlab:backup:restore BACKUP=<backup-id> REPOSITORIES_PATHS=group-a,group-b/project-c SKIP_REPOSITORIES_PATHS=group-a/project-d
  ```

### Restaurer des sauvegardes non archivées {#restore-untarred-backups}

Si une [sauvegarde non archivée](backup_gitlab.md#skipping-tar-creation) (créée avec `SKIP=tar`) est trouvée et qu'aucune sauvegarde n'est choisie avec `BACKUP=<backup-id>`, la sauvegarde non archivée est utilisée.

Par exemple :

- Installations avec paquet Linux :

  ```shell
  sudo gitlab-backup restore
  ```

- Installations compilées manuellement :

  ```shell
  sudo -u git -H bundle exec rake gitlab:backup:restore
  ```

### Restauration à l'aide de sauvegardes de dépôts côté serveur {#restoring-using-server-side-repository-backups}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitaly/-/issues/4941) dans `gitlab-backup` dans GitLab 16.3.
- Prise en charge côté serveur dans `gitlab-backup` pour la restauration d'une sauvegarde spécifiée plutôt que la dernière sauvegarde [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132188) dans GitLab 16.6.
- Prise en charge côté serveur dans `gitlab-backup` pour la création de sauvegardes incrémentielles [introduite](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6475) dans GitLab 16.6.
- Prise en charge côté serveur dans `backup-utility` [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/438393) dans GitLab 17.0.

{{< /history >}}

Lorsqu'une sauvegarde côté serveur est collectée, le processus de restauration utilise par défaut le mécanisme de restauration côté serveur présenté dans [Créer des sauvegardes de dépôts côté serveur](backup_gitlab.md#create-server-side-repository-backups). Vous pouvez configurer la restauration des sauvegardes de sorte que le nœud Gitaly qui héberge chaque dépôt soit responsable d'extraire les données de sauvegarde nécessaires directement depuis le stockage objet.

1. [Configurer une destination de sauvegarde côté serveur dans Gitaly](../gitaly/configure_gitaly.md#configure-server-side-backups).
1. Démarrez un processus de restauration de sauvegarde côté serveur en spécifiant l'[ID de la sauvegarde](backup_archive_process.md#backup-id) que vous souhaitez restaurer :

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
sudo gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce
```

{{< /tab >}}

{{< tab title="Compilé manuellement" >}}

```shell
sudo -u git -H bundle exec rake gitlab:backup:restore BACKUP=11493107454_2018_04_25_10.6.4-ce
```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --restore -t <backup_ID> --repositories-server-side
```

Lors de l'utilisation des [sauvegardes basées sur cron](https://docs.gitlab.com/charts/backup-restore/backup/#cron-based-backup), ajoutez le drapeau `--repositories-server-side` aux arguments supplémentaires.

{{< /tab >}}

{{< /tabs >}}

## Dépannage {#troubleshooting}

Voici les problèmes possibles que vous pourriez rencontrer, ainsi que les solutions potentielles.

### Restauration de la sauvegarde de base de données avec des avertissements en sortie d'une installation avec paquet Linux {#restoring-database-backup-using-output-warnings-from-a-linux-package-installation}

Si vous utilisez des procédures de restauration de sauvegarde, vous pouvez rencontrer les messages d'avertissement suivants :

```plaintext
ERROR: must be owner of extension pg_trgm
ERROR: must be owner of extension btree_gist
ERROR: must be owner of extension plpgsql
WARNING:  no privileges could be revoked for "public" (two occurrences)
WARNING:  no privileges were granted for "public" (two occurrences)
```

Sachez que la sauvegarde est restaurée avec succès malgré ces messages d'avertissement.

La tâche Rake s'exécute en tant qu'utilisateur `gitlab`, qui ne dispose pas d'un accès superutilisateur à la base de données. Lorsque la restauration est initiée, elle s'exécute également en tant qu'utilisateur `gitlab`, mais elle tente également de modifier les objets auxquels elle n'a pas accès. Ces objets n'ont aucune influence sur la sauvegarde ou la restauration de la base de données, mais affichent un message d'avertissement.

Pour plus d'informations, voir :

- Outil de suivi des tickets PostgreSQL :
  - [Ne pas être un superutilisateur](https://www.postgresql.org/message-id/201110220712.30886.adrian.klaver@gmail.com).
  - [Avoir des propriétaires différents](https://www.postgresql.org/message-id/2039.1177339749@sss.pgh.pa.us).
- Stack Overflow :  [Erreurs résultantes](https://stackoverflow.com/questions/4368789/error-must-be-owner-of-language-plpgsql).

### La restauration échoue en raison d'un hook de serveur Git {#restoring-fails-due-to-git-server-hook}

Lors de la restauration depuis une sauvegarde, vous pouvez rencontrer une erreur lorsque les conditions suivantes sont vraies :

- Un hook de serveur Git (`custom_hook`) est configuré à l'aide de la méthode pour [GitLab version 15.10 et antérieure](../server_hooks.md)
- Votre version de GitLab est la version 15.11 ou ultérieure
- Vous avez créé des liens symboliques vers un répertoire en dehors des emplacements gérés par GitLab

L'erreur ressemble à :

```plaintext
{"level":"fatal","msg":"restore: pipeline: 1 failures encountered:\n - @hashed/path/to/hashed_repository.git (path/to_project): manager: restore custom hooks, \"@hashed/path/to/hashed_repository/<BackupID>_<GitLabVersion>-ee/001.custom_hooks.tar\": rpc error: code = Internal desc = setting custom hooks: generating prepared vote: walking directory: copying file to hash: read /mnt/gitlab-app/git-data/repositories/+gitaly/tmp/default-repositories.old.<timestamp>.<temporaryfolder>/custom_hooks/compliance-triggers.d: is a directory\n","pid":3256017,"time":"2023-08-10T20:09:44.395Z"}
```

Pour résoudre ce problème, vous pouvez mettre à jour les [hooks de serveur](../server_hooks.md) Git pour GitLab version 15.11 et ultérieure, et créer une nouvelle sauvegarde.

### Restauration réussie avec des dépôts affichés comme vides lors de l'utilisation de `fapolicyd` {#successful-restore-with-repositories-showing-as-empty-when-using-fapolicyd}

Lors de l'utilisation de `fapolicyd` pour une sécurité accrue, GitLab peut indiquer que la restauration a réussi, mais les dépôts s'affichent comme vides. Pour plus d'aide sur la résolution des problèmes, consultez la [documentation de dépannage de Gitaly](../gitaly/troubleshooting.md#repositories-are-shown-as-empty-after-a-gitlab-restore).
