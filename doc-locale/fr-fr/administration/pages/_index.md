---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Administration de GitLab Pages
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

GitLab Pages fournit un hébergement de sites statiques pour les projets et groupes GitLab. Les administrateurs de serveur doivent configurer Pages avant que les utilisateurs puissent accéder à cette fonctionnalité. Avec GitLab Pages, les administrateurs peuvent :

- Héberger des sites Web statiques en toute sécurité avec [des domaines personnalisés](#custom-domains) et des certificats SSL/TLS.
- Activer l'authentification pour contrôler l'accès aux sites Pages via les permissions GitLab.
- Mettre à l'échelle les déploiements en utilisant le stockage objet ou le stockage réseau dans des environnements multi-nœuds.
- Surveiller et gérer le trafic avec la limitation de débit et des en-têtes personnalisés.
- Prendre en charge les adresses IPv4 et IPv6 pour tous les sites Pages.

Le daemon GitLab Pages s'exécute en tant que processus distinct et peut être configuré soit sur le même serveur que GitLab, soit sur sa propre infrastructure dédiée. Pour la documentation utilisateur, voir [GitLab Pages](../../user/project/pages/_index.md).

> [!note]
> Ce guide est destiné aux installations de packages Linux. Pour les installations auto-compilées, voir [Administration de GitLab Pages pour les installations auto-compilées](source.md).

## Daemon GitLab Pages {#gitlab-pages-daemon}

GitLab Pages utilise le [daemon GitLab Pages](https://gitlab.com/gitlab-org/gitlab-pages), un serveur HTTP de base écrit en Go qui peut écouter sur une adresse IP externe et prendre en charge les [domaines personnalisés](#custom-domains) et les certificats personnalisés. Il prend en charge les certificats dynamiques via Server Name Indication (SNI) et expose les pages en utilisant HTTP2 par défaut.

Pour plus d'informations, voir le [README](https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md).

Lorsqu'il est utilisé avec des [domaines personnalisés](#custom-domains), le daemon Pages doit écouter sur les ports `80` ou `443`. Cela n'est pas requis pour les [domaines génériques](#wildcard-domains).

Vous pouvez exécuter le daemon Pages :

- Sur le même serveur que GitLab, en écoutant sur une IP secondaire.
- Sur un [serveur distinct](#running-gitlab-pages-on-a-separate-server). Le [chemin Pages](#change-storage-path) doit également être présent sur le serveur où le daemon Pages est installé, vous devez donc le partager sur le réseau.
- Sur le même serveur que GitLab, en écoutant sur la même IP mais sur des ports différents. Dans ce cas, vous devez proxifier le trafic avec un équilibreur de charge. Pour HTTPS, utilisez l'équilibrage de charge TCP. Si vous utilisez la terminaison TLS (équilibrage de charge HTTPS), les pages ne peuvent pas être servies avec des certificats fournis par l'utilisateur. Pour HTTP, l'équilibrage de charge HTTP ou TCP est acceptable.

Les sections suivantes supposent la première option. Si vous ne prenez pas en charge les domaines personnalisés, une IP secondaire n'est pas nécessaire.

## Prérequis {#prerequisites}

Cette section décrit les prérequis pour configurer GitLab Pages.

> [!note]
> Si votre instance GitLab et le daemon Pages sont déployés dans un réseau privé ou derrière un pare-feu, vos sites Web GitLab Pages ne sont accessibles qu'aux appareils et aux utilisateurs ayant accès au réseau privé.

### Domaines génériques {#wildcard-domains}

Chaque site obtient son propre sous-domaine (par exemple, `<namespace>.example.io/<project_slug>`). Ce sous-domaine nécessite un enregistrement DNS générique (`*.example.io`) et est la configuration recommandée pour la plupart des instances.

Avant de configurer Pages pour les domaines génériques, vous devez :

1. Avoir un domaine pour Pages qui n'est pas un sous-domaine de votre domaine d'instance GitLab.

   | Domaine GitLab        | Domaine Pages        | Est-ce que ça fonctionne ? |
   | -------------------- | ------------------- | ------------- |
   | `example.com`        | `example.io`        | {{< icon name="check-circle" >}} Oui |
   | `example.com`        | `pages.example.com` | {{< icon name="dotted-circle" >}} Non <sup>1</sup> |
   | `gitlab.example.com` | `pages.example.com` | {{< icon name="check-circle" >}} Oui |

   **Footnotes** :

   1. Si le domaine Pages est un sous-domaine de votre domaine d'instance GitLab, tous les sites Pages déployés peuvent accéder aux cookies de session GitLab.

1. Configurez un **wildcard DNS record**.
1. Facultatif. Avoir un **wildcard certificate** pour ce domaine si vous décidez de servir Pages sous HTTPS.
1. Facultatif mais recommandé. Activez les [runners d'instance](../../ci/runners/_index.md) afin que vos utilisateurs n'aient pas à apporter les leurs.
1. Pour les domaines personnalisés, avoir une **secondary IP**.

### Sites à domaine unique {#single-domain-sites}

Tous les sites partagent un domaine, avec l'espace de nommage et le slug du projet comme segments de chemin (par exemple, `example.io/<namespace>/<project_slug>`). Ce domaine ne nécessite qu'un seul enregistrement DNS `A`.

Avant de configurer Pages pour les sites à domaine unique, vous devez :

1. Avoir un domaine pour Pages qui n'est pas un sous-domaine de votre domaine d'instance GitLab.

   | Domaine GitLab        | Domaine Pages        | Pris en charge |
   | -------------------- | ------------------- | ------------- |
   | `example.com`        | `example.io`        | {{< icon name="check-circle" >}} Oui |
   | `example.com`        | `pages.example.com` | {{< icon name="dotted-circle" >}} Non <sup>1</sup> |
   | `gitlab.example.com` | `pages.example.com` | {{< icon name="check-circle" >}} Oui |

   **Footnotes** :

   1. Si le domaine Pages est un sous-domaine de votre domaine d'instance GitLab, tous les sites Pages déployés peuvent accéder aux cookies de session GitLab.

1. Configurez un **DNS record**.
1. Facultatif. Si vous décidez de servir Pages sous HTTPS, avoir un **TLS certificate** pour ce domaine.
1. Facultatif mais recommandé. Activez les [runners d'instance](../../ci/runners/_index.md) afin que vos utilisateurs n'aient pas à apporter les leurs.
1. Pour les domaines personnalisés, avoir une **secondary IP**.

### Ajouter le domaine à la liste des suffixes publics {#add-the-domain-to-the-public-suffix-list}

La [liste des suffixes publics](https://publicsuffix.org) est utilisée par les navigateurs pour décider comment traiter les sous-domaines. Si votre instance GitLab permet aux membres du public de créer des sites GitLab Pages, elle permet également à ces utilisateurs de créer des sous-domaines sur le domaine Pages (`example.io`). L'ajout du domaine à la liste des suffixes publics empêche les navigateurs d'accepter les [supercookies](https://en.wikipedia.org/wiki/HTTP_cookie#Supercookie), entre autres choses.

Pour soumettre votre sous-domaine GitLab Pages, voir [soumettre des amendements à la liste des suffixes publics](https://publicsuffix.org/submit/). Par exemple, si votre domaine est `example.io`, vous devriez demander que `example.io` soit ajouté à la liste des suffixes publics. GitLab.com a ajouté `gitlab.io` [en 2016](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/230).

### Configuration DNS {#dns-configuration}

GitLab Pages s'exécute sur son propre hôte virtuel. Dans votre serveur ou fournisseur DNS, ajoutez un [enregistrement DNS générique `A`](https://en.wikipedia.org/wiki/Wildcard_DNS_record) pointant vers l'hôte sur lequel GitLab s'exécute. Par exemple :

```plaintext
*.example.io. 1800 IN A    192.0.2.1
*.example.io. 1800 IN AAAA 2001:db8::1
```

Où `example.io` est le domaine depuis lequel GitLab Pages est servi, `192.0.2.1` est l'adresse IPv4 de votre instance GitLab, et `2001:db8::1` est l'adresse IPv6. Si vous n'avez pas d'IPv6, vous pouvez omettre l'enregistrement `AAAA`.

#### Configuration DNS pour les sites à domaine unique {#dns-configuration-for-single-domain-sites}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/17584) en tant qu'[expérience](../../policy/development_stages_support.md) dans GitLab 16.7.
- [Passé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148621) en [bêta](../../policy/development_stages_support.md) dans GitLab 16.11.
- [Modification](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1111) de l'implémentation de NGINX vers le code de GitLab Pages dans GitLab 17.2.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/483365) dans GitLab 17.4.

{{< /history >}}

Pour configurer le DNS de GitLab Pages pour les sites à domaine unique sans DNS générique :

1. Activez l'indicateur GitLab Pages pour cette fonctionnalité en ajoutant `gitlab_pages['namespace_in_path'] = true` à `/etc/gitlab/gitlab.rb`.
1. Dans votre fournisseur DNS, ajoutez des entrées pour `example.io`. Remplacez `example.io` par votre nom de domaine, et `192.0.0.0` par l'adresse IPv4 de votre instance :

   ```plaintext
   example.io          1800 IN A    192.0.0.0
   ```

1. Facultatif. Si votre instance GitLab a une adresse IPv6, ajoutez des entrées pour celle-ci. Remplacez `example.io` par votre nom de domaine, et `2001:db8::1` par l'adresse IPv6 de votre instance :

   ```plaintext
   example.io          1800 IN AAAA 2001:db8::1
   ```

   `example.io` est le domaine depuis lequel GitLab Pages est servi.

#### Configuration DNS pour les domaines personnalisés {#dns-configuration-for-custom-domains}

Si vous avez besoin de la prise en charge des domaines personnalisés, tous les sous-domaines du domaine racine Pages doivent pointer vers l'IP secondaire dédiée au daemon Pages. Sans cette configuration, les utilisateurs ne peuvent pas utiliser les enregistrements `CNAME` pour pointer leurs [domaines personnalisés](#custom-domains) vers leurs GitLab Pages.

Par exemple :

```plaintext
example.com   1800 IN A    192.0.2.1
*.example.io. 1800 IN A    192.0.2.2
```

Cet exemple contient :

- `example.com` :  Le domaine GitLab.
- `example.io` :  Le domaine depuis lequel GitLab Pages est servi.
- `192.0.2.1` :  L'IP principale de votre instance GitLab.
- `192.0.2.2` :  L'IP secondaire dédiée à GitLab Pages. Elle doit être différente de l'IP principale.

> [!note]
> N'utilisez pas le domaine GitLab pour servir les pages utilisateur. Pour plus d'informations, voir la [section sécurité](#security).

## Configuration {#configuration}

Vous pouvez configurer GitLab Pages de plusieurs façons. Les exemples suivants sont répertoriés de la configuration la plus simple à la plus avancée.

### Domaines génériques {#wildcard-domains-1}

Cette configuration est la configuration minimale pour utiliser GitLab Pages et sert de base pour toutes les autres configurations. Dans cette configuration :

- NGINX proxifie toutes les requêtes vers le daemon GitLab Pages.
- Le daemon GitLab Pages n'écoute pas directement sur l'internet public.

Prérequis :

- Vous avez configuré le [DNS générique](#dns-configuration).

Pour configurer GitLab Pages afin d'utiliser des domaines génériques :

1. Définissez l'URL externe pour GitLab Pages dans `/etc/gitlab/gitlab.rb` :

   ```ruby
   external_url "http://example.com" # external_url here is only for reference
   pages_external_url 'http://example.io' # Important: not a subdomain of external_url, so cannot be http://pages.example.com
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Le schéma d'URL résultant est `http://<namespace>.example.io/<project_slug>`.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une vue d'ensemble, voir la vidéo [activer GitLab Pages pour GitLab CE et EE](https://youtu.be/dD8c7WNcc6s).
<!-- Video published on 2017-02-22 -->

### Sites à domaine unique {#single-domain-sites-1}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/17584) en tant qu'[expérience](../../policy/development_stages_support.md) dans GitLab 16.7.
- [Passé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148621) en [bêta](../../policy/development_stages_support.md) dans GitLab 16.11.
- [Modification](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1111) de l'implémentation de NGINX vers le code de GitLab Pages dans GitLab 17.2.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/483365) dans GitLab 17.4.

{{< /history >}}

Cette configuration est la configuration minimale pour utiliser les sites à domaine unique et sert de base pour toutes les autres configurations à domaine unique. Dans cette configuration :

- NGINX proxifie toutes les requêtes vers le daemon GitLab Pages.
- Le daemon GitLab Pages n'écoute pas directement sur l'internet public.

Prérequis :

- Vous avez configuré le DNS pour les [sites à domaine unique](#dns-configuration-for-single-domain-sites).

Pour configurer GitLab Pages afin d'utiliser des sites à domaine unique :

1. Dans `/etc/gitlab/gitlab.rb`, définissez l'URL externe pour GitLab Pages et activez la fonctionnalité :

   ```ruby
   external_url "http://example.com" # Swap out this URL for your own
   pages_external_url 'http://example.io' # Important: not a subdomain of external_url, so cannot be http://pages.example.com

   # Set this flag to enable this feature
   gitlab_pages['namespace_in_path'] = true
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Le schéma d'URL résultant est `http://example.io/<namespace>/<project_slug>`.

> [!warning]
> GitLab Pages ne prend en charge qu'un seul schéma d'URL à la fois : les domaines génériques ou les sites à domaine unique. Si vous activez `namespace_in_path`, les sites Web GitLab Pages existants ne sont accessibles qu'en tant que sites à domaine unique.

### Domaines génériques avec prise en charge TLS {#wildcard-domains-with-tls-support}

NGINX proxifie toutes les requêtes vers le daemon. Le daemon Pages n'écoute pas sur l'internet public.

Un seul générique peut être attribué à une instance.

Prérequis :

- Vous avez configuré le [DNS générique](#dns-configuration).
- Vous avez un certificat TLS. Il peut s'agir d'un certificat générique ou de tout autre type répondant aux [exigences](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md#manually-add-ssltls-certificates).

Pour configurer les domaines génériques avec la prise en charge TLS :

1. Placez le certificat TLS générique pour `*.example.io` et la clé dans `/etc/gitlab/ssl`.
1. Dans `/etc/gitlab/gitlab.rb`, spécifiez la configuration suivante :

   ```ruby
   external_url "https://example.com" # external_url here is only for reference
   pages_external_url 'https://example.io' # Important: not a subdomain of external_url, so cannot be https://pages.example.com

   pages_nginx['redirect_http_to_https'] = true
   ```

1. Si votre certificat et votre clé ne sont pas nommés `example.io.crt` et `example.io.key`, ajoutez les chemins complets :

   ```ruby
   pages_nginx['ssl_certificate'] = "/etc/gitlab/ssl/pages-nginx.crt"
   pages_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/pages-nginx.key"
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
1. Si vous utilisez le [contrôle d'accès](#access-control) , mettez à jour l'URI de redirection dans l'[application OAuth système](../../integration/oauth_provider.md#create-an-instance-wide-application) de GitLab Pages pour utiliser le protocole HTTPS.

Le schéma d'URL résultant est `https://<namespace>.example.io/<project_slug>`.

> [!warning]
> GitLab Pages ne met pas à jour l'application OAuth si des modifications sont apportées à l'URI de redirection. Avant de reconfigurer, supprimez la section `gitlab_pages` de `/etc/gitlab/gitlab-secrets.json`, puis exécutez `gitlab-ctl reconfigure`. Pour plus d'informations, voir [GitLab Pages ne régénère pas OAuth](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3947).

### Sites à domaine unique avec prise en charge TLS {#single-domain-sites-with-tls-support}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/17584) en tant qu'[expérience](../../policy/development_stages_support.md) dans GitLab 16.7.
- [Passé](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148621) en [bêta](../../policy/development_stages_support.md) dans GitLab 16.11.
- [Modification](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/1111) de l'implémentation de NGINX vers le code de GitLab Pages dans GitLab 17.2.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/483365) dans GitLab 17.4.

{{< /history >}}

Dans cette configuration, NGINX proxifie toutes les requêtes vers le daemon. Le daemon GitLab Pages n'écoute pas sur l'internet public.

Prérequis :

- Vous avez configuré le DNS pour les [sites à domaine unique](#dns-configuration-for-single-domain-sites).
- Vous avez un certificat TLS qui couvre votre domaine (comme `example.io`).

Pour configurer les sites à domaine unique avec la prise en charge TLS :

1. Ajoutez votre certificat TLS et votre clé dans `/etc/gitlab/ssl`.
1. Dans `/etc/gitlab/gitlab.rb`, définissez l'URL externe pour GitLab Pages et activez la fonctionnalité :

   ```ruby
   external_url "https://example.com" # Swap out this URL for your own
   pages_external_url 'https://example.io' # Important: not a subdomain of external_url, so cannot be https://pages.example.com

   pages_nginx['redirect_http_to_https'] = true

   # Set this flag to enable this feature
   gitlab_pages['namespace_in_path'] = true
   ```

1. Si vos fichiers de certificat TLS ou de clé ont des noms différents de `example.io.crt` et `example.io.key`, ajoutez les chemins complets :

   ```ruby
   pages_nginx['ssl_certificate'] = "/etc/gitlab/ssl/pages-nginx.crt"
   pages_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/pages-nginx.key"
   ```

1. Si vous utilisez le [contrôle d'accès](#access-control) , mettez à jour l'URI de redirection dans l'[application OAuth système](../../integration/oauth_provider.md#create-an-instance-wide-application) de GitLab Pages pour utiliser le protocole HTTPS.

   > [!note]
   > GitLab Pages ne met pas à jour l'application OAuth, et le `auth_redirect_uri` par défaut est mis à jour vers `https://example.io/projects/auth`. Avant de reconfigurer, supprimez la section `gitlab_pages` de `/etc/gitlab/gitlab-secrets.json`, puis exécutez `gitlab-ctl reconfigure`. Pour plus d'informations, voir [GitLab Pages ne régénère pas OAuth](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/3947).

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Le schéma d'URL résultant est `https://example.io/<namespace>/<project_slug>`.

> [!warning]
> GitLab Pages ne prend en charge qu'un seul schéma d'URL à la fois : les domaines génériques ou les sites à domaine unique. Si vous activez `namespace_in_path`, les sites Web GitLab Pages existants ne sont accessibles qu'en tant que sites à domaine unique.

### Domaines génériques avec équilibreur de charge à terminaison TLS {#wildcard-domains-with-tls-terminating-load-balancer}

Utilisez cette configuration lors de l'installation d'un [POC GitLab sur Amazon Web Services](../../install/aws/_index.md). Cette configuration inclut un [équilibreur de charge classique](../../install/aws/_index.md#load-balancer) à terminaison TLS qui écoute les connexions HTTPS, gère les certificats TLS et transfère le trafic HTTP vers l'instance.

Prérequis :

- [DNS générique](#dns-configuration) configuré.
- Un équilibreur de charge à terminaison TLS.

Pour configurer des domaines génériques avec un équilibreur de charge à terminaison TLS :

1. Dans `/etc/gitlab/gitlab.rb`, spécifiez la configuration suivante :

   ```ruby
   external_url "https://example.com" # external_url here is only for reference
   pages_external_url 'https://example.io' # Important: not a subdomain of external_url, so cannot be https://pages.example.com

   pages_nginx['enable'] = true
   pages_nginx['listen_port'] = 80
   pages_nginx['listen_https'] = false
   pages_nginx['redirect_http_to_https'] = true
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Le schéma d'URL résultant est `https://<namespace>.example.io/<project_slug>`.

### Paramètres globaux {#global-settings}

Le tableau suivant explique tous les paramètres de configuration connus de Pages dans une installation de package Linux. Ces options peuvent être ajustées dans `/etc/gitlab/gitlab.rb`, et prennent effet après que vous [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation).

La plupart de ces paramètres n'ont pas à être configurés manuellement, sauf si vous avez besoin d'un contrôle plus granulaire sur la façon dont le daemon Pages s'exécute et sert le contenu dans votre environnement.

| Paramètre                                 | Valeur par défaut                                               | Description |
|-----------------------------------------|-------------------------------------------------------|-------------|
| `pages_external_url` <sup>1</sup>       | Non applicable                                        | L'URL où GitLab Pages est accessible, y compris le protocole (HTTP / HTTPS). Si `https://` est utilisé, une configuration supplémentaire est requise. Pour plus d'informations, voir [les domaines génériques avec prise en charge TLS](#wildcard-domains-with-tls-support) et [les domaines personnalisés avec prise en charge TLS](#custom-domains-with-tls-support). |
| **`gitlab_pages[]`**                    | Non applicable                                        |             |
| `access_control`                        | Non applicable                                        | Indique si le [contrôle d'accès](_index.md#access-control) doit être activé. |
| `api_secret_key`                        | Généré automatiquement                                        | Chemin complet vers le fichier avec la clé secrète utilisée pour s'authentifier auprès de l'API GitLab. |
| `artifacts_server`                      | Non applicable                                        | Activer la visualisation des [artefacts de job](../cicd/job_artifacts.md) dans GitLab Pages. |
| `artifacts_server_timeout`              | Non applicable                                        | Délai d'expiration (en secondes) pour une requête proxifiée vers le serveur d'artefacts. |
| `artifacts_server_url`                  | GitLab `external URL` + `/api/v4`                     | URL de l'API pour proxifier les requêtes d'artefacts, par exemple `https://gitlab.com/api/v4`. Lors de l'exécution d'un serveur Pages distinct, cette URL doit pointer vers l'API du serveur GitLab principal. |
| `auth_redirect_uri`                     | Sous-domaine du projet de `pages_external_url` + `/auth` | URL de rappel pour l'authentification avec GitLab. L'URL doit être un sous-domaine de `pages_external_url` + `/auth`, par exemple `https://projects.example.io/auth`. Lorsque `namespace_in_path` est activé, la valeur par défaut est `pages_external_url` + `/projects/auth`, par exemple `https://example.io/projects/auth`. |
| `auth_secret`                           | Extrait automatiquement de GitLab                               | Clé secrète pour signer les demandes d'authentification. Laissez vide pour extraire automatiquement de GitLab lors de l'enregistrement OAuth. |
| `client_cert`                           | Non applicable                                        | Certificat client utilisé pour le [TLS mutuel](#support-mutual-tls-when-calling-the-gitlab-api) avec l'API GitLab. |
| `client_key`                            | Non applicable                                        | Clé client utilisée pour le [TLS mutuel](#support-mutual-tls-when-calling-the-gitlab-api) avec l'API GitLab. |
| `client_ca_certs`                       | Non applicable                                        | Certificats CA racine utilisés pour signer le certificat client utilisé pour le [TLS mutuel](#support-mutual-tls-when-calling-the-gitlab-api) avec l'API GitLab. |
| `dir`                                   | Non applicable                                        | Répertoire de travail pour les fichiers de configuration et de secrets. |
| `enable`                                | Non applicable                                        | Activer ou désactiver GitLab Pages sur le système actuel. |
| `external_http`                         | Non applicable                                        | Configurer Pages pour se lier à une ou plusieurs adresses IP secondaires, servant les requêtes HTTP. Plusieurs adresses peuvent être données sous forme de tableau, ainsi que des ports exacts, par exemple `['1.2.3.4', '1.2.3.5:8063']`. Définit la valeur de `listen_http`. Si vous exécutez GitLab Pages derrière un proxy inverse avec terminaison TLS, spécifiez `listen_proxy` au lieu de `external_http`. |
| `external_https`                        | Non applicable                                        | Configurer Pages pour se lier à une ou plusieurs adresses IP secondaires, servant les requêtes HTTPS. Plusieurs adresses peuvent être données sous forme de tableau, ainsi que des ports exacts, par exemple `['1.2.3.4', '1.2.3.5:8063']`. Définit la valeur de `listen_https`. |
| `custom_domain_mode`                    | Non applicable                                        | Configurer Pages pour activer le domaine personnalisé : `http` ou `https`. Lors de l'exécution d'un serveur Pages distinct, configurez également ce paramètre sur le serveur GitLab. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/285089) dans GitLab 18.1. |
| `server_shutdown_timeout`               | `30s`                                                 | Délai d'arrêt du serveur GitLab Pages en secondes. |
| `gitlab_client_http_timeout`            | `60s`                                                 | Délai de connexion du client HTTP de l'API GitLab en secondes. |
| `gitlab_client_jwt_expiry`              | `30s`                                                 | Durée d'expiration du jeton JWT en secondes. |
| `gitlab_cache_expiry`                   | `600s`                                                | La durée maximale pendant laquelle la configuration d'un domaine est stockée dans le [cache](#gitlab-api-cache-configuration). |
| `gitlab_cache_refresh`                  | `60s`                                                 | L'intervalle auquel la configuration d'un domaine est programmée pour être actualisée. |
| `gitlab_cache_cleanup`                  | `60s`                                                 | L'intervalle auquel les éléments expirés sont supprimés du [cache](#gitlab-api-cache-configuration). |
| `gitlab_retrieval_timeout`              | `30s`                                                 | Le temps maximum d'attente d'une réponse de l'API GitLab par requête. |
| `gitlab_retrieval_interval`             | `1s`                                                  | L'intervalle d'attente avant de réessayer de résoudre la configuration d'un domaine en utilisant l'API GitLab. |
| `gitlab_retrieval_retries`              | `3`                                                   | Le nombre maximum de fois où la configuration d'un domaine est retentée en utilisant l'API GitLab. |
| `gitlab_id`                             | Rempli automatiquement                                           | L'ID public de l'application OAuth. Laissez vide pour remplir automatiquement lorsque Pages s'authentifie avec GitLab. |
| `gitlab_secret`                         | Rempli automatiquement                                           | Le secret de l'application OAuth. Laissez vide pour remplir automatiquement lorsque Pages s'authentifie avec GitLab. |
| `auth_scope`                            | `api`                                                 | La portée de l'application OAuth à utiliser pour l'authentification. Doit correspondre aux paramètres de l'application OAuth de GitLab Pages. Laissez vide pour utiliser la portée `api` par défaut. |
| `auth_timeout`                          | `5s`                                                  | Délai d'expiration du client de l'application GitLab pour l'authentification en secondes. Une valeur de `0` signifie aucun délai d'expiration. |
| `auth_cookie_session_timeout`           | `10m`                                                 | Délai d'expiration de la session du cookie d'authentification en secondes. Une valeur de `0` signifie que le cookie est supprimé après la fin de la session du navigateur. |
| `gitlab_server`                         | GitLab `external_url`                                 | Serveur à utiliser pour l'authentification lorsque le contrôle d'accès est activé. |
| `headers`                               | Non applicable                                        | Spécifier tous les en-têtes HTTP supplémentaires qui doivent être envoyés au client avec chaque réponse. Plusieurs en-têtes peuvent être donnés sous forme de tableau, l'en-tête et la valeur sous forme d'une seule chaîne. Par exemple `['my-header: myvalue', 'my-other-header: my-other-value']`. |
| `enable_disk`                           | Non applicable                                        | Permet au daemon GitLab Pages de servir du contenu depuis le disque. Désactiver si le stockage sur disque partagé n'est pas disponible. |
| `insecure_ciphers`                      | Non applicable                                        | Utiliser la liste par défaut des suites de chiffrement, qui peut contenir des chiffrements non sécurisés comme 3DES et RC4. |
| `internal_gitlab_server`                | GitLab `external_url`                                 | Adresse du serveur GitLab interne utilisée exclusivement pour les requêtes API. À utiliser si vous souhaitez envoyer ce trafic via un équilibreur de charge interne. |
| `listen_proxy`                          | Non applicable                                        | Les adresses sur lesquelles écouter les requêtes de proxy inverse. Pages se lie aux sockets réseau de ces adresses et reçoit les requêtes entrantes de celles-ci. Définit la valeur de `proxy_pass` dans `$nginx-dir/conf/gitlab-pages.conf`. |
| `log_directory`                         | Non applicable                                        | Chemin absolu vers un répertoire de journaux. |
| `log_format`                            | Non applicable                                        | Le format de sortie des journaux : `text` ou `json`. |
| `log_verbose`                           | Non applicable                                        | Journalisation détaillée, true/false. |
| `namespace_in_path`                     | `false`                                               | Activer ou désactiver l'espace de nommage dans le chemin d'URL pour prendre en charge la configuration DNS des sites à domaine unique. |
| `propagate_correlation_id`              | `false`                                               | Définir sur true pour réutiliser l'ID de corrélation existant de l'en-tête de requête entrante `X-Request-ID` s'il est présent. Si un proxy inverse définit cet en-tête, la valeur est propagée dans la chaîne de requêtes. |
| `max_connections`                       | Non applicable                                        | Limite du nombre de connexions simultanées aux écouteurs HTTP, HTTPS ou proxy. |
| `max_uri_length`                        | `2048`                                                | La longueur maximale des URI acceptés par GitLab Pages. Définir sur 0 pour une longueur illimitée. |
| `metrics_address`                       | Non applicable                                        | L'adresse sur laquelle écouter les requêtes de métriques. |
| `redirect_http`                         | Non applicable                                        | Rediriger les pages de HTTP vers HTTPS, true/false. |
| `redirects_max_config_size`             | `65536`                                               | La taille maximale du fichier `_redirects`, en octets. |
| `redirects_max_path_segments`           | `25`                                                  | Le nombre maximum de segments de chemin autorisés dans les URL des règles `_redirects`. |
| `redirects_max_rule_count`              | `1000`                                                | Le nombre maximum de règles autorisées dans `_redirects`. |
| `sentry_dsn`                            | Non applicable                                        | L'adresse pour envoyer les rapports de pannes Sentry. |
| `sentry_enabled`                        | Non applicable                                        | Activer les rapports et la journalisation avec Sentry, true/false. |
| `sentry_environment`                    | Non applicable                                        | L'environnement pour les rapports de pannes Sentry. |
| `status_uri`                            | Non applicable                                        | Le chemin d'URL pour une page de statut, par exemple, `/@status`. Configurer pour activer le point de terminaison de vérification de l'état sur GitLab Pages. |
| `tls_max_version`                       | Non applicable                                        | Spécifie la version TLS maximale ("tls1.2" ou "tls1.3"). |
| `tls_min_version`                       | Non applicable                                        | Spécifie la version TLS minimale ("tls1.2" ou "tls1.3"). |
| `use_http2`                             | Non applicable                                        | Activer la prise en charge HTTP2. |
| **`gitlab_pages['env'][]`**             | Non applicable                                        |             |
| `http_proxy`                            | Non applicable                                        | Configurer GitLab Pages pour utiliser un proxy HTTP afin de gérer le trafic entre Pages et GitLab. Définit une variable d'environnement `http_proxy` lors du démarrage du daemon Pages. |
| **`gitlab_rails[]`**                    | Non applicable                                        |             |
| `pages_domain_verification_cron_worker` | Non applicable                                        | Planification pour la vérification des domaines personnalisés de GitLab Pages. |
| `pages_domain_ssl_renewal_cron_worker`  | Non applicable                                        | Planification pour l'obtention et le renouvellement des certificats SSL via Let's Encrypt pour les domaines GitLab Pages. |
| `pages_domain_removal_cron_worker`      | Non applicable                                        | Planification pour la suppression des domaines personnalisés GitLab Pages non vérifiés. |
| `pages_path`                            | `GITLAB-RAILS/shared/pages`                           | Le répertoire sur le disque où les pages sont stockées. |
| **`pages_nginx[]`**                     | Non applicable                                        |             |
| `enable`                                | Non applicable                                        | Inclure un bloc d'hôte virtuel `server{}` pour Pages dans NGINX. Nécessaire pour que NGINX proxifie le trafic vers le daemon Pages. Définir sur `false` si le daemon Pages doit recevoir directement toutes les requêtes, par exemple, lors de l'utilisation des [domaines personnalisés](_index.md#custom-domains). |
| `FF_CONFIGURABLE_ROOT_DIR`              | Non applicable                                        | Indicateur de fonctionnalité pour [personnaliser le dossier par défaut](../../user/project/pages/introduction.md#customize-the-default-folder) (activé par défaut). |
| `FF_ENABLE_PLACEHOLDERS`                | Non applicable                                        | Indicateur de fonctionnalité pour les réécritures (activé par défaut). Pour plus d'informations, voir [les réécritures](../../user/project/pages/redirects.md#rewrites). |
| `rate_limit_source_ip`                  | Non applicable                                        | Limite de débit par IP source en nombre de requêtes par seconde. Définir sur `0` pour désactiver cette fonctionnalité. |
| `rate_limit_source_ip_burst`            | Non applicable                                        | Limite de débit par IP source, rafale maximale autorisée par seconde. |
| `rate_limit_domain`                     | Non applicable                                        | Limite de débit par domaine en nombre de requêtes par seconde. Définir sur `0` pour désactiver cette fonctionnalité. |
| `rate_limit_domain_burst`               | Non applicable                                        | Limite de débit par domaine, rafale maximale autorisée par seconde. |
| `rate_limit_tls_source_ip`              | Non applicable                                        | Limite de débit par IP source en nombre de connexions TLS par seconde. Définir sur `0` pour désactiver cette fonctionnalité. |
| `rate_limit_tls_source_ip_burst`        | Non applicable                                        | Limite de débit par IP source, rafale maximale de connexions TLS autorisée par seconde. |
| `rate_limit_tls_domain`                 | Non applicable                                        | Limite de débit par domaine en nombre de connexions TLS par seconde. Définir sur `0` pour désactiver cette fonctionnalité. |
| `rate_limit_tls_domain_burst`           | Non applicable                                        | Limite de débit par domaine, rafale maximale de connexions TLS autorisée par seconde. |
| `rate_limit_subnets_allow_list`         | Non applicable                                        | Liste d'autorisation avec les plages d'IP (sous-réseaux) qui doivent contourner toutes les limites de débit. Par exemple, `['1.2.3.4/24', '2001:db8::1/32']`. [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/14653) dans GitLab 17.3. |
| `server_read_timeout`                   | `5s`                                                  | Durée maximale pour lire les en-têtes et le corps de la requête. Pour aucun délai d'expiration, définir sur `0` ou une valeur négative. |
| `server_read_header_timeout`            | `1s`                                                  | Durée maximale pour lire les en-têtes de la requête. Pour aucun délai d'expiration, définir sur `0` ou une valeur négative. |
| `server_write_timeout`                  | `0`                                                   | Durée maximale pour écrire tous les fichiers dans la réponse. Les fichiers plus volumineux nécessitent plus de temps. Pour aucun délai d'expiration, définir sur `0` ou une valeur négative. |
| `server_keep_alive`                     | `15s`                                                 | La période `Keep-Alive` pour les connexions réseau acceptées par cet écouteur. Si `0`, `Keep-Alive` est activé s'il est pris en charge par le protocole et le système d'exploitation. Si négatif, `Keep-Alive` est désactivé. |

**Footnotes** :

1. Lorsque vous utilisez un nœud Sidekiq externe, vous devez ajouter `pages_external_url` à votre configuration. Sans ce paramètre, le nœud Sidekiq externe ne peut pas traiter les jobs de déploiement.

## Configuration avancée {#advanced-configuration}

En plus des domaines génériques, vous pouvez configurer GitLab Pages pour travailler avec des domaines personnalisés, avec ou sans certificats TLS. Dans les deux cas, vous avez besoin d'une **secondary IP**. Si vous avez à la fois des adresses IPv6 et IPv4, vous pouvez les utiliser toutes les deux.

### Domaines personnalisés {#custom-domains}

Par défaut, les sites GitLab Pages sont servis sur un sous-domaine du domaine racine Pages, par exemple, `namespace.example.io/project`. Pour configurer un domaine personnalisé pour un site Pages, ajoutez un enregistrement DNS CNAME qui pointe votre propre domaine (par exemple, `example-custom-site-here.com`) vers GitLab Pages.

Si vous n'avez besoin que des URL de sous-domaine `*.example.io` par défaut, vous n'avez pas besoin de configurer la prise en charge des domaines personnalisés.

Dans cette configuration, le daemon Pages est en cours d'exécution et NGINX proxifie les requêtes vers celui-ci, mais le daemon peut également recevoir des requêtes de l'internet public. Les domaines personnalisés sont pris en charge sans TLS.

Prérequis :

- [DNS générique](#dns-configuration) configuré.
- Une IP secondaire.

Pour configurer des domaines personnalisés :

1. Dans `/etc/gitlab/gitlab.rb`, spécifiez la configuration suivante :

   ```ruby
   external_url "http://example.com" # external_url here is only for reference
   pages_external_url 'http://example.io' # Important: not a subdomain of external_url, so cannot be http://pages.example.com
   nginx['listen_addresses'] = ['192.0.2.1'] # The primary IP of the GitLab instance
   pages_nginx['enable'] = false
   gitlab_pages['external_http'] = ['192.0.2.2:80', '[2001:db8::2]:80'] # The secondary IPs for the GitLab Pages daemon
   gitlab_pages['custom_domain_mode'] = 'http' # Enable custom domain
   ```

   Si vous n'avez pas d'IPv6, omettez l'adresse IPv6.

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Les schémas d'URL résultants sont `http://<namespace>.example.io/<project_slug>` et `http://custom-domain.com`.

### Domaines personnalisés avec prise en charge TLS {#custom-domains-with-tls-support}

Dans cette configuration, le daemon Pages est en cours d'exécution et NGINX proxifie les requêtes vers celui-ci, mais le daemon peut également recevoir des requêtes de l'internet public. Les domaines personnalisés et TLS sont pris en charge.

Prérequis :

- [DNS générique](#dns-configuration) configuré.
- Un certificat TLS. Il peut s'agir d'un certificat générique ou de tout autre type répondant aux [exigences](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md#manually-add-ssltls-certificates).
- Une IP secondaire.

Pour configurer des domaines personnalisés avec prise en charge TLS :

1. Placez le certificat TLS générique pour `*.example.io` et la clé dans `/etc/gitlab/ssl`.
1. Dans `/etc/gitlab/gitlab.rb`, spécifiez la configuration suivante :

   ```ruby
   external_url "https://example.com" # external_url here is only for reference
   pages_external_url 'https://example.io' # Important: not a subdomain of external_url, so cannot be https://pages.example.com
   nginx['listen_addresses'] = ['192.0.2.1'] # The primary IP of the GitLab instance
   pages_nginx['enable'] = false
   gitlab_pages['external_http'] = ['192.0.2.2:80', '[2001:db8::2]:80'] # The secondary IPs for the GitLab Pages daemon
   gitlab_pages['external_https'] = ['192.0.2.2:443', '[2001:db8::2]:443'] # The secondary IPs for the GitLab Pages daemon
   gitlab_pages['custom_domain_mode'] = 'https' # Enable custom domain
   # Redirect pages from HTTP to HTTPS
   gitlab_pages['redirect_http'] = true
   ```

   Si vous n'avez pas d'IPv6, omettez l'adresse IPv6.

1. Si votre certificat et votre clé ne sont pas nommés `example.io.crt` et `example.io.key`, ajoutez les chemins complets :

   ```ruby
   gitlab_pages['cert'] = "/etc/gitlab/ssl/example.io.crt"
   gitlab_pages['cert_key'] = "/etc/gitlab/ssl/example.io.key"
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
1. Si vous utilisez le contrôle d'accès, modifiez l'URI de redirection dans l'[application OAuth système](../../integration/oauth_provider.md#create-an-instance-wide-application) de GitLab Pages pour utiliser le protocole HTTPS.

### Vérification de domaine personnalisé {#custom-domain-verification}

Pour empêcher les utilisateurs malveillants de détourner des domaines qui ne leur appartiennent pas, GitLab prend en charge la [vérification de domaine personnalisé](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md). Lors de l'ajout d'un domaine personnalisé, les utilisateurs doivent prouver qu'ils en sont propriétaires en ajoutant un code de vérification contrôlé par GitLab aux enregistrements DNS de ce domaine.

> [!warning]
> Désactiver la vérification de domaine est dangereux et peut entraîner diverses vulnérabilités. Si vous le désactivez, assurez-vous que le domaine racine Pages lui-même ne pointe pas vers l'IP secondaire, ou ajoutez le domaine racine en tant que domaine personnalisé à un projet. Sinon, n'importe quel utilisateur peut ajouter ce domaine en tant que domaine personnalisé à son projet.

Si votre base d'utilisateurs est privée ou autrement fiable, vous pouvez désactiver l'exigence de vérification :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Pages**.
1. Décochez la case **Exiger des utilisateurs qu'ils prouvent qu'ils sont propriétaires de domaines personnalisés**. Ce paramètre est activé par défaut.

### Intégration de Let's Encrypt {#lets-encrypt-integration}

[L'intégration de Let's Encrypt dans GitLab Pages](../../user/project/pages/custom_domains_ssl_tls_certification/lets_encrypt_integration.md) permet aux utilisateurs d'ajouter des certificats SSL Let's Encrypt pour les sites GitLab Pages servis sous un domaine personnalisé.

Pour l'activer :

1. Choisissez une adresse e-mail pour recevoir des notifications sur les domaines expirant.
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Pages**.
1. Saisissez l'adresse e-mail pour recevoir des notifications et acceptez les Conditions d'utilisation de Let's Encrypt.
1. Sélectionnez **Sauvegarder les modifications**.

### Contrôle d'accès {#access-control}

Le contrôle d'accès de GitLab Pages peut être configuré par projet et permet de contrôler l'accès à un site Pages en fonction de l'appartenance d'un utilisateur à ce projet.

Le contrôle d'accès fonctionne en enregistrant le daemon Pages comme une application OAuth auprès de GitLab. Chaque fois qu'un utilisateur non authentifié demande l'accès à un site Pages privé, le daemon Pages redirige l'utilisateur vers GitLab. Si l'authentification réussit, l'utilisateur est redirigé vers Pages avec un jeton, qui est conservé dans un cookie. Les cookies sont signés avec une clé secrète, ce qui permet de détecter toute altération.

Chaque requête pour voir une ressource sur un site privé est authentifiée par Pages à l'aide de ce jeton. Pour chaque requête reçue, Pages effectue une requête à l'API GitLab pour vérifier que l'utilisateur est autorisé à lire ce site.

Le contrôle d'accès de Pages est désactivé par défaut. Pour l'activer :

1. Dans `/etc/gitlab/gitlab.rb`, ajoutez :

   ```ruby
   gitlab_pages['access_control'] = true
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
1. Les utilisateurs peuvent maintenant le configurer dans les [paramètres de leurs projets](../../user/project/pages/pages_access_control.md).

> [!note]
> Pour que ce paramètre soit efficace avec les configurations multi-nœuds, appliquez-le à tous les nœuds App et aux nœuds Sidekiq.

#### Utilisation de Pages avec une portée d'authentification réduite {#using-pages-with-reduced-authentication-scope}

Vous pouvez configurer la portée que le daemon Pages utilise pour s'authentifier. Par défaut, il utilise la portée `api`.

Par exemple, ceci réduit la portée à `read_api` dans `/etc/gitlab/gitlab.rb` :

```ruby
gitlab_pages['auth_scope'] = 'read_api'
```

La portée à utiliser pour l'authentification doit correspondre aux paramètres de l'application OAuth de GitLab Pages. Les utilisateurs des applications préexistantes doivent modifier l'application OAuth de GitLab Pages.

Prérequis :

- Vous avez activé le [contrôle d'accès](#access-control).

Pour modifier la portée utilisée par Pages :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Applications**.
1. Développez **GitLab Pages**.
1. Décochez la case de la portée `api` et sélectionnez la case de la portée souhaitée (par exemple, `read_api`).
1. Sélectionnez **Sauvegarder les modifications**.

#### Désactiver l'accès public à tous les sites Pages {#disable-public-access-to-all-pages-sites}

Vous pouvez appliquer le contrôle d'accès pour tous les sites Web GitLab Pages hébergés sur votre instance GitLab. Lorsque vous activez ce paramètre, seuls les utilisateurs authentifiés peuvent accéder aux sites Web Pages. Tous les projets perdent l'option de niveau de visibilité **Tout le monde** et sont limités aux membres du projet ou à toute personne ayant accès, selon le paramètre de visibilité du projet.

Utilisez ce paramètre pour restreindre les informations publiées avec Pages aux seuls utilisateurs de votre instance.

Prérequis :

- Accès administrateur à l'instance.
- Contrôle d'accès activé pour que le paramètre s'affiche dans la zone d'administration.

Pour désactiver l'accès public à tous les sites Pages :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Pages**.
1. Cochez la case **Désactiver l'accès public aux sites Pages**.
1. Sélectionnez **Sauvegarder les modifications**.

#### Désactiver les domaines uniques par défaut {#disable-unique-domains-by-default}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/555559) dans GitLab 18.3.

{{< /history >}}

Par défaut, tous les sites GitLab Pages nouvellement créés utilisent des URL de domaine uniques (par exemple, `my-project-1a2b3c.example.com`), ce qui empêche le partage de cookies entre différents sites sous le même space de nommage.

Vous pouvez désactiver ce comportement par défaut afin que les nouveaux sites Pages utilisent des URL basées sur le chemin (par exemple, `my-namespace.example.com/my-project`) à la place. Cependant, cette approche présente le risque de partage de cookies entre différents sites sous le même space de nommage.

Ce paramètre contrôle le comportement par défaut uniquement pour les nouveaux sites. Les utilisateurs peuvent toujours remplacer ce paramètre pour des projets individuels.

Prérequis :

- Vous devez avoir un accès administrateur à l'instance.

Pour désactiver les domaines uniques par défaut :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Pages**.
1. Décochez la case **Activer par défaut les domaines uniques**.
1. Sélectionnez **Sauvegarder les modifications**.

Ce paramètre n'affecte que les nouveaux sites Pages. Les sites existants conservent leur configuration de domaine unique actuelle.

### Exécution derrière un proxy {#running-behind-a-proxy}

Vous pouvez utiliser GitLab Pages dans des environnements où la connectivité internet externe est contrôlée par un proxy.

Pour utiliser un proxy pour GitLab Pages :

1. Dans `/etc/gitlab/gitlab.rb`, ajoutez :

   ```ruby
   gitlab_pages['env']['http_proxy'] = 'http://example:8080'
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

### Utilisation d'une autorité de certification (CA) personnalisée {#using-a-custom-certificate-authority-ca}

Lors de l'utilisation de certificats émis par une CA personnalisée, le contrôle d'accès et la [vue en ligne des artefacts de job HTML](../../ci/jobs/job_artifacts.md#download-job-artifacts) ne fonctionnent pas si la CA personnalisée n'est pas reconnue.

Cela génère généralement cette erreur :

```plaintext
Post /oauth/token: x509: certificate signed by unknown authority
```

Pour résoudre ce problème :

- Pour les installations de packages Linux, [installez une CA personnalisée](https://docs.gitlab.com/omnibus/settings/ssl/#install-custom-public-certificates).
- Pour les installations auto-compilées, installez la CA personnalisée dans le magasin de certificats du système.

### Prise en charge du TLS mutuel lors de l'appel à l'API GitLab {#support-mutual-tls-when-calling-the-gitlab-api}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab-pages/-/issues/548) dans GitLab 17.1.

{{< /history >}}

Si GitLab est [configuré pour exiger le TLS mutuel](https://docs.gitlab.com/omnibus/settings/ssl/#enable-2-way-ssl-client-authentication), vous devez ajouter des certificats client à votre configuration GitLab Pages.

Les certificats ont ces exigences :

- Le certificat doit spécifier le nom d'hôte ou l'adresse IP en tant que Subject Alternative Name.
- La chaîne de certificats complète est requise, incluant le certificat de l'utilisateur final, les certificats intermédiaires et le certificat racine, dans cet ordre.

Le champ Common Name du certificat est ignoré.

Prérequis :

- Votre instance utilise la méthode d'installation du package Linux.

Pour configurer les certificats dans votre serveur GitLab Pages :

1. Sur les nœuds GitLab Pages, créez le répertoire `/etc/gitlab/ssl` et copiez-y votre clé et la chaîne de certificats complète :

   ```shell
   sudo mkdir -p /etc/gitlab/ssl
   sudo chmod 755 /etc/gitlab/ssl
   sudo cp key.pem cert.pem /etc/gitlab/ssl/
   sudo chmod 644 key.pem cert.pem
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_pages['client_cert'] = ['/etc/gitlab/ssl/cert.pem']
   gitlab_pages['client_key'] = ['/etc/gitlab/ssl/key.pem']
   ```

1. Si vous avez utilisé une CA personnalisée, copiez le certificat CA racine dans `/etc/gitlab/ssl` et modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_pages['client_ca_certs'] = ['/etc/gitlab/ssl/ca.pem']
   ```

   Les chemins de fichiers pour plusieurs autorités de certification personnalisées sont séparés par des virgules.

1. Si vous avez une installation GitLab Pages multi-nœuds, répétez ces étapes sur tous les nœuds.
1. Enregistrez une copie des fichiers de chaîne de certificats complète dans le répertoire `/etc/gitlab/trusted-certs` sur tous vos nœuds GitLab.

### Configuration du service ZIP et du cache {#zip-serving-and-cache-configuration}

> [!warning]
> Les valeurs par défaut recommandées sont définies dans GitLab Pages. Ne modifiez ces paramètres que si c'est absolument nécessaire.

GitLab Pages peut diffuser du contenu depuis des archives ZIP via le stockage d'objets. Il utilise un cache en mémoire pour améliorer les performances lors de la diffusion de contenu depuis une archive ZIP. Vous pouvez modifier le comportement du cache en changeant les indicateurs de configuration suivants.

| Paramètre | Description |
| ------- | ----------- |
| `zip_cache_expiration` | L'intervalle d'expiration du cache des archives ZIP. Doit être supérieur à zéro pour éviter de diffuser du contenu périmé. La valeur par défaut est `60s`. |
| `zip_cache_cleanup` | L'intervalle auquel les archives sont supprimées de la mémoire après leur expiration. La valeur par défaut est `30s`. |
| `zip_cache_refresh` | L'intervalle de temps pendant lequel une archive est prolongée en mémoire si elle est consultée avant `zip_cache_expiration`. Fonctionne conjointement avec `zip_cache_expiration` pour déterminer si une archive est prolongée en mémoire. Pour plus d'informations, consultez [l'exemple de rafraîchissement du cache ZIP](#zip-cache-refresh-example). La valeur par défaut est `30s`. |
| `zip_open_timeout` | Le temps maximum autorisé pour ouvrir une archive ZIP. Augmentez cette valeur pour les archives volumineuses ou les connexions réseau lentes. La valeur par défaut est `30s`. |
| `zip_http_client_timeout` | Le temps maximum pour le client HTTP ZIP. La valeur par défaut est `30m`. |

#### Exemple de rafraîchissement du cache ZIP {#zip-cache-refresh-example}

Les archives sont rafraîchies dans le cache (prolongeant le temps où elles sont conservées en mémoire) si elles sont consultées avant `zip_cache_expiration`, et si le temps restant avant l'expiration est inférieur ou égal à `zip_cache_refresh`. Par exemple, si `archive.zip` est consulté à l'instant `0s`, il expire dans `60s` (la valeur par défaut de `zip_cache_expiration`). Si l'archive est ouverte à nouveau après `15s`, elle n'est pas rafraîchie car le temps restant avant l'expiration (`45s`) est supérieur à `zip_cache_refresh` (par défaut `30s`). Cependant, si l'archive est consultée à nouveau après `45s` (depuis la première fois qu'elle a été ouverte), elle est rafraîchie. Cela prolonge le temps de conservation de l'archive en mémoire de `45s + zip_cache_expiration
(60s)`, pour un total de `105s`.

Lorsqu'une archive atteint `zip_cache_expiration`, elle est marquée comme expirée et supprimée lors du prochain intervalle `zip_cache_cleanup`.

![Une frise chronologique montre que le rafraîchissement du cache ZIP prolonge le temps d'expiration du cache ZIP.](img/zip_cache_configuration_v13_7.png)

### Prise en charge de HTTP Strict Transport Security (HSTS) {#http-strict-transport-security-hsts-support}

HTTP Strict Transport Security (HSTS) peut être activé via l'option de configuration `gitlab_pages['headers']`. HSTS informe les navigateurs que le site Web doit toujours être consulté via HTTPS, empêchant les attaquants de forcer des connexions non chiffrées. Il peut également améliorer la vitesse de chargement des pages en empêchant les navigateurs de tenter une connexion HTTP non chiffrée avant d'être redirigés vers HTTPS.

```ruby
gitlab_pages['headers'] = ['Strict-Transport-Security: max-age=63072000']
```

### Limites de redirection du projet Pages {#pages-project-redirect-limits}

GitLab Pages a des limites par défaut pour le [fichier `_redirects`](../../user/project/pages/redirects.md) afin de minimiser l'impact sur les performances.

Pour ajuster les limites :

```ruby
gitlab_pages['redirects_max_config_size'] = 131072
gitlab_pages['redirects_max_path_segments'] = 50
gitlab_pages['redirects_max_rule_count'] = 2000
```

## Utiliser des variables d'environnement {#use-environment-variables}

Vous pouvez passer une variable d'environnement au démon Pages pour activer ou désactiver un feature flag.

Pour désactiver la fonctionnalité de répertoire configurable :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_pages['env'] = {
     'FF_CONFIGURABLE_ROOT_DIR' => "false"
   }
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

## Activer la journalisation détaillée pour le démon {#activate-verbose-logging-for-daemon}

Pour configurer la journalisation détaillée du démon GitLab Pages :

1. Par défaut, le démon journalise uniquement avec le niveau `INFO`. Pour journaliser les événements avec le niveau `DEBUG`, modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_pages['log_verbose'] = true
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

## Propagation de l'ID de corrélation {#propagating-the-correlation-id}

Définir `propagate_correlation_id` sur `true` permet aux installations situées derrière un proxy inverse de générer et de définir un ID de corrélation sur les requêtes envoyées à GitLab Pages. Lorsqu'un proxy inverse définit la valeur d'en-tête `X-Request-ID`, la valeur se propage dans la chaîne de requêtes. Les utilisateurs peuvent [trouver l'ID de corrélation dans les journaux](../logs/tracing_correlation_id.md#identify-the-correlation-id-for-a-request).

Pour activer la propagation de l'ID de corrélation :

1. Dans `/etc/gitlab/gitlab.rb`, ajoutez :

   ```ruby
   gitlab_pages['propagate_correlation_id'] = true
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

## Modifier le chemin de stockage {#change-storage-path}

Pour modifier le chemin par défaut où le contenu de GitLab Pages est stocké :

1. Les pages sont stockées par défaut dans `/var/opt/gitlab/gitlab-rails/shared/pages`. Pour utiliser un emplacement différent, modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['pages_path'] = "/mnt/storage/pages"
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

## Configurer l'écouteur pour les requêtes de proxy inverse {#configure-listener-for-reverse-proxy-requests}

Pour configurer l'écouteur de proxy de GitLab Pages :

1. Par défaut, l'écouteur est configuré pour écouter les requêtes sur `localhost:8090`.

   Pour le désactiver, modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_pages['listen_proxy'] = nil
   ```

   Pour modifier le port, modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_pages['listen_proxy'] = "localhost:10080"
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

## Définir la taille maximale globale de chaque site GitLab Pages {#set-global-maximum-size-of-each-gitlab-pages-site}

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Prérequis :

- Vous devez avoir un accès administrateur à l'instance.

Pour définir la taille maximale globale des pages pour un projet :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Pages**.
1. Dans **Maximum size of pages**, saisissez une valeur. La valeur par défaut est `100`.
1. Sélectionnez **Sauvegarder les modifications**.

## Définir la taille maximale de chaque site GitLab Pages dans un groupe {#set-maximum-size-of-each-gitlab-pages-site-in-a-group}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Prérequis :

- Vous devez avoir un accès administrateur à l'instance.

Pour définir la taille maximale de chaque site GitLab Pages dans un groupe, en remplaçant le paramètre hérité :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre groupe.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Pages**.
1. Saisissez une valeur sous **Maximum size** en Mo.
1. Sélectionnez **Sauvegarder les modifications**.

## Définir la taille maximale du site GitLab Pages dans un projet {#set-maximum-size-of-gitlab-pages-site-in-a-project}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Prérequis :

- Vous devez avoir un accès administrateur à l'instance.

Pour définir la taille maximale d'un site GitLab Pages dans un projet, en remplaçant le paramètre hérité :

1. Dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Dans la barre latérale gauche, sélectionnez **Déploiement** > **Pages**.
1. Dans **Maximum size of pages**, saisissez la taille en Mo.
1. Sélectionnez **Sauvegarder les modifications**.

## Définir le nombre maximum de domaines personnalisés GitLab Pages pour un projet {#set-maximum-number-of-gitlab-pages-custom-domains-for-a-project}

Prérequis :

- Vous devez avoir un accès administrateur à l'instance.

Pour définir le nombre maximum de domaines personnalisés GitLab Pages pour un projet :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Pages**.
1. Saisissez une valeur pour **Nombre maximum de domaines personnalisés par projet**. Utilisez `0` pour un nombre illimité de domaines.
1. Sélectionnez **Sauvegarder les modifications**.

## Configurer l'expiration par défaut des déploiements parallèles {#configure-the-default-expiry-for-parallel-deployments}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/456477) dans GitLab 17.4.

{{< /history >}}

Prérequis :

- Accès administrateur à l'instance.

Pour configurer la durée par défaut après laquelle les [déploiements parallèles](../../user/project/pages/_index.md#parallel-deployments) sont supprimés :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Pages**.
1. Saisissez une valeur pour **Default expiration for parallel deployments in seconds**. Utilisez `0` si les déploiements parallèles ne doivent pas expirer par défaut.
1. Sélectionnez **Sauvegarder les modifications**.

## Définir le nombre maximum de fichiers par site GitLab Pages {#set-maximum-number-of-files-per-gitlab-pages-website}

Le nombre total d'entrées de fichiers (y compris les répertoires et les liens symboliques) est limité à `200,000` pour chaque site GitLab Pages.

Vous pouvez mettre à jour la limite dans votre instance GitLab Self-Managed en utilisant la [console GitLab Rails](../operations/rails_console.md#starting-a-rails-console-session).

Pour plus d'informations, consultez les [limites de l'application GitLab](../instance_limits.md#number-of-files-per-gitlab-pages-website).

## Exécuter GitLab Pages sur un serveur séparé {#running-gitlab-pages-on-a-separate-server}

Vous pouvez exécuter le démon GitLab Pages sur un serveur séparé pour réduire la charge sur votre serveur d'application principal.

> [!warning]
> La procédure suivante comprend des étapes pour sauvegarder et modifier le fichier `gitlab-secrets.json`. Ce fichier contient des secrets qui contrôlent le chiffrement de la base de données. Procédez avec précaution.

Pour configurer GitLab Pages sur un serveur séparé :

1. Facultatif. Pour activer le contrôle d'accès, ajoutez ce qui suit à `/etc/gitlab/gitlab.rb` et [reconfigurez le **GitLab server**](../restart_gitlab.md#reconfigure-a-linux-package-installation) :

   > [!warning]
   > Si vous prévoyez d'utiliser GitLab Pages avec le contrôle d'accès, activez-le sur le serveur GitLab avant de copier `gitlab-secrets.json`. L'activation du contrôle d'accès génère une nouvelle application OAuth, et les informations la concernant sont propagées vers `gitlab-secrets.json`. Si cela n'est pas effectué dans le bon ordre, vous pourriez rencontrer des problèmes avec le contrôle d'accès.

   ```ruby
   gitlab_pages['access_control'] = true
   ```

1. Créez une sauvegarde du fichier de secrets sur le **GitLab server** :

   ```shell
   cp /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.bak
   ```

1. Sur le **GitLab server**, pour activer Pages, ajoutez ce qui suit à `/etc/gitlab/gitlab.rb` :

   ```ruby
   pages_external_url "http://<pages_server_URL>"
   ```

1. Configurez le stockage d'objets en :
   - [Configurant le stockage d'objets et en migrant les données GitLab Pages vers celui-ci](#object-storage-settings).
   - [Configurant le stockage réseau](#enable-pages-network-storage-in-multi-node-environments).
1. [Reconfigurez le **GitLab server**](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet. Le fichier `gitlab-secrets.json` est maintenant mis à jour avec la nouvelle configuration.
1. Configurez un nouveau serveur. Celui-ci deviendra le **Pages server**.
1. Sur le **Pages server**, installez GitLab en utilisant le package Linux et modifiez `/etc/gitlab/gitlab.rb` pour inclure :

   ```ruby
   roles ['pages_role']

   pages_external_url "http://<pages_server_URL>"

   gitlab_pages['gitlab_server'] = 'http://<gitlab_server_IP_or_URL>'

   ## If access control was enabled
   gitlab_pages['access_control'] = true
   ```

1. Si vous avez des paramètres UID/GID personnalisés sur le **GitLab server**, ajoutez-les également au **Pages server** `/etc/gitlab/gitlab.rb`. Sinon, l'exécution de `gitlab-ctl reconfigure` sur le **GitLab server** peut modifier la propriété des fichiers et provoquer l'échec des requêtes Pages.

1. Créez une sauvegarde du fichier de secrets sur le **Pages server** :

   ```shell
   cp /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json.bak
   ```

1. Pour activer les domaines personnalisés pour les sites GitLab Pages individuels, configurez le **Pages server** en utilisant l'une des options suivantes :

   - [Domaines personnalisés](#custom-domains).
   - [Domaines personnalisés avec prise en charge TLS](#custom-domains-with-tls-support).

1. Copiez le fichier `/etc/gitlab/gitlab-secrets.json` du **GitLab server** vers le **Pages server** :

   ```shell
   # On the GitLab server
   cp /etc/gitlab/gitlab-secrets.json /mnt/pages/gitlab-secrets.json

   # On the Pages server
   mv /var/opt/gitlab/gitlab-rails/shared/pages/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json
   ```

1. [Reconfigurez le **Pages server**](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
1. Sur le **GitLab server**, apportez les modifications suivantes à `/etc/gitlab/gitlab.rb` :

   ```ruby
   pages_external_url "http://<pages_server_URL>"
   gitlab_pages['enable'] = false
   pages_nginx['enable'] = false
   ```

1. Pour activer les domaines personnalisés pour les sites GitLab Pages individuels, sur le **GitLab server**, apportez les modifications suivantes à `/etc/gitlab/gitlab.rb` :

   - Domaines personnalisés :

     ```ruby
        gitlab_pages['custom_domain_mode'] = 'http'
     ```

   - Domaines personnalisés avec prise en charge TLS :

     ```ruby
        gitlab_pages['custom_domain_mode'] = 'https'
     ```

1. [Reconfigurez le **GitLab server**](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

Pour distribuer la charge, vous pouvez exécuter GitLab Pages sur plusieurs serveurs en utilisant des pratiques d'équilibrage de charge standard, comme configurer votre serveur DNS pour renvoyer plusieurs adresses IP ou utiliser un équilibreur de charge au niveau IP. Pour configurer GitLab Pages sur plusieurs serveurs, répétez la procédure précédente pour chaque serveur Pages.

## Configuration de la source de domaine {#domain-source-configuration}

Lorsque le démon GitLab Pages traite une requête, il identifie d'abord quel projet doit servir l'URL demandée et comment son contenu est stocké.

Par défaut, GitLab Pages utilise l'API GitLab interne chaque fois qu'un nouveau domaine est demandé. Pages échoue à démarrer s'il ne peut pas se connecter à l'API. Les informations de domaine sont également mises en cache par le démon Pages pour accélérer les requêtes ultérieures.

Pour les problèmes courants, consultez la [section de dépannage](troubleshooting.md#failed-to-connect-to-the-internal-gitlab-api).

### Configuration du cache de l'API GitLab {#gitlab-api-cache-configuration}

La configuration basée sur l'API utilise un mécanisme de mise en cache pour améliorer les performances et la fiabilité. Vous pouvez modifier le comportement du cache en changeant les paramètres suivants, bien que les valeurs par défaut recommandées ne doivent être modifiées qu'en cas de nécessité. Une configuration incorrecte peut entraîner des erreurs intermittentes ou persistantes, ou le démon Pages diffusant du contenu périmé.

> [!note]
> Les indicateurs d'expiration, d'intervalle et de délai d'attente utilisent le [formatage de durée Go](https://pkg.go.dev/time#ParseDuration). Une chaîne de durée est une séquence éventuellement signée de nombres décimaux, chacun avec une fraction optionnelle et un suffixe d'unité, comme `300ms`, `1.5h` ou `2h45m`. Les unités de temps valides sont `ns`, `us` (ou `µs`), `ms`, `s`, `m`, `h`.

Exemples :

- Augmenter `gitlab_cache_expiry` permet aux éléments d'exister plus longtemps dans le cache. Utilisez ce paramètre si la communication entre GitLab Pages et GitLab Rails n'est pas stable.
- Augmenter `gitlab_cache_refresh` réduit la fréquence à laquelle GitLab Pages demande la configuration d'un domaine depuis GitLab Rails. Utilisez ce paramètre si GitLab Pages génère trop de requêtes vers l'API GitLab et que le contenu ne change pas fréquemment.
- Diminuer `gitlab_cache_cleanup` supprime les éléments expirés du cache plus fréquemment, réduisant l'utilisation de la mémoire sur votre nœud Pages.
- Diminuer `gitlab_retrieval_timeout` arrête les requêtes vers GitLab Rails plus rapidement. L'augmenter permet de disposer de plus de temps pour recevoir une réponse de l'API. Utilisez ce paramètre pour les environnements réseau lents.
- Diminuer `gitlab_retrieval_interval` augmente la fréquence des requêtes vers l'API, uniquement lorsqu'il y a une réponse d'erreur de l'API, comme un délai d'attente de connexion.
- Diminuer `gitlab_retrieval_retries` réduit le nombre de fois où la configuration d'un domaine est réessayée avant de signaler une erreur.

## Paramètres de stockage d'objets {#object-storage-settings}

Les paramètres de [stockage d'objets](../object_storage.md) suivants sont :

- Imbriqués sous `pages:` puis `object_store:` dans les installations auto-compilées.
- Préfixés par `pages_object_store_` dans les installations de packages Linux.

| Paramètre | Description | Valeur par défaut |
|---------|-------------|---------|
| `enabled` | Indique si le stockage d'objets est activé. | `false` |
| `remote_directory` | Le nom du bucket où le contenu du site Pages est stocké. | |
| `connection` | Diverses options de connexion décrites ci-dessous. | |

> [!note]
> Si vous souhaitez arrêter d'utiliser et déconnecter le serveur NFS, vous devez [désactiver explicitement le stockage local](#disable-pages-local-storage).

### Paramètres de connexion compatibles S3 {#s3-compatible-connection-settings}

Vous devriez utiliser les [paramètres de stockage d'objets consolidés](../object_storage.md#configure-a-single-storage-connection-for-all-object-types-consolidated-form).

Consultez [les paramètres de connexion disponibles pour différents fournisseurs](../object_storage.md#configure-the-connection-settings).

### Migrer les déploiements Pages vers le stockage d'objets {#migrate-pages-deployments-to-object-storage}

Les objets de déploiement Pages existants (archives ZIP) peuvent être stockés soit en local, soit dans le stockage d'objets.

Pour migrer vos déploiements Pages existants du stockage local vers le stockage d'objets :

```shell
sudo gitlab-rake gitlab:pages:deployments:migrate_to_object_storage
```

Vous pouvez suivre la progression et vérifier que tous les déploiements Pages ont été migrés avec succès en utilisant la [console PostgreSQL](https://docs.gitlab.com/omnibus/settings/database/#connecting-to-the-postgresql-database) :

- `sudo gitlab-rails dbconsole --database main` pour les installations de packages Linux.
- `sudo -u git -H psql -d gitlabhq_production` pour les installations auto-compilées.

Vérifiez que `objectstg` (où `store=2`) contient le nombre total de tous les déploiements Pages :

```shell
gitlabhq_production=# SELECT count(*) AS total, sum(case when file_store = '1' then 1 else 0 end) AS filesystem, sum(case when file_store = '2' then 1 else 0 end) AS objectstg FROM pages_deployments;

total | filesystem | objectstg
------+------------+-----------
   10 |          0 |        10
```

Après avoir vérifié que tout fonctionne correctement, [désactivez le stockage local Pages](#disable-pages-local-storage).

### Revenir aux déploiements Pages sur le stockage local {#rolling-pages-deployments-back-to-local-storage}

Après la migration vers le stockage d'objets, vous pouvez déplacer vos déploiements Pages vers le stockage local :

```shell
sudo gitlab-rake gitlab:pages:deployments:migrate_to_local
```

### Désactiver le stockage local Pages {#disable-pages-local-storage}

Si vous utilisez le stockage d'objets, vous pouvez désactiver le stockage local pour éviter une utilisation ou des écritures disque inutiles :

1. Modifiez `/etc/gitlab/gitlab.rb` :

   ```ruby
   gitlab_rails['pages_local_store_enabled'] = false
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

## Activer le stockage réseau Pages dans les environnements multi-nœuds {#enable-pages-network-storage-in-multi-node-environments}

Le stockage d'objets est la configuration privilégiée pour la plupart des environnements. Cependant, si vos besoins nécessitent un stockage réseau et que vous souhaitez configurer Pages pour qu'il s'exécute sur un [serveur séparé](#running-gitlab-pages-on-a-separate-server), vous devez :

1. Vérifier que le volume de stockage partagé est déjà monté et disponible à la fois sur le serveur principal et sur le serveur Pages prévu.
1. Mettre à jour `/etc/gitlab/gitlab.rb` sur chaque nœud pour inclure :

   ```ruby
   gitlab_pages['enable_disk'] = true
   gitlab_rails['pages_path'] = "/var/opt/gitlab/gitlab-rails/shared/pages" # Path to your network storage
   ```

1. Basculer Pages vers votre serveur séparé.

Après avoir configuré avec succès Pages sur votre serveur séparé, seul ce serveur a besoin d'accéder au volume de stockage partagé. Envisagez de laisser le volume de stockage partagé monté sur votre serveur principal au cas où vous auriez besoin de revenir à un environnement à nœud unique.

## Stockage ZIP {#zip-storage}

Le format de stockage sous-jacent de GitLab Pages est une seule archive ZIP par projet. Ces archives peuvent être stockées localement ou sur un [stockage d'objets](#object-storage-settings). Une nouvelle archive est stockée chaque fois qu'un site Pages est mis à jour.

## Sauvegarde {#backup}

GitLab Pages fait partie de la [sauvegarde régulière](../backup_restore/_index.md), il n'y a donc pas de sauvegarde séparée à configurer.

## Sécurité {#security}

Vous devriez sérieusement envisager d'exécuter GitLab Pages sous un nom d'hôte différent de celui de GitLab pour éviter les attaques XSS.

### Limites de débit {#rate-limits}

{{< history >}}

- [Modifié](https://gitlab.com/groups/gitlab-org/-/epics/14653) dans GitLab 17.3 :  Vous pouvez exclure des sous-réseaux des limites de débit Pages.

{{< /history >}}

Vous pouvez appliquer des limites de débit pour minimiser le risque d'attaque par déni de service (DoS). GitLab Pages utilise un algorithme de seau à jetons pour appliquer les limites de débit. Par défaut, les requêtes ou connexions TLS qui dépassent les limites spécifiées sont signalées et rejetées.

GitLab Pages prend en charge les types de limites de débit suivants :

- Pour chaque `source_ip` :  Limite les requêtes ou connexions TLS provenant d'une seule adresse IP cliente.
- Pour chaque `domain` :  Limite les requêtes ou connexions TLS par domaine hébergé sur GitLab Pages. Il peut s'agir d'un domaine personnalisé comme `example.com`, ou d'un domaine de groupe comme `group.gitlab.io`.

Les limites de débit basées sur les requêtes HTTP sont appliquées en utilisant les paramètres suivants :

- `rate_limit_source_ip` :  Nombre maximum de requêtes par IP cliente par seconde. Définir sur `0` pour désactiver.
- `rate_limit_source_ip_burst` :  Nombre maximum de requêtes autorisées dans une rafale initiale par IP cliente, par exemple lorsqu'une page charge plusieurs ressources simultanément.
- `rate_limit_domain` :  Nombre maximum de requêtes par domaine Pages hébergé par seconde. Définir sur `0` pour désactiver.
- `rate_limit_domain_burst` :  Nombre maximum de requêtes autorisées dans une rafale initiale par domaine Pages hébergé.

Les limites de débit basées sur les connexions TLS sont appliquées en utilisant les paramètres suivants :

- `rate_limit_tls_source_ip` :  Nombre maximum de connexions TLS par IP cliente par seconde. Définir sur `0` pour désactiver.
- `rate_limit_tls_source_ip_burst` :  Nombre maximum de connexions TLS autorisées dans une rafale initiale par IP cliente.
- `rate_limit_tls_domain` :  Nombre maximum de connexions TLS par domaine Pages hébergé par seconde. Définir sur `0` pour désactiver.
- `rate_limit_tls_domain_burst` :  Nombre maximum de connexions TLS autorisées dans une rafale initiale par domaine Pages hébergé.

Pour autoriser certaines plages d'adresses IP (sous-réseaux) à contourner toutes les limites de débit, utilisez `rate_limit_subnets_allow_list`. Par exemple, `['1.2.3.4/24', '2001:db8::1/32']`. Un [exemple de chart GitLab Pages](https://docs.gitlab.com/charts/charts/gitlab/gitlab-pages/#configure-rate-limits-subnets-allow-list) est disponible.

Si l'adresse IP du client est IPv6, la limite est appliquée au préfixe IPv6 d'une longueur de 64, plutôt qu'à l'adresse entière.

#### Activer les limites de débit des requêtes HTTP par IP source {#enable-http-requests-rate-limits-by-source-ip}

Pour définir des limites de débit dans `/etc/gitlab/gitlab.rb` :

1. Ajoutez ce qui suit :

   ```ruby
   gitlab_pages['rate_limit_source_ip'] = 20.0
   gitlab_pages['rate_limit_source_ip_burst'] = 600
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

#### Activer les limites de débit des requêtes HTTP par domaine {#enable-http-requests-rate-limits-by-domain}

Pour définir des limites de débit dans `/etc/gitlab/gitlab.rb` :

1. Ajoutez :

   ```ruby
   gitlab_pages['rate_limit_domain'] = 1000
   gitlab_pages['rate_limit_domain_burst'] = 5000
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

#### Activer les limites de débit des connexions TLS par IP source {#enable-tls-connections-rate-limits-by-source-ip}

Pour définir des limites de débit dans `/etc/gitlab/gitlab.rb` :

1. Ajoutez :

   ```ruby
   gitlab_pages['rate_limit_tls_source_ip'] = 20.0
   gitlab_pages['rate_limit_tls_source_ip_burst'] = 600
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

#### Activer les limites de débit des connexions TLS par domaine {#enable-tls-connections-rate-limits-by-domain}

Pour définir des limites de débit dans `/etc/gitlab/gitlab.rb` :

1. Ajoutez :

   ```ruby
   gitlab_pages['rate_limit_tls_domain'] = 1000
   gitlab_pages['rate_limit_tls_domain_burst'] = 5000
   ```

1. Enregistrez le fichier et [reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

## Sujets connexes {#related-topics}

- [Dépannage de l'administration de GitLab Pages](troubleshooting.md)
- [Documentation utilisateur de GitLab Pages](../../user/project/pages/_index.md)
- [Domaines personnalisés et certificats SSL/TLS](../../user/project/pages/custom_domains_ssl_tls_certification/_index.md)
- [Contrôle d'accès Pages](../../user/project/pages/pages_access_control.md)
- [Artefacts de job](../cicd/job_artifacts.md)
- [Intégration du fournisseur OAuth](../../integration/oauth_provider.md)
- [Limites de l'application GitLab](../instance_limits.md#number-of-files-per-gitlab-pages-website)
- [Stockage d'objets](../object_storage.md)
- [Déploiements parallèles](../../user/project/pages/_index.md#parallel-deployments)
- [Personnaliser le dossier par défaut](../../user/project/pages/introduction.md#customize-the-default-folder)
- [Redirections Pages](../../user/project/pages/redirects.md)
