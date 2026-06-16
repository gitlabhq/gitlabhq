---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Conan v1
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

> [!note]
> Pour les opérations Conan v2, consultez [API Conan v2](conan_v2.md).

Utilisez cette API pour interagir avec le [gestionnaire de paquets Conan v1](../../user/packages/conan_1_repository/_index.md). Ces endpoints fonctionnent aussi bien pour les projets que pour les instances.

> [!note]
> Ces endpoints ne respectent pas les méthodes d'authentification standard de l'API. Consultez chaque route pour plus de détails sur la manière dont les identifiants sont censés être transmis. Les méthodes d'authentification non documentées pourraient être supprimées à l'avenir.

En général, ces endpoints sont utilisés par le [client du gestionnaire de paquets Conan 1](https://docs.conan.io/en/latest/) et ne sont pas destinés à une utilisation manuelle.

> [!warning]
> Le registre Conan n'est pas conforme FIPS et est désactivé lorsque le mode FIPS est activé. Ces endpoints renvoient tous `404 Not Found`.

## Créer un token d'authentification {#create-an-authentication-token}

Crée un jeton Web JSON (JWT) à utiliser comme en-tête Bearer dans d'autres requêtes adressées au client du gestionnaire de paquets Conan.

```shell
"Authorization: Bearer <authenticate_token>"
```

```plaintext
GET /packages/conan/v1/users/authenticate
GET /projects/:id/packages/conan/v1/users/authenticate
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |

```shell
curl --user <username>:<your_access_token> \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/users/authenticate"
```

Exemple de réponse :

```shell
eyJhbGciOiJIUzI1NiIiheR5cCI6IkpXVCJ9.eyJhY2Nlc3NfdG9rZW4iOjMyMTQyMzAsqaVzZXJfaWQiOjQwNTkyNTQsImp0aSI6IjdlNzBiZTNjLWFlNWQtNDEyOC1hMmIyLWZiOThhZWM0MWM2OSIsImlhd3r1MTYxNjYyMzQzNSwibmJmIjoxNjE2NjIzNDMwLCJleHAiOjE2MTY2MjcwMzV9.QF0Q3ZIB2GW5zNKyMSIe0HIFOITjEsZEioR-27Rtu7E
```

## Vérifier la disponibilité d'un dépôt Conan {#verify-availability-of-a-conan-repository}

Vérifie la disponibilité du dépôt GitLab Conan.

```plaintext
GET /packages/conan/v1/ping
GET /projects/:id/packages/conan/v1/ping
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |

```shell
curl --url "https://gitlab.example.com/api/v4/packages/conan/v1/ping"
```

Exemple de réponse :

```json
""
```

## Rechercher un paquet Conan {#search-for-a-conan-package}

Recherche un paquet Conan spécifié dans l'instance.

```plaintext
GET /packages/conan/v1/conans/search
GET /projects/:id/packages/conan/v1/conans/search
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |
| `q`       | string | oui | Requête de recherche. Vous pouvez utiliser `*` comme caractère générique. |

```shell
curl --user <username>:<your_access_token> \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/search?q=Hello*"
```

Exemple de réponse :

```json
{
  "results": [
    "Hello/0.1@foo+conan_test_prod/beta",
    "Hello/0.1@foo+conan_test_prod/stable",
    "Hello/0.2@foo+conan_test_prod/beta",
    "Hello/0.3@foo+conan_test_prod/beta",
    "Hello/0.1@foo+conan-reference-test/stable",
    "HelloWorld/0.1@baz+conan-reference-test/beta"
    "hello-world/0.4@buz+conan-test/alpha"
  ]
}
```

## Vérifier les identifiants d'authentification {#verify-authentication-credentials}

Vérifie la validité des identifiants Basic Auth ou d'un JWT Conan spécifié généré depuis l'endpoint [`/authenticate`](#create-an-authentication-token).

```plaintext
GET /packages/conan/v1/users/check_credentials
GET /projects/:id/packages/conan/v1/users/check_credentials
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`      | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/users/check_credentials"
```

Exemple de réponse :

```shell
ok
```

## Récupérer un instantané de recette {#retrieve-a-recipe-snapshot}

Récupère un instantané des fichiers pour une recette Conan spécifiée. L'instantané est une liste de noms de fichiers avec leur hachage MD5 associé.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel
GET /projects/:id/packages/conan/v1/conans/:package_version/:package_username/:package_channel
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |
| `package_name`      | string | oui | Nom d'un paquet. |
| `package_version`   | string | oui | Version d'un paquet. |
| `package_username`  | string | oui | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`   | string | oui | Canal d'un paquet. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable"
```

Exemple de réponse :

```json
{
  "conan_sources.tgz": "eadf19b33f4c3c7e113faabf26e76277",
  "conanfile.py": "25e55b96a28f81a14ba8e8a8c99eeace",
  "conanmanifest.txt": "5b6fd77a2ba14303ce4cdb08c87e82ab"
}
```

## Récupérer un instantané de paquet {#retrieve-a-package-snapshot}

Récupère un instantané des fichiers pour un paquet Conan et une référence spécifiés. L'instantané est une liste de noms de fichiers avec leur hachage MD5 associé.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |
| `package_name`      | string | oui | Nom d'un paquet. |
| `package_version`   | string | oui | Version d'un paquet. |
| `package_username`  | string | oui | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`   | string | oui | Canal d'un paquet. |
| `conan_package_reference` | string | oui | Hachage de référence d'un paquet Conan. Conan génère cette valeur. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f"
```

Exemple de réponse :

```json
{
  "conan_package.tgz": "749b29bdf72587081ca03ec033ee59dc",
  "conaninfo.txt": "32859d737fe84e6a7ccfa4d64dc0d1f2",
  "conanmanifest.txt": "a86b398e813bd9aa111485a9054a2301"
}
```

## Récupérer un manifeste de recette {#retrieve-a-recipe-manifest}

Récupère un manifeste qui inclut une liste de fichiers et les URL de téléchargement associées pour une recette spécifiée.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/digest
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/digest
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |
| `package_name`      | string | oui | Nom d'un paquet. |
| `package_version`   | string | oui | Version d'un paquet. |
| `package_username`  | string | oui | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`   | string | oui | Canal d'un paquet. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/digest"
```

Exemple de réponse :

```json
{
  "conan_sources.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conan_sources.tgz",
  "conanfile.py": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanmanifest.txt"
}
```

## Récupérer un manifeste de paquet {#retrieve-a-package-manifest}

Récupère un manifeste qui inclut une liste de fichiers et les URL de téléchargement associées pour un paquet spécifié.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/digest
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/digest
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |
| `package_name`      | string | oui | Nom d'un paquet. |
| `package_version`   | string | oui | Version d'un paquet. |
| `package_username`  | string | oui | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`   | string | oui | Canal d'un paquet. |
| `conan_package_reference` | string | oui | Hachage de référence d'un paquet Conan. Conan génère cette valeur. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/digest"
```

Exemple de réponse :

```json
{
  "conan_package.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conan_package.tgz",
  "conaninfo.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conanmanifest.txt"
}
```

## Lister toutes les URL de téléchargement de recette {#list-all-recipe-download-urls}

Liste tous les fichiers et les URL de téléchargement associées pour une recette spécifiée. Renvoie la même charge utile que l'endpoint [manifeste de recette](#retrieve-a-recipe-manifest).

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/download_urls
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/download_urls
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |
| `package_name`      | string | oui | Nom d'un paquet. |
| `package_version`   | string | oui | Version d'un paquet. |
| `package_username`  | string | oui | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`   | string | oui | Canal d'un paquet. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/digest"
```

Exemple de réponse :

```json
{
  "conan_sources.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conan_sources.tgz",
  "conanfile.py": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanmanifest.txt"
}
```

## Lister toutes les URL de téléchargement de paquet {#list-all-package-download-urls}

Liste tous les fichiers et les URL de téléchargement associées pour un paquet spécifié. Renvoie la même charge utile que l'endpoint [manifeste de paquet](#retrieve-a-package-manifest).

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/download_urls
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/download_urls
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |
| `package_name`      | string | oui | Nom d'un paquet. |
| `package_version`   | string | oui | Version d'un paquet. |
| `package_username`  | string | oui | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`   | string | oui | Canal d'un paquet. |
| `conan_package_reference` | string | oui | Hachage de référence d'un paquet Conan. Conan génère cette valeur. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/download_urls"
```

Exemple de réponse :

```json
{
  "conan_package.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conan_package.tgz",
  "conaninfo.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conanmanifest.txt"
}
```

## Lister toutes les URL d'envoi de recette {#list-all-recipe-upload-urls}

Liste les URL d'envoi pour une collection spécifiée de fichiers de recette. La requête doit inclure un objet JSON avec le nom et la taille des fichiers individuels.

```plaintext
POST /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/upload_urls
POST /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/upload_urls
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |
| `package_name`      | string | oui | Nom d'un paquet. |
| `package_version`   | string | oui | Version d'un paquet. |
| `package_username`  | string | oui | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`   | string | oui | Canal d'un paquet. |

Exemple de charge utile JSON de la requête :

La charge utile doit inclure le nom et la taille du fichier.

```json
{
  "conanfile.py": 410,
  "conanmanifest.txt": 130
}
```

```shell
curl --request POST \
     --header "Authorization: Bearer <authenticate_token>" \
     --header "Content-Type: application/json" \
     --data '{"conanfile.py":410,"conanmanifest.txt":130}' \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/upload_urls"
```

Exemple de réponse :

```json
{
  "conanfile.py": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanmanifest.txt"
}
```

## Lister toutes les URL d'envoi de paquet {#list-all-package-upload-urls}

Liste les URL d'envoi pour une collection spécifiée de fichiers de paquet. La requête doit inclure un objet JSON avec le nom et la taille des fichiers individuels.

```plaintext
POST /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/upload_urls
POST /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/packages/:conan_package_reference/upload_urls
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |
| `package_name`      | string | oui | Nom d'un paquet. |
| `package_version`   | string | oui | Version d'un paquet. |
| `package_username`  | string | oui | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`   | string | oui | Canal d'un paquet. |
| `conan_package_reference` | string | oui | Hachage de référence d'un paquet Conan. Conan génère cette valeur. |

Exemple de charge utile JSON de la requête :

La charge utile doit inclure le nom et la taille du fichier.

```json
{
  "conan_package.tgz": 5412,
  "conanmanifest.txt": 130,
  "conaninfo.txt": 210
}
```

```shell
curl --request POST \
     --header "Authorization: Bearer <authenticate_token>" \
     --header "Content-Type: application/json" \
     --data '{"conan_package.tgz":5412,"conanmanifest.txt":130,"conaninfo.txt":210}' \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/upload_urls"
```

Exemple de réponse :

```json
{
  "conan_package.tgz": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/package/103f6067a947f366ef91fc1b7da351c588d1827f/0/conan_package.tgz",
  "conanmanifest.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/package/103f6067a947f366ef91fc1b7da351c588d1827f/0/conanmanifest.txt",
  "conaninfo.txt": "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/package/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt"
}
```

## Récupérer un fichier de recette {#retrieve-a-recipe-file}

Récupère un fichier de recette spécifié depuis le registre de paquets. Vous devez utiliser l'URL de téléchargement renvoyée par l'endpoint [URL de téléchargement de recette](#list-all-recipe-download-urls).

```plaintext
GET /packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
GET /projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |
| `package_name`      | string | oui | Nom d'un paquet. |
| `package_version`   | string | oui | Version d'un paquet. |
| `package_username`  | string | oui | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`   | string | oui | Canal d'un paquet. |
| `recipe_revision`   | string | oui | Révision de la recette. GitLab ne prend pas encore en charge les révisions Conan, la valeur par défaut `0` est donc toujours utilisée. |
| `file_name`         | string | oui | Le nom et l'extension de fichier du fichier demandé. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py"
```

Vous pouvez également écrire la sortie dans un fichier en utilisant :

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py" \
     >> conanfile.py
```

Cet exemple écrit dans `conanfile.py` dans le répertoire courant.

## Envoyer un fichier de recette {#upload-a-recipe-file}

Envoie un fichier de recette spécifié vers le registre de paquets. Vous devez utiliser l'URL d'envoi renvoyée par l'endpoint [URL d'envoi de recette](#list-all-recipe-upload-urls).

```plaintext
PUT /packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
PUT /projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/export/:file_name
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |
| `package_name`      | string | oui | Nom d'un paquet. |
| `package_version`   | string | oui | Version d'un paquet. |
| `package_username`  | string | oui | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`   | string | oui | Canal d'un paquet. |
| `recipe_revision`   | string | oui | Révision de la recette. GitLab ne prend pas encore en charge les révisions Conan, la valeur par défaut `0` est donc toujours utilisée. |
| `file_name`         | string | oui | Le nom et l'extension de fichier du fichier demandé. |

Fournissez le contenu du fichier dans le corps de la requête :

```shell
curl --request PUT \
     --user <username>:<personal_access_token> \
     --upload-file path/to/conanfile.py \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/export/conanfile.py"
```

## Récupérer un fichier de paquet {#retrieve-a-package-file}

Récupère un fichier de paquet spécifié depuis le registre de paquets. Vous devez utiliser l'URL de téléchargement renvoyée par l'endpoint [URL de téléchargement de paquet](#list-all-package-download-urls).

```plaintext
GET /packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
GET /projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |
| `package_name`      | string | oui | Nom d'un paquet. |
| `package_version`   | string | oui | Version d'un paquet. |
| `package_username`  | string | oui | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`   | string | oui | Canal d'un paquet. |
| `recipe_revision`   | string | oui | Révision de la recette. GitLab ne prend pas encore en charge les révisions Conan, la valeur par défaut `0` est donc toujours utilisée. |
| `conan_package_reference` | string | oui | Hachage de référence d'un paquet Conan. Conan génère cette valeur. |
| `package_revision`  | string | oui | Révision du paquet. GitLab ne prend pas encore en charge les révisions Conan, la valeur par défaut `0` est donc toujours utilisée. |
| `file_name`         | string | oui | Le nom et l'extension de fichier du fichier demandé. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt"
```

Vous pouvez également écrire la sortie dans un fichier en utilisant :

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/packages/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt" \
     >> conaninfo.txt
```

Cet exemple écrit dans `conaninfo.txt` dans le répertoire courant.

## Envoyer un fichier de paquet {#upload-a-package-file}

Envoie un fichier de paquet spécifié vers le registre de paquets. Vous devez utiliser l'URL d'envoi renvoyée par l'endpoint [URL d'envoi de paquet](#list-all-package-upload-urls).

```plaintext
PUT /packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
PUT /projects/:id/packages/conan/v1/files/:package_name/:package_version/:package_username/:package_channel/:recipe_revision/package/:conan_package_reference/:package_revision/:file_name
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |
| `package_name`      | string | oui | Nom d'un paquet. |
| `package_version`   | string | oui | Version d'un paquet. |
| `package_username`  | string | oui | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`   | string | oui | Canal d'un paquet. |
| `recipe_revision`   | string | oui | Révision de la recette. GitLab ne prend pas encore en charge les révisions Conan, la valeur par défaut `0` est donc toujours utilisée. |
| `conan_package_reference` | string | oui | Hachage de référence d'un paquet Conan. Conan génère cette valeur. |
| `package_revision`  | string | oui | Révision du paquet. GitLab ne prend pas encore en charge les révisions Conan, la valeur par défaut `0` est donc toujours utilisée. |
| `file_name`         | string | oui | Le nom et l'extension de fichier du fichier demandé. |

Fournissez le contenu du fichier dans le corps de la requête :

```shell
curl --request PUT \
     --user <username>:<your_access_token> \
     --upload-file path/to/conaninfo.txt \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/files/my-package/1.0/my-group+my-project/stable/0/package/103f6067a947f366ef91fc1b7da351c588d1827f/0/conaninfo.txt"
```

## Supprimer une recette et un paquet {#delete-a-recipe-and-package}

Supprime une recette Conan spécifiée et les fichiers de paquet associés du registre de paquets.

```plaintext
DELETE /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel
DELETE /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |
| `package_name`      | string | oui | Nom d'un paquet. |
| `package_version`   | string | oui | Version d'un paquet. |
| `package_username`  | string | oui | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`   | string | oui | Canal d'un paquet. |

```shell
curl --request DELETE \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable"
```

Exemple de réponse :

```json
{
  "id": 1,
  "project_id": 123,
  "created_at": "2020-08-19T13:17:28.655Z",
  "updated_at": "2020-08-19T13:17:28.655Z",
  "name": "my-package",
  "version": "1.0",
  "package_type": "conan",
  "creator_id": null,
  "status": "default"
}
```

## Récupérer les métadonnées des références de paquet {#retrieve-package-references-metadata}

Récupère les métadonnées de toutes les références de paquet d'un paquet spécifié.

```plaintext
GET /packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/search
GET /projects/:id/packages/conan/v1/conans/:package_name/:package_version/:package_username/:package_channel/search
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | Conditionnellement | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint de projet. |
| `package_name`      | string | oui | Nom d'un paquet. |
| `package_version`   | string | oui | Version d'un paquet. |
| `package_username`  | string | oui | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`   | string | oui | Canal d'un paquet. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/packages/conan/v1/conans/my-package/1.0/my-group+my-project/stable/search"
```

Exemple de réponse :

```json
{
  "103f6067a947f366ef91fc1b7da351c588d1827f": {
    "settings": {
      "arch": "x86_64",
      "build_type": "Release",
      "compiler": "gcc",
      "compiler.libcxx": "libstdc++",
      "compiler.version": "9",
      "os": "Linux"
    },
    "options": {
      "shared": "False"
    },
    "requires": {
      "zlib/1.2.11": null
    },
    "recipe_hash": "75151329520e7685dcf5da49ded2fec0"
  }
}
```

La réponse inclut les métadonnées suivantes pour chaque référence de paquet :

- `settings` : Les paramètres de compilation utilisés pour le paquet.
- `options` : Les options du paquet.
- `requires` : Les dépendances requises pour le paquet.
- `recipe_hash` : Le hachage de la recette.
