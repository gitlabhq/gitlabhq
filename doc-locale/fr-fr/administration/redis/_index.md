---
stage: Tenant Scale
group: Tenant Services
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Configurer Redis pour la mise à l'échelle"
description: "Configurer Redis pour la mise à l'échelle."
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

En fonction de la configuration de votre infrastructure et de la façon dont vous avez installé GitLab, il existe plusieurs façons de configurer Redis.

Vous pouvez choisir d'installer et de gérer Redis et Sentinel vous-même, d'utiliser une solution cloud hébergée, ou d'utiliser ceux fournis avec les packages Linux pour vous concentrer uniquement sur la configuration. Choisissez celui qui convient le mieux à vos besoins.

## Utiliser Valkey à la place de Redis {#use-valkey-instead-of-redis}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/omnibus-gitlab/-/merge_requests/9113) dans GitLab 18.9 en tant que [bêta](../../policy/development_stages_support.md#beta).
- [Disponible généralement](https://gitlab.com/gitlab-org/gitlab/-/work_items/585839) dans GitLab 19.0.

{{< /history >}}

[Valkey](https://valkey.io/) est un magasin de données clé/valeur open source haute performance, entièrement compatible avec Redis. GitLab prend en charge Valkey comme alternative à Redis.

Lorsqu'il est activé, Valkey utilise par défaut les mêmes conventions d'utilisateur, de groupe, de répertoire de données et de répertoire de journaux que Redis.

Pour passer à Valkey sur les nœuds Redis, ajoutez ce qui suit dans `/etc/gitlab/gitlab.rb` :

```ruby
redis['backend'] = 'valkey'
```

### Problèmes connus {#known-issues}

- En raison du [ticket 589642](https://gitlab.com/gitlab-org/gitlab/-/issues/589642) connu, la zone d'administration signale incorrectement la version de Valkey. Ce problème n'affecte pas la version de Valkey installée ni son fonctionnement.

## Réplication Redis et basculement avec le package Linux {#redis-replication-and-failover-using-the-linux-package}

Cette configuration est destinée aux cas où vous avez installé GitLab à l'aide du [package Linux **Enterprise Edition** (EE)](https://about.gitlab.com/install/?version=ee).

Redis et Sentinel sont tous deux inclus dans le package, vous pouvez donc l'utiliser pour configurer l'ensemble de l'infrastructure Redis (primaire, réplica et sentinel).

Pour plus d'informations, consultez [la réplication Redis et le basculement avec le package Linux](replication_and_failover.md).

### Sécuriser Redis et Sentinel avec TLS {#secure-redis-and-sentinel-with-tls}

Sécurisez les communications Redis et Sentinel à l'aide de TLS (Transport Layer Security). Pour des instructions détaillées sur l'activation du TLS standard et du TLS mutuel (mTLS), consultez [la sécurisation de Redis et Sentinel avec TLS](tls.md).

## Réplication Redis et basculement avec Redis non intégré {#redis-replication-and-failover-using-the-non-bundled-redis}

Cette configuration est destinée aux cas où vous disposez d'une installation par [package Linux](https://about.gitlab.com/install/) ou d'une [installation compilée manuellement](../../install/self_compiled/_index.md), mais où vous souhaitez utiliser vos propres serveurs Redis et Sentinel externes.

Pour plus d'informations, consultez [la réplication Redis et le basculement en fournissant votre propre instance](replication_and_failover_external.md).

## Redis autonome avec le package Linux {#standalone-redis-using-the-linux-package}

Cette configuration est destinée aux cas où vous avez installé le [package Linux **Community Edition** (CE)](https://about.gitlab.com/install/?version=ce) pour utiliser Redis intégré, afin de pouvoir utiliser le package avec uniquement le service Redis activé.

Pour plus d'informations, consultez [Redis autonome avec le package Linux](standalone.md).
