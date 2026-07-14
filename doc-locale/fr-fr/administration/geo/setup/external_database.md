---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Geo avec des instances PostgreSQL externes
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Ce document est pertinent si vous utilisez une instance PostgreSQL qui n'est pas gérée par le package Linux. Cela inclut les [instances gérées dans le cloud](../../reference_architectures/_index.md#best-practices-for-the-database-services), ou les instances PostgreSQL installées et configurées manuellement.

Assurez-vous d'utiliser l'une des versions de PostgreSQL [fournies avec le package Linux](../../package_information/postgresql_versions.md) pour [éviter les incompatibilités de versions](../_index.md#requirements-for-running-geo) au cas où un site Geo devrait être reconstruit.

> [!note]
> Si vous utilisez GitLab Geo, nous recommandons vivement d'exécuter des instances installées à l'aide du package Linux ou d'utiliser des [instances gérées dans le cloud validées](../../reference_architectures/_index.md#recommended-cloud-providers-and-services), car nous développons et testons activement sur la base de celles-ci. Nous ne pouvons pas garantir la compatibilité avec d'autres bases de données externes.

## Site **Principal** {#primary-site}

1. Connectez-vous en SSH à un **Rails node on your primary** et connectez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez :

   ```ruby
   ##
   ## Geo Primary role
   ## - configure dependent flags automatically to enable Geo
   ##
   roles ['geo_primary_role']

   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'
   ```

1. Reconfigurez le **Rails node** pour que la modification prenne effet :

   ```shell
   gitlab-ctl reconfigure
   ```

1. Exécutez la commande ci-dessous sur le **Rails node** pour définir le site comme site **principal** :

   ```shell
   gitlab-ctl set-geo-primary-node
   ```

   Cette commande utilise votre `external_url` définie dans `/etc/gitlab/gitlab.rb`.

### Configurer la base de données externe à répliquer {#configure-the-external-database-to-be-replicated}

Pour configurer une base de données externe, vous pouvez soit :

- Configurer vous-même la [réplication en continu](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION-SLOTS) (par exemple Amazon RDS, ou bare metal non géré par le package Linux).
- Effectuer manuellement la configuration de vos installations de packages Linux comme suit.

#### Utiliser les outils de votre fournisseur cloud pour répliquer la base de données principale {#leverage-your-cloud-providers-tools-to-replicate-the-primary-database}

Supposons que vous ayez un site principal configuré sur AWS EC2 qui utilise RDS. Vous pouvez maintenant simplement créer un réplica en lecture seule dans une région différente et le processus de réplication est géré par AWS. Assurez-vous d'avoir configuré le Network ACL (Access Control List), le Subnet et le Security Group selon vos besoins, afin que les nœuds Rails secondaires puissent accéder à la base de données.

Les instructions suivantes expliquent comment créer un réplica en lecture seule pour les fournisseurs cloud courants :

- Amazon RDS - [Creating a Read Replica](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html#USER_ReadRepl.Create)
- Azure Database for PostgreSQL - [Create and manage read replicas in Azure Database for PostgreSQL](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-read-replicas-portal)
- Google Cloud SQL - [Creating read replicas](https://cloud.google.com/sql/docs/postgres/replication/create-replica)

Une fois votre réplica en lecture seule configuré, vous pouvez passer directement à [la configuration de votre site secondaire](#configure-secondary-site-to-use-the-external-read-replica)

> [!warning]
> L'utilisation de méthodes de réplication logique telles que [AWS Database Migration Service](https://aws.amazon.com/dms/) ou [Google Cloud Database Migration Service](https://cloud.google.com/database-migration) pour, par exemple, répliquer depuis une base de données principale sur site vers un secondaire RDS n'est pas prise en charge.

#### Configurer manuellement la base de données principale pour la réplication {#manually-configure-the-primary-database-for-replication}

Le [`geo_primary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles) configure la base de données du nœud **principal** pour qu'elle soit répliquée en apportant des modifications à `pg_hba.conf` et `postgresql.conf`. Apportez manuellement les modifications de configuration suivantes à la configuration de votre base de données externe et assurez-vous de redémarrer PostgreSQL ensuite pour que les modifications prennent effet :

```plaintext
##
## Geo Primary Role
## - pg_hba.conf
##
host    all         all               <trusted primary IP>/32       md5
host    replication gitlab_replicator <trusted primary IP>/32       md5
host    all         all               <trusted secondary IP>/32     md5
host    replication gitlab_replicator <trusted secondary IP>/32     md5
```

```plaintext
##
## Geo Primary Role
## - postgresql.conf
##
wal_level = hot_standby
max_wal_senders = 10
wal_keep_segments = 50
max_replication_slots = 1 # number of secondary instances
hot_standby = on
```

## Sites **Secondaire** {#secondary-sites}

### Configurer manuellement la base de données réplica {#manually-configure-the-replica-database}

Apportez manuellement les modifications de configuration suivantes à vos fichiers `pg_hba.conf` et `postgresql.conf` de votre base de données réplica externe et assurez-vous de redémarrer PostgreSQL ensuite pour que les modifications prennent effet :

```plaintext
##
## Geo Secondary Role
## - pg_hba.conf
##
host    all         all               <trusted secondary IP>/32     md5
host    replication gitlab_replicator <trusted secondary IP>/32     md5
host    all         all               <trusted primary IP>/24       md5
```

```plaintext
##
## Geo Secondary Role
## - postgresql.conf
##
wal_level = hot_standby
max_wal_senders = 10
wal_keep_segments = 10
hot_standby = on
```

### Configurer le site **secondaire** pour utiliser le réplica en lecture seule externe {#configure-secondary-site-to-use-the-external-read-replica}

Avec les installations du package Linux, le [`geo_secondary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles) a trois fonctions principales :

1. Configurer la base de données réplica.
1. Configurer la base de données de suivi.
1. Activer le [Geo Log Cursor](../_index.md#geo-log-cursor) (non couvert dans cette section).

Pour configurer la connexion à la base de données réplica en lecture seule externe et activer le Log Cursor :

1. Connectez-vous en SSH à chaque nœud **Rails, Sidekiq and Geo Log Cursor** de votre site **secondaire** et connectez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez ce qui suit

   ```ruby
   ##
   ## Geo Secondary role
   ## - configure dependent flags automatically to enable Geo
   ##
   roles ['geo_secondary_role']

   # note this is shared between both databases,
   # make sure you define the same password in both
   gitlab_rails['db_password'] = '<your_primary_db_password_here>'

   gitlab_rails['db_username'] = 'gitlab'
   gitlab_rails['db_host'] = '<database_read_replica_host>'

   # Disable the bundled Omnibus PostgreSQL because we are
   # using an external PostgreSQL
   postgresql['enable'] = false
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation)

### Configurer la base de données de suivi {#configure-the-tracking-database}

Les sites **Secondaire** utilisent une installation PostgreSQL séparée comme base de données de suivi pour suivre l'état de réplication et récupérer automatiquement des problèmes de réplication potentiels. Le package Linux configure automatiquement une base de données de suivi lorsque `roles ['geo_secondary_role']` est défini. Si vous souhaitez exécuter cette base de données en dehors de votre installation du package Linux, utilisez les instructions suivantes.

#### Comprendre les bases de données de suivi internes et externes {#understanding-internal-and-external-tracking-databases}

Vous pouvez configurer la base de données de suivi pour qu'elle soit soit :

- Interne (`geo_postgresql['enable'] = true`) :  La base de données de suivi s'exécute en tant qu'instance PostgreSQL gérée sur le même serveur que l'application Rails. C'est la valeur par défaut.
- Externe (`geo_postgresql['enable'] = false`) :  La base de données de suivi s'exécute sur un serveur séparé ou en tant que service géré dans le cloud.

Dans les configurations multi-nœuds de sites secondaires, si vous activez la base de données de suivi sur un nœud Rails, elle devient « externe » pour tous les autres nœuds Rails du site. Tous les autres nœuds Rails doivent définir `geo_postgresql['enable'] = false` et spécifier les détails de connexion pour se connecter à cette base de données de suivi.

#### Services de base de données gérés dans le cloud {#cloud-managed-database-services}

Si vous utilisez un service géré dans le cloud pour la base de données de suivi, vous devrez peut-être accorder des rôles supplémentaires à l'utilisateur de votre base de données de suivi (par défaut, c'est `gitlab_geo`) :

- Amazon RDS requiert le rôle [`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html#Appendix.PostgreSQL.CommonDBATasks.Roles).
- Azure Database for PostgreSQL requiert le rôle [`azure_pg_admin`](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-create-users#how-to-create-additional-admin-users-in-azure-database-for-postgresql).
- Google Cloud SQL requiert le rôle [`cloudsqlsuperuser`](https://cloud.google.com/sql/docs/postgres/users#default-users).

C'est pour l'installation des extensions lors de l'installation et des mises à niveau. Comme alternative, [installez manuellement les extensions requises](../../postgresql/extensions.md).

> [!note]
> Si vous souhaitez utiliser Amazon RDS comme base de données de suivi, assurez-vous qu'elle a accès à la base de données secondaire. Malheureusement, le simple fait d'attribuer le même groupe de sécurité n'est pas suffisant, car les règles sortantes ne s'appliquent pas aux bases de données RDS PostgreSQL. Par conséquent, vous devez explicitement ajouter une règle entrante au groupe de sécurité du réplica en lecture seule autorisant tout le trafic TCP depuis la base de données de suivi sur le port 5432.

#### Créer la base de données de suivi {#create-the-tracking-database}

Créez et configurez la base de données de suivi dans votre instance PostgreSQL :

1. Configurez PostgreSQL conformément au [document sur les exigences de la base de données](../../../install/requirements.md#postgresql).
1. Configurez un utilisateur `gitlab_geo` avec un mot de passe de votre choix, créez la base de données `gitlabhq_geo_production` et faites de l'utilisateur le propriétaire de la base de données. Vous pouvez voir un exemple de cette configuration dans la [documentation d'installation auto-compilée](../../../install/self_compiled/_index.md#7-database).
1. Si vous n'utilisez **not** une base de données PostgreSQL gérée dans le cloud, assurez-vous que votre site secondaire peut communiquer avec votre base de données de suivi en modifiant manuellement le fichier `pg_hba.conf` associé à votre base de données de suivi. N'oubliez pas de redémarrer PostgreSQL ensuite pour que les modifications prennent effet :

   ```plaintext
   ##
   ## Geo Tracking Database Role
   ## - pg_hba.conf
   ##
   host    all         all               <trusted tracking IP>/32      md5
   host    all         all               <trusted secondary IP>/32     md5
   # In multi-node setups, add entries for all Rails nodes that will connect
   ```

#### Configurer GitLab {#configure-gitlab}

Configurez GitLab pour utiliser cette base de données. Ces étapes concernent les déploiements avec le package Linux et Docker.

1. Connectez-vous en SSH à un serveur GitLab **secondaire** et connectez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` avec les paramètres de connexion et les identifiants pour la machine hébergeant l'instance PostgreSQL :

   ```ruby
   geo_secondary['db_username'] = 'gitlab_geo'
   geo_secondary['db_password'] = '<your_tracking_db_password_here>'

   geo_secondary['db_host'] = '<tracking_database_host>'
   geo_secondary['db_port'] = <tracking_database_port>      # change to the correct port
   geo_postgresql['enable'] = false     # don't use internal managed instance
   ```

   Dans les configurations multi-nœuds, appliquez cette configuration à chaque nœud Rails devant se connecter à la base de données de suivi externe.

1. Enregistrez le fichier et [reconfigurez GitLab](../../restart_gitlab.md#reconfigure-a-linux-package-installation)

#### Configurer le schéma de base de données {#set-up-the-database-schema}

La commande de reconfiguration dans les [étapes précédemment listées](#configure-gitlab) pour les déploiements avec le package Linux et Docker devrait gérer ces étapes automatiquement.

1. Cette tâche crée le schéma de base de données. Elle nécessite que l'utilisateur de la base de données soit un superutilisateur.

   ```shell
   sudo gitlab-rake db:create:geo
   ```

1. L'application des migrations de base de données Rails (mises à jour du schéma et des données) est également effectuée par la reconfiguration. Si `geo_secondary['auto_migrate'] = false` est défini, ou si le schéma a été créé manuellement, cette étape sera nécessaire :

   ```shell
   sudo gitlab-rake db:migrate:geo
   ```
