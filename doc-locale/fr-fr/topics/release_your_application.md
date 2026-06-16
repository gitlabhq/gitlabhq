---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Environnements, packages, environnements éphémères, GitLab Pages."
title: Déployer et releaser votre application
---

Le déploiement est l'étape du processus de livraison logicielle au cours de laquelle votre application est déployée vers son infrastructure cible finale.

Vous pouvez déployer votre application en interne ou de manière publique. Prévisualisez une release dans un environnement éphémère, et utilisez des feature flags pour déployer des fonctionnalités de manière progressive.

{{< cards >}}

- [Prise en main](../user/get_started/get_started_deploy_release.md)
- [Packages et registres](../user/packages/_index.md)
- [Environnements](../ci/environments/_index.md)
- [Déploiements](../ci/environments/deployments.md)
- [Releases](../user/project/releases/_index.md)
- [Déployer une application de manière progressive](../ci/environments/incremental_rollouts.md)
- [Feature flags](../operations/feature_flags.md)
- [GitLab Pages](../user/project/pages/_index.md)

{{< /cards >}}

## Sujets connexes {#related-topics}

- [Auto DevOps](autodevops/_index.md) est un workflow automatisé basé sur CI/CD qui prend en charge l'ensemble de la chaîne d'approvisionnement logicielle : compilation, test, lint, package, déploiement, sécurisation et surveillance des applications à l'aide de GitLab CI/CD. Il fournit un ensemble de modèles prêts à l'emploi qui couvrent la grande majorité des cas d'utilisation.
- [Auto Deploy](autodevops/stages.md#auto-deploy) est l'étape DevOps dédiée au déploiement de logiciels à l'aide de GitLab CI/CD. Auto Deploy dispose d'une prise en charge intégrée des déploiements EC2 et ECS.
- Déployez vers des clusters Kubernetes en utilisant l'[agent GitLab pour Kubernetes](../user/clusters/agent/install/_index.md).
- Utilisez des images Docker pour exécuter des commandes AWS depuis GitLab CI/CD, ainsi qu'un modèle pour faciliter le [déploiement vers AWS](../ci/cloud_deployment/_index.md).
- Utilisez GitLab CI/CD pour cibler tout type d'infrastructure accessible par GitLab Runner. Les [variables d'environnement utilisateur et prédéfinies](../ci/variables/_index.md) et les modèles CI/CD permettent de configurer un grand nombre de stratégies de déploiement.
- Utilisez [Cloud Seed](../cloud_seed/_index.md) de GitLab pour configurer les informations d'identification de déploiement et déployer votre application sur Google Cloud Run avec un minimum de friction.
