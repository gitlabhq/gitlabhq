---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API des adresses e-mail des utilisateurs
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour interagir avec les adresses e-mail des comptes utilisateur. Pour plus d'informations, consultez [Compte utilisateur](../user/profile/_index.md).

## Lister toutes les adresses e-mail {#list-all-email-addresses}

Liste toutes les adresses e-mail de votre compte utilisateur.

Prérequis :

- Vous devez être authentifié.

```plaintext
GET /user/emails
```

Exemple de réponse :

```json
[
  {
    "id": 1,
    "email": "email@example.com",
    "confirmed_at": "2021-03-26T19:07:56.248Z"
  },
  {
    "id": 3,
    "email": "email2@example.com",
    "confirmed_at": null
  }
]
```

## Lister toutes les adresses e-mail d'un utilisateur {#list-all-email-addresses-for-a-user}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Liste toutes les adresses e-mail d'un compte utilisateur spécifié.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
GET /users/:id/emails
```

Attributs pris en charge :

| Attribut | Type    | Obligatoire | Description |
|:----------|:--------|:---------|:------------|
| `id`      | integer | oui      | ID du compte utilisateur |

## Récupérer les détails d'une adresse e-mail {#retrieve-details-on-an-email-address}

Récupère les détails d'une adresse e-mail spécifiée pour votre compte utilisateur.

```plaintext
GET /user/emails/:email_id
```

Attributs pris en charge :

| Attribut  | Type    | Obligatoire | Description |
|:-----------|:--------|:---------|:------------|
| `email_id` | integer | oui      | ID de l'adresse e-mail |

Exemple de réponse :

```json
{
  "id": 1,
  "email": "email@example.com",
  "confirmed_at": "2021-03-26T19:07:56.248Z"
}
```

## Ajouter une adresse e-mail {#add-an-email-address}

Ajoute une adresse e-mail à votre compte utilisateur.

```plaintext
POST /user/emails
```

Attributs pris en charge :

| Attribut | Type   | Obligatoire | Description |
|:----------|:-------|:---------|:------------|
| `email`   | string | oui      | Adresse e-mail |

```json
{
  "id": 4,
  "email": "email@example.com",
  "confirmed_at": "2021-03-26T19:07:56.248Z"
}
```

Renvoie l'e-mail créé avec le statut `201 Created` en cas de succès. Si une erreur se produit, un `400 Bad Request` est renvoyé avec un message expliquant l'erreur :

```json
{
  "message": {
    "email": [
      "has already been taken"
    ]
  }
}
```

## Ajouter une adresse e-mail pour un utilisateur {#add-an-email-address-for-a-user}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Ajoute une adresse e-mail à un compte utilisateur spécifié.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
POST /users/:id/emails
```

Attributs pris en charge :

| Attribut           | Type    | Obligatoire | Description |
|:--------------------|:--------|:---------|:------------|
| `id`                | string  | oui      | ID du compte utilisateur|
| `email`             | string  | oui      | Adresse e-mail |
| `skip_confirmation` | boolean | non       | Ignorer la confirmation et considérer l'adresse e-mail comme vérifiée. Valeurs possibles : `true`, `false`. Valeur par défaut : `false`. |

## Supprimer une adresse e-mail {#delete-an-email-address}

Supprime une adresse e-mail de votre compte utilisateur. Vous ne pouvez pas supprimer une adresse e-mail principale.

Tous les futurs e-mails envoyés à l'adresse e-mail supprimée sont envoyés à l'adresse e-mail principale à la place.

Prérequis :

- Vous devez être authentifié.

```plaintext
DELETE /user/emails/:email_id
```

Attributs pris en charge :

| Attribut  | Type    | Obligatoire | Description |
|:-----------|:--------|:---------|:------------|
| `email_id` | integer | oui      | ID de l'adresse e-mail |

Renvoie :

- `204 No Content` si l'opération a réussi.
- `404` si la ressource est introuvable.

## Supprimer une adresse e-mail pour un utilisateur {#delete-an-email-address-for-a-user}

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre : GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Supprime une adresse e-mail d'un compte utilisateur spécifié. Vous ne pouvez pas supprimer une adresse e-mail principale.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
DELETE /users/:id/emails/:email_id
```

Attributs pris en charge :

| Attribut  | Type    | Obligatoire | Description |
|:-----------|:--------|:---------|:------------|
| `id`       | integer | oui      | ID du compte utilisateur |
| `email_id` | integer | oui      | ID de l'adresse e-mail |
