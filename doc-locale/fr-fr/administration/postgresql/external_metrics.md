---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configuration de la surveillance et de la journalisation pour les bases de données externes
---

Les systèmes de bases de données PostgreSQL externes disposent de différentes options de journalisation pour surveiller les performances et résoudre les problèmes, mais celles-ci ne sont pas activées par défaut. Dans cette section, nous fournissons des recommandations pour PostgreSQL autogéré, ainsi que des recommandations pour certains grands fournisseurs de services PostgreSQL gérés.

## Paramètres de journalisation PostgreSQL recommandés {#recommended-postgresql-logging-settings}

Vous devez activer les paramètres de journalisation suivants :

- `log_statement=ddl` : journalise les modifications de la définition du modèle de base de données (DDL), telles que `CREATE`, `ALTER` ou `DROP` d'objets. Cela permet de suivre les modifications récentes du modèle susceptibles de causer des problèmes de performances, et d'identifier les failles de sécurité et les erreurs humaines.
- `log_lock_waits=on` : journalise les processus maintenant des [verrous](https://www.postgresql.org/docs/16/explicit-locking.html) pendant de longues périodes, cause fréquente de mauvaises performances des requêtes.
- `log_temp_files=0` : journalise l'utilisation de fichiers temporaires importants et inhabituels pouvant indiquer de mauvaises performances des requêtes.
- `log_autovacuum_min_duration=0` : journalise toutes les exécutions d'autovacuum. Autovacuum est un composant clé pour les performances globales du moteur PostgreSQL. Essentiel pour le dépannage et l'optimisation si les tuples morts ne sont pas supprimés des tables.
- `log_min_duration_statement=1000` : journalise les requêtes lentes (plus lentes qu'1 seconde).

La description complète de ces paramètres est disponible dans la [documentation de signalement des erreurs et de journalisation de PostgreSQL](https://www.postgresql.org/docs/16/runtime-config-logging.html#RUNTIME-CONFIG-LOGGING-WHAT).

## Amazon RDS {#amazon-rds}

Le service Amazon Relational Database Service (RDS) fournit un grand nombre de [métriques de surveillance](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Monitoring.html) et d'[interfaces de journalisation](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_Monitor_Logs_Events.html). Voici quelques éléments que vous devez configurer :

- Modifiez tous les [paramètres de journalisation PostgreSQL recommandés](#recommended-postgresql-logging-settings) via les [RDS Parameter Groups](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithDBInstanceParamGroups.html).
  - Comme les paramètres de journalisation recommandés sont [dynamiques dans RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.Parameters.html), vous n'avez pas besoin de redémarrer après avoir modifié ces paramètres.
  - Les journaux PostgreSQL peuvent être consultés via la [console RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/logs-events-streams-console.html).
- L'activation de [RDS performance insight](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_PerfInsights.html) vous permet de visualiser la charge de votre base de données avec de nombreuses métriques de performances importantes du moteur de base de données PostgreSQL.
- Activez [RDS Enhanced Monitoring](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_Monitoring.OS.html) pour surveiller les métriques du système d'exploitation. Ces métriques peuvent indiquer des goulots d'étranglement dans le matériel sous-jacent et le système d'exploitation qui impactent les performances de votre base de données.
  - Dans les environnements de production, définissez l'intervalle de surveillance à 10 secondes (ou moins) pour capturer les micro-pics d'utilisation des ressources pouvant être à l'origine de nombreux problèmes de performances. Définissez `Granularity=10` dans la console ou `monitoring-interval=10` dans l'interface CLI.
