---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer Geo pour deux sites à nœud unique (avec des services PostgreSQL externes)
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Le guide suivant fournit des instructions concises sur la façon de déployer GitLab Geo pour une installation de deux sites à nœud unique en utilisant deux instances de package Linux et des bases de données PostgreSQL externes comme RDS, Azure Database ou Google Cloud SQL.

Prérequis :

- Vous disposez d'au moins deux sites GitLab fonctionnant de manière indépendante. Pour créer les sites, consultez la [documentation sur les architectures de référence GitLab](../../reference_architectures/_index.md).
  - Un site GitLab sert de **Geo primary site**. Vous pouvez utiliser différentes tailles d'architecture de référence pour chaque site Geo. Si vous disposez déjà d'une instance GitLab fonctionnelle, vous pouvez l'utiliser comme site primaire.
  - Le second site GitLab sert de **Geo secondary site**. Geo prend en charge plusieurs sites secondaires.
- Le site primaire Geo dispose d'au moins une licence [GitLab Premium](https://about.gitlab.com/pricing/). Vous n'avez besoin que d'une seule licence pour tous les sites.
- Confirmez que tous les sites satisfont aux [exigences pour l'exécution de Geo](../_index.md#requirements-for-running-geo).

## Configurer Geo pour le package Linux (Omnibus) {#set-up-geo-for-linux-package-omnibus}

Prérequis :

- Vous utilisez PostgreSQL 12 ou une version ultérieure, qui inclut l'[outil `pg_basebackup`](https://www.postgresql.org/docs/16/app-pgbasebackup.html).

### Configurer le site primaire {#configure-the-primary-site}

1. Connectez-vous en SSH à votre site primaire GitLab et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Ajoutez un nom de site Geo unique dans `/etc/gitlab/gitlab.rb` :

   ```ruby
   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'
   ```

1. Pour appliquer la modification, reconfigurez le site primaire :

   ```shell
   gitlab-ctl reconfigure
   ```

1. Définissez le site comme votre site Geo primaire :

   ```shell
   gitlab-ctl set-geo-primary-node
   ```

   Cette commande utilise le `external_url` défini dans `/etc/gitlab/gitlab.rb`.

Pour un exemple de configuration, consultez [Site primaire complet avec PostgreSQL externe](#complete-primary-site-with-external-postgresql).

### Configurer la base de données externe à répliquer {#configure-the-external-database-to-be-replicated}

Pour configurer une base de données externe, vous pouvez soit :

- Configurer vous-même la [réplication en streaming](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION-SLOTS) (par exemple Amazon RDS, ou bare metal non géré par le package Linux).
- Effectuer manuellement la configuration de vos installations de package Linux comme suit.

#### Exploiter les outils de votre fournisseur cloud pour répliquer la base de données primaire {#leverage-your-cloud-providers-tools-to-replicate-the-primary-database}

Supposons que vous disposez d'un site primaire configuré sur AWS EC2 utilisant RDS. Vous pouvez maintenant créer un réplica en lecture seule dans une région différente et le processus de réplication est géré par AWS. Assurez-vous d'avoir configuré le Network ACL (Access Control List), le Subnet et le Security Group selon vos besoins, afin que les nœuds Rails secondaires puissent accéder à la base de données.

Les instructions suivantes expliquent comment créer un réplica en lecture seule pour les fournisseurs cloud courants :

- Amazon RDS - [Creating a Read Replica](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html#USER_ReadRepl.Create)
- Azure Database for PostgreSQL - [Create and manage read replicas in Azure Database for PostgreSQL](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-read-replicas-portal)
- Google Cloud SQL - [Creating read replicas](https://cloud.google.com/sql/docs/postgres/replication/create-replica)

Lorsque votre réplica en lecture seule est configuré, vous pouvez passer directement à [la configuration de votre site secondaire](#configure-the-secondary-site-to-use-the-external-read-replica).

### Configurer le site secondaire pour utiliser le réplica en lecture externe {#configure-the-secondary-site-to-use-the-external-read-replica}

Avec les installations de packages Linux, le [`geo_secondary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles) a trois fonctions principales :

1. Configurer la base de données réplica.
1. Configurer la base de données de suivi.
1. Activer le [Geo Log Cursor](../_index.md#geo-log-cursor).

Pour configurer la connexion à la base de données réplica en lecture externe :

1. Connectez-vous en SSH à chaque nœud **Rails, Sidekiq and Geo Log Cursor** de votre site **secondaire** et identifiez-vous en tant que root :

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
   gitlab_rails['db_password'] = '<your_db_password_here>'

   gitlab_rails['db_username'] = 'gitlab'
   gitlab_rails['db_host'] = '<database_read_replica_host>'

   # Disable the bundled Omnibus PostgreSQL because we are
   # using an external PostgreSQL
   postgresql['enable'] = false
   ```

1. Copiez l'exemple de configuration depuis [Site secondaire complet avec PostgreSQL externe](#complete-secondary-site-with-external-postgresql). Pour appliquer les modifications, enregistrez le fichier et reconfigurez GitLab :

   ```shell
   gitlab-ctl reconfigure
   ```

Si vous avez des problèmes de connectivité avec votre base de données réplica, [vérifiez la connectivité TCP](../../raketasks/maintenance.md) depuis votre serveur avec la commande suivante :

```shell
gitlab-rake gitlab:tcp_check[<replica FQDN>,5432]
```

Si cette étape échoue, vous utilisez peut-être une adresse IP incorrecte, ou un pare-feu pourrait empêcher l'accès au site. Vérifiez l'adresse IP en portant une attention particulière à la différence entre les adresses publiques et privées. Si un pare-feu est présent, assurez-vous que le site secondaire est autorisé à se connecter au site primaire sur le port 5432.

#### Répliquer manuellement les valeurs secrètes GitLab {#manually-replicate-secret-gitlab-values}

GitLab stocke un certain nombre de valeurs secrètes dans `/etc/gitlab/gitlab-secrets.json`. Ce fichier JSON doit être identique sur chacun des nœuds du site. Vous devez répliquer manuellement le fichier secret sur tous vos sites secondaires, bien que le [ticket 3789](https://gitlab.com/gitlab-org/gitlab/-/issues/3789) propose de modifier ce comportement.

1. Connectez-vous en SSH à un nœud Rails de votre site primaire et exécutez la commande ci-dessous :

   ```shell
   sudo cat /etc/gitlab/gitlab-secrets.json
   ```

   Cela affiche les secrets que vous devez répliquer, au format JSON.

1. Connectez-vous en SSH à chaque nœud de votre site Geo secondaire et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Effectuez une sauvegarde de tous les secrets existants :

   ```shell
   mv /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.`date +%F`
   ```

1. Copiez `/etc/gitlab/gitlab-secrets.json` depuis le nœud Rails du site primaire vers chaque nœud du site secondaire. Vous pouvez également copier-coller le contenu du fichier entre les nœuds :

   ```shell
   sudo editor /etc/gitlab/gitlab-secrets.json

   # paste the output of the `cat` command you ran on the primary
   # save and exit
   ```

1. Assurez-vous que les permissions du fichier sont correctes :

   ```shell
   chown root:root /etc/gitlab/gitlab-secrets.json
   chmod 0600 /etc/gitlab/gitlab-secrets.json
   ```

1. Pour appliquer les modifications, reconfigurez chaque nœud de site secondaire Rails, Sidekiq et Gitaly :

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

#### Répliquer manuellement les clés d'hôte SSH du site primaire {#manually-replicate-the-primary-site-ssh-host-keys}

1. Connectez-vous en SSH à chaque nœud de votre site secondaire et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Sauvegardez toutes les clés d'hôte SSH existantes :

   ```shell
   find /etc/ssh -iname 'ssh_host_*' -exec cp {} {}.backup.`date +%F` \;
   ```

1. Copiez les clés d'hôte OpenSSH depuis le site primaire.

   - Si vous pouvez accéder en tant que root à l'un des nœuds du site primaire gérant le trafic SSH (généralement, les nœuds principaux de l'application GitLab Rails) :

     ```shell
     # Run this from the secondary site, change `<primary_site_fqdn>` for the IP or FQDN of the server
     scp root@<primary_node_fqdn>:/etc/ssh/ssh_host_*_key* /etc/ssh
     ```

   - Si vous n'avez accès qu'à travers un utilisateur disposant des privilèges `sudo` :

     ```shell
     # Run this from the node on your primary site:
     sudo tar --transform 's/.*\///g' -zcvf ~/geo-host-key.tar.gz /etc/ssh/ssh_host_*_key*

     # Run this on each node on your secondary site:
     scp <user_with_sudo>@<primary_site_fqdn>:geo-host-key.tar.gz .
     tar zxvf ~/geo-host-key.tar.gz -C /etc/ssh
     ```

1. Pour chaque nœud du site secondaire, assurez-vous que les permissions du fichier sont correctes :

   ```shell
   chown root:root /etc/ssh/ssh_host_*_key*
   chmod 0600 /etc/ssh/ssh_host_*_key
   ```

1. Pour vérifier la correspondance des empreintes de clés, exécutez la commande suivante sur les nœuds primaires et secondaires de chaque site :

   ```shell
   for file in /etc/ssh/ssh_host_*_key; do ssh-keygen -lf $file; done
   ```

   Vous devriez obtenir une sortie similaire à la suivante :

   ```shell
   1024 SHA256:FEZX2jQa2bcsd/fn/uxBzxhKdx4Imc4raXrHwsbtP0M root@serverhostname (DSA)
   256 SHA256:uw98R35Uf+fYEQ/UnJD9Br4NXUFPv7JAUln5uHlgSeY root@serverhostname (ECDSA)
   256 SHA256:sqOUWcraZQKd89y/QQv/iynPTOGQxcOTIXU/LsoPmnM root@serverhostname (ED25519)
   2048 SHA256:qwa+rgir2Oy86QI+PZi/QVR+MSmrdrpsuH7YyKknC+s root@serverhostname (RSA)
   ```

   La sortie doit être identique sur les deux nœuds.

1. Vérifiez que vous disposez des clés publiques correctes pour les clés privées existantes :

   ```shell
   # This will print the fingerprint for private keys:
   for file in /etc/ssh/ssh_host_*_key; do ssh-keygen -lf $file; done

   # This will print the fingerprint for public keys:
   for file in /etc/ssh/ssh_host_*_key.pub; do ssh-keygen -lf $file; done
   ```

   La sortie des commandes de clés publiques et privées doit générer la même empreinte.

1. Pour chaque nœud du site secondaire, redémarrez `sshd` :

   ```shell
   # Debian or Ubuntu installations
   sudo service ssh reload

   # CentOS installations
   sudo service sshd reload
   ```

1. Pour vérifier que SSH est toujours fonctionnel, depuis un nouveau terminal, connectez-vous en SSH à votre serveur secondaire GitLab. Si vous ne pouvez pas vous connecter, assurez-vous d'avoir les permissions correctes.

#### Recherche rapide des clés SSH autorisées {#fast-lookup-of-authorized-ssh-keys}

Une fois le processus de réplication initial terminé, suivez les étapes pour [configurer la recherche rapide des clés SSH autorisées](../../operations/fast_ssh_key_lookup.md).

La recherche rapide est [requise pour Geo](../../operations/fast_ssh_key_lookup.md#fast-lookup-is-required-for-geo).

> [!note]
> L'authentification est gérée par le site primaire. Ne configurez pas d'authentification personnalisée pour le site secondaire. Toute modification nécessitant un accès à la zone **Admin** doit être effectuée sur le site primaire, car le site secondaire est une copie en lecture seule.

#### Ajouter le site secondaire {#add-the-secondary-site}

1. Connectez-vous en SSH à chaque nœud Rails et Sidekiq de votre site secondaire et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez un nom unique pour votre site.

   ```ruby
   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<secondary_site_name_here>'
   ```

   Enregistrez le nom unique pour les étapes suivantes.

1. Pour appliquer les modifications, reconfigurez chaque nœud Rails et Sidekiq de votre site secondaire.

   ```shell
   gitlab-ctl reconfigure
   ```

1. Accédez à l'instance GitLab du nœud primaire :
   1. Dans le coin supérieur droit, sélectionnez **Admin**.
   1. Sélectionnez **Geo** > **Sites**.
   1. Sélectionnez **Ajouter un site**.

      ![Formulaire pour ajouter un nouveau site Geo secondaire](img/adding_a_secondary_v15_8.png)

   1. Dans **Nom**, saisissez la valeur de `gitlab_rails['geo_node_name']` dans `/etc/gitlab/gitlab.rb`. Les valeurs doivent correspondre exactement.
   1. Dans **URL externe**, saisissez la valeur de `external_url` dans `/etc/gitlab/gitlab.rb`. Il est acceptable qu'une valeur se termine par `/` et l'autre non. Sinon, les valeurs doivent correspondre exactement.
   1. Facultatif. Dans **URL interne (facultatif)**, saisissez une URL interne pour le site primaire.
   1. Facultatif. Sélectionnez les groupes ou les fragments de stockage qui doivent être répliqués par le site secondaire. Pour tout répliquer, laissez le champ vide. Consultez [la synchronisation sélective](../replication/selective_synchronization.md).
   1. Sélectionnez **Sauvegarder les modifications**.
1. Connectez-vous en SSH à chaque nœud Rails et Sidekiq de votre site secondaire et redémarrez les services :

   ```shell
   sudo gitlab-ctl restart
   ```

1. Vérifiez s'il existe des problèmes courants avec votre configuration Geo en exécutant :

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

   Si l'une des vérifications échoue, consultez la [documentation de dépannage](../replication/troubleshooting/_index.md).

1. Pour vérifier que le site secondaire est accessible, connectez-vous en SSH à un serveur Rails ou Sidekiq de votre site primaire et exécutez :

   ```shell
   sudo gitlab-rake gitlab:geo:check
   ```

   Si l'une des vérifications échoue, consultez la [documentation de dépannage](../replication/troubleshooting/_index.md).

Une fois que le site secondaire a été ajouté à la page d'administration Geo et redémarré, le site commence automatiquement à répliquer les données manquantes depuis le site primaire dans un processus appelé remplissage (backfill).

Pendant ce temps, le site primaire commence à notifier chaque site secondaire de toute modification, afin que le site secondaire puisse agir immédiatement sur les notifications.

Assurez-vous que le site secondaire est en cours d'exécution et accessible. Vous pouvez vous connecter au site secondaire avec les mêmes identifiants que ceux utilisés avec le site primaire.

#### Activer l'accès Git via HTTP/HTTPS et SSH {#enable-git-access-over-httphttps-and-ssh}

Geo synchronise les dépôts via HTTP/HTTPS (activé par défaut pour les nouvelles installations) et nécessite donc que cette méthode de clonage soit activée. Si vous convertissez un site existant vers Geo, vous devez vérifier que la méthode de clonage est activée.

Sur le site primaire :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Si vous utilisez Git via SSH :
   1. Assurez-vous que **Protocoles d'accès Git activés** est défini sur **SSH et HTTP(S)**.
   1. Activez la [recherche rapide des clés SSH autorisées dans la base de données](../../operations/fast_ssh_key_lookup.md) sur les sites primaire et secondaire.
1. Si vous n'utilisez pas Git via SSH, définissez **Protocoles d'accès Git activés** sur **Uniquement HTTP(S)**.

#### Vérifier le bon fonctionnement du site secondaire {#verify-proper-functioning-of-the-secondary-site}

Vous pouvez vous connecter au site secondaire avec les mêmes identifiants que ceux utilisés avec le site primaire.

Après vous être connecté :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
1. Vérifiez que le site est correctement identifié comme un site Geo secondaire et que Geo est activé.

La réplication initiale peut prendre un certain temps. Vous pouvez surveiller le processus de synchronisation sur chaque site Geo depuis le tableau de bord **Sites Geo** du site primaire dans votre navigateur.

![Tableau de bord d'administration Geo affichant l'état de synchronisation d'un site secondaire.](img/geo_dashboard_v14_0.png)

## Configurer la base de données de suivi {#configure-the-tracking-database}

> [!note]
> Cette étape est facultative si vous souhaitez également configurer votre base de données de suivi de manière externe sur un autre serveur.

Les sites **Secondaire** utilisent une installation PostgreSQL distincte comme base de données de suivi pour suivre l'état de réplication et récupérer automatiquement des problèmes de réplication potentiels. Le package Linux configure automatiquement une base de données de suivi lorsque `roles ['geo_secondary_role']` est défini. Si vous souhaitez exécuter cette base de données en dehors de votre installation de package Linux, utilisez les instructions suivantes.

### Services de base de données gérés dans le cloud {#cloud-managed-database-services}

Si vous utilisez un service géré dans le cloud pour la base de données de suivi, vous devrez peut-être accorder des rôles supplémentaires à votre utilisateur de base de données de suivi (par défaut, il s'agit de `gitlab_geo`) :

- Amazon RDS requiert le rôle [`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html#Appendix.PostgreSQL.CommonDBATasks.Roles).
- Azure Database for PostgreSQL requiert le rôle [`azure_pg_admin`](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-create-users#how-to-create-additional-admin-users-in-azure-database-for-postgresql).
- Google Cloud SQL requiert le rôle [`cloudsqlsuperuser`](https://cloud.google.com/sql/docs/postgres/users#default-users).

Des rôles supplémentaires sont nécessaires pour l'installation des extensions lors de l'installation et des mises à niveau. Comme alternative, [installez les extensions requises manuellement](../../postgresql/extensions.md).

> [!note]
> Si vous souhaitez utiliser Amazon RDS comme base de données de suivi, assurez-vous qu'elle a accès à la base de données secondaire. Malheureusement, l'attribution du même groupe de sécurité ne suffit pas car les règles sortantes ne s'appliquent pas aux bases de données RDS PostgreSQL. Par conséquent, vous devez explicitement ajouter une règle entrante au groupe de sécurité du réplica en lecture autorisant tout trafic TCP depuis la base de données de suivi sur le port 5432.

### Créer la base de données de suivi {#create-the-tracking-database}

Créez et configurez la base de données de suivi dans votre instance PostgreSQL :

1. Configurez PostgreSQL conformément au [document sur les exigences de base de données](../../../install/requirements.md#postgresql).
1. Configurez un utilisateur `gitlab_geo` avec un mot de passe de votre choix, créez la base de données `gitlabhq_geo_production` et faites de l'utilisateur le propriétaire de la base de données. Vous pouvez voir un exemple de cette configuration dans la [documentation d'installation compilée manuellement](../../../install/self_compiled/_index.md#7-database).
1. Si vous n'utilisez **not** une base de données PostgreSQL gérée dans le cloud, assurez-vous que votre site secondaire peut communiquer avec votre base de données de suivi en modifiant manuellement le `pg_hba.conf` associé à votre base de données de suivi. N'oubliez pas de redémarrer PostgreSQL ensuite pour que les modifications prennent effet :

   ```plaintext
   ##
   ## Geo Tracking Database Role
   ## - pg_hba.conf
   ##
   host    all         all               <trusted tracking IP>/32      md5
   host    all         all               <trusted secondary IP>/32     md5
   ```

### Configurer GitLab {#configure-gitlab}

Configurez GitLab pour utiliser cette base de données. Ces étapes s'appliquent aux déploiements avec package Linux et Docker.

1. Connectez-vous en SSH à un serveur GitLab **secondaire** et identifiez-vous en tant que root :

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

1. Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   gitlab-ctl reconfigure
   ```

#### Configurer manuellement le schéma de base de données (facultatif) {#manually-set-up-the-database-schema-optional}

La commande de reconfiguration dans les [étapes listées précédemment](#configure-gitlab) gère ces étapes automatiquement. Ces étapes sont fournies au cas où quelque chose se serait mal passé.

1. Cette tâche crée le schéma de base de données. Elle nécessite que l'utilisateur de la base de données soit un superutilisateur.

   ```shell
   sudo gitlab-rake db:create:geo
   ```

1. L'application des migrations de base de données Rails (mises à jour du schéma et des données) est également effectuée par la reconfiguration. Si `geo_secondary['auto_migrate'] = false` est défini, ou si le schéma a été créé manuellement, cette étape est requise :

   ```shell
   sudo gitlab-rake db:migrate:geo
   ```

## Exemples de configurations {#example-configurations}

### Site primaire complet avec PostgreSQL externe {#complete-primary-site-with-external-postgresql}

<!-- If you update this configuration example, also update the example in two_single_node_sites.md -->

Cet exemple complet de configuration `gitlab.rb` est destiné à un site primaire Geo utilisant PostgreSQL externe :

```ruby
# Primary site with external PostgreSQL configuration example

## Geo Primary role
roles(['geo_primary_role'])

## The unique identifier for the Geo site
gitlab_rails['geo_node_name'] = 'headquarters'

## External URL
external_url 'https://gitlab.example.com'

## External PostgreSQL configuration
postgresql['enable'] = false
gitlab_rails['db_adapter'] = 'postgresql'
gitlab_rails['db_encoding'] = 'unicode'
gitlab_rails['db_host'] = 'primary-postgres.example.com'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_database'] = 'gitlabhq_production'
gitlab_rails['db_username'] = 'gitlab'
gitlab_rails['db_password'] = 'your_database_password_here'

## SSL/TLS configuration
nginx['listen_port'] = 80
nginx['listen_https'] = false
letsencrypt['enable'] = false

## Object Storage configuration (recommended for external services)
gitlab_rails['object_store']['enabled'] = true
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'region' => 'us-east-1',
  'aws_access_key_id' => 'your_access_key',
  'aws_secret_access_key' => 'your_secret_key'
}

## Monitoring configuration
node_exporter['listen_address'] = '0.0.0.0:9100'
gitlab_workhorse['prometheus_listen_addr'] = '0.0.0.0:9229'
```

### Site secondaire complet avec PostgreSQL externe {#complete-secondary-site-with-external-postgresql}

<!-- If you update this configuration example, also update the example in two_single_node_sites.md -->

Cet exemple complet de configuration `gitlab.rb` est destiné à un site secondaire Geo utilisant PostgreSQL externe :

```ruby
# Secondary site with external PostgreSQL configuration example

## Geo Secondary role
roles(['geo_secondary_role'])

## The unique identifier for the Geo site
gitlab_rails['geo_node_name'] = 'location-2'

## External URL
external_url 'https://gitlab.example.com'

## External PostgreSQL configuration (read-only replica)
postgresql['enable'] = false
gitlab_rails['db_adapter'] = 'postgresql'
gitlab_rails['db_encoding'] = 'unicode'
gitlab_rails['db_host'] = 'secondary-postgres.example.com'
gitlab_rails['db_port'] = 5432
gitlab_rails['db_database'] = 'gitlabhq_production'
gitlab_rails['db_username'] = 'gitlab'
gitlab_rails['db_password'] = 'your_database_password_here'

## Geo tracking database configuration
geo_secondary['db_username'] = 'gitlab_geo'
geo_secondary['db_password'] = 'your_tracking_db_password_here'
geo_secondary['db_host'] = 'secondary-tracking-db.example.com'
geo_secondary['db_port'] = 5432
geo_postgresql['enable'] = false

## SSL/TLS configuration
nginx['listen_port'] = 80
nginx['listen_https'] = false
letsencrypt['enable'] = false

## Object Storage configuration (must match primary)
gitlab_rails['object_store']['enabled'] = true
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'region' => 'us-east-1',
  'aws_access_key_id' => 'your_access_key',
  'aws_secret_access_key' => 'your_secret_key'
}

## Monitoring configuration
node_exporter['listen_address'] = '0.0.0.0:9100'
gitlab_workhorse['prometheus_listen_addr'] = '0.0.0.0:9229'
```

## Dépannage {#troubleshooting}

Consultez [le dépannage de Geo](../replication/troubleshooting/_index.md).
