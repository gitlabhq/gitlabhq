---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "API des variables CI/CD au niveau de l'instance"
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les [variables CI/CD](../ci/variables/_index.md#for-an-instance) de votre instance.

## Lister toutes les variables d'instance {#list-all-instance-variables}

{{< history >}}

- Paramètre `description` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/418331) dans GitLab 16.8.

{{< /history >}}

Répertorie toutes les variables CI/CD au niveau de l'instance. Utilisez les paramètres de [pagination](rest/_index.md#offset-based-pagination) `page` et `per_page` pour contrôler la pagination des résultats.

```plaintext
GET /admin/ci/variables
```

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ci/variables"
```

```json
[
    {
        "key": "TEST_VARIABLE_1",
        "description": null,
        "variable_type": "env_var",
        "value": "TEST_1",
        "protected": false,
        "masked": false,
        "raw": false
    },
    {
        "key": "TEST_VARIABLE_2",
        "description": null,
        "variable_type": "env_var",
        "value": "TEST_2",
        "protected": false,
        "masked": false,
        "raw": false
    }
]
```

## Récupérer les détails d'une variable d'instance {#retrieve-instance-variable-details}

{{< history >}}

- Paramètre `description` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/418331) dans GitLab 16.8.

{{< /history >}}

Récupère les détails d'une variable CI/CD au niveau de l'instance spécifique.

```plaintext
GET /admin/ci/variables/:key
```

| Attribut | Type    | Obligatoire | Description |
|-----------|---------|----------|-------------|
| `key`     | string  | Oui      | La `key` d'une variable |

```shell
curl \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ci/variables/TEST_VARIABLE_1"
```

```json
{
    "key": "TEST_VARIABLE_1",
    "description": null,
    "variable_type": "env_var",
    "value": "TEST_1",
    "protected": false,
    "masked": false,
    "raw": false
}
```

## Créer une variable d'instance {#create-instance-variable}

{{< history >}}

- Paramètre `description` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/418331) dans GitLab 16.8.

{{< /history >}}

Crée une nouvelle variable CI/CD au niveau de l'instance.

Le [nombre maximum de variables au niveau de l'instance](../administration/cicd/limits.md#instance-cicd-variable-limit) peut être modifié.

```plaintext
POST /admin/ci/variables
```

| Attribut       | Type    | Obligatoire | Description |
|-----------------|---------|----------|-------------|
| `key`           | string  | Oui      | La `key` de la variable. Maximum de 255 caractères, seuls `A-Z`, `a-z`, `0-9` et `_` sont autorisés. |
| `value`         | string  | Oui      | La `value` de la variable. Maximum de 10 000 caractères. |
| `description`   | string  | Non       | La description de la variable. Maximum de 255 caractères. |
| `masked`        | boolean | Non       | Indique si la variable est masquée. |
| `protected`     | boolean | Non       | Indique si la variable est protégée. |
| `raw`           | boolean | Non       | Indique si la variable est développable. |
| `variable_type` | string  | Non       | Le type de la variable. Les types disponibles sont : `env_var` (par défaut) et `file`. |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ci/variables" \
  --form "key=NEW_VARIABLE" \
  --form "value=new value"
```

```json
{
    "key": "NEW_VARIABLE",
    "description": null,
    "value": "new value",
    "variable_type": "env_var",
    "protected": false,
    "masked": false,
    "raw": false
}
```

## Mettre à jour une variable d'instance {#update-instance-variable}

{{< history >}}

- Paramètre `description` [introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/418331) dans GitLab 16.8.

{{< /history >}}

Met à jour une variable CI/CD au niveau de l'instance.

```plaintext
PUT /admin/ci/variables/:key
```

| Attribut       | Type    | Obligatoire | Description |
|-----------------|---------|----------|-------------|
| `description`   | string  | Non       | La description de la variable. Maximum de 255 caractères. |
| `key`           | string  | Oui      | La `key` de la variable. Maximum de 255 caractères, seuls `A-Z`, `a-z`, `0-9` et `_` sont autorisés. |
| `masked`        | boolean | Non       | Indique si la variable est masquée. |
| `protected`     | boolean | Non       | Indique si la variable est protégée. |
| `raw`           | boolean | Non       | Indique si la variable est développable. |
| `value`         | string  | Oui      | La `value` de la variable. Maximum de 10 000 caractères. |
| `variable_type` | string  | Non       | Le type de la variable. Les types disponibles sont : `env_var` (par défaut) et `file`. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ci/variables/NEW_VARIABLE" \
  --form "value=updated value"
```

```json
{
    "key": "NEW_VARIABLE",
    "description": null,
    "value": "updated value",
    "variable_type": "env_var",
    "protected": true,
    "masked": true,
    "raw": true
}
```

## Supprimer une variable d'instance {#delete-instance-variable}

Supprime une variable CI/CD au niveau de l'instance.

```plaintext
DELETE /admin/ci/variables/:key
```

| Attribut | Type   | Obligatoire | Description |
|-----------|--------|----------|-------------|
| `key`     | string | Oui      | La `key` d'une variable |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/admin/ci/variables/VARIABLE_1"
```
