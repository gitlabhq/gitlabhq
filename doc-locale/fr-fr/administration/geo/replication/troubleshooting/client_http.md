---
stage: Tenant Scale
group: Geo
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage des erreurs de client Geo et de code de réponse HTTP
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

## Corriger les erreurs client {#fixing-client-errors}

### Erreurs d'autorisation provenant des requêtes client LFS HTTP(S) {#authorization-errors-from-lfs-https-client-requests}

Vous pouvez rencontrer des problèmes si vous utilisez une version de [Git LFS](https://git-lfs.com/) antérieure à 2.4.2. Comme indiqué dans [ce ticket d'authentification](https://github.com/git-lfs/git-lfs/issues/3025), les requêtes redirigées du site secondaire vers le site principal n'envoient pas correctement l'en-tête Authorization. Cela peut entraîner soit une boucle infinie `Authorization <-> Redirect`, soit des messages d'erreur d'autorisation.

### Erreur : `Net::ReadTimeout` lors d'un push via SSH sur un site Geo secondaire {#error-netreadtimeout-when-pushing-through-ssh-on-a-geo-secondary}

Lorsque vous envoyez de grands dépôts via SSH sur un site Geo secondaire, vous pouvez rencontrer un délai d'attente. En effet, Rails transmet le push au site principal via un proxy et dispose d'un délai d'attente par défaut de 60 secondes, [comme décrit dans ce ticket Geo](https://gitlab.com/gitlab-org/gitlab/-/issues/7405).

Les solutions de contournement actuelles sont :

- Effectuez le push via HTTP à la place, où Workhorse transmet la requête au site principal via un proxy (ou redirige vers le site principal si le proxying Geo n'est pas activé).
- Effectuez le push directement vers le site principal.

Exemple de log (`gitlab-shell.log`) :

```plaintext
Failed to contact primary https://primary.domain.com/namespace/push_test.git\\nError: Net::ReadTimeout\",\"result\":null}" code=500 method=POST pid=5483 url="http://127.0.0.1:3000/api/v4/geo/proxy_git_push_ssh/push"
```

### Réparer l'autorisation OAuth entre les sites Geo {#repair-oauth-authorization-between-geo-sites}

Lors de la mise à niveau d'un site Geo, il est possible que vous ne puissiez pas vous connecter à un site secondaire qui utilise uniquement OAuth pour l'authentification. Dans ce cas, démarrez une session de [console Rails](../../../operations/rails_console.md) sur votre site principal et effectuez les étapes suivantes :

1. Pour trouver le nœud concerné, commencez par lister tous les nœuds Geo dont vous disposez :

   ```ruby
   GeoNode.all
   ```

1. Réparez le nœud Geo concerné en spécifiant l'ID :

   ```ruby
   GeoNode.find(<id>).repair
   ```

## Erreurs de code de réponse HTTP {#http-response-code-errors}

### Le site secondaire renvoie des erreurs 502 avec le proxying Geo {#secondary-site-returns-502-errors-with-geo-proxying}

Lorsque le [proxying Geo pour les sites secondaires](../../secondary_proxy/_index.md) est activé et que l'interface utilisateur du site secondaire renvoie des erreurs 502, il est possible que l'en-tête de réponse transmis par proxy depuis le site principal soit trop volumineux.

Vérifiez les logs NGINX pour détecter des erreurs similaires à cet exemple :

```plaintext
2022/01/26 00:02:13 [error] 26641#0: *829148 upstream sent too big header while reading response header from upstream, client: 10.0.2.2, server: geo.staging.gitlab.com, request: "POST /users/sign_in HTTP/2.0", upstream: "http://unix:/var/opt/gitlab/gitlab-workhorse/sockets/socket:/users/sign_in", host: "geo.staging.gitlab.com", referrer: "https://geo.staging.gitlab.com/users/sign_in"
```

Pour résoudre ce problème :

1. Définissez `nginx['proxy_custom_buffer_size'] = '8k'` dans `/etc/gitlab.rb` sur tous les nœuds web du site secondaire.
1. Reconfigurez le site **secondaire** en utilisant `sudo gitlab-ctl reconfigure`.

Si vous obtenez toujours cette erreur, vous pouvez augmenter davantage la taille du tampon en répétant les étapes précédentes et en modifiant la taille `8k`, par exemple en la doublant à `16k`.

### La zone Admin Geo affiche `Unknown` pour le statut de santé et « Request failed with status code 401 » {#geo-admin-area-shows-unknown-for-health-status-and-request-failed-with-status-code-401}

Si vous utilisez un équilibreur de charge, assurez-vous que l'URL de l'équilibreur de charge est définie comme `external_url` dans le fichier `/etc/gitlab/gitlab.rb` des nœuds situés derrière l'équilibreur de charge.

Sur le site principal, accédez à **Admin** > **Geo** > **Paramètres** et trouvez le champ **IP Geo autorisée**. Assurez-vous que l'adresse IP du site secondaire est bien répertoriée.

### Le site principal renvoie une erreur 500 lors de l'accès à `/admin/geo/replication/projects` {#primary-site-returns-500-error-when-accessing-admingeoreplicationprojects}

La navigation vers **Admin** > **Geo** > **Replication** (ou `/admin/geo/replication/projects`) sur un site Geo principal affiche une erreur 500, tandis que ce même lien sur le site secondaire fonctionne correctement. Le fichier `production.log` du site principal contient une entrée similaire à la suivante :

```plaintext
Geo::TrackingBase::SecondaryNotConfigured: Geo secondary database is not configured
  from ee/app/models/geo/tracking_base.rb:26:in `connection'
  [..]
  from ee/app/views/admin/geo/projects/_all.html.haml:1
```

Sur un site Geo principal, cette erreur peut être ignorée.

Cela se produit parce que GitLab tente d'afficher les registres depuis la [base de données de suivi Geo](../../_index.md#geo-tracking-database) qui n'existe pas sur le site principal (seuls les projets originaux existent sur le site principal ; aucun projet répliqué n'est présent, il n'existe donc pas de base de données de suivi).

### Le site secondaire renvoie une erreur 400 `Request header or cookie too large` {#secondary-site-returns-400-error-request-header-or-cookie-too-large}

Cette erreur peut se produire lorsque l'URL interne du site principal est incorrecte.

Par exemple, lorsque vous utilisez une URL unifiée et que l'URL interne du site principal est également égale à l'URL externe. Cela crée une boucle lorsqu'un site secondaire transmet les requêtes à l'URL interne du site principal via un proxy.

Pour résoudre ce problème, définissez l'URL interne du site principal sur une URL qui est :

- Unique au site principal.
- Accessible depuis tous les sites secondaires.

1. Visitez le site principal.
1. [Configurez les URL internes](../../../geo_sites.md#set-up-the-internal-urls).

### La zone Admin Geo renvoie une erreur 404 pour un site secondaire {#geo-admin-area-returns-404-error-for-a-secondary-site}

Parfois, `sudo gitlab-rake gitlab:geo:check` indique que les **Rails nodes of the secondary** sont en bonne santé, mais un message d'erreur 404 Not Found pour le site **secondaire** est renvoyé dans la zone **Admin** Geo de l'interface web pour le site **principal**.

Pour résoudre ce problème :

- Essayez de redémarrer **each Rails, Sidekiq and Gitaly nodes on your secondary site** en utilisant `sudo gitlab-ctl restart`.
- Vérifiez `/var/log/gitlab/gitlab-rails/geo.log` sur les nœuds Sidekiq pour voir si le site **secondaire** utilise IPv6 pour envoyer son statut au site **principal**. Si c'est le cas, ajoutez une entrée au site **principal** en utilisant IPv4 dans le fichier `/etc/hosts`. Vous pouvez également [activer IPv6 sur le site **principal**](https://docs.gitlab.com/omnibus/settings/nginx/#setting-the-nginx-listen-address-or-addresses).

## Les requêtes WebSocket échouent sur les sites Geo secondaires {#websocket-requests-fail-on-geo-secondary-sites}

Lors de l'utilisation de fonctionnalités reposant sur les WebSockets (telles que GitLab Duo Chat, les mises à jour de tickets en direct ou d'autres fonctionnalités en temps réel), les connexions peuvent échouer avec des erreurs 404 sur les sites Geo secondaires.

Cela se produit parce que les requêtes WebSocket sont transmises par proxy du site secondaire vers le site principal. Sur le site principal, ActionCable doit être configuré pour autoriser les requêtes WebSocket de tous les sites Geo. Par défaut, ActionCable n'autorise que les requêtes provenant du site local.

Pour résoudre ce problème, configurez `action_cable_allowed_origins` selon votre type d'installation :

- [Documentation Geo pour le package Linux](../configuration.md#add-primary-and-secondary-urls-as-allowed-actioncable-origins)
- [Documentation Geo pour le chart Helm](https://docs.gitlab.com/charts/advanced/geo/#configure-primary-database)
