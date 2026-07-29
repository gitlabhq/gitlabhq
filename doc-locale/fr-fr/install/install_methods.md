---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Linux, Helm, Docker, Operator, source ou scripts."
title: "Méthodes d'installation"
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Vous pouvez installer GitLab sur plusieurs [fournisseurs cloud](cloud_providers.md), ou utiliser l'une des méthodes suivantes.

## Package Linux {#linux-package}

Le package Linux inclut les packages officiels `deb` et `rpm`. Le package contient GitLab et ses composants dépendants, notamment PostgreSQL, Redis et Sidekiq.

Utilisez cette méthode si vous souhaitez la méthode la plus mature et la plus évolutive. Cette version est également utilisée sur GitLab.com.

Pour plus d'informations, consultez :

- [Package Linux](package/_index.md)
- [Architectures de référence](../administration/reference_architectures/_index.md)
- [Configuration requise](requirements.md)
- [Systèmes d'exploitation Linux pris en charge](package/_index.md#supported-platforms)

## Chart Helm {#helm-chart}

Utilisez un chart pour installer une version cloud-native de GitLab et ses composants sur Kubernetes.

Utilisez cette méthode si votre infrastructure est sur Kubernetes et que vous êtes familiarisé avec son fonctionnement.

Avant d'utiliser cette méthode d'installation, tenez compte des points suivants :

- La gestion, l'observabilité et certains autres concepts diffèrent des déploiements traditionnels.
- L'administration et le dépannage nécessitent des connaissances de Kubernetes.
- Cette méthode peut être plus coûteuse pour les installations de petite taille.
- L'installation par défaut nécessite plus de ressources qu'un déploiement de package Linux sur un seul nœud, car la plupart des services sont déployés de manière redondante.

Pour plus d'informations, consultez [Charts Helm](https://docs.gitlab.com/charts/).

## GitLab Operator {#gitlab-operator}

Pour installer une version cloud-native de GitLab et ses composants dans Kubernetes, utilisez GitLab Operator. Cette méthode d'installation et de gestion suit le [modèle Kubernetes Operator](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/).

Utilisez cette méthode si votre infrastructure est sur Kubernetes ou [OpenShift](openshift_and_gitlab/_index.md), et que vous êtes familiarisé avec le fonctionnement des Operators.

Cette méthode d'installation offre des fonctionnalités supplémentaires par rapport à la méthode d'installation via chart Helm, notamment l'automatisation des [étapes de mise à niveau de GitLab](https://docs.gitlab.com/operator/gitlab_upgrades/). Les considérations relatives au chart Helm s'appliquent également ici.

Envisagez la méthode d'installation via chart Helm si vous êtes limité par les [problèmes connus de GitLab Operator](https://docs.gitlab.com/operator/#known-issues).

Pour plus d'informations, consultez [GitLab Operator](https://docs.gitlab.com/operator/).

## Docker {#docker}

Installe les packages GitLab dans un conteneur Docker.

Utilisez cette méthode si vous êtes familiarisé avec Docker.

Pour plus d'informations, consultez [Docker](docker/_index.md).

## Auto-compilé {#self-compiled}

Installe GitLab et ses composants depuis zéro.

Utilisez cette méthode si aucune des méthodes précédentes n'est disponible pour votre plateforme. Peut être utilisé pour les systèmes non pris en charge tels que \*BSD.

Pour plus d'informations, consultez [l'installation auto-compilée](self_compiled/_index.md).

## GitLab Environment Toolkit (GET) {#gitlab-environment-toolkit-get}

[GitLab Environment Toolkit (GET)](https://gitlab.com/gitlab-org/gitlab-environment-toolkit#documentation) est un ensemble de scripts Terraform et Ansible basés sur des pratiques recommandées.

Vous pouvez utiliser GET pour déployer des environnements GitLab à grande échelle en suivant l'[architecture de référence](../administration/reference_architectures/_index.md) sur les principaux fournisseurs cloud sélectionnés (GCP, AWS et Azure).

Cette méthode d'installation présente certaines [limitations](https://gitlab.com/gitlab-org/gitlab-environment-toolkit#missing-features-to-be-aware-of) et nécessite une configuration manuelle pour les environnements de production.

## Distributions Linux non prises en charge et systèmes d'exploitation de type Unix {#unsupported-linux-distributions-and-unix-like-operating-systems}

L'[installation auto-compilée](self_compiled/_index.md) de GitLab sur les systèmes d'exploitation suivants est possible, mais non prise en charge :

- Arch Linux
- FreeBSD
- Gentoo
- macOS

## Microsoft Windows {#microsoft-windows}

GitLab est développé pour les systèmes d'exploitation basés sur Linux. Il ne fonctionne pas sur Microsoft Windows et il n'est pas prévu de le prendre en charge dans un avenir proche. Pour connaître le dernier statut de développement, consultez le [ticket 22337](https://gitlab.com/gitlab-org/gitlab/-/issues/22337). Envisagez d'utiliser une machine virtuelle pour exécuter GitLab.
