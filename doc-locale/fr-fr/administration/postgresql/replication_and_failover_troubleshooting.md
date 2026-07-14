---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage de la réplication et du basculement PostgreSQL pour les installations de packages Linux
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Lorsque vous travaillez avec la réplication et le basculement PostgreSQL, vous pouvez rencontrer les problèmes suivants.

## Les modifications de Consul et PostgreSQL ne prennent pas effet {#consul-and-postgresql-changes-not-taking-effect}

En raison des impacts potentiels, `gitlab-ctl reconfigure` recharge uniquement Consul et PostgreSQL, il ne redémarre pas les services. Cependant, toutes les modifications ne peuvent pas être activées par un rechargement.

Pour redémarrer l'un ou l'autre service, exécutez `gitlab-ctl restart SERVICE`

Pour PostgreSQL, il est généralement sûr de redémarrer le nœud leader par défaut. Le basculement automatique utilise par défaut un délai d'expiration d'1 minute. Si la base de données revient avant ce délai, aucune autre action n'est nécessaire.

Sur les nœuds serveur Consul, il est important de [redémarrer le service Consul](../consul.md#restart-consul) de manière contrôlée.

## Erreur PgBouncer `ERROR: pgbouncer cannot connect to server` {#pgbouncer-error-error-pgbouncer-cannot-connect-to-server}

Vous pouvez obtenir cette erreur lors de l'exécution de `gitlab-rake gitlab:db:configure` ou vous pouvez voir l'erreur dans le fichier journal PgBouncer.

```plaintext
PG::ConnectionBad: ERROR:  pgbouncer cannot connect to server
```

Le problème peut être que l'adresse IP de votre nœud PgBouncer n'est pas incluse dans le paramètre `trust_auth_cidr_addresses` dans `/etc/gitlab/gitlab.rb` sur les nœuds de base de données.

Vous pouvez confirmer qu'il s'agit bien du problème en vérifiant le journal PostgreSQL sur le nœud de base de données leader. Si vous voyez l'erreur suivante, alors `trust_auth_cidr_addresses` est le problème.

```plaintext
2018-03-29_13:59:12.11776 FATAL:  no pg_hba.conf entry for host "123.123.123.123", user "pgbouncer", database "gitlabhq_production", SSL off
```

Pour résoudre le problème, ajoutez l'adresse IP à `/etc/gitlab/gitlab.rb`.

```ruby
postgresql['trust_auth_cidr_addresses'] = %w(123.123.123.123/32 <other_cidrs>)
```

[Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

## Les nœuds PgBouncer ne basculent pas après un switchover Patroni {#pgbouncer-nodes-dont-fail-over-after-patroni-switchover}

En raison d'un [problème connu](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8166) qui affecte les versions de GitLab antérieures à la version 16.5.0, le basculement automatique des nœuds PgBouncer ne se produit pas après un [switchover Patroni](replication_and_failover.md#manual-failover-procedure-for-patroni). Dans cet exemple, GitLab n'a pas réussi à détecter une base de données en pause, puis a tenté d'effectuer un `RESUME` sur une base de données non mise en pause :

```plaintext
INFO -- : Running: gitlab-ctl pgb-notify --pg-database gitlabhq_production --newhost database7.example.com --user pgbouncer --hostuser gitlab-consul
ERROR -- : STDERR: Error running command: GitlabCtl::Errors::ExecutionError
ERROR -- : STDERR: ERROR: ERROR:  database gitlabhq_production is not paused
```

Pour vous assurer qu'un [switchover Patroni](replication_and_failover.md#manual-failover-procedure-for-patroni) réussit, vous devez redémarrer manuellement le service PgBouncer sur tous les nœuds PgBouncer avec cette commande :

```shell
gitlab-ctl restart pgbouncer
```

## Réinitialiser un réplica {#reinitialize-a-replica}

Si un réplica ne peut pas démarrer ou rejoindre le cluster, ou lorsqu'il prend du retard et ne peut pas rattraper son retard, il peut être nécessaire de réinitialiser le réplica :

1. [Vérifier le statut de réplication](replication_and_failover.md#check-replication-status) pour confirmer quel serveur doit être réinitialisé. Par exemple :

   ```plaintext
   + Cluster: postgresql-ha (6970678148837286213) ------+---------+--------------+----+-----------+
   | Member                              | Host         | Role    | State        | TL | Lag in MB |
   +-------------------------------------+--------------+---------+--------------+----+-----------+
   | gitlab-database-1.example.com       | 172.18.0.111 | Replica | running      | 55 |         0 |
   | gitlab-database-2.example.com       | 172.18.0.112 | Replica | start failed |    |   unknown |
   | gitlab-database-3.example.com       | 172.18.0.113 | Leader  | running      | 55 |           |
   +-------------------------------------+--------------+---------+--------------+----+-----------+
   ```

1. Connectez-vous au serveur défaillant et réinitialisez la base de données et la réplication. Patroni arrête PostgreSQL sur ce serveur, supprime le répertoire de données et le réinitialise à partir de zéro :

   ```shell
   sudo gitlab-ctl patroni reinitialize-replica --member gitlab-database-2.example.com
   ```

   Cette commande peut être exécutée sur n'importe quel nœud Patroni, mais notez que `sudo gitlab-ctl patroni reinitialize-replica` sans `--member` redémarre le serveur sur lequel elle est exécutée. Vous devriez l'exécuter localement sur le serveur défaillant pour réduire le risque de perte de données non intentionnelle.
1. Surveiller les journaux :

   ```shell
   sudo gitlab-ctl tail patroni
   ```

## Réinitialiser l'état Patroni dans Consul {#reset-the-patroni-state-in-consul}

> [!warning]
> La réinitialisation de l'état Patroni dans Consul est un processus potentiellement destructeur. Assurez-vous d'avoir d'abord une sauvegarde de base de données valide.

En dernier recours, vous pouvez réinitialiser complètement l'état Patroni dans Consul.

Cela peut être nécessaire si votre cluster Patroni est dans un état inconnu ou défectueux et qu'aucun nœud ne peut démarrer :

```plaintext
+ Cluster: postgresql-ha (6970678148837286213) ------+---------+---------+----+-----------+
| Member                              | Host         | Role    | State   | TL | Lag in MB |
+-------------------------------------+--------------+---------+---------+----+-----------+
| gitlab-database-1.example.com       | 172.18.0.111 | Replica | stopped |    |   unknown |
| gitlab-database-2.example.com       | 172.18.0.112 | Replica | stopped |    |   unknown |
| gitlab-database-3.example.com       | 172.18.0.113 | Replica | stopped |    |   unknown |
+-------------------------------------+--------------+---------+---------+----+-----------+
```

Avant de supprimer l'état Patroni dans Consul, [essayez de résoudre les erreurs `gitlab-ctl`](#errors-running-gitlab-ctl) sur les nœuds Patroni.

Ce processus entraîne un cluster Patroni réinitialisé lorsque le premier nœud Patroni démarre.

Pour réinitialiser l'état Patroni dans Consul :

1. Notez le nœud Patroni qui était le leader, ou celui que l'application considère comme le leader actuel, si l'état actuel en montre plusieurs, ou aucun :
   - Consultez les nœuds PgBouncer dans `/var/opt/gitlab/consul/databases.ini`, qui contient le nom d'hôte du leader actuel.
   - Consultez les journaux Patroni `/var/log/gitlab/patroni/current` (ou les journaux plus anciens rotatifs et compressés `/var/log/gitlab/patroni/@40000*`) sur tous les nœuds de base de données pour voir quel serveur a été le plus récemment identifié comme leader par le cluster :

     ```plaintext
     INFO: no action. I am a secondary (database1.local) and following a leader (database2.local)
     ```

1. Arrêter Patroni sur tous les nœuds :

   ```shell
   sudo gitlab-ctl stop patroni
   ```

1. Réinitialiser l'état dans Consul :

   ```shell
   /opt/gitlab/embedded/bin/consul kv delete -recurse /service/postgresql-ha/
   ```

1. Démarrer un nœud Patroni, qui initialise le cluster Patroni pour élire un leader. Il est fortement recommandé de démarrer le leader précédent (noté à la première étape), afin de ne pas perdre les écritures existantes qui n'ont peut-être pas été répliquées en raison de l'état défectueux du cluster :

   ```shell
   sudo gitlab-ctl start patroni
   ```

1. Démarrer tous les autres nœuds Patroni qui rejoignent le cluster Patroni en tant que réplicas :

   ```shell
   sudo gitlab-ctl start patroni
   ```

Si vous rencontrez encore des problèmes, l'étape suivante consiste à restaurer la dernière sauvegarde valide.

## Erreurs dans le journal Patroni concernant une entrée `pg_hba.conf` pour `127.0.0.1` {#errors-in-the-patroni-log-about-a-pg_hbaconf-entry-for-127001}

L'entrée de journal suivante dans le journal Patroni indique que la réplication ne fonctionne pas et qu'une modification de configuration est nécessaire :

```plaintext
FATAL:  no pg_hba.conf entry for replication connection from host "127.0.0.1", user "gitlab_replicator"
```

Pour résoudre le problème, assurez-vous que l'interface de bouclage est incluse dans la liste des adresses CIDR :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   postgresql['trust_auth_cidr_addresses'] = %w(<other_cidrs> 127.0.0.1/32)
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
1. Vérifiez que [tous les réplicas sont synchronisés](replication_and_failover.md#check-replication-status)

## Membres Patroni affichant un redémarrage en attente {#patroni-members-showing-as-pending-restart}

La sortie de `gitlab-ctl patroni members` peut afficher les membres Patroni sur un site secondaire avec un statut de redémarrage en attente :

```shell
secondary-site:postgresql-1> gitlab-ctl patroni members
+ Cluster: postgresql-ha ------------------------------------------------------------------+
| Member         | Host      | Role           | State   | TL | Lag in MB | Pending restart |
+----------------+-----------+----------------+---------+----+-----------+-----------------+
| patroni-1 | 10.20.0.1 | Replica        | running | 27 |         0 | *               |
| patroni-2 | 10.20.0.2 | Replica        | running | 27 |         5 | *               |
| patroni-3 | 10.20.0.3 | Standby Leader | running | 27 |           | *               |
+----------------+-----------+----------------+---------+----+-----------+----------
```

Le statut de redémarrage en attente signifie que ces nœuds attendent un redémarrage pour appliquer certaines modifications de configuration.

Pour savoir quels sont ces paramètres de redémarrage en attente, exécutez la commande suivante dans l'instance que vous devez vérifier :

```shell
sudo gitlab-psql -c "select name, setting,  short_desc, sourcefile, sourceline  from pg_settings where pending_restart"
```

Pour appliquer les modifications de configuration en attente, redémarrez les nœuds affectés :

1. Pour les nœuds réplicas, exécutez `sudo gitlab-ctl restart patroni`.
1. Pour le nœud leader, envisagez d'abord d'effectuer un basculement ou exécutez `sudo gitlab-ctl reload patroni` pour éviter les interruptions de service.

## Erreur : le point de départ demandé est en avance sur la position de vidage du Write Ahead Log (WAL) {#error-requested-start-point-is-ahead-of-the-write-ahead-log-wal-flush-position}

Cette erreur dans les journaux Patroni indique que la base de données ne réplique pas :

```plaintext
FATAL:  could not receive data from WAL stream:
ERROR:  requested starting point 0/5000000 is ahead of the WAL flush position of this server 0/4000388
```

Cet exemple d'erreur provient d'un réplica qui était initialement mal configuré et n'avait jamais répliqué.

Corrigez-la [en réinitialisant le réplica](#reinitialize-a-replica).

## Patroni ne parvient pas à démarrer avec `MemoryError` {#patroni-fails-to-start-with-memoryerror}

Patroni peut ne pas parvenir à démarrer, en enregistrant une erreur et une trace de pile :

```plaintext
MemoryError
Traceback (most recent call last):
  File "/opt/gitlab/embedded/bin/patroni", line 8, in <module>
    sys.exit(main())
[..]
  File "/opt/gitlab/embedded/lib/python3.7/ctypes/__init__.py", line 273, in _reset_cache
    CFUNCTYPE(c_int)(lambda: None)
```

Si la trace de pile se termine par `CFUNCTYPE(c_int)(lambda: None)`, ce code déclenche `MemoryError` si le serveur Linux a été renforcé pour des raisons de sécurité.

Le code amène Python à écrire des fichiers exécutables temporaires, et s'il ne peut pas trouver de système de fichiers pour le faire. Par exemple, si `noexec` est défini sur le système de fichiers `/tmp`, cela échoue avec `MemoryError` ([en savoir plus dans le ticket](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6184)).

## Erreurs lors de l'exécution de `gitlab-ctl` {#errors-running-gitlab-ctl}

Les nœuds Patroni peuvent se retrouver dans un état où les commandes `gitlab-ctl` échouent et où `gitlab-ctl reconfigure` ne peut pas réparer le nœud.

Si cela coïncide avec une mise à niveau de version de PostgreSQL, [suivez une procédure différente](#postgresql-major-version-upgrade-fails-on-a-patroni-replica)

Un symptôme courant est que `gitlab-ctl` ne peut pas déterminer les informations dont il a besoin sur l'installation si le serveur de base de données ne parvient pas à démarrer :

```plaintext
Malformed configuration JSON file found at /opt/gitlab/embedded/nodes/<HOSTNAME>.json.
This usually happens when your last run of `gitlab-ctl reconfigure` didn't complete successfully.
```

```plaintext
Error while reinitializing replica on the current node: Attributes not found in
/opt/gitlab/embedded/nodes/<HOSTNAME>.json, has reconfigure been run yet?
```

De même, le fichier de nœuds (`/opt/gitlab/embedded/nodes/<HOSTNAME>.json`) devrait contenir beaucoup d'informations, mais peut être créé avec seulement :

```json
{
  "name": "<HOSTNAME>"
}
```

Le processus suivant pour résoudre ce problème inclut la réinitialisation de ce réplica : l'état actuel de PostgreSQL sur ce nœud est supprimé :

1. Arrêter les services Patroni et (si présent) PostgreSQL :

   ```shell
   sudo gitlab-ctl status
   sudo gitlab-ctl stop patroni
   sudo gitlab-ctl stop postgresql
   ```

1. Supprimer `/var/opt/gitlab/postgresql/data` au cas où son état empêcherait PostgreSQL de démarrer :

   ```shell
   cd /var/opt/gitlab/postgresql
   sudo rm -rf data
   ```

   > [!warning]
   > Faites attention à cette étape pour éviter toute perte de données. Cette étape peut également être réalisée en renommant `data/` : assurez-vous qu'il y a suffisamment d'espace disque libre pour une nouvelle copie de la base de données primaire, et supprimez le répertoire supplémentaire une fois le réplica corrigé.

1. PostgreSQL n'étant pas en cours d'exécution, le fichier de nœuds est maintenant créé avec succès :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Démarrer Patroni :

   ```shell
   sudo gitlab-ctl start patroni
   ```

1. Surveiller les journaux et vérifier l'état du cluster :

   ```shell
   sudo gitlab-ctl tail patroni
   sudo gitlab-ctl patroni members
   ```

1. Réexécuter `reconfigure` :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Réinitialiser le réplica si `gitlab-ctl patroni members` indique que c'est nécessaire :

   ```shell
   sudo gitlab-ctl patroni reinitialize-replica
   ```

Si cette procédure ne fonctionne pas et si le cluster ne peut pas élire un leader, [il existe un autre correctif](#reset-the-patroni-state-in-consul) qui ne doit être utilisé qu'en dernier recours.

## La mise à niveau de version majeure de PostgreSQL échoue sur un réplica Patroni {#postgresql-major-version-upgrade-fails-on-a-patroni-replica}

Un réplica Patroni peut se retrouver bloqué dans une boucle lors de l'exécution de `gitlab-ctl pg-upgrade`, et la mise à niveau échoue.

Un exemple de symptômes est le suivant :

1. Un service `postgresql` est défini, ce qui ne devrait généralement pas être présent sur un nœud Patroni. Il est présent parce que `gitlab-ctl pg-upgrade` l'ajoute pour créer une nouvelle base de données vide :

   ```plaintext
   run: patroni: (pid 1972) 1919s; run: log: (pid 1971) 1919s
   down: postgresql: 1s, normally up, want up; run: log: (pid 1973) 1919s
   ```

1. PostgreSQL génère des entrées de journal `PANIC` dans `/var/log/gitlab/postgresql/current` pendant que Patroni supprime `/var/opt/gitlab/postgresql/data` dans le cadre de la réinitialisation du réplica :

   ```plaintext
   DETAIL:  Could not open file "pg_xact/0000": No such file or directory.
   WARNING:  terminating connection because of crash of another server process
   LOG:  all server processes terminated; reinitializing
   PANIC:  could not open file "global/pg_control": No such file or directory
   ```

1. Dans `/var/log/gitlab/patroni/current`, Patroni enregistre les éléments suivants. La version PostgreSQL locale est différente de celle du leader du cluster :

   ```plaintext
   INFO: trying to bootstrap from leader 'HOSTNAME'
   pg_basebackup: incompatible server version 12.6
   pg_basebackup: removing data directory "/var/opt/gitlab/postgresql/data"
   ERROR: Error when fetching backup: pg_basebackup exited with code=1
   ```

Cette solution de contournement s'applique lorsque le cluster Patroni est dans l'état suivant :

- Le [leader a été mis à niveau avec succès vers la nouvelle version majeure](replication_and_failover.md#upgrading-postgresql-major-version-in-a-patroni-cluster).
- L'étape de mise à niveau de PostgreSQL sur les réplicas échoue.

Cette solution de contournement complète la mise à niveau de PostgreSQL sur un réplica Patroni en configurant le nœud pour utiliser la nouvelle version de PostgreSQL, puis en le réinitialisant en tant que réplica dans le nouveau cluster créé lors de la mise à niveau du leader :

1. Vérifier l'état du cluster sur tous les nœuds pour confirmer quel est le leader et dans quel état se trouvent les réplicas

   ```shell
   sudo gitlab-ctl patroni members
   ```

1. Réplica : vérifier quelle version de PostgreSQL est active :

   ```shell
   sudo ls -al /opt/gitlab/embedded/bin | grep postgres
   ```

1. Réplica : s'assurer que le fichier de nœuds est correct et que `gitlab-ctl` peut s'exécuter. Cela résout le problème des [erreurs lors de l'exécution de `gitlab-ctl`](#errors-running-gitlab-ctl) si le réplica présente également l'une de ces erreurs :

   ```shell
   sudo gitlab-ctl stop patroni
   sudo gitlab-ctl reconfigure
   ```

1. Réplica : reconnecter les binaires PostgreSQL à la version requise pour corriger l'erreur `incompatible server version` :

   1. Modifiez `/etc/gitlab/gitlab.rb` et spécifiez la version requise :

      ```ruby
      postgresql['version'] = 13
      ```

   1. Reconfigurer GitLab :

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. Vérifier que les binaires sont reconnectés. Les binaires distribués pour PostgreSQL varient selon les versions majeures, il est courant d'avoir un petit nombre de liens symboliques incorrects :

      ```shell
      sudo ls -al /opt/gitlab/embedded/bin | grep postgres
      ```

1. Réplica : s'assurer que PostgreSQL est entièrement réinitialisé pour la version spécifiée :

   ```shell
   cd /var/opt/gitlab/postgresql
   sudo rm -rf data
   sudo gitlab-ctl reconfigure
   ```

1. Réplica : surveiller éventuellement la base de données dans deux sessions de terminal supplémentaires :

   - L'utilisation du disque augmente au fur et à mesure que `pg_basebackup` s'exécute. Suivre la progression de l'initialisation du réplica avec :

     ```shell
     cd /var/opt/gitlab/postgresql
     watch du -sh data
     ```

   - Surveiller le processus dans les journaux :

     ```shell
     sudo gitlab-ctl tail patroni
     ```

1. Réplica :  Démarrer Patroni pour réinitialiser le réplica :

   ```shell
   sudo gitlab-ctl start patroni
   ```

1. Réplica :  Une fois terminé, supprimer la version codée en dur de `/etc/gitlab/gitlab.rb` :

   1. Modifiez `/etc/gitlab/gitlab.rb` et supprimez `postgresql['version']`.
   1. Reconfigurer GitLab :

      ```shell
      sudo gitlab-ctl reconfigure
      ```

   1. Vérifier que les bons binaires sont liés :

      ```shell
      sudo ls -al /opt/gitlab/embedded/bin | grep postgres
      ```

1. Vérifier l'état du cluster sur tous les nœuds :

   ```shell
   sudo gitlab-ctl patroni members
   ```

Répétez cette procédure sur l'autre réplica si nécessaire.

## Réplicas PostgreSQL bloqués dans une boucle lors de leur création {#postgresql-replicas-stuck-in-loop-while-being-created}

Si les réplicas PostgreSQL semblent migrer mais redémarrent ensuite en boucle, vérifiez les permissions du dossier `/opt/gitlab-data/postgresql/` sur vos réplicas et votre serveur primaire.

Vous pouvez également voir ce message d'erreur dans les journaux : `could not get COPY data stream: ERROR: could not open file "<file>" Permission denied`.

## Problèmes avec d'autres composants {#issues-with-other-components}

Si vous rencontrez un problème avec un composant non décrit ici, assurez-vous de consulter la section de dépannage de la page de documentation spécifique correspondante :

- [Consul](../consul.md#troubleshooting-consul)
- [PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#troubleshooting)
