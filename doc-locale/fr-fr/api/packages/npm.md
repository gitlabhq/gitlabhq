---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API npm
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec le [client gestionnaire de paquets npm](../../user/packages/npm_registry/_index.md).

> [!warning]
> Cette API est utilisée par le [client gestionnaire de paquets npm](https://docs.npmjs.com/) et n'est pas destinée à une utilisation manuelle.

Ces endpoints ne respectent pas les méthodes d'authentification standard de l'API. Consultez la [documentation du registre de paquets npm](../../user/packages/npm_registry/_index.md) pour plus d'informations sur les en-têtes et les types de jetons pris en charge. Les méthodes d'authentification non documentées pourront être supprimées à l'avenir.

## Télécharger un paquet {#download-a-package}

Télécharge un paquet npm spécifié pour un projet. Cette URL est fournie par le [point de terminaison de métadonnées](#retrieve-package-metadata).

```plaintext
GET projects/:id/packages/npm/:package_name/-/:file_name
```

| Attribut         | Type   | Obligatoire | Description |
| ----------------- | ------ | -------- | ----------- |
| `id`              | string | oui      | L'ID ou le chemin complet du projet. |
| `package_name`    | string | oui      | Le nom du paquet. |
| `file_name`       | string | oui      | Le nom du fichier du paquet. |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope/my-pkg/-/@my-scope/my-pkg-0.0.1.tgz"
```

Écrire la sortie dans un fichier :

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope/my-pkg/-/@my-scope/my-pkg-0.0.1.tgz" >> @myscope/my-pkg-0.0.1.tgz
```

Ceci écrit le fichier téléchargé dans `@myscope/my-pkg-0.0.1.tgz` dans le répertoire courant.

## Envoyer un fichier de paquet {#upload-a-package-file}

Envoie un paquet pour un projet spécifié.

```plaintext
PUT projects/:id/packages/npm/:package_name
```

| Attribut      | Type   | Obligatoire | Description                         |
|----------------|--------|----------|-------------------------------------|
| `id`           | string | oui      | L'ID ou le chemin complet du projet. |
| `package_name` | string | oui      | Le nom du paquet.            |
| `versions`     | string | oui      | Informations sur la version du paquet.        |

```shell
curl --request PUT
     --header "Content-Type: application/json"
     --data @./path/to/metadata/file.json
     --header "Authorization: Bearer <personal_access_token>" \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope%2fmy-pkg"
```

Le contenu du fichier de métadonnées est généré par npm, mais ressemble à ceci :

```json
{
    "_attachments": {
        "@myscope/my-pkg-1.3.7.tgz": {
            "content_type": "application/octet-stream",
            "data": "H4sIAAAAAAAAE+1TQUvDMBjdeb/iI4edZEldV2dPwhARPIjiyXlI26zN1iYhSeeK7L+bNJtednMg4l4OKe+9PF7DF0XzNS0ZVmEfr4wUgxODEJLEMRzjPRJyCYPJNCFRlCTE+dzH1PvJqYscQ2ss1a7KT3PCv8DX/kfwMQRAgjYMpYBuIoIzKtwy6MILG6YNl8Jr0XgyvgpswUyuubJ75TGMDuSaUcsKyDooa1C6De6G8t7GRcG2br4CGxKME3wDR1hmrLexvJKwQLdaS52CkOAFMIrlfMlZsUAwGgHbcgsRcid3fdqade9SFz7u9a1naGsrqX3gHbcPNINDyydWcmN1By+W19x2oU7NcyZMfwn3z/PAqTaruanmUix5+V3UXVKq9yEoRZW1yqQYl9zWNBvnssFUcbyJsdJyxXJrcHQdz8gsTg6PzGChGty3H+6Gvz0BZ5xxxn/FJ1EDRNIACAAA",
            "length": 354
        }
    },
    "_id": "@myscope/my-pkg",
    "description": "Package created by me",
    "dist-tags": {
        "latest": "1.3.7"
    },
    "name": "@myscope/my-pkg",
    "readme": "ERROR: No README data found!",
    "versions": {
        "1.3.7": {
            "_id": "@myscope/my-pkg@1.3.7",
            "_nodeVersion": "12.18.4",
            "_npmVersion": "6.14.6",
            "author": {
                "name": "GitLab package registry Utility"
            },
            "description": "Package created by me",
            "dist": {
                "integrity": "sha512-loy16p+Dtw2S43lBmD3Nye+t+Vwv7Tbhv143UN2mwcjaHJyBfGZdNCTXnma3gJCUSE/AR4FPGWEyCOOTJ+ev9g==",
                "shasum": "4a9dbd94ca6093feda03d909f3d7e6bd89d9d4bf",
                "tarball": "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope/my-pkg/-/@myscope/my-pkg-1.3.7.tgz"
            },
            "keywords": [],
            "license": "ISC",
            "main": "index.js",
            "name": "@myscope/my-pkg",
            "publishConfig": {
                "@myscope:registry": "https://gitlab.example.com/api/v4/projects/1/packages/npm"
            },
            "readme": "ERROR: No README data found!",
            "scripts": {
                "test": "echo \"Error: no test specified\" && exit 1"
            },
            "version": "1.3.7"
        }
    }
}
```

## Préfixe de route {#route-prefix}

Pour les routes restantes, il existe deux ensembles de routes identiques qui effectuent chacun des requêtes dans différentes portées :

- Utilisez le préfixe au niveau de l'instance pour effectuer des requêtes dans la portée de l'ensemble de l'instance.
- Utilisez le préfixe au niveau du projet pour effectuer des requêtes dans la portée d'un seul projet.
- Utilisez le préfixe au niveau du groupe pour effectuer des requêtes dans la portée d'un groupe.

Les exemples de ce document utilisent tous le préfixe au niveau du projet.

### Niveau de l'instance {#instance-level}

```plaintext
/packages/npm
```

### Niveau du projet {#project-level}

```plaintext
/projects/:id/packages/npm
```

| Attribut | Type   | Obligatoire | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | oui      | L'ID du projet ou le chemin complet du projet. |

### Niveau du groupe {#group-level}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/299834) dans GitLab 16.0 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `npm_group_level_endpoints`. Désactivé par défaut.
- [Disponible de manière générale](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121837) dans GitLab 16.1. L'indicateur de fonctionnalité `npm_group_level_endpoints` a été supprimé.

{{< /history >}}

```plaintext
/groups/:id/-/packages/npm
```

| Attribut | Type   | Obligatoire | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | oui      | L'ID du groupe ou le chemin complet du groupe. |

## Récupérer les métadonnées d'un paquet {#retrieve-package-metadata}

Récupère les métadonnées d'un paquet spécifié.

```plaintext
GET <route-prefix>/:package_name
```

| Attribut      | Type   | Obligatoire | Description |
| -------------- | ------ | -------- | ----------- |
| `package_name` | string | oui      | Le nom du paquet. |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope/my-pkg"
```

Exemple de réponse :

```json
{
  "name": "@myscope/my-pkg",
  "versions": {
    "0.0.2": {
      "name": "@myscope/my-pkg",
      "version": "0.0.1",
      "dist": {
        "shasum": "93abb605b1110c0e3cca0a5b805e5cb01ac4ca9b",
        "tarball": "https://gitlab.example.com/api/v4/projects/1/packages/npm/@myscope/my-pkg/-/@myscope/my-pkg-0.0.1.tgz"
      }
    }
  },
  "dist-tags": {
    "latest": "0.0.1"
  }
}
```

Les URL de la réponse ont le même préfixe de route que celui utilisé pour les demander. Si vous les demandez avec la route au niveau de l'instance, les URL retournées contiennent `/api/v4/packages/npm`.

## Dist-Tags {#dist-tags}

### Lister tous les dist-tags {#list-all-dist-tags}

Liste tous les dist-tags pour un paquet spécifié.

```plaintext
GET <route-prefix>/-/package/:package_name/dist-tags
```

| Attribut      | Type   | Obligatoire | Description |
| -------------- | ------ | -------- | ----------- |
| `package_name` | string | oui      | Le nom du paquet. |

```shell
curl --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/-/package/@myscope/my-pkg/dist-tags"
```

Exemple de réponse :

```json
{
  "latest": "2.1.1",
  "stable": "1.0.0"
}
```

Les URL de la réponse ont le même préfixe de route que celui utilisé pour les demander. Si vous les demandez avec la route au niveau de l'instance, les URL retournées contiennent `/api/v4/packages/npm`.

### Créer ou mettre à jour un dist-tag {#create-or-update-a-dist-tag}

Crée ou met à jour un dist-tag spécifié pour un paquet.

```plaintext
PUT <route-prefix>/-/package/:package_name/dist-tags/:tag
```

| Attribut      | Type   | Obligatoire | Description |
| -------------- | ------ | -------- | ----------- |
| `package_name` | string | oui      | Le nom du paquet. |
| `tag`          | string | oui      | Le tag à créer ou à mettre à jour. |
| `version`      | string | oui      | La version à associer au tag. |

```shell
curl --request PUT --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/-/package/@myscope/my-pkg/dist-tags/stable"
```

Cet endpoint répond avec succès avec `204 No Content`.

### Supprimer un dist-tag {#delete-a-dist-tag}

Supprime un dist-tag spécifié pour un paquet.

```plaintext
DELETE <route-prefix>/-/package/:package_name/dist-tags/:tag
```

| Attribut      | Type   | Obligatoire | Description |
| -------------- | ------ | -------- | ----------- |
| `package_name` | string | oui      | Le nom du paquet. |
| `tag`          | string | oui      | Le tag à créer ou à mettre à jour. |

```shell
curl --request DELETE --header "Authorization: Bearer <personal_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/npm/-/package/@myscope/my-pkg/dist-tags/stable"
```

Cet endpoint répond avec succès avec `204 No Content`.
