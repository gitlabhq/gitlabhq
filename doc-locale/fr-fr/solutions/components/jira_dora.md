---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
description: "Intégrez Jira à GitLab pour la réplication des incidents en temps réel, permettant un suivi précis des métriques DORA, notamment le taux d'échec des modifications et le délai de restauration du service."
title: Intégration DORA de Jira à GitLab
---

{{< details >}}

- Édition : GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Avec GitLab, vous pouvez obtenir une visibilité sur les [métriques DORA](../../user/analytics/dora_metrics.md) pour vous aider à mesurer vos performances DevOps. Les 4 métriques sont :

- **Fréquence de déploiement** : nombre moyen de déploiements par jour en production
- **Délai d'exécution des changements** : nombre de secondes nécessaires pour livrer avec succès un commit en production (depuis le code commis jusqu'au code s'exécutant avec succès en production)
- **Taux d'échec des modifications** : % des déploiements qui provoquent un incident en production sur la période donnée
- **Délai de restauration du service** : durée médiane pendant laquelle un incident est resté ouvert dans un environnement de production

Tandis que les deux premières métriques sont générées à partir des CI/CD GitLab et des merge requests, les deux dernières dépendent de la création d'[incidents GitLab](../../operations/incident_management/manage_incidents.md).

Pour les équipes qui utilisent Jira pour le suivi des incidents, cela signifie que les incidents doivent être répliqués de Jira vers GitLab en temps réel. Ce projet explique comment mettre en place cette réplication.

> [!note]
> Une intégration similaire existe pour la réplication des tickets afin de générer des métriques Value Stream Analytics (délai d'exécution, tickets créés et tickets fermés). Si vous êtes intéressé par la réplication des tickets pour les métriques VSA, consultez l'[intégration VSA de Jira à GitLab](jira_vsa.md).

## Architecture {#architecture}

Nous devrons créer 2 workflows d'automatisation :

1. Créer des incidents GitLab lorsqu'ils sont créés dans Jira.
1. Résoudre les incidents GitLab lorsqu'ils sont résolus dans Jira.

### Création d'incidents {#incident-creation}

![Workflow montrant comment un incident Jira déclenche une alerte dans GitLab.](img/jira_dora_creation_flow_v18_1.png)

### Résolution d'incidents {#incident-resolution}

![Workflow montrant comment un incident Jira résolu déclenche la résolution d'un incident dans GitLab.](img/jira_dora_resolution_flow_v18_1.png)

## Configuration {#setup}

### Prérequis {#pre-requisites}

Cette procédure suppose que vous disposez :

- d'une licence GitLab Ultimate
- d'un projet Jira à partir duquel cloner les incidents

Jira impose des [limites](https://www.atlassian.com/software/jira/pricing) sur la fréquence des exécutions d'automatisation en fonction de votre licence Jira. À ce jour, les limites sont les suivantes :

| **Édition**   | **Limite**                    |
|------------|------------------------------|
| Gratuite       | 100 exécutions par mois           |
| Standard   | 1 700 exécutions par mois          |
| Premium    | 1 000 exécutions par utilisateur par mois |
| Enterprise | Exécutions illimitées               |

Chaque création d'incident compte comme 1 exécution, et chaque résolution d'incident compte comme 1 exécution.

### Point de terminaison d'alerte GitLab {#gitlab-alert-endpoint}

Nous devrons d'abord créer un point de terminaison HTTP qui peut être déclenché pour créer/résoudre des alertes dans GitLab, lesquelles créent/résolvent à leur tour des incidents.

1. Rendez-vous dans votre projet GitLab où vous souhaitez que les incidents Jira soient créés. Dans la barre latérale, accédez à **Paramètres** > **Supervision**. Développez la section **Alertes**.
1. Sous **Alertes**, passez à l'onglet **Paramètres d'alerte**. Cochez les cases suivantes, puis cliquez sur **Sauvegarder les modifications** :
   - _Créer un incident. Des incidents sont créés pour chaque alerte déclenchée._
   - _Fermer automatiquement l'incident associé lorsqu'une notification d'alerte de récupération résout une alerte_
1. Sous **Alertes**, passez à l'onglet **Intégrations actuelles**. Cliquez sur **Ajouter une nouvelle intégration**. Définissez le **Integration type** sur `HTTP Endpoint`, donnez-lui un nom (par exemple `Jira incident sync`), et réglez **Activer l'intégration** sur **Actif**. Nous reviendrons personnaliser le mappage de la charge utile des alertes une fois que nous aurons configuré nos workflows d'automatisation Jira.
1. Cliquez sur **Enregistrer l'intégration**. Un message devrait apparaître indiquant « Intégration enregistrée avec succès ». Cliquez sur **Afficher l'URL et la clé d'autorisation**.
1. Nous aurons besoin de l'URL du point de terminaison et de la clé d'autorisation lors de la configuration de notre workflow d'automatisation Jira et de notre fonction Lambda. Conservez donc ces informations pour plus tard.

### Workflow de création d'incidents Jira {#jira-incident-creation-workflow}

Pour déclencher automatiquement le point de terminaison d'alerte GitLab lors de la création d'un incident Jira, nous utiliserons l'[automatisation Jira](https://community.atlassian.com/t5/Jira-articles/Automation-for-Jira-Send-web-request-using-Jira-REST-API/ba-p/1443828).

1. Accédez à votre projet Jira où vos incidents sont gérés. Dans la barre latérale, accédez à **Paramètres du projet** > **Automation** (il se peut que vous deviez faire défiler vers le bas pour le trouver).
1. À partir d'ici, nous pouvons gérer nos workflows d'automatisation Jira. En haut à droite, cliquez sur **Create rule**.
1. Pour votre déclencheur, recherchez et sélectionnez **Ticket créé**. Cliquez sur **Sauvegarder**.
1. Ensuite, sélectionnez **IF : Add a condition**. Vous pouvez ici spécifier les conditions à vérifier pour déterminer si le ticket créé est lié à un incident. Pour ce guide, nous sélectionnerons **Issue fields condition**. Sous **Champ**, nous sélectionnerons **Résumé**, la **Condition** sera définie sur **contains**, et la valeur sera `incident`. Cliquez sur **Sauvegarder**.
1. Une fois notre déclencheur et notre condition définis, sélectionnez **THEN : Add an action**. Recherchez et sélectionnez **Send web request**.
1. Définissez la **Web request URL** sur votre **URL du crochet Web** GitLab de la section précédente.
1. Consultez la documentation GitLab pour les [options d'authentification du point de terminaison](../../operations/incident_management/integrations.md#authorization). Pour ce guide, nous utiliserons la méthode [Bearer authorization header](../../operations/incident_management/integrations.md#bearer-authorization-header). Dans votre configuration d'automatisation Jira, ajoutez les en-têtes suivants :

   | Nom | Valeur |
   | ------ | ------ |
   | Authorization | Bearer `<GitLab endpoint auth key de la section précédente>` |
   | Content-Type | `application/json` |

   - Vous pouvez définir l'en-tête `Authorization` sur « Hidden ».
1. Assurez-vous que la **HTTP method** est définie sur **POST**, et définissez le **Web request body** sur **Issue data (Jira format)**.
1. Enfin, cliquez sur **Sauvegarder**, donnez un nom à votre automatisation (par exemple `Jira incident creation`), puis cliquez sur **Turn it on**. En haut à droite, cliquez sur **Return to list**.
1. La dernière chose à faire est de mapper les valeurs de la charge utile Jira sur les paramètres d'alerte GitLab. Si vous prévoyez également de configurer la résolution des incidents pour la métrique **Délai de restauration du service**, ignorez cette étape pour l'instant. Sinon, accédez à [Mapper les valeurs de la charge utile Jira sur les paramètres d'alerte GitLab](#map-jira-payload-values-to-gitlab-alert-parameters) et suivez les étapes qui y sont décrites.

Une fois les valeurs de la charge utile mappées, les incidents que vous créez dans Jira seront également créés dans GitLab. Cela vous permettra de consulter la métrique DORA **Taux d'échec des modifications**.

### Workflow de résolution d'incidents Jira {#jira-incident-resolution-workflow}

Créez un autre workflow d'automatisation Jira comme décrit ci-dessus, avec les modifications suivantes :

1. Définissez le déclencheur sur **Issue transitioned**. Le champ « From status » peut être laissé vide. Le champ « To status » peut être défini sur n'importe quel statut représentant un incident résolu selon votre workflow (par exemple `Closed`, `Done`, `Resolved`, `Completed`).
1. Veillez à nommer l'automatisation de manière appropriée (par exemple `Jira incident close`).

### Mapper les valeurs de la charge utile Jira sur les paramètres d'alerte GitLab {#map-jira-payload-values-to-gitlab-alert-parameters}

1. Une fois votre workflow d'automatisation Jira créé, cliquez sur le workflow que vous venez de créer, puis sélectionnez **Then : Send web request**.
1. Développez la section **Validate your web request configuration**, et saisissez une clé de ticket _résolu_ pour le test (vous devez disposer d'une clé de ticket existante que vous pouvez utiliser). Cliquez sur **Valider**.
1. Développez la section **Request POST**, puis développez la section **Payload**. Copiez l'intégralité de la charge utile.
1. Retournez dans votre projet GitLab, et accédez à **Paramètres** > **Supervision** > **Alertes** > **Current Integrations**. Cliquez sur l'icône « paramètres » à côté de l'intégration que vous avez créée précédemment, et passez à l'onglet **Configurer les détails**.
1. Sous **Customize alert payload mapping**, collez la charge utile que vous avez copiée depuis Jira à l'étape 3. Cliquez ensuite sur **Analyser les champs de la charge utile**.
1. Mappez les champs comme indiqué ci-dessous :

   | Clé d'alerte GitLab | Clé d'alerte de la charge utile |
   | ------ | ------ |
   | Title | issue.fields.summary |
   | Description | issue.fields.status.description |
   | End time | issue.fields.resolutiondate<sup>1</sup> |
   | Monitoring tool | issue.fields.reporter.accountType |
   | Gravité | issue.fields.priority.name |
   | Fingerprint | issue.key |
   | Environment | issue.fields.project.name |

<sup>1</sup> Ceci n'est nécessaire que si vous avez configuré l'automatisation de la résolution des incidents. Si ce champ n'apparaît pas comme option, assurez-vous d'avoir saisi une clé de ticket _résolu_ pour le test à l'étape 2 ci-dessus.

1. Enfin, cliquez sur **Enregistrer l'intégration**.

À ce stade, les incidents que vous résolvez dans Jira seront également résolus dans GitLab. Cela vous permettra de consulter la métrique DORA **Délai de restauration du service**.

## Ressources {#resources}

- [Métriques DORA](../../user/analytics/dora_metrics.md)
  - [Mesurer les métriques DORA avec Jira](../../user/analytics/dora_metrics.md#with-jira)
- [Gestion des incidents GitLab](../../operations/incident_management/manage_incidents.md)
- [Points de terminaison HTTP GitLab](../../operations/incident_management/integrations.md#alerting-endpoints)
  - [Autorisation des points de terminaison HTTP GitLab](../../operations/incident_management/integrations.md#authorization)
  - [Paramètres d'alerte GitLab](../../operations/incident_management/integrations.md#customize-the-alert-payload-outside-of-gitlab)
  - [Alertes de récupération GitLab](../../operations/incident_management/integrations.md#recovery-alerts)
- [Automatisation Jira avec des requêtes web](https://community.atlassian.com/t5/Jira-articles/Automation-for-Jira-Send-web-request-using-Jira-REST-API/ba-p/1443828)
