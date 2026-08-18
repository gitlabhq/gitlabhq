---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Résolution des problèmes liés aux migrations Elasticsearch
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lors de l'utilisation des migrations Elasticsearch, vous pourriez rencontrer les problèmes suivants.

Si [`elasticsearch.log`](../../../administration/logs/_index.md#elasticsearchlog) contient des erreurs et que la nouvelle tentative de migrations ayant échoué ne fonctionne pas, contactez le support GitLab. Pour plus d'informations, consultez [les migrations de recherche avancée](../../advanced_search/elasticsearch.md#advanced-search-migrations).

## Erreur : `Elasticsearch::Transport::Transport::Errors::BadRequest` {#error-elasticsearchtransporttransporterrorsbadrequest}

Si vous rencontrez une exception similaire, assurez-vous d'avoir la bonne version d'Elasticsearch et de satisfaire aux [exigences système](../../advanced_search/elasticsearch.md#system-requirements). Vous pouvez également vérifier la version automatiquement en utilisant la commande `sudo gitlab-rake gitlab:check`.

## Erreur : `Faraday::TimeoutError (execution expired)` {#error-faradaytimeouterror-execution-expired}

Lorsque vous utilisez un proxy, définissez une variable d'environnement `gitlab_rails['env']` personnalisée nommée [`no_proxy`](https://docs.gitlab.com/omnibus/settings/environment-variables/) avec l'adresse IP de votre hôte Elasticsearch.

## Le statut d'un cluster Elasticsearch à nœud unique ne passe jamais du jaune au vert {#single-node-elasticsearch-cluster-status-never-goes-from-yellow-to-green}

Pour un cluster Elasticsearch à nœud unique, le statut fonctionnel de santé du cluster est jaune (jamais vert). La raison est que le fragment principal est alloué, mais les répliques ne peuvent pas l'être car il n'existe aucun autre nœud auquel Elasticsearch peut affecter une réplique. Cela s'applique également si vous utilisez le service [Amazon OpenSearch](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/aes-handling-errors.html#aes-handling-errors-yellow-cluster-status).

> [!warning]
> Il est déconseillé de définir le nombre de répliques sur `0` (cela n'est pas autorisé dans le menu d'intégration Elasticsearch de GitLab). Si vous prévoyez d'ajouter d'autres nœuds Elasticsearch (pour un total de plus d'un Elasticsearch), le nombre de répliques doit être défini sur une valeur entière supérieure à `0`. Ne pas le faire entraîne un manque de redondance (la perte d'un nœud corrompt l'index).

Si vous souhaitez avoir un statut vert pour votre cluster Elasticsearch à nœud unique, comprenez les risques et exécutez la requête suivante pour définir le nombre de répliques sur `0`. Le cluster ne tente plus de créer des répliques de fragments.

```shell
curl --request PUT localhost:9200/gitlab-production/_settings --header 'Content-Type: application/json' \
     --data '{
       "index" : {
         "number_of_replicas" : 0
       }
     }'
```

## Erreur : `health check timeout: no Elasticsearch node available` {#error-health-check-timeout-no-elasticsearch-node-available}

Si vous obtenez une erreur `health check timeout: no Elasticsearch node available` dans Sidekiq lors du processus d'indexation :

```plaintext
Gitlab::Elastic::Indexer::Error: time="2020-01-23T09:13:00Z" level=fatal msg="health check timeout: no Elasticsearch node available"
```

Vous n'avez probablement utilisé ni `http://` ni `https://` dans votre valeur dans le champ **URL** du menu d'intégration Elasticsearch. Vérifiez le format de l'URL dans ce champ, car le [client Elasticsearch pour Go](https://github.com/olivere/elastic) exige que le préfixe de l'URL soit [accepté comme valide](https://github.com/olivere/elastic/commit/a80af35aa41856dc2c986204e2b64eab81ccac3a). Après avoir corrigé le format de l'URL, [supprimez l'index](../../advanced_search/elasticsearch.md#gitlab-advanced-search-rake-tasks) et [réindexez le contenu de votre instance](../../advanced_search/elasticsearch.md#enable-advanced-search).

## Elasticsearch ne fonctionne pas avec certains plugins tiers {#elasticsearch-does-not-work-with-some-third-party-plugins}

Certains plugins tiers peuvent introduire des bugs dans votre cluster ou être incompatibles avec l'intégration.

Si votre cluster Elasticsearch dispose de plugins tiers et que l'intégration ne fonctionne pas, essayez de désactiver les plugins.

## Les workers Elasticsearch surchargent Sidekiq {#elasticsearch-workers-overload-sidekiq}

Dans certains cas, Elasticsearch ne peut plus se connecter à GitLab parce que :

- Le mot de passe Elasticsearch a été mis à jour d'un seul côté (erreurs `Unauthorized [401] ... unable to authenticate user`).
- Un pare-feu ou un problème réseau altère la connectivité (erreurs `Failed to open TCP connection to <ip>:9200`).

Ces erreurs sont consignées dans [`gitlab-rails/elasticsearch.log`](../../../administration/logs/_index.md#elasticsearchlog). Pour récupérer les erreurs, utilisez [`jq`](../../../administration/logs/log_parsing.md) :

```shell
$ jq --raw-output 'select(.severity == "ERROR") | [.error_class, .error_message] | @tsv' \
    gitlab-rails/elasticsearch.log |
  sort | uniq -c
```

Les workers `Elastic` et les [jobs Sidekiq](../../../administration/admin_area.md#background-jobs) peuvent également apparaître beaucoup plus souvent car Elasticsearch tente fréquemment de réindexer si un job précédent échoue. Vous pouvez utiliser [`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats#usage) ou `jq` pour compter les workers dans les [logs Sidekiq](../../../administration/logs/_index.md#sidekiq-logs) :

```shell
$ fast-stats --print-fields=count,score sidekiq/current
WORKER                            COUNT   SCORE
Search::Elastic::IndexBulkCronWorker         234  123456
Search::Elastic::IndexInitialBulkCronWorker  345   12345
Some::OtherWorker                             12     123
...

$ jq '.class' sidekiq/current | sort | uniq -c | sort -nr
 234 "Search::Elastic::IndexInitialBulkCronWorker"
 345 "Search::Elastic::IndexBulkCronWorker"
  12 "Some::OtherWorker"
...
```

Dans ce cas, `free -m` sur le nœud GitLab surchargé afficherait également une utilisation de `buff/cache` anormalement élevée.

## Erreur : `Couldn't load task status` {#error-couldnt-load-task-status}

Lors de la réindexation, vous pourriez obtenir une erreur `Couldn't load task status`. Une erreur `sliceId must be greater than 0 but was [-1]` pourrait également apparaître sur l'hôte Elasticsearch. Pour contourner ce problème, envisagez de [réindexer depuis zéro](indexing.md#last-resort-to-recreate-an-index) ou de mettre à niveau vers GitLab 16.3.

Pour plus d'informations, consultez le [ticket 422938](https://gitlab.com/gitlab-org/gitlab/-/issues/422938).

## Erreur : `migration has failed with NoMethodError:undefined method` {#error-migration-has-failed-with-nomethoderrorundefined-method}

Dans GitLab 15.11, la migration `BackfillProjectPermissionsInBlobs` peut échouer avec le message d'erreur suivant dans `elasticsearch.log` :

```shell
migration has failed with NoMethodError:undefined method `<<' for nil:NilClass, no retries left
```

Si `BackfillProjectPermissionsInBlobs` est la seule migration ayant échoué, vous pouvez mettre à niveau vers la dernière version de correctif de GitLab 16.0, qui inclut [le correctif](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118494). Sinon, vous pouvez ignorer l'erreur car elle n'affecte pas la fonctionnalité de la recherche avancée.

## Les jobs `ElasticIndexInitialBulkCronWorker` et `ElasticIndexBulkCronWorker` bloqués dans la déduplication {#elasticindexinitialbulkcronworker-and-elasticindexbulkcronworker-jobs-stuck-in-deduplication}

Dans GitLab 16.5 et versions antérieures, les jobs `ElasticIndexInitialBulkCronWorker` et `ElasticIndexBulkCronWorker` peuvent rester bloqués dans la déduplication. Ce problème peut empêcher la recherche avancée d'indexer correctement les documents, même après la création d'un nouvel index. Dans GitLab 16.6, `idempotent!` a été [supprimé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/135817) pour les workers cron en masse qui effectuent l'indexation.

Le log Sidekiq peut contenir les entrées suivantes :

```shell
{"severity":"INFO","time":"2023-10-31T10:33:06.998Z","retry":0,"queue":"default","version":0,"queue_namespace":"cronjob","args":[],"class":"ElasticIndexInitialBulkCronWorker",
...
"idempotency_key":"resque:gitlab:duplicate:default:<value>","duplicate-of":"91e8673347d4dc84fbad5319","job_size_bytes":2,"pid":12047,"job_status":"deduplicated","message":"ElasticIndexInitialBulkCronWorker JID-5e1af9180d6e8f991fc773c6: deduplicated: until executing","deduplication.type":"until executing"}
```

Pour résoudre ce problème :

1. Dans une [session de console Rails](../../../administration/operations/rails_console.md#starting-a-rails-console-session), exécutez cette commande :

   ```shell
   idempotency_key = "<idempotency_key_from_log_entry>"
   duplicate_key = "resque:gitlab:#{idempotency_key}:cookie:v2"
   Gitlab::Redis::Queues.with { |c| c.del(duplicate_key) }
   ```

1. Remplacez `<idempotency_key_from_log_entry>` par l'entrée réelle dans votre log.
