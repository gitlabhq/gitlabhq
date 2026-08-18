---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: API de modération des utilisateurs
---

{{< details >}}

- Édition :  Gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Utilisez cette API pour modérer les comptes utilisateurs. Pour plus d'informations, voir [Modérer les utilisateurs](../administration/moderate_users.md).

## Approuver l'accès d'un utilisateur {#approve-access-to-a-user}

Approuve l'accès à un compte utilisateur spécifié qui est en attente d'approbation.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
POST /users/:id/approve
```

Attributs pris en charge :

| Attribut  | Type    | Obligatoire | Description        |
|------------|---------|----------|--------------------|
| `id`       | integer | oui      | ID du compte utilisateur |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/approve"
```

Retourne :

- `201 Created` en cas de succès.
- `404 User Not Found` si l'utilisateur est introuvable.
- `403 Forbidden` si l'utilisateur ne peut pas être approuvé parce qu'il est bloqué par un administrateur ou par la synchronisation LDAP.
- `409 Conflict` si l'utilisateur a été désactivé.

Exemples de réponses :

```json
{ "message": "Success" }
```

```json
{ "message": "404 User Not Found" }
```

```json
{ "message": "The user you are trying to approve is not pending approval" }
```

## Rejeter l'accès d'un utilisateur {#reject-access-to-a-user}

Rejette l'accès à un compte utilisateur spécifié qui est en attente d'approbation.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
POST /users/:id/reject
```

Attributs pris en charge :

| Attribut  | Type    | Obligatoire | Description        |
|------------|---------|----------|--------------------|
| `id`       | integer | oui      | ID du compte utilisateur |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/reject"
```

Retourne :

- `200 OK` en cas de succès.
- `403 Forbidden` si l'authentification en tant qu'administrateur n'est pas effectuée.
- `404 User Not Found` si l'utilisateur est introuvable.
- `409 Conflict` si l'utilisateur n'est pas en attente d'approbation.

Exemples de réponses :

```json
{ "message": "Success" }
```

```json
{ "message": "404 User Not Found" }
```

```json
{ "message": "User does not have a pending request" }
```

## Désactiver un utilisateur {#deactivate-a-user}

Désactive un compte utilisateur spécifié. Pour plus d'informations sur les utilisateurs bannis, voir [Activer et désactiver les utilisateurs](../administration/moderate_users.md#deactivate-and-reactivate-users).

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
POST /users/:id/deactivate
```

Attributs pris en charge :

| Attribut  | Type    | Obligatoire | Description        |
|------------|---------|----------|--------------------|
| `id`       | integer | oui      | ID du compte utilisateur |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/deactivate"
```

Retourne :

- `201 OK` en cas de succès.
- `404 User Not Found` si l'utilisateur est introuvable.
- `403 Forbidden` lors d'une tentative de désactivation d'un utilisateur qui est :
  - Bloqué par un administrateur ou par la synchronisation LDAP.
  - Non [dormant](../administration/moderate_users.md#automatically-deactivate-dormant-users).
  - Interne.

## Réactiver un utilisateur {#reactivate-a-user}

Réactive un compte utilisateur spécifié qui était précédemment désactivé.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
POST /users/:id/activate
```

Attributs pris en charge :

| Attribut  | Type    | Obligatoire | Description        |
|------------|---------|----------|--------------------|
| `id`       | integer | oui      | ID du compte utilisateur |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/activate"
```

Retourne :

- `201 OK` en cas de succès.
- `404 User Not Found` si l'utilisateur est introuvable.
- `403 Forbidden` si l'utilisateur ne peut pas être activé parce qu'il est bloqué par un administrateur ou par la synchronisation LDAP.

## Bloquer l'accès d'un utilisateur {#block-access-to-a-user}

Bloque un compte utilisateur spécifié. Pour plus d'informations sur les utilisateurs bannis, voir [Bloquer et débloquer des utilisateurs](../administration/moderate_users.md#block-and-unblock-users).

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
POST /users/:id/block
```

Attributs pris en charge :

| Attribut  | Type    | Obligatoire | Description        |
|------------|---------|----------|--------------------|
| `id`       | integer | oui      | ID du compte utilisateur |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/block"
```

Retourne :

- `201 OK` en cas de succès.
- `404 User Not Found` si l'utilisateur est introuvable.
- `403 Forbidden` lors d'une tentative de blocage :
  - Un utilisateur bloqué via LDAP.
  - Un utilisateur interne.

## Débloquer l'accès d'un utilisateur {#unblock-access-to-a-user}

Débloque un compte utilisateur spécifié qui était précédemment bloqué.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
POST /users/:id/unblock
```

Attributs pris en charge :

| Attribut  | Type    | Obligatoire | Description        |
|------------|---------|----------|--------------------|
| `id`       | integer | oui      | ID du compte utilisateur |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/unblock"
```

Retourne :

- `201 OK` en cas de succès.
- `404 User Not Found` si l'utilisateur est introuvable.
- `403 Forbidden` lors d'une tentative de déblocage d'un utilisateur bloqué par la synchronisation LDAP.

## Bannir un utilisateur {#ban-a-user}

Bannit un compte utilisateur spécifié. Pour plus d'informations sur les utilisateurs bannis, voir [Bannir et débannir des utilisateurs](../administration/moderate_users.md#ban-and-unban-users).

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
POST /users/:id/ban
```

Attributs pris en charge :

| Attribut  | Type    | Obligatoire | Description        |
|------------|---------|----------|--------------------|
| `id`       | integer | oui      | ID du compte utilisateur |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/ban"
```

Retourne :

- `201 OK` en cas de succès.
- `404 User Not Found` si l'utilisateur est introuvable.
- `403 Forbidden` lors d'une tentative de bannissement d'un utilisateur qui n'est pas actif.

## Débannir un utilisateur {#unban-a-user}

Débannit un compte utilisateur spécifié qui était précédemment banni.

Prérequis :

- Vous devez disposer d'un accès administrateur à l'instance.

```plaintext
POST /users/:id/unban
```

Attributs pris en charge :

| Attribut  | Type    | Obligatoire | Description        |
|------------|---------|----------|--------------------|
| `id`       | integer | oui      | ID du compte utilisateur |

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/users/42/unban"
```

Retourne :

- `201 OK` en cas de succès.
- `404 User Not Found` si l'utilisateur est introuvable.
- `403 Forbidden` lors d'une tentative de débannissement d'un utilisateur qui n'est pas banni.

## Sujets connexes {#related-topics}

- [Consulter les signalements d'abus](../administration/review_abuse_reports.md)
- [Consulter les journaux de spam](../administration/review_spam_logs.md)
