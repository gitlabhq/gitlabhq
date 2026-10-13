---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Dépannage de l'agent GitLab pour Kubernetes"
---

Lorsque vous utilisez l'agent GitLab pour Kubernetes, vous pouvez rencontrer des problèmes nécessitant un dépannage.

Vous pouvez commencer par consulter les logs du service :

```shell
kubectl logs -f -l=app.kubernetes.io/name=gitlab-agent -n gitlab-agent
```

Si vous êtes administrateur GitLab, vous pouvez également consulter les [logs du serveur de l'agent GitLab pour Kubernetes](../../../administration/clusters/kas.md#troubleshooting).

## Transport : Error while dialing failed to WebSocket dial {#transport-error-while-dialing-failed-to-websocket-dial}

```json
{
  "level": "warn",
  "time": "2020-11-04T10:14:39.368Z",
  "msg": "GetConfiguration failed",
  "error": "rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing failed to WebSocket dial: failed to send handshake request: Get \\\"https://gitlab-kas:443/-/kubernetes-agent\\\": dial tcp: lookup gitlab-kas on 10.60.0.10:53: no such host\""
}
```

Cette erreur se produit en cas de problèmes de connectivité entre `kas-address` et le pod de votre agent. Pour résoudre ce problème, assurez-vous que `kas-address` est correct.

```json
{
  "level": "error",
  "time": "2021-06-25T21:15:45.335Z",
  "msg": "Reverse tunnel",
  "mod_name": "reverse_tunnel",
  "error": "Connect(): rpc error: code = Unavailable desc = connection error: desc= \"transport: Error while dialing failed to WebSocket dial: expected handshake response status code 101 but got 301\""
}
```

Cette erreur se produit lorsque `kas-address` ne contient pas de barre oblique finale. Pour résoudre ce problème, assurez-vous que l'URL `wss` ou `ws` se termine par une barre oblique finale, comme `wss://GitLab.host.tld:443/-/kubernetes-agent/` ou `ws://GitLab.host.tld:80/-/kubernetes-agent/`.

## Error while dialing failed to WebSocket dial: failed to send handshake request {#error-while-dialing-failed-to-websocket-dial-failed-to-send-handshake-request}

```json
{
  "level": "warn",
  "time": "2020-10-30T09:50:51.173Z",
  "msg": "GetConfiguration failed",
  "error": "rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing failed to WebSocket dial: failed to send handshake request: Get \\\"https://GitLabhost.tld:443/-/kubernetes-agent\\\": net/http: HTTP/1.x transport connection broken: malformed HTTP response \\\"\\\\x00\\\\x00\\\\x06\\\\x04\\\\x00\\\\x00\\\\x00\\\\x00\\\\x00\\\\x00\\\\x05\\\\x00\\\\x00@\\\\x00\\\"\""
}
```

Cette erreur se produit lorsque vous avez configuré `wss` comme `kas-address` côté agent, mais que le serveur de l'agent n'est pas disponible sur `wss`. Pour résoudre ce problème, assurez-vous que les mêmes schémas sont configurés des deux côtés.

## Decompressor is not installed for grpc-encoding {#decompressor-is-not-installed-for-grpc-encoding}

```json
{
  "level": "warn",
  "time": "2020-11-05T05:25:46.916Z",
  "msg": "GetConfiguration.Recv failed",
  "error": "rpc error: code = Unimplemented desc = grpc: Decompressor is not installed for grpc-encoding \"gzip\""
}
```

Cette erreur se produit lorsque la version de l'agent est plus récente que la version du serveur de l'agent (KAS). Pour résoudre ce problème, assurez-vous que `agentk` et le serveur de l'agent sont à la même version.

## Certificate signed by unknown authority {#certificate-signed-by-unknown-authority}

```json
{
  "level": "error",
  "time": "2021-02-25T07:22:37.158Z",
  "msg": "Reverse tunnel",
  "mod_name": "reverse_tunnel",
  "error": "Connect(): rpc error: code = Unavailable desc = connection error: desc = \"transport: Error while dialing failed to WebSocket dial: failed to send handshake request: Get \\\"https://GitLabhost.tld:443/-/kubernetes-agent/\\\": x509: certificate signed by unknown authority\""
}
```

Cette erreur se produit lorsque votre instance GitLab utilise un certificat signé par une autorité de certification interne inconnue de l'agent.

Pour résoudre ce problème, vous pouvez présenter le fichier de certificat CA à l'agent en [personnalisant l'installation Helm](install/_index.md#customize-the-helm-installation). Ajoutez `--set-file config.kasCaCert=my-custom-ca.pem` à la commande `helm install`. Le fichier doit être un certificat valide encodé en PEM ou en DER.

Lorsque vous déployez `agentk` avec une valeur `config.kasCaCert` définie, le certificat est ajouté à `configmap` et le fichier de certificat est monté dans `/etc/ssl/certs`.

Par exemple, avec la commande `kubectl get configmap -lapp=gitlab-agent -o yaml` :

```yaml
apiVersion: v1
items:
- apiVersion: v1
  data:
    ca.crt: |-
      -----BEGIN CERTIFICATE-----
      MIIFmzCCA4OgAwIBAgIUE+FvXfDpJ869UgJitjRX7HHT84cwDQYJKoZIhvcNAQEL
      ...truncated certificate...
      GHZCTQkbQyUwBWJOUyOxW1lro4hWqtP4xLj8Dpq1jfopH72h0qTGkX0XhFGiSaM=
      -----END CERTIFICATE-----
  kind: ConfigMap
  metadata:
    annotations:
      meta.helm.sh/release-name: self-signed
      meta.helm.sh/release-namespace: gitlab-agent-self-signed
    creationTimestamp: "2023-03-07T20:12:26Z"
    labels:
      app: gitlab-agent
      app.kubernetes.io/managed-by: Helm
      app.kubernetes.io/name: gitlab-agent
      app.kubernetes.io/version: v15.9.0
      helm.sh/chart: gitlab-agent-1.11.0
    name: self-signed-gitlab-agent
    resourceVersion: "263184207"
kind: List
```

Vous pourriez voir une erreur similaire dans les [logs du serveur de l'agent (KAS)](../../../administration/logs/_index.md#gitlab-agent-server-for-kubernetes-logs) de votre serveur d'application GitLab :

```json
{"level":"error","time":"2023-03-07T20:19:48.151Z","msg":"AgentInfo()","grpc_service":"gitlab.agent.agent_configuration.rpc.AgentConfiguration","grpc_method":"GetConfiguration","error":"Get \"https://gitlab.example.com/api/v4/internal/kubernetes/agent_info\": x509: certificate signed by unknown authority"}
```

Pour résoudre ce problème, [installez le certificat public de votre CA interne](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates) dans le répertoire `/etc/gitlab/trusted-certs`.

Vous pouvez également configurer le serveur de l'agent (KAS) pour lire le certificat depuis un répertoire personnalisé. Ajoutez la configuration suivante à `/etc/gitlab/gitlab.rb` :

```ruby
gitlab_kas['env'] = {
   'SSL_CERT_DIR' => "/opt/gitlab/embedded/ssl/certs/"
 }
```

Pour appliquer les modifications :

1. Reconfigurer GitLab.

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Redémarrez `gitlab-kas`.

   ```shell
   gitlab-ctl restart gitlab-kas
   ```

## Erreur : `Failed to register agent pod` {#error-failed-to-register-agent-pod}

Les logs du pod de l'agent peuvent afficher le message d'erreur `Failed to register agent pod. Please make sure the agent version matches the server version`.

Pour résoudre ce problème, assurez-vous que la version de l'agent correspond à la version de GitLab.

Si les versions correspondent et que l'erreur persiste :

1. Assurez-vous que `gitlab-kas` est en cours d'exécution avec `gitlab-ctl status gitlab-kas`.
1. Consultez les [logs](../../../administration/logs/_index.md#gitlab-agent-server-for-kubernetes-logs) de `gitlab-kas` pour vous assurer que l'agent fonctionne correctement.

## Failed to perform vulnerability scan on workload: jobs.batch already exists {#failed-to-perform-vulnerability-scan-on-workload-jobsbatch-already-exists}

```json
{
  "level": "error",
  "time": "2022-06-22T21:03:04.769Z",
  "msg": "Failed to perform vulnerability scan on workload",
  "mod_name": "starboard_vulnerability",
  "error": "running scan job: creating job: jobs.batch \"scan-vulnerabilityreport-b8d497769\" already exists"
}
```

L'agent GitLab pour Kubernetes effectue des analyses de vulnérabilités en créant un job pour analyser chaque workload. Si une analyse est interrompue, ces jobs peuvent être laissés en place et doivent être supprimés avant que d'autres jobs puissent être exécutés. Vous pouvez supprimer ces jobs en exécutant :

```shell
kubectl delete jobs -l app.kubernetes.io/managed-by=starboard -n gitlab-agent
```

[Nous travaillons à rendre le nettoyage de ces jobs plus robuste.](https://gitlab.com/gitlab-org/gitlab/-/issues/362016)

## Erreur d'analyse lors de l'installation {#parse-error-during-installation}

Lorsque vous installez l'agent, vous pouvez rencontrer une erreur indiquant :

```shell
Error: parse error at (gitlab-agent/templates/observability-secret.yaml:1): unclosed action
```

Cette erreur est généralement causée par une version incompatible de Helm. Pour résoudre ce problème, assurez-vous d'utiliser une version de Helm [compatible avec votre version de Kubernetes](_index.md#supported-kubernetes-versions-for-gitlab-features).

## `GitLab Agent Server: Unauthorized` erreur sur le tableau de bord pour Kubernetes {#gitlab-agent-server-unauthorized-error-on-dashboard-for-kubernetes}

Une erreur comme `GitLab Agent Server: Unauthorized. Trace ID: <...>` sur la page [Tableau de bord pour Kubernetes](../../../ci/environments/kubernetes_dashboard.md) peut être causée par l'un des éléments suivants :

- L'entrée `user_access` dans le fichier de configuration de l'agent n'existe pas ou est incorrecte. Pour résoudre ce problème, consultez [Accorder aux utilisateurs l'accès à Kubernetes](user_access.md).
- Il y a plusieurs [cookies `_gitlab_kas`](../../../administration/clusters/kas.md#kubernetes-api-proxy-cookie) dans le navigateur qui sont envoyés à KAS. La cause la plus probable est la présence de plusieurs instances GitLab hébergées sur le même site.

  Par exemple, `gitlab.com` définit un cookie `_gitlab_kas` ciblant `kas.gitlab.com`, mais le cookie est également envoyé à `kas.staging.gitlab.com`, ce qui provoque l'erreur sur `staging.gitlab.com`.

  Pour résoudre temporairement ce problème, supprimez le cookie `_gitlab_kas` pour `gitlab.com` dans le magasin de cookies du navigateur. [Le ticket 418998](https://gitlab.com/gitlab-org/gitlab/-/issues/418998) propose une correction pour ce problème connu.
- GitLab et KAS s'exécutent sur des sites différents. Par exemple, GitLab sur `gitlab.example.com` et KAS sur `kas.example.com`. GitLab ne prend pas en charge ce cas d'utilisation. Pour plus de détails, consultez le [ticket 416436](https://gitlab.com/gitlab-org/gitlab/-/issues/416436).

## Incompatibilité de version de l'agent {#agent-version-mismatch}

Dans GitLab, sur l'onglet **Agent** de la page des clusters Kubernetes, vous pourriez voir un avertissement indiquant `Agent version mismatch: The agent versions do not match each other across your cluster's pods.`

Cet avertissement peut être causé par une version plus ancienne de l'agent mise en cache par le serveur de l'agent pour Kubernetes (`kas`). Étant donné que `kas` supprime régulièrement les versions obsolètes de l'agent, vous devriez attendre au moins 20 minutes pour que l'agent et GitLab se synchronisent.

Si l'avertissement persiste, mettez à jour l'agent installé sur votre cluster.

## Les en-têtes de réponse du proxy de l'API Kubernetes sont perdus ou bloqués {#kubernetes-api-proxy-response-headers-are-lost-or-blocked}

Les en-têtes de réponse HTTP peuvent être bloqués lorsqu'ils sont envoyés depuis le cluster Kubernetes vers l'utilisateur via le proxy de l'API Kubernetes.

Cette erreur se produit probablement lorsqu'un en-tête de réponse n'est pas inclus dans la liste d'autorisation par défaut pour KAS.

Pour connaître les étapes permettant de résoudre ce problème, consultez [en-têtes de réponse bloqués](../../../administration/clusters/kas.md#error-blocked-kubernetes-api-proxy-response-header).
