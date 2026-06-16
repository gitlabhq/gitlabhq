---
stage: Developer Experience
group: API Platform
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Interagissez par programmation avec GitLab.
title: Premiers pas pour étendre GitLab
---

Interagissez par programmation avec GitLab. Automatisez des tâches, intégrez d'autres outils et créez des workflows personnalisés. GitLab prend également en charge les plugins et les hooks personnalisés.

Suivez ces étapes pour en savoir plus sur l'extension de GitLab.

## Étape 1 :  Configurer les intégrations {#step-1-set-up-integrations}

GitLab dispose de plusieurs intégrations majeures qui peuvent contribuer à rationaliser votre workflow de développement.

Ces intégrations couvrent un large éventail de domaines, notamment :

- **Authentification** :  OAuth, SAML, LDAP
- **Planning** :  Jira, Bugzilla, Redmine, Pivotal Tracker
- **Communication** :  Slack, Microsoft Teams, Mattermost
- **Sécurité** :  Checkmarx, Veracode, Fortify

Pour plus d'informations, voir :

- [La liste des intégrations](../../integration/_index.md)

## Étape 2 :  Configurer les webhooks {#step-2-set-up-webhooks}

Utilisez des webhooks pour notifier les services externes des événements GitLab.

Les webhooks écoutent des événements spécifiques tels que les push, les merges et les commits. Lorsque l'un de ces événements se produit, GitLab envoie un payload HTTP POST à l'URL configurée du webhook. Le payload envoyé par le webhook fournit des détails sur l'événement, comme le nom de l'événement, l'ID du projet, ainsi que les informations sur l'utilisateur et le commit. Le système externe identifie et traite ensuite l'événement.

Par exemple, vous pouvez avoir un webhook qui déclenche un nouveau build Jenkins à chaque fois qu'un code est poussé vers GitLab.

Vous pouvez configurer des webhooks par projet ou pour l'ensemble de l'instance GitLab. Les webhooks par projet écoutent les événements d'un projet particulier.

Vous pouvez utiliser des webhooks pour intégrer GitLab à divers outils externes, notamment les systèmes CI/CD, les plateformes de chat et de messagerie, ainsi que les outils de surveillance et de journalisation.

Pour plus d'informations, voir :

- [Webhooks](../../user/project/integrations/webhooks.md)

## Étape 3 :  Utiliser les API {#step-3-use-the-apis}

Utilisez l'API REST ou l'API GraphQL pour interagir par programmation avec GitLab et créer des intégrations personnalisées, récupérer des données ou automatiser des processus. Les API couvrent différents aspects de GitLab, notamment les projets, les tickets, les merge requests et les dépôts.

Les API REST de GitLab suivent les principes RESTful et utilisent JSON comme format de données pour les requêtes et les réponses. Vous pouvez authentifier ces requêtes et réponses en utilisant des jetons d'accès personnels ou des tokens OAuth 2.0.

GitLab propose également une API GraphQL, plus flexible et plus efficace pour interroger des données.

Commencez par explorer les API avec cURL ou un client REST pour comprendre les requêtes et les réponses. Utilisez ensuite l'API pour automatiser des tâches, comme la création de projets et l'ajout de membres à des groupes.

Pour plus d'informations, voir :

- [L'API REST](../api_resources.md)
- [L'API GraphQL](../graphql/reference/_index.md)

## Étape 4 :  Utiliser le CLI GitLab {#step-4-use-the-gitlab-cli}

Le CLI GitLab peut vous aider à effectuer diverses opérations GitLab et à gérer votre instance GitLab.

Vous pouvez utiliser le CLI GitLab pour effectuer toutes sortes de tâches en masse plus rapidement, par exemple :

- Créer de nouveaux projets, groupes et autres ressources GitLab
- Gérer les utilisateurs et les permissions
- Importer et exporter des projets entre des instances GitLab
- Déclencher des pipelines CI/CD

Pour plus d'informations, voir :

- [Installer le CLI GitLab](https://gitlab.com/gitlab-org/cli/#installation)
