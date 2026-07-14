---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configurez un serveur Redis autonome avec le package Linux. Utilisez cette configuration pour les petites installations GitLab qui ne nécessitent pas de réplication Redis ni de basculement.
title: Redis autonome utilisant le package Linux
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Le package Linux peut être utilisé pour configurer un serveur Redis autonome. Dans cette configuration, Redis n'est pas mis à l'échelle et représente un point de défaillance unique. Cependant, dans un environnement mis à l'échelle, l'objectif est de permettre à l'environnement de gérer davantage d'utilisateurs ou d'augmenter le débit. Redis lui-même est généralement stable et peut gérer de nombreuses requêtes, ce qui en fait un compromis acceptable de n'avoir qu'une seule instance. Consultez la page [architectures de référence](../reference_architectures/_index.md) pour une vue d'ensemble des options de mise à l'échelle de GitLab.

## Configurer l'instance Redis autonome {#set-up-the-standalone-redis-instance}

Les étapes ci-dessous sont le minimum nécessaire pour configurer un serveur Redis avec le package Linux :

1. Connectez-vous en SSH au serveur Redis.
1. [Téléchargez et installez](https://about.gitlab.com/install/) le package Linux souhaité en suivant **steps 1 and 2** de la page de téléchargement de GitLab. Ne suivez pas d'autres étapes sur la page de téléchargement.

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez le contenu suivant :

   ```ruby
   ## Enable Redis and disable all other services
   ## https://docs.gitlab.com/omnibus/roles/
   roles ['redis_master_role']

   ## Redis configuration
   redis['bind'] = '0.0.0.0'
   redis['port'] = 6379
   redis['password'] = '<redis_password>'

   ## Disable automatic database migrations
   ## Only the primary GitLab application server should handle migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. [Reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.
1. Notez l'adresse IP ou le nom d'hôte, le port et le mot de passe Redis du nœud Redis. Ces informations sont nécessaires lors de la [configuration des serveurs d'application GitLab](#set-up-the-gitlab-rails-application-instance).

Les [options de configuration avancées](https://docs.gitlab.com/omnibus/settings/redis/) sont prises en charge et peuvent être ajoutées si nécessaire.

## Configurer l'instance d'application GitLab Rails {#set-up-the-gitlab-rails-application-instance}

Sur l'instance où GitLab est installé :

1. Modifiez le fichier `/etc/gitlab/gitlab.rb` et ajoutez le contenu suivant :

   ```ruby
   ## Disable Redis
   redis['enable'] = false

   gitlab_rails['redis_host'] = 'redis.example.com'
   gitlab_rails['redis_port'] = 6379

   ## Required if Redis authentication is configured on the Redis node
   gitlab_rails['redis_password'] = '<redis_password>'
   ```

1. Enregistrez vos modifications dans `/etc/gitlab/gitlab.rb`.

1. [Reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

## Utiliser Valkey à la place de Redis {#use-valkey-instead-of-redis}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9113) dans GitLab 18.9 en tant que [bêta](../../policy/development_stages_support.md#beta).
- [Disponible en version générale](https://gitlab.com/gitlab-org/gitlab/-/work_items/585839) dans GitLab 19.0.

{{< /history >}}

Vous pouvez utiliser [Valkey](https://valkey.io/) comme remplacement compatible de Redis. Valkey utilise les mêmes options de configuration que Redis.

Pour utiliser Valkey à la place de Redis sur un nœud autonome :

1. Modifiez `/etc/gitlab/gitlab.rb` et ajoutez le contenu suivant :

   ```ruby
   ## Enable Redis and disable all other services
   ## https://docs.gitlab.com/omnibus/roles/
   roles ['redis_master_role']

   ## Switch to Valkey
   redis['backend'] = 'valkey'

   ## Redis configuration
   redis['bind'] = '0.0.0.0'
   redis['port'] = 6379
   redis['password'] = '<redis_password>'

   ## Disable automatic database migrations
   gitlab_rails['auto_migrate'] = false
   ```

1. [Reconfigurez GitLab](../restart_gitlab.md#reconfigure-a-linux-package-installation) pour que les modifications prennent effet.

La configuration de l'application GitLab Rails reste la même. Configurez `gitlab_rails['redis_host']`, `gitlab_rails['redis_port']` et `gitlab_rails['redis_password']` comme vous le feriez pour Redis.

### Problèmes connus {#known-issues}

- En raison du [ticket 589642](https://gitlab.com/gitlab-org/gitlab/-/issues/589642) connu, la zone d'administration signale incorrectement la version de Valkey. Ce ticket n'affecte pas la version de Valkey installée ni son fonctionnement.

## Dépannage {#troubleshooting}

Consultez le [guide de dépannage Redis](troubleshooting.md).
