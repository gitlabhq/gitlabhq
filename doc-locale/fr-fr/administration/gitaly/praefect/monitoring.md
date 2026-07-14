---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Surveillance de Gitaly Cluster (Praefect)
---

Pour surveiller Gitaly Cluster (Praefect), vous pouvez utiliser les métriques Prometheus. Deux endpoints de métriques distincts sont disponibles à partir desquels les métriques peuvent être collectées :

- L'endpoint `/metrics` par défaut.
- `/db_metrics`, qui contient des métriques nécessitant des requêtes de base de données.

## Endpoint Prometheus `/metrics` par défaut {#default-prometheus-metrics-endpoint}

Les métriques suivantes sont disponibles à partir de l'endpoint `/metrics` :

- `gitaly_praefect_read_distribution`, un compteur permettant de suivre la [distribution des lectures](_index.md#distributed-reads). Il possède deux labels :

  - `virtual_storage`.
  - `storage`.

  Ils reflètent la configuration définie pour cette instance de Praefect.

- `gitaly_praefect_replication_latency_bucket`, un histogramme mesurant le temps nécessaire à la réplication pour se terminer après le démarrage du job de réplication.
- `gitaly_praefect_replication_delay_bucket`, un histogramme mesurant le temps qui s'écoule entre la création du job de réplication et son démarrage.
- `gitaly_praefect_connections_total`, le nombre total de connexions à Praefect.
- `gitaly_praefect_method_types`, un comptage des RPC d'accesseur et de mutateur par nœud.

Pour surveiller la [cohérence forte](_index.md#strong-consistency), vous pouvez utiliser les métriques Prometheus suivantes :

- `gitaly_praefect_transactions_total`, le nombre de transactions créées et sur lesquelles un vote a été émis.
- `gitaly_praefect_subtransactions_per_transaction_total`, le nombre de fois où les nœuds ont émis un vote pour une seule transaction. Cela peut se produire plusieurs fois si plusieurs références sont mises à jour dans une seule transaction.
- `gitaly_praefect_voters_per_transaction_total` : le nombre de nœuds Gitaly participant à une transaction.
- `gitaly_praefect_transactions_delay_seconds`, le délai côté serveur introduit par l'attente de la validation de la transaction.
- `gitaly_hook_transaction_voting_delay_seconds`, le délai côté client introduit par l'attente de la validation de la transaction.

Pour surveiller la [vérification des dépôts](configure.md#repository-verification), utilisez les métriques Prometheus suivantes :

- `gitaly_praefect_verification_jobs_dequeued_total`, le nombre de jobs de vérification pris en charge par le worker.
- `gitaly_praefect_verification_jobs_completed_total`, le nombre de jobs de vérification effectués par le worker. Le label `result` indique le résultat final des jobs :
  - `valid` indique que le réplica attendu existait sur le stockage.
  - `invalid` indique que le réplica censé exister n'existait pas sur le stockage.
  - `error` indique que le job a échoué et doit être réessayé.
- `gitaly_praefect_stale_verification_leases_released_total`, le nombre de baux de vérification obsolètes libérés.

Vous pouvez également surveiller les [journaux Praefect](../../logs/_index.md#praefect-logs).

## Métriques de base de données : endpoint `/db_metrics` {#database-metrics-db_metrics-endpoint}

Les métriques suivantes sont disponibles à partir de l'endpoint `/db_metrics` :

- `gitaly_praefect_unavailable_repositories`, le nombre de dépôts ne disposant d'aucun réplica sain et à jour.
- `gitaly_praefect_replication_queue_depth`, le nombre de jobs dans la file d'attente de réplication.
- `gitaly_praefect_verification_queue_depth`, le nombre total de réplicas en attente de vérification.
