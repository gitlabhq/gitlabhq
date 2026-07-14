---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Mise à niveau des systèmes d'exploitation pour PostgreSQL"
---

> [!warning]
> [Geo](../geo/_index.md) ne peut pas être utilisé pour migrer une base de données PostgreSQL d'un système d'exploitation vers un autre. Si vous tentez de le faire, le site secondaire peut sembler être répliqué à 100 % alors qu'en réalité certaines données ne sont pas répliquées, ce qui entraîne une perte de données. Cela est dû au fait que Geo dépend de la réplication en flux PostgreSQL, qui souffre des limitations décrites dans ce document. Voir aussi [Geo Troubleshooting - Check OS locale data compatibility](../geo/replication/troubleshooting/common.md#check-os-locale-data-compatibility).

Si vous mettez à niveau le système d'exploitation sur lequel PostgreSQL s'exécute, tout [changement dans les données de paramètres régionaux peut corrompre vos index de base de données](https://wiki.postgresql.org/wiki/Locale_data_changes). En particulier, la mise à niveau vers `glibc` 2.28 est susceptible de causer ce problème. Pour éviter ce problème, effectuez la migration en utilisant l'une des options suivantes, grossièrement dans l'ordre de complexité :

- Recommandé. [Sauvegarde et restauration](#backup-and-restore).
- Recommandé. [Reconstruire tous les index](#rebuild-all-indexes).
- [Reconstruire uniquement les index affectés](#rebuild-only-affected-indexes).

Assurez-vous d'effectuer une sauvegarde avant de tenter toute migration, et validez le processus de migration dans un environnement similaire à la production. Si la durée de l'interruption de service peut poser un problème, envisagez de chronométrer différentes approches avec une copie des données de production dans un environnement similaire à la production.

Si vous exécutez un environnement GitLab à grande échelle et qu'aucun autre service ne s'exécute sur les nœuds où PostgreSQL est exécuté, nous vous recommandons de mettre à niveau le système d'exploitation des nœuds PostgreSQL séparément. Pour réduire la complexité et les risques, ne combinez pas la procédure avec d'autres modifications, en particulier si ces modifications ne nécessitent pas d'interruption de service, comme la mise à niveau du système d'exploitation des nœuds exécutant uniquement Puma ou Sidekiq.

Pour plus d'informations sur la manière dont GitLab prévoit de résoudre ce problème, consultez l'[epic 8573](https://gitlab.com/groups/gitlab-org/-/epics/8573).

## Sauvegarde et restauration {#backup-and-restore}

La sauvegarde et la restauration recrée l'intégralité de la base de données, y compris les index.

1. Planifiez une fenêtre d'interruption de service programmée. Sur tous les nœuds, arrêtez les services GitLab inutiles :

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. Sauvegardez la base de données PostgreSQL avec `pg_dump` ou l'[outil de sauvegarde GitLab, avec tous les types de données sauf `db` exclus](../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup) (de sorte que seule la base de données soit sauvegardée).
1. Sur tous les nœuds PostgreSQL, mettez à niveau le système d'exploitation.
1. Sur tous les nœuds PostgreSQL, [mettez à jour les sources du package GitLab](../../update/package/_index.md) après la mise à niveau du système d'exploitation.
1. Sur tous les nœuds PostgreSQL, installez le nouveau package GitLab de la même version de GitLab.
1. Restaurez la base de données PostgreSQL à partir de la sauvegarde.
1. Sur tous les nœuds, démarrez GitLab.

Avantages :

- Simple.
- Supprime tout gonflement de la base de données dans les index et les tables, réduisant l'utilisation du disque.

Inconvénients :

- L'interruption de service augmente avec la taille de la base de données, ce qui peut devenir problématique à un certain point. Cela dépend de nombreux facteurs, mais si votre base de données dépasse 100 Go, cela peut prendre de l'ordre de 24 heures.

### Sauvegarde et restauration, avec les sites secondaires Geo {#backup-and-restore-with-geo-secondary-sites}

1. Planifiez une fenêtre d'interruption de service programmée. Sur tous les nœuds de tous les sites, arrêtez les services GitLab inutiles :

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. Sur le site principal, sauvegardez la base de données PostgreSQL avec `pg_dump` ou l'[outil de sauvegarde GitLab, avec tous les types de données sauf `db` exclus](../backup_restore/backup_gitlab.md#excluding-specific-data-from-the-backup) (de sorte que seule la base de données soit sauvegardée).
1. Sur tous les nœuds PostgreSQL de tous les sites, mettez à niveau le système d'exploitation.
1. Sur tous les nœuds PostgreSQL de tous les sites, [mettez à jour les sources du package GitLab](../../update/package/_index.md) après la mise à niveau du système d'exploitation.
1. Sur tous les nœuds PostgreSQL de tous les sites, installez le nouveau package GitLab de la même version de GitLab.
1. Sur le site principal, restaurez la base de données PostgreSQL à partir de la sauvegarde.
1. Facultativement, commencez à utiliser le site principal, au risque de ne pas avoir de site secondaire comme secours à chaud.
1. Configurez à nouveau la réplication en flux PostgreSQL vers les sites secondaires.
1. Si les sites secondaires reçoivent du trafic des utilisateurs, laissez les bases de données en lecture-réplica se rattraper avant de démarrer GitLab.
1. Sur tous les nœuds de tous les sites, démarrez GitLab.

## Reconstruire tous les index {#rebuild-all-indexes}

[Reconstruire tous les index](https://www.postgresql.org/docs/16/sql-reindex.html).

1. Planifiez une fenêtre d'interruption de service programmée. Sur tous les nœuds, arrêtez les services GitLab inutiles :

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. Sur tous les nœuds PostgreSQL, mettez à niveau le système d'exploitation.
1. Sur tous les nœuds PostgreSQL, [mettez à jour les sources du package GitLab](../../update/package/_index.md) après la mise à niveau du système d'exploitation.
1. Sur tous les nœuds PostgreSQL, installez le nouveau package GitLab de la même version de GitLab.
1. Dans une [console de base de données](../troubleshooting/postgresql.md#start-a-database-console), reconstruisez tous les index :

   ```sql
   SET statement_timeout = 0;
   REINDEX DATABASE gitlabhq_production;
   ```

1. Après la réindexation de la base de données, la version doit être actualisée pour toutes les collations affectées. Pour mettre à jour le catalogue système afin d'enregistrer la version de collation actuelle :

   ```sql
   ALTER DATABASE gitlabhq_production REFRESH COLLATION VERSION;
   ```

   Les bases de données système telles que `template1` ou `postgres` peuvent également présenter des problèmes de collation au démarrage de PostgreSQL. Vérifiez les indications dans les messages d'erreur et actualisez également les collations dans ces bases de données.

1. Sur tous les nœuds, démarrez GitLab.

Avantages :

- Simple.
- Peut être plus rapide que la sauvegarde et la restauration, selon de nombreux facteurs.
- Supprime tout gonflement de la base de données dans les index, réduisant l'utilisation du disque.

Inconvénients :

- L'interruption de service augmente avec la taille de la base de données, ce qui peut devenir problématique à un certain point.

### Reconstruire tous les index, avec les sites secondaires Geo {#rebuild-all-indexes-with-geo-secondary-sites}

1. Planifiez une fenêtre d'interruption de service programmée. Sur tous les nœuds de tous les sites, arrêtez les services GitLab inutiles :

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. Sur tous les nœuds PostgreSQL, mettez à niveau le système d'exploitation.
1. Sur tous les nœuds PostgreSQL, [mettez à jour les sources du package GitLab](../../update/package/_index.md) après la mise à niveau du système d'exploitation.
1. Sur tous les nœuds PostgreSQL, installez le nouveau package GitLab de la même version de GitLab.
1. Sur le site principal, dans une [console de base de données](../troubleshooting/postgresql.md#start-a-database-console), reconstruisez tous les index :

   ```sql
   SET statement_timeout = 0;
   REINDEX DATABASE gitlabhq_production;
   ```

1. Après la réindexation de la base de données, la version doit être actualisée pour toutes les collations affectées. Pour mettre à jour le catalogue système afin d'enregistrer la version de collation actuelle :

   ```sql
   ALTER DATABASE <database_name> REFRESH COLLATION VERSION;
   ```

1. Si les sites secondaires reçoivent du trafic des utilisateurs, laissez les bases de données en lecture-réplica se rattraper avant de démarrer GitLab.
1. Sur tous les nœuds de tous les sites, démarrez GitLab.

## Reconstruire uniquement les index affectés {#rebuild-only-affected-indexes}

Cette approche est similaire à celle utilisée pour GitLab.com. Pour en savoir plus sur ce processus et sur la façon dont les différents types d'index ont été traités, consultez le billet de blog sur la [mise à niveau du système d'exploitation sur nos clusters de bases de données PostgreSQL](https://about.gitlab.com/blog/upgrading-database-os/).

1. Planifiez une fenêtre d'interruption de service programmée. Sur tous les nœuds, arrêtez les services GitLab inutiles :

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. Sur tous les nœuds PostgreSQL, mettez à niveau le système d'exploitation.
1. Sur tous les nœuds PostgreSQL, [mettez à jour les sources du package GitLab](../../update/package/_index.md) après la mise à niveau du système d'exploitation.
1. Sur tous les nœuds PostgreSQL, installez le nouveau package GitLab de la même version de GitLab.
1. [Déterminez quels index sont affectés](https://wiki.postgresql.org/wiki/Locale_data_changes#What_indexes_are_affected).
1. Dans une [console de base de données](../troubleshooting/postgresql.md#start-a-database-console), réindexez chaque index affecté :

   ```sql
   SET statement_timeout = 0;
   REINDEX INDEX <index name> CONCURRENTLY;
   ```

1. Après la réindexation des index défectueux, la collation doit être actualisée. Pour mettre à jour le catalogue système afin d'enregistrer la version de collation actuelle :

   ```sql
   ALTER DATABASE <database_name> REFRESH COLLATION VERSION;
   ```

1. Sur tous les nœuds, démarrez GitLab.

Avantages :

- L'interruption de service n'est pas consacrée à la reconstruction des index non affectés.

Inconvénients :

- Plus de risques d'erreurs.
- Nécessite une expertise approfondie de PostgreSQL pour gérer les problèmes inattendus lors de la migration.
- Conserve le gonflement de la base de données.

### Reconstruire uniquement les index affectés, avec les sites secondaires Geo {#rebuild-only-affected-indexes-with-geo-secondary-sites}

1. Planifiez une fenêtre d'interruption de service programmée. Sur tous les nœuds de tous les sites, arrêtez les services GitLab inutiles :

   ```shell
   gitlab-ctl stop
   gitlab-ctl start postgresql
   ```

1. Sur tous les nœuds PostgreSQL, mettez à niveau le système d'exploitation.
1. Sur tous les nœuds PostgreSQL, [mettez à jour les sources du package GitLab](../../update/package/_index.md) après la mise à niveau du système d'exploitation.
1. Sur tous les nœuds PostgreSQL, installez le nouveau package GitLab de la même version de GitLab.
1. [Déterminez quels index sont affectés](https://wiki.postgresql.org/wiki/Locale_data_changes#What_indexes_are_affected).
1. Sur le site principal, dans une [console de base de données](../troubleshooting/postgresql.md#start-a-database-console), réindexez chaque index affecté :

   ```sql
   SET statement_timeout = 0;
   REINDEX INDEX <index name> CONCURRENTLY;
   ```

1. Après la réindexation des index défectueux, la collation doit être actualisée. Pour mettre à jour le catalogue système afin d'enregistrer la version de collation actuelle :

   ```sql
   ALTER DATABASE <database_name> REFRESH COLLATION VERSION;
   ```

1. La réplication en flux PostgreSQL existante devrait répliquer les modifications de réindexation vers les bases de données en lecture-réplica.
1. Sur tous les nœuds de tous les sites, démarrez GitLab.

## Vérification des versions de `glibc` {#checking-glibc-versions}

Pour voir quelle version de `glibc` est utilisée, exécutez `ldd --version`.

Le tableau suivant indique les versions de `glibc` fournies pour différents systèmes d'exploitation :

| Système d'exploitation    | Version de `glibc` |
|---------------------|-----------------|
| CentOS 7            | 2.17            |
| RedHat Enterprise 8 | 2.28            |
| RedHat Enterprise 9 | 2.34            |
| Ubuntu 18.04        | 2.27            |
| Ubuntu 20.04        | 2.31            |
| Ubuntu 22.04        | 2.35            |
| Ubuntu 24.04        | 2.39            |

Par exemple, supposons que vous effectuez une mise à niveau de CentOS 7 vers RedHat Enterprise 8. Dans ce cas, l'utilisation de PostgreSQL sur ce système d'exploitation mis à niveau nécessite d'utiliser l'une des deux approches mentionnées, car `glibc` est mis à niveau de 2.17 à 2.28. Le fait de ne pas gérer correctement les modifications de collation entraîne des défaillances importantes dans GitLab, par exemple des runners qui ne récupèrent pas les jobs avec des étiquettes.

D'un autre côté, si PostgreSQL s'exécute déjà sur `glibc` 2.28 ou supérieur sans problème, vos index devraient continuer à fonctionner sans autre action. Par exemple, si vous avez exécuté PostgreSQL sur RedHat Enterprise 8 (`glibc` 2.28) pendant un certain temps et souhaitez effectuer une mise à niveau vers RedHat Enterprise 9 (`glibc` 2.34), il ne devrait pas y avoir de problèmes liés aux collations.

### Vérification des versions de collation de `glibc` {#verifying-glibc-collation-versions}

Pour PostgreSQL 13 et versions ultérieures, vous pouvez vérifier que la version de collation de votre base de données correspond à votre système avec cette requête SQL :

```sql
SELECT collname AS COLLATION_NAME,
       collversion AS VERSION,
       pg_collation_actual_version(oid) AS actual_version
FROM pg_collation
WHERE collprovider = 'c';
```

### Exemple de collation correspondante {#matching-collation-example}

Par exemple, sur un système Ubuntu 22.04, la sortie d'un système correctement indexé ressemble à :

```sql
gitlabhq_production=# SELECT collname AS COLLATION_NAME,
       collversion AS VERSION,
       pg_collation_actual_version(oid) AS actual_version
FROM pg_collation
WHERE collprovider = 'c';
 collation_name | version | actual_version
----------------+---------+----------------
 C              |         |
 POSIX          |         |
 ucs_basic      |         |
 C.utf8         |         |
 en_US.utf8     | 2.35    | 2.35
 en_US          | 2.35    | 2.35
(6 rows)
```

### Exemple de collation non correspondante {#mismatched-collation-example}

D'un autre côté, si vous avez effectué une mise à niveau d'Ubuntu 18.04 vers 22.04 sans réindexation, vous pourriez voir :

```sql
gitlabhq_production=# SELECT collname AS COLLATION_NAME,
       collversion AS VERSION,
       pg_collation_actual_version(oid) AS actual_version
FROM pg_collation
WHERE collprovider = 'c';
 collation_name | version | actual_version
----------------+---------+----------------
 C              |         |
 POSIX          |         |
 ucs_basic      |         |
 C.utf8         |         |
 en_US.utf8     | 2.27    | 2.35
 en_US          | 2.27    | 2.35
(6 rows)
```

## Réplication en flux {#streaming-replication}

Le problème d'index corrompu affecte la réplication en flux PostgreSQL. Vous devez [reconstruire tous les index](#rebuild-all-indexes) ou [reconstruire uniquement les index affectés](#rebuild-only-affected-indexes) avant d'autoriser les lectures sur un réplica avec des données de paramètres régionaux différentes.

## Variantes Geo supplémentaires {#additional-geo-variations}

Les procédures de mise à niveau documentées précédemment ne sont pas gravées dans le marbre. Avec Geo, il existe potentiellement davantage d'options, car il existe une infrastructure redondante. Vous pouvez envisager des modifications adaptées à votre cas d'utilisation, mais veillez à les évaluer par rapport à la complexité supplémentaire que cela engendre. Voici quelques exemples :

Pour réserver un site secondaire comme secours à chaud en cas de sinistre lors de la mise à niveau du système d'exploitation du site principal et de l'autre site secondaire :

1. Isolez les données du site secondaire des modifications apportées sur le site principal :  Mettez en pause le site secondaire.
1. Effectuez la mise à niveau du système d'exploitation sur le site principal.
1. Si la mise à niveau du système d'exploitation échoue et que le site principal est irrécupérable, promouvez le site secondaire, redirigez les utilisateurs vers celui-ci et réessayez plus tard. Cela vous laisse sans site secondaire à jour.

Pour fournir aux utilisateurs un accès en lecture seule à GitLab pendant la mise à niveau du système d'exploitation (interruption de service partielle) :

1. Activez le [Maintenance Mode](../maintenance_mode/_index.md) sur le site principal au lieu de l'arrêter.
1. Promouvez le site secondaire mais ne redirigez pas encore les utilisateurs vers celui-ci.
1. Effectuez la mise à niveau du système d'exploitation sur le site promu.
1. Redirigez les utilisateurs vers le site promu plutôt que vers l'ancien site principal.
1. Configurez l'ancien site principal comme nouveau site secondaire.

> [!warning]
> Même si le site secondaire dispose déjà d'une lecture-réplica de la base de données, vous ne pouvez pas mettre à niveau son système d'exploitation avant la promotion. Si vous tentiez de le faire, le site secondaire pourrait manquer la réplication de certains dépôts Git ou fichiers, en raison des index corrompus. Voir [Réplication en flux](#streaming-replication).
