---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Dépannage d'OpenBao"
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed
- Statut : Version bêta

{{< /details >}}

Pour les tâches liées aux clés de récupération et aux jetons root de secours, consultez la [gestion des clés de récupération](recovery_key.md). Pour le basculement Geo, consultez [Reprise de Geo après sinistre](../geo/disaster_recovery/_index.md#step-4-optional-promote-the-openbao-ha-cluster).

## Où s'exécute OpenBao {#where-openbao-runs}

OpenBao s'exécute toujours dans Kubernetes, même lorsque GitLab utilise le package Linux. Le namespace et le nom du déploiement dépendent de la méthode d'installation :

| Méthode d'installation | Namespace | Déploiement       | Conteneur de pod    |
|---------------------|-----------|------------------|------------------|
| Cloud Native GitLab | `gitlab`  | `gitlab-openbao` | `openbao-server` |
| Package Linux       | `openbao` | `openbao`        | `openbao-server` |

Ces exemples utilisent le namespace Cloud Native `gitlab`. Pour une installation avec le package Linux, remplacez `gitlab` par `openbao` dans les commandes `kubectl`.

Les pods OpenBao portent le label `app.kubernetes.io/name=openbao`. Le nœud actif porte également `openbao-active=true`.

## Rechercher les logs OpenBao {#find-openbao-logs}

Lisez les logs OpenBao avec `kubectl logs`. Les logs GitLab Rails et Sidekiq associés sont stockés séparément, selon la méthode d'installation :

| Source         | Cloud Native GitLab                              | Package Linux                                      |
|----------------|--------------------------------------------------|----------------------------------------------------|
| Serveur OpenBao | `kubectl logs` sur le conteneur `openbao-server` | `kubectl logs` sur le conteneur `openbao-server`   |
| GitLab Rails   | `kubectl logs` sur les pods `webservice`          | `/var/log/gitlab/gitlab-rails/production_json.log` |
| Sidekiq        | `kubectl logs` sur les pods `sidekiq`             | `/var/log/gitlab/sidekiq/current`                  |
| GitLab Runner  | job log CI/CD dans l'interface utilisateur GitLab                   | job log CI/CD dans l'interface utilisateur GitLab                     |

OpenBao publie les événements d'audit vers GitLab et les écrit également dans les logs des pods OpenBao.

### Rechercher les pods OpenBao {#find-the-openbao-pods}

Pour lister les pods OpenBao et voir quel nœud est actif :

```shell
kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao \
  --label-columns openbao-active,openbao-sealed
```

Le pod dont `OPENBAO-ACTIVE` est défini sur `true` est le nœud actif. Les autres sont des nœuds de secours.

### Vérifier le statut d'OpenBao {#check-openbao-status}

OpenBao doit être déverrouillé pour traiter les requêtes. Pour vérifier, exécutez `bao status` dans un pod :

```shell
OPENBAO_POD=$(kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name | head -1)
kubectl exec -n gitlab "$OPENBAO_POD" -c openbao-server -- \
  sh -c "BAO_ADDR=http://127.0.0.1:8200 bao status"
```

Dans la sortie, `Sealed` doit être `false`. Le nœud actif affiche `HA Mode    active` et un nœud de secours affiche `HA Mode    standby` :

```plaintext
Seal Type       static
Initialized     true
Sealed          false
Storage Type    postgresql
HA Enabled      true
HA Mode         active
```

Le point de terminaison `sys/seal-status` rapporte le même état que `"sealed":false` :

```shell
kubectl exec -n gitlab "$OPENBAO_POD" -c openbao-server -- \
  sh -c "BAO_ADDR=http://127.0.0.1:8200 bao read sys/seal-status"
```

> [!note]
> Le binaire `bao` est présent dans le pod. Utilisez `bao read` pour les requêtes de point de terminaison depuis l'intérieur du pod.

Dans les logs, un nœud qui a été déverrouillé avec succès enregistre `vault is unsealed`. Le nœud actif enregistre `acquired lock, enabling active operation` et un nœud de secours enregistre `entering standby mode` :

```shell
OPENBAO_POD=$(kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name | head -1)
kubectl logs -n gitlab "$OPENBAO_POD" -c openbao-server \
  | grep -E "acquired lock, enabling active operation|entering standby mode"
```

### Rechercher des erreurs dans une fenêtre temporelle {#find-errors-in-a-time-window}

Pour lire les logs OpenBao sur une fenêtre temporelle, utilisez `--since` :

```shell
OPENBAO_POD=$(kubectl get pods -n gitlab -l app.kubernetes.io/name=openbao -o name | head -1)
kubectl logs -n gitlab "$OPENBAO_POD" -c openbao-server --since=30m \
  | grep -iE "error|warn|failed"
```

Pour une installation avec le package Linux, recherchez dans les fichiers de log Rails et Sidekiq par heure. Les logs sont au format JSON, un événement par ligne.

> [!note]
> OpenBao écrit toute la sortie vers l'erreur standard, de sorte que certaines plateformes de logs taguent chaque ligne comme une erreur. Faites confiance au niveau indiqué dans le corps du message (`[info]`, `[warn]`), pas à l'étiquette de la plateforme.

### Logs GitLab Rails {#gitlab-rails-logs}

Les logs Rails couvrent les opérations sur les secrets depuis l'interface utilisateur et l'API GraphQL, ainsi que le callback d'audit d'OpenBao.

Pour une installation Cloud Native :

```shell
kubectl logs -n gitlab -l app=webservice -c webservice \
  | grep -E "Projects::SecretsController|Groups::SecretsController|secrets_manager/audit_logs"
```

Pour une installation avec le package Linux :

```shell
grep -E "Projects::SecretsController|Groups::SecretsController|secrets_manager/audit_logs" \
  /var/log/gitlab/gitlab-rails/production_json.log
```

Les opérations GraphQL apparaissent avec un `caller_id` tel que `graphql:createProjectSecret` ou `graphql:getGroupSecrets`. Le callback d'audit apparaît sous le chemin `/api/v4/internal/secrets_manager/audit_logs`.

### Logs Sidekiq {#sidekiq-logs}

Les workers qui provisionnent, déprovisionnent et maintiennent les enregistrements du gestionnaire de secrets s'exécutent sous le namespace `SecretsManagement::`.

Pour une installation Cloud Native :

```shell
kubectl logs -n gitlab -l app=sidekiq -c sidekiq | grep "SecretsManagement::"
```

Pour une installation avec le package Linux :

```shell
grep "SecretsManagement::" /var/log/gitlab/sidekiq/current
```

Pour les problèmes de provisionnement, filtrez sur `ProvisionProjectSecretsManagerWorker` ou `ProvisionGroupSecretsManagerWorker`.

### Logs GitLab Runner {#gitlab-runner-logs}

Lorsqu'un job CI/CD échoue à récupérer un secret, la cause apparaît dans le job log dans l'interface utilisateur GitLab. Recherchez les chaînes suivantes dans le job log :

| Chaîne                                           | Signification                                                            |
|--------------------------------------------------|--------------------------------------------------------------------|
| `Resolving secrets`                              | Le runner a commencé à résoudre les secrets du job.                    |
| `Using "gitlab_secrets_manager" secret resolver` | Le runner a sélectionné le résolveur GitLab Secrets Manager.           |
| `not initialized or sealed Vault server`         | OpenBao est verrouillé ou non initialisé.                              |
| `api error: status code 403: permission denied`  | OpenBao a rejeté la requête, souvent un problème d'audience ou de permission. |
| `inline auth JWT is required`                    | Le runner n'a pas pu construire la requête d'authentification.            |

### Logs de démarrage sains {#healthy-startup-logs}

Après un redémarrage, le nœud actif enregistre cette séquence. Un nœud de secours s'arrête à `vault is unsealed` puis enregistre `entering standby mode`. Le format de ligne varie selon la configuration, faites donc correspondre le texte du message plutôt qu'un préfixe.

| Message de log                                | Signification                              | Si absent                                            |
|--------------------------------------------|--------------------------------------|-------------------------------------------------------|
| `==> OpenBao server started!`              | Le processus a démarré et lu la configuration. | Le pod n'a pas réussi à démarrer. Vérifiez les événements du pod.        |
| `vault is unsealed`                        | Le déverrouillage automatique a réussi.               | Le déverrouillage automatique a échoué. Vérifiez le secret de déverrouillage ou KMS.   |
| `acquired lock, enabling active operation` | Ce nœud est devenu actif.             | Aucun nœud n'est actif. Vérifiez la base de données et le verrou HA.    |
| `post-unseal setup complete`               | Le nœud actif a terminé la configuration.      | La configuration n'a pas été achevée. Vérifiez la connexion à la base de données.  |

### Messages d'erreur {#error-messages}

Les messages OpenBao proviennent du conteneur `openbao-server`. Les messages GitLab proviennent des logs Rails ou Sidekiq.

| Conteneur        | Message                                                       | Explication                                                        | Action                                                              |
|------------------|---------------------------------------------------------------|--------------------------------------------------------------------|---------------------------------------------------------------------|
| `openbao-server` | `cipher: message authentication failed`                       | La clé de scellement ne peut pas déchiffrer les données stockées.                       | Pour un déverrouillage statique, copiez le secret de déverrouillage depuis le site principal. Pour un scellement KMS, vérifiez la clé KMS. Consultez [Dépanner les déploiements Geo](#troubleshoot-geo-deployments). |
| `openbao-server` | `unknown key ID`                                              | L'ID de la clé de déverrouillage statique ne correspond pas aux données en base de données.  | Copiez le secret de déverrouillage depuis le site principal. Consultez [Dépanner les déploiements Geo](#troubleshoot-geo-deployments). |
| `openbao-server` | `failed to acquire lock`                                      | Un nœud de secours ne peut pas acquérir le verrou HA sur une base de données en lecture seule. | Attendu sur un secondaire Geo. Aucune action requise.                    |
| `openbao-server` | `cannot execute INSERT in a read-only transaction`            | Un nœud de secours a tenté d'écrire sur un réplica en lecture seule.                   | Attendu sur un secondaire Geo. Sinon, assurez-vous qu'OpenBao dispose d'un accès en écriture à la base de données et vérifiez les permissions de la base de données. |
| `openbao-server` | `post-unseal upgrade seal keys failed: error="no recovery key found"` | La clé de récupération n'a jamais été stockée.                         | Sans conséquence. Exécutez `recovery_key:store`. |
| Rails ou Sidekiq | `[OpenBao] health check returned unhealthy`                   | OpenBao a répondu mais a signalé un état non sain.                 | Vérifiez `bao status` et les logs OpenBao.                            |
| Rails ou Sidekiq | `[OpenBao] health check failed`                               | GitLab n'a pas pu atteindre OpenBao.                                    | Vérifiez la connectivité. Consultez [GitLab ne peut pas se connecter à OpenBao](#gitlab-cannot-connect-to-openbao). |
| Rails ou Sidekiq | `Failed to authenticate with OpenBao`                         | OpenBao a rejeté le JWT.                                          | Vérifiez l'audience. Consultez [L'authentification JWT échoue](#jwt-authentication-fails). |
| Rails ou Sidekiq | `Failed to open TCP connection to <host>:443 (execution expired)` | Sidekiq n'a pas pu atteindre l'URL OpenBao.                       | Vérifiez le DNS et l'URL OpenBao depuis un pod Sidekiq.                   |
| Rails ou Sidekiq | `SSL_connect ... state=error: wrong version number`           | Une URL `https` pointe vers un écouteur OpenBao qui sert du `http`.   | Faites correspondre le schéma de l'URL à l'écouteur. Consultez [GitLab ne peut pas se connecter à OpenBao](#gitlab-cannot-connect-to-openbao). |
| Rails ou Sidekiq | `Retrying failed secrets_manager maintenance task`            | Une tâche de provisionnement ou de déprovisionnement est en cours de nouvelle tentative.            | Vérifiez l'erreur du worker dans le même log. Les nouvelles tentatives s'arrêtent après trois essais. |

## Le gestionnaire de secrets est bloqué en provisionnement {#secrets-manager-is-stuck-in-provisioning}

Lorsque vous activez le gestionnaire de secrets, le bouton peut rester dans un état de chargement avec le statut `provisioning`. Le gestionnaire de secrets n'a pas d'état `failed`, donc toute étape qui échoue avant l'activation laisse l'enregistrement bloqué. La cause habituelle est que Sidekiq ne peut pas atteindre OpenBao.

Pour diagnostiquer :

1. Vérifiez les logs Sidekiq pour le worker de provisionnement :

   ```shell
   kubectl logs -n gitlab -l app=sidekiq -c sidekiq \
     | grep -E "ProvisionProjectSecretsManagerWorker|ProvisionGroupSecretsManagerWorker"
   ```

1. Vérifiez si Sidekiq peut atteindre OpenBao, depuis un pod ou un nœud Sidekiq :

   ```shell
   curl "https://openbao.example.com/v1/sys/health"
   ```

Un worker de maintenance réessaie une tâche obsolète jusqu'à trois fois, puis s'arrête. Après cela, l'enregistrement reste dans `provisioning` sans récupération automatique, et les nouvelles tentatives enregistrent `Retrying failed
secrets_manager maintenance task`.

Une fois la connectivité rétablie, désactivez et réactivez le gestionnaire de secrets pour le provisionner à nouveau.

### Point de montage d'authentification manquant après l'auto-initialisation {#authentication-mount-missing-after-self-initialization}

Sur une nouvelle installation avec plusieurs pods OpenBao, une condition de course lors de l'auto-initialisation peut laisser OpenBao déverrouillé mais sans le point de montage d'authentification `gitlab_rails_jwt/`. Les pods semblent sains, mais les opérations sur les secrets échouent avec une erreur de permission refusée. Exécutez `bao auth list` avec un jeton root pour confirmer que le point de montage existe. Pour éviter la condition de course, démarrez une nouvelle installation avec un seul réplica, confirmez que l'initialisation est terminée, puis montez en charge.

## GitLab ne peut pas se connecter à OpenBao {#gitlab-cannot-connect-to-openbao}

GitLab Rails et Sidekiq se connectent à OpenBao via HTTP. Rails utilise `internal_url`, et se replie sur `url` lorsque `internal_url` n'est pas défini. Pour inspecter la configuration, exécutez cette commande dans la [console Rails](../operations/rails_console.md) :

```ruby
Gitlab.config.openbao.to_h
```

Causes courantes :

- Une URL `https://` pointant vers un écouteur OpenBao qui sert du `http` échoue avec `wrong version number`. `global.openbao.https` définit le schéma avec lequel GitLab se connecte, pas le TLS de l'écouteur OpenBao. L'écouteur sert du HTTP simple par défaut. Laissez `global.openbao.https` non défini pour qu'il corresponde, ou activez le TLS de l'écouteur avec `openbao.config.tlsDisable: false` et définissez `global.openbao.https` sur `true`.
- La découverte OIDC et la journalisation d'audit échouent avec un certificat TLS non approuvé. Utilisez un certificat approuvé par GitLab.
- Une requête qui ne produit aucune entrée d'audit OpenBao n'a jamais atteint le backend d'authentification. Vérifiez l'Ingress ou le proxy inverse.

Pour une installation Cloud Native, une configuration fonctionnelle ressemble à ceci :

```yaml
global:
  openbao:
    enabled: true
    url: http://gitlab-openbao-active:8200
    internal_url: http://gitlab-openbao-active:8200
```

Pour une installation avec le package Linux, GitLab utilise le paramètre `gitlab_rails['openbao']['url']` dans `/etc/gitlab/gitlab.rb` pour se connecter à OpenBao. Le proxy inverse NGINX intégré achemine vers OpenBao avec les paramètres `oak['components']['openbao']`. Pour plus d'informations, consultez [Installer OpenBao pour un déploiement avec le package Linux](linux_package_integration.md).

## L'authentification JWT échoue {#jwt-authentication-fails}

GitLab s'authentifie auprès d'OpenBao avec un JWT. La revendication `aud` (audience) dans le JWT doit correspondre exactement à la valeur `bound_audiences` sur le rôle d'authentification OpenBao. Toute différence fait échouer l'authentification, y compris une barre oblique finale, `http` comparé à `https`, ou un port.

OpenBao stocke `bound_audiences` au moment de l'initialisation, dérivé de l'URL OpenBao. La valeur stockée ne change pas lorsque vous modifiez l'URL ultérieurement. La modification de l'URL rompt donc l'authentification, car le `bound_audiences` stocké ne correspond plus au `aud` envoyé par GitLab. Pour définir l'audience indépendamment de l'URL de connexion, utilisez `global.openbao.jwt_audience`.

Pour trouver l'audience envoyée par GitLab, exécutez cette commande dans la console Rails :

```ruby
SecretsManagement::ProjectSecretsManager.jwt_audience
```

La méthode retourne la valeur `jwt_audience` configurée, ou l'`url` OpenBao lorsque `jwt_audience` n'est pas défini. Pour inspecter la valeur stockée, lisez le rôle d'authentification avec un jeton root et comparez `bound_audiences` à cette audience.

> [!warning]
> Vous ne pouvez pas résoudre ce problème sans accès privilégié. Le jeton root est révoqué après l'auto-initialisation, et la clé de déverrouillage n'est pas un substitut. Le secret de déverrouillage contient uniquement la clé de déverrouillage, pas un jeton root.

Pour corriger la discordance sans supprimer les secrets stockés, reconfigurez l'authentification avec une clé de récupération. Pour la procédure, consultez [Reconfigurer l'authentification avec une clé de récupération](maintenance.md#reconfigure-authentication-with-a-recovery-key).

Si vous ne disposez pas d'une clé de récupération, [réinitialisez les données OpenBao](maintenance.md#reset-openbao-data). Cela supprime tous les secrets stockés.

## Les pods OpenBao sont verrouillés {#openbao-pods-are-sealed}

Si `bao status` signale `Sealed    true` au démarrage, le déverrouillage automatique a échoué :

- Avec le déverrouillage statique par défaut, la cause est généralement un secret de déverrouillage manquant ou incorrect. Le secret est `gitlab-openbao-unseal` pour une installation Cloud Native, et `openbao-static-unseal` pour une installation avec le package Linux.
- Avec le déverrouillage automatique KMS, actuellement AWS KMS (`awskms`), la cause est généralement qu'OpenBao ne peut pas atteindre le KMS.

Pour vérifier le statut du scellement, consultez [Vérifier le statut d'OpenBao](#check-openbao-status).

> [!warning]
> Si vous faites pivoter la clé de déverrouillage statique sans conserver la clé précédente disponible, OpenBao ne peut pas déchiffrer les données existantes. Ajoutez la clé précédente aux côtés de la nouvelle clé, et supprimez-la uniquement après que tous les pods fonctionnent avec la nouvelle clé.

## Problèmes de base de données {#database-problems}

OpenBao nécessite sa propre base de données PostgreSQL. Le chart GitLab fait échouer l'installation ou la mise à niveau si vous activez OpenBao sans une base de données dédiée.

Autres problèmes de base de données :

- L'épuisement du pool de connexions ou une latence élevée provoquent des délais d'attente intermittents.
- Des valeurs incorrectes pour `md5_auth_cidr_addresses`, `sslMode` ou le mot de passe dans une configuration PostgreSQL du package Linux font passer les pods OpenBao en `CrashLoopBackOff`. Pour les paramètres corrects, consultez [Installer OpenBao pour un déploiement avec le package Linux](linux_package_integration.md).

## Des événements d'audit sont manquants {#audit-events-are-missing}

OpenBao publie les événements d'audit vers GitLab à l'adresse `/api/v4/internal/secrets_manager/audit_logs`. Le chart GitLab active la journalisation d'audit par défaut. Si les événements d'audit n'arrivent pas :

- Définir `config.audit.http.enabled` sur `false` empêche OpenBao de publier des événements. Confirmez que la journalisation d'audit est activée.
- Une discordance de jeton d'audit partagé renvoie `401` sur le point de terminaison d'audit. Confirmez que GitLab et OpenBao utilisent le même jeton d'audit.

## Dépanner les déploiements Geo {#troubleshoot-geo-deployments}

OpenBao s'exécute en tant que nœud actif sur le site Geo principal et en tant que nœud de secours sur chaque site secondaire. Un nœud secondaire se connecte à un réplica PostgreSQL en lecture seule, il enregistre donc `failed to acquire lock` et `cannot execute INSERT in a read-only transaction`. Ces messages sont attendus.

Si un nœud secondaire enregistre `cipher: message authentication failed` ou `unknown key ID`, sa clé de scellement ne correspond pas à celle du principal. La correction dépend du mécanisme de scellement :

- Avec un déverrouillage statique, copiez le secret `gitlab-openbao-unseal` depuis le cluster principal vers le cluster secondaire, puis redémarrez les pods OpenBao :

  ```shell
  kubectl -n gitlab get secret gitlab-openbao-unseal -o yaml
  ```

- Avec un scellement KMS, configurez les deux sites pour utiliser la même clé KMS.

Si l'authentification JWT échoue après un basculement, l'audience ne correspond plus au `bound_audiences` stocké. La correction dépend du domaine :

- Si les deux sites utilisent l'URL OpenBao principale, définissez `jwt_audience` sur l'URL OpenBao principale sur les deux sites. Consultez [Installer OpenBao sur un site secondaire](_index.md#install-openbao-on-a-secondary-site).
- Si le site secondaire utilise un domaine différent, cette configuration n'est pas prise en charge. La reconfiguration de l'audience ne restaure pas l'authentification, car chaque espace de nommage de projet et de groupe doit également être reprovisionné. Mettez à jour le DNS de sorte que le domaine principal pointe vers le secondaire promu. Pour plus d'informations, consultez [Déploiement Geo](_index.md#geo-deployment).

## Diagnostiquer les opérations lentes sur les secrets {#diagnose-slow-secret-operations}

Lorsque les jobs CI/CD sont lents à récupérer les secrets ou que les opérations sur les secrets expirent, utilisez les requêtes suivantes pour trouver la cause. Exécutez ces requêtes dans l'instance Prometheus ou Grafana qui collecte les métriques OpenBao. Pour exposer ces métriques, consultez [Métriques OpenBao](_index.md#openbao-metrics).

### Confirmer que la latence est élevée {#confirm-latency-is-elevated}

Utilisez la requête suivante pour mesurer la latence moyenne des requêtes en millisecondes. La requête fonctionne à n'importe quel niveau de trafic, y compris pour les déploiements à faible trafic :

```prometheus
rate(openbao_core_handle_request_sum[5m])
/
rate(openbao_core_handle_request_count[5m])
```

En charge normale, la latence moyenne pour tous les types de requêtes est généralement de 3 à 7 ms. Examinez le problème si la latence moyenne dépasse régulièrement 20 ms.

Lorsqu'OpenBao traite activement des requêtes, utilisez la requête suivante pour la latence P99 :

```prometheus
openbao_core_handle_request{quantile="0.99"}
```

Le P99 normal est inférieur à 10 ms. Cette requête retourne `NaN` lorsqu'OpenBao est inactif car la fenêtre de résumé ne contient pas d'observations récentes. Utilisez la requête basée sur le taux dans ce cas.

### Identifier les problèmes potentiels {#identify-potential-issues}

| Problème potentiel             | Quoi vérifier                   | Requête                                                                       | Seuil           | Action                                                             |
|-----------------------------|---------------------------------|-----------------------------------------------------------------------------|---------------------|--------------------------------------------------------------------|
| Limite CPU trop basse           | Taux de limitation CFS              | [Requête de limitation CPU](_index.md#cpu-throttling)                            | > 25 %               | Augmenter la limite CPU                                                 |
| La demande dépasse la capacité CPU | Utilisation du CPU                 | [Requête d'utilisation du CPU](_index.md#cpu-utilization)                          | > 50 % de la demande    | Passer à la ligne suivante dans le [tableau de dimensionnement](_index.md#pod-resources) |
| Pic de requêtes               | Requêtes en cours de traitement              | `openbao_core_in_flight_requests`                                           | Soutenu au-dessus de 5   | Transitoire. Surveillez les récurrences.                                 |
| Goulot d'étranglement PostgreSQL       | Latence de lecture PostgreSQL moyenne | `rate(openbao_postgres_get_sum[5m]) / rate(openbao_postgres_get_count[5m])` | > 5 ms              | Vérifiez les ressources PostgreSQL et le pool de connexions                     |
| Pression mémoire             | Utilisation de la mémoire              | [Requête d'utilisation de la mémoire](_index.md#memory-utilization)                    | Proche de la demande de mémoire | Augmentez la mémoire à l'aide de la [formule de namespace](_index.md#memory-utilization) |

Si la latence PostgreSQL est élevée, vérifiez si le pool de connexions est saturé. Si toutes les connexions sont occupées, les requêtes supplémentaires se mettent en file d'attente et génèrent de la latence. Pour la configuration du pool de connexions, consultez [Ressources de base de données](_index.md#database-resources).
