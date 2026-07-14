---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage de la base de données de métadonnées du registre de conteneurs
description: Résoudre les problèmes liés à la base de données de métadonnées du registre de conteneurs.
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

## Erreur : `there are pending database migrations` {#error-there-are-pending-database-migrations}

Si le registre a été mis à jour et qu'il existe des migrations de schéma en attente, le registre ne démarre pas et affiche le message d'erreur suivant :

```shell
FATA[0000] configuring application: there are pending database migrations, use the 'registry database migrate' CLI command to check and apply them
```

Pour résoudre ce problème, suivez les étapes pour [appliquer les migrations de base de données](container_registry_metadata_database.md#apply-database-migrations).

Avant la version 18.3, vous devez appliquer manuellement les migrations de base de données à chaque mise à niveau de version.

### Erreur : `offline garbage collection is no longer possible` {#error-offline-garbage-collection-is-no-longer-possible}

Si le registre utilise la base de données de métadonnées et que vous essayez d'exécuter la [collecte des éléments non référencés hors ligne](container_registry.md#container-registry-garbage-collection), le registre échoue avec le message d'erreur suivant :

```shell
ERRO[0000] this filesystem is managed by the metadata database, and offline garbage collection is no longer possible, if you are not using the database anymore, remove the file at the lock_path in this log message lock_path=/docker/registry/lockfiles/database-in-use
```

Vous devez soit :

- Cesser d'utiliser la collecte des éléments non référencés hors ligne.
- Si vous n'utilisez plus la base de données de métadonnées, supprimez le fichier de verrouillage indiqué au niveau du `lock_path` affiché dans le message d'erreur. Par exemple, supprimez le fichier `/docker/registry/lockfiles/database-in-use`.

### Erreur : `cannot execute <STATEMENT> in a read-only transaction` {#error-cannot-execute-statement-in-a-read-only-transaction}

Le registre pourrait échouer lors de l'[application des migrations de base de données](container_registry_metadata_database.md#apply-database-migrations) avec le message d'erreur suivant :

```shell
err="ERROR: cannot execute CREATE TABLE in a read-only transaction (SQLSTATE 25006)"
```

De plus, le registre pourrait échouer avec le message d'erreur suivant si vous essayez d'exécuter la [collecte des éléments non référencés en ligne](container_registry.md#performing-garbage-collection-without-downtime) :

```shell
error="processing task: fetching next GC blob task: scanning GC blob task: ERROR: cannot execute SELECT FOR UPDATE in a read-only transaction (SQLSTATE 25006)"
```

Vous devez vérifier que les transactions en lecture seule sont désactivées en vérifiant les valeurs de `default_transaction_read_only` et `transaction_read_only` dans la console PostgreSQL. Par exemple :

```sql
# SHOW default_transaction_read_only;
 default_transaction_read_only
 -------------------------------
 on
(1 row)

# SHOW transaction_read_only;
 transaction_read_only
 -----------------------
 on
(1 row)
```

Si l'une de ces valeurs est définie sur `on`, vous devez la désactiver :

1. Modifiez votre `postgresql.conf` et définissez la valeur suivante :

   ```shell
   default_transaction_read_only=off
   ```

1. Redémarrez votre serveur Postgres pour appliquer ces paramètres.
1. Essayez d'[appliquer les migrations de base de données](container_registry_metadata_database.md#apply-database-migrations) à nouveau, le cas échéant.
1. Redémarrez le registre `sudo gitlab-ctl restart registry`.

### Erreur : `cannot import all repositories while the tags table has entries` {#error-cannot-import-all-repositories-while-the-tags-table-has-entries}

Si vous essayez d'[importer les métadonnées de registre existantes](container_registry_metadata_database.md#enable-the-database-for-existing-registries) et que vous rencontrez l'erreur suivante :

```shell
ERRO[0000] cannot import all repositories while the tags table has entries, you must truncate the table manually before retrying,
see https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#troubleshooting
common_blobs=true dry_run=false error="tags table is not empty"
```

Cette erreur se produit lorsqu'il existe des entrées dans la table `tags` de la base de données du registre, ce qui peut arriver si vous :

- Avez tenté l'[importation en une étape](container_registry_metadata_database_one_step_import.md) et avez rencontré des erreurs.
- Avez tenté le processus d'[importation en trois étapes](container_registry_metadata_database_three_step_import.md) et avez rencontré des erreurs.
- Avez arrêté le processus d'importation intentionnellement.
- Avez essayé de relancer l'importation après l'une des actions précédentes.
- Avez exécuté l'importation avec le mauvais fichier de configuration.

Pour résoudre ce problème, vous devez supprimer les entrées existantes dans la table des tags. Vous devez tronquer la table manuellement sur votre instance PostgreSQL :

1. Modifiez `/etc/gitlab/gitlab.rb` et assurez-vous que la base de données de métadonnées est désactivée :

   ```ruby
   registry['database'] = {
     'enabled' => false,
   }
   ```

1. Connectez-vous à votre base de données de registre à l'aide d'un client PostgreSQL.
1. Tronquez la table `tags` pour supprimer toutes les entrées existantes :

   ```sql
   TRUNCATE TABLE tags RESTART IDENTITY CASCADE;
   ```

1. Après avoir tronqué la table `tags`, essayez de relancer le processus d'importation.

### Erreur : `database-in-use lockfile exists` {#error-database-in-use-lockfile-exists}

Si vous essayez d'[importer les métadonnées de registre existantes](container_registry_metadata_database.md#enable-the-database-for-existing-registries) et que vous rencontrez l'erreur suivante :

```shell
|  [0s] step two: import tags failed to import metadata: importing all repositories: 1 error occurred:
    * could not restore lockfiles: database-in-use lockfile exists
```

Cette erreur signifie que vous avez précédemment importé le registre et terminé l'importation de toutes les données du dépôt (étape deux) et que le `database-in-use` existe dans le système de fichiers du registre. Vous ne devez pas relancer l'importateur si vous rencontrez ce problème.

Si vous devez continuer, vous devez supprimer manuellement le fichier de verrouillage `database-in-use` du système de fichiers. Le fichier se trouve à l'emplacement `/path/to/rootdirectory/docker/registry/lockfiles/database-in-use`.

### Erreur : `pre importing all repositories: AccessDenied:` {#error-pre-importing-all-repositories-accessdenied}

Vous pourriez recevoir une erreur `AccessDenied` lors de l'[importation de registres existants](container_registry_metadata_database.md#enable-the-database-for-existing-registries) en utilisant AWS S3 comme backend de stockage :

```shell
/opt/gitlab/embedded/bin/registry database import --step-one /var/opt/gitlab/registry/config.yml
  [0s] step one: import manifests
  [0s] step one: import manifests failed to import metadata: pre importing all repositories: AccessDenied: Access Denied
```

Assurez-vous que l'utilisateur exécutant la commande dispose des [portées d'autorisation](https://docker-docs.uclv.cu/registry/storage-drivers/s3/#s3-permission-scopes) correctes.

### Le registre ne démarre pas en raison de problèmes de gestion des métadonnées {#registry-fails-to-start-due-to-metadata-management-issues}

Le registre pourrait ne pas démarrer avec l'une des erreurs suivantes :

#### Erreur : `registry filesystem metadata in use, please import data before enabling the database` {#error-registry-filesystem-metadata-in-use-please-import-data-before-enabling-the-database}

Cette erreur se produit lorsque la base de données est activée dans votre configuration `registry['database'] = { 'enabled' => true}` mais que vous n'avez pas encore [importé les métadonnées de registre existantes](container_registry_metadata_database.md#enable-the-database-for-existing-registries) dans la base de données de métadonnées.

#### Erreur : `registry metadata database in use, please enable the database` {#error-registry-metadata-database-in-use-please-enable-the-database}

Cette erreur se produit lorsque vous avez terminé l'[importation des métadonnées de registre existantes](container_registry_metadata_database.md#enable-the-database-for-existing-registries) dans la base de données de métadonnées, mais que vous n'avez pas activé la base de données dans votre configuration.

#### Problèmes lors de la vérification ou de la création des fichiers de verrouillage {#problems-checking-or-creating-the-lock-files}

Si vous rencontrez l'une des erreurs suivantes :

- `could not check if filesystem metadata is locked`
- `could not check if database metadata is locked`
- `failed to mark filesystem for database only usage`
- `failed to mark filesystem only usage`

Le registre ne peut pas accéder au `rootdirectory` configuré. Cette erreur est peu susceptible de se produire si vous aviez un registre fonctionnel auparavant. Consultez les journaux d'erreurs pour détecter tout problème de configuration.

### L'utilisation du stockage ne diminue pas après la suppression des tags {#storage-usage-not-decreasing-after-deleting-tags}

Par défaut, le collecteur des éléments non référencés en ligne ne commencera à supprimer les couches non référencées que 48 heures après la suppression de tous les tags auxquels elles étaient associées. Ce délai garantit que le collecteur des éléments non référencés n'interfère pas avec les envois d'images de longue durée ou interrompus, car les couches sont envoyées au registre avant d'être associées à une image et un tag.

### Erreur : `permission denied for schema public (SQLSTATE 42501)` {#error-permission-denied-for-schema-public-sqlstate-42501}

Lors d'une migration de registre ou d'une mise à niveau de GitLab, vous pourriez obtenir l'une des erreurs suivantes :

- `ERROR: permission denied for schema public (SQLSTATE 42501)`
- `ERROR: relation "public.blobs" does not exist (SQLSTATE 42P01)`

Ces types d'erreurs sont dus à un changement dans PostgreSQL 15+, qui supprime les privilèges CREATE par défaut sur le schéma public pour des raisons de sécurité. Par défaut, seuls les propriétaires de bases de données peuvent créer des objets dans le schéma public dans PostgreSQL 15+.

Pour résoudre l'erreur, exécutez la commande suivante pour donner à un utilisateur du registre les privilèges de propriétaire de la base de données du registre :

```sql
ALTER DATABASE <registry_database_name> OWNER TO <registry_user>;
```

Cela donne à l'utilisateur du registre les autorisations nécessaires pour créer des tables et exécuter des migrations avec succès.

### Erreur : `database-in-use and filesystem-in-use lockfiles present` {#error-database-in-use-and-filesystem-in-use-lockfiles-present}

Cette erreur se produit lorsque les fichiers de verrouillage `filesystem-in-use` et `database-in-use` sont tous deux présents sur le stockage de registre configuré et indique un état de registre ambigu.

Pour résoudre cette erreur, vous devez déterminer si votre registre est censé utiliser la base de données de métadonnées ou le stockage de métadonnées hérité.

Votre registre est probablement censé utiliser la base de données de métadonnées si :

- Vous avez déjà effectué l'un des [processus d'importation](container_registry_metadata_database.md#choose-the-right-import-method).
- La configuration de votre registre indique que le registre est activé.

Vérifiez le fichier à l'emplacement `/etc/gitlab/gitlab.rb` pour voir si le registre est activé :

```ruby
registry['database'] = {
  'enabled' => true,
}
```

Après avoir confirmé que le registre est censé utiliser la base de données, supprimez le fichier de verrouillage `filesystem-in-use` présent dans le stockage de registre configuré situé à `/docker/registry/lockfiles/filesystem-in-use`.

Sinon, si les scénarios ci-dessus ne sont pas vrais et que votre registre est censé utiliser le stockage de métadonnées hérité, supprimez le fichier de verrouillage `database-in-use` à l'emplacement `/docker/registry/lockfiles/database-in-use`.

Pour GitLab 18.8 et 18.9, vous pouvez désactiver les vérifications des fichiers de verrouillage en définissant le feature flag du registre de conteneurs `REGISTRY_FF_ENFORCE_LOCKFILES` sur `false`. Bien que cela désactive les vérifications, cette erreur est destinée à garantir l'intégrité des données de votre registre et il est préférable de confirmer quel stockage de métadonnées vous utilisez. Le feature flag `REGISTRY_FF_ENFORCE_LOCKFILES` a été supprimé dans GitLab 18.10. Pour plus d'informations, consultez [Feature flags du registre de conteneurs](container_registry.md#container-registry-feature-flags).
