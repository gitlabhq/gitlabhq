---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gérer les extensions PostgreSQL
description: Installez les extensions PostgreSQL requises et recommandées pour GitLab Self-Managed.
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab nécessite des extensions PostgreSQL spécifiques dans chaque base de données. Pour la liste des extensions requises et les versions minimales de GitLab, consultez [Exigences PostgreSQL](../../install/requirements.md#extensions).

Pour installer des extensions, PostgreSQL nécessite des privilèges de superutilisateur. L'utilisateur de la base de données GitLab n'est généralement pas un superutilisateur, vous devez donc installer les extensions manuellement avant de mettre à niveau GitLab.

## Installer les extensions requises {#install-required-extensions}

1. Connectez-vous à la base de données PostgreSQL de GitLab en tant que superutilisateur, par exemple :

   ```shell
   sudo gitlab-psql -d gitlabhq_production
   ```

1. Installez l'extension (`btree_gist` dans cet exemple) en utilisant [`CREATE EXTENSION`](https://www.postgresql.org/docs/16/sql-createextension.html) :

   ```sql
   CREATE EXTENSION IF NOT EXISTS btree_gist
   ```

1. Vérifiez les extensions installées :

   ```shell
   gitlabhq_production=# \dx
   ```

Sur certains systèmes, vous devrez peut-être installer un package supplémentaire (par exemple, `postgresql-contrib`) pour que certaines extensions soient disponibles.

## Activer pg_stat_statements {#enable-pg_stat_statements}

`pg_stat_statements` est recommandé pour résoudre les problèmes de requêtes de base de données lentes. Son activation nécessite des privilèges de superutilisateur et un redémarrage de PostgreSQL.

1. Ajoutez `pg_stat_statements` à `shared_preload_libraries` dans `postgresql.conf`. Pour les installations avec le package Linux, ajoutez ce qui suit à `/etc/gitlab/gitlab.rb` :

   ```ruby
   postgresql['shared_preload_libraries'] = 'pg_stat_statements'
   ```

1. Redémarrez PostgreSQL.
1. Créez l'extension en tant que superutilisateur :

   ```sql
   CREATE EXTENSION IF NOT EXISTS pg_stat_statements
   ```

Pour plus d'informations, consultez [Activer les données statistiques de requêtes optionnelles](../raketasks/maintenance.md#enable-optional-query-statistics-data).

## Dépannage {#troubleshooting}

Lorsque vous travaillez avec des extensions PostgreSQL, vous pourriez rencontrer le problème suivant.

### La migration échoue car une extension est manquante {#migration-fails-because-an-extension-is-missing}

Si une migration de base de données échoue parce qu'une extension est manquante, installez-la manuellement en tant que superutilisateur, puis relancez les migrations :

```shell
sudo gitlab-rake db:migrate
```
