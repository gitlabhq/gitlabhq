---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des intégrations de groupe
description: "Configurez et gérez les intégrations pour un groupe avec l'API REST."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/328496) dans GitLab 17.9.

{{< /history >}}

Utilisez cette API pour gérer les [intégrations](../user/project/integrations/_index.md) d'un groupe et de ses sous-groupes.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le groupe.

## Lister toutes les intégrations actives {#list-all-active-integrations}

Obtenez la liste de toutes les intégrations de groupe actives. Le champ `vulnerability_events` est uniquement disponible pour GitLab Enterprise Edition.

```plaintext
GET /groups/:id/integrations
```

Exemple de réponse :

```json
[
  {
    "id": 75,
    "title": "Jenkins CI",
    "slug": "jenkins",
    "created_at": "2019-11-20T11:20:25.297Z",
    "updated_at": "2019-11-20T12:24:37.498Z",
    "active": true,
    "commit_events": true,
    "push_events": true,
    "issues_events": true,
    "alert_events": true,
    "confidential_issues_events": true,
    "merge_requests_events": true,
    "tag_push_events": false,
    "deployment_events": false,
    "note_events": true,
    "confidential_note_events": true,
    "pipeline_events": true,
    "wiki_page_events": true,
    "job_events": true,
    "comment_on_event_enabled": true,
    "inherited": false,
    "vulnerability_events": true
  },
  {
    "id": 76,
    "title": "Alerts endpoint",
    "slug": "alerts",
    "created_at": "2019-11-20T11:20:25.297Z",
    "updated_at": "2019-11-20T12:24:37.498Z",
    "active": true,
    "commit_events": true,
    "push_events": true,
    "issues_events": true,
    "alert_events": true,
    "confidential_issues_events": true,
    "merge_requests_events": true,
    "tag_push_events": true,
    "deployment_events": false,
    "note_events": true,
    "confidential_note_events": true,
    "pipeline_events": true,
    "wiki_page_events": true,
    "job_events": true,
    "comment_on_event_enabled": true,
    "inherited": false,
    "vulnerability_events": true
  }
]
```

## Asana {#asana}

### Configurer Asana {#set-up-asana}

Configurez l'intégration Asana pour un groupe.

```plaintext
PUT /groups/:id/integrations/asana
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `api_key` | string | oui | Jeton d'API utilisateur. L'utilisateur doit avoir accès à la tâche. Tous les commentaires sont attribués à cet utilisateur. |
| `restrict_to_branch` | string | non | Liste des branches à inspecter automatiquement, séparées par des virgules. Laissez vide pour inclure toutes les branches. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Asana {#disable-asana}

Désactivez l'intégration Asana pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/asana
```

### Obtenir les paramètres Asana {#get-asana-settings}

Obtenez les paramètres d'intégration Asana pour un groupe.

```plaintext
GET /groups/:id/integrations/asana
```

## Assembla {#assembla}

### Configurer Assembla {#set-up-assembla}

Configurez l'intégration Assembla pour un groupe.

```plaintext
PUT /groups/:id/integrations/assembla
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | oui | Le jeton d'authentification. |
| `subdomain` | string | non | Le paramètre de sous-domaine. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Assembla {#disable-assembla}

Désactivez l'intégration Assembla pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/assembla
```

### Obtenir les paramètres Assembla {#get-assembla-settings}

Obtenez les paramètres d'intégration Assembla pour un groupe.

```plaintext
GET /groups/:id/integrations/assembla
```

## Atlassian Bamboo {#atlassian-bamboo}

### Configurer Atlassian Bamboo {#set-up-atlassian-bamboo}

Configurez l'intégration Atlassian Bamboo pour un groupe.

Vous devez configurer l'étiquetage automatique des révisions et un déclencheur de dépôt dans Bamboo.

```plaintext
PUT /groups/:id/integrations/bamboo
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `bamboo_url` | string | oui | URL racine de Bamboo (par exemple, `https://bamboo.example.com`). |
| `enable_ssl_verification` | boolean | non | Activer la vérification SSL. La valeur par défaut est `true` (activée). |
| `build_key` | string | oui | Clé du plan de build Bamboo (par exemple, `KEY`). |
| `username` | string | oui | Utilisateur disposant d'un accès API au serveur Bamboo. |
| `password` | string | oui | Mot de passe de l'utilisateur. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Atlassian Bamboo {#disable-atlassian-bamboo}

Désactivez l'intégration Atlassian Bamboo pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/bamboo
```

### Obtenir les paramètres Atlassian Bamboo {#get-atlassian-bamboo-settings}

Obtenez les paramètres d'intégration Atlassian Bamboo pour un groupe.

```plaintext
GET /groups/:id/integrations/bamboo
```

## Bugzilla {#bugzilla}

### Configurer Bugzilla {#set-up-bugzilla}

Configurez l'intégration Bugzilla pour un groupe.

```plaintext
PUT /groups/:id/integrations/bugzilla
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | oui |  URL du nouveau ticket. |
| `issues_url` | string | oui | URL du ticket. |
| `project_url` | string | oui | URL du projet. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Bugzilla {#disable-bugzilla}

Désactivez l'intégration Bugzilla pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/bugzilla
```

### Obtenir les paramètres Bugzilla {#get-bugzilla-settings}

Obtenez les paramètres d'intégration Bugzilla pour un groupe.

```plaintext
GET /groups/:id/integrations/bugzilla
```

## Buildkite {#buildkite}

### Configurer Buildkite {#set-up-buildkite}

Configurez l'intégration Buildkite pour un groupe.

```plaintext
PUT /groups/:id/integrations/buildkite
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | oui | Jeton GitLab du projet Buildkite. |
| `project_url` | string | oui | URL du pipeline (par exemple, `https://buildkite.com/example/pipeline`). |
| `enable_ssl_verification` | boolean | non | **Déprécié** : Ce paramètre n'a aucun effet car la vérification SSL est toujours activée. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tag. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Buildkite {#disable-buildkite}

Désactivez l'intégration Buildkite pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/buildkite
```

### Obtenir les paramètres Buildkite {#get-buildkite-settings}

Obtenez les paramètres d'intégration Buildkite pour un groupe.

```plaintext
GET /groups/:id/integrations/buildkite
```

## Campfire Classic {#campfire-classic}

Vous pouvez vous intégrer à Campfire Classic. Cependant, Campfire Classic est un ancien produit qui n'est [plus vendu](https://gitlab.com/gitlab-org/gitlab/-/issues/329337) par Basecamp.

### Configurer Campfire Classic {#set-up-campfire-classic}

Configurez l'intégration Campfire Classic pour un groupe.

```plaintext
PUT /groups/:id/integrations/campfire
```

Paramètres :

| Paramètre     | Type    | Obligatoire | Description                                                                                 |
|---------------|---------|----------|---------------------------------------------------------------------------------------------|
| `token`       | string  | oui     | Jeton d'authentification API de Campfire Classic. Pour obtenir le jeton, connectez-vous à Campfire Classic et sélectionnez **My info**. |
| `subdomain`   | string  | non    | Sous-domaine `.campfirenow.com` lorsque vous êtes connecté. |
| `room`        | string  | non    | Partie ID de l'URL de la salle Campfire Classic. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Campfire Classic {#disable-campfire-classic}

Désactivez l'intégration Campfire Classic pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/campfire
```

### Obtenir les paramètres Campfire Classic {#get-campfire-classic-settings}

Obtenez les paramètres d'intégration Campfire Classic pour un groupe.

```plaintext
GET /groups/:id/integrations/campfire
```

## ClickUp {#clickup}

### Configurer ClickUp {#set-up-clickup}

Configurez l'intégration ClickUp pour un groupe.

```plaintext
PUT /groups/:id/integrations/clickup
```

Paramètres :

| Paramètre     | Type   | Obligatoire | Description    |
| ------------- | ------ | -------- | -------------- |
| `issues_url`  | string | oui     | URL du ticket.     |
| `project_url` | string | oui     | URL du projet.   |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver ClickUp {#disable-clickup}

Désactivez l'intégration ClickUp pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/clickup
```

### Obtenir les paramètres ClickUp {#get-clickup-settings}

Obtenez les paramètres d'intégration ClickUp pour un groupe.

```plaintext
GET /groups/:id/integrations/clickup
```

## Confluence Workspace {#confluence-workspace}

### Configurer Confluence Workspace {#set-up-confluence-workspace}

Configurez l'intégration Confluence Workspace pour un groupe.

```plaintext
PUT /groups/:id/integrations/confluence
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `confluence_url` | string | oui | URL du Confluence Workspace hébergé sur `atlassian.net`. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Confluence Workspace {#disable-confluence-workspace}

Désactivez l'intégration Confluence Workspace pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/confluence
```

### Obtenir les paramètres Confluence Workspace {#get-confluence-workspace-settings}

Obtenez les paramètres d'intégration Confluence Workspace pour un groupe.

```plaintext
GET /groups/:id/integrations/confluence
```

## Outil de suivi des tickets personnalisé {#custom-issue-tracker}

### Configurer un outil de suivi des tickets personnalisé {#set-up-a-custom-issue-tracker}

Configurez un outil de suivi des tickets personnalisé pour un groupe.

```plaintext
PUT /groups/:id/integrations/custom-issue-tracker
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | oui |  URL du nouveau ticket. |
| `issues_url` | string | oui | URL du ticket. |
| `project_url` | string | oui | URL du projet. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver un outil de suivi des tickets personnalisé {#disable-a-custom-issue-tracker}

Désactivez un outil de suivi des tickets personnalisé pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/custom-issue-tracker
```

### Obtenir les paramètres de l'outil de suivi des tickets personnalisé {#get-custom-issue-tracker-settings}

Obtenez les paramètres de l'outil de suivi des tickets personnalisé pour un groupe.

```plaintext
GET /groups/:id/integrations/custom-issue-tracker
```

## Datadog {#datadog}

### Configurer Datadog {#set-up-datadog}

Configurez l'intégration Datadog pour un groupe.

```plaintext
PUT /groups/:id/integrations/datadog
```

Paramètres :

| Paramètre              | Type    | Obligatoire | Description                                                                                                                                                                            |
|------------------------|---------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api_key`              | string  | oui     | Clé API utilisée pour l'authentification avec Datadog.                                                                                                                                          |
| `api_url`              | string  | non    | (Avancé) L'URL complète de votre site Datadog.                                                                                                                                          |
| `datadog_env`          | string  | non    | Pour les déploiements auto-gérés, définissez le tag `env%` pour toutes les données envoyées à Datadog.                                                                                                      |
| `datadog_service`      | string  | non    | Taguez toutes les données de cette instance GitLab dans Datadog. Peut être utilisé pour gérer plusieurs déploiements auto-gérés.                                                                          |
| `datadog_site`         | string  | non    | Le site Datadog vers lequel envoyer les données. Pour envoyer des données au site de l'UE, utilisez `datadoghq.eu`.                                                                                                      |
| `datadog_tags`         | string  | non    | Tags personnalisés dans Datadog. Spécifiez un tag par ligne au format `key:value\nkey2:value2`                                                                                                 |
| `archive_trace_events` | boolean | non    | Lorsqu'il est activé, les job logs sont collectés par Datadog et affichés avec les traces d'exécution de pipeline. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Datadog {#disable-datadog}

Désactivez l'intégration Datadog pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/datadog
```

### Obtenir les paramètres Datadog {#get-datadog-settings}

Obtenez les paramètres d'intégration Datadog pour un groupe.

```plaintext
GET /groups/:id/integrations/datadog
```

## Diffblue Cover {#diffblue-cover}

### Configurer Diffblue Cover {#set-up-diffblue-cover}

Configurez l'intégration Diffblue Cover pour un groupe.

```plaintext
PUT /groups/:id/integrations/diffblue-cover
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `diffblue_license_key` | string | oui | Clé de licence Diffblue Cover. |
| `diffblue_access_token_name` | string | oui | Nom du jeton d'accès utilisé par Diffblue Cover dans les pipelines. |
| `diffblue_access_token_secret` | string  | oui | Secret du jeton d'accès utilisé par Diffblue Cover dans les pipelines. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Diffblue Cover {#disable-diffblue-cover}

Désactivez l'intégration Diffblue Cover pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/diffblue-cover
```

### Obtenir les paramètres Diffblue Cover {#get-diffblue-cover-settings}

Obtenez les paramètres d'intégration Diffblue Cover pour un groupe.

```plaintext
GET /groups/:id/integrations/diffblue-cover
```

## Discord Notifications {#discord-notifications}

### Configurer Discord Notifications {#set-up-discord-notifications}

Configurez Discord Notifications pour un groupe.

```plaintext
PUT /groups/:id/integrations/discord
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | oui | Webhook Discord (par exemple, `https://discord.com/api/webhooks/...`). |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de ticket confidentiel. |
| `confidential_issue_channel` | string | non | Le remplacement du webhook pour recevoir les notifications des événements de ticket confidentiel. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de note confidentielle. |
| `confidential_note_channel` | string | non | Le remplacement du webhook pour recevoir les notifications des événements de note confidentielle. |
| `deployment_events` | boolean | non | Activer les notifications pour les événements de déploiement. |
| `deployment_channel` | string | non | Le remplacement du webhook pour recevoir les notifications des événements de déploiement. |
| `group_confidential_mentions_events` | boolean | non | Activer les notifications pour les événements de mention confidentielle de groupe. |
| `group_confidential_mentions_channel` | string | non | Le remplacement du webhook pour recevoir les notifications des événements de mention confidentielle de groupe. |
| `group_mentions_events` | boolean | non | Activer les notifications pour les événements de mention de groupe. |
| `group_mentions_channel` | string | non | Le remplacement du webhook pour recevoir les notifications des événements de mention de groupe. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de ticket. |
| `issue_channel` | string | non | Le remplacement du webhook pour recevoir les notifications des événements de ticket. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `merge_request_channel` | string | non | Le remplacement du webhook pour recevoir les notifications des événements de merge request. |
| `note_events` | boolean | non | Activer les notifications pour les événements de note. |
| `note_channel` | string | non | Le remplacement du webhook pour recevoir les notifications des événements de note. |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines en échec. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `pipeline_channel` | string | non | Le remplacement du webhook pour recevoir les notifications des événements de pipeline. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `push_channel` | string | non | Le remplacement du webhook pour recevoir les notifications des événements de push. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tag. |
| `tag_push_channel` | string | non | Le remplacement du webhook pour recevoir les notifications des événements de push de tag. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de page wiki. |
| `wiki_page_channel` | string | non | Le remplacement du webhook pour recevoir les notifications des événements de page wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Discord Notifications {#disable-discord-notifications}

Désactivez Discord Notifications pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/discord
```

### Obtenir les paramètres Discord Notifications {#get-discord-notifications-settings}

Obtenez les paramètres Discord Notifications pour un groupe.

```plaintext
GET /groups/:id/integrations/discord
```

## Drone {#drone}

### Configurer Drone {#set-up-drone}

Configurez l'intégration Drone pour un groupe.

```plaintext
PUT /groups/:id/integrations/drone-ci
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | oui | Jeton spécifique au projet Drone CI. |
| `drone_url` | string | oui | `http://drone.example.com`. |
| `enable_ssl_verification` | boolean | non | Activer la vérification SSL. La valeur par défaut est `true` (activée). |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tag. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Drone {#disable-drone}

Désactivez l'intégration Drone pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/drone-ci
```

### Obtenir les paramètres Drone {#get-drone-settings}

Obtenez les paramètres d'intégration Drone pour un groupe.

```plaintext
GET /groups/:id/integrations/drone-ci
```

## E-mails lors d'un push {#emails-on-push}

### Configurer les e-mails lors d'un push {#set-up-emails-on-push}

Configurez l'intégration d'e-mails lors d'un push pour un groupe.

```plaintext
PUT /groups/:id/integrations/emails-on-push
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | oui | Adresses e-mail séparées par des espaces. |
| `disable_diffs` | boolean | non | Désactiver les diffs de code. |
| `send_from_committer_email` | boolean | non | Envoyer depuis le committeur. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tag. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. Les notifications sont toujours envoyées pour les pushs de tag. La valeur par défaut est `all`. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver les e-mails lors d'un push {#disable-emails-on-push}

Désactivez l'intégration d'e-mails lors d'un push pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/emails-on-push
```

### Obtenir les paramètres des e-mails lors d'un push {#get-emails-on-push-settings}

Obtenez les paramètres d'intégration des e-mails lors d'un push pour un groupe.

```plaintext
GET /groups/:id/integrations/emails-on-push
```

## Engineering Workflow Management (EWM) {#engineering-workflow-management-ewm}

### Configurer EWM {#set-up-ewm}

Configurez l'intégration EWM pour un groupe.

```plaintext
PUT /groups/:id/integrations/ewm
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | oui | URL du nouveau ticket. |
| `project_url`   | string | oui | URL du projet. |
| `issues_url`    | string | oui | URL du ticket. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver EWM {#disable-ewm}

Désactivez l'intégration EWM pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/ewm
```

### Obtenir les paramètres EWM {#get-ewm-settings}

Obtenez les paramètres d'intégration EWM pour un groupe.

```plaintext
GET /groups/:id/integrations/ewm
```

## Wiki externe {#external-wiki}

### Configurer un wiki externe {#set-up-an-external-wiki}

Configurez un wiki externe pour un groupe.

```plaintext
PUT /groups/:id/integrations/external-wiki
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `external_wiki_url` | string | oui | URL du wiki externe. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver un wiki externe {#disable-an-external-wiki}

Désactivez un wiki externe pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/external-wiki
```

### Obtenir les paramètres du wiki externe {#get-external-wiki-settings}

Obtenez les paramètres du wiki externe pour un groupe.

```plaintext
GET /groups/:id/integrations/external-wiki
```

## GitGuardian {#gitguardian}

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!flag]
> Sur GitLab Self-Managed, cette fonctionnalité est disponible par défaut. Pour masquer la fonctionnalité, demandez à un administrateur de [désactiver le feature flag](../administration/feature_flags/_index.md) nommé `git_guardian_integration`. Sur GitLab.com, cette fonctionnalité n'est pas disponible. Sur GitLab Dedicated, cette fonctionnalité est disponible.

[GitGuardian](https://www.gitguardian.com/) est un service de cybersécurité qui détecte les données sensibles telles que les clés API et les mots de passe dans les dépôts de code source. Il analyse les dépôts Git, alerte sur les violations de politique et aide les organisations à corriger les problèmes de sécurité avant que les pirates ne puissent les exploiter.

Vous pouvez configurer GitLab pour rejeter les commits en fonction des politiques GitGuardian.

Pour les problèmes connus et les étapes de dépannage, consultez [Dépannage GitGuardian](../user/project/integrations/git_guardian.md#troubleshooting).

### Configurer GitGuardian {#set-up-gitguardian}

Configurez l'intégration GitGuardian pour un groupe.

```plaintext
PUT /groups/:id/integrations/git-guardian
```

Paramètres :

| Paramètre | Type | Obligatoire | Description                                   |
| --------- | ---- | -------- |-----------------------------------------------|
| `token` | string | oui | Jeton API GitGuardian avec la portée `scan`. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver GitGuardian {#disable-gitguardian}

Désactivez l'intégration GitGuardian pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/git-guardian
```

### Obtenir les paramètres GitGuardian {#get-gitguardian-settings}

Obtenez les paramètres d'intégration GitGuardian pour un groupe.

```plaintext
GET /groups/:id/integrations/git-guardian
```

## GitHub {#github}

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

### Configurer GitHub {#set-up-github}

Configurez l'intégration GitHub pour un groupe.

```plaintext
PUT /groups/:id/integrations/github
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | oui | Jeton API GitHub avec la portée OAuth `repo:status`. |
| `repository_url` | string | oui | URL du dépôt GitHub. |
| `static_context` | boolean | non | Ajouter le nom d'hôte de votre instance GitLab au [nom de la vérification de statut](../user/project/integrations/github.md#static-or-dynamic-status-check-names). |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver GitHub {#disable-github}

Désactivez l'intégration GitHub pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/github
```

### Obtenir les paramètres GitHub {#get-github-settings}

Obtenez les paramètres d'intégration GitHub pour un groupe.

```plaintext
GET /groups/:id/integrations/github
```

## Application GitLab pour Jira Cloud {#gitlab-for-jira-cloud-app}

L'intégration de l'application GitLab pour Jira Cloud est activée ou désactivée automatiquement via [la liaison et la déliaison de groupe dans Jira](../integration/jira/connect-app.md#configure-the-gitlab-for-jira-cloud-app). Vous ne pouvez pas activer ou désactiver l'intégration avec le formulaire des intégrations GitLab ou l'API.

### Mettre à jour l'intégration pour un groupe {#update-integration-for-a-group}

Utilisez cet endpoint d'API REST pour mettre à jour une intégration que vous créez avec la liaison de groupe dans Jira.

```plaintext
PUT /groups/:id/integrations/jira-cloud-app
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `jira_cloud_app_service_ids` | string | non | ID de service Jira Service Management. Utilisez des virgules (`,`) pour séparer plusieurs ID. |
| `jira_cloud_app_enable_deployment_gating` | boolean | non | Active le contrôle de déploiement pour les déploiements GitLab bloqués depuis Jira Service Management. |
| `jira_cloud_app_deployment_gating_environments` | string | non | Les environnements (production, staging, test ou développement) pour lesquels activer le contrôle de déploiement. Requis si le contrôle de déploiement est activé. Utilisez des virgules (`,`) pour séparer plusieurs environnements. |

### Obtenir les paramètres de l'application GitLab pour Jira Cloud {#get-gitlab-for-jira-cloud-app-settings}

Obtenez les paramètres d'intégration de l'application GitLab pour Jira Cloud pour un groupe.

```plaintext
GET /groups/:id/integrations/jira-cloud-app
```

## Application GitLab pour Slack {#gitlab-for-slack-app}

### Configurer l'application GitLab pour Slack {#set-up-gitlab-for-slack-app}

Mettez à jour l'intégration de l'application GitLab pour Slack pour un groupe.

Vous ne pouvez pas créer une application GitLab pour Slack via l'API car l'intégration nécessite un jeton OAuth 2.0 que vous ne pouvez pas obtenir uniquement depuis l'API GitLab. À la place, vous devez [installer l'application](../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app) depuis l'interface GitLab. Vous pouvez ensuite utiliser cet endpoint d'API REST pour mettre à jour l'intégration.

```plaintext
PUT /groups/:id/integrations/gitlab-slack-application
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `channel` | string | non | Canal par défaut à utiliser si aucun autre canal n'est configuré. |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines en échec. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `notify_only_default_branch` | boolean | non | **Déprécié** : Ce paramètre a été remplacé par `branches_to_be_notified`. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `alert_events` | boolean | non | Activer les notifications pour les événements d'alerte. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de ticket. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de ticket confidentiel. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `note_events` | boolean | non | Activer les notifications pour les événements de note. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de note confidentielle. |
| `deployment_events` | boolean | non | Activer les notifications pour les événements de déploiement. |
| `incidents_events` | boolean | non | Activer les notifications pour les événements d'incident. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tag. |
| `vulnerability_events` | boolean | non | Activer les notifications pour les événements de vulnérabilité. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de page wiki. |
| `labels_to_be_notified` | string | non | Labels pour lesquels envoyer des notifications. Si non défini, recevoir des notifications pour tous les événements. |
| `labels_to_be_notified_behavior` | string | non | Labels pour lesquels être notifié. Les options valides sont `match_any` et `match_all`. Par défaut `match_any`. |
| `push_channel` | string | non | Nom du canal pour recevoir les notifications des événements de push. |
| `issue_channel` | string | non | Nom du canal pour recevoir les notifications des événements de ticket. |
| `confidential_issue_channel` | string | non | Nom du canal pour recevoir les notifications des événements de ticket confidentiel. |
| `merge_request_channel` | string | non | Nom du canal pour recevoir les notifications des événements de merge request. |
| `note_channel` | string | non | Nom du canal pour recevoir les notifications des événements de note. |
| `confidential_note_channel` | string | non | Nom du canal pour recevoir les notifications des événements de note confidentielle. |
| `tag_push_channel` | string | non | Nom du canal pour recevoir les notifications des événements de push de tag. |
| `pipeline_channel` | string | non | Nom du canal pour recevoir les notifications des événements de pipeline. |
| `wiki_page_channel` | string | non | Nom du canal pour recevoir les notifications des événements de page wiki. |
| `deployment_channel` | string | non | Nom du canal pour recevoir les notifications des événements de déploiement. |
| `incident_channel` | string | non | Nom du canal pour recevoir les notifications des événements d'incident. |
| `vulnerability_channel` | string | non | Nom du canal pour recevoir les notifications des événements de vulnérabilité. |
| `alert_channel` | string | non | Nom du canal pour recevoir les notifications des événements d'alerte. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver GitLab for Slack app {#disable-gitlab-for-slack-app}

Désactiver l'intégration GitLab for Slack app pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/gitlab-slack-application
```

### Obtenir les paramètres de GitLab for Slack app {#get-gitlab-for-slack-app-settings}

Obtenir les paramètres d'intégration de GitLab for Slack app pour un groupe.

```plaintext
GET /groups/:id/integrations/gitlab-slack-application
```

## Google Chat {#google-chat}

### Configurer Google Chat {#set-up-google-chat}

Configurer l'intégration Google Chat pour un groupe.

```plaintext
PUT /groups/:id/integrations/hangouts-chat
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | oui | Le webhook Hangouts Chat (par exemple, `https://chat.googleapis.com/v1/spaces...`). |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines en échec. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `notify_only_default_branch` | boolean | non | **Déprécié** : Ce paramètre a été remplacé par `branches_to_be_notified`. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de ticket. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de ticket confidentiel. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tag. |
| `note_events` | boolean | non | Activer les notifications pour les événements de note. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de note confidentielle. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de page wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Google Chat {#disable-google-chat}

Désactiver l'intégration Google Chat pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/hangouts-chat
```

### Obtenir les paramètres de Google Chat {#get-google-chat-settings}

Obtenir les paramètres d'intégration Google Chat pour un groupe.

```plaintext
GET /groups/:id/integrations/hangouts-chat
```

## Google Artifact Management {#google-artifact-management}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com
- Statut : Bêta

{{< /details >}}

Cette fonctionnalité est en [bêta](../policy/development_stages_support.md).

### Configurer Google Artifact Management {#set-up-google-artifact-management}

Configurer l'intégration Google Artifact Management pour un groupe.

```plaintext
PUT /groups/:id/integrations/google-cloud-platform-artifact-registry
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `artifact_registry_project_id` | string | oui | ID du projet Google Cloud. |
| `artifact_registry_location` | string | oui | Emplacement du dépôt Artifact Registry. |
| `artifact_registry_repositories` | string | oui | Dépôt d'Artifact Registry. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Google Artifact Management {#disable-google-artifact-management}

Désactiver l'intégration Google Artifact Management pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/google-cloud-platform-artifact-registry
```

### Obtenir les paramètres de Google Artifact Management {#get-google-artifact-management-settings}

Obtenir les paramètres d'intégration Google Artifact Management pour un groupe.

```plaintext
GET /groups/:id/integrations/google-cloud-platform-artifact-registry
```

## Google Cloud Identity and Access Management (IAM) {#google-cloud-identity-and-access-management-iam}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com
- Statut : Bêta

{{< /details >}}

Cette fonctionnalité est en [bêta](../policy/development_stages_support.md).

### Configurer Google Cloud Identity and Access Management {#set-up-google-cloud-identity-and-access-management}

Configurer l'intégration Google Cloud Identity and Access Management pour un groupe.

```plaintext
PUT /groups/:id/integrations/google-cloud-platform-workload-identity-federation
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `workload_identity_federation_project_id` | string | oui | ID du projet Google Cloud pour le Workload Identity Federation. |
| `workload_identity_federation_project_number` | entier | oui | Numéro de projet Google Cloud pour le Workload Identity Federation. |
| `workload_identity_pool_id` | string | oui | ID du pool d'identités de charge de travail. |
| `workload_identity_pool_provider_id` | string | oui | ID du fournisseur du pool d'identités de charge de travail. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Google Cloud Identity and Access Management {#disable-google-cloud-identity-and-access-management}

Désactiver l'intégration Google Cloud Identity and Access Management pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/google-cloud-platform-workload-identity-federation
```

### Obtenir Google Cloud Identity and Access Management {#get-google-cloud-identity-and-access-management}

Obtenir les paramètres de Google Cloud Identity and Access Management pour un groupe.

```plaintext
GET /groups/:id/integration/google-cloud-platform-workload-identity-federation
```

## Harbor {#harbor}

### Configurer Harbor {#set-up-harbor}

Configurer l'intégration Harbor pour un groupe.

```plaintext
PUT /groups/:id/integrations/harbor
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `url` | string | oui | L'URL de base de l'instance Harbor liée au projet GitLab. Par exemple, `https://demo.goharbor.io`. |
| `project_name` | string | oui | Le nom du projet dans l'instance Harbor. Par exemple, `testproject`. |
| `username` | string | oui | Le nom d'utilisateur créé dans l'interface Harbor. |
| `password` | string | oui | Le mot de passe de l'utilisateur. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Harbor {#disable-harbor}

Désactiver l'intégration Harbor pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/harbor
```

### Obtenir les paramètres de Harbor {#get-harbor-settings}

Obtenir les paramètres d'intégration Harbor pour un groupe.

```plaintext
GET /groups/:id/integrations/harbor
```

## irker (passerelle IRC) {#irker-irc-gateway}

### Configurer irker {#set-up-irker}

Configurer l'intégration irker pour un groupe.

```plaintext
PUT /groups/:id/integrations/irker
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | oui | Destinataires ou canaux séparés par des espaces. |
| `default_irc_uri` | string | non | `irc://irc.network.net:6697/`. |
| `server_host` | string | non | localhost. |
| `server_port` | entier | non | 6659\. |
| `colorize_messages` | boolean | non | Coloriser les messages. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver irker {#disable-irker}

Désactiver l'intégration irker pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/irker
```

### Obtenir les paramètres d'irker {#get-irker-settings}

Obtenir les paramètres d'intégration irker pour un groupe.

```plaintext
GET /groups/:id/integrations/irker
```

## JetBrains TeamCity {#jetbrains-teamcity}

### Configurer JetBrains TeamCity {#set-up-jetbrains-teamcity}

Configurer l'intégration JetBrains TeamCity pour un groupe.

La configuration de build dans TeamCity doit utiliser le format de numéro de build `%build.vcs.number%`. Dans les paramètres avancés de la racine VCS, configurez la surveillance de toutes les branches afin que les merge requests puissent être générées.

```plaintext
PUT /groups/:id/integrations/teamcity
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `teamcity_url` | string | oui | URL racine TeamCity (par exemple, `https://teamcity.example.com`). |
| `enable_ssl_verification` | boolean | non | Activer la vérification SSL. La valeur par défaut est `true` (activée). |
| `build_type` | string | oui | ID de configuration de build. |
| `username` | string | oui | Un utilisateur avec les permissions pour déclencher une build manuelle. |
| `password` | string | oui | Le mot de passe de l'utilisateur. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver JetBrains TeamCity {#disable-jetbrains-teamcity}

Désactiver l'intégration JetBrains TeamCity pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/teamcity
```

### Obtenir les paramètres de JetBrains TeamCity {#get-jetbrains-teamcity-settings}

Obtenir les paramètres d'intégration JetBrains TeamCity pour un groupe.

```plaintext
GET /groups/:id/integrations/teamcity
```

## Jira {#jira}

### Configurer Jira {#set-up-jira}

Configurer l'intégration Jira pour un groupe.

```plaintext
PUT /groups/:id/integrations/jira
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `url`           | string | oui | L'URL du projet Jira qui est lié à ce projet GitLab (par exemple, `https://jira.example.com`). |
| `api_url`   | string | non | L'URL de base de l'API de l'instance Jira. La valeur de l'URL web est utilisée si non définie (par exemple, `https://jira-api.example.com`). |
| `username`      | string | non   | L'adresse e-mail ou le nom d'utilisateur à utiliser avec Jira. Pour Jira Cloud, utilisez une adresse e-mail ; pour Jira Data Center et Jira Server, utilisez un nom d'utilisateur. Requis lors de l'utilisation de l'authentification Basic (`jira_auth_type` est `0`). |
| `password`      | string | oui  | Le jeton API Jira, le mot de passe ou le jeton d'accès personnel à utiliser avec Jira. Lorsque votre méthode d'authentification est basic (`jira_auth_type` est `0`), utilisez un jeton API pour Jira Cloud ou un mot de passe pour Jira Data Center ou Jira Server. Lorsque votre méthode d'authentification est un jeton d'accès personnel Jira (`jira_auth_type` est `1`), utilisez le jeton d'accès personnel. |
| `jira_auth_type`| entier | non  | La méthode d'authentification à utiliser avec Jira. `0` signifie Authentification Basic. `1` signifie jeton d'accès personnel Jira. Par défaut `0`. |
| `jira_issue_prefix` | string | non | Préfixe pour faire correspondre les clés de tickets Jira. |
| `jira_issue_regex` | string | non | Expression régulière pour faire correspondre les clés de tickets Jira. |
| `jira_issue_transition_automatic` | boolean | non | Activer les [transitions de tickets automatiques](../integration/jira/issues.md#automatic-issue-transitions). A la priorité sur `jira_issue_transition_id` si activé. Par défaut `false`. |
| `jira_issue_transition_id` | string | non | L'ID d'une ou plusieurs transitions pour les [transitions de tickets personnalisées](../integration/jira/issues.md#custom-issue-transitions). Ignoré si `jira_issue_transition_automatic` est activé. La valeur par défaut est une chaîne vide, ce qui désactive les transitions personnalisées. |
| `commit_events` | boolean | non | Activer les notifications pour les événements de commit. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `comment_on_event_enabled` | boolean | non | Activer les commentaires dans les tickets Jira pour chaque événement GitLab (commit ou merge request). |
| `issues_enabled` | boolean | non | Activer la consultation des tickets Jira dans GitLab. |
| `project_keys` | tableau de chaînes | non | Clés des projets Jira. Lorsque `issues_enabled` est `true`, ce paramètre spécifie les projets Jira depuis lesquels afficher les tickets dans GitLab. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Jira {#disable-jira}

Désactiver l'intégration Jira pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/jira
```

### Obtenir les paramètres de Jira {#get-jira-settings}

Obtenir les paramètres d'intégration Jira pour un groupe.

```plaintext
GET /groups/:id/integrations/jira
```

## Linear {#linear}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198297) dans GitLab 18.3.

{{< /history >}}

### Configurer Linear {#set-up-linear}

Configurer l'intégration Linear pour un groupe.

```plaintext
PUT /groups/:id/integrations/linear
```

Paramètres :

| Paramètre     | Type   | Obligatoire | Description    |
| ------------- | ------ | -------- | -------------- |
| `workspace_url`  | string | oui     | URL du ticket.     |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Linear {#disable-linear}

Désactiver l'intégration Linear pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/linear
```

### Obtenir les paramètres de Linear {#get-linear-settings}

Obtenir les paramètres d'intégration Linear pour un groupe.

```plaintext
GET /groups/:id/integrations/linear
```

## Notifications Matrix {#matrix-notifications}

### Configurer les notifications Matrix {#set-up-matrix-notifications}

Configurer les notifications Matrix pour un groupe.

```plaintext
PUT /groups/:id/integrations/matrix
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `hostname`   | string | non | Nom d'hôte personnalisé du serveur Matrix. La valeur par défaut est `https://matrix.org`. |
| `token`   | string | oui | Le jeton d'accès Matrix (par exemple, `syt-zyx57W2v1u123ew11`). |
| `room` | string | oui | Identifiant unique de la salle cible (au format `!qPKKM111FFKKsfoCVy:matrix.org`). |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines en échec. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de ticket. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de ticket confidentiel. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tag. |
| `note_events` | boolean | non | Activer les notifications pour les événements de note. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de note confidentielle. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de page wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver les notifications Matrix {#disable-matrix-notifications}

Désactiver les notifications Matrix pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/matrix
```

### Obtenir les paramètres des notifications Matrix {#get-matrix-notifications-settings}

Obtenir les paramètres des notifications Matrix pour un groupe.

```plaintext
GET /groups/:id/integrations/matrix
```

## Notifications Mattermost {#mattermost-notifications}

### Configurer les notifications Mattermost {#set-up-mattermost-notifications}

Configurer les notifications Mattermost pour un groupe.

```plaintext
PUT /groups/:id/integrations/mattermost
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | oui | Webhook des notifications Mattermost (par exemple, `http://mattermost.example.com/hooks/...`). |
| `username` | string | non | Nom d'utilisateur des notifications Mattermost. |
| `channel` | string | non | Canal par défaut à utiliser si aucun autre canal n'est configuré. |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines en échec. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `notify_only_default_branch` | boolean | non | **Déprécié** : Ce paramètre a été remplacé par `branches_to_be_notified`. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `labels_to_be_notified` | string | non | Labels pour lesquels envoyer des notifications. Laisser vide pour recevoir des notifications pour tous les événements. |
| `labels_to_be_notified_behavior` | string | non | Labels pour lesquels être notifié. Les options valides sont `match_any` et `match_all`. La valeur par défaut est `match_any`. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de ticket. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de ticket confidentiel. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tag. |
| `note_events` | boolean | non | Activer les notifications pour les événements de note. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de note confidentielle. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de page wiki. |
| `push_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de push. |
| `issue_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de ticket. |
| `confidential_issue_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de ticket confidentiel. |
| `merge_request_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de merge request. |
| `note_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de note. |
| `confidential_note_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de note confidentielle. |
| `tag_push_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de push de tag. |
| `pipeline_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de pipeline. |
| `wiki_page_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de page wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver les notifications Mattermost {#disable-mattermost-notifications}

Désactiver les notifications Mattermost pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/mattermost
```

### Obtenir les paramètres des notifications Mattermost {#get-mattermost-notifications-settings}

Obtenir les paramètres des notifications Mattermost pour un groupe.

```plaintext
GET /groups/:id/integrations/mattermost
```

## Commandes slash Mattermost {#mattermost-slash-commands}

### Configurer les commandes slash Mattermost {#set-up-mattermost-slash-commands}

Configurer les commandes slash Mattermost pour un groupe.

```plaintext
PUT /groups/:id/integrations/mattermost-slash-commands
```

Paramètres :

| Paramètre | Type   | Obligatoire | Description           |
| --------- | ------ | -------- | --------------------- |
| `token`   | string | oui      | Le jeton Mattermost. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver les commandes slash Mattermost {#disable-mattermost-slash-commands}

Désactiver les commandes slash Mattermost pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/mattermost-slash-commands
```

### Obtenir les paramètres des commandes slash Mattermost {#get-mattermost-slash-commands-settings}

Obtenir les paramètres des commandes slash Mattermost pour un groupe.

```plaintext
GET /groups/:id/integrations/mattermost-slash-commands
```

## Notifications Microsoft Teams {#microsoft-teams-notifications}

### Configurer les notifications Microsoft Teams {#set-up-microsoft-teams-notifications}

Configurer les notifications Microsoft Teams pour un groupe.

```plaintext
PUT /groups/:id/integrations/microsoft-teams
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | oui | Le webhook Microsoft Teams (par exemple, `https://outlook.office.com/webhook/...`). |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines en échec. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `notify_only_default_branch` | boolean | non | **Déprécié** : Ce paramètre a été remplacé par `branches_to_be_notified`. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de ticket. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de ticket confidentiel. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tag. |
| `note_events` | boolean | non | Activer les notifications pour les événements de note. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de note confidentielle. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de page wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver les notifications Microsoft Teams {#disable-microsoft-teams-notifications}

Désactiver les notifications Microsoft Teams pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/microsoft-teams
```

### Obtenir les paramètres des notifications Microsoft Teams {#get-microsoft-teams-notifications-settings}

Obtenir les paramètres des notifications Microsoft Teams pour un groupe.

```plaintext
GET /groups/:id/integrations/microsoft-teams
```

## Mock CI {#mock-ci}

Cette intégration est uniquement disponible dans un environnement de développement. Pour un exemple de serveur Mock CI, voir [`gitlab-org/gitlab-mock-ci-service`](https://gitlab.com/gitlab-org/gitlab-mock-ci-service).

### Configurer Mock CI {#set-up-mock-ci}

Configurer l'intégration Mock CI pour un groupe.

```plaintext
PUT /groups/:id/integrations/mock-ci
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `mock_service_url` | string | oui | URL de l'intégration Mock CI. |
| `enable_ssl_verification` | boolean | non | Activer la vérification SSL. La valeur par défaut est `true` (activée). |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Mock CI {#disable-mock-ci}

Désactiver l'intégration Mock CI pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/mock-ci
```

### Obtenir les paramètres de Mock CI {#get-mock-ci-settings}

Obtenir les paramètres d'intégration Mock CI pour un groupe.

```plaintext
GET /groups/:id/integrations/mock-ci
```

## Packagist {#packagist}

### Configurer Packagist {#set-up-packagist}

Configurer l'intégration Packagist pour un groupe.

```plaintext
PUT /groups/:id/integrations/packagist
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `username` | string | oui | Le nom d'utilisateur d'un compte Packagist. |
| `token` | string | oui | Jeton API du serveur Packagist. |
| `server` | boolean | non | URL du serveur Packagist. Laisser vide pour la valeur par défaut `<https://packagist.org>`. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tag. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Packagist {#disable-packagist}

Désactiver l'intégration Packagist pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/packagist
```

### Obtenir les paramètres de Packagist {#get-packagist-settings}

Obtenir les paramètres d'intégration Packagist pour un groupe.

```plaintext
GET /groups/:id/integrations/packagist
```

## Phorge {#phorge}

### Configurer Phorge {#set-up-phorge}

Configurer l'intégration Phorge pour un groupe.

```plaintext
PUT /groups/:id/integrations/phorge
```

Paramètres :

| Paramètre       | Type   | Obligatoire | Description           |
|-----------------|--------|----------|-----------------------|
| `issues_url`    | string | oui     | URL du ticket.     |
| `project_url`   | string | oui     | URL du projet.   |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Phorge {#disable-phorge}

Désactiver l'intégration Phorge pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/phorge
```

### Obtenir les paramètres de Phorge {#get-phorge-settings}

Obtenir les paramètres d'intégration Phorge pour un groupe.

```plaintext
GET /groups/:id/integrations/phorge
```

## E-mails sur l'état du pipeline {#pipeline-status-emails}

### Configurer les e-mails sur l'état du pipeline {#set-up-pipeline-status-emails}

Configurer les e-mails sur l'état du pipeline pour un groupe.

```plaintext
PUT /groups/:id/integrations/pipelines-email
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | oui | Liste des adresses e-mail des destinataires séparées par des virgules. |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines en échec. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `notify_only_default_branch` | boolean | non | Envoyer des notifications pour la branche par défaut. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver les e-mails sur l'état du pipeline {#disable-pipeline-status-emails}

Désactiver les e-mails sur l'état du pipeline pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/pipelines-email
```

### Obtenir les paramètres des e-mails sur l'état du pipeline {#get-pipeline-status-emails-settings}

Obtenir les paramètres des e-mails sur l'état du pipeline pour un groupe.

```plaintext
GET /groups/:id/integrations/pipelines-email
```

## Pivotal Tracker {#pivotal-tracker}

### Configurer Pivotal Tracker {#set-up-pivotal-tracker}

Configurer l'intégration Pivotal Tracker pour un groupe.

```plaintext
PUT /groups/:id/integrations/pivotaltracker
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | oui | Le jeton Pivotal Tracker. |
| `restrict_to_branch` | boolean | non | Liste des branches à inspecter automatiquement, séparées par des virgules. Laissez vide pour inclure toutes les branches. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Pivotal Tracker {#disable-pivotal-tracker}

Désactiver l'intégration Pivotal Tracker pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/pivotaltracker
```

### Obtenir les paramètres de Pivotal Tracker {#get-pivotal-tracker-settings}

Obtenir les paramètres d'intégration Pivotal Tracker pour un groupe.

```plaintext
GET /groups/:id/integrations/pivotaltracker
```

## Pumble {#pumble}

### Configurer Pumble {#set-up-pumble}

Configurer l'intégration Pumble pour un groupe.

```plaintext
PUT /groups/:id/integrations/pumble
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | oui | Le webhook Pumble (par exemple, `https://api.pumble.com/workspaces/x/...`). |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de ticket confidentiel. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de note confidentielle. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de ticket. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `note_events` | boolean | non | Activer les notifications pour les événements de note. |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines en échec. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tag. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de page wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Pumble {#disable-pumble}

Désactiver l'intégration Pumble pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/pumble
```

### Obtenir les paramètres de Pumble {#get-pumble-settings}

Obtenir les paramètres d'intégration Pumble pour un groupe.

```plaintext
GET /groups/:id/integrations/pumble
```

## Pushover {#pushover}

### Configurer Pushover {#set-up-pushover}

Configurer l'intégration Pushover pour un groupe.

```plaintext
PUT /groups/:id/integrations/pushover
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `api_key` | string | oui | Votre clé d'application. |
| `user_key` | string | oui | Votre clé utilisateur. |
| `priority` | string | oui | La priorité. |
| `device` | string | non | Laisser vide pour tous les appareils actifs. |
| `sound` | string | non | Le son de la notification. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Pushover {#disable-pushover}

Désactiver l'intégration Pushover pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/pushover
```

### Obtenir les paramètres de Pushover {#get-pushover-settings}

Obtenir les paramètres d'intégration Pushover pour un groupe.

```plaintext
GET /groups/:id/integrations/pushover
```

## Redmine {#redmine}

### Configurer Redmine {#set-up-redmine}

Configurer l'intégration Redmine pour un groupe.

```plaintext
PUT /groups/:id/integrations/redmine
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | oui | URL du nouveau ticket. |
| `project_url` | string | oui | URL du projet. |
| `issues_url` | string | oui | URL du ticket. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Redmine {#disable-redmine}

Désactiver l'intégration Redmine pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/redmine
```

### Obtenir les paramètres de Redmine {#get-redmine-settings}

Obtenir les paramètres d'intégration Redmine pour un groupe.

```plaintext
GET /groups/:id/integrations/redmine
```

## Notifications Slack {#slack-notifications}

### Configurer les notifications Slack {#set-up-slack-notifications}

Configurer les notifications Slack pour un groupe.

```plaintext
PUT /groups/:id/integrations/slack
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | oui | Webhook des notifications Slack (par exemple, `https://hooks.slack.com/services/...`). |
| `username` | string | non | Nom d'utilisateur des notifications Slack. |
| `channel` | string | non | Canal par défaut à utiliser si aucun autre canal n'est configuré. |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines en échec. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `notify_only_default_branch` | boolean | non | **Déprécié** : Ce paramètre a été remplacé par `branches_to_be_notified`. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `labels_to_be_notified` | string | non | Labels pour lesquels envoyer des notifications. Laisser vide pour recevoir des notifications pour tous les événements. |
| `labels_to_be_notified_behavior` | string | non | Labels pour lesquels être notifié. Les options valides sont `match_any` et `match_all`. La valeur par défaut est `match_any`. |
| `alert_channel` | string | non | Le nom du canal pour recevoir des notifications pour les événements d'alerte. |
| `alert_events` | boolean | non | Activer les notifications pour les événements d'alerte. |
| `commit_events` | boolean | non | Activer les notifications pour les événements de commit. |
| `confidential_issue_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de ticket confidentiel. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de ticket confidentiel. |
| `confidential_note_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de note confidentielle. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de note confidentielle. |
| `deployment_channel` | string | non | Le nom du canal pour recevoir des notifications pour les événements de déploiement. |
| `deployment_events` | boolean | non | Activer les notifications pour les événements de déploiement. |
| `incident_channel` | string | non | Le nom du canal pour recevoir des notifications pour les événements d'incident. |
| `incidents_events` | boolean | non | Activer les notifications pour les événements d'incident. |
| `issue_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de ticket. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de ticket. |
| `job_events` | boolean | non | Activer les notifications pour les événements de job. |
| `merge_request_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de merge request. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `note_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de note. |
| `note_events` | boolean | non | Activer les notifications pour les événements de note. |
| `pipeline_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de pipeline. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `push_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de push. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `tag_push_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de push de tag. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tag. |
| `wiki_page_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de page wiki. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de page wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver les notifications Slack {#disable-slack-notifications}

Désactiver les notifications Slack pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/slack
```

### Obtenir les paramètres des notifications Slack {#get-slack-notifications-settings}

Obtenir les paramètres des notifications Slack pour un groupe.

```plaintext
GET /groups/:id/integrations/slack
```

## Squash TM {#squash-tm}

### Configurer Squash TM {#set-up-squash-tm}

Configurer les paramètres d'intégration Squash TM pour un groupe.

```plaintext
PUT /groups/:id/integrations/squash-tm
```

Paramètres :

| Paramètre               | Type   | Obligatoire | Description                   |
|-------------------------|--------|----------|-------------------------------|
| `url`                   | string | oui      | URL du webhook Squash TM. |
| `token`                 | string | non       | Jeton secret.                 |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Squash TM {#disable-squash-tm}

Désactiver l'intégration Squash TM pour un groupe. Les paramètres d'intégration sont conservés.

```plaintext
DELETE /groups/:id/integrations/squash-tm
```

### Obtenir les paramètres de Squash TM {#get-squash-tm-settings}

Obtenir les paramètres d'intégration Squash TM pour un groupe.

```plaintext
GET /groups/:id/integrations/squash-tm
```

## Telegram {#telegram}

### Configurer Telegram {#set-up-telegram}

Configurer l'intégration Telegram pour un groupe.

```plaintext
PUT /groups/:id/integrations/telegram
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `hostname`   | string | non | Nom d'hôte personnalisé de l'API Telegram. La valeur par défaut est `https://api.telegram.org`. |
| `token`   | string | oui | Le jeton du bot Telegram (par exemple, `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`). |
| `room` | string | oui | Identifiant unique du chat cible ou nom d'utilisateur du canal cible (au format `@channelusername`). |
| `thread` | entier | non | Identifiant unique du fil de discussion du message cible (sujet dans un supergroupre de forum). |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines en échec. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `push_events` | boolean | oui | Activer les notifications pour les événements de push. |
| `issues_events` | boolean | oui | Activer les notifications pour les événements de ticket. |
| `confidential_issues_events` | boolean | oui | Activer les notifications pour les événements de ticket confidentiel. |
| `merge_requests_events` | boolean | oui | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | oui | Activer les notifications pour les événements de push de tag. |
| `note_events` | boolean | oui | Activer les notifications pour les événements de note. |
| `confidential_note_events` | boolean | oui | Activer les notifications pour les événements de note confidentielle. |
| `pipeline_events` | boolean | oui | Activer les notifications pour les événements de pipeline. |
| `wiki_page_events` | boolean | oui | Activer les notifications pour les événements de page wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Telegram {#disable-telegram}

Désactiver l'intégration Telegram pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/telegram
```

### Obtenir les paramètres de Telegram {#get-telegram-settings}

Obtenir les paramètres d'intégration Telegram pour un groupe.

```plaintext
GET /groups/:id/integrations/telegram
```

## Unify Circuit {#unify-circuit}

### Configurer Unify Circuit {#set-up-unify-circuit}

Configurer l'intégration Unify Circuit pour un groupe.

```plaintext
PUT /groups/:id/integrations/unify-circuit
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | oui | Le webhook Unify Circuit (par exemple, `https://circuit.com/rest/v2/webhooks/incoming/...`). |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines en échec. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de ticket. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de ticket confidentiel. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tag. |
| `note_events` | boolean | non | Activer les notifications pour les événements de note. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de note confidentielle. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de page wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Unify Circuit {#disable-unify-circuit}

Désactiver l'intégration Unify Circuit pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/unify-circuit
```

### Obtenir les paramètres d'Unify Circuit {#get-unify-circuit-settings}

Obtenir les paramètres d'intégration Unify Circuit pour un groupe.

```plaintext
GET /groups/:id/integrations/unify-circuit
```

## Webex Teams {#webex-teams}

### Configurer Webex Teams {#set-up-webex-teams}

Configurer Webex Teams pour un groupe.

```plaintext
PUT /groups/:id/integrations/webex-teams
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | oui | Le webhook Webex Teams (par exemple, `https://api.ciscospark.com/v1/webhooks/incoming/...`). |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines en échec. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de ticket. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de ticket confidentiel. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tag. |
| `note_events` | boolean | non | Activer les notifications pour les événements de note. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de note confidentielle. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de page wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver Webex Teams {#disable-webex-teams}

Désactiver Webex Teams pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/webex-teams
```

### Obtenir les paramètres de Webex Teams {#get-webex-teams-settings}

Obtenir les paramètres de Webex Teams pour un groupe.

```plaintext
GET /groups/:id/integrations/webex-teams
```

## YouTrack {#youtrack}

### Configurer YouTrack {#set-up-youtrack}

Configurer l'intégration YouTrack pour un groupe.

```plaintext
PUT /groups/:id/integrations/youtrack
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `issues_url` | string | oui | URL du ticket. |
| `project_url` | string | oui | URL du projet. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. Par défaut `false`. |

### Désactiver YouTrack {#disable-youtrack}

Désactiver l'intégration YouTrack pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /groups/:id/integrations/youtrack
```

### Obtenir les paramètres de YouTrack {#get-youtrack-settings}

Obtenir les paramètres d'intégration YouTrack pour un groupe.

```plaintext
GET /groups/:id/integrations/youtrack
```
