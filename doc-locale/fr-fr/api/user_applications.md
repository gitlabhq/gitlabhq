---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des applications utilisateur
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour gérer les applications OAuth au niveau utilisateur qui :

- [Utilisent GitLab comme fournisseur d'authentification](../integration/oauth_provider.md).
- [Permettent l'accès aux ressources GitLab au nom d'un utilisateur](oauth2.md).

> [!note]
> Pour gérer les applications à l'échelle de l'instance, utilisez l'[API Applications](applications.md).

Prérequis :

- Accès administrateur ou authentifié en tant qu'utilisateur propriétaire de l'application.

## Créer une application {#create-an-application}

Crée une nouvelle application OAuth pour l'utilisateur authentifié.

Renvoie `201` si la requête aboutit.

```plaintext
POST /user/applications
```

Attributs pris en charge :

| Attribut      | Type    | Obligatoire | Description                      |
|:---------------|:--------|:---------|:---------------------------------|
| `name`         | string  | oui      | Nom de l'application.         |
| `redirect_uri` | string  | oui      | URI de redirection de l'application. |
| `scopes`       | string  | oui      | Portées disponibles pour l'application. Séparez plusieurs portées par un espace. |
| `confidential` | boolean | non       | Si `true`, l'application peut stocker en toute sécurité les informations d'identification du client, telles que le secret client. Les applications non confidentielles (telles que les applications mobiles natives et les applications monopages) peuvent exposer les informations d'identification du client. Si non spécifié, la valeur par défaut est `true`. |

Exemple de requête :

```shell
curl --request POST \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --data "name=MyApplication&redirect_uri=http://redirect.uri&scopes=api read_user email" \
    --url "https://gitlab.example.com/api/v4/user/applications"
```

Exemple de réponse :

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "MyApplication",
    "secret": "ee1dd64b6adc89cf7e2c23099301ccc2c61b441064e9324d963c46902a85ec34",
    "callback_url": "http://redirect.uri",
    "confidential": true
}
```

## Lister toutes les applications {#list-all-applications}

Liste toutes les applications appartenant à l'utilisateur authentifié.

```plaintext
GET /user/applications
```

Exemple de requête :

```shell
curl --request GET \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/user/applications"
```

Exemple de réponse :

```json
[
    {
        "id":1,
        "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
        "application_name": "MyApplication",
        "callback_url": "http://redirect.uri",
        "confidential": true
    }
]
```

## Récupérer une application spécifique {#retrieve-a-specific-application}

Récupère les détails d'une application spécifique appartenant à l'utilisateur authentifié.

Renvoie `200` si la requête aboutit.

```plaintext
GET /user/applications/:id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description                                         |
|:----------|:--------|:---------|:----------------------------------------------------|
| `id`      | integer | oui      | ID de l'application. Diffère du `application_id`. |

Exemple de requête :

```shell
curl --request GET \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/user/applications/:id"
```

Exemple de réponse :

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "MyApplication",
    "callback_url": "http://redirect.uri",
    "confidential": true
}
```

## Mettre à jour une application {#update-an-application}

Met à jour une application existante appartenant à l'utilisateur authentifié.

Renvoie `200` si la requête aboutit.

```plaintext
PUT /user/applications/:id
```

Attributs pris en charge :

| Attribut      | Type    | Obligatoire | Description                      |
|:---------------|:--------|:---------|:---------------------------------|
| `id`           | integer | oui      | ID de l'application. Diffère du `application_id`. |
| `name`         | string  | non       | Nom de l'application.         |
| `scopes`       | string  | non       | Portées disponibles pour l'application. Séparez plusieurs portées par un espace. |

Exemple de requête :

```shell
curl --request PUT \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --data "name=UpdatedApplication" \
    --url "https://gitlab.example.com/api/v4/user/applications/:id"
```

Exemple de réponse :

```json
{
    "id":1,
    "application_id": "5832fc6e14300a0d962240a8144466eef4ee93ef0d218477e55f11cf12fc3737",
    "application_name": "UpdatedApplication",
    "callback_url": "http://redirect.uri",
    "confidential": true
}
```

## Supprimer une application {#delete-an-application}

Supprime une application spécifiée appartenant à l'utilisateur authentifié.

Renvoie `204` si la requête aboutit.

```plaintext
DELETE /user/applications/:id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description                                         |
|:----------|:--------|:---------|:----------------------------------------------------|
| `id`      | integer | oui      | ID de l'application. Diffère du `application_id`. |

Exemple de requête :

```shell
curl --request DELETE \
    --header "PRIVATE-TOKEN: <your_access_token>" \
    --url "https://gitlab.example.com/api/v4/user/applications/:id"
```
