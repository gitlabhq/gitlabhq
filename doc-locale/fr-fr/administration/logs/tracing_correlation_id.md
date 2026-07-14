---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Trouver les entrées de journal pertinentes avec un ID de corrélation
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les instances GitLab enregistrent un ID de suivi de requête unique (connu sous le nom d'« ID de corrélation ») pour la plupart des requêtes. Chaque requête individuelle adressée à GitLab obtient son propre ID de corrélation, qui est ensuite enregistré dans les journaux de chaque composant GitLab pour cette requête. Cela facilite le traçage du comportement dans un système distribué. Sans cet ID, il peut être difficile, voire impossible, de faire correspondre les entrées de journal corrélées.

## Identifier l'ID de corrélation pour une requête {#identify-the-correlation-id-for-a-request}

L'ID de corrélation est enregistré dans les journaux structurés sous la clé `correlation_id` et dans tous les en-têtes de réponse que GitLab envoie sous l'en-tête `x-request-id`. Vous pouvez trouver votre ID de corrélation en effectuant une recherche dans l'un ou l'autre de ces emplacements.

### Obtenir l'ID de corrélation dans votre navigateur {#getting-the-correlation-id-in-your-browser}

Vous pouvez utiliser les outils de développement de votre navigateur pour surveiller et inspecter l'activité réseau avec le site que vous visitez. Consultez les liens ci-dessous pour accéder à la documentation de surveillance réseau de certains navigateurs populaires.

- [Network Monitor - Firefox Developer Tools](https://firefox-source-docs.mozilla.org/devtools-user/network_monitor/index.html)
- [Inspect Network Activity In Chrome DevTools](https://developer.chrome.com/docs/devtools/network/)
- [Safari Web Development Tools](https://developer.apple.com/safari/tools/)
- [Microsoft Edge Network panel](https://learn.microsoft.com/en-us/microsoft-edge/devtools-guide-chromium/network/)

Pour localiser une requête pertinente et afficher son ID de corrélation :

1. Activez la journalisation persistante dans votre moniteur réseau. Certaines actions dans GitLab vous redirigent rapidement après l'envoi d'un formulaire, ce qui permet de capturer toute l'activité pertinente.
1. Pour vous aider à isoler les requêtes que vous recherchez, vous pouvez filtrer par requêtes `document`.
1. Sélectionnez la requête qui vous intéresse pour afficher plus de détails.
1. Accédez à la section **En-têtes** et recherchez **En-têtes de réponse**. Vous devriez y trouver un en-tête `x-request-id` avec une valeur générée aléatoirement par GitLab pour la requête.

Voir l'exemple suivant :

![Exemple d'ID de corrélation dans la section En-têtes des détails d'une requête réseau pour un document HTML](img/network_monitor_xid_v13_6.png)

### Obtenir l'ID de corrélation à partir de vos journaux {#getting-the-correlation-id-from-your-logs}

Une autre approche pour trouver l'ID de corrélation correct consiste à rechercher ou surveiller vos journaux et à trouver la valeur `correlation_id` pour l'entrée de journal que vous recherchez.

Par exemple, si vous souhaitez comprendre ce qui se passe ou ce qui se bloque lorsque vous reproduisez une action dans GitLab, vous pouvez surveiller les journaux GitLab en temps réel, en filtrant les requêtes par votre utilisateur, puis observer les requêtes jusqu'à ce que vous voyiez ce qui vous intéresse.

### Obtenir l'ID de corrélation à partir de curl {#getting-the-correlation-id-from-curl}

Si vous utilisez `curl`, vous pouvez utiliser l'option verbose pour afficher les en-têtes de requête et de réponse, ainsi que d'autres informations de débogage.

```shell
➜  ~ curl --verbose "https://gitlab.example.com/api/v4/projects"
# look for a line that looks like this
< x-request-id: 4rAMkV3gof4
```

#### Utiliser jq {#using-jq}

Cet exemple utilise [jq](https://stedolan.github.io/jq/) pour filtrer les résultats et afficher les valeurs qui nous intéressent le plus.

```shell
sudo gitlab-ctl tail gitlab-rails/production_json.log | jq 'select(.username == "bob") | "User: \(.username), \(.method) \(.path), \(.controller)#\(.action), ID: \(.correlation_id)"'
```

```plaintext
"User: bob, GET /root/linux, ProjectsController#show, ID: U7k7fh6NpW3"
"User: bob, GET /root/linux/commits/master/signatures, Projects::CommitsController#signatures, ID: XPIHpctzEg1"
"User: bob, GET /root/linux/blob/master/README, Projects::BlobController#show, ID: LOt9hgi1TV4"
```

#### Utiliser grep {#using-grep}

Cet exemple utilise uniquement `grep` et `tr`, qui sont plus susceptibles d'être installés que `jq`.

```shell
sudo gitlab-ctl tail gitlab-rails/production_json.log | grep '"username":"bob"' | tr ',' '\n' | egrep 'method|path|correlation_id'
```

```plaintext
{"method":"GET"
"path":"/root/linux"
"username":"bob"
"correlation_id":"U7k7fh6NpW3"}
{"method":"GET"
"path":"/root/linux/commits/master/signatures"
"username":"bob"
"correlation_id":"XPIHpctzEg1"}
{"method":"GET"
"path":"/root/linux/blob/master/README"
"username":"bob"
"correlation_id":"LOt9hgi1TV4"}
```

## Rechercher l'ID de corrélation dans vos journaux {#searching-your-logs-for-the-correlation-id}

Lorsque vous disposez de l'ID de corrélation, vous pouvez commencer à rechercher les entrées de journal pertinentes. Vous pouvez filtrer les lignes par l'ID de corrélation lui-même. La combinaison de `find` et de `grep` devrait être suffisante pour trouver les entrées que vous recherchez.

```shell
# find <gitlab log directory> -type f -mtime -0 exec grep '<correlation ID>' '{}' '+'
find /var/log/gitlab -type f -mtime 0 -exec grep 'LOt9hgi1TV4' '{}' '+'
```

```plaintext
/var/log/gitlab/gitlab-workhorse/current:{"correlation_id":"LOt9hgi1TV4","duration_ms":2478,"host":"gitlab.domain.tld","level":"info","method":"GET","msg":"access","proto":"HTTP/1.1","referrer":"https://gitlab.domain.tld/root/linux","remote_addr":"68.0.116.160:0","remote_ip":"[filtered]","status":200,"system":"http","time":"2019-09-17T22:17:19Z","uri":"/root/linux/blob/master/README?format=json\u0026viewer=rich","user_agent":"Mozilla/5.0 (Mac) Gecko Firefox/69.0","written_bytes":1743}
/var/log/gitlab/gitaly/current:{"correlation_id":"LOt9hgi1TV4","grpc.code":"OK","grpc.meta.auth_version":"v2","grpc.meta.client_name":"gitlab-web","grpc.method":"FindCommits","grpc.request.deadline":"2019-09-17T22:17:47Z","grpc.request.fullMethod":"/gitaly.CommitService/FindCommits","grpc.request.glProjectPath":"root/linux","grpc.request.glRepository":"project-1","grpc.request.repoPath":"@hashed/6b/86/6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b.git","grpc.request.repoStorage":"default","grpc.request.topLevelGroup":"@hashed","grpc.service":"gitaly.CommitService","grpc.start_time":"2019-09-17T22:17:17Z","grpc.time_ms":2319.161,"level":"info","msg":"finished streaming call with code OK","peer.address":"@","span.kind":"server","system":"grpc","time":"2019-09-17T22:17:19Z"}
/var/log/gitlab/gitlab-rails/production_json.log:{"method":"GET","path":"/root/linux/blob/master/README","format":"json","controller":"Projects::BlobController","action":"show","status":200,"duration":2448.77,"view":0.49,"db":21.63,"time":"2019-09-17T22:17:19.800Z","params":[{"key":"viewer","value":"rich"},{"key":"namespace_id","value":"root"},{"key":"project_id","value":"linux"},{"key":"id","value":"master/README"}],"remote_ip":"[filtered]","user_id":2,"username":"bob","ua":"Mozilla/5.0 (Mac) Gecko Firefox/69.0","queue_duration":3.38,"gitaly_calls":1,"gitaly_duration":0.77,"rugged_calls":4,"rugged_duration_ms":28.74,"correlation_id":"LOt9hgi1TV4"}
```

### Recherche dans les architectures distribuées {#searching-in-distributed-architectures}

Si vous avez effectué une mise à l'échelle horizontale de votre infrastructure GitLab, vous devez effectuer une recherche sur tous vos nœuds GitLab. Vous pouvez le faire avec un logiciel d'agrégation de journaux tel que Loki, ELK, Splunk, ou d'autres.

Vous pouvez utiliser un outil comme Ansible ou PSSH (parallel SSH) qui peut exécuter des commandes identiques sur vos serveurs en parallèle, ou concevoir votre propre solution.

### Affichage de la requête dans la barre de performance {#viewing-the-request-in-the-performance-bar}

Vous pouvez utiliser la [barre de performance](../monitoring/performance/performance_bar.md) pour afficher des données intéressantes, notamment les appels effectués vers SQL et Gitaly.

Pour afficher les données, l'ID de corrélation de la requête doit correspondre à la même session que celle de l'utilisateur qui consulte la barre de performance. Pour les requêtes API, cela signifie que vous devez effectuer la requête en utilisant le cookie de session de l'utilisateur authentifié.

Par exemple, si vous souhaitez afficher les requêtes de base de données exécutées pour le point de terminaison API suivant :

```shell
https://gitlab.com/api/v4/groups/2564205/projects?with_security_reports=true&page=1&per_page=1
```

Tout d'abord, activez le panneau **Outils de développement**. Consultez [Obtenir l'ID de corrélation dans votre navigateur](#getting-the-correlation-id-in-your-browser) pour plus de détails sur la façon de procéder.

Une fois les outils de développement activés, obtenez un cookie de session comme suit :

1. Visitez <https://gitlab.com> en étant connecté.
1. Facultatif. Sélectionnez le filtre de requêtes **Fetch/XHR** dans le panneau **Outils de développement**. Cette étape est décrite pour les outils de développement Google Chrome et n'est pas strictement nécessaire ; elle facilite simplement la recherche de la bonne requête.
1. Sélectionnez la requête `results?request_id=<some-request-id>` sur le côté gauche.
1. Le cookie de session s'affiche dans la section `Request Headers` du panneau `Headers`. Faites un clic droit sur la valeur du cookie et sélectionnez `Copy value`.

![Affichage d'un cookie de session dans le panneau Outils de développement d'un navigateur](img/obtaining-a-session-cookie-for-request_v14_3.png)

Vous avez la valeur du cookie de session copiée dans votre presse-papiers, par exemple :

```shell
experimentation_subject_id=<subject-id>; _gitlab_session=<session-id>; event_filter=all; visitor_id=<visitor-id>; perf_bar_enabled=true; sidebar_collapsed=true; diff_view=inline; sast_entry_point_dismissed=true; auto_devops_settings_dismissed=true; cf_clearance=<cf-clearance>; collapsed_gutter=false
```

Utilisez la valeur du cookie de session pour formuler une requête API en la collant dans un en-tête personnalisé d'une requête `curl` :

```shell
$ curl --include "https://gitlab.com/api/v4/groups/2564205/projects?with_security_reports=true&page=1&per_page=1" \
--header 'cookie: experimentation_subject_id=<subject-id>; _gitlab_session=<session-id>; event_filter=all; visitor_id=<visitor-id>; perf_bar_enabled=true; sidebar_collapsed=true; diff_view=inline; sast_entry_point_dismissed=true; auto_devops_settings_dismissed=true; cf_clearance=<cf-clearance>; collapsed_gutter=false'

  date: Tue, 28 Sep 2021 03:55:33 GMT
  content-type: application/json
  ...
  x-request-id: 01FGN8P881GF2E5J91JYA338Y3
  ...
  [
    {
      "id":27497069,
      "description":"Analyzer for images used on live K8S containers based on Starboard"
    },
    "container_registry_image_prefix":"registry.gitlab.com/gitlab-org/security-products/analyzers/cluster-image-scanning",
    "..."
  ]
```

La réponse contient les données du point de terminaison API, ainsi qu'une valeur `correlation_id`, renvoyée dans l'en-tête `x-request-id`, comme décrit dans la section [Identifier l'ID de corrélation pour une requête](#identify-the-correlation-id-for-a-request).

Vous pouvez ensuite afficher les détails de la base de données pour cette requête :

1. Collez la valeur `x-request-id` dans le champ `request details` de la [barre de performance](../monitoring/performance/performance_bar.md) et appuyez sur <kbd>Enter/Return</kbd>. Cet exemple utilise la valeur `x-request-id` `01FGN8P881GF2E5J91JYA338Y3`, renvoyée par la réponse précédente :

   ![Le champ de détails de requête de la barre de performance contenant un exemple de valeur](img/paste-request-id-into-progress-bar_v14_3.png)

1. Une nouvelle requête est insérée dans la liste déroulante `Request Selector` sur le côté droit de la barre de performance. Sélectionnez la nouvelle requête pour afficher les métriques de la requête API :

   ![Un exemple de requête mis en évidence dans une liste déroulante Sélecteur de requêtes ouverte](img/select-request-id-from-request-selector-drop-down-menu_v14_3.png)

1. Sélectionnez le lien `pg` dans la barre de progression pour afficher les requêtes de base de données exécutées par la requête API :

   ![Détails de la base de données de l'API GitLab : 29 ms / 34 requêtes](img/view-pg-details_v14_3.png)

   La boîte de dialogue des requêtes de base de données s'affiche :

   ![Boîte de dialogue des requêtes de base de données avec 34 requêtes SQL, une durée de 29 ms, 34 réplicas, 4 en cache et des options de tri](img/database-query-dialog_v14_3.png)
