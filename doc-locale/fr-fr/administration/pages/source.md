---
stage: Plan
group: Knowledge
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Administration de GitLab Pages pour les installations auto-compilées
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

> [!note]
> Avant de tenter d'activer GitLab Pages, assurez-vous d'abord d'avoir [installé GitLab](../../install/self_compiled/_index.md) avec succès.

Ce document explique comment configurer GitLab Pages pour les installations GitLab auto-compilées.

Pour plus d'informations sur la configuration de GitLab Pages pour les installations de packages Linux (recommandé), consultez la [documentation du package Linux](_index.md). L'installation du package Linux contient la dernière version prise en charge de GitLab Pages.

## Fonctionnement de GitLab Pages {#how-gitlab-pages-works}

GitLab Pages utilise le démon GitLab Pages, un serveur HTTP léger qui écoute sur une adresse IP externe et prend en charge les domaines personnalisés et les certificats. Il prend en charge les certificats dynamiques via `SNI` et expose les pages en utilisant HTTP2 par défaut. Pour plus d'informations, consultez le [README](https://gitlab.com/gitlab-org/gitlab-pages/blob/master/README.md).

Pour les [domaines personnalisés](#custom-domains), le démon Pages doit écouter sur les ports `80` ou `443`. Cela ne s'applique pas aux [domaines génériques](#wildcard-domains). Vous pouvez le configurer de l'une des façons suivantes :

- Sur le même serveur que GitLab, en écoutant sur une IP secondaire.
- Sur un serveur séparé. Le [chemin Pages](#change-storage-path) doit également être présent sur ce serveur, vous devez donc le partager sur le réseau.
- Sur le même serveur que GitLab, en écoutant sur la même IP mais sur des ports différents. Dans ce cas, vous devez proxifier le trafic avec un équilibreur de charge. Pour HTTPS, utilisez l'équilibrage de charge TCP. Si vous utilisez la terminaison TLS (équilibrage de charge HTTPS), les pages ne peuvent pas être servies avec des certificats fournis par l'utilisateur. Pour HTTP, l'équilibrage de charge HTTP ou TCP est acceptable.

Les sections suivantes supposent la première option. Si vous ne prenez pas en charge les domaines personnalisés, une IP secondaire n'est pas nécessaire.

## Prérequis {#prerequisites}

Avant de procéder à la configuration de Pages, assurez-vous que :

- Vous disposez d'un domaine distinct pour servir GitLab Pages. Dans ce document, ce domaine est `example.io`.
- Vous avez configuré un **wildcard DNS record** pour ce domaine.
- Vous avez installé les packages `zip` et `unzip` sur le même serveur où GitLab est installé. Les packages sont nécessaires pour compresser et décompresser les artefacts Pages.
- Facultatif. Vous disposez d'un **wildcard certificate** pour le domaine Pages (`*.example.io`) si vous décidez de servir Pages sous HTTPS.
- Facultatif mais recommandé. Vous avez configuré et activé des [runners d'instance](../../ci/runners/_index.md) afin que vos utilisateurs n'aient pas à apporter les leurs.

### Configuration DNS {#dns-configuration}

GitLab Pages doit s'exécuter sur son propre hôte virtuel. Dans votre serveur ou fournisseur DNS, ajoutez un [enregistrement DNS générique `A`](https://en.wikipedia.org/wiki/Wildcard_DNS_record) pointant vers l'hôte sur lequel GitLab s'exécute. Par exemple :

```plaintext
*.example.io. 1800 IN A 192.0.2.1
```

Où `example.io` est le domaine depuis lequel GitLab Pages est servi, et `192.0.2.1` est l'adresse IP de votre instance GitLab.

> [!note]
> N'utilisez pas le domaine GitLab pour servir les pages utilisateur. Pour plus d'informations, consultez la [section sécurité](#security).

## Configuration {#configuration}

Vous pouvez configurer GitLab Pages de plusieurs façons. Les options suivantes sont listées de la configuration la plus simple à la plus avancée. La configuration minimale requise pour toutes les configurations est un enregistrement DNS générique.

### Domaines génériques {#wildcard-domains}

Chaque site obtient son propre sous-domaine (par exemple, `<namespace>.example.io/<project_slug>`). Ce sous-domaine nécessite un enregistrement DNS générique (`*.example.io`) et constitue la configuration recommandée pour la plupart des instances.

Prérequis :

- [Configuration DNS générique](#dns-configuration)

Cette configuration est le minimum avec lequel vous pouvez utiliser Pages. C'est la base pour toutes les autres configurations décrites ci-dessous. NGINX proxifie toutes les requêtes vers le démon. Le démon Pages n'écoute pas le monde extérieur.

1. Installez le démon Pages :

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. Accédez au répertoire d'installation de GitLab :

   ```shell
   cd /home/git/gitlab
   ```

1. Modifiez `gitlab.yml` et sous le paramètre `pages`, définissez `enabled` sur `true` et le `host` sur le FQDN depuis lequel servir GitLab Pages :

   ```yaml
   ## GitLab Pages
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     # path: shared/pages

     host: example.io
     access_control: false
     port: 8090
     https: false
     artifacts_server: false
     external_http: ["127.0.0.1:8090"]
     secret_file: /home/git/gitlab/gitlab-pages-secret
   ```

1. Ajoutez le fichier de configuration suivant dans `/home/git/gitlab-pages/gitlab-pages.conf`. Remplacez `example.io` par le FQDN depuis lequel servir GitLab Pages et `gitlab.example.com` par l'URL de votre instance GitLab :

   ```ini
   listen-http=:8090
   pages-root=/home/git/gitlab/shared/pages
   api-secret-key=/home/git/gitlab/gitlab-pages-secret
   pages-domain=example.io
   internal-gitlab-server=https://gitlab.example.com

   Vous pouvez utiliser une adresse `http` lorsque GitLab Pages et GitLab s'exécutent sur le même hôte. Si vous utilisez
   `https` avec un certificat auto-signé, rendez votre CA personnalisée disponible pour GitLab Pages, par
   exemple en définissant la variable d'environnement `SSL_CERT_DIR`.

1. Ajoutez la clé API secrète :

   ```shell
   sudo -u git -H openssl rand -base64 32 > /home/git/gitlab/gitlab-pages-secret
   ```

1. Pour activer le démon Pages :

   - Si votre système utilise systemd init, exécutez :

     ```shell
     sudo systemctl edit gitlab.target
     ```

     Dans l'éditeur, ajoutez ce qui suit et enregistrez le fichier :

     ```plaintext
     [Unit]
     Wants=gitlab-pages.service
     ```

   - Si votre système utilise SysV init, modifiez `/etc/default/gitlab` et définissez `gitlab_pages_enabled` sur `true` :

     ```ini
     gitlab_pages_enabled=true
     ```

1. Copiez le fichier de configuration NGINX `gitlab-pages` :

   ```shell
   sudo cp lib/support/nginx/gitlab-pages /etc/nginx/sites-available/gitlab-pages.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages.conf
   ```

1. Redémarrez NGINX.
1. [Redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).

### Domaines génériques avec support TLS {#wildcard-domains-with-tls-support}

Prérequis :

- [Configuration DNS générique](#dns-configuration)
- Certificat TLS générique

Schéma d'URL : `https://<namespace>.example.io/<project_slug>`

NGINX proxifie toutes les requêtes vers le démon. Le démon Pages n'écoute pas l'internet public.

Pour configurer des domaines génériques avec le support TLS :

1. Installez le démon Pages :

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. Dans `gitlab.yml`, définissez le `port` sur `443` et `https` sur `true` :

   ```yaml
   ## GitLab Pages
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     # path: shared/pages

     host: example.io
     port: 443
     https: true
   ```

1. Modifiez `/etc/default/gitlab` et définissez `gitlab_pages_enabled` sur `true`. Dans `gitlab_pages_options`, `-pages-domain` doit correspondre à la valeur de `host`. Les paramètres `-root-cert` et `-root-key` sont les certificats TLS génériques pour le domaine `example.io` :

   ```ini
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -root-cert /path/to/example.io.crt -root-key /path/to/example.io.key"
   ```

1. Copiez le fichier de configuration NGINX `gitlab-pages-ssl` :

   ```shell
   sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
   ```

1. Redémarrez NGINX.
1. [Redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).

## Configuration avancée {#advanced-configuration}

En plus des domaines génériques, vous pouvez configurer GitLab Pages pour fonctionner avec des domaines personnalisés, avec ou sans certificats TLS.

### Domaines personnalisés {#custom-domains}

Prérequis :

- [Configuration DNS générique](#dns-configuration)
- IP secondaire

Schéma d'URL : `http://<namespace>.example.io/<project_slug>` et `http://custom-domain.com`

Dans cette configuration, le démon Pages est en cours d'exécution et NGINX proxifie les requêtes vers lui, mais le démon peut également recevoir des requêtes de l'internet public. Les domaines personnalisés sont pris en charge sans TLS.

Pour configurer des domaines personnalisés :

1. Installez le démon Pages :

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. Modifiez `gitlab.yml`. Définissez `host` sur le FQDN depuis lequel servir GitLab Pages, et définissez `external_http` sur l'IP secondaire sur laquelle le démon Pages écoute :

   ```yaml
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     # path: shared/pages

     host: example.io
     port: 80
     https: false

     external_http: 192.0.2.2:80
   ```

1. Modifiez `/etc/default/gitlab` et définissez `gitlab_pages_enabled` sur `true`. Dans `gitlab_pages_options` :

   - `-pages-domain` doit correspondre à `host`.
   - `-listen-http` doit correspondre à `external_http`.
   - `-listen-https` doit correspondre à `external_https`.

   ```ini
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 192.0.2.2:80"
   ```

1. Copiez le fichier de configuration NGINX `gitlab-pages` :

   ```shell
   sudo cp lib/support/nginx/gitlab-pages /etc/nginx/sites-available/gitlab-pages.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages.conf
   ```

1. Modifiez toutes les configurations liées à GitLab dans `/etc/nginx/site-available/` et remplacez `0.0.0.0` par `192.0.2.1`, où `192.0.2.1` est l'IP principale sur laquelle GitLab écoute.
1. Redémarrez NGINX.
1. [Redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).

### Domaines personnalisés avec support TLS {#custom-domains-with-tls-support}

Prérequis :

- [Configuration DNS générique](#dns-configuration)
- Certificat TLS générique
- IP secondaire

Schéma d'URL : `https://<namespace>.example.io/<project_slug>` et `https://custom-domain.com`

Dans cette configuration, le démon Pages est en cours d'exécution et NGINX proxifie les requêtes vers lui, mais le démon peut également recevoir des requêtes de l'internet public. Les domaines personnalisés et TLS sont pris en charge.

Pour configurer des domaines personnalisés avec le support TLS :

1. Installez le démon Pages :

   ```shell
   cd /home/git
   sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-pages.git
   cd gitlab-pages
   sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
   sudo -u git -H make
   ```

1. Modifiez `gitlab.yml`. Définissez `host` sur le FQDN depuis lequel servir GitLab Pages, et définissez `external_http` et `external_https` sur l'IP secondaire sur laquelle le démon Pages écoute :

   ```yaml
   ## GitLab Pages
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     # path: shared/pages

     host: example.io
     port: 443
     https: true

     external_http: 192.0.2.2:80
     external_https: 192.0.2.2:443
   ```

1. Modifiez `/etc/default/gitlab` et définissez `gitlab_pages_enabled` sur `true`. Dans `gitlab_pages_options` :

   - `-pages-domain` doit correspondre à `host`.
   - `-listen-http` doit correspondre à `external_http`.
   - `-listen-https` doit correspondre à `external_https`.

   Les paramètres `-root-cert` et `-root-key` sont les certificats TLS génériques pour le domaine `example.io` :

   ```ini
   gitlab_pages_enabled=true
   gitlab_pages_options="-pages-domain example.io -pages-root $app_root/shared/pages -listen-proxy 127.0.0.1:8090 -listen-http 192.0.2.2:80 -listen-https 192.0.2.2:443 -root-cert /path/to/example.io.crt -root-key /path/to/example.io.key"
   ```

1. Copiez le fichier de configuration NGINX `gitlab-pages-ssl` :

   ```shell
   sudo cp lib/support/nginx/gitlab-pages-ssl /etc/nginx/sites-available/gitlab-pages-ssl.conf
   sudo ln -sf /etc/nginx/sites-{available,enabled}/gitlab-pages-ssl.conf
   ```

1. Modifiez toutes les configurations liées à GitLab dans `/etc/nginx/site-available/` et remplacez `0.0.0.0` par `192.0.2.1`, où `192.0.2.1` est l'IP principale sur laquelle GitLab écoute.
1. Redémarrez NGINX.
1. [Redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).

## Mises en garde NGINX {#nginx-caveats}

> [!note]
> Les informations suivantes s'appliquent uniquement aux installations auto-compilées.

Soyez prudent lors de la configuration du nom de domaine dans la configuration NGINX. Vous ne devez pas supprimer les barres obliques inverses.

Si votre domaine GitLab Pages est `example.io`, remplacez :

```nginx
server_name ~^.*\.YOUR_GITLAB_PAGES\.DOMAIN$;
```

par :

```nginx
server_name ~^.*\.example\.io$;
```

Si vous utilisez un sous-domaine, échappez tous les points (`.`) sauf le premier avec une barre oblique inverse (`\`). Par exemple, `pages.example.io` serait :

```nginx
server_name ~^.*\.pages\.example\.io$;
```

## Contrôle d'accès {#access-control}

Le contrôle d'accès de GitLab Pages peut être configuré par projet. L'accès à un site Pages peut être contrôlé en fonction de l'appartenance d'un utilisateur à ce projet.

Le contrôle d'accès fonctionne en enregistrant le démon Pages en tant qu'application OAuth auprès de GitLab. Chaque fois qu'un utilisateur non authentifié demande l'accès à un site Pages privé, le démon Pages redirige l'utilisateur vers GitLab. Si l'authentification réussit, l'utilisateur est redirigé vers Pages avec un jeton, qui est conservé dans un cookie. Les cookies sont signés avec une clé secrète, de sorte que toute altération peut être détectée.

Chaque requête pour afficher une ressource sur un site privé est authentifiée par Pages à l'aide de ce jeton. Pour chaque requête reçue, Pages effectue une requête à l'API GitLab pour vérifier que l'utilisateur est autorisé à lire ce site.

Les paramètres de contrôle d'accès pour Pages sont :

- Définis dans un fichier de configuration par une convention nommée `gitlab-pages-config`.
- Transmis à Pages à l'aide du drapeau `-config` ou de la variable d'environnement `CONFIG`.

Le contrôle d'accès Pages est désactivé par défaut. Pour l'activer :

1. Modifiez `config/gitlab.yml` :

   ```yaml
   pages:
     access_control: true
   ```

1. [Redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).
1. Créez une nouvelle [application OAuth système](../../integration/oauth_provider.md#create-a-user-owned-application). Nommez-la `GitLab Pages` et définissez la **Redirect URL** sur `https://projects.example.io/auth`. Elle n'a pas besoin d'être une application de confiance, mais elle a besoin de la portée `api`.
1. Démarrez le démon Pages en passant un fichier de configuration avec les arguments suivants :

   ```shell
     auth-client-id=<OAuth Application ID generated by GitLab>
     auth-client-secret=<OAuth code generated by GitLab>
     auth-redirect-uri='http://projects.example.io/auth'
     auth-secret=<40 random hex characters>
     auth-server=<URL of the GitLab instance>
   ```

1. Les utilisateurs peuvent maintenant le configurer dans les [paramètres de leur projet](../../user/project/pages/pages_access_control.md).

## Modifier le chemin de stockage {#change-storage-path}

Pour modifier le chemin par défaut où le contenu de GitLab Pages est stocké :

1. Les pages sont stockées par défaut dans `/home/git/gitlab/shared/pages`. Pour utiliser un emplacement différent, modifiez `gitlab.yml` sous la section `pages` :

   ```yaml
   pages:
     enabled: true
     # The location where pages are stored (default: shared/pages).
     path: /mnt/storage/pages
   ```

1. [Redémarrez GitLab](../restart_gitlab.md#self-compiled-installations).

## Définir la taille maximale de Pages {#set-maximum-pages-size}

La taille maximale par défaut des archives décompressées par projet est de 100 Mo.

Prérequis :

- Accès administrateur.

Pour modifier cette valeur :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Préférences**.
1. Développez **Pages**.
1. Mettez à jour la valeur pour **Maximum size of pages (MB)**.

## Sauvegarde {#backup}

Les pages font partie de la [sauvegarde régulière](../backup_restore/_index.md), il n'y a donc rien à configurer.

## Sécurité {#security}

Vous devriez fortement envisager d'exécuter GitLab Pages sous un nom d'hôte différent de celui de GitLab pour prévenir les attaques XSS.
