---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation de l'API REST pour la gestion des fichiers de dépôt Git dans GitLab."
title: API des fichiers de dépôt
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les [fichiers de dépôt](../user/project/repository/_index.md). Vous pouvez également [configurer les limites de débit](../administration/settings/files_api_rate_limits.md) pour cette API.

## Portées disponibles pour les jetons d'accès personnels {#available-scopes-for-personal-access-tokens}

Les [jetons d'accès personnels](../user/profile/personal_access_tokens.md) prennent en charge ces portées :

| Portée             | Description |
|-------------------|-------------|
| `api`             | Autorise l'accès en lecture-écriture aux fichiers du dépôt. |
| `read_api`        | Autorise l'accès en lecture aux fichiers du dépôt. |
| `read_repository` | Autorise l'accès en lecture aux fichiers du dépôt. |

## Récupérer un fichier depuis un dépôt {#retrieve-a-file-from-a-repository}

Récupère des informations sur un fichier spécifié dans un dépôt. Cela inclut des informations telles que le nom, la taille et le contenu du fichier. Le contenu du fichier est encodé en Base64. Vous pouvez accéder à cet endpoint sans authentification si le dépôt est accessible publiquement.

Pour les blobs de plus de 10 Mo, cet endpoint a une limite de débit de 5 requêtes par minute.

```plaintext
GET /projects/:id/repository/files/:file_path
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
|-------------|-------------------|----------|-------------|
| `file_path` | string            | Oui      | Chemin complet encodé dans l'URL vers le fichier, tel que `lib%2Fclass%2Erb`. |
| `id`        | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL](rest/_index.md#namespaced-paths) du projet. |
| `ref`       | string            | Oui      | Nom de la branche, du tag ou du commit. Utilisez `HEAD` pour utiliser automatiquement la branche par défaut. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut          | Type    | Description |
|--------------------|---------|-------------|
| `blob_id`          | string  | SHA du blob.   |
| `commit_id`        | string  | SHA du commit pour le fichier. |
| `content`          | string  | Contenu du fichier encodé en Base64. |
| `content_sha256`   | string  | Hachage SHA256 du contenu du fichier. |
| `encoding`         | string  | Encodage utilisé pour le contenu du fichier. |
| `execute_filemode` | boolean | Si `true`, le flag d'exécution est défini sur le fichier. |
| `file_name`        | string  | Nom du fichier. |
| `file_path`        | string  | Chemin complet vers le fichier. |
| `last_commit_id`   | string  | SHA du dernier commit ayant modifié ce fichier. |
| `ref`              | string  | Nom de la branche, du tag ou du commit utilisé. |
| `size`             | entier | Taille du fichier en octets. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fmodels%2Fkey%2Erb?ref=main"
```

Si vous ne connaissez pas le nom de la branche ou souhaitez utiliser la branche par défaut, vous pouvez utiliser `HEAD` comme valeur de `ref`. Par exemple :

```shell
curl --header "PRIVATE-TOKEN: " \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fmodels%2Fkey%2Erb?ref=HEAD"
```

Exemple de réponse :

```json
{
  "file_name": "key.rb",
  "file_path": "app/models/key.rb",
  "size": 1476,
  "encoding": "base64",
  "content": "IyA9PSBTY2hlbWEgSW5mb3...",
  "content_sha256": "4c294617b60715c1d218e61164a3abd4808a4284cbc30e6728a01ad9aada4481",
  "ref": "main",
  "blob_id": "79f7bbd25901e8334750839545a9bd021f0e4c83",
  "commit_id": "d5a3ff139356ce33e37e73add446f16869741b50",
  "last_commit_id": "570e7b2abdd848b95f2f578043fc23bd6f6fd24d",
  "execute_filemode": false
}
```

### Obtenir uniquement les métadonnées du fichier {#get-file-metadata-only}

Vous pouvez également utiliser `HEAD` pour récupérer uniquement les métadonnées du fichier.

```plaintext
HEAD /projects/:id/repository/files/:file_path
```

```shell
curl --head --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fmodels%2Fkey%2Erb?ref=main"
```

Exemple de réponse :

```plaintext
HTTP/1.1 200 OK
...
X-Gitlab-Blob-Id: 79f7bbd25901e8334750839545a9bd021f0e4c83
X-Gitlab-Commit-Id: d5a3ff139356ce33e37e73add446f16869741b50
X-Gitlab-Content-Sha256: 4c294617b60715c1d218e61164a3abd4808a4284cbc30e6728a01ad9aada4481
X-Gitlab-Encoding: base64
X-Gitlab-File-Name: key.rb
X-Gitlab-File-Path: app/models/key.rb
X-Gitlab-Last-Commit-Id: 570e7b2abdd848b95f2f578043fc23bd6f6fd24d
X-Gitlab-Ref: main
X-Gitlab-Size: 1476
X-Gitlab-Execute-Filemode: false
...
```

## Récupérer l'historique blame d'un fichier depuis un dépôt {#retrieve-file-blame-history-from-a-repository}

Récupère l'historique blame d'un fichier spécifié dans un dépôt. Chaque plage blame contient des lignes et les informations de commit correspondantes.

```plaintext
GET /projects/:id/repository/files/:file_path/blame
```

Attributs pris en charge :

| Attribut      | Type              | Obligatoire | Description |
|----------------|-------------------|----------|-------------|
| `file_path`    | string            | Oui      | Chemin complet encodé dans l'URL vers le fichier, tel que `lib%2Fclass%2Erb`. |
| `id`           | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `ref`          | string            | Oui      | Nom de la branche, du tag ou du commit. Utilisez `HEAD` pour utiliser automatiquement la branche par défaut. |
| `range`        | hash              | Non       | Plage blame. |
| `range[end]`   | entier           | Non       | Dernière ligne de la plage à blâmer. |
| `range[start]` | entier           | Non       | Première ligne de la plage à blâmer. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut | Type   | Description |
|-----------|--------|-------------|
| `commit`  | objet | Informations de commit pour la plage blame. |
| `lines`   | tableau  | Tableau de lignes pour cette plage blame. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/path%2Fto%2Ffile.rb/blame?ref=main"
```

Exemple de réponse :

```json
[
  {
    "commit": {
      "id": "d42409d56517157c48bf3bd97d3f75974dde19fb",
      "message": "Add feature\n\nalso fix bug\n",
      "parent_ids": [
        "cc6e14f9328fa6d7b5a0d3c30dc2002a3f2a3822"
      ],
      "authored_date": "2015-12-18T08:12:22.000Z",
      "author_name": "John Doe",
      "author_email": "john.doe@example.com",
      "committed_date": "2015-12-18T08:12:22.000Z",
      "committer_name": "John Doe",
      "committer_email": "john.doe@example.com"
    },
    "lines": [
      "require 'fileutils'",
      "require 'open3'",
      ""
    ]
  }
]
```

### Obtenir uniquement les métadonnées blame du fichier {#get-file-blame-metadata-only}

Utilisez la méthode `HEAD` pour renvoyer uniquement les métadonnées blame du fichier.

```plaintext
HEAD /projects/:id/repository/files/:file_path/blame
```

```shell
curl --head --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/path%2Fto%2Ffile.rb/blame?ref=main"
```

Exemple de réponse :

```plaintext
HTTP/1.1 200 OK
...
X-Gitlab-Blob-Id: 79f7bbd25901e8334750839545a9bd021f0e4c83
X-Gitlab-Commit-Id: d5a3ff139356ce33e37e73add446f16869741b50
X-Gitlab-Content-Sha256: 4c294617b60715c1d218e61164a3abd4808a4284cbc30e6728a01ad9aada4481
X-Gitlab-Encoding: base64
X-Gitlab-File-Name: file.rb
X-Gitlab-File-Path: path/to/file.rb
X-Gitlab-Last-Commit-Id: 570e7b2abdd848b95f2f578043fc23bd6f6fd24d
X-Gitlab-Ref: main
X-Gitlab-Size: 1476
X-Gitlab-Execute-Filemode: false
...
```

### Demander une plage blame {#request-a-blame-range}

Pour demander une plage blame, spécifiez les paramètres `range[start]` et `range[end]` avec les numéros de ligne de début et de fin du fichier.

```shell
curl --head --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/path%2Fto%2Ffile.rb/blame?ref=main&range[start]=1&range[end]=2"
```

Exemple de réponse :

```json
[
  {
    "commit": {
      "id": "d42409d56517157c48bf3bd97d3f75974dde19fb",
      "message": "Add feature\n\nalso fix bug\n",
      "parent_ids": [
        "cc6e14f9328fa6d7b5a0d3c30dc2002a3f2a3822"
      ],
      "authored_date": "2015-12-18T08:12:22.000Z",
      "author_name": "John Doe",
      "author_email": "john.doe@example.com",
      "committed_date": "2015-12-18T08:12:22.000Z",
      "committer_name": "John Doe",
      "committer_email": "john.doe@example.com"
    },
    "lines": [
      "require 'fileutils'",
      "require 'open3'"
    ]
  }
]
```

## Récupérer un fichier brut depuis un dépôt {#retrieve-a-raw-file-from-a-repository}

Récupère le contenu brut d'un fichier spécifié dans un dépôt.

```plaintext
GET /projects/:id/repository/files/:file_path/raw
```

Attributs pris en charge :

| Attribut   | Type              | Obligatoire | Description |
|-------------|-------------------|----------|-------------|
| `file_path` | string            | Oui      | Chemin complet encodé dans l'URL vers le fichier, tel que `lib%2Fclass%2Erb`. |
| `id`        | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `lfs`       | boolean           | Non       | Si `true`, détermine si la réponse doit contenir le contenu du fichier Git LFS plutôt que le pointeur. Ignoré si le fichier n'est pas suivi par Git LFS. Par défaut `false`. |
| `ref`       | string            | Non       | Nom de la branche, du tag ou du commit. La valeur par défaut est `HEAD` du projet. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fmodels%2Fkey%2Erb/raw?ref=main"
```

> [!note]
> Semblable à [la récupération d'un fichier depuis un dépôt](repository_files.md#retrieve-a-file-from-a-repository), vous pouvez utiliser `HEAD` pour obtenir uniquement les métadonnées du fichier.

## Créer un fichier dans un dépôt {#create-a-file-in-a-repository}

{{< history >}}

- Limites de taille de requête et de débit introduites dans GitLab 18.7.

{{< /history >}}

Crée un fichier dans un dépôt spécifié. Pour créer plusieurs fichiers avec une seule requête, consultez l'[API commits](commits.md#create-a-commit).

```plaintext
POST /projects/:id/repository/files/:file_path
```

> [!note]
> Cet endpoint est soumis aux [limites de taille de requête et de débit](../administration/instance_limits.md#commits-and-files-api-limits). Les requêtes dépassant la limite par défaut de 300 Mo sont rejetées. Les requêtes supérieures à 20 Mo sont soumises à une limite de débit de 3 requêtes toutes les 30 secondes.

Attributs pris en charge :

| Attribut          | Type              | Obligatoire | Description |
|--------------------|-------------------|----------|-------------|
| `branch`           | string            | Oui      | Nom de la branche à créer. Le commit est ajouté à cette branche. |
| `commit_message`   | string            | Oui      | Message de commit. |
| `content`          | string            | Oui      | Le contenu du fichier. |
| `file_path`        | string            | Oui      | Chemin complet encodé dans l'URL vers le fichier. Par exemple : `lib%2Fclass%2Erb`. |
| `id`               | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `author_email`     | string            | Non       | Adresse e-mail de l'auteur du commit. |
| `author_name`      | string            | Non       | Nom de l'auteur du commit. |
| `encoding`         | string            | Non       | Changer l'encodage en `base64`. La valeur par défaut est `text`. |
| `execute_filemode` | boolean           | Non       | Si `true`, active le flag `execute` sur le fichier. Si `false`, désactive le flag `execute` sur le fichier. |
| `start_branch`     | string            | Non       | Nom de la branche de base à partir de laquelle créer la branche. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut   | Type   | Description |
|-------------|--------|-------------|
| `branch`    | string | Nom de la branche dans laquelle le fichier a été créé. |
| `file_path` | string | Chemin vers le fichier créé. |

```shell
curl --request POST \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header "Content-Type: application/json" \
  --data '{"branch": "main", "author_email": "author@example.com", "author_name": "Firstname Lastname",
            "content": "some content", "commit_message": "create a new file"}' \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fproject%2Erb"
```

Exemple de réponse :

```json
{
  "file_path": "app/project.rb",
  "branch": "main"
}
```

## Mettre à jour un fichier dans un dépôt {#update-a-file-in-a-repository}

{{< history >}}

- Limites de taille de requête et de débit introduites dans GitLab 18.7.

{{< /history >}}

Met à jour un fichier spécifié dans un dépôt. Pour mettre à jour plusieurs fichiers avec une seule requête, consultez l'[API commits](commits.md#create-a-commit).

```plaintext
PUT /projects/:id/repository/files/:file_path
```

> [!note]
> Cet endpoint est soumis aux [limites de taille de requête et de débit](../administration/instance_limits.md#commits-and-files-api-limits). Les requêtes dépassant la limite par défaut de 300 Mo sont rejetées. Les requêtes supérieures à 20 Mo sont soumises à une limite de débit de 3 requêtes toutes les 30 secondes.

Attributs pris en charge :

| Attribut        | Type              | Obligatoire | Description |
| ---------------- | ----------------- | -------- | ----------- |
| `branch`         | string            | Oui      | Nom de la branche à créer. Le commit est ajouté à cette branche. |
| `commit_message` | string            | Oui      | Message de commit. |
| `content`        | string            | Oui      | Contenu du fichier. |
| `file_path`      | string            | Oui      | Chemin complet encodé dans l'URL vers le fichier. Par exemple : `lib%2Fclass%2Erb`. |
| `id`             | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths)  |
| `author_email`   | string            | Non       | Adresse e-mail de l'auteur du commit. |
| `author_name`    | string            | Non       | Nom de l'auteur du commit. |
| `encoding`       | string            | Non       | Changer l'encodage en `base64`. La valeur par défaut est `text`. |
| `execute_filemode` | boolean         | Non       | Si `true`, active le flag `execute` sur le fichier. Si `false`, désactive le flag `execute` sur le fichier. |
| `last_commit_id` | string            | Non       | Dernier ID de commit de fichier connu. |
| `start_branch`   | string            | Non       | Nom de la branche de base à partir de laquelle créer la branche. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut   | Type   | Description |
|-------------|--------|-------------|
| `branch`    | string | Nom de la branche dans laquelle le fichier a été mis à jour. |
| `file_path` | string | Chemin vers le fichier mis à jour. |

```shell
curl --request PUT \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header "Content-Type: application/json" \
  --data '{"branch": "main", "author_email": "author@example.com", "author_name": "Firstname Lastname",
       "content": "some content", "commit_message": "update file"}' \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fproject%2Erb"
```

Exemple de réponse :

```json
{
  "file_path": "app/project.rb",
  "branch": "main"
}
```

Si le commit échoue pour une raison quelconque, l'API renvoie une erreur `400 Bad Request` avec un message d'erreur non spécifique. Les causes possibles d'un commit échoué incluent :

- Le `file_path` contenait `/../` (tentative de traversée de répertoire).
- Le commit était vide : le nouveau contenu du fichier était identique au contenu actuel du fichier.
- Quelqu'un a mis à jour la branche avec `git push` pendant que la modification du fichier était en cours.

[GitLab Shell](https://gitlab.com/gitlab-org/gitlab-shell/) dispose d'un code de retour booléen, ce qui empêche GitLab de spécifier l'erreur.

## Supprimer un fichier dans un dépôt {#delete-a-file-in-a-repository}

Supprime un fichier spécifié dans un dépôt. Pour supprimer plusieurs fichiers avec une seule requête, consultez l'[API commits](commits.md#create-a-commit).

```plaintext
DELETE /projects/:id/repository/files/:file_path
```

Attributs pris en charge :

| Attribut        | Type              | Obligatoire | Description |
|------------------|-------------------|----------|-------------|
| `branch`         | string            | Oui      | Nom de la branche à créer. Le commit est ajouté à cette branche. |
| `commit_message` | string            | Oui      | Message de commit. |
| `file_path`      | string            | Oui      | Chemin complet encodé dans l'URL vers le fichier. Par exemple : `lib%2Fclass%2Erb`. |
| `id`             | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `author_email`   | string            | Non       | Adresse e-mail de l'auteur du commit. |
| `author_name`    | string            | Non       | Nom de l'auteur du commit. |
| `last_commit_id` | string            | Non       | Dernier ID de commit de fichier connu. |
| `start_branch`   | string            | Non       | Nom de la branche de base à partir de laquelle créer la branche. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes).

```shell
curl --request DELETE \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header "Content-Type: application/json" \
  --data '{"branch": "main", "author_email": "author@example.com", "author_name": "Firstname Lastname",
       "commit_message": "delete file"}' \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/files/app%2Fproject%2Erb"
```
