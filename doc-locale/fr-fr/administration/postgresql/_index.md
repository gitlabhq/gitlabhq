---
stage: Data Access
group: Database Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Configurer PostgreSQL pour la mise à l'échelle"
description: "Configurez PostgreSQL pour la mise à l'échelle."
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Dans cette section, vous êtes guidé dans la configuration d'une base de données PostgreSQL à utiliser avec GitLab dans l'une de nos [architectures de référence](../reference_architectures/_index.md).

## Options de configuration {#configuration-options}

Choisissez l'une des options de configuration PostgreSQL suivantes :

### PostgreSQL autonome pour les installations de packages Linux {#standalone-postgresql-for-linux-package-installations}

Cette configuration est prévue pour les cas où vous avez installé GitLab à l'aide du [package Linux](https://about.gitlab.com/install/) (CE ou EE), afin d'utiliser PostgreSQL intégré en activant uniquement son service.

Apprenez comment [configurer une instance PostgreSQL autonome](standalone.md) pour les installations de packages Linux.

### Fournir votre propre instance PostgreSQL {#provide-your-own-postgresql-instance}

Cette configuration est prévue pour les cas où vous avez installé GitLab à l'aide du [package Linux](https://about.gitlab.com/install/) (CE ou EE), ou avez [compilé vous-même](../../install/self_compiled/_index.md) votre installation, mais souhaitez utiliser votre propre serveur PostgreSQL externe.

Apprenez comment [configurer une instance PostgreSQL externe](external.md).

Lors de la configuration d'une base de données externe, il existe certaines métriques utiles pour la surveillance et le dépannage. Lors de la configuration d'une base de données externe, des paramètres de surveillance et de journalisation sont requis pour résoudre divers problèmes liés à la base de données. En savoir plus sur la [configuration de la surveillance et de la journalisation pour les bases de données externes](external_metrics.md).

### Réplication et basculement PostgreSQL pour les installations de packages Linux {#postgresql-replication-and-failover-for-linux-package-installations}

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Cette configuration est prévue pour les cas où vous avez installé GitLab à l'aide du [package Linux **Enterprise Edition** (EE)](https://about.gitlab.com/install/?version=ee).

Tous les outils nécessaires comme PostgreSQL, PgBouncer et Patroni sont intégrés dans le package, vous pouvez donc l'utiliser pour configurer l'ensemble de l'infrastructure PostgreSQL (primaire, réplica).

Apprenez comment [configurer la réplication et le basculement PostgreSQL](replication_and_failover.md) pour les installations de packages Linux.

## Sujets connexes {#related-topics}

- [Gérer les extensions PostgreSQL](extensions.md)
- [Utilisation du service PgBouncer intégré](pgbouncer.md)
- [Équilibrage de charge de base de données](database_load_balancing.md)
- [Déplacement des bases de données GitLab vers une autre instance PostgreSQL](moving.md)
- Guides de base de données pour le développement GitLab
- [Mettre à niveau une base de données externe](external_upgrade.md)
- [Mise à niveau des systèmes d'exploitation pour PostgreSQL](upgrading_os.md)
