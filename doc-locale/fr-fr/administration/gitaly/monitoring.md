---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Surveillance de Gitaly
---

Utilisez les journaux disponibles et les [métriques Prometheus](../monitoring/prometheus/_index.md) pour surveiller Gitaly.

Les définitions des métriques sont disponibles :

- Directement depuis le point de terminaison `/metrics` de Prometheus configuré pour Gitaly.
- En utilisant [Grafana Explore](https://grafana.com/docs/grafana/latest/explore/) sur une instance Grafana configurée avec Prometheus.

Gitaly peut être configuré pour limiter les requêtes en fonction de la simultanéité des requêtes (adaptative ou non adaptative).

## Surveiller la limitation de simultanéité de Gitaly {#monitor-gitaly-concurrency-limiting}

Vous pouvez observer le comportement spécifique des [requêtes en file d'attente de simultanéité](concurrency_limiting.md#limit-rpc-concurrency) à l'aide des journaux Gitaly et de Prometheus.

Dans les [journaux Gitaly](../logs/_index.md#gitaly-logs), vous pouvez identifier les journaux liés à la limitation de simultanéité pack-objects avec des entrées telles que :

| Champ du journal                        | Description |
|----------------------------------|-------------|
| `limit.concurrency_queue_length` | Indique la longueur actuelle de la file d'attente spécifique au type RPC de l'appel en cours. Fournit des informations sur le nombre de requêtes en attente de traitement en raison des limites de simultanéité. |
| `limit.concurrency_queue_ms`     | Représente la durée, en millisecondes, qu'une requête a passée à attendre dans la file d'attente en raison de la limite de RPC simultanés. Ce champ aide à comprendre l'impact des limites de simultanéité sur les temps de traitement des requêtes. |
| `limit.concurrency_dropped`      | Si la requête est abandonnée en raison de l'atteinte des limites, ce champ spécifie la raison : soit `max_time` (la requête a attendu dans la file d'attente plus longtemps que le temps maximum autorisé) ou `max_size` (la file d'attente a atteint sa taille maximale). |
| `limit.limiting_key`             | Identifie la clé utilisée pour la limitation. |
| `limit.limiting_type`            | Spécifie le type de processus limité. Dans ce contexte, il s'agit de `per-rpc`, indiquant que la limitation de simultanéité est appliquée sur une base par RPC. |

Par exemple :

```json
{
  "limit.concurrency_queue_length": 1,
  "limit.concurrency_queue_ms": 0,
  "limit.limiting_key": "@hashed/79/02/7902699be42c8a8e46fbbb450172651786b22c56a189f7625a6da49081b2451.git",
  "limit.limiting_type": "per-rpc"
}
```

Dans Prometheus, recherchez les métriques suivantes :

- `gitaly_concurrency_limiting_in_progress` indique le nombre de requêtes simultanées en cours de traitement.
- `gitaly_concurrency_limiting_queued` indique le nombre de requêtes pour un RPC dans un dépôt donné qui sont en attente en raison de l'atteinte de la limite de simultanéité.
- `gitaly_concurrency_limiting_acquiring_seconds` indique la durée d'attente d'une requête en raison des limites de simultanéité avant d'être traitée.
- `gitaly_requests_dropped_total` fournit un nombre total de requêtes abandonnées en raison de la limitation des requêtes. Le label `reason` indique pourquoi une requête a été abandonnée :
  - `max_size`, car la taille de la file d'attente de simultanéité a été atteinte.
  - `max_time`, car la requête a dépassé le temps d'attente maximal en file d'attente tel que configuré dans Gitaly.

## Surveiller la limitation de simultanéité pack-objects de Gitaly {#monitor-gitaly-pack-objects-concurrency-limiting}

Vous pouvez observer le comportement spécifique de la [limitation pack-objects](concurrency_limiting.md#limit-pack-objects-concurrency) à l'aide des journaux Gitaly et de Prometheus.

Dans les [journaux Gitaly](../logs/_index.md#gitaly-logs), vous pouvez identifier les journaux liés à la limitation de simultanéité pack-objects avec des entrées telles que :

| Champ du journal                        | Description |
|:---------------------------------|:------------|
| `limit.concurrency_queue_length` | Longueur actuelle de la file d'attente pour les processus pack-objects. Indique le nombre de requêtes en attente de traitement car la limite sur les processus simultanés a été atteinte. |
| `limit.concurrency_queue_ms`     | Temps qu'une requête a passé à attendre dans la file d'attente, en millisecondes. Indique la durée d'attente d'une requête en raison des limites de simultanéité. |
| `limit.limiting_key`             | IP distante de l'expéditeur. |
| `limit.limiting_type`            | Type de processus limité. Dans ce cas, `pack-objects`. |

Exemple de configuration :

```json
{
  "limit.concurrency_queue_length": 1,
  "limit.concurrency_queue_ms": 0,
  "limit.limiting_key": "1.2.3.4",
  "limit.limiting_type": "pack-objects"
}
```

Dans Prometheus, recherchez les métriques suivantes :

- `gitaly_pack_objects_in_progress` indique le nombre de processus pack-objects traités simultanément.
- `gitaly_pack_objects_queued` indique le nombre de requêtes pour les processus pack-objects en attente en raison de l'atteinte de la limite de simultanéité.
- `gitaly_pack_objects_acquiring_seconds` indique la durée d'attente d'une requête pour un processus pack-object en raison des limites de simultanéité avant d'être traitée.

## Surveiller la limitation de simultanéité adaptative de Gitaly {#monitor-gitaly-adaptive-concurrency-limiting}

{{< history >}}

- [Introduite](https://gitlab.com/groups/gitlab-org/-/epics/10734) dans GitLab 16.6.

{{< /history >}}

Vous pouvez observer le comportement spécifique de la [limitation de simultanéité adaptative](concurrency_limiting.md#adaptive-concurrency-limiting) à l'aide des journaux Gitaly et de Prometheus.

La limitation de simultanéité adaptative est une extension de la limitation de simultanéité statique ; par conséquent, toutes les métriques et tous les journaux applicables à la [limitation de simultanéité statique](#monitor-gitaly-concurrency-limiting) sont également pertinents lors de la surveillance des limites adaptatives. De plus, la limitation adaptative introduit plusieurs métriques spécifiques qui aident à surveiller l'ajustement dynamique des limites.

### Journaux de limitation adaptative {#adaptive-limiting-logs}

Dans les [journaux Gitaly](../logs/_index.md#gitaly-logs), vous pouvez identifier les journaux liés à la limitation de simultanéité adaptative lorsque les limites actuelles sont ajustées. Vous pouvez filtrer le contenu des journaux (`msg`) pour les messages « Multiplicative decrease » et « Additive increase ».

Ces journaux de débogage ne sont disponibles qu'au niveau de gravité de débogage et peuvent être verbeux, mais ils fournissent des informations détaillées sur les ajustements des limites adaptatives.

| Champ du journal        | Description |
|:-----------------|:------------|
| `limit`          | Le nom de la limite en cours d'ajustement. |
| `previous_limit` | La limite précédente avant qu'elle soit augmentée ou diminuée. |
| `new_limit`      | La nouvelle limite après qu'elle a été augmentée ou diminuée. |
| `watcher`        | L'observateur de ressources qui a déterminé que le nœud est sous pression. Par exemple : `CgroupCpu` ou `CgroupMemory`. |
| `reason`         | La raison derrière l'ajustement de la limite. |
| `stats.*`        | Quelques statistiques derrière une décision d'ajustement. Elles sont à des fins de débogage. |

Exemple de journal :

```json
{
  "msg": "Multiplicative decrease",
  "limit": "pack-objects",
  "new_limit": 14,
  "previous_limit": 29,
  "reason": "cgroup CPU throttled too much",
  "watcher": "CgroupCpu",
  "stats.time_diff": 15.0,
  "stats.throttled_duration": 13.0,
  "stat.sthrottled_threshold": 0.5
}
```

### Métriques de limitation adaptative {#adaptive-limiting-metrics}

Dans Prometheus, recherchez les métriques suivantes :

Métriques générales de limitation de simultanéité, applicables aux limites statiques et adaptatives :

- `gitaly_concurrency_limiting_in_progress` - Nombre de requêtes en cours de traitement.
- `gitaly_concurrency_limiting_queued` - Nombre de requêtes en attente dans la file d'attente en raison des limites de simultanéité.
- `gitaly_concurrency_limiting_acquiring_seconds` - Temps passé par les requêtes en attente en raison des limites de simultanéité avant le début du traitement.

Métriques spécifiques à la limitation de simultanéité adaptative :

- `gitaly_concurrency_limiting_current_limit` - Une jauge indiquant la valeur limite actuelle d'une limite de simultanéité adaptative pour chaque type RPC. Seules les limites adaptatives sont incluses dans cette métrique.
- `gitaly_concurrency_limiting_backoff_events_total` - Compteur indiquant le nombre total d'événements de backoff, représentant quand et pourquoi les limites sont réduites en raison de la pression sur les ressources.
- `gitaly_concurrency_limiting_watcher_errors_total` - Compteur suivant les erreurs qui se produisent lorsque Gitaly ne parvient pas à récupérer les données de ressources, ce qui peut affecter la capacité de Gitaly à évaluer la situation actuelle des ressources.

Lors de l'investigation de problèmes liés à la limitation adaptative, mettez en corrélation ces métriques avec les métriques et journaux généraux de limitation de simultanéité pour obtenir une vue complète du comportement du système.

## Surveiller les cgroups de Gitaly {#monitor-gitaly-cgroups}

Vous pouvez observer le statut des [groupes de contrôle (cgroups)](configure_gitaly.md#control-groups) à l'aide de Prometheus :

- `gitaly_cgroups_reclaim_attempts_total`, une jauge pour le nombre total de fois où une tentative de récupération de mémoire a eu lieu. Ce nombre est réinitialisé à chaque redémarrage du serveur.
- `gitaly_cgroups_cpu_usage`, une jauge qui mesure l'utilisation du CPU par cgroup.
- `gitaly_cgroup_procs_total`, une jauge qui mesure le nombre total de processus que Gitaly a générés sous le contrôle des cgroups.
- `gitaly_cgroup_cpu_cfs_periods_total`, un compteur pour la valeur de [`nr_periods`](https://docs.kernel.org/scheduler/sched-bwc.html#statistics).
- `gitaly_cgroup_cpu_cfs_throttled_periods_total`, un compteur pour la valeur de [`nr_throttled`](https://docs.kernel.org/scheduler/sched-bwc.html#statistics).
- `gitaly_cgroup_cpu_cfs_throttled_seconds_total`, un compteur pour la valeur de [`throttled_time`](https://docs.kernel.org/scheduler/sched-bwc.html#statistics) en secondes.

## Cache `pack-objects` {#pack-objects-cache}

Les métriques suivantes du [cache `pack-objects`](configure_gitaly.md#pack-objects-cache) sont disponibles :

- `gitaly_pack_objects_cache_enabled`, une jauge définie à `1` lorsque le cache est activé. Labels disponibles : `dir` et `max_age`.
- `gitaly_pack_objects_cache_lookups_total`, un compteur pour les recherches dans le cache. Label disponible : `result`.
- `gitaly_pack_objects_generated_bytes_total`, un compteur pour le nombre d'octets écrits dans le cache.
- `gitaly_pack_objects_served_bytes_total`, un compteur pour le nombre d'octets lus depuis le cache.
- `gitaly_streamcache_filestore_disk_usage_bytes`, une jauge pour la taille totale des fichiers du cache. Label disponible : `dir`.
- `gitaly_streamcache_index_entries`, une jauge pour le nombre d'entrées dans le cache. Label disponible : `dir`.

Certaines de ces métriques commencent par `gitaly_streamcache` car elles sont générées par le package de bibliothèque interne `streamcache` dans Gitaly.

Exemple :

```plaintext
gitaly_pack_objects_cache_enabled{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache",max_age="300"} 1
gitaly_pack_objects_cache_lookups_total{result="hit"} 2
gitaly_pack_objects_cache_lookups_total{result="miss"} 1
gitaly_pack_objects_generated_bytes_total 2.618649e+07
gitaly_pack_objects_served_bytes_total 7.855947e+07
gitaly_streamcache_filestore_disk_usage_bytes{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache"} 2.6200152e+07
gitaly_streamcache_filestore_removed_total{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache"} 1
gitaly_streamcache_index_entries{dir="/var/opt/gitlab/git-data/repositories/+gitaly/PackObjectsCache"} 1
```

## Surveiller les sauvegardes côté serveur de Gitaly {#monitor-gitaly-server-side-backups}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitaly/-/issues/5358) dans GitLab 16.7.

{{< /history >}}

Surveillez les [sauvegardes de dépôt côté serveur](configure_gitaly.md#configure-server-side-backups) avec les métriques suivantes :

- `gitaly_backup_latency_seconds`, un histogramme mesurant la durée en secondes que chaque phase d'une sauvegarde côté serveur prend. Les différentes phases sont `refs`, `bundle` et `custom_hooks` et représentent le type de données traitées à chaque étape.
- `gitaly_backup_bundle_bytes`, un histogramme mesurant le débit de chargement des bundles Git envoyés vers le stockage d'objets par le service de sauvegarde Gitaly.

Utilisez ces métriques notamment si votre instance GitLab contient de grands dépôts.

## Requêtes {#queries}

Voici quelques requêtes pour surveiller Gitaly :

- Utilisez la requête Prometheus suivante pour observer le [type de connexions](tls_support.md) que Gitaly dessert dans un environnement de production :

  ```prometheus
  sum(rate(gitaly_connections_total[5m])) by (type)
  ```

- Utilisez la requête Prometheus suivante pour surveiller le [comportement d'authentification](tls_support.md#observe-type-of-gitaly-connections) de votre installation GitLab :

  ```prometheus
  sum(rate(gitaly_authentications_total[5m])) by (enforced, status)
  ```

  Dans un système où l'authentification est correctement configurée et où vous avez du trafic en direct, vous verrez quelque chose comme ceci :

  ```prometheus
  {enforced="true",status="ok"}  4424.985419441742
  ```

  Il peut également y avoir d'autres nombres avec un taux de 0, mais vous ne devez prendre note que des nombres non nuls.

  Le seul nombre non nul devrait avoir `enforced="true",status="ok"`. Si vous avez d'autres nombres non nuls, quelque chose ne va pas dans votre configuration.

  Le nombre `status="ok"` reflète votre taux de requêtes actuel. Dans l'exemple précédent, Gitaly traite environ 4 000 requêtes par seconde.

- Utilisez la requête Prometheus suivante pour observer les [versions du protocole Git](../git_protocol.md) utilisées dans un environnement de production :

  ```prometheus
  sum(rate(gitaly_git_protocol_requests_total[1m])) by (grpc_method,git_protocol,grpc_service)
  ```
