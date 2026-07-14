---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Importation en trois étapes
description: "Activez la base de données de métadonnées du registre de conteneurs avec un temps d'arrêt minimal."
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Importez les métadonnées de votre registre de conteneurs existant. La procédure suivante est recommandée pour les registres de grande taille (200 Gio ou plus), ou si vous souhaitez minimiser le temps d'arrêt lors de l'importation.

## Pré-importer les dépôts (étape 1) {#pre-import-repositories-step-one}

Des utilisateurs ont signalé que l'importation de l'étape 1 s'est terminée à [des vitesses de 2 à 4 To par heure](https://gitlab.com/gitlab-org/gitlab/-/issues/423459). À la vitesse la plus lente, les registres contenant plus de 100 To de données pourraient prendre plus de 48 heures.

Vous pouvez continuer à utiliser le registre normalement pendant l'exécution de l'étape 1.

{{< tabs >}}

{{< tab title="GitLab 18.7 et versions ultérieures" >}}

1. Assurez-vous que la base de données est désactivée dans la section `database` de votre fichier `/etc/gitlab/gitlab.rb` :

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. [Appliquez les migrations de base de données](container_registry_metadata_database.md#apply-database-migrations).
1. Exécutez la première étape pour lancer l'importation :

   ```shell
   sudo gitlab-ctl registry-database import --step-one --log-to-stdout
   ```

{{< /tab >}}

{{< tab title="GitLab 18.3 à 18.6" >}}

1. Assurez-vous que la base de données est désactivée dans la section `database` de votre fichier `/etc/gitlab/gitlab.rb` :

   ```ruby
   registry['database'] = {
     'enabled' => false, # Must be false!
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. [Appliquez les migrations de base de données](container_registry_metadata_database.md#apply-database-migrations).
1. Exécutez la première étape pour lancer l'importation :

   ```shell
   sudo -u registry gitlab-ctl registry-database import --step-one --log-to-stdout
   ```

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

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. [Appliquez les migrations de base de données](container_registry_metadata_database.md#apply-database-migrations) si vous ne l'avez pas encore fait.
1. Exécutez la première étape pour lancer l'importation :

   ```shell
   sudo gitlab-ctl registry-database import --step-one
   ```

{{< /tab >}}

{{< /tabs >}}

> [!note]
> Essayez de planifier l'étape suivante dès que possible afin de réduire la durée du temps d'arrêt nécessaire. Idéalement, moins d'une semaine après la fin de l'étape 1. Toute nouvelle donnée écrite dans le registre entre les étapes 1 et 2 allonge la durée de l'étape 2.

## Importer toutes les données des dépôts (étape 2) {#import-all-repository-data-step-two}

Cette étape nécessite l'arrêt du registre ou sa mise en mode `read-only` ; cependant, vous pouvez vous attendre à ce que cette étape se termine environ 90 % plus vite que l'étape 1. Prévoyez suffisamment de temps pour le temps d'arrêt pendant l'exécution de l'étape 2.

{{< tabs >}}

{{< tab title="GitLab 18.7 et versions ultérieures" >}}

1. Assurez-vous que le registre est en mode `read-only`.

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
1. Exécutez l'étape 2 de l'importation :

   ```shell
   sudo gitlab-ctl registry-database import --step-two --log-to-stdout
   ```

1. Si la commande s'est terminée avec succès, toutes les images sont maintenant entièrement importées. Vous pouvez maintenant activer la base de données, désactiver le mode lecture seule dans la configuration et démarrer le service de registre :

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be set to true!
   }

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => { # This section can be removed.
       'readonly' => {
         'enabled' => false
       }
     }
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

{{< /tab >}}

{{< tab title="GitLab 18.3 à 18.6" >}}

1. Assurez-vous que le registre est en mode `read-only`.

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
1. Exécutez l'étape 2 de l'importation :

   ```shell
   sudo -u registry gitlab-ctl registry-database import --step-two --log-to-stdout
   ```

1. Si la commande s'est terminée avec succès, toutes les images sont maintenant entièrement importées. Vous pouvez maintenant activer la base de données, désactiver le mode lecture seule dans la configuration et démarrer le service de registre :

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be set to true!
   }

   ## Object Storage - Container Registry
   registry['storage'] = {
     'gcs' => {
       'bucket' => '<my-company-container-registry>',
       'chunksize' => 5242880
     },
     'maintenance' => { # This section can be removed.
       'readonly' => {
         'enabled' => false
       }
     }
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

{{< /tab >}}

{{< tab title="GitLab 17.5 à 18.2" >}}

1. Assurez-vous que le registre est en mode `read-only`.

   Modifiez votre `/etc/gitlab/gitlab.rb` et ajoutez la section `maintenance` à la configuration `registry['storage']`. Par exemple, pour un registre basé sur `gcs` utilisant un bucket `gs://my-company-container-registry`, la configuration pourrait être :

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
1. Exécutez l'étape 2 de l'importation :

   ```shell
   sudo gitlab-ctl registry-database import --step-two
   ```

1. Si la commande s'est terminée avec succès, toutes les images sont maintenant entièrement importées. Vous pouvez maintenant activer la base de données, désactiver le mode lecture seule dans la configuration et démarrer le service de registre :

   ```ruby
   registry['database'] = {
     'enabled' => true, # Must be set to true!
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
     'maintenance' => { # This section can be removed.
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

## Importer les données restantes (étape 3) {#import-remaining-data-step-three}

Même si le registre utilise désormais entièrement la base de données pour ses métadonnées, il n'a pas encore accès aux blobs de couche potentiellement inutilisés, ce qui empêche leur suppression par le ramasse-miettes en ligne.

Vous pouvez continuer à utiliser le registre normalement pendant l'exécution de l'étape 3.

Pour terminer le processus, exécutez la dernière étape de la migration :

{{< tabs >}}

{{< tab title="GitLab 18.7 et versions ultérieures" >}}

```shell
sudo gitlab-ctl registry-database import --step-three --log-to-stdout
```

{{< /tab >}}

{{< tab title="GitLab 18.3 à 18.6" >}}

```shell
sudo -u registry gitlab-ctl registry-database import --step-three --log-to-stdout
```

{{< /tab >}}

{{< tab title="GitLab 17.5 à 18.2" >}}

```shell
sudo gitlab-ctl registry-database import --step-three
```

{{< /tab >}}

{{< /tabs >}}

Une fois que cette commande s'est terminée avec succès, les métadonnées du registre sont désormais entièrement importées dans la base de données.

## Après l'importation {#after-import}

Les grands registres peuvent avoir des centaines de milliers, voire des millions de blobs en attente de révision pour la collecte des éléments inutilisés après une importation. C'est normal, et aux intervalles de workers par défaut, le traitement prend du temps.

Pour savoir à quoi vous attendre et comment accélérer le traitement, consultez :

- [Post-importation](container_registry_metadata_database.md#post-import) pour un aperçu du comportement attendu après la fin d'une importation.
- [Vérifiez l'état de la collecte des éléments inutilisés en ligne](container_registry_metadata_database.md#check-the-health-of-online-garbage-collection) pour surveiller les files d'attente de révision de la collecte des éléments inutilisés.
- [Ajustez l'intervalle du worker de collecte des éléments inutilisés](container_registry_metadata_database.md#adjust-the-garbage-collector-worker-interval) pour accélérer temporairement le traitement des grands arriérés.
