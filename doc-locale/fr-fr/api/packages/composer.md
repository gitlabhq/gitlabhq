---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Composer
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec le [client gestionnaire de paquets Composer](../../user/packages/composer_repository/_index.md).

> [!warning]
> Cette API est utilisée par le [client gestionnaire de paquets Composer](https://getcomposer.org/) et n'est généralement pas destinée à une utilisation manuelle.

Ces endpoints ne respectent pas les méthodes d'authentification d'API standard. Consultez la [documentation du registre de paquets Composer](../../user/packages/composer_repository/_index.md) pour plus de détails sur les en-têtes et types de jetons pris en charge. Les méthodes d'authentification non documentées pourraient être supprimées à l'avenir.

## Récupérer les modèles d'URL du dépôt {#retrieve-repository-url-templates}

Récupère les modèles d'URL du dépôt pour demander des paquets individuels pour un groupe.

```plaintext
GET group/:id/-/packages/composer/packages
```

| Attribut | Type   | Obligatoire | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | oui      | L'identifiant ou le chemin complet du groupe. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/group/1/-/packages/composer/packages"
```

Exemple de réponse :

```json
{
  "packages": [],
  "metadata-url": "/api/v4/group/1/-/packages/composer/p2/%package%.json",
  "provider-includes": {
    "p/%hash%.json": {
      "sha256": "082df4a5035f8725a12a4a3d2da5e6aaa966d06843d0a5c6d499313810427bd6"
    }
  },
  "providers-url": "/api/v4/group/1/-/packages/composer/%package%$%hash%.json"
}
```

Cet endpoint est utilisé par Composer V1 et V2. Pour voir la réponse spécifique à V2, incluez l'en-tête `User-Agent` de Composer. L'utilisation de Composer V2 est recommandée par rapport à V1.

```shell
curl --user <username>:<personal_access_token> \
     --header "User-Agent: Composer/2" \
     --url "https://gitlab.example.com/api/v4/group/1/-/packages/composer/packages"
```

Exemple de réponse :

```json
{
  "packages": [],
  "metadata-url": "/api/v4/group/1/-/packages/composer/p2/%package%.json"
}
```

## Liste des paquets V1 {#v1-packages-list}

Récupère une liste de paquets dans le dépôt pour un groupe, en fonction du SHA fournisseur V1. L'utilisation de Composer V2 est recommandée par rapport à V1.

```plaintext
GET group/:id/-/packages/composer/p/:sha
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | oui | L'identifiant ou le chemin complet du groupe. |
| `sha`     | string | oui | Le SHA fournisseur, fourni par la [requête de base](#retrieve-repository-url-templates) Composer. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/group/1/-/packages/composer/p/082df4a5035f8725a12a4a3d2da5e6aaa966d06843d0a5c6d499313810427bd6"
```

Exemple de réponse :

```json
{
  "providers": {
    "my-org/my-composer-package": {
      "sha256": "5c873497cdaa82eda35af5de24b789be92dfb6510baf117c42f03899c166b6e7"
    }
  }
}
```

## Récupérer les métadonnées du paquet V1 {#retrieve-v1-package-metadata}

Récupère la liste des versions et des métadonnées d'un paquet spécifié pour un groupe. L'utilisation de Composer V2 est recommandée par rapport à V1.

```plaintext
GET group/:id/-/packages/composer/:package_name$:sha
```

Notez le symbole `$` dans l'URL. Lors de requêtes, vous pourriez avoir besoin de la version encodée en URL du symbole `%24`. Reportez-vous à l'exemple après le tableau :

| Attribut      | Type   | Obligatoire | Description                                                                           |
|----------------|--------|----------|---------------------------------------------------------------------------------------|
| `id`           | string | oui      | L'identifiant ou le chemin complet du groupe.                                                     |
| `package_name` | string | oui      | Le nom du paquet.                                                              |
| `sha`          | string | oui      | Le condensat SHA du paquet, fourni par la [liste des paquets V1](#v1-packages-list). |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/group/1/-/packages/composer/my-org/my-composer-package%245c873497cdaa82eda35af5de24b789be92dfb6510baf117c42f03899c166b6e7"
```

Exemple de réponse :

```json
{
  "packages": {
    "my-org/my-composer-package": {
      "1.0.0": {
        "name": "my-org/my-composer-package",
        "type": "library",
        "license": "GPL-3.0-only",
        "version": "1.0.0",
        "dist": {
          "type": "zip",
          "url": "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=673594f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "reference": "673594f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "shasum": ""
        },
        "source": {
          "type": "git",
          "url": "https://gitlab.example.com/my-org/my-composer-package.git",
          "reference": "673594f85a55fe3c0eb45df7bd2fa9d95a1601ab"
        },
        "uid": 1234567
      },
      "2.0.0": {
        "name": "my-org/my-composer-package",
        "type": "library",
        "license": "GPL-3.0-only",
        "version": "2.0.0",
        "dist": {
          "type": "zip",
          "url": "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=445394f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "reference": "445394f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "shasum": ""
        },
        "source": {
          "type": "git",
          "url": "https://gitlab.example.com/my-org/my-composer-package.git",
          "reference": "445394f85a55fe3c0eb45df7bd2fa9d95a1601ab"
        },
        "uid": 1234567
      }
    }
  }
}
```

## Récupérer les métadonnées du paquet V2 {#retrieve-v2-package-metadata}

Récupère la liste des versions et des métadonnées d'un paquet spécifié pour un groupe.

```plaintext
GET group/:id/-/packages/composer/p2/:package_name
```

| Attribut      | Type   | Obligatoire | Description |
| -------------- | ------ | -------- | ----------- |
| `id`           | string | oui      | L'identifiant ou le chemin complet du groupe. |
| `package_name` | string | oui      | Le nom du paquet. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/group/1/-/packages/composer/p2/my-org/my-composer-package"
```

Exemple de réponse :

```json
{
  "packages": {
    "my-org/my-composer-package": {
      "1.0.0": {
        "name": "my-org/my-composer-package",
        "type": "library",
        "license": "GPL-3.0-only",
        "version": "1.0.0",
        "dist": {
          "type": "zip",
          "url": "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=673594f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "reference": "673594f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "shasum": ""
        },
        "source": {
          "type": "git",
          "url": "https://gitlab.example.com/my-org/my-composer-package.git",
          "reference": "673594f85a55fe3c0eb45df7bd2fa9d95a1601ab"
        },
        "uid": 1234567
      },
      "2.0.0": {
        "name": "my-org/my-composer-package",
        "type": "library",
        "license": "GPL-3.0-only",
        "version": "2.0.0",
        "dist": {
          "type": "zip",
          "url": "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=445394f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "reference": "445394f85a55fe3c0eb45df7bd2fa9d95a1601ab",
          "shasum": ""
        },
        "source": {
          "type": "git",
          "url": "https://gitlab.example.com/my-org/my-composer-package.git",
          "reference": "445394f85a55fe3c0eb45df7bd2fa9d95a1601ab"
        },
        "uid": 1234567
      }
    }
  }
}
```

## Créer un paquet {#create-a-package}

Crée un paquet Composer à partir d'un tag ou d'une branche Git spécifié(e) pour un projet.

```plaintext
POST projects/:id/packages/composer
```

| Attribut | Type   | Obligatoire | Description |
| --------- | ------ | -------- | ----------- |
| `id`      | string | oui      | L'identifiant ou le chemin complet du groupe. |
| `tag`     | string | non       | Le nom du tag à cibler pour le paquet. |
| `branch`  | string | non       | Le nom de la branche à cibler pour le paquet. |

```shell
curl --request POST --user <username>:<personal_access_token> \
     --data tag=v1.0.0 \
     --url "https://gitlab.example.com/api/v4/projects/1/packages/composer"
```

Exemple de réponse :

```json
{
  "message": "201 Created"
}
```

## Télécharger une archive de paquet {#download-a-package-archive}

Télécharge une archive de paquet Composer spécifiée pour un projet. Cette URL est fournie dans la réponse [v1](#retrieve-v1-package-metadata) ou [métadonnées du paquet v2](#retrieve-v2-package-metadata). Une extension de fichier `.zip` doit être présente dans la requête.

```plaintext
GET projects/:id/packages/composer/archives/:package_name
```

| Attribut      | Type   | Obligatoire | Description |
| -------------- | ------ | -------- | ----------- |
| `id`           | string | oui      | L'identifiant ou le chemin complet du groupe. |
| `package_name` | string | oui      | Le nom du paquet. |
| `sha`          | string | oui      | Le SHA cible de la version du paquet demandée. |

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=673594f85a55fe3c0eb45df7bd2fa9d95a1601ab"
```

Écrire la sortie dans un fichier :

```shell
curl --user <username>:<personal_access_token> \
  --url "https://gitlab.example.com/api/v4/projects/1/packages/composer/archives/my-org/my-composer-package.zip?sha=673594f85a55fe3c0eb45df7bd2fa9d95a1601ab" >> package.zip
```

Le fichier téléchargé est écrit dans `package.zip` dans le répertoire courant.
