---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage des sauvegardes GitLab
---

Lorsque vous sauvegardez GitLab, vous pouvez rencontrer les problèmes suivants.

## Lorsque le fichier de secrets est perdu {#when-the-secrets-file-is-lost}

Si vous n'avez pas [sauvegardé le fichier de secrets](backup_gitlab.md#storing-configuration-files), vous devez effectuer plusieurs étapes pour que GitLab fonctionne à nouveau correctement.

Le fichier de secrets est responsable du stockage de la clé de chiffrement pour les colonnes contenant des informations requises et sensibles. Si la clé est perdue, GitLab ne peut pas déchiffrer ces colonnes, ce qui empêche l'accès aux éléments suivants :

- [Variables CI/CD](../../ci/variables/_index.md)
- [Intégration Kubernetes / GCP](../../user/infrastructure/clusters/_index.md)
- [Domaines Pages personnalisés](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md)
- [Suivi des erreurs de projet](../../operations/error_tracking.md)
- [Authentification des runners](../../ci/runners/_index.md)
- [Mise en miroir de projet](../../user/project/repository/mirror/_index.md)
- [Intégrations](../../user/project/integrations/_index.md)
- [Webhooks](../../user/project/integrations/webhooks.md)
- [Jetons de déploiement](../../user/project/deploy_tokens/_index.md)

Dans des cas tels que les variables CI/CD et l'authentification des runners, vous pouvez rencontrer des comportements inattendus, tels que :

- Jobs bloqués.
- Erreurs 500.

Dans ce cas, vous devez réinitialiser tous les jetons pour les variables CI/CD et l'authentification des runners, ce qui est décrit plus en détail dans les sections suivantes. Après avoir réinitialisé les jetons, vous devriez pouvoir visiter votre projet et les jobs recommenceront à s'exécuter.

> [!warning]
> Les étapes de cette section peuvent potentiellement entraîner une perte de données sur les éléments précédemment listés. Envisagez d'ouvrir une [demande d'assistance](https://support.gitlab.com/hc/en-us/requests/new) si vous êtes un client Premium ou Ultimate.

### Vérifier que toutes les valeurs peuvent être déchiffrées {#verify-that-all-values-can-be-decrypted}

Vous pouvez déterminer si votre base de données contient des valeurs qui ne peuvent pas être déchiffrées en utilisant une [tâche Rake](../raketasks/check.md#verify-database-values-can-be-decrypted-using-the-current-secrets).

### Effectuer une sauvegarde {#take-a-backup}

Vous devez modifier directement les données GitLab pour contourner le problème de votre fichier de secrets perdu.

> [!warning]
> Assurez-vous de créer une sauvegarde complète de la base de données avant de tenter toute modification.

### Désactiver l'authentification à deux facteurs (2FA) pour les utilisateurs {#disable-user-two-factor-authentication-2fa}

Les utilisateurs avec la uthentification à deux facteurs activée ne peuvent pas se connecter à GitLab. Dans ce cas, vous devez [désactiver la 2FA pour tous les utilisateurs](../../security/two_factor_authentication.md#for-all-users), après quoi les utilisateurs devront réactiver la 2FA.

### Réinitialiser les variables CI/CD {#reset-cicd-variables}

1. Accédez à la console de base de données :

   Pour le package Linux (Omnibus) :

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   Pour les installations auto-compilées :

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Examinez les tables `ci_group_variables` et `ci_variables` :

   ```sql
   SELECT * FROM public."ci_group_variables";
   SELECT * FROM public."ci_variables";
   ```

   Ce sont les variables que vous devez supprimer.

1. Supprimez toutes les variables :

   ```sql
   DELETE FROM ci_group_variables;
   DELETE FROM ci_variables;
   ```

1. Si vous connaissez le groupe ou le projet spécifique à partir duquel vous souhaitez supprimer des variables, vous pouvez inclure une instruction `WHERE` pour le préciser dans votre `DELETE` :

   ```sql
   DELETE FROM ci_group_variables WHERE group_id = <GROUPID>;
   DELETE FROM ci_variables WHERE project_id = <PROJECTID>;
   ```

Vous devrez peut-être reconfigurer ou redémarrer GitLab pour que les modifications prennent effet.

### Réinitialiser les jetons d'enregistrement des runners {#reset-runner-registration-tokens}

1. Accédez à la console de base de données :

   Pour le package Linux (Omnibus) :

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   Pour les installations auto-compilées :

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Effacez tous les jetons pour les projets, les groupes et l'instance entière :

   > [!warning]
   > La dernière opération `UPDATE` empêche les runners de pouvoir récupérer de nouveaux jobs. Vous devez enregistrer de nouveaux runners.

   ```sql
   -- Clear project tokens
   UPDATE projects SET runners_token = null, runners_token_encrypted = null;
   -- Clear group tokens
   UPDATE namespaces SET runners_token = null, runners_token_encrypted = null;
   -- Clear instance tokens
   UPDATE application_settings SET runners_registration_token_encrypted = null;
   -- Clear key used for JWT authentication
   -- This may break the $CI_JWT_TOKEN job variable:
   -- https://gitlab.com/gitlab-org/gitlab/-/issues/325965
   UPDATE application_settings SET encrypted_ci_jwt_signing_key = null;
   -- Clear runner tokens
   UPDATE ci_runners SET token = null, token_encrypted = null;
   ```

### Réinitialiser les jobs de pipeline en attente {#reset-pending-pipeline-jobs}

1. Accédez à la console de base de données :

   Pour le package Linux (Omnibus) :

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   Pour les installations auto-compilées :

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Effacez tous les jetons pour les jobs en attente :

   ```sql
   -- Clear build tokens
   UPDATE ci_builds SET token_encrypted = null;
   ```

Une stratégie similaire peut être employée pour les fonctionnalités restantes. En supprimant les données qui ne peuvent pas être déchiffrées, GitLab peut être remis en fonctionnement, et les données perdues peuvent être remplacées manuellement.

### Corriger les intégrations et les webhooks {#fix-integrations-and-webhooks}

Si vous avez perdu vos secrets, les pages [paramètres des intégrations](../../user/project/integrations/_index.md) et [paramètres des webhooks](../../user/project/integrations/webhooks.md) peuvent afficher des messages d'erreur `500`. Des secrets perdus peuvent également produire des erreurs `500` lorsque vous tentez d'accéder à un dépôt dans un projet avec une intégration ou un webhook précédemment configuré.

La solution consiste à tronquer les tables affectées (celles contenant des colonnes chiffrées). Cela supprime toutes vos intégrations configurées, vos webhooks et les métadonnées associées. Vous devez vérifier que les secrets sont la cause première avant de supprimer des données.

1. Accédez à la console de base de données :

   Pour le package Linux (Omnibus) :

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   Pour les installations auto-compilées :

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Tronquez les tables suivantes :

   ```sql
   -- truncate web_hooks table
   TRUNCATE integrations, chat_names, issue_tracker_data, jira_tracker_data, slack_integrations, web_hooks, zentao_tracker_data, web_hook_logs CASCADE;
   ```

## Le registre de conteneurs n'est pas restauré {#container-registry-is-not-restored}

Si vous restaurez une sauvegarde depuis un environnement qui utilise le [registre de conteneurs](../../user/packages/container_registry/_index.md) vers un environnement nouvellement installé où le registre de conteneurs n'est pas activé, le registre de conteneurs n'est pas restauré.

Pour restaurer également le registre de conteneurs, vous devez [l'activer](../packages/container_registry.md#enable-the-container-registry) dans le nouvel environnement avant de restaurer la sauvegarde.

## Échecs de push du registre de conteneurs après restauration d'une sauvegarde {#container-registry-push-failures-after-restoring-from-a-backup}

Si vous utilisez le [registre de conteneurs](../../user/packages/container_registry/_index.md), les push vers le registre peuvent échouer après la restauration de votre sauvegarde sur une instance de package Linux (Omnibus) après la restauration des données du registre.

Ces échecs mentionnent des problèmes de permissions dans les journaux du registre, similaires à :

```plaintext
level=error
msg="response completed with error"
err.code=unknown
err.detail="filesystem: mkdir /var/opt/gitlab/gitlab-rails/shared/registry/docker/registry/v2/repositories/...: permission denied"
err.message="unknown error"
```

Ce problème est causé par la restauration s'exécutant en tant qu'utilisateur non privilégié `git`, qui est incapable d'attribuer la propriété correcte aux fichiers du registre pendant le processus de restauration ([issue #62759](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/62759 "Incorrect permissions on registry filesystem after restore")).

Pour remettre votre registre en fonctionnement :

```shell
sudo chown -R registry:registry /var/opt/gitlab/gitlab-rails/shared/registry/docker
```

Si vous avez modifié l'emplacement par défaut du système de fichiers pour le registre, exécutez `chown` sur votre emplacement personnalisé, plutôt que `/var/opt/gitlab/gitlab-rails/shared/registry/docker`.

## La sauvegarde ne se termine pas avec une erreur Gzip {#backup-fails-to-complete-with-gzip-error}

Lors de l'exécution de la sauvegarde, vous pouvez recevoir un message d'erreur Gzip :

```shell
sudo /opt/gitlab/bin/gitlab-backup create
...
Dumping ...
...
gzip: stdout: Input/output error

Backup failed
```

Si cela se produit, examinez les éléments suivants :

- Vérifiez qu'il y a suffisamment d'espace disque pour l'opération Gzip. Il n'est pas rare que les sauvegardes utilisant la [stratégie par défaut](backup_gitlab.md#backup-strategy-option) nécessitent la moitié de la taille de l'instance en espace disque libre lors de la création de la sauvegarde.
- Si NFS est utilisé, vérifiez si l'option de montage `timeout` est définie. La valeur par défaut est `600`, et la réduire à des valeurs plus petites entraîne cette erreur.

## La sauvegarde échoue avec l'erreur `File name too long` {#backup-fails-with-file-name-too-long-error}

Pendant la sauvegarde, vous pouvez obtenir l'erreur `File name too long` ([issue #354984](https://gitlab.com/gitlab-org/gitlab/-/issues/354984)). Par exemple :

```plaintext
Problem: <class 'OSError: [Errno 36] File name too long:
```

Ce problème empêche le script de sauvegarde de se terminer. Pour résoudre ce problème, vous devez tronquer les noms de fichiers à l'origine du problème. Un maximum de 246 caractères, extension de fichier incluse, est autorisé.

> [!warning]
> Les étapes de cette section peuvent potentiellement entraîner une perte de données. Toutes les étapes doivent être suivies strictement dans l'ordre indiqué. Envisagez d'ouvrir une [demande d'assistance](https://support.gitlab.com/hc/en-us/requests/new) si vous êtes un client Premium ou Ultimate.

La troncature des noms de fichiers pour résoudre l'erreur implique :

- Le nettoyage des fichiers téléversés à distance qui ne sont pas suivis dans la base de données.
- La troncature des noms de fichiers dans la base de données.
- La réexécution de la tâche de sauvegarde.

### Nettoyer les fichiers téléversés à distance {#clean-up-remote-uploaded-files}

Un [problème connu](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/45425) a entraîné la conservation des téléversements dans le stockage d'objets après la suppression d'une ressource parente. Ce problème a été [résolu](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/18698).

Pour corriger ces fichiers, vous devez nettoyer tous les fichiers téléversés à distance qui se trouvent dans le stockage mais ne sont pas suivis dans la table de base de données `uploads`.

1. Listez tous les fichiers de téléversement du stockage d'objets qui peuvent être déplacés vers un répertoire des objets trouvés s'ils n'existent pas dans la base de données GitLab :

   ```shell
   bundle exec rake gitlab:cleanup:remote_upload_files RAILS_ENV=production
   ```

1. Si vous êtes sûr de vouloir supprimer ces fichiers et retirer tous les fichiers téléversés non référencés, exécutez :

   > [!warning]
   > L'action suivante est irréversible.

   ```shell
   bundle exec rake gitlab:cleanup:remote_upload_files RAILS_ENV=production DRY_RUN=false
   ```

### Tronquer les noms de fichiers référencés par la base de données {#truncate-the-filenames-referenced-by-the-database}

Vous devez tronquer les fichiers référencés par la base de données qui causent le problème. Les noms de fichiers référencés par la base de données sont stockés :

- Dans la table `uploads`.
- Dans les références trouvées. Toute référence trouvée dans d'autres tables et colonnes de la base de données.
- Sur le système de fichiers.

Tronquez les noms de fichiers dans la table `uploads` :

1. Accédez à la console de base de données :

   Pour le package Linux (Omnibus) :

   ```shell
   sudo gitlab-rails dbconsole --database main
   ```

   Pour les installations auto-compilées :

   ```shell
   sudo -u git -H bundle exec rails dbconsole -e production --database main
   ```

1. Recherchez dans la table `uploads` les noms de fichiers de plus de 246 caractères :

   La requête suivante sélectionne les enregistrements `uploads` dont les noms de fichiers dépassent 246 caractères par lots de 0 à 10000. Cela améliore les performances sur les grandes instances GitLab avec des tables contenant des milliers d'enregistrements.

   ```sql
   CREATE TEMP TABLE uploads_with_long_filenames AS
   SELECT ROW_NUMBER() OVER(ORDER BY id) row_id, id, path
   FROM uploads AS u
   WHERE LENGTH((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1]) > 246;

   CREATE INDEX ON uploads_with_long_filenames(row_id);

   SELECT
      u.id,
      u.path,
      -- Current filename
      (regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1] AS current_filename,
      -- New filename
      CONCAT(
         LEFT(SPLIT_PART((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1], '.', 1), 242),
         COALESCE(SUBSTRING((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1] FROM '\.(?:.(?!\.))+$'))
      ) AS new_filename,
      -- New path
      CONCAT(
         COALESCE((regexp_match(u.path, '(.*\/).*'))[1], ''),
         CONCAT(
            LEFT(SPLIT_PART((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1], '.', 1), 242),
            COALESCE(SUBSTRING((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1] FROM '\.(?:.(?!\.))+$'))
         )
      ) AS new_path
   FROM uploads_with_long_filenames AS u
   WHERE u.row_id > 0 AND u.row_id <= 10000;
   ```

   Exemple de résultat :

   ```postgresql
   -[ RECORD 1 ]----+--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   id               | 34
   path             | public/@hashed/loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisit.txt
   current_filename | loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisit.txt
   new_filename     | loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelits.txt
   new_path         | public/@hashed/loremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelitsedvulputatemisitloremipsumdolorsitametconsecteturadipiscingelitseddoeiusmodtemporincididuntutlaboreetdoloremagnaaliquaauctorelits.txt
   ```

   Où :

   - `current_filename` : un nom de fichier de plus de 246 caractères.
   - `new_filename` : un nom de fichier tronqué à 246 caractères maximum.
   - `new_path` : nouveau chemin tenant compte de `new_filename` (tronqué).

   Après avoir validé les résultats du lot, vous devez modifier la taille du lot (`row_id`) en utilisant la séquence de nombres suivante (10000 à 20000). Répétez ce processus jusqu'à atteindre le dernier enregistrement dans la table `uploads`.

1. Renommez les fichiers trouvés dans la table `uploads` des noms de fichiers longs vers les nouveaux noms de fichiers tronqués. La requête suivante annule la mise à jour afin que vous puissiez vérifier les résultats en toute sécurité dans un wrapper de transaction :

   ```sql
   CREATE TEMP TABLE uploads_with_long_filenames AS
   SELECT ROW_NUMBER() OVER(ORDER BY id) row_id, path, id
   FROM uploads AS u
   WHERE LENGTH((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1]) > 246;

   CREATE INDEX ON uploads_with_long_filenames(row_id);

   BEGIN;
   WITH updated_uploads AS (
      UPDATE uploads
      SET
         path =
         CONCAT(
            COALESCE((regexp_match(updatable_uploads.path, '(.*\/).*'))[1], ''),
            CONCAT(
               LEFT(SPLIT_PART((regexp_match(updatable_uploads.path, '[^\\/:*?"<>|\r\n]+$'))[1], '.', 1), 242),
               COALESCE(SUBSTRING((regexp_match(updatable_uploads.path, '[^\\/:*?"<>|\r\n]+$'))[1] FROM '\.(?:.(?!\.))+$'))
            )
         )
      FROM
         uploads_with_long_filenames AS updatable_uploads
      WHERE
         uploads.id = updatable_uploads.id
      AND updatable_uploads.row_id > 0 AND updatable_uploads.row_id  <= 10000
      RETURNING uploads.*
   )
   SELECT id, path FROM updated_uploads;
   ROLLBACK;
   ```

   Après avoir validé les résultats de la mise à jour du lot, vous devez modifier la taille du lot (`row_id`) en utilisant la séquence de nombres suivante (10000 à 20000). Répétez ce processus jusqu'à atteindre le dernier enregistrement dans la table `uploads`.

1. Validez que les nouveaux noms de fichiers issus de la requête précédente sont bien ceux attendus. Si vous êtes sûr de vouloir tronquer les enregistrements trouvés à l'étape précédente à 246 caractères, exécutez ce qui suit :

   > [!warning]
   > L'action suivante est irréversible.

   ```sql
   CREATE TEMP TABLE uploads_with_long_filenames AS
   SELECT ROW_NUMBER() OVER(ORDER BY id) row_id, path, id
   FROM uploads AS u
   WHERE LENGTH((regexp_match(u.path, '[^\\/:*?"<>|\r\n]+$'))[1]) > 246;

   CREATE INDEX ON uploads_with_long_filenames(row_id);

   UPDATE uploads
   SET
   path =
      CONCAT(
         COALESCE((regexp_match(updatable_uploads.path, '(.*\/).*'))[1], ''),
         CONCAT(
            LEFT(SPLIT_PART((regexp_match(updatable_uploads.path, '[^\\/:*?"<>|\r\n]+$'))[1], '.', 1), 242),
            COALESCE(SUBSTRING((regexp_match(updatable_uploads.path, '[^\\/:*?"<>|\r\n]+$'))[1] FROM '\.(?:.(?!\.))+$'))
         )
      )
   FROM
   uploads_with_long_filenames AS updatable_uploads
   WHERE
   uploads.id = updatable_uploads.id
   AND updatable_uploads.row_id > 0 AND updatable_uploads.row_id  <= 10000;
   ```

   Après avoir terminé la mise à jour du lot, vous devez modifier la taille du lot (`updatable_uploads.row_id`) en utilisant la séquence de nombres suivante (10000 à 20000). Répétez ce processus jusqu'à atteindre le dernier enregistrement dans la table `uploads`.

Tronquez les noms de fichiers dans les références trouvées :

1. Vérifiez si ces enregistrements sont référencés quelque part. Une façon de procéder est de vider la base de données et de rechercher le nom du répertoire parent et le nom du fichier :

   1. Pour vider votre base de données, vous pouvez utiliser la commande suivante comme exemple :

      ```shell
      pg_dump -h /var/opt/gitlab/postgresql/ -d gitlabhq_production > gitlab-dump.tmp
      ```

   1. Vous pouvez ensuite rechercher les références à l'aide de la commande `grep`. Combiner le répertoire parent et le nom du fichier peut être une bonne idée. Par exemple :

      ```shell
      grep public/alongfilenamehere.txt gitlab-dump.tmp
      ```

1. Remplacez ces noms de fichiers longs par les nouveaux noms de fichiers obtenus en interrogeant la table `uploads`.

Tronquez les noms de fichiers sur le système de fichiers. Vous devez renommer manuellement les fichiers dans votre système de fichiers avec les nouveaux noms de fichiers obtenus en interrogeant la table `uploads`.

### Réexécuter la tâche de sauvegarde {#re-run-the-backup-task}

Après avoir suivi toutes les étapes précédentes, réexécutez la tâche de sauvegarde.

## La restauration de la sauvegarde de la base de données échoue lorsque `pg_stat_statements` était précédemment activé {#restoring-database-backup-fails-when-pg_stat_statements-was-previously-enabled}

La sauvegarde GitLab de la base de données PostgreSQL inclut toutes les instructions SQL nécessaires pour activer les extensions qui étaient précédemment activées dans la base de données.

L'extension `pg_stat_statements` ne peut être activée ou désactivée que par un utilisateur PostgreSQL ayant le rôle `superuser`. Étant donné que le processus de restauration utilise un utilisateur de base de données avec des permissions limitées, il ne peut pas exécuter les instructions SQL suivantes :

```sql
DROP EXTENSION IF EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;
```

Lors de la tentative de restauration de la sauvegarde dans une instance PostgreSQL qui ne dispose pas de l'extension `pg_stats_statements`, le message d'erreur suivant s'affiche :

```plaintext
ERROR: permission denied to create extension "pg_stat_statements"
HINT: Must be superuser to create this extension.
ERROR: extension "pg_stat_statements" does not exist
```

Lors de la tentative de restauration dans une instance où l'extension `pg_stats_statements` est activée, l'étape de nettoyage échoue avec un message d'erreur similaire au suivant :

```plaintext
rake aborted!
ActiveRecord::StatementInvalid: PG::InsufficientPrivilege: ERROR: must be owner of view pg_stat_statements
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:42:in `block (4 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:41:in `each'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:41:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/backup.rake:71:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
Caused by:
PG::InsufficientPrivilege: ERROR: must be owner of view pg_stat_statements
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:42:in `block (4 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:41:in `each'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/db.rake:41:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/service/gitlab-rails/lib/tasks/gitlab/backup.rake:71:in `block (3 levels) in <top (required)>'
/opt/gitlab/embedded/bin/bundle:23:in `load'
/opt/gitlab/embedded/bin/bundle:23:in `<main>'
Tasks: TOP => gitlab:db:drop_tables
(See full trace by running task with --trace)
```

### Empêcher le fichier de dump d'inclure `pg_stat_statements` {#prevent-the-dump-file-to-include-pg_stat_statements}

Pour éviter l'inclusion de l'extension dans le fichier de dump PostgreSQL faisant partie du bundle de sauvegarde, activez l'extension dans tout schéma sauf le schéma `public` :

```sql
CREATE SCHEMA adm;
CREATE EXTENSION pg_stat_statements SCHEMA adm;
```

Si l'extension était précédemment activée dans le schéma `public`, déplacez-la vers un nouveau schéma :

```sql
CREATE SCHEMA adm;
ALTER EXTENSION pg_stat_statements SET SCHEMA adm;
```

Pour interroger les données `pg_stat_statements` après avoir modifié le schéma, préfixez le nom de la vue avec le nouveau schéma :

```sql
SELECT * FROM adm.pg_stat_statements limit 0;
```

Pour le rendre compatible avec des solutions de surveillance tierces qui s'attendent à ce qu'il soit activé dans le schéma `public`, vous devez l'inclure dans le `search_path` :

```sql
set search_path to public,adm;
```

### Corriger un fichier de dump existant pour supprimer les références à `pg_stat_statements` {#fix-an-existing-dump-file-to-remove-references-to-pg_stat_statements}

Pour corriger un fichier de sauvegarde existant, effectuez les modifications suivantes :

1. Extrayez de la sauvegarde le fichier suivant : `db/database.sql.gz`.
1. Décompressez le fichier ou utilisez un éditeur capable de le gérer compressé.
1. Supprimez les lignes suivantes, ou des lignes similaires :

   ```sql
   CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;
   ```

   ```sql
   COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';
   ```

1. Enregistrez les modifications et recompressez le fichier.
1. Mettez à jour le fichier de sauvegarde avec le fichier modifié `db/database.sql.gz`.
