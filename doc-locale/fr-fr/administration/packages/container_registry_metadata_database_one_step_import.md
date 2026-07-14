---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Import en une étape
description: Activer la base de données de métadonnées du registre de conteneurs en une étape.
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Utilisez la méthode d'import en une étape si vous exécutez régulièrement la [collecte des éléments inutilisés hors ligne](container_registry.md#container-registry-garbage-collection). Cette méthode est une opération plus simple par rapport à la méthode d'import en trois étapes.

## Import en une étape {#one-step-import}

> [!warning]
> Le registre doit être arrêté ou rester en mode `read-only` pendant l'import. Sinon, les données écrites pendant l'import deviennent inaccessibles ou entraînent des incohérences.

{{< tabs >}}

{{< tab title="GitLab 18.7 et versions ultérieures" >}}

1. Assurez-vous que la base de données est désactivée dans la section `registry['database']` de votre fichier `/etc/gitlab/gitlab.rb` :

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
   }
   ```

1. Assurez-vous que le registre est défini en mode `read-only`.

   Modifiez votre `/etc/gitlab/gitlab.rb` et ajoutez la section `maintenance` à la configuration `registry['storage']`. Par exemple, pour un registre backend `gcs` utilisant un bucket `gs://my-company-container-registry`, la configuration pourrait être :

   ```ruby
   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => true # Must be set to true.
       }
     }
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. [Appliquez les migrations de base de données](container_registry_metadata_database.md#apply-database-migrations).
1. Exécutez la commande suivante :

   ```shell
   sudo gitlab-ctl registry-database import --log-to-stdout
   ```

1. Si la commande s'est terminée avec succès, le registre est entièrement importé. Vous pouvez activer la base de données, désactiver le mode lecture seule dans la configuration et démarrer le service de registre :

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be enabled now!
   }

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => false
       }
     }
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

{{< /tab >}}

{{< tab title="GitLab 18.3 à 18.6" >}}

1. Assurez-vous que la base de données est désactivée dans la section `registry['database']` de votre fichier `/etc/gitlab/gitlab.rb` :

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
   }
   ```

1. Assurez-vous que le registre est défini en mode `read-only`.

   Modifiez votre `/etc/gitlab/gitlab.rb` et ajoutez la section `maintenance` à la configuration `registry['storage']`. Par exemple, pour un registre backend `gcs` utilisant un bucket `gs://my-company-container-registry`, la configuration pourrait être :

   ```ruby
   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => true # Must be set to true.
       }
     }
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. [Appliquez les migrations de base de données](container_registry_metadata_database.md#apply-database-migrations).
1. Exécutez la commande suivante :

   ```shell
   sudo -u registry gitlab-ctl registry-database import --log-to-stdout
   ```

1. Si la commande s'est terminée avec succès, le registre est entièrement importé. Vous pouvez activer la base de données, désactiver le mode lecture seule dans la configuration et démarrer le service de registre :

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be enabled now!
   }

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => false
       }
     }
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

{{< /tab >}}

{{< tab title="GitLab 17.5 à 18.2" >}}

Prérequis :

- Créez une [base de données externe](../postgresql/external.md#container-registry-metadata-database).

1. Ajoutez la section `database` à votre fichier `/etc/gitlab/gitlab.rb`, mais commencez avec la base de données de métadonnées désactivée :

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
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

1. Assurez-vous que le registre est défini en mode `read-only`.

   Modifiez votre `/etc/gitlab/gitlab.rb` et ajoutez la section `maintenance` à la configuration `registry['storage']`. Par exemple, pour un registre backend `gcs` utilisant un bucket `gs://my-company-container-registry`, la configuration pourrait être :

   ```ruby
   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => true # Must be set to true.
       }
     }
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. [Appliquez les migrations de base de données](container_registry_metadata_database.md#apply-database-migrations) si vous ne l'avez pas encore fait.
1. Exécutez la commande suivante :

   ```shell
   sudo gitlab-ctl registry-database import
   ```

1. Si la commande s'est terminée avec succès, le registre est maintenant entièrement importé. Vous pouvez maintenant activer la base de données, désactiver le mode lecture seule dans la configuration et démarrer le service de registre :

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be enabled now!
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

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => {
       'readonly' => {
         'enabled' => false
       }
     }
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

{{< /tab >}}

{{< /tabs >}}

Vous pouvez maintenant utiliser la base de données de métadonnées pour toutes les opérations !

## Après l'import {#after-import}

Les grands registres de conteneurs peuvent avoir des centaines de milliers, voire des millions de blobs mis en file d'attente pour une révision de la collecte des éléments inutilisés après un import. C'est normal, et aux intervalles de worker par défaut, le traitement prend du temps.

Pour obtenir des conseils sur ce à quoi vous attendre et comment accélérer le traitement, consultez :

- [Post-import](container_registry_metadata_database.md#post-import) pour une vue d'ensemble du comportement attendu après la fin d'un import.
- [Vérifier l'intégrité de la collecte des éléments inutilisés en ligne](container_registry_metadata_database.md#check-the-health-of-online-garbage-collection) pour surveiller les files d'attente de révision de la collecte des éléments inutilisés.
- [Ajuster l'intervalle de worker du collecteur d'éléments inutilisés](container_registry_metadata_database.md#adjust-the-garbage-collector-worker-interval) pour accélérer temporairement le traitement des grands backlogs.
