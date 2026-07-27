---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des intégrations de projet
description: "Configurez et gérez les intégrations d'un projet avec l'API REST."
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [intégrations](../user/project/integrations/_index.md) d'un projet.

Prérequis :

- Vous devez avoir le rôle Maintainer ou Owner pour le projet.

## Lister toutes les intégrations actives {#list-all-active-integrations}

{{< history >}}

- Le champ `vulnerability_events` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131831) dans GitLab 16.4.
- Le champ `inherited` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/154915) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le champ `inherited` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

Obtenez une liste de toutes les intégrations de projet actives. Le champ `vulnerability_events` est uniquement disponible pour GitLab Enterprise Edition.

```plaintext
GET /projects/:id/integrations
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

## Apple App Store Connect {#apple-app-store-connect}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Apple App Store Connect {#set-up-apple-app-store-connect}

Configurez l'intégration Apple App Store Connect pour un projet.

```plaintext
PUT /projects/:id/integrations/apple_app_store
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `app_store_issuer_id` | string | oui | ID de l'émetteur Apple App Store Connect. |
| `app_store_key_id` | string | oui | ID de clé Apple App Store Connect. |
| `app_store_private_key_file_name` | string | oui | Nom du fichier de clé privée Apple App Store Connect. |
| `app_store_private_key` | string | oui | Clé privée Apple App Store Connect. |
| `app_store_protected_refs` | boolean | non | Définir des variables uniquement sur les branches et les tags protégés. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Apple App Store Connect {#disable-apple-app-store-connect}

Désactivez l'intégration Apple App Store Connect pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/apple_app_store
```

### Obtenir les paramètres Apple App Store Connect {#get-apple-app-store-connect-settings}

Obtenez les paramètres d'intégration Apple App Store Connect pour un projet.

```plaintext
GET /projects/:id/integrations/apple_app_store
```

## Asana {#asana}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Asana {#set-up-asana}

Configurez l'intégration Asana pour un projet.

```plaintext
PUT /projects/:id/integrations/asana
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `api_key` | string | oui | Jeton d'API utilisateur. L'utilisateur doit avoir accès à la tâche. Tous les commentaires sont attribués à cet utilisateur. |
| `restrict_to_branch` | string | non | Liste de branches séparées par des virgules à inspecter automatiquement. Laissez vide pour inclure toutes les branches. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Asana {#disable-asana}

Désactivez l'intégration Asana pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/asana
```

### Obtenir les paramètres Asana {#get-asana-settings}

Obtenez les paramètres d'intégration Asana pour un projet.

```plaintext
GET /projects/:id/integrations/asana
```

## Assembla {#assembla}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Assembla {#set-up-assembla}

Configurez l'intégration Assembla pour un projet.

```plaintext
PUT /projects/:id/integrations/assembla
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | oui | Le jeton d'authentification. |
| `subdomain` | string | non | Le paramètre de sous-domaine. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Assembla {#disable-assembla}

Désactivez l'intégration Assembla pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/assembla
```

### Obtenir les paramètres Assembla {#get-assembla-settings}

Obtenez les paramètres d'intégration Assembla pour un projet.

```plaintext
GET /projects/:id/integrations/assembla
```

## Atlassian Bamboo {#atlassian-bamboo}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Atlassian Bamboo {#set-up-atlassian-bamboo}

Configurez l'intégration Atlassian Bamboo pour un projet.

Vous devez configurer l'étiquetage automatique des révisions et un déclencheur de dépôt dans Bamboo.

```plaintext
PUT /projects/:id/integrations/bamboo
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `bamboo_url` | string | oui | URL racine de Bamboo (par exemple, `https://bamboo.example.com`). |
| `enable_ssl_verification` | boolean | non | Activer la vérification SSL. La valeur par défaut est `true` (activé). |
| `build_key` | string | oui | Clé du plan de build Bamboo (par exemple, `KEY`). |
| `username` | string | oui | Utilisateur disposant d'un accès API au serveur Bamboo. |
| `password` | string | oui | Mot de passe de l'utilisateur. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Atlassian Bamboo {#disable-atlassian-bamboo}

Désactivez l'intégration Atlassian Bamboo pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/bamboo
```

### Obtenir les paramètres Atlassian Bamboo {#get-atlassian-bamboo-settings}

Obtenez les paramètres d'intégration Atlassian Bamboo pour un projet.

```plaintext
GET /projects/:id/integrations/bamboo
```

## Bugzilla {#bugzilla}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Bugzilla {#set-up-bugzilla}

Configurez l'intégration Bugzilla pour un projet.

```plaintext
PUT /projects/:id/integrations/bugzilla
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | oui |  URL du nouveau ticket. |
| `issues_url` | string | oui | URL du ticket. |
| `project_url` | string | oui | URL du projet. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Bugzilla {#disable-bugzilla}

Désactivez l'intégration Bugzilla pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/bugzilla
```

### Obtenir les paramètres Bugzilla {#get-bugzilla-settings}

Obtenez les paramètres d'intégration Bugzilla pour un projet.

```plaintext
GET /projects/:id/integrations/bugzilla
```

## Buildkite {#buildkite}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Buildkite {#set-up-buildkite}

Configurez l'intégration Buildkite pour un projet.

```plaintext
PUT /projects/:id/integrations/buildkite
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | oui | Jeton obtenu après la création d'un pipeline Buildkite avec un dépôt GitLab. |
| `project_url` | string | oui | URL du pipeline (par exemple, `https://buildkite.com/example/pipeline`). |
| `enable_ssl_verification` | boolean | non | **Déprécié** : Ce paramètre n'a aucun effet car la vérification SSL est toujours activée. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tags. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Buildkite {#disable-buildkite}

Désactivez l'intégration Buildkite pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/buildkite
```

### Obtenir les paramètres Buildkite {#get-buildkite-settings}

Obtenez les paramètres d'intégration Buildkite pour un projet.

```plaintext
GET /projects/:id/integrations/buildkite
```

## Campfire Classic {#campfire-classic}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

Vous pouvez vous intégrer à Campfire Classic. Cependant, Campfire Classic est un ancien produit qui n'est [plus vendu](https://gitlab.com/gitlab-org/gitlab/-/issues/329337) par Basecamp.

### Configurer Campfire Classic {#set-up-campfire-classic}

Configurez l'intégration Campfire Classic pour un projet.

```plaintext
PUT /projects/:id/integrations/campfire
```

Paramètres :

| Paramètre     | Type    | Obligatoire | Description                                                                                 |
|---------------|---------|----------|---------------------------------------------------------------------------------------------|
| `token`       | string  | oui     | Jeton d'authentification API de Campfire Classic. Pour obtenir le jeton, connectez-vous à Campfire Classic et sélectionnez **My info**. |
| `subdomain`   | string  | non    | Sous-domaine `.campfirenow.com` lorsque vous êtes connecté. |
| `room`        | string  | non    | Partie ID de l'URL de la salle Campfire Classic. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Campfire Classic {#disable-campfire-classic}

Désactivez l'intégration Campfire Classic pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/campfire
```

### Obtenir les paramètres Campfire Classic {#get-campfire-classic-settings}

Obtenez les paramètres d'intégration Campfire Classic pour un projet.

```plaintext
GET /projects/:id/integrations/campfire
```

## ClickUp {#clickup}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/120732) dans GitLab 16.1.
- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer ClickUp {#set-up-clickup}

Configurez l'intégration ClickUp pour un projet.

```plaintext
PUT /projects/:id/integrations/clickup
```

Paramètres :

| Paramètre     | Type   | Obligatoire | Description    |
| ------------- | ------ | -------- | -------------- |
| `issues_url`  | string | oui     | URL du ticket.     |
| `project_url` | string | oui     | URL du projet.   |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver ClickUp {#disable-clickup}

Désactivez l'intégration ClickUp pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/clickup
```

### Obtenir les paramètres ClickUp {#get-clickup-settings}

Obtenez les paramètres d'intégration ClickUp pour un projet.

```plaintext
GET /projects/:id/integrations/clickup
```

## Confluence Workspace {#confluence-workspace}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

Utilisez un Confluence Cloud Workspace comme wiki de votre projet.

### Configurer Confluence Workspace {#set-up-confluence-workspace}

Configurez l'intégration Confluence Workspace pour un projet.

```plaintext
PUT /projects/:id/integrations/confluence
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `confluence_url` | string | oui | URL du Confluence Workspace hébergé sur `atlassian.net`. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Confluence Workspace {#disable-confluence-workspace}

Désactivez l'intégration Confluence Workspace pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/confluence
```

### Obtenir les paramètres Confluence Workspace {#get-confluence-workspace-settings}

Obtenez les paramètres d'intégration Confluence Workspace pour un projet.

```plaintext
GET /projects/:id/integrations/confluence
```

## Outil de suivi de tickets personnalisé {#custom-issue-tracker}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer un outil de suivi de tickets personnalisé {#set-up-a-custom-issue-tracker}

Configurez un outil de suivi de tickets personnalisé pour un projet.

```plaintext
PUT /projects/:id/integrations/custom-issue-tracker
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | oui |  URL du nouveau ticket. |
| `issues_url` | string | oui | URL du ticket. |
| `project_url` | string | oui | URL du projet. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver un outil de suivi de tickets personnalisé {#disable-a-custom-issue-tracker}

Désactivez un outil de suivi de tickets personnalisé pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/custom-issue-tracker
```

### Obtenir les paramètres de l'outil de suivi de tickets personnalisé {#get-custom-issue-tracker-settings}

Obtenez les paramètres de l'outil de suivi de tickets personnalisé pour un projet.

```plaintext
GET /projects/:id/integrations/custom-issue-tracker
```

## Datadog {#datadog}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Datadog {#set-up-datadog}

Configurez l'intégration Datadog pour un projet.

```plaintext
PUT /projects/:id/integrations/datadog
```

Paramètres :

| Paramètre              | Type    | Obligatoire | Description                                                                                                                                                                            |
|------------------------|---------|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api_key`              | string  | oui     | [Clé d'API](https://docs.datadoghq.com/account_management/api-app-keys/) utilisée pour l'authentification auprès de Datadog. |
| `datadog_ci_visibility`| boolean | oui     | Active la collecte des événements de pipeline et de job dans Datadog pour afficher les traces d'exécution de pipeline. |
| `api_url`              | string  | non    | URL complète de votre site Datadog. |
| `datadog_env`          | string  | non    | Pour les déploiements auto-gérés, tag `env%` pour toutes les données envoyées à Datadog. |
| `datadog_service`      | string  | non    | Instance GitLab pour taguer toutes les données dans Datadog. Peut être utilisé lors de la gestion de plusieurs déploiements auto-gérés. |
| `datadog_site`         | string  | non    | Site Datadog vers lequel envoyer des données. Pour envoyer des données au site EU, utilisez `datadoghq.eu`. |
| `datadog_tags`         | string  | non    | Tags personnalisés dans Datadog. Spécifiez un tag par ligne au format `key:value\nkey2:value2`. |
| `archive_trace_events` | boolean | non    | Lorsqu'activé, les job logs sont collectés par Datadog et affichés avec les traces d'exécution de pipeline ([introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/346339) dans GitLab 15.3). |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Datadog {#disable-datadog}

Désactivez l'intégration Datadog pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/datadog
```

### Obtenir les paramètres Datadog {#get-datadog-settings}

Obtenez les paramètres d'intégration Datadog pour un projet.

```plaintext
GET /projects/:id/integrations/datadog
```

## Diffblue Cover {#diffblue-cover}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Diffblue Cover {#set-up-diffblue-cover}

Configurez l'intégration Diffblue Cover pour un projet.

```plaintext
PUT /projects/:id/integrations/diffblue-cover
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `diffblue_license_key` | string | oui | Clé de licence Diffblue Cover. |
| `diffblue_access_token_name` | string | oui | Nom du jeton d'accès utilisé par Diffblue Cover dans les pipelines. |
| `diffblue_access_token_secret` | string  | oui | Secret du jeton d'accès utilisé par Diffblue Cover dans les pipelines. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Diffblue Cover {#disable-diffblue-cover}

Désactivez l'intégration Diffblue Cover pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/diffblue-cover
```

### Obtenir les paramètres Diffblue Cover {#get-diffblue-cover-settings}

Obtenez les paramètres d'intégration Diffblue Cover pour un projet.

```plaintext
GET /projects/:id/integrations/diffblue-cover
```

## Discord Notifications {#discord-notifications}

{{< history >}}

- Les paramètres `_channel` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125621) dans GitLab 16.3.
- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Discord Notifications {#set-up-discord-notifications}

Configurez Discord Notifications pour un projet.

```plaintext
PUT /projects/:id/integrations/discord
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | oui | Webhook Discord (par exemple, `https://discord.com/api/webhooks/...`). |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de tickets confidentiels. |
| `confidential_issue_channel` | string | non | Le webhook de remplacement pour recevoir des notifications pour les événements de tickets confidentiels. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de notes confidentielles. |
| `confidential_note_channel` | string | non | Le webhook de remplacement pour recevoir des notifications pour les événements de notes confidentielles. |
| `deployment_events` | boolean | non | Activer les notifications pour les événements de déploiement. |
| `deployment_channel` | string | non | Le webhook de remplacement pour recevoir des notifications pour les événements de déploiement. |
| `group_confidential_mentions_events` | boolean | non | Activer les notifications pour les événements de mentions confidentielles de groupe. |
| `group_confidential_mentions_channel` | string | non | Le webhook de remplacement pour recevoir des notifications pour les événements de mentions confidentielles de groupe. |
| `group_mentions_events` | boolean | non | Activer les notifications pour les événements de mentions de groupe. |
| `group_mentions_channel` | string | non | Le webhook de remplacement pour recevoir des notifications pour les événements de mentions de groupe. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de tickets. |
| `issue_channel` | string | non | Le webhook de remplacement pour recevoir des notifications pour les événements de tickets. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `merge_request_channel` | string | non | Le webhook de remplacement pour recevoir des notifications pour les événements de merge request. |
| `note_events` | boolean | non | Activer les notifications pour les événements de notes. |
| `note_channel` | string | non | Le webhook de remplacement pour recevoir des notifications pour les événements de notes. |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines défaillants. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `pipeline_channel` | string | non | Le webhook de remplacement pour recevoir des notifications pour les événements de pipeline. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `push_channel` | string | non | Le webhook de remplacement pour recevoir des notifications pour les événements de push. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tags. |
| `tag_push_channel` | string | non | Le webhook de remplacement pour recevoir des notifications pour les événements de push de tags. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de pages wiki. |
| `wiki_page_channel` | string | non | Le webhook de remplacement pour recevoir des notifications pour les événements de pages wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Discord Notifications {#disable-discord-notifications}

Désactivez Discord Notifications pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/discord
```

### Obtenir les paramètres Discord Notifications {#get-discord-notifications-settings}

Obtenez les paramètres Discord Notifications pour un projet.

```plaintext
GET /projects/:id/integrations/discord
```

## Drone {#drone}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Drone {#set-up-drone}

Configurez l'intégration Drone pour un projet.

```plaintext
PUT /projects/:id/integrations/drone-ci
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | oui | Jeton Drone CI. |
| `drone_url` | string | oui | URL de Drone CI (par exemple, `http://drone.example.com`). |
| `enable_ssl_verification` | boolean | non | Activer la vérification SSL. La valeur par défaut est `true` (activé). |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tags. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Drone {#disable-drone}

Désactivez l'intégration Drone pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/drone-ci
```

### Obtenir les paramètres Drone {#get-drone-settings}

Obtenez les paramètres d'intégration Drone pour un projet.

```plaintext
GET /projects/:id/integrations/drone-ci
```

## E-mails lors du push {#emails-on-push}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer les e-mails lors du push {#set-up-emails-on-push}

Configurez l'intégration e-mails lors du push pour un projet.

```plaintext
PUT /projects/:id/integrations/emails-on-push
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | oui | E-mails séparés par des espaces. |
| `disable_diffs` | boolean | non | Désactiver les diffs de code. |
| `send_from_committer_email` | boolean | non | Envoyer depuis le committer. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tags. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. Les notifications sont toujours envoyées pour les pushs de tags. La valeur par défaut est `all`. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver les e-mails lors du push {#disable-emails-on-push}

Désactivez l'intégration e-mails lors du push pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/emails-on-push
```

### Obtenir les paramètres des e-mails lors du push {#get-emails-on-push-settings}

Obtenez les paramètres d'intégration des e-mails lors du push pour un projet.

```plaintext
GET /projects/:id/integrations/emails-on-push
```

## Engineering Workflow Management (EWM) {#engineering-workflow-management-ewm}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer EWM {#set-up-ewm}

Configurez l'intégration EWM pour un projet.

```plaintext
PUT /projects/:id/integrations/ewm
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | oui | URL du nouveau ticket. |
| `project_url`   | string | oui | URL du projet. |
| `issues_url`    | string | oui | URL du ticket. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver EWM {#disable-ewm}

Désactivez l'intégration EWM pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/ewm
```

### Obtenir les paramètres EWM {#get-ewm-settings}

Obtenez les paramètres d'intégration EWM pour un projet.

```plaintext
GET /projects/:id/integrations/ewm
```

## Wiki externe {#external-wiki}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer un wiki externe {#set-up-an-external-wiki}

Configurez un wiki externe pour un projet.

```plaintext
PUT /projects/:id/integrations/external-wiki
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `external_wiki_url` | string | oui | URL du wiki externe. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver un wiki externe {#disable-an-external-wiki}

Désactivez un wiki externe pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/external-wiki
```

### Obtenir les paramètres du wiki externe {#get-external-wiki-settings}

Obtenez les paramètres du wiki externe pour un projet.

```plaintext
GET /projects/:id/integrations/external-wiki
```

## GitGuardian {#gitguardian}

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/435706) dans GitLab 16.9 [avec un feature flag](../administration/feature_flags/_index.md) nommé `git_guardian_integration`. Activé par défaut. Désactivé sur GitLab.com.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/438695#note_2226917025) dans GitLab 17.7.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/176391) dans GitLab 17.8. L'indicateur de fonctionnalité `git_guardian_integration` a été supprimé.
- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

[GitGuardian](https://www.gitguardian.com/) est un service de cybersécurité qui détecte les données sensibles telles que les clés d'API et les mots de passe dans les dépôts de code source. Il analyse les dépôts Git, alerte sur les violations de politique et aide les organisations à résoudre les problèmes de sécurité avant que les pirates ne puissent les exploiter.

Vous pouvez configurer GitLab pour rejeter les commits basés sur les politiques de GitGuardian.

Pour les problèmes connus et les étapes de dépannage, consultez [Dépannage de GitGuardian](../user/project/integrations/git_guardian.md#troubleshooting).

### Configurer GitGuardian {#set-up-gitguardian}

Configurez l'intégration GitGuardian pour un projet.

```plaintext
PUT /projects/:id/integrations/git-guardian
```

Paramètres :

| Paramètre | Type | Obligatoire | Description                                   |
| --------- | ---- | -------- |-----------------------------------------------|
| `token` | string | oui | Jeton d'API GitGuardian avec la portée `scan`. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver GitGuardian {#disable-gitguardian}

Désactivez l'intégration GitGuardian pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/git-guardian
```

### Obtenir les paramètres GitGuardian {#get-gitguardian-settings}

Obtenez les paramètres d'intégration GitGuardian pour un projet.

```plaintext
GET /projects/:id/integrations/git-guardian
```

## GitHub {#github}

{{< details >}}

- Édition : Premium, Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer GitHub {#set-up-github}

Configurez l'intégration GitHub pour un projet.

```plaintext
PUT /projects/:id/integrations/github
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | oui | Jeton d'API GitHub avec la portée OAuth `repo:status`. |
| `repository_url` | string | oui | URL du dépôt GitHub. |
| `static_context` | boolean | non | Ajouter le nom d'hôte de votre instance GitLab au [nom de la vérification de statut](../user/project/integrations/github.md#static-or-dynamic-status-check-names). |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver GitHub {#disable-github}

Désactiver l'intégration GitHub pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/github
```

### Obtenir les paramètres GitHub {#get-github-settings}

Obtenir les paramètres d'intégration GitHub pour un projet.

```plaintext
GET /projects/:id/integrations/github
```

## GitLab pour l'application Jira Cloud {#gitlab-for-jira-cloud-app}

L'intégration de l'application GitLab pour Jira Cloud est activée ou désactivée automatiquement via [la liaison et la dissociation de groupes dans Jira](../integration/jira/connect-app.md#configure-the-gitlab-for-jira-cloud-app). Vous ne pouvez pas activer ou désactiver l'intégration avec le formulaire des intégrations GitLab ou l'API.

### Mettre à jour l'intégration pour un projet {#update-integration-for-a-project}

Utilisez ce point de terminaison d'API pour mettre à jour une intégration que vous créez avec la liaison de groupe dans Jira.

```plaintext
PUT /projects/:id/integrations/jira-cloud-app
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `jira_cloud_app_service_ids` | string | non | ID de service Jira Service Management. Utilisez des virgules (`,`) pour séparer plusieurs ID. |
| `jira_cloud_app_enable_deployment_gating` | boolean | non | Active le contrôle du déploiement pour les déploiements GitLab bloqués depuis Jira Service Management. |
| `jira_cloud_app_deployment_gating_environments` | string | non | Les environnements (production, staging, testing ou development) pour lesquels activer le contrôle du déploiement. Obligatoire si le contrôle du déploiement est activé. Utilisez des virgules (`,`) pour séparer plusieurs environnements. |

### Obtenir les paramètres de l'application GitLab pour Jira Cloud {#get-gitlab-for-jira-cloud-app-settings}

Obtenir les paramètres d'intégration de l'application GitLab pour Jira Cloud pour un projet.

```plaintext
GET /projects/:id/integrations/jira-cloud-app
```

## Application GitLab pour Slack {#gitlab-for-slack-app}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer l'application GitLab pour Slack {#set-up-gitlab-for-slack-app}

Mettre à jour l'intégration de l'application GitLab pour Slack pour un projet.

Vous ne pouvez pas créer d'application GitLab pour Slack via l'API, car l'intégration nécessite un jeton OAuth 2.0 que vous ne pouvez pas obtenir uniquement depuis l'API GitLab. À la place, vous devez [installer l'application](../user/project/integrations/gitlab_slack_application.md#install-the-gitlab-for-slack-app) depuis l'interface GitLab. Vous pouvez ensuite utiliser ce point de terminaison d'API pour mettre à jour l'intégration.

```plaintext
PUT /projects/:id/integrations/gitlab-slack-application
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `channel` | string | non | Canal par défaut à utiliser si aucun autre canal n'est configuré. |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines défaillants. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `notify_only_default_branch` | boolean | non | **Déprécié** : Ce paramètre a été remplacé par `branches_to_be_notified`. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `alert_events` | boolean | non | Activer les notifications pour les événements d'alerte. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de tickets. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de tickets confidentiels. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `note_events` | boolean | non | Activer les notifications pour les événements de notes. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de notes confidentielles. |
| `deployment_events` | boolean | non | Activer les notifications pour les événements de déploiement. |
| `incidents_events` | boolean | non | Activer les notifications pour les événements d'incident. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tags. |
| `vulnerability_events` | boolean | non | Activer les notifications pour les événements de vulnérabilité. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de pages wiki. |
| `labels_to_be_notified` | string | non | Labels pour lesquels envoyer des notifications. Si non défini, recevez des notifications pour tous les événements. |
| `labels_to_be_notified_behavior` | string | non | Labels pour lesquels recevoir des notifications. Les options valides sont `match_any` et `match_all`. La valeur par défaut est `match_any`. |
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
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver l'application GitLab pour Slack {#disable-gitlab-for-slack-app}

Désactiver l'intégration de l'application GitLab pour Slack pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/gitlab-slack-application
```

### Obtenir les paramètres de l'application GitLab pour Slack {#get-gitlab-for-slack-app-settings}

Obtenir les paramètres d'intégration de l'application GitLab pour Slack pour un projet.

```plaintext
GET /projects/:id/integrations/gitlab-slack-application
```

## Google Chat {#google-chat}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Google Chat {#set-up-google-chat}

Configurer l'intégration Google Chat pour un projet.

```plaintext
PUT /projects/:id/integrations/hangouts-chat
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | oui | Le webhook Hangouts Chat (par exemple, `https://chat.googleapis.com/v1/spaces...`). |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines défaillants. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `notify_only_default_branch` | boolean | non | **Déprécié** : Ce paramètre a été remplacé par `branches_to_be_notified`. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de tickets. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de tickets confidentiels. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tags. |
| `note_events` | boolean | non | Activer les notifications pour les événements de notes. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de notes confidentielles. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de pages wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Google Chat {#disable-google-chat}

Désactiver l'intégration Google Chat pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/hangouts-chat
```

### Obtenir les paramètres Google Chat {#get-google-chat-settings}

Obtenir les paramètres d'intégration Google Chat pour un projet.

```plaintext
GET /projects/:id/integrations/hangouts-chat
```

## Google Artifact Management {#google-artifact-management}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com
- Statut : Bêta

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/425066) dans GitLab 16.9 en tant que fonctionnalité [bêta](../policy/development_stages_support.md) [avec un indicateur](../administration/feature_flags/_index.md) nommé `google_cloud_support_feature_flag`. Désactivé par défaut.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472) dans GitLab 17.1. L'indicateur de fonctionnalité `google_cloud_support_feature_flag` a été supprimé.
- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

Cette fonctionnalité est en [bêta](../policy/development_stages_support.md).

### Configurer Google Artifact Management {#set-up-google-artifact-management}

Configurer l'intégration Google Artifact Management pour un projet.

```plaintext
PUT /projects/:id/integrations/google-cloud-platform-artifact-registry
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `artifact_registry_project_id` | string | oui | ID du projet Google Cloud. |
| `artifact_registry_location` | string | oui | Emplacement du dépôt Artifact Registry. |
| `artifact_registry_repositories` | string | oui | Dépôt Artifact Registry. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Google Artifact Management {#disable-google-artifact-management}

Désactiver l'intégration Google Artifact Management pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/google-cloud-platform-artifact-registry
```

### Obtenir les paramètres Google Artifact Management {#get-google-artifact-management-settings}

Obtenir les paramètres d'intégration Google Artifact Management pour un projet.

```plaintext
GET /projects/:id/integrations/google-cloud-platform-artifact-registry
```

## Google Cloud Identity and Access Management (IAM) {#google-cloud-identity-and-access-management-iam}

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com
- Statut : Bêta

{{< /details >}}

{{< history >}}

- Introduit dans GitLab 16.10 en tant que fonctionnalité [bêta](../policy/development_stages_support.md) [avec un indicateur](../administration/feature_flags/_index.md) nommé `google_cloud_support_feature_flag`. Désactivé par défaut.
- [Activé sur GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150472) dans GitLab 17.1. L'indicateur de fonctionnalité `google_cloud_support_feature_flag` a été supprimé.
- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

Cette fonctionnalité est en [bêta](../policy/development_stages_support.md).

### Configurer Google Cloud Identity and Access Management {#set-up-google-cloud-identity-and-access-management}

Configurer l'intégration Google Cloud Identity and Access Management pour un projet.

```plaintext
PUT /projects/:id/integrations/google-cloud-platform-workload-identity-federation
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `workload_identity_federation_project_id` | string | oui | ID de projet Google Cloud pour la fédération d'identité de charge de travail (Workload Identity Federation). |
| `workload_identity_federation_project_number` | entier | oui | Numéro de projet Google Cloud pour la fédération d'identité de charge de travail (Workload Identity Federation). |
| `workload_identity_pool_id` | string | oui | ID du pool d'identités de charge de travail. |
| `workload_identity_pool_provider_id` | string | oui | ID du fournisseur du pool d'identités de charge de travail. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Google Cloud Identity and Access Management {#disable-google-cloud-identity-and-access-management}

Désactiver l'intégration Google Cloud Identity and Access Management pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/google-cloud-platform-workload-identity-federation
```

### Obtenir Google Cloud Identity and Access Management {#get-google-cloud-identity-and-access-management}

Obtenir les paramètres de Google Cloud Identity and Access Management pour un projet.

```plaintext
GET /projects/:id/integration/google-cloud-platform-workload-identity-federation
```

## Google Play {#google-play}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Google Play {#set-up-google-play}

Configurer l'intégration Google Play pour un projet.

```plaintext
PUT /projects/:id/integrations/google-play
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `package_name` | string | oui | Nom de package de l'application dans Google Play. |
| `service_account_key` | string | oui | Clé du compte de service Google Play. |
| `service_account_key_file_name` | string | oui | Nom de fichier de la clé du compte de service Google Play. |
| `google_play_protected_refs` | boolean | non | Définir des variables uniquement sur les branches et les tags protégés. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Google Play {#disable-google-play}

Désactiver l'intégration Google Play pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/google-play
```

### Obtenir les paramètres Google Play {#get-google-play-settings}

Obtenir les paramètres d'intégration Google Play pour un projet.

```plaintext
GET /projects/:id/integrations/google-play
```

## Harbor {#harbor}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Harbor {#set-up-harbor}

Configurer l'intégration Harbor pour un projet.

```plaintext
PUT /projects/:id/integrations/harbor
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `url` | string | oui | L'URL de base de l'instance Harbor liée au projet GitLab. Par exemple, `https://demo.goharbor.io`. |
| `project_name` | string | oui | Le nom du projet dans l'instance Harbor. Par exemple, `testproject`. |
| `username` | string | oui | Le nom d'utilisateur créé dans l'interface Harbor. |
| `password` | string | oui | Le mot de passe de l'utilisateur. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Harbor {#disable-harbor}

Désactiver l'intégration Harbor pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/harbor
```

### Obtenir les paramètres Harbor {#get-harbor-settings}

Obtenir les paramètres d'intégration Harbor pour un projet.

```plaintext
GET /projects/:id/integrations/harbor
```

## irker (passerelle IRC) {#irker-irc-gateway}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer irker {#set-up-irker}

Configurer l'intégration irker pour un projet.

```plaintext
PUT /projects/:id/integrations/irker
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | oui | Liste de canaux ou d'adresses e-mail séparés par des virgules. |
| `default_irc_uri` | string | non | URI à ajouter avant chaque destinataire. La valeur par défaut est `irc://irc.network.net:6697/`. |
| `server_host` | string | non | Nom d'hôte du démon irker. La valeur par défaut est `localhost`. |
| `server_port` | entier | non | Port du démon irker. La valeur par défaut est `6659`. |
| `colorize_messages` | boolean | non | Coloriser les messages. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver irker {#disable-irker}

Désactiver l'intégration irker pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/irker
```

### Obtenir les paramètres irker {#get-irker-settings}

Obtenir les paramètres d'intégration irker pour un projet.

```plaintext
GET /projects/:id/integrations/irker
```

## Jenkins {#jenkins}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Jenkins {#set-up-jenkins}

Configurer l'intégration Jenkins pour un projet.

```plaintext
PUT /projects/:id/integrations/jenkins
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `jenkins_url` | string | oui | URL du serveur Jenkins. |
| `enable_ssl_verification` | boolean | non | Activer la vérification SSL. La valeur par défaut est `true` (activé). |
| `project_name` | string | oui | Nom du projet Jenkins. |
| `username` | string | non | Nom d'utilisateur du serveur Jenkins. |
| `password` | string | non | Mot de passe du serveur Jenkins. |
| `push_events` | boolean | non | Active les notifications pour les événements de push. |
| `merge_requests_events` | boolean | non | Active les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Active les notifications pour les événements de push de tag. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Jenkins {#disable-jenkins}

Désactiver l'intégration Jenkins pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/jenkins
```

### Obtenir les paramètres Jenkins {#get-jenkins-settings}

Obtenir les paramètres d'intégration Jenkins pour un projet.

```plaintext
GET /projects/:id/integrations/jenkins
```

## JetBrains TeamCity {#jetbrains-teamcity}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer JetBrains TeamCity {#set-up-jetbrains-teamcity}

Configurer l'intégration JetBrains TeamCity pour un projet.

La configuration de build dans TeamCity doit utiliser le format de numéro de build `%build.vcs.number%`. Dans les paramètres avancés de la racine VCS, configurez la surveillance de toutes les branches afin que les merge requests puissent être construites.

```plaintext
PUT /projects/:id/integrations/teamcity
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `teamcity_url` | string | oui | URL racine de TeamCity (par exemple, `https://teamcity.example.com`). |
| `enable_ssl_verification` | boolean | non | Activer la vérification SSL. La valeur par défaut est `true` (activé). |
| `build_type` | string | oui | L'ID de configuration de build du projet TeamCity. |
| `username` | string | oui | Un utilisateur disposant des autorisations nécessaires pour déclencher une build manuelle. |
| `password` | string | oui | Le mot de passe de l'utilisateur. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver JetBrains TeamCity {#disable-jetbrains-teamcity}

Désactiver l'intégration JetBrains TeamCity pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/teamcity
```

### Obtenir les paramètres JetBrains TeamCity {#get-jetbrains-teamcity-settings}

Obtenir les paramètres d'intégration JetBrains TeamCity pour un projet.

```plaintext
GET /projects/:id/integrations/teamcity
```

## Tickets Jira {#jira-issues}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer les tickets Jira {#set-up-jira-issues}

Configurer l'[intégration des tickets Jira](../integration/jira/configure.md) pour un projet.

```plaintext
PUT /projects/:id/integrations/jira
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `url`           | string | oui | L'URL du projet Jira lié à ce projet GitLab (par exemple, `https://jira.example.com`). |
| `api_url`   | string | non | L'URL de base de l'API de l'instance Jira. La valeur de l'URL web est utilisée si non définie (par exemple, `https://jira-api.example.com`). |
| `username`      | string | non   | L'adresse e-mail ou le nom d'utilisateur à utiliser avec Jira. Utilisez une adresse e-mail pour Jira Cloud, et un nom d'utilisateur pour Jira Data Center et Jira Server. Obligatoire lors de l'utilisation de l'authentification de base (`jira_auth_type` est `0`). |
| `password`      | string | oui  | Le jeton d'API Jira, le mot de passe ou le jeton d'accès personnel à utiliser avec Jira. Lors de l'utilisation de l'authentification de base (`jira_auth_type` est `0`), utilisez un jeton d'API pour Jira Cloud, et un mot de passe pour Jira Data Center ou Jira Server. Pour un jeton d'accès personnel Jira (`jira_auth_type` est `1`), utilisez le jeton d'accès personnel. |
| `jira_auth_type`| entier | non  | La méthode d'authentification à utiliser avec Jira. Utilisez `0` pour l'authentification de base, et `1` pour le jeton d'accès personnel Jira. La valeur par défaut est `0`. |
| `jira_issue_prefix` | string | non | Préfixe pour faire correspondre les clés de tickets Jira. |
| `jira_issue_regex` | string | non | Expression régulière pour faire correspondre les clés de tickets Jira. |
| `jira_issue_transition_automatic` | boolean | non | Activer les [transitions de tickets automatiques](../integration/jira/issues.md#automatic-issue-transitions). A la priorité sur `jira_issue_transition_id` si activé. La valeur par défaut est `false`. |
| `jira_issue_transition_id` | string | non | L'ID d'une ou plusieurs transitions pour les [transitions de tickets personnalisées](../integration/jira/issues.md#custom-issue-transitions). Ignoré lorsque `jira_issue_transition_automatic` est activé. La valeur par défaut est une chaîne vide, ce qui désactive les transitions personnalisées. |
| `commit_events` | boolean | non | Activer les notifications pour les événements de commit. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `comment_on_event_enabled` | boolean | non | Activer les commentaires dans les tickets Jira pour chaque événement GitLab (commit ou merge request). |
| `issues_enabled` | boolean | non | Activer la consultation des tickets Jira dans GitLab. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/267015) dans GitLab 17.0. |
| `project_keys` | tableau de chaînes | non | Clés des projets Jira. Lorsque `issues_enabled` est `true`, ce paramètre spécifie les projets Jira à partir desquels consulter les tickets dans GitLab. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/267015) dans GitLab 17.0. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |
| `vulnerabilities_enabled` | boolean | non | Disponible uniquement dans GitLab EE. Lorsque défini sur `true`, crée des tickets Jira pour les vulnérabilités GitLab.|
| `vulnerabilities_issuetype` | number | non | Disponible uniquement dans GitLab EE. ID du type de ticket Jira à utiliser lors de la création de tickets à partir de vulnérabilités. |
| `project_key` | string | non | Disponible uniquement dans GitLab EE. Clé du projet à utiliser lors de la création de tickets à partir de vulnérabilités. Ce paramètre est obligatoire si vous utilisez l'intégration pour créer des tickets à partir de vulnérabilités. |
| `customize_jira_issue_enabled` | boolean | non | Disponible uniquement dans GitLab EE. Lorsque défini sur `true`, ouvre un formulaire prérempli sur l'instance Jira lors de la création d'un ticket Jira à partir d'une vulnérabilité. |

### Désactiver Jira {#disable-jira}

Désactiver l'intégration des tickets Jira pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/jira
```

### Obtenir les paramètres Jira {#get-jira-settings}

Obtenir les paramètres d'intégration des tickets Jira pour un projet.

```plaintext
GET /projects/:id/integrations/jira
```

## Linear {#linear}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/198297) dans GitLab 18.3.

{{< /history >}}

### Configurer Linear {#set-up-linear}

Configurer l'intégration Linear pour un groupe.

```plaintext
PUT /projects/:id/integrations/linear
```

Paramètres :

| Paramètre     | Type   | Obligatoire | Description    |
| ------------- | ------ | -------- | -------------- |
| `workspace_url`  | string | oui     | URL du ticket.     |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités ou non. La valeur par défaut est `false`. |

### Désactiver Linear {#disable-linear}

Désactiver l'intégration Linear pour un groupe. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/linear
```

### Obtenir les paramètres Linear {#get-linear-settings}

Obtenir les paramètres d'intégration Linear pour un groupe.

```plaintext
GET /projects/:id/integrations/linear
```

## Notifications Matrix {#matrix-notifications}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer les notifications Matrix {#set-up-matrix-notifications}

Configurer les notifications Matrix pour un projet.

```plaintext
PUT /projects/:id/integrations/matrix
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `hostname`   | string | non | Nom d'hôte personnalisé du serveur Matrix. La valeur par défaut est `https://matrix.org`. |
| `token`   | string | oui | Le jeton d'accès Matrix (par exemple, `syt-zyx57W2v1u123ew11`). |
| `room` | string | oui | Identifiant unique pour la salle cible (au format `!qPKKM111FFKKsfoCVy:matrix.org`). |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines défaillants. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de tickets. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de tickets confidentiels. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tags. |
| `note_events` | boolean | non | Activer les notifications pour les événements de notes. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de notes confidentielles. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de pages wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver les notifications Matrix {#disable-matrix-notifications}

Désactiver les notifications Matrix pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/matrix
```

### Obtenir les paramètres des notifications Matrix {#get-matrix-notifications-settings}

Obtenir les paramètres des notifications Matrix pour un projet.

```plaintext
GET /projects/:id/integrations/matrix
```

## Notifications Mattermost {#mattermost-notifications}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer les notifications Mattermost {#set-up-mattermost-notifications}

Configurer les notifications Mattermost pour un projet.

```plaintext
PUT /projects/:id/integrations/mattermost
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | oui | Webhook des notifications Mattermost (par exemple, `http://mattermost.example.com/hooks/...`). |
| `username` | string | non | Nom d'utilisateur des notifications Mattermost. |
| `channel` | string | non | Canal par défaut à utiliser si aucun autre canal n'est configuré. |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines défaillants. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `notify_only_default_branch` | boolean | non | **Déprécié** : Ce paramètre a été remplacé par `branches_to_be_notified`. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `labels_to_be_notified` | string | non | Labels pour lesquels envoyer des notifications. Laissez vide pour recevoir des notifications pour tous les événements. |
| `labels_to_be_notified_behavior` | string | non | Labels pour lesquels recevoir des notifications. Les options valides sont `match_any` et `match_all`. La valeur par défaut est `match_any`. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de tickets. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de tickets confidentiels. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tags. |
| `note_events` | boolean | non | Activer les notifications pour les événements de notes. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de notes confidentielles. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de pages wiki. |
| `push_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de push. |
| `issue_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de ticket. |
| `confidential_issue_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de ticket confidentiel. |
| `merge_request_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de merge request. |
| `note_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de note. |
| `confidential_note_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de note confidentielle. |
| `tag_push_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de push de tag. |
| `pipeline_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de pipeline. |
| `wiki_page_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de page wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver les notifications Mattermost {#disable-mattermost-notifications}

Désactiver les notifications Mattermost pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/mattermost
```

### Obtenir les paramètres des notifications Mattermost {#get-mattermost-notifications-settings}

Obtenir les paramètres des notifications Mattermost pour un projet.

```plaintext
GET /projects/:id/integrations/mattermost
```

## Commandes slash Mattermost {#mattermost-slash-commands}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer les commandes slash Mattermost {#set-up-mattermost-slash-commands}

Configurer les commandes slash Mattermost pour un projet.

```plaintext
PUT /projects/:id/integrations/mattermost-slash-commands
```

Paramètres :

| Paramètre | Type   | Obligatoire | Description           |
| --------- | ------ | -------- | --------------------- |
| `token`   | string | oui      | Le token Mattermost. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver les commandes slash Mattermost {#disable-mattermost-slash-commands}

Désactiver les commandes slash Mattermost pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/mattermost-slash-commands
```

### Obtenir les paramètres des commandes slash Mattermost {#get-mattermost-slash-commands-settings}

Obtenir les paramètres des commandes slash Mattermost pour un projet.

```plaintext
GET /projects/:id/integrations/mattermost-slash-commands
```

## Notifications Microsoft Teams {#microsoft-teams-notifications}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer les notifications Microsoft Teams {#set-up-microsoft-teams-notifications}

Configurer les notifications Microsoft Teams pour un projet.

```plaintext
PUT /projects/:id/integrations/microsoft-teams
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | oui | Le webhook Microsoft Teams (par exemple, `https://outlook.office.com/webhook/...`). |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines défaillants. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `notify_only_default_branch` | boolean | non | **Déprécié** : Ce paramètre a été remplacé par `branches_to_be_notified`. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de tickets. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de tickets confidentiels. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tags. |
| `note_events` | boolean | non | Activer les notifications pour les événements de notes. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de notes confidentielles. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de pages wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver les notifications Microsoft Teams {#disable-microsoft-teams-notifications}

Désactiver les notifications Microsoft Teams pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/microsoft-teams
```

### Obtenir les paramètres des notifications Microsoft Teams {#get-microsoft-teams-notifications-settings}

Obtenir les paramètres des notifications Microsoft Teams pour un projet.

```plaintext
GET /projects/:id/integrations/microsoft-teams
```

## Mock CI {#mock-ci}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

Cette intégration n'est disponible que dans un environnement de développement. Pour un exemple de serveur Mock CI, voir [`gitlab-org/gitlab-mock-ci-service`](https://gitlab.com/gitlab-org/gitlab-mock-ci-service).

### Configurer Mock CI {#set-up-mock-ci}

Configurer l'intégration Mock CI pour un projet.

```plaintext
PUT /projects/:id/integrations/mock-ci
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `mock_service_url` | string | oui | URL de l'intégration Mock CI. |
| `enable_ssl_verification` | boolean | non | Activer la vérification SSL. La valeur par défaut est `true` (activé). |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Mock CI {#disable-mock-ci}

Désactiver l'intégration Mock CI pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/mock-ci
```

### Obtenir les paramètres de Mock CI {#get-mock-ci-settings}

Obtenir les paramètres de l'intégration Mock CI pour un projet.

```plaintext
GET /projects/:id/integrations/mock-ci
```

## Packagist {#packagist}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Packagist {#set-up-packagist}

Configurer l'intégration Packagist pour un projet.

```plaintext
PUT /projects/:id/integrations/packagist
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `username` | string | oui | Nom d'utilisateur d'un compte Packagist. |
| `token` | string | oui | Jeton API du serveur Packagist. |
| `server` | boolean | non | URL du serveur Packagist. La valeur par défaut est `https://packagist.org`. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tags. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Packagist {#disable-packagist}

Désactiver l'intégration Packagist pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/packagist
```

### Obtenir les paramètres de Packagist {#get-packagist-settings}

Obtenir les paramètres de l'intégration Packagist pour un projet.

```plaintext
GET /projects/:id/integrations/packagist
```

## Phorge {#phorge}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145863) dans GitLab 16.11.
- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Phorge {#set-up-phorge}

Configurer l'intégration Phorge pour un projet.

```plaintext
PUT /projects/:id/integrations/phorge
```

Paramètres :

| Paramètre       | Type   | Obligatoire | Description           |
|-----------------|--------|----------|-----------------------|
| `issues_url`    | string | oui     | URL du ticket.     |
| `project_url`   | string | oui     | URL du projet.   |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Phorge {#disable-phorge}

Désactiver l'intégration Phorge pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/phorge
```

### Obtenir les paramètres de Phorge {#get-phorge-settings}

Obtenir les paramètres de l'intégration Phorge pour un projet.

```plaintext
GET /projects/:id/integrations/phorge
```

## E-mails de statut de pipeline {#pipeline-status-emails}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer les e-mails de statut de pipeline {#set-up-pipeline-status-emails}

Configurer les e-mails de statut de pipeline pour un projet.

```plaintext
PUT /projects/:id/integrations/pipelines-email
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `recipients` | string | oui | Liste séparée par des virgules des adresses e-mail des destinataires. |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines défaillants. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `notify_only_default_branch` | boolean | non | Envoyer des notifications pour la branche par défaut. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver les e-mails de statut de pipeline {#disable-pipeline-status-emails}

Désactiver les e-mails de statut de pipeline pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/pipelines-email
```

### Obtenir les paramètres des e-mails de statut de pipeline {#get-pipeline-status-emails-settings}

Obtenir les paramètres des e-mails de statut de pipeline pour un projet.

```plaintext
GET /projects/:id/integrations/pipelines-email
```

## Pivotal Tracker {#pivotal-tracker}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Pivotal Tracker {#set-up-pivotal-tracker}

Configurer l'intégration Pivotal Tracker pour un projet.

```plaintext
PUT /projects/:id/integrations/pivotaltracker
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `token` | string | oui | Le token Pivotal Tracker. |
| `restrict_to_branch` | boolean | non | Liste séparée par des virgules des branches à inspecter automatiquement. Laissez vide pour inclure toutes les branches. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Pivotal Tracker {#disable-pivotal-tracker}

Désactiver l'intégration Pivotal Tracker pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/pivotaltracker
```

### Obtenir les paramètres de Pivotal Tracker {#get-pivotal-tracker-settings}

Obtenir les paramètres de l'intégration Pivotal Tracker pour un projet.

```plaintext
GET /projects/:id/integrations/pivotaltracker
```

## Pumble {#pumble}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Pumble {#set-up-pumble}

Configurer l'intégration Pumble pour un projet.

```plaintext
PUT /projects/:id/integrations/pumble
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | oui | Le webhook Pumble (par exemple, `https://api.pumble.com/workspaces/x/...`). |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de tickets confidentiels. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de notes confidentielles. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de tickets. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `note_events` | boolean | non | Activer les notifications pour les événements de notes. |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines défaillants. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tags. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de pages wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Pumble {#disable-pumble}

Désactiver l'intégration Pumble pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/pumble
```

### Obtenir les paramètres de Pumble {#get-pumble-settings}

Obtenir les paramètres de l'intégration Pumble pour un projet.

```plaintext
GET /projects/:id/integrations/pumble
```

## Pushover {#pushover}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Pushover {#set-up-pushover}

Configurer l'intégration Pushover pour un projet.

```plaintext
PUT /projects/:id/integrations/pushover
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `api_key` | string | oui | La clé d'application. |
| `user_key` | string | oui | La clé utilisateur. |
| `priority` | string | oui | La priorité. |
| `device` | string | non | Laissez vide pour tous les appareils actifs. |
| `sound` | string | non | Le son de la notification. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Pushover {#disable-pushover}

Désactiver l'intégration Pushover pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/pushover
```

### Obtenir les paramètres de Pushover {#get-pushover-settings}

Obtenir les paramètres de l'intégration Pushover pour un projet.

```plaintext
GET /projects/:id/integrations/pushover
```

## Redmine {#redmine}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Redmine {#set-up-redmine}

Configurer l'intégration Redmine pour un projet.

```plaintext
PUT /projects/:id/integrations/redmine
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `new_issue_url` | string | oui | URL du nouveau ticket. |
| `project_url` | string | oui | URL du projet. |
| `issues_url` | string | oui | URL du ticket. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Redmine {#disable-redmine}

Désactiver l'intégration Redmine pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/redmine
```

### Obtenir les paramètres de Redmine {#get-redmine-settings}

Obtenir les paramètres de l'intégration Redmine pour un projet.

```plaintext
GET /projects/:id/integrations/redmine
```

## Notifications Slack {#slack-notifications}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer les notifications Slack {#set-up-slack-notifications}

Configurer les notifications Slack pour un projet.

```plaintext
PUT /projects/:id/integrations/slack
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | oui | Webhook des notifications Slack (par exemple, `https://hooks.slack.com/services/...`). |
| `username` | string | non | Nom d'utilisateur des notifications Slack. |
| `channel` | string | non | Canal par défaut à utiliser si aucun autre canal n'est configuré. |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines défaillants. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `notify_only_default_branch` | boolean | non | **Déprécié** : Ce paramètre a été remplacé par `branches_to_be_notified`. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `labels_to_be_notified` | string | non | Labels pour lesquels envoyer des notifications. Laissez vide pour recevoir des notifications pour tous les événements. |
| `labels_to_be_notified_behavior` | string | non | Labels pour lesquels recevoir des notifications. Les options valides sont `match_any` et `match_all`. La valeur par défaut est `match_any`. |
| `alert_channel` | string | non | Le nom du canal pour recevoir les notifications des événements d'alerte. |
| `alert_events` | boolean | non | Activer les notifications pour les événements d'alerte. |
| `commit_events` | boolean | non | Activer les notifications pour les événements de commit. |
| `confidential_issue_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de ticket confidentiel. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de tickets confidentiels. |
| `confidential_note_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de note confidentielle. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de notes confidentielles. |
| `deployment_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de déploiement. |
| `deployment_events` | boolean | non | Activer les notifications pour les événements de déploiement. |
| `incident_channel` | string | non | Le nom du canal pour recevoir les notifications des événements d'incident. |
| `incidents_events` | boolean | non | Activer les notifications pour les événements d'incident. |
| `issue_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de ticket. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de tickets. |
| `job_events` | boolean | non | Activer les notifications pour les événements de job. |
| `merge_request_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de merge request. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `note_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de note. |
| `note_events` | boolean | non | Activer les notifications pour les événements de notes. |
| `pipeline_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de pipeline. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `push_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de push. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `tag_push_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de push de tag. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tags. |
| `wiki_page_channel` | string | non | Le nom du canal pour recevoir les notifications des événements de page wiki. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de pages wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver les notifications Slack {#disable-slack-notifications}

Désactiver les notifications Slack pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/slack
```

### Obtenir les paramètres des notifications Slack {#get-slack-notifications-settings}

Obtenir les paramètres des notifications Slack pour un projet.

```plaintext
GET /projects/:id/integrations/slack
```

## Squash TM {#squash-tm}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/337855) dans GitLab 15.10.
- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Squash TM {#set-up-squash-tm}

Configurer les paramètres de l'intégration Squash TM pour un projet.

```plaintext
PUT /projects/:id/integrations/squash-tm
```

Paramètres :

| Paramètre               | Type   | Obligatoire | Description                   |
|-------------------------|--------|----------|-------------------------------|
| `url`                   | string | oui      | URL du webhook Squash TM. |
| `token`                 | string | non       | Token secret.                 |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Squash TM {#disable-squash-tm}

Désactiver l'intégration Squash TM pour un projet. Les paramètres d'intégration sont conservés.

```plaintext
DELETE /projects/:id/integrations/squash-tm
```

### Obtenir les paramètres de Squash TM {#get-squash-tm-settings}

Obtenir les paramètres de l'intégration Squash TM pour un projet.

```plaintext
GET /projects/:id/integrations/squash-tm
```

## Telegram {#telegram}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Telegram {#set-up-telegram}

Configurer l'intégration Telegram pour un projet.

```plaintext
PUT /projects/:id/integrations/telegram
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `hostname`   | string | non | Nom d'hôte personnalisé de l'API Telegram ([introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/461313) dans GitLab 17.1). La valeur par défaut est `https://api.telegram.org`. |
| `token`   | string | oui | Le token du bot Telegram (par exemple, `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`). |
| `room` | string | oui | Identifiant unique du chat cible ou nom d'utilisateur du canal cible (au format `@channelusername`). |
| `thread` | entier | non | Identifiant unique du fil de discussion cible (topic dans un supergroupe forum). [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/441097) dans GitLab 16.11. |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines défaillants. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications ([introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134361) dans GitLab 16.5). Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `push_events` | boolean | oui | Activer les notifications pour les événements de push. |
| `issues_events` | boolean | oui | Activer les notifications pour les événements de tickets. |
| `confidential_issues_events` | boolean | oui | Activer les notifications pour les événements de tickets confidentiels. |
| `merge_requests_events` | boolean | oui | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | oui | Activer les notifications pour les événements de push de tags. |
| `note_events` | boolean | oui | Activer les notifications pour les événements de notes. |
| `confidential_note_events` | boolean | oui | Activer les notifications pour les événements de notes confidentielles. |
| `pipeline_events` | boolean | oui | Activer les notifications pour les événements de pipeline. |
| `wiki_page_events` | boolean | oui | Activer les notifications pour les événements de pages wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Telegram {#disable-telegram}

Désactiver l'intégration Telegram pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/telegram
```

### Obtenir les paramètres de Telegram {#get-telegram-settings}

Obtenir les paramètres de l'intégration Telegram pour un projet.

```plaintext
GET /projects/:id/integrations/telegram
```

## Unify Circuit {#unify-circuit}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Unify Circuit {#set-up-unify-circuit}

Configurer l'intégration Unify Circuit pour un projet.

```plaintext
PUT /projects/:id/integrations/unify-circuit
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | oui | Le webhook Unify Circuit (par exemple, `https://circuit.com/rest/v2/webhooks/incoming/...`). |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines défaillants. |
| `notify_only_when_pipeline_status_changes` | boolean | non | Envoyer des notifications uniquement lorsque le statut du pipeline pour la référence change. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de tickets. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de tickets confidentiels. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tags. |
| `note_events` | boolean | non | Activer les notifications pour les événements de notes. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de notes confidentielles. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de pages wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Unify Circuit {#disable-unify-circuit}

Désactiver l'intégration Unify Circuit pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/unify-circuit
```

### Obtenir les paramètres Unify Circuit {#get-unify-circuit-settings}

Obtenir les paramètres d'intégration Unify Circuit pour un projet.

```plaintext
GET /projects/:id/integrations/unify-circuit
```

## Webex Teams {#webex-teams}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer Webex Teams {#set-up-webex-teams}

Configurer Webex Teams pour un projet.

```plaintext
PUT /projects/:id/integrations/webex-teams
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `webhook` | string | oui | Le webhook Webex Teams (par exemple, `https://api.ciscospark.com/v1/webhooks/incoming/...`). |
| `notify_only_broken_pipelines` | boolean | non | Envoyer des notifications pour les pipelines défaillants. |
| `branches_to_be_notified` | string | non | Branches pour lesquelles envoyer des notifications. Les options valides sont `all`, `default`, `protected` et `default_and_protected`. La valeur par défaut est `default`. |
| `push_events` | boolean | non | Activer les notifications pour les événements de push. |
| `issues_events` | boolean | non | Activer les notifications pour les événements de tickets. |
| `confidential_issues_events` | boolean | non | Activer les notifications pour les événements de tickets confidentiels. |
| `merge_requests_events` | boolean | non | Activer les notifications pour les événements de merge request. |
| `tag_push_events` | boolean | non | Activer les notifications pour les événements de push de tags. |
| `note_events` | boolean | non | Activer les notifications pour les événements de notes. |
| `confidential_note_events` | boolean | non | Activer les notifications pour les événements de notes confidentielles. |
| `pipeline_events` | boolean | non | Activer les notifications pour les événements de pipeline. |
| `wiki_page_events` | boolean | non | Activer les notifications pour les événements de pages wiki. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver Webex Teams {#disable-webex-teams}

Désactiver Webex Teams pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/webex-teams
```

### Obtenir les paramètres Webex Teams {#get-webex-teams-settings}

Obtenir les paramètres Webex Teams pour un projet.

```plaintext
GET /projects/:id/integrations/webex-teams
```

## YouTrack {#youtrack}

{{< history >}}

- Le paramètre `use_inherited_settings` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/467089) dans GitLab 17.2 [avec un indicateur](../administration/feature_flags/_index.md) nommé `integration_api_inheritance`. Désactivé par défaut.
- Le paramètre `use_inherited_settings` est [généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/467186) dans GitLab 17.3. L'indicateur de fonctionnalité `integration_api_inheritance` a été supprimé.

{{< /history >}}

### Configurer YouTrack {#set-up-youtrack}

Configurer l'intégration YouTrack pour un projet.

```plaintext
PUT /projects/:id/integrations/youtrack
```

Paramètres :

| Paramètre | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `issues_url` | string | oui | URL du ticket. |
| `project_url` | string | oui | URL du projet. |
| `use_inherited_settings` | boolean | non | Indique si les paramètres par défaut doivent être hérités. La valeur par défaut est `false`. |

### Désactiver YouTrack {#disable-youtrack}

Désactiver l'intégration YouTrack pour un projet. Les paramètres d'intégration sont réinitialisés.

```plaintext
DELETE /projects/:id/integrations/youtrack
```

### Obtenir les paramètres YouTrack {#get-youtrack-settings}

Obtenir les paramètres d'intégration YouTrack pour un projet.

```plaintext
GET /projects/:id/integrations/youtrack
```
