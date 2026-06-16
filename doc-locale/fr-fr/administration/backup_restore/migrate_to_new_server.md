---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrer vers un nouveau serveur
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

<!-- some details borrowed from GitLab.com move from Azure to GCP detailed at <https://gitlab.com/gitlab-com/migration/-/blob/master/.gitlab/issue_templates/failover.md> -->

Utilisez la sauvegarde et la restauration GitLab pour migrer une instance de package Linux vers un nouveau serveur. Vous avez également la possibilité de [migrer une instance GitLab de package Linux vers Docker](../../install/docker/migrate.md).

Si vous utilisez GitLab Geo, une autre option est la [reprise après sinistre Geo pour un basculement planifié](../geo/disaster_recovery/planned_failover.md). Vous devez vous assurer que tous les sites satisfont aux [exigences Geo](../geo/_index.md#requirements-for-running-geo) avant de sélectionner Geo pour la migration.

> [!warning]
> Évitez le traitement de données non coordonné par les nouveaux et anciens serveurs, où plusieurs serveurs pourraient se connecter simultanément et traiter les mêmes données. Par exemple, lorsque vous utilisez la [messagerie entrante](../incoming_email.md), si les deux instances GitLab traitent les e-mails en même temps, les deux instances manquent certaines données. Ce type de problème peut survenir avec d'autres services également, tels qu'une [base de données non packagée](https://docs.gitlab.com/omnibus/settings/database/#using-a-non-packaged-postgresql-database-management-server), une instance Redis non packagée ou un Sidekiq non packagé.

Prérequis :

- Une [bannière de message de diffusion](../broadcast_messages.md) publiée à l'avance pour informer vos utilisateurs de la migration à venir.
- Sauvegardes complètes et à jour. Créez une sauvegarde complète au niveau système, ou prenez un instantané de tous les serveurs impliqués dans la migration, au cas où des commandes destructives (comme `rm`) seraient exécutées incorrectement.
- Accès administrateur.

## Préparer le nouveau serveur {#prepare-the-new-server}

Pour préparer le nouveau serveur :

1. Copiez les [clés d'hôte SSH](https://superuser.com/questions/532040/copy-ssh-keys-from-one-server-to-another-server/532079#532079) de l'ancien serveur pour éviter les avertissements d'attaque de l'homme du milieu. Consultez [Répliquer manuellement les clés d'hôte SSH du site principal](../geo/replication/configuration.md#step-2-manually-replicate-the-primary-sites-ssh-host-keys) pour des exemples d'étapes.
1. [Installez GitLab](../../install/package/_index.md).
1. Configurez en copiant les fichiers `/etc/gitlab` de l'ancien serveur vers le nouveau serveur, et mettez-les à jour si nécessaire. Consultez les [instructions de sauvegarde et de restauration de l'installation du package Linux](https://docs.gitlab.com/omnibus/settings/backups/) pour plus de détails.
1. Le cas échéant, désactivez la [messagerie entrante](../incoming_email.md).
1. Bloquez le démarrage de nouveaux jobs CI/CD lors du démarrage initial après la sauvegarde et la restauration. Modifiez `/etc/gitlab/gitlab.rb` et définissez les éléments suivants :

   ```ruby
   nginx['custom_gitlab_server_config'] = "location = /api/v4/jobs/request {\n    deny all;\n    return 503;\n  }\n"
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Arrêtez GitLab pour éviter tout traitement de données inutile et non intentionnel :

   ```shell
   sudo gitlab-ctl stop
   ```

1. Arrêtez Redis :

   ```shell
   sudo gitlab-ctl stop redis
   ```

1. Configurez le nouveau serveur pour permettre la réception de la base de données Redis et des fichiers de sauvegarde GitLab :

   ```shell
   sudo rm -f /var/opt/gitlab/redis/dump.rdb
   sudo chown <your-linux-username> /var/opt/gitlab/redis /var/opt/gitlab/backups
   ```

## Préparer et transférer le contenu depuis l'ancien serveur {#prepare-and-transfer-content-from-the-old-server}

1. Assurez-vous de disposer d'une sauvegarde ou d'un instantané au niveau système à jour de l'ancien serveur.
1. Activez le [mode maintenance](../maintenance_mode/_index.md), s'il est pris en charge par votre édition de GitLab.
1. Bloquez le démarrage de nouveaux jobs CI/CD :
   1. Modifiez `/etc/gitlab/gitlab.rb`, et définissez les éléments suivants :

      ```ruby
      nginx['custom_gitlab_server_config'] = "location = /api/v4/jobs/request {\n    deny all;\n    return 503;\n  }\n"
      ```

   1. Reconfigurez GitLab :

      ```shell
      sudo gitlab-ctl reconfigure
      ```

1. Désactivez les jobs en arrière-plan périodiques :
   1. Dans le coin supérieur droit, sélectionnez **Admin**.
   1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Jobs en arrière-plan** pour afficher le tableau de bord Sidekiq.
   1. Sur le tableau de bord Sidekiq, dans son menu supérieur, sélectionnez **Cron**.
   1. Sur le tableau de bord Sidekiq, en haut à droite, sélectionnez **Disable All**.
1. Attendez que les jobs CI/CD en cours se terminent, ou acceptez que les jobs non terminés puissent être perdus. Pour afficher tous les jobs en cours :
   1. Dans la barre latérale gauche, sélectionnez **CI/CD** > **Jobs**.
   1. Dans la barre de filtre, sélectionnez **Statut** > **En cours**.
1. Attendez que les jobs Sidekiq se terminent :
   1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Jobs en arrière-plan**.
   1. Sur le tableau de bord Sidekiq, dans son menu supérieur, sélectionnez **Queues**.
   1. Sur le tableau de bord Sidekiq, en haut à droite, sélectionnez **Live Poll**. Attendez que **Occupé(e)** et **Enqueued** tombent à 0. Ces files d'attente contiennent des travaux soumis par vos utilisateurs ; arrêter le service avant que ces jobs ne soient terminés peut entraîner la perte de ces travaux. Notez les chiffres affichés dans le tableau de bord Sidekiq pour la vérification post-migration.
1. Videz la base de données Redis sur le disque et arrêtez GitLab à l'exception des services nécessaires à la migration :

   ```shell
   sudo /opt/gitlab/embedded/bin/redis-cli -s /var/opt/gitlab/redis/redis.socket save && \
   sudo gitlab-ctl stop && \
   sudo gitlab-ctl start postgresql && \
   sudo gitlab-ctl start gitaly
   ```

1. Créez une sauvegarde GitLab :

   ```shell
   sudo gitlab-backup create
   ```

1. Une fois la sauvegarde terminée, désactivez les services GitLab suivants et empêchez les redémarrages non intentionnels en ajoutant ce qui suit en bas de `/etc/gitlab/gitlab.rb` :

   ```ruby
   alertmanager['enable'] = false
   gitaly['enable'] = false
   gitlab_exporter['enable'] = false
   gitlab_pages['enable'] = false
   gitlab_workhorse['enable'] = false
   grafana['enable'] = false
   logrotate['enable'] = false
   gitlab_rails['incoming_email_enabled'] = false
   nginx['enable'] = false
   node_exporter['enable'] = false
   postgres_exporter['enable'] = false
   postgresql['enable'] = false
   prometheus['enable'] = false
   puma['enable'] = false
   redis['enable'] = false
   redis_exporter['enable'] = false
   registry['enable'] = false
   sidekiq['enable'] = false
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Vérifiez que tout est arrêté et confirmez qu'aucun service n'est en cours d'exécution :

   ```shell
   sudo gitlab-ctl status
   ```

1. Transférez la base de données Redis et les sauvegardes GitLab vers le nouveau serveur :

   ```shell
   sudo scp /var/opt/gitlab/redis/dump.rdb <your-linux-username>@new-server:/var/opt/gitlab/redis
   sudo scp /var/opt/gitlab/backups/your-backup.tar <your-linux-username>@new-server:/var/opt/gitlab/backups
   ```

### Pour les instances avec un grand volume de données Git et d'objets {#for-instances-with-a-large-volume-of-git-and-object-data}

Si votre instance GitLab contient une grande quantité de données sur des volumes locaux, par exemple supérieure à 1 To, les sauvegardes peuvent prendre beaucoup de temps. Dans ce cas, il peut être plus facile de transférer les données vers les volumes appropriés sur la nouvelle instance.

Les principaux volumes que vous pourriez avoir besoin de migrer manuellement sont :

- Le répertoire `/var/opt/gitlab/git-data` qui contient toutes les données Git. Assurez-vous de lire [la section de documentation sur le déplacement des dépôts](../operations/moving_repositories.md#migrate-to-another-gitlab-instance) pour éliminer les risques de corruption des données Git.
- Le répertoire `/var/opt/gitlab/gitlab-rails/shared` qui contient les données d'objets, comme les artefacts.
- Le répertoire `/var/opt/gitlab/gitlab-rails/uploads` qui contient les données de téléversement, comme les photos de profil des utilisateurs.
- Si vous utilisez le PostgreSQL intégré inclus avec le package Linux, vous devez également migrer le [répertoire de données PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#store-postgresql-data-in-a-different-directory) sous `/var/opt/gitlab/postgresql/data`.

Une fois tous les services GitLab arrêtés, vous pouvez utiliser des outils comme `rsync` ou des instantanés de volume montés pour déplacer les données vers le nouvel environnement.

## Restaurer les données sur le nouveau serveur {#restore-data-on-the-new-server}

1. Restaurez les autorisations appropriées du système de fichiers :

   ```shell
   sudo chown gitlab-redis /var/opt/gitlab/redis
   sudo chown gitlab-redis:gitlab-redis /var/opt/gitlab/redis/dump.rdb
   sudo chown git:root /var/opt/gitlab/backups
   sudo chown git:git /var/opt/gitlab/backups/your-backup.tar
   ```

1. Démarrez Redis :

   ```shell
   sudo gitlab-ctl start redis
   ```

   Redis récupère et restaure `dump.rdb` automatiquement.

1. [Restaurez la sauvegarde GitLab](restore_gitlab.md).
1. Vérifiez que la base de données Redis a été correctement restaurée :
   1. Dans le coin supérieur droit, sélectionnez **Admin**.
   1. Dans la barre latérale gauche, sélectionnez **Surveillance** > **Jobs en arrière-plan**.
   1. Sous le tableau de bord Sidekiq, vérifiez que les chiffres correspondent à ceux affichés sur l'ancien serveur.
   1. Toujours sous le tableau de bord Sidekiq, sélectionnez **Cron** puis **Enable All** pour réactiver les jobs en arrière-plan périodiques.
1. Testez que les opérations en lecture seule sur l'instance GitLab fonctionnent comme prévu. Par exemple, parcourez les fichiers du dépôt de projet, les merge requests et les tickets.
1. Désactivez le [mode maintenance](../maintenance_mode/_index.md), s'il était précédemment activé.
1. Testez que l'instance GitLab fonctionne comme prévu.
1. Le cas échéant, réactivez la [messagerie entrante](../incoming_email.md) et testez qu'elle fonctionne comme prévu.
1. Mettez à jour votre DNS ou votre équilibreur de charge pour pointer vers le nouveau serveur.
1. Débloquez le démarrage de nouveaux jobs CI/CD en supprimant la configuration NGINX personnalisée que vous avez ajoutée précédemment :

   ```ruby
   # The following line must be removed
   nginx['custom_gitlab_server_config'] = "location = /api/v4/jobs/request {\n    deny all;\n    return 503;\n  }\n"
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Supprimez la [bannière de message de diffusion](../broadcast_messages.md) de maintenance planifiée.
