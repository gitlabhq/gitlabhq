---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
gitlab_dedicated: yes
title: API de licence
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les endpoints de licence. Pour plus d'informations, voir [activer GitLab EE avec un fichier de licence ou une clé](../administration/license_file.md).

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

## Récupérer les informations de licence {#retrieve-license-information}

Récupère les informations sur la licence actuelle.

```plaintext
GET /license
```

```json
{
  "id": 2,
  "plan": "ultimate",
  "created_at": "2018-02-27T23:21:58.674Z",
  "starts_at": "2018-01-27",
  "expires_at": "2022-01-27",
  "historical_max": 300,
  "maximum_user_count": 300,
  "expired": false,
  "overage": 200,
  "user_limit": 100,
  "active_users": 300,
  "licensee": {
    "Name": "John Doe1",
    "Email": "johndoe1@gitlab.com",
    "Company": "GitLab"
  },
  "add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  }
}
```

## Lister toutes les licences {#list-all-licenses}

Liste les informations sur toutes les licences.

```plaintext
GET /licenses
```

```json
[
  {
    "id": 1,
    "plan": "premium",
    "created_at": "2018-02-27T23:21:58.674Z",
    "starts_at": "2018-01-27",
    "expires_at": "2022-01-27",
    "historical_max": 300,
    "maximum_user_count": 300,
    "expired": false,
    "overage": 200,
    "user_limit": 100,
    "licensee": {
      "Name": "John Doe1",
      "Email": "johndoe1@gitlab.com",
      "Company": "GitLab"
    },
    "add_ons": {
      "GitLab_FileLocks": 1,
      "GitLab_Auditor_User": 1
    }
  },
  {
    "id": 2,
    "plan": "ultimate",
    "created_at": "2018-02-27T23:21:58.674Z",
    "starts_at": "2018-01-27",
    "expires_at": "2022-01-27",
    "historical_max": 300,
    "maximum_user_count": 300,
    "expired": false,
    "overage": 200,
    "user_limit": 100,
    "licensee": {
      "Name": "Doe John",
      "Email": "doejohn@gitlab.com",
      "Company": "GitLab"
    },
    "add_ons": {
      "GitLab_FileLocks": 1
    }
  }
]
```

Le dépassement correspond à la différence entre le nombre d'utilisateurs facturables et le nombre d'utilisateurs sous licence. Ce calcul diffère selon que la licence a expiré ou non.

- Si la licence a expiré, le système utilise le nombre maximal historique d'utilisateurs facturables (`historical_max`).
- Si la licence n'a pas expiré, il utilise le nombre actuel d'utilisateurs facturables.

Retourne :

- `200 OK` avec une réponse contenant les licences au format JSON. Il s'agit d'un tableau JSON vide s'il n'y a pas de licences.
- `403 Forbidden` si l'utilisateur actuel n'est pas autorisé à lire les licences.

## Récupérer une licence {#retrieve-a-license}

Récupère les informations sur une licence spécifiée.

```plaintext
GET /license/:id
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description               |
|-----------|---------|----------|---------------------------|
| `id`      | entier | oui      | ID de la licence GitLab. |

Retourne les codes de statut suivants :

- `200 OK` :  La réponse contient les licences au format JSON.
- `404 Not Found` :  La licence demandée n'existe pas.
- `403 Forbidden` :  L'utilisateur actuel n'est pas autorisé à lire les licences.

Exemple de requête :

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/license/:id"
```

Exemple de réponse :

```json
{
  "id": 1,
  "plan": "premium",
  "created_at": "2018-02-27T23:21:58.674Z",
  "starts_at": "2018-01-27",
  "expires_at": "2022-01-27",
  "historical_max": 300,
  "maximum_user_count": 300,
  "expired": false,
  "overage": 200,
  "user_limit": 100,
  "active_users": 50,
  "licensee": {
    "Name": "John Doe1",
    "Email": "johndoe1@gitlab.com",
    "Company": "GitLab"
  },
  "add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  }
}
```

## Créer une licence {#create-a-license}

Crée une nouvelle licence.

```plaintext
POST /license
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `license` | string | oui | La chaîne de licence |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/license?license=eyJkYXRhIjoiMHM5Q...S01Udz09XG4ifQ=="
```

Exemple de réponse :

```json
{
  "id": 1,
  "plan": "ultimate",
  "created_at": "2018-02-27T23:21:58.674Z",
  "starts_at": "2018-01-27",
  "expires_at": "2022-01-27",
  "historical_max": 300,
  "maximum_user_count": 300,
  "expired": false,
  "overage": 200,
  "user_limit": 100,
  "active_users": 300,
  "licensee": {
    "Name": "John Doe1",
    "Email": "johndoe1@gitlab.com",
    "Company": "GitLab"
  },
  "add_ons": {
    "GitLab_FileLocks": 1,
    "GitLab_Auditor_User": 1
  }
}
```

Retourne :

- `201 Created` si la licence est ajoutée avec succès.
- `400 Bad Request` si la licence n'a pas pu être ajoutée, avec un message d'erreur expliquant la raison.

## Supprimer une licence {#delete-a-license}

Supprime une licence spécifiée.

```plaintext
DELETE /license/:id
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier | oui | ID de la licence GitLab. |

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/license/:id"
```

Retourne :

- `204 No Content` si la licence est supprimée avec succès.
- `403 Forbidden` si l'utilisateur actuel n'est pas autorisé à supprimer la licence.
- `404 Not Found` si la licence à supprimer est introuvable.

## Déclencher le recalcul des utilisateurs facturables {#trigger-recalculation-of-billable-users}

Déclenche le recalcul des utilisateurs facturables pour une licence spécifiée.

```plaintext
PUT /license/:id/refresh_billable_users
```

| Attribut | Type | Obligatoire | Description |
| --------- | ---- | -------- | ----------- |
| `id` | entier | oui | ID de la licence GitLab. |

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/license/:id/refresh_billable_users"
```

Exemple de réponse :

```json
{
  "success": true
}
```

Retourne :

- `202 Accepted` si la demande d'actualisation des utilisateurs facturables est lancée avec succès.
- `403 Forbidden` si l'utilisateur actuel n'est pas autorisé à actualiser les utilisateurs facturables pour la licence.
- `404 Not Found` si la licence est introuvable.

| Attribut                    | Type          | Description                               |
|:-----------------------------|:--------------|:------------------------------------------|
| `success`                    | boolean       | Indique si la demande a réussi ou non.     |

## Récupérer les informations d'utilisation de la licence {#retrieve-license-usage-information}

Récupère les informations d'utilisation de la licence actuelle et les exporte au format CSV.

```plaintext
GET /license/usage_export.csv
```

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/license/usage_export.csv"
```

Exemple de réponse :

```plaintext
License Key,"eyJkYXRhIjoib1EwRWZXU3RobDY2Yl=
"
Email,user@example.com
License Start Date,2023-02-22
License End Date,2024-02-22
Company,Example Corp.
Generated At,2023-09-05 06:56:23
"",""
Date,Billable User Count
2023-07-11 12:00:05,21
2023-07-13 12:00:06,21
2023-08-16 12:00:02,21
2023-09-04 12:00:12,21
```

Retourne :

- `200 OK` :  La réponse contient l'utilisation de la licence au format CSV.
- `403 Forbidden` si l'utilisateur actuel n'est pas autorisé à consulter l'utilisation de la licence.
