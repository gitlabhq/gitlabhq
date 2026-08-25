---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: Intégration Jira à GitLab VSA
---

{{< details >}}

- Édition : GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab [Value Stream Analytics (VSA)](../../user/group/value_stream_analytics/_index.md) fournit des informations précieuses sur votre workflow de développement, en suivant des métriques clés telles que :

- **Durée d'exécution** : délai entre la création et la clôture d'un ticket
- **Tickets créés** : nombre de nouveaux tickets sur une période donnée
- **Tickets fermés** : nombre de tickets résolus sur une période donnée

Pour les équipes utilisant Jira pour le suivi des tickets tout en tirant parti de GitLab pour le développement, cette intégration permet la réplication automatique des tickets Jira vers GitLab en temps réel. Cela garantit des métriques VSA précises sans demander aux équipes de modifier leurs workflows Jira existants.

L'intégration alimente également le **Tableau de bord des chaînes de valeur** GitLab (GitLab Ultimate uniquement), qui offre une vue d'ensemble des métriques DevSecOps clés et est accessible sous **Analyse** > **Tableaux de bord de données d'analyse** dans votre projet ou groupe GitLab.

> [!note]
> Une intégration similaire existe pour la réplication des incidents afin de générer des métriques DORA spécifiques (taux d'échec des changements et délai de restauration du service). Si vous êtes intéressé par la réplication des incidents, consultez le [Jira Incident Replicator](jira_dora.md).

## Architecture {#architecture}

Nous allons créer 2 workflows d'automatisation à l'aide de l'automatisation Jira :

1. Créer des tickets GitLab lorsqu'ils sont créés dans Jira
1. Fermer les tickets GitLab lorsqu'ils sont résolus dans Jira

### Création de tickets {#issue-creation}

Lorsqu'un nouveau ticket est créé dans Jira, le workflow d'automatisation envoie une requête POST à l'API Issues de GitLab pour créer un ticket correspondant dans le projet GitLab spécifié.

### Résolution de tickets {#issue-resolution}

Lorsqu'un ticket Jira passe à un état résolu (Closed, Done, Resolved), le workflow d'automatisation envoie une requête PUT pour fermer le ticket GitLab correspondant.

## Configuration {#setup}

### Prérequis {#pre-requisites}

Cette procédure suppose que vous disposez des éléments suivants :

- Un projet GitLab dans lequel vous souhaitez générer des données d'analyse VSA
- Un projet Jira à partir duquel répliquer les tickets
- Une licence GitLab Ultimate ou GitLab Premium (pour les fonctionnalités de Value Stream Analytics)

Jira impose des [limites](https://www.atlassian.com/software/jira/pricing) sur la fréquence des exécutions d'automatisation selon votre licence Jira :

| **Édition**   | **Limite**                    |
|------------|------------------------------|
| Gratuite       | 100 exécutions par mois           |
| Standard   | 1 700 exécutions par mois          |
| Premium    | 1 000 exécutions par utilisateur par mois |
| Enterprise | Exécutions illimitées               |

Chaque création de ticket compte comme 1 exécution, et chaque résolution de ticket compte comme 1 exécution.

### Jeton d'accès au projet GitLab {#gitlab-project-access-token}

Tout d'abord, nous devons créer un jeton d'accès au projet GitLab avec les permissions nécessaires pour créer et mettre à jour des tickets via l'API.

1. Accédez à votre projet GitLab dans lequel vous souhaitez que les tickets Jira soient répliqués. Dans la barre latérale, accédez à **Paramètres** > **Access Tokens**.
1. Cliquez sur **Ajouter un jeton**.
1. Définissez la configuration suivante :
   - **Nom du jeton** : `Jira VSA Integration` (ou tout autre nom descriptif)
   - **Date d'expiration** : définir selon vos politiques de sécurité
   - **Rôle** : `Owner` (requis pour définir des identifiants de tickets personnalisés)
   - **Périmètre d'accès** : cochez `api` (accès complet à l'API)

**Important** : un jeton d'accès de niveau **Propriétaire** est requis, car l'intégration doit forcer la définition d'identifiants de tickets personnalisés lors de la création de tickets dans GitLab. Cela garantit que lorsque les tickets Jira sont fermés, l'automatisation peut identifier et fermer le ticket GitLab correspondant en utilisant le même mappage d'identifiants. Sans le rôle Propriétaire, l'API GitLab n'autorisera pas la définition d'identifiants de tickets personnalisés, ce qui rompra la synchronisation entre la fermeture des tickets Jira et la fermeture des tickets GitLab.

1. Cliquez sur **Create project access token** et enregistrez le jeton généré en lieu sûr, vous en aurez besoin pour la configuration de l'automatisation Jira.

### Workflow de création de tickets Jira {#jira-issue-creation-workflow}

Pour créer automatiquement des tickets GitLab lorsque des tickets Jira sont créés, nous utiliserons [l'automatisation Jira](https://community.atlassian.com/t5/Jira-articles/Automation-for-Jira-Send-web-request-using-Jira-REST-API/ba-p/1443828).

1. Accédez à votre projet Jira. Dans la barre latérale, accédez à **Paramètres du projet** > **Automation**.
1. Cliquez sur **Create rule** en haut à droite.
1. Pour votre déclencheur, recherchez et sélectionnez **Ticket créé**. Cliquez sur **Sauvegarder**.
1. *Facultatif* : ajoutez des conditions pour filtrer les tickets à répliquer. Par exemple, vous pouvez ajouter une condition **Issue fields condition** pour ne répliquer que les tickets de certains types ou avec des labels spécifiques.
1. Sélectionnez **THEN : Add an action**. Recherchez et sélectionnez **Send web request**.
1. Configurez la requête web :
   - **Web request URL** : `https://gitlab.com/api/v4/projects/<GITLAB_PROJECT_ID>/issues` (remplacez `gitlab.com` par l'URL de votre instance GitLab si elle est auto-hébergée, et `<GITLAB_PROJECT_ID>` par l'identifiant numérique de votre projet GitLab, par exemple `42718690`)
   - **HTTP method** : **POST**
   - **Web request body** : **Custom data**
1. Ajoutez les en-têtes suivants :

   | Nom | Valeur |
   | ------ | ------ |
   | Authorization | Bearer `<YOUR_GITLAB_TOKEN>` |
   | Content-Type | `application/json` |

   Définissez l'en-tête Authorization sur « Hidden » pour des raisons de sécurité.
1. Dans le champ **Custom data**, saisissez :

   ```json
   {
     "title": "{{issue.summary}}",
     "iid": {{issue.key.replace("VSA-", "1000")}}
   }
   ```

   Remplacez `"VSA-"` par le préfixe de votre projet Jira (par exemple, si vos tickets Jira sont numérotés `PROJ-123`, utilisez `"PROJ-"`). La valeur `1000` est un nombre de base qui est ajouté pour éviter tout conflit avec les tickets qui pourraient avoir été créés directement dans GitLab via l'interface utilisateur, vous pouvez ajuster cette valeur selon vos besoins.
1. Cliquez sur **Sauvegarder**, donnez un nom descriptif à votre automatisation (par exemple, `Jira to GitLab Issue Creation`), puis cliquez sur **Turn it on**.

### Workflow de résolution de tickets Jira {#jira-issue-resolution-workflow}

Créez un second workflow d'automatisation pour fermer les tickets GitLab lorsque les tickets Jira sont résolus :

1. Suivez les étapes 1-2 du workflow de création pour démarrer une nouvelle règle.
1. Définissez le déclencheur sur **Issue transitioned** :
   - Laissez le champ « From status » vide
   - Définissez « To status » sur les statuts résolus : `Closed`, `Done`, `Resolved` (adaptez selon votre workflow Jira)
1. Ignorez les conditions (ou ajoutez des conditions personnalisées si nécessaire).
1. Ajoutez une action **Send web request** avec :
   - **Web request URL** : `https://gitlab.com/api/v4/projects/<GITLAB_PROJECT_ID>/issues/{{issue.key.replace("<JIRA_PROJECT_PREFIX>-", "1000").urlEncode}}` (remplacez `gitlab.com` par l'URL de votre instance GitLab si elle est auto-hébergée, `<GITLAB_PROJECT_ID>` par l'identifiant numérique de votre projet GitLab, et `<JIRA_PROJECT_PREFIX>` par le préfixe de votre projet Jira, comme `VSA` ou `PROJ`)
   - **HTTP method** : **PUT**
   - **Web request body** : **Custom data**
1. Utilisez les mêmes en-têtes que pour le workflow de création.
1. Dans le champ **Custom data**, saisissez :

   ```json
   {
     "state_event": "close"
   }
   ```

1. Enregistrez et activez la règle d'automatisation avec un nom descriptif (par exemple, `Jira to GitLab Issue Closer`).

## Configuration de Value Stream Analytics {#value-stream-analytics-configuration}

Une fois vos workflows d'automatisation actifs, GitLab commencera à recevoir des données de tickets. Voici comment accéder à vos données d'analyse :

### Tableau de bord des chaînes de valeur (Automatique - GitLab Ultimate uniquement) {#value-streams-dashboard-automatic---ultimate-only}

Le **Tableau de bord des chaînes de valeur** est automatiquement alimenté par les métriques issues de vos tickets répliqués et est disponible avec GitLab Ultimate :

1. Dans votre projet ou groupe GitLab, accédez à **Analyse** > **Tableaux de bord de données d'analyse**
1. Cliquez sur **Tableau de bord des chaînes de valeur**
1. Vous verrez des métriques incluant les Tickets créés, les Tickets fermés, la Durée d'exécution et le Cycle time

### Value Stream Analytics (Configuration requise - GitLab Premium et GitLab Ultimate) {#value-stream-analytics-requires-setup---premium-and-ultimate}

Pour des données d'analyse plus détaillées et des chaînes de valeur personnalisées (disponibles avec GitLab Premium et GitLab Ultimate) :

1. Accédez à **Analyse** > **Données d'analyse des chaînes de valeur** dans votre projet ou groupe GitLab
1. Cliquez sur **Nouvelle chaîne de valeur** pour créer une chaîne de valeur personnalisée
1. Configurez les étapes et les workflows selon votre processus de développement
1. Les métriques telles que la durée d'exécution et le nombre de nouveaux tickets seront automatiquement générées et affichées à côté des étapes que vous créez
1. Consultez la [documentation GitLab Value Stream Analytics](../../user/group/value_stream_analytics/_index.md#create-a-value-stream) pour des instructions de configuration détaillées

## Considérations multi-projets {#multi-project-considerations}

Si vous souhaitez répliquer des tickets issus de plusieurs projets Jira à l'aide d'un seul ensemble de règles d'automatisation, envisagez d'utiliser une approche basée sur un horodatage pour générer des identifiants de tickets uniques plutôt que la méthode par préfixe de projet :

Remplacez la valeur `iid` dans vos données personnalisées par :

```json
"iid": {{issue.created.replace("-","").replace("T","").replace(":","").replace(".","").replace("+","")}}
```

Cela convertit l'horodatage de création (format : `2025-02-15T09:45:32.7+0000`) en une valeur numérique. Notez que cette approche peut générer des identifiants de tickets très longs et présente un faible risque de conflits si deux tickets sont créés exactement au même moment.

## Ressources {#resources}

- [GitLab Value Stream Analytics](../../user/group/value_stream_analytics/_index.md)
  - [Créer une chaîne de valeur](../../user/group/value_stream_analytics/_index.md#create-a-value-stream)
- [Tableau de bord des chaînes de valeur GitLab](../../user/analytics/value_streams_dashboard.md)
- [API Issues GitLab](../../api/issues.md)
  - [Créer un nouveau ticket](../../api/issues.md#create-an-issue)
  - [Modifier un ticket](../../api/issues.md#update-an-issue)
- [Jetons d'accès au projet GitLab](../../user/project/settings/project_access_tokens.md)
- [Automatisation Jira avec les requêtes web](https://community.atlassian.com/t5/Jira-articles/Automation-for-Jira-Send-web-request-using-Jira-REST-API/ba-p/1443828)
