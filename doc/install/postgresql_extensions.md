---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Managing PostgreSQL extensions **(FREE SELF)**

This guide documents how to manage PostgreSQL extensions for installations with an external
PostgreSQL database.

The following extensions must be loaded into the GitLab database:

| Extension    | Minimum GitLab version |
|--------------|------------------------|
| `pg_trgm`    | 8.6                    |
| `btree_gist` | 13.1                   |
| `plpgsql`    | 11.7                   |

In order to install extensions, PostgreSQL requires the user to have superuser privileges.
Typically, the GitLab database user is not a superuser. Therefore, regular database migrations
cannot be used in installing extensions and instead, extensions have to be installed manually
prior to upgrading GitLab to a newer version.

## Installing PostgreSQL extensions manually

In order to install a PostgreSQL extension, this procedure should be followed:

1. Connect to the GitLab PostgreSQL database using a superuser, for example:

   ```shell
   sudo gitlab-psql -d gitlabhq_production
   ```

1. Install the extension (`btree_gist` in this example) using [`CREATE EXTENSION`](https://www.postgresql.org/docs/11/sql-createextension.html):

   ```sql
   CREATE EXTENSION IF NOT EXISTS btree_gist
   ```

1. Verify installed extensions:

   ```shell
    gitlabhq_production=# \dx
                                        List of installed extensions
        Name    | Version |   Schema   |                            Description
    ------------+---------+------------+-------------------------------------------------------------------
    btree_gist | 1.5     | public     | support for indexing common datatypes in GiST
    pg_trgm    | 1.4     | public     | text similarity measurement and index searching based on trigrams
    plpgsql    | 1.0     | pg_catalog | PL/pgSQL procedural language
    (3 rows)
   ```

On some systems you may need to install an additional package (for example,
`postgresql-contrib`) for certain extensions to become available.

## A typical migration failure scenario

The following is an example of a situation when the extension hasn't been installed before running migrations.
In this scenario, the database migration fails to create the extension `btree_gist` because of insufficient
privileges.

```shell
== 20200515152649 EnableBtreeGistExtension: migrating =========================
-- execute("CREATE EXTENSION IF NOT EXISTS btree_gist")

GitLab requires the PostgreSQL extension 'btree_gist' installed in database 'gitlabhq_production', but
the database user is not allowed to install the extension.

You can either install the extension manually using a database superuser:

  CREATE EXTENSION IF NOT EXISTS btree_gist

Or, you can solve this by logging in to the GitLab database (gitlabhq_production) using a superuser and running:

    ALTER regular WITH SUPERUSER

This query will grant the user superuser permissions, ensuring any database extensions
can be installed through migrations.
```

In order to recover from this situation, the extension needs to be installed manually using a superuser, and
the database migration (or GitLab upgrade) can be retried afterwards.
