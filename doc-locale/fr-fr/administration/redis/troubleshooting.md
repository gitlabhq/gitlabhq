---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage de Redis
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

De nombreux éléments doivent être gérés avec soin pour que la configuration HA fonctionne comme prévu.

Avant de procéder au dépannage ci-dessous, vérifiez vos règles de pare-feu :

- Machines Redis
  - Accepter les connexions TCP sur `6379`
  - Se connecter aux autres machines Redis via TCP sur `6379`
- Machines Sentinel
  - Accepter les connexions TCP sur `26379`
  - Se connecter aux autres machines Sentinel via TCP sur `26379`
  - Se connecter aux machines Redis via TCP sur `6379`

## Vérification de base de l'activité Redis {#basic-redis-activity-check}

Commencez le dépannage Redis par une vérification de base de l'activité Redis :

1. Ouvrez un terminal sur votre serveur GitLab.
1. Exécutez `gitlab-redis-cli --stat` et observez la sortie pendant son exécution.
1. Accédez à votre interface GitLab et parcourez quelques pages. N'importe quelle page convient, par exemple les aperçus de groupes ou de projets, les tickets, ou les fichiers dans les dépôts.
1. Vérifiez à nouveau la sortie de `stat` et confirmez que les valeurs de `keys`, `clients`, `requests` et `connections` augmentent au fur et à mesure de votre navigation. Si les nombres augmentent, les fonctionnalités Redis de base fonctionnent et GitLab peut s'y connecter.

## Dépannage de la réplication Redis {#troubleshooting-redis-replication}

Vous pouvez vérifier si tout est correct en vous connectant à chaque serveur à l'aide de l'application `redis-cli` et en envoyant la commande `info replication` comme ci-dessous.

```shell
/opt/gitlab/embedded/bin/redis-cli -h <redis-host-or-ip> -a '<redis-password>' info replication
```

Lorsque vous êtes connecté à un Redis `Primary`, vous voyez le nombre de `replicas` connectés, ainsi qu'une liste de chacun avec les détails de connexion :

```plaintext
# Replication
role:master
connected_replicas:1
replica0:ip=10.133.5.21,port=6379,state=online,offset=208037514,lag=1
master_repl_offset:208037658
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:206989083
repl_backlog_histlen:1048576
```

Lorsqu'il s'agit d'un `replica`, vous voyez les détails de la connexion principale et si elle est `up` ou `down` :

```plaintext
# Replication
role:replica
master_host:10.133.1.58
master_port:6379
master_link_status:up
master_last_io_seconds_ago:1
master_sync_in_progress:0
replica_repl_offset:208096498
replica_priority:100
replica_read_only:1
connected_replicas:0
master_repl_offset:0
repl_backlog_active:0
repl_backlog_size:1048576
repl_backlog_first_byte_offset:0
repl_backlog_histlen:0
```

## Utilisation élevée du CPU sur l'instance Redis {#high-cpu-usage-on-redis-instance}

Par défaut, GitLab utilise plus de 600 files d'attente Sidekiq, chacune stockée sous forme de liste Redis. Chaque thread Sidekiq émet une commande `BRPOP` avec toutes les files d'attente listées dans une longue chaîne. L'utilisation du CPU par Redis augmente à mesure que le nombre de files d'attente et le taux d'appels `BRPOP` augmentent. Si votre instance GitLab comporte de nombreux processus Sidekiq, cela peut amener l'utilisation du CPU de Redis à approcher les 100 %. Une utilisation élevée du CPU dégrade significativement les performances de GitLab.

Pour réduire l'utilisation du CPU sur Redis causée par Sidekiq, vous pouvez :

- Utiliser les [règles de routage](../sidekiq/processing_specific_job_classes.md#routing-rules) pour réduire le nombre de files d'attente Sidekiq.
- Si vous utilisez GitLab 16.6 ou une version antérieure, augmentez la [variable d'environnement `SIDEKIQ_SEMI_RELIABLE_FETCH_TIMEOUT`](../environment_variables.md) pour améliorer l'utilisation du CPU sur Redis. Sur GitLab 16.7 et versions ultérieures, la [valeur par défaut est 5](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139583), ce qui devrait être suffisant.

L'option `SIDEKIQ_SEMI_RELIABLE_FETCH_TIMEOUT` réduit la surcharge causée par les déconnexions et reconnexions, mais augmente le délai d'arrêt de Sidekiq.

## Dépannage de Sentinel {#troubleshooting-sentinel}

Si vous obtenez une erreur telle que : `Redis::CannotConnectError: No sentinels available.`, il se peut que quelque chose ne soit pas correct dans vos fichiers de configuration ou que cela soit lié à [ce ticket](https://github.com/redis/redis-rb/issues/531).

Vous devez vous assurer que vous définissez la même valeur dans `redis['master_name']` et `redis['master_password']` que celle que vous avez définie pour votre nœud sentinel.

Le fonctionnement du connecteur Redis `redis-rb` avec sentinel est un peu contre-intuitif. Nous essayons de masquer la complexité dans le package Linux, mais cela nécessite tout de même quelques configurations supplémentaires.

Pour vous assurer que votre configuration est correcte :

1. Connectez-vous en SSH à votre serveur d'application GitLab
1. Accédez à la console Rails :

   ```shell
   # For Omnibus installations
   sudo gitlab-rails console

   # For source installations
   sudo -u git rails console -e production
   ```

1. Exécutez dans la console :

   ```ruby
   redis = Gitlab::Redis::SharedState.redis
   redis.info
   ```

   Laissez cet écran ouvert et procédez au déclenchement d'un basculement comme décrit ci-dessous.

1. Pour déclencher un basculement sur le Redis principal, connectez-vous en SSH au serveur Redis et exécutez :

   ```shell
   # port must match your primary redis port, and the sleep time must be a few seconds bigger than defined one
    redis-cli -h localhost -p 6379 DEBUG sleep 20
   ```

   > [!warning]
   > Cette action affecte les services et met l'instance hors service pendant jusqu'à 20 secondes. En cas de succès, l'instance devrait récupérer après ce délai.

1. Puis, de retour dans la console Rails de la première étape, exécutez :

   ```ruby
   redis.info
   ```

   Vous devriez voir un port différent après quelques secondes de délai (le temps de basculement/reconnexion).

## Dépannage d'un Redis non intégré avec une installation compilée depuis les sources {#troubleshooting-a-non-bundled-redis-with-a-self-compiled-installation}

Si vous obtenez une erreur dans GitLab comme `Redis::CannotConnectError: No sentinels available.`, il se peut que quelque chose ne soit pas correct dans vos fichiers de configuration ou que cela soit lié à [ce ticket en amont](https://github.com/redis/redis-rb/issues/531).

Vous devez vous assurer que `resque.yml` et `sentinel.conf` sont configurés correctement, sinon `redis-rb` ne fonctionne pas correctement.

Le `master-group-name` (`gitlab-redis`) défini dans (`sentinel.conf`) **must** être utilisé comme nom d'hôte dans GitLab (`resque.yml`) :

```conf
# sentinel.conf:
sentinel monitor gitlab-redis 10.0.0.1 6379 2
sentinel down-after-milliseconds gitlab-redis 10000
sentinel config-epoch gitlab-redis 0
sentinel leader-epoch gitlab-redis 0
```

```yaml
# resque.yaml
production:
  url: redis://:myredispassword@gitlab-redis/
  sentinels:
    -
      host: 10.0.0.1
      port: 26379  # point to sentinel, not to redis port
    -
      host: 10.0.0.2
      port: 26379  # point to sentinel, not to redis port
    -
      host: 10.0.0.3
      port: 26379  # point to sentinel, not to redis port
```

En cas de doute, consultez la documentation de [Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/).
