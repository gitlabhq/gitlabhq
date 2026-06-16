---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Gérez les destinations de diffusion des événements d'audit pour l'ensemble des instances GitLab à l'aide de l'API GraphQL, notamment les configurations HTTP et Google Cloud Logging."
title: "API GraphQL de diffusion des événements d'audit pour les instances"
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/335175) dans GitLab 16.0 [avec un flag](../feature_flags.md) nommé `ff_external_audit_events`. Désactivé par défaut.
- Les API pour les en-têtes HTTP personnalisés pour les destinations de diffusion au niveau de l'instance ont été [introduites](https://gitlab.com/gitlab-org/gitlab/-/issues/404560) dans GitLab 16.1 [avec un flag](../feature_flags.md) nommé `ff_external_audit_events`. Désactivé par défaut.
- [Le feature flag `ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/393772) est activé par défaut dans GitLab 16.2.
- La prise en charge de l'API pour les noms de destination spécifiés par l'utilisateur a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/413894) dans GitLab 16.2.
- Les destinations de diffusion d'instance ont été [rendues généralement disponibles](https://gitlab.com/gitlab-org/gitlab/-/issues/393772) dans GitLab 16.4. [Le feature flag `ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/417708) a été supprimé.

{{< /history >}}

Gérez les destinations de diffusion des événements d'audit pour les instances à l'aide d'une API GraphQL.

## Destinations HTTP {#http-destinations}

Gérez les destinations de diffusion HTTP pour une instance entière.

### Ajouter une nouvelle destination HTTP {#add-a-new-http-destination}

Ajoutez une nouvelle destination de diffusion HTTP à une instance.

Prérequis :

- Accès administrateur à l'instance.

Pour activer la diffusion et ajouter une destination, utilisez la mutation `instanceExternalAuditEventDestinationCreate` dans l'API GraphQL.

```graphql
mutation {
  instanceExternalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest"}) {
    errors
    instanceExternalAuditEventDestination {
      destinationUrl
      id
      name
      verificationToken
    }
  }
}
```

La diffusion des événements est activée si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

Vous pouvez éventuellement spécifier votre propre nom de destination (au lieu du nom généré par défaut par GitLab) à l'aide de la mutation GraphQL `instanceExternalAuditEventDestinationCreate`. La longueur du nom ne doit pas dépasser 72 caractères et les espaces blancs en fin de chaîne ne sont pas supprimés. Cette valeur doit être unique. Par exemple :

```graphql
mutation {
  instanceExternalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest", name: "destination-name-here"}) {
    errors
    instanceExternalAuditEventDestination {
      destinationUrl
      id
      name
      verificationToken
    }
  }
}
```

Les administrateurs d'instance peuvent ajouter un en-tête HTTP à l'aide de la mutation GraphQL `auditEventsStreamingInstanceHeadersCreate`. Vous pouvez récupérer l'ID de destination en [répertoriant toutes les destinations de diffusion](#list-streaming-destinations) pour l'instance ou à partir de la mutation précédente.

```graphql
mutation {
  auditEventsStreamingInstanceHeadersCreate(input:
    {
      destinationId: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/42",
      key: "foo",
      value: "bar",
      active: true
    }) {
    errors
    header {
      id
      key
      value
      active
    }
  }
}
```

L'en-tête est créé si l'objet `errors` renvoyé est vide.

### Répertorier les destinations de diffusion {#list-streaming-destinations}

Répertoriez toutes les destinations de diffusion HTTP pour une instance.

Prérequis :

- Accès administrateur à l'instance.

Pour afficher une liste des destinations de diffusion pour une instance, utilisez le type de requête `instanceExternalAuditEventDestinations`.

```graphql
query {
  instanceExternalAuditEventDestinations {
    nodes {
      id
      name
      destinationUrl
      verificationToken
      headers {
        nodes {
          id
          key
          value
          active
        }
      }
      eventTypeFilters
    }
  }
}
```

Si la liste résultante est vide, la diffusion des audits n'est pas activée pour l'instance.

Vous avez besoin des valeurs d'ID renvoyées par cette requête pour les mutations de mise à jour et de suppression.

### Mettre à jour les destinations de diffusion {#update-streaming-destinations}

Mettez à jour une destination de diffusion HTTP pour une instance.

Prérequis :

- Accès administrateur à l'instance.

Pour mettre à jour les destinations de diffusion pour une instance, utilisez le type de mutation `instanceExternalAuditEventDestinationUpdate`. Vous pouvez récupérer l'ID de destination en [répertoriant toutes les destinations externes](#list-streaming-destinations) pour l'instance.

```graphql
mutation {
  instanceExternalAuditEventDestinationUpdate(input: {
    id: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/1",
    destinationUrl: "https://www.new-domain.com/webhook",
    name: "destination-name"}) {
    errors
    instanceExternalAuditEventDestination {
      destinationUrl
      id
      name
      verificationToken
    }
  }
}
```

La destination de diffusion est mise à jour si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

Les administrateurs d'instance peuvent mettre à jour les en-têtes HTTP personnalisés des destinations de diffusion à l'aide du type de mutation `auditEventsStreamingInstanceHeadersUpdate`. Vous pouvez récupérer l'ID des en-têtes HTTP personnalisés en [répertoriant tous les en-têtes HTTP personnalisés](#list-streaming-destinations) pour l'instance.

```graphql
mutation {
  auditEventsStreamingInstanceHeadersUpdate(input: { headerId: "gid://gitlab/AuditEvents::Streaming::InstanceHeader/2", key: "new-key", value: "new-value", active: false }) {
    errors
    header {
      id
      key
      value
      active
    }
  }
}
```

L'en-tête est mis à jour si l'objet `errors` renvoyé est vide.

### Supprimer les destinations de diffusion {#delete-streaming-destinations}

Supprimez les destinations de diffusion pour une instance entière.

Lorsque la dernière destination est supprimée avec succès, la diffusion est désactivée pour l'instance.

Prérequis :

- Accès administrateur à l'instance.

Pour supprimer les destinations de diffusion, utilisez le type de mutation `instanceExternalAuditEventDestinationDestroy`. Vous pouvez récupérer l'ID des destinations en [répertoriant toutes les destinations de diffusion](#list-streaming-destinations) pour l'instance.

```graphql
mutation {
  instanceExternalAuditEventDestinationDestroy(input: { id: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/1" }) {
    errors
  }
}
```

La destination de diffusion est supprimée si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

Pour supprimer un en-tête HTTP, utilisez la mutation GraphQL `auditEventsStreamingInstanceHeadersDestroy`. Pour récupérer l'ID de l'en-tête, [répertoriez tous les en-têtes HTTP personnalisés](#list-streaming-destinations) pour l'instance.

```graphql
mutation {
  auditEventsStreamingInstanceHeadersDestroy(input: { headerId: "gid://gitlab/AuditEvents::Streaming::InstanceHeader/<id>" }) {
    errors
  }
}
```

L'en-tête est supprimé si l'objet `errors` renvoyé est vide.

### Filtres de type d'événement {#event-type-filters}

{{< history >}}

- L'API de filtres de type d'événement a été [introduite](https://gitlab.com/groups/gitlab-org/-/epics/10868) dans GitLab 16.2.

{{< /history >}}

Lorsque cette fonctionnalité est activée pour une instance, vous pouvez utiliser une API pour permettre aux utilisateurs de filtrer les événements d'audit diffusés par destination. Si la fonctionnalité est activée sans filtre, la destination reçoit tous les événements d'audit.

Une destination de diffusion dont un filtre de type d'événement est défini possède un label **filtré** ({{< icon name="filter" >}}).

#### Utiliser l'API pour ajouter un filtre de type d'événement {#use-the-api-to-add-an-event-type-filter}

Prérequis :

- Vous devez disposer de l'accès administrateur pour l'instance.

Vous pouvez ajouter une liste de filtres de type d'événement à l'aide de la mutation `auditEventsStreamingDestinationInstanceEventsAdd` :

```graphql
mutation {
    auditEventsStreamingDestinationInstanceEventsAdd(input: {
        destinationId: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/1",
        eventTypeFilters: ["list of event type filters"]}){
        errors
        eventTypeFilters
    }
}
```

Les filtres de type d'événement sont ajoutés si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

#### Utiliser l'API pour supprimer un filtre de type d'événement {#use-the-api-to-remove-an-event-type-filter}

Prérequis :

- Vous devez disposer de l'accès administrateur pour l'instance.

Vous pouvez supprimer une liste de filtres de type d'événement à l'aide de la mutation `auditEventsStreamingDestinationInstanceEventsRemove` :

```graphql
mutation {
    auditEventsStreamingDestinationInstanceEventsRemove(input: {
    destinationId: "gid://gitlab/AuditEvents::InstanceExternalAuditEventDestination/1",
    eventTypeFilters: ["list of event type filters"]
  }){
    errors
  }
}
```

Les filtres de type d'événement sont supprimés si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

## Destinations Google Cloud Logging {#google-cloud-logging-destinations}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/11303) dans GitLab 16.5.

{{< /history >}}

Gérez les destinations Google Cloud Logging pour une instance entière.

Avant de configurer la diffusion des événements d'audit Google Cloud Logging, vous devez satisfaire [les prérequis](../../administration/compliance/audit_event_streaming.md#prerequisites).

### Ajouter une nouvelle destination Google Cloud Logging {#add-a-new-google-cloud-logging-destination}

Ajoutez une nouvelle destination de configuration Google Cloud Logging à une instance.

Prérequis :

- Vous disposez d'un accès administrateur à l'instance.
- Vous disposez d'un projet Google Cloud avec les autorisations nécessaires pour créer des comptes de service et activer Google Cloud Logging.

Pour activer la diffusion et ajouter une configuration, utilisez la mutation `instanceGoogleCloudLoggingConfigurationCreate` dans l'API GraphQL.

```graphql
mutation {
  instanceGoogleCloudLoggingConfigurationCreate(input: { googleProjectIdName: "my-google-project", clientEmail: "my-email@my-google-project.iam.gservice.account.com", privateKey: "YOUR_PRIVATE_KEY", logIdName: "audit-events", name: "destination-name" } ) {
    errors
    googleCloudLoggingConfiguration {
      id
      googleProjectIdName
      logIdName
      clientEmail
      name
    }
    errors
  }
}
```

La diffusion des événements est activée si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

### Répertorier les configurations Google Cloud Logging {#list-google-cloud-logging-configurations}

Répertoriez toutes les destinations de configuration Google Cloud Logging pour une instance.

Prérequis :

- Vous disposez d'un accès administrateur à l'instance.

Vous pouvez afficher une liste des configurations de diffusion pour une instance à l'aide du type de requête `instanceGoogleCloudLoggingConfigurations`.

```graphql
query {
  instanceGoogleCloudLoggingConfigurations {
    nodes {
      id
      logIdName
      googleProjectIdName
      clientEmail
      name
    }
  }
}
```

Si la liste résultante est vide, la diffusion des audits n'est pas activée pour l'instance.

Vous avez besoin des valeurs d'ID renvoyées par cette requête pour les mutations de mise à jour et de suppression.

### Mettre à jour les configurations Google Cloud Logging {#update-google-cloud-logging-configurations}

Mettez à jour les destinations de configuration Google Cloud Logging pour une instance.

Prérequis :

- Vous disposez d'un accès administrateur à l'instance.

Pour mettre à jour la configuration de diffusion pour une instance, utilisez le type de mutation `instanceGoogleCloudLoggingConfigurationUpdate`. Vous pouvez récupérer l'ID de configuration en [répertoriant toutes les destinations externes](#list-google-cloud-logging-configurations).

```graphql
mutation {
  instanceGoogleCloudLoggingConfigurationUpdate(
    input: {id: "gid://gitlab/AuditEvents::Instance::GoogleCloudLoggingConfiguration/1", googleProjectIdName: "updated-google-id", clientEmail: "updated@my-google-project.iam.gservice.account.com", privateKey: "YOUR_PRIVATE_KEY", logIdName: "audit-events", name: "updated name"}
  ) {
    errors
    instanceGoogleCloudLoggingConfiguration {
      id
      logIdName
      googleProjectIdName
      clientEmail
      name
    }
  }
}
```

La configuration de diffusion est mise à jour si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

### Supprimer les configurations Google Cloud Logging {#delete-google-cloud-logging-configurations}

Supprimez les destinations de diffusion pour une instance.

Lorsque la dernière destination est supprimée avec succès, la diffusion est désactivée pour l'instance.

Prérequis :

- Vous disposez d'un accès administrateur à l'instance.

Pour supprimer les configurations de diffusion, utilisez le type de mutation `instanceGoogleCloudLoggingConfigurationDestroy`. Vous pouvez récupérer l'ID des configurations en [répertoriant toutes les destinations de diffusion](#list-google-cloud-logging-configurations) pour l'instance.

```graphql
mutation {
  instanceGoogleCloudLoggingConfigurationDestroy(input: { id: "gid://gitlab/AuditEvents::Instance::GoogleCloudLoggingConfiguration/1" }) {
    errors
  }
}
```

La configuration de diffusion est supprimée si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.
