---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Équilibreur de charge pour GitLab multi-nœuds
description: Utilisez un équilibreur de charge avec une instance multi-nœuds.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Dans une configuration GitLab multi-nœuds, vous avez besoin d'un équilibreur de charge pour acheminer le trafic vers les serveurs d'applications. Les détails concernant l'équilibreur de charge à utiliser ou la configuration exacte dépassent la portée de la documentation GitLab. Nous espérons que si vous gérez des systèmes HA comme GitLab, vous disposez déjà d'un équilibreur de charge de votre choix. Parmi les exemples, on trouve HAProxy (open source), F5 Big-IP LTM et Citrix NetScaler. Cette documentation décrit les ports et protocoles à utiliser avec GitLab.

## SSL {#ssl}

Comment souhaitez-vous gérer le SSL dans votre environnement multi-nœuds ? Il existe plusieurs options différentes :

- Chaque nœud d'application termine le SSL
- Les équilibreurs de charge terminent le SSL et la communication n'est pas sécurisée entre les équilibreurs de charge et les nœuds d'application
- Les équilibreurs de charge terminent le SSL et la communication est sécurisée entre les équilibreurs de charge et les nœuds d'application

### Les nœuds d'application terminent le SSL {#application-nodes-terminate-ssl}

Configurez vos équilibreurs de charge pour transmettre les connexions sur le port 443 avec le protocole 'TCP' plutôt que 'HTTP(S)'. Cela transmet la connexion au service NGINX des nœuds d'application sans modification. NGINX dispose du certificat SSL et écoute sur le port 443.

Consultez la [documentation HTTPS](https://docs.gitlab.com/omnibus/settings/ssl/) pour en savoir plus sur la gestion des certificats SSL et la configuration de NGINX.

### Les équilibreurs de charge terminent le SSL sans SSL backend {#load-balancers-terminate-ssl-without-backend-ssl}

Configurez vos équilibreurs de charge pour utiliser le protocole `HTTP(S)` plutôt que `TCP`. Les équilibreurs de charge sont responsables de la gestion des certificats SSL et de la terminaison SSL.

Étant donné que la communication entre les équilibreurs de charge et GitLab n'est pas sécurisée, une configuration supplémentaire est nécessaire. Consultez la [documentation SSL par proxy](https://docs.gitlab.com/omnibus/settings/ssl/#configure-a-reverse-proxy-or-load-balancer-ssl-termination) pour plus de détails.

### Les équilibreurs de charge terminent le SSL avec SSL backend {#load-balancers-terminate-ssl-with-backend-ssl}

Configurez vos équilibreurs de charge pour utiliser le protocole `HTTP(S)` plutôt que `TCP`. Les équilibreurs de charge sont responsables de la gestion des certificats SSL que voient les utilisateurs finaux.

Le trafic est sécurisé entre les équilibreurs de charge et NGINX dans ce scénario. Il n'est pas nécessaire d'ajouter une configuration pour le SSL par proxy, car la connexion est sécurisée de bout en bout. Cependant, une configuration doit être ajoutée à GitLab pour configurer les certificats SSL. Consultez la [documentation HTTPS](https://docs.gitlab.com/omnibus/settings/ssl/) pour en savoir plus sur la gestion des certificats SSL et la configuration de NGINX.

## Ports {#ports}

### Ports de base {#basic-ports}

| Port LB | Port backend | Protocole                 |
| ------- | ------------ | ------------------------ |
| 80      | 80           | HTTP (*1*)               |
| 443     | 443          | TCP ou HTTPS (*1*) (*2*) |
| 22      | 22           | TCP                      |

- (*1*) : Votre équilibreur de charge doit prendre en charge les connexions WebSocket pour des fonctionnalités telles que [GitLab Duo Non-Agentic Chat](../user/gitlab_duo_chat/_index.md), les mises à jour en temps réel des labels dans les tickets et les merge requests, et les [terminaux web](../ci/environments/_index.md#web-terminals-deprecated). Les équilibreurs de charge qui ne prennent pas en charge les WebSockets (par exemple, AWS Classic Load Balancers) ne sont pas compatibles avec GitLab pour ces fonctionnalités. Lors de l'utilisation du proxy HTTP ou HTTPS, votre équilibreur de charge doit être configuré pour transmettre les en-têtes hop-by-hop `Connection` et `Upgrade` aux serveurs backend. Cela fait référence au transfert d'en-têtes HTTP, et non au mode Direct Server Return (DSR).
- (*2*) : Lors de l'utilisation du protocole HTTPS pour le port 443, vous devez ajouter un certificat SSL aux équilibreurs de charge. Si vous souhaitez terminer le SSL au niveau du serveur d'application GitLab, utilisez le protocole TCP.

### Ports GitLab Pages {#gitlab-pages-ports}

Si vous utilisez GitLab Pages avec la prise en charge des domaines personnalisés, vous avez besoin de configurations de ports supplémentaires. GitLab Pages nécessite une adresse IP virtuelle distincte. Configurez le DNS pour pointer `pages_external_url` depuis `/etc/gitlab/gitlab.rb` vers la nouvelle adresse IP virtuelle. Consultez la [documentation GitLab Pages](pages/_index.md) pour plus d'informations.

| Port LB | Port backend  | Protocole  |
| ------- | ------------- | --------- |
| 80      | Variable (*1*)  | HTTP      |
| 443     | Variable (*1*)  | TCP (*2*) |

- (*1*) : Le port backend pour GitLab Pages dépend des paramètres `gitlab_pages['external_http']` et `gitlab_pages['external_https']`. Consultez la [documentation GitLab Pages](pages/_index.md) pour plus de détails.
- (*2*) : Le port 443 pour GitLab Pages doit toujours utiliser le protocole TCP. Les utilisateurs peuvent configurer des domaines personnalisés avec un SSL personnalisé, ce qui ne serait pas possible si le SSL était terminé au niveau de l'équilibreur de charge.

### Port SSH alternatif {#alternate-ssh-port}

Certaines organisations ont des politiques interdisant l'ouverture du port SSH 22. Dans ce cas, il peut être utile de configurer un nom d'hôte SSH alternatif permettant aux utilisateurs d'utiliser SSH sur le port 443. Un nom d'hôte SSH alternatif nécessite une nouvelle adresse IP virtuelle par rapport à l'autre configuration HTTP GitLab documentée précédemment.

Configurez le DNS pour un nom d'hôte SSH alternatif tel que `altssh.gitlab.example.com`.

| Port LB | Port backend | Protocole |
| ------- | ------------ | -------- |
| 443     | 22           | TCP      |

## Vérification de disponibilité {#readiness-check}

Il est fortement recommandé que les déploiements multi-nœuds configurent les équilibreurs de charge pour utiliser la [vérification de disponibilité](monitoring/health_check.md#readiness) afin de s'assurer qu'un nœud est prêt à accepter du trafic avant de lui en acheminer. Cela est particulièrement important lors de l'utilisation de Puma, car il existe une brève période pendant un redémarrage où Puma n'accepte pas les requêtes.

> [!warning]
> L'utilisation du paramètre `all=1` avec la vérification de disponibilité dans les versions GitLab 15.4 à 15.8 peut entraîner une [augmentation de l'utilisation de la mémoire Praefect](https://gitlab.com/gitlab-org/gitaly/-/issues/4751) et provoquer des erreurs de mémoire.

## Dépannage {#troubleshooting}

### Le contrôle de santé renvoie un code HTTP `408` via l'équilibreur de charge {#the-health-check-is-returning-a-408-http-code-via-the-load-balancer}

Si vous utilisez le [AWS Classic Load Balancer](https://docs.aws.amazon.com/en_en/elasticloadbalancing/latest/classic/elb-ssl-security-policy.html#ssl-ciphers) dans GitLab 15.0 ou version ultérieure, vous devez activer le chiffrement `AES256-GCM-SHA384` dans NGINX. Consultez [AES256-GCM-SHA384 SSL cipher no longer allowed by default by NGINX](../update/versions/gitlab_15_changes.md#1500) pour plus d'informations.

Les chiffrements par défaut pour une version de GitLab peuvent être consultés dans le fichier [`files/gitlab-cookbooks/gitlab/attributes/default.rb`](https://gitlab.com/gitlab-org/omnibus-gitlab/-/blob/master/files/gitlab-cookbooks/gitlab/attributes/default.rb) en sélectionnant le tag Git correspondant à votre version cible de GitLab (par exemple `15.0.5+ee.0`). Si votre équilibreur de charge l'exige, vous pouvez alors définir des [chiffrements SSL personnalisés](https://docs.gitlab.com/omnibus/settings/ssl/#use-custom-ssl-ciphers) pour NGINX.

### Certaines pages et certains liens sont téléchargés au lieu d'être affichés dans le navigateur {#some-pages-and-links-are-downloaded-instead-of-rendered-in-the-browser}

Certaines fonctionnalités de GitLab nécessitent l'utilisation des WebSockets. Dans certains scénarios où la prise en charge des WebSockets n'est pas activée sur votre équilibreur de charge, vous pourriez constater que certains liens ou pages sont téléchargés au lieu d'être affichés dans le navigateur. Les fichiers téléchargés peuvent contenir du contenu ressemblant à ce qui suit :

```plaintext
One or more reserved bits are on: reserved1 = 1, reserved2 = 0, reserved3 = 0
```

Votre équilibreur de charge doit être capable de prendre en charge les requêtes HTTP WebSocket. Si des liens sont téléchargés de cette façon, vérifiez la configuration de votre équilibreur de charge et assurez-vous que les requêtes HTTP WebSocket sont activées.
