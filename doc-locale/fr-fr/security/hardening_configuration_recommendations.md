---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Durcissement - Recommandations de configuration
---

Les directives générales de durcissement sont décrites dans la [documentation principale sur le durcissement](hardening.md).

Certaines recommandations de durcissement pour les instances GitLab impliquent des services supplémentaires ou un contrôle via des fichiers de configuration. Pour rappel, chaque fois que vous apportez des modifications à des fichiers de configuration, effectuez des copies de sauvegarde de ceux-ci avant de les modifier. De plus, si vous effectuez de nombreuses modifications, il est recommandé de ne pas les effectuer toutes en même temps, et de les tester après chaque modification pour vous assurer que tout fonctionne correctement.

## NGINX {#nginx}

NGINX est utilisé pour servir l'interface web permettant d'accéder à l'instance GitLab. Étant donné que NGINX est contrôlé et intégré à GitLab, la modification du fichier `/etc/gitlab/gitlab.rb` est utilisée pour les ajustements. Voici quelques recommandations pour améliorer la sécurité de NGINX lui-même :

1. Créez la [clé Diffie-Hellman](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_dhparam) :

   ```shell
   sudo openssl dhparam -out /etc/gitlab/ssl/dhparam.pem 4096
   ```

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez ce qui suit :

   ```ruby
   #
   # Only strong ciphers are used
   #
   nginx['ssl_ciphers'] = "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:TLS_AES_256_GCM_SHA384:TLS_AES_128_GCM_SHA256"
   #
   # Follow preferred ciphers and the order listed as preference
   #
   nginx['ssl_prefer_server_ciphers'] = "on"
   #
   # Only allow TLSv1.2 and TLSv1.3
   #
   nginx['ssl_protocols'] = "TLSv1.2 TLSv1.3"

   ##! **Recommended in: https://nginx.org/en/docs/http/ngx_http_ssl_module.html**
   nginx['ssl_session_cache'] = "builtin:1000 shared:SSL:10m"

   ##! **Default according to https://nginx.org/en/docs/http/ngx_http_ssl_module.html**
   nginx['ssl_session_timeout'] = "5m"

   # Should prevent logjam attack etc
   nginx['ssl_dhparam'] = "/etc/gitlab/ssl/dhparam.pem" # changed from nil

   # Turn off session ticket reuse
   nginx['ssl_session_tickets'] = "off"
   # Pick our own curve instead of what openssl hands us
   nginx['ssl_ecdh_curve'] = "secp384r1"
   ```

1. Reconfigurez GitLab :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

## Consul {#consul}

Consul peut être intégré dans un environnement GitLab et est destiné aux déploiements de grande envergure. En général, pour les déploiements autonomes et auto-gérés avec moins de 1 000 utilisateurs, Consul n'est peut-être pas nécessaire. Si cela est nécessaire, consultez d'abord la [documentation sur Consul](../administration/consul.md), mais surtout assurez-vous que le chiffrement est utilisé lors des communications. Pour plus d'informations détaillées sur Consul, consultez le [site web de HashiCorp](https://developer.hashicorp.com/consul/docs) pour comprendre son fonctionnement, et examinez les informations sur la [sécurité du chiffrement](https://developer.hashicorp.com/consul/docs/security/encryption).

## Variables d'environnement {#environment-variables}

Vous pouvez personnaliser plusieurs [variables d'environnement](https://docs.gitlab.com/omnibus/settings/environment-variables/) sur les systèmes auto-gérés. La principale variable d'environnement à exploiter d'un point de vue sécurité est `GITLAB_ROOT_PASSWORD` lors du processus d'installation. Si vous installez le système auto-géré avec une adresse IP publique exposée à Internet, assurez-vous que le mot de passe est défini sur quelque chose de robuste. Historiquement, la mise en place de tout type de service exposé au public, qu'il s'agisse de GitLab ou d'une autre application, a montré que des attaques opportunistes se produisent dès que ces systèmes sont découverts, c'est pourquoi le processus de durcissement devrait commencer dès l'installation.

Comme mentionné dans les [recommandations relatives au système d'exploitation](hardening_operating_system_recommendations.md), idéalement, des règles de pare-feu devraient déjà être en place avant le début de l'installation de GitLab, mais vous devriez tout de même définir un mot de passe sécurisé avant l'installation via `GITLAB_ROOT_PASSWORD`.

## Protocoles Git {#git-protocols}

Pour vous assurer que seuls les utilisateurs autorisés utilisent SSH pour l'accès Git, ajoutez ce qui suit à votre fichier `/etc/ssh/sshd_config` :

```shell
# Ensure only authorized users are using Git
AcceptEnv GIT_PROTOCOL
```

Cela garantit que les utilisateurs ne peuvent pas extraire des projets via SSH à moins d'avoir un compte GitLab valide pouvant effectuer des opérations `git` via SSH. Plus de détails sont disponibles dans [Configuring Git Protocol](../administration/git_protocol.md).

## E-mail entrant {#incoming-email}

Vous pouvez configurer GitLab Self-Managed pour permettre l'utilisation des e-mails entrants pour commenter ou créer des tickets et des merge requests par les utilisateurs enregistrés sur l'instance GitLab. Dans un environnement durci, vous ne devriez pas configurer cette fonctionnalité, car elle implique des communications externes envoyant des informations.

Si la fonctionnalité est requise, suivez les instructions dans la [documentation sur les e-mails entrants](../administration/incoming_email.md), avec les recommandations suivantes pour garantir une sécurité maximale :

- Dédiez une adresse e-mail spécifiquement aux e-mails entrants vers l'instance.
- Utilisez le [sous-adressage d'e-mail](../administration/incoming_email.md).
- Les comptes e-mail utilisés par les utilisateurs pour envoyer des e-mails doivent exiger et avoir l'authentification multifacteur (MFA) activée sur ces comptes.
- Pour Postfix en particulier, suivez la [documentation de configuration de Postfix pour les e-mails entrants](../administration/reply_by_email_postfix_setup.md).

## Réplication et basculement Redis {#redis-replication-and-failover}

Redis est utilisé sur une installation de package Linux pour la réplication et le basculement, et peut être configuré lorsque la mise à l'échelle nécessite cette capacité. Gardez à l'esprit que cela ouvre les ports TCP `6379` pour Redis et `26379` pour Sentinel. Suivez la [documentation sur la réplication et le basculement](../administration/redis/replication_and_failover.md), mais notez les adresses IP de tous les nœuds et configurez des règles de pare-feu entre les nœuds qui n'autorisent que l'autre nœud à accéder à ces ports spécifiques.

## Configuration de Sidekiq {#sidekiq-configuration}

Dans les [instructions de configuration d'un Sidekiq externe](../administration/sidekiq/_index.md), il existe de nombreuses références à la configuration des plages d'adresses IP. Vous devez [configurer HTTPS](../administration/sidekiq/_index.md#enable-https) et envisager de restreindre ces adresses IP aux systèmes spécifiques avec lesquels Sidekiq communique. Vous devrez peut-être également ajuster les règles de pare-feu au niveau du système d'exploitation.

## Signature S/MIME des e-mails {#smime-signing-of-email}

Si l'instance GitLab est configurée pour envoyer des notifications par e-mail aux utilisateurs, configurez la signature S/MIME pour aider les destinataires à s'assurer que les e-mails sont légitimes. Suivez les instructions sur la [signature des e-mails sortants](../administration/smime_signing_email.md).

## Registre de conteneurs {#container-registry}

Si Let's Encrypt est configuré, le registre de conteneurs est activé par défaut. Cela permet aux projets de stocker leurs propres images Docker. Suivez les instructions de configuration du [registre de conteneurs](../administration/packages/container_registry.md), afin de pouvoir notamment restreindre l'activation automatique sur les nouveaux projets et désactiver entièrement le registre de conteneurs. Vous devrez peut-être ajuster les règles de pare-feu pour autoriser l'accès. Si le système est complètement autonome, vous devriez restreindre l'accès au registre de conteneurs à localhost uniquement. Des exemples spécifiques de ports utilisés et leur configuration sont également inclus dans la documentation.
