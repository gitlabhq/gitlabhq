---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: PostgreSQL autonome pour les installations du package Linux
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Si vous souhaitez que votre service de base de données soit hébergé séparément de vos serveurs d'application GitLab, vous pouvez le faire en utilisant les binaires PostgreSQL fournis avec le package Linux. Cela est recommandé dans le cadre de notre [architecture de référence pour jusqu'à 40 RPS ou 2 000 utilisateurs](../reference_architectures/2k_users.md).

## Configuration {#setting-it-up}

1. Connectez-vous en SSH au serveur PostgreSQL.
1. [Téléchargez et installez](https://about.gitlab.com/install/) le package Linux souhaité en suivant les étapes 1 et 2 de la page de téléchargements GitLab. Ne réalisez aucune autre étape sur la page de téléchargement.
1. Générez un hash de mot de passe pour PostgreSQL. Cela suppose que vous utilisez le nom d'utilisateur par défaut `gitlab` (recommandé). La commande demande un mot de passe et une confirmation. Utilisez la valeur générée par cette commande à l'étape suivante comme valeur de `POSTGRESQL_PASSWORD_HASH`.

   ```shell
   sudo gitlab-ctl pg-password-md5 gitlab
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez le contenu ci-dessous, en mettant à jour les valeurs d'espace réservé de manière appropriée.

   - `POSTGRESQL_PASSWORD_HASH` - La valeur générée à l'étape précédente
   - `APPLICATION_SERVER_IP_BLOCKS` - Une liste délimitée par des espaces de sous-réseaux IP ou d'adresses IP des serveurs d'application GitLab qui se connectent à la base de données. Exemple : `%w(123.123.123.123/32 123.123.123.234/32)`

   ```ruby
   # Disable all components except PostgreSQL
   roles(['postgres_role'])
   prometheus['enable'] = false
   alertmanager['enable'] = false
   pgbouncer_exporter['enable'] = false
   redis_exporter['enable'] = false
   gitlab_exporter['enable'] = false

   postgresql['listen_address'] = '0.0.0.0'
   postgresql['port'] = 5432

   # Replace POSTGRESQL_PASSWORD_HASH with a generated md5 value
   postgresql['sql_user_password'] = 'POSTGRESQL_PASSWORD_HASH'

   # Replace APPLICATION_SERVER_IP_BLOCKS with Network Address (XXX.XXX.XXX.XXX/YY)
   postgresql['trust_auth_cidr_addresses'] = %w(APPLICATION_SERVER_IP_BLOCKS)

   # Disable automatic database migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
1. Notez l'adresse IP ou le nom d'hôte, le port et le mot de passe en texte clair du nœud PostgreSQL. Ces informations sont nécessaires lors de la configuration ultérieure des serveurs d'application GitLab.
1. [Activer la surveillance](replication_and_failover.md#enable-monitoring)

Les options de configuration avancées sont prises en charge et peuvent être ajoutées si nécessaire.
