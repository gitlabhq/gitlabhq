---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Configurer GitLab à l'aide d'un service PostgreSQL externe"
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Si vous hébergez GitLab chez un fournisseur cloud, vous pouvez éventuellement utiliser un service géré pour PostgreSQL. Par exemple, AWS propose un service de base de données relationnelle géré (RDS) qui exécute PostgreSQL.

Vous pouvez également choisir de gérer votre propre instance ou cluster PostgreSQL séparément du package Linux.

Si vous utilisez un service géré dans le cloud ou fournissez votre propre instance PostgreSQL, configurez PostgreSQL conformément au [document sur les exigences de la base de données](../../install/requirements.md#postgresql).

## Base de données GitLab Rails {#gitlab-rails-database}

Après avoir configuré le serveur PostgreSQL externe :

1. Connectez-vous à votre serveur de base de données.
1. Configurez un utilisateur `gitlab` avec le mot de passe de votre choix, créez la base de données `gitlabhq_production` et faites de cet utilisateur le propriétaire de la base de données. Vous trouverez un exemple de cette configuration dans la [documentation d'installation à partir des sources](../../install/self_compiled/_index.md#7-database).
1. Si vous utilisez un service géré dans le cloud, vous devrez peut-être accorder des rôles supplémentaires à votre utilisateur `gitlab` :
   - Amazon RDS requiert le rôle [`rds_superuser`](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html#Appendix.PostgreSQL.CommonDBATasks.Roles).
   - Azure Database for PostgreSQL requiert le rôle [`azure_pg_admin`](https://learn.microsoft.com/en-us/azure/postgresql/single-server/how-to-create-users#how-to-create-additional-admin-users-in-azure-database-for-postgresql). Azure Database for PostgreSQL - Flexible Server requiert [l'autorisation des extensions avant leur installation](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-extensions#how-to-use-postgresql-extensions).
   - Google Cloud SQL requiert le rôle [`cloudsqlsuperuser`](https://cloud.google.com/sql/docs/postgres/users#default-users).

   Ceci est nécessaire pour l'installation des extensions lors de l'installation et des mises à niveau. Vous pouvez également [installer manuellement les extensions requises](extensions.md).
1. Configurez les serveurs d'applications GitLab avec les informations de connexion appropriées pour votre service PostgreSQL externe dans votre fichier `/etc/gitlab/gitlab.rb` :

   ```ruby
   # Disable the bundled Omnibus provided PostgreSQL
   postgresql['enable'] = false

   # PostgreSQL connection details
   gitlab_rails['db_adapter'] = 'postgresql'
   gitlab_rails['db_encoding'] = 'unicode'
   gitlab_rails['db_host'] = '10.1.0.5' # IP/hostname of database server
   gitlab_rails['db_port'] = 5432
   gitlab_rails['db_password'] = 'DB password'
   ```

   Pour plus d'informations sur les configurations multi-nœuds de GitLab, consultez les [architectures de référence](../reference_architectures/_index.md).

1. Reconfigurer pour que les modifications prennent effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Redémarrez PostgreSQL pour activer le port TCP :

   ```shell
   sudo gitlab-ctl restart
   ```

## Base de données de métadonnées du registre de conteneurs {#container-registry-metadata-database}

Si vous prévoyez d'utiliser la [base de données de métadonnées du registre de conteneurs](../packages/container_registry_metadata_database.md), vous devez également créer la base de données et l'utilisateur du registre.

Après avoir configuré le serveur PostgreSQL externe :

1. Connectez-vous à votre serveur de base de données.
1. Utilisez les commandes SQL suivantes pour créer l'utilisateur et la base de données :

   ```sql
   -- Create the registry user
   CREATE USER registry WITH PASSWORD '<your_registry_password>';

   -- Create the registry database
   CREATE DATABASE registry OWNER registry;
   ```

1. Pour les services gérés dans le cloud, accordez les rôles supplémentaires nécessaires :

   {{< tabs >}}

   {{< tab title="Amazon RDS" >}}

   ```sql
   GRANT rds_superuser TO registry;
   ```

   {{< /tab >}}

   {{< tab title="Azure database" >}}

   ```sql
   GRANT azure_pg_admin TO registry;
   ```

   {{< /tab >}}

   {{< tab title="Google Cloud SQL" >}}

   ```sql
   GRANT cloudsqlsuperuser TO registry;
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. Vous pouvez maintenant activer et commencer à utiliser la base de données de métadonnées du registre de conteneurs.

## Dépannage {#troubleshooting}

### Résoudre l'erreur `SSL SYSCALL error: EOF detected` {#resolve-ssl-syscall-error-eof-detected-error}

Lors de l'utilisation d'une instance PostgreSQL externe, vous pouvez rencontrer une erreur comme :

```shell
pg_dump: error: Error message from server: SSL SYSCALL error: EOF detected
```

Pour résoudre cette erreur, assurez-vous de respecter les [exigences minimales de PostgreSQL](../../install/requirements.md#postgresql). Après avoir mis à niveau votre instance RDS vers une [version prise en charge](../../install/requirements.md#postgresql), vous devriez pouvoir effectuer une sauvegarde sans cette erreur. Consultez le [ticket 64763](https://gitlab.com/gitlab-org/gitlab/-/issues/364763) pour plus d'informations.
