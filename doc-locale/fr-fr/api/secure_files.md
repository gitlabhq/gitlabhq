---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des fichiers sécurisés au niveau du projet
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Disponible en version générale](https://gitlab.com/gitlab-org/gitlab/-/issues/350748) dans GitLab 15.7. L'indicateur de fonctionnalité `ci_secure_files` a été supprimé.

{{< /history >}}

Utilisez cette API pour gérer les [fichiers sécurisés](../ci/secure_files/_index.md) d'un projet.

## Lister tous les fichiers sécurisés d'un projet {#list-all-secure-files-for-a-project}

Liste tous les fichiers sécurisés d'un projet spécifié.

```plaintext
GET /projects/:project_id/secure_files
```

Attributs pris en charge :

| Attribut    | Type           | Obligatoire | Description |
|--------------|----------------|----------|-------------|
| `project_id` | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files"
```

Exemple de réponse :

```json
[
    {
        "id": 1,
        "name": "myfile.jks",
        "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac",
        "checksum_algorithm": "sha256",
        "created_at": "2022-02-22T22:22:22.222Z",
        "expires_at": null,
        "metadata": null
    },
    {
        "id": 2,
        "name": "myfile.cer",
        "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aa2",
        "checksum_algorithm": "sha256",
        "created_at": "2022-02-22T22:22:22.222Z",
        "expires_at": "2023-09-21T14:55:59.000Z",
        "metadata": {
            "id":"75949910542696343243264405377658443914",
            "issuer": {
                "C":"US",
                "O":"Apple Inc.",
                "CN":"Apple Worldwide Developer Relations Certification Authority",
                "OU":"G3"
            },
            "subject": {
                "C":"US",
                "O":"Organization Name",
                "CN":"Apple Distribution: Organization Name (ABC123XYZ)",
                "OU":"ABC123XYZ",
                "UID":"ABC123XYZ"
            },
            "expires_at":"2023-09-21T14:55:59.000Z"
        }
    }
]
```

## Récupérer les détails d'un fichier sécurisé {#retrieve-details-of-a-secure-file}

Récupère les détails d'un fichier sécurisé spécifié dans un projet.

```plaintext
GET /projects/:project_id/secure_files/:id
```

Attributs pris en charge :

| Attribut    | Type           | Obligatoire | Description |
|--------------|----------------|----------|-------------|
| `id`         | entier        | Oui      | L'ID d'un fichier sécurisé. |
| `project_id` | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files/1"
```

Exemple de réponse :

```json
{
    "id": 1,
    "name": "myfile.jks",
    "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac",
    "checksum_algorithm": "sha256",
    "created_at": "2022-02-22T22:22:22.222Z",
    "expires_at": null,
    "metadata": null
}
```

## Créer un fichier sécurisé {#create-a-secure-file}

Crée un fichier sécurisé dans un projet spécifié.

```plaintext
POST /projects/:project_id/secure_files
```

Attributs pris en charge :

| Attribut       | Type           | Obligatoire | Description |
|-----------------|----------------|----------|-------------|
| `file`          | fichier           | Oui      | Le fichier à téléverser (limite de 5 Mo). |
| `name`          | string         | Oui      | Le nom du fichier à téléverser. Le nom de fichier doit être unique dans le projet. |
| `project_id`    | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files" \
  --form "name=myfile.jks" \
  --form "file=@/path/to/file/myfile.jks"
```

Exemple de réponse :

```json
{
    "id": 1,
    "name": "myfile.jks",
    "checksum": "16630b189ab34b2e3504f4758e1054d2e478deda510b2b08cc0ef38d12e80aac",
    "checksum_algorithm": "sha256",
    "created_at": "2022-02-22T22:22:22.222Z",
    "expires_at": null,
    "metadata": null
}
```

## Télécharger un fichier sécurisé {#download-a-secure-file}

Télécharge le contenu d'un fichier sécurisé spécifié dans un projet.

```plaintext
GET /projects/:project_id/secure_files/:id/download
```

Attributs pris en charge :

| Attribut    | Type           | Obligatoire | Description |
|--------------|----------------|----------|-------------|
| `id`         | entier        | Oui      | L'ID d'un fichier sécurisé. |
| `project_id` | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files/1/download" \
  --output myfile.jks
```

## Supprimer un fichier sécurisé {#delete-a-secure-file}

Supprime un fichier sécurisé spécifié d'un projet.

```plaintext
DELETE /projects/:project_id/secure_files/:id
```

Attributs pris en charge :

| Attribut    | Type           | Obligatoire | Description |
|--------------|----------------|----------|-------------|
| `id`         | entier        | Oui      | L'ID d'un fichier sécurisé. |
| `project_id` | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/secure_files/1"
```
