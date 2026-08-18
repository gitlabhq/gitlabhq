---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Zoekt
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed
- Statut : disponibilité limitée

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049) en tant que [version bêta](../../policy/development_stages_support.md#beta) dans GitLab 15.9 [avec des feature flags](../../administration/feature_flags/_index.md) nommés `index_code_with_zoekt` et `search_code_with_zoekt`. Désactivés par défaut.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/388519) dans GitLab 16.6.
- La recherche de code globale a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147077) dans GitLab 16.11 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `zoekt_cross_namespace_search`. Désactivés par défaut.
- Les feature flags `index_code_with_zoekt` et `search_code_with_zoekt` ont été [supprimés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378) dans GitLab 17.1.
- Le feature flag `zoekt_rollout_worker` a été [ajouté](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175666) dans GitLab 17.9. Désactivés par défaut.
- [Modifié](https://gitlab.com/groups/gitlab-org/-/epics/17918) de version bêta à disponibilité limitée dans GitLab 18.6.
- Les feature flags [`zoekt_cross_namespace_search`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213413) et [`zoekt_rollout_worker`](https://gitlab.com/gitlab-org/gitlab/-/issues/519660) ont été supprimés dans GitLab 18.7.

{{< /history >}}

> [!warning]
> Cette fonctionnalité est en [disponibilité limitée](../../policy/development_stages_support.md#limited-availability). Pour plus d'informations, consultez l'[epic 9404](https://gitlab.com/groups/gitlab-org/-/epics/9404). Donnez votre avis dans le [ticket 420920](https://gitlab.com/gitlab-org/gitlab/-/issues/420920).

Zoekt est un moteur de recherche open source conçu spécifiquement pour la recherche de code.

Grâce à cette intégration, vous pouvez utiliser la [recherche de code exacte](../../user/search/exact_code_search.md) plutôt que la [recherche avancée](../../user/search/advanced_search.md) pour rechercher du code dans GitLab. Vous pouvez utiliser les modes de correspondance exacte et d'expression régulière pour rechercher du code dans un groupe ou un dépôt.

> [!note]
> Zoekt gère uniquement la recherche de code et ne remplace pas [Elasticsearch ou OpenSearch](../advanced_search/elasticsearch.md). Pour toutes les autres portées de recherche, notamment les commentaires, les commits, les epics, les tickets, les merge requests, les jalons, les projets, les utilisateurs et les wikis, Elasticsearch ou OpenSearch est toujours requis.

## Compatibilité des versions {#version-compatibility}

Chaque version de GitLab est fournie avec une version spécifique de `gitlab-zoekt-indexer` et une version du chart `gitlab-zoekt`.

| Version de GitLab | Version de `gitlab-zoekt-indexer` | Version du chart `gitlab-zoekt` |
|----------------|--------------------------------|------------------------------|
| 19.1           | 1.16.1                         | 4.1.0                        |
| 19.0           | 1.14.2                         | 4.0.0                        |
| 18.11          | 1.13.1                         | 3.11.0                       |
| 18.10          | 1.11.2                         | 3.10.0                       |
| 18.9           | 1.8.2                          | 3.9.0                        |
| 18.8           | 1.8.0                          | 3.8.0                        |
| 18.6 et 18.7  | 1.7.6                          | 3.7.1                        |

## Installer Zoekt {#install-zoekt}

Prérequis :

- Disposer d'un accès administrateur

Pour [activer la recherche de code exacte](#enable-exact-code-search) dans GitLab, vous devez avoir au moins un nœud Zoekt connecté à l'instance. Les méthodes d'installation suivantes sont prises en charge pour Zoekt :

- [Chart Zoekt](https://docs.gitlab.com/charts/charts/gitlab/gitlab-zoekt/) (en tant que chart autonome ou sous-chart du chart Helm GitLab)
- [GitLab Operator](https://docs.gitlab.com/operator/) (avec `gitlab-zoekt.install=true`)

Les méthodes d'installation suivantes sont disponibles à des fins de test uniquement et non pour une utilisation en production :

- [Docker Compose](https://gitlab.com/gitlab-org/gitlab-zoekt-indexer/-/tree/main/example/docker-compose)
- [Playbook Ansible](https://gitlab.com/gitlab-org/search-team/code-search/ansible-gitlab-zoekt)

## Activer la recherche de code exacte {#enable-exact-code-search}

### Depuis l'interface utilisateur de GitLab {#from-the-gitlab-ui}

Prérequis :

- Disposer d'un accès administrateur
- [Zoekt installé](#install-zoekt)

Pour activer la [recherche de code exacte](../../user/search/exact_code_search.md) depuis l'interface utilisateur de GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**
1. Développez **Recherche de code spécifique**
1. Cochez les cases **Activer l'indexation** et **Activer la recherche**
1. Sélectionnez **Enregistrer les modifications**

### Avec les tâches Rake {#with-rake-tasks}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/580121) dans GitLab 18.10

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur
- [Zoekt installé](#install-zoekt)

Vous pouvez gérer la [recherche de code exacte](../../user/search/exact_code_search.md) avec des tâches Rake.

#### Activer l'indexation et la recherche {#enable-indexing-and-search}

Pour activer l'indexation et la recherche, exécutez cette tâche Rake :

```shell
gitlab-rake gitlab:zoekt:index
```

Cette tâche active `zoekt_indexing_enabled`, `zoekt_search_enabled` et `zoekt_auto_index_root_namespace`. `RolloutWorker` indexe automatiquement tous les espaces de nommage racines, et la recherche devient disponible lorsque les index sont prêts.

#### Désactiver l'indexation et la recherche {#disable-indexing-and-search}

Pour désactiver l'indexation et la recherche, exécutez cette tâche Rake :

```shell
gitlab-rake gitlab:zoekt:disable
```

Cette tâche désactive à la fois `zoekt_indexing_enabled` et `zoekt_search_enabled`.

#### Mettre en pause et reprendre l'indexation {#pause-and-resume-indexing}

Pour mettre en pause l'indexation (par exemple, pendant la maintenance), exécutez cette tâche Rake :

```shell
gitlab-rake gitlab:zoekt:pause_indexing
```

Pour reprendre l'indexation, exécutez cette tâche Rake :

```shell
gitlab-rake gitlab:zoekt:resume_indexing
```

#### Estimer les besoins en stockage {#estimate-storage-requirements}

Pour estimer le stockage requis pour vos nœuds Zoekt, exécutez cette tâche Rake :

```shell
sudo gitlab-rake gitlab:zoekt:estimate_storage
```

Pour plus d'informations, consultez [Estimer les besoins en stockage](#estimate-requirements).

#### Réessayer l'indexation des dépôts ayant échoué {#retry-indexing-of-failed-repositories}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/239608) dans GitLab 19.1

{{< /history >}}

Pour réessayer l'indexation de tous les enregistrements de dépôts Zoekt à l'état `failed`, exécutez cette tâche Rake :

```shell
gitlab-rake gitlab:zoekt:reindex_failed_projects
```

Cette tâche fait passer tous les enregistrements `failed` `zoekt_repository` à l'état `pending` avec `retries_left` défini sur `1`, afin qu'ils soient récupérés lors du prochain cycle d'indexation.

Pour réessayer uniquement des projets spécifiques, transmettez une liste d'identifiants de projet séparés par des virgules :

```shell
gitlab-rake "gitlab:zoekt:reindex_failed_projects[1,2,3]"
```

## Vérifier le statut d'indexation {#check-indexing-status}

{{< history >}}

- L'arrêt de l'indexation lorsque le stockage du nœud Zoekt dépasse le niveau critique a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/504945) dans GitLab 17.7 [avec un feature flag](../../administration/feature_flags/_index.md) nommé `zoekt_critical_watermark_stop_indexing`. Désactivés par défaut.
- [Activé sur GitLab.com, GitLab Self-Managed et GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/issues/505334) dans GitLab 18.0.
- [En disponibilité générale](https://gitlab.com/gitlab-org/gitlab/-/issues/505334) dans GitLab 18.1. Le feature flag `zoekt_critical_watermark_stop_indexing` a été supprimé.

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Les performances d'indexation dépendent des limites de CPU et de mémoire sur les nœuds de l'indexeur Zoekt. Pour vérifier le statut d'indexation :

{{< tabs >}}

{{< tab title="GitLab 17.10 et versions ultérieures" >}}

Exécutez cette tâche Rake :

```shell
gitlab-rake gitlab:zoekt:info
```

Pour actualiser automatiquement les données toutes les 10 secondes, exécutez plutôt cette tâche Rake :

```shell
gitlab-rake "gitlab:zoekt:info[10]"
```

{{< /tab >}}

{{< tab title="GitLab 17.9 et versions antérieures" >}}

Dans une [console Rails](../../administration/operations/rails_console.md#starting-a-rails-console-session), exécutez ces commandes :

```ruby
Search::Zoekt::Index.group(:state).count
Search::Zoekt::Repository.group(:state).count
Search::Zoekt::Task.group(:state).count
```

{{< /tab >}}

{{< /tabs >}}

### Exemple de sortie {#sample-output}

La tâche Rake `gitlab:zoekt:info` renvoie une sortie similaire à la suivante :

```console
Exact Code Search
GitLab version:                                                 19.1.0
Enable indexing:                                                yes
Enable searching:                                               yes
Pause indexing:                                                 no
Index root namespaces automatically:                            yes
Cache search results for five minutes:                          yes
Indexing CPU to tasks multiplier:                               1.0
Probability of random force reindexing (percentage):            0.25
Number of parallel processes per indexing task:                 1
Number of namespaces per indexing rollout:                      32
Offline nodes automatically deleted after:                      20m
Indexing timeout per project:                                   30m
Maximum number of files per project to be indexed:              500000
Maximum file size for indexing:                                 1MB
Maximum trigrams per file:                                      20000
Retry interval for failed namespaces:                           1d
Number of replicas per namespace:                               1
Maximum number of projects for legacy search:                   1000
Maximum number of process restarts within 15 minutes for nodes: 3

Nodes
# Number of Zoekt nodes and their status
Node count:                   2 (online: 2, offline: 0)
Last seen at:                 2026-04-16 22:58:09 UTC (less than a minute ago)
Max schema_version:           2601
Storage reserved / usable:    71.1 MiB / 124 GiB (0.06%)
Storage indexed / reserved:   42.7 MiB / 71.1 MiB (60.0%)
Storage used / total:         797 GiB / 921 GiB (86.54%)
Online node watermark levels: 2
  - low: 2

Indexing status
Group count:                      8
# Number of enabled namespaces and their status
EnabledNamespace count:           8 (without indices: 0, rollout blocked: 0, with search disabled: 0)
Replicas count:                   8
  - ready: 8
Indices count:                    8
  - ready: 8
Indices watermark levels:         8
  - healthy: 8
Repositories count:               10
  - ready: 10
Tasks count:                      10
  - done: 10
Tasks pending/processing by type: (none)
Storage buffer factor:            0.831× [dynamic (observed)]

Feature Flags (Non-Default Values)
Feature flags:  none

Feature Flags (Default Values)
Feature flags:  none

Node Details
Node 1 - test-zoekt-hostname-1:
  Status:                       Online
  Last seen at:                 2026-04-16 22:58:09 UTC (less than a minute ago)
  Disk utilization:             86.54%
  Unclaimed storage:            62 GiB
  # Zoekt build version on the node. Must match GitLab version.
  Zoekt version:                2026.04.15-v1.4.0-1-g89a8871
  Schema version:               2601
Node 2 - test-zoekt-hostname-2:
  Status:                       Online
  Last seen at:                 2026-04-16 22:58:09 UTC (less than a minute ago)
  Disk utilization:             86.54%
  Unclaimed storage:            62 GiB
  Zoekt version:                2026.04.15-v1.4.0-1-g89a8871
  Schema version:               2601
```

## Effectuer un bilan de santé {#run-a-health-check}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/203671) dans GitLab 18.4

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Effectuez un bilan de santé pour comprendre le statut de votre infrastructure Zoekt, notamment :

- Nœuds en ligne et hors ligne
- Paramètres d'indexation et de recherche
- Points de terminaison de l'API de recherche
- Génération de jetons web JSON

Pour effectuer un bilan de santé, exécutez la tâche suivante :

```shell
gitlab-rake gitlab:zoekt:health
```

Cette tâche fournit :

- Le statut global : `HEALTHY`, `DEGRADED` ou `UNHEALTHY`
- Recommandations pour résoudre les problèmes détectés
- Codes de sortie pour les intégrations d'automatisation et de surveillance : `0=healthy`, `1=degraded` ou `2=unhealthy`

### Exécuter des vérifications automatiquement {#run-checks-automatically}

Pour exécuter automatiquement des bilans de santé toutes les 10 secondes, exécutez la tâche suivante :

```shell
gitlab-rake "gitlab:zoekt:health[10]"
```

La sortie inclut des indicateurs de statut colorés et affiche :

- Nombre de nœuds en ligne et hors ligne, avertissements d'utilisation du stockage et problèmes de connectivité
- Validation des paramètres de base et statuts d'indexation des espaces de nommage et des dépôts
- Le statut global incluant une évaluation de santé combinée : `HEALTHY`, `DEGRADED` ou `UNHEALTHY`
- Recommandations pour résoudre les problèmes

## Forcer la réindexation des projets {#force-reindex-projects}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/478814) dans GitLab 18.10

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Pour forcer la réindexation d'une plage de projets, exécutez cette tâche Rake :

```shell
gitlab-rake gitlab:zoekt:reindex_projects ID_FROM=10 ID_TO=20
```

`ID_FROM` et `ID_TO` représentent la plage d'identifiants de projet.

Pour forcer la réindexation d'un seul projet, utilisez la même valeur pour `ID_FROM` et `ID_TO`. Pour forcer la réindexation de tous les projets, n'utilisez pas ces variables d'environnement.

## Mettre en pause l'indexation {#pause-indexing}

Prérequis :

- Disposer d'un accès administrateur

Pour mettre en pause l'indexation pour la [recherche de code exacte](../../user/search/exact_code_search.md) :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**
1. Développez **Recherche de code spécifique**
1. Cochez la case **Interrompre l'indexation**
1. Sélectionnez **Enregistrer les modifications**

Lorsque vous mettez en pause l'indexation pour la recherche de code exacte, toutes les modifications apportées à votre dépôt sont mises en file d'attente. Pour reprendre l'indexation, décochez la case **Pause indexing for exact code search**.

## Indexer automatiquement les espaces de nommage racines {#index-root-namespaces-automatically}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/455533) dans GitLab 17.1

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Vous pouvez indexer automatiquement les espaces de nommage racines existants et nouveaux. Pour indexer automatiquement tous les espaces de nommage racines :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**
1. Développez **Recherche de code spécifique**
1. Cochez la case **Indexer automatiquement les espaces de nommage racines**
1. Sélectionnez **Enregistrer les modifications**

Lorsque vous activez ce paramètre, GitLab crée des tâches d'indexation pour tous les projets dans :

- Tous les groupes et sous-groupes
- Tout nouvel espace de nommage racine

Une fois un projet indexé, GitLab ne crée qu'une indexation incrémentielle lorsqu'une modification du dépôt est détectée.

Lorsque vous désactivez ce paramètre :

- Les espaces de nommage racines existants restent indexés
- Les nouveaux espaces de nommage racines ne sont plus indexés

## Mettre en cache les résultats de recherche {#cache-search-results}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/523213) dans GitLab 18.0

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Vous pouvez mettre en cache les résultats de recherche pour de meilleures performances. Cette fonctionnalité est activée par défaut et met en cache les résultats pendant cinq minutes.

Pour mettre en cache les résultats de recherche :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**
1. Développez **Recherche de code spécifique**
1. Cochez la case **Cache search results for five minutes**
1. Sélectionnez **Enregistrer les modifications**

## Définir les tâches d'indexation simultanées {#set-concurrent-indexing-tasks}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/481725) dans GitLab 17.4

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Vous pouvez définir le nombre de tâches d'indexation simultanées pour un nœud Zoekt par rapport à sa capacité CPU.

Un multiplicateur plus élevé signifie que davantage de tâches peuvent s'exécuter simultanément, ce qui améliore le débit d'indexation au prix d'une utilisation accrue du CPU. La valeur par défaut est `1.0` (une tâche par cœur CPU).

Vous pouvez ajuster cette valeur en fonction des performances et de la charge de travail du nœud. Pour définir le nombre de tâches d'indexation simultanées :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**
1. Développez **Recherche de code spécifique**
1. Dans le champ de texte **Indexation du processeur sur le multiplicateur de tâches**, saisissez une valeur.

   Par exemple, si un nœud Zoekt dispose de `4` cœurs CPU et que le multiplicateur est `1.5`, le nombre de tâches simultanées pour le nœud est `6`.
1. Sélectionnez **Enregistrer les modifications**

## Définir la probabilité de réindexation forcée aléatoire {#define-the-probability-of-random-force-reindexing}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/222273) dans GitLab 18.9

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Vous pouvez définir la probabilité qu'un projet soit réindexé de force au lieu d'être indexé de manière incrémentielle. La valeur par défaut est `0.25` (0,25 %).

La réindexation forcée aide à éviter l'épuisement des gestionnaires de mappage mémoire (mmap) en reconstruisant périodiquement les index depuis zéro. Un pourcentage plus élevé augmente la charge d'indexation, en particulier pour les très grands dépôts.

Pour définir la probabilité de réindexation forcée aléatoire :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**
1. Développez **Recherche de code spécifique**
1. Dans le champ de texte **Probabilité de réindexation forcée aléatoire (pourcentage)**, saisissez un nombre compris entre `0` et `100`
1. Sélectionnez **Enregistrer les modifications**

## Définir le nombre de processus parallèles par tâche d'indexation {#set-the-number-of-parallel-processes-per-indexing-task}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/539526) dans GitLab 18.1

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Vous pouvez définir le nombre de processus parallèles par tâche d'indexation.

Un nombre plus élevé améliore le temps d'indexation au prix d'une utilisation accrue du CPU et de la mémoire. La valeur par défaut est `1` (un processus par tâche d'indexation).

Vous pouvez ajuster cette valeur en fonction des performances et de la charge de travail du nœud. Pour définir le nombre de processus parallèles par tâche d'indexation :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**
1. Développez **Recherche de code spécifique**
1. Dans le champ de texte **Nombre de processus parallèles par tâche d'indexation**, saisissez une valeur
1. Sélectionnez **Enregistrer les modifications**

## Définir le nombre d'espaces de nommage par déploiement d'indexation {#set-the-number-of-namespaces-per-indexing-rollout}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/536175) dans GitLab 18.0

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Vous pouvez définir le nombre d'espaces de nommage par job `RolloutWorker` pour l'indexation initiale. La valeur par défaut est `32`. Vous pouvez ajuster cette valeur en fonction des performances et de la charge de travail du nœud.

Pour définir le nombre d'espaces de nommage par déploiement d'indexation :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**
1. Développez **Recherche de code spécifique**
1. Dans le champ de texte **Nombre d'espaces de nommage par déploiement d'indexation**, saisissez un nombre supérieur à zéro
1. Sélectionnez **Enregistrer les modifications**

## Définir quand les nœuds hors ligne sont automatiquement supprimés {#define-when-offline-nodes-are-automatically-deleted}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/487162) dans GitLab 17.5
- La case à cocher **Delete offline nodes after 12 hours** a été [mise à jour](https://gitlab.com/gitlab-org/gitlab/-/issues/536178) en champ de texte **Les nœuds hors ligne sont automatiquement supprimés au bout de** dans GitLab 18.1

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Vous pouvez supprimer automatiquement les nœuds Zoekt hors ligne après une période spécifique, ainsi que leurs index, dépôts et tâches associés. La valeur par défaut est `12h` (12 heures).

Utilisez ce paramètre pour gérer votre infrastructure Zoekt et éviter les ressources orphelines. Pour définir quand les nœuds hors ligne sont automatiquement supprimés :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**
1. Développez **Recherche de code spécifique**
1. Dans le champ de texte **Les nœuds hors ligne sont automatiquement supprimés au bout de**, saisissez une valeur (par exemple, `30m` (30 minutes), `2h` (deux heures) ou `1d` (un jour). Pour désactiver la suppression automatique, définissez la valeur sur `0`
1. Sélectionnez **Enregistrer les modifications**

## Définir le délai d'indexation pour un projet {#define-the-indexing-timeout-for-a-project}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182581) dans GitLab 18.2

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Vous pouvez définir le délai d'indexation pour un projet. La valeur par défaut est `30m` (30 minutes).

Pour définir le délai d'indexation pour un projet :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**
1. Développez **Recherche de code spécifique**
1. Dans le champ de texte **Délai d'indexation par projet**, saisissez une valeur (par exemple, `30m` (30 minutes), `2h` (deux heures) ou `1d` (un jour)
1. Sélectionnez **Enregistrer les modifications**

## Définir le nombre maximal de fichiers dans un projet à indexer {#set-the-maximum-number-of-files-in-a-project-to-be-indexed}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/539526) dans GitLab 18.2

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Vous pouvez définir le nombre maximal de fichiers dans un projet pouvant être indexés. Les projets comportant plus de fichiers que cette limite sur la branche par défaut ne sont pas indexés. La valeur par défaut est `500,000`.

Vous pouvez ajuster cette valeur en fonction des performances et de la charge de travail du nœud. Pour définir le nombre maximal de fichiers dans un projet à indexer :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**
1. Développez **Recherche de code spécifique**
1. Dans le champ de texte **Nombre maximal de fichiers par projet à indexer**, saisissez un nombre supérieur à zéro
1. Sélectionnez **Enregistrer les modifications**

## Définir la taille maximale des fichiers pour l'indexation {#set-maximum-file-size-for-indexing}

{{< history >}}

- [Introduites](https://gitlab.com/gitlab-org/gitlab/-/issues/581176) dans GitLab 18.7

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Vous pouvez définir la taille maximale d'un fichier à indexer. La valeur par défaut est `1MB`.

Pour les fichiers dépassant la taille spécifiée, seuls les noms de fichiers sont indexés. Vous pouvez rechercher ces fichiers uniquement par nom de fichier.

Pour définir la taille maximale des fichiers pour l'indexation :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**
1. Développez **Recherche de code spécifique**
1. Dans le champ de texte **Taille maximale des fichiers pour l'indexation**, saisissez une valeur (par exemple, `512B`, `50KB`, `2MB` ou `1GB`). La valeur peut également être en minuscules
1. Sélectionnez **Enregistrer les modifications**

## Définir le nombre maximal de trigrammes pour l'indexation {#set-the-maximum-trigram-count-for-indexing}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/584506) dans GitLab 18.8

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Vous pouvez définir le nombre maximal de trigrammes pour qu'un fichier soit indexé. La valeur par défaut est `20,000`.

Les trigrammes sont des séquences de trois caractères que Zoekt utilise pour une recherche de code efficace. Pour les fichiers dépassant cette limite de trigrammes, seuls les noms de fichiers sont indexés. Une limite plus élevée affecte à la fois les performances d'indexation et de recherche.

Pour définir le nombre maximal de trigrammes pour l'indexation :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**
1. Développez **Recherche de code spécifique**
1. Dans le champ de texte **Nombre maximal de trigrammes par fichier**, saisissez un nombre supérieur à zéro
1. Sélectionnez **Enregistrer les modifications**

## Définir l'intervalle de nouvelle tentative pour les espaces de nommage ayant échoué {#define-the-retry-interval-for-failed-namespaces}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182581) dans GitLab 17.10

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Vous pouvez définir l'intervalle de nouvelle tentative pour les espaces de nommage ayant précédemment échoué. La valeur par défaut est `1d` (un jour). Une valeur de `0` signifie que les espaces de nommage ayant échoué ne feront jamais de nouvelle tentative.

Pour définir l'intervalle de nouvelle tentative pour les espaces de nommage ayant échoué :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**
1. Développez **Recherche de code spécifique**
1. Dans le champ de texte **Intervalle de nouvelles tentatives pour les espaces de nommage ayant échoué**, saisissez une valeur (par exemple, `30m` (30 minutes), `2h` (deux heures) ou `1d` (un jour)
1. Sélectionnez **Enregistrer les modifications**

## Définir le nombre de réplicas par espace de nommage {#set-the-number-of-replicas-per-namespace}

{{< history >}}

- [Introduites](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214067) dans GitLab 18.7

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Vous pouvez définir le nombre de réplicas par espace de nommage. La valeur par défaut est `1` (un réplica par espace de nommage).

Augmenter le nombre de réplicas par espace de nommage améliore la disponibilité de la recherche en répartissant la charge sur plusieurs nœuds Zoekt. Un plus grand nombre de réplicas augmente les besoins en stockage.

Pour définir le nombre de réplicas par espace de nommage :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**
1. Développez **Recherche de code spécifique**
1. Dans le champ de texte **Nombre de réplicas par espace de nommage**, saisissez un nombre supérieur à zéro
1. Sélectionnez **Enregistrer les modifications**

## Définir le nombre maximal de projets pour la recherche dans les anciennes versions {#set-the-maximum-number-of-projects-for-legacy-search}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224337) dans GitLab 18.10

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Vous pouvez définir le nombre maximal de projets à rechercher dans un groupe lorsque l'indexation par identifiant de traversée est encore en cours. La valeur par défaut est `1,000`.

Lorsque vous effectuez une recherche dans un groupe avant que l'indexation par identifiant de traversée soit terminée, GitLab recherche uniquement les premiers projets (par identifiant de projet) jusqu'à cette limite et affiche un avertissement indiquant que certains projets ne sont pas inclus dans les résultats. Une fois l'indexation par identifiant de traversée terminée, GitLab recherche dans tous les projets du groupe.

Pour définir le nombre maximal de projets pour la recherche dans les anciennes versions :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**
1. Développez **Recherche de code spécifique**
1. Dans le champ de texte **Nombre maximal de projets pour la recherche dans les anciennes versions**, saisissez un nombre supérieur à zéro
1. Sélectionnez **Enregistrer les modifications**

## Définir le nombre maximal de redémarrages de processus pour les nœuds {#set-the-maximum-number-of-process-restarts-for-nodes}

{{< history >}}

- [Introduction](https://gitlab.com/gitlab-org/gitlab/-/work_items/593556) dans GitLab 19.1
- [Introduit](https://gitlab.com/gitlab-org/gitlab-zoekt-indexer/-/merge_requests/911) dans Zoekt 1.16.0

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Vous pouvez définir le nombre maximal de redémarrages de processus en l'espace de 15 minutes avant qu'un nœud soit exclu du routage de recherche. La valeur par défaut est `2`.

GitLab utilise ce paramètre pour détecter les processus d'indexeur ou de serveur web en boucle de plantage. Lorsqu'un nœud dépasse le nombre de redémarrages de processus en l'espace de 15 minutes, il est exclu de la recherche jusqu'à ce que le nombre de redémarrages revienne dans la plage. Une valeur de `0` signifie que le nœud est exclu après un seul redémarrage.

Si tous les nœuds en ligne sont exclus, GitLab bascule sur l'ensemble complet des nœuds en ligne pour éviter une interruption de la recherche.

Pour définir le nombre maximal de redémarrages de processus pour les nœuds :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**
1. Développez **Recherche de code spécifique**
1. Dans le champ de texte **Nombre maximal de redémarrages de processus par nœud en l'espace de 15 minutes**, saisissez un nombre supérieur ou égal à zéro
1. Sélectionnez **Enregistrer les modifications**

## Exécuter Zoekt sur un serveur séparé {#run-zoekt-on-a-separate-server}

{{< history >}}

- L'authentification pour Zoekt a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/389749) dans GitLab 16.3

{{< /history >}}

Prérequis :

- Disposer d'un accès administrateur

Pour exécuter Zoekt sur un serveur différent de GitLab :

1. [Modifiez l'interface d'écoute de Gitaly](../../administration/gitaly/configure_gitaly.md#change-the-gitaly-listening-interface)
1. [Installez Zoekt](#install-zoekt)

## Recommandations de dimensionnement {#sizing-recommendations}

Les recommandations suivantes peuvent être sur-provisionnées pour certains déploiements. Vous devez surveiller votre déploiement pour vous assurer que :

- Aucun événement de mémoire insuffisante ne se produit.
- La limitation du CPU n'est pas excessive.
- Les performances d'indexation correspondent à vos exigences.

Ajustez les ressources en fonction des caractéristiques spécifiques de votre charge de travail, notamment :

- Taille et complexité du dépôt
- Nombre de développeurs actifs
- Fréquence des modifications de code
- Modèles d'indexation

### Architecture mémoire {#memory-architecture}

Le serveur web et l'indexeur ont des modèles d'utilisation de la mémoire différents.

Le serveur web mappe en mémoire les fragments d'index depuis le disque vers la mémoire virtuelle. Le système d'exploitation transfère les données des fragments depuis et vers la mémoire physique au fil des recherches. L'utilisation de la mémoire résidente augmente avec l'ensemble de travail actif. Les nœuds avec des index plus grands ou un volume de requêtes plus élevé nécessitent davantage de mémoire pour le serveur web afin d'éviter l'écroulement des pages et les situations de mémoire insuffisante.

Lorsque l'indexeur construit ou reconstruit des index, il traite les données d'objets Git en mémoire. L'utilisation de la mémoire augmente brusquement lors de l'indexation de grands dépôts ou lorsque plusieurs tâches s'exécutent en parallèle. Vous pouvez contrôler la mémoire maximale de l'indexeur en ajustant le nombre de [processus parallèles par tâche d'indexation](#set-the-number-of-parallel-processes-per-indexing-task) et de [tâches d'indexation simultanées](#set-concurrent-indexing-tasks).

Dans les déploiements sur VM et sur serveur physique, le serveur web et l'indexeur partagent la même mémoire système.

### Nœuds {#nodes}

Pour des performances optimales, le dimensionnement approprié des nœuds Zoekt est crucial. Les recommandations de dimensionnement diffèrent entre les déploiements Kubernetes et VM en raison de la façon dont les ressources sont allouées et gérées.

#### Déploiements Kubernetes {#kubernetes-deployments}

Le tableau suivant présente les ressources recommandées par nœud (par pod StatefulSet) pour les déploiements Kubernetes en fonction des besoins en stockage d'index. Chaque pod du StatefulSet exécute ses propres conteneurs de serveur web et d'indexeur avec des allocations de ressources indépendantes et son propre volume persistant pour le stockage des index. Si vous exécutez plusieurs nœuds, multipliez ces ressources par le nombre de nœuds pour calculer les ressources totales du cluster.

| Disque   | CPU du serveur web | Mémoire du serveur web  | CPU de l'indexeur | Mémoire de l'indexeur |
|--------|---------------|-------------------|-------------|----------------|
| 128 Go | 1             | 16 Gio            | 1           | 6 Gio  |
| 256 Go | 1,5           | 32 Gio            | 1           | 8 Gio  |
| 512 Go | 2             | 64 Gio            | 1           | 12 Gio |
| 1 To   | 3             | 128 Gio           | 1,5         | 24 Gio |
| 2 To   | 4             | 256 Gio           | 2           | 32 Gio |

Pour gérer les ressources de manière plus granulaire, vous pouvez allouer le CPU et la mémoire séparément à différents conteneurs.

Pour les déploiements Kubernetes :

- Ne définissez pas de limites CPU pour les conteneurs Zoekt. Les limites CPU peuvent provoquer une limitation inutile lors des pics d'indexation, ce qui aurait un impact significatif sur les performances. Utilisez plutôt des demandes de ressources pour garantir une disponibilité CPU minimale et vous assurer que les conteneurs utilisent le CPU supplémentaire lorsqu'il est disponible et nécessaire.
- Définissez des limites de mémoire appropriées pour éviter la contention de ressources et les situations de mémoire insuffisante.
- Utilisez des classes de stockage haute performance pour de meilleures performances d'indexation. GitLab.com utilise `pd-balanced` sur GCP, ce qui équilibre les performances et les coûts. Les options équivalentes incluent `gp3` sur AWS et `Premium_LRS` sur Azure.

#### Déploiements sur VM et sur serveur physique {#vm-and-bare-metal-deployments}

Le tableau suivant présente les ressources recommandées par nœud pour les déploiements sur VM et sur serveur physique en fonction des besoins en stockage d'index. Si vous exécutez plusieurs nœuds, multipliez ces ressources par le nombre de nœuds pour calculer les ressources totales du cluster.

| Disque   | Taille de la VM  | CPU total | Mémoire totale | AWS          | GCP             | Azure |
|--------|----------|-----------|--------------|--------------|-----------------|-------|
| 128 Go | Small    | 2 cœurs   | 16 Go        | `r5.large`   | `n1-highmem-2`  | `Standard_E2s_v3`  |
| 256 Go | Moyen   | 4 cœurs   | 32 Go        | `r5.xlarge`  | `n1-highmem-4`  | `Standard_E4s_v3`  |
| 512 Go | Large    | 4 cœurs   | 64 Go        | `r5.2xlarge` | `n1-highmem-8`  | `Standard_E8s_v3`  |
| 1 To   | X-Large  | 8 cœurs   | 128 Go       | `r5.4xlarge` | `n1-highmem-16` | `Standard_E16s_v3` |
| 2 To   | 2X-Large | 16 cœurs  | 256 Go       | `r5.8xlarge` | `n1-highmem-32` | `Standard_E32s_v3` |

Vous pouvez allouer ces ressources uniquement à l'ensemble du nœud.

Pour les déploiements sur VM et sur serveur physique :

- Surveillez l'utilisation du CPU, de la mémoire et du disque pour identifier les goulots d'étranglement.
- Envisagez d'utiliser un stockage SSD pour de meilleures performances d'indexation.
- Assurez-vous d'une bande passante réseau suffisante pour le transfert de données entre GitLab et les nœuds Zoekt.

### Stockage {#storage}

Les besoins en stockage de Zoekt dépendent de la taille de vos dépôts Git et de votre configuration de réplicas. Zoekt indexe uniquement les données d'objets Git (code source et historique des commits). Il n'indexe pas les fichiers LFS, les artefacts CI/CD, les paquets, les wikis ni les autres composants de stockage.

#### Estimer les besoins {#estimate-requirements}

Pour estimer les besoins en stockage, exécutez cette tâche Rake :

```shell
sudo gitlab-rake gitlab:zoekt:estimate_storage
```

Cette tâche interroge votre base de données GitLab et génère une estimation du stockage basée sur les tailles actuelles de vos dépôts et votre configuration de réplicas.

Pour calculer manuellement les besoins en stockage, utilisez plutôt ces formules :

```plaintext
storage_per_replica = sum(repository_git_size) × buffer_factor
total_cluster_storage = storage_per_replica × number_of_replicas
```

`repository_git_size` est la taille des objets Git pour chaque dépôt. Cette valeur n'inclut pas les objets LFS, les wikis, les artefacts ni les paquets. `buffer_factor` est la marge disponible lors de l'indexation initiale. Vous pouvez calculer cette valeur avec `Search::Zoekt::Index.global_buffer_factor`, qui est généralement égale à `3` par défaut.

Pour afficher `repository_git_size` :

1. Dans le coin supérieur droit, sélectionnez **Admin**
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Projets**
1. Dans la colonne **Dépôt**, consultez la taille des objets Git

Pour la cible de provisionnement initiale, commencez par trois fois votre total `repository_git_size` multiplié par le nombre de réplicas. Par exemple :

- 100 Go de données de dépôt Git et un réplica : 300 Go de stockage Zoekt
- 100 Go de données de dépôt Git et deux réplicas : 600 Go de stockage Zoekt

GitLab réserve cette marge en interne pour s'assurer que Zoekt dispose de suffisamment d'espace lors de l'indexation. Une fois l'indexation initiale terminée, l'utilisation réelle du disque est généralement plus proche de la moitié de `repository_git_size` d'après les données observées sur GitLab.com. Effectuez une mise à l'échelle verticale ou horizontale uniquement si nécessaire.

Pour afficher le facteur de tampon actuel, exécutez cette tâche Rake :

```shell
sudo gitlab-rake gitlab:zoekt:info
```

La sortie inclut **Storage buffer factor**, qui affiche la valeur dynamique utilisée par le planificateur.

Pour surveiller le stockage des nœuds Zoekt, consultez [vérifier le statut d'indexation](#check-indexing-status). Si les espaces de nommage ne sont pas indexés en raison d'un espace disque insuffisant, ajoutez des nœuds ou augmentez la capacité disque.

## Sécurité et authentification {#security-and-authentication}

Zoekt implémente un système d'authentification multicouche pour sécuriser la communication entre GitLab, l'indexeur Zoekt et les composants du serveur web Zoekt. L'authentification est appliquée sur tous les canaux de communication.

Toutes les méthodes d'authentification utilisent le secret GitLab Shell. Les tentatives d'authentification échouées renvoient des réponses `401 Unauthorized`.

### Indexeur Zoekt vers GitLab {#zoekt-indexer-to-gitlab}

L'indexeur Zoekt s'authentifie auprès de GitLab avec des jetons web JSON (JWT) pour récupérer les tâches d'indexation et envoyer des rappels de fin.

Cette méthode utilise `.gitlab_shell_secret` pour la signature et la vérification. Les jetons sont envoyés dans l'en-tête `Gitlab-Shell-Api-Request`. Les points de terminaison suivants sont disponibles :

- `GET /internal/search/zoekt/:uuid/heartbeat` pour la récupération des tâches
- `POST /internal/search/zoekt/:uuid/callback` pour les mises à jour de statut

Cette méthode assure une interrogation sécurisée pour la distribution des tâches et la notification du statut entre les nœuds de l'indexeur Zoekt et GitLab.

### GitLab vers le serveur web Zoekt {#gitlab-to-the-zoekt-webserver}

#### Authentification JWT {#jwt-authentication}

{{< history >}}

- L'authentification JWT a été [introduite](https://gitlab.com/gitlab-org/gitlab-zoekt-indexer/-/releases/v1.0.0) dans GitLab Zoekt 1.0.0

{{< /history >}}

GitLab s'authentifie auprès du serveur web Zoekt avec des jetons web JSON (JWT) pour exécuter des requêtes de recherche. Les jetons JWT fournissent une authentification à durée limitée, signée cryptographiquement, cohérente avec les autres modèles d'authentification GitLab.

Cette méthode utilise `Gitlab::Shell.secret_token` et l'algorithme HS256 (HMAC avec SHA-256). Les jetons sont envoyés dans l'en-tête `Authorization: Bearer <jwt_token>` et expirent dans cinq minutes pour limiter l'exposition.

Les points de terminaison incluent `/webserver/api/search` et `/webserver/api/v2/search`. Les revendications JWT sont l'émetteur (`gitlab`) et l'audience (`gitlab-zoekt`).
