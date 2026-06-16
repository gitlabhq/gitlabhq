---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Administration des artefacts de job
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Il s'agit de la documentation d'administration. Pour apprendre à utiliser les artefacts de job dans votre pipeline CI/CD GitLab, consultez la [documentation de configuration des artefacts de job](../../ci/jobs/job_artifacts.md).

Un artefact est une liste de fichiers et de répertoires attachés à un job après sa fin. Cette fonctionnalité est activée par défaut dans toutes les installations GitLab.

## Désactivation des artefacts de job {#disabling-job-artifacts}

Pour désactiver les artefacts sur l'ensemble du site :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['artifacts_enabled'] = false
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       artifacts:
         enabled: false
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['artifacts_enabled'] = false
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     artifacts:
       enabled: false
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## Stockage des artefacts de job {#storing-job-artifacts}

GitLab Runner peut charger une archive contenant les artefacts de job vers GitLab. Par défaut, cette opération est effectuée lorsque le job réussit, mais elle peut également être effectuée en cas d'échec, ou toujours, avec le paramètre [`artifacts:when`](../../ci/yaml/_index.md#artifactswhen).

La plupart des artefacts sont compressés par GitLab Runner avant d'être envoyés au coordinateur. L'exception à cette règle concerne les [artefacts de rapports](../../ci/yaml/_index.md#artifactsreports), qui sont compressés après le chargement.

### Utilisation du stockage local {#using-local-storage}

Si vous utilisez le package Linux ou disposez d'une installation compilée manuellement, vous pouvez modifier l'emplacement de stockage local des artefacts.

> [!note]
> Pour les installations Docker, vous pouvez modifier le chemin de montage de vos données. Pour le chart Helm, utilisez le [stockage d'objets](https://docs.gitlab.com/charts/advanced/external-object-storage/).

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

Les artefacts sont stockés par défaut dans `/var/opt/gitlab/gitlab-rails/shared/artifacts`.

1. Pour modifier le chemin de stockage, par exemple vers `/mnt/storage/artifacts`, modifiez `/etc/gitlab/gitlab.rb` et ajoutez la ligne suivante :

   ```ruby
   gitlab_rails['artifacts_path'] = "/mnt/storage/artifacts"
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

Les artefacts sont stockés par défaut dans `/home/git/gitlab/shared/artifacts`.

1. Pour modifier le chemin de stockage, par exemple vers `/mnt/storage/artifacts`, modifiez `/home/git/gitlab/config/gitlab.yml` et ajoutez ou modifiez les lignes suivantes :

   ```yaml
   production: &base
     artifacts:
       enabled: true
       path: /mnt/storage/artifacts
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

### Utilisation du stockage d'objets {#using-object-storage}

Si vous ne souhaitez pas utiliser le disque local où GitLab est installé pour stocker les artefacts, vous pouvez utiliser un stockage d'objets tel qu'AWS S3 à la place.

Si vous configurez GitLab pour stocker les artefacts sur un stockage d'objets, vous souhaiterez peut-être également [éliminer l'utilisation du disque local pour les job logs](job_logs.md#prevent-local-disk-usage). Dans les deux cas, les job logs sont archivés et déplacés vers le stockage d'objets à la fin du job.

> [!warning]
> Dans une configuration multi-serveurs, vous devez utiliser l'une des options pour [éliminer l'utilisation du disque local pour les job logs](job_logs.md#prevent-local-disk-usage), sinon les job logs pourraient être perdus.

Vous devriez utiliser les [paramètres de stockage d'objets consolidés](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).

### Migration vers le stockage d'objets {#migrating-to-object-storage}

Vous pouvez migrer les artefacts de job du stockage local vers le stockage d'objets. Le traitement est effectué par un worker en arrière-plan et ne nécessite **no downtime**.

1. [Configurez le stockage d'objets](#using-object-storage).
1. Migrez les artefacts :

   {{< tabs >}}

   {{< tab title="Linux package (Omnibus)" >}}

   ```shell
   sudo gitlab-rake gitlab:artifacts:migrate
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   ```shell
   sudo docker exec -t <container name> gitlab-rake gitlab:artifacts:migrate
   ```

   {{< /tab >}}

   {{< tab title="Self-compiled (source)" >}}

   ```shell
   sudo -u git -H bundle exec rake gitlab:artifacts:migrate RAILS_ENV=production
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. Facultatif. Suivez la progression et vérifiez que tous les artefacts de job ont été migrés avec succès à l'aide de la console PostgreSQL.
   1. Ouvrez une console PostgreSQL :

      {{< tabs >}}

      {{< tab title="Linux package (Omnibus)" >}}

      ```shell
      sudo gitlab-psql
      ```

      {{< /tab >}}

      {{< tab title="Docker" >}}

      ```shell
      sudo docker exec -it <container_name> /bin/bash
      gitlab-psql
      ```

      {{< /tab >}}

      {{< tab title="Self-compiled (source)" >}}

      ```shell
      sudo -u git -H psql -d gitlabhq_production
      ```

      {{< /tab >}}

      {{< /tabs >}}

   1. Vérifiez que tous les artefacts ont été migrés vers le stockage d'objets à l'aide de la requête SQL suivante. Le nombre de `objectstg` doit être identique à `total` :

      ```shell
      gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM p_ci_job_artifacts;

      total | filesystem | objectstg
      ------+------------+-----------
         19 |          0 |        19
      ```

1. Vérifiez qu'il n'y a aucun fichier sur le disque dans le répertoire `artifacts` :

   {{< tabs >}}

   {{< tab title="Linux package (Omnibus)" >}}

   ```shell
   sudo find /var/opt/gitlab/gitlab-rails/shared/artifacts -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< tab title="Docker" >}}

   En supposant que vous avez monté `/var/opt/gitlab` sur `/srv/gitlab` :

   ```shell
   sudo find /srv/gitlab/gitlab-rails/shared/artifacts -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< tab title="Self-compiled (source)" >}}

   ```shell
   sudo find /home/git/gitlab/shared/artifacts -type f | grep -v tmp | wc -l
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. Si [Geo](../geo/_index.md) est activé, [revérifiez tous les artefacts de job](../geo/replication/troubleshooting/synchronization_verification.md#reverify-one-component-on-all-sites).

Dans certains cas, vous devez exécuter la [tâche Rake de nettoyage des fichiers d'artefacts orphelins](../raketasks/cleanup.md#remove-orphan-artifact-files) pour nettoyer les artefacts orphelins.

### Migration du stockage d'objets vers le stockage local {#migrating-from-object-storage-to-local-storage}

Pour migrer les artefacts vers le stockage local :

1. Exécutez `gitlab-rake gitlab:artifacts:migrate_to_local`.
1. [Désactivez sélectivement le stockage des artefacts](../object_storage.md#disable-object-storage-for-specific-features) dans `gitlab.rb`.
1. [Reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

Avant GitLab 18.6, une migration du stockage distant vers le stockage local pouvait entraîner la [copie des artefacts avec des noms de fichiers incorrects](job_artifacts_troubleshooting.md#job-artifacts-can-have-wrong-filenames).

## Expiration des artefacts {#expiring-artifacts}

Si [`artifacts:expire_in`](../../ci/yaml/_index.md#artifactsexpire_in) est utilisé pour définir une expiration pour les artefacts, ceux-ci sont marqués pour suppression juste après la date passée. Sinon, ils expirent selon le [paramètre d'expiration des artefacts par défaut](../settings/continuous_integration.md#set-default-artifacts-expiration).

Les artefacts sont supprimés par le cron job `expire_build_artifacts_worker` que Sidekiq exécute toutes les 7 minutes (`*/7 * * * *` en syntaxe [Cron](../../topics/cron/_index.md)).

Pour modifier la planification par défaut de suppression des artefacts expirés :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez la ligne suivante (ou décommentez-la si elle existe déjà et est commentée), en remplaçant votre planification en syntaxe cron :

   ```ruby
   gitlab_rails['expire_build_artifacts_worker_cron'] = "*/7 * * * *"
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   global:
     appConfig:
       cron_jobs:
         expire_build_artifacts_worker:
           cron: "*/7 * * * *"
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab
   ```

{{< /tab >}}

{{< tab title="Docker" >}}

1. Modifiez `docker-compose.yml` :

   ```yaml
   version: "3.6"
   services:
     gitlab:
       environment:
         GITLAB_OMNIBUS_CONFIG: |
           gitlab_rails['expire_build_artifacts_worker_cron'] = "*/7 * * * *"
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   docker compose up -d
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `/home/git/gitlab/config/gitlab.yml` :

   ```yaml
   production: &base
     cron_jobs:
       expire_build_artifacts_worker:
         cron: "*/7 * * * *"
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

{{< /tab >}}

{{< /tabs >}}

## Définir la taille de fichier maximale des artefacts {#set-the-maximum-file-size-of-the-artifacts}

Si les artefacts sont activés, vous pouvez modifier la taille de fichier maximale des artefacts via les [paramètres de la zone **Admin**](../settings/continuous_integration.md#set-maximum-artifacts-size).

## Statistiques de stockage {#storage-statistics}

Vous pouvez consulter le stockage total utilisé pour les artefacts de job pour les groupes et les projets dans :

- La zone **Admin**
- Les API [groupes](../../api/groups.md) et [projets](../../api/projects.md)

## Détails d'implémentation {#implementation-details}

Lorsque GitLab reçoit une archive d'artefacts, un fichier de métadonnées d'archive est également généré par [GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse). Ce fichier de métadonnées décrit toutes les entrées situées dans l'archive d'artefacts elle-même. Le fichier de métadonnées est au format binaire, avec une compression Gzip supplémentaire.

GitLab n'extrait pas l'archive d'artefacts pour économiser de l'espace, de la mémoire et des E/S disque. Il inspecte plutôt le fichier de métadonnées qui contient toutes les informations pertinentes. Cela est particulièrement important lorsqu'il y a de nombreux artefacts ou qu'une archive est un fichier très volumineux.

Lors de la sélection d'un fichier spécifique, [GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse) l'extrait de l'archive et le téléchargement commence. Cette implémentation permet d'économiser de l'espace, de la mémoire et des E/S disque.
