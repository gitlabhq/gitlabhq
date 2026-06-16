---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API Applications
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les applications OAuth à l'échelle de l'instance qui :

- [Utilisent GitLab comme fournisseur d'authentification](../integration/oauth_provider.md).
- [Permettent l'accès aux ressources GitLab au nom d'un utilisateur](oauth2.md).

> [!note]
> Vous ne pouvez pas utiliser cette API pour gérer les applications de groupe ou les applications utilisateur individuelles.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

## Créer une application {#create-an-application}

Crée une application.

Renvoie `200` si la requête aboutit.

```plaintext
POST /applications
```

Attributs pris en charge :

| Attribut      | Type    | Obligatoire | Description                      |
|:---------------|:--------|:---------|:---------------------------------|
| `name`         | string  | oui      | Nom de l'application.         |
| `redirect_uri` | string  | oui      | URI de redirection de l'application. |
| `scopes`       | string  | oui      | Portées disponibles pour l'application. Séparez plusieurs portées par un espace. |
| `confidential` | boolean | non       | Si `true`, l'application peut stocker de manière sécurisée les informations d'identification du client, telles que le secret client. Les applications non confidentielles (telles que les applications mobiles natives et les applications à page unique) peuvent exposer les informations d'identification du client. Par défaut, la valeur est `true` si non spécifiée. |

Exemple de requête :

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --data "name=MyApplication&redirect_uri=http://redirect.uri&scopes=api read_user email" \
    --url "https://gitlab.example.com/api/v4/applications"
```

Exemple de réponse :

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "MyApplication",
    "secret": "ee1dd64b6adc89cf7e2c23099301ccc2c61b441064e9324d963c46902a85ec34",
    "callback_url": "http://redirect.uri",
    "confidential": true,
    "scopes": ["api", "read_user", "email"]
}
```

## Lister toutes les applications {#list-all-applications}

Liste toutes les applications.

```plaintext
GET /applications
```

Exemple de requête :

```shell
curl --request GET \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/applications"
```

Exemple de réponse :

```json
[
    {
        "id":1,
        "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
        "application_name": "MyApplication",
        "callback_url": "http://redirect.uri",
        "confidential": true,
        "scopes": ["api", "read_user"]
    }
]
```

> [!note]
> La valeur `secret` n'est pas exposée par cette API.

## Supprimer une application {#delete-an-application}

Supprime une application spécifiée.

Renvoie `204` si la requête aboutit.

```plaintext
DELETE /applications/:id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description                                         |
|:----------|:--------|:---------|:----------------------------------------------------|
| `id`      | integer | oui      | L'ID de l'application (pas le `application_id`). |

Exemple de requête :

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/applications/:id"
```

## Renouveler le secret d'une application {#renew-an-application-secret}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/422420) dans GitLab 16.11.

{{< /history >}}

Renouvelle le secret d'une application spécifiée. Renvoie `200` si la requête aboutit.

```plaintext
POST /applications/:id/renew-secret
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description                                         |
|:----------|:--------|:---------|:----------------------------------------------------|
| `id`      | integer | oui      | L'ID de l'application (pas le `application_id`). |

Exemple de requête :

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/applications/:id/renew-secret"
```

Exemple de réponse :

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "MyApplication",
    "secret": "ee1dd64b6adc89cf7e2c23099301ccc2c61b441064e9324d963c46902a85ec34",
    "callback_url": "http://redirect.uri",
    "confidential": true,
    "scopes": ["api", "read_user"]
}
```
