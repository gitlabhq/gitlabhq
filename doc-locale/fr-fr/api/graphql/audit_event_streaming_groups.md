---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Gérez les destinations de diffusion d'événements d'audit pour les groupes principaux à l'aide de l'API GraphQL, notamment les configurations HTTP et Google Cloud Logging."
title: "API GraphQL de diffusion d'événements d'audit pour les groupes principaux"
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- L'API des en-têtes HTTP personnalisés a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/361216) dans GitLab 15.1 [avec un flag](../feature_flags.md) nommé `streaming_audit_event_headers`. Désactivé par défaut.
- L'API des en-têtes HTTP personnalisés a été [activée sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/362941) dans GitLab 15.2.
- L'API des en-têtes HTTP personnalisés a été [rendue généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/366524) dans GitLab 15.3. [Le feature flag `streaming_audit_event_headers`](https://gitlab.com/gitlab-org/gitlab/-/issues/362941) a été supprimé.
- La prise en charge de l'API de jeton de vérification spécifié par l'utilisateur a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/360813) dans GitLab 15.4.
- [Le feature flag `ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/393772) est activé par défaut dans GitLab 16.2.
- La prise en charge de l'API de nom de destination spécifié par l'utilisateur a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/413894) dans GitLab 16.2.
- Le [feature flag `ff_external_audit_events`](https://gitlab.com/gitlab-org/gitlab/-/issues/417708) de l'API a été supprimé dans GitLab 16.4.

{{< /history >}}

Gérez les destinations de diffusion d'événements d'audit pour les groupes principaux à l'aide d'une API GraphQL.

## Destinations HTTP {#http-destinations}

Gérez les destinations de diffusion HTTP pour les groupes principaux.

### Ajouter une nouvelle destination de diffusion {#add-a-new-streaming-destination}

Ajoutez une nouvelle destination de diffusion aux groupes principaux.

> [!warning]
> Les destinations de diffusion reçoivent **l'ensemble** des données d'événements d'audit, qui peuvent inclure des informations sensibles. Assurez-vous de faire confiance à la destination de diffusion.

Prérequis :

- Rôle de propriétaire pour un groupe principal.

Pour activer la diffusion et ajouter une destination à un groupe principal, utilisez la mutation `externalAuditEventDestinationCreate`.

```graphql
mutation {
  externalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest", groupPath: "my-group" } ) {
    errors
    externalAuditEventDestination {
      id
      name
      destinationUrl
      verificationToken
      group {
        name
      }
    }
  }
}
```

Vous pouvez éventuellement spécifier votre propre jeton de vérification (au lieu de celui généré par défaut par GitLab) à l'aide de la mutation GraphQL `externalAuditEventDestinationCreate`. La longueur du jeton de vérification doit être comprise entre 16 et 24 caractères et les espaces en fin de chaîne ne sont pas supprimés. Vous devez définir une valeur aléatoire et unique cryptographiquement. Par exemple :

```graphql
mutation {
  externalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest", groupPath: "my-group", verificationToken: "unique-random-verification-token-here" } ) {
    errors
    externalAuditEventDestination {
      id
      name
      destinationUrl
      verificationToken
      group {
        name
      }
    }
  }
}
```

Vous pouvez éventuellement spécifier votre propre nom de destination (au lieu de celui généré par défaut par GitLab) à l'aide de la mutation GraphQL `externalAuditEventDestinationCreate`. La longueur du nom ne doit pas dépasser 72 caractères et les espaces en fin de chaîne ne sont pas supprimés. Cette valeur doit être unique dans la portée d'un groupe. Par exemple :

```graphql
mutation {
  externalAuditEventDestinationCreate(input: { destinationUrl: "https://mydomain.io/endpoint/ingest", name: "destination-name-here", groupPath: "my-group" }) {
    errors
    externalAuditEventDestination {
      id
      name
      destinationUrl
      verificationToken
      group {
        name
      }
    }
  }
}
```

La diffusion d'événements est activée si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

Vous pouvez ajouter un en-tête HTTP à l'aide de la mutation GraphQL `auditEventsStreamingHeadersCreate`. Vous pouvez récupérer l'ID de destination en [listant toutes les destinations de diffusion](#list-streaming-destinations) pour le groupe ou à partir de la mutation ci-dessus.

```graphql
mutation {
  auditEventsStreamingHeadersCreate(input: {
    destinationId: "gid://gitlab/AuditEvents::ExternalAuditEventDestination/1",
     key: "foo",
     value: "bar",
     active: false
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

### Lister les destinations de diffusion {#list-streaming-destinations}

Listez les destinations de diffusion pour un groupe principal.

Prérequis :

- Rôle de propriétaire pour un groupe principal.

Vous pouvez afficher la liste des destinations de diffusion pour un groupe principal à l'aide du type de requête `externalAuditEventDestinations`.

```graphql
query {
  group(fullPath: "my-group") {
    id
    externalAuditEventDestinations {
      nodes {
        destinationUrl
        verificationToken
        id
        name
        headers {
          nodes {
            key
            value
            id
            active
          }
        }
        eventTypeFilters
        namespaceFilter {
          id
          namespace {
            id
            name
            fullName
          }
        }
      }
    }
  }
}
```

Si la liste résultante est vide, la diffusion d'audit n'est pas activée pour ce groupe.

### Mettre à jour les destinations de diffusion {#update-streaming-destinations}

Mettez à jour les destinations de diffusion pour un groupe principal.

Prérequis :

- Rôle de propriétaire pour un groupe principal.

Pour mettre à jour les destinations de diffusion pour un groupe, utilisez le type de mutation `externalAuditEventDestinationUpdate`. Vous pouvez récupérer l'ID des destinations en [listant toutes les destinations de diffusion](#list-streaming-destinations) pour le groupe.

```graphql
mutation {
  externalAuditEventDestinationUpdate(input: {
    id:"gid://gitlab/AuditEvents::ExternalAuditEventDestination/1",
    destinationUrl: "https://www.new-domain.com/webhook",
    name: "destination-name"} ) {
    errors
    externalAuditEventDestination {
      id
      name
      destinationUrl
      verificationToken
      group {
        name
      }
    }
  }
}
```

La destination de diffusion est mise à jour si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

Les utilisateurs ayant le rôle de propriétaire pour un groupe peuvent mettre à jour les en-têtes HTTP personnalisés des destinations de diffusion à l'aide du type de mutation `auditEventsStreamingHeadersUpdate`. Vous pouvez récupérer l'ID des en-têtes HTTP personnalisés en [listant tous les en-têtes HTTP personnalisés](#list-streaming-destinations) pour le groupe.

```graphql
mutation {
  auditEventsStreamingHeadersUpdate(input: { headerId: "gid://gitlab/AuditEvents::Streaming::Header/2", key: "new-key", value: "new-value", active: false }) {
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

Les propriétaires de groupe peuvent supprimer un en-tête HTTP à l'aide de la mutation GraphQL `auditEventsStreamingHeadersDestroy`. Vous pouvez récupérer l'ID de l'en-tête en [listant tous les en-têtes HTTP personnalisés](#list-streaming-destinations) pour le groupe.

```graphql
mutation {
  auditEventsStreamingHeadersDestroy(input: { headerId: "gid://gitlab/AuditEvents::Streaming::Header/1" }) {
    errors
  }
}
```

L'en-tête est supprimé si l'objet `errors` renvoyé est vide.

### Supprimer les destinations de diffusion {#delete-streaming-destinations}

Supprimez les destinations de diffusion pour un groupe principal.

Lorsque la dernière destination est supprimée avec succès, la diffusion est désactivée pour le groupe.

Prérequis :

- Rôle de propriétaire pour un groupe principal.

Les utilisateurs ayant le rôle de propriétaire pour un groupe peuvent supprimer les destinations de diffusion à l'aide du type de mutation `externalAuditEventDestinationDestroy`. Vous pouvez récupérer l'ID des destinations en [listant toutes les destinations de diffusion](#list-streaming-destinations) pour le groupe.

```graphql
mutation {
  externalAuditEventDestinationDestroy(input: { id: destination }) {
    errors
  }
}
```

La destination de diffusion est supprimée si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

Les propriétaires de groupe peuvent supprimer un en-tête HTTP à l'aide de la mutation GraphQL `auditEventsStreamingHeadersDestroy`. Vous pouvez récupérer l'ID de l'en-tête en [listant tous les en-têtes HTTP personnalisés](#list-streaming-destinations) pour le groupe.

```graphql
mutation {
  auditEventsStreamingHeadersDestroy(input: { headerId: "gid://gitlab/AuditEvents::Streaming::Header/1" }) {
    errors
  }
}
```

L'en-tête est supprimé si l'objet `errors` renvoyé est vide.

### Filtres de types d'événements {#event-type-filters}

{{< history >}}

- L'API des filtres de types d'événements a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/344845) dans GitLab 15.7.

{{< /history >}}

Lorsque cette fonctionnalité est activée pour un groupe, vous pouvez utiliser une API pour permettre aux utilisateurs de filtrer les événements d'audit diffusés par destination. Si la fonctionnalité est activée sans filtres, la destination reçoit tous les événements d'audit.

Une destination de diffusion dont un filtre de type d'événement est défini porte un label **filtré** ({{< icon name="filter" >}}).

#### Utiliser l'API pour ajouter un filtre de type d'événement {#use-the-api-to-add-an-event-type-filter}

Prérequis :

- Vous devez avoir le rôle Owner pour le groupe.

Vous pouvez ajouter une liste de filtres de types d'événements à l'aide du type de requête `auditEventsStreamingDestinationEventsAdd` :

```graphql
mutation {
    auditEventsStreamingDestinationEventsAdd(input: {
        destinationId: "gid://gitlab/AuditEvents::ExternalAuditEventDestination/1",
        eventTypeFilters: ["list of event type filters"]}){
        errors
        eventTypeFilters
    }
}
```

Les filtres de types d'événements sont ajoutés si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

#### Utiliser l'API pour supprimer un filtre de type d'événement {#use-the-api-to-remove-an-event-type-filter}

Prérequis :

- Vous devez avoir le rôle Owner pour le groupe.

Vous pouvez supprimer une liste de filtres de types d'événements à l'aide du type de mutation `auditEventsStreamingDestinationEventsRemove` :

```graphql
mutation {
    auditEventsStreamingDestinationEventsRemove(input: {
    destinationId: "gid://gitlab/AuditEvents::ExternalAuditEventDestination/1",
    eventTypeFilters: ["list of event type filters"]
  }){
    errors
  }
}
```

Les filtres de types d'événements sont supprimés si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

### Filtres d'espace de nommage {#namespace-filters}

{{< history >}}

- L'API des filtres d'espace de nommage a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/344845) dans GitLab 16.7.

{{< /history >}}

Lorsque vous appliquez un filtre d'espace de nommage à un groupe, les utilisateurs peuvent filtrer les événements d'audit diffusés par destination pour un sous-groupe ou un projet spécifique du groupe. Sinon, la destination reçoit tous les événements d'audit.

Une destination de diffusion dont un filtre d'espace de nommage est défini porte un label **filtré** ({{< icon name="filter" >}}).

#### Utiliser l'API pour ajouter un filtre d'espace de nommage {#use-the-api-to-add-a-namespace-filter}

Prérequis :

- Vous devez avoir le rôle Owner pour le groupe.

Vous pouvez ajouter un filtre d'espace de nommage à l'aide du type de mutation `auditEventsStreamingHttpNamespaceFiltersAdd` pour les sous-groupes et les projets.

Le filtre d'espace de nommage est ajouté si :

- L'API renvoie un objet `errors` vide.
- L'API répond avec `200 OK`.

##### Mutation pour sous-groupe {#mutation-for-subgroup}

```graphql
mutation auditEventsStreamingHttpNamespaceFiltersAdd {
  auditEventsStreamingHttpNamespaceFiltersAdd(input: {
    destinationId: "gid://gitlab/AuditEvents::ExternalAuditEventDestination/1",
    groupPath: "path/to/subgroup"
  }) {
    errors
    namespaceFilter {
      id
      namespace {
        id
        name
        fullName
      }
    }
  }
}
```

##### Mutation pour projet {#mutation-for-project}

```graphql
mutation auditEventsStreamingHttpNamespaceFiltersAdd {
  auditEventsStreamingHttpNamespaceFiltersAdd(input: {
    destinationId: "gid://gitlab/AuditEvents::ExternalAuditEventDestination/1",
    projectPath: "path/to/project"
  }) {
    errors
    namespaceFilter {
      id
      namespace {
        id
        name
        fullName
      }
    }
  }
}
```

#### Utiliser l'API pour supprimer un filtre d'espace de nommage {#use-the-api-to-remove-a-namespace-filter}

Prérequis :

- Vous devez avoir le rôle Owner pour le groupe.

Vous pouvez supprimer un filtre d'espace de nommage à l'aide du type de mutation `auditEventsStreamingHttpNamespaceFiltersDelete` :

```graphql
mutation auditEventsStreamingHttpNamespaceFiltersDelete {
  auditEventsStreamingHttpNamespaceFiltersDelete(input: {
    namespaceFilterId: "gid://gitlab/AuditEvents::Streaming::HTTP::NamespaceFilter/5"
  }) {
    errors
  }
}
```

Le filtre d'espace de nommage est supprimé si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

## Destinations Google Cloud Logging {#google-cloud-logging-destinations}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/409422) dans GitLab 16.1.

{{< /history >}}

Gérez les destinations Google Cloud Logging pour les groupes principaux.

Avant de configurer la diffusion d'événements d'audit Google Cloud Logging, vous devez satisfaire [les prérequis](../../user/compliance/audit_event_streaming.md#prerequisites).

### Ajouter une nouvelle destination Google Cloud Logging {#add-a-new-google-cloud-logging-destination}

Ajoutez une nouvelle destination de configuration Google Cloud Logging à un groupe principal.

Prérequis :

- Rôle de propriétaire pour un groupe principal.
- Un projet Google Cloud avec les autorisations nécessaires pour créer des comptes de service et activer Google Cloud Logging.

Pour activer la diffusion et ajouter une configuration, utilisez la mutation `googleCloudLoggingConfigurationCreate` dans l'API GraphQL.

```graphql
mutation {
  googleCloudLoggingConfigurationCreate(input: { groupPath: "my-group", googleProjectIdName: "my-google-project", clientEmail: "my-email@my-google-project.iam.gservice.account.com", privateKey: "YOUR_PRIVATE_KEY", logIdName: "audit-events", name: "destination-name" } ) {
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

La diffusion d'événements est activée si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.

### Lister les configurations Google Cloud Logging {#list-google-cloud-logging-configurations}

Listez toutes les destinations de configuration Google Cloud Logging pour un groupe principal.

Prérequis :

- Rôle de propriétaire pour un groupe principal.

Vous pouvez afficher la liste des configurations de diffusion pour un groupe principal à l'aide du type de requête `googleCloudLoggingConfigurations`.

```graphql
query {
  group(fullPath: "my-group") {
    id
    googleCloudLoggingConfigurations {
      nodes {
        id
        logIdName
        googleProjectIdName
        clientEmail
        name
      }
    }
  }
}
```

Si la liste résultante est vide, la diffusion d'audit n'est pas activée pour le groupe.

Vous avez besoin des valeurs d'ID renvoyées par cette requête pour les mutations de mise à jour et de suppression.

### Mettre à jour les configurations Google Cloud Logging {#update-google-cloud-logging-configurations}

Mettez à jour les destinations de configuration Google Cloud Logging pour un groupe principal.

Prérequis :

- Rôle de propriétaire pour un groupe principal.

Pour mettre à jour la configuration de diffusion pour un groupe principal, utilisez le type de mutation `googleCloudLoggingConfigurationUpdate`. Vous pouvez récupérer l'ID de configuration en [listant toutes les destinations externes](#list-google-cloud-logging-configurations).

```graphql
mutation {
  googleCloudLoggingConfigurationUpdate(
    input: {id: "gid://gitlab/AuditEvents::GoogleCloudLoggingConfiguration/1", googleProjectIdName: "my-google-project", clientEmail: "my-email@my-google-project.iam.gservice.account.com", privateKey: "YOUR_PRIVATE_KEY", logIdName: "audit-events", name: "updated-destination-name" }
  ) {
    errors
    googleCloudLoggingConfiguration {
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

Supprimez les destinations de diffusion pour un groupe principal.

Lorsque la dernière destination est supprimée avec succès, la diffusion est désactivée pour le groupe.

Prérequis :

- Rôle de propriétaire pour un groupe principal.

Les utilisateurs ayant le rôle de propriétaire pour un groupe peuvent supprimer les configurations de diffusion à l'aide du type de mutation `googleCloudLoggingConfigurationDestroy`. Vous pouvez récupérer l'ID des configurations en [listant toutes les destinations de diffusion](#list-google-cloud-logging-configurations) pour le groupe.

```graphql
mutation {
  googleCloudLoggingConfigurationDestroy(input: { id: "gid://gitlab/AuditEvents::GoogleCloudLoggingConfiguration/1" }) {
    errors
  }
}
```

La configuration de diffusion est supprimée si :

- L'objet `errors` renvoyé est vide.
- L'API répond avec `200 OK`.
