---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Analyser les logs GitLab avec `jq`
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Nous recommandons d'utiliser des outils d'agrégation et de recherche de logs comme Kibana et Splunk dans la mesure du possible, mais s'ils ne sont pas disponibles, vous pouvez toujours analyser rapidement les [logs GitLab](_index.md) au format JSON à l'aide de [`jq`](https://stedolan.github.io/jq/).

> [!note]
> Spécifiquement pour résumer les événements d'erreur et les statistiques d'utilisation de base, l'équipe de support GitLab propose l'outil spécialisé [`fast-stats` tool](https://gitlab.com/gitlab-com/support/toolbox/fast-stats/#when-to-use-it). Il peut généralement traiter des logs plus volumineux bien plus rapidement que `jq` et génère une sélection plus large d'informations statistiques.

## Qu'est-ce que JQ ? {#what-is-jq}

Comme indiqué dans son [manuel](https://stedolan.github.io/jq/manual/), `jq` est un processeur JSON en ligne de commande. Les exemples suivants incluent des cas d'utilisation ciblés pour l'analyse des fichiers de logs GitLab.

## Analyse des logs {#parsing-logs}

Les exemples listés ci-dessous font référence à leurs fichiers de logs respectifs par leurs chemins d'installation relatifs du package Linux et leurs noms de fichiers par défaut. Retrouvez les chemins complets respectifs dans les [sections des logs GitLab](_index.md#production_jsonlog).

### Logs compressés {#compressed-logs}

Lorsque les [fichiers de logs sont alternés](https://smarden.org/runit/svlogd.8), ils sont renommés au format d'horodatage Unix et compressés avec `gzip`. Le nom de fichier résultant ressemble à `@40000000624492fa18da6f34.s`. Ces fichiers doivent être traités différemment avant l'analyse, contrairement aux fichiers de logs plus récents :

- Pour décompresser le fichier, utilisez `gunzip -S .s @40000000624492fa18da6f34.s`, en remplaçant le nom de fichier par le nom de votre fichier de log compressé.
- Pour lire ou rediriger le fichier directement, utilisez `zcat` ou `zless`.
- Pour rechercher dans le contenu du fichier, utilisez `zgrep`.

### Commandes générales {#general-commands}

#### Rediriger la sortie colorisée de `jq` vers `less` {#pipe-colorized-jq-output-into-less}

```shell
jq . <FILE> -C | less -R
```

#### Rechercher un terme et afficher joliment toutes les lignes correspondantes {#search-for-a-term-and-pretty-print-all-matching-lines}

```shell
grep <TERM> <FILE> | jq .
```

#### Ignorer les lignes JSON non valides {#skip-invalid-lines-of-json}

```shell
jq -cR 'fromjson?' file.json | jq <COMMAND>
```

Par défaut, `jq` génère une erreur lorsqu'il rencontre une ligne qui n'est pas du JSON valide. Cette commande ignore toutes les lignes non valides et analyse le reste.

#### Afficher la plage temporelle d'un log JSON {#print-a-json-logs-time-range}

```shell
cat log.json | (head -1; tail -1) | jq '.time'
```

Utilisez `zcat` si le fichier a été alterné et compressé :

```shell
zcat @400000006026b71d1a7af804.s | (head -1; tail -1) | jq '.time'

zcat some_json.log.25.gz | (head -1; tail -1) | jq '.time'
```

#### Obtenir l'activité pour un ID de corrélation dans plusieurs logs JSON par ordre chronologique {#get-activity-for-correlation-id-across-multiple-json-logs-in-chronological-order}

```shell
grep -hR <correlationID> | jq -c -R 'fromjson?' | jq -C -s 'sort_by(.time)'  | less -R
```

### Analyse de `gitlab-rails/production_json.log` et `gitlab-rails/api_json.log` {#parsing-gitlab-railsproduction_jsonlog-and-gitlab-railsapi_jsonlog}

#### Trouver toutes les requêtes avec un code de statut 5XX {#find-all-requests-with-a-5xx-status-code}

```shell
jq 'select(.status >= 500)' <FILE>
```

#### Les 10 requêtes les plus lentes {#top-10-slowest-requests}

```shell
jq -s 'sort_by(-.duration_s) | limit(10; .[])' <FILE>
```

#### Trouver et afficher joliment toutes les requêtes liées à un projet {#find-and-pretty-print-all-requests-related-to-a-project}

```shell
grep <PROJECT_NAME> <FILE> | jq .
```

#### Trouver toutes les requêtes avec une durée totale > 5 secondes {#find-all-requests-with-a-total-duration--5-seconds}

```shell
jq 'select(.duration_s > 5000)' <FILE>
```

#### Trouver toutes les requêtes de projet avec plus de 5 appels Gitaly {#find-all-project-requests-with-more-than-5-gitaly-calls}

```shell
grep <PROJECT_NAME> <FILE> | jq 'select(.gitaly_calls > 5)'
```

#### Trouver toutes les requêtes avec une durée Gitaly > 10 secondes {#find-all-requests-with-a-gitaly-duration--10-seconds}

```shell
jq 'select(.gitaly_duration_s > 10000)' <FILE>
```

#### Trouver toutes les requêtes avec une durée de file d'attente > 10 secondes {#find-all-requests-with-a-queue-duration--10-seconds}

```shell
jq 'select(.queue_duration_s > 10000)' <FILE>
```

#### Top 10 des requêtes par nombre d'appels Gitaly {#top-10-requests-by--of-gitaly-calls}

```shell
jq -s 'map(select(.gitaly_calls != null)) | sort_by(-.gitaly_calls) | limit(10; .[])' <FILE>
```

#### Afficher une plage temporelle spécifique {#output-a-specific-time-range}

```shell
jq 'select(.time >= "2023-01-10T00:00:00Z" and .time <= "2023-01-10T12:00:00Z")' <FILE>
```

### Analyse de `gitlab-rails/production_json.log` {#parsing-gitlab-railsproduction_jsonlog}

#### Afficher les trois principales méthodes de contrôleur par volume de requêtes et leurs trois durées les plus longues {#print-the-top-three-controller-methods-by-request-volume-and-their-three-longest-durations}

```shell
jq -s -r 'group_by(.controller+.action) | sort_by(-length) | limit(3; .[]) | sort_by(-.duration_s) | "CT: \(length)\tMETHOD: \(.[0].controller)#\(.[0].action)\tDURS: \(.[0].duration_s),  \(.[1].duration_s),  \(.[2].duration_s)"' production_json.log
```

**Exemple de sortie**

```plaintext
CT: 2721   METHOD: SessionsController#new  DURS: 844.06,  713.81,  704.66
CT: 2435   METHOD: MetricsController#index DURS: 299.29,  284.01,  158.57
CT: 1328   METHOD: Projects::NotesController#index DURS: 403.99,  386.29,  384.39
```

Vous pouvez également utiliser [`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats) :

```shell
fast-stats --verbose --limit=3 production_json.log
```

### Analyse de `gitlab-rails/api_json.log` {#parsing-gitlab-railsapi_jsonlog}

#### Afficher les trois principales routes avec le nombre de requêtes et leurs trois durées les plus longues {#print-top-three-routes-with-request-count-and-their-three-longest-durations}

```shell
jq -s -r 'group_by(.route) | sort_by(-length) | limit(3; .[]) | sort_by(-.duration_s) | "CT: \(length)\tROUTE: \(.[0].route)\tDURS: \(.[0].duration_s),  \(.[1].duration_s),  \(.[2].duration_s)"' api_json.log
```

**Exemple de sortie**

```plaintext
CT: 2472 ROUTE: /api/:version/internal/allowed   DURS: 56402.65,  38411.43,  19500.41
CT: 297  ROUTE: /api/:version/projects/:id/repository/tags       DURS: 731.39,  685.57,  480.86
CT: 190  ROUTE: /api/:version/projects/:id/repository/commits    DURS: 1079.02,  979.68,  958.21
```

Vous pouvez également utiliser [`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats) :

```shell
fast-stats --verbose --limit=3 api_json.log
```

#### Afficher les principaux user agents de l'API {#print-top-api-user-agents}

```shell
jq --raw-output '
  select(.remote_ip != "127.0.0.1") | [
    (.time | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("…%m-%dT%H…")),
    ."meta.caller_id", .username, .ua
  ] | @tsv' api_json.log | sort | uniq -c \
  | grep --invert-match --extended-regexp '^\s+\d{1,3}\b'
```

**Exemple de sortie** :

```plaintext
 1234 …01-12T01…  GET /api/:version/projects/:id/pipelines  some_user  # plus browser details; OK
54321 …01-12T01…  POST /api/:version/projects/:id/repository/files/:file_path/raw  some_bot
 5678 …01-12T01…  PATCH /api/:version/jobs/:id/trace gitlab-runner     # plus version details; OK
```

Cet exemple montre un outil ou un script personnalisé provoquant un [taux de requêtes (>15 RPS)](../reference_architectures/_index.md#available-reference-architectures) anormalement élevé. Les user agents dans cette situation peuvent être des [clients tiers](../../api/rest/third_party_clients.md) spécialisés, ou des outils généraux comme `curl`.

L'agrégation horaire permet de :

- Corréler les pics d'activité des bots ou des utilisateurs avec les données des outils de surveillance tels que [Prometheus](../monitoring/prometheus/_index.md).
- Évaluer les [paramètres de limite de débit](../settings/user_and_ip_rate_limits.md).

En complément de `jq`, utilisez [`fast-stats top`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats/-/blob/main/README.md#top) pour examiner l'impact sur les performances de ces utilisateurs et bots :

```shell
fast-stats top --display=percentage --sort-by=cpu-s api_json.log
```

Une fréquence de requêtes élevée n'est pas automatiquement un problème en soi, mais utiliser un pourcentage important d'une ressource quelconque l'est.

### Analyse de `gitlab-rails/importer.log` {#parsing-gitlab-railsimporterlog}

Pour résoudre les problèmes liés aux [imports de projets](../raketasks/project_import_export.md) ou aux [migrations](../../user/import/_index.md), exécutez cette commande :

```shell
jq 'select(.project_path == "<namespace>/<project>").error_messages' importer.log
```

Pour les problèmes courants, consultez la [résolution des problèmes](../raketasks/import_export_rake_tasks_troubleshooting.md).

### Analyse de `gitlab-workhorse/current` {#parsing-gitlab-workhorsecurrent}

#### Afficher les principaux user agents de Workhorse {#print-top-workhorse-user-agents}

```shell
jq --raw-output '
  select(.remote_ip != "127.0.0.1") | [
    (.time | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("…%m-%dT%H…")),
    .remote_ip, .uri, .user_agent
  ] | @tsv' current |
  sort | uniq -c
```

De même que dans l'[exemple `ua` de l'API](#print-top-api-user-agents), de nombreux user agents inattendus dans cette sortie indiquent des scripts non optimisés. Les user agents attendus incluent `gitlab-runner`, `GitLab-Shell` et les navigateurs.

L'impact sur les performances des runners vérifiant la présence de nouveaux jobs peut être réduit en augmentant [le paramètre `check_interval`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-global-section), par exemple.

### Analyse de `gitlab-rails/geo.log` {#parsing-gitlab-railsgeolog}

#### Trouver les erreurs de synchronisation Geo les plus courantes {#find-most-common-geo-sync-errors}

Si [la tâche Rake `gitlab:geo:status`](../geo/replication/troubleshooting/common.md#sync-status-rake-task) signale de manière répétée que certains éléments n'atteignent jamais 100 %, la commande suivante permet de se concentrer sur les erreurs les plus courantes.

```shell
jq --raw-output 'select(.severity == "ERROR") | [
  (.time | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("…%m-%dT%H:%M…")),
  .class, .id, .message, .error
  ] | @tsv' geo.log \
  | sort | uniq -c
```

Consultez notre [page de résolution des problèmes Geo](../geo/replication/troubleshooting/_index.md) pour obtenir des conseils sur les messages d'erreur spécifiques.

### Analyse de `gitaly/current` {#parsing-gitalycurrent}

Utilisez les exemples suivants pour [résoudre les problèmes de Gitaly](../gitaly/troubleshooting.md).

#### Trouver toutes les requêtes Gitaly envoyées depuis l'interface web {#find-all-gitaly-requests-sent-from-web-ui}

```shell
jq 'select(."grpc.meta.client_name" == "gitlab-web")' current
```

#### Trouver toutes les requêtes Gitaly échouées {#find-all-failed-gitaly-requests}

```shell
jq 'select(."grpc.code" != null and ."grpc.code" != "OK")' current
```

#### Trouver toutes les requêtes ayant duré plus de 30 secondes {#find-all-requests-that-took-longer-than-30-seconds}

```shell
jq 'select(."grpc.time_ms" > 30000)' current
```

#### Afficher les dix premiers projets par volume de requêtes et leurs trois durées les plus longues {#print-top-ten-projects-by-request-volume-and-their-three-longest-durations}

```shell
jq --raw-output --slurp '
  map(
    select(
      ."grpc.request.glProjectPath" != null
      and ."grpc.request.glProjectPath" != ""
      and ."grpc.time_ms" != null
    )
  )
  | group_by(."grpc.request.glProjectPath")
  | sort_by(-length)
  | limit(10; .[])
  | sort_by(-."grpc.time_ms")
  | [
      length,
      .[0]."grpc.time_ms",
      .[1]."grpc.time_ms",
      .[2]."grpc.time_ms",
      .[0]."grpc.request.glProjectPath"
    ]
  | @sh' current |
  awk 'BEGIN { printf "%7s %10s %10s %10s\t%s\n", "CT", "MAX DURS", "", "", "PROJECT" }
  { printf "%7u %7u ms, %7u ms, %7u ms\t%s\n", $1, $2, $3, $4, $5 }'
```

**Exemple de sortie**

```plaintext
   CT    MAX DURS                              PROJECT
  206    4898 ms,    1101 ms,    1032 ms      'groupD/project4'
  109    1420 ms,     962 ms,     875 ms      'groupEF/project56'
  663     106 ms,      96 ms,      94 ms      'groupABC/project123'
  ...
```

Vous pouvez également utiliser [`fast-stats`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats) :

```shell
fast-stats top --sort-by=duration current
```

#### Vue d'ensemble des types d'activité des utilisateurs et des projets {#types-of-user-and-project-activity-overview}

```shell
jq --raw-output '[
    (.time | split(".")[0] | strptime("%Y-%m-%dT%H:%M:%S") | strftime("…%m-%dT%H…")),
    .username, ."grpc.method", ."grpc.request.glProjectPath"
  ] | @tsv' current | sort | uniq -c \
  | grep --invert-match --extended-regexp '^\s+\d{1,3}\b'
```

**Exemple de sortie** :

```plaintext
 5678 …01-12T01…     ReferenceTransactionHook  # Praefect operation; OK
54321 …01-12T01…  some_bot   GetBlobs    namespace/subgroup/project
 1234 …01-12T01…  some_user  FindCommit  namespace/subgroup/project
```

Cet exemple montre un outil ou un script personnalisé provoquant un [taux de requêtes (>15 RPS)](../reference_architectures/_index.md#available-reference-architectures) anormalement élevé sur Gitaly. L'agrégation horaire permet de :

- Corréler les pics d'activité des bots ou des utilisateurs avec les données des outils de surveillance tels que [Prometheus](../monitoring/prometheus/_index.md).
- Évaluer les [paramètres de limite de débit](../settings/user_and_ip_rate_limits.md).

En complément de `jq`, utilisez [`fast-stats top`](https://gitlab.com/gitlab-com/support/toolbox/fast-stats/-/blob/main/README.md#top) pour examiner l'impact sur les performances de ces utilisateurs et bots :

```shell
fast-stats top --display=percentage --sort-by=cpu-s current
```

Une fréquence de requêtes élevée n'est pas automatiquement un problème en soi, mais utiliser un pourcentage important d'une ressource quelconque l'est.

#### Trouver tous les projets affectés par un problème Git fatal {#find-all-projects-affected-by-a-fatal-git-problem}

```shell
grep "fatal: " current |
  jq '."grpc.request.glProjectPath"' |
  sort | uniq
```

### Analyse de `gitlab-shell/gitlab-shell.log` {#parsing-gitlab-shellgitlab-shelllog}

Pour examiner les appels Git via SSH.

Trouver les 20 principaux appels par projet et utilisateur :

```shell
jq --raw-output --slurp '
  map(
    select(
      .username != null and
      .gl_project_path !=null
    )
  )
  | group_by(.username+.gl_project_path)
  | sort_by(-length)
  | limit(20; .[])
  | "count: \(length)\tuser: \(.[0].username)\tproject: \(.[0].gl_project_path)" ' \
  gitlab-shell.log
```

Trouver les 20 principaux appels par projet, utilisateur et commande :

```shell
jq --raw-output --slurp '
  map(
    select(
      .command  != null and
      .username != null and
      .gl_project_path !=null
    )
  )
  | group_by(.username+.gl_project_path+.command)
  | sort_by(-length)
  | limit(20; .[])
  | "count: \(length)\tcommand: \(.[0].command)\tuser: \(.[0].username)\tproject: \(.[0].gl_project_path)" ' \
  gitlab-shell.log
```
