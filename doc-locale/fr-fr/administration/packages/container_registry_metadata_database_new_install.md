---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Base de données de métadonnées du registre de conteneurs pour les nouvelles installations
description: Activez la base de données de métadonnées du registre de conteneurs pour les nouvelles installations.
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Activez la base de données de métadonnées du registre de conteneurs pour votre instance.

## Activer la base de données de métadonnées {#enable-the-metadata-database}

Activez la base de données de métadonnées pour un nouveau registre de conteneurs.

{{< tabs >}}

{{< tab title="GitLab 18.3 et versions ultérieures" >}}

Prérequis :

- Vous devez disposer d'un nouveau registre de conteneurs sans images envoyées vers le registre.

Pour activer la base de données :

1. Activez la base de données en modifiant `/etc/gitlab/gitlab.rb` et en définissant `enabled` sur `true` :

   ```ruby
   registry['database'] = {
     'enabled' => true,
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

{{< /tab >}}

{{< tab title="GitLab 17.5 à 18.2" >}}

Prérequis :

- Vous devez disposer d'un nouveau registre de conteneurs sans images envoyées vers le registre.
- Créez une [base de données externe](../postgresql/external.md#container-registry-metadata-database).

Pour activer la base de données :

1. Modifiez `/etc/gitlab/gitlab.rb` en ajoutant les détails de connexion à votre base de données, mais commencez avec la base de données de métadonnées désactivée :

   ```ruby
   registry['database'] = {
     'enabled' => false,
     'host' => '<registry_database_host_placeholder_change_me>',
     'port' => 5432, # Default, but set to the port of your database instance if it differs.
     'user' => '<registry_database_username_placeholder_change_me>',
     'password' => '<registry_database_placeholder_change_me>',
     'dbname' => '<registry_database_name_placeholder_change_me>',
     'sslmode' => 'require', # See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/16/libpq-ssl.html.
     'sslcert' => '</path/to/cert.pem>',
     'sslkey' => '</path/to/private.key>',
     'sslrootcert' => '</path/to/ca.pem>'
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. [Appliquez les migrations de base de données](container_registry_metadata_database.md#apply-database-migrations).
1. Activez la base de données en modifiant `/etc/gitlab/gitlab.rb` et en définissant `enabled` sur `true` :

   ```ruby
   registry['database'] = {
     'enabled' => true,
     'host' => '<registry_database_host_placeholder_change_me>',
     'port' => 5432, # Default, but set to the port of your database instance if it differs.
     'user' => '<registry_database_username_placeholder_change_me>',
     'password' => '<registry_database_placeholder_change_me>',
     'dbname' => '<registry_database_name_placeholder_change_me>',
     'sslmode' => 'require', # See the PostgreSQL documentation for additional information https://www.postgresql.org/docs/16/libpq-ssl.html.
     'sslcert' => '</path/to/cert.pem>',
     'sslkey' => '</path/to/private.key>',
     'sslrootcert' => '</path/to/ca.pem>'
   }
   ```

{{< /tab >}}

{{< /tabs >}}

Vous pouvez désormais utiliser la base de données de métadonnées pour toutes les opérations !
