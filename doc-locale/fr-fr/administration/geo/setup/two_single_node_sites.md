---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Configurez la réplication GitLab Geo entre deux sites à nœud unique pour la reprise après sinistre, avec prise en charge des installations de package Linux et Docker."
title: Configurer Geo pour deux sites à nœud unique
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Le guide suivant fournit des instructions concises sur la façon de déployer GitLab Geo pour une installation à deux sites à nœud unique utilisant deux instances de package Linux sans services externes configurés. Ce guide s'applique également aux installations basées sur [Docker](../../../install/docker/_index.md).

Prérequis :

- Vous disposez d'au moins deux sites GitLab fonctionnant de manière indépendante. Pour créer les sites, consultez la [documentation des architectures de référence GitLab](../../reference_architectures/_index.md).
  - Un site GitLab sert de **Geo primary site**. Vous pouvez utiliser différentes tailles d'architecture de référence pour chaque site Geo. Si vous disposez déjà d'une instance GitLab fonctionnelle, vous pouvez l'utiliser comme site principal.
  - Le second site GitLab sert de **Geo secondary site**. Geo prend en charge plusieurs sites secondaires.
- Le site Geo principal possède au moins une licence [GitLab Premium](https://about.gitlab.com/pricing/). Vous n'avez besoin que d'une seule licence pour tous les sites.
- Confirmez que tous les sites satisfont aux [conditions requises pour exécuter Geo](../_index.md#requirements-for-running-geo).

## Configurer Geo pour le package Linux (Omnibus) {#set-up-geo-for-linux-package-omnibus}

Prérequis :

- Vous utilisez PostgreSQL 12 ou une version ultérieure, qui inclut l'[outil `pg_basebackup`](https://www.postgresql.org/docs/16/app-pgbasebackup.html).

### Configurer le site principal {#configure-the-primary-site}

> [!note]
> Pour les installations basées sur Docker :
>
> Appliquez les paramètres mentionnés ci-dessous directement au fichier `/etc/gitlab/gitlab.rb` du conteneur GitLab, ou ajoutez-les à la variable d'environnement `GITLAB_OMNIBUS_CONFIG` dans son fichier [Docker Compose](../../../install/docker/installation.md#install-gitlab-by-using-docker-compose).
>
> Lors de l'utilisation de [Docker Compose](../../../install/docker/installation.md#install-gitlab-by-using-docker-compose), utilisez `docker-compose -f <docker-compose-file-name>.yml up` au lieu de `gitlab-ctl reconfigure` pour appliquer les modifications de configuration.

1. Connectez-vous en SSH à votre site GitLab principal et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. [Désactivez les mises à niveau automatiques de PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades) pour éviter des interruptions involontaires lors de la mise à niveau de GitLab. Prenez connaissance des [mises en garde connues lors de la mise à niveau de PostgreSQL avec Geo](https://docs.gitlab.com/omnibus/settings/database/#caveats-when-upgrading-postgresql-with-geo). En particulier pour les environnements plus importants, les mises à niveau de PostgreSQL doivent être planifiées et exécutées consciencieusement. Par conséquent et à l'avenir, assurez-vous que les mises à niveau de PostgreSQL font partie des activités de maintenance régulières.
1. Ajoutez un nom de site Geo unique à `/etc/gitlab/gitlab.rb` :

   ```ruby
   ##
   ## The unique identifier for the Geo site. See
   ## https://docs.gitlab.com/administration/geo_sites/#common-settings
   ##
   gitlab_rails['geo_node_name'] = '<site_name_here>'
   ```

1. Pour appliquer la modification, reconfigurez le site principal :

   ```shell
   gitlab-ctl reconfigure
   ```

1. Définissez le site comme votre site Geo principal :

   ```shell
   gitlab-ctl set-geo-primary-node
   ```

   Cette commande utilise l'`external_url` défini dans `/etc/gitlab/gitlab.rb`.

1. Copiez l'exemple de configuration depuis [Site principal complet](#complete-primary-site).
1. Créez un mot de passe pour l'utilisateur de base de données `gitlab` et mettez à jour Rails pour utiliser le nouveau mot de passe.

   > [!note]
   > Les valeurs configurées pour les paramètres `gitlab_rails['db_password']` et `postgresql['sql_user_password']` doivent correspondre. Cependant, seule la valeur `postgresql['sql_user_password']` doit être le mot de passe chiffré MD5. Les modifications apportées à ce sujet sont discutées dans [Rethink how we handle PostgreSQL passwords in cookbooks](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5713).

   1. Générez un hash MD5 du mot de passe souhaité :

      ```shell
      gitlab-ctl pg-password-md5 gitlab
      # Enter password: <your_db_password_here>
      # Confirm password: <your_db_password_here>
      # fca0b89a972d69f00eb3ec98a5838484
      ```

   1. Modifiez `/etc/gitlab/gitlab.rb` :

      ```ruby
      # Fill with the hash generated by `gitlab-ctl pg-password-md5 gitlab`
      postgresql['sql_user_password'] = '<md5_hash_of_your_db_password>'

      # Every node that runs Puma or Sidekiq needs to have the database
      # password specified as below. If you have a high-availability setup, this
      # must be present in all application nodes.
      gitlab_rails['db_password'] = '<your_db_password_here>'
      ```

1. Définissez un mot de passe pour l'[utilisateur de réplication](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION) de la base de données. Utilisez le nom d'utilisateur défini dans `/etc/gitlab/gitlab.rb` sous le paramètre `postgresql['sql_replication_user']`. La valeur par défaut est `gitlab_replicator`.

   1. Générez un hash MD5 du mot de passe souhaité :

      ```shell
      gitlab-ctl pg-password-md5 gitlab_replicator

      # Enter password: <your_replication_password_here>
      # Confirm password: <your_replication_password_here>
      # 950233c0dfc2f39c64cf30457c3b7f1e
      ```

   1. Modifiez `/etc/gitlab/gitlab.rb` :

      ```ruby
      # Fill with the hash generated by `gitlab-ctl pg-password-md5 gitlab_replicator`
      postgresql['sql_replication_password'] = '<md5_hash_of_your_replication_password>'
      ```

   1. Facultatif. Si vous utilisez une base de données externe non gérée par le package Linux, vous devez créer l'utilisateur `gitlab_replicator` et définir manuellement un mot de passe pour cet utilisateur :

      ```sql
      --- Create a new user 'replicator'
      CREATE USER gitlab_replicator;

      --- Set/change a password and grants replication privilege
      ALTER USER gitlab_replicator WITH REPLICATION ENCRYPTED PASSWORD '<replication_password>';
      ```

1. Dans `/etc/gitlab/gitlab.rb`, définissez le rôle sur [`geo_primary_role`](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles) :

   ```ruby
   ## Geo Primary role
   roles(['geo_primary_role'])
   ```

1. Configurez PostgreSQL pour écouter sur les interfaces réseau :

   1. Pour rechercher l'adresse d'un site Geo, connectez-vous en SSH au site Geo et exécutez :

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
      | `postgresql['listen_address']`          | Adresse publique du site principal ou adresse privée VPC.                     |
      | `postgresql['md5_auth_cidr_addresses']` | Adresses publiques des sites principal et secondaire ou adresses privées VPC. |

      Si vous utilisez Google Cloud Platform, SoftLayer, ou tout autre fournisseur proposant un cloud privé virtuel (VPC), vous pouvez utiliser les adresses privées des sites principal et secondaire (correspondant à l'« adresse interne » pour Google Cloud Platform) pour `postgresql['md5_auth_cidr_addresses']` et `postgresql['listen_address']`.

      > [!note]
      > Si vous devez utiliser `0.0.0.0` ou `*` comme `listen_address`, vous devez également ajouter `127.0.0.1/32` au paramètre `postgresql['md5_auth_cidr_addresses']`, pour permettre à Rails de se connecter via `127.0.0.1`. Pour plus d'informations, consultez le [ticket 5258](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5258).

      En fonction de votre configuration réseau, les adresses suggérées peuvent être incorrectes. Si vos sites principal et secondaire se connectent via un réseau local, ou un réseau virtuel reliant des zones de disponibilité comme [Amazon VPC](https://aws.amazon.com/vpc/) ou [Google VPC](https://cloud.google.com/vpc/), vous devez utiliser l'adresse privée du site secondaire pour `postgresql['md5_auth_cidr_addresses']`.

   1. Ajoutez les lignes suivantes à `/etc/gitlab/gitlab.rb`. Veillez à remplacer les adresses IP par des adresses appropriées à votre configuration réseau :

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
      ```

1. Désactivez temporairement les migrations automatiques de base de données jusqu'à ce que PostgreSQL soit redémarré et à l'écoute sur l'adresse privée. Dans `/etc/gitlab/gitlab.rb`, définissez `gitlab_rails['auto_migrate']` sur false :

   ```ruby
   ## Disable automatic database migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. Pour appliquer ces modifications, reconfigurez GitLab et redémarrez PostgreSQL :

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart postgresql
   ```

1. Pour réactiver les migrations, modifiez `/etc/gitlab/gitlab.rb` et changez `gitlab_rails['auto_migrate']` en `true` :

   ```ruby
   gitlab_rails['auto_migrate'] = true
   ```

   Enregistrez le fichier et reconfigurez GitLab :

   ```shell
   gitlab-ctl reconfigure
   ```

   Le serveur PostgreSQL est configuré pour accepter les connexions distantes.

1. Exécutez `netstat -plnt | grep 5432` pour vous assurer que PostgreSQL écoute sur le port `5432` à l'adresse privée du site principal.
1. Un certificat a été automatiquement généré lors de la reconfiguration de GitLab. Le certificat est utilisé automatiquement pour protéger votre trafic PostgreSQL contre les écoutes indiscrètes. Pour vous protéger contre les attaquants actifs (« man-in-the-middle »), copiez le certificat sur le site secondaire :

   1. Faites une copie de `server.crt` sur le site principal :

      ```shell
      cat ~gitlab-psql/data/server.crt
      ```

   1. Enregistrez la sortie pour la configuration du site secondaire. Le certificat n'est pas une donnée sensible.

   Le certificat est créé avec un nom commun générique `PostgreSQL`. Pour éviter les erreurs de non-concordance de nom d'hôte, vous devez utiliser le mode `verify-ca` lors de la réplication de la base de données.

### Configurer le serveur secondaire {#configure-the-secondary-server}

1. Connectez-vous en SSH à votre site GitLab secondaire et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. [Désactivez les mises à niveau automatiques de PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#opt-out-of-automatic-postgresql-upgrades) pour éviter des interruptions involontaires lors de la mise à niveau de GitLab. Prenez connaissance des [mises en garde connues lors de la mise à niveau de PostgreSQL avec Geo](https://docs.gitlab.com/omnibus/settings/database/#caveats-when-upgrading-postgresql-with-geo). En particulier pour les environnements plus importants, les mises à niveau de PostgreSQL doivent être planifiées et exécutées consciencieusement. Par conséquent et à l'avenir, assurez-vous que les mises à niveau de PostgreSQL font partie des activités de maintenance régulières.
1. Pour éviter l'exécution de commandes avant la configuration du site, arrêtez le serveur d'application et Sidekiq :

   ```shell
   gitlab-ctl stop puma
   gitlab-ctl stop sidekiq
   ```

1. [Vérifiez la connectivité TCP](../../raketasks/maintenance.md) au serveur PostgreSQL du site principal :

   ```shell
   gitlab-rake gitlab:tcp_check[<primary_site_ip>,5432]
   ```

   Si cette étape échoue, vous utilisez peut-être une adresse IP incorrecte, ou un pare-feu empêche l'accès au site. Vérifiez l'adresse IP en faisant bien attention à la différence entre les adresses publiques et privées. Si un pare-feu est présent, assurez-vous que le site secondaire est autorisé à se connecter au site principal sur le port 5432.

1. Sur le site secondaire, créez un fichier appelé `server.crt` et ajoutez la copie du certificat que vous avez effectuée lors de la configuration du site principal.

   ```shell
   editor server.crt
   ```

1. Pour configurer la vérification TLS de PostgreSQL sur le site secondaire, installez `server.crt` :

   ```shell
   install \
      -D \
      -o gitlab-psql \
      -g gitlab-psql \
      -m 0400 \
      -T server.crt ~gitlab-psql/.postgresql/root.crt
   ```

   PostgreSQL reconnaît désormais uniquement ce certificat exact lors de la vérification des connexions TLS. Le certificat peut être répliqué par quelqu'un ayant accès à la clé privée, qui n'est présente que sur le site principal.

1. Testez que l'utilisateur `gitlab-psql` peut se connecter à la base de données du site principal. Le nom de package Linux par défaut est `gitlabhq_production` :

    {{< tabs >}}

    {{< tab title="Package Linux" >}}

    ```shell
    sudo \
        -u gitlab-psql /opt/gitlab/embedded/bin/psql \
        --list \
        -U gitlab_replicator \
        -d "dbname=gitlabhq_production sslmode=verify-ca" \
        -W \
        -h <primary_site_ip>
    ```

    {{< /tab >}}

    {{< tab title="Docker" >}}

    ```shell
    docker exec -it <container_name> su - gitlab-psql -c '/opt/gitlab/embedded/bin/psql \
        --list \
        -U gitlab_replicator \
        -d "dbname=gitlabhq_production sslmode=verify-ca" \
        -W \
        -h <primary_site_ip>'
    ```

    {{< /tab >}}

    {{< /tabs >}}

   Lorsque vous y êtes invité, saisissez le mot de passe en clair que vous avez défini pour l'utilisateur `gitlab_replicator`. Si tout s'est déroulé correctement, vous devriez voir la liste des bases de données du site principal.

1. Modifiez `/etc/gitlab/gitlab.rb` et définissez le rôle sur `geo_secondary_role` :

   ```ruby
   ##
   ## Geo Secondary role
   ## - configure dependent flags automatically to enable Geo
   ##
   roles(['geo_secondary_role'])
   ```

   Pour plus d'informations, consultez [les rôles Geo](https://docs.gitlab.com/omnibus/roles/#gitlab-geo-roles).

1. Pour configurer PostgreSQL, modifiez `/etc/gitlab/gitlab.rb` et ajoutez les éléments suivants :

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

   Veillez à remplacer les adresses IP par des adresses appropriées à votre configuration réseau.

1. Copiez l'exemple de configuration depuis [Site secondaire complet](#complete-secondary-site).
1. Pour appliquer les modifications, enregistrez le fichier et reconfigurez GitLab :

   ```shell
   gitlab-ctl reconfigure
   ```

1. Pour appliquer le changement d'adresse IP, redémarrez PostgreSQL :

   ```shell
   gitlab-ctl restart postgresql
   ```

### Répliquer la base de données {#replicate-the-database}

Connectez la base de données du site secondaire à la base de données du site principal. Vous pouvez utiliser le script ci-dessous pour répliquer la base de données et créer les fichiers nécessaires à la réplication en continu.

Le script utilise les répertoires par défaut du package Linux. Si vous avez modifié les valeurs par défaut, remplacez les noms de répertoires et de chemins dans le script ci-dessous par vos propres noms.

> [!warning]
> Exécutez le script de réplication uniquement sur le site secondaire. Le script supprime toutes les données PostgreSQL avant d'exécuter `pg_basebackup`, ce qui peut entraîner une perte de données.

Pour répliquer la base de données :

1. Connectez-vous en SSH à votre site GitLab secondaire et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Choisissez un [nom compatible avec les bases de données](https://www.postgresql.org/docs/16/warm-standby.html#STREAMING-REPLICATION-SLOTS-MANIPULATION) pour votre site secondaire à utiliser comme nom d'emplacement de réplication. Par exemple, si votre domaine est `secondary.geo.example.com`, utilisez `secondary_example` comme nom d'emplacement.

   Les noms d'emplacements de réplication ne doivent contenir que des lettres minuscules, des chiffres et le caractère de soulignement.

1. Exécutez la commande suivante pour sauvegarder et restaurer la base de données, et commencer la réplication.

   > [!warning]
   > Chaque site Geo secondaire doit avoir son propre nom d'emplacement de réplication unique. L'utilisation du même nom d'emplacement pour deux sites secondaires interrompt la réplication PostgreSQL.

   ```shell
   gitlab-ctl replicate-geo-database \
      --slot-name=<secondary_slot_name> \
      --host=<primary_site_ip> \
      --sslmode=verify-ca
   ```

   Lorsque vous y êtes invité, saisissez le mot de passe en clair que vous avez configuré pour `gitlab_replicator`.

Le processus de réplication est terminé.

## Configurer un nouveau site secondaire {#configure-a-new-secondary-site}

Une fois le processus de réplication initial terminé, procédez à la configuration des éléments suivants sur le site secondaire.

### Recherche rapide des clés SSH autorisées {#fast-lookup-of-authorized-ssh-keys}

Suivez la documentation pour [configurer la recherche rapide des clés SSH autorisées](../../operations/fast_ssh_key_lookup.md).

La recherche rapide est [obligatoire pour Geo](../../operations/fast_ssh_key_lookup.md#fast-lookup-is-required-for-geo).

> [!note]
> L'authentification est gérée par le site principal. Ne configurez pas d'authentification personnalisée pour le site secondaire. Toute modification nécessitant l'accès à la zone **Admin** doit être effectuée sur le site principal, car le site secondaire est une copie en lecture seule.

### Répliquer manuellement les valeurs secrètes de GitLab {#manually-replicate-secret-gitlab-values}

GitLab stocke un certain nombre de valeurs secrètes dans `/etc/gitlab/gitlab-secrets.json`. Ce fichier JSON doit être identique sur chacun des nœuds du site. Vous devez répliquer manuellement le fichier de secrets sur tous vos sites secondaires, bien que le [ticket 3789](https://gitlab.com/gitlab-org/gitlab/-/issues/3789) propose de modifier ce comportement.

1. Connectez-vous en SSH à un nœud Rails de votre site principal et exécutez la commande ci-dessous :

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

1. Copiez `/etc/gitlab/gitlab-secrets.json` depuis le nœud Rails du site principal vers chaque nœud du site secondaire. Vous pouvez également copier-coller le contenu du fichier entre les nœuds :

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

1. Pour appliquer les modifications, reconfigurez chaque nœud Rails, Sidekiq et Gitaly du site secondaire :

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

### Répliquer manuellement les clés d'hôte SSH du site principal {#manually-replicate-the-primary-site-ssh-host-keys}

1. Connectez-vous en SSH à chaque nœud de votre site secondaire et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Sauvegardez toutes les clés d'hôte SSH existantes :

   ```shell
   find /etc/ssh -iname 'ssh_host_*' -exec cp {} {}.backup.`date +%F` \;
   ```

1. Copiez les clés d'hôte OpenSSH depuis le site principal.

   - Si vous pouvez accéder en tant que root à l'un des nœuds du site principal servant le trafic SSH (généralement, les nœuds principaux de l'application GitLab Rails) :

     ```shell
     # Run this from the secondary site, change `<primary_site_fqdn>` for the IP or FQDN of the server
     scp root@<primary_node_fqdn>:/etc/ssh/ssh_host_*_key* /etc/ssh
     ```

   - Si vous n'avez accès que via un utilisateur disposant des privilèges `sudo` :

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

1. Pour vérifier la correspondance des empreintes de clés, exécutez la commande suivante sur les nœuds principal et secondaire de chaque site :

   ```shell
   for file in /etc/ssh/ssh_host_*_key; do ssh-keygen -lf $file; done
   ```

   Vous devriez obtenir une sortie similaire à ce qui suit :

   ```shell
   1024 SHA256:FEZX2jQa2bcsd/fn/uxBzxhKdx4Imc4raXrHwsbtP0M root@serverhostname (DSA)
   256 SHA256:uw98R35Uf+fYEQ/UnJD9Br4NXUFPv7JAUln5uHlgSeY root@serverhostname (ECDSA)
   256 SHA256:sqOUWcraZQKd89y/QQv/iynPTOGQxcOTIXU/LsoPmnM root@serverhostname (ED25519)
   2048 SHA256:qwa+rgir2Oy86QI+PZi/QVR+MSmrdrpsuH7YyKknC+s root@serverhostname (RSA)
   ```

   La sortie doit être identique sur les deux nœuds.

1. Vérifiez que vous disposez des bonnes clés publiques pour les clés privées existantes :

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

1. Pour vérifier que SSH est toujours fonctionnel, ouvrez un nouveau terminal et connectez-vous en SSH à votre serveur GitLab secondaire. Si vous ne pouvez pas vous connecter, assurez-vous d'avoir les permissions correctes.

### Ajouter le site secondaire {#add-the-secondary-site}

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
   gitlab_rails['geo_node_name'] = '<site_name_here>'
   ```

   Enregistrez le nom unique pour les étapes suivantes.

1. Pour appliquer les modifications, reconfigurez chaque nœud Rails et Sidekiq de votre site secondaire.

   ```shell
   gitlab-ctl reconfigure
   ```

1. Accédez à l'instance GitLab du nœud principal :
   1. Dans le coin supérieur droit, sélectionnez **Admin**.
   1. Sélectionnez **Geo** > **Sites**.
   1. Sélectionnez **Ajouter un site**.

      ![Formulaire pour ajouter un nouveau site avec trois champs de saisie : Nom, URL externe et URL interne (facultatif).](img/adding_a_secondary_v15_8.png)

   1. Dans **Nom**, saisissez la valeur de `gitlab_rails['geo_node_name']` dans `/etc/gitlab/gitlab.rb`. Les valeurs doivent correspondre exactement.
   1. Dans **URL externe**, saisissez la valeur de `external_url` dans `/etc/gitlab/gitlab.rb`. Ce n'est pas un problème si l'une des valeurs se termine par `/` et l'autre non. Sinon, les valeurs doivent correspondre exactement.
   1. Facultatif. Dans **URL interne (facultatif)**, saisissez une URL interne pour le site principal.
   1. Facultatif. Sélectionnez les groupes ou les fragments de stockage qui doivent être répliqués par le site secondaire. Pour tout répliquer, laissez le champ vide. Consultez [la synchronisation sélective](../replication/selective_synchronization.md).
   1. Sélectionnez **Sauvegarder les modifications**.
1. Connectez-vous en SSH à chaque nœud Rails et Sidekiq de votre site secondaire et redémarrez les services :

   ```shell
   gitlab-ctl restart
   ```

1. Vérifiez s'il existe des problèmes courants avec votre configuration Geo en exécutant :

   ```shell
   gitlab-rake gitlab:geo:check
   ```

   Si l'un des contrôles échoue, consultez la [documentation de dépannage](../replication/troubleshooting/_index.md).

1. Pour vérifier que le site secondaire est accessible, connectez-vous en SSH à un serveur Rails ou Sidekiq de votre site principal et identifiez-vous en tant que root :

   ```shell
   gitlab-rake gitlab:geo:check
   ```

   Si l'un des contrôles échoue, consultez la [documentation de dépannage](../replication/troubleshooting/_index.md).

Une fois le site secondaire ajouté à la page d'administration Geo et redémarré, il commence automatiquement à répliquer les données manquantes depuis le site principal dans un processus appelé remplissage (backfill).

Pendant ce temps, le site principal commence à notifier chaque site secondaire de tout changement, afin que le site secondaire puisse agir immédiatement sur les notifications.

Assurez-vous que le site secondaire est en cours d'exécution et accessible. Vous pouvez vous connecter au site secondaire avec les mêmes informations d'identification que celles utilisées pour le site principal.

### Ajouter les URL principale et secondaire comme origines ActionCable autorisées {#add-primary-and-secondary-urls-as-allowed-actioncable-origins}

Cette étape permet aux websockets de fonctionner de manière transparente depuis les sites principal et secondaire.

1. Collectez les **external URLs** de vos sites (principal et secondaire). Vous pouvez les trouver dans les pages de sites dans la zone Admin, comme mentionné dans la section ci-dessus.
1. Connectez-vous en SSH à chaque nœud Rails et Sidekiq de votre **primary site** et identifiez-vous en tant que root :

   ```shell
   sudo -i
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` pour ajouter les URL collectées à l'étape 1 au paramètre `action_cable_allowed_origins` :

   ```ruby
   gitlab_rails['action_cable_allowed_origins'] = ['https://secondary.example.com', 'https://primary.example.com']
   ```

1. Pour appliquer les modifications, reconfigurez chaque nœud Rails et Sidekiq et redémarrez le service :

   ```shell
   gitlab-ctl reconfigure
   gitlab-ctl restart
   ```

### Activer l'accès Git via HTTP/HTTPS et SSH {#enable-git-access-over-httphttps-and-ssh}

Geo synchronise les dépôts via HTTP/HTTPS et nécessite donc que cette méthode de clonage soit activée. Elle est activée par défaut. Si vous convertissez un site existant vers Geo, vous devez vérifier que la méthode de clonage est activée.

Sur le site principal :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Contrôles de visibilité et d'accès**.
1. Si vous utilisez Git via SSH :
   1. Assurez-vous que **Protocoles d'accès Git activés** est défini sur **SSH et HTTP(S)**.
   1. Suivez [Recherche rapide des clés SSH autorisées dans la base de données](../../operations/fast_ssh_key_lookup.md) sur les sites principal et secondaire.
1. Si vous n'utilisez pas Git via SSH, définissez **Protocoles d'accès Git activés** sur **Uniquement HTTP(S)**.

### Vérifier le bon fonctionnement du site secondaire {#verify-proper-functioning-of-the-secondary-site}

Vous pouvez vous connecter au site secondaire avec les mêmes informations d'identification que celles utilisées pour le site principal.

Après vous être connecté :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo** > **Sites**.
1. Vérifiez que le site est correctement identifié comme site Geo secondaire et que Geo est activé.

La réplication initiale peut prendre un certain temps. Vous pouvez surveiller le processus de synchronisation sur chaque site Geo depuis le tableau de bord **Sites Geo** du site principal dans votre navigateur.

![Le tableau de bord Sites Geo affichant l'état de synchronisation.](img/geo_dashboard_v14_0.png)

## Exemples de configurations {#example-configurations}

### Site principal complet {#complete-primary-site}

<!-- If you update this configuration example, also update the example in two_single_node_external_services.md -->

Cet exemple de configuration `gitlab.rb` complet est utilisé pour un site Geo principal :

```ruby
# Primary site configuration example

## Geo Primary role
roles(['geo_primary_role'])

## The unique identifier for the Geo site
gitlab_rails['geo_node_name'] = 'headquarters'

## External URL
external_url 'https://gitlab.example.com'

## Database configuration
gitlab_rails['db_password'] = 'your_database_password_here'
postgresql['sql_user_password'] = 'md5_hash_of_your_database_password'
postgresql['sql_replication_password'] = 'md5_hash_of_your_replication_password'

## PostgreSQL network configuration
postgresql['listen_address'] = '10.0.1.10'  # Primary site IP
postgresql['md5_auth_cidr_addresses'] = ['10.0.1.10/32', '10.0.2.10/32']  # Primary and secondary IPs

## Disable automatic migrations (handled centrally, and to avoid unplanned downtime)
gitlab_rails['auto_migrate'] = false

## SSL/TLS configuration
nginx['listen_port'] = 80
nginx['listen_https'] = false
letsencrypt['enable'] = false

## Object Storage configuration (optional)
gitlab_rails['object_store']['enabled'] = true
gitlab_rails['object_store']['connection'] = {
  'provider' => 'AWS',
  'region' => 'us-east-1',
  'aws_access_key_id' => 'your_access_key',
  'aws_secret_access_key' => 'your_secret_key'
}

## Monitoring configuration (optional)
node_exporter['listen_address'] = '0.0.0.0:9100'
gitlab_workhorse['prometheus_listen_addr'] = '0.0.0.0:9229'
gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '10.0.0.0/8']

## Gitaly configuration
gitaly['configuration'] = {
  prometheus_listen_addr: '0.0.0.0:9236',
}

## ActionCable allowed origins
gitlab_rails['action_cable_allowed_origins'] = ['https://secondary.example.com', 'https://primary.example.com']
```

### Site secondaire complet {#complete-secondary-site}

<!-- If you update this configuration example, also update the example in two_single_node_external_services.md -->

Cet exemple de configuration `gitlab.rb` complet est destiné à un site Geo secondaire :

```ruby
# Secondary site configuration example

## Geo Secondary role
roles(['geo_secondary_role'])

## The unique identifier for the Geo site
gitlab_rails['geo_node_name'] = 'location-2'

## External URL (can be the same as primary for unified URL setup)
external_url 'https://gitlab.example.com'

## Database configuration
gitlab_rails['db_password'] = 'your_database_password_here'
postgresql['sql_user_password'] = 'md5_hash_of_your_database_password'
postgresql['sql_replication_password'] = 'md5_hash_of_your_replication_password'

## PostgreSQL network configuration
postgresql['listen_address'] = '10.0.2.10'  # Secondary site IP
postgresql['md5_auth_cidr_addresses'] = ['10.0.2.10/32']

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

## Monitoring configuration (optional)
node_exporter['listen_address'] = '0.0.0.0:9100'
gitlab_workhorse['prometheus_listen_addr'] = '0.0.0.0:9229'
gitlab_rails['monitoring_whitelist'] = ['127.0.0.0/8', '10.0.0.0/8']

## Gitaly configuration
gitaly['configuration'] = {
  prometheus_listen_addr: '0.0.0.0:9236',
}
```

## Sujets connexes {#related-topics}

- [Dépannage de Geo](../replication/troubleshooting/_index.md)
