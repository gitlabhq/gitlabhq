---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Prérequis pour l'installation."
title: "Exigences d'installation de GitLab"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

GitLab a des exigences d'installation spécifiques.

## Stockage {#storage}

L'espace de stockage nécessaire dépend en grande partie de la taille des dépôts que vous souhaitez avoir dans GitLab. À titre indicatif, vous devriez disposer d'au moins autant d'espace libre que la taille combinée de tous vos dépôts.

Le package Linux nécessite environ 2,5 Go d'espace de stockage pour l'installation. Combiné avec PostgreSQL, les journaux, les fichiers temporaires et la surcharge du système d'exploitation, prévoyez au moins 40 Go d'espace disque pour une installation GitLab de base sans données de dépôt. Pour plus de flexibilité en matière de stockage, envisagez de monter votre disque dur via la gestion de volumes logiques. Vous devriez disposer d'un disque dur d'au moins 7 200 RPM ou d'un disque SSD pour réduire les temps de réponse.

Étant donné que les performances du système de fichiers peuvent affecter les performances globales de GitLab, vous devriez [éviter d'utiliser des systèmes de fichiers basés sur le cloud pour le stockage](../administration/nfs.md#avoid-using-cloud-based-file-systems).

## CPU {#cpu}

Les exigences en matière de CPU dépendent du nombre d'utilisateurs et de la charge de travail attendue. La charge de travail inclut l'activité de vos utilisateurs, l'utilisation de l'automatisation et de la mise en miroir, ainsi que la taille du dépôt.

Pour un maximum de 20 requêtes par seconde ou 1 000 utilisateurs, vous devriez disposer de 8 vCPU. Pour plus d'utilisateurs ou une charge de travail plus élevée, consultez [les architectures de référence](../administration/reference_architectures/_index.md).

## Mémoire {#memory}

Les exigences en matière de mémoire dépendent du nombre d'utilisateurs et de la charge de travail attendue. La charge de travail inclut l'activité de vos utilisateurs, l'utilisation de l'automatisation et de la mise en miroir, ainsi que la taille du dépôt.

Pour un maximum de 20 requêtes par seconde ou 1 000 utilisateurs, vous devriez disposer de 16 Go de mémoire. Pour plus d'utilisateurs ou une charge de travail plus élevée, consultez [les architectures de référence](../administration/reference_architectures/_index.md).

Dans certains cas, GitLab peut fonctionner avec au moins 8 Go de mémoire. Pour plus d'informations, consultez [l'exécution de GitLab dans un environnement à mémoire limitée](https://docs.gitlab.com/omnibus/settings/memory_constrained_envs/).

## PostgreSQL {#postgresql}

[PostgreSQL](https://www.postgresql.org/) est la seule base de données prise en charge et est fournie avec le package Linux. Vous pouvez également utiliser une [base de données PostgreSQL externe](https://docs.gitlab.com/omnibus/settings/database/#using-a-non-packaged-postgresql-database-management-server) [qui doit être configurée correctement](#postgresql-settings).

### Versions prises en charge {#supported-versions}

Pour les versions suivantes de GitLab, utilisez ces versions de PostgreSQL :

| Version de GitLab | Version du chart Helm | Version minimale de PostgreSQL | Version maximale de PostgreSQL |
| -------------- | ------------------ | -------------------------- | -------------------------- |
| 19.x           | 10.x               | 17.x                       | 17.x                       |
| 18.x           | 9.x                | [16.5](https://gitlab.com/gitlab-org/gitlab/-/issues/508672) | 17.x ([testé avec GitLab 17.10 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/issues/521159)) |
| 17.x           | 8.x                | [14.14](https://gitlab.com/gitlab-org/gitlab/-/issues/508672) | 16.x ([testé avec GitLab 16.10 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145298)) |
| 16.x           | 7.x                | 13.6                       | 15.x ([testé avec GitLab 16.1 et versions ultérieures](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119344)) |

Les versions mineures de PostgreSQL [n'incluent que des correctifs de bogues et de sécurité](https://www.postgresql.org/support/versioning/). Utilisez toujours la dernière version mineure pour éviter les problèmes connus dans PostgreSQL. Pour plus d'informations, consultez [l'ticket 364763](https://gitlab.com/gitlab-org/gitlab/-/issues/364763).

Pour utiliser une version majeure de PostgreSQL ultérieure à celle spécifiée, vérifiez si une [version ultérieure est fournie avec le package Linux](http://gitlab-org.gitlab.io/omnibus-gitlab/licenses.html).

### Exigences de stockage {#storage-requirements}

En fonction du [nombre d'utilisateurs](../administration/reference_architectures/_index.md), le serveur PostgreSQL doit disposer de :

- Pour la plupart des instances GitLab, au moins 5 à 10 Go de stockage.
- Pour GitLab Ultimate, au moins 12 Go de stockage (1 Go de données de vulnérabilité doit être importé).

### Extensions {#extensions}

Pour installer des extensions, PostgreSQL nécessite des privilèges de super-utilisateur. Pour obtenir des instructions, consultez [Gérer les extensions PostgreSQL](../administration/postgresql/extensions.md).

| Extension            | Version minimale de GitLab | Type        | Base de données |
|----------------------|------------------------|-------------|----------|
| `amcheck`            | 18.4                   | Obligatoire    | Principale |
| `btree_gist`         | 13.1                   | Obligatoire    | Principale |
| `pg_trgm`            | 8.6                    | Obligatoire    | Principale |
| `plpgsql`            | 11.7                   | Obligatoire    | Principale, [bases de données de suivi secondaires Geo](../administration/geo/_index.md) (version minimale 9.0) |
| `pg_stat_statements` | -                      | Recommandé | Tous |

### GitLab Geo {#gitlab-geo}

Pour [GitLab Geo](../administration/geo/_index.md) , vous devriez utiliser le package Linux ou des [fournisseurs cloud validés](../administration/reference_architectures/_index.md#recommended-cloud-providers-and-services) pour installer GitLab. La compatibilité avec d'autres bases de données externes n'est pas garantie.

Pour plus d'informations, consultez [les exigences pour l'exécution de Geo](../administration/geo/_index.md#requirements-for-running-geo).

### Compatibilité des paramètres régionaux {#locale-compatibility}

Lorsque vous modifiez les données de paramètres régionaux dans `glibc`, les fichiers de base de données PostgreSQL ne sont plus entièrement compatibles entre différents systèmes d'exploitation. Pour éviter la corruption d'index, [vérifiez la compatibilité des paramètres régionaux](../administration/geo/replication/troubleshooting/common.md#check-os-locale-data-compatibility) lorsque vous :

- Déplacez des données PostgreSQL binaires entre des serveurs.
- Mettez à niveau votre distribution Linux.
- Mettez à jour ou modifiez des images de conteneurs tierces.

Pour plus d'informations, consultez [la mise à niveau des systèmes d'exploitation pour PostgreSQL](../administration/postgresql/upgrading_os.md).

### Schémas GitLab {#gitlab-schemas}

Vous devriez créer ou utiliser des bases de données exclusivement pour GitLab, [Geo](../administration/geo/_index.md) , [Gitaly Cluster (Praefect)](../administration/gitaly/praefect/_index.md) ou d'autres composants. Ne créez pas et ne modifiez pas de bases de données, de schémas, d'utilisateurs ou d'autres propriétés, sauf lorsque vous suivez :

- Les procédures de la documentation GitLab
- Les instructions du support ou des ingénieurs GitLab

L'application GitLab principale utilise trois schémas :

- Le schéma `public` par défaut
- `gitlab_partitions_static` (créé automatiquement)
- `gitlab_partitions_dynamic` (créé automatiquement)

Lors des migrations de bases de données Rails, GitLab peut créer ou modifier des schémas ou des tables. Les migrations de bases de données sont testées par rapport à la définition du schéma dans la base de code GitLab. Si vous modifiez un schéma, les [mises à niveau de GitLab](../update/_index.md) pourraient échouer.

### Paramètres PostgreSQL {#postgresql-settings}

Voici quelques paramètres obligatoires pour les instances PostgreSQL gérées en externe.

| Paramètre ajustable        | Valeur requise | Plus d'informations |
|:-----------------------|:---------------|:-----------------|
| `work_mem`             | minimum `8 MB`  | Cette valeur est la valeur par défaut du package Linux. Dans les déploiements de grande envergure, si les requêtes créent des fichiers temporaires, vous devriez augmenter ce paramètre. |
| `maintenance_work_mem` | minimum `64 MB` | Vous avez besoin de [davantage pour les serveurs de base de données plus importants](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/8377#note_1728173087). |
| `max_connections`      | minimum `400`   | Calculez en fonction de vos composants GitLab. Consultez la page [Régler PostgreSQL](../administration/postgresql/tune.md) pour obtenir des conseils détaillés. |
| `shared_buffers`       | minimum `2 GB`  | Vous avez besoin de plus pour les serveurs de base de données plus importants. La valeur par défaut du package Linux est définie à 25 % de la RAM du serveur. |
| `statement_timeout`    | 15000 à 60000 | Un délai d'expiration des instructions évite les problèmes incontrôlés liés aux verrous et au rejet de nouveaux clients par la base de données. Vous devriez utiliser des valeurs comprises entre 15 et 60 secondes (15 000 à 60 000 millisecondes), où une minute correspond au paramètre de délai d'expiration du rack Puma. |
| `hot_standby_feedback` | `on` | Pour les configurations avec plusieurs nœuds et un [équilibrage de charge de base de données](../administration/postgresql/database_load_balancing.md#configuring-database-load-balancing) configuré, assurez-vous que tous les nœuds réplica ont `hot_standby_feedback` activé pour éviter l'accumulation de retard. |

Vous pouvez configurer certains paramètres PostgreSQL pour la base de données spécifique, plutôt que pour toutes les bases de données sur le serveur.

- Vous pourriez limiter la configuration à des bases de données spécifiques lors de l'hébergement de plusieurs bases de données sur le même serveur.
- Pour obtenir des conseils sur l'emplacement d'application de la configuration, consultez votre administrateur de base de données ou votre fournisseur.
- Pour GCP Cloud SQL, vous pouvez définir `statement_timeout` sur une base de données ou un utilisateur spécifique, mais pas [en tant qu'indicateur de base de données](https://cloud.google.com/sql/docs/postgres/flags#list-flags-postgres). Par exemple : `ALTER DATABASE gitlab SET statement_timeout = '60s';`

## Puma {#puma}

Les paramètres [Puma](https://puma.io/) recommandés dépendent de votre [installation](install_methods.md). Par défaut, le package Linux utilise les paramètres recommandés.

Pour ajuster les paramètres Puma :

- Pour le package Linux, consultez [les paramètres Puma](../administration/operations/puma.md).
- Pour le chart Helm GitLab, consultez le [chart `webservice`](https://docs.gitlab.com/charts/charts/gitlab/webservice/).

### Workers {#workers}

Le nombre recommandé de workers Puma dépend en grande partie de la capacité du CPU et de la mémoire. Par défaut, le package Linux utilise le nombre recommandé de workers. Pour plus d'informations sur la façon dont ce nombre est calculé, consultez [`puma.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab/libraries/puma.rb?ref_type=heads#L46-69).

Un nœud ne doit jamais avoir moins de deux workers Puma. Par exemple, un nœud devrait avoir :

- Deux workers pour 2 cœurs CPU et 8 Go de mémoire
- Deux workers pour 4 cœurs CPU et 4 Go de mémoire
- Quatre workers pour 4 cœurs CPU et 8 Go de mémoire
- Six workers pour 8 cœurs CPU et 8 Go de mémoire
- Huit workers pour 8 cœurs CPU et 16 Go de mémoire

Par défaut, chaque worker Puma est limité à 1,2 Go de mémoire. Vous pouvez [ajuster ce paramètre](../administration/operations/puma.md#tuning-memory-use) dans `/etc/gitlab/gitlab.rb`.

Vous pouvez également augmenter le nombre de workers Puma, à condition que la capacité CPU et mémoire soit suffisante. Un plus grand nombre de workers réduirait les temps de réponse et améliorerait la capacité à gérer les requêtes parallèles. Effectuez des tests pour vérifier le nombre optimal de workers pour votre [installation](install_methods.md).

### Threads {#threads}

Le nombre recommandé de threads Puma dépend de la mémoire totale du système. Un nœud devrait utiliser :

- Un thread pour un système d'exploitation avec un maximum de 2 Go de mémoire
- Quatre threads pour un système d'exploitation avec plus de 2 Go de mémoire

Un plus grand nombre de threads entraînerait un swap excessif et des performances réduites.

## Redis {#redis}

[Redis](https://redis.io/) ou [Valkey](https://valkey.io/) stocke toutes les sessions utilisateur et les tâches en arrière-plan et nécessite environ 25 ko par utilisateur en moyenne.

Redis 7.2 ou Valkey 7.2 est requis. Pour plus d'informations sur les dates de fin de vie, consultez la [documentation Redis](https://redis.io/docs/latest/operate/oss_and_stack/install/version-mgmt/).

- Utilisez une instance autonome (avec ou sans haute disponibilité). Redis Cluster n'est pas pris en charge.
- Définissez la [politique d'éviction](../administration/redis/replication_and_failover_external.md#setting-the-eviction-policy) de manière appropriée.

## Sidekiq {#sidekiq}

[Sidekiq](https://sidekiq.org/) utilise un processus multi-thread pour les tâches en arrière-plan. Ce processus consomme initialement plus de 200 Mo de mémoire et peut augmenter avec le temps en raison de fuites mémoire.

Sur un serveur très actif avec plus de 10 000 utilisateurs facturables, le processus Sidekiq peut consommer plus de 1 Go de mémoire.

## Prometheus {#prometheus}

Par défaut, [Prometheus](https://prometheus.io) et ses exportateurs associés sont activés pour surveiller GitLab. Ces processus consomment environ 200 Mo de mémoire.

Pour plus d'informations, consultez [la surveillance de GitLab avec Prometheus](../administration/monitoring/prometheus/_index.md).

## Navigateurs web pris en charge {#supported-web-browsers}

GitLab prend en charge les navigateurs web suivants :

- [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/new/)
- [Google Chrome](https://www.google.com/chrome/)
- [Chromium](https://www.chromium.org/getting-involved/dev-channel/)
- [Apple Safari](https://www.apple.com/safari/)
- [Microsoft Edge](https://www.microsoft.com/en-us/edge?form=MA13QK)

GitLab prend en charge :

- Les deux versions majeures les plus récentes de ces navigateurs
- La version mineure actuelle d'une version majeure prise en charge

L'exécution de GitLab avec JavaScript désactivé dans ces navigateurs n'est pas prise en charge.

## Sujets connexes {#related-topics}

- [Installer GitLab Runner](https://docs.gitlab.com/runner/install/)
- [Sécuriser votre installation](../security/_index.md)
