---
stage: Package
group: Package Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Conan v2
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/519741) dans GitLab 17.11 [avec un indicateur](../../administration/feature_flags/_index.md) nommé `conan_package_revisions_support`. Désactivé par défaut.
- [Activé sur GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/14896) dans GitLab 18.3. L'indicateur de fonctionnalité `conan_package_revisions_support` a été supprimé.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Utilisez cette API pour interagir avec le [gestionnaire de paquets Conan v2](../../user/packages/conan_2_repository/_index.md). Pour les opérations Conan v1, voir l'[API Conan v1](conan_v1.md).

> [!note]
> Ces endpoints ne respectent pas les méthodes d'authentification standard de l'API. Consultez chaque route pour plus de détails sur la façon dont les informations d'identification sont censées être transmises. Les méthodes d'authentification non documentées pourront être supprimées à l'avenir.

En général, ces endpoints sont utilisés par le [client du gestionnaire de paquets Conan 2](https://docs.conan.io/2/index.html) et ne sont pas destinés à une utilisation manuelle.

> [!warning]
> Le registre Conan n'est pas conforme FIPS et est désactivé lorsque le mode FIPS est activé. Ces endpoints retournent tous `404 Not Found`.

## Créer un jeton d'authentification {#create-an-authentication-token}

Crée un JSON Web Token (JWT) à utiliser comme en-tête Bearer dans d'autres requêtes.

```shell
"Authorization: Bearer <authenticate_token>
```

Le client du gestionnaire de paquets Conan 2 utilise automatiquement ce jeton.

```plaintext
GET /projects/:id/packages/conan/v2/users/authenticate
```

| Attribut | Type   | Obligatoire      | Description                                                                  |
| --------- | ------ | ------------- | ---------------------------------------------------------------------------- |
| `id`      | string | Conditionnel | L'ID du projet ou le chemin complet du projet. Requis uniquement pour l'endpoint du projet. |

Générer un jeton Basic Auth encodé en base64 :

```shell
echo -n "<username>:<your_access_token>"|base64
```

Utiliser le jeton Basic Auth encodé en base64 pour obtenir un jeton JWT :

```shell
curl --request GET \
     --header 'Authorization: Basic <base64_encoded_token>' \
     --url "https://gitlab.example.com/api/v4/packages/conan/v2/users/authenticate"
```

Exemple de réponse :

```shell
eyJhbGciOiJIUzI1NiIiheR5cCI6IkpXVCJ9.eyJhY2Nlc3NfdG9rZW4iOjMyMTQyMzAsqaVzZXJfaWQiOjQwNTkyNTQsImp0aSI6IjdlNzBiZTNjLWFlNWQtNDEyOC1hMmIyLWZiOThhZWM0MWM2OSIsImlhd3r1MTYxNjYyMzQzNSwibmJmIjoxNjE2NjIzNDMwLCJleHAiOjE2MTY2MjcwMzV9.QF0Q3ZIB2GW5zNKyMSIe0HIFOITjEsZEioR-27Rtu7E
```

## Vérifier les informations d'authentification {#verify-authentication-credentials}

Vérifie la validité des informations d'identification Basic Auth ou d'un JWT Conan spécifié généré depuis l'endpoint Conan v1 [`/authenticate`](conan_v1.md#create-an-authentication-token).

```plaintext
GET /projects/:id/packages/conan/v2/users/check_credentials
```

| Attribut | Type   | Obligatoire | Description                          |
| --------- | ------ | -------- | ------------------------------------ |
| `id`      | string | oui      | L'ID du projet ou le chemin complet du projet. |

```shell
curl --request GET \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/<project_id>/packages/conan/v2/users/check_credentials"
```

Exemple de réponse :

```plaintext
ok
```

## Rechercher un paquet Conan {#search-for-a-conan-package}

Recherche un paquet Conan spécifié dans le projet.

```plaintext
GET /projects/:id/packages/conan/v2/conans/search?q=:query
```

| Attribut | Type   | Obligatoire | Description                                  |
| --------- | ------ | -------- | -------------------------------------------- |
| `id`      | string | oui      | L'ID du projet ou le chemin complet du projet.         |
| `query`   | string | oui      | Requête de recherche. Vous pouvez utiliser `*` comme caractère générique. |

```shell
curl --request GET \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/search?q=Hello*"
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

## Récupérer la dernière révision de recette {#retrieve-latest-recipe-revision}

Récupère le hachage de révision et la date de création de la dernière recette de paquet.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/latest
```

| Attribut          | Type   | Obligatoire | Description                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | string | oui      | L'ID du projet ou le chemin complet du projet.                                                        |
| `package_name`     | string | oui      | Nom d'un paquet.                                                                          |
| `package_version`  | string | oui      | Version d'un paquet.                                                                       |
| `package_username` | string | oui      | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`  | string | oui      | Canal d'un paquet.                                                                       |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/latest"
```

Exemple de réponse :

```json
{
  "revision" : "75151329520e7685dcf5da49ded2fec0",
  "time" : "2024-12-17T09:16:40.334+0000"
}
```

## Lister toutes les révisions de recette {#list-all-recipe-revisions}

Liste toutes les révisions d'une recette de paquet.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions
```

| Attribut          | Type   | Obligatoire | Description                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | string | oui      | L'ID du projet ou le chemin complet du projet.                                                        |
| `package_name`     | string | oui      | Nom d'un paquet.                                                                          |
| `package_version`  | string | oui      | Version d'un paquet.                                                                       |
| `package_username` | string | oui      | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`  | string | oui      | Canal d'un paquet.                                                                       |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions"
```

Exemple de réponse :

```json
{
  "reference": "my-package/1.0@my-group+my-project/stable",
  "revisions": [
    {
      "revision": "75151329520e7685dcf5da49ded2fec0",
      "time": "2024-12-17T09:16:40.334+0000"
    },
    {
      "revision": "df28fd816be3a119de5ce4d374436b25",
      "time": "2024-12-17T09:15:30.123+0000"
    }
  ]
}
```

## Supprimer une révision de recette {#delete-a-recipe-revision}

Supprime une révision de recette spécifiée du registre. Si le paquet ne possède qu'une seule révision de recette, le paquet est également supprimé.

```plaintext
DELETE /projects/:id/packages/conan/conans/:package_name/package_version/:package_username/:package_channel/revisions/:recipe_revision
```

| Attribut          | Type   | Obligatoire | Description                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | string | oui      | L'ID du projet ou le chemin complet du projet.                                                        |
| `package_name`     | string | oui      | Nom d'un paquet.                                                                          |
| `package_version`  | string | oui      | Version d'un paquet.                                                                       |
| `package_username` | string | oui      | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`  | string | oui      | Canal d'un paquet.                                                                       |
| `recipe_revision`  | string | oui      | Hachage de révision de la révision de recette à supprimer.                                                |

```shell
curl --request DELETE \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/2be19f5a69b2cb02ab576755252319b9"
```

## Lister tous les fichiers de recette {#list-all-recipe-files}

Liste tous les fichiers de recette du registre de paquets.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/files
```

| Attribut          | Type   | Obligatoire | Description                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | string | oui      | L'ID du projet ou le chemin complet du projet.                                                        |
| `package_name`     | string | oui      | Nom d'un paquet.                                                                          |
| `package_version`  | string | oui      | Version d'un paquet.                                                                       |
| `package_username` | string | oui      | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`  | string | oui      | Canal d'un paquet.                                                                       |
| `recipe_revision`  | string | oui      | Révision de la recette. N'accepte pas une valeur de `0`.                                     |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-username/stable/revisions/df28fd816be3a119de5ce4d374436b25/files"
```

Exemple de réponse :

```json
{
  "files": {
    "conan_sources.tgz": {},
    "conanfile.py": {},
    "conanmanifest.txt": {}
  }
}
```

## Récupérer un fichier de recette {#retrieve-a-recipe-file}

Récupère un fichier de recette spécifié depuis le registre de paquets.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/files/:file_name
```

| Attribut          | Type   | Obligatoire | Description                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | string | oui      | L'ID du projet ou le chemin complet du projet.                                                        |
| `package_name`     | string | oui      | Nom d'un paquet.                                                                          |
| `package_version`  | string | oui      | Version d'un paquet.                                                                       |
| `package_username` | string | oui      | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`  | string | oui      | Canal d'un paquet.                                                                       |
| `recipe_revision`  | string | oui      | Révision de la recette. N'accepte pas une valeur de `0`.                                     |
| `file_name`        | string | oui      | Le nom et l'extension de fichier du fichier demandé.                                          |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-username/stable/revisions/df28fd816be3a119de5ce4d374436b25/files/conanfile.py"
```

Vous pouvez également écrire la sortie dans un fichier en utilisant :

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-username/stable/revisions/df28fd816be3a119de5ce4d374436b25/files/conanfile.py" \
     >> conanfile.py
```

Cet exemple écrit dans `conanfile.py` dans le répertoire courant.

## Téléverser un fichier de recette {#upload-a-recipe-file}

Téléverse un fichier de recette spécifié vers le registre de paquets.

```plaintext
PUT /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/files/:file_name
```

| Attribut          | Type   | Obligatoire | Description                                                                                 |
| ------------------ | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`               | string | oui      | L'ID du projet ou le chemin complet du projet.                                                        |
| `package_name`     | string | oui      | Nom d'un paquet.                                                                          |
| `package_version`  | string | oui      | Version d'un paquet.                                                                       |
| `package_username` | string | oui      | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`  | string | oui      | Canal d'un paquet.                                                                       |
| `recipe_revision`  | string | oui      | Révision de la recette. N'accepte pas une valeur de `0`.                                     |
| `file_name`        | string | oui      | Le nom et l'extension de fichier du fichier demandé.                                          |

```shell
curl --request PUT \
     --header "Authorization: Bearer <authenticate_token>" \
     --upload-file path/to/conanfile.py \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/upload-v2-package/1.0.0/user/stable/revisions/123456789012345678901234567890ab/files/conanfile.py"
```

Exemple de réponse :

```json
{
  "id": 38,
  "package_id": 28,
  "created_at": "2025-04-07T12:35:40.841Z",
  "updated_at": "2025-04-07T12:35:40.841Z",
  "size": 24,
  "file_store": 1,
  "file_md5": "131f806af123b497209a516f46d12ffd",
  "file_sha1": "01b992b2b1976a3f4c1e5294d0cab549cd438502",
  "file_name": "conanfile.py",
  "file": {
    "url": "/94/00/9400f1b21cb527d7fa3d3eabba93557a18ebe7a2ca4e471cfe5e4c5b4ca7f767/packages/28/files/38/conanfile.py"
  },
  "file_sha256": null,
  "verification_retry_at": null,
  "verified_at": null,
  "verification_failure": null,
  "verification_retry_count": null,
  "verification_checksum": null,
  "verification_state": 0,
  "verification_started_at": null,
  "status": "default",
  "file_final_path": null,
  "project_id": 9,
  "new_file_path": null
}
```

## Lister toutes les révisions de paquet {#list-all-package-revisions}

Liste toutes les révisions de paquet pour une révision de recette et une référence de paquet spécifiques.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions
```

| Attribut                 | Type   | Obligatoire | Description                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | string | oui      | L'ID du projet ou le chemin complet du projet.                                                        |
| `package_name`            | string | oui      | Nom d'un paquet.                                                                          |
| `package_version`         | string | oui      | Version d'un paquet.                                                                       |
| `package_username`        | string | oui      | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`         | string | oui      | Canal d'un paquet.                                                                       |
| `recipe_revision`         | string | oui      | Révision de la recette. N'accepte pas une valeur de `0`.                                     |
| `conan_package_reference` | string | oui      | Hachage de référence d'un paquet Conan. Conan génère cette valeur.                              |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions"
```

Exemple de réponse :

```json
{
  "reference": "my-package/1.0@my-group+my-project/stable#75151329520e7685dcf5da49ded2fec0:103f6067a947f366ef91fc1b7da351c588d1827f",
  "revisions": [
    {
      "revision": "2bfb52659449d84ed11356c353bfbe86",
      "time": "2024-12-17T09:16:40.334+0000"
    },
    {
      "revision": "3bdd2d8c8e76c876ebd1ac0469a4e72c",
      "time": "2024-12-17T09:15:30.123+0000"
    }
  ]
}
```

## Récupérer la dernière révision de paquet {#retrieve-latest-package-revision}

Récupère le hachage de révision et la date de création de la dernière révision de paquet pour une révision de recette et une référence de paquet spécifiées.

```plaintext
GET /api/v4/projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/latest
```

| Attribut                 | Type   | Obligatoire | Description                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | string | oui      | L'ID du projet ou le chemin complet du projet.                                                        |
| `package_name`            | string | oui      | Nom d'un paquet.                                                                          |
| `package_version`         | string | oui      | Version d'un paquet.                                                                       |
| `package_username`        | string | oui      | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`         | string | oui      | Canal d'un paquet.                                                                       |
| `recipe_revision`         | string | oui      | Révision de la recette. N'accepte pas une valeur de `0`.                                     |
| `conan_package_reference` | string | oui      | Hachage de référence d'un paquet Conan. Conan génère cette valeur.                              |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/latest"
```

Exemple de réponse :

```json
{
  "revision" : "3bdd2d8c8e76c876ebd1ac0469a4e72c",
  "time" : "2024-12-17T09:16:40.334+0000"
}
```

## Supprimer une révision de paquet {#delete-a-package-revision}

Supprime une révision de paquet spécifiée du registre. Si la référence de paquet ne possède qu'une seule révision de paquet, la référence de paquet est également supprimée.

```plaintext
DELETE /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions/:package_revision
```

| Attribut                 | Type   | Obligatoire | Description                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | string | oui      | L'ID du projet ou le chemin complet du projet.                                                        |
| `package_name`            | string | oui      | Nom d'un paquet.                                                                          |
| `package_version`         | string | oui      | Version d'un paquet.                                                                       |
| `package_username`        | string | oui      | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`         | string | oui      | Canal d'un paquet.                                                                       |
| `recipe_revision`         | string | oui      | Révision de la recette. N'accepte pas une valeur de `0`.                                             |
| `conan_package_reference` | string | oui      | Hachage de référence d'un paquet Conan. Conan génère cette valeur.                              |
| `package_revision`        | string | oui      | Révision du paquet. N'accepte pas une valeur de `0`.                                    |

```shell
curl --request DELETE \
     --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions/3bdd2d8c8e76c876ebd1ac0469a4e72c"
```

## Récupérer un fichier de paquet {#retrieve-a-package-file}

Récupère un fichier de paquet spécifié depuis le registre de paquets.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions/:package_revision/files/:file_name
```

| Attribut                 | Type   | Obligatoire | Description                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | string | oui      | L'ID du projet ou le chemin complet du projet.                                                        |
| `package_name`            | string | oui      | Nom d'un paquet.                                                                          |
| `package_version`         | string | oui      | Version d'un paquet.                                                                       |
| `package_username`        | string | oui      | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`         | string | oui      | Canal d'un paquet.                                                                       |
| `recipe_revision`         | string | oui      | Révision de la recette. N'accepte pas une valeur de `0`.                                     |
| `conan_package_reference` | string | oui      | Hachage de référence d'un paquet Conan. Conan génère cette valeur.                              |
| `package_revision`        | string | oui      | Révision du paquet. N'accepte pas une valeur de `0`.                                    |
| `file_name`               | string | oui      | Le nom et l'extension de fichier du fichier demandé.                                          |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions/3bdd2d8c8e76c876ebd1ac0469a4e72c/files/conaninfo.txt"
```

Vous pouvez également écrire la sortie dans un fichier en utilisant :

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions/3bdd2d8c8e76c876ebd1ac0469a4e72c/files/conaninfo.txt" \
     >> conaninfo.txt
```

Cet exemple écrit dans `conaninfo.txt` dans le répertoire courant.

## Téléverser un fichier de paquet {#upload-a-package-file}

Téléverse un fichier de paquet spécifié vers le registre de paquets.

```plaintext
PUT /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/packages/:conan_package_reference/revisions/:package_revision/files/:file_name
```

| Attribut                 | Type   | Obligatoire | Description                                                                                 |
| ------------------------- | ------ | -------- | ------------------------------------------------------------------------------------------- |
| `id`                      | string | oui      | L'ID du projet ou le chemin complet du projet.                                                        |
| `package_name`            | string | oui      | Nom d'un paquet.                                                                          |
| `package_version`         | string | oui      | Version d'un paquet.                                                                       |
| `package_username`        | string | oui      | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`         | string | oui      | Canal d'un paquet.                                                                       |
| `recipe_revision`         | string | oui      | Révision de la recette. N'accepte pas une valeur de `0`.                                     |
| `conan_package_reference` | string | oui      | Hachage de référence d'un paquet Conan. Conan génère cette valeur.                              |
| `package_revision`        | string | oui      | Révision du paquet. N'accepte pas une valeur de `0`.                                    |
| `file_name`               | string | oui      | Le nom et l'extension de fichier du fichier demandé.                                          |

Fournissez le contenu du fichier dans le corps de la requête :

```shell
curl --request PUT \
     --header "Authorization: Bearer <authenticate_token>" \
     --upload-file path/to/conaninfo.txt \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/packages/103f6067a947f366ef91fc1b7da351c588d1827f/revisions/3bdd2d8c8e76c876ebd1ac0469a4e72c/files/conaninfo.txt"
```

Exemple de réponse :

```json
{
  "id": 202,
  "package_id": 48,
  "created_at": "2025-03-19T10:06:53.626Z",
  "updated_at": "2025-03-19T10:06:53.626Z",
  "size": 208,
  "file_store": 1,
  "file_md5": "bf996313bbdd75944b58f8c673661d99",
  "file_sha1": "02c8adf14c94135fb95d472f96525063efe09ee8",
  "file_name": "conaninfo.txt",
  "file": {
      "url": "/94/00/9400f1b21cb527d7fa3d3eabba93557a18ebe7a2ca4e471cfe5e4c5b4ca7f767/packages/48/files/202/conaninfo.txt"
  },
  "file_sha256": null,
  "verification_retry_at": null,
  "verified_at": null,
  "verification_failure": null,
  "verification_retry_count": null,
  "verification_checksum": null,
  "verification_state": 0,
  "verification_started_at": null,
  "status": "default",
  "file_final_path": null,
  "project_id": 9,
  "new_file_path": null
}
```

## Récupérer les métadonnées des références de paquet {#retrieve-package-references-metadata}

Récupère les métadonnées de toutes les références de paquet d'un paquet spécifié.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/search
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | oui | L'ID du projet ou le chemin complet du projet. |
| `package_name`      | string | oui | Nom d'un paquet. |
| `package_version`   | string | oui | Version d'un paquet. |
| `package_username`  | string | oui | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`   | string | oui | Canal d'un paquet. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/search"
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

## Récupérer les métadonnées des références de paquet par révision de recette {#retrieve-package-references-metadata-by-recipe-revision}

Récupère les métadonnées de toutes les références de paquet associées à une révision de recette spécifiée.

```plaintext
GET /projects/:id/packages/conan/v2/conans/:package_name/:package_version/:package_username/:package_channel/revisions/:recipe_revision/search
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id`                | string | oui | L'ID du projet ou le chemin complet du projet. |
| `package_name`      | string | oui | Nom d'un paquet. |
| `package_version`   | string | oui | Version d'un paquet. |
| `package_username`  | string | oui | Nom d'utilisateur Conan d'un paquet. Cet attribut est le chemin complet de votre projet séparé par `+`. |
| `package_channel`   | string | oui | Canal d'un paquet. |
| `recipe_revision`   | string | oui | Révision de la recette. N'accepte pas une valeur de `0`. |

```shell
curl --header "Authorization: Bearer <authenticate_token>" \
     --url "https://gitlab.example.com/api/v4/projects/9/packages/conan/v2/conans/my-package/1.0/my-group+my-project/stable/revisions/75151329520e7685dcf5da49ded2fec0/search"
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
