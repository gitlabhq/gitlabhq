---
stage: Analytics
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Service Ping
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec le processus Service Ping de GitLab.

## Exporter les données Service Ping {#export-service-ping-data}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141446) dans GitLab 16.9.

{{< /history >}}

Exporte la charge utile JSON collectée dans Service Ping. Si aucune donnée de charge utile n'est disponible dans le cache de l'application, une réponse vide est renvoyée. Si les données de charge utile sont vides, assurez-vous que la [fonctionnalité Service Ping est activée](../administration/settings/usage_statistics.md#enable-or-disable-service-ping) et attendez que le job cron soit exécuté, ou générez les données de charge utile manuellement.

Prérequis :

- Vous devez vous authentifier avec un jeton d'accès personnel disposant de la portée `read_service_ping`.

```plaintext
GET /usage_data/service_ping
```

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/usage_data/service_ping"
```

Exemple de réponse :

```json
  "recorded_at": "2024-01-15T23:33:50.387Z",
  "license": {},
  "counts": {
    "assignee_lists": 0,
    "ci_builds": 463,
    "ci_external_pipelines": 0,
    "ci_pipeline_config_auto_devops": 0,
    "ci_pipeline_config_repository": 0,
    "ci_triggers": 0,
    "ci_pipeline_schedules": 0
...
```

### Interprétation de `schema_inconsistencies_metric` {#interpreting-schema_inconsistencies_metric}

La charge utile JSON de Service Ping inclut `schema_inconsistencies_metric`. Les incohérences du schéma de base de données sont attendues et sont peu susceptibles d'indiquer un problème avec votre instance.

Cette métrique est conçue uniquement pour le dépannage des problèmes en cours et ne doit pas être utilisée comme vérification régulière de l'état de santé. La métrique ne doit être interprétée qu'avec l'assistance du support GitLab. La métrique signale les mêmes incohérences de schéma de base de données que la [tâche Rake de vérification du schéma de base de données](../administration/raketasks/maintenance.md#check-the-database-for-schema-inconsistencies).

Pour plus d'informations, consultez le [ticket 467544](https://gitlab.com/gitlab-org/gitlab/-/issues/467544).

## Exporter les définitions de métriques {#export-metric-definitions}

Exporte toutes les définitions de métriques dans un seul fichier YAML, similaire au [dictionnaire de métriques](https://metrics.gitlab.com/), pour faciliter l'importation.

```plaintext
GET /usage_data/metric_definitions
```

Exemple de requête :

```shell
curl --request GET \
  --url "https://gitlab.example.com/api/v4/usage_data/metric_definitions"
```

Exemple de réponse :

```yaml
---
- key_path: redis_hll_counters.search.i_search_paid_monthly
  description: Calculated unique users to perform a search with a paid license enabled
    by month
  product_group: global_search
  value_type: number
  status: active
  time_frame: 28d
  data_source: redis_hll
  tier:
  - premium
  - ultimate
...
```

## Répertorier toutes les requêtes SQL Service Ping {#list-all-service-ping-sql-queries}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57016) dans GitLab 13.11.
- [Déployé derrière un feature flag](../administration/feature_flags/_index.md) nommé `usage_data_queries_api`, désactivé par défaut.

{{< /history >}}

Répertorie toutes les requêtes SQL brutes utilisées pour calculer Service Ping. Cette action est soumise au feature flag `usage_data_queries_api` et n'est disponible que pour les utilisateurs [Administrateur](../user/permissions.md) de l'instance GitLab.

```plaintext
GET /usage_data/queries
```

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/usage_data/queries"
```

Exemple de réponse :

```json
{
  "recorded_at": "2021-03-23T06:31:21.267Z",
  "uuid": null,
  "hostname": "localhost",
  "version": "13.11.0-pre",
  "installation_type": "gitlab-development-kit",
  "active_user_count": "SELECT COUNT(\"users\".\"id\") FROM \"users\" WHERE (\"users\".\"state\" IN ('active')) AND (\"users\".\"user_type\" IS NULL OR \"users\".\"user_type\" IN (NULL, 6, 4))",
  "edition": "EE",
  "license_md5": "c701acc03844c45366dd175ef7a4e19c",
  "license_sha256": "366dd175ef7a4e19cc701acc03844c45366dd175ef7a4e19cc701acc03844c45",
  "license_id": null,
  "historical_max_users": 0,
  "licensee": {
    "Name": "John Doe1"
  },
  "license_user_count": null,
  "license_starts_at": "1970-01-01",
  "license_expires_at": "2022-02-23",
  "license_plan": "starter",
  "license_add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  },
  "license_trial": null,
  "license_subscription_id": "0000",
  "license": {},
  "settings": {
    "ldap_encrypted_secrets_enabled": false,
    "operating_system": "mac_os_x-11.2.2"
  },
  "counts": {
    "assignee_lists": "SELECT COUNT(\"lists\".\"id\") FROM \"lists\" WHERE \"lists\".\"list_type\" = 3",
    "boards": "SELECT COUNT(\"boards\".\"id\") FROM \"boards\"",
    "ci_builds": "SELECT COUNT(\"ci_builds\".\"id\") FROM \"ci_builds\" WHERE \"ci_builds\".\"type\" = 'Ci::Build'",
    "ci_internal_pipelines": "SELECT COUNT(\"ci_pipelines\".\"id\") FROM \"ci_pipelines\" WHERE (\"ci_pipelines\".\"source\" IN (1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 12, 13) OR \"ci_pipelines\".\"source\" IS NULL)",
    "ci_external_pipelines": "SELECT COUNT(\"ci_pipelines\".\"id\") FROM \"ci_pipelines\" WHERE \"ci_pipelines\".\"source\" = 6",
    "ci_pipeline_config_auto_devops": "SELECT COUNT(\"ci_pipelines\".\"id\") FROM \"ci_pipelines\" WHERE \"ci_pipelines\".\"config_source\" = 2",
    "ci_pipeline_config_repository": "SELECT COUNT(\"ci_pipelines\".\"id\") FROM \"ci_pipelines\" WHERE \"ci_pipelines\".\"config_source\" = 1",
    "ci_runners": "SELECT COUNT(\"ci_runners\".\"id\") FROM \"ci_runners\"",
...
```

## Répertorier toutes les métriques non-SQL {#list-all-non-sql-metrics}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57050) dans GitLab 13.11.
- [Déployé derrière un feature flag](../administration/feature_flags/_index.md), nommé `usage_data_non_sql_metrics`, désactivé par défaut.

{{< /history >}}

Répertorie toutes les données de métriques non-SQL utilisées dans le Service Ping. Cette action est soumise au feature flag `usage_data_non_sql_metrics` et n'est disponible que pour les utilisateurs [Administrateur](../user/permissions.md) de l'instance GitLab.

```plaintext
GET /usage_data/non_sql_metrics
```

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/usage_data/non_sql_metrics"
```

Exemple de réponse :

```json
{
  "recorded_at": "2021-03-26T07:04:03.724Z",
  "uuid": null,
  "hostname": "localhost",
  "version": "13.11.0-pre",
  "installation_type": "gitlab-development-kit",
  "active_user_count": -3,
  "edition": "EE",
  "license_md5": "bb8cd0d8a6d9569ff3f70b8927a1f949",
  "license_sha256": "366dd175ef7a4e19cc701acc03844c45366dd175ef7a4e19cc701acc03844c45",
  "license_id": null,
  "historical_max_users": 0,
  "licensee": {
    "Name": "John Doe1"
  },
  "license_user_count": null,
  "license_starts_at": "1970-01-01",
  "license_expires_at": "2022-02-26",
  "license_plan": "starter",
  "license_add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  },
  "license_trial": null,
  "license_subscription_id": "0000",
  "license": {},
  "settings": {
    "ldap_encrypted_secrets_enabled": false,
    "operating_system": "mac_os_x-11.2.2"
  },
...
```

## Suivre les événements internes {#track-internal-events}

Suit les événements internes dans l'instance GitLab.

Prérequis :

- Vous devez vous authentifier avec un jeton d'accès personnel disposant de la portée `api` ou `ai_workflows`.

```plaintext
POST /usage_data/track_event
```

Pour envoyer des événements à Snowplow, définissez le paramètre `send_to_snowplow` sur `true`.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --request POST \
     --data '{
       "event": "mr_name_changed",
       "send_to_snowplow": true,
       "namespace_id": 1,
       "project_id": 1,
       "additional_properties": {
         "lang": "eng"
       }
     }' \
     --url "https://gitlab.example.com/api/v4/usage_data/track_event"
```

Si le suivi de plusieurs événements est requis, envoyez un tableau d'événements au point de terminaison `/track_events` :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
     --header "Content-Type: application/json" \
     --request POST \
     --data '{
       "events": [
         {
           "event": "mr_name_changed",
           "namespace_id": 1,
           "project_id": 1,
           "additional_properties": {
             "lang": "eng"
           }
         },
         {
           "event": "mr_name_changed",
           "namespace_id": 2,
           "project_id": 2,
           "additional_properties": {
             "lang": "eng"
           }
         }
       ]
     }' \
     --url "https://gitlab.example.com/api/v4/usage_data/track_events"
```
