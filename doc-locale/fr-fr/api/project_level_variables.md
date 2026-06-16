---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des variables CI/CD au niveau du projet
---

{{< details >}}

- Édition : Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [`filter`](https://gitlab.com/gitlab-org/gitlab/-/issues/340185) introduit dans GitLab 16.9.

{{< /history >}}

Utilisez cette API pour interagir avec les [variables CI/CD](../ci/variables/_index.md#for-a-project) d'un projet.

## Lister les variables du projet {#list-project-variables}

Répertorie toutes les variables d'un projet. Utilisez les paramètres de [pagination](rest/_index.md#offset-based-pagination) `page` et `per_page` pour contrôler la pagination des résultats.

```plaintext
GET /projects/:id/variables
```

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables"
```

Exemple de réponse :

```json
[
    {
        "variable_type": "env_var",
        "key": "TEST_VARIABLE_1",
        "value": "TEST_1",
        "protected": false,
        "masked": true,
        "hidden": false,
        "raw": false,
        "environment_scope": "*",
        "description": null
    },
    {
        "variable_type": "env_var",
        "key": "TEST_VARIABLE_2",
        "value": "TEST_2",
        "protected": false,
        "masked": false,
        "hidden": false,
        "raw": false,
        "environment_scope": "*",
        "description": null
    }
]
```

## Récupérer une variable unique {#retrieve-a-single-variable}

Récupère les détails d'une variable unique. S'il existe plusieurs variables avec la même clé, utilisez `filter` pour sélectionner le bon `environment_scope`.

```plaintext
GET /projects/:id/variables/:key
```

| Attribut | Type              | Obligatoire | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `key`     | string            | Oui      | Clé d'une variable. |
| `filter`  | hash              | Non       | Filtre les résultats lorsque plusieurs variables partagent la même clé. Valeurs possibles : `[environment_scope]`. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables/TEST_VARIABLE_1"
```

Exemple de réponse :

```json
{
    "key": "TEST_VARIABLE_1",
    "variable_type": "env_var",
    "value": "TEST_1",
    "protected": false,
    "masked": true,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": null
}
```

Exemple de requête avec `filter` :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables/SCOPED_VARIABLE_1" \
  --form "filter[environment_scope]=production"
```

## Créer une variable {#create-a-variable}

{{< history >}}

- Les attributs `masked_and_hidden` et `hidden` [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/29674) dans GitLab 17.4.

{{< /history >}}

Crée une nouvelle variable. Si une variable avec le même `key` existe déjà, la nouvelle variable doit avoir un `environment_scope` différent. Sinon, GitLab renvoie un message similaire à : `VARIABLE_NAME has already been taken`.

```plaintext
POST /projects/:id/variables
```

| Attribut           | Type           | Obligatoire | Description |
|---------------------|----------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | ID ou [chemin encodé en URL du projet](rest/_index.md#namespaced-paths) |
| `key`               | string         | Oui      | Le `key` d'une variable ; ne doit pas dépasser 255 caractères ; seuls `A-Z`, `a-z`, `0-9` et `_` sont autorisés |
| `value`             | string         | Oui      | La `value` d'une variable |
| `description`       | string         | Non       | La description de la variable. Par défaut : `null`. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/409641) dans GitLab 16.2. |
| `environment_scope` | string         | Non       | Le `environment_scope` de la variable. Par défaut : `*` |
| `masked`            | boolean        | Non       | Indique si la variable est masquée. Par défaut : `false` |
| `masked_and_hidden` | boolean        | Non       | Indique si la variable est masquée et cachée. Par défaut : `false` |
| `protected`         | boolean        | Non       | Indique si la variable est protégée. Par défaut : `false` |
| `raw`               | boolean        | Non       | Indique si la variable est traitée comme une chaîne brute. Par défaut : `true`. Lorsque la valeur est `false`, les variables dans la valeur sont [développées](../ci/variables/_index.md#allow-cicd-variable-expansion). |
| `variable_type`     | string         | Non       | Le type d'une variable. Les types disponibles sont : `env_var` (par défaut) et `file` |

Exemple de requête :

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables" \
  --form "key=NEW_VARIABLE" \
  --form "value=new value"
```

Exemple de réponse :

```json
{
    "variable_type": "env_var",
    "key": "NEW_VARIABLE",
    "value": "new value",
    "protected": false,
    "masked": false,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": null
}
```

## Mettre à jour une variable {#update-a-variable}

Met à jour une variable CI/CD de projet. S'il existe plusieurs variables avec la même clé, utilisez `filter` pour sélectionner le bon `environment_scope`.

```plaintext
PUT /projects/:id/variables/:key
```

| Attribut           | Type              | Obligatoire | Description |
| ------------------- | ----------------- | -------- | ----------- |
| `id`                | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `key`               | string            | Oui      | Clé d'une variable. |
| `value`             | string            | Oui      | Valeur d'une variable. |
| `description`       | string            | Non       | Description de la variable. [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/409641) dans GitLab 16.2. Par défaut : `null`. |
| `environment_scope` | string            | Non       | Portée d'environnement de la variable. |
| `filter`            | hash              | Non       | Filtre les résultats lorsque plusieurs variables partagent la même clé. Valeurs possibles : `[environment_scope]`. |
| `masked`            | boolean           | Non       | Si `true`, indique que la variable est masquée. |
| `protected`         | boolean           | Non       | Si `true`, indique que la variable est protégée. |
| `raw`               | boolean           | Non       | Si `true`, indique que la variable est traitée comme une chaîne brute. Lorsque la valeur est `false`, la valeur de la variable est [développée](../ci/variables/_index.md#allow-cicd-variable-expansion). Par défaut : `true`. |
| `variable_type`     | string            | Non       | Type d'une variable. Les types disponibles sont : `env_var` (par défaut) et `file`. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables/NEW_VARIABLE" \
  --form "value=updated value"
```

Exemple de réponse :

```json
{
    "variable_type": "env_var",
    "key": "NEW_VARIABLE",
    "value": "updated value",
    "protected": true,
    "masked": false,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": "null"
}
```

Exemple de requête avec `filter` :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/variables/SCOPED_VARIABLE_1" \
  --form "value=updated value" \
  --form "environment_scope=production" \
  --form "filter[environment_scope]=production"
```

## Supprimer une variable {#delete-a-variable}

Supprime une variable CI/CD de projet. S'il existe plusieurs variables avec la même clé, utilisez `filter` pour sélectionner le bon `environment_scope`.

```plaintext
DELETE /projects/:id/variables/:key
```

| Attribut | Type              | Obligatoire | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | entier ou chaîne | Oui      | ID ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du projet. |
| `key`     | string            | Oui      | Clé d'une variable. |
| `filter`  | hash              | Non       | Filtre les résultats lorsque plusieurs variables partagent la même clé. Valeurs possibles : `[environment_scope]`. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>"
  --url "https://gitlab.example.com/api/v4/projects/1/variables/VARIABLE_1"
```

Exemple de requête avec `filter` :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>"
  --url "https://gitlab.example.com/api/v4/projects/1/variables/SCOPED_VARIABLE_1" \
  --form "filter[environment_scope]=production"
```
