---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des vulnérabilités de projet
description: API des vulnérabilités de projet pour lister et créer des vulnérabilités de projet. Nécessite une authentification et les autorisations appropriées.
---

{{< details >}}

- Édition : Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- `last_edited_at` [déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) dans GitLab 16.7.
- `start_date` [déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) dans GitLab 16.7.
- `updated_by_id` [déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) dans GitLab 16.7.
- `last_edited_by_id` [déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) dans GitLab 16.7.
- `due_date` [déprécié](https://gitlab.com/gitlab-org/gitlab/-/issues/268154) dans GitLab 16.7.

{{< /history >}}

> [!warning]
> Cette API est en cours de dépréciation et est considérée comme instable. Le contenu de la réponse peut être sujet à des modifications ou des ruptures entre les releases de GitLab. Utilisez plutôt l'[API GraphQL](graphql/reference/_index.md#queryvulnerabilities).

Utilisez cette API pour gérer les [vulnérabilités de projet](../user/application_security/vulnerabilities/_index.md). Chaque appel à cette API nécessite une authentification.

Si un utilisateur n'est pas membre d'un projet privé, les requêtes vers ce projet privé retournent un code de statut `404 Not Found`.

## Lister les vulnérabilités du projet {#list-project-vulnerabilities}

Lister toutes les vulnérabilités d'un projet.

Si un utilisateur authentifié n'a pas la permission [d'utiliser le tableau de bord de sécurité du projet](../user/permissions.md#project-permissions), les requêtes `GET` pour les vulnérabilités de ce projet résultent en un code de statut `403`.

Les réponses sont [paginées](rest/_index.md#pagination) et retournent 20 résultats par défaut.

```plaintext
GET /projects/:id/vulnerabilities
```

| Attribut     | Type           | Obligatoire | Description                                                                                                                                                                 |
| ------------- | -------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | entier ou chaîne de caractères | oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths).                                                            |

```shell
curl --request GET \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/4/vulnerabilities"
```

Exemple de réponse :

```json
[
    {
        "author_id": 1,
        "confidence": "medium",
        "created_at": "2020-04-07T14:01:04.655Z",
        "description": null,
        "dismissed_at": null,
        "dismissed_by_id": null,
        "finding": {
            "confidence": "medium",
            "created_at": "2020-04-07T14:01:04.630Z",
            "id": 103,
            "location_fingerprint": "228998b5db51d86d3b091939e2f5873ada0a14a1",
            "metadata_version": "2.0",
            "name": "Regular Expression Denial of Service in debug",
            "primary_identifier_id": 135,
            "project_id": 24,
            "raw_metadata": "{\"category\":\"dependency_scanning\",\"name\":\"Regular Expression Denial of Service\",\"message\":\"Regular Expression Denial of Service in debug\",\"description\":\"The debug module is vulnerable to regular expression denial of service when untrusted user input is passed into the `o` formatter. It takes around 50k characters to block for 2 seconds making this a low severity issue.\",\"cve\":\"yarn.lock:debug:gemnasium:37283ed4-0380-40d7-ada7-2d994afcc62a\",\"severity\":\"Unknown\",\"solution\":\"Upgrade to latest versions.\",\"scanner\":{\"id\":\"gemnasium\",\"name\":\"Gemnasium\"},\"location\":{\"file\":\"yarn.lock\",\"dependency\":{\"package\":{\"name\":\"debug\"},\"version\":\"1.0.5\"}},\"identifiers\":[{\"type\":\"gemnasium\",\"name\":\"Gemnasium-37283ed4-0380-40d7-ada7-2d994afcc62a\",\"value\":\"37283ed4-0380-40d7-ada7-2d994afcc62a\",\"url\":\"https://deps.sec.gitlab.com/packages/npm/debug/versions/1.0.5/advisories\"}],\"links\":[{\"url\":\"https://nodesecurity.io/advisories/534\"},{\"url\":\"https://github.com/visionmedia/debug/issues/501\"},{\"url\":\"https://github.com/visionmedia/debug/pull/504\"}],\"remediations\":[null]}",
            "report_type": "dependency_scanning",
            "scanner_id": 63,
            "severity": "low",
            "updated_at": "2020-04-07T14:01:04.664Z",
            "uuid": "f1d528ae-d0cc-47f6-a72f-936cec846ae7",
            "vulnerability_id": 103
        },
        "id": 103,
        "project": {
            "created_at": "2020-04-07T13:54:25.634Z",
            "description": "",
            "id": 24,
            "name": "security-reports",
            "name_with_namespace": "gitlab-org / security-reports",
            "path": "security-reports",
            "path_with_namespace": "gitlab-org/security-reports"
        },
        "project_default_branch": "main",
        "report_type": "dependency_scanning",
        "resolved_at": null,
        "resolved_by_id": null,
        "resolved_on_default_branch": false,
        "severity": "low",
        "state": "detected",
        "title": "Regular Expression Denial of Service in debug",
        "updated_at": "2020-04-07T14:01:04.655Z"
    }
]
```

## Créer une vulnérabilité {#create-a-vulnerability}

Crée une nouvelle vulnérabilité.

Si un utilisateur authentifié n'a pas la permission de [créer une nouvelle vulnérabilité](../user/permissions.md#project-permissions), cette requête résulte en un code de statut `403`.

```plaintext
POST /projects/:id/vulnerabilities?finding_id=<your_finding_id>
```

| Attribut           | Type              | Obligatoire   | Description                                                                                                                  |
| ------------------- | ----------------- | ---------- | -----------------------------------------------------------------------------------------------------------------------------|
| `id`                | entier ou chaîne de caractères | oui        | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) dont l'utilisateur authentifié est membre  |
| `finding_id`        | entier ou chaîne de caractères | oui        | L'ID d'un résultat de vulnérabilité à partir duquel créer la nouvelle vulnérabilité |

Les autres attributs d'une vulnérabilité nouvellement créée sont renseignés à partir du résultat de vulnérabilité source, ou avec ces valeurs par défaut :

| Attribut    | Valeur                                                 |
|--------------|-------------------------------------------------------|
| `author`     | L'utilisateur authentifié                                |
| `title`      | L'attribut `name` d'un résultat de vulnérabilité       |
| `state`      | `opened`                                              |
| `severity`   | L'attribut `severity` d'un résultat de vulnérabilité   |
| `confidence` | L'attribut `confidence` d'un résultat de vulnérabilité |

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/1/vulnerabilities?finding_id=1"
```

Exemple de réponse :

```json
{
    "author_id": 1,
    "confidence": "medium",
    "created_at": "2020-04-07T14:01:04.655Z",
    "description": null,
    "dismissed_at": null,
    "dismissed_by_id": null,
    "finding": {
        "confidence": "medium",
        "created_at": "2020-04-07T14:01:04.630Z",
        "id": 103,
        "location_fingerprint": "228998b5db51d86d3b091939e2f5873ada0a14a1",
        "metadata_version": "2.0",
        "name": "Regular Expression Denial of Service in debug",
        "primary_identifier_id": 135,
        "project_id": 24,
        "raw_metadata": "{\"category\":\"dependency_scanning\",\"name\":\"Regular Expression Denial of Service\",\"message\":\"Regular Expression Denial of Service in debug\",\"description\":\"The debug module is vulnerable to regular expression denial of service when untrusted user input is passed into the `o` formatter. It takes around 50k characters to block for 2 seconds making this a low severity issue.\",\"cve\":\"yarn.lock:debug:gemnasium:37283ed4-0380-40d7-ada7-2d994afcc62a\",\"severity\":\"Unknown\",\"solution\":\"Upgrade to latest versions.\",\"scanner\":{\"id\":\"gemnasium\",\"name\":\"Gemnasium\"},\"location\":{\"file\":\"yarn.lock\",\"dependency\":{\"package\":{\"name\":\"debug\"},\"version\":\"1.0.5\"}},\"identifiers\":[{\"type\":\"gemnasium\",\"name\":\"Gemnasium-37283ed4-0380-40d7-ada7-2d994afcc62a\",\"value\":\"37283ed4-0380-40d7-ada7-2d994afcc62a\",\"url\":\"https://deps.sec.gitlab.com/packages/npm/debug/versions/1.0.5/advisories\"}],\"links\":[{\"url\":\"https://nodesecurity.io/advisories/534\"},{\"url\":\"https://github.com/visionmedia/debug/issues/501\"},{\"url\":\"https://github.com/visionmedia/debug/pull/504\"}],\"remediations\":[null]}",
        "report_type": "dependency_scanning",
        "scanner_id": 63,
        "severity": "low",
        "updated_at": "2020-04-07T14:01:04.664Z",
        "uuid": "f1d528ae-d0cc-47f6-a72f-936cec846ae7",
        "vulnerability_id": 103
    },
    "id": 103,
    "project": {
        "created_at": "2020-04-07T13:54:25.634Z",
        "description": "",
        "id": 24,
        "name": "security-reports",
        "name_with_namespace": "gitlab-org / security-reports",
        "path": "security-reports",
        "path_with_namespace": "gitlab-org/security-reports"
    },
    "project_default_branch": "main",
    "report_type": "dependency_scanning",
    "resolved_at": null,
    "resolved_by_id": null,
    "resolved_on_default_branch": false,
    "severity": "low",
    "state": "detected",
    "title": "Regular Expression Denial of Service in debug",
    "updated_at": "2020-04-07T14:01:04.655Z"
}
```

### Erreurs {#errors}

Cette erreur se produit lorsqu'un résultat choisi pour créer une vulnérabilité est introuvable ou est déjà associé à une autre vulnérabilité :

```plaintext
A Vulnerability Finding is not found or already attached to a different Vulnerability
```

Code de statut : `400`

Exemple de réponse :

```json
{
  "message": {
    "base": [
      "finding is not found or is already attached to a vulnerability"
    ]
  }
}
```
