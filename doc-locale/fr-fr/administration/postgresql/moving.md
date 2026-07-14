---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Déplacement des bases de données GitLab vers une autre instance PostgreSQL
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Il est parfois nécessaire de déplacer vos bases de données d'une instance PostgreSQL vers une autre. Par exemple, si vous utilisez AWS Aurora et que vous vous préparez à activer l'équilibrage de charge de base de données, vous devez déplacer vos bases de données vers RDS pour PostgreSQL.

Pour déplacer des bases de données d'une instance vers une autre :

1. Rassemblez les informations sur les endpoints PostgreSQL source et de destination :

   ```shell
   SRC_PGHOST=<source postgresql host>
   SRC_PGUSER=<source postgresql user>

   DST_PGHOST=<destination postgresql host>
   DST_PGUSER=<destination postgresql user>
   ```

1. Arrêtez GitLab :

   ```shell
   sudo gitlab-ctl stop
   ```

1. Effectuez un dump des bases de données depuis la source :

   ```shell
   /opt/gitlab/embedded/bin/pg_dump -h $SRC_PGHOST -U $SRC_PGUSER -c -C -f gitlabhq_production.sql gitlabhq_production
   /opt/gitlab/embedded/bin/pg_dump -h $SRC_PGHOST -U $SRC_PGUSER -c -C -f praefect_production.sql praefect_production
   ```

   > [!note]
   > Dans de rares cas, vous pouvez constater des problèmes de performance de base de données après avoir effectué un `pg_dump` et une restauration. Cela peut se produire car `pg_dump` ne contient pas les statistiques [utilisées par l'optimiseur pour prendre des décisions de planification des requêtes](https://www.postgresql.org/docs/16/app-pgdump.html). Si les performances se dégradent après une restauration, résolvez le problème en identifiant la requête problématique, puis en exécutant ANALYZE sur les tables utilisées par la requête.

1. Restaurez les bases de données vers la destination (cela écrase toutes les bases de données existantes portant les mêmes noms) :

   ```shell
   /opt/gitlab/embedded/bin/psql -h $DST_PGHOST -U $DST_PGUSER -f praefect_production.sql postgres
   /opt/gitlab/embedded/bin/psql -h $DST_PGHOST -U $DST_PGUSER -f gitlabhq_production.sql postgres
   ```

1. Facultatif. Si vous migrez d'une base de données qui n'utilise pas PgBouncer vers une base de données qui l'utilise, vous devez ajouter manuellement une [fonction `pg_shadow_lookup`](../gitaly/praefect/configure.md#manual-database-setup) à la base de données de l'application (généralement `gitlabhq_production`).
1. Configurez les serveurs d'applications GitLab avec les informations de connexion appropriées pour votre instance PostgreSQL de destination dans votre fichier `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['db_host'] = '<destination postgresql host>'
   ```

   Pour plus d'informations sur les configurations GitLab multi-nœuds, consultez les [architectures de référence](../reference_architectures/_index.md).

1. Reconfigurez pour que les modifications prennent effet :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Redémarrez GitLab :

   ```shell
   sudo gitlab-ctl start
   ```
