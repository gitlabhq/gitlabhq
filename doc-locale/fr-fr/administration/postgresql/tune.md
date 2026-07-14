---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Optimiser PostgreSQL
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous devez optimiser PostgreSQL dans les cas suivants :

- D'autres composants GitLab sont reconfigurés ou mis à l'échelle d'une manière qui affecte la base de données.
- Les performances de votre environnement GitLab sont dégradées.
- GitLab utilise un [service PostgreSQL externe](external.md).

Utilisez ces informations en combinaison avec les [paramètres PostgreSQL requis](../../install/requirements.md#postgresql-settings) pour GitLab.

## Planifier vos connexions de base de données {#plan-your-database-connections}

> [!note]
> Les versions 16.0 et ultérieures de GitLab utilisent [deux ensembles de connexions de base de données](https://docs.gitlab.com/omnibus/settings/database/#configuring-multiple-database-connections) pour les tables `main` et `ci`. Cela double l'utilisation des connexions, même lorsque la même base de données PostgreSQL sert les deux ensembles de tables.

GitLab utilise des connexions de base de données provenant de plusieurs composants. Une planification appropriée des connexions évite l'épuisement des connexions de base de données et les problèmes de performances.

Chaque composant GitLab utilise des connexions de base de données en fonction de sa configuration. Sidekiq et Puma établissent un pool de connexions à PostgreSQL lors de l'initialisation. Le nombre de connexions dans le pool peut augmenter ultérieurement en cas de pics de connexions ou d'augmentations temporaires de la demande :

- Configurez la marge du pool de base de données avec la variable d'environnement `DB_POOL_HEADROOM`.
- Lorsque vous optimisez PostgreSQL, prévoyez une marge pour le pool mais ne la modifiez pas. Les déploiements GitLab répondent mieux à une demande plus élevée si davantage de capacité est disponible : déployez davantage de workers Sidekiq ou Puma.

### Puma {#puma}

```plaintext
Puma connections = puma['worker_processes'] × (puma['max_threads'] + DB_POOL_HEADROOM)
```

Par défaut :

- `puma['worker_processes']` est basé sur le nombre de cœurs CPU.
- `puma['max_threads']` est `4`.
- `DB_POOL_HEADROOM` est `10`.

Calcul par worker :  Chaque worker Puma utilise 4 threads + 10 de marge, pour un total de 14 connexions.

Calcul par défaut, en supposant 8 vCPU :  8 workers × 14 connexions par worker, pour un total de 112 connexions Puma.

### Sidekiq {#sidekiq}

```plaintext
Sidekiq connections = Number of Sidekiq processes × (sidekiq['concurrency'] + 1 + DB_POOL_HEADROOM)
```

Par défaut :

- Le nombre de processus Sidekiq est `1`.
- `sidekiq['concurrency']` est `20`.
- `DB_POOL_HEADROOM` est `10`.

Calcul par défaut :  1 processus Sidekiq × (20 de simultanéité + 1 + 10 de marge), pour un total de 31 connexions Sidekiq.

### Geo Log Cursor (installations Geo uniquement) {#geo-log-cursor-geo-installations-only}

Le démon [Geo Log Cursor](../../development/geo.md#geo-log-cursor-daemon) s'exécute sur tous les nœuds GitLab Rails d'un site secondaire.

```plaintext
Geo log cursor connections = 1 + DB_POOL_HEADROOM
```

Calcul par défaut :  1 + 10 de marge, pour un total de 11 connexions Geo.

### Exigences totales en matière de connexions {#total-connection-requirements}

Pour les installations à nœud unique :

```plaintext
Total connections = 2 × (Puma + Sidekiq + Geo)
```

Pour les installations multi-nœuds, multipliez par le nombre de nœuds exécutant chaque composant :

```plaintext
Total connections = 2 × ((Puma × Rails nodes) + (Sidekiq × Sidekiq nodes) + (Geo × secondary Rails nodes))
```

La multiplication par 2 prend en compte les [connexions de base de données doubles](https://docs.gitlab.com/omnibus/settings/database/#configuring-multiple-database-connections) dans GitLab 16.0 et versions ultérieures.

Pour les installations Geo :

- Site principal :  Utilisez `Geo = 0`. Geo Log Cursor ne s'exécute pas sur les sites principaux.
- Sites secondaires :  Calculez les connexions de base de données Geo Log Cursor pour un site secondaire, et appliquez ce même calcul à tous les sites secondaires.
- Chaque site Geo se connecte à sa propre base de données, vous n'avez donc pas besoin d'additionner les connexions de plusieurs sites Geo.
- Définissez `max_connections` sur la même valeur sur la base de données PostgreSQL principale et sur toutes les bases de données réplicas, en utilisant l'exigence de connexion la plus élevée parmi tous les sites Geo.

### Exemples {#examples}

#### Installation à nœud unique {#single-node-installation}

Cet exemple est basé sur l'architecture de référence GitLab pour [20 RPS (requêtes par seconde) ou 1 000 utilisateurs](../reference_architectures/1k_users.md) :

| Composant | Nœuds | Configuration             | Connexions par composant | Total du composant, base de données double |
|-----------|-------|---------------------------|---------------------------|---------------------------------|
| Puma      | 1     | 8 workers, 4 threads chacun | 14 par worker             | 224                             |
| Sidekiq   | 1     | 1 processus, 20 de simultanéité | 31 par processus            | 62                              |
| Total     |       |                           |                           | 286                             |

#### Installation multi-nœuds {#multi-node-installation}

Cet exemple est basé sur l'architecture de référence GitLab pour [40 RPS (requêtes par seconde) ou 2 000 utilisateurs](../reference_architectures/2k_users.md) :

| Composant | Nœuds | Configuration                      | Connexions par composant | Total du composant, base de données double |
|-----------|-------|------------------------------------|---------------------------|--------------------------------|
| Puma      | 2     | 8 workers par nœud, 4 threads chacun | 14 par worker             | 448                            |
| Sidekiq   | 1     | 4 processus, 20 de simultanéité chacun   | 31 par processus            | 248                            |
| Total     |       |                                    |                           | 696                            |

#### Installation à nœud unique avec Geo {#single-node-installation-with-geo}

Cet exemple est basé sur l'architecture de référence GitLab pour [20 RPS (requêtes par seconde) ou 1 000 utilisateurs](../reference_architectures/1k_users.md).

| Composant par site Geo                | Nœuds | Configuration             | Connexions par composant | Total du composant, base de données double |
|---------------------------------------|-------|---------------------------|---------------------------|--------------------------------|
| Puma                                  | 1     | 8 workers, 4 threads chacun | 14 par worker             | 224                            |
| Sidekiq                               | 1     | 1 processus, 20 de simultanéité | 31 par processus            | 62                             |
| Geo Log Cursor (sites secondaires uniquement) | 1     | 1 processus                 | 11 par processus            | 22                             |
| Total                                 |       |                           |                           | 308                            |

#### Installation multi-nœuds avec Geo {#multi-node-installation-with-geo}

Cet exemple est basé sur l'architecture de référence GitLab pour [40 RPS (requêtes par seconde) ou 2 000 utilisateurs](../reference_architectures/2k_users.md) :

| Composant par site Geo                | Nœuds | Configuration                      | Connexions par composant | Total du composant, base de données double |
|---------------------------------------|-------|------------------------------------|---------------------------|--------------------------------|
| Puma                                  | 2     | 8 workers par nœud, 4 threads chacun | 14 par worker             | 448                            |
| Sidekiq                               | 1     | 4 processus, 20 de simultanéité chacun   | 31 par processus            | 248                            |
| Geo Log Cursor (sites secondaires uniquement) | 2     | 1 processus par nœud Rails           | 11 par processus            | 44                             |
| Total                                 |       |                                    |                           | 740                            |
