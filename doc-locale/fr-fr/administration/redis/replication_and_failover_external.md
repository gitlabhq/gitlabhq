---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Réplication et basculement Redis avec votre propre instance
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Si vous hébergez GitLab sur un fournisseur cloud, vous pouvez éventuellement utiliser un service géré pour Redis. Par exemple, AWS propose ElastiCache qui exécute Redis.

Vous pouvez également choisir de gérer votre propre instance Redis séparément du package Linux.

## Prérequis {#requirements}

Voici les prérequis pour fournir votre propre instance Redis :

- Trouvez la version minimale de Redis requise sur la [page des prérequis](../../install/requirements.md).
- Redis en mode autonome ou Redis haute disponibilité avec Sentinel sont pris en charge. Redis Cluster n'est pas pris en charge.
- Redis géré par des fournisseurs cloud tels qu'AWS ElastiCache fonctionne correctement. Si ces services prennent en charge la haute disponibilité, assurez-vous qu'il ne s'agit **pas** du type Redis Cluster.

Notez l'adresse IP ou le nom d'hôte, le port et le mot de passe (si requis) du nœud Redis.

## Redis comme service géré chez un fournisseur cloud {#redis-as-a-managed-service-in-a-cloud-provider}

1. Configurez Redis conformément aux [prérequis](#requirements).
1. Configurez les serveurs d'application GitLab avec les informations de connexion appropriées pour votre service Redis externe dans votre fichier `/etc/gitlab/gitlab.rb` :

   Lors de l'utilisation d'une instance Redis unique :

   ```ruby
   redis['enable'] = false

   gitlab_rails['redis_host'] = '<redis_instance_url>'
   gitlab_rails['redis_port'] = '<redis_instance_port>'

   # Required if Redis authentication is configured on the Redis node
   gitlab_rails['redis_password'] = '<redis_password>'

   # Set to true if instance is using Redis SSL
   gitlab_rails['redis_ssl'] = true
   ```

   Lors de l'utilisation d'instances Redis Cache et Persistent séparées :

   ```ruby
   redis['enable'] = false

   # Default Redis connection
   gitlab_rails['redis_host'] = '<redis_persistent_instance_url>'
   gitlab_rails['redis_port'] = '<redis_persistent_instance_port>'
   gitlab_rails['redis_password'] = '<redis_persistent_password>'

   # Set to true if instance is using Redis SSL
   gitlab_rails['redis_ssl'] = true

   # Redis Cache connection
   # Replace `redis://` with `rediss://` if using SSL
   gitlab_rails['redis_cache_instance'] = 'redis://:<redis_cache_password>@<redis_cache_instance_url>:<redis_cache_instance_port>'
   ```

1. Reconfigurer pour que les modifications prennent effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Définir la politique d'éviction {#setting-the-eviction-policy}

Lors de l'exécution d'une instance Redis unique, la politique d'éviction doit être définie sur `noeviction`.

Si vous exécutez des instances Redis Cache et Persistent séparées, Cache doit être configuré comme un [cache Least Recently Used](https://redis.io/docs/latest/operate/rs/databases/memory-performance/eviction-policy/) (LRU) avec `allkeys-lru` tandis que Persistent doit être défini sur `noeviction`.

La configuration de ce paramètre dépend du fournisseur cloud ou du service, mais en général, les paramètres et valeurs suivants configurent un cache :

- `maxmemory-policy` = `allkeys-lru`
- `maxmemory-samples` = `5`

## Réplication et basculement Redis avec vos propres serveurs Redis {#redis-replication-and-failover-with-your-own-redis-servers}

Il s'agit de la documentation pour configurer une installation Redis évolutive lorsque vous avez installé Redis vous-même et que vous n'utilisez pas celui fourni avec les packages Linux, bien que l'utilisation des packages Linux soit fortement recommandée car nous les optimisons spécifiquement pour GitLab, et nous nous chargeons de mettre à jour Redis vers la dernière version prise en charge.

Notez également que vous pouvez choisir de remplacer toutes les références à `/home/git/gitlab/config/resque.yml` conformément aux paramètres Redis avancés décrits dans la [Documentation des fichiers de configuration](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/README.md).

Nous ne saurions trop insister sur l'importance de lire la documentation sur la [réplication et le basculement](replication_and_failover.md) du package Linux Redis HA, car elle fournit des informations précieuses sur la configuration de Redis. Lisez-la avant de poursuivre avec ce guide.

Avant de procéder à la configuration des nouvelles instances Redis, voici quelques prérequis :

- Tous les serveurs Redis de ce guide doivent être configurés pour utiliser une connexion TCP au lieu d'un socket. Pour configurer Redis afin d'utiliser des connexions TCP, vous devez définir à la fois `bind` et `port` dans le fichier de configuration Redis. Vous pouvez vous lier à toutes les interfaces (`0.0.0.0`) ou spécifier l'IP de l'interface souhaitée (par exemple, une interface d'un réseau interne).
- Depuis Redis 3.2, vous devez définir un mot de passe pour recevoir des connexions externes (`requirepass`).
- Si vous utilisez Redis avec Sentinel, vous devez également définir le même mot de passe pour la définition du mot de passe de réplica (`masterauth`) dans la même instance.

De plus, lisez les prérequis décrits dans [Réplication et basculement Redis avec le package Linux](replication_and_failover.md#requirements).

### Étape 1. Configuration de l'instance Redis principale {#step-1-configuring-the-primary-redis-instance}

En supposant que l'IP de l'instance Redis principale est `10.0.0.1` :

1. [Installez Redis](../../install/self_compiled/_index.md#8-redis).
1. Modifiez `/etc/redis/redis.conf` :

   ```conf
   ## Define a `bind` address pointing to a local IP that your other machines
   ## can reach you. If you really need to bind to an external accessible IP, make
   ## sure you add extra firewall rules to prevent unauthorized access:
   bind 10.0.0.1

   ## Define a `port` to force redis to listen on TCP so other machines can
   ## connect to it (default port is `6379`).
   port 6379

   ## Set up password authentication (use the same password in all nodes).
   ## The password should be defined equal for both `requirepass` and `masterauth`
   ## when setting up Redis to use with Sentinel.
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   ```

1. Redémarrez le service Redis pour que les modifications prennent effet.

### Étape 2. Configuration des instances Redis réplicas {#step-2-configuring-the-replica-redis-instances}

En supposant que l'IP de l'instance Redis réplica est `10.0.0.2` :

1. [Installez Redis](../../install/self_compiled/_index.md#8-redis).
1. Modifiez `/etc/redis/redis.conf` :

   ```conf
   ## Define a `bind` address pointing to a local IP that your other machines
   ## can reach you. If you really need to bind to an external accessible IP, make
   ## sure you add extra firewall rules to prevent unauthorized access:
   bind 10.0.0.2

   ## Define a `port` to force redis to listen on TCP so other machines can
   ## connect to it (default port is `6379`).
   port 6379

   ## Set up password authentication (use the same password in all nodes).
   ## The password should be defined equal for both `requirepass` and `masterauth`
   ## when setting up Redis to use with Sentinel.
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here

   ## Define `replicaof` pointing to the Redis primary instance with IP and port.
   replicaof 10.0.0.1 6379
   ```

1. Redémarrez le service Redis pour que les modifications prennent effet.
1. Répétez les étapes pour tous les autres nœuds réplicas.

### Étape 3. Configuration des instances Redis Sentinel {#step-3-configuring-the-redis-sentinel-instances}

Sentinel est un type spécial de serveur Redis. Il hérite de la plupart des options de configuration de base que vous pouvez définir dans `redis.conf`, avec des options spécifiques commençant par le préfixe `sentinel`.

En supposant que Redis Sentinel est installé sur la même instance que Redis principal avec l'IP `10.0.0.1` (certains paramètres peuvent se chevaucher avec le principal) :

1. [Installez Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/).
1. Modifiez `/etc/redis/sentinel.conf` :

   ```conf
   ## Define a `bind` address pointing to a local IP that your other machines
   ## can reach you. If you really need to bind to an external accessible IP, make
   ## sure you add extra firewall rules to prevent unauthorized access:
   bind 10.0.0.1

   ## Define a `port` to force Sentinel to listen on TCP so other machines can
   ## connect to it (default port is `6379`).
   port 26379

   ## Set up password authentication (use the same password in all nodes).
   ## The password should be defined equal for both `requirepass` and `masterauth`
   ## when setting up Redis to use with Sentinel.
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here

   ## Define with `sentinel auth-pass` the same shared password you have
   ## defined for both Redis primary and replicas instances.
   sentinel auth-pass gitlab-redis redis-password-goes-here

   ## Define with `sentinel monitor` the IP and port of the Redis
   ## primary node, and the quorum required to start a failover.
   sentinel monitor gitlab-redis 10.0.0.1 6379 2

   ## Define with `sentinel down-after-milliseconds` the time in `ms`
   ## that an unresponsive server is considered down.
   sentinel down-after-milliseconds gitlab-redis 10000

   ## Define a value for `sentinel failover_timeout` in `ms`. This has multiple
   ## meanings:
   ##
   ## * The time needed to re-start a failover after a previous failover was
   ##   already tried against the same primary by a given Sentinel, is two
   ##   times the failover timeout.
   ##
   ## * The time needed for a replica replicating to a wrong primary according
   ##   to a Sentinel current configuration, to be forced to replicate
   ##   with the right primary, is exactly the failover timeout (counting since
   ##   the moment a Sentinel detected the misconfiguration).
   ##
   ## * The time needed to cancel a failover that is already in progress but
   ##   did not produced any configuration change (REPLICAOF NO ONE yet not
   ##   acknowledged by the promoted replica).
   ##
   ## * The maximum time a failover in progress waits for all the replicas to be
   ##   reconfigured as replicas of the new primary. However even after this time
   ##   the replicas are reconfigured by the Sentinels anyway, but not with
   ##   the exact parallel-syncs progression as specified.
   sentinel failover_timeout 30000
   ```

1. Redémarrez le service Redis pour que les modifications prennent effet.
1. Répétez les étapes pour tous les autres nœuds Sentinel.

### Étape 4. Configuration de l'application GitLab {#step-4-configuring-the-gitlab-application}

Vous pouvez activer ou désactiver la prise en charge de Sentinel à tout moment dans les nouvelles installations ou les installations existantes. Du point de vue de l'application GitLab, il suffit d'avoir les informations d'identification correctes pour les nœuds Sentinel.

Bien qu'il ne nécessite pas une liste de tous les nœuds Sentinel, en cas de défaillance, il doit accéder à au moins l'un des nœuds répertoriés.

Les étapes suivantes doivent être effectuées sur le serveur d'application GitLab qui, idéalement, ne devrait pas avoir Redis ou des Sentinels sur la même machine :

1. Modifiez `/home/git/gitlab/config/resque.yml` en suivant l'exemple dans [`resque.yml.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/resque.yml.example), et décommentez les lignes Sentinel en pointant vers les informations d'identification correctes du serveur :

   ```yaml
   # resque.yaml
   production:
     url: redis://:redis-password-goes-here@gitlab-redis/
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

1. [Redémarrez GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

## Exemple de configuration minimale avec 1 principal, 2 réplicas et 3 sentinelles {#example-of-minimal-configuration-with-1-primary-2-replicas-and-3-sentinels}

Dans cet exemple, nous considérons que tous les serveurs disposent d'une interface réseau interne avec des IP dans la plage `10.0.0.x`, et qu'ils peuvent se connecter les uns aux autres en utilisant ces IP.

Dans une utilisation réelle, vous configureriez également des règles de pare-feu pour empêcher tout accès non autorisé depuis d'autres machines et bloquer le trafic en provenance de l'extérieur ([Internet](https://gitlab.com/gitlab-org/gitlab-foss/uploads/c4cc8cd353604bd80315f9384035ff9e/The_Internet_IT_Crowd.png)).

Pour cet exemple, **Sentinel 1** est configuré sur la même machine que le **Redis Primary**, **Sentinel 2** sur la même machine que le **Replica 1**, et **Sentinel 3** sur la même machine que le **Replica 2**.

Voici une liste et une description de chaque **machine** et de l'**IP** attribuée :

- `10.0.0.1` :  Redis Principal + Sentinel 1
- `10.0.0.2` :  Redis Réplica 1 + Sentinel 2
- `10.0.0.3` :  Redis Réplica 2 + Sentinel 3
- `10.0.0.4` :  Application GitLab

Après la configuration initiale, si un basculement est initié par les nœuds Sentinel, les nœuds Redis sont reconfigurés et le **Principal** change définitivement (y compris dans `redis.conf`) d'un nœud à l'autre, jusqu'à ce qu'un nouveau basculement soit initié.

La même chose se produit avec `sentinel.conf` qui est remplacé après l'exécution initiale, après que tout nouveau nœud sentinel commence à surveiller le **Principal**, ou qu'un basculement promeut un nœud **Principal** différent.

### Exemple de configuration pour Redis principal et Sentinel 1 {#example-configuration-for-redis-primary-and-sentinel-1}

1. Dans `/etc/redis/redis.conf` :

   ```conf
   bind 10.0.0.1
   port 6379
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   ```

1. Dans `/etc/redis/sentinel.conf` :

   ```conf
   bind 10.0.0.1
   port 26379
   sentinel auth-pass gitlab-redis redis-password-goes-here
   sentinel monitor gitlab-redis 10.0.0.1 6379 2
   sentinel down-after-milliseconds gitlab-redis 10000
   sentinel failover_timeout 30000
   ```

1. Redémarrez le service Redis pour que les modifications prennent effet.

### Exemple de configuration pour Redis réplica 1 et Sentinel 2 {#example-configuration-for-redis-replica-1-and-sentinel-2}

1. Dans `/etc/redis/redis.conf` :

   ```conf
   bind 10.0.0.2
   port 6379
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   replicaof 10.0.0.1 6379
   ```

1. Dans `/etc/redis/sentinel.conf` :

   ```conf
   bind 10.0.0.2
   port 26379
   sentinel auth-pass gitlab-redis redis-password-goes-here
   sentinel monitor gitlab-redis 10.0.0.1 6379 2
   sentinel down-after-milliseconds gitlab-redis 10000
   sentinel failover_timeout 30000
   ```

1. Redémarrez le service Redis pour que les modifications prennent effet.

### Exemple de configuration pour Redis réplica 2 et Sentinel 3 {#example-configuration-for-redis-replica-2-and-sentinel-3}

1. Dans `/etc/redis/redis.conf` :

   ```conf
   bind 10.0.0.3
   port 6379
   requirepass redis-password-goes-here
   masterauth redis-password-goes-here
   replicaof 10.0.0.1 6379
   ```

1. Dans `/etc/redis/sentinel.conf` :

   ```conf
   bind 10.0.0.3
   port 26379
   sentinel auth-pass gitlab-redis redis-password-goes-here
   sentinel monitor gitlab-redis 10.0.0.1 6379 2
   sentinel down-after-milliseconds gitlab-redis 10000
   sentinel failover_timeout 30000
   ```

1. Redémarrez le service Redis pour que les modifications prennent effet.

### Exemple de configuration de l'application GitLab {#example-configuration-of-the-gitlab-application}

1. Modifiez `/home/git/gitlab/config/resque.yml` :

   ```yaml
   production:
     url: redis://:redis-password-goes-here@gitlab-redis/
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

1. [Redémarrez GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

## Dépannage {#troubleshooting}

Consultez le [guide de dépannage Redis](troubleshooting.md).
