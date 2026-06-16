---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Job logs
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les job logs sont envoyés par un runner pendant qu'il traite un job. Vous pouvez consulter les logs dans des endroits tels que les pages de job, les pipelines et les notifications par e-mail.

## Flux de données {#data-flow}

En général, il existe deux états pour les job logs : `log` et `archived log`. Le tableau suivant présente les phases par lesquelles passe un log :

| Phase          | État        | Condition               | Flux de données                                | Chemin de stockage |
| -------------- | ------------ | ----------------------- | -----------------------------------------| ----------- |
| 1 : patching    | log          | Lorsqu'un job est en cours d'exécution   | Runner => Puma => stockage de fichiers | `#{ROOT_PATH}/gitlab-ci/builds/#{YYYY_mm}/#{project_id}/#{job_id}.log` |
| 2 : archiving   | log archivé | Après la fin d'un job | Sidekiq déplace le log vers le dossier des artefacts    | `#{ROOT_PATH}/gitlab-rails/shared/artifacts/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/job.log` |
| 3 : uploading   | log archivé | Après l'archivage d'un log | Sidekiq déplace le log archivé vers [l'object storage](#uploading-logs-to-object-storage) (si configuré) | `#{bucket_name}/#{disk_hash}/#{YYYY_mm_dd}/#{job_id}/#{job_artifact_id}/job.log` |

Le `ROOT_PATH` varie selon l'environnement :

- Pour le package Linux, il s'agit de `/var/opt/gitlab`.
- Pour les installations compilées depuis les sources, il s'agit de `/home/git/gitlab`.

## Modification de l'emplacement local des job logs {#changing-the-job-logs-local-location}

> [!note]
> Pour les installations Docker, vous pouvez modifier le chemin de montage de vos données. Pour le chart Helm, utilisez l'object storage.

Pour modifier l'emplacement de stockage des job logs :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Facultatif. Si vous avez des job logs existants, suspendez le traitement des données d'intégration continue en arrêtant temporairement Sidekiq :

   ```shell
   sudo gitlab-ctl stop sidekiq
   ```

1. Définissez le nouvel emplacement de stockage dans `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_ci['builds_directory'] = '/mnt/gitlab-ci/builds'
   ```

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Utilisez `rsync` pour déplacer les job logs de l'emplacement actuel vers le nouvel emplacement :

   ```shell
   sudo rsync -avzh --remove-source-files --ignore-existing --progress /var/opt/gitlab/gitlab-ci/builds/ /mnt/gitlab-ci/builds/
   ```

   Utilisez `--ignore-existing` pour ne pas écraser les nouveaux job logs avec des versions plus anciennes du même log.

1. Si vous avez choisi de suspendre le traitement des données d'intégration continue, vous pouvez redémarrer Sidekiq :

   ```shell
   sudo gitlab-ctl start sidekiq
   ```

1. Supprimez l'ancien emplacement de stockage des job logs :

   ```shell
   sudo rm -rf /var/opt/gitlab/gitlab-ci/builds
   ```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Facultatif. Si vous avez des job logs existants, suspendez le traitement des données d'intégration continue en arrêtant temporairement Sidekiq :

   ```shell
   # For systems running systemd
   sudo systemctl stop gitlab-sidekiq

   # For systems running SysV init
   sudo service gitlab stop
   ```

1. Modifiez `/home/git/gitlab/config/gitlab.yml` pour définir le nouvel emplacement de stockage :

   ```yaml
   production: &base
     gitlab_ci:
       builds_path: /mnt/gitlab-ci/builds
   ```

1. Enregistrez le fichier et redémarrez GitLab :

   ```shell
   # For systems running systemd
   sudo systemctl restart gitlab.target

   # For systems running SysV init
   sudo service gitlab restart
   ```

1. Utilisez `rsync` pour déplacer les job logs de l'emplacement actuel vers le nouvel emplacement :

   ```shell
   sudo rsync -avzh --remove-source-files --ignore-existing --progress /home/git/gitlab/builds/ /mnt/gitlab-ci/builds/
   ```

   Utilisez `--ignore-existing` pour ne pas écraser les nouveaux job logs avec des versions plus anciennes du même log.

1. Si vous avez choisi de suspendre le traitement des données d'intégration continue, vous pouvez redémarrer Sidekiq :

   ```shell
   # For systems running systemd
   sudo systemctl start gitlab-sidekiq

   # For systems running SysV init
   sudo service gitlab start
   ```

1. Supprimez l'ancien emplacement de stockage des job logs :

   ```shell
   sudo rm -rf /home/git/gitlab/builds
   ```

{{< /tab >}}

{{< /tabs >}}

## Envoi des logs vers l'object storage {#uploading-logs-to-object-storage}

Les logs archivés sont considérés comme des [artefacts de job](job_artifacts.md). Par conséquent, lorsque vous [configurez l'intégration de l'object storage](job_artifacts.md#using-object-storage), les job logs sont automatiquement migrés vers celui-ci avec les autres artefacts de job.

Consultez « Phase 3 : uploading » dans [Flux de données](#data-flow) pour en savoir plus sur le processus.

## Taille maximale du fichier log {#maximum-log-file-size}

La limite de taille des fichiers job log dans GitLab est de 100 mégaoctets par défaut. Tout job dépassant cette limite est marqué comme ayant échoué et abandonné par le runner. Pour plus de détails, consultez [Taille maximale des fichiers pour les job logs](../instance_limits.md#maximum-file-size-for-job-logs).

## Empêcher l'utilisation du disque local {#prevent-local-disk-usage}

Si vous souhaitez éviter toute utilisation du disque local pour les job logs, vous pouvez utiliser l'une des options suivantes :

- Activez la [journalisation incrémentielle](#configure-incremental-logging).
- Définissez l'[emplacement des job logs](#changing-the-job-logs-local-location) sur un lecteur NFS.

## Comment supprimer les job logs {#how-to-remove-job-logs}

Il n'existe pas de méthode pour faire expirer automatiquement les anciens job logs. Cependant, il est possible de les supprimer en toute sécurité s'ils occupent trop d'espace. Si vous supprimez les logs manuellement, la sortie du job dans l'interface utilisateur sera vide.

Pour plus de détails sur la suppression des job logs à l'aide de GitLab CLI, consultez [Supprimer les job logs](../../user/storage_management_automation.md#delete-job-logs).

Pour le chart Helm, utilisez les outils de gestion du stockage fournis avec votre object storage.

Vous pouvez également supprimer les job logs à l'aide de commandes shell. Par exemple, pour supprimer tous les job logs de plus de 60 jours, exécutez la commande suivante depuis un shell dans votre instance GitLab.

> [!warning]
> La commande suivante supprime définitivement les fichiers log et est irréversible.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

```shell
find /var/opt/gitlab/gitlab-rails/shared/artifacts -name "job.log" -mtime +60 -delete
```

{{< /tab >}}

{{< tab title="Docker" >}}

En supposant que vous avez monté `/var/opt/gitlab` sur `/srv/gitlab` :

```shell
find /srv/gitlab/gitlab-rails/shared/artifacts -name "job.log" -mtime +60 -delete
```

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

```shell
find /home/git/gitlab/shared/artifacts -name "job.log" -mtime +60 -delete
```

{{< /tab >}}

{{< /tabs >}}

Une fois les logs supprimés, vous pouvez trouver les références de fichiers rompues en exécutant la tâche Rake qui vérifie l'[intégrité des fichiers téléversés](../raketasks/check.md#uploaded-files-integrity). Pour plus d'informations, consultez comment [supprimer les références aux artefacts manquants](../raketasks/check.md#delete-references-to-missing-artifacts).

## Journalisation incrémentielle {#incremental-logging}

La journalisation incrémentielle modifie la façon dont les job logs sont traités et stockés, améliorant ainsi les performances dans les déploiements à grande échelle.

Par défaut, les job logs sont envoyés depuis GitLab Runner par blocs et mis en cache temporairement sur le disque. Une fois le job terminé, un job en arrière-plan archive le log dans le répertoire des artefacts ou dans l'object storage si celui-ci est configuré.

Avec la journalisation incrémentielle, les logs sont stockés dans Redis et un stockage persistant au lieu du stockage de fichiers. Cette approche :

- Empêche l'utilisation du disque local pour les job logs.
- Élimine le besoin de partage NFS entre les serveurs Rails et Sidekiq.
- Améliore les performances dans les installations multi-nœuds.

Le processus de journalisation incrémentielle utilise Redis comme stockage temporaire et suit ce flow :

1. Le runner sélectionne un job depuis GitLab.
1. Le runner envoie une partie du log à GitLab.
1. GitLab ajoute les données à Redis dans l'espace de nommage `Gitlab::Redis::TraceChunks`.
1. Lorsque les données dans Redis atteignent 128 Ko, elles sont vidées dans un stockage persistant.
1. Les étapes précédentes se répètent jusqu'à la fin du job.
1. Une fois le job terminé, GitLab planifie un worker Sidekiq pour archiver le log.
1. Le worker Sidekiq archive le log dans l'object storage et nettoie les données temporaires.

Redis Cluster n'est pas pris en charge avec la journalisation incrémentielle. Pour plus d'informations, consultez [l'issue 224171](https://gitlab.com/gitlab-org/gitlab/-/issues/224171).

### Configurer la journalisation incrémentielle {#configure-incremental-logging}

Avant d'activer la journalisation incrémentielle, vous devez [configurer l'object storage](job_artifacts.md#using-object-storage) pour les artefacts CI/CD, les logs et les builds. Une fois la journalisation incrémentielle activée, les fichiers ne peuvent plus être écrits sur le disque et il n'existe aucune protection contre les erreurs de configuration.

Lorsque vous activez la journalisation incrémentielle, les logs des jobs en cours d'exécution continuent d'être écrits sur le disque, mais les nouveaux jobs utilisent la journalisation incrémentielle.

Lorsque vous désactivez la journalisation incrémentielle, les jobs en cours d'exécution continuent d'utiliser la journalisation incrémentielle, mais les nouveaux jobs écrivent sur le disque.

Pour configurer la journalisation incrémentielle :

- Utilisez le paramètre dans la [zone d'administration](../settings/continuous_integration.md#access-job-log-settings) ou l'[API Settings](../../api/settings.md).
