---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Apprenez à configurer et gérer la réplication de base de données GitLab Geo pour maintenir les sites principal et secondaires synchronisés, notamment les exigences, les méthodes de réplication et les conseils de dépannage."
title: Réplication de la base de données Geo
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Ce document décrit les étapes minimales requises pour répliquer votre base de données GitLab principale vers la base de données d'un site secondaire. Il se peut que vous deviez modifier certaines valeurs, en fonction d'attributs tels que la configuration et la taille de votre base de données.

> [!note]
> Si votre installation GitLab utilise des instances PostgreSQL externes (non gérées par une installation de package Linux), les rôles ne peuvent pas effectuer toutes les étapes de configuration nécessaires. Dans ce cas, utilisez plutôt le processus [Geo avec des instances PostgreSQL externes](external_database.md).

Assurez-vous que le site **secondaire** exécute la même version de GitLab Enterprise Edition que le site **principal**. Confirmez que vous avez ajouté une licence pour un [abonnement Premium ou Ultimate](https://about.gitlab.com/pricing/) à votre site **principal**.

Assurez-vous de lire et de passer en revue toutes ces étapes avant de les exécuter dans vos environnements de test ou de production.

> [!note]
> Les étapes du processus de configuration doivent être effectuées dans l'ordre indiqué dans la documentation. Sinon, [complétez toutes les étapes précédentes](_index.md#using-linux-package-installations) avant de continuer.

## Exigences de cohérence des mots de passe de la base de données {#database-password-consistency-requirements}

Chaque type de mot de passe lié à la base de données doit avoir des valeurs correspondantes sur tous les sites Geo (principal et secondaires). Cela inclut :

- `postgresql['sql_replication_password']` (mot de passe de l'utilisateur de réplication, MD5)
- `postgresql['sql_user_password']` (mot de passe de l'utilisateur de la base de données GitLab, MD5)
- `gitlab_rails['db_password']` (mot de passe de l'utilisateur de la base de données GitLab, en texte clair)
- `patroni['replication_password']` (pour les configurations Patroni, en texte clair)
- `patroni['password']` (pour l'authentification de l'API Patroni, en texte clair)
- `postgresql['pgbouncer_user_password']` (lors de l'utilisation de PgBouncer, MD5)

Par exemple, la valeur `patroni['password']` configurée sur le site principal doit être identique à la valeur `patroni['password']` sur tous les sites secondaires.

Ces mots de passe sont utilisés pour l'authentification de la base de données et la réplication entre les sites principal et secondaires. L'utilisation de mots de passe différents entraîne des échecs de réplication et empêche le bon fonctionnement de Geo.

## Réplication de base de données à instance unique {#single-instance-database-replication}

Une réplication de base de données à instance unique est plus facile à configurer et offre toujours les mêmes capacités Geo qu'une alternative en cluster. Elle est utile pour les configurations fonctionnant sur une seule machine ou souhaitant évaluer Geo pour une future installation en cluster.

Une instance unique peut être étendue à une version en cluster à l'aide de Patroni, ce qui est recommandé pour une architecture hautement disponible.

Suivez les instructions ci-dessous pour configurer la réplication PostgreSQL en tant que base de données à instance unique. Vous pouvez également consulter les instructions de [réplication de base de données multi-nœuds](#multi-node-database-replication) pour configurer la réplication avec un cluster Patroni.

### Réplication PostgreSQL {#postgresql-replication}

Le site GitLab **principal** où les opérations d'écriture se produisent se connecte au serveur de base de données **principal**. Les sites **Secondaire** se connectent à leurs propres serveurs de base de données (qui sont en lecture seule).

Vous devriez utiliser les [slots de réplication PostgreSQL](https://medium.com/@tk512/replication-slots-in-postgresql-b4b03d277c75) pour vous assurer que le site **principal** conserve toutes les données nécessaires à la récupération des sites **secondaire**. Voir ci-dessous pour plus de détails.

Le guide suivant suppose que :

- Vous utilisez le package Linux (et donc PostgreSQL 12 ou version ultérieure), qui inclut l'[outil `pg_basebackup`](https://www.postgresql.org/docs/16/app-pgbasebackup.html).
- Vous avez un site **principal** déjà configuré (le serveur GitLab depuis lequel vous effectuez la réplication), exécutant PostgreSQL (ou une version équivalente) géré par votre installation de package Linux, et vous avez un nouveau site **secondaire** configuré avec les mêmes [versions de PostgreSQL](../_index.md#requirements-for-running-geo), le même OS et GitLab sur tous les sites.

> [!warning]
> Geo fonctionne avec la réplication en continu. La réplication logique n'est pas prise en charge, mais l'[epic 18022](https://gitlab.com/groups/gitlab-org/-/epics/18022) propose de modifier ce comportement.

#### Étape 1. Configurer le site **principal** {#step-1-configure-the-primary-site}

1. Connectez-vous en SSH à votre site GitLab **principal** et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. [Désactivez les mises à niveau automatiques de PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades) pour éviter des interruptions non planifiées lors de la mise à niveau de GitLab. Tenez compte des [mises en garde connues lors de la mise à niveau de PostgreSQL avec Geo](https://docs.gitlab.com/omnibus/settings/database/#caveats-when-upgrading-postgresql-with-geo). En particulier pour les environnements plus importants, les mises à niveau de PostgreSQL doivent être planifiées et exécutées consciencieusement. Par conséquent et à l'avenir, assurez-vous que les mises à niveau de PostgreSQL font partie des activités de maintenance régulières.
1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez un nom **unique** pour votre site :

   ```ruby
   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'
   ```

1. Reconfigurez le site **principal** pour que la modification prenne effet :

   ```shell
   gitlab-ctl reconfigure
   ```

1. Exécutez la commande ci-dessous pour définir le site comme site **principal** :

   ```shell
   gitlab-ctl set-geo-primary-node
   ```

   Cette commande utilise votre `external_url` défini dans `/etc/gitlab/gitlab.rb`.

1. Définissez un mot de passe pour l'utilisateur de base de données `gitlab` :

   Générez un hachage MD5 du mot de passe souhaité :

   ```shell
   gitlab-ctl pg-password-md5 gitlab
   # Enter password: <your_db_password_here>
   # Confirm password: <your_db_password_here>
   # fca0b89a972d69f00eb3ec98a5838484
   ```

   Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Fill with the hash generated by `gitlab-ctl pg-password-md5 gitlab`
   postgresql['sql_user_password'] = '<md5_hash_of_your_db_password>'

   # Every node that runs Puma or Sidekiq needs to have the database
   # password specified as below. If you have a high-availability setup, this
   # must be present in all application nodes.
   gitlab_rails['db_password'] = '<your_db_password_here>'
   ```

1. Définissez un mot de passe pour l'[utilisateur de réplication](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION) de la base de données.

   Utilisez le nom d'utilisateur défini dans `/etc/gitlab/gitlab.rb` sous le paramètre `postgresql['sql_replication_user']`. La valeur par défaut est `gitlab_replicator`. Si vous avez modifié le nom d'utilisateur, adaptez les instructions ci-dessous.

   Générez un hachage MD5 du mot de passe souhaité :

   ```shell
   gitlab-ctl pg-password-md5 gitlab_replicator
   # Enter password: <your_replication_password_here>
   # Confirm password: <your_replication_password_here>
   # 950233c0dfc2f39c64cf30457c3b7f1e
   ```

   Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Fill with the hash generated by `gitlab-ctl pg-password-md5 gitlab_replicator`
   postgresql['sql_replication_password'] = '<md5_hash_of_your_replication_password>'
   ```

   Si vous utilisez une base de données externe non gérée par votre installation de package Linux, vous devez créer l'utilisateur `gitlab_replicator` et définir manuellement un mot de passe pour cet utilisateur :

   ```sql
   --- Create a new user 'replicator'
   CREATE USER gitlab_replicator;

   --- Set/change a password and grants replication privilege
   ALTER USER gitlab_replicator WITH REPLICATION ENCRYPTED PASSWORD '<replication_password>';
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` et définissez le rôle sur `geo_primary_role` (pour plus d'informations, voir [les rôles Geo](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)) :

   ```ruby
   ## Geo Primary role
   roles(['geo_primary_role'])
   ```

1. Configurez PostgreSQL pour écouter sur les interfaces réseau :

   Pour des raisons de sécurité, PostgreSQL n'écoute par défaut sur aucune interface réseau. Cependant, Geo exige que le site **secondaire** puisse se connecter à la base de données du site **principal**. Pour cette raison, vous avez besoin de l'adresse IP de chaque site.

   > [!note]
   > Pour les instances PostgreSQL externes, consultez les [instructions supplémentaires](external_database.md).

   Si vous utilisez un fournisseur de cloud, vous pouvez rechercher les adresses de chaque site Geo via la console de gestion de votre fournisseur de cloud.

   Pour rechercher l'adresse d'un site Geo, connectez-vous en SSH au site Geo et exécutez :

   ```shell
   ##
   ## Private address
   ##
   ip route get 255.255.255.255 | awk '{print "Private address:", $NF; exit}'

   ##
   ## Public address
   ##
   echo "External address: $(curl --silent "ipinfo.io/ip")"
   ```

   Dans la plupart des cas, les adresses suivantes sont utilisées pour configurer GitLab Geo :

   | Configuration                           | Adresse                                                               |
   |:----------------------------------------|:----------------------------------------------------------------------|
   | `postgresql['listen_address']`          | Adresse publique ou adresse privée VPC du site **Principal**.                     |
   | `postgresql['md5_auth_cidr_addresses']` | Adresses publiques ou adresses privées VPC des sites **Principal** et **Secondaire**. |

   Si vous utilisez Google Cloud Platform, SoftLayer ou tout autre fournisseur proposant un cloud privé virtuel (VPC), nous vous recommandons d'utiliser les adresses « privées » ou « internes » des sites **principal** et **secondaire** pour `postgresql['md5_auth_cidr_addresses']` et `postgresql['listen_address']`.

   L'option `listen_address` ouvre PostgreSQL aux connexions réseau avec l'interface correspondant à l'adresse indiquée. Consultez [la documentation PostgreSQL](https://www.postgresql.org/docs/16/runtime-config-connection.html) pour plus de détails.

   > [!note]
   > Si vous avez besoin d'utiliser `0.0.0.0` ou `*` comme `listen_address`, vous devez également ajouter `127.0.0.1/32` au paramètre `postgresql['md5_auth_cidr_addresses']`, pour permettre à Rails de se connecter via `127.0.0.1`. Pour plus d'informations, consultez le [ticket 5258](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5258).

   Selon votre configuration réseau, les adresses suggérées peuvent être incorrectes. Si vos sites **principal** et **secondaire** se connectent via un réseau local, ou un réseau virtuel reliant des zones de disponibilité comme l'[Amazon VPC](https://aws.amazon.com/vpc/) ou le [Google VPC](https://cloud.google.com/vpc/), vous devriez utiliser l'adresse privée du site **secondaire** pour `postgresql['md5_auth_cidr_addresses']`.

   Modifiez `/etc/gitlab/gitlab.rb` et ajoutez ce qui suit, en remplaçant les adresses IP par des adresses adaptées à votre configuration réseau :

   ```ruby
   ##
   ## Primary address
   ## - replace '<primary_node_ip>' with the public or VPC address of your Geo primary node
   ##
   postgresql['listen_address'] = '<primary_site_ip>'

   ##
   # Allow PostgreSQL client authentication from the primary and secondary IPs. These IPs may be
   # public or VPC addresses in CIDR format, for example ['198.51.100.1/32', '198.51.100.2/32']
   ##
   postgresql['md5_auth_cidr_addresses'] = ['<primary_site_ip>/32', '<secondary_site_ip>/32']

   ##
   ## Replication settings
   ##
   # postgresql['max_replication_slots'] = 1 # Set this to be the number of Geo secondary nodes if you have more than one
   # postgresql['max_wal_senders'] = 10
   # postgresql['wal_keep_segments'] = 10
   ```

1. Désactivez temporairement les migrations automatiques de base de données jusqu'à ce que PostgreSQL soit redémarré et en écoute sur l'adresse privée. Modifiez `/etc/gitlab/gitlab.rb` et remplacez la valeur de la configuration par false :

   ```ruby
   ## Disable automatic database migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. Facultatif. Si vous souhaitez ajouter un autre site **secondaire**, le paramètre correspondant ressemblerait à :

   ```ruby
   postgresql['md5_auth_cidr_addresses'] = ['<primary_site_ip>/32', '<secondary_site_ip>/32', '<another_secondary_site_ip>/32']
   ```

   Vous pouvez également modifier `wal_keep_segments` et `max_wal_senders` pour répondre à vos exigences de réplication de base de données. Consultez la [documentation PostgreSQL - Réplication](https://www.postgresql.org/docs/16/runtime-config-replication.html) pour plus d'informations.

1. Enregistrez le fichier et reconfigurez GitLab pour appliquer les modifications d'écoute de la base de données et les modifications des slots de réplication :

   ```shell
   gitlab-ctl reconfigure
   ```

   Redémarrez PostgreSQL pour que ses modifications prennent effet :

   ```shell
   gitlab-ctl restart postgresql
   ```

1. Réactivez les migrations maintenant que PostgreSQL est redémarré et en écoute sur l'adresse privée.

   Modifiez `/etc/gitlab/gitlab.rb` et **modification** la configuration en `true` :

   ```ruby
   gitlab_rails['auto_migrate'] = true
   ```

   Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   gitlab-ctl reconfigure
   ```

1. Maintenant que le serveur PostgreSQL est configuré pour accepter les connexions distantes, exécutez `netstat -plnt | grep 5432` pour vous assurer que PostgreSQL écoute sur le port `5432` vers l'adresse privée du site **principal**.
1. Un certificat a été automatiquement généré lors de la reconfiguration de GitLab. Celui-ci est utilisé automatiquement pour protéger votre trafic PostgreSQL des oreilles indiscrètes. Pour se protéger contre les attaquants actifs (« homme du milieu »), le site **secondaire** a besoin d'une copie de l'autorité de certification (CA) qui a signé le certificat. Dans le cas de ce certificat auto-signé, faites une copie du fichier PostgreSQL `server.crt` sur le site **principal** en exécutant cette commande :

   ```shell
   cat ~gitlab-psql/data/server.crt
   ```

   Copiez le résultat dans le presse-papiers ou dans un fichier local. Vous en aurez besoin lors de la configuration du site **secondaire** ! Le certificat n'est pas une donnée sensible.

   Cependant, ce certificat est créé avec un nom commun (Common Name) générique `PostgreSQL`. Pour cette raison, vous devez utiliser le mode `verify-ca` lors de la réplication de la base de données, sinon la non-correspondance du nom d'hôte provoque des erreurs.

1. Facultatif. Générez votre propre certificat SSL et [configurez manuellement SSL pour PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#configuring-ssl), au lieu d'utiliser le certificat généré.

   Vous avez besoin au minimum du certificat SSL et de la clé. Définissez les valeurs `postgresql['ssl_cert_file']` et `postgresql['ssl_key_file']` avec leurs chemins complets, conformément à la documentation SSL de la base de données.

   Cela vous permet d'utiliser le mode SSL `verify-full` lors de la réplication de la base de données et de bénéficier de l'avantage supplémentaire de la vérification du nom d'hôte complet dans le CN.

   À l'avenir, vous pouvez utiliser ce certificat (que vous avez également défini dans `postgresql['ssl_cert_file']`) au lieu du certificat auto-signé généré automatiquement précédemment. Cela vous permet d'utiliser `verify-full` sans erreurs de réplication si le CN correspond.

   Sur votre base de données principale, ouvrez `/etc/gitlab/gitlab.rb` et recherchez `postgresql['ssl_ca_file']` (le certificat CA). Copiez sa valeur dans votre presse-papiers, que vous collerez ensuite dans `server.crt`.

#### Étape 2. Configurer le serveur **secondaire** {#step-2-configure-the-secondary-server}

1. Connectez-vous en SSH à votre site GitLab **secondaire** et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. [Désactivez les mises à niveau automatiques de PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades) pour éviter des interruptions non planifiées lors de la mise à niveau de GitLab. Tenez compte des [mises en garde connues lors de la mise à niveau de PostgreSQL avec Geo](https://docs.gitlab.com/omnibus/settings/database/#caveats-when-upgrading-postgresql-with-geo). En particulier pour les environnements plus importants, les mises à niveau de PostgreSQL doivent être planifiées et exécutées consciencieusement. Par conséquent et à l'avenir, assurez-vous que les mises à niveau de PostgreSQL font partie des activités de maintenance régulières.
1. Arrêtez le serveur d'application et Sidekiq :

   ```shell
   gitlab-ctl stop puma
   gitlab-ctl stop sidekiq
   ```

   > [!note]
   > Cette étape est importante pour éviter d'exécuter quoi que ce soit avant que le site soit entièrement configuré.

1. [Vérifiez la connectivité TCP](../../raketasks/maintenance.md) vers le serveur PostgreSQL du site **principal** :

   ```shell
   gitlab-rake gitlab:tcp_check[<primary_site_ip>,5432]
   ```

   > [!note]
   > Si cette étape échoue, vous utilisez peut-être une adresse IP incorrecte, ou un pare-feu bloque l'accès au site. Vérifiez l'adresse IP en prêtant une attention particulière à la différence entre les adresses publiques et privées. Assurez-vous que, si un pare-feu est présent, le site **secondaire** est autorisé à se connecter au site **principal** sur le port 5432.

1. Créez un fichier `server.crt` sur le site **secondaire**, avec le contenu obtenu lors de la dernière étape de la configuration du site **principal** :

   ```shell
   editor server.crt
   ```

1. Configurez la vérification TLS de PostgreSQL sur le site **secondaire** :

   Installez le fichier `server.crt` :

   ```shell
   install \
      -D \
      -o gitlab-psql \
      -g gitlab-psql \
      -m 0400 \
      -T server.crt ~gitlab-psql/.postgresql/root.crt
   ```

   PostgreSQL ne reconnaît désormais que ce certificat exact lors de la vérification des connexions TLS. Le certificat ne peut être répliqué que par quelqu'un ayant accès à la clé privée, qui est **only** présente sur le site **principal**.

1. Testez que l'utilisateur `gitlab-psql` peut se connecter à la base de données du site **principal** (le nom de base de données par défaut est `gitlabhq_production` sur une installation de package Linux) :

   ```shell
   sudo \
      -u gitlab-psql /opt/gitlab/embedded/bin/psql \
      --list \
      -U gitlab_replicator \
      -d "dbname=gitlabhq_production sslmode=verify-ca" \
      -W \
      -h <primary_site_ip>
   ```

   > [!note]
   > Si vous utilisez des certificats générés manuellement et souhaitez utiliser `sslmode=verify-full` pour bénéficier de la vérification complète du nom d'hôte, remplacez `verify-ca` par `verify-full` lors de l'exécution de la commande.

   Lorsque vous y êtes invité, saisissez le mot de passe en texte clair que vous avez défini lors de la première étape pour l'utilisateur `gitlab_replicator`. Si tout a fonctionné correctement, vous devriez voir la liste des bases de données du site **principal**.

   Un échec de connexion ici indique que la configuration TLS est incorrecte. Assurez-vous que le contenu de `~gitlab-psql/data/server.crt` sur le site **principal** correspond au contenu de `~gitlab-psql/.postgresql/root.crt` sur le site **secondaire**.

1. Modifiez `/etc/gitlab/gitlab.rb` et définissez le rôle sur `geo_secondary_role` (pour plus d'informations, voir [les rôles Geo](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles)) :

   ```ruby
   ##
   ## Geo Secondary role
   ## - configure dependent flags automatically to enable Geo
   ##
   roles(['geo_secondary_role'])
   ```

1. Configurez PostgreSQL :

   Cette étape est similaire à la façon dont vous avez configuré l'instance **principal**. Vous devez l'activer, même si vous utilisez un seul nœud.

   > [!warning]
   > Chaque type de mot de passe doit avoir des [valeurs correspondantes](#database-password-consistency-requirements) sur tous les sites Geo.

   Modifiez `/etc/gitlab/gitlab.rb` et ajoutez ce qui suit, en remplaçant les adresses IP par des adresses adaptées à votre configuration réseau :

   ```ruby
   ##
   ## Secondary address
   ## - replace '<secondary_site_ip>' with the public or VPC address of your Geo secondary site
   ##
   postgresql['listen_address'] = '<secondary_site_ip>'
   postgresql['md5_auth_cidr_addresses'] = ['<secondary_site_ip>/32']

   ##
   ## Database credentials password (defined previously in primary site)
   ## - replicate same values here as defined in primary site
   ##
   postgresql['sql_replication_password'] = '<md5_hash_of_your_replication_password>'
   postgresql['sql_user_password'] = '<md5_hash_of_your_db_password>'
   gitlab_rails['db_password'] = '<your_db_password_here>'
   ```

   Pour les instances PostgreSQL externes, consultez les [instructions supplémentaires](external_database.md). Si vous remettez en ligne un ancien site **principal** pour qu'il serve de site **secondaire**, vous devez également supprimer `roles(['geo_primary_role'])` ou `geo_primary_role['enable'] = true`.

1. Reconfigurez GitLab pour que les modifications prennent effet :

   ```shell
   gitlab-ctl reconfigure
   ```

1. Redémarrez PostgreSQL pour que la modification de l'IP prenne effet :

   ```shell
   gitlab-ctl restart postgresql
   ```

#### Étape 3. Lancer le processus de réplication {#step-3-initiate-the-replication-process}

Voici un script qui connecte la base de données du site **secondaire** à la base de données du site **principal**. Ce script réplique la base de données et crée les fichiers nécessaires à la réplication en continu.

Les répertoires utilisés sont ceux par défaut configurés dans une installation de package Linux. Si vous avez modifié des paramètres par défaut, configurez le script en conséquence (en remplaçant les répertoires et les chemins).

> [!warning]
> Assurez-vous d'exécuter ceci sur le site **secondaire**, car cela supprime toutes les données de PostgreSQL avant d'exécuter `pg_basebackup`.

1. Connectez-vous en SSH à votre site GitLab **secondaire** et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Choisissez un [nom compatible avec les bases de données](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION-SLOTS-MANIPULATION) à utiliser pour votre site **secondaire** comme nom de slot de réplication. Par exemple, si votre domaine est `secondary.geo.example.com`, utilisez `secondary_example` comme nom de slot, comme indiqué dans les commandes ci-dessous.

1. Exécutez la commande ci-dessous pour démarrer une sauvegarde/restauration et lancer la réplication

   > [!warning]
   > Chaque site Geo **secondaire** doit avoir son propre nom de slot de réplication unique. L'utilisation du même nom de slot entre deux secondaires interrompt la réplication PostgreSQL.

   Les noms de slots de réplication ne doivent contenir que des lettres minuscules, des chiffres et le caractère de soulignement.

   Lorsque vous y êtes invité, saisissez le mot de passe en texte clair que vous avez configuré pour l'utilisateur `gitlab_replicator` lors de la première étape.

   ```shell
   gitlab-ctl replicate-geo-database \
      --slot-name=<secondary_site_name> \
      --host=<primary_site_ip> \
      --sslmode=verify-ca
   ```

   > [!note]
   > Si vous avez généré des certificats PostgreSQL personnalisés, vous devez utiliser `--sslmode=verify-full` (ou omettre entièrement la ligne `sslmode`), afin de bénéficier de la validation supplémentaire du nom d'hôte complet dans le CN / SAN du certificat pour une sécurité renforcée. Sinon, l'utilisation du certificat créé automatiquement avec `verify-full` échoue, car il possède un CN générique `PostgreSQL` qui ne correspond pas à la valeur `--host` dans cette commande.

   Cette commande accepte également un certain nombre d'options supplémentaires. Vous pouvez utiliser `--help` pour les lister toutes, mais voici quelques conseils :

   - Si votre site principal comporte un seul nœud, utilisez l'hôte du nœud principal comme paramètre `--host`.
   - Si votre site principal utilise une base de données PostgreSQL externe, vous devez ajuster le paramètre `--host` :
     - Pour les configurations PgBouncer, ciblez directement l'hôte de la base de données PostgreSQL réelle, et non l'adresse PgBouncer.
     - Pour les configurations Patroni, ciblez l'hôte du leader Patroni actuel.
     - Lors de l'utilisation d'un équilibreur de charge (par exemple, HAProxy), si l'équilibreur de charge est configuré pour toujours router vers le leader Patroni, vous pouvez cibler l'équilibreur de charge. Sinon, vous devez cibler l'hôte de base de données réel.
     - Pour les configurations avec un nœud PostgreSQL dédié, ciblez directement l'hôte de base de données dédié.
   - Modifiez `--slot-name` par le nom du slot de réplication à utiliser sur la base de données **principal**. Le script tente de créer automatiquement le slot de réplication s'il n'existe pas.
   - Si PostgreSQL écoute sur un port non standard, ajoutez `--port=`.
   - Si votre base de données est trop volumineuse pour être transférée en 30 minutes, vous devez augmenter le délai d'expiration. Par exemple, utilisez `--backup-timeout=3600` si vous prévoyez que la réplication initiale prendra moins d'une heure.
   - Passez `--sslmode=disable` pour ignorer complètement l'authentification TLS de PostgreSQL (par exemple, si vous savez que le chemin réseau est sécurisé, ou si vous utilisez un VPN site à site). Ce n'est **not** sûr sur Internet public !
   - Vous pouvez lire plus de détails sur chaque `sslmode` dans la [documentation PostgreSQL](https://www.postgresql.org/docs/16/libpq-ssl.html#LIBPQ-SSL-PROTECTION). Les instructions répertoriées précédemment sont rédigées avec soin pour assurer une protection contre les écoutes passives et les attaquants actifs de type « homme du milieu ».
   - Si vous réutilisez un ancien site comme site Geo **secondaire**, vous devez ajouter `--force` à la ligne de commande.
   - Sur une machine hors production, vous pouvez désactiver l'étape de sauvegarde (si vous êtes certain que c'est ce que vous souhaitez) en ajoutant `--skip-backup`.

Le processus de réplication est maintenant terminé.

> [!note]
> Le processus de réplication copie uniquement les données de la base de données du site principal vers la base de données du site secondaire. Pour terminer la configuration de votre site secondaire, [ajoutez le site secondaire sur votre site principal](../replication/configuration.md#step-3-add-the-secondary-site).

### Prise en charge de PgBouncer (facultatif) {#pgbouncer-support-optional}

[PgBouncer](https://www.pgbouncer.org/) peut être utilisé avec GitLab Geo pour regrouper les connexions PostgreSQL, ce qui peut améliorer les performances même lors d'une installation à instance unique.

Vous devriez utiliser PgBouncer si vous utilisez GitLab dans une configuration hautement disponible avec un cluster de nœuds supportant un site Geo **principal** et deux autres clusters de nœuds supportant un site Geo **secondaire**. Vous avez besoin de deux nœuds PgBouncer : un pour la base de données principale et l'autre pour la base de données de suivi. Pour plus d'informations, consultez [la documentation correspondante](../../postgresql/replication_and_failover.md).

### Modification du mot de passe de réplication {#changing-the-replication-password}

> [!warning]
> Lors de la modification du mot de passe de réplication, vous devez le mettre à jour sur **l'ensemble** des sites Geo (principal et tous les secondaires) avec la [même valeur de mot de passe](#database-password-consistency-requirements). Le fait de ne pas synchroniser les mots de passe interrompt la réplication.

Pour modifier le mot de passe de l'[utilisateur de réplication](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION) lors de l'utilisation d'instances PostgreSQL gérées par une installation de package Linux :

Sur le site GitLab Geo **principal** :

1. La valeur par défaut de l'utilisateur de réplication est `gitlab_replicator`, mais si vous avez défini un utilisateur de réplication personnalisé dans votre `/etc/gitlab/gitlab.rb` sous le paramètre `postgresql['sql_replication_user']`, assurez-vous d'adapter les instructions suivantes à votre propre utilisateur.

   Générez un hachage MD5 du mot de passe souhaité :

   ```shell
   sudo gitlab-ctl pg-password-md5 gitlab_replicator
   # Enter password: <your_replication_password_here>
   # Confirm password: <your_replication_password_here>
   # 950233c0dfc2f39c64cf30457c3b7f1e
   ```

   Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Fill with the hash generated by `gitlab-ctl pg-password-md5 gitlab_replicator`
   postgresql['sql_replication_password'] = '<md5_hash_of_your_replication_password>'
   ```

1. Enregistrez le fichier et reconfigurez GitLab pour modifier le mot de passe de l'utilisateur de réplication dans PostgreSQL :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Redémarrez PostgreSQL pour que le changement de mot de passe de réplication prenne effet :

   ```shell
   sudo gitlab-ctl restart postgresql
   ```

Jusqu'à ce que le mot de passe soit mis à jour sur les sites **secondaire**, le [journal PostgreSQL](../../logs/_index.md#postgresql-logs) sur les sites secondaires signale le message d'erreur suivant :

```console
FATAL:  could not connect to the primary server: FATAL:  password authentication failed for user "gitlab_replicator"
```

Sur tous les sites GitLab Geo **secondaire** :

1. La première étape n'est pas nécessaire d'un point de vue configuration, car le `'sql_replication_password'` haché n'est pas utilisé sur les sites GitLab Geo **secondaire**. Cependant, dans le cas où un site **secondaire** doit être promu au rang de GitLab Geo **principal**, assurez-vous de faire correspondre `'sql_replication_password'` dans la configuration du site **secondaire**.

   Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Fill with the hash generated by `gitlab-ctl pg-password-md5 gitlab_replicator` on the Geo primary
   postgresql['sql_replication_password'] = '<md5_hash_of_your_replication_password>'
   ```

1. Lors de la configuration initiale de la réplication, la commande `gitlab-ctl replicate-geo-database` écrit le mot de passe en texte clair du compte utilisateur de réplication dans deux emplacements :

   - `gitlab-geo.conf` :  Utilisé par le processus de réplication PostgreSQL, écrit dans le répertoire de données PostgreSQL, par défaut dans `/var/opt/gitlab/postgresql/data/gitlab-geo.conf`.
   - `.pgpass` :  Utilisé par l'utilisateur `gitlab-psql`, situé par défaut dans `/var/opt/gitlab/postgresql/.pgpass`.

   Mettez à jour le mot de passe en texte clair dans ces deux fichiers, puis redémarrez PostgreSQL :

   ```shell
   sudo gitlab-ctl restart postgresql
   ```

## Réplication de base de données multi-nœuds {#multi-node-database-replication}

### Migration d'un nœud PostgreSQL unique vers Patroni {#migrating-a-single-postgresql-node-to-patroni}

Avant l'introduction de Patroni, Geo ne prenait pas en charge les installations de packages Linux pour les configurations HA sur le site **secondaire**.

Avec Patroni, cette prise en charge est désormais possible. Pour migrer le PostgreSQL existant vers Patroni :

1. Assurez-vous d'avoir un cluster Consul configuré sur le site secondaire (de la même manière que vous l'avez configuré sur le site **principal**).
1. [Configurez un slot de réplication permanent](#step-1-configure-patroni-permanent-replication-slot-on-the-primary-site).
1. [Configurez l'équilibreur de charge interne](#step-2-configure-the-internal-load-balancer-on-the-primary-site).
1. [Configurez un nœud PgBouncer](#step-3-configure-pgbouncer-nodes-on-the-secondary-site)
1. [Configurez un cluster de secours (Standby Cluster)](#step-4-configure-a-standby-cluster-on-the-secondary-site) sur cette machine à nœud unique.

Vous vous retrouvez avec un **Standby Cluster** à nœud unique. Cela vous permet d'ajouter des nœuds Patroni supplémentaires en suivant les mêmes instructions répertoriées précédemment.

### Prise en charge de Patroni {#patroni-support}

Patroni est la solution officielle de gestion de réplication pour Geo. Patroni peut être utilisé pour créer un cluster hautement disponible sur le site Geo **principal** et sur un site Geo **secondaire**. L'utilisation de Patroni sur un site **secondaire** est facultative et vous n'avez pas à utiliser le même nombre de nœuds sur chaque site Geo.

Pour les instructions sur la configuration de Patroni sur le site principal, consultez la [documentation correspondante](../../postgresql/replication_and_failover.md#patroni).

#### Configuration du cluster Patroni pour un site Geo secondaire {#configuring-patroni-cluster-for-a-geo-secondary-site}

Sur un site Geo secondaire, la base de données PostgreSQL principale est un réplica en lecture seule de la base de données PostgreSQL du site principal.

Une configuration prête pour la production et sécurisée nécessite au minimum :

- 3 nœuds Consul _(sites principal et secondaires)_
- 2 nœuds Patroni _(sites principal et secondaires)_
- 1 nœud PgBouncer _(sites principal et secondaires)_
- 1 équilibreur de charge interne _(site principal uniquement)_

L'équilibreur de charge interne fournit un point de terminaison unique pour se connecter au leader du cluster Patroni chaque fois qu'un nouveau leader est élu. L'équilibreur de charge est nécessaire pour activer la réplication en cascade depuis les sites secondaires.

Assurez-vous d'utiliser des [identifiants par mot de passe](../../postgresql/replication_and_failover.md#database-authorization-for-patroni) et d'autres bonnes pratiques de base de données.

##### Étape 1. Configurer le slot de réplication permanent Patroni sur le site principal {#step-1-configure-patroni-permanent-replication-slot-on-the-primary-site}

Configurez un slot de réplication persistant sur la base de données principale pour assurer la réplication continue des données de la base de données principale vers le cluster Patroni sur le nœud secondaire.

{{< tabs >}}

{{< tab title="Principal avec cluster Patroni" >}}

Pour configurer la réplication de base de données avec Patroni sur un site secondaire, vous devez configurer un slot de réplication permanent sur le cluster Patroni du site principal et vous assurer que l'authentification par mot de passe est utilisée.

Sur chaque nœud exécutant une instance Patroni sur le site principal **starting on the Patroni Leader instance** :

1. Connectez-vous en SSH à votre instance Patroni et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. [Désactivez les mises à niveau automatiques de PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades) pour éviter des interruptions non planifiées lors de la mise à niveau de GitLab. Tenez compte des [mises en garde connues lors de la mise à niveau de PostgreSQL avec Geo](https://docs.gitlab.com/omnibus/settings/database/#caveats-when-upgrading-postgresql-with-geo). En particulier pour les environnements plus importants, les mises à niveau de PostgreSQL doivent être planifiées et exécutées consciencieusement. Par conséquent et à l'avenir, assurez-vous que les mises à niveau de PostgreSQL font partie des activités de maintenance régulières.
1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez ce qui suit. Assurez-vous que chaque type de mot de passe a des [valeurs correspondantes](#database-password-consistency-requirements) sur tous les sites Geo.

   ```ruby
   roles(['patroni_role'])

   consul['services'] = %w(postgresql)
   consul['configuration'] = {
     retry_join: %w[CONSUL_PRIMARY1_IP CONSUL_PRIMARY2_IP CONSUL_PRIMARY3_IP]
   }

   # You need one entry for each secondary, with a unique name following PostgreSQL slot_name constraints:
   #
   # Configuration syntax is: 'unique_slotname' => { 'type' => 'physical' },
   # We don't support setting a permanent replication slot for logical replication type
   patroni['replication_slots'] = {
     'geo_secondary' => { 'type' => 'physical' }
   }

   patroni['use_pg_rewind'] = true
   patroni['postgresql']['max_wal_senders'] = 8 # Use double of the amount of patroni/reserved slots (3 patronis + 1 reserved slot for a Geo secondary).
   patroni['postgresql']['max_replication_slots'] = 8 # Use double of the amount of patroni/reserved slots (3 patronis + 1 reserved slot for a Geo secondary).
   patroni['username'] = 'PATRONI_API_USERNAME'
   patroni['password'] = 'PATRONI_API_PASSWORD'
   patroni['replication_password'] = 'PLAIN_TEXT_POSTGRESQL_REPLICATION_PASSWORD'

   # Add all patroni nodes to the allowlist
   patroni['allowlist'] = %w[
     127.0.0.1/32
     PATRONI_PRIMARY1_IP/32 PATRONI_PRIMARY2_IP/32 PATRONI_PRIMARY3_IP/32
     PATRONI_SECONDARY1_IP/32 PATRONI_SECONDARY2_IP/32 PATRONI_SECONDARY3_IP/32
   ]

   # We list all secondary instances as they can all become a Standby Leader
   postgresql['md5_auth_cidr_addresses'] = %w[
     PATRONI_PRIMARY1_IP/32 PATRONI_PRIMARY2_IP/32 PATRONI_PRIMARY3_IP/32 PATRONI_PRIMARY_PGBOUNCER/32
     PATRONI_SECONDARY1_IP/32 PATRONI_SECONDARY2_IP/32 PATRONI_SECONDARY3_IP/32 PATRONI_SECONDARY_PGBOUNCER/32
   ]

   postgresql['pgbouncer_user_password'] = 'PGBOUNCER_PASSWORD_HASH'
   postgresql['sql_replication_password'] = 'POSTGRESQL_REPLICATION_PASSWORD_HASH'
   postgresql['sql_user_password'] = 'POSTGRESQL_PASSWORD_HASH'
   postgresql['listen_address'] = '0.0.0.0' # You can use a public or VPC address here instead
   ```

1. Reconfigurez GitLab pour que les modifications prennent effet :

   ```shell
   gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Principal avec instance PostgreSQL unique" >}}

1. Connectez-vous en SSH à votre instance à nœud unique et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. [Désactivez les mises à niveau automatiques de PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades) pour éviter des interruptions non planifiées lors de la mise à niveau de GitLab. Tenez compte des [mises en garde connues lors de la mise à niveau de PostgreSQL avec Geo](https://docs.gitlab.com/omnibus/settings/database/#caveats-when-upgrading-postgresql-with-geo). En particulier pour les environnements plus importants, les mises à niveau de PostgreSQL doivent être planifiées et exécutées consciencieusement. Par conséquent et à l'avenir, assurez-vous que les mises à niveau de PostgreSQL font partie des activités de maintenance régulières.
1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez ce qui suit :

   ```ruby
   postgresql['max_wal_senders'] = 2 # Use 2 per secondary site (1 temporary slot for initial Patroni replication + 1 reserved slot for a Geo secondary)
   postgresql['max_replication_slots'] = 2 # Use 2 per secondary site (1 temporary slot for initial Patroni replication + 1 reserved slot for a Geo secondary)
   ```

1. Reconfigurez GitLab :

   ```shell
   gitlab-ctl reconfigure
   ```

1. Redémarrez le service PostgreSQL pour que les nouvelles modifications prennent effet :

   ```shell
   gitlab-ctl restart postgresql
   ```

1. Démarrez une console de base de données

   ```shell
   gitlab-psql
   ```

1. Configurez le slot de réplication permanent sur le site principal

   ```sql
   select pg_create_physical_replication_slot('geo_secondary')
   ```

1. Facultatif. Si le site principal n'a pas de PgBouncer, mais que le site secondaire en a un :

   Configurez l'utilisateur `pgbouncer` sur le site principal et ajoutez la fonction `pg_shadow_lookup` nécessaire pour PgBouncer incluse avec le package Linux. PgBouncer sur le serveur secondaire devrait toujours être en mesure de se connecter aux nœuds PostgreSQL sur le site secondaire.

   ```sql
   --- Create a new user 'pgbouncer'
   CREATE USER pgbouncer;

   --- Set/change a password and grants replication privilege
   ALTER USER pgbouncer WITH REPLICATION ENCRYPTED PASSWORD '<pgbouncer_password_from_secondary>';

   CREATE OR REPLACE FUNCTION public.pg_shadow_lookup(in i_username text, out username text, out password text) RETURNS record AS $$
   BEGIN
       SELECT usename, passwd FROM pg_catalog.pg_shadow
       WHERE usename = i_username INTO username, password;
       RETURN;
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER;

   REVOKE ALL ON FUNCTION public.pg_shadow_lookup(text) FROM public, pgbouncer;
   GRANT EXECUTE ON FUNCTION public.pg_shadow_lookup(text) TO pgbouncer;
   ```

{{< /tab >}}

{{< /tabs >}}

##### Étape 2. Configurer l'équilibreur de charge interne sur le site principal {#step-2-configure-the-internal-load-balancer-on-the-primary-site}

Pour éviter de reconfigurer le Standby Leader sur le site secondaire chaque fois qu'un nouveau Leader est élu sur le site principal, vous devriez configurer un équilibreur de charge interne TCP. Cet équilibreur de charge fournit un point de terminaison unique pour se connecter au Leader du cluster Patroni.

Les packages Linux n'incluent pas d'équilibreur de charge. Voici comment vous pourriez le faire avec [HAProxy](https://www.haproxy.org/).

Les adresses IP et noms suivants sont utilisés à titre d'exemple :

- `10.6.0.21` :  Patroni 1 (`patroni1.internal`)
- `10.6.0.22` :  Patroni 2 (`patroni2.internal`)
- `10.6.0.23` :  Patroni 3 (`patroni3.internal`)

```plaintext
global
    log /dev/log local0
    log localhost local1 notice
    log stdout format raw local0

defaults
    log global
    default-server inter 3s fall 3 rise 2 on-marked-down shutdown-sessions

frontend internal-postgresql-tcp-in
    bind *:5432
    mode tcp
    option tcplog

    default_backend postgresql

backend postgresql
    mode tcp
    option httpchk
    http-check expect status 200

    server patroni1.internal 10.6.0.21:5432 maxconn 100 check port 8008
    server patroni2.internal 10.6.0.22:5432 maxconn 100 check port 8008
    server patroni3.internal 10.6.0.23:5432 maxconn 100 check port 8008
```

Pour plus de conseils, consultez la documentation de votre équilibreur de charge préféré.

##### Étape 3. Configurer les nœuds PgBouncer sur le site secondaire {#step-3-configure-pgbouncer-nodes-on-the-secondary-site}

Une configuration prête pour la production et hautement disponible nécessite au moins trois nœuds Consul et un minimum d'un nœud PgBouncer. Cependant, il est recommandé d'avoir un nœud PgBouncer par nœud de base de données. Un équilibreur de charge interne (TCP) est requis lorsqu'il y a plus d'un nœud de service PgBouncer. L'équilibreur de charge interne fournit un point de terminaison unique pour se connecter au cluster PgBouncer. Pour plus d'informations, consultez [la documentation correspondante](../../postgresql/replication_and_failover.md).

Sur chaque nœud exécutant une instance PgBouncer sur le site **secondaire** :

1. Connectez-vous en SSH à votre nœud PgBouncer et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez ce qui suit :

   ```ruby
   # Disable all components except Pgbouncer and Consul agent
   roles(['pgbouncer_role'])

   # PgBouncer configuration
   pgbouncer['admin_users'] = %w(pgbouncer gitlab-consul)
   pgbouncer['users'] = {
   'gitlab-consul': {
      # Generate it with: `gitlab-ctl pg-password-md5 gitlab-consul`
      password: 'GITLAB_CONSUL_PASSWORD_HASH'
    },
     'pgbouncer': {
       # Generate it with: `gitlab-ctl pg-password-md5 pgbouncer`
       password: 'PGBOUNCER_PASSWORD_HASH'
     }
   }

   # Consul configuration
   consul['watchers'] = %w(postgresql)
   consul['configuration'] = {
     retry_join: %w[CONSUL_SECONDARY1_IP CONSUL_SECONDARY2_IP CONSUL_SECONDARY3_IP]
   }
   consul['monitoring_service_discovery'] =  true
   ```

1. Reconfigurez GitLab pour que les modifications prennent effet :

   ```shell
   gitlab-ctl reconfigure
   ```

1. Créez un fichier `.pgpass` pour que Consul puisse recharger PgBouncer. Saisissez `PLAIN_TEXT_PGBOUNCER_PASSWORD` deux fois lorsque vous y êtes invité :

   ```shell
   gitlab-ctl write-pgpass --host 127.0.0.1 --database pgbouncer --user pgbouncer --hostuser gitlab-consul
   ```

1. Rechargez le service PgBouncer :

   ```shell
   gitlab-ctl hup pgbouncer
   ```

##### Étape 4. Configurer un cluster de secours (Standby cluster) sur le site secondaire {#step-4-configure-a-standby-cluster-on-the-secondary-site}

> [!note]
> Si vous convertissez un site secondaire avec une instance PostgreSQL unique en cluster Patroni, vous devez commencer sur l'instance PostgreSQL. Elle devient l'instance Patroni Standby Leader, puis vous pouvez basculer vers un autre réplica si nécessaire.

Pour chaque nœud exécutant une instance Patroni sur le site secondaire :

1. Connectez-vous en SSH à votre nœud Patroni et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. [Désactivez les mises à niveau automatiques de PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades) pour éviter des interruptions non planifiées lors de la mise à niveau de GitLab. Tenez compte des [mises en garde connues lors de la mise à niveau de PostgreSQL avec Geo](https://docs.gitlab.com/omnibus/settings/database/#caveats-when-upgrading-postgresql-with-geo). En particulier pour les environnements plus importants, les mises à niveau de PostgreSQL doivent être planifiées et exécutées consciencieusement. Par conséquent et à l'avenir, assurez-vous que les mises à niveau de PostgreSQL font partie des activités de maintenance régulières.
1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez ce qui suit :

   > [!warning]
   > Chaque type de mot de passe doit avoir des [valeurs correspondantes](#database-password-consistency-requirements) sur tous les sites Geo.

   ```ruby
   roles(['consul_role', 'patroni_role'])

   consul['enable'] = true
   consul['configuration'] = {
     retry_join: %w[CONSUL_SECONDARY1_IP CONSUL_SECONDARY2_IP CONSUL_SECONDARY3_IP]
   }
   consul['services'] = %w(postgresql)

   postgresql['md5_auth_cidr_addresses'] = [
     'PATRONI_SECONDARY1_IP/32', 'PATRONI_SECONDARY2_IP/32', 'PATRONI_SECONDARY3_IP/32', 'PATRONI_SECONDARY_PGBOUNCER/32',
     # Any other instance that needs access to the database as per documentation
   ]


   # Add patroni nodes to the allowlist
   patroni['allowlist'] = %w[
     127.0.0.1/32
     PATRONI_SECONDARY1_IP/32 PATRONI_SECONDARY2_IP/32 PATRONI_SECONDARY3_IP/32
   ]

   patroni['standby_cluster']['enable'] = true
   patroni['standby_cluster']['host'] = 'INTERNAL_LOAD_BALANCER_PRIMARY_IP'
   patroni['standby_cluster']['port'] = INTERNAL_LOAD_BALANCER_PRIMARY_PORT
   patroni['standby_cluster']['primary_slot_name'] = 'geo_secondary' # Or the unique replication slot name you setup before
   patroni['username'] = 'PATRONI_API_USERNAME'
   patroni['password'] = 'PATRONI_API_PASSWORD'
   patroni['replication_password'] = 'PLAIN_TEXT_POSTGRESQL_REPLICATION_PASSWORD'
   patroni['use_pg_rewind'] = true
   patroni['postgresql']['max_wal_senders'] = 5 # A minimum of three for one replica, plus two for each additional replica
   patroni['postgresql']['max_replication_slots'] = 5 # A minimum of three for one replica, plus two for each additional replica

   postgresql['pgbouncer_user_password'] = 'PGBOUNCER_PASSWORD_HASH'
   postgresql['sql_replication_password'] = 'POSTGRESQL_REPLICATION_PASSWORD_HASH'
   postgresql['sql_user_password'] = 'POSTGRESQL_PASSWORD_HASH'
   postgresql['listen_address'] = '0.0.0.0' # You can use a public or VPC address here instead

   # GitLab Rails configuration is required for `gitlab-ctl geo-replication-pause`
   gitlab_rails['db_password'] = 'POSTGRESQL_PASSWORD'
   gitlab_rails['enable'] = true
   gitlab_rails['auto_migrate'] = false
   ```

   Lors de la configuration de `patroni['standby_cluster']['host']` et `patroni['standby_cluster']['port']` :
   - `INTERNAL_LOAD_BALANCER_PRIMARY_IP` doit pointer vers l'IP de l'équilibreur de charge interne principal.
   - `INTERNAL_LOAD_BALANCER_PRIMARY_PORT` doit pointer vers le port frontend [configuré pour le leader du cluster Patroni principal](#step-2-configure-the-internal-load-balancer-on-the-primary-site). **Do not** le port frontend PgBouncer.

1. Reconfigurez GitLab pour que les modifications prennent effet. Cette étape est nécessaire pour initialiser les utilisateurs et les paramètres PostgreSQL.

   - S'il s'agit d'une nouvelle installation de Patroni :

     ```shell
     gitlab-ctl reconfigure
     ```

   - Si vous configurez un cluster de secours Patroni sur un site qui avait auparavant un cluster Patroni fonctionnel :

     1. Arrêtez Patroni sur tous les nœuds gérés par Patroni, y compris les réplicas en cascade :

        ```shell
        gitlab-ctl stop patroni
        ```

     1. Exécutez ce qui suit sur le nœud Patroni leader pour recréer le cluster de secours :

        ```shell
        rm -rf /var/opt/gitlab/postgresql/data
        /opt/gitlab/embedded/bin/patronictl -c /var/opt/gitlab/patroni/patroni.yaml remove postgresql-ha
        gitlab-ctl reconfigure
        ```

     1. Démarrez Patroni sur le nœud Patroni leader pour lancer le processus de réplication depuis la base de données principale :

        ```shell
        gitlab-ctl start patroni
        ```

     1. Vérifiez l'état du cluster Patroni :

        ```shell
        gitlab-ctl patroni members
        ```

        Vérifiez que :

        - Le nœud Patroni actuel apparaît dans la sortie.
        - Le rôle est `Standby Leader`. Le rôle peut initialement afficher `Replica`.
        - L'état est `Running`. L'état peut initialement afficher `Creating replica`.

        Attendez que le rôle du nœud se stabilise en tant que `Standby Leader` et que l'état soit `Running`. Cela peut prendre quelques minutes.

     1. Lorsque le nœud Patroni leader est le `Standby Leader` et est en état `Running`, démarrez Patroni sur les autres nœuds Patroni du cluster de secours :

        ```shell
        gitlab-ctl start patroni
        ```

        Les autres nœuds Patroni devraient rejoindre le nouveau cluster de secours en tant que réplicas et commencer à se répliquer automatiquement depuis le nœud Patroni leader.

1. Vérifiez l'état du cluster :

   ```shell
   gitlab-ctl patroni members
   ```

   Assurez-vous que tous les nœuds Patroni sont listés dans l'état `Running`. Il devrait y avoir un nœud `Standby Leader` et plusieurs nœuds `Replica`.

### Migration d'un nœud de base de données de suivi unique vers Patroni {#migrating-a-single-tracking-database-node-to-patroni}

Avant l'introduction de Patroni, Geo ne prenait pas en charge les installations de packages Linux pour les configurations HA sur le site secondaire.

Avec Patroni, il est désormais possible de prendre en charge les configurations HA. Cependant, certaines restrictions dans Patroni empêchent la gestion de deux clusters différents sur la même machine. Vous devriez configurer un nouveau cluster Patroni pour la base de données de suivi en suivant les mêmes instructions décrivant comment [configurer un cluster Patroni pour un site Geo secondaire](#configuring-patroni-cluster-for-a-geo-secondary-site).

Les nœuds secondaires renseignent la nouvelle base de données de suivi et aucune synchronisation de données n'est requise.

### Configuration du cluster Patroni pour la base de données PostgreSQL de suivi {#configuring-patroni-cluster-for-the-tracking-postgresql-database}

Les sites Geo **Secondaire** utilisent une installation PostgreSQL séparée comme base de données de suivi pour suivre l'état de la réplication et récupérer automatiquement des problèmes de réplication potentiels.

Si vous souhaitez exécuter la base de données de suivi Geo sur un seul nœud, consultez [Configurer la base de données de suivi Geo sur le site Geo secondaire](../replication/multiple_servers.md#step-2-configure-the-geo-tracking-database-on-the-geo-secondary-site).

Le package Linux ne prend pas en charge l'exécution de la base de données de suivi Geo dans une configuration hautement disponible. En particulier, le basculement ne fonctionne pas correctement. Consultez le [ticket de demande de fonctionnalité](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/7292).

Si vous souhaitez exécuter la base de données de suivi Geo dans une configuration hautement disponible, vous pouvez connecter le site secondaire à une base de données PostgreSQL externe, telle qu'une base de données gérée dans le cloud, ou un cluster [Patroni](https://patroni.readthedocs.io/en/latest/) configuré manuellement (non géré par le package Linux GitLab). Suivez les instructions de [Geo avec des instances PostgreSQL externes](external_database.md#configure-the-tracking-database).

## Dépannage {#troubleshooting}

Consultez le [document de dépannage](../replication/troubleshooting/_index.md).
