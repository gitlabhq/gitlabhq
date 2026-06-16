---
stage: Verify
group: Runner Core
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Adoptez les meilleures pratiques pour gérer votre infrastructure.
title: Premiers pas dans la gestion de votre infrastructure
---

Avec l'essor des approches DevOps et SRE, la gestion de l'infrastructure est devenue codifiée et automatisable. Vous pouvez désormais adopter les meilleures pratiques de développement logiciel dans la gestion de votre infrastructure.

Les tâches quotidiennes d'une équipe opérationnelle classique ont évolué et ressemblent davantage au développement logiciel traditionnel. Dans le même temps, les ingénieurs logiciels sont de plus en plus amenés à contrôler l'ensemble de leur cycle de vie DevOps, y compris les déploiements et la livraison.

GitLab offre diverses fonctionnalités pour accélérer et simplifier vos pratiques de gestion de l'infrastructure.

La gestion de l'infrastructure fait partie d'un workflow plus large :

![Gérer l'infrastructure dans la section Release du cycle de vie DevOps GitLab.](img/get_started_managing_infrastructure_v16_11.png)

## Étape 1 :  Utiliser du code pour gérer votre infrastructure {#step-1-use-code-to-manage-your-infrastructure}

GitLab dispose d'intégrations poussées avec Terraform pour exécuter des pipelines d'Infrastructure as Code et prendre en charge divers processus. Terraform est considéré comme la référence en matière de provisionnement d'infrastructure cloud. Les différentes intégrations GitLab vous aident à :

- Démarrer rapidement sans configuration préalable.
- Collaborer autour des changements d'infrastructure dans les merge requests de la même manière que vous le feriez pour des modifications de code.
- Passer à l'échelle grâce à un registre de modules.

Pour plus d'informations, consultez :

- [Infrastructure as Code](../infrastructure/iac/_index.md)

## Étape 2 :  Interagir avec les clusters Kubernetes {#step-2-interact-with-kubernetes-clusters}

L'intégration de GitLab avec Kubernetes vous aide à installer, configurer, gérer, déployer et dépanner les applications de cluster. Avec l'agent GitLab pour Kubernetes, vous pouvez connecter des clusters derrière un pare-feu, avoir un accès en temps réel aux endpoints d'API, effectuer des déploiements en mode pull ou push pour les environnements de production et hors production, et bien plus encore.

Pour plus d'informations, consultez :

- [Créer des clusters Kubernetes dans le cloud](../clusters/create/_index.md)
- [Connecter des clusters Kubernetes avec GitLab](../clusters/agent/_index.md)

## Étape 3 :  Documenter les procédures avec des runbooks {#step-3-document-procedures-with-runbooks}

Les runbooks sont un ensemble de procédures documentées qui expliquent comment accomplir une tâche, comme démarrer, arrêter, déboguer ou dépanner un système. Dans GitLab, les runbooks sont créés en Markdown. Ils peuvent inclure divers éléments, notamment du texte, des extraits de code, des images et des liens.

Les runbooks dans GitLab s'intègrent aux autres fonctionnalités GitLab, comme les pipelines CI/CD et les tickets. Vous pouvez déclencher des runbooks automatiquement en fonction d'événements ou de conditions spécifiques, par exemple lorsqu'un pipeline est réussi ou qu'un ticket est créé. De plus, les utilisateurs peuvent lier des runbooks à des tickets, des merge requests et d'autres objets GitLab.

Pour plus d'informations, consultez :

- [Fonctionnement des runbooks exécutables dans GitLab](../project/clusters/runbooks/_index.md)
