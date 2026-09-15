---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ServiceNow
description: "Configurez ServiceNow pour centraliser et automatiser les workflows GitLab."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

ServiceNow propose plusieurs intégrations pour vous aider à centraliser et à automatiser la gestion de vos workflows GitLab.

Pour simplifier votre stack et rationaliser vos processus, utilisez les [approbations de déploiement](../../api/oauth2.md) GitLab dès que possible.

## GitLab spoke {#gitlab-spoke}

Avec le GitLab spoke dans ServiceNow, vous pouvez automatiser des actions pour les projets, groupes, utilisateurs, tickets, merge requests, branches et dépôts GitLab.

Pour obtenir la liste complète des fonctionnalités, consultez la [documentation du GitLab spoke (version Xanadu)](https://docs.servicenow.com/bundle/xanadu-integrate-applications/page/administer/integrationhub-store-spokes/concept/gitlab-spoke.html).

Vous devez [configurer GitLab en tant que fournisseur de services d'authentification OAuth 2.0](../../integration/oauth_provider.md), ce qui implique de créer une application, puis de fournir l'identifiant d'application et le secret dans ServiceNow.

## GitLab SCM and Continuous Integration for DevOps {#gitlab-scm-and-continuous-integration-for-devops}

Dans ServiceNow DevOps, vous pouvez vous intégrer aux dépôts GitLab et à GitLab CI/CD pour centraliser votre vue de l'activité GitLab et de vos processus de gestion des changements. Vous pouvez :

- Suivez les informations sur l'activité dans les dépôts GitLab et les pipelines CI/CD dans ServiceNow.
- Intégrez les pipelines CI/CD GitLab en automatisant la création de tickets de changement et en définissant les critères permettant l'auto-approbation des changements.

Pour plus d'informations, consultez les ressources ServiceNow suivantes :

- [Page d'accueil de ServiceNow DevOps](https://www.servicenow.com/products/devops.html)
- [Documentation de ServiceNow DevOps](https://docs.servicenow.com/bundle/tokyo-devops/page/product/enterprise-dev-ops/concept/dev-ops-bundle-landing-page.html)
- [GitLab SCM and Continuous Integration for DevOps](https://store.servicenow.com/sn_appstore_store.do#!/store/application/54dc4eacdbc2dcd02805320b7c96191e/)
