---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Mise à niveau des bases de données PostgreSQL externes
---

Lors de la mise à niveau de votre moteur de base de données PostgreSQL, il est important de suivre toutes les étapes recommandées par la communauté PostgreSQL et votre fournisseur cloud. Deux types de mises à niveau existent pour les bases de données PostgreSQL :

- Mises à niveau de versions mineures :  Celles-ci incluent uniquement des correctifs de bogues et de sécurité. Elles sont toujours rétrocompatibles avec le modèle de base de données de votre application existante.

  Le processus de mise à niveau de version mineure consiste à remplacer les binaires PostgreSQL et à redémarrer le service de base de données. Le répertoire de données reste inchangé.

- Mises à niveau de versions majeures :  Celles-ci modifient le format de stockage interne et le catalogue de la base de données. Par conséquent, les statistiques d'objets utilisées par l'optimiseur de requêtes [ne sont pas transférées vers la nouvelle version](https://www.postgresql.org/docs/16/pgupgrade.html) et doivent être reconstruites avec `ANALYZE`.

  Ne pas suivre le processus de mise à niveau de version majeure documenté entraîne souvent de mauvaises performances de la base de données et une utilisation élevée du processeur sur le serveur de base de données.

Tous les principaux fournisseurs cloud prennent en charge les mises à niveau majeures en place des instances de base de données, en utilisant l'utilitaire `pg_upgrade`. Cependant, vous devez suivre les étapes de pré et post-mise à niveau pour réduire le risque de dégradation des performances ou d'interruption de la base de données.

Lisez attentivement les étapes de mise à niveau de version majeure de votre plateforme de base de données externe :

- [Amazon RDS for PostgreSQL](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_UpgradeDBInstance.PostgreSQL.html#USER_UpgradeDBInstance.PostgreSQL.MajorVersion.Process)
- [Azure Database for PostgreSQL Flexible Server](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-major-version-upgrade)
- [Google Cloud SQL for PostgreSQL](https://cloud.google.com/sql/docs/postgres/upgrade-major-db-version-inplace)
- [Communauté PostgreSQL `pg_upgrade`](https://www.postgresql.org/docs/16/pgupgrade.html)

## Toujours exécuter `ANALYZE` sur votre base de données après une mise à niveau de version majeure {#always-analyze-your-database-after-a-major-version-upgrade}

Il est obligatoire d'exécuter l'[opération `ANALYZE`](https://www.postgresql.org/docs/16/sql-analyze.html) pour actualiser la table `pg_statistic` après une mise à niveau de version majeure, car les statistiques de l'optimiseur [ne sont pas transférées par `pg_upgrade`](https://www.postgresql.org/docs/16/pgupgrade.html). Cette opération doit être effectuée pour toutes les bases de données sur le service/l'instance/le cluster PostgreSQL mis à niveau.

Lorsque vous planifiez votre fenêtre de maintenance, vous devez inclure la durée de `ANALYZE`, car cette opération peut dégrader significativement les performances de GitLab.

Pour accélérer l'opération `ANALYZE`, utilisez l'[utilitaire `vacuumdb`](https://www.postgresql.org/docs/16/app-vacuumdb.html), avec `--analyze-only --jobs=njobs` pour exécuter la commande `ANALYZE` en parallèle en lançant `njobs` commandes simultanément.
