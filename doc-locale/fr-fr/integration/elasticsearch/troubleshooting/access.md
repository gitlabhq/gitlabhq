---
stage: AI-powered
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Dépannage de l'accès à Elasticsearch"
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Lorsque vous utilisez l'accès à Elasticsearch, vous pouvez rencontrer les problèmes suivants.

## Définir des configurations dans la console Rails {#set-configurations-in-the-rails-console}

Consultez [Démarrer une session de console Rails](../../../administration/operations/rails_console.md#starting-a-rails-console-session).

### Lister les attributs {#list-attributes}

Pour lister tous les attributs disponibles :

1. Ouvrez la console Rails (`sudo gitlab-rails console`).
1. Exécutez la commande suivante :

```ruby
ApplicationSetting.last.attributes
```

La sortie contient tous les paramètres disponibles dans [l'intégration Elasticsearch](../../advanced_search/elasticsearch.md), tels que `elasticsearch_indexing`, `elasticsearch_url`, `elasticsearch_replicas` et `elasticsearch_pause_indexing`.

### Définir des attributs {#set-attributes}

Pour définir un paramètre d'intégration Elasticsearch, exécutez une commande telle que :

```ruby
ApplicationSetting.last.update(elasticsearch_url: '<your ES URL and port>')

#or

ApplicationSetting.last.update(elasticsearch_indexing: false)
```

### Obtenir des attributs {#get-attributes}

Pour vérifier si les paramètres ont été définis dans [l'intégration Elasticsearch](../../advanced_search/elasticsearch.md) ou dans la console Rails, exécutez une commande telle que :

```ruby
Gitlab::CurrentSettings.elasticsearch_url

#or

Gitlab::CurrentSettings.elasticsearch_indexing
```

### Modifier le mot de passe {#change-the-password}

Pour modifier le mot de passe Elasticsearch, exécutez les commandes suivantes :

```ruby
es_url = Gitlab::CurrentSettings.current_application_settings

# Confirm the current Elasticsearch URL
es_url.elasticsearch_url

# Set the Elasticsearch URL
es_url.elasticsearch_url = "http://<username>:<password>@your.es.host:<port>"

# Save the change
es_url.save!
```

## Afficher les journaux {#view-logs}

Les journaux constituent l'un des outils les plus précieux pour identifier les problèmes liés à l'intégration Elasticsearch. Les journaux les plus pertinents pour cette intégration sont :

1. [`sidekiq.log`](../../../administration/logs/_index.md#sidekiqlog) - Toute l'indexation se produit dans Sidekiq, de sorte que la plupart des journaux pertinents pour l'intégration Elasticsearch se trouvent dans ce fichier.
1. [`elasticsearch.log`](../../../administration/logs/_index.md#elasticsearchlog) - Ce fichier contient des journaux supplémentaires spécifiques à Elasticsearch qui peuvent contenir des informations de diagnostic sur la recherche, l'indexation ou les migrations.

Voici quelques pièges courants et comment les surmonter.

## Vérifier que votre instance GitLab utilise Elasticsearch {#verify-that-your-gitlab-instance-is-using-elasticsearch}

Pour vérifier que votre instance GitLab utilise Elasticsearch :

- Lorsque vous effectuez une recherche, dans le coin supérieur droit de la page de résultats de recherche, assurez-vous que **recherche avancée est activée** est affiché.
- Dans la zone **Admin**, sous **Paramètres** > **Rechercher**, vérifiez que les paramètres de recherche avancée sont sélectionnés.

  Ces mêmes paramètres peuvent être obtenus depuis la console Rails si nécessaire :

  ```ruby
  ::Gitlab::CurrentSettings.elasticsearch_search?         # Whether or not searches will use Elasticsearch
  ::Gitlab::CurrentSettings.elasticsearch_indexing?       # Whether or not content will be indexed in Elasticsearch
  ::Gitlab::CurrentSettings.elasticsearch_limit_indexing? # Whether or not Elasticsearch is limited only to certain projects/namespaces
  ```

- Confirmez que les recherches utilisent Elasticsearch en accédant à la [console Rails](../../../administration/operations/rails_console.md) et en exécutant les commandes suivantes :

  ```rails
  u = User.find_by_email('email_of_user_doing_search')
  s = SearchService.new(u, {:search => 'search_term'})
  pp s.search_objects.class
  ```

  La sortie de la dernière commande est la clé ici. Si elle affiche :

  - `ActiveRecord::Relation`, elle **n'utilise pas** Elasticsearch.
  - `Kaminari::PaginatableArray`, elle **utilise** Elasticsearch.
- Si Elasticsearch est limité à des espaces de nommage spécifiques et que vous devez savoir si Elasticsearch est utilisé pour un projet ou un espace de nommage spécifique, vous pouvez utiliser la console Rails :

  ```ruby
  ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: Namespace.find_by_full_path("/my-namespace"))
  ::Gitlab::CurrentSettings.search_using_elasticsearch?(scope: Project.find_by_full_path("/my-namespace/my-project"))
  ```

## Erreur : `User: anonymous is not authorized to perform: es:ESHttpGet` {#error-user-anonymous-is-not-authorized-to-perform-eseshttpget}

Lorsque vous utilisez une politique d'accès au niveau du domaine avec AWS OpenSearch ou Elasticsearch, le rôle AWS n'est pas attribué aux nœuds GitLab appropriés. Les nœuds GitLab Rails et Sidekiq ont besoin de l'autorisation de communiquer avec le cluster de recherche.

```plaintext
User: anonymous is not authorized to perform: es:ESHttpGet because no resource-based policy allows the es:ESHttpGet
action
```

Pour résoudre ce problème, assurez-vous que le rôle AWS est attribué aux nœuds GitLab appropriés.

## Aucune région valide spécifiée {#no-valid-region-specified}

Lorsque vous utilisez l'autorisation AWS avec la recherche avancée, la région que vous spécifiez doit être valide.

## Erreur : `no permissions for [indices:data/write/bulk]` {#error-no-permissions-for-indicesdatawritebulk}

Lorsque vous utilisez le contrôle d'accès précis avec un rôle IAM ou un rôle créé à l'aide d'AWS OpenSearch Dashboards, vous pouvez rencontrer l'erreur suivante :

```json
{
  "error": {
    "root_cause": [
      {
        "type": "security_exception",
        "reason": "no permissions for [indices:data/write/bulk] and User [name=arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE, backend_roles=[arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE], requestedTenant=null]"
      }
    ],
    "type": "security_exception",
    "reason": "no permissions for [indices:data/write/bulk] and User [name=arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE, backend_roles=[arn:aws:iam::xxx:role/INSERT_ROLE_NAME_HERE], requestedTenant=null]"
  },
  "status": 403
}
```

Pour résoudre ce problème, vous devez [mapper les rôles aux utilisateurs](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-mapping) dans AWS OpenSearch Dashboards.

## Créer des utilisateurs maîtres supplémentaires dans AWS OpenSearch Service {#create-additional-master-users-in-aws-opensearch-service}

Vous pouvez définir un utilisateur maître lors de la création d'un domaine. Avec cet utilisateur, vous pouvez créer des utilisateurs maîtres supplémentaires. Pour plus d'informations, consultez la [documentation AWS](https://docs.aws.amazon.com/opensearch-service/latest/developerguide/fgac.html#fgac-more-masters).

Pour créer des utilisateurs et des rôles avec des autorisations et mapper des utilisateurs à des rôles, consultez la [documentation OpenSearch](https://opensearch.org/docs/latest/security/access-control/users-roles/). Vous devez inclure les autorisations suivantes dans le rôle :

```json
{
  "cluster_permissions": [
    "cluster_composite_ops",
    "cluster_monitor"
  ],
  "index_permissions": [
    {
      "index_patterns": [
        "gitlab*"
      ],
      "allowed_actions": [
        "data_access",
        "manage_aliases",
        "search",
        "create_index",
        "delete",
        "manage"
      ]
    },
    {
      "index_patterns": [
        "*"
      ],
      "allowed_actions": [
        "indices:admin/aliases/get",
        "indices:monitor/stats"
      ]
    }
  ]
}
```

## Accumulation de connexions TCP ouvertes {#accumulation-of-open-tcp-connections}

Dans GitLab 17.11 et versions ultérieures, vous pouvez remarquer une augmentation des connexions TCP ouvertes entre les processus GitLab et les services externes. Ces connexions s'accumulent au fil du temps et ne sont pas correctement fermées.

Ce problème est lié au changement d'adaptateur Faraday de `net_http` vers `typhoeus` pour le regroupement de connexions dans GitLab. Pour plus d'informations, consultez [l'issue 550805](https://gitlab.com/gitlab-org/gitlab/-/issues/550805).

Pour résoudre ce problème, définissez [`elasticsearch_client_adapter`](../../../api/settings.md#available-settings) sur `net_http`.
