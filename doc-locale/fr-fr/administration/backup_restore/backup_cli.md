---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
ignore_in_report: true
title: Sauvegarder et restaurer GitLab avec `gitlab-backup-cli`
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed
- Statut : Expérience

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/11908) dans GitLab 17.0. Cette fonctionnalité est une [expérience](../../policy/development_stages_support.md) et soumise au [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

{{< /history >}}

Cet outil est en cours de développement et est destiné à terme à remplacer [les tâches Rake utilisées pour sauvegarder et restaurer GitLab](backup_gitlab.md). Vous pouvez suivre le développement de cet outil dans l'epic :  [Next Gen Scalable Backup and Restore](https://gitlab.com/groups/gitlab-org/-/epics/11577).

Les commentaires sur l'outil sont les bienvenus dans [le ticket de feedback](https://gitlab.com/gitlab-org/gitlab/-/issues/457155).

## Effectuer une sauvegarde {#taking-a-backup}

Pour effectuer une sauvegarde de l'installation GitLab actuelle :

```shell
sudo gitlab-backup-cli backup all
```

### Sauvegarde du stockage d'objets {#backing-up-object-storage}

Seul Google Cloud est pris en charge. Consultez l'[epic 11577](https://gitlab.com/groups/gitlab-org/-/epics/11577) pour connaître le plan d'ajout d'autres fournisseurs.

#### GCP {#gcp}

`gitlab-backup-cli` crée et exécute des jobs avec le [Storage Transfer Service](https://cloud.google.com/storage-transfer-service/) de Google Cloud pour copier les données GitLab vers un bucket de sauvegarde séparé.

Prérequis :

- Consultez la [présentation des comptes de service](https://cloud.google.com/iam/docs/service-account-overview) pour vous authentifier avec un compte de service.
- Ce document part du principe que vous configurez et utilisez un compte de service Google Cloud dédié à la gestion des sauvegardes.
- Si aucune autre information d'identification n'est fournie et que vous exécutez l'outil dans Google Cloud, l'outil tente d'utiliser les accès de l'infrastructure sur laquelle il s'exécute. Pour des [raisons de sécurité](#security-considerations), vous devez exécuter l'outil avec des informations d'identification séparées et restreindre l'accès aux sauvegardes créées depuis l'application.

Pour créer une sauvegarde :

1. [Créer un rôle](https://cloud.google.com/iam/docs/creating-custom-roles) :
   1. Créez un fichier `role.yaml` avec la définition suivante :

   ```yaml
   ---
   description: Role for backing up GitLab object storage
   includedPermissions:
      - storagetransfer.jobs.create
      - storagetransfer.jobs.get
      - storagetransfer.jobs.run
      - storagetransfer.jobs.update
      - storagetransfer.operations.get
      - storagetransfer.projects.getServiceAccount
   stage: GA
   title: GitLab Backup Role
   ```

   1. Appliquer le rôle :

      ```shell
      gcloud iam roles create --project=<YOUR_PROJECT_ID> <ROLE_NAME> --file=role.yaml
      ```

1. Créez un compte de service pour les sauvegardes et ajoutez-le au rôle :

   ```shell
   gcloud iam service-accounts create "gitlab-backup-cli" --display-name="GitLab Backup Service Account"
   # Get the service account email from the output of the following
   gcloud iam service-accounts list
   # Add the account to the role created previously
   gcloud projects add-iam-policy-binding <YOUR_PROJECT_ID> --member="serviceAccount:<SERVICE_ACCOUNT_EMAIL>" --role="roles/<ROLE_NAME>"
   ```

1. Pour vous authentifier avec un compte de service, consultez les [informations d'identification du compte de service](https://cloud.google.com/iam/docs/service-account-overview#credentials). Les informations d'identification peuvent être enregistrées dans un fichier ou stockées dans une variable d'environnement prédéfinie.
1. Créez un bucket de destination pour la sauvegarde dans [Google Cloud Storage](https://cloud.google.com/storage/). Les options disponibles dépendent fortement de vos besoins.
1. Exécuter la sauvegarde :

   ```shell
   sudo gitlab-backup-cli backup all --backup-bucket=<BUCKET_NAME>
   ```

   Si vous souhaitez sauvegarder le bucket du registre de conteneurs, ajoutez l'option `--registry-bucket=<REGISTRY_BUCKET_NAME>`.
1. La sauvegarde crée une entrée sous `backups/<BACKUP_ID>/<BUCKET>` pour chacun des types de stockage d'objets dans le bucket.

## Structure du répertoire de sauvegarde {#backup-directory-structure}

Exemple de structure de répertoire de sauvegarde :

```plaintext
backups
└── 1714053314_2024_04_25_17.0.0-pre
    ├── artifacts.tar.gz
    ├── backup_information.json
    ├── builds.tar.gz
    ├── ci_secure_files.tar.gz
    ├── db
    │   ├── ci_database.sql.gz
    │   └── database.sql.gz
    ├── lfs.tar.gz
    ├── packages.tar.gz
    ├── pages.tar.gz
    ├── registry.tar.gz
    ├── repositories
    │   ├── default
    │   │   ├── @hashed
    │   │   └── @snippets
    │   └── manifests
    │       └── default
    ├── terraform_state.tar.gz
    └── uploads.tar.gz
```

Le répertoire `db` est utilisé pour sauvegarder la base de données PostgreSQL de GitLab en utilisant `pg_dump` pour créer [un dump SQL](https://www.postgresql.org/docs/16/backup-dump.html). La sortie de `pg_dump` est transmise via un pipe à `gzip` afin de créer un fichier SQL compressé.

Le répertoire `repositories` est utilisé pour sauvegarder les dépôts Git, tels qu'ils figurent dans la base de données GitLab.

## ID de sauvegarde {#backup-id}

Les ID de sauvegarde identifient les sauvegardes individuelles. Vous avez besoin de l'ID de sauvegarde d'une archive de sauvegarde si vous devez restaurer GitLab et que plusieurs sauvegardes sont disponibles.

Les sauvegardes sont enregistrées dans un répertoire défini dans `backup_path`, spécifié dans le fichier `config/gitlab.yml`.

- Par défaut, les sauvegardes sont stockées dans `/var/opt/gitlab/backups`.
- Par défaut, les répertoires de sauvegarde sont nommés d'après les `backup_id` où `<backup-id>` identifie l'heure de création de la sauvegarde et la version de GitLab.

Par exemple, si le nom du répertoire de sauvegarde est `1714053314_2024_04_25_17.0.0-pre`, l'heure de création est représentée par `1714053314_2024_04_25` et la version de GitLab est 17.0.0-pre.

## Fichier de métadonnées de sauvegarde (`backup_information.json`) {#backup-metadata-file-backup_informationjson}

{{< history >}}

- La version 2 des métadonnées a été introduite dans [GitLab 16.11](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/149441).

{{< /history >}}

`backup_information.json` se trouve dans le répertoire de sauvegarde et stocke les métadonnées relatives à la sauvegarde. Par exemple :

```json
{
  "metadata_version": 2,
  "backup_id": "1714053314_2024_04_25_17.0.0-pre",
  "created_at": "2024-04-25T13:55:14Z",
  "gitlab_version": "17.0.0-pre"
}
```

## Restaurer une sauvegarde {#restore-a-backup}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/469247) dans GitLab 17.6.

{{< /history >}}

Prérequis :

- Vous disposez de l'ID de sauvegarde d'une sauvegarde créée avec `gitlab-backup-cli`.

Pour restaurer une sauvegarde de l'installation GitLab actuelle :

- Exécutez la commande suivante :

  ```shell
  sudo gitlab-backup-cli restore all <backup_id>
  ```

### Restaurer les données de stockage d'objets {#restore-object-storage-data}

Vous pouvez restaurer des données depuis Google Cloud Storage. [L'epic 11577](https://gitlab.com/groups/gitlab-org/-/epics/11577) propose d'ajouter la prise en charge d'autres fournisseurs.

Prérequis :

- Vous disposez de l'ID de sauvegarde d'une sauvegarde créée avec `gitlab-backup-cli`.
- Vous avez configuré les autorisations requises pour l'emplacement de restauration.
- Vous avez configuré la configuration du stockage d'objets dans le fichier `gitlab.rb` ou `gitlab.yml`, et celle-ci correspond à l'environnement de sauvegarde.
- Vous avez testé le processus de restauration dans un environnement de staging.

Pour restaurer les données de stockage d'objets :

- Exécutez la commande suivante :

  ```shell
  sudo gitlab-backup restore <backup_id>
  ```

Le processus de restauration :

- Ne vide pas d'abord le bucket de destination.
- Écrase les fichiers existants portant les mêmes noms dans le bucket de destination.
- Peut prendre un temps considérable, selon la quantité de données restaurées.

Surveillez toujours les ressources de votre système lors d'une restauration. Conservez vos fichiers originaux jusqu'à ce que vous ayez vérifié que la restauration a réussi.

## Problèmes connus {#known-issues}

Lorsque vous travaillez avec `gitlab-backup-cli`, vous pouvez rencontrer les problèmes suivants.

### Compatibilité d'architecture {#architecture-compatibility}

Si vous utilisez l'outil `gitlab-backup-cli` sur des architectures autres que l'[architecture 1K](../reference_architectures/1k_users.md), vous pourriez rencontrer des problèmes. Cet outil n'est pris en charge que sur l'architecture 1K et est recommandé uniquement pour les environnements concernés.

### Stratégie de sauvegarde {#backup-strategy}

Les modifications apportées aux fichiers existants pendant la sauvegarde peuvent entraîner des problèmes sur l'instance GitLab. Ce problème survient parce que la version initiale de l'outil n'utilise pas la [stratégie de copie](backup_gitlab.md#backup-strategy-option).

Une solution de contournement de ce problème consiste à :

- Faire passer l'instance GitLab en [Mode Maintenance](../maintenance_mode/_index.md).
- Restreindre le trafic vers les serveurs pendant la sauvegarde pour préserver les ressources de l'instance.

Nous étudions une alternative à la stratégie de copie, consultez le [ticket 428520](https://gitlab.com/gitlab-org/gitlab/-/issues/428520).

## Quelles données sont sauvegardées ? {#what-data-is-backed-up}

1. Données du dépôt Git
1. Bases de données
1. Blobs

## Quelles données ne sont PAS sauvegardées ? {#what-data-is-not-backed-up}

1. Secrets et configurations

   - Suivez la documentation sur la façon de [sauvegarder les secrets et la configuration](backup_gitlab.md#storing-configuration-files).

1. Données transitoires et données de cache

   - Redis : Cache
   - Redis : Données Sidekiq
   - Journaux
   - Elasticsearch
   - Données d'observabilité / Métriques Prometheus

## Considérations de sécurité {#security-considerations}

Au lieu d'utiliser les mêmes informations d'identification, vous devez créer un compte utilisateur distinct avec uniquement les autorisations nécessaires à l'exécution des sauvegardes. Exécuter des sauvegardes avec les mêmes informations d'identification que l'application est une mauvaise pratique de sécurité pour plusieurs raisons :

- Principe du moindre privilège - Le processus de sauvegarde nécessite des autorisations plus étendues (comme l'accès en lecture à toutes les données) que celles requises pour les opérations normales de l'application. Un utilisateur ou un processus doit disposer de l'accès minimal nécessaire à l'accomplissement de sa fonction.
- Risque de compromission - Si les informations d'identification de l'application sont compromises, un attaquant peut accéder à l'application et à toutes ses données de sauvegarde, exposant également les données historiques.
- Séparation des tâches - L'utilisation d'informations d'identification distinctes pour les sauvegardes et les applications aide à maintenir une séparation des tâches. Cette séparation rend plus difficile pour un seul compte compromis de causer des dommages étendus.
- Piste d'audit - Des informations d'identification distinctes pour les sauvegardes facilitent le suivi et l'audit des activités de sauvegarde indépendamment des opérations régulières de l'application.
- Contrôle d'accès granulaire - Des informations d'identification différentes permettent un contrôle d'accès plus granulaire. Les informations d'identification de sauvegarde peuvent se voir accorder un accès en lecture seule aux données, tandis que les informations d'identification de l'application peuvent nécessiter un accès en lecture-écriture à des tables ou des schémas spécifiques.
- Exigences de conformité - De nombreuses normes réglementaires et cadres de conformité (comme le RGPD, la HIPAA ou le PCI-DSS) exigent ou recommandent fortement la séparation des tâches et les contrôles d'accès, plus faciles à réaliser avec des informations d'identification distinctes.
- Gestion facilitée du cycle de vie - Les processus d'application et de sauvegarde peuvent avoir des cycles de vie différents. L'utilisation d'informations d'identification distinctes facilite la gestion indépendante de ces cycles de vie. Par exemple, vous pouvez faire tourner ou révoquer des informations d'identification sans affecter l'autre processus.
- Protection contre les vulnérabilités de l'application - Si l'application présente une vulnérabilité permettant une injection SQL ou d'autres formes d'accès non autorisé aux données, l'utilisation d'informations d'identification de sauvegarde distinctes ajoute une couche de protection supplémentaire pour le processus de sauvegarde.
