---
stage: Tenant Scale
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage de Gitaly
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les sections suivantes proposent des solutions possibles aux erreurs Gitaly.

Consultez également les paramètres de [délai d'expiration Gitaly](../settings/gitaly_timeouts.md), ainsi que nos conseils sur [l'analyse du fichier `gitaly/current`](../logs/log_parsing.md#parsing-gitalycurrent).

## Prérequis {#prerequisites}

Vous devez disposer d'un accès administrateur.

## Vérifier les versions lors de l'utilisation de serveurs Gitaly autonomes {#check-versions-when-using-standalone-gitaly-servers}

Lorsque vous utilisez des serveurs Gitaly autonomes, vous devez vous assurer qu'ils sont à la même version que GitLab pour garantir une compatibilité totale :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble** > **Serveurs Gitaly**.
1. Confirmez que tous les serveurs Gitaly indiquent qu'ils sont à jour.

## Trouver les détails des ressources de stockage {#find-storage-resource-details}

Vous pouvez exécuter les commandes suivantes dans une [console Rails](../operations/rails_console.md#starting-a-rails-console-session) pour déterminer l'espace disponible et utilisé sur un stockage Gitaly :

```ruby
Gitlab::GitalyClient::ServerService.new("default").storage_disk_statistics
# For Gitaly Cluster (Praefect)
Gitlab::GitalyClient::ServerService.new("<storage name>").disk_statistics
```

## Utiliser `gitaly-debug` {#use-gitaly-debug}

La commande `gitaly-debug` fournit des outils de "débogage en production" pour les performances de Gitaly et de Git. Elle est destinée à aider les ingénieurs de production et les ingénieurs du support à examiner les problèmes de performances de Gitaly.

Pour afficher la page d'aide de `gitaly-debug` et obtenir la liste des sous-commandes prises en charge, exécutez :

```shell
gitaly-debug -h
```

## Utiliser `gitaly git` lorsque Git est requis pour le dépannage {#use-gitaly-git-when-git-is-required-for-troubleshooting}

Utilisez `gitaly git` pour exécuter des commandes Git en utilisant le même environnement d'exécution Git que Gitaly à des fins de débogage ou de test. `gitaly git` est la méthode privilégiée pour assurer la compatibilité des versions.

`gitaly git` transmet tous les arguments à l'invocation Git sous-jacente et prend en charge toutes les formes d'entrée que Git prend en charge. Pour utiliser `gitaly git`, exécutez :

```shell
sudo -u git -- /opt/gitlab/embedded/bin/gitaly git <git-command>
```

Par exemple, pour exécuter `git ls-tree` via Gitaly sur une instance de package Linux dans le répertoire de travail d'un dépôt :

```shell
sudo -u git -- /opt/gitlab/embedded/bin/gitaly git ls-tree --name-status HEAD
```

## Les commits, les push et les clones retournent une erreur 401 {#commits-pushes-and-clones-return-a-401}

```plaintext
remote: GitLab: 401 Unauthorized
```

Vous devez synchroniser votre fichier `gitlab-secrets.json` avec vos nœuds d'application GitLab.

## Erreurs 500 et `fetching folder content` sur les pages de dépôt {#500-and-fetching-folder-content-errors-on-repository-pages}

`Fetching folder content`, et dans certains cas `500`, les erreurs indiquent des problèmes de connectivité entre GitLab et Gitaly. Consultez les [journaux gRPC côté client](#client-side-grpc-logs) pour plus de détails.

## Journaux gRPC côté client {#client-side-grpc-logs}

Gitaly utilise le framework RPC [gRPC](https://grpc.io/). Le client Ruby gRPC possède son propre fichier journal qui peut contenir des informations utiles lorsque vous rencontrez des erreurs Gitaly. Vous pouvez contrôler le niveau de journal du client gRPC avec la variable d'environnement `GRPC_LOG_LEVEL`. Le niveau par défaut est `WARN`.

Vous pouvez exécuter une trace gRPC avec :

```shell
sudo GRPC_TRACE=all GRPC_VERBOSITY=DEBUG gitlab-rake gitlab:gitaly:check
```

Si cette commande échoue avec une erreur `failed to connect to all addresses`, vérifiez s'il y a un problème SSL ou TLS :

```shell
/opt/gitlab/embedded/bin/openssl s_client -connect <gitaly-ipaddress>:<port> -verify_return_error
```

Vérifiez si le champ `Verify return code` indique un [problème de configuration connu de l'installation de package Linux](https://docs.gitlab.com/omnibus/settings/ssl/).

Si `openssl` réussit mais que `gitlab-rake gitlab:gitaly:check` échoue, vérifiez les [exigences en matière de certificats](tls_support.md#certificate-requirements) pour Gitaly.

## Journaux gRPC côté serveur {#server-side-grpc-logs}

Le traçage gRPC peut également être activé dans Gitaly lui-même avec la variable d'environnement `GODEBUG=http2debug`. Pour définir cela dans une installation de package Linux :

1. Ajoutez ce qui suit à votre fichier `gitlab.rb` :

   ```ruby
   gitaly['env'] = {
     "GODEBUG=http2debug" => "2"
   }
   ```

1. [Reconfigurer](../restart_gitlab.md#reconfigure-a-linux-package-installation) GitLab.

## Corrélation des processus Git avec les RPC {#correlating-git-processes-with-rpcs}

Vous devez parfois déterminer quel RPC Gitaly a créé un processus Git particulier.

Une méthode pour ce faire consiste à utiliser la journalisation `DEBUG`. Cependant, cela doit être activé à l'avance et les journaux produits sont volumineux.

Une méthode légère pour effectuer cette corrélation consiste à inspecter l'environnement du processus Git (en utilisant son `PID`) et à examiner la variable `CORRELATION_ID` :

```shell
PID=<Git process ID>
sudo cat /proc/$PID/environ | tr '\0' '\n' | grep ^CORRELATION_ID=
```

Cette méthode n'est pas fiable pour les processus `git cat-file`, car Gitaly les regroupe et les réutilise en interne entre les RPC.

## Les modifications de dépôt échouent avec une erreur `401 Unauthorized` {#repository-changes-fail-with-a-401-unauthorized-error}

Si vous exécutez Gitaly sur son propre serveur et constatez les conditions suivantes :

- Les utilisateurs peuvent cloner et récupérer des dépôts avec succès en utilisant SSH et HTTPS.
- Les utilisateurs ne peuvent pas pousser vers des dépôts, ou reçoivent un message `401 Unauthorized` lorsqu'ils tentent d'y apporter des modifications dans l'interface web.

Gitaly peut ne pas parvenir à s'authentifier auprès du client Gitaly car il possède le [mauvais fichier de secrets](configure_gitaly.md#configure-gitaly-servers).

Confirmez que tout ce qui suit est vrai :

- Lorsqu'un utilisateur effectue un `git push` vers n'importe quel dépôt sur ce serveur Gitaly, cela échoue avec une erreur `401 Unauthorized` :

  ```shell
  remote: GitLab: 401 Unauthorized
  To <REMOTE_URL>
  ! [remote rejected] branch-name -> branch-name (pre-receive hook declined)
  error: failed to push some refs to '<REMOTE_URL>'
  ```

- Lorsqu'un utilisateur ajoute ou modifie un fichier du dépôt via l'interface GitLab, cela échoue immédiatement avec une bannière rouge `401 Unauthorized`.
- La création d'un nouveau projet et son [initialisation avec un README](../../user/project/_index.md#create-a-blank-project) crée le projet avec succès mais ne crée pas le README.
- Lorsque vous [suivez les journaux](https://docs.gitlab.com/omnibus/settings/logs/#tail-logs-in-a-console-on-the-server) sur un client Gitaly et reproduisez l'erreur, vous obtenez des erreurs `401` en accédant à l'endpoint `/api/v4/internal/allowed` :

  ```shell
  # api_json.log
  {
    "time": "2019-07-18T00:30:14.967Z",
    "severity": "INFO",
    "duration": 0.57,
    "db": 0,
    "view": 0.57,
    "status": 401,
    "method": "POST",
    "path": "\/api\/v4\/internal\/allowed",
    "params": [
      {
        "key": "action",
        "value": "git-receive-pack"
      },
      {
        "key": "changes",
        "value": "REDACTED"
      },
      {
        "key": "gl_repository",
        "value": "REDACTED"
      },
      {
        "key": "project",
        "value": "\/path\/to\/project.git"
      },
      {
        "key": "protocol",
        "value": "web"
      },
      {
        "key": "env",
        "value": "{\"GIT_ALTERNATE_OBJECT_DIRECTORIES\":[],\"GIT_ALTERNATE_OBJECT_DIRECTORIES_RELATIVE\":[],\"GIT_OBJECT_DIRECTORY\":null,\"GIT_OBJECT_DIRECTORY_RELATIVE\":null}"
      },
      {
        "key": "user_id",
        "value": "2"
      },
      {
        "key": "secret_token",
        "value": "[FILTERED]"
      }
    ],
    "host": "gitlab.example.com",
    "ip": "REDACTED",
    "ua": "Ruby",
    "route": "\/api\/:version\/internal\/allowed",
    "queue_duration": 4.24,
    "gitaly_calls": 0,
    "gitaly_duration": 0,
    "correlation_id": "XPUZqTukaP3"
  }

  # nginx_access.log
  [IP] - - [18/Jul/2019:00:30:14 +0000] "POST /api/v4/internal/allowed HTTP/1.1" 401 30 "" "Ruby"
  ```

Pour résoudre ce problème, confirmez que votre [fichier `gitlab-secrets.json`](configure_gitaly.md#configure-gitaly-servers) sur le serveur Gitaly correspond à celui du client Gitaly. S'il ne correspond pas, mettez à jour le fichier de secrets sur le serveur Gitaly pour qu'il corresponde au client Gitaly, puis [reconfigurez](../restart_gitlab.md#reconfigure-a-linux-package-installation).

Si vous avez confirmé que votre fichier `gitlab-secrets.json` est identique sur tous les serveurs et clients Gitaly, l'application peut récupérer ce secret depuis un fichier différent. Le `config.toml file` de votre serveur Gitaly indique le fichier de secrets utilisé.

## Les push de dépôt échouent avec `401 Unauthorized` et `JWT::VerificationError` {#repository-pushes-fail-with-401-unauthorized-and-jwtverificationerror}

Lors d'une tentative de `git push`, vous pouvez voir :

- Des erreurs `401 Unauthorized`.
- Ce qui suit dans les journaux du serveur :

  ```json
  {
    ...
    "exception.class":"JWT::VerificationError",
    "exception.message":"Signature verification raised",
    ...
  }
  ```

Cette combinaison d'erreurs se produit lorsque le serveur GitLab a été mis à niveau vers GitLab 15.5 ou une version ultérieure, mais que Gitaly n'a pas encore été mis à niveau.

GitLab 15.5 et versions ultérieures [s'authentifient auprès de GitLab Shell à l'aide d'un jeton JWT au lieu d'un secret partagé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/86148). Vous devriez [mettre à niveau les serveurs Gitaly externes](../../update/plan_your_upgrade.md#upgrades-for-optional-features) avant de mettre à niveau le serveur GitLab.

## Les push de dépôt échouent avec une erreur `deny updating a hidden ref` {#repository-pushes-fail-with-a-deny-updating-a-hidden-ref-error}

Gitaly possède des références GitLab internes en lecture seule que les utilisateurs ne sont pas autorisés à mettre à jour. Si vous tentez de mettre à jour des références internes avec `git push --mirror`, Git retourne l'erreur de rejet `deny updating a hidden ref`.

Les références suivantes sont en lecture seule :

- refs/environments/
- refs/keep-around/
- refs/merge-requests/
- refs/pipelines/

Pour ne pousser en miroir que les branches et les tags, et éviter de tenter de pousser en miroir des refs protégés, exécutez :

```shell
git push --force-with-lease origin 'refs/heads/*:refs/heads/*' 'refs/tags/*:refs/tags/*'
```

Tout autre espace de nommage que l'administrateur souhaite pousser peut également être inclus via des [refspecs](https://git-scm.com/docs/git-push#_options) supplémentaires.

## Les outils en ligne de commande ne peuvent pas se connecter à Gitaly {#command-line-tools-cannot-connect-to-gitaly}

gRPC ne peut pas atteindre votre serveur Gitaly si :

- Vous ne pouvez pas vous connecter à un serveur Gitaly avec des outils en ligne de commande.
- Certaines actions produisent un message d'erreur `14: Connect Failed`.

Vérifiez que vous pouvez atteindre Gitaly en utilisant TCP :

```shell
sudo gitlab-rake gitlab:tcp_check[GITALY_SERVER_IP,GITALY_LISTEN_PORT]
```

Si la connexion TCP :

- Échoue, vérifiez vos paramètres réseau et vos règles de pare-feu.
- Réussit, vos paramètres réseau et vos règles de pare-feu sont corrects.

Si vous utilisez des serveurs proxy dans votre environnement en ligne de commande tel que Bash, ceux-ci peuvent interférer avec votre trafic gRPC.

Si vous utilisez Bash ou un environnement en ligne de commande compatible, exécutez les commandes suivantes pour déterminer si des serveurs proxy sont configurés :

```shell
echo $http_proxy
echo $https_proxy
```

Si l'une de ces variables a une valeur, vos connexions Gitaly CLI peuvent être acheminées via un proxy qui ne peut pas se connecter à Gitaly.

Pour supprimer le paramètre de proxy, exécutez les commandes suivantes (selon les variables qui avaient des valeurs) :

```shell
unset http_proxy
unset https_proxy
```

## Erreurs de permission refusée apparaissant dans les journaux Gitaly ou Praefect lors de l'accès aux dépôts {#permission-denied-errors-appearing-in-gitaly-or-praefect-logs-when-accessing-repositories}

Vous pouvez voir ce qui suit dans les journaux Gitaly et Praefect :

```shell
{
  ...
  "error":"rpc error: code = PermissionDenied desc = permission denied: token has expired",
  "grpc.code":"PermissionDenied",
  "grpc.meta.client_name":"gitlab-web",
  "grpc.request.fullMethod":"/gitaly.ServerService/ServerInfo",
  "level":"warning",
  "msg":"finished unary call with code PermissionDenied",
  ...
}
```

Ces informations dans les journaux sont un [code de réponse d'erreur](https://grpc.github.io/grpc/core/md_doc_statuscodes.html) d'appel gRPC.

Si cette erreur se produit, même si [les jetons d'authentification Gitaly sont correctement configurés](praefect/troubleshooting.md#praefect-errors-in-logs), il est probable que les serveurs Gitaly subissent une [dérive d'horloge](https://en.wikipedia.org/wiki/Clock_drift). Les jetons d'authentification envoyés à Gitaly incluent un horodatage. Pour être considéré comme valide, Gitaly exige que cet horodatage soit dans les 60 secondes de l'heure du serveur Gitaly.

Assurez-vous que les clients et les serveurs Gitaly sont synchronisés, et utilisez un serveur de temps NTP (Network Time Protocol) pour les maintenir synchronisés.

## Gitaly n'écoute pas sur la nouvelle adresse après reconfiguration {#gitaly-not-listening-on-new-address-after-reconfiguring}

Lors de la mise à jour des valeurs `gitaly['configuration'][:listen_addr]` ou `gitaly['configuration'][:prometheus_listen_addr]`, Gitaly peut continuer à écouter sur l'ancienne adresse après un `sudo gitlab-ctl reconfigure`.

Lorsque cela se produit, exécutez `sudo gitlab-ctl restart` pour résoudre le problème. Cela ne devrait plus être nécessaire car [ce problème](https://gitlab.com/gitlab-org/gitaly/-/issues/2521) est résolu.

## Avertissements de vérification de l'état {#health-check-warnings}

L'avertissement suivant dans `/var/log/gitlab/praefect/current` peut être ignoré.

```plaintext
"error":"full method name not found: /grpc.health.v1.Health/Check",
"msg":"error when looking up method info"
```

## Erreurs de fichier introuvable {#file-not-found-errors}

Les erreurs suivantes dans `/var/log/gitlab/gitaly/current` peuvent être ignorées. Elles sont causées par l'application GitLab Rails qui vérifie l'existence de fichiers spécifiques qui n'existent pas dans un dépôt.

```plaintext
"error":"not found: .gitlab/route-map.yml"
"error":"not found: Dockerfile"
"error":"not found: .gitlab-ci.yml"
```

## Les push Git sont lents lorsque Dynatrace est activé {#git-pushes-are-slow-when-dynatrace-is-enabled}

Dynatrace peut provoquer un délai de plusieurs secondes au démarrage et à l'arrêt du hook de transaction de référence `sudo -u git -- /opt/gitlab/embedded/bin/gitaly-hooks`. `gitaly-hooks` est exécuté deux fois lorsque les utilisateurs poussent, ce qui entraîne un délai significatif.

Dynatrace semble instrumenter les binaires en chargeant dynamiquement un fichier `.so`, ce qui contribue aux mauvaises performances des processus `gitaly-hooks` à durée de vie relativement courte.

Si les push Git sont trop lents lorsque Dynatrace est activé, désactivez Dynatrace. Vous devrez peut-être supprimer complètement Dynatrace du système sur lequel Gitaly s'exécute pour empêcher le chargement du fichier `.so`.

## `gitaly check` échoue avec le code de statut `401` {#gitaly-check-fails-with-401-status-code}

`gitaly check` peut échouer avec le code de statut `401` si Gitaly ne peut pas accéder à l'API GitLab interne.

Une façon de résoudre ce problème est de s'assurer que l'entrée est correcte pour l'URL de l'API interne GitLab configurée dans `gitlab.rb` avec `gitlab_rails['internal_api_url']`.

## Les modifications (diffs) ne se chargent pas pour les nouvelles merge requests lors de l'utilisation de Gitaly TLS {#changes-diffs-dont-load-for-new-merge-requests-when-using-gitaly-tls}

Après l'activation de [Gitaly avec TLS](tls_support.md), les modifications (diffs) pour les nouvelles merge requests ne sont pas générées et vous voyez le message suivant dans GitLab :

```plaintext
Building your merge request... This page will update when the build is complete
```

Gitaly doit pouvoir se connecter à lui-même pour effectuer certaines opérations. Si le certificat Gitaly n'est pas approuvé par le serveur Gitaly, les diffs de merge request ne peuvent pas être générés.

Si Gitaly ne peut pas se connecter à lui-même, vous verrez des messages dans les [journaux Gitaly](../logs/_index.md#gitaly-logs) similaires aux messages suivants :

```json
{
   "level":"warning",
   "msg":"[core] [Channel #16 SubChannel #17] grpc: addrConn.createTransport failed to connect to {Addr: \"ext-gitaly.example.com:9999\", ServerName: \"ext-gitaly.example.com:9999\", }. Err: connection error: desc = \"transport: authentication handshake failed: tls: failed to verify certificate: x509: certificate signed by unknown authority\"",
   "pid":820,
   "system":"system",
   "time":"2023-11-06T05:40:04.169Z"
}
{
   "level":"info",
   "msg":"[core] [Server #3] grpc: Server.Serve failed to create ServerTransport: connection error: desc = \"ServerHandshake(\\\"x.x.x.x:x\\\") failed: wrapped server handshake: remote error: tls: bad certificate\"",
   "pid":820,
   "system":"system",
   "time":"2023-11-06T05:40:04.169Z"
}
```

Pour résoudre le problème, assurez-vous d'avoir ajouté votre certificat Gitaly dans le dossier `/etc/gitlab/trusted-certs` sur le serveur Gitaly et :

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) afin que les certificats soient liés symboliquement
1. Redémarrez Gitaly manuellement `sudo gitlab-ctl restart gitaly` pour que les certificats soient chargés par le processus Gitaly.

## Gitaly ne parvient pas à dupliquer les processus stockés sur des systèmes de fichiers `noexec` {#gitaly-fails-to-fork-processes-stored-on-noexec-file-systems}

L'application de l'option `noexec` à un point de montage (par exemple, `/var`) entraîne des erreurs `permission denied` de la part de Gitaly, liées au fork de processus. Par exemple :

```shell
fork/exec /var/opt/gitlab/gitaly/run/gitaly-2057/gitaly-git2go: permission denied
```

Pour résoudre ce problème, supprimez l'option `noexec` du montage du système de fichiers. Une alternative consiste à modifier le répertoire d'exécution de Gitaly :

1. Ajoutez `gitaly['runtime_dir'] = '<PATH_WITH_EXEC_PERM>'` à `/etc/gitlab/gitlab.rb` et spécifiez un emplacement sans `noexec` défini.
1. Exécutez `sudo gitlab-ctl reconfigure`.

## La signature des commits échoue avec `invalid argument` ou `invalid data` {#commit-signing-fails-with-invalid-argument-or-invalid-data}

Si la signature des commits échoue avec l'une de ces erreurs :

- `invalid argument: signing key is encrypted`
- `invalid data: tag byte does not have MSB set`

Cette erreur se produit parce que la signature des commits Gitaly est sans interface utilisateur et n'est pas associée à un utilisateur spécifique. La clé de signature GPG doit être créée sans phrase secrète, ou la phrase secrète doit être supprimée avant l'exportation.

## Les journaux Gitaly affichent des erreurs dans les messages `info` {#gitaly-logs-show-errors-in-info-messages}

En raison d'un bug [introduit](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6201) dans GitLab 16.3, des entrées supplémentaires ont été écrites dans les [journaux Gitaly](../logs/_index.md#gitaly-logs). Ces entrées de journal contenaient `"level":"info"` mais la chaîne `msg` semblait contenir une erreur.

Par exemple :

```json
{"level":"info","msg":"[core] [Server #3] grpc: Server.Serve failed to create ServerTransport: connection error: desc = \"ServerHandshake(\\\"x.x.x.x:x\\\") failed: wrapped server handshake: EOF\"","pid":6145,"system":"system","time":"2023-12-14T21:20:39.999Z"}
```

La raison de cette entrée de journal est que la bibliothèque gRPC sous-jacente génère parfois des journaux de transport volumineux. Ces entrées de journal semblent être des erreurs mais peuvent, en général, être ignorées.

Ce bug a été [corrigé](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/6513/) dans GitLab 16.4.5, 16.5.5 et 16.6.0, ce qui empêche ces types de messages d'être écrits dans les journaux Gitaly.

## Profilage de Gitaly {#profiling-gitaly}

Gitaly expose plusieurs outils de profilage des performances intégrés à Go sur le port d'écoute Prometheus. Par exemple, si Prometheus écoute sur le port `9236` du serveur GitLab :

- Obtenez une liste des `goroutines` en cours d'exécution et leurs traces de pile :

  ```shell
  curl --output goroutines.txt "http://<gitaly_server>:9236/debug/pprof/goroutine?debug=2"
  ```

- Exécutez un profil CPU pendant 30 secondes :

  ```shell
  curl --output cpu.bin "http://<gitaly_server>:9236/debug/pprof/profile"
  ```

- Profilez l'utilisation de la mémoire heap :

  ```shell
  curl --output heap.bin "http://<gitaly_server>:9236/debug/pprof/heap"
  ```

- Enregistrez une trace d'exécution de 5 secondes. Cela impacte les performances de Gitaly pendant l'exécution :

  ```shell
  curl --output trace.bin "http://<gitaly_server>:9236/debug/pprof/trace?seconds=5"
  ```

Sur un hôte avec `go` installé, le profil CPU et le profil heap peuvent être visualisés dans un navigateur :

```shell
go tool pprof -http=:8001 cpu.bin
go tool pprof -http=:8001 heap.bin
```

Les traces d'exécution peuvent être visualisées en exécutant :

```shell
go tool trace heap.bin
```

### Profiler les opérations Git {#profile-git-operations}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitaly/-/issues/5700) dans GitLab 16.9 [avec un flag](../feature_flags/_index.md) nommé `log_git_traces`. Désactivé par défaut.

{{< /history >}}

> [!flag]
> Sur GitLab Self-Managed, cette fonctionnalité n'est pas disponible par défaut. Pour la rendre disponible, un administrateur peut [activer le feature flag](../feature_flags/_index.md) nommé `log_git_traces`. Sur GitLab.com, cette fonctionnalité est disponible mais peut uniquement être configurée par les administrateurs de GitLab.com. Sur GitLab Dedicated, cette fonctionnalité n'est pas disponible.

Vous pouvez profiler les opérations Git effectuées par Gitaly en envoyant des informations supplémentaires sur les opérations Git aux journaux Gitaly. Grâce à ces informations, les utilisateurs ont une meilleure visibilité pour l'optimisation des performances, le débogage et la collecte générale de télémétrie. Pour plus d'informations, consultez la [référence de l'API Git Trace2](https://git-scm.com/docs/api-trace2).

Pour éviter une surcharge du système, la journalisation des informations supplémentaires est soumise à une limite de débit. Si la limite de débit est dépassée, les traces sont ignorées. Cependant, une fois que le débit revient à un état normal, les traces sont à nouveau traitées automatiquement. La limitation du débit garantit que le système reste stable et évite tout impact négatif dû à un traitement excessif des traces.

## Les dépôts apparaissent vides après une restauration GitLab {#repositories-are-shown-as-empty-after-a-gitlab-restore}

Lors de l'utilisation de `fapolicyd` pour une sécurité accrue, GitLab peut indiquer qu'une restauration depuis un fichier de sauvegarde GitLab a réussi, mais :

- Les dépôts apparaissent vides.
- La création de nouveaux fichiers entraîne une erreur similaire à :

  ```plaintext
  13:commit: commit: starting process [/var/opt/gitlab/gitaly/run/gitaly-5428/gitaly-git2go -log-format json -log-level -correlation-id
  01GP1383JV6JD6MQJBH2E1RT03 -enabled-feature-flags -disabled-feature-flags commit]: fork/exec /var/opt/gitlab/gitaly/run/gitaly-5428/gitaly-git2go: operation not permitted.
  ```

- Les journaux Gitaly peuvent contenir des erreurs similaires à :

  ```plaintext
   "error": "exit status 128, stderr: \"fatal: cannot exec '/var/opt/gitlab/gitaly/run/gitaly-5428/hooks-1277154941.d/reference-transaction':

    Operation not permitted\\nfatal: cannot exec '/var/opt/gitlab/gitaly/run/gitaly-5428/hooks-1277154941.d/reference-transaction': Operation
    not permitted\\nfatal: ref updates aborted by hook\\n\"",
   "grpc.code": "Internal",
   "grpc.meta.deadline_type": "none",
   "grpc.meta.method_type": "client_stream",
   "grpc.method": "FetchBundle",
   "grpc.request.fullMethod": "/gitaly.RepositoryService/FetchBundle",
  ...
  ```

Vous pouvez utiliser le [mode débogage](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/security_hardening/assembly_blocking-and-allowing-applications-using-fapolicyd_security-hardening#ref_troubleshooting-problems-related-to-fapolicyd_assembly_blocking-and-allowing-applications-using-fapolicyd) pour déterminer si `fapolicyd` refuse l'exécution en fonction des règles actuelles.

Si vous constatez que `fapolicyd` refuse l'exécution, tenez compte des points suivants :

1. Autorisez tous les exécutables dans `/var/opt/gitlab/gitaly` dans votre configuration `fapolicyd` :

   ```plaintext
   allow perm=any all : ftype=application/x-executable dir=/var/opt/gitlab/gitaly/
   ```

1. Redémarrez les services :

   ```shell
   sudo systemctl restart fapolicyd

   sudo gitlab-ctl restart gitaly
   ```

## Erreur `Pre-receive hook declined` lors du push vers une instance RHEL avec `fapolicyd` activé {#pre-receive-hook-declined-error-when-pushing-to-rhel-instance-with-fapolicyd-enabled}

Lors d'un push vers une instance basée sur RHEL avec `fapolicyd` activé, vous pouvez obtenir une erreur `Pre-receive hook declined`. Cette erreur peut se produire parce que `fapolicyd` peut bloquer l'exécution du binaire Gitaly. Pour résoudre ce problème, vous pouvez soit :

- Désactiver `fapolicyd`.
- Créer une règle `fapolicyd` pour autoriser l'exécution des binaires Gitaly avec `fapolicyd` activé.

Pour créer une règle autorisant l'exécution des binaires Gitaly :

1. Créez un fichier à l'emplacement `/etc/fapolicyd/rules.d/89-gitlab.rules`.
1. Saisissez ce qui suit dans le fichier :

   ```plaintext
   allow perm=any all : ftype=application/x-executable dir=/var/opt/gitlab/gitaly/
   ```

1. Redémarrez le service :

   ```shell
   systemctl restart fapolicyd
   ```

La nouvelle règle prend effet après le redémarrage du démon.

## Mettre à jour les dépôts après la suppression d'un stockage avec un chemin en double {#update-repositories-after-removing-a-storage-with-a-duplicate-path}

{{< history >}}

- Tâche Rake `gitlab:gitaly:update_removed_storage_projects` [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153008) dans GitLab 17.1.

{{< /history >}}

Dans GitLab 17.0, la prise en charge de la configuration des stockages avec des chemins en double [a été supprimée](https://gitlab.com/gitlab-org/gitaly/-/issues/5598). Cela peut signifier que vous devez supprimer la configuration de stockage en double de la configuration `gitaly`.

> [!warning]
> N'utilisez cette tâche Rake que lorsque les anciens et nouveaux stockages partagent le même chemin de disque sur le même serveur Gitaly. L'utilisation de cette tâche Rake dans toute autre situation rend le dépôt indisponible. Utilisez l'[API de déplacement du stockage du dépôt de projet](../../api/project_repository_storage_moves.md) pour transférer des projets entre des stockages dans toutes les autres situations.

Lors de la suppression de la configuration Gitaly d'un stockage qui utilisait le même chemin qu'un autre stockage, les projets associés à l'ancien stockage doivent être réassignés au nouveau.

Par exemple, vous pourriez avoir une configuration similaire à la suivante :

```ruby
gitaly['configuration'] = {
  storage: [
    {
       name: 'default',
       path: '/var/opt/gitlab/git-data/repositories',
    },
    {
       name: 'duplicate-path',
       path: '/var/opt/gitlab/git-data/repositories',
    },
  ],
}
```

Si vous supprimiez `duplicate-path` de la configuration, vous exécuteriez la tâche Rake suivante pour associer tous les projets qui lui sont assignés à `default` à la place :

{{< tabs >}}

{{< tab title="Linux package installations" >}}

```shell
sudo gitlab-rake "gitlab:gitaly:update_removed_storage_projects[duplicate-path, default]"
```

{{< /tab >}}

{{< tab title="Self-compiled installations" >}}

```shell
sudo -u git -H bundle exec rake "gitlab:gitaly:update_removed_storage_projects[duplicate-path, default]" RAILS_ENV=production
```

{{< /tab >}}

{{< /tabs >}}

## Erreur : `fatal: deflate error (0)\n` lors du téléchargement d'un dépôt en tant que fichier ZIP {#error-fatal-deflate-error-0n-when-downloading-repository-as-zip-file}

En raison d'un bug Git ([ticket 575](https://gitlab.com/gitlab-org/git/-/issues/575)) corrigé dans la version 2.51 de Git, le téléchargement d'un dépôt en tant qu'archive ZIP produit dans certains cas un fichier ZIP incomplet. Lorsque cela se produit, les journaux Gitaly affichent l'erreur suivante :

```plaintext
  "msg": "fatal: deflate error (0)\n",
```

Pour résoudre ce problème, mettez à niveau vers une version de GitLab et Gitaly qui utilise une version corrigée de Git. Si vous ne pouvez pas mettre à niveau, utilisez ces étapes pour contourner le problème :

{{< tabs >}}

{{< tab title="Linux package installations" >}}

1. Vérifiez la taille de vos blobs en utilisant [`git-sizer`](https://github.com/github/git-sizer#getting-started).
1. Configurez `core.bigFileThreshold` pour qu'il soit supérieur à la taille du blob le plus grand (la valeur par défaut est `50m`) :

   ```ruby
     gitaly['configuration'] = {
      # ... your existing configuration ...
      git: {
        config: [
          # ... any existing git config entries ...
          {
            key: 'core.bigFileThreshold',
            value: '500m'
          }
        ]
      }
    }
   ```

1. Exécutez `gitlab-ctl reconfigure`.

{{< /tab >}}

{{< tab title="Helm chart (Kubernetes)" >}}

1. Vérifiez la taille de vos blobs en utilisant [`git-sizer`](https://github.com/github/git-sizer#getting-started).
1. Configurez `core.bigFileThreshold` dans votre fichier `values.yml` :

   ```yaml
   git:
     config:
       - key: "core.bigFileThreshold"
         value: "500m"
   ```

1. Pour mettre à jour la configuration, exécutez `helm upgrade <gitlab_release> gitlab/gitlab -f values.yaml`.

{{< /tab >}}

{{< tab title="Self-compiled installations" >}}

1. Vérifiez la taille de vos blobs en utilisant [`git-sizer`](https://github.com/github/git-sizer#getting-started).
1. Configurez `core.bigFileThreshold` dans `/home/git/gitaly/config.toml` :

   ```toml
   # [[git.config]]
   # key = core.bigFileThreshold
   # value = 500m
   ```

{{< /tab >}}

{{< /tabs >}}
