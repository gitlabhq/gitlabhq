---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Installer GitLab Relay (KAS)
description: Gérer GitLab Relay (KAS).
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab Relay (KAS) est un composant installé avec GitLab. Il sert de relais de communication central pour la communication gRPC bidirectionnelle entre GitLab et les systèmes externes, notamment :

- Runners : Requis pour utiliser le [Job Router](../../ci/runners/job_router/_index.md) et les [Runner Controllers](../../ci/runners/job_router/runner_controllers.md).
- Clusters Kubernetes : Requis pour utiliser l'[Agent for Kubernetes](../../user/clusters/agent/_index.md).

KAS était anciennement connu sous le nom de Kubernetes Agent Server. Le nom a été modifié pour refléter son rôle élargi au-delà de Kubernetes.

GitLab Relay (KAS) est installé et disponible sur GitLab.com à l'adresse `wss://kas.gitlab.com`. Si vous utilisez GitLab Self-Managed, GitLab Relay (KAS) est installé et disponible par défaut.

## Options d'installation {#installation-options}

En tant qu'administrateur GitLab, vous pouvez contrôler l'installation de GitLab Relay (KAS) :

- Pour les [installations de package Linux](#for-linux-package-installations).
- Pour les [installations GitLab Helm chart](#for-gitlab-helm-chart).

### Pour les installations de package Linux {#for-linux-package-installations}

GitLab Relay (KAS) pour les installations de package Linux peut être activé sur un seul nœud ou sur plusieurs nœuds à la fois. Par défaut, GitLab Relay (KAS) est activé et disponible à l'adresse `ws://gitlab.example.com/-/kubernetes-agent/`.

#### Désactiver sur un seul nœud {#disable-on-a-single-node}

Pour désactiver GitLab Relay (KAS) sur un seul nœud :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_kas['enable'] = false
   ```

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

#### Activer KAS sur plusieurs nœuds {#turn-on-kas-on-multiple-nodes}

Les instances KAS communiquent entre elles en enregistrant leurs adresses privées dans Redis à un emplacement bien connu. Chaque KAS doit être configuré pour présenter les détails de son adresse privée afin que les autres instances puissent l'atteindre.

Pour activer KAS sur plusieurs nœuds :

1. Ajoutez la [configuration commune](#common-configuration).
1. Ajoutez la configuration à partir de l'une des options suivantes :

   - [Option 1 - configuration manuelle explicite](#option-1---explicit-manual-configuration)
   - [Option 2 - configuration automatique basée sur CIDR](#option-2---automatic-cidr-based-configuration)
   - [Option 3 - configuration automatique basée sur la configuration du listener](#option-3---automatic-configuration-based-on-listener-configuration)

1. [Reconfigurer GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).
1. (Facultatif) Si vous utilisez un environnement multi-serveurs avec des nœuds GitLab Rails et Sidekiq séparés, activez KAS sur les nœuds Sidekiq.

##### Configuration commune {#common-configuration}

Pour chaque nœud KAS, modifiez le fichier situé à `/etc/gitlab/gitlab.rb` et ajoutez la configuration suivante :

```ruby
gitlab_kas_external_url 'wss://kas.gitlab.example.com/'

gitlab_kas['api_secret_key'] = '<32_bytes_long_base64_encoded_value>'
gitlab_kas['private_api_secret_key'] = '<32_bytes_long_base64_encoded_value>'

# private_api_listen_address examples, pick one:

gitlab_kas['private_api_listen_address'] = 'A.B.C.D:8155' # Listen on a particular IPv4. Each node must use its own unique IP.
# gitlab_kas['private_api_listen_address'] = '[A:B:C::D]:8155' # Listen on a particular IPv6. Each node must use its own unique IP.
# gitlab_kas['private_api_listen_address'] = 'kas-N.gitlab.example.com:8155' # Listen on all IPv4 and IPv6 interfaces that the DNS name resolves to. Each node must use its own unique domain.
# gitlab_kas['private_api_listen_address'] = ':8155' # Listen on all IPv4 and IPv6 interfaces.
# gitlab_kas['private_api_listen_address'] = '0.0.0.0:8155' # Listen on all IPv4 interfaces.
# gitlab_kas['private_api_listen_address'] = '[::]:8155' # Listen on all IPv6 interfaces.

# Uncomment below to enable KAS to KAS TLS communication
# gitlab_kas['private_api_certificate_file'] = '<path_to_kas_server_crt_file>'
# gitlab_kas['private_api_key_file'] = '<path_to_kas_server_certificate_key>'

gitlab_kas['env'] = {
  # 'OWN_PRIVATE_API_HOST' => '<server-name-from-cert>' # Add if you want to use TLS for KAS->KAS communication. This name is used to verify the TLS certificate host name instead of the host in the URL of the destination KAS.
  'SSL_CERT_DIR' => "/opt/gitlab/embedded/ssl/certs/",
}

gitlab_rails['gitlab_kas_external_url'] = 'wss://gitlab.example.com/-/kubernetes-agent/'
gitlab_rails['gitlab_kas_internal_url'] = 'grpc://kas.internal.gitlab.example.com'
gitlab_rails['gitlab_kas_external_k8s_proxy_url'] = 'https://gitlab.example.com/-/kubernetes-agent/k8s-proxy/'
```

**Do not** `private_api_listen_address` pour écouter sur une adresse interne, telle que :

- `localhost`
- Adresses IP de bouclage (loopback), comme `127.0.0.1` ou `::1`
- Un socket UNIX

Les autres nœuds KAS ne peuvent pas atteindre ces adresses.

Pour les configurations à nœud unique, vous pouvez définir `private_api_listen_address` pour écouter sur une adresse interne.

##### Option 1 - configuration manuelle explicite {#option-1---explicit-manual-configuration}

Pour chaque nœud KAS, modifiez le fichier situé à `/etc/gitlab/gitlab.rb` et définissez explicitement la variable d'environnement `OWN_PRIVATE_API_URL` :

```ruby
gitlab_kas['env'] = {
  # OWN_PRIVATE_API_URL examples, pick one. Each node must use its own unique IP or DNS name.
  # Use grpcs:// when using TLS on the private API endpoint.

  'OWN_PRIVATE_API_URL' => 'grpc://A.B.C.D:8155' # IPv4
  # 'OWN_PRIVATE_API_URL' => 'grpcs://A.B.C.D:8155' # IPv4 + TLS
  # 'OWN_PRIVATE_API_URL' => 'grpc://[A:B:C::D]:8155' # IPv6
  # 'OWN_PRIVATE_API_URL' => 'grpc://kas-N-private-api.gitlab.example.com:8155' # DNS name
}
```

##### Option 2 - configuration automatique basée sur CIDR {#option-2---automatic-cidr-based-configuration}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/464) dans GitLab 16.5.0.
- [Ajout](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/merge_requests/2183) de la prise en charge de plusieurs CIDR à `OWN_PRIVATE_API_CIDR` dans GitLab 17.8.1.

{{< /history >}}

Il est possible que vous ne puissiez pas définir une adresse IP ou un nom d'hôte exact dans la variable `OWN_PRIVATE_API_URL` si, par exemple, l'hôte KAS se voit attribuer dynamiquement une adresse IP et un nom d'hôte.

Si vous ne pouvez pas définir une adresse IP ou un nom d'hôte exact, vous pouvez configurer `OWN_PRIVATE_API_CIDR` pour que KAS construise dynamiquement `OWN_PRIVATE_API_URL` en fonction d'un ou plusieurs [CIDRs](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing) :

Cette approche permet à chaque nœud KAS d'utiliser une configuration statique qui fonctionne tant que le CIDR ne change pas.

Pour chaque nœud KAS, modifiez le fichier situé à `/etc/gitlab/gitlab.rb` pour construire dynamiquement l'URL `OWN_PRIVATE_API_URL` :

1. Commentez `OWN_PRIVATE_API_URL` dans votre configuration commune pour désactiver cette variable.
1. Configurez `OWN_PRIVATE_API_CIDR` pour spécifier les réseaux sur lesquels les nœuds KAS écoutent. Lorsque vous démarrez KAS, il détermine quelle adresse IP privée utiliser en sélectionnant l'adresse d'hôte qui correspond au CIDR spécifié.
1. Configurez `OWN_PRIVATE_API_PORT` pour utiliser un port différent. Par défaut, KAS utilise le port du paramètre `private_api_listen_address`.
1. Si vous utilisez TLS sur le point de terminaison de l'API privée, configurez `OWN_PRIVATE_API_SCHEME=grpcs`. Par défaut, KAS utilise le schéma `grpc`.

```ruby
gitlab_kas['env'] = {
  # 'OWN_PRIVATE_API_CIDR' => '10.0.0.0/8', # IPv4 example
  # 'OWN_PRIVATE_API_CIDR' => '2001:db8:8a2e:370::7334/64', # IPv6 example
  # 'OWN_PRIVATE_API_CIDR' => '10.0.0.0/8,2001:db8:8a2e:370::7334/64', # multiple CIRDs example

  # 'OWN_PRIVATE_API_PORT' => '8155',
  # 'OWN_PRIVATE_API_SCHEME' => 'grpc',
}
```

##### Option 3 - configuration automatique basée sur la configuration du listener {#option-3---automatic-configuration-based-on-listener-configuration}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/464) dans GitLab 16.5.0.
- [Mise à jour](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/510) de KAS pour écouter et publier toutes les adresses IP non-loopback et filtrer les adresses IPv4 et IPv6 en fonction de la valeur de `private_api_listen_network`.

{{< /history >}}

Un nœud KAS peut déterminer les adresses IP disponibles en fonction des paramètres `private_api_listen_network` et `private_api_listen_address` :

- Si `private_api_listen_address` est défini sur une adresse IP fixe et un numéro de port (par exemple, `ip:port`), il utilise cette adresse IP.
- Si `private_api_listen_address` n'a pas d'adresse IP (par exemple, `:8155`), ou a une adresse IP non spécifiée (par exemple, `[::]:8155` ou `0.0.0.0:8155`), KAS attribue toutes les adresses IP non-loopback et non-link-local au nœud. Les adresses IPv4 et IPv6 sont filtrées en fonction de la valeur de `private_api_listen_network`.
- Si `private_api_listen_address` est un `hostname:PORT` (par exemple, `kas-N-private-api.gitlab.example.com:8155`), KAS résout le nom DNS et attribue toutes les adresses IP au nœud. Dans ce mode, KAS écoute uniquement sur la première adresse IP (ce comportement est défini par la [bibliothèque standard Go](https://pkg.go.dev/net#Listen)). Les adresses IPv4 et IPv6 sont filtrées en fonction de la valeur de `private_api_listen_network`.

Avant d'exposer l'adresse API privée d'un KAS sur toutes les adresses IP, assurez-vous que cette action n'entre pas en conflit avec la politique de sécurité de votre organisation. Le point de terminaison de l'API privée nécessite un jeton d'authentification valide pour toutes les requêtes.

Pour chaque nœud KAS, modifiez le fichier situé à `/etc/gitlab/gitlab.rb` :

Exemple 1. Écouter sur toutes les interfaces IPv4 et IPv6 :

```ruby
# gitlab_kas['private_api_listen_network'] = 'tcp' # this is the default value, no need to set it.
gitlab_kas['private_api_listen_address'] = ':8155' # Listen on all IPv4 and IPv6 interfaces
```

Exemple 2. Écouter sur toutes les interfaces IPv4 :

```ruby
gitlab_kas['private_api_listen_network'] = 'tcp4'
gitlab_kas['private_api_listen_address'] = ':8155'
```

Exemple 3. Écouter sur toutes les interfaces IPv6 :

```ruby
gitlab_kas['private_api_listen_network'] = 'tcp6'
gitlab_kas['private_api_listen_address'] = ':8155'
```

Vous pouvez utiliser des variables d'environnement pour remplacer le schéma et le port qui construisent l'URL `OWN_PRIVATE_API_URL` :

```ruby
gitlab_kas['env'] = {
  # 'OWN_PRIVATE_API_PORT' => '8155',
  # 'OWN_PRIVATE_API_SCHEME' => 'grpc',
}
```

##### Utiliser un équilibreur de charge ou un proxy inverse avec plusieurs instances KAS {#use-a-load-balancer-or-reverse-proxy-with-multiple-kas-instances}

> [!warning]
> Lorsque vous placez un équilibreur de charge ou un proxy inverse devant KAS, configurez des points de terminaison séparés pour le trafic externe et interne afin d'éviter d'exposer l'API interne.

KAS sert le trafic sur différents ports :

- Port 8150 (`listen_address`) : Connexions des agents (WebSocket/gRPC)
- Port 8153 (`internal_api_listen_address`) : API GitLab Rails (gRPC)

  > [!warning]
  > N'exposez pas le port 8153 publiquement. Bien que le port soit authentifié, il ne doit être accessible qu'aux instances GitLab Rails.

Pour sécuriser KAS lorsque vous utilisez un équilibreur de charge ou un proxy inverse, configurez deux points de terminaison séparés :

- Point de terminaison externe : Port 8150 (pour les agents)
- Point de terminaison interne : Port 8153 (pour GitLab Rails uniquement, restreint par le réseau ou le pare-feu)

Cette séparation garantit que l'API interne reste isolée de l'accès public.

Par exemple, configurez un point de terminaison interne avec des restrictions réseau dans NGINX :

```nginx
# Internal endpoint (network-restricted)
server {
  listen 8443 ssl http2;
  server_name kas-internal.example.com;

  # Optional: allow 10.0.1.0/24; deny all;

  location /gitlab.agent. {
    grpc_pass grpc://kas-backend:8153;
  }
}
```

Configurez GitLab pour utiliser les points de terminaison séparés (`/etc/gitlab/gitlab.rb`) :

```ruby
gitlab_rails['gitlab_kas_external_url'] = 'wss://kas-external.example.com'
gitlab_rails['gitlab_kas_internal_url'] = 'grpcs://kas-internal.example.com:8443'
gitlab_rails['gitlab_kas_external_k8s_proxy_url'] = 'https://kas-external.example.com/k8s-proxy/'
```

Points de configuration clés :

- Utilisez des domaines, des ports ou des restrictions IP séparés pour le trafic interne.
- Pour les équilibreurs de charge cloud, configurez des groupes cibles séparés pour les ports 8150 et 8153.

##### Paramètres du nœud GitLab Relay (KAS) {#gitlab-relay-kas-node-settings}

| Paramètre                                             | Description |
|-----------------------------------------------------|-------------|
| `gitlab_kas['private_api_listen_network']`          | La famille réseau sur laquelle KAS écoute. La valeur par défaut est `tcp` pour les réseaux IPv4 et IPv6. Définissez sur `tcp4` pour IPv4 ou `tcp6` pour IPv6. |
| `gitlab_kas['private_api_listen_address']`          | L'adresse sur laquelle KAS écoute. Définissez sur `0.0.0.0:8155` ou sur une adresse IP et un port accessibles par les autres nœuds du cluster. |
| `gitlab_kas['api_secret_key']`                      | Le secret partagé utilisé pour l'authentification entre KAS et GitLab. La valeur doit être encodée en Base64 et faire exactement 32 octets. |
| `gitlab_kas['private_api_secret_key']`              | Le secret partagé utilisé pour l'authentification entre différentes instances KAS. La valeur doit être encodée en Base64 et faire exactement 32 octets. |
| `gitlab_kas['private_api_certificate_file']`        | Chemin complet du fichier de certificat du serveur KAS. Requis lorsque `OWN_PRIVATE_API_SCHEME` ou `OWN_PRIVATE_API_URL` est `grpcs`. |
| `gitlab_kas['private_api_key_file']`                | Chemin complet du fichier de clé de certificat du serveur KAS. Requis lorsque `OWN_PRIVATE_API_SCHEME` ou `OWN_PRIVATE_API_URL` est `grpcs`. |
| `OWN_PRIVATE_API_SCHEME`                            | Valeur facultative utilisée pour spécifier le schéma à utiliser lors de la construction de `OWN_PRIVATE_API_URL`. Peut être `grpc` ou `grpcs`. |
| `OWN_PRIVATE_API_URL`                               | La variable d'environnement utilisée par KAS pour la découverte de services. Définissez sur le nom d'hôte ou l'adresse IP du nœud que vous configurez. Le nœud doit être accessible par les autres nœuds du cluster. |
| `OWN_PRIVATE_API_HOST`                              | Valeur facultative utilisée pour vérifier le nom d'hôte du certificat TLS. <sup>1</sup> Un client compare cette valeur au nom d'hôte dans le fichier de certificat TLS du serveur. |
| `OWN_PRIVATE_API_PORT`                              | Valeur facultative utilisée pour spécifier le port à utiliser lors de la construction de `OWN_PRIVATE_API_URL`. |
| `OWN_PRIVATE_API_CIDR`                              | Valeur facultative utilisée pour spécifier les adresses IP des réseaux disponibles à utiliser lors de la construction de `OWN_PRIVATE_API_URL`. |
| `gitlab_kas['client_timeout_seconds']`              | Le délai d'attente pour que le client se connecte au KAS. |
| `gitlab_kas_external_url`                           | L'URL exposée aux utilisateurs pour l'`agentk` dans le cluster. Peut être un domaine complet ou un sous-domaine, <sup>2</sup> ou une URL externe GitLab. <sup>3</sup> Si vide, prend par défaut une URL externe GitLab. |
| `gitlab_rails['gitlab_kas_external_url']`           | L'URL exposée aux utilisateurs pour l'`agentk` dans le cluster. Si vide, prend par défaut la valeur de `gitlab_kas_external_url`. |
| `gitlab_rails['gitlab_kas_external_k8s_proxy_url']` | L'URL exposée aux utilisateurs pour le proxy de l'API Kubernetes. Si vide, prend par défaut une URL basée sur `gitlab_kas_external_url`. |
| `gitlab_rails['gitlab_kas_internal_url']`           | L'URL interne utilisée par le backend GitLab pour communiquer avec KAS. |

**Remarques** :

1. Le TLS pour les connexions sortantes est activé lorsque `OWN_PRIVATE_API_URL` ou `OWN_PRIVATE_API_SCHEME` commence par `grpcs`.
1. Par exemple, `wss://kas.gitlab.example.com/`.
1. Par exemple, `wss://gitlab.example.com/-/kubernetes-agent/`.

#### Configurer un nœud KAS autonome {#configure-a-standalone-kas-node}

Configurez Omnibus pour exécuter KAS séparément des autres composants.

Sur chaque nœud Rails :

```ruby
## KAS Config
gitlab_kas['enable'] = false

gitlab_rails['gitlab_kas_enabled'] = true
gitlab_rails['gitlab_kas_external_url'] = 'wss://kas.example.com/-/kubernetes-agent/'
gitlab_rails['gitlab_kas_internal_url'] = 'grpc://<KAS_NODE_IP_OR_DOMAIN>:8153' # If you want to configure multiple KAS nodes that are behind an internal LB, then use 'grpc://<LB_IP_OR_DOMAIN>:<port>'
gitlab_rails['gitlab_kas_external_k8s_proxy_url'] = 'https://kas.example.com/-/kubernetes-agent/k8s-proxy/'
```

Sur chaque nœud KAS :

```ruby
### External URL
external_url 'https://kas.example.com'

### Avoid running unnecessary services ###
gitaly['enable'] = false
gitlab_workhorse['enable'] = false
nginx['enable'] = true
postgresql['enable'] = false
prometheus['enable'] = false
puma['enable'] = false
redis['enable'] = false
sidekiq['enable'] = false

### Prevent database connections during 'gitlab-ctl reconfigure' ###
gitlab_rails['rake_cache_clear'] = false
gitlab_rails['auto_migrate'] = false

gitlab_kas['redis_password'] = '<redis_password>'

# Uncomment below if using Redis high availability with Sentinel
# gitlab_kas['redis_sentinels'] = [
#  {host: '<REDIS_IP>', port: 26379},
#  {host: '<REDIS_IP>', port: 26379},
#  {host: '<REDIS_IP>', port: 26379},
# ]
# gitlab_kas['redis_sentinels_master_name'] = 'gitlab-redis'
# gitlab_kas['redis_sentinels_password'] = '<redis_sentinels_password>'

### GitLab Relay (KAS) ###
gitlab_kas['enable'] = true
gitlab_kas_external_url 'wss://kas.example.com/-/kubernetes-agent/'
gitlab_kas['api_secret_key'] = '<32_bytes_long_base64_encoded_value>'
gitlab_kas['private_api_secret_key'] = '<32_bytes_long_base64_encoded_value>'
gitlab_kas['private_api_listen_address'] = '<KAS_NODE_PRIVATE_IP>:8155'

gitlab_kas['listen_address'] = '<KAS_NODE_PRIVATE_IP>:8150'
gitlab_kas['observability_listen_address'] = '<KAS_NODE_PRIVATE_IP>:8151'
gitlab_kas['internal_api_listen_address'] = '<KAS_NODE_PRIVATE_IP>:8153'
gitlab_kas['kubernetes_api_listen_address'] = '<KAS_NODE_PRIVATE_IP>:8154'

```

### Pour GitLab Helm Chart {#for-gitlab-helm-chart}

Consultez [comment utiliser le chart GitLab-KAS](https://docs.gitlab.com/charts/charts/gitlab/kas/).

## Cookie proxy de l'API Kubernetes {#kubernetes-api-proxy-cookie}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/104504) dans GitLab 15.10 [avec des feature flags](../feature_flags/_index.md) nommés `kas_user_access` et `kas_user_access_project`. Désactivé par défaut. Désactivé par défaut.
- Les feature flags `kas_user_access` et `kas_user_access_project` ont été [activés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123479) dans GitLab 16.1.
- Les feature flags `kas_user_access` et `kas_user_access_project` ont été [supprimés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125835) dans GitLab 16.2.

{{< /history >}}

GitLab Relay (KAS) proxy les requêtes de l'API Kubernetes vers l'agent GitLab pour Kubernetes avec :

- Un [job CI/CD](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kubernetes_ci_access.md).
- [Les identifiants de l'utilisateur GitLab](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/kubernetes_user_access.md).

Pour s'authentifier avec les identifiants de l'utilisateur, Rails définit un cookie pour le frontend GitLab. Ce cookie s'appelle `_gitlab_kas` et il contient un ID de session chiffré, comme le [cookie `_gitlab_session`](../../user/profile/_index.md#cookies-used-for-sign-in). Le cookie `_gitlab_kas` doit être envoyé au point de terminaison du proxy KAS avec chaque requête pour authentifier et autoriser l'utilisateur.

## Activer les agents réceptifs {#enable-receptive-agents}

{{< details >}}

- Niveau : Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/12180) dans GitLab 17.4.

{{< /history >}}

Les [agents réceptifs](../../user/clusters/agent/_index.md#receptive-agents) permettent à GitLab de s'intégrer aux clusters Kubernetes qui ne peuvent pas établir de connexion réseau vers l'instance GitLab, mais auxquels GitLab peut se connecter.

Prérequis :

- Accès administrateur.

Pour activer les agents réceptifs :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Agent GitLab pour Kubernetes**.
1. Activez le bouton **Activer le mode réceptif**.

## Configurer la liste d'autorisation des en-têtes de réponse du proxy de l'API Kubernetes {#configure-kubernetes-api-proxy-response-header-allowlist}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/642) dans GitLab 18.3 [avec un flag](../feature_flags/_index.md) nommé `kas_k8s_api_proxy_response_header_allowlist`. Désactivé par défaut. Désactivé par défaut.
- [Généralement disponible](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/642) dans GitLab 18.7. Feature flag `kas_k8s_api_proxy_response_header_allowlist` supprimé.

{{< /history >}}

Le proxy de l'API Kubernetes dans KAS utilise une liste d'autorisation pour les en-têtes de réponse. Les en-têtes Kubernetes et HTTP sécurisés et bien connus sont autorisés par défaut.

Pour obtenir la liste des en-têtes de réponse autorisés, consultez la [liste d'autorisation des en-têtes de réponse](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/internal/module/kubernetes_api/server/proxy_headers.go).

Si vous avez besoin d'en-têtes de réponse qui ne figurent pas dans la liste d'autorisation par défaut, vous pouvez ajouter vos en-têtes de réponse dans la configuration KAS.

Pour ajouter des en-têtes de réponse supplémentaires autorisés :

```yaml
agent:
  kubernetes_api:
    extra_allowed_response_headers:
      - 'X-My-Custom-Header-To-Allow'
```

La prise en charge de l'ajout de davantage d'en-têtes de réponse est suivie dans le [ticket 550614](https://gitlab.com/gitlab-org/gitlab/-/issues/550614).

## Dépannage {#troubleshooting}

Si vous rencontrez des problèmes lors de l'utilisation de GitLab Relay (KAS), consultez les journaux du service en exécutant la commande suivante :

```shell
kubectl logs -f -l=app=kas -n <YOUR-GITLAB-NAMESPACE>
```

Dans les installations de package Linux, les journaux se trouvent dans `/var/log/gitlab/gitlab-kas/`.

Vous pouvez également [résoudre les problèmes avec des agents individuels](../../user/clusters/agent/troubleshooting.md).

### Fichier de configuration introuvable {#configuration-file-not-found}

Si vous obtenez le message d'erreur suivant :

```plaintext
time="2020-10-29T04:44:14Z" level=warning msg="Config: failed to fetch" agent_id=2 error="configuration file not found: \".gitlab/agents/test-agent/config.yaml\
```

Le chemin est incorrect pour l'un des éléments suivants :

- Le dépôt où l'agent a été enregistré.
- Le fichier de configuration de l'agent.

Pour résoudre ce problème, assurez-vous que les chemins sont corrects.

### Erreur : `dial tcp <GITLAB_INTERNAL_IP>:443: connect: connection refused` {#error-dial-tcp-gitlab_internal_ip443-connect-connection-refused}

Si vous exécutez GitLab Self-Managed et que :

- L'instance ne s'exécute pas derrière un proxy de terminaison SSL.
- L'instance n'a pas HTTPS configuré sur l'instance GitLab elle-même.
- Le nom d'hôte de l'instance se résout localement vers son adresse IP interne.

Lorsque GitLab Relay (KAS) tente de se connecter à l'API GitLab, l'erreur suivante peut se produire :

```json
{"level":"error","time":"2021-08-16T14:56:47.289Z","msg":"GetAgentInfo()","correlation_id":"01FD7QE35RXXXX8R47WZFBAXTN","grpc_service":"gitlab.agent.reverse_tunnel.rpc.ReverseTunnel","grpc_method":"Connect","error":"Get \"https://gitlab.example.com/api/v4/internal/kubernetes/agent_info\": dial tcp 172.17.0.4:443: connect: connection refused"}
```

Pour résoudre ce problème dans les installations de package Linux, définissez le paramètre suivant dans `/etc/gitlab/gitlab.rb`. Remplacez `gitlab.example.com` par le nom d'hôte de votre instance GitLab :

```ruby
gitlab_kas['gitlab_address'] = 'http://gitlab.example.com'
```

### Erreur : `x509: certificate signed by unknown authority` {#error-x509-certificate-signed-by-unknown-authority}

Si vous rencontrez cette erreur en essayant d'accéder à l'URL GitLab, cela signifie qu'elle ne fait pas confiance au certificat GitLab.

Vous pourriez voir une erreur similaire dans les journaux KAS de votre serveur d'application GitLab :

```json
{"level":"error","time":"2023-03-07T20:19:48.151Z","msg":"AgentInfo()","grpc_service":"gitlab.agent.agent_configuration.rpc.AgentConfiguration","grpc_method":"GetConfiguration","error":"Get \"https://gitlab.example.com/api/v4/internal/kubernetes/agent_info\": x509: certificate signed by unknown authority"}
```

Pour corriger cette erreur, installez le certificat public de votre autorité de certification interne dans le répertoire `/etc/gitlab/trusted-certs`.

Vous pouvez également configurer KAS pour lire le certificat depuis un répertoire personnalisé. Pour ce faire, ajoutez la configuration suivante au fichier situé à `/etc/gitlab/gitlab.rb` :

```ruby
gitlab_kas['env'] = {
   'SSL_CERT_DIR' => "/opt/gitlab/embedded/ssl/certs/"
 }
```

Pour appliquer les modifications :

1. Reconfigurer GitLab :

```shell
sudo gitlab-ctl reconfigure
```

1. Redémarrer GitLab Relay (KAS) :

```shell
gitlab-ctl restart gitlab-kas
```

### Erreur : `GRPC::DeadlineExceeded in Clusters::Agents::NotifyGitPushWorker` {#error-grpcdeadlineexceeded-in-clustersagentsnotifygitpushworker}

Cette erreur se produit probablement lorsque le client ne reçoit pas de réponse dans le délai d'attente par défaut (5 secondes). Pour résoudre le problème, vous pouvez augmenter le délai d'attente du client en modifiant le fichier de configuration `/etc/gitlab/gitlab.rb`.

#### Étapes de résolution {#steps-to-resolve}

1. Ajoutez ou mettez à jour la configuration suivante pour augmenter la valeur du délai d'attente :

```ruby
gitlab_kas['client_timeout_seconds'] = "10"
```

1. Appliquez les modifications en reconfigurant GitLab :

```shell
gitlab-ctl reconfigure
```

#### Remarque {#note}

Vous pouvez ajuster la valeur du délai d'attente en fonction de vos besoins spécifiques. Il est recommandé d'effectuer des tests pour s'assurer que le problème est résolu sans impact sur les performances du système.

### Erreur : `Blocked Kubernetes API proxy response header` {#error-blocked-kubernetes-api-proxy-response-header}

Si des en-têtes de réponse HTTP sont perdus lors de leur envoi du cluster Kubernetes à l'utilisateur via le proxy de l'API Kubernetes, vérifiez les journaux KAS ou l'instance Sentry pour l'erreur suivante :

```plaintext
Blocked Kubernetes API proxy response header. Please configure extra allowed headers for your instance in the KAS config with `extra_allowed_response_headers` and have a look at the troubleshooting guide at https://docs.gitlab.com/administration/clusters/kas/#troubleshooting.
```

Cette erreur signifie que le proxy de l'API Kubernetes a bloqué des en-têtes de réponse car ils ne sont pas définis dans la liste d'autorisation des en-têtes de réponse.

Pour plus d'informations sur l'ajout d'en-têtes de réponse, consultez [configurer la liste d'autorisation des en-têtes de réponse](#configure-kubernetes-api-proxy-response-header-allowlist).

La prise en charge de l'ajout de davantage d'en-têtes de réponse est suivie dans le [ticket 550614](https://gitlab.com/gitlab-org/gitlab/-/issues/550614).
