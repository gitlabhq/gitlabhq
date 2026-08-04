---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Dépannage de l'indexation et de la recherche Elasticsearch"
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous utilisez l'indexation ou la recherche Elasticsearch, vous pouvez rencontrer les problèmes suivants.

## Créer un index vide {#create-an-empty-index}

En cas de problèmes d'indexation, essayez d'abord de créer un index vide. Vérifiez l'instance Elasticsearch pour voir si l'index `gitlab-production` existe. Si c'est le cas, supprimez manuellement l'index sur l'instance Elasticsearch et essayez de le recréer à partir de la tâche Rake [`recreate_index`](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks).

Si vous rencontrez toujours des problèmes, essayez de créer un index manuellement sur l'instance Elasticsearch. Si vous :

- Si vous ne pouvez pas créer des indices, contactez votre administrateur Elasticsearch.
- Si vous pouvez créer des indices, contactez le support GitLab.

## Vérifier le statut des projets indexés {#check-the-status-of-indexed-projects}

Vous pouvez rechercher des erreurs lors de l'indexation des projets. Des erreurs peuvent survenir sur :

- L'instance GitLab : si vous ne pouvez pas les corriger vous-même, contactez le support GitLab pour obtenir des conseils.
- L'instance Elasticsearch : [si l'erreur n'est pas répertoriée](_index.md), contactez votre administrateur Elasticsearch.

Si l'indexation ne renvoie pas d'erreurs, vérifiez le statut des projets indexés avec les tâches Rake suivantes :

- [`sudo gitlab-rake gitlab:elastic:index_projects_status`](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks) pour le statut global
- [`sudo gitlab-rake gitlab:elastic:projects_not_indexed`](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks) pour les projets spécifiques qui ne sont pas indexés

Si l'indexation est :

- Terminée, contactez le support GitLab.
- Non terminée, essayez de réindexer ce projet en exécutant `sudo gitlab-rake gitlab:elastic:index_projects ID_FROM=<project ID> ID_TO=<project ID>`.

Si la réindexation du projet affiche des erreurs sur :

- L'instance GitLab : contactez le support GitLab.
- L'instance Elasticsearch ou aucune erreur du tout : contactez votre administrateur Elasticsearch pour vérifier l'instance.

## Aucun résultat de recherche après la mise à jour de GitLab {#no-search-results-after-updating-gitlab}

Nous mettons continuellement à jour nos stratégies d'indexation et visons à prendre en charge les versions plus récentes d'Elasticsearch. Lorsque des modifications d'indexation sont apportées, vous devrez peut-être [réindexer](../../advanced_search/elasticsearch.md#zero-downtime-reindexing) après la mise à jour de GitLab.

## Aucun résultat de recherche après l'indexation de tous les dépôts {#no-search-results-after-indexing-all-repositories}

> [!note]
> N'utilisez pas ces instructions pour les scénarios qui n'indexent qu'un [sous-ensemble d'espaces de nommage](../../advanced_search/elasticsearch.md#limit-the-amount-of-namespace-and-project-data-to-index).

Assurez-vous d'avoir [indexé toutes les données de la base de données](../../advanced_search/elasticsearch.md#enable-advanced-search).

S'il n'y a pas de résultats (hits) dans la recherche de l'interface utilisateur, vérifiez si vous obtenez les mêmes résultats via la console Rails (`sudo gitlab-rails console`) :

```ruby
u = User.find_by_username('your-username')
s = SearchService.new(u, {:search => 'search_term', :scope => 'blobs'})
pp s.search_objects.to_a
```

Au-delà de cela, vérifiez via l'[API de recherche Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/search-search.html) si les données s'affichent côté Elasticsearch :

```shell
curl --request GET <elasticsearch_server_ip>:9200/gitlab-production/_search?q=<search_term>
```

Des [appels d'API Elasticsearch plus complexes](https://www.elastic.co/guide/en/elasticsearch/reference/current/query-filter-context.html) sont également possibles.

Si les résultats :

- Correspondent, vérifiez que vous utilisez la [syntaxe prise en charge](../../../user/search/advanced_search.md#syntax). La recherche avancée ne prend pas en charge la [correspondance exacte de sous-chaînes](https://gitlab.com/gitlab-org/gitlab/-/issues/325234).
- Ne correspondent pas, cela indique un problème avec les documents générés à partir du projet. Il est préférable de [réindexer ce projet](../../advanced_search/elasticsearch.md#indexing-a-range-of-projects-or-a-specific-project).

Consultez les [portées d'index Elasticsearch](../../advanced_search/elasticsearch.md#advanced-search-index-scopes) pour plus d'informations sur la recherche de types de données spécifiques.

## Aucun résultat de recherche après l'activation de la recherche avancée avec une faible simultanéité {#no-search-results-after-enabling-advanced-search-with-low-concurrency}

Après avoir activé la recherche avancée, vous pourriez constater que les documents ne sont pas indexés et que le code n'est pas consultable. Vous pourriez voir un message dans les journaux Sidekiq similaire au suivant :

```json
"job_status":"concurrency_limit","message":"Search::Elastic::CommitIndexerWorker JID-352e0b9ee88af9f455c69b81: concurrency_limit: paused"
```

Pour résoudre ce problème :

1. Utilisez la tâche Rake `gitlab-rake gitlab:elastic:info` pour vérifier le statut des **Indexing queues**.
1. Si **Concurrency limit code queue** est non nul, vérifiez la valeur de **Simultanéité d'indexation de code**. Des valeurs trop faibles peuvent empêcher la progression de l'indexation. Envisagez d'augmenter cette valeur et de vérifier la progression avec la tâche Rake.

## Aucun résultat de recherche après le changement de serveurs Elasticsearch {#no-search-results-after-switching-elasticsearch-servers}

Pour réindexer la base de données, les dépôts et les wikis, [indexez l'instance](../../advanced_search/elasticsearch.md#index-the-instance).

## L'indexation échoue avec `error: elastic: Error 429 (Too Many Requests)` {#indexing-fails-with-error-elastic-error-429-too-many-requests}

Si les workers Sidekiq `Search::Elastic::CommitIndexerWorker` échouent avec cette erreur lors de l'indexation, cela signifie généralement qu'Elasticsearch n'est pas en mesure de suivre la simultanéité des demandes d'indexation. Pour y remédier, modifiez les paramètres suivants :

- Pour diminuer le débit d'indexation, vous pouvez réduire `Bulk request concurrency` (voir [Paramètres de recherche avancée](../../advanced_search/elasticsearch.md#advanced-search-configuration)). Cette valeur est définie à `10` par défaut, mais vous pouvez la réduire jusqu'à 1 pour diminuer le nombre d'opérations d'indexation simultanées.
- Si la modification de `Bulk request concurrency` n'a pas aidé, vous pouvez utiliser l'option [règles de routage](../../../administration/sidekiq/processing_specific_job_classes.md#routing-rules) pour [limiter les jobs d'indexation à des nœuds Sidekiq spécifiques](../../advanced_search/elasticsearch.md#index-large-instances-with-dedicated-sidekiq-nodes-or-processes), ce qui devrait réduire le nombre de demandes d'indexation.

## Erreur : `Elasticsearch::Transport::Transport::Errors::RequestEntityTooLarge` {#error-elasticsearchtransporttransporterrorsrequestentitytoolarge}

```plaintext
[413] {"Message":"Request size exceeded 10485760 bytes"}
```

Cette exception se produit lorsque votre cluster Elasticsearch est configuré pour rejeter les demandes dépassant une certaine taille (10 Mio dans ce cas). Cela correspond au paramètre `http.max_content_length` dans `elasticsearch.yml`. Augmentez-le à une taille supérieure et redémarrez votre cluster Elasticsearch.

AWS impose des [limites réseau](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/limits.html#network-limits) sur la taille maximale des charges utiles des requêtes HTTP en fonction de la taille de l'instance sous-jacente. Définissez la taille maximale des requêtes en bloc à une valeur inférieure à 10 Mio.

## L'indexation est très lente ou échoue avec `rejected execution of coordinating operation` {#indexing-is-very-slow-or-fails-with-rejected-execution-of-coordinating-operation}

Les requêtes en bloc rejetées par les nœuds Elasticsearch sont probablement dues à la charge et au manque de mémoire disponible. Assurez-vous que votre cluster Elasticsearch répond à la [configuration système requise](../../advanced_search/elasticsearch.md#system-requirements) et dispose de suffisamment de ressources pour effectuer des opérations en bloc. Voir également l'erreur [« 429 (Too Many Requests) »](#indexing-fails-with-error-elastic-error-429-too-many-requests).

## L'indexation échoue avec `strict_dynamic_mapping_exception` {#indexing-fails-with-strict_dynamic_mapping_exception}

L'indexation peut échouer si toutes les [migrations de recherche avancée n'ont pas été terminées avant d'effectuer une mise à niveau majeure](../../advanced_search/elasticsearch.md#all-migrations-must-be-finished-before-doing-a-major-upgrade). Un important backlog Sidekiq peut accompagner cette erreur. Pour corriger les échecs d'indexation, vous devez réindexer la base de données, les dépôts et les wikis.

1. Mettez en pause l'indexation pour que Sidekiq puisse rattraper son retard :

   ```shell
   sudo gitlab-rake gitlab:elastic:pause_indexing
   ```

1. [Recréez l'index à partir de zéro](#last-resort-to-recreate-an-index).
1. Reprenez l'indexation :

   ```shell
   sudo gitlab-rake gitlab:elastic:resume_indexing
   ```

## L'indexation continue de se mettre en pause avec `elasticsearch_pause_indexing setting is enabled` {#indexing-keeps-pausing-with-elasticsearch_pause_indexing-setting-is-enabled}

Vous pourriez remarquer que les nouvelles données ne sont pas détectées lorsque vous effectuez une recherche.

Cette erreur se produit lorsque les nouvelles données ne sont pas indexées correctement.

Pour résoudre cette erreur, [réindexez vos données](../../advanced_search/elasticsearch.md#zero-downtime-reindexing).

Cependant, lors de la réindexation, vous pourriez obtenir une erreur où le processus d'indexation continue de se mettre en pause et les journaux Elasticsearch affichent ce qui suit :

```shell
"message":"elasticsearch_pause_indexing setting is enabled. Job was added to the waiting queue"
```

Si la réindexation ne résout pas ce problème et que vous n'avez pas mis en pause le processus d'indexation manuellement, cette erreur peut se produire parce que deux instances GitLab partagent un même cluster Elasticsearch.

Pour résoudre cette erreur, déconnectez l'une des instances GitLab du cluster Elasticsearch.

Pour plus d'informations, consultez le [ticket 3421](https://gitlab.com/gitlab-org/gitlab/-/issues/3421).

## La recherche échoue avec `too_many_clauses: maxClauseCount is set to 1024` {#search-fails-with-too_many_clauses-maxclausecount-is-set-to-1024}

Cette erreur se produit lorsqu'une requête a plus de clauses que ce qui est défini dans le paramètre `indices.query.bool.max_clause_count` :

- [Dans Elasticsearch 7.17 et versions antérieures](https://www.elastic.co/guide/en/elasticsearch/reference/7.17/search-settings.html), la valeur par défaut est `1024`.
- [Dans Elasticsearch 8.0](https://www.elastic.co/guide/en/elasticsearch/reference/8.0/search-settings.html), la valeur par défaut est `4096`.
- [Dans Elasticsearch 8.1 et versions ultérieures](https://www.elastic.co/guide/en/elasticsearch/reference/8.1/search-settings.html), le paramètre est obsolète et la valeur est déterminée dynamiquement.

Pour résoudre ce problème, augmentez la valeur ou mettez à niveau vers Elasticsearch 8.1 ou une version ultérieure. L'augmentation de la valeur peut entraîner une dégradation des performances.

## Les résultats de recherche contiennent des doublons sur plusieurs pages {#search-results-contain-duplicates-across-multiple-pages}

Lorsque vous utilisez la recherche avancée, les résultats de recherche qui s'étendent sur plusieurs pages peuvent contenir des doublons. Lorsque des doublons apparaissent, certains résultats correspondants ne sont pas retournés.

GitLab pagine les résultats en fonction du nombre de résultats correspondants uniques provenant d'Elasticsearch. Cependant, en raison de la façon dont Elasticsearch ordonne les résultats, le même résultat peut apparaître sur plusieurs pages. Ce problème est plus susceptible de se produire lorsque vous triez les résultats par pertinence.

Comme solution de contournement, envisagez ce qui suit :

- Une requête de recherche plus spécifique pour affiner les résultats.
- Une option de tri différente si possible.

Pour plus d'informations, consultez le [ticket 416286](https://gitlab.com/gitlab-org/gitlab/-/work_items/416286).

## Erreur : `disk usage exceeded flood-stage watermark, index has read-only-allow-delete block` {#error-disk-usage-exceeded-flood-stage-watermark-index-has-read-only-allow-delete-block}

Cette erreur se produit lorsque votre cluster Elasticsearch possède au moins un nœud dont l'espace disque est dangereusement faible. Un cluster qui dépasse le seuil de limite par défaut de 95 % applique un blocage en lecture seule qui empêche toute opération d'écriture ultérieure. Ce blocage peut entraîner l'échec des nouvelles opérations d'indexation et produire des résultats de recherche obsolètes.

Vous pouvez vérifier si le cluster est en mode lecture seule avec la tâche Rake suivante :

```shell
sudo gitlab-rake gitlab:elastic:info
```

Recherchez une sortie indiquant que `blocks.write` ou `blocks.read_only_allow_delete` est `true`.

Pour vérifier l'utilisation du disque sur votre cluster Elasticsearch, exécutez la commande suivante :

```shell
curl --request GET '<your_ES_cluster>:9200/_cat/allocation?v&pretty'
```

Pour résoudre ce problème, augmentez le volume de disque sur les nœuds pleins. Vous pouvez estimer la taille du cluster avec la tâche Rake suivante :

```shell
sudo gitlab-rake gitlab:elastic:estimate_cluster_size
```

## Dernier recours pour recréer un index {#last-resort-to-recreate-an-index}

Il peut arriver que des données n'aient jamais été indexées et ne se trouvent pas dans la file d'attente, ou que l'index soit dans un état où les migrations ne peuvent tout simplement pas progresser. Il est toujours préférable d'essayer de résoudre la cause racine du problème en [consultant les journaux](access.md#view-logs).

En dernier recours, vous pouvez recréer l'index à partir de zéro. Pour les petites installations GitLab, recréer l'index peut être un moyen rapide de résoudre certains problèmes. Pour les grandes installations GitLab, cependant, cette méthode peut prendre très longtemps. Votre index n'affiche pas les résultats de recherche corrects tant que l'indexation n'est pas terminée. Vous pouvez décocher la case **Recherche avancée** pendant l'exécution de l'indexation.

Si vous êtes sûr d'avoir lu les mises en garde précédentes et souhaitez continuer, vous devez exécuter la tâche Rake suivante pour recréer l'intégralité de l'index à partir de zéro.

{{< tabs >}}

{{< tab title="Paquet Linux (Omnibus)" >}}

```shell
# WARNING: DO NOT RUN THIS UNTIL YOU READ THE DESCRIPTION ABOVE
sudo gitlab-rake gitlab:elastic:index
```

{{< /tab >}}

{{< tab title="Auto-compilée (source)" >}}

```shell
# WARNING: DO NOT RUN THIS UNTIL YOU READ THE DESCRIPTION ABOVE
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:elastic:index
```

{{< /tab >}}

{{< /tabs >}}

## File d'attente morte {#dead-queue}

Les éléments se retrouvent dans la file d'attente morte lorsqu'ils échouent après une nouvelle tentative. Les éléments de la file d'attente morte nécessitent une investigation manuelle et ne font pas l'objet de nouvelles tentatives automatiques.

### Vérifier le statut {#check-the-status}

Pour vérifier la taille et les détails de la file d'attente morte :

1. Démarrez la console Rails :

   ```shell
   sudo gitlab-rails console
   ```

1. Vérifiez le nombre d'éléments en échec :

   ```ruby
   Search::Elastic::DeadQueue.queue_size
   ```

1. Inspectez les détails des éléments en échec :

   ```ruby
   Search::Elastic::DeadQueue.queued_items
   ```

   Cette commande retourne un hash où chaque clé est un numéro de shard et chaque valeur est un tableau de paires `[spec, score]`. La spécification contient des informations sur l'élément en échec.

### Réessayer les éléments {#retry-items}

Mettez en file d'attente les éléments que vous souhaitez réessayer. Si ces éléments échouent à nouveau, ils sont renvoyés dans la file d'attente morte.

Pour réessayer les éléments dans la file d'attente morte :

1. Démarrez la console Rails :

   ```shell
   sudo gitlab-rails console
   ```

1. Déplacez les éléments de la file d'attente morte vers la file d'attente de nouvelle tentative :

   ```ruby
   specs = Search::Elastic::DeadQueue.queued_items.flat_map { |_, items| items.map { |spec, _| spec } }

   Search::Elastic::DeadQueue.clear_tracking!
   Search::Elastic::RetryQueue.track!(*specs)
   ```

1. Facultatif. [Vérifiez le statut d'indexation](../../advanced_search/elasticsearch.md#check-indexing-status).

Pour supprimer des éléments de la file d'attente morte sans les réessayer, exécutez la commande suivante :

```ruby
Search::Elastic::DeadQueue.clear_tracking!
```

### Contacter le support GitLab {#contact-gitlab-support}

Si vous avez besoin d'aide concernant les éléments de la file d'attente morte, partagez les informations suivantes avec le support GitLab :

- La sortie de `Search::Elastic::DeadQueue.queue_size`
- Vos versions d'Elasticsearch et de GitLab
- Quand les échecs d'indexation ont commencé
- Les journaux d'application ou messages d'erreur pertinents

## Améliorer les performances d'Elasticsearch {#improve-elasticsearch-performance}

Pour améliorer les performances, assurez-vous que :

- Le serveur Elasticsearch **n'est pas** en cours d'exécution sur le même nœud que GitLab.
- Le serveur Elasticsearch dispose de suffisamment de RAM et de cœurs CPU.
- Le sharding **est** utilisé.

Pour entrer dans les détails, si Elasticsearch s'exécute sur le même serveur que GitLab, des conflits de ressources sont **très** susceptibles de se produire. Idéalement, Elasticsearch, qui nécessite des ressources importantes, devrait s'exécuter sur son propre serveur (éventuellement couplé avec Logstash et Kibana).

En ce qui concerne Elasticsearch, la RAM est la ressource clé. Elasticsearch recommande :

- **Au moins** 8 Go de RAM pour une instance hors production.
- **Au moins** 16 Go de RAM pour une instance de production.
- Idéalement, 64 Go de RAM.

Pour les CPU, Elasticsearch recommande au moins 2 cœurs CPU, mais Elasticsearch indique que les configurations courantes utilisent jusqu'à 8 cœurs. Pour plus de détails sur les spécifications du serveur, consultez le [guide matériel Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/guide/current/hardware.html).

Au-delà de l'évident, le sharding entre en jeu. Le sharding est un élément central d'Elasticsearch. Il permet la mise à l'échelle horizontale des indices, ce qui est utile lorsque vous traitez une grande quantité de données.

Avec la façon dont GitLab effectue l'indexation, il y a une **énorme** quantité de documents indexés. En utilisant le sharding, vous pouvez accélérer la capacité d'Elasticsearch à localiser les données, car chaque shard est un index Lucene.

Si vous n'utilisez pas le sharding, vous risquez de rencontrer des problèmes lorsque vous commencez à utiliser Elasticsearch dans un environnement de production.

Un index avec un seul shard n'a **aucun facteur de mise à l’échelle** et est susceptible de rencontrer des problèmes lorsqu'il est sollicité avec une certaine fréquence. Consultez la [documentation Elasticsearch sur la planification de capacité](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/capacity-planning.html).

Le moyen le plus simple de déterminer si le sharding est utilisé est de vérifier la sortie de l'[API de santé Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-health.html) :

- Rouge signifie que le cluster est hors service.
- Jaune signifie qu'il est opérationnel sans sharding/réplication.
- Vert signifie qu'il est en bonne santé (opérationnel, avec sharding et réplication).

Pour une utilisation en production, il devrait toujours être vert.

Au-delà de ces étapes, vous abordez certaines des vérifications plus complexes, telles que les fusions et la mise en cache. Celles-ci peuvent devenir complexes et demandent du temps à maîtriser ; il est donc préférable d'escalader le problème ou de collaborer avec un expert Elasticsearch si vous devez approfondir ces aspects.

Contactez le support GitLab, mais cela est probablement quelque chose qu'un administrateur Elasticsearch expérimenté connaît mieux.

## Indexation initiale lente {#slow-initial-indexing}

Plus votre instance GitLab contient de données, plus l'indexation prend du temps. Vous pouvez estimer la taille du cluster avec la tâche Rake `sudo gitlab-rake gitlab:elastic:estimate_cluster_size`.

### Pour les documents de code {#for-code-documents}

Assurez-vous d'avoir suffisamment de nœuds et de processus Sidekiq pour indexer efficacement le code, les commits et les wikis. Si votre indexation initiale est lente, envisagez des [nœuds ou processus Sidekiq dédiés](../../advanced_search/elasticsearch.md#index-large-instances-with-dedicated-sidekiq-nodes-or-processes).

### Pour les documents non-code {#for-non-code-documents}

Si l'indexation initiale est lente mais que Sidekiq dispose de suffisamment de nœuds et de processus, vous pouvez ajuster les paramètres des workers de recherche avancée dans GitLab. Pour **Remettre en file d'attente les workers d'indexation**, la valeur par défaut est `false`. Pour **Nombre de shards pour l'indexation non codée**, la valeur par défaut est `2`. Ces paramètres limitent l'indexation à 2 000 documents par minute.

Prérequis :

- Disposer d'un accès administrateur.

Pour ajuster les paramètres des workers :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Rechercher**.
1. Développez **Recherche avancée**.
1. Cochez la case **Remettre en file d'attente les workers d'indexation**.
1. Dans la zone de texte **Nombre de shards pour l'indexation non codée**, saisissez une valeur supérieure à `2`.
1. Sélectionnez **Enregistrer les modifications**.
