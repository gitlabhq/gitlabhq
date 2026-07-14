---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer une instance Sidekiq externe
description: Configurer une instance Sidekiq externe.
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Vous pouvez configurer une instance Sidekiq externe en utilisant Sidekiq intégré dans le package GitLab. Sidekiq nécessite une connexion aux instances Redis, PostgreSQL et Gitaly.

## Configurer l'accès TCP pour PostgreSQL, Gitaly et Redis sur l'instance GitLab {#configure-tcp-access-for-postgresql-gitaly-and-redis-on-the-gitlab-instance}

Par défaut, GitLab utilise des sockets UNIX et n'est pas configuré pour communiquer via TCP. Pour modifier cela :

1. [Configurer le serveur PostgreSQL intégré pour écouter sur TCP/IP](https://docs.gitlab.com/omnibus/settings/database/#configure-packaged-postgresql-server-to-listen-on-tcpip) en ajoutant les adresses IP du serveur Sidekiq à `postgresql['md5_auth_cidr_addresses']`
1. [Rendre Redis intégré accessible via TCP](https://docs.gitlab.com/omnibus/settings/redis/#making-the-bundled-redis-reachable-via-tcp)
1. Modifiez le fichier `/etc/gitlab/gitlab.rb` sur votre instance GitLab et ajoutez ce qui suit :

   ```ruby
   ## Gitaly
   gitaly['configuration'] = {
      # ...
      #
      # Make Gitaly accept connections on all network interfaces
      listen_addr: '0.0.0.0:8075',
      auth: {
         ## Set up the Gitaly token as a form of authentication because you are accessing Gitaly over the network
         ## https://docs.gitlab.com/administration/gitaly/configure_gitaly/#about-the-gitaly-token
         token: 'abc123secret',
      },
   }

   gitlab_rails['gitaly_token'] = 'abc123secret'

   # Password to Authenticate Redis
   gitlab_rails['redis_password'] = 'redis-password-goes-here'
   ```

1. Exécutez `reconfigure` :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Redémarrez le serveur `PostgreSQL` :

   ```shell
   sudo gitlab-ctl restart postgresql
   ```

## Configurer une instance Sidekiq {#set-up-sidekiq-instance}

Trouvez [votre architecture de référence](../reference_architectures/_index.md#available-reference-architectures) et suivez les détails de configuration de l'instance Sidekiq.

## Configurer plusieurs nœuds Sidekiq avec un stockage partagé {#configure-multiple-sidekiq-nodes-with-shared-storage}

Si vous exécutez plusieurs nœuds Sidekiq avec un stockage de fichiers partagé, comme NFS, vous devez spécifier les UID et GID pour vous assurer qu'ils correspondent entre les serveurs. La spécification des UID et GID empêche les problèmes de permissions dans le système de fichiers. Ce conseil est similaire aux [recommandations pour les configurations Geo](../geo/replication/multiple_servers.md#step-4-configure-the-frontend-application-nodes-on-the-geo-secondary-site).

Pour configurer plusieurs nœuds Sidekiq :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   user['uid'] = 9000
   user['gid'] = 9000
   web_server['uid'] = 9001
   web_server['gid'] = 9001
   registry['uid'] = 9002
   registry['gid'] = 9002
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Configurer le registre de conteneurs lors de l'utilisation d'un Sidekiq externe {#configure-the-container-registry-when-using-an-external-sidekiq}

Si vous utilisez le registre de conteneurs et qu'il s'exécute sur un nœud différent de Sidekiq, suivez les étapes ci-dessous.

1. Modifiez `/etc/gitlab/gitlab.rb` et configurez l'URL du registre :

   ```ruby
   gitlab_rails['registry_api_url'] = "https://registry.example.com"
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Dans l'instance où le registre de conteneurs est hébergé, copiez le fichier `registry.key` vers le nœud Sidekiq.

## Configurer le serveur de métriques Sidekiq {#configure-the-sidekiq-metrics-server}

Si vous souhaitez collecter les métriques Sidekiq, activez le serveur de métriques Sidekiq. Pour rendre les métriques disponibles depuis `localhost:8082/metrics` :

Pour configurer le serveur de métriques :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   sidekiq['metrics_enabled'] = true
   sidekiq['listen_address'] = "localhost"
   sidekiq['listen_port'] = 8082

   # Optionally log all the metrics server logs to log/sidekiq_exporter.log
   sidekiq['exporter_log_enabled'] = true
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

### Activer HTTPS {#enable-https}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/364771) dans GitLab 15.2.

{{< /history >}}

Pour servir les métriques via HTTPS plutôt que HTTP, activez TLS dans les paramètres de l'exportateur :

1. Modifiez `/etc/gitlab/gitlab.rb` pour ajouter (ou trouver et décommenter) les lignes suivantes :

   ```ruby
   sidekiq['exporter_tls_enabled'] = true
   sidekiq['exporter_tls_cert_path'] = "/path/to/certificate.pem"
   sidekiq['exporter_tls_key_path'] = "/path/to/private-key.pem"
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Lorsque TLS est activé, les mêmes `port` et `address` sont utilisés que ceux décrits précédemment. Le serveur de métriques ne peut pas servir à la fois HTTP et HTTPS en même temps.

## Configurer les vérifications de santé {#configure-health-checks}

Si vous utilisez des sondes de vérification de santé pour observer Sidekiq, activez le serveur de vérification de santé Sidekiq. Pour rendre les vérifications de santé disponibles depuis `localhost:8092` :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   sidekiq['health_checks_enabled'] = true
   sidekiq['health_checks_listen_address'] = "localhost"
   sidekiq['health_checks_listen_port'] = 8092
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Pour plus d'informations sur les vérifications de santé, consultez la [page de vérification de santé Sidekiq](sidekiq_health_check.md).

## Configurer LDAP et la synchronisation des utilisateurs ou des groupes {#configure-ldap-and-user-or-group-synchronization}

Si vous utilisez LDAP pour la gestion des utilisateurs et des groupes, vous devez ajouter la configuration LDAP à votre nœud Sidekiq ainsi qu'au worker de synchronisation LDAP. Si la configuration LDAP et le worker de synchronisation LDAP ne sont pas appliqués à votre nœud Sidekiq, les utilisateurs et les groupes ne sont pas automatiquement synchronisés.

Pour plus d'informations sur la configuration de LDAP pour GitLab, consultez :

- [Documentation de configuration LDAP de GitLab](../auth/ldap/_index.md#configure-ldap)
- [Documentation de synchronisation LDAP](../auth/ldap/ldap_synchronization.md#adjust-ldap-sync-schedule)

Pour activer LDAP avec le worker de synchronisation pour Sidekiq :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['ldap_enabled'] = true
   gitlab_rails['prevent_ldap_sign_in'] = false
   gitlab_rails['ldap_servers'] = {
   'main' => {
   'label' => 'LDAP',
   'host' => 'ldap.mydomain.com',
   'port' => 389,
   'uid' => 'sAMAccountName',
   'encryption' => 'simple_tls',
   'verify_certificates' => true,
   'bind_dn' => '_the_full_dn_of_the_user_you_will_bind_with',
   'password' => '_the_password_of_the_bind_user',
   'tls_options' => {
      'ca_file' => '',
      'ssl_version' => '',
      'ciphers' => '',
      'cert' => '',
      'key' => ''
   },
   'timeout' => 10,
   'active_directory' => true,
   'allow_username_or_email_login' => false,
   'block_auto_created_users' => false,
   'base' => 'dc=example,dc=com',
   'user_filter' => '',
   'attributes' => {
      'username' => ['uid', 'userid', 'sAMAccountName'],
      'email' => ['mail', 'email', 'userPrincipalName'],
      'name' => 'cn',
      'first_name' => 'givenName',
      'last_name' => 'sn'
   },
   'lowercase_usernames' => false,

   # Enterprise Edition only
   # https://docs.gitlab.com/administration/auth/ldap/ldap_synchronization/
   'group_base' => '',
   'admin_group' => '',
   'external_groups' => [],
   'sync_ssh_keys' => false
   }
   }
   gitlab_rails['ldap_sync_worker_cron'] = "0 */12 * * *"
   ```

1. Reconfigurer GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Configurer les groupes SAML pour la synchronisation des groupes SAML {#configure-saml-groups-for-saml-group-sync}

Si vous utilisez la [synchronisation des groupes SAML](../../user/group/saml_sso/group_sync.md), vous devez configurer les [groupes SAML](../../integration/saml.md#configure-users-based-on-saml-group-membership) sur tous vos nœuds Sidekiq.

## Sujets connexes {#related-topics}

- [Processus Sidekiq supplémentaires](extra_sidekiq_processes.md)
- [Traitement de classes de jobs spécifiques](processing_specific_job_classes.md)
- [Vérifications de santé Sidekiq](sidekiq_health_check.md)
- [Utilisation du chart GitLab-Sidekiq](https://docs.gitlab.com/charts/charts/gitlab/sidekiq/)

## Dépannage {#troubleshooting}

Consultez notre [guide d'administration pour le dépannage de Sidekiq](sidekiq_troubleshooting.md).
