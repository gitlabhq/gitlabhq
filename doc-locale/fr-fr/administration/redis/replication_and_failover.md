---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Réplication Redis et basculement avec le paquet Linux
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Cette documentation concerne le paquet Linux. Pour utiliser votre propre instance Redis non intégrée, consultez [Réplication Redis et basculement avec votre propre instance](replication_and_failover_external.md).

Dans le jargon Redis, `primary` est appelé `master`. Dans ce document, `primary` est utilisé à la place de `master`, sauf dans les paramètres où `master` est requis.

L'utilisation de [Redis](https://redis.io/) dans un environnement évolutif est possible en utilisant une topologie **Principal** x **Replica** avec un service [Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/) pour surveiller et démarrer automatiquement la procédure de basculement.

Redis requiert une authentification s'il est utilisé avec Sentinel. Consultez la documentation [Redis Security](https://redis.io/docs/latest/operate/rc/security/) pour plus d'informations. Nous recommandons d'utiliser une combinaison d'un mot de passe Redis et de règles de pare-feu strictes pour sécuriser votre service Redis. Nous vous encourageons vivement à lire la documentation [Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/) avant de configurer Redis avec GitLab afin de bien comprendre la topologie et l'architecture.

Avant d'entrer dans les détails de la configuration de Redis et Redis Sentinel pour une topologie répliquée, assurez-vous de lire ce document dans son intégralité pour mieux comprendre comment les composants sont liés entre eux.

Vous avez besoin d'au moins `3` machines indépendantes : physiques ou des VMs s'exécutant sur des machines physiques distinctes. Il est essentiel que toutes les instances Redis primaires et réplicas s'exécutent sur des machines différentes. Si vous ne provisionnez pas les machines de cette manière spécifique, tout problème avec l'environnement partagé peut faire tomber l'ensemble de votre configuration.

Il est acceptable d'exécuter un Sentinel aux côtés d'une instance Redis primaire ou réplica. Il ne devrait cependant pas y avoir plus d'un Sentinel sur la même machine.

Vous devez également prendre en compte la topologie réseau sous-jacente, en vous assurant d'avoir une connectivité redondante entre Redis / Sentinel et les instances GitLab, sinon les réseaux deviennent un point de défaillance unique.

L'exécution de Redis dans un environnement à grande échelle nécessite quelques éléments :

- Plusieurs instances Redis
- Exécuter Redis dans une topologie **Principal** x **Replica**
- Plusieurs instances Sentinel
- Support applicatif et visibilité sur l'ensemble des instances Sentinel et Redis

Redis Sentinel peut gérer les tâches les plus importantes dans un environnement HA, notamment aider à maintenir les serveurs en ligne avec un temps d'arrêt minimal voire nul. Redis Sentinel :

- Surveille les instances **Principal** et **Replicas** pour vérifier leur disponibilité
- Promeut un **Replica** en **Principal** lorsque le **Principal** tombe en panne
- Rétrograde un **Principal** en **Replica** lorsque le **Principal** défaillant revient en ligne (pour éviter le partitionnement des données)
- Peut être interrogé par l'application pour toujours se connecter au serveur **Principal** actuel

Lorsqu'un **Principal** ne répond plus, il est de la responsabilité de l'application (dans notre cas GitLab) de gérer le délai d'attente et la reconnexion (en interrogeant un **Sentinel** pour un nouveau **Principal**).

Pour mieux comprendre comment configurer correctement Sentinel, lisez d'abord la documentation [Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/), car une mauvaise configuration peut entraîner une perte de données ou faire tomber l'ensemble de votre cluster, annulant ainsi l'effort de basculement.

## Configuration recommandée {#recommended-setup}

Pour une configuration minimale, vous devez installer le paquet Linux sur `3` machines **independent**, les deux avec **Redis** et **Sentinel** :

- Redis Principal + Sentinel
- Redis Réplica + Sentinel
- Redis Réplica + Sentinel

Si vous n'êtes pas sûr ou ne comprenez pas pourquoi et d'où provient le nombre de nœuds, lisez [Présentation de la configuration Redis](#redis-setup-overview) et [Présentation de la configuration Sentinel](#sentinel-setup-overview).

Pour une configuration recommandée pouvant résister à davantage de pannes, vous devez installer le paquet Linux sur `5` machines **independent**, les deux avec **Redis** et **Sentinel** :

- Redis Principal + Sentinel
- Redis Réplica + Sentinel
- Redis Réplica + Sentinel
- Redis Réplica + Sentinel
- Redis Réplica + Sentinel

### Présentation de la configuration Redis {#redis-setup-overview}

Vous devez disposer d'au moins `3` serveurs Redis : `1` primaire, `2` réplicas, et chacun doit être sur des machines indépendantes.

Vous pouvez avoir des nœuds Redis supplémentaires, ce qui permet de survivre à une situation où plusieurs nœuds tombent en panne. Lorsqu'il ne reste que `2` nœuds en ligne, un basculement n'est pas déclenché.

Par exemple, si vous avez `6` nœuds Redis, un maximum de `3` peuvent être hors ligne simultanément.

Il existe différentes exigences pour les nœuds Sentinel. Si vous les hébergez sur les mêmes machines Redis, vous devrez peut-être prendre ces restrictions en compte lors du calcul du nombre de nœuds à provisionner. Consultez la documentation [Présentation de la configuration Sentinel](#sentinel-setup-overview) pour plus d'informations.

Tous les nœuds Redis doivent être configurés de la même manière et avec des spécifications serveur similaires, car en cas de basculement, tout **Replica** peut être promu en tant que nouveau **Principal** par les serveurs Sentinel.

La réplication nécessite une authentification, vous devez donc définir un mot de passe pour protéger tous les nœuds Redis et les Sentinels. Ils partagent tous le même mot de passe, et toutes les instances doivent pouvoir communiquer entre elles sur le réseau.

### Présentation de la configuration Sentinel {#sentinel-setup-overview}

Les Sentinels surveillent à la fois les autres Sentinels et les nœuds Redis. Chaque fois qu'un Sentinel détecte qu'un nœud Redis ne répond pas, il annonce l'état du nœud aux autres Sentinels. Les Sentinels doivent atteindre un _quorum_ (le nombre minimum de Sentinels s'accordant sur le fait qu'un nœud est hors ligne) pour pouvoir démarrer un basculement.

Lorsque le **quorum** est atteint, la **majority** de tous les nœuds Sentinel connus doivent être disponibles et accessibles, afin qu'ils puissent élire le **leader** Sentinel qui prend toutes les décisions pour restaurer la disponibilité du service en :

- Promouvant un nouveau **Principal**
- Reconfigurant les autres **Replicas** et en les faisant pointer vers le nouveau **Principal**
- Annonçant le nouveau **Principal** à tous les autres pairs Sentinel
- Reconfigurant l'ancien **Principal** et en le rétrogradant en **Replica** lorsqu'il revient en ligne

Vous devez disposer d'au moins `3` serveurs Redis Sentinel, et chacun doit se trouver sur une machine indépendante (susceptibles de tomber en panne indépendamment), idéalement dans des zones géographiques différentes.

Vous pouvez les configurer sur les mêmes machines que celles où vous avez configuré les autres serveurs Redis, mais sachez que si un nœud entier tombe en panne, vous perdez à la fois un Sentinel et une instance Redis.

Le nombre de sentinels devrait idéalement toujours être un nombre **odd**, pour que l'algorithme de consensus soit efficace en cas de panne.

Dans une topologie à `3` nœuds, vous ne pouvez vous permettre que `1` nœud Sentinel en panne. Chaque fois que la **majority** des Sentinels tombe en panne, la protection contre le partitionnement réseau empêche les actions destructrices et un basculement **is not started**.

Voici quelques exemples :

- Avec `5` ou `6` sentinels, un maximum de `2` peuvent tomber en panne pour qu'un basculement commence.
- Avec `7` sentinels, un maximum de `3` nœuds peuvent tomber en panne.

L'élection du **Leader** peut parfois échouer lors du tour de vote lorsque le **consensus** n'est pas atteint. Dans ce cas, une nouvelle tentative est effectuée après le délai défini dans `sentinel['failover_timeout']` (en millisecondes).

> [!note]
> Nous verrons où `sentinel['failover_timeout']` est défini plus tard.

La variable `failover_timeout` a de nombreux cas d'utilisation différents. Selon la documentation officielle :

- Le temps nécessaire pour redémarrer un basculement après qu'un basculement précédent a déjà été tenté contre le même primaire par un Sentinel donné est deux fois le délai de basculement.

- Le temps nécessaire pour qu'un réplica se répliquant vers un mauvais primaire selon la configuration actuelle d'un Sentinel soit forcé de se répliquer vers le bon primaire est exactement le délai de basculement (compté depuis le moment où un Sentinel a détecté la mauvaise configuration).

- Le temps nécessaire pour annuler un basculement déjà en cours mais n'ayant produit aucun changement de configuration (REPLICAOF NO ONE pas encore acquitté par le réplica promu).

- Le temps maximum qu'un basculement en cours attend que tous les réplicas soient reconfigurés en tant que réplicas du nouveau primaire. Cependant, même après ce délai, les réplicas sont quand même reconfigurés par les Sentinels, mais pas avec la progression exact de parallel-syncs telle que spécifiée.

## Configuration de Redis {#configuring-redis}

C'est la section où nous installons et configurons les nouvelles instances Redis.

On suppose que vous avez installé GitLab et tous ses composants depuis zéro. Si vous avez déjà Redis installé et en cours d'exécution, lisez comment [passer d'une installation sur une seule machine](#switching-from-an-existing-single-machine-installation).

> [!note]
> Les nœuds Redis (primaire et réplica) ont besoin du même mot de passe défini dans `redis['password']`. À tout moment lors d'un basculement, les Sentinels peuvent reconfigurer un nœud et modifier son statut de primaire à réplica et vice versa.

### Prérequis {#requirements}

Les prérequis pour une configuration Redis sont les suivants :

1. Provisionnez le nombre minimum d'instances requis tel que spécifié dans la section [configuration recommandée](#recommended-setup).
1. Nous **Do not** d'installer Redis ou Redis Sentinel sur les mêmes machines que celles sur lesquelles votre application GitLab s'exécute, car cela affaiblit votre configuration HA. Vous pouvez cependant choisir d'installer Redis et Sentinel sur la même machine.
1. Tous les nœuds Redis doivent pouvoir communiquer entre eux et accepter les connexions entrantes sur les ports Redis (`6379`) et Sentinel (`26379`) (sauf si vous modifiez les valeurs par défaut).
1. Le serveur qui héberge l'application GitLab doit pouvoir accéder aux nœuds Redis.
1. Protégez les nœuds contre les accès provenant de réseaux externes ([Internet](https://gitlab.com/gitlab-org/gitlab-foss/uploads/c4cc8cd353604bd80315f9384035ff9e/The_Internet_IT_Crowd.png)), à l'aide d'un pare-feu.

### Passage d'une installation existante sur une seule machine {#switching-from-an-existing-single-machine-installation}

Si vous avez déjà une installation GitLab sur une seule machine en cours d'exécution, vous devez d'abord répliquer à partir de cette machine, avant de désactiver l'instance Redis qui s'y trouve.

Votre installation sur une seule machine est le **Principal** initial, et les `3` autres doivent être configurés en tant que **Replica** pointant vers cette machine.

Une fois la réplication à jour, vous devez arrêter les services sur l'installation mono-machine, afin de faire pivoter le **Principal** vers l'un des nouveaux nœuds.

Apportez les modifications requises dans la configuration et redémarrez les nouveaux nœuds.

Pour désactiver Redis dans l'installation unique, éditez `/etc/gitlab/gitlab.rb` :

```ruby
redis['enable'] = false
```

Si vous ne répliquez pas d'abord, vous risquez de perdre des données (tâches en arrière-plan non traitées).

### Étape 1. Configuration de l'instance Redis primaire {#step-1-configuring-the-primary-redis-instance}

1. Connectez-vous en SSH au serveur Redis **Principal**.
1. [Téléchargez et installez](https://about.gitlab.com/install/) le paquet Linux souhaité en utilisant **steps 1 and 2** de la page de téléchargements GitLab.
   - Assurez-vous de sélectionner le bon paquet Linux, avec la même version et le même type (éditions Community, Enterprise) que votre installation actuelle.
   - Ne complétez pas les autres étapes sur la page de téléchargement.

1. Éditez `/etc/gitlab/gitlab.rb` et ajoutez le contenu :

   ```ruby
   # Specify server role as 'redis_master_role'
   roles ['redis_master_role']

   # IP address pointing to a local IP that the other machines can reach to.
   # You can also set bind to '0.0.0.0' which listen in all interfaces.
   # If you really need to bind to an external accessible IP, make
   # sure you add extra firewall rules to prevent unauthorized access.
   redis['bind'] = '10.0.0.1'

   # Define a port so Redis can listen for TCP requests which allows other
   # machines to connect to it.
   redis['port'] = 6379

   # Set up password authentication for Redis (use the same password in all nodes).
   redis['password'] = 'redis-password-goes-here'
   ```

1. Seul le serveur d'application GitLab primaire doit gérer les migrations. Pour empêcher l'exécution des migrations de base de données lors d'une mise à niveau, ajoutez la configuration suivante à votre fichier `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['auto_migrate'] = false
   ```

1. [Reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

> [!note]
> Vous pouvez spécifier plusieurs rôles comme sentinel et Redis ainsi : `roles ['redis_sentinel_role', 'redis_master_role']`. En savoir plus sur les [rôles](https://docs.gitlab.com/omnibus/roles/).

### Étape 2. Configuration des instances Redis réplicas {#step-2-configuring-the-replica-redis-instances}

1. Connectez-vous en SSH au serveur Redis **replica**.
1. [Téléchargez et installez](https://about.gitlab.com/install/) le paquet Linux souhaité en utilisant **steps 1 and 2** de la page de téléchargements GitLab.
   - Assurez-vous de sélectionner le bon paquet Linux, avec la même version et le même type (éditions Community, Enterprise) que votre installation actuelle.
   - Ne complétez pas les autres étapes sur la page de téléchargement.

1. Éditez `/etc/gitlab/gitlab.rb` et ajoutez le contenu :

   ```ruby
   # Specify server role as 'redis_replica_role'
   roles ['redis_replica_role']

   # IP address pointing to a local IP that the other machines can reach to.
   # You can also set bind to '0.0.0.0' which listen in all interfaces.
   # If you really need to bind to an external accessible IP, make
   # sure you add extra firewall rules to prevent unauthorized access.
   redis['bind'] = '10.0.0.2'

   # Define a port so Redis can listen for TCP requests which allows other
   # machines to connect to it.
   redis['port'] = 6379

   # The same password for Redis authentication you set up for the primary node.
   redis['password'] = 'redis-password-goes-here'

   # The IP of the primary Redis node.
   redis['master_ip'] = '10.0.0.1'

   # Port of primary Redis server, uncomment to change to non default. Defaults
   # to `6379`.
   #redis['master_port'] = 6379
   ```

1. Pour empêcher l'exécution automatique de la reconfiguration lors d'une mise à niveau, exécutez :

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

1. Seul le serveur d'application GitLab primaire doit gérer les migrations. Pour empêcher l'exécution des migrations de base de données lors d'une mise à niveau, ajoutez la configuration suivante à votre fichier `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['auto_migrate'] = false
   ```

1. [Reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
1. Répétez les étapes pour tous les autres nœuds réplicas.

> [!note]
> Vous pouvez spécifier plusieurs rôles comme sentinel et Redis ainsi : `roles ['redis_sentinel_role', 'redis_master_role']`. En savoir plus sur les [rôles](https://docs.gitlab.com/omnibus/roles/).

Ces valeurs n'ont pas à être modifiées à nouveau dans `/etc/gitlab/gitlab.rb` après un basculement, car les nœuds sont gérés par les Sentinels, et même après un `gitlab-ctl reconfigure`, leur configuration est restaurée par les mêmes Sentinels.

### Étape 3. Configuration des instances Redis Sentinel {#step-3-configuring-the-redis-sentinel-instances}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/235938) de la prise en charge de l'authentification par mot de passe Sentinel dans GitLab 16.1.

{{< /history >}}

Maintenant que les serveurs Redis sont tous configurés, configurons les serveurs Sentinel.

Si vous n'êtes pas sûr que vos serveurs Redis fonctionnent et se répliquent correctement, lisez le [Dépannage de la réplication](troubleshooting.md#troubleshooting-redis-replication) et corrigez le problème avant de procéder à la configuration de Sentinel.

Vous devez disposer d'au moins `3` serveurs Redis Sentinel, et chacun doit se trouver sur une machine indépendante. Vous pouvez les configurer sur les mêmes machines que celles où vous avez configuré les autres serveurs Redis.

Avec GitLab Enterprise Edition, vous pouvez utiliser le paquet Linux pour configurer plusieurs machines avec le démon Sentinel.

1. Connectez-vous en SSH au serveur qui héberge Redis Sentinel.
1. **You can omit this step if the Sentinels is hosted in the same node as the other Redis instances**.

   [Téléchargez et installez](https://about.gitlab.com/install/) le paquet Linux Enterprise Edition en utilisant **steps 1 and 2** de la page de téléchargements GitLab.
   - Assurez-vous de sélectionner le bon paquet Linux, avec la même version que celle utilisée par l'application GitLab.
   - Ne complétez pas les autres étapes sur la page de téléchargement.

1. Éditez `/etc/gitlab/gitlab.rb` et ajoutez le contenu (si vous installez les Sentinels sur le même nœud que les autres instances Redis, certaines valeurs peuvent être dupliquées ci-dessous) :

   ```ruby
   roles ['redis_sentinel_role']

   # Must be the same in every sentinel node
   redis['master_name'] = 'gitlab-redis'

   # The same password for Redis authentication you set up for the primary node.
   redis['master_password'] = 'redis-password-goes-here'

   # The IP of the primary Redis node.
   redis['master_ip'] = '10.0.0.1'

   # Define a port so Redis can listen for TCP requests which allows other
   # machines to connect to it.
   redis['port'] = 6379

   # Port of primary Redis server, uncomment to change to non default. Defaults
   # to `6379`.
   #redis['master_port'] = 6379

   ## Configure Sentinel
   sentinel['bind'] = '10.0.0.1'

   ## Optional password for Sentinel authentication. Defaults to no password required.
   # sentinel['password'] = 'sentinel-password-goes here'

   # Port that Sentinel listens on, uncomment to change to non default. Defaults
   # to `26379`.
   # sentinel['port'] = 26379

   ## Quorum must reflect the amount of voting sentinels it take to start a failover.
   ## Value must NOT be greater than the amount of sentinels.
   ##
   ## The quorum can be used to tune Sentinel in two ways:
   ## 1. If a the quorum is set to a value smaller than the majority of Sentinels
   ##    we deploy, we are basically making Sentinel more sensible to primary failures,
   ##    triggering a failover as soon as even just a minority of Sentinels is no longer
   ##    able to talk with the primary.
   ## 1. If a quorum is set to a value greater than the majority of Sentinels, we are
   ##    making Sentinel able to failover only when there are a very large number (larger
   ##    than majority) of well connected Sentinels which agree about the primary being down.s
   sentinel['quorum'] = 2

   ## Consider unresponsive server down after x amount of ms.
   # sentinel['down_after_milliseconds'] = 10000

   ## Specifies the failover timeout in milliseconds. It is used in many ways:
   ##
   ## - The time needed to re-start a failover after a previous failover was
   ##   already tried against the same primary by a given Sentinel, is two
   ##   times the failover timeout.
   ##
   ## - The time needed for a replica replicating to a wrong primary according
   ##   to a Sentinel current configuration, to be forced to replicate
   ##   with the right primary, is exactly the failover timeout (counting since
   ##   the moment a Sentinel detected the misconfiguration).
   ##
   ## - The time needed to cancel a failover that is already in progress but
   ##   did not produced any configuration change (REPLICAOF NO ONE yet not
   ##   acknowledged by the promoted replica).
   ##
   ## - The maximum time a failover in progress waits for all the replica to be
   ##   reconfigured as replicas of the new primary. However even after this time
   ##   the replicas are reconfigured by the Sentinels anyway, but not with
   ##   the exact parallel-syncs progression as specified.
   # sentinel['failover_timeout'] = 60000
   ```

1. Pour empêcher l'exécution des migrations de base de données lors d'une mise à niveau, exécutez :

   ```shell
   sudo touch /etc/gitlab/skip-auto-reconfigure
   ```

   Seul le serveur d'application GitLab primaire doit gérer les migrations.

1. [Reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
1. Répétez les étapes pour tous les autres nœuds Sentinel.

### Étape 4. Configuration de l'application GitLab {#step-4-configuring-the-gitlab-application}

La dernière partie consiste à informer le serveur d'application GitLab principal des serveurs Redis Sentinels et des identifiants d'authentification.

Vous pouvez activer ou désactiver la prise en charge de Sentinel à tout moment dans les installations nouvelles ou existantes. Du point de vue de l'application GitLab, tout ce dont elle a besoin sont les identifiants corrects pour les nœuds Sentinel.

Bien qu'elle ne nécessite pas une liste de tous les nœuds Sentinel, en cas de panne, elle doit accéder à au moins l'un de ceux listés.

> [!note]
> Les étapes suivantes doivent être effectuées sur le serveur d'application GitLab qui, idéalement, ne devrait pas avoir Redis ou des Sentinels pour une configuration HA.

1. Connectez-vous en SSH au serveur où l'application GitLab est installée.
1. Éditez `/etc/gitlab/gitlab.rb` et ajoutez/modifiez les lignes suivantes :

   ```ruby
   ## Must be the same in every sentinel node
   redis['master_name'] = 'gitlab-redis'

   ## The same password for Redis authentication you set up for the primary node.
   redis['master_password'] = 'redis-password-goes-here'

   ## A list of sentinels with `host` and `port`
   gitlab_rails['redis_sentinels'] = [
     {'host' => '10.0.0.1', 'port' => 26379},
     {'host' => '10.0.0.2', 'port' => 26379},
     {'host' => '10.0.0.3', 'port' => 26379}
   ]
   # gitlab_rails['redis_sentinels_password'] = 'sentinel-password-goes-here' # uncomment and set it to the same value as in sentinel['password']
   ```

1. [Reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

### Étape 5. Activer la surveillance {#step-5-enable-monitoring}

Si vous activez la surveillance, elle doit être activée sur **l'ensemble** des serveurs Redis.

1. Assurez-vous de collecter [`CONSUL_SERVER_NODES`](../postgresql/replication_and_failover.md#consul-information), qui sont les adresses IP ou les enregistrements DNS des nœuds du serveur Consul, pour l'étape suivante. Notez qu'ils sont présentés sous la forme `Y.Y.Y.Y consul1.gitlab.example.com Z.Z.Z.Z`
1. Créez/éditez `/etc/gitlab/gitlab.rb` et ajoutez la configuration suivante :

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

   # Set the network addresses that the exporters listen on
   node_exporter['listen_address'] = '0.0.0.0:9100'
   redis_exporter['listen_address'] = '0.0.0.0:9121'
   ```

1. Exécutez `sudo gitlab-ctl reconfigure` pour compiler la configuration.

## Exemple de configuration minimale avec 1 primaire, 2 réplicas et 3 Sentinels {#example-of-a-minimal-configuration-with-1-primary-2-replicas-and-3-sentinels}

Dans cet exemple, nous considérons que tous les serveurs disposent d'une interface réseau interne avec des adresses IP dans la plage `10.0.0.x`, et qu'ils peuvent se connecter les uns aux autres en utilisant ces adresses IP.

Dans un usage réel, vous configureriez également des règles de pare-feu pour empêcher les accès non autorisés depuis d'autres machines et bloquer le trafic venant de l'extérieur (Internet).

Nous utilisons les mêmes `3` nœuds avec la topologie **Redis** + **Sentinel** décrite dans la documentation [Présentation de la configuration Redis](#redis-setup-overview) et [Présentation de la configuration Sentinel](#sentinel-setup-overview).

Voici une liste et une description de chaque **machine** et de l'**IP** assignée :

- `10.0.0.1` :  Redis principal + Sentinel 1
- `10.0.0.2` :  Redis Réplica 1 + Sentinel 2
- `10.0.0.3` :  Redis Réplica 2 + Sentinel 3
- `10.0.0.4` :  Application GitLab

Après la configuration initiale, si un basculement est déclenché par les nœuds Sentinel, les nœuds Redis sont reconfigurés et le **Principal** change de façon permanente (y compris dans `redis.conf`) d'un nœud à l'autre, jusqu'à ce qu'un nouveau basculement soit déclenché.

La même chose se produit avec `sentinel.conf` qui est écrasé après l'exécution initiale, après que tout nouveau nœud sentinel commence à surveiller le **Principal**, ou qu'un basculement promeut un autre nœud **Principal**.

### Exemple de configuration pour le Redis primaire et Sentinel 1 {#example-configuration-for-redis-primary-and-sentinel-1}

Dans `/etc/gitlab/gitlab.rb` :

```ruby
roles ['redis_sentinel_role', 'redis_master_role']
redis['bind'] = '10.0.0.1'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'
redis['master_name'] = 'gitlab-redis' # must be the same in every sentinel node
redis['master_password'] = 'redis-password-goes-here' # the same value defined in redis['password'] in the primary instance
redis['master_ip'] = '10.0.0.1' # ip of the initial primary redis instance
#redis['master_port'] = 6379 # port of the initial primary redis instance, uncomment to change to non default
sentinel['bind'] = '10.0.0.1'
# sentinel['password'] = 'sentinel-password-goes-here' # must be the same in every sentinel node, uncomment to set a password
# sentinel['port'] = 26379 # uncomment to change default port
sentinel['quorum'] = 2
# sentinel['down_after_milliseconds'] = 10000
# sentinel['failover_timeout'] = 60000
```

[Reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

### Exemple de configuration pour le Redis réplica 1 et Sentinel 2 {#example-configuration-for-redis-replica-1-and-sentinel-2}

Dans `/etc/gitlab/gitlab.rb` :

```ruby
roles ['redis_sentinel_role', 'redis_replica_role']
redis['bind'] = '10.0.0.2'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'
redis['master_password'] = 'redis-password-goes-here'
redis['master_ip'] = '10.0.0.1' # IP of primary Redis server
#redis['master_port'] = 6379 # Port of primary Redis server, uncomment to change to non default
redis['master_name'] = 'gitlab-redis' # must be the same in every sentinel node
sentinel['bind'] = '10.0.0.2'
# sentinel['password'] = 'sentinel-password-goes-here' # must be the same in every sentinel node, uncomment to set a password
# sentinel['port'] = 26379 # uncomment to change default port
sentinel['quorum'] = 2
# sentinel['down_after_milliseconds'] = 10000
# sentinel['failover_timeout'] = 60000
```

[Reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

### Exemple de configuration pour le Redis réplica 2 et Sentinel 3 {#example-configuration-for-redis-replica-2-and-sentinel-3}

Dans `/etc/gitlab/gitlab.rb` :

```ruby
roles ['redis_sentinel_role', 'redis_replica_role']
redis['bind'] = '10.0.0.3'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'
redis['master_password'] = 'redis-password-goes-here'
redis['master_ip'] = '10.0.0.1' # IP of primary Redis server
#redis['master_port'] = 6379 # Port of primary Redis server, uncomment to change to non default
redis['master_name'] = 'gitlab-redis' # must be the same in every sentinel node
sentinel['bind'] = '10.0.0.3'
# sentinel['password'] = 'sentinel-password-goes-here' # must be the same in every sentinel node, uncomment to set a password
# sentinel['port'] = 26379 # uncomment to change default port
sentinel['quorum'] = 2
# sentinel['down_after_milliseconds'] = 10000
# sentinel['failover_timeout'] = 60000
```

[Reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

### Exemple de configuration pour l'application GitLab {#example-configuration-for-the-gitlab-application}

Dans `/etc/gitlab/gitlab.rb` :

```ruby
redis['master_name'] = 'gitlab-redis'
redis['master_password'] = 'redis-password-goes-here'
gitlab_rails['redis_sentinels'] = [
  {'host' => '10.0.0.1', 'port' => 26379},
  {'host' => '10.0.0.2', 'port' => 26379},
  {'host' => '10.0.0.3', 'port' => 26379}
]
# gitlab_rails['redis_sentinels_password'] = 'sentinel-password-goes-here' # uncomment and set it to the same value as in sentinel['password']
```

[Reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

## Configuration avancée {#advanced-configuration}

Cette section couvre les options de configuration qui vont au-delà des configurations recommandées et minimales.

### Exécution de plusieurs clusters Redis {#running-multiple-redis-clusters}

Le paquet Linux prend en charge l'exécution d'instances Redis et Sentinel séparées pour différentes classes de persistance.

| Classe              | Objectif |
|--------------------|---------|
| `cache`            | Stocker les données en cache. |
| `queues`           | Stocker les tâches en arrière-plan Sidekiq. |
| `shared_state`     | Stocker les données liées aux sessions et autres données persistantes. |
| `actioncable`      | Backend de file d'attente Pub/Sub pour ActionCable. |
| `trace_chunks`     | Stocker les données de [fragments de trace CI](../cicd/job_logs.md#incremental-logging). |
| `rate_limiting`    | Stocker l'état de [limite de débit](../settings/user_and_ip_rate_limits.md). |
| `sessions`         | Stocker les sessions. |
| `repository_cache` | Stocker les données de cache spécifiques aux dépôts. |

Pour faire fonctionner cela avec Sentinel :

1. [Configurez les différentes instances Redis/Sentinels](#configuring-redis) selon vos besoins.
1. Pour chaque instance d'application Rails, éditez son fichier `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['redis_cache_instance'] = REDIS_CACHE_URL
   gitlab_rails['redis_queues_instance'] = REDIS_QUEUES_URL
   gitlab_rails['redis_shared_state_instance'] = REDIS_SHARED_STATE_URL
   gitlab_rails['redis_actioncable_instance'] = REDIS_ACTIONCABLE_URL
   gitlab_rails['redis_trace_chunks_instance'] = REDIS_TRACE_CHUNKS_URL
   gitlab_rails['redis_rate_limiting_instance'] = REDIS_RATE_LIMITING_URL
   gitlab_rails['redis_sessions_instance'] = REDIS_SESSIONS_URL
   gitlab_rails['redis_repository_cache_instance'] = REDIS_REPOSITORY_CACHE_URL

   # Configure the Sentinels
   gitlab_rails['redis_cache_sentinels'] = [
     { host: REDIS_CACHE_SENTINEL_HOST, port: 26379 },
     { host: REDIS_CACHE_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_queues_sentinels'] = [
     { host: REDIS_QUEUES_SENTINEL_HOST, port: 26379 },
     { host: REDIS_QUEUES_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_shared_state_sentinels'] = [
     { host: SHARED_STATE_SENTINEL_HOST, port: 26379 },
     { host: SHARED_STATE_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_actioncable_sentinels'] = [
     { host: ACTIONCABLE_SENTINEL_HOST, port: 26379 },
     { host: ACTIONCABLE_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_trace_chunks_sentinels'] = [
     { host: TRACE_CHUNKS_SENTINEL_HOST, port: 26379 },
     { host: TRACE_CHUNKS_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_rate_limiting_sentinels'] = [
     { host: RATE_LIMITING_SENTINEL_HOST, port: 26379 },
     { host: RATE_LIMITING_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_sessions_sentinels'] = [
     { host: SESSIONS_SENTINEL_HOST, port: 26379 },
     { host: SESSIONS_SENTINEL_HOST2, port: 26379 }
   ]
   gitlab_rails['redis_repository_cache_sentinels'] = [
     { host: REPOSITORY_CACHE_SENTINEL_HOST, port: 26379 },
     { host: REPOSITORY_CACHE_SENTINEL_HOST2, port: 26379 }
   ]

   # gitlab_rails['redis_cache_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_queues_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_shared_state_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_actioncable_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_trace_chunks_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_rate_limiting_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_sessions_sentinels_password'] = 'sentinel-password-goes-here'
   # gitlab_rails['redis_repository_cache_sentinels_password'] = 'sentinel-password-goes-here'
   ```

   - Les URL Redis doivent être au format : `redis://:PASSWORD@SENTINEL_PRIMARY_NAME`, où :
     - `PASSWORD` est le mot de passe en clair pour l'instance Redis.
     - `SENTINEL_PRIMARY_NAME` est le nom primaire Sentinel défini avec `redis['master_name']`, par exemple `gitlab-redis-cache`.

1. Enregistrez le fichier et reconfigurez GitLab pour que la modification prenne effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

> [!note]
> Pour chaque classe de persistance, GitLab utilise par défaut la configuration spécifiée dans `gitlab_rails['redis_sentinels']` sauf si elle est remplacée par les paramètres décrits précédemment.

### Contrôle des services en cours d'exécution {#control-running-services}

Dans l'exemple précédent, nous avons utilisé `redis_sentinel_role` et `redis_master_role` qui simplifient la quantité de modifications de configuration.

Si vous souhaitez plus de contrôle, voici ce que chacun configure automatiquement pour vous lorsqu'il est activé :

```ruby
## Redis Sentinel Role
redis_sentinel_role['enable'] = true

# When Sentinel Role is enabled, the following services are also enabled
sentinel['enable'] = true

# The following services are disabled
redis['enable'] = false
bootstrap['enable'] = false
nginx['enable'] = false
postgresql['enable'] = false
gitlab_rails['enable'] = false
mailroom['enable'] = false

-------

## Redis primary/replica Role
redis_master_role['enable'] = true # enable only one of them
redis_replica_role['enable'] = true # enable only one of them

# When Redis primary or Replica role are enabled, the following services are
# enabled/disabled. If Redis and Sentinel roles are combined, both
# services are enabled.

# The following services are disabled
sentinel['enable'] = false
bootstrap['enable'] = false
nginx['enable'] = false
postgresql['enable'] = false
gitlab_rails['enable'] = false
mailroom['enable'] = false

# For Redis Replica role, also change this setting from default 'true' to 'false':
redis['master'] = false
```

Vous pouvez trouver les attributs pertinents définis dans [`gitlab_rails.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/blob/master/files/gitlab-cookbooks/gitlab/libraries/gitlab_rails.rb).

### Contrôle du comportement au démarrage {#control-startup-behavior}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/6646) dans GitLab 15.10.

{{< /history >}}

Pour empêcher le service Redis intégré de démarrer au démarrage ou de redémarrer après avoir modifié sa configuration :

1. Éditez `/etc/gitlab/gitlab.rb` :

   ```ruby
   redis['start_down'] = true
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Si vous avez besoin de tester un nouveau nœud réplica, vous pouvez définir `start_down` sur `true` et démarrer le nœud manuellement. Une fois que le nouveau nœud réplica est confirmé comme fonctionnel dans le cluster Redis, définissez `start_down` sur `false` et reconfigurez GitLab pour vous assurer que le nœud démarre et redémarre comme prévu lors du fonctionnement.

### Contrôle de la configuration des réplicas {#control-replica-configuration}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/6646) dans GitLab 15.10.

{{< /history >}}

Pour empêcher la ligne `replicaof` d'apparaître dans le fichier de configuration Redis :

1. Éditez `/etc/gitlab/gitlab.rb` :

   ```ruby
   redis['set_replicaof'] = false
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Ce paramètre peut être utilisé pour empêcher la réplication d'un nœud Redis indépendamment des autres paramètres Redis.

## Utiliser Valkey à la place de Redis {#use-valkey-instead-of-redis}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9113) dans GitLab 18.9 en tant que [bêta](../../policy/development_stages_support.md#beta).
- [Disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/585839) dans GitLab 19.0.

{{< /history >}}

Vous pouvez utiliser [Valkey](https://valkey.io/) comme remplacement direct de Redis dans les configurations de réplication et de basculement. Valkey utilise les mêmes rôles et options de configuration que Redis.

### Configurer les nœuds primaire et réplicas Valkey {#configure-valkey-primary-and-replica-nodes}

Sur chaque nœud (primaire et réplicas), ajoutez ce qui suit à `/etc/gitlab/gitlab.rb` pour passer de Redis à Valkey :

```ruby
# Use the same Redis roles
roles ['redis_master_role']  # or 'redis_replica_role' for replicas

# Switch to Valkey
redis['backend'] = 'valkey'

# Use the same configuration options as for Redis
redis['bind'] = '10.0.0.1'
redis['port'] = 6379
redis['password'] = 'redis-password-goes-here'

gitlab_rails['auto_migrate'] = false
```

### Configurer Sentinel pour Valkey {#configure-sentinel-for-valkey}

Sur chaque nœud Sentinel, ajoutez ce qui suit à `/etc/gitlab/gitlab.rb` :

```ruby
roles ['redis_sentinel_role']

# Switch redis backend to Valkey
# Then Sentinel will use the same backend
redis['backend'] = 'valkey'

# Sentinel configuration (same as for Redis)
redis['master_name'] = 'gitlab-redis'
redis['master_password'] = 'redis-password-goes-here'
redis['master_ip'] = '10.0.0.1'
redis['port'] = 6379

sentinel['bind'] = '10.0.0.1'
sentinel['quorum'] = 2
```

Toutes les autres options de configuration Sentinel restent identiques à celles documentées dans [Configuration des instances Redis Sentinel](#step-3-configuring-the-redis-sentinel-instances).

### Problèmes connus {#known-issues}

- En raison du [problème 589642](https://gitlab.com/gitlab-org/gitlab/-/issues/589642) connu, la zone d'administration signale incorrectement la version de Valkey. Ce problème n'affecte pas la version de Valkey installée ni son fonctionnement.

## Sécuriser Redis et Sentinel avec TLS {#secure-redis-and-sentinel-with-tls}

Pour des informations complètes sur la sécurisation des communications Redis et Sentinel à l'aide de TLS, consultez [Sécurisation de Redis et Sentinel avec TLS](tls.md).

## Dépannage {#troubleshooting}

Consultez le [guide de dépannage Redis](troubleshooting.md).

## Lecture complémentaire {#further-reading}

En savoir plus :

1. [Architectures de référence](../reference_architectures/_index.md)
1. [Configurer la base de données](../postgresql/replication_and_failover.md)
1. [Configurer NFS](../nfs.md)
1. [Configurer les équilibreurs de charge](../load_balancer.md)
