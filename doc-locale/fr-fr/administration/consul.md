---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Comment configurer Consul
description: Configurer un cluster Consul.
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Un cluster Consul se compose à la fois d'[agents serveur et client](https://developer.hashicorp.com/consul/docs/agent). Les serveurs s'exécutent sur leurs propres nœuds et les clients s'exécutent sur d'autres nœuds qui communiquent à leur tour avec les serveurs.

GitLab Premium inclut une version groupée de [Consul](https://www.consul.io/), une solution de mise en réseau de services que vous pouvez gérer en utilisant `/etc/gitlab/gitlab.rb`.

## Prérequis {#prerequisites}

Avant de configurer Consul :

1. Consultez la documentation sur l'[architecture de référence](reference_architectures/_index.md#available-reference-architectures) pour déterminer le nombre de nœuds serveur Consul dont vous devez disposer.
1. Si nécessaire, assurez-vous que les [ports appropriés sont ouverts](package_information/defaults.md#ports) dans votre pare-feu.

## Configurer les nœuds Consul {#configure-the-consul-nodes}

Sur chaque nœud serveur Consul :

1. Suivez les instructions pour [installer](https://about.gitlab.com/install/) GitLab en choisissant votre plateforme préférée, mais ne fournissez pas la valeur `EXTERNAL_URL` lorsqu'elle est demandée.
1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez ce qui suit en remplaçant les valeurs indiquées dans la section `retry_join`. Dans l'exemple ci-dessous, il y a trois nœuds, deux désignés par leur IP et un par son FQDN ; vous pouvez utiliser l'une ou l'autre notation :

   ```ruby
   # Disable all components except Consul
   roles ['consul_role']

   # Consul nodes: can be FQDN or IP, separated by a whitespace
   consul['configuration'] = {
     server: true,
     retry_join: %w(10.10.10.1 consul1.gitlab.example.com 10.10.10.2)
   }

   # Disable auto migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. [Reconfigurez GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
1. Exécutez la commande suivante pour vérifier que Consul est correctement configuré et que tous les nœuds serveur communiquent bien :

   ```shell
   sudo /opt/gitlab/embedded/bin/consul members
   ```

   Le résultat devrait être similaire à :

   ```plaintext
   Node                 Address               Status  Type    Build  Protocol  DC
   CONSUL_NODE_ONE      XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_consul
   CONSUL_NODE_TWO      XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_consul
   CONSUL_NODE_THREE    XXX.XXX.XXX.YYY:8301  alive   server  0.9.2  2         gitlab_consul
   ```

   Si les résultats affichent des nœuds avec un statut différent de `alive`, ou si l'un des trois nœuds est manquant, consultez la [section Dépannage](#troubleshooting-consul).

## Sécurisation des nœuds Consul {#securing-the-consul-nodes}

Il existe deux façons de sécuriser la communication entre les nœuds Consul : en utilisant le chiffrement TLS ou le chiffrement gossip.

### Chiffrement TLS {#tls-encryption}

Par défaut, TLS n'est pas activé pour le cluster Consul. Les options de configuration par défaut et leurs valeurs par défaut sont :

```ruby
consul['use_tls'] = false
consul['tls_ca_file'] = nil
consul['tls_certificate_file'] = nil
consul['tls_key_file'] = nil
consul['tls_verify_client'] = nil
```

Ces options de configuration s'appliquent à la fois aux nœuds client et serveur.

Pour activer TLS sur un nœud Consul, commencez par `consul['use_tls'] = true`. Selon le rôle du nœud (serveur ou client) et vos préférences TLS, vous devez fournir une configuration supplémentaire :

- Sur un nœud serveur, vous devez au moins spécifier `tls_ca_file`, `tls_certificate_file` et `tls_key_file`.
- Sur un nœud client, lorsque l'authentification TLS client est désactivée sur le serveur (activée par défaut), vous devez au moins spécifier `tls_ca_file` ; sinon, vous devez transmettre le certificat et la clé TLS client en utilisant `tls_certificate_file`, `tls_key_file`.

Lorsque TLS est activé, le serveur utilise mTLS par défaut et écoute à la fois sur HTTPS et HTTP (ainsi que sur RPC TLS et non-TLS). Il attend des clients qu'ils utilisent l'authentification TLS. Vous pouvez désactiver l'authentification TLS client en définissant `consul['tls_verify_client'] = false`.

En revanche, les clients utilisent TLS uniquement pour les connexions sortantes vers les nœuds serveur et n'écoutent que sur HTTP (et RPC non-TLS) pour les requêtes entrantes. Vous pouvez forcer les agents Consul clients à utiliser TLS pour les connexions entrantes en définissant `consul['https_port']` sur un entier non négatif (`8501` est le port HTTPS par défaut de Consul). Vous devez également transmettre `tls_certificate_file` et `tls_key_file` pour que cela fonctionne. Lorsque les nœuds serveur utilisent l'authentification TLS client, le certificat et la clé TLS client sont utilisés à la fois pour l'authentification TLS et les connexions HTTPS entrantes.

Les nœuds clients Consul n'utilisent pas l'authentification TLS client par défaut (contrairement aux serveurs) et vous devez explicitement leur demander de le faire en définissant `consul['tls_verify_client'] = true`.

Vous trouverez ci-dessous quelques exemples de chiffrement TLS.

#### Prise en charge TLS minimale {#minimal-tls-support}

Dans l'exemple suivant, le serveur utilise TLS pour les connexions entrantes (sans authentification TLS client).

{{< tabs >}}

{{< tab title="Nœud serveur Consul" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   consul['enable'] = true
   consul['configuration'] = {
     'server' => true
   }

   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/server.crt.pem'
   consul['tls_key_file'] = '/path/to/server.key.pem'
   consul['tls_verify_client'] = false
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Nœud client Consul" >}}

Ce qui suit peut être configuré sur un nœud Patroni, par exemple.

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   consul['enable'] = true
   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   patroni['consul']['url'] = 'http://localhost:8500'
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Patroni communique avec l'agent Consul local qui n'utilise pas TLS pour les connexions entrantes. D'où l'URL HTTP pour `patroni['consul']['url']`.

{{< /tab >}}

{{< /tabs >}}

#### Prise en charge TLS par défaut {#default-tls-support}

Dans l'exemple suivant, le serveur utilise l'authentification TLS mutuelle.

{{< tabs >}}

{{< tab title="Nœud serveur Consul" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   consul['enable'] = true
   consul['configuration'] = {
     'server' => true
   }

   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/server.crt.pem'
   consul['tls_key_file'] = '/path/to/server.key.pem'
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Nœud client Consul" >}}

Ce qui suit peut être configuré sur un nœud Patroni, par exemple.

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   consul['enable'] = true
   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/client.crt.pem'
   consul['tls_key_file'] = '/path/to/client.key.pem'
   patroni['consul']['url'] = 'http://localhost:8500'
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Patroni communique avec l'agent Consul local qui n'utilise pas TLS pour les connexions entrantes, même s'il utilise l'authentification TLS vers les nœuds serveur Consul. D'où l'URL HTTP pour `patroni['consul']['url']`.

{{< /tab >}}

{{< /tabs >}}

#### Prise en charge TLS complète {#full-tls-support}

Dans l'exemple suivant, le client et le serveur utilisent tous deux l'authentification TLS mutuelle.

Les certificats du serveur Consul, du client Consul et du client Patroni doivent être émis par la même autorité de certification pour que l'authentification TLS mutuelle fonctionne.

{{< tabs >}}

{{< tab title="Nœud serveur Consul" >}}

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   consul['enable'] = true
   consul['configuration'] = {
     'server' => true
   }

   consul['use_tls'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/server.crt.pem'
   consul['tls_key_file'] = '/path/to/server.key.pem'
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< tab title="Nœud client Consul" >}}

Ce qui suit peut être configuré sur un nœud Patroni, par exemple.

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   consul['enable'] = true
   consul['use_tls'] = true
   consul['tls_verify_client'] = true
   consul['tls_ca_file'] = '/path/to/ca.crt.pem'
   consul['tls_certificate_file'] = '/path/to/client.crt.pem'
   consul['tls_key_file'] = '/path/to/client.key.pem'
   consul['https_port'] = 8501

   patroni['consul']['url'] = 'https://localhost:8501'
   patroni['consul']['cacert'] = '/path/to/ca.crt.pem'
   patroni['consul']['cert'] = '/opt/tls/patroni.crt.pem'
   patroni['consul']['key'] = '/opt/tls/patroni.key.pem'
   patroni['consul']['verify'] = true
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

{{< /tab >}}

{{< /tabs >}}

### Chiffrement gossip {#gossip-encryption}

Le protocole Gossip peut être chiffré pour sécuriser la communication entre les agents Consul. Par défaut, le chiffrement n'est pas activé ; pour l'activer, une clé de chiffrement partagée est requise. Pour plus de commodité, la clé peut être générée en utilisant la commande `gitlab-ctl consul keygen`. La clé doit comporter 32 octets, être encodée en Base 64 et partagée sur tous les agents.

Les options suivantes fonctionnent sur les nœuds client et serveur.

Pour activer le protocole gossip :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   consul['encryption_key'] = <base-64-key>
   consul['encryption_verify_incoming'] = true
   consul['encryption_verify_outgoing'] = true
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

Pour [activer le chiffrement dans un datacenter existant](https://developer.hashicorp.com/consul/docs/security/encryption#enable-on-an-existing-consul-datacenter), définissez manuellement ces options pour une mise à jour progressive.

## Mettre à niveau les nœuds Consul {#upgrade-the-consul-nodes}

Pour mettre à niveau vos nœuds Consul, mettez à niveau le package GitLab.

Les nœuds doivent être :

- Membres d'un cluster sain avant la mise à niveau du package Linux.
- Mis à niveau un nœud à la fois.

Identifiez tout problème de santé existant dans le cluster en exécutant la commande suivante sur chaque nœud. La commande renvoie un tableau vide si le cluster est sain :

```shell
curl "http://127.0.0.1:8500/v1/health/state/critical"
```

Si la version de Consul a changé, un avis s'affiche à la fin de `gitlab-ctl reconfigure` vous informant que Consul doit être redémarré pour que la nouvelle version soit utilisée.

Redémarrez Consul un nœud à la fois :

```shell
sudo gitlab-ctl restart consul
```

Les nœuds Consul communiquent en utilisant le protocole raft. Si le leader actuel se déconnecte, une élection de leader doit avoir lieu. Un nœud leader doit exister pour faciliter la synchronisation au sein du cluster. Si trop de nœuds se déconnectent en même temps, le cluster perd le quorum et n'élit pas de leader en raison d'un [consensus rompu](https://developer.hashicorp.com/consul/docs/architecture/consensus).

Consultez la [section de dépannage](#troubleshooting-consul) si le cluster n'est pas en mesure de récupérer après la mise à niveau. La [récupération après panne](#outage-recovery) peut être particulièrement utile.

GitLab utilise Consul pour stocker uniquement des données transitoires facilement régénérables. Si le Consul intégré n'était utilisé par aucun processus autre que GitLab lui-même, vous pouvez [reconstruire le cluster from scratch](#recreate-from-scratch).

## Dépannage de Consul {#troubleshooting-consul}

Voici quelques opérations à effectuer si vous devez déboguer des problèmes. Vous pouvez consulter les journaux d'erreurs en exécutant :

```shell
sudo gitlab-ctl tail consul
```

### Vérifier l'appartenance au cluster {#check-the-cluster-membership}

Pour déterminer quels nœuds font partie du cluster, exécutez la commande suivante sur n'importe quel membre du cluster :

```shell
sudo /opt/gitlab/embedded/bin/consul members
```

Le résultat devrait être similaire à :

```plaintext
Node            Address               Status  Type    Build  Protocol  DC
consul-b        XX.XX.X.Y:8301        alive   server  0.9.0  2         gitlab_consul
consul-c        XX.XX.X.Y:8301        alive   server  0.9.0  2         gitlab_consul
consul-c        XX.XX.X.Y:8301        alive   server  0.9.0  2         gitlab_consul
db-a            XX.XX.X.Y:8301        alive   client  0.9.0  2         gitlab_consul
db-b            XX.XX.X.Y:8301        alive   client  0.9.0  2         gitlab_consul
```

Idéalement, tous les nœuds ont un `Status` `alive`.

### Redémarrer Consul {#restart-consul}

S'il est nécessaire de redémarrer Consul, il est important de le faire de manière contrôlée afin de maintenir le quorum. Si le quorum est perdu, pour récupérer le cluster, suivez le processus de [récupération après panne](#outage-recovery) de Consul.

Par mesure de sécurité, il est recommandé de ne redémarrer Consul que sur un nœud à la fois pour s'assurer que le cluster reste intact. Pour les clusters plus importants, il est possible de redémarrer plusieurs nœuds à la fois. Consultez le [document de consensus Consul](https://developer.hashicorp.com/consul/docs/architecture/consensus#deployment-table) pour connaître le nombre de défaillances qu'il peut tolérer. Il s'agit du nombre de redémarrages simultanés qu'il peut supporter.

Pour redémarrer Consul :

```shell
sudo gitlab-ctl restart consul
```

### Nœuds Consul incapables de communiquer {#consul-nodes-unable-to-communicate}

Par défaut, Consul tente de se [lier](https://developer.hashicorp.com/consul/docs/agent/config/config-files#bind_addr) à `0.0.0.0`, mais il annonce la première adresse IP privée du nœud pour que les autres nœuds Consul puissent communiquer avec lui. Si les autres nœuds ne peuvent pas communiquer avec un nœud sur cette adresse, le cluster a un statut d'échec.

Si vous rencontrez ce problème, des messages comme celui-ci s'affichent dans `gitlab-ctl tail consul` :

```plaintext
2017-09-25_19:53:39.90821     2017/09/25 19:53:39 [WARN] raft: no known peers, aborting election
2017-09-25_19:53:41.74356     2017/09/25 19:53:41 [ERR] agent: failed to sync remote state: No cluster leader
```

Pour résoudre ce problème :

1. Choisissez une adresse sur chaque nœud que tous les autres nœuds peuvent atteindre pour accéder à ce nœud.
1. Mettez à jour votre `/etc/gitlab/gitlab.rb`

   ```ruby
   consul['configuration'] = {
     ...
     bind_addr: 'IP ADDRESS'
   }
   ```

1. Reconfigurez GitLab ;

   ```shell
   gitlab-ctl reconfigure
   ```

Si vous voyez encore les erreurs, vous devrez peut-être [effacer la base de données Consul et la réinitialiser](#recreate-from-scratch) sur le nœud affecté.

### Consul ne démarre pas - plusieurs adresses IP privées {#consul-does-not-start---multiple-private-ips}

Si un nœud possède plusieurs adresses IP privées, Consul ne sait pas quelle adresse privée annoncer et se ferme immédiatement au démarrage.

Des messages comme le suivant s'affichent dans `gitlab-ctl tail consul` :

```plaintext
2017-11-09_17:41:45.52876 ==> Starting Consul agent...
2017-11-09_17:41:45.53057 ==> Error creating agent: Failed to get advertise address: Multiple private IPs found. Please configure one.
```

Pour résoudre ce problème :

1. Choisissez une adresse sur le nœud que tous les autres nœuds peuvent atteindre pour accéder à ce nœud.
1. Mettez à jour votre `/etc/gitlab/gitlab.rb`

   ```ruby
   consul['configuration'] = {
     ...
     bind_addr: 'IP ADDRESS'
   }
   ```

1. Reconfigurez GitLab ;

   ```shell
   gitlab-ctl reconfigure
   ```

### Récupération après panne {#outage-recovery}

Si vous avez perdu suffisamment de nœuds Consul dans le cluster pour rompre le quorum, le cluster est considéré comme défaillant et ne peut pas fonctionner sans intervention manuelle. Dans ce cas, vous pouvez soit recréer les nœuds from scratch, soit tenter une récupération.

#### Recréer from scratch {#recreate-from-scratch}

Par défaut, GitLab ne stocke rien dans le nœud Consul qui ne puisse pas être recréé. Pour effacer la base de données Consul et la réinitialiser :

```shell
sudo gitlab-ctl stop consul
sudo rm -rf /var/opt/gitlab/consul/data
sudo gitlab-ctl start consul
```

Après cela, le nœud devrait redémarrer et le reste des agents serveur devrait se reconnecter. Peu après, les agents client devraient également se reconnecter.

S'ils ne se reconnectent pas, vous devrez peut-être également effacer les données Consul sur le client :

```shell
sudo rm -rf /var/opt/gitlab/consul/data
```

#### Récupérer un nœud défaillant {#recover-a-failed-node}

Si vous avez utilisé Consul pour stocker d'autres données et souhaitez restaurer le nœud défaillant, suivez le [guide Consul](https://developer.hashicorp.com/consul/tutorials/operate-consul/recovery-outage) pour récupérer un cluster défaillant.
