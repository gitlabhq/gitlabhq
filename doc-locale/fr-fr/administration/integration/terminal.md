---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Terminaux Web (obsolète)
description: Informations sur les terminaux Web.
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Cette fonctionnalité a été [rendue obsolète](https://gitlab.com/groups/gitlab-org/configure/-/epics/8) dans GitLab 14.5.
- [Désactivée sur GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/353410) dans GitLab 15.0.

{{< /history >}}

> [!flag]
> Sur GitLab Self-Managed, cette fonctionnalité n'est pas disponible par défaut. Pour la rendre disponible, un administrateur peut [activer le feature flag](../feature_flags/_index.md) nommé `certificate_based_clusters`.

- En savoir plus sur les [terminaux Web accessibles via le Web IDE](../../user/project/web_ide/_index.md) (non obsolètes).
- En savoir plus sur les [terminaux Web accessibles depuis un job CI en cours d'exécution](../../ci/interactive_web_terminal/_index.md) (non obsolètes).

---

Avec l'introduction de l'[intégration Kubernetes](../../user/infrastructure/clusters/_index.md), GitLab peut stocker et utiliser des identifiants pour un cluster Kubernetes. GitLab utilise ces identifiants pour fournir l'accès aux [terminaux Web](../../ci/environments/_index.md#web-terminals-deprecated) pour les environnements.

> [!note]
> Seuls les utilisateurs disposant au minimum du rôle [Maintainer](../../user/permissions.md) pour le projet peuvent accéder aux terminaux Web.

## Fonctionnement des terminaux Web {#how-web-terminals-work}

Un aperçu détaillé de l'architecture des terminaux Web et de leur fonctionnement est disponible dans [ce document](https://gitlab.com/gitlab-org/gitlab-workhorse/blob/master/doc/channel.md). En bref :

- GitLab s'appuie sur l'utilisateur pour fournir ses propres identifiants Kubernetes et pour labeler de manière appropriée les pods qu'il crée lors du déploiement.
- Lorsqu'un utilisateur accède à la page de terminal pour un environnement, une application JavaScript lui est servie, qui ouvre une connexion WebSocket vers GitLab.
- Le WebSocket est géré dans [Workhorse](https://gitlab.com/gitlab-org/gitlab-workhorse), plutôt que sur le serveur d'application Rails.
- Workhorse interroge Rails pour obtenir les détails de connexion et les permissions des utilisateurs. Rails interroge Kubernetes en arrière-plan via [Sidekiq](../sidekiq/sidekiq_troubleshooting.md).
- Workhorse agit comme un serveur proxy entre le navigateur de l'utilisateur et l'API Kubernetes, transmettant les trames WebSocket entre les deux.
- Workhorse interroge régulièrement Rails, mettant fin à la connexion WebSocket si l'utilisateur n'a plus la permission d'accéder au terminal ou si les détails de connexion ont changé.

## Sécurité {#security}

GitLab et [GitLab Runner](https://docs.gitlab.com/runner/) prennent certaines précautions pour maintenir les données des terminaux Web interactifs chiffrées entre eux, et tout est protégé par des contrôles d'autorisation. Cela est décrit plus en détail ci-dessous.

- Les terminaux Web interactifs sont complètement désactivés sauf si [`[session_server]`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-session_server-section) est configuré.
- À chaque démarrage du runner, celui-ci génère un certificat `x509` utilisé pour une connexion `wss` (Web Socket Secure).
- Pour chaque job créé, une URL aléatoire est générée et supprimée à la fin du job. Cette URL est utilisée pour établir une connexion web socket. L'URL de la session est au format `(IP|HOST):PORT/session/$SOME_HASH`, où `IP/HOST` et `PORT` correspondent à la valeur configurée [`listen_address`](https://docs.gitlab.com/runner/configuration/advanced-configuration/#the-session_server-section).
- Chaque URL de session créée possède un en-tête d'autorisation qui doit être envoyé pour établir une connexion `wss`.
- L'URL de session n'est exposée aux utilisateurs d'aucune façon. GitLab conserve tout l'état en interne et effectue le proxy en conséquence.

## Activation et désactivation du support des terminaux {#enabling-and-disabling-terminal-support}

> [!note]
> Les AWS Classic Load Balancers ne prennent pas en charge les web sockets. Si vous souhaitez que les terminaux Web fonctionnent, utilisez des AWS Network Load Balancers. Lisez la [Comparaison des produits AWS Elastic Load Balancing](https://aws.amazon.com/elasticloadbalancing/features/#compare) pour plus d'informations.

Comme les terminaux Web utilisent les WebSockets, chaque proxy inverse HTTP/HTTPS placé devant Workhorse doit être configuré pour transmettre les en-têtes `Connection` et `Upgrade` au suivant dans la chaîne. GitLab est configuré par défaut pour le faire.

Cependant, si vous exécutez un [équilibreur de charge](../load_balancer.md) devant GitLab, vous devrez peut-être apporter des modifications à votre configuration. Ces guides documentent les étapes nécessaires pour une sélection de proxies inverses populaires :

- [Apache](https://httpd.apache.org/docs/2.4/mod/mod_proxy_wstunnel.html)
- [NGINX](https://www.f5.com/company/blog/nginx/websocket-nginx/)
- [HAProxy](https://www.haproxy.com/blog/websockets-load-balancing-with-haproxy)
- [Varnish](https://varnish-cache.org/docs/4.1/users-guide/vcl-example-websockets.html)

Workhorse ne laisse pas passer les requêtes WebSocket vers des endpoints non-WebSocket, il est donc sûr d'activer globalement la prise en charge de ces en-têtes. Si vous préférez un ensemble de règles plus restreint, vous pouvez le limiter aux URLs se terminant par `/terminal.ws`. Cette approche peut tout de même entraîner quelques faux positifs.

Si vous avez compilé votre installation vous-même, vous devrez peut-être apporter des modifications à votre configuration. Consultez [Mise à niveau de Community Edition et Enterprise Edition depuis les sources](../../update/upgrading_from_source.md#new-configuration-for-nginx-or-apache) pour plus de détails.

Pour désactiver le support des terminaux Web dans GitLab, arrêtez de transmettre les en-têtes hop-by-hop `Connection` et `Upgrade` dans le premier proxy inverse HTTP de la chaîne. Pour la plupart des utilisateurs, il s'agit du serveur NGINX fourni avec les installations du package Linux. Dans ce cas, vous devez :

- Trouvez la section `nginx['proxy_set_headers']` de votre fichier `gitlab.rb`
- Assurez-vous que le bloc entier est décommenté, puis commentez ou supprimez les lignes `Connection` et `Upgrade`.

Pour votre propre équilibreur de charge, inversez simplement les modifications de configuration recommandées par les guides précédemment listés.

Lorsque ces en-têtes ne sont pas transmis, Workhorse renvoie une réponse `400 Bad Request` aux utilisateurs tentant d'utiliser un terminal Web. En retour, ils reçoivent un message `Connection failed`.

## Limitation de la durée de connexion WebSocket {#limiting-websocket-connection-time}

Par défaut, les sessions de terminal n'expirent pas.

Prérequis :

- Accès administrateur.

Pour limiter la durée de vie des sessions de terminal dans votre instance GitLab :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres** > **Général**.
1. Développez **Terminal Web**.
1. Définissez un `max session time`.
