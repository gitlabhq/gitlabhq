---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Vulnerabilities
description: "Gérez les vulnérabilités GitLab avec l'API REST (obsolète). Prend en charge les opérations de récupération, confirmation, résolution, rejet et annulation. Utilisez plutôt GraphQL."
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `last_edited_at` [obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) dans GitLab 16.7.
- `start_date` [obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) dans GitLab 16.7.
- `updated_by_id` [obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) dans GitLab 16.7.
- `last_edited_by_id` [obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) dans GitLab 16.7.
- `due_date` [obsolète](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) dans GitLab 16.7.

{{< /history >}}

> [!note]
> L'ancienne API Vulnerabilities a été renommée en API Vulnerability Findings et sa documentation a été déplacée vers [un autre emplacement](vulnerability_findings.md). Ce document décrit désormais la nouvelle API Vulnerabilities qui permet d'accéder aux [Vulnerabilities](https://gitlab.com/groups/gitlab-org/-/epics/634).

Chaque appel d'API REST aux vulnérabilités doit être [authentifié](rest/authentication.md).

Si un utilisateur authentifié n'est pas autorisé à [consulter le rapport de vulnérabilité](../user/permissions.md#project-application-security), cette requête renvoie un code de statut `403 Forbidden`.

> [!warning]
> Cette API est en cours d'obsolescence et est considérée comme instable. Le contenu de la réponse peut être modifié ou rompu d'une release GitLab à l'autre. Utilisez plutôt l'[API GraphQL](graphql/reference/_index.md#queryvulnerabilities). Pour plus d'informations, consultez les [exemples GraphQL](#replace-vulnerability-rest-api-with-graphql).

## Récupérer une vulnérabilité {#retrieve-a-vulnerability}

Récupère une vulnérabilité spécifiée.

```plaintext
GET /vulnerabilities/:id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID d'une Vulnerability à récupérer |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/vulnerabilities/1"
```

Exemple de réponse :

```json
{
  "id": 1,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "opened",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "closed_by_id": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "closed_at": null
}
```

## Confirmer une vulnérabilité {#confirm-a-vulnerability}

Confirme une vulnérabilité spécifiée. Renvoie le code de statut `304` si la vulnérabilité est déjà confirmée.

Si un utilisateur authentifié n'est pas autorisé à [modifier le statut de la vulnérabilité](../user/permissions.md#project-application-security), cette requête génère un code de statut `403`.

```plaintext
POST /vulnerabilities/:id/confirm
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID d'une vulnérabilité à confirmer |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/vulnerabilities/5/confirm"
```

Exemple de réponse :

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "confirmed",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "closed_by_id": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "closed_at": null
}
```

## Résoudre une vulnérabilité {#resolve-a-vulnerability}

Résout une vulnérabilité spécifiée. Renvoie le code de statut `304` si la vulnérabilité est déjà résolue.

Si un utilisateur authentifié n'est pas autorisé à [modifier le statut de la vulnérabilité](../user/permissions.md#project-application-security), cette requête génère un code de statut `403`.

```plaintext
POST /vulnerabilities/:id/resolve
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID d'une Vulnerability à résoudre |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/vulnerabilities/5/resolve"
```

Exemple de réponse :

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "resolved",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "closed_by_id": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "closed_at": null
}
```

## Rejeter une vulnérabilité {#dismiss-a-vulnerability}

Rejette une vulnérabilité spécifiée. Renvoie le code de statut `304` si la vulnérabilité est déjà rejetée.

Si un utilisateur authentifié n'est pas autorisé à [modifier le statut de la vulnérabilité](../user/permissions.md#project-application-security), cette requête génère un code de statut `403`.

```plaintext
POST /vulnerabilities/:id/dismiss
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID d'une vulnérabilité à rejeter |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/vulnerabilities/5/dismiss"
```

Exemple de réponse :

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "closed",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "closed_by_id": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "closed_at": null
}
```

## Rétablir une vulnérabilité à l'état détecté {#revert-a-vulnerability-to-the-detected-state}

Rétablit une vulnérabilité spécifiée à l'état détecté. Renvoie le code de statut `304` si la vulnérabilité est déjà dans l'état détecté.

Si un utilisateur authentifié n'est pas autorisé à [modifier le statut de la vulnérabilité](../user/permissions.md#project-application-security), cette requête génère un code de statut `403`.

```plaintext
POST /vulnerabilities/:id/revert
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier ou chaîne | oui | L'ID d'une vulnérabilité à rétablir à l'état détecté |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/vulnerabilities/5/revert"
```

Exemple de réponse :

```json
{
  "id": 2,
  "title": "Predictable pseudorandom number generator",
  "description": null,
  "state": "detected",
  "severity": "medium",
  "confidence": "medium",
  "report_type": "sast",
  "project": {
    "id": 32,
    "name": "security-reports",
    "full_path": "/gitlab-examples/security/security-reports",
    "full_name": "gitlab-examples / security / security-reports"
  },
  "author_id": 1,
  "closed_by_id": null,
  "created_at": "2019-10-13T15:08:40.219Z",
  "updated_at": "2019-10-13T15:09:40.382Z",
  "closed_at": null
}
```

## Remplacer l'API REST Vulnerability par GraphQL {#replace-vulnerability-rest-api-with-graphql}

Pour vous préparer à la [prochaine obsolescence](https://gitlab.com/groups/gitlab-org/-/epics/5118) du point de terminaison de l'API REST Vulnerability, utilisez les exemples ci-dessous pour effectuer les opérations équivalentes avec l'API GraphQL.

### GraphQL - Vulnérabilité unique {#graphql---single-vulnerability}

Utilisez [`Query.vulnerability`](graphql/reference/_index.md#queryvulnerability).

```graphql
{
  vulnerability(id: "gid://gitlab/Vulnerability/20345379") {
    title
    description
    state
    severity
    reportType
    project {
      id
      name
      fullPath
    }
    detectedAt
    confirmedAt
    resolvedAt
    resolvedBy {
      id
      username
    }
  }
}
```

Exemple de réponse :

```json
{
  "data": {
    "vulnerability": {
      "title": "Improper Input Validation in railties",
      "description": "A remote code execution vulnerability in development mode Rails beta3 can allow an attacker to guess the automatically generated development mode secret token. This secret token can be used in combination with other Rails internals to escalate to a remote code execution exploit.",
      "state": "RESOLVED",
      "severity": "CRITICAL",
      "reportType": "DEPENDENCY_SCANNING",
      "project": {
        "id": "gid://gitlab/Project/6102100",
        "name": "security-reports",
        "fullPath": "gitlab-examples/security/security-reports"
      },
      "detectedAt": "2021-10-14T03:13:41Z",
      "confirmedAt": "2021-12-14T01:45:56Z",
      "resolvedAt": "2021-12-14T01:45:59Z",
      "resolvedBy": {
        "id": "gid://gitlab/User/480804",
        "username": "thiagocsf"
      }
    }
  }
}
```

### GraphQL - Confirmer une vulnérabilité {#graphql---confirm-vulnerability}

Utilisez [`Mutation.vulnerabilityConfirm`](graphql/reference/_index.md#mutationvulnerabilityconfirm).

```graphql
mutation {
  vulnerabilityConfirm(input: { id: "gid://gitlab/Vulnerability/23577695"}) {
    vulnerability {
      state
    }
    errors
  }
}
```

Exemple de réponse :

```json
{
  "data": {
    "vulnerabilityConfirm": {
      "vulnerability": {
        "state": "CONFIRMED"
      },
      "errors": []
    }
  }
}
```

### GraphQL - Résoudre une vulnérabilité {#graphql---resolve-vulnerability}

Utilisez [`Mutation.vulnerabilityResolve`](graphql/reference/_index.md#mutationvulnerabilityresolve).

```graphql
mutation {
  vulnerabilityResolve(input: { id: "gid://gitlab/Vulnerability/23577695"}) {
    vulnerability {
      state
    }
    errors
  }
}
```

Exemple de réponse :

```json
{
  "data": {
    "vulnerabilityConfirm": {
      "vulnerability": {
        "state": "RESOLVED"
      },
      "errors": []
    }
  }
}
```

### GraphQL - Rejeter une vulnérabilité {#graphql---dismiss-vulnerability}

Utilisez [`Mutation.vulnerabilityDismiss`](graphql/reference/_index.md#mutationvulnerabilitydismiss).

```graphql
mutation {
  vulnerabilityDismiss(input: { id: "gid://gitlab/Vulnerability/23577695"}) {
    vulnerability {
      state
    }
    errors
  }
}
```

Exemple de réponse :

```json
{
  "data": {
    "vulnerabilityConfirm": {
      "vulnerability": {
        "state": "DISMISSED"
      },
      "errors": []
    }
  }
}
```

### GraphQL - Rétablir une vulnérabilité à l'état détecté {#graphql---revert-vulnerability-to-the-detected-state}

Utilisez [`Mutation.vulnerabilityRevertToDetected`](graphql/reference/_index.md#mutationvulnerabilityreverttodetected).

```graphql
mutation {
  vulnerabilityRevertToDetected(input: { id: "gid://gitlab/Vulnerability/20345379"}) {
    vulnerability {
      state
    }
    errors
  }
}
```

Exemple de réponse :

```json
{
  "data": {
    "vulnerabilityConfirm": {
      "vulnerability": {
        "state": "DETECTED"
      },
      "errors": []
    }
  }
}
```
