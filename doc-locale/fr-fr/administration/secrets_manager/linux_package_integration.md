---
stage: Sec
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Installer OpenBao pour un déploiement GitLab avec le package Linux
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed
- Statut :  Bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/9669) dans GitLab 19.0 en version bêta.

{{< /history >}}

Utilisez un cluster Kubernetes pour exécuter OpenBao aux côtés d'une instance GitLab installée avec le package Linux. OpenBao s'exécute dans le cluster et se connecte à une base de données PostgreSQL. GitLab Rails et Sidekiq se connectent à OpenBao via HTTPS.

Exécutez OpenBao de l'une des deux manières suivantes :

- **Colocated cluster** :  Une distribution Kubernetes locale (par exemple, k3s) s'exécute sur le même hôte que votre instance de package Linux. Le NGINX fourni avec le package Linux agit comme proxy inverse avec terminaison TLS pour l'URL externe d'OpenBao. L'application GitLab se connecte à OpenBao via le point de terminaison que Kubernetes expose sur le réseau partagé.
- **External Kubernetes cluster** :  OpenBao s'exécute dans un cluster Kubernetes séparé. Vous concevez l'Ingress du cluster et la terminaison TLS. GitLab Rails et Sidekiq se connectent à l'URL OpenBao que vous exposez. Envisagez cette approche si vous avez un déploiement de package Linux multi-nœuds ou si vous préférez utiliser un service Kubernetes géré par votre fournisseur cloud.

> [!note]
> Le [cluster PostgreSQL](../postgresql/replication_and_failover.md) géré par le package Linux n'est pas pris en charge comme backend de base de données OpenBao. Si vous utilisez un tel cluster pour GitLab, provisionnez une instance PostgreSQL séparée pour OpenBao, soit autogérée, soit en tant que service de base de données cloud géré. Pour plus d'informations, consultez le [ticket 7292](https://gitlab.com/gitlab-org/omnibus-gitlab/-/work_items/7292).

## Prérequis {#prerequisites}

{{< tabs >}}

{{< tab title="Cluster colocalisé" >}}

- GitLab 19.0 ou version ultérieure installé avec le package Linux, avec accès administrateur.
- Une distribution Kubernetes locale installée sur le même hôte.
- `helm` et `kubectl` disponibles sur l'hôte.
- Un enregistrement DNS qui pointe le domaine OpenBao vers l'adresse IP publique de l'hôte.

{{< /tab >}}

{{< tab title="Cluster externe" >}}

- Une instance GitLab installée avec le package Linux, avec accès administrateur.
- Un cluster Kubernetes externe accessible depuis les nœuds de votre instance de package Linux.
- `helm` et `kubectl` configurés pour accéder au cluster.
- Un enregistrement DNS qui pointe le domaine OpenBao vers l'adresse IP de l'Ingress du cluster.

{{< /tab >}}

{{< /tabs >}}

## Exigences {#requirements}

{{< tabs >}}

{{< tab title="Cluster colocalisé" >}}

Avant d'installer OpenBao, vérifiez que votre distribution Kubernetes répond à ces exigences :

- Les [recommandations de dimensionnement d'OpenBao](_index.md#sizing-recommendations) doivent être satisfaites en plus des exigences d'une instance de package Linux et des exigences de votre cluster Kubernetes.
- Rien dans votre Kubernetes colocalisé ne doit tenter de se connecter aux ports déjà utilisés par GitLab. De nombreuses petites distributions Kubernetes installent des équilibreurs de charge qui se lient aux ports 80 et 443 par défaut. Désactivez ces composants car le NGINX géré par le package Linux écoute déjà sur ces ports.
- Votre Kubernetes colocalisé doit partager un réseau avec votre instance de package Linux afin que le NGINX géré par le package Linux puisse acheminer le trafic OpenBao externe vers le service OpenBao et écouter les requêtes provenant de celui-ci. Votre instance de package Linux ne se soucie pas de savoir si le service est exposé via un Kubernetes `LoadBalancer` ou `NodePort`, du moment que les deux sont accessibles dans le réseau partagé.

{{< /tab >}}

{{< tab title="Cluster externe" >}}

Avant d'installer OpenBao, vérifiez que votre configuration répond à ces exigences :

- Les [recommandations de dimensionnement d'OpenBao](_index.md#sizing-recommendations) doivent être satisfaites par votre cluster Kubernetes.
- Une connectivité réseau doit exister entre les pods OpenBao dans le cluster et les nœuds de votre instance de package Linux. La façon dont vous établissez cette connectivité dépend de votre infrastructure. Par exemple, vous pourriez utiliser le peering VPC, un VPC partagé ou des règles de pare-feu. GitLab Rails et Sidekiq doivent être en mesure d'atteindre l'URL OpenBao que vous exposez depuis le cluster.
- Si vous utilisez PostgreSQL géré par le package Linux comme base de données OpenBao, le nœud PostgreSQL doit accepter les connexions TCP depuis le CIDR du pod du cluster. Configurez des règles de pare-feu ou de groupe de sécurité pour autoriser ce trafic sur le port de la base de données.

{{< /tab >}}

{{< /tabs >}}

## Avant de commencer {#before-you-begin}

{{< tabs >}}

{{< tab title="Cluster colocalisé" >}}

Avant de commencer :

1. Collectez le CIDR de votre CNI Kubernetes (réseau de pods). Vous en aurez besoin plus tard pour configurer l'authentification PostgreSQL.
1. Collectez l'adresse IP de l'interface réseau partagée entre votre instance de package Linux et Kubernetes (`<SHARED_NETWORK_IP>`). Vous en aurez besoin plus tard pour plusieurs valeurs de configuration.
1. Confirmez que votre distribution Kubernetes est entièrement en cours d'exécution avant de tenter d'installer OpenBao.
1. Confirmez que votre contexte `kubectl` est défini sur ce cluster (`KUBECONFIG` est correctement configuré).

{{< /tab >}}

{{< tab title="Cluster externe" >}}

Avant de commencer :

1. Collectez le CIDR de votre réseau de pods Kubernetes. Vous en aurez besoin plus tard pour configurer l'authentification PostgreSQL.
1. Collectez l'adresse de l'instance PostgreSQL qu'OpenBao utilise (`<POSTGRES_ADDRESS>`). Il s'agit soit de l'adresse IP de votre nœud PostgreSQL du package Linux, soit du point de terminaison de votre instance PostgreSQL externe ou gérée.
1. Confirmez que votre cluster Kubernetes est entièrement en cours d'exécution avant de tenter d'installer OpenBao.
1. Confirmez que votre contexte `kubectl` est défini sur ce cluster (`KUBECONFIG` est correctement configuré).

{{< /tab >}}

{{< /tabs >}}

## Provisionner la base de données PostgreSQL d'OpenBao {#provision-the-openbao-postgresql-database}

> [!note]
> `gitlab-psql` est uniquement disponible lors de l'utilisation de PostgreSQL géré par le package Linux. Si vous utilisez plutôt une instance PostgreSQL externe ou gérée, exécutez des commandes SQL équivalentes sur cette instance. La logique de création des utilisateurs et de la base de données est la même.

`gitlab-psql` se connecte via le socket Unix et ne nécessite pas d'écouteurs TCP, vous pouvez donc exécuter ces commandes avant `gitlab-ctl reconfigure`.

Pour provisionner la base de données PostgreSQL d'OpenBao :

1. Choisissez un mot de passe fort pour l'utilisateur de la base de données OpenBao. Vous utiliserez ce même mot de passe dans le secret Kubernetes à la dernière étape de cette section.

1. Créez l'utilisateur de la base de données OpenBao :

   ```shell
   sudo gitlab-psql \
     -c "CREATE USER openbao WITH PASSWORD '<strong-password>';"
   ```

1. Créez la base de données OpenBao :

   ```shell
   sudo gitlab-psql \
     -c "CREATE DATABASE openbao OWNER openbao;"
   ```

1. Créez l'espace de nommage Kubernetes et le secret qui transmet le mot de passe de la base de données au chart Helm :

   ```shell
   kubectl create namespace openbao

   kubectl create secret generic openbao-db-secret \
     --namespace openbao \
     --from-literal=password='<strong-password>'
   ```

## Installer OpenBao à l'aide de Helm {#install-openbao-by-using-helm}

{{< tabs >}}

{{< tab title="Cluster colocalisé" >}}

Pour installer OpenBao à l'aide de Helm :

1. Ajoutez le dépôt Helm GitLab :

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   ```

1. Créez un fichier `openbao-values.yaml` avec le contenu suivant, en remplaçant les valeurs fictives par vos domaines réels et votre adresse IP :

   ```yaml
   config:
     ui: false
     storage:
       postgresql:
         haEnabled: true
         connection:
           host: "<SHARED_NETWORK_IP>"
           port: 5432
           database: openbao
           username: openbao
           sslMode: "disable"
           password:
             secret: openbao-db-secret
             key: password
     initialize:
       enabled: true
       oidcDiscoveryUrl: "https://<GITLAB_DOMAIN>"
       boundIssuer: "https://<GITLAB_DOMAIN>"
       boundAudiences: '"https://<OPENBAO_DOMAIN>"'

   gatewayRoute:
     enabled: false
   ```

1. Installez OpenBao :

   ```shell
   helm upgrade --install openbao gitlab/openbao \
     --namespace openbao \
     --values openbao-values.yaml
   ```

   N'utilisez pas `--wait`, car le pod ne peut pas se connecter à PostgreSQL. PostgreSQL n'accepte les connexions TCP depuis le réseau de pods qu'après `gitlab-ctl reconfigure`. Pour l'instant, les pods sont dans un état `CrashLoopBackOff`.

   Pour toutes les options de chart disponibles, consultez la [documentation du chart Helm OpenBao](https://docs.gitlab.com/charts/charts/openbao/).

1. Définissez l'URL interne à utiliser pour le service OpenBao. Vous avez plusieurs options :

   - Équilibreur de charge. Si vous utilisez un équilibreur de charge interne sur votre cluster Kubernetes colocalisé, vous pouvez définir le paramètre `oak['components']['openbao']['internal_url']` de votre fichier `gitlab.rb` sur l'URL interne de votre équilibreur de charge pour acheminer les requêtes vers le service Kubernetes OpenBao. Dans ce cas, vous devez configurer le DNS pour vous assurer que l'URL interne est résolue vers l'IP de l'équilibreur de charge interne.
   - Cluster `nodePort`. Si vous personnalisez votre service de chart OpenBao pour qu'il s'exécute sur un type de service Kubernetes `nodePort`, l'URL interne peut également être configurée en conséquence.
   - Service `clusterIP`. Cette option est probablement la plus simple. Vous pouvez également ignorer complètement un équilibreur de charge pour votre cluster colocalisé en informant l'URL interne d'OpenBao de communiquer directement avec le service OpenBao `clusterIP`. Cette option vous évite d'avoir à installer un équilibreur de charge supplémentaire sur votre machine car le NGINX géré par le package Linux est déjà présent.

   Vous pouvez trouver le `clusterIP` du service OpenBao en exécutant :

   ```shell
   kubectl -n openbao get svc openbao-active \
     -o jsonpath='{.spec.clusterIP}'
   ```

   N'oubliez pas que l'IP de l'URL interne doit être accessible par la machine hôte en dehors de votre cluster Kubernetes. Configurez votre cluster pour allouer des IP depuis votre `<SHARED_NETWORK_IP>` choisi.

{{< /tab >}}

{{< tab title="Cluster externe" >}}

Pour installer OpenBao à l'aide de Helm :

1. Ajoutez le dépôt Helm GitLab :

   ```shell
   helm repo add gitlab https://charts.gitlab.io
   helm repo update
   ```

1. Créez un fichier `openbao-values.yaml` avec le contenu suivant, en remplaçant les valeurs fictives par vos domaines réels et votre adresse PostgreSQL :

   ```yaml
   config:
     ui: false
     storage:
       postgresql:
         haEnabled: true
         connection:
           host: "<POSTGRES_ADDRESS>"
           port: 5432
           database: openbao
           username: openbao
           password:
             secret: openbao-db-secret
             key: password
     initialize:
       enabled: true
       oidcDiscoveryUrl: "https://<GITLAB_DOMAIN>"
       boundIssuer: "https://<GITLAB_DOMAIN>"
       boundAudiences: '"https://<OPENBAO_DOMAIN>"'

   # The chart deploys a Kubernetes Ingress resource by default, which you need to provide the hostname to be reachable for GitLab Rails and Sidekiq
   # Alternatively, you could configure it to deploy an HTTPRoute resource, if you prefer to deploy a Gateway API controller.
   #
   # For available network ingress and TLS configuration options, see:
   # https://docs.gitlab.com/charts/charts/openbao/#ingress-and-tls-configuration-options
   ingress:
     enabled: true
     hostname: "<OPENBAO_DOMAIN>"
   ```

1. Installez OpenBao :

   ```shell
   helm upgrade --install openbao gitlab/openbao \
     --namespace openbao \
     --values openbao-values.yaml
   ```

Pour toutes les options de chart disponibles, consultez la [documentation du chart Helm OpenBao](https://docs.gitlab.com/charts/charts/openbao/).

{{< /tab >}}

{{< /tabs >}}

## Configurer GitLab {#configure-gitlab}

{{< tabs >}}

{{< tab title="Cluster colocalisé" >}}

Ajoutez ce qui suit à `/etc/gitlab/gitlab.rb` sur votre hôte GitLab, en remplaçant les valeurs fictives par vos adresses IP et votre domaine réels :

```ruby
# PostgreSQL: accept TCP connections from Kubernetes pods.
# Use the shared network IP to restrict exposure to the shared network.
# Using '0.0.0.0' makes PostgreSQL listen on all interfaces, including public ones.
postgresql['listen_address'] = '<SHARED_NETWORK_IP>'

# Local connections (GitLab Rails and other services) continue without a password.
postgresql['trust_auth_cidr_addresses'] = %w[127.0.0.1/32 ::1/128]

# Kubernetes pods authenticate with a password.
# Replace 10.42.0.0/16 with the CIDR of your Kubernetes CNI (pod network).
postgresql['md5_auth_cidr_addresses'] = %w[10.42.0.0/16]

# OAK: OpenBao reverse proxy via GitLab NGINX.
oak['enable'] = true
oak['network_address'] = '<SHARED_NETWORK_IP>'

oak['components']['openbao']['enable'] = true

# Replace 'https://openbao.example.com' with the URL of the DNS record
# you configured for OpenBao, which resolves to your host's public IP address.
oak['components']['openbao']['external_url'] = 'https://openbao.example.com'

# Example of service clusterIP. Replace <CLUSTER_IP> with the IP taken
# from the previous step.
#
# A nodePort would look similar: specify the cluster node IP with the port
# you chose when you deployed OpenBao.
#
# If behind a load balancer: 'http://openbao-internal.example.com'
oak['components']['openbao']['internal_url'] = 'http://<CLUSTER_IP>:8200'

# The URL that the GitLab application uses to connect to OpenBao.
gitlab_rails['openbao'] = {
  'url' => 'https://openbao.example.com'
}
```

Dans cette configuration :

- `postgresql['listen_address']` est l'IP du réseau partagé. Les connexions provenant de CIDR non répertoriés dans `trust_auth_cidr_addresses` ou `md5_auth_cidr_addresses` sont rejetées par PostgreSQL.
- `postgresql['trust_auth_cidr_addresses']` est une liste de blocs CIDR (localhost uniquement). Les connexions depuis ces blocs ne nécessitent pas de mot de passe. Ces adresses sont utilisées par les services GitLab.
- `postgresql['md5_auth_cidr_addresses']` est une liste de blocs CIDR du CIDR du pod. Les connexions depuis ces blocs nécessitent un mot de passe. Ces adresses sont utilisées par les pods OpenBao. Authentification par mot de passe. Utilisé par les pods OpenBao.
- `oak['network_address']` est l'IP du réseau partagé. Utilisé par les directives d'écoute NGINX.
- `oak['components']['openbao']['internal_url']` est l'URL utilisée par l'application GitLab pour communiquer avec OpenBao.
- `gitlab_rails['openbao']['url']` est l'URL OpenBao utilisée par l'application GitLab.

Si votre paramètre `external_url` GitLab utilise `https://`, Let's Encrypt est déjà activé. Définir le schéma `external_url` d'OpenBao sur `https://` est suffisant. GitLab ajoute automatiquement le domaine OpenBao comme Subject Alternative Name (SAN) sur le certificat Let's Encrypt existant.

Pour utiliser un certificat personnalisé à la place, ajoutez :

```ruby
oak['components']['openbao']['ssl_certificate']     = '/etc/gitlab/ssl/openbao.example.com.crt'
oak['components']['openbao']['ssl_certificate_key'] = '/etc/gitlab/ssl/openbao.example.com.key'
```

{{< /tab >}}

{{< tab title="Cluster externe" >}}

Ajoutez ce qui suit à `/etc/gitlab/gitlab.rb` sur chaque nœud d'application GitLab, en remplaçant les valeurs fictives par vos adresses et votre domaine réels :

```ruby
# The URL GitLab Rails uses to connect to OpenBao.
gitlab_rails['openbao'] = {
  'url' => 'https://openbao.example.com'
}
```

Si vous avez des nœuds Sidekiq séparés, ajoutez le même paramètre `gitlab_rails['openbao']` à `/etc/gitlab/gitlab.rb` sur chaque nœud Sidekiq. Les workers Sidekiq qui provisionnent les secrets nécessitent également un accès à OpenBao.

Si vous utilisez PostgreSQL géré par le package Linux comme base de données OpenBao, ajoutez également ce qui suit à `/etc/gitlab/gitlab.rb` sur le nœud PostgreSQL :

```ruby
# PostgreSQL: accept TCP connections from Kubernetes pods.
postgresql['listen_address'] = '<POSTGRES_ADDRESS>'

# Local connections (GitLab Rails and other services) continue without a password.
postgresql['trust_auth_cidr_addresses'] = %w[127.0.0.1/32 ::1/128]

# Kubernetes pods authenticate with a password.
# Replace 10.0.0.0/14 with the CIDR of your Kubernetes pod network.
postgresql['md5_auth_cidr_addresses'] = %w[10.0.0.0/14]
```

{{< /tab >}}

{{< /tabs >}}

## Appliquer les modifications de configuration {#apply-configuration-changes}

{{< tabs >}}

{{< tab title="Cluster colocalisé" >}}

Appliquez les modifications de configuration :

```shell
sudo gitlab-ctl reconfigure
```

Cette commande applique toute la configuration en une seule passe :

- PostgreSQL commence à accepter les connexions TCP des pods Kubernetes.
- NGINX est configuré avec l'hôte virtuel OpenBao, y compris la terminaison TLS et la redirection HTTP vers HTTPS.
- Le certificat Let's Encrypt est émis ou renouvelé, le cas échéant.

{{< /tab >}}

{{< tab title="Cluster externe" >}}

Appliquez les modifications de configuration sur chaque nœud où vous avez mis à jour `gitlab.rb` :

```shell
sudo gitlab-ctl reconfigure
```

Sur le nœud PostgreSQL, cela fait accepter à PostgreSQL les connexions TCP depuis le réseau de pods du cluster. Sur les nœuds Rails et Sidekiq, cela applique la configuration de l'URL OpenBao.

{{< /tab >}}

{{< /tabs >}}

## Attendre qu'OpenBao soit prêt {#wait-for-openbao-to-become-ready}

Attendez que le déploiement soit terminé :

```shell
kubectl -n openbao rollout status deployment openbao
```

Pour les clusters colocalisés, les pods précédemment dans un état `CrashLoopBackOff` deviennent sains après que `gitlab-ctl reconfigure` se termine.

## Vérifier l'installation {#verify-the-installation}

Pour vérifier l'installation :

1. Vérifiez qu'OpenBao est accessible :

   ```shell
   curl "https://openbao.example.com/v1/sys/health"
   ```

   Une réponse réussie ressemble à :

   ```json
   {
     "initialized": true,
     "sealed": false,
     "standby": false,
     "version": "2.0.0"
   }
   ```

1. [Activez le GitLab Secrets Manager](../../ci/secrets/secrets_manager/_index.md#enable-for-a-group-or-project).
