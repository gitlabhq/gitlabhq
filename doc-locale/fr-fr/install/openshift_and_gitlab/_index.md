---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Exécutez GitLab Self-Managed et des flottes de runners GitLab sur OpenShift et intégrez-les avec l'agent GitLab pour Kubernetes."
title: "Prise en charge d'OpenShift"
---

La compatibilité OpenShift - GitLab peut être abordée sous trois aspects différents. Cette page vous aide à naviguer entre ces aspects et fournit des informations introductives pour démarrer avec OpenShift et GitLab.

## Qu'est-ce qu'OpenShift {#what-is-openshift}

OpenShift vous aide à développer, déployer et gérer des applications basées sur des conteneurs. Il vous fournit une plateforme en libre-service pour créer, modifier et déployer des applications à la demande. Cela permet d'accélérer les cycles de vie de développement et de release.

## Utiliser OpenShift pour exécuter GitLab Self-Managed {#use-openshift-to-run-gitlab-self-managed}

Vous pouvez exécuter GitLab dans un cluster OpenShift avec GitLab Operator. Pour plus d'informations sur la configuration de GitLab sur OpenShift, consultez [GitLab Operator](https://docs.gitlab.com/operator/).

## Utiliser OpenShift pour exécuter une flotte de runners GitLab {#use-openshift-to-run-a-gitlab-runner-fleet}

GitLab Operator n'inclut pas GitLab Runner. Pour installer et gérer une flotte de runners GitLab dans un cluster OpenShift, utilisez [GitLab Runner Operator](https://gitlab.com/gitlab-org/gl-openshift/gitlab-runner-operator).

### Déployer et intégrer avec OpenShift depuis GitLab {#deploy-to-and-integrate-with-openshift-from-gitlab}

Le déploiement d'applications personnalisées ou COTS sur OpenShift depuis GitLab est pris en charge à l'aide de [l'agent GitLab pour Kubernetes](../../user/clusters/agent/_index.md).

### Fonctionnalités GitLab non prises en charge {#unsupported-gitlab-features}

#### Docker-in-Docker {#docker-in-docker}

Lors de l'utilisation d'OpenShift pour exécuter une flotte de runners GitLab, certaines fonctionnalités GitLab ne sont pas prises en charge en raison du modèle de sécurité d'OpenShift. Les fonctionnalités nécessitant Docker-in-Docker peuvent ne pas fonctionner.

Pour Auto DevOps, les fonctionnalités suivantes ne sont pas encore prises en charge :

- [Auto Code Quality](../../ci/testing/code_quality.md)
- [Politiques d'approbation de licences](../../user/compliance/license_approval_policies.md)
- Auto Browser Performance Testing
- Auto Build
- [Analyse des conteneurs opérationnels](../../user/clusters/agent/vulnerabilities.md) (Remarque : [L'analyse des conteneurs](../../user/application_security/container_scanning/_index.md) dans un pipeline est prise en charge)
