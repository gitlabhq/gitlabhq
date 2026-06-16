---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sauvegarder et restaurer les grandes architectures de référence
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les sauvegardes GitLab préservent la cohérence des données et permettent la reprise après sinistre pour les déploiements GitLab à grande échelle. Ce processus :

- Coordonne les sauvegardes de données entre les composants de stockage distribués
- Préserve les bases de données PostgreSQL allant jusqu'à plusieurs téraoctets
- Protège les données de stockage d'objets dans les services externes
- Maintient l'intégrité des sauvegardes pour les grandes collections de dépôts Git
- Crée des copies récupérables des fichiers de configuration et des fichiers secrets
- Permet la restauration des données système avec un temps d'arrêt minimal

Suivez ces procédures pour les environnements GitLab exécutant des architectures de référence prenant en charge 3 000 utilisateurs et plus, avec des considérations particulières pour les bases de données et le stockage d'objets dans le cloud.

> [!note]
> Ce document est destiné aux environnements utilisant :
>
> - [Architectures de référence hybrides cloud-native et package Linux (Omnibus) 60 RPS / 3 000 utilisateurs et plus](../reference_architectures/_index.md)
> - [Amazon RDS](https://aws.amazon.com/rds/) pour les données PostgreSQL
> - [Amazon S3](https://aws.amazon.com/s3/) pour le stockage d'objets
> - [Stockage d'objets](../object_storage.md) pour stocker tout ce qui est possible, y compris les [blobs](backup_gitlab.md#blobs) et le [registre de conteneurs](backup_gitlab.md#container-registry)

## Configurer les sauvegardes quotidiennes {#configure-daily-backups}

### Configurer la sauvegarde des données PostgreSQL {#configure-backup-of-postgresql-data}

La [commande de sauvegarde](backup_gitlab.md) utilise `pg_dump`, qui n'est [pas appropriée pour les bases de données de plus de 100 Go](backup_gitlab.md#postgresql-databases). Vous devez choisir une solution PostgreSQL disposant de capacités de sauvegarde natives et robustes.

{{< tabs >}}

{{< tab title="AWS" >}}

1. [Configurez AWS Backup](https://docs.aws.amazon.com/aws-backup/latest/devguide/creating-a-backup-plan.html) pour sauvegarder les données RDS (et S3). Pour une protection maximale, [configurez les sauvegardes continues ainsi que les sauvegardes par instantané](https://docs.aws.amazon.com/aws-backup/latest/devguide/point-in-time-recovery.html).
1. Configurez AWS Backup pour copier les sauvegardes vers une région distincte. Lorsqu'AWS effectue une sauvegarde, celle-ci ne peut être restaurée que dans la région où elle est stockée.
1. Une fois qu'AWS Backup a exécuté au moins une sauvegarde planifiée, vous pouvez [créer une sauvegarde à la demande](https://docs.aws.amazon.com/aws-backup/latest/devguide/recov-point-create-on-demand-backup.html) selon vos besoins.

{{< /tab >}}

{{< tab title="Google" >}}

Planifiez les [sauvegardes quotidiennes automatisées des données Google Cloud SQL](https://cloud.google.com/sql/docs/postgres/backup-recovery/backing-up#schedulebackups). Les sauvegardes quotidiennes [peuvent être conservées](https://cloud.google.com/sql/docs/postgres/backup-recovery/backups#retention) pendant jusqu'à un an, et les journaux de transactions peuvent être conservés pendant 7 jours par défaut pour la récupération à un instant précis.

{{< /tab >}}

{{< /tabs >}}

### Configurer la sauvegarde des données de stockage d'objets {#configure-backup-of-object-storage-data}

[Le stockage d'objets](../object_storage.md) , ([pas NFS](../nfs.md) ) est recommandé pour stocker les données GitLab, y compris les [blobs](backup_gitlab.md#blobs) et le [registre de conteneurs](backup_gitlab.md#container-registry).

{{< tabs >}}

{{< tab title="AWS" >}}

Configurez AWS Backup pour sauvegarder les données S3. Cela peut être fait en même temps que la [configuration de la sauvegarde des données PostgreSQL](#configure-backup-of-postgresql-data).

{{< /tab >}}

{{< tab title="Google" >}}

1. [Créez un bucket de sauvegarde dans GCS](https://cloud.google.com/storage/docs/creating-buckets).
1. [Créez des tâches Storage Transfer Service](https://cloud.google.com/storage-transfer/docs/create-transfers) qui copient chaque bucket de stockage d'objets GitLab vers un bucket de sauvegarde. Vous pouvez créer ces jobs une seule fois, et [les planifier pour s'exécuter quotidiennement](https://cloud.google.com/storage-transfer/docs/schedule-transfer-jobs). Cependant, cela mélange les données de stockage d'objets nouvelles et anciennes, de sorte que les fichiers supprimés dans GitLab existeront toujours dans la sauvegarde. Cela gaspille de l'espace de stockage après la restauration, mais ce n'est pas un problème par ailleurs. Ces fichiers seraient inaccessibles aux utilisateurs GitLab car ils n'existent pas dans la base de données GitLab. Vous pouvez supprimer [certains de ces fichiers orphelins](../raketasks/cleanup.md#clean-up-project-upload-files-from-object-storage) après la restauration, mais cette tâche Rake de nettoyage ne fonctionne que sur un sous-ensemble de fichiers.
   1. Pour `When to overwrite`, choisissez `Never`. Les fichiers stockés dans les objets GitLab sont destinés à être immuables. Cette sélection pourrait être utile si un acteur malveillant réussissait à modifier les fichiers GitLab.
   1. Pour `When to delete`, choisissez `Never`. Si vous synchronisez le bucket de sauvegarde avec la source, vous ne pourrez pas récupérer les fichiers supprimés accidentellement ou de manière malveillante depuis la source.
1. Il est également possible de sauvegarder le stockage d'objets dans des buckets ou des sous-répertoires séparés par jour. Cela évite le problème des fichiers orphelins après la restauration et prend en charge la sauvegarde des versions de fichiers si nécessaire. Mais cela augmente considérablement les coûts de stockage des sauvegardes. Cela peut être fait avec [une Cloud Function déclenchée par Cloud Scheduler](https://cloud.google.com/scheduler/docs/tut-gcf-pub-sub), ou avec un script exécuté par une tâche cron. Un exemple partiel :

   ```shell
   # Set GCP project so you don't have to specify it in every command
   gcloud config set project example-gcp-project-name

   # Grant the Storage Transfer Service's hidden service account permission to write to the backup bucket. The integer 123456789012 is the GCP project's ID.
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.objectAdmin gs://backup-bucket

   # Grant the Storage Transfer Service's hidden service account permission to list and read objects in the source buckets. The integer 123456789012 is the GCP project's ID.
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-artifacts
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-ci-secure-files
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-dependency-proxy
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-lfs
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-mr-diffs
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-packages
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-pages
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-registry
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-terraform-state
   gsutil iam ch serviceAccount:project-123456789012@storage-transfer-service.iam.gserviceaccount.com:roles/storage.legacyBucketReader,roles/storage.objectViewer gs://gitlab-bucket-uploads

   # Create transfer jobs for each bucket, targeting a subdirectory in the backup bucket.
   today=$(date +%F)
   gcloud transfer jobs create gs://gitlab-bucket-artifacts/ gs://backup-bucket/$today/artifacts/ --name "$today-backup-artifacts"
   gcloud transfer jobs create gs://gitlab-bucket-ci-secure-files/ gs://backup-bucket/$today/ci-secure-files/ --name "$today-backup-ci-secure-files"
   gcloud transfer jobs create gs://gitlab-bucket-dependency-proxy/ gs://backup-bucket/$today/dependency-proxy/ --name "$today-backup-dependency-proxy"
   gcloud transfer jobs create gs://gitlab-bucket-lfs/ gs://backup-bucket/$today/lfs/ --name "$today-backup-lfs"
   gcloud transfer jobs create gs://gitlab-bucket-mr-diffs/ gs://backup-bucket/$today/mr-diffs/ --name "$today-backup-mr-diffs"
   gcloud transfer jobs create gs://gitlab-bucket-packages/ gs://backup-bucket/$today/packages/ --name "$today-backup-packages"
   gcloud transfer jobs create gs://gitlab-bucket-pages/ gs://backup-bucket/$today/pages/ --name "$today-backup-pages"
   gcloud transfer jobs create gs://gitlab-bucket-registry/ gs://backup-bucket/$today/registry/ --name "$today-backup-registry"
   gcloud transfer jobs create gs://gitlab-bucket-terraform-state/ gs://backup-bucket/$today/terraform-state/ --name "$today-backup-terraform-state"
   gcloud transfer jobs create gs://gitlab-bucket-uploads/ gs://backup-bucket/$today/uploads/ --name "$today-backup-uploads"
   ```

   1. Ces Transfer Jobs ne sont pas automatiquement supprimés après leur exécution. Vous pouvez implémenter le nettoyage des anciens jobs dans le script.
   1. L'exemple de script ne supprime pas les anciennes sauvegardes. Vous pouvez implémenter le nettoyage des anciennes sauvegardes selon votre politique de rétention souhaitée.
1. Assurez-vous que les sauvegardes sont effectuées au même moment ou après les sauvegardes Cloud SQL, afin de réduire les incohérences de données.

{{< /tab >}}

{{< /tabs >}}

### Configurer la sauvegarde des dépôts Git {#configure-backup-of-git-repositories}

Configurez des tâches cron pour effectuer des sauvegardes côté serveur Gitaly :

{{< tabs >}}

{{< tab title="Package Linux (Omnibus)" >}}

1. Configurez la destination de sauvegarde côté serveur Gitaly sur tous les nœuds Gitaly en suivant [Configurer les sauvegardes côté serveur](../gitaly/configure_gitaly.md#configure-server-side-backups). Ce bucket est utilisé exclusivement par Gitaly pour stocker les données du dépôt.
1. Pendant que Gitaly sauvegarde toutes les données du dépôt Git dans son bucket de stockage d'objets désigné configuré précédemment, l'outil utilitaire de sauvegarde (`gitlab-backup`) charge des données de sauvegarde supplémentaires. Ces données comprennent un fichier `tar` contenant des métadonnées essentielles pour les restaurations. Vous pouvez utiliser le même bucket que les autres sauvegardes ou un bucket séparé. Assurez-vous que ces données de sauvegarde sont correctement chargées vers le stockage distant (cloud) en suivant [Charger les sauvegardes vers un stockage distant (cloud)](backup_gitlab.md#upload-backups-to-a-remote-cloud-storage) pour configurer le bucket de chargement.
1. (Facultatif) Pour renforcer la durabilité de ces données de sauvegarde, sauvegardez tous les buckets configurés précédemment avec leur fournisseur de stockage d'objets respectif en les ajoutant aux [sauvegardes des données de stockage d'objets](#configure-backup-of-object-storage-data).
1. Connectez-vous en SSH à un nœud GitLab Rails, qui est un nœud exécutant Puma ou Sidekiq.
1. Effectuez une sauvegarde complète de vos données Git. Utilisez la variable `REPOSITORIES_SERVER_SIDE` et ignorez les données PostgreSQL :

   ```shell
   sudo gitlab-backup create REPOSITORIES_SERVER_SIDE=true SKIP=db
   ```

   Cela amène les nœuds Gitaly à charger les données Git et certaines métadonnées vers le stockage distant. Les blobs tels que les chargements, les artefacts et LFS n'ont pas besoin d'être explicitement ignorés, car la commande `gitlab-backup` ne sauvegarde pas le stockage d'objets par défaut.

1. Notez l'[ID de sauvegarde](backup_archive_process.md#backup-id) de la sauvegarde, qui est nécessaire pour l'étape suivante. Par exemple, si la commande de sauvegarde génère `2024-02-22 02:17:47 UTC -- Backup 1708568263_2024_02_22_16.9.0-ce is done.`, l'ID de sauvegarde est `1708568263_2024_02_22_16.9.0-ce`.
1. Vérifiez que la sauvegarde complète a créé des données à la fois dans le bucket de sauvegarde Gitaly et dans le bucket de sauvegarde habituel.
1. Exécutez à nouveau la [commande de sauvegarde](backup_gitlab.md#backup-command) , cette fois en spécifiant la [sauvegarde incrémentielle des dépôts Git](backup_gitlab.md#incremental-repository-backups) et un ID de sauvegarde. En utilisant l'exemple d'ID de l'étape précédente, la commande est :

   ```shell
   sudo gitlab-backup create REPOSITORIES_SERVER_SIDE=true SKIP=db INCREMENTAL=yes PREVIOUS_BACKUP=1708568263_2024_02_22_16.9.0-ce
   ```

   La valeur de `PREVIOUS_BACKUP` n'est pas utilisée par cette commande, mais elle est requise par la commande. Il existe un ticket pour supprimer cette exigence inutile, voir [ticket 429141](https://gitlab.com/gitlab-org/gitlab/-/issues/429141).

1. Vérifiez que la sauvegarde incrémentielle a réussi et que des données ont été ajoutées au stockage d'objets.
1. [Configurez cron pour effectuer des sauvegardes quotidiennes](backup_gitlab.md#configuring-cron-to-make-daily-backups). Modifiez la crontab pour l'utilisateur `root` :

   ```shell
   sudo su -
   crontab -e
   ```

1. Ajoutez-y les lignes suivantes pour planifier la sauvegarde tous les jours de chaque mois à 2h00. Pour limiter le nombre d'incréments nécessaires pour restaurer une sauvegarde, une sauvegarde complète des dépôts Git sera effectuée le premier de chaque mois, et les jours restants effectueront une sauvegarde incrémentielle :

   ```plaintext
   0 2 1 * * /opt/gitlab/bin/gitlab-backup create REPOSITORIES_SERVER_SIDE=true SKIP=db CRON=1
   0 2 2-31 * * /opt/gitlab/bin/gitlab-backup create REPOSITORIES_SERVER_SIDE=true SKIP=db INCREMENTAL=yes PREVIOUS_BACKUP=1708568263_2024_02_22_16.9.0-ce CRON=1
   ```

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Configurez la destination de sauvegarde côté serveur Gitaly sur tous les nœuds Gitaly en suivant [Configurer les sauvegardes côté serveur](../gitaly/configure_gitaly.md#configure-server-side-backups). Ce bucket est utilisé exclusivement par Gitaly pour stocker les données du dépôt.
1. Pendant que Gitaly sauvegarde toutes les données du dépôt Git dans son bucket de stockage d'objets désigné configuré précédemment, l'outil utilitaire de sauvegarde (`gitlab-backup`) charge des données de sauvegarde supplémentaires. Ces données comprennent un fichier `tar` contenant des métadonnées essentielles pour les restaurations. Vous pouvez utiliser le même bucket que les autres sauvegardes ou un bucket séparé. Assurez-vous que ces données de sauvegarde sont correctement chargées vers le stockage distant (cloud) en suivant [Charger les sauvegardes vers un stockage distant (cloud)](backup_gitlab.md#upload-backups-to-a-remote-cloud-storage) pour configurer le bucket de chargement.
1. (Facultatif) Pour renforcer la durabilité de ces données de sauvegarde, tous les buckets configurés précédemment peuvent être sauvegardés par leur fournisseur de stockage d'objets respectif en les ajoutant aux [sauvegardes des données de stockage d'objets](#configure-backup-of-object-storage-data).
1. Connectez-vous en SSH à un nœud GitLab Rails, qui est un nœud exécutant Puma ou Sidekiq.
1. Effectuez une sauvegarde complète de vos données Git. Utilisez la variable `REPOSITORIES_SERVER_SIDE` et ignorez toutes les autres données :

   ```shell
   kubectl exec <Toolbox pod name> -it -- backup-utility --repositories-server-side --skip db,builds,pages,registry,uploads,artifacts,lfs,packages,external_diffs,terraform_state,pages,ci_secure_files
   ```

   Cela amène les nœuds Gitaly à charger les données Git et certaines métadonnées vers le stockage distant. Consultez [les outils inclus dans Toolbox](https://docs.gitlab.com/charts/charts/gitlab/toolbox/#toolbox-included-tools).

1. Vérifiez que la sauvegarde complète a créé des données à la fois dans le bucket de sauvegarde Gitaly et dans le bucket de sauvegarde habituel. La sauvegarde incrémentielle du dépôt n'est pas prise en charge par `backup-utility` avec la sauvegarde du dépôt côté serveur, voir [charts issue 3421](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3421).
1. [Configurez cron pour effectuer des sauvegardes quotidiennes](https://docs.gitlab.com/charts/backup-restore/backup/#cron-based-backup). Plus précisément, définissez `gitlab.toolbox.backups.cron.extraArgs` pour inclure :

   ```shell
   --repositories-server-side --skip db --skip repositories --skip uploads --skip builds --skip artifacts --skip pages --skip lfs --skip terraform_state --skip registry --skip packages --skip ci_secure_files
   ```

{{< /tab >}}

{{< /tabs >}}

### Configurer la sauvegarde des fichiers de configuration {#configure-backup-of-configuration-files}

Si votre configuration et vos secrets sont définis en dehors de votre déploiement puis déployés dans celui-ci, l'implémentation de la stratégie de sauvegarde dépend de votre configuration et de vos exigences spécifiques. Par exemple, vous pouvez stocker des secrets dans [AWS Secret Manager](https://aws.amazon.com/secrets-manager/) avec [réplication dans plusieurs régions](https://docs.aws.amazon.com/secretsmanager/latest/userguide/create-manage-multi-region-secrets.html) et configurer un script pour sauvegarder les secrets automatiquement.

Si votre configuration et vos secrets sont uniquement définis dans votre déploiement :

1. [Stocker les fichiers de configuration](backup_gitlab.md#storing-configuration-files) décrit comment extraire les fichiers de configuration et les fichiers secrets.
1. Ces fichiers doivent être chargés vers un compte de stockage d'objets distinct, plus restrictif.

## Restaurer une sauvegarde {#restore-a-backup}

Restaurez une sauvegarde d'une instance GitLab.

### Prérequis {#prerequisites}

Avant de restaurer une sauvegarde :

1. Choisissez une [instance GitLab de destination fonctionnelle](restore_gitlab.md#the-destination-gitlab-instance-must-already-be-working).
1. Assurez-vous que l'instance GitLab de destination se trouve dans une région où vos sauvegardes AWS sont stockées.
1. Vérifiez que l'[instance GitLab de destination utilise exactement la même version et le même type (CE ou EE) de GitLab](restore_gitlab.md#the-destination-gitlab-instance-must-have-the-exact-same-version) sur lequel les données de sauvegarde ont été créées. Par exemple, CE 15.1.4.
1. [Restaurez les secrets sauvegardés vers l'instance GitLab de destination](restore_gitlab.md#gitlab-secrets-must-be-restored).
1. Assurez-vous que l'[instance GitLab de destination dispose des mêmes stockages de dépôts configurés](restore_gitlab.md#certain-gitlab-configuration-must-match-the-original-backed-up-environment). Des stockages supplémentaires sont acceptables.
1. Assurez-vous que le [stockage d'objets est configuré](restore_gitlab.md#certain-gitlab-configuration-must-match-the-original-backed-up-environment).
1. Pour utiliser de nouveaux secrets ou une nouvelle configuration, et pour éviter de gérer des changements de configuration inattendus lors de la restauration :

   - Installations du package Linux sur tous les nœuds :
     1. [Reconfigurez](../restart_gitlab.md#reconfigure-a-linux-package-installation) l'instance GitLab de destination.
     1. [Redémarrez](../restart_gitlab.md#restart-a-linux-package-installation) l'instance GitLab de destination.

   - Installations avec chart Helm (Kubernetes) :

     1. Sur tous les nœuds du package Linux GitLab, exécutez :

        ```shell
        sudo gitlab-ctl reconfigure
        sudo gitlab-ctl start
        ```

     1. Assurez-vous d'avoir une instance GitLab en cours d'exécution en déployant les charts. Assurez-vous que le pod Toolbox est activé et en cours d'exécution en exécutant la commande suivante :

        ```shell
        kubectl get pods -lrelease=RELEASE_NAME,app=toolbox
        ```

     1. Les pods Webservice, Sidekiq et Toolbox doivent être redémarrés. La façon la plus sûre de redémarrer ces pods est d'exécuter :

        ```shell
        kubectl delete pods -lapp=sidekiq,release=<helm release name>
        kubectl delete pods -lapp=webservice,release=<helm release name>
        kubectl delete pods -lapp=toolbox,release=<helm release name>
        ```

1. Confirmez que l'instance GitLab de destination fonctionne toujours. Par exemple :

   - Effectuez des requêtes vers les [points de terminaison de vérification d'état](../monitoring/health_check.md).
   - [Exécutez les tâches Rake de vérification GitLab](../raketasks/maintenance.md#check-gitlab-configuration).

1. Arrêtez les services GitLab qui se connectent à la base de données PostgreSQL.

   - Installations du package Linux sur tous les nœuds exécutant Puma ou Sidekiq, exécutez :

     ```shell
     sudo gitlab-ctl stop
     ```

   - Installations avec chart Helm (Kubernetes) :

     1. Notez le nombre actuel de réplicas pour les clients de base de données pour le redémarrage ultérieur :

        ```shell
        kubectl get deploy -n <namespace> -lapp=sidekiq,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
        kubectl get deploy -n <namespace> -lapp=webservice,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
        kubectl get deploy -n <namespace> -lapp=prometheus,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
        ```

     1. Arrêtez les clients de la base de données pour empêcher les verrous d'interférer avec le processus de restauration :

        ```shell
        kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=0
        kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=0
        kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=0
        ```

### Restaurer les données de stockage d'objets {#restore-object-storage-data}

{{< tabs >}}

{{< tab title="AWS" >}}

Chaque bucket existe en tant que sauvegarde distincte dans AWS et chaque sauvegarde peut être restaurée vers un bucket existant ou nouveau.

1. Pour restaurer des buckets, un rôle IAM avec les autorisations appropriées est requis :

   - `AWSBackupServiceRolePolicyForBackup`
   - `AWSBackupServiceRolePolicyForRestores`
   - `AWSBackupServiceRolePolicyForS3Restore`
   - `AWSBackupServiceRolePolicyForS3Backup`

1. Si des buckets existants sont utilisés, ils doivent avoir les [listes de contrôle d'accès activées](https://docs.aws.amazon.com/AmazonS3/latest/userguide/managing-acls.html).
1. [Restaurez les buckets S3 à l'aide des outils intégrés](https://docs.aws.amazon.com/aws-backup/latest/devguide/restoring-s3.html).
1. Vous pouvez passer à [Restaurer les données PostgreSQL](#restore-postgresql-data) pendant que le job de restauration est en cours d'exécution.

{{< /tab >}}

{{< tab title="Google" >}}

1. [Créez des tâches Storage Transfer Service](https://cloud.google.com/storage-transfer/docs/create-transfers) pour transférer les données sauvegardées vers les buckets GitLab.
1. Vous pouvez passer à [Restaurer les données PostgreSQL](#restore-postgresql-data) pendant que les tâches de transfert sont en cours d'exécution.

{{< /tab >}}

{{< /tabs >}}

### Restaurer les données PostgreSQL {#restore-postgresql-data}

{{< tabs >}}

{{< tab title="AWS" >}}

1. [Restaurez la base de données AWS RDS à l'aide des outils intégrés](https://docs.aws.amazon.com/aws-backup/latest/devguide/restoring-rds.html), ce qui crée une nouvelle instance RDS.
1. Étant donné que la nouvelle instance RDS a un point de terminaison différent, vous devez reconfigurer l'instance GitLab de destination pour pointer vers la nouvelle base de données :

   - Pour les installations du package Linux, suivez [Utilisation d'un serveur de gestion de base de données PostgreSQL non packagé](https://docs.gitlab.com/omnibus/settings/database/#using-a-non-packaged-postgresql-database-management-server).

   - Pour les installations avec chart Helm (Kubernetes), suivez [Configurer le chart GitLab avec une base de données externe](https://docs.gitlab.com/charts/advanced/external-db/).

1. Avant de continuer, attendez que la nouvelle instance RDS soit créée et prête à l'emploi.

{{< /tab >}}

{{< tab title="Google" >}}

1. [Restaurez la base de données Google Cloud SQL à l'aide des outils intégrés](https://cloud.google.com/sql/docs/postgres/backup-recovery/restoring).
1. Si vous restaurez vers une nouvelle instance de base de données, reconfigurez GitLab pour pointer vers la nouvelle base de données :

   - Pour les installations du package Linux, suivez [Utilisation d'un serveur de gestion de base de données PostgreSQL non packagé](https://docs.gitlab.com/omnibus/settings/database/#using-a-non-packaged-postgresql-database-management-server).

   - Pour les installations avec chart Helm (Kubernetes), suivez [Configurer le chart GitLab avec une base de données externe](https://docs.gitlab.com/charts/advanced/external-db/).

1. Avant de continuer, attendez que l'instance Cloud SQL soit prête à l'emploi.

{{< /tab >}}

{{< /tabs >}}

### Restaurer les dépôts Git {#restore-git-repositories}

Premièrement, dans le cadre de [Restaurer les données de stockage d'objets](#restore-object-storage-data), vous devriez avoir déjà :

- Restauré un bucket contenant les sauvegardes côté serveur Gitaly des dépôts Git.
- Restauré un bucket contenant les fichiers `*_gitlab_backup.tar`.

{{< tabs >}}

{{< tab title="Package Linux (Omnibus)" >}}

1. Connectez-vous en SSH à un nœud GitLab Rails, qui est un nœud exécutant Puma ou Sidekiq.
1. Dans votre bucket de sauvegarde, choisissez un fichier `*_gitlab_backup.tar` en fonction de son horodatage, aligné avec les données PostgreSQL et de stockage d'objets que vous avez restaurées.
1. Téléchargez le fichier `tar` dans `/var/opt/gitlab/backups/`.
1. Restaurez la sauvegarde en spécifiant l'ID de la sauvegarde que vous souhaitez restaurer, en omettant `_gitlab_backup.tar` du nom :

   ```shell
   # This command will overwrite the contents of your GitLab database!
   sudo gitlab-backup restore BACKUP=11493107454_2018_04_25_10.6.4-ce SKIP=db
   ```

   Si la version de GitLab de votre fichier tar de sauvegarde ne correspond pas à la version installée de GitLab, la commande de restauration s'interrompt avec un message d'erreur. Installez la [version correcte de GitLab](https://packages.gitlab.com/ui/browse/gitlab), puis réessayez.

1. Reconfigurez, démarrez et [vérifiez](../raketasks/maintenance.md#check-gitlab-configuration) GitLab :

   1. Sur tous les nœuds PostgreSQL, exécutez :

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. Sur tous les nœuds Puma ou Sidekiq, exécutez :

      ```shell
      sudo gitlab-ctl start
      ```

   1. Sur un nœud Puma ou Sidekiq, exécutez :

      ```shell
      sudo gitlab-rake gitlab:check SANITIZE=true
      ```

1. Vérifiez que les [valeurs de la base de données peuvent être déchiffrées](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets), surtout si `/etc/gitlab/gitlab-secrets.json` a été restauré, ou si un serveur différent est la cible de la restauration :

   Sur un nœud Puma ou Sidekiq, exécutez :

   ```shell
   sudo gitlab-rake gitlab:doctor:secrets
   ```

1. Pour plus de certitude, vous pouvez effectuer [une vérification d'intégrité des fichiers chargés](../raketasks/check.md#uploaded-files-integrity) :

   Sur un nœud Puma ou Sidekiq, exécutez :

   ```shell
   sudo gitlab-rake gitlab:artifacts:check
   sudo gitlab-rake gitlab:lfs:check
   sudo gitlab-rake gitlab:uploads:check
   ```

   Si des fichiers manquants ou corrompus sont trouvés, cela ne signifie pas toujours que le processus de sauvegarde et de restauration a échoué. Par exemple, les fichiers peuvent être manquants ou corrompus sur l'instance GitLab source. Vous devrez peut-être consulter les sauvegardes précédentes. Si vous migrez GitLab vers un nouvel environnement, vous pouvez exécuter les mêmes vérifications sur l'instance GitLab source pour déterminer si le résultat de la vérification d'intégrité est préexistant ou lié au processus de sauvegarde et de restauration.

{{< /tab >}}

{{< tab title="Chart Helm (Kubernetes)" >}}

1. Connectez-vous en SSH à un pod toolbox.
1. Dans votre bucket de sauvegarde, choisissez un fichier `*_gitlab_backup.tar` en fonction de son horodatage, aligné avec les données PostgreSQL et de stockage d'objets que vous avez restaurées.
1. Téléchargez le fichier `tar` dans `/var/opt/gitlab/backups/`.
1. Restaurez la sauvegarde en spécifiant l'ID de la sauvegarde que vous souhaitez restaurer, en omettant `_gitlab_backup.tar` du nom :

   ```shell
   # This command will overwrite the contents of Gitaly!
   kubectl exec <Toolbox pod name> -it -- backup-utility --restore -t 11493107454_2018_04_25_10.6.4-ce --skip db,builds,pages,registry,uploads,artifacts,lfs,packages,external_diffs,terraform_state,pages,ci_secure_files
   ```

   Si la version de GitLab de votre fichier tar de sauvegarde ne correspond pas à la version installée de GitLab, la commande de restauration s'interrompt avec un message d'erreur. Installez la [version correcte de GitLab](https://packages.gitlab.com/ui/browse/gitlab), puis réessayez.

1. Redémarrez et [vérifiez](../raketasks/maintenance.md#check-gitlab-configuration) GitLab :

   1. Démarrez les déploiements arrêtés, en utilisant le nombre de réplicas noté dans [Prérequis](#prerequisites) :

      ```shell
      kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=<original value>
      kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=<original value>
      kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=<original value>
      ```

   1. Dans le pod Toolbox, exécutez :

      ```shell
      sudo gitlab-rake gitlab:check SANITIZE=true
      ```

1. Vérifiez que les [valeurs de la base de données peuvent être déchiffrées](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets), surtout si `/etc/gitlab/gitlab-secrets.json` a été restauré, ou si un serveur différent est la cible de la restauration :

   Dans le pod Toolbox, exécutez :

   ```shell
   sudo gitlab-rake gitlab:doctor:secrets
   ```

1. Pour plus de certitude, vous pouvez effectuer [une vérification d'intégrité des fichiers chargés](../raketasks/check.md#uploaded-files-integrity) :

   Ces commandes peuvent prendre beaucoup de temps car elles itèrent sur toutes les lignes. Par conséquent, exécutez les commandes suivantes sur le nœud GitLab Rails, plutôt que sur un pod Toolbox :

   ```shell
   sudo gitlab-rake gitlab:artifacts:check
   sudo gitlab-rake gitlab:lfs:check
   sudo gitlab-rake gitlab:uploads:check
   ```

   Si des fichiers manquants ou corrompus sont trouvés, cela ne signifie pas toujours que le processus de sauvegarde et de restauration a échoué. Par exemple, les fichiers peuvent être manquants ou corrompus sur l'instance GitLab source. Vous devrez peut-être consulter les sauvegardes précédentes. Si vous migrez GitLab vers un nouvel environnement, vous pouvez exécuter les mêmes vérifications sur l'instance GitLab source pour déterminer si le résultat de la vérification d'intégrité est préexistant ou lié au processus de sauvegarde et de restauration.

{{< /tab >}}

{{< /tabs >}}

La restauration devrait être terminée.
