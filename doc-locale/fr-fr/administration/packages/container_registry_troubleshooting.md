---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage du registre de conteneurs
description: Résolvez les problèmes courants liés à votre registre de conteneurs GitLab.
---

Avant d'examiner des problèmes spécifiques, essayez ces étapes de dépannage :

1. Vérifiez que l'horloge système de votre client Docker et de votre serveur GitLab sont synchronisées (par exemple, via NTP).
1. Pour les registres basés sur S3, vérifiez que vos autorisations IAM et vos identifiants S3 (y compris la région) sont corrects. Pour plus d'informations, consultez la [politique IAM exemple](https://distribution.github.io/distribution/storage-drivers/s3/).
1. Vérifiez les erreurs dans les journaux du registre (par exemple, `/var/log/gitlab/registry/current`) et les journaux de production GitLab (par exemple, `/var/log/gitlab/gitlab-rails/production.log`).
1. Vérifiez le fichier de configuration NGINX pour le registre de conteneurs (par exemple, `/var/opt/gitlab/nginx/conf/gitlab-registry.conf`) pour confirmer quel port reçoit les requêtes.
1. Vérifiez que les requêtes sont correctement transmises au registre de conteneurs :

   ```shell
   curl --verbose --noproxy "*" https://<hostname>:<port>/v2/_catalog
   ```

   La réponse doit inclure une ligne avec `Www-Authenticate: Bearer` contenant `service="container_registry"`. Par exemple :

   ```plaintext
   < HTTP/1.1 401 Unauthorized
   < Server: nginx
   < Date: Fri, 07 Mar 2025 08:24:43 GMT
   < Content-Type: application/json
   < Content-Length: 162
   < Connection: keep-alive
   < Docker-Distribution-Api-Version: registry/2.0
   < Www-Authenticate: Bearer realm="https://<hostname>/jwt/auth",service="container_registry",scope="registry:catalog:*"
   < X-Content-Type-Options: nosniff
   <
   {"errors":[{"code":"UNAUTHORIZED","message":"authentication required","detail":
   [{"Type":"registry","Class":"","Name":"catalog","ProjectPath":"","Action":"*"}]}]}
   * Connection #0 to host <hostname> left intact
   ```

## Erreur : `... x509: certificate signed by unknown authority` {#error--x509-certificate-signed-by-unknown-authority}

Lors de l'utilisation d'un certificat auto-signé avec le registre de conteneurs, vous pourriez rencontrer une erreur similaire dans vos jobs de pipeline CI/CD :

```plaintext
Error response from daemon: Get registry.example.com/v1/users/: x509: certificate signed by unknown authority
```

Cette erreur se produit car le démon Docker exécutant la commande attend un certificat signé par une autorité de certification reconnue, et non un certificat auto-signé.

Pour résoudre cette erreur, configurez Docker pour approuver les certificats auto-signés. Pour obtenir de l'aide sur la configuration de Docker, consultez [Configurer les certificats auto-signés](container_registry.md#configure-self-signed-certificates).

Pour des informations supplémentaires, consultez le [ticket 18239](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/18239).

## La tentative de connexion Docker échoue avec : 'token signed by untrusted key' {#docker-login-attempt-fails-with-token-signed-by-untrusted-key}

[Le registre s'appuie sur GitLab pour valider les identifiants](container_registry.md#container-registry-architecture) Si le registre ne parvient pas à authentifier des tentatives de connexion valides, vous obtenez le message d'erreur suivant :

```shell
# docker login gitlab.company.com:4567
Username: user
Password:
Error response from daemon: login attempt to https://gitlab.company.com:4567/v2/ failed with status: 401 Unauthorized
```

Et plus précisément, cela apparaît dans le fichier journal `/var/log/gitlab/registry/current` :

```plaintext
level=info
msg="token signed by untrusted key with ID: "TOKE:NL6Q:7PW6:EXAM:PLET:OKEN:BG27:RCIB:D2S3:EXAM:PLET:OKEN""
level=warning msg="error authorizing context: invalid token" go.version=go1.12.7 http.request.host="gitlab.company.com:4567"
http.request.id=74613829-2655-4f96-8991-1c9fe33869b8 http.request.method=GET http.request.remoteaddr=10.72.11.20
http.request.uri="/v2/" http.request.useragent="docker/19.03.2 go/go1.12.8 git-commit/6a30dfc
kernel/3.10.0-693.2.2.el7.x86_64 os/linux arch/amd64 UpstreamClient(Docker-Client/19.03.2 \(linux\))"
```

(Sauts de ligne ajoutés pour la lisibilité.)

GitLab utilise le contenu des deux parties de la paire de clés du certificat pour chiffrer le jeton d'authentification du registre. Ce message signifie que ces contenus ne correspondent pas.

Vérifiez quels fichiers sont utilisés :

- `grep -A6 'auth:' /var/opt/gitlab/registry/config.yml`

  ```yaml
  ## Container registry certificate
     auth:
       token:
         realm: https://gitlab.my.net/jwt/auth
         service: container_registry
         issuer: omnibus-gitlab-issuer
    -->  rootcertbundle: /var/opt/gitlab/registry/gitlab-registry.crt
         autoredirect: false
  ```

- `grep -A9 'Container Registry' /var/opt/gitlab/gitlab-rails/etc/gitlab.yml`

  ```yaml
  ## Container registry key
     registry:
       enabled: true
       host: gitlab.company.com
       port: 4567
       api_url: http://127.0.0.1:5000 # internal address to the registry, is used by GitLab to directly communicate with API
       path: /var/opt/gitlab/gitlab-rails/shared/registry
  -->  key: /var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key
       issuer: omnibus-gitlab-issuer
       notification_secret:
  ```

La sortie de ces commandes `openssl` doit correspondre, prouvant que la paire cert-clé est valide :

```shell
/opt/gitlab/embedded/bin/openssl x509 -noout -modulus -in /var/opt/gitlab/registry/gitlab-registry.crt | /opt/gitlab/embedded/bin/openssl sha256
/opt/gitlab/embedded/bin/openssl rsa -noout -modulus -in /var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key | /opt/gitlab/embedded/bin/openssl sha256
```

Si les deux parties du certificat ne correspondent pas, supprimez les fichiers et exécutez `gitlab-ctl reconfigure` pour régénérer la paire. La paire est recréée en utilisant les valeurs existantes dans `/etc/gitlab/gitlab-secrets.json` si elles existent. Pour générer une nouvelle paire, supprimez la section `registry` dans votre `/etc/gitlab/gitlab-secrets.json` avant d'exécuter `gitlab-ctl reconfigure`.

Si vous avez remplacé la paire auto-signée générée automatiquement par vos propres certificats et vous êtes assuré que leurs contenus correspondent, vous pouvez supprimer la section 'registry' dans votre `/etc/gitlab/gitlab-secrets.json` et exécuter `gitlab-ctl reconfigure`.

## Erreur du registre GitLab avec AWS S3 lors de l'envoi de grandes images {#aws-s3-with-the-gitlab-registry-error-when-pushing-large-images}

Lors de l'utilisation d'AWS S3 avec le registre GitLab, une erreur peut se produire lors de l'envoi de grandes images. Recherchez l'erreur suivante dans le journal du registre :

```plaintext
level=error msg="response completed with error" err.code=unknown err.detail="unexpected EOF" err.message="unknown error"
```

Pour résoudre l'erreur, spécifiez une valeur `chunksize` dans la configuration du registre. Commencez avec une valeur comprise entre `25000000` (25 Mo) et `50000000` (50 Mo).

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   registry['storage'] = {
     's3' => {
       'accesskey' => 'AKIAKIAKI',
       'secretkey' => 'secret123',
       'bucket'    => 'gitlab-registry-bucket-AKIAKIAKI',
       'chunksize' => 25000000
     }
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez `config/gitlab.yml` :

   ```yaml
   storage:
     s3:
       accesskey: 'AKIAKIAKI'
       secretkey: 'secret123'
       bucket: 'gitlab-registry-bucket-AKIAKIAKI'
       chunksize: 25000000
   ```

1. Enregistrez le fichier et [redémarrez GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

## Prise en charge des anciens clients Docker {#supporting-older-docker-clients}

Le registre de conteneurs Docker fourni avec GitLab désactive le manifeste schema1 par défaut. Si vous utilisez encore d'anciens clients Docker (1.9 ou antérieur), vous pourriez rencontrer une erreur lors de l'envoi d'images. Consultez le [ticket 4145](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4145) pour plus de détails.

Vous pouvez ajouter une option de configuration pour la compatibilité ascendante.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   registry['compatibility_schema1_enabled'] = true
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez le fichier de configuration YAML que vous avez créé lors du déploiement du registre. Ajoutez l'extrait suivant :

   ```yaml
   compatibility:
       schema1:
           enabled: true
   ```

1. Redémarrez le registre pour que les modifications prennent effet.

{{< /tab >}}

{{< /tabs >}}

## Erreur de connexion Docker {#docker-connection-error}

Une erreur de connexion Docker peut se produire lorsqu'il y a des caractères spéciaux dans le nom du groupe, du projet ou de la branche. Les caractères spéciaux peuvent inclure :

- Tiret bas initial
- Trait d'union/tiret final
- Double trait d'union/tiret

Pour contourner ce problème, vous pouvez [modifier le chemin du groupe](../../user/group/manage.md#change-a-groups-path), [modifier le chemin du projet](../../user/project/working_with_projects.md#rename-a-repository) ou modifier le nom de la branche. Une autre option consiste à créer une [règle de push](../../user/project/repository/push_rules.md) pour éviter cette erreur sur toute l'instance.

## Erreurs d'envoi d'images {#image-push-errors}

Vous pourriez être bloqué dans des boucles de nouvelle tentative lors de l'envoi d'images Docker, même si `docker login` réussit.

Ce problème se produit lorsque NGINX ne transmet pas correctement les en-têtes au registre, généralement dans des configurations personnalisées où le SSL est déchargé vers un proxy inverse tiers.

Pour plus d'informations, consultez [Docker push through NGINX proxy fails trying to send a 32B layer #970](https://github.com/docker/distribution/issues/970).

Pour résoudre ce problème, mettez à jour votre configuration NGINX pour activer les URL relatives dans le registre :

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   registry['env'] = {
     "REGISTRY_HTTP_RELATIVEURLS" => true
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Modifiez le fichier de configuration YAML que vous avez créé lors du déploiement du registre. Ajoutez l'extrait suivant :

   ```yaml
   http:
       relativeurls: true
   ```

1. Enregistrez le fichier et [redémarrez GitLab](../restart_gitlab.md#self-compiled-installations) pour que les modifications prennent effet.

{{< /tab >}}

{{< tab title="Docker Compose" >}}

1. Modifiez votre fichier `docker-compose.yaml` :

   ```yaml
   GITLAB_OMNIBUS_CONFIG: |
     registry['env'] = {
       "REGISTRY_HTTP_RELATIVEURLS" => true
     }
   ```

1. Si le problème persiste, assurez-vous que les deux URL utilisent HTTPS :

   ```yaml
   GITLAB_OMNIBUS_CONFIG: |
     external_url 'https://git.example.com'
     registry_external_url 'https://git.example.com:5050'
   ```

1. Enregistrez le fichier et redémarrez le conteneur :

   ```shell
   sudo docker restart gitlab
   ```

{{< /tab >}}

{{< /tabs >}}

## Activer le serveur de débogage du registre {#enable-the-registry-debug-server}

Vous pouvez utiliser le serveur de débogage du registre de conteneurs pour diagnostiquer les problèmes. L'endpoint de débogage peut surveiller les métriques et l'état de santé, ainsi qu'effectuer du profilage.

> [!warning]
> Des informations sensibles peuvent être disponibles via l'endpoint de débogage. L'accès à l'endpoint de débogage doit être restreint dans un environnement de production.

Le serveur de débogage optionnel peut être activé en définissant l'adresse de débogage du registre dans votre configuration `gitlab.rb`.

```ruby
registry['debug_addr'] = "localhost:5001"
```

Après avoir ajouté le paramètre, [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour appliquer la modification.

Utilisez curl pour demander la sortie de débogage au serveur de débogage :

```shell
curl "localhost:5001/debug/health"
curl "localhost:5001/debug/vars"
```

### Métriques Prometheus {#prometheus-metrics}

Prometheus fournit des métriques que vous pouvez utiliser pour surveiller et résoudre les problèmes de performance de votre registre de conteneurs.

Les sections suivantes :

- Vous montrent comment activer les métriques Prometheus
- Répertorient toutes les métriques Prometheus exportées par le registre de conteneurs, organisées par composant

#### Activer les métriques Prometheus {#enable-prometheus-metrics}

Prérequis :

- Vous devez [activer le serveur de débogage du registre](#enable-the-registry-debug-server).

Pour activer les métriques Prometheus, ajoutez la configuration suivante dans `gitlab.rb` :

```ruby
# Enable Prometheus metrics
registry['debug'] = {
  'prometheus' => {
    'enabled' => true,
    'path' => '/metrics'
  }
}
```

Pour appliquer la modification, [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

Utilisez curl pour demander des métriques au serveur de débogage :

```shell
curl "localhost:5001/metrics"
```

#### Métriques de notifications {#notifications-metrics}

#### Compteurs {#counters}

| Nom de la métrique | Description | Labels | Valeurs de label |
|-------------|-------------|--------|--------------|
| `registry_notifications_events_total` | Le nombre total d'événements. | `type`, `action`, `artifact`, `endpoint` | `type` : `Successes`, `Failures`, `Events`, `Dropped` |
| `registry_notifications_status_total` | Le nombre de réponses HTTP par code de statut reçues de l'endpoint de notifications. | `code`, `endpoint` | `code` :  Codes de statut HTTP (par exemple, `200 OK` ou `404 Not Found`) |
| `registry_notifications_errors_total` | Le nombre d'événements qui ont généré une erreur lors de l'envoi. L'envoi des requêtes peut faire l'objet de nouvelles tentatives. | `endpoint` | chaîne : `'...'` |
| `registry_notifications_delivery_total` | Le nombre d'événements livrés ou perdus. Un événement est perdu une fois que le nombre de tentatives est épuisé. | `endpoint`, `delivery_type` | `delivery_type` : `delivered`, `lost` |

#### Jauges {#gauges}

| Nom de la métrique | Description | Labels | Valeurs de label |
|-------------|-------------|--------|--------------|
| `registry_notifications_pending` | La jauge des événements en attente dans la file d'attente, représentée par la longueur de la file. | `endpoint` | chaîne : `'...'` |

#### Histogrammes {#histograms}

| Nom de la métrique | Description | Labels | Compartiments |
|-------------|-------------|--------|---------|
| `registry_notifications_retries_count` | L'histogramme des tentatives de livraison cumulatives. | `endpoint` | `[0, 1, 2, 3, 5, 10, 15, 20, 30, 50]` |
| `registry_notifications_http_latency_seconds` | L'histogramme de latence de livraison HTTP. | `endpoint` | `[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 25, 50, 100]` (secondes) |
| `registry_notifications_total_latency_seconds` | L'histogramme de latence totale de livraison. | `endpoint` | `[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 25, 50, 100]` (secondes) |

#### Métriques de migration en arrière-plan par lots (BBM) {#batched-background-migration-bbm-metrics}

##### Compteurs {#counters-1}

| Nom de la métrique | Description | Labels | Valeurs de label |
|-------------|-------------|--------|--------------|
| `registry_bbm_runs_total` | Un compteur pour les exécutions du worker de migration par lots. | Aucune | Aucune |
| `registry_bbm_migrated_tuples_total` | Un compteur pour le total des enregistrements migrés par la migration par lots. | `migration_name`, `migration_id` | chaîne : `'...'` |

##### Jauges {#gauges-1}

| Nom de la métrique | Description | Labels | Valeurs de label |
|-------------|-------------|--------|--------------|
| `registry_bbm_job_batch_size` | Une jauge pour la taille de lot d'un job de migration par lots. | `migration_name`, `migration_id` | chaîne : `'...'` |
| `registry_database_bbm_progress_percent` | Pourcentage d'avancement de la migration en arrière-plan (0-100). | `migration_id`, `migration_name`, `status` | chaîne : `'...'` |

##### Histogrammes {#histograms-1}

| Nom de la métrique | Description | Labels | Compartiments |
|-------------|-------------|--------|---------|
| `registry_bbm_run_duration_seconds` | Un histogramme de latences pour les exécutions du worker de migration par lots. | Aucune | `[0.5, 1, 2, 5, 10, 15, 30, 60, 120, 300, 600, 900, 1800, 3600]` (0,5s à 1h) |
| `registry_bbm_job_duration_seconds` | Un histogramme de latences pour un job de migration par lots. | `migration_name`, `migration_id` | `[0.5, 1, 2, 5, 10, 15, 30, 60, 120, 300, 600, 900, 1800, 3600]` (0,5s à 1h) |
| `registry_bbm_query_duration_seconds` | Un histogramme de latences pour les requêtes de base de données de migration par lots. | `migration_name`, `migration_id` | `[0.5, 1, 2, 5, 10, 15, 30, 60, 120, 300, 600, 900, 1800, 3600]` (0,5s à 1h) |
| `registry_bbm_sleep_duration_seconds` | Un histogramme des durées de veille entre les exécutions du worker BBM. | `worker` | `[0.5, 1, 5, 15, 30, 60, 300, 600, 900, 1800, 3600, 7200, 10800, 21600, 43200, 86400]` (500ms à 24h) |

#### Métriques de base de données {#database-metrics}

##### Compteurs {#counters-2}

| Nom de la métrique | Description | Labels | Valeurs de label |
|-------------|-------------|--------|--------------|
| `registry_database_queries_total` | Un compteur pour les requêtes de base de données. | `name` | chaîne : `'...'` |
| `registry_database_lb_lsn_cache_hits_total` | Un compteur pour les accès au cache LSN de l'équilibrage de charge de la base de données (hits et misses). | `result` | `result` : `hit`, `miss` |
| `registry_database_lb_pool_events_total` | Un compteur des réplicas ajoutés ou supprimés du pool d'équilibrage de charge de la base de données. | `event`, `reason` | `event` : `replica_added`, `replica_removed`, `replica_quarantined`, `replica_reintegrated`<br>`reason` : `replication_lag`, `connectivity`, `removed_from_dns`, `discovered` |
| `registry_database_lb_targets_total` | Un compteur pour les élections de cibles principale et réplica lors de l'équilibrage de charge de la base de données. | `target_type`, `fallback`, `reason` | `target_type` : `primary`, `replica`<br>`fallback` : `true`, `false`<br>`reason` : `selected`, `no_cache`, `no_replica`, `error`, `not_up_to_date`, `all_quarantined` |

##### Jauges {#gauges-2}

| Nom de la métrique | Description | Labels | Valeurs de label |
|-------------|-------------|--------|--------------|
| `registry_database_lb_pool_size` | Une jauge pour le nombre actuel de réplicas dans le pool d'équilibrage de charge. | Aucune | Aucune |
| `registry_database_lb_pool_status` | Une jauge pour le statut actuel de chaque réplica dans le pool d'équilibrage de charge. | `replica`, `status` | `status` : `online`, `quarantined` |
| `registry_database_lb_lag_bytes` | Une jauge pour le décalage de réplication en octets pour chaque réplica. | `replica` | chaîne : `'...'` |
| `registry_database_migrations_total` | Une jauge pour le nombre total de migrations de base de données (appliquées + en attente) | `migration_type` | `migration_type` : `pre_deployment`, `post_deployment` |
| `registry_database_rows` | Une jauge pour le nombre de lignes dans les tables de base de données définies par le label `query_name`. | `query_name` | `query_name` : `gc_blob_review_queue`, `gc_manifest_review_queue`, `gc_blob_review_queue_overdue`, `gc_manifest_review_queue_overdue`, `applied_pre_migrations`, `applied_post_migrations` |

##### Histogrammes {#histograms-2}

| Nom de la métrique | Description | Labels | Compartiments |
|-------------|-------------|--------|---------|
| `registry_database_query_duration_seconds` | Un histogramme de latences pour les requêtes de base de données. | `name` | Compartiments par défaut de Prometheus. <sup>1</sup> |
| `registry_database_lb_lsn_cache_operation_duration_seconds` | Un histogramme de latences pour les opérations du cache LSN de l'équilibrage de charge de la base de données. | `operation`, `error` | `operation` : `set`, `get`<br>`error` : `true`, `false`<br>Compartiments par défaut de Prometheus. <sup>1</sup> |
| `registry_database_lb_lookup_seconds` | Un histogramme de latences pour les recherches DNS de l'équilibrage de charge de la base de données. | `lookup_type`, `error` | `lookup_type` : `srv`, `host`<br>`error` : `true`, `false`<br>Compartiments par défaut de Prometheus. <sup>1</sup>  |
| `registry_database_lb_lag_seconds` | Un histogramme du décalage de réplication en secondes pour chaque réplica. | `replica` | `[0.001, 0.01, 0.1, 0.5, 1, 5, 10, 20, 30, 60]` (1ms à 60s) |
| `registry_database_row_count_collection_duration_seconds` | Un histogramme de la durée totale pour la collecte de toutes les requêtes de comptage de lignes de la base de données en une seule exécution. | Aucune | `[0.1, 0.5, 1, 2, 5, 10, 30, 60]` (100ms à 60s) |

**Footnotes** :

1. Valeurs des compartiments par défaut de Prometheus : `[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]` (secondes)

#### Métriques de collecte des déchets (GC) {#garbage-collection-gc-metrics}

##### Compteurs {#counters-3}

| Nom de la métrique | Description | Labels | Valeurs de label |
|-------------|-------------|--------|--------------|
| `registry_gc_runs_total` | Un compteur pour les exécutions du worker GC en ligne. | `worker`, `noop`, `error`, `dangling`, `event` | `noop` : `true`, `false`<br>`error` : `true`, `false`<br>`dangling` : `true`, `false` |
| `registry_gc_deletes_total` | Un compteur des artefacts supprimés lors du GC en ligne. | `backend`, `artifact` | `backend` : `storage`, `database`<br>`artifact` : `blob`, `manifest` |
| `registry_gc_storage_deleted_bytes_total` | Un compteur pour les octets supprimés du stockage lors du GC en ligne. | `media_type` | chaîne : `'...'` |
| `registry_gc_postpones_total` | Un compteur pour les reports de révision du GC en ligne. | `worker` | chaîne : `'...'` |

##### Histogrammes {#histograms-3}

| Nom de la métrique | Description | Labels | Compartiments |
|-------------|-------------|--------|---------|
| `registry_gc_run_duration_seconds` | Un histogramme de latences pour les exécutions du worker GC en ligne. | `worker`, `noop`, `error`, `dangling`, `event` | `noop` : `true`, `false`<br>`error` : `true`, `false`<br>`dangling` : `true`, `false`<br>Compartiments par défaut de Prometheus. <sup>1</sup> |
| `registry_gc_delete_duration_seconds` | Un histogramme de latences pour les suppressions d'artefacts lors du GC en ligne. | `backend`, `artifact`, `error` | `backend` : `storage`, `database`<br>`artifact` : `blob`, `manifest`<br>`error` : `true`, `false`<br>Compartiments par défaut de Prometheus. <sup>1</sup> |
| `registry_gc_sleep_duration_seconds` | Un histogramme des durées de veille entre les exécutions du worker GC en ligne. | `worker` | `[0.5, 1, 5, 15, 30, 60, 300, 600, 900, 1800, 3600, 7200, 10800, 21600, 43200, 86400]` (500ms à 24h) |

**Footnotes** :

1. Valeurs des compartiments par défaut de Prometheus : `[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]` (secondes)

#### Métriques de stockage {#storage-metrics}

##### Compteurs {#counters-4}

| Nom de la métrique | Description | Labels | Valeurs de label |
|-------------|-------------|--------|--------------|
| `registry_storage_cdn_redirects_total` | Un compteur des redirections CDN pour les téléchargements de blobs. | `backend`, `bypass`, `bypass_reason` | `bypass` : `true`, `false` |
| `registry_storage_rate_limit_total` | Un compteur des requêtes au pilote de stockage ayant atteint une limite de débit. | Aucune | Aucune |
| `registry_storage_storage_backend_retries_total` | Un compteur des nouvelles tentatives effectuées lors de la communication avec le backend de stockage. | `retry_type` | `retry_type` : `native`, `custom` |
| `registry_storage_urlcache_requests_total` | Un compteur des requêtes du middleware de cache d'URL. | `result`, `reason` | `result` : `hit`, `miss` |
| `registry_storage_access_tracker_dropped_events` | Un compteur des événements abandonnés dans le tracker d'accès en raison d'un délai d'attente dépassé. | Aucune | Aucune |

##### Jauges {#gauges-3}

| Nom de la métrique | Description | Labels | Valeurs de label |
|-------------|-------------|--------|--------------|
| `registry_storage_object_accesses_topn` | Total des accès pour les N objets les plus fréquemment accédés. | `top_n` | `top_n` : `1`, `10`, `100`, `1000`, `10000`, `all` |

##### Histogrammes {#histograms-4}

| Nom de la métrique | Description | Labels | Compartiments |
|-------------|-------------|--------|---------|
| `registry_storage_blob_download_bytes` | Un histogramme des tailles de téléchargement de blobs pour le backend de stockage. | `redirect` | `redirect` : `true`, `false`<br>`[524288, 1048576, 67108864, 134217728, 268435456, 536870912, 1073741824, 2147483648, 3221225472, 4294967296, 5368709120, 6442450944, 7516192768, 8589934592, 9663676416, 10737418240, 21474836480, 32212254720, 42949672960, 53687091200]` (512 Kio à 50 Gio) |
| `registry_storage_blob_upload_bytes` | Un histogramme des octets de nouveaux téléchargements de blobs pour le backend de stockage. | Aucune | `[524288, 1048576, 67108864, 134217728, 268435456, 536870912, 1073741824, 2147483648, 3221225472, 4294967296, 5368709120, 6442450944, 7516192768, 8589934592, 9663676416, 10737418240, 21474836480, 32212254720, 42949672960, 53687091200]` (512 Kio à 50 Gio) |
| `registry_storage_urlcache_object_size` | Un histogramme des tailles d'objets dans le cache d'URL. | Aucune | `[100, 250, 500, 750, 1000, 1500, 2048, 3072, 5120, 10240]` (100 octets à 10 Kio) |
| `registry_storage_object_accesses_distribution` | Distribution des comptages d'accès sur tous les objets. | Aucune | Compartiments exponentiels : `[10, 20, 40, 80, 160, 320, 640, 1280, 2560, 5120, 10240]` |

## Activer les journaux de débogage du registre {#enable-registry-debug-logs}

Vous pouvez activer les journaux de débogage pour faciliter le dépannage du registre de conteneurs.

> [!warning]
> Les journaux de débogage peuvent contenir des informations sensibles telles que des détails d'authentification, des jetons ou des informations sur le dépôt. Activez les journaux de débogage uniquement si nécessaire, et désactivez-les une fois le dépannage terminé.

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Modifiez `/var/opt/gitlab/registry/config.yml` :

   ```yaml
   level: debug
   ```

1. Enregistrez le fichier et redémarrez le registre :

   ```shell
   sudo gitlab-ctl restart registry
   ```

Cette configuration est temporaire et est supprimée lorsque vous exécutez `gitlab-ctl reconfigure`.

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Exportez les valeurs Helm :

   ```shell
   helm get values gitlab > gitlab_values.yaml
   ```

1. Modifiez `gitlab_values.yaml` :

   ```yaml
   registry:
     log:
       level: debug
   ```

1. Enregistrez le fichier et appliquez les nouvelles valeurs :

   ```shell
   helm upgrade -f gitlab_values.yaml gitlab gitlab/gitlab --namespace <namespace>
   ```

{{< /tab >}}

{{< /tabs >}}

### Activer les métriques Prometheus du registre {#enable-registry-prometheus-metrics}

Si le serveur de débogage est activé, vous pouvez également activer les métriques Prometheus. Cet endpoint expose une télémétrie très détaillée concernant presque toutes les opérations du registre.

```ruby
registry['debug'] = {
  'prometheus' => {
    'enabled' => true,
    'path' => '/metrics'
  }
}
```

Utilisez curl pour demander la sortie de débogage depuis Prometheus :

```shell
curl "localhost:5001/debug/metrics"
```

## Tags avec un nom vide {#tags-with-an-empty-name}

Si vous utilisez [AWS DataSync](https://aws.amazon.com/datasync/) pour copier les données du registre vers ou entre des buckets S3, un objet de métadonnées vide est créé dans le chemin racine de chaque dépôt de conteneurs dans le bucket de destination. Cela amène le registre à interpréter ces fichiers comme un tag qui apparaît sans nom dans l'interface utilisateur et l'API GitLab. Pour plus d'informations, consultez [ce ticket](https://gitlab.com/gitlab-org/container-registry/-/issues/341).

Pour corriger ce problème, vous pouvez faire l'une des deux choses suivantes :

- Utilisez la commande [`rm`](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3/rm.html) de l'AWS CLI pour supprimer les objets vides à la racine de chaque dépôt concerné. Portez une attention particulière au `/` final et assurez-vous de ne pas utiliser l'option `--recursive` :

  ```shell
  aws s3 rm s3://<bucket>/docker/registry/v2/repositories/<path to repository>/
  ```

- Utilisez la commande [`sync`](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3/sync.html) de l'AWS CLI pour copier les données du registre vers un nouveau bucket et configurer le registre pour l'utiliser. Cela laisse les objets vides en place.

## Dépannage avancé {#advanced-troubleshooting}

Nous utilisons un exemple concret pour illustrer comment diagnostiquer un problème avec la configuration S3.

### Examiner une politique de nettoyage {#investigate-a-cleanup-policy}

Si vous ne savez pas pourquoi votre politique de nettoyage a ou n'a pas supprimé un tag, exécutez la politique ligne par ligne en exécutant le script ci-dessous depuis la [console Rails](../operations/rails_console.md). Cela peut aider à diagnostiquer les problèmes liés à la politique.

```ruby
repo = ContainerRepository.find(<repository_id>)
policy = repo.project.container_expiration_policy

tags = repo.tags
tags.map(&:name)

tags.reject!(&:latest?)
tags.map(&:name)

regex_delete = ::Gitlab::UntrustedRegexp.new("\\A#{policy.name_regex}\\z")
regex_retain = ::Gitlab::UntrustedRegexp.new("\\A#{policy.name_regex_keep}\\z")

tags.select! { |tag| regex_delete.match?(tag.name) && !regex_retain.match?(tag.name) }

tags.map(&:name)

now = DateTime.current
tags.sort_by! { |tag| tag.created_at || now }.reverse! # Lengthy operation

tags = tags.drop(policy.keep_n)
tags.map(&:name)

older_than_timestamp = ChronicDuration.parse(policy.older_than).seconds.ago

tags.select! { |tag| tag.created_at && tag.created_at < older_than_timestamp }

tags.map(&:name)
```

- Le script construit la liste des tags à supprimer (`tags`).
- `tags.map(&:name)` affiche une liste de tags à supprimer. Il peut s'agir d'une opération longue.
- Après chaque filtre, vérifiez la liste de `tags` pour voir si elle contient les tags destinés à être supprimés.

### Erreur 403 inattendue lors d'un push {#unexpected-403-error-during-push}

Un utilisateur a tenté d'activer un registre basé sur S3. L'étape `docker login` s'est déroulée correctement. Cependant, lors de l'envoi d'une image, la sortie affichait :

```plaintext
The push refers to a repository [s3-testing.myregistry.com:5050/root/docker-test/docker-image]
dc5e59c14160: Pushing [==================================================>] 14.85 kB
03c20c1a019a: Pushing [==================================================>] 2.048 kB
a08f14ef632e: Pushing [==================================================>] 2.048 kB
228950524c88: Pushing 2.048 kB
6a8ecde4cc03: Pushing [==>                                                ] 9.901 MB/205.7 MB
5f70bf18a086: Pushing 1.024 kB
737f40e80b7f: Waiting
82b57dbc5385: Waiting
19429b698a22: Waiting
9436069b92a3: Waiting
error parsing HTTP 403 response body: unexpected end of JSON input: ""
```

Cette erreur est ambiguë car il n'est pas clair si le 403 provient de l'application GitLab Rails, du registre Docker ou d'autre chose. Dans ce cas, puisque nous savons que la connexion a réussi, nous devons probablement examiner la communication entre le client et le registre.

L'API REST entre le client Docker et le registre est décrite [dans la documentation Docker](https://distribution.github.io/distribution/spec/api/). Habituellement, on utiliserait simplement Wireshark ou tcpdump pour capturer le trafic et voir où les choses ont mal tourné. Cependant, étant donné que toutes les communications entre les clients et les serveurs Docker se font via HTTPS, il est un peu difficile de déchiffrer rapidement le trafic, même si vous connaissez la clé privée. Que peut-on faire à la place ?

Une façon serait de désactiver HTTPS en configurant un [registre non sécurisé](https://distribution.github.io/distribution/about/insecure/). Cela pourrait introduire une faille de sécurité et n'est recommandé que pour les tests locaux. Si vous avez un système en production et que vous ne pouvez pas ou ne voulez pas faire cela, il existe une autre façon : utiliser mitmproxy, qui signifie Man-in-the-Middle Proxy.

### mitmproxy {#mitmproxy}

[mitmproxy](https://mitmproxy.org/) vous permet de placer un proxy entre votre client et votre serveur pour inspecter tout le trafic. Un point délicat est que votre système doit faire confiance aux certificats SSL de mitmproxy pour que cela fonctionne.

Les instructions d'installation suivantes supposent que vous exécutez Ubuntu :

1. [Installez mitmproxy](https://docs.mitmproxy.org/stable/overview-installation/).
1. Exécutez `mitmproxy --port 9000` pour générer ses certificats. Appuyez sur <kbd>Control</kbd>-<kbd>C</kbd> pour quitter.
1. Installez le certificat depuis `~/.mitmproxy` sur votre système :

   ```shell
   sudo cp ~/.mitmproxy/mitmproxy-ca-cert.pem /usr/local/share/ca-certificates/mitmproxy-ca-cert.crt
   sudo update-ca-certificates
   ```

En cas de succès, la sortie doit indiquer qu'un certificat a été ajouté :

```shell
Updating certificates in /etc/ssl/certs... 1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d....done.
```

Pour vérifier que les certificats sont correctement installés, exécutez :

```shell
mitmproxy --listen-port 9000
```

Cette commande exécute mitmproxy sur le port `9000`. Dans une autre fenêtre, exécutez :

```shell
curl --proxy "http://localhost:9000" "https://httpbin.org/status/200"
```

Si tout est correctement configuré, les informations s'affichent dans la fenêtre mitmproxy et aucune erreur n'est générée par les commandes curl.

### Exécution du démon Docker avec un proxy {#running-the-docker-daemon-with-a-proxy}

Pour que Docker se connecte via un proxy, vous devez démarrer le démon Docker avec les variables d'environnement appropriées. Le moyen le plus simple est d'arrêter Docker (par exemple `sudo initctl stop docker`) puis d'exécuter Docker manuellement. En tant que root, exécutez :

```shell
export HTTP_PROXY="http://localhost:9000"
export HTTPS_PROXY="http://localhost:9000"
docker daemon --debug # or dockerd --debug
```

Cette commande lance le démon Docker et redirige toutes les connexions via mitmproxy.

### Exécution du client Docker {#running-the-docker-client}

Maintenant que nous avons mitmproxy et Docker en cours d'exécution, nous pouvons tenter de nous connecter et d'envoyer une image de conteneur. Vous devrez peut-être exécuter en tant que root pour ce faire. Par exemple :

```shell
docker login example.s3.amazonaws.com:5050
docker push example.s3.amazonaws.com:5050/root/docker-test/docker-image
```

Dans l'exemple précédent, nous voyons la trace suivante dans la fenêtre mitmproxy :

```plaintext
PUT https://example.s3.amazonaws.com:4567/v2/root/docker-test/blobs/uploads/(UUID)/(QUERYSTRING)
    ← 201 text/plain [no content] 661ms
HEAD https://example.s3.amazonaws.com:4567/v2/root/docker-test/blobs/sha256:(SHA)
    ← 307 application/octet-stream [no content] 93ms
HEAD https://example.s3.amazonaws.com:4567/v2/root/docker-test/blobs/sha256:(SHA)
    ← 307 application/octet-stream [no content] 101ms
HEAD https://example.s3.amazonaws.com:4567/v2/root/docker-test/blobs/sha256:(SHA)
    ← 307 application/octet-stream [no content] 87ms
HEAD https://amazonaws.example.com/docker/registry/vs/blobs/sha256/dd/(UUID)/data(QUERYSTRING)
    ← 403 application/xml [no content] 80ms
HEAD https://amazonaws.example.com/docker/registry/vs/blobs/sha256/dd/(UUID)/data(QUERYSTRING)
    ← 403 application/xml [no content] 62ms
```

Cette sortie montre :

- Les requêtes PUT initiales se sont déroulées correctement avec un code de statut `201`.
- Le `201` a redirigé le client vers le bucket Amazon S3.
- La requête HEAD vers le bucket AWS a signalé un `403 Unauthorized`.

Qu'est-ce que cela signifie ? Cela suggère fortement que l'utilisateur S3 ne dispose pas des [autorisations pour effectuer une requête HEAD](https://docs.aws.amazon.com/AmazonS3/latest/API/API_HeadObject.html). La solution : vérifiez à nouveau les [autorisations IAM](https://distribution.github.io/distribution/storage-drivers/s3/). Une fois les autorisations correctes définies, l'erreur a disparu.

## L'absence de `gitlab-registry.key` empêche la suppression du dépôt de conteneurs {#missing-gitlab-registrykey-prevents-container-repository-deletion}

Si vous désactivez le registre de conteneurs de votre instance GitLab et essayez de supprimer un projet qui contient des dépôts de conteneurs, l'erreur suivante se produit :

```plaintext
Errno::ENOENT: No such file or directory @ rb_sysopen - /var/opt/gitlab/gitlab-rails/etc/gitlab-registry.key
```

Dans ce cas, suivez ces étapes :

1. Activez temporairement le paramètre à l'échelle de l'instance pour le registre de conteneurs dans votre `gitlab.rb` :

   ```ruby
   gitlab_rails['registry_enabled'] = true
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
1. Réessayez la suppression.

Si vous ne parvenez toujours pas à supprimer le dépôt en utilisant les méthodes courantes, vous pouvez utiliser la [console Rails GitLab](../operations/rails_console.md) pour supprimer le projet de force :

```ruby
# Path to the project you'd like to remove
prj = Project.find_by_full_path(<project_path>)

# The following will delete the project's container registry, so be sure to double-check the path beforehand!
if prj.has_container_registry_tags?
  prj.container_repositories.each { |p| p.destroy }
end
```

## Le service de registre écoute sur l'adresse IPv6 au lieu de l'IPv4 {#registry-service-listens-on-ipv6-address-instead-of-ipv4}

Vous pourriez voir l'erreur suivante si le nom d'hôte `localhost` se résout en adresse de bouclage IPv6 (`::1`) sur votre serveur GitLab et que GitLab s'attend à ce que le service de registre soit disponible sur l'adresse de bouclage IPv4 (`127.0.0.1`) :

```plaintext
request: "GET /v2/ HTTP/1.1", upstream: "http://[::1]:5000/v2/", host: "registry.example.com:5005"
[error] 1201#0: *13442797 connect() failed (111: Connection refused) while connecting to upstream, client: x.x.x.x, server: registry.example.com, request: "GET /v2/<path> HTTP/1.1", upstream: "http://[::1]:5000/v2/<path>", host: "registry.example.com:5005"
```

Pour corriger l'erreur, remplacez `registry['registry_http_addr']` par une adresse IPv4 dans `/etc/gitlab/gitlab.rb`. Par exemple :

```ruby
registry['registry_http_addr'] = "127.0.0.1:5000"
```

Consultez le [ticket 5449](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/5449) pour plus de détails.

## Échecs de push et utilisation élevée du CPU avec Google Cloud Storage (GCS) {#push-failures-and-high-cpu-usage-with-google-cloud-storage-gcs}

Vous pourriez obtenir une erreur `502 Bad Gateway` lors de l'envoi d'images de conteneurs vers un registre qui utilise GCS comme backend. Le registre peut également connaître des pics d'utilisation du CPU lors de l'envoi de grandes images.

Ce problème se produit lorsque le registre communique avec GCS en utilisant le protocole HTTP/2.

La solution de contournement consiste à désactiver HTTP/2 dans votre déploiement de registre en définissant la variable d'environnement `GODEBUG` à `http2client=0`.

Pour plus d'informations, consultez le [ticket 1425](https://gitlab.com/gitlab-org/container-registry/-/issues/1425).
