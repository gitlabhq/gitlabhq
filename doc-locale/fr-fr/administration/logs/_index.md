---
stage: Analytics
group: Platform Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Système de journalisation
description: Accédez à des fonctionnalités complètes de journalisation et de surveillance.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Le système de journalisation de GitLab fournit des fonctionnalités complètes de journalisation et de surveillance pour analyser votre instance GitLab. Vous pouvez utiliser les journaux pour identifier les problèmes système, enquêter sur les événements de sécurité et analyser les performances des applications. Une entrée de journal existe pour chaque action ; ainsi, lorsque des problèmes surviennent, ces journaux fournissent les données nécessaires pour diagnostiquer et résoudre rapidement les problèmes.

Le système de journalisation :

- Suit toutes les activités des applications dans les composants GitLab dans des fichiers journaux structurés.
- Enregistre les métriques de performance, les erreurs et les événements de sécurité dans des formats standardisés.
- S'intègre aux outils d'analyse de journaux tels qu'Elasticsearch et Splunk via la journalisation JSON.
- Maintient des fichiers journaux séparés pour les différents services et composants GitLab.
- Inclut des identifiants de corrélation pour tracer les requêtes dans l'ensemble du système.

Les fichiers journaux système sont généralement en texte brut dans un format de fichier journal standard.

Le système de journalisation est similaire aux [événements d'audit](../compliance/audit_event_reports.md). Pour plus d'informations, voir également :

- [Personnalisation de la journalisation sur les installations de packages Linux](https://docs.gitlab.com/omnibus/settings/logs/)
- [Analyse des journaux GitLab au format JSON](log_parsing.md)

## Niveaux de journal {#log-levels}

Chaque message de journal a un niveau de journal attribué qui indique son importance et sa verbosité. Chaque journaliseur a un niveau de journal minimum attribué. Un journaliseur émet un message de journal uniquement si son niveau de journal est égal ou supérieur au niveau de journal minimum.

Les niveaux de journal suivants sont pris en charge :

| Niveau | Nom      |
|:------|:----------|
| 0     | `DEBUG`   |
| 1     | `INFO`    |
| 2     | `WARN`    |
| 3     | `ERROR`   |
| 4     | `FATAL`   |
| 5     | `UNKNOWN` |

Les journaliseurs GitLab émettent tous les messages de journal car ils sont définis sur `DEBUG` par défaut.

### Remplacer le niveau de journal par défaut {#override-default-log-level}

Vous pouvez remplacer le niveau de journal minimum pour les journaliseurs GitLab en utilisant la variable d'environnement `GITLAB_LOG_LEVEL`. Les valeurs valides sont soit une valeur de `0` à `5`, soit le nom du niveau de journal.

Exemple :

```shell
GITLAB_LOG_LEVEL=info
```

Pour certains services, d'autres niveaux de journal sont en place et ne sont pas affectés par ce paramètre. Certains de ces services ont leurs propres variables d'environnement pour remplacer le niveau de journal. Par exemple :

| Service                   | Niveau de journal | Variable d'environnement |
|:--------------------------|:----------|:---------------------|
| GitLab Cleanup            | `INFO`    | `DEBUG`              |
| GitLab Doctor             | `INFO`    | `VERBOSE`            |
| GitLab Export             | `INFO`    | `EXPORT_DEBUG`       |
| GitLab Import             | `INFO`    | `IMPORT_DEBUG`       |
| GitLab QA Runtime         | `INFO`    | `QA_LOG_LEVEL`       |
| GitLab Product Usage Data | `INFO`    |                      |
| Google APIs               | `INFO`    |                      |
| Rack Timeout              | `ERROR`   |                      |
| Snowplow Tracker          | `FATAL`   |                      |
| gRPC Client (Gitaly)      | `WARN`    | `GRPC_LOG_LEVEL`     |
| LLM                       | `INFO`    | `LLM_DEBUG`          |

## Rotation des journaux {#log-rotation}

Les journaux d'un service donné peuvent être gérés et pivotés par :

- `logrotate`
- `svlogd` (démon de journalisation de service de `runit`)
- `logrotate` et `svlogd`
- Ou pas du tout

Le tableau suivant contient des informations sur le démon responsable de la gestion et de la rotation des journaux pour les services inclus :

- Les journaux [gérés par `svlogd`](https://docs.gitlab.com/omnibus/settings/logs/#runit-logs) sont écrits dans un fichier appelé `current`. Leurs versions archivées sont compressées dans des fichiers `@<hexadecimal-ID>.s`.
- Le service `logrotate` intégré à GitLab [gère tous les autres journaux](https://docs.gitlab.com/omnibus/settings/logs/#logrotate). Leurs versions archivées sont compressées dans des fichiers `<original-name>.<number>.gz`.

| Type de journal                                        | Géré par logrotate    | Géré par svlogd/runit |
|:------------------------------------------------|:------------------------|:------------------------|
| [Journaux Alertmanager](#alertmanager-logs)         | {{< icon name="dotted-circle" >}} Non  | {{< icon name="check-circle" >}} Oui  |
| [Journaux Consul](#consul-logs)                     | {{< icon name="dotted-circle" >}} Non  | {{< icon name="check-circle" >}} Oui  |
| [Journaux crond](#crond-logs)                       | {{< icon name="dotted-circle" >}} Non  | {{< icon name="check-circle" >}} Oui  |
| [Gitaly](#gitaly-logs)                          | {{< icon name="check-circle" >}} Oui  | {{< icon name="check-circle" >}} Oui  |
| [GitLab Exporter pour les installations de packages Linux](#gitlab-exporter-logs) | {{< icon name="dotted-circle" >}} Non  | {{< icon name="check-circle" >}} Oui  |
| [Journaux GitLab Pages](#pages-logs)                | {{< icon name="check-circle" >}} Oui  | {{< icon name="check-circle" >}} Oui  |
| GitLab Rails                                    | {{< icon name="check-circle" >}} Oui  | {{< icon name="dotted-circle" >}} Non  |
| [Journaux GitLab Shell](#gitlab-shelllog)           | {{< icon name="check-circle" >}} Oui  | {{< icon name="dotted-circle" >}} Non  |
| [Journaux Grafana](#grafana-logs)                   | {{< icon name="dotted-circle" >}} Non  | {{< icon name="check-circle" >}} Oui  |
| [Journaux LogRotate](#logrotate-logs)               | {{< icon name="dotted-circle" >}} Non  | {{< icon name="check-circle" >}} Oui  |
| [Mailroom](#mail_room_jsonlog-default)          | {{< icon name="check-circle" >}} Oui  | {{< icon name="check-circle" >}} Oui  |
| [NGINX](#nginx-logs)                            | {{< icon name="check-circle" >}} Oui  | {{< icon name="check-circle" >}} Oui  |
| [Journaux Patroni](#patroni-logs)                   | {{< icon name="dotted-circle" >}} Non  | {{< icon name="check-circle" >}} Oui  |
| [Journaux PgBouncer](#pgbouncer-logs)               | {{< icon name="dotted-circle" >}} Non  | {{< icon name="check-circle" >}} Oui  |
| [Journaux PostgreSQL](#postgresql-logs)             | {{< icon name="dotted-circle" >}} Non  | {{< icon name="check-circle" >}} Oui  |
| [Journaux Praefect](#praefect-logs)                 | {{< icon name="dotted-circle" >}} Oui | {{< icon name="check-circle" >}} Oui  |
| [Journaux Prometheus](#prometheus-logs)             | {{< icon name="dotted-circle" >}} Non  | {{< icon name="check-circle" >}} Oui  |
| [Puma](#puma-logs)                              | {{< icon name="check-circle" >}} Oui  | {{< icon name="check-circle" >}} Oui  |
| [Journaux Redis](#redis-logs)                       | {{< icon name="dotted-circle" >}} Non  | {{< icon name="check-circle" >}} Oui  |
| [Journaux du registre de conteneurs](#registry-logs)                 | {{< icon name="dotted-circle" >}} Non  | {{< icon name="check-circle" >}} Oui  |
| [Journaux Sentinel](#sentinel-logs)                 | {{< icon name="dotted-circle" >}} Non  | {{< icon name="check-circle" >}} Oui  |
| [Journaux Sidekiq](#sidekiq-logs)                   | {{< icon name="dotted-circle" >}} Non  | {{< icon name="check-circle" >}} Oui  |
| [Journaux Workhorse](#workhorse-logs)               | {{< icon name="check-circle" >}} Oui  | {{< icon name="check-circle" >}} Oui  |

Pour plus d'informations sur les services qui génèrent ces journaux, consultez la [présentation de l'architecture GitLab](../../development/architecture.md).

## Accès aux journaux sur les installations de graphiques Helm {#accessing-logs-on-helm-chart-installations}

Sur les installations de graphiques Helm, les composants GitLab envoient les journaux vers `stdout`, accessible via `kubectl logs`. Les journaux sont également disponibles dans le pod à l'adresse `/var/log/gitlab` pendant la durée de vie du pod.

### Pods avec journaux structurés (filtrage par sous-composant) {#pods-with-structured-logs-subcomponent-filtering}

Certains pods incluent un champ `subcomponent` qui identifie le type de journal spécifique :

```shell
# Webservice pod logs (Rails application)
kubectl logs -l app=webservice -c webservice | jq 'select(."subcomponent"=="<subcomponent-key>")'

# Sidekiq pod logs (background jobs)
kubectl logs -l app=sidekiq | jq 'select(."subcomponent"=="<subcomponent-key>")'
```

Les sections de journal suivantes indiquent le pod approprié et la clé de sous-composant, le cas échéant.

### Autres pods {#other-pods}

Pour les autres composants GitLab qui n'utilisent pas de journaux structurés avec des sous-composants, vous pouvez accéder directement aux journaux.

Pour trouver les sélecteurs de pods disponibles :

```shell
# List all unique app labels in use
kubectl get pods -o jsonpath='{range .items[*]}{.metadata.labels.app}{"\n"}{end}' | grep -v '^$' | sort | uniq

# For pods with app labels
kubectl logs -l app=<pod-selector>

# For specific pods (when app labels aren't available)
kubectl get pods
kubectl logs <pod-name>
```

Pour plus de commandes de dépannage Kubernetes, consultez la [feuille de triche Kubernetes](https://docs.gitlab.com/charts/troubleshooting/kubernetes_cheat_sheet/).

## `production_json.log` {#production_jsonlog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/production_json.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/production_json.log` sur les installations compilées manuellement.
- Sur les pods Webservice sous la clé `subcomponent="production_json"` sur les installations de graphiques Helm.

Il contient un journal structuré pour les requêtes du contrôleur Rails reçues de GitLab, grâce à [Lograge](https://github.com/roidrage/lograge/). Les requêtes de l'API sont enregistrées dans un fichier séparé dans `api_json.log`.

Chaque ligne contient du JSON qui peut être ingéré par des services tels qu'Elasticsearch et Splunk. Des sauts de ligne ont été ajoutés aux exemples pour faciliter la lecture :

```json
{
  "method":"GET",
  "path":"/gitlab/gitlab-foss/issues/1234",
  "format":"html",
  "controller":"Projects::IssuesController",
  "action":"show",
  "status":200,
  "time":"2017-08-08T20:15:54.821Z",
  "params":[{"key":"param_key","value":"param_value"}],
  "remote_ip":"18.245.0.1",
  "user_id":1,
  "username":"admin",
  "queue_duration_s":0.0,
  "gitaly_calls":16,
  "gitaly_duration_s":0.16,
  "redis_calls":115,
  "redis_duration_s":0.13,
  "redis_read_bytes":1507378,
  "redis_write_bytes":2920,
  "correlation_id":"O1SdybnnIq7",
  "cpu_s":17.50,
  "db_duration_s":0.08,
  "view_duration_s":2.39,
  "duration_s":20.54,
  "pid": 81836,
  "worker_id":"puma_0"
}
```

Cet exemple était une requête GET pour un ticket spécifique. Chaque ligne contient également des données de performance, avec des temps en secondes :

- `duration_s` : Temps total pour récupérer la requête
- `queue_duration_s` : Temps total pendant lequel la requête a été mise en file d'attente dans GitLab Workhorse
- `view_duration_s` : Temps total dans les vues Rails
- `db_duration_s` : Temps total pour récupérer les données depuis PostgreSQL
- `cpu_s` : Temps total passé sur le CPU
- `gitaly_duration_s` : Temps total des appels Gitaly
- `gitaly_calls` : Nombre total d'appels effectués vers Gitaly
- `redis_calls` : Nombre total d'appels effectués vers Redis
- `redis_cross_slot_calls` : Nombre total d'appels inter-slots effectués vers Redis
- `redis_allowed_cross_slot_calls` : Nombre total d'appels inter-slots autorisés effectués vers Redis
- `redis_duration_s` : Temps total pour récupérer les données depuis Redis
- `redis_read_bytes` : Nombre total d'octets lus depuis Redis
- `redis_write_bytes` : Nombre total d'octets écrits dans Redis
- `redis_<instance>_calls` : Nombre total d'appels effectués vers une instance Redis
- `redis_<instance>_cross_slot_calls` : Nombre total d'appels inter-slots effectués vers une instance Redis
- `redis_<instance>_allowed_cross_slot_calls` : Nombre total d'appels inter-slots autorisés effectués vers une instance Redis
- `redis_<instance>_duration_s` : Temps total pour récupérer les données depuis une instance Redis
- `redis_<instance>_read_bytes` : Nombre total d'octets lus depuis une instance Redis
- `redis_<instance>_write_bytes` : Nombre total d'octets écrits dans une instance Redis
- `pid` : L'ID de processus Linux du worker (change au redémarrage des workers)
- `worker_id` : L'ID logique du worker (ne change pas au redémarrage des workers)

L'activité de clonage et de récupération des utilisateurs via le transport HTTP apparaît dans le journal sous la forme `action: git_upload_pack`.

De plus, le journal contient l'adresse IP d'origine (`remote_ip`), l'ID de l'utilisateur (`user_id`) et le nom d'utilisateur (`username`).

Certains points de terminaison (tels que `/search`) peuvent envoyer des requêtes à Elasticsearch si vous utilisez la [recherche avancée](../../user/search/advanced_search.md). Ceux-ci journalisent également `elasticsearch_calls` et `elasticsearch_call_duration_s`, qui correspondent à :

- `elasticsearch_calls` : Nombre total d'appels vers Elasticsearch
- `elasticsearch_duration_s` : Temps total pris par les appels Elasticsearch
- `elasticsearch_timed_out_count` : Nombre total d'appels vers Elasticsearch ayant expiré et donc retourné des résultats partiels

Les événements de connexion et d'abonnement ActionCable sont également enregistrés dans ce fichier et suivent le format précédent. Les champs `method`, `path` et `format` ne sont pas applicables et sont toujours vides. La connexion ActionCable ou la classe de canal est utilisée comme `controller`.

```json
{
  "method":null,
  "path":null,
  "format":null,
  "controller":"IssuesChannel",
  "action":"subscribe",
  "status":200,
  "time":"2020-05-14T19:46:22.008Z",
  "params":[{"key":"project_path","value":"gitlab/gitlab-foss"},{"key":"iid","value":"1"}],
  "remote_ip":"127.0.0.1",
  "user_id":1,
  "username":"admin",
  "ua":"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:76.0) Gecko/20100101 Firefox/76.0",
  "correlation_id":"jSOIEynHCUa",
  "duration_s":0.32566
}
```

> [!note]
> Si une erreur se produit, un champ `exception` est inclus avec `class`, `message` et `backtrace`. Les versions précédentes incluaient un champ `error` au lieu de `exception.class` et `exception.message`. Par exemple :

```json
{
  "method": "GET",
  "path": "/admin",
  "format": "html",
  "controller": "Admin::DashboardController",
  "action": "index",
  "status": 500,
  "time": "2019-11-14T13:12:46.156Z",
  "params": [],
  "remote_ip": "127.0.0.1",
  "user_id": 1,
  "username": "root",
  "ua": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:70.0) Gecko/20100101 Firefox/70.0",
  "queue_duration": 274.35,
  "correlation_id": "KjDVUhNvvV3",
  "queue_duration_s":0.0,
  "gitaly_calls":16,
  "gitaly_duration_s":0.16,
  "redis_calls":115,
  "redis_duration_s":0.13,
  "correlation_id":"O1SdybnnIq7",
  "cpu_s":17.50,
  "db_duration_s":0.08,
  "view_duration_s":2.39,
  "duration_s":20.54,
  "pid": 81836,
  "worker_id": "puma_0",
  "exception.class": "NameError",
  "exception.message": "undefined local variable or method `adsf' for #<Admin::DashboardController:0x00007ff3c9648588>",
  "exception.backtrace": [
    "app/controllers/admin/dashboard_controller.rb:11:in `index'",
    "ee/app/controllers/ee/admin/dashboard_controller.rb:14:in `index'",
    "ee/lib/gitlab/ip_address_state.rb:10:in `with'",
    "ee/app/controllers/ee/application_controller.rb:43:in `set_current_ip_address'",
    "lib/gitlab/session.rb:11:in `with_session'",
    "app/controllers/application_controller.rb:450:in `set_session_storage'",
    "app/controllers/application_controller.rb:444:in `set_locale'",
    "ee/lib/gitlab/jira/middleware.rb:19:in `call'"
  ]
}
```

## `production.log` {#productionlog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/production.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/production.log` sur les installations compilées manuellement.

Il contient des informations sur toutes les requêtes effectuées. Vous pouvez voir l'URL et le type de requête, l'adresse IP et les parties du code impliquées dans le traitement de cette requête particulière. De plus, vous pouvez voir toutes les requêtes SQL exécutées et le temps que chacune a pris. Cette tâche est plus utile pour les contributeurs et les développeurs GitLab. Utilisez une partie de ce fichier journal lorsque vous signalez des bogues. Par exemple :

```plaintext
Started GET "/gitlabhq/yaml_db/tree/master" for 168.111.56.1 at 2015-02-12 19:34:53 +0200
Processing by Projects::TreeController#show as HTML
  Parameters: {"project_id"=>"gitlabhq/yaml_db", "id"=>"master"}

  ... [CUT OUT]

  Namespaces"."created_at" DESC, "namespaces"."id" DESC LIMIT 1 [["id", 26]]
  CACHE (0.0ms) SELECT  "members".* FROM "members"  WHERE "members"."source_type" = 'Project' AND "members"."type" IN ('ProjectMember') AND "members"."source_id" = $1 AND "members"."source_type" = $2 AND "members"."user_id" = 1  ORDER BY "members"."created_at" DESC, "members"."id" DESC LIMIT 1  [["source_id", 18], ["source_type", "Project"]]
  CACHE (0.0ms) SELECT  "members".* FROM "members"  WHERE "members"."source_type" = 'Project' AND "members".
  (1.4ms) SELECT COUNT(*) FROM "merge_requests"  WHERE "merge_requests"."target_project_id" = $1 AND ("merge_requests"."state" IN ('opened','reopened')) [["target_project_id", 18]]
  Rendered layouts/nav/_project.html.haml (28.0ms)
  Rendered layouts/_collapse_button.html.haml (0.2ms)
  Rendered layouts/_flash.html.haml (0.1ms)
  Rendered layouts/_page.html.haml (32.9ms)
Completed 200 OK in 166ms (Views: 117.4ms | ActiveRecord: 27.2ms)
```

Dans cet exemple, le serveur a traité une requête HTTP avec l'URL `/gitlabhq/yaml_db/tree/master` depuis l'IP `168.111.56.1` à `2015-02-12 19:34:53 +0200`. La requête a été traitée par `Projects::TreeController`.

## `api_json.log` {#api_jsonlog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/api_json.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/api_json.log` sur les installations compilées manuellement.
- Sur les pods Webservice sous la clé `subcomponent="api_json"` sur les installations de graphiques Helm.

Il vous aide à voir les requêtes effectuées directement vers l'API. Par exemple :

```json
{
  "time":"2018-10-29T12:49:42.123Z",
  "severity":"INFO",
  "duration":709.08,
  "db":14.59,
  "view":694.49,
  "status":200,
  "method":"GET",
  "path":"/api/v4/projects",
  "params":[{"key":"action","value":"git-upload-pack"},{"key":"changes","value":"_any"},{"key":"key_id","value":"secret"},{"key":"secret_token","value":"[FILTERED]"}],
  "host":"localhost",
  "remote_ip":"::1",
  "ua":"Ruby",
  "route":"/api/:version/projects",
  "user_id":1,
  "username":"root",
  "queue_duration":100.31,
  "gitaly_calls":30,
  "gitaly_duration":5.36,
  "pid": 81836,
  "worker_id": "puma_0",
  ...
}
```

Cette entrée montre un point de terminaison interne auquel on accède pour vérifier si une clé SSH associée peut télécharger le projet en question en utilisant un `git fetch` ou un `git clone`. Dans cet exemple, nous voyons :

- `duration` : Temps total en millisecondes pour récupérer la requête
- `queue_duration` : Temps total en millisecondes pendant lequel la requête a été mise en file d'attente dans GitLab Workhorse
- `method` : La méthode HTTP utilisée pour effectuer la requête
- `path` : Le chemin relatif de la requête
- `params` : Paires clé-valeur passées dans une chaîne de requête ou un corps HTTP (les paramètres sensibles, tels que les mots de passe et les jetons, sont filtrés)
- `ua` : L'agent utilisateur du requérant

> [!note]
> Depuis [`Grape Logging`](https://github.com/aserafin/grape_logging) v1.8.4, `view_duration_s` est calculé par [`duration_s - db_duration_s`](https://github.com/aserafin/grape_logging/blob/v1.8.4/lib/grape_logging/middleware/request_logger.rb#L117-L119). Par conséquent, `view_duration_s` peut être affecté par de nombreux facteurs différents, comme le processus de lecture-écriture sur Redis ou HTTP externe, et pas uniquement le processus de sérialisation.

## `application.log` (déprécié) {#applicationlog-deprecated}

{{< history >}}

- [Déprécié](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/111046) dans GitLab 15.10.

{{< /history >}}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/application.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/application.log` sur les installations compilées manuellement.

Il contient une version moins structurée des journaux dans [`application_json.log`](#application_jsonlog), comme cet exemple :

```plaintext
October 06, 2014 11:56: User "Administrator" (admin@example.com) was created
October 06, 2014 11:56: Documentcloud created a new project "Documentcloud / Underscore"
October 06, 2014 11:56: Gitlab Org created a new project "Gitlab Org / Gitlab Ce"
October 07, 2014 11:25: User "Claudie Hodkiewicz" (nasir_stehr@olson.co.uk)  was removed
October 07, 2014 11:25: Project "project133" was removed
```

## `application_json.log` {#application_jsonlog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/application_json.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/application_json.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq et Webservice sous la clé `subcomponent="application_json"` sur les installations de graphiques Helm.

Il vous aide à découvrir les événements se produisant dans votre instance, tels que la création d'utilisateurs et la suppression de projets. Par exemple :

```json
{
  "severity":"INFO",
  "time":"2020-01-14T13:35:15.466Z",
  "correlation_id":"3823a1550b64417f9c9ed8ee0f48087e",
  "message":"User \"Administrator\" (admin@example.com) was created"
}
{
  "severity":"INFO",
  "time":"2020-01-14T13:35:15.466Z",
  "correlation_id":"78e3df10c9a18745243d524540bd5be4",
  "message":"Project \"project133\" was removed"
}
```

## `integrations_json.log` {#integrations_jsonlog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/integrations_json.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/integrations_json.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq et Webservice sous la clé `subcomponent="integrations_json"` sur les installations de graphiques Helm.

Il contient des informations sur les activités d'[intégration](../../user/project/integrations/_index.md), telles que les services Jira, Asana et irker. Il utilise le format JSON, comme dans cet exemple :

```json
{
  "severity":"ERROR",
  "time":"2018-09-06T14:56:20.439Z",
  "service_class":"Integrations::Jira",
  "project_id":8,
  "project_path":"h5bp/html5-boilerplate",
  "message":"Error sending message",
  "client_url":"http://jira.gitlab.com:8080",
  "error":"execution expired"
}
{
  "severity":"INFO",
  "time":"2018-09-06T17:15:16.365Z",
  "service_class":"Integrations::Jira",
  "project_id":3,
  "project_path":"namespace2/project2",
  "message":"Successfully posted",
  "client_url":"http://jira.example.com"
}
```

## `kubernetes.log` (déprécié) {#kuberneteslog-deprecated}

{{< history >}}

- [Déprécié](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) dans GitLab 14.5.

{{< /history >}}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/kubernetes.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/kubernetes.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq sous la clé `subcomponent="kubernetes"` sur les installations de graphiques Helm.

Il journalise les informations relatives aux [clusters basés sur des certificats](../../user/project/clusters/_index.md), telles que les erreurs de connectivité. Chaque ligne contient du JSON qui peut être ingéré par des services tels qu'Elasticsearch et Splunk.

## `git_json.log` {#git_jsonlog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/git_json.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/git_json.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq sous la clé `subcomponent="git_json"` sur les installations de graphiques Helm.

GitLab doit interagir avec les dépôts Git, mais dans de rares cas, quelque chose peut mal tourner. Si cela se produit, vous devez savoir exactement ce qui s'est passé. Ce fichier journal contient toutes les requêtes échouées de GitLab vers les dépôts Git. Dans la majorité des cas, ce fichier est utile uniquement pour les développeurs. Par exemple :

```json
{
   "severity":"ERROR",
   "time":"2019-07-19T22:16:12.528Z",
   "correlation_id":"FeGxww5Hj64",
   "message":"Command failed [1]: /usr/bin/git --git-dir=/Users/vsizov/gitlab-development-kit/gitlab/tmp/tests/gitlab-satellites/group184/gitlabhq/.git --work-tree=/Users/vsizov/gitlab-development-kit/gitlab/tmp/tests/gitlab-satellites/group184/gitlabhq merge --no-ff -mMerge branch 'feature_conflict' into 'feature' source/feature_conflict\n\nerror: failed to push some refs to '/Users/vsizov/gitlab-development-kit/repositories/gitlabhq/gitlab_git.git'"
}
```

## `audit_json.log` {#audit_jsonlog}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> GitLab Free suit un petit nombre d'événements d'audit différents. GitLab Premium en suit beaucoup plus.

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/audit_json.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/audit_json.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq et Webservice sous la clé `subcomponent="audit_json"` sur les installations de graphiques Helm.

Les modifications apportées aux paramètres et aux appartenances des groupes ou des projets (`target_details`) sont enregistrées dans ce fichier. Par exemple :

```json
{
  "severity":"INFO",
  "time":"2018-10-17T17:38:22.523Z",
  "author_id":3,
  "entity_id":2,
  "entity_type":"Project",
  "change":"visibility",
  "from":"Private",
  "to":"Public",
  "author_name":"John Doe4",
  "target_id":2,
  "target_type":"Project",
  "target_details":"namespace2/project2"
}
```

## Journaux Sidekiq {#sidekiq-logs}

Pour les installations de packages Linux, certains journaux Sidekiq se trouvent dans `/var/log/gitlab/sidekiq/current` et comme suit.

### `sidekiq.log` {#sidekiqlog}

{{< history >}}

- Le format de journal par défaut pour les installations de graphiques Helm [a changé de `text` à `json`](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3169) dans GitLab 16.0 et versions ultérieures.

{{< /history >}}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/sidekiq/current` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/sidekiq.log` sur les installations compilées manuellement.

GitLab utilise des jobs en arrière-plan pour le traitement des tâches pouvant prendre un long moment. Toutes les informations concernant le traitement de ces jobs sont écrites dans ce fichier. Par exemple :

```json
{
  "severity":"INFO",
  "time":"2018-04-03T22:57:22.071Z",
  "queue":"cronjob:update_all_mirrors",
  "args":[],
  "class":"UpdateAllMirrorsWorker",
  "retry":false,
  "queue_namespace":"cronjob",
  "jid":"06aeaa3b0aadacf9981f368e",
  "created_at":"2018-04-03T22:57:21.930Z",
  "enqueued_at":"2018-04-03T22:57:21.931Z",
  "pid":10077,
  "worker_id":"sidekiq_0",
  "message":"UpdateAllMirrorsWorker JID-06aeaa3b0aadacf9981f368e: done: 0.139 sec",
  "job_status":"done",
  "duration":0.139,
  "completed_at":"2018-04-03T22:57:22.071Z",
  "db_duration":0.05,
  "db_duration_s":0.0005,
  "gitaly_duration":0,
  "gitaly_calls":0
}
```

Au lieu de journaux JSON, vous pouvez choisir de générer des journaux texte pour Sidekiq. Par exemple :

```plaintext
2023-05-16T16:08:55.272Z pid=82525 tid=23rl INFO: Initializing websocket
2023-05-16T16:08:55.279Z pid=82525 tid=23rl INFO: Booted Rails 6.1.7.2 application in production environment
2023-05-16T16:08:55.279Z pid=82525 tid=23rl INFO: Running in ruby 3.0.5p211 (2022-11-24 revision ba5cf0f7c5) [arm64-darwin22]
2023-05-16T16:08:55.279Z pid=82525 tid=23rl INFO: See LICENSE and the LGPL-3.0 for licensing details.
2023-05-16T16:08:55.279Z pid=82525 tid=23rl INFO: Upgrade to Sidekiq Pro for more features and support: https://sidekiq.org
2023-05-16T16:08:55.286Z pid=82525 tid=7p4t INFO: Cleaning working queues
2023-05-16T16:09:06.043Z pid=82525 tid=7p7d class=ScheduleMergeRequestCleanupRefsWorker jid=efcc73f169c09a514b06da3f INFO: start
2023-05-16T16:09:06.050Z pid=82525 tid=7p7d class=ScheduleMergeRequestCleanupRefsWorker jid=efcc73f169c09a514b06da3f INFO: arguments: []
2023-05-16T16:09:06.065Z pid=82525 tid=7p81 class=UserStatusCleanup::BatchWorker jid=e279aa6409ac33031a314822 INFO: start
2023-05-16T16:09:06.066Z pid=82525 tid=7p81 class=UserStatusCleanup::BatchWorker jid=e279aa6409ac33031a314822 INFO: arguments: []
```

Pour les installations de packages Linux, ajoutez l'option de configuration :

```ruby
sidekiq['log_format'] = 'text'
```

Pour les installations compilées manuellement, modifiez `gitlab.yml` et définissez l'option de configuration Sidekiq `log_format` :

```yaml
  ## Sidekiq
  sidekiq:
    log_format: text
```

### `sidekiq_client.log` {#sidekiq_clientlog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/sidekiq_client.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/sidekiq_client.log` sur les installations compilées manuellement.
- Sur les pods Webservice sous la clé `subcomponent="sidekiq_client"` sur les installations de graphiques Helm.

Ce fichier contient des informations de journalisation sur les jobs avant que Sidekiq ne commence à les traiter, par exemple avant leur mise en file d'attente.

Ce fichier journal suit la même structure que [`sidekiq.log`](#sidekiqlog), il est donc structuré en JSON si vous avez configuré cela pour Sidekiq comme mentionné précédemment.

## `gitlab-shell.log` {#gitlab-shelllog}

GitLab Shell est utilisé par GitLab pour exécuter des commandes Git et fournir un accès SSH aux dépôts Git.

Les informations contenant les requêtes `git-{upload-pack,receive-pack}` se trouvent à `/var/log/gitlab/gitlab-shell/gitlab-shell.log`. Les informations sur les hooks vers GitLab Shell depuis Gitaly se trouvent à `/var/log/gitlab/gitaly/current`.

Exemples d'entrées de journal pour `/var/log/gitlab/gitlab-shell/gitlab-shell.log` :

```json
{
  "duration_ms": 74.104,
  "level": "info",
  "method": "POST",
  "msg": "Finished HTTP request",
  "time": "2020-04-17T20:28:46Z",
  "url": "http://127.0.0.1:8080/api/v4/internal/allowed"
}
{
  "command": "git-upload-pack",
  "git_protocol": "",
  "gl_project_path": "root/example",
  "gl_repository": "project-1",
  "level": "info",
  "msg": "executing git command",
  "time": "2020-04-17T20:28:46Z",
  "user_id": "user-1",
  "username": "root"
}
```

Exemples d'entrées de journal pour `/var/log/gitlab/gitaly/current` :

```json
{
  "method": "POST",
  "url": "http://127.0.0.1:8080/api/v4/internal/allowed",
  "duration": 0.058012959,
  "gitaly_embedded": true,
  "pid": 16636,
  "level": "info",
  "msg": "finished HTTP request",
  "time": "2020-04-17T20:29:08+00:00"
}
{
  "method": "POST",
  "url": "http://127.0.0.1:8080/api/v4/internal/pre_receive",
  "duration": 0.031022552,
  "gitaly_embedded": true,
  "pid": 16636,
  "level": "info",
  "msg": "finished HTTP request",
  "time": "2020-04-17T20:29:08+00:00"
}
```

## Journaux Gitaly {#gitaly-logs}

Ce fichier se trouve dans `/var/log/gitlab/gitaly/current` et est produit par [runit](https://smarden.org/runit/). `runit` est fourni avec le package Linux et une brève explication de son objectif est disponible [dans la documentation du package Linux](https://docs.gitlab.com/omnibus/architecture/#runit).

### `grpc.log` {#grpclog}

Ce fichier se trouve à `/var/log/gitlab/gitlab-rails/grpc.log` pour les installations de packages Linux. Journalisation native [gRPC](https://grpc.io/) utilisée par Gitaly.

### `gitaly_hooks.log` {#gitaly_hookslog}

Ce fichier se trouve à `/var/log/gitlab/gitaly/gitaly_hooks.log` et est produit par la commande `gitaly-hooks`. Il contient également des enregistrements sur les échecs reçus lors du traitement des réponses de l'API GitLab.

## Journaux Puma {#puma-logs}

### `puma_stdout.log` {#puma_stdoutlog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/puma/puma_stdout.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/puma_stdout.log` sur les installations compilées manuellement.

### `puma_stderr.log` {#puma_stderrlog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/puma/puma_stderr.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/puma_stderr.log` sur les installations compilées manuellement.

## `repocheck.log` {#repochecklog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/repocheck.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/repocheck.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq sous la clé `subcomponent="repocheck"` sur les installations de graphiques Helm.

Il journalise les informations chaque fois qu'une [vérification de dépôt est effectuée](../repository_checks.md) sur un projet.

## `importer.log` {#importerlog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/importer.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/importer.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq sous la clé `subcomponent="importer"` sur les installations de graphiques Helm.

Ce fichier journalise la progression des [imports et migrations de projets](../../user/import/_index.md).

## `exporter.log` {#exporterlog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/exporter.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/exporter.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq et Webservice sous la clé `subcomponent="exporter"` sur les installations de graphiques Helm.

Il journalise la progression du processus d'exportation.

## `features_json.log` {#features_jsonlog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/features_json.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/features_json.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq et Webservice sous la clé `subcomponent="features_json"` sur les installations de graphiques Helm.

Les événements de modification des feature flags dans le développement de GitLab sont enregistrés dans ce fichier. Par exemple :

```json
{"severity":"INFO","time":"2020-11-24T02:30:59.860Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable","extra.thing":"true"}
{"severity":"INFO","time":"2020-11-24T02:31:29.108Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable","extra.thing":"true"}
{"severity":"INFO","time":"2020-11-24T02:31:29.129Z","correlation_id":null,"key":"cd_auto_rollback","action":"disable","extra.thing":"false"}
{"severity":"INFO","time":"2020-11-24T02:31:29.177Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable","extra.thing":"Project:1"}
{"severity":"INFO","time":"2020-11-24T02:31:29.183Z","correlation_id":null,"key":"cd_auto_rollback","action":"disable","extra.thing":"Project:1"}
{"severity":"INFO","time":"2020-11-24T02:31:29.188Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable_percentage_of_time","extra.percentage":"50"}
{"severity":"INFO","time":"2020-11-24T02:31:29.193Z","correlation_id":null,"key":"cd_auto_rollback","action":"disable_percentage_of_time"}
{"severity":"INFO","time":"2020-11-24T02:31:29.198Z","correlation_id":null,"key":"cd_auto_rollback","action":"enable_percentage_of_actors","extra.percentage":"50"}
{"severity":"INFO","time":"2020-11-24T02:31:29.203Z","correlation_id":null,"key":"cd_auto_rollback","action":"disable_percentage_of_actors"}
{"severity":"INFO","time":"2020-11-24T02:31:29.329Z","correlation_id":null,"key":"cd_auto_rollback","action":"remove"}
```

## `ci_resource_groups_json.log` {#ci_resource_groups_jsonlog}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/384180) dans GitLab 15.9.

{{< /history >}}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/ci_resource_groups_json.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/ci_resource_group_json.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq et Webservice sous la clé `subcomponent="ci_resource_groups_json"` sur les installations de graphiques Helm.

Il contient des informations sur l'acquisition de [groupes de ressources](../../ci/resource_groups/_index.md). Par exemple :

```json
{"severity":"INFO","time":"2023-02-10T23:02:06.095Z","correlation_id":"01GRYS10C2DZQ9J1G12ZVAD4YD","resource_group_id":1,"processable_id":288,"message":"attempted to assign resource to processable","success":true}
{"severity":"INFO","time":"2023-02-10T23:02:08.945Z","correlation_id":"01GRYS138MYEG32C0QEWMC4BDM","resource_group_id":1,"processable_id":288,"message":"attempted to release resource from processable","success":true}
```

Les exemples montrent les champs `resource_group_id`, `processable_id`, `message` et `success` pour chaque entrée.

## `auth.log` {#authlog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/auth.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/auth.log` sur les installations compilées manuellement.

Ce journal enregistre :

- Les requêtes dépassant la [limite de débit](../settings/rate_limits_on_raw_endpoints.md) sur les points de terminaison bruts.
- Les requêtes abusives vers les [chemins protégés](../settings/protected_paths.md).
- L'ID utilisateur et le nom d'utilisateur, si disponibles.

## `auth_json.log` {#auth_jsonlog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/auth_json.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/auth_json.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq et Webservice sous la clé `subcomponent="auth_json"` sur les installations de graphiques Helm.

Ce fichier contient la version JSON des journaux dans `auth.log`, par exemple :

```json
{
    "severity":"ERROR",
    "time":"2023-04-19T22:14:25.893Z",
    "correlation_id":"01GYDSAKAN2SPZPAMJNRWW5H8S",
    "message":"Rack_Attack",
    "env":"blocklist",
    "remote_ip":"x.x.x.x",
    "request_method":"GET",
    "path":"/group/project.git/info/refs?service=git-upload-pack"
}
```

## `graphql_json.log` {#graphql_jsonlog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/graphql_json.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/graphql_json.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq et Webservice sous la clé `subcomponent="graphql_json"` sur les installations de graphiques Helm.

Les requêtes GraphQL sont enregistrées dans le fichier. Par exemple :

```json
{"query_string":"query IntrospectionQuery{__schema {queryType { name },mutationType { name }}}...(etc)","variables":{"a":1,"b":2},"complexity":181,"depth":1,"duration_s":7}
```

## `clickhouse.log` {#clickhouselog}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/133371) dans GitLab 16.5.

{{< /history >}}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/clickhouse.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/clickhouse.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq et Webservice sous la clé `subcomponent="clickhouse"`.

Le fichier `clickhouse.log` journalise les informations relatives au [client de base de données ClickHouse](../../integration/clickhouse.md) dans GitLab.

## `migrations.log` {#migrationslog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/migrations.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/migrations.log` sur les installations compilées manuellement.

Ce fichier journalise la progression des [migrations de bases de données](../raketasks/maintenance.md#display-status-of-database-migrations).

## `mail_room_json.log` (par défaut) {#mail_room_jsonlog-default}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/mailroom/current` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/mail_room_json.log` sur les installations compilées manuellement.

Ce fichier journal structuré enregistre l'activité interne du gem `mail_room`. Son nom et son chemin sont configurables ; le nom et le chemin peuvent donc ne pas correspondre à ceux documentés précédemment.

## `web_hooks.log` {#web_hookslog}

{{< history >}}

- Introduit dans GitLab 16.3.

{{< /history >}}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/web_hooks.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/web_hooks.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq sous la clé `subcomponent="web_hooks"` sur les installations de graphiques Helm.

Les événements de mise en attente exponentielle, de désactivation et de réactivation du webhook sont enregistrés dans ce fichier. Par exemple :

```json
{"severity":"INFO","time":"2020-11-24T02:30:59.860Z","hook_id":12,"action":"backoff","disabled_until":"2020-11-24T04:30:59.860Z","recent_failures":2}
{"severity":"INFO","time":"2020-11-24T02:30:59.860Z","hook_id":12,"action":"disable","disabled_until":null,"recent_failures":100}
{"severity":"INFO","time":"2020-11-24T02:30:59.860Z","hook_id":12,"action":"enable","disabled_until":null,"recent_failures":0}
```

## Journaux de reconfiguration {#reconfigure-logs}

Les fichiers journaux de reconfiguration se trouvent dans `/var/log/gitlab/reconfigure` pour les installations de packages Linux. Les installations compilées manuellement n'ont pas de journaux de reconfiguration. Un journal de reconfiguration est rempli chaque fois que `gitlab-ctl reconfigure` est exécuté manuellement ou dans le cadre d'une mise à niveau.

Les fichiers journaux de reconfiguration sont nommés selon l'horodatage UNIX du moment où la reconfiguration a été initiée, tel que `1509705644.log`

## `sidekiq_exporter.log` et `web_exporter.log` {#sidekiq_exporterlog-and-web_exporterlog}

Si les métriques Prometheus et le Sidekiq Exporter sont tous les deux activés, Sidekiq démarre un serveur Web et écoute sur le port défini (par défaut : `8082`). Par défaut, les journaux d'accès de Sidekiq Exporter sont désactivés mais peuvent être activés :

- Utilisez l'option `sidekiq['exporter_log_enabled'] = true` dans `/etc/gitlab/gitlab.rb` sur les installations de packages Linux.
- Utilisez l'option `sidekiq_exporter.log_enabled` dans `gitlab.yml` sur les installations compilées manuellement.

Lorsqu'il est activé, selon votre méthode d'installation, ce fichier se trouve à :

- `/var/log/gitlab/gitlab-rails/sidekiq_exporter.log` sur les installations de packages Linux.
- `/home/git/gitlab/log/sidekiq_exporter.log` sur les installations compilées manuellement.

Si les métriques Prometheus et le Web Exporter sont tous les deux activés, Puma démarre un serveur Web et écoute sur le port défini (par défaut : `8083`), et les journaux d'accès sont générés à un emplacement basé sur votre méthode d'installation :

- `/var/log/gitlab/gitlab-rails/web_exporter.log` sur les installations de packages Linux.
- `/home/git/gitlab/log/web_exporter.log` sur les installations compilées manuellement.

## `database_load_balancing.log` {#database_load_balancinglog}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Contient des détails sur la [répartition de charge de base de données](../postgresql/database_load_balancing.md) GitLab.

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/database_load_balancing.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/database_load_balancing.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq et Webservice sous la clé `subcomponent="database_load_balancing"` sur les installations de graphiques Helm.

## `zoekt.log` {#zoektlog}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/110980) dans GitLab 15.9.

{{< /history >}}

Ce fichier journalise les informations relatives à la [recherche de code exact](../../user/search/exact_code_search.md).

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/zoekt.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/zoekt.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq et Webservice sous la clé `subcomponent="zoekt"` sur les installations de graphiques Helm.

## `elasticsearch.log` {#elasticsearchlog}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Ce fichier journalise les informations relatives à l'intégration Elasticsearch, y compris les erreurs lors de l'indexation ou de la recherche dans Elasticsearch.

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/elasticsearch.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/elasticsearch.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq et Webservice sous la clé `subcomponent="elasticsearch"` sur les installations de graphiques Helm.

Chaque ligne contient du JSON qui peut être ingéré par des services tels qu'Elasticsearch et Splunk. Des sauts de ligne ont été ajoutés à la ligne d'exemple suivante pour plus de clarté :

```json
{
  "severity":"DEBUG",
  "time":"2019-10-17T06:23:13.227Z",
  "correlation_id":null,
  "message":"redacted_search_result",
  "class_name":"Milestone",
  "id":2,
  "ability":"read_milestone",
  "current_user_id":2,
  "query":"project"
}
```

## `exceptions_json.log` {#exceptions_jsonlog}

Ce fichier journalise les informations sur les exceptions suivies par `Gitlab::ErrorTracking`, qui fournit un moyen standard et cohérent de traiter les exceptions récupérées.

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/exceptions_json.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/exceptions_json.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq et Webservice sous la clé `subcomponent="exceptions_json"` sur les installations de graphiques Helm.

Chaque ligne contient du JSON qui peut être ingéré par Elasticsearch. Par exemple :

```json
{
  "severity": "ERROR",
  "time": "2019-12-17T11:49:29.485Z",
  "correlation_id": "AbDVUrrTvM1",
  "extra.project_id": 55,
  "extra.relation_key": "milestones",
  "extra.relation_index": 1,
  "exception.class": "NoMethodError",
  "exception.message": "undefined method `strong_memoize' for #<Gitlab::ImportExport::RelationFactory:0x00007fb5d917c4b0>",
  "exception.backtrace": [
    "lib/gitlab/import_export/relation_factory.rb:329:in `unique_relation?'",
    "lib/gitlab/import_export/relation_factory.rb:345:in `find_or_create_object!'"
  ]
}
```

## `service_measurement.log` {#service_measurementlog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/service_measurement.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/service_measurement.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq et Webservice sous la clé `subcomponent="service_measurement"` sur les installations de graphiques Helm.

Il contient uniquement un journal structuré unique avec des mesures pour chaque exécution de service. Il contient des mesures telles que le nombre d'appels SQL, `execution_time`, `gc_stats` et `memory usage`.

Par exemple :

```json
{ "severity":"INFO", "time":"2020-04-22T16:04:50.691Z","correlation_id":"04f1366e-57a1-45b8-88c1-b00b23dc3616","class":"Projects::ImportExport::ExportService","current_user":"John Doe","project_full_path":"group1/test-export","file_path":"/path/to/archive","gc_stats":{"count":{"before":127,"after":127,"diff":0},"heap_allocated_pages":{"before":10369,"after":10369,"diff":0},"heap_sorted_length":{"before":10369,"after":10369,"diff":0},"heap_allocatable_pages":{"before":0,"after":0,"diff":0},"heap_available_slots":{"before":4226409,"after":4226409,"diff":0},"heap_live_slots":{"before":2542709,"after":2641420,"diff":98711},"heap_free_slots":{"before":1683700,"after":1584989,"diff":-98711},"heap_final_slots":{"before":0,"after":0,"diff":0},"heap_marked_slots":{"before":2542704,"after":2542704,"diff":0},"heap_eden_pages":{"before":10369,"after":10369,"diff":0},"heap_tomb_pages":{"before":0,"after":0,"diff":0},"total_allocated_pages":{"before":10369,"after":10369,"diff":0},"total_freed_pages":{"before":0,"after":0,"diff":0},"total_allocated_objects":{"before":24896308,"after":24995019,"diff":98711},"total_freed_objects":{"before":22353599,"after":22353599,"diff":0},"malloc_increase_bytes":{"before":140032,"after":6650240,"diff":6510208},"malloc_increase_bytes_limit":{"before":25804104,"after":25804104,"diff":0},"minor_gc_count":{"before":94,"after":94,"diff":0},"major_gc_count":{"before":33,"after":33,"diff":0},"remembered_wb_unprotected_objects":{"before":34284,"after":34284,"diff":0},"remembered_wb_unprotected_objects_limit":{"before":68568,"after":68568,"diff":0},"old_objects":{"before":2404725,"after":2404725,"diff":0},"old_objects_limit":{"before":4809450,"after":4809450,"diff":0},"oldmalloc_increase_bytes":{"before":140032,"after":6650240,"diff":6510208},"oldmalloc_increase_bytes_limit":{"before":68537556,"after":68537556,"diff":0}},"time_to_finish":0.12298400001600385,"number_of_sql_calls":70,"memory_usage":"0.0 MiB","label":"process_48616"}
```

## `geo.log` {#geolog}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/geo.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/geo.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq et Webservice sous la clé `subcomponent="geo"` sur les installations de graphiques Helm.

Ce fichier contient des informations sur les tentatives de synchronisation des dépôts et des fichiers par Geo. Chaque ligne du fichier contient une entrée JSON séparée pouvant être ingérée dans (par exemple, Elasticsearch ou Splunk).

Par exemple :

```json
{"severity":"INFO","time":"2017-08-06T05:40:16.104Z","message":"Repository update","project_id":1,"source":"repository","resync_repository":true,"resync_wiki":true,"class":"Gitlab::Geo::LogCursor::Daemon","cursor_delay_s":0.038}
```

Ce message indique que Geo a détecté qu'une mise à jour de dépôt était nécessaire pour le projet `1`.

## `update_mirror_service_json.log` {#update_mirror_service_jsonlog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/update_mirror_service_json.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/update_mirror_service_json.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq sous la clé `subcomponent="update_mirror_service_json"` sur les installations de graphiques Helm.

Ce fichier contient des informations sur les erreurs LFS survenues lors de la mise en miroir de projet. Pendant que nous travaillons à déplacer d'autres erreurs de mise en miroir de projet dans ce journal, le [journal général](#productionlog) peut être utilisé.

```json
{
   "severity":"ERROR",
   "time":"2020-07-28T23:29:29.473Z",
   "correlation_id":"5HgIkCJsO53",
   "user_id":"x",
   "project_id":"x",
   "import_url":"https://mirror-source/group/project.git",
   "error_message":"The LFS objects download list couldn't be imported. Error: Unauthorized"
}
```

## `llm.log` {#llmlog}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120506) dans GitLab 16.0.

{{< /history >}}

Le fichier `llm.log` journalise les informations relatives aux [fonctionnalités d'IA](../../user/gitlab_duo/_index.md).  La journalisation inclut des informations sur les événements d'IA.

### Journalisation des entrées et sorties LLM {#llm-input-and-output-logging}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/13401) dans GitLab 17.2 [avec un indicateur](../feature_flags/_index.md) nommé `expanded_ai_logging`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique. Cette fonctionnalité est disponible pour les tests, mais n'est pas prête pour une utilisation en production.

Pour journaliser l'entrée de l'invite LLM et la sortie de réponse, activez le feature flag `expanded_ai_logging`. Cet indicateur est destiné à une utilisation sur GitLab.com uniquement, et non sur les instances GitLab Self-Managed.

Cet indicateur est désactivé par défaut et ne peut être activé que :

- Pour GitLab.com, lorsque vous fournissez votre consentement via un [ticket d'assistance](https://about.gitlab.com/support/portal/) GitLab.

Par défaut, le journal ne contient pas les entrées d'invites LLM et les sorties de réponse afin de prendre en charge les [politiques de conservation des données](../../user/gitlab_duo/data_usage.md#data-retention) des données de fonctionnalités IA.

Le fichier journal est situé à :

- Dans le fichier `/var/log/gitlab/gitlab-rails/llm.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/llm.log` sur les installations compilées manuellement.
- Sur les pods Webservice sous la clé `subcomponent="llm"` sur les installations de graphiques Helm.

## `epic_work_item_sync.log` {#epic_work_item_synclog}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120506) dans GitLab 16.9.

{{< /history >}}

Le fichier `epic_work_item_sync.log` journalise les informations relatives à la synchronisation et à la migration des epics en tant qu'éléments de travail.

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/epic_work_item_sync.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/epic_work_item_sync.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq et Webservice sous la clé `subcomponent="epic_work_item_sync"` sur les installations de graphiques Helm.

## `secret_push_protection.log` {#secret_push_protectionlog}

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137812) dans GitLab 16.7.

{{< /history >}}

Le fichier `secret_push_protection.log` journalise les informations relatives à la fonctionnalité de [protection des push de secrets](../../user/application_security/secret_detection/secret_push_protection/_index.md).

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/secret_push_protection.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/secret_push_protection.log` sur les installations compilées manuellement.
- Sur les pods Webservice sous la clé `subcomponent="secret_push_protection"` sur les installations de graphiques Helm.

## `active_context.log` {#active_contextlog}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/work_items/554925) dans GitLab 18.3.

{{< /history >}}

Le fichier `active_context.log` journalise les informations relatives aux pipelines d'embedding via la [couche `ActiveContext`](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/ai_context_abstraction_layer/).

GitLab prend en charge les embeddings de code `ActiveContext`. Ce pipeline gère la génération d'embeddings pour les fichiers de code de projet. Pour plus d'informations, consultez la [conception de l'architecture](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/codebase_as_chat_context/code_embeddings/).

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/active_context.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/active_context.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq sous la clé `subcomponent="activecontext"` sur les installations de graphiques Helm.

## `ai_catalog.log` {#ai_cataloglog}

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/576627) dans GitLab 18.8.

{{< /history >}}

Le fichier `ai_catalog.log` journalise les informations relatives au [catalogue d'IA](../../user/duo_agent_platform/ai_catalog.md), y compris lorsque les flows et les agents du catalogue d'IA sont exécutés.

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/ai_catalog.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/ai_catalog.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq sous la clé `subcomponent="ai_catalog"` sur les installations de graphiques Helm.

## `user_experience_slis.log` {#user_experience_slislog}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/user_experience_slis.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/user_experience_slis.log` sur les installations compilées manuellement.
- Sur les pods Webservice sous la clé `subcomponent="user_experience_slis"` sur les installations de graphiques Helm.

Il contient un journal structuré JSON pour les SLI d'expérience utilisateur correspondant à ses métriques.

Chaque ligne contient du JSON qui peut être ingéré par des services tels qu'Elasticsearch.

Exemple :

```json
{
  "checkpoint": "start",
  "component": "gitlab",
  "correlation_id": "3823a1550b64417f9c9ed8ee0f48087e",
  "covered_experience": "create_merge_request",
  "elapsed_time_s": 0,
  "environment": "gprd",
  "feature_category": "code_review_workflow",
  "logtag": "F",
  "meta": {
    "caller_id": "Projects::MergeRequests::CreationsController#create",
    "client_id": "user/123",
    "feature_category": "code_review_workflow",
    "gl_user_id": 123,
    "organization_id": 456,
    "project": "project/path/here",
    "remote_ip": "x.x.x.x",
    "root_namespace": "project",
    "subscription_plan": "ultimate",
    "user": "a_username"
  },
  "severity": "INFO",
  "shard": "default",
  "stage": "cny",
  "start_time": "2025-10-31 15:21:40 UTC",
  "subcomponent": "user_experience_slis",
  "tag": "web-cny-rails.var.log.containers.gitlab-cny-webservice-web-123-abc_gitlab-cny_webservice-4567890.log",
  "tier": "sv",
  "time": "2025-10-31T15:21:40.333Z",
  "type": "web",
  "urgency": "async_fast",
  "urgency_threshold_s": 15
}
```

Les champs disponibles sont documentés dans le [document de conception pour les SLI d'expérience utilisateur](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/user_experience_slis/#sdk-requirements).

## Journaux du registre de conteneurs {#registry-logs}

Pour les installations de packages Linux, les journaux du registre de conteneurs se trouvent dans `/var/log/gitlab/registry/current`.

## Journaux NGINX {#nginx-logs}

Pour les installations de packages Linux, les journaux NGINX se trouvent dans :

- `/var/log/gitlab/nginx/gitlab_access.log` : Un journal des requêtes envoyées à GitLab
- `/var/log/gitlab/nginx/gitlab_error.log` : Un journal des erreurs NGINX pour GitLab
- `/var/log/gitlab/nginx/gitlab_pages_access.log` : Un journal des requêtes envoyées aux sites statiques Pages
- `/var/log/gitlab/nginx/gitlab_pages_error.log` : Un journal des erreurs NGINX pour les sites statiques Pages
- `/var/log/gitlab/nginx/gitlab_registry_access.log` : Un journal des requêtes envoyées au registre de conteneurs
- `/var/log/gitlab/nginx/gitlab_registry_error.log` : Un journal des erreurs NGINX pour le registre de conteneurs
- `/var/log/gitlab/nginx/gitlab_mattermost_access.log` : Un journal des requêtes envoyées à Mattermost
- `/var/log/gitlab/nginx/gitlab_mattermost_error.log` : Un journal des erreurs NGINX pour Mattermost

Voici le format de journal d'accès NGINX GitLab par défaut :

```plaintext
'$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"'
```

Les `$request` et `$http_referer` sont [filtrés](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/support/nginx/gitlab) pour les paramètres de chaîne de requête sensibles tels que les jetons secrets.

## Journaux Pages {#pages-logs}

Pour les installations de package Linux, les journaux Pages se trouvent dans `/var/log/gitlab/gitlab-pages/current`.

Par exemple :

```json
{
  "level": "info",
  "msg": "GitLab Pages Daemon",
  "revision": "52b2899",
  "time": "2020-04-22T17:53:12Z",
  "version": "1.17.0"
}
{
  "level": "info",
  "msg": "URL: https://gitlab.com/gitlab-org/gitlab-pages",
  "time": "2020-04-22T17:53:12Z"
}
{
  "gid": 998,
  "in-place": false,
  "level": "info",
  "msg": "running the daemon as unprivileged user",
  "time": "2020-04-22T17:53:12Z",
  "uid": 998
}
```

## Journal des données d'utilisation du produit {#product-usage-data-log}

> [!note]
> Nous déconseillons d'utiliser les journaux bruts pour analyser l'utilisation des fonctionnalités, car la qualité des données n'a pas encore été certifiée pour l'exactitude.
>
> La liste des événements peut changer à chaque version en fonction des nouvelles fonctionnalités ou des modifications apportées aux fonctionnalités existantes. Les rapports d'adoption certifiés intégrés au produit seront disponibles une fois les données prêtes pour l'analyse.

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/product_usage_data.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/product_usage_data.log` sur les installations compilées manuellement.
- Sur les pods Webservice sous la clé `subcomponent="product_usage_data"` sur les installations de graphiques Helm.

Il contient des journaux au format JSON des événements d'utilisation du produit suivis via Snowplow. Chaque ligne du fichier contient une entrée JSON distincte qui peut être ingérée par des services tels qu'Elasticsearch ou Splunk. Des sauts de ligne ont été ajoutés aux exemples pour faciliter la lecture :

```json
{
  "severity":"INFO",
  "time":"2025-04-09T13:43:40.254Z",
  "message":"sending event",
  "payload":"{
  \"e\":\"se\",
  \"se_ca\":\"projects:merge_requests:diffs\",
  \"se_ac\":\"i_code_review_user_searches_diff\",
  \"cx\":\"eyJzY2hlbWEiOiJpZ2x1OmNvbS5zbm93cGxvd2FuYWx5dGljcy5zbm93cGxvdy9jb250ZXh0cy9qc29uc2NoZW1hLzEtMC0xIiwiZGF0YSI6W3sic2NoZW1hIjoiaWdsdTpjb20uZ2l0bGFiL2dpdGxhYl9zdGFuZGFyZC9qc29uc2NoZW1hLzEtMS0xIiwiZGF0YSI6eyJlbnZpcm9ubWVudCI6ImRldmVsb3BtZW50Iiwic291cmNlIjoiZ2l0bGFiLXJhaWxzIiwiY29ycmVsYXRpb25faWQiOiJlNDk2NzNjNWI2MGQ5ODc0M2U4YWI0MjZiMTZmMTkxMiIsInBsYW4iOiJkZWZhdWx0IiwiZXh0cmEiOnt9LCJ1c2VyX2lkIjpudWxsLCJnbG9iYWxfdXNlcl9pZCI6bnVsbCwiaXNfZ2l0bGFiX3RlYW1fbWVtYmVyIjpudWxsLCJuYW1lc3BhY2VfaWQiOjMxLCJwcm9qZWN0X2lkIjo2LCJmZWF0dXJlX2VuYWJsZWRfYnlfbmFtZXNwYWNlX2lkcyI6bnVsbCwicmVhbG0iOiJzZWxmLW1hbmFnZWQiLCJpbnN0YW5jZV9pZCI6IjJkMDg1NzBkLWNmZGItNDFmMy1iODllLWM3MTM5YmFjZTI3NSIsImhvc3RfbmFtZSI6ImpsYXJzZW4tLTIwMjIxMjE0LVBWWTY5IiwiaW5zdGFuY2VfdmVyc2lvbiI6IjE3LjExLjAiLCJjb250ZXh0X2dlbmVyYXRlZF9hdCI6IjIwMjUtMDQtMDkgMTM6NDM6NDAgVVRDIn19LHsic2NoZW1hIjoiaWdsdTpjb20uZ2l0bGFiL2dpdGxhYl9zZXJ2aWNlX3BpbmcvanNvbnNjaGVtYS8xLTAtMSIsImRhdGEiOnsiZGF0YV9zb3VyY2UiOiJyZWRpc19obGwiLCJldmVudF9uYW1lIjoiaV9jb2RlX3Jldmlld191c2VyX3NlYXJjaGVzX2RpZmYifX1dfQ==\",
  \"p\":\"srv\",
  \"dtm\":\"1744206220253\",
  \"tna\":\"gl\",
  \"tv\":\"rb-0.8.0\",
  \"eid\":\"4f067989-d10d-40b0-9312-ad9d7355be7f\"
}
```

Pour inspecter ces journaux, vous pouvez utiliser la [tâche Rake](../raketasks/_index.md) `product_usage_data:format` qui formate la sortie JSON et décode les données de contexte encodées en base64 pour une meilleure lisibilité :

```shell
gitlab-rake "product_usage_data:format[log/product_usage_data.log]"
# or pipe the logs directly
cat log/product_usage_data.log | gitlab-rake product_usage_data:format
# or tail the logs in real-time
tail -f log/product_usage_data.log | gitlab-rake product_usage_data:format
```

Vous pouvez désactiver ce journal en définissant la variable d'environnement `GITLAB_DISABLE_PRODUCT_USAGE_EVENT_LOGGING` sur n'importe quelle valeur.

## Journaux Let's Encrypt {#lets-encrypt-logs}

Pour les installations de package Linux, les journaux de [renouvellement automatique](https://docs.gitlab.com/omnibus/settings/ssl/#renew-the-certificates-automatically) de Let's Encrypt se trouvent dans `/var/log/gitlab/lets-encrypt/`.

## Journaux Mattermost {#mattermost-logs}

Pour les installations de package Linux, les journaux Mattermost se trouvent aux emplacements suivants :

- `/var/log/gitlab/mattermost/mattermost.log`
- `/var/log/gitlab/mattermost/current`

## Journaux Workhorse {#workhorse-logs}

Pour les installations de package Linux, les journaux Workhorse se trouvent dans `/var/log/gitlab/gitlab-workhorse/current`.

## Journaux Patroni {#patroni-logs}

Pour les installations de package Linux, les journaux Patroni se trouvent dans `/var/log/gitlab/patroni/current`.

## Journaux PgBouncer {#pgbouncer-logs}

Pour les installations de package Linux, les journaux PgBouncer se trouvent dans `/var/log/gitlab/pgbouncer/current`.

## Journaux PostgreSQL {#postgresql-logs}

Pour les installations de package Linux, les journaux PostgreSQL se trouvent dans `/var/log/gitlab/postgresql/current`.

Si Patroni est utilisé, les journaux PostgreSQL sont stockés dans les [journaux Patroni](#patroni-logs) à la place.

## Journaux Prometheus {#prometheus-logs}

Pour les installations de package Linux, les journaux Prometheus se trouvent dans `/var/log/gitlab/prometheus/current`.

## Journaux Redis {#redis-logs}

Pour les installations de package Linux, les journaux Redis se trouvent dans `/var/log/gitlab/redis/current`.

## Journaux Sentinel {#sentinel-logs}

Pour les installations de package Linux, les journaux Sentinel se trouvent dans `/var/log/gitlab/sentinel/current`.

## Journaux Alertmanager {#alertmanager-logs}

Pour les installations de package Linux, les journaux Alertmanager se trouvent dans `/var/log/gitlab/alertmanager/current`.

## Journaux Consul {#consul-logs}

Pour les installations de package Linux, les journaux Consul se trouvent dans `/var/log/gitlab/consul/current`.

<!-- vale gitlab_base.Spelling = NO -->

## Journaux crond {#crond-logs}

Pour les installations de package Linux, les journaux crond se trouvent dans `/var/log/gitlab/crond/`.

<!-- vale gitlab_base.Spelling = YES -->

## Journaux Grafana {#grafana-logs}

Pour les installations de package Linux, les journaux Grafana se trouvent dans `/var/log/gitlab/grafana/current`.

## Journaux LogRotate {#logrotate-logs}

Pour les installations de package Linux, les journaux `logrotate` se trouvent dans `/var/log/gitlab/logrotate/current`.

## Journaux GitLab Monitor {#gitlab-monitor-logs}

Pour les installations de package Linux, les journaux GitLab Monitor se trouvent dans `/var/log/gitlab/gitlab-monitor/`.

## Journaux GitLab Exporter {#gitlab-exporter-logs}

Pour les installations de package Linux, les journaux GitLab Exporter se trouvent dans `/var/log/gitlab/gitlab-exporter/current`.

## Journaux du serveur agent GitLab pour Kubernetes {#gitlab-agent-server-for-kubernetes-logs}

Pour les installations de package Linux, les journaux du serveur agent GitLab pour Kubernetes se trouvent dans `/var/log/gitlab/gitlab-kas/current`.

## Journaux Praefect {#praefect-logs}

Pour les installations de package Linux, les journaux Praefect se trouvent dans `/var/log/gitlab/praefect/`.

GitLab suit également les [métriques Prometheus pour Gitaly Cluster (Praefect)](../gitaly/praefect/monitoring.md).

## Journal de sauvegarde {#backup-log}

Pour les installations de package Linux, le journal de sauvegarde est situé dans `/var/log/gitlab/gitlab-rails/backup_json.log`.

Sur les installations Helm chart, le journal de sauvegarde est stocké dans le pod Toolbox, à `/var/log/gitlab/backup_json.log`.

Ce journal est renseigné lors de la [création d'une sauvegarde GitLab](../backup_restore/_index.md). Vous pouvez utiliser ce journal pour comprendre comment le processus de sauvegarde s'est déroulé.

## Statistiques de la barre de performance {#performance-bar-stats}

Ce journal est situé :

- Dans le fichier `/var/log/gitlab/gitlab-rails/performance_bar_json.log` sur les installations de packages Linux.
- Dans le fichier `/home/git/gitlab/log/performance_bar_json.log` sur les installations compilées manuellement.
- Sur les pods Sidekiq sous la clé `subcomponent="performance_bar_json"` sur les installations de graphiques Helm.

Les statistiques de la barre de performance (actuellement uniquement la durée des requêtes SQL) sont enregistrées dans ce fichier. Par exemple :

```json
{"severity":"INFO","time":"2020-12-04T09:29:44.592Z","correlation_id":"33680b1490ccd35981b03639c406a697","filename":"app/models/ci/pipeline.rb","method_path":"app/models/ci/pipeline.rb:each_with_object","request_id":"rYHomD0VJS4","duration_ms":26.889,"count":2,"query_type": "active-record"}
```

Ces statistiques sont journalisées sur .com uniquement, désactivées sur les déploiements auto-gérés.

## Collecte des journaux {#gathering-logs}

Lors du [dépannage](../troubleshooting/_index.md) de problèmes qui ne sont pas localisés dans l'un des composants listés précédemment, il est utile de collecter simultanément plusieurs journaux et statistiques depuis une instance GitLab.

> [!note]
> Le support GitLab demande souvent l'un d'entre eux et maintient les outils requis.

### Suivre brièvement les journaux principaux {#briefly-tail-the-main-logs}

Si le bug ou l'erreur est facilement reproductible, enregistrez les journaux GitLab principaux [dans un fichier](../troubleshooting/linux_cheat_sheet.md#files-and-directories) tout en reproduisant le problème plusieurs fois :

```shell
sudo gitlab-ctl tail | tee /tmp/<case-ID-and-keywords>.log
```

Terminez la collecte des journaux avec <kbd>Contrôle</kbd> + <kbd>C</kbd>.

### Collecte des journaux SOS {#gathering-sos-logs}

Si des dégradations de performances ou des erreurs en cascade se produisent et ne peuvent pas être facilement attribuées à l'un des composants GitLab listés précédemment, [utilisez nos scripts SOS](../troubleshooting/diagnostics_tools.md#sos-scripts).

### Fast-stats {#fast-stats}

[Fast-stats](https://gitlab.com/gitlab-com/support/toolbox/fast-stats) est un outil permettant de créer et de comparer des statistiques de performance à partir des journaux GitLab. Pour plus de détails et des instructions pour l'exécuter, consultez la [documentation de fast-stats](https://gitlab.com/gitlab-com/support/toolbox/fast-stats#usage).

## Trouver les entrées de journal pertinentes avec un ID de corrélation {#find-relevant-log-entries-with-a-correlation-id}

La plupart des requêtes ont un ID de journal qui peut être utilisé pour [trouver les entrées de journal pertinentes](tracing_correlation_id.md).
