---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: "Documentation de l'API REST pour les étiquettes Git dans GitLab."
title: API Tags
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API REST pour gérer les [étiquettes Git](../user/project/repository/tags/_index.md). Cette API REST retourne également les informations de signature X.509 des étiquettes signées.

## Lister toutes les étiquettes du dépôt du projet {#list-all-project-repository-tags}

{{< history >}}

- L'attribut de réponse `created_at` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/451011) dans GitLab 16.11.

{{< /history >}}

Liste toutes les étiquettes du dépôt d'un projet, triées par date et heure de mise à jour en ordre décroissant.

> [!note]
> Si le dépôt est accessible publiquement, l'authentification (`--header "PRIVATE-TOKEN: <your_access_token>"`) n'est pas requise.

```plaintext
GET /projects/:id/repository/tags
```

Attributs pris en charge :

| Attribut    | Type              | Obligatoire | Description |
|--------------|-------------------|----------|-------------|
| `id`         | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL](rest/_index.md#namespaced-paths) du projet. |
| `order_by`   | string            | Non       | Retourner les étiquettes triées par `name`, `updated` ou `version`. `version` trie par numéro de version sémantique. La valeur par défaut est `updated`. |
| `page`       | entier           | Non       | Numéro de page actuel pour la pagination. La valeur par défaut est `1`. |
| `page_token` | string            | Non       | Nom de l'étiquette à partir de laquelle commencer la pagination. Utilisé pour la pagination par jeu de clés. |
| `search`     | string            | Non       | Retourner une liste d'étiquettes correspondant aux critères de recherche. Vous pouvez utiliser `^term` et `term$` pour trouver les étiquettes qui commencent et se terminent par `term`. Aucune autre expression régulière n'est prise en charge. |
| `sort`       | string            | Non       | Retourner les étiquettes triées dans l'ordre `asc` ou `desc`. La valeur par défaut est `desc`. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                | Type    | Description |
|--------------------------|---------|-------------|
| `commit`                 | objet  | Informations de commit associées à l'étiquette. |
| `commit.author_email`    | string  | Adresse e-mail de l'auteur du commit. |
| `commit.author_name`     | string  | Nom de l'auteur du commit. |
| `commit.authored_date`   | string  | Date à laquelle le commit a été rédigé au format ISO 8601. |
| `commit.committed_date`  | string  | Date à laquelle le commit a été soumis au format ISO 8601. |
| `commit.committer_email` | string  | Adresse e-mail du validateur. |
| `commit.committer_name`  | string  | Nom du validateur. |
| `commit.created_at`      | string  | Date à laquelle le commit a été créé au format ISO 8601. |
| `commit.id`              | string  | SHA complet du commit. |
| `commit.message`         | string  | Message de commit. |
| `commit.parent_ids`      | tableau   | Tableau des SHA des commits parents. |
| `commit.short_id`        | string  | SHA abrégé du commit. |
| `commit.title`           | string  | Titre du commit. |
| `created_at`             | string  | Date à laquelle l'étiquette a été créée au format ISO 8601. |
| `message`                | string  | Message de l'étiquette. |
| `name`                   | string  | Nom de l'étiquette. |
| `protected`              | boolean | Si `true`, l'étiquette est protégée. |
| `release`                | objet  | Informations de release associées à l'étiquette. |
| `release.description`    | string  | Description de la release. |
| `release.tag_name`       | string  | Nom d'étiquette de la release. |
| `target`                 | string  | SHA vers lequel pointe l'étiquette. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/5/repository/tags"
```

Exemple de réponse :

```json
[
  {
    "commit": {
      "id": "2695effb5807a22ff3d138d593fd856244e155e7",
      "short_id": "2695effb",
      "title": "Initial commit",
      "created_at": "2017-07-26T11:08:53.000+02:00",
      "parent_ids": [
        "2a4b78934375d7f53875269ffd4f45fd83a84ebe"
      ],
      "message": "Initial commit",
      "author_name": "John Smith",
      "author_email": "john@example.com",
      "authored_date": "2012-05-28T04:42:42-07:00",
      "committer_name": "Jack Smith",
      "committer_email": "jack@example.com",
      "committed_date": "2012-05-28T04:42:42-07:00"
    },
    "release": {
      "tag_name": "1.0.0",
      "description": "Amazing release. Wow"
    },
    "name": "v1.0.0",
    "target": "2695effb5807a22ff3d138d593fd856244e155e7",
    "message": null,
    "protected": true,
    "created_at": "2017-07-26T11:08:53.000+02:00"
  }
]
```

## Récupérer une seule étiquette du dépôt {#retrieve-a-single-repository-tag}

{{< history >}}

- L'attribut de réponse `created_at` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/451011) dans GitLab 16.11.

{{< /history >}}

Récupère une étiquette du dépôt avec le nom spécifié. Cet endpoint est accessible sans authentification si le dépôt est accessible publiquement.

```plaintext
GET /projects/:id/repository/tags/:tag_name
```

Attributs pris en charge :

| Attribut  | Type              | Obligatoire | Description |
|------------|-------------------|----------|-------------|
| `id`       | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `tag_name` | string            | Oui      | Nom d'une étiquette. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                | Type    | Description |
|--------------------------|---------|-------------|
| `commit`                 | objet  | Informations de commit associées à l'étiquette. |
| `commit.author_email`    | string  | Adresse e-mail de l'auteur du commit. |
| `commit.author_name`     | string  | Nom de l'auteur du commit. |
| `commit.authored_date`   | string  | Date à laquelle le commit a été rédigé au format ISO 8601. |
| `commit.committed_date`  | string  | Date à laquelle le commit a été soumis au format ISO 8601. |
| `commit.committer_email` | string  | Adresse e-mail du validateur. |
| `commit.committer_name`  | string  | Nom du validateur. |
| `commit.created_at`      | string  | Date à laquelle le commit a été créé au format ISO 8601. |
| `commit.id`              | string  | SHA complet du commit. |
| `commit.message`         | string  | Message de commit. |
| `commit.parent_ids`      | tableau   | Tableau des SHA des commits parents. |
| `commit.short_id`        | string  | SHA abrégé du commit. |
| `commit.title`           | string  | Titre du commit. |
| `created_at`             | string  | Date à laquelle l'étiquette a été créée au format ISO 8601. |
| `message`                | string  | Message de l'étiquette. |
| `name`                   | string  | Nom de l'étiquette. |
| `protected`              | boolean | Si `true`, l'étiquette est protégée. |
| `release`                | objet  | Informations de release associées à l'étiquette. |
| `target`                 | string  | SHA vers lequel pointe l'étiquette. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/tags/v1.0.0"
```

Exemple de réponse :

```json
{
  "name": "v5.0.0",
  "message": null,
  "target": "60a8ff033665e1207714d6670fcd7b65304ec02f",
  "commit": {
    "id": "60a8ff033665e1207714d6670fcd7b65304ec02f",
    "short_id": "60a8ff03",
    "title": "Initial commit",
    "created_at": "2017-07-26T11:08:53.000+02:00",
    "parent_ids": [
      "f61c062ff8bcbdb00e0a1b3317a91aed6ceee06b"
    ],
    "message": "v5.0.0\n",
    "author_name": "Arthur Verschaeve",
    "author_email": "contact@arthurverschaeve.be",
    "authored_date": "2015-02-01T21:56:31.000+01:00",
    "committer_name": "Arthur Verschaeve",
    "committer_email": "contact@arthurverschaeve.be",
    "committed_date": "2015-02-01T21:56:31.000+01:00"
  },
  "release": null,
  "protected": false,
  "created_at": "2017-07-26T11:08:53.000+02:00"
}
```

## Créer une nouvelle étiquette {#create-a-new-tag}

{{< history >}}

- L'attribut de réponse `created_at` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/451011) dans GitLab 16.11.

{{< /history >}}

Crée une nouvelle étiquette dans le dépôt pointant vers la référence fournie.

```plaintext
POST /projects/:id/repository/tags
```

Attributs pris en charge :

| Attribut  | Type              | Obligatoire | Description |
|------------|-------------------|----------|-------------|
| `id`       | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `ref`      | string            | Oui      | Créer une étiquette à partir d'un SHA de commit, d'un autre nom d'étiquette ou d'un nom de branche. |
| `tag_name` | string            | Oui      | Nom d'une étiquette. |
| `message`  | string            | Non       | Créer une étiquette annotée. |

En cas de succès, renvoie [`201 Created`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                | Type    | Description |
|--------------------------|---------|-------------|
| `commit`                 | objet  | Informations de commit associées à l'étiquette. |
| `commit.author_email`    | string  | Adresse e-mail de l'auteur du commit. |
| `commit.author_name`     | string  | Nom de l'auteur du commit. |
| `commit.authored_date`   | string  | Date à laquelle le commit a été rédigé au format ISO 8601. |
| `commit.committed_date`  | string  | Date à laquelle le commit a été soumis au format ISO 8601. |
| `commit.committer_email` | string  | Adresse e-mail du validateur. |
| `commit.committer_name`  | string  | Nom du validateur. |
| `commit.created_at`      | string  | Date à laquelle le commit a été créé au format ISO 8601. |
| `commit.id`              | string  | SHA complet du commit. |
| `commit.message`         | string  | Message de commit. |
| `commit.parent_ids`      | tableau   | Tableau des SHA des commits parents. |
| `commit.short_id`        | string  | SHA abrégé du commit. |
| `commit.title`           | string  | Titre du commit. |
| `created_at`             | string  | Date à laquelle l'étiquette a été créée au format ISO 8601. |
| `message`                | string  | Message de l'étiquette. |
| `name`                   | string  | Nom de l'étiquette. |
| `protected`              | boolean | Si `true`, l'étiquette est protégée. |
| `release`                | objet  | Informations de release associées à l'étiquette. |
| `target`                 | string  | SHA vers lequel pointe l'étiquette. |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/tags?tag_name=test&ref=main"
```

Exemple de réponse :

```json
{
  "commit": {
    "id": "2695effb5807a22ff3d138d593fd856244e155e7",
    "short_id": "2695effb",
    "title": "Initial commit",
    "created_at": "2017-07-26T11:08:53.000+02:00",
    "parent_ids": [
      "2a4b78934375d7f53875269ffd4f45fd83a84ebe"
    ],
    "message": "Initial commit",
    "author_name": "John Smith",
    "author_email": "john@example.com",
    "authored_date": "2012-05-28T04:42:42-07:00",
    "committer_name": "Jack Smith",
    "committer_email": "jack@example.com",
    "committed_date": "2012-05-28T04:42:42-07:00"
  },
  "release": null,
  "name": "v1.0.0",
  "target": "2695effb5807a22ff3d138d593fd856244e155e7",
  "message": null,
  "protected": false,
  "created_at": null
}
```

Le type d'étiquette créée détermine le contenu de `created_at`, `target` et `message` :

- Pour les étiquettes annotées :
  - `created_at` contient l'horodatage de la création de l'étiquette.
  - `message` contient l'annotation.
  - `target` contient l'ID de l'objet étiquette.
- Pour les étiquettes légères :
  - `created_at` est null.
  - `message` est null.
  - `target` contient l'ID du commit.

Les erreurs retournent le code de statut `405` avec un message d'erreur explicatif.

## Supprimer une étiquette {#delete-a-tag}

Supprime une étiquette du dépôt avec le nom spécifié.

```plaintext
DELETE /projects/:id/repository/tags/:tag_name
```

Attributs pris en charge :

| Attribut  | Type              | Obligatoire | Description |
|------------|-------------------|----------|-------------|
| `id`       | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `tag_name` | string            | Oui      | Nom d'une étiquette. |

## Récupérer la signature X.509 d'une étiquette {#retrieve-x509-signature-of-a-tag}

Récupère la [signature X.509 d'une étiquette](../user/project/repository/signed_commits/x509.md), si elle est signée. Les étiquettes non signées retournent une réponse `404 Not Found`.

```plaintext
GET /projects/:id/repository/tags/:tag_name/signature
```

Attributs pris en charge :

| Attribut  | Type              | Obligatoire | Description |
|------------|-------------------|----------|-------------|
| `id`       | entier ou chaîne | Oui      | ID ou [chemin encodé dans l'URL du projet](rest/_index.md#namespaced-paths). |
| `tag_name` | string            | Oui      | Nom d'une étiquette. |

En cas de succès, renvoie [`200 OK`](rest/troubleshooting.md#status-codes) et les attributs de réponse suivants :

| Attribut                                             | Type    | Description |
|-------------------------------------------------------|---------|-------------|
| `signature_type`                                      | string  | Type de signature (`X509`). |
| `verification_status`                                 | string  | Statut de vérification de la signature. |
| `x509_certificate`                                    | objet  | Informations du certificat X.509. |
| `x509_certificate.certificate_status`                 | string  | Statut du certificat. |
| `x509_certificate.email`                              | string  | Adresse e-mail du certificat. |
| `x509_certificate.id`                                 | entier | ID du certificat. |
| `x509_certificate.serial_number`                      | entier | Numéro de série du certificat. |
| `x509_certificate.subject`                            | string  | Sujet du certificat. |
| `x509_certificate.subject_key_identifier`             | string  | Identifiant de clé du sujet du certificat. |
| `x509_certificate.x509_issuer`                        | objet  | Informations de l'émetteur du certificat. |
| `x509_certificate.x509_issuer.crl_url`                | string  | URL de la liste de révocation de certificats. |
| `x509_certificate.x509_issuer.id`                     | entier | ID de l'émetteur. |
| `x509_certificate.x509_issuer.subject`                | string  | Sujet de l'émetteur. |
| `x509_certificate.x509_issuer.subject_key_identifier` | string  | Identifiant de clé du sujet de l'émetteur. |

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/repository/tags/v1.1.1/signature"
```

Exemple de réponse si l'étiquette est signée en X.509 :

```json
{
  "signature_type": "X509",
  "verification_status": "unverified",
  "x509_certificate": {
    "id": 1,
    "subject": "CN=gitlab@example.org,OU=Example,O=World",
    "subject_key_identifier": "BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC:BC",
    "email": "gitlab@example.org",
    "serial_number": 278969561018901340486471282831158785578,
    "certificate_status": "good",
    "x509_issuer": {
      "id": 1,
      "subject": "CN=PKI,OU=Example,O=World",
      "subject_key_identifier": "AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB:AB",
      "crl_url": "http://example.com/pki.crl"
    }
  }
}
```

Exemple de réponse si l'étiquette n'est pas signée :

```json
{
  "message": "404 GPG Signature Not Found"
}
```
