---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des variables de niveau groupe
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Introduction de [`filter`](https://gitlab.com/gitlab-org/gitlab/-/issues/340185) dans GitLab 16.9.

{{< /history >}}

Utilisez cette API pour interagir avec les [variables CI/CD](../ci/variables/_index.md#for-a-group) d'un groupe.

Prérequis :

- Vous devez avoir le rôle Owner pour le groupe.

## Lister toutes les variables de groupe {#list-all-group-variables}

Répertorie toutes les variables d'un groupe spécifié. Utilisez les paramètres de [pagination](rest/_index.md#offset-based-pagination) `page` et `per_page` pour contrôler la pagination des résultats.

```plaintext
GET /groups/:id/variables
```

| Attribut | Type           | Obligatoire | Description |
|-----------|----------------|----------|-------------|
| `id`      | entier ou chaîne | Oui      | L'ID d'un groupe ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe |

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables"
```

```json
[
    {
        "key": "TEST_VARIABLE_1",
        "variable_type": "env_var",
        "value": "TEST_1",
        "protected": false,
        "masked": false,
        "hidden": false,
        "raw": false,
        "environment_scope": "*",
        "description": null
    },
    {
        "key": "TEST_VARIABLE_2",
        "variable_type": "env_var",
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

## Récupérer les détails d'une variable de groupe {#retrieve-details-of-a-group-variable}

{{< history >}}

- Le paramètre `filter` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/340185) dans GitLab 16.9.

{{< /history >}}

Récupère les détails d'une variable de groupe spécifiée. S'il existe plusieurs variables avec la même clé, utilisez `filter` pour sélectionner le bon `environment_scope`.

```plaintext
GET /groups/:id/variables/:key
```

| Attribut | Type              | Obligatoire | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | entier ou chaîne | Oui      | ID d'un groupe ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `key`     | string            | Oui      | Clé d'une variable. |
| `filter`  | hash              | Non       | Filtre les résultats lorsque plusieurs variables partagent la même clé. Valeurs possibles : `[environment_scope]`. GitLab Premium et GitLab Ultimate uniquement. |

Exemple de requête :

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/TEST_VARIABLE_1"
```

```json
{
    "key": "TEST_VARIABLE_1",
    "variable_type": "env_var",
    "value": "TEST_1",
    "protected": false,
    "masked": false,
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
  --url "https://gitlab.example.com/api/v4/groups/1/variables/SCOPED_VARIABLE_1" \
  --form "filter[environment_scope]=production"
```

## Créer une variable de groupe {#create-a-group-variable}

{{< history >}}

- Les attributs `masked_and_hidden` et `hidden` ont été [introduits](https://gitlab.com/gitlab-org/gitlab/-/issues/29674) dans GitLab 17.4.

{{< /history >}}

Crée une variable de groupe.

```plaintext
POST /groups/:id/variables
```

| Attribut           | Type              | Obligatoire | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | entier ou chaîne | Oui      | L'ID d'un groupe ou le [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `key`               | string            | Oui      | La `key` d'une variable. Maximum 255 caractères. Seuls `A-Z`, `a-z`, `0-9` et `_` sont autorisés. |
| `value`             | string            | Oui      | La `value` d'une variable. |
| `description`       | string            | Non       | La `description` de la variable. Maximum 255 caractères. Par défaut : `null`. |
| `environment_scope` | string            | Non       | La [portée d'environnement](../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable) d'une variable. GitLab Premium et GitLab Ultimate uniquement. |
| `masked`            | boolean           | Non       | Indique si la variable est masquée. |
| `masked_and_hidden` | boolean           | Non       | Indique si la variable est masquée et cachée. Par défaut : `false` |
| `protected`         | boolean           | Non       | Indique si la variable est protégée. |
| `raw`               | boolean           | Non       | Indique si la variable est traitée comme une chaîne brute. Par défaut : `true`. Lorsque `false`, les variables dans la valeur sont [développées](../ci/variables/_index.md#allow-cicd-variable-expansion). |
| `variable_type`     | string            | Non       | Le type d'une variable. Les types disponibles sont : `env_var` (par défaut) et `file`. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables" \
  --form "key=NEW_VARIABLE" \
  --form "value=new value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "new value",
    "variable_type": "env_var",
    "protected": false,
    "masked": false,
    "hidden": false,
    "raw": false,
    "environment_scope": "*",
    "description": null
}
```

## Mettre à jour une variable de groupe {#update-a-group-variable}

{{< history >}}

- Le paramètre `filter` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/340185) dans GitLab 16.9.

{{< /history >}}

Met à jour la variable de groupe spécifiée. S'il existe plusieurs variables avec la même clé, utilisez `filter` pour sélectionner le bon `environment_scope`.

> [!warning]
> Lors du filtrage pour un `environment_scope` qui n'existe pas, le point de terminaison se rabat sur la mise à jour d'une variable portant le même nom mais avec une portée d'environnement différente. Vérifiez l'existence d'une portée pour une variable donnée en utilisant le point de terminaison [récupérer les détails d'une variable de groupe](#retrieve-details-of-a-group-variable).

```plaintext
PUT /groups/:id/variables/:key
```

| Attribut           | Type              | Obligatoire | Description |
| ------------------- | ----------------- | -------- | ----------- |
| `id`                | entier ou chaîne | Oui      | ID d'un groupe ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `key`               | string            | Oui      | Clé d'une variable. |
| `value`             | string            | Oui      | Valeur d'une variable. |
| `description`       | string            | Non       | Description de la variable. [Introduction](https://gitlab.com/gitlab-org/gitlab/-/issues/409641) dans GitLab 16.2. Par défaut : `null`. |
| `environment_scope` | string            | Non       | [Portée d'environnement](../ci/environments/_index.md#limit-the-environment-scope-of-a-cicd-variable) d'une variable. GitLab Premium et GitLab Ultimate uniquement. |
| `filter`            | hash              | Non       | Filtre les résultats lorsque plusieurs variables partagent la même clé. Valeurs possibles : `[environment_scope]`. GitLab Premium et GitLab Ultimate uniquement. |
| `masked`            | boolean           | Non       | Si `true`, indique que la variable est masquée. |
| `protected`         | boolean           | Non       | Si `true`, indique que la variable est protégée. |
| `raw`               | boolean           | Non       | Si `true`, indique que la variable est traitée comme une chaîne brute. Lorsque `false`, la valeur de la variable est [développée](../ci/variables/_index.md#allow-cicd-variable-expansion). Par défaut : `true`. |
| `variable_type`     | string            | Non       | Type d'une variable. Les types disponibles sont : `env_var` (par défaut) et `file`. |

Exemple de requête :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/NEW_VARIABLE" \
  --form "value=updated value"
```

```json
{
    "key": "NEW_VARIABLE",
    "value": "updated value",
    "variable_type": "env_var",
    "protected": true,
    "masked": true,
    "hidden": false,
    "raw": true,
    "environment_scope": "*",
    "description": null
}
```

Exemple de requête avec `filter` :

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/SCOPED_VARIABLE_1" \
  --form "value=updated value" \
  --form "environment_scope=production" \
  --form "filter[environment_scope]=production"
```

## Supprimer une variable de groupe {#delete-a-group-variable}

{{< history >}}

- Le paramètre `filter` a été [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/340185) dans GitLab 16.9.

{{< /history >}}

Supprime la variable de groupe spécifiée. S'il existe plusieurs variables avec la même clé, utilisez `filter` pour sélectionner le bon `environment_scope`.

```plaintext
DELETE /groups/:id/variables/:key
```

| Attribut | Type              | Obligatoire | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | entier ou chaîne | Oui      | ID d'un groupe ou [chemin encodé en URL](rest/_index.md#namespaced-paths) du groupe. |
| `key`     | string            | Oui      | Clé d'une variable. |
| `filter`  | hash              | Non       | Filtre les résultats lorsque plusieurs variables partagent la même clé. Valeurs possibles : `[environment_scope]`. GitLab Premium et GitLab Ultimate uniquement. |

Exemple de requête :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/VARIABLE_1"
```

Exemple de requête avec `filter` :

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/groups/1/variables/SCOPED_VARIABLE_1" \
  --form "filter[environment_scope]=production"
```
