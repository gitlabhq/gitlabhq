---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer Geo pour plusieurs nœuds
description: "Configurez Geo dans un environnement multi-nœuds, couvrant la configuration des sites principal et secondaire, la réplication de base de données, la configuration de la base de données de suivi et l'intégration du répartiteur de charge."
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Ce document décrit une architecture de référence minimale pour l'exécution de Geo dans une configuration multi-nœuds. Si votre configuration multi-nœuds diffère de celle décrite, il est possible d'adapter ces instructions à vos besoins.

Ce guide s'applique aux installations avec plusieurs nœuds d'application (Sidekiq ou GitLab Rails). Pour les installations à nœud unique avec PostgreSQL externe, suivez [Configurer Geo pour deux sites à nœud unique (avec des services PostgreSQL externes)](../setup/two_single_node_external_services.md), et adaptez votre configuration si vous utilisez d'autres services externes.

## Présentation de l'architecture {#architecture-overview}

![Architecture pour l'exécution de Geo dans une configuration multi-nœuds avec des services backend principal et secondaire](img/geo-ha-diagram_v11_11.png)

**[source du diagramme - membres de l'équipe GitLab uniquement](https://docs.google.com/drawings/d/1z0VlizKiLNXVVVaERFwgsIOuEgjcUqDTWPdQYsE7Z4c/edit)**

Le diagramme de topologie suppose que les sites Geo **principal** et **secondaire** sont situés dans deux emplacements distincts, sur leur propre réseau virtuel avec des adresses IP privées. Le réseau est configuré de telle sorte que toutes les machines dans un emplacement géographique peuvent communiquer entre elles en utilisant leurs adresses IP privées. Les adresses IP indiquées sont des exemples et peuvent être différentes selon la topologie réseau de votre déploiement.

La seule façon externe d'accéder aux deux sites Geo est via HTTPS sur `gitlab.us.example.com` et `gitlab.eu.example.com` dans l'exemple précédent.

> [!note]
> Les sites Geo **principal** et **secondaire** doivent pouvoir communiquer entre eux via HTTPS.

## Redis et PostgreSQL pour plusieurs nœuds {#redis-and-postgresql-for-multiple-nodes}

En raison de la complexité supplémentaire liée à la configuration de cette configuration pour PostgreSQL et Redis, elle n'est pas couverte par cette documentation Geo multi-nœuds.

Pour plus d'informations sur la configuration d'un cluster PostgreSQL multi-nœuds et d'un cluster Redis à l'aide du package Linux, voir :

- [Réplication de base de données Geo multi-nœuds](../setup/database.md#multi-node-database-replication)
- [Documentation Redis multi-nœuds](../../redis/replication_and_failover.md)

> [!note]
> Il est possible d'utiliser des services hébergés dans le cloud pour PostgreSQL et Redis, mais cela dépasse la portée de ce document.

## Prérequis : Deux sites GitLab multi-nœuds fonctionnant de manière indépendante {#prerequisites-two-independently-working-gitlab-multi-node-sites}

Un site GitLab sert de site Geo **principal**. Utilisez la [documentation sur les architectures de référence GitLab](../../reference_architectures/_index.md) pour effectuer cette configuration. Vous pouvez utiliser différentes tailles d'architecture de référence pour chaque site Geo. Si vous disposez déjà d'une instance GitLab fonctionnelle en cours d'utilisation, elle peut être utilisée comme site **principal**.

Le deuxième site GitLab sert de site Geo **secondaire**. Là encore, utilisez la [documentation sur les architectures de référence GitLab](../../reference_architectures/_index.md) pour effectuer cette configuration. Il est conseillé de vous connecter et de le tester. Toutefois, sachez que ses données sont effacées dans le cadre du processus de réplication depuis le site **principal**.

## Configurer un site GitLab en tant que site Geo **principal** {#configure-a-gitlab-site-to-be-the-geo-primary-site}

Les étapes suivantes permettent à un site GitLab de servir de site Geo **principal**.

### Étape 1 :  Configurer les nœuds frontend **principal** {#step-1-configure-the-primary-frontend-nodes}

> [!note]
> N'utilisez pas [`geo_primary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles), car il est destiné à un site à nœud unique.

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez ce qui suit :

   ```ruby
   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'

   ##
   ## Disable automatic migrations
   ##
   gitlab_rails['auto_migrate'] = false
   ```

Après avoir effectué ces modifications, [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

### Étape 2 :  Définir le site comme site **principal** {#step-2-define-the-site-as-the-primary-site}

1. Exécutez la commande suivante sur l'un des nœuds frontend :

   ```shell
   sudo gitlab-ctl set-geo-primary-node
   ```

> [!note]
> PostgreSQL et Redis doivent déjà avoir été désactivés sur les nœuds d'application lors de la configuration typique de GitLab multi-nœuds. Les connexions des nœuds d'application aux services sur les nœuds backend doivent également avoir été configurées. Consultez la documentation sur la configuration multi-nœuds pour [PostgreSQL](../../postgresql/replication_and_failover.md#configuring-the-application-nodes) et [Redis](../../redis/replication_and_failover.md#example-configuration-for-the-gitlab-application).

## Configurer l'autre site GitLab en tant que site Geo **secondaire** {#configure-the-other-gitlab-site-to-be-a-geo-secondary-site}

Un site **secondaire** est similaire à tout autre site GitLab multi-nœuds, avec trois différences majeures :

- La base de données PostgreSQL principale est un réplica en lecture seule de la base de données PostgreSQL du site Geo **principal**.
- Il existe une base de données PostgreSQL supplémentaire pour chaque site Geo **secondaire**, appelée « base de données de suivi Geo », qui suit l'état de réplication et de vérification de diverses ressources.
- Il existe un service GitLab supplémentaire [`geo-logcursor`](../_index.md#geo-log-cursor)

Par conséquent, nous configurons les composants multi-nœuds un par un et incluons les déviations par rapport à la configuration multi-nœuds standard. Cependant, nous recommandons vivement de configurer d'abord un tout nouveau site GitLab, comme s'il ne faisait pas partie d'une configuration Geo. Cela permet de vérifier qu'il s'agit d'un site GitLab fonctionnel. Et ce n'est qu'ensuite qu'il doit être modifié pour être utilisé comme site Geo **secondaire**. Cela aide à distinguer les problèmes de configuration Geo des problèmes de configuration multi-nœuds sans rapport.

### Étape 1 :  Configurer les services Redis et Gitaly sur le site Geo **secondaire** {#step-1-configure-the-redis-and-gitaly-services-on-the-geo-secondary-site}

Configurez les services suivants, en utilisant à nouveau la documentation multi-nœuds non-Geo :

- [Configuration de Redis pour GitLab](../../redis/replication_and_failover.md#example-configuration-for-the-gitlab-application) pour plusieurs nœuds.
- [Gitaly](../../gitaly/_index.md), qui stocke les données synchronisées depuis le site Geo **principal**.

> [!note]
> [NFS](../../nfs.md) peut être utilisé à la place de Gitaly, mais n'est pas recommandé.

### Étape 2 :  Configurer la base de données de suivi Geo sur le site Geo **secondaire** {#step-2-configure-the-geo-tracking-database-on-the-geo-secondary-site}

La base de données de suivi Geo ne peut pas être exécutée dans un cluster PostgreSQL multi-nœuds, voir [Configuration du cluster Patroni pour la base de données PostgreSQL de suivi](../setup/database.md#configuring-patroni-cluster-for-the-tracking-postgresql-database).

Vous pouvez exécuter la base de données de suivi Geo sur un seul nœud comme suit :

1. Générez un hash MD5 du mot de passe souhaité pour l'utilisateur de base de données que l'application GitLab utilise pour accéder à la base de données de suivi :

   Le nom d'utilisateur (`gitlab_geo` par défaut) est incorporé dans le hash.

   ```shell
   gitlab-ctl pg-password-md5 gitlab_geo
   # Enter password: <your_tracking_db_password_here>
   # Confirm password: <your_tracking_db_password_here>
   # fca0b89a972d69f00eb3ec98a5838484
   ```

   Utilisez ce hash pour renseigner `<tracking_database_password_md5_hash>` à l'étape suivante.

1. Sur la machine sur laquelle la base de données de suivi Geo est destinée à s'exécuter, ajoutez ce qui suit à `/etc/gitlab/gitlab.rb` :

   ```ruby
   ##
   ## Enable the Geo secondary tracking database
   ##
   geo_postgresql['enable'] = true
   geo_postgresql['listen_address'] = '<ip_address_of_this_host>'
   geo_postgresql['sql_user_password'] = '<tracking_database_password_md5_hash>'

   ##
   ## Configure PostgreSQL connection to the replica database
   ##
   geo_postgresql['md5_auth_cidr_addresses'] = ['<replica_database_ip>/32']
   gitlab_rails['db_host'] = '<replica_database_ip>'

   # Prevent reconfigure from attempting to run migrations on the replica database
   gitlab_rails['auto_migrate'] = false
   ```

1. [Désactivez les mises à niveau automatiques de PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades) pour éviter tout temps d'arrêt involontaire lors de la mise à niveau de GitLab. Tenez compte des [mises en garde connues lors de la mise à niveau de PostgreSQL avec Geo](https://docs.gitlab.com/omnibus/settings/database/#caveats-when-upgrading-postgresql-with-geo). En particulier pour les environnements plus importants, les mises à niveau de PostgreSQL doivent être planifiées et exécutées de manière réfléchie. En conséquence et à l'avenir, assurez-vous que les mises à niveau de PostgreSQL font partie des activités de maintenance régulières.

Après avoir effectué ces modifications, [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Si vous utilisez une instance PostgreSQL externe, référez-vous également à [Geo avec des instances PostgreSQL externes](../setup/external_database.md).

### Étape 3 :  Configurer la réplication en continu PostgreSQL {#step-3-configure-postgresql-streaming-replication}

Suivez les [instructions de réplication de base de données Geo](../setup/database.md).

Si vous utilisez une instance PostgreSQL externe, référez-vous également à [Geo avec des instances PostgreSQL externes](../setup/external_database.md).

Après avoir activé la réplication en continu, `gitlab-rake db:migrate:status:geo` échoue jusqu'à ce que la [configuration du site secondaire soit terminée](#step-7-copy-secrets-and-add-the-secondary-site-in-the-application), notamment [Configuration Geo - Étape 3. Ajouter le site secondaire](configuration.md#step-3-add-the-secondary-site).

### Étape 4 :  Configurer les nœuds d'application frontend sur le site Geo **secondaire** {#step-4-configure-the-frontend-application-nodes-on-the-geo-secondary-site}

> [!note]
> N'utilisez pas [`geo_secondary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles), car il est destiné à un site à nœud unique.

Dans le [schéma d'architecture](#architecture-overview) minimal, deux machines exécutent les services d'application GitLab. Ces services sont activés sélectivement dans la configuration.

Configurez les nœuds d'application GitLab Rails en suivant les étapes pertinentes décrites dans les [architectures de référence](../../reference_architectures/_index.md), puis effectuez les modifications suivantes :

1. Modifiez `/etc/gitlab/gitlab.rb` sur chaque nœud d'application du site Geo **secondaire**, et ajoutez ce qui suit :

   ```ruby
   ##
   ## Enable GitLab application services. The application_role enables many services.
   ## Alternatively, you can choose to enable or disable specific services on
   ## different nodes to aid in horizontal scaling and separation of concerns.
   ##
   roles ['application_role']

   ## `application_role` already enables this. You only need this line if
   ## you selectively enable individual services that depend on Rails, like
   ## `puma`, `sidekiq`, `geo-logcursor`, and so on.
   gitlab_rails['enable'] = true

   ##
   ## Enable Geo Log Cursor service
   ##
   geo_logcursor['enable'] = true

   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'

   ##
   ## Disable automatic migrations
   ##
   gitlab_rails['auto_migrate'] = false

   ##
   ## Configure the connection to the tracking database
   ##
   geo_secondary['enable'] = true
   geo_secondary['db_host'] = '<geo_tracking_db_host>'
   geo_secondary['db_password'] = '<geo_tracking_db_password>'

   ##
   ## Configure connection to the streaming replica database, if you haven't
   ## already
   ##
   gitlab_rails['db_host'] = '<replica_database_host>'
   gitlab_rails['db_password'] = '<replica_database_password>'

   ##
   ## Configure connection to Redis, if you haven't already
   ##
   gitlab_rails['redis_host'] = '<redis_host>'
   gitlab_rails['redis_password'] = '<redis_password>'

   ##
   ## If you are using custom users not managed by Omnibus, you need to specify
   ## UIDs and GIDs like below, and ensure they match between nodes in a
   ## cluster to avoid permissions issues
   ##
   user['uid'] = 9000
   user['gid'] = 9000
   web_server['uid'] = 9001
   web_server['gid'] = 9001
   registry['uid'] = 9002
   registry['gid'] = 9002
   ```

> [!warning]
> Si vous avez configuré le cluster PostgreSQL à l'aide du package Linux et avez défini `postgresql['sql_user_password'] = 'md5 digest of secret'`, gardez à l'esprit que `gitlab_rails['db_password']` et `geo_secondary['db_password']` contiennent les mots de passe en clair. Ces configurations sont utilisées pour permettre aux nœuds Rails de se connecter aux bases de données.

Assurez-vous que l'adresse IP du nœud actuel est répertoriée dans le paramètre `postgresql['md5_auth_cidr_addresses']` de la base de données réplica en lecture afin de permettre à Rails sur ce nœud de se connecter à PostgreSQL.

Après avoir effectué ces modifications, [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Dans la topologie de [présentation de l'architecture](#architecture-overview), les services GitLab suivants sont activés sur les nœuds « frontend » :

- `geo-logcursor`
- `gitlab-pages`
- `gitlab-workhorse`
- `logrotate`
- `nginx`
- `registry`
- `remote-syslog`
- `sidekiq`
- `puma`

Vérifiez l'existence de ces services en exécutant `sudo gitlab-ctl status` sur les nœuds d'application frontend.

### Étape 5 :  Configurer le répartiteur de charge pour le site Geo **secondaire** {#step-5-set-up-the-loadbalancer-for-the-geo-secondary-site}

Le [schéma d'architecture](#architecture-overview) minimal montre un répartiteur de charge à chaque emplacement géographique pour acheminer le trafic vers les nœuds d'application.

Voir [Répartiteur de charge pour GitLab avec plusieurs nœuds](../../load_balancer.md) pour plus d'informations.

### Étape 6 :  Configurer les nœuds d'application backend sur le site Geo **secondaire** {#step-6-configure-the-backend-application-nodes-on-the-geo-secondary-site}

Le [schéma d'architecture](#architecture-overview) minimal montre tous les services d'application s'exécutant ensemble sur les mêmes machines. Cependant, pour plusieurs nœuds, nous [recommandons vivement d'exécuter tous les services séparément](../../reference_architectures/_index.md).

Par exemple, un nœud Sidekiq pourrait être configuré de manière similaire aux nœuds d'application frontend documentés précédemment, avec quelques modifications pour n'exécuter que le service `sidekiq` :

1. Modifiez `/etc/gitlab/gitlab.rb` sur chaque nœud Sidekiq du site Geo **secondaire**, et ajoutez ce qui suit :

   ```ruby
   ##
   ## Enable the Sidekiq service
   ##
   sidekiq['enable'] = true
   gitlab_rails['enable'] = true

   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'

   ##
   ## Disable automatic migrations
   ##
   gitlab_rails['auto_migrate'] = false

   ##
   ## Configure the connection to the tracking database
   ##
   geo_secondary['enable'] = true
   geo_secondary['db_host'] = '<geo_tracking_db_host>'
   geo_secondary['db_password'] = '<geo_tracking_db_password>'

   ##
   ## Configure connection to the streaming replica database, if you haven't
   ## already
   ##
   gitlab_rails['db_host'] = '<replica_database_host>'
   gitlab_rails['db_password'] = '<replica_database_password>'

   ##
   ## Configure connection to Redis, if you haven't already
   ##
   gitlab_rails['redis_host'] = '<redis_host>'
   gitlab_rails['redis_password'] = '<redis_password>'

   ##
   ## If you are using custom users not managed by Omnibus, you need to specify
   ## UIDs and GIDs like below, and ensure they match between nodes in a
   ## cluster to avoid permissions issues
   ##
   user['uid'] = 9000
   user['gid'] = 9000
   web_server['uid'] = 9001
   web_server['gid'] = 9001
   registry['uid'] = 9002
   registry['gid'] = 9002
   ```

   Vous pouvez de même configurer un nœud pour n'exécuter que le service `geo-logcursor` avec `geo_logcursor['enable'] = true` et désactiver Sidekiq avec `sidekiq['enable'] = false`.

   Ces nœuds n'ont pas besoin d'être rattachés au répartiteur de charge.

### Étape 7 :  Copier les secrets et ajouter le site secondaire dans l'application {#step-7-copy-secrets-and-add-the-secondary-site-in-the-application}

1. [Configurez GitLab](configuration.md) pour définir les sites **principal** et **secondaire**.
