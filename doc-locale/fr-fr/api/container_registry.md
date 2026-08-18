---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API du registre de conteneurs
description: "Gérez votre registre de conteneurs GitLab avec l'API REST."
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer le [registre de conteneurs GitLab](../user/packages/container_registry/_index.md).

Pour vous authentifier auprès de ces endpoints depuis un job CI/CD, transmettez la variable [`$CI_JOB_TOKEN`](../ci/jobs/ci_job_token.md) dans l'en-tête `JOB-TOKEN`. Le jeton de job n'a accès qu'au registre de conteneurs du projet qui a créé le pipeline.

## Modifier la visibilité du registre de conteneurs {#change-the-visibility-of-the-container-registry}

Modifie la visibilité du registre de conteneurs pour un projet spécifié.

```plaintext
PUT /projects/:id/
```

| Attribut                         | Type              | Obligatoire | Description |
|-----------------------------------|-------------------|----------|-------------|
| `id`                              | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du projet accessible par l'utilisateur authentifié. |
| `container_registry_access_level` | string            | non       | La visibilité souhaitée du registre de conteneurs. L'une des valeurs suivantes : `enabled` (par défaut), `private` ou `disabled`. |

Description des valeurs possibles pour `container_registry_access_level` :

- `enabled` (Par défaut) :  Le registre de conteneurs est visible pour toute personne ayant accès au projet. Si le projet est public, le registre de conteneurs est également public. Si le projet est interne ou privé, le registre de conteneurs est également interne ou privé.
- `private` :  Le registre de conteneurs n'est visible que pour les membres du projet ayant le rôle Reporter ou supérieur. Ce comportement est similaire à celui d'un projet privé avec la visibilité du registre de conteneurs activée.
- `disabled` :  Le registre de conteneurs est désactivé.

Consultez les [autorisations de visibilité du registre de conteneurs](../user/packages/container_registry/_index.md#container-registry-visibility-permissions) pour plus de détails sur les autorisations accordées aux utilisateurs par ce paramètre.

```shell
curl --request PUT "https://gitlab.example.com/api/v4/projects/5/" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Accept: application/json' \
  --header 'Content-Type: application/json' \
  --data-raw '{
      "container_registry_access_level": "private"
  }'
```

Exemple de réponse :

```json
{
  "id": 5,
  "name": "Project 5",
  "container_registry_access_level": "private",
  ...
}
```

## Répertorier tous les dépôts du registre {#list-all-registry-repositories}

### Au sein d'un projet {#within-a-project}

Répertorie tous les dépôts du registre pour un projet spécifié.

Les réponses sont [paginées](rest/_index.md#pagination) et retournent 20 résultats par défaut.

```plaintext
GET /projects/:id/registry/repositories
```

| Attribut    | Type           | Obligatoire | Description |
|--------------|----------------|----------|-------------|
| `id`         | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du projet accessible par l'utilisateur authentifié. |
| `tags`       | boolean        | non       | Si le paramètre est inclus avec la valeur true, chaque dépôt inclut un tableau de `"tags"` dans la réponse. |
| `tags_count` | boolean        | non       | Si le paramètre est inclus avec la valeur true, chaque dépôt inclut `"tags_count"` dans la réponse. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "",
    "path": "group/project",
    "project_id": 9,
    "location": "gitlab.example.com:5000/group/project",
    "created_at": "2019-01-10T13:38:57.391Z",
    "cleanup_policy_started_at": "2020-01-10T15:40:57.391Z",
    "status": null
  },
  {
    "id": 2,
    "name": "releases",
    "path": "group/project/releases",
    "project_id": 9,
    "location": "gitlab.example.com:5000/group/project/releases",
    "created_at": "2019-01-10T13:39:08.229Z",
    "cleanup_policy_started_at": "2020-08-17T03:12:35.489Z",
    "status": "delete_ongoing"
  }
]
```

### Au sein d'un groupe {#within-a-group}

{{< history >}}

- Les attributs `tags` et `tag_count` ont été [supprimés](https://gitlab.com/gitlab-org/gitlab/-/issues/336912) dans GitLab 15.0.

{{< /history >}}

Répertorie tous les dépôts du registre pour un groupe spécifié.

Les réponses sont [paginées](rest/_index.md#pagination) et retournent 20 résultats par défaut.

```plaintext
GET /groups/:id/registry/repositories
```

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du groupe accessible par l'utilisateur authentifié. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/2/registry/repositories"
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "name": "",
    "path": "group/project",
    "project_id": 9,
    "location": "gitlab.example.com:5000/group/project",
    "created_at": "2019-01-10T13:38:57.391Z",
    "cleanup_policy_started_at": "2020-08-17T03:12:35.489Z",
  },
  {
    "id": 2,
    "name": "",
    "path": "group/other_project",
    "project_id": 11,
    "location": "gitlab.example.com:5000/group/other_project",
    "created_at": "2019-01-10T13:39:08.229Z",
    "cleanup_policy_started_at": "2020-01-10T15:40:57.391Z",
  }
]
```

## Récupérer les détails d'un dépôt unique {#retrieve-details-of-a-single-repository}

Récupère les détails d'un dépôt de registre spécifié.

```plaintext
GET /registry/repositories/:id
```

| Attribut    | Type           | Obligatoire | Description |
|--------------|----------------|----------|-------------|
| `id`         | entier ou chaîne | oui      | L'ID du dépôt de registre accessible par l'utilisateur authentifié. |
| `tags`       | boolean        | non       | Si le paramètre est inclus avec la valeur `true`, la réponse inclut un tableau de `"tags"`. |
| `tags_count` | boolean        | non       | Si le paramètre est inclus avec la valeur `true`, la réponse inclut `"tags_count"`. |
| `size`       | boolean        | non       | Si le paramètre est inclus avec la valeur `true`, la réponse inclut `"size"`. Il s'agit de la taille dédupliquée de toutes les images contenues dans le dépôt. La déduplication élimine les copies supplémentaires de données identiques. Par exemple, si vous téléversez la même image deux fois, le registre de conteneurs ne stocke qu'une seule copie. Ce champ est uniquement disponible sur GitLab.com pour les dépôts créés après le `2021-11-04`. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/registry/repositories/2?tags=true&tags_count=true&size=true"
```

Exemple de réponse :

```json
{
  "id": 2,
  "name": "",
  "path": "group/project",
  "project_id": 9,
  "location": "gitlab.example.com:5000/group/project",
  "created_at": "2019-01-10T13:38:57.391Z",
  "cleanup_policy_started_at": "2020-08-17T03:12:35.489Z",
  "tags_count": 1,
  "tags": [
    {
      "name": "0.0.1",
      "path": "group/project:0.0.1",
      "location": "gitlab.example.com:5000/group/project:0.0.1"
    }
  ],
  "size": 2818413,
  "status": "delete_scheduled"
}
```

## Supprimer un dépôt de registre {#delete-registry-repository}

Supprime un dépôt spécifié dans le registre.

Cette opération est exécutée de manière asynchrone et peut prendre un certain temps avant d'être exécutée.

```plaintext
DELETE /projects/:id/registry/repositories/:repository_id
```

| Attribut       | Type           | Obligatoire | Description |
|-----------------|----------------|----------|-------------|
| `id`            | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du projet. |
| `repository_id` | entier        | oui      | L'ID du dépôt de registre. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2"
```

## Répertorier tous les tags du dépôt de registre {#list-all-registry-repository-tags}

### Au sein d'un projet {#within-a-project-1}

{{< history >}}

- La pagination par jeu de clés a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/issues/432470) dans GitLab 16.10 pour GitLab.com uniquement.

{{< /history >}}

Répertorie tous les tags pour un dépôt de registre spécifié.

Les réponses sont [paginées](rest/_index.md#pagination) et retournent 20 résultats par défaut.

> [!note]
> La pagination par décalage est obsolète et la pagination par jeu de clés est désormais la méthode de pagination privilégiée.

```plaintext
GET /projects/:id/registry/repositories/:repository_id/tags
```

| Attribut       | Type           | Obligatoire | Description |
|-----------------|----------------|----------|-------------|
| `id`            | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du projet accessible par l'utilisateur authentifié. |
| `repository_id` | entier        | oui      | L'ID du dépôt de registre. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
```

Exemple de réponse :

```json
[
  {
    "name": "A",
    "path": "group/project:A",
    "location": "gitlab.example.com:5000/group/project:A"
  },
  {
    "name": "latest",
    "path": "group/project:latest",
    "location": "gitlab.example.com:5000/group/project:latest"
  }
]
```

## Récupérer les détails d'un tag de dépôt de registre {#retrieve-details-of-a-registry-repository-tag}

Récupère les détails d'un tag de dépôt de registre spécifié.

```plaintext
GET /projects/:id/registry/repositories/:repository_id/tags/:tag_name
```

| Attribut       | Type           | Obligatoire | Description |
|-----------------|----------------|----------|-------------|
| `id`            | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du projet accessible par l'utilisateur authentifié. |
| `repository_id` | entier        | oui      | L'ID du dépôt de registre. |
| `tag_name`      | string         | oui      | Le nom du tag. |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags/v10.0.0"
```

Exemple de réponse :

```json
{
  "name": "v10.0.0",
  "path": "group/project:latest",
  "location": "gitlab.example.com:5000/group/project:latest",
  "revision": "e9ed9d87c881d8c2fd3a31b41904d01ba0b836e7fd15240d774d811a1c248181",
  "short_revision": "e9ed9d87c",
  "digest": "sha256:c3490dcf10ffb6530c1303522a1405dfaf7daecd8f38d3e6a1ba19ea1f8a1751",
  "created_at": "2019-01-06T16:49:51.272+00:00",
  "total_size": 350224384
}
```

## Supprimer un tag de dépôt de registre {#delete-a-registry-repository-tag}

Supprime un tag de dépôt de registre de conteneurs spécifié.

L'endpoint renvoie une erreur [`403 Forbidden`](rest/troubleshooting.md#status-codes) si le tag correspond à des règles de protection dans le projet. Pour plus d'informations sur les règles de protection des tags, consultez [Tags de conteneurs protégés](../user/packages/container_registry/protected_container_tags.md).

```plaintext
DELETE /projects/:id/registry/repositories/:repository_id/tags/:tag_name
```

| Attribut       | Type           | Obligatoire | Description |
|-----------------|----------------|----------|-------------|
| `id`            | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du projet. |
| `repository_id` | entier        | oui      | L'ID du dépôt de registre. |
| `tag_name`      | string         | oui      | Le nom du tag. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags/v10.0.0"
```

Cette opération ne supprime pas les blobs. Pour récupérer de l'espace disque, [exécutez le garbage collection](../administration/packages/container_registry.md#container-registry-garbage-collection).

## Supprimer des tags de dépôt de registre en masse {#delete-registry-repository-tags-in-bulk}

Supprime des tags de dépôt de registre en masse selon des critères spécifiés.

<i class="fa-youtube-play" aria-hidden="true"></i> Pour une présentation, consultez [Use the container registry API to delete all tags except \*](https://youtu.be/Hi19bKe_xsg).

```plaintext
DELETE /projects/:id/registry/repositories/:repository_id/tags
```

| Attribut           | Type           | Obligatoire | Description |
|---------------------|----------------|----------|-------------|
| `id`                | entier ou chaîne | oui      | L'ID ou le [chemin encodé URL](rest/_index.md#namespaced-paths) du projet. |
| `repository_id`     | entier        | oui      | L'ID du dépôt de registre. |
| `keep_n`            | entier        | non       | Le nombre de tags les plus récents du nom donné à conserver. |
| `name_regex`        | string         | non       | L'expression régulière [re2](https://github.com/google/re2/wiki/Syntax) du nom à supprimer. Pour supprimer tous les tags, spécifiez `.*`. Remarque : `name_regex` est obsolète au profit de `name_regex_delete`. Ce champ est validé. |
| `name_regex_delete` | string         | oui      | L'expression régulière [re2](https://github.com/google/re2/wiki/Syntax) du nom à supprimer. Pour supprimer tous les tags, spécifiez `.*`. Ce champ est validé. |
| `name_regex_keep`   | string         | non       | L'expression régulière [re2](https://github.com/google/re2/wiki/Syntax) du nom à conserver. Cette valeur remplace toute correspondance de `name_regex_delete`. Ce champ est validé. Remarque : définir la valeur sur `.*` n'a aucun effet. |
| `older_than`        | string         | non       | Tags à supprimer qui sont plus anciens que la durée donnée, exprimée sous forme lisible `1h`, `1d`, `1month`. |

Cette API REST retourne le [code de statut HTTP 202](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/202) en cas de succès et effectue les opérations suivantes :

- Elle trie tous les tags par date de création. La date de création correspond au moment de la création du manifeste, et non au moment du push du tag.
- Elle supprime uniquement les tags correspondant à `name_regex_delete` (ou à l'attribut obsolète `name_regex`), en conservant ceux qui correspondent à `name_regex_keep`.
- Elle ne supprime jamais le tag nommé `latest`.
- Elle conserve les N tags correspondants les plus récents (si `keep_n` est spécifié).
- Elle supprime uniquement les tags qui sont plus anciens que la durée X (si `older_than` est spécifié).
- Elle exclut les [tags protégés](../user/packages/container_registry/protected_container_tags.md).
- Elle planifie l'exécution du job asynchrone en arrière-plan.

Ces opérations sont exécutées de manière asynchrone et peuvent prendre un certain temps avant d'être exécutées. Vous pouvez exécuter cette opération au plus une fois par heure pour un dépôt de conteneurs donné.

Cette opération ne supprime pas les blobs. Pour récupérer de l'espace disque, [exécutez le garbage collection](../administration/packages/container_registry.md#container-registry-garbage-collection).

> [!warning]
> Le nombre de tags supprimés par cette API REST est limité sur GitLab.com en raison de l'échelle du registre de conteneurs. Si votre gistre de conteneurs comporte un grand nombre de tags à supprimer, seuls certains d'entre eux seront supprimés et vous devrez peut-être appeler cette API plusieurs fois. Pour planifier la suppression automatique des tags, utilisez plutôt une [politique de nettoyage](../user/packages/container_registry/reduce_container_registry_storage.md#cleanup-policy).

Exemples :

- Supprimer les noms de tags correspondant à l'expression régulière (Git SHA), toujours en conserver au moins 5 et supprimer ceux qui sont plus anciens que 2 jours :

  ```shell
  curl --request DELETE \
    --data 'name_regex_delete=[0-9a-z]{40}' \
    --data 'keep_n=5' \
    --data 'older_than=2d' \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

- Supprimer tous les tags, mais toujours conserver les 5 plus récents :

  ```shell
  curl --request DELETE \
    --data 'name_regex_delete=.*' \
    --data 'keep_n=5' \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

- Supprimer tous les tags, mais toujours conserver les tags commençant par `stable` :

  ```shell
  curl --request DELETE \
    --data 'name_regex_delete=.*' \
    --data 'name_regex_keep=stable.*' \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

- Supprimer tous les tags qui sont plus anciens que 1 mois :

  ```shell
  curl --request DELETE \
    --data 'name_regex_delete=.*' \
    --data 'older_than=1month' \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
  ```

### Utiliser cURL avec une expression régulière contenant `+` {#use-curl-with-a-regular-expression-that-contains-}

Lors de l'utilisation de cURL, le caractère `+` dans les expressions régulières doit être [encodé en URL](https://curl.se/docs/manpage.html#--data-urlencode) pour être traité correctement par le backend GitLab Rails. Par exemple :

```shell
curl --request DELETE \
  --data-urlencode 'name_regex_delete=dev-.+' \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/registry/repositories/2/tags"
```

## Endpoints à l'échelle de l'instance {#instance-wide-endpoints}

Outre les API GitLab spécifiques aux groupes et aux projets expliquées précédemment, le registre de conteneurs dispose de ses propres endpoints. Pour les interroger, suivez le mécanisme intégré du registre pour obtenir et utiliser un [jeton d'authentification](https://distribution.github.io/distribution/spec/auth/token/).

> [!note]
> Ces jetons sont différents des jetons d'accès au projet ou des jetons d'accès personnels dans l'application GitLab.

### Obtenir un jeton depuis GitLab {#obtain-token-from-gitlab}

```plaintext
GET ${CI_SERVER_URL}/jwt/auth?service=container_registry&scope=*
```

Vous devez spécifier les [portées et actions](https://distribution.github.io/distribution/spec/auth/scope/) correctes pour récupérer un jeton valide :

```shell
SCOPE="repository:${CI_PROJECT_PATH}:delete" # or push, pull

curl --request GET \
  --user "${CI_REGISTRY_USER}:${CI_REGISTRY_PASSWORD}" \
  --url "${CI_SERVER_URL}/jwt/auth?service=container_registry&scope=${SCOPE}"
```

### Supprimer des tags d'image par référence {#delete-image-tags-by-reference}

{{< history >}}

- L'endpoint `v2/<name>/manifests/<tag>` a été [introduit](https://gitlab.com/gitlab-org/container-registry/-/issues/1091) et l'endpoint `v2/<name>/tags/reference/<tag>` a été [rendu obsolète](https://gitlab.com/gitlab-org/container-registry/-/issues/1094) dans GitLab 16.4.

{{< /history >}}

```plaintext
DELETE http(s)://${CI_REGISTRY}/v2/${CI_REGISTRY_IMAGE}/tags/reference/${CI_COMMIT_SHORT_SHA}
```

Vous pouvez utiliser le jeton récupéré avec les variables prédéfinies `CI_REGISTRY_USER` et `CI_REGISTRY_PASSWORD` pour supprimer des tags d'image de conteneur par référence sur votre instance GitLab. La [Container-Registry-Feature](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/docker/v2/api.md#delete-tag) `tag_delete` doit être activée.

```shell
$ curl --request DELETE \
    --header "Authorization: Bearer <token_from_above>" \
    --header "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    --url "https://gitlab.example.com:5050/v2/${CI_REGISTRY_IMAGE}/manifests/${CI_COMMIT_SHORT_SHA}"
```

### Répertorier tous les dépôts de conteneurs {#listing-all-container-repositories}

```plaintext
GET http(s)://${CI_REGISTRY}/v2/_catalog
```

Pour répertorier tous les dépôts de conteneurs sur votre instance GitLab, des identifiants d'administrateur sont requis :

```shell
$ SCOPE="registry:catalog:*"

$ curl --request GET \
    --user "<admin-username>:<admin-password>" \
    --url "https://gitlab.example.com/jwt/auth?service=container_registry&scope=${SCOPE}"
{"token":" ... "}

$ curl --header "Authorization: Bearer <token_from_above>" \
    --url "https://gitlab.example.com:5050/v2/_catalog"
```
