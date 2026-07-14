---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation du service PgBouncer intégré
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

> [!note]
> PgBouncer est intégré dans le package `gitlab-ee`, mais son utilisation est gratuite. Pour bénéficier du support, vous devez avoir un [abonnement Premium](https://about.gitlab.com/pricing/).

[PgBouncer](https://www.pgbouncer.org/) est utilisé pour migrer de manière transparente les connexions de base de données entre les serveurs lors d'un scénario de basculement. De plus, il peut être utilisé dans une configuration non tolérante aux pannes pour regrouper les connexions, accélérant ainsi le temps de réponse tout en réduisant l'utilisation des ressources.

GitLab Premium inclut une version intégrée de PgBouncer qui peut être gérée via `/etc/gitlab/gitlab.rb`.

## PgBouncer dans le cadre d'une installation GitLab tolérante aux pannes {#pgbouncer-as-part-of-a-fault-tolerant-gitlab-installation}

Ce contenu a été déplacé vers un [nouvel emplacement](replication_and_failover.md#configure-pgbouncer-nodes).

## PgBouncer dans le cadre d'une installation GitLab non tolérante aux pannes {#pgbouncer-as-part-of-a-non-fault-tolerant-gitlab-installation}

1. Générez `PGBOUNCER_USER_PASSWORD_HASH` avec la commande `gitlab-ctl pg-password-md5 pgbouncer`
1. Générez `SQL_USER_PASSWORD_HASH` avec la commande `gitlab-ctl pg-password-md5 gitlab`. Saisissez le SQL_USER_PASSWORD en texte brut ultérieurement.
1. Sur votre nœud de base de données, assurez-vous que les éléments suivants sont définis dans votre `/etc/gitlab/gitlab.rb`

   ```ruby
   postgresql['pgbouncer_user_password'] = 'PGBOUNCER_USER_PASSWORD_HASH'
   postgresql['sql_user_password'] = 'SQL_USER_PASSWORD_HASH'
   postgresql['listen_address'] = 'XX.XX.XX.Y' # Where XX.XX.XX.Y is the ip address on the node postgresql should listen on
   postgresql['md5_auth_cidr_addresses'] = %w(AA.AA.AA.B/32) # Where AA.AA.AA.B is the IP address of the pgbouncer node
   ```

1. Exécutez `gitlab-ctl reconfigure`

   > [!note]
   > Si la base de données était déjà en cours d'exécution, elle doit être redémarrée après la reconfiguration en exécutant `gitlab-ctl restart postgresql`.

1. Sur le nœud sur lequel vous exécutez PgBouncer, assurez-vous que les éléments suivants sont définis dans `/etc/gitlab/gitlab.rb`

   ```ruby
   pgbouncer['enable'] = true
   pgbouncer['databases'] = {
     gitlabhq_production: {
       host: 'DATABASE_HOST',
       user: 'pgbouncer',
       password: 'PGBOUNCER_USER_PASSWORD_HASH'
     }
   }
   ```

   Vous pouvez transmettre des paramètres de configuration supplémentaires par base de données, par exemple :

   ```ruby
   pgbouncer['databases'] = {
     gitlabhq_production: {
        ...
        pool_mode: 'transaction'
     }
   }
   ```

   Utilisez ces paramètres avec précaution. Pour la liste complète des paramètres, consultez la [documentation PgBouncer](https://www.pgbouncer.org/config.html#section-databases).

1. Exécutez `gitlab-ctl reconfigure`
1. Sur le nœud exécutant Puma, assurez-vous que les éléments suivants sont définis dans `/etc/gitlab/gitlab.rb`

   ```ruby
   gitlab_rails['db_host'] = 'PGBOUNCER_HOST'
   gitlab_rails['db_port'] = '6432'
   gitlab_rails['db_password'] = 'SQL_USER_PASSWORD'
   ```

1. Exécutez `gitlab-ctl reconfigure`
1. À ce stade, votre instance devrait se connecter à la base de données via PgBouncer. Si vous rencontrez des problèmes, consultez la section [Dépannage](#troubleshooting)

## Sauvegardes {#backups}

Ne sauvegardez pas et ne restaurez pas GitLab via une connexion PgBouncer : cela provoque une interruption de service GitLab.

[En savoir plus à ce sujet et sur la façon de reconfigurer les sauvegardes](../backup_restore/backup_gitlab.md#back-up-and-restore-for-installations-using-pgbouncer).

## Activer la surveillance {#enable-monitoring}

Si vous activez la surveillance, elle doit être activée sur tous les serveurs PgBouncer.

1. Créez/modifiez `/etc/gitlab/gitlab.rb` et ajoutez la configuration suivante :

   ```ruby
   # Enable service discovery for Prometheus
   consul['enable'] = true
   consul['monitoring_service_discovery'] =  true

   # Replace placeholders
   # Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z
   # with the addresses of the Consul server nodes
   consul['configuration'] = {
      retry_join: %w(Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z),
   }

   # Set the network addresses that the exporters will listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   pgbouncer_exporter['listen_address'] = '0.0.0.0:9188'
   ```

1. Exécutez `sudo gitlab-ctl reconfigure` pour compiler la configuration.

## Console d'administration {#administrative-console}

Dans les installations de packages Linux, une commande est fournie pour se connecter automatiquement à la console d'administration PgBouncer. Consultez la [documentation PgBouncer](https://www.pgbouncer.org/usage.html#admin-console) pour des instructions détaillées sur la façon d'interagir avec la console.

Pour démarrer une session, exécutez la commande suivante et fournissez le mot de passe pour l'utilisateur `pgbouncer` :

```shell
sudo gitlab-ctl pgb-console
```

Pour obtenir des informations de base sur l'instance :

```shell
pgbouncer=# show databases; show clients; show servers;
        name         |   host    | port |      database       | force_user | pool_size | reserve_pool | pool_mode | max_connections | current_connections
---------------------+-----------+------+---------------------+------------+-----------+--------------+-----------+-----------------+---------------------
 gitlabhq_production | 127.0.0.1 | 5432 | gitlabhq_production |            |       100 |            5 |           |               0 |                   1
 pgbouncer           |           | 6432 | pgbouncer           | pgbouncer  |         2 |            0 | statement |               0 |                   0
(2 rows)

 type |   user    |      database       | state  |   addr    | port  | local_addr | local_port |    connect_time     |    request_time     |    ptr    | link
| remote_pid | tls
------+-----------+---------------------+--------+-----------+-------+------------+------------+---------------------+---------------------+-----------+------
+------------+-----
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44590 | 127.0.0.1  |       6432 | 2018-04-24 22:13:10 | 2018-04-24 22:17:10 | 0x12444c0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44592 | 127.0.0.1  |       6432 | 2018-04-24 22:13:10 | 2018-04-24 22:17:10 | 0x12447c0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44594 | 127.0.0.1  |       6432 | 2018-04-24 22:13:10 | 2018-04-24 22:17:10 | 0x1244940 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44706 | 127.0.0.1  |       6432 | 2018-04-24 22:14:22 | 2018-04-24 22:16:31 | 0x1244ac0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44708 | 127.0.0.1  |       6432 | 2018-04-24 22:14:22 | 2018-04-24 22:15:15 | 0x1244c40 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44794 | 127.0.0.1  |       6432 | 2018-04-24 22:15:15 | 2018-04-24 22:15:15 | 0x1244dc0 |
|          0 |
 C    | gitlab    | gitlabhq_production | active | 127.0.0.1 | 44798 | 127.0.0.1  |       6432 | 2018-04-24 22:15:15 | 2018-04-24 22:16:31 | 0x1244f40 |
|          0 |
 C    | pgbouncer | pgbouncer           | active | 127.0.0.1 | 44660 | 127.0.0.1  |       6432 | 2018-04-24 22:13:51 | 2018-04-24 22:17:12 | 0x1244640 |
|          0 |
(8 rows)

 type |  user  |      database       | state |   addr    | port | local_addr | local_port |    connect_time     |    request_time     |    ptr    | link | rem
ote_pid | tls
------+--------+---------------------+-------+-----------+------+------------+------------+---------------------+---------------------+-----------+------+----
--------+-----
 S    | gitlab | gitlabhq_production | idle  | 127.0.0.1 | 5432 | 127.0.0.1  |      35646 | 2018-04-24 22:15:15 | 2018-04-24 22:17:10 | 0x124dca0 |      |
  19980 |
(1 row)
```

## Procédure pour contourner PgBouncer {#procedure-for-bypassing-pgbouncer}

### Installations de packages Linux {#linux-package-installations}

Certaines modifications de base de données doivent être effectuées directement, et non via PgBouncer.

Les principales tâches concernées sont les [restaurations de bases de données](../backup_restore/backup_gitlab.md#back-up-and-restore-for-installations-using-pgbouncer) et les [mises à niveau GitLab avec des migrations de bases de données](../../update/zero_downtime.md).

1. Pour trouver le nœud primaire, exécutez la commande suivante sur un nœud de base de données :

   ```shell
   sudo gitlab-ctl patroni members
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` sur le nœud d'application sur lequel vous effectuez la tâche, et mettez à jour `gitlab_rails['db_host']` et `gitlab_rails['db_port']` avec l'hôte et le port du nœud primaire de la base de données.

1. Exécutez la reconfiguration :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Une fois les tâches ou la procédure effectuées, repassez à l'utilisation de PgBouncer :

1. Reconfigurez `/etc/gitlab/gitlab.rb` pour pointer vers PgBouncer.
1. Exécutez la reconfiguration :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Installations de chart Helm {#helm-chart-installations}

Les déploiements à haute disponibilité doivent également contourner PgBouncer pour les mêmes raisons que les déploiements basés sur des packages Linux. Pour les installations de chart Helm :

- Les tâches de sauvegarde et de restauration de base de données sont effectuées par le conteneur toolbox.
- Les tâches de migration sont effectuées par le conteneur migrations.

Vous devez remplacer le port PostgreSQL sur chaque sous-chart, afin que ces tâches puissent s'exécuter et se connecter directement à PostgreSQL :

- [Toolbox](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/charts/gitlab/charts/toolbox/values.yaml#L40)
- [Migrations](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/charts/gitlab/charts/migrations/values.yaml#L46)

## Réglage fin {#fine-tuning}

Les paramètres par défaut de PgBouncer conviennent à la majorité des installations. Dans des cas spécifiques, vous pouvez modifier les variables spécifiques aux performances et aux ressources pour augmenter le débit possible ou limiter l'utilisation des ressources qui pourrait entraîner un épuisement de la mémoire sur la base de données.

Vous pouvez trouver les paramètres et la documentation correspondante dans la [documentation officielle de PgBouncer](https://www.pgbouncer.org/config.html). Ci-dessous sont listés les plus pertinents et leurs valeurs par défaut sur une installation de package Linux :

- `pgbouncer['max_client_conn']` (par défaut : `2048`, dépend des limites des descripteurs de fichiers du serveur) Il s'agit du pool « frontend » dans PgBouncer : connexions de Rails vers PgBouncer.
- `pgbouncer['default_pool_size']` (par défaut : `100`) Il s'agit du pool « backend » dans PgBouncer : connexions de PgBouncer vers la base de données.

Le nombre idéal pour `default_pool_size` doit être suffisant pour gérer tous les services provisionnés qui doivent accéder à la base de données. Pour des conseils détaillés sur le calcul de la taille de pool requise, consultez [Régler PostgreSQL](tune.md).

Si vous utilisez plusieurs PgBouncer avec un équilibreur de charge interne, vous pouvez diviser `default_pool_size` par le nombre d'instances pour garantir une charge uniformément répartie entre eux.

`pgbouncer['max_client_conn']` est la limite stricte des connexions que PgBouncer peut accepter. Il est peu probable que vous ayez besoin de modifier cette valeur. Si vous atteignez cette limite, vous pouvez envisager d'ajouter des PgBouncers supplémentaires avec un équilibreur de charge interne.

Lors de la configuration des limites pour un PgBouncer pointant vers la base de données de suivi Geo, vous pouvez probablement ignorer `puma` dans l'équation, car il n'accède à cette base de données que de manière sporadique.

## Dépannage {#troubleshooting}

Si vous rencontrez des problèmes de connexion via PgBouncer, le premier endroit à vérifier est toujours les journaux :

```shell
sudo gitlab-ctl tail pgbouncer
```

De plus, vous pouvez vérifier la sortie de `show databases` dans la [console d'administration](#administrative-console). Dans la sortie, vous devriez voir des valeurs dans le champ `host` pour la base de données `gitlabhq_production`. De plus, `current_connections` doit être supérieur à 1.

### Message : `LOG:  invalid CIDR mask in address` {#message-log--invalid-cidr-mask-in-address}

Consultez le correctif suggéré [dans la documentation Geo](../geo/replication/troubleshooting/postgresql_replication.md#message-log--invalid-cidr-mask-in-address).

### Message : `LOG:  invalid IP mask "md5": Name or service not known` {#message-log--invalid-ip-mask-md5-name-or-service-not-known}

Consultez le correctif suggéré [dans la documentation Geo](../geo/replication/troubleshooting/postgresql_replication.md#message-log--invalid-ip-mask-md5-name-or-service-not-known).
