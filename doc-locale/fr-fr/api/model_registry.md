---
stage: Deploy
group: MLOps
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API du registre de modèles
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec le [registre de modèles](../user/project/ml/model_registry/_index.md) de machine learning.

L'attribut `:model_version_id` dans chaque endpoint accepte soit un ID de version de modèle, soit un ID d'exécution de candidat. Pour plus d'informations, voir [ID de version de modèle et de candidat](#model-version-and-candidate-ids).

## Télécharger un fichier de package de modèle de machine learning {#download-a-machine-learning-model-package-file}

Télécharge un fichier spécifié depuis un package de modèle de machine learning.

```plaintext
GET /api/v4/projects/:id/packages/ml_models/:model_version_id/files/(*path/):file_name
```

Attributs pris en charge :

| Attribut          | Type              | Obligatoire | Description |
|--------------------|-------------------|----------|-------------|
| `id`               | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `model_version_id` | entier ou chaîne | Oui      | L'ID de version du modèle ou l'ID d'exécution du candidat. Voir [ID de version de modèle et de candidat](#model-version-and-candidate-ids). |
| `file_name`        | string            | Oui      | Le nom de fichier. |
| `path`             | string            | Non       | Le chemin du répertoire pour le fichier. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) ainsi que le contenu du fichier.

Exemple de requête :

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/foo.txt"
```

Exemple de requête avec un chemin de répertoire :

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/my_dir/foo.txt"
```

## Envoyer un fichier de package de modèle {#upload-a-model-package-file}

Envoie un fichier vers un package de modèle de machine learning.

### Autoriser l'envoi {#authorize-the-upload}

Autorise l'envoi d'un fichier vers un package de modèle de machine learning.

```plaintext
PUT /api/v4/projects/:id/packages/ml_models/:model_version_id/files/(*path/):file_name/authorize
```

Attributs pris en charge :

| Attribut          | Type              | Obligatoire | Description |
|--------------------|-------------------|----------|-------------|
| `id`               | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `model_version_id` | entier ou chaîne | Oui      | L'ID de version du modèle ou l'ID d'exécution du candidat. Voir [ID de version de modèle et de candidat](#model-version-and-candidate-ids). |
| `file_name`        | string            | Oui      | Le nom de fichier. |
| `path`             | string            | Non       | Le chemin du répertoire pour le fichier. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request PUT \
  --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/model.pkl/authorize"
```

### Envoyer le fichier {#send-the-file}

Envoie le fichier vers un package de modèle de machine learning.

```plaintext
PUT /api/v4/projects/:id/packages/ml_models/:model_version_id/files/(*path/):file_name
```

Attributs pris en charge :

| Attribut          | Type              | Obligatoire | Description |
|--------------------|-------------------|----------|-------------|
| `id`               | entier ou chaîne | Oui      | L'ID ou le [chemin encodé en URL du projet](rest/_index.md#namespaced-paths). |
| `model_version_id` | entier ou chaîne | Oui      | L'ID de version du modèle ou l'ID d'exécution du candidat. Voir [ID de version de modèle et de candidat](#model-version-and-candidate-ids). |
| `file_name`        | string            | Oui      | Le nom de fichier. |
| `path`             | string            | Non       | Le chemin du répertoire pour le fichier. |
| `file`             | fichier              | Oui      | Le fichier à envoyer. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes).

Exemple de requête :

```shell
curl --request PUT \
  --header "Authorization: Bearer <your_access_token>" \
  --form "file=@model.pkl" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/model.pkl"
```

Exemple de requête avec un chemin de répertoire :

```shell
curl --request PUT \
  --header "Authorization: Bearer <your_access_token>" \
  --form "file=@model.pkl" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/2/files/my_dir/model.pkl"
```

## ID de version de modèle et de candidat {#model-version-and-candidate-ids}

L'attribut `:model_version_id` accepte soit un ID de version de modèle, soit un ID d'exécution de candidat.

Pour trouver l'ID de version du modèle, vérifiez l'URL de la page de version du modèle. Par exemple, dans `https://gitlab.example.com/my-namespace/my-project/-/ml/models/1/versions/5`, l'ID de version du modèle est `5`.

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/5/files/model.pkl"
```

Pour utiliser un ID d'exécution de candidat, faites précéder l'ID interne du candidat de `candidate:`. Par exemple, dans `https://gitlab.example.com/my-namespace/my-project/-/ml/candidates/5`, la valeur pour `:model_version_id` est `candidate:5`.

```shell
curl --header "Authorization: Bearer <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/ml_models/candidate:5/files/model.pkl"
```
